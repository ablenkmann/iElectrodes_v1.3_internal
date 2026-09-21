function [projectable, alreadyDone] = arrayProjectionState(arrays)
%ARRAYPROJECTIONSTATE  Which arrays can be projected, and which already were.
%
%   [projectable, alreadyDone] = arrayProjectionState(arrays)
%
%   Two logical rows, one entry per array in ARRAYS:
%
%     PROJECTABLE   the array is a grid or a strip - one that sits on the
%                   brain surface and can be projected onto the cortical
%                   envelope.
%     ALREADYDONE   the array carries a projection from an earlier run.
%
%   Depth electrodes are corrected too, but not by projection. The brain-shift
%   correction projects the grids and strips onto the envelope, measures how
%   far each surface contact moved, and then moves every depth contact by a
%   distance-weighted interpolation of those surface displacements (see
%   ELECTRODES2HULLCORRECTION). So the surface arrays are where the
%   correction comes from, and a project with none of them has nothing to
%   derive it from. That - not that depth electrodes need no correcting - is
%   why the SCE checkbox refuses when PROJECTABLE is all false.
%
%   The two outputs are what the checkbox needs before it does anything:
%   whether a correction can be computed at all, and whether it should ask
%   the user about recalculating.
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
