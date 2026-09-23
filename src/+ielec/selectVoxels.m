function [project, work] = selectVoxels(project, work, cfg)
%IELEC.SELECTVOXELS  Choose some of the voxels on offer, and weigh them.
%
%   [project, work] = ielec.selectVoxels(project, work, cfg) takes the
%   voxels cfg.indices picks out of work.candidateVoxels and puts them in
%   work as the selection to work from:
%
%     work.selectedVoxels    M x 3, their anatomical coordinates
%     work.selectedWeights   M x 1, the CT intensity of each, minus the
%                            lowest in the CT - the weight clustering and
%                            GridFit give it
%
%   PROJECT is not changed.
%
%   Options (cfg):
%     cfg.indices   which of the candidate voxels are selected: a logical
%                   array as long as them, or a list of positions. required
%
%   Which voxels the user picked is the frontend's input - in the GUI it
%   comes from brushing the 3-D plot. What they are is data, and it belongs
%   in work, which is why the picking and the weighing are separated here:
%   nothing downstream has to read coordinates back out of a plot.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:noVoxels (nothing to select from - threshold first),
%   ielec:badSelection, and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.indices = brushed;              % logical, from the 3-D view
%       [project, work] = ielec.selectVoxels(project, work, cfg);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.THRESHOLDCT, IELEC.CLUSTER, VOXELWEIGHTS.

cfg = checkCfg(cfg, struct(), {'indices'}, 'selectVoxels');

if ~isfield(work, 'candidateVoxels') || isempty(work.candidateVoxels)
    error('ielec:noVoxels', ...
        'ielec.selectVoxels: there are no voxels to select from - threshold the CT first.');
end

candidates = work.candidateVoxels;
idx        = cfg.indices;

if islogical(idx)
    if numel(idx) ~= size(candidates, 1)
        error('ielec:badSelection', ...
            ['ielec.selectVoxels: the selection is %d long and there are %d voxels. ' ...
             'It belongs to an older set of voxels; select again.'], ...
            numel(idx), size(candidates, 1));
    end
else
    if ~isnumeric(idx) || any(idx(:) < 1) || any(idx(:) > size(candidates, 1)) || ...
            any(mod(idx(:), 1) ~= 0)
        error('ielec:badSelection', ...
            'ielec.selectVoxels: cfg.indices must be a logical array or positions in 1..%d.', ...
            size(candidates, 1));
    end
end

work.selectedVoxels  = candidates(idx, :);
work.selectedWeights = voxelWeights(project.TAC, project.S2, work.selectedVoxels);
end
