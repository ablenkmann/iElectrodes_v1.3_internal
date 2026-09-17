function electrodes = readElectrodeStructure(fullPath)
%READELECTRODESTRUCTURE  Read electrode arrays from an iElectrodes .mat.
%
%   electrodes = readElectrodeStructure(fullPath) reads the file written by
%   WRITEELECTRODESTRUCTURE and returns the arrays as a cell array, checked
%   by CHECKELECTRODESTRUCTURE.
%
%   Old files hold a struct array rather than a cell array of structs. Those
%   are converted here, so callers only ever see one shape.
%
%   The file must contain a variable named `electrodes`; anything else is
%   refused by name rather than leaving the caller with nothing.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also WRITEELECTRODESTRUCTURE, READFIELDTRIPELECTRODES,
%   READEEGLABELECTRODES, CHECKELECTRODESTRUCTURE.

% load() warns about the missing variable before this function gets to say
% anything more useful about it, so that warning is turned off and the check
% below reports it instead
wasOn = warning('off', 'MATLAB:load:variableNotFound');
restoreWarnings = onCleanup(@() warning(wasOn));

loaded = load(fullPath, 'electrodes');

if ~isfield(loaded, 'electrodes')
    error('readElectrodeStructure:notElectrodes', ...
        'The file %s does not contain an electrodes structure.', fullPath);
end

electrodes = loaded.electrodes;

% a struct array becomes a cell array of structs
if isstruct(electrodes)
    asStructArray = electrodes;
    electrodes = cell(1, length(asStructArray));
    for i = 1:length(asStructArray)
        electrodes{i} = asStructArray(i);
    end
end

electrodes = checkElectrodeStructure(electrodes);
end
