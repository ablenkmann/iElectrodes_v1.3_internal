function [project, work] = fitTarget(cfg, project, work)
%IELEC.FITTARGET  Press a planned grid onto the cortical envelope.
%
%   [project, work] = ielec.fitTarget(cfg, project, work) fits one of the
%   project's planning grids to the smooth cortical envelope and stores the
%   result in that target's .projection. WORK is not changed.
%
%   Options (cfg):
%     cfg.index   which planning target. Required.
%
%   IELEC.NEWTARGET lays a grid tangent to the envelope: flat, touching it
%   at one point. This is the other half of planning one. The contacts are
%   pulled onto the surface and held at their spacing by the springs of
%   Dykstra et al. 2012, so a grid planned across a sulcus follows it
%   instead of floating over it.
%
%   Two settings are not the ones the project works with, exactly as in the
%   button: the method is always 'springs' rather than the CEPA default, and
%   the springs are the planning ones, options.SCE_springs_projection_planning.
%   Those differ from the localization springs in one setting that matters -
%   meshReduceL is 100 mm rather than 20, so a larger piece of the envelope is
%   kept and the fit is slower, not coarser - and in RefineMesh, which nothing
%   reads any more (the refinepatch block in PROJECTION2MESH is commented out).
%   Neither is written back into work.options.
%
%   The envelope is the patient's own, both hemispheres merged, whatever
%   space the project is being worked in. That is what the button has always
%   done, and it differs from IELEC.PROJECTARRAYS, which follows
%   project.currentSpace - see docs/OPEN_QUESTIONS.md item 34.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:noSurfaces (no envelope to fit it to), ielec:badOption (an
%   index that is not one of the targets) and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.index = 1;
%       [project, work] = ielec.fitTarget(cfg, project, work);
%       project.targets{1}.projection{1}.displacement
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   Options (cfg):
%     cfg.index    which planning target to fit.                   required
%     cfg.springs  a struct of springs settings to change for this call,
%                  merged over work.options.SCE_springs_projection_planning
%                  field by field - struct('meshReduceL', 60) changes one
%                  and leaves the rest.
%                  Default: the session's planning springs, unchanged
%
%   The springs decide where the contacts come to rest, so they are the
%   call's to set and the merged set is recorded with the step. They used to
%   be read out of work.options where they were used, so the project could
%   not say which settings had produced the fit it holds - see
%   docs/OPEN_QUESTIONS.md item 51.
%
%   See also ELECTRODES2HULLCORRECTION, IELEC.NEWTARGET, IELEC.PLACETARGET,
%            IELEC.PROJECTARRAYS.

cfg = checkCfg(cfg, struct('springs', []), {'index'}, 'fitTarget');

targets = fieldOr(project, 'targets', {});
if ~isnumeric(cfg.index) || ~isscalar(cfg.index) || mod(cfg.index, 1) ~= 0 || ...
        cfg.index < 1 || cfg.index > numel(targets)
    error('ielec:badOption', ...
        'ielec.fitTarget: cfg.index must be one of the %d planning targets.', ...
        numel(targets));
end
target = targets{cfg.index};

% A depth target is not refused here. ELECTRODES2HULLCORRECTION warns
% ("no grid electrodes to do projection") and gives the array back unchanged,
% and that is reachable from the panel - the Grids radio shows the Grids panel
% without changing which array is selected. Refusing it would turn a warning
% into an error on a path a user can reach, so the warning stays the backend's
% to give. See docs/OPEN_QUESTIONS.md item 36.

% The patient's own envelope, both hemispheres merged - ENVELOPEFOR's Native
% branch is the MERGEMESH call the button made itself. 'Native' is written
% here rather than taken from project.currentSpace because that is the
% button's behaviour; see docs/OPEN_QUESTIONS.md item 34.
%
% Alejandro's question about this merge, from the button:
%   SPLIT LEFT AND RIGHT ???
% i.e. whether a grid should be fitted to the hemisphere it is on instead of
% to both at once. Open.
[vertices, faces] = envelopeFor('Native', project, work);
if isempty(vertices)
    error('ielec:noSurfaces', ...
        ['ielec.fitTarget: a planning grid is fitted to the smooth cortical ' ...
         'envelope, and this project has none. Build or load one first ' ...
         '(ielec.buildEnvelope, ielec.loadSurfaces).']);
end

% The planning settings, for this call only. The springs decide where the
% contacts come to rest, so they travel in cfg and are recorded with the
% step - docs/OPEN_QUESTIONS.md item 51. What the caller gives is merged
% over the session's planning springs, field by field, so a call can change
% one of them without naming the rest; the merged set is written back into
% cfg, which is what RECORDSTEP writes.
base = fieldOr(work.options, 'SCE_springs_projection_planning', struct());
if ~isempty(cfg.springs)
    if ~isstruct(cfg.springs) || ~isscalar(cfg.springs)
        error('ielec:badOption', ...
            ['ielec.fitTarget: cfg.springs is a struct of settings to ' ...
             'change, such as struct(''meshReduceL'', 60).']);
    end
    unknown = setdiff(fieldnames(cfg.springs), fieldnames(base));
    if ~isempty(unknown)
        error('ielec:badOption', ...
            'ielec.fitTarget: cfg.springs has no setting called ''%s''.', ...
            unknown{1});
    end
    for f = fieldnames(cfg.springs)'
        base.(f{1}) = cfg.springs.(f{1});
    end
end
cfg.springs = base;

options = work.options;
options.SCE_projection_method  = 'springs';
options.SCE_springs_projection = cfg.springs;

fitted = electrodes2hullCorrection({target}, vertices, faces, options);

project.targets{cfg.index} = fitted{1};

project = recordStep(project, mfilename, cfg);
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end
