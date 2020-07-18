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

% display prompt so user knows what to do 
disp('Select rows that do not contain vessels for background subtraction.')
% select rows that do not contain vessels for background subtraction -
% create mask 
[ROI_stack,xmin,ymin,width,height] = firstTimeCreateROIs(1,reg__Stacks{1});
% determine what rows were selected so far 
ymax = height + ymin - 1;
rowsSelected = ymin:ymax;
% if all rows were not selected display what rows were selected and give
% option to select more rows 
allRows = 1:size(reg__Stacks{1},1); % row indices possible 
if length(rowsSelected) < length(allRows) % if there are less rows selected than the total number of rows possible
    % find the rows that were not selected 
    rowsNotSelected = ~ismember(allRows,rowsSelected); 
    RowInds = find(rowsNotSelected);
    % let the user know what rows still need selection 
    
    % @@@@@@@@@@@@@@@@@@@
% BELOW NEEDS EDITING 
% @@@@@@@@@@@@@@@@@@@

    % INSTEAD OF DISPLAYING THE INDEX OF WHAT ROWS STILL NEED SELECTION -
    % THIS WOULD WORK BETTER IF I DRAW THE ROI BOUNDARIES MADE SO FAR
    % DURING NEXT ROUND OF ROI SELECTION 
    disp('These rows still need selection:')
    disp(RowInds)
    


    % select additional rows that do not contain vessels for background subtraction -
    % create mask 
    [ROI_stack,xmin,ymin,width,height] = firstTimeCreateROIs(1,reg__Stacks{1});

end 



% apply mask to each frame to get background pixel intensity per row 
% @@@@@@@@@@@@@@@@@@@
% BELOW NEEDS EDITING 
% @@@@@@@@@@@@@@@@@@@
BG_ROIboundData = cell(1,length(reg__Stacks));
BG_ROIstacks = cell(1,length(reg__Stacks));
for stack = 1:length(reg__Stacks)
    data = reg__Stacks{stack};
    if stack == 1
        [ROI_stacks,xmins,ymins,widths,heights] = firstTimeCreateROIs(1,data);
        BG_ROIboundData{stack}{1} = xmins;
        BG_ROIboundData{stack}{2} = ymins;
        BG_ROIboundData{stack}{3} = widths;
        BG_ROIboundData{stack}{4} = heights;
        BG_ROIstacks{stack} = ROI_stacks;

    elseif stack > 1 
        BG_ROIboundData{stack}{1} = BG_ROIboundData{1}{1};
        BG_ROIboundData{stack}{2} = BG_ROIboundData{1}{2};
        BG_ROIboundData{stack}{3} = BG_ROIboundData{1}{3};
        BG_ROIboundData{stack}{4} = BG_ROIboundData{1}{4};

        xmins = BG_ROIboundData{stack}{1};
        ymins = BG_ROIboundData{stack}{2};
        widths = BG_ROIboundData{stack}{3};
        heights = BG_ROIboundData{stack}{4};
        [ROI_stacks] = make_ROIs_notfirst_time(data,xmins,ymins,widths,heights);
        BG_ROIstacks{stack} = ROI_stacks;
    end 
end 

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