function ui = emptyColourCaches(ui)
%EMPTYCOLOURCACHES  Clear the colour caches, for a project with nothing in it.
%
%   ui = emptyColourCaches(ui) sets the three colour caches the GUI keeps in
%   ui - wmparcColors, AnnotColor_R and AnnotColor_L - to what
%   CHECKPROJECTSTRUCTURE gives an empty project: no parcellation colours,
%   and grey for each of zero surface vertices. Everything else in UI is
%   left alone.
%
%   The caches are derived from the project, and they are display state, so
%   the ielec layer neither returns nor sees them. When the layer starts a
%   new project, the frontend clears them with this.
%
%   iElectrodes 2 - RITMO / FRONT Neurolab, University of Oslo
%
%   See also IELEC.NEWPROJECT, CHECKPROJECTSTRUCTURE.

ui.wmparcColors = [];
ui.AnnotColor_R = ones(0,3)*.5;   % grey, for each of no vertices
ui.AnnotColor_L = ones(0,3)*.5;
end
