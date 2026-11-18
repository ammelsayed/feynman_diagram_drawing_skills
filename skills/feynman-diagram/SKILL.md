---
name: feynman-diagram
description: >
  Draw publication-quality Feynman diagrams with Asymptote's feynman package.
  Use for "draw a Feynman diagram", "make an .asy diagram", "Feynman diagram in
  Asymptote", "compile this .asy", or any request involving particle-process
  diagrams. Covers physics validity (real vertices, fermion-flow quark vs
  antiquark), internal and group symmetry (ratios, shared external geometry),
  label semantics and placement (endpoint/midline/vertex, glyph bounding boxes,
  object density), a cross-platform compile workflow, and mandatory visual
  auditing. General rules for any process (ggF, VBF, Higgs self-coupling,
  QCD/EW), with examples — not tied to one diagram.
---

# Feynman diagrams in Asymptote

Goal: a plain-text Asymptote source file, and a PNG rendered from it, that a
physicist would accept for a publication — correct physics, balanced geometry,
clean labels, verified by looking at the rendered image.

## What to deliver

For each diagram: the Asymptote source, the PDF compiled from it, and a PNG
rasterized from that PDF at 220 dpi or more — all in the folder the user asked
for. The PDF and the PNG must be produced from the source you deliver, and the
PNG must be one you have looked at. How those files get made is the agent's
business: this skill is instructions only, ships no script, and suits any
editor, shell and toolchain on Linux, macOS, Windows or WSL.

- **Set up first.** Asymptote and its `feynman` package ship together in a
  standard installation. Confirm both are available before drawing; if they
  are not, install Asymptote for this platform or ask the user to. A web
  service is a last resort: it uploads the source, so use it only with the
  user's consent and never for unpublished material. With no engine available,
  deliver the source and say plainly that it was not compiled.
- **Write plain-text source, one file per diagram**, named for the diagram the
  user asked for. A name that contains a path separator, `..`, or a leading
  dash is a reason to ask which diagram is meant, not something to turn into a
  file name; hand every path to a tool as one whole argument.
- **Rasterize rather than bitmap.** A 220+ dpi raster of the vector page is
  what looks right on paper; any rasterizer the platform provides will do.
- **Verify, then deliver.** The PNG you show the user must have been produced
  from the delivered source and must look right: open it and zoom about three
  times into the crowded regions. If the source changed after the last render,
  or an older PNG sits beside it, render again and look again — never assume
  the file on disk is current. A diagram nobody looked at is not finished.
- **Say what happened.** Compilation and rasterization can fail; when they do,
  say so in one line instead of presenting an older or partial artifact as the
  result.

Safety: Asymptote executes the script it is given, including every file that
script imports or includes, so a source tree from elsewhere is executable
code, not data. Compile only source whose whole dependency set you or the user
wrote; when that cannot be established, decline in one line and explain why.

House style, matching the user's own scripts and blog: begin the source by
importing the `feynman` package, set the default pen to 0.75 line width, apply
the package defaults, and define one scale length of 50 units that every
coordinate is expressed against — helpers expand to that length along
directions at chosen angles, so the whole figure scales uniformly. Draw
fermions, gluons and vector bosons with the package's dedicated routines
`drawFermion`, `drawGluon`, `drawPhoton`, and scalars with `drawScalar` (a
Higgs line normally carries no arrow). Vertices are filled dots at heavy
line width; text is placed with the package's label routine, with mathematics
in dollar signs.

## The four rules

Apply every rule to every diagram, every time.

### Rule 1 — Physics correctness (first, before drawing anything)

Read the process and the **specific theory the user asked for**, then check
that every vertex exists in that theory. Do not draw a vertex that is not in
its Feynman rules.

- SM / κ-framework couplings: `ttg`, `ttH` (κ_t), `HHH` (κ_λ), `VVH` (κ_V),
  `VVHH` (κ_2V), `HHHH` (κ_4). Coupling labels belong to **their** vertex.
- A quartic contact (e.g. VVHH, HHHH) is a genuine **4-point vertex**: all four
  lines meet at one dot; there is **no** internal propagator inside it.
- Three-point vector–scalar couplings are theory-dependent. In the SM a
  `V→HH` vertex with two identical neutral Higgses does not exist — reject it.
  But in extended Higgs models (e.g. a charged Higgs pair coupling to Z or a
  `H⁺H⁻γ/Z` vertex) a vector couples to two scalars at a genuine 3-point
  vertex. Check the requested model before rejecting or drawing such a vertex;
  preserve valid vector–scalar vertices.
- A cascade (e.g. H\*→HH) is different: it has a real off-shell propagator from
  the production vertex to a separate decay vertex. Label the mediator on its
  line, and put each coupling at its own vertex (κ_V at production, κ_λ at the
  split).
- **Fermion flow and anti-particles.** A closed quark loop carries one
  continuous arrow flow. Label each segment with the **requested quark flavor**,
  not always top: if the loop is a bottom loop use `$b$` and `$\bar{b}$`, and so
  on for any flavor. Determine which segment is the antiquark **from the actual
  arrow direction**, not from a fixed vertex or edge position: following the
  arrows around the loop, the segment whose arrow runs from the outgoing side
  back into the incoming (e.g. gluon) vertex is the antiquark; the rest are
  quarks. In the common orientation where arrows run clockwise, that is the
  bottom edge of a box/pentagon or the lower diagonal of a triangle — but
  re-derive it from the arrows whenever the geometry differs. In FeynArts style
  an anti-top renders as `t~`. Split a fermion line at a Higgs attachment into
  two separate segments, each with its own arrow and label, not one line with
  one arrow.
