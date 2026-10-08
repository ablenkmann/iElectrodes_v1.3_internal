function text = encodeHistory(history)
%ENCODEHISTORY  The processing history as one string, for the .iel file.
%
%   text = encodeHistory(history) turns the cell of steps the project holds
%   into a single JSON string, which is what the file stores. DECODEHISTORY
%   turns it back.
%
%   The project holds the history in the shape docs/API_LAYER.md specifies -
%   a cell of structs, one per step, read at the prompt as
%   project.history{3}.cfg.lowThreshold - and this is the file's shape only.
%
%   Why: a .iel file is HDF5 (-v7.3), where every cell element and every
%   nested struct is an object with its own header, so a cell of structs cost
%   about **4,400 bytes per step** whatever the cfg held. As JSON a step is
%   124 characters, and what that costs on disk falls as the history grows,
%   because the file is deflated: about 250 bytes a step for the first few,
%   66 at a hundred steps, 21 at a thousand. The honest figure is the 124
%   characters; the rest is compression. docs/OPEN_QUESTIONS.md item 41 has
%   the measurements.
%
%   **A save never fails because of a history.** JSON cannot carry a function
%   handle, a complex number, a sparse matrix or a duration, and a cfg that
%   holds one used to abort the save of the whole patient project. Now the
%   step that cannot be encoded is replaced by a note saying so, the rest of
%   the history is kept, the project is written, and a warning says which
%   steps were affected. Losing a line of provenance is not a reason to lose
%   the patient's data.
%
%   What JSON does not carry, for the values it does accept:
%
%     class        an int32 comes back a double of the same value
%     orientation  a ROW vector comes back a COLUMN. A column survives, since
%                  that is what JSONDECODE produces for a JSON array
%     Inf and NaN  are **lost, not flattened**: a scalar comes back 0-by-0,
%                  and inside an array it becomes NaN. This is the one case
%                  where a value rather than a type goes, and it matters -
%                  [NaN NaN NaN] is the documented default of
%                  options.image_voxdim
%
%   TEST_IELFORMAT pins all three. A value that has to survive byte for byte
%   does not belong in a recorded step.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also DECODEHISTORY, WRITEIELFILE, CHECKPROJECTSTRUCTURE.

if isempty(history)
    text = '[]';
    return
end

% Belt and braces: CHECKPROJECTSTRUCTURE routes every history through
% DECODEHISTORY, which always returns a cell, so this cannot fire from the
% repository's own paths.
if ~iscell(history)
    error('encodeHistory:notACell', ...
        ['A processing history is a cell of steps, one per call; this one ' ...
         'is a %s.'], class(history));
end

try
    text = jsonencode(history);
    return
catch err
    firstFailure = err;
end

% One step at a time, so that one unencodable value costs that step and not
% the save.
replaced = {};
for k = 1:numel(history)
    try
        jsonencode(history{k});
    catch
        replaced{end+1} = nameOf(history{k}, k);   %#ok<AGROW>
        history{k} = withoutTheCfg(history{k}, firstFailure.message);
    end
end

if isempty(replaced)
    % The failure was not any one step's. Keep the project, lose the history,
    % and say so - there is nothing else to try.
    text = '[]';
    warning('encodeHistory:notEncodable', ...
        ['The processing history could not be written and has been left out ' ...
         'of the file. The project itself is saved. MATLAB said: %s'], ...
        firstFailure.message);
    return
end

text = jsonencode(history);
warning('encodeHistory:stepNotEncodable', ...
    ['%d step(s) of the processing history hold a value JSON cannot carry ' ...
     'and were written as a note instead: %s. The project is saved and the ' ...
     'other steps are intact. MATLAB said: %s'], ...
    numel(replaced), strjoin(replaced, ', '), firstFailure.message);
end

% ---------------------------------------------------------------------
function name = nameOf(step, k)
if isstruct(step) && isfield(step, 'function') && ischar(step.function)
    name = sprintf('%s (step %d)', step.function, k);
else
    name = sprintf('step %d', k);
end
end

function step = withoutTheCfg(step, because)
% keep what can be kept: which function, when, and which version
kept = struct();
for f = {'function', 'date', 'version'}
    if isstruct(step) && isfield(step, f{1})
        kept.(f{1}) = step.(f{1});
    end
end
kept.cfg = sprintf('<not recorded: %s>', because);
step = kept;
end
