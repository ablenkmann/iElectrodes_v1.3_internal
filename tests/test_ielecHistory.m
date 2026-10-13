function ok = test_ielecHistory()
%TEST_IELECHISTORY  Every ielec function records its call, or is named here.
%
%   ok = test_ielecHistory() checks the processing history two ways.
%
%   Statically: every function in src/+ielec/ either calls RECORDSTEP or is
%   on the list below, which names the nine that record nothing and why. A
%   new layer function that records neither nor appears there fails this, the
%   way tests/test_frontendUsesLayer.m fails a new backend call. The list
%   only shrinks on purpose.
%
%   Dynamically: that what is recorded is the shape docs/API_LAYER.md
%   specifies, that the cfg recorded is the one CHECKCFG filled in rather
%   than the one the caller passed, that a call the layer makes to itself
%   records nothing, and that a function which returns early because there
%   was nothing to do records nothing either.
%
%   The dynamic half drives the functions that need no image and no file -
%   ten of the thirty-one. The other twenty-one are covered statically only:
%   the scan proves the call is there, in the right shape, but not that it
%   runs. Driving them needs an MRI, a CT, a parcellation, a pair of
%   surfaces or a label file, which is what the tests of those functions
%   already set up; each of those compares the project it produces against
%   the pre-layer code modulo the history, through TESTS/WITHOUTHISTORY, so
%   none of them would notice a missing step. That is a known gap and the
%   honest place to say so is here.
%
%   The fixtures need no image and no file: a planned depth electrode is
%   built from numbers, which is why this test runs in under a second while
%   the ones that open the example project take seconds.
%
%   Usage:  cd into the repository, then
%              test_ielecHistory
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also RECORDSTEP, ENCODEHISTORY, TEST_IELFORMAT, docs/API_LAYER.md.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

%% ------------------------------------------ who records, and who does not
% The nine that record nothing. Each one is here for a reason, and the reason
% is the same three in different clothes: it reports, it writes a file, or it
% starts a session.
silent = {
  'projectionState',    'reports what the projection would do, and changes nothing'
  'pointLabel',         'reports what the atlas calls a place - the cursor moves often'
  'arrayFileContents',  'reports what is in a file, before the import is decided'
  'colourCaches',       'computes display colours, which are not a result'
  'saveProject',        'writes a file; the project is what it was'
  'saveTargets',        'writes a file; the plan is what it was'
  'export',             'writes a file; recording the export would record the reading of it'
  'startSession',       'starts the program, before there is a project to record in'
  'openProject',        'replaces the project with a file, history and all - a step here would grow the history on every open'
};

fprintf('\n--- which functions record ------------------------------------\n');

% The CALL, not the word. contains(code,'recordStep(') matched the name in a
% comment, so a function could stop recording - with the line commented out,
% or described in prose - and this still counted it. The pattern is anchored
% to the start of a line, so a full-line comment (which starts with %) and a
% trailing comment (which has code before it) cannot match, and it pins the
% shape as well: the step is the function's own cfg, under its own name.
theCall = '^\s*project = recordStep\(project, mfilename, \w+\);\s*$';

layer   = dir(fullfile(repoRoot, 'src', '+ielec', '*.m'));
records = {};
quiet   = {};
for k = 1:numel(layer)
    [~, name] = fileparts(layer(k).name);
    code = fileread(fullfile(layer(k).folder, layer(k).name));
    if ~isempty(regexp(code, theCall, 'lineanchors', 'once'))
        records{end+1} = name;   %#ok<AGROW>
    else
        quiet{end+1} = name;     %#ok<AGROW>
    end
end

fprintf('  %d of %d layer functions record a step.\n', numel(records), numel(layer));

