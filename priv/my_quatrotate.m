function rotated_vector = my_quatrotate(quaternion, vector)

% Rotate a 3D vector using a quaternion.
%
% Parameters:
%   vector: A 3D vector to be rotated (e.g., [x, y, z]).
%   quaternion: A quaternion [w, x, y, z].
%
% Returns:
%   rotated_vector: The rotated 3D vector.

% Ensure the input vector is a 3-element vector
if numel(vector) ~= 3
    error('Input vector must be a 3-element vector [x, y, z].');
end

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
rotated_vector = rotation_matrix * vector(:); % Ensure vector is a column vector
rotated_vector = reshape(rotated_vector,size(vector));
end