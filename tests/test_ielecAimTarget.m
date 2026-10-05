function ok = test_ielecAimTarget()
%TEST_IELECAIMTARGET  Check ielec.aimTarget.
%
%   ok = test_ielecAimTarget() aims a planned depth electrode every way the
%   planning panel can aim one, and compares each result with the lines
%   UPDATETARGET, ANGLECHANGE and ALPHABETACHANGE ran, kept verbatim at the
%   end of this file and chained in the order the callbacks chained them.
%
%   The four routes are the four ways the panel points an electrode: the two
%   ends typed or clicked, a direction as azimuth and elevation, the
%   stereotactic frame's two angles, and no direction at all - which is what
%   a change to the contact count or a spacing needs.
%
%   Two things this test exists to prove:
%
%   - ALPHABETACHANGE wrote the typed angles into .alpha twice, so .beta
%     never received one (docs/OPEN_QUESTIONS.md item 24). The verbatim block
%     below keeps that double write. The layer does not write either value,
%     and the results still have to match - which is what "the bug was never
%     observable" means, and the reason it is not reproduced.
%
%   - On the frame-angle route the far end is built from the .frameDown the
%     target carries BEFORE the new trajectory replaces it. The fixture for
%     that check crosses z = 0, so getting the order wrong turns beta by 180
%     degrees and the comparison fails.
%
%   Usage:  cd into the repository, then
%              test_ielecAimTarget
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.AIMTARGET, DEPTHTRAJECTORY, TRAJECTORYENDPOINT,
%            FRAMETRAJECTORYENDPOINT, IELEC.SETFRAME.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

work = struct();
project = [];
project.targets = {depthTarget([0 0 0], [45 45 45])};

%% ------------------------------------------- no direction: the stored ends
fprintf('\n--- ielec.aimTarget against updateTarget ----------------------\n');

expected = chain(project.targets{1});
[got, gotWork] = ielec.aimTarget(struct('index', 1), project, work);

nFail = nFail + check(isequaln(got.targets{1}, expected), ...
    'the stored ends, as updateTarget recomputed them', ...
    sprintf('azimuth %.4g', expected.azimut));
nFail = nFail + check(isequal(fieldnames(got.targets{1}), fieldnames(expected)), ...
    'and the fields in the order it left them', '');
nFail = nFail + check(isequaln(gotWork, work), 'work is not changed', '');

%% ------------------------------------------------ the far end, given
fprintf('\n--- a far end, as the boxes and the click give it -------------\n');

xo = [30 -12 8];
base = project.targets{1};
base.targetOut.x = xo(1); base.targetOut.y = xo(2); base.targetOut.z = xo(3);
expected = chain(base);
got = ielec.aimTarget(struct('index', 1, 'targetOut', xo), project, work);
nFail = nFail + check(isequaln(got.targets{1}, expected) && ...
        isequal(fieldnames(got.targets{1}), fieldnames(expected)), ...
    'cfg.targetOut, as the Target Out boxes set it', mat2str(xo));

xi = [-4 2 -6];
base = project.targets{1};
base.targetIn.x = xi(1); base.targetIn.y = xi(2); base.targetIn.z = xi(3);
expected = chain(base);
got = ielec.aimTarget(struct('index', 1, 'targetIn', xi), project, work);
nFail = nFail + check(isequaln(got.targets{1}, expected) && ...
        isequal(fieldnames(got.targets{1}), fieldnames(expected)), ...
    'and cfg.targetIn, as the Target In boxes set it', mat2str(xi));

%% ----------------------------------------------- azimuth and elevation
fprintf('\n--- a direction, as angleChange computed it ------------------\n');

az = 23; el = -11;
expected = chain(originalAngleChange(project.targets{1}, az, el));
got = ielec.aimTarget(struct('index', 1, 'azimuth', az, 'elevation', el), ...
                       project, work);
