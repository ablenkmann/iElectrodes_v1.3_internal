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

**Status: FIXED.** Alejandro approved it - "seems strange because it worked
as it should. Fix it then". The reason it looked as though it worked is that
native-space labelling uses `[x y z]` correctly; only the MNI path was
affected, and planning targets are rarely labelled in MNI space. The run-time
warning above is the evidence that it was not working.

Labels reported for planning targets in MNI space by 1.020 and earlier are
wrong. `tests/test_labelingMNI.m` now requires the targets to come back with
labels, which they could not do before.

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

**Status: FIXED.** Alejandro: "this is an error that needs to be fixed".

A second fault in the same three lines turned up while fixing it: the label
count came from `prj.targets{l}.ntargets`, and `ntargets` is not assigned
anywhere in the toolbox - it appears exactly once, here. So the branch had two
ways to fail, which is consistent with it never having run. It now reads
`nElectrodes`, like every other array does.

`tests/test_labelingWithoutAtlas.m` runs the branch on a project with its
parcellation removed, which is the ordinary state of a project before the
FreeSurfer output is loaded.

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

**Alejandro's answer so far:** "I'm guessing that 2024 or 2025, but I'm not
sure. It depends on the implications of this decision."

**The implications, as far as this work can see them:**

- *The minimum cannot be newer than the release v2 is developed and tested
  on.* Newer releases run code written for older ones, not the reverse.
  Development and testing currently happen on **R2023b**. A minimum of
  R2024b or R2025a would mean shipping something that cannot be run on the
  machine it was built on. So either the minimum is R2023b or earlier, or
  development moves to a newer release before the App Designer work starts.
- *App Designer is where the choice becomes binding.* An app saved in a
  newer release is not guaranteed to open in an older release's App
  Designer, so the release the v2 GUI is built in effectively becomes the
  minimum for anyone who wants to edit it.
- *The existing code is not what constrains it.* `electrodes_gui.m` carries
  twelve `verLessThan` checks - eleven for R2014b (8.4.0), one for R2018b
  (9.5). Under any minimum from R2019a on, all twelve are dead branches and
  can be deleted.

The simplest consistent rule: **the minimum is the release the v2 GUI is
built in.** That turns the open question into a smaller one - whether to
upgrade from R2023b before starting the frontend - and the reference
discussion's suggestion of asking a few active users what they run still
applies.

**Status:** open, but narrowed. Needed before the frontend work starts, not
before.

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

**Status: FIXED.** Alejandro: "a warning seems better". Both outputs are now
assigned at the top of the function, so the three guards warn and return as
they were written to.

**One more thing turned up when it was tested.** This entry used to claim that
both callers already test `isempty(brushCrd)`. Only `Fitpushbutton_Callback`
does. `ClusterButton_Callback` went straight on to the clustering, and the
missing-output error had been what stopped it. With the outputs assigned,
pressing `Clus` with nothing selected warned and then failed inside
`kmedoids` with "X must have more rows than the number of clusters". The same
guard Fit already had is now in Clus, so both buttons print the same line and
return.

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

**Status: DONE.** Alejandro: "Grids should be accepted to."

The Grids boxes are filled from the array's own `rows`, `columns` and
`distance`, and the radio pair now follows the selected array instead of
staying wherever the user last left it. Its `hemisphere` and `rotation` have
no boxes in the panel, so there is nothing to show for them.

Whichever mode is not the array's has its boxes cleared, so that numbers left
over from a previously selected array cannot be read as belonging to this
one.

The radio and the panel visibility are now set in one place,
`showPlanningPanel`, called both from the radio pair's own callback and from
`UpdateTargetEditBox`. Setting `SelectedObject` programmatically does not
fire `SelectionChangedFcn`, so the visibility has to be set alongside it -
which is exactly the kind of thing that drifts apart when it is written
twice.

**One more thing turned up while checking it by hand.** The `+` and `-`
buttons that walk through the planning arrays never called
`UpdateTargetEditBox` at all - they set the array name and the contact label
and nothing else. So the Simulate panel kept describing whatever was last
loaded, whichever array was selected, for depth arrays as much as for grids.
`Load simulated coordinates` was its only live caller.

Both buttons now refresh the panel, which is what makes any of the above
visible while working. The two `set` calls they used to make are gone:
`UpdateTargetEditBox` sets those same two boxes itself.

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

**Status: REMOVED.** Alejandro: "Delete".

Checked before deleting, because removing a block that size on a reading of
the code alone is not something to do lightly:

- `choice` is assigned exactly once in that function, to the literal `'No'`.
  Every other `choice =` in the file is a local variable in a different
  function.
- `coregDlg` and `angle_tra2rmat`, both called inside the branch, do not
  exist anywhere in the toolbox - not in `app/`, `extras/`, `legacy/`,
  `src/` or the repository root.
- `fileCT` and `pathBase` are used in the branch and assigned nowhere.

So the branch could not have run even if `choice` had been `'Yes'`. 128 lines
went, and `LoadCTtool_ClickedCallback` is now 72 lines instead of 193. The
history keeps it: `git log -S "spm_coreg" -- electrodes_gui.m` finds the
commit that removed it.

