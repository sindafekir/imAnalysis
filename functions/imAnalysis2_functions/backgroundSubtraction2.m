function [stackOut] = backgroundSubtraction2(stackIn,BG_ROIboundData)

BG_ROIstacks = cell(1,length(stackIn));
for stack = 1:length(stackIn)
    data = stackIn{stack};
    
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

% determine average pixel intensity of each frame in the control ROI
BGpixInt = cell(1,length(stackIn));
for stack = 1:length(stackIn)
    BGpixInt{stack} = mean(mean(BG_ROIstacks{stack}{1}));
end 

% do background subtraction 
stackOut = cell(1,length(stackIn));
for stack = 1:length(stackIn) 
    for frame = 1:size(BGpixInt{1},3)
        stackOut{stack}(:,:,frame) = (stackIn{stack}(:,:,frame)-BGpixInt{stack}(:,:,frame));
    end 
end 

end 