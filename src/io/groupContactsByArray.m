function [arrayNames, arrayIndex] = groupContactsByArray(labels)
%GROUPCONTACTSBYARRAY  Work out which array each imported contact belongs to.
%
%   [arrayNames, arrayIndex] = groupContactsByArray(labels)
%
%   EEGLAB and FieldTrip files hold one flat list of contacts, with no
%   record of which electrode array each one was on. iElectrodes recovers it
%   from the labels, on the convention that a contact is named after its
%   array plus a number: G1, G2, ... are contacts of array G, and TR1, TR2,
%   ... of array TR.
%
%     LABELS      cell array of contact labels, one per contact
%     ARRAYNAMES  the arrays found, one name each
%     ARRAYINDEX  for every contact, which entry of ARRAYNAMES it belongs to
%
%   Two properties of the convention are worth knowing, because both come
%   straight from how the name is taken:
%
%   - The name is ALL the letters in the label, not just the ones in front
%     of the number. So 'G1a' belongs to array 'Ga', and 'L1A' to 'LA'.
%   - ARRAYNAMES comes back sorted - UNIQUE sorts - so arrays are listed in
%     alphabetical order, upper case before lower case, not in the order
%     they appear in the file.
%
%   A label with no letters at all gives an array named ''.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ELECTRODEARRAYFROMCONTACTS, READEEGLABELECTRODES,
%   READFIELDTRIPELECTRODES.

N = length(labels);
labelsAlpha = cell(1, N);

% get array names
for i = 1:N
    l = labels{i};
    d = isstrprop(l, 'alpha');
    labelsAlpha{i} = l(d);
end

% arrayIndex==i contains the indexes to the electrodes in arrayNames(i)
[arrayNames, ~, arrayIndex] = unique(labelsAlpha);
end
