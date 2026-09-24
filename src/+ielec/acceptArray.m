function [project, work, index] = acceptArray(project, work, cfg, array)
%IELEC.ACCEPTARRAY  Put a localized array into the project.
%
%   [project, work, index] = ielec.acceptArray(project, work, cfg, array)
%   adds ARRAY - what IELEC.FITARRAY or IELEC.CLUSTER proposed - to
%   project.electrodes, and returns where it went.
%
%   Options (cfg):
%     cfg.index   which array to replace. [] adds a new one at the end,
%                 which is the usual case.                    Default: []
%
%   WORK. Adding a new array finishes the localization it came from, so the
%   contacts in progress are cleared - work.GS, work.brushCrd,
%   work.brushWeight and work.clusters - with the previous values kept in
%   work.oldGS and the other old fields, which is what Undo restores.
%   Replacing an array (cfg.index) leaves the work in progress alone, as the
%   Add button did.
%
%   The array is not labelled or projected here: IELEC.LABEL does the
%   labelling and the projection to the smooth cortical envelope is its own
%   step. Each is a decision of its own, and a caller may want one without
%   the other.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:badArray (not an array structure), ielec:badOption (an
%   index that is not a position in the project's arrays), and those of the
%   cfg check.
%
%   Example
%       [project, work, array] = ielec.fitArray(project, work, fitCfg);
%       [project, work, index] = ielec.acceptArray(project, work, [], array);
%       project.electrodes{index}.Name
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ADDARRAY, IELEC.FITARRAY, IELEC.LABEL, IELEC.REMOVEARRAY.

defaults.index = [];
cfg = checkCfg(cfg, defaults, {}, 'acceptArray');

if nargin < 4 || ~isstruct(array) || ~isscalar(array) || ~isfield(array, 'x')
    error('ielec:badArray', ...
        'ielec.acceptArray: ARRAY must be one electrode array structure, as ielec.fitArray returns.');
end

arrays = fieldOr(project, 'electrodes', {});
if ~isempty(cfg.index)
    n = cfg.index;
    if ~isnumeric(n) || ~isscalar(n) || n < 1 || mod(n,1) ~= 0 || n > numel(arrays)
        error('ielec:badOption', ...
            'ielec.acceptArray: cfg.index must be one of the project''s %d arrays.', ...
            numel(arrays));
    end
end

[project.electrodes, index] = addArray(arrays, array, cfg.index);

if isempty(cfg.index)
    % the contacts in progress became this array
    work.oldGS          = fieldOr(work, 'GS', []);
    work.oldbrushCrd    = fieldOr(work, 'brushCrd', []);
    work.oldbrushWeight = fieldOr(work, 'brushWeight', []);
    work.oldclusters    = fieldOr(work, 'clusters', []);

    work.GS          = [];
    work.brushCrd    = [];
    work.brushWeight = [];
    work.clusters    = [];
end
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end
