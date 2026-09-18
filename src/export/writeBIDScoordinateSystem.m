function writeBIDScoordinateSystem(fullPath, intendedFor, processingDescription, processingReference)
%WRITEBIDSCOORDINATESYSTEM  Write the BIDS coordinate-system json.
%
%   writeBIDScoordinateSystem(fullPath, intendedFor, processingDescription,
%   processingReference) writes the json that belongs next to a BIDS
%   electrodes.tsv, describing what the coordinates in it mean.
%
%     intendedFor             the image the coordinates came from
%     processingDescription   what was done to them - 'none' for contacts as
%                             localized, the projection method otherwise
%     processingReference     the paper to cite for that processing
%
%   TWO KEY NAMES WERE CORRECTED HERE, not in v1.020, which wrote them as
%   `IndendedFor` and `iEEGCoordinateProcessingDescripton`. BIDS spells them
%   `IntendedFor` and `iEEGCoordinateProcessingDescription`, so a validator
%   ignored both fields in every json this toolbox wrote before now. A script
%   that reads the old spellings will stop finding them.
%
%   THE TEXT IS ALSO WRITTEN WITH A FORMAT SPECIFIER now. v1.020 called
%   fprintf(fid, text) with no '%s', so backslashes and percent signs in the
%   text were read as format escapes: on Windows, where intendedFor is a path
%   like C:\temp\new.nii, the \t and \n became a tab and a newline and the
%   file was not valid json.
%
%   STILL OPEN: the value of IntendedFor. BIDS wants a URI relative to the
%   dataset; what is written is the absolute path the CT had on the machine
%   where the project was made, because iElectrodes does not know where the
%   dataset root is. See docs/OPEN_QUESTIONS.md item 12.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also WRITEBIDSELECTRODES.

coordSys = struct( ...
    'iEEGCoordinateSystem', 'ScanRAS', ...
    'iEEGCoordinateUnits', 'mm', ...
    'IntendedFor', intendedFor, ...
    'iEEGCoordinateSystemDescription', 'Coordinates system is RAS from imported CT image.', ...
    'iEEGCoordinateProcessingDescription', processingDescription, ...
    'iEEGCoordinateProcessingReference', processingReference);

fid = fopen(fullPath, 'w');
if fid == -1
    error('writeBIDScoordinateSystem:cannotWrite', 'Cannot write to %s', fullPath);
end
encodedJSON = jsonencode(coordSys);
fprintf(fid, '%s', encodedJSON);   % '%s', so a Windows path is not an escape
fclose(fid);
end
