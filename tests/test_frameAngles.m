function ok = test_frameAngles()
%TEST_FRAMEANGLES  Check the stereotactic-frame geometry taken out of the GUI.
%
%   ok = test_frameAngles() compares FRAMETRAJECTORYENDPOINT and
%   TRAJECTORYFRAMEANGLES with the code that used to sit in AlphaBetaChange
%   and estimateAnglesFrame, kept verbatim below, for all four ways of
%   mounting the frame and both frame directions. No figure is opened, and
%   no project file is needed.
%
%   It then checks the property that matters to a user: setting the frame
%   angles and reading them back gives the same angles - the two functions
%   are inverses. And it checks the rule that decides whether the frame
%   points down.
%
%   Usage:  cd into the repository, then
%              test_frameAngles
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also FRAMETRAJECTORYENDPOINT, TRAJECTORYFRAMEANGLES.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end

positions = {'Left','Right','Anterior','Posterior'};
xi = [12 -30 25];  n = 10;  fs = 3.5;  sl = 3.5;
alpha = 30;  beta = 120;
nFail = 0;

%% ------------------------------------ against the code from AlphaBetaChange
fprintf('\n--- the end point, against the code from AlphaBetaChange -----\n');
for p = 1:numel(positions)
    for down = [false true]
        expected = originalEndPoint(xi, alpha, beta, positions{p}, down, n, fs, sl);
        actual   = frameTrajectoryEndPoint(xi, alpha, beta, positions{p}, down, n, fs, sl);
        nFail = nFail + check(isequaln(expected, actual), ...
            sprintf('%-9s frame, pointing %s', positions{p}, upDown(down)), '');
    end
end

%% ---------------------------------- against the code from estimateAnglesFrame
fprintf('\n--- the angles, against the code from estimateAnglesFrame ----\n');
delta = [0.3 0.8 -0.52];  delta = delta / norm(delta);
for p = 1:numel(positions)
    for zLast = [15 -15]
        [ea, eb, ed] = originalAngles(delta, zLast, positions{p});
        [aa, ab, ad] = trajectoryFrameAngles(delta, zLast, positions{p});
        nFail = nFail + check(isequaln([ea eb ed], [aa ab ad]), ...
            sprintf('%-9s frame, last contact at z = %+d', positions{p}, zLast), ...
            sprintf('alpha %.2f  beta %.2f', aa, ab));
    end
end

%% ------------------------------------------------------ the two are inverses
fprintf('\n--- setting the angles and reading them back -----------------\n');
for p = 1:numel(positions)
    for down = [false true]
        xo    = frameTrajectoryEndPoint(xi, alpha, beta, positions{p}, down, n, fs, sl);
        d     = (xo - xi) / norm(xo - xi);
        zLast = -1 + 2*(~down);          % a last contact on the side that gives this frameDown
        [a2, b2, down2] = trajectoryFrameAngles(d, zLast, positions{p});
        same = abs(a2 - alpha) < 1e-9 && abs(b2 - beta) < 1e-9 && down2 == down;
        nFail = nFail + check(same, sprintf('%-9s frame, pointing %s', positions{p}, upDown(down)), ...
            sprintf('back to %.4f, %.4f', a2, b2));
    end
end

%% ------------------------------------------------------- the geometry itself
fprintf('\n--- the geometry itself --------------------------------------\n');
xo = frameTrajectoryEndPoint(xi, alpha, beta, 'Anterior', false, n, fs, sl);
nFail = nFail + check(abs(norm(xo - xi) - (fs + (n-2)*sl)) < 1e-9, ...
    'the end point is one electrode length away', sprintf('%.3f mm', norm(xo - xi)));

[~, ~, d1] = trajectoryFrameAngles(delta, -0.001, 'Anterior');
[~, ~, d2] = trajectoryFrameAngles(delta,  0,     'Anterior');
nFail = nFail + check(d1 == true && d2 == false, ...
    'the frame points down only below z = 0', 'z = 0 counts as up');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the frame angles behave as they did inside the GUI.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% From AlphaBetaChange, with the struct reads replaced by arguments.

function xo = originalEndPoint(xi, alpha, beta, framePosition, frameDown, n, fs_dist, sl_dist)
[dx,dy,dz]=alpha_beta2delta(alpha,beta,framePosition,frameDown);

delta=[dx dy dz];

dist=fs_dist+(n-2)*sl_dist; %length from first to last

% estimate xo
xo=xi+dist*delta;
end

% From estimateAnglesFrame, likewise.

function [alpha, beta, frameDown] = originalAngles(delta, zLast, framePosition)
frameDown = zLast < 0;
[alpha,beta]=delta2alpha_beta(delta(1),delta(2),delta(3),framePosition,frameDown);
end

% ---------------------------------------------------------------------
function s = upDown(down)
if down, s = 'down'; else, s = 'up'; end
end

function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-50s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-50s %s\n', what, detail);  bad = 1;
end
end
