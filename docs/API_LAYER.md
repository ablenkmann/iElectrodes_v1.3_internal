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

A third output carries what is neither project nor work. A function that only
*reports* something leaves both as they were and returns what it found:
`[project, work, report] = ielec.fn(project, work, cfg)`. A function whose
result is a proposal - `ielec.fitArray` returns the array it fitted, which
nothing has accepted yet - returns it the same way.

Data that is neither a setting nor part of project or work goes after the
three, as an extra argument: `ielec.acceptArray(project, work, cfg, array)`
takes the array to add that way, and the colour caches below travel the same
road. It keeps `cfg` small enough to record.

One exception, for the colour caches: the colours of the parcellation and the
surfaces, which the `.iel` file carries for iElectrodes 1.020. They are
display data, derived from the project, and large - computing the
parcellation's takes seconds. So the functions that read and write the file
hand them over and take them back as an extra argument, after the three:
`[project, work, caches] = ielec.openProject(...)` and
`ielec.saveProject(project, work, cfg, caches)`. Leave `caches` out when
saving and they are computed.

A function that *makes* such a cache while it changes the project returns it
as the third output instead: `ielec.loadAnatomy` gives back the parcellation's
colours and `ielec.loadAnnotations` the surfaces'. Both ways keep the cache
out of `project` and out of the layer's memory; the difference is only which
side produced it.

**2. `ui` never enters.** An ielec function does not receive `ui`, does not
return it, and does not know it exists. It opens no window, no dialog and no
figure, never calls `guidata`, and never reads a control. What the frontend
shows is the frontend's business: after a call it redraws, and it updates its
own display state. The colour caches are the example: the frontend keeps
them in `ui`, and the layer only hands them over (rule 1).

A question the user has to answer is a dialog, so it belongs to the frontend
too - but the frontend has to know that there is something to ask about.
`ielec.projectionState` is how: it reports what the projection would do, the
frontend asks what it wants to ask, and then it calls `ielec.projectArrays`
with the answer in `cfg`. A reporting call and a doing call, rather than a
callback into the frontend, which would put `ui` back into the layer.

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

**3b. A cfg may carry a selection, not data.** `cfg` is for settings, and
what goes in it is recorded in the history, so it stays small: a threshold,
a file name, how many contacts. The one thing that is neither is which items
the user picked - `ielec.selectVoxels` takes `cfg.indices`. Those are
positions in a list the layer already holds, not the data itself, and the
history records how many were picked rather than the list.

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
- An ielec function is named after what it does for the user, and never
  after the backend function it calls: `ielec.fitArray` calls `gridFit`.
- An ielec function does not call a backend function with the same name:
  inside a package that is easy to misread, and MATLAB's rules for it are
  easy to get wrong. So the backend's names describe what the function does
  to the file: `readIelFile` and `writeIelFile`, not `openProject` and
  `saveProject`. Those names belong to the layer - `ielec.openProject`,
  which also does not clash with MATLAB's own `openProject`.
  Where the backend's name is the right one for it - `addArray`,
  `removeArray`, which say what they do to a list - the name stays there and
  the layer takes a different one: `ielec.acceptArray`, `ielec.deleteArray`.
  (`newProject` and `loadProject` are the two exceptions left. Nothing in the
  layer calls them, and they are retired once nothing else does.)

**7. Each function comes with a test.** `tests/test_ielec<Name>.m` compares the
new function with the code it replaces, kept verbatim inside the test, and
checks the rules above: the signature, no window, an unknown option is refused.
It is the same method as during the separation.

One test may cover a group of functions that belong to the same button -
`test_ielecProjections.m` and `test_ielecSurfaces.m` each cover the
functions of one - as long as every function in it is compared with the
code it replaced.

**8. The frontend calls only ielec - and ielview.**
`tests/test_frontendUsesLayer.m` checks it, so the layer cannot be bypassed
without anyone noticing. Three things the frontend may call:

- `ielec.*`, for anything that touches the project;
- `ielview.*`, the drawing layer: `src/+ielview/`, functions that turn the
  data into something to display or turn a click into a coordinate. They keep
  no state and decide nothing scientific, and no backend function calls them.
  `ielview.mixImages` blends the MRI and the CT into the picture a view shows;
  `ielview.voxelFromPlaneClick` turns a click in a 2-D view into a voxel;
- the shared geometry: `AnatSpace2Mesh`, `mesh2AnatSpace` and `eucDistMat`.
  These are two-line coordinate and distance functions that the backend itself
  uses - `thresholdCTVoxels`, `gridFit`, `clusterContacts` and others - so they
  cannot become the frontend's. They are library functions, called the way
  `norm` is called, and the test lists them by name so that the exception
  stays three functions long.

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
| `ielec.openProject` | `readIelFile` and the project/work split in the Open button | the Open button |
| `ielec.saveProject` | `writeIelFile` with the GUI's colour caches | the Save button |
| `ielec.colourCaches` | computing the colour caches for a new project | the New button |
| `ielec.loadCT` | the CT and the mask in the Load CT button | the Load CT button |
| `ielec.thresholdCT` | the threshold block of `updatePlot` | the Localize panel |
| `ielec.selectVoxels` | what the Clus button took from the brushed plot | the Clus button |
| `ielec.cluster` | the Clus button's clustering and the contacts it adds | the Clus button |
| `ielec.fitArray` | the Fit button's GridFit call and the array it builds | the Fit button |
| `ielec.indexArray` | both halves of the Index button, and the array each built | the Index button |
| `ielec.reorderArray` | the order each of the six reorder buttons computed | the two turns, the two mirrors, Flip labels, Manual index |
| `ielec.nameContacts` | the naming call of both Label buttons | Label, Label from list |
| `ielec.pointLabel` | **reports only**: what the atlas calls the place a point is in | the coordinate box, on every cursor move |
| `ielec.acceptArray` | the adding and the clearing in `addElectrode2structure` | every button that adds an array |
| `ielec.label` | the two labelling wrappers, `labels2MNIspace` / `labels2NativeSpace` | eight callbacks |
| `ielec.projectionState` | what `processProjections` asked before deciding | the SCE checkbox |
| `ielec.projectArrays` | the brain-shift correction in `processProjections` | the SCE checkbox, and adding an array |
| `ielec.deleteArray` | the removing in both Remove buttons | the Remove buttons |
| `ielec.export` | the writers in every branch of the two export buttons | the export and report buttons |
| `ielec.arrayFileContents` | the reading the import button did before asking | the import button |
| `ielec.importArrays` | the reading and the building in the import button | the import button |
| `ielec.importLabels` | the reading inside `getLabelsFromFile` | the two label-list buttons |
| `ielec.loadAnatomy` | the two calls in the parcellation button | the Load FS labels button |
| `ielec.loadSurfaces` | reading, centring and thinning a pair of surfaces | the pial and the SCE buttons |
| `ielec.buildEnvelope` | the Build branch of the SCE button | the SCE button |
| `ielec.loadAnnotations` | reading the annotations, and clearing them | the pial button |

Next, in the order of the App Designer prototype's workflow:

| function | replaces |
|---|---|
| the planning panel | the workflow that is still almost entirely its own |

`examples/exampleHeadlessWorkflow.m` will be rewritten with ielec calls only.
It will then be the tutorial for scripting iElectrodes.

`tests/test_frontendUsesLayer.m` measures the distance to rule 8: it lists
every backend function `electrodes_gui.m` still calls, grouped by the ielec
function that is going to take the group over, and fails when one appears
that is not on the list - or when one is no longer called and the list has
not been shortened. Running it is the shortest answer to "what is left".

That question the list used to carry - what to do with the five functions the
frontend calls in order to draw - is settled. The two nothing else calls,
`mixImages` and `voxelFromPlaneClick`, moved into `src/+ielview/`, the drawing
layer; the three the backend itself uses stayed where they are and are named
in rule 8 as the exception. `src/+ielview/Contents.m` says what belongs
there.
