function [img, lims, aspect] = sliceView(volume, plane, index, voxdim)
%IELVIEW.SLICEVIEW  One plane of a volume, oriented as the 2-D views show it.
%
%   [img, lims, aspect] = ielview.sliceView(volume, plane, index, voxdim)
%
%   VOLUME is the image, either 3-D (grey) or 4-D with colour channels (what
%   IELVIEW.MIXIMAGES returns). PLANE is 1, 2 or 3 - the dimension that is
%   held fixed - and INDEX is where on it the slice is taken. VOXDIM is the
%   three voxel sizes in mm, which only the aspect ratio uses.
%
%     img      the slice, turned the way a view draws it
%     lims     [xlim; ylim] for the axes
%     aspect   DataAspectRatio for the axes
%
%   Part of the ielview drawing layer: pixels and numbers for a view to
%   use, no state and nothing scientific decided - see docs/API_LAYER.md
%   rule 8, which lets the frontend call this directly.
%
%   WHY THIS IS A FUNCTION AND NOT THREE LINES IN A CALLBACK
%
%   The three outputs have to agree with each other, and they are what a
%   view needs before it can draw a plane at all. A slice comes out of
%   MATLAB with its first dimension down the screen, so it is transposed;
%   the limits say how far the two in-plane dimensions run; and the aspect
%   ratio carries the two in-plane voxel sizes, without which a 0.9 mm
%   slice drawn on a 1 mm grid is subtly the wrong shape. Getting one of
%   the three right and another wrong gives a picture that still looks like
%   a brain.
%
%   They are what electrodes_gui.m's updateTAC does inline at lines 1730 and
%   1739-1741: fliplr(rot90(img,3)), the limits from the two in-plane sizes,
%   and the two in-plane voxel sizes in the aspect ratio. Reproduced rather
%   than redesigned, because the old views are what people have been reading.
%
%   WHAT THE TURN IS, AND WHAT IT IS NOT
%
%   fliplr(rot90(img,3)) is exactly a transpose - the rotation and the flip
%   undo each other's handedness - so this function performs no left-right
%   mirror. The mirror a reader sees comes from XDir 'reverse' on the axes,
%   which is the caller's to set and is why the example below sets it. A
%   left-right mirror in an image a surgeon reads does not announce itself,
%   so it is worth knowing which line of code owns it: not this one.
%
%   The caller still has to set the axes:
%
%       [img, lims, aspect] = ielview.sliceView(imgW, 3, z, voxdim);
%       image(ax, img);
%       ax.XLim = lims(1,:);  ax.YLim = lims(2,:);
%       ax.DataAspectRatio = aspect;
%       ax.YDir = 'normal';   ax.XDir = 'reverse';
%
%   TWO DELIBERATE DIFFERENCES FROM THE OLD INLINE CODE
%
%   The old code took the limits from size(project.T1.img); this takes them
%   from the volume it was handed, which is the same thing whenever the
%   volume shares the MRI's grid, and is right rather than assumed when it
%   does not.
%
%   The old code had no abs() on the voxel sizes. A negative one comes from
%   a flipped affine and is a size, not a direction; MATLAB refuses a
%   negative DataAspectRatio outright, so the old code would have errored
%   where this returns a usable aspect ratio.
%
%   Errors: ielview:badPlane, ielview:badIndex, ielview:badVoxdim.
%
%   Example
%       [p, w] = ielec.openProject(struct('file', f), [], []);
%       mixed  = ielview.mixImages(single(p.T1.img), [], 0, opt);
%       mid    = round(size(p.T1.img, 3) / 2);
%       img    = ielview.sliceView(mixed, 3, mid, diag(p.S2(:,1:3))');
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELVIEW.MIXIMAGES, IMAGE, IMAGESC.

if ~isnumeric(plane) || ~isscalar(plane) || ~ismember(plane, 1:3)
    error('ielview:badPlane', ...
        'ielview.sliceView: plane must be 1, 2 or 3.');
end

% size() drops trailing singleton dimensions, so a volume with one slice
% comes back as 2-D and size(volume) would be two numbers. Asking for three
% dimensions by name gives three, and a volume one slice thick keeps working
% - as it did when this was inline.
D = size(volume, 1:3);

if ~isnumeric(index) || ~isscalar(index) || ~isfinite(index) || ...
        index < 1 || index > D(plane) || mod(index, 1) ~= 0
    error('ielview:badIndex', ...
        'ielview.sliceView: index must be a whole number in 1..%d for plane %d.', ...
        D(plane), plane);
end

if nargin < 4 || isempty(voxdim)
    voxdim = [1 1 1];
end
if ~isnumeric(voxdim) || numel(voxdim) ~= 3 || ...
        ~all(isfinite(voxdim)) || any(voxdim == 0)
    % Without this the aspect ratio comes back as Inf and the caller fails
    % on ax.DataAspectRatio, several lines away from the cause.
    error('ielview:badVoxdim', ...
        'ielview.sliceView: voxdim must be three finite non-zero voxel sizes.');
end
voxdim = abs(voxdim(:)');

inPlane = setdiff(1:3, plane);   % p=1 -> [2 3], p=2 -> [1 3], p=3 -> [1 2]

% the slice: everything on the two dimensions that remain, one position on
% the third. RESHAPE rather than SQUEEZE, because squeeze removes every
% singleton it finds - including an in-plane dimension of one, which would
% take the colour channels along with it and hand back a grey strip.
idx        = {':', ':', ':'};
idx{plane} = index;
nChannels  = size(volume, 4);
if nChannels > 1
    img = reshape(volume(idx{:}, :), D(inPlane(1)), D(inPlane(2)), nChannels);
else
    img = reshape(volume(idx{:}),    D(inPlane(1)), D(inPlane(2)));
end

% the turn - a transpose, for the reason in the help above
img = fliplr(rot90(img, 3));

lims   = [0 D(inPlane(1)); 0 D(inPlane(2))];
aspect = [1/voxdim(inPlane(1)), 1/voxdim(inPlane(2)), 1];
end
