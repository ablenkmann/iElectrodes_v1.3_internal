function [project, work, removed] = removeCoordinate(cfg, project, work)
%IELEC.REMOVECOORDINATE  Take out the contact in progress nearest a point.
%
%   [project, work, removed] = ielec.removeCoordinate(cfg, project, work)
%   finds the contact in progress nearest the point it is given and takes it
%   out, together with the voxels it was made from. PROJECT gains nothing but
%   the step this records in its history.
%
%   Options (cfg):
%     cfg.coordinate   1-by-3, the point to look near, in anatomical
%                      coordinates - what the cursor is on. Required.
%     cfg.tolerance    how near is near enough, in mm.        Default: 2
%     cfg.group        which list to take it out of: 'contacts' or
%                      'anchors'.                      Default: 'contacts'
%
%   REMOVED is true when one was taken out and false when none was within
%   cfg.tolerance - which is the Delete button's warning, and the reason this
%   reports rather than failing. Nothing is changed in the false case, not
%   even the undo copies.
%
%   An anchor has none of that to take with it - work.anchors is a list of
%   coordinates and nothing else - so with cfg.group 'anchors' the row goes
%   and that is all. See docs/OPEN_QUESTIONS.md item 40.
%
%   What goes with a contact is the work the clustering did: the rows of
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
%   An empty list is not an error: nothing is near, so REMOVED is false.
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
defaults.group     = 'contacts';
cfg = checkCfg(cfg, defaults, {'coordinate'}, 'removeCoordinate');

field = coordinateField(cfg.group, 'removeCoordinate');

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
if isempty(fieldOr(work, field, []))
    return                     % nothing in progress, so nothing is near
end

distance = eucDistMat(work.(field), crd);
[nearest, ind] = min(distance);
if ~(nearest < cfg.tolerance)
    return                     % the button's "no electrodes in the proximity"
end

work = keepForUndo(work);

work.(field)(ind, :) = [];

if strcmp(field, 'GS')
    thisCluster  = find(work.clusters == ind);      % the voxels of that contact
    higher       = find(work.clusters >  ind);      % the contacts after it

    work.clusters(higher, :)     = work.clusters(higher, :) - 1;
    work.clusters(thisCluster, :)    = [];
    work.brushCrd(thisCluster, :)    = [];
    work.brushWeight(thisCluster, :) = [];
end

removed = true;

project = recordStep(project, mfilename, cfg);
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end
