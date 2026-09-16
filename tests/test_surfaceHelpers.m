function ok = test_surfaceHelpers()
%TEST_SURFACEHELPERS  Check the surface helpers extracted from the Load buttons.
%
%   ok = test_surfaceHelpers() exercises ANNOTATIONCOLOURS and CENTRESURFACES
%   without opening a figure and without needing any FreeSurfer files.
%
%   ANNOTATIONCOLOURS is checked twice, against two independent references:
%
%     1. the original inline code, kept verbatim below;
%     2. the AnnotColor_L / AnnotColor_R stored inside
%        examples/exampleNativeSpace.iel, which were produced by the
%        toolbox when that patient's annotation files were first loaded.
%
%   The second is the stronger of the two: it is a real result, computed
%   from real FreeSurfer data before any of this restructuring existed.
%
%   READSURFACEPAIR is not covered - it needs .pial files, which the
%   repository does not ship. It is a verbatim move of the try/catch that
%   was in both Load buttons.
%
%   Usage:  cd into the repository, then
%              test_surfaceHelpers
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

nFail = 0;

fprintf('\n--- annotationColours vs the original inline code ------------\n');
for h = {'R','L'}
    side  = h{1};
    lbl   = prj.(['AnnotLabel_' side]);
    table = prj.(['AnnotColortable_' side]);
    if isempty(lbl) || isempty(table)
        fprintf('  --        hemisphere %s carries no annotation\n', side);
        continue
    end

    % the original code, preserved on purpose
    [~,ind] = ismember(lbl, table.table(:,5));
    expected = ones(length(ind),3)*.5;
    expected(find(ind),:) = table.table(ind(find(ind)),1:3)/255;   %#ok<FNDSB>

    actual = annotationColours(lbl, table);
    nFail = nFail + check(isequaln(expected, actual), ...
        sprintf('hemisphere %s, %d vertices', side, numel(lbl)), '');
end

fprintf('\n--- annotationColours vs the colours stored in the project ---\n');
for h = {'R','L'}
    side   = h{1};
    stored = prj.(['AnnotColor_' side]);
    lbl    = prj.(['AnnotLabel_' side]);
    table  = prj.(['AnnotColortable_' side]);
    if isempty(lbl) || isempty(table) || isempty(stored)
        fprintf('  --        hemisphere %s has nothing stored to compare\n', side);
        continue
    end
    actual = annotationColours(lbl, table);
    same   = isequal(size(stored), size(actual)) && max(abs(stored(:)-actual(:))) == 0;
    nFail  = nFail + check(same, ...
        sprintf('hemisphere %s reproduces the stored colours', side), '');
    if ~same && isequal(size(stored), size(actual))
        fprintf('              largest difference %.3g over %d vertices\n', ...
            max(abs(stored(:)-actual(:))), size(stored,1));
    end
end

fprintf('\n--- centreSurfaces -------------------------------------------\n');
volumeSize = size(prj.T1.img);
S2         = prj.S2;
v1 = [0 0 0; 1 2 3; -4 5 -6];
v2 = [10 10 10];

% the original code, preserved on purpose
trans = mesh2AnatSpace(volumeSize/2, S2);
e1 = v1 + repmat(trans, size(v1,1), 1);
e2 = v2 + repmat(trans, size(v2,1), 1);

[a1,a2] = centreSurfaces(volumeSize, S2, v1, v2);
nFail = nFail + check(isequaln(e1,a1) && isequaln(e2,a2), 'same shift as the original code', '');
nFail = nFail + check(isequal(size(a1), size(v1)), 'shape preserved', '');

one = centreSurfaces(volumeSize, S2, v1);
nFail = nFail + check(isequaln(one, e1), 'works with a single surface', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the surface helpers behave as they did inline.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-44s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-44s %s\n', what, detail);  bad = 1;
end
end
