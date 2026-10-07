function ok = test_ielecCoordinates()
%TEST_IELECCOORDINATES  Check the four functions for the contacts in progress.
%
%   ok = test_ielecCoordinates() adds a contact by hand, removes one,
%   clears them all and undoes each, and compares every result with the
%   lines the Add, Delete, Clear and Undo buttons ran, kept verbatim at the
%   end of this file.
%
%   The check that matters most is the weight. The button read the CT at the
%   voxel the three sliders were on; IELEC.ADDCOORDINATE is given an
%   anatomical coordinate instead - which is what the layer deals in - and
%   has to come back to the same voxel through the same transform. The
%   example project's real S2 and real CT are used for that, at several
%   cursor positions, because a made-up transform would not test it.
%
%   The bookkeeping checks use a synthetic work instead: removing a contact
%   from the middle renumbers the clusters above it and drops the voxels
%   below it, and building that state by hand is both faster and clearer
%   than clustering until it happens.
%
%   Usage:  cd into the repository, then
%              test_ielecCoordinates
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.ADDCOORDINATE, IELEC.REMOVECOORDINATE,
%            IELEC.CLEARCOORDINATES, IELEC.UNDOCOORDINATES, KEEPFORUNDO.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

cfgOpen = [];
cfgOpen.file = fullfile(repoRoot, 'examples', 'exampleNativeSpace.iel');
[project, work] = ielec.openProject(cfgOpen, [], []);

%% ------------------------------------------- the weight, against the button
fprintf('\n--- ielec.addCoordinate against the Add button ---------------\n');

% a handful of cursor positions inside the CT, as the sliders would be
sz = size(project.TAC.img);
voxels = [round(sz/2); round(sz/3); round(sz/2) + [5 -7 3]; ...
          round(sz/4) + [1 1 1]];

sameWeight = true;
worstGap   = 0;
for k = 1:size(voxels, 1)
    v = voxels(k, :);
    expected = originalAdd(project, work, v);

    cfg = [];
    cfg.coordinate = mesh2AnatSpace(v, project.S2);
    [gotProject, got] = ielec.addCoordinate(cfg, project, work);

    sameWeight = sameWeight && isequaln(got.brushWeight, expected.brushWeight);
    worstGap   = max(worstGap, max(abs(got.GS(end,:) - expected.GS(end,:))));

    if k == 1
        nFail = nFail + check(isequaln(got, expected), ...
            'the contact the button added, work for work', ...
            sprintf('weight %g', expected.brushWeight(end)));
        nFail = nFail + check(isequal(fieldnames(got), fieldnames(expected)), ...
            'and the fields in the same order', 'both already had them');
        nFail = nFail + check(isequaln(gotProject, project), ...
            'project is not changed', '');
    end
end
nFail = nFail + check(sameWeight, ...
    'the CT weight is the same at every cursor position', ...
    sprintf('%d positions', size(voxels,1)));
nFail = nFail + check(worstGap == 0, ...
    'and the coordinate round-trips exactly', ...
    sprintf('largest difference %g mm', worstGap));

% a project with no CT weighs a hand-placed contact 0, as the button did
noCT = project;
noCT.TAC = [];
cfg = [];
cfg.coordinate = mesh2AnatSpace(voxels(1,:), project.S2);
[~, noCTwork] = ielec.addCoordinate(cfg, noCT, work);
nFail = nFail + check(noCTwork.brushWeight(end) == 0, ...
    'with no CT the weight is 0', '');

% Field order is only observable where the undo copies did not exist yet: a
% work out of CHECKPROJECTSTRUCTURE already has all eight, and assigning an
% existing field does not move it. This is the version of that check that can
% fail - KEEPFORUNDO has to create them in the order the button created them.
bare = rmfield(inProgressFields(work), ...
    {'oldGS', 'oldbrushCrd', 'oldbrushWeight', 'oldclusters'});
expectedBare = originalAdd(project, bare, voxels(1,:));
[~, gotBare] = ielec.addCoordinate(...
    struct('coordinate', mesh2AnatSpace(voxels(1,:), project.S2)), project, bare);
nFail = nFail + check(isequal(fieldnames(gotBare), fieldnames(expectedBare)), ...
    'the undo copies are created in the button''s order', ...
    'observable only where they did not exist');

