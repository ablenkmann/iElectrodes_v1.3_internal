function ok = compare_labelingBaseline()
%COMPARE_LABELINGBASELINE  Check that labelling still produces the baseline.
%
%   ok = compare_labelingBaseline() re-runs the native-space labelling on
%   examples/exampleNativeSpace.iel and compares every label, every valid
%   label list and every anatomical index against the reference stored by
%   CAPTURE_LABELINGBASELINE. It returns true when everything matches.
%
%   Run this after ANY change to the labelling code - refactoring, bug fixes,
%   moving functions between files. A pass means the change was
%   behaviour-preserving. A fail tells you exactly which array and which
%   contact moved, so you can decide whether the change was intended.
%
%   Usage:  cd into the repository, then
%              tests/compare_labelingBaseline
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo

%% Paths, same four folders electrodes_gui.m adds at start-up
repoRoot = fileparts(fileparts(mfilename('fullpath')));
codeFolders = {'src','app','assets','third_party'};
for k = 1:numel(codeFolders)
    thisFolder = fullfile(repoRoot, codeFolders{k});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

%% Load the reference
baselineFile = fullfile(repoRoot,'tests','baseline_nativeLabels.mat');
if ~isfile(baselineFile)
    error(['No baseline found. Run capture_labelingBaseline first to record\n' ...
           'the current behaviour, then use this script to check against it.']); %#ok<SPERR>
end
ref = load(baselineFile);
ref = ref.baseline;
fprintf('\nBaseline recorded on %s from %s\n', ref.createdOn, ref.sourceFile);

%% Re-run the labelling exactly as the baseline did
ielFile = fullfile(repoRoot,'examples','exampleNativeSpace.iel');
loaded  = load(ielFile,'-mat');
prj     = checkProjectStructure(loaded.s);
prj.options = default_ielectrodes_options([]);

fprintf('Re-running labelElectrodesNative ...\n');
prj = labelElectrodesNative(prj);

%% Compare, array by array
nDiff = 0;
fprintf('\n--- comparison -------------------------------------------\n');

if numel(prj.electrodes) ~= numel(ref.arrays)
    fprintf('  MISMATCH  array count: baseline %d, now %d\n', ...
        numel(ref.arrays), numel(prj.electrodes));
    nDiff = nDiff + 1;
else
    for a = 1:numel(ref.arrays)
        e = prj.electrodes{a};
        r = ref.arrays{a};
        d = 0;

        d = d + reportField(r.name,'aLabels',         r.aLabels,        e.aLabels);
        d = d + reportField(r.name,'validAnatLabels', r.validAnatLabels,e.validAnatLabels);
        d = d + reportField(r.name,'anatInd',         r.anatInd,        e.anatInd);

        for p = 1:min(numel(r.projection), numel(e.projection))
            tag = sprintf('%s projection %d', r.name, p);
            d = d + reportField(tag,'aLabels', r.projection{p}.aLabels, e.projection{p}.aLabels);
        end

        if d == 0
            fprintf('  OK        %-14s %d contacts, labels identical\n', r.name, size(r.aLabels,1));
        end
        nDiff = nDiff + d;
    end
end

%% Targets
for t = 1:min(numel(ref.targets), numel(prj.targets))
    r = ref.targets{t};
    g = prj.targets{t};
    d = reportField(sprintf('target %s',r.name),'aLabels', r.aLabels, g.aLabels);
    if d == 0
        fprintf('  OK        target %-8s labels identical\n', r.name);
    end
    nDiff = nDiff + d;
end

%% Verdict
fprintf('\n');
ok = (nDiff == 0);
if ok
    fprintf('PASS - labelling behaviour is unchanged.\n\n');
else
    fprintf('FAIL - %d field(s) differ from the baseline.\n', nDiff);
    fprintf('If the change was intentional (a bug fix, for example), re-run\n');
    fprintf('capture_labelingBaseline to record the new expected behaviour.\n\n');
end

if nargout == 0
    clear ok
end

end

% ---------------------------------------------------------------------
function d = reportField(where, what, expected, actual)
%REPORTFIELD  Compare one field and describe the first difference found.
if isequaln(expected, actual)
    d = 0; return
end
d = 1;
fprintf('  DIFFERS   %s / %s\n', where, what);

if iscell(expected) && iscell(actual)
    if ~isequal(size(expected), size(actual))
        fprintf('              size %s -> %s\n', matSize(expected), matSize(actual));
        return
    end
    shown = 0;
    for i = 1:numel(expected)
        if ~isequaln(expected{i}, actual{i})
            [r,c] = ind2sub(size(expected), i);
            fprintf('              row %d col %d: "%s" -> "%s"\n', ...
                r, c, asText(expected{i}), asText(actual{i}));
            shown = shown + 1;
            if shown >= 5
                fprintf('              ... (further differences not listed)\n');
                return
            end
        end
    end
elseif isnumeric(expected) && isnumeric(actual)
    if ~isequal(size(expected), size(actual))
        fprintf('              size %s -> %s\n', matSize(expected), matSize(actual));
    else
        fprintf('              %d of %d values changed\n', ...
            sum(expected(:) ~= actual(:)), numel(expected));
    end
end
end

function s = matSize(x)
s = strjoin(arrayfun(@(n) num2str(n), size(x), 'UniformOutput', false), 'x');
end

function s = asText(x)
if ischar(x)
    s = x;
elseif isempty(x)
    s = '(empty)';
else
    s = sprintf('<%s>', class(x));
end
end
