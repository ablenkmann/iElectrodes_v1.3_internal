function ok = test_ielecSurfaces()
%TEST_IELECSURFACES  Check ielec.loadSurfaces, buildEnvelope, loadAnnotations.
%
%   ok = test_ielecSurfaces() takes the surfaces of the example project,
%   writes them back out as a pair of ASCII surface files, reads them in
%   again through the layer, and compares the project with the steps the two
%   surface buttons ran themselves, kept verbatim below. It then builds the
%   smooth cortical envelope both ways - around a pair of small spheres and
%   with a small closing radius, not around the brain, because BUILDSCE costs
%   what the closing radius costs and the test would pay for it four times -
%   and clears the annotations both ways. The two envelopes are compared as
%   surfaces rather than vertex by vertex, because BUILDSCE is not
%   reproducible (docs/OPEN_QUESTIONS.md item 29).
%
%   Reading a pair of .annot files is not covered: an annotation is a
%   FreeSurfer binary layout, and the example project carries the labels but
%   not the files they came from. READ_ANNOTATION and ANNOTATIONCOLOURS are
%   unchanged, and tests/test_surfaceHelpers.m checks the colours against the
%   project's own.
%
%   Usage:  cd into the repository, then
%              test_ielecSurfaces
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.LOADSURFACES, IELEC.BUILDENVELOPE, IELEC.LOADANNOTATIONS.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
for f = {'src','app','assets','third_party'}
    thisFolder = fullfile(repoRoot, f{1});
    if isfolder(thisFolder), addpath(genpath(thisFolder)); end
end
spm('defaults','PET');

nFail = 0;
figuresBefore = numel(findall(0, 'Type', 'figure'));

cfgOpen = [];
cfgOpen.file = fullfile(repoRoot, 'examples', 'exampleNativeSpace.iel');
[project, work] = ielec.openProject([], [], cfgOpen);

folder = tempname;
mkdir(folder);
cleanup = onCleanup(@() removeFolder(folder)); %#ok<NASGU>

% the example's own envelope, written out as the pair of files a button
% would be given. It is small enough to read back quickly.
rightFile = writeAscSurface(fullfile(folder, 'rh.surface.asc'), ...
                            project.vertices_SCE_R, project.faces_SCE_R);
leftFile  = writeAscSurface(fullfile(folder, 'lh.surface.asc'), ...
                            project.vertices_SCE_L, project.faces_SCE_L);

readable = true;
backR = []; backL = [];
try
    [backR, ~, backL] = readSurfacePair(rightFile, leftFile);
catch err
    readable = false;
    fprintf('  (the surface files could not be read back: %s)\n', err.message);
end
readable = readable && isequal(size(backR), size(project.vertices_SCE_R)) && ...
                       isequal(size(backL), size(project.vertices_SCE_L));
nFail = nFail + check(readable, ...
    'the example surfaces can be written and read back whole', ...
    sprintf('%s and %s vertices', mat2str(size(backR,1)), mat2str(size(backL,1))));

%% ---------------------------------------------- loadSurfaces, as the button
if readable
fprintf('\n--- ielec.loadSurfaces against the surface buttons ------------\n');

% the resample target is below what the files hold, so the thinning branch
% is really taken: the example's envelope is already at 15000, where
% resampleSurfacePair returns at once and a wrongly thinned pair would look
% exactly like a whole one
for thisCase = {{'pial', false, []}, {'pial', true, []}, ...
                {'envelope', false, 4000}, {'envelope', true, 4000}}
    [target, centre, resample] = thisCase{1}{:};

    expected = originalLoad(project, rightFile, leftFile, target, centre, resample);

    cfg = [];
    cfg.right    = rightFile;
    cfg.left     = leftFile;
    cfg.target   = target;
    cfg.centre   = centre;
    cfg.resample = resample;
    [loaded, loadedWork] = ielec.loadSurfaces(project, work, cfg);

    nFail = nFail + check(isequaln(loaded, expected), ...
        sprintf('%s, centre %d, resample %s', target, centre, mat2str(resample)), ...
        sprintf('%d vertices', size(surfaceOf(loaded, target), 1)));
    nFail = nFail + check(isequaln(loadedWork, work), ...
        '   work is not changed', '');
