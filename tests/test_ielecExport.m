function ok = test_ielecExport()
%TEST_IELECEXPORT  Check ielec.export against the export buttons' own steps.
%
%   ok = test_ielecExport() writes the example project out in every format
%   iElectrodes knows, twice: once with the code the three export buttons ran
%   themselves, kept verbatim below, and once through the layer. The two
%   files have to be the same file - and where the writer refuses, both have
%   to be refused the same way, which is what the planning report does today
%   (docs/OPEN_QUESTIONS.md item 28).
%
%   Everything is written into a temporary folder, which is removed again.
%
%   Usage:  cd into the repository, then
%              test_ielecExport
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.EXPORT, ELECTRODECOORDINATES, ALABELS2TXT_NEW.

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

outFolder = tempname;
mkdir(outFolder);
cleanup = onCleanup(@() removeFolder(outFolder)); %#ok<NASGU>

%% ------------------------------------------------- every format, both ways
fprintf('\n--- ielec.export against the export buttons -------------------\n');

cases = {
  'structure',    'contacts',   '.mat'
  'eeglab',       'contacts',   '.txt'
  'eeglab',       'projection', '.txt'
  'fieldtrip',    'contacts',   '.mat'
  'fieldtrip',    'projection', '.mat'
  'bids',         'contacts',   '.tsv'
  'bids',         'projection', '.tsv'
  'labels',       'contacts',   '.txt'
  'labels',       'projection', '.txt'
  'targetLabels', 'contacts',   '.txt'
};

for k = 1:size(cases,1)
    [format, coordinates, extension] = cases{k,:};
    if strcmp(format, 'targetLabels') && isempty(project.targets)
        fprintf('  (skipped  targetLabels - the example has no planning target)\n');
        continue
    end

    theirs = fullfile(outFolder, sprintf('button_%d%s', k, extension));
    ours   = fullfile(outFolder, sprintf('layer_%d%s',  k, extension));

    cfg = [];
    cfg.file        = ours;
    cfg.format      = format;
    cfg.coordinates = coordinates;

    % The two have to behave the same, which includes failing the same way:
    % aLabelsTargets2txt_new walks the targets as a struct array while the
    % project keeps them in a cell array, so the planning report raises the
    % same error from the button and from the layer. See
    % docs/OPEN_QUESTIONS.md item 28.
    theirError = errorId(@() originalExport(project, work, format, coordinates, theirs));
    if ~isempty(theirError)
        ourError = errorId(@() ielec.export(project, work, cfg));
        nFail = nFail + check(strcmp(theirError, ourError), ...
            sprintf('%s, %s - refused the same way', format, coordinates), theirError);
        fclose('all');   % the writer that failed left its file open
        continue
    end

    [after, afterWork, report] = ielec.export(project, work, cfg);

    nFail = nFail + check(sameFile(theirs, ours), ...
        sprintf('%s, %s', format, coordinates), ...
        sprintf('%d contacts', report.contacts));
    nFail = nFail + check(isequaln(after, project) && isequaln(afterWork, work), ...
        '   and nothing was changed by writing it', '');
    nFail = nFail + check(strcmp(report.file, ours) && ...
            strcmp(report.format, format) && ...
            strcmp(report.coordinates, coordinates) && report.contacts > 0, ...
        '   and the report says what went into the file', '');
end

% the report of a project whose contacts have no anatomical labels yet: the
% button wrote coordinates and no label columns, and never touched the flat
% list, so neither do we
bare = project;
for k = 1:numel(bare.electrodes)
    bare.electrodes{k}.aLabels = {};
end
bareFile = fullfile(outFolder, 'labels_without_labels.txt');
nFail = nFail + check(strcmp(errorId(@() ielec.export(bare, work, ...
        struct('file', bareFile, 'format', 'labels'))), ''), ...
    'a report from a project with no anatomical labels', '');

%% --------------------------------------------- the json beside the BIDS tsv
fprintf('\n--- the BIDS coordinate system json --------------------------\n');

hasCT = isfield(project, 'TAC') && isstruct(project.TAC) && ...
        isfield(project.TAC, 'vol') && isfield(project.TAC.vol, 'fname');
nFail = nFail + check(hasCT, 'the example was localized on a CT', '');

if hasCT
    for coordinates = {'contacts', 'projection'}
        theirs = fullfile(outFolder, ['button_json_' coordinates{1} '.json']);
        ours   = fullfile(outFolder, ['layer_json_'  coordinates{1} '.json']);

        originalExport(project, work, 'bidsCoordinateSystem', coordinates{1}, theirs);
        ielec.export(project, work, struct('file', ours, ...
            'format', 'bidsCoordinateSystem', 'coordinates', coordinates{1}));

        nFail = nFail + check(sameFile(theirs, ours), ...
            sprintf('the json says the same, %s', coordinates{1}), '');
    end
end

