function ok = test_ielecDeleteArray()
%TEST_IELECDELETEARRAY  Check ielec.deleteArray.
%
%   ok = test_ielecDeleteArray() removes arrays from the example project
%   through the layer and compares the result with the REMOVEARRAY call the
%   two Remove buttons made themselves, for both lists - the localized
%   arrays and the planning targets. The index to show next is also checked
%   against the rule itself, not only against that call.
%
%   Usage:  cd into the repository, then
%              test_ielecDeleteArray
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.DELETEARRAY, REMOVEARRAY, IELEC.ACCEPTARRAY.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

cfgOpen = [];
cfgOpen.file = fullfile(repoRoot, 'examples', 'exampleNativeSpace.iel');
[project, work] = ielec.openProject([], [], cfgOpen);

% work in progress, which removing an array must not touch
work.GS       = rand(4,3);
work.clusters = repmat((1:4)', 10, 1);

%% ------------------------------------------------- one of the electrodes
fprintf('\n--- ielec.deleteArray against the Remove button ---------------\n');

names    = cellfun(@(e) e.Name, project.electrodes, 'UniformOutput', false);
expected = originalRemove(project, 'electrodes', 2);

cfg = [];
cfg.index = 2;
[shorter, shorterWork, selected] = ielec.deleteArray(project, work, cfg);

nFail = nFail + check(isequaln(shorter.electrodes, expected.arrays) && ...
        selected == expected.selected, ...
    'the array is gone, and the next one is chosen', ...
    sprintf('removed %s, now showing %d', names{2}, selected));
nFail = nFail + check(numel(shorter.electrodes) == numel(project.electrodes) - 1 && ...
        ~any(strcmp(cellfun(@(e) e.Name, shorter.electrodes, 'UniformOutput', false), ...
                    names{2})), ...
    'and only that one is gone', ...
    sprintf('%d arrays left', numel(shorter.electrodes)));
nFail = nFail + check(isequaln(shorterWork, work), ...
    'work is not changed', '');
nFail = nFail + check(selected == 1, ...
    'the array before the removed one is the one to show', '');

[~, ~, firstGone] = ielec.deleteArray(project, work, struct('index', 1));
nFail = nFail + check(firstGone == 1, ...
    'and when the first one goes, the one that followed it', '');
nFail = nFail + check(isequaln(rmfield(shorter, 'electrodes'), ...
        rmfield(project, 'electrodes')), ...
    'and nothing else in the project is', '');

%% ------------------------------------------------- the last one standing
fprintf('\n--- removing them one by one ---------------------------------\n');

left      = project;
lastIndex = -1;
for k = numel(project.electrodes):-1:1
    [left, ~, lastIndex] = ielec.deleteArray(left, work, struct('index', 1));
end
nFail = nFail + check(isempty(left.electrodes) && lastIndex == 0, ...
    'an empty project, and nothing to show', sprintf('selected %d', lastIndex));
nFail = nFail + check(strcmp(errorId(@() ielec.deleteArray(left, work, ...
        struct('index', 1))), 'ielec:badOption'), ...
    'and then there is nothing left to remove', '');

%% ------------------------------------------------------ a planning target
fprintf('\n--- and the planning targets ---------------------------------\n');

if isempty(project.targets)
    % the example has none: make one, so that the path is still covered
    withTargets = project;
    withTargets.targets = project.electrodes(1);
else
    withTargets = project;
end

expectedTarget = originalRemove(withTargets, 'targets', 1);
[fewer, ~, selectedTarget] = ielec.deleteArray(withTargets, work, ...
                                               struct('index', 1, 'group', 'targets'));

nFail = nFail + check(isequaln(fewer.targets, expectedTarget.arrays) && ...
        selectedTarget == expectedTarget.selected, ...
    'the planning array is removed the same way', ...
    sprintf('%d targets left', numel(fewer.targets)));
nFail = nFail + check(isequaln(fewer.electrodes, withTargets.electrodes), ...
    'and the localized arrays are left alone', '');

%% -------------------------------------------------------------- what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

nFail = nFail + check(strcmp(errorId(@() ielec.deleteArray(project, work, [])), ...
        'ielec:missingOption'), ...
    'a call that does not say which array', 'cfg.index');
nFail = nFail + check(strcmp(errorId(@() ielec.deleteArray(project, work, ...
        struct('index', numel(project.electrodes)+1))), 'ielec:badOption'), ...
    'an index that is not one of the arrays', '');
nFail = nFail + check(strcmp(errorId(@() ielec.deleteArray(project, work, ...
        struct('index', 1.5))), 'ielec:badOption'), ...
    'an index that is not a whole number', '');
nFail = nFail + check(strcmp(errorId(@() ielec.deleteArray(project, work, ...
        struct('index', 0))), 'ielec:badOption'), ...
    'index 0, which is what an empty list leaves behind', '');
nFail = nFail + check(strcmp(errorId(@() ielec.deleteArray(project, work, ...
        struct('index', 1, 'group', 'contacts'))), 'ielec:badOption'), ...
    'a group that is neither list', '');
nFail = nFail + check(strcmp(errorId(@() ielec.deleteArray(project, work, ...
        struct('index', 1, 'array', 1))), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.array');

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.deleteArray) == 3 && ...
        nargout(@ielec.deleteArray) == 3, ...
    'the signature, the array to show next as the third output', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - arrays are removed as the Remove buttons removed them.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% What both Remove buttons did once the user had said yes.

function out = originalRemove(project, group, index)
    [out.arrays, out.selected] = removeArray(project.(group), index);
end

% ---------------------------------------------------------------------
function id = errorId(f)
id = '';
try
    f();
catch err
    id = err.identifier;
end
end

function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-52s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-52s %s\n', what, detail);  bad = 1;
end
end
