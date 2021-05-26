%% set the directory
cd(uigetdir('*.*','WHERE ARE THE PHOTOS? '));  
fileList = dir();
dir1 = fileList(1).folder;
%% register images 
%{
% set registration paramaters 
volIm = input("Is this volume imaging data? Yes = 1. No = 0. "); 
if volIm == 1
    splitType = input('How must the data be split? Serial Split = 0. Alternating Split = 1. '); 
    numZplanes = input('How many Z planes are there? ');
elseif volIm == 0
    numZplanes = 1; 
end 
noStimIdx = contains({fileList.name},'noStim');
redStimIdx = contains({fileList.name},'redStim');
noStimLoc = find(noStimIdx == 1);
redStimLoc = find(redStimIdx == 1);
% import and register no stim vids 
disp('Importing Images')
for noStimVid = 1:sum(noStimIdx)
    dir2 = fileList(noStimLoc(noStimVid)).name;
    dir3 = append(dir1,'\',dir2);
    cd(dir3)
    tifList = dir('*.tif*');
    redStackLength = size(tifList,1)/2;
    greenStackLength = size(tifList,1)/2;
    image = imread(tifList(1).name); 
    % GET IMAGES
    redImageStack_noStim = zeros(size(image,1),size(image,2),redStackLength);
    for frame = 1:redStackLength 
        image = imread(tifList(frame).name); 
        redImageStack_noStim(:,:,frame) = image;
    end 
    count = 1; 
    greenImageStack_noStim = zeros(size(image,1),size(image,2),greenStackLength);
    for frame = redStackLength+1:(greenStackLength*2) 
        image = imread(tifList(frame).name); 
        greenImageStack_noStim(:,:,count) = image;
        count = count + 1;
    end 
    % MOTION CORRECTION 
    % separate volume imaging data into separate stacks per z plane and motion correction
    if volIm == 1
        disp('Separating Z-planes')
        %reorganize data by zPlane and prep for motion correction 
        [gZstacks] = splitStacks(greenImageStack_noStim,splitType,numZplanes);
        [gVolStack] = reorgVolStack(greenImageStack_noStim,splitType,numZplanes);
        [rZstacks] = splitStacks(redImageStack_noStim,splitType,numZplanes);
        [rVolStack] = reorgVolStack(redImageStack_noStim,splitType,numZplanes);        
        %3D registration     
        disp('3D Motion Correction')
        %need minimum 4 planes in Z for 3D registration to work-time to interpolate
        gVolStack5 = zeros(size(gVolStack,1),size(gVolStack,2),size(gVolStack,3)+size(gVolStack,3)-1,size(gVolStack,4));
        rVolStack5 = zeros(size(rVolStack,1),size(rVolStack,2),size(gVolStack,3)+size(gVolStack,3)-1,size(gVolStack,4));
        for ind = 1:size(gVolStack,4)
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
        ggRegVolStack = zeros(size(gVolStack,1),size(gVolStack,2),size(gVolStack,3)+size(gVolStack,3)-1,size(gVolStack,4));
        rrRegVolStack = zeros(size(gVolStack,1),size(gVolStack,2),size(gVolStack,3)+size(gVolStack,3)-1,size(gVolStack,4));
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
        gTemplate = mean(greenImageStack_noStim(:,:,1:42),3);
        [ggRegStack,~] = registerVesStack(greenImageStack_noStim,gTemplate);  
        ggRegZstacks{1} = ggRegStack;
    %     rTemplate = mean(redImageStack,3);
        rTemplate = mean(redImageStack_noStim(:,:,1:42),3);
        [rrRegStack,~] = registerVesStack(redImageStack_noStim,rTemplate);  
        rrRegZstacks{1} = rrRegStack;

        %package data for output 
        regStacks{2,1} = ggRegZstacks; regStacks{1,1} = 'ggRegZstacks';
        regStacks{2,2} = rrRegZstacks; regStacks{1,2} = 'rrRegZstacks';  
    end 
    % CHECK REGISTRATION
    if noStimVid == 1 
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
        regQualityCheck = input('Does the motion correction look okay? Input 1 for yes or 0 for no. ');
    end 
    % SAVE REGISTERED STACKS 
    if regQualityCheck == 1
        %make the directory and save the images 
        filename = sprintf('%s/regStacks_noStimVid_%d',dir1,noStimVid);
        save(filename,'regStacks')
    end     
end 
% import and register red stim vids 
for redStimVid = 1:sum(redStimIdx)
    dir2 = fileList(redStimLoc(redStimVid)).name;
    dir3 = append(dir1,'\',dir2);
    cd(dir3)
    tifList = dir('*.tif*');
    redStackLength = size(tifList,1)/2;
    greenStackLength = size(tifList,1)/2;
    image = imread(tifList(1).name); 
    % GET IMAGES
    redImageStack_noStim = zeros(size(image,1),size(image,2),redStackLength);
    for frame = 1:redStackLength 
        image = imread(tifList(frame).name); 
        redImageStack_noStim(:,:,frame) = image;
    end 
    count = 1; 
    greenImageStack_noStim = zeros(size(image,1),size(image,2),greenStackLength);
    for frame = redStackLength+1:(greenStackLength*2) 
        image = imread(tifList(frame).name); 
        greenImageStack_noStim(:,:,count) = image;
        count = count + 1;
    end 
    % MOTION CORRECTION 
    % separate volume imaging data into separate stacks per z plane and motion correction
    if volIm == 1
        disp('Separating Z-planes')
        %reorganize data by zPlane and prep for motion correction 
        [gZstacks] = splitStacks(greenImageStack_noStim,splitType,numZplanes);
        [gVolStack] = reorgVolStack(greenImageStack_noStim,splitType,numZplanes);
        [rZstacks] = splitStacks(redImageStack_noStim,splitType,numZplanes);
        [rVolStack] = reorgVolStack(redImageStack_noStim,splitType,numZplanes);        
        %3D registration     
        disp('3D Motion Correction')
        %need minimum 4 planes in Z for 3D registration to work-time to interpolate
        gVolStack5 = zeros(size(gVolStack,1),size(gVolStack,2),size(gVolStack,3)+size(gVolStack,3)-1,size(gVolStack,4));
        rVolStack5 = zeros(size(rVolStack,1),size(rVolStack,2),size(gVolStack,3)+size(gVolStack,3)-1,size(gVolStack,4));
        for ind = 1:size(gVolStack,4)
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
        ggRegVolStack = zeros(size(gVolStack,1),size(gVolStack,2),size(gVolStack,3)+size(gVolStack,3)-1,size(gVolStack,4));
        rrRegVolStack = zeros(size(gVolStack,1),size(gVolStack,2),size(gVolStack,3)+size(gVolStack,3)-1,size(gVolStack,4));
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
        gTemplate = mean(greenImageStack_noStim(:,:,1:25),3);
        [ggRegStack,~] = registerVesStack(greenImageStack_noStim,gTemplate);  
        ggRegZstacks{1} = ggRegStack;
    %     rTemplate = mean(redImageStack,3);
        rTemplate = mean(redImageStack_noStim(:,:,1:25),3);
        [rrRegStack,~] = registerVesStack(redImageStack_noStim,rTemplate);  
        rrRegZstacks{1} = rrRegStack;

        %package data for output 
        regStacks{2,1} = ggRegZstacks; regStacks{1,1} = 'ggRegZstacks';
        regStacks{2,2} = rrRegZstacks; regStacks{1,2} = 'rrRegZstacks';  
    end 
    % CHECK REGISTRATION
    if redStimVid == 1 
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
        regQualityCheck = input('Does the motion correction look okay? Input 1 for yes or 0 for no. ');
    end 
    % SAVE REGISTERED STACKS 
    if regQualityCheck == 1
        %make the directory and save the images 
        filename = sprintf('%s/regStacks_redStimVid_%d',dir1,redStimVid);
        save(filename,'regStacks')
    end     
end 
%}

regQ = input('Input 1 if image registration is complete. ');
if regQ == 1 
    clearvars -except fileList dir1
end 

%% get registered images, create ROI, and extract florescence data 
%{
% set paramaters 
chColor = input('Input 0 for green channel. Input 1 for red channel. '); 
cd(dir1)
regMatFiles = dir('*.mat*');
noStimIdx = contains({regMatFiles.name},'noStim');
redStimIdx = contains({regMatFiles.name},'redStim');
noStimLoc = find(noStimIdx == 1);
redStimLoc = find(redStimIdx == 1);
% no stim data 
meanPixInt_noStim = zeros(length(noStimLoc),1);
for noStimVid = 1:length(noStimLoc)
    regMatFileName = regMatFiles(noStimLoc(noStimVid)).name;
    regMat = matfile(regMatFileName);
    regStacks = regMat.regStacks;
    if chColor == 0 % green channel 
        data = regStacks{2,1}{1};
    elseif chColor == 1 % red channel 
        data = regStacks{2,2}{1};
    end 
    if noStimVid == 1 
        % create ROI
        imshow(mean(data(:,:,1:20),3),[100 150]) 
        ROIdata = drawfreehand(gca);  % manually draw outline
        ROIinds = ROIdata.Position;
        outLineQ = input('Input 1 if you are done drawing the ROI. ');
        if outLineQ == 1
            close all
        end 
    end 
    % get the mean change in pixel intensity over time 
    BW = poly2mask(ROIinds(:,1),ROIinds(:,2),size(data,1),size(data,2)); % create mask from hand drawn ROI 
    for frame = 1:size(data,3)
        Frame = data(:,:,frame);
        Frame(~BW) = 0; % apply mask to image
        meanPixInt_noStim(noStimVid,frame) = mean(Frame(BW));
    end 
end 
% red stim data 
meanPixInt_redStim = zeros(length(redStimLoc),1);
for redStimVid = 1:length(redStimLoc)
    regMatFileName = regMatFiles(redStimLoc(redStimVid)).name;
    regMat = matfile(regMatFileName);
    regStacks = regMat.regStacks;
    if chColor == 0 % green channel 
        data = regStacks{2,1}{1};
    elseif chColor == 1 % red channel 
        data = regStacks{2,2}{1};
    end 
    % get the mean change in pixel intensity over time 
    BW = poly2mask(ROIinds(:,1),ROIinds(:,2),size(data,1),size(data,2)); % create mask from hand drawn ROI 
   
    for frame = 1:size(data,3)
        Frame = data(:,:,frame);
        Frame(~BW) = 0; % apply mask to image
        meanPixInt_redStim(redStimVid,frame) = mean(Frame(BW));
    end 
end 
% replace 0s with NaNs 
meanPixInt_noStim(meanPixInt_noStim==0) = NaN;
meanPixInt_redStim(meanPixInt_redStim==0) = NaN;
%}

% save the fluorescence data 
dataExtractionQ = input('Input 1 if the fluorescence data has been extracted. ');
if dataExtractionQ == 1 
    animal = input('What animal is this? ');
    filename = sprintf('%s_Fdata',animal);
    save(filename,'meanPixInt_noStim','meanPixInt_redStim')
end 

%% determine the correct frame rate THE FRAME RATE REPORTED IN THE METADATA FOR 1P IMAGING IS NOT CORRECT
% find where the stim frames are 

stimTime = input('How long was the stimulus on for (sec)? ');
stimFrames = cell(1,size(meanPixInt_redStim,1));
lastStimFrames = cell(1,size(meanPixInt_redStim,1));
firstStimFrames = cell(1,size(meanPixInt_redStim,1));
stimFrameDiff = cell(1,size(meanPixInt_redStim,1));
maxStimFrameNums = cell(1,size(meanPixInt_redStim,1));
firstMaxStim = cell(1,size(meanPixInt_redStim,1));
firstMaxStimStartAndEndFrames = cell(1,size(meanPixInt_redStim,1));
MaxStimFrameDiff = zeros(1,size(meanPixInt_redStim,1));
realFPS = zeros(1,size(meanPixInt_redStim,1));
lastStimTimes = cell(1,size(meanPixInt_redStim,1));
count = 1;
count2 = 1;
for imBlock = 1:size(meanPixInt_redStim,1)
    plot(meanPixInt_redStim(imBlock,:))
    disp('Figure out where the stimulus threshold is. ');
    stimThresh = input(sprintf('What is the stimulus threshold for imaging block #%d? ',imBlock));
    stimFrames{imBlock} = find(meanPixInt_redStim(imBlock,:) > stimThresh);
    for stimFrame = 1:length(stimFrames{imBlock})
        if stimFrame < length(stimFrames{imBlock}) && stimFrames{imBlock}(stimFrame+1)-stimFrames{imBlock}(stimFrame) > 1 
            lastStimFrames{imBlock}(count) = stimFrames{imBlock}(stimFrame);
            count = count + 1;
        elseif stimFrame == length(stimFrames{imBlock}) && stimFrames{imBlock}(stimFrame)-stimFrames{imBlock}(stimFrame-1) == 1
            lastStimFrames{imBlock}(count) = stimFrames{imBlock}(stimFrame);
            count = count + 1;
        end 
        if stimFrame > 1 && stimFrames{imBlock}(stimFrame)-stimFrames{imBlock}(stimFrame-1) > 1 
            firstStimFrames{imBlock}(count2) = stimFrames{imBlock}(stimFrame);
            count2 = count2 + 1;
        elseif stimFrame == 1 && stimFrames{imBlock}(stimFrame+1)-stimFrames{imBlock}(stimFrame) == 1
            firstStimFrames{imBlock}(count2) = stimFrames{imBlock}(stimFrame);
            count2 = count2 + 1;
        elseif stimFrame == 1 && stimFrames{imBlock}(stimFrame+1)-stimFrames{imBlock}(stimFrame) > 1
            firstStimFrames{imBlock}(count2) = stimFrames{imBlock}(stimFrame);
            count2 = count2 + 1;
        end 
    end 
    % determine the true frame rate 
    if length(lastStimFrames{imBlock}) < length(firstStimFrames{imBlock})
        firstStimFrames{imBlock} = firstStimFrames{imBlock}(1:length(lastStimFrames{imBlock}));
    end 
    stimFrameDiff{imBlock} = (lastStimFrames{imBlock} - firstStimFrames{imBlock});
    maxStimFrameNums{imBlock} = max(stimFrameDiff{imBlock});
    firstMaxStim{imBlock} = find(stimFrameDiff{imBlock} == maxStimFrameNums{imBlock},1,'first');
    firstMaxStimStartAndEndFrames{imBlock} = [firstStimFrames{imBlock}(firstMaxStim{imBlock}), lastStimFrames{imBlock}(firstMaxStim{imBlock})];
    MaxStimFrameDiff(imBlock) = diff(firstMaxStimStartAndEndFrames{imBlock});
    realFPS(imBlock) = (MaxStimFrameDiff(imBlock)+1)/stimTime;
    lastStimTimes{imBlock} = lastStimFrames{imBlock}/realFPS(imBlock);
end 
realFPS = mode(realFPS);



%% create event triggered average (one mouse at a time)
%{
% align data to lastStimFrame
clear stimArray
windTimeLen = input('How long should the window be in sec? ');
lengthImBlocks = sum(~isnan(meanPixInt_redStim),2);
count = 1;
for imBlock = 1:size(meanPixInt_redStim,1)
    for stim = 1:length(lastStimTimes{imBlock})
        if lastStimFrames{imBlock}(stim)-(floor(windTimeLen/2)*realFPS) > 0 && lastStimFrames{imBlock}(stim)+(floor(windTimeLen/2)*realFPS) <   lengthImBlocks(imBlock)
            stimArray(count,:) = meanPixInt_redStim(imBlock,lastStimFrames{imBlock}(stim)-(floor(windTimeLen/2)*realFPS):lastStimFrames{imBlock}(stim)+(floor(windTimeLen/2)*realFPS));
        end 
        count = count + 1;
    end 
end 
% remove rows full of zeros 
stimArray = stimArray(any(stimArray,2),:);
% average and determine 95% CI for the first 5 trials 
SEM = (nanstd(stimArray))/(sqrt(size(stimArray,1))); % Standard Error            
ts_Low = tinv(0.025,size(stimArray,1)-1);% T-Score for 95% CI
ts_High = tinv(0.975,size(stimArray,1)-1);% T-Score for 95% CI
CI_Low = (nanmean(stimArray,1)) + (ts_Low*SEM);  % Confidence Intervals
CI_High = (nanmean(stimArray,1)) + (ts_High*SEM);  % Confidence Intervals
x = 1:size(stimArray,2);
% create averages for different number of trials 
avData = nanmean(stimArray,1);
% avDataFrist3stims = nanmean(stimArray(1:3,:),1);
% avDataFrist5stims = nanmean(stimArray(1:5,:),1);
% plot averaged data and set threshold to identify light stim 
plot(avData)
disp('Figure out where the stimulus threshold is. ');
stimThresh = input('What is the stimulus threshold? ');
stimFrames = find(avData > stimThresh);
% normalize data 
% normWindowTimeSize = input('How many seconds before stim start do you want to normalize to? ');
% normWindowFrameNum = round(realFPS*normWindowTimeSize);
% norm_avData = ((avData./nanmean((avData(stimFrames(1)-1-normWindowFrameNum:stimFrames(1)-1))))*100)-100;
% norm_CI_Low = ((CI_Low./nanmean((CI_Low(stimFrames(1)-1-normWindowFrameNum:stimFrames(1)-1))))*100)-100;
% norm_CI_High = ((CI_High./nanmean((CI_High(stimFrames(1)-1-normWindowFrameNum:stimFrames(1)-1))))*100)-100;
norm_avData = ((avData./nanmean((avData(1:realFPS*1))))*100)-100;
norm_CI_Low = ((CI_Low./nanmean((CI_Low(1:realFPS*1))))*100)-100;
norm_CI_High = ((CI_High./nanmean((CI_High(1:realFPS*1))))*100)-100;
% % normalise the first 5 trials 
% norm_avDataFrist5stims = (avDataFrist5stims./mean(avDataFrist5stims(1:9)))*100;
% plot 
Frames = size(stimArray,2);
Frames_pre_stim_start = -((Frames-1)/2); 
Frames_post_stim_start = (Frames-1)/2; 
sec_TimeVals = (((Frames_pre_stim_start:realFPS*2:Frames_post_stim_start)/realFPS));
if Frames > 100
    FrameVals = (1:realFPS*2:Frames)+11;
elseif Frames < 100
    FrameVals = (1:realFPS*2:Frames)+1; 
end 
figure 
ax=gca;
plot(norm_avData,'b','LineWidth',3)
patch([x fliplr(x)],[norm_CI_Low fliplr(norm_CI_High)],'b','EdgeColor','none')            
alpha(0.3)
ylim([-0.005 0.03])
xlim([1 length(avData)])
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;   
ax.FontSize = 25;
ax.FontName = 'Arial';
xlabel('time (s)','FontName','Arial')
ylabel('BBB Permeability Percent Change','FontName','Arial')

% figure
% ax=gca;
% hold all
% normStimArray = ((stimArray./nanmean((stimArray(:,stimFrames(1)-1-normWindowFrameNum:stimFrames(1)-1)),2))*100)-100;     
% for trace = 1:size(normStimArray,1)
%     plot(normStimArray(trace,:),'r','LineWidth',1)
% end 
% plot(norm_avData,'k','LineWidth',3)
% ylim([-0.1 0.3])
% xlim([1 length(avData)])
% ax.XTick = FrameVals;
% ax.XTickLabel = sec_TimeVals;   
% ax.FontSize = 25;
% ax.FontName = 'Times';
% xlabel('time (s)','FontName','Arial')
% ylabel('BBB Permeability Percent Change','FontName','Times')

%% save the data 
saveQ = input('Input 1 if you want to save the averaged data. ');
if saveQ == 1 
    cd(uigetdir('*.*','WHERE DO YOU WANT TO SAVE THE AVERAGED DATA? '));  
    animal = input('What animal is this? ');
    filename = sprintf('%s_avFdata',animal);
    save(filename,'avData')
end 

%% 
      
%}

%% create event triggred average (across mice) %THIS NEEDS WORK-NEED TO WRITE OWN UPSAMPLING CODE
%{
% get the data 
mouseNum = input('How many mice do you want to average across? ');
avData = cell(1,mouseNum);
FPS = zeros(1,mouseNum);
lenData = zeros(1,mouseNum); 
for mouse = 1:mouseNum
    text = sprintf('WHERE IS THE DATA FOR MOUSE %d? ',mouse);
    cd(uigetdir('*.*',text));  
    MatFile = dir('*_avFdata.mat*');    
    MatFileName = MatFile.name;    
    workspace = matfile(MatFileName);
    avData{mouse} = workspace.avData;    
    FPS(mouse) = workspace.realFPS;
    lenData(mouse) = length(avData{mouse});
end 

% resample if you need to 
lenDiff = diff(lenData);
data = zeros(mouseNum,max(lenData));
if any(lenDiff) == 0 % returns 0 if all elements are 0 (means data does not need to be resample)
    for mouse = 1:mouseNum
        data(mouse,:) = avData{mouse};
    end 
    FPS = FPS(1);
elseif any(lenDiff) == 1 % returns 1 if any elements are not 0 (data needs to be resampled)
    FPS = max(FPS);
    maxLen = max(lenData);
    %@@@@@@@@@@@@@@@@@@@@@@@@@@
    %THIS IS OUTPUTTING THE RIGHT LENGTH, BUT THE RESAMPLE FUNCTION IS
    %ADDING ARTIFACTS 
    %PICK UP HERE- NEED TO WRITE MY OWN RESAMPLING CODE ESSENTIALLY
    n = 5;
    beta = 40;
    for mouse = 1:mouseNum
        data(mouse,:) = resample(avData{mouse},maxLen,length(avData{mouse}),n,beta);
    end 
end 
figure;hold all; plot(data(1,:));plot(data(2,:));plot(data(3,:));
%% plot 
% average and determine 95% CI for the first 5 trials 
SEM = (nanstd(data))/(sqrt(size(data,1))); % Standard Error      
ts_Low = tinv(0.025,size(data,1)-1);% T-Score for 95% CI
ts_High = tinv(0.975,size(data,1)-1);% T-Score for 95% CI
CI_Low = (nanmean(data,1)) + (ts_Low*SEM);  % Confidence Intervals
CI_High = (nanmean(data,1)) + (ts_High*SEM);  % Confidence Intervals
x = 1:size(data,2);
% create averages for different number of trials 
avData = nanmean(data,1);
% plot averaged data and set threshold to identify light stim 
plot(avData)
disp('Figure out where the stimulus threshold is. ');
stimThresh = input('What is the stimulus threshold? ');
stimFrames = find(avData > stimThresh);
% normalize data 
norm_avData = ((avData./nanmean((avData(1:FPS*1))))*100)-100;
norm_CI_Low = ((CI_Low./nanmean((CI_Low(1:FPS*1))))*100)-100;
norm_CI_High = ((CI_High./nanmean((CI_High(1:FPS*1))))*100)-100;
% % normalise the first 5 trials 
% norm_avDataFrist5stims = (avDataFrist5stims./mean(avDataFrist5stims(1:9)))*100;
% plot 
Frames = size(data,2);
Frames_pre_stim_start = -((Frames-1)/2); 
Frames_post_stim_start = (Frames-1)/2; 
sec_TimeVals = (((Frames_pre_stim_start:FPS*2:Frames_post_stim_start)/FPS));
if Frames > 100
    FrameVals = (1:FPS*2:Frames)+11;
elseif Frames < 100
    FrameVals = (1:FPS*2:Frames)+1; 
end 
figure 
ax=gca;
plot(norm_avData,'k','LineWidth',3)
patch([x fliplr(x)],[norm_CI_Low fliplr(norm_CI_High)],'k','EdgeColor','none')            
alpha(0.3)
ylim([-0.005 0.03])
xlim([1 length(avData)])
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;   
ax.FontSize = 25;
ax.FontName = 'Arial';
xlabel('time (s)','FontName','Arial')
ylabel('BBB Permeability Percent Change','FontName','Arial')
%}

%% compare stim and no stim imaging block time series (entire video)
%{
% remove stim artifacts from F traces 
noStim_Fdata = meanPixInt_noStim;
redStim_Fdata = meanPixInt_redStim;
redStim_Fdata(redStim_Fdata>800) = NaN;
% normalize data to first 42 frames 
norm_redStim_Fdata = (redStim_Fdata./nanmean(redStim_Fdata(:,1:40),2))*100;
norm_noStim_Fdata = (noStim_Fdata./nanmean(noStim_Fdata(:,1:40),2))*100;
% plot 
Frames = size(norm_redStim_Fdata,2);
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
count = 1;
for redStimTrace = 1:size(redStim_Fdata,1)
    h(count) = plot(norm_redStim_Fdata(redStimTrace,:)-100,'r','LineWidth',1);
    count = count + 1;
end 
for noStimTrace = 1:size(noStim_Fdata,1)
    h(count) = plot(norm_noStim_Fdata(noStimTrace,:)-100,'k','LineWidth',1);
    count = count + 1;
end 
ylim([-0.3 1.5])
xlim([1 806])
ax.XTick = FrameVals;
ax.XTickLabel = min_TimeVals;   
ax.FontSize = 25;
ax.FontName = 'Times';
xlabel('time (min)','FontName','Times')
ylabel('BBB Permeability Percent Change','FontName','Times')
legend(h([1 size(redStim_Fdata,1)+size(noStim_Fdata,1)]),'stim block','no stim block')

%}





