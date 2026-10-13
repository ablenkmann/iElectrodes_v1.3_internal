function [project, work] = aimTarget(cfg, project, work)
%IELEC.AIMTARGET  Point a planned depth electrode, and lay its contacts out.
%
%   [project, work] = ielec.aimTarget(cfg, project, work) sets where a
%   planned depth electrode goes and how long it is, works out where each
%   contact then sits, and finishes with the frame angles of the direction it
%   ended up with. WORK is not changed.
%
%   Options (cfg):
%     cfg.index        which planning target. Required.
%
%   Where it points - at most ONE of these three ways:
%     cfg.targetOut    1-by-3, the far end, at the entry side.
%                                                              Default: []
%     cfg.azimuth      the direction in degrees, with cfg.elevation. Where
%     cfg.elevation    the far end lands then follows from the length.
%                                                              Default: []
%     cfg.alpha        the stereotactic frame angles in degrees, with
%     cfg.beta         cfg.beta. The frame's own mounting and whether it
%                      points down are the ones the target carries.
%                                                              Default: []
%   Give none of them and the far end it already has is used, which is what
%   a change to the length or the contact count needs.
%
%   What it is - each of these keeps the target's own when left out:
%     cfg.targetIn     1-by-3, the deep end - the anatomical target.
%     cfg.nContacts    how many contacts the electrode carries.
%     cfg.firstSecond  distance from the 1st contact to the 2nd, in mm.
%     cfg.secondLast   distance between every later pair, in mm.
%
%   Written into the target: whichever of .targetIn, .nElectrodes,
%   .FirstSecond and .SecondLast the cfg gave, then .targetOut, .delta,
%   .azimut, .elevation, .distances, .x, .y, .z, and then .alpha, .beta and
%   .frameDown through IELEC.SETFRAME.
%
%   cfg.targetIn, cfg.targetOut, cfg.nContacts, cfg.firstSecond and
%   cfg.secondLast are for scripting. The GUI's twelve depth-target boxes
%   and its click in a 2-D view still write their one coordinate straight
%   into the target and then call this with no direction at all, which is the
%   same computation by a shorter road; routing them through a cfg is for the
%   App Designer frontend to do. The last contact's z decides whether
%   the frame points down, so aiming the electrode can turn the frame over -
%   which is why the frame angles are worked out after the trajectory and
%   not before.
%
%   On the frame-angle route the direction is built from the frame's mounting
%   and the .frameDown the target carries NOW, before the new trajectory
%   replaces it. That order is the GUI's and it matters: using the new
%   frameDown would turn the electrode over by 180 degrees in beta whenever
%   the move crosses z = 0.
%
%   Nothing is rounded. What the boxes show is the frontend's business.
%
%   A degenerate aim is not refused. Two ends in the same place make .delta
%   a division by zero and the whole trajectory NaN, which is what
%   DEPTHTRAJECTORY has always done, and a NaN angle travels the same way.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:badOption (an index that is not one of the targets, more
%   than one way of saying where it points, half of a pair, a point that is
%   not three numbers, a count or a distance that is not one number) and
%   those of the cfg check.
%
%   Example
%       cfg = [];
%       cfg.index     = 1;
%       cfg.targetIn  = [-24 -12 -18];
%       cfg.targetOut = [-60 -12 -10];
%       [project, work] = ielec.aimTarget(cfg, project, work);
%
%       cfg = [];
%       cfg.index     = 1;
%       cfg.azimuth   = 12;
%       cfg.elevation = -4;
%       [project, work] = ielec.aimTarget(cfg, project, work);
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also DEPTHTRAJECTORY, TRAJECTORYENDPOINT, FRAMETRAJECTORYENDPOINT,
%            IELEC.SETFRAME, IELEC.NEWTARGET.

defaults.targetIn    = [];
defaults.targetOut   = [];
defaults.azimuth     = [];
defaults.elevation   = [];
defaults.alpha       = [];
defaults.beta        = [];
defaults.nContacts   = [];
defaults.firstSecond = [];
defaults.secondLast  = [];
cfg = checkCfg(cfg, defaults, {'index'}, 'aimTarget');

targets = fieldOr(project, 'targets', {});
if ~isnumeric(cfg.index) || ~isscalar(cfg.index) || mod(cfg.index, 1) ~= 0 || ...
        cfg.index < 1 || cfg.index > numel(targets)
    error('ielec:badOption', ...
        'ielec.aimTarget: cfg.index must be one of the %d planning targets.', ...
        numel(targets));
end
target = targets{cfg.index};

% ------------------------------------------------- one way of pointing it
byPoint = ~isempty(cfg.targetOut);
byAngle = ~isempty(cfg.azimuth) || ~isempty(cfg.elevation);
byFrame = ~isempty(cfg.alpha)   || ~isempty(cfg.beta);

