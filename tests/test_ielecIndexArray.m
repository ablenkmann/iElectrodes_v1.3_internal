function ok = test_ielecIndexArray()
%TEST_IELECINDEXARRAY  Check ielec.indexArray against the Index button.
%
%   ok = test_ielecIndexArray() numbers the contacts of the example
%   project's arrays through the layer, both ways the Index button does it -
%   an array that is already in the project, numbered again from its own
%   coordinates, and a set of contacts in progress, numbered for the first
%   time - and compares the array with the button's own steps, kept verbatim
%   at the end of this file.
%
%   The array is compared whole, field by field, because the button built it
%   the same way: the backend makes it and the callback fills in the four
%   fields the backend does not know about.
%
%   Usage:  cd into the repository, then
%              test_ielecIndexArray
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.INDEXARRAY, INDEXDEPTHELECTRODES, INDEXGRIDELECTRODES.

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

% no contacts in progress: that is what makes the button number an array
% that is already in the project
work.GS = [];

% which of the example's arrays is a line of contacts and which is a grid
lineArray = 0;
gridArray = 0;
for k = 1:numel(project.electrodes)
    e = project.electrodes{k};
    if lineArray == 0 && e.rows == 1 && e.nElectrodes >= 4
        lineArray = k;
    end
    if gridArray == 0 && e.rows > 1 && e.columns > 1
        gridArray = k;
    end
end

%% ------------------------------------- an array that is already in the project
fprintf('\n--- ielec.indexArray against the Index button -----------------\n');

if lineArray == 0
    fprintf('  (the example has no depth or strip array - that part is skipped)\n');
else
    expected = originalIndexAgain(project, work, lineArray, 'depth', [], []);

    cfg = [];
    cfg.shape = 'depth';
    cfg.index = lineArray;
    [numbered, numberedWork, array] = ielec.indexArray(cfg, project, work);

    nFail = nFail + check(isequaln(array, expected.array), ...
        'a depth array, numbered again as the button numbered it', ...
        sprintf('%s, %d contacts', project.electrodes{lineArray}.Name, array.nElectrodes));
    nFail = nFail + check(isequaln(withoutHistory(numbered), withoutHistory(project)), ...
        'the array is a proposal - the project gains only the step', '');
    nFail = nFail + check(isequaln(numberedWork, work), ...
        'and work is not either', '');
end

if gridArray == 0
    fprintf('  (the example has no grid array - that part is skipped)\n');
else
    rows     = project.electrodes{gridArray}.rows;
    columns  = project.electrodes{gridArray}.columns;
    expected = originalIndexAgain(project, work, gridArray, 'grid', rows, columns);

    cfg = [];
    cfg.shape   = 'grid';
    cfg.rows    = rows;
    cfg.columns = columns;
    cfg.index   = gridArray;
    [numbered, numberedWork, array] = ielec.indexArray(cfg, project, work);

    nFail = nFail + check(isequaln(array, expected.array), ...
        'a grid, numbered again as the button numbered it', ...
        sprintf('%s, %d by %d', project.electrodes{gridArray}.Name, rows, columns));
    nFail = nFail + check(isequaln(array.adjMat, expected.array.adjMat) && ...
            ~isempty(array.adjMat), ...
        'with the adjacency matrix the button made for it', ...
        sprintf('%s', mat2str(size(array.adjMat))));
    nFail = nFail + check(isequaln(withoutHistory(numbered), withoutHistory(project)) && isequaln(numberedWork, work), ...
        'and work is untouched, the project gaining only the step', '');
end

%% ------------------------------------------- contacts in progress, first time
fprintf('\n--- and for contacts that have just been clustered ------------\n');

