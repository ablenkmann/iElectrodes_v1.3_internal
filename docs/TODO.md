# What iElectrodes 2 still owes

The toolbox author's own list, from the Teams channels, kept here so that it
does not live only in a chat. His words are quoted; everything in square
brackets or under "Where this stands" is this restructuring's note on them,
added 19 October 2026.

The restructuring itself - the three layers, the `.iel` format, the
processing history - is finished. What follows is the work the author asked
for on top of it, and none of it is blocked by the layer any more.

---

## Back end

> * Possibility to include/use different atlases (beyond FreeSurfer and
>   Harvard-Oxford)
> * When opening the toolbox, check the latest version (reuse old code or
>   improve)
> * Trim MRI and CT images to the brain only (some extra cm around is fine)
> * Make a full report of all localized electrodes in pdf file. Consider
>   making new planes for visualization, along the electrode axis, so all
>   contacts within an array can be visible.
> * Code cleaning and pruning

**Where this stands.**

- **Different atlases.** `ielec.loadAnatomy` reads a parcellation and
  `ielec.label` / `ielec.pointLabel` answer from it or from the MNI
  probabilistic atlas, chosen by `project.currentSpace`. A third atlas needs
  a third branch there and a way to say which one is meant - a cfg option
  rather than a space, probably. Nothing in the layer's shape is in the way.
- **The version check: done.** Improved rather than reused -
  `app/config/checkUpdates.m` now reads the published file by splitting lines
  instead of counting bytes, warns instead of falling silent on a version it
  cannot parse, and no longer throws out of the opening function on a short
  response. `docs/OPEN_QUESTIONS.md` item 47 has the measurements and the one
  constraint that remains.
- **Trimming the images.** Not started. It touches `ielec.newProject` and
  `ielec.loadCT`, both of which already own the reslicing, so it has a home.
  Worth deciding first whether the trim is stored or recomputed, because a
  trimmed image changes every voxel coordinate in a project and the `.iel`
  file holds coordinates in anatomical space.
- **The PDF report.** Not started, and the largest of these. The author sent
  a page of what he means: one depth electrode (HD 1-8) in four panels -
  axial, coronal, sagittal and a 3-D view - with each pair of contacts named
  anatomically beside it ("1-2. Cisterna ambiens y margen posterior
  unco-amigdalino", "3-4. Limite supero-anterior cabeza hipocampo"). The
  "new planes along the electrode axis" is the part that needs new geometry:
  a plane containing the electrode's trajectory, so every contact of an array
  shows in one image instead of appearing and disappearing across slices.
  `ielec.export` is where a report would be added; the labels it would print
  are what `ielec.label` already produces.
- **Code cleaning and pruning.** Continuous. `docs/OPEN_QUESTIONS.md` holds
  forty-seven findings, several of which are this: dead parameters, a
  duplicated `fieldOr` in twenty-seven files, pragmas suppressing messages
  that are no longer emitted.

---

## Front end

> Ideas for visualization: add a 2D plot in the 3D view, as for example in
> 3D slicer

The author sent a 3D Slicer screenshot for this: a rendered head with the
three slice planes cutting through it in the 3-D view, and the axial,
sagittal and coronal slices beside it as their own panels.

> Layouts
> * Classical for now seems very nice.
> * Clinical has nice buttons and rounded edges for figures.

One of Classical and Clinical becomes the default and the rest are offered as
options. Clinical's buttons were the ones liked; a dark version of it is the
reference for the dark theme.

> In general, one bright and one dark interface should be available

> Fixing 3d plots
> * For the thresholded voxels view, use a colormap (not gray anymore)
> * For 3D view, show surfaces, but not voxels.
> * New naming of elements in APP : ask Claude to check the naming of menus,
>   buttons, functions and plots. They should be clear and represent what
>   they actually do.

**Where this stands.**

- **The nine HTML mockups are out of date** against the author's note and
  need redrawing before the App Designer build, not after.
- **The Localization panel is specified** - `docs/OPEN_QUESTIONS.md` item 40:
  two labelled sections, one per procedure, each with its own Add button and
  counter. The layer already takes a `cfg.group` for all four coordinate
  functions, so the eight controls are buttons over calls that exist.
- **The naming pass is a task for this restructuring** rather than for the
  frontend alone, because the layer's forty function names are the vocabulary
  the menus and buttons will borrow. It should run over
  `docs/FUNCTION_INVENTORY.md` and the App's own elements together.
- **A Messages panel** mirroring what the toolbox prints is still wanted; the
  layer helps here, since every `ielec` function reports through its third
  output rather than printing.
- **The MRI/CT visualization window is new code**, not a port. It is the one
  piece of the frontend that has no 1.020 original to be faithful to.

---

## Not on the author's list, found on the way

Four of the forty-seven open questions want his decision rather than ours, and
three of the four are answered as of 19 October 2026 - items 40, 45, 46 and
47. What is left of them is in each item.

The repository is ready to move to GitHub: line endings are settled, the
example data was already published in 2017, and the vendored tree no longer
carries a broken macOS binary.
