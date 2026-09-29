function ok = test_frontendUsesLayer()
%TEST_FRONTENDUSESLAYER  Which backend functions the frontend still calls.
%
%   ok = test_frontendUsesLayer() reads electrodes_gui.m, finds every call to
%   a function in src/ that is not part of the ielec package, and compares
%   that list with the one written down below. Rule 8 of docs/API_LAYER.md is
%   that in the end the frontend calls nothing but ielec.*; this test is how
%   the distance to that is measured, and it keeps the list honest:
%
%     - a backend function the GUI did not call before is a failure. Whatever
%       was added should have gone through the layer, or through the layer's
%       next function.
%     - one that is no longer called is also a failure, with the message to
%       take it off the list. The list only shrinks, and it shrinks on
%       purpose.
%
%   The list is grouped by the ielec function that is going to take each
%   group over, so what is printed is also the work that is left. Beside it
%   is a second, short list: the shared geometry the backend itself uses,
%   which rule 8 allows the frontend to call.
%
%   Comments do not count: a name inside a comment is not a call. Character
%   strings are left alone, so a function name inside one would count - none
%   does today, and a callback name in a string is a frontend call anyway.
%
%   Usage:  cd into the repository, then
%              test_frontendUsesLayer
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.OPENPROJECT, docs/API_LAYER.md.

repoRoot = fileparts(fileparts(mfilename('fullpath')));

%% ------------------------------------------ what is still waiting, by group
% Each group is what one coming ielec function takes over. Nothing here is a
% defect: it is the backend the GUI still reaches past the layer.
%
% A function stays on the list until its last call site goes, so a name can
% change group. makeAdjMat left the Index button with IELEC.INDEXARRAY and
% nameArrayContacts left the Label button with IELEC.NAMECONTACTS; both are
% still here because the planning panel makes an adjacency matrix and names a
% target's contacts of its own accord.
waiting = {
  'the planning panel - the one workflow not on the layer at all', {
    'newPlanningGrid', 'placePlanningGrid', 'depthTrajectory', 'trajectoryEndPoint', ...
    'trajectoryFrameAngles', 'frameTrajectoryEndPoint', 'loadPlanningTargets', ...
    'savePlanningTargets', 'addArray', 'checkElectrodeStructure', ...
    'electrodes2hullCorrection', 'makeAdjMat', 'nameArrayContacts'}
  'start-up, where the three state groups are made', {
    'checkProjectStructure', 'liftToProject', 'liftToWork', 'liftToUi', ...
    'uiFieldNames', 'default_ielectrodes_options'}
};

% Allowed by rule 8, and not work to be done: the shared geometry. Two-line
% coordinate and distance functions that the backend itself uses, so they
% cannot become the frontend's - library functions, called the way norm is.
% The list is short on purpose; anything else that wants to be an exception
% has to be argued for here.
allowed = {'AnatSpace2Mesh', 'mesh2AnatSpace', 'eucDistMat'};

expected = sort([waiting{:,2}, allowed]);

%% ------------------------------------------------- what the frontend calls
backend = backendFunctionNames(fullfile(repoRoot, 'src'));
code    = withoutComments(fileread(fullfile(repoRoot, 'electrodes_gui.m')));
names   = regexp(code, '(?<![\w.])([A-Za-z]\w*)\s*\(', 'tokens');
names   = unique(cellfun(@(c) c{1}, names, 'UniformOutput', false));
called  = sort(intersect(names, backend));

nFail = 0;

fprintf('\n--- what the frontend still calls past the layer --------------\n');
for g = 1:size(waiting,1)
    here = sort(intersect(waiting{g,2}, called));
    fprintf('  %-28s %s\n', sprintf('%d left', numel(here)), waiting{g,1});
    if ~isempty(here), fprintf('        %s\n', strjoin(here, ', ')); end
end

