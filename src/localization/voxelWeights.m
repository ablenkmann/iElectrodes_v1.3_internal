function weight = voxelWeights(CT, S2, coordinates)
%VOXELWEIGHTS  CT intensity of selected voxels, as weights for localization.
%
%   weight = voxelWeights(CT, S2, coordinates)
%
%   Clustering and GridFit both weigh each selected voxel by how bright it
%   is on the CT: brighter voxels are more likely to be the metal of a
%   contact, so they pull the contact centres towards themselves.
%
%     CT           the CT volume, as project.TAC
%     S2           voxel-to-anatomical transform, as project.S2
%     COORDINATES  the selected voxels, one row each, in anatomical space
%     WEIGHT       one weight per voxel: its intensity minus the lowest
%                  intensity in the whole CT, so every weight is >= 0
%
%   The coordinates are turned back into voxel indices by rounding, so a
%   coordinate that is not exactly on a voxel centre takes the voxel it
%   falls in.
%
%   The intensities are converted to double before subtracting, because a
%   CT stored as an integer type would otherwise saturate at 0.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also THRESHOLDCTVOXELS, CLUSTERCONTACTS, GRIDFIT.

TACCords = round(AnatSpace2Mesh(coordinates, S2));
indexTAC = sub2ind(size(CT.img), TACCords(:,1), TACCords(:,2), TACCords(:,3));
weight   = double(CT.img(indexTAC)) - double(min(CT.img(:))); %convert to double to avoid out of range
end
