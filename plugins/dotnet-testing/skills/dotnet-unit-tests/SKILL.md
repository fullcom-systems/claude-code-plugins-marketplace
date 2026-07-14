---
name: dotnet-unit-tests
description: >-
  Použij, když uživatel chce vytvořit, doplnit nebo upravit unit testy pro
  třídu/metodu v libovolném .NET/C# projektu — např. „napiš testy pro
  DiscountCalculator", „otestuj business logiku", „doplň testové scénáře".
  Skill nejprve zjistí testovací konvence repozitáře (framework, mock/assert
  knihovny, umístění testů) a testy jim přizpůsobí; pro nový testovací projekt
  navrhne výchozí stack xUnit + NSubstitute + Shouldly. Nepoužívej pro HTTP/API
  testy `.http` souborů — k tomu slouží skill dotnet-http-tests.
---

# Unit testy pro .NET projekty

Obecný skill pro tvorbu unit testů v **libovolném .NET projektu** — nezávisí na konkrétním
řešení, doméně ani sadě knihoven. Místo pevných konvencí jednoho projektu (namespace, cesty,
framework) nejprve **zjistí, co repozitář už používá**, a testy podle toho přizpůsobí. Tam,
kde repozitář žádnou konvenci ještě nemá (nový testovací projekt), navrhne rozumný výchozí
stack a upozorní na licenční aspekty.

## Kdy použít

Kdykoli uživatel chce vytvořit nebo doplnit unit testy pro třídu/metodu v C#/.NET projektu —
bez ohledu na to, jde-li o NextFIS, FIS, interní nástroj nebo úplně jiný repozitář.

## Krok 0 — zjisti konvence projektu (vždy jako první)

Než začneš psát testy, ověř si v repozitáři:

1. **Testovací framework** — nad existujícím testovacím projektem zkontroluj `<PackageReference>`
   v `.csproj`, případně atributy v existujících testech:
   - `xunit` → atributy `[Fact]` / `[Theory]` + `[InlineData]`
   - `NUnit` → atributy `[Test]` / `[TestCase]`, třída `[TestFixture]`
   - `MSTest.TestFramework` → atributy `[TestMethod]` / `[DataTestMethod]` + `[DataRow]`, třída `[TestClass]`
2. **Mock knihovna** — `Moq`, `NSubstitute`, `FakeItEasy`, případně žádná (ruční test doubles).
3. **Assertion knihovna** — `FluentAssertions`, `Shouldly`, `AwesomeAssertions`, nebo vestavěné
   `Assert.*` daného frameworku.
4. **Umístění a pojmenování testovacích projektů** — najdi existující `*.Tests.csproj` /
   `*.UnitTests.csproj` a zjisti, jak zrcadlí produkční projekt (viz níže).
5. **Jazyk komentářů/dokumentace** v existujících testech — čeština, nebo angličtina.

Zjištěné konvence **mají vždy přednost** před výchozími doporučeními níže — cílem je, aby nové
testy vypadaly, jako by je napsal někdo, kdo zbytek projektu už zná.

## Testovací stack — výchozí hodnoty pro nový testovací projekt

Pokud repozitář **ještě žádný testovací projekt nemá** (zakládáš ho poprvé), použij tato
výchozí doporučení:

| Kategorie | Doporučený výchozí | Časté alternativy (použij, pokud je repo již používá) |
|-----------|---------------------|----------------------------------------------------|
| **Framework** | xUnit | NUnit, MSTest |
| **Mockování** | NSubstitute | Moq, FakeItEasy |
| **Asserty** | Shouldly | FluentAssertions, AwesomeAssertions, vestavěné asserty |

### Proč NSubstitute a Shouldly

Pro **nové** testovací projekty preferuj **NSubstitute** a **Shouldly**:
- `Moq` a `FluentAssertions` mají od určité verze problematické licenční podmínky (SponsorLink
  telemetrie vyžadující přihlášení/licenci u komerčního použití).
- `NSubstitute` a `Shouldly` mají čistou BSD/MIT licenci bez těchto omezení.

