function iel=checkProjectStructure(s,iel)


%  iel=checkProjectStructure()
%  Makes a new and empty iel structure
%
%  iel=checkProjectStructure(s)
%  checks the content of s and complete the missing fields
%
%  iel=checkProjectStructure(s,iel)
%  checks the content of s and complete the missing fields.
%  Overwrites the content in iel
%
%  Used to define what to save and what to load from .iel files
% 
% A Blenkmann 2017

disp('Project estructure is beeing checked...')
if nargin <1
    s=[];
end

if nargin < 2
    iel=[];
end

%%

if  ~isfield(s,'FileName')
    iel.FileName=[];
else
    iel.FileName=s.FileName;
end
if  ~isfield(s,'PathName')
    iel.PathName=[];
else
    iel.PathName=s.PathName;
end

%% compatibility between nifti tools and spm goes here
% T1
if  ~isfield(s,'T1')
    iel.T1=[];
    iel.S2=[];    
else
    if isfield(s.T1,'fileprefix')    % nifti tools
        iel.T1=niftiTools2spm(s.T1);
        iel.S2=iel.T1.vol.mat(1:3,:);
    else                             % spm
        iel.T1=s.T1;
        iel.S2=s.S2;
    end
end


%TAC
if  ~isfield(s,'TAC')
    iel.TAC=[];
    iel.maxValue=[];    
elseif isempty(s.TAC)
        iel.TAC=[];
        iel.maxValue=[];       
else
    if isfield(s.TAC,'fileprefix')    % nifti tools
%         in_bbox=world_bb(iel.T1.vol);
%         vprm=spm_imatrix(iel.T1.vol.mat);
%         in_voxdim=vprm(7:9);
%         iel.TAC=niftiTools2spm(s.TAC,4,in_voxdim,in_bbox); %reslice information
         iel.TAC=niftiTools2spm(s.TAC);
    else
        iel.TAC=s.TAC;
    end
    iel.maxValue=double(max(iel.TAC.img(:)));
    iel.minValue=double(min(iel.TAC.img(:)));
end

% mask
if  ~isfield(s,'mask')
    iel.mask=[];
else
    if ~isstruct(s.mask)   % not new SPM type (old mat structure)
%         temp=s.T1;         % take as a base structure. Assuming same dimensions
%         temp.img=s.mask;   % replace img
%         temp.fileprefix='mask';
% 
%         in_bbox=world_bb(iel.T1.vol);
%         vprm=spm_imatrix(iel.T1.vol.mat);
%         in_voxdim=vprm(7:9);
% 
%         iel.mask=niftiTools2spm(temp,1,in_voxdim,in_bbox); %linear interp

        iel.mask=iel.T1;  % take as a base structure. Assuming same dimensions
        iel.mask.img=s.mask; % replace img
        iel.fname='mask.nii';
    else
        iel.mask=s.mask;
    end
end


% wmparc & wmparcS
if  ~isfield(s,'wmparc')
    iel.wmparc=[];
    iel.wmparcS=[];    
    iel.wmparcColors=[];
elseif isempty(s.wmparc)
    iel.wmparcColors=[];
   
else
     
    if isfield(s.wmparc,'fileprefix')    % nifti tools
%         in_bbox=world_bb(iel.T1.vol);
%         vprm=spm_imatrix(iel.T1.vol.mat);
%         in_voxdim=vprm(7:9);
%         iel.wmparc=niftiTools2spm(s.wmparc,0,in_voxdim,in_bbox); %no interpolation

        iel.wmparc=niftiTools2spm(s.wmparc); 
        iel.wmparcS=iel.wmparc.vol.mat(1:3,:);
        
    else
        iel.wmparc=s.wmparc;
        iel.wmparcS=s.wmparcS;
    end

    if isfield(s,'wmparcColors') 
        iel.wmparcColors=s.wmparcColors;
    else
        % Same mapping the Load parcellation button uses; see
        % src/labeling/parcellationColours.m
        iel.wmparcColors=parcellationColours(s.wmparc.img);
    end
end

%% clusters and brush related
if  ~isfield(s,'GS')
    iel.GS=[];
    iel.oldGS=[];
else
    iel.GS=s.GS;
    iel.oldGS=s.oldGS;
end

% Anchors for the GridFit algorithm - docs/OPEN_QUESTIONS.md item 40. Every
% file written before this field existed has neither of the two, so both
% default to empty and an old project opens exactly as it did. The two are
% checked separately rather than together as GS and oldGS are above: that
% pair assumes a file with GS always has oldGS, and a file is not something
% this can promise.
if  ~isfield(s,'anchors')
    iel.anchors=[];
else
    iel.anchors=s.anchors;
end
if  ~isfield(s,'oldanchors')
    iel.oldanchors=[];
