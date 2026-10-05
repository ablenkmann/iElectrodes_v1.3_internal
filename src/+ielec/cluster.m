function [project, work, quality] = cluster(cfg, project, work) %#ok<INUSL> project is not changed
%IELEC.CLUSTER  Group the selected voxels into contacts.
%
%   [project, work, quality] = ielec.cluster(cfg, project, work) splits the
%   voxels in work.selectedVoxels into cfg.nClusters groups and takes the
%   centre of each as a contact. The contacts are added to the ones already
%   found, in work:
%
%     work.GS            the contacts so far, one row each
%     work.brushCrd      the voxels they were made from
%     work.clusters      which contact each of those voxels belongs to,
%                        numbered on from the contacts already there
%     work.brushWeight   the weights used
%
%   The previous values are kept in work.oldGS, work.oldbrushCrd,
%   work.oldclusters and work.oldbrushWeight, which is what Undo restores.
%   PROJECT is not changed: these are contacts in progress, not an accepted
%   array. IELEC.GRIDFIT and the Add button are what make an array of them.
%
%   Options (cfg):
%     cfg.nClusters   how many contacts to find.                   required
%
%   QUALITY is how plausible the result looks, as numbers rather than
%   printed sentences - the distances between neighbouring contacts, their
%   mean and spread, how many look like outliers, and .suspect when any do.
%   The caller decides what to say about them. CLUSTERCONTACTS describes
%   each field.
%
%   The clustering is randomised, so two runs on the same voxels need not
%   agree; seed the generator before calling if a run has to be reproducible.
%
%   Nothing is drawn and no window is opened.
%
%   Errors: ielec:noSelection (select voxels first), ielec:badOption (the
%   number of contacts is not a positive whole number, or there are fewer
%   voxels than that), and those of the cfg check.
%
%   Example
%       [project, work, quality] = ielec.cluster(struct('nClusters', 8), project, work);
%       quality.meanDistance
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also CLUSTERCONTACTS, IELEC.SELECTVOXELS.

cfg = checkCfg(cfg, struct(), {'nClusters'}, 'cluster');

if ~isfield(work, 'selectedVoxels') || isempty(work.selectedVoxels) || ...
        ~isfield(work, 'selectedWeights') || isempty(work.selectedWeights)
    error('ielec:noSelection', ...
        'ielec.cluster: select some voxels first (ielec.selectVoxels).');
end

n = cfg.nClusters;
if ~isnumeric(n) || ~isscalar(n) || n < 1 || mod(n, 1) ~= 0
    error('ielec:badOption', 'ielec.cluster: cfg.nClusters must be a positive whole number.');
end
if n > size(work.selectedVoxels, 1)
    error('ielec:badOption', ...
        'ielec.cluster: %d contacts asked for, but only %d voxels are selected.', ...
        n, size(work.selectedVoxels, 1));
end

[GS, clusters, weight, quality] = ...
    clusterContacts(work.selectedVoxels, work.selectedWeights, n);

work.oldGS          = work.GS;
work.oldbrushCrd    = work.brushCrd;
work.oldbrushWeight = work.brushWeight;
work.oldclusters    = work.clusters;

work.GS          = [work.GS;          GS];
work.brushCrd    = [work.brushCrd;    work.selectedVoxels];
work.clusters    = [work.clusters;    clusters + length(unique(work.clusters))];
work.brushWeight = [work.brushWeight; weight];
end
