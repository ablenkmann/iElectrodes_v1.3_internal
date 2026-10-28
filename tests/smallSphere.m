function [vertices, faces] = smallSphere(centre, radius)
%SMALLSPHERE  A closed surface small enough for BUILDSCE to wrap in a second.
%
%   [vertices, faces] = smallSphere(centre) gives a sphere of radius 15 mm
%   around CENTRE, as a vertex list and a triangulation.
%
%   [vertices, faces] = smallSphere(centre, radius) sets the radius.
%
%   What BUILDSCE costs depends on how much space a surface covers and on
%   the closing radius, not on how many vertices it has: around a brain it
%   takes minutes, and a test that builds four envelopes pays for it four
%   times. A pair of these, with a small options.buildSCEradius, is the same
%   code on a small volume - which is what a test of the layer wants, the
%   algorithm itself being tested elsewhere.

if nargin < 2, radius = 15; end

[x, y, z] = sphere(20);
mesh = surf2patch(radius*x + centre(1), radius*y + centre(2), ...
                  radius*z + centre(3), 'triangles');
[vertices, ~, back] = unique(round(mesh.vertices, 6), 'rows', 'stable');
faces = back(mesh.faces);
faces(faces(:,1) == faces(:,2) | faces(:,2) == faces(:,3) | ...
      faces(:,1) == faces(:,3), :) = [];     % the poles collapse to slivers
end
