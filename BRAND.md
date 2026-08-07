# Colour palette – sampled from the school blazer

**Status: ratified. This is the brand palette.**

The base is taken directly from the uniform photo. Dominant blazer blue is **#1F3477**, lit folds run to **#2A4EA8**, deepest shadow sits at **#141A3D**. That gives a hue of ~226° – royal blue with a faint violet lean – which everything else is built around.

## Base

| Token | Hex | Role |
|---|---|---|
| `--blue` | **#1F3477** | Primary. The blazer body. Filled squares, buttons, headings on white |
| `--blue-lift` | **#2A4EA8** | Lit folds. Hovers, links, secondary fills |
| `--navy` | **#16234F** | Deepest fold. Dark chrome: donation bar, footer, toasts |
| `--blue-300` | **#8FA6DA** | Pastel mid. Borders, inactive states, chart fills |
| `--blue-100` | **#DCE3F5** | Pastel wash. Cards, hover backgrounds |
| `--blue-50` | **#EEF2FB** | Faintest tint. Inset panels, open squares |

## Neutrals

| Token | Hex | Role |
|---|---|---|
| `--surface` | **#FFFFFF** | Cards, sheets, the checkout |
| `--paper` | **#F7F9FD** | Page ground – white with one breath of blue |
| `--line` | **#D9E0F0** | Hairlines and borders |
| `--ink` | **#1A1D2B** | Body text |
| `--ink-2` | **#5A6180** | Secondary text, captions |

## Pastel accents

| Token | Hex | Role |
|---|---|---|
| `--butter` | **#F7D488** | Your current selection, the progress meter |
| `--butter-deep` | **#E0A83C** | Focus ring, accent borders |
| `--mint` | **#A9D9C8** | Gallery, soft panels |
| `--mint-deep` | **#2A7361** | Squares you filled, the message wall |
| `--blush` | **#F4BCC0** | Gallery, tertiary highlight |
| `--sage` | **#CFE3B8** | Gallery, tertiary highlight |

## Paste-ready

```css
:root{
  --blue:#1F3477;  --blue-lift:#2A4EA8;  --navy:#16234F;
  --blue-300:#8FA6DA;  --blue-100:#DCE3F5;  --blue-50:#EEF2FB;
  --surface:#FFFFFF;  --paper:#F7F9FD;  --line:#D9E0F0;
  --ink:#1A1D2B;  --ink-2:#5A6180;
  --butter:#F7D488;  --butter-deep:#E0A83C;
  --mint:#A9D9C8;  --mint-deep:#2A7361;
  --blush:#F4BCC0;  --sage:#CFE3B8;
}
```

## Tints

80%, 40% and 20% colour strength, remainder white. **Restricted to infographics, tables, digital buttons, graphs and highlights.** Not for page chrome, body text or interface surfaces.

| Colour | 100% | 80% | 40% | 20% |
|---|---|---|---|---|
| blue | #1F3477 | #4C5D92 | #A5AEC9 | #D2D6E4 |
| blue-lift | #2A4EA8 | #5571B9 | #AAB8DC | #D4DCEE |
| navy | #16234F | #454F72 | #A2A7B9 | #D0D3DC |
| butter | #F7D488 | #F9DDA0 | #FCEECF | #FDF6E7 |
| butter-deep | #E0A83C | #E6B963 | #F3DCB1 | #F9EED8 |
| mint | #A9D9C8 | #BAE1D3 | #DDF0E9 | #EEF7F4 |
| mint-deep | #2A7361 | #558F81 | #AAC7C0 | #D4E3DF |
| blush | #F4BCC0 | #F6C9CD | #FBE4E6 | #FDF2F2 |
| sage | #CFE3B8 | #D9E9C6 | #ECF4E3 | #F5F9F1 |
| ink | #1A1D2B | #484A55 | #A3A5AA | #D1D2D5 |

Tokens: `--tint-{colour}-{80|40|20}`. Text rules and the charting constraints are in `CLAUDE.md` – the short version is that 40% and 20% tints always take dark text and always need a border in a chart, because none of them reach 1.4:1 against the page on their own.

## Square states

| State | Fill | Text |
|---|---|---|
| Open | `--blue-50` #EEF2FB, `--line` border | `--ink-2` |
| Your pick | `--butter` #F7D488 | `--navy` |
| Filled by someone | `--blue` #1F3477 | white |
| Filled by you | `--mint-deep` #2A7361 | white |

## Contrast

Pastels are where accessibility usually quietly fails, so every text pairing was checked. All pass WCAG AA; most pass AAA.