- Consistent notation: label every Higgs `$H$` (uppercase) across all diagrams
  in a set; never mix `h` and `H`. Keep verbatim coupling notation (κ_t, κ_λ,
  λ_3, λ_4, …) consistent across the family.

### Rule 2 — Internal symmetry (within one diagram)

Beauty comes from balance. Design coordinates so equal things look equal.

- A "box" loop is a **square**: equal width and height. A pentagon/trapezoid
  should likewise be geometrically regular where the topology allows.
- External lines of the same role have **equal length** (all incoming gluons,
  all outgoing Higgses). Parallel lines stay parallel: if you make the incoming
  gluons horizontal, make the intermediate Higgs horizontal too and give all
  three the same length.
- Fan-outs are symmetric about the axis (upper and outgoing lower lines mirror
  each other in angle and length).
- **Labels obey the same symmetry.** A pair of labels (two V's, two κ_t's,
  top/bottom antiquark labels) go on *matching* sides and at *equal distances*
  from their objects. Never put one partner on the left and the other on the
  right; never leave one tight to its vertex while the other is shoved far
  away. If one of a pair must move to clear an obstacle, move its partner by
  the same magnitude toward the equivalent clear side.

### Rule 3 — Group symmetry (across a family of diagrams)

Diagrams of one process family (ggF set, VBF set, triple-Higgs set) share the
**exact same external geometry and canvas**: same incoming/outgoing endpoint
coordinates, same loop placement, same page size. Only the interior changes
(the loop shape, the mediator, the vertices) between panels. Two diagrams that
differ only by one Higgs attached on the incoming side must keep the outgoing
side — and its labels — identical, down to the coordinates.

### Rule 4 — Label semantics and placement

A label's meaning determines where it goes, and its **whole glyph area** — not
its center — must sit clear of everything.

- **Incoming particle**: at the *start* of its line (the free outer end).
  **Outgoing particle**: at the *end* of its line. Put these just outside the
  endpoint, a small gap away.
- **Mediator / internal line** (H\*, Z\*, V): at the *middle* of that line, just
  off it (perpendicular offset) so the glyph does not sit on the wiggle/dash.
  "Middle" means the line's midpoint along its length, not an arbitrary nearby
  empty spot.
- **Vertex label** (κ, λ): near its vertex, offset into a clear sector. Start
  around 0.12–0.15L from the dot in the house scale; go closer only if it would
  collide, farther only if the surrounding lines force it.
- **Whole-glyph check.** Labels like κ_λ have descenders/tails (the λ tail) that
  can cross a nearby line even when the letter's center looks clear. Zoom in
  (~3x) and check the entire bounding box — including subscripts and the
  antiquark bar — against every nearby line, dot, and other label. Move the
  whole label into the empty wedge until the entire glyph clears.
- **Object-density check.** Look at a ~1–2 cm circle around each candidate
  position and count what is nearby (lines, vertices, other labels). When a
  label has several valid placements that obey rules 1–3, choose the one with
  the lowest object density. Typical example: around a VVH vertex the space
  above the wavy V line is crowded by the outgoing quark/H line; the interior
  wedge or the opposite side is often emptier. Apply this to *every* label.
- **Proximity is not symmetry.** After any symmetry-driven move, re-check the
  actual gap to the object. A label symmetrically placed but far from its
  vertex still violates this rule.

## Review discipline (how to actually finish)

1. After **every** edit — however tiny — recompile, re-render, and re-inspect
   the PNG against all four rules before accepting the step. A change that
   breaks a rule is rejected: revert and try another placement. Never stack
   unreviewed edits.
2. When you restore a file from a backup or copy, **re-audit every label** in
   it: a backup can contain stale positions for labels unrelated to the fix at
   hand.
3. When the user teaches a rule or you find a bug, **audit all sibling diagrams**
   proactively. Do not wait to be told the same issue diagram by diagram.
4. If rules conflict (e.g. a uniform label gap would force an overlap), rule 4's
   no-overlap requirement wins: keep the clean position and state the conflict
   explicitly rather than forcing a bad placement.
5. Examples of the above in practice:
   - Two κ labels flanking a mediator line: move them as a *pair*, with equal
     offsets toward each vertex's clear side (one side is crowded by an
     incoming wiggle, the other by outgoing lines) — never fix one by itself.
   - A κ_λ whose tail crossed an outgoing H line was fixed by moving the whole
     label up-left into the empty wedge, not by shrinking its distance.
   - A VBF set was fixed by giving all three diagrams the identical external
     block, so only the internal VBS mechanism differed.

## Pre-finish checklist

- [ ] Every vertex exists in the requested theory; couplings match vertices.
- [ ] Fermion loops use the correct flavor and label the antiquark from the
      actual arrow flow (not from a fixed example geometry).
- [ ] Loops are square/regular; same-role lines have equal length and are
      parallel where appropriate.
- [ ] Paired labels are mirror-symmetric with equal gaps.
- [ ] All sibling diagrams share external geometry/canvas.
- [ ] External labels at endpoints, mediators mid-line, couplings at vertices.
- [ ] Every label's full glyph (tails/subscripts included) is clear; low-density
      placement chosen.
- [ ] The PNG was rendered from the current source and visually inspected after
      the last edit; the PDF and PNG exist and are non-empty.
- [ ] Only source written by the user or the agent was compiled.