undeclared = setdiff(quiet, silent(:,1)');
nFail = nFail + check(isempty(undeclared), ...
    'every function that records nothing is named above', ...
    strjoin(undeclared, ', '));
if ~isempty(undeclared)
    fprintf(['        ^ either it should record, or it belongs in the list ' ...
             'with a reason.\n']);
end

gone = setdiff(silent(:,1)', quiet);
nFail = nFail + check(isempty(gone), ...
    'and everything named above still records nothing', strjoin(gone, ', '));
if ~isempty(gone)
    fprintf('        ^ it records now: take it out of the list.\n');
end

nFail = nFail + check(numel(records) + numel(quiet) == numel(layer), ...
    'and every function is one or the other', '');

%% ------------------------------------------------------- the shape of a step
fprintf('\n--- what a step looks like ------------------------------------\n');

work = struct();
[project, work] = ielec.newDepthTarget([], [], work);

nFail = nFail + check(numel(project.history) == 1, ...
    'one call, one step', sprintf('%d', numel(project.history)));

step = project.history{1};
nFail = nFail + check(isequal(sort(fieldnames(step))', ...
        {'cfg', 'date', 'function', 'version'}), ...
    'the four fields the design specifies', strjoin(sort(fieldnames(step))', ', '));
nFail = nFail + check(strcmp(step.function, 'ielec.newDepthTarget'), ...
    'the function, with its package in front', step.function);
nFail = nFail + check(strcmp(step.version, '2.0'), ...
    'the version of the line that made it', step.version);
nFail = nFail + check(~isempty(regexp(step.date, ...
        '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$', 'once')), ...
    'and when, as the design writes it', step.date);

% The cfg is the one CHECKCFG filled in, not the empty one the caller passed.
% This is the whole point: a threshold of 2500 recorded as 2500.
nFail = nFail + check(isstruct(step.cfg) && strcmp(step.cfg.name, 'Planning') && ...
        isequal(step.cfg.targetOut, [45 45 45]) && step.cfg.nContacts == 10, ...
    'the cfg with its defaults filled in, not the [] it was given', ...
    sprintf('nContacts %d, name %s', step.cfg.nContacts, step.cfg.name));

%% ------------------------------------------ a call the layer makes to itself
fprintf('\n--- the layer calling itself ----------------------------------\n');

% newDepthTarget calls aimTarget, which calls setFrame. One step above, not
% three - otherwise one keystroke in the Azimuth box writes three steps and
% replaying them applies the inner ones twice.
nFail = nFail + check(numel(project.history) == 1 && ...
        strcmp(project.history{1}.function, 'ielec.newDepthTarget'), ...
    'newDepthTarget records itself, not aimTarget and setFrame', ...
    'the stack is what tells them apart');

% called directly, each is a step of its own
[project, work] = ielec.aimTarget(struct('index', 1), project, work);
[project, work] = ielec.setFrame(struct('index', 1), project, work);
nFail = nFail + check(numel(project.history) == 3 && ...
        strcmp(project.history{2}.function, 'ielec.aimTarget') && ...
        strcmp(project.history{3}.function, 'ielec.setFrame'), ...
    'and called directly, each records', ...
    strjoin(cellfun(@(s) s.function, project.history, 'UniformOutput', false), ' '));

%% ------------------------------------------- nothing done, nothing recorded
fprintf('\n--- and nothing happened, nothing recorded --------------------\n');

% removeCoordinate returns early when nothing is near the cursor
before = numel(project.history);
withContacts = project;
work.GS = [0 0 0];  work.brushCrd = [0 0 0];
work.brushWeight = 1;  work.clusters = 1;
[after, ~, removed] = ielec.removeCoordinate(...
    struct('coordinate', [500 500 500]), withContacts, work);
nFail = nFail + check(~removed && numel(after.history) == before, ...
    'nothing within the tolerance records nothing', ...
    sprintf('%d steps before, %d after', before, numel(after.history)));

[after, ~, removed] = ielec.removeCoordinate(...
    struct('coordinate', [0 0 0]), withContacts, work);
nFail = nFail + check(removed && numel(after.history) == before + 1, ...
    'and removing one records one', ...
    sprintf('%d steps', numel(after.history)));

% a function with no options records a checked cfg, not the [] it was handed
[cleared, ~] = ielec.clearCoordinates([], withContacts, work);
nFail = nFail + check(isstruct(cleared.history{end}.cfg) && ...
        isempty(fieldnames(cleared.history{end}.cfg)), ...
    'a function with no options records an empty struct, not []', ...
    class(cleared.history{end}.cfg));

%% ------------------------------------- four more that need no image or file
fprintf('\n--- and the ones that can be driven without a file -------------\n');

array = checkElectrodeStructure();
array = array{1};
array.Name        = 'G';
array.Type        = 'grid';
array.nElectrodes = 4;
array.rows        = 2;
array.columns     = 2;
array.x = [0;10;0;10];  array.y = [0;0;10;10];  array.z = [0;0;0;0];
array.ch_label = {'G1','G2','G3','G4'};

drivable = {
  'acceptArray',   @(p, w) ielec.acceptArray([], p, w, array)
  'nameContacts',  @(p, w) ielec.nameContacts(struct('index', 1, 'baseName', 'LTG'), p, w)
  'deleteArray',   @(p, w) ielec.deleteArray(struct('index', 1), p, w)
  'setOptions',    @(p, w) ielec.setOptions([], p, w)
};
driven = project;  drivenWork = work;
for k = 1:size(drivable, 1)
    before = numel(driven.history);
    [driven, drivenWork] = drivable{k, 2}(driven, drivenWork);
    nFail = nFail + check(numel(driven.history) == before + 1 && ...
            strcmp(driven.history{end}.function, ['ielec.' drivable{k,1}]), ...
        sprintf('%s records one step', drivable{k,1}), ...
        driven.history{end}.function);
end

%% ---------------------------------------------------------- they accumulate
fprintf('\n--- in the order they were made -------------------------------\n');

names = cellfun(@(s) s.function, project.history, 'UniformOutput', false);
nFail = nFail + check(numel(unique(names)) == 3 && ...
        strcmp(names{1}, 'ielec.newDepthTarget'), ...
    'the steps are in the order the calls were made', strjoin(names, ' -> '));

%% ------------------------------------------------------------ layer rules
fprintf('\n--- and nothing was drawn -------------------------------------\n');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - every call that produces something records what it was given.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-52s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-52s %s\n', what, detail);  bad = 1;
end
end
