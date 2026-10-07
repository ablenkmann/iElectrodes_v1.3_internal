# iElectrodes 2 — repository architecture

This document describes how the repository is organised after the backend
separation, why, and what comes next. It follows the architecture in
Alejandro's "Modernize iElectrodes GUI" sessions, adapted so that **frontend
and backend are the two visible top-level code folders**.

The separation of backend from GUI is finished: no scientific algorithm is
left in `electrodes_gui.m`, and the main workflow runs from a script without
a window. The next phase is a layer between the two - `src/+ielec/`, the
only part of the backend the frontend calls (`docs/API_LAYER.md`) - built
together with the App Designer frontend.

## Getting started

Add the repository to the MATLAB path with its subfolders — *Home → Set Path →
Add with Subfolders…*, then *Save*. Do not have another copy of iElectrodes on
the path at the same time: files with the same names shadow each other
silently. `which electrodes_gui` shows which copy MATLAB will run.

```matlab
electrodes_gui                  % the GUI, as before

cd tests
run_all_tests quiet             % every test, one line each, then a summary

cd ../examples
exampleHeadlessWorkflow         % the whole workflow from a script, no window
```

No test opens a figure. The example project, `examples/exampleNativeSpace.iel`,
is the input to most tests — do not save over it.

## Layout

```
iElectrodes/
├── electrodes_gui.m / .fig   the GUIDE interface - now GUI only
│
├── app/            ══ FRONTEND ══  exists because there is a GUI
│   ├── config/       display defaults, colours, GUI state defaults, update check
│   ├── dialogs/      the small dialog windows
│   └── rendering/    drawing helpers
│
├── src/            ══ BACKEND ══  no figures, no handles, callable from a script
│   ├── +ielec/       the layer: the functions the frontend calls, all as
│   │                 [project, work] = ielec.fn(cfg, project, work)
│   ├── project/      the project model: new / open / load / save, the
│   │                 project / work / ui split, array add and remove,
│   │                 default processing options
│   ├── io/           reading images, parcellations, surfaces, electrode files;
│   │                 grouping imported contacts into arrays
│   ├── localization/ thresholding, voxel weights, clustering, GridFit and its
│   │                 options, building arrays from a fit, indexing
│   ├── projection/   brain-shift compensation: which arrays, which surface,
│   │                 the correction itself, the smooth cortical envelope
│   ├── labeling/     anatomical labelling in native and MNI space, contact
│   │                 naming, parcellation and annotation colours
│   ├── geometry/     trajectories, frame angles, planning-grid placement,
│   │                 coordinate transforms and the rest of the mathematics
│   └── export/       BIDS, EEGLAB, FieldTrip and iElectrodes exports
│
├── tests/          characterisation and property tests, and run_all_tests
├── examples/       the example projects, and exampleHeadlessWorkflow.m
├── docs/           API_LAYER, OPEN_QUESTIONS, STATE_FIELD_MAPPING, FUNCTION_INVENTORY
├── assets/         atlases, look-up tables, MNI meshes, icons
├── third_party/    SPM12, iso2mesh, NIfTI tools, refinepatch - not iElectrodes code
├── extras/         stand-alone scripts and a CT template (see OPEN_QUESTIONS 4)
└── legacy/         .old backups kept for reference
```

## The state: project, work, ui

The GUIDE `handles` structure used to hold everything - patient data,
in-progress results and graphics handles - in one flat list of 166 fields.
It is now split three ways, following the reference plan:

| | holds | examples | in the `.iel` file |
|---|---|---|---|
| `handles.project` | patient data and accepted results | images and their geometry, electrodes, planning targets, surfaces, parcellation | yes |
| `handles.work` | work in progress, settings, shared resources | selected voxels and weights, unfinished contacts, undo copies, CT intensity limits, the Localize panel's settings, processing options, MNI templates | only the fields that always were |
| `handles.ui` | presentation | graphics handles, redraw flags, colour caches, display options | only the colour caches the file has always carried |

