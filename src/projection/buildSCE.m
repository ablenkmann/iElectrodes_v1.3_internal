function [verticesSCE,facesSCE] = buildSCE(vertices,faces,options)
% build a Smooth Cortical Envelope using the pial surface
% A weighted average of SCE can be computed as well.

% Pial is converted to an binary image
% then dilation and erosion are used to "close" the surface
% with a sphere of size options.radius.
% If radius is scalar a single SCE is computed (use radius=50 for smooth output).
% If radius is a vector, a weighted average of SCE is coomputed (e.g. 
% [10 15 20 25 30 35 40 45 50] produce nice results).
% SCE might be further from the temporal-frontal intersection pial surface.
% SCE from smaller radius spheres enclosing produce closer but more bumpy
% results.
% Default resolution is 1mm

% A Blenkmann 2018
% updata 2020, use lowpass instead of laplacian smoothing

% open parallel pool if available
try
    parpool('Threads')
catch
end


tic;

if ~isfield(options,'buildSCEradius'); options.buildSCEradius = 50; end
if ~isfield(options,'resolution'); options.resolution = 1; end

meshSize =15000;

r_vec = options.buildSCEradius;

%% make binary image

res=options.resolution;

xi=[ round(min(vertices(:,1))-1-max(r_vec)) : res : round(max(vertices(:,1))+1+max(r_vec))] ;
yi=[ round(min(vertices(:,2))-1-max(r_vec)) : res : round(max(vertices(:,2))+1+max(r_vec))] ;
zi=[ round(min(vertices(:,3))-1-max(r_vec)) : res : round(max(vertices(:,3))+1+max(r_vec))] ;


% faces=[faces ones(length(faces),1)];

% addpath(genpath('/data/MATLAB/iso2mesh'))
img = surf2vol(vertices,faces,xi,yi,zi,'fill',1); % takes a while to compute


%% iterate sphere radius

for k=1:length(r_vec)
    
    r = r_vec(k);
    disp(['///  Building SCE approximation of radius ' num2str(r)]);
    
    % structuring element (by Luke Xie)
    sesize = r;
    sw=(sesize-1)/2;
    ses2=ceil(sesize/2);            % ceil sesize to handle odd diameters
    % [y,x,z]=meshgrid(-sw:sw,-sw:sw,-sw:sw);
    [y,x,z]=meshgrid(-sw:res:sw,-sw:res:sw,-sw:res:sw);
    m=sqrt(x.^2 + y.^2 + z.^2);
    b=(m <= m(ses2,ses2,sesize));
    se=strel('arbitrary',b);
    
    
    cImg=imclose(logical(img),se); % open parallel first to increase speed
    
    
    % % for debugging
    % figure;
    % i=1;
    % for z=1:round(max(zi)/10):max(zi)
    %     subplot(2,12,i);
    %     imagesc(img(:,:,z))
    %     axis image
    %     axis off
    %
    %     subplot(2,12,i+12);
    %     imagesc(cImg(:,:,z))
    %     axis image
    %     axis off
    %     i=i+1;
    % end
    
    dofix=1;
    opt=1;
    method='cgalsurf';
    isovalues=0.5;
    [verticesSCEarray{k},facesSCEarray{k}] = vol2surf(cImg,1:size(img,1),1:size(img,2),1:size(img,3),opt,dofix,method,isovalues);
    
    facesSCEarray{k}=facesSCEarray{k}(:,1:3);
    origin=[xi(1)+1,yi(1)+1, zi(1)+1];
    
    verticesSCEarray{k} = verticesSCEarray{k}*options.resolution + repmat(origin, size(verticesSCEarray{k},1),1);
    
    
    ratio=meshSize/length(verticesSCEarray{k});
    if ratio<1
        disp('/// Resampling mesh')
        [verticesSCEarray{k},facesSCEarray{k}]=meshresample(verticesSCEarray{k},facesSCEarray{k},ratio);
    end
    
    % smooth surface
    %verticesSCE=sms(verticesSCE,facesSCE,10,.5); % 10 iterations
    verticesSCEarray{k}=sms(verticesSCEarray{k},facesSCEarray{k},100,0.5,'lowpass'); % lowpass outperformts the other methods
    
end



%% compute distances to pial and to closest SCE (first). Then average.

if length(r_vec)==1 %nothing to compute
    
    verticesSCE = verticesSCEarray{1};
    facesSCE = facesSCEarray{1}; % faces definition does not change

