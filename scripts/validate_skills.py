#!/usr/bin/env python3
"""Validate every SKILL.md against the Agent Skills specification.

Uses PyYAML (installed by CI) as the single source of truth for frontmatter
parsing, so validation matches what real clients decode. There is no custom
fallback parser: a missing dependency is a hard error, never a silent
approximation.

Checks:
  - exactly `---` on the first line, closed by a `---` line
  - frontmatter parses as a YAML mapping with no duplicate keys
  - name: string, 1-64 chars, lowercase alphanumeric + single hyphens,
    matches the directory name
  - description: string, 1-1024 chars
  - compatibility (when present): string, at most 500 chars
  - non-empty body

Exits 1 if any skill fails.
"""
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("PyYAML is required: python3 -m pip install pyyaml", file=sys.stderr)
    sys.exit(2)

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
MAX_NAME = 64
MAX_DESC = 1024
MAX_COMPAT = 500


class StrictLoader(yaml.SafeLoader):
    """SafeLoader with duplicate-key rejection and YAML 1.2-ish scalars."""


def _no_duplicates(loader, node, deep=False):
    mapping = {}
    for key_node, value_node in node.value:
        # YAML merge key is a scalar tagged `<<` (alias to a mapping or list of
        # mappings). Flatten its inherited entries before duplicate checking.
        if isinstance(key_node, yaml.nodes.ScalarNode) and key_node.tag == 'tag:yaml.org,2002:merge':
            inherited = loader.construct_object(value_node, deep=deep)
            sources = inherited if isinstance(inherited, list) else [inherited]
            for src in sources:
                if not isinstance(src, dict):
                    raise ValueError("merge source must be a mapping")
                for k, v in src.items():
                    if k in mapping:
                        raise ValueError(f"duplicate frontmatter key: {k}")
                    mapping[k] = v
            continue
        key = loader.construct_object(key_node, deep=deep)
        if key in mapping:
            raise ValueError(f"duplicate frontmatter key: {key}")
        mapping[key] = loader.construct_object(value_node, deep=deep)
    return mapping


StrictLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, _no_duplicates)

# YAML 1.2 booleans are only true/false; keep the resolver table so `null`,
# `~`, numbers, etc. still decode to their proper non-string types.
# Copy first so SafeLoader used elsewhere in the process is untouched.
StrictLoader.yaml_implicit_resolvers = {
    ch: [
        (tag, regexp)
        for tag, regexp in resolvers
        if not (tag == 'tag:yaml.org,2002:bool' and ch in
                ('y', 'Y', 'n', 'N', 'o', 'O'))
    ]
    for ch, resolvers in yaml.SafeLoader.yaml_implicit_resolvers.items()
}


def parse_frontmatter(text):
    """Return (frontmatter dict, body) or (None, reason)."""
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        return None, "first line must be exactly '---'"
    try:
        end = next(i for i in range(1, len(lines)) if lines[i] == "---")
    except StopIteration:
        return None, "frontmatter is not closed with '---'"

    raw = "\n".join(lines[1:end])
    try:
        fm = yaml.load(raw, Loader=StrictLoader)
    except Exception as exc:
        return None, f"frontmatter is not valid YAML: {exc}"
    if fm is None:
        fm = {}
    if not isinstance(fm, dict):
        return None, "frontmatter must be a YAML mapping"
    return fm, "\n".join(lines[end + 1:])


def validate(skill_dir: Path):
    problems = []
    skill_md = skill_dir / "SKILL.md"

    if not skill_md.is_file():
        return [f"{skill_dir.name}: no SKILL.md"]

    fm, body = parse_frontmatter(skill_md.read_text(encoding="utf-8"))
    if fm is None:
        return [f"{skill_dir.name}: {body}"]

    name = fm.get("name")
    desc = fm.get("description")

    if "name" not in fm:
        problems.append(f"{skill_dir.name}: missing 'name'")
    elif not isinstance(name, str):
        problems.append(f"{skill_dir.name}: 'name' must be a string")
    else:
        if len(name) > MAX_NAME:
            problems.append(f"{skill_dir.name}: name longer than {MAX_NAME} chars")
        if not NAME_RE.match(name):
            problems.append(
                f"{skill_dir.name}: name '{name}' must be lowercase alphanumeric "
                "with single hyphens, no leading/trailing hyphen"
            )
        if name != skill_dir.name:
            problems.append(
                f"{skill_dir.name}: name '{name}' must match directory name '{skill_dir.name}'"
            )

    if "description" not in fm:
        problems.append(f"{skill_dir.name}: missing 'description'")
    elif not isinstance(desc, str):
        problems.append(f"{skill_dir.name}: 'description' must be a string")
    elif not desc.strip():
        problems.append(f"{skill_dir.name}: 'description' is empty")
    elif len(desc) > MAX_DESC:
        problems.append(f"{skill_dir.name}: description is {len(desc)} chars (max {MAX_DESC})")

    if "compatibility" in fm:
        compat = fm["compatibility"]
        if not isinstance(compat, str):
            problems.append(f"{skill_dir.name}: 'compatibility' must be a string")
        elif len(compat) > MAX_COMPAT:
            problems.append(
                f"{skill_dir.name}: compatibility is {len(compat)} chars (max {MAX_COMPAT})"
            )

    if not body.strip():
        problems.append(f"{skill_dir.name}: body is empty")

    return problems


def main():
    skills_dir = Path(__file__).resolve().parent.parent / "skills"
    if not skills_dir.is_dir():
        print(f"No skills directory at {skills_dir}")
        return 1
    skills = sorted(
        p for p in skills_dir.iterdir() if p.is_dir() and not p.name.startswith(".")
    )
    if not skills:
        print("No skills found under skills/")
        return 1

    problems = []
    for s in skills:
        found = validate(s)
        if found:
            problems.extend(found)
            print(f"FAIL  {s.name}")
            for p in found:
                print(f"      {p}")
        else:
            print(f"ok    {s.name}")

    print()
    if problems:
        print(f"{len(problems)} problem(s) across {len(skills)} skill(s)")
        return 1
    print(f"All {len(skills)} skills valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
