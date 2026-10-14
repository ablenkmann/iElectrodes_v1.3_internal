# `handles` field mapping: `project` / `work` / `ui`

Field-by-field classification of the state currently held in the `handles`
struct of `electrodes_gui.m`, following the three-structure organisation
proposed in Alejandro's second architecture discussion:

| Structure | Holds | Saved with the patient project |
|---|---|:---:|
| `project` | Patient data and **accepted** results | yes |
| `work` | Current operation, settings, temporary results | usually no |
| `ui` | Interface objects and presentation state | no |

This is the task that discussion names as the first concrete step, because a
field cannot be moved safely until its readers, its writers and its true owner
are known.

One field of `project` is not in this inventory and cannot be: `history`,
added in iElectrodes 2, was never a `handles` field. It holds the cfg of every
`ielec` call that changed the project, it is saved with the patient data, and
`PROJECTFIELDNAMES` lists it beside the migrated fields. See
`docs/API_LAYER.md`, "Recording each step".

## How each field was classified

Classification is derived from the source, not from the field names. Three
signals were used:

1. **Is the field ever assigned?** A field that is only ever read through
   `get(handles.X, …)` and never written is a control created by GUIDE, so it
   belongs to `ui` by construction. 106 of the 166 fields are in this group.
   The remaining 60 carry real state.
2. **Is it handled by `checkProjectStructure`?** That function defines what is
   written to and read from `.iel` files, so anything it touches is currently
   treated as part of the saved project.
3. **Is it reset by `defaultGuiVariables`?** Anything reset at start-up and on
   every new project is session state, not patient data.

Counts below are references in `electrodes_gui.m` as of the v2 restructuring.

## Summary

| Structure | Fields | References | Notes |
|---|---:|---:|---|
| `project` | 22 | 820 | the patient |
| `work` | 21 | 301 | in progress, settings, shared resources |
| `ui` (state) | 17 | 519 | graphics objects and derived display caches |
| `ui` (GUIDE controls) | 106 | 647 | never assigned; sliders, axes, buttons, panels |
| **total** | **166** | **2 287** | |

### `project` — patient data and accepted results

| Field | Refs | Touched by | In `.iel` | Meaning |
|---|---:|---:|:---:|---|
| `targets` | 304 | 44 fn | yes | Planning targets: geometry, spacing, angles, projections |
| `electrodes` | 213 | 28 fn | yes | Electrode arrays: coordinates, channel labels, projections, per-array processing parameters |
| `S2` | 58 | 27 fn | yes | Image-to-world (anatomical) transformation matrix |
| `T1` | 48 | 29 fn | yes | Patient MRI volume with its spatial metadata |
| `TAC` | 25 | 6 fn | yes | Patient CT volume (TAC = tomografia axial computarizada) |
| `vertices_SCE_R` | 24 | 15 fn | yes | Right SCE vertices |
| `vertices_SCE_L` | 23 | 15 fn | yes | Left smooth cortical envelope vertices |
| `currentSpace` | 20 | 18 fn | yes | Coordinate space the stored coordinates are in ("Native" / "MNI") |
| `wmparc` | 15 | 4 fn | yes | FreeSurfer parcellation volume for this patient |
| `faces_SCE_L` | 11 | 5 fn | yes | Left SCE faces |
| `faces_SCE_R` | 11 | 5 fn | yes | Right SCE faces |
| `verticesR` | 10 | 4 fn | yes | Right pial surface vertices |
| `mask` | 9 | 4 fn | yes | Brain mask derived from the MRI |
| `verticesL` | 9 | 4 fn | yes | Left pial surface vertices |
| `facesL` | 8 | 4 fn | yes | Left pial surface faces |
| `facesR` | 8 | 4 fn | yes | Right pial surface faces |
| `wmparcS` | 7 | 3 fn | yes | Transformation of the parcellation volume |
| `elecListLabels` | 5 | 1 fn | yes | Imported recording-channel label list |
| `AnnotLabel_L` | 3 | 2 fn | yes | Left surface annotation labels |
| `AnnotLabel_R` | 3 | 2 fn | yes | Right surface annotation labels |
| `AnnotColortable_L` | 3 | 2 fn | yes | Left annotation colour dictionary |
| `AnnotColortable_R` | 3 | 2 fn | yes | Right annotation colour dictionary |

### `work` — working data, settings, temporary results

