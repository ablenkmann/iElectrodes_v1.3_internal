function ok = test_voxelFromPlaneClick()
%TEST_VOXELFROMPLANECLICK  Check the click-to-voxel mapping for the 2-D views.
%
%   ok = test_voxelFromPlaneClick() checks VOXELFROMPLANECLICK against the
%   three cases written out by hand, which is how the mapping was written in
%   the code it replaced. No figure is opened.
%
%   The mapping is three lines long and entirely uninteresting until it is
%   wrong, at which point a planning electrode is placed in the wrong part of
%   the brain and the picture still looks reasonable. It was written out
%   separately in each of the places that needed it, which is the arrangement
%   that lets one copy drift.
%
%   Usage:  cd into the repository, then
%              test_voxelFromPlaneClick
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also VOXELFROMPLANECLICK.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end

nFail = 0;
sliderValue = 87;
d1 = 120;
d2 = 64;

fprintf('\n--- the three views ------------------------------------------\n');

% X view: the click gives y and z, x comes from the slider
nFail = nFail + check(isequal(voxelFromPlaneClick(1, sliderValue, [d1 d2]), ...
    [sliderValue d1 d2]), 'X view -> [slider d1 d2]', '');

% Y view: the click gives x and z
nFail = nFail + check(isequal(voxelFromPlaneClick(2, sliderValue, [d1 d2]), ...
    [d1 sliderValue d2]), 'Y view -> [d1 slider d2]', '');

% Z view: the click gives x and y
nFail = nFail + check(isequal(voxelFromPlaneClick(3, sliderValue, [d1 d2]), ...
    [d1 d2 sliderValue]), 'Z view -> [d1 d2 slider]', '');

fprintf('\n--- properties that must hold for every view -----------------\n');
bad = 0;
for plane = 1:3
    v = voxelFromPlaneClick(plane, sliderValue, [d1 d2]);
    if v(plane) ~= sliderValue, bad = bad + 1; end
    if ~isequal(sort(v), sort([sliderValue d1 d2])), bad = bad + 1; end
end
nFail = nFail + check(bad == 0, ...
    'the through-plane axis takes the slider, the others the click', '');

nFail = nFail + check(isequal(size(voxelFromPlaneClick(1, 0, [0 0])), [1 3]), ...
    'the result is a 1x3 row', '');

fprintf('\n--- what it refuses ------------------------------------------\n');
nFail = nFail + check(threw(@() voxelFromPlaneClick(4, 1, [1 2]), ...
    'voxelFromPlaneClick:badPlane'), 'a plane that is not 1, 2 or 3', '');
nFail = nFail + check(threw(@() voxelFromPlaneClick(1, 1, [1 2 3]), ...
    'voxelFromPlaneClick:badValues'), 'three in-plane values instead of two', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - a click lands where it should.\n\n');
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
