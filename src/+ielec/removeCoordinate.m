function [project, work, removed] = removeCoordinate(cfg, project, work)
%IELEC.REMOVECOORDINATE  Take out the contact in progress nearest a point.
%
%   [project, work, removed] = ielec.removeCoordinate(cfg, project, work)
%   finds the contact in progress nearest the point it is given and takes it
%   out, together with the voxels it was made from. PROJECT is not changed.
%
%   Options (cfg):
%     cfg.coordinate   1-by-3, the point to look near, in anatomical
%                      coordinates - what the cursor is on. Required.
%     cfg.tolerance    how near is near enough, in mm.        Default: 2
%
%   REMOVED is true when one was taken out and false when none was within
%   cfg.tolerance - which is the Delete button's warning, and the reason this
%   reports rather than failing. Nothing is changed in the false case, not
%   even the undo copies.
%
%   What goes with the contact is the work the clustering did: the rows of
%   work.brushCrd and work.brushWeight whose cluster was that contact, and
%   the cluster numbers above it come down by one so that they stay a
%   numbering of what is left. That renumbering is the whole reason this is
%   a layer function and not three lines in a callback.
%
%   The previous values go to work.oldGS and the other old fields, which
%   IELEC.UNDOCOORDINATES swaps back.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:badOption (a coordinate that is not three numbers, a
%   tolerance that is not one positive number) and those of the cfg check.
%   An empty work.GS is not an error: nothing is near, so REMOVED is false.
%
%   Example
%       cfg = [];
%       cfg.coordinate = cursor;
%       [project, work, removed] = ielec.removeCoordinate(cfg, project, work);
%       if ~removed, warning('nothing within 2 mm'); end
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.ADDCOORDINATE, IELEC.CLEARCOORDINATES,
%            IELEC.UNDOCOORDINATES, IELEC.CLUSTER, EUCDISTMAT.

defaults.tolerance = 2;
cfg = checkCfg(cfg, defaults, {'coordinate'}, 'removeCoordinate');

if ~isnumeric(cfg.coordinate) || numel(cfg.coordinate) ~= 3
    error('ielec:badOption', ...
        'ielec.removeCoordinate: cfg.coordinate must be three numbers, as [x y z].');
end
if ~isnumeric(cfg.tolerance) || ~isscalar(cfg.tolerance) || cfg.tolerance <= 0
    error('ielec:badOption', ...
        'ielec.removeCoordinate: cfg.tolerance must be a distance in mm.');
end
crd = cfg.coordinate(:)';

removed = false;
if isempty(fieldOr(work, 'GS', []))
    return                     % nothing in progress, so nothing is near
end

distance = eucDistMat(work.GS, crd);
[nearest, ind] = min(distance);
if ~(nearest < cfg.tolerance)
    return                     % the button's "no electrodes in the proximity"
end

work = keepForUndo(work);

work.GS(ind, :) = [];

thisCluster  = find(work.clusters == ind);      % the voxels of that contact
higher       = find(work.clusters >  ind);      % the contacts after it

work.clusters(higher, :)     = work.clusters(higher, :) - 1;
work.clusters(thisCluster, :)    = [];
work.brushCrd(thisCluster, :)    = [];
work.brushWeight(thisCluster, :) = [];

removed = true;
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end
