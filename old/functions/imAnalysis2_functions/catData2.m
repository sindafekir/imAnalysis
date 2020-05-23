function [testData3] = catData2(testData,testData2)

% if there are some missing trial types, dataArrays, won't be the same size
% so make the sizes the same first before concatenating 
for z = 1:length(testData)
    for ROI = 1:size(testData{1},2)
        if size(testData2{z}{ROI},2) < size(testData{z}{ROI},2)
            for trialType = size(testData2{z}{ROI},2)+1:size(testData{z}{ROI},2)
                testData2{z}{ROI}{trialType} = [];
            end 
        end 
    end 
end 

testData3 = cell(1,length(testData));
for z = 1:length(testData)
    for ROI = 1:size(testData{1},2)
        for trialType = 1:size(testData{1}{1},2)
            if isempty(testData2{z}{ROI}{trialType}) == 0 || trialType > size(testData2{1}{1},2)
                testData3{z}{ROI}{trialType} = horzcat(testData{z}{ROI}{trialType},testData2{z}{ROI}{trialType});  
            elseif isempty(testData2{z}{ROI}{trialType}) == 1
                testData3{z}{ROI}{trialType} = testData{z}{ROI}{trialType}; 
            end 
        end 
    end 
end 



end 