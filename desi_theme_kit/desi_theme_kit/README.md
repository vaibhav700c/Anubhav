# Desi Theme Kit — extracted from Kaala Teeka deck

## What's in here
- `assets/decor/` — actual vector art pulled from your pptx (unzipped as a
  zip archive, converted from the embedded SVGs/PNGs). Not recreated by eye —
  these are your deck's real assets, rasterized at app-appropriate sizes:
  - `mandala_motif.png` — the sunburst mandala
  - `flower_divider.png` — the marigold border strip used under headings
  - `jali_tile_watermark.png` — the lotus/jali lattice pattern, pre-baked to
    ~8% opacity so it can tile behind content without hurting readability
  - `jali_tile_full.png` — same pattern at full opacity, for small accents
  - `marigold_pot.png` — the kalash/marigold illustration (busier — use on
    an empty-state or onboarding screen, not behind dense data)
- `lib/theme/app_theme.dart` — ThemeData using the deck's exact 3 colors
  (#F5E6C8 cream, #7A1F1F maroon, #E16533 burnt orange) pulled from the
  slide XML, plus a font pairing
- `lib/widgets/desi_decorations.dart` — 3 drop-in widgets wrapping the assets
  above (DesiPatternBackground, MandalaCorner, FlowerDivider)

## Setup
1. Copy `assets/decor/` into your Flutter project's `assets/decor/`
2. Add to `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/decor/
   dependencies:
     google_fonts: ^6.2.1
   ```
3. Copy the two `lib/` files in, set `theme: AppTheme.theme` in your
   MaterialApp.
4. Wrap screen bodies in `DesiPatternBackground` where you want the texture,
   swap plain `Divider()`s for `FlowerDivider()`, and use `MandalaCorner`
   once on your home/splash screen — not on every screen.
