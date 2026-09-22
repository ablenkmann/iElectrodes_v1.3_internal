function ok = test_sessionState()
%TEST_SESSIONSTATE  Check that new fields of work never reach the .iel file.
%
%   ok = test_sessionState() puts the two fields the GUI now keeps in work -
%   the Localize panel's settings (work.localization) and the voxels on
%   offer for selection (work.candidateVoxels) - into a real project, saves
%   it with WRITEIELFILE, and checks that the file comes out with exactly the
%   fields it has without them. No figure is opened.
%
%   The reason it holds: CHECKPROJECTSTRUCTURE writes a fixed set of fields
%   and drops anything else. That is what lets the GUI keep state in work
%   without changing what a .iel file contains - and this test is what
%   would notice if that ever stopped being true.
%
%   Usage:  cd into the repository, then
%              test_sessionState
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also WRITEIELFILE, CHECKPROJECTSTRUCTURE.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

nFail = 0;
[project, work] = loadProject(fullfile(repoRoot, 'examples', 'exampleNativeSpace.iel'));

plainFile   = [tempname '.iel'];
sessionFile = [tempname '.iel'];
cleanup = onCleanup(@() cellfun(@deleteIfThere, {plainFile, sessionFile}));

fprintf('\n--- saving with and without the new fields ------------------\n');
writeIelFile(plainFile, project, work);

withSession = work;
withSession.localization = struct('thresholdLow',0.5,'thresholdHigh',1,'denoiseKernel',1, ...
                                  'nClusters',64,'rows',8,'columns',8);
withSession.candidateVoxels = rand(100, 3);
writeIelFile(sessionFile, project, withSession);

plain   = load(plainFile,   '-mat');
session = load(sessionFile, '-mat');

nFail = nFail + check(~isfield(session.s, 'localization') && ~isfield(session.s, 'candidateVoxels'), ...
    'neither new field is in the file', '');
nFail = nFail + check(isequal(sort(fieldnames(plain.s)), sort(fieldnames(session.s))), ...
    'the file has exactly the fields it has without them', ...
    sprintf('%d fields', numel(fieldnames(session.s))));

% work.options has always been in work too, and has never been in the file
nFail = nFail + check(isfield(work, 'options') && ~isfield(session.s, 'options'), ...
    'nor is work.options, as before', 'never written');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - state kept in work stays out of the project file.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function deleteIfThere(file)
if isfile(file), delete(file); end
end

function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-52s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-52s %s\n', what, detail);  bad = 1;
end
end
