# The ielec layer

The backend separation took every scientific algorithm out of the GUI. The GUI
still talks to the backend directly, though: it knows which of the ~130
functions in `src/` to call, in what order, with which arguments in which
position, where the default settings live, and how to put each result into
the project. Alejandro's proposal after the separation: put one layer between
the two, so that the frontend talks only to that layer.

This document sets the rules of that layer. It is written before most of the
layer exists, so that every function in it follows the same rules from the
first one on.

## Three layers

```
┌─ FRONTEND ─ electrodes_gui.m now, the App Designer app next ─────────┐
│   asks the user (dialogs, sliders, buttons), builds a cfg,           │
│   calls ONE ielec function, keeps what it returns, draws             │
│   holds: project, work  ─ the study      ui ─ only the frontend's    │
└──────────────────────────────┬───────────────────────────────────────┘
                               │  [project, work] = ielec.fn(project, work, cfg)
┌─ LAYER ─ src/+ielec/ ────────▼───────────────────────────────────────┐
│   checks cfg and fills in its defaults                               │
│   calls the backend functions in the right order                     │
│   puts the results into project and work                             │
└──────────────────────────────┬───────────────────────────────────────┘
                               │  T1 = loading_images_SPM(file, ...)
┌─ BACKEND ─ the rest of src/ ─▼───────────────────────────────────────┐
│   the algorithms: plain functions, their own arguments, no state     │
└──────────────────────────────────────────────────────────────────────┘
```

The same `ielec` call works from the GUIDE GUI, the App Designer app, and a
script. Users who know FieldTrip will recognise the style:
`cfg = []; cfg.x = ...; data = ft_something(cfg, data)`.

## The rules

**1. One signature.**

```matlab
[project, work] = ielec.functionName(project, work, cfg)
```

Always these three inputs, in this order. Always these two outputs, even when
a function changes only one of them. That way the caller never has to look up
what a function takes or returns. A function that starts something new, such
as `ielec.newProject`, is given `[]` for what it replaces.

A function that only *reports* something, and changes nothing, returns what it
reports as a third output and leaves project and work as they were:
`[project, work, report] = ielec.fn(project, work, cfg)`.

**2. `ui` never enters.** An ielec function does not receive `ui`, does not
return it, and does not know it exists. It opens no window, no dialog and no
figure, never calls `guidata`, and never reads a control. What the frontend
shows is the frontend's business: after a call it redraws, and it updates its
own display state, such as the colour caches (`app/config/emptyColourCaches.m`).

**3. All options go in `cfg`.** No positional options. Every function starts
with `checkCfg`, which:

- accepts `cfg = []` as "no options";
- **refuses an option it does not know** (`ielec:unknownOption`). A misspelt
  `cfg.T1fiel` must not be silently ignored and the default used in its place;
- refuses a call that leaves out a required option (`ielec:missingOption`);
- accepts `"strings"` as well as `'char vectors'`;
- fills in the defaults for the rest.

Defaults that are scientific settings come from `work.options`, which is
`default_ielectrodes_options`. A `cfg` field overrides them for one call, and
never changes `work.options`.

**4. Files by full path.** A file is named in one `cfg` field, with its full
path: `cfg.mri = 'C:\data\p01\T1.nii'`. It is not split into a folder and a
name. Where the file dialog last pointed is the frontend's business.

**5. Errors, with an identifier.** Each function checks its inputs and fails
with a message that names the function and says what was wrong, under an
`ielec:` identifier (`ielec:noSuchFile`, `ielec:noMRI`, ...), so that a
frontend can catch a specific error and show it the way it wants.

**6. Where the code lives.** `src/+ielec/` is a MATLAB package: the functions
are called as `ielec.newProject(...)`. Helpers that only the layer uses go in
`src/+ielec/private/`. The backend in the rest of `src/` stays as plain
functions. Only the layer is a package, so no backend call site has to change.
Two things follow from that:

- Inside the package, calls to the backend are unqualified (`loading_images_SPM(...)`),
  and calls to other ielec functions are qualified (`ielec.loadCT(...)`).
- An ielec function does not call a backend function with the same name. Where
  there is one (`newProject`, `loadProject`, `openProject`), the layer does
  the steps itself. The unpackaged versions are retired once nothing calls
  them any more. This also settles `docs/OPEN_QUESTIONS.md` item 21: the
  public name is `ielec.openProject`, which does not clash with MATLAB's.

**7. Each function comes with a test.** `tests/test_ielec<Name>.m` compares the
new function with the code it replaces, kept verbatim inside the test, and
checks the rules above: the signature, no window, an unknown option is refused.
It is the same method as during the separation.

**8. The frontend calls only ielec.** Once the layer is complete, a test will
check that `app/` and the frontend call no backend function directly, so the
layer cannot be bypassed without anyone noticing.

## Recording each step

Every ielec function that changes the project will record the call in
`project.history`:

```matlab
project.history{end+1} = struct( ...
    'function', 'ielec.loadCT', ...
    'cfg',      cfg, ...        % after the defaults were filled in
    'date',     '2026-09-22 14:03:10', ...
    'version',  '2.0');
```

This is what makes a result reproducible: which steps, in which order, with
which settings. It answers the question left open in OPEN_QUESTIONS item 18,
how to keep the Localize settings: each step's cfg holds them. It is also what
a "save the session as a script" feature would read.

Rules for it:

- The cfg holds settings and file names only, never images or other large
  data, so the file does not grow.
- It changes the `.iel` format. The file gets two new fields, `history` and
  `schemaVersion` (2). v2 opens v1.020 files as before, with an empty history.
  v1.020 should open v2 files by ignoring the new fields; that will be tested
  with the v1.020 copy, not assumed. A v2 file saved again from v1.020 loses
  its history.
- File paths are stored as given. They can contain a patient's name, so they
  need care when a project is shared.

Because it changes the file, history is added in a commit of its own. It is
not in the functions yet.

## What exists

| function | replaces | used by |
|---|---|---|
| `ielec.newProject` | the reading and reset in the New button | the New button |

Next, in the order of the App Designer prototype's workflow:

| function | replaces |
|---|---|
| `ielec.openProject`, `ielec.saveProject` | Open and Save; `loadProject` / `saveProject` |
| `ielec.loadCT` | the Load CT button: CT and brain mask onto the MRI |
| `ielec.thresholdCT` | `thresholdCTVoxels` and the candidate voxels in work |
| `ielec.selectVoxels` | the selection and `voxelWeights` |
| `ielec.cluster` | the Clus button |
| `ielec.gridFit` | the Fit button: `gridFitOptions` and `electrodeFromGridFit` |
| `ielec.addArray`, `ielec.removeArray` | array handling |
| `ielec.label` | anatomical labelling |
| `ielec.export` | the export formats |

`examples/exampleHeadlessWorkflow.m` will be rewritten with ielec calls only.
It will then be the tutorial for scripting iElectrodes.
