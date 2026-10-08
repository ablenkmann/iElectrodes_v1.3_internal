function ok = test_ielFormat()
%TEST_IELFORMAT  The .iel format: the history, the schema version, and 1.020.
%
%   ok = test_ielFormat() checks the two fields iElectrodes 2 adds to the
%   .iel file, in both directions:
%
%     - a file written by 1.020 opens with an empty history;
%     - a file written here carries history and schemaVersion 2;
%     - a history survives being written and read again - as a cell in the
%       project and as one JSON string in the file, which is what keeps a
%       recorded step to tens of bytes instead of 4.5 kB;
%     - **iElectrodes 1.020 can open a file written here**, which is the
%       promise docs/API_LAYER.md makes and says will be tested rather than
%       assumed.
%
%   That last one runs 1.020 in a MATLAB of its own, and the reason is worth
%   knowing: of the 406 function names under its priv, 77 are also names in
%   our src - checkProjectStructure among them - and most of the rest are the
%   SPM it carries, which would shadow ours in third_party. Putting its
%   folders on this MATLAB's path would shadow all of that for every test
%   that runs after this one. It carries its own SPM, so a separate process
%   needs nothing from here. It costs the suite one MATLAB start-up, which is
%   why this is the slowest test in the folder.
%
%   The check is 1.020's own reading core. Its Open button is a LOAD, then
%   DEFAULTGUIVARIABLES, then CHECKPROJECTSTRUCTURE(s, handles) - and the
%   last of those is the one that decides what a .iel file means to it.
%   DEFAULTGUIVARIABLES is skipped: it sets the MNI meshes, the cursor, the
%   plot flags and a hundred other interface defaults, every data field of
%   which CHECKPROJECTSTRUCTURE then overwrites.
%
%   It skips, passing, when the 1.020 copy is not beside the repository.
%
%   Usage:  cd into the repository, then
%              test_ielFormat
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also CHECKPROJECTSTRUCTURE, WRITEIELFILE, PROJECTFIELDNAMES,
%            IELEC.SAVEPROJECT, IELEC.OPENPROJECT, docs/API_LAYER.md.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

outFolder = fullfile(tempdir, ['iElectrodes_format_' char(java.util.UUID.randomUUID)]);
mkdir(outFolder);
removeLater = onCleanup(@() removeFolder(outFolder));

%% ------------------------------------------ a 1.020 file opens with no history
fprintf('\n--- a file from 1.020 --------------------------------------\n');

cfgOpen = [];
cfgOpen.file = fullfile(repoRoot, 'examples', 'exampleNativeSpace.iel');
[project, work, ui] = ielec.openProject(cfgOpen, [], []);

nFail = nFail + check(isfield(project, 'history'), ...
    'the project has a history field', '');
nFail = nFail + check(iscell(project.history) && isempty(project.history), ...
    'and it is empty, because 1.020 never wrote one', ...
    class(project.history));

% it is the project's, not the work's: what was done to the patient's data is
% part of the patient's data
nFail = nFail + check(~isfield(work, 'history'), ...
    'the history belongs to the project, not to work', '');

%% ------------------------------------- what we write carries both new fields
fprintf('\n--- what iElectrodes 2 writes ------------------------------\n');

plain = fullfile(outFolder, 'plain.iel');
ielec.saveProject(struct('file', plain), project, work, ui);

s = readFlat(plain);
nFail = nFail + check(isfield(s, 'history'), 'the file has a history', '');
nFail = nFail + check(isfield(s, 'schemaVersion') && isequal(s.schemaVersion, 2), ...
    'and a schemaVersion of 2', ...
    sprintf('%s', mat2str(fieldOr(s, 'schemaVersion', 'missing'))));

