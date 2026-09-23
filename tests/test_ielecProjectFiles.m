function ok = test_ielecProjectFiles()
%TEST_IELECPROJECTFILES  Check ielec.openProject and ielec.saveProject.
%
%   ok = test_ielecProjectFiles() opens the two example projects with
%   ielec.openProject and compares the result with the Open button's
%   original steps, kept verbatim below, colour caches included. It checks
%   that ielec.saveProject writes the same file the Save button wrote, that a
%   saved project opens again unchanged, that a script can save without
%   colour caches, and the rules of the layer.
%
%   It also shows OPEN_QUESTIONS item 25: after one project, the original
%   steps open a file whose parcellation is stored empty with the previous
%   project's parcellation still in it. ielec.openProject does not.
%
%   It writes project files to a temporary folder, removed at the end, and
%   takes a little while: the example projects are large.
%
%   Usage:  cd into the repository, then
%              test_ielecProjectFiles
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.OPENPROJECT, IELEC.SAVEPROJECT.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

folder = fullfile(tempdir, ['iElectrodes_test_ielecfiles_' char(java.util.UUID.randomUUID)]);
mkdir(folder);
removeLater = onCleanup(@() rmdir(folder, 's'));

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));
examples = fullfile(repoRoot, 'examples');

% What a running GUI holds when Open is pressed, after the display reset:
% a fresh project, the options, the shared resources, nothing selected,
% and a session setting that must survive.
fresh = liftToUi(liftToWork(liftToProject(checkProjectStructure([], struct()))));
fresh.work.options      = default_ielectrodes_options([]);
fresh.work.v_MNI        = 'shared resource, must survive';
fresh.work.localization = struct('thresholdLow', 1234);
fresh.work.selection    = struct('array',0,'contact',0,'planningArray',0,'planningTarget',0);

%% ------------------------------------------ the same as the Open button
for name = {'exampleNativeSpace.iel', 'exampleMNIspace.iel'}
    fprintf('\n--- ielec.openProject: %s -------------------\n', name{1});

    expected = originalOpen(fresh, [examples filesep], name{1});

    cfg = [];
    cfg.file = fullfile(examples, name{1});
    [project, work, caches] = ielec.openProject([], fresh.work, cfg);

    nFail = nFail + check(isequaln(project, expected.project), ...
        'project is what the Open button built', ...
        sprintf('%d arrays, %d planning', numel(project.electrodes), numel(project.targets)));
    nFail = nFail + check(isequaln(rmfield(work,'selection'), rmfield(expected.work,'selection')), ...
        'work is what the Open button built', '');
    n = double(~isempty(project.electrodes));  m = double(~isempty(project.targets));
    nFail = nFail + check(isequal(work.selection, ...
            struct('array',n,'contact',n,'planningArray',m,'planningTarget',m)), ...
        'the first array and planning array are selected', '');
    nFail = nFail + check(strcmp(work.v_MNI, fresh.work.v_MNI) && ...
            isequal(work.localization, fresh.work.localization), ...
        'what the file does not hold stays in work', '');

    same = true;
    for c = uiFieldNames()
        same = same && isequaln(caches.(c{1}), expected.ui.(c{1}));
    end
    nFail = nFail + check(same && numel(fieldnames(caches)) == numel(uiFieldNames()), ...
        'the colour caches are what the Open button put in ui', '');

    if strcmp(name{1}, 'exampleNativeSpace.iel')
        native = expected;        % kept for the checks below
    end
end

%% ------------------------------------------ the same as the Save button
fprintf('\n--- ielec.saveProject against the Save button -----------------\n');

buttonFile = fullfile(folder, 'byButton.iel');
originalSave(native, buttonFile);

caches = struct();
for c = uiFieldNames(), caches.(c{1}) = native.ui.(c{1}); end
cfg = []; cfg.file = fullfile(folder, 'byLayer.iel');
[p2, w2] = ielec.saveProject(native.project, native.work, cfg, caches);

a = load(buttonFile, '-mat');  b = load(cfg.file, '-mat');
nFail = nFail + check(isequaln(a.s, b.s), 'the file is what the Save button wrote', ...
    sprintf('%d fields', numel(fieldnames(b.s))));
nFail = nFail + check(isequaln(p2, native.project), 'the project comes back unchanged', '');
nFail = nFail + check(strcmp(w2.FileName, 'byLayer.iel') && strcmp(w2.PathName, [folder filesep]), ...
    'work records the new file', '');
