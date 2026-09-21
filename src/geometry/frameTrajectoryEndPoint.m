function targetOut = frameTrajectoryEndPoint(targetIn, alpha, beta, framePosition, frameDown, nContacts, firstSecond, secondLast)
%FRAMETRAJECTORYENDPOINT  The far end of a depth electrode, from frame angles.
%
%   targetOut = frameTrajectoryEndPoint(targetIn, alpha, beta, framePosition,
%                                       frameDown, nContacts, firstSecond,
%                                       secondLast)
%
%   The third way of planning a depth electrode, next to clicking both ends
%   (DEPTHTRAJECTORY) and typing azimuth and elevation (TRAJECTORYENDPOINT):
%   the deep end is fixed and the direction is given as the two angles a
%   stereotactic frame is set to.
%
%     TARGETIN       1-by-3, the deep end - the anatomical target
%     ALPHA, BETA    the frame angles, in degrees
%     FRAMEPOSITION  how the frame is mounted, e.g. 'Anterior' or 'Posterior'
%     FRAMEDOWN      true when the frame points down (see TRAJECTORYFRAMEANGLES)
%     NCONTACTS      how many contacts the electrode carries
%     FIRSTSECOND    distance from the 1st contact to the 2nd, in mm
%     SECONDLAST     distance between every later pair, in mm
%
%   The angles become a direction with ALPHA_BETA2DELTA; the length is the
%   same as in TRAJECTORYENDPOINT, first contact to last.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also TRAJECTORYFRAMEANGLES, TRAJECTORYENDPOINT, DEPTHTRAJECTORY,
%   ALPHA_BETA2DELTA.

[dx, dy, dz] = alpha_beta2delta(alpha, beta, framePosition, frameDown);
delta = [dx dy dz];

dist = firstSecond + (nContacts-2) * secondLast; %length from first to last

% estimate xo
targetOut = targetIn(:)' + dist * delta;
end
