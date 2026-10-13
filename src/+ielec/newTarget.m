function [project, work, index] = newTarget(cfg, project, work)
%IELEC.NEWTARGET  Plan a grid on the brain, before surgery.
%
%   [project, work, index] = ielec.newTarget(cfg, project, work) builds a
%   simulated subdural grid, lays it on the smooth cortical envelope with its
%   centre where it is told, and puts it in the project's planning targets.
%   INDEX is where it went, which is the one the frontend then shows. WORK is
%   not changed.
%
%   Options (cfg):
%     cfg.centre   1-by-3, where the centre of the grid should go - the
%                  cursor, when the button is pressed. Required.
%     cfg.rows     rows of contacts. Required.
%     cfg.columns  contacts per row. Required.
%     cfg.spacing  distance between neighbouring contacts, in mm. Required.
%
%   The grid is laid tangent to the envelope, so it needs one: a project
%   with no envelope is refused. It comes back named 'grid', its contacts
%   'grid1', 'grid2', ..., and its rotation at 0 - TANGENTIALGRID chooses
%   the orientation, there being no previous grid to keep one from.
%   IELEC.NAMECONTACTS with cfg.group 'targets' renames it.
%
%   A planned grid is not a localized one: it goes in project.targets, which
%   is the list the planning panel shows, and the two are kept apart
%   everywhere - including in the .iel file and the exports.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:noSurfaces (no envelope to lay it on), ielec:badOption
%   (a centre that is not three coordinates, a size that is not whole
%   numbers, a spacing that is not a distance) and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.centre  = [-54 -22 12];
%       cfg.rows    = 4;   cfg.columns = 5;   cfg.spacing = 10;
%       [project, work, index] = ielec.newTarget(cfg, project, work);
%       project.targets{index}.Name
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also NEWPLANNINGGRID, TANGENTIALGRID, IELEC.PLACETARGET,
%            IELEC.BUILDENVELOPE, IELEC.NAMECONTACTS.

cfg = checkCfg(cfg, struct(), {'centre', 'rows', 'columns', 'spacing'}, 'newTarget');

if ~isnumeric(cfg.centre) || ~isequal(size(cfg.centre), [1 3]) || ...
        ~all(isfinite(cfg.centre))
    error('ielec:badOption', ...
        'ielec.newTarget: cfg.centre must be one point, as [x y z].');
end
for f = {'rows', 'columns'}
    v = cfg.(f{1});
    if ~isnumeric(v) || ~isscalar(v) || ~isfinite(v) || v < 1 || mod(v, 1) ~= 0
        error('ielec:badOption', ...
            'ielec.newTarget: cfg.%s must be a positive whole number.', f{1});
    end
end
if ~isnumeric(cfg.spacing) || ~isscalar(cfg.spacing) || ...
        ~isfinite(cfg.spacing) || cfg.spacing <= 0
    error('ielec:badOption', ...
        'ielec.newTarget: cfg.spacing must be a distance in mm.');
end

% TANGENTIALGRID is given both hemispheres and picks the nearer one, but it
% reaches for the right one when neither is near, so the right envelope is
% the one that has to be there. That is the check the button makes too.
if isempty(fieldOr(project, 'vertices_SCE_R', []))
    error('ielec:noSurfaces', ...
        ['ielec.newTarget: a planning grid is laid on the smooth cortical ' ...
         'envelope, and this project has none. Build or load one first ' ...
         '(ielec.buildEnvelope, ielec.loadSurfaces).']);
end

target = newPlanningGrid(cfg.centre, cfg.rows, cfg.columns, cfg.spacing, ...
                         project.vertices_SCE_L, project.vertices_SCE_R);

[project.targets, index] = addArray(project.targets, target);

project = recordStep(project, mfilename, cfg);
end

function value = fieldOr(s, name, default)
if isfield(s, name), value = s.(name); else, value = default; end
end
