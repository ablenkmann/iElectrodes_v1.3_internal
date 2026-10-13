function [project, work] = setFrame(cfg, project, work)
%IELEC.SETFRAME  The stereotactic frame angles of a planned depth electrode.
%
%   [project, work] = ielec.setFrame(cfg, project, work) works out the two
%   angles a stereotactic frame would be set to in order to drive the planned
%   electrode along the trajectory it already has, and stores them with the
%   target. WORK is not changed.
%
%   Options (cfg):
%     cfg.index          which planning target. Required.
%     cfg.framePosition  how the frame is mounted: 'Left', 'Right',
%                        'Anterior' or 'Posterior'. Default: '', meaning
%                        leave the target's own, and do not write it back.
%
%   This is the frame half of planning a depth electrode, and it is kept
%   apart from the trajectory half on purpose. It reads .delta and the z of
%   the last contact and writes .alpha, .beta and .frameDown; it does not
%   touch .x, .y, .z or the two ends. So changing how the frame is mounted
%   cannot move a single contact - which matters for a project saved by an
%   older version, whose stored coordinates need not agree with what its
%   ends and spacings would produce today.
%
%   FRAMEDOWN is not an option: TRAJECTORYFRAMEANGLES decides it, by the
%   rule that the frame points down when the last contact lies below z = 0.
%
%   The angles are stored at full precision. Rounding them is display, and
%   belongs to whoever shows them.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:badOption (an index that is not one of the targets, a
%   frame position that is not one of the four, or a target with no
%   trajectory to read the angles from) and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.index         = 1;
%       cfg.framePosition = 'Anterior';
%       [project, work] = ielec.setFrame(cfg, project, work);
%       [project.targets{1}.alpha project.targets{1}.beta]
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also TRAJECTORYFRAMEANGLES, DELTA2ALPHA_BETA, IELEC.NEWTARGET.

defaults.framePosition = '';
cfg = checkCfg(cfg, defaults, {'index'}, 'setFrame');

targets = fieldOr(project, 'targets', {});
if ~isnumeric(cfg.index) || ~isscalar(cfg.index) || mod(cfg.index, 1) ~= 0 || ...
        cfg.index < 1 || cfg.index > numel(targets)
    error('ielec:badOption', ...
        'ielec.setFrame: cfg.index must be one of the %d planning targets.', ...
        numel(targets));
end
target = targets{cfg.index};

framePosition = cfg.framePosition;
if isempty(framePosition)
    framePosition = fieldOr(target, 'framePosition', '');
end
if ~any(strcmp(framePosition, {'Left', 'Right', 'Anterior', 'Posterior'}))
    error('ielec:badOption', ...
        ['ielec.setFrame: cfg.framePosition must be Left, Right, Anterior ' ...
         'or Posterior. Target %d has ''%s''.'], cfg.index, framePosition);
end

% The angles are read from .delta. A planned grid has none -
% CHECKELECTRODESTRUCTURE creates the depth fields only for a depth array -
% and before this the call said "Unrecognized field name delta". The panel
% can show the Depth boxes with a grid selected (docs/OPEN_QUESTIONS.md
% item 36), so that is reachable; it is an error either way, and now it says
% which. The Type is deliberately NOT checked: a target that carries a
% trajectory gets its angles computed whatever its Type says, which is what
% ESTIMATEANGLESFRAME did.
delta = fieldOr(target, 'delta', []);
if numel(delta) < 3
    error('ielec:badOption', ...
        ['ielec.setFrame: target %d has no trajectory to read the frame ' ...
         'angles from. A planned grid has none; a depth electrode has one ' ...
         'once it has been aimed.'], cfg.index);
end

% z(n) is left to index exactly as it did in the GUI, rather than guarded:
% an nElectrodes past the end of z errors there as it always has, and an
% empty one gives an empty last-contact z, from which DELTA2ALPHA_BETA
% computes the angles with the frame up. Both are states only a file can be
% in, and both are reproduced rather than refused.
n = fieldOr(target, 'nElectrodes', []);
z = fieldOr(target, 'z', []);

[alpha, beta, frameDown] = trajectoryFrameAngles(delta, z(n), framePosition);

% Only a frame position that was asked for is written back. ESTIMATEANGLESFRAME
% never wrote one: its callers had already put theirs in the project.
if ~isempty(cfg.framePosition)
    project.targets{cfg.index}.framePosition = framePosition;
end
project.targets{cfg.index}.frameDown = frameDown;
project.targets{cfg.index}.beta      = beta;
project.targets{cfg.index}.alpha     = alpha;

project = recordStep(project, mfilename, cfg);
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end
