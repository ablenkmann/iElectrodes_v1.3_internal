function flat = flattenProject(handles)
%FLATTENPROJECT  Copy handles.project fields back to a flat structure.
%
%   flat = flattenProject(handles) returns a copy of HANDLES in which every
%   field of HANDLES.project sits at the top level again, and the .project
%   field itself is removed.
%
%   This is the inverse of LIFTTOPROJECT. It exists so that code which still
%   expects the historical flat layout - currently CHECKPROJECTSTRUCTURE,
%   which defines the .iel file format - keeps working unchanged while the
%   in-memory layout migrates around it.
%
%   Use it only at that boundary. Everywhere else, read the values from
%   handles.project directly.
%
%   See also PROJECTFIELDNAMES, LIFTTOPROJECT.

flat = handles;

if isfield(flat,'project')
    names = fieldnames(flat.project);
    for k = 1:numel(names)
        flat.(names{k}) = flat.project.(names{k});
    end
    flat = rmfield(flat,'project');
end
end
