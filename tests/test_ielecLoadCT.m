function ok = test_ielecLoadCT()
%TEST_IELECLOADCT  Check ielec.loadCT, what the Load CT button does.
%
%   ok = test_ielecLoadCT() writes a small MRI, a CT with two bright blobs
%   in it and a mask that covers one of them, loads them with ielec.loadCT
%   and compares the result with the Load CT button's original steps, kept
%   verbatim below.
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
%   See also IELEC.LOADCT, LOADVOLUMEONTOMRI, THRESHOLDCTVOXELS.

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

%% ------------------------------------------ the same as the Load CT button
fprintf('\n--- ielec.loadCT against the Load CT button -------------------\n');

before.project = project;  before.work = work;
expected = originalLoadCT(before, [folder filesep], 'tinyCT.nii', [folder filesep], 'tinyMask.nii');

cfg = [];
cfg.ct   = ctFile;
cfg.mask = maskFile;
[loaded, loadedWork] = ielec.loadCT(cfg, project, work);

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

%% ------------------------------------------------------------ the options
fprintf('\n--- cfg ------------------------------------------------------\n');

cfg = []; cfg.ct = ctFile; cfg.mask = maskFile; cfg.interpolation = 0;
nearest = ielec.loadCT(cfg, project, work);
nFail = nFail + check(isequal(size(nearest.TAC.img), size(loaded.TAC.img)), ...
    'cfg.interpolation is accepted', 'nearest neighbour');

nFail = nFail + check(strcmp(errorId(@() ielec.loadCT(struct('ct', ctFile), project, work)), 'ielec:missingOption'), ...
    'the mask is not optional', '');
nFail = nFail + check(strcmp(errorId(@() ielec.loadCT(...
        struct('ct', ctFile, 'mask', fullfile(folder,'no_such.nii')), project, work)), 'ielec:noSuchFile'), ...
    'a missing file is refused by name', '');
nFail = nFail + check(strcmp(errorId(@() ielec.loadCT(...
        struct('ct', ctFile, 'mask', maskFile, 'CTfile', 1), project, work)), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.CTfile');

empty = liftToWork(liftToProject(checkProjectStructure([], struct())));
nFail = nFail + check(strcmp(errorId(@() ielec.loadCT(...
        struct('ct', ctFile, 'mask', maskFile), empty.project, empty.work)), 'ielec:noMRI'), ...
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
    fprintf('PASS - ielec.loadCT loads the CT and the mask as the button did.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% The Load CT button, with the two dialogs' answers given as arguments.

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
