function [alpha, beta, frameDown] = trajectoryFrameAngles(delta, lastContactZ, framePosition)
%TRAJECTORYFRAMEANGLES  The stereotactic frame angles of a planned trajectory.
%
%   [alpha, beta, frameDown] = trajectoryFrameAngles(delta, lastContactZ,
%                                                    framePosition)
%
%   The inverse of FRAMETRAJECTORYENDPOINT: given the direction of a planned
%   depth electrode, the two angles a stereotactic frame would be set to.
%   All angles in degrees - ALPHA from 0 to 90, BETA from 0 to 360.
%
%     DELTA          1-by-3 unit vector along the electrode, from the deep
%                    end outwards (as DEPTHTRAJECTORY returns it)
%     LASTCONTACTZ   z of the electrode's last contact
%     FRAMEPOSITION  how the frame is mounted, e.g. 'Anterior' or 'Posterior'
%
%   FRAMEDOWN is decided here by a rule worth knowing: the frame is taken to
%   point down when the LAST contact lies below z = 0. It is returned
%   because the project stores it with the array.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also FRAMETRAJECTORYENDPOINT, DEPTHTRAJECTORY, DELTA2ALPHA_BETA.

frameDown = lastContactZ < 0;

[alpha, beta] = delta2alpha_beta(delta(1), delta(2), delta(3), framePosition, frameDown);
end
