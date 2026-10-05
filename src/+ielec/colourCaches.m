function [project, work, ui] = colourCaches(cfg, project, work)
%IELEC.COLOURCACHES  The colours a display derives from the project.
%
%   [project, work, ui] = ielec.colourCaches(cfg, project, work) returns,
%   in UI, the colours of the parcellation and of the two pial surfaces
%   (wmparcColors, AnnotColor_R, AnnotColor_L). It changes nothing: PROJECT
%   and WORK come back as they went in.
%
%   The .iel file carries these colours, and the GUI draws with them, but
%   they are derived from the project, not part of it. So the layer does not
%   keep them - they are display state, and the window never enters the layer - and
%   a frontend asks for them when it has none that fit: for a new project.
%   An opened project brings its own (IELEC.OPENPROJECT).
%
%   Options (cfg): none. Pass [].
%
%   The parcellation colours use work.options.atlasLUTFile, as the Load
%   parcellation button does; with no options in WORK, the FreeSurfer
%   default.
%
%   Example
%       [project, work, ui] = ielec.colourCaches([], project, work);
%       handles.ui.wmparcColors = ui.wmparcColors;
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also PROJECTCOLOURCACHES, IELEC.OPENPROJECT, docs/API_LAYER.md.

checkCfg(cfg, struct(), {}, 'colourCaches');

lutFile = [];
if isstruct(work) && isfield(work, 'options') && isfield(work.options, 'atlasLUTFile')
    lutFile = work.options.atlasLUTFile;
end
ui = projectColourCaches(project, lutFile);
end
