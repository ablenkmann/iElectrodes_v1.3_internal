function ok = roundtrip_project(ielFile)
%ROUNDTRIP_PROJECT  Does patient data survive a save/load cycle unchanged?
%
%   ok = roundtrip_project() loads examples/exampleNativeSpace.iel, packs it
%   back into a project structure, writes it to a temporary file, reads that
%   file again, and compares the two results field by field.
%
%   ok = roundtrip_project(ielFile) does the same for another project file.
%
%   Nothing here opens a figure. The GUI's Save and Open buttons only add a
%   file dialog around exactly these calls, so this exercises the real
%   persistence path:
%
%       load(file,'-mat')              ->  s
%       checkProjectStructure(s)       ->  project      (unpack)
%       checkProjectStructure(project) ->  s            (pack)
%       save(file,'s')
%
%   Why it matters: the next step of the restructuring moves 22 patient-data
%   fields out of the flat handles struct into handles.project. That touches
%   820 references. This test is the safety net for that move - run it before
%   and after, and any field that stops surviving the cycle shows up by name.
%
%   Note on images: the first unpack converts volumes from the old
%   nifti-tools format to SPM format, so the raw saved structs differ between
%   the first and second pass by design. The comparison is therefore made
%   between the two UNPACKED projects, which is what the rest of the toolbox
%   actually works with.
%
%   Usage:  cd into the repository, then
%              tests/roundtrip_project
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

if nargin < 1
    ielFile = fullfile(repoRoot,'examples','exampleNativeSpace.iel');
end
if ~isfile(ielFile)
    error('Project file not found: %s', ielFile);
end

%% ---------------------------------------------------------------- pass 1
fprintf('\nRound-trip test\n');
fprintf('  source: %s\n\n', ielFile);

fprintf('  [1/4] loading and unpacking ...\n');
loaded = load(ielFile,'-mat');
projectA = checkProjectStructure(loaded.s);

%% ---------------------------------------------------------------- save
fprintf('  [2/4] packing and saving to a temporary file ...\n');
s = checkProjectStructure(projectA);                                     %#ok<NASGU>
tmpFile = fullfile(tempdir, 'ielectrodes_roundtrip.iel');
save(tmpFile,'s','-v7.3');
d = dir(tmpFile);
fprintf('        %s  (%.1f MB)\n', tmpFile, d.bytes/1e6);

%% ---------------------------------------------------------------- pass 2
fprintf('  [3/4] reading it back and unpacking again ...\n');
reloaded = load(tmpFile,'-mat');
projectB = checkProjectStructure(reloaded.s);

%% ---------------------------------------------------------------- compare
fprintf('  [4/4] comparing\n\n');

nDiff = 0;

fprintf('--- image geometry and transformations --------------------\n');
nDiff = nDiff + cmp('S2',            projectA, projectB);
nDiff = nDiff + cmpVolume('T1',      projectA, projectB);
nDiff = nDiff + cmpVolume('TAC',     projectA, projectB);
nDiff = nDiff + cmpVolume('mask',    projectA, projectB);
nDiff = nDiff + cmpVolume('wmparc',  projectA, projectB);
nDiff = nDiff + cmp('wmparcS',       projectA, projectB);

fprintf('\n--- surfaces ----------------------------------------------\n');
for f = {'verticesL','verticesR','facesL','facesR', ...
         'vertices_SCE_L','vertices_SCE_R','faces_SCE_L','faces_SCE_R'}
    nDiff = nDiff + cmp(f{1}, projectA, projectB);
end

fprintf('\n--- annotations -------------------------------------------\n');
for f = {'AnnotLabel_L','AnnotLabel_R','AnnotColortable_L','AnnotColortable_R'}
    nDiff = nDiff + cmp(f{1}, projectA, projectB);
end

fprintf('\n--- electrodes --------------------------------------------\n');
nDiff = nDiff + cmpArrays('electrodes', projectA, projectB);

fprintf('\n--- planning targets --------------------------------------\n');
nDiff = nDiff + cmpArrays('targets', projectA, projectB);

fprintf('\n--- other project fields ----------------------------------\n');
for f = {'currentSpace','elecListLabels'}
    nDiff = nDiff + cmp(f{1}, projectA, projectB);
end

fprintf('\n--- working data that .iel currently stores too ------------\n');
fprintf('  (these are work-in-progress values, not patient data, but the\n');
fprintf('   file format carries them today - see docs/STATE_FIELD_MAPPING.md)\n');
for f = {'GS','oldGS','clusters','oldclusters', ...
         'brushCrd','brushWeight','oldbrushCrd','oldbrushWeight'}
    nDiff = nDiff + cmp(f{1}, projectA, projectB);
end

