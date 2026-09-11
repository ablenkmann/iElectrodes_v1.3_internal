# iElectrodes 2 — repository architecture

This document describes the folder layout introduced during the v2 restructuring,
why each decision was made, and what the remaining steps are.

It follows the architecture discussed in Alejandro's "Modernize iElectrodes GUI"
session, adapted so that **frontend and backend are the two visible top-level
code folders**.

## Layout

```
iElectrodes/
├── electrodes_gui.m / .fig   legacy GUIDE shell (entry point, to be replaced by app/)
│
├── app/            ══ FRONTEND ══  everything that exists because there is a GUI
│   ├── dialogs/      standalone dialog windows (addremovelist, elecImportDlg,
│   │                 movelist, electrode-numbering uitable)
│   ├── rendering/    drawing helpers (electrode lines, cylinders, mesh display,
│   │                 3-D point picking)
│   └── config/       GUI-side configuration (colours, GUI state defaults,
│                     update check)
│
├── src/            ══ BACKEND ══  no figures, no handles, callable head-less
│   ├── project/      project & electrode data model, default processing options
│   ├── io/           MRI / CT / mask loading, NIfTI-SPM conversion, image mixing,
│   │                 FreeSurfer + EDF + text-label readers
│   ├── localization/ GridFit, k-means clustering, energy functions, optimisation
│   │                 constraints, grid/strip/depth definition, contact numbering,
│   │                 adjacency matrices
│   ├── projection/   brain-shift compensation: projection to mesh/SCE, smooth
│   │                 cortical envelope construction, hull correction, depth
│   │                 displacement field
│   ├── labeling/     anatomical labelling — anatomicLabel.m (MNI probabilistic
│   │                 atlas) and anatomicLabelFS.m (FreeSurfer, native space)
│   ├── geometry/     pure mathematics: distances, rotations, quaternions, angle
│   │                 conversions, ray/triangle intersection, volumes, areas,
│   │                 sphere fitting, coordinate transforms
│   └── export/       text exports and FieldTrip neighbour structures
│
├── assets/         atlases, look-up tables, MNI meshes, application icon
├── third_party/    bundled external toolboxes: SPM12, iso2mesh, NIfTI tools,
│                   refinepatch (mex). Not iElectrodes code.
├── examples/       sample .iel projects (native and MNI space)
├── legacy/         stale .old backups kept for reference
├── tests/          (empty) characterisation tests — next phase
└── docs/           (empty) further documentation
```

## Why plain folders instead of MATLAB `+packages`

The reference architecture proposes `src/+ielectrodes/+localization/gridFit.m`,
called as `ielectrodes.localization.gridFit(...)`.

That is the right end state, but it cannot be a first step: MATLAB resolves
package members **only** through fully-qualified names or function-scoped
`import` statements. Converting now would require rewriting every call site —
`electrodes_gui.m` alone has 149 functions and ~2 500 `handles` references, plus
the cross-calls between the backend functions themselves. A single mistake
produces an "undefined function" error at run time, not at compile time.

The folder **names** here are already the future package names. Converting one
area later is therefore:

1. rename `localization` → `+localization`
2. update the call sites of that area only
3. run the characterisation tests for that workflow

This matches Phase 3 of the reference plan — *move one workflow at a time out of
`electrodes_gui.m`* — instead of doing all of them in a single risky commit.

## Path setup

`electrodes_gui_OpeningFcn` adds `src/`, `app/`, `assets/` and `third_party/`
recursively with `genpath`, using `fullfile()` so the same code runs on Windows,
macOS and Linux. If a `priv/` folder still exists it is also added, so the
toolbox cannot break half-way through the migration.

## Next steps

The reference session named the concrete next task: an **architectural inventory
of the 149 functions in `electrodes_gui.m`**, classifying each as UI, plotting,
workflow, state, I/O or scientific algorithm.

Alejandro's review added the specific targets, all of which currently live mixed
into the GUI file and its `handles` struct:

| # | Item | Target |
|---|------|--------|
| 1 | Patient data is handled in the same place as graphical data | own backend model, `src/project/` |
| 2 | MRI / CT / mask handling | `src/io/` |
| 3 | Atlas loading | `src/io/` + `src/labeling/` |
| 4 | Labelling to native space (priority) and to MNI space | `src/labeling/`, separated |
| 5 | Input / output ports | `src/io/` + `src/export/` |

The `handles` struct is the root of items 1–5: its 166 fields mix UI component
handles (`sliderX`, `axes1`, `editArrayName`, …) with patient/scientific data
(`T1`, `TAC`, `electrodes`, `targets`, `wmparc`, `vertices_SCE_L`, `MNIprob`,
`currentSpace`, …). Separating those two groups into an explicit project model
is Phase 4 of the reference plan and the prerequisite for everything else.
