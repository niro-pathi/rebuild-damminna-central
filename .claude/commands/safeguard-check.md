---
description: Audit the change for child-safeguarding violations before commit
---

Check the current working tree against the child safeguarding rules in `CLAUDE.md`. This is the highest-priority review on this project – report any hit as a blocker, not a suggestion.

1. `git diff` to see what changed.
2. Trace every code path that could put student data on a public surface. Confirm no public endpoint, template, share payload, OG tag, email subject, or client-side variable can carry a student's name, age, grade, photo or village.
3. Confirm student data is filtered at the **query**, not in a response mapper.
4. Confirm no new way for a donor to choose, filter, browse or search for a specific child.
5. Confirm the reveal is still gated on an authenticated session tied to a completed payment, with no guessable URL.
6. Confirm `nameConsent` still gates every name, with "A student in Grade N" as the fallback.
7. Confirm no donor-to-child communication channel has been introduced.

Report findings as a list. If everything passes, say so in one line. Do not soften a violation.
