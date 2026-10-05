%     iElectrodes
%     Copyright (C) 2014, 2015, 2016, 2017, 2018  Alejandro Omar Blenkmann
%     ablenkmann@gmail.com
%     https://sourceforge.net/projects/ielectrodes/  
%     
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%     iElectrodes toolbox includes parts of code developed by Jimmy Shen
%     (jimmy@rotman-baycrest.on.ca) (NIfTI toolbox), Qianqian Fang
%     (iso2mesh), Panagiotis Moulos (addremovelist), Levente Hunyadi
%     (spherefit),Divahar Jayaraman (Cylinder), Dirk-Jan Kroon 
%     (refinepatch), Jeng-Ren Duann (readedf), Wellcome Trust Centre for 
%     Neuroimaging (SPM12).
%     Related codes from these authors are included for user convenience. 
%     The copyrights of these codes are reserved by the original parties.
%
%     iElectrodes toolbox is FOR RESEARCH PURPOSES ONLY. This software is
%     for research purposes only and has NOT BEEN APPROVED FOR CLINICAL 
%     USE.
%     If you publish results whose generation used this software, you must
%     provide attribution to the author of the software by referencing the
%     appropriate papers, as outlined on the iElectrodes website
%     (https://sourceforge.net/projects/ielectrodes/wiki).
%
%     IN NO EVENT SHALL THE AUTHOR, OR THE DISTRIBUTORS BE LIABLE TO ANY
%     PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
%     DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF THE USE OF THIS
%     SOFTWARE, ITS DOCUMENTATION, OR ANY DERIVATIVES THEREOF, EVEN IF THE
%     AUTHORS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
%     THE AUTHOR, AND THE DISTRIBUTORS SPECIFICALLY DISCLAIM ANY
%     WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
%     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
%     NON-INFRINGEMENT. THIS TOOLBOX IS PROVIDED ON AN “AS IS�? BASIS, AND
%     THE AUTHOR AND DISTRIBUTORS HAVE NO OBLIGATION TO PROVIDE
%     MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
%


%% Initialize

function varargout = electrodes_gui(varargin)
% ELECTRODES_GUI MATLAB code for electrodes_gui.fig
%      ELECTRODES_GUI, by itself, creates a new ELECTRODES_GUI or raises the existing
%      singleton*.
%
%      H = ELECTRODES_GUI returns the handle to a new ELECTRODES_GUI or the handle to
%      the existing singleton*.
%
%      ELECTRODES_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ELECTRODES_GUI.M with the given input arguments.
%
%      ELECTRODES_GUI('Property','Value',...) creates a new ELECTRODES_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before electrodes_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to electrodes_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help electrodes_gui

% Last Modified by GUIDE v2.5 30-Aug-2018 10:32:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @electrodes_gui_OpeningFcn, ...
    'gui_OutputFcn',  @electrodes_gui_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Outputs from this function are returned to the command line.
function varargout = electrodes_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes just before electrodes_gui is made visible.
function electrodes_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to electrodes_gui (see VARARGIN)

% Choose default command line output for electrodes_gui
handles.output = hObject;

[handles.work.pathstr,~,~] = fileparts(which('electrodes_gui.m'));
global debugging;
debugging=0;

% ---------------------------------------------------------------------
% iElectrodes 2 folder layout (see ARCHITECTURE.md)
%   src/         BACKEND  - GUI-free scientific code (headless-callable)
%   app/         FRONTEND - dialogs, rendering helpers, GUI configuration
%   assets/      atlases, look-up tables, MNI meshes, icons
%   third_party/ bundled external toolboxes (SPM, iso2mesh, NIfTI tools)
%   priv/        migration safety net - empty in a completed migration
%
% NOTE: the assets folder must NOT be called "resources". MATLAB reserves
% that name for toolbox metadata and refuses to add it to the path, which
% silently breaks every bare-name load such as "load MNImesh.mat".
%
% fullfile() is used so the same code works on Windows, macOS and Linux,
% and each folder is checked with isfolder() so a missing one is skipped
% instead of raising an error.
% ---------------------------------------------------------------------
iElectrodesFolders = {'src','app','assets','third_party','priv'};
for iFolder = 1:numel(iElectrodesFolders)
    thisFolder = fullfile(handles.work.pathstr, iElectrodesFolders{iFolder});
    if isfolder(thisFolder)
        addpath(genpath(thisFolder));
    end
end
clear iElectrodesFolders iFolder thisFolder

spm('defaults','PET');

disp('Welcome to iElectrodes.');
disp('iElectrodes toolbox is FOR RESEARCH PURPOSES ONLY. This software is');
disp('for research purposes only and has NOT BEEN APPROVED FOR CLINICAL USE.'); 
disp('');
disp('Help about using iElectrodes can be found online in ');
disp('https://sourceforge.net/p/ielectrodes/wiki/Home/')


% check for updates - current version is defined inside
handles=checkUpdates(handles);

% The three groups of state a session starts with: the empty project, the
% work that goes with it, and the colour caches the frontend keeps. What
% belongs where, and the order it has to be built in, is the layer's.
% handles.work is kept, so the path this function set above survives.
cfg = [];
[handles.project, handles.work, caches] = ...
    ielec.startSession(cfg, [], handles.work);
handles = takeColourCaches(handles, caches);

% and the options that only change what is shown, which are this window's
handles.ui.options = defaultDisplayOptions([]);

colors=[];
handles.ui.colors=defaultColors(colors);

% reset gui variables
handles=defaultGuiVariables(handles);

% layout 
if ~handles.ui.options.showLocalizeTools
    set(handles.PanelClustering,'Visible','off');
    set(handles.PanelLabel,'Visible','off');
end

if ~handles.ui.options.showPlanTools    
    set(handles.PanelPlanningDepths,'Visible','off');
end

% Update handles structure
guidata(hObject, handles);

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Construct a questdlg with three options
choice = questdlg('Do you want to save your project?', ...
    'Exit iElectrodes', ...
    'Yes','No','Cancel','Cancel');
% Handle response
switch choice
    case 'Yes'
        saved=Savepushtool_ClickedCallback(hObject, eventdata, handles);
        % Hint: delete(hObject) closes the figure
        if saved
            delete(hObject);
        end
    case 'No'
        % Hint: delete(hObject) closes the figure
        delete(hObject);
        
    case 'Cancel'
        return;
end

disp(' ');
disp('-------//--------');
disp(' ');
disp('Thank you for using iElectrodes.');
disp('Please support our work by citing our papers:');
disp(' ');
disp('- Blenkmann, Phillips, Princich, Rowe, Bekinschtein, Muravchik, and Kochen. 2017.')
disp('    iElectrodes: A Comprehensive Open-Source Toolbox for Depth and Subdural Grid ')
disp('    Electrode Localization.')
disp('    Frontiers Neuroinformatics, https://doi.org/10.3389/fninf.2017.00014')
disp(' ');
disp('- Blenkmann, Leske, Llorens,  Lin, Chang, Brunner, Schalk, Ivanovic, Larsson, Knight,')
disp('    Endestad, and Solbakk. 2024.')
disp('    Anatomical registration of intracranial electrodes. Robust model-based localization')
disp('    and deformable smooth brain-shift compensation methods')
disp('    Journal of Neuroscience Methods. https://doi.org/10.1016/j.jneumeth.2024.110056')

       

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%                 MOUSE                       %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%              left click                     %%%%%%%%%%%%%%%
% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project.')
    return
end

G=gca;
DD=get(G, 'CurrentPoint');
d1=DD(1,1); d2=DD(1,2);

%axes limits
xLimits = get(G, 'xlim');
yLimits = get(G, 'ylim');

if (G == handles.axes1) || (G == handles.axes2 && verLessThan('matlab','9.5')) 
        %handles.ui.rotate3d.Enable='on';
        
        [pout]  = select3d(handles); % error in new matlab versions >2018b with surfaces
        
        if isempty(pout) %not a valid point
            %disp('not a valid point');
            return;
        end 
        
        D=AnatSpace2Mesh(pout',handles.project.S2);
        
        set(handles.sliderX,'Value',D(1));
        set(handles.sliderY,'Value',D(2));
        set(handles.sliderZ,'Value',D(3));

        handles=updateTAC(handles);
elseif d1>xLimits(1) && d1<xLimits(2) && d2>yLimits(1) && d2<yLimits(2)
    
    % X-view
    % z=d2
    % y=d1
    
    if G == handles.axesX
        set(handles.sliderY,'Value',d1);
        set(handles.sliderZ,'Value',d2);
        
        % Y-view
        %x=d1
        %z=d2;
    elseif G == handles.axesY
        set(handles.sliderX,'Value',d1);
        set(handles.sliderZ,'Value',d2);
        
        % Z-view
        %x=d1
        %y=d2
    elseif G == handles.axesZ
        set(handles.sliderX,'Value',d1);
        set(handles.sliderY,'Value',d2);
        
        
    end
    handles=updateTAC(handles);
end

% Update handles structure
guidata(hObject, handles);


%%%%%%%%%%%%%%%                scroll                       %%%%%%%%%%%%%%%
% --- Executes on scroll wheel click while the figure is in focus.
function figure1_WindowScrollWheelFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	VerticalScrollCount: signed integer indicating direction and number of clicks
%	VerticalScrollAmount: number of lines scrolled for each click
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project.')
    return
end
step=-eventdata.VerticalScrollCount;
dim=size(handles.project.T1.img);

F=get(handles.figure1, 'CurrentPoint'); %mouse position in figure

% panel psition (it is easiest than axes position)
xPos=get(handles.PanelX,'pos');
yPos=get(handles.PanelY,'pos');
zPos=get(handles.PanelZ,'pos');

% X-view
tf1 = xPos(1) <= F(1) && F(1) <= xPos(1) + xPos(3);
tf2 = xPos(2) <= F(2) && F(2) <= xPos(2) + xPos(4);

if tf1 && tf2
    x=get(handles.sliderX,'Value') + step;
    
    if x>0 && x < dim(1)
        set(handles.sliderX,'Value',x);
    end
end

% Y-view
tf1 = yPos(1) <= F(1) && F(1) <= yPos(1) + yPos(3);
tf2 = yPos(2) <= F(2) && F(2) <= yPos(2) + yPos(4);

if tf1 && tf2
    y=get(handles.sliderY,'Value') + step;
    
    if y>0 && y < dim(2)
        set(handles.sliderY,'Value',y);
    end
end

% Z-view
tf1 = zPos(1) <= F(1) && F(1) <= zPos(1) + zPos(3);
tf2 = zPos(2) <= F(2) && F(2) <= zPos(2) + zPos(4);

if tf1 && tf2
    z=get(handles.sliderZ,'Value') + step;
    
    if z>0 && z < dim(3)
        set(handles.sliderZ,'Value',z);
    end
end

handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%            TOOLBAR                          %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%           New - MRI load             %%%%%%%%%%%%%%%%%%%%
function Newuipushtool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to Newuipushtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% load TAC

if ~isempty(handles.project.T1)
    % Construct a questdlg with three options
    choice = questdlg('Do you want to save your project?', ...
        '', ...
        'Yes','No','Cancel','Cancel');
    % Handle response
    switch choice
        case 'Yes'
            saved=Savepushtool_ClickedCallback(hObject, eventdata, handles);
            if saved   
                %nothing to do
            else
                %unable to save
                return;
            end
        case 'No'
            % nothing to do
        case 'Cancel'
            return;
    end
end

% load MRI
[T1file,PathName]=uigetfile('*.nii', 'Load MRI',handles.work.PathName);

if T1file ~=0
        
%    [T1,S2,T1file]=loading_images(PathName,T1file);
    handles=defaultGuiVariables(handles);

    % read the MRI and start an empty project around it
    cfg = [];
    cfg.mri = [PathName, T1file];
    [handles.project, handles.work] = ielec.newProject(cfg, [], handles.work);
    [~, ~, caches] = ielec.colourCaches([], handles.project, handles.work);
    handles = takeColourCaches(handles, caches);
    disp (['Loaded MRI from ' PathName, T1file])
 
    %fiugre name
    set(handles.figure1,'name',['iElectrodes - ' PathName T1file]);
    
    handles.work.PathName=PathName;
    
    handles=updateMix_TAC_MR(handles);    
     
    [xM,yM,zM]=size(handles.project.T1.img);
    set(handles.sliderX,'Min',1,'Max',xM,'SliderStep',[ 1/(xM-1) 10/(xM-1)],'Value',xM/2);
    set(handles.sliderY,'Min',1,'Max',yM,'SliderStep',[ 1/(yM-1) 10/(yM-1)],'Value',yM/2);
    set(handles.sliderZ,'Min',1,'Max',zM,'SliderStep',[ 1/(zM-1) 10/(zM-1)],'Value',zM/2);
    set(handles.TargetInXedit,'string','0');
    set(handles.TargetInYedit,'string','0');
    set(handles.TargetInZedit,'string','0');
    set(handles.TargetOutXedit,'string','0');
    set(handles.TargetOutYedit,'string','0');
    set(handles.TargetOutZedit,'string','0');
    set(handles.AzimuthTargetedit,'string','0');
    set(handles.ElevacionTargetedit,'string','0');
%    set(handles.TargetNameedit,'string','name');
    set(handles.editPlanningArrayName,'string','');
    set(handles.editPlanningElecLabel,'string','');
    handles = setSelectedPlanningArray(handles, 0);
    handles = setSelectedPlanningTarget(handles, 0);
%    set(handles.TargetArraytext,'string','0');
    set(handles.nClusText,'string', '0');

    handles.ui.cursor=mesh2AnatSpace([xM/2 yM/2 zM/2], handles.project.S2);
      
    guidata(hObject, handles);
    
    view(handles.axes2,-135,25);
    handles=updateElectrodes3D(handles);
    handles=updateTAC(handles);
    handles=updatePlot(handles);
    
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%     CT and brain mask load          %%%%%%%%%%%%%%%%%%%%
function LoadCTtool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to LoadCTtool2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% hObject    handle to Newuipushtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% load TAC

% MRI should be loaded first
if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project')
    return
end

[TACfile,PathName]=uigetfile('*.nii', 'Load CT',handles.work.PathName);

if TACfile~=0
    
    % The CT must already be coregistered to the MRI. iElectrodes does not
    % coregister it. The code that would have done so sat under a switch on
    % a variable assigned the constant 'No', so it could never run - and it
    % called two functions that are not in the toolbox and used two
    % variables that are never defined, so it could not have run even then.
    % Removed with Alejandro's agreement; see docs/OPEN_QUESTIONS.md item 9.

    %load mask file. The mask decides which voxels the thresholding may
    %select, so the CT is only useful with it: both are read together, and
    %nothing is loaded if this dialog is cancelled - see OPEN_QUESTIONS 26.
    [maskfile,maskPath]=uigetfile('*.nii', 'Load mask file',PathName);
    
    if maskfile~=0
        cfg = [];
        cfg.ct   = [PathName, TACfile];
        cfg.mask = [maskPath, maskfile];
        [handles.project, handles.work] = ielec.loadCT(cfg, handles.project, handles.work);
        disp (['Loaded CT from ' PathName, TACfile])
        disp (['Loaded Mask from ' maskPath, maskfile])
        PathName = maskPath;
        
        % arbitrary thresholds to start
        set(handles.sliderThrMin,'Value',0.9);
        set(handles.sliderThrMax,'Value',1);
               
        set(handles.text1,'String', get(handles.sliderThrMax,'Value')*(handles.work.maxValue-handles.work.minValue)+handles.work.minValue);
        set(handles.text2,'String', get(handles.sliderThrMin,'Value')*(handles.work.maxValue-handles.work.minValue)+handles.work.minValue);
        
        handles.work.PathName=PathName;
        
        handles=updateMix_TAC_MR(handles);

        handles.ui.updatePlots.views2D=[1 1 1];     
        handles=updateElectrodes3D(handles);
        handles=updateTAC(handles);
        handles=updatePlot(handles);
    end
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%             Save Project             %%%%%%%%%%%%%%%%%%%%
function saved=Savepushtool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to Savepushtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
saved=0;
if isempty(handles.project.T1)
    warning ('MRI is empty. Load images first. Click New button or open existing project');
    return;
else
    if isempty( handles.work.FileName)
        [FileName,PathName] = uiputfile('*.iel','Save filename',handles.work.PathName);
    else
        [FileName,PathName] = uiputfile('*.iel','Save filename',[handles.work.PathName handles.work.FileName]);
    end
    if FileName ~=0
        cfg = [];
        cfg.file = [PathName, FileName];
        [handles.project, handles.work] = ...
            ielec.saveProject(cfg, handles.project, handles.work, colourCachesOf(handles));
        disp (['Saved project in ' handles.work.PathName, handles.work.FileName])
        
        %fiugre name
        set(handles.figure1,'name', ['iElectrodes - ' handles.work.PathName, handles.work.FileName]);
        
        saved=1;
    else
        return;
    end
end
guidata(hObject, handles);
    
%%%%%%%%%%%%%%%%%             Open Project             %%%%%%%%%%%%%%%%%%%%
function Openpushtool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to Openpushtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


if ~isempty(handles.project.T1)
    % Construct a questdlg with three options
    choice = questdlg('Do you want to save your project?', ...
        '', ...
        'Yes','No','Cancel','Cancel');
    % Handle response
    switch choice
        case 'Yes'
            saved=Savepushtool_ClickedCallback(hObject, eventdata, handles);
            if saved   
                %nothing to do
            else
                %unable to save
                return;
            end
        case 'No'
            % nothing to do
        case 'Cancel'
            return;
    end
end

[FileName,PathName]=uigetfile('*.iel', 'Load iElectrodes file', handles.work.PathName);

if FileName ~=0   
    cfg = [];
    cfg.file = [PathName, FileName];
    [project, work, caches] = ielec.openProject(cfg, [], handles.work);
    disp (['Loaded project from ' PathName, FileName])
       
    % load defaults, including plot updates
    handles=defaultGuiVariables(handles);
    handles.project = project;
    handles.work    = work;
    handles = takeColourCaches(handles, caches);
    
    if ~isempty(handles.project.electrodes)
        handles = setSelectedArray(handles, 1);
        handles = setSelectedContact(handles, 1);
        set(handles.editArrayName,'String',handles.project.electrodes{1}.Name);
        set(handles.editElecLabels,'string',handles.project.electrodes{1}.ch_label{1});
        
    else
        
        set(handles.editArrayName,'string','');
        set(handles.editElecLabels,'string','');
        handles = setSelectedArray(handles, 0);
        handles = setSelectedContact(handles, 0);
    end
    
    if ~isempty(handles.project.targets)        
        
        handles = setSelectedPlanningArray(handles, 1);
        handles = setSelectedPlanningTarget(handles, 1);
        set(handles.editPlanningArrayName,'String',handles.project.targets{1}.Name);
        set(handles.editPlanningElecLabel,'string',handles.project.targets{1}.ch_label{1});
        
        % THIS NEEDS to be FIXED
%        UpdateTargetEditBox(hObject, eventdata, handles);   %this modifies handles
%         handles = guidata(hObject); % returns previous handles
    else
        
        set(handles.TargetInXedit,'string','0');
        set(handles.TargetInYedit,'string','0');
        set(handles.TargetInZedit,'string','0');
        set(handles.TargetOutXedit,'string','0');
        set(handles.TargetOutYedit,'string','0');
        set(handles.TargetOutZedit,'string','0');
        set(handles.AzimuthTargetedit,'string','0');
        set(handles.ElevacionTargetedit,'string','0');
        set(handles.editPlanningArrayName,'string','name');
        handles = setSelectedPlanningArray(handles, 0);
    end
    
    set(handles.text1,'String', get(handles.sliderThrMax,'Value')*(handles.work.maxValue-handles.work.minValue)+handles.work.minValue);
    set(handles.text2,'String', get(handles.sliderThrMin,'Value')*(handles.work.maxValue-handles.work.minValue)+handles.work.minValue);
    set(handles.nClusText,'string',num2str(size(handles.work.GS,1)));

    
    % by default not show projections (they may not exist!)
    set(handles.projectSCEcheckbox,'Value',0);

    handles=updateMix_TAC_MR(handles);
    [xM,yM,zM]=size(handles.project.T1.img);
    set(handles.sliderX,'Min',1,'Max',xM,'SliderStep',[ 1/(xM-1) 10/(xM-1)],'Value',xM/2);
    set(handles.sliderY,'Min',1,'Max',yM,'SliderStep',[ 1/(yM-1) 10/(yM-1)],'Value',yM/2);
    set(handles.sliderZ,'Min',1,'Max',zM,'SliderStep',[ 1/(zM-1) 10/(zM-1)],'Value',zM/2);
    handles.ui.cursor=mesh2AnatSpace([xM/2 yM/2 zM/2], handles.project.S2);

  
    if ~isempty(handles.project.wmparc)
        set(handles.MNILabelstogglebutton,'state','off');
    else
        set(handles.MNILabelstogglebutton,'state','on');    
    end

    view(handles.axes2,-135,25);
    handles=updateElectrodes3D(handles);
    handles=updateTAC(handles);
    handles=updatePlot(handles);

    %figure name
    set(handles.figure1,'name',['iElectrodes - ' handles.work.PathName, handles.work.FileName]);
end

% Update handles structure
guidata(hObject, handles);

% --------------------------------------------------------------------

%%%%%%%%%%%      Export electrode structure or coordinates    %%%%%%%%%%%%%
function SaveElectrodespushtool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to SaveElectrodespushtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty (handles.project.electrodes)
    warning('Electrodes is empty');
    return;
end

[selection,valid] = listdlg('PromptString','Select output format:',...
    'SelectionMode','single',...
    'ListString',{'iElectrodes  - electrodes structure (.mat)',...          % option 1
    'EEGLAB - electrodes (.txt)', 'EEGLAB - projections (.txt)',...         % options 2 & 3
    'FIELDTRIP - electrodes (.mat)', 'FIELDTRIP - projections(.mat)',...    % options 4 & 5
    'BIDS - electrodes (.tsv)', 'BIDS - projections (.tsv)'},...            % options 6 & 7
    'ListSize', [300 150]);


% write the file. Each case picks a file and says what it did; the layer
% writes it - which coordinates a format wants is its business, not ours.
if valid

    % which coordinates the chosen option asks for
    if any(selection == [3 5 7])
        coordinates = 'projection';
    else
        coordinates = 'contacts';
    end

    switch selection
        case 1 % iElectrodes structure
            [FileName,PathName] = uiputfile('*.mat','Save electrodes structure', handles.work.PathName);
            if FileName~=0
                handles.work.PathName=PathName;
                handles = exportFile(handles, 'structure', coordinates, ...
                    [handles.work.PathName, FileName]);
                disp (['Saved electrode structure in ' handles.work.PathName, FileName])
            end

        case {2, 3} % EEGLAB - contacts (2) or projections (3)
            if selection==2
                what = 'electrode';
            else
                what = 'SCE-projected';
            end
            [FileName,PathName] = uiputfile('*.txt',['Save ' what ' coordinates in EEGLAB format'], handles.work.PathName);
            if FileName~=0
                handles.work.PathName=PathName;
                handles = exportFile(handles, 'eeglab', coordinates, [PathName FileName]);
                disp([' ' what ' coordinates saved in ' PathName FileName ] )
                disp (' load to EEGLAB with the command:')
                disp (' EEG.chanlocs=readlocs( [ path file] , ''filetype'', ''custom'',''format'',{''labels'',''-Y'',''X'',''Z''}) ')
            end

        case {4, 5} % FIELDTRIP - contacts (4) or projections (5)
            if selection==4
                what = 'electrode';
            else
                what = 'SCE-projected';
            end
            [FileName,PathName] = uiputfile('*.mat',['Save ' what ' coordinates in FIELDTRIP structure'], handles.work.PathName);
            if FileName~=0
                handles.work.PathName=PathName;
                handles = exportFile(handles, 'fieldtrip', coordinates, ...
                    [handles.work.PathName, FileName]);
                disp (['Saved ' what ' coordinates in FIELTRIP structure in ' handles.work.PathName, FileName])
            end

        case 6 % elec-BIDS
            [FileName,PathName] = uiputfile('*.tsv','Save electrode coordinates in BIDS format', handles.work.PathName);
            if FileName~=0
                handles.work.PathName=PathName;
                handles = exportFile(handles, 'bids', coordinates, ...
                    [handles.work.PathName, FileName]);
                disp (['Saved electrodes using BIDS format  in ' handles.work.PathName, FileName]);
            end

            [FileName,PathName] = uiputfile('*.json','Save coordinates system in json BIDS format', handles.work.PathName);
            if FileName~=0
                handles.work.PathName=PathName;
                handles = exportFile(handles, 'bidsCoordinateSystem', coordinates, ...
                    [handles.work.PathName, FileName]);
                disp (['Saved coordinates system in json BIDS format  in ' handles.work.PathName, FileName]);
            end

        case 7 % proj-BIDS
            [FileName,PathName] = uiputfile('*.tsv','Save electrode SCE-projected coordinates in BIDS format', handles.work.PathName);
            if FileName~=0
                handles.work.PathName=PathName;
                handles = exportFile(handles, 'bids', coordinates, ...
                    [handles.work.PathName, FileName]);
                disp (['Saved electrode SCE-projected coordinates using BIDS format  in ' handles.work.PathName, FileName]);
            end

            [FileName,PathName] = uiputfile('*.json','Save coordinates system in json BIDS format', handles.work.PathName);
            if FileName~=0
                handles.work.PathName=PathName;
                handles = exportFile(handles, 'bidsCoordinateSystem', coordinates, ...
                    [handles.work.PathName, FileName]);
                disp (['Saved coordinates system in json BIDS format  in ' handles.work.PathName, FileName]);
            end

    end
end


% Update handles structure
guidata(hObject, handles);

function handles = exportFile(handles, format, coordinates, file)
% One export, through the layer. The dialogs above choose the format and the
% file; everything the format needs from the project is the layer's business.
cfg = [];
cfg.file        = file;
cfg.format      = format;
cfg.coordinates = coordinates;
[handles.project, handles.work] = ielec.export(cfg, handles.project, handles.work);

%%%%%%%%%%%            Load electrode structure               %%%%%%%%%%%%%
function LoadElectrodespushtool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to LoadElectrodespushtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% MRI should be loaded first
if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project')
    return
end


[selection,valid] = listdlg('PromptString','Select file format to import:',...
    'SelectionMode','single',...
    'ListString',{'iElectrodes - electrodes structure (.mat)',...
    'EEGLAB dataset- electrodes (.set)', 'FIELDTRIP - elec structure (.mat)'},...
    'ListSize', [300 150]);

% the file, then what the layer says is in it, then the questions only we
% can ask, and the import itself
if valid
    formats = {'structure', 'eeglab',  'fieldtrip'};
    filters = {'*.mat',     '*.set',   '*.mat'};
    titles  = {'Load electrodes structure', 'Load EEGLAB dataset', ...
               'Load FIELDTRIP elec structure'};

    [FileName,PathName] = uigetfile(filters{selection}, titles{selection}, handles.work.PathName);
    if FileName==0
        return;
    end
    handles.work.PathName=PathName;

    cfg = [];
    cfg.file   = [handles.work.PathName, FileName];
    cfg.format = formats{selection};

    try
        [~, ~, contents] = ielec.arrayFileContents(cfg, handles.project, handles.work);
    catch err
        warning(err.message);
        return;
    end

    if contents.needsChoices % EEGLAB or FIELDTRIP: a flat list of contacts
        % the file does not say what kind of array each one is; ask, and
        % hand the answers to the import
        A = numel(contents.arrays);
        button=questdlg([ [num2str(A) ' arrays were found: '] contents.arrays 'Continue?'],'','Yes','No','Yes');
        if strcmp(button,'No')
            return
        end
        for i=1:A
            [type,rows,columns]=elecImportDlg(contents.arrays{i}, contents.contacts(i));
            cfg.arrays(i).type    = type;
            cfg.arrays(i).rows    = rows;
            cfg.arrays(i).columns = columns;
        end
    end

    [handles.project, handles.work] = ielec.importArrays(cfg, handles.project, handles.work);
    
    handles = setSelectedArray(handles, 1);
    handles = setSelectedContact(handles, 1);
    set(handles.editArrayName,'String',handles.project.electrodes{1}.Name);
    set(handles.editElecLabels,'string',handles.project.electrodes{1}.ch_label{1});
    

    % anatomical labeling (electrodes and projections)
    if strcmp(handles.project.currentSpace,'MNI'); % options are 'Native' 'MNI'        %strcmp (get(handles.MNILabelstogglebutton,'state'),'on')
        handles=labels2MNIspace(handles);
    else
        handles=labels2NativeSpace(handles);
    end
       
    handles.ui.updatePlots.electrodes=1;
    handles.ui.updatePlots.labels=1;
    handles.ui.updatePlots.elecLines=1;
    handles=updateElectrodes3D(handles);
    handles=updateTAC(handles);
    handles=updatePlot(handles);
    
    % Update handles structure
    guidata(hObject, handles);
    disp (['Loaded electrodes structure from ' PathName, FileName])

end

%%%%%%%%%%%            Make electrode report                  %%%%%%%%%%%%%
function Reportuipushtool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to Reportuipushtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% MRI should be loaded first
if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project')
    return
end

optionsList={'Localized coordinates', 'SCE-projected coordinates'};
[selection,valid] = listdlg('PromptString','Select coordinates:',...
    'SelectionMode','single',...
    'ListString',optionsList,...
    'ListSize', [300 150]);


if valid & ~isempty(handles.project.electrodes)
      
    [FileName,PathName] = uiputfile('.txt','.txt ouput file',handles.work.PathName);
    if FileName~=0
        if selection == 2, coordinates = 'projection'; else, coordinates = 'contacts'; end
        handles = exportFile(handles, 'labels', coordinates, [PathName FileName]);
        disp (['Report saved in ' PathName, FileName])

    end
else
    warning ('Electrodes structure is empty');
end

% Update handles structure
guidata(hObject, handles);

% --------------------------------------------------------------------
%%%%%%%%%%%%%%%     FreeSurfer Labels structure (aparc+aseg / wmparc)    %%%%%%%%%%%%%%%
function LoadFSlabelsuipushtool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to LoadFSlabelsuipushtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Not changing handles.project.currentSpace since can be both 'MNI' or 'Native' space 

% MRI should be loaded first
if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project. Then load CT...')
    return
end

%load apar aseg / wmparc anatomical labels
[wmparcFile,PathName]=uigetfile('*.nii', 'Load parcellation file (aparc+aseg / aparc.a2009s / wmparc)',handles.work.PathName);

if ~isequal(wmparcFile,0)
    handles.work.PathName=PathName;

    cfg = [];
    cfg.file = [PathName wmparcFile];
    [handles.project, handles.work, handles.ui.wmparcColors] = ...
        ielec.loadAnatomy(cfg, handles.project, handles.work);

    
%    [handles.project.wmparc,handles.project.wmparcS,wmparcFile]=loading_images(handles.work.PathName,wmparcFile,2,handles.project.T1);
    disp (['Loaded FS labels from ' PathName, wmparcFile])
    
    
    % Update handles structure
    guidata(hObject, handles);
    set(handles.MNILabelstogglebutton,'state','off');
    
    % Update labels
    handles=labels2NativeSpace(handles);
    
    handles.ui.updatePlots.views2D=[1 1 1];
    handles=updateTAC(handles);
    guidata(hObject, handles); % update data again
end

% --------------------------------------------------------------------

%%%%%%%%%%%%%%%            MNI Labels On                  %%%%%%%%%%%%%%%%%
function MNILabelstogglebutton_OnCallback(hObject, eventdata, handles)
% hObject    handle to MNILabelstogglebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.project.currentSpace='MNI'; % options are 'Native' 'MNI' 
handles=labels2MNIspace(handles);
handles.ui.updatePlots.surfaces=1;

handles=updateElectrodes3D(handles);
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);


%%%%%%%%%%%%%%%            MNI Labels Off                   %%%%%%%%%%%%%%%
function MNILabelstogglebutton_OffCallback(hObject, eventdata, handles)
% hObject    handle to MNILabelstogglebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.project.currentSpace='Native'; % options are 'Native' 'MNI' 
handles=labels2NativeSpace(handles);
handles.ui.updatePlots.surfaces=1;

handles=updateElectrodes3D(handles);
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);

