# Feynman Diagram Drawing Skills

Turn any AI agent into a careful Feynman-diagram drafter. One skill that makes
agents draw diagrams a physicist accepts: correct vertices and fermion flow,
balanced geometry and clean labels, and the figure looked at before the agent
says "done".

Works with Claude Code, Codex, OpenCode, Cursor, DSH, WorkBuddy, and any client
that implements the Agent Skills open standard. It is a set of instructions to
copy into the folder your agent reads skills from.

```bash
npx skills add ammelsayed/feynman_diagram_drawing_skills
```

`npx skills add` and the plugin marketplace are third-party clients; they copy
the same directory into the folders those clients read.

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

1. **Physics correctness** — only vertices that exist in the theory the user
   asked for. A quartic contact (VVHH, HHHH) is a genuine 4-point vertex with
   **no** internal line; a `V→HH` 3-point vertex is theory-dependent (absent in
   the SM for two neutral Higgses, genuine in extended Higgs sectors), so check
   the model before rejecting or drawing it. Closed fermion loops carry one
   continuous arrow flow and take the requested quark flavor: arrows carry
   fermion-number flow, so the segment running back against the flow the loop
   entered with is the antiquark — a loop with no external fermion takes a
   consistent convention — never a fixed "always top" assumption.
   Consistent notation (`H` everywhere).
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

By hand, from the checkout root:

```bash
mkdir -p ~/.claude/skills
dest=~/.claude/skills/feynman-diagram
if [ -d "$dest" ]; then
  echo "a copy is already there; move it aside and run this again"
else
  stage=$(mktemp -d ~/.claude/skills/.staging.XXXXXX)
  cp -R skills/feynman-diagram/. "$stage"/
  mv -T "$stage" "$dest" || echo "could not move $stage into place"
fi
```

The copy is assembled in a staging directory and moved into place in one
step, so an interrupted copy leaves nothing at the destination. It refuses to
touch an existing `feynman-diagram` directory, so an edited skill is never
overwritten, and it never ends the shell it is pasted into. `git clone`
itself makes a checkout wherever you run it; nothing else outside
`~/.claude/skills/` is written.

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
│   └── validate.yml          # CI: skill spec + manifests
├── skills/
│   └── feynman-diagram/
│       └── SKILL.md          # the complete rule set
└── LICENSE
```

Skills use progressive disclosure: only the name and description load at
startup. The body loads when the task matches.

## Verify

CI checks the same things a client rejects on: that `SKILL.md` is a regular,
non-empty file, that its front matter is closed, that its `name` matches the
directory, that the description is present and under 1024 characters, that
both plugin manifests parse, and that the marketplace advertises exactly the
skills on disk. Run the workflow's steps locally with `act`, or read them in
`.github/workflows/validate.yml`.

## Contributing

Issues and PRs welcome. If you add a skill:

- Put it in `skills/<name>/SKILL.md` — name must match the directory.
- CI validates the file; nothing else needs to run.
- Keep the description under 1024 characters and make it say when to use the
  skill, not just what it does — that is the only text the agent sees before
  deciding.

## License

MIT. Use it, fork it, ship it.
