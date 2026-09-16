function [arrays, selected] = removeArray(arrays, index)
%REMOVEARRAY  Take an electrode or planning array out of the project's list.
%
%   [arrays, selected] = removeArray(arrays, index) removes ARRAYS{INDEX}
%   and returns the shortened list together with the index that should be
%   shown next.
%
%   The rule for what to show next is the part worth having in one place:
%
%     - the array before the one that was removed, if there is one;
%     - otherwise the first array, which is now whatever followed it;
%     - 0 when nothing is left.
%
%   Both lists the project keeps - project.electrodes and project.targets -
%   are removed from the same way, so both callers use this function.
%
%   Example
%       [prj.electrodes, n] = removeArray(prj.electrodes, 2);
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ADDARRAY, CHECKELECTRODESTRUCTURE.

arrays(index) = [];

if isempty(arrays)
    selected = 0;
elseif index-1 > 0
    selected = index-1;
else
    selected = index;
end
end
