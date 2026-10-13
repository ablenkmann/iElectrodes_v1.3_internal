function [project, work] = loadTargets(cfg, project, work)
%IELEC.LOADTARGETS  Read a planning file into the project's targets.
%
%   [project, work] = ielec.loadTargets(cfg, project, work) reads the
%   planning targets written by IELEC.SAVETARGETS or by the toolbox's Save
%   planning button, and puts them in project.targets. WORK is not changed.
%
%   The targets that were in the project are replaced, not added to, which
%   is what the Load planning button did: a planning file is a plan, and
%   opening one means working on that plan.
%
%   Options (cfg):
%     cfg.file   the .mat file to read. Full path. Required.
%
%   Nothing is drawn and no window is opened. Which file, and whether the
%   user meant to lose the plan already in the project, are the frontend's
%   questions - before this call.
%
%   Errors: ielec:badOption for a cfg.file that is not a path, and those of
%   the cfg check. What is in the file is the reader's to say:
%   loadPlanningTargets:notFound if it is not there, and
%   loadPlanningTargets:noTargets if it holds no planning structure.
%
%   Example
%       cfg = [];
%       cfg.file = fullfile(folder, 'plan_targets.mat');
%       [project, work] = ielec.loadTargets(cfg, project, work);
%       numel(project.targets)
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also LOADPLANNINGTARGETS, IELEC.SAVETARGETS, IELEC.NEWTARGET.

cfg = checkCfg(cfg, struct(), {'file'}, 'loadTargets');

if ~ischar(cfg.file) || isempty(cfg.file)
    error('ielec:badOption', ...
        'ielec.loadTargets: cfg.file must be the full path of the file to read.');
end

project.targets = loadPlanningTargets(cfg.file);

project = recordStep(project, mfilename, cfg);
end
