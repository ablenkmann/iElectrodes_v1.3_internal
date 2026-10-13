function ok = test_ielecNewDepthTarget()
%TEST_IELECNEWDEPTHTARGET  Check ielec.newDepthTarget.
%
%   ok = test_ielecNewDepthTarget() plans a depth electrode with an empty
%   cfg and compares it with the array the New target button built, kept
%   verbatim at the end of this file and followed by the UPDATETARGET and
%   ESTIMATEANGLESFRAME the button ran straight afterwards.
%
%   An empty cfg has to reproduce the button exactly - that is the whole
%   claim - so the comparison is on values AND on field order, which reaches
%   the .iel file. The button's ten hard-coded channel labels are compared
%   against the ones the layer generates, one by one.
%
%   The cfg's other values have no counterpart in the button, which could
%   only ever build this one electrode, so they are checked for internal
%   consistency instead: a cfg.nContacts of 8 has to give eight labels,
%   eight contacts, eight rows and an adjacency matrix to match.
%
%   Usage:  cd into the repository, then
%              test_ielecNewDepthTarget
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.NEWDEPTHTARGET, IELEC.AIMTARGET, IELEC.NEWTARGET,
%            CHECKELECTRODESTRUCTURE.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

work = struct();
project = [];
project.targets    = {};
project.electrodes = {};

%% ----------------------------------------- an empty cfg is the button
fprintf('\n--- ielec.newDepthTarget against the New target button -------\n');

expected = chain(originalNewTarget(project).targets{1});
[got, gotWork, index] = ielec.newDepthTarget([], project, work);

nFail = nFail + check(isequaln(got.targets{index}, expected), ...
    'an empty cfg plans the array the button planned', ...
    sprintf('%d contacts, azimuth %.4g', expected.nElectrodes, expected.azimut));
nFail = nFail + check(isequal(fieldnames(got.targets{index}), fieldnames(expected)), ...
    'with its fields in the same order', 'order reaches the .iel file');
nFail = nFail + check(index == 1 && numel(got.targets) == 1, ...
    'and it went on the end of the planning list', sprintf('index %d', index));
nFail = nFail + check(isequaln(gotWork, work), 'work is not changed', '');
nFail = nFail + check(isequaln(withoutHistory(rmfield(got, 'targets')), withoutHistory(rmfield(project, 'targets'))), ...
    'and nothing else in the project is', '');

% the ten labels the button spelled out by hand
buttonLabels = {'Planning 1','Planning 2','Planning 3','Planning 4','Planning 5',...
    'Planning 6','Planning 7','Planning 8','Planning 9','Planning 10'};
nFail = nFail + check(isequal(got.targets{index}.ch_label, buttonLabels), ...
    'the generated labels are the ten it spelled out', ...
    strjoin(got.targets{index}.ch_label([1 end]), ' ... '));

% The button's placeholder x = (0:5:45)' is not set here, because the
% contacts are laid out before this returns. Two things follow from that and
% they are not the same thing.
placeholder = (0:5:45)';

% The three sliders do not move. SHOWPLANNINGARRAY sets them from the first
% contact, and the first contact of the aimed electrode is the deep end -
% which is where the placeholder's first row was.
nFail = nFail + check(isequaln([got.targets{index}.x(1) got.targets{index}.y(1) ...
        got.targets{index}.z(1)], placeholder(1) * [1 1 1]), ...
    'the first contact is where the placeholder started', ...
    'so the three sliders land in the same place');

% What is DRAWN does change, and on purpose. SHOWPLANNINGARRAY redraws the
% 3-D view and the three slices from the whole of .x/.y/.z, and the button's
% own UPDATETARGET never redraws - so the button used to leave the user
% looking at the placeholder while the project held the real electrode. Now
% the two agree. docs/OPEN_QUESTIONS.md item 38.
drawn = [got.targets{index}.x(end) got.targets{index}.y(end) got.targets{index}.z(end)];
nFail = nFail + check(~isequaln(drawn, placeholder(end) * [1 1 1]) && ...
        all(abs(drawn - 45/sqrt(3)) < 1e-9), ...
    'and what is drawn is the electrode, not the placeholder', ...
    sprintf('last contact [%.4g %.4g %.4g], not [45 45 45]', drawn));

