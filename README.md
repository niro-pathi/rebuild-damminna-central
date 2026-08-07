# Rebuild Damminna Central

Donation site for the school sports ground at Damminna Central, Sri Lanka. 425 students, one square each, A$50 to fill a square. Run by an ACNC-registered Australian charity.

The grid is the product: it doubles as the progress meter, filling up visibly as squares are taken.

## Run it

No build step. Serve the folder over HTTP so the fonts load – opening `index.html` with `file://` will block them:

```bash
python3 -m http.server 8000
# http://localhost:8000
```

## Files

```
index.html          the whole front end – markup, styles, behaviour
fonts/              Grift Black, Juniper, JUST Sans Light (woff2 + woff)
CLAUDE.md           project memory – read before writing code
BRAND.md            colour, tints and typography reference
VOICE.md            tone of voice – read before writing any user-facing string
SETUP.md            GitHub, VS Code and Claude Code setup
.claude/commands/   /safeguard-check, /brand-check, /voice-check, /ship-check
```

## Status

Front-end prototype. Payments are simulated, student names and messages are invented sample data, and the budget figures are placeholders. See `CLAUDE.md` for what has to be true before this handles a real donation.
