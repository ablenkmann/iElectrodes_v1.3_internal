function ok = test_ielecStartSession()
%TEST_IELECSTARTSESSION  Check ielec.startSession and ielec.setOptions.
%
%   ok = test_ielecStartSession() builds a session through the layer and
%   compares the three groups with the five calls the GUI made on its way up,
%   kept verbatim at the end of this file.
%
%   It also checks the two things the layer promises about them: that every
%   field goes to the group its name list puts it in, and that work is filled
%   rather than replaced, so that what the caller already had in it survives.
%
%   Usage:  cd into the repository, then
%              test_ielecStartSession
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.STARTSESSION, IELEC.SETOPTIONS, CHECKPROJECTSTRUCTURE.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

%% ------------------------------------------- the same as the GUI's way up
fprintf('\n--- ielec.startSession against the opening function -----------\n');

expected = originalStartUp(repoRoot);

[project, work, caches] = ielec.startSession([], [], []);

nFail = nFail + check(isequaln(withoutHistory(project), withoutHistory(expected.project)), ...
    'the empty project is the one the GUI started with', ...
    sprintf('%d fields', numel(fieldnames(project))));
nFail = nFail + check(isequaln(caches, expected.ui), ...
    'and the colour caches are the ones it handed to ui', ...
    strjoin(fieldnames(caches)', ', '));

% work: the GUI's copy carries the path it set before the call, so compare
% the fields the session itself makes
sessionWork = rmfield(work, intersect(fieldnames(work), {'pathstr'}));
expectedWork = rmfield(expected.work, ...
    intersect(fieldnames(expected.work), {'pathstr'}));
nFail = nFail + check(isequaln(sessionWork, expectedWork), ...
    'and work is what its five calls left', ...
    sprintf('%d fields', numel(fieldnames(sessionWork))));

%% --------------------------------------------------- every field in a group
fprintf('\n--- where each field went ------------------------------------\n');

fromStructure = fieldnames(checkProjectStructure([], []));
inGroups      = [fieldnames(project); fieldnames(work); fieldnames(caches)];

% fname is the one field the structure makes that no list claims, and only
% for an old project whose mask is a raw image (docs/OPEN_QUESTIONS.md
% item 33). An empty session never has it.
nFail = nFail + check(~any(strcmp(fromStructure, 'fname')), ...
    'an empty session has no unclaimed field', '');
nFail = nFail + check(isempty(setdiff(fromStructure, inGroups)), ...
    'every field of the empty structure is in one of the three groups', ...
    strjoin(setdiff(fromStructure, inGroups)', ', '));
nFail = nFail + check(isempty(intersect(fieldnames(project), fieldnames(caches))), ...
    'and no field is in two of them', '');

nFail = nFail + check(all(ismember(uiFieldNames(), fieldnames(caches))), ...
    'the caches are the fields UIFIELDNAMES names', ...
    strjoin(uiFieldNames(), ', '));
nFail = nFail + check(isstruct(work.options) && ...
        isfield(work.options, 'image_voxdim'), ...
    'and the scientific options are in work', 'work.options');

%% ------------------------------------------------- work is kept, not replaced
fprintf('\n--- what the caller already had -------------------------------\n');

had = struct();
had.pathstr  = 'C:\somewhere\iElectrodes';
had.MNIlabels = {'one', 'two'};
[~, keptWork] = ielec.startSession([], [], had);

nFail = nFail + check(strcmp(keptWork.pathstr, had.pathstr) && ...
        isequal(keptWork.MNIlabels, had.MNIlabels), ...
    'what work already held is still there', 'pathstr, MNIlabels');
nFail = nFail + check(isfield(keptWork, 'options'), ...
    'and the session''s own fields are around it', '');

%% ----------------------------------------------------------- the options
fprintf('\n--- ielec.setOptions -----------------------------------------\n');

[~, reloaded] = ielec.setOptions([], project, work);
nFail = nFail + check(isequaln(reloaded.options, default_ielectrodes_options([])), ...
    'reloading gives what the configuration file says', '');

overriden = struct('image_voxdim', [0.5 0.5 0.5]);
[sameProject, changed] = ielec.setOptions(struct('options', overriden), project, work);
nFail = nFail + check(isequal(changed.options.image_voxdim, [0.5 0.5 0.5]), ...
    'and an override survives the defaults around it', ...
    mat2str(changed.options.image_voxdim));
nFail = nFail + check(isequaln(withoutHistory(sameProject), withoutHistory(project)), ...
    'the project is not touched', '');

%% -------------------------------------------------------------- what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

nFail = nFail + check(strcmp(errorId(@() ielec.startSession(struct('options', 'defaults'), ...
                                                             [], [])), 'ielec:badOption'), ...
    'options that are not a struct', 'cfg.options');
nFail = nFail + check(strcmp(errorId(@() ielec.startSession(struct('colors', 1), [], [])), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.colors');
nFail = nFail + check(strcmp(errorId(@() ielec.setOptions(struct('option', 1), [], [])), 'ielec:unknownOption'), ...
    'and by setOptions too', 'cfg.option');

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.startSession) == 3 && ...
        nargout(@ielec.startSession) == 3, ...
    'the signature, the caches as the third output', '');
nFail = nFail + check(nargin(@ielec.setOptions) == 3 && ...
        nargout(@ielec.setOptions) == 2, ...
    'and setOptions returns the two groups', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - a session starts as the GUI started one.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% What electrodes_gui_OpeningFcn ran to build the three groups, with the
% graphics handles it also carried left out.

function out = originalStartUp(repoRoot)
    handles = struct();
    [handles.work.pathstr,~,~] = fileparts(fullfile(repoRoot, 'electrodes_gui.m'));

    % make project structure
    handles=checkProjectStructure([],handles);

    handles=liftToProject(handles);   % patient data     -> handles.project
    handles=liftToWork(handles);      % work in progress -> handles.work
    handles=liftToUi(handles);        % colour caches    -> handles.ui

    options=[];
    handles.work.options = default_ielectrodes_options(options);

    out.project = handles.project;
    out.work    = handles.work;
    out.ui      = handles.ui;
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
