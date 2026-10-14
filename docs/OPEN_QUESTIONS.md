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

Found while the frame geometry was taken out of the GUI, and kept with a
comment through the commits that followed.

**Both lines are now gone.** When the trajectory moved onto the layer as
`ielec.aimTarget`, the typed angles stopped being written at all: nothing ever
read either value - `frameTrajectoryEndPoint` takes the angles as arguments,
and `ielec.setFrame` overwrites `.alpha` and `.beta` at the end of the call
with the angles of the trajectory that came out. `tests/test_ielecAimTarget.m`
keeps the double write in its verbatim copy of the old code and proves the
results still match field for field, which is what "it did no harm" means
when it is measured rather than argued.

So the question as asked - fix the typo or leave it - no longer has a subject.
One question is left, and it is a different one.

**Decision needed:** should the angles the user *typed* be stored anywhere?
Today they are not: what the project records is the frame angles of the
resulting trajectory, which for a straight answer are the same two numbers,
and for a degenerate one are not. Storing the typed pair as well would be a
change in what the `.iel` file holds, not a typo fix.

**Status:** the typo is removed, behaviour unchanged. Present in v1.020, where
both lines are still there.

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
  `tests/test_ielecSurfaces.m` compares them as surfaces instead - the same
  bounding box and centre to within three voxels of the raster the envelope
  is extracted from, vertex count within five percent - which is what "the
  same envelope" can mean here. On that test's own stand-in the two builds
  come out much closer than the measure allows: the boxes within 0.04 mm,
  the centres within 0.13 mm, the counts within 1.6 percent.

Found while moving the surfaces onto the layer: the test passed on its own
and failed inside `run_all_tests`, which is what a randomised step looks like.

**Decision needed:** whether this matters for the paper's reproducibility
claims. If it does, the fix is to seed the extractor - iso2mesh passes its
options through, so it may be a matter of one setting - or to record the
envelope in the file as the authoritative one, which the `.iel` format
already does.

**Status: open.** Present in v1.020.

---

## 30. Numbering an array again throws away its name, its labels and its projections

**Where:** the Index button of the Localize panel, for an array that is
already in the project - `Indexpushbutton_Callback`, now
`ielec.indexArray` with `cfg.index`

The Index button has two halves. With contacts in progress it numbers them
and adds a new array. With none in progress it numbers the array on show
again, which is how a grid that came out in the wrong order is put right.

That second half keeps four things from the old array - the cluster numbers,
the brushed voxels, their weights, and a new adjacency matrix - and takes
everything else from a fresh structure. So an array numbered again comes back
with

- `Name` set to `'depth'` or `'grid'`, whatever the user had called it;
- `ch_label` back to `'1'`, `'2'`, `'3'`, ..., whatever the recording channels
  were called;
- `projection` empty: the brain-shift correction has to be run again;
- `space`, `method` and `methodParameters` empty, so the array no longer says
  which space it is in or how it was found.

The coordinates and the order are right, which is what the button is for. The
rest is lost quietly, and the array that comes back says it is in no
particular space.

`ielec.indexArray` keeps this exactly as it was: the same four fields are
carried over, in the same order, so that this commit changes nothing for
anyone. Once it is decided what should happen, the fix is in one place.

**Decision needed:** which of the four to carry over. The name and the
channel labels are the user's and should almost certainly survive - the
coordinates moved between contact numbers, so the labels would have to be
permuted rather than kept, and `reorderElectrodes` already knows how. The
projections are stale once the numbering changes, so clearing them is
defensible, but then the array should say so rather than look unprojected.
`space` and `method` describe where the array came from and did not change.

**Status: open.** Present in v1.020.

---

## 31. `reorderElectrodes` moves the cluster numbers the opposite way from the coordinates

**Where:** `reorderElectrodes` in `src/localization/`, called by the six
buttons under the grid - now through `ielec.reorderArray`

`reorderElectrodes(electrodes, newOrder)` is given a new order and moves
everything about the array with it. The coordinates are read through it:

    electrodes.x = electrodes.x(newOrder);

so the contact that sits at position `j` afterwards is the one that was at
`newOrder(j)`. The anatomical labels and the projections are read the same
way. The cluster numbers are not - they are written through it:

    tmp(electrodes.clusters == i) = newOrder(i);

so the CT voxels that belonged to contact `i` are given the number
`newOrder(i)`. To follow the coordinates they would have to be given the
position that `i` moved to, which is the inverse: the `j` for which
`newOrder(j) == i`.

For three of the six buttons this makes no difference, because their orders
are their own opposites: mirroring the columns twice, or the rows twice, or
reversing a line twice, is no change at all, and for such a permutation the
map and its inverse are the same. The other three are where it shows. Turning
left and turning right are opposites of each other, not of themselves, so
after a single quarter turn the contacts are numbered correctly and the voxels
behind them belong to the wrong contacts; four turns put it right again, since
four turns are no turn either way. The manual button takes whatever order the
user dragged the list into, which is its own opposite only by chance.

What the clusters are used for is drawing the voxels of the selected contact
and the Undo of a localization, so the effect is a display and an undo that
disagree with the array after a quarter turn or a hand-made order, not a wrong
coordinate in an export.

