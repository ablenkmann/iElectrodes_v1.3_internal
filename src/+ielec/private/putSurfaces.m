function project = putSurfaces(project, target, vR, fR, vL, fL)
%PUTSURFACES  Store a right/left surface pair in the project - for ielec.
%
%   project = putSurfaces(project, target, vR, fR, vL, fL) writes the pair
%   into the fields TARGET names: 'pial' into verticesR/facesR/verticesL/
%   facesL, 'envelope' into vertices_SCE_R and the three beside it.
%
%   The project keeps the two pairs in differently named fields rather than
%   in one structure with a kind, which is why this exists in one place.
%
%   Private to the ielec package.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.LOADSURFACES, IELEC.BUILDENVELOPE, SCESURFACEFORSPACE.

switch target
    case 'pial'
        project.verticesR = vR;
        project.facesR    = fR;
        project.verticesL = vL;
        project.facesL    = fL;

    case 'envelope'
        project.vertices_SCE_R = vR;
        project.faces_SCE_R    = fR;
        project.vertices_SCE_L = vL;
        project.faces_SCE_L    = fL;

    otherwise
        % unreachable through the layer, and loud rather than silent if the
        % day comes: storing nothing looks exactly like a load that worked
        error('ielec:badOption', ...
            'putSurfaces: %s is not a pair of surfaces the project keeps.', target);
end
end
