function ok = test_ielecLoadMask()
%TEST_IELECLOADMASK  Check ielec.loadMask, the other half of the Load CT button.
%
%   ok = test_ielecLoadMask() writes a small MRI and a mask on a different
%   grid, loads the mask, and checks that it arrives resliced onto the MRI
%   and that nothing else moves.
%
%   WHAT IS WORTH CHECKING HERE
%
%   The mask decides which voxels IELEC.THRESHOLDCT may select, so a mask on
%   the wrong grid does not fail - it selects the wrong voxels, and the
%   contacts that come out of the wrong voxels still look like contacts.
%   The check is therefore that the mask comes back on the MRI's grid, and
%   that it is still a mask afterwards: trilinear interpolation of ones and
%   zeros has to leave something to threshold inside.
%
%   The second thing is order. This and IELEC.LOADCT were one function until
%   the toolbox author asked for two, and two functions that have to be
%   called in a particular order are a worse arrangement than one. So:
%   loading the mask first and the CT second has to give the same project as
%   the other way round.
%
%   Usage:  cd into the repository, then
%              test_ielecLoadMask
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.LOADMASK, IELEC.LOADCT, LOADVOLUMEONTOMRI.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

folder = fullfile(tempdir, ['iElectrodes_test_loadmask_' char(java.util.UUID.randomUUID)]);
mkdir(folder);
removeLater = onCleanup(@() rmdir(folder, 's'));

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

dim = [20 22 18];
mriFile = writeVolume(folder, 'tinyT1.nii', 200 * ones(dim), [1 1 1]);

ct = 100 * ones(dim);
ct(4:6, 4:6, 4:6) = 3000;
ctFile = writeVolume(folder, 'tinyCT.nii', ct, [1 1 1]);

% the mask on a coarser grid of its own, so that reslicing has work to do
maskDim = [10 11 9];
mask    = zeros(maskDim);
mask(1:5, 1:6, 1:5) = 1;
maskFile = writeVolume(folder, 'tinyMask.nii', mask, [2 2 2]);

[project, work] = ielec.newProject(struct('mri', mriFile, 'voxdim', [1 1 1]), [], []);

%% ------------------------------------------------------- onto the MRI
fprintf('\n--- the mask arrives on the MRI''s grid ----------------------\n');

[loaded, loadedWork] = ielec.loadMask(struct('mask', maskFile), project, work);

nFail = nFail + check(~isempty(loaded.mask), 'the mask is in the project', ...
    mat2str(size(loaded.mask.img)));
nFail = nFail + check(isequal(size(loaded.mask.img), size(project.T1.img)), ...
    'resliced onto the MRI, not left on its own grid', ...
    sprintf('mask was %s, MRI is %s', mat2str(maskDim), mat2str(size(project.T1.img))));
nFail = nFail + check(any(loaded.mask.img(:) > 0.5), ...
    'and there is still something inside it', ...
    sprintf('%d voxels', sum(loaded.mask.img(:) > 0.5)));

nFail = nFail + check(isequaln(loadedWork, work), 'work is unchanged', '');
nFail = nFail + check(isempty(loaded.TAC), 'the CT is not loaded by this', '');
nFail = nFail + check(isequaln(loaded.T1, project.T1), 'the MRI is untouched', '');

%% ------------------------------------------------------------- order
fprintf('\n--- either order gives the same project ----------------------\n');

[a, aWork] = ielec.loadCT(struct('ct', ctFile), project, work);
[a, aWork] = ielec.loadMask(struct('mask', maskFile), a, aWork);

[b, bWork] = ielec.loadMask(struct('mask', maskFile), project, work);
[b, bWork] = ielec.loadCT(struct('ct', ctFile), b, bWork);

% both volumes have to actually be there, or this compares nothing with
% nothing: with both functions stubbed out the three checks below all passed
nFail = nFail + check(~isempty(a.TAC) && ~isempty(a.mask) && ...
    ~isempty(a.TAC.img) && ~isempty(a.mask.img), ...
    'both volumes are loaded before they are compared', '');

nFail = nFail + check(isequaln(withoutHistory(a), withoutHistory(b)), ...
    'CT then mask equals mask then CT', '');
nFail = nFail + check(isequaln(aWork, bWork), 'and so does the work', '');

% only the history differs, because the steps happened in a different order
nFail = nFail + check(numel(a.history) == numel(b.history) && ...
    strcmp(a.history{end}.function, 'ielec.loadMask') && ...
    strcmp(b.history{end}.function, 'ielec.loadCT'), ...
    'the history records the order each was actually done in', '');

%% ------------------------------------------------------------ the options
fprintf('\n--- cfg ------------------------------------------------------\n');

sharp = ielec.loadMask(struct('mask', maskFile, 'interpolation', 0), project, work);
nFail = nFail + check(isequal(size(sharp.mask.img), size(project.T1.img)), ...
    'cfg.interpolation is accepted', 'nearest neighbour');
nFail = nFail + check(all(ismember(unique(sharp.mask.img(:)), [0 1])), ...
    'nearest neighbour keeps it to ones and zeros', '');

nFail = nFail + check(strcmp(errorId(@() ielec.loadMask(struct(), project, work)), ...
    'ielec:missingOption'), 'the mask is not optional', '');
nFail = nFail + check(strcmp(errorId(@() ielec.loadMask( ...
        struct('mask', maskFile, 'ct', ctFile), project, work)), ...
    'ielec:unknownOption'), 'cfg.ct belongs to ielec.loadCT', '');
nFail = nFail + check(strcmp(errorId(@() ielec.loadMask( ...
        struct('mask', fullfile(folder,'no_such.nii')), project, work)), ...
    'ielec:noSuchFile'), 'a missing file is refused by name', '');

empty = liftToWork(liftToProject(checkProjectStructure([], struct())));
nFail = nFail + check(strcmp(errorId(@() ielec.loadMask( ...
        struct('mask', maskFile), empty.project, empty.work)), 'ielec:noMRI'), ...
    'without an MRI it says so', '');

%% --------------------------------------------------------- layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.loadMask) == 3 && nargout(@ielec.loadMask) == 2, ...
    '[project, work] = ielec.loadMask(cfg, project, work)', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the mask loads onto the MRI, in either order.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function file = writeVolume(folder, name, img, voxdim)
file = fullfile(folder, name);
V.fname   = file;
V.dim     = size(img);
V.dt      = [spm_type('int16') 0];
V.mat     = [voxdim(1) 0 0 -10; 0 voxdim(2) 0 -11; 0 0 voxdim(3) -9; 0 0 0 1];
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
