%function h=vis(vertices,faces)
%function h=vis(vertices,faces,d)
%
%d: interp or flat (vertices o faces)
% 

function h=vis(v,f)%,d)
%if nargin==2; d=v(:,1); end;

h=plotsurf(v,f); 
set(h,'linestyle','none')
set(h,'faceColor',[0.7 0.7 0.7]);   
lighting phong; material dull; camlight;

% function h=vis(v,f,d)
% if nargin==2; d=v(:,1); end;
% 
% s.Vertices=v; s.Faces=f;
% s.FaceVertexCData=d(:);
% hs=patch(s); 
% %shading flat
% shading interp; 
% %shading faceted
% axis image;
% set(hs,'EdgeColor',[0.8 0.8 0.8],'facealpha',.3)
% xlabel('x'); ylabel('y'),zlabel('z')       
%xlabel('x'); ylabel('y'); zlabel('z');

% if nargout==1, h=hs; end


%ANTES
%function h=vis(v,f,d)
% s.Vertices=v;
% s.Faces=f;
% s.FaceVertexCData=d(:);
% hs=patch(s);
% if size(d(:),1)==size(v,1), shading interp; end
% if size(d(:),1)==size(f,1), shading flat; end
% colorbar
% axis image
% xlabel('x'); ylabel('y'); zlabel('z');
% if nargout==1, h=hs; end
