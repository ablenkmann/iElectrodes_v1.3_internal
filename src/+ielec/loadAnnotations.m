function [project, work, colours] = loadAnnotations(cfg, project, work)
%IELEC.LOADANNOTATIONS  Read the surface annotations, or clear them.
%
%   [project, work, colours] = ielec.loadAnnotations(cfg, project, work)
%   reads a FreeSurfer annotation for each hemisphere - the parcellation of
%   the surface, one label per vertex - and keeps the labels and their colour
%   tables in the project. WORK is not changed.
%
%   Options (cfg):
%     cfg.right   the right hemisphere's .annot. Full path.
%     cfg.left    the left one. Full path.
%
%   Both left out, or empty, means "no annotation": the labels and tables are
%   cleared and COLOURS comes back grey, which is what the button did when
%   the user said no. That is not the same as leaving the project alone - a
%   project that had an annotation loses it, as it did before.
%
%   COLOURS has a field per hemisphere, .right and .left, each an N-by-3
%   array of RGB in [0 1], one row per vertex of that surface. Like the
%   parcellation's colours it is a display cache, so it is the third output
%   and the frontend keeps it in ui.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:badOption (one hemisphere given without the other, or a
%   path that is not one), those of the cfg check, and whatever
%   READ_ANNOTATION raises about the files.
%
%   Example
%       cfg = [];
%       cfg.right = fullfile(folder, 'rh.aparc.annot');
%       cfg.left  = fullfile(folder, 'lh.aparc.annot');
%       [project, work, colours] = ielec.loadAnnotations(cfg, project, work);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also READ_ANNOTATION, ANNOTATIONCOLOURS, IELEC.LOADSURFACES.

defaults.right = '';
defaults.left  = '';
cfg = checkCfg(cfg, defaults, {}, 'loadAnnotations');

for f = {'right', 'left'}
    if ~ischar(cfg.(f{1}))
        error('ielec:badOption', ...
            'ielec.loadAnnotations: cfg.%s must be the full path of an .annot file.', f{1});
    end
end

given = [~isempty(cfg.right), ~isempty(cfg.left)];
if xor(given(1), given(2))
    error('ielec:badOption', ...
        ['ielec.loadAnnotations: an annotation is a pair. Give cfg.right and ' ...
         'cfg.left together, or neither to clear them.']);
end

if ~any(given)     % no annotation: grey vertices, and nothing kept
    project.AnnotLabel_R      = [];
    project.AnnotLabel_L      = [];
    project.AnnotColortable_R = [];
    project.AnnotColortable_L = [];

    colours.right = ones(length(fieldOr(project, 'verticesR', [])), 3) * .5;
    colours.left  = ones(length(fieldOr(project, 'verticesL', [])), 3) * .5;
    return
end

[~, labelR, tableR] = read_annotation(cfg.right);
[~, labelL, tableL] = read_annotation(cfg.left);

project.AnnotLabel_R      = labelR;   % label for each node
project.AnnotLabel_L      = labelL;
project.AnnotColortable_R = tableR;   % colortable info
project.AnnotColortable_L = tableL;

colours.right = annotationColours(labelR, tableR);
colours.left  = annotationColours(labelL, tableL);
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end
