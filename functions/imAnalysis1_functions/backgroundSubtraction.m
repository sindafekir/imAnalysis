function [stackOut,BG_ROIboundData] = backgroundSubtraction(reg__Stacks)

% black out the pixels that are part of calcium ROIs 
blackOutCaROIQ = input('Input 1 if you want to black out pixels in Ca ROIs. Input 0 otherwise. ');
if blackOutCaROIQ == 1         
    CaROImaskDir = uigetdir('*.*','WHERE ARE THE CA ROI COORDINATES?');
    cd(CaROImaskDir);
    CaROImaskFileName = uigetfile('*.*','GET THE CA ROI COORDINATES'); 
    CaROImaskMat = matfile(CaROImaskFileName); 
    CaROImasks = CaROImaskMat.CaROImasks;    
    %make your Ca ROI masks the right size for applying to a 3D array 
    threeDCaMask = cell(1,length(CaROImasks));
    for z = 1:length(CaROImasks)
        threeDCaMask{z} = repmat(CaROImasks{z},1,1,size(reg__Stacks{z},3));
    end 
    
    % @@@@@@@@@@@@@@@@@@@
    % BELOW NEEDS EDITING 
    % @@@@@@@@@@@@@@@@@@@ 
    
    %apply new mask to the right channel 
    rightChan = input('Input 0 to apply Ca ROI mask to green channel. Input 1 for the red channel. ');
    if rightChan == 0     
        RightChan = SNgreenStackAv;
    elseif rightChan == 1
        RightChan = SNredStackAv;
    end     
    for ccell = 1:length(terminals)
        RightChan{terminals(ccell)}(threeDCaMask) = 0;
    end 
end 




% display prompt so user knows what to do 
disp('Select rows that do not contain vessels for background subtraction.')

% select rows that do not contain vessels for background subtraction -
% create mask 
% @@@@@@@@@@@@@@@@@@@
% BELOW NEEDS EDITING 
% @@@@@@@@@@@@@@@@@@@
[ROI_stacks,xmins,ymins,widths,heights] = firstTimeCreateROIs(1,reg__Stacks{1});
BG_ROIboundData{1}{1} = xmins;
BG_ROIboundData{1}{2} = ymins;
BG_ROIboundData{1}{3} = widths;
BG_ROIboundData{1}{4} = heights;
BG_ROIstacks{1} = ROI_stacks;

% find out if all rows were selected 

% if all rows were not selected display what rows were selected and give
% option to select more rows 


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