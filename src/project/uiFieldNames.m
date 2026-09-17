function names = uiFieldNames()
%UIFIELDNAMES  Presentation fields that now live in handles.ui.
%
%   names = uiFieldNames() returns the field names that have been moved out
%   of the flat handles struct into handles.ui so far.
%
%   Unlike project and work, handles.ui is mostly built at run time -
%   graphics handles, the cursor, the plot-update flags - and none of that
%   ever arrives flat, so none of it is listed here. This list holds only the
%   presentation values that DO arrive flat, because the .iel file carries
%   them and CHECKPROJECTSTRUCTURE unpacks them at the top level.
%
%   All three are colour caches: arrays of RGB values derived from data the
%   project already holds.
%
%     wmparcColors    an RGB volume derived from wmparc and the FreeSurfer
%                     look-up table; drawn under the 2-D slices
%     AnnotColor_L    per-vertex RGB derived from the annotation labels and
%     AnnotColor_R    their colortable; handed to mvis when drawing the pial
%                     surfaces
%
%   Being caches, they could be recomputed on load - PARCELLATIONCOLOURS and
%   ANNOTATIONCOLOURS reproduce them exactly, and checkProjectStructure
%   already rebuilds wmparcColors when a file lacks it. They are kept in the
%   file anyway, and FLATTENPROJECT copies them back when saving, because
%   iElectrodes 1.020 fails to open a project whose AnnotColor_R is missing.
%   Dropping them would break that compatibility, which this restructuring
%   does not do.
%
%   See also LIFTTOUI, FLATTENPROJECT, PROJECTFIELDNAMES, WORKFIELDNAMES.

names = { ...
    ... % colour caches derived from project data, carried by the .iel file
    'wmparcColors', 'AnnotColor_L', 'AnnotColor_R' ...
    };
end
