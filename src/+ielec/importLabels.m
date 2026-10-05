function [project, work, labels] = importLabels(cfg, project, work)
%IELEC.IMPORTLABELS  Load the list of contact labels a project labels from.
%
%   [project, work, labels] = ielec.importLabels(cfg, project, work) reads a
%   list of contact labels - the channel names of the recording, usually -
%   and keeps it in project.elecListLabels, which is what the label dialog
%   offers when a contact is named by hand. WORK is not changed.
%
%   Options (cfg):
%     cfg.file     the file to read. Full path. Required.
%     cfg.format   how to read it. Required, one of:
%                    'txt'              a tab delimited text list
%                    'matlab'           a .mat with a cell array `labels`
%                    'eeglab'           a .set, its chanlocs labels
%                    'fieldtripHeader'  a .mat with a FieldTrip header
%                    'edf'              an .edf, its channel names
%
%   A file that yields no labels leaves the project as it was and returns an
%   empty list, which is what the button did with one: it went back without
%   replacing the labels it already had.
%
%   The list belongs to the project rather than to the session: it is the
%   recording's channel names, saved with the patient's data.
%
%   Nothing is drawn and no window is opened. Which file, and which of the
%   five formats it is, are the frontend's question - before this call.
%
%   Errors: ielec:badOption, and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.file   = fullfile(folder, 'channels.txt');
%       cfg.format = 'txt';
%       [project, work, labels] = ielec.importLabels(cfg, project, work);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also READCONTACTLABELS, IELEC.IMPORTARRAYS.

cfg = checkCfg(cfg, struct(), {'file', 'format'}, 'importLabels');

formats = {'txt', 'matlab', 'eeglab', 'fieldtripHeader', 'edf'};
if ~ischar(cfg.file) || isempty(cfg.file)
    error('ielec:badOption', ...
        'ielec.importLabels: cfg.file must be the full path of the file to read.');
end
if ~ischar(cfg.format) || ~ismember(cfg.format, formats)
    error('ielec:badOption', ...
        'ielec.importLabels: cfg.format must be one of: %s.', strjoin(formats, ', '));
end

labels = readContactLabels(cfg.file, cfg.format);

if ~isempty(labels)
    project.elecListLabels = labels;
end
end
