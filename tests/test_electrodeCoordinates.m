function ok = test_electrodeCoordinates()
%TEST_ELECTRODECOORDINATES  Check the contact list the exports are built on.
%
%   ok = test_electrodeCoordinates() compares ELECTRODECOORDINATES with the
%   two loops it replaced in SaveElectrodespushtool_ClickedCallback, which
%   are kept verbatim in local functions at the bottom of this file. It runs
%   against examples/exampleNativeSpace.iel. No figure is opened.
%
%   Every export format - EEGLAB, FieldTrip, BIDS - starts from this list, so
%   an error here would be written into all of them at once, in a file
%   someone then loads into another toolbox. That is the kind of mistake
%   nobody notices until the electrodes are in the wrong place in a figure.
%
%   The two loops were nearly identical, differing only in where they read
%   the coordinates from: the contacts themselves, or the first projection.
%   Both are checked.
%
%   Usage:  cd into the repository, then
%              test_electrodeCoordinates
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ELECTRODECOORDINATES.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

ielFile = fullfile(repoRoot,'examples','exampleNativeSpace.iel');
loaded  = load(ielFile,'-mat');
prj     = checkProjectStructure(loaded.s);
electrodes = prj.electrodes;

nFail = 0;

nContacts = 0;
for j = 1:numel(electrodes), nContacts = nContacts + electrodes{j}.nElectrodes; end
fprintf('\n   %d arrays, %d contacts\n', numel(electrodes), nContacts);

%% contacts
fprintf('\n--- source ''contacts'' ---------------------------------------\n');
expected = originalContactsLoop(electrodes);
actual   = electrodeCoordinates(electrodes, 'contacts');
nFail = nFail + compare(expected, actual, nContacts);

byDefault = electrodeCoordinates(electrodes);
nFail = nFail + check(isequal(actual, byDefault), 'contacts is the default', '');

%% projections
fprintf('\n--- source ''projection'' -------------------------------------\n');
hasProjection = true;
for j = 1:numel(electrodes)
    if ~isfield(electrodes{j},'projection') || isempty(electrodes{j}.projection)
        hasProjection = false;
    end
end
if ~hasProjection
    fprintf('  --        not every array in this project has a projection\n');
else
    expected = originalProjectionLoop(electrodes);
    actual   = electrodeCoordinates(electrodes, 'projection');
    nFail = nFail + compare(expected, actual, nContacts);

    onContacts = electrodeCoordinates(electrodes, 'contacts');
    nFail = nFail + check(~isequal(actual.x, onContacts.x), ...
        'projected coordinates differ from the contacts', '');
    nFail = nFail + check(isequal(actual.label, onContacts.label), ...
        'but the labels are the same', '');
end

%% edge cases
fprintf('\n--- edge cases -----------------------------------------------\n');
empty = electrodeCoordinates({});
nFail = nFail + check(isempty(empty.x) && isempty(empty.label) && ...
                      isempty(empty.type) && isempty(empty.anatomicalLabel), ...
    'no arrays gives empty lists, not an error', '');

threw = false;
try
    electrodeCoordinates(electrodes, 'somewhere else');
catch err
    threw = strcmp(err.identifier, 'electrodeCoordinates:unknownSource');
end
nFail = nFail + check(threw, 'an unknown source is refused by name', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the contact list is what the inline loops produced.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ---------------------------------------------------------------------
function bad = compare(expected, actual, nContacts)
bad = 0;
names = {'x','y','z','label','type','projectionMethod','anatomicalLabel'};
for k = 1:numel(names)
    thisField = names{k};
    same = isequaln(expected.(thisField), actual.(thisField));
    bad = bad + check(same, thisField, sprintf('%d entries', numel(actual.(thisField))));
    if ~same && numel(expected.(thisField)) ~= numel(actual.(thisField))
        fprintf('              original %d, extracted %d\n', ...
            numel(expected.(thisField)), numel(actual.(thisField)));
    end
end
bad = bad + check(numel(actual.x) == nContacts, 'one entry per contact', '');
end

% ---------------------------------------------------------------------
function c = originalContactsLoop(electrodes)
%ORIGINALCONTACTSLOOP  The export callback's first loop, kept verbatim.
i=1; x=[]; y=[]; z=[];
for j=1:length(electrodes)
    for k=1:electrodes{j}.nElectrodes
        %get coordinates
        x(i)=electrodes{j}.x(k);
        y(i)=electrodes{j}.y(k);
        z(i)=electrodes{j}.z(k);
        type{i} = electrodes{j}.Type;
        projMethod{i}='none';
        anatLabel{i}=electrodes{j}.aLabels{k};
        cl{i}=electrodes{j}.ch_label{k};
        i=i+1;
    end
end
c = pack(x,y,z,cl,type,projMethod,anatLabel);
end

% ---------------------------------------------------------------------
function c = originalProjectionLoop(electrodes)
%ORIGINALPROJECTIONLOOP  The export callback's second loop, kept verbatim.
i=1; x=[]; y=[]; z=[];
for j=1:length(electrodes)
    for k=1:electrodes{j}.nElectrodes
        %get coordinates
        x(i)=electrodes{j}.projection{1}.x(k); % export first projection (SCE for now)
        y(i)=electrodes{j}.projection{1}.y(k);
        z(i)=electrodes{j}.projection{1}.z(k);
        type{i} = electrodes{j}.Type;
        projMethod{i}=electrodes{j}.projection{1}.method;
        anatLabel{i}=electrodes{j}.projection{1}.aLabels{k};
        cl{i}=electrodes{j}.ch_label{k};
        i=i+1;
    end
end
c = pack(x,y,z,cl,type,projMethod,anatLabel);
end

% ---------------------------------------------------------------------
function c = pack(x,y,z,cl,type,projMethod,anatLabel)
c.x = x; c.y = y; c.z = z;
c.label = cl; c.type = type;
c.projectionMethod = projMethod;
c.anatomicalLabel  = anatLabel;
end

% ---------------------------------------------------------------------
function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-30s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-30s %s\n', what, detail);  bad = 1;
end
end
