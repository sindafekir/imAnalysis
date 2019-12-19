function [testData3] = catData3(testData,testData2)

% if there are some missing trial types, dataArrays, won't be the same size
% so make the sizes the same first before concatenating 
for z = 1:length(testData)   
    if size(testData2{z},2) < size(testData{z},2)
        for trialType = size(testData2{z},2)+1:size(testData{z},2)
            testData2{z}{trialType} = [];
        end 
    end     
end 

testData3 = cell(1,length(testData));
for z = 1:length(testData)
    for trialType = 1:size(testData{1},2)        
        if isempty(testData2{z}{trialType}) == 0 || trialType > size(testData2{1},2)
            testData3{z}{trialType} = horzcat(testData{z}{trialType},testData2{z}{trialType});  
        elseif isempty(testData2{z}{trialType}) == 1
            testData3{z}{trialType} = testData{z}{trialType}; 
        end 
    end     
end 

end 