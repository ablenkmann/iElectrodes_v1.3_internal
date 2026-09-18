function ok = test_electrodeExports()
%TEST_ELECTRODEEXPORTS  Do the export writers produce the same files as before?
%
%   ok = test_electrodeExports() writes every export format twice - once with
%   the new functions in src/export/, once with the code that used to sit
%   inside SaveElectrodespushtool_ClickedCallback, kept verbatim in local
%   functions below - and compares the two files byte for byte.
%
%   It runs on examples/exampleNativeSpace.iel and writes into the temporary
%   folder. No figure is opened and no file dialog: that is all the callback
%   still adds.
%
%   Byte-for-byte is the right comparison here. These files are read by other
%   toolboxes, so a difference in number formatting, column order or line
%   endings matters as much as a difference in the coordinates.
%
%   The BIDS json is the exception. Two of its keys were misspelled in
%   v1.020 and are now correct, so there is no old output to match - it is
%   checked against the BIDS specification instead, by decoding it.
%
%   Usage:  cd into the repository, then
%              test_electrodeExports
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also ELECTRODECOORDINATES, WRITEEEGLABCOORDINATES,
%   WRITEFIELDTRIPELECTRODES, WRITEBIDSELECTRODES, WRITEBIDSCOORDINATESYSTEM.

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

crd = electrodeCoordinates(electrodes, 'contacts');
x = crd.x; y = crd.y; z = crd.z; cl = crd.label;
type = crd.type; projMethod = crd.projectionMethod; anatLabel = crd.anatomicalLabel;

nFail = 0;
fprintf('\n   %d contacts to export\n', numel(x));

new = @(ext) fullfile(tempdir, ['ielectrodes_export_new'  ext]);
old = @(ext) fullfile(tempdir, ['ielectrodes_export_old'  ext]);

%% ------------------------------------------------- iElectrodes structure
fprintf('\n--- iElectrodes - electrodes structure (.mat) ----------------\n');
writeElectrodeStructure(new('.mat'), electrodes);
originalStructure(old('.mat'), electrodes);
a = load(new('.mat')); b = load(old('.mat'));
nFail = nFail + check(isfield(a,'electrodes'), 'the variable is called electrodes', '');
nFail = nFail + check(isequaln(a.electrodes, b.electrodes), 'same content as before', '');

%% ------------------------------------------------------------- EEGLAB
fprintf('\n--- EEGLAB (.txt) --------------------------------------------\n');
writeEEGLABcoordinates(new('.txt'), crd);
originalEEGLAB(old('.txt'), x, y, z, cl);
nFail = nFail + check(sameFile(new('.txt'), old('.txt')), 'identical file', ...
    sprintf('%d bytes', bytesOf(new('.txt'))));
nFail = nFail + check(countLines(new('.txt')) == numel(x), 'one line per contact', '');

%% ---------------------------------------------------------- FIELDTRIP
fprintf('\n--- FIELDTRIP (.mat) -----------------------------------------\n');
writeFieldTripElectrodes(new('.mat'), crd, electrodes, prj.currentSpace, 'No');
originalFieldTrip(old('.mat'), x, y, z, cl, electrodes, prj.currentSpace, 'No');
a = load(new('.mat')); b = load(old('.mat'));
nFail = nFail + check(isequaln(a.elec, b.elec), 'identical elec structure', '');
nFail = nFail + check(isequal(size(a.elec.elecpos), [numel(x) 3]), ...
    'elecpos is one row per contact', '');
nFail = nFail + check(strcmp(a.elec.cfg.projection,'No'), ...
    'projection is recorded', '');

writeFieldTripElectrodes(new('.mat'), crd, electrodes, prj.currentSpace, 'Yes');
a = load(new('.mat'));
nFail = nFail + check(strcmp(a.elec.cfg.projection,'Yes'), ...
    'and follows what it was told', '');

%% --------------------------------------------------------- BIDS .tsv
fprintf('\n--- BIDS electrodes (.tsv) -----------------------------------\n');
writeBIDSelectrodes(new('.tsv'), crd);
originalBIDStable(old('.tsv'), x, y, z, cl, type, projMethod, anatLabel);
nFail = nFail + check(sameFile(new('.tsv'), old('.tsv')), 'identical file', ...
    sprintf('%d bytes', bytesOf(new('.tsv'))));

header = firstLine(new('.tsv'));
nFail = nFail + check(startsWith(header, sprintf('name\tx\ty\tz\tsize')), ...
    'the five BIDS columns come first, in order', '');

