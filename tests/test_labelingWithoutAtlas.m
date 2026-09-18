function ok = test_labelingWithoutAtlas()
%TEST_LABELINGWITHOUTATLAS  Check native labelling when no parcellation is loaded.
%
%   ok = test_labelingWithoutAtlas() runs LABELELECTRODESNATIVE on a project
%   whose parcellation has been removed, so that the branch which fills in
%   'no atlas loaded' placeholders actually runs. No figure is opened.
%
%   That branch had never run. It looped over `prj.electrodes{l}.projection`
%   while writing into `prj.targets{l}`, and asked for a field `ntargets`
%   that is not assigned anywhere in the toolbox - so it raised an error the
%   moment it was reached, rather than filling in the placeholders it was
%   written to fill. Both are fixed; this test is what stops them coming back.
%
%   A project with no parcellation is the ordinary state of a new project:
%   the MRI and CT are loaded before the FreeSurfer output is. So this is not
%   an exotic case, it is the first few minutes of every session.
%
%   Usage:  cd into the repository, then
%              test_labelingWithoutAtlas
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also LABELELECTRODESNATIVE, COMPARE_LABELINGBASELINE.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

ielFile = fullfile(repoRoot,'examples','exampleNativeSpace.iel');
loaded  = load(ielFile,'-mat');
prj     = checkProjectStructure(loaded.s);
prj.options = default_ielectrodes_options([]);   % as the GUI supplies them

% the case under test: a project that has no parcellation
prj.wmparc  = [];
prj.wmparcS = [];

fprintf('\n   %d electrode arrays, %d planning arrays, no parcellation\n', ...
    numel(prj.electrodes), numel(prj.targets));

nFail = 0;

%% it has to run at all
fprintf('\n--- it completes ---------------------------------------------\n');
threw = '';
try
    labelled = labelElectrodesNative(prj);
catch err
    threw = err.message;
end
nFail = nFail + check(isempty(threw), 'no error', threw);

if ~isempty(threw)
    fprintf('\nFAIL - the no-atlas branch still raises an error.\n\n');
    ok = false; if nargout == 0, clear ok; end, return
end

%% the placeholders
fprintf('\n--- placeholders are filled in -------------------------------\n');

nFail = nFail + check(numel(labelled.electrodes) == numel(prj.electrodes), ...
    'every electrode array comes back', '');
nFail = nFail + check(numel(labelled.targets) == numel(prj.targets), ...
    'every planning array comes back', '');

nFail = nFail + checkPlaceholders('electrode', labelled.electrodes);
nFail = nFail + checkPlaceholders('planning',  labelled.targets);

%% the two bugs, named
fprintf('\n--- the two bugs this branch had -----------------------------\n');

% the loop bound used to come from electrodes{l} while writing into
% targets{l}, so with more planning arrays than electrode arrays it errored,
% and otherwise it filled the wrong number of entries
wrongCount = 0;
for l = 1:numel(labelled.targets)
    t = labelled.targets{l};
    if ~isfield(t,'projection') || isempty(t.projection), continue, end
    for p = 1:numel(t.projection)
        if isfield(t.projection{p},'aLabels') && ...
                numel(t.projection{p}.aLabels) ~= t.nElectrodes
            wrongCount = wrongCount + 1;
        end
    end
end
nFail = nFail + check(wrongCount == 0, ...
    'each projection gets one label per contact', ...
    sprintf('%d planning arrays', numel(labelled.targets)));

if numel(prj.targets) > numel(prj.electrodes)
    fprintf('  note      %d planning arrays against %d electrode arrays - the old\n', ...
        numel(prj.targets), numel(prj.electrodes));
    fprintf('            loop bound would have run off the end of electrodes{}\n');
end

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - labelling without an atlas fills in placeholders.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function bad = checkPlaceholders(what, arrays)
bad = 0;
wrong = 0;
for l = 1:numel(arrays)
    a = arrays{l};
    if ~isfield(a,'aLabels') || numel(a.aLabels) ~= a.nElectrodes
        wrong = wrong + 1;
        continue
    end
    for i = 1:numel(a.aLabels)
        if ~strcmp(a.aLabels{i}, 'no atlas loaded'), wrong = wrong + 1; break, end
    end
end
bad = bad + check(wrong == 0, ...
    sprintf('every %s contact says "no atlas loaded"', what), ...
    sprintf('%d arrays', numel(arrays)));
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-46s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-46s %s\n', what, detail);  bad = 1;
end
end