%% ------------------------------------------- it goes after what is there
fprintf('\n--- a second one ---------------------------------------------\n');

[two, ~, index2] = ielec.newDepthTarget([], got, work);
nFail = nFail + check(index2 == 2 && numel(two.targets) == 2, ...
    'the next one goes after it', sprintf('index %d', index2));
nFail = nFail + check(isequaln(two.targets{1}, got.targets{1}), ...
    'and the first is left alone', '');

%% --------------------------------------------------- an empty project
fprintf('\n--- and it needs no image and no surface ---------------------\n');

bare = struct();
[fromNothing, ~, idx] = ielec.newDepthTarget([], bare, work);
nFail = nFail + check(idx == 1 && numel(fromNothing.targets) == 1, ...
    'a depth target can be planned in an empty project', ...
    'unlike a grid, which needs the envelope');

%% ------------------------------------------------------ what the cfg does
fprintf('\n--- and what the cfg changes ---------------------------------\n');

cfg = [];
cfg.name        = 'LA';
cfg.targetIn    = [-24 -12 -18];
cfg.targetOut   = [-60 -12 -10];
cfg.nContacts   = 8;
cfg.firstSecond = 3;
cfg.secondLast  = 4.5;
[custom, ~, k] = ielec.newDepthTarget(cfg, project, work);
t = custom.targets{k};

nFail = nFail + check(strcmp(t.Name, 'LA') && numel(t.ch_label) == 8 && ...
        strcmp(t.ch_label{1}, 'LA 1') && strcmp(t.ch_label{8}, 'LA 8'), ...
    'cfg.name names the array and every contact', t.ch_label{end});
nFail = nFail + check(t.nElectrodes == 8 && t.rows == 8 && t.columns == 1 && ...
        numel(t.x) == 8 && isequal(t.adjMat, makeAdjMat(8, 1)), ...
    'cfg.nContacts reaches the count, the rows and the adjacency matrix', ...
    sprintf('%d contacts', numel(t.x)));
nFail = nFail + check(isequaln([t.targetIn.x t.targetIn.y t.targetIn.z], ...
        cfg.targetIn) && isequaln([t.targetOut.x t.targetOut.y t.targetOut.z], ...
        cfg.targetOut), ...
    'both ends are the ones it was given', '');
nFail = nFail + check(abs(norm([t.x(2)-t.x(1) t.y(2)-t.y(1) t.z(2)-t.z(1)]) ...
        - cfg.firstSecond) < 1e-9 && ...
        abs(norm([t.x(3)-t.x(2) t.y(3)-t.y(2) t.z(3)-t.z(2)]) ...
        - cfg.secondLast) < 1e-9, ...
    'the first gap and the rest are the two spacings', ...
    sprintf('%g then %g mm', cfg.firstSecond, cfg.secondLast));
nFail = nFail + check(~isempty(t.alpha) && ~isempty(t.beta) && ...
        ~isempty(t.delta) && numel(t.distances) == 8, ...
    'it comes back aimed and framed, not a shell', ...
    sprintf('alpha %.4g, beta %.4g', t.alpha, t.beta));

% Against TRAJECTORYFRAMEANGLES on the same trajectory, not against "it
% differs from Anterior": for a Right frame alpha happens to equal Anterior's,
% and only beta moves, so a check on alpha alone would read as a failure.
framed = ielec.newDepthTarget(struct('framePosition', 'Left'), project, work);
[wantAlpha, wantBeta] = trajectoryFrameAngles(expected.delta, ...
        expected.z(expected.nElectrodes), 'Left');
nFail = nFail + check(strcmp(framed.targets{1}.framePosition, 'Left') && ...
        isequaln([framed.targets{1}.alpha framed.targets{1}.beta], ...
                 [wantAlpha wantBeta]), ...
    'cfg.framePosition reaches the frame angles', ...
    sprintf('alpha %.4g, beta %.4g', wantAlpha, wantBeta));

%% ------------------------------------------------------ what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

