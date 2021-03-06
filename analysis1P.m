%% set paramaters

chColor = input('Input 0 for green channel. Input 1 for red channel. '); 
framePeriod = input("What is the framePeriod? ");
FPS = 1/framePeriod; 
%% get registered images 

regImDir = uigetdir('*.*','WHERE ARE THE REGISTERED IMAGES?');
cd(regImDir);
regMatFileName = uigetfile('*.*','GET THE REGISTERED IMAGES');
regMat = matfile(regMatFileName);
regStacks = regMat.regStacks;
if chColor == 0 % green channel 
    data = regStacks{2,1}{1};
elseif chColor == 1 % red channel 
    data = regStacks{2,2}{1};
end 

%% create ROI 

imshow(mean(data(:,:,1:20),3),[100 200]) 
ROIdata = drawfreehand(gca);  % manually draw outline
ROIinds = ROIdata.Position;
outLineQ = input('Input 1 if you are done drawing the ROI. ');
if outLineQ == 1
    close all
end 

% get the mean change in pixel intensity over time 
BW = poly2mask(ROIinds(:,1),ROIinds(:,2),size(data,1),size(data,2)); % create mask from hand drawn ROI 
meanPixInt = zeros(1,size(data,3));
for frame = 1:size(data,3)
    Frame = data(:,:,frame);
    Frame(~BW) = 0; % apply mask to image
    meanPixInt(frame) = mean(Frame(BW));
end 

%% create event triggered average
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%{
%% find where the stim frames are 
%{
plot(meanPixInt)
disp('Figure out where the stimulus threshold is. ');
stimThresh = input('What is the stimulus threshold? ');
stimFrames = find(meanPixInt > stimThresh);

% find where the last stim frame is per frame 
lastStimFrames = zeros(1);
firstStimFrames = zeros(1);
count = 1;
count2 = 1;
for stimFrame = 1:length(stimFrames)
    if stimFrame < length(stimFrames) && stimFrames(stimFrame+1)-stimFrames(stimFrame) > 1 
        lastStimFrames(count) = stimFrames(stimFrame);
        count = count + 1;
    elseif stimFrame == length(stimFrames) && stimFrames(stimFrame)-stimFrames(stimFrame-1) == 1
        lastStimFrames(count) = stimFrames(stimFrame);
        count = count + 1;
    end 
    if stimFrame > 1 && stimFrames(stimFrame)-stimFrames(stimFrame-1) > 1 
        firstStimFrames(count2) = stimFrames(stimFrame);
        count2 = count2 + 1;
    elseif stimFrame == 1 && stimFrames(stimFrame+1)-stimFrames(stimFrame) == 1
        firstStimFrames(count2) = stimFrames(stimFrame);
        count2 = count2 + 1;
    elseif stimFrame == 1 && stimFrames(stimFrame+1)-stimFrames(stimFrame) > 1
        firstStimFrames(count2) = stimFrames(stimFrame);
        count2 = count2 + 1;
    end 
end 

%% get stim start times from HDF file 

HDFchartDir = uigetdir('*.*','WHERE IS THE FUNCTION NEEDED TO CREATE THE HDF CHART?');
cd(HDFchartDir);
state = 7;
[HDFchart,state_start_f,state_end_f,FPS,vel_wheel_data,TrialTypes] = makeHDFchart_redBlueStim(state,framePeriod);

%% determine the true frame rate THE FRAME RATE REPORTED IN THE METADATA FOR 1P IMAGING IS NOT CORRECT 

stimTime = input('How long was one of the longest stimuli on for (sec)? ');
stimStartAndEndFrames = input('Input start and end frames for the example stimulus. ');
stimFrameDiff = diff(stimStartAndEndFrames);
realFPS = (stimFrameDiff+1)/stimTime;
lastStimTimes = lastStimFrames/realFPS;
firstStimTimes = firstStimFrames/realFPS;
StimTimes = stimFrames/realFPS;

%}
%% align data to lastStimFrame

windTimeLen = input('How long should the window be in sec? ');
stimArray = zeros(length(lastStimTimes),((windTimeLen)*realFPS)+1);
for stim = 1:length(lastStimTimes)
    if lastStimFrames(stim)-(floor(windTimeLen/2)*realFPS) > 0 && lastStimFrames(stim)+(floor(windTimeLen/2)*realFPS) < length(meanPixInt)
        stimArray(stim,:) = meanPixInt(lastStimFrames(stim)-(floor(windTimeLen/2)*realFPS):lastStimFrames(stim)+(floor(windTimeLen/2)*realFPS));
    end 
end 
% remove rows full of zeros 
stimArray = stimArray(any(stimArray,2),:);

% average and determine 95% CI for the first 5 trials 
SEM = (nanstd(stimArray(1:5,:)))/(sqrt(size(stimArray(1:5,:),1))); % Standard Error            
ts_Low = tinv(0.025,size(stimArray(1:5,:),1)-1);% T-Score for 95% CI
ts_High = tinv(0.975,size(stimArray(1:5,:),1)-1);% T-Score for 95% CI
CI_Low = (nanmean(stimArray(1:5,:),1)) + (ts_Low*SEM);  % Confidence Intervals
CI_High = (nanmean(stimArray(1:5,:),1)) + (ts_High*SEM);  % Confidence Intervals
x = 1:size(stimArray,2);

% create averages for different number of trials 
avData = nanmean(stimArray,1);
avDataFrist3stims = nanmean(stimArray(1:3,:),1);
avDataFrist5stims = nanmean(stimArray(1:5,:),1);

% normalise the first 5 trials 
norm_avDataFrist5stims = (avDataFrist5stims./mean(avDataFrist5stims(1:9)))*100;

% plot 
Frames = size(stimArray,2);
Frames_pre_stim_start = -((Frames-1)/2); 
Frames_post_stim_start = (Frames-1)/2; 
sec_TimeVals = floor(((Frames_pre_stim_start:realFPS:Frames_post_stim_start)/realFPS))-1;
if Frames > 100
    FrameVals = (1:realFPS:Frames)+11;
elseif Frames < 100
    FrameVals = (1:realFPS:Frames)-1; 
end 

figure 
ax=gca;
plot(norm_avDataFrist5stims-100,'r','LineWidth',3)
patch([x1 fliplr(x1)],[CI_Low1-113.7 fliplr(CI_High1)-113.7],'r','EdgeColor','none')          
patch([x2 fliplr(x2)],[CI_Low2-113.7 fliplr(CI_High2)-113.7],'r','EdgeColor','none')    
alpha(0.3)
ylim([-0.05 0.13])
xlim([1 25])
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;   
ax.FontSize = 25;
ax.FontName = 'Times';
xlabel('time (s)','FontName','Times')
ylabel('BBB Permeability Percent Change','FontName','Times')

      
%}

