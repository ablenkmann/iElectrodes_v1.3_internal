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
%   THE KEY NAMES BELOW ARE WRONG ON PURPOSE. BIDS calls them `IntendedFor`
%   and `iEEGCoordinateProcessingDescription`; v1.020 wrote them as
%   `IndendedFor` and `iEEGCoordinateProcessingDescripton`, so a validator
%   ignores both fields. Correcting the spelling changes what the toolbox
%   writes, so it is left for a dedicated commit - see
%   docs/OPEN_QUESTIONS.md item 12, which also covers the value of
%   IntendedFor and the escape problem noted below.
%
%   ALSO PRESERVED: the json is written with fprintf(fid, text) rather than
%   fprintf(fid, '%s', text), so backslashes and percent signs in the text
%   are read as format escapes. On Windows, where intendedFor is a path like
%   C:\temp\new.nii, \t and \n become a tab and a newline and the file is
%   corrupted. Same item 12.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also WRITEBIDSELECTRODES.

coordSys = struct( ...
    'iEEGCoordinateSystem', 'ScanRAS', ...
    'iEEGCoordinateUnits', 'mm', ...
    'IndendedFor', intendedFor, ...
    'iEEGCoordinateSystemDescription', 'Coordinates system is RAS from imported CT image.', ...
    'iEEGCoordinateProcessingDescripton', processingDescription, ...
    'iEEGCoordinateProcessingReference', processingReference);

fid = fopen(fullPath, 'w');
if fid == -1
    error('writeBIDScoordinateSystem:cannotWrite', 'Cannot write to %s', fullPath);
end
encodedJSON = jsonencode(coordSys);
fprintf(fid, encodedJSON);   %#ok<CTPCT> kept as v1.020 wrote it - see above
fclose(fid);
end
