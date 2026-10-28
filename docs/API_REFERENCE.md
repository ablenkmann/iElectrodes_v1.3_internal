# The ielec layer

The layer the frontend talks to, so that it never calls the backend
directly. Forty-three functions; what each one does, how it is called, and
what it takes.

The text comes from the help of each function, so it stays with the
code. `help ielec.cluster` at the MATLAB prompt gives any one of them in
full, with an example. `docs/API_LAYER.md` beside this is the design -
the rules these forty-three obey, and why.

## They all have one shape

```matlab
[project, work] = ielec.name(cfg, project, work)
```

- **`cfg`** is a struct and carries every choice. `[]` means "all
  defaults". An option the function does not know is an error, not a
  thing quietly ignored.
- **`project`** is the patient: the images, the arrays localized, the
  plan. It is what a `.iel` file holds.
- **`work`** is the session: what is loaded, selected, in progress.
- **Both go in and come out**, so nothing is hidden in a global or read
  back from the window.
- **A third output** appears where a function reports something, or
  proposes a result it does not store itself.
- **Nothing draws.** No window, no dialog, no `guidata`, no reading a
  control.
- **Errors are named** `ielec:*`, so a caller can tell a refusal from a
  crash.

In the option tables below, *sometimes* means required in some cases
only - a grid needs its rows and columns where a depth does not - and
`help` on the function gives the condition.

---

## A session and its project

Starting up, and the project as a whole.

### `ielec.startSession`  →  `project`, `work`, `ui`

Builds the empty project a session begins with, the work that goes with it, and the colour caches that belong to the frontend.

| | | |
|---|---|---|
| `options` | the scientific options to start from, as a struct whose fields override the defaults. [] takes... | default `[]` |

Errors: `ielec:badOption`

### `ielec.setOptions`  →  `project`, `work`

Fills work.options with the defaults, and with whatever cfg.options overrides.

| | | |
|---|---|---|
| `options` | a struct whose fields override the defaults. [] takes the defaults as they are - what... | default `[]` |

Errors: `ielec:badOption`

### `ielec.newProject`  →  `project`, `work`

Reads the MRI named in cfg.mri, reslices it, and returns an empty project built around it, together with WORK emptied of everything that belonged to the previous project.

