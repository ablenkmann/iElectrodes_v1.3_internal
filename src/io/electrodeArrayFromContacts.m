function array = electrodeArrayFromContacts(name, labels, pos, type, rows, columns)
%ELECTRODEARRAYFROMCONTACTS  Build an electrode array from imported contacts.
%
%   array = electrodeArrayFromContacts(name, labels, pos, type, rows, columns)
%
%   The second half of importing an EEGLAB or FieldTrip file. Once the
%   contacts have been grouped into arrays (GROUPCONTACTSBYARRAY) and the
%   user has said what kind of array each one is, this turns one group into
%   a complete electrode array structure.
%
%     NAME        the array's name, e.g. 'G'
%     LABELS      the labels of its contacts, in file order
%     POS         their positions, one row per contact
%     TYPE        'grid', 'strip' or 'depth'
%     ROWS        rows in the array
%     COLUMNS     columns in the array
%
%   Contacts keep the order they had in the file. Nothing checks that the
%   labels run 1, 2, 3 ... or that ROWS*COLUMNS matches the number of
%   contacts: the adjacency matrix is built from ROWS and COLUMNS as given.
%
%   The structure is completed by CHECKELECTRODESTRUCTURE, which fills in
%   every field the import does not know - anatomical labels, projections,
%   and so on - with its defaults.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also GROUPCONTACTSBYARRAY, CHECKELECTRODESTRUCTURE, MAKEADJMAT.

% define the basic fields
array.Name        = name;
array.nElectrodes = size(pos, 1);
array.x           = pos(:,1);
array.y           = pos(:,2);
array.z           = pos(:,3);
array.rows        = rows;
array.columns     = columns;
array.ch_label    = labels;
array.Type        = type;
array.adjMat      = makeAdjMat(rows, columns);
array = checkElectrodeStructure(array); % check one by one. Makes it easy to detect errors
end