`ielec.reorderArray` keeps the behaviour exactly: it calls
`reorderElectrodes` with the same order the button computed, and
`tests/test_ielecReorder.m` compares against the button's own lines, so the
current behaviour is pinned rather than quietly changed.

**Decision needed:** whether the cluster numbers should be inverted. The fix
is one line in `reorderElectrodes` - `tmp(clusters == newOrder(j)) = j` - but
it changes what the quarter-turn buttons do to a project, so it belongs in a
commit of its own with a test that says which way is right.

**Status: open.** Present in v1.020.

---

## 32. A loaded label list is thrown away if the selection window is cancelled

**Where:** the "Label from list" button - `LabelListPushbutton_Callback`

The button asks for a file of recording channel names when the project has
none, keeps them in `project.elecListLabels` - which the `.iel` file
saves - and then opens the two-column window where the user picks the ones
this array uses.

Cancelling that window returns from the callback before `guidata`, so the
labels that were just read from the file are lost with the rest of the
callback's copy of the project. The next press asks for the file again.

The same happens in the middle of the loop: picking the wrong number of
labels prints "Select N electrodes" and reopens the window, and pressing
Accept with nothing selected returns - again without keeping the file.

Nothing is damaged; the file is simply read twice. It is written down because
the fix belongs to the App Designer frontend rather than here: with the
project held in one place instead of in a callback's copy, reading a file and
choosing from it stop being one transaction.

**Status: open.** Present in v1.020.

---

## 33. `checkProjectStructure` writes `fname` at the top level, where it means `mask.fname`

**Where:** `checkProjectStructure` in `src/project/`, the branch that reads a
mask saved by the old NIfTI tools

When a project file holds its brain mask as a raw image rather than as an SPM
volume, the structure is rebuilt around the MRI and the image put back into
it:

    iel.mask = iel.T1;        % take as a base structure
    iel.mask.img = s.mask;    % replace img
    iel.fname = 'mask.nii';

That last line almost certainly means `iel.mask.fname`. As written it puts a
field called `fname` beside the project's own fields, where it says nothing
about which file anything came from, and leaves the copied volume's `fname`
pointing at the MRI it was copied from.

Nothing reads it. `fname` is in none of the three name lists
(`projectFieldNames`, `workFieldNames`, `uiFieldNames`), so the lifts drop it
on the way into the three groups and it never reaches the `.iel` file again.
The mask itself is correct; only the name of the file it claims to come from
is wrong, and only for a project saved by iElectrodes 1.x with a raw mask.

Found while moving the start-up onto the layer: the three lists cover every
field an empty structure makes, and this is the one field that appears only in
that legacy branch.

**Decision needed:** whether it should be `iel.mask.fname`. It is one word,
but it changes what a converted old project records about its own mask, so it
belongs in a commit that says so.

**Status: open.** Present in v1.020.

---

## 34. The planning grid is fitted to the native envelope whatever space the project is in

**Where:** the "Fit grid to surface" button - `fitPlanningGridButton_Callback`,
now `ielec.fitTarget`

The button merges `vertices_SCE_L` and `vertices_SCE_R` - the patient's own
envelope - and fits the planned grid to that. It never looks at
`project.currentSpace`.

`processProjections`, the same correction for the localized arrays, does look:
`sceSurfaceForSpace` gives it the MNI template envelope from `work` when the
project is being worked in MNI space, and the patient's own from `project`
otherwise. `ielec.projectArrays` keeps that, with `cfg.space` defaulting to
`project.currentSpace`.

So the two halves of the same operation disagree - but not in the way it first
looks. `ielec.newTarget` lays the grid on those same two fields, so planning
and fitting always agree with each other, in any space. The disagreement is
between planning and localization: in MNI space the localized arrays are
projected onto `work.v_MNI_SCE` and the planned ones onto the patient's own
envelope, so the same project ends up holding two kinds of projection that
cannot be compared.

`ielec.fitTarget` reproduces the button: the space is written as `'Native'` in
one place, with a comment pointing here, and there is no `cfg.space` until
this is decided.

Alejandro's own question sits in the same place, as a commented-out block in
the button, now a comment in `ielec.fitTarget`:

    SPLIT LEFT AND RIGHT ???

i.e. whether a grid should be fitted to the hemisphere it is on rather than to
both hemispheres at once.

**Decision needed:** whether the planning fit should follow
`project.currentSpace` as the localization fit does, and whether it should use
one hemisphere or both. The first is a `cfg.space` with a different default;
the second changes the result for every grid near the midline.

**Status: open.** Present in v1.020.

---

## 35. A planning file can be loaded into a project that has no envelope

**Where:** `ielec.loadTargets` and the "Fit grid to surface" button

`ielec.newTarget` refuses to plan a grid in a project with no cortical
envelope, because there is nothing to lay it on. `ielec.loadTargets` has no
such check: it replaces `project.targets` from a `.mat` file whatever the
project holds.

