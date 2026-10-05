function ok = test_ielecLocalize()
%TEST_IELECLOCALIZE  Check ielec.thresholdCT, ielec.selectVoxels and ielec.cluster.
%
%   ok = test_ielecLocalize() builds a small project whose CT has three
%   bright blobs in a row, like the contacts of a depth electrode, and runs
%   the Localize panel's steps on it: threshold, select, cluster. Each is
%   compared with the code it replaces in updatePlot and in the Clus button,
%   kept verbatim below.
%
%   The clustering is randomised, so both paths are run from the same seed.
%   The contacts it finds also have to land on the three blobs, which is the
%   check that the three steps fit together.
%
%   Usage:  cd into the repository, then
%              test_ielecLocalize
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.THRESHOLDCT, IELEC.SELECTVOXELS, IELEC.CLUSTER.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

folder = fullfile(tempdir, ['iElectrodes_test_localize_' char(java.util.UUID.randomUUID)]);
mkdir(folder);
removeLater = onCleanup(@() rmdir(folder, 's'));

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

% a CT with three bright blobs in a row, all inside the mask
dim = [24 24 20];
ct  = 100 * ones(dim);
centres = [6 12 10; 12 12 10; 18 12 10];
for k = 1:3
    c = centres(k,:);
    ct(c(1)-1:c(1)+1, c(2)-1:c(2)+1, c(3)-1:c(3)+1) = 3000;
end
mriFile  = writeVolume(folder, 'tinyT1.nii',   200 * ones(dim));
ctFile   = writeVolume(folder, 'tinyCT.nii',   ct);
maskFile = writeVolume(folder, 'tinyMask.nii', ones(dim));

[project, work] = ielec.newProject(struct('mri', mriFile, 'voxdim', [1 1 1]), [], []);
[project, work] = ielec.loadCT(struct('ct', ctFile, 'mask', maskFile), project, work);

low  = 0.5 * (double(work.maxValue) - double(work.minValue)) + double(work.minValue);
high = 2   *  double(work.maxValue);

%% -------------------------------------------- thresholdCT against updatePlot
fprintf('\n--- ielec.thresholdCT against updatePlot ---------------------\n');

[expCrd, expValues] = originalThreshold(project, low, high, 1, [], false);

cfg = [];
cfg.lowThreshold  = low;
cfg.highThreshold = high;
[project, work] = ielec.thresholdCT(cfg, project, work);

nFail = nFail + check(isequaln(work.candidateVoxels, expCrd) && ...
        isequaln(work.candidateValues, expValues), ...
    'the voxels are what updatePlot found', sprintf('%d', size(expCrd,1)));
nFail = nFail + check(~isempty(work.candidateVoxels), 'and there are some', '');

% the same, with one blob already localized and left out
withArray = project;
withArray.electrodes = {struct('brushCrd', voxelsNear(expCrd, centres(1,:)))};
expExcluded = originalThreshold(withArray, low, high, 1, [], true);
excludeCfg = cfg;
excludeCfg.excludeLocalized = true;
[~, excludedWork] = ielec.thresholdCT(excludeCfg, withArray, work);
nFail = nFail + check(isequaln(excludedWork.candidateVoxels, expExcluded) && ...
        size(expExcluded,1) < size(expCrd,1), ...
    'cfg.excludeLocalized leaves out an array''s voxels', ...
    sprintf('%d instead of %d', size(expExcluded,1), size(expCrd,1)));

