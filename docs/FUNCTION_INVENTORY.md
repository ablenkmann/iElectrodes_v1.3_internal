# Function inventory of `electrodes_gui.m`

Every function in `electrodes_gui.m`, classified by what it does. The reference
plan for iElectrodes 2 named this as the next concrete step: *"an architectural
inventory of the existing GUI functions: classify each as UI, plotting,
workflow, state, I/O, or scientific algorithm."*

It describes the file as of the end of the backend separation.

## The result

**No scientific algorithm is left in the GUI.** Every calculation - thresholding,
clustering, fitting, labelling, projection, trajectory and frame geometry,
planning-grid placement, import and export - is a function in `src/`, and the
GUI calls it. `examples/exampleHeadlessWorkflow.m` runs the main workflow with
no window open, which is the plan's test for exactly this.

| category | functions | lines of code |
|---|---:|---:|
| Workflow | 40 | 1233 |
| Work-state operations still in the GUI | 4 | 136 |
| Navigation | 9 | 263 |
| Plotting | 7 | 569 |
| UI | 87 | 808 |
| Selection state | 8 | 12 |
| GUIDE boilerplate | 7 | 54 |
| **total** | **162** | **3075** |

"I/O" has no row of its own: every file is read or written by a function in
`src/io/` or `src/export/`, and what remains in the GUI of it is the file
dialog, which is counted under Workflow.

Lines of code exclude comments and blank lines.

## How it was made

Each function was first classified automatically from what its code
contains - calls to drawing functions, to dialogs, to functions in `src/`, and
reads and writes of controls - and then read by hand where the rule could be
wrong. Two corrections came out of reading: callbacks whose only backend call
converts a coordinate for the cursor are Navigation, not Workflow, and the
MRI/CT blend is Plotting.

A separate search looked for arithmetic in every function that is not
Plotting. It found one real case - the stereotactic-frame angles, which were
then moved to `src/geometry/` (`frameTrajectoryEndPoint`,
`trajectoryFrameAngles`) - and the four work-state operations below. The rest
of what it matched was coordinate conversion for the cursor and rounding for
display.

## Still in the GUI, and worth moving next

These are small, and none is a scientific algorithm, but each changes `work`
in a way that is not presentation:

- **`NewTargetpushbutton_Callback`** (line 4637, 37 lines) builds a default depth planning target (10 contacts, 5 mm apart) while filling the Simulate boxes - the depth counterpart of `newPlanningGrid`.
- **`DelCoordinateButton_Callback`** (line 3401, 30 lines) removes the contact nearest the cursor from `work.GS`, with its voxels, and renumbers the clusters after it.
- **`AddCoordinateButton_Callback`** (line 3357, 26 lines) adds the cursor position to `work.GS` as a contact.
- **`Indexpushbutton_Callback`** (line 3591, 43 lines) renumbers the voxel clusters to follow the new contact order - the same loop, written twice.

Two kinds of repetition are also worth knowing about for the frontend, though
both are presentation: the eight next/previous buttons for arrays and contacts
(Navigation) are four pairs of near-copies, and every callback that changes the
electrodes ends by setting its own list of redraw flags.

## Every function

### Workflow - 40 functions

Carries out one user action: asks through a dialog or reads the controls, calls the backend in `src/` to do the work, and puts the result in `project` or `work`. This is what a button callback should be.

