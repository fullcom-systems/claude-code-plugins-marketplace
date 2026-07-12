#!/usr/bin/env node
// Stop hook: neumožní Claude ukončit tah, dokud testy neprojdou.
// Pojistka proti nekonečné smyčce = retry counter (stop_hook_active je jen sekundární).

const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const TEST_TARGET = "{{TEST_TARGET}}"; // <- doplněno při /setup-agentic-loop
const MAX_RETRIES = 5;
const COUNTER_FILE = path.join(__dirname, ".test-retry-count");

function readStdin() {
  try {
    return JSON.parse(fs.readFileSync(0, "utf-8"));
  } catch {
    return {};
  }
}

function getRetryCount() {
  try {
    return parseInt(fs.readFileSync(COUNTER_FILE, "utf-8"), 10) || 0;
  } catch {
    return 0;
  }
}

function setRetryCount(n) {
  fs.writeFileSync(COUNTER_FILE, String(n));
}

// Sdílený zámek se `verify-build.js` — ať `dotnet test` (který taky buildí) neběží souběžně
// s doběhávajícím buildem nad stejným řešením a nevzniknou falešné chyby ze zámků na obj/bin.
// LOCK_STALE_MS musí být delší než nejhorší legitimní držení zámku — tady až 2 běhy
// `dotnet test` po 300 s (no-build + fallback) = 600 s; hodnota MUSÍ být stejná v obou hoocích.
const LOCK_DIR = path.join(__dirname, ".dotnet-lock");
const LOCK_STALE_MS = 660_000;

function acquireLock() {
  try {
    fs.mkdirSync(LOCK_DIR);
    return true;
  } catch {
    try {
      // Vědomý kompromis: mezi statSync a rmSync je okno, kdy si dva procesy mohou stale
      // zámek "ukrást" navzájem — viz komentář ve verify-build.js.
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

// Test gate MUSÍ proběhnout, takže na zámek (drží ho třeba doběhávající build) chvíli počkáme.
// Atomics.wait je synchronní cross-platform sleep. Když se do maxWaitMs nedočkáme, spustíme
// testy i tak — případný souběžný fail zachytí retry counter při dalším pokusu.
function acquireLockBlocking(maxWaitMs) {
  const start = Date.now();
  const sab = new Int32Array(new SharedArrayBuffer(4));
  while (Date.now() - start < maxWaitMs) {
    if (acquireLock()) return true;
    Atomics.wait(sab, 0, 0, 500);
  }
  return acquireLock();
}

// Spustí testy. Primárně bez buildu (build po editaci zajišťuje verify-build.js / PostToolUse),
// což ušetří opakovaný build uvnitř `dotnet test`. Vrací { ok:true } nebo { ok:false, err }.
function runTests(noBuild) {
  try {
    execSync(`dotnet test "${TEST_TARGET}" ${noBuild ? "--no-build " : ""}--nologo`, {
      stdio: ["ignore", "pipe", "pipe"],
      timeout: 300_000,
    });
    return { ok: true };
  } catch (err) {
    return { ok: false, err };
  }
}

function isTimeout(err) {
  return err.killed || err.code === "ETIMEDOUT" || err.signal === "SIGTERM";
}

// Rozliší skutečné selhání testů od situace, kdy `--no-build` neměl co spustit (chybějící nebo
// neaktuální build, případně TEST_TARGET zahrnuje projekty mimo BUILD_TARGET) — v tom případě
// ve výstupu není žádný testový souhrn. Verzově stabilnější než parsování MSBuild hlášek.
function testsActuallyRan(err) {
  const output = (err.stdout?.toString() || "") + (err.stderr?.toString() || "");
  return /Passed!|Failed!|Passed:|Failed:|No test (is available|matches|source files)/i.test(output);
}

const input = readStdin();
const retries = getRetryCount();

// Pojistka proti nekonečné smyčce = tenhle retry counter. Stop hook s exit 2 vynutí
// pokračování, takže při dalších pokusech hook běží znovu — nesmí se tedy bezpodmínečně
// exitovat 0, jinak by se testy ověřily jen jednou a counter i MAX_RETRIES byly mrtvý kód.
// Counter se resetuje na úspěch a po dosažení MAX_RETRIES. Pozn.: soubor counteru přežívá
// mezi sessions — přerušený úkol s counterem > 0 sníží rozpočet pokusů dalšímu úkolu;
// vědomě jednoduché (counter se srovná při prvním úspěchu/stropu).
if (retries >= MAX_RETRIES) {
  setRetryCount(0);
  process.stderr.write(
    `Verifikace testů přeskočena po ${MAX_RETRIES} pokusech — zkontroluj ručně, ` +
      `možná je problém mimo dosah automatické opravy (rozbité prostředí, chybějící závislost apod.).\n`
  );
  process.exit(0); // necháme Claude zastavit, dál by to bylo kontraproduktivní
}

// Sekundární pojistka: jsme ve vynuceném pokračování, ale counter je na nule — stav se
// nepodařilo uložit (rozbitý counter, např. read-only fs). Bez funkčního counteru hrozí
// zacyklení, proto radši necháme Claude zastavit. Pole `stop_hook_active` už není
// v aktuálně dokumentovaném schématu Stop payloadu — pokud ho CLI neposílá, větev se
// nikdy neaktivuje a chová se to bezpečně (primární pojistkou zůstává counter).
if (input.stop_hook_active && retries === 0) {
  process.exit(0);
}

const locked = acquireLockBlocking(60_000);

// Primárně zkus rychlejší běh bez buildu. Když `--no-build` neměl co spustit (build nebyl
// aktuální nebo TEST_TARGET přesahuje BUILD_TARGET) a nešlo o timeout, spadni jednorázově
// zpět na plný build, ať je výsledek autoritativní. Timeout fallbackem neřešíme.
let result = runTests(true);
if (!result.ok && !isTimeout(result.err) && !testsActuallyRan(result.err)) {
  result = runTests(false);
}

let exitCode = 0;
let message = "";
if (result.ok) {
  setRetryCount(0);
} else {
  const err = result.err;
  setRetryCount(retries + 1);
  exitCode = 2;

  // Timeout není totéž co selhání testu — nehlas zavádějící "testy neprošly".
  if (isTimeout(err)) {
    message =
      `Testy překročily časový limit (pokus ${retries + 1}/${MAX_RETRIES}) — ` +
      `nemusí to znamenat chybu v kódu (pomalé prostředí, cold restore NuGet balíčků). ` +
      `Zvaž zúžení TEST_TARGET nebo delší timeout.\n`;
  } else {
    const output = (err.stdout?.toString() || "") + (err.stderr?.toString() || "");
    const summary = output
      .split("\n")
      .filter((l) => /Failed|Error Message|Passed!|Failed!/i.test(l))
      .slice(0, 30)
      .join("\n");
    message =
      `Testy neprošly (pokus ${retries + 1}/${MAX_RETRIES}):\n${summary || output.slice(-2000)}\n` +
      `Oprav selhávající testy před dokončením úkolu.\n`;
  }
}

// Uvolni zámek jen když jsme ho fakt získali (jinak bychom smazali cizí).
if (locked) releaseLock();
if (message) process.stderr.write(message);
process.exit(exitCode);
