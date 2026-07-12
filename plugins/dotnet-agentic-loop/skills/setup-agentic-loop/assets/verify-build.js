#!/usr/bin/env node
// PostToolUse hook: po každé editaci .cs/.csproj souboru spustí rychlý build.
// Exit 2 + stderr = feedback pro Claude (u PostToolUse tool už proběhl — akci to
// neblokuje, ale Claude výstup uvidí a může na něj hned reagovat).
// Exit 0 = žádná námitka, tok pokračuje normálně.

const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const BUILD_TARGET = "{{BUILD_TARGET}}"; // <- doplněno při /setup-agentic-loop

// Sdílený zámek build/test nad řešením. Agent často edituje víc souborů paralelně, takže
// by mohlo běžet víc `dotnet build` nad stejným řešením zároveň → zámky na obj/bin →
// falešné chyby. mkdir je atomické (test-and-set). Zámek po spadlém procesu (starší než
// LOCK_STALE_MS) ukradneme, ať se smyčka nezasekne.
const LOCK_DIR = path.join(__dirname, ".dotnet-lock");
const LOCK_STALE_MS = 180_000;

function acquireLock() {
  try {
    fs.mkdirSync(LOCK_DIR);
    return true;
  } catch {
    try {
      if (Date.now() - fs.statSync(LOCK_DIR).mtimeMs > LOCK_STALE_MS) {
        fs.rmSync(LOCK_DIR, { recursive: true, force: true });
        fs.mkdirSync(LOCK_DIR);
        return true;
      }
    } catch {}
    return false;
  }
}

function releaseLock() {
  try {
    fs.rmSync(LOCK_DIR, { recursive: true, force: true });
  } catch {}
}

function readStdin() {
  try {
    return JSON.parse(fs.readFileSync(0, "utf-8"));
  } catch {
    return {};
  }
}

const input = readStdin();
const filePath = input?.tool_input?.file_path || "";

// Reaguj jen na relevantní soubory, jinak build nespouštěj zbytečně.
if (!/\.(cs|csproj|props|targets)$/i.test(filePath)) {
  process.exit(0);
}

// Jiný build/test už běží nad řešením — nech ho doběhnout, tuhle změnu pokryje (finální
// stav navíc ověří Stop hook). Neblokuj se zbytečně na souběhu.
if (!acquireLock()) {
  process.exit(0);
}

let exitCode = 0;
let message = "";
try {
  const stdout = execSync(`dotnet build "${BUILD_TARGET}" --nologo -v q`, {
    stdio: ["ignore", "pipe", "pipe"],
    timeout: 120_000,
  }).toString();
  // Build prošel. Vytáhni analyzátorové/kompilátorové warnings (CA/S/RCS/IDE/CS…) v právě editovaném
  // souboru a předej je jako NEBLOKUJÍCÍ feedback — build ani smyčku to nezastaví, jen na ně upozorní
  // (měkký gate). Filtr na editovaný soubor drží šum nízko i v projektech s nahromaděnými warningy.
  const base = path.basename(filePath);
  const warnings = stdout
    .split("\n")
    .filter((l) => /:\s*warning\s+[A-Z]{1,4}\d+/i.test(l) && (base ? l.includes(base) : true))
    .slice(0, 20);
  if (warnings.length) {
    exitCode = 2;
    message =
      `Build po editaci ${filePath} prošel, ale statická analýza hlásí warnings ` +
      `(neblokující — zvaž opravu):\n${warnings.join("\n")}\n`;
  }
} catch (err) {
  exitCode = 2;
  // Timeout není totéž co chyba kompilace — nehlas zavádějící "build selhal".
  if (err.killed || err.code === "ETIMEDOUT" || err.signal === "SIGTERM") {
    message =
      `Build po editaci ${filePath} překročil časový limit — nemusí jít o chybu v kódu ` +
      `(pomalé prostředí, cold restore NuGet balíčků).\n`;
  } else {
    const output = (err.stdout?.toString() || "") + (err.stderr?.toString() || "");
    const errorLines = output
      .split("\n")
      .filter((l) => /error/i.test(l))
      .slice(0, 25)
      .join("\n");
    message = `Build selhal po editaci ${filePath}:\n${errorLines || output.slice(-2000)}\n`;
  }
}

releaseLock();
if (message) process.stderr.write(message);
process.exit(exitCode);
