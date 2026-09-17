function [GS, clusters, weight, quality] = clusterContacts(brushCrd, weight, nClus)
%CLUSTERCONTACTS  Group selected voxels into contacts, one cluster each.
%
%   [GS, clusters, weight, quality] = clusterContacts(brushCrd, weight, nClus)
%   splits the selected voxels into NCLUS groups and returns the centre of
%   each, which is where the contact is taken to be.
%
%     GS         NCLUS x 3, the centre of each cluster
%     clusters   one cluster number per voxel
%     weight     the weights actually used - see the note below
%     quality    how plausible the result looks, as numbers
%
%   WHICH ALGORITHM. K-medoids is used when it is available, because it
%   gives better solutions on this kind of data; it is slower. Otherwise the
%   toolbox falls back to k-means through CLUSTERING. Both are randomised, so
%   two runs on the same voxels do not have to agree - seed the generator
%   before calling if a run has to be reproducible.
%
%   THE CENTRE is the CT-intensity weighted mean of the voxels in the
%   cluster, not the plain mean. Brighter voxels are more likely to be the
%   metal of the contact, so they pull the centre towards themselves.
%
%   WHY WEIGHT COMES BACK. The k-medoids path converts the weights to double
%   before using them and the k-means path does not, and what is stored
%   afterwards is the converted copy. That is v1.020 behaviour, preserved
%   here rather than quietly normalised, so the weights used are returned
%   instead of being left for the caller to guess.
%
%   QUALITY carries what the toolbox uses to warn the user, as numbers
%   rather than as printed sentences, so that the GUI decides the wording:
%
%     .distances     for each contact, the distance to its closest neighbour
%     .meanDistance  mean of those
%     .madDistance   median absolute deviation of those
%     .nOutliers     how many are outliers by ISOUTLIER
%     .nLargeChange  how many differ from the median by more than 20%
%     .suspect       true when either count is above zero
%
%   A real array has contacts at a regular spacing, so those distances
%   should be nearly all the same. When they are not, either the voxels
%   belong to more than one array or the clustering has split a contact.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also CLUSTERING, GRIDFIT, EUCDISTMAT, THRESHOLDCTVOXELS.

if exist('kmedoids.m','file')
    disp('Running K-medoids clustering algorithm. This can take some time...');

    % good solutions, but time consuming
    clusters = kmedoids(brushCrd, nClus, 'Algorithm','pam', 'OnlinePhase','on');

    weight = double(weight);
    GS = zeros(nClus, 3);
    for i = 1:nClus
        ind = clusters == i;
        W   = sum(weight(ind));
        GS(i,:) = sum(diag(weight(ind)) * brushCrd(ind,:), 1) * (1/W);
    end
else
    disp('K-medoids algorithm not found. Running k-means algorithm')
    [GS, clusters] = clustering(nClus, brushCrd, weight);
end

quality = contactSpacing(GS);
end

% ---------------------------------------------------------------------
function quality = contactSpacing(GS)
%CONTACTSPACING  How regular is the spacing between the contacts found?

DD = eucDistMat(GS, GS);
DD(eye(size(DD)) == 1) = nan;
dd = min(DD);                      % distance to the closest neighbour

quality.distances    = dd;
quality.meanDistance = mean(dd);
quality.madDistance  = mad(dd);
quality.nOutliers    = sum(isoutlier(dd));
quality.nLargeChange = sum(abs(dd/median(dd) - 1) > 0.20);
quality.suspect      = quality.nOutliers > 0 || quality.nLargeChange > 0;
end
