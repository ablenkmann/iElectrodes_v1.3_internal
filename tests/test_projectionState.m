function ok = test_projectionState()
%TEST_PROJECTIONSTATE  Check the decisions taken out of the SCE checkbox.
%
%   ok = test_projectionState() compares ARRAYPROJECTIONSTATE and
%   SCESURFACEFORSPACE with the code that used to sit inside
%   processProjections, kept verbatim in local functions below. No figure is
%   opened.
%
%   Neither function projects anything - that is ELECTRODES2HULLCORRECTION's
%   job and it was already outside the GUI. What was inside the GUI were the
%   two decisions taken before it: which arrays are candidates at all, and
%   which surface to project them onto.
%
%   Usage:  cd into the repository, then
%              test_projectionState
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ARRAYPROJECTIONSTATE, SCESURFACEFORSPACE, ELECTRODES2HULLCORRECTION.

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

%% ------------------------------------- which arrays, against the old loops
fprintf('\n--- which arrays, against the code from processProjections ---\n');

[expProjectable, expDone] = originalArrayLoops(prj.electrodes);
[actProjectable, actDone] = arrayProjectionState(prj.electrodes);

nFail = nFail + check(isequal(logical(expProjectable), actProjectable), ...
    'same arrays are projectable', sprintf('%d of %d', sum(actProjectable), numel(actProjectable)));
nFail = nFail + check(isequal(logical(expDone), actDone), ...
    'same arrays already have a projection', sprintf('%d of %d', sum(actDone), numel(actDone)));

%% --------------------------------------------------- what the masks mean
fprintf('\n--- the masks themselves -------------------------------------\n');

misclassified   = 0;
depthProjectable = 0;
types = cell(1, numel(prj.electrodes));
for j = 1:numel(prj.electrodes)
    e = prj.electrodes{j};
    types{j} = e.Type;
    shouldProject = strcmp(e.Type,'grid') || strcmp(e.Type,'strip');
    if actProjectable(j) ~= shouldProject
        misclassified = misclassified + 1;
        fprintf('            %s is a %s but came back %d\n', e.Name, e.Type, actProjectable(j));
    end
    % a depth electrode is inside the brain, so there is nothing to project
    if strcmp(e.Type,'depth') && actProjectable(j)
        depthProjectable = depthProjectable + 1;
    end
end
nFail = nFail + check(misclassified == 0, 'every array is classified by its own Type', ...
    strjoin(types, ' '));
nFail = nFail + check(depthProjectable == 0, 'no depth electrode is marked projectable', ...
    sprintf('%d depth arrays', sum(strcmp(types,'depth'))));

nFail = nFail + check(isequal(size(actProjectable), [1 numel(prj.electrodes)]), ...
    'one entry per array, as a row', '');
nFail = nFail + check(islogical(actProjectable) && islogical(actDone), ...
    'the masks are logical', '');

% the case the old loop could not handle
[emptyProjectable, emptyDone] = arrayProjectionState({});
nFail = nFail + check(isempty(emptyProjectable) && isempty(emptyDone), ...
    'no arrays gives two empty masks', '');

%% ----------------------------------- which surface, against the old branch
fprintf('\n--- which surface --------------------------------------------\n');

if isempty(prj.vertices_SCE_L)
    fprintf('  note      this project carries no cortical envelope, so the\n');
    fprintf('            native branch cannot be compared here\n');
else
    [expV, expF] = originalNativeSurface(prj);
    [actV, actF] = sceSurfaceForSpace('Native', prj, struct());

    nFail = nFail + check(isequaln(expV, actV), 'native: same vertices as the old branch', ...
        sprintf('%d vertices', size(actV,1)));
    nFail = nFail + check(isequaln(expF, actF), 'native: same faces as the old branch', ...
        sprintf('%d faces', size(actF,1)));

    % the two hemispheres really are both in there
    nFail = nFail + check( ...
        size(actV,1) == size(prj.vertices_SCE_L,1) + size(prj.vertices_SCE_R,1), ...
        'native: both hemispheres are merged', ...
        sprintf('%d + %d', size(prj.vertices_SCE_L,1), size(prj.vertices_SCE_R,1)));
end

% a project whose envelope has not been built yet
noSCE = prj;
noSCE.vertices_SCE_L = [];
[emptyV, emptyF] = sceSurfaceForSpace('Native', noSCE, struct());
nFail = nFail + check(isempty(emptyV) && isempty(emptyF), ...
    'native: no envelope yet gives an empty surface', '');

% MNI space takes the template out of work, untouched
fakeWork.v_MNI_SCE = [0 0 0; 1 0 0; 0 1 0; 0 0 1];
fakeWork.f_MNI_SCE = [1 2 3; 1 2 4];
[mniV, mniF] = sceSurfaceForSpace('MNI', prj, fakeWork);
nFail = nFail + check(isequal(mniV, fakeWork.v_MNI_SCE) && isequal(mniF, fakeWork.f_MNI_SCE), ...
    'MNI: the shared template is taken from work', '');

% and it does not touch the project's own surfaces
nFail = nFail + check(~isequal(mniV, prj.vertices_SCE_L), ...
    'MNI: the patient''s own envelope is not used', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the projection decisions are made as they were in the GUI.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% From processProjections, with handles.project.electrodes passed in.

function [isgrid, projDone] = originalArrayLoops(electrodes)

for i=1:length(electrodes)
    isgrid(i)=strcmp({electrodes{i}.Type},'grid') || strcmp({electrodes{i}.Type},'strip');
end

projDone=[];
for i=1:length(electrodes)
    projDone(i)=~isempty(electrodes{i}.projection);
end
end

% The native branch of the same function.

function [vertices, faces] = originalNativeSurface(project)
[vertices,faces]=mergemesh(project.vertices_SCE_L, project.faces_SCE_L, project.vertices_SCE_R, project.faces_SCE_R );
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-48s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-48s %s\n', what, detail);  bad = 1;
end
end
