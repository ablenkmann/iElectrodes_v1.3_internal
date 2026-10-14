function [project, work] = undoCoordinates(cfg, project, work)
%IELEC.UNDOCOORDINATES  Take back the last change to the contacts in progress.
%
%   [project, work] = ielec.undoCoordinates(cfg, project, work) swaps the
%   coordinates in progress with the copy kept before the last change to
%   them. PROJECT gains nothing but the step this records in its history.
%
%   Options (cfg): none. Pass [].
%
%   It is a swap, not a stack: one step is kept, and calling this twice puts
%   back what you had. That is what the Undo button has always done, and the
%   reason it is a swap rather than a pop is that there is nowhere to pop
%   from - IELEC.ADDCOORDINATE, IELEC.REMOVECOORDINATE,
%   IELEC.CLEARCOORDINATES, IELEC.CLUSTER and IELEC.FITARRAY each overwrite
%   the one copy before they change anything. How deep an undo should be is
%   a question for the new frontend; this keeps the depth the toolbox has.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: those of the cfg check.
%
%   Example
%       [project, work] = ielec.undoCoordinates([], project, work);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.ADDCOORDINATE, IELEC.REMOVECOORDINATE,
%            IELEC.CLEARCOORDINATES, IELEC.CLUSTER, IELEC.FITARRAY.

cfg = checkCfg(cfg, struct(), {}, 'undoCoordinates');

% A work built before the anchors existed has neither side of that pair, and
% the swap below reads both directly. Normalising them to empty here is what
% CHECKPROJECTSTRUCTURE does for a real project anyway.
if ~isfield(work, 'anchors'),    work.anchors    = []; end
if ~isfield(work, 'oldanchors'), work.oldanchors = []; end

% The four swaps the button made, and the anchors with them: KEEPFORUNDO
% copies all five whichever list was about to change, so one Undo takes back
% one change wherever it was made.
for f = {{'GS', 'oldGS'}, {'brushCrd', 'oldbrushCrd'}, ...
         {'brushWeight', 'oldbrushWeight'}, {'clusters', 'oldclusters'}, ...
         {'anchors', 'oldanchors'}}
    current = f{1}{1};
    before  = f{1}{2};
    keep = work.(current);
    work.(current) = work.(before);
    work.(before)  = keep;
end

project = recordStep(project, mfilename, cfg);
end
