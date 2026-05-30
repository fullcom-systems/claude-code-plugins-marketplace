# Hello World Example

Ukázkový plugin pro Fullsys Claude Plugin Marketplace. Slouží jako referenční implementace skill pluginu a ověření, že marketplace funguje.

## Popis

Plugin obsahuje jeden skill `hello-world`, který se aktivuje při pozdravení nebo testovacím příkazu. Po spuštění zobrazí diagnostické informace o načtení pluginu.

## Instalace

Nejprve přidejte marketplace (jednorázově) a poté nainstalujte plugin:

```
/plugin marketplace add fullsys/claude-plugin-marketplace
/plugin install example-hello-world@fullsys-plugins
```

## Použití

Napište do chatu jeden z těchto příkazů:

- `hello world`
- `ahoj světe`
- `test plugin`

Skill odpoví pozdravem a zobrazí diagnostické informace o stavu pluginu.

## Požadavky

- Claude Code s podporou pluginů a skills
- Žádné externí závislosti

## Přispívání

Tento plugin je referenční šablona skill pluginu. Pro přidání vlastního pluginu postupujte podle [CONTRIBUTING.md](../../CONTRIBUTING.md) v kořeni repozitáře.
