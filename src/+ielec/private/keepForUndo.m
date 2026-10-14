function work = keepForUndo(work)
%KEEPFORUNDO  Copy the coordinates in progress aside, so Undo can get them back.
%
%   work = keepForUndo(work) copies work.GS, work.brushCrd, work.brushWeight,
%   work.clusters and work.anchors into work.oldGS, work.oldbrushCrd,
%   work.oldbrushWeight, work.oldclusters and work.oldanchors, replacing
%   whatever was there.
%
%   All five are copied whichever list the caller is about to change, so one
%   Undo takes back the last change to the coordinates in progress whether
%   that was a contact or an anchor. One step, not one step per list: the
%   depth is what IELEC.UNDOCOORDINATES swaps, and a per-list undo is a
%   frontend decision rather than something to invent here.
%
%   Every function that changes the coordinates in progress calls this first,
%   which is what the four buttons did with four lines each. One undo step is
%   kept, not a stack: that is what IELEC.UNDOCOORDINATES swaps back, and the
%   depth of it is a decision for the new frontend rather than something to
%   change while the buttons are being moved.
%
%   Private to the ielec package.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.ADDCOORDINATE, IELEC.REMOVECOORDINATE,
%            IELEC.CLEARCOORDINATES, IELEC.UNDOCOORDINATES.

work.oldGS          = work.GS;
work.oldbrushCrd    = work.brushCrd;
work.oldbrushWeight = work.brushWeight;
work.oldclusters    = work.clusters;
% FIELDOR is a local subfunction in the files that use it, not a shared
% function, and this private has no copy - so ISFIELD. A work built before
% work.anchors existed is treated as having none rather than failing.
if isfield(work, 'anchors')
    work.oldanchors = work.anchors;
else
    work.oldanchors = [];
end
end
