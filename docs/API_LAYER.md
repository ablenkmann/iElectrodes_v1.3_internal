# The ielec layer

The backend separation took every scientific algorithm out of the GUI. The GUI
still talks to the backend directly, though: it knows which of the ~130
functions in `src/` to call, in what order, with which arguments in which
position, where the default settings live, and how to put each result into
the project. The proposal after the separation was to put one layer between
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
                               │  [project, work] = ielec.fn(cfg, project, work)
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
[project, work] = ielec.functionName(cfg, project, work)
```

Always these three inputs, in this order: `cfg` first, as the back-end note
of 1 October 2026 fixes it, and as FieldTrip writes it. Always these two
outputs, even when a function changes only one of them. That way the caller never has to look up
what a function takes or returns. A function that starts something new, such
as `ielec.newProject`, is given `[]` for what it replaces.

A third output carries what is neither project nor work. A function that only
*reports* something leaves both as they were and returns what it found:
`[project, work, report] = ielec.fn(cfg, project, work)`. A function whose
result is a proposal - `ielec.fitArray` returns the array it fitted, which
nothing has accepted yet - returns it the same way.

Data that is neither a setting nor part of project or work goes after the
three, as a fourth argument: `ielec.acceptArray(cfg, project, work, array)`
takes the array to add that way, and the colour caches below travel the same
road. It keeps `cfg` small enough to record.

Display data is called `ui`, which is the name the back-end note gives the
slot: the colours of the parcellation and the surfaces, which the `.iel` file
carries for iElectrodes 1.020. They are derived from the project and large -
computing the parcellation's takes seconds - so the layer hands them over
rather than keeping them. The functions that read and write the file pass
them as the last argument:

```matlab
[project, work, ui] = ielec.openProject(cfg, [], work)
ielec.saveProject(cfg, project, work, ui)
```

Leave `ui` out when saving and the colours are computed.

A function that *makes* such a cache while it changes the project returns it
as the third output instead: `ielec.loadAnatomy` gives back the parcellation's
colours and `ielec.loadAnnotations` the surfaces'. Both ways keep the cache
out of `project` and out of the layer's memory; the difference is only which
side produced it.

Those two still return their own shape - one array, and a structure with
`.right` and `.left` - rather than a `ui` whose fields are the names the
frontend files them under (`wmparcColors`, `AnnotColor_R`, `AnnotColor_L`).
Making them match would let the frontend absorb any such output with one
function instead of unwrapping each by hand. **Open:** should they match, or
is the third output free to be whatever the function produced?

**2. The window never enters.** An ielec function opens no window, no dialog
and no figure, never calls `guidata`, and never reads a control. What the
frontend shows is the frontend's business: after a call it redraws, and it
updates its own display state.

The `ui` of rule 1 is not a breach of this. It is a plain structure of
colours that the layer computes and hands over, or is handed back to write to
the file. The layer never reads the frontend's `ui` and has no idea what else
is in it; it is data passing through, not the window reaching in. Before the
back-end note of 1 October this argument was called `caches`, and renaming it
changed nothing but the name.

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
- the shared geometry: `AnatSpace2Mesh` and `mesh2AnatSpace`.
  These are two-line coordinate functions that the backend itself
  uses - `thresholdCTVoxels`, `gridFit`, `clusterContacts` and others - so they
  cannot become the frontend's. They are library functions, called the way
  `norm` is called, and the test lists them by name so that the exception
  stays as short as it is. It was three until the coordinates in progress
  moved onto the layer: `eucDistMat` was there because the Delete button
  measured which contact the cursor was nearest, and `ielec.removeCoordinate`
  measures it now.

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
  data. That keeps the settings small, but it is not what decides the size of
  the file: the container does. A cell of structs in a `-v7.3` file is HDF5,
  where every cell element and nested struct is an object with its own header,
  so a recorded step cost about **4,400 bytes whatever was in its cfg**.
- **So the file stores the history as one string, and the project holds the
  cell.** `encodeHistory` and `decodeHistory` are the two ends of that, called
  by `writeIelFile` and `checkProjectStructure`. The shape above is unchanged:
  `project.history{3}.cfg.lowThreshold` is how a step is read, and the file
  carries the field the design names. Only its type on disk is different.
- The honest figure for what it costs is **124 characters of JSON a step**.
  What that costs on disk falls as the history grows, because the file is
  deflated: measured with distinct steps, about 250 bytes a step for the
  first few, 66 at a hundred steps, 21 at a thousand. Two orders of magnitude
  below the cell of structs either way. Beware per-step figures taken from
  repeated identical steps - a hundred and five hundred copies of one step
  give the same file size, because what is being measured there is
  compression. `docs/OPEN_QUESTIONS.md` item 41 has the tables.
- **A save never fails because of a history.** JSON cannot carry a function
  handle, a complex number, a sparse matrix or a duration. A cfg holding one
  used to abort the save of the whole patient project; now that step's cfg is
  replaced by a note, the other steps are kept, the file is written, and a
  warning says which steps were affected.
- What JSON does not carry, for the values it does accept, is three things,
  and `tests/test_ielFormat.m` pins all three:
    - **class**: an `int32` comes back a double of the same value;
    - **orientation**: a ROW vector comes back a COLUMN. A column survives -
      a JSON array decodes to a column, which is why it is that way round and
      not the other. That used to mean a recorded cfg could not be replayed:
      `ielec.newTarget` and `ielec.placeTarget` required `cfg.centre` to be
      exactly 1-by-3 and so refused their own recorded step. All **six**
      functions that take a point now accept three numbers in any
      orientation and normalise with `(:)'`: `ielec.addCoordinate`,
      `ielec.removeCoordinate`, `ielec.aimTarget` and
      `ielec.newDepthTarget` already did, and these two now do.
      `ielec.pointLabel` is the seventh function that takes coordinates and
      is deliberately left out: its `cfg.coordinate` is an N-by-3 **list**,
      where a 3-by-1 is ambiguous rather than merely unoriented - one point
      as a column, or three points of one coordinate each? It also records
      no step, being one of the nine that only report, so no recorded cfg is
      ever replayed into it. See `docs/OPEN_QUESTIONS.md` item 42;
      `tests/test_ielecPlanningGrid.m` replays a step out of a history to
      prove the rest;
    - **`Inf` and `NaN`**, which are *lost rather than flattened*: a scalar
      comes back 0-by-0 and inside an array it becomes `NaN`. That is a value
      going, not a type, and it matters - `[NaN NaN NaN]` is the documented
      default of `options.image_voxdim`, so a step that records a whole
      options struct does not survive a round trip intact.

  A value that has to survive byte for byte does not belong in a recorded
  step.