%% compare stim and no stim imaging block time series (entire video)
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%{
%% get the control registered images 

regImDir = uigetdir('*.*','WHERE ARE THE CONTROL REGISTERED IMAGES?');
cd(regImDir);
regMatFileName = uigetfile('*.*','GET THE CONTROL REGISTERED IMAGES');
regMat = matfile(regMatFileName);
regStacks = regMat.regStacks;
if chColor == 0 % green channel 
    conData = regStacks{2,1}{1};
elseif chColor == 1 % red channel 
    conData = regStacks{2,2}{1};
end 

%% get the mean change in pixel intensity over time for the control data 

conMeanPixInt = zeros(1,size(conData,3));
for frame = 1:size(conData,3)
    Frame = conData(:,:,frame);
    Frame(~BW) = 0; % apply mask to image
    conMeanPixInt(frame) = mean(Frame(BW));
end 

% normalize data to first 42 frames 
norm_meanPixInt = (meanPixInt./mean(meanPixInt(1:42)))*100;
norm_conMeanPixInt = (conMeanPixInt./mean(conMeanPixInt(1:42)))*100;
norm_meanPixInt = norm_meanPixInt(1:806);

% plot 
Frames = size(norm_meanPixInt,2);
sec_TimeVals = floor(((1:realFPS*60:Frames)/realFPS));
min_TimeVals = floor(sec_TimeVals/60);
if Frames > 100
    FrameVals = (1:realFPS*60:Frames)-1;
elseif Frames < 100
    FrameVals = (1:realFPS*60:Frames)-1; 
end 

figure 
hold all
ax=gca;
plot(norm_meanPixInt-100,'r','LineWidth',3)
plot(norm_conMeanPixInt-100,'k','LineWidth',3)
ylim([-0.3 1.5])
xlim([1 806])
ax.XTick = FrameVals;
ax.XTickLabel = min_TimeVals;   
ax.FontSize = 25;
ax.FontName = 'Times';
xlabel('time (min)','FontName','Times')
ylabel('BBB Permeability Percent Change','FontName','Times')

%}





