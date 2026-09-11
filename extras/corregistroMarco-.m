%update 29-April-2016
%Alejandro Blenkmann
%ablenkmann@gmail.com

addpath(genpath('/home/alejandro/Documents/MATLAB/toolbox/spm8'));
tic
%addpath(genpath('/data/data1/Processing/Images/electrodes/codigos'))
addpath(genpath('/data/Images/electrodes/codigos'))


spm_jobman('initcfg');
spm('defaults', 'FMRI');

marcoArriba=1;

subPath='/data/Images/HEC012/2nd_time-Automated/';

fileTACmarco=[subPath 'TACmarco/TAC_marco.nii'];
filerTACmarco=[subPath 'TACmarco/rTAC_marco.nii'];
fileTACmarcoN=[subPath 'TACmarco/TAC_marco_N.nii'];
filepatron=[subPath 'TACmarco/TAC_marco_arribaNew.nii'];
fileT1=[subPath 'T1pre/T1.nii'];
filewparc=[subPath 'T1pre/wmparc.nii'];
filerT1=[subPath 'T1pre/rT1.nii'];
filerwparc=[subPath 'T1pre/rwmparc.nii'];
fileTACpost=[subPath 'TACpost/TAC_post.nii'];
filerTACpost=[subPath 'TACpost/rTAC_post.nii'];

fileLeftPial=[subPath 'T1pre/lh.pial'];
fileRightPial=[subPath 'T1pre/rh.pial'];
filerLeftPial=[subPath 'T1pre/rlh.pial'];
filerRightPial=[subPath 'T1pre/rrh.pial'];

filePlanning=[subPath 'T1pre/planning.mat'];
filerPlanning=[subPath 'T1pre/rplanning.mat'];


%% check dimensions and orientation
spm_image('init',fileTACmarco) 

%% find traslation in Z automatically (beta!)
v=spm_vol(fileTACmarco);
x = spm_read_vols(v);
[~, t]=max(squeeze(mean(mean(x)))); %find out peak along z axis
if marcoArriba
    v.mat(3,4)=-t/v.mat(3,3)-12; %12mm = half of frame width -> the superior border
else
    v.mat(3,4)=-t/v.mat(3,3)+12; %12mm = half of frame width -> the inferior border
end
spm_get_space(fileTACmarco,v.mat); %set new space transformation (or spm_write_vol(v,x))


%% (omitir?) MANUAL: hacer el reorient de la imagen TACmarco. Alinear aproximadamente al sistema de coordenadas de la TAC patron

% a) buscar las coordenas que serian las adecuadas para el origen en el
% sistema de coordenadas del marco 
% b) cargar las coordenas cambiadas de signo en los campos x y z 
% c) aplicar Reorient Images a la imagen TACmarco.nii
% d) chequear que la coordenada 0 0 0 este en el origen dek sistema de
% coordenadas del marco

spm_image('init',fileTACmarco) 

%%  Umbralizar TAC marco paciente

matlabbatch{1}.spm.util.imcalc.input = {fileTACmarco};
matlabbatch{1}.spm.util.imcalc.output = fileTACmarcoN;
matlabbatch{1}.spm.util.imcalc.outdir = {''};
matlabbatch{1}.spm.util.imcalc.expression = 'i1.*(i1>1600).*(i1<3000)';
matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{1}.spm.util.imcalc.options.mask = 0;
matlabbatch{1}.spm.util.imcalc.options.interp = 0;
matlabbatch{1}.spm.util.imcalc.options.dtype = 4;

spm_jobman('run', matlabbatch);
clear matlabbatch

%% chequear imagen umbralizada 
spm_image('init',fileTACmarcoN)


%% visualize - check registration - Before correg
%if the images are not close, the algorithm fail!! It is not robust to
%small changes 
p=strvcat(filepatron,fileTACmarco,fileTACmarcoN);
spm_check_registration(p,{'Patron','TAC marco', 'TAC marco N'})

%% estimate TAC_marco_N -> TAC_marco patron

% VG    - handle for reference image (see spm_vol).
VolN=spm_vol(fileTACmarcoN);
% VF    - handle for source (moved) image.
VolP=spm_vol(filepatron);

eoptions.cost_fun = 'nmi'; %'ncc'
eoptions.sep = [4 2];
eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
eoptions.fwhm = [7 7];

