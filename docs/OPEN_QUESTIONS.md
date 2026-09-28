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

**First consequence, September 2026.** Moving the Clus button onto the layer
needed the brushed *positions* in the list of voxels, not the coordinates of
the brushed points. The branch for R2014a and earlier read the coordinates,
which cannot give positions, so it was dropped rather than rewritten for a
release v2 will not support. The other eleven `verLessThan` branches are
still there.

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

---

## 15. "Change centre" has no check that a planning grid exists

**Where:** `ChangeCenterPlanningGridButton_Callback` in `electrodes_gui.m`

Eight buttons move or turn the selected planning grid, and all eight start

```matlab
if isempty(handles.project.targets)
    warning('Targets is empty');
    return;
end
```

The ninth, "change centre", which moves the grid to the cursor, does not. It
goes straight to `handles.project.targets{a}`, so pressing it in a project
with no planning arrays fails with an indexing error instead of the warning
the other eight give.

Found while the ten planning-grid callbacks were merged. The eight now share
one helper, which keeps their check; "change centre" keeps its lack of one,
with a comment pointing here.

**Decision needed:** add the same check? It is the same kind of fault as
item 7, where the answer was "a warning seems better".

**Status:** preserved. Present in v1.020, not introduced by the
restructuring.

---

## 16. `tangentialGrid` returns without its output when the point is far from the surface

**Where:** `src/localization/tangentialGrid.m`

A planning grid is laid tangent to the smooth cortical envelope, using the
envelope's vertices within 10 mm of the requested centre. When there are
fewer than four:

```matlab
if length(surfPoints)<4
    warning('Coordinate to far from surface. Not enought points to calculate tangential surface. Choose another point');
    return;
end
```

`hemisphere` has been assigned by then, `pTan` has not. Every caller asks
for both, so MATLAB follows the warning with

```
Output argument "pTan" (and possibly others) not assigned a value
```

and the callback stops with a stack trace. The warning the user was meant
to read is followed by what looks like a crash.

It is reachable from "new grid" and "change centre", both of which take the
cursor as the centre: put the cursor more than 10 mm from the envelope - in
deep tissue, say - and press either.

The fix is not the one-liner it was for item 7. Assigning `pTan = []` alone
would make things worse: the callers go on to `target.x = pTan(:,1)`, which on
an empty array quietly succeeds and empties the grid. So the callers would
also need to check for an empty result and leave the grid where it was.

**Decision needed:** make the warning the whole story - `tangentialGrid`
returns an empty result, and callers keep the grid unchanged when they get
one?

**Status:** preserved. Present in v1.020, not introduced by the
restructuring.

---

## 17. The 3D view checks one planning array and draws another

**Where:** `updateElectrodes3D` in `electrodes_gui.m`, where the selected
planning contact is drawn in black

```matlab
for j=plotList
    ...                                   % draw every planning array
end

% plot selected target in black
a=selectedPlanningArray(handles);
l=selectedPlanningTarget(handles);

if ~isempty(handles.project.targets{j}.projection)     % checks array j
    ... scatter3(... handles.project.targets{a}.projection{1}.x(l), ...   % draws array a
```

The test looks at `j` - whatever the loop above happened to finish on, the
last planning array drawn - and the drawing uses `a`, the selected one. When
they differ in whether they have a projection, it fails:

```
Index exceeds the number of array elements. Index must not exceed 0.
Error in electrodes_gui>updateElectrodes3D
```

It turned up during the GUI check of the planning-grid work. On
`examples/exampleNativeSpace.iel`, pressing **Sup** fails every time: the
button moves the grid, which clears its old projection (a projection of the
old position no longer applies), and then the redraw tests the other
planning array - which still has one - and reaches for the selected grid's
now-empty projection. The move itself is never stored, because the error
comes before `guidata`.

The same happens in v1.020: its Sup button also cleared the projection and
then redrew. Nothing in the restructuring touches `updateElectrodes3D`.

