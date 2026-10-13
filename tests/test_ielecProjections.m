function ok = test_ielecProjections()
%TEST_IELECPROJECTIONS  Check ielec.projectionState and ielec.projectArrays.
%
%   ok = test_ielecProjections() projects the example project's arrays onto
%   the smooth cortical envelope through the layer, and compares the result
%   with the code the SCE checkbox ran itself, kept verbatim below - both
%   ways the checkbox can run it: all the arrays again, and only the new
%   ones.
%
%   The projection method is set to 'closestPoint' so that the comparison is
%   about the layer and not about an optimizer: the springs and CEPA methods
%   are iterative, and a test that has to run one twice is a slow test.
%
%   Usage:  cd into the repository, then
%              test_ielecProjections
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.PROJECTIONSTATE, IELEC.PROJECTARRAYS,
%            ELECTRODES2HULLCORRECTION, SCESURFACEFORSPACE.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

cfgOpen = [];
cfgOpen.file = fullfile(repoRoot, 'examples', 'exampleNativeSpace.iel');
[project, work] = ielec.openProject(cfgOpen, [], []);
work.options.SCE_projection_method = 'closestPoint';

% what the arrays are, read from the project itself and not from the
% function under test
types        = cellfun(@(e) e.Type, project.electrodes, 'UniformOutput', false);
onSurface    = strcmp(types, 'grid') | strcmp(types, 'strip');
hasProjection = cellfun(@(e) ~isempty(e.projection), project.electrodes);

%% ------------------------------------------------ projectionState: reporting
fprintf('\n--- ielec.projectionState against the checkbox''s own questions -\n');

expectedState = originalState(project, work);
[stateProject, stateWork, state] = ielec.projectionState([], project, work);

nFail = nFail + check(isequal(state.projectable, expectedState.projectable) && ...
        isequal(state.alreadyDone, expectedState.alreadyDone), ...
    'which arrays can be projected, and which are', ...
    sprintf('%d of %d projectable', sum(state.projectable), numel(state.projectable)));
nFail = nFail + check(isequal(logical(state.projectable), logical(onSurface)) && ...
        isequal(logical(state.alreadyDone), logical(hasProjection)), ...
    'the grids and the strips, and what has a projection', ...
    strjoin(types, ' '));
nFail = nFail + check(state.anyProjectable == any(onSurface) && ...
        state.allDone == all(hasProjection), ...
    'the two answers the checkbox acts on', ...
    sprintf('anyProjectable %d, allDone %d', state.anyProjectable, state.allDone));
nFail = nFail + check(state.surfaceAvailable == ~isempty(expectedState.vertices), ...
    'whether there is an envelope to project onto', ...
    sprintf('%d vertices', size(expectedState.vertices,1)));
nFail = nFail + check(state.surfaceAvailable, ...
    'the example has a native envelope (the rest needs one)', '');
nFail = nFail + check(isequaln(stateProject, project) && isequaln(stateWork, work), ...
    'it only reports: project and work come back untouched', '');

%% ------------------------------------- projectArrays: 'Yes, all' - everything
fprintf('\n--- ielec.projectArrays against the checkbox''s own steps -------\n');

expected = originalProjection(project, work, true);
[projected, projectedWork] = ielec.projectArrays(struct('recalculateAll', true), project, ...
                                                  work);

nFail = nFail + check(isequaln(projected.electrodes, expected.electrodes), ...
    'every contact lands where the checkbox put it', ...
    firstDisplacement(projected));
nFail = nFail + check(isequaln(projectedWork, work), ...
    'work is not changed', '');
nFail = nFail + check(isequaln(withoutHistory(rmfield(projected, 'electrodes')), withoutHistory(...
        rmfield(project, 'electrodes'))) && ...
        isequal(fieldnames(projected), fieldnames(project)), ...
    'and nothing but the electrodes in the project', '');
nFail = nFail + check(any(onSurface) && ...
        all(cellfun(@(e) ~isempty(e.projection), projected.electrodes(onSurface))), ...
    'each grid and strip carries a projection now', ...
    sprintf('%d of them', sum(onSurface)));

%% --------------------------- projectArrays: 'No, only the new one(s)' - some
fprintf('\n--- and only the new one(s), which is the default answer ------\n');

% one array localized after the last projection: everything else is done
partial      = projected;
newOne       = find(onSurface, 1);
partial.electrodes{newOne}.projection = [];

[~, ~, partialState] = ielec.projectionState([], partial, work);
nFail = nFail + check(~partialState.allDone && partialState.anyProjectable, ...
    'the report sees the one that is not projected', ...
    sprintf('array %d, %s', newOne, partial.electrodes{newOne}.Name));

expectedPartial = originalProjection(partial, work, false);
partialDone     = ielec.projectArrays([], partial, work);

nFail = nFail + check(isequaln(partialDone.electrodes, expectedPartial.electrodes), ...
    'the new one is projected as the checkbox projected it', '');
