function ok = test_planningGrid()
%TEST_PLANNINGGRID  Check the planning-grid placement taken out of the GUI.
%
%   ok = test_planningGrid() compares PLACEPLANNINGGRID and NEWPLANNINGGRID
%   with the code that used to be written out in ten callbacks - eight arrow
%   and rotate buttons, "change centre" and "new grid" - kept verbatim in
%   local functions below. It runs on the real cortical envelope of
%   examples/exampleNativeSpace.iel. No figure is opened.
%
%   The eight buttons differed from each other in a single line: an offset
%   of 1 mm along one axis, or a rotation of 5 degrees. So one verbatim copy
%   of a move button and one of a rotate button, with that line made a
%   parameter, stand for all eight.
%
%   It then checks two things TANGENTIALGRID guarantees because every step
%   inside it is rigid: neighbouring contacts end up exactly the grid spacing
%   apart, and a rotate button turns every contact by exactly 5 degrees
%   about the centre.
%
%   Usage:  cd into the repository, then
%              test_planningGrid
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also PLACEPLANNINGGRID, NEWPLANNINGGRID, TANGENTIALGRID.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

ielFile = fullfile(repoRoot,'examples','exampleNativeSpace.iel');
loaded  = load(ielFile,'-mat');
prj     = checkProjectStructure(loaded.s);

if isempty(prj.vertices_SCE_L) || isempty(prj.vertices_SCE_R)
    fprintf('\nThis project carries no cortical envelope, so there is nothing to place a grid on.\n\n');
    ok = false; if nargout == 0, clear ok; end, return
end
vL = prj.vertices_SCE_L;
vR = prj.vertices_SCE_R;

nFail = 0;

%% ------------------------------------------------ building a new grid
fprintf('\n--- a new grid, against the code from the New button ---------\n');

% somewhere on the envelope: a vertex of it is on it by definition
centre = vR(round(size(vR,1)/2), :);
rows = 4;  cols = 5;  eDist = 10;

expNew = originalNewGrid(centre, rows, cols, eDist, vL, vR);
actNew = newPlanningGrid(centre, rows, cols, eDist, vL, vR);
nFail = nFail + check(isequaln(expNew, actNew), 'the whole structure is identical', ...
    sprintf('%dx%d, %g mm, %s', rows, cols, eDist, actNew.hemisphere));

nFail = nFail + check(numel(actNew.x) == rows*cols, 'one contact per grid position', ...
    sprintf('%d', numel(actNew.x)));
labelsOk = numel(actNew.ch_label) == rows*cols;
for i = 1:numel(actNew.ch_label)
    labelsOk = labelsOk && strcmp(actNew.ch_label{i}, ['grid' num2str(i)]);
end
nFail = nFail + check(labelsOk, 'contacts are named grid1, grid2, ...', '');
nFail = nFail + check(isequal(actNew.planning,'yes') && actNew.rotation == 0, ...
    'it is a planning array, unrotated', '');
nFail = nFail + check(isequal(size(actNew.adjMat), [rows*cols rows*cols]), ...
    'adjacency matrix is nContacts square', '');
nFail = nFail + checkSpacing(actNew, eDist);
nFail = nFail + checkNearCentre(actNew, centre);

%% ------------------------------------- moving and turning an existing grid
fprintf('\n--- moving it, against the code from the arrow buttons --------\n');

% the grid just built stands in for one the user already has; the project's
% own planning grid is used instead when it has one
target = actNew;
for j = 1:numel(prj.targets)
    t = prj.targets{j};
    if strcmp(t.Type,'grid') && isfield(t,'distance') && ~isempty(t.x) ...
            && numel(t.x) == t.rows*t.columns
        target = t;
        fprintf('   using planning grid "%s" from the project, %dx%d\n', t.Name, t.rows, t.columns);
        break
    end
end
here = mean([target.x target.y target.z]);

% six directions, exactly as the buttons have them
moves = {'superior',[0 0 1]; 'inferior',[0 0 -1]; 'posterior',[0 -1 0];
         'anterior',[0 1 0]; 'left',[-1 0 0];      'right',[1 0 0]};
for k = 1:size(moves,1)
    [name, offset] = moves{k,:};
    expMoved = originalMoveButton(target, offset, vL, vR);
    actMoved = placePlanningGrid(target, here + offset, [], vL, vR);
    nFail = nFail + check(isequaln(expMoved, actMoved), name, '');
end

fprintf('\n--- turning it, against the code from the rotate buttons ------\n');
for rot = [-5 5]
    expTurned = originalRotateButton(target, rot, vL, vR);
    actTurned = placePlanningGrid(target, here + [0 0 0], rot, vL, vR);
    nFail = nFail + check(isequaln(expTurned, actTurned), sprintf('%+d degrees', rot), '');
end

fprintf('\n--- recentring it, against the code from Change centre --------\n');
cursor = here + [2 -2 1];
expCentred = originalChangeCentre(target, cursor, vL, vR);
actCentred = placePlanningGrid(target, cursor, [], vL, vR);
nFail = nFail + check(isequaln(expCentred, actCentred), 'to a point near the surface', '');

%% -------------------------------------------- what a placed grid must be
fprintf('\n--- the geometry itself --------------------------------------\n');

