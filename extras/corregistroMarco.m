% All images are cooregister to the stereotactic frame space defined by r256CT_PATTERN_frame_down_1mm.nii
% reoriented images names xx.nii are named as rxx.nii
% this script uses SPM8 
% First part of the code can be run previous to surgery. 
% Second part can be run after surgery

% add SPM8 path
addpath(genpath('/spm8/'));

spm_jobman('initcfg');
spm('defaults', 'FMRI');

% subject folder
subPath='/subjectXX/';

% image files
fileCTframe=[subPath 'CTframe/CT_frame.nii'];    % subject CT with frame
filerCTframe=[subPath 'CTframe/rCT_frame.nii'];  % reoriented CT with frame
fileCTframeN=[subPath 'CTframe/CT_frame_N.nii']; % CT with thresholded N   
filepattern=[subPath 'CTframe/r256CT_PATTERN_frame_down_1mm.nii']; % Frame pattern (provided)
fileT1=[subPath 'T1pre/T1.nii']; 		 % subject T1 MRI (native space)
filewparc=[subPath 'T1pre/wmparc.nii']; 	 % brain parcellation obtainded from Freesurfer
filerT1=[subPath 'T1pre/rT1.nii']; 		 % reoriented subject T1 MRI
filerwparc=[subPath 'T1pre/rwmparc.nii']; 	 % reoriented brain parcellation
fileCTpost=[subPath 'CTpost/CTpost.nii']; 	 % Post implantation CT
filerCTpost=[subPath 'CTpost/rCTpost.nii']; 	 % reoriented post implantation CT

% surface files
fileLeftPial=[subPath 'T1pre/lh.pial'];  	 % left hemisphere pial surface obtainded from Freesurfer
fileRightPial=[subPath 'T1pre/rh.pial']; 	 % right hemisphere surface
filerLeftPial=[subPath 'T1pre/rlh.pial'];	 % reoriented pial surface   
filerRightPial=[subPath 'T1pre/rrh.pial'];	 % reoriented pial surface   

% planning electrodes files
filePlanning=[subPath 'T1pre/planning.mat'];	 % planning structure obtained from iElectrodes (in T1 MRI native space)
filerPlanning=[subPath 'T1pre/rplanning.mat'];	 % reoriented planning coordinates


%% MANUAL: reorient CTframe (translation only). Align aproximatelly to CT_PATTERN

% a) buscar las coordenas que serian las adecuadas para el origen en el
% sistema de coordenadas del frame 
% b) cargar las coordenas cambiadas de signo en los campos x y z 
% c) aplicar Reorient Images a la imagen CTpost.nii
% d) chequear que la coordenada 0 0 0 este en el origen dek sistema de
% coordenadas del frame

spm_image
%%  Threshold CT frame 

matlabbatch{1}.spm.util.imcalc.input = {fileCTframe};
matlabbatch{1}.spm.util.imcalc.output = fileCTframeN;
matlabbatch{1}.spm.util.imcalc.outdir = {''};
matlabbatch{1}.spm.util.imcalc.expression = 'i1.*(i1>1600).*(i1<3000)';
matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{1}.spm.util.imcalc.options.mask = 0;
matlabbatch{1}.spm.util.imcalc.options.interp = 0;
matlabbatch{1}.spm.util.imcalc.options.dtype = 4;

spm_jobman('run', matlabbatch);
clear matlabbatch

%% Check threshold
spm_image

%% estimate CT_frame_N -> CT_frame pattern

% VG    - handle for reference image (see spm_vol).
VolN=spm_vol(fileCTframeN);
% VF    - handle for source (moved) image.
VolP=spm_vol(filepattern);

eoptions.cost_fun = 'nmi'; %'ncc'
eoptions.sep = [4 2];
eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
eoptions.fwhm = [7 7];

% estimate
matCTpre2frame = spm_coreg(VolP,VolN,eoptions);
MatCTpre2frame   = spm_matrix(matCTpre2frame);
save ('matCTpre2frame.mat','MatCTpre2frame');

disp('estimate CTframe done')

%% reslice CT_frame -> CT_frame pattern = rCT_frame
Mi  = inv(MatCTpre2frame);
%MM = spm_get_space(fileCTframeN);  % read from the input file
MM=VolN.mat;
% set transformation to images
spm_get_space(fileCTframe,Mi*MM); % change, and write to the input file
spm_get_space(fileCTframeN,Mi*MM); % change, and write to the input file

P = str2mat(filepattern,fileCTframe,fileCTframeN); % filenames for reslicing

roptions.interp = 1;
roptions.wrap = [0 0 0];
roptions.mask = 0;
roptions.mean  = 0;
roptions.which = 1;  % reslice all, except first file (pattern)
roptions.prefix = 'r';

spm_reslice(P,roptions);

disp('reslice CTframe done')
%% MANUAL: reorient T1pre (translation only). Apply the exactly the same transform to wmparc. Align both to CT pattern aproximatelly

VolT1orig=spm_vol(fileT1);
% a) buscar las coordenas que serian las adecuadas para el origen en el
% sistema de coordenadas del frame 
% b) cargar las coordenas cambiadas de signo en los campos x y z 
% c) aplicar Reorient Images a la imagen CTpost.nii
% d) chequear que la coordenada 0 0 0 este en el origen dek sistema de
% coordenadas del frame

