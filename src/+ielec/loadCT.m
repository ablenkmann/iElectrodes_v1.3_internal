function [project, work] = loadCT(cfg, project, work)
%IELEC.LOADCT  Add the CT and the brain mask to a project.
%
%   [project, work] = ielec.loadCT(cfg, project, work) reads the CT named in
%   cfg.ct and the mask named in cfg.mask, reslices both onto the MRI's grid,
%   and puts them in the project. WORK gets the CT's intensity limits, which
%   the threshold sliders work from.
%
%   Options (cfg):
%     cfg.ct                 path of the CT, a NIfTI file.           required
%     cfg.mask               path of the brain mask, a NIfTI file.   required
%     cfg.interpolation      interpolation for the CT, as SPM numbers
%                            it.                                   Default: 4
%     cfg.maskInterpolation  interpolation for the mask. It is a mask, so
%                            the default is trilinear.             Default: 1
%
%   The CT must already be coregistered to the MRI: it is resliced onto the
%   MRI's grid, not registered to it. The mask decides which voxels the
%   thresholding may select at all, so both are needed together; the Load CT
%   button asks for them one after the other.
%
%   project.S2, the image-to-world transformation, is taken from the CT
%   after reslicing, as the button did.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:noMRI (load an MRI first), ielec:noSuchFile, and those of
%   the cfg check.
%
%   Example
%       cfg = [];
%       cfg.ct   = 'C:\data\p01\CT.nii';
%       cfg.mask = 'C:\data\p01\mask.nii';
%       [project, work] = ielec.loadCT(cfg, project, work);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also LOADVOLUMEONTOMRI, IELEC.NEWPROJECT, docs/API_LAYER.md.

if ~isfield(project, 'T1') || isempty(project.T1)
    error('ielec:noMRI', ...
        'ielec.loadCT: load an MRI first - every other volume is resliced onto its grid.');
end

defaults.interpolation     = 4;
defaults.maskInterpolation = 1;
cfg = checkCfg(cfg, defaults, {'ct', 'mask'}, 'loadCT');

for f = {'ct', 'mask'}
    if ~ischar(cfg.(f{1}))
        error('ielec:badOption', 'ielec.loadCT: cfg.%s must be a file name.', f{1});
    end
    if ~isfile(cfg.(f{1}))
        error('ielec:noSuchFile', 'ielec.loadCT: no such file: %s', cfg.(f{1}));
    end
end

project.TAC  = loadVolumeOntoMRI('', cfg.ct,   project.T1, cfg.interpolation);
project.mask = loadVolumeOntoMRI('', cfg.mask, project.T1, cfg.maskInterpolation);
project.S2   = project.TAC.vol.mat(1:3,:);

work.maxValue = max(project.TAC.img(:));
work.minValue = min(project.TAC.img(:));
end
