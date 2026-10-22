% IELVIEW  The drawing layer: what the frontend needs in order to show things.
%
% A frontend has to turn the project into pixels, and turn a click back into
% a coordinate. That is not the science and it is not the frontend's own
% layout either - it is a small library of its own, so it lives beside
% src/+ielec/ rather than inside the backend.
%
%   ielview.mixImages            blend the MRI and the CT into one picture
%   ielview.sliceView            one plane of a volume, turned as a view draws it
%   ielview.voxelFromPlaneClick  a click in a 2-D view -> a voxel position
%   ielview.nearestOnRay         a click on a 3-D surface -> a vertex
%
% What belongs here: functions that produce something to display, or read
% something the user pointed at, and that no backend function calls. What
% does not: anything that decides what the data means (the backend), anything
% that changes the project (the ielec layer), and the shared geometry the
% backend itself uses - AnatSpace2Mesh, mesh2AnatSpace, eucDistMat are
% library functions on both sides of the line and stay in src/geometry.
%
% Windows, dialogs, axes and controls are the frontend's; nothing here opens
% one. The functions take values and return values, so the App Designer app
% and the GUIDE GUI can both use them.
%
% Errors raised here carry ielview: identifiers and nothing else, the way
% rule 5 of docs/API_LAYER.md settles the same question for the ielec layer.
% The identifier names the layer, not the function, so a caller can catch
% everything this layer throws without listing it.
%
% See also IELEC, docs/API_LAYER.md.
%
% iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
