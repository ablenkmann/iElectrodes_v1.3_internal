function work = keepForUndo(work)
%KEEPFORUNDO  Copy the coordinates in progress aside, so Undo can get them back.
%
%   work = keepForUndo(work) copies work.GS, work.brushCrd, work.brushWeight
%   and work.clusters into work.oldGS, work.oldbrushCrd, work.oldbrushWeight
%   and work.oldclusters, replacing whatever was there.
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
end
