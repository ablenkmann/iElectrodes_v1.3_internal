function [project, work, report] = trimImages(cfg, project, work)
%IELEC.TRIMIMAGES  Cut the project's volumes down to what it actually holds.
%
%   [project, work, report] = ielec.trimImages(cfg, project, work) crops
%   every volume in the project - the MRI, the CT, the brain mask and the
%   parcellation - to a box around everything the project holds in space,
%   and moves each image-to-world transformation so that nothing moves.
%   WORK is not changed.
%
%   Options (cfg):
%     cfg.margin  how much room to leave around it, in millimetres.
%                                                             Default: 10
%     cfg.box     a box in voxels, [lo; hi], instead of one worked out from
%                 the project. The margin is not added to it. Default: []
%
%     report.box      the box that was used, in voxels of the volume as it
%                     was before this call, as [lo; hi]
%     report.trimmed  which volumes were cropped
%     report.before   their size before
%     report.after    their size after
%     report.kept     the fraction of the volume kept, 0 to 1
%
%   ANATOMICAL COORDINATES DO NOT MOVE
%
%   This is what makes trimming safe. A project stores contacts, targets and
%   surfaces in anatomical space, in millimetres - not in voxels. Cropping
%   changes which voxel a point sits in, and the transformation is moved by
%   exactly the same amount, so every millimetre coordinate in the project
%   still means the same place. Nothing is re-registered and no contact
%   moves.
%
%   WHAT THE BOX COVERS, AND WHY IT IS NOT THE BRAIN
%
%   The author asked to "trim MRI and CT images to the brain only (some
%   extra cm around is fine)". Taken literally - the brain mask - it cuts
%   the brain. Measured on examples/exampleNativeSpace.iel:
%
%       mask       [27 35 78] .. [147 175 208]
%       surfaces   [18 27 85] .. [154 186 210]
%       contacts   [61 74 117] .. [130 133 203]
%       targets    [12 23 93] .. [105 182 219]
%
%   The pial surfaces reach outside the mask in every direction, because the
%   mask is the inskull mask and the surface sits against it. The planning
%   targets are outside everything, which is what planning is.
%
%   So the box is the union of all of them - mask, surfaces, envelope,
%   localized contacts, planned targets - and then the margin. On that
%   project it keeps 29 per cent of the volume, which is the saving asked
%   for without cutting anything the project knows about.
%
%   IT CANNOT BE UNDONE
%
%   What is outside the box is gone from the project, and saving it writes
%   the smaller images. The images on disk are untouched; a project can be
%   built again from them.
%
%   THE COLOUR CACHES
%
%   wmparcColors holds one colour per voxel and is display data, so it is
%   not in the project and cannot be cropped here. After trimming it no
%   longer matches the parcellation. Call IELEC.COLOURCACHES to rebuild it.
%   report.trimmed names the parcellation when this matters.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:noMRI, ielec:badOption, ielec:emptyBox (the box would keep
%   no voxels), and those of the cfg check.
%
%   Example
%       [project, work, r] = ielec.trimImages(struct('margin', 15), ...
%                                             project, work);
%       fprintf('kept %.0f%%\n', 100 * r.kept);
%       [project, work, caches] = ielec.colourCaches([], project, work);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.NEWPROJECT, IELEC.LOADCT, IELEC.COLOURCACHES,
%   ANATSPACE2MESH.

if ~isfield(project, 'T1') || isempty(project.T1)
    error('ielec:noMRI', ...
        'ielec.trimImages: there is no MRI, so there is nothing to trim.');
end

defaults.margin = 10;
defaults.box    = [];
cfg = checkCfg(cfg, defaults, {}, 'trimImages');

if ~isnumeric(cfg.margin) || ~isscalar(cfg.margin) || ...
        ~isfinite(cfg.margin) || cfg.margin < 0
    error('ielec:badOption', ...
        'ielec.trimImages: cfg.margin is a distance in millimetres, 0 or more.');
end

D = size(project.T1.img);
D = D(1:3);

if ~isempty(cfg.box)
    if ~isnumeric(cfg.box) || ~isequal(size(cfg.box), [2 3]) || ...
            ~all(isfinite(cfg.box(:))) || any(mod(cfg.box(:), 1) ~= 0)
        error('ielec:badOption', ...
            'ielec.trimImages: cfg.box is [lo; hi], two rows of three whole voxels.');
    end
    lo = cfg.box(1,:);
    hi = cfg.box(2,:);