else
    iel.oldanchors=s.oldanchors;
end

if isfield(s, 'brushCrd') && ~isempty(s.brushCrd)
    iel.brushCrd=s.brushCrd;
else
    iel.brushCrd=[];
end
if isfield(s, 'brushWeight') && ~isempty(s.brushWeight)
    iel.brushWeight=s.brushWeight;
else
    iel.brushWeight=[];
end

if isfield(s, 'clusters') && ~isempty(s.clusters)
    iel.clusters=s.clusters;
else
    iel.clusters=[];
end

if isfield(s, 'oldbrushCrd') && ~isempty(s.oldbrushCrd)
    iel.oldbrushCrd=s.oldbrushCrd;
else
    iel.oldbrushCrd=[];
end

if isfield(s, 'oldbrushWeight') && ~isempty(s.oldbrushWeight)
    iel.oldbrushWeight=s.oldbrushWeight;
else
    iel.oldbrushWeight=[];
end

if isfield(s, 'oldclusters') && ~isempty(s.oldclusters)
    iel.oldclusters=s.oldclusters;
else
    iel.oldclusters=[];
end


%% FS surfaces

% pial surfaces
if isfield(s, 'verticesR')
    iel.verticesR=s.verticesR;
    iel.facesR=s.facesR;
    iel.verticesL=s.verticesL;
    iel.facesL=s.facesL;
else
    iel.verticesR=[];
    iel.verticesL=[];
    iel.facesR=[];
    iel.facesL=[];
end
    
% SCE surfaces
if isfield(s,'vertices_SCE_R')
    iel.vertices_SCE_L = s.vertices_SCE_L;
    iel.vertices_SCE_R = s.vertices_SCE_R ;
    iel.faces_SCE_L = s.faces_SCE_L;
    iel.faces_SCE_R = s.faces_SCE_R;
else
    iel.vertices_SCE_L = [];
    iel.vertices_SCE_R  = [];
    iel.faces_SCE_L  = [];
    iel.faces_SCE_R  = [];
end

% annotation files
if isfield(s,'AnnotLabel_R')
    iel.AnnotLabel_R=s.AnnotLabel_R; %label for each node
    iel.AnnotLabel_L=s.AnnotLabel_L; %label for each node
    iel.AnnotColortable_R=s.AnnotColortable_R; %colortable info
    iel.AnnotColortable_L=s.AnnotColortable_L; %colortable info
    iel.AnnotColor_R=s.AnnotColor_R; %actual color used for each node
    iel.AnnotColor_L=s.AnnotColor_L; %actual color used for each node
else
    iel.AnnotLabel_R=[]; %label for each node
    iel.AnnotLabel_L=[]; %label for each node
    iel.AnnotColortable_R=[]; %colortable info
    iel.AnnotColortable_L=[]; %colortable info
    iel.AnnotColor_R=ones(length(iel.verticesR),3)*.5; %actual color used for each node = grey
    iel.AnnotColor_L=ones(length(iel.verticesL),3)*.5; %actual color used for each node = grey
end    

%% Electrodes
if isfield(s,'electrodes') && ~isempty(s.electrodes)
    iel.electrodes=checkElectrodeStructure( s.electrodes);
else
    iel.electrodes=[];
end

if isfield(s,'elecListLabels')
    iel.elecListLabels= s.elecListLabels;
else
    iel.elecListLabels={};
end

%% targets
if isfield(s,'targets') && ~isempty(s.targets)
    iel.targets= checkElectrodeStructure( s.targets); % Oct 2020
%   Run in case of incompatible structure names
%         for l=1:length(iel.targets)
%             iel.targets(l).FirstSecond=iel.targets(l).FirtsSecond;
%         end
%         iel.targets=rmfield(iel.targets,'FirtsSecond');
else
    iel.targets={}; % new version: 27 August 2018
end

%% processing history
% Added in iElectrodes 2: the cfg of every ielec call that changed the
% project, in the order they were made. A file written by 1.020 has none, and
% opens with an empty one - which is also what a project that has only been
% opened and saved again has. See docs/API_LAYER.md, "Recording each step".
% The file stores the history as one JSON string; the project holds it as the
% cell of steps docs/API_LAYER.md specifies. DECODEHISTORY does that, and
% also takes a cell as it is, and gives an empty history for anything it
% cannot read - rather than carrying a value through to break
% history{end+1} several frames later.
if isfield(s,'history')
    iel.history=decodeHistory(s.history);
else
    iel.history={};
end

%% current space
if isfield(s,'currentSpace')
    iel.currentSpace=s.currentSpace;
else
    if isfield(s,'facesR') &&  ~isempty(s.facesR) 
        iel.currentSpace='Native';
    else
        iel.currentSpace='MNI';
    end
end

disp('Checking done.')
