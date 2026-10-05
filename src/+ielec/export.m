function [project, work, report] = export(cfg, project, work)
%IELEC.EXPORT  Write the contacts out, in one of the formats iElectrodes knows.
%
%   [project, work, report] = ielec.export(cfg, project, work) writes one
%   file. Neither PROJECT nor WORK is changed - exporting is reading.
%
%   Options (cfg):
%     cfg.file         where to write. Full path. Required.
%     cfg.format       which format. Required, one of:
%
%        'structure'             the iElectrodes arrays themselves (.mat)
%        'eeglab'                EEGLAB coordinates (.txt)
%        'fieldtrip'             a FieldTrip elec structure (.mat)
%        'bids'                  BIDS electrodes (.tsv)
%        'bidsCoordinateSystem'  the json that belongs beside that .tsv
%        'labels'                the anatomical labels of every contact (.txt)
%        'targetLabels'          the same for the planning targets (.txt)
%
%     cfg.coordinates  which coordinates go in the file:
%                        'contacts'    where they were localized (default)
%                        'projection'  where they were projected to
%                      'structure' and 'targetLabels' write what they write
%                      and ignore it.
%
%   REPORT says what was written: .file, .format, .coordinates and .contacts,
%   the number of contacts in the file. A frontend can put that on screen.
%   The layer prints nothing of its own; two of the writers print a line of
%   their own ('... saved OK'), as they did when the buttons called them.
%
%   BIDS is two files, as it was in the button: the .tsv with the
%   coordinates, and a .json beside it saying what they mean. Two calls, one
%   per file, because each file needs its own name. The json records where
%   the coordinates came from - the CT the project was localized on - and
%   what was done to them: nothing for the contacts as localized, the
%   projection method for the projected ones, each with the paper to cite.
%
%   Nothing is drawn and no window is opened: which file, and whether to
%   overwrite it, is the frontend's question - so the file is chosen before
%   this is called, and an export that cannot be made fails after the dialog
%   rather than before it.
%
%   Errors: ielec:noArrays (nothing localized yet), ielec:noTargets, ielec:noCT
%   (the json needs the CT the coordinates came from), ielec:badOption, and
%   those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.file        = fullfile(pwd, 'contacts.tsv');
%       cfg.format      = 'bids';
%       [project, work, report] = ielec.export(cfg, project, work);
%       report.contacts
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ELECTRODECOORDINATES, WRITEBIDSELECTRODES, ALABELS2TXT_NEW.

defaults.coordinates = 'contacts';
cfg = checkCfg(cfg, defaults, {'file', 'format'}, 'export');

formats = {'structure', 'eeglab', 'fieldtrip', 'bids', 'bidsCoordinateSystem', ...
           'labels', 'targetLabels'};
if ~ischar(cfg.format) || ~ismember(cfg.format, formats)
    error('ielec:badOption', 'ielec.export: cfg.format must be one of: %s.', ...
        strjoin(formats, ', '));
end
if ~ischar(cfg.coordinates) || ~ismember(cfg.coordinates, {'contacts', 'projection'})
    error('ielec:badOption', ...
        'ielec.export: cfg.coordinates must be ''contacts'' or ''projection''.');
end
if ~ischar(cfg.file) || isempty(cfg.file)
    error('ielec:badOption', 'ielec.export: cfg.file must be the full path to write.');
end

arrays  = fieldOr(project, 'electrodes', {});
targets = fieldOr(project, 'targets', {});

if strcmp(cfg.format, 'targetLabels')
    if isempty(targets)
        error('ielec:noTargets', ...
            'ielec.export: there is no planning target to write.');
    end
elseif isempty(arrays)
    error('ielec:noArrays', ...
        'ielec.export: there is no array to write. Localize one first.');
end

% The flat contact list, for the formats whose writer takes it. The others -
% the structure and the two reports - are given the arrays themselves and are
% not asked for it, as in the buttons: a project whose contacts have no
% anatomical labels yet has no flat list to make, and its report is still a
% report.
needsList = ismember(cfg.format, {'eeglab', 'fieldtrip', 'bids', 'bidsCoordinateSystem'});
crd = [];
if needsList
    crd = electrodeCoordinates(arrays, cfg.coordinates);
end

projected = 'No';
if strcmp(cfg.coordinates, 'projection'), projected = 'Yes'; end

switch cfg.format
    case 'structure'
        writeElectrodeStructure(cfg.file, arrays);

    case 'eeglab'
        writeEEGLABcoordinates(cfg.file, crd);

    case 'fieldtrip'
        writeFieldTripElectrodes(cfg.file, crd, arrays, ...
            project.currentSpace, projected);

    case 'bids'
        writeBIDSelectrodes(cfg.file, crd);

    case 'bidsCoordinateSystem'
        writeBIDScoordinateSystem(cfg.file, ctFileName(project), ...
            processingOf(crd, cfg.coordinates), referenceFor(cfg.coordinates));

    case 'labels'
        aLabels2txt_new(arrays, cfg.file, labelHeading(cfg.coordinates));

    case 'targetLabels'
        aLabelsTargets2txt_new(targets, cfg.file);
end

report.file        = cfg.file;
report.format      = cfg.format;
report.coordinates = cfg.coordinates;
if strcmp(cfg.format, 'targetLabels')
    report.contacts = contactCount(targets);
elseif needsList
    report.contacts = numel(crd.x);
else
    report.contacts = contactCount(arrays);
end
end

% ---------------------------------------------------------------------
function n = contactCount(arrays)
% how many contacts there are in a list of arrays
n = 0;
for k = 1:numel(arrays)
    n = n + numel(arrays{k}.x);
end
end

% ---------------------------------------------------------------------
function name = ctFileName(project)
% the image the BIDS json points at: the CT the contacts were localized on
if ~isfield(project, 'TAC') || ~isstruct(project.TAC) || ...
        ~isfield(project.TAC, 'vol') || ~isfield(project.TAC.vol, 'fname')
    error('ielec:noCT', ...
        ['ielec.export: the BIDS json names the image the coordinates came ' ...
         'from, and this project has no CT loaded.']);
end
name = project.TAC.vol.fname;
end

function text = processingOf(crd, coordinates)
% what was done to the coordinates, in the json's words: nothing for the
% contacts as localized, the projection's own method for the projected ones
if strcmp(coordinates, 'projection')
    text = crd.projectionMethod{1};
else
    text = 'none';
end
end

function text = referenceFor(coordinates)
% the paper to cite for that processing, as the button wrote it
if strcmp(coordinates, 'projection')
    text = ['Blenkmann et al., 2017. https://doi.org/10.3389/fninf.2017.00014; ' ...
            'Blenkmann et al., 2023. https://doi.org/10.1101/2023.05.08.539503'];
else
    text = 'Blenkmann et al., 2017. https://doi.org/10.3389/fninf.2017.00014 ';
end
end

function text = labelHeading(coordinates)
% the words aLabels2txt_new switches on
if strcmp(coordinates, 'projection')
    text = 'SCE-projected coordinates';
else
    text = 'Localized coordinates';
end
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end
