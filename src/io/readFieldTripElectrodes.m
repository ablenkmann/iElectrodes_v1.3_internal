function [labels, positions] = readFieldTripElectrodes(fullPath)
%READFIELDTRIPELECTRODES  Read contact labels and positions from a FieldTrip .mat.
%
%   [labels, positions] = readFieldTripElectrodes(fullPath) reads the `elec`
%   structure written by WRITEFIELDTRIPELECTRODES, or by FieldTrip itself,
%   and returns its labels and its elecpos.
%
%   Contacts whose position contains a NaN are dropped, labels included. A
%   FieldTrip structure may describe channels whose location was never
%   determined, and there is nothing to place in a 3-D view for those.
%
%   The coordinates are used as they are - unlike EEGLAB, FieldTrip keeps
%   plain x, y and z.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also WRITEFIELDTRIPELECTRODES, READEEGLABELECTRODES,
%   READELECTRODESTRUCTURE.

% load() warns about the missing variable before this function gets to say
% anything more useful about it, so that warning is turned off and the check
% below reports it instead
wasOn = warning('off', 'MATLAB:load:variableNotFound');
restoreWarnings = onCleanup(@() warning(wasOn));

loaded = load(fullPath, 'elec');

if ~isfield(loaded, 'elec')
    error('readFieldTripElectrodes:notAnElecStructure', ...
        'The file %s does not contain an elec structure.', fullPath);
end

labels    = loaded.elec.label;
positions = loaded.elec.elecpos;

% a contact with an unknown coordinate cannot be placed
incomplete = any(isnan(positions), 2);
positions(incomplete, :) = [];
labels(incomplete)       = [];
end
