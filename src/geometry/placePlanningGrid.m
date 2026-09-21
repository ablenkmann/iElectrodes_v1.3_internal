function target = placePlanningGrid(target, centre, rotation, verticesL, verticesR)
%PLACEPLANNINGGRID  Lay an existing planning grid on the brain at a new centre.
%
%   target = placePlanningGrid(target, centre, rotation, verticesL, verticesR)
%
%   A planning grid is a simulated subdural grid: flat, laid tangent to the
%   smooth cortical envelope. This moves one to a new place on that surface
%   and lays it down again, keeping the orientation it already had.
%
%     TARGET     the planning grid, as stored in project.targets
%     CENTRE     1-by-3, where the centre of the grid should go
%     ROTATION   extra turn about the centre, in degrees; [] for none
%     VERTICESL  vertices of the left-hemisphere envelope
%     VERTICESR  vertices of the right-hemisphere envelope
%
%   The planning panel uses it three ways: the six arrow buttons move the
%   centre 1 mm along one axis, the two rotate buttons keep the centre and
%   turn the grid by 5 degrees, and "change centre" moves it to the cursor.
%
%   ROTATION must be [] for no rotation, not 0. TANGENTIALGRID skips the
%   rotation step entirely for [], and that is what the buttons have always
%   done; a 0 would run the rotation code for nothing.
%
%   The grid is laid down afresh rather than shifted, so its contacts follow
%   the curvature of the surface at the new place. Anything computed from the
%   old position no longer applies: .hemisphere is recomputed, and
%   .projection is cleared.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also NEWPLANNINGGRID, TANGENTIALGRID.

X = [target.x target.y target.z];

options = [];
options.previousGrid = X;
if ~isempty(rotation)
    options.additionalRotation = rotation;
end

[pTan, hemisphere] = tangentialGrid(centre, target.rows, target.columns, target.distance, ...
                                    verticesL, verticesR, options);

target.x = pTan(:,1);
target.y = pTan(:,2);
target.z = pTan(:,3);
target.hemisphere = hemisphere;
target.projection = {};
target = checkElectrodeStructure(target);
end
