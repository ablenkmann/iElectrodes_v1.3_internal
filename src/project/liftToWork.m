function handles = liftToWork(handles)
%LIFTTOWORK  Move migrated working-data fields into handles.work.
%
%   handles = liftToWork(handles) takes the fields listed by WORKFIELDNAMES
%   from the top level of HANDLES and moves them under HANDLES.work, removing
%   the flat copies so that only one authoritative copy of each value exists.
%
%   Call it right after LIFTTOPROJECT, wherever HANDLES has just been filled
%   from a file or from the empty-project defaults.
%
%   See also WORKFIELDNAMES, LIFTTOPROJECT, FLATTENPROJECT.

names = workFieldNames();

if ~isfield(handles,'work')
    handles.work = struct();
end

for k = 1:numel(names)
    thisField = names{k};
    if isfield(handles, thisField)
        handles.work.(thisField) = handles.(thisField);
        handles = rmfield(handles, thisField);
    end
end
end