Pro **existující** projekty vždy pokračuj v knihovně, kterou už používají — konzistence
v repozitáři má přednost před licenční preferencí. Podrobnou syntaxi všech čtyř knihoven
(+ NUnit/MSTest specifika) najdeš v `SYNTAX.md`.

## Postup tvorby testů

1. **Proveď krok 0** — zjisti konvence konkrétního repozitáře.
2. **Analyzuj třídu k testování** — přečti zdrojový soubor, identifikuj závislosti (konstruktor,
   rozhraní k mockování) a veřejné metody.
3. **Identifikuj testovatelné scénáře** — happy path, edge cases, chybové stavy (viz tabulka níže).
4. **Najdi nebo založ testovací třídu** podle konvencí dané níže.
5. **Implementuj testy** podle AAA patternu, se zjištěným (nebo výchozím) frameworkem a knihovnami.
6. **Spusť testy** a ověř, že prochází (viz sekce Spuštění testů).

## Konvence

### Umístění testů

Obecné pravidlo .NET ekosystému — testovací projekt **zrcadlí** strukturu produkčního projektu:

```
src/<Oblast>/<Projekt>/<Cesta>/TridaKTestovani.cs
tests/<Oblast>/<Projekt>.Tests/<Cesta>/TridaKTestovaniTests.cs
```

Konkrétní kořenové adresáře (`src/` vs. jiná struktura, `tests/` vs. `test/`) a název přípony
testovacího projektu (`.Tests`, `.UnitTests`, `.Test`) **přebírej z existujícího repozitáře**
zjištěného v kroku 0. Pokud testovací projekt pro danou oblast ještě neexistuje, založ ho vedle
ostatních testovacích projektů se stejnou konvencí pojmenování a `<TargetFramework>` odpovídajícím
testovanému produkčnímu projektu.

### Pojmenování

| Prvek | Konvence | Příklad |
|-------|----------|---------|
| Testovací třída | `{ClassName}Tests` | `DiscountCalculatorTests` |
| Testovací metoda | `{Metoda}_{Scénář}_{Očekávání}` | `Calculate_WhenCartIsEmpty_ReturnsZero` |

Tato konvence platí bez ohledu na framework (xUnit/NUnit/MSTest) — mění se pouze atributy.

### Struktura testovací třídy (příklad s xUnit + NSubstitute + Shouldly)

```csharp
using NSubstitute;
using Shouldly;

namespace MyCompany.MyProject.Domain.Tests.Pricing;

public class DiscountCalculatorTests
{
    /// <summary>
    /// Ověření že kalkulačka nevrátí slevu, pokud košík neobsahuje žádné položky.
    /// </summary>
    [Fact]
    public void Calculate_WhenCartIsEmpty_ReturnsZero()
    {
        // Arrange
        var pricingRules = Substitute.For<IPricingRulesProvider>();
        pricingRules.GetActiveRules().Returns(new List<PricingRule>());
        var sut = new DiscountCalculator(pricingRules);

        // Act
        var result = sut.Calculate(cart: new Cart());

        // Assert
        result.ShouldBe(0m);
    }
}
```

Ekvivalentní kostra s jinou kombinací frameworku/knihoven — viz `SYNTAX.md`.

## AAA Pattern (Arrange-Act-Assert)

Každý test MUSÍ používat AAA pattern s komentáři `// Arrange`, `// Act`, `// Assert` —
nezávisle na frameworku.

## Dokumentace testů

### XML dokumentace (povinná)

Každá testovací metoda MUSÍ mít `<summary>` popisující, co test ověřuje. **Výchozí jazyk je
čeština** (interní konvence Fullsys); pokud existující testy v repozitáři už dokumentují
anglicky, drž se jejich jazyka:

```csharp
/// <summary>
/// Ověření, že kalkulačka vrátí nulovou slevu pro prázdný košík.
/// </summary>
[Fact]
public void Calculate_WhenCartIsEmpty_ReturnsZero()
```

### Inline komentáře