nFail = nFail + check(~isempty(partialDone.electrodes{newOne}.projection), ...
    'it has a projection now', '');
others = setdiff(1:numel(types), newOne);
nFail = nFail + check(isequaln(partialDone.electrodes(others), ...
        projected.electrodes(others)), ...
    'and the ones that were done are untouched', ...
    sprintf('%d arrays', numel(others)));

%% ------------------------------------------------------------ nothing to redo
fprintf('\n--- a third call, with nothing left to do --------------------\n');

[again, againWork] = ielec.projectArrays([], projected, work);
nFail = nFail + check(isequaln(again, projected) && isequaln(againWork, work), ...
    'a project that is fully projected is left alone', '');

%% -------------------------------------------------------------- what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

depthsOnly = project;
for i = 1:numel(depthsOnly.electrodes)
    depthsOnly.electrodes{i}.Type = 'depth';
end
nFail = nFail + check(strcmp(errorId(@() ielec.projectArrays([], depthsOnly, work)), ...
        'ielec:noArraysToProject'), ...
    'a project with no grid or strip', '');

[~, ~, depthsState] = ielec.projectionState([], depthsOnly, work);
nFail = nFail + check(~depthsState.anyProjectable, ...
    'which the report says before the call', '');

noEnvelope = project;
noEnvelope.vertices_SCE_L = [];
noEnvelope.vertices_SCE_R = [];
nFail = nFail + check(strcmp(errorId(@() ielec.projectArrays(...
                                                              struct('recalculateAll', true), ...
                                                              noEnvelope, work)), 'ielec:noSurface'), ...
    'a patient with no envelope built yet', '');

[~, ~, stateNoEnvelope] = ielec.projectionState([], noEnvelope, work);
nFail = nFail + check(~stateNoEnvelope.surfaceAvailable && stateNoEnvelope.anyProjectable, ...
    'which the report also says before the call', '');

% MNI space, in a script that never loaded the template the GUI loads at
% start-up: a missing field is "no envelope", not an error from inside
noTemplate = work;
for f = {'v_MNI_SCE','f_MNI_SCE'}
    if isfield(noTemplate, f{1}), noTemplate = rmfield(noTemplate, f{1}); end
end
[~, ~, mniState] = ielec.projectionState(struct('space','MNI'), project, noTemplate);
nFail = nFail + check(~mniState.surfaceAvailable, ...
    'MNI space with no template loaded', '');
nFail = nFail + check(strcmp(errorId(@() ielec.projectArrays(...
        struct('space','MNI','recalculateAll',true), project, noTemplate)), 'ielec:noSurface'), ...
    'and the projection says so by name', '');

nFail = nFail + check(strcmp(errorId(@() ielec.projectArrays(struct('space', 'Talairach'), ...
                                                              project, work)), 'ielec:badOption'), ...
    'a space that is neither Native nor MNI', '');
nFail = nFail + check(strcmp(errorId(@() ielec.projectionState(...
        struct('recalculateAll', true), project, work)), 'ielec:unknownOption'), ...
    'an option the reporting call does not have', 'cfg.recalculateAll');
nFail = nFail + check(strcmp(errorId(@() ielec.projectArrays(struct('surface', 'pial'), ...
                                                              project, work)), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.surface');

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.projectArrays) == 3 && ...
        nargout(@ielec.projectArrays) == 2 && ...
        nargin(@ielec.projectionState) == 3 && ...
        nargout(@ielec.projectionState) == 3, ...
    'the signatures, the report as the third output', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the brain-shift correction is what the checkbox computed.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% What processProjections did between the checkbox and the labelling: ask the
% state, fetch the surface, correct the arrays. RECALCULATEALL is the answer
% to its question.

function s = originalState(project, work)
    arrays = project.electrodes;
    [s.projectable, s.alreadyDone] = arrayProjectionState(arrays);

    [s.vertices, s.faces] = sceSurfaceForSpace(project.currentSpace, ...
                                               project, work);
end

function project = originalProjection(project, work, recalculateAll)
    arrays = project.electrodes;
    [~, projDone] = arrayProjectionState(arrays);

    if recalculateAll
        projDone = false(size(projDone)); % 'Yes, all'
    end                                   % otherwise: only the new one(s)

    [vertices, faces] = sceSurfaceForSpace(project.currentSpace, ...
                                           project, work);

    project.electrodes = electrodes2hullCorrection(arrays, vertices, faces, ...
                                                   work.options, projDone);
end

% ---------------------------------------------------------------------
function text = firstDisplacement(project)
% how far the first projected contact moved, to show that it did
text = '';
for i = 1:numel(project.electrodes)
    p = project.electrodes{i}.projection;
    if ~isempty(p) && isfield(p{1}, 'displacement') && ~isempty(p{1}.displacement)
        text = sprintf('first contact moved %.1f mm', p{1}.displacement(1));
        return
    end
end
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
