function ok = test_depthTrajectory()
%TEST_DEPTHTRAJECTORY  Check the planning geometry taken out of the GUI.
%
%   ok = test_depthTrajectory() compares DEPTHTRAJECTORY and
%   TRAJECTORYENDPOINT with the code that used to sit inside updateTarget
%   and angleChange, both kept verbatim in local functions below. No figure
%   is opened.
%
%   The two functions are inverses of each other, which is the property
%   worth having a test for: the GUI lets the user define a depth electrode
%   either by clicking both ends or by typing a direction, and those two
%   routes have to agree. The round-trip check below is what says they do.
%
%   Most of this runs on made-up electrodes, because the geometry does not
%   care where the numbers came from and a test that needs no project file
%   runs in a fraction of a second. The last section uses a real planning
%   array from examples/exampleNativeSpace.iel when the project has one.
%
%   Usage:  cd into the repository, then
%              test_depthTrajectory
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also DEPTHTRAJECTORY, TRAJECTORYENDPOINT.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end

tol   = 1e-10;
nFail = 0;

% a few electrodes worth trying: an ordinary one, a Behnke-Fried one whose
% first gap differs from the rest, one lying along an axis, and one pointing
% backwards and downwards
cases = {
%    name                targetIn          targetOut         n   fs    sl
    'ordinary depth',   [ 10  -20   30], [ 55   -8   44],   10, 3.5,  3.5
    'Behnke-Fried',     [-12    4  -18], [-48   22   -6],   12, 8.0,  4.0
    'along x',          [  0    0    0], [ 40    0    0],    8, 5.0,  5.0
    'backwards, down',  [ 33   17   -5], [ -9  -21  -40],    6, 2.5,  4.5
};

%% ------------------------------- against the code from updateTarget
fprintf('\n--- against the code from updateTarget -----------------------\n');

for k = 1:size(cases,1)
    [name, xi, xo, n, fs, sl] = cases{k,:};

    [expDelta, expAz, expEl, expDist, expCrd] = originalUpdateTargetBlock(xi, xo, n, fs, sl);
    act = depthTrajectory(xi, xo, n, fs, sl);

    same = isequaln(expDelta, act.delta) && isequaln(expAz, act.azimuth) && ...
           isequaln(expEl, act.elevation) && isequaln(expDist, act.distances) && ...
           isequaln(expCrd, act.coordinates);
    nFail = nFail + check(same, name, sprintf('az %.2f  el %.2f', act.azimuth, act.elevation));
end

%% ------------------------------- against the code from angleChange
fprintf('\n--- against the code from angleChange ------------------------\n');

for k = 1:size(cases,1)
    [name, xi, ~, n, fs, sl] = cases{k,:};
    az = 37.5;  el = -12.25;   % a direction the user might have typed

    expOut = originalAngleChangeBlock(xi, az, el, n, fs, sl);
    actOut = trajectoryEndPoint(xi, az, el, n, fs, sl);

    nFail = nFail + check(isequaln(expOut, actOut), name, ...
        sprintf('[%.2f %.2f %.2f]', actOut(1), actOut(2), actOut(3)));
end

%% ------------------------------------------- the two are inverses
fprintf('\n--- clicking both ends and typing a direction agree ----------\n');

for k = 1:size(cases,1)
    [name, xi, xo, n, fs, sl] = cases{k,:};

    % the GUI's own length, so that the far end is comparable
    len   = fs + (n-2)*sl;
    xoLen = xi + len * ((xo-xi)/norm(xo-xi));   % same direction, GUI's length

    traj = depthTrajectory(xi, xoLen, n, fs, sl);
    back = trajectoryEndPoint(xi, traj.azimuth, traj.elevation, n, fs, sl);

    nFail = nFail + check(norm(back - xoLen) < 1e-9, name, ...
        sprintf('returns to within %.1e mm', norm(back - xoLen)));
end

%% ------------------------------------------------- what the result means
fprintf('\n--- the geometry itself --------------------------------------\n');

[~, xi, xo, n, fs, sl] = cases{2,:};    % the Behnke-Fried one
traj = depthTrajectory(xi, xo, n, fs, sl);

nFail = nFail + check(abs(norm(traj.delta) - 1) < tol, ...
    'delta is a unit vector', sprintf('%.15f', norm(traj.delta)));
nFail = nFail + check(isequal(size(traj.coordinates), [n 3]), ...
    'one coordinate per contact', sprintf('%dx%d', size(traj.coordinates,1), size(traj.coordinates,2)));
