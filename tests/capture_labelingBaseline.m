function capture_labelingBaseline()
%CAPTURE_LABELINGBASELINE  Characterisation test for native-space labelling.
%
%   Runs the anatomical labelling on examples/exampleNativeSpace.iel WITHOUT
%   opening the iElectrodes GUI, prints what the project contains, and stores
%   every resulting label in tests/baseline_nativeLabels.mat.
%
%   Run it once now, while the extracted code is still a verbatim copy of the
%   original. From then on it is the reference: after any change to the
%   labelling code, run COMPARE_LABELINGBASELINE to prove that the labels did
%   not move. That is what makes it safe to keep refactoring.
%
%   This script opening no figure is the point of the exercise: it is the
%   first piece of iElectrodes that can be driven from a script.
%
%   Usage:  cd into the repository, then
%              tests/capture_labelingBaseline
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo

%% ------------------------------------------------------------------
%  Locate the repository and put the code folders on the path
%  (the same four folders electrodes_gui.m adds at start-up)
%% ------------------------------------------------------------------
repoRoot = fileparts(fileparts(mfilename('fullpath')));
fprintf('\nRepository: %s\n', repoRoot);

codeFolders = {'src','app','assets','third_party'};
for k = 1:numel(codeFolders)
    thisFolder = fullfile(repoRoot, codeFolders{k});
    if isfolder(thisFolder)
        addpath(genpath(thisFolder));
    else
        error('Missing folder "%s". Run this from the restructured repository.', codeFolders{k});
    end
end

% SPM globals are needed by niftiTools2spm when the project stores images in
% the old nifti-tools format, which the example project does.
spm('defaults','PET');

%% ------------------------------------------------------------------
%  Load the example project - no GUI involved
%% ------------------------------------------------------------------
ielFile = fullfile(repoRoot,'examples','exampleNativeSpace.iel');
if ~isfile(ielFile)
    error('Example project not found: %s', ielFile);
end

fprintf('Loading %s\n', ielFile);
loaded = load(ielFile,'-mat');          % the file stores one variable, s
prj    = checkProjectStructure(loaded.s);
prj.options = default_ielectrodes_options([]);

%% ------------------------------------------------------------------
%  Report what is actually inside the project
%% ------------------------------------------------------------------
nArrays   = numel(prj.electrodes);
nTargets  = numel(prj.targets);
nContacts = 0;
for a = 1:nArrays
    nContacts = nContacts + numel(prj.electrodes{a}.x);
end

fprintf('\n--- project contents -------------------------------------\n');
fprintf('  electrode arrays      : %d  (%d contacts in total)\n', nArrays, nContacts);
fprintf('  planning targets      : %d\n', nTargets);
fprintf('  coordinate space      : %s\n', prj.currentSpace);
fprintf('  MRI loaded            : %s\n', yesno(~isempty(prj.T1)));
fprintf('  CT loaded             : %s\n', yesno(~isempty(prj.TAC)));
fprintf('  FreeSurfer parcellation: %s\n', yesno(~isempty(prj.wmparc)));

for a = 1:nArrays
    e = prj.electrodes{a};
    fprintf('    array %d: %-14s %3d contacts, type %s\n', ...
        a, e.Name, numel(e.x), e.Type);
end

if isempty(prj.wmparc)
    fprintf(['\n  NOTE: this project carries no parcellation volume, so the\n' ...
             '  labelling will fill every contact with "no atlas loaded".\n' ...
             '  That is still a valid baseline - it locks in the behaviour of\n' ...
             '  the empty-atlas branch - but load a wmparc file in the GUI and\n' ...
             '  re-save the project if you want the full labelling covered.\n']);
end

fprintf('\n--- labelling options ------------------------------------\n');
fprintf('  atlasLabelingRadio    : %g\n', prj.options.atlasLabelingRadio);
fprintf('  atlasLabelingMode     : %s\n', prj.options.atlasLabelingMode);
fprintf('  atlasLabelingMinProb  : %g\n', prj.options.atlasLabelingMinProb);
fprintf('  atlasLUTFile          : %s\n', prj.options.atlasLUTFile);

