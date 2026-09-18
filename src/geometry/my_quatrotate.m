function rotated_vector = my_quatrotate(quaternion, vector)

% Rotate one or more 3D vectors using a quaternion.
%
% Parameters:
%   vector: A 3D vector to be rotated (e.g., [x, y, z]), or an M-by-3 array
%           holding one such vector per row.
%   quaternion: A quaternion [w, x, y, z].
%
% Returns:
%   rotated_vector: The rotated vector, or the M-by-3 array of rotated
%                   vectors, with the shape of the input preserved.
%
% This stands in for the Aerospace Toolbox function QUATROTATE, which the
% callers used before and which takes an M-by-3 array. Every caller in this
% toolbox passes one - the ideal positions of a whole depth electrode, one
% contact per row - so the M-by-3 case is the one that is actually used.
% See docs/OPEN_QUESTIONS.md item 14.
%
% The rotation matrix is the one QUATROTATE documents, so a single vector
% gives the same answer here as it did there.

% Normalize the quaternion
quaternion = quaternion / norm(quaternion);

% Extract components of the quaternion
w = quaternion(1);
x = quaternion(2);
y = quaternion(3);
z = quaternion(4);

% Construct the rotation matrix
rotation_matrix = [
    1 - 2 * (y^2 + z^2), 2 * (x * y + z * w), 2 * (x * z - y * w);
    2 * (x * y - z * w), 1 - 2 * (x^2 + z^2), 2 * (y * z + x * w);
    2 * (x * z + y * w), 2 * (y * z - x * w), 1 - 2 * (x^2 + y^2)
    ];

% Rotate the vector
if numel(vector) == 3
    % a single vector, whichever way round it is written
    rotated_vector = rotation_matrix * vector(:); % Ensure vector is a column vector
    rotated_vector = reshape(rotated_vector,size(vector));

elseif ismatrix(vector) && size(vector,2) == 3
    % one vector per row: (R * v')' for every row at once
    rotated_vector = vector * rotation_matrix';

else
    error('my_quatrotate:badVector', ...
        ['Input must be a 3-element vector [x, y, z] or an M-by-3 array of ' ...
         'them, not %s.'], mat2str(size(vector)));
end
end
