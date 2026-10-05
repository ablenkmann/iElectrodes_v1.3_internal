function ok = test_ielecPointLabel()
%TEST_IELECPOINTLABEL  Check ielec.pointLabel against the coordinate box.
%
%   ok = test_ielecPointLabel() asks the layer what region a point is in and
%   compares the answer with the block that ran on every cursor move, kept
%   verbatim at the end of this file. Both atlases are covered: the patient's
%   parcellation, from the native-space example, and the template one, from
%   the MNI example with the Harvard-Oxford atlas loaded the way the GUI
%   loads it at start-up.
%
%   The point it asks about is the middle of the volume - where the GUI puts
%   the cursor when a project opens - rather than a contact, so that the test
%   does not depend on which array is first or on a contact lying inside the
%   parcellation (docs/OPEN_QUESTIONS.md item 3).
%
%   The one thing the layer does that the block did not is say which atlas
%   answered, or that neither did, so that the frontend can decide what to
%   write in the box. That is checked in all three cases.
%
%   Usage:  cd into the repository, then
%              test_ielecPointLabel
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.POINTLABEL, ANATOMICLABEL, ANATOMICLABELFS.

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
project.currentSpace = 'Native';   % this half is about the parcellation

% the middle of the volume, in the coordinates the cursor uses
middle = mesh2AnatSpace(size(project.T1.img)/2, project.S2);

%% --------------------------------------- the patient's own parcellation
fprintf('\n--- ielec.pointLabel against the coordinate box ---------------\n');

hasParcellation = isfield(project, 'wmparc') && ~isempty(project.wmparc);
if ~hasParcellation
    fprintf('  (the example carries no parcellation - that part is skipped)\n');
else
    expected = originalBox(project, work, middle, 1);

    cfg = [];
    cfg.coordinate = middle;
    [same, sameWork, report] = ielec.pointLabel(cfg, project, work);

    nFail = nFail + check(isequaln(report.label, expected.label), ...
        'the label is the one the box showed', firstOf(report.label));
    nFail = nFail + check(strcmp(report.source, 'parcellation') && ...
            ~isempty(report.label), ...
        'and it says which atlas answered', report.source);
    nFail = nFail + check(isequaln(same, project) && isequaln(sameWork, work), ...
        'nothing is changed - it only answers', '');

    % the cube around the point is one branch of the backend, the single
    % voxel it lands in the other, and cfg.lookAround is what picks
    expectedExact = originalBox(project, work, middle, 0);
    [~, ~, exact]  = ielec.pointLabel(struct('coordinate', middle, 'lookAround', false), ...
                                       project, work);

    nFail = nFail + check(isequaln(exact.label, expectedExact.label), ...
        'one voxel rather than a cube, as the backend does it', ...
        firstOf(exact.label));

    % several points at once. The answer has one row per point, and more
    % than one column when the atlas is asked for probabilities
    threePoints = mesh2AnatSpace(size(project.T1.img)/2 + [0 0 0; 2 0 0; 0 2 0], ...
                                project.S2);
    [~, ~, many] = ielec.pointLabel(struct('coordinate', threePoints), project, work);
    nFail = nFail + check(size(many.label, 1) == 3, ...
        'three points give three rows', ...
        sprintf('%s', mat2str(size(many.label))));
end

%% ------------------------------------------------- the template atlas
fprintf('\n--- and in MNI space -----------------------------------------\n');

mniFile = fullfile(repoRoot, 'examples', 'exampleMNIspace.iel');
if ~isfile(mniFile)
    fprintf('  (there is no MNI example project - that part is skipped)\n');
