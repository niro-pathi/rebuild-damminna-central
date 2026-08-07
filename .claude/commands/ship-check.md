---
description: Run the full pre-PR checklist
---

Work through the "Before opening a PR" checklist in `CLAUDE.md` against the current working tree.

Run `/safeguard-check`, `/brand-check` and `/voice-check` first, then verify the remaining items:

- Prices computed server-side; no amount accepted from a request body
- All user-supplied strings escaped on output
- Keyboard path works end to end; focus visible and restored on modal close
- `prefers-reduced-motion` respected by any new animation
- No secrets committed; `git diff --cached` clean of credentials

Finish with a single verdict line: ready, or blocked with the reasons.
