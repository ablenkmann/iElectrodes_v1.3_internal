# Architectural inventory of `electrodes_gui.m`

Static analysis of all 149 functions in the 7,085-line GUI file (v1.020),
prepared as the concrete next step named in the reference architecture
discussion: *"classify each function as UI, plotting, workflow, state, I/O or
scientific algorithm, then select the first vertical workflow to implement."*

## Summary

| Class | Functions | Lines | Meaning |
|---|---:|---:|---|
| **workflow** | 64 | **4,614** | calls the scientific backend from inside a GUI callback |
| ui | 68 | 1,561 | reads/writes widgets, no science |
| plotting | 2 | 492 | draws the 2-D/3-D views |
| state | 11 | 264 | flips flags and cached data |
| io | 4 | 122 | file dialogs and file writing |
| | **149** | **7,053** | 130 of the 149 are GUI callbacks |

**65 % of the file is workflow** — science that cannot currently be tested,
scripted or batch-run, because reaching the algorithm means clicking a button.

## The `handles` struct

166 fields, holding two unrelated things:

| Kind | Fields | References |
|---|---:|---:|
| UI components (`sliderX`, `axes1`, `editArrayName`, …) | 105 | 647 |
| Patient / scientific data (`T1`, `TAC`, `electrodes`, `targets`, `wmparc`, `vertices_SCE_L`, `MNIprob`, `currentSpace`, …) | 50 | **1,288** |
| Transient display state (cursors, plot handles, redraw flags) | 11 | 485 |

Patient data is a minority of the fields but the majority of the traffic
(1,288 of 2,420 references). Giving it its own home — an `ielectrodes.Project`
object — is the prerequisite for every target below.

## The five extraction targets

| # | Target | Functions | Lines | Destination |
|---|---|---:|---:|---|
| 1 | Patient data mixed with graphical data | 8 | 790 | `src/project/` |
| 2 | MRI / CT / mask handling | 13 | 926 | `src/io/` + `app/rendering/` |
| 3 | Atlas and surface loading | 6 | 428 | `src/io/` + `src/labeling/` |
| 4 | Native-space and MNI-space labelling | 6 | 297 | `src/labeling/` |
| 5 | Input / output ports | 5 | 157 | `src/io/` + `src/export/` |

### Target 1 — patient data mixed with graphical data
`SaveElectrodespushtool_ClickedCallback` (217), `LoadElectrodespushtool_ClickedCallback` (146),
`Openpushtool_ClickedCallback` (118), `Newuipushtool_ClickedCallback` (87),
`electrodes_gui_OpeningFcn` (79), `addElectrode2structure` (69),
`addtarget2structure` (40), `Savepushtool_ClickedCallback` (34)

### Target 2 — MRI / CT / masks
`updateTAC` (441), `LoadCTtool_ClickedCallback` (194), `updatePlot` (76),
`getThresholdedVoxels` (42), `updateMix_TAC_MR` (41), erode/dilate (34),
six window and threshold sliders (98)

`updateTAC` is the largest function in the file: 441 lines mixing slice
rendering, 78 UI reads/writes and two different anatomical labelling calls.
Split it before moving it.

### Target 3 — atlas and surface loading
`addFSsurfacesuipushtool_ClickedCallback` (159), `addSCEuipushtool_ClickedCallback` (124),
`LoadFSlabelsuipushtool_ClickedCallback` (77), plus three small clear/toggle callbacks

### Target 4 — labelling
`labels2NativeSpace` (100), `LabelListPushbutton_Callback` (96),
`labels2MNIspace` (35), `LabelAutoPushbutton_Callback` (32),
MNI toggle on/off (34)

### Target 5 — I/O ports
`LoadPlanninguitoggletool_ClickedCallback` (37), `Reportuipushtool_ClickedCallback` (35),
`snapshoottool_ClickedCallback` (33), `ReportPlanninguipushtool_ClickedCallback` (26),
`savePlanninguitoggletool_ClickedCallback` (26)

## Recommended first extraction: target 4

`labels2NativeSpace` and `labels2MNIspace` are the only substantial workflow
pair in the whole file that touch **zero** UI widgets and **zero** plotting
calls. 135 lines, one backend call each, no graphics entanglement — and native
labelling is the stated priority.

1. Record what both functions return for `examples/exampleNativeSpace.iel`
   (coordinates, labels, label counts). That is the characterisation test.
2. Move the bodies to `src/labeling/labelElectrodesNative.m` and
   `labelElectrodesMNI.m`, taking a project struct in, returning labels out,
   with no `handles` anywhere.
3. Reduce the two GUI functions to: read project, call function, refresh view.
4. Re-run the test. Identical labels means the extraction preserved behaviour.

This produces the first function in the toolbox callable from a script without
opening a figure — the acceptance test the reference architecture proposes for
the whole migration. Repeat the pattern for targets 3, 2 and 5, and leave the
project model (target 1) until last, when its real shape is known from four
worked examples.

## Largest functions overall

| Function | Lines | Class |
|---|---:|---|
| `updateTAC` | 441 | workflow |
| `updateElectrodes3D` | 386 | plotting |
| `SaveElectrodespushtool_ClickedCallback` | 217 | workflow |
| `LoadCTtool_ClickedCallback` | 194 | workflow |
| `Fitpushbutton_Callback` | 177 | workflow |
| `addFSsurfacesuipushtool_ClickedCallback` | 159 | workflow |
| `LoadElectrodespushtool_ClickedCallback` | 146 | workflow |
| `addSCEuipushtool_ClickedCallback` | 124 | workflow |
| `Openpushtool_ClickedCallback` | 118 | workflow |
| `UpdateTargetEditBox` | 116 | ui |
| `cross2D` | 106 | plotting |
| `labels2NativeSpace` | 100 | workflow |
