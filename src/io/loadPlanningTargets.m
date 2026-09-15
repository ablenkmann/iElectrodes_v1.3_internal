function targets = loadPlanningTargets(fileName)
%LOADPLANNINGTARGETS  Read a planning structure from a .mat file.
%
%   targets = loadPlanningTargets(fileName) returns the planning targets
%   stored in FILENAME by SAVEPLANNINGTARGETS or by the toolbox's Save
%   planning button.
%
%   The GUI's Load planning button is this call with a file dialog around
%   it, followed by a redraw.
%
%   A file that does not hold a variable called "targets" is reported as
%   such. The button used to reach this case as an "Unrecognized variable"
%   error several lines later, once the missing value was assigned into the
%   project - the same failure, named at the point where it can be
%   understood.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also SAVEPLANNINGTARGETS, CHECKELECTRODESTRUCTURE.

if ~isfile(fileName)
    error('loadPlanningTargets:notFound', ...
          'Planning file not found: %s', fileName);
end

loaded = load(fileName, 'targets');

if ~isfield(loaded, 'targets')
    error('loadPlanningTargets:noTargets', ...
          ['%s does not contain a variable called "targets", so it is not ' ...
           'a planning file written by iElectrodes.'], fileName);
end

targets = loaded.targets;
end
