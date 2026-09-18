function ok = test_electrodeFromGridFit()
%TEST_ELECTRODEFROMGRIDFIT  Check the array assembly taken out of the Fit button.
%
%   ok = test_electrodeFromGridFit() compares ELECTRODEFROMGRIDFIT with the
%   code that used to sit at the end of Fitpushbutton_Callback, kept verbatim
%   in a local function below. No figure is opened.
%
%   GridFit itself is not run - it takes minutes on a real grid, and it is
%   not what this function does. The inputs are taken instead from an array
%   in examples/exampleNativeSpace.iel that was localized with GridFit in the
%   first place: its contact positions stand in for GridFit's `pos`, and it
%   carries the voxels, the weights and the cluster numbers that the fit
%   produced. So the inputs are real, they are just already stored.
%
%   That also gives a check the verbatim comparison cannot give: the array
%   rebuilt from a stored fit must come back with the same adjacency matrix
%   the toolbox stored for it in the first place.
%
%   Usage:  cd into the repository, then
%              test_electrodeFromGridFit
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ELECTRODEFROMGRIDFIT, GRIDFIT, CHECKELECTRODESTRUCTURE.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

ielFile = fullfile(repoRoot,'examples','exampleNativeSpace.iel');
loaded  = load(ielFile,'-mat');
prj     = checkProjectStructure(loaded.s);

%% an array that carries a complete fit
source = [];
for j = 1:numel(prj.electrodes)
    e = prj.electrodes{j};
    if ~ismember(e.Type, {'grid','strip','depth'}),            continue, end
    if e.rows*e.columns ~= numel(e.x) || numel(e.x) == 0,      continue, end
    if isempty(e.brushCrd) || isempty(e.clusters),             continue, end
    source = e;
    break
end

if isempty(source)
    fprintf('\nNo array in this project carries a complete fit to rebuild.\n\n');
    ok = false; if nargout == 0, clear ok; end, return
end

pos             = [source.x(:) source.y(:) source.z(:)];
clusteredCrd    = source.brushCrd;
clusteredWeight = source.brushWeight;
clusters        = source.clusters;
type            = source.Type;
rows            = source.rows;
cols            = source.columns;
space           = source.space;
options         = source.methodParameters;

fprintf('\n   rebuilding %s: %s, %d x %d, %d voxels, space %s\n', ...
    source.Name, type, rows, cols, size(clusteredCrd,1), space);

nFail = 0;

%% ------------------------------ against the code from Fitpushbutton_Callback
fprintf('\n--- against the code from Fitpushbutton_Callback --------------\n');

expected = originalElectrodeBlock(pos, clusteredCrd, clusteredWeight, clusters, ...
    type, rows, cols, space, options);
actual   = electrodeFromGridFit(pos, clusteredCrd, clusteredWeight, clusters, ...
    type, rows, cols, space, options);

nFail = nFail + check(isequaln(expected, actual), 'the whole structure is identical', '');

if ~isequaln(expected, actual)
    expNames = fieldnames(expected);
    for k = 1:numel(expNames)
        thisField = expNames{k};
        if ~isfield(actual, thisField)
            fprintf('            missing field %s\n', thisField);
        elseif ~isequaln(expected.(thisField), actual.(thisField))
            fprintf('            differs: %s\n', thisField);
        end
    end
end

%% ----------------------------------------------------- what the result means
fprintf('\n--- the structure itself -------------------------------------\n');

nFail = nFail + check(isequal(actual.Type, type),  'the type asked for', type);
nFail = nFail + check(isequal(actual.Name, type),  'named after its type', actual.Name);
nFail = nFail + check(actual.nElectrodes == rows*cols, 'one contact per grid position', ...
    sprintf('%d', actual.nElectrodes));
nFail = nFail + check(isequal(size(actual.x), [rows*cols 1]), 'x is a column of contacts', '');
nFail = nFail + check(isequal(actual.method, 'grid_fit'), 'method recorded', actual.method);
nFail = nFail + check(isequaln(actual.methodParameters, options), 'options stored with it', '');
nFail = nFail + check(isequal(actual.space, space), 'space carried through', actual.space);

% contacts are labelled in fitted order, as strings
labelsOk = (numel(actual.ch_label) == rows*cols);
for i = 1:numel(actual.ch_label)
    if ~strcmp(actual.ch_label{i}, int2str(i)), labelsOk = false; break, end
end
nFail = nFail + check(labelsOk, 'contacts labelled 1..n in order', ...
    sprintf('%d labels', numel(actual.ch_label)));

nFail = nFail + check(isequal(size(actual.adjMat), [rows*cols rows*cols]), ...
    'adjacency matrix is nContacts square', '');

% every field the project structure defines must be there
template = checkElectrodeStructure();
template = template{1};
missing  = setdiff(fieldnames(template), fieldnames(actual));
if isempty(missing), missingText = ''; else, missingText = strjoin(missing(:)', ' '); end
nFail = nFail + check(isempty(missing), 'no field of the electrode structure is missing', ...
    missingText);

%% ------------------------------------------- against what the toolbox stored
fprintf('\n--- against the array as the toolbox stored it ----------------\n');
if strcmp(source.method, 'grid_fit')
    nFail = nFail + check(isequaln(actual.adjMat, source.adjMat), ...
        'same adjacency matrix as the stored fit', '');
else
    fprintf('  note      %s was localized by "%s", not grid_fit, so its stored\n', ...
        source.Name, source.method);
    fprintf('            adjacency matrix is not the one this function builds\n');
end

%% --------------------------------------------------------- what it refuses
fprintf('\n--- what it refuses ------------------------------------------\n');
threw = '';
try
    electrodeFromGridFit(pos, clusteredCrd, clusteredWeight, clusters, ...
        'sphere', rows, cols, space, options);
catch err
    threw = err.identifier;
end
nFail = nFail + check(strcmp(threw, 'electrodeFromGridFit:badType'), ...
    'a type that is not grid, strip or depth', threw);

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the array is assembled as it was inside the callback.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% From Fitpushbutton_Callback, with handles.project.currentSpace passed in as
% `space`, since a test has no handles.

function electrodes = originalElectrodeBlock(pos, clusteredCrd, clusteredWeight, ...
    clusters, type, rows, cols, space, options)

% Define new and empty electrode structure
electrodes=checkElectrodeStructure();
electrodes=electrodes{1}; %convert to structure

switch type
    case 'grid'
        electrodes.Type='grid';
    case  'strip'
        electrodes.Type='strip';
    case 'depth'
        electrodes.Type='depth';
end

electrodes.Name = electrodes.Type; %elecBaseName;
electrodes.nElectrodes = rows * cols;
electrodes.rows=rows;
electrodes.columns=cols;

electrodes.x=pos(:,1);
electrodes.y=pos(:,2);
electrodes.z=pos(:,3);

%index in ch labels
for i=1:(rows*cols)
    electrodes.ch_label{i}=int2str(i);%[elecBaseName int2str(i)];
end

% include in electrodes structure
electrodes.clusters=clusters;
electrodes.brushCrd=clusteredCrd;
electrodes.brushWeight=clusteredWeight;
electrodes.space = space; % 'Native'  or 'MNI'
electrodes.method = 'grid_fit';
electrodes.methodParameters = options; % store gridFit configuration parameters

% make adjacency Matrix
electrodes.adjMat=makeAdjMat(electrodes.rows,electrodes.columns);
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-46s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-46s %s\n', what, detail);  bad = 1;
end
end
