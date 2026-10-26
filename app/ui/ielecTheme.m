function t = ielecTheme(name)
%IELECTHEME  The colours and metrics one iElectrodes 2 theme is drawn with.
%
%   t = ielecTheme(name) returns a struct of colours for a named theme.
%   ielecTheme() lists the names.
%
%     'clinical'      the default. Warm light, teal accent.
%     'clinicalDark'  the same palette for a dark reading room.
%
%   The clinical values are the ones in the HTML mock-up
%   (frontend_mockups/ielectrodes2_A_clinical.html, [data-theme="clinical"]),
%   kept to the hex digit so that the window and the mock-up are the same
%   design rather than two interpretations of one.
%
%   clinicalDark is derived rather than copied, because the mock-up has no
%   dark clinical - its 'dark' and 'midnight' are separate designs. What is
%   kept is what makes clinical recognisable: the teal accent, the amber
%   cursor, the blue for planning. What is inverted is only the surfaces.
%
%   Every field is a 1-by-3 of doubles in [0 1], which is what the uifigure
%   components want, rather than the hex the mock-up is written in.
%
%     bg        the window behind everything
%     panel     a panel's face
%     panel2    a panel's face, one step back - headers, striped rows
%     line      a border
%     line2     a lighter divider, inside a panel
%     ink       text
%     ink2      text, one step quieter
%     mut       text, quiet: hints, units, counts
%     acc       the accent: a pressed button, a selected tab
%     accInk    text on the accent
%     warn      a warning
%     warnBg    behind a warning
%     view      the viewport, which is dark in both themes - an image is
%               read against black whatever the window does
%     viewInk   text drawn on the viewport
%     cross     the cursor's crosshair
%     dot       a contact
%     dotSel    the contact that is selected
%     plan      a planned array, which is never the same colour as a
%               localized one
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELECTRODES2, UIFIGURE.

names = {'clinical', 'clinicalDark'};

if nargin < 1 || isempty(name)
    t = names;
    return
end
if ~ismember(name, names)
    error('ielec:badTheme', ...
        'ielecTheme: no theme called ''%s''. There are: %s.', ...
        name, strjoin(names, ', '));
end

switch name
    case 'clinical'
        h = struct( ...
            'bg',      'F4F2EE', 'panel',  'FFFFFF', 'panel2', 'F8F7F4', ...
            'line',    'DCD8D0', 'line2',  'ECE9E3', ...
            'ink',     '1C1B19', 'ink2',   '3A3833', 'mut',    '5C5952', ...
            'acc',     '0F6E7B', 'accInk', 'FFFFFF', ...
            'warn',    '9A4B0B', 'warnBg', 'FDF1E3', ...
            'view',    '121417', 'viewInk','C9C5BD', ...
            'cross',   'E8A33D', 'dot',    'E8A33D', 'dotSel', 'FFFFFF', ...
            'plan',    '5AA9E6');

    case 'clinicalDark'
        % The surfaces step down; the accent steps up, because 0F6E7B on a
        % dark face is too close to it to read.
        h = struct( ...
            'bg',      '16181A', 'panel',  '212427', 'panel2', '1B1E21', ...
            'line',    '34383C', 'line2',  '292D31', ...
            'ink',     'E8E6E1', 'ink2',   'C6C3BC', 'mut',    '8E8B84', ...
            'acc',     '2AA3B0', 'accInk', '0B1012', ...
            'warn',    'D98634', 'warnBg', '2A2018', ...
            'view',    '0C0E10', 'viewInk','C9C5BD', ...
            'cross',   'E8A33D', 'dot',    'E8A33D', 'dotSel', 'FFFFFF', ...
            'plan',    '5AA9E6');
end

f = fieldnames(h);
for k = 1:numel(f)
    t.(f{k}) = hex2rgb(h.(f{k}));
end

t.name = name;
t.isDark = strcmp(name, 'clinicalDark');

% Metrics, from the mock-up's own custom properties
t.radius  = 8;      % --r,   a panel's corner
t.pad     = 12;     % --pad, inside a panel
t.gap     = 8;      % between controls
t.fontSize = 13;    % --fs
t.font     = 'Segoe UI';
t.monoFont = 'Consolas';
end

% ----------------------------------------------------------------------
function rgb = hex2rgb(h)
rgb = double([hex2dec(h(1:2)), hex2dec(h(3:4)), hex2dec(h(5:6))]) / 255;
end
