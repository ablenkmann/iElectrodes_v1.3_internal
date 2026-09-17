function coordinates = electrodeCoordinates(electrodes, source)
%ELECTRODECOORDINATES  One flat list of every contact, for exporting.
%
%   coordinates = electrodeCoordinates(electrodes) walks the arrays in
%   ELECTRODES and returns their contacts as parallel lists, in the order
%   array 1 contact 1, array 1 contact 2, ... array 2 contact 1, and so on.
%   Every export format starts from this list.
%
%   coordinates = electrodeCoordinates(electrodes, source) chooses which
%   coordinates to take:
%
%     'contacts'     where the contacts were localized     (the default)
%     'projection'   where they were projected to, using each array's FIRST
%                    projection - the smooth cortical envelope, currently
%
%   Returned fields, all the same length:
%
%     .x .y .z            coordinates, as row vectors
%     .label              contact label
%     .type               the array's Type, repeated for each of its contacts
%     .projectionMethod   the projection's method, or 'none' for contacts
%     .anatomicalLabel    the anatomical label of that contact
%
%   An empty list of arrays gives empty lists back, which is what the export
%   formats that need no coordinates - the iElectrodes .mat structure - pass
%   through.
%
%   Example
%       c = electrodeCoordinates(prj.electrodes);
%       [c.label(1:3); num2cell(c.x(1:3))]
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also CONCATENATEADJMAT, ALABELS2TXT_NEW.

if nargin < 2
    source = 'contacts';
end

useProjection = strcmpi(source, 'projection');
if ~useProjection && ~strcmpi(source, 'contacts')
    error('electrodeCoordinates:unknownSource', ...
        'SOURCE must be ''contacts'' or ''projection'', not ''%s''.', source);
end

x = []; y = []; z = [];
label = {}; type = {}; projectionMethod = {}; anatomicalLabel = {};

i = 1;
for j = 1:length(electrodes)
    for k = 1:electrodes{j}.nElectrodes

        if useProjection
            from = electrodes{j}.projection{1};   % first projection (SCE for now)
            projectionMethod{i} = from.method;
        else
            from = electrodes{j};
            projectionMethod{i} = 'none';
        end

        x(i) = from.x(k);
        y(i) = from.y(k);
        z(i) = from.z(k);
        anatomicalLabel{i} = from.aLabels{k};

        type{i}  = electrodes{j}.Type;
        label{i} = electrodes{j}.ch_label{k};   % the label belongs to the contact,
                                                % not to where it was projected
        i = i + 1;
    end
end

coordinates.x                = x;
coordinates.y                = y;
coordinates.z                = z;
coordinates.label            = label;
coordinates.type             = type;
coordinates.projectionMethod = projectionMethod;
coordinates.anatomicalLabel  = anatomicalLabel;
end
