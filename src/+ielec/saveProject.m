function [project, work] = saveProject(cfg, project, work, ui)
%IELEC.SAVEPROJECT  Save a project to a .iel file.
%
%   [project, work] = ielec.saveProject(cfg, project, work) writes PROJECT,
%   and the part of WORK the file format holds, to the .iel file named in
%   cfg.file. It returns PROJECT unchanged, and WORK with work.FileName and
%   work.PathName set to the file just written.
%
%   Options (cfg):
%     cfg.file   path of the .iel file to write. An existing file is
%                replaced.                                           required
%
%   [project, work] = ielec.saveProject(cfg, project, work, ui) writes
%   the colour caches given in UI (wmparcColors, AnnotColor_R,
%   AnnotColor_L) - the ones a display already holds.
%
%   The file is in the .iel format iElectrodes 1.020 reads: one flat
%   variable s, and the colour caches with it. Without UI they are
%   computed from the project (PROJECTCOLOURCACHES, with
%   work.options.atlasLUTFile), as the display computes them; for a large
%   parcellation that takes seconds, which passing them saves.
%
%   As before, s.FileName and s.PathName inside the file carry what WORK held
%   before this call, not the new name.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:emptyProject (no MRI - nothing to save), ielec:noSuchFolder,
%   and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.file = 'C:\data\patient01\patient01.iel';
%       [project, work] = ielec.saveProject(cfg, project, work);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.OPENPROJECT, WRITEIELFILE, PROJECTCOLOURCACHES,
%   docs/API_LAYER.md.

cfg = checkCfg(cfg, struct(), {'file'}, 'saveProject');
if ~ischar(cfg.file)
    error('ielec:badOption', 'ielec.saveProject: cfg.file must be a file name.');
end
if ~isfield(project, 'T1') || isempty(project.T1)
    error('ielec:emptyProject', ...
        'ielec.saveProject: the project has no MRI, so there is nothing to save.');
end
[folder, name, ext] = fileparts(cfg.file);
if ~isempty(folder) && ~isfolder(folder)
    error('ielec:noSuchFolder', 'ielec.saveProject: no such folder: %s', folder);
end

lutFile = [];
if isfield(work, 'options') && isfield(work.options, 'atlasLUTFile')
    lutFile = work.options.atlasLUTFile;
end
if nargin < 4 || isempty(ui)
    ui = projectColourCaches(project, lutFile);
end
writeIelFile(cfg.file, project, work, ui);

if isempty(folder)
    folder = pwd;
end
if folder(end) ~= filesep
    folder = [folder filesep];
end
work.FileName = [name ext];
work.PathName = folder;
end