end

plain = ielec.loadSurfaces(project, work, ...
                           struct('right', rightFile, 'left', leftFile));
nFail = nFail + check(isequal(plain.currentSpace, project.currentSpace), ...
    'the space is left to the button, as it always was', project.currentSpace);
nFail = nFail + check(isequal(size(plain.verticesR), size(backR)) && ...
        isequal(size(plain.verticesL), size(backL)), ...
    'and the pial pair is kept whole - the annotation needs every vertex', ...
    sprintf('%d vertices', size(plain.verticesR,1)));
end

%% ------------------------------------------- buildEnvelope, as the button
fprintf('\n--- ielec.buildEnvelope against the Build branch --------------\n');

% BUILDSCE rasterises the surface into a volume and closes it with a ball,
% so what it costs depends on how much space the surface covers, not on how
% many vertices it has: around a brain it takes minutes, and the test would
% pay for it four times. A pair of small spheres is the same code on a small
% volume, and it is the layer that is being tested, not the algorithm.
small = project;
[small.verticesR, small.facesR] = smallSphere([ 25 0 0]);
[small.verticesL, small.facesL] = smallSphere([-25 0 0]);

% and a small closing radius with them. BUILDSCE pads the surface's bounding
% box by options.buildSCEradius on every side and closes the volume with a
% ball of that size, so the radius - 50 mm for a brain - is what the minutes
% are spent on, not the mesh. Both sides are given the same options, so the
% comparison is unaffected.
buildWork = work;
buildWork.options.buildSCEradius = 6;

expectedBuild = originalBuild(small, buildWork, 1500);
[built, builtWork] = ielec.buildEnvelope(small, buildWork, struct('resample', 1500));

% BUILDSCE is not reproducible: CGAL's surface extractor is randomised, so
% the same surface built twice in one session gives a different number of
% points (docs/OPEN_QUESTIONS.md item 29). The envelopes are therefore
% compared as surfaces - same place, same size, same order of magnitude of
% detail - rather than vertex by vertex.
% three voxels of the raster the envelope is extracted from. BUILDSCE fills
% that default in itself, so the options the project carries need not have it
resolution = 1;
if isfield(buildWork.options, 'resolution')
    resolution = buildWork.options.resolution;
end
tolerance = 3 * resolution;
[sameR, howR] = sameSurface(built.vertices_SCE_R, expectedBuild.vertices_SCE_R, tolerance);
[sameL, howL] = sameSurface(built.vertices_SCE_L, expectedBuild.vertices_SCE_L, tolerance);

nFail = nFail + check(sameR && sameL, ...
    'the envelope is the one the button built', ...
    sprintf('R: %s | L: %s', howR, howL));
nFail = nFail + check(isfield(built, 'faces_SCE_R') && ~isempty(built.faces_SCE_R) && ...
        isfield(built, 'faces_SCE_L') && ~isempty(built.faces_SCE_L), ...
    'and its faces went into the project beside it', '');
nFail = nFail + check(isequaln(builtWork, buildWork), 'work is not changed', '');
nFail = nFail + check(isequaln(rmfield(built, {'vertices_SCE_R','faces_SCE_R', ...
        'vertices_SCE_L','faces_SCE_L'}), ...
        rmfield(small, {'vertices_SCE_R','faces_SCE_R','vertices_SCE_L','faces_SCE_L'})), ...
    'and nothing else in the project is', '');

%% ------------------------------------- loadAnnotations, the "No" branch
fprintf('\n--- ielec.loadAnnotations, clearing them ---------------------\n');

expectedClear = originalClear(project);
[cleared, clearedWork, colours] = ielec.loadAnnotations(project, work, []);

nFail = nFail + check(isequaln(cleared, expectedClear.project), ...
    'the labels and the tables are cleared', '');
