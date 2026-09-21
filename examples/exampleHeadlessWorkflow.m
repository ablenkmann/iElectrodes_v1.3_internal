function result = exampleHeadlessWorkflow(outputFolder)
%EXAMPLEHEADLESSWORKFLOW  The localization workflow from a script, no window.
%
%   result = exampleHeadlessWorkflow()
%   result = exampleHeadlessWorkflow(outputFolder)
%
%   Runs the main iElectrodes workflow on examples/exampleNativeSpace.iel
%   without opening a single figure:
%
%     1. open the project
%     2. threshold the CT
%     3. select the voxels of one depth electrode
%     4. weigh them by CT intensity
%     5. cluster them into contacts
%     6. fit the electrode model to them with GridFit
%     7. add the fitted array to the project
%     8. label every contact anatomically
%     9. export the coordinates in BIDS format
%    10. save the project, open it again, and check it came back
%
%   It is both an example for anyone who wants to script iElectrodes, and
%   evidence that the backend no longer depends on the GUI. The reference
%   plan for iElectrodes 2 asks for exactly this before the new interface is
%   built.
%
%   STEP 3 IS THE ONE THE GUI CANNOT HAND OVER. There, the user brushes the
%   voxels of one electrode by hand. Here the selection has to come from
%   somewhere, so the script takes every thresholded voxel within 5 mm of an
%   electrode the example project already has - one of its depth electrodes
%   - and localizes it again from scratch. That also makes the result
%   checkable: the new fit should land on the contacts the project already
%   had.
%
%   Files are written to OUTPUTFOLDER, by default a folder in tempdir - never
%   inside the repository. The example project itself is not changed.
%
%   RESULT holds what each step produced, so a test can check it.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also LOADPROJECT, THRESHOLDCTVOXELS, VOXELWEIGHTS, CLUSTERCONTACTS,
%   GRIDFITOPTIONS, GRIDFIT, ELECTRODEFROMGRIDFIT, LABELELECTRODESNATIVE,
%   WRITEBIDSELECTRODES, SAVEPROJECT.

%% ------------------------------------------------------------ setup
repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

if nargin < 1 || isempty(outputFolder)
    outputFolder = fullfile(tempdir, 'iElectrodes_headless_example');
end
if ~isfolder(outputFolder), mkdir(outputFolder); end

% GridFit draws its intermediate steps when the global "debugging" is on.
% Switch it off for the run and put back whatever it was.
global debugging %#ok<GVMIS>
debuggingBefore = debugging;
debugging = 0;
restoreDebugging = onCleanup(@() setDebugging(debuggingBefore));

figuresBefore = numel(findall(0, 'Type', 'figure'));
rng(0);   % clustering is randomised; this makes the run repeatable

say('iElectrodes without a window');

%% ------------------------------------------------------- 1. open the project
ielFile = fullfile(repoRoot, 'examples', 'exampleNativeSpace.iel');
[project, work] = loadProject(ielFile);

step(1, 'open the project', sprintf('%d electrode arrays, CT %s voxels', ...
    numel(project.electrodes), strjoin(string(size(project.TAC.img)), 'x')));

%% ------------------------------------------------------- 2. threshold the CT
% the threshold the GUI shows after opening a project: its sliders start at
% 0.5 and 1 of the CT's intensity range, and the denoise kernel at 1 (off)
opt.lowThreshold  = 0.5 * (work.maxValue - work.minValue) + work.minValue;
opt.highThreshold = 1.0 * (work.maxValue - work.minValue) + work.minValue;
opt.denoiseKernel = 1;

[voxels, ~] = thresholdCTVoxels(project.TAC, project.mask, project.S2, opt);

step(2, 'threshold the CT', sprintf('%d voxels between %.0f and %.0f', ...
    size(voxels,1), opt.lowThreshold, opt.highThreshold));

%% ------------------------------------ 3. select the voxels of one electrode
% stand-in for brushing: the voxels near a depth electrode already localized
reference = [];
for j = 1:numel(project.electrodes)
    e = project.electrodes{j};
    if strcmp(e.Type, 'depth') && e.nElectrodes > 2
        reference = e;
        break
    end
end
if isempty(reference)
    error('exampleHeadlessWorkflow:noDepth', ...
        'The example project holds no depth electrode to localize again.');
end
refContacts = [reference.x(:) reference.y(:) reference.z(:)];
nContacts   = reference.nElectrodes;

selectionRadius = 5;   % mm
distToElectrode = min(eucDistMat(voxels, refContacts), [], 2);
selected = voxels(distToElectrode < selectionRadius, :);

step(3, 'select one electrode', sprintf('%d voxels within %g mm of %s (%d contacts)', ...
    size(selected,1), selectionRadius, reference.Name, nContacts));

%% ----------------------------------------------------- 4. weigh the voxels
weight = voxelWeights(project.TAC, project.S2, selected);

step(4, 'weigh them by CT intensity', sprintf('weights %.0f to %.0f', min(weight), max(weight)));

