function [testData3] = catData(testData,testData2,maxCells,ROIinds)

% if there are some missing trial types, dataArrays, won't be the same size
% so make the sizes the same first before concatenating 
for cell = 1:maxCells
    if size(testData2{ROIinds(cell)},2) < size(testData{ROIinds(cell)},2)
    for z = 1:size(testData2{ROIinds(cell)},1)
        for trialType = size(testData2{ROIinds(cell)},2)+1:size(testData{ROIinds(cell)},2)
            testData2{ROIinds(cell)}{z,trialType} = []; 
        end 
    end 
    end 
end 

for cell = 1:maxCells
    emptyTrials2{ROIinds(cell)} = cellfun(@isempty, testData2{ROIinds(cell)});
    for z = 1:size(testData2{ROIinds(cell)},1)
        for trialType = 1:size(testData{ROIinds(cell)},2)            
            if emptyTrials2{ROIinds(cell)}(z,trialType) == 0  
                testData3{ROIinds(cell)}{z,trialType} = horzcat(testData{ROIinds(cell)}{z,trialType},testData2{ROIinds(cell)}{z,trialType});                     
            elseif emptyTrials2{ROIinds(cell)}(z,trialType) == 1
                testData3{ROIinds(cell)}{z,trialType} = testData{ROIinds(cell)}{z,trialType}; 
            end 
        end 
    end

end 
         