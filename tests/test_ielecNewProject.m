function ok = test_ielecNewProject()
%TEST_IELECNEWPROJECT  Check ielec.newProject, the first function of the layer.
%
%   ok = test_ielecNewProject() writes a small MRI to a temporary folder and
%   checks that ielec.newProject gives the same project and work as the New
%   button's original steps, kept verbatim below. It also checks the rules
%   every ielec function follows (docs/API_LAYER.md): the fixed signature,
%   no ui, no window, and a cfg that refuses what it does not know.
%
%   Usage:  cd into the repository, then
%              test_ielecNewProject
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.NEWPROJECT, IELEC.COLOURCACHES.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

folder = fullfile(tempdir, ['iElectrodes_test_ielec_' char(java.util.UUID.randomUUID)]);
mkdir(folder);
removeLater = onCleanup(@() rmdir(folder, 's'));
mriFile = writeTinyMRI(folder);

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

%% ------------------------------------------- the same as the New button
fprintf('\n--- ielec.newProject against the New button ------------------\n');

% what a running GUI holds when New is pressed: a previous project and its
% work in progress, the shared MNI resources, a selection
options = default_ielectrodes_options([]);
before.project.T1         = 'the previous MRI';
before.project.electrodes = {'an array from the previous project'};
before.work.options       = options;
before.work.v_MNI         = 'shared resource, must survive';
before.work.GS            = rand(5,3);
before.work.brushCrd      = rand(8,3);
before.work.FileName      = 'previous.iel';
before.work.selection     = struct('array',3,'contact',7,'planningArray',1,'planningTarget',2);
before.ui.colors          = 'display state';

% the original steps, with the file dialog's answer given directly
[p, n, e] = fileparts(mriFile);
expected = originalNewButton(before, [p filesep], [n e]);

cfg = [];
cfg.mri = mriFile;
[project, work] = ielec.newProject(cfg, [], before.work);

nFail = nFail + check(isequaln(withoutHistory(project), withoutHistory(expected.project)), ...
    'project is what the New button built', sprintf('%d fields', numel(fieldnames(project))));
nFail = nFail + check(isequaln(rmfield(work,'selection'), rmfield(expected.work,'selection')), ...
    'work is what the New button built', '');
nFail = nFail + check(isequal(work.selection, ...
        struct('array',0,'contact',0,'planningArray',0,'planningTarget',0)), ...
    'nothing is selected', '');

[~, ~, caches] = ielec.colourCaches([], project, work);
same = isequal(caches.wmparcColors, expected.ui.wmparcColors) && ...
       isequal(caches.AnnotColor_R, expected.ui.AnnotColor_R) && ...
       isequal(caches.AnnotColor_L, expected.ui.AnnotColor_L) && ...
       isequal(class(caches.AnnotColor_R), class(expected.ui.AnnotColor_R));
nFail = nFail + check(same, 'the colour caches are what New left in ui', '');

%% ------------------------------------------------------- what it keeps
fprintf('\n--- what a new project keeps and empties ---------------------\n');
nFail = nFail + check(isequal(size(project.T1.img), size(expected.project.T1.img)) && ...
    isequal(project.S2, project.T1.vol.mat(1:3,:)), 'the MRI and its S2 are in', ...
    sprintf('%dx%dx%d voxels', size(project.T1.img)));
nFail = nFail + check(isempty(project.electrodes) && isempty(project.targets), ...
    'the previous arrays are gone', '');
nFail = nFail + check(isempty(work.GS) && isempty(work.brushCrd) && isempty(work.FileName), ...
    'the previous work in progress is gone', '');
nFail = nFail + check(strcmp(work.v_MNI, before.work.v_MNI) && isequaln(work.options, options), ...
    'shared resources and options stay', '');

%% ------------------------------------------------------------ the options
fprintf('\n--- cfg ------------------------------------------------------\n');

