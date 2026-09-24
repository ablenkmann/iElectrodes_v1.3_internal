function [project, work] = label(project, work, cfg)
%IELEC.LABEL  Give every contact its anatomical label.
%
%   [project, work] = ielec.label(project, work, cfg) labels the contacts of
%   every array in the project, and of the planning targets, from the
%   anatomy: the patient's FreeSurfer parcellation in native space, or a
%   probabilistic atlas in MNI space. WORK is not changed.
%
%   Options (cfg):
%     cfg.space   'Native' or 'MNI'. Default: project.currentSpace, which is
%                 the space the stored coordinates are in.
%
%   Native space reads project.wmparc and the labelling settings in
%   work.options - the radius around a contact, whether to report the most
%   probable region or all of them, the look-up table. MNI space reads the
%   probabilistic atlas loaded once at start-up, which is a shared resource
%   and lives in work (work.MNIlabels, work.MNIprob, work.MNI_S_matrix).
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
%       [project, work] = ielec.label(project, work, []);        % as stored
%       [project, work] = ielec.label(project, work, struct('space','MNI'));
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also LABELELECTRODESNATIVE, LABELELECTRODESMNI, IELEC.ACCEPTARRAY.

defaults.space = fieldOr(project, 'currentSpace', 'Native');
cfg = checkCfg(cfg, defaults, {}, 'label');

if ~ischar(cfg.space) || ~ismember(cfg.space, {'Native', 'MNI'})
    error('ielec:badOption', ...
        'ielec.label: cfg.space must be ''Native'' or ''MNI''.');
end

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
    prj.options = fieldOr(work, 'options', default_ielectrodes_options([]));
    prj = labelElectrodesNative(prj);
end

% only what the labelling writes goes back, so that the project keeps being
% the one authoritative copy
project.electrodes = prj.electrodes;
project.targets    = prj.targets;
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = default;
end
end
