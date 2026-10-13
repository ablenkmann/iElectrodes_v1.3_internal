function ok = test_ielecPlanningFiles()
%TEST_IELECPLANNINGFILES  Check ielec.saveTargets and ielec.loadTargets.
%
%   ok = test_ielecPlanningFiles() writes the example project's planning
%   targets through the layer and reads them back, and compares each
%   direction with the line the Save planning and Load planning buttons ran
%   themselves, kept verbatim below.
%
%   The two buttons were a file dialog, one call, and a redraw. What is
%   checked here is that the call is the same call: the same file comes out
%   of saving, and the same targets come out of loading, with the project
%   and the work left alone in every other respect.
%
%   Usage:  cd into the repository, then
%              test_ielecPlanningFiles
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.SAVETARGETS, IELEC.LOADTARGETS, SAVEPLANNINGTARGETS,
%   LOADPLANNINGTARGETS.

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

if isempty(project.targets)
    fprintf(['\nThe example project has nothing planned, so there is no plan ' ...
             'to write or read.\nNothing to check.\n\n']);
    ok = true; if nargout == 0, clear ok; end, return
end

outFolder = tempname;
mkdir(outFolder);
cleanup = onCleanup(@() removeFolder(outFolder)); %#ok<NASGU>

%% ------------------------------------------------- saving, against the button
fprintf('\n--- ielec.saveTargets against the Save planning button --------\n');

theirs = fullfile(outFolder, 'theirs.mat');
ours   = fullfile(outFolder, 'ours.mat');

originalSave(project.targets, [outFolder filesep], 'theirs.mat');

cfg = [];
cfg.file = ours;
[afterSave, afterSaveWork] = ielec.saveTargets(cfg, project, work);

nFail = nFail + check(isfile(ours), 'the file is written', 'ours.mat');

theirsRead = load(theirs, 'targets');
oursRead   = load(ours,   'targets');
sameName   = isequaln(fieldnames(oursRead), {'targets'});
nFail = nFail + check(sameName, ...
    'under the one variable name the reader looks for', 'targets');
nFail = nFail + check(sameName && isequaln(oursRead.targets, theirsRead.targets), ...
    'and holds what the button''s call wrote', ...
    sprintf('%d targets', numel(theirsRead.targets)));
nFail = nFail + check(isequaln(afterSave, project) && isequaln(afterSaveWork, work), ...
    'the project and the work come back untouched', '');

%% ------------------------------------------------ loading, against the button
fprintf('\n--- ielec.loadTargets against the Load planning button --------\n');

% a project whose plan is not the one in the file, so that replacing shows
emptied         = project;
emptied.targets = project.targets(1);

expected = originalLoad([outFolder filesep], 'theirs.mat');

cfg = [];
cfg.file = theirs;
[loaded, loadedWork] = ielec.loadTargets(cfg, emptied, work);

nFail = nFail + check(isequaln(loaded.targets, expected), ...
    'the targets the button read', sprintf('%d targets', numel(loaded.targets)));
nFail = nFail + check(numel(loaded.targets) == numel(project.targets) && ...
        numel(loaded.targets) ~= numel(emptied.targets), ...
    '   the plan in the project is replaced, not added to', '');
nFail = nFail + check(isequaln(withoutHistory(rmfield(loaded, 'targets')), withoutHistory(rmfield(emptied, 'targets'))), ...
    '   and nothing else in the project is touched', '');
nFail = nFail + check(isequaln(loadedWork, work), ...
    '   work is not changed', '');

%% ------------------------------------------------------------ the round trip
fprintf('\n--- out and back ---------------------------------------------\n');

roundFile = fullfile(outFolder, 'round.mat');
ielec.saveTargets(struct('file', roundFile), project, work);
[back, ~] = ielec.loadTargets(struct('file', roundFile), emptied, work);
nFail = nFail + check(isequaln(back.targets, project.targets), ...
    'what is written is what comes back', '');

%% ----------------------------------------------------------- what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

nFail = nFail + check(strcmp(errorId(@() ielec.saveTargets(struct(), project, work)), ...
        'ielec:missingOption'), 'saving without saying which file', 'cfg.file');
nFail = nFail + check(strcmp(errorId(@() ielec.loadTargets(struct(), project, work)), ...
        'ielec:missingOption'), 'loading without saying which file', 'cfg.file');
nFail = nFail + check(strcmp(errorId(@() ielec.saveTargets(struct('file', 7), ...
        project, work)), 'ielec:badOption'), 'a file name that is not a path', '');
nFail = nFail + check(strcmp(errorId(@() ielec.loadTargets(...
        struct('file', fullfile(outFolder, 'no_such.mat')), project, work)), ...
        'loadPlanningTargets:notFound'), ...
    'a file that is not there, said by the reader', '');

notAPlan = fullfile(outFolder, 'not_a_plan.mat');
somethingElse = 1:5; %#ok<NASGU>
save(notAPlan, 'somethingElse');
nFail = nFail + check(strcmp(errorId(@() ielec.loadTargets(struct('file', notAPlan), ...
        project, work)), 'loadPlanningTargets:noTargets'), ...
    'a .mat that is not a planning file', '');

nFail = nFail + check(strcmp(errorId(@() ielec.saveTargets(...
        struct('file', fullfile(outFolder, 'no_such_folder', 'x.mat')), project, work)), ...
        'ielec:noSuchFolder'), 'a folder that does not exist', '');

noPlan         = project;
noPlan.targets = {};
nFail = nFail + check(strcmp(errorId(@() ielec.saveTargets(struct('file', ours), ...
        noPlan, work)), 'ielec:noTargets'), ...
    'saving a project with nothing planned', '');

nFail = nFail + check(strcmp(errorId(@() ielec.saveTargets(...
        struct('file', ours, 'targets', 1), project, work)), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.targets');

%% ------------------------------------------------------------- layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.saveTargets) == 3 && nargout(@ielec.saveTargets) == 2, ...
    '(cfg, project, work) for the one that writes', 'saveTargets');
nFail = nFail + check(nargin(@ielec.loadTargets) == 3 && nargout(@ielec.loadTargets) == 2, ...
    'and for the one that reads', 'loadTargets');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the planning files are the ones the buttons wrote and read.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% The two lines the planning buttons ran once the user had chosen a file.
% PathName comes from the dialog and ends in a separator, which is why the
% file name is joined to it the way it is here.

function originalSave(targets, PathName, FileName)
    savePlanningTargets(targets, [PathName, FileName]);
end

function targets = originalLoad(PathName, FileName)
    targets = loadPlanningTargets([PathName, FileName]);
end

% ---------------------------------------------------------------------
function removeFolder(folder)
if ~isfolder(folder), return, end
try
    rmdir(folder, 's');
catch
    fclose('all');
    try
        rmdir(folder, 's');
    catch err
        fprintf('  (could not remove %s: %s)\n', folder, err.message);
    end
end
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
