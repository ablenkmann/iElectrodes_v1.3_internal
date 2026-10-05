function [project, work] = reorderArray(cfg, project, work)
%IELEC.REORDERARRAY  Change which contact of an array is which.
%
%   [project, work] = ielec.reorderArray(cfg, project, work) moves the
%   contact numbers of one array around: the coordinates, the anatomical
%   labels, the cluster numbers and the projections all follow, so nothing
%   about the array changes except which contact is number one and which
%   follows which. The contacts keep the names they had - that is what these
%   buttons are for. WORK is not changed.
%
%   Options (cfg):
%     cfg.index   which array. Required.
%     cfg.change  what to do to it:
%                   'rotateLeft'     a quarter turn anticlockwise
%                   'rotateRight'    a quarter turn clockwise
%                   'flipLeftRight'  mirror the columns
%                   'flipUpDown'     mirror the rows
%                   'reverse'        last contact first, for a depth
%                                    electrode or a strip
%                   'order'          the order given in cfg.order
%                 Required.
%     cfg.order   with cfg.change 'order', the new order: the contact at
%                 position i afterwards is the one that was at cfg.order(i).
%                 A permutation of 1:nElectrodes.                Default: []
%
%   The six are the six buttons under the grid, and the last is the manual
%   one: the list the user drags into place is a permutation, and the layer
%   is given it rather than the window.
%
%   'reverse' is the only one that does not read the array's rows and
%   columns: a line of contacts is reversed whatever those say, which is how
%   the Flip labels button worked and matters for an array that never had
%   them set.
%
%   A quarter turn needs a square array - a turned rectangle would be an
%   array of another shape - and is refused for anything else, as the two
%   rotation buttons refuse it. The four grid changes need the array's rows
%   times columns to be the number of contacts, which the arithmetic rests
%   on.
%
%   A grid whose contact 1 is in the wrong corner is turned until the
%   numbering matches the recording, and the names stay where they were.
%
%   Nothing is drawn and no window is opened. The list window of the manual
%   button stays in the frontend.
%
%   Errors: ielec:badOption (an index that is not a position in the project,
%   a change that is none of the six, a quarter turn of a rectangle, a grid
%   whose rows times columns is not its number of contacts, an order that is
%   not a permutation of the array's contacts) and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.index  = 1;
%       cfg.change = 'rotateRight';
%       [project, work] = ielec.reorderArray(cfg, project, work);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ARRAYCONTACTORDER, REORDERELECTRODES, IELEC.INDEXARRAY.

defaults.order = [];
cfg = checkCfg(cfg, defaults, {'index', 'change'}, 'reorderArray');

arrays = fieldOr(project, 'electrodes', {});
if ~isnumeric(cfg.index) || ~isscalar(cfg.index) || mod(cfg.index, 1) ~= 0 || ...
        cfg.index < 1 || cfg.index > numel(arrays)
    error('ielec:badOption', ...
        'ielec.reorderArray: cfg.index must be one of the %d arrays in the project.', ...
        numel(arrays));
end

array = arrays{cfg.index};
known = {'rotateLeft', 'rotateRight', 'flipLeftRight', 'flipUpDown', ...
         'reverse', 'order'};
if ~ischar(cfg.change) || ~ismember(cfg.change, known)
    error('ielec:badOption', ...
        'ielec.reorderArray: cfg.change must be one of: %s.', strjoin(known, ', '));
end

if strcmp(cfg.change, 'order')
    newOrder = cfg.order(:);
    if isempty(newOrder) || ~isnumeric(newOrder) || ...
            ~isequal(sort(newOrder)', 1:array.nElectrodes)
        error('ielec:badOption', ...
            ['ielec.reorderArray: cfg.order must be a permutation of 1 to %d - ' ...
             'every contact of the array, once each.'], array.nElectrodes);
    end
elseif strcmp(cfg.change, 'reverse')
    % a line of contacts, however its rows and columns are recorded
    newOrder = arrayContactOrder(1, array.nElectrodes, 'reverse');
else
    if ismember(cfg.change, {'rotateLeft', 'rotateRight'}) && ...
            array.rows ~= array.columns
        error('ielec:badOption', ...
            ['ielec.reorderArray: a quarter turn is only defined for a square ' ...
             'array, and this one is %d by %d.'], array.rows, array.columns);
    end
    if double(array.rows) * double(array.columns) ~= array.nElectrodes
        error('ielec:badOption', ...
            ['ielec.reorderArray: the array says %d rows by %d columns and has ' ...
             '%d contacts. Turning or mirroring it needs those to agree.'], ...
            array.rows, array.columns, array.nElectrodes);
    end
    newOrder = arrayContactOrder(array.rows, array.columns, cfg.change);
end

project.electrodes{cfg.index} = reorderElectrodes(array, newOrder);
end

function value = fieldOr(s, name, default)
if isfield(s, name), value = s.(name); else, value = default; end
end
