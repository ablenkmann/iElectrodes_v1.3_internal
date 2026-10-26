function ok = test_ielecLabelOptions()
%TEST_IELECLABELOPTIONS  Check that what decides a label travels in cfg.
%
%   ok = test_ielecLabelOptions() checks that IELEC.LABEL and
%   IELEC.POINTLABEL take the three settings that decide an anatomical label
%   as options, fall back to the session's when they are not given, and
%   record the values that were used.
%
%   WHAT THIS IS FOR
%
%   The toolbox author, reading the design document: "cfg should carry all
%   the low-level configuration options a method needs to run. I have the
%   feeling that some of that is taken from work.options."
%
%   It was. The search radius, the mode and the minimum share decide what the
%   labels are - at radius 0 a contact gets one label, at radius 5 it gets
%   every region within 5 mm with a share each - and all three were read
%   straight out of work.options. So a caller could not set them for one run,
%   and because RECORDSTEP writes the cfg, the recorded step did not say
%   which had been used. Two runs that produced differently shaped results
%   left records that could not be told apart. work.options is not stored in
%   the .iel either, so reopening the project gave the configuration file's
%   defaults instead of the values the labels were made with.
%
%   The checks below are that measurement, turned round: the results must
%   still differ, and now the records must differ too.
%
%   See docs/OPEN_QUESTIONS.md item 51.
%
%   Usage:  cd into the repository, then
%              test_ielecLabelOptions
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.LABEL, IELEC.POINTLABEL, RESOLVELABELLING.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

ielFile = fullfile(repoRoot, 'examples', 'exampleNativeSpace.iel');
[project, work] = ielec.openProject(struct('file', ielFile), [], []);

%% ------------------------------------- the radius changes the answer
fprintf('\n--- the radius decides what the labels are -------------------\n');

[pA, wA] = ielec.label(struct('radius', 0), project, work);
[pB, wB] = ielec.label(struct('radius', 5), project, work);

labA = pA.electrodes{1}.aLabels;
labB = pB.electrodes{1}.aLabels;

nFail = nFail + check(~isequaln(labA, labB), ...
    'two radii give two different sets of labels', ...
    sprintf('%s against %s', mat2str(size(labA)), mat2str(size(labB))));
nFail = nFail + check(isequaln(wA, work) && isequaln(wB, work), ...
    'and work is not changed by either', '');

%% ------------------------------------- and the record says which was used
fprintf('\n--- and the project records which radius made them -----------\n');

sA = rmfield(pA.history{end}, 'date');
sB = rmfield(pB.history{end}, 'date');

nFail = nFail + check(~isequaln(sA, sB), ...
    'the two recorded steps can be told apart', ...
    'this is the whole point');
nFail = nFail + check(sA.cfg.radius == 0 && sB.cfg.radius == 5, ...
    'each holds the radius it was given', ...
    sprintf('%g and %g', sA.cfg.radius, sB.cfg.radius));
nFail = nFail + check(ischar(sA.cfg.mode) && ~isempty(sA.cfg.mode) && ...
    isnumeric(sA.cfg.minProbability) && ~isempty(sA.cfg.minProbability), ...
    'and the other two, filled in from the session', ...
    sprintf('mode %s, minProbability %g', sA.cfg.mode, sA.cfg.minProbability));

%% ----------------------------------------- giving nothing still works
fprintf('\n--- giving nothing still means the session''s settings --------\n');

[pC, ~] = ielec.label([], project, work);
sC = pC.history{end};

nFail = nFail + check(sC.cfg.radius == work.options.atlasLabelingRadio, ...
    'the recorded radius is the session''s', ...
    sprintf('%g', sC.cfg.radius));
nFail = nFail + check(strcmp(sC.cfg.mode, work.options.atlasLabelingMode), ...
    'and so is the mode', sC.cfg.mode);