%% ------------------------------ the bookkeeping, on a state built by hand
fprintf('\n--- ielec.removeCoordinate against the Delete button ---------\n');

% four contacts, each made of two voxels, so that removing the second one
% has clusters above it to renumber and voxels below it to drop
inProgress = work;
inProgress.GS          = [0 0 0; 10 0 0; 20 0 0; 30 0 0];
inProgress.brushCrd    = [0 0 0; 1 0 0; 10 0 0; 11 0 0; ...
                          20 0 0; 21 0 0; 30 0 0; 31 0 0];
inProgress.brushWeight = (1:8)';
inProgress.clusters    = [1;1; 2;2; 3;3; 4;4];

% and something in the fields Clear must NOT touch, so that check cannot
% pass by both sides being absent
inProgress.candidateVoxels = [1 2 3; 4 5 6];
inProgress.selectedVoxels  = [1 2 3];

empty = inProgress;
empty.GS = []; empty.brushCrd = []; empty.brushWeight = []; empty.clusters = [];

only = inProgress;
only.GS = [0 0 0]; only.brushCrd = [0 0 0; 1 0 0];
only.brushWeight = [1;2]; only.clusters = [1;1];

% Each case against the button's own lines, REMOVED included. The button
% warns on the cases it refuses, so its warning is silenced around the calls.
cases = {
  inProgress, [10  0  0],      'a contact in the middle, as the button removed it'
  inProgress, [ 0  0  0],      'the first contact'
  inProgress, [30  0  0],      'the last contact'
  only,       [ 0  0  0],      'the only contact'
  inProgress, [500 500 500],   'nothing within 2 mm'
  inProgress, [NaN NaN NaN],   'a NaN coordinate'
  empty,      [ 0  0  0],      'an empty list of contacts'
};
warnBefore = warning('off', 'all');
for k = 1:size(cases, 1)
    before = cases{k,1};
    crd    = cases{k,2};
    [expected, wantRemoved] = originalDelete(before, crd);
    [~, got, removed] = ielec.removeCoordinate(struct('coordinate', crd), ...
                                               project, before);
    nFail = nFail + check(isequaln(got, expected) && removed == wantRemoved, ...
        cases{k,3}, sprintf('removed %d', removed));
    if ~wantRemoved
        nFail = nFail + check(isequaln(got, before), ...
            '   and nothing was written, undo copies included', '');
    end
end
warning(warnBefore);

% the renumbering, spelled out for the middle case
[~, middle] = ielec.removeCoordinate(struct('coordinate', [10 0 0]), ...
                                      project, inProgress);