So a plan made for one project can be loaded into a fresh one, and then Fit
grid to surface reaches `mergemesh` with two empty surfaces. In v1.020 and
until this commit that is `MATLAB:badsubscript` thrown inside `mesheuler`,
which `mergemesh` calls - "Index in position 2 is invalid" - so the message
names neither the surfaces nor the button.

`ielec.fitTarget` now says `ielec:noSurfaces` instead. That is the same
identifier `ielec.newTarget` and `ielec.placeTarget` use, but not quite the
same check: those two test `vertices_SCE_R`, while this one goes through
`envelopeFor` and so tests `vertices_SCE_L`. A project with one hemisphere and
not the other would be judged differently by the three, and the message would
say the project has no envelope when it has half of one. Neither
`ielec.loadSurfaces` nor `ielec.buildEnvelope` can produce such a project, so
this is about the check being honest rather than about a case that happens.

The frontend does not catch the error yet, so the user still sees a MATLAB
error - a clear one rather than a confusing one.

**Decision needed:** whether `ielec.loadTargets` should refuse a plan the
project cannot hold, or whether a plan without an envelope is a legitimate
state to be in - a plan loaded first and the surfaces built afterwards. The
second is the more useful, and is why the check was not added there.

**Status: open.** Present in v1.020.

---

## 36. Fit grid to surface silently does nothing when a depth target is selected

**Where:** the "Fit grid to surface" button - `fitPlanningGridButton_Callback`,
now `ielec.fitTarget`

`ELECTRODES2HULLCORRECTION` loops over the arrays it is given and projects the
ones whose `Type` is `'grid'` or `'strip'`. Given a single `'depth'` array it
warns `no grid electrodes to do projection` and returns it unchanged, so the
button writes the array back exactly as it was and redraws.

That looked unreachable - the Fit button lives in the Grids panel, and
`showPlanningPanel` follows the selected array's type. It is not.
`UpdateTargetEditBox`, which is what calls `showPlanningPanel`, runs only when
a project is opened and when the next/previous array buttons are pressed. Two
paths leave the Grids panel up while a depth target is selected:

- `PlanningSelectionGroup_SelectionChangedFcn` shows the Grids panel when the
  Grids radio is clicked, and does not change the selection. So: create a
  depth target, click Grids, press Fit;
- `removePlanningArrayButton_Callback` moves the selection with
  `setSelectedPlanningArray` and never calls `UpdateTargetEditBox`. Removing a
  grid can leave a depth target selected with the Grids panel still shown.

Either way the user presses Fit, sees a warning in the command window if they
are looking at it, and nothing happens to the array.

`ielec.fitTarget` reproduces this rather than refusing the call: refusing would
turn a warning into an error on a path a user can reach. The guard was written
and then taken out for that reason.

**Decision needed:** whether the button should be disabled when the selected
planning array is not a grid, or whether the panel should follow the selection
everywhere it changes. The second is the real fix and belongs to the App
Designer frontend; the first is two lines in the GUIDE app.

**Status: open.** Present in v1.020.

---

## 37. `checkElectrodeStructure` defends `beta` but not `alpha`

**Where:** the depth planning block of `checkElectrodeStructure`, around the
line `if ~isfield(elec,'beta'); elec.beta=[]; end`

The block fills in every field a depth planning array is expected to have, so
that an array saved by an older version can be read: `targetIn`, `targetOut`,
`FirstSecond`, `SecondLast`, `framePosition`, `frameDown`, `delta`, `beta`,
`azimut`, `elevation`. **`alpha` is not in the list**, although `beta` is and
the two are always written together - `estimateAnglesFrame`, now
`ielec.setFrame`, produces them in one call.

`UpdateTargetEditBox` reads `handles.project.targets{l}.alpha` to fill the
Alpha box. It gets away with it today because the backward-compatibility block
just above runs `estimateAnglesFrame` - which writes `alpha` - whenever
`frameDown` is missing or empty, and `checkElectrodeStructure` makes a missing
`frameDown` empty. So an old array without `alpha` is also an old array
without a usable `frameDown`, and the angles are recomputed before anything
reads them.

The gap is an array that carries a real `frameDown` but no `alpha`. Whether
any released version saved such a file is unknown; the asymmetry in the field
list is clearly an oversight either way, and it is the kind that goes unnoticed
until a user opens a file nobody has.

`ielec.setFrame` writes `alpha` and so closes the gap wherever it is called,
and `tests/test_ielecSetFrame.m` checks that `alpha` is the one field it adds -
which is this finding, written as a test.

**Decision needed:** whether to add `alpha` to the list. One line, beside
`beta`, and it makes the structure self-consistent.

**Status: open.** Present in v1.020.

---

## 38. The New target button drew a placeholder, not the electrode it planned

**Where:** `NewTargetpushbutton_Callback`, and `showPlanningArray` /
`updateTarget` in `electrodes_gui.m`

The button built a depth planning array with its coordinates set to a
placeholder - `target.x = (0:5:45)'`, and the same for y and z - and only
then worked out where the contacts really go. The order it did that in was:

1. build the array, coordinates = the placeholder;
2. `addtarget2structure`, which added it and called `showPlanningArray`;
3. `updateTarget`, which replaced the coordinates with the real trajectory.