`docs/STATE_FIELD_MAPPING.md` lists every field and where it went.

**The `.iel` file is unchanged.** It is still a MATLAB v7.3 file holding one
flat variable `s`, exactly as v1.020 writes it, so projects move freely
between the two versions. `writeIelFile` flattens the three structures, and
`checkProjectStructure` writes a fixed list of fields and drops the rest - so
new state kept in `work` never reaches the file. `tests/test_sessionState.m`
checks that.

## What a callback does now

A button callback reads its inputs - from a dialog, or from the controls via
`readLocalizationSettings` into `work` - calls a function in `src/`, stores
the result in `project` or `work`, and redraws. The reference plan's example:

```matlab
function LocalizeButtonPushed(app, event)
    options = app.readLocalizationOptions();
    result  = ielectrodes.localization.gridFit(app.Project.CT, options);
    app.Project.setElectrodes(result);
    app.refreshElectrodeViews();
end
```

`Fitpushbutton_Callback` now has that shape, in GUIDE form. With the ielec
layer the shape gets stricter: the callback builds a `cfg`, calls one `ielec`
function and keeps the project and work it returns. The New button is the
first to work that way.
`docs/FUNCTION_INVENTORY.md` classifies all 162 functions of
`electrodes_gui.m`; four small operations on `work` are still in it and are
listed there as the first jobs of the next phase.

## How it was done

One workflow at a time, each in its own commit, every change
behaviour-preserving. Each extraction came with a characterisation test that
keeps the original code verbatim and requires the new function to give the
same answer, usually on the real example project. Where extracting a piece of
code revealed a fault, the fault was recorded in `docs/OPEN_QUESTIONS.md`
rather than fixed on the way; the few that were fixed were fixed in commits of
their own, and the entry says whether Alejandro has confirmed it.

Checks that go beyond "same as before":

- `test_headlessWorkflow` re-localizes one of the example project's depth
  electrodes from its CT with no window open: open, threshold, select,
  cluster, fit, label, export, save and reopen. GridFit lands 0.29 mm from the
  stored contacts on average.
- Pairs of functions that should be inverses are tested as inverses: the two
  trajectory directions, and the frame angles.
- Geometry is tested against what it must satisfy: a planning grid keeps its
  spacing when moved, a rotation keeps contact distances, a trajectory's
  contacts are collinear.

## Why plain folders instead of MATLAB packages

The reference plan proposes `src/+ielectrodes/+localization/gridFit.m`, called
as `ielectrodes.localization.gridFit(...)`. That is the right end state, but
not a first step: MATLAB finds package members only through their full names,
so converting means rewriting every call site at once, and a missed one is an
"undefined function" error at run time rather than when the file is loaded.

The folder names are already the future package names, so converting one area
later is: rename `localization` to `+localization`, update that area's call
sites, run its tests. `docs/OPEN_QUESTIONS.md` item 21 is one reason to do it
eventually.

## Where things stand against the reference plan

| phase | | |
|---|---|---|
| 1 | stabilise v1 | partly - v1.020 is kept as a reference copy and its faults are recorded; no release tag yet, and no reference datasets beyond the two example projects |
| 2 | characterisation tests | done - `tests/`, run with `run_all_tests` |
| 3 | headless computational API | done - `src/`, proven by `exampleHeadlessWorkflow` |
| 4 | explicit project model | done - `project` / `work` / `ui`; `schemaVersion` 2 and `project.history` are now written. The earlier decision not to change the file was reversed once 1.020's side of the compatibility could be measured rather than assumed - `tests/test_ielFormat.m` runs 1.020's own reader on a file written here |
| 5 | vertical GUI prototype in App Designer | next, together with the ielec layer (`docs/API_LAYER.md`) |
| 6 | gradual release | later |

The decisions needed before phase 5 - which MATLAB release to target, whether
the Localize settings are saved, whether `currentSpace` is split, GitHub and
licensing - are in `docs/OPEN_QUESTIONS.md`, with the evidence for each.
