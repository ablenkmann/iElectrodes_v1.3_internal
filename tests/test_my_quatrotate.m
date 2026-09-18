function ok = test_my_quatrotate()
%TEST_MY_QUATROTATE  Check quaternion rotation of one vector and of many.
%
%   ok = test_my_quatrotate() checks MY_QUATROTATE against the properties a
%   rotation has to have, and checks that rotating an M-by-3 array gives the
%   same answer as rotating its rows one at a time. No figure is opened, and
%   no project file is needed.
%
%   That last check is the point of this test. MY_QUATROTATE stands in for
%   the Aerospace Toolbox function QUATROTATE, which takes an M-by-3 array,
%   and every caller in this toolbox passes one - the ideal positions of a
%   whole depth electrode, one contact per row. The stand-in accepted only a
%   single 3-element vector, so it raised
%
%       Input vector must be a 3-element vector [x, y, z].
%
%   and no depth electrode could be fitted at all. See docs/OPEN_QUESTIONS.md
%   item 14.
%
%   Usage:  cd into the repository, then
%              test_my_quatrotate
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also MY_QUATROTATE, GRIDMATCHENERGY, DISTANCECONSTRAIN, GRIDFIT.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end

tol   = 1e-12;
nFail = 0;

%% ------------------------------------------------- a single vector, as before
fprintf('\n--- one vector ------------------------------------------------\n');

identity = [1 0 0 0];
nFail = nFail + check(norm(my_quatrotate(identity, [1 2 3]) - [1 2 3]) < tol, ...
    'the identity quaternion changes nothing', '');

% 90 degrees about z, in the convention QUATROTATE documents: x goes to -y
c = cos(pi/4);
qz90 = [c 0 0 c];
nFail = nFail + check(norm(my_quatrotate(qz90, [1 0 0]) - [0 -1 0]) < tol, ...
    'a quarter turn about z sends x to -y', '');

% the shape of a single vector is preserved, row or column
nFail = nFail + check(isequal(size(my_quatrotate(qz90, [1 0 0])),  [1 3]), ...
    'a row vector comes back a row', '');
nFail = nFail + check(isequal(size(my_quatrotate(qz90, [1;0;0])),  [3 1]), ...
    'a column vector comes back a column', '');

% length is preserved - it is a rotation
v = [3 -1 2];
nFail = nFail + check(abs(norm(my_quatrotate(qz90, v)) - norm(v)) < tol, ...
    'length is unchanged', sprintf('%.3f', norm(v)));

% a quaternion that is not a unit is normalised first
nFail = nFail + check(norm(my_quatrotate(2*qz90, v) - my_quatrotate(qz90, v)) < tol, ...
    'scaling the quaternion changes nothing', '');

%% ------------------------------------ many vectors: the case that was missing
fprintf('\n--- an M-by-3 array ------------------------------------------\n');

% a depth electrode's ideal positions, which is what the callers pass
nContacts = 8;
posIdeal  = zeros(nContacts,3);
posIdeal(:,1) = (0:3.5:(nContacts-1)*3.5)';
t = [12 -4 30];
block = posIdeal + t;

q = [0.6 0.1 -0.3 0.5];   % nothing special, deliberately not a nice angle

threw = '';
try
    rotatedBlock = my_quatrotate(q, block);
catch err
    threw = err.message;
end
nFail = nFail + check(isempty(threw), 'an 8-by-3 array is accepted at all', threw);

if ~isempty(threw)
    fprintf('\nFAIL - this is the bug the fix was for.\n\n');
    ok = false; if nargout == 0, clear ok; end, return
end

nFail = nFail + check(isequal(size(rotatedBlock), [nContacts 3]), ...
    'the array keeps its shape', sprintf('%dx%d', size(rotatedBlock,1), size(rotatedBlock,2)));

% the property that matters: rows are independent
rowByRow = zeros(nContacts,3);
for i = 1:nContacts
    rowByRow(i,:) = my_quatrotate(q, block(i,:));
end
nFail = nFail + check(max(abs(rotatedBlock(:) - rowByRow(:))) < tol, ...
    'every row is rotated as a single vector would be', ...
    sprintf('largest gap %.2e', max(abs(rotatedBlock(:) - rowByRow(:)))));

% a rotation is rigid: distances between contacts survive it
dBefore = eucDistMat(block, block);
dAfter  = eucDistMat(rotatedBlock, rotatedBlock);
nFail = nFail + check(max(abs(dBefore(:) - dAfter(:))) < 1e-9, ...
    'contact spacing is unchanged', ...
    sprintf('largest gap %.2e mm', max(abs(dBefore(:) - dAfter(:)))));

nFail = nFail + check(norm(my_quatrotate(identity, block) - block, 'fro') < tol, ...
    'the identity quaternion leaves the array alone', '');

%% --------------------------------------------------------- what it refuses
fprintf('\n--- what it refuses ------------------------------------------\n');
threw = '';
try
    my_quatrotate(q, [1 2; 3 4; 5 6]);
catch err
    threw = err.identifier;
end
nFail = nFail + check(strcmp(threw, 'my_quatrotate:badVector'), ...
    'an M-by-2 array is not a list of 3-D vectors', threw);

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - one vector or many, rotated the same way.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-48s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-48s %s\n', what, detail);  bad = 1;
end
end