`showPlanningArray` does not only move the three sliders. It sets
`ui.updatePlots.targets`, `.targetLines` and `.views2D` and calls
`updateElectrodes3D` and `updateTAC`, both of which read the whole of
`.x`, `.y`, `.z`: the contact cloud, the lines between contacts, and the
three 2-D views. And `updateTarget` never redraws - it recomputes, writes the
edit boxes, labels the contacts and works out the frame angles, and returns.

So step 2 drew the placeholder and step 3 silently replaced the data behind
it. After pressing New target the user was looking at a ten-contact chain
running to (45, 45, 45) at 8.66 mm spacing, while the project held the real
electrode: ten contacts at 5 mm ending at (25.98, 25.98, 25.98). The last
contact on screen was 32.94 mm from where it actually was. The picture
corrected itself at the next redraw - any slider move, any box edited - so it
was a first impression that was wrong, not a lasting error.

`ielec.newDepthTarget` lays the contacts out before it returns, so there is
no placeholder left to draw and the frontend's `showPlanningArray` draws the
electrode that is in the project. The first contact is unchanged - it is the
deep end either way - so the three sliders still land where they did.

This is a **visible difference**, named in the commit that introduced it, and
the only one in it. It is recorded here rather than being presented as a
tidy-up, because it changes what a user sees for the same click.

**Decision needed:** none for the drawing, which is now right. But
`updateTarget` redrawing nothing is worth knowing about: every caller has to
remember to redraw afterwards, and the twelve depth-target callbacks each do
it by hand. In the App Designer frontend that belongs in one place.

**Status: changed in v2.** Present in v1.020, where the placeholder is still
drawn.

---

## 39. The layer does not name the `work` fields a script has to read

**Where:** `ielec.loadCT` / `ielec.openProject` and `ielec.fitArray`, against
`examples/exampleHeadlessWorkflow.m`

Writing the headless example through the layer turned up two places where a
script has to know a field name that no `ielec` help mentions. Both are small;
together they are the difference between the layer being an interface and
being a convention.

**1. The CT's intensity limits.** The first thing the example does after
opening a project is set a threshold at half the CT's range:

    cfg.lowThreshold = 0.5 * (work.maxValue - work.minValue) + work.minValue;

`ielec.thresholdCT` is right to take an intensity rather than a slider
position - a recorded threshold has to mean the same thing without the
window. But the limits it needs are `work.minValue` and `work.maxValue`, and
those names appear in no help text in `src/`: `ielec.loadCT` says "WORK gets
the CT's intensity limits" and `ielec.openProject` says "the CT intensity
limits", neither naming the fields. A scripter cannot write the toolbox's own
default threshold without reading the source.

**2. The spacing an array was fitted with.** The example re-fits an electrode
with the spacing the stored one used, which it reads from
`reference.methodParameters.fixM1` and `.fixM1_BF`. `ielec.fitArray` takes
`cfg.spacing` and `cfg.firstSecondSpacing`, so the script has to translate
between the layer's names and the backend's, and `methodParameters` is
documented nowhere in `src/+ielec/`.

**3. What a space needs loaded.** `ielec.label` with no `cfg.space` follows
`project.currentSpace`, which is right. But the MNI branch reads the template
atlas out of `work` - `work.MNI_S_matrix`, `MNIlabels`, `MNIprob` - and
`ielec.openProject` does not load it; only `ielec.startSession` does. So a
script that opens an MNI-space project and labels it gets `ielec:noAtlas`,
while the same two lines on a Native-space project work. The window never
meets this because it opens a session at start-up. The example now says so in
a comment, and opens a Native project; before the layer it called
`labelElectrodesNative` unconditionally and so did not care.

None of the three is a defect: the example runs, and the fields are stable.
But all three are reach-ins past the interface, or things the interface does
not say, and the point of the layer is that there should not be any.

**Decision needed:** whether to name these fields and this prerequisite in
the help of the functions concerned - one line each in `ielec.loadCT` and
`ielec.openProject`, and a sentence in `ielec.fitArray` - or to answer them
with a reporting call, the way `ielec.projectionState` reports what the
projection would do. A `ielec.ctRange` that returns the limits would let a
script ask instead of reach; the cost is a function for two numbers.

**Status: open.** New in v2, and a consequence of the layer rather than
something v1.020 had.

---

## 40. Anchors and hand-placed contacts are the same list, and the Fit button anchors to all of it

**Where:** `work.GS`, the Add coordinate button, and the Fit button -
`ielec.addCoordinate`, `ielec.cluster` and `ielec.fitArray`

This is Alejandro's front-end note, comments 3 and 4R3: *"Consider separating
anchors from added coordinates in the work structure"* and *"Ideally, we need
a new variable to store anchors."* Here is what the code does today, so that
the question can be answered against it.

`work.GS` holds the contacts in progress, and three things put them there:

- `ielec.cluster`, which appends the centres it found;
- `ielec.addCoordinate`, the Add coordinate button, which appends one by
  hand with a cluster of its own;
- nothing else.