refusals = {
  struct('targetIn', [1 2]),        'a deep end that is not three numbers', 'cfg.targetIn'
  struct('targetOut', [1 2 3 4]),   'a far end that is not three numbers',  'cfg.targetOut'
  struct('nContacts', [4 5]),       'a count that is not one number',       'cfg.nContacts'
  struct('nContacts', 0),           'no contacts at all',                   'cfg.nContacts = 0'
  struct('nContacts', 2.5),         'a count that is not whole',            'cfg.nContacts = 2.5'
  struct('name', ''),               'a name that is empty',                 "cfg.name = ''" 
  struct('firstSecond', 'five'),    'a spacing that is not a number',       'cfg.firstSecond'
  struct('name', 7),                'a name that is not a name',            'cfg.name'
  struct('framePosition', 'Up'),    'a mounting that is not one of the four', 'Up'
};
for r = 1:size(refusals, 1)
    nFail = nFail + check(strcmp(errorId(@() ielec.newDepthTarget(refusals{r,1}, ...
            project, work)), 'ielec:badOption'), ...
        refusals{r,2}, refusals{r,3});
end
nFail = nFail + check(strcmp(errorId(@() ielec.newDepthTarget(...
        struct('contacts', 8), project, work)), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.contacts');

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.newDepthTarget) == 3 && ...
        nargout(@ielec.newDepthTarget) == 3, ...
    'newDepthTarget''s signature, the index as the third output', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the depth target is the one the button built.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% NEWTARGETPUSHBUTTON_CALLBACK's own lines, with the eleven SET calls on the
% boxes taken out, then the UPDATETARGET and ESTIMATEANGLESFRAME it called
% next - the same two blocks tests/test_ielecAimTarget.m uses.

function out = originalNewTarget(project)
    handles.project = project;

    target=[];
    target.Type='depth';
    target.Name='Planning';
    target.planning='yes';
    target=checkElectrodeStructure(target);

    target.targetIn.x=0;
    target.targetIn.y=0;
    target.targetIn.z=0;

    target.targetOut.x=45;
    target.targetOut.y=45;
    target.targetOut.z=45;

    target.x=[0:5:45]';
    target.y=[0:5:45]';
    target.z=[0:5:45]';

    target.rows=10;
    target.columns=1;
    target.adjMat=makeAdjMat(target.rows,target.columns);

    target.ch_label={'Planning 1','Planning 2','Planning 3','Planning 4','Planning 5',...
        'Planning 6','Planning 7','Planning 8','Planning 9','Planning 10'};

    target.nElectrodes=10;

    target.FirstSecond=5;

    target.SecondLast=5;

    target.framePosition='Anterior';
    target.frameDown=0;

    [handles.project.targets, l] = addArray(handles.project.targets, target);

    out.targets = handles.project.targets;
    out.index   = l;
end

function target = chain(target)
    target = originalUpdateTarget(target);
    target = originalEstimateAnglesFrame(target);
end

function target = originalUpdateTarget(target)
    handles.project.targets = {target};
    l = 1;
    target = handles.project.targets{l};

    xi = [target.targetIn.x  target.targetIn.y  target.targetIn.z];
    xo = [target.targetOut.x target.targetOut.y target.targetOut.z];

    trajectory = depthTrajectory(xi, xo, target.nElectrodes, ...
                                 target.FirstSecond, target.SecondLast);

    handles.project.targets{l}.delta     = trajectory.delta;
    handles.project.targets{l}.azimut    = trajectory.azimuth;
    handles.project.targets{l}.elevation = trajectory.elevation;
    handles.project.targets{l}.distances = trajectory.distances;
    handles.project.targets{l}.x = trajectory.coordinates(:,1);
    handles.project.targets{l}.y = trajectory.coordinates(:,2);
    handles.project.targets{l}.z = trajectory.coordinates(:,3);

    target = handles.project.targets{l};
end

function target = originalEstimateAnglesFrame(target)
    handles.project.targets = {target};
    l = 1;

    delta=handles.project.targets{l}.delta;

    target = handles.project.targets{l};
    [alpha, beta, frameDown] = trajectoryFrameAngles(delta, target.z(target.nElectrodes), ...
                                                     target.framePosition);
    handles.project.targets{l}.frameDown = frameDown;

    handles.project.targets{l}.beta=beta;
    handles.project.targets{l}.alpha=alpha;

    target = handles.project.targets{l};
end

% ---------------------------------------------------------------------
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
