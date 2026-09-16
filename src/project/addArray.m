function [arrays, selected] = addArray(arrays, array, index)
%ADDARRAY  Put an electrode or planning array into the project's list.
%
%   [arrays, selected] = addArray(arrays, array) appends ARRAY to the cell
%   array ARRAYS and returns the index it was given.
%
%   [arrays, selected] = addArray(arrays, array, index) overwrites
%   ARRAYS{INDEX} instead. An empty INDEX means append, so the caller can
%   pass the same variable through either way.
%
%   The project keeps two such lists - project.electrodes, the arrays that
%   were localized, and project.targets, the arrays that were planned. They
%   are added the same way, so both callers use this function.
%
%   SELECTED is the index the array ended up at. The GUI shows that array
%   after the call; a script can use it to reach the array it just added.
%
%   Example
%       [prj.electrodes, n] = addArray(prj.electrodes, e);      % append
%       [prj.electrodes, n] = addArray(prj.electrodes, e, 2);   % replace #2
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also REMOVEARRAY, CHECKELECTRODESTRUCTURE.

if nargin < 3
    index = [];
end

if isempty(index)
    selected = numel(arrays) + 1;
else
    selected = index;
end

arrays{selected} = array;
end
