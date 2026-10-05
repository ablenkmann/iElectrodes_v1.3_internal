function ok = test_ielecReorder()
%TEST_IELECREORDER  Check ielec.reorderArray and ARRAYCONTACTORDER.
%
%   ok = test_ielecReorder() turns, mirrors and reverses the example
%   project's arrays through the layer and compares each result with the
%   arithmetic the six buttons did themselves, kept verbatim at the end of
%   this file.
%
%   The permutation is also checked as a permutation: four quarter turns, or
%   two of any mirror, bring an array back to where it started, whatever the
%   arithmetic is.
%
%   Usage:  cd into the repository, then
%              test_ielecReorder
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.REORDERARRAY, ARRAYCONTACTORDER, REORDERELECTRODES.

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
[project, work] = ielec.openProject(cfgOpen, [], []);

% a grid to mirror, and a line of contacts to reverse
gridArray = 0;
lineArray = 0;
for k = 1:numel(project.electrodes)
    e = project.electrodes{k};
    if gridArray == 0 && e.rows > 1 && e.columns > 1 && ...
            e.rows * e.columns == e.nElectrodes
        gridArray = k;
    end
    if lineArray == 0 && e.rows == 1 && e.nElectrodes >= 4, lineArray = k; end
end

%% -------------------------------------------- the mirrors, against the buttons
fprintf('\n--- ielec.reorderArray against the six buttons ----------------\n');

if gridArray == 0
    fprintf('  (the example has no grid - the mirrors are skipped)\n');
else
    before = project.electrodes{gridArray};
    for change = {'flipLeftRight', 'flipUpDown'}
        expected = originalChange(project, gridArray, change{1});

        cfg = [];
        cfg.index  = gridArray;
        cfg.change = change{1};
        [mirrored, mirroredWork] = ielec.reorderArray(cfg, project, work);

        nFail = nFail + check(isequaln(mirrored, expected.project), ...
            sprintf('%s, as the button did it', change{1}), ...
            sprintf('%s, %d by %d', before.Name, before.rows, before.columns));
        nFail = nFail + check(isequaln(mirroredWork, work), ...
            '   work is not changed', '');
    end

    % what a mirror does and does not do: the contacts move, their names stay
    cfg = [];
    cfg.index  = gridArray;
    cfg.change = 'flipLeftRight';
    mirrored = ielec.reorderArray(cfg, project, work);
    after    = mirrored.electrodes{gridArray};
    order    = arrayContactOrder(before.rows, before.columns, 'flipLeftRight');

    someNames = '';
    if ~isempty(after.ch_label)
        someNames = sprintf('%s ... %s', after.ch_label{1}, after.ch_label{end});
    end
    nFail = nFail + check(isequal(after.ch_label, before.ch_label), ...
        'the contacts keep their names', someNames);
    nFail = nFail + check(isequaln([after.x after.y after.z], ...
            [before.x(order) before.y(order) before.z(order)]), ...
        'and the coordinates are the ones that moved', '');
    nFail = nFail + check(isequaln(rmfield(mirrored, 'electrodes'), ...
            rmfield(project, 'electrodes')), ...
        'nothing else in the project is touched', '');
    othersBefore = project.electrodes;   othersBefore(gridArray) = [];
    othersAfter  = mirrored.electrodes;  othersAfter(gridArray)  = [];
    nFail = nFail + check(isequaln(othersBefore, othersAfter), ...
        'and neither is any other array', ...
        sprintf('%d others', numel(othersAfter)));
end

%% ------------------------------------------------------- reversing a line
if lineArray == 0
    fprintf('  (the example has no depth or strip array - reverse is skipped)\n');
else
    expected = originalChange(project, lineArray, 'reverse');

    cfg = [];
    cfg.index  = lineArray;
    cfg.change = 'reverse';
    [reversed, reversedWork] = ielec.reorderArray(cfg, project, work);

    nFail = nFail + check(isequaln(reversed, expected.project), ...
        'reverse, as the Flip labels button did it', ...
        sprintf('%s, %d contacts', project.electrodes{lineArray}.Name, ...
                project.electrodes{lineArray}.nElectrodes));
    nFail = nFail + check(isequaln(reversedWork, work), ...
        '   work is not changed', '');

    % the Flip labels button counted contacts, not rows and columns, and an
    % array that never had those set must still reverse
    noSize = project;
    noSize.electrodes{lineArray}.rows    = 0;
    noSize.electrodes{lineArray}.columns = 0;
    expected = originalChange(noSize, lineArray, 'reverse');
    turned   = ielec.reorderArray(struct('index', lineArray, 'change', 'reverse'), noSize, ...
                                   work);
    nFail = nFail + check(isequaln(turned, expected.project), ...
        'and an array with no rows or columns reverses too', ...
        sprintf('%d contacts', noSize.electrodes{lineArray}.nElectrodes));
