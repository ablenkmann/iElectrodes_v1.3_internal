function makeApiReference(outFile)
%MAKEAPIREFERENCE  Write docs/API_REFERENCE.md from the layer's own help.
%
%   makeApiReference() rebuilds docs/API_REFERENCE.md from the help blocks of
%   src/+ielec/*.m. makeApiReference(outFile) writes it somewhere else.
%
%   Run it from anywhere:
%
%       makeApiReference
%
%   Nothing in the document is written by hand, which is the point: change a
%   function's help and rerun this, and the reference is current. A document
%   describing forty functions is otherwise wrong within a month and looks
%   right from the outside, which is the worst way for a document to be wrong.
%
%   What it takes from each function:
%
%     - the signature, with the package name put back on
%     - the H1 summary line
%     - the first sentence or two of the opening paragraph
%     - the Options block, one row per option, each with its own text
%     - which options are REQUIRED - from the CHECKCFG call rather than from
%       the prose, because that is the contract the function enforces. The
%       help is finer than that list: ielec.indexArray says cfg.rows is
%       "required for a grid", which CHECKCFG cannot express and the function
%       checks itself. Those come out as "sometimes".
%     - the ielec: error identifiers, without their explanations
%
%   What it leaves in `help`: the examples, the cross references, and the long
%   paragraphs about why a thing is the way it is. docs/API_LAYER.md is where
%   the why lives.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also HELP, docs/API_LAYER.md.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
if nargin < 1 || isempty(outFile)
    outFile = fullfile(root, 'docs', 'API_REFERENCE.md');
end

groups = {
 'A session and its project', ...
    'Starting up, and the project as a whole.', ...
    {'startSession','setOptions','newProject','openProject','saveProject','colourCaches'}
 'Images and surfaces', ...
    'What a project is built on: the CT, the atlas, the cortical surfaces.', ...
    {'loadCT','loadAnatomy','loadSurfaces','loadAnnotations','buildEnvelope'}
 'Localizing contacts', ...
    ['From a thresholded CT to an array in the project, in the order the ' ...
     'workflow runs.'], ...
    {'thresholdCT','selectVoxels','cluster','fitArray','indexArray', ...
     'addCoordinate','removeCoordinate','clearCoordinates','undoCoordinates', ...
     'acceptArray'}
 'Arrays already in the project', ...
    'Changing, naming and importing arrays after they exist.', ...
    {'nameContacts','reorderArray','deleteArray','importArrays', ...
     'arrayFileContents','importLabels'}
 'Anatomy and brain shift', ...
    'What the atlas says about a contact, and where a contact really sits.', ...
    {'label','pointLabel','projectArrays','projectionState'}
 'Planning, before surgery', ...
    ['Grids and depth electrodes planned on the brain rather than found in ' ...
     'a CT.'], ...
    {'newTarget','placeTarget','fitTarget','newDepthTarget','aimTarget', ...
     'setFrame','loadTargets','saveTargets'}
 'Writing the result out', '', {'export'}
};

listed = [groups{:,3}];
onDisk = dir(fullfile(root, 'src', '+ielec', '*.m'));
onDisk = erase({onDisk.name}, '.m');
missing = setdiff(onDisk, listed);
stale   = setdiff(listed, onDisk);
if ~isempty(missing) || ~isempty(stale)
    error('makeApiReference:grouping', ...
        ['The grouping in this file is out of step with src/+ielec.\n' ...
         '  on disk but not grouped: %s\n  grouped but not on disk: %s'], ...
        strjoin(missing, ', '), strjoin(stale, ', '));
end

L = {};
L = add(L, '# The ielec layer');
L = add(L, '');
L = add(L, 'The layer the frontend talks to, so that it never calls the backend');
L = add(L, 'directly. Forty functions; what each one does, how it is called, and');
L = add(L, 'what it takes.');
L = add(L, '');
L = add(L, 'The text comes from the help of each function, so it stays with the');
L = add(L, 'code. `help ielec.cluster` at the MATLAB prompt gives any one of them in');
L = add(L, 'full, with an example. `docs/API_LAYER.md` beside this is the design -');
L = add(L, 'the rules these forty obey, and why.');
L = add(L, '');
L = add(L, '## They all have one shape');
L = add(L, '');
L = add(L, '```matlab');
L = add(L, '[project, work] = ielec.name(cfg, project, work)');
L = add(L, '```');
L = add(L, '');
L = add(L, '- **`cfg`** is a struct and carries every choice. `[]` means "all');
L = add(L, '  defaults". An option the function does not know is an error, not a');
L = add(L, '  thing quietly ignored.');
L = add(L, '- **`project`** is the patient: the images, the arrays localized, the');
L = add(L, '  plan. It is what a `.iel` file holds.');
L = add(L, '- **`work`** is the session: what is loaded, selected, in progress.');
L = add(L, '- **Both go in and come out**, so nothing is hidden in a global or read');
L = add(L, '  back from the window.');
L = add(L, '- **A third output** appears where a function reports something, or');
L = add(L, '  proposes a result it does not store itself.');
L = add(L, '- **Nothing draws.** No window, no dialog, no `guidata`, no reading a');
L = add(L, '  control.');
L = add(L, '- **Errors are named** `ielec:*`, so a caller can tell a refusal from a');
L = add(L, '  crash.');
L = add(L, '');
L = add(L, 'In the option tables below, *sometimes* means required in some cases');
L = add(L, 'only - a grid needs its rows and columns where a depth does not - and');
L = add(L, '`help` on the function gives the condition.');
L = add(L, '');

n = 0;
for g = 1:size(groups, 1)
    L = add(L, '---');
    L = add(L, '');
    L = add(L, ['## ' groups{g,1}]);
    L = add(L, '');
    if ~isempty(groups{g,2})
        L = add(L, groups{g,2});
        L = add(L, '');
    end
    for k = 1:numel(groups{g,3})
        name = groups{g,3}{k};
        e = readEntry(fullfile(root, 'src', '+ielec', [name '.m']));
        n = n + 1;

        L = add(L, sprintf('### `ielec.%s`  %s  %s', name, char(8594), e.outs));
        L = add(L, '');
        L = add(L, e.opening);
        L = add(L, '');
        if ~isempty(e.options)
            L = add(L, '| | | |');
            L = add(L, '|---|---|---|');
            for o = 1:size(e.options, 1)
                L = add(L, sprintf('| `%s` | %s | %s |', e.options{o,:}));
            end
            L = add(L, '');
        end
        if ~isempty(e.errors)
            L = add(L, ['Errors: ' strjoin(strcat('`', e.errors, '`'), ', ')]);
            L = add(L, '');
        end
    end
end

L = add(L, '---');
L = add(L, '');
L = add(L, '*Generated by `tools/makeApiReference.m` from `src/+ielec/*.m`.*');

fid = fopen(outFile, 'w');
if fid == -1
    error('makeApiReference:cannotWrite', 'Cannot write %s', outFile);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', L{:});
fprintf('%s  (%d functions, %d lines)\n', outFile, n, numel(L));
end

% ======================================================================
function L = add(L, s)
L{end+1} = s;
end

% ----------------------------------------------------------------------
function e = readEntry(path)
raw   = fileread(path);
lines = strsplit(raw, newline);
lines = cellfun(@(s) regexprep(s, '\r$', ''), lines, 'UniformOutput', false);

% the outputs, from the signature
sig = strtrim(lines{1});
% One pattern for both shapes. An alternation with a capture in each branch
% comes back empty from MATLAB's regexp, so the brackets come off afterwards
% instead of being matched around.
tok = regexp(sig, '^function\s+(.*?)\s*=\s*\w+\(', 'tokens', 'once');
outs = '';
if ~isempty(tok)
    outs = regexprep(strtrim(tok{1}), '^\[|\]$', '');
end
parts = strtrim(strsplit(outs, ','));
parts = parts(~cellfun(@isempty, parts));
e.outs = strjoin(strcat('`', parts, '`'), ', ');

% the help block
body = {};
for i = 2:numel(lines)
    if isempty(lines{i}) || lines{i}(1) ~= '%'
        break
    end
    body{end+1} = strtrim(lines{i}(2:end));
end

summary = regexp(body{1}, '^IELEC\.\w+\s\s+(.*)$', 'tokens', 'once');
if isempty(summary), summary = body(1); end

% paragraphs
paras = {}; cur = {};
for i = 2:numel(body)
    if isempty(body{i})
        if ~isempty(cur), paras{end+1} = cur; cur = {}; end
    else
        cur{end+1} = body{i};
    end
end
if ~isempty(cur), paras{end+1} = cur; end

opening = ''; errLine = '';
% How many options there are is only known once the Options block has been
% read, and no function has more than eight, so these two grow as they go.
optName = {}; optText = {}; curOpt = 0;
for i = 1:numel(paras)
    p = paras{i};
    head = p{1};
    if startsWith(head, 'Options')
        for j = 2:numel(p)
            om = regexp(p{j}, '^cfg\.(\w+)\s+(.*)$', 'tokens', 'once');
            if ~isempty(om)
                curOpt = curOpt + 1;
                optName{curOpt} = om{1};  
                optText{curOpt} = om{2};  
                %#ok<*AGROW>
            elseif curOpt > 0
                optText{curOpt} = [optText{curOpt} ' ' p{j}];
            end
        end
    elseif startsWith(head, 'Errors:') && isempty(errLine)
        errLine = strjoin(p, ' ');
    elseif isempty(opening) && ~startsWith(head, {'Example','See also','iElectrodes 2'})
        t = strjoin(p, ' ');
        t = regexprep(t, '^\[?[\w,\s\]]*\]?\s*=?\s*ielec\.\w+\([^)]*\)\s*', '');
        if ~isempty(t)
            t(1) = upper(t(1));
        end
        opening = t;
    end
end
if isempty(opening), opening = summary{1}; end
e.opening = firstSentences(opening);

% required, from the contract rather than the prose
cm = regexp(raw, 'checkCfg\(\s*cfg\s*,.*?,\s*\{([^}]*)\}', 'tokens', 'once');
always = {};
if ~isempty(cm)
    always = regexp(cm{1}, '''(\w+)''', 'tokens');
    always = cellfun(@(c) c{1}, always, 'UniformOutput', false);
end

e.options = cell(0, 3);
for i = 1:numel(optName)
    if ismember(optName{i}, always)
        need = 'required';
    elseif contains(lower(optText{i}), 'required')
        need = 'sometimes';
    else
        d = regexp(optText{i}, 'Default:\s*(.+?)\s*$', 'tokens', 'once');
        if isempty(d)
            need = 'optional';
        else
            need = ['default `' strtrim(d{1}) '`'];
        end
    end
    e.options(end+1, :) = {optName{i}, glossOf(optText{i}), need};
end

ids = regexp(errLine, 'ielec:\w+', 'match');
e.errors = unique(ids);
end

% ----------------------------------------------------------------------
function out = firstSentences(text)
parts = regexp(strtrim(text), '(?<=[.!?])\s+', 'split');
out = strtrim(parts{1});
% one sentence can be too short to say anything - ielec.export opens with
% "writes one file" - so take the next one when it is
if numel(out) < 60 && numel(parts) > 1
    out = strtrim(strjoin(parts(1:2), ' '));
end
if numel(out) > 230
    out = strtrim(parts{1});
end
% a sentence ending in a colon introduces a list that is not here
if endsWith(out, ':')
    out = regexprep(out, '[,;]?\s*[^.;,]*:$', '.');
end
end

% ----------------------------------------------------------------------
function t = glossOf(text)
t = strtrim(regexprep(text, '\s+', ' '));
cut = regexp(t, '\s+(required|Default:)', 'once');
if ~isempty(cut)
    t = strtrim(t(1:cut-1));
end
t = strtrim(regexprep(t, '\.$', ''));
if numel(t) > 96
    t = t(1:96);
    sp = find(t == ' ', 1, 'last');
    if ~isempty(sp), t = t(1:sp-1); end
    t = [t '...'];
end
end
