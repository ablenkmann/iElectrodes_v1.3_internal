function ok = test_ielecFitArray()
%TEST_IELECFITARRAY  Check ielec.fitArray, what the Fit button does.
%
%   ok = test_ielecFitArray() builds a project whose CT has four bright
%   blobs 4 mm apart, like a depth electrode, thresholds and selects them,
%   and fits a four-contact depth electrode to them with ielec.fitArray. The
%   result is compared with the Fit button's original steps, kept verbatim
%   below, and the contacts have to land on the blobs.
%
%   It also checks the nailed contacts: the ones in work.GS are used to hold
%   the fit and are consumed, with the previous values kept for Undo.
%
%   GridFit takes a little while even for four contacts.
%
%   Usage:  cd into the repository, then
%              test_ielecFitArray
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.FITARRAY, GRIDFIT, GRIDFITOPTIONS, ELECTRODEFROMGRIDFIT.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

folder = fullfile(tempdir, ['iElectrodes_test_fit_' char(java.util.UUID.randomUUID)]);
mkdir(folder);
removeLater = onCleanup(@() rmdir(folder, 's'));

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

% four blobs in a row, 4 mm apart: a depth electrode with four contacts
dim     = [34 24 20];
centres = [8 12 10; 12 12 10; 16 12 10; 20 12 10];
ct = 100 * ones(dim);
for k = 1:size(centres,1)
    c = centres(k,:);
    ct(c(1)-1:c(1)+1, c(2)-1:c(2)+1, c(3)-1:c(3)+1) = 2000;   % the contact
    ct(c(1), c(2), c(3))                            = 3000;   % its centre, brighter
end
mriFile  = writeVolume(folder, 'tinyT1.nii',   200 * ones(dim));
ctFile   = writeVolume(folder, 'tinyCT.nii',   ct);
maskFile = writeVolume(folder, 'tinyMask.nii', ones(dim));
toWorld  = [-18 -14 -12];                      % from the header below

[project, work] = ielec.newProject(struct('mri', mriFile, 'voxdim', [1 1 1]), [], []);
[project, work] = ielec.loadCT(struct('ct', ctFile, 'mask', maskFile), project, work);

cfgT = [];
cfgT.lowThreshold  = 0.5 * (double(work.maxValue) - double(work.minValue)) + double(work.minValue);
cfgT.highThreshold = 2 * double(work.maxValue);
[project, work] = ielec.thresholdCT(cfgT, project, work);
[project, work] = ielec.selectVoxels(...
        struct('indices', true(size(work.candidateVoxels,1), 1)), project, work);

%% --------------------------------------------- fitArray against the button
fprintf('\n--- ielec.fitArray against the Fit button --------------------\n');

cfg = [];
cfg.type               = 'depth';
cfg.rows               = 1;
cfg.columns            = 4;
cfg.spacing            = 4;
cfg.firstSecondSpacing = 4;

rng(3);
expected = originalFit(project, work, 'depth', 1, 4, 4, 4, 0, [], []);
rng(3);
[project, fitted, array] = ielec.fitArray(cfg, project, work);

nFail = nFail + check(isequaln(array, expected), 'the array is what the button built', ...
    sprintf('%d contacts', array.nElectrodes));
nFail = nFail + check(strcmp(array.Type,'depth') && array.nElectrodes == 4 && ...
        strcmp(array.method,'grid_fit') && strcmp(array.space, project.currentSpace), ...
    'it is a depth array of four contacts, in the project''s space', array.space);
nFail = nFail + check(isempty(project.electrodes), ...
    'the project is not changed - the array is a proposal', '');
nFail = nFail + check(isequaln(fitted.selectedVoxels, work.selectedVoxels), ...
    'the selection is left alone', '');

found = sortrows([array.x array.y array.z], 1);
want  = centres + repmat(toWorld, size(centres,1), 1);
nFail = nFail + check(max(abs(found(:,1) - want(:,1))) < 1.5, ...
    'the contacts are on the four blobs', ...
    sprintf('%.2f mm at most', max(abs(found(:,1) - want(:,1)))));

%% ------------------------------------------------------- nailed contacts
fprintf('\n--- nailed contacts ------------------------------------------\n');

nailed = work;
nailed.GS = want([1 4], :);            % the two ends, already found
nailNumbers = [1; 4];

rng(3);
expectedNailed = originalFit(project, nailed, 'depth', 1, 4, 4, 4, 0, nailNumbers, nailed.GS);
nailCfg = cfg;
nailCfg.useNailedContacts = true;
nailCfg.nailNumbers       = nailNumbers;
rng(3);
[~, afterNails, nailedArray] = ielec.fitArray(nailCfg, project, nailed);

nFail = nFail + check(isequaln(nailedArray, expectedNailed), ...
    'the nailed fit is what the button built', '');
