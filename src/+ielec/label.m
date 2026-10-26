function [project, work] = label(cfg, project, work)
%IELEC.LABEL  Give every contact its anatomical label.
%
%   [project, work] = ielec.label(cfg, project, work) labels the contacts of
%   every array in the project, and of the planning targets, from the
%   anatomy: the patient's FreeSurfer parcellation in native space, or a
%   probabilistic atlas in MNI space. WORK is not changed.
%
%   Options (cfg):
%     cfg.space           'Native' or 'MNI'. Default: project.currentSpace,
%                         the space the stored coordinates are in
%                         (RESOLVESPACE).
%     cfg.radius          how far around a contact to look, in millimetres.
%                         0 looks at the contact's own voxel only.
%                         Default: work.options.atlasLabelingRadio
%     cfg.mode            'mode' reports the most common region in that
%                         radius, 'prob' reports every region with the share
%                         of voxels it holds.
%                         Default: work.options.atlasLabelingMode
%     cfg.minProbability  in 'prob', the smallest share worth reporting.
%                         Default: work.options.atlasLabelingMinProb
%
%   The last three are native labelling's; MNI labelling reads a
%   probabilistic atlas that has no such settings, and giving them with
%   cfg.space 'MNI' is refused rather than ignored.
%
%   WHY THEY ARE OPTIONS AND NOT ONLY SESSION SETTINGS
%
%   They decide what the labels are. Asked at radius 0 every contact gets one
%   label; at radius 5 it gets every region within 5 mm with a share each.
%   They used to be read straight out of work.options, so the call could not
%   set them for one run and - because RECORDSTEP writes the cfg - the step
%   recorded in the project did not say which had been used. Two runs that
%   produced differently shaped results left records that could not be told
%   apart, and work.options is not stored in the .iel, so reopening the
%   project gave the configuration file's defaults instead.
%
%   They are resolved into cfg before the work is done, so the recorded step
%   holds the values that were actually used, whether the caller gave them or
%   the session did. The toolbox author asked for this; see
%   docs/OPEN_QUESTIONS.md item 51.
%
%   Native space reads project.wmparc and the look-up table named in
%   work.options.atlasLUTFile, which is a file the session is configured
%   with rather than a per-call decision. MNI space reads the probabilistic
%   atlas loaded once at start-up, which is a shared resource and lives in
%   work (work.MNIlabels, work.MNIprob, work.MNI_S_matrix).
%
%   A contact that falls outside the anatomy is labelled 'unknown', which is
%   not an error: a subdural strip on the surface can do exactly that (see
%   docs/OPEN_QUESTIONS.md item 3).
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:badOption, ielec:noAtlas (MNI labelling without the atlas
%   in work), and those of the cfg check.
%
%   Example
%       [project, work] = ielec.label([], project, work);        % as stored
%       [project, work] = ielec.label(struct('space','MNI'), project, work);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also LABELELECTRODESNATIVE, LABELELECTRODESMNI, IELEC.ACCEPTARRAY.

defaults.space          = '';
defaults.radius         = [];
defaults.mode           = '';
defaults.minProbability = [];
cfg = checkCfg(cfg, defaults, {}, 'label');
cfg.space = resolveSpace(cfg.space, project, 'label');

options = fieldOr(work, 'options', default_ielectrodes_options([]));
[cfg, labelOpt] = resolveLabelling(cfg, options, 'label');

prj = project;
if strcmp(cfg.space, 'MNI')
    for f = {'MNI_S_matrix', 'MNIlabels', 'MNIprob'}
        if ~isfield(work, f{1}) || isempty(work.(f{1}))
            error('ielec:noAtlas', ...
                'ielec.label: the MNI atlas is not loaded (work.%s).', f{1});
        end
        prj.(f{1}) = work.(f{1});
    end
    prj = labelElectrodesMNI(prj);
else
    % the resolved values, not whatever the session happens to hold
    prj.options                        = options;
    prj.options.atlasLabelingRadio     = labelOpt.radio;
    prj.options.atlasLabelingMode      = labelOpt.mode;
    prj.options.atlasLabelingMinProb   = labelOpt.minProb;
    prj = labelElectrodesNative(prj);
end

% only what the labelling writes goes back, so that the project keeps being
% the one authoritative copy
project.electrodes = prj.electrodes;
project.targets    = prj.targets;

project = recordStep(project, mfilename, cfg);
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = default;
end
end
