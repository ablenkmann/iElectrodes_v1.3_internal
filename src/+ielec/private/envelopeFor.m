function [vertices, faces] = envelopeFor(space, project, work)
%ENVELOPEFOR  The smooth cortical envelope of a space, or nothing.
%
%   [vertices, faces] = envelopeFor(space, project, work) is
%   SCESURFACEFORSPACE with the "there is none" cases answered instead of
%   run into: the patient's own envelope lives in PROJECT and the MNI
%   template in WORK, and either can be missing - a project whose surfaces
%   have not been built, or a script that never loaded the template the GUI
%   loads at start-up. Both come back as empty VERTICES, which is what
%   SCESURFACEFORSPACE already returns for the first of them.
%
%   The caller decides what that means: IELEC.PROJECTIONSTATE reports it,
%   IELEC.PROJECTARRAYS refuses with ielec:noSurface.
%
%   Private to the ielec package.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also SCESURFACEFORSPACE, IELEC.PROJECTARRAYS.

vertices = [];
faces    = [];

if strcmp(space, 'MNI')
    if ~isstruct(work) || ~isfield(work, 'v_MNI_SCE') || ~isfield(work, 'f_MNI_SCE')
        return
    end
else
    if ~isstruct(project) || ~isfield(project, 'vertices_SCE_L')
        return
    end
end

[vertices, faces] = sceSurfaceForSpace(space, project, work);
end
