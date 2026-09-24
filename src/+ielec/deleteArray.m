function [project, work, selected] = deleteArray(project, work, cfg)
%IELEC.DELETEARRAY  Take an array out of the project.
%
%   [project, work, selected] = ielec.deleteArray(project, work, cfg)
%   removes one array from the project and returns the index of the array
%   that should be shown next, by REMOVEARRAY's rule: the one before it, or
%   the one that followed it when it was the first, or 0 when nothing is
%   left. WORK is not changed.
%
%   Options (cfg):
%     cfg.index   which array to remove. Required.
%     cfg.group   'electrodes', the localized arrays, or 'targets', the
%                 planned ones.                      Default: 'electrodes'
%
%   The two lists the project keeps are removed from the same way, so the
%   Remove button of the electrodes and the one of the planning targets are
%   the same call with a different cfg.group.
%
%   Asking the user whether they are sure is the frontend's, as every
%   question is (rule 2). This function removes what it is told to remove.
%
%   Nothing is drawn and no window is opened.
%
%   The name: the backend function this calls is REMOVEARRAY. An ielec
%   function does not take a backend function's name - inside a package that
%   is easy to misread, and MATLAB's name resolution there is easy to get
%   wrong - which is why IELEC.ACCEPTARRAY is not called addArray either
%   (docs/API_LAYER.md rule 6).
%
%   Errors: ielec:badOption (an index that is not a position in that list,
%   or a group that is neither), and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.index = 2;
%       [project, work, selected] = ielec.deleteArray(project, work, cfg);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also REMOVEARRAY, IELEC.ACCEPTARRAY.

defaults.group = 'electrodes';
cfg = checkCfg(cfg, defaults, {'index'}, 'deleteArray');

if ~ischar(cfg.group) || ~ismember(cfg.group, {'electrodes', 'targets'})
    error('ielec:badOption', ...
        'ielec.deleteArray: cfg.group must be ''electrodes'' or ''targets''.');
end

arrays = fieldOr(project, cfg.group, {});

n = cfg.index;
if ~isnumeric(n) || ~isscalar(n) || n < 1 || mod(n,1) ~= 0 || n > numel(arrays)
    error('ielec:badOption', ...
        'ielec.deleteArray: cfg.index must be one of the %d %s in the project.', ...
        numel(arrays), cfg.group);
end

[project.(cfg.group), selected] = removeArray(arrays, n);
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end
