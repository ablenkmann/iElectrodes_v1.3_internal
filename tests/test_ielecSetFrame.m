function ok = test_ielecSetFrame()
%TEST_IELECSETFRAME  Check ielec.setFrame.
%
%   ok = test_ielecSetFrame() works out the stereotactic frame angles of a
%   planned depth electrode in all four frame mountings, and compares each
%   with the lines ESTIMATEANGLESFRAME ran in the GUI, kept verbatim at the
%   end of this file.
%
%   The fixture is built here rather than read from the example project: the
%   frame angles are read from a target's own fields and need no image, no
%   surface and no file, so a synthetic depth target keeps this test to
%   under a second. It is built the way the New target button builds one -
%   CHECKELECTRODESTRUCTURE and the same defaults - and then given the
%   trajectory UPDATETARGET would have given it.
%
%   The promise this function makes is that setting the frame cannot move a
%   contact, which is why it is a function of its own, so that is checked
%   explicitly and not only implied by a struct comparison.
%
%   Usage:  cd into the repository, then
%              test_ielecSetFrame
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.SETFRAME, TRAJECTORYFRAMEANGLES, DELTA2ALPHA_BETA.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

project = [];
project.targets = {depthTarget([0 0 0], [45 45 45])};
% setFrame reads no options: the frame angles come from the target's own
% fields, so an empty work is the honest fixture and proves it.
work = struct();

%% ------------------------------- the four mountings, against the GUI's lines
fprintf('\n--- ielec.setFrame against estimateAnglesFrame ----------------\n');

for pos = {'Left', 'Right', 'Anterior', 'Posterior'}
    expected = originalEstimate(project.targets{1}, pos{1});
    [got, gotWork] = ielec.setFrame(struct('index', 1, 'framePosition', pos{1}), ...
                                     project, work);
    nFail = nFail + check(isequaln(got.targets{1}, expected.target), ...
        sprintf('the %s frame, as the GUI computed it', pos{1}), ...
        sprintf('alpha %.4g, beta %.4g', expected.target.alpha, expected.target.beta));
    nFail = nFail + check(isequaln(gotWork, work), ...
        'and work is not changed', '');
end

% the four give four different answers, so the comparison above is not four
% copies of the same number
angles = [];
for pos = {'Left', 'Right', 'Anterior', 'Posterior'}
    got = ielec.setFrame(struct('index', 1, 'framePosition', pos{1}), project, work);
    angles(end+1, :) = [got.targets{1}.alpha got.targets{1}.beta]; %#ok<AGROW>
end
nFail = nFail + check(size(unique(angles, 'rows'), 1) > 1, ...
    'the four mountings do not all give the same angles', ...
    sprintf('%d distinct', size(unique(angles, 'rows'), 1)));

%% ------------------------------------------- the frame position it is given
fprintf('\n--- where the frame position comes from -----------------------\n');

stored = project;
stored.targets{1}.framePosition = 'Posterior';
expected = originalEstimate(stored.targets{1}, 'Posterior');
got = ielec.setFrame(struct('index', 1), stored, work);
nFail = nFail + check(isequaln(got.targets{1}, expected.target), ...
    'no cfg.framePosition uses the target''s own', 'Posterior');

got = ielec.setFrame(struct('index', 1, 'framePosition', 'Left'), stored, work);
nFail = nFail + check(strcmp(got.targets{1}.framePosition, 'Left'), ...
    'and a cfg.framePosition replaces it', 'Posterior -> Left');

%% ------------------------------------------------------- frameDown is decided
fprintf('\n--- frameDown is decided, not taken --------------------------\n');

% TRAJECTORYFRAMEANGLES sets it from the z of the LAST contact, not from the
% target point and not from what the array already carries
down = [];
down.targets = {depthTarget([0 0 0], [45 45 -45])};
down.targets{1}.frameDown = 0;          % whatever it says now
got = ielec.setFrame(struct('index', 1, 'framePosition', 'Anterior'), down, work);
nFail = nFail + check(got.targets{1}.frameDown == 1, ...
    'a last contact below z = 0 turns the frame down', ...
    sprintf('z(last) = %.3g', down.targets{1}.z(down.targets{1}.nElectrodes)));

up = project;
up.targets{1}.frameDown = 1;
got = ielec.setFrame(struct('index', 1, 'framePosition', 'Anterior'), up, work);
nFail = nFail + check(got.targets{1}.frameDown == 0, ...
    'and one above it turns the frame up', '');

%% --------------------------------------- it cannot move a planned contact
fprintf('\n--- and it moves nothing -------------------------------------\n');

before = project.targets{1};
got    = ielec.setFrame(struct('index', 1, 'framePosition', 'Left'), project, work);
after  = got.targets{1};

nFail = nFail + check(isequaln([after.x after.y after.z], ...
        [before.x before.y before.z]), ...
    'the contacts are where they were', sprintf('%d contacts', numel(before.x)));
nFail = nFail + check(isequaln(after.targetIn, before.targetIn) && ...
        isequaln(after.targetOut, before.targetOut) && ...
        isequaln(after.delta, before.delta) && ...
        isequaln(after.azimut, before.azimut) && ...
        isequaln(after.elevation, before.elevation) && ...
        isequaln(after.distances, before.distances), ...
    'and so are both ends and the trajectory', '');
