function savePlanningTargets(targets, fileName)
%SAVEPLANNINGTARGETS  Write a planning structure to a .mat file.
%
%   savePlanningTargets(targets, fileName) stores TARGETS in FILENAME under
%   the variable name "targets", which is the name LOADPLANNINGTARGETS and
%   the toolbox's Load planning button expect to find.
%
%   The GUI's Save planning button is this call with a file dialog around
%   it. Keeping the write here means a script can produce planning files
%   the toolbox can open, without going through the interface.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also LOADPLANNINGTARGETS, CHECKELECTRODESTRUCTURE.

if isempty(targets)
    error('savePlanningTargets:empty', ...
          'There are no planning targets to save.');
end

save(fileName, 'targets');
end
