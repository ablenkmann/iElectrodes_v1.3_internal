function result = exampleHeadlessWorkflow(outputFolder)
%EXAMPLEHEADLESSWORKFLOW  The localization workflow from a script, no window.
%
%   result = exampleHeadlessWorkflow()
%   result = exampleHeadlessWorkflow(outputFolder)
%
%   Runs the main iElectrodes workflow on examples/exampleNativeSpace.iel
%   without opening a single figure, and **through the ielec layer only**:
%
%     1. open the project            ielec.openProject
%     2. threshold the CT            ielec.thresholdCT
%     3. select some voxels          ielec.selectVoxels
%     4. cluster them into contacts  ielec.cluster
%     5. fit the electrode model     ielec.fitArray
%     6. add the array               ielec.acceptArray
%     7. label every contact         ielec.label
%     8. export in BIDS format       ielec.export
%     9. save the project            ielec.saveProject
%    10. open it again               ielec.openProject
%
%   This is the tutorial for scripting iElectrodes. Every line that does
%   anything to the project is one `ielec` call with a cfg, the same calls
%   the window makes, so anything the window can do a script can do. Read
%   docs/API_LAYER.md for the rules those calls obey; the short version is
%
%       cfg = [];
%       cfg.something = ...;
%       [project, work] = ielec.doSomething(cfg, project, work);
%
%   and nothing else is needed - no handles, no figure, no globals.
%
%   The only backend function called directly is EUCDISTMAT, which rule 8 of
%   the layer names as one of three shared geometry functions the backend
%   itself uses. It is used here to measure how far the new fit landed from
%   the old one, which is the script's own bookkeeping and not part of the
%   workflow.
%
%   STEP 3 IS THE ONE THE WINDOW CANNOT HAND OVER. There the user brushes
%   the voxels of one electrode by hand. A script has to say which voxels it
%   means, so this one takes every thresholded voxel within 5 mm of a depth
%   electrode the example project already has, and localizes it again from
%   scratch. That also makes the result checkable: the new fit should land
%   on the contacts the project already had. IELEC.SELECTVOXELS takes those
%   as positions in the list IELEC.THRESHOLDCT left in work - a selection,
%   not data, which is rule 3b.
%
%   Files are written to OUTPUTFOLDER, by default a folder in tempdir - never
%   inside the repository. The example project itself is not changed.
%
%   RESULT holds what each step produced, so a test can check it.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.OPENPROJECT, IELEC.THRESHOLDCT, IELEC.SELECTVOXELS,
%   IELEC.CLUSTER, IELEC.FITARRAY, IELEC.ACCEPTARRAY, IELEC.LABEL,
%   IELEC.EXPORT, IELEC.SAVEPROJECT, docs/API_LAYER.md.

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
% Switch it off for the run and put back whatever it was. This is the one
% piece of state the layer does not own - a backend global, and the reason
% the layer never turns it on itself.
global debugging %#ok<GVMIS>
debuggingBefore = debugging;
debugging = 0;
restoreDebugging = onCleanup(@() setDebugging(debuggingBefore));

figuresBefore = numel(findall(0, 'Type', 'figure'));
rng(0);   % clustering is randomised; this makes the run repeatable

say('iElectrodes without a window');

%% ------------------------------------------------------- 1. open the project
cfg = [];
cfg.file = fullfile(repoRoot, 'examples', 'exampleNativeSpace.iel');
[project, work, ui] = ielec.openProject(cfg, [], []);

% UI is the third thing the layer hands over: the colours of the
% parcellation and the surfaces, which take seconds to compute. Keep it and
% give it back at step 9 and they are not computed again.
step(1, 'ielec.openProject', sprintf('%d electrode arrays, CT %s voxels', ...
    numel(project.electrodes), strjoin(string(size(project.TAC.img)), 'x')));

