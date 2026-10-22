function [project, work] = loadMask(cfg, project, work)
%IELEC.LOADMASK  Add the brain mask to a project.
%
%   [project, work] = ielec.loadMask(cfg, project, work) reads the mask named
%   in cfg.mask, reslices it onto the MRI's grid, and puts it in the project
%   as project.mask. WORK is returned unchanged.
%
%   Options (cfg):
%     cfg.mask           path of the brain mask, a NIfTI file.       required
%     cfg.interpolation  interpolation, as SPM numbers it. It is a mask,
%                        so the default is trilinear.              Default: 1
%
%   WHAT THE MASK IS FOR
%
%   It decides which voxels IELEC.THRESHOLDCT may select at all. Bone is
%   brighter than an electrode, so a threshold over the whole head returns
%   the skull; inside the mask it returns contacts. The Dilate and Erode
%   buttons in electrodes_gui.m change it in place afterwards; nothing else
%   in the layer reads it.
%
%   It is resliced onto the MRI's grid, like every other volume, so it does
%   not have to arrive on the CT's grid or on its own.
%
%   Either order works - this and IELEC.LOADCT are independent, and neither
%   looks at the other - and IELEC.THRESHOLDCT refuses until both are there,
%   naming the one that is missing.
%
%   WORK is an argument and an output so that every ielec function has the
%   same signature, not because this changes it.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:noMRI (load an MRI first), ielec:noSuchFile, and those of
%   the cfg check.
%
%   Example
%       cfg = [];
%       cfg.mask = 'C:\data\p01\mask.nii';
%       [project, work] = ielec.loadMask(cfg, project, work);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.LOADCT, IELEC.THRESHOLDCT, LOADVOLUMEONTOMRI,
%   docs/API_LAYER.md.

if ~isfield(project, 'T1') || isempty(project.T1)
    error('ielec:noMRI', ...
        'ielec.loadMask: load an MRI first - every other volume is resliced onto its grid.');
end

defaults.interpolation = 1;
cfg = checkCfg(cfg, defaults, {'mask'}, 'loadMask');

if ~ischar(cfg.mask)
    error('ielec:badOption', 'ielec.loadMask: cfg.mask must be a file name.');
end
if ~isfile(cfg.mask)
    error('ielec:noSuchFile', 'ielec.loadMask: no such file: %s', cfg.mask);
end

project.mask = loadVolumeOntoMRI('', cfg.mask, project.T1, cfg.interpolation);

project = recordStep(project, mfilename, cfg);
end
