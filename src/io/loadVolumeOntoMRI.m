function [volume, S] = loadVolumeOntoMRI(pathName, fileName, T1, interpolation)
%LOADVOLUMEONTOMRI  Read a NIfTI volume onto the patient MRI's voxel grid.
%
%   [volume, S] = loadVolumeOntoMRI(pathName, fileName, T1, interpolation)
%   reads a .nii file and reslices it onto the same voxel size and bounding
%   box as T1, so that a voxel index means the same thing in both. S is the
%   image-to-world transformation, the first three rows of the resliced
%   volume's affine matrix.
%
%   INTERPOLATION is the resampling order, and the choice matters:
%
%       0   nearest neighbour - for label volumes, where the voxel values
%           are region numbers. Averaging them would invent regions that do
%           not exist.
%       1   trilinear - for masks.
%       4   fourth-order Lagrange - for greyscale images such as the CT,
%           where smoothness is what is wanted.
%
%   Every caller used to repeat the same three lines to work out the grid:
%
%       vprm   = spm_imatrix(T1.vol.mat);
%       voxdim = vprm(7:9);
%       bbox   = world_bb(T1.vol);
%
%   in the Load CT button twice and in the Load parcellation button once.
%   They are here instead, which is also where the reason for them belongs:
%   every volume in a project has to sit on the MRI's grid, or coordinates
%   read from one would not mean the same in another.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also LOADPARCELLATION, LOADING_IMAGES_SPM, WORLD_BB.

if isempty(T1)
    error('loadVolumeOntoMRI:noMRI', ...
          'The MRI must be loaded first: every other volume is resliced onto its grid.');
end

vprm   = spm_imatrix(T1.vol.mat);
voxdim = vprm(7:9);
bbox   = world_bb(T1.vol);

volume = loading_images_SPM(pathName, fileName, interpolation, voxdim, bbox);
S      = volume.vol.mat(1:3,:);
end
