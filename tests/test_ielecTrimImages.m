function ok = test_ielecTrimImages()
%TEST_IELECTRIMIMAGES  Check that trimming the volumes moves nothing.
%
%   ok = test_ielecTrimImages() trims the example project and checks that
%   every coordinate it holds still means the same place, that nothing it
%   holds falls outside the smaller images, and that the result survives
%   being saved and opened again.
%
%   WHY THIS IS THE CHECK
%
%   The author asked to "trim MRI and CT images to the brain only (some
%   extra cm around is fine)". Trimming is safe only because a project
%   stores contacts, targets and surfaces in millimetres rather than in
%   voxels: cropping changes which voxel a point sits in, and moving the
%   image-to-world transformation by the same amount leaves the millimetres
%   alone. If that is ever got wrong, every contact in the project moves and
%   the pictures still look right - the slices still show a brain and the
%   contacts still sit on something.
%
%   So the checks are the two that would catch it: the stored millimetres
%   must be identical, and the same millimetre point must land on the same
%   image intensity through the new transformation as it did through the
%   old one.
%
%   The box is the union of everything the project holds, not the brain
%   mask. Measured on this project, the pial surfaces reach outside the mask
%   in every direction, so trimming to the mask would cut the brain - which
%   is the second check here.
%
%   Usage:  cd into the repository, then
%              test_ielecTrimImages
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.TRIMIMAGES, ANATSPACE2MESH, IELEC.COLOURCACHES.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

ielFile = fullfile(repoRoot, 'examples', 'exampleNativeSpace.iel');
[project, work] = ielec.openProject(struct('file', ielFile), [], []);

contactsBefore = everyContact(project);
surfaceBefore  = [project.verticesR; project.verticesL];

[trimmed, trimmedWork, report] = ielec.trimImages(struct('margin', 10), ...
    project, work);

%% ----------------------------------------------- it did cut something
fprintf('\n--- the volumes are smaller ----------------------------------\n');

nFail = nFail + check(all(report.after <= report.before) && ...
    any(report.after < report.before), 'the volumes were cut down', ...
    sprintf('%s -> %s, keeping %.1f%%', mat2str(report.before), ...
            mat2str(report.after), 100 * report.kept));
nFail = nFail + check(numel(report.trimmed) == 4, ...
    'all four volumes were cut, not some of them', ...
    strjoin(report.trimmed, ', '));
nFail = nFail + check(isequal(size(trimmed.T1.img), size(trimmed.TAC.img)) && ...
    isequal(size(trimmed.T1.img), size(trimmed.mask.img)) && ...
    isequal(size(trimmed.T1.img), size(trimmed.wmparc.img)), ...
    'and they are all still the same size as each other', ...
    mat2str(size(trimmed.T1.img)));
nFail = nFail + check(isequaln(trimmedWork, work), 'work is not changed', '');

%% -------------------------------------------- nothing moved, in millimetres
fprintf('\n--- and nothing moved ----------------------------------------\n');

nFail = nFail + check(isequaln(everyContact(trimmed), contactsBefore), ...
    'every contact is where it was', ...
    sprintf('%d contacts', size(contactsBefore, 1)));
nFail = nFail + check(isequaln([trimmed.verticesR; trimmed.verticesL], ...
    surfaceBefore), 'and every vertex of the surfaces', ...
    sprintf('%d vertices', size(surfaceBefore, 1)));

% the same millimetre point, through the two transformations, must find the
% same voxel value - this is what catches a transformation moved wrongly
pts    = contactsBefore(1:min(20, end), :);
wasAt  = round(AnatSpace2Mesh(pts, project.S2));
nowAt  = round(AnatSpace2Mesh(pts, trimmed.S2));
same   = true;
for i = 1:size(pts, 1)
    a = project.T1.img(wasAt(i,1), wasAt(i,2), wasAt(i,3));
    b = trimmed.T1.img(nowAt(i,1), nowAt(i,2), nowAt(i,3));
    same = same && isequaln(a, b);
end
nFail = nFail + check(same, ...
    'and finds the same image intensity through the new transformation', ...
    sprintf('shifted by %s voxels', mat2str(wasAt(1,:) - nowAt(1,:))));

nFail = nFail + check(~isequal(trimmed.S2, project.S2), ...
    'which it would not if the transformation had been left alone', ...
    'S2 moved with the images');