nFail = nFail + check(isequaln(colours.right, expectedClear.right) && ...
        isequaln(colours.left, expectedClear.left), ...
    'and every vertex comes back grey', ...
    sprintf('%s and %s', mat2str(size(colours.right)), mat2str(size(colours.left))));
nFail = nFail + check(isequaln(clearedWork, work), 'work is not changed', '');

%% -------------------------------------------------------------- what is refused
fprintf('\n--- what is refused ------------------------------------------\n');

noMRI = project;
noMRI.T1 = [];
nFail = nFail + check(strcmp(errorId(@() ielec.loadSurfaces(noMRI, work, ...
        struct('right', rightFile, 'left', leftFile, 'centre', true))), 'ielec:noMRI'), ...
    'centring with no MRI to centre on', '');
nFail = nFail + check(strcmp(errorId(@() ielec.loadSurfaces(project, work, ...
        struct('right', rightFile, 'left', leftFile, 'target', 'inflated'))), ...
        'ielec:badOption'), 'a target that is neither pial nor envelope', '');
nFail = nFail + check(strcmp(errorId(@() ielec.loadSurfaces(project, work, ...
        struct('right', rightFile))), 'ielec:missingOption'), ...
    'one hemisphere without the other', 'cfg.left');
nFail = nFail + check(strcmp(errorId(@() ielec.loadSurfaces(project, work, ...
        struct('right', rightFile, 'left', leftFile, 'resample', 2.5))), ...
        'ielec:badOption'), 'half a vertex to resample to', '');

noSurfaces = project;
noSurfaces.verticesL = [];
nFail = nFail + check(strcmp(errorId(@() ielec.buildEnvelope(noSurfaces, work, [])), ...
        'ielec:noSurfaces'), 'building an envelope with no pial surface', '');

nFail = nFail + check(strcmp(errorId(@() ielec.loadAnnotations(project, work, ...
        struct('right', 'rh.annot'))), 'ielec:badOption'), ...
    'one annotation without the other', '');
nFail = nFail + check(strcmp(errorId(@() ielec.loadAnnotations(project, work, ...
        struct('both', 'x'))), 'ielec:unknownOption'), ...
    'an unknown option is refused', 'cfg.both');

%% ------------------------------------------------------------ layer rules
fprintf('\n--- the rules of the layer -----------------------------------\n');
nFail = nFail + check(nargin(@ielec.loadSurfaces) == 3 && ...
        nargout(@ielec.loadSurfaces) == 2 && ...
        nargin(@ielec.buildEnvelope) == 3 && ...
        nargout(@ielec.buildEnvelope) == 2 && ...
        nargin(@ielec.loadAnnotations) == 3 && ...
        nargout(@ielec.loadAnnotations) == 3, ...
    'the signatures, the colours as a third output', '');
nFail = nFail + check(numel(findall(0, 'Type', 'figure')) == figuresBefore, ...
    'no window was opened', '');

fprintf('\n');
ok = (nFail == 0);
if ok
    fprintf('PASS - the surfaces are what the buttons put in the project.\n\n');
else
    fprintf('FAIL - %d check(s) failed.\n\n', nFail);
end
if nargout == 0, clear ok; end
end

% ===================== the original code, kept verbatim =====================
% What the two surface buttons did between their dialogs.

function project = originalLoad(project, rFile, lFile, target, centre, resample)
    [vR,fR,vL,fL] = readSurfacePair(rFile, lFile);

    if centre
        % translate pial surfaces to MRI center
        [vR,vL] = centreSurfaces(size(project.T1.img), project.S2, vR, vL);
    end

    if ~isempty(resample)
        %reduce to 15k vertices for nice resolution and speed plots
        [vR,fR,vL,fL] = resampleSurfacePair(vR,fR,vL,fL,resample);
    end

    if strcmp(target, 'pial')
        project.verticesR=vR;
        project.verticesL=vL;
        project.facesR=fR;
        project.facesL=fL;
    else
        project.vertices_SCE_R=vR;
        project.faces_SCE_R=fR;
        project.vertices_SCE_L=vL;
        project.faces_SCE_L=fL;
    end