fprintf('  %-28s %s\n', sprintf('%d allowed', numel(intersect(allowed, called))), ...
    'the shared geometry, which the backend uses too (rule 8)');
fprintf('        %s\n', strjoin(sort(intersect(allowed, called)), ', '));

fprintf('\n--- the list against the code --------------------------------\n');

added = setdiff(called, expected);
nFail = nFail + check(isempty(added), ...
    'no backend function the layer does not know about', ...
    strjoin(added, ', '));

gone = setdiff(expected, called);
nFail = nFail + check(isempty(gone), ...
    'and none on the list has been moved without saying so', ...
    strjoin(gone, ', '));
if ~isempty(gone)
    fprintf('        ^ moved onto the layer: take it out of the list in this test.\n');
end

nFail = nFail + check(numel(expected) == numel(unique(expected)), ...
    'the list names each function once', '');

%% ------------------------------------------------------ and what it does call
ielecCalls   = namesCalledIn(code, 'ielec');
ielviewCalls = namesCalledIn(code, 'ielview');
fprintf('\n--- and through the layers -----------------------------------\n');
fprintf('  %d ielec functions:   %s\n', numel(ielecCalls), strjoin(ielecCalls, ', '));
fprintf('  %d ielview functions: %s\n', numel(ielviewCalls), strjoin(ielviewCalls, ', '));
nFail = nFail + check(numel(ielecCalls) >= 26, ...
    'the frontend goes through the layer for the main workflow', '');
nFail = nFail + check(isequal(sort(ielviewCalls), {'mixImages', 'voxelFromPlaneClick'}), ...
    'and through ielview for what it draws', '');

fprintf('\n');
fprintf('  %d backend calls left to move, and %d allowed to stay.\n', ...
        numel(setdiff(called, allowed)), numel(intersect(allowed, called)));

ok = (nFail == 0);
if ok
    fprintf('\nPASS - the frontend reaches past the layer only where it is known to.\n\n');
else
    fprintf('\nFAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function names = backendFunctionNames(srcFolder)
% every .m under src/, except the ielec package itself and its private folder
listing = dir(fullfile(srcFolder, '**', '*.m'));
names   = {};
for k = 1:numel(listing)
    if contains(listing(k).folder, '+ielec') || contains(listing(k).folder, '+ielview')
        continue
    end
    [~, name] = fileparts(listing(k).name);
    names{end+1} = name; %#ok<AGROW>
end
names = unique(names);
end

function names = namesCalledIn(code, package)
% the functions of one package that the code calls, by their short name
found = regexp(code, [package '\.(\w+)'], 'tokens');
names = unique(cellfun(@(c) c{1}, found, 'UniformOutput', false));
end

function code = withoutComments(text)
% Everything from a % to the end of the line goes, unless the % is inside a
% character string. A quote opens a string only where a value cannot have
% just ended - otherwise it is the transpose operator.
lines = strsplit(text, newline);
for L = 1:numel(lines)
    line = lines{L};
    kept = '';
    inString = false;
    i = 1;
    while i <= numel(line)
        c = line(i);
        if inString
            kept(end+1) = c; %#ok<AGROW>
            if c == ''''
                if i < numel(line) && line(i+1) == ''''
                    kept(end+1) = ''''; %#ok<AGROW>
                    i = i + 1;
                else
                    inString = false;
                end
            end
        elseif c == ''''
            before = strtrim(kept);
            if ~isempty(before) && (isletter(before(end)) || any(before(end) == '0123456789)]}._'''))
                kept(end+1) = c; %#ok<AGROW>   transpose
            else
                inString = true;
                kept(end+1) = c; %#ok<AGROW>
            end
        elseif c == '%'
            break
        else
            kept(end+1) = c; %#ok<AGROW>
        end
        i = i + 1;
    end
    lines{L} = kept;
end
code = strjoin(lines, newline);
end

function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-52s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-52s %s\n', what, detail);  bad = 1;
end
end