moved = placePlanningGrid(target, here + [0 0 1], [], vL, vR);
nFail = nFail + checkSpacing(moved, target.distance);
nFail = nFail + checkNearCentre(moved, here + [0 0 1]);
nFail = nFail + check(isempty(moved.projection), 'an old projection is cleared', '');
nFail = nFail + check(~isempty(moved.hemisphere), 'the hemisphere is recomputed', moved.hemisphere);

% a rotate button turns every contact by exactly that angle about the centre
straight = placePlanningGrid(target, here, [], vL, vR);
turned   = placePlanningGrid(target, here, 5,  vL, vR);
P = [straight.x straight.y straight.z];  Q = [turned.x turned.y turned.z];
cP = mean(P);  cQ = mean(Q);
[~, far] = max(sqrt(sum((P - cP).^2, 2)));   % a contact well away from the centre
u = P(far,:) - cP;  v = Q(far,:) - cQ;
turnedBy = acosd(max(-1, min(1, dot(u,v) / (norm(u)*norm(v)))));
nFail = nFail + check(norm(cP - cQ) < 1e-9, 'turning keeps the centre where it was', '');
nFail = nFail + check(abs(turnedBy - 5) < 1e-6, 'a 5 degree turn turns it by 5 degrees', ...
    sprintf('%.9f', turnedBy));

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - planning grids are placed as they were by the ten callbacks.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function bad = checkSpacing(target, eDist)
% every contact's nearest neighbour is exactly one grid step away
P = [target.x target.y target.z];
D = eucDistMat(P, P);
D(eye(size(D)) == 1) = inf;
nearest = min(D, [], 2);
bad = check(max(abs(nearest - eDist)) < 1e-9, ...
    'neighbouring contacts are exactly one spacing apart', ...
    sprintf('%g mm, largest gap %.1e', eDist, max(abs(nearest - eDist))));
end

function bad = checkNearCentre(target, centre)
% the grid is centred on the surface patch within 10 mm of the point asked for
c = mean([target.x target.y target.z]);
bad = check(norm(c - centre) < 10, 'its centre is within 10 mm of the point asked for', ...
    sprintf('%.2f mm away', norm(c - centre)));
end

% ===================== the original code, kept verbatim =====================
% From newPlanningGridButton_Callback, reading rows/cols/eDist from arguments
% instead of edit boxes.

function target = originalNewGrid(crd, rows, cols, eDist, vertices_SCE_L, vertices_SCE_R)
options=[];
[pTan,hemisphere]=tangentialGrid(crd,rows,cols,eDist,vertices_SCE_L,vertices_SCE_R,options);

% save as a structure
target=[];
target.Type='grid';
target.Name='grid';
target.planning='yes';
target=checkElectrodeStructure(target);

target.x=pTan(:,1);
target.y=pTan(:,2);
target.z=pTan(:,3);
target.rows=rows;
target.columns=cols;
target.nElectrodes=rows*cols;
target.hemisphere=hemisphere;
target.rotation=0;
target.distance=eDist;

for i=1:target.nElectrodes
    target.ch_label{i} = [target.Name num2str(i)];
end
% make adjacency Matrix
target.adjMat=makeAdjMat(target.rows,target.columns);
end

% From pushbuttonSup_Callback. The other five arrow buttons differ only in
% the offset, which is therefore an argument here.

function target = originalMoveButton(target, offset, vertices_SCE_L, vertices_SCE_R)
X= [target.x target.y target.z];
mprev = mean (X); % previous center
crd = mprev + offset; % make more superior

options=[];
options.previousGrid=X;
[pTan,hemisphere]=tangentialGrid(crd,target.rows,target.columns,target.distance,vertices_SCE_L,vertices_SCE_R,options);

target.x=pTan(:,1);
target.y=pTan(:,2);
target.z=pTan(:,3);
target.hemisphere=hemisphere;
target.projection={};
target=checkElectrodeStructure(target);
end

% From RotLButton_Callback. rotRButton differs only in the sign.

function target = originalRotateButton(target, rotation, vertices_SCE_L, vertices_SCE_R)
X= [target.x target.y target.z];
mprev = mean (X); % previous center
crd = mprev; % same

options=[];
options.previousGrid=X;
options.additionalRotation = rotation; % rotate left
[pTan,hemisphere]=tangentialGrid(crd,target.rows,target.columns,target.distance,vertices_SCE_L,vertices_SCE_R,options);

target.x=pTan(:,1);
target.y=pTan(:,2);
target.z=pTan(:,3);
target.hemisphere=hemisphere;
target.projection={};
target=checkElectrodeStructure(target);
end

% From ChangeCenterPlanningGridButton_Callback, with handles.ui.cursor passed in.

function target = originalChangeCentre(target, cursor, vertices_SCE_L, vertices_SCE_R)
X= [target.x target.y target.z];

crd=cursor;

options=[];
options.previousGrid=X;
[pTan,hemisphere]=tangentialGrid(crd,target.rows,target.columns,target.distance,vertices_SCE_L,vertices_SCE_R,options);

target.x=pTan(:,1);
target.y=pTan(:,2);
target.z=pTan(:,3);
target.hemisphere=hemisphere;
target.projection={};
target=checkElectrodeStructure(target);
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-50s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-50s %s\n', what, detail);  bad = 1;
end
end