nFail = nFail + check(isequal(sort(fieldnames(after)), ...
        sort(unique([fieldnames(before); {'alpha'}]))), ...
    'the only field it can add is alpha', ...
    'checkElectrodeStructure does not create it - item 37');
% isequaln on structs ignores field order, and field order reaches the .iel
% file, so the order is compared on its own
expectedLeft = originalEstimate(before, 'Left');
nFail = nFail + check(isequal(fieldnames(after), fieldnames(expectedLeft.target)), ...
    'and they are in the order the GUI left them', 'order reaches the .iel file');

%% ------------------------------- the states only a file can put a target in
fprintf('\n--- what a file can hold, reproduced not refused --------------\n');

% An empty nElectrodes. z([]) is [], so the last contact's z is empty, the
% frame is up, and the angles still come out as ordinary numbers. The GUI did
% this; nothing in the toolbox produces it, but an old .iel file can hold it,
% and the layer reproduces it rather than refusing the call.
odd = project;
odd.targets{1}.nElectrodes = [];
expected = originalEstimate(odd.targets{1}, 'Anterior');
got = ielec.setFrame(struct('index', 1, 'framePosition', 'Anterior'), odd, work);
nFail = nFail + check(isequaln(got.targets{1}, expected.target), ...
    'an empty nElectrodes gives the angles it always gave', ...
    sprintf('alpha %.4g', expected.target.alpha));

% A Type that is not 'depth', on a target that carries a trajectory. The
% angles are computed, because that is what ESTIMATEANGLESFRAME did: it read
% .delta and never looked at .Type.
odd = project;
odd.targets{1}.Type = 'strip';
expected = originalEstimate(odd.targets{1}, 'Left');
got = ielec.setFrame(struct('index', 1, 'framePosition', 'Left'), odd, work);
nFail = nFail + check(isequaln(got.targets{1}, expected.target), ...
    'a Type that is not depth is not refused', 'Type ''strip''');

%% ------------------------------------------------------ what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

nFail = nFail + check(strcmp(errorId(@() ielec.setFrame(struct('index', 2), ...
        project, work)), 'ielec:badOption'), ...
    'a target that is not in the project', 'cfg.index');
nFail = nFail + check(strcmp(errorId(@() ielec.setFrame([], project, work)), ...
        'ielec:missingOption'), ...
    'no index at all', 'cfg.index');
nFail = nFail + check(strcmp(errorId(@() ielec.setFrame(...
        struct('index', 1, 'frame', 'Left'), project, work)), ...
        'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.frame');
nFail = nFail + check(strcmp(errorId(@() ielec.setFrame(...
        struct('index', 1, 'framePosition', 'Superior'), project, work)), ...
        'ielec:badOption'), ...
    'a mounting that is not one of the four', 'Superior');

noPosition = project;
noPosition.targets{1}.framePosition = '';
nFail = nFail + check(strcmp(errorId(@() ielec.setFrame(struct('index', 1), ...
        noPosition, work)), 'ielec:badOption'), ...
    'a target with no mounting and no cfg', '');

aGrid = project;
aGrid.targets{1} = struct('Type', 'grid', 'Name', 'grid', 'planning', 'yes');
nFail = nFail + check(strcmp(errorId(@() ielec.setFrame(...
        struct('index', 1, 'framePosition', 'Left'), aGrid, work)), ...
        'ielec:badOption'), ...
    'a planned grid, which has no trajectory', 'no delta');

noTrajectory = project;
noTrajectory.targets{1}.delta = [];
nFail = nFail + check(strcmp(errorId(@() ielec.setFrame(...
        struct('index', 1, 'framePosition', 'Left'), noTrajectory, work)), ...
        'ielec:badOption'), ...
    'a depth target that has not been aimed yet', 'empty delta');

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.setFrame) == 3 && ...
        nargout(@ielec.setFrame) == 2, ...
    'setFrame''s signature', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the frame angles are the ones the GUI computed.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% What ESTIMATEANGLESFRAME ran, with the selected array and the display taken
% out. The three writes are in the order it made them.

function out = originalEstimate(target, framePosition)
% The frame position goes onto the target first, OUTSIDE the block: that is
% what the radio-group callback did before it called ESTIMATEANGLESFRAME,
% which never wrote one itself. Everything from DELTA= down is that
% function's own code, verbatim.
    target.framePosition = framePosition;

    handles.project.targets = {target};
    l = 1;

    delta=handles.project.targets{l}.delta;

    target = handles.project.targets{l};
    [alpha, beta, frameDown] = trajectoryFrameAngles(delta, target.z(target.nElectrodes), ...
                                                     target.framePosition);
    handles.project.targets{l}.frameDown = frameDown;

    handles.project.targets{l}.beta=beta;
    handles.project.targets{l}.alpha=alpha;

    out.target = handles.project.targets{l};
end

% ---------------------------------------------------------------------
function target = depthTarget(targetIn, targetOut)
% a depth planning array as the New target button makes one, then aimed the
% way UPDATETARGET aims it
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

trajectory = depthTrajectory(targetIn, targetOut, target.nElectrodes, ...
                             target.FirstSecond, target.SecondLast);
target.delta     = trajectory.delta;
target.azimut    = trajectory.azimuth;
target.elevation = trajectory.elevation;
target.distances = trajectory.distances;
target.x = trajectory.coordinates(:,1);
target.y = trajectory.coordinates(:,2);
target.z = trajectory.coordinates(:,3);
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