% estimate
matTACpre2marco = spm_coreg(VolP,VolN,eoptions);
MatTACpre2marco   = spm_matrix(matTACpre2marco);
save ('matTACpre2marco.mat','MatTACpre2marco');

disp('estimate TACmarco done')

%% reslice TAC_marco -> TAC_marco patron = rTAC_marco
Mi  = inv(MatTACpre2marco);
%MM = spm_get_space(fileTACmarcoN);  % read from the input file
MM=VolN.mat;
% set transformation to images
spm_get_space(fileTACmarco,Mi*MM); % change, and write to the input file
spm_get_space(fileTACmarcoN,Mi*MM); % change, and write to the input file

P = str2mat(filepatron,fileTACmarco,fileTACmarcoN); % filenames for reslicing

roptions.interp = 1;
roptions.wrap = [0 0 0];
roptions.mask = 0;
roptions.mean  = 0;
roptions.which = 1;  % reslice all, except first file (patron)
roptions.prefix = 'r';

spm_reslice(P,roptions);

disp('reslice TACmarco done')


%% visualize - check registration
p=strvcat(filepatron,filerTACmarco);
spm_check_registration(p,{'Patron','r TAC marco'})


%% guardar sistema original de coordenadas
VolT1orig=spm_vol(fileT1);

%% (omitir?) MANUAL: hacer el reorient de la imagen T1pre y aplicar mismo realign a WMPARC !!!!
%Alinear aproximadamente al sistema de coordenadas de la TAC patron

% a) buscar las coordenas que serian las adecuadas para el origen en el
% sistema de coordenadas del marco 
% b) cargar las coordenas cambiadas de signo en los campos x y z 
% c) aplicar Reorient Images a la imagen T1pre.nii wmparc
% d) chequear que la coordenada 0 0 0 este en el origen dek sistema de
% coordenadas del marco

spm_image('init',fileT1)

%% guardar los valores de traslación manual
VolT1post=spm_vol(fileT1);
save('traslacionT1.mat','VolT1orig','VolT1post');

%% estimate T1pre -> rTACmarco

% VG    - handle for reference image (see spm_vol).
VolT1=spm_vol(fileT1);
% VF    - handle for source (moved) image.
VolrTAC=spm_vol(filerTACmarco);

eoptions.cost_fun = 'nmi';
eoptions.sep = [4 2];
eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
eoptions.fwhm = [7 7];

% estimate
matT12marco = spm_coreg(VolrTAC,VolT1,eoptions);
MatT12marco   = spm_matrix(matT12marco);
save ('matT12marco.mat','MatT12marco')

disp('estimate T1pre done')

%% reslice T1pre -> rTACmarco = rT1pre / rwmparc
Mi  = inv(MatT12marco);
%MM = spm_get_space(fileTACmarcoN);  % read from the input file
MM=VolT1.mat;
% set transformation to images
spm_get_space(fileT1,Mi*MM); % change, and write to the input file
spm_get_space(filewparc,Mi*MM); % change, and write to the input file

% T1 reslice
P = str2mat(filepatron,fileT1); % filenames for reslicing
roptions.interp = 1;
roptions.wrap = [0 0 0];
roptions.mask = 0;
roptions.mean  = 0;
roptions.which = 1;  % reslice all, except first file (patron)
roptions.prefix = 'r';

spm_reslice(P,roptions);

% wparc near neghbour interpolation 
P = str2mat(filepatron,filewparc); % filenames for reslicing
roptions.interp = 0;
spm_reslice(P,roptions);

disp('reslice T1pre done')
disp('reslice wparc done')
toc

%% visualize - check registration
p=strvcat(filerT1, filerwparc,   fileTACmarco);
spm_check_registration(p,{'rT1','r wparc', 'r TAC marco'})


%% T1 original a rT1 
% 
% 
% fileT1orig=[subPath 'T1pre/T1orig.nii'];
% 
% VolT1orig=spm_vol(fileT1orig);
% 
% VolrT1=spm_vol(filerT1);
% 
% eoptions.cost_fun = 'nmi';
% eoptions.sep = [4 2];
% eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
% eoptions.fwhm = [7 7];
% 
% % estimate
% matT1orig2rT1 = spm_coreg(VolrT1,VolT1orig,eoptions);
% MatT1orig2rT1   = spm_matrix(matT1orig2rT1);
% save ('matT1orig2rT1.mat','MatT1orig2rT1')
% 
% disp('estimate T1pre done')









