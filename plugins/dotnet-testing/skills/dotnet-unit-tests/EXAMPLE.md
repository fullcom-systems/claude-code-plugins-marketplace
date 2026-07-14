# Příklad Unit Testů

Tento soubor obsahuje referenční příklad unit testů — záměrně na **obecné doméně**
(slevový kalkulátor), aby šel použít jako vzor v jakémkoli .NET projektu. Použit je výchozí
doporučený stack (xUnit + NSubstitute + Shouldly); pro jinou kombinaci frameworku/knihoven
uprav syntaxi podle `SYNTAX.md`.

## Vstup (třída k testování)

```csharp
// src/MyProject.Domain/Pricing/DiscountCalculator.cs

namespace MyCompany.MyProject.Domain.Pricing;

/// <summary>
/// Třída pro výpočet celkové slevy na košík na základě aktivních cenových pravidel.
/// </summary>
public class DiscountCalculator
{
    private readonly IPricingRulesProvider _pricingRulesProvider;

    public DiscountCalculator(IPricingRulesProvider pricingRulesProvider)
    {
        _pricingRulesProvider = pricingRulesProvider;
    }

    public virtual IReadOnlyList<PricingRule> GetApplicableRules(Cart cart)
    {
        // implementace načtení pravidel platných pro položky v košíku
    }

    public async Task<decimal> CalculateAsync(Cart cart)
    {
        if (cart is null)
        {
            throw new ArgumentNullException(nameof(cart));
        }

        var rules = GetApplicableRules(cart);
        if (rules.Count == 0)
        {
            return 0m;
        }

        var totalDiscount = rules.Sum(rule => rule.DiscountAmountFor(cart));

        if (totalDiscount > cart.TotalPrice)
        {
            throw new InvalidOperationException(
                $"Calculated discount ({totalDiscount}) exceeds cart total ({cart.TotalPrice}).");
        }

        return totalDiscount;
    }
}
```

---

## Výstupní testy

```csharp
// tests/MyProject.Domain.Tests/Pricing/DiscountCalculatorTests.cs

using NSubstitute;
using Shouldly;
using MyCompany.MyProject.Domain.Pricing;

namespace MyCompany.MyProject.Domain.Tests.Pricing;

public class DiscountCalculatorTests
{
    /// <summary>
    /// Ověření, že kalkulačka vrátí nulovou slevu, pokud neexistuje žádné pravidlo
    /// aplikovatelné na aktuální obsah košíku.
    /// </summary>
    [Fact]
    public async Task CalculateAsync_WhenNoApplicableRules_ReturnsZero()
    {
        // Arrange
        // košík obsahuje jednu položku v hodnotě 200
        var cart = new Cart(items: new[] { new CartItem(productId: 1, quantity: 1, unitPrice: 200m) });
        var pricingRulesProvider = Substitute.For<IPricingRulesProvider>();
        var sut = Substitute.ForPartsOf<DiscountCalculator>(pricingRulesProvider);
        // ...pro tento košík neplatí žádné pravidlo
        sut.GetApplicableRules(cart).Returns(new List<PricingRule>());

        // Act
        var result = await sut.CalculateAsync(cart);

        // Assert
        result.ShouldBe(0m);
    }

    /// <summary>
    /// Ověření správného výpočtu slevy, pokud na košík platí jediné pravidlo.
    /// </summary>
    [Fact]
    public async Task CalculateAsync_WithSingleApplicableRule_ReturnsRuleDiscount()
    {
        // Arrange
        // košík v hodnotě 500...
        var cart = new Cart(items: new[] { new CartItem(productId: 1, quantity: 1, unitPrice: 500m) });
        var pricingRulesProvider = Substitute.For<IPricingRulesProvider>();
        var sut = Substitute.ForPartsOf<DiscountCalculator>(pricingRulesProvider);
        // ...a jedno pravidlo poskytující slevu 50
        var rule = Substitute.For<PricingRule>();
        rule.DiscountAmountFor(cart).Returns(50m);
        sut.GetApplicableRules(cart).Returns(new List<PricingRule> { rule });

        // Act
        var result = await sut.CalculateAsync(cart);

        // Assert
        result.ShouldBe(50m);
    }

    /// <summary>
    /// Ověření, že se sečtou slevy ze všech aplikovatelných pravidel, pokud jich na
    /// košík platí víc najednou.
    /// </summary>
    [Fact]
    public async Task CalculateAsync_WithMultipleApplicableRules_SumsDiscounts()
    {
        // Arrange
        // košík v hodnotě 1000...
        var cart = new Cart(items: new[] { new CartItem(productId: 1, quantity: 2, unitPrice: 500m) });
        var pricingRulesProvider = Substitute.For<IPricingRulesProvider>();
        var sut = Substitute.ForPartsOf<DiscountCalculator>(pricingRulesProvider);
        // ...a dvě platná pravidla, 50 a 30
        var ruleA = Substitute.For<PricingRule>();
        ruleA.DiscountAmountFor(cart).Returns(50m);
        var ruleB = Substitute.For<PricingRule>();
        ruleB.DiscountAmountFor(cart).Returns(30m);
        sut.GetApplicableRules(cart).Returns(new List<PricingRule> { ruleA, ruleB });

        // Act
        var result = await sut.CalculateAsync(cart);

        // Assert
        result.ShouldBe(80m);
    }

    /// <summary>
    /// Ověření vyvolání výjimky, pokud by součet slev z pravidel přesáhl celkovou
    /// cenu košíku (nekonzistentní/chybně nastavené pravidlo).
    /// </summary>
    [Fact]
    public async Task CalculateAsync_WhenDiscountExceedsCartTotal_ThrowsInvalidOperationException()
    {
        // Arrange
        // košík v hodnotě jen 40...
        var cart = new Cart(items: new[] { new CartItem(productId: 1, quantity: 1, unitPrice: 40m) });
        var pricingRulesProvider = Substitute.For<IPricingRulesProvider>();
        var sut = Substitute.ForPartsOf<DiscountCalculator>(pricingRulesProvider);
        // ...ale chybně nastavené pravidlo nabízí slevu 50 (víc než je celková cena)
        var rule = Substitute.For<PricingRule>();
        rule.DiscountAmountFor(cart).Returns(50m);
        sut.GetApplicableRules(cart).Returns(new List<PricingRule> { rule });

        // Act
        var act = () => sut.CalculateAsync(cart);

        // Assert
        var ex = await Should.ThrowAsync<InvalidOperationException>(act);
        ex.Message.ShouldContain("exceeds cart total");
    }

    /// <summary>
    /// Ověření, že metoda odmítne null košík hned na vstupu.
    /// </summary>
    [Fact]
    public async Task CalculateAsync_WhenCartIsNull_ThrowsArgumentNullException()
    {
        // Arrange
        var pricingRulesProvider = Substitute.For<IPricingRulesProvider>();
        var sut = new DiscountCalculator(pricingRulesProvider);

        // Act
        var act = () => sut.CalculateAsync(null!);

        // Assert
        await Should.ThrowAsync<ArgumentNullException>(act);
    }
}
```

