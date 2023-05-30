frames = 19:35;
vidQ2 = input('Input 1 to black out pixels inside of vessel. ');
ETAorSTAq = input('Input 0 if this is STA data or 1 if this is ETA data. ');
for frameInd = 1:length(frames)
    mouse = 1;
    inds = cell(1,max(terminals{mouse}));
    idx = cell(1,max(terminals{mouse}));
    indsV = cell(1,max(terminals{mouse}));
    maskNearVessel = cell(1,max(terminals{mouse}));
    indsV2 = cell(1,max(terminals{mouse}));
    indsA = cell(1,max(terminals{mouse}));
    indsA2 = cell(1,size(RightChan{ terminals{mouse}(1)},3));
    unIdxVals = cell(1,max(terminals{mouse}));
    CsNotNearVessel = cell(1,max(terminals{mouse}));
    clustSize = NaN(length(terminals{mouse}),length(unIdxVals{terminals{mouse}(ccell)}));
    clustAmp = NaN(length(terminals{mouse}),length(unIdxVals{terminals{mouse}(ccell)}));
    for ccell = 1:length(terminals{mouse})
        count = 1;
        term = terminals{mouse}(ccell);
        % use dbscan to find clustered pixels 
    %     im = RightChan{term}; % input image for % change vids
        im = binarySTA{term}; % input image for binarized z scored vids 
        vesselMask = BW_perim{term};
        % convert im to binary matrix where 1 = pixels that are positive going %
        % below code is for binarized z-score vids where 
        % 1 means greater than 95% CI and 2 means lower than 95% CI 
        im(im>1) = 0;
    
        % below code is for % change videos 
    %     maxPerc = max(max(max(im))); minPerc = min(min(min(im)));
    %     thresh = maxPerc/10;
    %     % thresh = 0;
    %     % change 
    %     im(im < thresh) = 0; im(im > thresh) = 1;
        % black out pixels inside of vessel     
        if vidQ2 == 1 
            im(BWstacks{terminals{mouse}(ccell)}) = 0;
        end 
        % get x and y and z coordinates of 1s (pixels that are positive going)
        [row, col, frame] = ind2sub(size(im),find(im > 0));
        inds{terminals{mouse}(ccell)}(:,1) = col; inds{terminals{mouse}(ccell)}(:,2) = row; inds{terminals{mouse}(ccell)}(:,3) = frame;
        % plot these x y coordinates for sanity check 
        % figure;scatter3(inds(:,1),inds(:,2),inds(:,3))
        % feed these x y coordinates into dbscan 
    %     numP = 3; % number of points a cluster needs to be considered valid
    %     fixRad = 1; % fixed radius for the search of neighbors 
        numP = 1; % number of points a cluster needs to be considered valid
        fixRad = 1; % fixed radius for the search of neighbors 
        [idx{terminals{mouse}(ccell)},corepts] = dbscan(inds{terminals{mouse}(ccell)},fixRad,numP);
        % need to convert cluster group identifiers into positive going values only
        % for scatter3
        unIdxVals{terminals{mouse}(ccell)} = unique(idx{terminals{mouse}(ccell)}); minIdxVal = min(unIdxVals{terminals{mouse}(ccell)});
        idx{terminals{mouse}(ccell)}(idx{terminals{mouse}(ccell)}<0) = NaN;
        unIdxVals{terminals{mouse}(ccell)}(unIdxVals{terminals{mouse}(ccell)}<0) = NaN;
        % get vessel outline coordinates 
        [rowV, colV, frameV] = ind2sub(size(vesselMask),find(vesselMask > 0));
        indsV{terminals{mouse}(ccell)}(:,1) = colV; indsV{terminals{mouse}(ccell)}(:,2) = rowV; indsV{terminals{mouse}(ccell)}(:,3) = frameV;  
        % figure out pixel locations just outside of vessel 
        for frame = 1:size(im,3)
            radius = 1;
            decomposition = 0;
            se = strel('disk', radius, decomposition);               
            maskNearVessel{terminals{mouse}(ccell)}(:,:,frame) = imdilate(BWstacks{terminals{mouse}(ccell)}(:,:,frame),se);               
        end 
        idx2 = idx;
        % get outline coordinates just outside of vessel 
        [rowV2, colV2, frameV2] = ind2sub(size(maskNearVessel{terminals{mouse}(ccell)}),find(maskNearVessel{terminals{mouse}(ccell)} > 0));
        indsV2{terminals{mouse}(ccell)}(:,1) = colV2; indsV2{terminals{mouse}(ccell)}(:,2) = rowV2; indsV2{terminals{mouse}(ccell)}(:,3) = frameV2;  
        % for each cluster, if one pixel is next to the vessel, keep that
        % cluster, otherwise clear that cluster
        for clust = 1:length(unIdxVals{terminals{mouse}(ccell)})
            % find what rows each cluster is located in
            [Crow, ~] = find(idx{terminals{mouse}(ccell)} == unIdxVals{terminals{mouse}(ccell)}(clust)); 
            % identify the x, y, z location of pixels per cluster
            cLocs = inds{terminals{mouse}(ccell)}(Crow,:);        
            % determine if cLocs are near the vessel 
            cLocsNearVes = ismember(indsV2{terminals{mouse}(ccell)},cLocs,'rows');
            if ~any(cLocsNearVes == 1) == 1 % if the cluster is not near the vessel 
                % delete cluster that is not near the vessel 
                inds{terminals{mouse}(ccell)}(Crow,:) = NaN; 
                idx{terminals{mouse}(ccell)}(Crow,:) = NaN; 
                CsNotNearVessel{terminals{mouse}(ccell)}(count) = unIdxVals{terminals{mouse}(ccell)}(clust);
                count = count + 1;            
            end 
            % determine cluster size 
            clustSize(ccell,clust) = sum(idx{terminals{mouse}(ccell)}(:) == unIdxVals{terminals{mouse}(ccell)}(clust));
            % determine cluster pixel amplitude 
            pixAmp = nan(1,size(cLocs,1));
            for pix = 1:length(pixAmp)
                pixAmp(pix) = RightChan{terminals{mouse}(ccell)}(cLocs(pix,2),cLocs(pix,1),cLocs(pix,3));
            end 
            clustAmp(ccell,clust) =  nanmean(pixAmp); %#ok<*NANSUM> 
        end         
    end 
    CsTooSmall = cell(1,max(terminals{mouse}));
    % remove clusters that are not big enough in size and plot 
    for ccell = 1:length(terminals{mouse})
        count = 1;
        % make 0s NaNs 
        clustSize(clustSize == 0) = NaN;
        clustAmp(clustAmp == 0) = NaN;
        % find the top 10 % of cluster sizes (this will be 100 or more
        % for 57)
        numClusts = nnz(~isnan(clustSize));
        numTopClusts = ceil(numClusts*0.1);
        reshapedSizes = reshape(clustSize,1,size(clustSize,1)*size(clustSize,2));
        % remove NaNs 
        reshapedSizes(isnan(reshapedSizes)) = [];
        % sort sizes 
        sortedSize = sort(reshapedSizes);
        % get the largest 10 % of cluster sizes 
        topClusts = sortedSize(end-numTopClusts+1:end);
        % get the locations of the topClusts 
        topClusts2 = ismember(clustSize,topClusts);       
        [topCx_A, topCy_C] = find(topClusts2);
        % determine what clusters are big enough to be included 
        bigClustAlocs = find(topCx_A == ccell); % find what rows the axon is in to determine what clusters are big enough per axon 
        bigClustLocs = topCy_C(bigClustAlocs);
        bigClusts = unIdxVals{terminals{mouse}(ccell)}(bigClustLocs);
        % remove clusters that do not include the top 10 % of sizes 
        for clust = 1:length(unIdxVals{terminals{mouse}(ccell)})
            % find what rows each cluster is located in
            [Crow, ~] = find(idx{terminals{mouse}(ccell)} == unIdxVals{terminals{mouse}(ccell)}(clust));  
            % remove clusters if they're too small 
            if sum(ismember(bigClusts,unIdxVals{terminals{mouse}(ccell)}(clust))) == 0 
                inds{terminals{mouse}(ccell)}(Crow,:) = NaN;
                idx{terminals{mouse}(ccell)}(Crow,:) = NaN;
                idx2{terminals{mouse}(ccell)}(Crow,:) = NaN;
                CsTooSmall{terminals{mouse}(ccell)}(count) = unIdxVals{terminals{mouse}(ccell)}(clust);
                count = count + 1;  
            end 
        end 
        % TRYING TO FLIP THE AXES FOR GRANT 
        % @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        % @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        % @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        % plot the grouped pixels 
        figure;scatter3(inds{terminals{mouse}(ccell)}(:,2),inds{terminals{mouse}(ccell)}(:,1),inds{terminals{mouse}(ccell)}(:,3),30,idx{terminals{mouse}(ccell)},'filled'); % plot clusters 
        % plot vessel outline 
        hold on; scatter3(indsV{terminals{mouse}(ccell)}(:,2),indsV{terminals{mouse}(ccell)}(:,1),indsV{terminals{mouse}(ccell)}(:,3),30,'k','filled'); % plot vessel outline     
    
    
    
        % ORIGINAL PLOTTING CODE BELOW 
    %     % plot the grouped pixels 
    %     figure;scatter3(inds{terminals{mouse}(ccell)}(:,1),inds{terminals{mouse}(ccell)}(:,2),inds{terminals{mouse}(ccell)}(:,3),30,idx{terminals{mouse}(ccell)},'filled'); % plot clusters 
    %     % plot vessel outline 
    %     hold on; scatter3(indsV{terminals{mouse}(ccell)}(:,1),indsV{terminals{mouse}(ccell)}(:,2),indsV{terminals{mouse}(ccell)}(:,3),30,'k','filled'); % plot vessel outline     
        % get the x-y coordinates of the Ca ROI         
        clearvars CAy CAx
        if ismember("ROIorders", variableInfo) == 1 % returns true
            [CAyf, CAxf] = find(ROIorders{1} == terminals{mouse}(ccell));  % x and y are column vectors.
        elseif ismember("ROIorders", variableInfo) == 0 % returns true
            [CAyf, CAxf] = find(CaROImasks{1} == terminals{mouse}(ccell));  % x and y are column vectors.
        end   
        % create axon x, y, z matrix 
        for frame = 1:size(im,3)
            if frame == 1 
                indsA{terminals{mouse}(ccell)}(:,1) = CAxf; indsA{terminals{mouse}(ccell)}(:,2) = CAyf; indsA{terminals{mouse}(ccell)}(:,3) = frame;
            elseif frame > 1 
                if frame == 2
                    len = size(indsA{terminals{mouse}(ccell)},1);
                end 
                len2 = size(indsA{terminals{mouse}(ccell)},1);
                indsA{terminals{mouse}(ccell)}(len2+1:len2+len,1) = CAxf; indsA{terminals{mouse}(ccell)}(len2+1:len2+len,2) = CAyf; indsA{terminals{mouse}(ccell)}(len2+1:len2+len,3) = frame;
            end 
        end 
        % TRYING TO FLIP THE AXES FOR GRANT 
        % @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        % @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        % @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        % plot axon location 
        hold on; scatter3(indsA{terminals{mouse}(ccell)}(:,2),indsA{terminals{mouse}(ccell)}(:,1),indsA{terminals{mouse}(ccell)}(:,3),30,'r'); % plot axon
        set(gca,'XLim',[0 40],'YLim',[10 65],'ZLim',[frames(frameInd)-0.5 frames(frameInd)+0.5])
        % ORIGINAL PLOTTING CODE BELOW 
    %     hold on; scatter3(indsA{terminals{mouse}(ccell)}(:,1),indsA{terminals{mouse}(ccell)}(:,2),indsA{terminals{mouse}(ccell)}(:,3),30,'r'); % plot axon 
        if ETAorSTAq == 0 
            title(sprintf('Axon %d',terminals{mouse}(ccell))); 
        elseif ETAorSTAq == 1 
            title('Opto Triggered'); 
        end 
    end 
    % remove cluster sizes that are irrelevant 
    removeClustSizes = ~ismember(clustSize,topClusts);
    clustSize(removeClustSizes) = NaN;
    % make sure clustAmp shows the same clusts as clustSize 
    clustsToRemove = isnan(clustSize);
    clustAmp(clustsToRemove) = NaN;
    
    % safekeep some variables 
    safeKeptInds = inds; 
    safeKeptIdx = idx;
    safeKeptClustSize = clustSize;
    safeKeptClustAmp = clustAmp;
end 