| function | line | code | calls in `src/` |
|---|---:|---:|---|
| `Newuipushtool_ClickedCallback` | 387 | 51 | `loading_images_SPM`, `mesh2AnatSpace`, `newProject` |
| `LoadCTtool_ClickedCallback` | 471 | 33 | `loadVolumeOntoMRI` |
| `Savepushtool_ClickedCallback` | 543 | 22 | `writeIelFile` |
| `Openpushtool_ClickedCallback` | 578 | 77 | `checkProjectStructure`, `liftToProject`, `liftToUi`, `liftToWork`, `mesh2AnatSpace`, `readIelFile` |
| `SaveElectrodespushtool_ClickedCallback` | 698 | 96 | `electrodeCoordinates`, `writeBIDScoordinateSystem`, `writeBIDSelectrodes`, `writeEEGLABcoordinates`, `writeElectrodeStructure`, `writeFieldTripElectrodes` |
| `LoadElectrodespushtool_ClickedCallback` | 822 | 83 | `electrodeArrayFromContacts`, `groupContactsByArray`, `readEEGLABelectrodes`, `readElectrodeStructure`, `readFieldTripElectrodes` |
| `Reportuipushtool_ClickedCallback` | 934 | 19 | `aLabels2txt_new` |
| `LoadFSlabelsuipushtool_ClickedCallback` | 969 | 19 | `loadParcellation`, `parcellationColours` |
| `labels2MNIspace` | 1071 | 7 | `labelElectrodesMNI` |
| `labels2NativeSpace` | 1091 | 5 | `labelElectrodesNative` |
| `addFSsurfacesuipushtool_ClickedCallback` | 1109 | 80 | `annotationColours`, `centreSurfaces`, `readSurfacePair`, `read_annotation` |
| `addSCEuipushtool_ClickedCallback` | 1286 | 50 | `buildSCE`, `centreSurfaces`, `readSurfacePair`, `resampleSurfacePair` |
| `savePlanninguitoggletool_ClickedCallback` | 1397 | 15 | `savePlanningTargets` |
| `LoadPlanninguitoggletool_ClickedCallback` | 1422 | 18 | `loadPlanningTargets` |
| `ReportPlanninguipushtool_ClickedCallback` | 1457 | 14 | `aLabelsTargets2txt_new` |
| `Configpushtool_ClickedCallback` | 1686 | 18 | `default_ielectrodes_options` |
| `ClusterButton_Callback` | 3092 | 29 | `clusterContacts` |
| `Fitpushbutton_Callback` | 3145 | 82 | `electrodeFromGridFit`, `gridFit`, `gridFitOptions` |
| `getThresholdedVoxels` | 3300 | 31 | `voxelWeights` |
| `addElectrode2structure` | 3666 | 35 | `AnatSpace2Mesh`, `addArray` |
| `rLpushbutton_Callback` | 3727 | 18 | `reorderElectrodes` |
| `rRpushbutton_Callback` | 3782 | 18 | `reorderElectrodes` |
| `fLRpushbutton_Callback` | 3836 | 14 | `reorderElectrodes` |
| `fUDpushbutton_Callback` | 3885 | 14 | `reorderElectrodes` |
| `FlipLabelsPushbutton_Callback` | 3937 | 12 | `reorderElectrodes` |
| `manualIndexpushbutton_Callback` | 3983 | 17 | `reorderElectrodes` |
| `LabelAutoPushbutton_Callback` | 4020 | 15 | `nameArrayContacts` |
| `LabelListPushbutton_Callback` | 4050 | 56 | `applyContactLabels`, `getLabelsFromFile` |
| `processProjections` | 4178 | 39 | `arrayProjectionState`, `electrodes2hullCorrection`, `sceSurfaceForSpace` |
| `RemoveArrayPushbutton_Callback` | 4546 | 31 | `AnatSpace2Mesh`, `removeArray` |
| `setPlanningPoint` | 4780 | 49 | `mesh2AnatSpace`, `voxelFromPlaneClick` |
| `angleChange` | 5016 | 23 | `trajectoryEndPoint` |
| `updateTarget` | 5055 | 33 | `depthTrajectory` |
| `newPlanningGridButton_Callback` | 5443 | 17 | `newPlanningGrid` |
| `fitPlanningGridButton_Callback` | 5509 | 18 | `electrodes2hullCorrection` |
| `ChangeCenterPlanningGridButton_Callback` | 5554 | 6 | `placePlanningGrid` |
| `nudgePlanningGrid` | 5651 | 10 | `placePlanningGrid` |
| `addtarget2structure` | 5684 | 18 | `AnatSpace2Mesh`, `addArray` |
| `removePlanningArrayButton_Callback` | 5722 | 31 | `AnatSpace2Mesh`, `removeArray` |
| `editPlanningArrayName_Callback` | 5768 | 10 | `nameArrayContacts` |

### Work-state operations still in the GUI - 4 functions

Small operations on `work` that are data handling rather than presentation. Not scientific algorithms, but they belong outside the GUI - the natural first jobs of the frontend phase (see below).

| function | line | code | calls in `src/` |
|---|---:|---:|---|
| `AddCoordinateButton_Callback` | 3357 | 26 | `mesh2AnatSpace` |
| `DelCoordinateButton_Callback` | 3401 | 30 | `eucDistMat`, `mesh2AnatSpace` |
| `Indexpushbutton_Callback` | 3591 | 43 | `indexDepthElectrodes`, `indexGridElectrodes`, `makeAdjMat` |
| `NewTargetpushbutton_Callback` | 4637 | 37 | `checkElectrodeStructure`, `makeAdjMat` |

### Navigation - 9 functions

Moves the cursor, the sliders and the 2D views to a contact or a clicked point. The only backend call is the voxel/anatomical coordinate conversion.