end

%% ------------------------------------------------------- the quarter turns
% A quarter turn needs a square array. If the example holds none, one of its
% arrays is squared up here - the arithmetic only reads rows and columns, so
% it is the same test.
%
% A turn is not its own opposite, which is what makes
% docs/OPEN_QUESTIONS.md item 31 visible: REORDERELECTRODES permutes the
% cluster numbers the other way round from the coordinates, and that only
% shows on a change that is not its own opposite - the two turns, and the
% manual order below. The comparisons here are against the button's own code,
% so they hold whichever way item 31 is settled, and fixing it has to change
% these lines on purpose.
square    = 0;
squared   = project;
howSquare = '';
for k = 1:numel(project.electrodes)
    if project.electrodes{k}.rows == project.electrodes{k}.columns && ...
            project.electrodes{k}.rows > 1
        square    = k;
        howSquare = 'from the example';
        break
    end
end
if square == 0
    for k = 1:numel(project.electrodes)
        n = project.electrodes{k}.nElectrodes;
        if n > 1 && mod(sqrt(n), 1) == 0
            square = k;
            squared.electrodes{k}.rows    = sqrt(n);
            squared.electrodes{k}.columns = sqrt(n);
            howSquare = sprintf('%s, read as %d by %d', ...
                project.electrodes{k}.Name, sqrt(n), sqrt(n));
            break
        end
    end
end

if square == 0
    fprintf('  (no array can be read as a square - the turns are skipped)\n');
else
    for change = {'rotateLeft', 'rotateRight'}
        expected = originalChange(squared, square, change{1});

        cfg = [];
        cfg.index  = square;
        cfg.change = change{1};
        turned = ielec.reorderArray(cfg, squared, work);

        nFail = nFail + check(isequaln(turned, expected.project), ...
            sprintf('%s, as the button did it', change{1}), howSquare);
    end

    % four turns come back to the start
    fourTurns = squared;
    for t = 1:4
        fourTurns = ielec.reorderArray(struct('index', square, 'change', 'rotateLeft'), ...
                                        fourTurns, work);
    end
    nFail = nFail + check(isequaln(fourTurns.electrodes{square}, ...
            squared.electrodes{square}), ...
        'and four of them are no turn at all', '');
end

%% ------------------------------------------------- the order from the window
fprintf('\n--- the order the manual window gives ------------------------\n');

if gridArray == 0
    handArray = 1;
else
    handArray = gridArray;
end
n        = project.electrodes{handArray}.nElectrodes;
byHand   = [(2:n) 1];                       % each contact one place along
expected = originalManual(project, handArray, byHand);

cfg = [];
cfg.index  = handArray;
cfg.change = 'order';
cfg.order  = byHand;
[reordered, reorderedWork] = ielec.reorderArray(cfg, project, work);

nFail = nFail + check(isequaln(reordered, expected.project), ...
    'the array is reordered as the button reordered it', ...
    sprintf('%d contacts moved one place along', n));
nFail = nFail + check(isequaln(reorderedWork, work), ...
    'work is not changed', '');

%% ------------------------------------------------- arrayContactOrder itself
fprintf('\n--- the permutations themselves ------------------------------\n');

