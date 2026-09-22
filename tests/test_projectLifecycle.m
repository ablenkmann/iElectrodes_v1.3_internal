function ok = test_projectLifecycle()
%TEST_PROJECTLIFECYCLE  Check newProject, writeIelFile and readIelFile.
%
%   ok = test_projectLifecycle() exercises the three functions the New, Save
%   and Open buttons now call. No figure is opened, and no file dialog: that
%   is all the buttons add.
%
%   It builds a small project by hand rather than using the examples, so it
%   runs in a moment and so the values it checks are ones this file chose.
%   ROUNDTRIP_PROJECT and TEST_PROJECTGROUPS already compare a real 47 MB
%   project field by field; the point here is the three functions.
%
%   The check worth naming is that NEWPROJECT leaves alone what it has no
%   business touching. Emptying a project must not throw away the MNI
%   template surfaces and the atlas, which are loaded once at start-up and
%   live in work, nor the graphics in ui. If it did, New would work and then
%   MNI labelling would quietly stop.
%
%   Usage:  cd into the repository, then
%              test_projectLifecycle
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also NEWPROJECT, WRITEIELFILE, READIELFILE.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end

nFail = 0;

%% ------------------------------------------------------------- newProject
fprintf('\n--- newProject -----------------------------------------------\n');

T1.img     = zeros(4,5,6,'single');
T1.vol.mat = [2 0 0 -10; 0 2 0 -20; 0 0 2 -30; 0 0 0 1];

% what a running GUI already holds when New is pressed
before.work.v_MNI     = 'shared resource, must survive';
before.work.selection = struct('array',3,'contact',7);
before.ui.colors      = 'graphics setting, must survive';
before.ui.figureThing = 'a graphics handle would live here';
before.somethingElse  = 'not one of the three groups';

state = newProject(before, T1);

nFail = nFail + check(isequaln(state.project.T1, T1), 'the MRI is in the project', '');
nFail = nFail + check(isequal(state.project.S2, T1.vol.mat(1:3,:)), ...
    'S2 comes from the MRI transformation', '');
nFail = nFail + check(isempty(state.project.electrodes), 'no electrodes yet', '');
nFail = nFail + check(isempty(state.project.targets), 'no planning arrays yet', '');
nFail = nFail + check(isempty(state.project.TAC), 'no CT yet', '');
nFail = nFail + check(ischar(state.project.currentSpace), ...
    'currentSpace is set', sprintf('"%s"', state.project.currentSpace));
nFail = nFail + check(isempty(state.work.FileName) && isempty(state.work.PathName), ...
    'the project has no file yet', '');

nFail = nFail + check(strcmp(state.work.v_MNI, before.work.v_MNI), ...
    'shared resources in work survive', '');
nFail = nFail + check(isequal(state.work.selection, before.work.selection), ...
    'the selection in work survives', '');
nFail = nFail + check(strcmp(state.ui.colors, before.ui.colors), ...
    'settings in ui survive', '');
nFail = nFail + check(strcmp(state.ui.figureThing, before.ui.figureThing), ...
    'graphics in ui survive', '');
nFail = nFail + check(strcmp(state.somethingElse, before.somethingElse), ...
    'fields outside the three groups are untouched', '');

leftFlat = {};
for g = {'project','work','ui'}
    names = feval([g{1} 'FieldNames']);
    for k = 1:numel(names)
        if isfield(state, names{k}), leftFlat{end+1} = names{k}; end %#ok<AGROW>
    end
end
nFail = nFail + check(isempty(leftFlat), 'nothing is left at the top level', ...
    strjoin(leftFlat, ' '));

%% ------------------------------------------- writeIelFile then readIelFile
fprintf('\n--- writeIelFile and readIelFile -----------------------------\n');

% enough of a project for checkProjectStructure to keep the colour caches:
% they are only kept when the data they were derived from is there too
state.project.verticesR         = rand(5,3);
state.project.verticesL         = rand(4,3);
state.project.facesR            = [1 2 3; 3 4 5];
state.project.facesL            = [1 2 3];
state.project.AnnotLabel_R      = (1:5)';
state.project.AnnotLabel_L      = (1:4)';
state.project.AnnotColortable_R = struct('table', [255 0 0 0 1]);
state.project.AnnotColortable_L = struct('table', [0 255 0 0 2]);
state.project.wmparc            = struct('img', int32(zeros(2,2,2)));
state.project.wmparcS           = [eye(3) zeros(3,1)];
state.project.currentSpace      = 'Native';

