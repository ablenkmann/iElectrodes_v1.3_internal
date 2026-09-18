function [coordinates, values] = thresholdCTVoxels(CT, mask, S2, opt)
%THRESHOLDCTVOXELS  CT voxels bright enough to be electrode contacts.
%
%   [coordinates, values] = thresholdCTVoxels(CT, mask, S2, opt) returns the
%   anatomical coordinates of the voxels that pass the threshold, and their
%   CT intensities. These are the black points in the thresholded voxels
%   view, the ones the user brushes to select contacts.
%
%   CT and MASK are volumes as the project holds them; S2 is the project's
%   image-to-world transformation. OPT carries the settings:
%
%     .lowThreshold        keep voxels strictly above this
%     .highThreshold       and strictly below this
%     .denoiseKernel       size of the cubic opening applied first;
%                          1 or less means no denoising
%     .excludeCoordinates  anatomical coordinates already assigned to
%                          electrodes, to be left out; [] for none
%     .maxCount            plot at most this many, chosen at random; inf
%                          for no limit. The GUI passes
%                          ui.options.scatter3D_elem_limit - how many points
%                          are drawn is a display setting, not a scientific
%                          one
%
%   The denoising is a morphological opening - erode, then dilate with the
%   same cube. It removes specks smaller than the kernel while leaving
%   anything larger roughly its own size, which suits CT artifacts: the
%   metal of a contact survives, isolated noisy voxels do not.
%
%   The intensities returned are read from the ORIGINAL CT, not from the
%   denoised copy. The denoising decides which voxels are kept; it is not
%   meant to change what they measure.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also MESH2ANATSPACE, ANATSPACE2MESH, GRIDFIT.

img = CT.img;

% morphological opening, if asked for
if isfield(opt,'denoiseKernel') && opt.denoiseKernel > 1
    k = ones(opt.denoiseKernel, opt.denoiseKernel, opt.denoiseKernel);
    img = imerode(img, k);
    img = imdilate(img, k);
end

% threshold, inside the brain mask
keep = (img > opt.lowThreshold) & (img < opt.highThreshold) & logical(mask.img);
ind  = find(keep);

% drop voxels that already belong to a localised contact
if isfield(opt,'excludeCoordinates') && ~isempty(opt.excludeCoordinates)
    excludeVoxel = round(AnatSpace2Mesh(opt.excludeCoordinates, S2));
    excludeInd   = sub2ind(size(CT.img), ...
        excludeVoxel(:,1), excludeVoxel(:,2), excludeVoxel(:,3));
    ind = ind(~ismember(ind, excludeInd));
end

if isempty(ind)
    coordinates = [];
    values      = [];
    return
end

% a scatter3 of a million points is unusable, so show a sample of them
if isfield(opt,'maxCount') && numel(ind) > opt.maxCount
    warning([num2str(numel(ind)) ' voxels thresholded. Only a random selection of ' ...
             num2str(opt.maxCount) ' voxels are plotted']);
    disp('The limit value can be changed in app/config/defaultDisplayOptions.m')
    ind = ind(randperm(numel(ind), opt.maxCount));
end

values = CT.img(ind);                      % from the original CT, not the denoised copy

crd = zeros(3, numel(ind));
[crd(1,:), crd(2,:), crd(3,:)] = ind2sub(size(CT.img), ind);
coordinates = mesh2AnatSpace(crd', S2);
end
