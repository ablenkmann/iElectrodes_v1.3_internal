function ok = test_thresholdCTVoxels()
%TEST_THRESHOLDCTVOXELS  Check the voxel selection extracted from updatePlot.
%
%   ok = test_thresholdCTVoxels() runs THRESHOLDCTVOXELS against the CT and
%   the mask stored in examples/exampleNativeSpace.iel, and compares the
%   result with the original inline code from updatePlot, which is kept
%   verbatim in a local function at the bottom of this file.
%
%   No figure is opened. The reference is the code that used to run inside
%   the GUI, so a difference here means the extraction changed behaviour.
%
%   Four settings are covered:
%
%     1. plain threshold, no denoising, no exclusion
%     2. denoising on (the morphological opening)
%     3. exclusion on (voxels of already localised contacts removed)
%     4. an empty result, and the random subsampling limit
%
%   The random subsampling cannot be compared voxel by voxel - it draws a
%   different sample every call - so cases 1 to 3 run with maxCount = inf
%   and the limit is checked separately, by count only.
%
%   Usage:  cd into the repository, then
%              test_thresholdCTVoxels
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

ielFile = fullfile(repoRoot,'examples','exampleNativeSpace.iel');
loaded  = load(ielFile,'-mat');
prj     = checkProjectStructure(loaded.s);

nFail = 0;

if isempty(prj.TAC) || isempty(prj.mask)
    fprintf('\nThe example project carries no CT or no mask - nothing to test.\n\n');
    ok = false;
    if nargout == 0, clear ok; end
    return
end

% Thresholds are plain intensities, the same thing the sliders produce.
% They are chosen from the CT itself so that a useful number of voxels
% passes on any example project: the brightest ~20000 voxels inside the
% mask, which is the order of magnitude the user actually works with.
lo = double(min(prj.TAC.img(:)));
hi = double(max(prj.TAC.img(:)));

insideMask = sort(double(prj.TAC.img(logical(prj.mask.img))));
wanted     = 20000;
if numel(insideMask) > wanted
    thrLow = insideMask(end-wanted);
else
    thrLow = lo + 0.60*(hi-lo);
end
thrHigh = hi + 1;

fprintf('\n   CT %s, intensities %.4g to %.4g, threshold at %.4g\n', ...
    mat2str(size(prj.TAC.img)), lo, hi, thrLow);

% ---------------------------------------------------------------- case 1
fprintf('\n--- plain threshold -----------------------------------------\n');
opt = struct('lowThreshold',thrLow, 'highThreshold',thrHigh, ...
             'denoiseKernel',1, 'excludeCoordinates',[], 'maxCount',inf);
nFail = nFail + compareWithOriginal(prj, opt, 'no denoising, no exclusion');

% ---------------------------------------------------------------- case 2
fprintf('\n--- denoising (morphological opening) ------------------------\n');
for kernel = [2 3]
    opt.denoiseKernel = kernel;
    nFail = nFail + compareWithOriginal(prj, opt, ...
        sprintf('denoise kernel %d', kernel));
end
opt.denoiseKernel = 1;

% ---------------------------------------------------------------- case 3
fprintf('\n--- excluding already localised voxels -----------------------\n');
localised = [];
for j = 1:numel(prj.electrodes)
    localised = [localised; prj.electrodes{j}.brushCrd];  %#ok<AGROW>
end
if isempty(localised)
    fprintf('  --        the example has no localised contacts\n');
else
    opt.excludeCoordinates = localised;
    nFail = nFail + compareWithOriginal(prj, opt, ...
        sprintf('%d localised voxels removed', size(localised,1)));
    opt.excludeCoordinates = [];
end

% ---------------------------------------------------------------- case 4
fprintf('\n--- edge cases -----------------------------------------------\n');
optEmpty = opt;
optEmpty.lowThreshold  = hi + 1;
optEmpty.highThreshold = hi + 2;
[c,v] = thresholdCTVoxels(prj.TAC, prj.mask, prj.S2, optEmpty);
nFail = nFail + check(isempty(c) && isempty(v), ...
    'nothing passes the threshold -> empty, no error', '');

optLimit = opt;
optLimit.maxCount = 500;
warnState = warning('off','all');
[c,v] = thresholdCTVoxels(prj.TAC, prj.mask, prj.S2, optLimit);
warning(warnState);
nFail = nFail + check(size(c,1) == 500 && numel(v) == 500, ...
    'maxCount caps the number of voxels', sprintf('(%d returned)', size(c,1)));
nFail = nFail + check(size(c,2) == 3, 'coordinates are Nx3', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - thresholdCTVoxels behaves as the inline code did.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function bad = compareWithOriginal(prj, opt, what)
[eCrd, eVal] = originalInlineCode(prj, opt);
[aCrd, aVal] = thresholdCTVoxels(prj.TAC, prj.mask, prj.S2, opt);

same = isequaln(eCrd, aCrd) && isequaln(eVal, aVal);
bad  = check(same, what, sprintf('(%d voxels)', size(eCrd,1)));
if ~same
    fprintf('              original %s, extracted %s\n', ...
        mat2str(size(eCrd)), mat2str(size(aCrd)));
    if isequal(size(eCrd), size(aCrd)) && ~isempty(eCrd)
        fprintf('              largest coordinate difference %.3g\n', ...
            max(abs(eCrd(:)-aCrd(:))));
    end
end
end

% ---------------------------------------------------------------------
function [crdOut, vTAC] = originalInlineCode(prj, opt)
%ORIGINALINLINECODE  updatePlot as it was before the extraction.
%
%   Kept verbatim on purpose, with the slider reads replaced by the values
%   in OPT. Do not tidy this up - it is the reference.

denKernelSize = opt.denoiseKernel;
lowThr        = opt.lowThreshold;
hiThr         = opt.highThreshold;

% img is a grayscale matrix
img = prj.TAC.img;

% denoise
if denKernelSize>1
    img=imerode( img, ones(denKernelSize,denKernelSize,denKernelSize));
    img=imdilate( img, ones(denKernelSize,denKernelSize,denKernelSize));
end

% img is converted to a binary images
img=(img> lowThr ) & (img< hiThr) & logical(prj.mask.img); %only maked voxels

% indices to thresholded voxels
ind=find(img);

% Remove already localized voxels
if ~isempty(opt.excludeCoordinates)
    localizedCrd = opt.excludeCoordinates;
    localizedCTCords=round(AnatSpace2Mesh(localizedCrd,prj.S2));
    indexCT=sub2ind(size(prj.TAC.img),localizedCTCords(:,1),localizedCTCords(:,2),localizedCTCords(:,3));

    % remove voxels present in old localizations
    k =  ~ismember(ind,indexCT);
    ind = ind(k);
end

crdOut = [];
vTAC   = [];
if ~isempty(ind)
    vTAC=prj.TAC.img(ind); %values
    crd = [];
    [crd(1,:),crd(2,:),crd(3,:)]=ind2sub(size(img),ind); % coords in (i,j,k) image space
    crdOut=mesh2AnatSpace(crd',prj.S2); %transform to real space
end
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-44s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-44s %s\n', what, detail);  bad = 1;
end
end
