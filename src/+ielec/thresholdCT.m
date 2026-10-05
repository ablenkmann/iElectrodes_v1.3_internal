function [project, work] = thresholdCT(cfg, project, work)
%IELEC.THRESHOLDCT  The CT voxels bright enough to be contacts.
%
%   [project, work] = ielec.thresholdCT(cfg, project, work) finds the voxels
%   of the CT between two intensities and inside the brain mask, and puts
%   them in work as the voxels on offer for selection:
%
%     work.candidateVoxels   N x 3, their anatomical coordinates
%     work.candidateValues   N x 1, how bright each one is
%
%   PROJECT is not changed. What the user then picks out of these is
%   IELEC.SELECTVOXELS; any earlier selection is cleared, because it refers
%   to voxels that are no longer on offer.
%
%   Options (cfg):
%     cfg.lowThreshold    lower intensity, in the CT's own units. required
%     cfg.highThreshold   upper intensity, the same.             required
%     cfg.denoiseKernel   erode then dilate with a cube this many voxels
%                         wide before thresholding; 1 is off.   Default: 1
%     cfg.maxCount        keep at most this many voxels, chosen at random,
%                         and warn. [] keeps all of them.      Default: []
%     cfg.excludeLocalized  leave out the voxels of the arrays already
%                         localized in the project.         Default: false
%
%   The thresholds are intensities, not slider positions: what a control
%   shows is the frontend's business, and a recorded threshold has to mean
%   the same thing without it.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:noCT (no CT or no mask), and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.lowThreshold  = 2500;
%       cfg.highThreshold = 4000;
%       [project, work] = ielec.thresholdCT(cfg, project, work);
%       size(work.candidateVoxels, 1)
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also THRESHOLDCTVOXELS, IELEC.SELECTVOXELS, IELEC.LOADCT.

if ~isfield(project, 'TAC') || isempty(project.TAC) || ...
        ~isfield(project, 'mask') || isempty(project.mask)
    error('ielec:noCT', ...
        'ielec.thresholdCT: load a CT and a brain mask first (ielec.loadCT).');
end

defaults.denoiseKernel    = 1;
defaults.maxCount         = [];
defaults.excludeLocalized = false;
cfg = checkCfg(cfg, defaults, {'lowThreshold', 'highThreshold'}, 'thresholdCT');

opt.lowThreshold  = cfg.lowThreshold;
opt.highThreshold = cfg.highThreshold;
opt.denoiseKernel = cfg.denoiseKernel;
if ~isempty(cfg.maxCount)
    opt.maxCount = cfg.maxCount;
end

opt.excludeCoordinates = [];
if cfg.excludeLocalized
    for j = 1:numel(project.electrodes)
        opt.excludeCoordinates = [opt.excludeCoordinates; project.electrodes{j}.brushCrd]; %#ok<AGROW>
    end
end

[work.candidateVoxels, work.candidateValues] = ...
    thresholdCTVoxels(project.TAC, project.mask, project.S2, opt);

% a selection made from the previous voxels means nothing now
work.selectedVoxels  = [];
work.selectedWeights = [];
end