The front-end note has the Add coordinate button under **both** Localization
via Clustering and Localization via Grid Fit, with "(same function and
variable)" beside the second, and a counter that reads "number of electrodes"
in one panel and "number of anchors" in the other with "(same function)". That
is accurate: it is one button, one variable and one counter, wearing two
names.

**What the Fit button does with it.** `cfg.useNailedContacts` is set to
`~isempty(work.GS)`, so pressing Fit anchors the fit to **everything** in the
list - the clustered contacts as much as the hand-placed ones. That is the
normal workflow: cluster, then fit, and the clustering holds the fit.

**So the separation is not a refactor.** If anchors become their own
variable, then after clustering the anchor list is empty and Fit no longer
holds to the clustered contacts, which changes the main path through the
program. Two readings of the note, and they differ in what the program does:

1. **Anchors are the hand-placed ones only.** The clustered contacts stop
   holding the fit. The note's "Use anchors (using add coordinate manually)"
   reads this way. It is a real change in what Fit produces.
2. **Anchors are both, and the new variable only records which came from
   where.** Fit behaves as it does now, and the separation buys the frontend
   two counters and the ability to show them differently. Behaviour is
   preserved.

**It also changes the `.iel` file.** `GS`, `clusters`, `brushCrd`,
`brushWeight` and their `old*` copies are all in `workFieldNames`, so they
are saved. A new `work.anchors` would be saved too, which puts this in the
same box as `history` and `schemaVersion`: a format change, needing the test
that v1.020 can still open a v2 file.

**Decision needed, and it is the one that blocks the work:** which of the two
readings? If (1), say so and it becomes a named behaviour change with its own
commit. If (2), the work is bookkeeping and can go in with the format change.

What has been done in the meantime is the part that needs no decision: the
four buttons that change the list - Add, Delete, Clear and Undo - now go
through the layer instead of editing `work` in the frontend, so whichever
reading is chosen, the change is inside the layer rather than spread across
four callbacks.

**Answered, and it is neither reading.** Alejandro, by email, 14 October 2026:

> What I would like to do in the new version it to have two separate
> structures in work:
>
> 1. Work.GS: Coordinates selected via clustering or manual approach. These
>    are later used in the indexing step.
> 2. Work. Anchors (or any other name that makes sense): manually selected
>    coordinates (could use the same selections procedure as 1) that are used
>    in the GridFit algorithm as anchors.
>
> That also means that the user interface will have two buttons, one for each
> procedure (a) clustering + indexing and b) GridFit).

So `work.GS` is not split. It keeps exactly what it holds today - clustered
and hand-placed together - and feeds the indexing step. A **second** list is
added beside it, filled by hand only, and the GridFit algorithm anchors to
that one instead. Both readings above asked which half of `work.GS` the
anchors are; the answer is that neither half is, and the anchors are a list
of their own.

It reaches reading (1)'s consequence by a different route. After clustering,
`work.anchors` is empty, so the Fit button no longer holds the fit to the
clustered contacts. That is a change on the main path through the program -
cluster, then fit - and it gets named where it happens.

**Done in two commits,** because the list and the redirection are two
different things and only the second changes behaviour:

1. *The list exists and the layer can fill it.* `work.anchors` and
   `work.oldanchors` join `workFieldNames`, `checkProjectStructure` defaults
   both to empty so that every file written before them opens unchanged, and
   `ielec.addCoordinate`, `ielec.removeCoordinate` and
   `ielec.clearCoordinates` take a `cfg.group` of `'contacts'` - the default,
   so every existing caller gets the behaviour it had - or `'anchors'`.
   Nothing reads `work.anchors` yet, which is what keeps `work` and the rest
   of `project` bit-identical for every existing caller.

   One thing is not identical, and it is named rather than undone:
   **`project.history` gains the group.** `cfg.group` is a defaulted option,
   so `checkCfg` fills it in and `recordStep` writes what `checkCfg` made -
   which is the design's own rule about the recorded cfg. Measured against
   the commit before:

   | function | recorded before | recorded now |
   |---|---|---|
   | `ielec.addCoordinate` | `{coordinate}` | `{coordinate, group}` |
   | `ielec.removeCoordinate` | `{coordinate, tolerance}` | `{coordinate, tolerance, group}` |
   | `ielec.clearCoordinates` | `{}` | `{group}` |
   | `ielec.undoCoordinates` | `{}` | `{}` |

   The history is serialised into the `.iel`, so the file contents change for
   any project those three touch. It is the same thing
   `ielec.removeCoordinate` already did with its defaulted `cfg.tolerance`,
   and a replayed step that did not carry the group would have to guess which
   list it meant - so the group belongs in the record. What it is not is
   "nothing changed".
2. *`ielec.fitArray` nails to `work.anchors` instead of `work.GS`.* One named
   behaviour change, on its own.

Two things the answer settles by implication rather than directly, decided
here because they are small and the alternative is guessing twice:

- **an anchor is a coordinate and nothing else.** `work.clusters`,
  `work.brushCrd` and `work.brushWeight` stay the contacts' bookkeeping.
  `gridFit` is given only the nail positions, and a row in `work.clusters`
  for an anchor would claim a cluster of brushed voxels that does not exist.
  So `ielec.removeCoordinate` on an anchor takes the row and nothing with
  it, where on a contact it still renumbers the clusters above it.
- **one Undo still covers one change, wherever it was made.** `keepForUndo`
  copies all five lists whichever one is about to change, rather than keeping
  a step per list. That is the depth the toolbox has; a deeper undo is a
  frontend question, as it was before.

The field is `anchors`, lower case, which is what `clusters`, `brushCrd` and
`options` look like. The email's `Work.Anchors` names the thing rather than
the field, and the note says any sensible name will do.

**The third part of the answer is frontend work:** two buttons, one per
procedure. Until those exist the window has one Add coordinate button and it
writes to the contacts, as it always has - so after the second commit the Fit
button has no way to be anchored from the window at all, and the nailing
feature is reachable only from a script. That is a consequence worth writing
down rather than discovering, and the two buttons are what answers it.

**Status: answered; the list is in, the redirection follows.** The conflation
is in v1.020 too.

---

## 41. A recorded step costs 4.5 kB of container, whatever is in its cfg

**Where:** `docs/API_LAYER.md`, "Recording each step"; the shape created in
`checkProjectStructure` and written by `writeIelFile`

The design's rule for the processing history is that *"the cfg holds settings
and file names only, never images or other large data, so the file does not
grow."* The first half is right and worth keeping. The second does not follow,
and the reason is the container rather than the contents.

A `.iel` file is `-v7.3`, which is HDF5, and the history is a cell of structs.
Every cell element and every nested struct becomes an HDF5 object with its own
header, so the cost per step is almost independent of what the cfg holds.
Measured with the design's own example step - `ielec.thresholdCT` with a low
and a high threshold, plus the function name, the date and the version:

| steps | file | per step |
|---|---|---|
| 0 | 1,928 B | |
| 1 | 11,552 B | |
| 10 | 49,992 B | ~4,800 B |
| 100 | 448,248 B | 4,463 B |
| 500 | 2,228,888 B | 4,458 B |

In the real example project, a hundred steps take `exampleNativeSpace.iel`
from 47,231,649 to 47,670,401 bytes: +0.4 MB.

The same five hundred steps are **8,586 bytes in total** in `-v7` - 17 bytes a
step, a 260-fold difference - so this is the container, not the data. Three
other shapes, measured at five hundred steps:

| shape | per step |
|---|---|
| cell of structs (what the design says) | 4,458 B |
| struct array | 3,357 B |
| cell of `jsonencode`d steps | 652 B |
| the whole history as one JSON string | 13 B |

**How much does it matter?** A real session is hundreds of ielec calls:
threshold, select, cluster, fit, index, six reorders per array, a naming call
per array and per contact, nine moves per planning target. At five hundred
steps the history is ~2.2 MB of overhead for ~25 KB of settings, written on
every save. Against a 47 MB project that is 5%; against a project that is an
MRI and a few arrays it is a visible share.

**Why now:** the format commit has landed and nothing fills the history yet.
Changing the shape later is another format change, with another round of
1.020 compatibility work. Changing it now costs nothing, because there is
nothing to migrate.

**Answered, by separating the two shapes.** The question as posed - keep the
readable cell, or take the cheap string - was a false choice: the cell is what
makes a history readable *in the project*, and the string is only how it
reaches the disk. So the project holds the cell the design specifies, and
`writeIelFile` serialises it on the way out while `checkProjectStructure`
decodes it on the way in - `encodeHistory` and `decodeHistory`, two functions
of twenty lines.

Measured after the change, on the history alone rather than as a delta buried
in a 47 MB file, and with **distinct** steps rather than repeated copies of
one:

| steps | JSON | file | on disk, per step |
|---|---|---|---|
| 1 | 124 chars | 9,112 B | 248 B |
| 10 | 124/step | 11,336 B | 247 B |
| 100 | 124/step | 15,448 B | 66 B |
| 500 | 124/step | 20,498 B | 23 B |
| 1000 | 124/step | 29,740 B | 21 B |

against the same distinct steps as a cell of structs: 4,401 B/step at a
hundred, 4,435 at five hundred. So the reduction is about **a hundredfold**,
and `project.history{3}.cfg.lowThreshold` reads exactly as it did.

The only fixed figure is **124 characters of JSON a step**. The on-disk column
falls as the history grows because the file is deflated, so "bytes per step"
is not a cost - it is a compression ratio. An earlier version of this item
quoted 27 B and 9 B a step; those came from a hundred and five hundred
*identical* steps, which deflate to almost nothing. The proof is that a
hundred and five hundred identical steps give the same file size to the byte.

What it gives up is type, and that is the part worth knowing. JSON does not
carry class or orientation: an `int32` comes back a double of the same value,
a column vector comes back a row, an empty char comes back 0-by-0.
`tests/test_ielFormat.m` pins which types survive and which flatten, so a
change in MATLAB's own encoder shows up there. A cfg holds thresholds, file
names, counts and flags, so nothing a recorded step carries today needs more
than JSON gives - but a cfg field that has to survive byte for byte must not
be put in a history.