% the flat file is still flat: the two new fields sit at the top level with
% everything else, which is what 1.020 reads
nFail = nFail + check(~isstruct(fieldOr(s, 'project', 0)), ...
    'and the file is still flat', ...
    ['grouped fields present: ' ...
     strjoin(intersect(fieldnames(s), {'project','work','ui'})', ', ')]);

%% ------------------------------------------- a history survives a round trip
fprintf('\n--- and a history comes back -------------------------------\n');

step1 = struct('function', 'ielec.loadCT', ...
               'cfg',      struct('ct', 'C:\data\p01\CT.nii', 'mask', ''), ...
               'date',     '2026-10-08 11:04:00', ...
               'version',  '2.0');
step2 = struct('function', 'ielec.thresholdCT', ...
               'cfg',      struct('lowThreshold', 2500, 'highThreshold', 4000), ...
               'date',     '2026-10-08 11:05:12', ...
               'version',  '2.0');

withHistory = project;
withHistory.history = {step1, step2};

stamped = fullfile(outFolder, 'stamped.iel');
ielec.saveProject(struct('file', stamped), withHistory, work, ui);
[reopened, ~] = ielec.openProject(struct('file', stamped), [], []);

nFail = nFail + check(isequaln(reopened.history, {step1, step2}), ...
    'two steps written and read back, cfg and all', ...
    sprintf('%d steps', numel(reopened.history)));
keptFile = '';
if ~isempty(reopened.history) && isstruct(reopened.history{1}) && ...
        isfield(reopened.history{1}, 'cfg') && ...
        isfield(reopened.history{1}.cfg, 'ct')
    keptFile = reopened.history{1}.cfg.ct;
end
nFail = nFail + check(isequaln(keptFile, step1.cfg.ct), ...
    'the file names in a cfg survive as they were given', keptFile);

% everything else about the project is unchanged by carrying a history
nFail = nFail + check(isequaln(rmfield(reopened, 'history'), ...
        rmfield(withHistory, 'history')), ...
    'and nothing else in the project moved', '');

%% ----------------------------- stored as a string, held as a cell
fprintf('\n--- the shape on disk and the shape in memory ---------------\n');

stored = readFlat(stamped);
nFail = nFail + check(ischar(stored.history), ...
    'the file holds the history as one string', ...
    sprintf('%s, %d chars', class(stored.history), numel(stored.history)));
nFail = nFail + check(iscell(reopened.history), ...
    'and the project holds the cell the design specifies', ...
    'so project.history{3}.cfg still reads');

% JSONDECODE's own inconsistency: a JSON array whose objects all have the
% same fields comes back a STRUCT ARRAY, one whose objects differ comes back
% a CELL. Two identical ielec calls give the first, and the project's history
% has to be a cell either way.
same = struct('function', 'ielec.thresholdCT', ...
              'cfg',      struct('lowThreshold', 2500, 'highThreshold', 4000), ...
              'date',     '2026-10-09 10:00:00', 'version', '2.0');
uniform = project;
uniform.history = {same, same, same};
uniformFile = fullfile(outFolder, 'uniform.iel');
ielec.saveProject(struct('file', uniformFile), uniform, work, ui);
[backUniform, ~] = ielec.openProject(struct('file', uniformFile), [], []);
nFail = nFail + check(iscell(backUniform.history) && ...
        isequaln(backUniform.history, {same, same, same}), ...
    'three identical steps come back as a cell of three', ...
    sprintf('%s of %d', class(backUniform.history), numel(backUniform.history)));

% A file written between the commit that added the history and the one that
% started serialising it holds the cell itself. There are none outside a
% temporary folder, and reading them costs one branch.
oldShape = fullfile(outFolder, 'cellshape.iel');
flat = readFlat(stamped);
flat.history = {step1, step2};
saveFlat(oldShape, flat);
[backOld, ~] = ielec.openProject(struct('file', oldShape), [], []);
nFail = nFail + check(isequaln(backOld.history, {step1, step2}), ...
    'and a file holding the cell itself still opens', ...
    sprintf('%d steps', numel(backOld.history)));

%% --------------------------------------------- what it costs, and what it loses
fprintf('\n--- what a step costs --------------------------------------\n');

% Measured on the history itself rather than as a delta buried in a 47 MB
% file, where HDF5 block granularity dominates - and with DISTINCT steps,
% because a hundred identical ones deflate to almost nothing and give a
% figure that flatters the result. The one fixed number is the JSON length.
steps = cell(1, 100);
for k = 1:100
    steps{k} = struct('function', 'ielec.thresholdCT', ...
        'cfg',  struct('lowThreshold', 2000 + k, 'highThreshold', 4000 + 3*k), ...
        'date', sprintf('2026-10-09 %02d:%02d:00', mod(k,24), mod(k*7,60)), ...
        'version', '2.0');
end
perStepChars = numel(encodeHistory(steps)) / 100;
nFail = nFail + check(perStepChars > 50 && perStepChars < 300, ...
    'a recorded step is about 124 characters of JSON', ...
    sprintf('%.0f characters a step', perStepChars));

asString = fullfile(outFolder, 'asString.mat');
asCell   = fullfile(outFolder, 'asCell.mat');
saveHistory(asString, encodeHistory(steps));
saveHistory(asCell,   steps);
ratio = sizeOf(asCell) / sizeOf(asString);
nFail = nFail + check(ratio > 10, ...
    'and on disk it costs at least ten times less than the cell', ...
    sprintf('%d B against %d B, %.0f-fold', sizeOf(asString), sizeOf(asCell), ratio));

% What JSON carries and what it flattens, pinned here so that a change is
% noticed in this test rather than in somebody's history. docs/API_LAYER.md
% says the same in words.
drift = struct('function', 'ielec.fitArray', 'date', 'd', 'version', '2.0', ...
    'cfg', struct('name', 'LA', 'count', int32(8), 'spacing', 4.5, ...
                  'useNailed', true, 'nothing', [], 'row', [1 2 3], ...
                  'column', [1;2;3], 'unbounded', Inf, 'missing', NaN, ...
                  'window', [10 Inf]));
driftFile = fullfile(outFolder, 'drift.iel');
withDrift = project;  withDrift.history = {drift};
ielec.saveProject(struct('file', driftFile), withDrift, work, ui);
[backDrift, ~] = ielec.openProject(struct('file', driftFile), [], []);
c = backDrift.history{1}.cfg;

nFail = nFail + check(strcmp(c.name, 'LA') && isequal(c.spacing, 4.5) && ...
        islogical(c.useNailed) && c.useNailed && isempty(c.nothing), ...
    'a name, a number, a flag and an empty come back as they were', '');
nFail = nFail + check(isa(c.count, 'double') && isequal(c.count, 8), ...
    'an int32 comes back a double, by value', ...
    sprintf('int32(8) -> %s(%g)', class(c.count), c.count));

% Orientation, the right way round: a JSON array decodes to a COLUMN, so a
% row becomes a column and a column survives. The earlier version of this
% check used c.row(:)' and passed either way, while the doc beside it said
% the opposite of what happens.
nFail = nFail + check(isequal(size(c.row), [3 1]) && isequal(c.row, [1;2;3]), ...
    'a ROW vector comes back a column, values intact', ...
    sprintf('1x3 -> %s', mat2str(size(c.row))));
nFail = nFail + check(isequal(size(c.column), [3 1]) && isequal(c.column, [1;2;3]), ...
    'and a column survives as it was', ...
    sprintf('3x1 -> %s', mat2str(size(c.column))));

% Inf and NaN are LOST, not flattened - the one case where a value rather
% than a type goes. [NaN NaN NaN] is the documented default of
% options.image_voxdim, so this is not a corner case.
nFail = nFail + check(isempty(c.unbounded) && isempty(c.missing), ...
    'a scalar Inf or NaN comes back 0-by-0 - the value is gone', ...
    sprintf('Inf -> %s%s, NaN -> %s%s', class(c.unbounded), mat2str(size(c.unbounded)), ...
            class(c.missing), mat2str(size(c.missing))));
nFail = nFail + check(numel(c.window) == 2 && c.window(1) == 10 && ...
        isnan(c.window(2)), ...
    'and an Inf inside an array becomes NaN', mat2str(c.window'));

%% --------------------------- a step JSON cannot carry costs that step only
fprintf('\n--- and a save never fails because of a history -------------\n');

% JSON cannot encode a function handle. Before this, such a cfg aborted the
% save of the whole patient project and wrote no file at all.
hard = project;
hard.history = { ...
    struct('function', 'ielec.loadCT', 'cfg', struct('callback', @sin), ...
           'date', 'd', 'version', '2.0'), ...
    struct('function', 'ielec.cluster', 'cfg', struct('nClusters', 8), ...
           'date', 'd', 'version', '2.0')};
hardFile = fullfile(outFolder, 'unencodable.iel');

warnBefore = warning('off', 'all');
threw = '';
try
    ielec.saveProject(struct('file', hardFile), hard, work, ui);
catch err
    threw = err.identifier;
end
warning(warnBefore);

nFail = nFail + check(isempty(threw) && isfile(hardFile), ...
    'a function handle in a cfg does not stop the save', threw);

if isfile(hardFile)
    [backHard, ~] = ielec.openProject(struct('file', hardFile), [], []);
    nFail = nFail + check(numel(backHard.history) == 2 && ...
            isequaln(backHard.history{2}, hard.history{2}), ...
        'the step beside it is kept, cfg and all', ...
        sprintf('%d steps back', numel(backHard.history)));
    nFail = nFail + check(ischar(backHard.history{1}.cfg) && ...
            contains(backHard.history{1}.cfg, 'not recorded'), ...
        'and the one that could not be written says so', ...
        firstChars(backHard.history{1}.cfg, 48));
end

%% ----------------------------------------------- and 1.020 can open it
fprintf('\n--- iElectrodes 1.020 opening a v2 file --------------------\n');

v1 = findV1020(repoRoot);
if isempty(v1)
    fprintf(['  SKIPPED   no iElectrodes 1.020 copy beside the repository\n' ...
             '            (looked for ../iElectrodes_v1.020 and ../../iElectrodes_v1.020)\n']);
else
    [verdict, output] = askV1020(v1, stamped, outFolder);

    nFail = nFail + check(verdict.opened, ...
        '1.020 reads a file written by iElectrodes 2', ...
        lastLine(output));
    nFail = nFail + check(verdict.arrays == numel(project.electrodes) && ...
            verdict.targets == numel(project.targets), ...
        'with every electrode array and planning target', ...
        sprintf('%g arrays, %g targets', verdict.arrays, verdict.targets));

    % By content, not by count: a count would not notice 1.020 degrading
    % what is inside an array.
    [wantCoords, wantLabels] = contentOf(project.electrodes);
    nFail = nFail + check(nearly(verdict.coordSum, wantCoords), ...
        'and the contacts are where we wrote them', ...
        sprintf('coordinate sum %.10g', verdict.coordSum));
    nFail = nFail + check(verdict.labels == wantLabels, ...
        'with every channel label', ...
        sprintf('%g of %d', verdict.labels, wantLabels));

    % The third bullet of the design: a v2 file saved again from 1.020 loses
    % its history. Both halves measured - it is not in what 1.020 reads, and
    % not in what 1.020 would write back out. Compared against 0 rather than
    % tested for falsehood, so a child that printed nothing fails here
    % instead of passing.
    nFail = nFail + check(verdict.keptHistory == 0, ...
        '1.020 does not keep the history it was given', ...
        sprintf('isfield says %g', verdict.keptHistory));
    nFail = nFail + check(verdict.resaveHistory == 0, ...
        'and would not write one back out', ...
        sprintf('isfield says %g', verdict.resaveHistory));
end

%% ------------------------------------------------------------ no windows
fprintf('\n--- and nothing was drawn ----------------------------------\n');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the format carries a history, and 1.020 still opens it.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function v1 = findV1020(repoRoot)
% the copy the handoff keeps beside the repository
v1 = '';
for candidate = { fullfile(fileparts(repoRoot), 'iElectrodes_v1.020'), ...
                  fullfile(fileparts(fileparts(repoRoot)), 'iElectrodes_v1.020') }
    if isfolder(candidate{1}) && ...
            isfile(fullfile(candidate{1}, 'priv', 'backend', 'checkProjectStructure.m'))
        v1 = candidate{1};
        return
    end
end
end

function [verdict, output] = askV1020(v1, ielFile, outFolder)
% Run 1.020's reading core in a MATLAB of its own and bring back four
% numbers. Its own folders only: it carries the SPM it needs.
scriptFile = fullfile(outFolder, 'ask_v1020.m');

fid = fopen(scriptFile, 'w');
fprintf(fid, 'restoredefaultpath;\n');
fprintf(fid, 'addpath(genpath(%s));\n', quoted(fullfile(v1, 'priv')));
fprintf(fid, 'L = load(%s, ''-mat'');\n', quoted(ielFile));
fprintf(fid, 'iel = checkProjectStructure(L.s, struct());\n');
fprintf(fid, 'fprintf(''V1_OPENED=%%d\\n'', 1);\n');
fprintf(fid, 'fprintf(''V1_ARRAYS=%%d\\n'', numel(iel.electrodes));\n');
fprintf(fid, 'fprintf(''V1_TARGETS=%%d\\n'', numel(iel.targets));\n');
fprintf(fid, 'fprintf(''V1_HISTORY=%%d\\n'', isfield(iel, ''history''));\n');
% the contacts it actually got, and their labels
fprintf(fid, 'cs = 0; nl = 0;\n');
fprintf(fid, 'for a = 1:numel(iel.electrodes)\n');
fprintf(fid, '  e = iel.electrodes{a};\n');
fprintf(fid, '  cs = cs + sum(double([e.x(:); e.y(:); e.z(:)]));\n');
fprintf(fid, '  nl = nl + numel(e.ch_label);\n');
fprintf(fid, 'end\n');
fprintf(fid, 'fprintf(''V1_COORDSUM=%%.17g\\n'', cs);\n');
fprintf(fid, 'fprintf(''V1_LABELS=%%d\\n'', nl);\n');
% and what it would write back out: its Save calls the same check with one
% argument and saves what comes back
fprintf(fid, 'back = checkProjectStructure(iel);\n');
fprintf(fid, 'fprintf(''V1_RESAVE_HISTORY=%%d\\n'', isfield(back, ''history''));\n');
fclose(fid);

command = sprintf('"%s" -batch "run(''%s'')"', ...
    fullfile(matlabroot, 'bin', 'matlab'), scriptFile);
[~, output] = system(command);

verdict.opened        = ~isempty(regexp(output, 'V1_OPENED=1', 'once'));
verdict.arrays        = numberAfter(output, 'V1_ARRAYS=');
verdict.targets       = numberAfter(output, 'V1_TARGETS=');
verdict.keptHistory   = numberAfter(output, 'V1_HISTORY=');
verdict.resaveHistory = numberAfter(output, 'V1_RESAVE_HISTORY=');
verdict.coordSum      = numberAfter(output, 'V1_COORDSUM=');
verdict.labels        = numberAfter(output, 'V1_LABELS=');
end

function out = quoted(text)
out = ['''' strrep(text, '''', '''''') ''''];
end

function n = numberAfter(text, tag)
% NaN when the tag is absent, so a check against a number FAILS rather than
% passing on a child that printed nothing
n = NaN;
found = regexp(text, [tag '(\S+)'], 'tokens', 'once');
if ~isempty(found), n = str2double(found{1}); end
end

function [coordSum, labels] = contentOf(arrays)
coordSum = 0;  labels = 0;
for a = 1:numel(arrays)
    e = arrays{a};
    coordSum = coordSum + sum(double([e.x(:); e.y(:); e.z(:)]));
    labels   = labels   + numel(e.ch_label);
end
end

function yes = nearly(a, b)
yes = ~isnan(a) && abs(a - b) <= 1e-9 * max(1, abs(b));
end

function line = lastLine(text)
% the last line of what the other MATLAB said, which is where its error is
pieces = strtrim(splitlines(strtrim(text)));
pieces = pieces(~cellfun(@isempty, pieces));
if isempty(pieces), line = ''; else, line = pieces{end}; end
end

function s = readFlat(file)
loaded = load(file, '-mat');
s = loaded.s;
end

function saveFlat(file, s)
% s is used - SAVE takes it by name, which the Code Analyzer understands, so
% no pragma (one suppressing a message MATLAB does not emit becomes a message
% of its own)
save(file, 's', '-v7.3');
end

function n = sizeOf(file)
d = dir(file);
n = d.bytes;
end

function saveHistory(file, value)
% the history on its own, in the two fields the format adds
s = struct();
s.schemaVersion = 2;
s.history = value;
save(file, 's', '-v7.3');
end

function out = firstChars(text, n)
if numel(text) > n, out = [text(1:n) '...']; else, out = text; end
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end

function removeFolder(folder)
if isfolder(folder)
    rmdir(folder, 's');
end
end

function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-52s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-52s %s\n', what, detail);  bad = 1;
end
end