% --------------------------------------------------------------------
%%%%%%%%%%%%%%%           Labels to MNI space               %%%%%%%%%%%%%%%
function handles=labels2MNIspace(handles)
% Thin GUI wrapper around ielec.label: two lines, kept because eight
% callbacks say "label in MNI space" and read better for it.
[handles.project, handles.work] = ...
    ielec.label(struct('space','MNI'), handles.project, handles.work);

%%%%%%%%%%%%%%%           Labels to Native space            %%%%%%%%%%%%%%%
function handles=labels2NativeSpace(handles)
% Thin GUI wrapper around ielec.label, as labels2MNIspace above.
[handles.project, handles.work] = ...
    ielec.label(struct('space','Native'), handles.project, handles.work);


% --------------------------------------------------------------------
%%%%%%%%%%%%%         Add brain PIAL surfaces from FS          %%%%%%%%%%%%
function addFSsurfacesuipushtool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to addFSsurfacesuipushtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% MRI should be loaded first
if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project. Then load surfaces...')
    return
end

% load right surface
disp (['Please select a RIGHT hemisphere pial surface' ])
[rFile,PathName]=uigetfile({'*.pial' , '*.pial';   '*.*', '*.*'}, 'Load RIGHT hemisphere surface ',handles.work.PathName);

if isequal(rFile,0)
    return;
end
rFile=[PathName rFile]; %concat file name
handles.work.PathName=PathName;

% load left surface
disp (['Please select a LEFT hemisphere pial surface' ])
[lFile,PathName]=uigetfile({'*.pial' , '*.pial';   '*.*', '*.*'}, 'Load LEFT hemisphere surface ',PathName);

if isequal(lFile,0)
   return;
end
lFile=[PathName lFile]; %concat file name

cfg = [];
cfg.right  = rFile;
cfg.left   = lFile;
cfg.target = 'pial';
cfg.centre = false;

choice = questdlg('Do you want to center the surfaces? (Recommended)', ...
    '', 'Yes','No','Cancel','Yes');
% Handle response
switch choice
    case 'Yes'
        % translate pial surfaces to MRI center
        cfg.centre = true;

    case 'No'
        % do nothing
    case 'Cancel'
        return;
    case ''
        return;
end

% the pial surfaces are kept whole: the annotation below has one label per
% vertex, so a thinned surface would have vertices with no label
[handles.project, handles.work] = ...
    ielec.loadSurfaces(cfg, handles.project, handles.work);

disp (['Loaded surfaces from ' rFile ' (right hem) and '  lFile ' (left hem)' ])
if cfg.centre
    disp (['Surfaces centered'])
end

%reduce to 15k vertices for nice resolution and speed plots
% k = handles.work.options.reduce_surfaces_elements / length(vR);
% if k< 1
%     try
%         [handles.project.verticesR,handles.project.facesR]=meshresample(vR,fR,k);
%         [handles.project.verticesL,handles.project.facesL]=meshresample(vL,fL,k);
%     catch
%         disp({'WARNING - iso2mesh function meshresample not found or error.'
%             'Pial surfaces will not be resampled. 3D view could be slowed down.'})
%         handles.project.verticesR=vR;
%         handles.project.facesR=fR;
%         handles.project.verticesL=vL;
%         handles.project.facesL=fL;
%     end
%     
% else
%     handles.project.verticesR=vR;
%     handles.project.verticesL=vL;
%     handles.project.facesR=fR;
%     handles.project.facesL=fL;
% end
% No reduction to be able to usse annotation information

% dealin with annotation files after surfaces are done
choice = questdlg('Do you want to load annotation files?', ...
    '', 'Yes','No','Cancel','Yes');

switch choice
    case 'Yes'
        % load right annotation
        disp (['Please select a RIGHT hemisphere annotation file' ])

        [AnnotFile_R,PathName]=uigetfile({'*.annot' , '*.annot';   '*.*', '*.*'}, 'Load RIGHT hemisphere annotation ',PathName);
        
        if isequal(AnnotFile_R,0)
            return;
        end
        AnnotFile_R=[PathName AnnotFile_R]; %concat file name
        
        % load right annotation
        disp (['Please select a LEFT hemisphere annotation file' ])
        [AnnotFile_L,PathName]=uigetfile({'*.annot' , '*.annot';   '*.*', '*.*'}, 'Load LEFT hemisphere annotation ',PathName);
        
        if isequal(AnnotFile_L,0)
            return;
        end
        AnnotFile_L=[PathName AnnotFile_L]; %concat file name

        annotCfg = [];
        annotCfg.right = AnnotFile_R;
        annotCfg.left  = AnnotFile_L;
        [handles.project, handles.work, colours] = ...
            ielec.loadAnnotations(annotCfg, handles.project, handles.work);
        disp (['Loaded annotation files from ' AnnotFile_R ' (right hem) and ' AnnotFile_L ' (left hem)'])

        handles.ui.AnnotColor_R=colours.right; %actual color used for each node
        handles.ui.AnnotColor_L=colours.left; %actual color used for each node
        
    case 'No'
        
        % no annotation: the labels are cleared and every node is grey
        [handles.project, handles.work, colours] = ...
            ielec.loadAnnotations([], handles.project, handles.work);

        handles.ui.AnnotColor_R=colours.right;
        handles.ui.AnnotColor_L=colours.left;
        
    case 'Cancel'
        return;
    case ''
        return;
end

handles.project.currentSpace='Native'; % options are 'Native' 'MNI'
% Update handles structure
guidata(hObject, handles);
%lock MNI labels button
set(handles.MNILabelstogglebutton,'State','Off'); % this will call to labels2NativeSpace and updateElectrodes3D

handles.ui.updatePlots.surfaces=1;
handles=updateElectrodes3D (handles);
% Update handles structure
guidata(hObject, handles);


%%%%%%%%%%%%%         Clear brain PIAL surfaces from FS          %%%%%%%%%%%%
function ClearFSsurfaceuipushtool2_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to ClearFSsurfaceuipushtool2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% MRI should be loaded first
if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project. Then you can add surfaces...')
    return
end
handles.project.verticesR=[];
handles.project.verticesL=[];
handles.project.facesR=[];
handles.project.facesL=[];

handles.project.AnnotLabel_R=[];
handles.project.AnnotLabel_L=[];
handles.project.AnnotColortable_R=[]; 
handles.project.AnnotColortable_L=[]; 
handles.ui.AnnotColor_R=[];
handles.ui.AnnotColor_L=[];

handles.project.currentSpace='MNI'; % options are 'Native' 'MNI' 
handles.ui.updatePlots.surfaces=1;
% Update handles structure
guidata(hObject, handles);

set(handles.MNILabelstogglebutton,'State','On'); % this will call to labels2MNIspace and updateElectrodes3D

% --------------------------------------------------------------------
%%%%%%%%%%%%%          Add/Build SCE surfaces from FS                %%%%%%%%%%%%
function addSCEuipushtool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to addSCEuipushtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% MRI should be loaded first
if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project. Then load surfaces...')
    return
end

type = questdlg('Do you want to load a Smooth Cortical Envelope (SCE) surface, or build one from the pial surface?', ...
	'SCE', ...
	'Load','Build','Load');

% Handle response
switch type
    case 'Load'
        
        % load surface
        [rFile,PathName]=uigetfile({'*.pial-outer-smoothed','*.pial-outer-smoothed'; '*.*', '*.*'}, 'Load RIGHT hemisphere Smoothed Cortical Envelope ',handles.work.PathName);
        
        if ~isequal(rFile,0)
            handles.work.PathName=PathName;
            [lFile,PathName]=uigetfile({'*.pial-outer-smoothed','*.pial-outer-smoothed'; '*.*', '*.*'}, 'Load LEFT hemisphere Smoothed Cortical Envelope ',handles.work.PathName);
            
            if ~isequal(lFile,0)
                
                cfg = [];
                cfg.right    = [PathName rFile];
                cfg.left     = [PathName lFile];
                cfg.target   = 'envelope';
                cfg.centre   = false;
                cfg.resample = 15000;  % nice resolution and speed plots

                choice = questdlg('Do you want to center the surfaces? (Recommended)', ...
                    '', 'Yes','No','Cancel','Yes');
                % Handle response
                switch choice
                    case 'Yes'
                        % translate pial surfaces to MRI center
                        cfg.centre = true;

                    case 'No'
                        % do nothing
                    case 'Cancel'
                        return;
                    case ''
                        return;
                end

                [handles.project, handles.work] = ...
                    ielec.loadSurfaces(cfg, handles.project, handles.work);

                disp (['Loaded surfaces from ' PathName, rFile ' and ' PathName, lFile ])
                
            else
                return; % no file
            end
        else
            return; % no file
        end
        
    case 'Build'
        
        % compute SCE, and reduce to 15k vertices for nice resolution and
        % speed plots
        [handles.project, handles.work] = ielec.buildEnvelope(struct('resample', 15000), ...
                                                               handles.project, ...
                                                               handles.work);
        
end

handles.project.currentSpace='Native'; % options are 'Native' 'MNI'
% Update handles structure
guidata(hObject, handles);
set(handles.MNILabelstogglebutton,'State','Off'); % this will call to labels2NativeSpace and updateElectrodes3D



%%%%%%%%%%%%%          Clear SCE surfaces from FS             %%%%%%%%%%%%
function removeSCEuipushtooluipushtool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to removeSCEuipushtooluipushtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% MRI should be loaded first
if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project. Then you can add surfaces...')
    return
end
handles.project.vertices_SCE_R=[];
handles.project.vertices_SCE_L=[];
handles.project.faces_SCE_R=[];
handles.project.faces_SCE_L=[];

handles.project.currentSpace='MNI'; % options are 'Native' 'MNI' 
% Update handles structure
guidata(hObject, handles);

set(handles.MNILabelstogglebutton,'State','On'); % this will call to labels2MNISpace and updateElectrodes3D

% --------------------------------------------------------------------
%%%%%%%%%%%%%%%        save planning structure              %%%%%%%%%%%%%%%
function savePlanninguitoggletool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to savePlanninguitoggletool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% MRI should be loaded first
if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project. Then do the planning...')
    return
end
if isempty(handles.project.targets)
    warning('Targets is empty')
else
    [FileName,PathName] = uiputfile('*.mat','Save planning structure', handles.work.PathName);
    if FileName~=0
        handles.work.PathName=PathName;
        cfg = [];
        cfg.file = [handles.work.PathName, FileName];
        [handles.project, handles.work] = ...
            ielec.saveTargets(cfg, handles.project, handles.work);
        disp (['Saved targets in ' handles.work.PathName, FileName])
    end
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%        Load planning structure              %%%%%%%%%%%%%%%
function LoadPlanninguitoggletool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to LoadPlanninguitoggletool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% MRI should be loaded first
if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project')
    return
end

[FileName,PathName] = uigetfile('*.mat','Load planning structure',handles.work.PathName);
if FileName~=0
    handles.work.PathName=PathName;
    cfg = [];
    cfg.file = [handles.work.PathName, FileName];
    [handles.project, handles.work] = ...
        ielec.loadTargets(cfg, handles.project, handles.work);
    disp (['Loaded targets from ' handles.work.PathName, FileName])

    
    % go to first target
    l=1;
    
    handles = setSelectedPlanningArray(handles, l);
    
    handles = UpdateTargetEditBox(handles);
    
    handles.ui.updatePlots.targets=1;
    handles.ui.updatePlots.targetLines=1;
    handles=updateTAC(handles);
    handles=updateElectrodes3D(handles);
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%        Make report planning structure       %%%%%%%%%%%%%%%
function ReportPlanninguipushtool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to ReportPlanninguipushtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% MRI should be loaded first
if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project')
    return
end

if ~isempty(handles.project.targets)
    [FileName,PathName] = uiputfile('.txt','.txt ouput file',handles.work.PathName);
    if FileName~=0
        handles = exportFile(handles, 'targetLabels', 'contacts', [PathName FileName]);
        disp (['Saved targets report in ' handles.work.PathName, FileName])

    end
else
    warning ('Targets structure is empty');
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%              rotate 3d                   %%%%%%%%%%%%%%%
% --------------------------------------------------------------------
function uitoggletool2_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uitoggletool2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(handles.ui.rotate3d.Enable,'on')
    handles.ui.rotate3d.Enable='off';
else
    handles.ui.rotate3d.Enable='on';
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%         change colormap                     %%%%%%%%%%%%%%%
function ColorMappushtool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to ColorMappushtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isequal(get(handles.figure1,'colormap'),gray)
    if exist('parula','file') % ver 2014b and above
        colormap parula
    else
        colormap jet
    end
else
    colormap gray
end

%%%%%%%%%%%%%%%         reset 2D view plots - remove?       %%%%%%%%%%%%%%%
function resetTACplotButton_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to resetTACplotButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Both flags, as everywhere else that resets the 2-D axes. resetTAC alone
% does nothing: updateTAC only redraws a plane when its slice has changed
% or views2D forces it, and the axis-limit reset lives inside that test. So
% pressing this button without moving the cursor used to be a no-op, quietly.
handles.ui.updatePlots.views2D=[1 1 1];  % Force update all slices
handles.ui.updatePlots.resetTAC=1;       % reset 2D views axes
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%         change Layout                       %%%%%%%%%%%%%%%
%--------------------------------------------------------------------
function ToggleLayoutuitoggletool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to ToggleLayoutuitoggletool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



if handles.ui.layout==0
    %  3D view  + 2 views
    handles.ui.layout=1;
    set(handles.PanelThres,'Visible','off');
    set(handles.Panel3D,'Position', [0.001 0.001 0.437 0.998]);
    set(handles.Panel3Doptions,'Position', [0.88 0.8 0.11 0.36/2]);
    
    set(handles.Panel3D,'FontSize',0.013);  
    
elseif handles.ui.layout==1 
    % 2D views
    handles.ui.layout=2;
    set(handles.Panel3D,'Visible','off');
    set(handles.PanelClustering,'Visible','off');
    set(handles.PanelLabel,'Visible','off');
    
    set(handles.PanelZ,'Position', [0.001 0.3 0.332 0.699]);
    set(handles.PanelY,'Position', [0.335 0.3 0.332 0.699]);
    set(handles.PanelX,'Position', [0.668 0.3 0.332 0.699]);
    
    set(handles.Panel2Dviews,'Position', [0.528 0.213 0.192 0.087]);
    set(handles.PanelCoordinates,'Position', [0.528 0.113 0.192 0.098]);
    
    set(handles.PanelX,'FontSize',0.018);
    set(handles.PanelY,'FontSize',0.018);
    set(handles.PanelZ,'FontSize',0.018);
    
