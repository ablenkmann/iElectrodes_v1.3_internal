function ok = test_ielecPlanningGrid()
%TEST_IELECPLANNINGGRID  Check ielec.newTarget and ielec.placeTarget.
%
%   ok = test_ielecPlanningGrid() plans a grid on the example project's
%   envelope, moves it and turns it, and compares each result with the lines
%   the planning buttons ran themselves, kept verbatim at the end of this
%   file.
%
%   The three ways the panel calls PLACEPLANNINGGRID are the three ways the
%   layer can be called, so all three are checked: a new centre, an offset
%   from the one it has, and a turn about it.
%
%   Usage:  cd into the repository, then
%              test_ielecPlanningGrid
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.NEWTARGET, IELEC.PLACETARGET, NEWPLANNINGGRID,
%            PLACEPLANNINGGRID.

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

if isempty(project.vertices_SCE_R)
    fprintf(['\nThe example project has no cortical envelope, so a planning ' ...
             'grid cannot be laid on it.\nNothing to check.\n\n']);
    ok = true; if nargout == 0, clear ok; end, return
end

% a point on the envelope, so the grid lands somewhere sensible
onTheBrain = project.vertices_SCE_R(1, :);
rows = 4;  columns = 5;  spacing = 10;

%% ------------------------------------------- planning one, against the button
fprintf('\n--- ielec.newTarget against the New planning grid button ------\n');

expected = originalNew(project, onTheBrain, rows, columns, spacing);

cfg = [];
cfg.centre  = onTheBrain;
cfg.rows    = rows;
cfg.columns = columns;
cfg.spacing = spacing;
[planned, plannedWork, index] = ielec.newTarget(cfg, project, work);

nFail = nFail + check(isequaln(planned.targets, expected.targets), ...
    'the planned grid is the one the button planned', ...
    sprintf('%s, %d by %d', planned.targets{index}.Name, rows, columns));
nFail = nFail + check(index == numel(project.targets) + 1 && ...
        index == numel(planned.targets), ...
    'and it went on the end of the planning list', sprintf('index %d', index));
nFail = nFail + check(isequaln(plannedWork, work), ...
    'work is not changed', '');
nFail = nFail + check(isequaln(withoutHistory(rmfield(planned, 'targets')), withoutHistory(...
        rmfield(project, 'targets'))), ...
    'and nothing else in the project is', '');
nFail = nFail + check(isequal(numel(planned.electrodes), numel(project.electrodes)), ...
    'a planned array is not a localized one', ...
    sprintf('%d localized, %d planned', numel(planned.electrodes), ...
            numel(planned.targets)));

%% ------------------------------------------------- moving it, all three ways
fprintf('\n--- ielec.placeTarget against the planning buttons ------------\n');

% "change centre": the cursor. The vertex furthest from where the grid is, so
% that it really moves rather than shifting a millimetre
[~, faraway] = max(sum((project.vertices_SCE_R - onTheBrain).^2, 2));
elsewhere    = project.vertices_SCE_R(faraway, :);
expected  = originalPlace(planned, index, elsewhere, []);
moved     = ielec.placeTarget(struct('index', index, 'centre', elsewhere), planned, work);
nFail = nFail + check(isequaln(moved.targets{index}, expected.target), ...
    'moved to a new centre, as Change centre did it', '');

% an arrow button: 1 mm along one axis
before   = planned.targets{index};
expected = originalPlace(planned, index, ...
    mean([before.x before.y before.z]) + [0 0 1], []);
nudged   = ielec.placeTarget(struct('index', index, 'offset', [0 0 1]), planned, work);
nFail = nFail + check(isequaln(nudged.targets{index}, expected.target), ...
    'nudged 1 mm, as the arrow buttons did it', 'offset [0 0 1]');

% a rotate button: no move, 5 degrees
expected = originalPlace(planned, index, mean([before.x before.y before.z]), 5);
turned   = ielec.placeTarget(struct('index', index, 'offset', [0 0 0], 'rotation', 5), ...
                              planned, work);
