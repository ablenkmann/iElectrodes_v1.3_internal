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
- **Trimming the images: done.** `ielec.trimImages` cuts the MRI, the CT,
  the brain mask and the parcellation down to a box around everything the
  project holds, and moves each image-to-world transformation by the same
  amount. The question of whether a trim is stored or recomputed turned out
  not to arise: the `.iel` holds coordinates in millimetres, so moving the
  transformation leaves every one of them meaning the same place, and the
  smaller images are simply what is stored.

  Taking "to the brain" literally would have cut the brain. Measured on the
  example project, the pial surfaces reach outside the brain mask in every
  direction, so the box is the union of the mask, the surfaces, the
  contacts and the planned targets, plus a margin. That keeps 44 per cent
  of the example's volume - 43.8 MB down to 19.4 MB per volume, and the
  file from 44.8 MB to 35.6 MB.
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

---

## What the new window got wrong, from using it (28-30 October 2026)

Emir's six, after driving `app/ui/iElectrodes2.m`. All six are done. The
record below is what each one turned out to be, which in two cases is not
what was guessed first, and in one case is not what was guessed second
either - the answer came from putting his screenshot of 1.020 next to one
of this window.

1. **The plots were too small and the panels too wide.** *Done.* The body
   splits 2.4 to 1 rather than 1.4 to 1, the foot strip is 120 and the
   contact table 200. The folding sizers wrote the old numbers back the
   first time a panel was folded; both are constants now, in one place.

2. **The 3-D brain looked bad**, and 4. **the contacts looked like they
   were floating.** *Done, and the cause was neither of the first two
   guesses.*

   The first guess was a coarse mesh. Measured, the file carries the full
   pial surface - 114 637 and 116 003 vertices - so the mesh was never it.

   The second guess was the half transparency 1.020 starts at, and the
   planning targets being drawn by default. Both were changed, and both
   were then put back: his screenshot of 1.020 shows a half-transparent
   brain *with* the planning targets, and that is the picture he called
   clear and high quality.

   What was actually missing is the lines between neighbouring contacts.
   1.020 draws them with `plotElectrodesLines`, which this repository
   already carries in `app/rendering/`; the old window calls it at
   `electrodes_gui.m:1982` and the new window never did. Without them an
   array is a scatter of identical dots and nothing says which dot belongs
   to which electrode. With them a grid reads as a lattice and a depth
   electrode as its own shaft. That one call is most of the difference
   between the two screenshots.

   Measured, for the record: the grid sits 1.4 mm outside the pial surface
   on average and the strip 2.3 mm, which is correct and is what the
   brain-shift projection exists for.

3. **It zoomed in on itself after any operation.** *Done.* `draw3D` framed
   the camera on every pass, so every checkbox, every added contact and
   every move of the cursor threw away a view that had been turned by
   hand. The camera is taken before the clear and put back after; framing
   happens when a project is opened and when the button in the view's own
   toolbar asks for it. A draw that had no surface to frame on no longer
   counts as a framing draw - it used to leave the limits measured without
   the surface, and clip the brain when it came back.

   The opening view is 1.020's fixed `view(-135, 25)` again. Aiming the
   camera at the middle of the contacts was tried instead and was worse in
   practice: it opened on the front of the head, where the brain is
   narrowest and fills least of the view.

5. **The brain could not be turned with the mouse.** *Done.* It could -
   `draw3D` sets the rotate and zoom interactions - but every view is built
   with its toolbar hidden, so nothing said so, and (3) undid any turn on
   the next redraw. The two views in space now carry a toolbar with rotate,
   pan and zoom; the three planes do not, because a plane that rotates
   under the pointer cannot be clicked accurately.

6. **Closing did not ask whether to save.** *Done.* Save is wired to
   `ielec.saveProject`, and closing asks when the project has changed.
   Whether it has is the length of `project.history`, leaving out
   `ielec.thresholdCT`: that one records a step every time a threshold
   moves, including once on the first visit to the Localize step, so
   counting it asked the user to save a project nobody had touched.

**Still open, found on the way.**

- ~~The voxel view resets its camera the same way the 3-D view used to.~~
  *Done:* it keeps it, by the same capture-and-restore, with its own
  `FrameVoxelsNext`. A cloud turned to line a region up survives a
  threshold moving, which is the one thing brushing needs of it.
- 1.020 can switch the lattice off - `PlotConnCheckbox`, gating both
  `electrodes_gui.m:1963` and `:2104` - and the new window draws it
  unconditionally. A dense plan is a lot of lines: the example's 8x8
  planning grid alone is 112 of the 285. The drawing already falls back
  from spheres to dots past 600 contacts for the same reason, so the box
  this wants is the one 1.020 has.
- **The project does not record how big a contact is.** "Contacts drawn
  as" now offers *True size* beside Dots and Spheres, which draws a
  subdural contact 2.3 mm across the exposed face and a depth contact
  0.8 mm - but those are typical clinical values written into the window,
  not anything read from the patient's file. `checkElectrodeStructure.m`
  has no field for them. The file does say the kind, and the spacing
  agrees with it (10 mm for the example's grid and strip, 5 mm for its two
  depth electrodes, which is subdural and SEEG), so the guess is a good
  one - but a guess in the frontend is the wrong place for a number that
  belongs to the electrode. The right fix is a field on the array, written
  when it is built and carried in the .iel, which is a layer change and
  Alejandro's to approve.

  Still a marker, not a model: a contact is a sphere at true size, where a
  subdural contact is a disc lying on the surface and an SEEG contact a
  cylinder along its own shaft. The shaft is already drawn, as the lattice
  chain.

The 1.020 window asks none of these questions of itself, so there is
nothing to be faithful to here; this is the one piece of the frontend being
designed rather than ported - which is also why being faithful to it where
it *has* an answer, as in 2 and 4, turned out to be the right instinct.
