function [testData3] = catWheelData(testData,testData2)

% if there are some missing trial types, dataArrays, won't be the same size
% so make the sizes the same first before concatenating 
if size(testData2,2) < size(testData,2)
    for trialType = size(testData2,2)+1:size(testData,2)
        testData2{trialType} = []; 
    end 
end 

emptyTrials2 = cellfun(@isempty, testData2);
testData3 = cell(1,size(testData,2));
for trialType = 1:size(testData,2)
    if emptyTrials2(trialType) == 0 
        testData3{trialType} = horzcat(testData{trialType},testData2{trialType});    
    elseif emptyTrials2(trialType) == 1
        testData3{trialType} = testData{trialType};
    end 
end 

end 