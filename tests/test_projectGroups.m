function ok = test_projectGroups()
%TEST_PROJECTGROUPS  Do the three groups survive the trip to a file and back?
%
%   ok = test_projectGroups() checks LIFTTOPROJECT, LIFTTOWORK, LIFTTOUI and
%   FLATTENPROJECT together, on examples/exampleNativeSpace.iel. No figure is
%   opened.
%
%   The in-memory layout is three sub-structs - project, work, ui - and the
%   .iel file is flat. Saving therefore flattens and loading lifts, and this
%   test follows a real project once round that loop:
%
%       file  ->  checkProjectStructure  ->  flat
%             ->  liftToProject/Work/Ui  ->  grouped
%             ->  flattenProject         ->  flat again
%             ->  checkProjectStructure  ->  what would be written
%
%   and requires the last step to equal the first.
%
%   The case worth having a test for is the three colour caches. They are
%   presentation data and live in handles.ui, but the file carries them and
%   iElectrodes 1.020 refuses to open a project whose AnnotColor_R is
%   missing. FLATTENPROJECT therefore COPIES them out of ui when saving
%   rather than moving them. A refactoring that quietly turned that copy into
%   a move would write files that older versions cannot open - and nothing
%   would look wrong until someone tried.
%
%   Usage:  cd into the repository, then
%              test_projectGroups
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also FLATTENPROJECT, LIFTTOUI, UIFIELDNAMES, ROUNDTRIP_PROJECT.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

ielFile = fullfile(repoRoot,'examples','exampleNativeSpace.iel');
loaded  = load(ielFile,'-mat');
flatIn  = checkProjectStructure(loaded.s);

nFail = 0;

%% lift
grouped = liftToProject(flatIn);
grouped = liftToWork(grouped);
grouped = liftToUi(grouped);

fprintf('\n--- lifting ---------------------------------------------------\n');
nFail = nFail + check(isfield(grouped,'project') && isfield(grouped,'work') ...
                      && isfield(grouped,'ui'), 'all three groups exist', '');

nFail = nFail + checkGroup('project', projectFieldNames(), grouped, flatIn);
nFail = nFail + checkGroup('work',    workFieldNames(),    grouped, flatIn);
nFail = nFail + checkGroup('ui',      uiFieldNames(),      grouped, flatIn);

leftFlat = {};
for g = {'project','work','ui'}
    names = feval([g{1} 'FieldNames']);
    for k = 1:numel(names)
        if isfield(grouped, names{k}), leftFlat{end+1} = names{k}; end %#ok<AGROW>
    end
end
nFail = nFail + check(isempty(leftFlat), 'nothing is left at the top level', ...
    strjoin(leftFlat, ' '));

%% flatten
fprintf('\n--- flattening ------------------------------------------------\n');
flatOut = flattenProject(grouped);

nFail = nFail + check(~isfield(flatOut,'project') && ~isfield(flatOut,'work'), ...
    'project and work are moved out', '');
nFail = nFail + check(isfield(flatOut,'ui'), ...
    'ui stays - it holds graphics the file never gets', '');

uiNames = uiFieldNames();
for k = 1:numel(uiNames)
    thisField = uiNames{k};
    inFlat = isfield(flatOut, thisField);
    inUi   = isfield(flatOut.ui, thisField);
    nFail = nFail + check(inFlat && inUi, ...
        sprintf('%s is copied, not moved', thisField), '');
end

%% what would actually be written to the file
fprintf('\n--- the .iel that would be written ----------------------------\n');
written = checkProjectStructure(flatOut);

fields = [projectFieldNames(), workFieldNames(), uiFieldNames()];
differing = {};
for k = 1:numel(fields)
    thisField = fields{k};
    if ~isfield(flatIn, thisField) || ~isfield(written, thisField), continue, end
    if ~isequaln(flatIn.(thisField), written.(thisField))
        differing{end+1} = thisField; %#ok<AGROW>
    end
end
nFail = nFail + check(isempty(differing), ...
    sprintf('%d fields identical to the source', numel(fields)), ...
    strjoin(differing, ' '));

for k = 1:numel(uiNames)
    thisField = uiNames{k};
    nFail = nFail + check(isfield(written, thisField), ...
        sprintf('%s reaches the file', thisField), ...
        sizeOf(written, thisField));
end

nFail = nFail + check(isfield(written,'AnnotColor_R') && ~isempty(written.AnnotColor_R), ...
    'AnnotColor_R is not empty - 1.020 can open this', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the three groups round-trip through the flat file format.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function bad = checkGroup(groupName, names, grouped, flatIn)
missing = {};
wrong   = {};
for k = 1:numel(names)
    thisField = names{k};
    if ~isfield(flatIn, thisField), continue, end   % not in this project
    if ~isfield(grouped.(groupName), thisField)
        missing{end+1} = thisField; %#ok<AGROW>
    elseif ~isequaln(grouped.(groupName).(thisField), flatIn.(thisField))
        wrong{end+1} = thisField;   %#ok<AGROW>
    end
end
bad = check(isempty(missing) && isempty(wrong), ...
    sprintf('%s holds its %d fields, unchanged', groupName, numel(names)), ...
    strjoin([missing wrong], ' '));
end

% ---------------------------------------------------------------------
function s = sizeOf(st, name)
v = st.(name);
if isempty(v), s = '(empty)'; else, s = mat2str(size(v)); end
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-50s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-50s %s\n', what, detail);  bad = 1;
end
end
