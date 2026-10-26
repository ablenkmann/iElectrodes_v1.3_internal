function ok = test_ielecDummyMask()
%TEST_IELECDUMMYMASK  Check the mask that stands in for a real one.
%
%   ok = test_ielecDummyMask() writes a small MRI and a CT with two bright
%   blobs, and checks that IELEC.DUMMYMASK makes a mask that lets both
%   through - where a real mask covering one of them lets only that one.
%
%   WHAT IS WORTH CHECKING
%
%   The point of this mask is that it restricts nothing, so the check is not
%   that a mask-shaped thing appeared in the project: it is that thresholding
%   with it returns everything above the threshold, and that the same CT with
%   a real mask returns less. A mask of zeros would pass the first kind of
%   check and fail this one.
%
%   The author asked for "a mask full of ones with the size of CT". It is
%   built from the MRI, because every volume is resliced onto the MRI's grid
%   and the two are therefore the same size - so it also works before a CT
%   is loaded, which is checked here too.
%
%   Usage:  cd into the repository, then
%              test_ielecDummyMask
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.DUMMYMASK, IELEC.LOADMASK, IELEC.THRESHOLDCT.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

folder = fullfile(tempdir, ['iElectrodes_test_dummy_' char(java.util.UUID.randomUUID)]);
mkdir(folder);
removeLater = onCleanup(@() rmdir(folder, 's'));

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

dim = [20 22 18];
mriFile = writeVolume(folder, 'tinyT1.nii', 200 * ones(dim));

ct = 100 * ones(dim);
ct(4:6,   4:6,   4:6)   = 3000;      % the half a real mask covers
ct(15:17, 17:19, 13:15) = 3000;      % the half it does not
ctFile = writeVolume(folder, 'tinyCT.nii', ct);

realMask = zeros(dim);
realMask(1:10, 1:11, 1:9) = 1;
maskFile = writeVolume(folder, 'tinyMask.nii', realMask);

[project, work] = ielec.newProject(struct('mri', mriFile, 'voxdim', [1 1 1]), [], []);
[withCT, withCTwork] = ielec.loadCT(struct('ct', ctFile), project, work);

%% ------------------------------------------------- it restricts nothing
fprintf('\n--- a mask that lets everything through ----------------------\n');

[dummy, dummyWork] = ielec.dummyMask([], withCT, withCTwork);

nFail = nFail + check(~isempty(dummy.mask) && isfield(dummy.mask, 'img'), ...
    'there is a mask in the project', class(dummy.mask));
nFail = nFail + check(isequal(size(dummy.mask.img), size(project.T1.img)), ...
    'the size of the MRI, which is the size of the CT', ...
    mat2str(size(dummy.mask.img)));
nFail = nFail + check(all(dummy.mask.img(:) == 1), ...
    'every voxel is in it', '');
nFail = nFail + check(isequaln(dummyWork, withCTwork), 'work is unchanged', '');

cfg = [];
cfg.lowThreshold  = 1000;
cfg.highThreshold = 4000;
[~, dummyThr] = ielec.thresholdCT(cfg, dummy, dummyWork);

[realm, realWork] = ielec.loadMask(struct('mask', maskFile), withCT, withCTwork);
[~, realThr] = ielec.thresholdCT(cfg, realm, realWork);

nBoth = size(dummyThr.candidateVoxels, 1);
nOne  = size(realThr.candidateVoxels, 1);

nFail = nFail + check(nOne > 0, 'the real mask finds its own blob', ...
    sprintf('%d voxels', nOne));
nFail = nFail + check(nBoth > nOne, ...
    'and the dummy mask finds more than the real one', ...
    sprintf('%d against %d', nBoth, nOne));
nFail = nFail + check(nBoth == 2 * nOne, ...
    'both blobs rather than one', ...
    sprintf('%d = 2 x %d', nBoth, nOne));

%% ---------------------------------------------------- before a CT is there
fprintf('\n--- it does not wait for the CT ------------------------------\n');

noCT = ielec.dummyMask([], project, work);
nFail = nFail + check(all(noCT.mask.img(:) == 1) && ...
    isequal(size(noCT.mask.img), size(project.T1.img)), ...
    'a mask can be made before a CT is loaded', '');
nFail = nFail + check(strcmp(errorId(@() ielec.thresholdCT(cfg, noCT, work)), ...
    'ielec:noCT'), 'and thresholding then asks for the CT, not the mask', '');

%% ---------------------------------------------------------- it is recorded
fprintf('\n--- the project says it was done -----------------------------\n');

nFail = nFail + check(strcmp(dummy.history{end}.function, 'ielec.dummyMask'), ...
    'the step is in the history', dummy.history{end}.function);

%% ------------------------------------------------------- what it refuses
fprintf('\n--- cfg ------------------------------------------------------\n');

nFail = nFail + check(strcmp(errorId(@() ielec.dummyMask( ...
        struct('mask', maskFile), withCT, withCTwork)), 'ielec:unknownOption'), ...
    'it takes no options, and says so', 'cfg.mask');

empty = liftToWork(liftToProject(checkProjectStructure([], struct())));
nFail = nFail + check(strcmp(errorId(@() ielec.dummyMask( ...
        [], empty.project, empty.work)), 'ielec:noMRI'), ...
    'without an MRI it says so', '');

%% --------------------------------------------------------- layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.dummyMask) == 3 && ...
    nargout(@ielec.dummyMask) == 2, ...
    '[project, work] = ielec.dummyMask(cfg, project, work)', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - a CT can be thresholded without a real mask.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function file = writeVolume(folder, name, img)
file = fullfile(folder, name);
V.fname   = file;
V.dim     = size(img);
V.dt      = [spm_type('int16') 0];
V.mat     = [1 0 0 -10; 0 1 0 -11; 0 0 1 -9; 0 0 0 1];
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
