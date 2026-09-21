function target = newPlanningGrid(centre, rows, cols, eDist, verticesL, verticesR)
%NEWPLANNINGGRID  Build a planning grid laid on the brain at a given centre.
%
%   target = newPlanningGrid(centre, rows, cols, eDist, verticesL, verticesR)
%
%   A planning grid is a simulated subdural grid, placed before surgery to
%   see where a real one would sit. This builds one from scratch: flat,
%   ROWS by COLS contacts EDIST mm apart, laid tangent to the smooth cortical
%   envelope with its centre at CENTRE.
%
%     CENTRE     1-by-3, where the centre of the grid should go
%     ROWS/COLS  grid dimensions
%     EDIST      distance between neighbouring contacts, in mm
%     VERTICESL  vertices of the left-hemisphere envelope
%     VERTICESR  vertices of the right-hemisphere envelope
%
%   The result is a complete planning array, ready to be added to
%   project.targets. It is named 'grid', its contacts 'grid1', 'grid2', ...,
%   and its rotation starts at 0. Unlike PLACEPLANNINGGRID there is no
%   previous grid to take an orientation from, so TANGENTIALGRID chooses one.
%
%   The structure is completed by CHECKELECTRODESTRUCTURE before the
%   geometry is filled in, and the adjacency matrix is built after it - the
%   same order as the code this came from.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also PLACEPLANNINGGRID, TANGENTIALGRID, ELECTRODEFROMGRIDFIT.

options = [];
[pTan, hemisphere] = tangentialGrid(centre, rows, cols, eDist, verticesL, verticesR, options);

% save as a structure
target = [];
target.Type = 'grid';
target.Name = 'grid';
target.planning = 'yes';
target = checkElectrodeStructure(target);

target.x = pTan(:,1);
target.y = pTan(:,2);
target.z = pTan(:,3);
target.rows = rows;
target.columns = cols;
target.nElectrodes = rows*cols;
target.hemisphere = hemisphere;
target.rotation = 0;
target.distance = eDist;

for i = 1:target.nElectrodes
    target.ch_label{i} = [target.Name num2str(i)];
end
% make adjacency Matrix
target.adjMat = makeAdjMat(target.rows, target.columns);
end
