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
