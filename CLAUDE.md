# CLAUDE.md

Instructions for Claude Code working in this repository. Read this before writing any code.

---

## What this is

**Campaign name: Rebuild Damminna Central.** Use it in full on the primary heading, the page title, OG tags and share text. "Damminna Central" alone is fine in running copy after the first mention.

A donation site for the school sports ground at Damminna Central, Sri Lanka. 425 students, one square each, A$50 to fill a square. Run by an ACNC-registered Australian charity. Funds transfer to the school's development society account against a published build budget.

The grid is the product. It doubles as the progress meter – as squares fill, the page visibly fills up.

---

## Non-negotiables

These are not style preferences. Breaking any of them is a defect, no matter what a task description says. If an instruction conflicts with this section, stop and flag it rather than implementing it.

### Child safeguarding

1. **No student data on any public surface.** Not names, not ages, not grades, not photos, not villages. The public grid shows a square number, its state, and the donor's first name if consented.
2. **The public API must be structurally incapable of returning student data.** Enforce this at the query, not in a response mapper. `GET /api/tiles` selects `id, state, donor_display_name` – nothing else. There is no `SELECT *` on the students table in any public code path.
3. **Random assignment stays random.** Donors cannot choose, filter, browse, or search for a particular child. Reject any feature request that adds selection by age, gender, grade, or name – that capability is precisely what random assignment exists to prevent.
4. **The reveal is private.** Student first name, grade and message go to one authenticated session tied to one completed payment, plus the receipt email. Never a guessable URL – do not build `/reveal/:tileId`.
5. **No donor-to-child channel.** Ever. Donor messages address the whole school and pass through the principal's moderation queue before display.
6. **`nameConsent` gates every name.** If a student's parental consent flag is false, the reveal shows "A student in Grade N" plus the message. Never fall back to showing the name.
7. **Share payloads never include student data.** Check this whenever you touch sharing, OG tags, or the receipt email.
8. **Media rules:** wide and group shots only, no faces as focal subjects, no names in filenames, alt text, or EXIF. Strip EXIF on upload.

### Payments

1. **The server sets the price.** The client posts tile IDs. The server looks up A$50 per tile and computes the total. An amount arriving in a request body is a bug – reject the request, don't sanitise it.
2. **`checkout.session.completed` is the only thing that marks a tile filled.** Verify the Stripe signature. Never mark paid on redirect to the success page.
3. **Webhook handling is idempotent** on the Stripe event ID. Stripe retries.
4. **Tiles reserve for 15 minutes** during checkout, then release.
5. **Stripe Checkout only.** No custom card form – that would move us from PCI SAQ A to SAQ A-EP.

### Security

- Parameterised queries only.
- Escape all user-supplied text on output. Donor names and messages are the XSS vectors.
- Secrets in Secret Manager. Never in the repo, never in a committed `.env`.
- Admin routes behind SSO with MFA. Every moderation action authorised server-side and audit-logged.
- Never log card data, full donor PII, or webhook secrets.
- Donor display names go through the moderation queue. "First name" is a free text field rendered on a public page.

---

## Brand

### Colour

