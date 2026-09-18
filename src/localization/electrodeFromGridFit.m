function array = electrodeFromGridFit(pos, clusteredCrd, clusteredWeight, clusters, ...
                                     type, rows, cols, space, options)
%ELECTRODEFROMGRIDFIT  Build an electrode array structure from a GridFit result.
%
%   array = electrodeFromGridFit(pos, clusteredCrd, clusteredWeight, clusters,
%                                type, rows, cols, space, options)
%
%   The first four inputs are GRIDFIT's four outputs, in its own order:
%
%     POS              nContacts-by-3, the fitted contact positions
%     CLUSTEREDCRD     the CT voxels the fit ended up using
%     CLUSTEREDWEIGHT  their intensities
%     CLUSTERS         which contact each of those voxels belongs to
%
%   and the rest say what was asked for and where it lives:
%
%     TYPE     'grid', 'strip' or 'depth'
%     ROWS     rows in the array (1 for a strip or a depth electrode)
%     COLS     columns in the array
%     SPACE    'Native' or 'MNI' - the space POS is expressed in
%     OPTIONS  the GridFit configuration used, stored with the array so that
%              a fit can be read back later and understood
%
%   The result is a complete electrode array structure: every field that
%   CHECKELECTRODESTRUCTURE defines, with the ones this fit determines filled
%   in. Contacts are labelled '1', '2', ... in fitted order; the array is
%   named after its type, which is what the GUI shows until it is renamed.
%
%   This is assembly, not computation - it is what the Fit button did with
%   GridFit's answer once the answer was in, and it is here so that a fit can
%   be turned into an array without a figure being open.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also GRIDFIT, CHECKELECTRODESTRUCTURE, MAKEADJMAT, CLUSTERCONTACTS.

if ~ismember(type, {'grid','strip','depth'})
    error('electrodeFromGridFit:badType', ...
        'TYPE must be ''grid'', ''strip'' or ''depth'', not ''%s''.', type);
end

% Define new and empty electrode structure
array = checkElectrodeStructure();
array = array{1}; %convert to structure

array.Type = type;
array.Name = array.Type; %elecBaseName;
array.nElectrodes = rows * cols;
array.rows    = rows;
array.columns = cols;

array.x = pos(:,1);
array.y = pos(:,2);
array.z = pos(:,3);

%index in ch labels
for i = 1:(rows*cols)
    array.ch_label{i} = int2str(i);%[elecBaseName int2str(i)];
end

% the voxels the fit was built from, and which contact each one belongs to
array.clusters    = clusters;
array.brushCrd    = clusteredCrd;
array.brushWeight = clusteredWeight;

array.space  = space;  % 'Native' or 'MNI'
array.method = 'grid_fit';
array.methodParameters = options; % store gridFit configuration parameters

% make adjacency Matrix
array.adjMat = makeAdjMat(array.rows, array.columns);
end
