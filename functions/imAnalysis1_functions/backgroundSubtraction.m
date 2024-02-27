function [stackOut,BG_ROIboundData,CaROImask] = backgroundSubtraction(reg__Stacks)

if iscell(reg__Stacks) == 0 
    reg__Stacks2{1} = reg__Stacks;
elseif iscell(reg__Stacks) == 1 
    reg__Stacks2 = reg__Stacks;
end 

% apply mask to each frame to get background pixel intensity per row 
BG_ROIboundData = cell(1,length(reg__Stacks2));
BG_ROIstacks = cell(1,length(reg__Stacks2));
for stack = 1:length(reg__Stacks2)
    data = reg__Stacks2{stack};
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
BGpixInt = cell(1,length(reg__Stacks2));
for stack = 1:length(reg__Stacks2)
    BGpixInt{stack} = mean(mean(BG_ROIstacks{stack}{1}));
end 

% do background subtraction 
stackOut = cell(1,length(reg__Stacks2));
for stack = 1:length(reg__Stacks2) 
    for frame = 1:size(BGpixInt{1},3)
        if iscell(reg__Stacks) == 0 
            stackOut{stack}(:,:,frame) = (reg__Stacks(:,:,frame)-BGpixInt{stack}(:,:,frame));
        elseif iscell(reg__Stacks) == 1 
            stackOut{stack}(:,:,frame) = (reg__Stacks{stack}(:,:,frame)-BGpixInt{stack}(:,:,frame));
        end  
    end 
end 

end 