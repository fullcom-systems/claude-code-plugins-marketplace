# Syntaxe testovacích frameworků a knihoven

Tento soubor obsahuje podrobné příklady syntaxe pro testovací frameworky a mock/assertion
knihovny běžné v .NET ekosystému. Použij ho jako referenci poté, co v kroku 0 (`SKILL.md`)
zjistíš, co konkrétní repozitář používá.

## Obsah

- [Testovací frameworky](#testovací-frameworky)
  - [xUnit (preferováno pro nové projekty)](#xunit-preferováno-pro-nové-projekty)
  - [NUnit](#nunit)
  - [MSTest](#mstest)
- [Mock knihovny](#mock-knihovny)
  - [NSubstitute (preferováno)](#nsubstitute-preferováno)
  - [Moq (časté v existujících projektech)](#moq-časté-v-existujících-projektech)
- [Assertion knihovny](#assertion-knihovny)
  - [Shouldly (preferováno)](#shouldly-preferováno)
  - [FluentAssertions (časté v existujících projektech)](#fluentassertions-časté-v-existujících-projektech)
- [Porovnávací tabulky](#porovnávací-tabulky)

---

## Testovací frameworky

### xUnit (preferováno pro nové projekty)

```csharp
using Xunit;

public class DiscountCalculatorTests
{
    [Fact]
    public void Calculate_WhenCartIsEmpty_ReturnsZero() { /* ... */ }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void Validate_WhenQuantityIsZeroOrNegative_ReturnsFalse(decimal quantity) { /* ... */ }

    // Setup/teardown přes konstruktor a IDisposable (žádné [SetUp]/[TearDown] atributy)
    public DiscountCalculatorTests()
    {
        // spouští se před KAŽDÝM testem
    }
}
```

### NUnit

```csharp
using NUnit.Framework;

[TestFixture]
public class DiscountCalculatorTests
{
    [SetUp]
    public void Setup()
    {
        // spouští se před KAŽDÝM testem
    }

    [Test]
    public void Calculate_WhenCartIsEmpty_ReturnsZero() { /* ... */ }

    [TestCase(0)]
    [TestCase(-1)]
    public void Validate_WhenQuantityIsZeroOrNegative_ReturnsFalse(decimal quantity) { /* ... */ }
}
```

### MSTest

```csharp
using Microsoft.VisualStudio.TestTools.UnitTesting;

[TestClass]
public class DiscountCalculatorTests
{
    [TestInitialize]
    public void Setup()
    {
        // spouští se před KAŽDÝM testem
    }

    [TestMethod]
    public void Calculate_WhenCartIsEmpty_ReturnsZero() { /* ... */ }

    [DataTestMethod]
    [DataRow(0)]
    [DataRow(-1)]
    public void Validate_WhenQuantityIsZeroOrNegative_ReturnsFalse(decimal quantity) { /* ... */ }
}
```

### Srovnání atributů

| Účel | xUnit | NUnit | MSTest |
|------|-------|-------|--------|
| Testovací třída | (žádný atribut) | `[TestFixture]` | `[TestClass]` |
| Jednoduchý test | `[Fact]` | `[Test]` | `[TestMethod]` |
| Parametrizovaný test | `[Theory]` + `[InlineData]` | `[Test]` + `[TestCase]` | `[DataTestMethod]` + `[DataRow]` |
| Před každým testem | konstruktor | `[SetUp]` | `[TestInitialize]` |
| Po každém testu | `IDisposable.Dispose()` | `[TearDown]` | `[TestCleanup]` |
| Přeskočit test | `[Fact(Skip = "důvod")]` | `[Ignore("důvod")]` | `[Ignore]` |

---

## Mock knihovny

### NSubstitute (preferováno)

NSubstitute má čistší syntaxi a MIT licenci.

```csharp
using NSubstitute;

// Vytvoření mocku
var repository = Substitute.For<IOrderRepository>();

// Setup návratové hodnoty
repository.GetById(Arg.Any<int>()).Returns(entity);
repository.GetByIdAsync(Arg.Any<int>()).Returns(Task.FromResult(entity));

// Setup pro konkrétní argument
repository.GetById(42).Returns(specificEntity);

// Vyhození výjimky
repository.Delete(Arg.Any<int>()).Throws<NotFoundException>();

// Callback
repository.When(r => r.Save(Arg.Any<Order>()))
    .Do(call => savedEntity = call.Arg<Order>());
```

#### Verifikace volání

```csharp
// Ověření že metoda byla zavolána
repository.Received().Save(Arg.Any<Order>());
repository.Received(1).Save(Arg.Any<Order>()); // přesně jednou

// Ověření že metoda NEBYLA zavolána
repository.DidNotReceive().Delete(Arg.Any<int>());

// Ověření s konkrétními parametry
repository.Received().Save(Arg.Is<Order>(o => o.Id == 1));
```

#### Partial mock (virtuální metody)

```csharp
var sut = Substitute.ForPartsOf<DiscountCalculator>(pricingRules);
sut.GetApplicableRules(Arg.Any<Cart>())
    .Returns(new List<PricingRule> { rule });
```

### Moq (časté v existujících projektech)

```csharp
using Moq;

// Vytvoření mocku
var mock = new Mock<IOrderRepository>();

// Návratová hodnota
mock.Setup(s => s.GetById(It.IsAny<int>())).Returns(entity);
mock.Setup(s => s.GetByIdAsync(It.IsAny<int>())).ReturnsAsync(entity);

// Vyhození výjimky
mock.Setup(s => s.Delete(It.IsAny<int>())).Throws<NotFoundException>();

// Callback
mock.Setup(s => s.Save(It.IsAny<Order>()))
    .Callback<Order>(o => savedEntity = o);

// Přístup k instanci
var repository = mock.Object;
```

#### Verifikace volání

```csharp
// Ověření že metoda byla zavolána
mock.Verify(s => s.Save(It.IsAny<Order>()), Times.Once);
mock.Verify(s => s.Delete(It.IsAny<int>()), Times.Never);

// Ověření s konkrétními parametry
mock.Verify(s => s.Save(It.Is<Order>(o => o.Id == 1)), Times.Once);
```

#### Partial mock (virtuální metody)

```csharp
var sutMock = new Mock<DiscountCalculator>(pricingRules);
sutMock.Setup(s => s.GetApplicableRules(It.IsAny<Cart>()))
    .Returns(new List<PricingRule> { rule });
var sut = sutMock.Object;
```

> Poznámka: Moq od verze 4.20 obsahuje kontroverzní SponsorLink telemetrii (později staženo,
> ale důvěra byla narušena). Pro nové projekty proto preferuj NSubstitute.

---

## Assertion knihovny

### Shouldly (preferováno)

Shouldly má čistší syntaxi, lepší chybové zprávy a BSD licenci.

```csharp
using Shouldly;

// Hodnoty
result.ShouldBe(10);
result.ShouldBeNull();
result.ShouldNotBeNull();
result.ShouldBeTrue();
result.ShouldBeFalse();
result.ShouldBeGreaterThan(5);
result.ShouldBeLessThanOrEqualTo(100);

// Kolekce
list.ShouldBeEmpty();
list.ShouldNotBeEmpty();
list.Count.ShouldBe(5);
list.ShouldContain(item);
list.ShouldContain(x => x.Id == 1);
list.ShouldAllBe(x => x.IsValid);
list.ShouldBeUnique();

// Stringy
str.ShouldBe("expected");
str.ShouldContain("substring");
str.ShouldStartWith("prefix");
str.ShouldEndWith("suffix");
str.ShouldBeNullOrEmpty();
str.ShouldMatch(@"regex\d+");

// Porovnání objektů (deep equality)
result.ShouldBeEquivalentTo(expected);
```

#### Testování výjimek

```csharp
// Synchronní metoda
var ex = Should.Throw<InvalidOperationException>(() => sut.DoSomething());
ex.Message.ShouldContain("expected message");

// Asynchronní metoda
var ex = await Should.ThrowAsync<NotFoundException>(
    async () => await sut.DoSomethingAsync());
ex.Message.ShouldContain("expected message");

// Ověření že výjimka NENÍ vyhozena
Should.NotThrow(() => sut.DoSomething());
await Should.NotThrowAsync(async () => await sut.DoSomethingAsync());
```

#### Výhody Shouldly

1. **Lepší chybové zprávy** — automaticky zobrazí název proměnné:
   ```
   result.ShouldBe(10)
   // Chyba: result should be 10 but was 5
   ```
2. **Čistší syntaxe** — méně psaní, žádné `.Should()`.
3. **BSD licence** — bez kontroverzí.

### FluentAssertions (časté v existujících projektech)

```csharp
using FluentAssertions;

// Hodnoty
result.Should().Be(10);
result.Should().BeNull();
result.Should().NotBeNull();
result.Should().BeTrue();
result.Should().BeFalse();

// Kolekce
list.Should().BeEmpty();
list.Should().HaveCount(5);
list.Should().Contain(item);
list.Should().ContainSingle();

// Stringy
str.Should().Be("expected");
str.Should().Contain("substring");
str.Should().StartWith("prefix");

// Porovnání objektů
result.Should().BeEquivalentTo(expected);
```

#### Testování výjimek

```csharp
// Synchronní metoda
var act = () => sut.DoSomething();
act.Should().Throw<InvalidOperationException>()
   .WithMessage("Expected message");

// Asynchronní metoda
var act = async () => await sut.DoSomethingAsync();
await act.Should().ThrowAsync<NotFoundException>()
   .WithMessage("Expected message*");
```

> Poznámka: FluentAssertions od verze 8 vyžaduje komerční licenci (SponsorLink). Pro nové
> projekty proto preferuj Shouldly nebo bezplatnou vidlici `AwesomeAssertions` (API kompatibilní
> s FluentAssertions < 8).

---

## Porovnávací tabulky

### Moq vs NSubstitute

| Operace | Moq | NSubstitute |
|---------|-----|-------------|
| Vytvoření mocku | `new Mock<IService>()` | `Substitute.For<IService>()` |
| Přístup k instanci | `mock.Object` | přímo `substitute` |
| Any argument | `It.IsAny<int>()` | `Arg.Any<int>()` |
| Konkrétní argument | `It.Is<T>(predicate)` | `Arg.Is<T>(predicate)` |
| Setup | `.Setup(x => x.Method()).Returns()` | `.Method().Returns()` |
| Verify zavolání | `.Verify(x => x.Method(), Times.Once)` | `.Received().Method()` |
| Verify nezavolání | `.Verify(x => x.Method(), Times.Never)` | `.DidNotReceive().Method()` |

### FluentAssertions vs Shouldly

| Operace | FluentAssertions | Shouldly |
|---------|-------------------|----------|
| Rovnost | `.Should().Be(x)` | `.ShouldBe(x)` |
| Null | `.Should().BeNull()` | `.ShouldBeNull()` |
| True/False | `.Should().BeTrue()` | `.ShouldBeTrue()` |
| Kolekce prázdná | `.Should().BeEmpty()` | `.ShouldBeEmpty()` |
| Kolekce obsahuje | `.Should().Contain(x)` | `.ShouldContain(x)` |
| String obsahuje | `.Should().Contain("x")` | `.ShouldContain("x")` |
| Výjimka (sync) | `act.Should().Throw<T>()` | `Should.Throw<T>(act)` |
| Výjimka (async) | `await act.Should().ThrowAsync<T>()` | `await Should.ThrowAsync<T>(act)` |
| Deep equality | `.Should().BeEquivalentTo(x)` | `.ShouldBeEquivalentTo(x)` |
