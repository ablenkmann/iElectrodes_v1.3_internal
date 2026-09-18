function prj = labelElectrodesNative(prj)
%LABELELECTRODESNATIVE  Anatomical labelling in native (FreeSurfer) space.
%
%   prj = labelElectrodesNative(prj) assigns an anatomical label to every
%   electrode contact, every projected contact and every planning target in
%   the project, by looking each coordinate up in the FreeSurfer wmparc
%   parcellation volume.
%
%   Required fields of PRJ
%     .electrodes                    cell array of electrode arrays
%     .targets                       cell array of planning targets
%     .wmparc                        FreeSurfer parcellation volume (.img)
%     .wmparcS                       parcellation space transform
%     .options.atlasLabelingRadio    search radius; 0 disables look-around
%     .options.atlasLabelingMode     'mode' (most probable) or 'prob'
%     .options.atlasLabelingMinProb  minimum probability in 'prob' mode
%     .options.atlasLUTFile          look-up table, e.g. FreeSurferColorLUT.mat
%
%   Fields written back into PRJ
%     .aLabels .validAnatLabels .anatInd  on each array, each projection and
%     each target. When no parcellation is loaded the labels are filled with
%     'no atlas loaded'.
%
%   PRJ is an ordinary project struct as produced by checkProjectStructure.
%   This function contains no GUI code and opens no figure, so it can be
%   called from a script or a test. See also LABELELECTRODESMNI.
%
%   Extracted verbatim from labels2NativeSpace in electrodes_gui.m (v1.020)
%   during the iElectrodes 2 restructuring - the logic below is unchanged.
%
%   See also ANATOMICLABELFS, LABELELECTRODESMNI, CHECKPROJECTSTRUCTURE.

opt.radio=prj.options.atlasLabelingRadio;
opt.mode=prj.options.atlasLabelingMode;    % look arround mode: 'mode' most probable (default)/ 'prob'  probabilities 
opt.minProb=prj.options.atlasLabelingMinProb;    % minimum probability to consider in 'prob' 

if opt.radio>0
    lookAround=1;

else
    lookAround=0;
end


%anatomical labeling of all electrodes
if ~isempty(prj.electrodes)
    L=length(prj.electrodes);
    for l=1:L
        pos=[prj.electrodes{l}.x prj.electrodes{l}.y prj.electrodes{l}.z];
        
        if ~isempty(prj.wmparc)
            [prj.electrodes{l}.aLabels,prj.electrodes{l}.validAnatLabels,prj.electrodes{l}.anatInd]=...
                anatomicLabelFS(pos,[],prj.options.atlasLUTFile,lookAround,prj.wmparc.img,prj.wmparcS,[],[],opt);
            %    if isfield(prj.electrodes{l},'projection') && ~isempty(prj.electrodes{l}.projection)
            for p=1:length(prj.electrodes{l}.projection)
                pos=[prj.electrodes{l}.projection{p}.x prj.electrodes{l}.projection{p}.y...
                    prj.electrodes{l}.projection{p}.z];
                [prj.electrodes{l}.projection{p}.aLabels,prj.electrodes{l}.projection{p}.validAnatLabels...
                    ,prj.electrodes{l}.projection{p}.anatInd]=...
                    anatomicLabelFS(pos,[],prj.options.atlasLUTFile,lookAround,prj.wmparc.img,prj.wmparcS,[],[],opt);
            end
            %     end
        else
            prj.electrodes{l}.aLabels=repmat({'no atlas loaded'},prj.electrodes{l}.nElectrodes,1);
            prj.electrodes{l}.validAnatLabels={};
            prj.electrodes{l}.anatInd=[];
            %     if isfield(prj.electrodes{l},'projection') && ~isempty(prj.electrodes{l}.projection)
            for p=1:length(prj.electrodes{l}.projection)
                prj.electrodes{l}.projection{p}.aLabels=repmat({'no atlas loaded'},prj.electrodes{l}.nElectrodes,1);
                prj.electrodes{l}.projection{p}.validAnatLabels={};
                prj.electrodes{l}.projection{p}.anatInd=[];
            end
        end
    end
end

% anatomical labeling of all planning electrodes - OLD
% if ~isempty(prj.targets)
%     L=length(prj.targets);
%     for l=1:L
%         pos=[prj.targets(l).coordinates(:,1) prj.targets(l).coordinates(:,2) prj.targets(l).coordinates(:,3)];
% 
%         if ~isempty(prj.wmparc)
% %            prj.targets(l).aLabels=anatomicLabelFS(pos, [],lookAround,prj.wmparc.img,prj.wmparcS,radio);
%             [prj.targets(l).aLabels,prj.targets(l).validAnatLabels,prj.targets(l).anatInd]=...
%                 anatomicLabelFS(pos, [],lookAround,prj.wmparc.img,prj.wmparcS,opt);
%         else
%             prj.targets(l).aLabels=repmat({'no atlas loaded'},prj.targets(l).nElectrodes,1);
%             prj.targets(l).validAnatLabels={};
%             prj.targets(l).anatInd=[];
%         end
%     end
% end

% anatomical labeling of all planning electrodes
if ~isempty(prj.targets)
    L=length(prj.targets);
    for l=1:L
        pos=[prj.targets{l}.x prj.targets{l}.y prj.targets{l}.z];
        
        if ~isempty(prj.wmparc)
            [prj.targets{l}.aLabels,prj.targets{l}.validAnatLabels,prj.targets{l}.anatInd]=...
                 anatomicLabelFS(pos,[],prj.options.atlasLUTFile,lookAround,prj.wmparc.img,prj.wmparcS,[],[],opt);

             %             if isfield(prj.targets{l},'projection') && ~isempty(prj.targets{l}.projection.x)
             for p=1:length(prj.targets{l}.projection)
                 pos=[prj.targets{l}.projection{p}.x prj.targets{l}.projection{p}.y...
                    prj.targets{l}.projection{p}.z];
                [prj.targets{l}.projection{p}.aLabels,prj.targets{l}.projection{p}.validAnatLabels...
                    ,prj.targets{l}.projection{p}.anatInd]=...
                 anatomicLabelFS(pos,[],prj.options.atlasLUTFile,lookAround,prj.wmparc.img,prj.wmparcS,[],[],opt);
            end
        else
            prj.targets{l}.aLabels=repmat({'no atlas loaded'},prj.targets{l}.nElectrodes,1);
            prj.targets{l}.validAnatLabels={};
            prj.targets{l}.anatInd=[];
%             if isfield(prj.targets{l},'projection') && ~isempty(prj.targets{l}.projection.x)
            for p=1:length(prj.targets{l}.projection)
                prj.targets{l}.projection{p}.aLabels=repmat({'no atlas loaded'},prj.targets{l}.nElectrodes,1);
                prj.targets{l}.projection{p}.validAnatLabels={};
                prj.targets{l}.projection{p}.anatInd=[];
            end
        end
    end
end
