---
name: feynman-diagram
description: >
  Draw publication-quality Feynman diagrams with Asymptote's feynman package.
  Use for "draw a Feynman diagram", "make an .asy diagram", "Feynman diagram in
  Asymptote", "compile this .asy", or any request involving particle-process
  diagrams. Covers physics validity (vertices, fermion-flow/t vs anti-t),
  internal and group symmetry (ratios, shared external geometry across a family),
  label semantics and placement (endpoint/midline/vertex, glyph bounding boxes,
  object density), the compile workflow in WSL, and mandatory visual auditing.
  General rules for any process (ggF, VBF, Higgs self-coupling, QCD/EW), with
  examples — not tied to one diagram.
---

# Feynman diagrams in Asymptote

Goal: a `.asy` script that renders to a PNG a physicist would accept for a
publication — correct physics, balanced geometry, clean labels, verified by
looking at the rendered image.

## Environment and workflow

The toolchain lives in **WSL**, not Windows. Use the native `wsl` tool
(`wsl -e bash -lc '...'` under the hood) with `/mnt/c/...` paths.

- Check first: `which asy && asy --version` (Asymptote 2.87, `feynman.asy` in
  `/usr/share/asymptote/`).
- House style (matches the user's own scripts and blog):

  ```asy
  import feynman;
  currentpen = linewidth(0.75);
  fmdefaults();
  real L = 50;
  ```

  Define points relative to each other with `L` and `dir(angle)` so the whole
  diagram scales uniformly. Draw with `drawFermion`, `drawGluon`,
  `drawPhoton` (vector bosons), `drawScalar` (Higgs — dashed), `dot(...,
  linewidth(3))` for vertices, and `label(...)` for text. Higgs lines should
  normally have no arrow: `drawScalar(a--b, None)`.

- Compile to PDF then rasterize (PDF then `pdftoppm` gives clean high-res PNG):

  ```bash
  asy -f pdf name.asy
  pdftoppm -png -r 200 -singlefile name.pdf name
  ```

  Keep the `.asy`, `.pdf`, and `.png` together in the requested folder.

- **Never claim done without looking at the rendered PNG.** Read the image,
  zoom crops (`convert x.png -crop WxH+X+Y +repage -resize 300% z.png`) where
  labels and lines are dense.

## The four rules

Apply every rule to every diagram, every time.

### Rule 1 — Physics correctness (first, before drawing anything)

Read the process and check that every vertex actually exists in the theory.
Do not draw a vertex that is not in the Feynman rules.

- SM / κ-framework couplings: `ttg`, `ttH` (κ_t), `HHH` (κ_λ), `VVH` (κ_V),
  `VVHH` (κ_2V), `HHHH` (κ_4). Coupling labels belong to **their** vertex.
- A quartic contact (e.g. VVHH, HHHH) is a genuine **4-point vertex**: all four
  lines meet at one dot; there is **no** internal propagator inside it. A
  3-point `V→HH` vertex does not exist in a gauge theory — drawing one is a
  physics error even if the picture looks tidy.
- A cascade (e.g. H\*→HH) is different: it has a real off-shell propagator from
  the production vertex to a separate decay vertex. Label the mediator on its
  line, and put each coupling at its own vertex (κ_V at production, κ_λ at the
  split).
- **Fermion flow and anti-particles.** A closed quark loop carries one
  continuous arrow flow. The loop segment whose arrow points *into* the
  incoming bottom-left gluon vertex is an **anti-quark**: label it `$\bar{t}$`
  (renders as `t~` in FeynArts style); every other segment of the same loop is
  `$t$`. Concretely: bottom edge of a box/pentagon, or lower diagonal of a
  triangle, is t̄. Get this right from the start — labelling a whole loop `t`
  is wrong. Split a vertical edge at a Higgs attachment into two separate
  fermion segments, each with its own arrow and label, not one line with one
  arrow.
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
  top/bottom t̄) go on *matching* sides and at *equal distances* from their
  objects. Never put one partner on the left and the other on the right; never
  leave one tight to its vertex while the other is shoved far away. If one of a
  pair must move to clear an obstacle, move its partner by the same magnitude
  toward the equivalent clear side.

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
  (~3x) and check the entire bounding box — including subscripts and the t-bar
  — against every nearby line, dot, and other label. Move the whole label into
  the empty wedge until the entire glyph clears.
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

- [ ] Every vertex exists in the theory; couplings match their vertices.
- [ ] Fermion loop has t on forward segments, t̄ on the return segment.
- [ ] Loops are square/regular; same-role lines have equal length and are
      parallel where appropriate.
- [ ] Paired labels are mirror-symmetric with equal gaps.
- [ ] All sibling diagrams share external geometry/canvas.
- [ ] External labels at endpoints, mediators mid-line, couplings at vertices.
- [ ] Every label's full glyph (tails/subscripts included) is clear; low-density
      placement chosen.
- [ ] Every changed PNG was re-rendered and visually inspected after the change.
