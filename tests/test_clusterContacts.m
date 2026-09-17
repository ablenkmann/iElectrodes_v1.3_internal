function ok = test_clusterContacts()
%TEST_CLUSTERCONTACTS  Check the clustering step extracted from the Clus button.
%
%   ok = test_clusterContacts() compares CLUSTERCONTACTS with the code that
%   used to sit inside ClusterButton_Callback, kept verbatim in a local
%   function below. It runs on the voxels of the first electrode array in
%   examples/exampleNativeSpace.iel - real brushed voxels, with their CT
%   intensities as weights. No figure is opened.
%
%   BOTH ALGORITHMS ARE RANDOMISED, so the comparison only means anything if
%   both runs start from the same state. The random generator is therefore
%   seeded immediately before each call. If this test ever fails on the
%   comparison but passes on the checks below it, suspect that the two paths
%   have stopped consuming randomness in the same order, not that the
%   clustering is wrong.
%
%   Usage:  cd into the repository, then
%              test_clusterContacts
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also CLUSTERCONTACTS, CLUSTERING, GRIDFIT.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

ielFile = fullfile(repoRoot,'examples','exampleNativeSpace.iel');
loaded  = load(ielFile,'-mat');
prj     = checkProjectStructure(loaded.s);

% the first array that carries the voxels it was localized from
array = [];
for j = 1:numel(prj.electrodes)
    e = prj.electrodes{j};
    if isfield(e,'brushCrd') && ~isempty(e.brushCrd) && size(e.brushCrd,1) > e.nElectrodes ...
            && isfield(e,'brushWeight') && numel(e.brushWeight) == size(e.brushCrd,1)
        array = e;
        break
    end
end

if isempty(array)
    fprintf('\nNo array in this project carries its brushed voxels and weights.\n\n');
    ok = false; if nargout == 0, clear ok; end, return
end

brushCrd = array.brushCrd;
weight   = array.brushWeight;
nClus    = array.nElectrodes;

fprintf('\n   array %s: %d voxels into %d contacts\n', array.Name, size(brushCrd,1), nClus);

nFail = 0;

%% --------------------------------------------- against the original code
fprintf('\n--- against the code from ClusterButton_Callback --------------\n');

rng(42);
[expGS, expClusters, expWeight, expQ] = originalClusterBlock(brushCrd, weight, nClus);
rng(42);
[actGS, actClusters, actWeight, actQ] = clusterContacts(brushCrd, weight, nClus);

nFail = nFail + check(isequaln(expGS, actGS), 'same contact centres', ...
    sprintf('%dx%d', size(actGS,1), size(actGS,2)));
nFail = nFail + check(isequaln(expClusters, actClusters), 'same cluster per voxel', '');
nFail = nFail + check(isequaln(expWeight, actWeight), 'same weights returned', ...
    class(actWeight));

for f = {'meanDistance','madDistance','nOutliers','nLargeChange','suspect'}
    thisField = f{1};
    nFail = nFail + check(isequaln(expQ.(thisField), actQ.(thisField)), ...
        ['quality.' thisField], num2str(actQ.(thisField)));
end

%% ------------------------------------------------- what the result means
fprintf('\n--- the result itself ----------------------------------------\n');
nFail = nFail + check(size(actGS,1) == nClus, 'one centre per contact asked for', '');
nFail = nFail + check(size(actGS,2) == 3, 'centres are 3-D', '');
nFail = nFail + check(numel(actClusters) == size(brushCrd,1), ...
    'one cluster number per voxel', '');
nFail = nFail + check(all(actClusters >= 1 & actClusters <= nClus), ...
    'every voxel lands in a real cluster', '');
nFail = nFail + check(~any(isnan(actGS(:))), 'no centre is NaN', '');

% every centre must sit inside the cloud it came from
lo = min(brushCrd,[],1);  hi = max(brushCrd,[],1);
inside = true;
for i = 1:size(actGS,1)
    inside = inside && all(actGS(i,:) >= lo - eps) && all(actGS(i,:) <= hi + eps);
end
nFail = nFail + check(inside, 'every centre is inside the selected voxels', '');

nFail = nFail + check(numel(actQ.distances) == nClus, ...
    'one neighbour distance per contact', ...
    sprintf('mean %.2f mm', actQ.meanDistance));

%% ------------------------------- the centre is weighted, not a plain mean
fprintf('\n--- the centre of mass is weighted ---------------------------\n');
% one contact pulled towards its bright voxels: a plain mean of the same
% voxels should not land in the same place
plainMeans = zeros(nClus,3);
for i = 1:nClus
    plainMeans(i,:) = mean(brushCrd(actClusters == i, :), 1);
end
nFail = nFail + check(~isequaln(plainMeans, actGS), ...
    'centres differ from the unweighted means', ...
    sprintf('largest gap %.3f mm', max(sqrt(sum((plainMeans-actGS).^2,2)))));

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - clustering behaves as it did inside the callback.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================

function [GS, clusters, weight, quality] = originalClusterBlock(brushCrd, weight, nClus)
if exist('kmedoids.m','file')
    disp('Running K-medoids clustering algorithm. This can take some time...');
    [clusters] = kmedoids(brushCrd,nClus,'Algorithm','pam', 'OnlinePhase','on');
    GS=zeros(nClus,3); % cluster
    %get center of mass
    for i=1:nClus
        weight=double(weight);
        ind=clusters==i;
        W=sum(weight(ind));
        GS(i,:)=sum(diag(weight(ind))* brushCrd(ind,:),1)*(1/W);
    end
else
    disp('K-medoids algorithm not found. Running k-means algorithm')
    [GS,clusters]=clustering (nClus,brushCrd,weight);
end

% check distribution of distances to clossest neighbour
DD=eucDistMat(GS,GS);
DD(eye(size(DD))==1)=nan;
dd=min(DD); %closest neighbour

quality.distances    = dd;
quality.meanDistance = mean(dd);
quality.madDistance  = mad(dd);
quality.nOutliers    = sum(isoutlier(dd));
quality.nLargeChange = sum(abs(dd/median(dd)-1)>0.20);
quality.suspect      = any(isoutlier(dd)) || any(abs(dd/median(dd)-1)>0.20);
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-44s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-44s %s\n', what, detail);  bad = 1;
end
end
