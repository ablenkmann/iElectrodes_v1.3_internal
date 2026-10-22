function ok = test_ielecLoadCT()
%TEST_IELECLOADCT  Check ielec.loadCT, half of what the Load CT button does.
%
%   ok = test_ielecLoadCT() writes a small MRI, a CT with two bright blobs
%   in it and a mask that covers one of them, loads them with ielec.loadCT
%   and ielec.loadMask, and compares the result with the Load CT button's
%   original steps, kept verbatim below.
%
%   THE SPLIT IS WHAT THIS CHECKS
%
%   ielec.loadCT used to read the CT and the mask together. The toolbox
%   author asked for two functions, because they are two files, two
%   reslicings and two project fields. The check that matters is therefore
%   not that each half works, but that the two of them together still build
%   exactly what the one of them built - and what the button built before
%   either existed.
%
%   It then thresholds the loaded CT, which is what the CT and the mask are
%   for: the voxels found have to be the blob inside the mask and not the
%   one outside it. That checks the CT, the mask and the transformation
%   together, not just that three fields were filled in.
%
%   Usage:  cd into the repository, then
%              test_ielecLoadCT
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.LOADCT, IELEC.LOADMASK, LOADVOLUMEONTOMRI,
%   THRESHOLDCTVOXELS.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

folder = fullfile(tempdir, ['iElectrodes_test_loadct_' char(java.util.UUID.randomUUID)]);
mkdir(folder);
removeLater = onCleanup(@() rmdir(folder, 's'));

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

dim = [20 22 18];
mriFile  = writeVolume(folder, 'tinyT1.nii',  200 * ones(dim));
% two bright blobs, one at each end, in a dim background
ct = 100 * ones(dim);
ct(4:6,   4:6,   4:6)   = 3000;      % inside the mask
ct(15:17, 17:19, 13:15) = 3000;      % outside it
ctFile   = writeVolume(folder, 'tinyCT.nii', ct);
mask = zeros(dim);
mask(1:10, 1:11, 1:9) = 1;
maskFile = writeVolume(folder, 'tinyMask.nii', mask);

[project, work] = ielec.newProject(struct('mri', mriFile, 'voxdim', [1 1 1]), [], []);

%% --------------------------------- the two together, against the button
fprintf('\n--- loadCT then loadMask, against the Load CT button ----------\n');

before.project = project;  before.work = work;
expected = originalLoadCT(before, [folder filesep], 'tinyCT.nii', [folder filesep], 'tinyMask.nii');

[loaded, loadedWork] = ielec.loadCT(struct('ct', ctFile), project, work);
[loaded, loadedWork] = ielec.loadMask(struct('mask', maskFile), loaded, loadedWork);

nFail = nFail + check(isequaln(withoutHistory(loaded), withoutHistory(expected.project)), ...
    'project is what the button built', ...
    sprintf('CT %s', mat2str(size(loaded.TAC.img))));
nFail = nFail + check(isequaln(loadedWork, expected.work), ...
    'work is what the button built', ...
    sprintf('%g to %g', double(loadedWork.minValue), double(loadedWork.maxValue)));
nFail = nFail + check(isequal(loaded.S2, loaded.TAC.vol.mat(1:3,:)), ...
    'S2 comes from the CT, as the button set it', '');
nFail = nFail + check(isequaln(loaded.T1, project.T1) && isempty(loaded.electrodes), ...
    'the rest of the project is untouched', '');

%% ------------------------------------------------ what loadCT does alone
fprintf('\n--- loadCT on its own ----------------------------------------\n');

[ctOnly, ctOnlyWork] = ielec.loadCT(struct('ct', ctFile), project, work);

nFail = nFail + check(~isempty(ctOnly.TAC), 'the CT is in the project', ...
    mat2str(size(ctOnly.TAC.img)));
nFail = nFail + check(isempty(ctOnly.mask), ...
    'and the mask is not - that is loadMask''s', '');
