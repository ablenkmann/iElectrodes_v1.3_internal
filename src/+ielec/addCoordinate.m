function [project, work] = addCoordinate(cfg, project, work)
%IELEC.ADDCOORDINATE  Add one contact by hand, where the cursor is.
%
%   [project, work] = ielec.addCoordinate(cfg, project, work) puts one more
%   contact into the coordinates in progress, at the point it is given, and
%   weighs it by the CT. PROJECT gains nothing but the step this records in
%   its history.
%
%   Options (cfg):
%     cfg.coordinate   1-by-3, where the contact goes, in anatomical
%                      coordinates - what the cursor is on. Required.
%     cfg.group        which list it joins: 'contacts', the contacts in
%                      progress, or 'anchors', the points that hold a
%                      GridFit.                        Default: 'contacts'
%
%   With cfg.group 'contacts' the contact joins work.GS, and the point joins
%   work.brushCrd as a "cluster" of its own with the next free number, so
%   that a contact added by hand and one found by clustering are the same
%   kind of thing afterwards: IELEC.INDEXARRAY orders them together. The
%   previous values go to work.oldGS and the other old fields, which
%   IELEC.UNDOCOORDINATES swaps back.
%
%   The weight is the CT intensity at that voxel, less the lowest in the CT.
%   It is left in the CT's own class, which is what the button stored: that
%   is a hair's breadth from the weight IELEC.SELECTVOXELS gives a brushed
%   voxel, which VOXELWEIGHTS casts to double first so that an integer CT
%   cannot saturate. Appending a single to a column of doubles turns the
%   column single, so the two are not interchangeable - this one is the
%   button's. A project with no CT gives every hand-placed contact a weight
%   of 0, as the button did.
%
%   An anchor is weighed too, and the weight is then thrown away - nothing
%   uses it. What that leaves behind is the refusal: a point outside the CT
%   is refused whichever group it was going to join, which is stricter than
%   an anchor needs. It is the same rule as for a contact, and one rule is
%   worth more here than one saved check.
%
%   The coordinate is taken to the nearest voxel. The button took FLOOR of
%   each slider, but a slider is already on a voxel, so what arrived was a
%   whole number and the two agree; they differ only for a coordinate between
%   voxels, which only a script can supply. Rounding is also what
%   VOXELWEIGHTS does.
%
%   With cfg.group 'anchors' it joins work.anchors and nothing else. An
%   anchor is a coordinate: GRIDFIT takes the nail positions and has no use
%   for the clustering bookkeeping, and a row in work.clusters here would
%   claim a cluster of brushed voxels that does not exist. So the two lists
%   are not the same shape of thing, which is the point of separating them.
%
%   This is the separation Alejandro's front-end note asks for -
%   docs/OPEN_QUESTIONS.md item 40. IELEC.FITARRAY nails to work.anchors and
%   consumes it, so this is how a fit is held to a point: with cfg.group
%   'anchors'. Contacts in work.GS no longer hold one.
%
%   Nothing is drawn and no window is opened. Where the cursor is, and
%   whether there is an image to put a contact on, belong to the frontend.
%
%   Errors: ielec:noMRI (no project to place it in - no S2), ielec:badOption
%   (a coordinate that is not three numbers, or one that falls outside the
%   CT and so has no intensity to weigh it by) and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.coordinate = [-24 -12 -18];
%       [project, work] = ielec.addCoordinate(cfg, project, work);
%       size(work.GS, 1)
%
%       cfg.group = 'anchors';         % the same point, as an anchor
%       [project, work] = ielec.addCoordinate(cfg, project, work);
%       size(work.anchors, 1)
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.REMOVECOORDINATE, IELEC.CLEARCOORDINATES,
%            IELEC.UNDOCOORDINATES, IELEC.CLUSTER, ANATSPACE2MESH.

defaults.group = 'contacts';
cfg = checkCfg(cfg, defaults, {'coordinate'}, 'addCoordinate');

field = coordinateField(cfg.group, 'addCoordinate');

if ~isnumeric(cfg.coordinate) || numel(cfg.coordinate) ~= 3
    error('ielec:badOption', ...
        'ielec.addCoordinate: cfg.coordinate must be three numbers, as [x y z].');
end
crd = cfg.coordinate(:)';

if ~isstruct(project) || ~isfield(project, 'S2') || isempty(project.S2)
    error('ielec:noMRI', ...
        ['ielec.addCoordinate: there is no image to place a contact on. ' ...
         'Open a project or load an MRI first.']);
end

% The weight comes from the CT at that voxel. The button read it straight
% from the sliders, which are already in voxels; here the coordinate arrives
% in anatomical space, so it goes back through the same transform.
weight = 0;                    % no CT: every hand-placed contact weighs 0
if ~isempty(fieldOr(project, 'TAC', []))
    voxel = round(AnatSpace2Mesh(crd, project.S2));
    inside = all(voxel >= 1) && all(voxel(:)' <= size(project.TAC.img, 1:3));
    if ~inside
        % one argument per %g: ERROR refuses a non-scalar formatted
        % argument, and would throw MATLAB:error:nonScalarInput instead of
        % this, losing both the identifier and the message
        error('ielec:badOption', ...
            ['ielec.addCoordinate: [%g %g %g] is outside the CT, so it has ' ...
             'no intensity to weigh it by.'], crd(1), crd(2), crd(3));
    end
    weight = project.TAC.img(voxel(1), voxel(2), voxel(3)) ...
             - min(project.TAC.img(:));
end

work = keepForUndo(work);

if strcmp(field, 'GS')
    work.GS          = [work.GS;          crd];
    work.brushCrd    = [work.brushCrd;    crd];
    work.clusters    = [work.clusters;    (length(unique(work.clusters)) + 1)];
    work.brushWeight = [work.brushWeight; weight];
else
    % an anchor is a coordinate and nothing else - see above
    work.anchors = [fieldOr(work, 'anchors', []); crd];
end

project = recordStep(project, mfilename, cfg);
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end
