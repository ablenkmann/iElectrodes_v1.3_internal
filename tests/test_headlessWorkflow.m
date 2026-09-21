function ok = test_headlessWorkflow()
%TEST_HEADLESSWORKFLOW  Run the whole workflow from a script and check it.
%
%   ok = test_headlessWorkflow() runs examples/exampleHeadlessWorkflow.m -
%   open, threshold, select, weigh, cluster, fit, add, label, export, save
%   and reopen - and checks what each step produced.
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