nFail = nFail + check(isequaln(got.targets{1}, expected), ...
    'cfg.azimuth with cfg.elevation', sprintf('az %g, el %g', az, el));
nFail = nFail + check(isequal(fieldnames(got.targets{1}), fieldnames(expected)), ...
    'and the fields in the order it left them', '');

%% --------------------------------------------------- the frame angles
fprintf('\n--- the frame angles, as AlphaBetaChange computed them -------\n');

alpha = 40; beta = 200;
expected = chain(originalAlphaBetaChange(project.targets{1}, alpha, beta));
got = ielec.aimTarget(struct('index', 1, 'alpha', alpha, 'beta', beta), ...
                       project, work);
nFail = nFail + check(isequaln(got.targets{1}, expected), ...
    'cfg.alpha with cfg.beta, double .alpha write and all', ...
    sprintf('alpha %g, beta %g', alpha, beta));
nFail = nFail + check(isequal(fieldnames(got.targets{1}), fieldnames(expected)), ...
    'and the fields in the order it left them', 'item 24 leaves no trace');

% the ordering dependency: a target whose aim crosses z = 0, so that the
% stored frameDown and the new one disagree
crossing = [];
crossing.targets = {depthTarget([0 0 20], [20 20 -30])};
expected = chain(originalAlphaBetaChange(crossing.targets{1}, alpha, beta));
got = ielec.aimTarget(struct('index', 1, 'alpha', alpha, 'beta', beta), ...
                       crossing, work);

% the check above is only worth making if the two frameDowns really differ:
% if they agreed, the order could be wrong and nothing would show
wasDown = crossing.targets{1}.frameDown;
isDown  = got.targets{1}.frameDown;
nFail = nFail + check(wasDown ~= isDown, ...
    'the fixture does cross z = 0, so the order is exercised', ...
    sprintf('frameDown %d -> %d', wasDown, isDown));
nFail = nFail + check(isequaln(got.targets{1}, expected), ...
    'the far end uses the frameDown it had, not the new one', ...
    sprintf('beta %.4g', got.targets{1}.beta));

%% ------------------------------------------------- what it is, not where
fprintf('\n--- the count and the two spacings ---------------------------\n');

for change = {{'nContacts', 'nElectrodes', 6}, ...
              {'firstSecond', 'FirstSecond', 3}, ...
              {'secondLast', 'SecondLast', 7}}
    c = change{1};
    base = project.targets{1};
    base.(c{2}) = c{3};
    expected = chain(base);
    got = ielec.aimTarget(struct('index', 1, c{1}, c{3}), project, work);
    nFail = nFail + check(isequaln(got.targets{1}, expected) && ...
            isequal(fieldnames(got.targets{1}), fieldnames(expected)), ...
        sprintf('cfg.%s', c{1}), sprintf('%s = %g', c{2}, c{3}));
end

%% ------------------------------------------- the four routes differ
fprintf('\n--- and the four routes are four routes ----------------------\n');

ends = cell(1, 4);
ends{1} = aimedEnd(ielec.aimTarget(struct('index', 1), project, work));
ends{2} = aimedEnd(ielec.aimTarget(struct('index', 1, 'targetOut', xo), project, work));
ends{3} = aimedEnd(ielec.aimTarget(struct('index', 1, 'azimuth', az, ...
                                           'elevation', el), project, work));
ends{4} = aimedEnd(ielec.aimTarget(struct('index', 1, 'alpha', alpha, ...
                                           'beta', beta), project, work));
