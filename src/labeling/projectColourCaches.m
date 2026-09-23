function caches = projectColourCaches(project, lutFile)
%PROJECTCOLOURCACHES  The colours the display derives from a project.
%
%   caches = projectColourCaches(project, lutFile) returns a struct with the
%   three colour caches the .iel file carries and the GUI draws with:
%
%     wmparcColors   an RGB colour for every voxel of the parcellation,
%                    from the look-up table LUTFILE, or [] when the project
%                    has no parcellation
%     AnnotColor_R   an RGB colour for every vertex of the right pial surface,
%     AnnotColor_L   from its cortical annotation, or grey (0.5) for every
%                    vertex when there is no annotation
%
%   They are computed the way the toolbox computes them when a parcellation
%   or an annotation is loaded - PARCELLATIONCOLOURS and ANNOTATIONCOLOURS -
%   so they are the same values, not an approximation. LUTFILE is
%   work.options.atlasLUTFile; leave it empty for the FreeSurfer default.
%
%   Nothing is drawn. This is data derived from the project; the display
%   decides what to do with it.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also PARCELLATIONCOLOURS, ANNOTATIONCOLOURS, IELEC.COLOURCACHES.

if nargin < 2
    lutFile = [];
end

if isempty(fieldOr(project, 'wmparc', []))
    caches.wmparcColors = [];
else
    caches.wmparcColors = parcellationColours(project.wmparc.img, lutFile);
end

for side = 'RL'
    labels = fieldOr(project, ['AnnotLabel_' side], []);
    if ~isempty(labels)
        colours = annotationColours(labels, project.(['AnnotColortable_' side]));
    else
        colours = ones(length(fieldOr(project, ['vertices' side], [])), 3) * .5;
    end
    caches.(['AnnotColor_' side]) = colours;
end
end

function value = fieldOr(s, name, default)
if isfield(s, name), value = s.(name); else, value = default; end
end