if byPoint + byAngle + byFrame > 1
    error('ielec:badOption', ...
        ['ielec.aimTarget: say where it points one way - cfg.targetOut, or ' ...
         'cfg.azimuth with cfg.elevation, or cfg.alpha with cfg.beta.']);
end
if byAngle && (isempty(cfg.azimuth) || isempty(cfg.elevation))
    error('ielec:badOption', ...
        'ielec.aimTarget: cfg.azimuth and cfg.elevation go together.');
end
if byFrame && (isempty(cfg.alpha) || isempty(cfg.beta))
    error('ielec:badOption', ...
        'ielec.aimTarget: cfg.alpha and cfg.beta go together.');
end

% Only the shape is checked. A value that is not finite is let through: the
% toolbox's answer to a degenerate aim is a NaN trajectory, not an error.
for f = {'targetIn', 'targetOut'}
    v = cfg.(f{1});
    if ~isempty(v) && (~isnumeric(v) || numel(v) ~= 3)
        error('ielec:badOption', ...
            'ielec.aimTarget: cfg.%s must be three numbers, as [x y z].', f{1});
    end
end
for f = {'azimuth', 'elevation', 'alpha', 'beta', 'nContacts', ...
         'firstSecond', 'secondLast'}
    v = cfg.(f{1});
    if ~isempty(v) && (~isnumeric(v) || ~isscalar(v))
        error('ielec:badOption', ...
            'ielec.aimTarget: cfg.%s must be one number.', f{1});
    end
end

% ------------------------------------------- what the electrode is, first
% The length is read from these, so they are in place before the far end is
% worked out from a direction.
if ~isempty(cfg.targetIn)
    xi = cfg.targetIn(:)';
    target.targetIn.x = xi(1);
    target.targetIn.y = xi(2);
    target.targetIn.z = xi(3);
end
if ~isempty(cfg.nContacts),   target.nElectrodes = cfg.nContacts;   end
if ~isempty(cfg.firstSecond), target.FirstSecond = cfg.firstSecond; end
if ~isempty(cfg.secondLast),  target.SecondLast  = cfg.secondLast;  end

% A planned grid has none of the depth fields - CHECKELECTRODESTRUCTURE
% creates them only for a depth array - and the panel can show the Depth
% boxes with a grid selected (docs/OPEN_QUESTIONS.md item 36). That said
% "Unrecognized field name targetIn"; IELEC.SETFRAME already turns the same
% situation into an ielec: error one step later, and this is the same check
% one step earlier, so a frontend can catch either.
for f = {'targetIn', 'targetOut', 'nElectrodes', 'FirstSecond', 'SecondLast'}
    if ~isfield(target, f{1})
        error('ielec:badOption', ...
            ['ielec.aimTarget: target %d has no .%s, so it is not a depth ' ...
             'electrode to aim. A planned grid is moved with ' ...
             'ielec.placeTarget.'], cfg.index, f{1});
    end
end

xi = [target.targetIn.x target.targetIn.y target.targetIn.z];
n  = target.nElectrodes;
fs = target.FirstSecond;
sl = target.SecondLast;

% ------------------------------------------------------------ the far end
if byPoint
    xo = cfg.targetOut(:)';
elseif byAngle
    xo = trajectoryEndPoint(xi, cfg.azimuth, cfg.elevation, n, fs, sl);
elseif byFrame
    % the mounting and the frameDown the target carries now - see the help
    xo = frameTrajectoryEndPoint(xi, cfg.alpha, cfg.beta, ...
            target.framePosition, target.frameDown, n, fs, sl);
else
    xo = [target.targetOut.x target.targetOut.y target.targetOut.z];
end

target.targetOut.x = xo(1);
target.targetOut.y = xo(2);
target.targetOut.z = xo(3);

% ---------------------------------------------------------- the contacts
trajectory = depthTrajectory(xi, xo, n, fs, sl);

target.delta     = trajectory.delta;
target.azimut    = trajectory.azimuth;
target.elevation = trajectory.elevation;
target.distances = trajectory.distances;
target.x = trajectory.coordinates(:,1);
target.y = trajectory.coordinates(:,2);
target.z = trajectory.coordinates(:,3);

project.targets{cfg.index} = target;

% --------------------------------------------------------- and the frame
% After the trajectory, because frameDown follows the new last contact.
[project, work] = ielec.setFrame(struct('index', cfg.index), project, work);

project = recordStep(project, mfilename, cfg);
end

function value = fieldOr(s, name, default)
if isstruct(s) && isfield(s, name), value = s.(name); else, value = default; end
end
