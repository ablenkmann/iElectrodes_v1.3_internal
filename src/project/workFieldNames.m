function names = workFieldNames()
%WORKFIELDNAMES  Working-data fields that now live in handles.work.
%
%   names = workFieldNames() returns the field names that have been moved out
%   of the flat handles struct into handles.work so far.
%
%   handles.work holds the operation currently in progress: intermediate
%   results, settings, and shared resources. It is the middle of the three
%   structures proposed in the architecture discussion:
%
%     project   the patient, and results that have been accepted
%     work      what is being done right now
%     ui        graphics objects and presentation state
%
%   PARTIAL LIST, and it lists only the fields that can arrive FLAT and so
%   have to be lifted. Working data that is only ever assigned into
%   handles.work directly - the selection, the toolbox path and version, the
%   electrode-numbering table - is not here, because there is nothing to lift.
%   The MNI template surfaces and atlas below are in that situation too since
%   defaultGuiVariables started writing them into the group; they are kept
%   listed because a .iel file could still carry an old flat copy.
%
%   `options` was the last field still flat. It has been split: the settings
%   that decide what is computed are in handles.work.options, and the ones
%   that only change what is shown are in handles.ui.options. Neither is
%   listed here, because neither ever arrives flat - they are built at
%   start-up, not read from a file.
%
%   NOTE ON .iel FILES: unlike most working data, twelve of these ARE written
%   to the project file today, so FLATTENPROJECT puts them back at the top level
%   when saving. Whether they should be saved at all is case 1 in
%   docs/STATE_FIELD_MAPPING.md - a question for the toolbox author, not one
%   this restructuring answers.
%
%   See also PROJECTFIELDNAMES, LIFTTOWORK, FLATTENPROJECT.

names = { ...
    ... % contact coordinates that are not yet an accepted electrode array,
    ... % also used as anchor points ("nailed" contacts) when fitting
    'GS', ...
    ... % which voxel cluster each selected voxel belongs to
    'clusters', ...
    ... % the currently selected voxels and their CT intensities
    'brushCrd', 'brushWeight', ...
    ... % undo copies, restored by the Undo button
    'oldGS', 'oldclusters', 'oldbrushCrd', 'oldbrushWeight', ...
    ... % where the project file came from and where to browse next
    'FileName', 'PathName', ...
    ... % CT intensity limits; recomputed from TAC by checkProjectStructure
    'minValue', 'maxValue', ...
    ... % MNI template surfaces, loaded once at start-up - shared resources,
    ... % identical for every patient, so they are work rather than project
    'v_MNI', 'f_MNI', 'v_MNI_SCE', 'f_MNI_SCE', ...
    ... % MNI probabilistic atlas used for labelling in MNI space
    'MNIlabels', 'MNIprob', 'MNI_S_matrix' ...
    };
end