cfg = []; cfg.mri = mriFile; cfg.voxdim = [1 1 1];
p1 = ielec.newProject(cfg, [], before.work);
vprm = spm_imatrix(p1.T1.vol.mat);
nFail = nFail + check(max(abs(abs(vprm(7:9)) - 1)) < 1e-9, 'cfg.voxdim is used', ...
    sprintf('%g %g %g mm', abs(vprm(7:9))));

cfg = []; cfg.mri = string(mriFile);
% Modulo the history, like its neighbour below, and for the reason the
% nameContacts check had: both sides are layer calls, each records a step of
% its own, and RECORDSTEP writes the date to the second - so compared whole
% this passed or failed on whether the two calls fell in the same clock
% second. It failed once in a suite run and passed alone, which is what that
% looks like from the outside.
%
% What the whole-project comparison was asserting by accident is checked
% outright instead: CHECKCFG turns a scalar string into a char, so the step a
% string path records is the same step a char path records, and nothing of
% class string reaches the .iel file.
fromString = ielec.newProject(cfg, [], before.work);
nFail = nFail + check(isequaln(withoutHistory(fromString), withoutHistory(project)), ...
    'a string works as well as a char', '');
nFail = nFail + check(ischar(fromString.history{end}.cfg.mri), ...
    'and the step it records holds a char, not a string', ...
    class(fromString.history{end}.cfg.mri));

p2 = ielec.newProject(struct('mri', mriFile), [], []);
nFail = nFail + check(isequaln(withoutHistory(p2), withoutHistory(project)), ...
    'a script can start from no work at all', '');

cfg = []; cfg.mri = mriFile; cfg.T1file = mriFile;   % a misspelt option
nFail = nFail + check(strcmp(errorId(@() ielec.newProject(cfg, [], before.work)), ...
    'ielec:unknownOption'), 'an unknown option is refused, not ignored', 'cfg.T1file');

nFail = nFail + check(strcmp(errorId(@() ielec.newProject([], [], before.work)), ...
    'ielec:missingOption'), 'a missing cfg.mri is refused', '');

cfg = []; cfg.mri = fullfile(folder, 'there_is_no_such.nii');
nFail = nFail + check(strcmp(errorId(@() ielec.newProject(cfg, [], before.work)), ...
    'ielec:noSuchFile'), 'a missing file is refused by name', '');

%% --------------------------------------------------------- layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.newProject) == 3 && nargout(@ielec.newProject) == 2, ...
    '[project, work] = ielec.newProject(cfg, project, work)', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - ielec.newProject starts a project as the New button did.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% The New button before the layer, from reading the MRI to the end of the
% project reset. defaultGuiVariables is left out: it only runs first, in both
% versions, and the work it leaves is what both are given.

function handles = originalNewButton(handles, PathName, T1file)
    [T1]=loading_images_SPM(PathName,T1file,4,handles.work.options.image_voxdim); %interpolation = 4
    handles=newProject(handles,T1);   % empty project around the new MRI
    handles.work.maxValue=[];
end

% ---------------------------------------------------------------------
function file = writeTinyMRI(folder)
% A 10x12x8 volume with 2 mm voxels and an oblique-free transformation.
file = fullfile(folder, 'tinyT1.nii');
V.fname   = file;
V.dim     = [10 12 8];
V.dt      = [spm_type('int16') 0];
V.mat     = [2 0 0 -10; 0 2 0 -12; 0 0 2 -8; 0 0 0 1];
V.pinfo   = [1; 0; 0];
V.descrip = 'iElectrodes test MRI';
[x, y, z] = ndgrid(1:V.dim(1), 1:V.dim(2), 1:V.dim(3));
img = round(100 * (x + 2*y + 3*z));
spm_write_vol(V, img);
end

function id = errorId(f)
id = '';
try
    f();
catch err
    id = err.identifier;
end
end

function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-52s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-52s %s\n', what, detail);  bad = 1;
end
end
