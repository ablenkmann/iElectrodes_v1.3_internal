function writeElectrodeStructure(fullPath, electrodes)
%WRITEELECTRODESTRUCTURE  Save the electrode arrays as an iElectrodes .mat.
%
%   writeElectrodeStructure(fullPath, electrodes) writes ELECTRODES to
%   FULLPATH under the variable name `electrodes`, which is what the Load
%   Electrodes button expects to find.
%
%   This is the one export that keeps everything: the arrays exactly as the
%   project holds them, including projections, labels and adjacency. The
%   other formats flatten the arrays into a list of contacts and keep only
%   what that format defines.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also WRITEEEGLABCOORDINATES, WRITEFIELDTRIPELECTRODES, WRITEBIDSELECTRODES.

save(fullPath, 'electrodes');
end