else
    % set default view
    handles.ui.layout=0;
    set(handles.Panel3D,'Position', [0.001 0.5 0.437 0.499]);
    set(handles.PanelThres,'Visible','on');
    if  handles.ui.options.showLocalizeTools 
        set(handles.PanelClustering,'Visible','on');
        set(handles.PanelLabel,'Visible','on');
    else
        set(handles.PanelClustering,'Visible','off');
        set(handles.PanelLabel,'Visible','off');
    end
    if handles.ui.options.showPlanTools
         set(handles.PanelPlanningDepths,'Visible','on'); % 
    else
        set(handles.PanelPlanningDepths,'Visible','off');
    end
    set(handles.Panel3Doptions,'Position', [0.88 0.593 0.11 0.36]);
    set(handles.Panel3D,'Visible','on');
    set(handles.PanelZ,'Position', [0.441 0.0 0.278 0.5]);
    set(handles.PanelY,'Position', [0.441 0.5 0.278 0.5]);
    set(handles.PanelX,'Position', [0.721 0.5 0.278 0.5]);
    
    set(handles.PanelCoordinates,'Position', [0.801 0.309 0.192 0.098]);
    set(handles.Panel2Dviews,'Position', [0.801 0.409 0.192 0.087]);

    set(handles.Panel3D,'FontSize',0.026);   
    set(handles.PanelThres,'FontSize',0.026);
    set(handles.PanelX,'FontSize',0.026);
    set(handles.PanelY,'FontSize',0.026);
    set(handles.PanelZ,'FontSize',0.026);
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%              view cross                     %%%%%%%%%%%%%%%
function viewCrossbutton_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to viewCrossbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(handles.project.T1); % avoid changing crosshairs wwithout images loaded
%    handles.ui.updatePlots.views2D=[1 1 1];
%    handles=updateTAC(handles);
    handles=cross2D(handles); 
    handles=cross3D(handles);
    handles=cross3DThres(handles);
    
    % Update handles structure
    guidata(hObject, handles);
end

%%%%%%%%%%%%%%%              snapshoot                     %%%%%%%%%%%%%%%
function snapshoottool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to snapshoottool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

defaultFileName=[handles.work.PathName filesep  handles.work.FileName(1:end-4) '-' handles.editElecLabels.String];
[FileName,PathName] = uiputfile({'*.png'; '*.jpg'; '*.tif';'*.bmp';'*.eps';'*.fig'},'Save snapshot',defaultFileName);
if FileName~=0
    handles.work.PathName=PathName;
    if strcmpi( FileName(end-2:end), 'png')
        print('-dpng',[handles.work.PathName  FileName]);
    elseif strcmpi( FileName(end-2:end), 'jpg')
        print('-djpeg',[handles.work.PathName  FileName]);
    elseif strcmpi( FileName(end-2:end), 'tif')
        print('-dtiff',[handles.work.PathName  FileName]);
    elseif strcmpi( FileName(end-2:end), 'bmp')
        print('-dbmp',[handles.work.PathName  FileName]);
    elseif strcmpi( FileName(end-2:end), 'eps')
        print('-depsc','-r300',[handles.work.PathName  FileName]);
    elseif strcmpi( FileName(end-2:end), 'fig')        
        Fig1 = figure;
        copyobj(handles.axes2, Fig1);
        savefig(Fig1, [handles.work.PathName  FileName]);
        close(Fig1);
    end
    
end

% Update handles structure
guidata(hObject, handles);

%--------------------------------------------------------------------
%%%%%%%%%%%%%%%              about box                     %%%%%%%%%%%%%%%
function uipushtool13_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtool13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Or msg using a figure
[cdata,map] = imread('Icon_mini.jpg');
%Create the message dialog box, including the custom icon.
%h=msgbox('Operation Completed', 'Success','custom',cdata,map);

msgbox({
    ' iElectrodes'
    [' Version: ' handles.work.iElectrodes_version]
    [' ' handles.work.iElectrodes_date]
    ''
    ' Copyright (C) 2014, 2015, 2016, 2017  '
    ' Alejandro Omar Blenkmann, PhD'
    ' ablenkmann@gmail.com'
    ' '
    ' For more information visit '
    ' https://sourceforge.net/projects/ielectrodes/ ' 
    
    }, 'About this program' ,'custom',cdata,map);


%%%%%%%%%%%%%%%              help                           %%%%%%%%%%%%%%%
function helpPushtool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to helpPushtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% open help Wiki in system web browser
web('https://sourceforge.net/p/ielectrodes/wiki/Home/','-browser')


function Configpushtool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to Configpushtool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Reload configuration from file
cfg = [];
[handles.project, handles.work] = ...
    ielec.setOptions(cfg, handles.project, handles.work);
handles.ui.options   = defaultDisplayOptions([]);
disp('Default_ielectrodes_options.m loaded')
disp('DefaultDisplayOptions loaded')

colors=[];
handles.ui.colors=defaultColors(colors);
disp('DefaultColors loaded')

handles=updateMix_TAC_MR(handles);

handles.ui.updatePlots.views2D=[1 1 1]; % Force update all slices
handles.ui.updatePlots.resetTAC=1;      % reset 2D views axes

% update elec labels
if strcmp (handles.project.currentSpace, 'Native') % options are 'Native' 'MNI' 
    handles=labels2NativeSpace(handles);
else
     handles=labels2MNIspace(handles);
end
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%            VISUALIZATION                    %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%            update 2D views                  %%%%%%%%%%%%%%%
function handles=updateTAC(handles)

% This function is afecting the visual variables inside handles, but not
% updating handle structure. call guidata(hObject, handles) afterwards.
% inicialize cross handles
% calling to cross2D, cross3D, cross3DThres

if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project.')
    return
end

D=size(handles.project.T1.img);

% update sliders values to round values
x=round(get(handles.sliderX,'Value'));
y=round(get(handles.sliderY,'Value'));
z=round(get(handles.sliderZ,'Value'));

% set sliders values
set(handles.sliderX,'Value',x); set(handles.sliderY,'Value',y); set(handles.sliderZ,'Value',z);
% set matrix coords text
set(handles.textX,'String',x); set(handles.textY,'String', y); set(handles.textZ,'String', z);
% define anatomical coords
prevCursor=handles.ui.cursor;
handles.ui.cursor=mesh2AnatSpace([x y z], handles.project.S2);

%indicates if need to update current slice or not
updateSlice=(abs(handles.ui.cursor-prevCursor)>=diag(handles.project.S2(1:3,1:3))') | handles.ui.updatePlots.views2D; %Force update all slices;
handles.ui.updatePlots.views2D=[0 0 0]; %remove force plot

% coordinates box
set(handles.textXac,'String', int2str(handles.ui.cursor(1)));
set(handles.textYac,'String', int2str(handles.ui.cursor(2)));
set(handles.textZac,'String', int2str(handles.ui.cursor(3)));
 
% mWS=get(handles.MinWinslider,'Value'); not used in color data anymore
% MWS=get(handles.MaxWinslider,'Value');

markerPlanning=handles.ui.colors.targetMarker2D;
colorPlanning=handles.ui.colors.target2D;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ------------- the three 2-D plane views -------
%
% X, Y and Z used to be three blocks of 120 lines that differed only in
% which axis is sliced. Everything else - the image, the parcellation
% overlay, the electrode overlay, the planning overlay - was the same work
% written three times, so a change to one view had to be made three times
% to keep the views consistent, and nothing said so.
%
% The whole difference between them is the table below. For plane p:
%
%   planeAxes(p)   the axes it is drawn in
%   sliceVoxel(p)  the slider position, which fixes the slice
%   inPlane        the two image dimensions that remain, ascending
%
% inPlane is simply "every dimension except p", which is why the in-plane
% marker columns, the axis limits and the pixel aspect ratio all follow
% from p alone.

planeAxes  = [handles.axesX handles.axesY handles.axesZ];
sliceVoxel = [x y z];

for p = 1:3

    thisAxes = planeAxes(p);
    inPlane  = setdiff(1:3, p);      % p=1 -> [2 3], p=2 -> [1 3], p=3 -> [1 2]
    v        = sliceVoxel(p);

    set(handles.figure1,'CurrentAxes',thisAxes);

    if ~updateSlice(p)
        continue
    end

    set(thisAxes,'NextPlot','replacechildren');

    % the slice itself: colon on the two in-plane dimensions, the slider
    % position on the third
    sliceIdx    = {':',':',':'};
    sliceIdx{p} = v;

    if handles.ui.color
        img=squeeze(handles.ui.imgW(sliceIdx{:},:)); %true color imgW:(dimX,dimY,dimZ,3)
        if ~isempty(handles.ui.wmparcColors)
            imgAtlas=squeeze(handles.ui.wmparcColors(sliceIdx{:},:));
            alphaMask=double(sum(imgAtlas,3)>0);
        else
            imgAtlas=[];
            alphaMask=1;
        end
    else
        img=squeeze(handles.ui.imgW(sliceIdx{:}));
    end

    imagesc(fliplr(rot90(img,3)));
    set(thisAxes,'NextPlot','add');

    if get(handles.parcellationCheckbox,'Value')
        imagesc(fliplr(rot90(imgAtlas,3)),'AlphaData',fliplr(rot90(alphaMask,3))*handles.ui.colors.alphaAtlas);
    end

    if handles.ui.updatePlots.resetTAC
        pixdim=diag(handles.project.S2(:,1:3));
        DD=size(handles.project.T1.img);
        set(thisAxes,'xlim',[0 DD(inPlane(1))],'ylim',[0 DD(inPlane(2))])
        set(thisAxes,'DataAspectRatio',[1/pixdim(inPlane(1)) 1/pixdim(inPlane(2)) 1]);
        set(thisAxes,'YDir','normal')
        set(thisAxes,'XDir','reverse')
        if p == 3
            handles.ui.updatePlots.resetTAC=0;   % cleared once, after the last plane
        end
    end

    %overlay electrodes
    if get(handles.ElecOverlaycheckbox,'value')
        if get(handles.plotAllRadiobutton,'value') %plot all
            arrayList = 1:length(handles.project.electrodes);
        else %plot only selected electrode
            arrayList = selectedArray(handles);
            if arrayList == 0, arrayList = []; end
        end
        for i = arrayList
            if strcmp(handles.project.electrodes{i}.Type,'grid')
                colorElectrodes=handles.ui.colors.electrodesGrid2D;
                markerElectrodes=handles.ui.colors.electrodesMarker2D;
            else
                colorElectrodes=handles.ui.colors.electrodesDepth2D;
                markerElectrodes=handles.ui.colors.electrodesMarker2D;
            end
            if get(handles.projectSCEcheckbox,'Value') % projection to SCE
                c=AnatSpace2Mesh([handles.project.electrodes{i}.projection{1}.x handles.project.electrodes{i}.projection{1}.y handles.project.electrodes{i}.projection{1}.z],handles.project.S2);
            else
                c=AnatSpace2Mesh([handles.project.electrodes{i}.x handles.project.electrodes{i}.y handles.project.electrodes{i}.z],handles.project.S2);
            end
            if get(handles.Collapsecheckbox,'Value')
                line(c(:,inPlane(1)),c(:,inPlane(2)),'Marker',markerElectrodes,'Color',colorElectrodes,'LineStyle','none');
            else
                ind= abs(c(:,p)-v)<1;
                line(c(ind,inPlane(1)),c(ind,inPlane(2)),'Marker',markerElectrodes,'Color',colorElectrodes,'LineStyle','none');
            end
        end
    end

    %overlay planning
    if get(handles.planningOverlaycheckbox,'value')
        if get(handles.plotAllPlanningRadioButton,'value') %plot all
            targetList = 1:length(handles.project.targets);
        else %plot only selected planning electrode
            targetList = selectedPlanningArray(handles);
            if targetList <= 0, targetList = []; end
        end
        for i = targetList
            if isempty(handles.project.targets{i}.projection)
                c=AnatSpace2Mesh([handles.project.targets{i}.x handles.project.targets{i}.y handles.project.targets{i}.z],handles.project.S2);
            else
                c=AnatSpace2Mesh([handles.project.targets{i}.projection{1}.x handles.project.targets{i}.projection{1}.y handles.project.targets{i}.projection{1}.z],handles.project.S2);
            end
            if get(handles.Collapsecheckbox,'Value')
                line(c(:,inPlane(1)),c(:,inPlane(2)),'Marker',markerPlanning,'Color',colorPlanning,'LineStyle','none');
            else
                ind= abs(c(:,p)-v)<1;
                line(c(ind,inPlane(1)),c(ind,inPlane(2)),'Marker',markerPlanning,'Color',colorPlanning,'LineStyle','none');
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Update anatomical Labels in Coordinates box

% Which atlas can answer, and what it says, is the layer's; what to write in
% the box when none can is this window's.
cfg = [];
cfg.coordinate = handles.ui.cursor;
[~, ~, whereTheCursorIs] = ielec.pointLabel(cfg, handles.project, handles.work);

if strcmp(whereTheCursorIs.source, 'none')
    set(handles.aLabelText,'String','No Native Atlas loaded');
else
    set(handles.aLabelText,'String',whereTheCursorIs.label);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update crosshairs
%update cross in 2D
handles=cross2D(handles);%,updateSlice);

% update cross in axes2 (3D)
handles=cross3D(handles);%,0);

% update cross in axes1 (3D Threshold)
handles=cross3DThres(handles);

%%%%%%%%%%%%%%%            update 3D view                   %%%%%%%%%%%%%%%
function handles=updateElectrodes3D (handles)
% this function is afecting the visual variables inside handles, but not
% updating handle structure. call guidata(hObject, handles) afterwards
% calling to cross3D and cross3DThres

%select axes
axes(handles.axes2);
if handles.ui.updatePlots.cla
    cla %clear axes
    set(handles.axes2, 'Clipping', 'on');
    hold on;
    axis image
    xlabel(handles.axes2,'x'); ylabel(handles.axes2,'y'); zlabel(handles.axes2,'z');
    handles.ui.plot3Dhandles.GS=[];
    handles.ui.plot3Dhandles.electrodes=[];
    handles.ui.plot3Dhandles.labels=[];
    handles.ui.plot3Dhandles.targetLabels=[];
    handles.ui.plot3Dhandles.elecLines=[];
    handles.ui.plot3Dhandles.targets=[];
    handles.ui.plot3Dhandles.targetLines=[];
    handles.ui.plot3Dhandles.surfaces=[];
    handles.ui.plot3Dhandles.hcam=[];
    handles.ui.updatePlots.cla=0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot GS clusterd coordinates

% if ~isempty(handles.work.GS) %plot just after cluster (not labeled or indexed)
%     scatter3(handles.axes2,handles.work.GS(:,1),handles.work.GS(:,2),handles.work.GS(:,3),'ro', 'filled')

if handles.ui.updatePlots.GS %plot
    if ishandle(handles.ui.plot3Dhandles.GS) %clear and replace
         delete(handles.ui.plot3Dhandles.GS);
    end
    if ~isempty(handles.work.GS) 
        handles.ui.plot3Dhandles.GS=scatter3(handles.axes2,handles.work.GS(:,1),handles.work.GS(:,2),handles.work.GS(:,3),'ro', 'filled');
    end
    handles.ui.updatePlots.GS=0;
end
        
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get plotlist for electrodes, labels, connections  

if ~isempty(handles.project.electrodes)>0 % plot electrodes (labeled or indexed)
    %plot all electrode arrays
    if get(handles.plotAllRadiobutton,'value')
        plotList=1:length(handles.project.electrodes);
    else %plot one electrode array
        plotList=selectedArray(handles);
    end
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot electrodes
if handles.ui.updatePlots.electrodes %plot
    %clear and replace
    dlt=ishandle(handles.ui.plot3Dhandles.electrodes);
    if any(dlt) 
        delete(handles.ui.plot3Dhandles.electrodes(dlt));
    end
    
    if ~isempty(handles.project.electrodes)>0 % plot electrodes
        for j=plotList
            if get(handles.projectSCEcheckbox,'Value') % projection to SCE
                x=handles.project.electrodes{j}.projection{1}.x;
                y=handles.project.electrodes{j}.projection{1}.y;
                z=handles.project.electrodes{j}.projection{1}.z;
            else %without projection
                x=handles.project.electrodes{j}.x;
                y=handles.project.electrodes{j}.y;
                z=handles.project.electrodes{j}.z;
            end
            %plot electrodes
            if isfield (handles.project.electrodes{j},'Type') & strcmp(handles.project.electrodes{j}.Type,'grid');
                %grids
                handles.ui.plot3Dhandles.electrodes(j)=scatter3(handles.axes2,x,y,z,handles.ui.colors.electrodesSize3D,handles.ui.colors.electrodesGrid3D,handles.ui.colors.electrodesMarker3D, 'filled');%'ro'
            else
                %depth
                handles.ui.plot3Dhandles.electrodes(j)=scatter3(handles.axes2,x,y,z,handles.ui.colors.electrodesSize3D,handles.ui.colors.electrodesDepth3D,handles.ui.colors.electrodesMarker3D, 'filled');%'bo'
            end
        end
        
        % plot selected electrode in black
        a=selectedArray(handles);
        l=selectedContact(handles);
        if get(handles.projectSCEcheckbox,'Value')  && isfield(handles.project.electrodes{a},'projection')% projection to SCE
            handles.ui.plot3Dhandles.electrodes(end+1)=scatter3(handles.axes2,handles.project.electrodes{a}.projection{1}.x(l),...
                handles.project.electrodes{a}.projection{1}.y(l),handles.project.electrodes{a}.projection{1}.z(l),handles.ui.colors.electrodesSize3D,handles.ui.colors.electrodesSelected3D,handles.ui.colors.electrodesMarker3D, 'filled');
        else
            handles.ui.plot3Dhandles.electrodes(end+1)=scatter3(handles.axes2,handles.project.electrodes{a}.x(l),...
                handles.project.electrodes{a}.y(l),handles.project.electrodes{a}.z(l),handles.ui.colors.electrodesSize3D,handles.ui.colors.electrodesSelected3D,handles.ui.colors.electrodesMarker3D, 'filled');
        end
    end

    handles.ui.updatePlots.electrodes=0;    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot lines(cylinders) between electrodes
 if ~isempty(handles.project.electrodes)>0 && handles.ui.updatePlots.elecLines %% && get(handles.PlotConnCheckbox,'Value')
    %clear and replace
    for k=1:length(handles.ui.plot3Dhandles.elecLines)
        dlt=ishandle(handles.ui.plot3Dhandles.elecLines{k});
        if any(dlt)
            delete(handles.ui.plot3Dhandles.elecLines{k}(dlt));
        end
    end
    if get(handles.PlotConnCheckbox,'Value')
        
        for j=plotList
            if get(handles.projectSCEcheckbox,'Value') % projection to SCE
                x=handles.project.electrodes{j}.projection{1}.x;
                y=handles.project.electrodes{j}.projection{1}.y;
                z=handles.project.electrodes{j}.projection{1}.z;
            else %without projection
                x=handles.project.electrodes{j}.x;
                y=handles.project.electrodes{j}.y;
                z=handles.project.electrodes{j}.z;
            end
            
            X=[x,y,z];
            if isfield (handles.project.electrodes{j},'Type') && strcmp(handles.project.electrodes{j}.Type,'grid')
                color=handles.ui.colors.cylColorGrid;
            else
                color=handles.ui.colors.cylColorDepth;
            end
            handles.ui.plot3Dhandles.elecLines{j}=plotElectrodesLines(X,handles.project.electrodes{j}.rows,handles.project.electrodes{j}.columns,color);
%            set(handles.ui.plot3Dhandles.elecLines{j},'FaceAlpha',handles.ui.colors.cylAlpha);
        end
    end
     handles.ui.updatePlots.elecLines = 0;       
 end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot electrode labels

if ~isempty(handles.project.electrodes)>0 && handles.ui.updatePlots.labels
    %clear and replace
    dlt=ishandle(handles.ui.plot3Dhandles.labels);
    if any(dlt) 
        delete(handles.ui.plot3Dhandles.labels(dlt));
    end
     
     %     if isfield(handles.project.electrodes{j},'recorded_channels') %for compatiblillity with previous versions
     %             labelList=handles.project.electrodes{j}.recorded_channels;
     %             ch_label=cell(1,handles.project.electrodes{j}.nElectrodes);
     %             ch_label(labelList)=handles.project.electrodes{j}.ch_label;
     %         else
     %             labelList=1:handles.project.electrodes{j}.nElectrodes;
     %             ch_label=handles.project.electrodes{j}.ch_label;
     %         end
     k=1;
     for j=plotList
        if get(handles.projectSCEcheckbox,'Value') % projection to SCE
            x=handles.project.electrodes{j}.projection{1}.x;
            y=handles.project.electrodes{j}.projection{1}.y;
            z=handles.project.electrodes{j}.projection{1}.z;
        else %without projection
            x=handles.project.electrodes{j}.x;
            y=handles.project.electrodes{j}.y;
            z=handles.project.electrodes{j}.z;
        end
        
         labelList=1:handles.project.electrodes{j}.nElectrodes;
         ch_label=handles.project.electrodes{j}.ch_label;
         
         if get(handles.DispLabelsCheckbox,'Value')
             for i=labelList
                 %remove special characters
                 ch_label{i}(~isstrprop(ch_label{i},'alphanum')) = ' ';
                 handles.ui.plot3Dhandles.labels(k)=...
                     text(x(i)+1,y(i)+1,z(i)+1,ch_label{i},...
                     'color',handles.ui.colors.labelsColor,...
                     'FontSize',handles.ui.colors.labelsFontSize,...
                 'FontWeight','bold');
                k=k+1;
             end
         end
     end
     handles.ui.updatePlots.labels=0;
 end   
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get plotlist for Targerts
plotList=[];
if ~isempty(handles.project.targets)>0 % plot targets
    %plot all targets array
    if get(handles.plotAllPlanningRadioButton,'value')
        plotList=1:length(handles.project.targets);
    else %plot one target array
        plotList=selectedPlanningArray(handles);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot targets
   
if ~isempty(handles.project.targets)>0 && handles.ui.updatePlots.targets

    %clear and replace    
    for k=1:length(handles.ui.plot3Dhandles.targets)
        dlt=ishandle(handles.ui.plot3Dhandles.targets{k});
        if any(dlt)
            delete(handles.ui.plot3Dhandles.targets{k});
        end
    end
        
    for j=plotList
        if ~isempty(handles.project.targets{j}.projection)
            x=handles.project.targets{j}.projection{1}.x;
            y=handles.project.targets{j}.projection{1}.y;
            z=handles.project.targets{j}.projection{1}.z;
        else
            x=handles.project.targets{j}.x;
            y=handles.project.targets{j}.y;
            z=handles.project.targets{j}.z;
        end
        handles.ui.plot3Dhandles.targets{j}=scatter3(handles.axes2,x,y,z,handles.ui.colors.targetSize3D,handles.ui.colors.target3D,handles.ui.colors.targetMarker3D, 'filled');%'go'
    end
    
    % plot selected target in black
    a=selectedPlanningArray(handles);
    l=selectedPlanningTarget(handles);
    
    if ~isempty(handles.project.targets{j}.projection)
        handles.ui.plot3Dhandles.targets{end+1}=scatter3(handles.axes2,handles.project.targets{a}.projection{1}.x(l),...
            handles.project.targets{a}.projection{1}.y(l),handles.project.targets{a}.projection{1}.z(l),handles.ui.colors.targetSize3D,handles.ui.colors.targetSelected3D,handles.ui.colors.targetMarker3D, 'filled');%'ko'
    else
        handles.ui.plot3Dhandles.targets{end+1}=scatter3(handles.axes2,handles.project.targets{a}.x(l),...
            handles.project.targets{a}.y(l),handles.project.targets{a}.z(l),handles.ui.colors.targetSize3D,handles.ui.colors.targetSelected3D,handles.ui.colors.targetMarker3D, 'filled');%'ko'
    end
    handles.ui.updatePlots.targets=0;    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot targetLines

