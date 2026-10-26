function [project, work, report] = pointLabel(cfg, project, work)
%IELEC.POINTLABEL  Which anatomical region a point is in.
%
%   [project, work, report] = ielec.pointLabel(cfg, project, work) says what
%   the atlas calls the place a coordinate is in. Nothing is changed: the
%   project and work come back as they went in, and the answer is the third
%   output.
%
%   Options (cfg):
%     cfg.radius          how far around the point to look, in millimetres.
%                         Default: work.options.atlasLabelingRadio
%     cfg.mode            'mode' for the most common region in that radius,
%                         'prob' for every region with its share.
%                         Default: work.options.atlasLabelingMode
%     cfg.minProbability  in 'prob', the smallest share worth reporting.
%                         Default: work.options.atlasLabelingMinProb
%
%   The three are native labelling's, as in IELEC.LABEL, and are refused in
%   a project whose space is MNI. They used to be read straight out of
%   work.options, so a caller could not ask for one answer at one radius and
%   another at another - see docs/OPEN_QUESTIONS.md item 51.
%
%     cfg.coordinate  the point, or several, as N-by-3 in the space the
%                     project is currently in.                     Required
%     cfg.lookAround  ask what is most common in a small cube around the
%                     point rather than what is in the one voxel it lands
%                     in. Only the patient's parcellation uses it; the size
%                     of the cube and how the answer is chosen come from
%                     work.options (atlasLabelingRadio, atlasLabelingMode,
%                     atlasLabelingMinProb).                   Default: true
%
%   The report:
%     report.label   what the atlas says, exactly as the backend answers it:
%                    a cell with one row per point, which has more than one
%                    column when the atlas is asked for probabilities rather
%                    than for the most common label. Empty when there is no
%                    atlas to ask, and the empty character vector for a point
%                    outside the atlas.
%     report.source  which atlas answered -
%                      'MNI'           the template atlas, because the
%                                      project is in MNI space
%                      'parcellation'  the patient's own FreeSurfer
%                                      parcellation
%                      'none'          there is neither, so nothing was
%                                      asked and report.label is empty
%
%   Why the source is in the report: what to show the user when there is no
%   atlas is a question about a text box, and that belongs to the frontend
%   (docs/API_LAYER.md rule 2). The layer says which atlas answered, or that
%   none did, and the frontend writes whatever it likes in that case.
%
%   This is what the coordinate box shows as the cursor moves, so it runs
%   often and does as little as the button did: one call, one point.
%
%   The name: the backend functions this calls are ANATOMICLABEL and
%   ANATOMICLABELFS. An ielec function does not take a backend function's
%   name (rule 6), and this one covers both. IELEC.LABEL is the other side
%   of the same coin - it labels the contacts of the arrays and keeps the
%   answer in the project, where this one only answers a question.
%
%   Errors: ielec:badOption (a coordinate that is not N-by-3),
%   ielec:noAtlas (MNI space with no MNI atlas in work, the same identifier
%   IELEC.LABEL raises for it) and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.coordinate = [-54 -22 12];
%       [~, ~, report] = ielec.pointLabel(cfg, project, work);
%       report.source
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ANATOMICLABEL, ANATOMICLABELFS, IELEC.LABEL, IELEC.LOADANATOMY.

defaults.lookAround     = true;
defaults.radius         = [];
defaults.mode           = '';
defaults.minProbability = [];
cfg = checkCfg(cfg, defaults, {'coordinate'}, 'pointLabel');

options = fieldOr(work, 'options', default_ielectrodes_options([]));
cfg.space = project.currentSpace;          % only so the check below can see it
[cfg, labelOpt] = resolveLabelling(cfg, options, 'pointLabel');
cfg = rmfield(cfg, 'space');

if ~isnumeric(cfg.coordinate) || isempty(cfg.coordinate) || ...
        size(cfg.coordinate, 2) ~= 3 || ~all(isfinite(cfg.coordinate(:)))
    error('ielec:badOption', ...
        ['ielec.pointLabel: cfg.coordinate must be an N-by-3 of finite ' ...
         'coordinates in the project''s current space.']);
end
if ~(islogical(cfg.lookAround) || isnumeric(cfg.lookAround)) || ...
        ~isscalar(cfg.lookAround) || ~isfinite(cfg.lookAround)
    error('ielec:badOption', ...
        'ielec.pointLabel: cfg.lookAround is on or off.');
end
lookAround = double(logical(cfg.lookAround));

if strcmp(project.currentSpace, 'MNI')
    for f = {'MNI_S_matrix', 'MNIlabels', 'MNIprob'}
        if ~isfield(work, f{1}) || isempty(work.(f{1}))
            error('ielec:noAtlas', ...
                'ielec.pointLabel: the MNI atlas is not loaded (work.%s).', f{1});
        end
    end

    report.source = 'MNI';
    report.label  = anatomicLabel(cfg.coordinate, work.MNI_S_matrix, ...
                                  work.MNIlabels, work.MNIprob);

elseif ~isempty(fieldOr(project, 'wmparc', []))
    opt = labelOpt;

    report.source = 'parcellation';
    report.label  = anatomicLabelFS(cfg.coordinate, [], ...
        work.options.atlasLUTFile, lookAround, project.wmparc.img, ...
        project.wmparcS, [], [], opt);

else
    report.source = 'none';
    report.label  = {};
end
end

function value = fieldOr(s, name, default)
if isfield(s, name), value = s.(name); else, value = default; end
end