else
    [mniProject, mniWork] = ielec.openProject(struct('file', mniFile), [], []);

    % the atlas, loaded the way defaultGuiVariables loads it at start-up
    atlas = load('HOatlas_cort-subCort_lateralized.mat');   % labels, prob, S
    mniWork.MNI_S_matrix = atlas.S;
    mniWork.MNIlabels    = atlas.labels;
    mniWork.MNIprob      = atlas.prob;

    % a contact of the first array: in MNI space, and inside the atlas
    firstArray = mniProject.electrodes{1};
    inBrain    = [firstArray.x(1) firstArray.y(1) firstArray.z(1)];

    expected = originalBox(mniProject, mniWork, inBrain, 1);
    [~, ~, report] = ielec.pointLabel(struct('coordinate', inBrain), mniProject, mniWork);

    nFail = nFail + check(isequaln(report.label, expected.label), ...
        'the template atlas answers as the box had it', firstOf(report.label));
    nFail = nFail + check(strcmp(report.source, 'MNI') && ...
            ~isempty(report.label), ...
        'and the report says which atlas that was', report.source);

    nFail = nFail + check(strcmp(errorId(@() ielec.pointLabel(...
                                                               struct('coordinate', inBrain), ...
                                                               mniProject, ...
                                                               rmfield(mniWork, 'MNIprob'))), ...
            'ielec:noAtlas'), ...
        'MNI space with no atlas loaded says so', 'ielec:noAtlas');
end

%% --------------------------------------------------------- no atlas at all
fprintf('\n--- with no atlas to ask -------------------------------------\n');

bare = project;
bare.wmparc       = [];
bare.currentSpace = 'Native';

[~, ~, report] = ielec.pointLabel(struct('coordinate', middle), bare, work);
nFail = nFail + check(strcmp(report.source, 'none') && isempty(report.label), ...
    'nothing is asked and nothing is claimed', report.source);

if isfield(bare, 'wmparc')
    [~, ~, noField] = ielec.pointLabel(struct('coordinate', middle), ...
                                        rmfield(bare, 'wmparc'), work);
    nFail = nFail + check(strcmp(noField.source, 'none'), ...
        'and a project without the field at all is the same', noField.source);
end

%% -------------------------------------------------------------- what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

nFail = nFail + check(strcmp(errorId(@() ielec.pointLabel([], project, work)), ...
        'ielec:missingOption'), ...
    'a call with no point', 'cfg.coordinate');
nFail = nFail + check(strcmp(errorId(@() ielec.pointLabel(struct('coordinate', [1 2]), ...
                                                           project, work)), 'ielec:badOption'), ...
    'a point that is not three coordinates', '');
nFail = nFail + check(strcmp(errorId(@() ielec.pointLabel(struct('coordinate', [1 2 NaN]), ...
                                                           project, work)), 'ielec:badOption'), ...
    'a coordinate that is not a number', 'NaN');
nFail = nFail + check(strcmp(errorId(@() ielec.pointLabel(...
        struct('coordinate', middle, 'lookAround', NaN), project, work)), 'ielec:badOption'), ...
    'a lookAround that is neither on nor off', 'NaN');
nFail = nFail + check(strcmp(errorId(@() ielec.pointLabel(...
        struct('coordinate', middle, 'radio', 2), project, work)), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.radio');

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.pointLabel) == 3 && ...
        nargout(@ielec.pointLabel) == 3, ...
    'the signature, the answer as the third output', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the point is labelled as the coordinate box labelled it.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% What ran in updatePlot on every cursor move, with the text box taken out and
% the lookAround it hardcoded as 1 passed in instead, so that both branches of
% ANATOMICLABELFS can be compared.

function out = originalBox(project, work, cursor, lookAround)
    handles.project = project;
    handles.work    = work;
    handles.ui.cursor = cursor;

    aL = [];
    if strcmp(handles.project.currentSpace, 'MNI')
        aL=anatomicLabel(handles.ui.cursor,handles.work.MNI_S_matrix,handles.work.MNIlabels,handles.work.MNIprob);
    elseif ~isempty(handles.project.wmparc) % Native space
        opt.radio=handles.work.options.atlasLabelingRadio;
        opt.mode=handles.work.options.atlasLabelingMode;
        opt.minProb=handles.work.options.atlasLabelingMinProb;

        aL=anatomicLabelFS(handles.ui.cursor,[],handles.work.options.atlasLUTFile,lookAround,handles.project.wmparc.img,handles.project.wmparcS,[],[],opt);
    end

    out.label = aL;
end

% ---------------------------------------------------------------------
function text = firstOf(label)
text = '';
if iscell(label) && ~isempty(label)
    text = label{1};
elseif ischar(label)
    text = label;
end
if ~ischar(text), text = class(text); end
if numel(text) > 40, text = [text(1:37) '...']; end
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
