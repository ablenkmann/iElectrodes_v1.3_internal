function [vR, fR, vL, fL] = readSurfacePair(rightFile, leftFile)
%READSURFACEPAIR  Read a right/left pair of cortical surfaces.
%
%   [vR,fR,vL,fL] = readSurfacePair(rightFile, leftFile) returns the
%   vertices and faces of both hemispheres.
%
%   Two formats are accepted, in the order the toolbox has always tried
%   them: FreeSurfer's own binary surface files (.pial,
%   .pial-outer-smoothed) first, and iso2mesh .asc files as a fallback. The
%   fallback is reached by READ_SURF failing, not by looking at the
%   extension, because FreeSurfer surfaces are not named consistently
%   across versions.
%
%   Both hemispheres are read together on purpose: a surface pair that
%   fails halfway leaves the project with one hemisphere from one subject
%   and one from another, which is worse than not loading at all.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also CENTRESURFACES, RESAMPLESURFACE, READ_SURF.

try     % original FreeSurfer files
    [vR,fR] = read_surf(rightFile);
    [vL,fL] = read_surf(leftFile);
catch   % iso2mesh asc files
    [vR,fR] = readasc(rightFile);
    [vL,fL] = readasc(leftFile);
end
end