%% -------------------------------------------------------- BIDS .json
% This one is NOT compared against the original code: two of its keys were
% misspelled and are now correct, so the old output is what must not come
% back. It is checked against the BIDS specification instead.
fprintf('\n--- BIDS coordinate system (.json) ---------------------------\n');
intendedFor = prj.TAC.vol.fname;
reference   = 'Blenkmann et al., 2017. https://doi.org/10.3389/fninf.2017.00014 ';

writeBIDScoordinateSystem(new('.json'), intendedFor, 'none', reference);
written = fileread(new('.json'));
nFail = nFail + check(~isempty(written), 'the file is written', ...
    sprintf('%d bytes', bytesOf(new('.json'))));

decoded = [];
try
    decoded = jsondecode(written);
catch err
    fprintf('              %s\n', err.message);
end
nFail = nFail + check(~isempty(decoded), 'and is valid json', '');

if ~isempty(decoded)
    for f = {'iEEGCoordinateSystem','iEEGCoordinateUnits','IntendedFor', ...
             'iEEGCoordinateSystemDescription', ...
             'iEEGCoordinateProcessingDescription', ...
             'iEEGCoordinateProcessingReference'}
        nFail = nFail + check(isfield(decoded, f{1}), ...
            ['BIDS key ' f{1}], '');
    end
    nFail = nFail + check(strcmp(decoded.iEEGCoordinateSystem,'ScanRAS'), ...
        'the coordinate system is named', decoded.iEEGCoordinateSystem);
    nFail = nFail + check(strcmp(decoded.iEEGCoordinateUnits,'mm'), ...
        'the units are mm', '');
end

% the two spellings v1.020 wrote, which a validator ignored
nFail = nFail + check(~contains(written,'"IndendedFor"'), ...
    'the misspelled IndendedFor is gone', '');
nFail = nFail + check(~contains(written,'"iEEGCoordinateProcessingDescripton"'), ...
    'and the misspelled Descripton', '');

% a Windows path used to be read as format escapes, because the text was
% passed to fprintf as the format string
fprintf('\n--- a path with backslashes ----------------------------------\n');
windowsPath = 'C:\temp\new.nii';
writeBIDScoordinateSystem(new('.json'), windowsPath, 'none', reference);
decodedPath = jsondecode(fileread(new('.json')));
nFail = nFail + check(strcmp(decodedPath.IntendedFor, windowsPath), ...
    'the path survives unchanged', decodedPath.IntendedFor);

%% clean up
for ext = {'.mat','.txt','.tsv','.json'}
    if isfile(new(ext{1})), delete(new(ext{1})); end
    if isfile(old(ext{1})), delete(old(ext{1})); end
end

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - every export format writes what it wrote before.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================

function originalStructure(fullPath, electrodes) %#ok<INUSD>
save(fullPath,'electrodes');
end

function originalEEGLAB(fullPath, x, y, z, cl)
fid=fopen(fullPath,'w+'); %overwrite
for i=1:length(x)
    fprintf(fid,'%s\t %e\t %e\t %e\n',cl{i},x(i),y(i),z(i));
end
fclose(fid);
end

function originalFieldTrip(fullPath, x, y, z, cl, electrodes, currentSpace, projection)
elec.label=cl';
elec.elecpos=[x',y',z'];
elec.unit='mm';
elec.coordsys=currentSpace;
elec.adjMat=concatenateAdjMat(electrodes);
elec.cfg.method = 'iElectrodes';
elec.cfg.projection=projection;
save(fullPath,'elec');
end

function originalBIDStable(fullPath, x, y, z, cl, type, projMethod, anatLabel)
elecTable=table(cl', x', y', z', nan(size(x')), type', projMethod', anatLabel', ...
    'VariableNames',{'name','x','y','z','size','Electrode Type','Projection Method','Anatomical Label'});
writetable(elecTable, fullPath,'FileType','text','Delimiter','tab');
end

% ============================== small helpers ==============================

function same = sameFile(a, b)
fa = fopen(a,'r'); da = fread(fa); fclose(fa);
fb = fopen(b,'r'); db = fread(fb); fclose(fb);
same = isequal(da, db);
end

function n = bytesOf(f)
d = dir(f); n = d.bytes;
end

function n = countLines(f)
text = fileread(f);
n = numel(strfind(text, newline));
end

function line = firstLine(f)
text  = fileread(f);
breaks = strfind(text, newline);
if isempty(breaks), line = text; else, line = text(1:breaks(1)-1); end
line = strtrim(line);
end

function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-44s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-44s %s\n', what, detail);  bad = 1;
end
end
