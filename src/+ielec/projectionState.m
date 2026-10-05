function [project, work, report] = projectionState(cfg, project, work)
%IELEC.PROJECTIONSTATE  Which arrays can be projected, and which already are.
%
%   [project, work, report] = ielec.projectionState(cfg, project, work)
%   reports on the brain-shift projection without doing anything: PROJECT
%   and WORK come back as they went in.
%
%   REPORT:
%     .projectable       true for each array that can be projected - the
%                        grids and the strips, which sit on the surface
%     .alreadyDone       true for each array that already has a projection
%     .anyProjectable    true when there is anything to project at all
%     .allDone           true when every array has a projection, which is
%                        what makes IELEC.PROJECTARRAYS a no-op
%     .surfaceAvailable  true when the smooth cortical envelope to project
%                        onto exists: the patient's in native space, the
%                        template in MNI space. Asking for it costs the
%                        merge of the two hemispheres, so this is a call to
%                        make when there is a decision to make.
%
%   Options (cfg):
%     cfg.space   'Native' or 'MNI', which decides whose envelope is asked
%                 for. Default: project.currentSpace.
%
%   A frontend asks this before IELEC.PROJECTARRAYS, so that it can say what
%   it has to say - that there is nothing to project, that some arrays are
%   projected already and it wants to know whether to redo them, that the
%   envelope is missing - and then call the projection itself.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:badOption, and those of the cfg check.
%
%   Example
%       [~, ~, state] = ielec.projectionState([], project, work);
%       if ~state.anyProjectable, disp('localize a grid first'), end
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ARRAYPROJECTIONSTATE, ENVELOPEFOR, IELEC.PROJECTARRAYS.

cfg   = checkCfg(cfg, struct('space', ''), {}, 'projectionState');
space = resolveSpace(cfg.space, project, 'projectionState');

arrays = fieldOr(project, 'electrodes', {});
[report.projectable, report.alreadyDone] = arrayProjectionState(arrays);
report.anyProjectable = any(report.projectable);
report.allDone        = ~isempty(report.alreadyDone) && all(report.alreadyDone);

vertices = envelopeFor(space, project, work);
report.surfaceAvailable = ~isempty(vertices);
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end