Inline komentáře v Arrange sekci vysvětlují **co se nastavuje a proč** (business kontext), ve
stejném jazyce jako XML dokumentace:

```csharp
// Arrange
// zákazník má v košíku 3 kusy stejného produktu...
var cart = new Cart(items: new[] { new CartItem(productId: 1, quantity: 3) });
// ...a aktivní je pravidlo "3 za cenu 2"
var rule = new PricingRule(productId: 1, type: RuleType.ThreeForTwo);
```

## Scénáře k testování

Pro každou metodu identifikuj:

| Kategorie | Příklady |
|-----------|----------|
| **Happy path** | Standardní úspěšné provedení |
| **Edge cases** | Prázdné kolekce, null hodnoty, hraniční hodnoty |
| **Error cases** | Nevalidní vstup, chybové stavy, výjimky |
| **Business rules** | Specifická business pravidla a validace dané domény |

### Příklad scénářů

Pro metodu `Calculate(cart)`:

```
✓ Calculate_WithEligibleItems_ReturnsDiscountAmount
✓ Calculate_WhenCartIsEmpty_ReturnsZero
✓ Calculate_WhenNoActiveRules_ReturnsZero
✓ Calculate_WithMultipleApplicableRules_AppliesHighestDiscount
✓ Calculate_WhenCartIsNull_ThrowsArgumentNullException
```

## Parametrizované testy

Pro testování více vstupních hodnot použij parametrizovaný atribut daného frameworku
(`[Theory]`+`[InlineData]` u xUnit, `[TestCase]` u NUnit, `[DataTestMethod]`+`[DataRow]` u
MSTest — viz `SYNTAX.md`). Příklad s xUnit:

```csharp
/// <summary>
/// Ověření validace záporného a nulového množství.
/// </summary>
[Theory]
[InlineData(0)]
[InlineData(-1)]
[InlineData(-100)]
public void Validate_WhenQuantityIsZeroOrNegative_ReturnsFalse(decimal quantity)
{
    // Arrange
    var validator = new QuantityValidator();

    // Act
    var result = validator.IsValid(quantity);

    // Assert
    result.ShouldBeFalse();
}
```

## Kontrolní seznam

Před dokončením testů ověř:

- [ ] Proběhl krok 0 (zjištění konvencí repozitáře), a testy jim odpovídají?
- [ ] Testovací třída je ve správném namespace a adresáři (zrcadlí produkční projekt)?
- [ ] Název třídy končí konvencí daného projektu (typicky `Tests`)?
- [ ] Názvy metod dodržují konvenci `{Metoda}_{Scénář}_{Očekávání}`?
- [ ] Každá metoda má XML dokumentaci ve správném jazyce (repo konvence, výchozí čeština)?
- [ ] Inline komentáře vysvětlují business kontext ve stejném jazyce?
- [ ] Použit AAA pattern s komentáři?
- [ ] Pokryty happy path, edge cases i error cases?
- [ ] Použit framework a knihovny, které repozitář již používá (nebo odůvodněná výchozí volba)?
- [ ] Testy prošly (`dotnet test`)?

## Spuštění testů

Cesty k `.sln`/`.csproj` se projekt od projektu liší — pokud je neznáš, nejdřív je dohledej:

```powershell
# Najdi testovací projekty v repozitáři
Get-ChildItem -Recurse -Filter "*.Tests.csproj" -File
Get-ChildItem -Recurse -Filter "*.UnitTests.csproj" -File

# Spuštění všech testů v řešení
dotnet test .\NazevReseni.sln

# Spuštění konkrétního testovacího projektu
dotnet test .\tests\Cesta\NazevProjektu.Tests\

# Spuštění jednoho testu podle filtru názvu
dotnet test --filter "FullyQualifiedName~NazevTestovaciMetody"
```

## Další soubory

- `SYNTAX.md` — podrobná syntaxe xUnit/NUnit/MSTest a mock/assert knihoven (NSubstitute, Moq,
  Shouldly, FluentAssertions).
- `EXAMPLE.md` — kompletní referenční příklad (obecná doména, bez vazby na konkrétní projekt).
