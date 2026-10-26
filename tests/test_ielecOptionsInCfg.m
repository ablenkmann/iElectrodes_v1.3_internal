function ok = test_ielecOptionsInCfg()
%TEST_IELECOPTIONSINCFG  Check that a call can set what decides its result.
%
%   ok = test_ielecOptionsInCfg() checks the five layer functions that used
%   to take a decision out of work.options without the caller being able to
%   set it or the project being able to record it.
%
%   WHAT THIS IS FOR
%
%   The toolbox author: "cfg should carry all the low-level configuration
%   options a method needs to run. I have the feeling that some of that is
%   taken from work.options."
%
%   Seven functions had that shape. IELEC.LABEL and IELEC.POINTLABEL are
%   checked in tests/test_ielecLabelOptions.m; the other five are here:
%
%     ielec.projectArrays  cfg.method            where a contact is carried
%     ielec.indexArray     cfg.projectionMethod  how contacts are ordered
%     ielec.buildEnvelope  cfg.radius            the envelope's shape
%     ielec.fitTarget      cfg.springs           where a planned grid rests
%     ielec.fitArray       cfg.gridFit           how the model is fitted
%
%   Each must do three things: take the value, fall back to the session's
%   when it is not given, and record whichever was used - because RECORDSTEP
%   writes the cfg, and work.options never reaches the .iel.
%
%   The two slow ones, fitTarget and fitArray, have their recording checked
%   in their own tests, which already pay for a real fit. Here they are
%   checked for what they refuse, which costs nothing.
%
%   See docs/OPEN_QUESTIONS.md item 51.
%
%   Usage:  cd into the repository, then
%              test_ielecOptionsInCfg
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also TEST_IELECLABELOPTIONS, IELEC.PROJECTARRAYS, IELEC.INDEXARRAY,
%            IELEC.BUILDENVELOPE.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

[project, work] = ielec.openProject(struct('file', ...
    fullfile(repoRoot, 'examples', 'exampleNativeSpace.iel')), [], []);

%% --------------------------------------------------- projectArrays
fprintf('\n--- ielec.projectArrays: which way the contacts are carried --\n');

[a, aw] = ielec.projectArrays( ...
    struct('method', 'closestPoint', 'recalculateAll', true), project, work);
[b, ~]  = ielec.projectArrays( ...
    struct('method', 'springs', 'recalculateAll', true), project, work);

pa = a.electrodes{1}.projection{1};
pb = b.electrodes{1}.projection{1};
apart = max(abs([pa.x(:)-pb.x(:); pa.y(:)-pb.y(:); pa.z(:)-pb.z(:)]));

nFail = nFail + check(apart > 0, ...
    'two methods put the contacts in different places', ...
    sprintf('up to %.3f mm apart', apart));
nFail = nFail + check(strcmp(a.history{end}.cfg.method, 'closestPoint') && ...
    strcmp(b.history{end}.cfg.method, 'springs'), ...
    'and each step records the one it used', '');
nFail = nFail + check(isequaln(aw, work), 'work is not changed', '');

[c, ~] = ielec.projectArrays(struct('recalculateAll', true), project, work);
nFail = nFail + check(strcmp(c.history{end}.cfg.method, ...
    work.options.SCE_projection_method), ...
    'giving nothing records the session''s method', ...
    c.history{end}.cfg.method);

%% ------------------------------------------------------- indexArray
fprintf('\n--- ielec.indexArray: how the contacts are ordered -----------\n');

arr  = project.electrodes{1};
cfgI = struct('shape', 'grid', 'rows', arr.rows, 'columns', arr.columns, ...
              'index', 1, 'projectionMethod', 'PCA');
[d1, ~] = ielec.indexArray(cfgI, project, work);
nFail = nFail + check(strcmp(d1.history{end}.cfg.projectionMethod, 'PCA'), ...
    'the step records the method it was given', '');

cfgI = rmfield(cfgI, 'projectionMethod');
[d2, ~] = ielec.indexArray(cfgI, project, work);
nFail = nFail + check(strcmp(d2.history{end}.cfg.projectionMethod, ...
    work.options.indexing_projection_method), ...
    'and the session''s when it is not', ...
    d2.history{end}.cfg.projectionMethod);