%% ------------------------------------------------------------------
%  Run the labelling - this is the function that used to live inside
%  electrodes_gui.m and could only be reached by clicking a button
%% ------------------------------------------------------------------
fprintf('\nRunning labelElectrodesNative ...\n');
t = tic;
prj = labelElectrodesNative(prj);
fprintf('done in %.2f s\n', toc(t));

%% ------------------------------------------------------------------
%  Collect every label into a plain, comparable structure
%% ------------------------------------------------------------------
baseline = struct();
baseline.createdOn   = datestr(now,'yyyy-mm-dd HH:MM:SS');
baseline.sourceFile  = 'examples/exampleNativeSpace.iel';
baseline.options     = prj.options;
baseline.arrays      = cell(nArrays,1);

for a = 1:nArrays
    e = prj.electrodes{a};
    entry = struct();
    entry.name             = e.Name;
    entry.type             = e.Type;
    entry.aLabels          = e.aLabels;
    entry.validAnatLabels  = e.validAnatLabels;
    entry.anatInd          = e.anatInd;
    entry.projection       = cell(numel(e.projection),1);
    for p = 1:numel(e.projection)
        entry.projection{p} = struct( ...
            'aLabels',         {e.projection{p}.aLabels}, ...
            'validAnatLabels', {e.projection{p}.validAnatLabels}, ...
            'anatInd',          e.projection{p}.anatInd);
    end
    baseline.arrays{a} = entry;
end

baseline.targets = cell(nTargets,1);
for tIdx = 1:nTargets
    g = prj.targets{tIdx};
    baseline.targets{tIdx} = struct( ...
        'name',            g.Name, ...
        'aLabels',         {g.aLabels}, ...
        'validAnatLabels', {g.validAnatLabels}, ...
        'anatInd',          g.anatInd);
end

%% ------------------------------------------------------------------
%  Save and summarise
%% ------------------------------------------------------------------
outFile = fullfile(repoRoot,'tests','baseline_nativeLabels.mat');
save(outFile,'baseline','-v7');

fprintf('\n--- labels produced --------------------------------------\n');
fprintf('  In "prob" mode anatomicLabelFS returns one ROW per contact and one\n');
fprintf('  COLUMN per candidate region, each cell reading like "73%% ctx-lh-...".\n');
fprintf('  Cells past a contact''s last candidate are empty.\n\n');
for a = 1:nArrays
    lbl = baseline.arrays{a}.aLabels;
    fprintf('  %-14s %3d contacts x %d candidate slots, %3d distinct labels\n', ...
        baseline.arrays{a}.name, size(lbl,1), size(lbl,2), countDistinct(lbl));
    fprintf('       contact 1: %s\n', describeContact(lbl,1));
end

fprintf('\nBaseline written to tests/baseline_nativeLabels.mat\n');
fprintf('No figure was opened: the labelling now runs head-less.\n\n');

end

function s = yesno(tf)
if tf, s = 'yes'; else, s = 'no'; end
end

function n = countDistinct(lbl)
%COUNTDISTINCT  Number of distinct non-empty label strings in a label cell.
flat  = lbl(:);
isStr = cellfun(@(x) ischar(x) && ~isempty(x), flat);
n     = numel(unique(flat(isStr)));
end

function txt = describeContact(lbl, row)
%DESCRIBECONTACT  All candidate labels of one contact, joined for printing.
if isempty(lbl) || row > size(lbl,1)
    txt = '(none)'; return
end
cand  = lbl(row,:);
isStr = cellfun(@(x) ischar(x) && ~isempty(x), cand);
cand  = cand(isStr);
if isempty(cand)
    txt = '(none)';
else
    txt = strjoin(cand, '  |  ');
end
end
