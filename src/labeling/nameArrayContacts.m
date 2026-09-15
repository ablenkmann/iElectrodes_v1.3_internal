function array = nameArrayContacts(array, baseName)
%NAMEARRAYCONTACTS  Name an electrode array and number its contacts.
%
%   array = nameArrayContacts(array, baseName) sets ARRAY.Name to BASENAME
%   and labels contact i as [BASENAME int2str(i)], for every one of the
%   array's nElectrodes contacts. It returns the updated array.
%
%   This is what the "Auto" button under Label electrodes does. The button
%   reads the base name from a text box and refreshes the views; the naming
%   itself is here, so it can be done from a script or a test.
%
%   Example
%       e = prj.electrodes{1};
%       e = nameArrayContacts(e, 'LTG');     % LTG1, LTG2, LTG3, ...
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also APPLYCONTACTLABELS, LABELELECTRODESNATIVE.

if ~isfield(array,'nElectrodes')
    error('nameArrayContacts:noContactCount', ...
          'The array has no nElectrodes field, so its contacts cannot be numbered.');
end

array.Name = baseName;

for i = 1:array.nElectrodes
    array.ch_label{i} = [baseName int2str(i)];
end
end
