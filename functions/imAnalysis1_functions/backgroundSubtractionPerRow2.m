function [stackOut] = backgroundSubtractionPerRow2(reg__Stacks,BG_ROIboundData)

ROIstacks = cell(1,length(reg__Stacks));
for z = 1:length(reg__Stacks)
    for i = 1:length(BG_ROIboundData{2,1}{z})
        % get the back ground ROI coordinates 
        xmins = BG_ROIboundData{2,1}{z}(i);
        ymins = BG_ROIboundData{2,3}{z}(i);
        widths = BG_ROIboundData{2,5}{z}(i);
        heights = BG_ROIboundData{2,6}{z}(i);
        % use previously defined back ground ROI coordinates to select rows
        [ROI_stack] = make_ROIs_notfirst_time(reg__Stacks{z},xmins,ymins,widths,heights);
        ROIstacks{z}{i} = ROI_stack;
    end 
end 

% determine average pixel intensity of each frame and row in the control
% ROIs
BGpixInt = cell(1,length(reg__Stacks));
for z = 1:length(reg__Stacks)
    for i = 1:length(ROIstacks{z})
        BGpixInt{z}{i} = mean(ROIstacks{z}{i}{1},2);
    end 
end 

% do background subtraction per row 
stackOut = cell(1,length(reg__Stacks));
for z = 1:length(reg__Stacks)
    for i = 1:length(ROIstacks{z})        
        for frame = 1:size(ROIstacks{z}{i}{1},3)          
            stackOut{z}(BG_ROIboundData{2,3}{z}(i):BG_ROIboundData{2,4}{z}(i),:,frame) = (reg__Stacks{z}(BG_ROIboundData{2,3}{z}(i):BG_ROIboundData{2,4}{z}(i),:,frame)-BGpixInt{z}{i}(:,:,frame));
        end         
    end 
end 

end 