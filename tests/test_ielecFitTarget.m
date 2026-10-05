function ok = test_ielecFitTarget()
%TEST_IELECFITTARGET  Check ielec.fitTarget.
%
%   ok = test_ielecFitTarget() plans a grid on the example project's
%   envelope, fits it to that envelope, and compares the result with the
%   lines the "Fit grid to surface" button ran itself, kept verbatim at the
%   end of this file.
%
%   The springs projection is an FMINCON run from a fixed starting point
%   with no parallelism, so the same grid and the same mesh give the same
%   answer twice; that is what makes the comparison possible. It is also
%   the slowest part of this test by far.
%
%   The fit is checked for having done something, not only for matching:
%   a comparison of two no-ops would pass whatever the function did.
%
%   Usage:  cd into the repository, then
%              test_ielecFitTarget
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.FITTARGET, ELECTRODES2HULLCORRECTION, IELEC.NEWTARGET.

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

if isempty(project.vertices_SCE_R)
    fprintf(['\nThe example project has no cortical envelope, so a planning ' ...
             'grid cannot be fitted to it.\nNothing to check.\n\n']);
    ok = true; if nargout == 0, clear ok; end, return
end

% a grid to fit: planned the way the New planning grid button plans one
onTheBrain = project.vertices_SCE_R(1, :);
cfgNew = [];
cfgNew.centre  = onTheBrain;
cfgNew.rows    = 2;
cfgNew.columns = 3;
cfgNew.spacing = 10;
[planned, work, index] = ielec.newTarget(cfgNew, project, work);

%% --------------------------------------- fitting it, against the button
fprintf('\n--- ielec.fitTarget against the Fit grid to surface button ----\n');

expected = originalFit(planned, index, work);

[fitted, fittedWork] = ielec.fitTarget(struct('index', index), planned, work);

nFail = nFail + check(isequaln(fitted.targets{index}, expected.target), ...
    'the fitted grid is the one the button fitted', ...
    sprintf('%d by %d', cfgNew.rows, cfgNew.columns));
nFail = nFail + check(isequaln(fittedWork, work), ...
    'work is not changed', '');
nFail = nFail + check(isequaln(rmfield(fitted, 'targets'), ...
        rmfield(planned, 'targets')), ...
    'and nothing else in the project is', '');
nFail = nFail + check(isequaln(fitted.targets([1:index-1, index+1:end]), ...
        planned.targets([1:index-1, index+1:end])), ...
    'nor any other planning target', ...
    sprintf('%d target(s) beside it', numel(planned.targets) - 1));

%% ----------------------------------------------- and having done something
fprintf('\n--- and the fit is a fit -------------------------------------\n');

before = planned.targets{index};
after  = fitted.targets{index};

nFail = nFail + check(~isempty(fieldOr(after, 'projection', [])), ...
    'the target has a projection it did not have', ...
    sprintf('%d projection(s)', numel(fieldOr(after, 'projection', {}))));

proj = after.projection{1};
nFail = nFail + check(any(abs(proj.displacement(:)) > 1e-6), ...
    'the contacts moved onto the surface', ...
    sprintf('largest displacement %.3g mm', max(abs(proj.displacement(:)))));
nFail = nFail + check(strcmp(proj.method, ' SCE_springs'), ...
    'by the springs method, not the project''s default', proj.method);
nFail = nFail + check(isequaln([after.x after.y after.z], ...
        [before.x before.y before.z]), ...
    'and the planned coordinates themselves are left alone', ...
    'the fit lives in .projection');

%% ------------------------------------------------------ what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

noEnvelope = planned;
noEnvelope.vertices_SCE_L = [];
nFail = nFail + check(strcmp(errorId(@() ielec.fitTarget(struct('index', index), ...
        noEnvelope, work)), 'ielec:noSurfaces'), ...
    'no envelope to fit it to', '');
nFail = nFail + check(strcmp(errorId(@() ielec.fitTarget(...
        struct('index', numel(planned.targets) + 1), planned, work)), ...
        'ielec:badOption'), ...
    'a target that is not in the project', 'cfg.index');
nFail = nFail + check(strcmp(errorId(@() ielec.fitTarget([], planned, work)), ...
        'ielec:missingOption'), ...
    'no index at all', 'cfg.index');
nFail = nFail + check(strcmp(errorId(@() ielec.fitTarget(...
        struct('index', index, 'space', 'MNI'), planned, work)), ...
        'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.space');

%% ------------------------------------------------- and what is NOT refused
fprintf('\n--- and what is not refused ----------------------------------\n');

% A depth target reaches ELECTRODES2HULLCORRECTION, which warns and gives it
% back unchanged. That is what the button did, and the panel can reach it, so
% the layer does not turn it into an error - see docs/OPEN_QUESTIONS.md item 36.
withDepth = planned;
withDepth.targets{end+1} = depthLikeTarget();
lastDepth = numel(withDepth.targets);
warnBefore = warning('off', 'all');
[depthFitted, depthWork] = ielec.fitTarget(struct('index', lastDepth), withDepth, work);
warning(warnBefore);
nFail = nFail + check(isequaln(depthFitted.targets{lastDepth}, ...
        withDepth.targets{lastDepth}), ...
    'a planned depth electrode comes back unchanged', 'as the button left it');
nFail = nFail + check(isequaln(depthWork, work), ...
    'and work is still not changed', '');

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.fitTarget) == 3 && ...
        nargout(@ielec.fitTarget) == 2, ...
    'fitTarget''s signature', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - a planned grid is fitted as the button fitted it.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% What fitPlanningGridButton_Callback ran, with the selected array taken out.

function out = originalFit(project, a, work)
    handles.project = project;
    handles.work    = work;

    target=handles.project.targets{a};

    options=handles.work.options;
    options.SCE_projection_method = 'springs';
    options.SCE_springs_projection = options.SCE_springs_projection_planning;


    [vertices,faces] = mergemesh(handles.project.vertices_SCE_L, handles.project.faces_SCE_L, handles.project.vertices_SCE_R, handles.project.faces_SCE_R );
    targetCell = electrodes2hullCorrection({target},vertices,faces,options);

    handles.project.targets{a}=targetCell{1};

    out.target = handles.project.targets{a};
end

% ---------------------------------------------------------------------
function target = depthLikeTarget()
% the empty depth planning array the New target button starts from.
% CHECKELECTRODESTRUCTURE returns a struct for a struct, a cell for a cell.
target=[];
target.Type='depth';
target.Name='Planning';
target.planning='yes';
target=checkElectrodeStructure(target);
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end

function id = errorId(f)
id = '';
try
    f();
catch err
    id = err.identifier;
    if isempty(id), id = err.message; end
end
end

function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-52s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-52s %s\n', what, detail);  bad = 1;
end
end
