function [project, work] = newProject(project, work, cfg) %#ok<INUSL> project is replaced
%IELEC.NEWPROJECT  Start a new, empty project around an MRI.
%
%   [project, work] = ielec.newProject([], work, cfg) reads the MRI named in
%   cfg.mri, reslices it, and returns an empty project built around it,
%   together with WORK emptied of everything that belonged to the previous
%   project.
%
%   Options (cfg):
%     cfg.mri            path of the MRI, a NIfTI file.              required
%     cfg.voxdim         voxel size to reslice to, in mm, 1x3.
%                        Default: work.options.image_voxdim. NaN keeps
%                        the file's own size along that axis.
%     cfg.interpolation  interpolation used for the reslicing, as SPM
%                        numbers it (0 nearest neighbour, 1 trilinear,
%                        2-127 higher-order Lagrange).       Default: 4
%
%   PROJECT is replaced, so pass []. It is an argument so that every ielec
%   function has the same signature.
%
%   WORK keeps what is not tied to a project: the processing options and
%   the shared MNI resources loaded at start-up. What belonged to the
%   previous project - selected voxels, clusters, unfinished contacts, the
%   undo copies, the file name and folder - is emptied, and
%   the selection is set back to nothing selected. If WORK has no options,
%   the defaults are put in, as after starting iElectrodes.
%
%   What an empty project contains is decided by CHECKPROJECTSTRUCTURE, the
%   function that defines the .iel format, so a new project is the same as
%   a project opened from a file with nothing in it.
%
%   Nothing is drawn and no window is opened. The caller keeps its own
%   display state: in the GUI that is handles.ui, which this function
%   never sees.
%
%   Errors: ielec:noSuchFile, ielec:badOption, and those of the cfg check
%   (ielec:badCfg, ielec:unknownOption, ielec:missingOption).
%
%   Example
%       cfg = [];
%       cfg.mri = 'C:\data\patient01\T1.nii';
%       [project, work] = ielec.newProject([], [], cfg);
%       project.electrodes          % empty - nothing localized yet
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also CHECKPROJECTSTRUCTURE, LOADING_IMAGES_SPM, docs/API_LAYER.md.

if isempty(work)
    work = struct();
end
if ~isfield(work, 'options') || isempty(work.options)
    work.options = default_ielectrodes_options([]);
end

defaults.voxdim        = work.options.image_voxdim;
defaults.interpolation = 4;
cfg = checkCfg(cfg, defaults, {'mri'}, 'newProject');

if ~ischar(cfg.mri)
    error('ielec:badOption', 'ielec.newProject: cfg.mri must be a file name.');
end
if ~isfile(cfg.mri)
    error('ielec:noSuchFile', 'ielec.newProject: no such file: %s', cfg.mri);
end

T1 = loading_images_SPM('', cfg.mri, cfg.interpolation, cfg.voxdim);

% An empty project and emptied work, as a file with nothing in it would give.
% checkProjectStructure also gives empty colour caches; those are display
% state and are not returned.
state.work = work;
state = checkProjectStructure([], state);
state = liftToProject(state);
state = liftToWork(state);

project    = state.project;
project.T1 = T1;                       % the MRI, as an SPM volume
project.S2 = T1.vol.mat(1:3,:);        % its image-to-world transformation

work = state.work;
work.selection.array          = 0;     % nothing selected in an empty project
work.selection.contact        = 0;
work.selection.planningArray  = 0;
work.selection.planningTarget = 0;
end
