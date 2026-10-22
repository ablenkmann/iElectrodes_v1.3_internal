function [project, work] = loadCT(cfg, project, work)
%IELEC.LOADCT  Add the CT to a project.
%
%   [project, work] = ielec.loadCT(cfg, project, work) reads the CT named in
%   cfg.ct, reslices it onto the MRI's grid, and puts it in the project as
%   project.TAC. WORK gets the CT's intensity limits, which a threshold
%   control works from.
%
%   Options (cfg):
%     cfg.ct             path of the CT, a NIfTI file.               required
%     cfg.interpolation  interpolation, as SPM numbers it.         Default: 4
%
%   The CT must already be coregistered to the MRI: it is resliced onto the
%   MRI's grid, not registered to it.
%
%   project.S2, the image-to-world transformation, is taken from the CT
%   after reslicing, as the Load CT button did.
%
%   THE MASK IS IELEC.LOADMASK
%
%   This used to read the brain mask as well, because nothing can be
%   thresholded without one and the button asked for both. They are two
%   files, two reslicings and two project fields, so they are two functions:
%   a caller that already has a mask should not have to name one again to
%   replace a CT.
%
%   Either order works - both are resliced onto the MRI and neither looks at
%   the other - and IELEC.THRESHOLDCT refuses until both are there, naming
%   the one that is missing. A frontend that wants the old all-or-nothing
%   behaviour asks for both files before it calls either function, which is
%   what the Load CT button does; see docs/OPEN_QUESTIONS.md item 26.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:noMRI (load an MRI first), ielec:noSuchFile, and those of
%   the cfg check.
%
%   Example
%       cfg = [];
%       cfg.ct = 'C:\data\p01\CT.nii';
%       [project, work] = ielec.loadCT(cfg, project, work);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.LOADMASK, LOADVOLUMEONTOMRI, IELEC.NEWPROJECT,
%   docs/API_LAYER.md.

if ~isfield(project, 'T1') || isempty(project.T1)
    error('ielec:noMRI', ...
        'ielec.loadCT: load an MRI first - every other volume is resliced onto its grid.');
end

defaults.interpolation = 4;
cfg = checkCfg(cfg, defaults, {'ct'}, 'loadCT');

if ~ischar(cfg.ct)
    error('ielec:badOption', 'ielec.loadCT: cfg.ct must be a file name.');
end
if ~isfile(cfg.ct)
    error('ielec:noSuchFile', 'ielec.loadCT: no such file: %s', cfg.ct);
end

project.TAC = loadVolumeOntoMRI('', cfg.ct, project.T1, cfg.interpolation);
project.S2  = project.TAC.vol.mat(1:3,:);

work.maxValue = max(project.TAC.img(:));
work.minValue = min(project.TAC.img(:));

project = recordStep(project, mfilename, cfg);
end
