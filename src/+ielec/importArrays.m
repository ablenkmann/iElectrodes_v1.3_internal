function [project, work, added] = importArrays(project, work, cfg)
%IELEC.IMPORTARRAYS  Read arrays from another format into the project.
%
%   [project, work, added] = ielec.importArrays(project, work, cfg) reads a
%   file of electrodes and appends what it holds to project.electrodes.
%   ADDED is the index of each array that was added. WORK is not changed.
%
%   Options (cfg):
%     cfg.file     the file to read. Full path. Required.
%     cfg.format   'structure' (an iElectrodes .mat), 'eeglab' (a .set) or
%                  'fieldtrip' (an elec structure). Required.
%     cfg.arrays   what kind of array each one is, for the formats that do
%                  not say: a struct per array, in the order
%                  IELEC.ARRAYFILECONTENTS reported them, with the fields
%                     .type      'grid', 'strip' or 'depth'
%                     .rows      rows in the array
%                     .columns   columns in the array
%                  Required for 'eeglab' and 'fieldtrip', refused for
%                  'structure', which carries complete arrays already.
%
%   An EEGLAB or FieldTrip file is a flat list of labelled points. Which
%   array a contact belongs to is read from its label (GROUPCONTACTSBYARRAY);
%   what kind of array that is cannot be, so it is asked - by the frontend,
%   which puts the answers in cfg.arrays.
%
%   The arrays are appended, as importing always did: nothing in the project
%   is replaced, and the labelling is a step of its own (IELEC.LABEL).
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:missingOption (cfg.arrays for a format that needs it),
%   ielec:badOption, ielec:badArrays (one entry per array in the file, each
%   with a type that exists and rows times columns equal to that array's
%   number of contacts - the same arithmetic the import dialog insisted on),
%   and whatever the reader raises about the file.
%
%   Example
%       cfg = [];
%       cfg.file   = fullfile(folder, 'electrodes.mat');
%       cfg.format = 'structure';
%       [project, work, added] = ielec.importArrays(project, work, cfg);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.ARRAYFILECONTENTS, ELECTRODEARRAYFROMCONTACTS, IELEC.LABEL.

cfg = checkCfg(cfg, struct('arrays', []), {'file', 'format'}, 'importArrays');
checkFileAndFormat(cfg, 'importArrays');

if strcmp(cfg.format, 'structure')
    if ~isempty(cfg.arrays)
        error('ielec:badOption', ...
            ['ielec.importArrays: an iElectrodes .mat holds complete arrays, ' ...
             'so cfg.arrays has nothing to say about it.']);
    end
    newArrays = readElectrodeStructure(cfg.file);
else
    if strcmp(cfg.format, 'eeglab')
        [labels, positions] = readEEGLABelectrodes(cfg.file);
    else
        [labels, positions] = readFieldTripElectrodes(cfg.file);
    end

    [names, index] = groupContactsByArray(labels);
    counts  = arrayfun(@(k) sum(index == k), 1:numel(names));
    choices = checkChoices(cfg.arrays, names, counts);

    newArrays = cell(1, numel(names));
    for k = 1:numel(names)
        newArrays{k} = electrodeArrayFromContacts(names{k}, labels(index == k), ...
            positions(index == k, :), choices(k).type, ...
            choices(k).rows, choices(k).columns);
    end
end

before = numel(fieldOr(project, 'electrodes', {}));
project.electrodes = [fieldOr(project, 'electrodes', {}) newArrays];
added = before + (1:numel(newArrays));
end

% ---------------------------------------------------------------------
function choices = checkChoices(choices, names, counts)
% one answer per array in the file, each saying what kind of array it is and
% how it is laid out. The import dialog would not let the user past a layout
% that does not account for every contact, so neither does this.
if isempty(choices)
    error('ielec:missingOption', ...
        ['ielec.importArrays: this format does not say what kind of array ' ...
         'each one is, so cfg.arrays must say it - one entry per array, in ' ...
         'the order ielec.arrayFileContents reports them (%s).'], ...
        strjoin(names, ', '));
end
if ~isstruct(choices) || numel(choices) ~= numel(names) || ...
        ~all(isfield(choices, {'type', 'rows', 'columns'}))
    error('ielec:badArrays', ...
        ['ielec.importArrays: cfg.arrays must have one entry per array in ' ...
         'the file - %d of them - each with .type, .rows and .columns.'], ...
        numel(names));
end
for k = 1:numel(choices)
    if ~ischar(choices(k).type) || ...
            ~ismember(choices(k).type, {'grid', 'strip', 'depth'})
        error('ielec:badArrays', ...
            'ielec.importArrays: cfg.arrays(%d).type must be grid, strip or depth.', k);
    end
    if ~wholeNumber(choices(k).rows) || ~wholeNumber(choices(k).columns)
        error('ielec:badArrays', ...
            'ielec.importArrays: cfg.arrays(%d).rows and .columns must be whole numbers.', k);
    end
    if choices(k).rows * choices(k).columns ~= counts(k)
        error('ielec:badArrays', ...
            ['ielec.importArrays: array %s has %d contacts in the file, and ' ...
             'cfg.arrays(%d) says %d x %d.'], names{k}, counts(k), k, ...
            choices(k).rows, choices(k).columns);
    end
end
end

function yes = wholeNumber(value)
yes = isnumeric(value) && isscalar(value) && isfinite(value) && ...
      value >= 1 && mod(value, 1) == 0;
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end