**What the user is left with,** and it is now said in the callback: the CT
must already be coregistered to the MRI, done in SPM or elsewhere first.
That was already true - the code that claimed otherwise never ran - but
nothing said so. Worth putting in the user documentation as well.


---

## 10. Renaming an array renumbers its contacts, but only for planning arrays

**Where:** `editArrayName_Callback` and `editPlanningArrayName_Callback` in
`electrodes_gui.m`

The two name boxes behave differently. Renaming a **planning** array also
rewrites every contact label:

```matlab
handles.project.targets{a} = nameArrayContacts(handles.project.targets{a}, str);
% -> targets{a}.ch_label = {str1, str2, ...}
```

Renaming a **localized** array only sets the name. The loop that would
rewrite the labels is still there, commented out, with a note:

```matlab
% Electrode labels and Array are independent now
% N=handles.project.electrodes{a}.nElectrodes;
% for i=1:N
%     handles.project.electrodes{a}.ch_label{i}=[str int2str(i)];
% end
```

That note reads like a deliberate decision: once contacts have been labelled
from a recording montage, an array rename should not silently overwrite
those labels. The `Auto` button under *Label electrodes* is what renumbers
them on purpose.

If that reasoning is right, it applies to planning arrays too - a planned
array can be labelled from a list just as a localized one can, and renaming
it currently throws those labels away without asking.

**Decision needed:** should the planning name box follow the localized one
and leave contact labels alone? It is a behaviour change, so it is left for
a separate dedicated commit.

**Status:** left as it is. Present in v1.020, not introduced by the
restructuring.

---

## 11. Two toolbar buttons are hidden, so their callbacks can never run

**Where:** `electrodes_gui.fig`, and the callbacks in `electrodes_gui.m`

Two toolbar buttons carry `Visible = 'off'` in the .fig, and nothing in
`electrodes_gui.m` ever turns them back on:

| Tag | Tooltip | Callback |
|-----|---------|----------|
| `ClearFSsurfaceuipushtool2` | Remove pial surface | line 1507, 18 code lines |
| `removeSCEuipushtooluipushtool` | Remove smoothed cortical envelope | line 1626, 11 code lines |