| Field | Refs | Touched by | In `.iel` | Meaning |
|---|---:|---:|:---:|---|
| `PathName` | 85 | 15 fn | yes | Last browsing directory |
| `GS` | 42 | 11 fn | yes | Unfinished contact coordinates; also used as fitting anchors |
| `options` | 33 | 15 fn | no | Processing settings - scientific part only; see the split below |
| `clusters` | 24 | 8 fn | yes | Voxel-to-contact cluster assignment |
| `brushCrd` | 16 | 8 fn | yes | Coordinates of the currently selected voxels |
| `brushWeight` | 16 | 8 fn | yes | Intensities of the selected voxels |
| `minValue` | 13 | 3 fn | yes | CT intensity lower limit; recomputable from TAC |
| `oldGS` | 9 | 8 fn | yes | Undo copy of GS |
| `FileName` | 9 | 3 fn | yes | Current project file name |
| `oldclusters` | 8 | 7 fn | yes | Undo copy of clusters |
| `oldbrushCrd` | 8 | 7 fn | yes | Undo copy |
| `oldbrushWeight` | 8 | 7 fn | yes | Undo copy |
| `maxValue` | 8 | 4 fn | yes | CT intensity upper limit; recomputable from TAC |
| `f_MNI_SCE` | 5 | 2 fn | no | MNI template SCE faces |
| `f_MNI` | 4 | 1 fn | no | MNI template surface faces |
| `v_MNI_SCE` | 3 | 2 fn | no | MNI template SCE vertices |
| `uitable_elecNum` | 2 | 1 fn | no | Anchor contact numbers for GridFit - numeric data despite the name |
| `MNIprob` | 2 | 2 fn | no | MNI probabilistic atlas volumes |
| `MNIlabels` | 2 | 2 fn | no | MNI atlas label names |
| `MNI_S_matrix` | 2 | 2 fn | no | MNI-to-voxel transformation |
| `v_MNI` | 2 | 1 fn | no | MNI template surface vertices |

### `ui` — presentation state and manually created graphics

| Field | Refs | Touched by | In `.iel` | Meaning |
|---|---:|---:|:---:|---|
| `updatePlots` | 220 | 91 fn | no | Redraw flags - which views still need refreshing |
| `colors` | 92 | 7 fn | no | Display colour and marker palette |
| `cross` | 80 | 3 fn | no | Crosshair line graphics handles and position |
| `plot3Dhandles` | 60 | 1 fn | no | Handles of the 3-D electrode graphics objects |
| `cursor` | 15 | 7 fn | no | Current cursor / slice position |
| `imgW` | 11 | 4 fn | no | Fused MRI+CT display image - derived, recomputable |
| `wmparcColors` | 7 | 2 fn | yes | Parcellation colour volume - derived from wmparc + LUT |
| `sct` | 6 | 2 fn | no | scatter3 object holding the thresholded voxels |
| `layout` | 5 | 1 fn | no | Panel layout state |
| `AnnotColor_L` | 4 | 3 fn | yes | Left annotation colours - derived |
| `AnnotColor_R` | 4 | 3 fn | yes | Right annotation colours - derived |
| `rotate3d` | 4 | 2 fn | no | 3-D rotation interaction object |
| `color` | 3 | 1 fn | no | Single working colour value |
| `viewPoint` | 3 | 1 fn | no | Camera position |
| `output` | 2 | 2 fn | no | GUIDE standard output handle |
| `pathstr` | 2 | 1 fn | no | Toolbox installation folder |
| `brushObj` | 1 | 1 fn | no | Brush interaction object |

## Cases that need a decision

### 1. Seventeen `work` / `ui` fields are currently saved into `.iel` files

`checkProjectStructure` writes these to the project file even though they are
not patient data:

`GS`, `oldGS`, `clusters`, `oldclusters`, `brushCrd`, `oldbrushCrd`,
`brushWeight`, `oldbrushWeight`, `anchors`, `oldanchors` — unfinished
localisation work and its undo history · `minValue`, `maxValue` — recomputable CT intensity limits ·
`FileName`, `PathName` — where the file happened to be last time ·
`wmparcColors`, `AnnotColor_L`, `AnnotColor_R` — colour volumes derived from
the parcellation and the annotations

Existing `.iel` files therefore contain a half-finished session alongside the
patient. Splitting the structures forces a choice: keep writing them (as an
optional saved session, so an interrupted localisation can still be resumed),
or drop them and regenerate on load. Either way the reader must keep accepting
them, or every existing project file becomes unreadable.

### 2. `currentSpace` is scientific, not a display toggle

It is set by the MNI/Native toggle button, which makes it look like a view
setting. But it is also written into each electrode as `elec.coordsys` when
electrodes are saved, and it decides which labelling runs. It records **which
coordinate system the stored coordinates are actually in**, so it belongs in
`project`. What belongs in `ui` is the separate question of which atlas or
overlay is currently displayed.

### 3. `options` must be split