%% apply transformation to planning coords and pial surface

addpath('/data/data1/Processing/Images/electrodes/codigos/');
addpath(genpath('/data/data1/Processing/Images/electrodes/iso2mesh'));

[vl,fl]=read_surf(fileLeftPial);
%[vl,fl]=meshresample(vl,fl,0.2);

[vr,fr]=read_surf(fileRightPial);
%[vr,fr]=meshresample(vr,fr,0.2);

% translacion
load('traslacionT1.mat')
Dorig=VolT1orig.mat;
Dpost=VolT1post.mat;

MD=inv(Dorig)*(Dpost);

%D=VolT1post.mat(1:3,4)-VolT1orig.mat(1:3,4);
%MD=[1 0 0 D(1); 0 1 0 D(2); 0 0 1 D(3); 0 0 0 1];

% matriz de transformacion inversa de coregistro
Mi=inv(MatT12marco); 


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

% elegir algunas coordenadas en rT1.nii y plotear para chequear el correcto
% corregistro y transformacion
scatter3(-9,7,33,'ko', 'filled')
scatter3(65,-15,-32,'ko', 'filled')
scatter3(-30,28,-67,'ko', 'filled')

%% aplico transformacion al planning

%load targets
load (filePlanning)
targets2=transformTargets(targets,MD);
targets2=transformTargets(targets2,Mi);

targets=targets2;
save(filerPlanning,'targets')
toc
%% ////////////////////////////////////////////////////////////////////////
% ////////////////////////           Cx           /////////////////////////
% /////////////////////////////////////////////////////////////////////////

%% 3) TACpost.nii --->> rT1.nii


%% reset image orientation? Test...
V    = spm_vol(fileTACpost);
M    = V.mat;
vox  = sqrt(sum(M(1:3,1:3).^2));
if det(M(1:3,1:3))<0, vox(1) = -vox(1); end
orig = (V.dim(1:3)+1)/2;
off  = -vox.*orig;
M    = [vox(1) 0      0      off(1)
    0      vox(2) 0      off(2)
    0      0      vox(3) off(3)
    0      0      0      1];
spm_get_space(fileTACpost,M); %set new space transformation
        
%% MANUAL (omitir?): hacer el reorient de la imagen TACpost. Alinear aproximadamente al sistema de coordenadas de la TAC patron

% a) buscar las coordenas que serian las adecuadas para el origen en el
% sistema de coordenadas del marco 
% b) cargar las coordenas cambiadas de signo en los campos x y z 
% c) aplicar Reorient Images a la imagen TACpost.nii
% d) chequear que la coordenada 0 0 0 este en el origen dek sistema de
% coordenadas del marco

spm_image('init',fileTACpost)

%% estimate TACpost -> rT1pre

% VG    - handle for reference image (see spm_vol).
VolrT1=spm_vol(filerT1);
% VF    - handle for source (moved) image.
VolTACpost=spm_vol(fileTACpost);

eoptions.cost_fun = 'nmi';
eoptions.sep = [4 2];
eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
eoptions.fwhm = [7 7];

% estimate
matTACpost2marco = spm_coreg(VolrT1,VolTACpost,eoptions);
MatTACpost2marco   = spm_matrix(matTACpost2marco);
save ('MatTACpost2marco.mat','MatTACpost2marco')

disp('estimate TACmpost done')

%% reslice TACpost -> rT1pre = rTACpost
Mi  = inv(MatTACpost2marco);
%MM = spm_get_space(fileTACmarcoN);  % read from the input file
MM=VolTACpost.mat;
% set transformation to images
spm_get_space(fileTACpost,Mi*MM); % change(set), and write to the input file

% TACpost reslice
P = str2mat(filepatron,fileTACpost); % filenames for reslicing
roptions.interp = 1;
roptions.wrap = [0 0 0];
roptions.mask = 0;
roptions.mean  = 0;
roptions.which = 1;  % reslice all, except first file (patron)
roptions.prefix = 'r';

spm_reslice(P,roptions);
disp('reslice TACpost done')

%% visualize - check registration
p=strvcat(filerT1, filerTACpost);
spm_check_registration(p,{'rT1','r TAC post'})


