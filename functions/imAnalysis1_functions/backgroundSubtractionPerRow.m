function [stackOut,BG_ROIboundData] = backgroundSubtractionPerRow(reg__Stacks)

% black out the pixels that are part of calcium ROIs 
blackOutCaROIQ = input('Input 1 if you want to black out pixels in Ca ROIs. Input 0 otherwise. ');
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
        threeDCaMask{z} = repmat(CaROImasks{z},1,1,size(reg__Stacks{z},3));
        % apply your Ca ROI masks to the images 
        reg__Stacks{z}(threeDCaMask{z}) = 0;
    end    
end 

% @@@@@@@@@@@@@@@@@@@
% BELOW NEEDS EDITING 
% @@@@@@@@@@@@@@@@@@@

% TO DO:
% FINISH ADDING IN ABILITY TO ITERATE THROUGH Z PLANES 
% TEST THE CODE 

% select rows for background subtraction - this code goes through multiple
% rounds of row selection - make sure to select rows where they do not have
% blacked out pixels (from the calcium ROI removal) or vessels 
for z = 1:length(CaROImasks)
    disp(fprintf('This is Z plane #%d.',z))
    % display prompt so user knows what to do 
    disp('Select rows that do not contain vessels for background subtraction.')
    % select rows that do not contain vessels for background subtraction -
    % create mask 
    [ROI_stack,xmin,ymin,width,height] = firstTimeCreateROIs(1,reg__Stacks{1});
    it = 1; 
    ROIstacks{it} = ROI_stack;
    xmins(it) = xmin;
    ymins(it) = ymin;
    widths(it) = width;
    heights(it) = height;
    % determine what rows were selected so far 
    ymax = height + ymin - 1;
    xmax = width + xmin - 1;
    xmaxs(it) = xmax;
    ymaxs(it) = ymax;
    rowsSelected = ymin:ymax;
    % if all rows were not selected display what rows were selected and give
    % option to select more rows 
    allRows = 1:size(reg__Stacks{1},1); % row indices possible 
    while length(rowsSelected) < length(allRows) % if there are less rows selected than the total number of rows possible
        % find the rows that were not selected 
        rowsNotSelected = ~ismember(allRows,rowsSelected); 
        RowInds = find(rowsNotSelected);
        % let the user know what rows still need selection 
        disp('These rows still need selection:')
        disp(RowInds)                    
        %overlay background subtraction ROIs (so far) on image of FOV 
        subplot(1,2,1)
        imshow(reg__Stacks{1}(:,:,1),[0 1000]);
        hold all; 
        for i = 1:it
            x = [xmins(i),xmaxs(i),xmaxs(i),xmins(i),xmins(i)];
            y = [ymins(i),ymins(i),ymaxs(i),ymaxs(i),ymins(i)];
            plot(x,y,'r','LineWidth',2) 
        end
        % select additional rows that do not contain vessels for background subtraction -
        % create mask
        subplot(1,2,2)
        [ROI_stack,xmin,ymin,width,height] = firstTimeCreateROIs(1,reg__Stacks{1});
        it = it + 1;
        ROIstacks{it} = ROI_stack;
        xmins(it) = xmin;
        ymins(it) = ymin;
        % determine what rows were selected so far 
        ymax = height + ymin - 1;
        xmax = width + xmin - 1;
        xmaxs(it) = xmax;
        ymaxs(it) = ymax;
        widths(it) = width;
        heights(it) = height;
        rowsSelected = [rowsSelected,ymin:ymax];
    end 
    BG_ROIboundData{z}{1} = xmins;
    BG_ROIboundData{z}{2} = ymins;
    BG_ROIboundData{z}{3} = widths;
    BG_ROIboundData{z}{4} = heights;
end 

%@@@@@@@@@@@@@@@@@@@@


% NEED TO EVENTUALLY:
% FIGURE OUT WHAT TO DO ABOUT OVERLAPPING ROW SELECTION - FOR NOW I DON'T
% HAVE ANY OVERLAP SO GET ALL BELOW CODE WORKING WITHOUT OVERLAP FIRST AND THEN MAKE IT
% MORE COMPLICATED 


% determine average pixel intensity of each frame and row in the control
% ROIs
% @@@@@@@@@@@@@@@@@@@
% BELOW NEEDS EDITING 
% @@@@@@@@@@@@@@@@@@@
BGpixInt = cell(1,length(reg__Stacks));
for stack = 1:length(reg__Stacks)
    BGpixInt{stack} = mean(mean(BG_ROIstacks{stack}{1}));
end 

% do background subtraction 
% @@@@@@@@@@@@@@@@@@@
% BELOW NEEDS EDITING 
% @@@@@@@@@@@@@@@@@@@
stackOut = cell(1,length(reg__Stacks));
for stack = 1:length(reg__Stacks) 
    for frame = 1:size(BGpixInt{1},3)
        stackOut{stack}(:,:,frame) = (reg__Stacks{stack}(:,:,frame)-BGpixInt{stack}(:,:,frame));
    end 
end 

end 