| function | line | code | calls in `src/` |
|---|---:|---:|---|
| `figure1_WindowButtonDownFcn` | 249 | 33 | `AnatSpace2Mesh` |
| `NextArrayPushbutton_Callback` | 4344 | 31 | `AnatSpace2Mesh` |
| `PrevArrayPushbutton_Callback` | 4394 | 31 | `AnatSpace2Mesh` |
| `NextElecPushbutton_Callback` | 4443 | 27 | `AnatSpace2Mesh` |
| `PrevElecPushbutton_Callback` | 4486 | 27 | `AnatSpace2Mesh` |
| `nextPlanningArray_Callback` | 5860 | 30 | `AnatSpace2Mesh` |
| `prevPlannigArray_Callback` | 5908 | 30 | `AnatSpace2Mesh` |
| `nextPlanningElecButton_Callback` | 5956 | 27 | `AnatSpace2Mesh` |
| `prevPlanningElecButton_Callback` | 6001 | 27 | `AnatSpace2Mesh` |

### Plotting - 7 functions

Draws: the 3D view, the 2D slices, the cross-hairs, the thresholded-voxel view, the MRI/CT blend.

| function | line | code | calls in `src/` |
|---|---:|---:|---|
| `updateTAC` | 1724 | 126 | `AnatSpace2Mesh`, `anatomicLabel`, `anatomicLabelFS`, `mesh2AnatSpace` |
| `updateElectrodes3D` | 1925 | 269 | - |
| `cross2D` | 2332 | 67 | - |
| `cross3D` | 2438 | 30 | `mesh2AnatSpace` |
| `cross3DThres` | 2491 | 30 | `mesh2AnatSpace` |
| `updatePlot` | 2584 | 30 | `thresholdCTVoxels` |
| `updateMix_TAC_MR` | 2869 | 17 | `mixImages` |

### UI - 87 functions

Reads or writes controls, shows or hides panels, sets redraw flags, and the small dialogs that only inform the user. No backend call and no calculation.