if ~isempty(handles.project.targets)>0 && handles.ui.updatePlots.targetLines
    %clear and replace
    for k=1:length(handles.ui.plot3Dhandles.targetLines)
        dlt=ishandle(handles.ui.plot3Dhandles.targetLines{k});
        if any(dlt)
            delete(handles.ui.plot3Dhandles.targetLines{k});
        end
    end
    
    %plot lines(cylinders) between target electrodes
    for j=plotList
        if get(handles.PlotConnCheckbox,'Value')
            
        if ~isempty(handles.project.targets{j}.projection)
            x=handles.project.targets{j}.projection{1}.x;
            y=handles.project.targets{j}.projection{1}.y;
            z=handles.project.targets{j}.projection{1}.z;
        else
            x=handles.project.targets{j}.x;
            y=handles.project.targets{j}.y;
            z=handles.project.targets{j}.z;
        end
            X=[x,y,z];
            color=handles.ui.colors.cylColorTargets;
            handles.ui.plot3Dhandles.targetLines{j}=plotElectrodesLines(X,handles.project.targets{j}.rows,handles.project.targets{j}.columns,color);
%            set(handles.ui.plot3Dhandles.targetLines{j},'FaceAlpha',handles.ui.colors.cylAlphaTages);
        end
    end    
    handles.ui.updatePlots.targetLines=0;    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot target labels
% TODO

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot brain surfaces

if handles.ui.updatePlots.surfaces
    hind=zeros(1,4);
    %clear and replace
    dlt=ishandle(handles.ui.plot3Dhandles.surfaces);
    if any(dlt)
        delete(handles.ui.plot3Dhandles.surfaces(dlt));
    end
    
    % use subject surface
    if strcmp(handles.project.currentSpace,'Native')
        if ~isempty(handles.project.verticesR) %plot pials
            if get(handles.Rightcheckbox,'Value')
                if get(handles.Annotationcheckbox,'Value')
                    handles.ui.plot3Dhandles.surfaces(1)=mvis(handles.project.verticesR,handles.project.facesR,handles.ui.AnnotColor_R); %annotation in colors
                else
                    handles.ui.plot3Dhandles.surfaces(1)=mvis(handles.project.verticesR,handles.project.facesR); %grey
                end
                hind(1)=1;
                hold on;
            end
            if get(handles.Leftcheckbox,'Value')                
                if get(handles.Annotationcheckbox,'Value')
                    handles.ui.plot3Dhandles.surfaces(2)=mvis(handles.project.verticesL,handles.project.facesL, handles.ui.AnnotColor_L); % annotation in colors
                else
                    handles.ui.plot3Dhandles.surfaces(2)=mvis(handles.project.verticesL,handles.project.facesL);% grey    
                end
                hind(2)=1;
                hold on;
            end
        end
        if ~isempty(handles.project.vertices_SCE_R) && get(handles.RightSCEcheckbox,'Value')
%         if ~isempty(handles.project.vertices_SCE_R) && get(handles.projectSCEcheckbox,'Value') % plot projection to SCE
%             if get(handles.RightSCEcheckbox,'Value')
            handles.ui.plot3Dhandles.surfaces(3)=mvis(handles.project.vertices_SCE_R,handles.project.faces_SCE_R);
            hind(3)=1;
            hold on;
        end
        if ~isempty(handles.project.vertices_SCE_L) && get(handles.LeftSCEcheckbox,'Value')
%               if get(handles.LeftSCEcheckbox,'Value')
            handles.ui.plot3Dhandles.surfaces(4)=mvis(handles.project.vertices_SCE_L,handles.project.faces_SCE_L);
            hind(4)=1;
            hold on;
%            end
        end
        
    else %use MNI surface
        if get(handles.Rightcheckbox,'Value') %plot pials
            handles.ui.plot3Dhandles.surfaces(1)=mvis(handles.work.v_MNI,handles.work.f_MNI(handles.work.f_MNI(:,4)==1,1:3));
            hind(1)=1;
            hold on;
        end
        if get(handles.Leftcheckbox,'Value')
            handles.ui.plot3Dhandles.surfaces(2)=mvis(handles.work.v_MNI,handles.work.f_MNI(handles.work.f_MNI(:,4)==2,1:3));
            hind(2)=1;
            hold on;
        end
        
%         if get(handles.projectSCEcheckbox,'Value') % projection to SCE
        if get(handles.RightSCEcheckbox,'Value')
            handles.ui.plot3Dhandles.surfaces(3)=mvis(handles.work.v_MNI_SCE,handles.work.f_MNI_SCE(handles.work.f_MNI_SCE(:,4)==2,1:3));
            hind(3)=1;
            hold on;
        end
        if get(handles.LeftSCEcheckbox,'Value')
            handles.ui.plot3Dhandles.surfaces(4)=mvis(handles.work.v_MNI_SCE,handles.work.f_MNI_SCE(handles.work.f_MNI_SCE(:,4)==1,1:3));
            hind(4)=1;
            hold on;
        end
%         end
    end
    
    % change transparency values if there is any surface
    for i=1:length(hind);
        if hind(i)
            alpha ( handles.ui.plot3Dhandles.surfaces(i), get(handles.AlphaSlider,'Value'));
        end
    end

    handles.ui.updatePlots.surfaces=0;    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% define camera handle
[vax2(1),vax2(2)]=view(handles.axes2);

% no camlight
if ~(any(ishandle(handles.ui.plot3Dhandles.hcam)))
     handles.ui.plot3Dhandles.hcam=camlight('headlight');
%     handles.ui.plot3Dhandles.hcam(1)=camlight(-90,30); 
%     handles.ui.plot3Dhandles.hcam(2)=camlight(90,30);
%     handles.ui.plot3Dhandles.hcam(3)=camlight(0,-90);    
    handles.ui.viewPoint=vax2;

    
% camlight with diff angle
elseif any(handles.ui.viewPoint~=vax2)
    delete(handles.ui.plot3Dhandles.hcam);
     handles.ui.plot3Dhandles.hcam=camlight('headlight');
%     handles.ui.plot3Dhandles.hcam(1)=camlight(-90,30); 
%     handles.ui.plot3Dhandles.hcam(2)=camlight(90,30);
%     handles.ui.plot3Dhandles.hcam(3)=camlight(0,-90);
    handles.ui.viewPoint=vax2;        
end

handles=cross3D(handles);
handles=cross3DThres(handles);


function Reset3Dpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Reset3Dpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ui.updatePlots.GS=1;
handles.ui.updatePlots.electrodes=1;
handles.ui.updatePlots.labels=1;
handles.ui.updatePlots.elecLines=1;

handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;

handles.ui.updatePlots.surfaces=1;
handles.ui.updatePlots.cla=1;

handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%   update crosshairs in 2D and 3D view       %%%%%%%%%%%%%%%
function handles=cross2D(handles) %,updateSlice)
% Fuction to update 2D crosshairs. 
% if handles.ui.cross.xh1 .xh2 .xv1 ..... .zv1 .zv2 are valid, the coordinates
% are updated. If not valid new lines are created.
%
% This method is afecting the visual variables inside handles, but not
% updating handle structure. call guidata(hObject, handles) afterwards.



    x=round(get(handles.sliderX,'Value'));
    y=round(get(handles.sliderY,'Value'));
    z=round(get(handles.sliderZ,'Value'));
    
    D=size(handles.project.T1.img);

    % X plane
    set(handles.figure1,'CurrentAxes',handles.axesX);
    if ~ishandle(handles.ui.cross.xh1) %updateSlice(1)
        %inicialize cross handles
        %horizontal
        handles.ui.cross.xh1=line([0 y-1],[z,z],'Color',handles.ui.colors.y);
        handles.ui.cross.xh2=line([y+1 D(2)],[z,z],'Color',handles.ui.colors.y);
        % %vertical
        handles.ui.cross.xv1=line([y y],[0,z-1],'Color',handles.ui.colors.z);
        handles.ui.cross.xv2=line([y y],[z+1,D(3)],'Color',handles.ui.colors.z);
    else
        %horizontal
        set(handles.ui.cross.xh1, 'XData', [0 y-1], 'YData', [z z],'Color',handles.ui.colors.y);
        set(handles.ui.cross.xh2, 'XData', [y+1 D(2)], 'YData', [z z],'Color',handles.ui.colors.y);
        %vertical
        set(handles.ui.cross.xv1,'XData', [y y], 'YData',[0,z-1],'Color',handles.ui.colors.z);
        set(handles.ui.cross.xv2, 'XData', [y y], 'YData', [z+1,D(3)],'Color',handles.ui.colors.z);
    end
    
    % Y plane
    set(handles.figure1,'CurrentAxes',handles.axesY);
    if ~ishandle(handles.ui.cross.yh1)  %updateSlice(2)    %inicialize cross handles
        %horizontal
        handles.ui.cross.yh1=line([0 x-1],[z,z],'Color',handles.ui.colors.x);
        handles.ui.cross.yh2=line([x+1 D(1)],[z,z],'Color',handles.ui.colors.x);
        % %vertical
        handles.ui.cross.yv1=line([x x],[0,z-1],'Color',handles.ui.colors.z);
        handles.ui.cross.yv2=line([x x],[z+1,D(3)],'Color',handles.ui.colors.z);
        
    else
        %horizontal
        set(handles.ui.cross.yh1, 'XData', [0 x-1], 'YData', [z z],'Color',handles.ui.colors.x);
        set(handles.ui.cross.yh2, 'XData', [x+1 D(1)], 'YData', [z z],'Color',handles.ui.colors.x);
        %vertical
        set(handles.ui.cross.yv1,'XData', [x x], 'YData',[0,z-1],'Color',handles.ui.colors.z);
        set(handles.ui.cross.yv2, 'XData', [x x], 'YData', [z+1,D(3)],'Color',handles.ui.colors.z);
    end
    
    %Z plane
    set(handles.figure1,'CurrentAxes',handles.axesZ);
    if ~ishandle(handles.ui.cross.zh1) %updateSlice(3)
        %inicialize cross handles
        
        %horizontal
        handles.ui.cross.zh1=line([0 x-1],[y,y],'Color',handles.ui.colors.x);
        handles.ui.cross.zh2=line([x+1 D(1)],[y,y],'Color',handles.ui.colors.x);
        % %vertical
        handles.ui.cross.zv1=line([x,x],[0 y-1],'Color',handles.ui.colors.y);
        handles.ui.cross.zv2=line([x,x],[y+1 D(2)],'Color',handles.ui.colors.y);
        
    else
        %horizontal
        set(handles.ui.cross.zh1, 'XData', [0 x-1], 'YData', [y y],'Color',handles.ui.colors.x);
        set(handles.ui.cross.zh2, 'XData', [x+1 D(1)], 'YData', [y y],'Color',handles.ui.colors.x);
        %vertical
        set(handles.ui.cross.zv1,'XData', [x x], 'YData',[0,y-1],'Color',handles.ui.colors.y);
        set(handles.ui.cross.zv2, 'XData', [x x], 'YData', [y+1,D(2)],'Color',handles.ui.colors.y);
        
    end

if strcmpi( get(handles.viewCrossbutton,'state'), 'on')
        
    set(handles.ui.cross.xh1,'Visible','on');
    set(handles.ui.cross.xh2,'Visible','on');
    set(handles.ui.cross.xv1,'Visible','on');
    set(handles.ui.cross.xv2,'Visible','on');
    set(handles.ui.cross.yh1,'Visible','on');
    set(handles.ui.cross.yh2,'Visible','on');
    set(handles.ui.cross.yv1,'Visible','on');
    set(handles.ui.cross.yv2,'Visible','on');
    set(handles.ui.cross.zh1,'Visible','on');
    set(handles.ui.cross.zh2,'Visible','on');
    set(handles.ui.cross.zv1,'Visible','on');
    set(handles.ui.cross.zv2,'Visible','on');
else
    set(handles.ui.cross.xh1,'Visible','off');
    set(handles.ui.cross.xh2,'Visible','off');
    set(handles.ui.cross.xv1,'Visible','off');
    set(handles.ui.cross.xv2,'Visible','off');
    set(handles.ui.cross.yh1,'Visible','off');
    set(handles.ui.cross.yh2,'Visible','off');
    set(handles.ui.cross.yv1,'Visible','off');
    set(handles.ui.cross.yv2,'Visible','off');
    set(handles.ui.cross.zh1,'Visible','off');
    set(handles.ui.cross.zh2,'Visible','off');
    set(handles.ui.cross.zv1,'Visible','off');
    set(handles.ui.cross.zv2,'Visible','off');
    
end

function handles=cross3D(handles)%,new)
% Fuction to update 3D crosshairs. 
% if handles.ui.cross.x3D .y3D .z3D are valid, the coordinates
% are updated. If not valid new lines are created.
%
% This method is afecting the visual variables inside handles, but not
% updating handle structure. call guidata(hObject, handles) afterwards.
% inicialize cross handles
%
% OLD stuff:
% new = 1 plot new
% new = 0 update plot

if isempty(handles.project.T1)
    warning('First Load MRI image. Click New button or open existing project');
    return;
end

%plot crosshair in 3D VIEW using 2D cords
x=floor(get(handles.sliderX,'Value'));
y=floor(get(handles.sliderY,'Value'));
z=floor(get(handles.sliderZ,'Value'));

crd=mesh2AnatSpace([x,y,z],handles.project.S2);

xl=get(handles.axes2,'XLim'); 
yl=get(handles.axes2,'YLim'); 
zl=get(handles.axes2,'ZLim'); 

if ~ishandle(handles.ui.cross.x3D) %new
    axes(handles.axes2);
    handles.ui.cross.x3D=line(xl,[crd(2) crd(2)],[crd(3) crd(3)],'Color',handles.ui.colors.x);
    handles.ui.cross.y3D=line([crd(1),crd(1)],yl,[crd(3) crd(3)],'Color',handles.ui.colors.y);
    handles.ui.cross.z3D=line([crd(1),crd(1)],[crd(2) crd(2)],zl,'Color',handles.ui.colors.z);
    
else %modify
    set(handles.ui.cross.x3D, 'XData',xl, 'YData', [crd(2) crd(2)], 'ZData',[crd(3) crd(3)], 'Color',handles.ui.colors.x);
    set(handles.ui.cross.y3D, 'XData',[crd(1),crd(1)], 'YData', yl, 'ZData',[crd(3) crd(3)], 'Color',handles.ui.colors.y);
    set(handles.ui.cross.z3D, 'XData',[crd(1),crd(1)], 'YData', [crd(2) crd(2)], 'ZData',zl, 'Color',handles.ui.colors.z);    
end
    
if strcmpi( get(handles.viewCrossbutton,'state'), 'on')
        set(handles.ui.cross.x3D,'Visible','on');
        set(handles.ui.cross.y3D,'Visible','on');
        set(handles.ui.cross.z3D,'Visible','on');
   
else
        set(handles.ui.cross.x3D,'Visible','off');
        set(handles.ui.cross.y3D,'Visible','off');
        set(handles.ui.cross.z3D,'Visible','off');
        
end

function handles=cross3DThres(handles)
% Fuction to update 3D crosshairs in the 3DThres view. 
% if handles.ui.cross.x3D .y3D .z3D are valid, the coordinates
% are updated. If not valid new lines are created.
%
% This method is afecting the visual variables inside handles, but not
% updating handle structure. call guidata(hObject, handles) afterwards.
% inicialize cross handles

if isempty(handles.project.T1)
    warning('First Load MRI image. Click New button or open existing project');
    return;
end

%plot crosshair in 3D VIEW using 2D cords
x=floor(get(handles.sliderX,'Value'));
y=floor(get(handles.sliderY,'Value'));
z=floor(get(handles.sliderZ,'Value'));

crd=mesh2AnatSpace([x,y,z],handles.project.S2);

%plot crosshair in 3D Threshold using 2D cords
axes(handles.axes1);
xl=get(handles.axes1,'XLim');
yl=get(handles.axes1,'YLim');
zl=get(handles.axes1,'ZLim');

if ~ishandle(handles.ui.cross.x3DThres) %new
    handles.ui.cross.x3DThres=line(xl,[crd(2) crd(2)],[crd(3) crd(3)],'Color','r');
    handles.ui.cross.y3DThres=line([crd(1),crd(1)],yl,[crd(3) crd(3)],'Color','g');
    handles.ui.cross.z3DThres=line([crd(1),crd(1)],[crd(2) crd(2)],zl,'Color','b');
else %modify
    set(handles.ui.cross.x3DThres, 'XData',xl, 'YData', [crd(2) crd(2)], 'ZData',[crd(3) crd(3)], 'Color','r');
    set(handles.ui.cross.y3DThres, 'XData',[crd(1),crd(1)], 'YData', yl, 'ZData',[crd(3) crd(3)], 'Color','g');
    set(handles.ui.cross.z3DThres, 'XData',[crd(1),crd(1)], 'YData', [crd(2) crd(2)], 'ZData',zl, 'Color','b');
end


if strcmpi( get(handles.viewCrossbutton,'state'), 'on')
    set(handles.ui.cross.x3DThres,'Visible','on');
    set(handles.ui.cross.y3DThres,'Visible','on');
    set(handles.ui.cross.z3DThres,'Visible','on');
else
    set(handles.ui.cross.x3DThres,'Visible','off');
    set(handles.ui.cross.y3DThres,'Visible','off');
    set(handles.ui.cross.z3DThres,'Visible','off');
    
end

%--------------------------------------------------------------------
%%%%%%%%%%%%%%%           Go to Button (invisible)          %%%%%%%%%%%%%%%
function GoToButton_Callback(hObject, eventdata, handles)
% hObject    handle to GoToButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project.')
    return
end

%axes(handles.axesX);
[d1,d2]=ginput(1);

G=gca;
% X-view
% z=d2
% y=d1

if G == handles.axesX %get(handles.radiobuttonX,'Value')
    set(handles.sliderY,'Value',d1);
    set(handles.sliderZ,'Value',d2);
    
    % Y-view
    %x=d1
    %z=d2;
elseif G == handles.axesY %get(handles.radiobuttonY,'Value')
    set(handles.sliderX,'Value',d1);
    set(handles.sliderZ,'Value',d2);
    
    % Z-view
    %x=d1
    %y=d2
elseif G == handles.axesZ % get(handles.radiobuttonZ,'Value')
    set(handles.sliderX,'Value',d1);
    set(handles.sliderY,'Value',d2);
end
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%         update thresholding view            %%%%%%%%%%%%%%%
function handles=updatePlot (handles)
% This method is afecting the visual variables inside handles, but not
% updating handle structure. call guidata(hObject, handles) afterwards.
% inicialize cross handles.
% Function calls to cross3DThres

axes(handles.axes1) %makes a new axes
axis image
cla

if isempty(handles.project.TAC)
    text (0.25,0.5,'No CT image to threshold. Click Load CT button');
else
    
    % Which voxels are bright enough to be contacts, and where they are.
    % The selection itself lives in src/localization/, so it can be run and
    % checked without a figure. The settings are read off the controls into
    % work first, and taken from there.
    handles  = readLocalizationSettings(handles);
    settings = handles.work.localization;
    range    = handles.work.maxValue - handles.work.minValue;

    cfg = [];
    cfg.lowThreshold      = settings.thresholdLow  * range + handles.work.minValue;
    cfg.highThreshold     = settings.thresholdHigh * range + handles.work.minValue;
    cfg.denoiseKernel     = settings.denoiseKernel;
    cfg.maxCount          = handles.ui.options.scatter3D_elem_limit;
    cfg.excludeLocalized  = logical(get(handles.LocalizedCheckbox,'value'));
    [handles.project, handles.work] = ielec.thresholdCT(cfg, handles.project, handles.work);

    % the voxels on offer for selection are work data: the plot below shows
    % them, and the selection is made by their position in this list
    crd  = handles.work.candidateVoxels;
    vTAC = handles.work.candidateValues;

    % skip if there are no points to plot
    if ~isempty(crd)
        handles.ui.sct=scatter3(handles.axes1, crd(:,1),crd(:,2),crd(:,3),20,vTAC,'o', 'filled');
    end
    xlabel(handles.axes1,'x'); ylabel(handles.axes1,'y'); zlabel(handles.axes1,'z');
    axis(handles.axes1, 'image')
    %----------
    
    set(handles.text1,'String', round(cfg.highThreshold));
    set(handles.text2,'String', round(cfg.lowThreshold));
    
    
    % update cross in axes1 (3D Threshold)
    handles=cross3DThres(handles);
end

%--------------------------------------------------------------------
%%%%%%%%%%%%%%%          3D surfaces to plot                %%%%%%%%%%%%%%%
% --- Leftcheckbox.
function Leftcheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to Leftcheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Leftcheckbox

handles.ui.updatePlots.surfaces=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

% --- Rightcheckbox.
function Rightcheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to Rightcheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Rightcheckbox

handles.ui.updatePlots.surfaces=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

% --- LeftSCEcheckbox.
function LeftSCEcheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to LeftSCEcheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of LeftSCEcheckbox
handles.ui.updatePlots.surfaces=1;
handles=updateElectrodes3D(handles);
guidata(hObject, handles);

% --- RightSCEcheckbox.
function RightSCEcheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to RightSCEcheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of RightSCEcheckbox

handles.ui.updatePlots.surfaces=1;
handles=updateElectrodes3D(handles);
guidata(hObject, handles);

% --- PlotConnCheckbox.
function PlotConnCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to PlotConnCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.ui.updatePlots.elecLines=1;
handles.ui.updatePlots.targetLines=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

% --- DispLabelsCheckbox.
function DispLabelsCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to DispLabelsCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DispLabelsCheckbox
handles.ui.updatePlots.labels=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);


% --- Display Cortical parcellation (annotation) 
function Annotationcheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to Annotationcheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Annotationcheckbox

handles.ui.updatePlots.surfaces=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);


%--------------------------------------------------------------------
%%%%%%%%%%%%%%%            2D view sliders                  %%%%%%%%%%%%%%%
% --- sliderX
function sliderX_Callback(hObject, eventdata, handles)
% hObject    handle to sliderX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% make value integer
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);

% --- sliderY 
function sliderY_Callback(hObject, eventdata, handles)
% hObject    handle to sliderY (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% make value integer
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);

% --- sliderZ
function sliderZ_Callback(hObject, eventdata, handles)
% hObject    handle to sliderZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% make value integer
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);

%--------------------------------------------------------------------
%%%%%%%%%%%%%%%         3D view transparency slider         %%%%%%%%%%%%%%%
function AlphaSlider_Callback(hObject, eventdata, handles)
% hObject    handle to AlphaSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

handles.ui.updatePlots.surfaces=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in RotLeftpushbutton.
function RotLeftpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to RotLeftpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
camroll(handles.axes1,5);