%% ----------------------------------------------------- buildEnvelope
fprintf('\n--- ielec.buildEnvelope: the shape of the envelope ----------\n');

[e1, ew] = ielec.buildEnvelope(struct('radius', 30, 'resample', 2000), ...
    project, work);
nFail = nFail + check(e1.history{end}.cfg.radius == 30, ...
    'the step records the radius it was given', '');
nFail = nFail + check(~isempty(e1.vertices_SCE_R) && ...
    ~isempty(e1.vertices_SCE_L), 'and an envelope was built', ...
    sprintf('%d vertices', size(e1.vertices_SCE_R, 1)));
nFail = nFail + check(isequaln(ew, work), 'work is not changed', '');

[e2, ~] = ielec.buildEnvelope(struct('resample', 2000), project, work);
nFail = nFail + check(isequaln(e2.history{end}.cfg.radius, ...
    work.options.buildSCEradius), ...
    'and the session''s when it is not', ...
    sprintf('%g', e2.history{end}.cfg.radius));

%% ------------------------------------------- what the five refuse
fprintf('\n--- what they refuse -----------------------------------------\n');

nFail = nFail + check(strcmp(errorId(@() ielec.projectArrays( ...
    struct('method', 'nonsense'), project, work)), 'ielec:badOption'), ...
    'projectArrays: a method that does not exist', '');
nFail = nFail + check(strcmp(errorId(@() ielec.indexArray( ...
    struct('shape','grid','rows',4,'columns',5,'index',1, ...
           'projectionMethod','xyz'), project, work)), 'ielec:badOption'), ...
    'indexArray: a method that does not exist', '');
nFail = nFail + check(strcmp(errorId(@() ielec.buildEnvelope( ...
    struct('radius', -3), project, work)), 'ielec:badOption'), ...
    'buildEnvelope: a radius of less than nothing', '');
nFail = nFail + check(strcmp(errorId(@() ielec.buildEnvelope( ...
    struct('radius', [10 NaN]), project, work)), 'ielec:badOption'), ...
    'buildEnvelope: a NaN among several radii', '');

nFail = nFail + check(strcmp(errorId(@() ielec.fitTarget( ...
    struct('index', 1, 'springs', 7), project, work)), 'ielec:badOption'), ...
    'fitTarget: springs that are not a struct of settings', '');
nFail = nFail + check(strcmp(errorId(@() ielec.fitTarget( ...
    struct('index', 1, 'springs', struct('notASetting', 1)), ...
    project, work)), 'ielec:badOption'), ...
    'fitTarget: a springs setting that does not exist', '');

% fitArray refuses a call with nothing selected before it looks at any
% option, as it always has - so there has to be a selection for the GridFit
% settings to be reached at all
[thr, thrWork] = ielec.thresholdCT(struct('lowThreshold', 2500, ...
    'highThreshold', 4000), project, work);
[~, selWork] = ielec.selectVoxels(struct('indices', ...
    true(size(thrWork.candidateVoxels, 1), 1)), thr, thrWork);

fitCfg = struct('type','grid','rows',4,'columns',5,'spacing',10);
fitCfg.gridFit = 7;
nFail = nFail + check(strcmp(errorId(@() ielec.fitArray(fitCfg, ...
    project, selWork)), 'ielec:badOption'), ...
    'fitArray: GridFit settings that are not a struct', '');
fitCfg.gridFit = struct('notASetting', 1);
nFail = nFail + check(strcmp(errorId(@() ielec.fitArray(fitCfg, ...
    project, selWork)), 'ielec:badOption'), ...
    'fitArray: a GridFit setting that does not exist', '');

% and with nothing selected it still refuses for that reason first
nFail = nFail + check(strcmp(errorId(@() ielec.fitArray(fitCfg, ...
    project, work)), 'ielec:noSelection'), ...
    'fitArray: with nothing selected, that comes first', ...
    'as it did before any of these options existed');

%% --------------------------------------------------------- layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - a call can set what decides its result, and it is recorded.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
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
    fprintf('  ok        %-54s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-54s %s\n', what, detail);  bad = 1;
end
end
