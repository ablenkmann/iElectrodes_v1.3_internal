function [project, work] = nameContacts(project, work, cfg)
%IELEC.NAMECONTACTS  Name an array and its contacts.
%
%   [project, work] = ielec.nameContacts(project, work, cfg) gives one array
%   its name and its contacts theirs. WORK is not changed.
%
%   Options (cfg):
%     cfg.index     which array. Required.
%     cfg.group     'electrodes', the localized arrays, or 'targets', the
%                   planned ones.                    Default: 'electrodes'
%     cfg.baseName  the name of the array. With no cfg.labels it is also the
%                   contacts' name: they become baseName1, baseName2, and so
%                   on. Empty leaves the array's name alone when labels are
%                   given, and numbers the contacts without a prefix when
%                   they are not - which is what the button does with an
%                   empty box.                                  Default: ''
%     cfg.labels    one label per contact, as a cell of text - the recording
%                   channels, in the order of the contacts. {} numbers them
%                   from cfg.baseName instead.                   Default: {}
%                   A cell of strings is taken as well and kept as character
%                   vectors, which is what the project holds everywhere else.
%
%   The two are the two Label buttons. "Label" numbers the contacts from the
%   base name in the box; "Label from list" takes the recording channel names
%   the user picked out of a list and gives them to the contacts in order.
%   Which labels those are is the frontend's question - a file dialog and a
%   two-column window - and the answer arrives here as cfg.labels.
%
%   The contacts are named in their present order, so an array whose
%   numbering is wrong should be put right first (IELEC.INDEXARRAY,
%   IELEC.REORDERARRAY) and named after.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:badOption (a group that is neither, an index that is not a
%   position in the project,
%   a base name that is not text, labels that are not one character vector
%   per contact) and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.index    = 1;
%       cfg.baseName = 'LTG';                  % LTG1, LTG2, LTG3, ...
%       [project, work] = ielec.nameContacts(project, work, cfg);
%
%       cfg.labels = {'A1','A2','A3','A4'};    % or the recording's own names
%       [project, work] = ielec.nameContacts(project, work, cfg);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also NAMEARRAYCONTACTS, APPLYCONTACTLABELS, IELEC.IMPORTLABELS,
%            IELEC.REORDERARRAY.

defaults.baseName = '';
defaults.labels   = {};
defaults.group    = 'electrodes';
cfg = checkCfg(cfg, defaults, {'index'}, 'nameContacts');

if ~ischar(cfg.group) || ~ismember(cfg.group, {'electrodes', 'targets'})
    error('ielec:badOption', ...
        'ielec.nameContacts: cfg.group must be ''electrodes'' or ''targets''.');
end

arrays = fieldOr(project, cfg.group, {});
if ~isnumeric(cfg.index) || ~isscalar(cfg.index) || mod(cfg.index, 1) ~= 0 || ...
        cfg.index < 1 || cfg.index > numel(arrays)
    error('ielec:badOption', ...
        'ielec.nameContacts: cfg.index must be one of the %d %s in the project.', ...
        numel(arrays), cfg.group);
end
array = arrays{cfg.index};

if ~ischar(cfg.baseName) || (~isempty(cfg.baseName) && ~isrow(cfg.baseName))
    error('ielec:badOption', ...
        'ielec.nameContacts: cfg.baseName must be text - the name of the array.');
end

if ~isempty(cfg.labels)
    if ~iscell(cfg.labels) || numel(cfg.labels) ~= array.nElectrodes
        error('ielec:badOption', ...
            ['ielec.nameContacts: cfg.labels must hold one label per contact - ' ...
             '%d of them, and there are %d.'], numel(cfg.labels), array.nElectrodes);
    end
    isText = @(s) (ischar(s) && (isempty(s) || isrow(s))) || ...
                  (isstring(s) && isscalar(s));
    if ~all(cellfun(isText, cfg.labels))
        error('ielec:badOption', ...
            'ielec.nameContacts: every label in cfg.labels must be text.');
    end
    % a .mat of labels may hold strings rather than character vectors; the
    % project keeps character vectors everywhere else
    labels = cfg.labels;
    for k = 1:numel(labels)
        if isstring(labels{k}), labels{k} = char(labels{k}); end
    end

    project.(cfg.group){cfg.index} = applyContactLabels(array, labels, cfg.baseName);
else
    project.(cfg.group){cfg.index} = nameArrayContacts(array, cfg.baseName);
end
end

function value = fieldOr(s, name, default)
if isfield(s, name), value = s.(name); else, value = default; end
end
