function handles = liftToProject(handles)
%LIFTTOPROJECT  Move migrated patient-data fields into handles.project.
%
%   handles = liftToProject(handles) takes the fields listed by
%   PROJECTFIELDNAMES from the top level of HANDLES and moves them under
%   HANDLES.project, removing the flat copies so that only one authoritative
%   copy of each value exists.
%
%   Call it right after checkProjectStructure has filled HANDLES from a file
%   or from the empty-project defaults.
%
%   See also PROJECTFIELDNAMES, FLATTENPROJECT.

names = projectFieldNames();

if ~isfield(handles,'project')
    handles.project = struct();
end

for k = 1:numel(names)
    thisField = names{k};
    if isfield(handles, thisField)
        handles.project.(thisField) = handles.(thisField);
        handles = rmfield(handles, thisField);
    end
end
end
