function varargout = centreSurfaces(volumeSize, S2, varargin)
%CENTRESURFACES  Shift surfaces to the centre of an image volume.
%
%   [vR,vL] = centreSurfaces(volumeSize, S2, vR, vL) moves each set of
%   vertices by the anatomical position of the volume's centre voxel, so
%   that surfaces stored relative to their own origin line up with the
%   patient's MRI. Any number of vertex arrays may be passed and are
%   returned in the same order.
%
%   VOLUMESIZE is the voxel size of the MRI, size(T1.img). S2 is the
%   project's image-to-world transformation.
%
%   The toolbox used to read the size from handles.ui.imgW, the fused
%   MRI+CT picture built for display. That works, because the fused image
%   is built on the MRI's grid - but it makes a geometric correction depend
%   on something that exists only to be looked at, and it breaks silently
%   if the display image is ever built differently. The size is now passed
%   in from the MRI itself.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also READSURFACEPAIR, MESH2ANATSPACE.

trans = mesh2AnatSpace(volumeSize/2, S2);

varargout = cell(1, numel(varargin));
for k = 1:numel(varargin)
    v = varargin{k};
    varargout{k} = v + repmat(trans, size(v,1), 1);
end
end
