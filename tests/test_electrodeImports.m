function ok = test_electrodeImports()
%TEST_ELECTRODEIMPORTS  Check the three import readers.
%
%   ok = test_electrodeImports() exercises READELECTRODESTRUCTURE,
%   READEEGLABELECTRODES and READFIELDTRIPELECTRODES against the code that
%   used to sit inside LoadElectrodespushtool_ClickedCallback, kept verbatim
%   in local functions below. No figure is opened and no file dialog.
%
%   Two of the three are checked by writing a file with this toolbox's own
%   export writer and reading it straight back, which is the round trip a
%   user actually does. The EEGLAB reader gets a small dataset built here,
%   since the repository ships no .set file.
%
%   The EEGLAB axis swap is the part worth a test of its own. A .set stores
%   coordinates in EEGLAB's convention and the reader returns [-Y X Z]; get
%   that wrong and every imported contact is mirrored, which looks plausible
%   in a 3-D view and is not.
%
%   Usage:  cd into the repository, then
%              test_electrodeImports
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also READELECTRODESTRUCTURE, READEEGLABELECTRODES,
%   READFIELDTRIPELECTRODES, TEST_ELECTRODEEXPORTS.

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
tmp = @(name) fullfile(tempdir, ['ielectrodes_import_' name]);

%% ------------------------------------------- iElectrodes .mat, cell array
fprintf('\n--- iElectrodes electrodes structure --------------------------\n');
writeElectrodeStructure(tmp('cell.mat'), electrodes);

expected = originalStructureRead(tmp('cell.mat'));
actual   = readElectrodeStructure(tmp('cell.mat'));
nFail = nFail + check(isequaln(expected, actual), 'same as the inline code', ...
    sprintf('%d arrays', numel(actual)));
nFail = nFail + check(iscell(actual), 'a cell array comes back', '');

%% ------------------------------------- iElectrodes .mat, old struct array
fprintf('\n--- the same file written the old way, as a struct array ------\n');
% the same array twice, so the struct array is well formed whatever fields
% the project's arrays happen to differ in
saveAsStructArray(tmp('struct.mat'), {electrodes{1}, electrodes{1}});

fromStruct = readElectrodeStructure(tmp('struct.mat'));
nFail = nFail + check(iscell(fromStruct), 'a struct array is converted to a cell', ...
    sprintf('%d arrays', numel(fromStruct)));
nFail = nFail + check(numel(fromStruct) == 2, 'with one entry per array', '');
nFail = nFail + check(strcmp(fromStruct{1}.Name, electrodes{1}.Name), ...
    'and the arrays survive the conversion', fromStruct{1}.Name);

%% --------------------------------------------------------------- EEGLAB
fprintf('\n--- EEGLAB dataset -------------------------------------------\n');
EEG.chanlocs = struct('labels', {'A1','A2','B1'}, ...
                      'X', {1,2,3}, 'Y', {4,5,6}, 'Z', {7,8,9});        %#ok<STRNU>
save(tmp('dataset.set'), 'EEG');

[expLabels, expPos] = originalEEGLABread(tmp('dataset.set'));
[actLabels, actPos] = readEEGLABelectrodes(tmp('dataset.set'));
nFail = nFail + check(isequal(expLabels, actLabels), 'same labels as the inline code', '');
nFail = nFail + check(isequaln(expPos, actPos), 'same positions', '');

nFail = nFail + check(isequal(actLabels, {'A1','A2','B1'}), 'the labels are read', '');
nFail = nFail + check(isequal(actPos, [-4 1 7; -5 2 8; -6 3 9]), ...
    'the axes are swapped to [-Y X Z]', '');

%% ------------------------------------------------------------ FIELDTRIP
fprintf('\n--- FIELDTRIP elec structure ---------------------------------\n');
crd = electrodeCoordinates(electrodes);
writeFieldTripElectrodes(tmp('elec.mat'), crd, electrodes, prj.currentSpace, 'No');

