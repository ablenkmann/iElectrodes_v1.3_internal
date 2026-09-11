% For this tutorial we assume: 
% SPM is installed
% Freesurfer is installed
% Fieldtrip is installed
%
% You have CT and T1 MRI images from patientX in nifti format. 
% If you have dicom images convert them using dcm2nii or spm

%% Initialize
addpath('/toolbox/spm8'); % add spm to path
% initialize spm
spm('defaults','fmri');

% add patient folder
pathBase='/data/Images/patientX';

fileT1=[pathBase '/T1.nii'];
fileCT=[pathBase '/CT.nii'];

%% 1. Align MRI to Alignment to Anterior and Posterior Commissure (ACPC)
% AC will have the (0 0 0) coordinate
% PC will be in (0 -y 0) coordinate
% this means, the y axes will cross the AC and PC 
% NOTE: this step (optional) is done to sistematize the processing
% more info http://imaging.mrc-cbu.cam.ac.uk/imaging/FindingCommissures

spm_image('Display',fileT1);
% use the controls below and apply transformation with reorient button

% you can also crop the images to remove unnecesary voxels (for example
% using MRIcron). This will strongly impact the performance of the
% iElectrodes voxels, specially if working with high resolution images or
% when the processing computer has a limitted amount of RAM memory

%% 2. RUN Freesurfer pipeline and localGI
% This process may take up to 24hs.
% Open terminal and type
%
% >> recon-all -s patientX -i /data/Images/patientX/T1.nii -all
%
% Then, if you want to project Grid electrodes to the Smoothed Cortical Envelope (SCE)
% run the following command :
%
% >> recon-all -s patientX -localGI
%

%% 3. Define FS files to use and copy to the working folder

pathFS = ['/data/FS/patientX/']; % Folder to get FreeSurfer Files files
FSimgFiles = {'aparc+aseg.mgz', 'aparc.a2009s+aseg.mgz', 'ribbon.mgz','T1.mgz'}; 
FSsurfFiles = {'lh.pial', 'rh.pial','lh.pial-outer-smoothed','rh.pial-outer-smoothed'};

% Copy FS surface files to local dir
 for i=1:length(FSsurfFiles)
     copyfile([pathFS 'surf/' FSsurfFiles{i}], pathBase); % Freesurfer files
 end
 
% for further use, define: 
fileMask=[pathBase 'ribbon.nii'];
fileAtlasDK=[pathBase 'aparc+aseg.nii']; %Desikan-Killiany 
fileAtlasDx=[pathBase 'aparc.a2009s+aseg.nii']; %Destrieux

%% 4.  Convert images from .mgz to .nii with the function mgz2nii (in the same forlder)
% mgz2nii(path, file, outPath)
% files are exported in RAS coordinate system
% edit mgz2nii.m and set FREESURFER_HOME according to your local FS installation 

for i=1:length(FSimgFiles)
    mgz2nii([pathFS 'mri/'],FSimgFiles{i},pathBase); %you need FS installed!!!
end

%% 5. Check MRI - CT registration
% if not alligned, allign them manually
% Right click on CT -> reorient image -> current image -> manually introduce values and Apply tranformation.
   
p=strvcat(fileT1, fileCT);
spm_check_registration(p,{'T1 ','CT'})


%% 6. estimate CT -> T1pre transformation

% handle for reference image (see spm_vol).
VolT1=spm_vol(fileT1);
% handle for source (moved) image.
VolCT=spm_vol(fileCT);

eoptions.cost_fun = 'nmi'; %normalized mutual information
eoptions.sep = [4 2];
eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
eoptions.fwhm = [7 7];

% estimate transformation
matCT2T1 = spm_coreg(VolT1,VolCT,eoptions);
MatCT2T1   = spm_matrix(matCT2T1);

% save transformation to file
save ([pathBase 'MatCT2T1.mat'],'MatCT2T1')
disp('Coregister estimate done')

%% 7. apply transform to CT  
% This procedure changes the CT header, not a new file

VolT1=spm_vol(fileT1);
VolCT=spm_vol(fileCT);

%load transformation
load ([pathBase 'MatCT2T1.mat'],'MatCT2T1')

Mi  = inv(MatCT2T1);
MM=VolCT.mat;

% set transformation to CT image
spm_get_space(fileCT,Mi*MM); % change(set), and write to the input file

disp('Apply transformations done') 

% NOTE: CT reslice is now done in iElectrodes. Not need to do it here

%% 8. visualize images - check registration (better to do in other visualization software)
p=strvcat(fileT1, filerCT);
spm_check_registration(p,{'T1 ','CT'});

%% ///////////////////////////////////////////////////////////////////////////////////////////////////
%% The next steps are related to normalization only. If you want to work in the native space, stop here

%% 9.  Normalization 
% script for normalization to MNI152 
% credits:  Daniel Mitchell MRC-CBSU, Cambridge, UK