% --- Executes on button press in RotRightpushbutton.
function RotRightpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to RotRightpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
camroll(handles.axes1,-5);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%            2D VIEWS                         %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%         visualzation window                 %%%%%%%%%%%%%%%
% --- MinWinslider
function MinWinslider_Callback(hObject, eventdata, handles)
% hObject    handle to MinWinslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
if get(handles.MinWinslider,'Value') > get(handles.MaxWinslider,'Value')
    set(handles.MinWinslider,'Value',get(handles.MaxWinslider,'Value')-1e-10); %need to be diferent values
end

handles=updateMix_TAC_MR(handles);
handles.ui.updatePlots.views2D=[1 1 1];
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);

% --- MaxWinslider
function MaxWinslider_Callback(hObject, eventdata, handles)
% hObject    handle to MaxWinslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
if get(handles.MinWinslider,'Value') > get(handles.MaxWinslider,'Value')
    set(handles.MaxWinslider,'Value',get(handles.MinWinslider,'Value')+1e-10); %need to be diferent values
end

handles=updateMix_TAC_MR(handles);

handles.ui.updatePlots.views2D=[1 1 1];
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);

%--------------------------------------------------------------------
%%%%%%%%%%%%%%%               MRI-CT mixture                %%%%%%%%%%%%%%%
function TAC_MRIslider_Callback(hObject, eventdata, handles)
% hObject    handle to TAC_MRIslider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

handles=updateMix_TAC_MR(handles);
handles=updateTAC(handles);
% Update handles structure
guidata(hObject, handles);

function handles=updateMix_TAC_MR(handles)
% Updates the content of handles.ui.imgW based on the available images and
% color options options. Should call for updateTAC after

opt.colorT1=handles.ui.colors.colorT1; %from defaultGuiVariables
opt.colorCT=handles.ui.colors.colorCT; %from defaultGuiVariables
opt.edgeCTchannels=handles.ui.colors.edgeCTchannels;
opt.percentileThres=handles.ui.colors.percentileThres;
opt.edgeCT=get(handles.edgeCheckbox,'Value'); %edgeCT
opt.win=[get(handles.MinWinslider,'Value') get(handles.MaxWinslider,'Value')];
mixValue=get(handles.TAC_MRIslider,'Value');

if ~isempty(handles.project.T1)
    
    T1=single(handles.project.T1.img);
% normalized T1 in int16 format - mixImages has to be fixed to work with
% int16
%     T1=int16(handles.project.T1.img);
%     T1=T1-min(T1(:));
%     T1=T1 * ( (2^15-1) / max(T1(:)));
        
    if isempty(handles.project.TAC)
        %only MRI
       handles.ui.imgW=ielview.mixImages(T1,[],mixValue,opt);
    else
        %MRI and CT mixture
        TAC=single(handles.project.TAC.img);
        % normalized T1 in int16 format
%         TAC=int16(handles.project.TAC.img);
%         TAC=TAC-min(TAC(:));
%         TAC=TAC * ( (2^15-1) / max(TAC(:)));

        handles.ui.imgW=ielview.mixImages(T1,TAC,mixValue,opt);

    end
    handles.ui.updatePlots.views2D=[1 1 1];
end

%--------------------------------------------------------------------
%%%%%%%%%%%%%%%             overlays                       %%%%%%%%%%%%%%%
% --- Electrodes Overlay
function ElecOverlaycheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to ElecOverlaycheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ElecOverlaycheckbox
handles.ui.updatePlots.views2D=[1 1 1]; %Force update all slices
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);

% --- planning Overlay
function planningOverlaycheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to planningOverlaycheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of planningOverlaycheckbox
handles.ui.updatePlots.views2D=[1 1 1]; %Force update all slices
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);

% --- Collapse 
function Collapsecheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to Collapsecheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Collapsecheckbox
handles.ui.updatePlots.views2D=[1 1 1]; %Force update all slices
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);

% --- Parcellation atlas
function parcellationCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to parcellationCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of parcellationCheckbox

handles.ui.updatePlots.views2D=[1 1 1];
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);

% --- Edge CT
function edgeCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to edgeCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of edgeCheckbox

handles=updateMix_TAC_MR(handles);
handles.ui.updatePlots.views2D=[1 1 1];
handles=updateTAC(handles);
% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%             CLUSTERING                      %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%    Thresholding / Denoise Sliders           %%%%%%%%%%%%%%%
% --- sliderThrMax
function sliderThrMax_Callback(hObject, eventdata, handles)
% hObject    handle to sliderThrMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

handles=updatePlot(handles);

% Update handles structure
guidata(hObject, handles);


% --- sliderThrMin
function sliderThrMin_Callback(hObject, eventdata, handles)
% hObject    handle to sliderThrMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% --- Executes during object creation, after setting all properties.

handles=updatePlot(handles);

% Update handles structure
guidata(hObject, handles);

% --- Denoise
function denoiseSlider_Callback(hObject, eventdata, handles)
% hObject    handle to denoiseSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

handles=updatePlot(handles);

% Update handles structure
guidata(hObject, handles);


% --- Already localized voxels
function LocalizedCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to LocalizedCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of LocalizedCheckbox

handles=updatePlot(handles);

% Update handles structure
guidata(hObject, handles);


%--------------------------------------------------------------------
%%%%%%%%%%%%%%%           Erode - Dilate                    %%%%%%%%%%%%%%%
% --- Dilate
function ImgDilatePushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to ImgDilatePushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isempty(handles.project.mask)
    warning('Mask image not present');
    return;
else
    handles.project.mask.img=imdilate( handles.project.mask.img, ones(3,3,3));
    handles=updatePlot(handles);
end

% Update handles structure
guidata(hObject, handles);

% --- Erode
function ImgErodePushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to ImgErodePushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isempty(handles.project.mask)
    warning('Mask image not present');
    return;
else
    handles.project.mask.img=imerode( handles.project.mask.img, ones(3,3,3));
    handles=updatePlot(handles);
end

% Update handles structure
guidata(hObject, handles);

%--------------------------------------------------------------------
%%%%%%%%%%%%%%%             Brushing                       %%%%%%%%%%%%%%%
% --- Select Voxels
function SelectVoxelspushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to SelectVoxelspushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
brushObj=brush;
set(brushObj,'Enable','on');
handles.ui.brushObj=brushObj;


% Update handles structure
guidata(hObject, handles);

%--------------------------------------------------------------------
%%%%%%%%%%%%%%%        Clustering / Fitting                 %%%%%%%%%%%%%%%
% --- ClusterButton.
function ClusterButton_Callback(hObject, eventdata, handles)
% hObject    handle to ClusterButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% which voxels the user selected in the 3-D view
brushedIdx = brushedVoxelIndices(handles);

if isempty(brushedIdx)
    disp('You must select some voxels first');
    return;
end

[handles.project, handles.work] = ...
    ielec.selectVoxels(struct('indices', brushedIdx), handles.project, handles.work);

handles = readLocalizationSettings(handles);
nClus   = handles.work.localization.nClusters;

[handles.project, handles.work, quality] = ...
    ielec.cluster(struct('nClusters', nClus), handles.project, handles.work);

% report how regular the spacing came out. The numbers are computed in
% clusterContacts; the wording belongs here.
disp([num2str(nClus) ' electrodes localized' ])
disp(['Mean Inter-Electrode Distance: ' num2str(quality.meanDistance,2) ' mm'])
disp(['MAD Inter-Electrode Distance: ' num2str(quality.madDistance,2) ' mm'])

if quality.suspect
    disp( [ num2str(quality.nOutliers) ' outliers observed. ' num2str(quality.nLargeChange) ' show > 20% change in IED.' ])
    disp('Possible localization error. Check your results visually.');     
    disp('If the solution is not optimal, try to split the voxels into smaller groups and rerun clustering');
    disp('If that doesn''t work, use GridFit algorithm instead.');
end


set(handles.nClusText,'string',num2str(size(handles.work.GS,1)));

handles.ui.updatePlots.GS=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);


% --- Fit grid
function Fitpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Fitpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% which voxels the user selected in the 3-D view
brushedIdx = brushedVoxelIndices(handles);

if isempty(brushedIdx)
    disp('You must select some voxels first');
    return;
end

[handles.project, handles.work] = ...
    ielec.selectVoxels(struct('indices', brushedIdx), handles.project, handles.work);

fixM1_BF = [];   % only a depth electrode asks for it

type = questdlg('What type of electrode array do you want to fit?', ...
	'Array', ...
	'depth','strip','grid','grid');


% Handle response
switch type
    case 'grid'
        set(handles.GridButton,'value',true);        
        prompt = {'Rows:','Columns:','Interelectrode distance[mm]:','Overlap (0/1):'};
        dlg_title = 'Fit grid to selected voxels';
        dimText = inputdlg(prompt,dlg_title);
        
        if isempty(dimText)
            return;
        else
            rows = str2num(dimText{1});  %rows
            cols = str2num(dimText{2});  %cols
            fixM1 = str2num(dimText{3}); %inter-electrode distance
            overlap = str2num(dimText{4}); %overlap 0/1
        end
        
    case 'strip'
        set(handles.GridButton,'value',true);        
        prompt = {'Number of electrodes:','Interelectrode distance [mm]:','Overlap (0/1):'};
        dlg_title = 'Fit strip to selected voxels';
        dimText = inputdlg(prompt,dlg_title);
        
        if isempty(dimText)
            return;
        else
            rows = 1;  %rows
            cols = str2num(dimText{1});  %cols
            fixM1 = str2num(dimText{2}); %inter-electrode distance
            overlap = str2num(dimText{3}); %overlap 0/1
        end
        
    case 'depth'
        set(handles.DepthButton,'value',true);
        prompt = {'Number of electrodes:','Interelectrode distance 1st-2nd [mm]:','Interelectrode distance 2nd-end [mm]:'};
        dlg_title = 'Fit depth to selected voxels';
        dimText = inputdlg(prompt,dlg_title);
        
        if isempty(dimText)
            return;
        else
            rows = 1;
            cols     = str2num(dimText{1});
            fixM1_BF = str2num(dimText{2}); % distance between 1st-2nd elec used for Behnke Fried electrodes
            fixM1    = str2num(dimText{3});
        end  
        overlap=0; % no overlap defined for depth
       
    otherwise
        return;
end


%check if there are some "Nailed electrodes" as previously selected (GS)
%coordinates
if ~isempty(handles.work.GS)
    handles.work.uitable_elecNum = [];

    %use GS coordinates as Nailed. The table asks which contact each of them
    %is; ielec.fitArray takes the coordinates from work.GS and empties it.
    guidata(hObject, handles);     % % Update content in handles structure
    electrodeNailNaumber_uitable (hObject, handles,rows*cols); %use graphical interface. This will change content in handles.
    handles = guidata(hObject); % retrive updated data
    
    nailNumbers = handles.work.uitable_elecNum;
    
%     if strcmp(options.constrain_type,'volume_distance') & length(options.NailElectrodeNumber)>1
%         warning('using more than 1 nailed coordinate with volume_distance constrain might not converge. Changing constrain to distance.')
%         options.constrain_type = 'distance';
%     end
        
else
    nailNumbers = [];
end

cfg = [];
cfg.type               = type;
cfg.rows               = rows;
cfg.columns            = cols;
cfg.spacing            = fixM1;
cfg.firstSecondSpacing = fixM1_BF;
cfg.overlap            = overlap;
cfg.useNailedContacts  = ~isempty(handles.work.GS);
cfg.nailNumbers        = nailNumbers;

disp('/// Starting grid/depth fitting algorithm. This may take some minutes depending on the grid size.')
disp(['Fitting a grid/depth of dimensions: ' num2str(rows) ' x ' num2str(cols) ' and inter-electrode distance : ' num2str(fixM1) ])
tic;

[handles.project, handles.work, electrodes] = ...
    ielec.fitArray(cfg, handles.project, handles.work);
disp(['GridFit algorithm finished in ' num2str(toc) ' seconds']);

if cfg.useNailedContacts
    % the nailed contacts were consumed by the fit
    set(handles.nClusText,'string',num2str(size(handles.work.GS,1)));
    handles.ui.updatePlots.GS=1;
end


% add new electrode to handles
handles = addElectrode2structure(handles,electrodes,[]);

% % Update handles structure
guidata(hObject, handles);


function handles = readLocalizationSettings(handles)
% The scientific settings of the Localize panel, read off its controls into
% handles.work.localization at the moment they are about to be used.
%
% The controls are where the user types them; work is where the calculation
% takes them from, so what was used is on record in work rather than only in
% the controls. The same values are read, with the same conversions, as the
% code that read the controls directly did.
%
% They are not written to the .iel: CHECKPROJECTSTRUCTURE writes a fixed set
% of fields, and work.localization is not one of them. Whether the settings
% should be saved with the project is docs/OPEN_QUESTIONS.md item 18.
settings.thresholdLow  = get(handles.sliderThrMin,'Value');               % fraction of the CT range
settings.thresholdHigh = get(handles.sliderThrMax,'Value');               % fraction of the CT range
settings.denoiseKernel = round(get(handles.denoiseSlider, 'value'));      % voxels; 1 = off
settings.nClusters     = str2double(get(handles.clusNElecEdit,'String')); % contacts to cluster into
settings.rows          = str2double(get(handles.rowsEdit,'string'));      % grid rows, for Index
settings.columns       = str2double(get(handles.colsEdit,'string'));      % grid columns, for Index
handles.work.localization = settings;


%--------------------------------------------------------------------
function brushedIdx = brushedVoxelIndices(handles)
% Which of the voxels on offer the user brushed in the 3-D view, as a
% logical array over handles.work.candidateVoxels. Empty when none are
% selected, after a warning saying so.
%
% Reading the brush is the one thing only the figure can do, so it stays
% here; everything after it works from work.candidateVoxels.
%
% The branch for MATLAB R2014a and earlier is gone: it read the coordinates
% out of the brushed line instead of the selection, which cannot give
% positions in the list, and the oldest release v2 supports is far newer
% (docs/OPEN_QUESTIONS.md item 6).

brushedIdx = [];

if isempty(handles.ui.sct)
    warning ('There are no points selected to be clustered');
    return;
end

brushed = logical(handles.ui.sct.BrushData);   % one flag per plotted point
if isempty(brushed) || ~any(brushed)
    warning ('There are no points selected to be clustered');
    return;
end

if numel(brushed) ~= size(handles.work.candidateVoxels, 1)
    % cannot happen while the plot and work.candidateVoxels are made
    % together in updatePlot; if they ever disagree, refuse rather than
    % take the wrong voxels
    warning ('The selection does not match the voxels shown. Select the voxels again.');
    return;
end

brushedIdx = brushed;

%--------------------------------------------------------------------
%%%%%%%%%%%%%%%        Manually add coordinates             %%%%%%%%%%%%%%%
% --- AddCoordinateButton.
function AddCoordinateButton_Callback(hObject, eventdata, handles)
% hObject    handle to AddCoordinateButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% get sliders values
if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project.')
    return
end

x=floor(get(handles.sliderX,'Value'));
y=floor(get(handles.sliderY,'Value'));
z=floor(get(handles.sliderZ,'Value'));

crd=[x y z];
crd=mesh2AnatSpace(crd,handles.project.S2);

if ~isempty(handles.project.TAC)
    weight=handles.project.TAC.img(x,y,z)-min(handles.project.TAC.img(:));
else
    weight=0; % force to zero if CT not present
end
        
% save old GS
handles.work.oldGS=handles.work.GS;
handles.work.oldbrushCrd=handles.work.brushCrd;
handles.work.oldbrushWeight=handles.work.brushWeight;
handles.work.oldclusters=handles.work.clusters;

handles.work.GS=[handles.work.GS; crd];
handles.work.brushCrd=[handles.work.brushCrd; crd];
handles.work.clusters=[handles.work.clusters; (length(unique(handles.work.clusters))+1)];
handles.work.brushWeight=[handles.work.brushWeight; weight];
set(handles.nClusText,'string',num2str(size(handles.work.GS,1)));

handles.ui.updatePlots.GS=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);


%%%%%%%%%%%%%%%     Manually delete coordinates             %%%%%%%%%%%%%%%
% --- DelCoordinateButton.
function DelCoordinateButton_Callback(hObject, eventdata, handles)
% hObject    handle to DelCoordinateButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project.')
    return
end

x=floor(get(handles.sliderX,'Value'));
y=floor(get(handles.sliderY,'Value'));
z=floor(get(handles.sliderZ,'Value'));

crd=[x y z];
crd=mesh2AnatSpace(crd,handles.project.S2);

%search for closest coordinate 
dist=eucDistMat(handles.work.GS,crd);
[m,ind]=min(dist);

if m<2 %2mm
    % save old GS
    handles.work.oldGS=handles.work.GS;
    handles.work.oldbrushCrd=handles.work.brushCrd;
    handles.work.oldbrushWeight=handles.work.brushWeight;
    handles.work.oldclusters=handles.work.clusters;
    
    %remove coordinate from GS
    handles.work.GS(ind,:)=[];
    
    indClus=find(handles.work.clusters==ind); %actual cluster
    indBigClus=find(handles.work.clusters>ind); %clusters of bigger index
    
    handles.work.clusters(indBigClus,:)= handles.work.clusters(indBigClus,:)-1; %decrease the clus num
    handles.work.clusters(indClus,:)=[]; % remove cluster elements 
        
    handles.work.brushCrd(indClus,:)=[]; %remove brush coords
    handles.work.brushWeight(indClus,:)=[]; %remove brushweight
    
    set(handles.nClusText,'string',num2str(size(handles.work.GS,1)));
    
    handles.ui.updatePlots.GS=1;
    handles=updateElectrodes3D(handles);
    
    % Update handles structure
    guidata(hObject, handles);

else
    warning('No electrodes in the proximity (2mm) to be deleted')
end

%%%%%%%%%%%%%%%   Clear Coordinates in case of error        %%%%%%%%%%%%%%%
% --- ClearAllButton.
function ClearAllButton_Callback(hObject, eventdata, handles)
% hObject    handle to ClearAllButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project.')
    return
end

% save old GS
handles.work.oldGS=handles.work.GS;
handles.work.oldbrushCrd=handles.work.brushCrd;
handles.work.oldbrushWeight=handles.work.brushWeight;
handles.work.oldclusters=handles.work.clusters;

handles.work.GS=[];
handles.work.brushCrd=[];
handles.work.brushWeight=[];
handles.work.clusters=[];
set(handles.nClusText,'string',num2str(size(handles.work.GS,1)));

handles.ui.updatePlots.electrodes=1;
handles.ui.updatePlots.labels=1;
handles.ui.updatePlots.elecLines=1;
handles.ui.updatePlots.GS=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);


% --- Removed // ClearLastButton.
function ClearLastButton_Callback(hObject, eventdata, handles)
% % hObject    handle to ClearLastButton (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% if isempty(handles.project.T1)
%     warning ('First Load MRI image. Click New button or open existing project.')
%     return
% end
% 
% handles.work.oldGS=handles.work.GS;
% handles.work.GS(end,:)=[];
% set(handles.nClusText,'string',num2str(size(handles.work.GS,1)));
%
% handles.ui.updatePlots.GS=1;
% handles=updateElectrodes3D(handles);
% 
% % Update handles structure
% guidata(hObject, handles);
% 

% --- Undo 
function Recpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Recpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%recover GS, brushCrd, and brushWeight from old  

tempGS=handles.work.GS;
handles.work.GS=handles.work.oldGS;
handles.work.oldGS=tempGS;

tempbrushCrd=handles.work.brushCrd;
handles.work.brushCrd=handles.work.oldbrushCrd;
handles.work.oldbrushCrd=tempbrushCrd;

tempbrushWeight=handles.work.brushWeight;
handles.work.brushWeight=handles.work.oldbrushWeight;
handles.work.oldbrushWeight=tempbrushWeight;

tempclusters=handles.work.clusters;
handles.work.clusters=handles.work.oldclusters;
handles.work.oldclusters=tempclusters;

set(handles.nClusText,'string',num2str(size(handles.work.GS,1)));

handles.ui.updatePlots.GS=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%             LABELING                        %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%   Change grid or depth electrode labeling   %%%%%%%%%%%%%%%
% --- Executes when selected object is changed in arrayUipanel.
function arrayUipanel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in arrayUipanel
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

if get(handles.DepthButton,'Value') % deepth electrode selected
    set(handles.text19,'Visible','off');
    set(handles.text20,'Visible','off');
    
    set(handles.rowsEdit,'Visible','off');
    set(handles.colsEdit,'Visible','off');
    
    set(handles.rLpushbutton,'Visible','off');
    set(handles.rRpushbutton,'Visible','off');
    set(handles.fLRpushbutton,'Visible','off');
    set(handles.fUDpushbutton,'Visible','off');
    
    set(handles.FlipLabelsPushbutton,'Visible','on');
    
else  %grid selected
    
    set(handles.text19,'Visible','on');
    set(handles.text20,'Visible','on');
    
    set(handles.rowsEdit,'Visible','on');
    set(handles.colsEdit,'Visible','on');
    
    set(handles.rLpushbutton,'Visible','on');
    set(handles.rRpushbutton,'Visible','on');
    set(handles.fLRpushbutton,'Visible','on');
    set(handles.fUDpushbutton,'Visible','on');
    
    set(handles.FlipLabelsPushbutton,'Visible','off');
    
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%                Indexing                     %%%%%%%%%%%%%%%
% --- Executes on button press in Indexpushbutton.
function Indexpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Indexpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Number the contacts of an array. Which array: the one on show when there
% are no contacts in progress, the contacts in progress otherwise - the same
% two cases as before, now told apart by cfg.index.
cfg = [];
if get(handles.DepthButton,'value')
    cfg.shape = 'depth';
elseif get(handles.GridButton,'value')
    handles     = readLocalizationSettings(handles);
    cfg.shape   = 'grid';
    cfg.rows    = handles.work.localization.rows;
    cfg.columns = handles.work.localization.columns;
end

if isempty(handles.work.GS)
    cfg.index = selectedArray(handles);   % number that array again
    thisArray = cfg.index;
else
    thisArray = [];                       % a new array, appended at the end
end

[handles.project, handles.work, array] = ...
    ielec.indexArray(cfg, handles.project, handles.work);

% an array that was numbered again replaces itself; a new one is appended
handles = addElectrode2structure(handles, array, thisArray);

% Update handles structure
guidata(hObject, handles);

function handles = addElectrode2structure(handles,electrodes,array)
% Add electrodes to handles.project.electrodes 
% if arrray is empty, make a new electrode cell at the endl
% Otherwise, replce electrode

% append when ARRAY is empty, overwrite that index otherwise. Adding a new
% array also finishes the localization it came from, so the contacts in
% progress are cleared - the layer does both.
[handles.project, handles.work, l] = ...
    ielec.acceptArray(struct('index', array), handles.project, handles.work, electrodes);

% process projections if needed
handles=processProjections(handles);

% anatomical labeling (electrodes and projections)
if strcmp(handles.project.currentSpace,'MNI'); % options are 'Native' 'MNI'        %strcmp (get(handles.MNILabelstogglebutton,'state'),'on')
    handles=labels2MNIspace(handles);
else
    handles=labels2NativeSpace(handles);
end
    
if isempty(array) % a new array: the contacts in progress are gone
    set(handles.nClusText,'string',num2str(size(handles.work.GS,1)));
end

%set visualization to this electrode
handles = setSelectedArray(handles, l);
handles = setSelectedContact(handles, 1);
set(handles.editArrayName,'String',handles.project.electrodes{l}.Name);
set(handles.editElecLabels,'string',handles.project.electrodes{l}.ch_label{1});

% go to first electrode coordinate for checking
d1=handles.project.electrodes{l}.x(1);
d2=handles.project.electrodes{l}.y(1);
d3=handles.project.electrodes{l}.z(1);

D=AnatSpace2Mesh([d1 d2 d3],handles.project.S2);
set(handles.sliderX,'Value',D(1));
set(handles.sliderY,'Value',D(2));
set(handles.sliderZ,'Value',D(3));

handles.ui.updatePlots.GS=1;
handles.ui.updatePlots.electrodes=1;
handles.ui.updatePlots.labels=1;
handles.ui.updatePlots.elecLines=1;

handles=updateElectrodes3D(handles);
handles=updateTAC(handles);

%--------------------------------------------------------------------
%%%%%%%%%%%%%%%   grid Indexing/labeling modifications      %%%%%%%%%%%%%%%

% --- Executes on button press in rLpushbutton.
function rLpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to rLpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.project.electrodes)
    warning('Electrodes is empty. First cluster some electrodes');
    return;
