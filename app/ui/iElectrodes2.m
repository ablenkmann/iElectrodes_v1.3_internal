classdef iElectrodes2 < matlab.apps.AppBase
%IELECTRODES2  The iElectrodes 2 window.
%
%   iElectrodes2 opens it. iElectrodes2('clinicalDark') opens it dark.
%
%   Work in progress. The window draws a project and the views work; most
%   of the controls inside the five steps are not wired yet, and are
%   visibly inert rather than silently doing nothing.
%
%   THE SHAPE
%
%   Five steps across the top - Localize, Arrays, Anatomy, Planning, Export.
%   They are steps rather than pages: the views and the contact list stay put
%   and only the stack of controls under the contacts changes, so the picture
%   a person is working on never goes away when they move on.
%
%     top     the name, the five steps, the open file, light or dark
%     left    five views - three planes, the CT voxels, the surfaces -
%             with the cursor box and the messages under them
%     right   the contacts, the current step's controls, then the view
%             settings, which belong to no step
%     bottom  what the project has loaded, and what is in it
%
%   WHAT WORKS
%
%   Project > Open reads a .iel through ielec.openProject. The three planes
%   draw through ielview.sliceView, with the parcellation over them, the
%   contacts of every array, the planned targets and a crosshair; clicking
%   one moves the cursor. The CT threshold runs ielec.thresholdCT and plots
%   what it finds; one button brushes and then takes the brushed voxels
%   through ielec.selectVoxels. The 3-D view draws the surfaces, the
%   contacts, and the slices in space, and a click on the brain takes a
%   slice there.
%
%   WHAT DOES NOT
%
%   The controls of the Arrays, Anatomy, Planning and Export steps are
%   placeholders. "Radiological convention" is built and disabled on
%   purpose: which way round the planes are drawn is the one thing here
%   that can be wrong without looking wrong, and the old window has no such
%   switch to copy.
%
%   WHY A CLASSDEF AND NOT A .mlapp
%
%   Same components as App Designer - uifigure, uigridlayout, uipanel - and
%   its base class. The difference is that this file is text, so it diffs and
%   reviews; a .mlapp is a zip that git stores as a blob. The old
%   electrodes_gui.fig already showed the cost of that.
%
%   Errors: iElectrodes2:badStep, iElectrodes2:noSection,
%   iElectrodes2:badTheme. The ielec: prefix belongs to the layer.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELECTHEME.

    properties (Access = public)
        UIFigure    matlab.ui.Figure
        Theme       struct
        Step        char = 'Localize'
    end

    properties (SetAccess = private, GetAccess = public)
        % The two the layer passes about, held as the layer hands them back
        % and replaced only by a layer call. Readable from outside - a test
        % wants to see what was opened - but not writable, so the layer's
        % ownership of project state is structural here rather than a matter
        % of this window's own discipline (docs/OPEN_QUESTIONS.md item 48).
        Project     struct = struct()
        Work        struct = struct()
    end

    properties (Access = private)
        Controls    struct = struct()  % the controls a step wires up
        Scatter     = []        % the voxels on offer, as plotted
        Brushing    logical = false
        PickPoint   double = []     % where the brain was last clicked
        SphereCount double = 0      % how many spheres this drawing has made
        Thr         double = []     % the thresholds in the CT's own units
        DenoiseK    double = 1      % and the denoise kernel beside them
        SurfaceAlpha double = 0.5  % the old AlphaSlider's own default
        MixValue    double = 0.5   % 0 the MRI alone, 1 the CT alone
        Mixed       = []        % the blended volume IELVIEW.MIXIMAGES makes
        Voxel       double = [] % where the cursor is, in voxels
        Caches      struct = struct()   % the colour caches the file carries
    end

    properties (Access = private)
        Root        matlab.ui.container.GridLayout
        TopBar      matlab.ui.container.GridLayout
        Body        matlab.ui.container.GridLayout
        LeftCol     matlab.ui.container.GridLayout
        ViewGrid    matlab.ui.container.GridLayout
        RightCol    matlab.ui.container.GridLayout
        StepStack   matlab.ui.container.GridLayout
        ViewBlock   matlab.ui.container.GridLayout
        InfoLabel   matlab.ui.control.Label
        StatusBar   matlab.ui.container.GridLayout

        StepButtons struct = struct()
        Views       struct = struct()
        Sections    struct = struct()
        Chips       matlab.ui.control.Label
        CountLabel  matlab.ui.control.Label
        FileLabel   matlab.ui.control.Label
        MessageBox  matlab.ui.control.TextArea
        ContactTable matlab.ui.control.Table
        ThemeSwitch matlab.ui.control.Switch
    end

    properties (Constant, Access = private)
        STEPS = {'Localize', 'Arrays', 'Anatomy', 'Planning', 'Export'}
    end

    methods (Access = public)
        function app = iElectrodes2(themeName)
            if nargin < 1 || isempty(themeName), themeName = 'clinical'; end
            addToolboxPath();
            app.Theme = ielecTheme(themeName);

            app.buildWindow();
            app.buildMenus();
            app.buildTopBar();
            app.buildLeft();
            app.buildRight();
            app.buildStatusBar();
            app.showStep(app.Step);
            app.applyTheme();

            app.UIFigure.Visible = 'on';
            registerApp(app, app.UIFigure);
            app.UIFigure.CloseRequestFcn = @(~,~) delete(app);
            if nargout == 0, clear app, end
        end

        function setStep(app, name)
            %SETSTEP  Show one of the five steps: Localize ... Export.
            if ~ismember(name, app.STEPS)
                error('iElectrodes2:badStep', 'iElectrodes2: no step called ''%s''.', name);
            end
            app.showStep(name);
        end

        function setTheme(app, which)
            %SETTHEME  'light' or 'dark', or the theme names 'clinical' and
            %   'clinicalDark' that the constructor takes.
            %
            %   Two vocabularies for two themes is one too many, but the
            %   switch on screen says light and dark and the constructor
            %   takes a theme name, so both arrive here. Translated rather
            %   than refused: setTheme('clinicalDark') used to throw a raw
            %   MATLAB error from inside the switch.
            switch which
                case {'light', 'clinical'},      which = 'light';
                case {'dark',  'clinicalDark'},  which = 'dark';
                otherwise
                    error('iElectrodes2:badTheme', ...
                        ['iElectrodes2: no theme called ''%s''. ' ...
                         'There are: light, dark.'], which);
            end
            app.ThemeSwitch.Value = which;
            app.switchTheme(which);
        end

        function openProject(app, file)
            %OPENPROJECT  Open a .iel and draw it.
            if nargin < 2 || isempty(file)
                [f, d] = uigetfile('*.iel', 'Open an iElectrodes project');
                if isequal(f, 0), return, end
                file = fullfile(d, f);
            end
            % the third output is the colour caches the file carries; they
            % are display data, which is why the layer hands them back
            % separately - and taking them saves recomputing a large
            % parcellation, which is seconds
            try
                [app.Project, app.Work, app.Caches] = ielec.openProject( ...
                    struct('file', file), [], []);
            catch err
                % The layer says why, with the identifier rule 5 promises.
                % Without this the window looks inert while a stack trace
                % lands in the command window, which is a poor way to find
                % out that a file is not a project.
                app.showMessage(['Could not open it: ' err.message]);
                return
            end

            % nothing of the last project survives into this one
            app.PickPoint = [];
            app.Scatter   = [];
            app.Thr       = [];

            app.Mixed = app.blendVolumes();
            D = size(app.Project.T1.img);
            app.Voxel = round(D / 2);

            [~, name, ext] = fileparts(file);
            app.FileLabel.Text = [name ext];
            app.showMessage(sprintf('Opened %s - %d x %d x %d', [name ext], D));
            app.redrawPlanes();
            app.resetThresholds();
            if ~isfield(app.Project, 'TAC') || isempty(app.Project.TAC)
                % no CT in this project: clear whatever the last one left,
                % rather than showing one patient's voxels under another's
                cla(app.Views.voxels.axes);
                app.Views.voxels.caption.Text = 'no CT loaded';
            end
            app.draw3D();
        end

        function goTo(app, voxel)
            %GOTO  Put the cursor on a voxel and redraw.
            %
            %   goTo(app, [88 128 128]). Out of the volume is clamped to it
            %   rather than refused: a click near the edge means the edge.
            if isempty(app.Mixed), return, end
            D     = size(app.Project.T1.img);
            voxel = max(min(round(voxel(:)'), D), [1 1 1]);
            if isequal(voxel, app.Voxel), return, end
            app.Voxel = voxel;
            app.redrawPlanes();
            if app.checked('slicePlanes'), app.draw3D(); end
        end

        function resetThresholds(app)
            %RESETTHRESHOLDS  Start the thresholds where the old window did.
            %
            %   Its two sliders ran over the CT's range and sat at 0.5 and
            %   1 - read out of electrodes_gui.fig rather than assumed - so
            %   half way up the range to the top of it. Written here as the
            %   intensities they come to, because this window's fields are
            %   intensities. A CT with a different range gets different
            %   numbers, which is the point of computing them.
            if ~isfield(app.Project, 'TAC') || isempty(app.Project.TAC)
                return
            end

            % The layer already measured these when it loaded the CT; a
            % second pass over the volume to find them again is work for
            % nothing. (checkProjectStructure and ielec.loadCT both set them.)
            lo = double(app.Work.minValue);
            hi = double(app.Work.maxValue);
            app.Thr      = [round(lo + 0.5 * (hi - lo)), round(hi)];
            app.DenoiseK = 1;

            % Worked out whether or not the Localize step is showing: its
            % controls exist only while it is, and a project opened from
            % another step used to leave the panel saying "no CT loaded"
            % over a project that has one.
            if ~isfield(app.Controls, 'ctRange')
                return
            end
            r = app.Controls.ctRange;
            r(1).Value = app.Thr(1);
            r(2).Value = app.Thr(2);
            app.applyThreshold();
        end

        function fold(app, names)
            %FOLD  Collapse named panels: fold(app, {'contacts','messages'}).
            if ischar(names), names = {names}; end
            for k = 1:numel(names)
                if ~isfield(app.Sections, names{k})
                    error('iElectrodes2:noSection', ...
                        'iElectrodes2: no panel called ''%s''.', names{k});
                end
                if app.Sections.(names{k}).open
                    app.toggleSection(names{k});
                end
            end
        end

        function delete(app)
            delete(app.UIFigure);
        end
    end

    % ==================================================================
    methods (Access = private)

        function buildWindow(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Name = 'iElectrodes 2';
            app.UIFigure.Position = [60 60 1560 940];

            app.Root = uigridlayout(app.UIFigure, [3 1]);
            app.Root.RowHeight   = {44, '1x', 26};
            app.Root.ColumnWidth = {'1x'};
            app.Root.Padding     = [10 8 10 8];
            app.Root.RowSpacing  = 8;

            app.Body = uigridlayout(app.Root, [1 2]);
            app.Body.Layout.Row    = 2;
            app.Body.ColumnWidth   = {'1.4x', '1x'};
            app.Body.RowHeight     = {'1x'};
            app.Body.Padding       = [0 0 0 0];
            app.Body.ColumnSpacing = 10;
        end

        function mixed = blendVolumes(app)
            % The colours are the toolbox's own - app/config/defaultColors.m
            % - so the new window and the old one tint an image the same.
            %
            % MIXIMAGES normalises each volume to 0..1 itself and only
            % then applies opt.win, as an offset and a scale:
            % (img - win(1)) / win(2). The window is therefore in normalised
            % units, not in intensities - give it the volume's own range and
            % the image comes out black. The old window takes it from two
            % sliders that run 0 to 1 and start at 0 and 1, read out of
            % electrodes_gui.fig rather than assumed, which is [0 1]: the
            % whole range, nothing clipped. The MRI and CT window controls
            % the design notes ask for are what will move it.
            %
            % mixValue 0 is the MRI on its own. The two colours overlap, so
            % MIXIMAGES mixes linearly and 0 weighs the CT out.
            c = defaultColors();
            opt.colorT1         = c.colorT1;
            opt.colorCT         = c.colorCT;
            opt.edgeCTchannels  = c.edgeCTchannels;
            opt.percentileThres = c.percentileThres;
            opt.edgeCT          = app.checked('ctEdge');

            opt.win = [0 1];

            T1 = single(app.Project.T1.img);

            CT = [];
            if isfield(app.Project, 'TAC') && ~isempty(app.Project.TAC)
                CT = single(app.Project.TAC.img);
            end
            % 0 is the MRI alone and 1 the CT alone; in between, because
            % the two colours overlap, MIXIMAGES weighs them linearly
            mixed = ielview.mixImages(T1, CT, app.MixValue, opt);
        end

        function redrawPlanes(app)
            if isempty(app.Mixed), return, end
            voxdim = abs(diag(app.Project.S2(:,1:3))');
            for pl = 1:3
                v  = app.Voxel(pl);
                ax = app.Views.(app.planeName(pl)).axes;
                [img, lims, aspect] = ielview.sliceView(app.Mixed, pl, v, voxdim);
                cla(ax);
                im = image(ax, img);
                im.ButtonDownFcn = @(~,~) app.planeClicked(pl);
                hold(ax, 'on');
                app.drawAtlas(ax, pl, v, voxdim);
                app.drawContacts2D(ax, pl, v);
                if app.checked('crosshair')
                    app.drawCross(ax, pl, lims);
                end
                hold(ax, 'off');
                % after the drawing, because IMAGE resets them
                ax.XLim = lims(1,:);
                ax.YLim = lims(2,:);
                ax.DataAspectRatio = aspect;
                ax.YDir = 'normal';
                ax.XDir = 'reverse';
                ax.XTick = []; ax.YTick = [];
                app.Views.(app.planeName(pl)).caption.Text = ...
                    sprintf('%d of %d', v, size(app.Mixed, pl));
            end

            crd = mesh2AnatSpace(app.Voxel, app.Project.S2);
            app.InfoLabel.Text = sprintf('x %.1f    y %.1f    z %.1f\n%s', ...
                crd(1), crd(2), crd(3), '(no anatomical label yet)');

            app.CountLabel.Text = app.countLine();
            app.fillContactTable();
            app.Chips.Text = app.statusLine();
        end

        function drawContacts2D(app, ax, pl, v)
            % The contacts this slice passes through, and the planned ones.
            %
            % The coordinates go on the axes as plain voxel numbers on the
            % two in-plane dimensions, which land where they belong because
            % the slice was turned and the x axis reversed - the same pair
            % of facts, kept together. Within one voxel of the slice is the
            % old views' rule, not a new one.
            %
            % Red grid, blue depth, green planned: the toolbox's own
            % colours, so a reader coming from version 1 reads the same
            % image. app/config/defaultColors.m.
            c       = defaultColors();
            inPlane = setdiff(1:3, pl);

            arrays = fieldOrEmpty(app.Project, 'electrodes');
            for k = 1:numel(arrays)
                if strcmp(arrays{k}.Type, 'grid')
                    col = c.electrodesGrid2D;
                else
                    col = c.electrodesDepth2D;
                end
                app.plotArray2D(ax, arrays{k}, pl, v, inPlane, ...
                    col, c.electrodesMarker2D);
            end

            targets = fieldOrEmpty(app.Project, 'targets');
            for k = 1:numel(targets)
                app.plotArray2D(ax, targets{k}, pl, v, inPlane, ...
                    c.target2D, c.targetMarker2D);
            end

            % The contacts being built, which are not an array yet, and the
            % anchors beside them. The old window shows these only in the
            % 3-D threshold view; on the planes is where you can see whether
            % a contact landed on the metal, so they are here too, in the
            % theme's own colours so they are not taken for an accepted
            % array.
            t = app.Theme;
            app.plotPoints2D(ax, fieldOrNumeric(app.Work, 'GS'), ...
                pl, v, inPlane, t.dot, 'o');
            app.plotPoints2D(ax, fieldOrNumeric(app.Work, 'anchors'), ...
                pl, v, inPlane, t.dotSel, 's');
        end

        function drawAtlas(app, ax, pl, v, voxdim)
            % The parcellation over the slice, at the toolbox's own
            % transparency. The colours are the cache the file carried, so
            % this costs a slice, not a parcellation.
            if ~app.checked('showAtlas'), return, end
            if ~isfield(app.Caches, 'wmparcColors') || ...
                    isempty(app.Caches.wmparcColors)
                return
            end
            img  = ielview.sliceView(app.Caches.wmparcColors, pl, v, voxdim);
            mask = double(sum(img, 3) > 0) * defaultColors().alphaAtlas;
            image(ax, img, 'AlphaData', mask, 'PickableParts', 'none');
        end

        function drawCross(app, ax, pl, lims)
            %DRAWCROSS  Four segments with a gap where the cursor is.
            %
            %   The gap is the point: a crosshair drawn through the voxel it
            %   marks hides the thing being looked at.
            %
            %   A line that runs along an axis takes that axis's colour -
            %   red x, green y, blue z - so a view says which two axes it is
            %   showing without being labelled. Written once here; the old
            %   window wrote it out three times, once per plane.
            c       = defaultColors();
            names   = {'x', 'y', 'z'};
            inPlane = setdiff(1:3, pl);
            a  = inPlane(1);   b  = inPlane(2);
            pa = app.Voxel(a); pb = app.Voxel(b);

            line(ax, [lims(1,1) pa-1], [pb pb], 'Color', c.(names{a}), ...
                'PickableParts', 'none');
            line(ax, [pa+1 lims(1,2)], [pb pb], 'Color', c.(names{a}), ...
                'PickableParts', 'none');
            line(ax, [pa pa], [lims(2,1) pb-1], 'Color', c.(names{b}), ...
                'PickableParts', 'none');
            line(ax, [pa pa], [pb+1 lims(2,2)], 'Color', c.(names{b}), ...
                'PickableParts', 'none');
        end

        function plotPoints2D(app, ax, pts, pl, v, inPlane, col, marker)
            %PLOTPOINTS2D  Points on one plane, near it or all of them.
            %
            %   PTS is N-by-3 in anatomical millimetres. Which of them are
            %   drawn is the "All contacts, not just this slice" box: off,
            %   only those within a voxel of the slice; on, every one of
            %   them flattened onto it, which is what the old window's
            %   Collapse does.
            if isempty(pts), return, end
            m = AnatSpace2Mesh(pts, app.Project.S2);

            if app.checked('collapse')
                near = true(size(m,1), 1);
            else
                near = abs(m(:,pl) - v) < 1;
            end
            if ~any(near), return, end

            % PickableParts none so that clicking a contact moves the
            % cursor there rather than being swallowed by the marker
            line(ax, m(near, inPlane(1)), m(near, inPlane(2)), ...
                'Marker', marker, 'Color', col, 'LineStyle', 'none', ...
                'MarkerSize', 7, 'LineWidth', 1.2, 'PickableParts', 'none');
        end

        function plotArray2D(app, ax, array, pl, v, inPlane, col, marker)
            if ~isfield(array, 'x') || isempty(array.x), return, end
            [px, py, pz] = app.contactCoords(array);
            app.plotPoints2D(ax, [px(:) py(:) pz(:)], pl, v, inPlane, ...
                col, marker);
        end

        function fillContactTable(app)
            % One array at a time, the one that is selected - which is how
            % the work goes, contact by contact down a single array.
            arrays = fieldOrEmpty(app.Project, 'electrodes');
            i = 0;
            if isfield(app.Work, 'selection') && ...
                    isfield(app.Work.selection, 'array')
                i = app.Work.selection.array;
            end
            if i < 1 || i > numel(arrays)
                app.ContactTable.Data = cell(0,4);
                app.setSectionTitle('contacts', 'Contacts');
                return
            end

            a = arrays{i};
            n = numel(a.x);
            rows = cell(n, 4);
            for k = 1:n
                if isfield(a, 'ch_label') && numel(a.ch_label) >= k
                    rows{k,1} = a.ch_label{k};
                else
                    rows{k,1} = sprintf('%s%d', a.Name, k);
                end
                % one decimal of a millimetre, which is what the coordinate
                % boxes have always shown; written out rather than left to
                % the table, which prints four digits the number has not got
                rows{k,2} = sprintf('%.1f', a.x(k));
                rows{k,3} = sprintf('%.1f', a.y(k));
                rows{k,4} = sprintf('%.1f', a.z(k));
            end
            app.ContactTable.Data = rows;
            app.setSectionTitle('contacts', ['Contacts - ' a.Name]);
        end

        function planeClicked(app, pl)
            %PLANECLICKED  Move the cursor to where a 2-D view was clicked.
            %
            %   A view fixes one coordinate and the click gives the other
            %   two - which two is IELVIEW.VOXELFROMPLANECLICK's business,
            %   not this window's, which is the point of it being there.
            %
            %   The two the click gives come straight off the axes because
            %   the slice was drawn in voxel coordinates: the same reason
            %   the contact markers go on unconverted.
            if isempty(app.Mixed), return, end
            ax = app.Views.(app.planeName(pl)).axes;
            cp = ax.CurrentPoint;
            app.goTo(ielview.voxelFromPlaneClick(pl, app.Voxel(pl), ...
                                                 round(cp(1,1:2))));
        end

        function name = planeName(~, pl)
            % plane 1, 2, 3 are the X, Y and Z views - the order
            % electrodes_gui.m's planeAxes has always used
            names = {'xPlane', 'yPlane', 'zPlane'};
            name  = names{pl};
        end

        function draw3D(app)
            %DRAW3D  The surfaces and the contacts, in space.
            ax = app.Views.threeD.axes;
            cla(ax);
            if isempty(app.Mixed)
                app.Views.threeD.caption.Text = 'nothing to show';
                return
            end

            app.SphereCount = 0;

            % a 3-D view that cannot be turned is a picture, not a view
            enableDefaultInteractivity(ax);
            ax.Interactions = [rotateInteraction, zoomInteraction];

            hold(ax, 'on');
            c      = defaultColors();
            shown  = 0;

            if app.checked('slicePlanes')
                shown = shown + app.drawSlicePlanes(ax);
            end

            if app.checked('pial')
                withAtlas = app.checked('atlasSurface');
                shown = shown + app.patchHemisphere(ax, 'R', withAtlas, 'pial');
                shown = shown + app.patchHemisphere(ax, 'L', withAtlas, 'pial');
            end
            if app.checked('envelope3d')
                shown = shown + app.patchHemisphere(ax, 'R', false, 'envelope');
                shown = shown + app.patchHemisphere(ax, 'L', false, 'envelope');
            end

            arrays = fieldOrEmpty(app.Project, 'electrodes');
            for k = 1:numel(arrays)
                a = arrays{k};
                if ~isfield(a, 'x') || isempty(a.x), continue, end
                if strcmp(a.Type, 'grid')
                    col = c.electrodesGrid3D;
                else
                    col = c.electrodesDepth3D;
                end
                [cx, cy, cz] = app.contactCoords(a);
                app.drawContacts3D(ax, cx, cy, cz, col);
                if app.checked('contactLabels') && isfield(a, 'ch_label')
                    text(ax, cx, cy, cz, a.ch_label, ...
                        'Color', c.labelsColor, 'FontSize', c.labelsFontSize);
                end
                shown = shown + 1;
            end

            % A planned target is not a contact that exists, so it is
            % drawn apart from one and can be put away. The old window
            % keeps a box for this; the design notes do not, which is how
            % a view ends up full of green that reads as electrodes sitting
            % off the brain when it is a plan.
            % the contacts being built, before they are an array
            t = app.Theme;
            gs = fieldOrNumeric(app.Work, 'GS');
            if ~isempty(gs)
                app.drawContacts3D(ax, gs(:,1), gs(:,2), gs(:,3), t.dot);
                shown = shown + 1;
            end
            an = fieldOrNumeric(app.Work, 'anchors');
            if ~isempty(an)
                app.drawContacts3D(ax, an(:,1), an(:,2), an(:,3), t.dotSel);
                shown = shown + 1;
            end

            targets = fieldOrEmpty(app.Project, 'targets');
            if app.checked('planned')
                for k = 1:numel(targets)
                    t = targets{k};
                    if ~isfield(t, 'x') || isempty(t.x), continue, end
                    [tx, ty, tz] = app.contactCoords(t);
                    app.drawContacts3D(ax, tx, ty, tz, c.target3D);
                    shown = shown + 1;
                end
            end

            hold(ax, 'off');
            if shown == 0
                app.Views.threeD.caption.Text = 'nothing to show';
                return
            end

            axis(ax, 'image');
            ax.Clipping = 'on';
            ax.XTick = []; ax.YTick = []; ax.ZTick = [];
            app.aimAtContacts(ax);

            % AXIS IMAGE fits everything in, and what is furthest out is
            % usually a planned array sitting well clear of the head, so
            % the brain ends up small in the middle of its own view. Frame
            % on the surfaces instead: a cube around them, which puts the
            % brain the same size in the view whichever surface is drawn,
            % and leaves what is outside the cube outside.
            app.frameOnSurfaces(ax);

            % Perspective, because a brain under parallel projection reads
            % as a diagram of a brain: the far side comes out the same size
            % as the near one and the depth goes out of it.
            ax.Projection = 'perspective';

            app.lightRig(ax);
            app.drawPickMarker(ax);
            app.Views.threeD.caption.Text = sprintf('%d arrays - %d planned', ...
                numel(arrays), numel(targets));
        end

        function surfaceClicked(app, src)
            %SURFACECLICKED  Take a slice where the brain was clicked.
            %
            %   "Pick a slice off the brain and see it in the 2-D views" -
            %   which is this, in one step: the point clicked becomes the
            %   cursor, and the three 2-D views are already drawn at the
            %   cursor.
            %
            %   HOW THE POINT IS FOUND
            %
            %   A click gives a line through the scene, not a point:
            %   ax.CurrentPoint is where that line enters and leaves. What
            %   is wanted is where it first meets the surface. Rather than
            %   intersect a quarter of a million triangles, take the
            %   vertices lying within a few millimetres of the line and
            %   keep the one nearest the camera - on a mesh whose faces are
            %   about a millimetre across, the nearest vertex to the ray is
            %   the point to within the size of a face, and a contact is
            %   bigger than that.
            if ~app.checked('pickSlice'), return, end

            ax = ancestor(src, 'axes');
            cp = ax.CurrentPoint;            % [near; far] on the view line
            p0 = cp(1,:);
            dir = cp(2,:) - p0;
            dir = dir / norm(dir);

            k = ielview.nearestOnRay(src.Vertices, p0, dir, 3);
            if isempty(k)
                app.showMessage('Nothing on the surface under that click.');
                return
            end

            app.PickPoint = src.Vertices(k,:);
            app.goTo(AnatSpace2Mesh(app.PickPoint, app.Project.S2));
            % GOTO redraws the 3-D view only when the slice planes are on,
            % and they start off - so without this the marker that says
            % where the slice was taken appears later, when something else
            % happens to redraw
            app.draw3D();
            app.showMessage(sprintf('Slice taken at x %.1f  y %.1f  z %.1f', ...
                app.PickPoint));
        end

        function txt = statusLine(app)
            %STATUSLINE  What the project has, at a glance.
            %
            %   Six things, and the same six before a project is open as
            %   after. It used to be built with six and then replaced with
            %   three, so atlas, pial and envelope - the three that differ
            %   between one project and the next - vanished the moment a
            %   project was opened.
            dot = [' ' char(183) ' '];
            if isempty(fieldnames(app.Project)) || ...
                    ~isfield(app.Project, 'currentSpace')
                % before a project is open, do not assert a space
                txt = strjoin({'no project', 'MRI --', 'CT --', ...
                    'atlas --', 'pial --', 'envelope --'}, dot);
                return
            end
            txt = strjoin({ ...
                [app.Project.currentSpace ' space'], ...
                ['MRI '      tick(~isempty(app.Project.T1))], ...
                ['CT '       tick(has(app.Project, 'TAC'))], ...
                ['atlas '    tick(has(app.Project, 'wmparc'))], ...
                ['pial '     tick(has(app.Project, 'verticesR') || ...
                                  has(app.Project, 'verticesL'))], ...
                ['envelope ' tick(has(app.Project, 'vertices_SCE_R') || ...
                                  has(app.Project, 'vertices_SCE_L'))]}, dot);
        end

        function txt = countLine(app)
            txt = sprintf('%d arrays %s %d contacts %s %d planned', ...
                numel(fieldOrEmpty(app.Project, 'electrodes')), char(183), ...
                countContacts(app.Project), char(183), ...
                numel(fieldOrEmpty(app.Project, 'targets')));
        end

        function drawPickMarker(app, ax)
            % where the last click landed, so a taken slice can be seen to
            % have been taken
            if isempty(app.PickPoint), return, end
            t = app.Theme;
            line(ax, app.PickPoint(1), app.PickPoint(2), app.PickPoint(3), ...
                'Marker', 'o', 'MarkerSize', 9, 'LineWidth', 2, ...
                'Color', t.cross, 'LineStyle', 'none', ...
                'PickableParts', 'none');
        end

        function drawContacts3D(app, ax, x, y, z, col)
            %DRAWCONTACTS3D  Contacts, as dots or as spheres.
            %
            %   A dot is a flat disc that the lights do not touch, the same
            %   size however far away it is, and it reads as a marker on a
            %   plot. A sphere is a thing in the room: it takes the light
            %   the brain takes, it shrinks with distance, and it is hidden
            %   by what is in front of it. That is most of the difference
            %   between a plot of a brain and a picture of one.
            %
            %   The radius is in millimetres, so a contact is shown at a
            %   size rather than at a number of pixels and shrinks with
            %   distance like everything else. 2 mm is a marker, not a
            %   measurement: an exposed subdural contact is about that
            %   across, and a depth contact is smaller, but one size that
            %   can be seen beats two that cannot.
            x = x(:); y = y(:); z = z(:);

            if ~strcmp(app.contactShape(), 'Spheres') || ...
                    numel(x) + app.SphereCount > 600
                % Dots, either because they were asked for or because a
                % sphere each would be hundreds of surfaces - a planning
                % grid can hold a lot of points, and a view that takes
                % seconds to turn is worse than a flat marker.
                c = defaultColors();
                scatter3(ax, x, y, z, c.electrodesSize3D, col, ...
                    c.electrodesMarker3D, 'filled');
                return
            end

            [ux, uy, uz] = sphere(14);
            r = 2;
            for i = 1:numel(x)
                h = surface(ax, x(i) + r*ux, y(i) + r*uy, z(i) + r*uz, ...
                    'FaceColor', col, 'EdgeColor', 'none', ...
                    'FaceLighting', 'gouraud', 'PickableParts', 'none');
                h.AmbientStrength          = 0.30;
                h.DiffuseStrength          = 0.80;
                h.SpecularStrength         = 0.45;
                h.SpecularExponent         = 12;
                h.SpecularColorReflectance = 0.3;
            end
            app.SphereCount = app.SphereCount + numel(x);
        end

        function [x, y, z] = contactCoords(app, array)
            %CONTACTCOORDS  Where to draw an array: as found, or projected.
            %
            %   A subdural grid is recorded where the CT puts it, which is
            %   outside the pial surface by a millimetre or two - the dura,
            %   the fluid, and the brain having shifted under the opening.
            %   On a folded surface those millimetres are enough for a
            %   contact to sit down inside a sulcus and be hidden by the
            %   gyri beside it, which reads as the contacts having gone
            %   missing rather than as them being where they are.
            %
            %   The toolbox's own answer is the projection: the positions
            %   carried onto the smoothed cortical envelope, which is what
            %   IELEC.PROJECTARRAYS writes into array.projection. Drawn on
            %   the envelope they sit on the surface and can be seen.
            %
            %   Which of the two is on screen is a choice, never a silent
            %   substitution: a projected position is not where the contact
            %   was found.
            x = array.x; y = array.y; z = array.z;
            if ~app.checked('projected'), return, end
            if ~isfield(array, 'projection') || isempty(array.projection)
                return
            end
            q = array.projection{1};
            if ~isfield(q, 'x') || isempty(q.x) || numel(q.x) ~= numel(x)
                return
            end
            x = q.x; y = q.y; z = q.z;
        end

        function a = surfaceOpacity(app)
            %SURFACEOPACITY  How see-through the surfaces are, 0 to 1.
            %
            %   It starts at 0.5, which is where the old window's alpha
            %   slider starts, and it has to be a control rather than a
            %   constant: an opaque surface hides every depth contact
            %   inside it, and a see-through one is harder to read the
            %   shape of. Neither is right for both jobs.
            a = app.SurfaceAlpha;
            if isfield(app.Controls, 'opacity') && isvalid(app.Controls.opacity)
                a = app.Controls.opacity.Value;
            end
            a = min(max(a, 0.05), 1);
        end

        function name = contactShape(app)
            name = 'Spheres';
            if isfield(app.Controls, 'model3d') && ...
                    isvalid(app.Controls.model3d)
                name = app.Controls.model3d.Value;
            end
        end

        function n = drawSlicePlanes(app, ax)
            %DRAWSLICEPLANES  The three 2-D views, where they actually are.
            %
            %   What 3D Slicer shows and the old window did not: the slices
            %   placed in space, so a contact can be seen against the
            %   anatomy it sits in rather than against a separate picture of
            %   it. The pixels are the same blend the 2-D views draw, so
            %   mixing, windowing and the CT edge reach this view too.
            %
            %   The slice is taken unturned here, because it is not being
            %   read on a screen - it is being laid on a surface whose four
            %   corners say which way round it goes. Rows run along the
            %   first in-plane axis, columns along the second, and the
            %   corners are built in that order; MESH2ANATSPACE puts them
            %   in millimetres, which is the space the brain is drawn in.
            n  = 0;
            bb = app.brainVoxelBox();

            for pl = 1:3
                v       = app.Voxel(pl);
                inPlane = setdiff(1:3, pl);
                a = inPlane(1);
                b = inPlane(2);

                % cropped to the brain, not the head. A slice taken across
                % the whole volume brings the face and the skull with it,
                % and a jaw in the 3-D view is not what anyone is looking
                % at - it also boxes the brain in behind three full-size
                % walls.
                idx     = cell(1,3);
                idx{pl} = v;
                idx{a}  = bb(1,a):bb(2,a);
                idx{b}  = bb(1,b):bb(2,b);
                img     = squeeze(app.Mixed(idx{:}, :));

                X = zeros(2); Y = zeros(2); Z = zeros(2);
                aEnds = bb(:,a)';
                bEnds = bb(:,b)';
                for i = 1:2
                    for j = 1:2
                        c     = zeros(1,3);
                        c(pl) = v;
                        c(a)  = aEnds(i);
                        c(b)  = bEnds(j);
                        m = mesh2AnatSpace(c, app.Project.S2);
                        X(i,j) = m(1); Y(i,j) = m(2); Z(i,j) = m(3);
                    end
                end

                surface(ax, X, Y, Z, 'CData', img, ...
                    'FaceColor', 'texturemap', 'EdgeColor', 'none', ...
                    'FaceLighting', 'none', 'PickableParts', 'none');
                n = n + 1;
            end
        end

        function middle = brainMiddle(app)
            %BRAINMIDDLE  The centre of the brain surfaces, in millimetres.
            lo = [ inf  inf  inf];
            hi = [-inf -inf -inf];
            for f = {'verticesR', 'verticesL', ...
                     'vertices_SCE_R', 'vertices_SCE_L'}
                if isfield(app.Project, f{1}) && ~isempty(app.Project.(f{1}))
                    V  = app.Project.(f{1});
                    lo = min(lo, min(V, [], 1));
                    hi = max(hi, max(V, [], 1));
                end
            end
            if any(~isfinite([lo hi]))
                middle = [0 0 0];
            else
                middle = (lo + hi) / 2;
            end
        end

        function bb = brainVoxelBox(app)
            %BRAINVOXELBOX  The voxels the brain surface spans, as [lo; hi].
            %
            %   From the surfaces the project carries rather than from what
            %   happens to be drawn, so that it does not depend on the order
            %   things are put in the view. The whole volume when there is
            %   no surface to go by.
            D  = size(app.Project.T1.img);
            D  = D(1:3);
            bb = [1 1 1; D];

            V = [];
            for f = {'verticesR', 'verticesL', ...
                     'vertices_SCE_R', 'vertices_SCE_L'}
                if isfield(app.Project, f{1}) && ~isempty(app.Project.(f{1}))
                    V = [V; app.Project.(f{1})]; %#ok<AGROW>
                end
            end
            if isempty(V), return, end

            m  = AnatSpace2Mesh(V, app.Project.S2);
            lo = max(floor(min(m, [], 1)), [1 1 1]);
            hi = min(ceil( max(m, [], 1)), D);
            if any(hi <= lo), return, end
            bb = [lo; hi];
        end

        function n = patchHemisphere(app, ax, side, withAtlas, which)
            %PATCHHEMISPHERE  One hemisphere, grey or coloured by the atlas.
            %
            %   WHICH is 'pial' for the folded surface or 'envelope' for the
            %   smooth cortical envelope the toolbox builds from it - the
            %   same pair the old window offers, under the names it uses in
            %   the file: verticesR and vertices_SCE_R.
            %
            %   The colours, when there are any, are the caches the file
            %   carried and IELEC.OPENPROJECT handed back - computing them
            %   again for a large parcellation is seconds. They are per
            %   pial vertex, so they only go on the pial surface.
            n = 0;
            if nargin < 5, which = 'pial'; end
            if strcmp(which, 'envelope')
                vName = ['vertices_SCE_' side];
                fName = ['faces_SCE_' side];
                withAtlas = false;
            else
                vName = ['vertices' side];
                fName = ['faces' side];
            end
            if ~isfield(app.Project, vName) || isempty(app.Project.(vName))
                return
            end

            h = patch(ax, 'Vertices', app.Project.(vName), ...
                          'Faces',    app.Project.(fName), ...
                          'LineStyle', 'none');

            cache = ['AnnotColor_' side];
            if withAtlas && isfield(app.Caches, cache) && ...
                    ~isempty(app.Caches.(cache))
                h.FaceVertexCData = app.Caches.(cache);
                h.FaceColor = 'interp';
            else
                h.FaceColor = [0.88 0.85 0.82];  % mvis.m's grey, warmed
            end
            h.FaceAlpha = app.surfaceOpacity();

            % Matte, not plastic. MATLAB's own presets leave a surface
            % either flat ('dull', almost no shape) or shiny ('shiny',
            % a highlight that reads as wet plastic). These are a high
            % roughness: most of the light diffuse, a trace of specular
            % with a tight exponent, and little ambient so that the gyri
            % keep their shadows. The lights do the rest.
            h.FaceLighting             = 'gouraud';
            h.BackFaceLighting         = 'reverselit';
            h.AmbientStrength          = 0.38;
            h.DiffuseStrength          = 0.85;
            h.SpecularStrength         = 0.12;
            h.SpecularExponent         = 20;
            h.SpecularColorReflectance = 0.0;

            % A click on the surface is how a slice is taken - see
            % SURFACECLICKED. The patch carries its own vertices, so the
            % callback has everything it needs without looking them up.
            h.ButtonDownFcn = @(src,~) app.surfaceClicked(src);
            n = 1;
        end

        function aimAtContacts(app, ax)
            %AIMATCONTACTS  Open the view looking at the electrodes.
            %
            %   The old window opens at a fixed three-quarter view, which
            %   for half of patients is the side the electrodes are not on,
            %   and the first thing to do is turn the brain round. Here the
            %   camera starts on the side they are: the direction from the
            %   middle of the brain to the middle of the contacts.
            %
            %   MATLAB's azimuth is measured round z from the -y axis, and
            %   the elevation above the xy plane, which is what the two
            %   ATAN2D below are. The elevation is held back from straight
            %   overhead, because a brain seen from directly above is a
            %   shape nobody recognises.
            %
            %   With no contacts yet - a new project, which is where this
            %   window will usually start - it is the old window's view.
            pts    = [];
            arrays = fieldOrEmpty(app.Project, 'electrodes');
            for k = 1:numel(arrays)
                if ~isfield(arrays{k}, 'x') || isempty(arrays{k}.x), continue, end
                [cx, cy, cz] = app.contactCoords(arrays{k});
                pts = [pts; cx(:) cy(:) cz(:)]; %#ok<AGROW>
            end
            if isempty(pts)
                view(ax, -135, 25);
                return
            end

            % the brain's own middle, from the surfaces rather than from
            % the axes: the aiming happens before the framing, so that the
            % zoom is applied at the viewpoint it will be seen from
            middle = app.brainMiddle();
            d      = mean(pts, 1) - middle;
            if norm(d) < eps
                view(ax, -135, 25);
                return
            end

            az = atan2d(d(1), -d(2));
            el = atan2d(d(3), hypot(d(1), d(2)));
            el = max(min(el, 45), -25);
            view(ax, az, el);
        end

        function frameOnSurfaces(~, ax)
            %FRAMEONSURFACES  Put the camera round what is drawn as a surface.
            %
            %   The surfaces' own box, not a cube around it: a cube is as
            %   wide as the brain is long, and the view then has to fit
            %   that width, which leaves the brain small with air above and
            %   below it. The equal data aspect ratio is what keeps the
            %   shape honest; the limits only say what to look at.
            h = findobj(ax, 'Type', 'patch');
            if isempty(h), return, end

            lo = [ inf  inf  inf];
            hi = [-inf -inf -inf];
            for k = 1:numel(h)
                V  = h(k).Vertices;
                lo = min(lo, min(V, [], 1));
                hi = max(hi, max(V, [], 1));
            end
            if any(~isfinite([lo hi])), return, end

            middle = (lo + hi) / 2;
            half   = (hi - lo) / 2 * 1.04;       % a little air round it
            half   = max(half, 1);               % never a flat box
            ax.XLim = middle(1) + [-half(1) half(1)];
            ax.YLim = middle(2) + [-half(2) half(2)];
            ax.ZLim = middle(3) + [-half(3) half(3)];
            ax.DataAspectRatio = [1 1 1];

            % the fit leaves air on the long side; take some of it back,
            % but not so much that turning the brain pushes it out of frame
            camzoom(ax, 1.1);
        end

        function lightRig(~, ax)
            %LIGHTRIG  Three lights, the way a render is lit.
            %
            %   A single headlight - which is what camlight('headlight')
            %   gives, and what the old window used - puts the light where
            %   the eye is, so nothing casts a shadow towards the viewer
            %   and the shape flattens out. Three fixed lights instead: a
            %   warm key above and in front, a cool fill opposite it at a
            %   third of the strength, and a dim one from below to keep the
            %   underside from going black. A light's strength in MATLAB is
            %   its colour, which is why the fill is a dark grey-blue
            %   rather than white.
            %
            %   They are infinite and fixed in the data, not on the camera,
            %   so turning the brain moves the light across it.
            delete(findobj(ax, 'Type', 'light'));
            light(ax, 'Style', 'infinite', 'Position', [ 1.0  1.0  0.8], ...
                  'Color', [1.00 0.96 0.90]);
            light(ax, 'Style', 'infinite', 'Position', [-1.0 -0.6  0.3], ...
                  'Color', [0.34 0.38 0.46]);
            light(ax, 'Style', 'infinite', 'Position', [-0.3  0.4 -1.0], ...
                  'Color', [0.26 0.25 0.24]);
        end

        function yes = checked(app, name)
            yes = isfield(app.Controls, name) && ...
                  isvalid(app.Controls.(name)) && ...
                  logical(app.Controls.(name).Value);
        end

        function redrawAll(app)
            app.redrawPlanes();
            app.draw3D();
        end

        function clusterPressed(app)
            %CLUSTERPRESSED  Split the selected voxels into contacts.
            if ~app.hasProject(), return, end
            n = app.Controls.nContacts.Value;
            try
                [app.Project, app.Work, quality] = ielec.cluster( ...
                    struct('nClusters', n), app.Project, app.Work);
            catch err
                app.showMessage(err.message);
                return
            end

            % what the layer hands back about the fit, for the user to judge
            said = sprintf('%d contacts in progress', ...
                size(app.Work.GS, 1));
            if isstruct(quality) && isfield(quality, 'meanDistance')
                said = sprintf('%s, %.1f mm apart on average', said, ...
                    quality.meanDistance);
            end
            app.showMessage([said '.']);
            app.redrawAll();
        end

        function addHere(app, group, word)
            %ADDHERE  Put a contact or an anchor where the cursor is.
            if ~app.hasProject(), return, end
            mm = mesh2AnatSpace(app.Voxel, app.Project.S2);
            try
                [app.Project, app.Work] = ielec.addCoordinate( ...
                    struct('coordinate', mm, 'group', group), ...
                    app.Project, app.Work);
            catch err
                app.showMessage(err.message);
                return
            end
            app.showMessage(sprintf('%s added at x %.1f  y %.1f  z %.1f.', ...
                [upper(word(1)) word(2:end)], mm));
            app.redrawAll();
        end

        function removeHere(app)
            %REMOVEHERE  Take out the contact nearest the cursor.
            if ~app.hasProject(), return, end
            mm = mesh2AnatSpace(app.Voxel, app.Project.S2);
            try
                [app.Project, app.Work, gone] = ielec.removeCoordinate( ...
                    struct('coordinate', mm), app.Project, app.Work);
            catch err
                app.showMessage(err.message);
                return
            end
            if gone
                app.showMessage('Contact removed.');
            else
                % the layer reports rather than raises, so say so plainly
                app.showMessage('Nothing within 2 mm of the cursor.');
            end
            app.redrawAll();
        end

        function clearHere(app)
            if ~app.hasProject(), return, end
            try
                [app.Project, app.Work] = ielec.clearCoordinates( ...
                    [], app.Project, app.Work);
            catch err
                app.showMessage(err.message);
                return
            end
            app.showMessage('Cleared. Undo brings them back.');
            app.redrawAll();
        end

        function undoHere(app)
            if ~app.hasProject(), return, end
            try
                [app.Project, app.Work] = ielec.undoCoordinates( ...
                    [], app.Project, app.Work);
            catch err
                app.showMessage(err.message);
                return
            end
            % Undo is a swap: pressing it again puts them back as they were
            app.showMessage(sprintf('Undone - %d contacts in progress.', ...
                size(fieldOrNumeric(app.Work, 'GS'), 1)));
            app.redrawAll();
        end

        function yes = hasProject(app)
            yes = ~isempty(app.Mixed);
            if ~yes
                app.showMessage('Open a project first.');
            end
        end

        function remix(app)
            %REMIX  Blend the volumes again and redraw - the slider moved.
            if isempty(app.Mixed), return, end
            if isfield(app.Controls, 'mixing')
                app.MixValue = app.Controls.mixing.Value;
            end
            app.Mixed = app.blendVolumes();
            app.redrawPlanes();
        end

        function showMessage(app, line)
            app.MessageBox.Value = [app.MessageBox.Value; {line}];
        end

        % ----------------------------------------------------------
        function buildMenus(app)
            % The design notes keep as a menu what is an action or a
            % setting, rather than a control belonging to one step. Each
            % item names the layer function it will call, so the list can be
            % checked against the layer rather than guessed at.
            f = app.UIFigure;

            m = uimenu(f, 'Text', '&Project');
            app.menuItems(m, {
                'New project',              'ielec.newProject'
                'Open project...',          '@open'
                'Save project',             'ielec.saveProject'
                '---',                      ''
                'Load CT...',               'ielec.loadCT'
                'Load brain mask...',       'ielec.loadMask'
                'Use a mask of ones',       'ielec.dummyMask'
                'Load atlas...',            'ielec.loadAnatomy'
                'Load surfaces...',         'ielec.loadSurfaces'
                'Load annotations...',      'ielec.loadAnnotations'
                'Build the envelope',       'ielec.buildEnvelope'
                'Trim the images...',       'ielec.trimImages'
                '---',                      ''
                'Space: native or MNI...',  ''
                'Processing history...',    ''});

            m = uimenu(f, 'Text', '&Settings');
            app.menuItems(m, {
                'Layout...',                ''
                'Colours and fonts...',     ''
                'Options...',               'ielec.setOptions'});

            m = uimenu(f, 'Text', '&Help');
            app.menuItems(m, {
                'Help',                     ''
                'About iElectrodes',        ''});
        end

        function menuItems(app, parent, rows)
            for k = 1:size(rows, 1)
                if strcmp(rows{k,1}, '---'), continue, end
                item = uimenu(parent, 'Text', rows{k,1}, 'Enable', 'off');
                if strcmp(rows{k,2}, '@open')
                    item.Enable = 'on';
                    item.MenuSelectedFcn = @(~,~) app.openProject();
                    rows{k,2} = 'ielec.openProject';
                end
                if k > 1 && strcmp(rows{k-1,1}, '---')
                    item.Separator = 'on';
                end
                if ~isempty(rows{k,2})
                    item.Tooltip = ['will call ' rows{k,2}];
                end
            end
        end

        % ----------------------------------------------------------
        function buildTopBar(app)
            app.TopBar = uigridlayout(app.Root, [1 4]);
            app.TopBar.Layout.Row  = 1;
            app.TopBar.ColumnWidth = {130, 'fit', '1x', 'fit'};
            app.TopBar.RowHeight   = {'1x'};
            app.TopBar.Padding     = [0 0 0 0];
            app.TopBar.ColumnSpacing = 14;

            name = uilabel(app.TopBar, 'Text', 'iElectrodes 2');
            name.Layout.Column = 1;
            name.FontSize = 16;
            name.FontWeight = 'bold';

            % the five steps. Toggle buttons rather than a uitabgroup,
            % because a tab group would take the views with it and the
            % whole point is that they stay.
            steps = uigridlayout(app.TopBar, [1 numel(app.STEPS)]);
            steps.Layout.Column = 2;
            steps.ColumnWidth = repmat({86}, 1, numel(app.STEPS));
            steps.RowHeight   = {28};
            steps.Padding     = [0 0 0 0];
            steps.ColumnSpacing = 4;
            for k = 1:numel(app.STEPS)
                s = app.STEPS{k};
                b = uibutton(steps, 'state', 'Text', s);
                b.Layout.Column = k;
                b.Tooltip = sprintf('Step %d', k);
                b.ValueChangedFcn = @(src,~) app.stepClicked(s, src);
                app.StepButtons.(s) = b;
            end

            app.FileLabel = uilabel(app.TopBar, 'Text', '(no project open)');
            app.FileLabel.Layout.Column = 3;
            app.FileLabel.HorizontalAlignment = 'right';

            app.ThemeSwitch = uiswitch(app.TopBar, 'slider', ...
                'Items', {'light', 'dark'});
            app.ThemeSwitch.Layout.Column = 4;
            app.ThemeSwitch.Value = 'light';
            if app.Theme.isDark, app.ThemeSwitch.Value = 'dark'; end
            app.ThemeSwitch.ValueChangedFcn = @(src,~) app.switchTheme(src.Value);
        end

        function stepClicked(app, name, src)
            src.Value = true;          % a step cannot be switched off
            app.showStep(name);
        end

        % ----------------------------------------------------------
        function buildLeft(app)
            app.LeftCol = uigridlayout(app.Body, [2 1]);
            app.LeftCol.Layout.Column = 1;
            app.LeftCol.RowHeight   = {'1x', 150};
            app.LeftCol.ColumnWidth = {'1x'};
            app.LeftCol.Padding     = [0 0 0 0];
            app.LeftCol.RowSpacing  = 10;

            % three planes above, the voxels and the 3-D below - the
            % mock-up's arrangement, and the reason the top row is three is
            % that a plane is read against the other two
            app.ViewGrid = uigridlayout(app.LeftCol, [2 6]);
            app.ViewGrid.Layout.Row = 1;
            app.ViewGrid.RowHeight   = {'1x', '1x'};
            app.ViewGrid.ColumnWidth = repmat({'1x'}, 1, 6);
            app.ViewGrid.Padding     = [0 0 0 0];
            app.ViewGrid.RowSpacing    = 10;
            app.ViewGrid.ColumnSpacing = 10;

            spec = {
                'zPlane',    'Axial (Z)',          1, [1 2], '-- of --'
                'yPlane',    'Coronal (Y)',        1, [3 4], '-- of --'
                'xPlane',    'Sagittal (X)',       1, [5 6], '-- of --'
                'voxels',    'CT voxels above threshold', 2, [1 3], 'no CT loaded'
                'threeD',    'Surfaces and contacts', 2, [4 6], 'nothing to show'
                };
            for k = 1:size(spec, 1)
                p = uipanel(app.ViewGrid, 'Title', spec{k,2});
                p.Layout.Row    = spec{k,3};
                p.Layout.Column = spec{k,4};
                g = uigridlayout(p, [2 1]);
                g.RowHeight   = {'1x', 16};
                g.ColumnWidth = {'1x'};
                g.Padding     = [3 3 3 3];
                g.RowSpacing  = 2;
                ax = uiaxes(g);
                ax.Layout.Row = 1;
                ax.Toolbar.Visible = 'off';
                disableDefaultInteractivity(ax);
                ax.XTick = []; ax.YTick = [];
                cap = uilabel(g, 'Text', spec{k,5});
                cap.Layout.Row = 2;
                cap.FontSize = 10;
                cap.HorizontalAlignment = 'right';
                app.Views.(spec{k,1}) = struct('panel', p, 'axes', ax, ...
                                               'caption', cap);
            end

            % "Info box: Current coordinates and current anatomical
            % label. Place it next to the Messages box. Always visible." -
            % the design notes, which is why it is a row of the window and
            % not a section that can be collapsed over.
            bottom = uigridlayout(app.LeftCol, [1 2]);
            bottom.Layout.Row    = 2;
            bottom.ColumnWidth   = {260, '1x'};
            bottom.RowHeight     = {'1x'};
            bottom.Padding       = [0 0 0 0];
            bottom.ColumnSpacing = 10;

            [info, ig] = app.panelWithHeader(bottom, 'cursor', 'Cursor');
            info.Layout.Column = 1;
            app.InfoLabel = uilabel(ig, 'Text', ...
                sprintf('x --    y --    z --\n(no anatomical label)'));
            app.InfoLabel.VerticalAlignment = 'top';
            app.setSizer('cursor', @(~) app.sizeFootRow());

            [msg, mg] = app.panelWithHeader(bottom, 'messages', 'Messages');
            msg.Layout.Column = 2;
            app.MessageBox = uitextarea(mg, 'Editable', 'off', 'Value', ...
                {'iElectrodes 2 - open a project from the Project menu.'});
            app.setSizer('messages', @(~) app.sizeFootRow());
        end

        % ----------------------------------------------------------
        function buildRight(app)
            app.RightCol = uigridlayout(app.Body, [3 1]);
            app.RightCol.Layout.Column = 2;
            app.RightCol.RowHeight   = {240, '1x', 'fit'};
            app.RightCol.ColumnWidth = {'1x'};
            app.RightCol.Padding     = [0 0 0 0];
            app.RightCol.RowSpacing  = 10;

            % the contacts stay whatever step is current, because every step
            % is about them
            [cp, cg] = app.panelWithHeader(app.RightCol, 'contacts', 'Contacts');
            cp.Layout.Row = 1;
            app.ContactTable = uitable(cg, 'Data', cell(0,4), ...
                'ColumnName', {'Label', 'x', 'y', 'z'});
            app.ContactTable.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.setSizer('contacts', @(open) app.sizeContactsPanel(open));

            app.StepStack = uigridlayout(app.RightCol, [1 1]);
            app.StepStack.Layout.Row  = 2;
            app.StepStack.ColumnWidth = {'1x'};
            app.StepStack.Padding     = [0 0 0 0];
            app.StepStack.RowSpacing  = 8;
            app.StepStack.Scrollable  = 'on';

            app.ViewBlock = uigridlayout(app.RightCol, [3 1]);
            app.ViewBlock.Layout.Row  = 3;
            app.ViewBlock.ColumnWidth = {'1x'};
            app.ViewBlock.RowHeight   = {'fit', 'fit', 'fit'};
            app.ViewBlock.Padding     = [0 0 0 0];
            app.ViewBlock.RowSpacing  = 8;
            app.buildViewBlock();
        end

        function sizeContactsPanel(app, open)
            if open
                app.RightCol.RowHeight{1} = 240;
            else
                app.RightCol.RowHeight{1} = 46;
            end
        end

        % ----------------------------------------------------------
        function buildViewBlock(app)
            % "Visualization and Navigation" in the design notes. It is a
            % peer of Localization there, not one of the five steps,
            % because it applies whatever step is current - so it sits
            % under the step's own controls, reachable from all of them and
            % in the way of none. Collapsed to start, which is what the
            % notes ask for by calling the 2D and 3D blocks collapsible.
            app.addSection(0, 'view2d', '2D view', {
                'Show atlas',                 'check',  'showAtlas'
                'MRI / CT blend',             'slider', 'mixing'
                'Show CT edge',               'check',  'ctEdge'
                'Show crosshair',             'check',  'crosshair'
                'Radiological convention',    'check',  'radiological'}, ...
                app.ViewBlock);

            app.addSection(0, 'view3d', '3D view', {
                'Take a slice by clicking',   'check', 'pickSlice'
                'Show the slices in space',   'check', 'slicePlanes'
                'Pial surfaces (L/R)',        'check',  'pial'
                'Surface opacity',            'slider', 'opacity'
                'Atlas on the surface',       'check', 'atlasSurface'
                'Smoothed surface (L/R)',     'check', 'envelope3d'
                'Projected to the envelope',  'check', 'projected'
                'Planned targets',            'check', 'planned'
                'Contact labels',             'check', 'contactLabels'
                'Contacts drawn as',          'model', 'model3d'}, app.ViewBlock);

            app.addSection(0, 'navigate', 'Navigation', {
                'Arrays',                     'arrays', ''
                'All contacts, not just this slice', 'check', 'collapse'}, ...
                app.ViewBlock);

            % WHAT THE 3-D VIEW STARTS AS
            %
            % Where the old window starts, read out of electrodes_gui.fig
            % rather than chosen here: both hemispheres shown, the
            % annotation on, the surfaces half see-through, the envelope
            % off, projections off, the planning overlay on. A new window
            % that opens a familiar project onto an unfamiliar picture is a
            % change nobody asked for.
            %
            % What is different is how it is drawn, not what is shown:
            % spheres rather than flat markers, no axes box, three fixed
            % lights rather than a headlight, and a camera framed on the
            % surfaces and aimed at the electrodes.
            app.Controls.pial.Value         = true;
            app.Controls.planned.Value      = true;
            app.Controls.model3d.Value      = 'Spheres';
            app.Controls.opacity.Value      = app.SurfaceAlpha;

            app.Controls.atlasSurface.Value = true;

            % Off to start. The three planes span the whole volume, so
            % with all of them on they box the brain in and it is the
            % planes you see - which is true of 3D Slicer too, where
            % turning slices on and off is half of using the 3-D view.
            % The surfaces are what this view is for; the slices are a
            % tick away when a contact has to be seen against anatomy.
            app.Controls.slicePlanes.Value = false;

            for n = {'slicePlanes', 'pial', 'atlasSurface', ...
                     'contactLabels', 'envelope3d', 'pickSlice', 'planned'}
                app.Controls.(n{1}).ValueChangedFcn = @(~,~) app.draw3D();
            end
            % this one moves the contacts in both the 2-D and the 3-D views
            app.Controls.projected.ValueChangedFcn = @(~,~) app.redrawAll();
            app.Controls.model3d.ValueChangedFcn = @(~,~) app.draw3D();
            app.Controls.opacity.ValueChangedFcn = @(~,~) app.draw3D();

            % Where the old window starts, read out of electrodes_gui.fig
            % rather than chosen here: the parcellation box is ticked, so is
            % the collapse box, and the MRI-CT slider sits at 0.5. A new
            % window that opens a project onto a different picture than the
            % one people know is a change nobody asked for.
            app.Controls.crosshair.Value = true;
            app.Controls.showAtlas.Value = true;
            app.Controls.collapse.Value  = true;
            app.Controls.mixing.Value    = 0.5;
            app.MixValue                 = 0.5;

            for n = {'showAtlas', 'crosshair', 'collapse'}
                app.Controls.(n{1}).ValueChangedFcn = @(~,~) app.redrawPlanes();
            end
            % these two change the blend itself, so the volume is mixed again
            for n = {'mixing', 'ctEdge'}
                app.Controls.(n{1}).ValueChangedFcn = @(~,~) app.remix();
            end

            % "Radiological convention" is left alone on purpose. Which way
            % round the planes are drawn is the one thing in this window
            % that can be wrong without looking wrong, and the old window
            % has no such switch to copy - it draws one way. Guessing which
            % side of it the toolbox is on is not a thing to guess.
            app.Controls.radiological.Enable = 'off';

            for n = {'view2d', 'view3d', 'navigate'}
                app.toggleSection(n{1});       % start collapsed
            end
        end

        % ----------------------------------------------------------
        function showStep(app, name)
            app.Step = name;
            for k = 1:numel(app.STEPS)
                s = app.STEPS{k};
                app.StepButtons.(s).Value = strcmp(s, name);
            end

            delete(allchild(app.StepStack));
            % only the step's own sections go; the view block's survive,
            % because they belong to no step
            keep = struct();
            f = fieldnames(app.Sections);
            for i = 1:numel(f)
                if isvalid(app.Sections.(f{i}).panel)
                    keep.(f{i}) = app.Sections.(f{i});
                end
            end
            app.Sections = keep;

            % the same for the named controls: a step's own go with it
            f = fieldnames(app.Controls);
            for i = 1:numel(f)
                if ~all(isvalid(app.Controls.(f{i})))
                    app.Controls = rmfield(app.Controls, f{i});
                end
            end

            % what each step asks for, from the design notes
            switch name
                case 'Localize'
                    spec = {
                        'threshold', 'CT threshold', {
                            'CT threshold, low and high', 'range', 'ctRange'
                            'Denoise (voxels)',           'spin',  'denoise'
                            'Brush to select voxels',     'state', 'selectVoxels'}
                        'cluster',   'Clustering and indexing', {
                            'Contacts to find',           'spin',   'nContacts'
                            'Cluster',                    'accent', 'clusterNow'
                            'Add contact by hand',        'button', 'addByHand'
                            'Delete / Clear / Undo',      'triple', 'editContacts'
                            'Index the contacts',         'button', 'indexNow'}
                        'gridfit',   'Fit a grid model (GridFit)', {
                            'Type',                       'segment', 'arrayType'
                            'Rows / Columns / Spacing',   'numbers', ''
                            'Add anchor by hand',         'button',  ''
                            'Fit the model',              'accent',  ''}
                        };
                case 'Arrays'
                    spec = {
                        'name',     'Name the contacts', {
                            'Base name',                  'edit'
                            'Name / Name from a list',    'pair'
                            'Rotate / Flip',              'pair'
                            'Index by hand',              'button'}
                        'arraylist', 'Arrays in this project', {
                            'arrays',                     'table'
                            'Remove array',               'button'}
                        };
                case 'Anatomy'
                    spec = {
                        'atlas',    'Anatomical labelling', {
                            'Anatomy from',               'segment',  'anatomySpace'
                            'Inclusion distance, mm',     'spin',     ''
                            'Inclusion mode',             'dropdown', 'inclusionMode'
                            'Label the contacts',         'accent',   ''}
                        'shift',    'Brain shift', {
                            'Build the envelope',         'button'
                            'Project the arrays',         'accent'}
                        };
                case 'Planning'
                    spec = {
                        'newplan',  'A new target', {
                            'Rows / Columns / Spacing',   'numbers'
                            'New planning grid',          'accent'
                            'New depth electrode',        'button'}
                        'place',    'Place and aim', {
                            'Move',                       'triple'
                            'Rotate',                     'pair'
                            'Azimuth / Elevation',        'pair'
                            'Fit to the envelope',        'button'}
                        };
                case 'Export'
                    spec = {
                        'exp',      'Write the contacts out', {
                            'Format',                     'dropdown', 'exportFormat'
                            'Coordinates',                'segment',  'exportCoordinates'
                            'Write the file',             'accent',   ''}
                        };
            end

            heights = cell(1, size(spec,1));
            for k = 1:size(spec, 1)
                app.addSection(k, spec{k,1}, spec{k,2}, spec{k,3});
                heights{k} = 'fit';
            end
            app.StepStack.RowHeight = heights;
            if app.Brushing
                % the button that turned brushing on has just been deleted,
                % so nothing is left to turn it off with
                brush(app.UIFigure, 'off');
                app.Brushing = false;
            end
            app.wireStep(name);
            app.applyTheme();
        end

        function wireStep(app, name)
            % What a control does is the window's, not the section builder's:
            % the builder makes the shape, this says what it means.
            switch name
                case 'Localize'
                    r = app.Controls.ctRange;
                    % A step's controls are built fresh each time it is
                    % shown, so put back what was set the last time it was:
                    % otherwise the boxes would read 2500 and 4000 over a
                    % voxel view made with something else, and a number on
                    % screen that does not describe what is beside it is
                    % worse than no number.
                    if ~isempty(app.Thr)
                        r(1).Value = app.Thr(1);
                        r(2).Value = app.Thr(2);
                        app.Controls.denoise.Value = app.DenoiseK;
                        % and the voxels those numbers describe, which were
                        % not worked out while this step was hidden
                        if isempty(app.Scatter), app.applyThreshold(); end
                    end
                    r(1).ValueChangedFcn = @(~,~) app.applyThreshold();
                    r(2).ValueChangedFcn = @(~,~) app.applyThreshold();
                    app.Controls.denoise.ValueChangedFcn = ...
                        @(~,~) app.applyThreshold();
                    app.Controls.selectVoxels.ValueChangedFcn = ...
                        @(src,~) app.selectVoxelsPressed(src);
                    app.Controls.denoise.Limits = [1 5];   % as the old slider

                    app.Controls.nContacts.Limits = [1 Inf];
                    app.Controls.clusterNow.ButtonPushedFcn = ...
                        @(~,~) app.clusterPressed();
                    app.Controls.addByHand.ButtonPushedFcn = ...
                        @(~,~) app.addHere('contacts', 'contact');

                    % Delete, Clear and Undo, left to right
                    edit = app.Controls.editContacts;
                    edit(1).ButtonPushedFcn = @(~,~) app.removeHere();
                    edit(2).ButtonPushedFcn = @(~,~) app.clearHere();
                    edit(3).ButtonPushedFcn = @(~,~) app.undoHere();
            end

            % the view block belongs to no step, so it is wired once, the
            % first time its controls exist
            for n = {'pial', 'atlasSurface', 'contactLabels', 'planned', ...
                     'envelope3d', 'pickSlice', 'slicePlanes', 'model3d', ...
                     'projected', 'opacity'}
                if isfield(app.Controls, n{1}) && ...
                        isempty(app.Controls.(n{1}).ValueChangedFcn)
                    app.Controls.(n{1}).ValueChangedFcn = ...
                        @(~,~) app.draw3D();
                end
            end
        end

        function applyThreshold(app)
            %APPLYTHRESHOLD  The CT voxels bright enough to be contacts.
            %
            %   The two numbers are intensities in the CT's own units, which
            %   is what IELEC.THRESHOLDCT takes and what its history records:
            %   a threshold has to mean the same thing without the control
            %   that set it. The old window kept sliders in fractions of the
            %   CT range and converted on the way in; this one does not
            %   convert, so what is on screen is what was recorded.
            if ~app.hasCT(), return, end

            r = app.Controls.ctRange;
            app.Thr      = [r(1).Value, r(2).Value];
            app.DenoiseK = app.Controls.denoise.Value;

            cfg = [];
            cfg.lowThreshold  = app.Thr(1);
            cfg.highThreshold = app.Thr(2);
            cfg.denoiseKernel = app.DenoiseK;
            cfg.maxCount      = app.maxVoxelsToPlot();

            try
                [app.Project, app.Work] = ielec.thresholdCT( ...
                    cfg, app.Project, app.Work);
            catch ME
                app.showMessage(ME.message);
                return
            end
            app.drawVoxels();
        end

        function drawVoxels(app)
            ax = app.Views.voxels.axes;
            cla(ax);
            app.Scatter = [];

            crd = [];
            if isfield(app.Work, 'candidateVoxels')
                crd = app.Work.candidateVoxels;
            end
            if isempty(crd)
                app.Views.voxels.caption.Text = 'nothing above the threshold';
                return
            end

            % coloured by how bright each voxel is, as the old view had it:
            % a contact and a skull screw are both above the threshold and
            % the colour is what tells them apart
            app.Scatter = scatter3(ax, crd(:,1), crd(:,2), crd(:,3), 20, ...
                app.Work.candidateValues, 'o', 'filled');

            % A colourmap, not grey: what separates a contact from a skull
            % screw here is how bright it is, and grey points on a cloud of
            % grey points say nothing. TURBO runs the whole way round, so
            % the brightest band is unmistakable at a glance.
            colormap(ax, turbo);

            % Most candidates sit just above the low threshold, so mapping
            % the colours over the full range leaves nearly all of them in
            % the same dark band. Clipped to the middle 96 per cent, the
            % map spends its range where the voxels actually are.
            sv = sort(double(app.Work.candidateValues(:)));
            lo = sv(max(1, round(0.02 * numel(sv))));
            hi = sv(max(2, round(0.98 * numel(sv))));
            if hi > lo, clim(ax, [lo hi]); end

            % turning the cloud is how an array is told from a skull screw,
            % and it is also how a region is lined up before brushing it
            enableDefaultInteractivity(ax);
            ax.Interactions = [rotateInteraction, zoomInteraction];
            view(ax, -135, 25);
            axis(ax, 'image');
            ax.XTick = []; ax.YTick = []; ax.ZTick = [];
            app.Views.voxels.caption.Text = sprintf('%d voxels', size(crd,1));
        end

        function selectVoxelsPressed(app, src)
            %SELECTVOXELSPRESSED  Brush the voxel view, then take what is brushed.
            %
            %   Down turns brushing on so a region can be dragged out in the
            %   voxel view; up takes what was brushed. The old window had
            %   the brush on the figure toolbar and a separate button; the
            %   design notes take the toolbar away, so the one button is
            %   both halves of the same act.
            if ~app.hasCT() || isempty(app.Scatter)
                src.Value = false;
                app.showMessage('Threshold the CT first - there are no voxels to select.');
                return
            end

            if src.Value
                app.Brushing = true;
                brush(app.UIFigure, 'on');
                src.Text = 'Take the brushed voxels';
                app.showMessage('Brushing on: drag a region in the voxel view.');
                return
            end

            brush(app.UIFigure, 'off');
            app.Brushing = false;
            src.Text = 'Brush to select voxels';

            idx = logical(app.Scatter.BrushData);
            if isempty(idx) || ~any(idx)
                app.showMessage('Nothing was brushed, so nothing was selected.');
                return
            end
            if numel(idx) ~= size(app.Work.candidateVoxels, 1)
                % the plot and the candidates are made together, so this
                % cannot happen; if they ever disagree, refuse rather than
                % take the wrong voxels
                app.showMessage('The brush does not match the voxels shown. Threshold again.');
                return
            end

            [app.Project, app.Work] = ielec.selectVoxels( ...
                struct('indices', idx), app.Project, app.Work);
            app.showMessage(sprintf('%d of %d voxels selected.', ...
                sum(idx), numel(idx)));
            app.Views.voxels.caption.Text = sprintf('%d of %d selected', ...
                sum(idx), numel(idx));
        end

        function yes = hasCT(app)
            yes = ~isempty(app.Mixed) && isfield(app.Project, 'TAC') && ...
                  ~isempty(app.Project.TAC) && isfield(app.Controls, 'ctRange');
        end

        function n = maxVoxelsToPlot(~)
            %MAXVOXELSTOPLOT  How many points the voxel view will take.
            %
            %   From app/config/defaultDisplayOptions.m, which is where the
            %   old window reads it and where the backend's own warning
            %   tells the user to change it. It used to look in
            %   work.options, which is the processing options and has never
            %   held this - so the test never passed, the hard-coded number
            %   was always used, and the warning pointed at a file this
            %   window did not read.
            options = defaultDisplayOptions(struct());
            n = options.scatter3D_elem_limit;
        end

        % ----------------------------------------------------------
        function addSection(app, row, name, title, rows, parent)
            if nargin < 6 || isempty(parent)
                parent = app.StepStack;
            end
            if row == 0
                % row 0 means "the next free one in this container"
                used = 0;
                f = fieldnames(app.Sections);
                for i = 1:numel(f)
                    if app.Sections.(f{i}).parent == parent
                        used = used + 1;
                    end
                end
                row = used + 1;
            end
            p = uipanel(parent);
            p.Layout.Row    = row;
            p.Layout.Column = 1;

            g = uigridlayout(p, [2 1]);
            g.RowHeight   = {24, 'fit'};
            g.ColumnWidth = {'1x'};
            g.Padding     = [8 8 8 8];
            g.RowSpacing  = 6;

            head = uibutton(g, 'Text', headerText(title, true));
            head.Layout.Row = 1;
            head.HorizontalAlignment = 'left';
            head.FontSize = 11;
            head.FontWeight = 'bold';

            inner = uigridlayout(g, [size(rows,1) 1]);
            inner.Layout.Row  = 2;
            inner.ColumnWidth = {'1x'};
            inner.Padding     = [0 0 0 0];
            inner.RowSpacing  = 6;

            h = cell(1, size(rows,1));
            for k = 1:size(rows, 1)
                h{k} = 26;
                nm = '';
                if size(rows, 2) >= 3, nm = rows{k,3}; end
                c = app.makeControl(inner, rows{k,1}, rows{k,2}, nm);
                c.Layout.Row = k;
                if strcmp(rows{k,2}, 'table'), h{k} = 130; end
            end
            inner.RowHeight = h;

            app.Sections.(name) = struct('panel', p, 'head', head, ...
                                         'inner', inner, 'open', true, ...
                                         'row', row, 'parent', parent, ...
                                         'sizer', [], 'title', title);
            head.ButtonPushedFcn = @(~,~) app.toggleSection(name);
        end

        function c = makeControl(app, parent, label, kind, name)
            if nargin < 5, name = ''; end
            switch kind
                case 'button'
                    c = uibutton(parent, 'Text', label);
                case 'accent'
                    c = uibutton(parent, 'Text', label);
                    c.Tag = 'accent';
                case 'state'
                    c = uibutton(parent, 'state', 'Text', label);
                case 'check'
                    c = uicheckbox(parent, 'Text', label);
                case {'pair', 'triple'}
                    % One button per name in the label, not one per the
                    % kind's number. A label with fewer names than buttons
                    % used to put the whole label in every spare one, so
                    % "Move" as a triple came out as three buttons all
                    % saying Move.
                    bits = strsplit(label, {' / ', ' and '});
                    bits = cellfun(@strtrim, bits, 'UniformOutput', false);
                    n    = min(numel(bits), 2 + strcmp(kind, 'triple'));
                    c = uigridlayout(parent, [1 n]);
                    c.Padding = [0 0 0 0];
                    c.ColumnSpacing = 4;
                    for i = 1:n
                        uibutton(c, 'Text', bits{i});
                    end
                case 'range'
                    c = uigridlayout(parent, [1 3]);
                    c.Padding = [0 0 0 0];
                    c.ColumnWidth = {'1x', 70, 70};
                    uilabel(c, 'Text', label);
                    uieditfield(c, 'numeric', 'Value', 2500);
                    uieditfield(c, 'numeric', 'Value', 4000);
                case 'spin'
                    c = uigridlayout(parent, [1 2]);
                    c.Padding = [0 0 0 0];
                    c.ColumnWidth = {'1x', 80};
                    uilabel(c, 'Text', label);
                    uispinner(c, 'Value', 1, 'Limits', [1 Inf]);
                case 'edit'
                    c = uigridlayout(parent, [1 2]);
                    c.Padding = [0 0 0 0];
                    c.ColumnWidth = {'1x', 110};
                    uilabel(c, 'Text', label);
                    uieditfield(c, 'text');
                case 'dropdown'
                    c = uigridlayout(parent, [1 2]);
                    c.Padding = [0 0 0 0];
                    c.ColumnWidth = {'1x', 150};
                    uilabel(c, 'Text', label);
                    items = choicesFor(name);
                    if isempty(items)
                        d = uidropdown(c, 'Items', {'(not decided yet)'});
                        d.Enable = 'off';
                    else
                        uidropdown(c, 'Items', items);
                    end
                case 'numbers'
                    % three small numeric fields under one caption, which is
                    % what rows/columns/spacing is - three buttons said the
                    % opposite
                    bits = strsplit(label, ' / ');
                    c = uigridlayout(parent, [1 2 * numel(bits)]);
                    c.Padding = [0 0 0 0];
                    c.ColumnSpacing = 4;
                    w = cell(1, 2 * numel(bits));
                    for i = 1:numel(bits)
                        w{2*i-1} = 'fit';
                        w{2*i}   = 52;
                        uilabel(c, 'Text', strtrim(bits{i}));
                        uieditfield(c, 'numeric', 'Value', 1);
                    end
                    c.ColumnWidth = w;

                case 'slider'
                    c = uigridlayout(parent, [1 2]);
                    c.Padding = [0 0 0 0];
                    c.ColumnWidth = {'fit', '1x'};
                    uilabel(c, 'Text', label);
                    sl = uislider(c, 'Limits', [0 1], 'Value', 0.5);
                    sl.MajorTicks = [];  sl.MinorTicks = [];

                case 'model'
                    % the three ways the notes list of drawing a contact
                    c = uigridlayout(parent, [1 2]);
                    c.Padding = [0 0 0 0];
                    c.ColumnWidth = {'fit', '1x'};
                    uilabel(c, 'Text', label);
                    % "Rendered model" is in the design notes and is not
                    % built, so it is not on the list: a dropdown that
                    % offers something and then draws a dot instead is
                    % worse than a shorter dropdown.
                    uidropdown(c, 'Items', {'Dots', 'Spheres'});

                case 'arrays'
                    c = uigridlayout(parent, [1 3]);
                    c.Padding = [0 0 0 0];
                    c.ColumnSpacing = 4;
                    uilabel(c, 'Text', label);
                    uibutton(c, 'state', 'Text', 'all');
                    uibutton(c, 'state', 'Text', 'current');

                case 'segment'
                    c = uigridlayout(parent, [1 max(1, numel(choicesFor(name)))]);
                    c.Padding = [0 0 0 0];
                    c.ColumnSpacing = 4;
                    items = choicesFor(name);
                    if isempty(items), items = {label}; end
                    for i = 1:numel(items)
                        b = uibutton(c, 'state', 'Text', items{i});
                        b.Enable = matlab.lang.OnOffSwitchState( ...
                            ~isempty(choicesFor(name)));
                    end
                case 'table'
                    c = uitable(parent, 'Data', cell(0,3), ...
                        'ColumnName', {'Array','Kind','n'});
                otherwise
                    c = uilabel(parent, 'Text', label);
            end
            if isprop(c, 'FontSize') && ~isa(c, 'matlab.ui.container.GridLayout')
                c.FontSize = app.Theme.fontSize;
            end

            % A named row is one a step is going to wire up, so keep what it
            % made: the control itself, or, for a row that is a little grid
            % of several, the ones that are not labels - left to right,
            % which is how the label reads them ("low and high"). By column
            % rather than by the order they were created, because the order
            % on screen is the one that is meant.
            if ~isempty(name)
                if isa(c, 'matlab.ui.container.GridLayout')
                    kids = c.Children;
                    kids = kids(~arrayfun( ...
                        @(x) isa(x, 'matlab.ui.control.Label'), kids));
                    [~, order] = sort(arrayfun(@(x) x.Layout.Column, kids));
                    app.Controls.(name) = kids(order);
                else
                    app.Controls.(name) = c;
                end
            end
        end

        function [panel, inner, head] = panelWithHeader(app, parent, name, title)
            %PANELWITHHEADER  A panel whose title bar is a button that folds it.
            %
            %   Which panels fold is not a choice made here - the design
            %   notes say it panel by panel: 2D, 3D and Navigation are
            %   "(collapsible)", Contacts "should be collapsible", Messages
            %   is "collapsible, make smaller, narrower". The cursor box is
            %   "always visible", which is about it always being THERE
            %   rather than about it being fixed open, so it folds too.
            panel = uipanel(parent);
            g = uigridlayout(panel, [2 1]);
            g.RowHeight   = {24, '1x'};
            g.ColumnWidth = {'1x'};
            g.Padding     = [8 8 8 8];
            g.RowSpacing  = 6;

            head = uibutton(g, 'Text', headerText(title, true));
            head.Layout.Row = 1;
            head.HorizontalAlignment = 'left';
            head.FontSize   = 11;
            head.FontWeight = 'bold';

            inner = uigridlayout(g, [1 1]);
            inner.Layout.Row  = 2;
            inner.ColumnWidth = {'1x'};
            inner.Padding     = [0 0 0 0];
            inner.RowSpacing  = 6;

            app.Sections.(name) = struct('panel', panel, 'head', head, ...
                'inner', inner, 'open', true, 'row', 0, 'parent', parent, ...
                'sizer', [], 'title', title);
            head.ButtonPushedFcn = @(~,~) app.toggleSection(name);
        end

        function toggleSection(app, name)
            s = app.Sections.(name);
            s.open = ~s.open;
            app.Sections.(name) = s;
            s.inner.Visible = matlab.lang.OnOffSwitchState(s.open);

            % Built from the title, not sliced off the text that is there.
            % Editing the text in place cost it a character every toggle -
            % two spaces and an arrow replacing two spaces, an arrow and
            % three spaces - so three folds of a panel and its name started
            % losing letters.
            s.head.Text = headerText(s.title, s.open);
            if ~isempty(s.sizer)
                % a panel that is not a row of a stack says for itself what
                % its size becomes - the contacts shrink a fixed row, the
                % two at the foot share one
                s.sizer(s.open);
            elseif s.open
                s.parent.RowHeight{s.row} = 'fit';
            else
                s.parent.RowHeight{s.row} = 46;
            end
        end

        function setSectionTitle(app, name, title)
            %SETSECTIONTITLE  Rename a panel without disturbing its arrow.
            %
            %   The contact panel puts the array's name in its header, and
            %   it does it on every cursor move. Writing the header text
            %   directly put the open arrow back each time, so a folded
            %   panel showed the arrow for an open one - and the arrow is
            %   what the user clicked to fold it.
            s = app.Sections.(name);
            s.title = title;
            app.Sections.(name) = s;
            s.head.Text = headerText(title, s.open);
        end

        function setSizer(app, name, fcn)
            s = app.Sections.(name);
            s.sizer = fcn;
            app.Sections.(name) = s;
        end

        function sizeFootRow(app)
            % the cursor box and the messages share a row, so it is only
            % short when both are folded
            open = app.Sections.cursor.open || app.Sections.messages.open;
            if open
                app.LeftCol.RowHeight{2} = 150;
            else
                app.LeftCol.RowHeight{2} = 46;
            end
        end

        % ----------------------------------------------------------
        function buildStatusBar(app)
            app.StatusBar = uigridlayout(app.Root, [1 2]);
            app.StatusBar.Layout.Row = 3;
            app.StatusBar.ColumnWidth = {'1x', 'fit'};
            app.StatusBar.RowHeight   = {'1x'};
            app.StatusBar.Padding     = [2 0 2 0];

            app.Chips = uilabel(app.StatusBar, 'Text', app.statusLine());
            app.Chips.Layout.Column = 1;
            app.Chips.FontSize = 11;

            app.CountLabel = uilabel(app.StatusBar, 'Text', app.countLine());
            app.CountLabel.Layout.Column = 2;
            app.CountLabel.FontSize = 11;
            app.CountLabel.HorizontalAlignment = 'right';
        end

        % ----------------------------------------------------------
        function switchTheme(app, which)
            if strcmp(which, 'dark')
                app.Theme = ielecTheme('clinicalDark');
            else
                app.Theme = ielecTheme('clinical');
            end
            app.applyTheme();

            % APPLYTHEME colours the controls and the axes; what is drawn
            % inside them keeps the old theme's colours until it is drawn
            % again - most visibly the pick marker, which is the theme's
            % cross colour.
            if ~isempty(app.Mixed)
                app.redrawPlanes();
                app.draw3D();
            end
        end

        function applyTheme(app)
            t = app.Theme;
            app.UIFigure.Color = t.bg;
            app.themeTree(app.UIFigure, t);

            for g = [app.Root, app.TopBar, app.Body, app.LeftCol, ...
                     app.ViewGrid, app.RightCol, app.StepStack, app.StatusBar]
                g.BackgroundColor = t.bg;
            end

            % the step that is current wears the accent
            for k = 1:numel(app.STEPS)
                b = app.StepButtons.(app.STEPS{k});
                if b.Value
                    b.BackgroundColor = t.acc;
                    b.FontColor       = t.accInk;
                else
                    b.BackgroundColor = t.panel;
                    b.FontColor       = t.ink2;
                end
            end

            % the viewports are dark in both themes: an image is read
            % against black whatever the window does
            v = fieldnames(app.Views);
            for k = 1:numel(v)
                ax = app.Views.(v{k}).axes;
                if ismember(v{k}, {'voxels', 'threeD'})
                    % No backdrop and no box. A 3-D axes draws its box as
                    % a wire prism, and a prism behind a brain is scenery
                    % nobody asked for: the brain and the voxel cloud sit
                    % on the panel itself.
                    ax.Color = 'none';
                    axis(ax, 'off');
                else
                    % a slice is read against black, whatever the window does
                    ax.Color  = t.view;
                    ax.XColor = t.view;
                    ax.YColor = t.view;
                end
                app.Views.(v{k}).caption.FontColor = t.mut;
            end

            app.ThemeSwitch.FontColor = t.ink2;
            app.Chips.FontColor      = t.mut;
            app.CountLabel.FontColor = t.mut;
            app.FileLabel.FontColor  = t.mut;
        end

        function themeTree(app, node, t)
            kids = allchild(node);
            for k = 1:numel(kids)
                c = kids(k);
                switch class(c)
                    case 'matlab.ui.container.Panel'
                        c.BackgroundColor = t.panel;
                        c.ForegroundColor = t.mut;
                        c.HighlightColor  = t.line;
                        c.FontSize        = 11;
                    case 'matlab.ui.container.GridLayout'
                        c.BackgroundColor = t.panel;
                    case 'matlab.ui.control.Label'
                        c.FontColor = t.ink2;
                    case {'matlab.ui.control.Button', ...
                          'matlab.ui.control.StateButton'}
                        if strcmp(c.Tag, 'accent')
                            c.BackgroundColor = t.acc;
                            c.FontColor       = t.accInk;
                        else
                            c.BackgroundColor = t.panel2;
                            c.FontColor       = t.ink;
                        end
                    case 'matlab.ui.control.CheckBox'
                        c.FontColor = t.ink;
                    case {'matlab.ui.control.NumericEditField', ...
                          'matlab.ui.control.EditField', ...
                          'matlab.ui.control.Spinner', ...
                          'matlab.ui.control.DropDown'}
                        c.BackgroundColor = t.panel2;
                        c.FontColor       = t.ink;
                    case 'matlab.ui.control.TextArea'
                        c.BackgroundColor = t.panel2;
                        c.FontColor       = t.ink2;
                        c.FontName        = t.monoFont;
                    case 'matlab.ui.control.Table'
                        % BackgroundColor is the row striping; the face
                        % behind an empty table follows the parent, so the
                        % grid under it has to be themed as well
                        c.BackgroundColor = t.panel;
                        c.ForegroundColor = t.ink;
                        if isprop(c, 'Parent') && isprop(c.Parent, 'BackgroundColor')
                            c.Parent.BackgroundColor = t.panel;
                        end
                end
                if isprop(c, 'Children') && ~isempty(c.Children)
                    app.themeTree(c, t);
                end
            end
        end
    end
end

% ======================================================================
function items = choicesFor(name)
%CHOICESFOR  What a named dropdown or segment offers.
%
%   The values are the layer's own, not labels invented here: a control that
%   offers something the layer will not accept is a bug waiting for the day
%   it is wired. See the help of ielec.export and ielec.label.
%
%   A row that is not listed gets a control that is visibly not decided yet,
%   rather than another row's list. Three of them had another row's list -
%   an Export "Format" that offered atlas inclusion modes, and an "Atlas"
%   that offered electrode types - which a reader cannot tell from a bug in
%   the real thing.
switch name
    case 'exportFormat'                      % ielec.export, cfg.format
        items = {'structure', 'eeglab', 'fieldtrip', 'bids', ...
                 'bidsCoordinateSystem', 'labels', 'targetLabels'};
    case 'exportCoordinates'                 % ielec.export, cfg.coordinates
        items = {'contacts', 'projection'};
    case 'anatomySpace'                      % ielec.label, cfg.space
        items = {'Native', 'MNI'};
    case 'inclusionMode'
        % Readable here, two short strings in the layer: ielec.label takes
        % cfg.mode as 'mode' or 'prob'. Whoever wires this maps
        % 'most probable' -> 'mode' and 'probabilistic' -> 'prob'; the
        % layer refuses anything else, so a wrong mapping cannot pass
        % quietly.
        items = {'most probable', 'probabilistic'};
    case 'arrayType'                         % ielec.fitArray, cfg.type
        items = {'Grid', 'Strip', 'Depth'};
    case 'model3d'
        items = {'Dots', 'Spheres'};
    otherwise
        items = {};
end
end

function txt = headerText(title, isOpen)
%HEADERTEXT  A panel header: the arrow that says which way it folds, then
%   the title in capitals. One place, so that the two are never built one
%   way and rewritten another.
arrow = char(9662);            % pointing down: open
if ~isOpen
    arrow = char(9656);        % pointing right: folded
end
txt = ['  ' arrow '   ' upper(title)];
end

function addToolboxPath()
%ADDTOOLBOXPATH  Put the toolbox on the path, as electrodes_gui.m does.
%
%   The window is found first - it has to be, or this would not be running -
%   and everything it calls is found from there: the layer, the drawing
%   layer, the configuration, SPM. Without it, opening the window from a
%   folder that only has app/ui on the path gets as far as the first
%   ielec call and then stops, which is a poor way to start a demonstration.
%
%   Same five folders as the old window, each checked before it is added so
%   that a missing one is skipped rather than raising.
here = fileparts(mfilename('fullpath'));         % app/ui
root = fileparts(fileparts(here));               % the repository
for f = {'src', 'app', 'assets', 'third_party', 'priv'}
    thisFolder = fullfile(root, f{1});
    if isfolder(thisFolder)
        addpath(genpath(thisFolder));
    end
end

% electrodes_gui.m sets these right after the same five folders. Every
% volume this window loads goes through SPM, and SPM without its defaults
% set behaves differently from SPM with them - so the old window and the
% new one are not quietly doing two different things.
if exist('spm', 'file') == 2
    spm('defaults', 'PET');
end
end

function v = fieldOrEmpty(s, name)
if isfield(s, name) && ~isempty(s.(name))
    v = s.(name);
else
    v = {};
end
end

function n = countContacts(project)
n = 0;
arrays = fieldOrEmpty(project, 'electrodes');
for k = 1:numel(arrays)
    if isfield(arrays{k}, 'x')
        n = n + numel(arrays{k}.x);
    end
end
end

function v = fieldOrNumeric(s, name)
% an N-by-3 of points, or empty. fieldOrEmpty gives {} for a missing field,
% which is right for a list of arrays and wrong for a list of coordinates.
if isstruct(s) && isfield(s, name) && isnumeric(s.(name)) && ...
        size(s.(name), 2) == 3
    v = s.(name);
else
    v = [];
end
end

function yes = has(project, field)
% a field that is there and has something in it
yes = isfield(project, field) && ~isempty(project.(field));
end

function s = tick(yes)
if yes, s = 'yes'; else, s = '--'; end
end