Of the 17 settings in `default_ielectrodes_options.m`, the GUI reads these as
scientific parameters — they change results and belong in `work.options`:

`atlasLabelingRadio`, `atlasLabelingMode`, `atlasLabelingMinProb`,
`atlasLUTFile`, `gridFit_grids`, `gridFit_strips`, `gridFit_depth`,
`indexing_projection_method`, `image_voxdim`, `reduce_surfaces_elements`

and these as presentation settings, which belong in `ui.options`:

`scatter`, `showLocalizeTools`, `showPlanTools`, `cylAlpha`

When a result is accepted, the scientific settings that produced it should be
recorded with that result rather than left in the global options.

### 4. Selected voxels exist only inside a graphics object

`getThresholdedVoxels` recovers the selection by reading it back out of the
plotted scatter:

```matlab
brushedIdx    = logical(handles.sct.BrushData);
brushCrd(:,1) = handles.sct.XData(brushedIdx);
brushCrd(:,2) = handles.sct.YData(brushedIdx);
brushCrd(:,3) = handles.sct.ZData(brushedIdx);
```

There is no data copy of the selection. Every localisation run — clustering
and GridFit alike — begins from coordinates held in a figure. Until the
selection is stored as `work` data with its image reference, voxel selection
cannot be scripted, and the fitting step cannot be tested without a window.

### 5. Scientific values and the current selection live inside controls

| Control | Value it actually holds | Belongs in |
|---|---|---|
| `sliderThrMin`, `sliderThrMax` | CT threshold limits | `work` |
| `denoiseSlider` | denoising kernel size | `work` |
| `rowsEdit`, `colsEdit` | array dimensions for fitting | `work` |
| `nClusText`, `clusNElecEdit` | requested number of clusters / contacts | `work` |
| `arrayNumberText`, `elecNumberText` | which array and contact is selected | `work` |
| `arrayPlanningNumberText`, `elecPlanningNumberText` | selected planning array and target | `work` |

The four selection controls are read back with `str2double(get(…, 'String'))`
in **60 places**. The application's notion of "which array am I working on" is
the text printed on a label. These values must become ordinary variables, with
the controls displaying and editing them rather than storing them.

## Differences from the proposal in the discussion

The mapping above agrees with the discussion on every structural point. Two
corrections come from reading the current source:

- The field count is 166 here rather than 164, and 106 of them are GUIDE
  controls that need no individual decision. That census covered
  `electrodes_gui.m` only; adding the two fields named in the correction below
  brings the total to 168.
- `wmparcColors`, `AnnotColor_L` and `AnnotColor_R` are correctly identified
  there as derived display caches, but they are *also* written to `.iel`
  today, which the proposal does not mention. See case 1.

### Correction to an earlier draft of this document

An earlier version of this section claimed that `handles.hlink` and
`handles.buttonDown` do not exist in this codebase. That was wrong, and the
error is worth recording because it shows how easy it is to mis-map state in a
GUIDE application: the census behind it searched `electrodes_gui.m` alone, and
both fields are created somewhere else.

Both are set in `app/config/defaultGuiVariables.m`:

| field | created at | what it is |
|---|---|---|
| `buttonDown` | line 24, `handles.buttonDown=0` | flag saying a mouse button is held down on an axis, so motion callbacks know a drag is in progress |
| `hlink` | line 74, `linkprop([handles.axes1,handles.axes2],{'CameraPosition','CameraUpVector'})` | a `linkprop` object keeping the two 3-D axes pointing the same way |

The discussion's placement of both under `ui` is correct. `hlink` holds live
graphics handles and must never be saved; `buttonDown` is transient interaction
state with no meaning outside a figure.

The practical lesson: `defaultGuiVariables.m` writes into the same flat
`handles` struct as the GUI file, so it is a second, silent source of state.
Any future field census has to cover it — and it is also the reason
`liftToProject` is called *after* `defaultGuiVariables` in `OpeningFcn` rather
than before.

## Suggested migration order

1. Introduce `handles.project` and `handles.work`, keeping every current field
   name and representation. Leave the GUIDE controls where they are.
2. Move one field at a time, together with all of its readers and writers.
   Never leave two authoritative copies of the same value.
3. Pull the values listed in case 5 out of the controls, starting with the
   thresholds, since `getThresholdedVoxels` depends on them.
4. Give the voxel selection a home in `work` so that it no longer has to be
   read back from the scatter object.
5. Extract project I/O — validate, save, load, and an adapter for existing
   `.iel` files — with file names passed in as arguments and the file dialogs
   left in the GUI.
6. Milestone: a patient-data round trip. Load a project, save it, reopen it,
   and confirm that image geometry, electrode coordinates, channel names and
   transformations are unchanged.
