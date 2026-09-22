function ok = test_scriptEntryPoints()
%TEST_SCRIPTENTRYPOINTS  Check what a script needed that only the GUI had.
%
%   ok = test_scriptEntryPoints() checks LOADPROJECT, GRIDFITOPTIONS and
%   VOXELWEIGHTS, and WRITEIELFILE called without the GUI's ui structure.
%   All four were found while writing examples/exampleHeadlessWorkflow.m:
%   without the first three a script had to copy code out of the Open
%   button, the Fit button and getThresholdedVoxels, and saving from a script
%   failed outright. GRIDFITOPTIONS and VOXELWEIGHTS are compared with the
%   code they came from, kept verbatim below. No figure is opened.
%
%   Usage:  cd into the repository, then
%              test_scriptEntryPoints
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also LOADPROJECT, GRIDFITOPTIONS, VOXELWEIGHTS.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

ielFile = fullfile(repoRoot,'examples','exampleNativeSpace.iel');
nFail = 0;

%% ------------------------------------------------------------ loadProject
fprintf('\n--- loadProject ----------------------------------------------\n');

[project, work] = loadProject(ielFile);

% the same steps the Open button takes, done by hand
loaded = load(ielFile, '-mat');
state  = checkProjectStructure(loaded.s, struct());
state  = liftToWork(liftToProject(state));

nFail = nFail + check(isequaln(project, state.project), ...
    'project is what the Open button builds', sprintf('%d fields', numel(fieldnames(project))));
workNoOptions = rmfield(work, 'options');
nFail = nFail + check(isequaln(workNoOptions, state.work), ...
    'work is what the Open button builds', '');
nFail = nFail + check(isequaln(work.options, default_ielectrodes_options([])), ...
    'work.options holds the defaults, as after starting', '');
nFail = nFail + check(~isfield(project,'options') && ~isfield(project,'maxValue'), ...
    'settings and caches are not in project', '');
nFail = nFail + check(~isempty(project.TAC) && ~isempty(project.electrodes), ...
    'the CT and the electrodes came through', sprintf('%d arrays', numel(project.electrodes)));

threw = '';
try
    loadProject(fullfile(tempdir, 'there_is_no_such_project.iel'));
catch err
    threw = err.identifier;
end
nFail = nFail + check(strcmp(threw, 'readIelFile:noSuchFile'), ...
    'a missing file is refused by name', threw);

%% ------------------------------------------ writeIelFile, without the GUI
fprintf('\n--- writeIelFile without ui, as a script calls it ------------\n');

savedFile = [tempname '.iel'];
removeSaved = onCleanup(@() deleteIfThere(savedFile));

threw = '';
try
    writeIelFile(savedFile, project, work);   % no ui: what a script does
catch err
    threw = err.message;
end
nFail = nFail + check(isempty(threw), 'a project with annotations saves without ui', threw);

if isempty(threw)
    written = load(savedFile, '-mat');
    for side = 'RL'
        field  = ['AnnotColor_' side];
        stored = loaded.s.(field);
        mine   = written.s.(field);
        same   = isequal(size(stored), size(mine)) && max(abs(stored(:) - mine(:))) < 1e-12;
        nFail  = nFail + check(same, ...
            sprintf('%s computed = %s stored in the example', field, field), ...
            sprintf('%d vertices', size(mine,1)));
    end
end

% a project without annotations: the colours are grey, as on loading one
bare = project;
bare.AnnotLabel_R = [];  bare.AnnotLabel_L = [];
threw = '';
try
    writeIelFile(savedFile, bare, work);
catch err
    threw = err.message;
end
nFail = nFail + check(isempty(threw), 'a project without annotations saves too', threw);
if isempty(threw)
    written = load(savedFile, '-mat');
    grey = all(written.s.AnnotColor_R(:) == 0.5) && ...
           size(written.s.AnnotColor_R, 1) == size(project.verticesR, 1);
    nFail = nFail + check(grey, 'and its surfaces are grey', '');
end

%% ------------------------------------------------------------ voxelWeights
fprintf('\n--- voxelWeights, against the code from getThresholdedVoxels -\n');

opt.lowThreshold  = 0.5*(work.maxValue - work.minValue) + work.minValue;
opt.highThreshold = work.maxValue;
opt.denoiseKernel = 1;
crd = thresholdCTVoxels(project.TAC, project.mask, project.S2, opt);
crd = crd(1:min(2000, size(crd,1)), :);

expW = originalWeights(project.TAC, project.S2, crd);
actW = voxelWeights(project.TAC, project.S2, crd);
nFail = nFail + check(isequaln(expW, actW), 'same weights', sprintf('%d voxels', numel(actW)));
nFail = nFail + check(isa(actW,'double') && all(actW >= 0), ...
    'weights are double and never negative', sprintf('%g to %g', min(actW), max(actW)));

