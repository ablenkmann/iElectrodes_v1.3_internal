function ok = test_headlessWorkflow()
%TEST_HEADLESSWORKFLOW  Run the whole workflow from a script and check it.
%
%   ok = test_headlessWorkflow() runs examples/exampleHeadlessWorkflow.m -
%   open, threshold, select, cluster, fit, add, label, export, save and open
%   again - and checks what each step produced, and that it produced it
%   through the ielec layer.
%
%   The strongest single check in the suite: if any step still needed the
%   GUI, this would fail or open a window. It also re-localizes one of the
%   example project's depth electrodes from its CT, so it checks the science
%   end to end: the new fit has to land on the contacts the project already
%   had.
%
%   It writes a project file and a .tsv to a temporary folder, removed at the
%   end, and takes longer than the other tests because it runs GridFit and
%   saves a full project.
%
%   Usage:  cd into the repository, then
%              test_headlessWorkflow
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also EXAMPLEHEADLESSWORKFLOW.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repoRoot, 'examples'));

outFolder = fullfile(tempdir, ['iElectrodes_test_headless_' char(java.util.UUID.randomUUID)]);
removeLater = onCleanup(@() removeFolder(outFolder));

nFail = 0;

threw = '';
try
    r = exampleHeadlessWorkflow(outFolder);
catch err
    threw = sprintf('%s (%s)', err.message, err.stack(1).name);
end

fprintf('\n--- the run --------------------------------------------------\n');
nFail = nFail + check(isempty(threw), 'every step ran', threw);
if ~isempty(threw)
    fprintf('\nFAIL - the workflow stopped.\n\n');
    ok = false; if nargout == 0, clear ok; end, return
end
nFail = nFail + check(r.figuresOpened == 0, 'no window was opened', ...
    sprintf('%d', r.figuresOpened));

fprintf('\n--- each step produced something -----------------------------\n');
nFail = nFail + check(r.nThresholded > 0, 'the CT threshold found voxels', ...
    sprintf('%d', r.nThresholded));
nFail = nFail + check(r.nSelected > r.newArray.nElectrodes, ...
    'more voxels selected than contacts to find', sprintf('%d voxels', r.nSelected));
nFail = nFail + check(numel(r.clusterError) == r.newArray.nElectrodes, ...
    'one cluster per contact', sprintf('%d', numel(r.clusterError)));
nFail = nFail + check(isequal(size(r.fitPositions), [r.newArray.nElectrodes 3]), ...
    'GridFit placed every contact', sprintf('%dx3', size(r.fitPositions,1)));
nFail = nFail + check(r.nArraysAfter == r.nArraysBefore + 1, ...
    'the new array was added', sprintf('%d -> %d', r.nArraysBefore, r.nArraysAfter));

% aLabels has one ROW per contact and one column per region, most probable
% first ('74% Right-Hippocampus', then the next region, ...). A contact with
% fewer regions than the widest row leaves empty cells after its last one,
% so what must hold is that every row has a first label.
aLabels  = r.newArray.aLabels;
labelled = size(aLabels, 1) == r.newArray.nElectrodes && ...
           all(cellfun(@(s) ischar(s) && ~isempty(s), aLabels(:,1)));
nFail = nFail + check(labelled, 'every new contact has an anatomical label', ...
    sprintf('%d contacts, up to %d regions each', size(aLabels,1), size(aLabels,2)));

nFail = nFail + check(r.tsvContacts == r.nContactsTotal, ...
    'the .tsv has one line per contact in the project', ...
    sprintf('%d of %d', r.tsvContacts, r.nContactsTotal));
nFail = nFail + check(r.reopenedMatches, 'saved and reopened unchanged', '');

fprintf('\n--- the science ----------------------------------------------\n');
% The new fit is made from the same CT voxels the stored localization was.
% It should land on the stored contacts to well within a contact spacing.
nFail = nFail + check(mean(r.fitError) < 2, ...
    sprintf('GridFit lands on the stored %s contacts', r.referenceName), ...
    sprintf('%.2f mm on average, %.2f at most', mean(r.fitError), max(r.fitError)));
nFail = nFail + check(mean(r.clusterError) < 2, ...
    'clustering lands on them too', ...
    sprintf('%.2f mm on average', mean(r.clusterError)));

fprintf('\n--- and it goes through the layer ----------------------------\n');
% The example is the tutorial for scripting iElectrodes, so it has to be
% scriptable the way the document says: ielec calls and nothing else. This is
% rule 8 applied to the example instead of to the window, and it is here
% because a backend call that creeps back in would still pass every check
% above - the workflow would run, it just would not be an example any more.
% Strings go as well as comments, which is the one way this differs from
% test_frontendUsesLayer.m. That test keeps them on purpose - a callback name
% in a string is a frontend call anyway - but this example PRINTS the name of
% the layer function each step calls, so every one of the nine appears inside
% a character string. Counting those would be counting the log, and the first
% version of this check did exactly that: it passed with every ielec call in
% the file renamed away.
exampleFile = fullfile(repoRoot, 'examples', 'exampleHeadlessWorkflow.m');
code    = withoutStrings(withoutComments(fileread(exampleFile)));
backend = backendFunctionNames(fullfile(repoRoot, 'src'));
names   = regexp(code, '(?<![\w.])([A-Za-z]\w*)\s*\(', 'tokens');
names   = unique(cellfun(@(c) c{1}, names, 'UniformOutput', false));
called  = sort(intersect(names, backend));

