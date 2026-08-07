# Setup – pushing to GitHub and working in VS Code

Repo: https://github.com/niro-pathi/rebuild-damminna-central

## 1. Get the code into the repo

Unzip the bundle, then from inside that folder:

**If the GitHub repo is empty** (no commits yet):

```bash
git init
git branch -M main
git add .
git commit -m "Rebuild Damminna Central: prototype, brand system, voice guide"
git remote add origin https://github.com/niro-pathi/rebuild-damminna-central.git
git push -u origin main
```

**If the repo already has commits** (a README from setup, say):

```bash
git init
git branch -M main
git remote add origin https://github.com/niro-pathi/rebuild-damminna-central.git
git fetch origin
git reset --soft origin/main      # adopt existing history, keep these files staged
git add .
git commit -m "Rebuild Damminna Central: prototype, brand system, voice guide"
git push -u origin main
```

If you'd rather not think about it, clone first and copy the files in:

```bash
git clone https://github.com/niro-pathi/rebuild-damminna-central.git
cd rebuild-damminna-central
# copy everything from the bundle in here, then:
git add . && git commit -m "Initial site and brand system" && git push
```

## 2. Open in VS Code

```bash
code .
```

VS Code will prompt to install the recommended extensions from `.vscode/extensions.json` – Claude Code, Prettier, and the axe accessibility linter.

## 3. Run the site

There's no build step, but the fonts won't load over `file://`. Serve it:

```bash
python3 -m http.server 8000
```

Then open http://localhost:8000.

## 4. Claude Code

`CLAUDE.md` sits at the repo root, so Claude Code loads it as project memory automatically at the start of every session – the safeguarding rules, payment rules, brand tokens and voice rules travel with the codebase. Run `/memory` to see what's loaded.

Four project slash commands are committed in `.claude/commands/`:

| Command | What it does |
|---|---|
| `/safeguard-check` | Audits the working tree for child-safeguarding violations. Run this before every commit that touches data flow |
| `/brand-check` | Colour tokens, tints, font weights, em dashes, contrast |
| `/voice-check` | Copy against `VOICE.md`, including flagging unverified factual claims |
| `/ship-check` | Runs all three, then the rest of the PR checklist |

`.claude/settings.json` pre-approves read-only tools and the safe git commands so you're not clicking through permission prompts. Adjust with `/permissions`. Personal overrides go in `.claude/settings.local.json`, which is gitignored.

**A note on how to use `/safeguard-check`.** The rules in `CLAUDE.md` are written as blockers rather than preferences, and the command is told to report violations without softening them. That's deliberate: the most likely way this project causes harm isn't a dramatic breach, it's a small reasonable-sounding feature request – "can donors filter by age?", "can we show the child's photo to their sponsor?" – implemented helpfully by someone who didn't have the context. The file is that context.

## 5. Before this handles a real donation

`CLAUDE.md` has the full list. The short version: there is no backend yet. Payments are simulated, student data is invented sample content, and the budget figures are placeholders. Nothing here should be pointed at a real Stripe key until the server-side pieces in the architecture section exist.
