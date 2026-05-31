# repo-architect

GitHub Repository Architect — Claude Code skill pro analýzu, návrh a opravu struktury GitHub repozitářů dle open-source best-practice standardů.

## Skill: `/repo-architect`

| Argument | Popis |
|----------|-------|
| `analyze` | Analyzuje existující strukturu a hodnotí ji oproti zlatému standardu |
| `new <jazyk>` | Generuje doporučenou strukturu pro nový projekt (např. `new python`, `new typescript`) |
| `fix` | Analyzuje a navrhne konkrétní příkazy pro nápravu struktury |

Pokud je spuštěn bez argumentu na repozitáři s existujícím kódem, automaticky se přepne do režimu `analyze`.

## Co skill dělá

- Generuje **vizuální ASCII strom** složek a souborů
- Hodnotí strukturu dle **zlatého standardu** (povinné/doporučené/volitelné soubory)
- Detekuje jazyk/framework z root souborů
- Navrhuje konkrétní příkazy pro nápravu (`.ps1` pro Windows, `.sh` pro Linux)
- Upozorňuje na dopady změn na importy a CI/CD

## Instalace

```
/plugin install repo-architect
```

## Příklady použití

```
/repo-architect analyze
/repo-architect new dotnet
/repo-architect fix
```

## Changelog

### 1.0.0

- Počáteční vydání skilu repo-architect
- Režimy: analyze, new, fix
- Podpora: Node.js, Python, Rust, .NET, Go, Java, Docker, Terraform