nFail = nFail + check(strcmp(errorId(@() ielec.thresholdCT(setfield(cfg, 'threshold', 1), ...
                                                            project, work)), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.threshold'); %#ok<SFLD>

% the cap on how many are kept
[~, cappedWork] = ielec.thresholdCT(setfield(cfg, 'maxCount', 5), project, work); %#ok<SFLD>
nFail = nFail + check(size(cappedWork.candidateVoxels,1) == 5, ...
    'cfg.maxCount keeps that many', '5');

%% ------------------------------------------------------------ selectVoxels
fprintf('\n--- ielec.selectVoxels ---------------------------------------\n');

nCandidates = size(work.candidateVoxels, 1);
brushed = false(nCandidates, 1);
brushed(1:2:end) = true;                      % every other one, as brushing might

[project, work] = ielec.selectVoxels(struct('indices', brushed), project, work);

nFail = nFail + check(isequal(work.selectedVoxels, work.candidateVoxels(brushed,:)), ...
    'the selected voxels are the ones picked', sprintf('%d', sum(brushed)));
nFail = nFail + check(isequaln(work.selectedWeights, ...
        voxelWeights(project.TAC, project.S2, work.selectedVoxels)), ...
    'their weights are what the Clus button used', '');

[~, byPosition] = ielec.selectVoxels(struct('indices', find(brushed)), project, work);
nFail = nFail + check(isequaln(byPosition.selectedVoxels, work.selectedVoxels), ...
    'positions work as well as a logical array', '');

nFail = nFail + check(strcmp(errorId(@() ielec.selectVoxels(...
        struct('indices', true(nCandidates+3, 1)), project, work)), 'ielec:badSelection'), ...
    'a selection from an older set of voxels is refused', '');
nFail = nFail + check(strcmp(errorId(@() ielec.selectVoxels(...
        struct('indices', brushed, 'index', 1), project, work)), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.index');
noVoxels = work;  noVoxels.candidateVoxels = [];
nFail = nFail + check(strcmp(errorId(@() ielec.selectVoxels(struct('indices', true), ...
                                                             project, noVoxels)), 'ielec:noVoxels'), ...
    'selecting before thresholding is refused', '');

%% ------------------------------------------- cluster against the Clus button
fprintf('\n--- ielec.cluster against the Clus button --------------------\n');

% both from the same seed: the clustering is randomised
rng(7);
expected = originalCluster(work, work.selectedVoxels, work.selectedWeights, 3);
rng(7);
[project, clustered, quality] = ielec.cluster(struct('nClusters', 3), project, work);

nFail = nFail + check(isequaln(clustered.GS, expected.GS) && ...
        isequaln(clustered.clusters, expected.clusters) && ...
        isequaln(clustered.brushCrd, expected.brushCrd) && ...
        isequaln(clustered.brushWeight, expected.brushWeight), ...
    'work is what the Clus button built', sprintf('%d contacts', size(clustered.GS,1)));
nFail = nFail + check(isequaln(clustered.oldGS, work.GS) && ...
        isequaln(clustered.oldbrushCrd, work.brushCrd), ...
    'the previous contacts are kept for Undo', '');
nFail = nFail + check(isfield(quality,'meanDistance') && isfield(quality,'suspect'), ...
    'quality comes back for the caller to report', ...
    sprintf('%.1f mm apart', quality.meanDistance));

% the contacts landed on the three blobs
found = sortrows(clustered.GS, 1);
world = centres + repmat([-14 -14 -12], 3, 1);   % voxel to world, from the header
nFail = nFail + check(isequal(size(found), [3 3]) && ...
        max(abs(found(:,1) - world(:,1))) < 2, ...
    'the three contacts are on the three blobs', ...
    sprintf('%.2f mm at most', max(abs(found(:,1) - world(:,1)))));

% clustering again adds to what is there, numbering on
rng(7);
[~, twice] = ielec.cluster(struct('nClusters', 3), project, clustered);
nFail = nFail + check(size(twice.GS,1) == 6 && max(twice.clusters) == 6, ...
    'a second run adds contacts and numbers on', ...
    sprintf('%d contacts, clusters up to %d', size(twice.GS,1), max(twice.clusters)));

nFail = nFail + check(strcmp(errorId(@() ielec.cluster(struct('nClusters', 0), project, ...
                                                        work)), 'ielec:badOption'), ...
    'zero contacts is refused', '');
nFail = nFail + check(strcmp(errorId(@() ielec.cluster(struct('nClusters', 1e6), project, ...
                                                        work)), 'ielec:badOption'), ...
    'more contacts than voxels is refused', '');
nFail = nFail + check(strcmp(errorId(@() ielec.cluster(struct('nClusters', 3, 'nClus', 3), ...
                                                        project, work)), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.nClus');
nothingSelected = work;  nothingSelected.selectedVoxels = [];
nFail = nFail + check(strcmp(errorId(@() ielec.cluster(struct('nClusters', 3), project, ...
                                                        nothingSelected)), 'ielec:noSelection'), ...
    'clustering before selecting is refused', '');

%% --------------------------------------------------------- layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.thresholdCT) == 3 && nargout(@ielec.thresholdCT) == 2 && ...
        nargin(@ielec.selectVoxels) == 3 && nargout(@ielec.selectVoxels) == 2 && ...
        nargin(@ielec.cluster) == 3 && nargout(@ielec.cluster) == 3, ...
    'the three keep the signature', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - threshold, select and cluster work as the panel did.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% The threshold block of updatePlot and the clustering block of the Clus
% button, with what was read off the controls given as arguments.

function [crd, vTAC] = originalThreshold(prj, lowThreshold, highThreshold, ...
                                         denoiseKernel, maxCount, excludeLocalized)
    opt.lowThreshold  = lowThreshold;
    opt.highThreshold = highThreshold;
    opt.denoiseKernel = denoiseKernel;
    if ~isempty(maxCount)
        opt.maxCount  = maxCount;
    end

    % Remove already localized voxels
    opt.excludeCoordinates = [];
    if excludeLocalized
        for j=1:length(prj.electrodes)
            opt.excludeCoordinates=[opt.excludeCoordinates; prj.electrodes{j}.brushCrd];
        end
    end

    [crd,vTAC] = thresholdCTVoxels(prj.TAC, prj.mask, prj.S2, opt);
end

function work = originalCluster(work, brushCrd, weight, nClus)
    [GS,clusters,weight] = clusterContacts(brushCrd,weight,nClus);

    % save old GS
    work.oldGS=work.GS;
    work.oldbrushCrd=work.brushCrd;
    work.oldbrushWeight=work.brushWeight;
    work.oldclusters=work.clusters;

    %add electrodes coordinates to previous
    work.GS=[work.GS; GS];
    work.brushCrd=[work.brushCrd; brushCrd];
    work.clusters=[work.clusters; (clusters+length(unique(work.clusters)))];
    work.brushWeight=[work.brushWeight; weight];
end

% ---------------------------------------------------------------------
function crd = voxelsNear(allCrd, centre)
% the coordinates of the voxels around one blob, as an array's brushCrd
world = centre + [-14 -14 -12];
crd   = allCrd(all(abs(allCrd - world) < 3, 2), :);
end

function file = writeVolume(folder, name, img)
file = fullfile(folder, name);
V.fname   = file;
V.dim     = size(img);
V.dt      = [spm_type('int16') 0];
V.mat     = [1 0 0 -14; 0 1 0 -14; 0 0 1 -12; 0 0 0 1];
V.pinfo   = [1; 0; 0];
V.descrip = 'iElectrodes test volume';
spm_write_vol(V, img);
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
