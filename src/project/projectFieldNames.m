function names = projectFieldNames()
%PROJECTFIELDNAMES  Patient-data fields that now live in handles.project.
%
%   names = projectFieldNames() returns the field names that have been moved
%   out of the flat handles struct into handles.project so far.
%
%   This list is the single place that records how far the project/work/ui
%   migration has progressed. LIFTTOPROJECT and FLATTENPROJECT both read it,
%   so moving a new group of fields takes two steps and nothing else:
%
%     1. add the field names here
%     2. rename handles.<field> to handles.project.<field> in electrodes_gui.m
%
%   The .iel file format is deliberately NOT affected: files stay flat, so
%   projects written by older versions keep loading and projects written now
%   keep opening in older versions.
%
%   See docs/STATE_FIELD_MAPPING.md for the full classification of all 166
%   handles fields into project / work / ui.
%
%   See also LIFTTOPROJECT, FLATTENPROJECT, CHECKPROJECTSTRUCTURE.

names = { ...
    ... % FreeSurfer pial surfaces
    'verticesL', 'verticesR', 'facesL', 'facesR', ...
    ... % smooth cortical envelope surfaces
    'vertices_SCE_L', 'vertices_SCE_R', 'faces_SCE_L', 'faces_SCE_R', ...
    ... % images and the image-to-world transformation
    'T1', 'TAC', 'mask', 'S2', ...
    ... % patient atlas and surface annotations
    ... % (the derived colour volumes wmparcColors and AnnotColor_L/R stay out:
    ... %  they are display caches and belong to ui, see STATE_FIELD_MAPPING.md)
    'wmparc', 'wmparcS', ...
    'AnnotLabel_L', 'AnnotLabel_R', 'AnnotColortable_L', 'AnnotColortable_R', ...
    ... % electrodes, planning targets and the space their coordinates are in
    'electrodes', 'targets', 'currentSpace', 'elecListLabels' ...
    };
end
