function trajectory = depthTrajectory(targetIn, targetOut, nContacts, firstSecond, secondLast)
%DEPTHTRAJECTORY  Contacts along a planned depth electrode, from its two ends.
%
%   trajectory = depthTrajectory(targetIn, targetOut, nContacts,
%                                firstSecond, secondLast)
%
%   A planned depth electrode is a straight line through the brain. The
%   surgeon fixes its two ends; everything else about it follows.
%
%     TARGETIN     1-by-3, the deep end - the anatomical target
%     TARGETOUT    1-by-3, the other end, at the entry side
%     NCONTACTS    how many contacts the electrode carries
%     FIRSTSECOND  distance from the 1st contact to the 2nd, in mm
%     SECONDLAST   distance between every later pair, in mm
%
%   Two spacings rather than one because of Behnke-Fried electrodes, whose
%   first gap differs from the rest.
%
%   The result holds everything the planning panel and the 3-D view need:
%
%     .delta        1-by-3 unit vector along the electrode, In towards Out
%     .azimuth      direction of .delta in degrees
%     .elevation    direction of .delta in degrees
%     .distances    how far each contact sits from the first one, in mm
%     .coordinates  nContacts-by-3, where the contacts actually are
%
%   .azimuth and .elevation are not rounded here. The GUI rounds them for
%   display, but what is stored in the project is the full value.
%
%   Two things are preserved from the code this came out of rather than
%   tidied, because they are what the toolbox has always done:
%
%   - If the two ends coincide, .delta is a division by zero and the whole
%     result is NaN rather than an error.
%   - For a single-contact electrode .distances comes back with two entries
%     instead of one. The extra entry is never read: .coordinates has one
%     row, as it should.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also TRAJECTORYENDPOINT, which goes the other way.

delta = (targetOut(:)' - targetIn(:)') / norm(targetOut(:)' - targetIn(:)');

[az, el, ~] = cart2sph(delta(1), delta(2), delta(3));

%convert from radians to degres
az = az * 180/pi;
el = el * 180/pi;

distances = [0 firstSecond firstSecond + ((1:(nContacts-2)) * secondLast)];

coordinates = zeros(nContacts, 3);
for i = 1:nContacts
    coordinates(i,:) = targetIn(:)' + distances(i) * delta;
end

trajectory.delta       = delta;
trajectory.azimuth     = az;
trajectory.elevation   = el;
trajectory.distances   = distances;
trajectory.coordinates = coordinates;
end