---

## Shrnutí testovaných scénářů

| Scénář | Metoda | Očekávání |
|--------|--------|-----------|
| Žádné platné pravidlo | `CalculateAsync_WhenNoApplicableRules_ReturnsZero` | Vrátí nulovou slevu |
| Jedno platné pravidlo | `CalculateAsync_WithSingleApplicableRule_ReturnsRuleDiscount` | Vrátí slevu dle pravidla |
| Více platných pravidel | `CalculateAsync_WithMultipleApplicableRules_SumsDiscounts` | Sečte slevy |
| Sleva přesahuje cenu | `CalculateAsync_WhenDiscountExceedsCartTotal_ThrowsInvalidOperationException` | Vyhodí výjimku |
| Neplatný vstup | `CalculateAsync_WhenCartIsNull_ThrowsArgumentNullException` | Vyhodí výjimku hned na vstupu |

---

## Poznámky k příkladu

### Mockování virtuální metody (partial mock)

V testech, kde chceme testovat logiku `CalculateAsync` izolovaně od skutečného načítání
pravidel, je použit partial mock virtuální metody `GetApplicableRules`:

```csharp
var sut = Substitute.ForPartsOf<DiscountCalculator>(pricingRulesProvider);
sut.GetApplicableRules(cart).Returns(new List<PricingRule> { rule });
```

Ekvivalent v Moq: `var sutMock = new Mock<DiscountCalculator>(pricingRulesProvider); sutMock.Setup(...)`
(viz `SYNTAX.md`). Partial mock je vhodný, když:
- Metoda načítá data z databáze nebo externího zdroje.
- Chceme testovat logiku volající metody izolovaně.
- Alternativou by bylo vytvořit testovací podtřídu (stub) nebo přesunout načítání do vstřikované závislosti.

### Testování výjimek

Pro asynchronní metody používáme `Should.ThrowAsync<T>(...)` (Shouldly), případně
`await act.Should().ThrowAsync<T>().WithMessage(...)` u FluentAssertions — viz `SYNTAX.md`.

### Čitelné komentáře

Komentáře v Arrange sekci vysvětlují business kontext:
- Co reprezentuje testovací hodnota.
- Proč je tato hodnota zvolena.
- Jaký stav simulujeme.

Stejný princip platí bez ohledu na doménu konkrétního projektu — nahraď `Cart`/`PricingRule`
za reálné třídy z testovaného projektu, ale strukturu a styl komentářů zachovej.
