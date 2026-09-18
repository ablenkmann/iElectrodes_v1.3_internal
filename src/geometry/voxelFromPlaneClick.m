function voxel = voxelFromPlaneClick(plane, throughPlane, inPlaneValues)
%VOXELFROMPLANECLICK  Turn a click in one 2-D view into a 3-D voxel position.
%
%   voxel = voxelFromPlaneClick(plane, throughPlane, inPlaneValues) returns
%   the [x y z] voxel coordinate a click stands for.
%
%     plane           which view was clicked: 1 for the X view, 2 for the Y
%                     view, 3 for the Z view
%     throughPlane    where that view is currently sliced - the coordinate
%                     the click says nothing about
%     inPlaneValues   the two coordinates the click does give, in ascending
%                     axis order
%
%   A 2-D view fixes one coordinate and lets the user choose the other two.
%   Which two depends on the view, and the answer is always "the other ones":
%
%     X view   click gives  y and z,  x comes from the slider
%     Y view   click gives  x and z,  y comes from the slider
%     Z view   click gives  x and y,  z comes from the slider
%
%   Writing that out three times, once per view, is how it gets written out
%   differently the fourth time.
%
%   Example
%       voxelFromPlaneClick(2, 87, [120 64])   % Y view -> [120 87 64]
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also MESH2ANATSPACE, ANATSPACE2MESH.

if ~ismember(plane, [1 2 3])
    error('voxelFromPlaneClick:badPlane', ...
        'PLANE must be 1, 2 or 3, not %s.', num2str(plane));
end
if numel(inPlaneValues) ~= 2
    error('voxelFromPlaneClick:badValues', ...
        'INPLANEVALUES must hold two coordinates, not %d.', numel(inPlaneValues));
end

voxel        = zeros(1,3);
voxel(plane) = throughPlane;
voxel(setdiff(1:3, plane)) = inPlaneValues;
end
