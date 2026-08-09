# Walkthrough: "DON'T CUT IT" Functional Prototype

We have built and verified the initial functional prototype of **“DON’T CUT IT”**, an educational 2D Indonesian tropical rainforest lane-defense game about deforestation.

---

## 🌺 1. Screen Flow & Navigation Architecture

The game implements the complete requested flow:
```
[ HOME ] ──▶ [ PLAY / STAGE SELECT ] ──▶ [ PLAYTEST / ARENA ] ──▶ [ RESULT ] ──▶ [ HOME ]
   │
   ├──▶ [ FLORA ALMANAC / FIELD GUIDE ]
   └──▶ [ SETTINGS & AUDIO CONTROLS ]
```

- [home_screen.dart](file:///c:/Users/LENOVO/Downloads/Dont-cut-tree/lib/screens/home_screen.dart): Lush tropical rainforest animated title screen with ambient spore particles, `PLAY DEFENSE`, `FLORA ALMANAC`, and `SETTINGS` buttons.
- [stage_select_screen.dart](file:///c:/Users/LENOVO/Downloads/Dont-cut-tree/lib/screens/stage_select_screen.dart): Map across Indonesian biodiversity sectors (Sumatra Bukit Barisan, Kalimantan Heart of Borneo, Papua Lorentz Peatlands).
- [game_screen.dart](file:///c:/Users/LENOVO/Downloads/Dont-cut-tree/lib/screens/game_screen.dart): 16:9 responsive arena with letterbox framing, top HUD (energy, sanctum hearts, wave progress), vertical rail controller, bottom plant tray, and pause overlay.
- [result_screen.dart](file:///c:/Users/LENOVO/Downloads/Dont-cut-tree/lib/screens/result_screen.dart): Post-battle screen with star rating, prevented deforestation hectares, machinery crushed, and an **Educational Rainforest Ecosystem Fact Card**.
- [almanac_screen.dart](file:///c:/Users/LENOVO/Downloads/Dont-cut-tree/lib/screens/almanac_screen.dart): Interactive field guide covering Indonesian Flora (*Rafflesia arnoldii*, *Titan Arum*, *Bornean Ironwood*, *Pitcher Plants*, *Moon Orchids*) and Deforestation Threats (*Chainsaw Tractors*, *Logging Haulers*, *Peat Dredge Excavators*).
- [settings_screen.dart](file:///c:/Users/LENOVO/Downloads/Dont-cut-tree/lib/screens/settings_screen.dart): BGM & SFX sliders, screen shake toggle, 16:9 cinema framing toggle, and progress reset.

---

## 🌿 2. Arena Layout & Constraints

The gameplay arena adheres to the design specifications:
```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│  TOP HUD: [🌴 Sector Info]   [🌱 150 Seeds]   [♥ ♥ ♥ Sanctum]   [🌊 Wave 1/3]   [⏸]   │
├───────────────┬──────────────────────────────────────────┬─────────────────────────────┤
│   LEFT RAIL   │          CENTER 8×3 PLANTING GRID        │   RIGHT DEFORESTATION PATH  │
│ (Vertical)    │ (Humus Soil, Sprout Marker, Plant Cards) │ (Clearcut Track, Stumps)    │
│               │                                          │                             │
│ Lane 0 ───●   │  [·] [·] [·] [·] [·] [·] [·] [·]         │  ◀◀🚜 Chainsaw Tractor      │
│ Lane 1 ───🌺  │  [🌿][·] [·] [🪵][·] [·] [·] [·]         │  ◀◀🚛 Heavy Timber Hauler   │
│ Lane 2 ───●   │  [·] [·] [🪴][·] [·] [·] [·] [·]         │  ◀◀🏗️ Peat Dredge Excavator │
│ (Rafflesia)   │ (Strict separation: Rafflesia NOT on grid)│                             │
└───────────────┴──────────────────────────────────────────┴─────────────────────────────┘
  BOTTOM TRAY: [🌿 Pakis 50] [🪵 Ironwood 75] [🌺 Titan 100] [🪴 Pitcher 125] [🌸 Orchid 50] [🪓 Dig]
```

- **Strict Rafflesia Separation**: Rafflesia operates exclusively on the left vertical rail at `X = 85.0` and can only move vertically between Lanes 0, 1, and 2 (`W/S`, `Up/Down` keys, or lane touch buttons).
- **8×3 Soil Planting Grid**: 8 columns by 3 rows where defensive plants are cultivated using Eco-Seeds.
- **Deforestation Machinery Spawning**: Spawns from the far right clearcut logging road (`X = 990.0`) and advances left.
- **Rafflesia Auto-Attack**: Detects any active machinery on its current horizontal lane and launches bio-explosive spores.

---

## ⚙️ 3. Core Mechanics & Mathematical Specifications

1. **Seed Drop Probability**:
   - Every defeated machinery rolls against an exact **20% probability** (`Random().nextDouble() < 0.20`) to spawn a floating, bouncing golden Eco-Seed Pod.
2. **5 Indonesian Defensive Flora Types**:
   - **Ancient Fern Sprout (*Cyathea contaminans*)**: Rapid spore launcher (50 seeds, 4s CD).
   - **Bornean Ironwood (*Eusideroxylon zwageri*)**: Indestructible 900 HP barrier (75 seeds, 8s CD).
   - **Titan Arum (*Amorphophallus titanum*)**: Stench aura slowing enemies by 50% & applying continuous poison DPS (100 seeds, 10s CD).
   - **Tropical Pitcher Plant (*Nepenthes ampullaria*)**: Launches corrosive acid breaking machinery armor (125 seeds, 9s CD).
   - **Moon Forest Orchid (*Phalaenopsis amabilis*)**: Harnesses canopy sunlight to produce +25 Eco-Seeds (50 seeds, 6s CD).
3. **Audio & Effects Engine**:
   - Procedural Web Audio synthesis for bio-spore firing, plant growth, machinery impacts, seed collection chimes, and tropical rainforest ambient soundscapes.
   - Particle physics system for green foliage splinters, diesel exhaust smoke, impact sparks, and toxic vapor clouds.

---

## ✅ 4. Automated Verification & Quality Assurance

All unit tests and static analyses were executed:

```bash
$ flutter analyze
Analyzing Dont-cut-tree...                                      
No issues found! (ran in 5.9s)
```

```bash
$ flutter test
00:00 +0: loading C:/Users/LENOVO/Downloads/Dont-cut-tree/test/game_test.dart
00:00 +0: DON'T CUT IT - Core Game Mechanics & Lane Arena Tests Arena initialization - 3 lanes, 8x3 grid, and Rafflesia vertical rail
00:00 +1: DON'T CUT IT - Core Game Mechanics & Lane Arena Tests Rafflesia moves vertically UP and DOWN between lanes (0, 1, 2) only
00:00 +2: DON'T CUT IT - Core Game Mechanics & Lane Arena Tests Planting on the 8x3 grid deducts seeds and enforces cooldowns
00:00 +3: DON'T CUT IT - Core Game Mechanics & Lane Arena Tests Shovel tool digs up and removes plants from the grid
00:00 +4: DON'T CUT IT - Core Game Mechanics & Lane Arena Tests Deforestation machinery moves LEFT and damages blocking plants
00:00 +5: DON'T CUT IT - Core Game Mechanics & Lane Arena Tests Enemy defeat has exactly 20% Seed Drop chance distribution
00:00 +6: DON'T CUT IT - Core Game Mechanics & Lane Arena Tests Sanctum breach decreases health and triggers defeat when 0
00:00 +7: DON'T CUT IT - Core Game Mechanics & Lane Arena Tests Storage service records stars, seeds, and deforestation prevented
00:00 +8: All tests passed!
```