%% ---------------------------------------------------------------- verdict
if exist(tmpFile,'file'), delete(tmpFile); end

fprintf('\n');
ok = (nDiff == 0);
if ok
    fprintf('PASS - the project survives a save/load cycle unchanged.\n\n');
else
    fprintf('FAIL - %d field(s) changed across the cycle.\n\n', nDiff);
end

if nargout == 0
    clear ok
end

end

% =====================================================================
function d = cmp(name, A, B)
%CMP  Compare one field of two project structs and print one line.
hasA = isfield(A,name);
hasB = isfield(B,name);
if ~hasA && ~hasB
    fprintf('  --        %-20s absent from both\n', name);
    d = 0; return
end
if hasA ~= hasB
    fprintf('  MISSING   %-20s present in %s only\n', name, tern(hasA,'the original','the reloaded copy'));
    d = 1; return
end
if isequaln(A.(name), B.(name))
    fprintf('  ok        %-20s %s\n', name, describe(A.(name)));
    d = 0;
else
    fprintf('  DIFFERS   %-20s %s  ->  %s\n', name, describe(A.(name)), describe(B.(name)));
    d = 1;
end
end

% ---------------------------------------------------------------------
function d = cmpVolume(name, A, B)
%CMPVOLUME  Compare an image volume: voxel data and spatial geometry.
if ~isfield(A,name) || isempty(A.(name))
    fprintf('  --        %-20s not loaded in this project\n', name);
    d = 0; return
end
d = 0;
a = A.(name); b = B.(name);

if isequaln(a.img, b.img)
    fprintf('  ok        %-20s voxels %s\n', [name '.img'], describe(a.img));
else
    fprintf('  DIFFERS   %-20s voxel data changed\n', [name '.img']);
    d = d + 1;
end

if isfield(a,'vol') && isfield(b,'vol')
    if isequaln(a.vol.mat, b.vol.mat)
        fprintf('  ok        %-20s geometry preserved\n', [name '.vol.mat']);
    else
        fprintf('  DIFFERS   %-20s SPATIAL GEOMETRY CHANGED\n', [name '.vol.mat']);
        disp(a.vol.mat); disp(b.vol.mat);
        d = d + 1;
    end
end
end

% ---------------------------------------------------------------------
function d = cmpArrays(name, A, B)
%CMPARRAYS  Compare electrode or target arrays contact by contact.
d = 0;
a = A.(name); b = B.(name);
if numel(a) ~= numel(b)
    fprintf('  DIFFERS   %s count: %d -> %d\n', name, numel(a), numel(b));
    d = 1; return
end
if isempty(a)
    fprintf('  --        no %s in this project\n', name);
    return
end
for i = 1:numel(a)
    ea = a{i}; eb = b{i};
    problems = {};
    if ~isequaln([ea.x ea.y ea.z], [eb.x eb.y eb.z]), problems{end+1} = 'coordinates'; end %#ok<AGROW>
    if isfield(ea,'ch_label') && ~isequaln(ea.ch_label, eb.ch_label),   problems{end+1} = 'channel names'; end %#ok<AGROW>
    if isfield(ea,'Name')     && ~isequaln(ea.Name, eb.Name),           problems{end+1} = 'array name'; end %#ok<AGROW>
    if isfield(ea,'Type')     && ~isequaln(ea.Type, eb.Type),           problems{end+1} = 'type'; end %#ok<AGROW>
    if isfield(ea,'projection') && ~isequaln(ea.projection, eb.projection), problems{end+1} = 'projections'; end %#ok<AGROW>
    if ~isequaln(ea, eb) && isempty(problems),                          problems{end+1} = 'some other field'; end %#ok<AGROW>

    nm = '(unnamed)';
    if isfield(ea,'Name'), nm = ea.Name; end
    if isempty(problems)
        fprintf('  ok        %-14s %3d contacts, coordinates and names identical\n', nm, numel(ea.x));
    else
        fprintf('  DIFFERS   %-14s %s\n', nm, strjoin(problems, ', '));
        d = d + 1;
    end
end
end

% ---------------------------------------------------------------------
function s = describe(x)
%DESCRIBE  Short, printable summary of a value.
if ischar(x)
    s = sprintf('"%s"', x);
elseif isempty(x)
    s = '(empty)';
elseif isnumeric(x) || islogical(x)
    s = sprintf('%s %s', matSize(x), class(x));
elseif iscell(x)
    s = sprintf('%s cell', matSize(x));
elseif isstruct(x)
    s = sprintf('%s struct', matSize(x));
else
    s = class(x);
end
end

function s = matSize(x)
s = strjoin(arrayfun(@(n) num2str(n), size(x), 'UniformOutput', false), 'x');
end

function s = tern(c,a,b)
if c, s = a; else, s = b; end
end
