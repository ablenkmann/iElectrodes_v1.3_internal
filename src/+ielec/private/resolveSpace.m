function space = resolveSpace(space, project, caller)
%RESOLVESPACE  The coordinate space a call works in - for the ielec layer.
%
%   space = resolveSpace(cfg.space, project, caller) returns 'Native' or
%   'MNI'. An empty value means "the space the project's coordinates are
%   in", project.currentSpace, and 'Native' when even that is missing, as a
%   project with no surfaces starts out.
%
%   Anything else is refused with ielec:badOption, naming CALLER.
%
%   Private to the ielec package.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo

if isempty(space)
    if isstruct(project) && isfield(project, 'currentSpace') && ~isempty(project.currentSpace)
        space = project.currentSpace;
    else
        space = 'Native';
    end
end

if ~ischar(space) || ~ismember(space, {'Native', 'MNI'})
    error('ielec:badOption', ...
        'ielec.%s: cfg.space must be ''Native'' or ''MNI''.', caller);
end
end
