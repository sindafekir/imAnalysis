function smoothAndPlotVesselData

%% smooth data 
filtTime = input('How many seconds do you want to smooth your data by? '); userInput(UIr,1) = ("How many seconds do you want to smooth your data by? "); userInput(UIr,2) = (filtTime); UIr = UIr+1;

filtData = cell(1,length(ROIstacks));
for Z = 1:length(ROIstacks)
    for trialType = 1:size(inputStacks{z},2)
        for VROI = 1:numROIs 
            if isempty(inputStacks{z}{trialType}) == 0 
                for trial = 1:size(ROIstacks{Z}{trialType},2)
                    [filtD] = MovMeanSmoothData(zData{Z}{trialType}{trial}{VROI},filtTime,FPS);
                    filtData{Z}{trialType}{trial}{VROI} = filtD;
                end 
            end 
        end 
    end 
end 

%% plot your data 
dataMin = input("data Y axis MIN: ");
dataMax = input("data Y axis MAX: ");
BBBplotDataAndRunVelocity(filtData,FPS,numZplanes,sec_before_stim_start,dataMin,dataMax,numROIs,ROIstacks,filtTime);

end 