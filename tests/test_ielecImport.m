function ok = test_ielecImport()
%TEST_IELECIMPORT  Check ielec.arrayFileContents and ielec.importArrays.
%
%   ok = test_ielecImport() writes the example project out in the formats
%   iElectrodes can read back, then imports each one twice: once with the
%   code the import button ran itself, kept verbatim below, and once through
%   the layer. The project has to end up the same either way.
%
%   The EEGLAB dataset is made here rather than exported, because the toolbox
%   writes EEGLAB coordinates as text and reads them back from a .set.
%
%   Everything is written into a temporary folder, which is removed again.
%
%   Usage:  cd into the repository, then
%              test_ielecImport
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.IMPORTARRAYS, IELEC.ARRAYFILECONTENTS, GROUPCONTACTSBYARRAY.

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

outFolder = tempname;
mkdir(outFolder);
cleanup = onCleanup(@() removeFolder(outFolder)); %#ok<NASGU>

%% ------------------------------------------------------------ the files
files.structure = fullfile(outFolder, 'electrodes.mat');
files.fieldtrip = fullfile(outFolder, 'elec.mat');
files.eeglab    = fullfile(outFolder, 'dataset.set');

ielec.export(struct('file', files.structure, 'format', 'structure'), project, work);
ielec.export(struct('file', files.fieldtrip, 'format', 'fieldtrip'), project, work);
writeFakeEEGLABdataset(project, files.eeglab);

%% -------------------------------------------- what the layer says is in them
fprintf('\n--- ielec.arrayFileContents against the button''s own reading --\n');

for f = {'structure', 'fieldtrip', 'eeglab'}
    format = f{1};
    expected = originalContents(files.(format), format);

    [same, sameWork, contents] = ielec.arrayFileContents(...
            struct('file', files.(format), 'format', format), project, work);

    nFail = nFail + check(isequal(contents.arrays, expected.arrays) && ...
            isequal(contents.contacts(:)', expected.contacts(:)'), ...
        sprintf('%s: the arrays in the file', format), ...
        sprintf('%s (%d contacts)', strjoin(contents.arrays, ' '), contents.total));
    nFail = nFail + check(contents.needsChoices == ~strcmp(format, 'structure'), ...
        '   and whether it says what kind they are', '');
    nFail = nFail + check(isequaln(same, project) && isequaln(sameWork, work), ...
        '   it only reports: project and work come back untouched', '');
end

%% ------------------------------------------------------- and the import
fprintf('\n--- ielec.importArrays against the import button --------------\n');

for f = {'structure', 'fieldtrip', 'eeglab'}
    format = f{1};

    cfg = [];
    cfg.file   = files.(format);
    cfg.format = format;
    if ~strcmp(format, 'structure')
        % what the dialog would have answered: one row, as many columns as
        % the array has contacts
        info = originalContents(files.(format), format);
        for k = 1:numel(info.arrays)
            cfg.arrays(k).type    = 'depth';
            cfg.arrays(k).rows    = 1;
            cfg.arrays(k).columns = info.contacts(k);
        end
    end

    expected = originalImport(project, files.(format), format, ...
                              choicesOf(cfg, format));
    [imported, importedWork, added] = ielec.importArrays(cfg, project, work);

    nFail = nFail + check(isequaln(imported.electrodes, expected.electrodes), ...
        sprintf('%s: the arrays are what the button appended', format), ...
        sprintf('%d added', numel(added)));
    nFail = nFail + check(isequal(added, numel(project.electrodes) + ...
            (1:numel(imported.electrodes) - numel(project.electrodes))), ...
        '   and they went to the end, as importing always did', '');
    nFail = nFail + check(isequaln(importedWork, work), ...
        '   work is not changed', '');
    nFail = nFail + check(isequaln(rmfield(imported, 'electrodes'), ...
            rmfield(project, 'electrodes')), ...
        '   and nothing else in the project is', '');
end

%% -------------------------------------------------------------- what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

nFail = nFail + check(strcmp(errorId(@() ielec.importArrays(...
        struct('file', files.eeglab, 'format', 'eeglab'), project, work)), 'ielec:missingOption'), ...
    'a flat list with nothing said about the arrays', 'cfg.arrays');

one.type = 'depth'; one.rows = 1; one.columns = 1;
nFail = nFail + check(strcmp(errorId(@() ielec.importArrays(...
        struct('file', files.eeglab, 'format', 'eeglab', 'arrays', one), project, work)), ...
        'ielec:badArrays'), 'fewer answers than there are arrays', '');

