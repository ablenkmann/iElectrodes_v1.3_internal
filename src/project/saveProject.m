function saveProject(fullPath, project, work, ui)
%SAVEPROJECT  Write a project to a .iel file.
%
%   saveProject(fullPath, project, work) writes the project to FULLPATH in
%   the .iel format.
%
%   saveProject(fullPath, project, work, ui) also writes the colour caches
%   the file carries. Leave UI out and the file is written without them,
%   which iElectrodes 1.020 cannot open - see UIFIELDNAMES. The GUI always
%   passes it.
%
%   The .iel format is a MATLAB v7.3 file holding a single variable named s,
%   and s is FLAT: every field sits at the top level, the way the toolbox
%   held them before the project/work/ui split. That is deliberate, so that
%   files written here keep opening in older versions and the other way
%   round. FLATTENPROJECT undoes the grouping and CHECKPROJECTSTRUCTURE
%   decides what is worth writing; this function is the boundary where both
%   happen.
%
%   Nothing here opens a figure. The Save button adds a file dialog around
%   this call and nothing else.
%
%   Note that the file name is not folded into what is written: s.FileName
%   and s.PathName carry whatever the project already held, as they did
%   before this was a function.
%
%   Example
%       saveProject(fullfile(pwd,'patient.iel'), prj.project, prj.work, prj.ui);
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also OPENPROJECT, NEWPROJECT, FLATTENPROJECT, CHECKPROJECTSTRUCTURE.

state.project = project;
state.work    = work;
if nargin > 3
    state.ui = ui;
end

s = checkProjectStructure(flattenProject(state));   %#ok<NASGU> .iel stays flat

save(fullPath, 's', '-v7.3');
end
