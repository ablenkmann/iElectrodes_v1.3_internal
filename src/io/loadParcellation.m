function [parcellation, parcellationS] = loadParcellation(pathName, fileName, T1)
%LOADPARCELLATION  Read a FreeSurfer parcellation onto the MRI's grid.
%
%   [parcellation, parcellationS] = loadParcellation(pathName, fileName, T1)
%   reads a parcellation volume - aparc+aseg, aparc.a2009s or wmparc - onto
%   the same voxel grid as T1, using nearest-neighbour interpolation because
%   the voxel values are region numbers and averaging them would invent
%   regions that do not exist.
%
%   PARCELLATIONS is the image-to-world transformation, kept beside the
%   volume the way the rest of the toolbox expects.
%
%   The Load parcellation button is this call with a file dialog around it.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also LOADVOLUMEONTOMRI, PARCELLATIONCOLOURS.

[parcellation, parcellationS] = loadVolumeOntoMRI(pathName, fileName, T1, 0);
end
