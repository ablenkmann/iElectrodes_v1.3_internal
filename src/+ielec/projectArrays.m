function [project, work] = projectArrays(cfg, project, work)
%IELEC.PROJECTARRAYS  Compensate the brain shift: project the arrays to the envelope.
%
%   [project, work] = ielec.projectArrays(cfg, project, work) projects the
%   grids and strips onto the smooth cortical envelope and corrects the
%   depth electrodes with them, and stores the result in each array's
%   .projection. WORK is not changed.
%
%   Options (cfg):
%     cfg.space           'Native' or 'MNI', which envelope to project onto.
%                         Default: project.currentSpace.
%     cfg.recalculateAll  redo the arrays that already have a projection as
%                         well as the new ones.             Default: false
%
%   A craniotomy lets the brain move, so a grid localized on the CT sits
%   above the cortex it was on. The correction moves each contact back onto
%   the envelope (ELECTRODES2HULLCORRECTION); a depth electrode is not
%   projected but corrected, by interpolating the displacement of the
%   surface arrays around it.
%
%   Nothing happens when every array already has a projection, as before -
%   which includes the depth electrodes, so adding one after a projection
%   makes the next call redo the correction for it.
%
%   Nothing is drawn and no window is opened. The question of whether to
%   redo existing projections is the frontend's - IELEC.PROJECTIONSTATE
%   says what there is to ask about.
%
%   Errors: ielec:noArraysToProject (no grid or strip in the project),
%   ielec:noSurface (no smooth cortical envelope in this space),
%   ielec:badOption, and those of the cfg check.
%
%   Example
%       [project, work] = ielec.projectArrays([], project, work);
%       project.electrodes{1}.projection
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ELECTRODES2HULLCORRECTION, IELEC.PROJECTIONSTATE, ENVELOPEFOR.

defaults.space          = '';
defaults.recalculateAll = false;
defaults.method         = '';
cfg   = checkCfg(cfg, defaults, {}, 'projectArrays');
space = resolveSpace(cfg.space, project, 'projectArrays');

% Which way the contacts are carried onto the envelope. Different methods
% put a contact in different places, so it is the call's to choose and is
% recorded with the step - item 51. Only a value the caller gives is
% checked; the session's goes through as it always did.
if ~isempty(cfg.method)
    cfg.method = char(cfg.method);
    known = {'CEPA', 'closestPoint', 'springs', 'normal', 'normal-SCE', ...
             'realistic'};
    if ~ismember(cfg.method, known)
        error('ielec:badOption', ...
            'ielec.projectArrays: cfg.method is one of: %s.', ...
            strjoin(known, ', '));
    end
else
    cfg.method = fieldOr(work.options, 'SCE_projection_method', 'CEPA');
end

arrays = fieldOr(project, 'electrodes', {});
[projectable, alreadyDone] = arrayProjectionState(arrays);

if ~any(projectable)
    error('ielec:noArraysToProject', ...
        ['ielec.projectArrays: there is no grid or strip to project. ' ...
         'Localize one first.']);
end

if cfg.recalculateAll
    alreadyDone = false(size(alreadyDone));
end
if all(alreadyDone)
    return       % every array is projected already
end

[vertices, faces] = envelopeFor(space, project, work);
if isempty(vertices)
    error('ielec:noSurface', ...
        ['ielec.projectArrays: there is no smooth cortical envelope in %s space. ' ...
         'Load or generate one first.'], space);
end

projectOptions = work.options;
projectOptions.SCE_projection_method = cfg.method;

project.electrodes = electrodes2hullCorrection(arrays, vertices, faces, ...
                                               projectOptions, alreadyDone);

project = recordStep(project, mfilename, cfg);
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end
