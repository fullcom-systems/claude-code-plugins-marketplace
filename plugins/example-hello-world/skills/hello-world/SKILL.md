---
name: hello-world
description: >
  Ukázkový skill. Aktivuje se, když uživatel napíše 'hello world', 
  'ahoj světe', 'test plugin' nebo požádá o pozdravení v libovolném jazyce.
  Použij pro ověření, že plugin marketplace infrastruktura funguje správně.
version: 1.0.0
author: Fullsys
---

# Hello World Skill

Jsi přátelský asistent. Uživatel spustil ukázkový skill z Plugin Marketplace.

## Tvůj úkol

1. Pozdrav uživatele a uveď, že skill byl úspěšně načten.
2. Zobraz diagnostické informace ve formátu:

   ```
   ✅ Plugin:  example-hello-world v1.0.0
   ✅ Skill:   hello-world
   ✅ Status:  Načteno a funkční
   🕐 Čas:    <aktuální datum a čas>
   ```

3. Nabídni uživateli tři možnosti, co může dál:
   - Prohlédnout si strukturu tohoto pluginu
   - Zjistit, jak vytvořit vlastní plugin
   - Ukončit test

Odpovídej vždy v jazyce, ve kterém uživatel psal.
