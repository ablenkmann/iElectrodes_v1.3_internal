function [labels, positions] = readEEGLABelectrodes(fullPath)
%READEEGLABELECTRODES  Read contact labels and positions from an EEGLAB .set.
%
%   [labels, positions] = readEEGLABelectrodes(fullPath) reads the chanlocs
%   of an EEGLAB dataset and returns the contact labels as a cell array and
%   their coordinates as an Nx3 matrix.
%
%   AXES. EEGLAB stores X, Y and Z in its own convention, and the columns
%   returned here are
%
%       [ -Y   X   Z ]
%
%   which is the inverse of the order iElectrodes writes when exporting -
%   see WRITEEEGLABCOORDINATES, whose help gives the readlocs format string
%   with the same swap. The coordinates in a .set are not iElectrodes
%   coordinates until they have been through this.
%
%   An EEGLAB .set is a MATLAB file, so it is read as one. A file without an
%   EEG structure is refused by name.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also WRITEEEGLABCOORDINATES, READFIELDTRIPELECTRODES,
%   READELECTRODESTRUCTURE.

% load() warns about the missing variable before this function gets to say
% anything more useful about it, so that warning is turned off and the check
% below reports it instead
wasOn = warning('off', 'MATLAB:load:variableNotFound');
restoreWarnings = onCleanup(@() warning(wasOn));

loaded = load(fullPath, 'EEG', '-mat');   % a .set is a MATLAB file

if ~isfield(loaded, 'EEG')
    error('readEEGLABelectrodes:notADataset', ...
        'The file %s does not contain an EEGLAB EEG structure.', fullPath);
end

EEG = loaded.EEG;

labels    = {EEG.chanlocs.labels};
positions = [-[EEG.chanlocs.Y];  [EEG.chanlocs.X];  [EEG.chanlocs.Z] ]';
end
