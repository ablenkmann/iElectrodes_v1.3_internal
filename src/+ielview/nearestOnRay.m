function k = nearestOnRay(vertices, origin, direction, tolerance)
%IELVIEW.NEARESTONRAY  The vertex a view line meets first.
%
%   k = ielview.nearestOnRay(vertices, origin, direction, tolerance)
%
%   VERTICES is N x 3, and may be empty. ORIGIN is a point on the line and
%   DIRECTION a vector along it, which need not be a unit vector. TOLERANCE
%   is how far off the line a vertex may be and still count, in the units of
%   VERTICES; a vertex exactly at the tolerance does not count. It defaults
%   to 3.
%
%     k   the row of VERTICES the line meets first, or empty
%
%   K IS EMPTY WHENEVER THERE IS NOTHING TO PICK
%
%   That is: no vertices at all; no vertex within TOLERANCE of the line;
%   every such vertex behind ORIGIN; or a line that is not finite. The
%   caller gets one answer for "nothing under that click" rather than
%   having to tell four cases apart, and gets no exception for a click that
%   simply missed.
%
%   Part of the ielview drawing layer: numbers for a view to use, no state
%   and nothing scientific decided - see docs/API_LAYER.md rule 8, which
%   lets the frontend call this directly.
%
%   WHY A VERTEX AND NOT AN INTERSECTION
%
%   A click on a 3-D view gives a line through the scene, not a point: the
%   window knows where the line enters and leaves, and the surface is
%   somewhere along it. The exact answer is to intersect the line with every
%   triangle, which for a pial surface is a quarter of a million of them per
%   click.
%
%   A mesh whose faces are about a millimetre across does not need that.
%   The vertices within a few millimetres of the line are the ones the line
%   passes through, and the nearest of those to the eye is the point on the
%   near surface. The error is the size of a face; a contact is larger.
%
%   What picks the near surface rather than the far one is taking the
%   smallest distance along the line, not the largest - without that, a
%   click on a forehead lands on the back of the head and the slice looks
%   plausible. Vertices behind ORIGIN are dropped as well, which matters
%   when ORIGIN is the camera rather than the near face of the axes box.
%
%   Errors: ielview:badVertices, ielview:badRay, ielview:badTolerance.
%
%   Example
%       cp  = ax.CurrentPoint;             % [near; far] on the view line
%       k   = ielview.nearestOnRay(h.Vertices, cp(1,:), diff(cp), 3);
%       if ~isempty(k), point = h.Vertices(k,:); end
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELVIEW.VOXELFROMPLANECLICK, ANATSPACE2MESH.

if isempty(vertices)
    k = [];
    return
end
if ~isnumeric(vertices) || ndims(vertices) ~= 2 || size(vertices, 2) ~= 3 %#ok<ISMAT>
    error('ielview:badVertices', ...
        'ielview.nearestOnRay: vertices must be N by 3.');
end
if ~isnumeric(origin) || numel(origin) ~= 3 || ...
        ~isnumeric(direction) || numel(direction) ~= 3
    error('ielview:badRay', ...
        'ielview.nearestOnRay: origin and direction must each hold three numbers.');
end

origin    = double(origin(:)');
direction = double(direction(:)');

% A line with a NaN in it cannot meet anything, and it reaches here from an
% axes that has not drawn yet rather than from a mistake in the code - so it
% is nothing to pick, not an error to raise in front of the user.
if ~all(isfinite(origin)) || ~all(isfinite(direction))
    k = [];
    return
end

len = norm(direction);
if len == 0
    error('ielview:badRay', ...
        'ielview.nearestOnRay: direction must have a length.');
end
direction = direction / len;

if nargin < 4 || isempty(tolerance)
    tolerance = 3;
end
if ~isnumeric(tolerance) || ~isscalar(tolerance) || ...
        ~isfinite(tolerance) || tolerance <= 0
    error('ielview:badTolerance', ...
        'ielview.nearestOnRay: tolerance must be a positive distance.');
end

w   = double(vertices) - origin;
t   = w * direction';          % how far along the line each vertex lies
off = w - t * direction;       % and how far off it
d2  = sum(off .^ 2, 2);

near = d2 < tolerance ^ 2 & t > 0;   % close to the line, in front of the eye
if ~any(near)
    k = [];
    return
end

t(~near) = inf;
[~, k]   = min(t);             % the first one the line meets
end
