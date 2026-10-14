function options = gridFitOptions(baseOptions, type, rows, cols, fixM1, fixM1_BF, overlap, nailNumbers, nailCoords)
%GRIDFITOPTIONS  Assemble the options GridFit needs for one array.
%
%   options = gridFitOptions(baseOptions, type, rows, cols, fixM1, fixM1_BF,
%                            overlap, nailNumbers, nailCoords)
%
%   GridFit is configured in two layers. The processing options hold one
%   set of defaults per kind of array; this function takes the set for TYPE
%   and adds what depends on the array being fitted:
%
%     BASEOPTIONS  the processing options, i.e. work.options, holding
%                  .gridFit_grids, .gridFit_strips and .gridFit_depth
%     TYPE         'grid', 'strip' or 'depth'
%     ROWS, COLS   the array's dimensions
%     FIXM1        distance between neighbouring contacts, in mm
%     FIXM1_BF     distance from the 1st contact to the 2nd, in mm. Only
%                  used for a depth electrode, where it may differ from the
%                  rest (Behnke-Fried); for grids and strips FIXM1 is used.
%     OVERLAP      1 if the grid may overlap itself, else 0 (depth: 0)
%     NAILNUMBERS  optional: which contact each nailed coordinate is, NaN
%                  for a coordinate left unassigned
%     NAILCOORDS   optional: the nailed coordinates, one row each
%
%   "Nailed" contacts are positions the user has already fixed by hand;
%   GridFit keeps those contacts at those positions. They used to be the
%   contacts found by clustering - work.GS - and are now the anchors in
%   work.anchors, placed deliberately as anchors. The two are separate
%   lists: see docs/OPEN_QUESTIONS.md item 40. NAILCOORDS is an argument
%   either way, so nothing here changed but the sentence.
%
%   Finally the attraction to the CT voxels, minDef2.Kc, is set with
%   KC_OPTIMAL from the array's size and spacing.
%
%   One fault is preserved from the Fit button, where this came from: the
%   unassigned nailed coordinates are removed with
%       options.NailElectrodeCrd(isnan(options.NailElectrodeNumber)) = [];
%   which on a matrix removes single elements rather than rows, and leaves a
%   flattened list. It only matters when a nailed coordinate is left
%   unassigned. See docs/OPEN_QUESTIONS.md item 20.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also GRIDFIT, KC_OPTIMAL, ELECTRODEFROMGRIDFIT, DEFAULT_IELECTRODES_OPTIONS.

if nargin < 8, nailNumbers = []; end
if nargin < 9, nailCoords  = []; end

switch type
    case 'grid'
        options = baseOptions.gridFit_grids;
    case 'strip'
        options = baseOptions.gridFit_strips;
    case 'depth'
        options = baseOptions.gridFit_depth;
    otherwise
        error('gridFitOptions:badType', ...
            'TYPE must be ''grid'', ''strip'' or ''depth'', not ''%s''.', type);
end

options.fixM1 = fixM1;
if strcmp(type, 'depth')
    options.fixM1_BF = fixM1_BF;
else
    options.fixM1_BF = fixM1;
end

if isempty(nailCoords)   % no nailed coordinates, as when the Fit button finds none
    options.NailElectrodeNumber = [];
    options.NailElectrodeCrd    = [];
else
    options.NailElectrodeNumber = nailNumbers;
    options.NailElectrodeCrd    = nailCoords;

    % if some coords are not selected, nan is given
    % crds need to be removed  (see OPEN_QUESTIONS item 20)
    options.NailElectrodeCrd(isnan(options.NailElectrodeNumber )) = [];
    options.NailElectrodeNumber(isnan(options.NailElectrodeNumber )) = [];
end

% calculate Kc as optimal Kc from simulations
options.minDef2.Kc = Kc_optimal(fixM1, rows*cols, overlap, options.minDef2.model, options.type); % coregistration: the higher this number, the stronger the atraction to the CT voxels
end
