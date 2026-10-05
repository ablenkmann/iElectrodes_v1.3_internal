function [project, work, index] = newDepthTarget(cfg, project, work)
%IELEC.NEWDEPTHTARGET  Plan a depth electrode, before surgery.
%
%   [project, work, index] = ielec.newDepthTarget(cfg, project, work) builds
%   a simulated depth electrode - a straight line of contacts between an
%   anatomical target and an entry side - aims it, and puts it in the
%   project's planning targets. INDEX is where it went, which is the one the
%   frontend then shows. WORK is not changed.
%
%   Options (cfg), all of them optional, and all defaulting to what the New
%   target button has always started from:
%     cfg.name           what to call it.                Default: 'Planning'
%     cfg.targetIn       1-by-3, the deep end.           Default: [0 0 0]
%     cfg.targetOut      1-by-3, the entry side.         Default: [45 45 45]
%     cfg.nContacts      how many contacts.              Default: 10
%     cfg.firstSecond    1st contact to 2nd, in mm.      Default: 5
%     cfg.secondLast     every later pair, in mm.        Default: 5
%     cfg.framePosition  'Left', 'Right', 'Anterior' or 'Posterior'.
%                                                        Default: 'Anterior'
%   So ielec.newDepthTarget([], project, work) is the button.
%
%   The contacts are laid out before this returns - IELEC.AIMTARGET, which
%   also gives the array its frame angles - so what comes back is a finished
%   target and not a shell waiting to be aimed. The two ends are a direction
%   and a distance, not a span: the last contact sits
%   firstSecond + (nContacts-2)*secondLast mm from the first, along the line
%   towards cfg.targetOut, which is why .targetOut and the last contact are
%   not the same point.
%
%   A depth target needs no image and no surface - unlike IELEC.NEWTARGET,
%   which lays a grid on the cortical envelope - so it can be planned in an
%   empty project.
%
%   A planned electrode is not a localized one: it goes in project.targets,
%   the list the planning panel shows, and the two are kept apart everywhere,
%   including in the .iel file and the exports. IELEC.NAMECONTACTS with
%   cfg.group 'targets' renames it afterwards.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:badOption (a point that is not three numbers, a count that
%   is not a positive whole number, a spacing that is not one number, an
%   empty name, a frame position that is not one of the four) and those of
%   the cfg check.
%
%   Example
%       cfg = [];
%       cfg.name      = 'LA';
%       cfg.targetIn  = [-24 -12 -18];
%       cfg.targetOut = [-60 -12 -10];
%       cfg.nContacts = 8;
%       [project, work, index] = ielec.newDepthTarget(cfg, project, work);
%       project.targets{index}.ch_label{end}
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.AIMTARGET, IELEC.SETFRAME, IELEC.NEWTARGET,
%            IELEC.NAMECONTACTS, CHECKELECTRODESTRUCTURE.

defaults.name          = 'Planning';
defaults.targetIn      = [0 0 0];
defaults.targetOut     = [45 45 45];
defaults.nContacts     = 10;
defaults.firstSecond   = 5;
defaults.secondLast    = 5;
defaults.framePosition = 'Anterior';
cfg = checkCfg(cfg, defaults, {}, 'newDepthTarget');

for f = {'targetIn', 'targetOut'}
    v = cfg.(f{1});
    if ~isnumeric(v) || numel(v) ~= 3
        error('ielec:badOption', ...
            'ielec.newDepthTarget: cfg.%s must be three numbers, as [x y z].', ...
            f{1});
    end
end
% The two spacings are only measured with, so a degenerate one is let
% through the way a degenerate aim is. The count is not: it indexes 1:n, it
% sizes the adjacency matrix and it is what z(n) reads, so a count that is
% not a positive whole number reaches three backend functions and fails in
% each with a MATLAB: identifier instead of an ielec: one.
for f = {'firstSecond', 'secondLast'}
    v = cfg.(f{1});
    if ~isnumeric(v) || ~isscalar(v)
        error('ielec:badOption', ...
            'ielec.newDepthTarget: cfg.%s must be one number.', f{1});
    end
end
if ~isnumeric(cfg.nContacts) || ~isscalar(cfg.nContacts) || ...
        ~isfinite(cfg.nContacts) || cfg.nContacts < 1 || mod(cfg.nContacts, 1) ~= 0
    error('ielec:badOption', ...
        'ielec.newDepthTarget: cfg.nContacts must be a positive whole number.');
end
if ~ischar(cfg.name) || isempty(cfg.name)
    error('ielec:badOption', ...
        'ielec.newDepthTarget: cfg.name must be a name.');
end
if ~any(strcmp(cfg.framePosition, {'Left', 'Right', 'Anterior', 'Posterior'}))
    error('ielec:badOption', ...
        ['ielec.newDepthTarget: cfg.framePosition must be Left, Right, ' ...
         'Anterior or Posterior.']);
end

% CHECKELECTRODESTRUCTURE first, on nothing but the three names, exactly as
% the button called it: it is what fixes which fields the array has and in
% what order, and it is called before any coordinate exists - so .x comes
% back empty and .nElectrodes zero, and everything below fills them in.
target          = [];
target.Type     = 'depth';
target.Name     = cfg.name;
target.planning = 'yes';
target = checkElectrodeStructure(target);

xi = cfg.targetIn(:)';
xo = cfg.targetOut(:)';
target.targetIn.x  = xi(1);
target.targetIn.y  = xi(2);
target.targetIn.z  = xi(3);
target.targetOut.x = xo(1);
target.targetOut.y = xo(2);
target.targetOut.z = xo(3);

% A depth electrode is one contact wide. The button wrote rows = 10, which
% was the contact count spelled twice.
target.rows    = cfg.nContacts;
target.columns = 1;
target.adjMat  = makeAdjMat(target.rows, target.columns);

target.ch_label = arrayfun(@(k) sprintf('%s %d', cfg.name, k), ...
                           1:cfg.nContacts, 'UniformOutput', false);

target.nElectrodes = cfg.nContacts;
target.FirstSecond = cfg.firstSecond;
target.SecondLast  = cfg.secondLast;

target.framePosition = cfg.framePosition;
target.frameDown     = 0;

[project.targets, index] = addArray(fieldOr(project, 'targets', {}), target);

% and aim it, which lays the contacts out and works out the frame angles
[project, work] = ielec.aimTarget(struct('index', index), project, work);
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end
