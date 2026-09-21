function [project, work] = loadProject(fullPath)
%LOADPROJECT  Open a .iel project for use from a script: patient data and work.
%
%   [project, work] = loadProject(fullPath)
%
%   The script-side counterpart of the GUI's Open button. It reads the file,
%   completes it with CHECKPROJECTSTRUCTURE - so a file from an older version
%   gets every field the current one expects - and splits it the way the GUI
%   does:
%
%     PROJECT  patient data and accepted results: images, electrodes,
%              planning targets, surfaces, parcellation
%     WORK     work in progress and settings: selected voxels, unfinished
%              contacts, CT intensity limits, and the processing options
%
%   The processing options are not stored in a .iel file. WORK.options holds
%   the defaults from DEFAULT_IELECTRODES_OPTIONS, which is what the GUI has
%   after starting - so a script and a fresh GUI session behave the same.
%
%   The GUI's display caches (annotation colours and the like) are left out;
%   nothing outside the GUI uses them.
%
%   The file itself is not changed. SAVEPROJECT writes a project back.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also SAVEPROJECT, OPENPROJECT, NEWPROJECT, CHECKPROJECTSTRUCTURE.

s = openProject(fullPath);

state = checkProjectStructure(s, struct());
state = liftToProject(state);   % patient data     -> state.project
state = liftToWork(state);      % work in progress -> state.work

project = state.project;
work    = state.work;
work.options = default_ielectrodes_options([]);
end
