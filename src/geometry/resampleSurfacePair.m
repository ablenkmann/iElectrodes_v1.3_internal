function [vR, fR, vL, fL] = resampleSurfacePair(vR, fR, vL, fL, targetVertices)
%RESAMPLESURFACEPAIR  Reduce a pair of surfaces to a workable vertex count.
%
%   [vR,fR,vL,fL] = resampleSurfacePair(vR,fR,vL,fL,targetVertices) thins
%   both hemispheres towards TARGETVERTICES vertices each, and returns them
%   unchanged if they are already at or below that size.
%
%   The point is drawing speed, not accuracy: a full FreeSurfer surface has
%   well over a hundred thousand vertices, and rotating two of them in a
%   3-D axis is slow enough to be unpleasant. Nothing is measured on these
%   surfaces, so a coarser mesh costs nothing that matters.
%
%   Resampling needs iso2mesh's MESHRESAMPLE. When it is missing or fails,
%   both surfaces are returned at full resolution with a warning, because a
%   slow 3-D view is better than no surfaces. The pair is kept together for
%   the same reason it is read together: one thinned hemisphere beside one
%   full one would be a mismatched pair nobody asked for.
%
%   TARGETVERTICES is a parameter rather than the constant it used to be,
%   so it can become a setting without touching this code. Both callers
%   pass 15000, which is what was hard-coded in each of them.
%
%   The "resampling mesh" message was printed by one of the two callers and
%   not the other; it is printed here, so both behave the same. Thinning two
%   surfaces of well over a hundred thousand vertices takes a few seconds,
%   and saying so beats an interface that looks stuck.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also READSURFACEPAIR, CENTRESURFACES, BUILDSCE.

k = targetVertices / length(vR);

if k >= 1
    return      % already small enough
end

disp('resampling mesh')

try
    [rv, rf] = meshresample(vR, fR, k);
    [lv, lf] = meshresample(vL, fL, k);
    vR = rv; fR = rf;
    vL = lv; fL = lf;
catch
    disp({'WARNING - iso2mesh function meshresample not found or error.'
          'SCE surfaces will not be resampled. 3D view could be slowed down.'})
end
end
