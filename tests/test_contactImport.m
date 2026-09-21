function ok = test_contactImport()
%TEST_CONTACTIMPORT  Check the import steps taken out of the Load button.
%
%   ok = test_contactImport() compares GROUPCONTACTSBYARRAY and
%   ELECTRODEARRAYFROMCONTACTS with the code that used to sit inside
%   LoadElectrodespushtool_ClickedCallback, kept verbatim in local functions
%   below. No figure is opened.
%
%   The input is a real round trip. The arrays of
%   examples/exampleNativeSpace.iel are flattened into one list of labels
%   and positions with ELECTRODECOORDINATES - exactly what the EEGLAB and
%   FieldTrip exports write - and then imported back. Every array has to come
%   back with its own name, contacts, labels and positions.
%
%   The dialog in between, where the user says what kind of array each one
%   is, is replaced by the type and dimensions of the original array.
%
%   Usage:  cd into the repository, then
%              test_contactImport
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also GROUPCONTACTSBYARRAY, ELECTRODEARRAYFROMCONTACTS,
%   ELECTRODECOORDINATES.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

ielFile = fullfile(repoRoot,'examples','exampleNativeSpace.iel');
loaded  = load(ielFile,'-mat');
prj     = checkProjectStructure(loaded.s);

% what an export would have written
crd    = electrodeCoordinates(prj.electrodes, 'contacts');
labels = crd.label;
pos    = [crd.x(:) crd.y(:) crd.z(:)];

fprintf('\n   %d arrays, %d contacts exported\n', numel(prj.electrodes), numel(labels));

nFail = 0;

%% ------------------------------------------------ grouping, against the old loop
fprintf('\n--- grouping contacts, against the code from the Load button --\n');

[expNames, expIndex] = originalGrouping(labels);
[actNames, actIndex] = groupContactsByArray(labels);

nFail = nFail + check(isequal(expNames, actNames), 'same arrays found', strjoin(actNames, ' '));
nFail = nFail + check(isequal(expIndex, actIndex), 'every contact in the same array', '');

%% -------------------------------------------- building, against the old block
fprintf('\n--- building arrays, against the code from the Load button ----\n');

for i = 1:numel(actNames)
    % the answers the user would give in the dialog: the original array's own
    % type and size when there is one, otherwise a plausible depth electrode
    source = findArray(prj.electrodes, actNames{i});
    if isempty(source)
        answer = {'depth', 1, sum(actIndex==i)};
    else
        answer = {source.Type, source.rows, source.columns};
    end
    expArray = originalBuild(actNames{i}, labels, pos, actIndex, i, answer{:});
    actArray = electrodeArrayFromContacts(actNames{i}, labels(actIndex==i), pos(actIndex==i,:), answer{:});
    nFail = nFail + check(isequaln(expArray, actArray), actNames{i}, ...
        sprintf('%s, %d contacts', actArray.Type, actArray.nElectrodes));
end

%% ------------------------------------------------------- the round trip
fprintf('\n--- exported and imported back --------------------------------\n');

recovered = 0;
for j = 1:numel(prj.electrodes)
    e = prj.electrodes{j};
    i = find(strcmp(actNames, e.Name), 1);
    if isempty(i)
        fprintf('  note      array %s does not come back under its own name: its\n', e.Name);
        fprintf('            contact labels do not carry the array name\n');
        continue
    end
    back = electrodeArrayFromContacts(actNames{i}, labels(actIndex==i), pos(actIndex==i,:), ...
                                      e.Type, e.rows, e.columns);
    same = back.nElectrodes == e.nElectrodes && ...
           max(abs(back.x(:) - e.x(:))) == 0 && ...
           max(abs(back.y(:) - e.y(:))) == 0 && ...
           max(abs(back.z(:) - e.z(:))) == 0 && ...
           isequal(back.ch_label(:), e.ch_label(:));
    nFail = nFail + check(same, sprintf('%s: same contacts, labels and positions', e.Name), ...
        sprintf('%d contacts', back.nElectrodes));
    recovered = recovered + 1;
end

if recovered == numel(prj.electrodes)
    nFail = nFail + check(numel(actNames) == numel(prj.electrodes), ...
        'no extra arrays appear', sprintf('%d arrays', numel(actNames)));
end

%% ------------------------------------------- the two properties in the help
fprintf('\n--- the naming convention -------------------------------------\n');

[n1, i1] = groupContactsByArray({'TR1','G1','TR2','G2'});
nFail = nFail + check(isequal(n1, {'G','TR'}) && isequal(i1(:)', [2 1 2 1]), ...
    'names come back sorted, not in file order', strjoin(n1, ' '));

n2 = groupContactsByArray({'G1a','L1A'});
nFail = nFail + check(isequal(sort(n2), sort({'Ga','LA'})), ...
    'the name is all the letters, not just the prefix', strjoin(n2, ' '));

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - imported contacts become the same arrays as before.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function a = findArray(arrays, name)
a = [];
for j = 1:numel(arrays)
    if strcmp(arrays{j}.Name, name), a = arrays{j}; return, end
end
end

% ===================== the original code, kept verbatim =====================
% From LoadElectrodespushtool_ClickedCallback.

function [labelsArray, ic] = originalGrouping(labels)
N=length(labels);
% get array names
for i=1:N
    l=labels{i};
    d=isstrprop(l, 'alpha');
    labelsAlpha{i}=l(d);
end
[labelsArray,~,ic]=unique(labelsAlpha); % ic==i contains the indexes to the electrodes in array labelsArray(i)
end

% The loop body from the same place, for array i, with the answers from
% elecImportDlg passed in.

function e = originalBuild(name, labels, pos, ic, i, type, rows, columns)
elecNew = {};
% define the basic fields
elecNew{i}.Name=name;
elecNew{i}.nElectrodes=sum(ic==i);
elecNew{i}.x=pos(ic==i,1);
elecNew{i}.y=pos(ic==i,2);
elecNew{i}.z=pos(ic==i,3);
elecNew{i}.rows=rows;
elecNew{i}.columns=columns;
elecNew{i}.ch_label=labels(ic==i);
elecNew{i}.Type=type;
elecNew{i}.adjMat=makeAdjMat(rows,columns);
elecNew{i}=checkElectrodeStructure(elecNew{i}); % check one by one. Makes it easy to detect errors
e = elecNew{i};
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-50s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-50s %s\n', what, detail);  bad = 1;
end
end
