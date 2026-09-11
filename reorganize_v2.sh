#!/usr/bin/env bash
# =====================================================================
# iElectrodes 2 - repository restructuring
#
# Target layout follows the architecture Alejandro discussed with ChatGPT
# ("Modernize iElectrodes GUI"), with FRONTEND and BACKEND as the two
# top-level code folders:
#
#   app/          FRONTEND  - GUI shell support: dialogs, rendering, config
#   src/          BACKEND   - GUI-free scientific code, headless-callable
#     project/      project + patient/electrode data model, options
#     io/           image loading (MRI/CT/masks), NIfTI/FreeSurfer/EDF readers
#     localization/ GridFit, clustering, energies, constraints, numbering
#     projection/   brain-shift compensation, SCE, hull, depth displacement
#     labeling/     anatomical labelling (MNI atlas + FreeSurfer native)
#     geometry/     pure maths: distances, rotations, transforms, meshes
#     export/       text / FieldTrip exports
#   resources/    atlases, look-up tables, MNI meshes, icon
#   third_party/  bundled external toolboxes (SPM12, iso2mesh, NIfTI tools)
#   examples/     sample .iel projects
#   legacy/       stale .old backups
#   tests/ docs/  created empty, for the phases that follow
#
# NOTE ON MATLAB PACKAGES
# ChatGPT's final target uses +package folders (ielectrodes.localization.gridFit).
# We deliberately use PLAIN folder names in this step: MATLAB would then require
# every one of the ~2500 call sites to be rewritten as fully-qualified names.
# The folder NAMES already match the future packages, so converting later is
# just renaming "localization" -> "+localization" plus the call-site update,
# done one workflow at a time (ChatGPT Phase 3).
#
# Run from the repo root (where electrodes_gui.m lives), in Git Bash:
#     bash reorganize_v2.sh
# Close VS Code and MATLAB first - open file handles make git mv fail on Windows.
# =====================================================================

set -e

if [ ! -f electrodes_gui.m ]; then
  echo "ERROR: run this from the folder that contains electrodes_gui.m"; exit 1
fi

# ---------------------------------------------------------------------
# 0. Git baseline (ChatGPT Phase 1: tag the working version before changing it)
# ---------------------------------------------------------------------
if [ ! -d .git ]; then
  echo ">> initialising git repository"
  git init
  git add -A
  git commit -m "iElectrodes v1.020 - original working version from Alejandro"
else
  echo ">> git repo already present"
  if ! git diff --quiet || ! git diff --cached --quiet; then
    git add -A
    git commit -m "Snapshot before v2 restructuring"
  fi
fi

if ! git rev-parse -q --verify refs/tags/v1-baseline >/dev/null; then
  git tag -a v1-baseline -m "Last known-good v1 layout, before the v2 restructuring"
  echo ">> tagged v1-baseline"
fi

# ---------------------------------------------------------------------
# 1. Create the new skeleton
# ---------------------------------------------------------------------
mkdir -p "app/config"
mkdir -p "app/dialogs"
mkdir -p "app/rendering"
mkdir -p "legacy"
mkdir -p "resources"
mkdir -p "src/export"
mkdir -p "src/geometry"
mkdir -p "src/io"
mkdir -p "src/labeling"
mkdir -p "src/localization"
mkdir -p "src/project"
mkdir -p "src/projection"
mkdir -p "third_party"
mkdir -p "examples"
mkdir -p "tests"
mkdir -p "docs"

# helper: move only if the source exists, so a missing file warns instead of aborting
mv_if () {  # $1 = source, $2 = destination folder
  if [ -e "$1" ]; then
    git mv "$1" "$2/" 
  else
    echo "   (skipped, not found: $1)"
  fi
}

# ---------------------------------------------------------------------
# 2. third_party/ - bundled external toolboxes (not iElectrodes code)
# ---------------------------------------------------------------------
mv_if "priv/SPM_functions" "third_party"
mv_if "priv/iso2mesh_functions" "third_party"
mv_if "priv/Nifti_tools_functions" "third_party"
mv_if "priv/compile" "third_party"

