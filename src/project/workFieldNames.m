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
%   PARTIAL LIST. This first group is the localisation work in progress and
%   its undo history - plain data, no GUI representation, and all eight are
%   already covered by tests/roundtrip_project. The remaining work fields
%   (FileName, PathName, options, minValue, maxValue, the MNI template and
%   atlas resources, uitable_elecNum) come in later groups; some of them need
%   a decision first, because their value currently lives inside a uicontrol.
%   See docs/STATE_FIELD_MAPPING.md for the full classification.
%
%   NOTE ON .iel FILES: unlike most working data, these eight ARE written to
%   the project file today, so FLATTENPROJECT puts them back at the top level
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
    'oldGS', 'oldclusters', 'oldbrushCrd', 'oldbrushWeight' ...
    };
end