nFail = nFail + check(isequal(nailedArray.methodParameters.NailElectrodeNumber, nailNumbers) && ...
        isequal(nailedArray.methodParameters.NailElectrodeCrd, nailed.GS), ...
    'the nails are recorded with the array', '');
nFail = nFail + check(isempty(afterNails.GS) && isequal(afterNails.oldGS, nailed.GS), ...
    'work.GS is consumed and kept for Undo', '');

% no numbers assigned: the coordinates go in but hold nothing, which is what
% the button did when the table was closed without a choice. What
% gridFitOptions then makes of them is its business - item 20 - so the check
% is again against the button, not against a shape chosen here.
unnumbered = nailCfg;  unnumbered.nailNumbers = [];
rng(3);
expectedUnnumbered = originalFit(project, nailed, 'depth', 1, 4, 4, 4, 0, [], nailed.GS);
rng(3);
[~, afterUnnumbered, unnumberedArray] = ielec.fitArray(unnumbered, project, nailed);
nFail = nFail + check(isequaln(unnumberedArray, expectedUnnumbered), ...
    'with no numbers, still what the button built', ...
    sprintf('coordinates come back %s', ...
            mat2str(size(unnumberedArray.methodParameters.NailElectrodeCrd))));
nFail = nFail + check(isempty(unnumberedArray.methodParameters.NailElectrodeNumber), ...
    'and nothing holds the fit', '');
nFail = nFail + check(isempty(afterUnnumbered.GS), 'work.GS is consumed either way', '');

%% -------------------------------------------------------------- refusals
fprintf('\n--- what is refused ------------------------------------------\n');

nFail = nFail + check(strcmp(errorId(@() ielec.fitArray(setfield(cfg, 'type', 'sphere'), ...
                                                         project, work)), 'ielec:badOption'), ...
    'a type that is not grid, strip or depth', ''); %#ok<SFLD>
nFail = nFail + check(strcmp(errorId(@() ielec.fitArray(setfield(cfg, 'columns', 0), ...
                                                         project, work)), 'ielec:badOption'), ...
    'zero contacts', ''); %#ok<SFLD>
nFail = nFail + check(strcmp(errorId(@() ielec.fitArray(setfield(cfg, 'spacing', -1), ...
                                                         project, work)), 'ielec:badOption'), ...
    'a spacing that is not a distance', ''); %#ok<SFLD>
badNails = nailCfg;  badNails.nailNumbers = [1; 2; 3];
nFail = nFail + check(strcmp(errorId(@() ielec.fitArray(badNails, project, nailed)), ...
        'ielec:badOption'), 'more nail numbers than contacts in work.GS', '');
noContacts = nailCfg;
nFail = nFail + check(strcmp(errorId(@() ielec.fitArray(noContacts, project, work)), ...
        'ielec:badOption'), 'nailed contacts asked for with an empty work.GS', '');
nFail = nFail + check(strcmp(errorId(@() ielec.fitArray(setfield(cfg, 'nElec', 4), project, ...
                                                         work)), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.nElec'); %#ok<SFLD>
nothingSelected = work;  nothingSelected.selectedVoxels = [];
nFail = nFail + check(strcmp(errorId(@() ielec.fitArray(cfg, project, nothingSelected)), ...
        'ielec:noSelection'), 'fitting before selecting', '');

%% --------------------------------------------------------- layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.fitArray) == 3 && nargout(@ielec.fitArray) == 3, ...
    '[project, work, array] = ielec.fitArray(cfg, project, work)', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - ielec.fitArray fits an array as the Fit button did.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% The Fit button from the end of its dialogs to the array, with the dialogs'
% answers and the nail table's answers given as arguments.

function electrodes = originalFit(prj, work, type, rows, cols, fixM1, fixM1_BF, ...
                                  overlap, nailNumbers, nailCoords)
    options = gridFitOptions(work.options, type, rows, cols, fixM1, fixM1_BF, ...
                             overlap, nailNumbers, nailCoords);

    [pos,clusteredCrd,clusteredWeight,clusters] = ...
        gridFit(work.selectedVoxels,work.selectedWeights,rows,cols,options);

    electrodes = electrodeFromGridFit(pos, clusteredCrd, clusteredWeight, clusters, ...
                                      type, rows, cols, prj.currentSpace, options);
end

% ---------------------------------------------------------------------
function file = writeVolume(folder, name, img)
file = fullfile(folder, name);
V.fname   = file;
V.dim     = size(img);
V.dt      = [spm_type('int16') 0];
V.mat     = [1 0 0 -18; 0 1 0 -14; 0 0 1 -12; 0 0 0 1];
V.pinfo   = [1; 0; 0];
V.descrip = 'iElectrodes test volume';
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
