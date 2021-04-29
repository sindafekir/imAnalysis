%% register images 

% set registration paramaters 
volIm = input("Is this volume imaging data? Yes = 1. No = 0. "); 
if volIm == 1
    splitType = input('How must the data be split? Serial Split = 0. Alternating Split = 1. '); 
    numZplanes = input('How many Z planes are there? ');
elseif volIm == 0
    numZplanes = 1; 
end 

% get images 
disp('Importing Images')
cd(uigetdir('*.*','WHERE ARE THE PHOTOS? '));  
fileList = dir();
%PICK UP HERE ~ 
numNoStimTrials = sum(fileList.name(:)=='noStim');
numStimTrials = ;

%fileList = dir('*.tif*');

imStackDir = fileList(1).folder; 
greenStackLength = size(fileList,1)/2;
redStackLength = size(fileList,1)/2;
image = imread(fileList(1).name); 
redImageStack = zeros(size(image,1),size(image,2),redStackLength);
for frame = 1:redStackLength 
    image = imread(fileList(frame).name); 
    redImageStack(:,:,frame) = image;
end 
count = 1; 
greenImageStack = zeros(size(image,1),size(image,2),greenStackLength);
for frame = redStackLength+1:(greenStackLength*2) 
    image = imread(fileList(frame).name); 
    greenImageStack(:,:,count) = image;
    count = count + 1;
end 

%% separate volume imaging data into separate stacks per z plane and motion correction
%{
if volIm == 1
    disp('Separating Z-planes')
    %reorganize data by zPlane and prep for motion correction 
    [gZstacks] = splitStacks(greenImageStack,splitType,numZplanes);
    [gVolStack] = reorgVolStack(greenImageStack,splitType,numZplanes);
    [rZstacks] = splitStacks(redImageStack,splitType,numZplanes);
    [rVolStack] = reorgVolStack(redImageStack,splitType,numZplanes);        

    %3D registration     
    disp('3D Motion Correction')
    %need minimum 4 planes in Z for 3D registration to work-time to interpolate
    gVolStack5 = zeros(size(gVolStack,1),size(gVolStack,2),size(gVolStack,3)+size(gVolStack,3)-1,size(gVolStack,4));
    rVolStack5 = zeros(size(rVolStack,1),size(rVolStack,2),size(gVolStack,3)+size(gVolStack,3)-1,size(gVolStack,4));
    tic
    parfor ind = 1:size(gVolStack,4)
        count = 1;
        for zplane = 1:size(gVolStack,3)+size(gVolStack,3)-1
            if rem(zplane,2) == 0
                gVolStack5(:,:,zplane,ind) = mean(gVolStack(:,:,count-1:count,ind),3);
                rVolStack5(:,:,zplane,ind) = mean(rVolStack(:,:,count-1:count,ind),3);
            elseif rem(zplane,2) == 1 
                gVolStack5(:,:,zplane,ind) = gVolStack(:,:,count,ind);
                rVolStack5(:,:,zplane,ind) = rVolStack(:,:,count,ind);
                count = count +1;
            end 
        end 
    end 
    toc
    gTemplate = mean(gVolStack5,4);
    rTemplate = mean(rVolStack5,4);
    %create optimizer and metric, setting modality to multimodal because the
    %template and actual images look different (as template is mean = smoothed)
    [optimizer, metric] = imregconfig('multimodal')    ;
    %tune the poperties of the optimizer
    optimizer.InitialRadius = 0.004;
    optimizer.Epsilon = 1.5;
    optimizer.GrowthFactor = 1.01;
    optimizer.MaximumIterations = 300;
    for ind = 1:size(gVolStack,4)
        ggRegVolStack(:,:,:,ind) = imregister(gVolStack5(:,:,:,ind),gTemplate,'affine', optimizer, metric,'PyramidLevels',1);
        rrRegVolStack(:,:,:,ind) = imregister(rVolStack5(:,:,:,ind),rTemplate,'affine', optimizer, metric,'PyramidLevels',1);
    end 
    [ggVZstacks5] = volStack2splitStacks(ggRegVolStack);
    [rrVZstacks5] = volStack2splitStacks(rrRegVolStack);
    %get rid of extra z planes
    count = 1; 
    ggVZstacks3 = cell(1,size(gZstacks,2));
    rrVZstacks3 = cell(1,size(gZstacks,2));
    for zPlane = 1:size(gZstacks,2)
        ggVZstacks3{zPlane} = ggVZstacks5{count};
        rrVZstacks3{zPlane} = rrVZstacks5{count};
        count = count+2;
    end 

    %package data for output 
    regStacks{2,3} = ggVZstacks3; regStacks{1,3} = 'ggVZstacks3';     
    regStacks{2,4} = rrVZstacks3; regStacks{1,4} = 'rrVZstacks3';

elseif volIm == 0   
    disp('2D Motion Correction')
    %2D register imaging data    
%     gTemplate = mean(greenImageStack,3);
    gTemplate = mean(greenImageStack(:,:,1:42),3);
    [ggRegStack,~] = registerVesStack(greenImageStack,gTemplate);  
    ggRegZstacks{1} = ggRegStack;
%     rTemplate = mean(redImageStack,3);
    rTemplate = mean(redImageStack(:,:,1:42),3);
    [rrRegStack,~] = registerVesStack(redImageStack,rTemplate);  
    rrRegZstacks{1} = rrRegStack;

    %package data for output 
    regStacks{2,1} = ggRegZstacks; regStacks{1,1} = 'ggRegZstacks';
    regStacks{2,2} = rrRegZstacks; regStacks{1,2} = 'rrRegZstacks';  
end 
%}