spm_image

%% save translation 
VolT1post=spm_vol(fileT1);
save('traslacionT1.mat','VolT1orig','VolT1post');

%% estimate T1pre -> rCTframe

% VG    - handle for reference image (see spm_vol).
VolT1=spm_vol(fileT1);
% VF    - handle for source (moved) image.
VolrCT=spm_vol(filerCTframe);

eoptions.cost_fun = 'nmi';
eoptions.sep = [4 2];
eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
eoptions.fwhm = [7 7];

% estimate
matT12frame = spm_coreg(VolrCT,VolT1,eoptions);
MatT12frame   = spm_matrix(matT12frame);
save ('matT12frame.mat','MatT12frame')

disp('estimate T1pre done')

%% reslice T1pre -> rCTframe = rT1pre / rwmparc
Mi  = inv(MatT12frame);
%MM = spm_get_space(fileCTframeN);  % read from the input file
MM=VolT1.mat;
% set transformation to images
spm_get_space(fileT1,Mi*MM); % change, and write to the input file
spm_get_space(filewparc,Mi*MM); % change, and write to the input file

% T1 reslice
P = str2mat(filepattern,fileT1); % filenames for reslicing
roptions.interp = 1;
roptions.wrap = [0 0 0];
roptions.mask = 0;
roptions.mean  = 0;
roptions.which = 1;  % reslice all, except first file (pattern)
roptions.prefix = 'r';

spm_reslice(P,roptions);

% wparc near neghbour interpolation 
P = str2mat(filepattern,filewparc); % filenames for reslicing
roptions.interp = 0;
spm_reslice(P,roptions);

disp('reslice T1pre done')
disp('reslice wparc done')
toc

%% apply transformation to planning coords and pial surface

addpath('/data/data1/Processing/Images/electrodes/codigos/');
addpath(genpath('/data/data1/Processing/Images/electrodes/iso2mesh'));

[vl,fl]=read_surf(fileLeftPial);
%[vl,fl]=meshresample(vl,fl,0.2);

[vr,fr]=read_surf(fileRightPial);
%[vr,fr]=meshresample(vr,fr,0.2);

% traslation
load('traslacionT1.mat')
D=VolT1post.mat(1:3,4)-VolT1orig.mat(1:3,4);
MD=[1 0 0 D(1); 0 1 0 D(2); 0 0 1 D(3); 0 0 0 1];

% inverese transformation matrix
Mi=inv(MatT12frame);

vl2=[vl ones(length(vl),1)];
vr2=[vr ones(length(vr),1)];

vl2d=MD*vl2';
vr2d=MD*vr2';


V3l=Mi*vl2d;
V3r=Mi*vr2d;

% write surfaces in the corregistered space 
write_surf(filerLeftPial,V3l(1:3,:)',fl)
write_surf(filerRightPial,V3r(1:3,:)',fr)

%% plot
figure;
vis(V3l(1:3,:)',fl);
hold on;
vis (V3r(1:3,:)',fr);
axis image
shading interp; 
lighting phong; material dull; camlight;
title 'coreg  space'

%% transform planning

%load targets
load (filePlanning)
targets2=transformTargets(targets,MD);
targets2=transformTargets(targets2,Mi);

targets=targets2;
save(filerPlanning,'targets')
toc


%% ////////////////////////////////////////////////////////////////////////
% /////////////      Second part after surgery    /////////////////////////
% /////////////////////////////////////////////////////////////////////////

%% 3) CTpost.nii --->> rT1.nii

%% MANUAL: reorient CTpost (translation only). Align aproximatelly to CT_PATTERN

% a) buscar las coordenas que serian las adecuadas para el origen en el
% sistema de coordenadas del frame 
% b) cargar las coordenas cambiadas de signo en los campos x y z 
% c) aplicar Reorient Images a la imagen CTpost.nii
% d) chequear que la coordenada 0 0 0 este en el origen dek sistema de
% coordenadas del frame

spm_image

%% estimate CTpost -> rT1pre

% VG    - handle for reference image (see spm_vol).
VolrT1=spm_vol(filerT1);
% VF    - handle for source (moved) image.
VolCTpost=spm_vol(fileCTpost);

eoptions.cost_fun = 'nmi';
eoptions.sep = [4 2];
eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
eoptions.fwhm = [7 7];

% estimate
matCTpost2frame = spm_coreg(VolrT1,VolCTpost,eoptions);
MatCTpost2frame   = spm_matrix(matCTpost2frame);
save ('MatCTpost2frame.mat','MatCTpost2frame')

disp('estimate CTmpost done')

%% reslice CTpost -> rT1pre = rCTpost
Mi  = inv(MatCTpost2frame);
%MM = spm_get_space(fileCTframeN);  % read from the input file
MM=VolCTpost.mat;
% set transformation to images
spm_get_space(fileCTpost,Mi*MM); % change, and write to the input file

% CTpost reslice
P = str2mat(filepattern,fileCTpost); % filenames for reslicing
roptions.interp = 1;
roptions.wrap = [0 0 0];
roptions.mask = 0;
roptions.mean  = 0;
roptions.which = 1;  % reslice all, except first file (pattern)
roptions.prefix = 'r';

spm_reslice(P,roptions);
disp('reslice CTpost done')



