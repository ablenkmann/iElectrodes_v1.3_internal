# Open questions for Alejandro

Findings from the v2 restructuring that need a decision from the toolbox
author. Ordered by how much they affect the science.

---

## 1. Planning targets are labelled at the wrong coordinate in MNI space

**Where:** `labels2MNIspace`, now `src/labeling/labelElectrodesMNI.m`

In the planning-targets loop the position is built as:

```matlab
pos = [prj.targets{l}.x  prj.targets{l}.y  prj.targets{l}.y];
```

`.y` appears twice and `.z` is never read, so every planning target is looked
up at `(x, y, y)` instead of `(x, y, z)`. The electrode loop a few lines above
uses the correct `[x y z]`, so only planning targets are affected.

Every anatomical label reported for a planning target in MNI space is
therefore taken from the wrong voxel, unless `y` happens to equal `z`.

**Decision needed:** is this simply a typo to fix? If so, note that fixing it
will change the labels of existing planning targets, so any report already
produced from an MNI-space project carries the old values.

**Observed at run time.** Switching the MNI Labels toggle on, with
`examples/exampleNativeSpace.iel` loaded, produces:

```
Warning: coordinates out of MNI matrix space
> In anatomicLabel (line 64)
  In labelElectrodesMNI (line 61)      <- the planning-targets loop
  In labels2MNIspace (line 1343)
  In MNILabelstogglebutton_OnCallback (line 1301)
```

Line 61 is the `anatomicLabel` call two lines below the `[x y y]` position, and
the electrode loop above it produces no such warning. Substituting `y` for `z`
pushes the targets outside the MNI volume, which is exactly what the warning
reports. So this is not only visible in the source - it fires on the example
project that ships with the toolbox.

**Status:** deliberately left unfixed. The extraction was kept
behaviour-preserving on purpose; the fix belongs in its own commit so its
effect can be measured separately.

---

## 2. Target loop iterates over the wrong array when no atlas is loaded

**Where:** `labels2NativeSpace`, now `src/labeling/labelElectrodesNative.m`

In the `else` branch that fills in placeholder labels when no parcellation is
loaded, the projections of planning targets are filled like this:

```matlab
for p = 1:length(prj.electrodes{l}.projection)      % <- electrodes
    prj.targets{l}.projection{p}.aLabels = ...      % <- targets
```

The loop bound comes from `electrodes{l}` while the writing goes into
`targets{l}`. If there are fewer electrode arrays than targets this errors; if
the projection counts differ it silently fills the wrong number of entries.

This branch only runs when no parcellation is loaded, which is why it has
probably never been hit in practice.

**Decision needed:** confirm it should read `prj.targets{l}.projection`, and
whether that same `else` branch is worth keeping at all.

**Status:** left unfixed, same reasoning as above.

---

## 3. Which coordinate should subdural arrays be labelled from?

**Where:** anatomical labelling in general

Running the labelling on `examples/exampleNativeSpace.iel`:

| array | type | contacts | result |
|---|---|---:|---|
| G | grid | 20 | labelled, e.g. `97% ctx-rh-caudalmiddlefrontal` |
| TR | depth | 10 | labelled, e.g. `94% Right-Hippocampus` |
| TL | depth | 10 | labelled, e.g. `46% Left-Amygdala \| 30% Left-Inf-Lat-Vent` |
| s | strip | 4 | **every contact `unknown`** |

The strip's contacts appear to fall outside the wmparc volume, which is
plausible: a subdural strip sits on the surface while the parcellation covers
brain tissue. The projected coordinates would land inside the cortex, and the
code already computes and labels those separately.

**Decision needed:** for subdural grids and strips, should the anatomical
label shown in the GUI and written into reports come from the localised
coordinate or from the projected one? If the projected one, should that be the
default or an option?

---

## 4. Repository contains a file too large for GitHub

**Where:** `extras/r256TAC_PATRON_frame_down_1mm.nii` — 134 MB

GitHub refuses any single file over 100 MB. `third_party/.../tpm/TPM.nii`
(51 MB) is also over GitHub's 50 MB warning threshold. The file is already in
the git history, so if the project later moves to GitHub — as the reference
architecture discussion recommends — the history would have to be rewritten or
the file moved to Git LFS.

Not urgent while development stays local.

**Decision needed, eventually:** is that CT template still needed by
`extras/corregistroMarco.m`? Options are Git LFS, distributing it separately
from the repository, or dropping it.

---

## 5. Licence metadata inconsistency

Raised in the reference architecture discussion, repeated here so it is not
lost: the SourceForge project page states the GNU Free Documentation License,
while `license.txt` and the source headers use GPLv3.

**Decision needed:** correct the project metadata, and review the licences of
the bundled third-party code in `third_party/` before any v2 release.

---

## 6. Oldest MATLAB release to support

The reference discussion suggests choosing R2024b as the oldest supported
release for v2 and keeping v1 available for older installations, with the
final choice made after asking a few active users what they actually run.

**Decision needed:** which MATLAB releases must v2 support? This affects
whether App Designer features introduced in recent releases can be used.

---

## 7. `getThresholdedVoxels` crashes instead of warning when nothing is selected

**Where:** `getThresholdedVoxels` in `electrodes_gui.m`