end

a=selectedArray(handles);

electrodes=handles.project.electrodes{a};
if electrodes.rows ~= electrodes.columns
    warning('rows ~= columns');

else
    cfg = [];
    cfg.index  = a;
    cfg.change = 'rotateLeft';
    [handles.project, handles.work] = ...
        ielec.reorderArray(cfg, handles.project, handles.work);

    handles.ui.updatePlots.labels=1;
    handles=updateElectrodes3D(handles);

end

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in rRpushbutton.
function rRpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to rRpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isempty(handles.project.electrodes)
    warning('Electrodes is empty. First cluster some electrodes');
    return;
end

a=selectedArray(handles);

electrodes=handles.project.electrodes{a};
if electrodes.rows ~= electrodes.columns
    warning('rows ~= columns');
else

    cfg = [];
    cfg.index  = a;
    cfg.change = 'rotateRight';
    [handles.project, handles.work] = ...
        ielec.reorderArray(cfg, handles.project, handles.work);

    handles.ui.updatePlots.labels=1;
    handles=updateElectrodes3D(handles);
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in fLRpushbutton.
function fLRpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to fLRpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isempty(handles.project.electrodes)
    warning('Electrodes is empty. First cluster some electrodes');
    return;
end

a=selectedArray(handles);

cfg = [];
cfg.index  = a;
cfg.change = 'flipLeftRight';
[handles.project, handles.work] = ...
    ielec.reorderArray(cfg, handles.project, handles.work);

handles.ui.updatePlots.labels=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in fUDpushbutton.
function fUDpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to fUDpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isempty(handles.project.electrodes)
    warning('Electrodes is empty. First cluster some electrodes');
    return;
end

a=selectedArray(handles);

cfg = [];
cfg.index  = a;
cfg.change = 'flipUpDown';
[handles.project, handles.work] = ...
    ielec.reorderArray(cfg, handles.project, handles.work);

handles.ui.updatePlots.labels=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

%--------------------------------------------------------------------
%%%%%%%%%%%%%     flip depth electrodes Index/labels        %%%%%%%%%%%%%%%
% --- Executes on button press in FlipLabelsPushbutton.
function FlipLabelsPushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to FlipLabelsPushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
a=selectedArray(handles);


if a==0
    warning('Electrodes is empty. First cluster some electrodes');
    return;
end
% one line of contacts, and only its direction can be wrong
cfg = [];
cfg.index  = a;
cfg.change = 'reverse';
[handles.project, handles.work] = ...
    ielec.reorderArray(cfg, handles.project, handles.work);

handles.ui.updatePlots.labels=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);


%--------------------------------------------------------------------
%%%%%%%%%%%%%     Manual indexing electrodes        %%%%%%%%%%%%%%%
% --- Manual Index pushbutton.
function manualIndexpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to manualIndexpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.project.electrodes)
    warning('Electrodes is empty. First cluster some electrodes');
    return;
end

a=selectedArray(handles);

electrodes=handles.project.electrodes{a};

[newOrder, chLabelsOut]=movelist(electrodes.ch_label);

if all(strcmp(chLabelsOut, electrodes.ch_label)) %all channels the same
    return;
end

% the window dragged the list into a new order; the layer is given that
cfg = [];
cfg.index  = a;
cfg.change = 'order';
cfg.order  = newOrder(:);
[handles.project, handles.work] = ...
    ielec.reorderArray(cfg, handles.project, handles.work);

handles.ui.updatePlots.electrodes=1;
handles.ui.updatePlots.labels=1;
handles.ui.updatePlots.elecLines=1;

handles=updateElectrodes3D(handles);


% Update handles structure
guidata(hObject, handles);


%--------------------------------------------------------------------
%%%%%%%%%%%%%     Label electrodes using base name          %%%%%%%%%%%%%%%
% --- Executes on button press in LabelAutoPushbutton.
function LabelAutoPushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to LabelAutoPushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% works over the current electrode array
if isempty(handles.project.electrodes)
    warning('Electrodes is empty. First index some electrodes');
    return;
end
l=selectedArray(handles);
elecBaseName=get(handles.labelEdit, 'String');

% the box holds the name; the numbering from it is the layer's
cfg = [];
cfg.index    = l;
cfg.baseName = elecBaseName;
[handles.project, handles.work] = ...
    ielec.nameContacts(cfg, handles.project, handles.work);

handles = setSelectedContact(handles, 1);
set(handles.editArrayName,'String', handles.project.electrodes{l}.Name);
set(handles.editElecLabels,'string', handles.project.electrodes{l}.ch_label{1});

handles.ui.updatePlots.labels=1;
handles=updateElectrodes3D(handles);
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%     Label electrodes from list                %%%%%%%%%%%%%%%
% --- Executes on button press in LabelListPushbutton.
function LabelListPushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to LabelListPushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.project.electrodes)
    warning('Electrodes is empty. First cluster some electrodes');
    return;
end
% works over the current electrode array
l=selectedArray(handles);
N=handles.project.electrodes{l}.nElectrodes;
elecBaseName=get(handles.labelEdit, 'String');

%get labels from file
if isempty(handles.project.elecListLabels)
    handles = loadLabelList(handles);
    temp = handles.project.elecListLabels;
    
%     temp={
%         'a1' 'b1' 'c1' 'd1' 'e1' 'f1' 'g1' 'h1'...
%         'a2' 'b2' 'c2' 'd2' 'e2' 'f2' 'g2' 'h2'...
%         'a3' 'b3' 'c3' 'd3' 'e3' 'f3' 'g3' 'h3'...
%         'a4' 'b4' 'c4' 'd4' 'e4' 'f4' 'g4' 'h4'...
%         'a5' 'b5' 'c5' 'd5' 'e5' 'f5' 'g5' 'h5'...
%         'a6' 'b6' 'c6' 'd6' 'e6' 'f6' 'g6' 'h6'...
%         'a7' 'b7' 'c7' 'd7' 'e7' 'f7' 'g7' 'h7'...
%         'a8' 'b8' 'c8' 'd8' 'e8' 'f8' 'g8' 'h8'...
%         'a9' 'b9' 'c9' 'd9' 'e9' 'f9' 'g9' 'h9'};
    
    if isempty(temp)
        return;
    end
    handles.project.elecListLabels=temp;
else
    % add option to go again into electrodes list
    choice = questdlg('Do you want to load new labels from file?', ...
        '', 'Yes','No','Cancel','No');
    % Handle response
    switch choice
        case 'Yes'
            handles = loadLabelList(handles);
            if isempty(handles.project.elecListLabels)
                return;
            end
        case 'No'
            % do nothing
        case 'Cancel'
            return;
        case ''
            return;
    end
end

left=handles.project.elecListLabels;
right=handles.project.electrodes{l}.ch_label;

while true
    [right,left]=addremovelist(...
        'LeftContents',left,...
        'RightContents',right,...
        'ListNames',{'Available Labels' 'Array Labels'},'KeepSorted',false,...
        'Title',['Select ' int2str(N) ' labels for curret array']);
    
    if length(right)==N    % check number of selected electrodes
        break;
    elseif isempty(right)  % no changes (Accept button)
        return;
    else
        disp(['Select ' int2str(N) ' electrodes'])
    end
    
end

handles.project.elecListLabels=left;

% Same boundary as the Auto button: the dialogs above chose the labels, and
% the layer is given them
cfg = [];
cfg.index    = l;
cfg.baseName = elecBaseName;
cfg.labels   = right;
[handles.project, handles.work] = ...
    ielec.nameContacts(cfg, handles.project, handles.work);

set(handles.editArrayName,'String',handles.project.electrodes{l}.Name);
handles = setSelectedContact(handles, 1);
set(handles.editElecLabels,'string', handles.project.electrodes{l}.ch_label{1});

handles.ui.updatePlots.labels=1;
handles=updateElectrodes3D(handles);
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);

function handles = loadLabelList(handles)
% Ask for a file of contact labels and let the layer read it. The five
% formats are the five filters of this dialog; which one the user picked is
% what filterindex says, and the layer is told by name.
formats = {'txt', 'matlab', 'eeglab', 'fieldtripHeader', 'edf'};

[labelsFile,PathName,filterindex]=uigetfile({
    '*.txt', 'Text files (Tab delimited) (*.txt)'; ...         % 1
    '*.mat', 'MATLAB files (labels Cell array) (*.mat)'; ...   % 2
    '*.set', 'EEGLAB set files (*.set)';...                    % 3
    '*.mat', 'Fieltrip hdr files (*.mat)';...                  % 4
    '*.edf', 'edf files (*.edf)'},...                          % 5
    'Load labels from file',handles.work.PathName);

if ~ischar(labelsFile) || filterindex > numel(formats)
    return   % cancelled, or a filter that names no format
end

cfg = [];
cfg.file   = [PathName labelsFile];
cfg.format = formats{filterindex};
[handles.project, handles.work] = ielec.importLabels(cfg, handles.project, handles.work);

%--------------------------------------------------------------------
%%%%%%%%%%%%%%%    Project electrodes to SCE  %%%%%%%%%%%%%%%
% --- Executes on button press in projectSCEcheckbox.
function projectSCEcheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to projectSCEcheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of projectSCEcheckbox

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TODO: add atlas and compatibility with native space surfaces

% global debugging
% debugging=1;

if isempty(handles.project.electrodes)
    warning('Electrodes is empty. First cluster some electrodes');
    return;
end

handles=processProjections(handles);

handles.ui.updatePlots.electrodes=1;
handles.ui.updatePlots.labels=1;
handles.ui.updatePlots.elecLines=1;
handles.ui.updatePlots.surfaces=1;

handles=updateElectrodes3D(handles);
handles.ui.updatePlots.views2D=[1 1 1];
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);


function handles=processProjections(handles)

if ~get(handles.projectSCEcheckbox,'Value')   % the box is off: nothing to do
    return
end

% What the layer knows about the projection; the questions are ours.
[handles.project, handles.work, state] = ...
    ielec.projectionState([], handles.project, handles.work);

if ~state.anyProjectable
    warning('It is not posible to project electrodes to SCE. No grids localized yet. Please localize grids first.');
    set(handles.projectSCEcheckbox,'Value',0);
    return;
end

% Deal with previous projections
cfg = [];
cfg.recalculateAll = false;
if any(state.alreadyDone) %some projections were done before
    % Do you want to recalculate all?
    choice = questdlg('Do you want to recalculate all projections?', ...
        '', 'Yes, all','No, only the new one(s)','No, only the new one(s)');
    % Handle response
    switch choice
        case 'Yes, all'
            cfg.recalculateAll = true; % put all to cero and recalculate
        case 'No, only the new one(s)'
            % do nothing
        case '' % close the dialog box
            set(handles.projectSCEcheckbox,'Value',0);
            return;
    end
end

% Do the projections
if state.allDone && ~cfg.recalculateAll
    return
end

if ~state.surfaceAvailable && ~strcmp(handles.project.currentSpace,'MNI')
    % Native space, and this patient has no smooth cortical envelope yet.
    % The MNI branch has never had this check - its surface is a template
    % that ships with the toolbox - and it is left without one.
    warning('First you need to load or generate a smooth cortical envelope. Use the toolbar button for that purpose')
    set(handles.projectSCEcheckbox,'Value',0);
else
    [handles.project, handles.work] = ...
        ielec.projectArrays(cfg, handles.project, handles.work);
end

% anatomical labeling (electrodes and projections)
% Reached even when the warning above fired, as it always has been.
if strcmp(handles.project.currentSpace,'MNI') % options are 'Native' 'MNI'
    handles=labels2MNIspace(handles);
else
    handles=labels2NativeSpace(handles);
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%             NAVIGATE ELECTRODES             %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%          edit array name                %%%%%%%%%%%%%%%
function editArrayName_Callback(hObject, eventdata, handles)
% hObject    handle to editArrayName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editArrayName as text
%        str2double(get(hObject,'String')) returns contents of editArrayName as a double
if isempty(handles.project.electrodes)
    warning('Electrodes is empty. First cluster some electrodes');
    return;
end

str=get(handles.editArrayName,'String');
a=selectedArray(handles);

handles.project.electrodes{a}.Name=str;

% Electrode labels and Array are independent now
% N=handles.project.electrodes{a}.nElectrodes;
% 
% for i=1:N
%     handles.project.electrodes{a}.ch_label{i}=[str int2str(i)];
% end

handles.ui.updatePlots.labels=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);


%%%%%%%%%%%%%%%          edit electrode name                %%%%%%%%%%%%%%%
function editElecLabels_Callback(hObject, eventdata, handles)
% hObject    handle to editElecLabels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editElecLabels as text
%        str2double(get(hObject,'String')) returns contents of editElecLabels as a double

if isempty(handles.project.electrodes)
    warning('Electrodes is empty. First cluster some electrodes');
    return;
end

str=get(handles.editElecLabels,'String');
a=selectedContact(handles);
l=selectedArray(handles);

handles.project.electrodes{l}.ch_label{a}=str;

handles.ui.updatePlots.labels=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);


%%%%%%%%%%%%%%%          edit electrode Coordinate          %%%%%%%%%%%%%%%
function setElecCoordpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to setElecCoordpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.project.electrodes)
    warning('Electrodes is empty. First cluster some electrodes');
    return;
end

a=selectedContact(handles);
l=selectedArray(handles);

% get cursor coordinates
crd=handles.ui.cursor;

% apply to current electrode
if get(handles.projectSCEcheckbox,'Value') % projection to SCE
    handles.project.electrodes{l}.projection{1}.x(a)=crd(1);
    handles.project.electrodes{l}.projection{1}.y(a)=crd(2);
    handles.project.electrodes{l}.projection{1}.z(a)=crd(3);
else %without projection
    handles.project.electrodes{l}.x(a)=crd(1);
    handles.project.electrodes{l}.y(a)=crd(2);
    handles.project.electrodes{l}.z(a)=crd(3);
end

handles.ui.updatePlots.electrodes=1;
handles.ui.updatePlots.elecLines=1;
handles.ui.updatePlots.labels=1;
handles.ui.updatePlots.views2D=[1 1 1];

handles=updateTAC(handles);
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%          navigate electrodes                %%%%%%%%%%%%%%%
% --- Executes on button press in NextArrayPushbutton.
function NextArrayPushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to NextArrayPushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isempty(handles.project.electrodes)
    warning('Electrodes is empty. First cluster some electrodes');
    return;
end

l=selectedArray(handles);
if l < length(handles.project.electrodes)
    a=1; %set electrode to 1
    
    handles = setSelectedArray(handles, l+1);
    handles = setSelectedContact(handles, a);
    
    
    if get(handles.projectSCEcheckbox,'Value') % projection to SCE
        d1=handles.project.electrodes{l+1}.projection{1}.x(a);
        d2=handles.project.electrodes{l+1}.projection{1}.y(a);
        d3=handles.project.electrodes{l+1}.projection{1}.z(a);
    else %without projection
        d1=handles.project.electrodes{l+1}.x(a);
        d2=handles.project.electrodes{l+1}.y(a);
        d3=handles.project.electrodes{l+1}.z(a);
    end

    
    D=AnatSpace2Mesh([d1 d2 d3],handles.project.S2);
    set(handles.sliderX,'Value',D(1));
    set(handles.sliderY,'Value',D(2));
    set(handles.sliderZ,'Value',D(3));    
    
    handles.ui.updatePlots.electrodes=1;
    handles.ui.updatePlots.labels=1;
    handles.ui.updatePlots.elecLines=1;
    
    handles=updateElectrodes3D(handles);
    handles=updateTAC(handles);
    
    set(handles.editArrayName,'String',handles.project.electrodes{l+1}.Name);
    set(handles.editElecLabels,'string', handles.project.electrodes{l+1}.ch_label{a});

    
end

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in PrevArrayPushbutton.
function PrevArrayPushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to PrevArrayPushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.project.electrodes)
    warning('Electrodes is empty. First cluster some electrodes');
    return;
end


l=selectedArray(handles);

if l>1
    a=1; %set electrode to 1
    handles = setSelectedArray(handles, l-1);
    handles = setSelectedContact(handles, a);
    
    if get(handles.projectSCEcheckbox,'Value') % projection to SCE
        d1=handles.project.electrodes{l-1}.projection{1}.x(a);
        d2=handles.project.electrodes{l-1}.projection{1}.y(a);
        d3=handles.project.electrodes{l-1}.projection{1}.z(a);
    else %without projection
        d1=handles.project.electrodes{l-1}.x(a);
        d2=handles.project.electrodes{l-1}.y(a);
        d3=handles.project.electrodes{l-1}.z(a);
    end

    D=AnatSpace2Mesh([d1 d2 d3],handles.project.S2);
    set(handles.sliderX,'Value',D(1));
    set(handles.sliderY,'Value',D(2));
    set(handles.sliderZ,'Value',D(3));
    
    handles.ui.updatePlots.electrodes=1;
    handles.ui.updatePlots.labels=1;
    handles.ui.updatePlots.elecLines=1;
    
    handles=updateElectrodes3D(handles);
    handles=updateTAC(handles);
    
    set(handles.editArrayName,'String',handles.project.electrodes{l-1}.Name);
    set(handles.editElecLabels,'string', handles.project.electrodes{l-1}.ch_label{a});
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in NextElecPushbutton.
function NextElecPushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to NextElecPushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isempty(handles.project.electrodes)
    warning('Electrodes is empty. First cluster some electrodes');
    return;
end

l=selectedContact(handles)+1;
a=selectedArray(handles);

if l <= handles.project.electrodes{a}.nElectrodes
    handles = setSelectedContact(handles, l);
    set(handles.editElecLabels,'string', handles.project.electrodes{a}.ch_label{l});
    
    if get(handles.projectSCEcheckbox,'Value') % projection to SCE
        d1=handles.project.electrodes{a}.projection{1}.x(l);
        d2=handles.project.electrodes{a}.projection{1}.y(l);
        d3=handles.project.electrodes{a}.projection{1}.z(l);
    else %without projection
        d1=handles.project.electrodes{a}.x(l);
        d2=handles.project.electrodes{a}.y(l);
        d3=handles.project.electrodes{a}.z(l);
    end

    D=AnatSpace2Mesh([d1 d2 d3],handles.project.S2);
    set(handles.sliderX,'Value',D(1));
    set(handles.sliderY,'Value',D(2));
    set(handles.sliderZ,'Value',D(3));
    
    
    handles.ui.updatePlots.electrodes=1;
    handles=updateElectrodes3D(handles);
    handles=updateTAC(handles);
    
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in PrevElecPushbutton.
function PrevElecPushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to PrevElecPushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isempty(handles.project.electrodes)
    warning('Electrodes is empty. First cluster some electrodes');
    return;
end

l=selectedContact(handles)-1;
a=selectedArray(handles);

if l >= 1
    handles = setSelectedContact(handles, l);
    set(handles.editElecLabels,'string', handles.project.electrodes{a}.ch_label{l});
    
    if get(handles.projectSCEcheckbox,'Value') % projection to SCE
        d1=handles.project.electrodes{a}.projection{1}.x(l);
        d2=handles.project.electrodes{a}.projection{1}.y(l);
        d3=handles.project.electrodes{a}.projection{1}.z(l);
    else %without projection
        d1=handles.project.electrodes{a}.x(l);
        d2=handles.project.electrodes{a}.y(l);
        d3=handles.project.electrodes{a}.z(l);
    end
    
    D=AnatSpace2Mesh([d1 d2 d3],handles.project.S2);
    set(handles.sliderX,'Value',D(1));
    set(handles.sliderY,'Value',D(2));
    set(handles.sliderZ,'Value',D(3));
    
    handles.ui.updatePlots.electrodes=1;
    handles=updateElectrodes3D(handles);
    handles=updateTAC(handles);
end

% Update handles structure
guidata(hObject, handles);

%--------------------------------------------------------------------
%%%%%%%%%%%  Select what electrodes to plot in 3D and 2D views  %%%%%%%%%%%
% --- Executes when selected object is changed in plotElectrodesOneAllUipanel.
function plotElectrodesOneAllUipanel_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in plotElectrodesOneAllUipanel
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.ui.updatePlots.views2D=[1 1 1]; %Force update all slices
handles=updateTAC(handles);

handles.ui.updatePlots.electrodes=1;
handles.ui.updatePlots.labels=1;
handles.ui.updatePlots.elecLines=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

%--------------------------------------------------------------------
%%%%%%%%%%%%%                Remove Array                   %%%%%%%%%%%%%%%
% --- Executes on button press in RemoveArraypushbutton.
function RemoveArrayPushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to RemoveArrayPushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(handles.project.electrodes) 
    
    l=selectedArray(handles); %actual elec to remove
% add warning image
    choice = questdlg([ 'Are you sure to remove electrode array number ' num2str(l) ' ?'], ...
        'Delete array', ...
        'Yes','No','No');
    if strcmp(choice,'No')
       return;
    end
    [handles.project, handles.work, a] = ...
        ielec.deleteArray(struct('index', l), handles.project, handles.work);
    handles = setSelectedArray(handles, a);

    if a == 0 % nothing left
        handles = setSelectedContact(handles, 0);

    else % at least one electrode left
        handles = setSelectedContact(handles, 1);
        
        d1=handles.project.electrodes{a}.x(1);
        d2=handles.project.electrodes{a}.y(1);
        d3=handles.project.electrodes{a}.z(1);
        
        D=AnatSpace2Mesh([d1 d2 d3],handles.project.S2);
        set(handles.sliderX,'Value',D(1));
        set(handles.sliderY,'Value',D(2));
        set(handles.sliderZ,'Value',D(3));
    end
    
    handles.ui.updatePlots.views2D=[1 1 1]; % Force update all slices
    handles.ui.updatePlots.resetTAC=1;      % reset 2D views axes
    handles.ui.updatePlots.electrodes=1;
    handles.ui.updatePlots.labels=1;
    handles.ui.updatePlots.elecLines=1;
    handles=updateElectrodes3D(handles);
    handles=updateTAC(handles);
end

% Update handles structure
guidata(hObject, handles);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%          PLANNING  DEPTHS                  %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Planning Selection Group: Grids or Depths
function PlanningSelectionGroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in PlanningSelectionGroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(handles.DepthPlanningButton,'Value') % deepth electrode selected
    showPlanningPanel(handles, 'depth');
else
    showPlanningPanel(handles, 'grid');
end


