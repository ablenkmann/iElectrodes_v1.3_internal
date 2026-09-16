function ok = test_labelingMNI()
%TEST_LABELINGMNI  Check anatomical labelling in MNI space, without a figure.
%
%   ok = test_labelingMNI() labels the electrodes of
%   examples/exampleMNIspace.iel against the Harvard-Oxford atlas and checks
%   the result. It is the MNI-space counterpart of compare_labelingBaseline,
%   which covers native space only.
%
%   It exists for two reasons.
%
%   The first is coverage: item 4 of the restructuring is "labelling to
%   native space and to MNI space, separated", and only the native half had
%   a test.
%
%   The second is the atlas itself. MNIlabels, MNIprob and MNI_S_matrix are
%   loaded once at start-up and kept in handles.work. If they were ever lost
%   or mixed up, the GUI would not crash - anatomicLabel would simply warn
%   that the coordinates are outside the atlas and hand back empty labels,
%   which looks like a labelling problem rather than a missing atlas. This
%   test tells the two apart.
%
%   What a failure here means
%     'atlas out of MNI space'   the atlas or the transform is wrong, or the
%                                project's coordinates are not in MNI space
%     'labels differ'            the labelling changed against what the
%                                project file already holds
%
%   Usage:  cd into the repository, then
%              test_labelingMNI
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also LABELELECTRODESMNI, ANATOMICLABEL, COMPARE_LABELINGBASELINE.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

nFail = 0;

%% the atlas, loaded the same way defaultGuiVariables loads it
fprintf('\n--- the Harvard-Oxford atlas ---------------------------------\n');
atlas = load('HOatlas_cort-subCort_lateralized.mat');   % labels, prob, S

nFail = nFail + check(isfield(atlas,'labels') && isfield(atlas,'prob') && ...
                      isfield(atlas,'S'), 'the file holds labels, prob and S', '');
if nFail > 0
    fprintf('\nFAIL - the atlas file is not what was expected.\n\n');
    ok = false; if nargout == 0, clear ok; end, return
end

S      = atlas.S;
labels = atlas.labels;
prob   = atlas.prob;

nFail = nFail + check(isequal(size(S),[3 4]), 'S is a 3x4 transform', '');
nFail = nFail + check(ndims(prob.img) == 4, 'prob.img is a 4-D volume', ...
    sprintf('%s', mat2str(size(prob.img))));
nFail = nFail + check(numel(labels) == size(prob.img,4), ...
    'one label per probability volume', sprintf('(%d)', numel(labels)));

%% the project
ielFile = fullfile(repoRoot,'examples','exampleMNIspace.iel');
if ~isfile(ielFile)
    fprintf('\nThe MNI example project is not here - nothing more to check.\n\n');
    ok = (nFail == 0); if nargout == 0, clear ok; end, return
end

loaded = load(ielFile,'-mat');
prj    = checkProjectStructure(loaded.s);

fprintf('\n--- labelling each electrode array ---------------------------\n');
fprintf('   %s, %d electrode arrays\n', 'exampleMNIspace.iel', numel(prj.electrodes));

anyLabelled = false;
for l = 1:numel(prj.electrodes)
    e   = prj.electrodes{l};
    pos = [e.x e.y e.z];

    lastwarn('');
    aLabels = anatomicLabel(pos, S, labels, prob);
    outside = ~isempty(strfind(lastwarn, 'out of MNI matrix space')); %#ok<STREMP>

    nFail = nFail + check(~outside, ...
        sprintf('array %d (%s) is inside the atlas', l, e.Name), ...
        sprintf('%d contacts', size(pos,1)));

    if outside, continue, end

    nFail = nFail + check(size(aLabels,1) == size(pos,1), ...
        sprintf('array %d has one row per contact', l), '');

    named = 0;
    for i = 1:size(aLabels,1)
        if ~isempty(aLabels{i,1}), named = named + 1; end
    end
    nFail = nFail + check(named > 0, ...
        sprintf('array %d got anatomical labels', l), ...
        sprintf('%d of %d contacts', named, size(aLabels,1)));
    anyLabelled = anyLabelled || (named > 0);

    % the strongest check available: the labels stored in the project were
    % produced by the toolbox itself, before any of this restructuring
    if isfield(e,'aLabels') && ~isempty(e.aLabels) && iscell(e.aLabels)
        same = isequaln(e.aLabels, aLabels);
        nFail = nFail + check(same, ...
            sprintf('array %d reproduces the stored labels', l), '');
        if ~same && isequal(size(e.aLabels), size(aLabels))
            differing = 0;
            for i = 1:numel(aLabels)
                if ~isequaln(e.aLabels{i}, aLabels{i}), differing = differing + 1; end
            end
            fprintf('              %d of %d entries differ\n', differing, numel(aLabels));
        end
    end
end

%% the whole function, the way the GUI calls it
fprintf('\n--- labelElectrodesMNI on the whole project ------------------\n');
fprintf('   (the planning targets are looked up at [x y y] - a known bug\n');
fprintf('    in v1.020, preserved on purpose; see labelElectrodesMNI.m)\n');

prj.MNI_S_matrix = S;
prj.MNIlabels    = labels;
prj.MNIprob      = prob;

warnState = warning('off','all');
labelled  = labelElectrodesMNI(prj);
warning(warnState);

nFail = nFail + check(numel(labelled.electrodes) == numel(prj.electrodes), ...
    'every electrode array comes back', '');

withLabels = 0;
for l = 1:numel(labelled.electrodes)
    if isfield(labelled.electrodes{l},'aLabels') && ~isempty(labelled.electrodes{l}.aLabels)
        withLabels = withLabels + 1;
    end
end
nFail = nFail + check(withLabels == numel(labelled.electrodes) || ~anyLabelled, ...
    'every electrode array carries labels', ...
    sprintf('%d of %d', withLabels, numel(labelled.electrodes)));

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - MNI labelling works and the atlas is intact.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-48s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-48s %s\n', what, detail);  bad = 1;
end
end
