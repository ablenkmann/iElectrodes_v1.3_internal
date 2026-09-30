function [project, work, caches] = startSession(project, work, cfg) %#ok<INUSL> project is replaced
%IELEC.STARTSESSION  The three groups of state a session starts with.
%
%   [project, work, caches] = ielec.startSession([], [], cfg) builds the
%   empty project a session begins with, the work that goes with it, and the
%   colour caches that belong to the frontend. It is what the GUI ran on its
%   way up, and what a script needs before it does anything else.
%
%   Options (cfg):
%     cfg.options  the scientific options to start from, as a struct whose
%                  fields override the defaults. [] takes the defaults as
%                  they are - what DEFAULT_IELECTRODES_OPTIONS reads from
%                  the configuration file.                     Default: []
%
%   PROJECT is replaced, so pass []. WORK is kept and filled: whatever the
%   caller already had in it - a path it remembered, an atlas it loaded -
%   survives, and the fields of an empty session are added around it. Pass
%   [] for a session that starts from nothing.
%
%   The three groups are what the restructuring separated:
%
%     project   the patient: images, arrays, surfaces, the parcellation -
%               everything the .iel file holds
%     work      the session: options, the localization in progress, the
%               atlases in memory, what is selected
%     caches    colours derived from the project that only the frontend
%               needs - the parcellation's and the annotations'. They are
%               returned rather than kept in the project, the same way
%               IELEC.OPENPROJECT hands them over, and the frontend keeps
%               them in ui.
%
%   Which field belongs to which group is not decided here:
%   PROJECTFIELDNAMES, WORKFIELDNAMES and UIFIELDNAMES say, and the three
%   lifts move them. This function is the one call that runs all of it in
%   the right order.
%
%   Nothing is drawn and no window is opened. What the GUI does around this
%   - its own display options, its colours, its graphics handles - stays in
%   the frontend.
%
%   Errors: ielec:badOption (cfg.options that is not a struct) and those of
%   the cfg check.
%
%   Example
%       [project, work] = ielec.startSession([], [], []);
%       project.electrodes        % empty - nothing localized yet
%       work.options.image_voxdim
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also CHECKPROJECTSTRUCTURE, LIFTTOPROJECT, LIFTTOWORK, LIFTTOUI,
%            IELEC.SETOPTIONS, IELEC.NEWPROJECT, IELEC.OPENPROJECT.

defaults.options = [];
cfg = checkCfg(cfg, defaults, {}, 'startSession');

if ~isempty(cfg.options) && ~isstruct(cfg.options)
    error('ielec:badOption', ...
        'ielec.startSession: cfg.options must be a struct of options, or [].');
end

if isempty(work)
    work = struct();
end

% the empty structure, then each field into the group it belongs to
state.work = work;
state = checkProjectStructure([], state);
state = liftToProject(state);
state = liftToWork(state);
state = liftToUi(state);

project = state.project;
work    = state.work;
caches  = state.ui;

work.options = default_ielectrodes_options(cfg.options);
end