% --- Show the Simulate panel for one kind of planning array.
% Called both when the user moves the radio pair and when UpdateTargetEditBox
% follows the selected array, so the two cannot drift apart. Setting
% SelectedObject does not fire SelectionChangedFcn, which is why this sets
% the panel visibility itself.
function showPlanningPanel(handles, arrayType)
isDepth = strcmp(arrayType, 'depth');

if isDepth
    set(handles.PlanningSelectionGroup, 'SelectedObject', handles.DepthPlanningButton);
else
    set(handles.PlanningSelectionGroup, 'SelectedObject', handles.GridPlanningButton);
end

if isDepth
    set(handles.PanelPlanningDepths,'Visible','on')
    set(handles.PanelPlanningGrids,'Visible','off')
else
    set(handles.PanelPlanningDepths,'Visible','off')
    set(handles.PanelPlanningGrids,'Visible','on')
end


%%%%%%%%%%%%%%%        new target definition               %%%%%%%%%%%%%%%
% --- Executes on button press in NewTargetpushbutton.
function NewTargetpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to NewTargetpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

target=[];
target.Type='depth';
target.Name='Planning';
target.planning='yes';
target=checkElectrodeStructure(target);


set(handles.TargetInXedit,'String','0');
set(handles.TargetInYedit,'String','0');
set(handles.TargetInZedit,'String','0');
target.targetIn.x=0;
target.targetIn.y=0;
target.targetIn.z=0;

set(handles.TargetOutXedit,'String','45');
set(handles.TargetOutYedit,'String','45');
set(handles.TargetOutZedit,'String','45');
target.targetOut.x=45;
target.targetOut.y=45;
target.targetOut.z=45;

target.x=[0:5:45]';
target.y=[0:5:45]';
target.z=[0:5:45]';

target.rows=10; 
target.columns=1;
target.adjMat=makeAdjMat(target.rows,target.columns);

target.ch_label={'Planning 1','Planning 2','Planning 3','Planning 4','Planning 5',...
    'Planning 6','Planning 7','Planning 8','Planning 9','Planning 10'};

set(handles.nTargetEdit,'String','10');
target.nElectrodes=10;

set(handles.FirstSecondTargetedit,'String','5');
target.FirstSecond=5;

set(handles.SecondLastTargetEdit,'String','5');
target.SecondLast=5;

set(handles.AnteriorFrameradiobutton,'value',1)
target.framePosition='Anterior';
target.frameDown=0;

handles = addtarget2structure(handles,target); % updating anat info. Since empty, not working

handles = updateTarget(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%        edit target Name                     %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%   edit target distance beteween electrodes  %%%%%%%%%%%%%%%
function FirstSecondTargetedit_Callback(hObject, eventdata, handles)
% hObject    handle to FirstSecondTargetedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FirstSecondTargetedit as text
%        str2double(get(hObject,'String')) returns contents of FirstSecondTargetedit as a double
l=selectedPlanningArray(handles);
handles.project.targets{l}.FirstSecond=str2double(get(handles.FirstSecondTargetedit,'String'));
handles=updateTarget(handles);
handles.ui.updatePlots.views2D=[1 1 1];
handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;

handles=updateTAC(handles);
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

function SecondLastTargetEdit_Callback(hObject, eventdata, handles)
% hObject    handle to SecondLastTargetEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SecondLastTargetEdit as text
%        str2double(get(hObject,'String')) returns contents of SecondLastTargetEdit as a double
l=selectedPlanningArray(handles);
handles.project.targets{l}.SecondLast=str2double(get(handles.SecondLastTargetEdit,'String'));
handles=updateTarget(handles);

handles.ui.updatePlots.views2D=[1 1 1];
handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;
handles=updateTAC(handles);
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%      edit target number of electrodes       %%%%%%%%%%%%%%%
function nTargetEdit_Callback(hObject, eventdata, handles)
% hObject    handle to nTargetEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nTargetEdit as text
%        str2double(get(hObject,'String')) returns contents of nTargetEdit as a double
l=selectedPlanningArray(handles);
handles.project.targets{l}.nElectrodes=str2double(get(handles.nTargetEdit,'String'));
handles=updateTarget(handles);
handles.ui.updatePlots.views2D=[1 1 1];
handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;

handles=updateTAC(handles);
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

%--------------------------------------------------------------------
%%%%%%%%%%%%%%  change target locations with mouse click    %%%%%%%%%%%%%%%
% --- Executes on button press in TargetInpushbutton.
function TargetInpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to TargetInpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = setPlanningPoint(handles, 'targetIn');
guidata(hObject, handles);

% --- Executes on button press in TargetOutpushbutton.
function TargetOutpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to TargetOutpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = setPlanningPoint(handles, 'targetOut');
guidata(hObject, handles);


% --- Let the user click one end of a planning depth electrode in a 2-D view.
% POINTFIELD is 'targetIn' (the target) or 'targetOut' (the entry point).
% The two buttons did the same 80 lines each, differing in which field they
% wrote and which boxes they filled - and in one more thing, see below.
function handles = setPlanningPoint(handles, pointField)

if isempty(handles.project.T1)
    warning ('First Load MRI image. Click New button or open existing project.')
    return
end

if isempty(handles.project.targets)
    warning('First create a new target');
    return;
end

switch pointField
    case 'targetIn'
        boxes = {'TargetInXedit','TargetInYedit','TargetInZedit'};
        % The Target button does NOT round the click before using it, while
        % the Entry P button does. That difference is v1.020's, preserved
        % here rather than quietly settled - see docs/OPEN_QUESTIONS.md
        % item 13.
        roundClick = false;
    case 'targetOut'
        boxes = {'TargetOutXedit','TargetOutYedit','TargetOutZedit'};
        roundClick = true;
end

[d1,d2]=ginput(1);

if roundClick && ~verLessThan('matlab','8.4.0')
    d1=round(d1,3,'significant');
    d2=round(d2,3,'significant');
end

% which view was clicked, and which sliders it therefore moves
planeAxes   = [handles.axesX handles.axesY handles.axesZ];
planeSlider = {handles.sliderX, handles.sliderY, handles.sliderZ};

plane = find(gca == planeAxes, 1);
if isempty(plane)
    warning('you must click inside one off the three 2D plane views')
    return;
end

inPlane = setdiff(1:3, plane);
set(planeSlider{inPlane(1)}, 'Value', d1);
set(planeSlider{inPlane(2)}, 'Value', d2);

voxel = ielview.voxelFromPlaneClick(plane, get(planeSlider{plane},'Value'), [d1 d2]);

% set target coordinates
% define anatomical coords
coords=mesh2AnatSpace(voxel, handles.project.S2);

l=selectedPlanningArray(handles);
handles.project.targets{l}.(pointField).x=coords(1);
handles.project.targets{l}.(pointField).y=coords(2);
handles.project.targets{l}.(pointField).z=coords(3);

if ~verLessThan('matlab','8.4.0')
    coords=round(coords,3,'significant');
end

for k = 1:3
    set(handles.(boxes{k}), 'String', num2str(coords(k)));
end

handles=updateTarget(handles);
handles.ui.updatePlots.views2D=[1 1 1];
handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;

handles=updateTAC(handles);
handles=updateElectrodes3D(handles);


function TargetInXedit_Callback(hObject, eventdata, handles)
% hObject    handle to TargetInXedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TargetInXedit as text
%        str2double(get(hObject,'String')) returns contents of TargetInXedit as a double

l=selectedPlanningArray(handles);
handles.project.targets{l}.targetIn.x=str2double(get(handles.TargetInXedit,'String'));
handles=updateTarget(handles);
handles.ui.updatePlots.views2D=[1 1 1];
handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;

handles=updateTAC(handles);
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

function TargetInYedit_Callback(hObject, eventdata, handles)
% hObject    handle to TargetInYedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TargetInYedit as text
%        str2double(get(hObject,'String')) returns contents of TargetInYedit as a double
l=selectedPlanningArray(handles);
handles.project.targets{l}.targetIn.y=str2double(get(handles.TargetInYedit,'String'));
handles=updateTarget(handles);
handles.ui.updatePlots.views2D=[1 1 1];
handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;

handles=updateTAC(handles);
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

function TargetInZedit_Callback(hObject, eventdata, handles)
% hObject    handle to TargetInZedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TargetInZedit as text
%        str2double(get(hObject,'String')) returns contents of TargetInZedit as a double
l=selectedPlanningArray(handles);
handles.project.targets{l}.targetIn.z=str2double(get(handles.TargetInZedit,'String'));

%handles.project.targets{l}.frameDown = handles.project.targets(l).coordinates(handles.project.targets(l).n,3) < 0; % handles.project.targets(l).targetIn.z < 0;
handles=updateTarget(handles);
handles.ui.updatePlots.views2D=[1 1 1];
handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;

handles=updateTAC(handles);
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

function TargetOutXedit_Callback(hObject, eventdata, handles)
% hObject    handle to TargetOutXedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TargetOutXedit as text
%        str2double(get(hObject,'String')) returns contents of TargetOutXedit as a double
l=selectedPlanningArray(handles);
handles.project.targets{l}.targetOut.x=str2double(get(handles.TargetOutXedit,'String'));
handles=updateTarget(handles);
handles.ui.updatePlots.views2D=[1 1 1];
handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;

handles=updateTAC(handles);
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

function TargetOutYedit_Callback(hObject, eventdata, handles)
% hObject    handle to TargetOutYedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TargetOutYedit as text
%        str2double(get(hObject,'String')) returns contents of TargetOutYedit as a double
l=selectedPlanningArray(handles);
handles.project.targets{l}.targetOut.y=str2double(get(handles.TargetOutYedit,'String'));
handles=updateTarget(handles);
handles.ui.updatePlots.views2D=[1 1 1];
handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;

handles=updateTAC(handles);
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

function TargetOutZedit_Callback(hObject, eventdata, handles)
% hObject    handle to TargetOutZedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TargetOutZedit as text
%        str2double(get(hObject,'String')) returns contents of TargetOutZedit as a double
l=selectedPlanningArray(handles);
handles.project.targets{l}.targetOut.z=str2double(get(handles.TargetOutZedit,'String'));
handles=updateTarget(handles);
handles.ui.updatePlots.views2D=[1 1 1];
handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;

handles=updateTAC(handles);
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

%--------------------------------------------------------------------
%%%%%% change targetOut location editing angles Azimuth or Elevation %%%%%%
function ElevacionTargetedit_Callback(hObject, eventdata, handles)
% hObject    handle to ElevacionTargetedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ElevacionTargetedit as text
%        str2double(get(hObject,'String')) returns contents of ElevacionTargetedit as a double
handles=angleChange(handles);
handles.ui.updatePlots.views2D=[1 1 1];
handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;

handles=updateTAC(handles);
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

function AzimuthTargetedit_Callback(hObject, eventdata, handles)
% hObject    handle to AzimuthTargetedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AzimuthTargetedit as text
%        str2double(get(hObject,'String')) returns contents of AzimuthTargetedit as a double
handles=angleChange(handles);
handles.ui.updatePlots.views2D=[1 1 1];
handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;

handles=updateTAC(handles);
handles=updateElectrodes3D(handles);
% Update handles structure
guidata(hObject, handles);

%%%%%%             change targetOut location                         %%%%%%
%%%%%%              editing angles Azimuth or Elevation              %%%%%%
function handles=angleChange(handles)
% The user typed a direction: move the far end of the electrode to match.

l=selectedPlanningArray(handles);
target = handles.project.targets{l};

az=str2double( get(handles.AzimuthTargetedit,'String') );
el=str2double( get(handles.ElevacionTargetedit,'String') );

% if an error with conversion to double occurs, do nothing
if isnan(az)
    return;
end

if isnan(el)
    return;
end

xi = [target.targetIn.x target.targetIn.y target.targetIn.z];
xo = trajectoryEndPoint(xi, az, el, target.nElectrodes, ...
                        target.FirstSecond, target.SecondLast);

handles.project.targets{l}.targetOut.x=xo(1);
handles.project.targets{l}.targetOut.y=xo(2);
handles.project.targets{l}.targetOut.z=xo(3);

if ~verLessThan('matlab','8.4.0')
    xo=round(xo,3,'significant');
end

%punto taget Out
set(handles.TargetOutXedit,'String',num2str(xo(1)));
set(handles.TargetOutYedit,'String',num2str(xo(2)));
set(handles.TargetOutZedit,'String',num2str(xo(3)));

handles=updateTarget(handles);


%--------------------------------------------------------------------
function handles=updateTarget(handles)
%%%%%%%%% update targets structure after changing parameters      %%%%%%%%%
%%%%%%%%% targetIn, TargetOut, n, fs_dist, sl_dist
%%%%%%%%% Changes: delta, coordinates, az, el, distances, alpha, beta %%%%%

l=selectedPlanningArray(handles);
target = handles.project.targets{l};

xi = [target.targetIn.x  target.targetIn.y  target.targetIn.z];
xo = [target.targetOut.x target.targetOut.y target.targetOut.z];

trajectory = depthTrajectory(xi, xo, target.nElectrodes, ...
                             target.FirstSecond, target.SecondLast);

handles.project.targets{l}.delta     = trajectory.delta;
handles.project.targets{l}.azimut    = trajectory.azimuth;
handles.project.targets{l}.elevation = trajectory.elevation;
handles.project.targets{l}.distances = trajectory.distances;
handles.project.targets{l}.x = trajectory.coordinates(:,1);
handles.project.targets{l}.y = trajectory.coordinates(:,2);
handles.project.targets{l}.z = trajectory.coordinates(:,3);

% the boxes show a rounded angle, and show a straight axis as exactly zero.
% What is stored above is the full value.
az = trajectory.azimuth;
el = trajectory.elevation;

if ~verLessThan('matlab','8.4.0')
    az=round(az,3,'significant');
    el=round(el,3,'significant');
end

if abs(az)<0.01
    az=0;
end
if abs(el)<0.01
    el=0;
end

set(handles.AzimuthTargetedit,'String',num2str(az))
set(handles.ElevacionTargetedit,'String',num2str(el))

% anatomical labeling (electrodes and projections)
if strcmp(handles.project.currentSpace,'MNI') % options are 'Native' 'MNI'
    handles=labels2MNIspace(handles);
else
    handles=labels2NativeSpace(handles);
end

handles=estimateAnglesFrame(handles);


function handles=estimateAnglesFrame(handles)
% The selected target's frame angles, through the layer, and then shown.
%
% The frame position is the one the target already carries: the radio group
% sends a new one through the layer itself, and the backward compatibility
% block in UPDATETARGETEDITBOX sets it before calling this.

l=selectedPlanningArray(handles);

cfg = [];
cfg.index = l;
[handles.project, handles.work] = ...
    ielec.setFrame(cfg, handles.project, handles.work);

handles = showFrameAngles(handles);


% --- Show the selected target's frame angles in the two boxes.
% What the project stores is the full value; the rounding is display, and
% an angle within a hundredth of zero is shown as a straight zero.
function handles = showFrameAngles(handles)

l=selectedPlanningArray(handles);

alpha=handles.project.targets{l}.alpha;
beta=handles.project.targets{l}.beta;

if verLessThan('matlab','8.4.0')
    % execute code for R2014a or earlier
else
    % execute code for R2014b or later
    alpha=round(alpha,3,'significant');
    beta=round(beta,3,'significant');
end

if abs(alpha)<0.01
    alpha=0;
end
if abs(beta)<0.01
    beta=0;
end
set(handles.AlphaAngleEdit,'string', num2str(alpha));
set(handles.BetaAngleEdit,'string', num2str(beta));

%--------------------------------------------------------------------
%%%%%%%%%%          change in frame position                %%%%%%%%%%%%%%%
function Framebuttongroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in Framebuttongroup
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

l=selectedPlanningArray(handles);

% An empty framePosition means "keep the target's own", which is what the
% callback did when no button in the group was the selected one.
framePosition='';

%left frame
if get(handles.LeftFrameradiobutton,'value')
    framePosition='Left';
    %right frame
elseif get(handles.RightFrameradiobutton,'value')
    framePosition='Right';
    %anterior frame
elseif get(handles.AnteriorFrameradiobutton,'value')
    framePosition='Anterior';
    %posterior frame
elseif get(handles.PosteriorFrameradiobutton,'value')
    framePosition='Posterior';
end

cfg = [];
cfg.index         = l;
cfg.framePosition = framePosition;
[handles.project, handles.work] = ...
    ielec.setFrame(cfg, handles.project, handles.work);

handles = showFrameAngles(handles);

% Update handles structure
guidata(hObject, handles);

%--------------------------------------------------------------------
%%%%%%% change target locations editing Alpha and Beta frame angles  %%%%%%
function AlphaAngleEdit_Callback(hObject, eventdata, handles)
% hObject    handle to AlphaAngleEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of AlphaAngleEdit as text
%        str2double(get(hObject,'String')) returns contents of AlphaAngleEdit as a double
handles=AlphaBetaChange(handles);
handles.ui.updatePlots.views2D=[1 1 1];
handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;

handles=updateTAC(handles);
handles=updateElectrodes3D(handles);
% Update handles structure
guidata(hObject, handles);

function BetaAngleEdit_Callback(hObject, eventdata, handles)
% hObject    handle to BetaAngleEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of BetaAngleEdit as text
%        str2double(get(hObject,'String')) returns contents of BetaAngleEdit as a double
handles=AlphaBetaChange(handles);
handles.ui.updatePlots.views2D=[1 1 1];
handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;

handles=updateTAC(handles);
handles=updateElectrodes3D(handles);
% Update handles structure
guidata(hObject, handles);

function handles=AlphaBetaChange(handles)
% estimates xo based on changes on alpha or beta anlges
% saves alpha and beta in targets structure

l=selectedPlanningArray(handles);

n=handles.project.targets{l}.nElectrodes;
fs_dist=handles.project.targets{l}.FirstSecond;
sl_dist=handles.project.targets{l}.SecondLast;

%punto Target IN
xi(1)= handles.project.targets{l}.targetIn.x;
xi(2)= handles.project.targets{l}.targetIn.y;
xi(3)= handles.project.targets{l}.targetIn.z;

alpha = str2double( get(handles.AlphaAngleEdit,'String'));
beta = str2double( get(handles.BetaAngleEdit,'String'));

handles.project.targets{l}.alpha=alpha;
handles.project.targets{l}.alpha=beta;   % sic: should be .beta - see OPEN_QUESTIONS item 24

% estimate xo, from the frame angles (src/geometry/)
xo = frameTrajectoryEndPoint(xi, alpha, beta, ...
        handles.project.targets{l}.framePosition, handles.project.targets{l}.frameDown, ...
        n, fs_dist, sl_dist);

handles.project.targets{l}.targetOut.x=xo(1);
handles.project.targets{l}.targetOut.y=xo(2);
handles.project.targets{l}.targetOut.z=xo(3);
if verLessThan('matlab','8.4.0')
    % execute code for R2014a or earlier
else
    xo=round(xo,3,'significant');
end

%punto taget Out
set(handles.TargetOutXedit,'String',num2str(xo(1)));
set(handles.TargetOutYedit,'String',num2str(xo(2)));
set(handles.TargetOutZedit,'String',num2str(xo(3)));

handles=updateTarget(handles); %this will call to estimateAnglesFrame that should estimate the same angles


function handles = UpdateTargetEditBox(handles)
% Refresh the Simulate panel from the selected planning array.
%
% Returns handles because it does more than write to controls: the
% backward-compatibility block below fills in frameDown, framePosition,
% alpha and beta for projects saved before those fields existed. The caller
% must keep the returned struct, or that work is computed and thrown away.

l=selectedPlanningArray(handles);

% the panel follows the array, rather than staying wherever the user last
% left the radio pair
showPlanningPanel(handles, handles.project.targets{l}.Type);

set(handles.editPlanningArrayName,'String',handles.project.targets{l}.Name);
set(handles.nTargetEdit,'String',num2str(handles.project.targets{l}.nElectrodes));
handles = setSelectedPlanningTarget(handles, 1);
set(handles.editPlanningElecLabel,'string',handles.project.targets{l}.ch_label{1});


% Everything below belongs to a DEPTH planning array: an entry point, a
% target point, the trajectory angles and the stereotactic frame.
% checkElectrodeStructure creates those fields only for arrays whose Type
% is 'depth' (see its planning block), so reading them for a grid array
% fails with "Unrecognized field name".
%
% That is what used to happen. This function assumed every planning array
% was a depth electrode, so Load simulated coordinates crashed on any
% project holding a planning GRID - which is every project made with the
% New button in Grids mode.
%
% A planning GRID is now handled too: Alejandro asked for grids to be
% accepted, so the Grids boxes are filled from the array's own rows,
% columns and distance, and the panel switches to Grids mode above. Its
% hemisphere and rotation have no boxes to fill.
%
% Either way the boxes belonging to the other mode are cleared, so that
% they cannot be read as describing the array that is now selected.
if strcmp(handles.project.targets{l}.Type, 'depth')

    set(handles.FirstSecondTargetedit,'String',num2str(handles.project.targets{l}.FirstSecond));
    set(handles.SecondLastTargetEdit,'String',num2str(handles.project.targets{l}.SecondLast));

    %punto Target IN
    xi(1)=handles.project.targets{l}.targetIn.x;
    xi(2)=handles.project.targets{l}.targetIn.y;
    xi(3)=handles.project.targets{l}.targetIn.z;

    if verLessThan('matlab','8.4.0')
        % execute code for R2014a or earlier
    else
        xi=round(xi,3,'significant');
    end

    set(handles.TargetInXedit,'String',num2str(xi(1)));
    set(handles.TargetInYedit,'String',num2str(xi(2)));
    set(handles.TargetInZedit,'String',num2str(xi(3)));


    %punto taget OUT
    xo(1)=handles.project.targets{l}.targetOut.x;
    xo(2)=handles.project.targets{l}.targetOut.y;
    xo(3)=handles.project.targets{l}.targetOut.z;

    if verLessThan('matlab','8.4.0')
        % execute code for R2014a or earlier
    else
        xo=round(xo,3,'significant');
    end

    %punto taget Out
    set(handles.TargetOutXedit,'String',num2str(xo(1)));
    set(handles.TargetOutYedit,'String',num2str(xo(2)));
    set(handles.TargetOutZedit,'String',num2str(xo(3)));


    if verLessThan('matlab','8.4.0')
        % execute code for R2014a or earlier 
        az=handles.project.targets{l}.azimut;
        el=handles.project.targets{l}.elevation;
    else
        % execute code for R2014b or later
        az=round(handles.project.targets{l}.azimut,4,'significant');
        el=round(handles.project.targets{l}.elevation,4,'significant');
    end


    % Azimuth
    set(handles.AzimuthTargetedit,'String',num2str(az))

    % Elevation
    set(handles.ElevacionTargetedit,'String',num2str(el))


    % backward compatibility ---
    if isfield (handles.project.targets{l},'frameDown')
        if isempty (handles.project.targets{l}.frameDown)
            handles.project.targets{l}.framePosition='Anterior';
            handles.project.targets{l}.frameDown =  handles.project.targets{l}.z(handles.project.targets{l}.nElectrodes) < 0; %handles.project.targets{l}.targetIn.z < 0;
            handles=estimateAnglesFrame(handles); %estimate alpha and beta
        end
    else
        handles.project.targets{l}.framePosition='Anterior';
        handles.project.targets{l}.frameDown = handles.project.targets{l}.z(handles.project.targets{l}.nElectrodes) < 0; %handles.project.targets{l}.targetIn.z < 0;
    
        handles=estimateAnglesFrame(handles); %estimate alpha and beta
    
    end
    % ----


    %left frame
    if strcmp(handles.project.targets{l}.framePosition,'Left');
        set(handles.LeftFrameradiobutton,'value',1)
        %right frame
    elseif  strcmp(handles.project.targets{l}.framePosition,'Right');
        set(handles.RightFrameradiobutton,'value',1)
        %anterior frame
    elseif  strcmp(handles.project.targets{l}.framePosition,'Anterior');
        set(handles.AnteriorFrameradiobutton,'value',1)
        %posterior frame
    elseif strcmp(handles.project.targets{l}.framePosition,'Posterior');
        set(handles.PosteriorFrameradiobutton,'value',1)
    end



    beta=handles.project.targets{l}.beta;
    alpha=handles.project.targets{l}.alpha;
    if verLessThan('matlab','8.4.0')
        % execute code for R2014a or earlier
    else
        % execute code for R2014b or later
        alpha=round(alpha,3,'significant');
        beta=round(beta,3,'significant');
    end

    set(handles.AlphaAngleEdit,'string', num2str(alpha));
    set(handles.BetaAngleEdit,'string', num2str(beta));

    clearPlanningBoxes(handles, 'grid');   % the other mode's boxes

elseif strcmp(handles.project.targets{l}.Type, 'grid')

    set(handles.rowsPlanningGridEdit,    'String', num2str(handles.project.targets{l}.rows));
    set(handles.columnsPlanningGridEdit, 'String', num2str(handles.project.targets{l}.columns));
    set(handles.distancePlanningGridEdit,'String', num2str(handles.project.targets{l}.distance));

    clearPlanningBoxes(handles, 'depth');  % the other mode's boxes

else
    % neither: leave nothing behind that could be read as this array's
    clearPlanningBoxes(handles, 'depth');
    clearPlanningBoxes(handles, 'grid');
end


% --- Empty the boxes of one Simulate mode.
function clearPlanningBoxes(handles, mode)
switch mode
    case 'depth'
        boxes = {'FirstSecondTargetedit','SecondLastTargetEdit', ...
                 'TargetInXedit','TargetInYedit','TargetInZedit', ...
                 'TargetOutXedit','TargetOutYedit','TargetOutZedit', ...
                 'AzimuthTargetedit','ElevacionTargetedit', ...
                 'AlphaAngleEdit','BetaAngleEdit'};
    case 'grid'
        boxes = {'rowsPlanningGridEdit','columnsPlanningGridEdit', ...
                 'distancePlanningGridEdit'};
end
for k = 1:numel(boxes)
    set(handles.(boxes{k}), 'String', '');
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%           PLANNING  GRIDS                  %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%           New planning                       %%%%%%%%%%%%%%%
function newPlanningGridButton_Callback(hObject, eventdata, handles)
% hObject    handle to newPlanningGridButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% check for the presence of SCE
if isempty(handles.project.vertices_SCE_R)
    warning('First you need to load or generate a smooth cortical envelope. Use the toolbar button for that purpose.')
    return;
end

% the boxes say how big it is, the cursor where it goes
cfg = [];
cfg.centre  = handles.ui.cursor;
cfg.rows    = str2num(get(handles.rowsPlanningGridEdit,'String'));      %#ok<ST2NM>
cfg.columns = str2num(get(handles.columnsPlanningGridEdit,'String'));   %#ok<ST2NM>
cfg.spacing = str2num(get(handles.distancePlanningGridEdit,'String'));  %#ok<ST2NM>

[handles.project, handles.work, l] = ...
    ielec.newTarget(cfg, handles.project, handles.work);

% show the one that was just planned
handles = showPlanningArray(handles, l);

% anatomical labeling (electrodes and projections)
if strcmp(handles.project.currentSpace,'MNI') % options are 'Native' 'MNI'
    handles=labels2MNIspace(handles);
else
    handles=labels2NativeSpace(handles);
end

% Update handles structure
guidata(hObject, handles);


% --- Rows, columns , distance
function rowsPlanningGridEdit_Callback(hObject, eventdata, handles)
% hObject    handle to rowsPlanningGridEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of rowsPlanningGridEdit as text
%        str2double(get(hObject,'String')) returns contents of rowsPlanningGridEdit as a double
%
% TODO


function columnsPlanningGridEdit_Callback(hObject, eventdata, handles)
% hObject    handle to columnsPlanningGridEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of columnsPlanningGridEdit as text
%        str2double(get(hObject,'String')) returns contents of columnsPlanningGridEdit as a double
%
% TODO

function distancePlanningGridEdit_Callback(hObject, eventdata, handles)
% hObject    handle to distancePlanningGridEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of distancePlanningGridEdit as text
%        str2double(get(hObject,'String')) returns contents of distancePlanningGridEdit as a double
%
% TODO


% --- Fit grid to surface
function fitPlanningGridButton_Callback(hObject, eventdata, handles)
% hObject    handle to fitPlanningGridButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.project.targets)
    warning('Targets is empty');
    return;