nFail = nFail + check(isequaln(turned.targets{index}, expected.target), ...
    'turned 5 degrees, as the rotate buttons did it', 'rotation 5');

[~, placedWork] = ielec.placeTarget(struct('index', index, 'offset', [0 0 1]), planned, ...
                                     work);
nFail = nFail + check(isequaln(placedWork, work), ...
    'work is not changed', '');

% PLACEPLANNINGGRID skips the rotation step for [] and runs it for 0. A turn
% of 0 degrees is the identity, so the two cannot be told apart by what comes
% out; each is checked against the same call made directly instead
centreNow    = mean([before.x before.y before.z]);
expectedZero = originalPlace(planned, index, centreNow, 0);
expectedNone = originalPlace(planned, index, centreNow, []);
zeroTurn = ielec.placeTarget(struct('index', index, 'offset', [0 0 0], 'rotation', 0), ...
                              planned, work);
noTurn   = ielec.placeTarget(struct('index', index, 'offset', [0 0 0]), planned, work);

nFail = nFail + check(isequaln(zeroTurn.targets{index}, expectedZero.target) && ...
        isequaln(noTurn.targets{index}, expectedNone.target), ...
    'a rotation of 0 and one of [] each go through as given', '');

%% ---------------------------------------------- naming a planned array
fprintf('\n--- and naming it --------------------------------------------\n');

named = ielec.nameContacts(struct('index', index, 'group', 'targets', 'baseName', 'PlanA'), ...
                            planned, work);
nFail = nFail + check(strcmp(named.targets{index}.Name, 'PlanA') && ...
        strcmp(named.targets{index}.ch_label{1}, 'PlanA1'), ...
    'a planned array is named like a localized one', ...
    named.targets{index}.ch_label{end});
nFail = nFail + check(isequaln(named.electrodes, planned.electrodes), ...
    'and the localized ones are left alone', '');

%% ------------------------------- a cfg out of the history can be replayed
fprintf('\n--- replaying a recorded cfg ---------------------------------\n');