%% ------------------------------------------------------ 5. cluster them
[centres, ~, ~, quality] = clusterContacts(selected, weight, nContacts);
clusterError = min(eucDistMat(centres, refContacts), [], 2);

step(5, 'cluster into contacts', sprintf('%d centres, %.2f mm apart on average, %.2f mm from the stored contacts', ...
    size(centres,1), quality.meanDistance, mean(clusterError)));

%% --------------------------------------------------------- 6. fit GridFit
% the spacing of the electrode, as the stored localization used it
if isstruct(reference.methodParameters) && all(isfield(reference.methodParameters, {'fixM1','fixM1_BF'}))
    fixM1    = reference.methodParameters.fixM1;
    fixM1_BF = reference.methodParameters.fixM1_BF;
    spacingFrom = 'its stored GridFit settings';
else
    gaps     = sqrt(sum(diff(refContacts, 1, 1).^2, 2));
    fixM1_BF = gaps(1);
    fixM1    = median(gaps(2:end));
    spacingFrom = 'the spacing of its stored contacts';
end

options = gridFitOptions(work.options, 'depth', 1, nContacts, fixM1, fixM1_BF, 0);
fitStart = tic;
[pos, clusteredCrd, clusteredWeight, clusters] = gridFit(selected, weight, 1, nContacts, options);
fitSeconds = toc(fitStart);

array = electrodeFromGridFit(pos, clusteredCrd, clusteredWeight, clusters, ...
                             'depth', 1, nContacts, project.currentSpace, options);
array.Name = [reference.Name '_refit'];
fitError = min(eucDistMat(pos, refContacts), [], 2);

step(6, 'fit with GridFit', sprintf('%.2f mm from the stored contacts on average, %.2f at most (%.1f s; spacing from %s)', ...
    mean(fitError), max(fitError), fitSeconds, spacingFrom));

%% ------------------------------------------------- 7. add it to the project
nBefore = numel(project.electrodes);
project.electrodes = addArray(project.electrodes, array, []);

step(7, 'add it to the project', sprintf('%d -> %d arrays, new one "%s"', ...
    nBefore, numel(project.electrodes), array.Name));

%% ------------------------------------------------------- 8. label contacts
prj         = project;
prj.options = work.options;
prj = labelElectrodesNative(prj);
project.electrodes = prj.electrodes;
project.targets    = prj.targets;

newLabels = project.electrodes{end}.aLabels;
if isempty(newLabels), firstLabel = '(no label)'; else, firstLabel = newLabels{1}; end
step(8, 'label every contact', sprintf('contact 1 of %s: %s', array.Name, firstLabel));

%% --------------------------------------------------------------- 9. export
tsvFile = fullfile(outputFolder, 'electrodes.tsv');
coordinates = electrodeCoordinates(project.electrodes, 'contacts');
writeBIDSelectrodes(tsvFile, coordinates);

tsvLines = numel(splitlines(strtrim(fileread(tsvFile))));
step(9, 'export in BIDS format', sprintf('%d contacts to %s', tsvLines - 1, tsvFile));

%% ----------------------------------------------------- 10. save and reopen
ielOut = fullfile(outputFolder, 'headless.iel');
saveProject(ielOut, project, work);
[reopened, ~] = loadProject(ielOut);

back = reopened.electrodes{end};
sameBack = numel(reopened.electrodes) == numel(project.electrodes) && ...
           strcmp(back.Name, array.Name) && ...
           isequal([back.x back.y back.z], [array.x array.y array.z]);

step(10, 'save and open again', sprintf('%d arrays back, "%s" %s', ...
    numel(reopened.electrodes), back.Name, ternary(sameBack, 'unchanged', 'CHANGED')));

%% ------------------------------------------------------------ the verdict
figuresAfter = numel(findall(0, 'Type', 'figure'));
say(sprintf('windows opened: %d', figuresAfter - figuresBefore));

result.referenceName     = reference.Name;
result.nThresholded      = size(voxels, 1);
result.nSelected         = size(selected, 1);
result.clusterQuality    = quality;
result.clusterError      = clusterError;
result.fitPositions      = pos;
result.fitError          = fitError;
result.fitSeconds        = fitSeconds;
result.newArray          = project.electrodes{end};
result.nArraysBefore     = nBefore;
result.nArraysAfter      = numel(project.electrodes);
result.tsvFile           = tsvFile;
result.tsvContacts       = tsvLines - 1;
result.nContactsTotal    = numel(coordinates.x);
result.ielFile           = ielOut;
result.reopenedMatches   = sameBack;
result.figuresOpened     = figuresAfter - figuresBefore;
result.outputFolder      = outputFolder;
end

% ---------------------------------------------------------------------
function step(n, what, detail)
fprintf('  %2d  %-28s %s\n', n, what, detail);
end

function say(text)
fprintf('\n=== %s ===\n\n', text);
end

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end

function setDebugging(value)
global debugging %#ok<GVMIS>
debugging = value;
end
