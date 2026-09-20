function [projectable, alreadyDone] = arrayProjectionState(arrays)
%ARRAYPROJECTIONSTATE  Which arrays can be projected, and which already were.
%
%   [projectable, alreadyDone] = arrayProjectionState(arrays)
%
%   Two logical rows, one entry per array in ARRAYS:
%
%     PROJECTABLE   the array is a grid or a strip. Only those are projected
%                   onto the cortical envelope - a depth electrode is inside
%                   the brain already, so there is nothing to correct.
%     ALREADYDONE   the array carries a projection from an earlier run.
%
%   The two are what the SCE checkbox needs before it does anything: whether
%   there is anything to project at all, and whether it should ask the user
%   about recalculating.
%
%   An empty ARRAYS gives two empty results. The loop this replaced left its
%   variable undefined in that case and failed on the next line, but neither
%   caller can reach it with nothing localized.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also SCESURFACEFORSPACE, ELECTRODES2HULLCORRECTION.

projectable = false(1, numel(arrays));
alreadyDone = false(1, numel(arrays));

for i = 1:numel(arrays)
    projectable(i) = strcmp(arrays{i}.Type, 'grid') || strcmp(arrays{i}.Type, 'strip');
    alreadyDone(i) = ~isempty(arrays{i}.projection);
end
end
