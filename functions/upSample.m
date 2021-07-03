function [upSampledData] = upSample(data,upSampleSize)
    lenData = length(data); 
    diffLens = upSampleSize - lenData; 
    %how spaced apart does each number need to be? 
    factor = (diffLens/lenData)+1;
    %space number apart appropriately 
    upSampledData = NaN(1,upSampleSize);
    for dataPoint = 1:lenData 
        upSampledData((round(dataPoint*(factor+(factor/lenData))-factor))+1) = data(dataPoint);
    end 
    % interpolate data 
    upSampledData = inpaint_nans(upSampledData);
end 


