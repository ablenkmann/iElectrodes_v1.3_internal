function handles = liftToUi(handles)
%LIFTTOUI  Move migrated presentation fields into handles.ui.
%
%   handles = liftToUi(handles) takes the fields listed by UIFIELDNAMES from
%   the top level of HANDLES and moves them under HANDLES.ui, removing the
%   flat copies so that only one authoritative copy of each value exists.
%
%   Call it next to LIFTTOPROJECT and LIFTTOWORK, wherever HANDLES has just
%   been filled from a file or from the empty-project defaults.
%
%   See also UIFIELDNAMES, LIFTTOPROJECT, LIFTTOWORK, FLATTENPROJECT.

names = uiFieldNames();

if ~isfield(handles,'ui')
    handles.ui = struct();
end

for k = 1:numel(names)
    thisField = names{k};
    if isfield(handles, thisField)
        handles.ui.(thisField) = handles.(thisField);
        handles = rmfield(handles, thisField);
    end
end
end
