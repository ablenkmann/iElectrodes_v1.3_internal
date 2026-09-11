% function mgz2nii(path, file)
% convertes mgz file to nii file using freesurfer 4.3.0
% path including '/' at the end
% input file including '.mgz' at the end
% output file in the same directory

% function mgz2nii(path, file, outPath)
% specify output directory

% RAS orientation


function mgz2nii(path, file, outPath)

if nargin<3
    outPath=path;
end

codeToRun=['!'];
codeToRun=[codeToRun 'export FREESURFER_HOME=/opt/freesurfer; ']; %  codeToRun=[codeToRun 'export FREESURFER_HOME=; '];/usr/local/freesurfer
codeToRun=[codeToRun 'source $FREESURFER_HOME/SetUpFreeSurfer.sh; '];

codeToRun=[codeToRun 'mri_convert --in_type mgz --out_type nii --out_orientation RAS '...
    path file ' ' outPath file(1:end-3) 'nii'];

eval(codeToRun)

%eval (['!freesurfer_4.3.0; mri_convert --in_type mgz --out_type nii --out_orientation RAS '...
%    path file ' ' outPath file(1:end-3) 'nii'])
%end
