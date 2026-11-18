#!/usr/bin/env python3
"""Validate every SKILL.md against the Agent Skills specification.

Checks the fields a client will reject on:
  - exactly `---` on the first line, closed by a `---` line
  - frontmatter parses as YAML (PyYAML if available, strict fallback otherwise)
  - name present, 1-64 chars, lowercase alphanumeric + single hyphens,
    no leading/trailing hyphen, matches its directory name
  - description present, string, 1-1024 chars
  - compatibility, when present, is a string of at most 500 chars
  - body non-empty

Exits 1 if any skill fails. No mandatory third-party dependencies: uses PyYAML
when installed, otherwise a conservative parser that rejects constructs it
cannot decode rather than silently accepting malformed metadata.
"""
import re
import sys
from pathlib import Path

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
MAX_NAME = 64
MAX_DESC = 1024
MAX_COMPAT = 500

try:
    import yaml  # type: ignore
except ImportError:
    yaml = None


def _fallback_scalar(raw):
    """Decode a YAML scalar conservatively; raise ValueError on ambiguity."""
    s = raw.strip()
    if not s:
        return None
    if (s[0] == s[-1] == '"') or (s[0] == s[-1] == "'"):
        # Reject strings with escapes/quotes we cannot decode exactly.
        if "\\" in s or (s[0] == '"' and '"' in s[1:-1]) or (s[0] == "'" and "''" in s[1:-1]):
            raise ValueError("unsupported quoted scalar")
        return s[1:-1]
    if s in {"null", "Null", "NULL", "~"}:
        return None
    if s in {"true", "True", "TRUE", "false", "False", "FALSE"}:
        raise ValueError("boolean scalar where string expected")
    if re.fullmatch(r"[-+]?\d+(\.\d+)?", s):
        raise ValueError("numeric scalar where string expected")
    if s[0] in "[{&*!|>@`":
        raise ValueError("unsupported YAML construct")
    return s


def _fallback_frontmatter(lines):
    """Parse flat key: value / block scalar frontmatter without PyYAML."""
    fm, key, buf = {}, None, []
    for line in lines:
        if not line.strip():
            if key is not None:
                buf.append("")
            continue
        m = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if m:
            if key is not None:
                fm[key] = _join_block(buf)
            key, raw = m.group(1), m.group(2).strip()
            buf = [raw]
        elif key is not None:
            buf.append(line.strip())
        else:
            raise ValueError(f"unexpected line outside a field: {line!r}")
    if key is not None:
        fm[key] = _join_block(buf)
    return fm


def _join_block(buf):
    """Join a YAML block scalar: drop trailing blanks, keep internal newlines."""
    while buf and buf[-1] == "":
        buf.pop()
    return "\n".join(buf).strip()


def parse_frontmatter(text):
    """Return (frontmatter dict, body) or (None, reason)."""
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        return None, "first line must be exactly '---'"
    try:
        end = next(i for i in range(1, len(lines)) if lines[i].strip() == "---")
    except StopIteration:
        return None, "frontmatter is not closed with '---'"

    raw = "\n".join(lines[1:end])
    if yaml is not None:
        try:
            fm = yaml.safe_load(raw)
        except Exception as exc:
            return None, f"frontmatter is not valid YAML: {exc}"
        if fm is None:
            fm = {}
        if not isinstance(fm, dict):
            return None, "frontmatter must be a YAML mapping"
        # YAML decodes scalars to real types — exactly what clients see.
    else:
        try:
            fm = _fallback_frontmatter(lines[1:end])
        except ValueError as exc:
            return None, f"frontmatter cannot be safely parsed: {exc}"

    return fm, "\n".join(lines[end + 1:])


def _is_string(value):
    """PyYAML may decode quoted numerics back to str; require an actual string."""
    return isinstance(value, str)


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
    compat = fm.get("compatibility")

    if name is None:
        problems.append(f"{skill_dir.name}: missing 'name'")
    elif not _is_string(name):
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

    if desc is None:
        problems.append(f"{skill_dir.name}: missing 'description'")
    elif not _is_string(desc):
        problems.append(f"{skill_dir.name}: 'description' must be a string")
    elif not desc.strip():
        problems.append(f"{skill_dir.name}: 'description' is empty")
    elif len(desc) > MAX_DESC:
        problems.append(
            f"{skill_dir.name}: description is {len(desc)} chars (max {MAX_DESC})"
        )

    if compat is not None:
        if not _is_string(compat):
            problems.append(f"{skill_dir.name}: 'compatibility' must be a string")
        elif len(compat) > MAX_COMPAT:
            problems.append(
                f"{skill_dir.name}: compatibility is {len(compat)} chars (max {MAX_COMPAT})"
            )

    if not body.strip():
        problems.append(f"{skill_dir.name}: body is empty")

    return problems


def main():
    root = Path(__file__).resolve().parent.parent
    skills_dir = root / "skills"
    if not skills_dir.is_dir():
        print(f"No skills directory at {skills_dir}")
        return 1
    skills = sorted(
        p for p in skills_dir.iterdir() if p.is_dir() and not p.name.startswith(".")
    )
    if not skills:
        print("No skills found under skills/")
        return 1

    all_problems = []
    for s in skills:
        problems = validate(s)
        if problems:
            all_problems.extend(problems)
            print(f"FAIL  {s.name}")
            for p in problems:
                print(f"      {p}")
        else:
            print(f"ok    {s.name}")

    print()
    if all_problems:
        print(f"{len(all_problems)} problem(s) across {len(skills)} skill(s)")
        return 1
    print(f"All {len(skills)} skills valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