Two alternatives were rejected. `-v7` instead of `-v7.3` would have fixed the
cost for the whole file at 17 bytes a step, but it changes how every image is
stored and caps a variable at 2 GB, which is a far larger change than the
history warrants. `getByteStreamFromArray` would have been exact and smaller
still, but it is not a documented function, and a `.iel` file holds patient
data that has to open in ten years.

**Decision still open for Alejandro:** nothing above needs him, but the type
flattening is the kind of thing he may want written differently - or may want
the history to carry a `schemaVersion` of its own, so that a future encoding
can be told from this one.

**Status: answered in the commit that serialised it.** New in v2; there was no
history to size in 1.020.

---

## 42. A cfg read back out of the history cannot always be replayed

**Where:** `encodeHistory` / `decodeHistory`, against `ielec.newTarget:52` and
`ielec.placeTarget:75`

`docs/API_LAYER.md` names a "save the session as a script" feature as one of
the things the processing history is for. That does not work yet, and the
reason is two lines of validation disagreeing with the storage.

JSON does not carry orientation. A JSON array decodes to a **column**, so a
`cfg` field that was a 1-by-3 row when it was recorded comes back 3-by-1.
Measured on a real save and reopen:

    cfg.centre as recorded : [17.7419 -37.5927 67.254]    size [1 3]
    cfg.centre as reopened : [17.7419; -37.5927; 67.254]  size [3 1]
    values identical       : yes
    replayed into ielec.newTarget: ielec:badOption,
        "cfg.centre must be one point, as [x y z]."

`ielec.newTarget` and `ielec.placeTarget` check `isequal(size(v), [1 3])`.
`ielec.addCoordinate` and `ielec.aimTarget` check `numel(v) ~= 3` and then
normalise with `(:)'`, so they replay fine. The layer is inconsistent with
itself about this, and only half of it can be driven from a recorded cfg.

The same applies to `default_ielectrodes_options`: its `image_voxdim` is a
1-by-3 row, and a recorded `cfg.options` comes back with a 3-by-1 - which
`ielec.setOptions` accepts and stores, so the column then travels into
`work.options`. It survives today only because `loading_images_SPM` happens to
do `voxdim = abs(voxdim(:)')`. Nothing guarantees that for the next consumer.

**Answered: (1), the six functions that take a point agree.**
`ielec.newTarget` and `ielec.placeTarget` check `numel(v) ~= 3` and normalise
with `(:)'`, which is what `ielec.addCoordinate`, `ielec.removeCoordinate`,
`ielec.aimTarget` and `ielec.newDepthTarget` already did. Two lines, and the
six agree about what a point is.

Six, not four: the first draft of this item said four and was simply
miscounted - `ielec.removeCoordinate` and `ielec.newDepthTarget` were already
in the normalising half and were left out of the tally.

`ielec.pointLabel` is the seventh function that takes coordinates and it is
**not** included, deliberately. Its `cfg.coordinate` is an N-by-3 *list*, and
there a 3-by-1 is ambiguous rather than merely unoriented: one point written
as a column, or three points of one coordinate each? Guessing would be worse
than refusing, so it keeps `size(cfg.coordinate, 2) ~= 3`, which is what its
help has always promised. It is also one of the nine functions that record no
step, because it only reports - so there is no recorded `ielec.pointLabel`
cfg to replay, and the replay argument does not reach it.

It is a deliberate behaviour change - the first in this effort - because the
two functions now accept input they used to refuse. Nothing that worked
before stops working: the GUI and every test pass 1-by-3, and the count is
still checked, so two numbers or four are refused as they were. The
normalisation is not cosmetic in `ielec.placeTarget`: `mean([x y z])` is
1-by-3, so a 3-by-1 `cfg.offset` expands into a 3-by-3, and
`placePlanningGrid` then throws `MATLAB:sizeDimensionsMustMatch`. Measured -
an earlier draft of this item said it would *misplace* the grid, which is
wrong and the kinder failure of the two. It stops the call, with an
identifier that is not one of ours.

`tests/test_ielecPlanningGrid.m` now takes a recorded `ielec.newTarget` step
through `encodeHistory`/`decodeHistory`, confirms its centre comes back
3-by-1, and replays it - producing the same grid. That is the thing this item
existed for.

What is left of the original question is about the *rest* of a cfg rather
than a point: a recorded `cfg.options` carries an `image_voxdim` that also
comes back a column, and nothing yet promises that every recorded cfg is
replayable - only that a point is.

**The three ways out, as they were written.** Either

1. the four functions that take a point agree to accept three numbers in any
   orientation, as two of them already do - two lines, and it makes every
   recorded cfg replayable; or
2. `decodeHistory` restores orientation, which it cannot do in general because
   the information is not in the file - it would need the encoder to record
   the shape of every numeric field, which is a bigger format commitment than
   the history itself; or
3. the history is documented as a record to read rather than to replay, and
   the "save as a script" idea needs the shapes written down separately.

(1) is the small one and the layer is already half-way there. It is a
behaviour change in two layer functions - they would accept input they refuse
today - so it belongs in a commit that says so, not in the format commit.