global defaults
defs = defaults.normalise;
    
defs.estimate.weight = '';
estopts.warpreg = 10; % default =  1; was 10
estopts.samp = 1; % could increase this to sacrifice accuracy for speed 

% parameters can be changed in order to improve output
defs.estimate.reg=0.1;  %was 1
defs.estimate.nits=32;  %was 16
defs.estimate.cutoff=25; % was 25

defs.write.vox = [.5 .5 .5];
defs.write.bb = [-90 -126 -72; 91 91 109];

[pth, nam, ext]=fileparts(fileT1);

% Use the ribbon image from freesurfer as a mask to improve normalization
estopts.msk=fileMask;

%prefixes
mT1name=fullfile(pth,['m' nam ext]); %bias corrected
gmname=fullfile(pth,['c1m' nam ext]); % GM
wmname=fullfile(pth,['c2m' nam ext]); % WM
cfname=fullfile(pth,['c3m' nam ext]); % CSF


filemT1=[pathBase 'mT1.nii'];
ToTrans={fileCT,filemT1,fileMask};

disp('Initialize normalisation done')
%% 10. SPM segment and normalize function to do the work
% 2 stage process, as proposed by RH, to increased robustness [djm 13/03/06]

%%%%%%%% 1st pass, bias correction:
estopts.regtype='';    % turn off affine:

out = spm_preproc(fileT1,estopts);
[sn]   = spm_prep2sn(out); % don't write deformation files

% only write out attenuation corrected image
writeopts.biascor = 1;
writeopts.GM  = [0 0 0];
writeopts.WM  = [0 0 0];
writeopts.CSF = [0 0 0];
writeopts.cleanup = [0];
spm_preproc_write(sn,writeopts);

%%%%%%%% 2nd pass using attenuation corrected image
% mstruc should be the attenuation corrected image

matname = fullfile(pth,['m' nam '_seg_sn.mat']);
invmatname = fullfile(pth,['m' nam '_seg_inv_sn.mat']);

estopts.regtype='mni';    % turn on affine again
out = spm_preproc(mT1name,estopts);
spm_prep2sn(out); % do write deformation files

% write out native tissue segmentations
writeopts.biascor = 0;
writeopts.GM  = [0 0 1];
writeopts.WM  = [0 0 1];
writeopts.CSF = [0 0 1];
writeopts.cleanup = [0];
sn=load(matname);
spm_preproc_write(sn,writeopts);


% Apply normalization doing spatial interpolation
for f=1:length(ToTrans)
    spm_write_sn(ToTrans{f},matname,defs.write);
end

% Apply transformation to the specific atlas DK and Dx
% whithout linear interpolation
defs.write.interp = 0; 
spm_write_sn(fileAtlasDK,matname,defs.write);
spm_write_sn(fileAtlasDx,matname,defs.write);


% Now save graphical check
figure(spm_figure('GetWin')); clf
myvols=spm_vol(char(fullfile(pth,['wm' nam ext]),...% normalised T1
    temp_imgs, ... % template T1
    fullfile(pth,['wCT' ext]), ...%normalized CT
    fullfile(pth,['waparc+aseg' ext]))); %normalized atlas

    % regexprep(gmname,'c1m','wc1m'))); % normalised GM

spm_check_registration(myvols)

ann(1)=annotation('textbox',[.1 .891 .3 .025],'HorizontalAlignment','center','Color','r','String','Normalised T1');
ann(2)=annotation('textbox',[.6 .891 .3 .025],'HorizontalAlignment','center','Color','r','String','T1 template');
ann(3)=annotation('textbox',[.1 .413 .3 .025],'HorizontalAlignment','center','Color','r','String','normalized CT');
ann(4)=annotation('textbox',[.6 .413 .3 .025],'HorizontalAlignment','center','Color','r','String','normalized atlas DK');


%% 11. Normalize pial surfaces (for visualization purposes only)
% using Fieldtrip

addpath('/data/iso2mesh-master')
addpath('/data/fieldtrip-20180201')
ft_defaults
 
% load surf files (.pial) 
names= {'lh.pial', 'rh.pial'};
for i=1:2
    fname=names(i);
    
    [vertex_coords, faces] = read_surf(fname);
    
    % laod transformation file
    load('mT1_seg_sn.mat')
    M=[];
    M.Affine=Affine;
    M.Tr=Tr;
    M.VF=VF;
    M.VG=VG;
    M.flags=flags;
    
    % apply transformation using a modified version of individual2sn
    % Bounding box modified to fit a bigger set of coordinates 
    [warped_coords] = ft_warp_apply(M, vertex_coords, 'individual2sn');
    
       
    % save a surface mesh to FreeSurfer ASC mesh format
    saveasc(warped_coords,faces,['w_' fname])
    
end