It is reachable from any of the nine buttons that move a planning grid,
whenever the project holds a second planning array, the moved one is not the
last, and the last one has a projection.

The fix is one character: `targets{j}` becomes `targets{a}` in that test. It
is almost certainly a copy of the loop's own test, which uses `j` correctly.

**Decision needed:** fix it? The intent is not in doubt - the code that
follows only makes sense for `a` - but it changes what the toolbox does, so
it gets its own commit and a yes first.

**Status:** open. Present in v1.020, not introduced by the restructuring.

---

## 18. Where the localization settings should live

**Where:** the threshold sliders, the denoise slider, the cluster-count box
and the rows / columns boxes of the Localize panel

**Correction first.** This entry used to say the settings could not be moved
into `work` because "`saveProject` writes every field of `work` into the
`.iel`", so the move would change the file. That was wrong.
`checkProjectStructure` writes a fixed list of known fields and drops
everything else - which is also why `work.options` has never been in a
project file. Moving the settings into `work` never threatened the file.
`tests/test_sessionState.m` now checks exactly that.

**What was done.** The reference plan says these values "must become explicit
work data; the controls should display or edit them". The edit boxes have no
callbacks of their own, so the GUI now reads all six controls into
`work.localization` at the moment they are used - updating the voxel view,
pressing Clus, pressing Index - and the calculation takes them from there:

| setting | control | used by |
|---|---|---|
| `thresholdLow`, `thresholdHigh` | the two threshold sliders | `thresholdCTVoxels` |
| `denoiseKernel` | the denoise slider | `thresholdCTVoxels` |
| `nClusters` | the box beside Clus | `clusterContacts` |
| `rows`, `columns` | the boxes beside Index | `indexGridElectrodes` |

The same values are read with the same conversions, so nothing behaves
differently. `readLocalizationSettings` in `electrodes_gui.m` is the only
place that reads them off the controls; it is the GUIDE-era version of the
`app.readLocalizationOptions()` the reference plan sketches for App
Designer.

**Decision still needed, at the start of the frontend work:** should these
settings be saved - with the project, or with each result they produced?
GridFit already records its configuration in every array it fits
(`methodParameters`), but nothing records the threshold that produced the
voxels it was fitted to. Saving them would mean adding fields to the file.

**Status:** moved into `work`, not saved. The saving question is open.
---

## 19. `checkElectrodeStructure` empties `x` instead of creating `distances`

**Where:** `src/project/checkElectrodeStructure.m`, in the block that fills in
missing fields for a planning depth array

```matlab
if ~isfield(elec,'elevation');   elec.elevation=[];   end

if ~isfield(elec,'distances');   elec.x=[];           end   % <- x, not distances
if ~isfield(elec,'coordinates'); elec.coordinates=[]; end
```

Every other line in the block creates the field it tests for. This one
tests for `distances` and empties `x`. It is almost certainly meant to read
`elec.distances=[];`.

What it does depends on when it is reached:

- A **new** planning depth array passes through before it has coordinates,
  so emptying `x` changes nothing, and `updateTarget` writes both `x` and
  `distances` straight afterwards. New projects are not affected.
- A planning depth array that **already has coordinates but no `distances`
  field** - one saved by a version from before that field existed - would
  have `x` emptied, with `y` and `z` left as they were. Opening such a file
  runs every array through this function.

Found by reading, while the import code was extracted. The second case has
not been reproduced; it would need a project file old enough to lack the
field.

**Decision needed:** fix it? One word, and the intent is clear from the
lines around it.

**Status:** preserved. Present in v1.020, not introduced by the
restructuring.

---

## 20. Unassigned nailed contacts are removed element by element, not row by row

**Where:** the Fit button's options, now `src/localization/gridFitOptions.m`

Before GridFit runs, contacts found earlier by clustering can be "nailed":
the user says in a small table which contact number each of those
coordinates is, and GridFit keeps them there. A coordinate the user leaves
without a number gets NaN and is dropped:

```matlab
options.NailElectrodeCrd(isnan(options.NailElectrodeNumber)) = [];
options.NailElectrodeNumber(isnan(options.NailElectrodeNumber)) = [];
```

`NailElectrodeCrd` is N-by-3 - one row per coordinate - but the index has one
entry per coordinate, not per element. MATLAB therefore deletes single
*elements* and flattens what is left into one row. With three coordinates and
the second one left unassigned, a 3-by-3 matrix becomes a 1-by-8 row, and
GridFit is handed numbers that are no longer coordinates.

It only happens when a nailed coordinate is left unassigned; when every one
gets a number, nothing is removed. `tests/test_scriptEntryPoints.m` shows the
1-by-8 result.

The fix is two characters: `(isnan(...), :)`.

**Decision needed:** fix it? The intent is clear from the comment next to it,
"crds need to be removed".

**Status:** preserved. Present in v1.020, not introduced by the
restructuring.

---

## 21. `openProject` has the same name as a MATLAB function

**Where:** `src/project/openProject.m` (now `readIelFile.m`)

MATLAB has had its own `openProject`, for MATLAB Projects (`.prj` files),
since R2019a. With iElectrodes on the path, ours takes precedence, so
nothing breaks today. It would start to matter if iElectrodes itself became a
MATLAB Project, which the reference architecture recommends
(`iElectrodes.prj`): MATLAB's function would then be hidden by ours.

It also becomes moot if the backend moves into the `+ielectrodes` package,
where the full name is `ielectrodes.openProject`.

**Decision needed, when the packaging is decided:** rename it, or rely on the
package.

**Status: CLOSED.** After the separation, Alejandro proposed a layer between
frontend and backend, and it is a package: `src/+ielec/`
(`docs/API_LAYER.md`). The name `openProject` now belongs to the layer, as
`ielec.openProject`, which does not clash. The plain backend function was
renamed to what it does, `readIelFile`, and `saveProject` to `writeIelFile`
with it.

---

## 22. `PathName` means two different things

**Where:** `handles.work.FileName` / `PathName`, used by the file dialogs and
written into every `.iel`

`PathName` is both "the folder the project file is in" and "the folder the
last file dialog was in". Twenty of the GUI's file dialogs - opening the
project, loading a CT, exporting electrodes to BIDS or FieldTrip, loading
surfaces, and more - set it to wherever the user just browsed, and 22 open
there, the save-project dialog among them. So after exporting a `.tsv` to the Desktop,
`PathName` points to the Desktop, the next save dialog opens there, and that
is the `PathName` written into the `.iel`.

The reference plan proposes separating the two: the current project's file
name on one side, the last folder browsed on the other.

That is a change in behaviour - where dialogs open, and what the file
records - so it is not made here.

**Decision needed:** separate them? If so, which one should the `.iel` keep?

**Status:** open. Present in v1.020.

---

## 23. The voxel view keeps a deleted plot when no voxel passes the threshold

**Where:** `updatePlot` and `getThresholdedVoxels` in `electrodes_gui.m`

`updatePlot` clears the voxel view (`cla`) and draws the thresholded voxels
as a new scatter, stored in `handles.ui.sct` - but only if there are voxels
to draw:

```matlab
if ~isempty(crd)
    handles.ui.sct = scatter3(handles.axes1, ...);
end
```

When the thresholds leave no voxel, `ui.sct` still holds the previous scatter,
which `cla` has just deleted. `getThresholdedVoxels` then tests
`isempty(handles.ui.sct)` - false for a deleted object - and reads its
`BrushData`, which MATLAB refuses for a deleted object. So pressing Clus or
Fit after thresholding everything away would fail with "Invalid or deleted
object" instead of the "no points selected" warning.

Found by reading, while the voxel coordinates were moved into `work`; not
reproduced. `work.candidateVoxels` is set to the empty result in that case,
so the fix would be to test that instead of the plot object.

**Decision needed:** fix it? The same kind of fault as item 7.

**Status:** preserved. Present in v1.020.

---

## 24. The frame angles write beta into alpha