**Note on the name.** Despite what it is called, this function does not
threshold anything. It returns the voxels the user has *brushed* in the 3D
view, for clustering. The thresholding proper now lives in
`src/localization/thresholdCTVoxels.m`. When this function is extracted in
turn, `brushedVoxels` would say what it does.

The function has three guard branches that warn and return early:

```matlab
function [brushCrd,weight]=getThresholdedVoxels(handles)
...
    warning ('There are no points selected to be clustered');
    return;                       % brushCrd and weight are never assigned
```

None of them assigns the output arguments, so MATLAB raises

```
Output argument "brushCrd" (and possibly others) not assigned a value
```

and the callback aborts with a red stack trace. Pressing `Clus` or `Fit`
without having selected any voxels therefore looks like a crash rather than
the intended message. Both callers already test `if isempty(brushCrd)`, so
they are prepared for an empty result.

The fix is one line before each `return`:

```matlab
brushCrd = [];
weight   = [];
```

**Decision needed:** confirm this is simply an oversight. It is a behaviour
change - the user would see a warning instead of an error - so, like the two
labelling bugs above, it has been left for a separate dedicated commit.

**Status:** left unfixed. Present in v1.020, not introduced by the
restructuring.

---

## 8. The Simulate panel has no grid mode, so loading a planning grid fails

**Where:** `UpdateTargetEditBox` in `electrodes_gui.m`

`checkElectrodeStructure` gives a planning array different fields depending
on its type:

```matlab
if strcmp(elec.planning, 'yes')
    if strcmp(elec.Type, 'grid')
        hemisphere, rotation, distance
    end
    if strcmp(elec.Type, 'depth')
        targetIn, targetOut, FirstSecond, SecondLast,
        framePosition, frameDown, delta, beta, azimut, elevation
    end
end
```

`UpdateTargetEditBox` refreshes the whole Simulate panel from the selected
planning array, and read the depth-only fields unconditionally. For a
planning **grid** it therefore failed with `Unrecognized field name
"FirstSecond"` before it could draw anything.

Its only live caller is the **Load simulated coordinates** button, so that
button has been unusable for every project containing a planning grid -
which is every project made with the New button in Grids mode. The shipped
`examples/exampleNativeSpace.iel` is one: all six of its planning arrays
are grids.

**What was done:** the depth-only part is now inside
`if strcmp(Type,'depth')`, and for any other type those boxes are cleared
instead of being left showing the previously selected array's numbers. The
button works again and no longer misreports.

A related symptom, visible once the button works: the panel's
`Depths` / `Grids` radio pair does not follow the selected array either. It
stays wherever the user last left it, so a grid array can be displayed with
`Depths` selected. Same cause - nothing in the refresh path knows the
array's type.

**Decision needed:** what should the panel show when a planning GRID is
selected? The panel has a Grids mode with its own rows, columns and
distance boxes, and the array carries `rows`, `columns`, `distance`,
`hemisphere` and `rotation`. Filling those in, and moving the radio pair to
match the array, is the obvious answer - but it is a design choice about
the interface, so it was deliberately left out of the restructuring.

**Two smaller faults fixed in the same path, both from the same redesign:**

- `TargetNameedit` and `TargetElectext` do not exist among the .fig's 209
  controls. Replaced with `editPlanningArrayName` and the planning target
  counter, which is what every other site uses. `TargetNameedit_Callback`,
  the callback of the missing control, was removed - it renamed the
  selected planning array, which `editPlanningArrayName_Callback` already
  does.
- `targets{..}.Electrodes` is read in five places and assigned nowhere in
  the repository. The real field is `nElectrodes`. Two lines computing the
  same value, one of each spelling, made this unambiguous. Fixing it also
  unbreaks `angleChange` and `AlphaBetaChange`, so the azimuth, elevation,
  alpha and beta boxes work again.

---

## 9. The CT coregistration in the Load CT button is unreachable and broken

**Where:** `LoadCTtool_ClickedCallback` in `electrodes_gui.m`

Of that callback's 194 lines, about 115 can never run. Just before the
switch that would select them:

```matlab
choice = 'No'; % code below is not ready
```

`choice` is assigned a constant, so the switch always takes `case 'No'`,
which does nothing, and execution continues to the plain load below.

The unreachable part offers three ways to align the CT with the MRI: a
manual dialog with rotate and centre buttons, an SPM `spm_coreg` estimate
saved to `MatCT2MR.mat`, and a step that applies a previously saved
transformation. It would not survive being reached, either:

```matlab
VolCT = spm_vol(fileCT);                      % fileCT is never defined
load([pathBase 'MatCT2MR.mat'], 'MatCT2MR')   % pathBase is never defined
```

So it is not merely disabled - it is unfinished.

**Decision needed:** is this work in progress that should be completed, or
an abandoned attempt that should be removed? It was left in place, because
deleting someone's unfinished feature is not a call the restructuring
should make. Either answer is easy to act on; leaving it as it is, is what
costs - 115 lines that look like behaviour and are not.

Worth noting alongside: with this code inert, iElectrodes offers no way to
coregister a CT that is not already aligned with the MRI. Users have to do
it in SPM or elsewhere first. If that is the intended workflow, saying so
in the documentation would help more than the dead code does.

