# Feynman Diagram Drawing Skills

Turn any AI agent into a careful Feynman-diagram drafter. One skill that makes
agents draw diagrams a physicist accepts: correct vertices and fermion flow,
balanced geometry, clean labels, and a rendered image that was actually looked
at before the agent says "done".

Works with Claude Code, Codex, OpenCode, Cursor, DSH, WorkBuddy, and any client
that implements the Agent Skills open standard. Install with one command, or
use it as a Claude Code plugin marketplace.

```bash
npx skills add ammelsayed/feynman_diagram_drawing_skills
```

Requires Node 22.20+. Detects your installed agents and lets you pick where to
install.

## The problem this fixes

Ask an AI to draw a Feynman diagram and you get a plausible picture with an
impossible vertex, a box that is really a long rectangle, labels floating far
from their objects, an anti-top labelled as a top, and no check of the rendered
result. This skill is the procedure that prevents that. Not a vibe — a set of
checkable rules.

## What's inside

| Skill | Use it to | The hard part it enforces |
|---|---|---|
| `feynman-diagram` | Draw any Feynman diagram in Asymptote's `feynman` package | Physics validity, internal/group symmetry, label semantics and placement, mandatory visual auditing |

### The four rules (summary)

1. **Physics correctness** — only vertices valid in the requested theory (a
   VVHH contact is 4-point with no internal line; `V→HH` is rejected in the SM
   but may be valid in extended models, e.g. charged-Higgs pairs). Closed
   fermion loops use the requested quark flavor, and the antiquark label is
   derived from the actual arrow flow, not a fixed example geometry. Consistent
   notation (`H` everywhere).
2. **Internal symmetry** — square loops, equal-length parallel same-role lines,
   symmetric fan-outs, and *mirrored label pairs* with equal gaps.
3. **Group symmetry** — diagrams of one family share the exact external
   geometry and canvas; only the interior changes between panels.
4. **Label semantics and placement** — external labels at line endpoints,
   mediators at line midpoints, couplings near their vertices. The *whole glyph*
   (tails/subscripts included) must be clear; pick the lowest object-density
   placement; check proximity separately from symmetry.

## Install

Any agent, one command:

```bash
npx skills add ammelsayed/feynman_diagram_drawing_skills
```

Claude Code, as a plugin marketplace:

```
/plugin marketplace add ammelsayed/feynman_diagram_drawing_skills
/plugin install feynman-diagram-drawing-skills@feynman-diagram-drawing-skills
```

Then `/feynman-diagram-drawing-skills:feynman-diagram`.

Shell installer, every agent at once:

macOS / Linux / WSL:

```bash
curl -fsSL https://raw.githubusercontent.com/ammelsayed/feynman_diagram_drawing_skills/main/install.sh | bash
```

Windows:

```powershell
irm https://raw.githubusercontent.com/ammelsayed/feynman_diagram_drawing_skills/main/install.ps1 | iex
```

The installer writes only into agents that exist on your machine, and supports
`--dry-run` / `-DryRun` and `--uninstall` / `-Uninstall`.

Manual:

```bash
git clone https://github.com/ammelsayed/feynman_diagram_drawing_skills
cp -R feynman_diagram_drawing_skills/skills/* ~/.claude/skills/
```

| Agent | Directory |
|---|---|
| Claude Code | `~/.claude/skills/` |
| Codex | `~/.codex/skills/` |
| OpenCode | `~/.config/opencode/skills/` or `~/.claude/skills/` |
| Cursor | `~/.cursor/skills/` |
| zcode | `~/.zcode/skills/` |
| DSH | `~/.dsh/skills/` |
| WorkBuddy | `~/.workbuddy/skills/` |
| Any Agent Skills client | `~/.agents/skills/` |

## Layout

```
feynman_diagram_drawing_skills/
├── .claude-plugin/
│   ├── plugin.json           # plugin manifest
│   └── marketplace.json      # marketplace catalog
├── .github/workflows/
│   └── validate.yml          # CI: skill spec + manifests + installer syntax
├── skills/
│   └── feynman-diagram/
│       └── SKILL.md          # the complete rule set
├── scripts/
│   └── validate_skills.py    # spec checker, no dependencies
├── install.sh
├── install.ps1
└── LICENSE
```

Skills use progressive disclosure: only the name and description load at
startup. The body loads when the task matches.

## Verify

```bash
python3 scripts/validate_skills.py
```

```
ok    feynman-diagram

All 1 skills valid
```

Checks name format, name/directory match, description length, frontmatter
delimiters, and non-empty body — the things a client rejects on.

## Contributing

Issues and PRs welcome. If you add a skill:

- Put it in `skills/<name>/SKILL.md` — name must match the directory.
- Run `python3 scripts/validate_skills.py`.
- Keep the description under 1024 characters and make it say when to use the
  skill, not just what it does — that is the only text the agent sees before
  deciding.

## License

MIT. Use it, fork it, ship it.
