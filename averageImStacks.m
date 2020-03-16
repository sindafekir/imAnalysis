%% get just the data you need 
temp = matfile('SF58_20190627_70FITC_ROI2_V3-5_BBB');
SF_58_70FITC_ROI2_sortedStacks = temp.sortedStacks;

%% select the data you want to aveage and aveage 
data = SF_58_70FITC_ROI2_sortedStacks{1}{4};
for trial = 1:length(data)
    dataArray(:,:,:,trial) = data{trial};
end 
avData = mean(dataArray,4);
totalTime = 60; %seconds 
FPS = size(avData,3)/totalTime;

%% diaplay frame of interest 
timeOfInterest = 31; %seconds 
figure;imagesc(avData(:,:,round(timeOfInterest*FPS)))

%% make Diff image 
Im16sec = avData(:,:,round(16*FPS));
Im31sec = avData(:,:,round(31*FPS));

diffIm = Im31sec - Im16sec; 
figure;imagesc(diffIm)
%% create tiff object and then write to folder
for frame = 1:612
    avData1(:,:,frame)=avData(:,:,frame)-min(avData(:,:,frame)); % shift data such that the smallest element of A is 0
    avData2(:,:,frame)=avData1(:,:,frame)/max(max(avData1(:,:,frame))); % normalize the shifted data to 1 
    imwrite(avData2(:,:,frame),sprintf('%d.tiff',frame));
end 


% %% resample trials from different mice 
% resThis = SF58_ROI2_trials{4};
% goalLength = 594;
% for trial = 1:length(resThis)
%     RSF58{trial} = resample(resThis{trial},goalLength,length(resThis{trial}));
% end 
% 
% RSF58 = SF58_ROI2_trials{4};
% 
% for trial = 1:22
%     SF58array(trial,:) = RSF58{trial};
% end 
% 
% Tiff(avData,'SF58_2090627_ROI2_plumeExample.tif')