%% check registration 
%{
if volIm == 1     
    %check relationship b/w template and 3D registered images
    count = 1; 
    ggTemp2regCorr3D = zeros(size(gZstacks,2),size(ggVZstacks3{1},3));
    rrTemp2regCorr3D = zeros(size(rZstacks,2),size(rrVZstacks3{1},3));
    for zPlane = 1:size(gZstacks,2)
        for ind = 1:size(ggVZstacks3{1},3)
            ggTemp2regCorr3D(zPlane,ind) = corr2(gTemplate(:,:,count),ggVZstacks3{zPlane}(:,:,ind));
            rrTemp2regCorr3D(zPlane,ind) = corr2(rTemplate(:,:,count),rrVZstacks3{zPlane}(:,:,ind));
        end 
        count = count+2;
    end 
    %plot 3D registration for comparison 
    figure;
    subplot(1,2,1);
    hold all; 
    for zPlane = 1:size(gZstacks,2)
        plot(ggTemp2regCorr3D(zPlane,:));
        title({'Correlation Coefficient of 3D Motion Correction Template and Output';'Green Channel Registered with Green Channel Template'}); 
    end 
    subplot(1,2,2);
    hold all; 
    for zPlane = 1:size(rZstacks,2)
        plot(rrTemp2regCorr3D(zPlane,:));
        title({'Correlation Coefficient of 3D Motion Correction Template and Output';'Red Channel Registered with Red Channel Template'}); 
    end     
elseif volIm == 0 
    %check relationship b/w template and 2D registered images     
    ggTemp2regCorr2D = zeros(1,size(ggRegZstacks{1},3));
    rrTemp2regCorr2D = zeros(1,size(rrRegZstacks{1},3));
    for ind = 1:size(ggRegZstacks{1},3)
        ggTemp2regCorr2D(ind) = corr2(gTemplate,ggRegZstacks{1}(:,:,ind));
        rrTemp2regCorr2D(ind) = corr2(rTemplate,rrRegZstacks{1}(:,:,ind));
    end 
    %plot 2D registrations for comparison 
    figure;
    subplot(1,2,1);
    plot(ggTemp2regCorr2D);
    title({'Correlation Coefficient of 2D Motion Correction Template and Output';'Green Channel Registered with Green Channel Template'}); 
    subplot(1,2,2);
    plot(rrTemp2regCorr2D);
    title({'Correlation Coefficient of 2D Motion Correction Template and Output';'Red Channel Registered with Red Channel Template'}); 
end 
%}

%% save registered stacks 
%{
clearvars -except regStacks
vid = input('What number video is this? '); 

%make the directory and save the images 
dir1 = input('What folder are you saving these images in? ');
dir2 = strrep(dir1,'\','/');
filename = sprintf('%s/regStacks_vid%d',dir2,vid);
save(filename)
%}

%}
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
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





