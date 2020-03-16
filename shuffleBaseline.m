%% create power spectrums of each baseline period per mouse 


% average across FOV, trial, Z, and ROI 

%% jitter baseline period start times 

%% average overlap in jittered baseline periods 

%% create power spectrums of jittered baseline period averages 


%% plot TS objects - THIS WORKS JUST NEED TO DO THIS ITERATIVELY WHEN THE TIME COMES 
endTime = 618/SF53_ROI2_FPS;
Tval2 = ((1/SF53_ROI2_FPS): (1/SF53_ROI2_FPS) : (618/SF53_ROI2_FPS));

test2 = timeseries(SF53_ROI2_Bdata{1}{4}{1}{1},Tval2);
plot(test1)
hold on
plot(test2)
