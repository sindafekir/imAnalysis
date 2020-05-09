function [testData3] = catData(testData,testData2,maxCells,ROIinds)

% if there are some missing trial types, dataArrays, won't be the same size
% so make the sizes the same first before concatenating 
for ccell = 1:maxCells
    if size(testData2{ROIinds(ccell)},2) < size(testData{ROIinds(ccell)},2)
    for z = 1:size(testData2{ROIinds(ccell)},1)
        for trialType = size(testData2{ROIinds(ccell)},2)+1:size(testData{ROIinds(ccell)},2)
            testData2{ROIinds(ccell)}{z,trialType} = []; 
        end 
    end 
    end 
end 

emptyTrials2 = cell(1,ROIinds(maxCells));
testData3 = cell(1,ROIinds(maxCells));
for ccell = 1:maxCells
    emptyTrials2{ROIinds(ccell)} = cellfun(@isempty, testData2{ROIinds(ccell)});
    for z = 1:size(testData2{ROIinds(ccell)},1)
        for trialType = 1:size(testData{ROIinds(ccell)},2)            
            if emptyTrials2{ROIinds(ccell)}(z,trialType) == 0  
                testData3{ROIinds(ccell)}{z,trialType} = horzcat(testData{ROIinds(ccell)}{z,trialType},testData2{ROIinds(ccell)}{z,trialType});                     
            elseif emptyTrials2{ROIinds(ccell)}(z,trialType) == 1
                testData3{ROIinds(ccell)}{z,trialType} = testData{ROIinds(ccell)}{z,trialType}; 
            end 
        end 
    end

end 
         