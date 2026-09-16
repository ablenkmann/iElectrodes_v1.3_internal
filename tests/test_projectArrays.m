function ok = test_projectArrays()
%TEST_PROJECTARRAYS  Check the add/remove operations on the project's lists.
%
%   ok = test_projectArrays() exercises ADDARRAY and REMOVEARRAY, the two
%   functions the project uses to keep its electrode and planning arrays.
%   No figure is opened.
%
%   The interesting part is REMOVEARRAY's second output: which array the
%   user is left looking at after a removal. That rule used to be written
%   out twice in electrodes_gui.m, once for electrodes and once for
%   planning arrays, and it is easy to get wrong at the ends of the list.
%   It is checked here at every position.
%
%   The functions are also run against the real arrays of
%   examples/exampleNativeSpace.iel, so that they are seen to work on
%   actual electrode structures and not only on placeholders.
%
%   Usage:  cd into the repository, then
%              test_projectArrays
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end

nFail = 0;

% ---------------------------------------------------------------- addArray
fprintf('\n--- addArray -------------------------------------------------\n');

[a, n] = addArray({}, 'first');
nFail = nFail + check(isequal(a, {'first'}) && n == 1, ...
    'appending to an empty list', '');

[a, n] = addArray(a, 'second');
nFail = nFail + check(isequal(a, {'first','second'}) && n == 2, ...
    'appending to a list that has one', '');

[a, n] = addArray(a, 'third', []);
nFail = nFail + check(isequal(a, {'first','second','third'}) && n == 3, ...
    'an empty index means append', '');

[b, n] = addArray(a, 'replaced', 2);
nFail = nFail + check(isequal(b, {'first','replaced','third'}) && n == 2, ...
    'an index overwrites that entry', '');
nFail = nFail + check(numel(b) == numel(a), ...
    'overwriting does not change the length', '');

% ------------------------------------------------------------- removeArray
fprintf('\n--- removeArray ----------------------------------------------\n');

full = {'A','B','C','D'};

[a, n] = removeArray(full, 1);
nFail = nFail + check(isequal(a, {'B','C','D'}) && n == 1, ...
    'removing the first keeps the selection at 1', '');

[a, n] = removeArray(full, 3);
nFail = nFail + check(isequal(a, {'A','B','D'}) && n == 2, ...
    'removing from the middle selects the one before', '');

[a, n] = removeArray(full, 4);
nFail = nFail + check(isequal(a, {'A','B','C'}) && n == 3, ...
    'removing the last selects the new last', '');

[a, n] = removeArray({'only'}, 1);
nFail = nFail + check(isempty(a) && n == 0, ...
    'removing the only one leaves nothing selected', '');

fprintf('\n--- the selection always points at something -----------------\n');
bad = 0;
for listLength = 1:6
    for removed = 1:listLength
        list = num2cell(1:listLength);
        [rest, sel] = removeArray(list, removed);
        if isempty(rest)
            valid = (sel == 0);
        else
            valid = (sel >= 1) && (sel <= numel(rest));
        end
        if ~valid
            fprintf('              length %d, removed %d -> selection %d\n', ...
                listLength, removed, sel);
            bad = bad + 1;
        end
    end
end
nFail = nFail + check(bad == 0, '21 list lengths and positions', '');

% --------------------------------------------------- add then remove again
fprintf('\n--- adding then removing restores the list -------------------\n');
before  = {'A','B','C'};
[after, n] = addArray(before, 'D');
after      = removeArray(after, n);
nFail = nFail + check(isequal(before, after), ...
    'append then remove is a no-op', '');

% ------------------------------------------------------ on a real project
fprintf('\n--- on the arrays of exampleNativeSpace.iel ------------------\n');
ielFile = fullfile(repoRoot,'examples','exampleNativeSpace.iel');
if ~isfile(ielFile)
    fprintf('  --        the example project is not here\n');
else
    loaded = load(ielFile,'-mat');
    prj    = checkProjectStructure(loaded.s);

    nBefore = numel(prj.electrodes);
    extra   = prj.electrodes{1};
    extra.Name = 'COPY';

    [list, n] = addArray(prj.electrodes, extra);
    nFail = nFail + check(numel(list) == nBefore+1 && n == nBefore+1, ...
        sprintf('%d electrode arrays -> %d', nBefore, numel(list)), '');
    nFail = nFail + check(strcmp(list{n}.Name,'COPY'), ...
        'the added array is the one that was passed', '');

    [list, sel] = removeArray(list, n);
    nFail = nFail + check(numel(list) == nBefore && sel == nBefore, ...
        'and removing it gives the original list back', '');
    nFail = nFail + check(isequaln(list, prj.electrodes), ...
        'the remaining arrays are untouched', '');

    nTargets = numel(prj.targets);
    if nTargets > 1
        [tl, sel] = removeArray(prj.targets, nTargets);
        nFail = nFail + check(numel(tl) == nTargets-1 && sel == nTargets-1, ...
            sprintf('%d planning arrays -> %d', nTargets, numel(tl)), '');
    end
end

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the project array operations behave as specified.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-48s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-48s %s\n', what, detail);  bad = 1;
end
end
