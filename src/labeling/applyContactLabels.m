function array = applyContactLabels(array, labels, arrayName)
%APPLYCONTACTLABELS  Give an electrode array's contacts labels from a list.
%
%   array = applyContactLabels(array, labels) replaces the array's channel
%   labels with LABELS, a cell array holding exactly one label per contact.
%
%   array = applyContactLabels(array, labels, arrayName) also renames the
%   array itself.
%
%   This is what the "List" button under Label electrodes does once the
%   recording-channel names have been picked. The button handles the file
%   dialog and the two-column selection window; the assignment is here.
%
%   Unlike the button, this function refuses a list whose length does not
%   match the number of contacts, rather than silently labelling part of the
%   array - a script has no selection window to fall back on.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also NAMEARRAYCONTACTS, LABELELECTRODESNATIVE.

if ~isfield(array,'nElectrodes')
    error('applyContactLabels:noContactCount', ...
          'The array has no nElectrodes field, so its contacts cannot be labelled.');
end

if numel(labels) ~= array.nElectrodes
    thisName = '(unnamed)';
    if isfield(array,'Name') && ~isempty(array.Name), thisName = array.Name; end
    error('applyContactLabels:wrongCount', ...
          'Array "%s" has %d contacts but %d labels were given.', ...
          thisName, array.nElectrodes, numel(labels));
end

if nargin >= 3 && ~isempty(arrayName)
    array.Name = arrayName;
end

for i = 1:array.nElectrodes
    array.ch_label{i} = labels{i};
end
end
