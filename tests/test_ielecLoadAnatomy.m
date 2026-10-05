function ok = test_ielecLoadAnatomy()
%TEST_IELECLOADANATOMY  Check ielec.loadAnatomy against the parcellation button.
%
%   ok = test_ielecLoadAnatomy() writes a tiny MRI and a tiny parcellation,
%   reads the parcellation through the layer, and compares the project and
%   the colour cache with the two calls the button made itself, kept verbatim
%   below.
%
%   The volumes are small and made here, so the test needs no data beside the
%   repository and runs in a second.
%
%   Usage:  cd into the repository, then
%              test_ielecLoadAnatomy
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.LOADANATOMY, LOADPARCELLATION, PARCELLATIONCOLOURS.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

folder = tempname;
mkdir(folder);
cleanup = onCleanup(@() removeFolder(folder)); %#ok<NASGU>

dim = [16 18 14];
mriFile = writeVolume(folder, 'tinyT1.nii', 200 * ones(dim));

% a parcellation of three regions, by their FreeSurfer numbers
parcellation = zeros(dim);
parcellation(2:6,   2:6,   2:5)  = 17;    % Left-Hippocampus
parcellation(9:13,  9:13,  8:11) = 53;    % Right-Hippocampus
parcellation(2:6,   9:13,  8:11) = 1035;  % ctx-lh-precentral
parcellationFile = writeVolume(folder, 'tinyParcellation.nii', parcellation);

[project, work] = ielec.newProject(struct('mri', mriFile, 'voxdim', [1 1 1]), [], []);

%% ------------------------------------------- the same as the button's steps
fprintf('\n--- ielec.loadAnatomy against the parcellation button ---------\n');

expected = originalLoad(project, work, [folder filesep], 'tinyParcellation.nii');

cfg = [];
cfg.file = parcellationFile;
[loaded, loadedWork, colours] = ielec.loadAnatomy(cfg, project, work);

nFail = nFail + check(isequaln(loaded.wmparc, expected.project.wmparc) && ...
        isequaln(loaded.wmparcS, expected.project.wmparcS), ...
    'the parcellation is what the button read', ...
    sprintf('%s voxels', mat2str(size(loaded.wmparc.img))));
nFail = nFail + check(isequaln(colours, expected.colours), ...
    'and the colours are the ones it computed', ...
    sprintf('%s', mat2str(size(colours))));
nFail = nFail + check(isequaln(loadedWork, work), ...
    'work is not changed', '');
nFail = nFail + check(isequaln(rmfield(loaded, {'wmparc','wmparcS'}), ...
        rmfield(project, {'wmparc','wmparcS'})), ...
    'and nothing else in the project is', '');
nFail = nFail + check(isequal(loaded.currentSpace, project.currentSpace), ...
    'the space is left alone - a parcellation belongs to either', ...
    loaded.currentSpace);

%% ----------------------------------------------- the colours are a cache
fprintf('\n--- what the colours are -------------------------------------\n');

nFail = nFail + check(isequal(size(colours), [dim 3]) && ...
        all(colours(:) >= 0 & colours(:) <= 1), ...
    'one RGB per voxel, in [0 1]', '');
% read the regions out of the volume that was loaded rather than out of the
% one that was written: it is resliced onto the MRI's grid on the way in
img  = loaded.wmparc.img;
flat = reshape(colours, [], 3);
left  = find(img == 17);    % Left-Hippocampus
right = find(img == 53);    % Right-Hippocampus

nFail = nFail + check(~isempty(left) && ~isempty(right), ...
    'the regions came through the reslicing', ...
    sprintf('%d and %d voxels', numel(left), numel(right)));

if ~isempty(left)
    nFail = nFail + check(size(unique(flat(left,:), 'rows'), 1) == 1, ...
        'every voxel of a region has the same colour', ...
        mat2str(flat(left(1),:), 2));

    % and it is the colour the look-up table gives that region. Note that
    % the two hippocampi are NOT a pair to tell apart this way: FreeSurfer
    % gives a structure and its mirror image the same colour, so 17 and 53
    % are both (220 216 20).
    lut = load(work.options.atlasLUTFile);
    row = find(lut.values == 17, 1);
    fromTable = double(lut.RGB(row,:));
    if max(fromTable) > 1, fromTable = fromTable / 255; end

    nFail = nFail + check(~isempty(row) && ...
            max(abs(flat(left(1),:) - fromTable)) < 1e-6, ...
        'and it is the one the look-up table gives it', ...
        sprintf('%s from the table', mat2str(fromTable, 2)));
end

%% -------------------------------------------------------------- what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

noMRI = project;
noMRI.T1 = [];
nFail = nFail + check(strcmp(errorId(@() ielec.loadAnatomy(cfg, noMRI, work)), ...
        'ielec:noMRI'), 'a project with no MRI to read it onto', '');
nFail = nFail + check(strcmp(errorId(@() ielec.loadAnatomy(struct('lut', 'x.mat'), project, ...
                                                            work)), 'ielec:missingOption'), ...
    'a call that does not say which file', 'cfg.file');
nFail = nFail + check(strcmp(errorId(@() ielec.loadAnatomy(...
        struct('file', parcellationFile, 'colours', 1), project, work)), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.colours');

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.loadAnatomy) == 3 && ...
        nargout(@ielec.loadAnatomy) == 3, ...
    'the signature, the colour cache as the third output', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the parcellation is read as the button read it.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% What the Load parcellation button did once the user had chosen a file.

function out = originalLoad(project, work, PathName, wmparcFile)
    handles.project = project;
    handles.work    = work;

    [handles.project.wmparc, handles.project.wmparcS] = ...
        loadParcellation(PathName, wmparcFile, handles.project.T1);

    handles.ui.wmparcColors = ...
        parcellationColours(handles.project.wmparc.img, handles.work.options.atlasLUTFile);

    out.project = handles.project;
    out.colours = handles.ui.wmparcColors;
end

% ---------------------------------------------------------------------
function file = writeVolume(folder, name, img)
file = fullfile(folder, name);
V.fname   = file;
V.dim     = size(img);
V.dt      = [spm_type('int16') 0];
V.mat     = [1 0 0 -8; 0 1 0 -9; 0 0 1 -7; 0 0 0 1];
V.pinfo   = [1; 0; 0];
V.descrip = 'iElectrodes test volume';
spm_write_vol(V, img);
end

function removeFolder(folder)
if ~isfolder(folder), return, end
try
    rmdir(folder, 's');
catch
    fclose('all');
    try
        rmdir(folder, 's');
    catch err
        fprintf('  (could not remove %s: %s)\n', folder, err.message);
    end
end
end

function id = errorId(f)
id = '';
try
    f();
catch err
    id = err.identifier;
    if isempty(id), id = err.message; end
end
end

function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-52s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-52s %s\n', what, detail);  bad = 1;
end
end
