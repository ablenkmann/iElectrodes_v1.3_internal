function project = recordStep(project, name, cfg)
%RECORDSTEP  Append one call to the project's processing history.
%
%   project = recordStep(project, mfilename, cfg) adds a step to
%   project.history, in the shape docs/API_LAYER.md specifies:
%
%     .function   'ielec.loadCT' - NAME with the package in front
%     .cfg        the cfg, after CHECKCFG filled in its defaults
%     .date       when, as 'yyyy-mm-dd HH:MM:SS'
%     .version    '2.0'
%
%   Every ielec function that produces something a result depends on calls
%   this once, as its last act, with the cfg it was given after the defaults
%   were filled in - which is the whole point: a threshold of 2500 recorded
%   as 2500, not as an empty cfg that happened to default to it.
%
%   Callers pass MFILENAME rather than their own name spelled out. Thirty-one
%   functions call this; a spelled-out name is thirty-one chances to typo one
%   and one more thing to forget when a function is renamed.
%
%   It is called where the change is COMMITTED, not at the top. A function
%   that returns early because there was nothing to do - IELEC.PROJECTARRAYS
%   when every array is already projected, IELEC.REMOVECOORDINATE when
%   nothing was near the cursor - records nothing, because nothing happened.
%
%   **A nested call records nothing.** Two layer functions call others:
%   IELEC.AIMTARGET calls IELEC.SETFRAME, and IELEC.NEWDEPTHTARGET calls
%   IELEC.AIMTARGET. Without this, one keystroke in the Azimuth box would
%   write three steps, two of them the layer talking to itself, and replaying
%   them in order would apply the inner ones twice. So the history records
%   the calls the FRONTEND made - which is also the list a script would have
%   to make to reproduce the result - and the stack is what tells them apart.
%   A function called directly still records: IELEC.SETFRAME from the frame
%   radio group is a step, the same function from inside IELEC.AIMTARGET is
%   not. A local subfunction of the SAME layer function is not nesting - it
%   is the same call - so the line may be moved into one without the step
%   going missing.
%
%   The nine functions that never call it are listed by name in
%   tests/test_ielecHistory.m, which fails if a layer function neither
%   records nor is on that list.
%
%   The version is the iElectrodes 2 line, written as the design writes it.
%   It is not read from version.txt, which still says 1.020 - the last
%   released version, and the right answer for that file until v2 ships.
%   When it does, this should read from it.
%
%   Private to the ielec package.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ENCODEHISTORY, DECODEHISTORY, docs/API_LAYER.md.

% Nested? A frame under src/+ielec/ below the function that called this means
% the layer called itself, and the outer call is the one worth recording.
%
% Frames in the SAME file as the caller do not count. A layer function may
% factor the tail of its work into a local subfunction, and that is still one
% call; counting it as nesting would silently swallow the step while the work
% itself landed, which is a defect nothing would notice.
frames = dbstack('-completenames');
if numel(frames) >= 2
    callerFile = frames(2).file;
    for k = 3:numel(frames)
        if ~strcmp(frames(k).file, callerFile) && ...
                contains(frames(k).file, ['+ielec' filesep])
            return
        end
    end
end

if ~isstruct(project) || ~isfield(project, 'history') || ~iscell(project.history)
    % a project that has not been through CHECKPROJECTSTRUCTURE - which
    % IELEC.NEWPROJECT's is, before it is filled in
    project.history = {};
end

project.history{end+1} = struct( ...
    'function', ['ielec.' name], ...
    'cfg',      cfg, ...
    'date',     char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')), ...
    'version',  '2.0');
end
