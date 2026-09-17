function s = openProject(fullPath)
%OPENPROJECT  Read the structure stored in a .iel file.
%
%   s = openProject(fullPath) returns the flat structure the file holds. Run
%   it through CHECKPROJECTSTRUCTURE to get a project, and through
%   LIFTTOPROJECT, LIFTTOWORK and LIFTTOUI to get the three groups:
%
%       s     = openProject(file);
%       state = checkProjectStructure(s);
%       state = liftToUi(liftToWork(liftToProject(state)));
%
%   A .iel file is a MATLAB v7.3 file holding a single variable named s.
%   Anything else is refused by name: a file that is not a MATLAB file at
%   all, a MATLAB file without that variable, and a path that does not
%   exist. A bare load would leave the caller running with an undefined
%   variable, or report the failure from several frames deeper with no
%   mention of what was being attempted.
%
%   Nothing here opens a figure. The Open button adds a file dialog around
%   this call, and then a great deal of work to show what was read.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also SAVEPROJECT, NEWPROJECT, CHECKPROJECTSTRUCTURE.

if ~isfile(fullPath)
    error('openProject:noSuchFile', 'No such file: %s', fullPath);
end

try
    loaded = load(fullPath, '-mat');
catch err
    % not a MATLAB file at all - load fails before there is anything to look
    % at, so the file is reported here rather than by a stack several frames
    % deeper
    error('openProject:notAProject', ...
        ['%s cannot be read as a project. A .iel file is a MATLAB file ' ...
         'holding a single variable named s.\n         MATLAB said: %s'], ...
        fullPath, err.message);
end

if ~isfield(loaded, 's')
    error('openProject:notAProject', ...
        ['%s does not hold a project. A .iel file contains a single ' ...
         'variable named s; this one contains: %s'], ...
        fullPath, strjoin(fieldnames(loaded)', ', '));
end

s = loaded.s;
end
