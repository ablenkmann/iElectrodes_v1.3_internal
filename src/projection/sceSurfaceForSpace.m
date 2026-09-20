function [vertices, faces] = sceSurfaceForSpace(space, project, work)
%SCESURFACEFORSPACE  The smooth cortical envelope to project electrodes onto.
%
%   [vertices, faces] = sceSurfaceForSpace(space, project, work)
%
%   Which surface a subdural array is projected onto depends on the space the
%   project is being worked in, and the two surfaces live in different places
%   for a reason:
%
%     'MNI'      a template envelope, the same for every patient, so it is a
%                shared resource and lives in WORK.
%     otherwise  the patient's own envelope, built from their FreeSurfer
%                output, so it is their data and lives in PROJECT - as two
%                hemispheres, which are merged here into one surface.
%
%   That split is the three-structure design doing its job: the same question
%   is answered from WORK or from PROJECT depending on whose surface it is.
%
%   VERTICES comes back empty when the patient's own envelope has not been
%   built yet. The caller decides what to say about that; the MNI branch has
%   never had such a check, because the template ships with the toolbox.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ARRAYPROJECTIONSTATE, ELECTRODES2HULLCORRECTION, BUILDSCE.

switch space
    case 'MNI'
        vertices = work.v_MNI_SCE;
        faces    = work.f_MNI_SCE;

    otherwise   % Native space
        if isempty(project.vertices_SCE_L)
            vertices = [];
            faces    = [];
            return
        end
        [vertices, faces] = mergemesh(project.vertices_SCE_L, project.faces_SCE_L, ...
                                      project.vertices_SCE_R, project.faces_SCE_R);
end
end