[expLabels, expPos] = originalFieldTripRead(tmp('elec.mat'));
[actLabels, actPos] = readFieldTripElectrodes(tmp('elec.mat'));
nFail = nFail + check(isequal(expLabels, actLabels), 'same labels as the inline code', '');
nFail = nFail + check(isequaln(expPos, actPos), 'same positions', ...
    sprintf('%d contacts', size(actPos,1)));
nFail = nFail + check(isequal(actPos, [crd.x' crd.y' crd.z']), ...
    'what was exported comes back unchanged', '');

fprintf('\n--- contacts with no coordinate ------------------------------\n');
elec.label   = {'A1';'A2';'A3'};
elec.elecpos = [1 2 3; NaN NaN NaN; 7 8 9];                              %#ok<STRNU>
save(tmp('withnan.mat'), 'elec');

[expLabels, expPos] = originalFieldTripRead(tmp('withnan.mat'));
[actLabels, actPos] = readFieldTripElectrodes(tmp('withnan.mat'));
nFail = nFail + check(isequal(expLabels, actLabels) && isequaln(expPos, actPos), ...
    'same as the inline code', '');
nFail = nFail + check(isequal(actPos, [1 2 3; 7 8 9]), 'the NaN row is dropped', '');
nFail = nFail + check(isequal(actLabels, {'A1';'A3'}), 'and so is its label', '');

%% ----------------------------------------------------------- refusals
fprintf('\n--- files that are not what was asked for --------------------\n');
notThis = 42;                                                            %#ok<NASGU>
save(tmp('wrong.mat'), 'notThis');

% load() warns before the readers get a chance to say anything, and here the
% variable is missing on purpose - so that warning is expected, not a result
wasOn = warning('off', 'MATLAB:load:variableNotFound');
restoreWarnings = onCleanup(@() warning(wasOn));

nFail = nFail + check(threw(@() readElectrodeStructure(tmp('wrong.mat')), ...
    'readElectrodeStructure:notElectrodes'), 'no electrodes variable', '');
nFail = nFail + check(threw(@() readEEGLABelectrodes(tmp('wrong.mat')), ...
    'readEEGLABelectrodes:notADataset'), 'no EEG structure', '');
nFail = nFail + check(threw(@() readFieldTripElectrodes(tmp('wrong.mat')), ...
    'readFieldTripElectrodes:notAnElecStructure'), 'no elec structure', '');

clear restoreWarnings

%% clean up
for name = {'cell.mat','struct.mat','dataset.set','elec.mat','withnan.mat','wrong.mat'}
    if isfile(tmp(name{1})), delete(tmp(name{1})); end
end

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the import readers read what the inline code read.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================

function elecNew = originalStructureRead(fullPath)
s=load(fullPath,'electrodes');
electrodes=s.electrodes;
if isstruct(electrodes)
    electrodes2=electrodes;
    clear electrodes
    for i=1:length(electrodes2)
        electrodes{i}=electrodes2(i);
    end
    clear electrodes2
end
elecNew=checkElectrodeStructure(electrodes);
end

function [labels, pos] = originalEEGLABread(fullPath)
load(fullPath,'EEG','-mat'); %load as matlab file EEG structure
labels={EEG.chanlocs.labels};
pos = [-[EEG.chanlocs.Y];  [EEG.chanlocs.X];  [EEG.chanlocs.Z] ]';
end

function [labels, pos] = originalFieldTripRead(fullPath)
s=load(fullPath,'elec'); %load as matlab file elec structure
labels=s.elec.label;
pos=s.elec.elecpos;
% remove if there is any NaN coordinate electrode
i=find(sum(isnan(pos)')');
pos(i,:)=[];
labels(i)=[];
end

% ============================== small helpers ==============================

function saveAsStructArray(fullPath, cellOfArrays)
% write the arrays the way old files hold them: a struct array, not a cell
electrodes = cellOfArrays{1};
for j = 2:numel(cellOfArrays)
    electrodes(j) = cellOfArrays{j};                                     %#ok<AGROW>
end
save(fullPath, 'electrodes');
end

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

function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-44s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-44s %s\n', what, detail);  bad = 1;
end
end