% EUCDISTMAT is one of the three shared geometry functions rule 8 allows, and
% the example uses it for its own bookkeeping - measuring how far the new fit
% landed from the old one - not for any step of the workflow.
allowed = {'eucDistMat'};
nFail = nFail + check(isequal(called, allowed), ...
    'the example calls no backend function but eucDistMat', ...
    strjoin(called, ', '));

% The nine by name, and as calls - ielec.something( - rather than as a
% count, so that the printed detail says what it means and a step that
% leaves the layer fails here instead of being absorbed by a >= .
nine = {'acceptArray', 'cluster', 'export', 'fitArray', 'label', ...
        'openProject', 'saveProject', 'selectVoxels', 'thresholdCT'};
found      = regexp(code, 'ielec\.(\w+)\s*\(', 'tokens');
ielecCalls = unique(cellfun(@(c) c{1}, found, 'UniformOutput', false));
nFail = nFail + check(isequal(ielecCalls, nine), ...
    'and it drives the workflow with these nine layer functions', ...
    strjoin(ielecCalls, ', '));

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the whole workflow runs from a script, without a window.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
% The next two are copies of the ones in tests/test_frontendUsesLayer.m. Each
% test in this folder carries its own helpers - CHECK and ERRORID are copied
% the same way - so that one can be read and run without the others.

function code = withoutStrings(text)
% Blank out what is inside every character string, leaving the quotes. The
% string scanner is the one in WITHOUTCOMMENTS: a quote opens a string only
% where a value cannot have just ended, otherwise it is the transpose
% operator.
lines = strsplit(text, newline);
for L = 1:numel(lines)
    line = lines{L};
    kept = '';
    inString = false;
    i = 1;
    while i <= numel(line)
        c = line(i);
        if inString
            if c == ''''
                kept(end+1) = c; %#ok<AGROW>
                if i < numel(line) && line(i+1) == ''''
                    i = i + 1;            % an escaped quote, still inside
                else
                    inString = false;
                end
            end                           % anything else is dropped
        elseif c == ''''
            before = strtrim(kept);
            if ~isempty(before) && (isletter(before(end)) || any(before(end) == '0123456789)]}._'''))
                kept(end+1) = c; %#ok<AGROW>   transpose
            else
                inString = true;
                kept(end+1) = c; %#ok<AGROW>
            end
        else
            kept(end+1) = c; %#ok<AGROW>
        end
        i = i + 1;
    end
    lines{L} = kept;
end
code = strjoin(lines, newline);
end

function names = backendFunctionNames(srcFolder)
% Every .m under src/, except the two packages. Only src/ - a call reaching
% into app/, extras/, legacy/ or the repository root would not be seen here,
% and neither would one made through FEVAL or a function handle.
listing = dir(fullfile(srcFolder, '**', '*.m'));
names   = {};
for k = 1:numel(listing)
    if contains(listing(k).folder, '+ielec') || contains(listing(k).folder, '+ielview')
        continue
    end
    [~, name] = fileparts(listing(k).name);
    names{end+1} = name; %#ok<AGROW>
end
names = unique(names);
end

function code = withoutComments(text)
% Everything from a % to the end of the line goes, unless the % is inside a
% character string - which matters here, because the example is full of
% SPRINTF format strings. A quote opens a string only where a value cannot
% have just ended; otherwise it is the transpose operator.
lines = strsplit(text, newline);
for L = 1:numel(lines)
    line = lines{L};
    kept = '';
    inString = false;
    i = 1;
    while i <= numel(line)
        c = line(i);
        if inString
            kept(end+1) = c; %#ok<AGROW>
            if c == ''''
                if i < numel(line) && line(i+1) == ''''
                    kept(end+1) = ''''; %#ok<AGROW>
                    i = i + 1;
                else
                    inString = false;
                end
            end
        elseif c == ''''
            before = strtrim(kept);
            if ~isempty(before) && (isletter(before(end)) || any(before(end) == '0123456789)]}._'''))
                kept(end+1) = c; %#ok<AGROW>   transpose
            else
                inString = true;
                kept(end+1) = c; %#ok<AGROW>
            end
        elseif c == '%'
            break
        else
            kept(end+1) = c; %#ok<AGROW>
        end
        i = i + 1;
    end
    lines{L} = kept;
end
code = strjoin(lines, newline);
end

function removeFolder(folder)
if isfolder(folder)
    rmdir(folder, 's');
end
end

function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-50s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-50s %s\n', what, detail);  bad = 1;
end
end
