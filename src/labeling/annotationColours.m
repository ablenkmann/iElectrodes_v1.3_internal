function colours = annotationColours(annotLabel, colortable)
%ANNOTATIONCOLOURS  Per-vertex colours for a FreeSurfer surface annotation.
%
%   colours = annotationColours(annotLabel, colortable) returns an N-by-3
%   array of RGB values in [0 1], one row per surface vertex, taken from the
%   annotation's own colour table.
%
%   ANNOTLABEL is the per-vertex label as READ_ANNOTATION returns it, and
%   COLORTABLE its companion structure, whose fifth table column holds the
%   label values and whose first three hold the colours.
%
%   Vertices whose label is not in the table - FreeSurfer leaves some
%   unassigned, typically along the medial wall - are given mid grey rather
%   than dropped, so the returned array always has one row per vertex and
%   can be handed straight to PATCH.
%
%   iElectrodes 2 restructuring - RITMO / FRONT Neurolab, University of Oslo
%
%   See also PARCELLATIONCOLOURS, READ_ANNOTATION.

[~, ind] = ismember(annotLabel, colortable.table(:,5));

colours = ones(length(ind), 3) * .5;                % unassigned -> grey
found   = find(ind);
colours(found,:) = colortable.table(ind(found), 1:3) / 255;
end