- It changes the `.iel` format. The file gets two new fields, `history` and
  `schemaVersion` (2). **That half is done.** v2 opens a v1.020 file with an
  empty history, and v1.020 opens a v2 file: `tests/test_ielFormat.m` runs
  1.020's own reading code on a file written here, in a MATLAB of its own
  because its folders would shadow this one's - 77 of the 406 function names
  under its `priv` are also names in `src/` here, `checkProjectStructure`
  among them, and the rest are the SPM it carries, which would shadow the copy
  in `third_party`. It gets back every electrode array and every planning
  target, compared by content and not by count. It ignores the new fields
  because its structure check asks `isfield` for the fields it wants and
  never enumerates what it was given - which is also why a v2 file saved
  again from v1.020 loses its history: the history does not survive being
  read by it, so it cannot be written back out.

  That check needs a 1.020 copy beside the repository - `../iElectrodes_v1.020`
  or one level further up. Without one it skips, and the suite still reports a
  pass, so a clean run is not on its own evidence that the compatibility still
  holds.
- Nothing reads `schemaVersion` yet. It is written so that a later version can
  tell what it is looking at; refusing a file from a *future* version would be
  a new behaviour and is not part of this.
- File paths are stored as given. They can contain a patient's name, so they
  need care when a project is shared.

Because it changes the file, the format came in two commits of its own - the
fields, and then the string the history is stored as. **The functions record
now.**

Thirty-one of the forty record a step; nine do not, and
`tests/test_ielecHistory.m` names those nine with a reason each and fails if a
layer function neither records nor appears there. The nine are the three kinds
of function that produce nothing: one that reports (`projectionState`,
`pointLabel`, `arrayFileContents`, `colourCaches`), one that writes a file
(`saveProject`, `saveTargets`, `export`), and one that starts a session
(`startSession`, `openProject` - which replaces the project with a file,
history and all, so a step there would grow the history on every open).

Two things about what gets recorded are worth knowing:

- **the cfg is the one `checkCfg` filled in**, not the one the caller passed.
  `ielec.newDepthTarget([], project, work)` records
  `{"name":"Planning","targetIn":[0,0,0],"targetOut":[45,45,45],"nContacts":10,...}`,
  which is the point: a threshold of 2500 is recorded as 2500 and not as an
  empty cfg that happened to default to it. The one exception is
  `ielec.selectVoxels`, which records how many voxels were picked instead of
  which - rule 3b above, because `cfg.indices` is as long as the candidate
  list and the step would be 27,000 characters against a typical 124;