end

function project = originalBuild(project, work, resample)
    % compute SCE
    [vL,fL] = buildSCE(project.verticesL,project.facesL,work.options);
    [vR,fR] = buildSCE(project.verticesR,project.facesR,work.options);

    %reduce to 15k vertices for nice resolution and speed plots
    [vR,fR,vL,fL] = resampleSurfacePair(vR,fR,vL,fL,resample);

    project.vertices_SCE_R=vR;
    project.faces_SCE_R=fR;
    project.vertices_SCE_L=vL;
    project.faces_SCE_L=fL;
end

function out = originalClear(project)
    project.AnnotLabel_R=[]; %label for each node
    project.AnnotLabel_L=[]; %label for each node
    project.AnnotColortable_R=[]; %colortable info
    project.AnnotColortable_L=[]; %colortable info

    out.project = project;
    out.right = ones(length(project.verticesR),3)*.5;
    out.left  = ones(length(project.verticesL),3)*.5;
end

% ---------------------------------------------------------------------
function [same, how] = sameSurface(a, b, tolerance)
% Two runs of a randomised mesher on the same input describe the same
% surface with different triangles. What can be compared is where that
% surface is and how big it is: both are read off a volume rasterised at
% options.resolution, so neither the box around it nor its centre can move
% by more than a few voxels. TOLERANCE is that, in millimetres; the vertex
% count is allowed a twentieth either way.
if isempty(a) || isempty(b)
    same = false; how = 'one of them is empty'; return
end

box    = max([abs(min(a) - min(b)), abs(max(a) - max(b))]);
centre = max(abs(mean(a) - mean(b)));
count  = abs(size(a,1) - size(b,1)) / size(b,1);

same = box < tolerance && centre < tolerance && count <= 0.05;
how  = sprintf('box %.2f mm, centre %.2f mm, count %.1f%%', box, centre, 100*count);
end

function [vertices, faces] = smallSphere(centre)
% a closed surface small enough for BUILDSCE to wrap in a second
[x, y, z] = sphere(20);
mesh = surf2patch(15*x + centre(1), 15*y + centre(2), 15*z + centre(3), 'triangles');
[vertices, ~, back] = unique(round(mesh.vertices, 6), 'rows', 'stable');
faces = back(mesh.faces);
faces(faces(:,1) == faces(:,2) | faces(:,2) == faces(:,3) | ...
      faces(:,1) == faces(:,3), :) = [];     % the poles collapse to slivers
end

function v = surfaceOf(project, target)
if strcmp(target, 'pial'), v = project.verticesR; else, v = project.vertices_SCE_R; end
end

function file = writeAscSurface(file, vertices, faces)
% a FreeSurfer ASCII surface, which readSurfacePair falls back to
fid = fopen(file, 'w');
if fid < 0
    error('test_ielecSurfaces:cannotWrite', 'Could not write %s.', file);
end
fprintf(fid, '#!ascii version of a surface written by test_ielecSurfaces\n');
fprintf(fid, '%d %d\n', size(vertices,1), size(faces,1));
fprintf(fid, '%f %f %f 0\n', vertices(:,1:3)');
fprintf(fid, '%d %d %d 0\n', (faces(:,1:3) - 1)');
fclose(fid);
end

function removeFolder(folder)
if ~isfolder(folder), return, end
try
    rmdir(folder, 's');
catch
    fclose('all');
    try
        rmdir(folder, 's');
    catch err
        fprintf('  (could not remove %s: %s)\n', folder, err.message);
    end
end
end

function id = errorId(f)
id = '';
try
    f();
catch err
    id = err.identifier;
    if isempty(id), id = err.message; end
end
end

function bad = check(cond, what, detail)
if cond
    fprintf('  ok        %-52s %s\n', what, detail);  bad = 0;
else
    fprintf('  FAILED    %-52s %s\n', what, detail);  bad = 1;
end
end
