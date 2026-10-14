function [project, work, array] = fitArray(cfg, project, work)
%IELEC.FITARRAY  Fit an electrode array to the selected voxels.
%
%   [project, work, array] = ielec.fitArray(cfg, project, work) fits a grid,
%   a strip or a depth electrode of the given size and spacing to the voxels
%   in work.selectedVoxels, and returns the array it found.
%
%   Options (cfg):
%     cfg.type       'grid', 'strip' or 'depth'.                   required
%     cfg.rows       rows of contacts; 1 for a strip or a depth.   required
%     cfg.columns    contacts per row.                             required
%     cfg.spacing    distance between neighbouring contacts, in mm. For a
%                    depth electrode, between the second contact and the
%                    ones after it.                                required
%     cfg.firstSecondSpacing   depth electrodes only: between the first and
%                    second contact, which differs on a Behnke-Fried
%                    electrode. [] means the same as cfg.spacing. Default: []
%     cfg.overlap    1 when the array overlaps itself, 0 when it does
%                    not. Not used for a depth.                  Default: 0
%     cfg.useNailedContacts   hold the fit to the anchors already in
%                    work.anchors.                           Default: false
%     cfg.nailNumbers  which contact of the array each of those is - what
%                    the Fit button's table asks for. NaN for one that is
%                    not assigned, and [] for none assigned at all, which
%                    records them with the array without holding the fit to
%                    them, as the button did.                   Default: []
%
%   The array is returned rather than put in the project: it is a proposal
%   until it is accepted, and the caller may still name it or throw it away.
%
%   WORK. When nailed contacts are used, the anchors in work.anchors are
%   what they are, so they are consumed: work.anchors is emptied and the
%   previous values are kept in work.oldanchors and the other old fields, so
%   that Undo restores them.
%
%   The contacts in progress are NOT touched, and that is a change from what
%   the Fit button did. The anchors used to be work.GS, so clustering and
%   then fitting held the fit to the clustered contacts; the two lists are
%   separate now, work.GS belongs to the indexing step, and a fit is held
%   only by points placed by hand as anchors. That is Alejandro's answer,
%   recorded in docs/OPEN_QUESTIONS.md item 40.
%
%   The name. The algorithm itself is GRIDFIT, in src/localization/. A
%   function inside the package must not call a plain function of its own
%   name (docs/API_LAYER.md rule 6), so this one is called after what it
%   does for the user: it fits an array.
%
%   The fit is what GRIDFIT does: it pulls a model of the array towards the
%   CT voxels while keeping its shape. The settings for the type come from
%   work.options (GRIDFITOPTIONS), and the attraction to the voxels from
%   KC_OPTIMAL. It can take minutes for a large grid.
%
%   Nothing is drawn and no window is opened. The dialogs that ask for the
%   size, the spacing and the nailed contacts stay in the frontend.
%
%   Errors: ielec:noSelection, ielec:badOption, and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.type = 'depth';  cfg.rows = 1;  cfg.columns = 10;
%       cfg.spacing = 3.5;   cfg.firstSecondSpacing = 3.5;
%       [project, work, array] = ielec.fitArray(cfg, project, work);
%       array.nElectrodes
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also GRIDFIT, GRIDFITOPTIONS, ELECTRODEFROMGRIDFIT, IELEC.SELECTVOXELS.

defaults.firstSecondSpacing = [];
defaults.overlap            = 0;
defaults.useNailedContacts  = false;
defaults.nailNumbers        = [];
cfg = checkCfg(cfg, defaults, {'type', 'rows', 'columns', 'spacing'}, 'fitArray');

if ~isfield(work, 'selectedVoxels') || isempty(work.selectedVoxels) || ...
        ~isfield(work, 'selectedWeights') || isempty(work.selectedWeights)
    error('ielec:noSelection', ...
        'ielec.fitArray: select some voxels first (ielec.selectVoxels).');
end
if ~ischar(cfg.type) || ~ismember(cfg.type, {'grid', 'strip', 'depth'})
    error('ielec:badOption', ...
        'ielec.fitArray: cfg.type must be ''grid'', ''strip'' or ''depth'', not ''%s''.', ...
        char(string(cfg.type)));
end
for f = {'rows', 'columns'}
    v = cfg.(f{1});
    if ~isnumeric(v) || ~isscalar(v) || v < 1 || mod(v, 1) ~= 0
        error('ielec:badOption', ...
            'ielec.fitArray: cfg.%s must be a positive whole number.', f{1});
    end
end
if ~strcmp(cfg.type, 'grid') && cfg.rows ~= 1
    error('ielec:badOption', 'ielec.fitArray: cfg.rows must be 1 for a %s.', cfg.type);
end
if ~isnumeric(cfg.spacing) || ~isscalar(cfg.spacing) || ~isfinite(cfg.spacing) || cfg.spacing <= 0
    error('ielec:badOption', 'ielec.fitArray: cfg.spacing must be a distance in mm.');
end

% nailed contacts: the anchors already in work.anchors, each told which
% contact of the array it is - NOT work.GS, which is the indexing step's
% (docs/OPEN_QUESTIONS.md item 40)
nailCoords = [];
if cfg.useNailedContacts || ~isempty(cfg.nailNumbers)
    nailCoords = fieldOr(work, 'anchors', []);
    if isempty(nailCoords)
        error('ielec:badOption', ...
            ['ielec.fitArray: nailed contacts were asked for, but ' ...
             'work.anchors is empty. Contacts in work.GS do not hold a ' ...
             'fit - place anchors with ielec.addCoordinate and ' ...
             'cfg.group ''anchors''.']);
    end
    if ~isempty(cfg.nailNumbers) && numel(cfg.nailNumbers) ~= size(nailCoords, 1)
        error('ielec:badOption', ...
            ['ielec.fitArray: %d nail numbers for %d anchors in ' ...
             'work.anchors. There must be one number per anchor.'], ...
            numel(cfg.nailNumbers), size(nailCoords, 1));
    end
end

options = gridFitOptions(work.options, cfg.type, cfg.rows, cfg.columns, ...
                         cfg.spacing, cfg.firstSecondSpacing, cfg.overlap, ...
                         cfg.nailNumbers, nailCoords);

[pos, clusteredCrd, clusteredWeight, clusters] = ...
    gridFit(work.selectedVoxels, work.selectedWeights, cfg.rows, cfg.columns, options);

array = electrodeFromGridFit(pos, clusteredCrd, clusteredWeight, clusters, ...
                             cfg.type, cfg.rows, cfg.columns, project.currentSpace, options);

if ~isempty(nailCoords)
    % The anchors in work.anchors have been used as this array's nails, so
    % they are consumed. The contacts in progress are left where they are:
    % they are the indexing step's, and a fit no longer touches them.
    % All five copies move so that one Undo gives back the whole state.
    work.oldGS          = fieldOr(work, 'GS', []);
    work.oldbrushCrd    = fieldOr(work, 'brushCrd', []);
    work.oldbrushWeight = fieldOr(work, 'brushWeight', []);
    work.oldclusters    = fieldOr(work, 'clusters', []);
    work.oldanchors     = fieldOr(work, 'anchors', []);
    work.anchors        = [];
end

project = recordStep(project, mfilename, cfg);
end

function value = fieldOr(s, name, default)
if isfield(s, name), value = s.(name); else, value = default; end
end
