function writeBIDSelectrodes(fullPath, coordinates)
%WRITEBIDSELECTRODES  Write contacts as a BIDS electrodes.tsv.
%
%   writeBIDSelectrodes(fullPath, coordinates) writes a tab-separated table
%   to FULLPATH with the five columns BIDS requires, in the order it
%   requires them, followed by three of the toolbox's own:
%
%       name  x  y  z  size  Electrode Type  Projection Method  Anatomical Label
%
%   `size` is the contact surface area in mm2, which iElectrodes does not
%   record, so it is written as NaN.
%
%   The three extra columns and their spelling are kept as v1.020 wrote
%   them - see docs/OPEN_QUESTIONS.md item 12, which asks whether they
%   should follow BIDS naming instead.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ELECTRODECOORDINATES, WRITEBIDSCOORDINATESYSTEM.

n = numel(coordinates.x);

elecTable = table(coordinates.label', coordinates.x', coordinates.y', ...
    coordinates.z', nan(n,1), coordinates.type', ...
    coordinates.projectionMethod', coordinates.anatomicalLabel', ...
    'VariableNames', {'name','x','y','z','size', ...
                      'Electrode Type','Projection Method','Anatomical Label'});

writetable(elecTable, fullPath, 'FileType', 'text', 'Delimiter', 'tab');
end
