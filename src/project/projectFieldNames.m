function names = projectFieldNames()
%PROJECTFIELDNAMES  Patient-data fields that now live in handles.project.
%
%   names = projectFieldNames() returns the field names that live under
%   handles.project: the ones moved out of the flat handles struct, and any
%   that iElectrodes 2 added there and the flat struct never had.
%
%   This list is the single place that records how far the project/work/ui
%   migration has progressed. LIFTTOPROJECT and FLATTENPROJECT both read it,
%   so moving a group of fields out of the flat struct takes two steps and
%   nothing else:
%
%     1. add the field names here
%     2. rename handles.<field> to handles.project.<field> in electrodes_gui.m
%
%   A field that is new in iElectrodes 2 needs only step 1, because there is
%   no flat copy to rename - 'history' is the first of those, and the recipe
%   above does not apply to it.
%
%   The GROUPING does not affect the .iel file format: files stay flat, so
%   projects written by older versions keep loading and projects written now
%   keep opening in older versions. One field here does change the file, and
%   says so: 'history', added in iElectrodes 2, is a field 1.020 never wrote.
%   It opens a 1.020 file with an empty history and 1.020 ignores it in a
%   file of ours - which TEST_IELFORMAT checks rather than assumes.
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
    ... % (the derived colour volumes wmparcColors and AnnotColor_L/R are not
    ... %  here: they are display caches and live in handles.ui, see
    ... %  UIFIELDNAMES - the .iel file still carries them, which FLATTENPROJECT
    ... %  handles)
    'wmparc', 'wmparcS', ...
    'AnnotLabel_L', 'AnnotLabel_R', 'AnnotColortable_L', 'AnnotColortable_R', ...
    ... % electrodes, planning targets and the space their coordinates are in
    'electrodes', 'targets', 'currentSpace', 'elecListLabels', ...
    ... % what was done to this project, one cfg per step (iElectrodes 2)
    'history' ...
    };
end
