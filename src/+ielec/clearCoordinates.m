function [project, work] = clearCoordinates(cfg, project, work)
%IELEC.CLEARCOORDINATES  Throw away the contacts in progress.
%
%   [project, work] = ielec.clearCoordinates(cfg, project, work) empties the
%   coordinates in progress: the contacts, the voxels they were made from,
%   their weights and their cluster numbers. PROJECT gains nothing but the
%   step this records in its history, so the arrays already localized are
%   untouched - this is the way out of a clustering that went wrong, not a
%   way to delete an array.
%
%   Options (cfg):
%     cfg.group   which list to empty: 'contacts', the contacts in progress
%                 and the voxels behind them, or 'anchors', the points that
%                 hold a GridFit.                      Default: 'contacts'
%
%   The previous values go to work.oldGS and the other old fields, so one
%   press of this can be taken back with IELEC.UNDOCOORDINATES.
%
%   What this does NOT clear is the selection the voxels were picked from -
%   work.candidateVoxels and work.selectedVoxels stay, so the same brushed
%   voxels can be clustered again with a different number of contacts
%   without thresholding and brushing them afresh. That is what the button
%   did, and it is the useful half of it.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:badOption (a group that is neither list) and those of the
%   cfg check.
%
%   Example
%       [project, work] = ielec.clearCoordinates([], project, work);
%       isempty(work.GS)
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.UNDOCOORDINATES, IELEC.ADDCOORDINATE,
%            IELEC.REMOVECOORDINATE, IELEC.CLUSTER.

defaults.group = 'contacts';
cfg = checkCfg(cfg, defaults, {}, 'clearCoordinates');

field = coordinateField(cfg.group, 'clearCoordinates');

work = keepForUndo(work);

if strcmp(field, 'GS')
    work.GS          = [];
    work.brushCrd    = [];
    work.brushWeight = [];
    work.clusters    = [];
else
    % the anchors only: there is no clustering behind them to throw away
    work.anchors = [];
end

project = recordStep(project, mfilename, cfg);
end