% This is what docs/OPEN_QUESTIONS.md item 42 was about. JSON carries no
% orientation, so a 1-by-3 cfg.centre comes back from the file as 3-by-1.
% Both functions used to require exactly 1-by-3 and so refused their own
% recorded cfg; they take three numbers in any orientation now.
%
% These calls are inside a try because they are the ones a reversion would
% break. Bare, the first refusal would abort this function and take the
% eleven checks below it down with it - the refusals and the layer rules
% have nothing to do with orientation, and losing the orientation should
% read as one failure, not as a test that never ran.
try
    recorded = decodeHistory(encodeHistory(planned.history));
    step     = recorded{end};
    nFail = nFail + check(strcmp(step.function, 'ielec.newTarget') && ...
            isequal(size(step.cfg.centre), [3 1]), ...
        'a recorded centre comes back from the file as a column', ...
        sprintf('1x3 -> %s', mat2str(size(step.cfg.centre))));

    % Value for value, not within a tolerance: JSONENCODE and JSONDECODE are
    % exact for a coordinate - measured, including awkward ones like
    % -37.999634072 - so the orientation is the only thing that may differ.
    % A tolerance here would pass a codec that had started rounding.
    nFail = nFail + check(isequal(step.cfg.centre(:)', cfg.centre), ...
        'with its value unchanged, orientation and nothing else', ...
        sprintf('largest difference %g', ...
                max(abs(step.cfg.centre(:)' - cfg.centre))));

    replayed = ielec.newTarget(step.cfg, project, work);
    nFail = nFail + check(isequaln(replayed.targets{end}, planned.targets{index}), ...
        'and replaying it plans the same grid', ...
        'which is what the history is for');

    % the same for the three ways of moving one
    movedRow    = ielec.placeTarget(struct('index', index, 'offset', [0 0 1]), planned, work);
    movedColumn = ielec.placeTarget(struct('index', index, 'offset', [0; 0; 1]), planned, work);
    nFail = nFail + check(isequaln(movedRow.targets{index}, movedColumn.targets{index}), ...
        'an offset as a column moves it the same way', ...
        'and does not throw MATLAB:sizeDimensionsMustMatch');

    centreRow    = ielec.placeTarget(struct('index', index, 'centre', elsewhere), planned, work);
    centreColumn = ielec.placeTarget(struct('index', index, 'centre', elsewhere(:)), planned, work);
    nFail = nFail + check(isequaln(centreRow.targets{index}, centreColumn.targets{index}), ...
        'and so does a centre', '');
catch err
    nFail = nFail + check(false, ...
        'replaying a recorded cfg', err.identifier);
end

%% -------------------------------------------------------------- what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

noEnvelope = project;
noEnvelope.vertices_SCE_R = [];
nFail = nFail + check(strcmp(errorId(@() ielec.newTarget(cfg, noEnvelope, work)), ...
        'ielec:noSurfaces'), ...
    'planning with no envelope to lay it on', '');
nFail = nFail + check(strcmp(errorId(@() ielec.newTarget(...
        struct('centre', onTheBrain, 'rows', 4, 'columns', 5), project, work)), ...
        'ielec:missingOption'), ...
    'a grid with no spacing', 'cfg.spacing');
nFail = nFail + check(strcmp(errorId(@() ielec.newTarget(...
        struct('centre', [1 2], 'rows', 4, 'columns', 5, 'spacing', 10), project, work)), ...
        'ielec:badOption'), ...
    'a centre that is not three coordinates', 'two is still refused');
nFail = nFail + check(strcmp(errorId(@() ielec.newTarget(...
        struct('centre', [1 2 3 4], 'rows', 4, 'columns', 5, 'spacing', 10), project, work)), ...
        'ielec:badOption'), ...
    'and neither is four', 'the count is checked, the shape is not');
nFail = nFail + check(strcmp(errorId(@() ielec.placeTarget(struct('index', index), planned, ...
                                                            work)), 'ielec:badOption'), ...
    'neither a centre nor an offset', '');
nFail = nFail + check(strcmp(errorId(@() ielec.placeTarget(...
        struct('index', index, 'centre', elsewhere, 'offset', [0 0 1]), planned, work)), ...
        'ielec:badOption'), ...
    'both of them at once', '');
nFail = nFail + check(strcmp(errorId(@() ielec.placeTarget(...
        struct('index', numel(planned.targets) + 1, 'offset', [0 0 1]), planned, work)), ...
        'ielec:badOption'), ...
    'a target that is not in the project', 'cfg.index');
nFail = nFail + check(strcmp(errorId(@() ielec.newTarget(...
        struct('centre', onTheBrain, 'rows', 4, 'columns', 5, 'spacing', 10, 'name', 'x'), ...
        project, work)), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.name');

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.newTarget) == 3 && ...
        nargout(@ielec.newTarget) == 3, ...
    'newTarget''s signature, the index as the third output', '');
nFail = nFail + check(nargin(@ielec.placeTarget) == 3 && ...
        nargout(@ielec.placeTarget) == 2, ...
    'and placeTarget returns the two groups', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - a grid is planned and moved as the buttons did it.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% What the New planning grid button and the nine move/turn buttons ran, with
% the boxes and the cursor taken out.

function out = originalNew(project, crd, rows, cols, eDist)
    handles.project = project;

    target = newPlanningGrid(crd, rows, cols, eDist, ...
        handles.project.vertices_SCE_L, handles.project.vertices_SCE_R);

    [handles.project.targets, l] = addArray(handles.project.targets, target);

    out.targets = handles.project.targets;
    out.index   = l;
end

function out = originalPlace(project, a, centre, rotation)
    handles.project = project;

    target=handles.project.targets{a};

    handles.project.targets{a} = placePlanningGrid(target, centre, rotation, ...
        handles.project.vertices_SCE_L, handles.project.vertices_SCE_R);

    out.target = handles.project.targets{a};
end

% ---------------------------------------------------------------------
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