**Status: answered for a point; open for a whole cfg.** New in v2; there was no history to replay in 1.020.

## 43. The layer checks that an option is numeric, not that it is a number it can use

**Where:** every `isnumeric` in `src/+ielec/`, measured on
`ielec.newTarget:52` and `ielec.placeTarget:75`

`isnumeric` is a wider net than the layer wants, and `isfinite` does not
narrow it the way it looks as though it does. Measured in R2023b:

    isfinite(1+0.5i)          1     % a complex triple passes the guard
    isnumeric(sparse([1 2 3])) 1    % so does a sparse one
    isfloat(int32(1))          0
    isnumeric(int32(1))        1    % and so does an integer one

Driven through `ielec.newTarget` with `cfg.centre` on the example project's
envelope, 4 by 5 at 10 mm:

    complex(centre, [0 0 0.5])  ACCEPTED  grid shift 0.000 mm  recorded double
    sparse(centre)              ACCEPTED  grid shift 0.000 mm  recorded double
    single(centre)              ACCEPTED  grid shift 0.000 mm  recorded SINGLE
    int32(round(centre))        refused   MATLAB:mtimes:integerNotSupported
    [true true true]            refused   ielec:badOption

Two different problems, and neither is what you would guess:

**The integer is a rule 5 breach.** An `int32` centre reaches the geometry and
fails there, so the caller gets `MATLAB:mtimes:integerNotSupported` from
`ielec.newTarget` and `MATLAB:mixedClasses` from `ielec.placeTarget`. The
layer promises its own identifiers. Replacing `isnumeric` with `isfloat`
would turn both into `ielec:badOption`, which is an error becoming a better
error - nothing that works today stops working, because neither works today.

**The complex number does not misplace anything - it quietly empties the
record.** The grid it plans is identical to the real-valued one, to 0.000 mm,
because the geometry discards the imaginary part on the way. The damage shows
up one save later: `jsonencode` raises
`MATLAB:json:UnsupportedComplexDataType`, so `encodeHistory` falls back to a
note and that step comes back as

    "cfg":"<not recorded: Unable to encode complex valued objects of
     class double as JSON-formatted text.>"

The call succeeded, the grid is right, and the provenance of it is gone. A
`sparse` centre behaves the same way.

`single` is the mild case: identical grid, but the step records
`cfg.centre` as `single` where every other step records a double, and JSON
brings it back as a double - so a replayed step is not the recorded one,
class for class.

**Why this is written down rather than fixed.** `isfloat` alone is free, but
`isreal` and `~issparse` are not: a complex or sparse centre *works today* and
plans the correct grid, so refusing it turns a success into an error. That is
exactly the change this effort has made by accident before and now checks for
deliberately. The honest fix is one decision taken once for the whole layer -
what classes an option may have, applied to all six point-takers and to
`spacing`, `rotation`, `index`, `tolerance` and the rest - not two conjuncts
smuggled into a commit about orientation. It wants its own commit and a
sentence in `docs/API_LAYER.md` saying what a number is.

Nobody reaches any of this from the window: the GUI passes doubles from
`str2double` and the cursor. It is a script, or a typo in one, that gets here.

**Status: open.** The `isnumeric` guards are v2; the geometry that fails on an
integer is 1.020's.

## 44. A one-by-one planning grid is a single contact at NaN

**Where:** `ielec.newTarget:58` (the rows and columns check), into
`newPlanningGrid` / `tangentialGrid`

`ielec.newTarget` requires `cfg.rows` and `cfg.columns` to be positive whole
numbers, which 1 and 1 are. Measured on the example project:

    rows=1 columns=1   ACCEPTED   1 contact,  x=NaN y=NaN z=NaN
    rows=1 columns=5   ACCEPTED   5 contacts, no NaN
    rows=5 columns=1   ACCEPTED   5 contacts, no NaN
    rows=2 columns=2   ACCEPTED   4 contacts, no NaN

Only the 1-by-1 is degenerate: a single contact has no extent in either
direction, so there is nothing for the tangent plane to be computed from. The
grid is created, added to `project.targets`, named, counted and recorded as a
step like any other - and every coordinate in it is `NaN`.

It is reachable from the planning panel: the rows and columns boxes take any
positive whole number, so typing 1 in both and pressing the button makes one.
The frontend would then draw nothing and show a target that cannot be moved,
turned or exported to anything meaningful.

A single planned contact is not an absurd thing to want - a one-contact depth
target is what `ielec.newDepthTarget` is for, with two points to orient it.
What is absurd is a *grid* of one. The two candidate answers are to refuse
`rows == 1 && columns == 1` with `ielec:badOption`, or to let the geometry
answer and refuse the result when it comes back non-finite, which would also
catch whatever else is degenerate that has not been found yet. The second is
the better guard and the bigger change.

Not fixed here: refusing it is a behaviour change in a function this commit
is already changing for a different reason, and one commit says one thing.

**Status: open.** Pre-existing - the guard is v2, but the geometry it calls is
1.020's and takes 1-by-1 the same way.
