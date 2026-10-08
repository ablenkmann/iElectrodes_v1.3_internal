function history = decodeHistory(stored)
%DECODEHISTORY  The processing history of a .iel file, as the project holds it.
%
%   history = decodeHistory(stored) returns a cell of steps - the shape
%   docs/API_LAYER.md specifies and the project holds - from whatever the
%   file carried:
%
%     a string      the JSON that ENCODEHISTORY wrote. The normal case.
%     a cell        taken as it is. Files written between the commit that
%                   added the history and the one that started storing it as
%                   a string hold the cell itself; there are no such files
%                   outside a test's temporary folder, and accepting them
%                   costs one line.
%     nothing       a 1.020 file, or a project that has done nothing yet.
%     anything else an empty history, and a warning. A file this version
%                   cannot read the history of opens without one rather than
%                   carrying a value that would break history{end+1} later -
%                   but it says so, because dropping a provenance record in
%                   silence is worse than dropping it.
%
%   The one thing worth knowing is JSONDECODE's own inconsistency: a JSON
%   array whose objects all have the same fields comes back a STRUCT ARRAY,
%   and one whose objects differ comes back a CELL. Two calls to
%   ielec.thresholdCT give the first; a threshold and a fit give the second.
%   Both are normalised to a cell here, so the project's history is a cell
%   whatever the session happened to do.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ENCODEHISTORY, CHECKPROJECTSTRUCTURE, JSONDECODE.

history = {};

if nargin < 1 || isempty(stored)
    return
end

if iscell(stored)
    history = stored(:)';          % already the project's shape
    return
end

if ~(ischar(stored) || isstring(stored))
    warning('decodeHistory:unreadable', ...
        ['The processing history in this project is a %s, which this version ' ...
         'cannot read. The project opens with an empty history; everything ' ...
         'else in it is unaffected.'], class(stored));
    return
end

try
    decoded = jsondecode(char(stored));
catch err
    warning('decodeHistory:notJSON', ...
        ['The processing history in this project could not be read. The ' ...
         'project opens with an empty history; everything else in it is ' ...
         'unaffected. MATLAB said: %s'], err.message);
    return
end

if isempty(decoded)
    return
end

if iscell(decoded)
    history = decoded(:)';
elseif isstruct(decoded)
    % the uniform case: one struct per step, in a struct array
    history = num2cell(decoded(:)');
else
    % valid JSON, but not a list of steps - a hand-edited file
    warning('decodeHistory:notSteps', ...
        ['The processing history in this project decoded to a %s rather ' ...
         'than a list of steps. The project opens with an empty history.'], ...
        class(decoded));
    history = {};
end
end