nFail = nFail + check(norm(traj.coordinates(1,:) - xi) < tol, ...
    'the first contact sits on the target', '');

% the first gap is the Behnke-Fried one, every later gap is the other
gaps = sqrt(sum(diff(traj.coordinates,1,1).^2, 2));
nFail = nFail + check(abs(gaps(1) - fs) < tol, ...
    'the 1st-2nd gap is the first-second distance', sprintf('%.3f mm', gaps(1)));
nFail = nFail + check(max(abs(gaps(2:end) - sl)) < tol, ...
    'every later gap is the second-last distance', sprintf('%.3f mm', gaps(2)));

% the contacts lie on one straight line
offLine = 0;
for i = 1:n
    along   = dot(traj.coordinates(i,:) - xi, traj.delta);
    offLine = max(offLine, norm(traj.coordinates(i,:) - (xi + along*traj.delta)));
end
nFail = nFail + check(offLine < 1e-9, 'the contacts are collinear', ...
    sprintf('furthest off the line %.1e mm', offLine));

% the distance from first to last is the length the other function uses
lastGap = norm(traj.coordinates(end,:) - traj.coordinates(1,:));
nFail = nFail + check(abs(lastGap - (fs + (n-2)*sl)) < 1e-9, ...
    'first to last is the electrode length', sprintf('%.3f mm', lastGap));

%% --------------------------------------- against a real planning array
fprintf('\n--- against a planning array in the example project ----------\n');

ielFile = fullfile(repoRoot,'examples','exampleNativeSpace.iel');
loaded  = load(ielFile,'-mat');
prj     = checkProjectStructure(loaded.s);

source = [];
for j = 1:numel(prj.targets)
    t = prj.targets{j};
    if ~strcmp(t.Type,'depth'),                        continue, end
    if ~isfield(t,'targetIn') || ~isfield(t,'azimut'), continue, end
    if isempty(t.x) || numel(t.x) ~= t.nElectrodes,    continue, end
    source = t;
    break
end

if isempty(source)
    fprintf('  note      this project holds no depth planning array, so there is\n');
    fprintf('            nothing here to recompute - the checks above stand alone\n');
else
    xi = [source.targetIn.x  source.targetIn.y  source.targetIn.z];
    xo = [source.targetOut.x source.targetOut.y source.targetOut.z];
    traj = depthTrajectory(xi, xo, source.nElectrodes, source.FirstSecond, source.SecondLast);

    nFail = nFail + check(abs(traj.azimuth   - source.azimut)    < 1e-6, ...
        'the stored azimuth is recovered',   sprintf('%.4f', traj.azimuth));
    nFail = nFail + check(abs(traj.elevation - source.elevation) < 1e-6, ...
        'the stored elevation is recovered', sprintf('%.4f', traj.elevation));

    stored = [source.x(:) source.y(:) source.z(:)];
    gap    = max(abs(traj.coordinates(:) - stored(:)));
    nFail  = nFail + check(gap < 1e-6, 'the stored contact positions are recovered', ...
        sprintf('largest gap %.1e mm', gap));
end

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the planning geometry behaves as it did inside the GUI.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% From updateTarget, with the struct reads replaced by the arguments.

function [delta, az, el, distances, coordinates] = originalUpdateTargetBlock(xi, xo, n, fs_dist, sl_dist)

dx=xo(1) - xi(1);
dy=xo(2) - xi(2);
dz=xo(3) - xi(3);

% compute az, el, coordinates, distances
delta=[dx dy dz] / norm([dx dy dz]);
[az,el,~] =cart2sph(delta(1), delta(2), delta(3));
%convert from radians to degres
az=az*180/pi;
el=el*180/pi;

distances= [0 fs_dist fs_dist + ((1:(n-2))*sl_dist)];
for i=1:n
    coordinates(i,:)= xi+ distances(i) * delta;
end
end

% From angleChange, likewise.

function xo = originalAngleChangeBlock(xi, az, el, n, fs_dist, sl_dist)

%convert degres to radians
az=az*pi/180;
el=el*pi/180;

[dx, dy, dz] =sph2cart(az,el,1); %radius=1
delta=[dx dy dz];

dist=fs_dist+(n-2)*sl_dist; %length from first to last

xo=xi+dist*delta;
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-46s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-46s %s\n', what, detail);  bad = 1;
end
end