| | | |
|---|---|---|
| `mri` | path of the MRI, a NIfTI file | required |
| `voxdim` | voxel size to reslice to, in mm, 1x3 | default `work.options.image_voxdim. NaN keeps the file's own size along that axis.` |
| `interpolation` | interpolation used for the reslicing, as SPM numbers it (0 nearest neighbour, 1 trilinear,... | default `4` |

Errors: `ielec:badCfg`, `ielec:badOption`, `ielec:missingOption`, `ielec:noSuchFile`, `ielec:unknownOption`

### `ielec.openProject`  →  `project`, `work`, `ui`

Reads the .iel file named in cfg.file and returns its project, and WORK with the file's work in progress in it.

| | | |
|---|---|---|
| `file` | path of the .iel file | required |

Errors: `ielec:noSuchFile`, `ielec:notAProject`

### `ielec.saveProject`  →  `project`, `work`

Writes PROJECT, and the part of WORK the file format holds, to the .iel file named in cfg.file.

| | | |
|---|---|---|
| `file` | path of the .iel file to write. An existing file is replaced | required |

Errors: `ielec:emptyProject`, `ielec:noSuchFolder`

### `ielec.colourCaches`  →  `project`, `work`, `ui`

Returns, in UI, the colours of the parcellation and of the two pial surfaces (wmparcColors, AnnotColor_R, AnnotColor_L).

---

## Images and surfaces

What a project is built on: the CT, the atlas, the cortical surfaces.

### `ielec.loadCT`  →  `project`, `work`

Reads the CT named in cfg.ct, reslices it onto the MRI's grid, and puts it in the project as project.TAC.

| | | |
|---|---|---|
| `ct` | path of the CT, a NIfTI file | required |
| `interpolation` | interpolation, as SPM numbers it | default `4` |

Errors: `ielec:noMRI`, `ielec:noSuchFile`

### `ielec.loadMask`  →  `project`, `work`

Reads the mask named in cfg.mask, reslices it onto the MRI's grid, and puts it in the project as project.mask.

| | | |
|---|---|---|
| `mask` | path of the brain mask, a NIfTI file | required |
| `interpolation` | interpolation, as SPM numbers it. It is a mask, so the default is trilinear | default `1` |

Errors: `ielec:noMRI`, `ielec:noSuchFile`

### `ielec.dummyMask`  →  `project`, `work`

Puts a mask of ones in the project, on the MRI's grid, so that a CT can be thresholded by someone who has no mask to hand.

Errors: `ielec:noMRI`

### `ielec.loadAnatomy`  →  `project`, `work`, `colours`

Reads a parcellation volume - aparc+aseg, aparc.a2009s or wmparc - onto the MRI's voxel grid, and keeps it in project.wmparc and project.wmparcS.

| | | |
|---|---|---|
| `file` | the parcellation to read. Full path. Required | required |
| `lut` | the look-up table the colours come from, if not the one in work.options.atlasLUTFile | default `''` |

Errors: `ielec:badOption`, `ielec:noMRI`

### `ielec.loadSurfaces`  →  `project`, `work`

Reads the two hemispheres of a cortical surface and keeps them in the project.

| | | |
|---|---|---|
| `right` | the right hemisphere's file. Full path. Required | required |
| `left` | the left one. Full path. Required | required |
| `target` | which pair of surfaces this is: 'pial' the cortical surface the contacts are drawn on and... | optional |
| `centre` | move the surfaces to the centre of the MRI volume. FreeSurfer writes them relative to their own... | default `false` |
| `resample` | thin both hemispheres towards this many vertices, for drawing speed. [] keeps them whole | default `[]` |

Errors: `ielec:badOption`, `ielec:noMRI`

### `ielec.loadAnnotations`  →  `project`, `work`, `colours`

Reads a FreeSurfer annotation for each hemisphere - the parcellation of the surface, one label per vertex - and keeps the labels and their colour tables in the project.

| | | |
|---|---|---|
| `right` | the right hemisphere's .annot. Full path | optional |
| `left` | the left one. Full path | optional |

Errors: `ielec:badOption`

### `ielec.buildEnvelope`  →  `project`, `work`

Wraps each hemisphere's pial surface in a smooth envelope and keeps the pair in the project, as vertices_SCE_R and the three fields beside it.

| | | |
|---|---|---|
| `resample` | thin both hemispheres towards this many vertices, for drawing speed. [] keeps them whole | default `15000` |
| `resample` | how many vertices the envelope is reduced to. [] keeps every one of them | default `15000` |
| `radius` | the radius, in millimetres, of the sphere rolled over the pial surface to enclose it. A vector... | default `work.options.buildSCEradius` |

Errors: `ielec:badOption`, `ielec:noSurfaces`

### `ielec.trimImages`  →  `project`, `work`, `report`

Crops every volume in the project - the MRI, the CT, the brain mask and the parcellation - to a box around everything the project holds in space, and moves each image-to-world transformation so that nothing moves.

| | | |
|---|---|---|
| `margin` | how much room to leave around it, in millimetres | default `10` |
| `box` | a box in voxels, [lo; hi], instead of one worked out from the project. The margin is not added... | default `[]` |

Errors: `ielec:badOption`, `ielec:emptyBox`, `ielec:noMRI`

---

## Localizing contacts

From a thresholded CT to an array in the project, in the order the workflow runs.

### `ielec.thresholdCT`  →  `project`, `work`

Finds the voxels of the CT between two intensities and inside the brain mask.

| | | |
|---|---|---|
| `lowThreshold` | lower intensity, in the CT's own units | required |
| `highThreshold` | upper intensity, the same | required |
| `denoiseKernel` | erode then dilate with a cube this many voxels wide before thresholding; 1 is off | default `1` |
| `maxCount` | keep at most this many voxels, chosen at random, and warn. [] keeps all of them | default `[]` |
| `excludeLocalized` | leave out the voxels of the arrays already localized in the project | default `false` |

Errors: `ielec:noCT`, `ielec:noMask`

### `ielec.selectVoxels`  →  `project`, `work`

Takes the voxels cfg.indices picks out of work..

| | | |
|---|---|---|
| `indices` | which of the candidate voxels are selected: a logical array as long as them, or a list of... | required |

Errors: `ielec:badSelection`, `ielec:noVoxels`

### `ielec.cluster`  →  `project`, `work`, `quality`

Splits the voxels in work.selectedVoxels into cfg.nClusters groups and takes the centre of each as a contact.

| | | |
|---|---|---|
| `nClusters` | how many contacts to find | required |

Errors: `ielec:badOption`, `ielec:noSelection`

### `ielec.fitArray`  →  `project`, `work`, `array`

Fits a grid, a strip or a depth electrode of the given size and spacing to the voxels in work.selectedVoxels, and returns the array it found.

| | | |
|---|---|---|
| `type` | 'grid', 'strip' or 'depth' | required |
| `rows` | rows of contacts; 1 for a strip or a depth | required |
| `columns` | contacts per row | required |
| `spacing` | distance between neighbouring contacts, in mm. For a depth electrode, between the second... | required |
| `firstSecondSpacing` | depth electrodes only: between the first and second contact, which differs on a Behnke-Fried... | default `[]` |
| `overlap` | 1 when the array overlaps itself, 0 when it does not. Not used for a depth | default `0` |
| `useNailedContacts` | hold the fit to the anchors already in work.anchors | default `false` |
| `nailNumbers` | which contact of the array each of those is - what the Fit button's table asks for. NaN for one... | default `[]` |
| `gridFit` | a struct of GridFit settings to change for this call, merged field by field over the set... | default `the session's set for cfg.type, as is` |

Errors: `ielec:badOption`, `ielec:noSelection`

### `ielec.indexArray`  →  `project`, `work`, `array`

Takes a set of contact coordinates, works out which contact is number one and which follows which, and returns the array it made.

| | | |
|---|---|---|
| `shape` | 'depth' a depth electrode or a strip: the contacts are ordered along the line they lie on... | required |
| `rows` | rows of contacts | sometimes |
| `columns` | contacts per row | sometimes |
| `index` | which array to number again. [] numbers the contacts in progress (work.GS) for the first time | default `[]` |

Errors: `ielec:badOption`, `ielec:noContacts`

### `ielec.addCoordinate`  →  `project`, `work`

Puts one more contact into the coordinates in progress, at the point it is given, and weighs it by the CT.

| | | |
|---|---|---|
| `coordinate` | 1-by-3, where the contact goes, in anatomical coordinates - what the cursor is on. Required | required |
| `group` | which list it joins: 'contacts', the contacts in progress, or 'anchors', the points that hold a... | default `'contacts'` |

Errors: `ielec:badOption`, `ielec:noMRI`

### `ielec.removeCoordinate`  →  `project`, `work`, `removed`

Finds the contact in progress nearest the point it is given and takes it out, together with the voxels it was made from.

| | | |
|---|---|---|
| `coordinate` | 1-by-3, the point to look near, in anatomical coordinates - what the cursor is on. Required | required |
| `tolerance` | how near is near enough, in mm | default `2` |
| `group` | which list to take it out of: 'contacts' or 'anchors' | default `'contacts'` |

Errors: `ielec:badOption`

### `ielec.clearCoordinates`  →  `project`, `work`

Empties the coordinates in progress: the contacts, the voxels they were made from, their weights and their cluster numbers.

| | | |
|---|---|---|
| `group` | which list to empty: 'contacts', the contacts in progress and the voxels behind them, or... | default `'contacts'` |

Errors: `ielec:badOption`

### `ielec.undoCoordinates`  →  `project`, `work`

Swaps the coordinates in progress with the copy kept before the last change to them.

### `ielec.acceptArray`  →  `project`, `work`, `index`

Adds ARRAY - what IELEC.FITARRAY or IELEC.CLUSTER proposed - to project.electrodes, and returns where it went.

| | | |
|---|---|---|
| `index` | which array to replace. [] adds a new one at the end, which is the usual case | default `[]` |

Errors: `ielec:badArray`, `ielec:badOption`

---

## Arrays already in the project

Changing, naming and importing arrays after they exist.

### `ielec.nameContacts`  →  `project`, `work`

Gives one array its name and its contacts theirs. WORK is not changed.

| | | |
|---|---|---|
| `index` | which array. Required | required |
| `group` | 'electrodes', the localized arrays, or 'targets', the planned ones | default `'electrodes'` |
| `baseName` | the name of the array. With no cfg.labels it is also the contacts' name: they become baseName1,... | default `''` |
| `labels` | one label per contact, as a cell of text - the recording channels, in the order of the... | default `{} A cell of strings is taken as well and kept as character vectors, which is what the project holds everywhere else.` |

Errors: `ielec:badOption`

### `ielec.reorderArray`  →  `project`, `work`

Moves the contact numbers of one array around: the coordinates, the anatomical labels, the cluster numbers and the projections all follow, so nothing about the array changes except which contact is number one and which follows which.

| | | |
|---|---|---|
| `index` | which array. Required | required |
| `change` | what to do to it: 'rotateLeft' a quarter turn anticlockwise 'rotateRight' a quarter turn... | required |
| `order` | with cfg.change 'order', the new order: the contact at position i afterwards is the one that... | default `[]` |

Errors: `ielec:badOption`

### `ielec.deleteArray`  →  `project`, `work`, `selected`

Removes one array from the project and returns the index of the array that should be shown next, by REMOVEARRAY's rule: the one before it, or the one that followed it when it was the first, or 0 when nothing is left.

| | | |
|---|---|---|
| `index` | which array to remove. Required | required |
| `group` | 'electrodes', the localized arrays, or 'targets', the planned ones | default `'electrodes'` |

Errors: `ielec:badOption`

### `ielec.importArrays`  →  `project`, `work`, `added`

Reads a file of electrodes and appends what it holds to project.electrodes.

| | | |
|---|---|---|
| `file` | the file to read. Full path. Required | required |
| `format` | 'structure' (an iElectrodes .mat), 'eeglab' (a .set) or 'fieldtrip' (an elec structure).... | required |
| `arrays` | what kind of array each one is, for the formats that do not say: a struct per array, in the... | sometimes |

Errors: `ielec:badArrays`, `ielec:badOption`, `ielec:missingOption`

### `ielec.arrayFileContents`  →  `project`, `work`, `report`

Reads a file of electrodes and says what is in it, without touching the project.

| | | |
|---|---|---|
| `file` | the file to look into. Full path. Required | required |
| `format` | 'structure' (an iElectrodes .mat), 'eeglab' (a .set) or 'fieldtrip' (an elec structure).... | required |

Errors: `ielec:badOption`

### `ielec.importLabels`  →  `project`, `work`, `labels`

Reads a list of contact labels - the channel names of the recording, usually - and keeps it in project.elecListLabels, which is what the label dialog offers when a contact is named by hand.

| | | |
|---|---|---|
| `file` | the file to read. Full path. Required | required |
| `format` | how to read it. Required, one of: 'txt' a tab delimited text list 'matlab' a .mat with a cell... | required |

Errors: `ielec:badOption`

---

## Anatomy and brain shift

What the atlas says about a contact, and where a contact really sits.

### `ielec.label`  →  `project`, `work`

Labels the contacts of every array in the project, and of the planning targets, from the anatomy: the patient's FreeSurfer parcellation in native space, or a probabilistic atlas in MNI space.

| | | |
|---|---|---|
| `space` | 'Native' or 'MNI' | default `project.currentSpace, the space the stored coordinates are in (RESOLVESPACE).` |
| `radius` | how far around a contact to look, in millimetres. 0 looks at the contact's own voxel only | default `work.options.atlasLabelingRadio` |
| `mode` | 'mode' reports the most common region in that radius, 'prob' reports every region with the... | default `work.options.atlasLabelingMode` |
| `minProbability` | in 'prob', the smallest share worth reporting | default `work.options.atlasLabelingMinProb` |

Errors: `ielec:badOption`, `ielec:noAtlas`

### `ielec.pointLabel`  →  `project`, `work`, `report`

Says what the atlas calls the place a coordinate is in. Nothing is changed: the project and work come back as they went in, and the answer is the third output.

| | | |
|---|---|---|
| `radius` | how far around the point to look, in millimetres | default `work.options.atlasLabelingRadio` |
| `mode` | 'mode' for the most common region in that radius, 'prob' for every region with its share | default `work.options.atlasLabelingMode` |
| `minProbability` | in 'prob', the smallest share worth reporting | default `work.options.atlasLabelingMinProb` |

Errors: `ielec:badOption`, `ielec:noAtlas`

### `ielec.projectArrays`  →  `project`, `work`

Projects the grids and strips onto the smooth cortical envelope and corrects the depth electrodes with them, and stores the result in each array's .projection.

| | | |
|---|---|---|
| `space` | 'Native' or 'MNI', which envelope to project onto | default `project.currentSpace.` |
| `recalculateAll` | redo the arrays that already have a projection as well as the new ones | default `false` |

Errors: `ielec:badOption`, `ielec:noArraysToProject`, `ielec:noSurface`

### `ielec.projectionState`  →  `project`, `work`, `report`

Reports on the brain-shift projection without doing anything: PROJECT and WORK come back as they went in.

| | | |
|---|---|---|
| `space` | 'Native' or 'MNI', which decides whose envelope is asked for | default `project.currentSpace.` |

Errors: `ielec:badOption`

---

## Planning, before surgery

Grids and depth electrodes planned on the brain rather than found in a CT.

### `ielec.newTarget`  →  `project`, `work`, `index`

Builds a simulated subdural grid, lays it on the smooth cortical envelope with its centre where it is told, and puts it in the project's planning targets.

| | | |
|---|---|---|
| `centre` | three numbers in any orientation, where the centre of the grid should go - the cursor, when the... | required |
| `rows` | rows of contacts. Required | required |
| `columns` | contacts per row. Required | required |
| `spacing` | distance between neighbouring contacts, in mm. Required | required |

Errors: `ielec:badOption`, `ielec:noSurfaces`

### `ielec.placeTarget`  →  `project`, `work`

Lays one of the project's planning targets down again at a new place on the smooth cortical envelope, or turns it where it is.

| | | |
|---|---|---|
| `index` | which target. Required | required |
| `centre` | three numbers in any orientation, where its centre should go. Use this or cfg.offset, not both | default `[]` |
| `offset` | three numbers in mm, added to the centre it has now - which is what the six arrow buttons do | default `[]` |
| `rotation` | an extra turn about the centre, in degrees. [] is no turn at all, which is not the same as 0:... | default `[]` |

Errors: `ielec:badOption`, `ielec:noSurfaces`

### `ielec.fitTarget`  →  `project`, `work`

Fits one of the project's planning grids to the smooth cortical envelope and stores the result in that target's .projection.

| | | |
|---|---|---|
| `index` | which planning target. Required | required |
| `index` | which planning target to fit | required |
| `springs` | a struct of springs settings to change for this call, merged over... | default `the session's planning springs, unchanged` |

Errors: `ielec:badOption`, `ielec:noSurfaces`

### `ielec.newDepthTarget`  →  `project`, `work`, `index`

Builds a simulated depth electrode - a straight line of contacts between an anatomical target and an entry side - aims it, and puts it in the project's planning targets.

| | | |
|---|---|---|
| `name` | what to call it | default `'Planning'` |
| `targetIn` | 1-by-3, the deep end | default `[0 0 0]` |
| `targetOut` | 1-by-3, the entry side | default `[45 45 45]` |
| `nContacts` | how many contacts | default `10` |
| `firstSecond` | 1st contact to 2nd, in mm | default `5` |
| `secondLast` | every later pair, in mm | default `5` |
| `framePosition` | 'Left', 'Right', 'Anterior' or 'Posterior' | default `'Anterior' So ielec.newDepthTarget([], project, work) is the button.` |

Errors: `ielec:badOption`

### `ielec.aimTarget`  →  `project`, `work`

Sets where a planned depth electrode goes and how long it is, works out where each contact then sits, and finishes with the frame angles of the direction it ended up with.

| | | |
|---|---|---|
| `index` | which planning target. Required | required |

Errors: `ielec:badOption`

### `ielec.setFrame`  →  `project`, `work`

Works out the two angles a stereotactic frame would be set to in order to drive the planned electrode along the trajectory it already has, and stores them with the target.

| | | |
|---|---|---|
| `index` | which planning target. Required | required |
| `framePosition` | how the frame is mounted: 'Left', 'Right', 'Anterior' or 'Posterior' | default `'', meaning leave the target's own, and do not write it back.` |

Errors: `ielec:badOption`

### `ielec.loadTargets`  →  `project`, `work`

Reads the planning targets written by IELEC.SAVETARGETS or by the toolbox's Save planning button, and puts them in project.targets.

| | | |
|---|---|---|
| `file` | the .mat file to read. Full path. Required | required |

Errors: `ielec:badOption`

### `ielec.saveTargets`  →  `project`, `work`

Writes project.targets to a .mat file that IELEC.LOADTARGETS and the toolbox's Load planning button can read.

| | | |
|---|---|---|
| `file` | the .mat file to write. Full path. Required | required |

Errors: `ielec:badOption`, `ielec:noSuchFolder`, `ielec:noTargets`

---

## Writing the result out

### `ielec.export`  →  `project`, `work`, `report`

Writes one file. Neither PROJECT nor WORK is changed - exporting is reading.

| | | |
|---|---|---|
| `file` | where to write. Full path. Required | required |
| `format` | which format. Required, one of: | required |

Errors: `ielec:badOption`, `ielec:noArrays`, `ielec:noCT`, `ielec:noTargets`

---

*Generated by `tools/makeApiReference.m` from `src/+ielec/*.m`.*
