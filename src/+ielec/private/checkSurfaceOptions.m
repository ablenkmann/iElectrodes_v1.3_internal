function checkSurfaceOptions(cfg, caller)
%CHECKSURFACEOPTIONS  The options the surface calls share - for ielec.
%
%   checkSurfaceOptions(cfg, caller) refuses a cfg.target that is neither
%   'pial' nor 'envelope', a cfg.resample that is not a whole number of
%   vertices (or []), a cfg.centre that is not true or false, and cfg.right
%   and cfg.left that are not paths. Each is checked only where the calling
%   function has it. CALLER is named in the error.
%
%   Private to the ielec package.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.LOADSURFACES, IELEC.BUILDENVELOPE.

if isfield(cfg, 'target') && ...
        (~ischar(cfg.target) || ~ismember(cfg.target, {'pial', 'envelope'}))
    error('ielec:badOption', ...
        'ielec.%s: cfg.target must be ''pial'' or ''envelope''.', caller);
end

if isfield(cfg, 'resample') && ~isempty(cfg.resample) && ...
        (~isnumeric(cfg.resample) || ~isscalar(cfg.resample) || ...
         ~isfinite(cfg.resample) || cfg.resample < 1 || mod(cfg.resample, 1) ~= 0)
    error('ielec:badOption', ...
        'ielec.%s: cfg.resample must be a whole number of vertices, or [].', caller);
end

if isfield(cfg, 'centre') && ...
        ~(islogical(cfg.centre) || (isnumeric(cfg.centre) && isscalar(cfg.centre)))
    error('ielec:badOption', ...
        'ielec.%s: cfg.centre must be true or false.', caller);
end

for f = {'right', 'left'}
    if isfield(cfg, f{1}) && (~ischar(cfg.(f{1})) || isempty(cfg.(f{1})))
        error('ielec:badOption', ...
            'ielec.%s: cfg.%s must be the full path of a surface file.', caller, f{1});
    end
end
end