| function | line | code |
|---|---:|---:|
| `figure1_CloseRequestFcn` | 198 | 30 |
| `figure1_WindowScrollWheelFcn` | 319 | 36 |
| `MNILabelstogglebutton_OnCallback` | 1037 | 6 |
| `MNILabelstogglebutton_OffCallback` | 1054 | 6 |
| `ClearFSsurfaceuipushtool2_ClickedCallback` | 1255 | 18 |
| `removeSCEuipushtooluipushtool_ClickedCallback` | 1374 | 11 |
| `uitoggletool2_ClickedCallback` | 1483 | 6 |
| `ColorMappushtool_ClickedCallback` | 1497 | 9 |
| `resetTACplotButton_ClickedCallback` | 1513 | 4 |
| `ToggleLayoutuitoggletool_ClickedCallback` | 1530 | 49 |
| `viewCrossbutton_ClickedCallback` | 1601 | 6 |
| `snapshoottool_ClickedCallback` | 1618 | 22 |
| `uipushtool13_ClickedCallback` | 1651 | 13 |
| `helpPushtool_ClickedCallback` | 1677 | 1 |
| `Reset3Dpushbutton_Callback` | 2311 | 10 |
| `GoToButton_Callback` | 2542 | 18 |
| `Leftcheckbox_Callback` | 2643 | 3 |
| `Rightcheckbox_Callback` | 2657 | 3 |
| `LeftSCEcheckbox_Callback` | 2671 | 3 |
| `RightSCEcheckbox_Callback` | 2682 | 3 |
| `PlotConnCheckbox_Callback` | 2694 | 4 |
| `DispLabelsCheckbox_Callback` | 2707 | 3 |
| `Annotationcheckbox_Callback` | 2721 | 3 |
| `sliderX_Callback` | 2738 | 2 |
| `sliderY_Callback` | 2752 | 2 |
| `sliderZ_Callback` | 2766 | 2 |
| `AlphaSlider_Callback` | 2781 | 3 |
| `RotLeftpushbutton_Callback` | 2797 | 1 |
| `RotRightpushbutton_Callback` | 2804 | 1 |
| `MinWinslider_Callback` | 2816 | 7 |
| `MaxWinslider_Callback` | 2835 | 7 |
| `TAC_MRIslider_Callback` | 2856 | 3 |
| `ElecOverlaycheckbox_Callback` | 2910 | 3 |
| `planningOverlaycheckbox_Callback` | 2923 | 3 |
| `Collapsecheckbox_Callback` | 2936 | 3 |
| `parcellationCheckbox_Callback` | 2949 | 3 |
| `edgeCheckbox_Callback` | 2963 | 4 |
| `sliderThrMax_Callback` | 2982 | 2 |
| `sliderThrMin_Callback` | 2997 | 2 |
| `denoiseSlider_Callback` | 3012 | 2 |
| `LocalizedCheckbox_Callback` | 3027 | 2 |
| `ImgDilatePushbutton_Callback` | 3043 | 8 |
| `ImgErodePushbutton_Callback` | 3059 | 8 |
| `SelectVoxelspushbutton_Callback` | 3077 | 4 |
| `readLocalizationSettings` | 3278 | 7 |
| `ClearAllButton_Callback` | 3455 | 19 |
| `Recpushbutton_Callback` | 3508 | 16 |
| `arrayUipanel_SelectionChangeFcn` | 3547 | 22 |
| `projectSCEcheckbox_Callback` | 4145 | 13 |
| `editArrayName_Callback` | 4245 | 10 |
| `editElecLabels_Callback` | 4277 | 11 |
| `setElecCoordpushbutton_Callback` | 4304 | 23 |
| `plotElectrodesOneAllUipanel_SelectionChangedFcn` | 4528 | 7 |
| `PlanningSelectionGroup_SelectionChangedFcn` | 4600 | 5 |
| `showPlanningPanel` | 4617 | 13 |
| `FirstSecondTargetedit_Callback` | 4696 | 9 |
| `SecondLastTargetEdit_Callback` | 4716 | 9 |
| `nTargetEdit_Callback` | 4737 | 9 |
| `TargetInpushbutton_Callback` | 4760 | 2 |
| `TargetOutpushbutton_Callback` | 4768 | 2 |
| `TargetInXedit_Callback` | 4854 | 9 |
| `TargetInYedit_Callback` | 4875 | 9 |
| `TargetInZedit_Callback` | 4895 | 9 |
| `TargetOutXedit_Callback` | 4917 | 9 |
| `TargetOutYedit_Callback` | 4937 | 9 |
| `TargetOutZedit_Callback` | 4957 | 9 |
| `ElevacionTargetedit_Callback` | 4979 | 7 |
| `AzimuthTargetedit_Callback` | 4997 | 7 |
| `estimateAnglesFrame` | 5107 | 21 |
| `Framebuttongroup_SelectionChangedFcn` | 5160 | 12 |
| `AlphaAngleEdit_Callback` | 5187 | 7 |
| `BetaAngleEdit_Callback` | 5203 | 7 |
| `AlphaBetaChange` | 5219 | 25 |
| `UpdateTargetEditBox` | 5262 | 77 |
| `clearPlanningBoxes` | 5420 | 14 |
| `pushbuttonSup_Callback` | 5574 | 2 |
| `moveInfButton_Callback` | 5583 | 2 |
| `movePosButton_Callback` | 5592 | 2 |
| `moveAntButton_Callback` | 5601 | 2 |
| `pushbuttonLeft_Callback` | 5610 | 2 |
| `pushbuttonRight_Callback` | 5619 | 2 |
| `RotLButton_Callback` | 5628 | 2 |
| `rotRButton_Callback` | 5637 | 2 |
| `redrawPlanningGrid` | 5669 | 5 |
| `editPlanningElecLabel_Callback` | 5793 | 11 |
| `setPlanningElecCoordpushbutton_Callback` | 5819 | 23 |
| `plotTargetsOneAllUipanel_SelectionChangedFcn` | 6047 | 6 |

### Selection state - 8 functions

One-line accessors for which array and contact are selected, in `work.selection`.

| function | line | code |
|---|---:|---:|
| `selectedArray` | 6079 | 1 |
| `selectedContact` | 6083 | 1 |
| `setSelectedArray` | 6087 | 2 |
| `setSelectedContact` | 6092 | 2 |
| `selectedPlanningArray` | 6108 | 1 |
| `selectedPlanningTarget` | 6112 | 1 |
| `setSelectedPlanningArray` | 6116 | 2 |
| `setSelectedPlanningTarget` | 6121 | 2 |

### GUIDE boilerplate - 7 functions

Generated by GUIDE: the entry point, the opening and output functions, and callbacks left empty.

| function | line | code |
|---|---:|---:|
| `electrodes_gui` | 53 | 15 |
| `electrodes_gui_OutputFcn` | 99 | 1 |
| `electrodes_gui_OpeningFcn` | 109 | 38 |
| `ClearLastButton_Callback` | 3487 | 0 |
| `rowsPlanningGridEdit_Callback` | 5479 | 0 |
| `columnsPlanningGridEdit_Callback` | 5489 | 0 |
| `distancePlanningGridEdit_Callback` | 5498 | 0 |
