function state = newProject(state, T1)
%NEWPROJECT  Reset a project to empty, around a newly loaded MRI.
%
%   state = newProject(state, T1) empties STATE's project, work and ui
%   groups and puts the MRI volume T1 in the project, together with the
%   image-to-world transformation derived from it. It returns STATE.
%
%   STATE is any structure that carries the three groups - in the GUI that
%   is `handles`, in a script it can be an empty struct. Only the three
%   groups are touched; anything else STATE carries is left alone, which is
%   what lets the GUI pass its whole handles structure through.
%
%   What "empty" means is decided by CHECKPROJECTSTRUCTURE, the same
%   function that defines the .iel file format. A new project is therefore a
%   project read from a file that has nothing in it, which is the point: one
%   definition of what a project is, used by both paths.
%
%   Shared resources already in STATE.work - the MNI template surfaces, the
%   probabilistic atlas - survive, because an empty project has nothing to
%   put in their place. Graphics already in STATE.ui survive for the same
%   reason.
%
%   T1 is an SPM-style volume as LOADING_IMAGES_SPM returns it: T1.img holds
%   the voxels and T1.vol.mat the transformation.
%
%   Example
%       T1    = loading_images_SPM(pathName, fileName, 4, voxdim);
%       state = newProject(struct(), T1);
%       state.project.electrodes      % {} - nothing localized yet
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also OPENPROJECT, SAVEPROJECT, CHECKPROJECTSTRUCTURE.

state = checkProjectStructure([], state);
state = liftToProject(state);   % patient data     -> state.project
state = liftToWork(state);      % work in progress -> state.work
state = liftToUi(state);        % colour caches    -> state.ui

state.project.T1 = T1;                     % MRI T1 original (SPM structure)
state.project.S2 = T1.vol.mat(1:3,:);
end