else
    [lo, hi] = boxAround(project, D, cfg.margin);
end

lo = max(floor(lo), [1 1 1]);
hi = min(ceil(hi),  D);
if any(hi < lo)
    error('ielec:emptyBox', ...
        'ielec.trimImages: that box keeps no voxels.');
end
cfg.box = [lo; hi];          % recorded as the box actually used

% New voxel n is old voxel n + lo - 1, so the transformation is moved by
% exactly that and every millimetre coordinate still means the same place.
shift         = eye(4);
shift(1:3, 4) = lo(:) - 1;

idx = {lo(1):hi(1), lo(2):hi(2), lo(3):hi(3)};

report.box     = [lo; hi];
report.trimmed = {};
report.before  = D;
report.after   = hi - lo + 1;
report.kept    = prod(report.after) / prod(D);

for f = {'T1', 'TAC', 'mask', 'wmparc'}
    name = f{1};
    if ~isfield(project, name) || isempty(project.(name)), continue, end
    v = project.(name);
    if ~isstruct(v) || ~isfield(v, 'img') || isempty(v.img), continue, end
    if ~isequal(size(v.img), D)
        % a volume on a different grid is not ours to cut
        continue
    end

    v.img = v.img(idx{:});
    if isfield(v, 'vol') && isstruct(v.vol)
        v.vol.mat = v.vol.mat * shift;
        v.vol.dim = report.after;
    end
    project.(name)  = v;
    report.trimmed{end+1} = name;
end

% the transformations the project keeps beside the volumes
project.S2 = project.S2 * shift;
if isfield(project, 'wmparcS') && ~isempty(project.wmparcS)
    project.wmparcS = project.wmparcS * shift;
end

project = recordStep(project, mfilename, cfg);
end

% ---------------------------------------------------------------------
function [lo, hi] = boxAround(project, D, marginMM)
%BOXAROUND  The voxels everything the project holds in space falls in.

lo = [ inf  inf  inf];
hi = [-inf -inf -inf];

% the brain mask, where it has one
if isfield(project, 'mask') && ~isempty(project.mask) && ...
        isstruct(project.mask) && isfield(project.mask, 'img') && ...
        ~isempty(project.mask.img)
    inside = project.mask.img > 0.5;
    if any(inside(:))
        [i, j, k] = ind2sub(size(inside), find(inside));
        lo = min(lo, [min(i) min(j) min(k)]);
        hi = max(hi, [max(i) max(j) max(k)]);
    end
end

% every set of points the project stores in millimetres
points = [];
for f = {'verticesR', 'verticesL', 'vertices_SCE_R', 'vertices_SCE_L'}
    if isfield(project, f{1}) && ~isempty(project.(f{1}))
        points = [points; project.(f{1})]; %#ok<AGROW>
    end
end
for g = {'electrodes', 'targets'}
    arrays = [];
    if isfield(project, g{1}), arrays = project.(g{1}); end
    for a = 1:numel(arrays)
        one = arrays{a};
        if isfield(one, 'x') && ~isempty(one.x)
            points = [points; one.x(:) one.y(:) one.z(:)]; %#ok<AGROW>
        end
        if isfield(one, 'projection') && ~isempty(one.projection)
            q = one.projection{1};
            if isfield(q, 'x') && ~isempty(q.x)
                points = [points; q.x(:) q.y(:) q.z(:)]; %#ok<AGROW>
            end
        end
    end
end

if ~isempty(points)
    v  = AnatSpace2Mesh(points, project.S2);
    lo = min(lo, min(v, [], 1));
    hi = max(hi, max(v, [], 1));
end

if any(~isfinite([lo hi]))
    % nothing to go by: keep the volume as it is
    lo = [1 1 1];
    hi = D;
    return
end

% the margin is in millimetres, and a voxel is not a millimetre
voxelMM = abs(diag(project.S2(:, 1:3))');
voxelMM(voxelMM == 0) = 1;
pad = marginMM ./ voxelMM;

lo = lo - pad;
hi = hi + pad;
end