nFail = nFail + check(isequal(double(ctOnlyWork.maxValue), 3000) && ...
    isequal(double(ctOnlyWork.minValue), 100), ...
    'work gets the CT''s intensity limits', ...
    sprintf('%g to %g', double(ctOnlyWork.minValue), double(ctOnlyWork.maxValue)));

% with a CT and no mask there is nothing to threshold, and the message has
% to say which half is missing
nFail = nFail + check(strcmp(errorId(@() ielec.thresholdCT( ...
        struct('lowThreshold', 500, 'highThreshold', 4000), ...
        ctOnly, ctOnlyWork)), 'ielec:noMask'), ...
    'thresholding a CT with no mask names the mask', '');

% and the other way round, so the two are told apart by more than wording
maskOnly = ielec.loadMask(struct('mask', maskFile), project, work);
nFail = nFail + check(strcmp(errorId(@() ielec.thresholdCT( ...
        struct('lowThreshold', 500, 'highThreshold', 4000), ...
        maskOnly, work)), 'ielec:noCT'), ...
    'and a mask with no CT names the CT', '');

%% ------------------------------------------------------ what it is for
fprintf('\n--- thresholding the CT that was loaded ----------------------\n');

opt.lowThreshold  = 0.5 * (double(loadedWork.maxValue) - double(loadedWork.minValue));
opt.highThreshold = 2 * double(loadedWork.maxValue);   % above everything: < is strict
opt.denoiseKernel = 1;
crd = thresholdCTVoxels(loaded.TAC, loaded.mask, loaded.S2, opt);

nFail = nFail + check(~isempty(crd), 'the threshold found voxels', ...
    sprintf('%d', size(crd,1)));
if ~isempty(crd)
    inside = crd(:,1) < 1;   % the mask covers the low corner of the volume
    nFail = nFail + check(all(inside), 'only the blob inside the mask', ...
        sprintf('%d of %d', sum(inside), numel(inside)));
end

%% ----------------------------------------- the interpolation defaults
fprintf('\n--- the interpolation orders the button used -----------------\n');

% The volumes above share the MRI's grid, so reslicing them is the identity
% and the interpolation order makes no difference at all - which means the
% comparison with the button cannot see it. These two are on a grid of their
% own, where the orders do differ, so the defaults are pinned rather than
% assumed: 4 for the CT and 1 for the mask, as the button passed them.
coarseDim = [10 11 9];
ctCoarse  = 100 * ones(coarseDim);
ctCoarse(2:4, 2:4, 2:4) = 3000;
coarseCT  = writeVolume(folder, 'coarseCT.nii', ctCoarse, [2 2 2]);

byDefault = ielec.loadCT(struct('ct', coarseCT), project, work);
asFour    = loadVolumeOntoMRI('', coarseCT, project.T1, 4);
asOne     = loadVolumeOntoMRI('', coarseCT, project.T1, 1);

nFail = nFail + check(~isequaln(asFour.img, asOne.img), ...
    'on this grid the orders give different images', ...
    'so the next check can tell them apart');
nFail = nFail + check(isequaln(byDefault.TAC.img, asFour.img), ...
    'the CT is interpolated at order 4, as the button did', '');

coarseMask = writeVolume(folder, 'coarseMask.nii', ...
    double(ctCoarse > 1000), [2 2 2]);
maskDefault = ielec.loadMask(struct('mask', coarseMask), project, work);
maskAsOne   = loadVolumeOntoMRI('', coarseMask, project.T1, 1);
maskAsFour  = loadVolumeOntoMRI('', coarseMask, project.T1, 4);

nFail = nFail + check(~isequaln(maskAsOne.img, maskAsFour.img), ...
    'and for the mask too', '');
nFail = nFail + check(isequaln(maskDefault.mask.img, maskAsOne.img), ...
    'the mask is interpolated at order 1, as the button did', '');

%% ---------------------------------- a CT with no mask, saved and reopened
fprintf('\n--- a project that has a CT and no mask ----------------------\n');

