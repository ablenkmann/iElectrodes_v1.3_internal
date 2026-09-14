function flat = flattenProject(handles)
%FLATTENPROJECT  Copy the migrated sub-structs back to a flat structure.
%
%   flat = flattenProject(handles) returns a copy of HANDLES in which every
%   field of HANDLES.project and HANDLES.work sits at the top level again,
%   and the two sub-structs themselves are removed.
%
%   This is the inverse of LIFTTOPROJECT and LIFTTOWORK. It exists so that
%   code which still expects the historical flat layout - currently
%   CHECKPROJECTSTRUCTURE, which defines the .iel file format - keeps working
%   unchanged while the in-memory layout migrates around it.
%
%   Both sub-structs are flattened because the .iel file carries both today:
%   besides the patient data it also stores the localisation work in progress
%   and its undo history. That is case 1 in docs/STATE_FIELD_MAPPING.md, and
%   changing it would change the file format, so this function deliberately
%   preserves it.
%
%   Use it only at that boundary. Everywhere else, read the values from
%   handles.project or handles.work directly.
%
%   See also PROJECTFIELDNAMES, WORKFIELDNAMES, LIFTTOPROJECT, LIFTTOWORK.

flat   = handles;
groups = {'project','work'};

for g = 1:numel(groups)
    thisGroup = groups{g};
    if isfield(flat, thisGroup)
        names = fieldnames(flat.(thisGroup));
        for k = 1:numel(names)
            flat.(names{k}) = flat.(thisGroup).(names{k});
        end
        flat = rmfield(flat, thisGroup);
    end
end
end
