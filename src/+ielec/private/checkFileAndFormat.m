function checkFileAndFormat(cfg, caller)
%CHECKFILEANDFORMAT  The two options the import calls share - for ielec.
%
%   checkFileAndFormat(cfg, caller) refuses a cfg.file that is not a non-empty
%   character vector, and a cfg.format that is not one of the formats
%   iElectrodes can read: 'structure', 'eeglab' or 'fieldtrip'. CALLER is
%   named in the error. Whether the file exists and what is in it is the
%   reader's to say, as it was when the button called it.
%
%   Private to the ielec package.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.ARRAYFILECONTENTS, IELEC.IMPORTARRAYS.

formats = {'structure', 'eeglab', 'fieldtrip'};

if ~ischar(cfg.file) || isempty(cfg.file)
    error('ielec:badOption', ...
        'ielec.%s: cfg.file must be the full path of the file to read.', caller);
end
if ~ischar(cfg.format) || ~ismember(cfg.format, formats)
    error('ielec:badOption', ...
        'ielec.%s: cfg.format must be one of: %s.', caller, strjoin(formats, ', '));
end
end
