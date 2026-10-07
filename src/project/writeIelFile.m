function writeIelFile(fullPath, project, work, ui)
%WRITEIELFILE  Write a project to a .iel file.
%
%   writeIelFile(fullPath, project, work) writes the project to FULLPATH in
%   the .iel format.
%
%   writeIelFile(fullPath, project, work, ui) takes the colour caches the
%   file carries from UI, as the GUI does. Leave UI out - as a script does -
%   and the annotation colours are computed from the project with
%   ANNOTATIONCOLOURS, the function the GUI itself uses when annotations are
%   loaded. Either way the file is complete, and iElectrodes 1.020 can open
%   it; see UIFIELDNAMES.
%
%   This was not always so: the help used to say a file without UI would
%   simply lack the colours, but for any project with cortical annotations
%   CHECKPROJECTSTRUCTURE requires them, and the save failed with
%   "Unrecognized field name AnnotColor_R". Nothing had ever saved without UI
%   before, so it had never shown. It was the first headless example that
%   found it; that example now passes the UI it was given when the project
%   was opened, so the branch is exercised by TEST_SCRIPTENTRYPOINTS and
%   TEST_SESSIONSTATE instead.
%
%   The file carries two fields iElectrodes 1.020 never wrote: PROJECT.history,
%   the cfg of every ielec call that changed the project, and schemaVersion,
%   stamped here as 2. Both are ignored by 1.020, which asks isfield for the
%   fields it wants rather than enumerating what it was given -
%   TEST_IELFORMAT runs 1.020's own reading code on a file written here to
%   check that, rather than taking it on trust.
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
%       writeIelFile(fullfile(pwd,'patient.iel'), prj.project, prj.work, prj.ui);
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also LOADPROJECT, READIELFILE, NEWPROJECT, FLATTENPROJECT,
%   CHECKPROJECTSTRUCTURE, ANNOTATIONCOLOURS.

state.project = project;
state.work    = work;
if nargin > 3
    state.ui = ui;
else
    % no GUI: derive the caches the file needs from the patient data
    state.ui = struct();
    state.ui.AnnotColor_R = surfaceColours(project, 'R');
    state.ui.AnnotColor_L = surfaceColours(project, 'L');
end

s = checkProjectStructure(flattenProject(state));   % .iel stays flat

% The format this file is written in. It goes on AFTER the structure check,
% which builds s from the fields it knows and would drop anything else.
% Nothing reads it yet: it is here so that a later version can tell what it
% is looking at, and 1.020 ignores it - it asks isfield for the fields it
% wants and never enumerates what it was given. Note that this STAMPS rather
% than preserves: a file carrying a higher version opens here (the structure
% check drops the field with everything else it does not know) and is written
% back as 2, along with whatever this version understood of it.
s.schemaVersion = 2;

save(fullPath, 's', '-v7.3');
end

% ---------------------------------------------------------------------
function colours = surfaceColours(project, side)
% The colour of each vertex of one hemisphere's pial surface: from its
% annotation when there is one, otherwise grey - the same grey
% CHECKPROJECTSTRUCTURE gives a surface without annotation.
labels = fieldOr(project, ['AnnotLabel_' side], []);
if ~isempty(labels)
    colours = annotationColours(labels, project.(['AnnotColortable_' side]));
else
    colours = ones(length(fieldOr(project, ['vertices' side], [])), 3) * .5;
end
end

function value = fieldOr(s, name, default)
if isfield(s, name), value = s.(name); else, value = default; end
end
