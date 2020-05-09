function [rotStacks] = rotateStack2(reg_Stacks,ROIrotAngle)

%% rotate if necessary 
rotStacks = cell(1,length(reg_Stacks));
for stack = 1:length(reg_Stacks)  
   %if the rotation is finally good, rotate the stack 
    for frame = 1:size(reg_Stacks{stack},3)
        rotStacks{stack}(:,:,frame) = imrotate(reg_Stacks{stack}(:,:,frame),ROIrotAngle);
    end 
end 
end 