function [VZstacks] = volStack2splitStacks(regVolStack)


for subStack = 1:size(regVolStack,3)
    for subFrame = 1:size(regVolStack,4)
        VZstacks{subStack}(:,:,subFrame) = regVolStack(:,:,subStack,subFrame);
    end 
end 
       

end 