**Where:** `AlphaBetaChange` in `electrodes_gui.m`, which runs when the user
types the stereotactic frame angles of a planned depth electrode

```matlab
handles.project.targets{l}.alpha=alpha;
handles.project.targets{l}.alpha=beta;    % .alpha again - meant .beta
```

The second line writes beta into `.alpha`, and `.beta` is never set here.

It does no harm as things stand, because the function ends by calling
`updateTarget`, which recomputes both angles from the electrode's direction
and stores them correctly - so the wrong value lives only for a moment. It
would start to matter if that call were ever removed or moved.

Found while the frame geometry was taken out of the GUI; the line is kept,
marked with a comment.

**Decision needed:** fix it - one word - or leave it, since it has no effect?

**Status:** preserved. Present in v1.020.

---

## 25. A file with an empty parcellation keeps the previous project's

**Where:** `checkProjectStructure`, as the Open button used it

When a file holds `s.wmparc = []`, `checkProjectStructure` takes this branch:

```matlab
if  ~isfield(s,'wmparc')
    iel.wmparc=[];  iel.wmparcS=[];  iel.wmparcColors=[];
elseif isempty(s.wmparc)
    iel.wmparcColors=[];          % wmparc and wmparcS are not set
else
    ...
```

and leaves `wmparc` and `wmparcS` unset. The Open button ran it over the
running GUI's `handles`, so whatever those fields held before stayed: open a
patient with a parcellation, then such a file, and the second patient carries
the first patient's parcellation. Its colours are cleared, so it is not
drawn, but native-space labelling reads `wmparc`, so the second patient's
contacts would be labelled from the first patient's anatomy.

**How likely.** Not from files iElectrodes writes now: saving a project
without a parcellation goes through the same function, which drops the empty
field, so the file has no `wmparc` at all and the first branch is taken. It
needs a file that stores an empty `wmparc` - from an older version, or written
by another tool. Whether older versions wrote such files is not known here.

Found while moving Open onto the ielec layer. `ielec.openProject` builds the
project from the file alone, not on top of the previous one, so it cannot
happen there, and the Open button now uses it. For every file iElectrodes
writes, the result is the same as before; only for such a file does it
differ. `tests/test_ielecProjectFiles.m` makes one by hand and shows both.

The `elseif` branch itself is still in `checkProjectStructure`.

**Decision needed:** whether the branch should set `wmparc` and `wmparcS` to
`[]` as well, one line each, so that nothing else can hit it.

**Status: cannot happen in the Open button any more.** Present in v1.020.

---

## 26. Cancelling the mask dialog left half a CT in the project

**Where:** `LoadCTtool_ClickedCallback` in `electrodes_gui.m`

The Load CT button asked for the CT, read it into `project.TAC`, and then
asked for the brain mask. Everything that makes the CT usable - the mask,
`project.S2` from the CT, the intensity limits the threshold sliders work
from, and the redraw - was inside the `if maskfile~=0` branch. Cancelling
the mask dialog therefore left the project with a CT and none of it, and the
callback still saved that state. The views kept showing the MRI, while the
project held a CT that nothing could threshold: `thresholdCTVoxels` needs
`mask.img`.

It matters little in practice, because loading the CT again fixes it, but
saving in between would write the half-loaded project to the file.

Found while moving the button onto the layer. `ielec.loadCT` takes the CT
and the mask together - both are required - so the button now asks for both
first and loads nothing if either dialog is cancelled. The CT is read after
the mask has been chosen, not before, which is also the faster order for
the user.

**Decision needed:** none, unless you want cancelling the mask to keep the
CT. Then the mask would have to become optional everywhere that reads it.

**Status: FIXED in the Load CT button.** Present in v1.020.

---

## 27. Remove leaves the previous array's name in the name box

**Where:** `RemoveArrayPushbutton_Callback` and
`removePlanningArrayButton_Callback` in `electrodes_gui.m`

