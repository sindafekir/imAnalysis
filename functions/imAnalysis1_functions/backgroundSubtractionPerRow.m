function [stackOut,BG_ROIboundData] = backgroundSubtractionPerRow(reg__Stacks)

% black out the pixels that are part of calcium ROIs 
blackOutCaROIQ = input('Input 1 if you want to black out pixels in Ca ROIs. Input 0 otherwise. ');
reg__Stacks2 = reg__Stacks;
if blackOutCaROIQ == 1         
    % get the Ca ROI coordinates 
    CaROImaskDir = uigetdir('*.*','WHERE ARE THE CA ROI COORDINATES?');
    cd(CaROImaskDir);
    CaROImaskFileName = uigetfile('*.*','GET THE CA ROI COORDINATES'); 
    CaROImaskMat = matfile(CaROImaskFileName); 
    CaROImasks = CaROImaskMat.CaROImasks;    
    % apply the Ca ROI masks to the images   
    threeDCaMask = cell(1,length(CaROImasks));
    for z = 1:length(CaROImasks)
        % turn the CaROImasks into binary images by replacing all non zero
        % elements with ones 
        CaROImasks{z}(CaROImasks{z} ~= 0) = 1;    
        % convert CaROImasks from double to logical 
        CaROImasks{z} = logical(CaROImasks{z});
        % make your Ca ROI masks the right size for applying to a 3D array 
        threeDCaMask{z} = repmat(CaROImasks{z},1,1,size(reg__Stacks2{z},3));
        % apply your Ca ROI masks to the images 
        reg__Stacks2{z}(threeDCaMask{z}) = 0;
    end    
end 

% select rows for background subtraction - this code goes through multiple
% rounds of row selection - make sure to select rows where they do not have
% blacked out pixels (from the calcium ROI removal) or vessels 
ROIstacks = cell(1,length(CaROImasks));
xmins = cell(1,length(CaROImasks));
ymins = cell(1,length(CaROImasks));
widths = cell(1,length(CaROImasks));
heights = cell(1,length(CaROImasks));
xmaxs = cell(1,length(CaROImasks));
ymaxs = cell(1,length(CaROImasks));
BG_ROIboundData = cell(2,6);
BG_ROIboundData{1,1} = 'X min'; 
BG_ROIboundData{1,2} = 'X max'; 
BG_ROIboundData{1,3} = 'Y min'; 
BG_ROIboundData{1,4} = 'Y max'; 
BG_ROIboundData{1,5} = 'width'; 
BG_ROIboundData{1,6} = 'height'; 
for z = 1:length(CaROImasks)
    figure; 
    fprintf('This is Z plane #%d.  ',z)
    % display prompt so user knows what to do 
    disp('Select rows that do not contain vessels for background subtraction.')
    % select rows that do not contain vessels for background subtraction -
    % create mask 
    [ROI_stack,xmin,ymin,width,height] = firstTimeCreateROIs(1,reg__Stacks2{z});
    it = 1; 
    ROIstacks{z}{it} = ROI_stack;
    xmins{z}(it) = xmin;
    ymins{z}(it) = ymin;
    widths{z}(it) = width;
    heights{z}(it) = height;
    % determine what rows were selected so far 
    ymax = height + ymin;
    xmax = width + xmin;
    xmaxs{z}(it) = xmax;
    ymaxs{z}(it) = ymax;
    rowsSelected = ymin:ymax;
    % if all rows were not selected display what rows were selected and give
    % option to select more rows 
    allRows = 1:size(reg__Stacks{z},1); % row indices possible 
    while length(rowsSelected) < length(allRows) % if there are less rows selected than the total number of rows possible
        % find the rows that were not selected 
        rowsNotSelected = ~ismember(allRows,rowsSelected); 
        RowInds = find(rowsNotSelected);
        % let the user know what rows still need selection 
        disp('These rows still need selection:')
        disp(RowInds)                    
        %overlay background subtraction ROIs (so far) on image of FOV 
        subplot(1,2,1)
        imshow(reg__Stacks2{z}(:,:,1),[0 1000]);
        hold all; 
        for i = 1:it
            x = [xmins{z}(i),xmaxs{z}(i),xmaxs{z}(i),xmins{z}(i),xmins{z}(i)];
            y = [ymins{z}(i),ymins{z}(i),ymaxs{z}(i),ymaxs{z}(i),ymins{z}(i)];
            plot(x,y,'r','LineWidth',2) 
        end
        % select additional rows that do not contain vessels for background subtraction -
        % create mask
        subplot(1,2,2)
        [ROI_stack,xmin,ymin,width,height] = firstTimeCreateROIs(1,reg__Stacks2{z});
        it = it + 1;
        ROIstacks{z}{it} = ROI_stack;
        xmins{z}(it) = xmin;
        ymins{z}(it) = ymin;
        % determine what rows were selected so far 
        ymax = height + ymin;
        xmax = width + xmin;
        xmaxs{z}(it) = xmax;
        ymaxs{z}(it) = ymax;
        widths{z}(it) = width;
        heights{z}(it) = height;
        rowsSelected = [rowsSelected,ymin:ymax];
    end 
    BG_ROIboundData{2,1} = xmins;
    BG_ROIboundData{2,2} = xmaxs;
    BG_ROIboundData{2,3} = ymins;
    BG_ROIboundData{2,4} = ymaxs;
    BG_ROIboundData{2,5} = widths;
    BG_ROIboundData{2,6} = heights;
end 

% determine average pixel intensity of each frame and row in the control
% ROIs
BGpixInt = cell(1,length(CaROImasks));
for z = 1:length(CaROImasks)
    for i = 1:length(ROIstacks{z})
        BGpixInt{z}{i} = mean(ROIstacks{z}{i}{1},2);
    end 
end 

% ensure the size of the ROI boundaries does not accidentally exceed the
% size of the FOV
for z = 1:length(CaROImasks)
    for i = 1:length(ROIstacks{z})
        if BG_ROIboundData{2,4}{z}(i) > size(reg__Stacks{1},1)
            BG_ROIboundData{2,4}{z}(i) = size(reg__Stacks{1},1);
        end 
    end 
end 

% do background subtraction per row 
stackOut = cell(1,length(CaROImasks));
for z = 1:length(CaROImasks)
    for i = 1:length(ROIstacks{z})        
        for frame = 1:size(ROIstacks{z}{i}{1},3)          
            stackOut{z}(BG_ROIboundData{2,3}{z}(i):BG_ROIboundData{2,4}{z}(i),:,frame) = (reg__Stacks{z}(BG_ROIboundData{2,3}{z}(i):BG_ROIboundData{2,4}{z}(i),:,frame)-BGpixInt{z}{i}(:,:,frame));
        end         
    end 
end 

end 