function [project, work] = placeTarget(cfg, project, work)
%IELEC.PLACETARGET  Move or turn a planned grid on the brain.
%
%   [project, work] = ielec.placeTarget(cfg, project, work) lays one of the
%   project's planning targets down again at a new place on the smooth
%   cortical envelope, or turns it where it is. WORK is not changed.
%
%   Options (cfg):
%     cfg.index     which target. Required.
%     cfg.centre    1-by-3, where its centre should go. Use this or
%                   cfg.offset, not both.                      Default: []
%     cfg.offset    1-by-3 in mm, added to the centre it has now - which is
%                   what the six arrow buttons do.             Default: []
%     cfg.rotation  an extra turn about the centre, in degrees. [] is no
%                   turn at all, which is not the same as 0: with [] the
%                   rotation step is skipped, and that is what the buttons
%                   have always done.                          Default: []
%
%   The three ways the planning panel uses it are the three ways it can be
%   called: the arrow buttons give cfg.offset, the rotate buttons give
%   cfg.offset [0 0 0] and a cfg.rotation, and "change centre" gives
%   cfg.centre.
%
%   The grid is laid down afresh rather than shifted, so its contacts follow
%   the curvature of the surface where it lands. Anything computed from the
%   old position no longer holds: the hemisphere is worked out again and the
%   projection is cleared, as PLACEPLANNINGGRID has always done.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:noSurfaces (no envelope to lay it on), ielec:badOption
%   (an index that is not one of the targets, both or neither of centre and
%   offset, a rotation that is not one number) and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.index  = 1;
%       cfg.offset = [0 0 1];          % 1 mm superior
%       [project, work] = ielec.placeTarget(cfg, project, work);
%
%       cfg.offset = [0 0 0];  cfg.rotation = 5;
%       [project, work] = ielec.placeTarget(cfg, project, work);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also PLACEPLANNINGGRID, TANGENTIALGRID, IELEC.NEWTARGET.

defaults.centre   = [];
defaults.offset   = [];
defaults.rotation = [];
cfg = checkCfg(cfg, defaults, {'index'}, 'placeTarget');

targets = fieldOr(project, 'targets', {});
if ~isnumeric(cfg.index) || ~isscalar(cfg.index) || mod(cfg.index, 1) ~= 0 || ...
        cfg.index < 1 || cfg.index > numel(targets)
    error('ielec:badOption', ...
        'ielec.placeTarget: cfg.index must be one of the %d planning targets.', ...
        numel(targets));
end
target = targets{cfg.index};

if isempty(cfg.centre) == isempty(cfg.offset)
    error('ielec:badOption', ...
        ['ielec.placeTarget: say where it goes with cfg.centre, or how far ' ...
         'to move it with cfg.offset - one of the two.']);
end
for f = {'centre', 'offset'}
    v = cfg.(f{1});
    if ~isempty(v) && (~isnumeric(v) || ~isequal(size(v), [1 3]) || ~all(isfinite(v)))
        error('ielec:badOption', ...
            'ielec.placeTarget: cfg.%s must be three numbers, as [x y z].', f{1});
    end
end
if ~isempty(cfg.rotation) && (~isnumeric(cfg.rotation) || ...
        ~isscalar(cfg.rotation) || ~isfinite(cfg.rotation))
    error('ielec:badOption', ...
        'ielec.placeTarget: cfg.rotation must be an angle in degrees, or [].');
end

% the right envelope is the one TANGENTIALGRID needs - see IELEC.NEWTARGET
if isempty(fieldOr(project, 'vertices_SCE_R', []))
    error('ielec:noSurfaces', ...
        ['ielec.placeTarget: a planning grid is laid on the smooth cortical ' ...
         'envelope, and this project has none.']);
end

if ~isempty(cfg.offset)
    centre = mean([target.x target.y target.z]) + cfg.offset;
else
    centre = cfg.centre;
end

project.targets{cfg.index} = placePlanningGrid(target, centre, cfg.rotation, ...
    project.vertices_SCE_L, project.vertices_SCE_R);

project = recordStep(project, mfilename, cfg);
end

function value = fieldOr(s, name, default)
if isfield(s, name), value = s.(name); else, value = default; end
end
