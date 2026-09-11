function electrodeNailNaumber_uitable (hObject, handles,nFit)
% graphical interface to introduce the electrode number of nailed electrode
% coordinates. changes will be stored in handles.uitable_elecNum

% use in the following way
%     guidata(hObject, handles);     % % Update content in handles structure
%     electrodeNailNaumber_uitable (hObject, handles, nFit); %use graphical interface. This will change content in handles.
%     handles = guidata(hObject); % retrive updated data
    
% nFit = number of electrodes to fit

% new version using cathegorical selection on electrode number

coords=handles.GS;
N=size(coords,1); % number of selected electrodes
%elecNumber=zeros(N,1);
order=1:N;

catElecNum = repmat({categorical(1:nFit)'},N,1);

fig = uifigure('Position',[300 300 752 250]);
set(fig,'name','Define Electrode Number for Nailed Coordinates and close this window ')

% old code for free text
% uit = uitable(fig,'Data',[order', coords, elecNumber], 'DeleteFcn',{@MyDeleteFcn_uitable, hObject, handles},'Parent',fig,'Position',[25 50 700 200]);
% uit.ColumnEditable = [false false false false true];
% uit.ColumnName = {'Selection','X','Y','Z','Elec Number' };

uit = uitable(fig,'Data',table(order', coords, catElecNum), 'DeleteFcn',{@MyDeleteFcn_uitable, hObject, handles},'Parent',fig,'Position',[25 50 700 200]);
uit.ColumnEditable = [false false true];
uit.ColumnName = {'Coord Selection','(X, Y, Z)','Elec Number - select' };

% TODO t.SelfAssessedHealthStatus = categorical(t.SelfAssessedHealthStatus,{'Poor','Fair','Good','Excellent'},' Ordinal',true);

waitfor(uit) % wait untilt table is closed

%elecNumber = tableOut(:,end); % save output as vector

end

% code that is run when closing the window
function data = MyDeleteFcn_uitable(hTable, event, hObject, handles)

% old code for free text
%  data = hTable.Data;                        % Get data from UI table
%  handles.uitable_elecNum = data(:,end);    % Store the UI table data

data = table2array(hTable.Data(:,end));    % Get data from UI table

for i=1:size(data,1)
    if ischar(data{i})
        handles.uitable_elecNum(i) = str2double(data{i});    % Store the UI table data
    else
        handles.uitable_elecNum(i) = nan;    % Store the UI table data - selection not used
    end
end

guidata(hObject,handles)                  % store the data into the main GUI
end