# ---------------------------------------------------------------------
# 3. Split priv/ into FRONTEND (app/) and BACKEND (src/)
# ---------------------------------------------------------------------
echo ">> app/config"
mv_if "priv/defaultColors.m" "app/config"
mv_if "priv/defaultGuiVariables.m" "app/config"
mv_if "priv/checkUpdates.m" "app/config"

echo ">> app/dialogs"
mv_if "priv/addremovelist.m" "app/dialogs"
mv_if "priv/addremovelist.fig" "app/dialogs"
mv_if "priv/elecImportDlg.m" "app/dialogs"
mv_if "priv/elecImportDlg.fig" "app/dialogs"
mv_if "priv/movelist.m" "app/dialogs"
mv_if "priv/movelist.fig" "app/dialogs"
mv_if "priv/electrodeNailNaumber_uitable.m" "app/dialogs"

echo ">> app/rendering"
mv_if "priv/plotElectrodesLines.m" "app/rendering"
mv_if "priv/mvis.m" "app/rendering"
mv_if "priv/Cyl.m" "app/rendering"
mv_if "priv/select3d.m" "app/rendering"

echo ">> legacy"
mv_if "priv/niftiTools2spm.m.old" "legacy"
mv_if "priv/searchClosest.m.old" "legacy"

echo ">> resources"
mv_if "priv/FreeSurferColorLUT.mat" "resources"
mv_if "priv/HMAT_LUT.mat" "resources"
mv_if "priv/HOatlas_cort-subCort_lateralized.mat" "resources"
mv_if "priv/MNI_hull_LR.mat" "resources"
mv_if "priv/MNImesh.mat" "resources"
mv_if "priv/S-matrix_to_MNI.mat" "resources"
mv_if "priv/Yeo2011LUT.mat" "resources"
mv_if "priv/Icon_mini.jpg" "resources"

echo ">> src/export"
mv_if "priv/aLabels2txt_new.m" "src/export"
mv_if "priv/aLabelsTargets2txt_new.m" "src/export"
mv_if "priv/electrodes2neighboursFTformat.m" "src/export"

echo ">> src/geometry"
mv_if "priv/eucDist.m" "src/geometry"
mv_if "priv/eucDistMat.m" "src/geometry"
mv_if "priv/angleV.m" "src/geometry"
mv_if "priv/AxelRot.m" "src/geometry"
mv_if "priv/my_quatrotate.m" "src/geometry"
mv_if "priv/wrapToPi.m" "src/geometry"
mv_if "priv/alpha_beta2delta.m" "src/geometry"
mv_if "priv/delta2alpha_beta.m" "src/geometry"
mv_if "priv/distance3DP2E.m" "src/geometry"
mv_if "priv/distance3DP2F.m" "src/geometry"
mv_if "priv/lineIntersect3D.m" "src/geometry"
mv_if "priv/interseccionVecMesh.m" "src/geometry"
mv_if "priv/interseccionVecTri.m" "src/geometry"
mv_if "priv/faceAreaCuboid.m" "src/geometry"
mv_if "priv/volumeCuboid.m" "src/geometry"
mv_if "priv/sphere_gd.m" "src/geometry"
mv_if "priv/spherefit.m" "src/geometry"
mv_if "priv/mesh2AnatSpace.m" "src/geometry"
mv_if "priv/AnatSpace2Mesh.m" "src/geometry"
mv_if "priv/transformElectrodes.m" "src/geometry"
mv_if "priv/transformTargets.m" "src/geometry"

echo ">> src/io"
mv_if "priv/loading_images.m" "src/io"
mv_if "priv/loading_images_SPM.m" "src/io"
mv_if "priv/niftiTools2spm.m" "src/io"
mv_if "priv/mixImages.m" "src/io"
mv_if "priv/fread3.m" "src/io"
mv_if "priv/read_annotation.m" "src/io"
mv_if "priv/read_curv.m" "src/io"
mv_if "priv/readEdfHeader.m" "src/io"
mv_if "priv/getLabelsFromFile.m" "src/io"
mv_if "priv/importTxtLabels.m" "src/io"

echo ">> src/labeling"
mv_if "priv/anatomicLabel.m" "src/labeling"
mv_if "priv/anatomicLabelFS.m" "src/labeling"