else
    
    facesSCE = facesSCEarray{1}; % faces definition does not change
    
    ratio=meshSize/length(vertices);
    [verticesPial,facesPial]=meshresample(vertices,faces,ratio);
    
    for k=length(r_vec):-1:1
        
        disp(['///computing distances for SCE approximation of radius ' num2str(r_vec(k))]);
        
        % compute all distances to pial
        dist2Pial = eucDistMat(verticesSCEarray{k},verticesPial); % N_sce_k x N_pial
        [dd2P,~]=min(dist2Pial,[],2); % N_sce_k
        
        %compute distance to closest to match average coordinates later
        dist2Closest = eucDistMat(verticesSCEarray{1},verticesSCEarray{k}); % N_closest x N_sce_k
        [~,ind2C]=min(dist2Closest,[],2); % N_closest
        
        wN(:,k) = exp(-dd2P(ind2C)); % weights
        
        closeVertices(:,:,k) = verticesSCEarray{k}(ind2C,:);  %N_verices_closest x 3 x N_SCE
        
    end
    
    %normalize weights per vertex point
    wN_norm = wN ./ sum(wN,2);
    
    wN_norm=repmat(wN_norm,[1 3]);
    wN_norm=reshape(wN_norm,[],9,3);
    wN_norm=permute(wN_norm,[1,3,2]);
    
    %compute weighted average
    verticesSCE = sum (closeVertices .* wN_norm,3) ; %N_verices_closest x 3 x N_SCE - sum across the last dim
    
    % final smoothing
    verticesSCE = sms(verticesSCE,facesSCE,100,0.5,'lowpass'); % lowpass outperformts the other methods
end

disp(['SCE completed in  ' num2str(toc) ' seconds'])



%% Alternative iterative approach - slower approach

% verticesSCE = verticesSCEarray{1};
% facesSCE = facesSCEarray{1};
%
% ratio=meshSize/length(vertices);
% [verticesPial,facesPial]=meshresample(vertices,faces,ratio);
%
% for k=2:length(r_vec)
%
%     disp(['/// Smoothing SCE approximation of radius ' num2str(r_vec(k))]);
%
%     SCE_next = verticesSCEarray{k};
%
%     %compute distances
%     distActual2Pial = eucDistMat(verticesSCE,verticesPial); % N_actual x N_pial
%     [ddA2P,indA2P]=min(distActual2Pial,[],2); % N_actual
%
%     distNext2Pial = eucDistMat(SCE_next,verticesPial); % N_next x N_pial
%     [ddN2P,indN2P]=min(distNext2Pial,[],2); % N_next
%
%     distActual2Next = eucDistMat(verticesSCE,SCE_next); % N_actual x N_next
%     [ddA2N,indA2N]=min(distActual2Next,[],2); % N_actual
%
%
%     % weights
%     wA = exp(-ddA2P);
%     wN = exp(-ddN2P(indA2N));
%
%     %normalize
%     wA_norm = wA ./ (wA+wN);
%     wN_norm = wN ./ (wA+wN);
%
%     %update actual
%     verticesSCE = verticesSCE .* repmat((wA_norm),[1 3]) +  SCE_next(indA2N,:) .* repmat((wN_norm),[1 3]);
%
%     % smooth
%     verticesSCE = sms(verticesSCE,facesSCEarray{1},20,0.5,'lowpass'); % lowpass outperformts the other methods
% end

% final smoothing
% verticesSCE = sms(verticesSCE,facesSCEarray{1},100,0.5,'lowpass'); % lowpass outperformts the other methods



%% Plot all surfaces
%
% figure
% for k=1:9
%     ax(k)=subplot(3,4,k);
%     h(k)=mvis(verticesSCEarray{k},facesSCEarray{k});
%     h(k).FaceAlpha = 0.6;
%
%     hold on;
%     hp=mvis(verticesPial, facesPial);
%     hp.FaceColor = [1 0 1];
%
%     camlight; view(0,-90); camlight; view(-90,-0); camlight;
%     title(r_vec(k))
% end
%
% % set(h,'facealpha',0.2)
% %camlight
%
% %figure
% ax(10)=subplot(3,4,10);
%
% ha=mvis(verticesSCE,facesSCE);
% ha.FaceAlpha = 0.6;
%
% hold on;
% hp=mvis(verticesPial, facesPial);
% hp.FaceColor = [1 0 1];
%
% camlight; view(0,-90); camlight; view(-90,-0); camlight;
%
% title('iterative')
%
% hlink = linkprop(ax,{'CameraPosition','CameraUpVector'});
%
% %% Plot all surfaces - opaque
%
% figure
% for k=1:9
%     ax(k)=subplot(3,4,k);
%     h(k)=mvis(verticesSCEarray{k},facesSCEarray{k});
%
%     camlight; view(0,-90); camlight; view(-90,-0); camlight;
%     title(r_vec(k))
% end
%
% % set(h,'facealpha',0.2)
% %camlight
%
% %figure
% ax(10)=subplot(3,4,10);
%
% ha=mvis(verticesSCE,facesSCE);
%
% camlight; view(0,-90); camlight; view(-90,-0); camlight;
%
% title('iterative')
%
% hlink = linkprop(ax,{'CameraPosition','CameraUpVector'});
%