| Pairing | Ratio |
|---|---|
| White on `--blue` | 11.6 : 1 |
| White on `--navy` | 15.1 : 1 |
| White on `--blue-lift` | 7.6 : 1 |
| `--navy` on `--butter` | 10.6 : 1 |
| `--ink` on `--paper` | 15.9 : 1 |
| `--ink-2` on `--paper` | 5.8 : 1 |
| White on `--mint-deep` | 5.6 : 1 |

Two notes on why some values sit where they do. The pastel accents (`--butter`, `--mint`, `--blush`, `--sage`) are backgrounds and fills only – never text colours, because at pastel lightness nothing reaches 4.5:1 against white. And `--mint-deep` was darkened from a softer green specifically to carry white text on the message wall.



---

# Typography

Three brand fonts, self-hosted from `/fonts` as woff2 with a woff fallback.

| Role | Font | CSS token | Leading | Tracking |
|---|---|---|---|---|
| Primary headline | Grift Black | `--headline` | 0.85 (80–90%) | +0.01em (+10) |
| Sub-headline, intro, pull quotes | Juniper Regular | `--sub` | 1.2 (120%) | 0 |
| Body copy | JUST Sans Light | `--body` | 1.2 (120%) | 0 |

**Grift Black is ALL CAPS, always.** Use it for maximum impact on the primary title and key messages: `h1`, `h2`, sheet titles, and the large campaign numbers. It is a display weight – never below ~20px, never in sentence case.

**Juniper Regular** bridges headline and body – sub-headlines, introductory paragraphs, pull quotes, and UI labels where a little personality helps.

**JUST Sans Light** carries all long-form text: paragraphs, lists, form help, footers.

```css
--headline:'Grift Black',Impact,'Arial Black',system-ui,sans-serif;
--sub:'Juniper','Helvetica Neue',Arial,sans-serif;
--body:'JUST Sans Light',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;

--lead-headline:0.85;  --lead-sub:1.2;  --lead-body:1.2;  --track-headline:0.01em;
```

## Weights

Each family ships **one cut**. Declare the weight each file actually contains and never ask for another, or the browser will synthesise a fake bold.

| Font | Real weight | Declare |
|---|---|---|
| Grift Black | 900 | `font-weight:900` on `@font-face` **and** on every headline selector |
| Juniper Regular | 400 | leave at default |
| JUST Sans Light | 300 | leave at default |

Grift Black is the only face with a bold cut. Never put `font-weight:500`+ on anything set in Juniper or JUST Sans Light.

## Missing glyphs

Checked across all three files.

| Glyph | Grift Black | Juniper | JUST Sans Light |
|---|---|---|---|
| em dash — | yes | yes | yes |
| en dash – | yes | yes | yes |
| middot · | yes | **missing** | yes |
| curly quotes ‘ ’ “ ” | yes | yes | yes |
| heart ♥ | **missing** | **missing** | **missing** |
| tick ✓ | **missing** | **missing** | **missing** |

Grift Black is a much fuller family than the Bricklyn it replaces (460 glyphs against 201), so headline copy is no longer restricted – dashes and middots are all available. Two constraints remain:

- **Juniper has no middot.** The basket line ("3 places – A$150") is Juniper-set, so it uses an en dash. Don't reintroduce a `·` in Juniper copy.
- **No font has a heart or tick.** The heart on anonymous squares and the tick on the confirmation screen are inline SVG (`HEART`, `TICK` constants), not characters. Every font stack also ends in a system fallback so any stray glyph falls back per-glyph rather than rendering as a blank box.

The wallet buttons read "Apple Pay" and "Google Pay" as words. When you wire up real Stripe Payment Request buttons, Stripe supplies its own compliant marks – use those and don't restyle them.

## Licensing

Confirm before launch: the fonts are served publicly from the site, which is webfont embedding and must be permitted by each licence. `fsType` embedding flags as shipped:

| Font | fsType | Meaning |
|---|---|---|
| Grift Black | 0 | Installable – least restrictive |
| JUST Sans Light | 0 | Installable |
| Juniper Regular | 4 | **Preview & print only** – the most restrictive of the three |

Juniper is the one to check. `fsType` is a hint rather than the licence itself, so the governing document is the EULA, but a preview-and-print flag is worth a direct question to the foundry before go-live.

## Accessibility note

The guide's 120% body leading is tighter than WCAG 1.4.8 (AAA), which asks for 1.5 in paragraph text, and JUST Sans Light is a light weight, which compounds it – relevant for older donors reading on a phone. The build follows the brand guide as specified. If the client approves a change, it is one line: `--lead-body:1.5`.