state.ui.AnnotColor_R = rand(5,3);
state.ui.AnnotColor_L = rand(4,3);
state.ui.wmparcColors = rand(2,2,2,3);

tmpFile = fullfile(tempdir, 'ielectrodes_lifecycle.iel');
if isfile(tmpFile), delete(tmpFile); end

writeIelFile(tmpFile, state.project, state.work, state.ui);
nFail = nFail + check(isfile(tmpFile), 'the file is written', ...
    sprintf('%.1f kB', dirBytes(tmpFile)/1e3));

s = readIelFile(tmpFile);
nFail = nFail + check(isstruct(s), 'and read back', '');

nFail = nFail + check(isequaln(s.T1, T1), 'the MRI survives', '');
nFail = nFail + check(isequal(s.S2, T1.vol.mat(1:3,:)), 'S2 survives', '');
nFail = nFail + check(strcmp(s.currentSpace,'Native'), 'currentSpace survives', '');

for f = {'AnnotColor_R','AnnotColor_L','wmparcColors'}
    thisField = f{1};
    nFail = nFail + check(isfield(s, thisField) && ...
        isequaln(s.(thisField), state.ui.(thisField)), ...
        sprintf('%s survives, from ui', thisField), '');
end

% Reported, not asserted: checkProjectStructure turns an empty mask into a
% copy of the MRI with an empty img, because its "old .mat mask" branch tests
% ~isstruct and [] is not a struct. Worth knowing when reading a .iel of a
% project that was saved before a CT and mask were loaded.
if isfield(s,'mask') && isstruct(s.mask) && isfield(s.mask,'img') && isempty(s.mask.img)
    fprintf('  note      a project with no mask is written as an empty copy of the MRI\n');
end

% the whole way round, the way the Open button does it
reopened = checkProjectStructure(s);
reopened = liftToUi(liftToWork(liftToProject(reopened)));
nFail = nFail + check(isequaln(reopened.project.verticesR, state.project.verticesR), ...
    'a reopened project has its surfaces back', '');
nFail = nFail + check(isequaln(reopened.ui.AnnotColor_R, state.ui.AnnotColor_R), ...
    'and its colour caches, back in ui', '');

delete(tmpFile);

%% ---------------------------------------------------- readIelFile refuses
fprintf('\n--- readIelFile on something that is not a project -----------\n');

nFail = nFail + check(threw(@() readIelFile(fullfile(tempdir,'no_such_file.iel')), ...
    'readIelFile:noSuchFile'), 'a missing file is named as such', '');

notAProject = fullfile(tempdir, 'ielectrodes_notaproject.mat');
somethingElse = 42;                                        %#ok<NASGU>
save(notAProject, 'somethingElse');
nFail = nFail + check(threw(@() readIelFile(notAProject), 'readIelFile:notAProject'), ...
    'a file without s is refused, not silently loaded', '');
delete(notAProject);

notMatlab = fullfile(tempdir, 'ielectrodes_notmatlab.iel');
fid = fopen(notMatlab, 'w');
fprintf(fid, 'this is a text file, not a MAT-file\n');
fclose(fid);
nFail = nFail + check(threw(@() readIelFile(notMatlab), 'readIelFile:notAProject'), ...
    'a file that is not MATLAB at all is refused too', '');
delete(notMatlab);

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - new, save and open behave as specified.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function yes = threw(fcn, identifier)
yes = false;
try
    fcn();
catch err
    yes = strcmp(err.identifier, identifier);
    if ~yes
        fprintf('              threw %s instead of %s\n', err.identifier, identifier);
    end
end
end

% ---------------------------------------------------------------------
function b = dirBytes(f)
d = dir(f);
b = d.bytes;
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-48s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-48s %s\n', what, detail);  bad = 1;
end
end
