function ok = test_sliceView()
%TEST_SLICEVIEW  Check that a plane comes out the way the old views drew it.
%
%   ok = test_sliceView() checks IELVIEW.SLICEVIEW against the expressions it
%   replaced, written out here, for all three planes and for both a grey
%   volume and a colour one. No figure is opened.
%
%   WHAT THIS DOES AND DOES NOT GUARD
%
%   It guards the three things a view needs before it can draw a plane - the
%   slice, the axes limits and the aspect ratio - against drifting from what
%   electrodes_gui.m's updateTAC did inline at lines 1730 and 1739-1741. Get
%   one of the three right and another wrong and the picture still looks like
%   a brain, which is why they are checked together.
%
%   It does not guard against a left-right mirror, because this function does
%   not perform one: fliplr(rot90(img,3)) is exactly a transpose - the
%   rotation and the flip undo each other's handedness. The mirror a reader
%   sees comes from XDir 'reverse', which the caller sets. Said here because
%   a test that claims to guard something it does not is worse than no test.
%
%   Usage:  cd into the repository, then
%              test_sliceView
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELVIEW.SLICEVIEW.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end

nFail = 0;

% a volume whose every voxel is different, so that a wrong turn cannot pass
D      = [4 5 6];
volume = reshape(1:prod(D), D);
voxdim = [0.8 1.0 1.25];

fprintf('\n--- the same slice the old views drew ------------------------\n');

for plane = 1:3
    index   = 2;
    inPlane = setdiff(1:3, plane);

    % the expression updateTAC used, written out
    idx        = {':', ':', ':'};
    idx{plane} = index;
    wanted     = fliplr(rot90(squeeze(volume(idx{:})), 3));

    [img, lims, aspect] = ielview.sliceView(volume, plane, index, voxdim);

    nFail = nFail + check(isequal(img, wanted), ...
        sprintf('plane %d: the slice matches the old expression', plane), ...
        mat2str(size(img)));

    nFail = nFail + check(isequal(lims, ...
        [0 D(inPlane(1)); 0 D(inPlane(2))]), ...
        sprintf('plane %d: the limits are the in-plane sizes', plane), '');

    nFail = nFail + check(isequal(aspect, ...
        [1/voxdim(inPlane(1)), 1/voxdim(inPlane(2)), 1]), ...
        sprintf('plane %d: the aspect ratio is the in-plane voxels', plane), '');
end

fprintf('\n--- a colour volume keeps its channels -----------------------\n');

colour = reshape(1:prod([D 3]), [D 3]);
for plane = 1:3
    index      = 3;
    idx        = {':', ':', ':'};
    idx{plane} = index;
    wanted     = fliplr(rot90(squeeze(colour(idx{:}, :)), 3));

    img = ielview.sliceView(colour, plane, index, voxdim);
    nFail = nFail + check(isequal(img, wanted), ...
        sprintf('plane %d: the colour slice matches', plane), ...
        mat2str(size(img)));
end

fprintf('\n--- a volume one slice thick ---------------------------------\n');
% size() drops trailing singleton dimensions, so these are the shapes that
% break a function which reads size(volume) and indexes the third element.
% The old inline code took the limits one dimension at a time and coped.

thin = reshape(1:20, [4 5 1]);
for plane = 1:3
    try
        [img, lims] = ielview.sliceView(thin, plane, 1, voxdim);
        inPlane = setdiff(1:3, plane);
        want    = [4 5 1];
        nFail = nFail + check(isequal(lims, ...
            [0 want(inPlane(1)); 0 want(inPlane(2))]), ...
            sprintf('plane %d: one slice thick still gives limits', plane), ...
            mat2str(size(img)));
    catch err
        nFail = nFail + check(false, ...
            sprintf('plane %d: one slice thick still gives limits', plane), ...
            ['threw ' err.identifier]);
    end
end

thinColour = reshape(1:60, [4 5 1 3]);
img = ielview.sliceView(thinColour, 1, 1, voxdim);
nFail = nFail + check(size(img, 3) == 3, ...
    'and a colour volume one slice thick keeps its channels', ...
    mat2str(size(img)));

fprintf('\n--- things that must hold whatever is asked for --------------\n');

img = ielview.sliceView(volume, 3, 1);
nFail = nFail + check(isequal(size(img), [D(2) D(1)]), ...
    'without voxel sizes it still slices', mat2str(size(img)));

[~, ~, a] = ielview.sliceView(volume, 3, 1);
nFail = nFail + check(isequal(a, [1 1 1]), ...
    'and the aspect ratio falls back to isotropic', '');

[~, ~, a] = ielview.sliceView(volume, 1, 1, -voxdim);
nFail = nFail + check(all(a > 0), ...
    'a negative voxel size is a size, not a direction', '');

fprintf('\n--- what it refuses ------------------------------------------\n');

nFail = nFail + check(threw(@() ielview.sliceView(volume, 4, 1, voxdim), ...
    'ielview:badPlane'), 'a plane that is not 1, 2 or 3', '');
nFail = nFail + check(threw(@() ielview.sliceView(volume, [1 2], 1, voxdim), ...
    'ielview:badPlane'), 'two planes at once', '');
nFail = nFail + check(threw(@() ielview.sliceView(volume, 1, 0, voxdim), ...
    'ielview:badIndex'), 'a slice before the first one', '');
nFail = nFail + check(threw(@() ielview.sliceView(volume, 1, D(1)+1, voxdim), ...
    'ielview:badIndex'), 'a slice past the last one', '');
nFail = nFail + check(threw(@() ielview.sliceView(volume, 1, 1.5, voxdim), ...
    'ielview:badIndex'), 'a slice between two slices', '');

% a zero voxel size gives an infinite aspect ratio, which fails in the
% caller on ax.DataAspectRatio, several lines from the cause
nFail = nFail + check(threw(@() ielview.sliceView(volume, 1, 1, [1 0 1]), ...
    'ielview:badVoxdim'), 'a voxel size of zero', '');
nFail = nFail + check(threw(@() ielview.sliceView(volume, 1, 1, [1 1]), ...
    'ielview:badVoxdim'), 'two voxel sizes instead of three', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - a slice comes out the way the old views drew it.\n\n');
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