nFail = nFail + check(strcmp(errorId(@() ielec.importArrays(...
        struct('file', files.structure, 'format', 'structure', 'arrays', one), project, ...
        work)), ...
        'ielec:badOption'), 'answers for a file that carries complete arrays', '');

nFail = nFail + check(strcmp(errorId(@() ielec.importArrays(...
        struct('file', files.structure, 'format', 'bids'), project, work)), 'ielec:badOption'), ...
    'a format that cannot be read back', '');

% the layout the import dialog would not have allowed: rows times columns
% has to account for every contact of that array
wrongLayout = originalContents(files.eeglab, 'eeglab');
for k = 1:numel(wrongLayout.arrays)
    layout(k).type    = 'depth'; %#ok<AGROW>
    layout(k).rows    = 1;       %#ok<AGROW>
    layout(k).columns = wrongLayout.contacts(k); %#ok<AGROW>
end
layout(1).columns = layout(1).columns + 1;
nFail = nFail + check(strcmp(errorId(@() ielec.importArrays(...
        struct('file', files.eeglab, 'format', 'eeglab', 'arrays', layout), project, work)), ...
        'ielec:badArrays'), 'a layout that leaves a contact out', '');
nFail = nFail + check(strcmp(errorId(@() ielec.arrayFileContents(...
        struct('format', 'structure'), project, work)), 'ielec:missingOption'), ...
    'a call that does not say which file', 'cfg.file');
nFail = nFail + check(strcmp(errorId(@() ielec.arrayFileContents(...
        struct('file', files.structure, 'format', 'structure', 'arrays', one), project, ...
        work)), ...
        'ielec:unknownOption'), 'an unknown option is refused', 'cfg.arrays');

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.importArrays) == 3 && ...
        nargout(@ielec.importArrays) == 3 && ...
        nargin(@ielec.arrayFileContents) == 3 && ...
        nargout(@ielec.arrayFileContents) == 3, ...
    'the signatures, the report as the third output', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - importing puts in the project what the button put in it.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% What the import button did: read the file, and for the two flat formats
% group the contacts by array and build one array per group.

function out = originalContents(file, format)
    switch format
        case 'structure'
            electrodes = readElectrodeStructure(file);
            out.arrays   = cellfun(@(e) e.Name, electrodes, 'UniformOutput', false);
            out.contacts = cellfun(@(e) numel(e.x), electrodes);
        case 'eeglab'
            labels = readEEGLABelectrodes(file);
            [out.arrays, ic] = groupContactsByArray(labels);
            out.contacts = arrayfun(@(k) sum(ic == k), 1:numel(out.arrays));
        case 'fieldtrip'
            labels = readFieldTripElectrodes(file);
            [out.arrays, ic] = groupContactsByArray(labels);
            out.contacts = arrayfun(@(k) sum(ic == k), 1:numel(out.arrays));
    end
end

function project = originalImport(project, file, format, choices)
    switch format
        case 'structure'
            elecNew = readElectrodeStructure(file);
        case 'eeglab'
            [labels,pos] = readEEGLABelectrodes(file);
        case 'fieldtrip'
            [labels,pos] = readFieldTripElectrodes(file);
    end

    if ~strcmp(format, 'structure')
        [labelsArray, ic] = groupContactsByArray(labels); % ic==i: the contacts of array labelsArray{i}
        A=length(labelsArray);
        for i=1:A
            type = choices(i).type; rows = choices(i).rows; columns = choices(i).columns;
            elecNew{i} = electrodeArrayFromContacts(labelsArray{i}, labels(ic==i), ...
                                                    pos(ic==i,:), type, rows, columns);
        end
    end

    project.electrodes=[project.electrodes elecNew]; %append new elecs to old ones
end

% ---------------------------------------------------------------------
function choices = choicesOf(cfg, format)
if strcmp(format, 'structure'), choices = []; else, choices = cfg.arrays; end
end

function writeFakeEEGLABdataset(project, file)
% an EEGLAB .set is a MATLAB file holding EEG; only its chanlocs are read.
% The coordinates are written in EEGLAB's own axes, which the reader undoes.
labels = {};
xyz    = [];
for k = 1:numel(project.electrodes)
    e = project.electrodes{k};
    labels = [labels; e.ch_label(:)];          %#ok<AGROW>
    xyz    = [xyz; [e.x(:) e.y(:) e.z(:)]];    %#ok<AGROW>
end
for i = 1:numel(labels)
    EEG.chanlocs(i).labels = labels{i};
    EEG.chanlocs(i).X      =  xyz(i,2);
    EEG.chanlocs(i).Y      = -xyz(i,1);
    EEG.chanlocs(i).Z      =  xyz(i,3);
end
save(file, 'EEG', '-mat');
end

function removeFolder(folder)
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
