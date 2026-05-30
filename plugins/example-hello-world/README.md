# Hello World Example

Ukázkový plugin pro Claude Plugin Marketplace. Slouží jako referenční implementace a ověření, že infrastruktura marketplace funguje správně.

## Popis

Plugin obsahuje jeden skill `hello-world`, který se aktivuje při pozdravení nebo testovacím příkazu. Po spuštění zobrazí diagnostické informace o načtení pluginu.

## Instalace

1. Stáhněte soubor `example-hello-world-1.0.0.plugin` z [GitHub Releases](https://github.com/fullsys/claude-plugin-marketplace/releases) nebo sestavte lokálně:

   ```bash
   ./scripts/build-plugin.sh plugins/example-hello-world
   ```

2. V Claude Cowork naimportujte `.plugin` soubor přes dialog pro instalaci pluginů.

3. Alternativně zkopírujte skill do lokální složky skills:

   ```bash
   cp -r plugins/example-hello-world/skills/hello-world ~/.claude/skills/
   ```

## Použití

Napište do chatu jeden z těchto příkazů:

- `hello world`
- `ahoj světe`
- `test plugin`

Skill odpoví pozdravem a zobrazí diagnostické informace o stavu pluginu.

## Požadavky

- Claude Cowork s podporou pluginů a skills
- Žádné externí závislosti

## Přispívání

Tento plugin je referenční šablona. Pro přidání vlastního pluginu postupujte podle [CONTRIBUTING.md](../../CONTRIBUTING.md) v kořeni repozitáře.
