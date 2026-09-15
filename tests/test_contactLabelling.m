function ok = test_contactLabelling()
%TEST_CONTACTLABELLING  Check the two contact-naming functions, head-less.
%
%   ok = test_contactLabelling() exercises NAMEARRAYCONTACTS and
%   APPLYCONTACTLABELS on the arrays of examples/exampleNativeSpace.iel and
%   on a deliberately wrong input, without opening a figure.
%
%   These two functions are what the Auto and List buttons under "Label
%   electrodes" do once the dialogs have collected their input. Before the
%   v2 restructuring the naming loops sat inside those callbacks, so the
%   only way to run them was to click.
%
%   Usage:  cd into the repository, then
%              tests/test_contactLabelling
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

ielFile = fullfile(repoRoot,'examples','exampleNativeSpace.iel');
loaded  = load(ielFile,'-mat');
prj     = checkProjectStructure(loaded.s);

nFail = 0;
fprintf('\n--- nameArrayContacts -------------------------------------\n');
for a = 1:numel(prj.electrodes)
    e = prj.electrodes{a};
    before = e.ch_label;
    e = nameArrayContacts(e, 'ZZ');

    nFail = nFail + check(strcmp(e.Name,'ZZ'), ...
        sprintf('array %d renamed', a), e.Name);
    nFail = nFail + check(numel(e.ch_label)==e.nElectrodes, ...
        sprintf('array %d label count', a), numel(e.ch_label));
    nFail = nFail + check(isequal(e.ch_label{1},'ZZ1') && ...
                          isequal(e.ch_label{end},['ZZ' int2str(e.nElectrodes)]), ...
        sprintf('array %d numbering', a), [e.ch_label{1} ' .. ' e.ch_label{end}]);
    nFail = nFail + check(~isequal(before, e.ch_label) || e.nElectrodes==0, ...
        sprintf('array %d labels actually changed', a), '');
end

fprintf('\n--- applyContactLabels ------------------------------------\n');
e = prj.electrodes{1};
wanted = arrayfun(@(k) sprintf('CH%02d',k), 1:e.nElectrodes, 'UniformOutput', false);
e2 = applyContactLabels(e, wanted, 'FromList');
nFail = nFail + check(isequal(e2.ch_label(1:e.nElectrodes), wanted), 'labels applied', '');
nFail = nFail + check(strcmp(e2.Name,'FromList'), 'array renamed', e2.Name);

e3 = applyContactLabels(e, wanted);
nFail = nFail + check(strcmp(e3.Name, e.Name), 'name kept when not given', e3.Name);

fprintf('\n--- a wrong-length list must be refused, not applied -------\n');
tooFew = wanted(1:end-1);
threw  = false;
try
    applyContactLabels(e, tooFew);
catch err
    threw = strcmp(err.identifier,'applyContactLabels:wrongCount');
end
nFail = nFail + check(threw, 'short list rejected', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - contact labelling behaves as specified.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-32s %s\n', what, num2str(detail));
    bad = 0;
else
    fprintf('  FAILED    %-32s %s\n', what, num2str(detail));
    bad = 1;
end
end
