function ok = test_parcellationColours()
%TEST_PARCELLATIONCOLOURS  Characterisation test for the parcellation colours.
%
%   ok = test_parcellationColours() computes the colour volume of the example
%   project's parcellation the way the toolbox used to - the eight lines that
%   sat inline in the Load parcellation button and in checkProjectStructure -
%   and checks that PARCELLATIONCOLOURS reproduces it exactly.
%
%   The reference is computed here, inline, rather than read from the
%   project. That matters: checkProjectStructure now calls the function under
%   test, so comparing against what it produced would prove nothing. The copy
%   below is the original code, kept deliberately, and it is what makes this
%   a real check.
%
%   Usage:  cd into the repository, then
%              test_parcellationColours
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

ielFile = fullfile(repoRoot,'examples','exampleNativeSpace.iel');
loaded  = load(ielFile,'-mat');
prj     = checkProjectStructure(loaded.s);

if isempty(prj.wmparc)
    fprintf('\nThis project carries no parcellation; nothing to compare.\n\n');
    ok = true; if nargout==0, clear ok; end
    return
end

img = prj.wmparc.img;
fprintf('\nParcellation: %s voxels, %d distinct region numbers\n', ...
    strjoin(arrayfun(@(n) num2str(n), size(img), 'UniformOutput', false),'x'), ...
    numel(unique(img(:))));

%% Reference: the original inline code, preserved on purpose
load FreeSurferColorLUT.mat values RGB          %#ok<LOAD>
[~,lob] = ismember(int32(img), int32(values));
lob(lob==0) = 1;
c = RGB(lob,:)/255;
expected = reshape(c, [size(img),3]);

%% What the extracted function produces
actual = parcellationColours(img);

nFail = 0;
nFail = nFail + check(isequal(size(expected), size(actual)), 'size', ...
    strjoin(arrayfun(@(n) num2str(n), size(actual), 'UniformOutput', false),'x'));
nFail = nFail + check(isequaln(expected, actual), 'every voxel colour identical', '');

%% Unknown regions must fall back to the table's first entry
odd = img;
odd(1) = intmax('int32');                       % a region number no table holds
oddColours = parcellationColours(odd);
nFail = nFail + check(isequal(squeeze(oddColours(1,1,1,:))', RGB(1,:)/255), ...
    'unknown region -> first LUT entry', '');

%% An explicit look-up table must be accepted
nFail = nFail + check(isequaln(parcellationColours(img,'FreeSurferColorLUT.mat'), actual), ...
    'explicit LUT gives the same result', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - parcellationColours reproduces the original mapping.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-38s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-38s %s\n', what, detail);  bad = 1;
end
end
