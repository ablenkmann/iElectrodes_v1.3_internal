function colours = parcellationColours(parcellationImg, lutFile)
%PARCELLATIONCOLOURS  Colour volume for a FreeSurfer parcellation.
%
%   colours = parcellationColours(parcellationImg) maps every voxel of a
%   parcellation volume to the RGB colour its region is given in the
%   FreeSurfer look-up table, and returns an X-by-Y-by-Z-by-3 array of
%   values in [0 1], ready to index into for display.
%
%   colours = parcellationColours(parcellationImg, lutFile) uses another
%   look-up table. It must hold the variables `values` (region numbers) and
%   `RGB` (0-255 colours, one row per value). The default is the
%   FreeSurferColorLUT.mat shipped in assets/.
%
%   Voxels whose region number is not in the table are given the colour of
%   the table's first entry, which is "unknown".
%
%   This is a display cache, not patient data: it is derived entirely from
%   the parcellation and the table, and can always be recomputed. It exists
%   as a function because the same eight lines used to sit in two places -
%   the Load parcellation button and checkProjectStructure - where they
%   could drift apart unnoticed.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also LOADPARCELLATION, CHECKPROJECTSTRUCTURE.

if nargin < 2 || isempty(lutFile)
    lutFile = 'FreeSurferColorLUT.mat';
end

lut = load(lutFile, 'values', 'RGB');
if ~isfield(lut,'values') || ~isfield(lut,'RGB')
    error('parcellationColours:badLUT', ...
          '%s does not hold both "values" and "RGB".', lutFile);
end

[~, lob] = ismember(int32(parcellationImg), int32(lut.values));
lob(lob == 0) = 1;                       % region not in the table -> unknown

c = lut.RGB(lob,:) / 255;
colours = reshape(c, [size(parcellationImg), 3]);
end