Both sit next to their working counterparts - `addFSsurfacesuipushtool`
("Load pial surfaces") and `addSCEuipushtool` ("Load or build smoothed
cortical envelope"), which are visible - so the toolbar offers a way to add
each surface and no way to take it back. The user sees four brain icons'
worth of space occupied by two.

The callbacks themselves look finished and correct. Removing the pial
surfaces clears the vertices, faces, annotation labels, colortables and
colour caches, sets `currentSpace` back to `'MNI'` and re-labels; removing
the SCE does the matching thing for the envelope surfaces. Neither is a stub.

Found while testing the colour-cache move: the test asked for "press Remove
pial surface" and there was no such button to press.

**Decision needed:** were these hidden deliberately - because clearing a
surface discards annotation data that then has to be re-loaded from
FreeSurfer, and that is easy to do by accident - or did the `Visible` flag get
switched off during some earlier editing session and never switched back? If
deliberate, the callbacks are dead weight and should say so; if accidental,
making them visible is a one-property change in the .fig.

**Status:** left as it is. Present in v1.020, not introduced by the
restructuring.

---

## 12. Two misspelled keys in the BIDS coordinate-system json

**Where:** `SaveElectrodespushtool_ClickedCallback` in `electrodes_gui.m`,
BIDS options 6 and 7

The json written next to the BIDS electrodes.tsv contains:

```json
"IndendedFor": "/data/Images/HRM007-OC/rTAC.nii",
"iEEGCoordinateProcessingDescripton": "none",
```

The BIDS specification names these `IntendedFor` and
`iEEGCoordinateProcessingDescription`. Both spellings in the code are wrong,
so a validator does not recognise either field: the pointer to the CT and the
note about whether coordinates were projected are both silently ignored.

The other four keys - `iEEGCoordinateSystem`, `iEEGCoordinateUnits`,
`iEEGCoordinateSystemDescription`, `iEEGCoordinateProcessingReference` - are
spelled correctly.

**Related, and a separate question.** `IntendedFor` is meant to hold a BIDS
URI relative to the dataset. The value written is
`handles.project.TAC.vol.fname`, the absolute path the CT happened to have on
the machine where the project was made - in the shipped example,
`/data/Images/HRM007-OC/rTAC.nii`. That path means nothing on any other
computer. iElectrodes does not know where the BIDS dataset root is, so it
cannot compute the relative path on its own; it would have to ask.

**Also worth deciding.** The electrodes.tsv carries three extra columns named
`Electrode Type`, `Projection Method` and `Anatomical Label`. BIDS allows
extra columns, but names with spaces are awkward to read back, and BIDS
already defines an optional `type` column that `Electrode Type` duplicates
under a different name.

**Status: the two typos are FIXED.** Alejandro: "go ahead and fix them". A
script that reads the old spellings will stop finding those fields; nothing
inside the toolbox does.

The `fprintf` escape problem is fixed in the same place - the json is now
written with `fprintf(fid, '%s', text)`, so a Windows path stays a path.
`tests/test_electrodeExports.m` writes a json with `C:\temp\new.nii` in it
and decodes the result, which is the check that would have caught it.

That test no longer compares the json against the original code, since the
original output is now the thing that must not come back. It decodes the file
and checks it against the specification instead.

**STILL OPEN - the value of `IntendedFor`,** which is the absolute path the CT
had on the machine where the project was made, where BIDS wants a URI relative
to the dataset root. iElectrodes does not know where that root is, so it would
have to ask. Not raised with Alejandro yet.

**ALSO STILL OPEN - the three extra `.tsv` columns** named `Electrode Type`,
`Projection Method` and `Anatomical Label`. BIDS allows extra columns, but
names with spaces are awkward to read back, and BIDS already defines an
optional `type` column that `Electrode Type` duplicates.

---

## 13. Target and Entry P treat the click differently

**Where:** `setPlanningPoint` in `electrodes_gui.m`, called by
`TargetInpushbutton_Callback` and `TargetOutpushbutton_Callback`

The two buttons let the user click one end of a planning depth electrode in a
2-D view. They were written out separately, about eighty lines each, and one
difference survived between them:

```matlab
[d1,d2]=ginput(1);

% Entry P only:
d1=round(d1,3,'significant');
d2=round(d2,3,'significant');
```

`Entry P` rounds the clicked position to three significant digits before
using it; `Target` uses it as clicked. In a 256-voxel image three significant
digits is roughly voxel precision, so the entry point snaps to a voxel and
the target point does not.

Both then round the ANATOMICAL coordinates to three significant digits before
writing them into the edit boxes, so the difference is not visible in the
boxes - only in the sliders and in what is stored.

The two callbacks are now one function and the difference is a flag in it,
kept rather than settled.

**Decision needed:** should both round, or neither? Rounding to a voxel is
defensible - the user cannot click more precisely than a voxel anyway - but
doing it to one end of the electrode and not the other is hard to defend
either way.

**Status:** preserved. Present in v1.020, not introduced by the
restructuring.

---

## 14. `my_quatrotate` takes one vector, but every caller passes a whole electrode

**Where:** `src/geometry/my_quatrotate.m`, called from `gridMatchEnergy.m`
(twice), `distanceConstrain.m` and `gridFit.m`

Fitting a depth electrode fails before it starts:

```
Error using my_quatrotate
Input vector must be a 3-element vector [x, y, z].

Error in gridMatchEnergy (line 73)
    pos=my_quatrotate(q,options.posIdeal+t);
...
Caused by:
    Failure in initial objective function evaluation. FMINCON cannot continue.
```

`my_quatrotate` is a stand-in for the Aerospace Toolbox function
`quatrotate`. In v1.020 all four call sites used `quatrotate`; in this
version each one is commented out with the stand-in beneath it:

```matlab
%    pos=quatrotate(q,options.posIdeal+t);
    pos=my_quatrotate(q,options.posIdeal+t);
```

`quatrotate` takes an M-by-3 array and rotates every row. The stand-in
begins

```matlab
if numel(vector) ~= 3
    error('Input vector must be a 3-element vector [x, y, z].');
end
```

so it takes one vector and nothing else. What the callers pass is
`posIdeal + t`, and `posIdeal` is `zeros(rows*cols,3)` - the ideal positions
of the whole electrode, one contact per row. For an 8-contact depth
electrode that is an 8-by-3 array, so the guard fires immediately.

The consequence is not subtle. `1D_fix` is the default second minimization
for depth electrodes:

```matlab
options.gridFit_depth.minDef2.model = '1D_fix';
```

and `1D_fix` is the only model that rotates. So **no depth electrode can be
fitted with GridFit in this version at all**. The first minimization
completes, the second one dies on its first function evaluation. Grids and
strips use the `3D` model, never reach these lines, and are unaffected -
which is presumably why it went unnoticed.

The rotation matrix inside the stand-in is the one `quatrotate` documents,
so a single vector already gives the right answer. Only the shape handling
is missing.

```matlab
if numel(vector) == 3
    rotated_vector = rotation_matrix * vector(:);
    rotated_vector = reshape(rotated_vector,size(vector));
elseif ismatrix(vector) && size(vector,2) == 3
    rotated_vector = vector * rotation_matrix';   % (R*v')' for every row
else
    error('my_quatrotate:badVector', ...);
end
```

`tests/test_my_quatrotate.m` checks that rotating an M-by-3 array gives the
same answer as rotating its rows one at a time, that contact spacing survives
the rotation, and that a single vector still behaves exactly as before.

**Decision needed:** none about *what* the answer should be - the line this
stand-in replaced says it. But the replacement itself is recent and not ours,
so Alejandro should know it shipped in a state where depth fitting could not
run, in case there is a newer version of the file somewhere that already
fixes this.

**Status: FIXED, pending confirmation.** Not present in v1.020, which called
`quatrotate` and needed the Aerospace Toolbox. Introduced by whoever replaced
it; not by the restructuring.
