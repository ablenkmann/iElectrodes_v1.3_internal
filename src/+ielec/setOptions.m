function [project, work] = setOptions(cfg, project, work)
%IELEC.SETOPTIONS  Put the scientific options into work.
%
%   [project, work] = ielec.setOptions(cfg, project, work) fills
%   work.options with the defaults, and with whatever cfg.options overrides.
%   PROJECT gains nothing but the step this records in its history.
%
%   Options (cfg):
%     cfg.options  a struct whose fields override the defaults. [] takes the
%                  defaults as they are - what DEFAULT_IELECTRODES_OPTIONS
%                  reads from the configuration file, so [] is also how the
%                  options are reloaded after that file is edited.
%                                                               Default: []
%
%   These are the options that change a result: voxel sizes, clustering and
%   fitting settings, the atlas and how it is read. What only changes what is
%   shown lives in the frontend and never reaches here (rule 2).
%
%   Reloading is what the Config button does: DEFAULT_IELECTRODES_OPTIONS
%   reads the file again, so the same call picks up an edit to it without
%   restarting.
%
%   Errors: ielec:badOption (cfg.options that is not a struct) and those of
%   the cfg check.
%
%   Example
%       [project, work] = ielec.setOptions([], project, work);
%       work.options.clustering_method
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also DEFAULT_IELECTRODES_OPTIONS, IELEC.STARTSESSION.

defaults.options = [];
cfg = checkCfg(cfg, defaults, {}, 'setOptions');

if ~isempty(cfg.options) && ~isstruct(cfg.options)
    error('ielec:badOption', ...
        'ielec.setOptions: cfg.options must be a struct of options, or [].');
end

if isempty(work)
    work = struct();
end

work.options = default_ielectrodes_options(cfg.options);

project = recordStep(project, mfilename, cfg);
end
