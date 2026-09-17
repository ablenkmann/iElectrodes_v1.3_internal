function writeEEGLABcoordinates(fullPath, coordinates)
%WRITEEEGLABCOORDINATES  Write contact coordinates as an EEGLAB location file.
%
%   writeEEGLABcoordinates(fullPath, coordinates) writes one line per contact
%   to FULLPATH, tab separated:
%
%       label    x    y    z
%
%   COORDINATES comes from ELECTRODECOORDINATES, so the same function writes
%   both the localized contacts and their projections - which of the two is
%   decided before the call, not here.
%
%   EEGLAB reads the file with
%
%       EEG.chanlocs = readlocs(file, 'filetype', 'custom', ...
%                               'format', {'labels','-Y','X','Z'})
%
%   Note the axis order in that format string: EEGLAB's own convention, not
%   a transformation applied here. The file holds plain x, y and z.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ELECTRODECOORDINATES, WRITEBIDSELECTRODES.

fid = fopen(fullPath, 'w+');   % overwrite
if fid == -1
    error('writeEEGLABcoordinates:cannotWrite', 'Cannot write to %s', fullPath);
end
closeWhenDone = onCleanup(@() fclose(fid));

for i = 1:numel(coordinates.x)
    fprintf(fid, '%s\t %e\t %e\t %e\n', coordinates.label{i}, ...
        coordinates.x(i), coordinates.y(i), coordinates.z(i));
end
end
