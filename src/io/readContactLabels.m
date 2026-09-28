function labels = readContactLabels(fullPath, format)
%READCONTACTLABELS  Read a list of contact labels from a file.
%
%   labels = readContactLabels(fullPath, format) returns the labels held in
%   one file, as a cell array. FORMAT says how to read it:
%
%     'txt'              a tab delimited text list        (IMPORTTXTLABELS)
%     'matlab'           a .mat holding a cell array named `labels`
%     'eeglab'           a .set, from which the chanlocs labels are taken
%     'fieldtripHeader'  a .mat holding a FieldTrip header, `hdr.label`
%     'edf'              an .edf, whose header names its channels
%
%   These are the five entries the "load labels from file" dialog offered,
%   and the switch below is the one GETLABELSFROMFILE ran once the user had
%   chosen a file. The dialog itself is not here: a backend function that
%   opens a window cannot be called from a script, from a test, or from the
%   layer (docs/API_LAYER.md rule 2), which is why the reading moved out of
%   it and the asking stayed in the frontend.
%
%   A format this function does not know gives an empty list and says so,
%   exactly as the dialog's `otherwise` branch did.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IMPORTTXTLABELS, READEDFHEADER, IELEC.IMPORTLABELS.

labels = {};

switch format
    case 'txt' %load channels in a txt file
        labels = importTxtLabels(fullPath);

    case 'matlab' %MATLAB labels cell array
        s = load(fullPath);
        labels = s.labels;

    case 'eeglab' %EEGLAB
        s = load('-mat', fullPath);
        labels = {s.EEG.chanlocs.labels};

    case 'fieldtripHeader' %Fieldtrip (ft_readheader output)
        s = load('-mat', fullPath);
        labels = s.hdr.label;

    case 'edf'
        header = readEdfHeader(fullPath);
        labels = cellstr(header.channelname);

    otherwise
        disp('File format not supported');
end
end
