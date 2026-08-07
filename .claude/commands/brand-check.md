---
description: Check colour and typography against the ratified brand guide
---

Audit the working tree against the colour and typography rules in `CLAUDE.md` and `BRAND.md`.

1. `grep -oE '#[0-9A-Fa-f]{6}' index.html` – every hit must be inside `:root`. Report any raw hex in component code.
2. Confirm no `--tint-` token is used outside an infographic, table, button, graph or highlight.
3. Confirm no `font-weight:500` or above on anything set in Juniper or JUST Sans Light. Grift Black at 900 is correct.
4. Confirm headline copy is ALL CAPS and set in `--headline`.
5. `grep -n $'\u2014' .` – must return nothing. Em dashes are banned; use en dashes.
6. For any new colour pairing, compute the WCAG contrast ratio and state it. Text needs 4.5:1, non-text UI needs 3:1.
7. Confirm no chart encodes meaning by colour or tint alone.

List each check with a pass or fail and the evidence.