%% ------------------------------------------------------- 2. threshold the CT
% The thresholds are intensities, not slider positions. These are the ones
% the window shows after opening a project: its sliders start at 0.5 and 1
% of the CT's intensity range.
cfg = [];
cfg.lowThreshold  = 0.5 * (work.maxValue - work.minValue) + work.minValue;
cfg.highThreshold = 1.0 * (work.maxValue - work.minValue) + work.minValue;
cfg.denoiseKernel = 1;                       % 1 is off
[project, work] = ielec.thresholdCT(cfg, project, work);

step(2, 'ielec.thresholdCT', sprintf('%d voxels between %.0f and %.0f', ...
    size(work.candidateVoxels,1), cfg.lowThreshold, cfg.highThreshold));

%% ------------------------------------ 3. select the voxels of one electrode
% Stand-in for brushing: the candidates near a depth electrode already
% localized. See the note in the help above.
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
distToElectrode = min(eucDistMat(work.candidateVoxels, refContacts), [], 2);

cfg = [];
cfg.indices = distToElectrode < selectionRadius;    % logical, as long as the candidates
[project, work] = ielec.selectVoxels(cfg, project, work);

% The weighing came with it: ielec.selectVoxels puts the coordinates in
% work.selectedVoxels and their CT weights in work.selectedWeights, so what
% used to be two steps is one call.
step(3, 'ielec.selectVoxels', sprintf('%d voxels within %g mm of %s, weights %.0f to %.0f', ...
    size(work.selectedVoxels,1), selectionRadius, reference.Name, ...
    min(work.selectedWeights), max(work.selectedWeights)));

%% ------------------------------------------------------ 4. cluster them
cfg = [];
cfg.nClusters = nContacts;
[project, work, quality] = ielec.cluster(cfg, project, work);

% ielec.cluster appends to the contacts already in work.GS, so the ones it
% just found are the last nContacts rows.
centres      = work.GS(end-nContacts+1:end, :);
clusterError = min(eucDistMat(centres, refContacts), [], 2);

step(4, 'ielec.cluster', sprintf('%d centres, %.2f mm apart on average, %.2f mm from the stored contacts', ...
    size(centres,1), quality.meanDistance, mean(clusterError)));

%% --------------------------------------------------------- 5. fit the model
% The spacing of the electrode, as the stored localization used it. A depth
% electrode has two: the first gap, which differs on a Behnke-Fried
% electrode, and all the rest.
if isstruct(reference.methodParameters) && all(isfield(reference.methodParameters, {'fixM1','fixM1_BF'}))
    spacing      = reference.methodParameters.fixM1;
    firstSpacing = reference.methodParameters.fixM1_BF;
    spacingFrom  = 'its stored GridFit settings';
else
    gaps         = sqrt(sum(diff(refContacts, 1, 1).^2, 2));
    firstSpacing = gaps(1);
    spacing      = median(gaps(2:end));
    spacingFrom  = 'the spacing of its stored contacts';
end

cfg = [];
cfg.type                = 'depth';
cfg.rows                = 1;
cfg.columns             = nContacts;
cfg.spacing             = spacing;
cfg.firstSecondSpacing  = firstSpacing;
fitStart = tic;
[project, work, array] = ielec.fitArray(cfg, project, work);
fitSeconds = toc(fitStart);

% The array comes back as a proposal: nothing has accepted it yet, which is
% why it is the third output and not in the project. Naming it is the
% caller's business - ielec.nameContacts would rename its contacts too.
array.Name = [reference.Name '_refit'];

fitPositions = [array.x array.y array.z];
fitError     = min(eucDistMat(fitPositions, refContacts), [], 2);

step(5, 'ielec.fitArray', sprintf('%.2f mm from the stored contacts on average, %.2f at most (%.1f s; spacing from %s)', ...
    mean(fitError), max(fitError), fitSeconds, spacingFrom));

%% ------------------------------------------------- 6. add it to the project
nBefore = numel(project.electrodes);

cfg = [];                        % cfg.index would replace an array instead
[project, work, index] = ielec.acceptArray(cfg, project, work, array);

step(6, 'ielec.acceptArray', sprintf('%d -> %d arrays, new one "%s" at %d', ...
    nBefore, numel(project.electrodes), project.electrodes{index}.Name, index));

