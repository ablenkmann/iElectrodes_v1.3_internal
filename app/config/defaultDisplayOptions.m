function options=defaultDisplayOptions(options)
%DEFAULTDISPLAYOPTIONS  Settings that change what is shown, not what is computed.
%
%   options = defaultDisplayOptions(options) fills in the display settings
%   that are missing from OPTIONS and returns it. Call it with [] for the
%   defaults.
%
%   These belong to handles.ui.options. Changing any of them changes what
%   appears on screen and nothing else: no coordinate, label or fit depends
%   on them.
%
%   The scientific settings - image resolution, the GridFit parameters, the
%   projection and labelling parameters - live in
%   src/project/default_ielectrodes_options.m and go to handles.work.options.
%   Alejandro drew that line: "Non-scientific are colours, default layout,
%   and visualization options. Scientific are the rest."
%
%   Colours are a third file, app/config/defaultColors.m, and land in
%   handles.ui.colors.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also DEFAULT_IELECTRODES_OPTIONS, DEFAULTCOLORS.

if nargin<1
    options=[];
end

%% thresholded voxels view

% How many voxels the 3D scatter plot draws at most. Above this a random
% sample of that size is shown instead, with a warning. Only the picture is
% affected: the voxels themselves are all still there.
if ~isfield(options, 'scatter3D_elem_limit')
    options.scatter3D_elem_limit=50000;
end

%% layout

% Which panels are visible at start-up.
if ~isfield (options, 'showLocalizeTools')
    options.showLocalizeTools=true;
end

if ~isfield (options, 'showPlanTools')
    options.showPlanTools=true;
end
