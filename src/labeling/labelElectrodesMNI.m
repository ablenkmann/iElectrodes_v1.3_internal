function prj = labelElectrodesMNI(prj)
%LABELELECTRODESMNI  Anatomical labelling in MNI space.
%
%   prj = labelElectrodesMNI(prj) assigns an anatomical label to every
%   electrode contact, every projected contact and every planning target in
%   the project, using the Harvard-Oxford probabilistic atlas in MNI space.
%
%   Required fields of PRJ
%     .electrodes     cell array of electrode arrays
%     .targets        cell array of planning targets
%     .MNI_S_matrix   transform from MNI coordinates to atlas voxel space
%     .MNIlabels      atlas label names
%     .MNIprob        atlas probability volumes
%
%   Fields written back into PRJ
%     .aLabels .validAnatLabels .anatInd  on each array, each projection and
%     each target.
%
%   PRJ is an ordinary project struct as produced by checkProjectStructure.
%   This function contains no GUI code and opens no figure, so it can be
%   called from a script or a test. See also LABELELECTRODESNATIVE.
%
%   Extracted verbatim from labels2MNIspace in electrodes_gui.m (v1.020)
%   during the iElectrodes 2 restructuring - the logic below is unchanged.
%
%   FIXED HERE, not in v1.020: the planning-targets loop built its position
%   as [x y y] instead of [x y z], so every planning target was looked up at
%   the wrong voxel unless y happened to equal z. Labels reported for planning
%   targets in MNI space by 1.020 and earlier are therefore wrong, and any
%   report already produced from such a project carries those values.
%
%   See also ANATOMICLABEL, LABELELECTRODESNATIVE, CHECKPROJECTSTRUCTURE.

%anatomical labeling of all electrodes
if ~isempty(prj.electrodes)
    L=length(prj.electrodes);
    for l=1:L
        pos=[prj.electrodes{l}.x prj.electrodes{l}.y prj.electrodes{l}.z];
        %        prj.electrodes{l}.aLabels=anatomicLabel(pos,prj.MNI_S_matrix,prj.MNIlabels,prj.MNIprob);
        [prj.electrodes{l}.aLabels,prj.electrodes{l}.validAnatLabels,prj.electrodes{l}.anatInd]=...
            anatomicLabel(pos,prj.MNI_S_matrix,prj.MNIlabels,prj.MNIprob);
        %         if isfield(prj.electrodes{l},'projection') && ~isempty(prj.electrodes{l}.projection)
        for p=1:length(prj.electrodes{l}.projection)
            pos=[prj.electrodes{l}.projection{p}.x prj.electrodes{l}.projection{p}.y...
                prj.electrodes{l}.projection{p}.z];
            [prj.electrodes{l}.projection{p}.aLabels,prj.electrodes{l}.projection{p}.validAnatLabels,...
                prj.electrodes{l}.projection{p}.anatInd]=...
                anatomicLabel(pos,prj.MNI_S_matrix,prj.MNIlabels,prj.MNIprob);
            %             end
        end
    end
end

%anatomical labeling of all planning electrodes
if ~isempty(prj.targets)
    L=length(prj.targets);
    for l=1:L
        pos=[prj.targets{l}.x prj.targets{l}.y prj.targets{l}.z];
%        prj.targets(l).aLabels=anatomicLabel(pos,prj.MNI_S_matrix,prj.MNIlabels,prj.MNIprob);
        [prj.targets{l}.aLabels,prj.targets{l}.validAnatLabels,prj.targets{l}.anatInd]=...
            anatomicLabel(pos,prj.MNI_S_matrix,prj.MNIlabels,prj.MNIprob);
    end
end