echo ">> src/localization"
mv_if "priv/gridFit.m" "src/localization"
mv_if "priv/clustering.m" "src/localization"
mv_if "priv/recluster.m" "src/localization"
mv_if "priv/farout.m" "src/localization"
mv_if "priv/distance.m" "src/localization"
mv_if "priv/gridMatchEnergy.m" "src/localization"
mv_if "priv/hybridEnergy.m" "src/localization"
mv_if "priv/defSpringsEnergy.m" "src/localization"
mv_if "priv/Kc_optimal.m" "src/localization"
mv_if "priv/distanceConstrain.m" "src/localization"
mv_if "priv/linFunDistanceConstrain.m" "src/localization"
mv_if "priv/surfFunDistanceConstrain.m" "src/localization"
mv_if "priv/meshDistanceConstrain.m" "src/localization"
mv_if "priv/meshDistance_Deformation_Constrain.m" "src/localization"
mv_if "priv/gridVolumeConstrain.m" "src/localization"
mv_if "priv/gridVolumeAreaConstrain.m" "src/localization"
mv_if "priv/gridVolumeDistanceConstrain.m" "src/localization"
mv_if "priv/defineGrid.m" "src/localization"
mv_if "priv/defineStrip.m" "src/localization"
mv_if "priv/curveGrid.m" "src/localization"
mv_if "priv/findCornersGrid.m" "src/localization"
mv_if "priv/grid2PCAorSph.m" "src/localization"
mv_if "priv/tangentialGrid.m" "src/localization"
mv_if "priv/searchClosest.m" "src/localization"
mv_if "priv/indexGridElectrodes.m" "src/localization"
mv_if "priv/indexDepthElectrodes.m" "src/localization"
mv_if "priv/reorderElectrodes.m" "src/localization"
mv_if "priv/removeContactDepth.m" "src/localization"
mv_if "priv/makeAdjMat.m" "src/localization"
mv_if "priv/concatenateAdjMat.m" "src/localization"
mv_if "priv/makeCouboidsInd.m" "src/localization"
mv_if "priv/makeFace4CouboidsInd.m" "src/localization"

echo ">> src/project"
mv_if "priv/checkProjectStructure.m" "src/project"
mv_if "priv/checkElectrodeStructure.m" "src/project"
mv_if "priv/default_ielectrodes_options.m" "src/project"

echo ">> src/projection"
mv_if "priv/projection2mesh.m" "src/projection"
mv_if "priv/projection1D.m" "src/projection"
mv_if "priv/projectionSCE2pial.m" "src/projection"
mv_if "priv/buildSCE.m" "src/projection"
mv_if "priv/electrodes2hullCorrection.m" "src/projection"
mv_if "priv/depthDisplacementCorrection.m" "src/projection"
mv_if "priv/meshROI.m" "src/projection"

# ---------------------------------------------------------------------
# 4. examples/ - sample projects (large .iel files)
# ---------------------------------------------------------------------
mv_if "exampleMNIspace.iel" "examples"
mv_if "exampleNativeSpace.iel" "examples"

# ---------------------------------------------------------------------
# 5. Activate the patched electrodes_gui.m
#    (its addpath block now points at src/ app/ resources/ third_party/
#     instead of priv/, and uses fullfile() so it works on every OS)
# ---------------------------------------------------------------------
if [ -f _patched_electrodes_gui.m ]; then
  mv -f _patched_electrodes_gui.m electrodes_gui.m
  echo ">> electrodes_gui.m addpath block updated"
else
  echo "WARNING: _patched_electrodes_gui.m not found - electrodes_gui.m still points at priv/"
fi

# ---------------------------------------------------------------------
# 6. Report anything left behind in priv/
# ---------------------------------------------------------------------
if [ -d priv ] && [ -n "$(ls -A priv 2>/dev/null)" ]; then
  echo ""
  echo "!! priv/ is not empty - these files were not in the mapping:"
  ls -A priv
  echo "   (they still work: electrodes_gui.m keeps priv/ on the path as a safety net)"
else
  rmdir priv 2>/dev/null || true
  echo ">> priv/ is now empty and removed"
fi

echo ""
echo "Done."
echo "1) Open electrodes_gui.m in MATLAB and check the app still starts."
echo "2) Load one of the projects in examples/ to exercise the full pipeline."
echo "3) Then:  git add -A && git commit -m \"Restructure into app/ (frontend) and src/ (backend)\""