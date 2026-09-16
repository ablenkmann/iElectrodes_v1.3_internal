function handles=defaultGuiVariables(handles)


%MNI brain
load MNImesh.mat;
handles.work.f_MNI=f_MNI;
handles.work.v_MNI=v_MNI;

%load MNI convex hull
load MNI_hull_LR.mat;
handles.work.f_MNI_SCE=f_hull;
handles.work.v_MNI_SCE=v_hull;


% HO atlas
load ('HOatlas_cort-subCort_lateralized.mat');
handles.work.MNIlabels=labels;
handles.work.MNIprob = prob;
handles.work.MNI_S_matrix=S;

colormap gray
handles.ui.layout=0; %default layaut

handles.ui.buttonDown=0;

% Plot update options. 
% If update = 0, no changes to current plot

handles.ui.updatePlots.views2D=[1 1 1]; % Force update all slices
handles.ui.updatePlots.resetTAC=1;      % reset 2D views axes
handles.ui.updatePlots.GS=1;
handles.ui.updatePlots.electrodes=1;
handles.ui.updatePlots.labels=1;
handles.ui.updatePlots.elecLines=1;

handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;

handles.ui.updatePlots.surfaces=1;

handles.ui.updatePlots.cla=1;

% plot 3D handles
handles.ui.plot3Dhandles.GS=[];
handles.ui.plot3Dhandles.electrodes=[];
handles.ui.plot3Dhandles.labels=[];
handles.ui.plot3Dhandles.elecLines=[];
handles.ui.plot3Dhandles.targets=[];
handles.ui.plot3Dhandles.targetLines=[];
handles.ui.plot3Dhandles.surfaces=[];
handles.ui.plot3Dhandles.hcam=[];

handles.ui.viewPoint=[-135,25];


handles.work.PathName=pwd;

handles.ui.color=1;

% we assume starting in MNI
handles.project.currentSpace='MNI'; % options are 'Native' 'MNI' 
set(handles.MNILabelstogglebutton,'State','On'); % this will call to labels2NativeSpace and updateElectrodes3D

% cursor
handles.ui.cursor=[0 0 0];

% which electrode array and contact the user is working on. This lives in
% work rather than in the text controls that display it; see the selection
% accessors at the end of electrodes_gui.m. Assigned directly because,
% unlike the rest of work, it never arrives from a .iel file.
handles.work.selection.array   = 0;
handles.work.selection.contact = 0;
handles.work.selection.planningArray  = 0;
handles.work.selection.planningTarget = 0;

handles.ui.rotate3d=rotate3d(handles.figure1);
setAllowAxesRotate(handles.ui.rotate3d,handles.axesX,false); 
setAllowAxesRotate(handles.ui.rotate3d,handles.axesY,false); 
setAllowAxesRotate(handles.ui.rotate3d,handles.axesZ,false); 
%handles.ui.rotate3d.ActionPreCallback=@Rotate3dActionPreCallback; %how to
%send handles structure as a parameter in this function??

handles.ui.hlink = linkprop([handles.axes1,handles.axes2],{'CameraPosition','CameraUpVector'});
% add select lock/unlock checkbox on axes1 or 2 

% crosshair handles 

axes(handles.axes2);
handles.ui.cross.x3D=line([0 0],[0 0],[0 0],'Color',handles.ui.colors.x);
handles.ui.cross.y3D=line([0 0],[0 0],[0 0],'Color',handles.ui.colors.y);
handles.ui.cross.z3D=line([0 0],[0 0],[0 0],'Color',handles.ui.colors.z);
view(handles.axes2,-135,25);

axes(handles.axesX);
handles.ui.cross.xh1=line([0 0],[0 0],'Color',handles.ui.colors.y);
handles.ui.cross.xh2=line([0 0],[0 0],'Color',handles.ui.colors.y);
handles.ui.cross.xv1=line([0 0],[0 0],'Color',handles.ui.colors.z);
handles.ui.cross.xv2=line([0 0],[0 0],'Color',handles.ui.colors.z);

axes(handles.axesY);
handles.ui.cross.yh1=line([0 0],[0 0],'Color',handles.ui.colors.x);
handles.ui.cross.yh2=line([0 0],[0 0],'Color',handles.ui.colors.x);
handles.ui.cross.yv1=line([0 0],[0 0],'Color',handles.ui.colors.z);
handles.ui.cross.yv2=line([0 0],[0 0],'Color',handles.ui.colors.z);

axes(handles.axesZ);
handles.ui.cross.zh1=line([0 0],[0 0],'Color',handles.ui.colors.x);
handles.ui.cross.zh2=line([0 0],[0 0],'Color',handles.ui.colors.x);
handles.ui.cross.zv1=line([0 0],[0 0],'Color',handles.ui.colors.y);
handles.ui.cross.zv2=line([0 0],[0 0],'Color',handles.ui.colors.y);

axes(handles.axes1);
handles.ui.cross.x3DThres=line([0 0],[0 0],[0 0],'Color',handles.ui.colors.x);
handles.ui.cross.y3DThres=line([0 0],[0 0],[0 0],'Color',handles.ui.colors.y);
handles.ui.cross.z3DThres=line([0 0],[0 0],[0 0],'Color',handles.ui.colors.z);


% scatter points
handles.ui.sct=[];

% max value
handles.work.maxValue=[];