nFail = nFail + check(size(unique(round(cell2mat(ends'), 6), 'rows'), 1) == 4, ...
    'the four give four different far ends', ...
    sprintf('%d distinct', size(unique(round(cell2mat(ends'), 6), 'rows'), 1)));

%% ------------------------------------------------- a degenerate aim
fprintf('\n--- a degenerate aim is not refused --------------------------\n');

% The route that can really arrive with a NaN is the frame one.
% ALPHABETACHANGE has no isnan guard, so str2double('abc') goes straight into
% the cfg; ANGLECHANGE returns early on a NaN, so its own route never gets
% here and a NaN check on it would be a check against nothing.
expected = chain(originalAlphaBetaChange(project.targets{1}, NaN, NaN));
got = ielec.aimTarget(struct('index', 1, 'alpha', NaN, 'beta', NaN), ...
                       project, work);
nFail = nFail + check(isequaln(got.targets{1}, expected), ...
    'a NaN frame angle gives the NaN trajectory it always gave', ...
    'AlphaBetaChange has no isnan guard');

same = project;
same.targets{1}.targetOut = same.targets{1}.targetIn;
expected = chain(same.targets{1});
got = ielec.aimTarget(struct('index', 1, 'targetOut', [0 0 0]), project, work);
nFail = nFail + check(isequaln(got.targets{1}, expected) && ...
        all(isnan(got.targets{1}.delta)), ...
    'two ends in the same place give a NaN delta, not an error', ...
    'depthTrajectory has always done this');

%% ------------------------------------------------------ what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

refusals = {
  struct('index', 1, 'targetOut', xo, 'azimuth', az, 'elevation', el), ...
      'two ways of pointing it at once', 'targetOut and azimuth'
  struct('index', 1, 'azimuth', az), ...
      'azimuth without elevation', 'half a pair'
  struct('index', 1, 'alpha', alpha), ...
      'alpha without beta', 'half a pair'
  struct('index', 1, 'targetOut', [1 2]), ...
      'a far end that is not three numbers', 'cfg.targetOut'
  struct('index', 1, 'nContacts', [4 5]), ...
      'a contact count that is not one number', 'cfg.nContacts'
  struct('index', 2), ...
      'a target that is not in the project', 'cfg.index'
};
for k = 1:size(refusals, 1)
    nFail = nFail + check(strcmp(errorId(@() ielec.aimTarget(refusals{k,1}, ...
            project, work)), 'ielec:badOption'), ...
        refusals{k,2}, refusals{k,3});
end
aGrid = project;
aGrid.targets{1} = struct('Type', 'grid', 'Name', 'grid', 'planning', 'yes');
nFail = nFail + check(strcmp(errorId(@() ielec.aimTarget(struct('index', 1), ...
        aGrid, work)), 'ielec:badOption'), ...
    'a planned grid, which has no ends to aim', 'no .targetIn');
nFail = nFail + check(strcmp(errorId(@() ielec.aimTarget([], project, work)), ...
        'ielec:missingOption'), ...
    'no index at all', 'cfg.index');
nFail = nFail + check(strcmp(errorId(@() ielec.aimTarget(...
        struct('index', 1, 'target_out', xo), project, work)), ...
        'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.target_out');

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.aimTarget) == 3 && ...
        nargout(@ielec.aimTarget) == 2, ...
    'aimTarget''s signature', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the electrode is aimed as the panel aimed it.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% The three callbacks' own lines, with the selected array, the display and
% the anatomical labelling taken out. CHAIN puts them in the order the
% callbacks did: the route's own lines, then UPDATETARGET's trajectory, then
% ESTIMATEANGLESFRAME.

function target = chain(target)
    target = originalUpdateTarget(target);
    target = originalEstimateAnglesFrame(target);
end

function target = originalUpdateTarget(target)
    handles.project.targets = {target};
    l = 1;
    target = handles.project.targets{l};

    xi = [target.targetIn.x  target.targetIn.y  target.targetIn.z];
    xo = [target.targetOut.x target.targetOut.y target.targetOut.z];

    trajectory = depthTrajectory(xi, xo, target.nElectrodes, ...
                                 target.FirstSecond, target.SecondLast);

    handles.project.targets{l}.delta     = trajectory.delta;
    handles.project.targets{l}.azimut    = trajectory.azimuth;
    handles.project.targets{l}.elevation = trajectory.elevation;
    handles.project.targets{l}.distances = trajectory.distances;
    handles.project.targets{l}.x = trajectory.coordinates(:,1);
    handles.project.targets{l}.y = trajectory.coordinates(:,2);
    handles.project.targets{l}.z = trajectory.coordinates(:,3);

    target = handles.project.targets{l};
end

function target = originalEstimateAnglesFrame(target)
    handles.project.targets = {target};
    l = 1;

    delta=handles.project.targets{l}.delta;

    target = handles.project.targets{l};
    [alpha, beta, frameDown] = trajectoryFrameAngles(delta, target.z(target.nElectrodes), ...
                                                     target.framePosition);
    handles.project.targets{l}.frameDown = frameDown;

    handles.project.targets{l}.beta=beta;
    handles.project.targets{l}.alpha=alpha;

    target = handles.project.targets{l};
end

function target = originalAngleChange(target, az, el)
    handles.project.targets = {target};
    l = 1;
    target = handles.project.targets{l};

    xi = [target.targetIn.x target.targetIn.y target.targetIn.z];
    xo = trajectoryEndPoint(xi, az, el, target.nElectrodes, ...
                            target.FirstSecond, target.SecondLast);

    handles.project.targets{l}.targetOut.x=xo(1);
    handles.project.targets{l}.targetOut.y=xo(2);
    handles.project.targets{l}.targetOut.z=xo(3);

    target = handles.project.targets{l};
end

function target = originalAlphaBetaChange(target, alpha, beta)
    handles.project.targets = {target};
    l = 1;

    n=handles.project.targets{l}.nElectrodes;
    fs_dist=handles.project.targets{l}.FirstSecond;
    sl_dist=handles.project.targets{l}.SecondLast;

    %punto Target IN
    xi(1)= handles.project.targets{l}.targetIn.x;
    xi(2)= handles.project.targets{l}.targetIn.y;
    xi(3)= handles.project.targets{l}.targetIn.z;

    handles.project.targets{l}.alpha=alpha;
    handles.project.targets{l}.alpha=beta;   % sic: should be .beta - item 24

    % estimate xo, from the frame angles (src/geometry/)
    xo = frameTrajectoryEndPoint(xi, alpha, beta, ...
            handles.project.targets{l}.framePosition, handles.project.targets{l}.frameDown, ...
            n, fs_dist, sl_dist);

    handles.project.targets{l}.targetOut.x=xo(1);
    handles.project.targets{l}.targetOut.y=xo(2);
    handles.project.targets{l}.targetOut.z=xo(3);

    target = handles.project.targets{l};
end

% ---------------------------------------------------------------------
function target = depthTarget(targetIn, targetOut)
% A depth planning array with everything AIMTARGET reads, aimed and framed
% once so that .alpha already exists - which is the state every depth target
% in the panel is in by the time it can be re-aimed, and so the state in
% which no field is being created for the first time. It is not the whole of
% what the New target button builds: .adjMat and .ch_label are left as
% CHECKELECTRODESTRUCTURE leaves them, because nothing here reads either.
target=[];
target.Type='depth';
target.Name='Planning';
target.planning='yes';
target=checkElectrodeStructure(target);

target.targetIn.x=targetIn(1);
target.targetIn.y=targetIn(2);
target.targetIn.z=targetIn(3);
target.targetOut.x=targetOut(1);
target.targetOut.y=targetOut(2);
target.targetOut.z=targetOut(3);

target.nElectrodes=10;
target.FirstSecond=5;
target.SecondLast=5;
target.rows=10;
target.columns=1;
target.framePosition='Anterior';
target.frameDown=0;

target = originalUpdateTarget(target);
target = originalEstimateAnglesFrame(target);
end

function xo = aimedEnd(project)
xo = [project.targets{1}.targetOut.x project.targets{1}.targetOut.y ...
      project.targets{1}.targetOut.z];
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