rows = 3; columns = 4;
for change = {'flipLeftRight', 'flipUpDown'}
    order = arrayContactOrder(rows, columns, change{1});
    nFail = nFail + check(isequal(sort(order)', 1:rows*columns) && ...
            isequal(size(order), [rows*columns 1]), ...
        sprintf('%s is a permutation, as a column', change{1}), '');
    nFail = nFail + check(isequal(order(order), (1:rows*columns)'), ...
        '   and twice over is no change', '');
end

order = arrayContactOrder(1, 6, 'reverse');
nFail = nFail + check(isequal(order, (6:-1:1)'), ...
    'reverse is the contacts backwards', mat2str(order'));

turn = arrayContactOrder(3, 3, 'rotateLeft');
back = arrayContactOrder(3, 3, 'rotateRight');
nFail = nFail + check(isequal(turn(back), (1:9)'), ...
    'a turn each way is no turn', '');

nFail = nFail + check(strcmp(errorId(@() arrayContactOrder(3, 4, 'rotateLeft')), ...
        'arrayContactOrder:notSquare'), ...
    'a quarter turn of a rectangle is refused', '');

%% -------------------------------------------------------------- what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

nFail = nFail + check(strcmp(errorId(@() ielec.reorderArray(...
        struct('index', 1, 'change', 'sideways'), project, work)), 'ielec:badOption'), ...
    'a change that is none of the six', 'cfg.change');
nFail = nFail + check(strcmp(errorId(@() ielec.reorderArray(...
        struct('index', numel(project.electrodes) + 1, 'change', 'reverse'), project, work)), ...
        'ielec:badOption'), ...
    'an array that is not in the project', 'cfg.index');
nFail = nFail + check(strcmp(errorId(@() ielec.reorderArray(...
        struct('index', 1, 'change', 'order', 'order', [1 1 2]), project, work)), ...
        'ielec:badOption'), ...
    'an order that is not a permutation', 'cfg.order');
nFail = nFail + check(strcmp(errorId(@() ielec.reorderArray(...
        struct('index', 1, 'change', 'order'), project, work)), 'ielec:badOption'), ...
    'an order that is missing', 'cfg.order');
nFail = nFail + check(strcmp(errorId(@() ielec.reorderArray(...
        struct('index', 1, 'change', 'reverse', 'group', 'targets'), project, work)), ...
        'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.group');

if gridArray > 0 && project.electrodes{gridArray}.rows ~= project.electrodes{gridArray}.columns
    nFail = nFail + check(strcmp(errorId(@() ielec.reorderArray(...
            struct('index', gridArray, 'change', 'rotateLeft'), project, work)), 'ielec:badOption'), ...
        'a quarter turn of a rectangle', ...
        sprintf('%d by %d', project.electrodes{gridArray}.rows, ...
                project.electrodes{gridArray}.columns));
end

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.reorderArray) == 3 && ...
        nargout(@ielec.reorderArray) == 2, ...
    'the signature, and nothing else comes out', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
fprintf('  what the example allowed: mirrors %s, reverse %s, turns %s.\n', ...
    ranOrNot(gridArray > 0), ranOrNot(lineArray > 0), ranOrNot(square > 0));

ok = (nFail == 0);
if ok
    fprintf('PASS - the contacts move as the six buttons moved them.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% The five buttons under the grid computed their own order and called
% REORDERELECTRODES with it. The lines below are theirs.

function out = originalChange(project, a, change)
    handles.project = project;

    electrodes=handles.project.electrodes{a};

    switch change
        case 'rotateLeft'
            newOrder=1:electrodes.nElectrodes;
            newOrder=permute(reshape(newOrder,electrodes.columns,electrodes.rows),[2 1]);
            newOrder=permute(rot90(newOrder,-1),[2 1]);
        case 'rotateRight'
            newOrder=1:electrodes.nElectrodes;
            newOrder=permute(reshape(newOrder,electrodes.columns,electrodes.rows),[2 1]);
            newOrder=permute(rot90(newOrder),[2 1]);
        case 'flipLeftRight'
            newOrder=1:electrodes.nElectrodes;
            newOrder=permute(reshape(newOrder,electrodes.columns,electrodes.rows),[2 1]);
            newOrder=permute(fliplr(newOrder),[2 1]);
        case 'flipUpDown'
            newOrder=1:electrodes.nElectrodes;
            newOrder=permute(reshape(newOrder,electrodes.columns,electrodes.rows),[2 1]);
            newOrder=permute(flipud(newOrder),[2 1]);
        case 'reverse'
            newOrder=fliplr(1:electrodes.nElectrodes);
    end

    electrodes=reorderElectrodes(electrodes,newOrder(:));

    handles.project.electrodes{a}=electrodes;

    out.project = handles.project;
end

function out = originalManual(project, a, newOrder)
    handles.project = project;

    electrodes=handles.project.electrodes{a};

    electrodes=reorderElectrodes(electrodes,newOrder(:));

    handles.project.electrodes{a}=electrodes;

    out.project = handles.project;
end

% ---------------------------------------------------------------------
function word = ranOrNot(didRun)
if didRun, word = 'ran'; else, word = 'SKIPPED'; end
end

function id = errorId(f)
id = '';
try
    f();
catch err
    id = err.identifier;
    if isempty(id), id = err.message; end
end
end

function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-52s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-52s %s\n', what, detail);  bad = 1;
end
end