Removing an array moves the selection to the array before it - or to the one
that followed it when the first was removed - and the 3D view, the slices and
the sliders all follow. The name box does not: `editArrayName` still shows
the name of the array that was just removed, until something else writes it.

Everything else that changes the selected array sets it. The two navigation
buttons do it in one line each (`set(handles.editArrayName,'String',
handles.project.electrodes{l-1}.Name)`), and so do adding an array, opening a
project and clicking a contact. Only the two Remove buttons do not, in both
lists, and `setSelectedArray` does not write any control - it writes
`work.selection`.

So the box shows a name that belongs to no array. Typing in it then renames
the array that is now selected, which is the array whose name is not on
screen.

Found while moving the button onto the layer; it is display state, so the
layer has nothing to do with it - which is also why it is a good candidate
for the App Designer frontend, where the name field can be bound to the
selected array instead of written by hand in twelve places.

**Decision needed:** none, if the frontend is going to hold the selection in
one place. One line in each of the two callbacks fixes it in the GUIDE GUI
meanwhile.

**Status: open.** Present in v1.020.

---

## 28. The planning report walks the targets as a struct array

**Where:** `aLabelsTargets2txt_new` in `src/export/`, called by
`ReportPlanninguipushtool_ClickedCallback`

The report of the planning targets loops

```matlab
for n = 1:length(targets)
    if targets(n).frameDown
```

which reads TARGETS as a struct array. The project keeps them in a cell array
of structures - `project.targets{n}` - everywhere else: the GUI reads
`handles.project.targets{a}.x(1)`, `addArray` and `removeArray` treat both
lists the same way, and `checkElectrodeStructure` returns a cell. So
`targets(n)` is a 1x1 cell and the line fails with "Dot indexing is not
supported for variables of this type", before anything is written.

The button therefore cannot have worked on any project whose targets went
through `checkElectrodeStructure`. The electrode report beside it,
`aLabels2txt_new`, indexes `electrodes{n}` correctly, which is what the same
code looks like when it is right.

Found by `tests/test_ielecExport.m`, which writes every format both ways: the
button's own code and `ielec.export` fail identically here, so the test
requires them to be refused the same way rather than to produce the same file.

**Decision needed:** whether the targets were a struct array in some older
version - in which case a project saved then still opens - or the loop was
simply never run against a cell. The fix is `targets{n}` throughout the
function, four lines, and its own commit with a test that writes a report.

**Status: open.** Present in v1.020.

---

## 29. `buildSCE` does not give the same envelope twice

**Where:** `buildSCE` in `src/projection/`, through `vol2surf` and iso2mesh's
CGAL surface extractor

Building the smooth cortical envelope from the same surface, twice, in one
MATLAB session, gives two different meshes. The extractor prints its own seed
- `RNG seed 1648335518`, the same both times - and still returns a different
number of points: 2348 one time and 2310 the next, for a surface that had not
changed. The later steps are deterministic, so the difference comes from the
CGAL mesher, which is randomised internally.

What follows from it:

- two people who build an envelope from the same FreeSurfer surface get
  different envelopes, and so, after the brain-shift correction, slightly
  different contact coordinates. The difference is a fraction of a
  millimetre, well under the localization's own uncertainty, but it is there;
- a project cannot be rebuilt bit for bit from its inputs. Once the `.iel`
  file records the history of the calls that made it, the history will
  describe how the envelope was built without being enough to reproduce it;
- a test cannot compare two envelopes vertex by vertex.
  `tests/test_ielecSurfaces.m` compares them as surfaces instead - same
  bounding box and centre to a tenth of a millimetre, vertex count within
  five percent - which is what "the same envelope" can mean here.

Found while moving the surfaces onto the layer: the test passed on its own
and failed inside `run_all_tests`, which is what a randomised step looks like.

**Decision needed:** whether this matters for the paper's reproducibility
claims. If it does, the fix is to seed the extractor - iso2mesh passes its
options through, so it may be a matter of one setting - or to record the
envelope in the file as the authoritative one, which the `.iel` format
already does.

**Status: open.** Present in v1.020.