%% ------------------------------------- nothing it holds was cut off
fprintf('\n--- and nothing it holds fell outside ------------------------\n');

held = [surfaceBefore; contactsBefore; everyTarget(project)];
v    = AnatSpace2Mesh(held, trimmed.S2);
D    = size(trimmed.T1.img);
inside = all(v >= 1, 2) & all(v <= D, 2);
nFail = nFail + check(all(inside), ...
    'every point the project holds is still in the images', ...
    sprintf('%d of %d', sum(inside), numel(inside)));

% the measurement that says why the box is not the mask
m = project.mask.img > 0.5;
[i, j, k] = ind2sub(size(m), find(m));
maskBox = [min([i j k]); max([i j k])];
sv = AnatSpace2Mesh(surfaceBefore, project.S2);
nFail = nFail + check(any(min(sv) < maskBox(1,:)) || ...
    any(max(sv) > maskBox(2,:)), ...
    'the surfaces do reach outside the brain mask', ...
    'so the mask alone would cut the brain');

%% ------------------------------------------------- it survives the file
fprintf('\n--- and it survives being saved and opened again -------------\n');

out = fullfile(tempdir, ['iElectrodes_trim_' ...
    char(java.util.UUID.randomUUID) '.iel']);
removeLater = onCleanup(@() deleteIfThere(out));
ielec.saveProject(struct('file', out), trimmed, trimmedWork);
back = ielec.openProject(struct('file', out), [], []);

nFail = nFail + check(isequal(size(back.T1.img), size(trimmed.T1.img)), ...
    'the smaller images come back', mat2str(size(back.T1.img)));
nFail = nFail + check(isequaln(everyContact(back), contactsBefore), ...
    'with every contact still where it started', '');
nFail = nFail + check(dir(out).bytes < dir(ielFile).bytes, ...
    'and the file is smaller than the one it came from', ...
    sprintf('%.1f MB against %.1f MB', dir(out).bytes/1048576, ...
            dir(ielFile).bytes/1048576));

%% ----------------------------------------------------- the step and the cfg
fprintf('\n--- what the project records ---------------------------------\n');

step = trimmed.history{end};
nFail = nFail + check(strcmp(step.function, 'ielec.trimImages'), ...
    'the step is recorded', step.function);
nFail = nFail + check(isequaln(step.cfg.box, report.box), ...
    'with the box it actually used, not the one it was asked for', ...
    mat2str(step.cfg.box));

%% ----------------------------------------------------- what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

nFail = nFail + check(strcmp(errorId(@() ielec.trimImages( ...
    struct('margin', -1), project, work)), 'ielec:badOption'), ...
    'a margin of less than nothing', '');
nFail = nFail + check(strcmp(errorId(@() ielec.trimImages( ...
    struct('box', [1 1 1]), project, work)), 'ielec:badOption'), ...
    'a box that is not two rows of three', '');
nFail = nFail + check(strcmp(errorId(@() ielec.trimImages( ...
    struct('box', [10 10 10; 5 5 5]), project, work)), 'ielec:emptyBox'), ...
    'a box with nothing in it', '');

empty = liftToWork(liftToProject(checkProjectStructure([], struct())));
nFail = nFail + check(strcmp(errorId(@() ielec.trimImages( ...
    [], empty.project, empty.work)), 'ielec:noMRI'), ...
    'a project with no images at all', '');

%% --------------------------------------------------------- layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.trimImages) == 3 && ...
    nargout(@ielec.trimImages) == 3, ...
    '[project, work, report] = ielec.trimImages(cfg, project, work)', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the images are smaller and nothing in them moved.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function pts = everyContact(project)
pts = [];
if ~isfield(project, 'electrodes'), return, end
for a = 1:numel(project.electrodes)
    e = project.electrodes{a};
    if isfield(e, 'x') && ~isempty(e.x)
        pts = [pts; e.x(:) e.y(:) e.z(:)]; %#ok<AGROW>
    end
end
end

function pts = everyTarget(project)
pts = [];
if ~isfield(project, 'targets'), return, end
for a = 1:numel(project.targets)
    t = project.targets{a};
    if isfield(t, 'x') && ~isempty(t.x)
        pts = [pts; t.x(:) t.y(:) t.z(:)]; %#ok<AGROW>
    end
end
end

function deleteIfThere(f)
if isfile(f), delete(f); end
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
    fprintf('  ok        %-56s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-56s %s\n', what, detail);  bad = 1;
end
end
