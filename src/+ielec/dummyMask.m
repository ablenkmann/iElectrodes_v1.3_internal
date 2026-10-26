function [project, work] = dummyMask(cfg, project, work)
%IELEC.DUMMYMASK  A brain mask that selects every voxel.
%
%   [project, work] = ielec.dummyMask(cfg, project, work) puts a mask of ones
%   in the project, on the MRI's grid, so that a CT can be thresholded by
%   someone who has no mask to hand. WORK is returned unchanged.
%
%   Options (cfg): none.
%
%   WHAT IT IS FOR, AND WHAT IT COSTS
%
%   The mask decides which voxels IELEC.THRESHOLDCT may select. Without one
%   there is nothing to threshold at all, which turns "I have not made a mask
%   yet" into "I cannot look at my CT" - and a mask is not always ready when
%   the images are.
%
%   A mask of ones removes the restriction rather than meeting it. Bone is
%   brighter than an electrode, so a threshold over the whole head returns
%   the skull along with the contacts, and the brushing step then has to
%   throw away a skull instead of a few stray voxels. It makes the CT usable;
%   it does not make a real mask unnecessary.
%
%   It is recorded in the project's history like any other step, so a project
%   thresholded this way says so.
%
%   THE SIZE OF THE CT, WHICH IS THE SIZE OF THE MRI
%
%   Every volume in a project is resliced onto the MRI's grid when it is
%   loaded, the CT included, so the two are the same size and this can be
%   built from the MRI alone. That is deliberate: it works before a CT is
%   loaded as well as after, and nothing has to be done in a particular
%   order.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:noMRI (load an MRI first), and those of the cfg check.
%
%   Example
%       [project, work] = ielec.loadCT(struct('ct', ctFile), project, work);
%       [project, work] = ielec.dummyMask([], project, work);
%       [project, work] = ielec.thresholdCT(cfg, project, work);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.LOADMASK, IELEC.LOADCT, IELEC.THRESHOLDCT,
%   docs/API_LAYER.md.

if ~isfield(project, 'T1') || isempty(project.T1)
    error('ielec:noMRI', ...
        'ielec.dummyMask: load an MRI first - the mask is built on its grid.');
end

cfg = checkCfg(cfg, struct(), {}, 'dummyMask');

% The MRI's own structure, so the grid and the image-to-world transformation
% are the ones every other volume in the project is on. uint8 because the
% only thing done with a mask is logical(mask.img), and ones as uint8 are a
% quarter of the memory of the single the MRI is likely to be in.
project.mask     = project.T1;
project.mask.img = ones(size(project.T1.img), 'uint8');

% and its own name, not the MRI's. checkProjectStructure has the same copy
% in its old-mask branch and sets the name one level too high, which is
% docs/OPEN_QUESTIONS.md item 33.
if isfield(project.mask, 'vol') && isstruct(project.mask.vol)
    project.mask.vol.fname = 'dummyMask.nii';
end

project = recordStep(project, mfilename, cfg);
end
