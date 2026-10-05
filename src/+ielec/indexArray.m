function [project, work, array] = indexArray(cfg, project, work)
%IELEC.INDEXARRAY  Number the contacts of an array, in the order they lie.
%
%   [project, work, array] = ielec.indexArray(cfg, project, work) takes a
%   set of contact coordinates, works out which contact is number one and
%   which follows which, and returns the array it made. The array is not put
%   in the project: it is a proposal, like the one IELEC.FITARRAY returns,
%   and IELEC.ACCEPTARRAY is what puts it in.
%
%   Options (cfg):
%     cfg.shape    'depth'  a depth electrode or a strip: the contacts are
%                           ordered along the line they lie on
%                  'grid'   a grid of cfg.rows by cfg.columns contacts,
%                           ordered row by row. A grid with one row or one
%                           column is a strip, and is ordered as one.
%                                                                 required
%     cfg.rows     rows of contacts.               required for a grid
%     cfg.columns  contacts per row.               required for a grid
%     cfg.index    which array to number again. [] numbers the contacts in
%                  progress (work.GS) for the first time.       Default: []
%
%   The two cases are the two halves of the Index button. With cfg.index
%   empty the contacts in work.GS have just been clustered and have no order
%   yet, so the array also records where it came from - the space, the
%   method, and the projection method the indexing used - and the brushed
%   voxels come with it. With cfg.index given, an array already in the
%   project is numbered again from its own coordinates, which is how a grid
%   that came out in the wrong order is put right.
%
%   WORK. Numbering the contacts in progress renumbers work.clusters with
%   them: a cluster number is the number of the contact it belongs to, so it
%   has to follow the new order. Numbering an array again does not change
%   work.
%
%   Which contact is number one is the backend's decision, not this
%   function's: INDEXDEPTHELECTRODES sorts the contacts along their main
%   axis and starts at the end that is further from the centre of the
%   volume, and INDEXGRIDELECTRODES finds the grid's corners and fits an
%   ideal grid over them, by the method in work.options
%   (indexing_projection_method).
%
%   Nothing is drawn and no window is opened. The radio buttons that say
%   depth or grid, and the boxes with the rows and the columns, stay in the
%   frontend.
%
%   The name: the backend functions this calls are INDEXDEPTHELECTRODES and
%   INDEXGRIDELECTRODES. An ielec function does not take a backend
%   function's name (docs/API_LAYER.md rule 6), and this one covers both.
%
%   Errors: ielec:noContacts (nothing in progress to number),
%   ielec:badOption (a shape that is neither, an index that is not a
%   position in the project, a grid whose rows times columns is not the
%   number of contacts), and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.shape = 'grid';  cfg.rows = 4;  cfg.columns = 5;
%       [project, work, array] = ielec.indexArray(cfg, project, work);
%       [project, work] = ielec.acceptArray([], project, work, array);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also INDEXDEPTHELECTRODES, INDEXGRIDELECTRODES, MAKEADJMAT,
%            IELEC.ACCEPTARRAY, IELEC.FITARRAY.

defaults.rows    = [];
defaults.columns = [];
defaults.index   = [];
cfg = checkCfg(cfg, defaults, {'shape'}, 'indexArray');

if ~ischar(cfg.shape) || ~ismember(cfg.shape, {'depth', 'grid'})
    error('ielec:badOption', ...
        'ielec.indexArray: cfg.shape must be ''depth'' or ''grid'', not ''%s''.', ...
        char(string(cfg.shape)));
end

% where the coordinates come from: the contacts in progress, or an array
% that is already in the project
if isempty(cfg.index)
    coordinates = fieldOr(work, 'GS', []);
    if isempty(coordinates)
        error('ielec:noContacts', ...
            ['ielec.indexArray: there are no contacts in progress to number. ' ...
             'Cluster some first (ielec.cluster), or say which array to ' ...
             'number again with cfg.index.']);
    end
else
    arrays = fieldOr(project, 'electrodes', {});
    if ~isnumeric(cfg.index) || ~isscalar(cfg.index) || mod(cfg.index, 1) ~= 0 || ...
            cfg.index < 1 || cfg.index > numel(arrays)
        error('ielec:badOption', ...
            'ielec.indexArray: cfg.index must be one of the %d arrays in the project.', ...
            numel(arrays));
    end
    previous    = arrays{cfg.index};
    coordinates = [previous.x previous.y previous.z];
end

if strcmp(cfg.shape, 'grid')
    for f = {'rows', 'columns'}
        v = cfg.(f{1});
        if ~isnumeric(v) || ~isscalar(v) || ~isfinite(v) || v < 1 || mod(v, 1) ~= 0
            error('ielec:badOption', ...
                'ielec.indexArray: cfg.%s must be a positive whole number for a grid.', ...
                f{1});
        end
    end
    if cfg.rows * cfg.columns ~= size(coordinates, 1)
        error('ielec:badOption', ...
            ['ielec.indexArray: %d rows by %d columns is %d contacts, and there ' ...
             'are %d to number.'], cfg.rows, cfg.columns, ...
            cfg.rows * cfg.columns, size(coordinates, 1));
    end
end

switch cfg.shape
    case 'depth'
        [array, order] = indexDepthElectrodes(coordinates, 'depth');
    case 'grid'
        [array, order] = indexGridElectrodes(coordinates, cfg.rows, cfg.columns, ...
                                             'grid', work.options);
end

if isempty(cfg.index)
    % the contacts in progress become this array. Their cluster numbers are
    % contact numbers, so they follow the new order - in work too, because
    % that is where the voxels they belong to are
    before = work.clusters;
    for i = 1:size(coordinates, 1)
        work.clusters(before == order(i)) = i;
    end

    array.clusters     = work.clusters;
    array.brushCrd     = work.brushCrd;
    array.brushWeight  = work.brushWeight;
    array.space        = project.currentSpace;      % 'Native' or 'MNI'
    array.method       = 'clustering';
    array.methodParameters.indexing_projection_method = ...
        work.options.indexing_projection_method;
else
    before = previous.clusters;
    for i = 1:numel(order)
        array.clusters(before == order(i)) = i;
    end

    array.brushCrd    = previous.brushCrd;
    array.brushWeight = previous.brushWeight;
end

array.adjMat = makeAdjMat(array.rows, array.columns);
end

function value = fieldOr(s, name, default)
if isfield(s, name), value = s.(name); else, value = default; end
end