- **a call the layer makes to itself records nothing.** `ielec.aimTarget`
  calls `ielec.setFrame`, and `ielec.newDepthTarget` calls `ielec.aimTarget`.
  Without that, one keystroke in the Azimuth box would write three steps, two
  of them the layer talking to itself, and replaying them in order would apply
  the inner ones twice. So the history records the calls the FRONTEND made,
  which is also the list a script would have to make; `recordStep` reads the
  stack to tell them apart. Called directly, each still records.

Two things a recorded cfg carries that are worth knowing before this is relied
on. `ielec.setOptions` takes a whole options struct, so its step is 2,733
characters - twenty times a typical one - and `options.image_voxdim` is a
1-by-3 row, which JSON brings back as a column, so that one step does not
survive the file unchanged. The window never reaches it (the Config button
passes `cfg = []`, recorded as twelve characters); a script does. And every
function that takes a file name records it as given: `loadCT`, `newProject`,
`loadSurfaces`, `loadTargets` and `importLabels` put the full path in the
history, which from this commit travels inside a shared `.iel`. The bullet
below has always said paths need care when a project is shared; it now
applies to the history as well as to the fields it was written about.

The work-stage functions record too - `thresholdCT`, `selectVoxels`,
`cluster`, `fitArray` and the rest - which is what keeps the Localize settings
and answers item 18. The consequence is that their help no longer says
"PROJECT is not changed": it says the project gains nothing but the step
recorded in its history, which is true and is the only thing that changed
about them.

## What exists

| function | replaces | used by |
|---|---|---|
| `ielec.startSession` | the structure, the three lifts and the options of the opening function | start-up |
| `ielec.setOptions` | rereading the options file | the Config button |
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
| `ielec.nameContacts` | the naming call of both Label buttons, and the planning name box | Label, Label from list, the planning panel |
| `ielec.newTarget` | the New planning grid button's grid, and adding it | the planning panel |
| `ielec.placeTarget` | the centre and the turn of the nine move buttons | the planning panel |
| `ielec.fitTarget` | the springs projection of the Fit grid to surface button | the planning panel |
| `ielec.setFrame` | the frame angles of `estimateAnglesFrame` | the frame radio group, and every change to a depth target |
| `ielec.aimTarget` | the trajectory of `updateTarget`, `angleChange` and `AlphaBetaChange` | the Azimuth and Elevation boxes, the Alpha and Beta boxes, and `updateTarget` for everything else |
| `ielec.newDepthTarget` | the array the New target button built in the frontend | the New target button |
| `ielec.addCoordinate` | the four lines and the CT weight of the Add coordinate button | the Add coordinate button |
| `ielec.removeCoordinate` | the nearest-contact search and the cluster renumbering of the Delete button | the Delete coordinate button |
| `ielec.clearCoordinates` | the emptying in the Clear all button | the Clear all button |
| `ielec.undoCoordinates` | the four swaps in the Undo button | the Undo button |
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
| `ielec.loadTargets` | `loadPlanningTargets`, into `project.targets` | the Load planning button |
| `ielec.saveTargets` | `savePlanningTargets`, from `project.targets` | the Save planning button |

That is all of them. **Rule 8 is met:** `electrodes_gui.m` calls no backend
function any more, apart from the two shared geometry ones rule 8 names.
`tests/test_frontendUsesLayer.m` keeps an empty list and fails if one comes
back.

`examples/exampleHeadlessWorkflow.m` is written with ielec calls only, and is
the tutorial for scripting iElectrodes: ten steps, nine `ielec` functions, no
window, and the one backend call rule 8 allows. `tests/test_headlessWorkflow.m`
checks that it stays that way as well as that it still works.

`tests/test_frontendUsesLayer.m` used to measure the distance to rule 8, by
listing every backend function `electrodes_gui.m` still called, grouped by
the ielec function that was going to take the group over. The list is empty
now, and what the test still does is fail when a backend call turns up in the
frontend again - or when one of the three allowed ones stops being called and
the exception list has not been shortened.

That question the list used to carry - what to do with the five functions the
frontend calls in order to draw - is settled. The two nothing else calls,
`mixImages` and `voxelFromPlaneClick`, moved into `src/+ielview/`, the drawing
layer; the three the backend itself uses stayed where they are and are named
in rule 8 as the exception. `src/+ielview/Contents.m` says what belongs
there.