nFail = nFail + check(isequal(b.s.FileName, native.work.FileName), ...
    'the file records the name it had before, as the button did', b.s.FileName);

cfg2 = []; cfg2.file = cfg.file;
reopened = ielec.openProject([], w2, cfg2);
nFail = nFail + check(isequaln(reopened, native.project), 'saved and opened again unchanged', '');

% a script saves without colour caches: they are computed
cfg4 = []; cfg4.file = fullfile(folder, 'byScript.iel');
ielec.saveProject(native.project, native.work, cfg4);
cfg4.file = fullfile(folder, 'byScript.iel');
[fromScript, ~, scriptCaches] = ielec.openProject([], w2, cfg4);
nFail = nFail + check(isequaln(fromScript, native.project) && ...
        ~isempty(scriptCaches.AnnotColor_R), ...
    'saved without caches, they are computed', '');

%% --------------------------------------------------------- item 25
fprintf('\n--- a file with an empty parcellation, opened after one with ----\n');

% iElectrodes' own save drops an empty parcellation from the file, so this
% file is made by hand: the same project, with wmparc stored empty.
s = a.s;
s.wmparc = [];  s.wmparcS = [];
emptyParcFile = fullfile(folder, 'emptyParcellation.iel');
save(emptyParcFile, 's', '-v7.3');

stale = originalOpen(native, [folder filesep], 'emptyParcellation.iel');
nFail = nFail + check(~isempty(stale.project.wmparc), ...
    'the original steps keep the previous parcellation', 'item 25 - the fault');

cfg3 = []; cfg3.file = emptyParcFile;
opened = ielec.openProject([], native.work, cfg3);
nFail = nFail + check(isempty(opened.wmparc) && isempty(opened.wmparcS), ...
    'ielec.openProject does not', 'item 25');

%% -------------------------------------------------------------- errors
fprintf('\n--- what is refused -------------------------------------------\n');

nFail = nFail + check(strcmp(errorId(@() ielec.openProject([], [], ...
        struct('file', fullfile(folder, 'no_such.iel')))), 'ielec:noSuchFile'), ...
    'open: a missing file', '');
notAProject = fullfile(folder, 'notes.iel');
fid = fopen(notAProject, 'w');  fprintf(fid, 'not a project');  fclose(fid);
nFail = nFail + check(strcmp(errorId(@() ielec.openProject([], [], ...
        struct('file', notAProject))), 'ielec:notAProject'), ...
    'open: a file that is not a project', '');
nFail = nFail + check(strcmp(errorId(@() ielec.openProject([], [], ...
        struct('file', buttonFile, 'fiel', 1))), 'ielec:unknownOption'), ...
    'open: an unknown option', 'cfg.fiel');
empty = liftToWork(liftToProject(checkProjectStructure([], struct())));
nFail = nFail + check(strcmp(errorId(@() ielec.saveProject(empty.project, empty.work, ...
        struct('file', fullfile(folder, 'x.iel')))), 'ielec:emptyProject'), ...
    'save: a project with no MRI', '');
nFail = nFail + check(strcmp(errorId(@() ielec.saveProject(native.project, native.work, ...
        struct('file', fullfile(folder, 'no_such_folder', 'x.iel')))), 'ielec:noSuchFolder'), ...
    'save: a folder that does not exist', '');

%% --------------------------------------------------------- layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.openProject) == 3 && nargout(@ielec.openProject) == 3 && ...
        nargin(@ielec.saveProject) == 4 && nargout(@ielec.saveProject) == 2, ...
    '(project, work, cfg), plus the colour caches', 'open, save');
nFail = nFail + check(nargin(@ielec.colourCaches) == 3 && nargout(@ielec.colourCaches) == 3, ...
    '[project, work, report] for one that only reports', 'colourCaches');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the layer opens and saves projects as the buttons did.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% The Open and Save buttons before the layer, with the file dialogs' answers
% given as arguments. defaultGuiVariables is left out of Open: the state
% passed in is what it leaves.

function handles = originalOpen(handles, PathName, FileName)
    s = readIelFile([PathName, FileName]);
    handles=checkProjectStructure(s,handles);
    handles=liftToProject(handles);   % patient data     -> handles.project
    handles=liftToWork(handles);      % work in progress -> handles.work
    handles=liftToUi(handles);        % colour caches    -> handles.ui

    handles.work.FileName=FileName;
    handles.work.PathName=PathName;
end

function originalSave(handles, file)
    writeIelFile(file, handles.project, handles.work, handles.ui);
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
