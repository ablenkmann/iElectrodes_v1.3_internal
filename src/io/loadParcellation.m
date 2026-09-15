function [parcellation, parcellationS] = loadParcellation(pathName, fileName, T1)
%LOADPARCELLATION  Read a FreeSurfer parcellation onto the MRI's grid.
%
%   [parcellation, parcellationS] = loadParcellation(pathName, fileName, T1)
%   reads a parcellation volume - aparc+aseg, aparc.a2009s or wmparc - and
%   resamples it onto the same voxel grid and bounding box as T1, so that a
%   voxel index means the same thing in both. Nearest-neighbour
%   interpolation is used, because the voxel values are region numbers and
%   averaging them would invent regions that do not exist.
%
%   PARCELLATIONS is the image-to-world transformation, the first three rows
%   of the volume's affine matrix, kept beside the volume the way the rest
%   of the toolbox expects.
%
%   The Load parcellation button is this call with a file dialog around it.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also PARCELLATIONCOLOURS, LOADING_IMAGES_SPM.

if isempty(T1)
    error('loadParcellation:noMRI', ...
          'The MRI must be loaded first: the parcellation is resampled onto its grid.');
end

vprm   = spm_imatrix(T1.vol.mat);
voxdim = vprm(7:9);
bbox   = world_bb(T1.vol);

parcellation  = loading_images_SPM(pathName, fileName, 0, voxdim, bbox);  % 0 = nearest neighbour
parcellationS = parcellation.vol.mat(1:3,:);
end
