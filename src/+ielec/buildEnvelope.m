function [project, work] = buildEnvelope(cfg, project, work)
%IELEC.BUILDENVELOPE  Build the smooth cortical envelope from the pial surfaces.
%
%   [project, work] = ielec.buildEnvelope(cfg, project, work) wraps each
%   hemisphere's pial surface in a smooth envelope and keeps the pair in the
%   project, as vertices_SCE_R and the three fields beside it. WORK is not
%   changed.
%
%   Options (cfg):
%     cfg.resample  thin both hemispheres towards this many vertices, for
%                   drawing speed. [] keeps them whole.  Default: 15000
%
%   The envelope is what the brain-shift correction projects a grid onto: a
%   surface that follows the cortex without following it into every sulcus,
%   which is where a subdural grid actually lies. BUILDSCE does the work,
%   with the smoothing settings in work.options; loading one someone else
%   built is IELEC.LOADSURFACES with cfg.target 'envelope'.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:noSurfaces (there are no pial surfaces to build it from -
%   the button had no such check and went into BUILDSCE with nothing),
%   ielec:badOption, those of the cfg check, and whatever BUILDSCE raises.
%
%   Example
%       [project, work] = ielec.buildEnvelope([], project, work);
%       size(project.vertices_SCE_R)
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also BUILDSCE, IELEC.LOADSURFACES, IELEC.PROJECTARRAYS.

cfg = checkCfg(cfg, struct('resample', 15000), {}, 'buildEnvelope');
checkSurfaceOptions(cfg, 'buildEnvelope');

if isempty(fieldOr(project, 'verticesL', [])) || isempty(fieldOr(project, 'verticesR', []))
    error('ielec:noSurfaces', ...
        ['ielec.buildEnvelope: the envelope is built from the pial surfaces, ' ...
         'and this project has none. Load them first.']);
end

% left first, then right, as the button built them
[vL, fL] = buildSCE(project.verticesL, project.facesL, work.options);
[vR, fR] = buildSCE(project.verticesR, project.facesR, work.options);

if ~isempty(cfg.resample)
    [vR, fR, vL, fL] = resampleSurfacePair(vR, fR, vL, fL, cfg.resample);
end

project = putSurfaces(project, 'envelope', vR, fR, vL, fL);

project = recordStep(project, mfilename, cfg);
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end
