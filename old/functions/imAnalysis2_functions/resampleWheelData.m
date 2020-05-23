function [ResampedVel_wheel_data] = resampleWheelData(reg_Stacks,vel_wheel_data)

if size(reg_Stacks{1},3)*length(vel_wheel_data) > 2^31       
    ResampedVel_wheel_data1 = resample(vel_wheel_data,length(vel_wheel_data)/100,length(vel_wheel_data));
    ResampedVel_wheel_data = resample(ResampedVel_wheel_data1,size(reg_Stacks{1},3),length(ResampedVel_wheel_data1));        
elseif size(reg_Stacks{1},3)*length(vel_wheel_data) < 2^31
    ResampedVel_wheel_data = resample(vel_wheel_data,size(reg_Stacks{1},3),length(vel_wheel_data)); 
end
end 