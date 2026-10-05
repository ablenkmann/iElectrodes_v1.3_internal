function [project, work] = saveTargets(cfg, project, work)
%IELEC.SAVETARGETS  Write the project's planning targets to a file.
%
%   [project, work] = ielec.saveTargets(cfg, project, work) writes
%   project.targets to a .mat file that IELEC.LOADTARGETS and the toolbox's
%   Load planning button can read. Neither PROJECT nor WORK is changed; they
%   come back so that a caller can write the same line for every ielec call.
%
%   The planning targets are saved on their own here. They also travel in
%   the project file, so this is for handing a plan to someone who is not
%   given the whole project, or for keeping one plan while another is tried.
%
%   Options (cfg):
%     cfg.file   the .mat file to write. Full path. Required.
%
%   Nothing is drawn and no window is opened. Which file, and whether to
%   overwrite one that is already there, are the frontend's questions -
%   before this call.
%
%   Errors: ielec:noTargets when there is nothing planned to save,
%   ielec:noSuchFolder for a folder that is not there, ielec:badOption for a
%   cfg.file that is not a path, and those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.file = fullfile(folder, 'plan_targets.mat');
%       [project, work] = ielec.saveTargets(cfg, project, work);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also SAVEPLANNINGTARGETS, IELEC.LOADTARGETS, IELEC.SAVEPROJECT.

cfg = checkCfg(cfg, struct(), {'file'}, 'saveTargets');

if ~ischar(cfg.file) || isempty(cfg.file)
    error('ielec:badOption', ...
        'ielec.saveTargets: cfg.file must be the full path of the file to write.');
end

if ~isfield(project, 'targets') || isempty(project.targets)
    error('ielec:noTargets', ...
        'ielec.saveTargets: there is nothing planned in this project to save.');
end

folder = fileparts(cfg.file);
if ~isempty(folder) && ~isfolder(folder)
    error('ielec:noSuchFolder', 'ielec.saveTargets: no such folder: %s', folder);
end

savePlanningTargets(project.targets, cfg.file);
end
