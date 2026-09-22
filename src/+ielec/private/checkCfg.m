function cfg = checkCfg(cfg, defaults, required, caller)
%CHECKCFG  Validate a cfg and fill in its defaults - for the ielec layer.
%
%   cfg = checkCfg(cfg, defaults, required, caller) is the first line of
%   every ielec function. It
%
%     - accepts [] as "no options given",
%     - refuses an option the function does not know. A misspelt option
%       would otherwise be ignored without a word, and the default silently
%       used in its place,
%     - refuses a call that leaves out a required option,
%     - turns a string ("...") into a character vector ('...'), so callers
%       may use either,
%     - fills in every option the caller left out from DEFAULTS.
%
%   DEFAULTS is a struct: its field names are the optional options, its
%   values their defaults. REQUIRED is a cell array of the options that have
%   no default. CALLER is the function's name inside the package, used in
%   the error messages.
%
%   Errors: ielec:badCfg, ielec:unknownOption, ielec:missingOption.
%
%   Private to the ielec package: only ielec functions can call it.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.NEWPROJECT.

if isempty(cfg)
    cfg = struct();
end
if ~isstruct(cfg) || ~isscalar(cfg)
    error('ielec:badCfg', ...
        'ielec.%s: cfg must be a struct - start with cfg = [] and set its fields.', caller);
end

known   = [fieldnames(defaults); required(:)];
given   = fieldnames(cfg);
unknown = setdiff(given, known);
if ~isempty(unknown)
    error('ielec:unknownOption', ...
        'ielec.%s does not know cfg.%s. The options it knows are: %s.', ...
        caller, unknown{1}, strjoin(sort(known)', ', '));
end

for k = 1:numel(given)
    if isstring(cfg.(given{k})) && isscalar(cfg.(given{k}))
        cfg.(given{k}) = char(cfg.(given{k}));
    end
end

for k = 1:numel(required)
    if ~isfield(cfg, required{k}) || isempty(cfg.(required{k}))
        error('ielec:missingOption', 'ielec.%s needs cfg.%s.', caller, required{k});
    end
end

names = fieldnames(defaults);
for k = 1:numel(names)
    if ~isfield(cfg, names{k})
        cfg.(names{k}) = defaults.(names{k});
    end
end
end
