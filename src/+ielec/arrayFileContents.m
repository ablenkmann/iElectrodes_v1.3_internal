function [project, work, report] = arrayFileContents(project, work, cfg)
%IELEC.ARRAYFILECONTENTS  What is in a file of electrodes, before importing it.
%
%   [project, work, report] = ielec.arrayFileContents(project, work, cfg)
%   reads a file of electrodes and says what is in it, without touching the
%   project. PROJECT and WORK come back as they went in.
%
%   Options (cfg):
%     cfg.file     the file to look into. Full path. Required.
%     cfg.format   'structure' (an iElectrodes .mat), 'eeglab' (a .set) or
%                  'fieldtrip' (an elec structure). Required.
%
%   REPORT:
%     .arrays         the name of each array in the file
%     .contacts       how many contacts each of them has
%     .total          how many contacts there are altogether
%     .needsChoices   true when the file says nothing about what kind of
%                     array each one is. An iElectrodes .mat carries complete
%                     arrays; EEGLAB and FieldTrip files are a flat list of
%                     labelled points, and the convention that the letters of
%                     a label name its array (GROUPCONTACTSBYARRAY) is all
%                     there is to go on. Whether array G is a 4x8 grid or a
%                     strip is then the user's to say, and IELEC.IMPORTARRAYS
%                     takes the answer in cfg.arrays.
%
%   A frontend asks this first, so that it knows what to ask the user about;
%   then it calls IELEC.IMPORTARRAYS with the answers. Two calls rather than a
%   callback, for the same reason as IELEC.PROJECTIONSTATE: a dialog belongs
%   to the frontend (rule 2), and the file is read again there.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:badOption, those of the cfg check, and whatever the reader
%   raises about the file itself - which the frontend shows as it always did.
%
%   Example
%       cfg = [];
%       cfg.file   = fullfile(folder, 'dataset.set');
%       cfg.format = 'eeglab';
%       [~, ~, what] = ielec.arrayFileContents(project, work, cfg);
%       what.arrays
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.IMPORTARRAYS, GROUPCONTACTSBYARRAY, READEEGLABELECTRODES.

cfg = checkCfg(cfg, struct(), {'file', 'format'}, 'arrayFileContents');
checkFileAndFormat(cfg, 'arrayFileContents');

if strcmp(cfg.format, 'structure')
    arrays = readElectrodeStructure(cfg.file);

    report.arrays   = cellfun(@(e) e.Name, arrays, 'UniformOutput', false);
    report.contacts = cellfun(@(e) numel(e.x), arrays);
    report.needsChoices = false;
else
    labels = readContactList(cfg.file, cfg.format);

    [names, index] = groupContactsByArray(labels);
    report.arrays   = names;
    report.contacts = arrayfun(@(k) sum(index == k), 1:numel(names));
    report.needsChoices = true;
end

report.total = sum(report.contacts);
end

function labels = readContactList(file, format)
% the labels of a flat list of contacts, which is all this call needs
if strcmp(format, 'eeglab')
    labels = readEEGLABelectrodes(file);
else
    labels = readFieldTripElectrodes(file);
end
end