%% ------------------------------------------------------- 7. label contacts
% No cfg.space: it follows project.currentSpace, which is the space the
% stored coordinates are in. This project is in Native space, where the
% atlas travels with the project.
%
% If you point this script at a project in MNI space - examples/
% exampleMNIspace.iel is one - this step needs the MNI template atlas, which
% lives in work and which ielec.openProject does not load. Open the session
% first, which is what the window does at start-up:
%
%     [project, work] = ielec.startSession([], [], []);
%     [project, work] = ielec.openProject(cfg, project, work);
%
% Without it ielec.label says ielec:noAtlas.
[project, work] = ielec.label([], project, work);

newLabels = project.electrodes{index}.aLabels;
if isempty(newLabels), firstLabel = '(no label)'; else, firstLabel = newLabels{1}; end
step(7, 'ielec.label', sprintf('contact 1 of %s: %s', ...
    project.electrodes{index}.Name, firstLabel));

%% --------------------------------------------------------------- 8. export
% BIDS is two files and so two calls, because each one needs its own name:
% the .tsv with the coordinates and the .json beside it saying what they
% mean.
tsvFile  = fullfile(outputFolder, 'electrodes.tsv');
jsonFile = fullfile(outputFolder, 'coordsystem.json');

cfg = [];
cfg.file        = tsvFile;
cfg.format      = 'bids';
cfg.coordinates = 'contacts';            % where they were localized
[project, work, report] = ielec.export(cfg, project, work);

cfg.file   = jsonFile;
cfg.format = 'bidsCoordinateSystem';
[project, work] = ielec.export(cfg, project, work);

tsvLines = numel(splitlines(strtrim(fileread(tsvFile))));
step(8, 'ielec.export', sprintf('%d contacts to %s, and the json beside it', ...
    report.contacts, tsvFile));

%% ------------------------------------------------------------ 9. save it
ielOut = fullfile(outputFolder, 'headless.iel');

cfg = [];
cfg.file = ielOut;
[project, work] = ielec.saveProject(cfg, project, work, ui);

step(9, 'ielec.saveProject', sprintf('%d arrays to %s', ...
    numel(project.electrodes), ielOut));

%% ----------------------------------------------------- 10. open it again
cfg = [];
cfg.file = ielOut;
[reopened, ~] = ielec.openProject(cfg, [], []);

back = reopened.electrodes{end};
sameBack = numel(reopened.electrodes) == numel(project.electrodes) && ...
           strcmp(back.Name, array.Name) && ...
           isequal([back.x back.y back.z], fitPositions);

step(10, 'ielec.openProject', sprintf('%d arrays back, "%s" %s', ...
    numel(reopened.electrodes), back.Name, ternary(sameBack, 'unchanged', 'CHANGED')));

%% ------------------------------------------------------------ the verdict
figuresAfter = numel(findall(0, 'Type', 'figure'));
say(sprintf('windows opened: %d', figuresAfter - figuresBefore));

result.referenceName     = reference.Name;
result.nThresholded      = size(work.candidateVoxels, 1);
result.nSelected         = size(work.selectedVoxels, 1);
result.clusterQuality    = quality;
result.clusterError      = clusterError;
result.fitPositions      = fitPositions;
result.fitError          = fitError;
result.fitSeconds        = fitSeconds;
result.newArray          = project.electrodes{index};
result.nArraysBefore     = nBefore;
result.nArraysAfter      = numel(project.electrodes);
result.tsvFile           = tsvFile;
result.jsonFile          = jsonFile;
result.tsvContacts       = tsvLines - 1;
result.nContactsTotal    = report.contacts;
result.ielFile           = ielOut;
result.reopenedMatches   = sameBack;
result.figuresOpened     = figuresAfter - figuresBefore;
result.outputFolder      = outputFolder;
end

% ---------------------------------------------------------------------
function step(n, what, detail)
fprintf('  %2d  %-22s %s\n', n, what, detail);
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