nFail = nFail + check(isequaln(pC.electrodes{1}.aLabels, ...
    labelledAtSessionRadius(project, work)), ...
    'and the labels are the ones the session''s settings give', '');

%% --------------------------------------------- it survives the file
fprintf('\n--- and it survives being saved and opened again -------------\n');

out = fullfile(tempdir, ['iElectrodes_labelopts_' ...
    char(java.util.UUID.randomUUID) '.iel']);
removeLater = onCleanup(@() deleteIfThere(out));
ielec.saveProject(struct('file', out), pB, work);
back = ielec.openProject(struct('file', out), [], []);

nFail = nFail + check(back.history{end}.cfg.radius == 5, ...
    'the reopened project still says radius 5', ...
    'work.options does not reach the file; the history does');

%% ------------------------------------------------ pointLabel as well
fprintf('\n--- one point, asked at two radii ----------------------------\n');

here = [20 -30 40];
[~, ~, r0] = ielec.pointLabel(struct('coordinate', here, 'radius', 0), ...
    project, work);
[~, ~, r6] = ielec.pointLabel(struct('coordinate', here, 'radius', 6), ...
    project, work);

nFail = nFail + check(strcmp(r0.source, 'parcellation'), ...
    'the parcellation answers', r0.source);
nFail = nFail + check(numel(r6.label) >= numel(r0.label), ...
    'a wider radius reports at least as many regions', ...
    sprintf('%d at 0, %d at 6', numel(r0.label), numel(r6.label)));
nFail = nFail + check(~isequaln(r0.label, r6.label), ...
    'and not the same ones', '');

%% ----------------------------------------------------- what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

nFail = nFail + check(strcmp(errorId(@() ielec.label( ...
    struct('radius', -1), project, work)), 'ielec:badOption'), ...
    'a negative radius', '');
nFail = nFail + check(strcmp(errorId(@() ielec.label( ...
    struct('mode', 'probably'), project, work)), 'ielec:badOption'), ...
    'a mode that is neither', 'mode or prob');
nFail = nFail + check(strcmp(errorId(@() ielec.label( ...
    struct('minProbability', 2), project, work)), 'ielec:badOption'), ...
    'a share above one', '');
nFail = nFail + check(strcmp(errorId(@() ielec.pointLabel( ...
    struct('coordinate', here, 'radius', NaN), project, work)), ...
    'ielec:badOption'), 'a radius of NaN', '');

% the three belong to the parcellation, and MNI has no parcellation
[pM, wM] = ielec.openProject(struct('file', ...
    fullfile(repoRoot, 'examples', 'exampleMNIspace.iel')), [], []);
nFail = nFail + check(strcmp(errorId(@() ielec.label( ...
    struct('radius', 3), pM, wM)), 'ielec:badOption'), ...
    'and all three in MNI space, where there is no radius to look within', '');
% and without them the option check does not fire at all: what stops it is
% the atlas itself, which openProject does not load - it is a shared
% resource the session loads once
nFail = nFail + check(strcmp(errorId(@() ielec.label([], pM, wM)), ...
    'ielec:noAtlas'), ...
    'while MNI labelling without them gets past the check', ...
    'and fails for the reason it always did');

%% --------------------------------------------------------- layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.label) == 3 && ...
    nargout(@ielec.label) == 2, 'label keeps its signature', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - what decides a label is given to it, and recorded.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function labels = labelledAtSessionRadius(project, work)
% the same call written out with the session's values given explicitly
p = ielec.label(struct( ...
    'radius',         work.options.atlasLabelingRadio, ...
    'mode',           work.options.atlasLabelingMode, ...
    'minProbability', work.options.atlasLabelingMinProb), project, work);
labels = p.electrodes{1}.aLabels;
end

function deleteIfThere(f)
if isfile(f), delete(f); end
end

function id = errorId(f)
id = '';
try
    f();
catch err
    id = err.identifier;
end
end

function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-54s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-54s %s\n', what, detail);  bad = 1;
end
end