% and the one thing the button did not check: it read project.TAC.vol.fname
noCT = rmfield(project, 'TAC');
nFail = nFail + check(strcmp(errorId(@() ielec.export(noCT, work, ...
        struct('file', fullfile(outFolder,'x.json'), ...
               'format', 'bidsCoordinateSystem'))), 'ielec:noCT'), ...
    'the json without a CT to point at', '');

%% -------------------------------------------------------------- what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

empty = project;
empty.electrodes = {};
nFail = nFail + check(strcmp(errorId(@() ielec.export(empty, work, ...
        struct('file', fullfile(outFolder,'x.tsv'), 'format', 'bids'))), ...
        'ielec:noArrays'), 'a project with nothing localized', '');

noTargets = project;
noTargets.targets = {};
nFail = nFail + check(strcmp(errorId(@() ielec.export(noTargets, work, ...
        struct('file', fullfile(outFolder,'x.txt'), 'format', 'targetLabels'))), ...
        'ielec:noTargets'), 'a targets report with no target', '');

nFail = nFail + check(strcmp(errorId(@() ielec.export(project, work, ...
        struct('format', 'bids'))), 'ielec:missingOption'), ...
    'a call that does not say where to write', 'cfg.file');
nFail = nFail + check(strcmp(errorId(@() ielec.export(project, work, ...
        struct('file', fullfile(outFolder,'x'), 'format', 'excel'))), 'ielec:badOption'), ...
    'a format that does not exist', '');
nFail = nFail + check(strcmp(errorId(@() ielec.export(project, work, ...
        struct('file', fullfile(outFolder,'x'), 'format', 'bids', ...
               'coordinates', 'pial'))), 'ielec:badOption'), ...
    'coordinates that are neither', '');
nFail = nFail + check(strcmp(errorId(@() ielec.export(project, work, ...
        struct('file', fullfile(outFolder,'x'), 'format', 'bids', ...
               'space', 'MNI'))), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.space');

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.export) == 3 && nargout(@ielec.export) == 3, ...
    'the signature, the report as the third output', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - every format is the file the button wrote.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% What the two export buttons did once the user had chosen a format and a
% file: fetch the coordinates, then call the writer for that format.

function originalExport(project, work, format, coordinates, file)
    electrodes = project.electrodes;

    % the Save button fetched the flat list for the formats whose writer
    % takes it; the two report buttons never called electrodeCoordinates
    if ismember(format, {'eeglab', 'fieldtrip', 'bids', 'bidsCoordinateSystem'})
        crd = electrodeCoordinates(electrodes, coordinates);
        projMethod = crd.projectionMethod;
    end

    switch format
        case 'structure'
            writeElectrodeStructure(file, electrodes);

        case 'eeglab'
            writeEEGLABcoordinates(file, crd);

        case 'fieldtrip'
            if strcmp(coordinates, 'projection'), projected = 'Yes';
            else,                                 projected = 'No';
            end
            writeFieldTripElectrodes(file, crd, ...
                electrodes, project.currentSpace, projected);

        case 'bids'
            writeBIDSelectrodes(file, crd);

        case 'bidsCoordinateSystem'
            if strcmp(coordinates, 'projection')
                writeBIDScoordinateSystem(file, ...
                    project.TAC.vol.fname, ...                                 % point to CT file
                    projMethod{1}, ...                                         % projection?
                    ['Blenkmann et al., 2017. https://doi.org/10.3389/fninf.2017.00014; ' ...
                     'Blenkmann et al., 2023. https://doi.org/10.1101/2023.05.08.539503']);
            else
                writeBIDScoordinateSystem(file, ...
                    project.TAC.vol.fname, ...                                 % point to CT file
                    'none', ...                                                % projection?
                    'Blenkmann et al., 2017. https://doi.org/10.3389/fninf.2017.00014 ');
            end

        case 'labels'
            if strcmp(coordinates, 'projection')
                optionsList = {'Localized coordinates', 'SCE-projected coordinates'};
                aLabels2txt_new(project.electrodes, file, optionsList{2});
            else
                optionsList = {'Localized coordinates', 'SCE-projected coordinates'};
                aLabels2txt_new(project.electrodes, file, optionsList{1});
            end

        case 'targetLabels'
            aLabelsTargets2txt_new(project.targets, file);
    end
end

% ---------------------------------------------------------------------
function removeFolder(folder)
% take the temporary folder away again, even if a writer that failed left its
% file open behind it
if ~isfolder(folder), return, end
try
    rmdir(folder, 's');
catch
    fclose('all');
    try
        rmdir(folder, 's');
    catch err
        fprintf('  (could not remove %s: %s)\n', folder, err.message);
    end
end
end

function same = sameFile(a, b)
% the same file: byte for byte for a text file, variable by variable for a
% .mat, where the two were written at different moments
[~, ~, extension] = fileparts(a);
if strcmpi(extension, '.mat')
    same = isequaln(load(a), load(b));
else
    same = isequal(fileread(a), fileread(b));
end
end

function id = errorId(f)
% the identifier of the error a call raises, '' when it raises none. A few
% MATLAB errors carry no identifier, so the message stands in for it there.
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