end

cfg = [];
cfg.index = selectedPlanningArray(handles);
[handles.project, handles.work] = ...
    ielec.fitTarget(cfg, handles.project, handles.work);

handles = redrawPlanningGrid(handles);

guidata(hObject, handles);



%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%       Displacements / Rotations             %%%%%%%%%%%%%%%

% --- Change Center
function ChangeCenterPlanningGridButton_Callback(hObject, eventdata, handles)
% hObject    handle to ChangeCenterPlanningGridButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Unlike the eight buttons below, this one has never checked that a planning
% array exists, so with none it fails instead of warning - now with
% ielec:badOption from the layer rather than on an index of 0. Kept as it is
% - see docs/OPEN_QUESTIONS.md item 15.
a=selectedPlanningArray(handles);

cfg = [];
cfg.index  = a;
cfg.centre = handles.ui.cursor;
[handles.project, handles.work] = ...
    ielec.placeTarget(cfg, handles.project, handles.work);
handles = redrawPlanningGrid(handles);

% Update handles structure
guidata(hObject, handles);


% --- Superior
function pushbuttonSup_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = nudgePlanningGrid(handles, [0 0 1], []);   % superior
guidata(hObject, handles);

% --- Inferior
function moveInfButton_Callback(hObject, eventdata, handles)
% hObject    handle to moveInfButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = nudgePlanningGrid(handles, [0 0 -1], []);   % inferior
guidata(hObject, handles);

% --- Posterior
function movePosButton_Callback(hObject, eventdata, handles)
% hObject    handle to movePosButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = nudgePlanningGrid(handles, [0 -1 0], []);   % posterior
guidata(hObject, handles);

% --- Anterior
function moveAntButton_Callback(hObject, eventdata, handles)
% hObject    handle to moveAntButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = nudgePlanningGrid(handles, [0 1 0], []);   % anterior
guidata(hObject, handles);

% ---Left
function pushbuttonLeft_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = nudgePlanningGrid(handles, [-1 0 0], []);   % left
guidata(hObject, handles);

% --- Right
function pushbuttonRight_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = nudgePlanningGrid(handles, [1 0 0], []);   % right
guidata(hObject, handles);

% --- Rotation Left
function RotLButton_Callback(hObject, eventdata, handles)
% hObject    handle to RotLButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = nudgePlanningGrid(handles, [0 0 0], -5);   % turn 5 degrees one way
guidata(hObject, handles);

% --- Rotation Right
function rotRButton_Callback(hObject, eventdata, handles)
% hObject    handle to rotRButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = nudgePlanningGrid(handles, [0 0 0], 5);   % turn 5 degrees the other way
guidata(hObject, handles);


%--------------------------------------------------------------------
% --- Move or turn the selected planning grid, for the eight buttons above.
% OFFSET is added to the centre of the grid, in mm. ROTATION turns it about
% that centre, in degrees, and is [] for none - see PLACEPLANNINGGRID for why
% it must be [] and not 0.
function handles = nudgePlanningGrid(handles, offset, rotation)

if isempty(handles.project.targets)
    warning('Targets is empty');
    return;
end

a=selectedPlanningArray(handles);

cfg = [];
cfg.index    = a;
cfg.offset   = offset;
cfg.rotation = rotation;
[handles.project, handles.work] = ...
    ielec.placeTarget(cfg, handles.project, handles.work);
handles = redrawPlanningGrid(handles);


% --- Redraw after a planning grid has moved.
function handles = redrawPlanningGrid(handles)

handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;
handles.ui.updatePlots.targetLabels=1;

handles=updateElectrodes3D(handles);
handles=updateTAC(handles);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%          NAVIGATE PLANNING                 %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Add targets to structure 
function handles = addtarget2structure(handles,target)
% Add target to handles.project.targets
%
% The planning grid goes in through ielec.newTarget, which adds it itself;
% this is the other caller, the depth target built in the frontend, and it
% keeps its own ADDARRAY until that one moves onto the layer too.
[handles.project.targets, l] = addArray(handles.project.targets, target);

handles = showPlanningArray(handles, l);


% --- Show the planning array at index L: the panel, the sliders, the views.
function handles = showPlanningArray(handles, l)

%set visualization to this electrode
handles = setSelectedPlanningArray(handles, l);
handles = setSelectedPlanningTarget(handles, 1);
set(handles.editPlanningArrayName,'String',handles.project.targets{l}.Name);
set(handles.editPlanningElecLabel,'string',handles.project.targets{l}.ch_label{1});

% go to first electrode coordinate for checking
d1=handles.project.targets{l}.x(1);
d2=handles.project.targets{l}.y(1);
d3=handles.project.targets{l}.z(1);

D=AnatSpace2Mesh([d1 d2 d3],handles.project.S2);
set(handles.sliderX,'Value',D(1));
set(handles.sliderY,'Value',D(2));
set(handles.sliderZ,'Value',D(3));


handles.ui.updatePlots.views2D=[1 1 1];     
handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;
handles.ui.updatePlots.targetLabels=1;

handles=updateElectrodes3D(handles);
handles=updateTAC(handles);

%--------------------------------------------------------------------
%%%%%%%%%%%%%                Remove Array                   %%%%%%%%%%%%%%%
function removePlanningArrayButton_Callback(hObject, eventdata, handles)
% hObject    handle to removePlanningArrayButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isempty(handles.project.targets) 
    
    l=selectedPlanningArray(handles); %actual elec to remove
% add warning image
    choice = questdlg([ 'Are you sure to remove planning array number ' num2str(l) ' ?'], ...
        'Delete array', ...
        'Yes','No','No');
    if strcmp(choice,'No')
       return;
    end
    [handles.project, handles.work, a] = ielec.deleteArray(...
            struct('index', l, 'group', 'targets'), handles.project, handles.work);
    handles = setSelectedPlanningArray(handles, a);

    if a == 0 % nothing left
        handles = setSelectedPlanningTarget(handles, 0);

    else % at least one electrode left
        handles = setSelectedPlanningTarget(handles, 1);
        
        d1=handles.project.targets{a}.x(1);
        d2=handles.project.targets{a}.y(1);
        d3=handles.project.targets{a}.z(1);
        
        D=AnatSpace2Mesh([d1 d2 d3],handles.project.S2);
        set(handles.sliderX,'Value',D(1));
        set(handles.sliderY,'Value',D(2));
        set(handles.sliderZ,'Value',D(3));
    end
    
    handles.ui.updatePlots.views2D=[1 1 1]; % Force update all slices
    handles.ui.updatePlots.resetTAC=1;      % reset 2D views axes
    handles.ui.updatePlots.targets=1;
    handles.ui.updatePlots.labels=1;
    handles.ui.updatePlots.targetLines=1;
    handles=updateElectrodes3D(handles);
    handles=updateTAC(handles);
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%          edit array name                    %%%%%%%%%%%%%%%
function editPlanningArrayName_Callback(hObject, eventdata, handles)
% hObject    handle to editPlanningArrayName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of editPlanningArrayName as text
%        str2double(get(hObject,'String')) returns contents of editPlanningArrayName as a double

if isempty(handles.project.targets)
    warning('Targets is empty');
    return;
end

str=get(handles.editPlanningArrayName,'String');
a=selectedPlanningArray(handles);

cfg = [];
cfg.index    = a;
cfg.group    = 'targets';
cfg.baseName = str;
[handles.project, handles.work] = ...
    ielec.nameContacts(cfg, handles.project, handles.work);

handles.ui.updatePlots.targetLabels=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);


%%%%%%%%%%%%%%%          edit electrode name                %%%%%%%%%%%%%%%
function editPlanningElecLabel_Callback(hObject, eventdata, handles)
% hObject    handle to editPlanningElecLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles   structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of editPlanningElecLabel as text
%        str2double(get(hObject,'String')) returns contents of editPlanningElecLabel as a double

if isempty(handles.project.targets)
    warning('Targets is empty');
    return;
end

str=get(handles.editPlanningElecLabel,'String');
a=selectedPlanningTarget(handles);
l=selectedPlanningArray(handles);

handles.project.targets{l}.ch_label{a}=str;

handles.ui.updatePlots.targetLabels=1;
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);


%%%%%%%%%%%%%%          edit electrode coordinate          %%%%%%%%%%%%%%%
function setPlanningElecCoordpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to setPlanningElecCoordpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.project.targets)
    warning('Targets is empty');
    return;
end

l=selectedPlanningTarget(handles)+1;
a=selectedPlanningArray(handles);

% get cursor coordinates
crd=handles.ui.cursor;

% apply to current electrode
if ~isempty(handles.project.targets{l}.projection)
    handles.project.targets{l}.projection{1}.x(a)=crd(1);
    handles.project.targets{l}.projection{1}.y(a)=crd(2);
    handles.project.targets{l}.projection{1}.z(a)=crd(3);
else %without projection
    handles.project.targets{l}.x(a)=crd(1);
    handles.project.targets{l}.y(a)=crd(2);
    handles.project.targets{l}.z(a)=crd(3);
end


handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;
handles.ui.updatePlots.targetLabels=1;
handles.ui.updatePlots.views2D=[1 1 1];

handles=updateTAC(handles);
handles=updateElectrodes3D(handles);

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%          navigate electrodes                %%%%%%%%%%%%%%%
% --- Executes on button press in nextPlanningArray.
function nextPlanningArray_Callback(hObject, eventdata, handles)
% hObject    handle to nextPlanningArray (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.project.targets)
    warning('Targets is empty');
    return;
end

l=selectedPlanningArray(handles);
if l < length(handles.project.targets)
    a=1; %set electrode to 1
    
    handles = setSelectedPlanningArray(handles, l+1);
    handles = setSelectedPlanningTarget(handles, a);
    
    if ~isempty(handles.project.targets{l+1}.projection)
        d1=handles.project.targets{l+1}.projection{1}.x(a);
        d2=handles.project.targets{l+1}.projection{1}.y(a);
        d3=handles.project.targets{l+1}.projection{1}.z(a);
    else
        d1=handles.project.targets{l+1}.x(a);
        d2=handles.project.targets{l+1}.y(a);
        d3=handles.project.targets{l+1}.z(a);
    end
    
    D=AnatSpace2Mesh([d1 d2 d3],handles.project.S2);
    set(handles.sliderX,'Value',D(1));
    set(handles.sliderY,'Value',D(2));
    set(handles.sliderZ,'Value',D(3));    
    
    handles.ui.updatePlots.targets=1;
    handles.ui.updatePlots.targetLabels=1;
    handles.ui.updatePlots.targetLines=1;
    
    handles=updateElectrodes3D(handles);
    handles=updateTAC(handles);
    
    % refresh the whole Simulate panel, not just the two name boxes: it
    % has to describe the array that is now selected
    handles = UpdateTargetEditBox(handles);
end

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in prevPlannigArray.
function prevPlannigArray_Callback(hObject, eventdata, handles)
% hObject    handle to prevPlannigArray (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.project.targets)
    warning('Targets is empty');
    return;
end

l=selectedPlanningArray(handles);

if l>1
    a=1; %set electrode to 1
    handles = setSelectedPlanningArray(handles, l-1);
    handles = setSelectedPlanningTarget(handles, a);

    if ~isempty(handles.project.targets{l-1}.projection)
        d1=handles.project.targets{l-1}.projection{1}.x(a);
        d2=handles.project.targets{l-1}.projection{1}.y(a);
        d3=handles.project.targets{l-1}.projection{1}.z(a);
    else
        d1=handles.project.targets{l-1}.x(a);
        d2=handles.project.targets{l-1}.y(a);
        d3=handles.project.targets{l-1}.z(a);
    end
    
    D=AnatSpace2Mesh([d1 d2 d3],handles.project.S2);
    set(handles.sliderX,'Value',D(1));
    set(handles.sliderY,'Value',D(2));
    set(handles.sliderZ,'Value',D(3));
    
    handles.ui.updatePlots.targets=1;
    handles.ui.updatePlots.targetLabels=1;
    handles.ui.updatePlots.targetLines=1;
    
    handles=updateElectrodes3D(handles);
    handles=updateTAC(handles);
    
    % refresh the whole Simulate panel, not just the two name boxes: it
    % has to describe the array that is now selected
    handles = UpdateTargetEditBox(handles);
end

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in nextPlanningElecButton.
function nextPlanningElecButton_Callback(hObject, eventdata, handles)
% hObject    handle to nextPlanningElecButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.project.targets)
    warning('Targets is empty');
    return;
end


l=selectedPlanningTarget(handles)+1;
a=selectedPlanningArray(handles);

if l <= handles.project.targets{a}.nElectrodes
    handles = setSelectedPlanningTarget(handles, l);
    set(handles.editPlanningElecLabel,'string', handles.project.targets{a}.ch_label{l});
        
    if ~isempty(handles.project.targets{a}.projection)
        d1=handles.project.targets{a}.projection{1}.x(l);
        d2=handles.project.targets{a}.projection{1}.y(l);
        d3=handles.project.targets{a}.projection{1}.z(l);
    else
        d1=handles.project.targets{a}.x(l);
        d2=handles.project.targets{a}.y(l);
        d3=handles.project.targets{a}.z(l);
    end
    
        
    D=AnatSpace2Mesh([d1 d2 d3],handles.project.S2);
    set(handles.sliderX,'Value',D(1));
    set(handles.sliderY,'Value',D(2));
    set(handles.sliderZ,'Value',D(3));
    
    
    handles.ui.updatePlots.targets=1;
    handles=updateElectrodes3D(handles);
    handles=updateTAC(handles);
    
end

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in prevPlanningElecButton.
function prevPlanningElecButton_Callback(hObject, eventdata, handles)
% hObject    handle to prevPlanningElecButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.project.targets)
    warning('Targets is empty');
    return;
end


l=selectedPlanningTarget(handles)-1;
a=selectedPlanningArray(handles);

if l >= 1
    handles = setSelectedPlanningTarget(handles, l);
    set(handles.editPlanningElecLabel,'string', handles.project.targets{a}.ch_label{l});
    
    if ~isempty(handles.project.targets{a}.projection)
        d1=handles.project.targets{a}.projection{1}.x(l);
        d2=handles.project.targets{a}.projection{1}.y(l);
        d3=handles.project.targets{a}.projection{1}.z(l);
    else
        d1=handles.project.targets{a}.x(l);
        d2=handles.project.targets{a}.y(l);
        d3=handles.project.targets{a}.z(l);
    end
    
    D=AnatSpace2Mesh([d1 d2 d3],handles.project.S2);
    set(handles.sliderX,'Value',D(1));
    set(handles.sliderY,'Value',D(2));
    set(handles.sliderZ,'Value',D(3));
    
    handles.ui.updatePlots.targets=1;
    handles=updateElectrodes3D(handles);
    handles=updateTAC(handles);
end

% Update handles structure
guidata(hObject, handles);


%--------------------------------------------------------------------
%%%%%%%%%%%%%%%     Select what planning electrodes to plot %%%%%%%%%%%%%%%
%                   in 3D and 2D views
% ---- plotTargetsOneAllUipanel
function plotTargetsOneAllUipanel_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in plotTargetsOneAllUipanel
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.ui.updatePlots.views2D=[1 1 1]; %Force update all slices

handles.ui.updatePlots.targets=1;
handles.ui.updatePlots.targetLines=1;

handles=updateElectrodes3D(handles);
handles=updateTAC(handles);

% Update handles structure
guidata(hObject, handles);


% =====================================================================
%                        electrode selection
% =====================================================================
% Which electrode array, and which contact inside it, the user is working
% on. The value lives in handles.work.selection; the two text controls
% next to the navigation arrows only display it.
%
% Before this change the label WAS the value: 27 places read it back with
% str2double(get(...,'String')), so the number the algorithms operated on
% was whatever text happened to be on screen, recovered by parsing it.
%
% The setters return handles, like every other function here that changes
% state, so callers must keep the returned struct and store it with
% guidata as usual. defaultGuiVariables initialises both to 0.

function n = selectedArray(handles)
%SELECTEDARRAY  Index of the electrode array being worked on.
n = handles.work.selection.array;

function n = selectedContact(handles)
%SELECTEDCONTACT  Index of the contact being worked on, inside that array.
n = handles.work.selection.contact;

function handles = setSelectedArray(handles, n)
%SETSELECTEDARRAY  Select an electrode array and show it in the interface.
handles.work.selection.array = n;
set(handles.arrayNumberText, 'String', num2str(n));

function handles = setSelectedContact(handles, n)
%SETSELECTEDCONTACT  Select a contact and show it in the interface.
handles.work.selection.contact = n;
set(handles.elecNumberText, 'String', num2str(n));


% =====================================================================
%                     planning-target selection
% =====================================================================
% The same story as the electrode selection above, for the planning side:
% which simulated array, and which target inside it, is being edited.
%
% 46 places read the number back out of the label - 35 with str2double and
% 11 with str2num, which evaluates the label's text as MATLAB code. Both
% are gone now.

function n = selectedPlanningArray(handles)
%SELECTEDPLANNINGARRAY  Index of the planning array being edited.
n = handles.work.selection.planningArray;

function n = selectedPlanningTarget(handles)
%SELECTEDPLANNINGTARGET  Index of the target being edited, inside that array.
n = handles.work.selection.planningTarget;

function handles = setSelectedPlanningArray(handles, n)
%SETSELECTEDPLANNINGARRAY  Select a planning array and show it in the interface.
handles.work.selection.planningArray = n;
set(handles.arrayPlanningNumberText, 'String', num2str(n));

function handles = setSelectedPlanningTarget(handles, n)
%SETSELECTEDPLANNINGTARGET  Select a target and show it in the interface.
handles.work.selection.planningTarget = n;
set(handles.elecPlanningNumberText, 'String', num2str(n));


% =====================================================================
%                          colour caches
% =====================================================================

function handles = takeColourCaches(handles, caches)
%TAKECOLOURCACHES  Put the colours derived from the project into ui.
%   The parcellation and surface colours are display state, so the ielec
%   layer does not keep them: it hands them over, and takes them back when
%   a project is saved (COLOURCACHESOF). Which colours those are is the
%   layer's to say, so the names come with them and are kept for the way
%   back - ielec.startSession hands over the empty set as the session opens,
%   so they are there from the first moment.
names = fieldnames(caches);
handles.ui.colourCacheNames = names;
for k = 1:numel(names)
    handles.ui.(names{k}) = caches.(names{k});
end

function caches = colourCachesOf(handles)
%COLOURCACHESOF  The colour caches in ui, for the layer to save with the project.
names = handles.ui.colourCacheNames;
for k = 1:numel(names)
    caches.(names{k}) = handles.ui.(names{k});
end
