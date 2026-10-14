function field = coordinateField(group, fname)
%COORDINATEFIELD  Which list of coordinates in progress a cfg.group names.
%
%   field = coordinateField(group, fname) turns the public name of a list
%   into the name of the field that holds it, and refuses anything else.
%   FNAME is the calling layer function, for the error message.
%
%       'contacts'  ->  'GS'       the contacts in progress: what clustering
%                                  produces and what the indexing step
%                                  consumes
%       'anchors'   ->  'anchors'  points placed by hand to hold the GridFit
%                                  algorithm
%
%   The two are separate lists on purpose - docs/OPEN_QUESTIONS.md item 40.
%   'contacts' is the default everywhere, so a caller that does not mention
%   a group gets the behaviour the buttons have always had.
%
%   The public name is not the field name for the contacts, and deliberately:
%   'GS' is what the field has been called since 1.020 and the file format
%   keeps it, but it says nothing to a caller. A cfg option is part of the
%   interface, so it gets the readable name, and this is the one place that
%   knows both.
%
%   Private to the ielec package.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.ADDCOORDINATE, IELEC.REMOVECOORDINATE,
%            IELEC.CLEARCOORDINATES, IELEC.UNDOCOORDINATES.

if ~ischar(group) && ~(isstring(group) && isscalar(group))
    error('ielec:badOption', ...
        'ielec.%s: cfg.group must be ''contacts'' or ''anchors''.', fname);
end

switch char(group)
    case 'contacts'
        field = 'GS';
    case 'anchors'
        field = 'anchors';
    otherwise
        error('ielec:badOption', ...
            'ielec.%s: cfg.group must be ''contacts'' or ''anchors'', not ''%s''.', ...
            fname, char(group));
end
end
