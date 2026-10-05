function ok = test_ielecImportLabels()
%TEST_IELECIMPORTLABELS  Check ielec.importLabels and readContactLabels.
%
%   ok = test_ielecImportLabels() writes a list of contact labels in four of
%   the five formats the label dialog offers, reads each one back through the
%   layer, and compares it with the switch the dialog ran itself, kept
%   verbatim below.
%
%   The fifth format, EDF, is not covered: it needs a real EDF header, which
%   is a binary layout this test would have to reproduce byte by byte to say
%   anything about. READEDFHEADER is unchanged by this commit.
%
%   Usage:  cd into the repository, then
%              test_ielecImportLabels
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.IMPORTLABELS, READCONTACTLABELS, IMPORTTXTLABELS.

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
project.elecListLabels = {};        % a project that has no list yet

outFolder = tempname;
mkdir(outFolder);
cleanup = onCleanup(@() removeFolder(outFolder)); %#ok<NASGU>

wanted = {'LA1', 'LA2', 'LA3', 'LB1', 'LB2'};

files.txt             = fullfile(outFolder, 'channels.txt');
files.matlab          = fullfile(outFolder, 'labels.mat');
files.eeglab          = fullfile(outFolder, 'dataset.set');
files.fieldtripHeader = fullfile(outFolder, 'hdr.mat');

writeTxtList(files.txt, wanted);

labels = wanted(:);                                             %#ok<NASGU>
save(files.matlab, 'labels');

for i = 1:numel(wanted), EEG.chanlocs(i).labels = wanted{i}; end
save(files.eeglab, 'EEG', '-mat');

hdr.label = wanted(:);                                          %#ok<STRNU>
save(files.fieldtripHeader, 'hdr');

%% -------------------------------------------------- every format, both ways
fprintf('\n--- ielec.importLabels against the dialog''s own reading -------\n');

for f = {'txt', 'matlab', 'eeglab', 'fieldtripHeader'}
    format = f{1};

    expected = originalRead(files.(format), formatIndex(format));

    cfg = [];
    cfg.file   = files.(format);
    cfg.format = format;
    [after, afterWork, got] = ielec.importLabels(cfg, project, work);

    nFail = nFail + check(isequal(got, expected), ...
        sprintf('%s: the labels the dialog read', format), ...
        sprintf('%d labels', numel(got)));
    nFail = nFail + check(isequal(after.elecListLabels, expected), ...
        '   and they are the project''s list now', '');
    nFail = nFail + check(isequaln(afterWork, work) && ...
            isequaln(rmfield(after, 'elecListLabels'), rmfield(project, 'elecListLabels')), ...
        '   work, and the rest of the project, are not changed', '');
end

%% ------------------------------------------------------- an empty result
fprintf('\n--- a file with nothing in it --------------------------------\n');

empty = fullfile(outFolder, 'empty.txt');
writeTxtList(empty, {});

withList = project;
withList.elecListLabels = wanted;
[kept, ~, none] = ielec.importLabels(struct('file', empty, 'format', 'txt'), withList, work);
nFail = nFail + check(isempty(none) && isequal(kept.elecListLabels, wanted), ...
    'the list the project already had is left alone', '');

%% -------------------------------------------------------------- what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

nFail = nFail + check(strcmp(errorId(@() ielec.importLabels(...
        struct('file', files.txt, 'format', 'csv'), project, work)), 'ielec:badOption'), ...
    'a format the dialog never offered', '');
nFail = nFail + check(strcmp(errorId(@() ielec.importLabels(struct('format', 'txt'), ...
                                                             project, work)), 'ielec:missingOption'), ...
    'a call that does not say which file', 'cfg.file');
nFail = nFail + check(strcmp(errorId(@() ielec.importLabels(...
        struct('file', files.txt, 'format', 'txt', 'arrays', 1), project, work)), ...
        'ielec:unknownOption'), 'an unknown option is refused', 'cfg.arrays');

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.importLabels) == 3 && ...
        nargout(@ielec.importLabels) == 3, ...
    'the signature, the labels as the third output', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened - not even by the reader', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the label list is what the dialog loaded.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% The switch getLabelsFromFile ran once the user had chosen a file, with the
% filter index the dialog returned.

function labels = originalRead(fullPath, filterindex)
    labels={};
    [PathName, name, extension] = fileparts(fullPath);
    labelsFile = [name extension];
    PathName   = [PathName filesep];

    switch filterindex
        case 1 %load channels in a txt file
            labels = importTxtLabels([PathName labelsFile]);
        case 2 %MATLAB labels cell array
            s=load([PathName labelsFile]);
            labels=s.labels;

        case 3 %EEGLAB
            s=load('-mat',[PathName labelsFile]);
            labels={s.EEG.chanlocs.labels};

        case 4 %Fieldtrip (ft_readheader output)
            s=load('-mat',[PathName labelsFile]);
            labels=s.hdr.label;

        case 5
            header=readEdfHeader([PathName labelsFile]);
            labels=cellstr(header.channelname);
        otherwise
            disp('File format not supported');
    end
end

% ---------------------------------------------------------------------
function index = formatIndex(format)
index = find(strcmp(format, {'txt', 'matlab', 'eeglab', 'fieldtripHeader', 'edf'}));
end

function writeTxtList(file, labels)
% the tab delimited list importTxtLabels reads
fid = fopen(file, 'w');
fprintf(fid, '%s\n', labels{:});
fclose(fid);
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