% Splitting the two makes this an ordinary state, and it has to survive the
% file. It did not: checkProjectStructure fabricated a mask struct with an
% empty image out of an empty mask, so isempty() said a mask was present and
% the threshold went on to fail inside thresholdCTVoxels with a raw MATLAB
% error - exactly what the layer's identifiers exist to prevent.
ctOnlyFile = fullfile(folder, 'ctOnly.iel');
ielec.saveProject(struct('file', ctOnlyFile), ctOnly, ctOnlyWork);
[reopened, reopenedWork] = ielec.openProject(struct('file', ctOnlyFile), [], []);

nFail = nFail + check(~isempty(reopened.TAC), 'the CT comes back', '');
nFail = nFail + check(isempty(reopened.mask), ...
    'and the mask is still absent, not an empty one pretending', ...
    sprintf('class %s', class(reopened.mask)));
nFail = nFail + check(strcmp(errorId(@() ielec.thresholdCT( ...
        struct('lowThreshold', 500, 'highThreshold', 4000), ...
        reopened, reopenedWork)), 'ielec:noMask'), ...
    'and thresholding it says so in the layer''s own words', '');

%% ------------------------------------------------------------ the options
fprintf('\n--- cfg ------------------------------------------------------\n');

nearest = ielec.loadCT(struct('ct', ctFile, 'interpolation', 0), project, work);
nFail = nFail + check(isequal(size(nearest.TAC.img), size(loaded.TAC.img)), ...
    'cfg.interpolation is accepted', 'nearest neighbour');

nFail = nFail + check(strcmp(errorId(@() ielec.loadCT(struct(), project, work)), ...
    'ielec:missingOption'), 'the CT is not optional', '');

% the change the author asked for: the mask is no longer this function's
nFail = nFail + check(strcmp(errorId(@() ielec.loadCT( ...
        struct('ct', ctFile, 'mask', maskFile), project, work)), ...
    'ielec:unknownOption'), 'cfg.mask belongs to ielec.loadMask now', '');

nFail = nFail + check(strcmp(errorId(@() ielec.loadCT(...
        struct('ct', fullfile(folder,'no_such.nii')), project, work)), 'ielec:noSuchFile'), ...
    'a missing file is refused by name', '');
nFail = nFail + check(strcmp(errorId(@() ielec.loadCT(...
        struct('ct', ctFile, 'CTfile', 1), project, work)), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.CTfile');

empty = liftToWork(liftToProject(checkProjectStructure([], struct())));
nFail = nFail + check(strcmp(errorId(@() ielec.loadCT(...
        struct('ct', ctFile), empty.project, empty.work)), 'ielec:noMRI'), ...
    'without an MRI it says so', '');

%% --------------------------------------------------------- layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.loadCT) == 3 && nargout(@ielec.loadCT) == 2, ...
    '[project, work] = ielec.loadCT(cfg, project, work)', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the CT and the mask load as the button loaded them.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% The Load CT button, with the two dialogs' answers given as arguments. It
% did both halves; the layer now does them in two calls, and the check above
% is that the two produce this.

function handles = originalLoadCT(handles, PathName, TACfile, maskPathName, maskfile)
    [handles.project.TAC]= ...
        loadVolumeOntoMRI(PathName,TACfile,handles.project.T1,4); %interpolation = 4

    [inskullMask]= ...
        loadVolumeOntoMRI(maskPathName,maskfile,handles.project.T1,1); %interpolation = 1

    handles.project.mask=inskullMask; %loading the img and the vol
    handles.project.S2=handles.project.TAC.vol.mat(1:3,:);
    maxValue=max(handles.project.TAC.img(:));
    minValue=min(handles.project.TAC.img(:));

    handles.work.maxValue=maxValue;
    handles.work.minValue=minValue;
end

% ---------------------------------------------------------------------
function file = writeVolume(folder, name, img, voxdim)
if nargin < 4, voxdim = [1 1 1]; end
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
