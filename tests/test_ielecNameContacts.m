function ok = test_ielecNameContacts()
%TEST_IELECNAMECONTACTS  Check ielec.nameContacts against the two Label buttons.
%
%   ok = test_ielecNameContacts() names an array of the example project both
%   ways - numbered from a base name, and from a list of recording channel
%   names - and compares the result with the one call each button made,
%   kept verbatim at the end of this file.
%
%   Usage:  cd into the repository, then
%              test_ielecNameContacts
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.NAMECONTACTS, NAMEARRAYCONTACTS, APPLYCONTACTLABELS.

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
[project, work] = ielec.openProject([], [], cfgOpen);

which1 = 1;
n      = project.electrodes{which1}.nElectrodes;

%% ------------------------------------------------- numbered from a base name
fprintf('\n--- ielec.nameContacts against the Label button ---------------\n');

expected = originalAuto(project, which1, 'LTG');

cfg = [];
cfg.index    = which1;
cfg.baseName = 'LTG';
[named, namedWork] = ielec.nameContacts(project, work, cfg);

nFail = nFail + check(isequaln(named, expected.project), ...
    'the array and its contacts are named as the button named them', ...
    sprintf('%s ... %s', named.electrodes{which1}.ch_label{1}, ...
            named.electrodes{which1}.ch_label{end}));
nFail = nFail + check(strcmp(named.electrodes{which1}.Name, 'LTG') && ...
        numel(named.electrodes{which1}.ch_label) == n, ...
    'the array takes the name, and every contact one', ...
    sprintf('%d contacts', n));
nFail = nFail + check(isequaln(namedWork, work), ...
    'work is not changed', '');
nFail = nFail + check(isequaln(rmfield(named, 'electrodes'), ...
        rmfield(project, 'electrodes')), ...
    'and nothing else in the project is', '');
others = 1:numel(project.electrodes);  others(others == which1) = [];
nFail = nFail + check(isequaln(project.electrodes(others), ...
        named.electrodes(others)), ...
    'no other array is touched', sprintf('%d others', numel(others)));

% an empty box: the contacts are numbered without a prefix, as before
expected = originalAuto(project, which1, '');
plain    = ielec.nameContacts(project, work, ...
    struct('index', which1, 'baseName', ''));
nFail = nFail + check(isequaln(plain, expected.project) && ...
        strcmp(plain.electrodes{which1}.ch_label{1}, '1'), ...
    'an empty name numbers the contacts and nothing more', ...
    sprintf('''%s'', ''%s'', ...', plain.electrodes{which1}.ch_label{1}, ...
            plain.electrodes{which1}.ch_label{2}));

%% --------------------------------------------------- from a list of channels
fprintf('\n--- and against the Label from list button -------------------\n');

fromRecording = arrayfun(@(k) sprintf('EEG %d', k), 1:n, 'UniformOutput', false);
expected      = originalFromList(project, which1, fromRecording, 'LTG');

cfg = [];
cfg.index    = which1;
cfg.baseName = 'LTG';
cfg.labels   = fromRecording;
[fromList, fromListWork] = ielec.nameContacts(project, work, cfg);

nFail = nFail + check(isequaln(fromList, expected.project), ...
    'the contacts take the list, as the button gave it to them', ...
    sprintf('%s ... %s', fromList.electrodes{which1}.ch_label{1}, ...
            fromList.electrodes{which1}.ch_label{end}));
nFail = nFail + check(isequal(fromList.electrodes{which1}.ch_label(:)', ...
        fromRecording), ...
    'in the order they were given, one per contact', '');
nFail = nFail + check(isequaln(fromListWork, work), ...
    'work is not changed', '');

% no base name with a list: the array keeps the name it had
expected = originalFromList(project, which1, fromRecording, '');
keptName = ielec.nameContacts(project, work, ...
    struct('index', which1, 'labels', {fromRecording}));
nFail = nFail + check(isequaln(keptName, expected.project) && ...
        ~isempty(project.electrodes{which1}.Name) && ...
        strcmp(keptName.electrodes{which1}.Name, ...
               project.electrodes{which1}.Name), ...
    'and with no base name the array keeps its own', ...
    project.electrodes{which1}.Name);

% the selection window may hand its labels back as a column
asColumn = ielec.nameContacts(project, work, ...
    struct('index', which1, 'baseName', 'LTG', 'labels', {fromRecording(:)}));
nFail = nFail + check(isequaln(asColumn, fromList), ...
    'a column of labels is the same as a row', '');

% and a .mat of labels may hold strings rather than character vectors
asStrings = ielec.nameContacts(project, work, ...
    struct('index', which1, 'baseName', 'LTG', ...
           'labels', {cellfun(@string, fromRecording, 'UniformOutput', false)}));
nFail = nFail + check(isequaln(asStrings, fromList), ...
    'and strings become character vectors, as the project holds them', ...
    class(asStrings.electrodes{which1}.ch_label{1}));

%% -------------------------------------------------------------- what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

nFail = nFail + check(strcmp(errorId(@() ielec.nameContacts(project, work, ...
        struct('baseName', 'LTG'))), 'ielec:missingOption'), ...
    'a call that does not say which array', 'cfg.index');
nFail = nFail + check(strcmp(errorId(@() ielec.nameContacts(project, work, ...
        struct('index', numel(project.electrodes) + 1, 'baseName', 'LTG'))), ...
        'ielec:badOption'), ...
    'an array that is not in the project', 'cfg.index');
nFail = nFail + check(strcmp(errorId(@() ielec.nameContacts(project, work, ...
        struct('index', which1, 'labels', {fromRecording(1:end-1)}))), ...
        'ielec:badOption'), ...
    'one label short of the contacts', sprintf('%d for %d', n-1, n));
nFail = nFail + check(strcmp(errorId(@() ielec.nameContacts(project, work, ...
        struct('index', which1, 'labels', {num2cell(1:n)}))), 'ielec:badOption'), ...
    'labels that are numbers rather than text', '');
nFail = nFail + check(strcmp(errorId(@() ielec.nameContacts(project, work, ...
        struct('index', which1, 'baseName', 42))), 'ielec:badOption'), ...
    'a name that is not text', 'cfg.baseName');
nFail = nFail + check(strcmp(errorId(@() ielec.nameContacts(project, work, ...
        struct('index', which1, 'name', 'LTG'))), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.name');

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.nameContacts) == 3 && ...
        nargout(@ielec.nameContacts) == 2, ...
    'the signature, and nothing else comes out', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the contacts are named as the buttons named them.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% The one line each Label button ran once it had its answer.

function out = originalAuto(project, l, elecBaseName)
    handles.project = project;

    handles.project.electrodes{l} = ...
        nameArrayContacts(handles.project.electrodes{l}, elecBaseName);

    out.project = handles.project;
end

function out = originalFromList(project, l, right, elecBaseName)
    handles.project = project;

    handles.project.electrodes{l} = ...
        applyContactLabels(handles.project.electrodes{l}, right, elecBaseName);

    out.project = handles.project;
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
