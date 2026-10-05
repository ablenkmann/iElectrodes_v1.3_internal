function ok = test_ielecArrays()
%TEST_IELECARRAYS  Check ielec.acceptArray and ielec.label.
%
%   ok = test_ielecArrays() adds an array to the example project with
%   ielec.acceptArray and labels the project with ielec.label, and compares
%   both with the code they replace in addElectrode2structure and in the two
%   labelling wrappers, kept verbatim below.
%
%   Usage:  cd into the repository, then
%              test_ielecArrays
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.ACCEPTARRAY, IELEC.LABEL, ADDARRAY, LABELELECTRODESNATIVE.

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

% what a GUI holds in the middle of a localization
work.GS          = rand(4,3);
work.brushCrd    = rand(40,3);
work.brushWeight = rand(40,1);
work.clusters    = repmat((1:4)', 10, 1);

%% ------------------------------------------ acceptArray, a new array
fprintf('\n--- ielec.acceptArray against the Add step -------------------\n');

newArray      = project.electrodes{1};
newArray.Name = 'a copy, added';

expected = originalAdd(project, work, newArray, []);
[added, addedWork, index] = ielec.acceptArray([], project, work, newArray);

nFail = nFail + check(isequaln(added.electrodes, expected.project.electrodes) && ...
        index == numel(expected.project.electrodes), ...
    'the array is added where the Add step added it', sprintf('array %d', index));
nFail = nFail + check(isequaln(addedWork, expected.work), ...
    'work is what the Add step left', '');
nFail = nFail + check(isempty(addedWork.GS) && isempty(addedWork.brushCrd) && ...
        isempty(addedWork.brushWeight) && isempty(addedWork.clusters), ...
    'the contacts in progress are cleared', '');
nFail = nFail + check(isequal(addedWork.oldGS, work.GS) && ...
        isequal(addedWork.oldclusters, work.clusters), ...
    'and kept for Undo', sprintf('%d contacts', size(work.GS,1)));

%% ------------------------------------------ acceptArray, replacing one
fprintf('\n--- ielec.acceptArray replacing an array ---------------------\n');

expectedReplace = originalAdd(project, work, newArray, 2);
[replaced, replacedWork] = ielec.acceptArray(struct('index', 2), project, work, newArray);

nFail = nFail + check(isequaln(replaced.electrodes, expectedReplace.project.electrodes) && ...
        numel(replaced.electrodes) == numel(project.electrodes), ...
    'the array replaces that one, and no other', sprintf('%d arrays', numel(replaced.electrodes)));
nFail = nFail + check(isequaln(replacedWork, work), ...
    'replacing leaves the work in progress alone', '');

%% --------------------------------------------------------- what is refused
nFail = nFail + check(strcmp(errorId(@() ielec.acceptArray([], project, work, 'not an array')), ...
        'ielec:badArray'), 'something that is not an array', '');
nFail = nFail + check(strcmp(errorId(@() ielec.acceptArray(...
        struct('index', numel(project.electrodes)+1), project, work, newArray)), 'ielec:badOption'), ...
    'an index that is not one of the arrays', '');
nFail = nFail + check(strcmp(errorId(@() ielec.acceptArray(struct('array', 1), project, ...
                                                            work, newArray)), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.array');

%% ------------------------------------------------- label, in native space
fprintf('\n--- ielec.label against the labelling wrappers ---------------\n');

expectedNative = originalLabelNative(project, work);
[labelledNative, workAfter] = ielec.label([], project, work);

nFail = nFail + check(isequaln(labelledNative.electrodes, expectedNative.electrodes) && ...
        isequaln(labelledNative.targets, expectedNative.targets), ...
    'native labels are what the wrapper produced', ...
    firstLabel(labelledNative));
nFail = nFail + check(isequaln(workAfter, work), 'work is not changed', '');
nFail = nFail + check(isequaln(rmfield(labelledNative, {'electrodes','targets'}), ...
        rmfield(project, {'electrodes','targets'})), ...
    'and nothing else in the project is', '');

%% ---------------------------------------------------- label, in MNI space
fprintf('\n--- and in MNI space -----------------------------------------\n');

% a project whose coordinates are in MNI space, and the atlas the GUI loads
% once at start-up
cfgMNI = [];
cfgMNI.file = fullfile(repoRoot, 'examples', 'exampleMNIspace.iel');
[mniProject, mniWork] = ielec.openProject(cfgMNI, [], []);

atlas = load('HOatlas_cort-subCort_lateralized.mat');
mniWork.MNIlabels    = atlas.labels;
mniWork.MNIprob      = atlas.prob;
mniWork.MNI_S_matrix = atlas.S;

expectedMNI  = originalLabelMNI(mniProject, mniWork);
labelledMNI  = ielec.label(struct('space','MNI'), mniProject, mniWork);

nFail = nFail + check(isequaln(labelledMNI.electrodes, expectedMNI.electrodes) && ...
        isequaln(labelledMNI.targets, expectedMNI.targets), ...
    'MNI labels are what the wrapper produced', firstLabel(labelledMNI));

nFail = nFail + check(strcmp(errorId(@() ielec.label(struct('space','MNI'), mniProject, ...
                                                      work)), 'ielec:noAtlas'), ...
    'MNI labelling without the atlas says so', '');
nFail = nFail + check(strcmp(errorId(@() ielec.label(struct('space','Talairach'), project, ...
                                                      work)), 'ielec:badOption'), ...
    'a space that is not Native or MNI', '');

%% --------------------------------------------------------- layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.label) == 3 && nargout(@ielec.label) == 2 && ...
        nargin(@ielec.acceptArray) == 4 && nargout(@ielec.acceptArray) == 3, ...
    'the signatures, with the array after the three', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - arrays are added and labelled as the GUI did.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% addElectrode2structure's own steps, without the drawing, and the two
% labelling wrappers.

function handles = originalAdd(project, work, electrodes, array)
    handles.project = project;
    handles.work    = work;

    % append when ARRAY is empty, overwrite that index otherwise
    [handles.project.electrodes, l] = addArray(handles.project.electrodes, electrodes, array); %#ok<NASGU>

    if isempty(array) % add array to structure
        %save to old coordinates
        handles.work.oldGS=handles.work.GS;
        handles.work.oldbrushCrd=handles.work.brushCrd;
        handles.work.oldbrushWeight=handles.work.brushWeight;
        handles.work.oldclusters=handles.work.clusters;

        % clear actual ones
        handles.work.GS=[];
        handles.work.brushCrd=[];
        handles.work.brushWeight=[];
        handles.work.clusters=[];
    end
end

function project = originalLabelNative(project, work)
    prj         = project;
    prj.options = work.options;

    prj = labelElectrodesNative(prj);

    project.electrodes = prj.electrodes;
    project.targets    = prj.targets;
end

function project = originalLabelMNI(project, work)
    prj              = project;
    prj.MNI_S_matrix = work.MNI_S_matrix;
    prj.MNIlabels    = work.MNIlabels;
    prj.MNIprob      = work.MNIprob;

    prj = labelElectrodesMNI(prj);

    project.electrodes = prj.electrodes;
    project.targets    = prj.targets;
end

% ---------------------------------------------------------------------
function text = firstLabel(project)
% the first contact's label, to show that there is one
text = '';
if ~isempty(project.electrodes) && isfield(project.electrodes{1}, 'aLabels') && ...
        ~isempty(project.electrodes{1}.aLabels)
    text = project.electrodes{1}.aLabels{1,1};
end
end

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
