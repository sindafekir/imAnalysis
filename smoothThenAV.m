function [smoothedAV] = smoothThenAV(dataArray,filtTime,FPS)

for d = 1:size(dataArray,1)
    [filtD] = SmoothData(dataArray(d,:),filtTime,FPS);
    filtData(d,:) = filtD; 
end 

smoothedAV = nanmean(filtData,1);
end 