%% ---------------------------------------------------------- gridFitOptions
fprintf('\n--- gridFitOptions, against the code from the Fit button ------\n');

cases = { ...
%    type     rows cols fixM1 fixM1_BF overlap
    'grid',    4,   5,   10,   [],      0
    'grid',    4,   5,   10,   [],      1
    'strip',   1,   6,   10,   [],      0
    'depth',   1,  10,  3.5,   3.5,     0
    'depth',   1,   8,  4.5,   8.0,     0 };

for k = 1:size(cases,1)
    [type, rows, cols, fixM1, fixM1_BF, overlap] = cases{k,:};
    expected = originalFitOptions(work.options, type, rows, cols, fixM1, fixM1_BF, overlap, [], []);
    act = gridFitOptions(work.options, type, rows, cols, fixM1, fixM1_BF, overlap);
    nFail = nFail + check(isequaln(expected, act), ...
        sprintf('%s %dx%d, %g mm, no nails', type, rows, cols, fixM1), ...
        sprintf('Kc %.4g', act.minDef2.Kc));
end

% nailed contacts, all assigned
nailCrd = [1 2 3; 4 5 6; 7 8 9];
expected = originalFitOptions(work.options, 'depth', 1, 10, 3.5, 3.5, 0, [1;4;7], nailCrd);
act = gridFitOptions(work.options, 'depth', 1, 10, 3.5, 3.5, 0, [1;4;7], nailCrd);
nFail = nFail + check(isequaln(expected, act) && isequal(act.NailElectrodeCrd, nailCrd), ...
    'three nailed contacts, all assigned', '');

% one left unassigned: the preserved fault of OPEN_QUESTIONS item 20
expected = originalFitOptions(work.options, 'depth', 1, 10, 3.5, 3.5, 0, [1;NaN;7], nailCrd);
act = gridFitOptions(work.options, 'depth', 1, 10, 3.5, 3.5, 0, [1;NaN;7], nailCrd);
nFail = nFail + check(isequaln(expected, act), ...
    'one unassigned: same as the Fit button did', ...
    sprintf('coordinates come back %dx%d, not 2x3 - item 20', ...
            size(act.NailElectrodeCrd,1), size(act.NailElectrodeCrd,2)));

threw = '';
try
    gridFitOptions(work.options, 'sphere', 1, 1, 1, 1, 0);
catch err
    threw = err.identifier;
end
nFail = nFail + check(strcmp(threw, 'gridFitOptions:badType'), ...
    'a type that is not grid, strip or depth', threw);

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - a script can open a project, weigh voxels and configure GridFit.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% The end of getThresholdedVoxels, with handles.project passed in as CT and S2.

function weight = originalWeights(TAC, S2, brushCrd)
TACCords=round(AnatSpace2Mesh(brushCrd,S2));
indexTAC=sub2ind(size(TAC.img),TACCords(:,1),TACCords(:,2),TACCords(:,3));
weight=double(TAC.img(indexTAC))-double(min(TAC.img(:))); %convert to double to avoid out of range
end

% The options assembly of Fitpushbutton_Callback. The dialogs are replaced by
% arguments, and the nail table's answers by nailNumbers / nailCoords, which
% stand for handles.work.uitable_elecNum and handles.work.GS.

function options = originalFitOptions(allOptions, type, rows, cols, fixM1, fixM1_BF, overlap, nailNumbers, nailCoords)
switch type
    case 'grid'
        options=allOptions.gridFit_grids;
    case 'strip'
        options=allOptions.gridFit_strips;
    case 'depth'
        options=allOptions.gridFit_depth;
end

options.fixM1=fixM1;
if strcmp(type,'depth')
     options.fixM1_BF=fixM1_BF;
else
     options.fixM1_BF=fixM1;
end

if ~isempty(nailCoords)
    options.NailElectrodeNumber = nailNumbers;
    options.NailElectrodeCrd = nailCoords;

    % if some coords are not selected, nan is given
    % crds need to be removed
    options.NailElectrodeCrd(isnan(options.NailElectrodeNumber )) = [];
    options.NailElectrodeNumber(isnan(options.NailElectrodeNumber )) = [];
else
    options.NailElectrodeNumber = [];
    options.NailElectrodeCrd =[];
end

% calculate Kc as optimal Kc from simulations
options.minDef2.Kc = Kc_optimal(fixM1,rows*cols,overlap,options.minDef2.model,options.type); % coregistration: the higher this number, the stronger the atraction to the CT voxels
end

% ---------------------------------------------------------------------
function deleteIfThere(file)
if isfile(file), delete(file); end
end

function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-50s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-50s %s\n', what, detail);  bad = 1;
end
end
