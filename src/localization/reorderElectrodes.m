function electrodes=reorderElectrodes(electrodes,newOrder)
% reorder electrodes
electrodes.x=electrodes.x(newOrder);
electrodes.y=electrodes.y(newOrder);
electrodes.z=electrodes.z(newOrder);

% reorder anatomical labels
electrodes.aLabels=electrodes.aLabels(newOrder);
if ~isempty(electrodes.anatInd) %no atlas assigned
    electrodes.anatInd=electrodes.anatInd(newOrder,:);
end

% reorder clusters
tmp=zeros(size(electrodes.clusters));
for i=1:length(newOrder)
    tmp(electrodes.clusters==i)=newOrder(i);
end

electrodes.clusters=tmp;

% brushCrd and brushWeight need no change
% adjMat no change

% reorder projection
if isfield(electrodes,'projection') && ~isempty(electrodes.projection)
    for k=1:length(electrodes.projection)

        electrodes.projection{k}.x=electrodes.projection{k}.x(newOrder);
        electrodes.projection{k}.y=electrodes.projection{k}.y(newOrder);
        electrodes.projection{k}.z=electrodes.projection{k}.z(newOrder);
        electrodes.projection{k}.displacement=electrodes.projection{k}.displacement(newOrder);
        electrodes.projection{k}.aLabels=electrodes.projection{k}.aLabels(newOrder);
        if ~isempty(electrodes.projection{k}.anatInd) %no atlas assigned
            electrodes.projection{k}.anatInd=electrodes.projection{k}.anatInd(newOrder,:);
        end
    end
end