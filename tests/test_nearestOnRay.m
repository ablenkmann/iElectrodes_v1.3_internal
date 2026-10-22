function ok = test_nearestOnRay()
%TEST_NEARESTONRAY  Check which vertex a click on a 3-D surface picks.
%
%   ok = test_nearestOnRay() checks IELVIEW.NEARESTONRAY on rays whose answer
%   is known. No figure is opened.
%
%   WHY THIS IS WORTH A TEST
%
%   This is what turns a click on the brain into a slice: the point it
%   returns becomes the cursor, and the three 2-D views are drawn there. A
%   mouse click cannot be made to happen in a test, so the geometry is out
%   here on its own, where rays can be aimed at vertices whose position is
%   known in advance.
%
%   The way it can be wrong and stay quiet is to take the vertex furthest
%   along the line instead of the nearest: a click on a forehead then lands
%   on the back of the head, and the slice that comes up looks perfectly
%   plausible. The check for it is to fire the same line from both ends and
%   require different answers.
%
%   Usage:  cd into the repository, then
%              test_nearestOnRay
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELVIEW.NEARESTONRAY, IELVIEW.VOXELFROMPLANECLICK.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end

nFail = 0;

% four vertices on the x axis, and one 5 mm off it
V = [ 0  0  0
     10  0  0
     20  0  0
     20  5  0];

fprintf('\n--- which one the ray meets first ----------------------------\n');

nFail = nFail + check(isequal( ...
    ielview.nearestOnRay(V, [-100 0 0], [1 0 0], 3), 1), ...
    'coming from -x, the first vertex', '');

nFail = nFail + check(isequal( ...
    ielview.nearestOnRay(V, [100 0 0], [-1 0 0], 3), 3), ...
    'the same line from the other end gives the other end', '');

nFail = nFail + check(isempty( ...
    ielview.nearestOnRay(V, [0 100 0], [0 1 0], 3)), ...
    'everything behind the eye is left out', '');

nFail = nFail + check(isempty( ...
    ielview.nearestOnRay(V, [0 -100 50], [0 1 0], 3)), ...
    'a ray that misses picks nothing', '');

fprintf('\n--- the tolerance --------------------------------------------\n');

% the one vertex 5 mm off the line is the only thing that pins a distance
nFail = nFail + check(isempty( ...
    ielview.nearestOnRay(V(4,:), [-100 0 0], [1 0 0], 3)), ...
    '5 mm off the ray is outside a 3 mm tolerance', '');

nFail = nFail + check(isequal( ...
    ielview.nearestOnRay(V(4,:), [-100 0 0], [1 0 0], 6), 1), ...
    'and inside a 6 mm one', '');

% the default is documented as 3, so it must behave like 3 - checked on the
% vertex that can tell them apart, not on one sitting exactly on the line
nFail = nFail + check(isempty( ...
    ielview.nearestOnRay(V(4,:), [-100 0 0], [1 0 0])), ...
    'the default tolerance is the documented 3, not larger', '');
nFail = nFail + check(isequal( ...
    ielview.nearestOnRay([2.5 0 0], [-100 0 0], [1 0 0]), 1), ...
    'and not smaller', '');

fprintf('\n--- nothing to pick, rather than an error --------------------\n');

nFail = nFail + check(isempty(ielview.nearestOnRay([], [0 0 0], [1 0 0], 3)), ...
    'no vertices at all', '');
nFail = nFail + check(isempty(ielview.nearestOnRay(zeros(0,3), [0 0 0], [1 0 0], 3)), ...
    'an empty N by 3', '');
nFail = nFail + check(isempty(ielview.nearestOnRay(V, [NaN 0 0], [1 0 0], 3)), ...
    'a line from an axes that has not drawn yet', '');

fprintf('\n--- things that must hold whatever is asked for --------------\n');

nFail = nFail + check(isequal( ...
    ielview.nearestOnRay(V, [-100 0 0], [5 0 0], 3), 1), ...
    'the direction need not be a unit vector', '');

k = ielview.nearestOnRay(V, [-100 0 0], [1 0 0], 3);
nFail = nFail + check(isscalar(k) && k == round(k) && ...
    k >= 1 && k <= size(V,1), ...
    'the answer is one usable row index', '');

nFail = nFail + check(isequal( ...
    ielview.nearestOnRay(V, [20 -100 0], [0 1 0], 1), 3), ...
    'a tight tolerance still finds the one on the line', '');

nFail = nFail + check(isequal( ...
    ielview.nearestOnRay(int16(V), [-100 0 0], [1 0 0], 3), 1), ...
    'integer vertices work', '');

fprintf('\n--- what it refuses ------------------------------------------\n');

nFail = nFail + check(threw(@() ielview.nearestOnRay([1 2], [0 0 0], [1 0 0], 3), ...
    'ielview:badVertices'), 'vertices that are not N by 3', '');
nFail = nFail + check(threw(@() ielview.nearestOnRay(V, [0 0], [1 0 0], 3), ...
    'ielview:badRay'), 'an origin that is not a point', '');
nFail = nFail + check(threw(@() ielview.nearestOnRay(V, [0 0 0], [0 0 0], 3), ...
    'ielview:badRay'), 'a direction with no length', '');
nFail = nFail + check(threw(@() ielview.nearestOnRay(V, [0 0 0], [1 0 0], -3), ...
    'ielview:badTolerance'), 'a negative tolerance', '');
nFail = nFail + check(threw(@() ielview.nearestOnRay(V, [0 0 0], [1 0 0], [3 3]), ...
    'ielview:badTolerance'), 'two tolerances', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - a click picks the surface in front of it.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function yes = threw(fcn, identifier)
yes = false;
try
    fcn();
catch err
    yes = strcmp(err.identifier, identifier);
end
end

function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-52s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-52s %s\n', what, detail);  bad = 1;
end
end
