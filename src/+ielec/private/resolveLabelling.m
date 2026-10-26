function [cfg, opt] = resolveLabelling(cfg, options, caller)
%RESOLVELABELLING  Settle the three settings that decide an anatomical label.
%
%   [cfg, opt] = resolveLabelling(cfg, options, caller)
%
%   CFG is the caller's, after CHECKCFG, with cfg.radius, cfg.mode and
%   cfg.minProbability among its fields and cfg.space already resolved.
%   OPTIONS is work.options. CALLER names the function, for the messages.
%
%     cfg   the same cfg with the three filled in: what the caller gave,
%           or what the session holds where the caller gave nothing
%     opt   the three under the names the backend uses - .radio, .mode,
%           .minProb - ready to hand to ANATOMICLABELFS
%
%   WHY THE CFG COMES BACK
%
%   RECORDSTEP writes the cfg, so filling the values in here is what puts
%   them in the project's history. Before this, they were read out of
%   work.options where they were used, the cfg held only the space, and two
%   runs at different radii left records that could not be told apart - and
%   work.options is not stored in the .iel, so the values were gone as soon
%   as the project was reopened. The toolbox author asked for the layer to
%   take its configuration through cfg; docs/OPEN_QUESTIONS.md item 51 has
%   the measurements.
%
%   Giving nothing is still the ordinary case, and still means the session's
%   settings. The difference is that the project now records which they were.
%
%   MNI
%
%   These three belong to the FreeSurfer parcellation. MNI labelling reads a
%   probabilistic atlas and has no radius to look within, so the three are
%   refused there rather than accepted and ignored.
%
%   Errors: ielec:badOption.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.LABEL, IELEC.POINTLABEL, ANATOMICLABELFS, CHECKCFG.

given = ~isempty(cfg.radius) || ~isempty(cfg.mode) || ...
        ~isempty(cfg.minProbability);

if strcmp(cfg.space, 'MNI')
    if given
        error('ielec:badOption', ...
            ['ielec.%s: cfg.radius, cfg.mode and cfg.minProbability are ' ...
             'the parcellation''s, and this project is in MNI space, ' ...
             'where the atlas is probabilistic and has none of them.'], caller);
    end
    opt = struct('radio', [], 'mode', '', 'minProb', []);
    return
end

% WHAT IS CHECKED AND WHAT IS NOT
%
% Only what the caller gave. A value that comes from work.options goes
% through as it is, because that is what happened before these options
% existed: the configuration file's value was handed to the backend
% unchecked. Checking it here would turn a session that has been working -
% or failing quietly - into one that refuses to start, and a guard that
% turns a success into an error is the one kind this layer must not add.

if ~isempty(cfg.radius)
    if ~isnumeric(cfg.radius) || ~isscalar(cfg.radius) || ...
            ~isfinite(cfg.radius) || cfg.radius < 0
        error('ielec:badOption', ...
            ['ielec.%s: cfg.radius must be a distance in millimetres, ' ...
             '0 or more.'], caller);
    end
else
    cfg.radius = options.atlasLabelingRadio;
end

if ~isempty(cfg.mode)
    cfg.mode = char(cfg.mode);
    if ~ismember(cfg.mode, {'mode', 'prob'})
        error('ielec:badOption', ...
            ['ielec.%s: cfg.mode is ''mode'' for the most common region ' ...
             'or ''prob'' for every region with its share.'], caller);
    end
else
    cfg.mode = options.atlasLabelingMode;
end

if ~isempty(cfg.minProbability)
    if ~isnumeric(cfg.minProbability) || ~isscalar(cfg.minProbability) || ...
            ~isfinite(cfg.minProbability) || ...
            cfg.minProbability < 0 || cfg.minProbability > 1
        error('ielec:badOption', ...
            'ielec.%s: cfg.minProbability is a share, between 0 and 1.', ...
            caller);
    end
else
    cfg.minProbability = options.atlasLabelingMinProb;
end

opt.radio   = cfg.radius;
opt.mode    = cfg.mode;
opt.minProb = cfg.minProbability;
end
