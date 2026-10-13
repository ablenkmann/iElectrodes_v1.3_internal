function [project, work, colours] = loadAnatomy(cfg, project, work)
%IELEC.LOADANATOMY  Read a FreeSurfer parcellation into the project.
%
%   [project, work, colours] = ielec.loadAnatomy(cfg, project, work)
%   reads a parcellation volume - aparc+aseg, aparc.a2009s or wmparc - onto
%   the MRI's voxel grid, and keeps it in project.wmparc and project.wmparcS.
%   WORK is not changed.
%
%   Options (cfg):
%     cfg.file   the parcellation to read. Full path. Required.
%     cfg.lut    the look-up table the colours come from, if not the one in
%                work.options.atlasLUTFile.                    Default: ''
%
%   COLOURS is the colour of every voxel, an X-by-Y-by-Z-by-3 array. It is a
%   display cache - derived from the parcellation and the table, and always
%   recomputable - so it is not part of the project: the frontend keeps it in
%   ui, the way it keeps the caches IELEC.OPENPROJECT hands over.
%
%   The parcellation is read with nearest-neighbour interpolation, because
%   the voxel values are region numbers and averaging them would invent
%   regions that do not exist.
%
%   Which space the project is in is not touched: a parcellation can belong
%   to either, as the button's own comment says.
%
%   The name: the backend function this calls is LOADPARCELLATION, and an
%   ielec function does not take the name of the backend function it calls
%   (docs/API_LAYER.md rule 6).
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:noMRI (there is no MRI to read it onto), ielec:badOption,
%   and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.file = fullfile(folder, 'wmparc.nii');
%       [project, work, colours] = ielec.loadAnatomy(cfg, project, work);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also LOADPARCELLATION, PARCELLATIONCOLOURS, IELEC.COLOURCACHES.

cfg = checkCfg(cfg, struct('lut', ''), {'file'}, 'loadAnatomy');

if ~ischar(cfg.file) || isempty(cfg.file)
    error('ielec:badOption', ...
        'ielec.loadAnatomy: cfg.file must be the full path of the parcellation.');
end
if ~ischar(cfg.lut)
    error('ielec:badOption', ...
        'ielec.loadAnatomy: cfg.lut must be the path of a look-up table.');
end
if ~isfield(project, 'T1') || isempty(project.T1)
    error('ielec:noMRI', ...
        ['ielec.loadAnatomy: a parcellation is read onto the MRI''s grid, ' ...
         'and this project has no MRI. Start a project first.']);
end

[folder, name, extension] = fileparts(cfg.file);

[project.wmparc, project.wmparcS] = ...
    loadParcellation([folder filesep], [name extension], project.T1);

lut = cfg.lut;
if isempty(lut)
    lut = fieldOr(fieldOr(work, 'options', struct()), 'atlasLUTFile', '');
end
colours = parcellationColours(project.wmparc.img, lut);

project = recordStep(project, mfilename, cfg);
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end
