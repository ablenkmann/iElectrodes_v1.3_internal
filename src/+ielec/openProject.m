function [project, work, caches] = openProject(project, work, cfg) %#ok<INUSL> project is replaced
%IELEC.OPENPROJECT  Open a project from a .iel file.
%
%   [project, work] = ielec.openProject([], work, cfg) reads the .iel file
%   named in cfg.file and returns its project, and WORK with the file's work
%   in progress in it.
%
%   [project, work, caches] = ielec.openProject([], work, cfg) also returns
%   the colour caches the file carries (wmparcColors, AnnotColor_R,
%   AnnotColor_L), so that a display can use them without computing them
%   again - for a large parcellation that takes seconds.
%
%   Options (cfg):
%     cfg.file   path of the .iel file.                               required
%
%   PROJECT is replaced, so pass []. It is an argument so that every ielec
%   function has the same signature.
%
%   What the file holds is completed by CHECKPROJECTSTRUCTURE, so a file
%   written by an older version comes back with every field the current one
%   expects.
%
%   WORK keeps what is not stored in a file - the processing options, the
%   shared MNI resources - and takes from the file what is: unfinished
%   contacts, selected voxels, clusters and their undo copies, the CT
%   intensity limits. work.FileName and work.PathName are set to the file
%   just opened. The first array and its first contact are selected, and the
%   first planning array and its first target, when there are any. If WORK
%   has no options, the defaults are put in, as after starting iElectrodes.
%
%   The colour caches are display data, so they come back apart from
%   PROJECT and WORK; the layer does not keep them. A file without them gets
%   them computed, as CHECKPROJECTSTRUCTURE has always done.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:noSuchFile, ielec:notAProject, and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.file = fullfile('examples', 'exampleNativeSpace.iel');
%       [project, work] = ielec.openProject([], [], cfg);
%       numel(project.electrodes)
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.SAVEPROJECT, IELEC.COLOURCACHES, READIELFILE,
%   CHECKPROJECTSTRUCTURE, docs/API_LAYER.md.

if isempty(work)
    work = struct();
end
if ~isfield(work, 'options') || isempty(work.options)
    work.options = default_ielectrodes_options([]);
end

cfg = checkCfg(cfg, struct(), {'file'}, 'openProject');
if ~ischar(cfg.file)
    error('ielec:badOption', 'ielec.openProject: cfg.file must be a file name.');
end
if ~isfile(cfg.file)
    error('ielec:noSuchFile', 'ielec.openProject: no such file: %s', cfg.file);
end

try
    s = readIelFile(cfg.file);
catch err
    error('ielec:notAProject', 'ielec.openProject: %s', err.message);
end

% The file's fields, completed, split into project and work. WORK comes in
% so that what the file does not hold - the options, the MNI resources -
% stays; the project starts from nothing, so nothing of a previous project
% can stay behind (see docs/OPEN_QUESTIONS.md item 25).
state.work = work;
state = checkProjectStructure(s, state);
state = liftToProject(state);
state = liftToWork(state);

caches = struct();
for c = uiFieldNames()
    caches.(c{1}) = state.(c{1});   % left flat by checkProjectStructure
end

project = state.project;
names = projectFieldNames();
for k = 1:numel(names)
    if ~isfield(project, names{k})
        project.(names{k}) = [];   % a field the file leaves unset is empty
    end
end

work = state.work;
[folder, name, ext] = fileparts(cfg.file);
if isempty(folder)
    folder = pwd;
end
if folder(end) ~= filesep
    folder = [folder filesep];
end
work.FileName = [name ext];
work.PathName = folder;

hasArrays  = ~isempty(project.electrodes);
hasTargets = ~isempty(project.targets);
work.selection.array          = double(hasArrays);
work.selection.contact        = double(hasArrays);
work.selection.planningArray  = double(hasTargets);
work.selection.planningTarget = double(hasTargets);
end