nFail = nFail + check(isequal(middle.clusters, [1;1; 2;2; 3;3]), ...
    'the clusters above it came down by one', mat2str(middle.clusters'));
nFail = nFail + check(isequal(middle.brushWeight, [1;2; 5;6; 7;8]), ...
    'and its own voxels went with it', mat2str(middle.brushWeight'));

% the tolerance is a tolerance
[~, ~, farButAllowed] = ielec.removeCoordinate(...
    struct('coordinate', [10 0 4], 'tolerance', 5), project, inProgress);
[~, ~, farAndNot] = ielec.removeCoordinate(...
    struct('coordinate', [10 0 4]), project, inProgress);
nFail = nFail + check(farButAllowed && ~farAndNot, ...
    'cfg.tolerance decides how near is near enough', '4 mm away: 5 yes, 2 no');

%% --------------------------------------------------------- clear and undo
fprintf('\n--- clearing and undoing -------------------------------------\n');

expected = originalClear(inProgress);
[~, cleared] = ielec.clearCoordinates([], project, inProgress);
nFail = nFail + check(isequaln(cleared, expected), ...
    'the Clear button, work for work', '');
nFail = nFail + check(isempty(cleared.GS) && isempty(cleared.brushCrd) && ...
        isempty(cleared.brushWeight) && isempty(cleared.clusters), ...
    'all four are empty', '');
nFail = nFail + check(isequal(cleared.oldGS, inProgress.GS), ...
    'and what was there is kept for Undo', ...
    sprintf('%d contacts', size(inProgress.GS,1)));
nFail = nFail + check(isequaln(cleared.candidateVoxels, inProgress.candidateVoxels) && ...
        isequaln(cleared.selectedVoxels, inProgress.selectedVoxels), ...
    'the voxels they were picked from are left alone', ...
    'so they can be clustered again');

expected = originalUndo(cleared);
[~, undone] = ielec.undoCoordinates([], project, cleared);
nFail = nFail + check(isequaln(undone, expected), ...
    'the Undo button, work for work', '');
nFail = nFail + check(isequal(undone.GS, inProgress.GS), ...
    'Undo after Clear brings the contacts back', ...
    sprintf('%d contacts', size(undone.GS,1)));

[~, undoneTwice] = ielec.undoCoordinates([], project, undone);
nFail = nFail + check(isequaln(undoneTwice, cleared), ...
    'and Undo twice puts them away again - it is a swap', '');

%% ------------------------------------------- each of them keeps an undo
fprintf('\n--- each one can be taken back -------------------------------\n');

for op = {'add', 'remove', 'clear'}
    switch op{1}
        case 'add'
            [~, after] = ielec.addCoordinate(...
                struct('coordinate', mesh2AnatSpace(voxels(1,:), project.S2)), ...
                project, inProgress);
        case 'remove'
            [~, after] = ielec.removeCoordinate(...
                struct('coordinate', [10 0 0]), project, inProgress);
        case 'clear'
            [~, after] = ielec.clearCoordinates([], project, inProgress);
    end
    [~, back] = ielec.undoCoordinates([], project, after);
    nFail = nFail + check(isequal(back.GS, inProgress.GS) && ...
            isequal(back.clusters, inProgress.clusters) && ...
            isequal(back.brushCrd, inProgress.brushCrd) && ...
            isequal(back.brushWeight, inProgress.brushWeight), ...
        sprintf('%s, then Undo, is where it started', op{1}), '');
end

%% ------------------------------------------------------ what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

refusals = {
  @() ielec.addCoordinate(struct('coordinate', [1 2]), project, work), ...
      'ielec:badOption', 'a coordinate that is not three numbers'
  @() ielec.addCoordinate([], project, work), ...
      'ielec:missingOption', 'no coordinate at all'
  @() ielec.addCoordinate(struct('crd', [1 2 3]), project, work), ...
      'ielec:unknownOption', 'an unknown option'
  @() ielec.removeCoordinate(struct('coordinate', [0 0 0], 'tolerance', -1), ...
      project, inProgress), ...
      'ielec:badOption', 'a tolerance that is not a distance'
  @() ielec.clearCoordinates(struct('all', true), project, work), ...
      'ielec:unknownOption', 'an option Clear does not have'
  @() ielec.undoCoordinates(struct('steps', 2), project, work), ...
      'ielec:unknownOption', 'an option Undo does not have'
};
for r = 1:size(refusals, 1)
    nFail = nFail + check(strcmp(errorId(refusals{r,1}), refusals{r,2}), ...
        refusals{r,3}, refusals{r,2});
end

% Outside the CT. This is the case that catches an error() whose message
% formats a vector: MATLAB refuses a non-scalar formatted argument and throws
% MATLAB:error:nonScalarInput instead, losing the identifier and the message.
outside = mesh2AnatSpace(size(project.TAC.img) + [10 10 10], project.S2);
nFail = nFail + check(strcmp(errorId(@() ielec.addCoordinate(...
        struct('coordinate', outside), project, work)), 'ielec:badOption'), ...
    'a coordinate outside the CT', 'ielec:badOption, message and all');

% no image to place a contact on
noImage = project;
noImage.S2 = [];
nFail = nFail + check(strcmp(errorId(@() ielec.addCoordinate(...
        struct('coordinate', [0 0 0]), noImage, work)), 'ielec:noMRI'), ...
    'no image to place it on', 'ielec:noMRI');

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.addCoordinate) == 3 && ...
        nargout(@ielec.addCoordinate) == 2, 'addCoordinate''s signature', '');
nFail = nFail + check(nargin(@ielec.removeCoordinate) == 3 && ...
        nargout(@ielec.removeCoordinate) == 3, ...
    'removeCoordinate''s, with the report as the third output', '');
nFail = nFail + check(nargin(@ielec.clearCoordinates) == 3 && ...
        nargout(@ielec.clearCoordinates) == 2, 'clearCoordinates''s', '');
nFail = nFail + check(nargin(@ielec.undoCoordinates) == 3 && ...
        nargout(@ielec.undoCoordinates) == 2, 'undoCoordinates''s', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the contacts in progress change as the buttons changed them.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% What the four buttons ran, with the slider reads, the counter, the redraw
% and GUIDATA taken out - and nothing else. ORIGINALDELETE keeps the
% nearest-contact search and the proximity branch, because those are half of
% what IELEC.REMOVECOORDINATE took over and the half that decides REMOVED.
% The slider values arrive as VOXEL, which is what FLOOR of the three
% sliders gave.

function work = originalAdd(project, work, voxel)
    handles.project = project;
    handles.work    = work;
    x = voxel(1);  y = voxel(2);  z = voxel(3);

    crd=[x y z];
    crd=mesh2AnatSpace(crd,handles.project.S2);

    if ~isempty(handles.project.TAC)
        weight=handles.project.TAC.img(x,y,z)-min(handles.project.TAC.img(:));
    else
        weight=0; % force to zero if CT not present
    end

    % save old GS
    handles.work.oldGS=handles.work.GS;
    handles.work.oldbrushCrd=handles.work.brushCrd;
    handles.work.oldbrushWeight=handles.work.brushWeight;
    handles.work.oldclusters=handles.work.clusters;

    handles.work.GS=[handles.work.GS; crd];
    handles.work.brushCrd=[handles.work.brushCrd; crd];
    handles.work.clusters=[handles.work.clusters; (length(unique(handles.work.clusters))+1)];
    handles.work.brushWeight=[handles.work.brushWeight; weight];

    work = handles.work;
end

function [work, removed] = originalDelete(work, crd)
    handles.work = work;
    removed = false;

    %search for closest coordinate
    dist=eucDistMat(handles.work.GS,crd);
    [m,ind]=min(dist);

    if m<2 %2mm
    % save old GS
    handles.work.oldGS=handles.work.GS;
    handles.work.oldbrushCrd=handles.work.brushCrd;
    handles.work.oldbrushWeight=handles.work.brushWeight;
    handles.work.oldclusters=handles.work.clusters;

    %remove coordinate from GS
    handles.work.GS(ind,:)=[];

    indClus=find(handles.work.clusters==ind); %actual cluster
    indBigClus=find(handles.work.clusters>ind); %clusters of bigger index

    handles.work.clusters(indBigClus,:)= handles.work.clusters(indBigClus,:)-1; %decrease the clus num
    handles.work.clusters(indClus,:)=[]; % remove cluster elements

    handles.work.brushCrd(indClus,:)=[]; %remove brush coords
    handles.work.brushWeight(indClus,:)=[]; %remove brushweight

        removed = true;
    else
        warning('No electrodes in the proximity (2mm) to be deleted')
    end

    work = handles.work;
end

function work = originalClear(work)
    handles.work = work;

    % save old GS
    handles.work.oldGS=handles.work.GS;
    handles.work.oldbrushCrd=handles.work.brushCrd;
    handles.work.oldbrushWeight=handles.work.brushWeight;
    handles.work.oldclusters=handles.work.clusters;

    handles.work.GS=[];
    handles.work.brushCrd=[];
    handles.work.brushWeight=[];
    handles.work.clusters=[];

    work = handles.work;
end

function work = originalUndo(work)
    handles.work = work;

    tempGS=handles.work.GS;
    handles.work.GS=handles.work.oldGS;
    handles.work.oldGS=tempGS;

    tempbrushCrd=handles.work.brushCrd;
    handles.work.brushCrd=handles.work.oldbrushCrd;
    handles.work.oldbrushCrd=tempbrushCrd;

    tempbrushWeight=handles.work.brushWeight;
    handles.work.brushWeight=handles.work.oldbrushWeight;
    handles.work.oldbrushWeight=tempbrushWeight;

    tempclusters=handles.work.clusters;
    handles.work.clusters=handles.work.oldclusters;
    handles.work.oldclusters=tempclusters;

    work = handles.work;
end

% ---------------------------------------------------------------------
function work = inProgressFields(work)
% the four in-progress fields emptied, so that RMFIELD of the old* copies
% leaves something a button could have been pressed on
work.GS = []; work.brushCrd = []; work.brushWeight = []; work.clusters = [];
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
