function newOrder = arrayContactOrder(rows, columns, change)
%ARRAYCONTACTORDER  The new contact order for a rotation or a flip.
%
%   newOrder = arrayContactOrder(rows, columns, change) returns the order the
%   contacts of a ROWS by COLUMNS array take after CHANGE, as a column of
%   positions: contact i of the array becomes contact newOrder(i). It is what
%   REORDERELECTRODES takes.
%
%   CHANGE is one of
%
%     'rotateLeft'      a quarter turn anticlockwise. Square arrays only
%     'rotateRight'     a quarter turn clockwise. Square arrays only
%     'flipLeftRight'   mirror the columns
%     'flipUpDown'      mirror the rows
%     'reverse'         last contact first. For a depth electrode or a
%                       strip, where there is one line of contacts and only
%                       its direction can be wrong. Ask for it with
%                       arrayContactOrder(1, nContacts, 'reverse')
%
%   The contacts of an array are numbered row by row, so the arithmetic is
%   the same in every case: lay the numbers 1 to rows*columns out as the
%   grid, turn or mirror that, and read it back row by row.
%
%   A quarter turn of an array that has more columns than rows would be an
%   array of a different shape, which this does not do: it is refused here.
%   The two buttons that ask for one refuse it themselves as well.
%
%   Why this is a function of its own: it is what the five little buttons
%   under the grid do, and it says what they do in one place instead of five,
%   where a script can ask for it too. The change itself is
%   REORDERELECTRODES, which moves the coordinates, the anatomical labels,
%   the cluster numbers and the projections together - the contacts keep the
%   names they had, which is what these buttons are for.
%
%   Example
%       newOrder = arrayContactOrder(4, 4, 'rotateRight');
%       e = reorderElectrodes(e, newOrder);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also REORDERELECTRODES, INDEXGRIDELECTRODES, IELEC.REORDERARRAY.

known = {'rotateLeft', 'rotateRight', 'flipLeftRight', 'flipUpDown', 'reverse'};
if ~ischar(change) || ~ismember(change, known)
    error('arrayContactOrder:unknownChange', ...
        'CHANGE must be one of: %s.', strjoin(known, ', '));
end
sizes = {rows, columns};
for k = 1:2
    v = sizes{k};
    if ~isnumeric(v) || ~isscalar(v) || ~isfinite(v) || v < 1 || mod(v, 1) ~= 0
        error('arrayContactOrder:badSize', ...
            'ROWS and COLUMNS must be positive whole numbers.');
    end
end
if ismember(change, {'rotateLeft', 'rotateRight'}) && rows ~= columns
    error('arrayContactOrder:notSquare', ...
        ['A quarter turn is only defined for a square array, and this one is ' ...
         '%d by %d.'], rows, columns);
end

n = double(rows) * double(columns);   % int8 rows from an old file would saturate

if strcmp(change, 'reverse')
    newOrder = fliplr(1:n);
    newOrder = newOrder(:);
    return
end

% the contact numbers, laid out as the array
asGrid = permute(reshape(1:n, columns, rows), [2 1]);

switch change
    case 'rotateLeft'
        asGrid = permute(rot90(asGrid, -1), [2 1]);
    case 'rotateRight'
        asGrid = permute(rot90(asGrid), [2 1]);
    case 'flipLeftRight'
        asGrid = permute(fliplr(asGrid), [2 1]);
    case 'flipUpDown'
        asGrid = permute(flipud(asGrid), [2 1]);
end

newOrder = asGrid(:);
end
