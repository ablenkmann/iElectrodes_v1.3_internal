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
%   The BIDS json is compared the same way, which means this test currently
%   REQUIRES the two misspelled keys - IndendedFor and
%   iEEGCoordinateProcessingDescripton. That is deliberate: see
%   docs/OPEN_QUESTIONS.md item 12. When the spelling is corrected, this test
%   has to be updated in the same commit, which is exactly the point.
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
fprintf('\n--- BIDS coordinate system (.json) ---------------------------\n');
intendedFor = prj.TAC.vol.fname;
reference   = 'Blenkmann et al., 2017. https://doi.org/10.3389/fninf.2017.00014 ';

writeBIDScoordinateSystem(new('.json'), intendedFor, 'none', reference);
originalBIDSjson(old('.json'), intendedFor, 'none', reference);
nFail = nFail + check(sameFile(new('.json'), old('.json')), 'identical file', ...
    sprintf('%d bytes', bytesOf(new('.json'))));

written = fileread(new('.json'));
nFail = nFail + check(contains(written,'"iEEGCoordinateSystem":"ScanRAS"'), ...
    'the coordinate system is named', '');
nFail = nFail + check(contains(written,'"IndendedFor"'), ...
    'the misspelled IndendedFor is still written', 'OPEN_QUESTIONS item 12');
nFail = nFail + check(contains(written,'"iEEGCoordinateProcessingDescripton"'), ...
    'and the misspelled Descripton', 'OPEN_QUESTIONS item 12');

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

function originalBIDSjson(fullPath, intendedFor, processing, reference)
coordSys = struct( 'iEEGCoordinateSystem', 'ScanRAS',...
    'iEEGCoordinateUnits','mm', ...
    'IndendedFor',  intendedFor,...
    'iEEGCoordinateSystemDescription', 'Coordinates system is RAS from imported CT image.',...
    'iEEGCoordinateProcessingDescripton', processing,...
    'iEEGCoordinateProcessingReference', reference);
fid=fopen(fullPath,'w');
encodedJSON = jsonencode(coordSys);
fprintf(fid, encodedJSON);
fclose (fid);
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