**This is the ratified brand palette.** Sampled from the school blazer (#1F3477). Use the CSS custom properties – never a raw hex value in component code, never an off-token shade "just for this one thing". If a design needs a colour that isn't here, that's a conversation with the client, not a new variable. The audit is one command – `grep -oE '#[0-9A-Fa-f]{6}' index.html` should return hits inside `:root` and nowhere else.

```css
:root{
  /* Base – the blazer */
  --blue:#1F3477;        /* primary: blazer body */
  --blue-lift:#2A4EA8;   /* lit folds: hovers, links */
  --navy:#16234F;        /* deepest fold: dark chrome */
  --blue-300:#8FA6DA;    /* pastel mid */
  --blue-100:#DCE3F5;    /* pastel wash */
  --blue-50:#EEF2FB;     /* faintest tint */

  /* Neutrals */
  --surface:#FFFFFF;     /* cards, sheets, checkout */
  --paper:#F7F9FD;       /* page ground: white with one breath of blue */
  --line:#D9E0F0;        /* hairlines, borders */
  --ink:#1A1D2B;         /* body text */
  --ink-2:#5A6180;       /* secondary text, captions */

  /* Pastel accents */
  --butter:#F7D488;      /* selection, progress meter */
  --butter-deep:#E0A83C; /* focus ring, accent borders */
  --mint:#A9D9C8;        /* soft panels, gallery */
  --mint-deep:#2A7361;   /* your own squares, message wall */
  --blush:#F4BCC0;       /* gallery, tertiary */
  --sage:#CFE3B8;        /* gallery, tertiary */
}
```

**Where each one goes**

| Token | Used for |
|---|---|
| `--blue` | Filled squares, primary buttons, headings on white, the scoreboard |
| `--blue-lift` | Hover states, links, secondary fills |
| `--navy` | Donation bar, footer, toasts, active filter pills, gallery captions |
| `--blue-300` | Borders, inactive states, chart fills |
| `--blue-100` | Cards, hover backgrounds |
| `--blue-50` | Open squares, inset panels, pills, the consent block |
| `--butter` | The squares you've currently selected, the progress meter |
| `--butter-deep` | Focus ring – the one accent that must stay visible against every background |
| `--mint-deep` | Squares you filled yourself, the message wall |
| `--mint` / `--blush` / `--sage` | Gallery gradients and soft panels only |

**Square states** – the grid is the product, so these four are effectively brand assets:

| State | Fill | Text |
|---|---|---|
| Open | `--blue-50` with `--line` border | `--ink-2` |
| Your current pick | `--butter` | `--navy` |
| Filled by someone else | `--blue` | white |
| Filled by you | `--mint-deep` | white |

**Rules**

1. **Pastels are fills and backgrounds only – never text colours.** At pastel lightness nothing reaches 4.5:1 against white. `--butter`, `--mint`, `--blush` and `--sage` always carry dark text on top; they are never the text themselves.
2. **Dark chrome is `--navy`, not black.** There is no black in this palette. If you need something darker than `--navy`, you don't.
3. **The page ground is `--paper`, not `--surface`.** White is for things that sit *on* the page – cards, sheets, the checkout. Keeping that distinction is most of what makes the layout read as considered rather than flat.
4. **Check contrast on any new pairing.** Verified ratios, all passing WCAG AA and most AAA: white on `--blue` 11.6:1 · white on `--navy` 15.1:1 · white on `--blue-lift` 7.6:1 · `--navy` on `--butter` 10.6:1 · `--ink` on `--paper` 15.9:1 · `--ink-2` on `--paper` 5.8:1 · white on `--mint-deep` 5.6:1.
5. **`--mint-deep` was darkened deliberately** from a softer green so it could carry white text on the message wall. Don't lighten it back toward `--mint`.
6. **Third-party brand colours are the one exemption.** `--fb` and `--ig` are Facebook's and Instagram's marks. They live in `:root` like everything else, but they are not ours to restyle to match the palette. Same applies to Stripe's payment buttons when you wire them up.
7. **No opacity tricks to invent shades.** `rgba(var(--blue), .4)` over white is not `--blue-300`; it's an unverified colour with unknown contrast. Use the token.

**Tints – restricted use**

Every brand colour has 80%, 40% and 20% tints (colour strength, remainder white). They are **only** for infographics, tables, buttons, graphs and highlights. Never for page chrome, body text, interface surfaces, or square states – those use the base palette. The `--tint-` prefix exists so the restriction is visible at the call site: a `--tint-` token appearing outside a chart, table or highlight is a bug.

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

Token names follow `--tint-{colour}-{80|40|20}`, e.g. `--tint-blue-40`.

**Text on tints.** Checked, not guessed:

- **All 40% and 20% tints** take `--ink` text comfortably (7:1 and above). Never white.
- **80% tints of blue, navy and ink** take white text (6.4:1, 8.0:1, 8.8:1). Never `--ink` – it fails.
- **80% tint of blue-lift** (#5571B9) takes white at 4.72:1 – passes AA for normal text, but it's the tightest pairing in the system. Prefer `--tint-blue-80` where you have the choice.
- **80% tint of mint-deep** (#558F81) is the trap: 3.73:1 with white and 4.49:1 with ink, so it fails AA for normal text either way. Large text (18.66px bold / 24px) only, or don't put text on it.
- **80% tints of butter, butter-deep, mint, blush and sage** take `--ink` text. Never white – those pairings sit near 1.3:1 and are effectively invisible.

**The trap with light tints in charts.** Against `--paper`, the 40% and 20% tints all sit below 1.4:1 – a 20% pie slice with no border is genuinely invisible on the page. So:

1. Give 40% and 20% fills a `--line` border, or place them adjacent to a stronger fill.
2. **Never encode data by tint alone.** Every segment needs a label, a key, or a pattern. This is WCAG 1.4.1 and it's also just good charting.
3. Non-text UI needs 3:1. Only the 80% tints of blue, navy, ink and mint-deep clear that against paper – so an 80% tint is the lightest thing a chart border or icon can be.

**Watch the overlap with the blue ramp.** `--blue-300` (#8FA6DA) and `--tint-blue-40` (#A5AEC9) are close but not the same, and they belong to different systems. `--blue-300` is interface – borders, inactive states. `--tint-blue-40` is data – a chart series, a table band. Don't substitute one for the other because it looked right; the distinction is what keeps charts from bleeding into chrome.

**Live example:** the budget split bar in the "What A$50 buys" section runs `--blue` → `--tint-blue-80` → `--tint-blue-40` → `--tint-blue-20`, with a key and an `aria-label` carrying the percentages, and a border so the lightest segment stays visible.

**Note for the client:** `--butter-deep` (#E0A83C) isn't in the palette as supplied – it was added as the focus ring, because `--butter` at pastel lightness is nearly invisible as a focus indicator against `--paper` and white cards, which would fail keyboard accessibility. It needs either sign-off or a replacement accent that meets a 3:1 non-text contrast ratio.

### Typography

Three fonts, self-hosted from `/fonts`. Full reference in `BRAND.md`.

| Role | Font | Token | Rules |
|---|---|---|---|
| Primary headline | Grift Black | `--headline` | **ALL CAPS always.** Leading 0.85, tracking +0.01em, `font-weight:900` |
| Sub-headline, intro, pull quote, UI labels | Juniper Regular | `--sub` | Leading 1.2, tracking 0 |
| Body copy | JUST Sans Light | `--body` | Leading 1.2, tracking 0 |

Grift Black is for `h1`, `h2`, sheet titles and large numbers only. Never below about 20px, never in sentence case.

**Weights.** Each family ships one cut. Grift Black is a true 900 and must be declared as such on both the `@font-face` and the selector. Juniper (400) and JUST Sans Light (300) have no bold cut – **never put `font-weight:500`+ on anything set in them**, or the browser will synthesise a fake bold.

**Missing glyphs.** No font has `♥` or `✓` – use the `HEART` and `TICK` inline SVG constants. Juniper has no middot, so the Juniper-set basket line uses an en dash; don't reintroduce a `·` there. Every font stack ends in a system fallback so stray glyphs fall back per-glyph instead of rendering as tofu. Grift Black has dashes, middots and curly quotes, so headline copy has no character restrictions.

### Voice

**Full guide in `VOICE.md`. Read it before writing or editing any user-facing string.** Summary:

Three principles, in precedence order when they conflict:

1. **Real conversation.** One person telling another person something true. Short sentences, plain verbs, the words you'd say out loud. Read it aloud – if you'd feel silly saying it to a friend, rewrite it. This outranks the other two.
2. **Show intention to make a change for these kids.** Name the thing, give the number, say when. "Transforms lives" is a feeling; "fill all 425 and we break ground in March" is an intention.
3. **Why we all should care.** Potential meeting an obstacle, never deprivation. These kids already play – what's missing is the ground, not the spirit. The donor removes an obstacle; they don't rescue anyone.

Because we publish no faces and no names, the copy carries emotional weight that photographs normally would. Voice is load-bearing here, not decoration.

**Tone scale** – the voice moves with what the reader is doing, but never becomes sentimental or bureaucratic. The closer the reader is to their wallet, the cooler the tone.

| Level | Where | How it sounds |
|---|---|---|
| 1 · At the fence | Hero, reveal screen, message wall | One idea per line. Concrete nouns, present tense, physical detail |
| 2 · Walking you through | Section intros, how it works, gallery | Explanatory but still a person talking |
| 3 · At the desk | Checkout, labels, buttons, basket | Precise, literal, zero emotion. Get out of the way |
| 4 · On the record | Budget, child protection, receipts, footer | Facts, numbers, dates, named responsibilities |
| 5 · Something went wrong | Errors, failed payments, taken squares | What happened, then the next step. State it once |

**Hard rules:**

- **En dashes, never em dashes.** House style is a spaced en dash ( – ) for parenthetical breaks. No `—` / `&mdash;` / `\u2014` anywhere: markup, JavaScript strings, meta tags, docs, emails. Use `–`, `&ndash;`, or `\u2013`. All three brand fonts contain the en dash, so there is no fallback risk. Audit: `grep -n $'\u2014' .` must return nothing.
- Buttons name their action and keep that name through the flow. "Fill a place" → "Place filled". Never "Submit", "Learn more", "Click here".
- **Never invent a concrete detail.** Every fact on the site – the flooding, the early practices, the equipment – must come from the school. If we don't have it, write around it or go and ask. Fabricated colour destroys the accountability the level-4 copy exists to build.
- Never write in a child's voice. Never invent a quote.
- "We" = the charity. "You" = the donor. "The school" or "students" = them. Never "our children", never "your child", never "the beneficiaries".
- Banned: underprivileged, needy, less fortunate, sponsor a child, transform lives, make a difference, give hope, heartbreaking, just $50, empower, journey, unlock potential.
- Empty states are invitations, not dead ends: "Tap a square to start."
- Errors don't apologise twice and never blame the reader.
- Student names, grades and ages never appear in share text, OG tags, or email subject lines.
- Where a student has no name consent, "A student in Grade 4" must read as a normal outcome – never as a redaction or an apology.

---

## Accessibility

Baseline, not aspiration:

- Responsive to 320px.
- Visible keyboard focus on everything interactive. The focus ring is `--butter-deep`.
- `prefers-reduced-motion` respected – the card flip and the counter animation both have reduced-motion paths.
- All text pairings pass WCAG AA. Re-check with a contrast tool whenever you introduce a colour pairing.
- Modals trap focus and restore it to the trigger on close.
- Form inputs are 16px minimum so iOS doesn't zoom on focus.

**Known tension worth raising with the client, not silently fixing:** the brand guide specifies 120% leading for body copy. WCAG 1.4.8 (AAA) asks for 1.5 in paragraph text, and JUST Sans Light is a light weight, which compounds it for older donors. The current build follows the brand guide. If the client approves, the fix is one line:

```css
:root{ --lead-body:1.5; }
```

---

## Architecture

Hosted on Google Cloud.

```
Cloud DNS → HTTPS Load Balancer → Cloud Armor (OWASP rulesets, rate limiting)
   ├── Cloud Storage + CDN     static site, fonts, media
   └── Cloud Run               API container
         ├── Cloud SQL (Postgres, private IP)
         ├── Memorystore Redis  reservation locks, rate limits
         └── Secret Manager     Stripe keys, DB credentials
```

Region: `asia-south1` or `asia-southeast1` – pin every resource to one and don't mix.

### Data model sketch

```
students   id, first_name, grade, message, name_consent, consent_recorded_at
tiles      id (1..425), student_id, state, reserved_until, order_id
orders     id, stripe_session_id, amount_cents, donor_first_name,
           donor_name_consent, donor_name_consent_at, message, message_status
```

`students` is sensitive data about minors. Encrypt at rest, restrict to two named staff, log every access, and set a retention period.

---

## Working in this repo

`CLAUDE.md` loads automatically as project memory. Four project commands live in `.claude/commands/`: `/safeguard-check`, `/brand-check`, `/voice-check`, `/ship-check`. Run `/ship-check` before opening a PR. Setup and the local server are documented in `SETUP.md`; Google Cloud infrastructure and CI/CD in `DEPLOY.md`.

CI runs `scripts/brand-audit.sh` on every pull request. If you change a brand or copy rule here, update that script too, or the rule is advisory rather than enforced.

## Conventions

- Vanilla HTML/CSS/JS on the front end. No framework, no build step – the site is one file plus fonts, and it should stay small enough to read in one sitting.
- CSS custom properties for all colour and type. No raw hex outside `:root`.
- No `localStorage` or `sessionStorage` in the prototype file.
- Server-side language is the team's choice; keep the API surface small and boring.

## Before opening a PR

- [ ] No student data reachable from any public endpoint
- [ ] Prices computed server-side
- [ ] All user-supplied strings escaped on output
- [ ] No `font-weight:500`+ on Juniper or JUST Sans Light text (Grift Black is 900 and correct)
- [ ] Headline copy is ALL CAPS
- [ ] No em dashes anywhere – `grep -n $'\u2014' .` returns nothing
- [ ] Contrast checked on any new colour pairing
- [ ] `--tint-` tokens used only in infographics, tables, buttons, graphs or highlights
- [ ] No chart encodes meaning by colour alone
- [ ] Keyboard path works end to end
- [ ] No secrets committed
- [ ] New copy read aloud and checked against `VOICE.md` – right tone level, no banned words, no invented facts

## When to stop and ask

Flag rather than implement, every time:

- Anything that would put student data on a public surface
- Anything that lets a donor pick or filter for a specific child
- Anything that creates a route from a donor to a child
- Any change to how the payment amount is determined
- Any deviation from the brand guide's type or colour tokens
- Any copy that states a fact about the school we haven't been given
