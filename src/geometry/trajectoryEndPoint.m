function targetOut = trajectoryEndPoint(targetIn, azimuth, elevation, nContacts, firstSecond, secondLast)
%TRAJECTORYENDPOINT  The far end of a depth electrode, from a direction.
%
%   targetOut = trajectoryEndPoint(targetIn, azimuth, elevation, nContacts,
%                                  firstSecond, secondLast)
%
%   The other way of planning a depth electrode. Instead of clicking both
%   ends, the surgeon fixes the deep end and types the direction; where the
%   last contact lands then follows from how long the electrode is.
%
%     TARGETIN     1-by-3, the deep end - the anatomical target
%     AZIMUTH      direction of the electrode, in degrees
%     ELEVATION    direction of the electrode, in degrees
%     NCONTACTS    how many contacts the electrode carries
%     FIRSTSECOND  distance from the 1st contact to the 2nd, in mm
%     SECONDLAST   distance between every later pair, in mm
%
%   The length is firstSecond + (nContacts-2)*secondLast, which is the
%   distance from the first contact to the last - so TARGETOUT is where the
%   last contact sits, not where the electrode enters the skull.
%
%   This is the inverse of DEPTHTRAJECTORY: feeding its .azimuth and
%   .elevation back in returns the TARGETOUT it started from, and
%   tests/test_depthTrajectory.m checks exactly that.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also DEPTHTRAJECTORY.

%convert degres to radians
az = azimuth   * pi/180;
el = elevation * pi/180;

[dx, dy, dz] = sph2cart(az, el, 1); %radius=1
delta = [dx dy dz];

dist = firstSecond + (nContacts-2) * secondLast; %length from first to last

targetOut = targetIn(:)' + dist * delta;
end