% six contacts along a line, and the brushed voxels they were clustered
% from: ten voxels per contact, in the order the clustering left them
inProgress          = work;
inProgress.GS       = [30 + (0:5)' * 4, 40 + (0:5)' * 0.2, 50 - (0:5)' * 0.1];
inProgress.clusters = repmat((1:6)', 10, 1);
inProgress.brushCrd = inProgress.GS(inProgress.clusters, :) + 0.3;
inProgress.brushWeight = ones(60, 1);

expected = originalIndexFirst(project, inProgress, 'depth', [], []);

cfg = [];
cfg.shape = 'depth';
[numbered, numberedWork, array] = ielec.indexArray(cfg, project, inProgress);

nFail = nFail + check(isequaln(array, expected.array), ...
    'the array is the one the button made', ...
    sprintf('%d contacts, %s', array.nElectrodes, array.Type));
nFail = nFail + check(isequaln(numberedWork, expected.work), ...
    'and the clusters in work follow the new order', '');
nFail = nFail + check(isequaln(withoutHistory(numbered), withoutHistory(project)), ...
    'the project is still untouched', '');
nFail = nFail + check(strcmp(array.space, project.currentSpace) && ...
        strcmp(array.method, 'clustering') && ...
        strcmp(array.methodParameters.indexing_projection_method, ...
               work.options.indexing_projection_method), ...
    'a new array records where it came from', ...
    sprintf('%s, %s', array.space, array.method));
nFail = nFail + check(isequaln(array.brushCrd, inProgress.brushCrd) && ...
        isequaln(array.brushWeight, inProgress.brushWeight), ...
    'and the brushed voxels come with it', ...
    sprintf('%d voxels', size(array.brushCrd,1)));

% the contacts come out in order along the line, whichever end is first
along = [array.x array.y array.z];
step  = diff(along(:,1));
nFail = nFail + check(all(step > 0) || all(step < 0), ...
    'the contacts are numbered along the line', ...
    sprintf('%.1f mm apart', abs(step(1))));

%% -------------------------------------------------------------- what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

nFail = nFail + check(strcmp(errorId(@() ielec.indexArray(struct('shape', 'depth'), ...
                                                           project, work)), 'ielec:noContacts'), ...
    'nothing in progress and no array named', '');
nFail = nFail + check(strcmp(errorId(@() ielec.indexArray(...
        struct('shape', 'spiral', 'index', 1), project, work)), 'ielec:badOption'), ...
    'a shape that is neither depth nor grid', 'cfg.shape');
nFail = nFail + check(strcmp(errorId(@() ielec.indexArray(...
        struct('shape', 'depth', 'index', numel(project.electrodes) + 1), project, work)), ...
        'ielec:badOption'), ...
    'an array that is not in the project', 'cfg.index');
nFail = nFail + check(strcmp(errorId(@() ielec.indexArray(...
        struct('shape', 'grid', 'index', 1), project, work)), 'ielec:badOption'), ...
    'a grid without its size', 'cfg.rows');
nFail = nFail + check(strcmp(errorId(@() ielec.indexArray(...
        struct('shape', 'grid', 'rows', 2, 'columns', 3, 'index', 1), project, work)), ...
        'ielec:badOption'), ...
    'a size that is not the number of contacts', 'rows x columns');
nFail = nFail + check(strcmp(errorId(@() ielec.indexArray(...
        struct('shape', 'depth', 'index', 1, 'order', 1), project, work)), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.order');

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.indexArray) == 3 && ...
        nargout(@ielec.indexArray) == 3, ...
    'the signature, the array as the third output', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the contacts are numbered as the button numbered them.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% The two halves of Indexpushbutton_Callback, with the radio buttons and the
% two edit boxes replaced by arguments.

function out = originalIndexAgain(project, work, l, shape, rows, columns)
    handles.project = project;
    handles.work    = work;

    electrodes = handles.project.electrodes{l};

    pos = [electrodes.x electrodes.y electrodes.z];

    % strips or depth
    if strcmp(shape, 'depth')
        [electrodesOut,Ix]=indexDepthElectrodes(pos,'depth');
    else
        [electrodesOut,Ix]=indexGridElectrodes(pos,rows,columns,'grid',handles.work.options);
    end

    tempC=electrodes.clusters;
    for i=1:length(Ix)
        electrodesOut.clusters(tempC==Ix(i))=i;
    end

    % include in electrodes structure
    electrodesOut.brushCrd=electrodes.brushCrd;
    electrodesOut.brushWeight=electrodes.brushWeight;

    electrodesOut.adjMat=makeAdjMat(electrodesOut.rows,electrodesOut.columns);

    out.array = electrodesOut;
end

function out = originalIndexFirst(project, work, shape, rows, columns)
    handles.project = project;
    handles.work    = work;

    % index electrode array for the first time
    % strips or depth
    if strcmp(shape, 'depth')
        [electrodes,Ix]=indexDepthElectrodes(handles.work.GS,'depth');
    else
        [electrodes,Ix]=indexGridElectrodes(handles.work.GS,rows,columns,'grid',handles.work.options);
    end

    % add info from all voxels in the clusters
    % rename clusters in the proper order
    tempC=handles.work.clusters;
    for i=1:size(handles.work.GS,1)
        handles.work.clusters(tempC==Ix(i))=i;
    end

    % include in electrodes structure
    electrodes.clusters=handles.work.clusters;
    electrodes.brushCrd=handles.work.brushCrd;
    electrodes.brushWeight=handles.work.brushWeight;
    electrodes.space = handles.project.currentSpace; % 'Native'  or 'MNI'
    electrodes.method = 'clustering';
    electrodes.methodParameters.indexing_projection_method = handles.work.options.indexing_projection_method;

    % make adjacency Matrix
    electrodes.adjMat=makeAdjMat(electrodes.rows,electrodes.columns);

    out.array = electrodes;
    out.work  = handles.work;
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
