function [rotStacks] = rotateStack2(reg_Stacks,ROIrotAngle)

%% rotate if necessary 
%if the rotation is finally good, rotate the stack 
for frame = 1:size(reg_Stacks,3)
    rotStacks(:,:,frame) = imrotate(reg_Stacks(:,:,frame),ROIrotAngle);
end 

end 