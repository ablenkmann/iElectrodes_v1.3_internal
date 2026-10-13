function [project, work] = loadSurfaces(cfg, project, work)
%IELEC.LOADSURFACES  Read a right/left pair of surfaces into the project.
%
%   [project, work] = ielec.loadSurfaces(cfg, project, work) reads the two
%   hemispheres of a cortical surface and keeps them in the project. WORK is
%   not changed.
%
%   Options (cfg):
%     cfg.right     the right hemisphere's file. Full path. Required.
%     cfg.left      the left one. Full path. Required.
%     cfg.target    which pair of surfaces this is:
%                     'pial'      the cortical surface the contacts are
%                                 drawn on and annotated with  (default)
%                     'envelope'  the smooth cortical envelope the
%                                 brain-shift correction projects onto
%     cfg.centre    move the surfaces to the centre of the MRI volume.
%                   FreeSurfer writes them relative to their own origin, so
%                   this is what lines them up with the patient's images.
%                                                         Default: false
%     cfg.resample  thin both hemispheres towards this many vertices, for
%                   drawing speed. [] keeps them whole.      Default: []
%
%   The pial surfaces are kept whole because the annotation gives one label
%   per vertex, and a thinned surface has no label for the vertices it
%   gained; the envelope carries no annotation, so it is thinned - 15000
%   vertices is what the button asks for.
%
%   Which space the project is in is not set here. The button does that
%   after its last question, and a file that turns out to be unreadable
%   should not have changed the project's mind about its coordinates.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:noMRI (cfg.centre with no MRI to centre on),
%   ielec:badOption, those of the cfg check, and whatever the reader raises
%   about the files.
%
%   Example
%       cfg = [];
%       cfg.right  = fullfile(folder, 'rh.pial');
%       cfg.left   = fullfile(folder, 'lh.pial');
%       cfg.centre = true;
%       [project, work] = ielec.loadSurfaces(cfg, project, work);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also READSURFACEPAIR, CENTRESURFACES, RESAMPLESURFACEPAIR,
%            IELEC.BUILDENVELOPE, IELEC.LOADANNOTATIONS.

defaults.target   = 'pial';
defaults.centre   = false;
defaults.resample = [];
cfg = checkCfg(cfg, defaults, {'right', 'left'}, 'loadSurfaces');
checkSurfaceOptions(cfg, 'loadSurfaces');

% everything that can be refused is refused before a file is read
if cfg.centre && (~isfield(project, 'T1') || isempty(project.T1))
    error('ielec:noMRI', ...
        ['ielec.loadSurfaces: centring puts the surfaces in the middle of ' ...
         'the MRI, and this project has no MRI.']);
end

[vR, fR, vL, fL] = readSurfacePair(cfg.right, cfg.left);

if cfg.centre
    [vR, vL] = centreSurfaces(size(project.T1.img), project.S2, vR, vL);
end

if ~isempty(cfg.resample)
    [vR, fR, vL, fL] = resampleSurfacePair(vR, fR, vL, fL, cfg.resample);
end

project = putSurfaces(project, cfg.target, vR, fR, vL, fL);

project = recordStep(project, mfilename, cfg);
end
