function writeFieldTripElectrodes(fullPath, coordinates, electrodes, coordinateSystem, projected)
%WRITEFIELDTRIPELECTRODES  Write contacts as a FieldTrip elec structure.
%
%   writeFieldTripElectrodes(fullPath, coordinates, electrodes,
%   coordinateSystem, projected) writes FULLPATH holding a variable `elec`
%   in FieldTrip's electrode format.
%
%     coordinates       from ELECTRODECOORDINATES - what goes in elec.elecpos
%     electrodes        the arrays themselves, needed for the adjacency
%                       matrix, which is a property of the arrays rather
%                       than of the flat contact list
%     coordinateSystem  the project's currentSpace, 'Native' or 'MNI'
%     projected         'Yes' or 'No', recorded in elec.cfg.projection
%
%   Units are written as mm, which is what the toolbox works in throughout.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ELECTRODECOORDINATES, CONCATENATEADJMAT, ELECTRODES2NEIGHBOURSFTFORMAT.

elec.label    = coordinates.label';
elec.elecpos  = [coordinates.x', coordinates.y', coordinates.z'];
% elec.chanpos = [];
% elec.tra     = [];   combination to make channels
elec.unit     = 'mm';
elec.coordsys = coordinateSystem;
elec.adjMat   = concatenateAdjMat(electrodes);   % Adjacency Matrix

elec.cfg.method     = 'iElectrodes';
elec.cfg.projection = projected;

save(fullPath, 'elec');
end
