function handles=checkUpdates(handles)


% Version managing 
% ALWAYS USE X.xxx format !!!!

% This is the iElectrodes 2 line. The number is 2.0, and it is written 2.000
% because the format named above is not decoration: the comparison further
% down reads the published file by byte position - web_data(1:5) for the
% version and web_data(8:end) for the date - so a version of three characters
% would shorten the first line by two bytes and shift both reads. Measured on
% the two files: with 2.000 they come back '2.000' and '18 October 2026';
% written as 2.0 they come back '2.0 ' with a newline still inside it, and
% ' October 2026' with the day gone. So the version field breaks as well as
% the date, and an older install reading this would draw its dialog line in
% two. Five characters keeps that arithmetic true, and str2double is 2 for
% either spelling, so only the display suffers.
%
% The processing history in an .iel file records '2.0' rather than this - see
% docs/API_LAYER.md, "Recording each step". The two are different things on
% purpose: this one is the build the Info button's About box shows and the
% update check compares against the published release, while that one marks
% which line of the toolbox wrote a step, and should not move because a
% display format did.
%
% The date is when this version string was set, as 12 May 2023 was for 1.020.
% It wants setting again when v2 is actually released.

handles.work.iElectrodes_version='2.000';
handles.work.iElectrodes_date='18 October 2026';

% overwrite version.txt automatically - Important for developing new
% versions

fid=fopen([handles.work.pathstr '/version.txt'],'w+'); 
if fid~=-1
    fprintf(fid,'%s \n',handles.work.iElectrodes_version);
    fprintf(fid,'%s \n',handles.work.iElectrodes_date);
    fclose(fid);
else
    warning('cannot update version.txt');
end

web_data=[];
try
    web_data=webread('https://sourceforge.net/p/ielectrodes/code/ci/master/tree/version.txt?format=raw');
catch 
    warning('Unable to check last version on-line' );
end
if ~isempty(web_data)
    % The published file is two lines, the version then the date, each
    % written '%s \n'. This reads them by splitting on the newline rather
    % than by counting bytes. web_data(1:5) and web_data(8:end) were correct
    % only while the version is exactly five characters, and they threw
    % MATLAB:badsubscript on anything shorter than eight bytes - a truncated
    % download, an error page, a redirect - from outside the try above and
    % so out of electrodes_gui_OpeningFcn, before the window was built.
    % docs/OPEN_QUESTIONS.md item 47.
    %
    % What is PUBLISHED still has to be five characters, because every
    % iElectrodes 1.020 in the field reads it by byte position too. This
    % changes only the reading end, so that it survives what it is handed.
    published = strsplit(strtrim(char(web_data(:)')), newline);
    last_version = strtrim(published{1});
    if numel(published) > 1
        last_date = strtrim(published{2});
    else
        last_date = '(no date)';
    end

newest = str2double(last_version);
if isnan(newest)
    % Silence used to be the answer here: str2double of a version with a
    % letter or two dots is NaN, NaN > x is false, and the toolbox reported
    % "you have the last version" for ever without ever having read one.
    warning('Could not read the published version number (''%s'').', last_version);
elseif newest < str2double(handles.work.iElectrodes_version)
    % Only while this build is ahead of the release, which is a development
    % state and cancels itself the moment the new version is published.
    fprintf('You are running iElectrodes %s, newer than the published %s.\n', ...
        handles.work.iElectrodes_version, last_version);
elseif newest>str2double(handles.work.iElectrodes_version)
    
    % Construct a questdlg with 2 options
    choice = questdlg( {'Would you like to download the last version?';
          '';
          ['Your version: ' handles.work.iElectrodes_version ' - ' handles.work.iElectrodes_date];
          ['Last version: ' last_version ' - ' last_date]} , ...
        'You don''t have the last iElectrodes version',...
        'Yes (recomended)','No','Yes (recomended)');
    
    % Handle response
    switch choice
        case 'Yes (recomended)'
            % open browser
            web('https://sourceforge.net/projects/ielectrodes/','-browser');
            %close gui
            %close(hObject);
            return;
        case 'No'
            % do nothing
    end
    
else
    % The author's own sentence, with the number it never used to say.
    fprintf('You have the last version of iElectrodes %s :-)\n', ...
        handles.work.iElectrodes_version);
end
end
