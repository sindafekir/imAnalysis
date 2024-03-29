%% register the raw data (run this for each video) 
%{
%% set the paramaters 
volIm = input("Is this volume imaging data? Yes = 1. No = 0. "); 
if volIm == 1
    splitType = input('How must the data be split? Serial Split = 0. Alternating Split = 1. '); 
    numZplanes = input('How many Z planes are there? ');
elseif volIm == 0
    numZplanes = 1; 
end 
%% get the images 
disp('Importing Images')
cd(uigetdir('*.*','WHERE ARE THE PHOTOS? '));    
fileList = dir('*.tif*');
imStackDir = fileList(1).folder; 
redChanQ = input('Input 1 to import red channel. Input 0 otherwise. ');
greenChanQ = input('Input 1 to import green channel. Input 0 otherwise. ');
frameAvQ = input('Input 1 if you need to downsample the data in any dimension. Input 0 otherwise. ');
if frameAvQ == 0 
    if redChanQ == 1 
        redStackLength = size(fileList,1)/2;
        image = imread(fileList(1).name); 
        redImageStack = zeros(size(image,1),size(image,2),redStackLength);
        for frame = 1:redStackLength 
            image = imread(fileList(frame).name); 
            redImageStack(:,:,frame) = image;
        end 
    end 
    if greenChanQ == 1 
        greenStackLength = size(fileList,1)/2;    
        count = 1; 
        greenImageStack = zeros(size(image,1),size(image,2),greenStackLength);
        for frame = redStackLength+1:(greenStackLength*2) 
            image = imread(fileList(frame).name); 
            greenImageStack(:,:,count) = image;
            count = count + 1;
        end 
    end
elseif frameAvQ == 1
    frameAvNum = input('How many frames do you want to average together across time? '); 
    if redChanQ == 1 
        redStackLength = ceil((size(fileList,1)/2)/frameAvNum);       
        image = imread(fileList(1).name); 
        fprintf('Red channel x and y pixel size: %d x %d. ',size(image,1),size(image,2))
        xyDownQ = input('Input 1 if you need to downsample the red channel in the x and y dimensions. ');
        downFactor = 1;
        if xyDownQ == 1
            downFactor = input('How much do you want to downsample the red channel x and y dimensions? ');
        end 
        avFrames = zeros(size(image,1),size(image,2),frameAvNum);
        redImageStack = zeros(ceil(size(image,1)/downFactor),ceil(size(image,2)/downFactor),redStackLength);
        avFrame = 1;
        count = 1;
        for frame = 1:(size(fileList,1)/2)
            image = imread(fileList(frame).name); 
            avFrames(:,:,avFrame) = image;
            avFrame = avFrame + 1;
            if avFrame > frameAvNum       
                avIm = mean(avFrames,3);
                downAvIm1 = downsample(avIm,downFactor);
                downAvIm2 = downsample(downAvIm1',downFactor);
                redImageStack(:,:,count) = downAvIm2;
                count = count + 1;
                avFrame = 1;
            end                   
        end 
    end 
    if greenChanQ == 1 
        greenStackLength = ceil((size(fileList,1)/2)/frameAvNum);
        image = imread(fileList(1).name); 
        fprintf('Green channel x and y pixel size: %d x %d. ',size(image,1),size(image,2))
        xyDownQ = input('Input 1 if you need to downsample the green channel in the x and y dimensions. ');
        downFactor = 1;
        if xyDownQ == 1
            downFactor = input('How much do you want to downsample the green channel x and y dimensions? ');
        end 
        avFrames = zeros(size(image,1),size(image,2),frameAvNum);
        greenImageStack = zeros(ceil(size(image,1)/downFactor),ceil(size(image,2)/downFactor),greenStackLength);
        avFrame = 1;
        count = 1; 
        for frame = (size(fileList,1)/2)+1:size(fileList,1) %CHECK THESE VALUES FOR BELOW TO BE CORRECT
            image = imread(fileList(frame).name); 
            avFrames(:,:,avFrame) = image;
            avFrame = avFrame + 1;
            if avFrame > frameAvNum      
                avIm = mean(avFrames,3);
                downAvIm1 = downsample(avIm,downFactor);
                downAvIm2 = downsample(downAvIm1',downFactor);
                greenImageStack(:,:,count) = downAvIm2;
                count = count + 1;
                avFrame = 1;
            end         
        end 
    end
end 
%% separate volume imaging data into separate stacks per z plane and motion correction
templateQ = input('Input 0 if you want the template to be the average of all frames. Not recommended if there is scramble. Input 1 otherwise. ');
if templateQ == 1
    if redChanQ == 1 
        fprintf('    %d red frames. ', size(redImageStack,3));
    end 
    if greenChanQ == 1
        fprintf('    %d green frames. ', size(greenImageStack,3));
    end 
    numTemplate = input('    Input the number of frames you want to use for the registration templates. ');
end 
if volIm == 1
    disp('Separating Z-planes')
    %reorganize data by zPlane and prep for motion correction 
    if redChanQ == 1
        [rZstacks] = splitStacks(redImageStack,splitType,numZplanes);
        [rVolStack] = reorgVolStack(redImageStack,splitType,numZplanes); 
    end 
    if greenChanQ == 1 
        [gZstacks] = splitStacks(greenImageStack,splitType,numZplanes);
        [gVolStack] = reorgVolStack(greenImageStack,splitType,numZplanes);
    end 
    
    %3D registration     
    disp('3D Motion Correction')
    %need minimum 4 planes in Z for 3D registration to work-time to interpolate
    if redChanQ == 1 
        rVolStack5 = zeros(size(rVolStack,1),size(rVolStack,2),size(gVolStack,3)+size(gVolStack,3)-1,size(gVolStack,4));
    end 
    if greenChanQ == 1 
        gVolStack5 = zeros(size(gVolStack,1),size(gVolStack,2),size(gVolStack,3)+size(gVolStack,3)-1,size(gVolStack,4));
    end 
    parfor ind = 1:size(gVolStack,4)
        count = 1;
        for zplane = 1:size(gVolStack,3)+size(gVolStack,3)-1
            if rem(zplane,2) == 0
                if redChanQ == 1 
                    rVolStack5(:,:,zplane,ind) = mean(rVolStack(:,:,count-1:count,ind),3);
                end 
                if greenChanQ == 1 
                    gVolStack5(:,:,zplane,ind) = mean(gVolStack(:,:,count-1:count,ind),3);
                end 
            elseif rem(zplane,2) == 1 
                if redChanQ == 1 
                    rVolStack5(:,:,zplane,ind) = rVolStack(:,:,count,ind);
                end 
                if greenChanQ == 1 
                    gVolStack5(:,:,zplane,ind) = gVolStack(:,:,count,ind);
                end 
                count = count +1;
            end 
        end 
    end 
    if redChanQ == 1 
        if templateQ == 0
            rTemplate = mean(rVolStack5,4);
        elseif templateQ == 1 
            rTemplate = mean(rVolStack5(:,:,1:numTemplate,:),4);
        end 
    end 
    if greenChanQ == 1 
        if templateQ == 0
            gTemplate = mean(gVolStack5,4);
        elseif templateQ == 1 
            gTemplate = mean(gVolStack5(:,:,1:numTemplate,:),4);
        end             
    end
    %create optimizer and metric, setting modality to multimodal because the
    %template and actual images look different (as template is mean = smoothed)
    [optimizer, metric] = imregconfig('multimodal')    ;
    %tune the poperties of the optimizer
    optimizer.InitialRadius = 0.004;
    optimizer.Epsilon = 1.5;
    optimizer.GrowthFactor = 1.01;
    optimizer.MaximumIterations = 300;
    for ind = 1:size(gVolStack,4)
        if redChanQ == 1 
            rrRegVolStack(:,:,:,ind) = imregister(rVolStack5(:,:,:,ind),rTemplate,'affine', optimizer, metric,'PyramidLevels',1);
        end 
        if greenChanQ == 1
            ggRegVolStack(:,:,:,ind) = imregister(gVolStack5(:,:,:,ind),gTemplate,'affine', optimizer, metric,'PyramidLevels',1);
        end 
    end 
    if redChanQ == 1 
        [rrVZstacks5] = volStack2splitStacks(rrRegVolStack);
        %get rid of extra z planes
        count = 1; 
        rrVZstacks3 = cell(1,size(gZstacks,2));
        for zPlane = 1:size(gZstacks,2)
            rrVZstacks3{zPlane} = rrVZstacks5{count};
            count = count+2;
        end 
        %package data for output 
        regStacks{2,4} = rrVZstacks3; regStacks{1,4} = 'rrVZstacks3';
    end 
    if greenChanQ == 1
        [ggVZstacks5] = volStack2splitStacks(ggRegVolStack);
        %get rid of extra z planes
        count = 1; 
        ggVZstacks3 = cell(1,size(gZstacks,2));
        for zPlane = 1:size(gZstacks,2)
            ggVZstacks3{zPlane} = ggVZstacks5{count};
            count = count+2;
        end 
        %package data for output 
        regStacks{2,3} = ggVZstacks3; regStacks{1,3} = 'ggVZstacks3';    
    end 

elseif volIm == 0   
    if redChanQ == 1 
        disp('2D Motion Correction')
        %2D register imaging data  
        if templateQ == 0
            rTemplate = mean(redImageStack,3);
        elseif templateQ == 1 
            rTemplate = mean(redImageStack(:,:,1:numTemplate),3);
        end             
%         rTemplate = mean(redImageStack(:,:,1:42),3);
        [rrRegStack,~] = registerVesStack(redImageStack,rTemplate);  
        rrRegZstacks{1} = rrRegStack;
        
        %package data for output 
        regStacks{2,2} = rrRegZstacks; regStacks{1,2} = 'rrRegZstacks';  
    end 
    if greenChanQ == 1
        disp('2D Motion Correction')
        %2D register imaging data    
        if templateQ == 0
            gTemplate = mean(greenImageStack,3);
        elseif templateQ == 1 
            gTemplate = mean(greenImageStack(:,:,1:numTemplate),3);
        end   
%         gTemplate = mean(greenImageStack(:,:,1:42),3);
        [ggRegStack,~] = registerVesStack(greenImageStack,gTemplate);  
        ggRegZstacks{1} = ggRegStack;
   
        %package data for output 
        regStacks{2,1} = ggRegZstacks; regStacks{1,1} = 'ggRegZstacks';
    end 
end 
%% check registration 
if volIm == 1     
    %check relationship b/w template and 3D registered images
    if redChanQ == 1
        count = 1; 
        rrTemp2regCorr3D = zeros(size(rZstacks,2),size(rrVZstacks3{1},3));
        for zPlane = 1:size(rZstacks,2)
            for ind = 1:size(rrVZstacks3{1},3)
                rrTemp2regCorr3D(zPlane,ind) = corr2(rTemplate(:,:,count),rrVZstacks3{zPlane}(:,:,ind));
            end 
            count = count+2;
        end 
    end 
    if greenChanQ == 1
        count = 1; 
        ggTemp2regCorr3D = zeros(size(gZstacks,2),size(ggVZstacks3{1},3));
        for zPlane = 1:size(gZstacks,2)
            for ind = 1:size(ggVZstacks3{1},3)
                ggTemp2regCorr3D(zPlane,ind) = corr2(gTemplate(:,:,count),ggVZstacks3{zPlane}(:,:,ind));
            end 
            count = count+2;
        end 
    end 
    
    %plot 3D registration for comparison 
    figure;
    subplot(1,2,1);
    hold all; 
    if greenChanQ == 1
        for zPlane = 1:size(gZstacks,2)
            plot(ggTemp2regCorr3D(zPlane,:));
            title({'Correlation Coefficient of 3D Motion Correction Template and Output';'Green Channel Registered with Green Channel Template'}); 
        end 
        subplot(1,2,2);
    end 
    hold all; 
    if redChanQ == 1
        for zPlane = 1:size(rZstacks,2)
            plot(rrTemp2regCorr3D(zPlane,:));
            title({'Correlation Coefficient of 3D Motion Correction Template and Output';'Red Channel Registered with Red Channel Template'}); 
        end
    end
elseif volIm == 0 
    if redChanQ == 1
        %check relationship b/w template and 2D registered images    
        rrTemp2regCorr2D = zeros(1,size(rrRegZstacks{1},3));
        for ind = 1:size(rrRegZstacks{1},3)
            rrTemp2regCorr2D(ind) = corr2(rTemplate,rrRegZstacks{1}(:,:,ind));
        end 
    end 
    if greenChanQ == 1
        %check relationship b/w template and 2D registered images     
        ggTemp2regCorr2D = zeros(1,size(ggRegZstacks{1},3));
        for ind = 1:size(ggRegZstacks{1},3)
            ggTemp2regCorr2D(ind) = corr2(gTemplate,ggRegZstacks{1}(:,:,ind));
        end 
    end 
    
    %plot 2D registrations for comparison 
    figure;
    if greenChanQ == 1
        subplot(1,2,1);
        plot(ggTemp2regCorr2D);
        title({'Correlation Coefficient of 2D Motion Correction Template and Output';'Green Channel Registered with Green Channel Template'}); 
    end 
    if redChanQ == 1
        subplot(1,2,2);
        plot(rrTemp2regCorr2D);
        title({'Correlation Coefficient of 2D Motion Correction Template and Output';'Red Channel Registered with Red Channel Template'}); 
    end 
end 
%
% implay(ggRegZstacks{1});
% implay(greenImageStack);

%% save registered stacks 
clearvars -except regStacks
vid = input('What number video is this? '); 

%make the directory and save the images 
dir1 = uigetdir('*.*','WHAT FOLDER ARE YOU SAVING THE DATA IN?'); % get the directory where you want to save your images 
dir2 = strrep(dir1,'\','/');
filename = sprintf('%s/regStacks_vid%d',dir2,vid);
save(filename)
%}
%% get and save out the data you need 
% one animal at a time
%{
clear 
%set the paramaters 
STAstackQ = input('Input 1 to import red and green channel stacks to create STA videos. Input 0 otherwise. ');
ETAstackQ = input('Input 1 to import red and green channel stacks to create ETA videos. Input 0 otherwise. '); 
if STAstackQ == 1 || ETAstackQ == 1 
    BGsubQ = input('Input 1 if you want to do background subtraction on your imported image stacks. Input 0 otherwise. ');
    if BGsubQ == 1
        BGsubTypeQ = 0; %input('Input 0 to do a simple background subtraction. Input 1 if you want to do row by row background subtraction. ');
    end 
end 
if STAstackQ == 1 || ETAstackQ == 1
    optoQ = input('Input 1 if this is an opto exeriment. Input 0 for a behavior experiment. ');
    if optoQ == 1 
        stimStateQ = input('Input 0 if you used flyback stimulation. Input 1 if not. ');
        if stimStateQ == 0 
            state = 8;
        elseif stimStateQ == 1
            state = 7;
        end 
    elseif optoQ == 0 
        state = input('Input the teensy state you care about. 2 = stim. 4 = reward. ');
        if state == 2
            state2Q = input('Input 1 if you want to separate stimulus time locked data by HIT or MISS trials? Input 0 otherwise. ');
            if state2Q == 1 
                state2 = input('Input 0 for stimulus HIT trials. Input 1 for stimulus MISS trials. ');
            end 
        end 
        if state == 4  
            state4 = input('Input 0 for reward HIT trials. Input 1 for reward MISS trials. ');
        end 
    end 
    % batchQ = input('Input 1 if you want to batch process across mice. Input 0 otherwise. ');
    % if batchQ == 0 
    %     mouseNum = 1; 
    % elseif batchQ == 1 
    %     mouseNum = input('How many mice are you batch processing? ');
    % end 
    mouseNum = 1; mouse = 1;
    FPSstack = cell(1,mouseNum);
    vidList = cell(1,mouseNum);
    framePeriod = input(sprintf('What is the frame period for mouse #%d? ',mouse));
    FPS = 1/framePeriod; 
    FPSq = input(sprintf('Input 1 if the FPS needs to be adjusted based on frame averaging for mouse #%d. ',mouse));
    FPSstack{mouse} = FPS;
    if FPSq == 1 
        FPSadjust = input(sprintf('By what factor does the FPS need to be adjusted for mouse #%d? ',mouse));
        FPSstack{mouse} = FPS/FPSadjust;
    elseif FPSq == 0 
        FPSadjust = 1;
    end 
    vidList{mouse} = input(sprintf('What videos are you analyzing for mouse #%d? ',mouse));    
end
if STAstackQ == 1 
    CAQ = 1;
    if CAQ == 1
        tTypeQ = 0; %input('Do you want to seperate calcium peaks by trial type (light condition)? No = 0. Yes = 1. ');
    end 
    mouseNum = 1; 
    if CAQ == 1 
        cDataFullTrace = cell(1,mouseNum);
        terminals = cell(1,mouseNum);
    end  
    dataDir = cell(1,mouseNum);
    % get your data        
    dirLabel = sprintf('WHERE IS THE CA DATA FOR MOUSE #%d? ',mouse);
    dataDir{mouse} = uigetdir('*.*',dirLabel);
    cd(dataDir{mouse}); % go to the right directory 
    if CAQ == 1 
        % get calcium data 
        terminals{mouse} = input(sprintf('What terminals do you care about for mouse #%d? Input in correct order. ',mouse));    
        CAfileList = dir('**/*CAdata_*.mat'); % list data files in current directory 
        for vid = 1:length(vidList{mouse})
            CAlabel = CAfileList.name;
            CAmat = matfile(sprintf(CAlabel,vidList{mouse}(vid)));
            CAdata = CAmat.CcellData;       
            cDataFullTrace{mouse}{vid} = CAdata;
        end 
    end         
end 
if STAstackQ == 1 || ETAstackQ == 1 
    % get registered images 
    regImDir = uigetdir('*.*','WHERE ARE THE REGISTERED IMAGES?');
    cd(regImDir);
    redlabel = input('Give a string example of what the red stacks are labeled as. Put %d in place of where the vid number is. '); % example: SF56_20190718_ROI2_vid1_BBB = SF56_20190718_ROI2_vid%d_BBB
    greenlabel = input('Give a string example of what the green stacks are labeled as. Put %d in place of where the vid number is. '); % example: SF56_20190718_ROI2_vid1_BBB = SF56_20190718_ROI2_vid%d_BBB
    greenStacks1 = cell(1,length(vidList{mouse}));
    redStacks1 = cell(1,length(vidList{mouse}));
    greenStacksBS = cell(1,length(vidList{mouse}));
    redStacksBS = cell(1,length(vidList{mouse}));
    redStackArray = cell(1,length(vidList{mouse}));
    greenStackArray = cell(1,length(vidList{mouse}));
    greenStacks = cell(1,length(vidList{mouse}));
    redStacks = cell(1,length(vidList{mouse}));
    for vid = 1:length(vidList{mouse})
        cd(regImDir);
        redMat = matfile(sprintf(redlabel,vidList{mouse}(vid)));       
        redRegStacks = redMat.regStacks;
        if size(redRegStacks,2) > 2 
            if iscell(redRegStacks{2,4}) == 0
                redStacks1{vid} = redRegStacks{2,4};
            elseif iscell(redRegStacks{2,4}) == 1
                redStacks1{vid} = redRegStacks{2,4}{1};
            end 
        elseif size(redRegStacks,2) == 2 
            if iscell(redRegStacks{2,2}) == 0 
                redStacks1{vid} = redRegStacks{2,2};
            elseif iscell(redRegStacks{2,2}) == 1 
                redStacks1{vid} = redRegStacks{2,2}{1};
            end 
        end 
        greenMat = matfile(sprintf(greenlabel,vidList{mouse}(vid)));       
        greenRegStacks = greenMat.regStacks;        
        if size(greenRegStacks,2) > 2 
            if iscell(greenRegStacks{2,3}) == 0
                greenStacks1{vid} = greenRegStacks{2,3};
            elseif iscell(greenRegStacks{2,3}) == 1
                greenStacks1{vid} = greenRegStacks{2,3}{1};
            end
        elseif size(greenRegStacks,2) == 2 
            if iscell(greenRegStacks{2,1}) == 0
                greenStacks1{vid} = greenRegStacks{2,1};
            elseif iscell(greenRegStacks{2,1}) == 1
                greenStacks1{vid} = greenRegStacks{2,1}{1};
            end     
        elseif size(greenRegStacks,2) == 1 
            greenStacks1{vid} = greenRegStacks{2,1}{1};
        end                            
        if BGsubQ == 0 
            redStacksBS = redStacks1;
            greenStacksBS = greenStacks1; 
        elseif BGsubQ == 1
            if BGsubTypeQ == 0 
                if vid == 1 
                    [redStacks_BS,BG_ROIboundData] = backgroundSubtraction(redStacks1{vid});
                    redStacksBS{vid} = redStacks_BS;
                    [greenStacks_BS] = backgroundSubtraction2(greenStacks1{vid},BG_ROIboundData);
                    greenStacksBS{vid} = greenStacks_BS;
                else
                    [redStacks_BS] = backgroundSubtraction2(redStacks1{vid},BG_ROIboundData);
                    redStacksBS{vid} = redStacks_BS;
                    [greenStacks_BS] = backgroundSubtraction2(greenStacks1{vid},BG_ROIboundData);
                    greenStacksBS{vid} = greenStacks_BS;
                end 
            elseif BGsubTypeQ == 1
                if vid == 1 
                    [redStacks_BS,BG_ROIboundData] = backgroundSubtractionPerRow(redStacks1{vid});
                    redStacksBS{vid} = redStacks_BS;
                    [greenStacks_BS] = backgroundSubtractionPerRow2(greenStacks1{vid},BG_ROIboundData);
                    greenStacksBS{vid} = greenStacks_BS;
                else
                    [redStacks_BS] = backgroundSubtractionPerRow2(redStacks1{vid},BG_ROIboundData);
                    redStacksBS{vid} = redStacks_BS;
                    [greenStacks_BS] = backgroundSubtractionPerRow2(greenStacks1{vid},BG_ROIboundData);
                    greenStacksBS{vid} = greenStacks_BS;
                end 
            end 
        end               
        % average registered imaging data across planes in Z 
        if iscell(redStacks1{1}) == 0 
            for Z = 1%:size(redStacks1{1},2)
                redStackArray{vid}(:,:,:,Z) = redStacksBS{vid}{Z};
                greenStackArray{vid}(:,:,:,Z) = greenStacksBS{vid}{Z};
            end 
        elseif iscell(redStacks1{1}) == 1 
            for Z = 1:size(redStacks1{1},2)
                redStackArray{vid}(:,:,:,Z) = redStacksBS{vid}{Z};
                greenStackArray{vid}(:,:,:,Z) = greenStacksBS{vid}{Z};
            end 
        end 
        redStacks{vid} = mean(redStackArray{vid},4);
        greenStacks{vid} = mean(greenStackArray{vid},4);
    end 
end 
clearvars redMat redRegStacks redStacks1 greenMat greenRegStacks greenStacks1 redStacksBS redStacks_BS greenStacksBS greenStacks_BS BG_ROIboundData redStackArray greenStackArray
% get HDF data for making ETA stack averages whether or not opto is done 
if ETAstackQ == 1 && optoQ == 1 
    state_end_f2 = cell(1,length(vidList{mouse}));        
    trialLengths2 = cell(1,length(vidList{mouse}));  
    state_start_f = cell(1,mouseNum);
    TrialTypes = cell(1,mouseNum);
    trialLengths = cell(1,mouseNum);
    state_end_f = cell(1,mouseNum);
    for vid = 1:length(vidList{mouse})
        [~,statestartf,stateendf,~,~,trialTypes] = makeHDFchart_redBlueStim(state,framePeriod,vidList{mouse}(vid),mouse);
        state_start_f{mouse}{vid} = floor(statestartf/FPSadjust);
        state_end_f2{vid} = floor(stateendf/FPSadjust);
        TrialTypes{mouse}{vid} = trialTypes(1:length(statestartf),:);
        trialLengths2{vid} = state_end_f2{vid}-state_start_f{mouse}{vid};
    end 
    % this fixes discrete time rounding errors to ensure the stimuli are
    % all the correct number of frames long 
    if mouse == 1 
        stimTimeLengths = input('How many seconds are the stims on for? ');
    end 
    stimFrameLengths = floor(stimTimeLengths*FPSstack{mouse});              
    for frameLength = 1:length(stimFrameLengths)
        for vid = 1:length(vidList{mouse})
            for trial = 1:length(state_start_f{mouse}{vid})
                [~,c] = min(abs(trialLengths2{vid}(trial)-stimFrameLengths));
                trialLengths{mouse}{vid}(trial) = stimFrameLengths(c);
                state_end_f{mouse}{vid}(trial) = state_start_f{mouse}{vid}(trial) + stimFrameLengths(c);
            end 
        end 
    end      
elseif ETAstackQ == 1 && optoQ == 0
    if state == 4 % reward 
        if state4 == 0 % reward HIT 
            state_end_f2 = cell(1,length(vidList{mouse}));
            trialLengths2 = cell(1,length(vidList{mouse}));
            state_start_f = cell(1,mouseNum);
            TrialTypes = cell(1,mouseNum);
            trialLengths = cell(1,mouseNum);
            state_end_f = cell(1,mouseNum);
            for vid = 1:length(vidList{mouse})
                [statestartf,stateendf] = behavior_FindStateBounds(state,framePeriod,vidList{mouse}(vid),mouse);
                state_start_f{mouse}{vid} = floor(statestartf/FPSadjust);
                if isempty(stateendf) == 0
                    state_end_f2{vid} = floor(stateendf/FPSadjust);
                    trialLengths2{vid} = state_end_f2{vid}-state_start_f{mouse}{vid};
                end 
            end    
        elseif state4 == 1 % reward MISS 
            state_end_f2 = cell(1,length(vidList{mouse}));
            trialLengths2 = cell(1,length(vidList{mouse}));
            state_start_f = cell(1,mouseNum);
            TrialTypes = cell(1,mouseNum);
            trialLengths = cell(1,mouseNum);
            state_end_f = cell(1,mouseNum);
            for vid = 1:length(vidList{mouse})
                [statestartf,stateendf] = behavior_FindStateBoundsRewardMiss(framePeriod,vidList{mouse}(vid),mouse);
                state_start_f{mouse}{vid} = floor(statestartf/FPSadjust);
                if isempty(stateendf) == 0
                    state_end_f2{vid} = floor(stateendf/FPSadjust);
                    trialLengths2{vid} = state_end_f2{vid}-state_start_f{mouse}{vid};
                end 
            end                  
        end 
    elseif state == 2 % stim 
        if state2Q == 0 % don't separate stim time locked data by HIT or MISS trials 
            state_end_f2 = cell(1,length(vidList{mouse}));
            trialLengths2 = cell(1,length(vidList{mouse}));
            state_start_f = cell(1,mouseNum);
            TrialTypes = cell(1,mouseNum);
            trialLengths = cell(1,mouseNum);
            state_end_f = cell(1,mouseNum);
            for vid = 1:length(vidList{mouse})
                [statestartf,stateendf] = behavior_FindStateBounds(state,framePeriod,vidList{mouse}(vid),mouse);
                state_start_f{mouse}{vid} = floor(statestartf/FPSadjust);
                if isempty(stateendf) == 0
                    state_end_f2{vid} = floor(stateendf/FPSadjust);
                    trialLengths2{vid} = state_end_f2{vid}-state_start_f{mouse}{vid};
                end 
            end   
        elseif state2Q == 1 % separate stim time locked data by HIT or MISS trials 
            state_end_f2 = cell(1,length(vidList{mouse}));
            trialLengths2 = cell(1,length(vidList{mouse}));
            state_start_f = cell(1,mouseNum);
            TrialTypes = cell(1,mouseNum);
            trialLengths = cell(1,mouseNum);
            state_end_f = cell(1,mouseNum);
            for vid = 1:length(vidList{mouse})
                [statestartf,stateendf] = behavior_FindStateBoundsHitOrMiss(framePeriod,vidList{mouse}(vid),mouse,state2);
                state_start_f{mouse}{vid} = floor(statestartf/FPSadjust);
                if isempty(stateendf) == 0
                    state_end_f2{vid} = floor(stateendf/FPSadjust);
                    trialLengths2{vid} = state_end_f2{vid}-state_start_f{mouse}{vid};
                end 
            end              
        end       
    end 

    % this fixes discrete time rounding errors to ensure the stimuli are
    % all the correct number of frames long 
    if mouse == 1 
        stimTimeLengths = input('How much time is there between the stim and reward? ');
    end 
    stimFrameLengths = floor(stimTimeLengths*FPSstack{mouse});
    for frameLength = 1:length(stimFrameLengths)
        for vid = 1:length(vidList{mouse})
            for trial = 1:length(state_start_f{mouse}{vid})
                % determine the correct length of frames per trial
                % (accounts for rounding/discrete time issues 
                [~,c] = min(abs(trialLengths2{vid}(trial)-stimFrameLengths));
                trialLengths{mouse}{vid}(trial) = stimFrameLengths(c);
                state_end_f{mouse}{vid}(trial) = state_start_f{mouse}{vid}(trial) + stimFrameLengths(c);
            end 
        end 
    end 
end 

% get red or blue opto stim trials only 
if ETAstackQ == 1
    if optoQ == 1 
        redTrialsOnlyQ = input('Input 0 if you want the start times for only red opto trials. Input 1 for blue only. ');
        if redTrialsOnlyQ == 0           
            for vid = 1:length(vidList{mouse}) 
                % find the trials that do not have red opto stims 
                [r,~] = find(TrialTypes{mouse}{vid}(:,2) ~= 2);
                % remove trials start and end frames that do not have
                % red opto stims 
                state_start_f{mouse}{vid}(r) = NaN;
                state_end_f{mouse}{vid}(r) = NaN;
                % remove NaNs 
                state_start_f{mouse}{vid} = state_start_f{mouse}{vid}(~isnan(state_start_f{mouse}{vid}));
                state_end_f{mouse}{vid} = state_end_f{mouse}{vid}(~isnan(state_end_f{mouse}{vid}));
                % remove 0s B = A(A~=)
                state_start_f{mouse}{vid} = state_start_f{mouse}{vid}(state_start_f{mouse}{vid}~=0);
                state_end_f{mouse}{vid} = state_end_f{mouse}{vid}(state_end_f{mouse}{vid}~=0);
            end             
        elseif redTrialsOnlyQ == 1
            for vid = 1:length(vidList{mouse}) 
                % find the trials that do not have blue opto stims 
                [r,~] = find(TrialTypes{mouse}{vid}(:,2) ~= 1);
                % remove trials start and end frames that do not have
                % red opto stims 
                state_start_f{mouse}{vid}(r) = NaN;
                state_end_f{mouse}{vid}(r) = NaN;
                % remove NaNs 
                state_start_f{mouse}{vid} = state_start_f{mouse}{vid}(~isnan(state_start_f{mouse}{vid}));
                state_end_f{mouse}{vid} = state_end_f{mouse}{vid}(~isnan(state_end_f{mouse}{vid}));
                % remove 0s B = A(A~=)
                state_start_f{mouse}{vid} = state_start_f{mouse}{vid}(state_start_f{mouse}{vid}~=0);
                state_end_f{mouse}{vid} = state_end_f{mouse}{vid}(state_end_f{mouse}{vid}~=0);
            end           
        end 
    end 
end 

% save out the workspace variables 
dir1 = uigetdir('*.*','WHAT FOLDER ARE YOU SAVING THE DATA IN?'); % get the directory where you want to save your images 
dir2 = strrep(dir1,'\','/');
filename = sprintf('%s/TAstackData_%dvids',dir2,vid);
save(filename)

%}
%% (ETA stacks) create red and green channel stack averages around opto stim or behavior (one animal at a time) 
% z scores the entire stack before sorting into windows for averaging 
% option to high pass filter the video 
% can create shuffled and bootrapped x number of spikes (based on input)
% (must save out non-shuffled STA vids before making
% shuffled and bootstrapped STA vids to create binary vids for DBscan)
%{
mouse = 1;
% termQ = input('Input 1 to update terminal labels. ');
% if termQ == 1 
%     terminals{mouse} = input(sprintf('What terminals do you care about for mouse #%d? Input in correct order. ',mouse)); 
%     tTypeQ = input('Do you want to seperate calcium peaks by trial type (light condition)? No = 0. Yes = 1. ');
%     dirLabel = sprintf('WHERE IS THE CA DATA FOR MOUSE #%d? ',mouse);
%     dataDir{mouse} = uigetdir('*.*',dirLabel);
%     cd(dataDir{mouse}); % go to the right directory 
%     % get calcium data    
%     CAfileList = dir('**/*CAdata_*.mat'); % list data files in current directory 
%     cDataFullTrace = cell(1);
%     for vid = 1:length(vidList{mouse})
%         CAlabel = CAfileList(vid).name;
%         CAmat = matfile(sprintf(CAlabel,vidList{mouse}(vid)));
%         CAdata = CAmat.CcellData;       
%         cDataFullTrace{mouse}{vid} = CAdata;
%     end 
% end 
greenStacksOrigin = greenStacks;
redStacksOrigin = redStacks;
% option to downsample the data 
rows = size(greenStacks{1},1);
cols = size(greenStacks{1},2);
fprintf('%d Rows and %d Columns. ', rows,cols);
downSampleQ = input('Input 1 to downsample the data. '); 
while downSampleQ == 1 
    dwnR = cell(1,length(vidList{mouse})); 
    dwnG = cell(1,length(vidList{mouse})); 
    downsampleRate = input("Input the downsample rate. ");
    for vid = 1:length(greenStacksOrigin)
        dwnR{vid} = downsample(redStacksOrigin{vid},downsampleRate);
        dwnR{vid} = permute(dwnR{vid},[2 1 3]);
        dwnR{vid} = downsample(dwnR{vid},downsampleRate);
        dwnR{vid} = permute(dwnR{vid},[2 1 3]);       
        dwnG{vid} = downsample(greenStacksOrigin{vid},downsampleRate);
        dwnG{vid} = permute(dwnG{vid},[2 1 3]);
        dwnG{vid} = downsample(dwnG{vid},downsampleRate);
        dwnG{vid} = permute(dwnG{vid},[2 1 3]);   
    end 
    implay(redStacksOrigin{1}); implay(dwnR{1}); implay(greenStacksOrigin{1}); implay(dwnG{1});
    downSampleQ2 = input('Input 1 if the data looks good and does not need re-downsampling. '); 
    if downSampleQ2 == 1
        greenStacksOrigin = dwnG; redStacksOrigin = dwnR; 
        clearvars dwnG dwnR
        downSampleQ = 0; 
    end 
end 
if exist('dataScrambleCutOffs','var') == 0 && exist('dataScrambleQ','var') == 0
    dataScrambleQ = input('Input 1 if there is data scramble. Input 0 otherwise. ');
    if dataScrambleQ == 1 
        dataScrambleCutOffs = input('What are the data scramble frame cut offs for all of the raw videos? ');
        for vid = 1:length(greenStacksOrigin)
            greenStacksOrigin{vid} = greenStacksOrigin{vid}(:,:,1:dataScrambleCutOffs(vid));
            redStacksOrigin{vid} = redStacksOrigin{vid}(:,:,1:dataScrambleCutOffs(vid));
        end 
    end 
end 
spikeQ = input("Input 0 to use real opto stim locations (DO THIS FIRST!!). Input 1 to use randomized and bootstrapped opto stim locations (based on ITI STD). "); 
if spikeQ == 1
    itNum = input('Input the number of bootstrap iterations that you want. ');
end 
% sort red and green channel stacks based on ca peak location 
% resort state_start_f into sigLocs{vid}{terminals{mouse}(ccell)}(peak) 
sigLocs = cell(1,length(vidList{mouse}));
for vid = 1:length(vidList{mouse})
    sigLocs{vid}= state_start_f{mouse}{vid}';
end 

windSize = input('How big should the window be around the Ca spike/event in seconds? '); %24
if spikeQ == 1   
    spikeISIs = cell(1,length(vidList{mouse})); 
    ISIstds = cell(1,length(vidList{mouse})); 
    randSpikes = cell(1,length(vidList{mouse})); 
    ISImean = cell(1,length(vidList{mouse}));
    randISIs = cell(1,length(vidList{mouse}));
    randSigLocs = cell(1,length(vidList{mouse}));
    for it = 1:itNum
        for vid = 1:length(vidList{mouse})
            % determine ISI
            spikeISIs{vid} = diff(sigLocs{vid});
            % determine STD (sigma) of ISI 
            ISIstds{vid} = std(spikeISIs{vid});
            % determine mean ISI 
            ISImean{vid} = mean(spikeISIs{vid});       
            % generate random spike Locs (sigLocs) based on ISI STD using same            
            for spike = 1:length(spikeISIs{vid})
                % generate random ISI
                r = random('Exponential',ISImean{vid});
                randISIs{vid}(spike) = floor(r);
            end              
            % plot distribution of real and rand ISIs for sanity check 
            %{
            figure;
            histogram(spikeISIs{vid}{terminals{mouse}(ccell)});
            title(sprintf("Real Spike ISIs. Vid %d. Axon %d. ",vid,terminals{mouse}(ccell)));
            figure;
            histogram(randISIs{vid}{terminals{mouse}(ccell)})
            title(sprintf("Rand Spike ISIs. Vid %d. Axon %d. ",vid,terminals{mouse}(ccell)));
            %}
            % use randISIs to generate randSigLocs 
            if isempty(randISIs{vid}) == 0 
                randSigLocs{vid}(it,:) = cumsum(randISIs{vid});
            end            
        end      
    end 
    sigLocs = randSigLocs;
    % remove full rows/iterations within sigLocs where the peaks + buffer space for
    % window are greater than the amount of frames per vid
    for vid = 1:length(vidList{mouse})
        if isempty(sigLocs{vid}) == 0 
            % find where the peak+buffer space is greater than the
            % number of frames in the video 
            [r,c] = find(sigLocs{vid} > (size(greenStacks{vid},3)+floor((windSize/2)*FPSstack{mouse})));
            % turn all values in sigLocs greater than our threshold into
            % nan
            for loc = 1:length(r)
                sigLocs{vid}(r(loc),c(loc)) = NaN;
            end 
            % find zeros and turn into nans 
            [r,c] = find(sigLocs{vid} == 0);
            for loc = 1:length(r)
                sigLocs{vid}(r(loc),c(loc)) = NaN;
            end 
            % find entire rows of nans 
            r = find(all(isnan(sigLocs{vid}),2));
            % remove the rows entirely made of NaNs 
            sigLocs{vid}(r,:) = [];      
            % find rows where there is only one spike/event and the rest are NaNs
            if size(sigLocs{vid},2) > 1
                r = find(sum(~isnan(sigLocs{vid}),2) == 1);
                % remove the rows where there is only one spike/event
                sigLocs{vid}(r,:) = [];  
            end 
            while size(sigLocs{vid},1) ~= itNum
                % generate random spike Locs (sigLocs) based on ISI STD using same            
                for spike = 1:length(spikeISIs{vid})
                    % generate random ISI
                    r = random('Exponential',ISImean{vid});
                    randISIs{vid}(spike) = floor(r);
                end              
                % use randISIs to generate randSigLocs 
                if isempty(randISIs{vid}) == 0 
                    sigLocs{vid}(size(sigLocs{vid},1)+1,:) = cumsum(randISIs{vid});
                end  
                % take another look for sigLocs that are out of range and
                % remove them  
                [r,c] = find(sigLocs{vid} > (size(greenStacks{vid},3)+floor((windSize/2)*FPSstack{mouse})));
                % turn all values in sigLocs greater than our threshold into
                % nan
                for loc = 1:length(r)
                    sigLocs{vid}(r(loc),c(loc)) = NaN;
                end 
                % find zeros and turn into nans 
                [r,c] = find(sigLocs{vid} == 0);
                for loc = 1:length(r)
                    sigLocs{vid}(r(loc),c(loc)) = NaN;
                end 
                % find entire rows of nans 
                r = find(all(isnan(sigLocs{vid}),2));
                % remove the rows entirely made of NaNs 
                sigLocs{vid}(r,:) = [];  
                % find rows where there is only one spike/event and the rest are NaNs
                if size(sigLocs{vid},2) > 1
                    r = find(sum(~isnan(sigLocs{vid}),2) == 1);
                    % remove the rows where there is only one spike/event
                    sigLocs{vid}(r,:) = [];  
                end 
            end 
        end 
    end   
end 
clearvars randSigLocs 

% crop the imaging data if you want to; better to do this up here to
% maximize computational speed ~ 
rightChan = input('Input 0 if dynamic (BBB/dlight) data is in the green channel. Input 1 if dynamic (BBB/dlight) data is in the red channel. ');
dataTypeQ = input('Input 0 if this is standard BBB data. Input 1 if this is dlight data. ');
if dataTypeQ == 0 
    rightVesChan = rightChan;
elseif dataTypeQ == 1
    if rightChan == 0
        rightVesChan = 1;
    elseif rightchan == 1 
        rightVesChan = 0;
    end 
end 

if spikeQ == 0
    cropQ = input("Input 1 if you want to crop the image. Input 0 otherwise. ");
    % ask user where to crop image     
    if cropQ == 1 
        %select the correct channel to view for cropping 
        if rightChan == 0     
            hold off;
            cropIm = nanmean(greenStacksOrigin{1},3); %#ok<*NANMEAN> 
        elseif rightChan == 1
            hold off; 
            cropIm = nanmean(redStacksOrigin{1},3);
        end         
        [~, rect] = imcrop(cropIm);
    end      
elseif spikeQ == 1 % get the rect (crop location data)   
    % import rect and cropQ 
    dataDir = uigetdir('*.*','WHERE IS THE NON-SHUFFLED STA VIDEO .MAT FILE?');
    cd(dataDir);
    nonShuffledFileName = uigetfile('*.*','GET THE NON-SHUFFLED STA VIDEO .MAT FILE'); 
    nonShuffledMat = matfile(nonShuffledFileName);
    cropQ = nonShuffledMat.cropQ;
    if cropQ == 1 
        rect = nonShuffledMat.rect;
    end 
end 

% crop if necessary  
greenStacks2 = cell(1,length(vidList{mouse}));
redStacks2 = cell(1,length(vidList{mouse}));
if cropQ == 1 
    for vid = 1:length(vidList{mouse})
        for frame = 1:size(greenStacksOrigin{vid},3)
            cropdIm = imcrop(greenStacksOrigin{vid}(:,:,frame),rect);
            greenStacks2{vid}(:,:,frame) = cropdIm;
        end 
    end 
    
    for vid = 1:length(vidList{mouse})
        for frame = 1:size(greenStacksOrigin{vid},3)
            cropdIm = imcrop(redStacksOrigin{vid}(:,:,frame),rect);
            redStacks2{vid}(:,:,frame) = cropdIm;
        end 
    end 
elseif cropQ == 0
    greenStacks2 = greenStacksOrigin;
    redStacks2 = redStacksOrigin;
end  
clearvars greenStacks redStacks
greenStacks = greenStacks2;
redStacks = redStacks2;
clearvars greenStacks2 redStacks2

% high pass filter the videos if you want 
highPassQ = input("Input 1 if you want to high pass filter the videos. Input 0 otherwise. ");
if highPassQ == 1 
    hpfGreen = cell(1,length(vidList{mouse}));
    hpfRed = cell(1,length(vidList{mouse}));
    for vid = 1:length(vidList{mouse})
        %get sliding baseline 
        [greenSlidingBL]=slidingBaselineVid(greenStacks{vid},floor((FPS)*10),0.5); %0.5 quantile thresh = the median value    
        [redSlidingBL]=slidingBaselineVid(redStacks{vid},floor((FPS)*10),0.5);
        %subtract sliding baseline from z scored data 
        hpfGreen{vid} = greenStacks{vid}-greenSlidingBL;
        hpfRed{vid} = redStacks{vid}-redSlidingBL;       
    end 
    clearvars greenSlidingBL redSlidingBL
elseif highPassQ == 0 
    hpfGreen = greenStacks;
    hpfRed = redStacks;
end 

zscoreQ = input('Input 1 to z-score the data. Input 0 otherwise. ');
if zscoreQ == 0 
    % combine the vids to get z score of whole experiment
    frameLens = zeros(1,length(vidList{mouse}));
    for vid = 1:length(vidList{mouse})
        if vid == 1 
            frameLen = size(greenStacks{vid},3);
        elseif vid > 1 
            frameLen = frameLen + size(greenStacks{vid},3);
        end 
        frameLens(vid) = size(greenStacks{vid},3);
    end 
    combGreenStack = zeros(size(greenStacks{1},1),size(greenStacks{1},2),frameLen);
    combRedStack = zeros(size(greenStacks{1},1),size(greenStacks{1},2),frameLen);
    for vid = 1:length(vidList{mouse})
        if vid == 1 
            count = size(greenStacks{vid},3);
        end 
        for frame = 1:size(greenStacks{vid},3) 
            if vid == 1 
                combGreenStack(:,:,frame) = hpfGreen{vid}(:,:,frame);
                combRedStack(:,:,frame) = hpfRed{vid}(:,:,frame);
            elseif vid > 1 
                combGreenStack(:,:,count+1) = hpfGreen{vid}(:,:,frame);
                combRedStack(:,:,count+1) = hpfRed{vid}(:,:,frame);
                count = count + 1;                                      
            end 
        end     
    end 
    % z score the videos 
    zGreenStack = zscore(combGreenStack,0,3);
    zRedStack = zscore(combRedStack,0,3);
    clearvars combGreenStack combRedStack    
    szGreenStack = hpfGreen; 
    szRedStack = hpfRed; 
elseif zscoreQ == 1 
    % combine the vids to get z score of whole experiment
    frameLens = zeros(1,length(vidList{mouse}));
    for vid = 1:length(vidList{mouse})
        if vid == 1 
            frameLen = size(greenStacks{vid},3);
        elseif vid > 1 
            frameLen = frameLen + size(greenStacks{vid},3);
        end 
        frameLens(vid) = size(greenStacks{vid},3);
    end 
    combGreenStack = zeros(size(greenStacks{1},1),size(greenStacks{1},2),frameLen);
    combRedStack = zeros(size(greenStacks{1},1),size(greenStacks{1},2),frameLen);
    for vid = 1:length(vidList{mouse})
        if vid == 1 
            count = size(greenStacks{vid},3);
        end 
        for frame = 1:size(greenStacks{vid},3) 
            if vid == 1 
                combGreenStack(:,:,frame) = hpfGreen{vid}(:,:,frame);
                combRedStack(:,:,frame) = hpfRed{vid}(:,:,frame);
            elseif vid > 1 
                combGreenStack(:,:,count+1) = hpfGreen{vid}(:,:,frame);
                combRedStack(:,:,count+1) = hpfRed{vid}(:,:,frame);
                count = count + 1;                                      
            end 
        end     
    end 
    % z score the videos 
    zGreenStack = zscore(combGreenStack,0,3);
    zRedStack = zscore(combRedStack,0,3);
    clearvars combGreenStack combRedStack
    % resort videos
    szGreenStack = cell(1,length(vidList{mouse}));
    szRedStack = cell(1,length(vidList{mouse}));
    count = 1;
    for vid = 1:length(vidList{mouse})
        for frame = 1:frameLens(vid)       
            szGreenStack{vid}(:,:,frame) = zGreenStack(:,:,count); 
            szRedStack{vid}(:,:,frame) = zRedStack(:,:,count); 
            count = count + 1;
        end 
    end     
end 

windFrames = floor(windSize*FPSstack{mouse});
start = sigLocs{1}(1,1)-floor((windSize/2)*FPSstack{mouse});
stop = sigLocs{1}(1,1)+floor((windSize/2)*FPSstack{mouse});
frameLens = stop-start+1;
if windFrames ~= frameLens
    CI_High = nan(size(zGreenStack,1),size(zGreenStack,2),frameLens,size(sigLocs{1},1));
    CI_Low = nan(size(zGreenStack,1),size(zGreenStack,2),frameLens,size(sigLocs{1},1));
    CIlowAv = nan(size(zGreenStack,1),size(zGreenStack,2),frameLens);
    CIhighAv = nan(size(zGreenStack,1),size(zGreenStack,2),frameLens);    
elseif windFrames == frameLens
    CI_High = nan(size(zGreenStack,1),size(zGreenStack,2),windFrames,size(sigLocs{1},1));
    CI_Low = nan(size(zGreenStack,1),size(zGreenStack,2),windFrames,size(sigLocs{1},1));
    CIlowAv = nan(size(zGreenStack,1),size(zGreenStack,2),windFrames);
    CIhighAv = nan(size(zGreenStack,1),size(zGreenStack,2),windFrames);
end 
% further sort and average data, get 95% CI bounds 
clearvars zGreenStack zRedStack
workFlow = 1;
while workFlow == 1 
    tic
    if spikeQ == 1 
%         CIq = input('Input 0 to get 95% CI. Input 1 for 99% CI. ')
        HighLowQ = input('Input 0 to get the low CI bound . Input 1 for the high CI bound. ');  
    end 
    if spikeQ == 0
        lenIts = 1;
        % make sure sigLocs is organized in the correct orientation: 
        % sigLocs{vid}(it,peak)
        [r,c] = size(sigLocs{1});
        if r ~= lenIts
            for vid = 1:length(vidList{mouse})  
                sigLocs{vid} = sigLocs{vid}';
            end 
        end 
    elseif spikeQ == 1 
        lenIts = itNum;
    end 
    for it = 1:size(sigLocs{1},1)
        % sort data 
        % terminals = terminals{1};
        sortedGreenStacks = cell(1,1);
        sortedRedStacks = cell(1,1);
        if rightChan == 0     
            VesSortedGreenStacks = cell(1,1);
        elseif rightChan == 1
            VesSortedRedStacks = cell(1,1);
        end    
        for vid = 1:length(vidList{mouse})                  
            if isempty(sigLocs{vid}) == 0
                for peak = 1:size(sigLocs{vid},2)            
                    if sigLocs{vid}(it,peak)-floor((windSize/2)*FPSstack{mouse}) > 0 && sigLocs{vid}(it,peak)+floor((windSize/2)*FPSstack{mouse}) < size(szGreenStack{vid},3)                
                        start = sigLocs{vid}(it,peak)-floor((windSize/2)*FPSstack{mouse});
                        stop = sigLocs{vid}(it,peak)+floor((windSize/2)*FPSstack{mouse});                
                        if start == 0 
                            start = 1 ;
                            stop = start + floor((windSize/2)*FPSstack{mouse}) + floor((windSize/2)*FPSstack{mouse});
                        end        
                        if stop < size(szGreenStack{vid},3) && start > 0 
                            sortedGreenStacks{vid}{peak} = szGreenStack{vid}(:,:,start:stop);
                            sortedRedStacks{vid}{peak} = szRedStack{vid}(:,:,start:stop);
                            if rightVesChan == 0     
                                VesSortedGreenStacks{vid}{peak} = greenStacks{vid}(:,:,start:stop);
                            elseif rightVesChan == 1
                                VesSortedRedStacks{vid}{peak} = redStacks{vid}(:,:,start:stop);
                            end    
                        end 
                    end 
                end     
            end                  
        end 
    %     clearvars greenStacks redStacks start stop sigLocs sigPeaks 
    
        % resort and average calcium peak aligned traces across videos 

%             greenStackArray2 = nan(size(sortedGreenStacks{1}{1},1),size(sortedGreenStacks{1}{1},2),size(sortedGreenStacks{1}{1},3),size(sortedGreenStacks{1},2));
%             if rightChan == 0     
%                 VesGreenStackArray2 = nan(size(sortedGreenStacks{1}{1},1),size(sortedGreenStacks{1}{1},2),size(sortedGreenStacks{1}{1},3),size(sortedGreenStacks{1},2));
%             end             
        count = 1;
        for vid = 1:length(vidList{mouse})     
            if length(sortedGreenStacks) >= vid && isempty(sortedGreenStacks{vid}) == 0 
                for peak = 1:size(sortedGreenStacks{vid},2)  
                    if isempty(sortedGreenStacks{vid}{peak}) == 0
                        greenStackArray2(:,:,:,count) = single(sortedGreenStacks{vid}{peak}); %#ok<SAGROW>
                        if rightVesChan == 0
                            VesGreenStackArray2(:,:,:,count) = single(VesSortedGreenStacks{vid}{peak}); %#ok<SAGROW>
                        end           
                        count = count + 1;
                    end 
                end
            end 
        end 
       
%         clearvars sortedGreenStacks VesSortedGreenStacks
        clearvars VesSortedGreenStacks
%             redStackArray2 = nan(size(sortedGreenStacks{1}{1},1),size(sortedGreenStacks{1}{1},2),size(sortedGreenStacks{1}{1},3),size(sortedGreenStacks{1},2));
%             if rightChan == 1     
%                 VesRedStackArray2 = nan(size(sortedGreenStacks{1}{1},1),size(sortedGreenStacks{1}{1},2),size(sortedGreenStacks{1}{1},3),size(sortedGreenStacks{1},2));
%             end  
        count = 1;
        for vid = 1:length(vidList{mouse}) 
            if length(sortedGreenStacks) >= vid && isempty(sortedGreenStacks{vid}) == 0 
                for peak = 1:size(sortedRedStacks{vid},2)  
                    if isempty(sortedRedStacks{vid}{peak}) == 0
                        redStackArray2(:,:,:,count) = single(sortedRedStacks{vid}{peak}); %#ok<SAGROW>
                        if rightVesChan == 1
                            VesRedStackArray2(:,:,:,count) = single(VesSortedRedStacks{vid}{peak}); %#ok<SAGROW>
                        end           
                        count = count + 1;
                    end 
                end
            end 
        end 
       
%         clearvars sortedRedStacks VesSortedRedStacks
        clearvars VesSortedRedStacks
        % determine the average 
        avGreenStack = nanmean(greenStackArray2,4);         
        clearvars greenStackArray2
        avRedStack = nanmean(redStackArray2,4);     
        clearvars redStackArray2
        if rightVesChan == 0  
            % determine the average 
            VesAvGreenStack = nanmean(VesGreenStackArray2,4);          
            clearvars VesGreenStackArray2
        end 
        if rightVesChan == 1  
            % determine the average 
            VesAvRedStack = nanmean(VesRedStackArray2,4);            
            clearvars VesRedStackArray2
        end 

        % determine 95% or 99% CI of bootstrapped data and av
        if spikeQ == 1       
            if rightChan == 0 % BBB data is in green channel 
                SEM = (nanstd(avGreenStack,0,3))/(sqrt(size(avGreenStack,3))); %#ok<*NANSTD> % Standard Error 
                ts_High = tinv(0.975,size(avGreenStack,3)-1);% T-Score for 95% CI
                ts_Low =  tinv(0.025,size(avGreenStack,3)-1);% T-Score for 95% CI
%                         ts_High = tinv(0.995,size(avRedStack{terminals{mouse}(ccell)},3)-1);% T-Score for 99% CI
%                         ts_Low =  tinv(0.005,size(avRedStack{terminals{mouse}(ccell)},3)-1);% T-Score for 99% CI
                if HighLowQ == 0
                    CI_Low(:,:,:,it) = (avGreenStack) + (ts_Low*SEM);   
                elseif HighLowQ == 1 
                    CI_High(:,:,:,it) = (avGreenStack) + (ts_High*SEM);  % Confidence Intervals  
                end    
            elseif rightChan == 1 % BBB data is in red channel 
                SEM = (nanstd(avRedStack,0,3))/(sqrt(size(avRedStack,3))); %#ok<*NANSTD> % Standard Error 
                ts_High = tinv(0.975,size(avRedStack,3)-1);% T-Score for 95% CI
                ts_Low =  tinv(0.025,size(avRedStack,3)-1);% T-Score for 95% CI
%                         ts_High = tinv(0.995,size(avRedStack{terminals{mouse}(ccell)},3)-1);% T-Score for 99% CI
%                         ts_Low =  tinv(0.005,size(avRedStack{terminals{mouse}(ccell)},3)-1);% T-Score for 99% CI
                if HighLowQ == 0
                    CI_Low(:,:,:,it) = (avRedStack) + (ts_Low*SEM);   
                elseif HighLowQ == 1 
                    CI_High(:,:,:,it) = (avRedStack) + (ts_High*SEM);  % Confidence Intervals  
                end                        
            end              
        end 
    end 
    if spikeQ == 1
        if HighLowQ == 0         
            CIlowAv = nanmean(CI_Low,4);
        elseif HighLowQ == 1
            CIhighAv = nanmean(CI_High,4);
        end 
     
        if HighLowQ == 0         
            clearvars CI_Low
        elseif HighLowQ == 1
            clearvars CI_High
        end 
        CIdoneQ = input('Input 1 if you created and averaged the bootstrapped CI high and low bounds? ');
        if CIdoneQ == 1
            workFlow = 0;
            clearvars sortedGreenStacks sortedRedStacks 
        end 
    elseif spikeQ == 0
        workFlow = 0;
        clearvars sortedGreenStacks sortedRedStacks 
    end 
    toc
end 

% don't normalize because it's z-scored 
NgreenStackAv = avGreenStack;
NredStackAv = avRedStack; 
if spikeQ == 1 
    nCIhighAv = CIhighAv;
    nCIlowAv = CIlowAv;
    clearvars CIhighAv CIlowAv
end 
%{
% normalize to some baseline point 
changePt = floor(size(avGreenStack{terminals{mouse}(ccell)},3)/2)-2; 
normTime = input("How many seconds before the calcium peak do you want to baseline to? ");
BLstart = changePt - floor(normTime*FPSstack{mouse});
NgreenStackAv = cell(1,length(avGreenStack));
NredStackAv = cell(1,length(avGreenStack));
% normalize to baseline period 
for ccell = 1:length(terminals{mouse})
    NgreenStackAv{terminals{mouse}(ccell)} = ((avGreenStack{terminals{mouse}(ccell)}./ (nanmean(avGreenStack{terminals{mouse}(ccell)}(:,:,BLstart:changePt),3)))*100)-100;
    NredStackAv{terminals{mouse}(ccell)} = ((avRedStack{terminals{mouse}(ccell)}./ (nanmean(avRedStack{terminals{mouse}(ccell)}(:,:,BLstart:changePt),3)))*100)-100;
end 
%}
%select the correct channel for vessel segmentation  
if rightVesChan == 0     
    vesChan = VesAvGreenStack;
elseif rightVesChan == 1
    vesChan = VesAvRedStack;
end    
clearvars avGreenStack avRedStack VesAvGreenStack VesAvRedStack

%temporal smoothing option
smoothQ = input('Input 0 if you do not want to do temporal smoothing. Input 1 otherwise. ');
if smoothQ == 0 
    SNgreenStackAv = NgreenStackAv;
    SNredStackAv = NredStackAv;
    if spikeQ == 1 
        snCIhighAv = nCIhighAv;
        snCIlowAv = nCIlowAv;
    end 
elseif smoothQ == 1
    filtTime = input('How many seconds do you want to smooth your data by? '); % our favorite STA trace is smoothed by 0.7 sec 
    filter_rate = FPSstack{mouse}*filtTime; 
    tempFiltChanQ= input('Input 0 to temporally smooth both channels. Input 1 otherwise. ');
    if tempFiltChanQ == 0     
        SNredStackAv = smoothdata(NredStackAv,3,'movmean',filter_rate);
        SNgreenStackAv = smoothdata(NgreenStackAv,3,'movmean',filter_rate);      
    elseif tempFiltChanQ == 1
        tempSmoothChanQ = input('Input 0 to temporally smooth green channel. Input 1 for red channel. ');
        if tempSmoothChanQ == 0
            SNredStackAv = NredStackAv;
            SNgreenStackAv = smoothdata(NgreenStackAv,3,'movmean',filter_rate);          
        elseif tempSmoothChanQ == 1
            SNgreenStackAv = NgreenStackAv;      
            SNredStackAv = smoothdata(NredStackAv,3,'movmean',filter_rate);                        
        end 
    end 
    if spikeQ == 1 
        snCIhighAv = smoothdata(nCIhighAv,3,'movmean',filter_rate);
        snCIlowAv = smoothdata(nCIlowAv,3,'movmean',filter_rate);         
    end 
end 
clearvars NgreenStackAv NredStackAv 
if spikeQ == 1
    clearvars nCIhighAv nCIlowAv
end 

%spatial smoothing option
spatSmoothQ = input('Input 0 if you do not want to do spatial smoothing. Input 1 otherwise. ');
if spatSmoothQ == 1 
    spatSmoothTypeQ = input('Input 0 to do gaussian spatial smoothing. Input 1 to do convolution spatial smoothing (using NxN array of 0.125 values). ');
    spatFiltChanQ= input('Input 0 to spatially smooth both channels. Input 1 otherwise. ');
    if spatFiltChanQ == 0 % if you want to spatially smooth both channels 
        redIn = SNredStackAv; 
        greenIn = SNgreenStackAv;
        if spikeQ == 1 
            CIhighIn = snCIhighAv;
            CIlowIn = snCIlowAv;    
            clearvars snCIhighAv snCIlowAv
        end 
        clearvars SNredStackAv SNgreenStackAv       
        if spatSmoothTypeQ == 0 % if you want to use gaussian spatial smoothing 
            sigma = input('What sigma do you want to use for Gaussian spatial filtering? ');
            SNredStackAv = imgaussfilt(redIn,sigma);
            SNgreenStackAv = imgaussfilt(greenIn,sigma);
            if spikeQ == 1
                snCIhighAv = imgaussfilt(CIhighIn,sigma);
                snCIlowAv = imgaussfilt(CIlowIn,sigma);
            end            
        elseif spatSmoothTypeQ == 1 % if you want to use convolution smoothing 
            % create your kernal for smoothing by convolution 
            kernalSize = input('What size NxN array do you want to use for convolution spatial filtering? ');
            K = 0.125*ones(kernalSize);
            SNredStackAv = convn(redIn,K,'same');
            SNgreenStackAv = convn(greenIn,K,'same');
            if spikeQ == 1
                snCIhighAv = convn(CIhighIn,K,'same');
                snCIlowAv = convn(CIlowIn,K,'same');
            end              
        end 
    elseif spatFiltChanQ == 1 % if you only want to spatially smooth one channel 
        spatSmoothChanQ = input('Input 0 to spatially smooth the green channel. Input 1 for the red channel. ');
        if spatSmoothTypeQ == 0 % if you want to use gaussian spatial smoothing 
            sigma = input('What sigma do you want to use for Gaussian spatial filtering? ');
            if spatSmoothChanQ == 0 % if you want to spatially smooth the green channel 
                greenIn = SNgreenStackAv;
                clearvars SNgreenStackAv
                SNgreenStackAv = imgaussfilt(greenIn,sigma);
                if spikeQ == 1 
                    snCIhighAv = imgaussfilt(CIhighIn,sigma);
                    snCIlowAv = imgaussfilt(CIlowIn,sigma);
                end                         
            elseif spatSmoothChanQ == 1 % if you want to spatially smooth the red channel 
                redIn = SNredStackAv; 
                clearvars SNredStackAv 
                SNredStackAv = imgaussfilt(redIn,sigma);
                if spikeQ == 1 
                    snCIhighAv = imgaussfilt(CIhighIn,sigma);
                    snCIlowAv = imgaussfilt(CIlowIn,sigma);
                end                                    
            end        
        elseif spatSmoothTypeQ == 1 % if you want to use convolution smoothing 
            % create your kernal for smoothing by convolution 
            kernalSize = input('What size NxN array do you want to use for convolution spatial filtering? ');
            K = 0.125*ones(kernalSize);
            if spatSmoothChanQ == 0 % if you want to spatially smooth the green channel 
                greenIn = SNgreenStackAv;
                clearvars SNgreenStackAv
                SNgreenStackAv = convn(greenIn,K,'same');
                if spikeQ == 1 
                    snCIhighAv = convn(CIhighIn,K,'same');
                    snCIlowAv = convn(CIlowIn,K,'same');
                end               
            elseif spatSmoothChanQ == 1 % if you want to spatially smooth the red channel 
                redIn = SNredStackAv; 
                clearvars SNredStackAv 
                SNredStackAv = convn(redIn,K,'same');
                if spikeQ == 1 
                    snCIhighAv = convn(CIhighIn,K,'same');
                    snCIlowAv = convn(CIlowIn,K,'same');
                end                                     
            end                          
        end 
    end 
end 
clearvars redIn greenIn 
if spikeQ == 1 
    clearvars CIhighIn CIlowIn
end 

% black out the pixels that are part of calcium ROIs 
if dataTypeQ == 0 
    blackOutCaROIQ = input('Input 1 if you want to black out pixels in Ca ROIs. Input 0 otherwise. ');
elseif dataTypeQ == 1 
    blackOutCaROIQ = 0;
end 
if blackOutCaROIQ == 1         
    CaROImaskDir = uigetdir('*.*','WHERE ARE THE CA ROI COORDINATES?');
    cd(CaROImaskDir);
    CaROImaskFileName = uigetfile('*.*','GET THE CA ROI COORDINATES'); 
    CaROImaskMat = matfile(CaROImaskFileName); 
    CaROImasks = CaROImaskMat.CaROImasks;
    % check to see if ROIorders exists in the matfile 
    variableInfo = who(CaROImaskMat);
    if ismember("ROIorders", variableInfo) == 1 % returns true 
        ROIorders = CaROImaskMat.ROIorders;                
    end   
    % crop if necessary 
    if cropQ == 1 
        if ismember("ROIorders", variableInfo) == 1 % returns true 
            ROIorders2 = cell(1,length(ROIorders));
            for z = 1:length(ROIorders)
                cropdIm = imcrop(ROIorders{z},rect);
                ROIorders2{z} = cropdIm;
            end     
        end 
        CaROImasks2 = cell(1,length(CaROImasks));
        for z = 1:length(CaROImasks)
            cropdIm = imcrop(CaROImasks{z},rect);
            CaROImasks2{z} = cropdIm;
        end              
        clearvars CaROImasks; CaROImasks = CaROImasks2; clearvars CaROImasks2 
        if ismember("ROIorders", variableInfo) == 1 % returns true 
            clearvars ROIorders; ROIorders = ROIorders2; clearvars ROIorders2
        end 
    end 
    % combine Ca ROIs from different planes in Z into one plane 
    if ismember("ROIorders", variableInfo) == 1 % returns true
        numZplanes = length(ROIorders);
    elseif ismember("ROIorders", variableInfo) == 0
        numZplanes = length(CaROImasks);
    end 
    if numZplanes > 1 
        combo = cell(1,numZplanes-1);
        combo2 = cell(1,numZplanes-1);
        for it = 1:numZplanes-1
            if it == 1 
                combo{it} = or(CaROImasks{1},CaROImasks{2});
                if ismember("ROIorders", variableInfo) == 1 % returns true
                    combo2{it} = or(ROIorders{1},ROIorders{2});
                end 
            elseif it > 1
                combo{it} = or(combo{it-1},CaROImasks{it+1});
                if ismember("ROIorders", variableInfo) == 1 % returns true
                    combo2{it} = or(combo2{it-1},ROIorders{it+1});
                end 
            end 
        end      
        ROIorders = combo2;
    elseif numZplanes == 1 
        combo = CaROImasks;       
    end    
    %make your combined Ca ROI mask the right size for applying to a 3D
    %arrray 
    ind = length(combo); combo1 = combo{ind};
    % downsample the Ca ROI mask if necessary 
    if exist("downsampleRate", 'var') == 1
        dwnC = downsample(combo1,downsampleRate);
        dwnC = permute(dwnC,[2 1 3]);
        dwnC = downsample(dwnC,downsampleRate);
        dwnC = permute(dwnC,[2 1 3]);  
        combo1 = dwnC; 
        clearvars dwnC 
    end 
    ThreeDCaMask = logical(repmat(combo1,1,1,size(SNredStackAv,3)));
    %apply new mask to the right channel 
    % this is defined above: rightChan = input('Input 0 if BBB data is in the green chanel. Input 1 if BBB data is in the red channel. ');
    if rightChan == 0     
        RightChan = SNgreenStackAv;
        otherChan = SNredStackAv;
    elseif rightChan == 1
        RightChan = SNredStackAv;
        otherChan = SNgreenStackAv;
    end     
    RightChan(ThreeDCaMask) = 0;   
elseif blackOutCaROIQ == 0          
    if rightChan == 0     
        RightChan = SNgreenStackAv;
        otherChan = SNredStackAv;
    elseif rightChan == 1
        RightChan = SNredStackAv;
        otherChan = SNgreenStackAv;
    end   
end 
clearvars SNgreenStackAv SNredStackAv

% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
segQ = input('Input 1 if you need to create a new vessel segmentation algorithm. Input 0 otherwise. ');
% create outline of vessel to overlay the %change BBB perm stack 
segmentVessel = 1;
while segmentVessel == 1 
    % apply Ca ROI mask to the appropriate channel to black out these
    % pixels 
    if blackOutCaROIQ == 1
        vesChan(ThreeDCaMask) = 0; 
    end    
    %segment the vessel (small sample of the data) 
    if segQ == 1    
        imageSegmenter(mean(vesChan,3))
        continu = input('Is the image segmenter closed? Yes = 1. No = 0. ');
    elseif segQ == 0 
        continu = 1;
    end   
    while continu == 1 
        BWstacks = nan(size(vesChan(:,:,1),1),size(vesChan(:,:,1),2),size(vesChan,3));
        BW_perim = nan(size(vesChan(:,:,1),1),size(vesChan(:,:,1),2),size(vesChan,3));
        segOverlays = nan(size(vesChan(:,:,1),1),size(vesChan(:,:,1),2),3,size(vesChan,3));   
        for frame = 1:size(vesChan,3)
            [BW,~] = segmentImageWT5_20190401_optoETA_20240220zScored(vesChan(:,:,frame)); % UPDATE HERE 
            BWstacks(:,:,frame) = BW; 
            %get the segmentation boundaries 
            BW_perim(:,:,frame) = bwperim(BW);
            %overlay segmentation boundaries on data
            segOverlays(:,:,:,frame) = imoverlay(mat2gray(vesChan(:,:,frame)), BW_perim(:,:,frame), [.3 1 .3]);   
        end      
        %play segmentation
        implay(BWstacks)
        continu = 0;
    end 
    %ask about segmentation quality    
    segmentVessel = input("Does the vessel need to be segmented again? Yes = 1. No = 0. ");
    if segmentVessel == 1
        clearvars BWthreshold BWopenRadius BW se boundaries
    end 
    if segQ == 0 
        segmentVessel = 0;
    end 
end
clearvars segOverlays 

cMapQ = input('Input 0 to create a color map that is red for positive % change and green for negative % change. Input 1 to create a colormap for only positive going values. ');
if cMapQ == 0
    % Create colormap that is green for positive, red for negative,
    % and a chunk inthe middle that is black.
%     greenColorMap = [zeros(1, 156), linspace(0, 1, 100)];
%     redColorMap = [linspace(1, 0, 100), zeros(1, 156)];
    % these are the original colors 
    greenColorMap = [zeros(1, 132), linspace(0, 1, 124)];
    redColorMap = [linspace(1, 0, 124), zeros(1, 132)];
    cMap = [redColorMap; greenColorMap; zeros(1, 256)]';
elseif cMapQ == 1
    % Create colormap that is green at max and black at min
    % this is the original green colorbar 
    % greenColorMap = linspace(0, 1, 256);
    % green colorbar with less green (what I've been using for z-scored
    % vids)
    % greenColorMap = [zeros(1, 60), linspace(0, 1, 196)];
    % greenColorMap with even less green (SF110 opto for Sabattini talk)
    % greenColorMap = [zeros(1, 170), linspace(0, 1, 86)];
    % steeper green colorbar (SF-57) w/more green greenColorMap =
    greenColorMap = [linspace(0, 1, 200),ones(1,56)];
    cMap = [zeros(1, 256); greenColorMap; zeros(1, 256)]';

%     % steeper green colorbar (SF-56)
%     greenColorMap = [linspace(0, 1, 110),ones(1,146)];
%     cMap = [zeros(1, 256); greenColorMap; zeros(1, 256)]';    
end 

% create a binarized version of the STA vids
% 1 means greater than 95% CI and 2 means lower than 95% CI 
if spikeQ == 1 
    clearvars RightChan
    RightChan = nonShuffledMat.RightChan;

    % create binary STA vid 
    binarySTAhigh = RightChan > snCIhighAv; 
    binarySTAlow = RightChan < snCIlowAv; 
    data = single(binarySTAhigh);
    binarySTA = data;
    binarySTA(binarySTAlow) = 2;
    clearvars binarySTAhigh binarySTAlow

    clearvars data
    data{1} = RightChan;
    clearvars RightChan terminals; 
    RightChan = data;
    terminals{1} = 1;
    clearvars data 
    data = binarySTA;
    clearvars binarySTA;
    binarySTA{1} = data;
    clearvars data;
    data = BW_perim;
    clearvars BW_perim;
    BW_perim{1} = data;
    clearvars data;
    data = BWstacks;
    clearvars BWstacks;
    BWstacks{1} = logical(data);
    data = vesChan;
    clearvars vesChan;
    vesChan{1} = data;
    clearvars data
    data = sigLocs; 
    clearvars sigLocs 
    for vid = 1:length(vidList{mouse}) 
        sigLocs{vid}{1} = data{vid};
    end 
    clearvars data
end 

% save out the workspace variables 
if spikeQ == 0 
    dir1 = uigetdir('*.*','WHAT FOLDER ARE YOU SAVING THE DATA IN?'); % get the directory where you want to save your images 
    dir2 = strrep(dir1,'\','/'); % change the direction of the slashes 
    filename = sprintf('%s/ETAstackData_realOptoStimLocs',dir2);
    save(filename)
elseif spikeQ == 1 
    dir1 = uigetdir('*.*','WHAT FOLDER ARE YOU SAVING THE DATA IN?'); % get the directory where you want to save your images 
    dir2 = strrep(dir1,'\','/');
    filename = sprintf('%s/ETAstackData_bootStrapped1kShuffledStimLocs',dir2);
    save(filename)    
end 


%% save out the images and/or plot traces 

% to make sure Ca ROIs show an average peak in the same frame, before
% moving onto the next step 
vesBlackQ = input('Input 1 to black out vessel. '); 
if iscell(RightChan) == 1 
    ims = RightChan{1};
    CaEventFrame = floor(size(RightChan{1},3)/2); % input('What frame does the opto stim start? ');
elseif iscell(RightChan) == 0
    ims = RightChan;
    CaEventFrame = floor(size(RightChan,3)/2); % input('What frame does the opto stim start? ');    
end 
%overlay vessel outline and GCaMP activity of the specific Ca ROI on top of %change images, black out pixels where
%the vessel is (because they're distracting), and save these images to a
%folder of your choosing (there will be subFolders per calcium ROI)
genImQ = input("Input 1 if you need to save out the images. ");   
if genImQ == 1 
    dir1 = uigetdir('*.*','WHAT FOLDER ARE YOU SAVING THE PHOTOS IN?'); % get the directory where you want to save your images 
    dir2 = strrep(dir1,'\','/');
end 
%black out pixels that belong to vessels   
if vesBlackQ == 1 
    if iscell(BWstacks) == 1 
        BWstacks = logical(BWstacks{1});
    elseif iscell(BWstacks) == 0
        BWstacks = logical(BWstacks);
    end 
    ims(BWstacks) = 0;
end                            
%find the upper and lower bounds of your data (per calcium ROI) 
maxValue = max(max(max(max(ims))));
minValue = min(min(min(min(ims))));
minMaxAbsVals = [abs(minValue),abs(maxValue)];
maxAbVal = max(minMaxAbsVals);
BBBtraceQ = input('Input 1 to plot BBB/dlight traces. Input 0 otherwise. ');
% ask user where to crop image             
if BBBtraceQ == 1 
    BBBtraceNumQ = input("How manny BBB/dlight traces do you want to generate? ");
end                         
if genImQ == 1 
    %create a new folder per calcium ROI 
    newFolder = ('Images');
    mkdir(dir2,newFolder)
end 
%overlay segmentation boundaries on the % change image stack and save
%images
if iscell(vesChan) == 0 
    numFrames = size(vesChan,3);   
elseif iscell(vesChan) == 1
    numFrames = size(vesChan{1},3);
end 
for frame = 1:numFrames
    figure('Visible','off');  
    if BBBtraceQ == 1
        if frame == 1
            ROIboundDatas = cell(1,BBBtraceNumQ);
            ROIstacks = cell(1,length(terminals{mouse}));
            for BBBroi = 1:BBBtraceNumQ
                % create BBB ROIs 
                disp('Create your ROI for BBB perm analysis');
                [~,xmins,ymins,widths,heights] = firstTimeCreateROIs(1,ims(:,:,frame));
                ROIboundData{1} = xmins;
                ROIboundData{2} = ymins;
                ROIboundData{3} = widths;
                ROIboundData{4} = heights;
                ROIboundDatas{BBBroi} = ROIboundData;                          
            end 
        end                  
        for BBBroi = 1:BBBtraceNumQ
            %use the ROI boundaries to generate ROIstacks 
            xmins = ROIboundDatas{BBBroi}{1};
            ymins = ROIboundDatas{BBBroi}{2};
            widths = ROIboundDatas{BBBroi}{3};
            heights = ROIboundDatas{BBBroi}{4};
            [ROI_stacks] = make_ROIs_notfirst_time(ims(:,:,frame),xmins,ymins,widths,heights);
            ROIstacks{BBBroi}(:,:,frame) = ROI_stacks{1};
        end 
    end 
    % create the % change image with the right white and black point
    % boundaries and colormap 
    if cMapQ == 0
        imagesc(ims(:,:,frame),[-maxAbVal,maxAbVal]); colormap(cMap); colorbar%this makes the max point 1% and the min point -1% 
    elseif cMapQ == 1 
        imagesc(ims(:,:,frame),[0,maxAbVal/3]); colormap(cMap); colorbar%this makes the max point 1% and the min point -1% 
    end                                    
    % get the x-y coordinates of the vessel outline
    if iscell(BW_perim) == 0
        [yf, xf] = find(BW_perim(:,:,frame));  % x and y are column vectors.
    elseif iscell(BW_perim) == 1
        [yf, xf] = find(BW_perim{1}(:,:,frame));  % x and y are column vectors.
    end                                          
    % plot the vessel outline over the % change image 
    hold on;
    scatter(xf,yf,'white','.');
    if cropQ == 1
        axonPixSize = 500;
    elseif cropQ == 0
        axonPixSize = 100;
    end 
    % plot colored border to show when event occurs 
    if frame == CaEventFrame || frame == (CaEventFrame-1) || frame == (CaEventFrame+1)
        %get border coordinates 
        colLen = size(ims,2);
        rowLen = size(ims,1);
        edg1_x = repelem(1,rowLen);
        edg1_y = 1:rowLen;
        edg2_x = repelem(colLen,rowLen);
        edg2_y = 1:rowLen;
        edg3_x = 1:colLen;
        edg3_y = repelem(1,colLen);
        edg4_x = 1:colLen;
        edg4_y = repelem(rowLen,colLen);
        edg_x = [edg1_x,edg2_x,edg3_x,edg4_x];
        edg_y = [edg1_y,edg2_y,edg3_y,edg4_y];
        hold on;
        scatter(edg_x,edg_y,100,'blue','filled','square');      
    end 
    ax = gca;
    ax.Visible = 'off';
    ax.FontSize = 20;
    if genImQ == 1 
        %save current figure to file 
        filename = sprintf('%s/Images/frame%d',dir2,frame);
        saveas(gca,[filename '.png'])
    end 
end            
% plot the BBB/dlight traces 
if BBBtraceQ == 1
    traceData = cell(1,BBBtraceNumQ);
    for BBBroi = 1:BBBtraceNumQ
        % turn 0s into NaNs 
        ROIstacks{BBBroi}(ROIstacks{BBBroi}==0) = NaN; 
        % average across per frame         
        for frame = 1:size(ROIstacks{BBBroi},3)
            traceData{BBBroi}(frame) = nanmean(nanmean(ROIstacks{BBBroi}(:,:,frame)));
        end 
    end
    % plot the figure 
    figure;
    ax=gca;
    clr = hsv(BBBtraceNumQ);
    hold all;
    for BBBroi = 1:BBBtraceNumQ
        plot(traceData{BBBroi},'Color',clr(1,:),'LineWidth',2)
    end 
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    ylabel("Z-Scored Change in Pixel Intensity")
    xlabel("Time (sec)") 
    Frames = size(ims,3);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
    FrameVals(3) = CaEventFrame;
    FrameVals(2) = CaEventFrame - (Frames/5);
    FrameVals(1) = FrameVals(2) - (Frames/5);
    FrameVals(4) = CaEventFrame + (Frames/5);
    FrameVals(5) = FrameVals(4) + (Frames/5); 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals; 
end


%}
%% (STA stacks) create red and green channel stack averages around calcium peak location (one animal at a time) 
% z scores the entire stack before sorting into windows for averaging 
% option to high pass filter the video 
% can create shuffled and bootrapped x number of spikes (based on input) 
% (must save out non-shuffled STA vids before making
% shuffled and bootstrapped STA vids to create binary vids for DBSCAN)
%{
greenStacksOrigin = greenStacks;
redStacksOrigin = redStacks;
% option to downsample the data 
downSampleQ = input('Input 1 to downsample the data. '); 
while downSampleQ == 1 
    dwnR = cell(1,length(vidList{mouse})); 
    dwnG = cell(1,length(vidList{mouse})); 
    downsampleRate = input("Input the downsample rate. ");
    for vid = 1:length(greenStacksOrigin)
        dwnR{vid} = downsample(redStacksOrigin{vid},downsampleRate);
        dwnR{vid} = permute(dwnR{vid},[2 1 3]);
        dwnR{vid} = downsample(dwnR{vid},downsampleRate);
        dwnR{vid} = permute(dwnR{vid},[2 1 3]);       
        dwnG{vid} = downsample(greenStacksOrigin{vid},downsampleRate);
        dwnG{vid} = permute(dwnG{vid},[2 1 3]);
        dwnG{vid} = downsample(dwnG{vid},downsampleRate);
        dwnG{vid} = permute(dwnG{vid},[2 1 3]);   
    end 
    implay(redStacksOrigin{1}); implay(dwnR{1}); implay(greenStacksOrigin{1}); implay(dwnG{1});
    downSampleQ2 = input('Input 1 if the data looks good and does not need re-downsampling. '); 
    if downSampleQ2 == 1
        greenStacksOrigin = dwnG; redStacksOrigin = dwnR; 
        clearvars dwnG dwnR
        downSampleQ = 0; 
    end 
end 
if exist('dataScrambleCutOffs','var') == 0 && exist('dataScrambleQ','var') == 0
    dataScrambleQ = input('Input 1 if there is data scramble. Input 0 otherwise. ');
    if dataScrambleQ == 1 
        dataScrambleCutOffs = input('What are the data scramble frame cut offs for all of the raw videos? ');
        for vid = 1:length(greenStacksOrigin)
            greenStacksOrigin{vid} = greenStacksOrigin{vid}(:,:,1:dataScrambleCutOffs(vid));
            redStacksOrigin{vid} = redStacksOrigin{vid}(:,:,1:dataScrambleCutOffs(vid));
        end 
    end 
end 
spikeQ = input("Input 0 to use real calcium spikes. Input 1 to use randomized and bootstrapped spikes (based on ISI STD). "); 
if spikeQ == 1
    itNum = input('Input the number of bootstrap iterations that you want. ');
end 
% sort red and green channel stacks based on ca peak location 
for mouse = 1:mouseNum
%     dir1 = dataDir{mouse};   
    % find peaks and then plot where they are in the entire TS 
    stdTrace = cell(1,length(vidList{mouse})); 
    sigPeaks = cell(1,length(vidList{mouse}));
    sigLocs = cell(1,length(vidList{mouse}));
    for vid = 1:length(vidList{mouse})
        for ccell = 1:length(terminals{mouse})
            %find the peaks 
    %         figure;
    %         ax=gca;
    %         hold all
            [peaks, locs] = findpeaks(cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)},'MinPeakProminence',0.1,'MinPeakWidth',2); %0.6,0.8,0.9,1\
            %find the sig peaks (peaks above 2 standard deviations from mean) 
            stdTrace{vid}{terminals{mouse}(ccell)} = std(cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)});  
            count = 1 ; 
            for loc = 1:length(locs)
                if peaks(loc) > stdTrace{vid}{terminals{mouse}(ccell)}*2
                    %if the peaks fall within the time windows used for the BBB
                    %trace examples in the DOD figure 
    %                 if locs(loc) > 197*FPSstack{mouse} && locs(loc) < 206.5*FPSstack{mouse} || locs(loc) > 256*FPSstack{mouse} && locs(loc) < 265.5*FPSstack{mouse} || locs(loc) > 509*FPSstack{mouse} && locs(loc) < 518.5*FPSstack{mouse}
                        sigPeaks{vid}{terminals{mouse}(ccell)}(count) = peaks(loc);
                        sigLocs{vid}{terminals{mouse}(ccell)}(count) = locs(loc);
    %                     plot([locs(loc) locs(loc)], [-5000 5000], 'k','LineWidth',2)
                        count = count + 1;
    %                 end 
                end 
            end 
            % below is plotting code 
            %{
            Frames = size(cDataFullTrace{vid}{terminals{mouse}(ccell)},2);
            Frames_pre_stim_start = -((Frames-1)/2); 
            Frames_post_stim_start = (Frames-1)/2; 
    %         sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}*50:Frames_post_stim_start)/FPSstack{mouse})+51);
            sec_TimeVals = floor(((0:2:(Frames/FPSstack{mouse}))));
            min_TimeVals = round(sec_TimeVals/60,2)+7.03;
            FrameVals = floor((0:(FPSstack{mouse}*2):Frames)); 

            %smooth the calcium data 
            [ScDataFullTrace] = MovMeanSmoothData(cDataFullTrace{vid}{terminals{mouse}(ccell)},(2/FPSstack{mouse}),FPSstack{mouse});

    %         plot((cDataFullTrace{vid}{terminals{mouse}(ccell)})+150,'b','LineWidth',3)
    %         plot(ScDataFullTrace+150,'b','LineWidth',3)
            plot(bDataFullTrace{vid},'r','LineWidth',3)

    %         for trial = 1:size(state_start_f{mouse}{vid},1)
    %             if TrialTypes{mouse}{vid}(trial,2) == 1
    %                 plot([state_start_f{mouse}{vid}(trial) state_start_f{mouse}{vid}(trial)], [-5000 5000], 'b','LineWidth',2)
    %                 plot([state_end_f{mouse}{vid}(trial) state_end_f{mouse}{vid}(trial)], [-5000 5000], 'b','LineWidth',2)
    %             elseif TrialTypes{mouse}{vid}(trial,2) == 2
    %                 plot([state_start_f{mouse}{vid}(trial) state_start_f{mouse}{vid}(trial)], [-5000 5000], 'r','LineWidth',2)
    %                 plot([state_end_f{mouse}{vid}(trial) state_end_f{mouse}{vid}(trial)], [-5000 5000], 'r','LineWidth',2)
    %             end 
    %         end 

            count = 1 ; 
            for loc = 1:length(locs)
                if peaks(loc) > stdTrace{vid}{terminals{mouse}(ccell)}*2
                    sigPeaks{vid}{terminals{mouse}(ccell)}(count) = peaks(loc);
                    sigLocs{vid}{terminals{mouse}(ccell)}(count) = locs(loc);
                    plot([locs(loc) locs(loc)], [-5000 5000], 'k','LineWidth',2)
                    count = count + 1;
                end 
            end 

    %         legend('Calcium signal','BBB permeability','Calcium peak','Location','NorthWest')

    % 
            ax.XTick = FrameVals;
            ax.XTickLabel = sec_TimeVals;
            ax.FontSize = 25;
            ax.FontName = 'Times';
            xLimStart = 256*FPSstack{mouse};
            xLimEnd = 266.5*FPSstack{mouse}; 
            xlim([0 size(cDataFullTrace{vid}{terminals{mouse}(ccell)},2)])
            xlim([xLimStart xLimEnd])
            ylim([-23 80])
            xlabel('time (sec)','FontName','Times')
    %         if smoothQ ==  1
    %             title({sprintf('terminal #%d data',terminals{mouse}(ccell)); sprintf('smoothed by %0.2f seconds',filtTime)})
    %         elseif smoothQ == 0 
    %             title(sprintf('terminal #%d raw data',terminals{mouse}(ccell)))
    %         end    
               %}
        end 
    end 
end 
clearvars peaks locs 
if spikeQ == 1   
    spikeISIs = cell(1,length(vidList{mouse})); 
    ISIstds = cell(1,length(vidList{mouse})); 
    randSpikes = cell(1,length(vidList{mouse})); 
    ISImean = cell(1,length(vidList{mouse}));
    randISIs = cell(1,length(vidList{mouse}));
    randSigLocs = cell(1,length(vidList{mouse}));
    for it = 1:itNum
        for vid = 1:length(vidList{mouse})
            for ccell = 1:length(terminals{mouse})
                % determine ISI
                spikeISIs{vid}{terminals{mouse}(ccell)} = diff(sigLocs{vid}{terminals{mouse}(ccell)});
                % determine STD (sigma) of ISI 
                ISIstds{vid}{terminals{mouse}(ccell)} = std(spikeISIs{vid}{terminals{mouse}(ccell)});
                % determine mean ISI 
                ISImean{vid}{terminals{mouse}(ccell)} = mean(spikeISIs{vid}{terminals{mouse}(ccell)});
                % generate random spike Locs (sigLocs) based on ISI STD using same            
                for spike = 1:length(spikeISIs{vid}{terminals{mouse}(ccell)})
                    % generate random ISI
                    r = random('Exponential',ISImean{vid}{terminals{mouse}(ccell)});
                    randISIs{vid}{terminals{mouse}(ccell)}(spike) = floor(r);
                end              
                % plot distribution of real and rand ISIs for sanity check 
                %{
                figure;
                histogram(spikeISIs{vid}{terminals{mouse}(ccell)});
                title(sprintf("Real Spike ISIs. Vid %d. Axon %d. ",vid,terminals{mouse}(ccell)));
                figure;
                histogram(randISIs{vid}{terminals{mouse}(ccell)})
                title(sprintf("Rand Spike ISIs. Vid %d. Axon %d. ",vid,terminals{mouse}(ccell)));
                %}
                % use randISIs to generate randSigLocs 
                randSigLocs{vid}{terminals{mouse}(ccell)}(it,:) = cumsum(randISIs{vid}{terminals{mouse}(ccell)});
            end 
        end      
    end 
    sigLocs = randSigLocs;
end 
clearvars randSigLocs 
% crop the imaging data if you want to; better to do this up here to
% maximize computational speed ~ 
rightChan = input('Input 0 if BBB data is in the green chanel. Input 1 if BBB data is in the red channel. ');
cropQ = input("Input 1 if you want to crop the image. Input 0 otherwise. ");
% ask user where to crop image     
if cropQ == 1 
    %select the correct channel to view for cropping 
    if rightChan == 0     
        hold off;
        cropIm = nanmean(greenStacksOrigin{1},3); %#ok<*NANMEAN> 
    elseif rightChan == 1
        hold off; 
        cropIm = nanmean(redStacksOrigin{1},3);
    end         
    [~, rect] = imcrop(cropIm);
end  
% crop if necessary  
greenStacks2 = cell(1,length(vidList{mouse}));
redStacks2 = cell(1,length(vidList{mouse}));
if cropQ == 1 
    for vid = 1:length(vidList{mouse})
        for frame = 1:size(greenStacksOrigin{vid},3)
            cropdIm = imcrop(greenStacksOrigin{vid}(:,:,frame),rect);
            greenStacks2{vid}(:,:,frame) = cropdIm;
        end 
    end 
    
    for vid = 1:length(vidList{mouse})
        for frame = 1:size(greenStacksOrigin{vid},3)
            cropdIm = imcrop(redStacksOrigin{vid}(:,:,frame),rect);
            redStacks2{vid}(:,:,frame) = cropdIm;
        end 
    end 
elseif cropQ == 0
    greenStacks2 = greenStacksOrigin;
    redStacks2 = redStacksOrigin;
end  
clearvars greenStacks redStacks
greenStacks = greenStacks2;
redStacks = redStacks2;
clearvars greenStacks2 redStacks2
% high pass filter the videos if you want 
highPassQ = input("Input 1 if you want to high pass filter the videos. Input 0 otherwise. ");
if highPassQ == 1 
    hpfGreen = cell(1,length(vidList{mouse}));
    hpfRed = cell(1,length(vidList{mouse}));
    for vid = 1:length(vidList{mouse})
        %get sliding baseline 
        [greenSlidingBL]=slidingBaselineVid(greenStacks{vid},floor((FPS)*10),0.5); %0.5 quantile thresh = the median value    
        [redSlidingBL]=slidingBaselineVid(redStacks{vid},floor((FPS)*10),0.5);
        %subtract sliding baseline from F
        hpfGreen{vid} = greenStacks{vid}-greenSlidingBL;
        hpfRed{vid} = redStacks{vid}-redSlidingBL;       
    end 
    clearvars greenSlidingBL redSlidingBL
elseif highPassQ == 0 
    hpfGreen = greenStacks;
    hpfRed = redStacks;
end 
% combine the vids to get z score of whole experiment
frameLens = zeros(1,length(vidList{mouse}));
for vid = 1:length(vidList{mouse})
    if vid == 1 
        frameLen = size(greenStacks{vid},3);
    elseif vid > 1 
        frameLen = frameLen + size(greenStacks{vid},3);
    end 
    frameLens(vid) = size(greenStacks{vid},3);
end 
combGreenStack = zeros(size(greenStacks{1},1),size(greenStacks{1},2),frameLen);
combRedStack = zeros(size(greenStacks{1},1),size(greenStacks{1},2),frameLen);
for vid = 1:length(vidList{mouse})
    if vid == 1 
        count = size(greenStacks{vid},3);
    end 
    for frame = 1:size(greenStacks{vid},3) 
        if vid == 1 
            combGreenStack(:,:,frame) = hpfGreen{vid}(:,:,frame);
            combRedStack(:,:,frame) = hpfRed{vid}(:,:,frame);
        elseif vid > 1 
            combGreenStack(:,:,count+1) = hpfGreen{vid}(:,:,frame);
            combRedStack(:,:,count+1) = hpfRed{vid}(:,:,frame);
            count = count + 1;                                      
        end 
    end     
end 
% z score the videos 
zGreenStack = zscore(combGreenStack,0,3);
zRedStack = zscore(combRedStack,0,3);
clearvars combGreenStack combRedStack
% resort videos
szGreenStack = cell(1,length(vidList{mouse}));
szRedStack = cell(1,length(vidList{mouse}));
count = 1;
for vid = 1:length(vidList{mouse})
    for frame = 1:frameLens(vid)       
        szGreenStack{vid}(:,:,frame) = zGreenStack(:,:,count); 
        szRedStack{vid}(:,:,frame) = zRedStack(:,:,count); 
        count = count + 1;
    end 
end 
clearvars zGreenStack zRedStack
% further sort and average data, get 95% CI bounds 
CI_High = cell(1,max(terminals{mouse}));
CI_Low = cell(1,max(terminals{mouse}));
CIlowAv = cell(1,max(terminals{mouse}));
CIhighAv = cell(1,max(terminals{mouse}));
windSize = input('How big should the window be around Ca peak in seconds? '); %24
workFlow = 1;
while workFlow == 1 
    tic
    if spikeQ == 1 
%         CIq = input('Input 0 to get 95% CI. Input 1 for 99% CI. ')
        HighLowQ = input('Input 0 to get the low CI bound . Input 1 for the high CI bound. ');  
    end 
    for it = 1:size(sigLocs{vid}{terminals{mouse}(ccell)},1)
        % sort data 
        % terminals = terminals{1};
        if tTypeQ == 0 
            sortedGreenStacks = cell(1,length(vidList{mouse}));
            sortedRedStacks = cell(1,length(vidList{mouse}));
            if rightChan == 0     
                VesSortedGreenStacks = cell(1,length(vidList{mouse}));
            elseif rightChan == 1
                VesSortedRedStacks = cell(1,length(vidList{mouse}));
            end    
                for vid = 1:length(vidList{mouse})
                    for ccell = 1:length(terminals{mouse})               
                        for peak = 1:size(sigLocs{vid}{terminals{mouse}(ccell)},2)            
                            if sigLocs{vid}{terminals{mouse}(ccell)}(it,peak)-floor((windSize/2)*FPSstack{mouse}) > 0 && sigLocs{vid}{terminals{mouse}(ccell)}(it,peak)+floor((windSize/2)*FPSstack{mouse}) < length(cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)})                
                                start = sigLocs{vid}{terminals{mouse}(ccell)}(it,peak)-floor((windSize/2)*FPSstack{mouse});
                                stop = sigLocs{vid}{terminals{mouse}(ccell)}(it,peak)+floor((windSize/2)*FPSstack{mouse});                
                                if start == 0 
                                    start = 1 ;
                                    stop = start + floor((windSize/2)*FPSstack{mouse}) + floor((windSize/2)*FPSstack{mouse});
                                end        
                                if stop < size(szGreenStack{vid},3)
                                    sortedGreenStacks{vid}{terminals{mouse}(ccell)}{peak} = szGreenStack{vid}(:,:,start:stop);
                                    sortedRedStacks{vid}{terminals{mouse}(ccell)}{peak} = szRedStack{vid}(:,:,start:stop);
                                    if rightChan == 0     
                                        VesSortedGreenStacks{vid}{terminals{mouse}(ccell)}{peak} = greenStacks{vid}(:,:,start:stop);
                                    elseif rightChan == 1
                                        VesSortedRedStacks{vid}{terminals{mouse}(ccell)}{peak} = redStacks{vid}(:,:,start:stop);
                                    end    
                                end 
                            end 
                        end               
                    end 
                end 
        elseif tTypeQ == 1
            %tTypeSigLocs{vid}{CaROI}{1} = blue light
            %tTypeSigLocs{vid}{CaROI}{2} = red light
            %tTypeSigLocs{vid}{CaROI}{3} = ISI
            sortedGreenStacks = cell(1,length(vidList{mouse}));
            sortedRedStacks = cell(1,length(vidList{mouse}));
            for vid = 1:length(vidList{mouse})  
                for ccell = 1:length(terminals{mouse})   
                    for per = 1:3 
                        for peak = 1:length(tTypeSigLocs{vid}{terminals{mouse}(ccell)}{per})                    
                            if tTypeSigLocs{vid}{terminals{mouse}(ccell)}{per}(peak)-floor((windSize/2)*FPSstack{mouse}) > 0 && tTypeSigLocs{vid}{terminals{mouse}(ccell)}{per}(peak)+floor((windSize/2)*FPSstack{mouse}) < length(cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)})                                     
                                start = tTypeSigLocs{vid}{terminals{mouse}(ccell)}{per}(peak)-floor((windSize/2)*FPSstack{mouse});
                                stop = tTypeSigLocs{vid}{terminals{mouse}(ccell)}{per}(peak)+floor((windSize/2)*FPSstack{mouse}); 
                                if start == 0 
                                    start = 1 ;
                                    stop = start + floor((windSize/2)*FPSstack{mouse}) + floor((windSize/2)*FPSstack{mouse});
                                end                
                                sortedGreenStacks{vid}{terminals{mouse}(ccell)}{per}{peak} = szGreenStack{vid}(:,:,start:stop);
                                sortedRedStacks{vid}{terminals{mouse}(ccell)}{per}{peak} = szRedStack{vid}(:,:,start:stop);
                            end 
                        end 
                    end 
                end 
            end   
        end 
    %     clearvars greenStacks redStacks start stop sigLocs sigPeaks 
    
        % resort and average calcium peak aligned traces across videos 
        if tTypeQ == 0 
            greenStackArray2 = cell(1,max(terminals{mouse}));
            if rightChan == 0     
                VesGreenStackArray2 = cell(1,max(terminals{mouse}));
            end  
            for ccell = 1:length(terminals{mouse})
                count = 1;
                for vid = 1:length(vidList{mouse})     
                    if length(sortedGreenStacks{vid}) >= terminals{mouse}(ccell)
                        for peak = 1:size(sortedGreenStacks{vid}{terminals{mouse}(ccell)},2)  
                            if isempty(sortedGreenStacks{vid}{terminals{mouse}(ccell)}{peak}) == 0 
                                greenStackArray2{terminals{mouse}(ccell)}(:,:,:,count) = single(sortedGreenStacks{vid}{terminals{mouse}(ccell)}{peak});
                                if rightChan == 0
                                    VesGreenStackArray2{terminals{mouse}(ccell)}(:,:,:,count) = single(VesSortedGreenStacks{vid}{terminals{mouse}(ccell)}{peak});
                                end           
                                count = count + 1;
                            end 
                        end
                    end 
                end 
            end 
    %         clearvars sortedGreenStacks VesSortedGreenStacks
            clearvars VesSortedGreenStacks
            redStackArray2 = cell(1,max(terminals{mouse}));
            if rightChan == 1     
                VesRedStackArray2 = cell(1,max(terminals{mouse}));
            end  
            for ccell = 1:length(terminals{mouse})
                count = 1;
                for vid = 1:length(vidList{mouse})  
                    if length(sortedRedStacks{vid}) >= terminals{mouse}(ccell)  
                        for peak = 1:size(sortedRedStacks{vid}{terminals{mouse}(ccell)},2)  
                            if isempty(sortedRedStacks{vid}{terminals{mouse}(ccell)}{peak}) == 0 
                                redStackArray2{terminals{mouse}(ccell)}(:,:,:,count) = single(sortedRedStacks{vid}{terminals{mouse}(ccell)}{peak});
                                if rightChan == 1
                                    VesRedStackArray2{terminals{mouse}(ccell)}(:,:,:,count) = single(VesSortedRedStacks{vid}{terminals{mouse}(ccell)}{peak});
                                end           
                                count = count + 1;
                            end 
                        end
                    end 
                end 
            end 
    %         clearvars sortedRedStacks VesSortedRedStacks
            clearvars VesSortedRedStacks
            avGreenStack = cell(1,max(terminals{mouse}));
            for ccell = 1:length(terminals{mouse}) % determine the average 
                avGreenStack{terminals{mouse}(ccell)} = nanmean(greenStackArray2{terminals{mouse}(ccell)},4);
            end 
            clearvars greenStackArray2
            avRedStack = cell(1,max(terminals{mouse}));
            for ccell = 1:length(terminals{mouse}) % determine the average 
                avRedStack{terminals{mouse}(ccell)} = nanmean(redStackArray2{terminals{mouse}(ccell)},4);
            end 
            clearvars redStackArray2
            if rightChan == 0  
                VesAvGreenStack = cell(1,max(terminals{mouse}));
                for ccell = 1:length(terminals{mouse}) % determine the average 
                    VesAvGreenStack{terminals{mouse}(ccell)} = nanmean(VesGreenStackArray2{terminals{mouse}(ccell)},4);
                end 
                clearvars VesGreenStackArray2
            end 
            if rightChan == 1  
                VesAvRedStack = cell(1,max(terminals{mouse}));
                for ccell = 1:length(terminals{mouse}) % determine the average 
                    VesAvRedStack{terminals{mouse}(ccell)} = nanmean(VesRedStackArray2{terminals{mouse}(ccell)},4);
                end 
                clearvars VesRedStackArray2
            end 
    
            % determine 95% or 99% CI of bootstrapped data and av
            if spikeQ == 1
                for ccell = 1:length(terminals{mouse})
                    if rightChan == 0 % BBB data is in green channel 
                        SEM = (nanstd(avGreenStack,0,3))/(sqrt(size(avGreenStack,3))); % Standard Error 
                        ts_High = tinv(0.975,size(avGreenStack,3)-1);% T-Score for 95% CI
                        ts_Low =  tinv(0.025,size(avGreenStack,3)-1);% T-Score for 95% CI
        %                         ts_High = tinv(0.995,size(avRedStack{terminals{mouse}(ccell)},3)-1);% T-Score for 99% CI
        %                         ts_Low =  tinv(0.005,size(avRedStack{terminals{mouse}(ccell)},3)-1);% T-Score for 99% CI
                        if HighLowQ == 0
                            CI_Low(:,:,:,it) = (avGreenStack) + (ts_Low*SEM);   
                        elseif HighLowQ == 1 
                            CI_High(:,:,:,it) = (avGreenStack) + (ts_High*SEM);  % Confidence Intervals  
                        end    
                    elseif rightChan == 1 % BBB data is in red channel 
                        SEM = (nanstd(avRedStack,0,3))/(sqrt(size(avRedStack,3))); % Standard Error 
                        ts_High = tinv(0.975,size(avRedStack,3)-1);% T-Score for 95% CI
                        ts_Low =  tinv(0.025,size(avRedStack,3)-1);% T-Score for 95% CI
        %                         ts_High = tinv(0.995,size(avRedStack{terminals{mouse}(ccell)},3)-1);% T-Score for 99% CI
        %                         ts_Low =  tinv(0.005,size(avRedStack{terminals{mouse}(ccell)},3)-1);% T-Score for 99% CI
                        if HighLowQ == 0
                            CI_Low(:,:,:,it) = (avRedStack) + (ts_Low*SEM);   
                        elseif HighLowQ == 1 
                            CI_High(:,:,:,it) = (avRedStack) + (ts_High*SEM);  % Confidence Intervals  
                        end                        
                    end 
                end 
            end 
        elseif tTypeQ == 1
            per = input('Input lighting condition you care about. Blue = 1. Red = 2. Light off = 3. ');
            greenStackArray2 = cell(1,length(vidList{mouse}));
            redStackArray2 = cell(1,length(vidList{mouse}));
            avGreenStack2 = cell(1,length(sortedGreenStacks{1}));
            avRedStack2 = cell(1,length(sortedGreenStacks{1}));
            avGreenStack = cell(1,length(sortedGreenStacks{1}));
            avRedStack = cell(1,length(sortedGreenStacks{1}));
            for ccell = 1:length(terminals{mouse})
                for vid = 1:length(vidList{mouse})    
                    count = 1;
                    for peak = 1:size(sortedGreenStacks{vid}{terminals{mouse}(ccell)}{per},2)  
                        if isempty(sortedGreenStacks{vid}{terminals{mouse}(ccell)}{per}{peak}) == 0
                            greenStackArray2{vid}{terminals{mouse}(ccell)}(:,:,:,count) = sortedGreenStacks{vid}{terminals{mouse}(ccell)}{per}{peak};
                            redStackArray2{vid}{terminals{mouse}(ccell)}(:,:,:,count) = sortedRedStacks{vid}{terminals{mouse}(ccell)}{per}{peak};
                            count = count + 1;
                        end 
                    end
                    avGreenStack2{terminals{mouse}(ccell)}(:,:,:,vid) = nanmean(greenStackArray2{vid}{terminals{mouse}(ccell)},4);
                    avRedStack2{terminals{mouse}(ccell)}(:,:,:,vid) = nanmean(redStackArray2{vid}{terminals{mouse}(ccell)},4);
                end 
                avGreenStack{terminals{mouse}(ccell)} = nanmean(avGreenStack2{terminals{mouse}(ccell)},4);
                avRedStack{terminals{mouse}(ccell)} = nanmean(avRedStack2{terminals{mouse}(ccell)},4);
            end 
    %         clearvars sortedGreenStacks sortedRedStacks greenStackArray2 redStackArray2 avGreenStack2 avRedStack2
            clearvars greenStackArray2 redStackArray2 avGreenStack2 avRedStack2
        end 
    end 
    if spikeQ == 1
        for ccell = 1:length(terminals{mouse})
            if HighLowQ == 0         
                CIlowAv{terminals{mouse}(ccell)} = nanmean(CI_Low{terminals{mouse}(ccell)},4);
            elseif HighLowQ == 1
                CIhighAv{terminals{mouse}(ccell)} = nanmean(CI_High{terminals{mouse}(ccell)},4);
            end 
        end 
        if HighLowQ == 0         
            clearvars CI_Low
        elseif HighLowQ == 1
            clearvars CI_High
        end 
        CIdoneQ = input('Input 1 if you created and averaged the bootstrapped CI high and low bounds? ');
        if CIdoneQ == 1
            workFlow = 0;
            clearvars sortedGreenStacks sortedRedStacks 
        end 
    elseif spikeQ == 0
        workFlow = 0;
        clearvars sortedGreenStacks sortedRedStacks 
    end 
    toc
end 
% don't normalize because it's z-scored 
NgreenStackAv = avGreenStack;
NredStackAv = avRedStack; 
if spikeQ == 1 
    nCIhighAv = CIhighAv;
    nCIlowAv = CIlowAv;
    clearvars CIhighAv CIlowAv
end 
%{
% normalize to some baseline point 
changePt = floor(size(avGreenStack{terminals{mouse}(ccell)},3)/2)-2; 
normTime = input("How many seconds before the calcium peak do you want to baseline to? ");
BLstart = changePt - floor(normTime*FPSstack{mouse});
NgreenStackAv = cell(1,length(avGreenStack));
NredStackAv = cell(1,length(avGreenStack));
% normalize to baseline period 
for ccell = 1:length(terminals{mouse})
    NgreenStackAv{terminals{mouse}(ccell)} = ((avGreenStack{terminals{mouse}(ccell)}./ (nanmean(avGreenStack{terminals{mouse}(ccell)}(:,:,BLstart:changePt),3)))*100)-100;
    NredStackAv{terminals{mouse}(ccell)} = ((avRedStack{terminals{mouse}(ccell)}./ (nanmean(avRedStack{terminals{mouse}(ccell)}(:,:,BLstart:changePt),3)))*100)-100;
end 
%}
%select the correct channel for vessel segmentation  
if rightChan == 0     
    vesChan = VesAvGreenStack;
elseif rightChan == 1
    vesChan = VesAvRedStack;
end    
clearvars avGreenStack avRedStack VesAvGreenStack 
%temporal smoothing option
smoothQ = input('Input 0 if you do not want to do temporal smoothing. Input 1 otherwise. ');
if smoothQ == 0 
    SNgreenStackAv = NgreenStackAv;
    SNredStackAv = NredStackAv;
    if spikeQ == 1 
        snCIhighAv = nCIhighAv;
        snCIlowAv = nCIlowAv;
    end 
elseif smoothQ == 1
    filtTime = input('How many seconds do you want to smooth your data by? '); % our favorite STA trace is smoothed by 0.7 sec 
    filter_rate = FPSstack{mouse}*filtTime; 
    tempFiltChanQ= input('Input 0 to temporally smooth both channels. Input 1 otherwise. ');
    if tempFiltChanQ == 0
        SNredStackAv = cell(1,length(NgreenStackAv));
        SNgreenStackAv = cell(1,length(NgreenStackAv));
        for ccell = 1:length(terminals{mouse})
            SNredStackAv{terminals{mouse}(ccell)} = smoothdata(NredStackAv{terminals{mouse}(ccell)},3,'movmean',filter_rate);
            SNgreenStackAv{terminals{mouse}(ccell)} = smoothdata(NgreenStackAv{terminals{mouse}(ccell)},3,'movmean',filter_rate);
        end 
    elseif tempFiltChanQ == 1
        tempSmoothChanQ = input('Input 0 to temporally smooth green channel. Input 1 for red channel. ');
        if tempSmoothChanQ == 0
            SNredStackAv = NredStackAv;
            SNgreenStackAv = cell(1,length(NgreenStackAv));
            for ccell = 1:length(terminals{mouse})
                SNgreenStackAv{terminals{mouse}(ccell)} = smoothdata(NgreenStackAv{terminals{mouse}(ccell)},3,'movmean',filter_rate);
            end 
        elseif tempSmoothChanQ == 1
            SNredStackAv = cell(1,length(NgreenStackAv));
            SNgreenStackAv = NgreenStackAv;
            for ccell = 1:length(terminals{mouse})
                SNredStackAv{terminals{mouse}(ccell)} = smoothdata(NredStackAv{terminals{mouse}(ccell)},3,'movmean',filter_rate);               
            end 
        end 
    end 
    if spikeQ == 1 
        snCIhighAv = cell(1,max(terminals{mouse}));
        snCIlowAv = cell(1,max(terminals{mouse}));
        for ccell = 1:length(terminals{mouse})      
            snCIhighAv{terminals{mouse}(ccell)} = smoothdata(nCIhighAv{terminals{mouse}(ccell)},3,'movmean',filter_rate);
            snCIlowAv{terminals{mouse}(ccell)} = smoothdata(nCIlowAv{terminals{mouse}(ccell)},3,'movmean',filter_rate);
        end    
    end 
end 
clearvars NgreenStackAv NredStackAv 
if spikeQ == 1
    clearvars nCIhighAv nCIlowAv
end 
%spatial smoothing option
spatSmoothQ = input('Input 0 if you do not want to do spatial smoothing. Input 1 otherwise. ');
if spatSmoothQ == 1 
    spatSmoothTypeQ = input('Input 0 to do gaussian spatial smoothing. Input 1 to do convolution spatial smoothing (using NxN array of 0.125 values). ');
    spatFiltChanQ= input('Input 0 to spatially smooth both channels. Input 1 otherwise. ');
    if spatFiltChanQ == 0 % if you want to spatially smooth both channels 
        redIn = SNredStackAv; 
        greenIn = SNgreenStackAv;
        if spikeQ == 1 
            CIhighIn = snCIhighAv;
            CIlowIn = snCIlowAv;    
            clearvars snCIhighAv snCIlowAv
        end 
        clearvars SNredStackAv SNgreenStackAv       
        if spatSmoothTypeQ == 0 % if you want to use gaussian spatial smoothing 
            sigma = input('What sigma do you want to use for Gaussian spatial filtering? ');
            for ccell = 1:length(terminals{mouse})
                SNredStackAv{terminals{mouse}(ccell)} = imgaussfilt(redIn{terminals{mouse}(ccell)},sigma);
                SNgreenStackAv{terminals{mouse}(ccell)} = imgaussfilt(greenIn{terminals{mouse}(ccell)},sigma);
                if spikeQ == 1
                    snCIhighAv{terminals{mouse}(ccell)} = imgaussfilt(CIhighIn{terminals{mouse}(ccell)},sigma);
                    snCIlowAv{terminals{mouse}(ccell)} = imgaussfilt(CIlowIn{terminals{mouse}(ccell)},sigma);
                end 
            end 
        elseif spatSmoothTypeQ == 1 % if you want to use convolution smoothing 
            % create your kernal for smoothing by convolution 
            kernalSize = input('What size NxN array do you want to use for convolution spatial filtering? ');
            K = 0.125*ones(kernalSize);
            for ccell = 1:length(terminals{mouse})
                SNredStackAv{terminals{mouse}(ccell)} = convn(redIn{terminals{mouse}(ccell)},K,'same');
                SNgreenStackAv{terminals{mouse}(ccell)} = convn(greenIn{terminals{mouse}(ccell)},K,'same');
                if spikeQ == 1
                    snCIhighAv{terminals{mouse}(ccell)} = convn(CIhighIn{terminals{mouse}(ccell)},K,'same');
                    snCIlowAv{terminals{mouse}(ccell)} = convn(CIlowIn{terminals{mouse}(ccell)},K,'same');
                end 
            end 
        end 
    elseif spatFiltChanQ == 1 % if you only want to spatially smooth one channel 
        spatSmoothChanQ = input('Input 0 to spatially smooth the green channel. Input 1 for the red channel. ');
        if spatSmoothTypeQ == 0 % if you want to use gaussian spatial smoothing 
            sigma = input('What sigma do you want to use for Gaussian spatial filtering? ');
            if spatSmoothChanQ == 0 % if you want to spatially smooth the green channel 
                greenIn = SNgreenStackAv;
                clearvars SNgreenStackAv
                for ccell = 1:length(terminals{mouse})
                    SNgreenStackAv{terminals{mouse}(ccell)} = imgaussfilt(greenIn{terminals{mouse}(ccell)},sigma);
                    if spikeQ == 1 
                        snCIhighAv{terminals{mouse}(ccell)} = imgaussfilt(CIhighIn{terminals{mouse}(ccell)},sigma);
                        snCIlowAv{terminals{mouse}(ccell)} = imgaussfilt(CIlowIn{terminals{mouse}(ccell)},sigma);
                    end 
                end              
            elseif spatSmoothChanQ == 1 % if you want to spatially smooth the red channel 
                redIn = SNredStackAv; 
                clearvars SNredStackAv 
                for ccell = 1:length(terminals{mouse})
                    SNredStackAv{terminals{mouse}(ccell)} = imgaussfilt(redIn{terminals{mouse}(ccell)},sigma);
                    if spikeQ == 1 
                        snCIhighAv{terminals{mouse}(ccell)} = imgaussfilt(CIhighIn{terminals{mouse}(ccell)},sigma);
                        snCIlowAv{terminals{mouse}(ccell)} = imgaussfilt(CIlowIn{terminals{mouse}(ccell)},sigma);
                    end                     
                end 
            end        
        elseif spatSmoothTypeQ == 1 % if you want to use convolution smoothing 
            % create your kernal for smoothing by convolution 
            kernalSize = input('What size NxN array do you want to use for convolution spatial filtering? ');
            K = 0.125*ones(kernalSize);
            if spatSmoothChanQ == 0 % if you want to spatially smooth the green channel 
                greenIn = SNgreenStackAv;
                clearvars SNgreenStackAv
                for ccell = 1:length(terminals{mouse})
                    SNgreenStackAv{terminals{mouse}(ccell)} = convn(greenIn{terminals{mouse}(ccell)},K,'same');
                    if spikeQ == 1 
                        snCIhighAv{terminals{mouse}(ccell)} = convn(CIhighIn{terminals{mouse}(ccell)},K,'same');
                        snCIlowAv{terminals{mouse}(ccell)} = convn(CIlowIn{terminals{mouse}(ccell)},K,'same');
                    end 
                end 
            elseif spatSmoothChanQ == 1 % if you want to spatially smooth the red channel 
                redIn = SNredStackAv; 
                clearvars SNredStackAv 
                for ccell = 1:length(terminals{mouse})
                    SNredStackAv{terminals{mouse}(ccell)} = convn(redIn{terminals{mouse}(ccell)},K,'same');
                    if spikeQ == 1 
                        snCIhighAv{terminals{mouse}(ccell)} = convn(CIhighIn{terminals{mouse}(ccell)},K,'same');
                        snCIlowAv{terminals{mouse}(ccell)} = convn(CIlowIn{terminals{mouse}(ccell)},K,'same');
                    end                     
                end 
            end                          
        end 
    end 
end 
clearvars redIn greenIn 
if spikeQ == 1 
    clearvars CIhighIn CIlowIn
end 
% black out the pixels that are part of calcium ROIs 
blackOutCaROIQ = input('Input 1 if you want to black out pixels in Ca ROIs. Input 0 otherwise. ');
if blackOutCaROIQ == 1         
    CaROImaskDir = uigetdir('*.*','WHERE ARE THE CA ROI COORDINATES?');
    cd(CaROImaskDir);
    CaROImaskFileName = uigetfile('*.*','GET THE CA ROI COORDINATES'); 
    CaROImaskMat = matfile(CaROImaskFileName); 
    CaROImasks = CaROImaskMat.CaROImasks; 
    % check to see if ROIorders exists in the matfile 
    variableInfo = who(CaROImaskMat);
    if ismember("ROIorders", variableInfo) == 1 % returns true 
        ROIorders = CaROImaskMat.ROIorders;                
    end   
    % crop if necessary 
    if cropQ == 1 
        if ismember("ROIorders", variableInfo) == 1 % returns true 
            ROIorders2 = cell(1,length(ROIorders));
            for z = 1:length(ROIorders)
                cropdIm = imcrop(ROIorders{z},rect);
                ROIorders2{z} = cropdIm;
            end     
        end 
        CaROImasks2 = cell(1,length(CaROImasks));
        for z = 1:length(CaROImasks)
            cropdIm = imcrop(CaROImasks{z},rect);
            CaROImasks2{z} = cropdIm;
        end              
        clearvars CaROImasks; CaROImasks = CaROImasks2; clearvars CaROImasks2 
        if ismember("ROIorders", variableInfo) == 1 % returns true 
            clearvars ROIorders; ROIorders = ROIorders2; clearvars ROIorders2
        end 
    end 
    % combine Ca ROIs from different planes in Z into one plane 
    if ismember("ROIorders", variableInfo) == 1 % returns true
        numZplanes = length(ROIorders);
    elseif ismember("ROIorders", variableInfo) == 0
        numZplanes = length(CaROImasks);
    end 
    if numZplanes > 1 
        combo = cell(1,numZplanes-1);
        combo2 = cell(1,numZplanes-1);
        for it = 1:numZplanes-1
            if it == 1 
                combo{it} = or(CaROImasks{1},CaROImasks{2});
                if ismember("ROIorders", variableInfo) == 1 % returns true
                    combo2{it} = or(ROIorders{1},ROIorders{2});
                end 
            elseif it > 1
                combo{it} = or(combo{it-1},CaROImasks{it+1});
                if ismember("ROIorders", variableInfo) == 1 % returns true
                    combo2{it} = or(combo2{it-1},ROIorders{it+1});
                end 
            end 
        end      
        ROIorders = combo2;
    elseif numZplanes == 1 
        combo = CaROImasks;       
    end        
    %make your combined Ca ROI mask the right size for applying to a 3D
    %arrray 
    ind = length(combo); combo1 = combo{ind};
    % downsample the Ca ROI mask if necessary 
    if exist("downsampleRate", 'var') == 1
        dwnC = downsample(combo1,downsampleRate);
        dwnC = permute(dwnC,[2 1 3]);
        dwnC = downsample(dwnC,downsampleRate);
        dwnC = permute(dwnC,[2 1 3]);  
        combo1 = dwnC; 
        clearvars dwnC 
    end 
    ThreeDCaMask = logical(repmat(combo1,1,1,size(SNredStackAv{terminals{mouse}(ccell)},3)));
    %apply new mask to the right channel 
    % this is defined above: rightChan = input('Input 0 if BBB data is in the green chanel. Input 1 if BBB data is in the red channel. ');
    if rightChan == 0     
        RightChan = SNgreenStackAv;
        otherChan = SNredStackAv;
    elseif rightChan == 1
        RightChan = SNredStackAv;
        otherChan = SNgreenStackAv;
    end     
    for ccell = 1:length(terminals{mouse})
        RightChan{terminals{mouse}(ccell)}(ThreeDCaMask) = 0;        
    end 
elseif blackOutCaROIQ == 0          
    if rightChan == 0     
        RightChan = SNgreenStackAv;
        otherChan = SNredStackAv;
    elseif rightChan == 1
        RightChan = SNredStackAv;
        otherChan = SNgreenStackAv;
    end   
end 
clearvars SNgreenStackAv SNredStackAv
AVQ = input('Input 1 to average STA videos. Input 0 otherwise. ');
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
if AVQ == 0 
    segQ = input('Input 1 if you need to create a new vessel segmentation algorithm. ');
    % create outline of vessel to overlay the %change BBB perm stack 
    segmentVessel = 1;
    while segmentVessel == 1 
        % apply Ca ROI mask to the appropriate channel to black out these
        % pixels 
        for ccell = 1:length(terminals{mouse})
            vesChan{terminals{mouse}(ccell)}(ThreeDCaMask) = 0;
        end 
        %segment the vessel (small sample of the data) 
        if segQ == 1 
            CaROI = input('What Ca ROI do you want to use to create the segmentation algorithm? ');    
            imageSegmenter(mean(vesChan{CaROI},3))
            continu = input('Is the image segmenter closed? Yes = 1. No = 0. ');
        elseif segQ == 0 
            continu = 1;
        end   
        while continu == 1 
            BWstacks = cell(1,length(vesChan));
            BW_perim = cell(1,length(vesChan));
            segOverlays = cell(1,length(vesChan));    
            for ccell = 1:length(terminals{mouse})
                for frame = 1:size(vesChan{terminals{mouse}(ccell)},3)
                    [BW,~] = segmentImage112_STAvid_20230706zScored(vesChan{terminals{mouse}(ccell)}(:,:,frame));
                    BWstacks{terminals{mouse}(ccell)}(:,:,frame) = BW; 
                    %get the segmentation boundaries 
                    BW_perim{terminals{mouse}(ccell)}(:,:,frame) = bwperim(BW);
                    %overlay segmentation boundaries on data
                    segOverlays{terminals{mouse}(ccell)}(:,:,:,frame) = imoverlay(mat2gray(vesChan{terminals{mouse}(ccell)}(:,:,frame)), BW_perim{terminals{mouse}(ccell)}(:,:,frame), [.3 1 .3]);   
                end   
            end 
            continu = 0;
        end 

        %ask about segmentation quality 
        if segQ == 1
            %play segmentation boundaries over images 
            implay(segOverlays{CaROI})
            segmentVessel = input("Does the vessel need to be segmented again? Yes = 1. No = 0. ");
            if segmentVessel == 1
                clearvars BWthreshold BWopenRadius BW se boundaries
            end 
        elseif segQ == 0 
            segmentVessel = 0;
        end 
    end
end
clearvars segOverlays 
cMapQ = input('Input 0 to create a color map that is red for positive % change and green for negative % change. Input 1 to create a colormap for only positive going values. ');
if cMapQ == 0
    % Create colormap that is green for positive, red for negative,
    % and a chunk inthe middle that is black.
%     greenColorMap = [zeros(1, 156), linspace(0, 1, 100)];
%     redColorMap = [linspace(1, 0, 100), zeros(1, 156)];
    % these are the original colors 
    greenColorMap = [zeros(1, 132), linspace(0, 1, 124)];
    redColorMap = [linspace(1, 0, 124), zeros(1, 132)];
    cMap = [redColorMap; greenColorMap; zeros(1, 256)]';
elseif cMapQ == 1
    % Create colormap that is green at max and black at min
    % this is the original green colorbar 
%     greenColorMap = linspace(0, 1, 256);
    % green colorbar with less green
    greenColorMap = [zeros(1, 60), linspace(0, 1, 196)];
%     % steeper green colorbar (SF-57)
%     greenColorMap = [zeros(1, 60), linspace(0, 1, 100),ones(1,96)];
    cMap = [zeros(1, 256); greenColorMap; zeros(1, 256)]';

%     % steeper green colorbar (SF-56)
%     greenColorMap = [linspace(0, 1, 110),ones(1,146)];
%     cMap = [zeros(1, 256); greenColorMap; zeros(1, 256)]';    
end 
% save the other channel first to ensure that all Ca ROIs show an average
%peak in the same frame 
dir1 = uigetdir('*.*','WHERE DO YOU WANT TO SAVE THE IMAGES?'); % get the directory where you want to save your images 
dir2 = strrep(dir1,'\','/'); % change the direction of the slashes 
CaROItimingCheckQ = input('Do you need to save the Ca data? Input 1 for yes. 0 for no. ');
if CaROItimingCheckQ == 1 
    for ccell = 1:length(terminals{mouse})
        %create a new folder per calcium ROI 
        newFolder = sprintf('CaROI_%d_calciumSignal',terminals{mouse}(ccell));
        mkdir(dir2,newFolder)
         for frame = 1:size(vesChan{terminals{mouse}(ccell)},3)    
            figure('Visible','off');     
            % the color lims below work great for 56 and 57, but not 58
            %imagesc(otherChan{terminals{mouse}(ccell)}(:,:,frame),[3,5]) 
            imagesc(otherChan{terminals{mouse}(ccell)}(:,:,frame))
            %save current figure to file 
            filename = sprintf('%s/CaROI_%d_calciumSignal/CaROI_%d_frame%d',dir2,terminals{mouse}(ccell),terminals{mouse}(ccell),frame);
            saveas(gca,[filename '.png'])
         end 
    end 
end 

% create a binarized version of the STA vids
% 1 means greater than 95% CI and 2 means lower than 95% CI 
if spikeQ == 1 
    clearvars RightChan
    dataDir = uigetdir('*.*','WHERE IS THE NON-SHUFFLED STA VIDEO .MAT FILE?');
    cd(dataDir);
    nonShuffledFileName = uigetfile('*.*','GET THE NON-SHUFFLED STA VIDEO .MAT FILE'); 
    nonShuffledMat = matfile(nonShuffledFileName);
    RightChan = nonShuffledMat.RightChan;
    % create binary STA vid 
    binarySTAhigh = cell(1,max(terminals{mouse}));
    binarySTAlow = cell(1,max(terminals{mouse}));
    binarySTA = cell(1,max(terminals{mouse}));
    for ccell = 1:length(terminals{mouse}) 
        binarySTAhigh{terminals{mouse}(ccell)} = RightChan{terminals{mouse}(ccell)} > snCIhighAv{terminals{mouse}(ccell)}; 
        binarySTAlow{terminals{mouse}(ccell)} = RightChan{terminals{mouse}(ccell)} < snCIlowAv{terminals{mouse}(ccell)}; 
        data = single(binarySTAhigh{terminals{mouse}(ccell)});
        binarySTA{terminals{mouse}(ccell)} = data;
        binarySTA{terminals{mouse}(ccell)}(binarySTAlow{terminals{mouse}(ccell)}) = 2;
    end 
    clearvars binarySTAhigh binarySTAlow
end 

%% conditional statement that ensures you checked the other channel

% to make sure Ca ROIs show an average peak in the same frame, before
% moving onto the next step 
CaFrameQ = input('Input 1 if you if you checked to make sure averaged Ca events happened in the same frame per ROI. And the anatomy is correct. ');
vesBlackQ = input('Input 1 to black out vessel. '); 
if spikeQ ==0 
    ims = RightChan;
elseif spikeQ == 1 
    ims = snCIhighAv;
end 
if CaFrameQ == 1 
    CaEventFrame = input('What frame did the Ca events happen in? ');
    if AVQ == 0  
        %overlay vessel outline and GCaMP activity of the specific Ca ROI on top of %change images, black out pixels where
        %the vessel is (because they're distracting), and save these images to a
        %folder of your choosing (there will be subFolders per calcium ROI)
        BBBtraceQ = input("Input 1 if you want to plot BBB STA traces.");
        if BBBtraceQ == 1 
            CTraces = cell(1,mouseNum); 
            CI_cLow = cell(1,mouseNum);
            CI_cHigh = cell(1,mouseNum);
            CTraceArray = cell(1,mouseNum);
            AVSNCdataPeaks = cell(1,mouseNum);
            SCdataPeaks = cell(1,mouseNum);
            SNCdataPeaks = cell(1,mouseNum);
            sortedCdata2 = cell(1,mouseNum);
            allCTraces3 = cell(1,mouseNum);  
            sortedCdata = cell(1,mouseNum);
            BBBdata = cell(1,mouseNum);
        end 
        for ccell = 1:length(terminals{mouse})  
            if ccell == 1
                genImQ = input("Input 1 if you need to generate the images. ");
            end             
            if genImQ == 1 
                %black out pixels that belong to vessels   
                if vesBlackQ == 1 
                    ims{terminals{mouse}(ccell)}(BWstacks{terminals{mouse}(ccell)}) = 0; 
                end                            
                %find the upper and lower bounds of your data (per calcium ROI) 
                maxValue = max(max(max(max(ims{terminals{mouse}(ccell)}))));
                minValue = min(min(min(min(ims{terminals{mouse}(ccell)}))));
                minMaxAbsVals = [abs(minValue),abs(maxValue)];
                maxAbVal = max(minMaxAbsVals);
                % ask user where to crop image
                if ccell == 1   
                    if BBBtraceQ == 1 
                        BBBtraceNumQ = input("How manny BBB traces do you want to generate? ");
                    end                 
                end            
                %create a new folder per calcium ROI 
                newFolder = sprintf('CaROI_%d_BBBsignal',terminals{mouse}(ccell));
                mkdir(dir2,newFolder)
                %overlay segmentation boundaries on the % change image stack and save
                %images
                for frame = 1:size(vesChan{terminals{mouse}(ccell)},3)   
                    % get the x-y coordinates of the Ca ROI         
                    clearvars CAy CAx
                    if ismember("ROIorders", variableInfo) == 1 % returns true
                        [CAyf, CAxf] = find(ROIorders{1} == terminals{mouse}(ccell));  % x and y are column vectors.
                    elseif ismember("ROIorders", variableInfo) == 0 % returns true
                        [CAyf, CAxf] = find(CaROImasks{1} == terminals{mouse}(ccell));  % x and y are column vectors.
                    end 
                    figure('Visible','off');  
                    if BBBtraceQ == 1
                        if ccell == 1 
                            if frame == 1
                                ROIboundDatas = cell(1,BBBtraceNumQ);
                                ROIstacks = cell(1,length(terminals{mouse}));
                                for BBBroi = 1:BBBtraceNumQ
                                    % create BBB ROIs 
                                    disp('Create your ROI for BBB perm analysis');
                                    [~,xmins,ymins,widths,heights] = firstTimeCreateROIs(1,ims{terminals{mouse}(ccell)}(:,:,frame));
                                    ROIboundData{1} = xmins;
                                    ROIboundData{2} = ymins;
                                    ROIboundData{3} = widths;
                                    ROIboundData{4} = heights;
                                    ROIboundDatas{BBBroi} = ROIboundData;                          
                                end 
                            end 
                        end 
                        for BBBroi = 1:BBBtraceNumQ
                            %use the ROI boundaries to generate ROIstacks 
                            xmins = ROIboundDatas{BBBroi}{1};
                            ymins = ROIboundDatas{BBBroi}{2};
                            widths = ROIboundDatas{BBBroi}{3};
                            heights = ROIboundDatas{BBBroi}{4};
                            [ROI_stacks] = make_ROIs_notfirst_time(ims{terminals{mouse}(ccell)}(:,:,frame),xmins,ymins,widths,heights);
                            ROIstacks{terminals{mouse}(ccell)}{BBBroi}(:,:,frame) = ROI_stacks{1};
                        end 
                    end 
                    % create the % change image with the right white and black point
                    % boundaries and colormap 
                    if cMapQ == 0
                        imagesc(ims{terminals{mouse}(ccell)}(:,:,frame),[-maxAbVal,maxAbVal]); colormap(cMap); colorbar%this makes the max point 1% and the min point -1% 
                    elseif cMapQ == 1 
                        imagesc(ims{terminals{mouse}(ccell)}(:,:,frame),[0,maxAbVal/3]); colormap(cMap); colorbar%this makes the max point 1% and the min point -1% 
                    end                                    
                    % get the x-y coordinates of the vessel outline
                    [yf, xf] = find(BW_perim{terminals{mouse}(ccell)}(:,:,frame));  % x and y are column vectors.                                         
                    % plot the vessel outline over the % change image 
                    hold on;
                    scatter(xf,yf,'white','.');
                    if cropQ == 1
                        axonPixSize = 500;
                    elseif cropQ == 0
                        axonPixSize = 100;
                    end 
                    scatter(CAxf,CAyf,axonPixSize,[0.5 0.5 0.5],'filled','square');
                    % plot the GCaMP signal marker in the right frame 
                    if frame == CaEventFrame || frame == (CaEventFrame-1) || frame == (CaEventFrame+1)
                        hold on;
                        scatter(CAxf,CAyf,axonPixSize,[0 0 1],'filled','square');
                        %get border coordinates 
                        colLen = size(ims{terminals{mouse}(ccell)},2);
                        rowLen = size(ims{terminals{mouse}(ccell)},1);
                        edg1_x = repelem(1,rowLen);
                        edg1_y = 1:rowLen;
                        edg2_x = repelem(colLen,rowLen);
                        edg2_y = 1:rowLen;
                        edg3_x = 1:colLen;
                        edg3_y = repelem(1,colLen);
                        edg4_x = 1:colLen;
                        edg4_y = repelem(rowLen,colLen);
                        edg_x = [edg1_x,edg2_x,edg3_x,edg4_x];
                        edg_y = [edg1_y,edg2_y,edg3_y,edg4_y];
                        hold on;
                        if cropQ == 1 
                            scatter(edg_x,edg_y,100,'blue','filled','square');    
                        end 
                    end 
                    ax = gca;
                    ax.Visible = 'off';
                    ax.FontSize = 20;
                    %save current figure to file 
                    filename = sprintf('%s/CaROI_%d_BBBsignal/CaROI_%d_frame%d',dir2,terminals{mouse}(ccell),terminals{mouse}(ccell),frame);
                    saveas(gca,[filename '.png'])
                end 
            end            
            % Plot BBB STA trace per axon and BBB roi 
            if BBBtraceQ == 1 
                regImDir = uigetdir('*.*',sprintf('WHERE IS THE STA DATA FOR MOUSE #%d?',mouse));
                cd(regImDir);
                MatFileName = uigetfile('*.*',sprintf('SELECT THE STA DATA FOR MOUSE #%d',mouse));
                Mat = matfile(MatFileName);                  
                sortedCdata{mouse} = Mat.sortedCdata;               
                % sort data         
                baselineTime = normTime;
                %smoothing option               
                if smoothQ == 0 
                    SCdataPeaks{mouse} = sortedCdata{mouse};
                elseif smoothQ == 1           
                    SCdataPeaks{mouse} = sortedCdata{mouse};
                    for vid = 1:length(vidList{mouse})                    
                       if vid <= length(sortedCdata{mouse}) 
                            for per = 1:length(sortedCdata{mouse}{vid}{terminals{mouse}(ccell)}) 
                                if isempty(sortedCdata{mouse}{vid}{terminals{mouse}(ccell)}{per}) == 0 
                                    %remove rows full of 0s if there are any b = a(any(a,2),:)
                                    SCdataPeaks{mouse}{vid}{terminals{mouse}(ccell)}{per} = SCdataPeaks{mouse}{vid}{terminals{mouse}(ccell)}{per}(any(SCdataPeaks{mouse}{vid}{terminals{mouse}(ccell)}{per},2),:);                 
                                end 
                            end
                       end                         
                    end 
                end     
                %normalize
                 for vid = 1:length(vidList{mouse})
                    if vid <= length(sortedCdata{mouse}) 
                        for per = 1:length(sortedCdata{mouse}{vid}{terminals{mouse}(ccell)})
                            if isempty(sortedCdata{mouse}{vid}{terminals{mouse}(ccell)}{per}) == 0 
                                %the data needs to be added to because there are some
                                %negative gonig points which mess up the normalizing 
                                % determine the minimum value, add space (+100)
                                minValToAdd = abs(ceil(min(min(SCdataPeaks{mouse}{vid}{terminals{mouse}(ccell)}{per}))))+100;
                                % add min value
                                sortedCdata2{mouse}{vid}{terminals{mouse}(ccell)}{per} = SCdataPeaks{mouse}{vid}{terminals{mouse}(ccell)}{per} + minValToAdd;
                                %normalize to baselineTime sec before changePt (calcium peak
                                %onset) BLstart 
                                if isempty(sortedCdata{mouse}{1}{terminals{mouse}(1)}) == 0
                                    if isempty(sortedCdata{mouse}{1}{terminals{mouse}(1)}{1}) == 0
                                        changePt = floor(size(sortedCdata{mouse}{1}{terminals{mouse}(1)}{1},2)/2)-4;
                                    elseif isempty(sortedCdata{mouse}{1}{terminals{mouse}(1)}{1}) == 1 && isempty(sortedCdata{mouse}{1}{terminals{mouse}(1)}{2}) == 0
                                        changePt = floor(size(sortedCdata{mouse}{1}{terminals{mouse}(1)}{2},2)/2)-4;
                                    end   
                                elseif isempty(sortedCdata{mouse}{1}{terminals{mouse}(2)}) == 0
                                    if isempty(sortedCdata{mouse}{1}{terminals{mouse}(2)}{1}) == 0
                                        changePt = floor(size(sortedCdata{mouse}{1}{terminals{mouse}(2)}{1},2)/2)-4;
                                    elseif isempty(sortedCdata{mouse}{1}{terminals{mouse}(2)}{1}) == 1 && isempty(sortedCdata{mouse}{1}{terminals{mouse}(2)}{2}) == 0
                                        changePt = floor(size(sortedCdata{mouse}{1}{terminals{mouse}(2)}{2},2)/2)-4;
                                    end  
                                elseif isempty(sortedCdata{mouse}{1}{terminals{mouse}(3)}) == 0
                                    if isempty(sortedCdata{mouse}{1}{terminals{mouse}(3)}{1}) == 0
                                        changePt = floor(size(sortedCdata{mouse}{1}{terminals{mouse}(3)}{1},2)/2)-4;
                                    elseif isempty(sortedCdata{mouse}{1}{terminals{mouse}(3)}{1}) == 1 && isempty(sortedCdata{mouse}{1}{terminals{mouse}(3)}{2}) == 0
                                        changePt = floor(size(sortedCdata{mouse}{1}{terminals{mouse}(3)}{2},2)/2)-4;
                                    end   
                                end 

                                if isempty(sortedCdata{mouse}{1}{terminals{mouse}(3)}{1}) == 0
                                    changePt = floor(size(sortedCdata{mouse}{1}{terminals{mouse}(3)}{1},2)/2)-4;
                                elseif isempty(sortedCdata{mouse}{1}{terminals{mouse}(3)}{1}) == 1 && isempty(sortedCdata{mouse}{1}{terminals{mouse}(3)}{2}) == 0
                                    changePt = floor(size(sortedCdata{mouse}{1}{terminals{mouse}(3)}{2},2)/2)-4;
                                end   
                %                 BLstart = changePt - floor(0.5*FPSstack{mouse});
                                BLstart = changePt - floor(baselineTime*FPSstack{mouse});

                                if isempty(sortedCdata2{mouse}{vid}{terminals{mouse}(ccell)}{per}) == 0 
                                    SNCdataPeaks{mouse}{vid}{terminals{mouse}(ccell)}{per} = ((sortedCdata2{mouse}{vid}{terminals{mouse}(ccell)}{per})./(nanmean(sortedCdata2{mouse}{vid}{terminals{mouse}(ccell)}{per}(:,BLstart:changePt),2)))*100;
                                end 
                            end               
                        end
                    end                   
                 end     
                count = 1;
                for vid = 1:length(vidList{mouse})  
                    if vid <= length(sortedCdata{mouse}) 
                        for per = 1:length(sortedCdata{mouse}{vid}{terminals{mouse}(ccell)})
                            if isempty(SCdataPeaks{mouse}{vid}{terminals{mouse}(ccell)}) == 0 %{mouse}{vid}{terminals{mouse}(ccell)}{per}
                                if isempty(SCdataPeaks{mouse}{vid}{terminals{mouse}(ccell)}{per}) == 0 
                                    for peak = 1:size(SNCdataPeaks{mouse}{vid}{terminals{mouse}(ccell)}{per},1) 
                                        allCTraces3{mouse}{terminals{mouse}(ccell)}{per}(count,:) = (SNCdataPeaks{mouse}{vid}{terminals{mouse}(ccell)}{per}(peak,:)-100);
                                        %remove rows full of 0s if there are any b = a(any(a,2),:)
                                        allCTraces3{mouse}{terminals{mouse}(ccell)}{per} = allCTraces3{mouse}{terminals{mouse}(ccell)}{per}(any(allCTraces3{mouse}{terminals{mouse}(ccell)}{per},2),:);
                                        count = count + 1;
                                    end 
                                end 
                            end                            
                        end 
                    end 
                end           
                %put all similar trials together 
                allCTraces = allCTraces3;
                CaROIs = terminals;
                CTraces{mouse} = allCTraces{mouse}(CaROIs{mouse});                                      
                %remove empty cells if there are any b = a(any(a,2),:)
                CTraces{mouse} = CTraces{mouse}(~cellfun('isempty',CTraces{mouse}));                               
                % create colors for plotting 
                Bcolors = [1,0,0;1,0.5,0;1,1,0];
                Ccolors = [0,0,1;0,0.5,1;0,1,1];
                % resort data: concatenate all CaROI data 
                % output = CaArray{mouse}{per}(concatenated caRoi data)
                % output = VW/BBBarray{mouse}{BBB/VWroi}{per}(concatenated caRoi data)     
                CTraceArray = cell(1,1);
                for per = 1:length(allCTraces3{mouse}{CaROIs{mouse}(1)})
                    if isempty(allCTraces3{mouse}{CaROIs{mouse}(1)}{per}) == 0                                                                                               
                        if isempty(CTraces{mouse}{ccell}) == 0 
                            if ccell == 1 
                                CTraceArray{mouse}{per} = CTraces{mouse}{ccell}{per};                              
                            elseif ccell > 1 
                                CTraceArray{mouse}{per} = vertcat(CTraceArray{mouse}{per},CTraces{mouse}{ccell}{per});                             
                            end
                        end 
                     
                        %DETERMINE 95% CI                       
                        SEMc = (nanstd(CTraceArray{mouse}{per}))/(sqrt(size(CTraceArray{mouse}{per},1))); %#ok<*NANSTD> % Standard Error            
                        ts_cLow = tinv(0.025,size(CTraceArray{mouse}{per},1)-1);% T-Score for 95% CI
                        ts_cHigh = tinv(0.975,size(CTraceArray{mouse}{per},1)-1);% T-Score for 95% CI
                        CI_cLow{mouse}{per} = (nanmean(CTraceArray{mouse}{per},1)) + (ts_cLow*SEMc);  % Confidence Intervals
                        CI_cHigh{mouse}{per} = (nanmean(CTraceArray{mouse}{per},1)) + (ts_cHigh*SEMc);  % Confidence Intervals 
                        
                        %get averages
                        AVSNCdataPeaks{mouse}{per} = nanmean(CTraceArray{mouse}{per},1);                    

                        % plot data                                                                           
                        for BBBroi = 1:BBBtraceNumQ
                            %determine range of data Ca data
                            CaDataRange = max(AVSNCdataPeaks{mouse}{per})-min(AVSNCdataPeaks{mouse}{per});
                            %determine plotting buffer space for Ca data 
                            CaBufferSpace = CaDataRange;
                            %determine first set of plotting min and max values for Ca data
                            CaPlotMin = min(AVSNCdataPeaks{mouse}{per})-CaBufferSpace;
                            CaPlotMax = max(AVSNCdataPeaks{mouse}{per})+CaBufferSpace; 
                            %determine Ca 0 ratio/location 
                            CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);
                                                       
                            %determine range of BBB data 
                            BBBdataRange = max(max(max(ROIstacks{terminals{mouse}(ccell)}{BBBroi})))-min(min(min(ROIstacks{terminals{mouse}(ccell)}{BBBroi})));                                       
                            %determine plotting buffer space for BBB data 
                            BBBbufferSpace = BBBdataRange;
                            %determine first set of plotting min and max values for BBB data
                            BBBplotMin = min(min(min(ROIstacks{terminals{mouse}(ccell)}{BBBroi})))-BBBbufferSpace;
                            BBBplotMax = max(max(max(ROIstacks{terminals{mouse}(ccell)}{BBBroi})))+BBBbufferSpace;
                            %determine BBB 0 ratio/location
                            BBBzeroRatio = abs(BBBplotMin)/(BBBplotMax-BBBplotMin);
                            %determine how much to shift the BBB axis so that the zeros align 
                            BBBbelowZero = (BBBplotMax-BBBplotMin)*CaZeroRatio;
                            BBBaboveZero = (BBBplotMax-BBBplotMin)-BBBbelowZero;
                            % replace zeros with NaNs 
                            ROIstacks{terminals{mouse}(ccell)}{BBBroi}(ROIstacks{terminals{mouse}(ccell)}{BBBroi}==0) = NaN;
                            for frame = 1:size(ROIstacks{terminals{mouse}(ccell)}{BBBroi},3)                                
                                % convert BBB ROI frames to TS values
                                BBBdata{terminals{mouse}(ccell)}{BBBroi}(frame) = nanmean(nanmean(ROIstacks{terminals{mouse}(ccell)}{BBBroi}(:,:,frame)));
                            end 
                            x = 1:length(BBBdata{terminals{mouse}(ccell)}{1});
%                             %DETERMINE 95% CI                       
%                             SEMb = (nanstd(BBBdata{terminals{mouse}(ccell)}{BBBroi}))/(sqrt(size(BBBdata{terminals{mouse}(ccell)}{BBBroi},1))); % Standard Error            
%                             ts_bLow = tinv(0.025,size(BBBdata{terminals{mouse}(ccell)}{BBBroi},1)-1);% T-Score for 95% CI
%                             ts_bHigh = tinv(0.975,size(BBBdata{terminals{mouse}(ccell)}{BBBroi},1)-1);% T-Score for 95% CI
%                             CI_bLow{mouse}{per} = (nanmean(BBBdata{terminals{mouse}(ccell)}{BBBroi},1)) + (ts_bLow*SEMb);  % Confidence Intervals
%                             CI_bHigh{mouse}{per} = (nanmean(BBBdata{terminals{mouse}(ccell)}{BBBroi},1)) + (ts_bHigh*SEMb);  % Confidence Intervals 
%                             %get average
%                             AVSNCdataPeaks{mouse}{per} = nanmean(CTraceArray{mouse}{per},1);  
                                                       
                            fig = figure;
                            Frames = size(x,2);
                            Frames_pre_stim_start = -((Frames-1)/2); 
                            Frames_post_stim_start = (Frames-1)/2; 
                            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
                            FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
                            ax=gca;
                            hold all
                            Cdata = AVSNCdataPeaks{mouse}{per}(100:152);
                            plot(Cdata,'blue','LineWidth',4)
                            CdataCIlow = CI_cLow{mouse}{per}(100:152);
                            CdataCIhigh = CI_cHigh{mouse}{per}(100:152);
                            patch([x fliplr(x)],[CdataCIlow fliplr(CdataCIhigh)],Ccolors(1,:),'EdgeColor','none')
                            changePt = floor(Frames/2)-floor(0.25*FPSstack{mouse});
                            ax.XTick = FrameVals;
                            ax.XTickLabel = sec_TimeVals;   
                            ax.FontSize = 25;
                            ax.FontName = 'Times';
                            xlabel('time (s)','FontName','Times')
                            ylabel('calcium signal percent change','FontName','Times')
                            xLimStart = floor(10*FPSstack{mouse});
                            xLimEnd = floor(24*FPSstack{mouse}); 
%                             xlim([1 size(AVSNCdataPeaks{mouse}{per},2)])
                            ylim([min(AVSNCdataPeaks{mouse}{per}-CaBufferSpace) max(AVSNCdataPeaks{mouse}{per}+CaBufferSpace)])
                            set(fig,'position', [500 100 900 800])
                            alpha(0.3)
                            %add right y axis tick marks for a specific DOD figure. 
                            yyaxis right 
                            p(1) = plot(BBBdata{terminals{mouse}(ccell)}{BBBroi},'green','LineWidth',4);
%                             patch([x fliplr(x)],[(close_CI_bLow{mouse}{BBBroi}{per}) (fliplr(close_CI_bHigh{mouse}{BBBroi}{per}))],Bcolors(1,:),'EdgeColor','none')
                            ylabel('BBB permeability percent change','FontName','Times')
                            title(sprintf('Close Terminals. Mouse %d. BBB ROI %d.',mouse,BBBroi))
                            alpha(0.3)
%                             legend([p(1) p(2)],'Close Terminals','Far Terminals')
                            set(gca,'YColor',[0 0 0]);   
                            ylim([-BBBbelowZero BBBaboveZero])
                        end                                       
                    end 
                end                
            end 
        end
        if BBBtraceQ == 1 
            clearvars sortedCdata SCdataPeaks SNCdataPeaks sortedCdata2 allCTraces3 CTraces CI_cLow CI_cHigh CTraceArray AVSNCdataPeaks BBBdata
        end 
    elseif AVQ == 1
        termsToAv = input('Input what terminal STA videos you want to average. '); 
        STAterms = zeros(size(ims{termsToAv(1)},1),size(ims{termsToAv(1)},2),size(ims{termsToAv(1)},3),length(termsToAv));
        STAtermsVesChans = zeros(size(ims{termsToAv(1)},1),size(ims{termsToAv(1)},2),size(ims{termsToAv(1)},3),length(termsToAv));        
        for termToAv = 1:length(termsToAv)
            %create 4D array containing all relevant terminals 
            STAterms(:,:,:,termToAv) = ims{termsToAv(termToAv)};
            STAtermsVesChans(:,:,:,termToAv) = vesChan{termsToAv(termToAv)};
        end 
        % average terminals of your choosing 
        STAav = mean(STAterms,4);
        STAavVesVid = mean(STAtermsVesChans,4);
        
        clearvars BW BWstacks BW_perim segOverlays
        BWstacks = zeros(size(ims{termsToAv(1)},1),size(ims{termsToAv(1)},2),size(ims{termsToAv(1)},3));
        BW_perim = zeros(size(ims{termsToAv(1)},1),size(ims{termsToAv(1)},2),size(ims{termsToAv(1)},3));
        for frame = 1:size(STAavVesVid,3)
            [BW,~] = segmentImageVesselFOV_SF58(STAavVesVid(:,:,frame));
            BWstacks(:,:,frame) = BW; 
            %get the segmentation boundaries 
            BW_perim(:,:,frame) = bwperim(BW);
            %overlay segmentation boundaries on data
            segOverlays(:,:,:,frame) = imoverlay(mat2gray(STAavVesVid(:,:,frame)), BW_perim(:,:,frame), [.3 1 .3]);   
        end 
        %play segmentation boundaries over images 
        implay(segOverlays)
        
        segQ = input('Input 1 if the segmentation was good. ');
        if segQ == 1
            %black out pixels that belong to vessels  
            BWstacks = ~BWstacks;
            STAav(~BWstacks) = 0;
            for frame = 1:size(STAavVesVid,3)
                % create the % change image with the right white and black point
                % boundaries and colormap 
                figure('Visible','off');  
                imagesc(STAav(:,:,frame),[0,0.5]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',0:0.25:0.5)%this makes the max point 1% and the min point -1% 
                % get the x-y coordinates of the vessel outline
                [y, x] = find(BW_perim(:,:,frame));  % x and y are column vectors.     
                % plot the vessel outline over the % change image 
                hold on;
                scatter(x,y,'white','.');
                % plot the GCaMP signal marker in the right frame 
                if frame == CaEventFrame || frame == (CaEventFrame-1) || frame == (CaEventFrame+1)     
                    % get the x-y coordinates of the Ca ROIs         
                    % find the pixels that are over 20 in value 
                    clearvars CAy CAx
                    for termToAv = 1:length(termsToAv)
                        [CAy, CAx] = find(otherChan{termsToAv(termToAv)}(:,:,frame) >= 20);  % x and y are column vectors.
                        hold on;
                        scatter(CAx,CAy,100,'white','filled');
                    end 
                    %get border coordinates 
                    colLen = size(STAav,2);
                    rowLen = size(STAav,1);
                    edg1_x = repelem(1,rowLen);
                    edg1_y = 1:rowLen;
                    edg2_x = repelem(colLen,rowLen);
                    edg2_y = 1:rowLen;
                    edg3_x = 1:colLen;
                    edg3_y = repelem(1,colLen);
                    edg4_x = 1:colLen;
                    edg4_y = repelem(rowLen,colLen);
                    edg_x = [edg1_x,edg2_x,edg3_x,edg4_x];
                    edg_y = [edg1_y,edg2_y,edg3_y,edg4_y];
                    hold on;
                    scatter(edg_x,edg_y,15,'white','filled','square');               
                end 
                ax = gca;
                ax.Visible = 'off';
                ax.FontSize = 20;
                %save current figure to file 
                termsString1 = string(termsToAv);
                termsString = join(termsString1,'_');
                filename = sprintf('%s/CaROIs_%s_frame%d',dir2,termsString,frame);
                saveas(gca,[filename '.png'])
            end 
        end 
        clearvars STAterms STAtermsVesChans STAav STAavVesVid BWstacks BW_perim segOverlays
    end 
end 
%}
%% plot the average change in pixel intensity (entire FOV) of the DBSCAN video (RightChan)
%{
pixInt = nan(1,size(RightChan{1},3));
for frame = 1:size(RightChan{1},3)
    pixInt(frame) = mean(mean(RightChan{1}(:,:,frame)));
end 
plot(pixInt)
%}
%%  DBSCAN time locked to axon calcium spikes and opto stim (one animal at a time) 
%{
%% get the pixel sizes 
getPixSizeQ = input('Input 1 to ask for pixel size. Input 0 otherwise. '); 
if getPixSizeQ == 1 
    XpixDist = input('How many microns per pixel are there in the X direction? '); 
    YpixDist = input('How many microns per pixel are there in the Y direction? '); 
    if exist('downsampleRate','var') == 1 
        XpixDist = XpixDist*downsampleRate;
        YpixDist = YpixDist*downsampleRate;
    end 
    addDwnSmpQ = input('Input 1 if there is an additional downsample factor from image registration. ');
    if addDwnSmpQ == 1 
        addDwnSmpFctr = input('Input the additional downsample factor. '); 
        XpixDist = XpixDist*addDwnSmpFctr;
        YpixDist = YpixDist*addDwnSmpFctr;
    end 
end 

%% plot clusters 
mouse = 1;
vidQ2 = input('Input 1 to black out pixels inside of vessel. ');
dlightQ = input('Input 1 if this is dlight data. Input 0 if this is BBB data. ');
ETAorSTAq = input('Input 0 if this is STA data or 1 if this is ETA data. ');
if ETAorSTAq == 1 % ETA data 
    ccell = 1; 
    ETAtype = input('Input 0 if this is opto data. Input 1 for behavior data. ');
    if ETAtype == 1
        ETAtype2 = input('Input 0 if the data is time locked to the stim. Input 1 if time locked to the reward. ');
    end 
end 
inds = cell(1,max(terminals{mouse}));
idx = cell(1,max(terminals{mouse}));
indsV = cell(1,max(terminals{mouse}));
maskNearVessel = cell(1,max(terminals{mouse}));
indsV2 = cell(1,max(terminals{mouse}));
indsA = cell(1,max(terminals{mouse}));
indsA2 = cell(1,size(RightChan{ terminals{mouse}(1)},3));
unIdxVals = cell(1,max(terminals{mouse}));
CsNotNearVessel = cell(1,max(terminals{mouse}));
clustSize = NaN(length(terminals{mouse}),length(unIdxVals{terminals{mouse}(ccell)}));
clustAmp = NaN(length(terminals{mouse}),length(unIdxVals{terminals{mouse}(ccell)}));
spikeCount = cell(1,max(terminals{mouse}));
for ccell = 1:length(terminals{mouse})
    % figure out the number of spikes per axon 
    if iscell(sigLocs{1}) == 1 % if siglocs{1} contains another cell 
        for vid = 1:length(sigLocs)
            if vid == 1 
                spikeCount{terminals{mouse}(ccell)} = size(sigLocs{vid}{terminals{mouse}(ccell)},2);
            elseif vid > 1 
                spikeCount{terminals{mouse}(ccell)} = size(sigLocs{vid}{terminals{mouse}(ccell)},2) + spikeCount{terminals{mouse}(ccell)};             
            end 
        end 
    elseif iscell(sigLocs{1}) == 0 
        for vid = 1:length(sigLocs)
            if vid == 1 
                spikeCount{terminals{mouse}(ccell)} = size(sigLocs{vid},2);
            elseif vid > 1 
                spikeCount{terminals{mouse}(ccell)} = size(sigLocs{vid},2) + spikeCount{terminals{mouse}(ccell)};             
            end 
        end  
    end 
    count = 1;
    term = terminals{mouse}(ccell);
    % use dbscan to find clustered pixels 
%     im = RightChan{term}; % input image for % change vids
    im = binarySTA{term}; % input image for binarized z scored vids 
    vesselMask = BW_perim{term};
    % convert im to binary matrix where 1 = pixels that are positive going %
    % below code is for binarized z-score vids where 
    % 1 means greater than 95% CI and 2 means lower than 95% CI 
    im(im>1) = 0;
    % remove noise pixels that are there in all the frames 
    noise = all(im,3);
    noise = repelem(noise,1,1,size(im,3));
    im(noise) = 0;
    % remove columnar noise 
    for frame = 1:size(im,3)
        im(:,:,frame) = bwareaopen(im(:,:,frame),3);
    end 
    % below code is for % change videos 
%     maxPerc = max(max(max(im))); minPerc = min(min(min(im)));
%     thresh = maxPerc/10;
%     % thresh = 0;
%     % change 
%     im(im < thresh) = 0; im(im > thresh) = 1;
    % black out pixels inside of vessel     
    if vidQ2 == 1 
        im(BWstacks{terminals{mouse}(ccell)}) = 0;
    end 
    % get x and y and z coordinates of 1s (pixels that are positive going)
    [row, col, frame] = ind2sub(size(im),find(im > 0));
    inds{terminals{mouse}(ccell)}(:,1) = col; inds{terminals{mouse}(ccell)}(:,2) = row; inds{terminals{mouse}(ccell)}(:,3) = frame;
    % plot these x y coordinates for sanity check 
    % figure;scatter3(inds(:,1),inds(:,2),inds(:,3))
    % feed these x y coordinates into dbscan 
%     numP = 3; % number of points a cluster needs to be considered valid
%     fixRad = 1; % fixed radius for the search of neighbors 
    numP = 1; % number of points a cluster needs to be considered valid
    fixRad = 1; % fixed radius for the search of neighbors 
    [idx{terminals{mouse}(ccell)},corepts] = dbscan(inds{terminals{mouse}(ccell)},fixRad,numP);
    % need to convert cluster group identifiers into positive going values only
    % for scatter3
    unIdxVals{terminals{mouse}(ccell)} = unique(idx{terminals{mouse}(ccell)}); minIdxVal = min(unIdxVals{terminals{mouse}(ccell)});
    idx{terminals{mouse}(ccell)}(idx{terminals{mouse}(ccell)}<0) = NaN;
    unIdxVals{terminals{mouse}(ccell)}(unIdxVals{terminals{mouse}(ccell)}<0) = NaN;
    % get vessel outline coordinates 
    [rowV, colV, frameV] = ind2sub(size(vesselMask),find(vesselMask > 0));
    indsV{terminals{mouse}(ccell)}(:,1) = colV; indsV{terminals{mouse}(ccell)}(:,2) = rowV; indsV{terminals{mouse}(ccell)}(:,3) = frameV;  
    % figure out pixel locations just outside of vessel 
    for frame = 1:size(im,3)
        radius = 1;
        decomposition = 0;
        se = strel('disk', radius, decomposition);               
        maskNearVessel{terminals{mouse}(ccell)}(:,:,frame) = imdilate(BWstacks{terminals{mouse}(ccell)}(:,:,frame),se);               
    end 
    idx2 = idx;
    % get outline coordinates just outside of vessel 
    [rowV2, colV2, frameV2] = ind2sub(size(maskNearVessel{terminals{mouse}(ccell)}),find(maskNearVessel{terminals{mouse}(ccell)} > 0));
    indsV2{terminals{mouse}(ccell)}(:,1) = colV2; indsV2{terminals{mouse}(ccell)}(:,2) = rowV2; indsV2{terminals{mouse}(ccell)}(:,3) = frameV2;  
    % for each cluster, if one pixel is next to the vessel, keep that
    % cluster, otherwise clear that cluster
    for clust = 1:length(unIdxVals{terminals{mouse}(ccell)})
        % find what rows each cluster is located in
        [Crow, ~] = find(idx{terminals{mouse}(ccell)} == unIdxVals{terminals{mouse}(ccell)}(clust)); 
        % identify the x, y, z location of pixels per cluster
        cLocs = inds{terminals{mouse}(ccell)}(Crow,:);      
        if dlightQ == 0 % this is BBB data 
            % determine if cLocs are near the vessel 
            cLocsNearVes = ismember(indsV2{terminals{mouse}(ccell)},cLocs,'rows');
            if ~any(cLocsNearVes == 1) == 1 % if the cluster is not near the vessel 
                % delete cluster that is not near the vessel 
                inds{terminals{mouse}(ccell)}(Crow,:) = NaN; 
                idx{terminals{mouse}(ccell)}(Crow,:) = NaN; 
                CsNotNearVessel{terminals{mouse}(ccell)}(count) = unIdxVals{terminals{mouse}(ccell)}(clust);
                count = count + 1;            
            end 
        end 
        % determine cluster size in microns 
        clustSize(ccell,clust) = (sum(idx{terminals{mouse}(ccell)}(:) == unIdxVals{terminals{mouse}(ccell)}(clust)))*XpixDist*YpixDist;
        % determine cluster pixel amplitude 
        pixAmp = nan(1,size(cLocs,1));
        for pix = 1:length(pixAmp)
            pixAmp(pix) = RightChan{terminals{mouse}(ccell)}(cLocs(pix,2),cLocs(pix,1),cLocs(pix,3));
        end 
        clustAmp(ccell,clust) =  nanmean(pixAmp); %#ok<*NANSUM> 
    end         
end 
CsTooSmall = cell(1,max(terminals{mouse}));
% remove clusters that are not big enough in size and plot 
for ccell = 1:length(terminals{mouse})
    count = 1;
    % make 0s NaNs 
    clustSize(clustSize == 0) = NaN;
    clustAmp(clustAmp == 0) = NaN;
    % find the top 10 % of cluster sizes (this will be 100 or more
    % for 57)
    numClusts = nnz(~isnan(clustSize));
    numTopClusts = ceil(numClusts*0.1);
    reshapedSizes = reshape(clustSize,1,size(clustSize,1)*size(clustSize,2));
    % remove NaNs 
    reshapedSizes(isnan(reshapedSizes)) = [];
    % sort sizes 
    sortedSize = sort(reshapedSizes);
    % get the largest 10 % of cluster sizes 
    topClusts = sortedSize(end-numTopClusts+1:end);
    % get the locations of the topClusts 
    topClusts2 = ismember(clustSize,topClusts);       
    [topCx_A, topCy_C] = find(topClusts2);
    % determine what clusters are big enough to be included 
    bigClustAlocs = find(topCx_A == ccell); % find what rows the axon is in to determine what clusters are big enough per axon 
    bigClustLocs = topCy_C(bigClustAlocs);
    bigClusts = unIdxVals{terminals{mouse}(ccell)}(bigClustLocs);
    % remove clusters that do not include the top 10 % of sizes 
    for clust = 1:length(unIdxVals{terminals{mouse}(ccell)})
        % find what rows each cluster is located in
        [Crow, ~] = find(idx{terminals{mouse}(ccell)} == unIdxVals{terminals{mouse}(ccell)}(clust));  
        % remove clusters if they're too small 
        if sum(ismember(bigClusts,unIdxVals{terminals{mouse}(ccell)}(clust))) == 0 
            inds{terminals{mouse}(ccell)}(Crow,:) = NaN;
            idx{terminals{mouse}(ccell)}(Crow,:) = NaN;
            idx2{terminals{mouse}(ccell)}(Crow,:) = NaN;
            CsTooSmall{terminals{mouse}(ccell)}(count) = unIdxVals{terminals{mouse}(ccell)}(clust);
            count = count + 1;  
        end 
    end 
    % plot the grouped pixels 
    figure;scatter3(inds{terminals{mouse}(ccell)}(:,1),inds{terminals{mouse}(ccell)}(:,2),inds{terminals{mouse}(ccell)}(:,3),30,idx{terminals{mouse}(ccell)},'filled'); % plot clusters 
    % plot vessel outline 
    hold on; scatter3(indsV{terminals{mouse}(ccell)}(:,1),indsV{terminals{mouse}(ccell)}(:,2),indsV{terminals{mouse}(ccell)}(:,3),30,'k','filled'); % plot vessel outline 
    % get the x-y coordinates of the Ca ROI         
    clearvars CAy CAx
    if ~exist('variableInfo','var') == 1
        variableInfo = who;
    end 
    if ismember("ROIorders", variableInfo) == 1 && sum(unique(ROIorders{1})) > 1
        [CAyf, CAxf] = find(ROIorders{1} == terminals{mouse}(ccell));  % x and y are column vectors.
    elseif ismember("ROIorders", variableInfo) == 0 && ismember("CaROImasks", variableInfo) == 1
        [CAyf, CAxf] = find(CaROImasks{1} == terminals{mouse}(ccell));  % x and y are column vectors.
    elseif ismember("ROIorders", variableInfo) == 1 && sum(unique(ROIorders{1})) <= 1
        [CAyf, CAxf] = find(CaROImasks{1} == terminals{mouse}(ccell));
    end   
    % create axon x, y, z matrix 
    if exist('CAxf','var') == 1
        for frame = 1:size(im,3)
            if frame == 1 
                indsA{terminals{mouse}(ccell)}(:,1) = CAxf; indsA{terminals{mouse}(ccell)}(:,2) = CAyf; indsA{terminals{mouse}(ccell)}(:,3) = frame;
            elseif frame > 1 
                if frame == 2
                    len = size(indsA{terminals{mouse}(ccell)},1);
                end 
                len2 = size(indsA{terminals{mouse}(ccell)},1);
                indsA{terminals{mouse}(ccell)}(len2+1:len2+len,1) = CAxf; indsA{terminals{mouse}(ccell)}(len2+1:len2+len,2) = CAyf; indsA{terminals{mouse}(ccell)}(len2+1:len2+len,3) = frame;
            end 
        end 
    end 
    if ETAorSTAq == 0 % STA data 
        % plot axon location 
        hold on; scatter3(indsA{terminals{mouse}(ccell)}(:,1),indsA{terminals{mouse}(ccell)}(:,2),indsA{terminals{mouse}(ccell)}(:,3),30,'r'); % plot axon
        % convert indsA to microns 
        indsA{terminals{mouse}(ccell)}(:,1) = indsA{terminals{mouse}(ccell)}(:,1)*XpixDist;
        indsA{terminals{mouse}(ccell)}(:,2) = indsA{terminals{mouse}(ccell)}(:,2)*YpixDist;
    end 
    % zlim([35 37])
%     set(gca,'XLim',[0 40],'YLim',[10 65])%,'ZLim',[18.5 19.5])
    if ETAorSTAq == 0 % STA data 
        axonLabel = sprintf('Axon %d.',terminals{mouse}(ccell)); 
        spikeCountLabel = sprintf('%d spikes.',spikeCount{terminals{mouse}(ccell)}); 
        title({axonLabel;spikeCountLabel})
    elseif ETAorSTAq == 1 % ETA data 
        if ETAtype == 0 % opto data 
            optoCountLabel = sprintf('%d Trials.',spikeCount{terminals{mouse}(ccell)}); 
            title({'Opto Triggered';optoCountLabel}); 
        elseif ETAtype == 1 % behavior data 
            optoCountLabel = sprintf('%d Trials.',spikeCount{terminals{mouse}(ccell)}); 
            if ETAtype2 == 0 % stim aligned 
                if exist('state2Q','var') == 1
                    if exist('state2','var') == 1
                        if state2 == 0 % HIT 
                            title({'Behavior Hit Stim Aligned';optoCountLabel}); 
                        elseif state2 == 1 % MISS
                            title({'Behavior Miss Stim Aligned';optoCountLabel}); 
                        end 
                    elseif exist('state2','var') == 0
                        title({'Behavior Stim Aligned';optoCountLabel}); 
                    end 
                elseif exist('state2Q','var') == 0
                    title({'Behavior Stim Aligned';optoCountLabel}); 
                end 
            elseif ETAtype2 == 1 % reward aligned 
                if state4 == 0 % reward HIT 
                    title({'Behavior Reward Hit Aligned';optoCountLabel}); 
                elseif state4 == 1 % reward MISS 
                    title({'Behavior Reward Miss Aligned';optoCountLabel}); 
                end 
            end 
        end 
    end 
    % for each cluster (use inds and idx) determine first frame of
    % appearance and plot a figure showing the first frame of appearance
    clustIDs = unique(idx{terminals{mouse}(ccell)}); % what are the different individual cluster ID numbers
    clustIDs = clustIDs(~isnan(unique(idx{terminals{mouse}(ccell)})));
    figure;
    for clust = 1:sum(~isnan(unique(idx{terminals{mouse}(ccell)})))
        % find the inds for the different individual clusters by ID number 
        cIDinds = find(idx{terminals{mouse}(ccell)} == clustIDs(clust));
        % determine the inds for the first frame each cluster appears in 
        minFrame = min(inds{terminals{mouse}(ccell)}(cIDinds,3));
        minFrameInds = cIDinds(inds{terminals{mouse}(ccell)}(cIDinds,3) == minFrame);
        minVFrameInds = find(indsV{terminals{mouse}(ccell)}(:,3) == minFrame);
        % plot the grouped pixels 
         scatter3(indsV{terminals{mouse}(ccell)}(minVFrameInds,1),indsV{terminals{mouse}(ccell)}(minVFrameInds,2),indsV{terminals{mouse}(ccell)}(minVFrameInds,3),30,'k','filled'); % plot vessel outline 
        % plot vessel outline 
        hold on; scatter3(inds{terminals{mouse}(ccell)}(minFrameInds,1),inds{terminals{mouse}(ccell)}(minFrameInds,2),inds{terminals{mouse}(ccell)}(minFrameInds,3),30,idx{terminals{mouse}(ccell)}(minFrameInds),'filled'); % plot clusters 
        cols = idx{terminals{mouse}(ccell)}(minFrameInds);
        colormap(parula(cols(1)))
    end 
    if ETAorSTAq == 0 % STA data 
        axonLabel = sprintf('Axon %d.',terminals{mouse}(ccell)); 
        spikeCountLabel = sprintf('%d spikes.',spikeCount{terminals{mouse}(ccell)}); 
        title({axonLabel;spikeCountLabel})
    elseif ETAorSTAq == 1 % ETA data 
        if ETAtype == 0 % opto data 
            optoCountLabel = sprintf('%d Trials.',spikeCount{terminals{mouse}(ccell)}); 
            title({'Opto Triggered';optoCountLabel}); 
        elseif ETAtype == 1 % behavior data 
            optoCountLabel = sprintf('%d Trials.',spikeCount{terminals{mouse}(ccell)}); 
            if ETAtype2 == 0 % stim aligned 
                if exist('state2Q','var') == 1
                    if exist('state2','var') == 1
                        if state2 == 0 % HIT 
                            title({'Behavior Hit Stim Aligned';optoCountLabel}); 
                        elseif state2 == 1 % MISS
                            title({'Behavior Miss Stim Aligned';optoCountLabel}); 
                        end 
                    elseif exist('state2','var') == 0
                        title({'Behavior Stim Aligned';optoCountLabel}); 
                    end 
                elseif exist('state2Q','var') == 0
                    title({'Behavior Stim Aligned';optoCountLabel}); 
                end 
            elseif ETAtype2 == 1 % reward aligned 
                title({'Behavior Reward Aligned';optoCountLabel}); 
            end 
        end 
    end 
end 
% remove cluster sizes that are irrelevant 
removeClustSizes = ~ismember(clustSize,topClusts);
clustSize(removeClustSizes) = NaN;
% make sure clustAmp shows the same clusts as clustSize 
clustsToRemove = isnan(clustSize);
clustAmp(clustsToRemove) = NaN;

% safekeep some variables 
safeKeptInds = inds; 
safeKeptIdx = idx;
safeKeptClustSize = clustSize;
safeKeptClustAmp = clustAmp;

for ccell = 1:length(terminals{mouse})
    if ccell == 1 
        saveBinVidQ = input('Input 1 to save out binary significance videos. Input 0 otherwise. ');
        saveClustVidQ = input('Input 1 to save out DBSCAN cluster videos. Input 0 otherwise. ');
        if saveBinVidQ == 1 || saveClustVidQ == 1 
            dir1 = uigetdir('*.*','WHAT FOLDER ARE YOU SAVING THE VIDS/PHOTOS IN?'); % get the directory where you want to save your images 
            dir2 = strrep(dir1,'\','/');    
            if iscell(RightChan) == 1 
                ims = RightChan{1};
                CaEventFrame = floor(size(RightChan{1},3)/2); % input('What frame does the opto stim start? ');
            elseif iscell(RightChan) == 0
                ims = RightChan;
                CaEventFrame = floor(size(RightChan,3)/2); % input('What frame does the opto stim start? ');    
            end 
            if saveBinVidQ == 1
                %create a new folder per calcium ROI 
                if ETAorSTAq == 0 % STA data
                    newFolder = sprintf('BinaryImages_axon%d',terminals{mouse}(ccell));
                elseif ETAorSTAq == 1 % ETA data
                    newFolder = ('BinaryImages');                    
                end 
                mkdir(dir2,newFolder)
            end 
            if saveClustVidQ == 1
                %create a new folder per calcium ROI 
                if ETAorSTAq == 0 % STA data
                    newFolder = sprintf('ClusterImages_axon%d',terminals{mouse}(ccell));                    
                elseif ETAorSTAq == 1 % ETA data
                    newFolder = ('ClusterImages');
                end 
                mkdir(dir2,newFolder)
            end 
        end 
    end 
    % option to save out the a binary video 
    if saveBinVidQ == 1
        for frame = 1:size(im,3)
            figure('Visible','off');  
            imshow(im(:,:,frame),'InitialMagnification', 800)
            % get the x-y coordinates of the vessel outline
            if iscell(BW_perim) == 0
                [yf, xf] = find(BW_perim(:,:,frame));  % x and y are column vectors.
            elseif iscell(BW_perim) == 1
                [yf, xf] = find(BW_perim{1}(:,:,frame));  % x and y are column vectors.
            end                                          
            % plot the vessel outline over the image 
            hold on;
            scatter(xf,yf,'red','.');
            % plot colored border to show when event occurs 
            if frame == CaEventFrame || frame == (CaEventFrame-1) || frame == (CaEventFrame+1)
                %get border coordinates 
                colLen = size(ims,2);
                rowLen = size(ims,1);
                edg1_x = repelem(1,rowLen);
                edg1_y = 1:rowLen;
                edg2_x = repelem(colLen,rowLen);
                edg2_y = 1:rowLen;
                edg3_x = 1:colLen;
                edg3_y = repelem(1,colLen);
                edg4_x = 1:colLen;
                edg4_y = repelem(rowLen,colLen);
                edg_x = [edg1_x,edg2_x,edg3_x,edg4_x];
                edg_y = [edg1_y,edg2_y,edg3_y,edg4_y];
                hold on;
                scatter(edg_x,edg_y,100,'blue','filled','square');      
            end 
            ax = gca;
            ax.Visible = 'off';
            %save current figure to file 
            filename = sprintf('%s/%s/frame%d',dir2,newFolder,frame);
            saveas(gca,[filename '.png'])
        end 
    end 
    % option to save out the cluster video 
    if saveClustVidQ == 1
        % determine the range of cluster colors that exist 
        unIdxClr = unique(idx{terminals{mouse}(ccell)});
        unIdxClrLoc = ~isnan(unique(idx{terminals{mouse}(ccell)}));
        unIdxClr = unIdxClr(unIdxClrLoc);
        clrMin = min(unIdxClr);
        clrMax = max(unIdxClr);
        % set the color bar based on this range ahead of time to be used
        % per frame 
        for frame = 1:size(im,3)
            figure('Visible','off');  
            % determine all the cluster data points in each individual frame 
            dataInds = find(inds{terminals{mouse}(ccell)}(:,3) == frame);
            % plot the grouped pixels 
            scatter(inds{terminals{mouse}(ccell)}(dataInds,1),inds{terminals{mouse}(ccell)}(dataInds,2),30,idx{terminals{mouse}(ccell)}(dataInds),'filled'); % plot clusters
            colormap default 
            clim([clrMin clrMax]);
            % determine all the vessel outline data points in each individual frame 
            dataIndsV = find(indsV{terminals{mouse}(ccell)}(:,3) == frame);
            % plot vessel outline 
            hold on; scatter(indsV{terminals{mouse}(ccell)}(dataIndsV,1),indsV{terminals{mouse}(ccell)}(dataIndsV,2),30,'k','filled'); % plot vessel outline 
            % plot colored border to show when event occurs 
            if frame == CaEventFrame || frame == (CaEventFrame-1) || frame == (CaEventFrame+1)
                %get border coordinates 
                colLen = size(ims,2);
                rowLen = size(ims,1);
                edg1_x = repelem(1,rowLen);
                edg1_y = 1:rowLen;
                edg2_x = repelem(colLen,rowLen);
                edg2_y = 1:rowLen;
                edg3_x = 1:colLen;
                edg3_y = repelem(1,colLen);
                edg4_x = 1:colLen;
                edg4_y = repelem(rowLen,colLen);
                edg_x = [edg1_x,edg2_x,edg3_x,edg4_x];
                edg_y = [edg1_y,edg2_y,edg3_y,edg4_y];
                hold on;
                scatter(edg_x,edg_y,100,'blue','filled','square');      
            end 
            ax = gca;
            ax.Visible = 'off';
            %save current figure to file 
            filename = sprintf('%s/%s/frame%d',dir2,newFolder,frame);
            saveas(gca,[filename '.png'])
        end 
    end 
end 

figure('Visible','on'); 

%% plot the proportion of clusters that are near the vessel out of total # of clusters 
if dlightQ == 0 % BBB data 
    % use unIdxVals (total # of clusters) and CsNotNearVessel (# of clusters
    % not near vessel)
    nearVsFarPlotData = zeros(length(terminals{mouse}),2);
    % resort data for stacked bar plot 
    unIdxVals2 = cell(1,max(terminals{mouse}));
    labels = strings(1,length(terminals{mouse}));
    for ccell = 1:length(terminals{mouse})
        unIdxVals2{terminals{mouse}(ccell)} = unique(idx2{terminals{mouse}(ccell)});
        nearVsFarPlotData(ccell,1) = length(unIdxVals2{terminals{mouse}(ccell)})-length(CsNotNearVessel{terminals{mouse}(ccell)});
        nearVsFarPlotData(ccell,2) = length(CsNotNearVessel{terminals{mouse}(ccell)});
        labels(ccell) = num2str(terminals{mouse}(ccell));
    end 
    % plot stacked bar plot
    if ETAorSTAq == 0 %ETAorSTAq = input('Input 0 if this is STA data or 1 if this is ETA data. ');
        figure;
        subplot(1,2,1)
        ax=gca;
        ba = bar(nearVsFarPlotData,'stacked','FaceColor','flat');
        ba(1).CData = [0 0.4470 0.7410];
        ba(2).CData = [0.8500 0.3250 0.0980];
        ax.FontSize = 15;
        ax.FontName = 'Times';
        ylabel("Number of Clusters")
        xlabel("Axon")
        legend("Clusters Near Vessel","Clusters Far from Vessel")
        xticklabels(labels)
        % plot pie chart 
        subplot(1,2,2)
        % resort data for averaged pie chart 
        AvNearVsFarPlotData = mean(nearVsFarPlotData,1);
        pie(AvNearVsFarPlotData);
        colormap([0 0.4470 0.7410; 0.8500 0.3250 0.0980])
    elseif ETAorSTAq == 1 
        figure;
        % plot pie chart 
        % resort data for averaged pie chart 
        AvNearVsFarPlotData = mean(nearVsFarPlotData,1);
        pie(AvNearVsFarPlotData);
        colormap([0 0.4470 0.7410; 0.8500 0.3250 0.0980])
        legend("Clusters Near Vessel","Clusters Far from Vessel")
    end 
end 
%% plot the number of pixels per cluster, the number of total pixels and the number of total clusters

uniqClusts = cell(1,max(terminals{mouse}));
numPixels = nan(1,length(terminals{mouse}));
numClusts = nan(1,length(terminals{mouse}));
uniqClustPixNums = nan(1,1);
count = 1;
for ccell = 1:length(terminals{mouse})
    % determine the total number of pixels 
    numPixels(ccell) = length(idx{terminals{mouse}(ccell)}(~isnan(idx{terminals{mouse}(ccell)})))*XpixDist*YpixDist;
    totalNumPixels = sum(numPixels);
    avNumPixels = mean(numPixels);
    medNumPixels = median(numPixels);
    % determine the total number of clusters 
    uniqClusts{terminals{mouse}(ccell)} = unique(idx{terminals{mouse}(ccell)}(~isnan(idx{terminals{mouse}(ccell)})));
    numClusts(ccell) = length(uniqClusts{terminals{mouse}(ccell)});
    totalNumClusts = sum(numClusts);
    avNumClusts = mean(numClusts);
    medNumClusts = median(numClusts);
    % determine the number of pixels per cluster 
    for clust = 1:numClusts(ccell)
        uniqClustPixNums(count) = length(find(idx{terminals{mouse}(ccell)}(~isnan(idx{terminals{mouse}(ccell)})) == uniqClusts{terminals{mouse}(ccell)}(clust)))*XpixDist*YpixDist;
        count = count + 1;
    end 
    totalUniqClustPixNums = sum(uniqClustPixNums);
    avNumUniqClustPixNums = mean(uniqClustPixNums);
    medNumUniqClustPixNums = median(uniqClustPixNums);
end 

if ETAorSTAq == 0 %ETAorSTAq = input('Input 0 if this is STA data or 1 if this is ETA data. ');
    subplot(1,3,1)
    histogram(numPixels,10)
    totalPixelNumLabel = sprintf('%.0f microns squared total.',totalNumPixels);
    avPixelNumLabel = sprintf('%.0f average microns squared per axon.',avNumPixels);
    medPixelNumLabel = sprintf('%.0f median microns squared per axon.',medNumPixels);
    title({totalPixelNumLabel;avPixelNumLabel;medPixelNumLabel})
    ax = gca;
    ax.FontSize = 15;
    subplot(1,3,2)
    histogram(numClusts,10)
    totalClustNumLabel = sprintf('%.0f clusters total.',totalNumClusts);
    avClustNumLabel = sprintf('%.0f average clusters per axon.',avNumClusts);
    medClustNumLabel = sprintf('%.0f median clusters per axon.',medNumClusts);
    title({totalClustNumLabel;avClustNumLabel;medClustNumLabel})
    ax = gca;
    ax.FontSize = 15;
    subplot(1,3,3)
    histogram(uniqClustPixNums,10)
    % totalUniqClustPixNumsLabel = sprintf('%.0f pixels total.',totalUniqClustPixNums);
    avUniqClustPixNumsLabel = sprintf('%.0f average microns squared per cluster.',avNumUniqClustPixNums);
    medNumUniqClustPixNumsLabel = sprintf('%.0f median microns squared per cluster.',medNumUniqClustPixNums);
    title({avUniqClustPixNumsLabel;medNumUniqClustPixNumsLabel})
    ax = gca;
    ax.FontSize = 15;
elseif ETAorSTAq == 1 %ETAorSTAq = input('Input 0 if this is STA data or 1 if this is ETA data. ');
    figure
    totalPixelNumLabel = sprintf('%.0f microns squared total.',totalNumPixels);
    totalClustNumLabel = sprintf('%.0f clusters total.',totalNumClusts);
    histogram(uniqClustPixNums,10)
    % totalUniqClustPixNumsLabel = sprintf('%.0f pixels total.',totalUniqClustPixNums);
    avUniqClustPixNumsLabel = sprintf('%.0f average microns squared per cluster.',avNumUniqClustPixNums);
    medNumUniqClustPixNumsLabel = sprintf('%.0f median microns squared per cluster.',medNumUniqClustPixNums);
    title({totalClustNumLabel;totalPixelNumLabel;avUniqClustPixNumsLabel;medNumUniqClustPixNumsLabel})
    ax = gca;
    ax.FontSize = 15;
end 
 
%% below code takes the clusters made and plotted above to make figures out of 
% asks if you want to separate clusters based off of their timing relative
% to spike 
inds = safeKeptInds;
idx = safeKeptIdx;
clustSize = safeKeptClustSize;
clustAmp = safeKeptClustAmp;

% separate clusters based off of whether they happened before or after the
% spike 
% before spike: frame <= 26 
% after spike: frame >= 27 
clustSpikeQ = input('Input 0 to see all clusters. Input 1 to see either pre/post spike clusters. ');
% clustSpikeQ3 = input('Input 0 to get average cluster timing. 1 to get start of cluster timing. ');
clustSpikeQ3 = 1;
if clustSpikeQ == 1
    clustSpikeQ2 = input('Input 0 to see pre spike clusters. Input 1 to see post spike clusters. ');     
end 

% determine cluster timing 
[s, ~] = cellfun(@size,unIdxVals);
maxNumClusts = max(s);
avClocFrame = NaN(length(terminals{mouse}),maxNumClusts);
clustStartFrame = NaN(length(terminals{mouse}),maxNumClusts);
for ccell = 1:length(terminals{mouse})
    for clust = 1:length(unIdxVals{terminals{mouse}(ccell)})
       % find what rows each cluster is located in
        [Crow, ~] = find(idx{terminals{mouse}(ccell)} == unIdxVals{terminals{mouse}(ccell)}(clust)); 
        % identify the x, y, z location of pixels per cluster
        cLocs = inds{terminals{mouse}(ccell)}(Crow,:);  
        % remove clusters that are not in the correct time bin                         
        if clustSpikeQ3 == 0 
            % this determines the average timing of each cluster 
            avClocFrame(ccell,clust) = mean(cLocs(:,3)); 
        elseif clustSpikeQ3 == 1 
            if isempty(cLocs) == 0
                % determine the start time of each cluster 
                avClocFrame(ccell,clust) = min(cLocs(:,3)); 
            end 
        end        
        if isempty(cLocs) == 0
            clustStartFrame(ccell,clust) = min(cLocs(:,3)); 
        end 
        frameThresh = ceil(size(im,3)/2);
        if clustSpikeQ == 1
            if clustSpikeQ2 == 0 % see pre spike clusters 
                if avClocFrame(ccell,clust) >= frameThresh % remove clusters that come after the spike 
                    inds{terminals{mouse}(ccell)}(Crow,:) = NaN; 
                    idx{terminals{mouse}(ccell)}(Crow,:) = NaN;
                    clustSize(ccell,clust) = NaN;
                    clustAmp(ccell,clust) = NaN;
                end 
            elseif clustSpikeQ2 == 1 % see post spike clusters 
                if avClocFrame(ccell,clust) < frameThresh % remove clusters that come before the spike 
                    inds{terminals{mouse}(ccell)}(Crow,:) = NaN; 
                    idx{terminals{mouse}(ccell)}(Crow,:) = NaN; 
                    clustSize(ccell,clust) = NaN;
                    clustAmp(ccell,clust) = NaN;
                end 
            end 
        end 
    end 
end 
% make 0s NaNs 
avClocFrame(avClocFrame == 0) = NaN;
clustStartFrame(clustStartFrame == 0) = NaN;

% determine when the cluster touches the vessel 
clustTouchVesFrame = NaN(length(terminals{mouse}),maxNumClusts);
for ccell = 1:length(terminals{mouse})
    % for each cluster, if one pixel is next to the vessel, keep that
    % cluster, otherwise clear that cluster
    for clust = 1:length(unIdxVals{terminals{mouse}(ccell)})
        % find what rows each cluster is located in
        [Crow, ~] = find(idx{terminals{mouse}(ccell)} == unIdxVals{terminals{mouse}(ccell)}(clust)); 
        % identify the x, y, z location of pixels per cluster
        cLocs = inds{terminals{mouse}(ccell)}(Crow,:);        
        % determine if cLocs are near the vessel 
        cLocsNearVes = ismember(indsV2{terminals{mouse}(ccell)},cLocs,'rows');
        % determine the first frame that cluster touches the vessel in
        vesTouchFrame = find(cLocsNearVes == 1, 1);
        if isempty(vesTouchFrame) == 0 
            clustTouchVesFrame(ccell,clust) = vesTouchFrame;
        end 
    end 
end 

% determine change in cluster size and pixel amplitude over time  
clustPixAmpTS = cell(1,max(terminals{mouse}));
clustSizeTS = cell(1,max(terminals{mouse}));
clustFit = cell(1);
for ccell = 1:length(terminals{mouse})
    for clust = 1:length(unIdxVals{terminals{mouse}(ccell)})
        % find what rows each cluster is located in
        [Crow, ~] = find(idx{terminals{mouse}(ccell)} == unIdxVals{terminals{mouse}(ccell)}(clust)); 
        % identify the x, y, z location of pixels per cluster
        cLocs = inds{terminals{mouse}(ccell)}(Crow,:); 
        for frame = 1:size(im,3)
            % get change in pixel amplitude 
            pixelInds = find(cLocs(:,3)==frame);
            pixAmp = nan(1,length(pixelInds));
            for pix = 1:length(pixelInds)
                pixAmp(pix) = RightChan{terminals{mouse}(ccell)}(cLocs(pixelInds(pix),2),cLocs(pixelInds(pix),1),cLocs(pixelInds(pix),3));
            end 
            clustPixAmpTS{terminals{mouse}(ccell)}(clust,frame) = nanmean(pixAmp); %#ok<*NANSUM> 
            % determine cluster size in microns over time          
            clustSizeTS{terminals{mouse}(ccell)}(clust,frame) = length(find(cLocs(:,3)==frame))*XpixDist*YpixDist;
        end  
    end 
    % remove clusters that start at the first frame and decrease over
    % time 
    [earlyClusts, ~] = find(clustSizeTS{terminals{mouse}(ccell)}(:,1) > 0);
    % determine trend line     
    for clust = 1:length(earlyClusts)
        clustFit{ccell,clust} = fit((1:sum(~isnan(clustSizeTS{terminals{mouse}(ccell)}(earlyClusts(clust),:))))',(clustSizeTS{terminals{mouse}(ccell)}(earlyClusts(clust),1:sum(~isnan(clustSizeTS{terminals{mouse}(ccell)}(earlyClusts(clust),:)))))','poly1');
        if clustFit{ccell,clust}.p1 < 0 %|| avClocFrame(ccell,earlyClusts(clust)) == 1  % if the slope is negative
            % THE SECOND CONDITION DIRECLTY ABOVE IS TEMPORARY CODE FOR 58

            % find what rows each cluster is located in
            [Crow, ~] = find(idx{terminals{mouse}(ccell)} == earlyClusts(clust)-1); 
            % remove the cluster 
            inds{terminals{mouse}(ccell)}(Crow,:) = NaN; 
            idx{terminals{mouse}(ccell)}(Crow,:) = NaN; 
            clustSize(ccell,earlyClusts(clust)) = NaN;
            clustAmp(ccell,earlyClusts(clust)) = NaN;
            clustSizeTS{terminals{mouse}(ccell)}(earlyClusts(clust),:) = NaN;
            avClocFrame(ccell,earlyClusts(clust)) = NaN;
            clustStartFrame(ccell,earlyClusts(clust)) = NaN;
            clustTouchVesFrame(ccell,earlyClusts(clust)) = NaN;
            clustPixAmpTS{terminals{mouse}(ccell)}(earlyClusts(clust),:) = NaN;          
        end 
    end 
end 
for ccell = 1:length(terminals{mouse})
    % turn 0s into NaNs 
    clustSizeTS{terminals{mouse}(ccell)}(clustSizeTS{terminals{mouse}(ccell)} == 0) = NaN;
    clustPixAmpTS{terminals{mouse}(ccell)}(clustPixAmpTS{terminals{mouse}(ccell)} == 0) = NaN;
    % remove rows that are entirely NaN
    clustSizeTS{terminals{mouse}(ccell)}(all(isnan(clustSizeTS{terminals{mouse}(ccell)}),2),:) = [];
    clustPixAmpTS{terminals{mouse}(ccell)}(all(isnan(clustPixAmpTS{terminals{mouse}(ccell)}),2),:) = [];
end   

if ETAorSTAq == 0 % STA data 
    % determine distance of each cluster from each axon 
    dists = cell(1,max(terminals{mouse}));
    minACdists = NaN(length(terminals{mouse}),length(unIdxVals{terminals{mouse}(ccell)}));
    for ccell = 1:length(terminals{mouse})
        for clust = 1:length(unIdxVals{terminals{mouse}(ccell)})
           % find what rows each cluster is located in
            [Crow, ~] = find(idx{terminals{mouse}(ccell)} == unIdxVals{terminals{mouse}(ccell)}(clust)); 
            % identify the x, y, z location of pixels per cluster
            cLocs = inds{terminals{mouse}(ccell)}(Crow,:);  
            % convert cLoc X and Y inds to microns 
            if isempty(cLocs) == 0 
                cLocs(:,1) = cLocs(:,1)*XpixDist; cLocs(:,2) = cLocs(:,2)*YpixDist; 
            end 
            for Apoint = 1:size(indsA{terminals{mouse}(ccell)},1)
                for Cpoint = 1:size(cLocs,1)
                    % get euclidean micron distance between each Ca ROI pixel
                    % and BBB cluster pixel 
                    dists{terminals{mouse}(ccell)}{clust}(Apoint,Cpoint) = sqrt(((cLocs(Cpoint,1)-indsA{terminals{mouse}(ccell)}(Apoint,1))^2)+((cLocs(Cpoint,2)-indsA{terminals{mouse}(ccell)}(Apoint,2))^2)); 
                end 
            end 
        end 
    end 
    for ccell = 1:length(terminals{mouse})
        for clust = 1:length(dists{terminals{mouse}(ccell)})
            % determine minimum distance between each Ca ROI and cluster 
            if isempty(dists{terminals{mouse}(ccell)}{clust}) == 0
                minACdists(ccell,clust) = min(min(dists{terminals{mouse}(ccell)}{clust}));
            end 
        end 
    end 
    % make 0s NaNs 
    minACdists(minACdists == 0) = NaN;
    % resort size and distance data for gscatter 
    if size(minACdists,2) < size(clustSize,2)
        minACdists(:,size(minACdists,2)+1:size(clustSize,2)) = NaN;
    end 
    
    % determine distance of each cluster origin from vessel from each axon 
    dists = cell(1,max(terminals{mouse}));
    minACOdists = NaN(length(terminals{mouse}),length(unIdxVals{terminals{mouse}(ccell)}));
    for ccell = 1:length(terminals{mouse})
        for clust = 1:length(unIdxVals{terminals{mouse}(ccell)})
           % find what rows each cluster is located in
            [Crow, ~] = find(idx{terminals{mouse}(ccell)} == unIdxVals{terminals{mouse}(ccell)}(clust)); 
            % identify the x, y, z location of pixels per cluster
            cLocs = inds{terminals{mouse}(ccell)}(Crow,:);  
            if isempty(cLocs) == 0 
                % determine the first frame that the cluster appears in 
                cFirstFrame = min(cLocs(:,3));
                [r,~] = find(cLocs(:,3) == cFirstFrame);
                % only select indices from the first time the cluster appears 
                cLocs = cLocs(r,:);
                % only look at axon location where the cluster first appears 
                [r,~] = find(indsA{terminals{mouse}(ccell)}(:,3) == cFirstFrame);
                indsAfirst = indsA{terminals{mouse}(ccell)}(r,:);
                % convert cLoc X and Y inds to microns 
                cLocs(:,1) = cLocs(:,1)*XpixDist; cLocs(:,2) = cLocs(:,2)*YpixDist; 
                for Apoint = 1:size(indsAfirst,1)
                    for Cpoint = 1:size(cLocs,1)
                        % get euclidean micron distance between each Ca ROI pixel
                        % and BBB cluster pixel 
                        dists{terminals{mouse}(ccell)}{clust}(Apoint,Cpoint) = sqrt(((cLocs(Cpoint,1)-indsAfirst(Apoint,1))^2)+((cLocs(Cpoint,2)-indsAfirst(Apoint,2))^2)); 
                    end 
                end 
            end
        end 
    end 
    for ccell = 1:length(terminals{mouse})
        for clust = 1:length(dists{terminals{mouse}(ccell)})
            % determine minimum distance between each Ca ROI and cluster 
            if isempty(dists{terminals{mouse}(ccell)}{clust}) == 0
                minACOdists(ccell,clust) = min(min(dists{terminals{mouse}(ccell)}{clust}));
            end 
        end 
    end 
    % make 0s NaNs 
    minACOdists(minACOdists == 0) = NaN;
    % resort size and distance data for gscatter 
    if size(minACOdists,2) < size(clustSize,2)
        minACOdists(:,size(minACOdists,2)+1:size(clustSize,2)) = NaN;
    end 
    
    % resort cluster start time and distance data for gscatter 
    clear timeDistArray includeX2 includY2 includeXY2
    f2 = cell(1,length(terminals{mouse}));
    for ccell = 1:length(terminals{mouse})
        if ccell == 1 
            timeDistArray(:,1) = avClocFrame(ccell,:);
            timeDistArray(:,2) = minACdists(ccell,:);
            timeDistArray(:,3) = ccell;       
            % determine trend line 
            includeX2 =~ isnan(timeDistArray(:,1)); includeY2 =~ isnan(timeDistArray(:,2));
            % make incude XY that has combined 0 locs 
            [zeroRow, ~] = find(includeY2 == 0);
            includeX2(zeroRow) = 0; includeXY2 = includeX2;                
            timeDistX = timeDistArray(:,1); timeDistY = timeDistArray(:,2);  
            if sum(includeXY2) > 1 
                f2{ccell} = fit(timeDistX(includeXY2),timeDistY(includeXY2),'poly1');  
            end 
        elseif ccell > 1 
            if ccell == 2
                len = size(timeDistArray,1);   
            end 
            len2 = size(timeDistArray,1);       
            timeDistArray(len2+1:len2+len,1) = avClocFrame(ccell,:);
            timeDistArray(len2+1:len2+len,2) = minACdists(ccell,:);
            timeDistArray(len2+1:len2+len,3) = ccell;                  
            % determine trend line 
            includeX2 =~ isnan(timeDistArray(len2+1:len2+len,1)); includeY2 =~ isnan(timeDistArray(len2+1:len2+len,2));
            % make incude XY that has combined 0 locs 
            [zeroRow, ~] = find(includeY2 == 0);
            includeX2(zeroRow) = 0; includeXY2 = includeX2;                
            timeDistX = timeDistArray(len2+1:len2+len,1); timeDistY = timeDistArray(len2+1:len2+len,2);   
            if sum(includeXY2) > 1 
                f2{ccell} = fit(timeDistX(includeXY2),timeDistY(includeXY2),'poly1');
            end 
        end 
    end 
    % determine average trend line for time vs distance 
    includeX2 =~ isnan(timeDistArray(:,1)); includeY2 =~ isnan(timeDistArray(:,2));
    % make incude XY that has combined 0 locs 
    [zeroRow, ~] = find(includeY2 == 0);
    includeX2(zeroRow) = 0; includeXY2 = includeX2;                
    timeDistX = timeDistArray(:,1); timeDistY = timeDistArray(:,2);   
    if length(find(includeXY2)) > 1
        fav2 = fitlm(timeDistX(includeXY2),timeDistY(includeXY2),'poly1');
    end 
    
    % resort cluster start time and distance of axon from cluster origin data for gscatter 
    clear timeODistArray includeX2 includY2 includeXY2
    f2O = cell(1,length(terminals{mouse}));
    for ccell = 1:length(terminals{mouse})
        if ccell == 1 
            timeODistArray(:,1) = avClocFrame(ccell,:);
            timeODistArray(:,2) = minACOdists(ccell,:);
            timeODistArray(:,3) = ccell;       
            % determine trend line 
            includeX2O =~ isnan(timeODistArray(:,1)); includeY2O =~ isnan(timeODistArray(:,2));
            % make incude XY that has combined 0 locs 
            [zeroRow, ~] = find(includeY2O == 0);
            includeX2O(zeroRow) = 0; includeXY2O = includeX2O;                
            timeDistOX = timeODistArray(:,1); timeDistOY = timeODistArray(:,2);  
            if sum(includeXY2O) > 1 
                f2O{ccell} = fit(timeDistOX(includeXY2O),timeDistOY(includeXY2O),'poly1');  
            end 
        elseif ccell > 1 
            if ccell == 2
                len = size(timeODistArray,1);   
            end 
            len2 = size(timeODistArray,1);       
            timeODistArray(len2+1:len2+len,1) = avClocFrame(ccell,:);
            timeODistArray(len2+1:len2+len,2) = minACOdists(ccell,:);
            timeODistArray(len2+1:len2+len,3) = ccell;                  
            % determine trend line 
            includeX2O =~ isnan(timeODistArray(len2+1:len2+len,1)); includeY2O =~ isnan(timeODistArray(len2+1:len2+len,2));
            % make incude XY that has combined 0 locs 
            [zeroRow, ~] = find(includeY2O == 0);
            includeX2O(zeroRow) = 0; includeXY2O = includeX2O;                
            timeDistXO = timeODistArray(len2+1:len2+len,1); timeDistOY = timeODistArray(len2+1:len2+len,2);   
            if sum(includeXY2O) > 1 
                f2O{ccell} = fit(timeDistXO(includeXY2O),timeDistOY(includeXY2O),'poly1');
            end 
        end 
    end 
    % determine average trend line for time vs distance 
    includeX2O =~ isnan(timeODistArray(:,1)); includeY2O =~ isnan(timeODistArray(:,2));
    % make incude XY that has combined 0 locs 
    [zeroRow, ~] = find(includeY2O == 0);
    includeX2O(zeroRow) = 0; includeXY2O = includeX2O;                
    timeDistXO = timeODistArray(:,1); timeDistOY = timeODistArray(:,2);   
    if length(find(includeXY2O)) > 1
        fav2O = fitlm(timeDistXO(includeXY2O),timeDistOY(includeXY2O),'poly1');
    end 

    % determine distance of each axon to the vessel 
    VAdistQ = input('Input 1 to get axon distances from the vessel. ');
    if VAdistQ == 1
        drawVQ = input('Input 1 to draw vessel outline for determining axon distance from vessel. ');
        if drawVQ == 1 
            clearvars indsV Vinds
            vesIm = nanmean(vesChan{terminals{mouse}(1)},3);
            figure;
            imshow(vesIm,[0 500])
            disp('Draw the vessel outline.');
            Vdata = drawfreehand(gca);  % manually draw vessel outline
            % get VR outline coordinates 
            Vinds = Vdata.Position;  
            outLineQ = input('Input 1 if you are done drawing the vessel outline. ');
            if outLineQ == 1
                close all
            end 
        end 
        len = size(Vinds,1); 
        % convert Vinds to microns 
        Vinds(:,1) = Vinds(:,1)*XpixDist; Vinds(:,2) = Vinds(:,2)*YpixDist;
        for frame = 1:size(im,3)
            if frame == 1 
                indsV(:,1:2) = Vinds;
                indsV(:,3) = frame;
            elseif frame > 1 
                len2 = size(indsV,1);
                indsV(len2+1:len2+len,1:2) = Vinds;
                indsV(len2+1:len2+len,3) = frame;
            end 
        end 
        % determine distance of axon to the vessel 
        dists = cell(1,max(terminals{mouse}));
        minVAdists = NaN(1,length(terminals{mouse}));
        for ccell = 1:length(terminals{mouse})
            for Vpoint = 1:size(indsV,1)
                for Apoint = 1:size(indsA{terminals{mouse}(ccell)},1)
                    % get euclidean micron distance between each Ca ROI and the vessel  
                    dists{terminals{mouse}(ccell)}(Vpoint,Apoint) = sqrt(((indsA{terminals{mouse}(ccell)}(Apoint,1)-indsV(Vpoint,1))^2)+((indsA{terminals{mouse}(ccell)}(Apoint,2)-indsV(Vpoint,2))^2)); 
                end 
            end 
        end 
        for ccell = 1:length(terminals{mouse})
            % determine minimum distance between each Ca ROI and cluster 
            if isempty(dists{terminals{mouse}(ccell)}) == 0
                minVAdists(ccell) = min(min(dists{terminals{mouse}(ccell)}));
            end 
        end 
        % make 0s NaNs 
        minVAdists(minVAdists == 0) = NaN;
    end
end 

if dlightQ == 0 % BBB data 
    clear sizeDistArray includeX includY includeXY
    labels = strings(1,length(terminals{mouse}));
    f = cell(1,length(terminals{mouse}));
    for ccell = 1:length(terminals{mouse})
        if ccell == 1 
            if exist('minACdists','var')
                sizeDistArray(:,1) = minACdists(ccell,:);
            end 
            sizeDistArray(:,2) = clustSize(ccell,:);
            sizeDistArray(:,3) = ccell;       
            % determine trend line 
            includeX =~ isnan(sizeDistArray(:,1)); includeY =~ isnan(sizeDistArray(:,2));
            % make incude XY that has combined 0 locs 
            [zeroRow, ~] = find(includeY == 0);
            includeX(zeroRow) = 0; includeXY = includeX;                
            sizeDistX = sizeDistArray(:,1); sizeDistY = sizeDistArray(:,2);  
            if sum(includeXY) > 1 
                f{ccell} = fit(sizeDistX(includeXY),sizeDistY(includeXY),'poly1');  
            end 
        elseif ccell > 1 
            if ccell == 2
                len = size(sizeDistArray,1);   
            end 
            len2 = size(sizeDistArray,1);    
            if exist('minACdists','var')
                sizeDistArray(len2+1:len2+len,1) = minACdists(ccell,:);
            end 
            sizeDistArray(len2+1:len2+len,2) = clustSize(ccell,:);
            sizeDistArray(len2+1:len2+len,3) = ccell;                  
            % determine trend line 
            includeX =~ isnan(sizeDistArray(len2+1:len2+len,1)); includeY =~ isnan(sizeDistArray(len2+1:len2+len,2));
            % make incude XY that has combined 0 locs 
            [zeroRow, ~] = find(includeY == 0);
            includeX(zeroRow) = 0; includeXY = includeX;                
            sizeDistX = sizeDistArray(len2+1:len2+len,1); sizeDistY = sizeDistArray(len2+1:len2+len,2);   
            if sum(includeXY) > 1 
                f{ccell} = fit(sizeDistX(includeXY),sizeDistY(includeXY),'poly1');
            end 
        end 
        labels(ccell) = num2str(terminals{mouse}(ccell));
    end 
    % determine average trend line for size vs distance 
    includeX =~ isnan(sizeDistArray(:,1)); includeY =~ isnan(sizeDistArray(:,2));
    % make incude XY that has combined 0 locs 
    [zeroRow, ~] = find(includeY == 0);
    includeX(zeroRow) = 0; includeXY = includeX;                
    sizeDistX = sizeDistArray(:,1); sizeDistY = sizeDistArray(:,2);   
    if length(find(includeXY)) > 1
        fav = fitlm(sizeDistX(includeXY),sizeDistY(includeXY),'poly1');
    end 
    
    clear ampDistArray includeX includY includeXY
    fAmp = cell(1,length(terminals{mouse}));
    for ccell = 1:length(terminals{mouse})
        if ccell == 1 
            if exist('minACdists','var')
                ampDistArray(:,1) = minACdists(ccell,:);
            end 
            ampDistArray(:,2) = clustAmp(ccell,:);
            ampDistArray(:,3) = ccell;       
            % determine trend line 
            includeX =~ isnan(ampDistArray(:,1)); includeY =~ isnan(ampDistArray(:,2));
            % make incude XY that has combined 0 locs 
            [zeroRow, ~] = find(includeY == 0);
            includeX(zeroRow) = 0; includeXY = includeX;                
            ampDistX = ampDistArray(:,1); ampDistY = ampDistArray(:,2);  
            if sum(includeXY) > 1 
                fAmp{ccell} = fit(ampDistX(includeXY),ampDistY(includeXY),'poly1');  
            end 
        elseif ccell > 1 
            if ccell == 2
                len = size(ampDistArray,1);   
            end 
            len2 = size(ampDistArray,1);       
            if exist('minACdists','var')
                ampDistArray(len2+1:len2+len,1) = minACdists(ccell,:);
            end 
            ampDistArray(len2+1:len2+len,2) = clustAmp(ccell,:);
            ampDistArray(len2+1:len2+len,3) = ccell;                  
            % determine trend line 
            includeX =~ isnan(ampDistArray(len2+1:len2+len,1)); includeY =~ isnan(ampDistArray(len2+1:len2+len,2));
            % make incude XY that has combined 0 locs 
            [zeroRow, ~] = find(includeY == 0);
            includeX(zeroRow) = 0; includeXY = includeX;                
            ampDistX = ampDistArray(len2+1:len2+len,1); ampDistY = ampDistArray(len2+1:len2+len,2);   
            if sum(includeXY) > 1 
                fAmp{ccell} = fit(ampDistX(includeXY),ampDistY(includeXY),'poly1');
            end 
        end 
    end 
    % determine average trend line for size vs distance 
    includeX =~ isnan(ampDistArray(:,1)); includeY =~ isnan(ampDistArray(:,2));
    % make incude XY that has combined 0 locs 
    [zeroRow, ~] = find(includeY == 0);
    includeX(zeroRow) = 0; includeXY = includeX;                
    ampDistX = ampDistArray(:,1); ampDistY = ampDistArray(:,2);   
    if length(find(includeXY)) > 1
        fAmpAv = fitlm(ampDistX(includeXY),ampDistY(includeXY),'poly1');
    end 
end 

% determine cluster distance from VR space if you want 
if exist('minACdists','var')
    VRQ = input('Input 1 to determine the distance of each axon from the VR space. ');
    if VRQ == 1 
        drawVRQ = input('Input 1 to draw VR space outline. ');
        if drawVRQ == 1 
            clearvars indsVR VRinds
            figure; imagesc(nanmean(vesChan{terminals{mouse}(1)},3))
            numVR = input('How many VR areas are there?. ');
            for VR = 1:numVR
                if VR == 1
                    vesIm = nanmean(vesChan{terminals{mouse}(1)},3);
                    figure;
                    imshow(vesIm,[0 500])
                    fprintf('Draw the %d VR area.',VR);
                    VRdata = drawfreehand(gca);  % manually draw vessel outline
                    % get VR outline coordinates 
                    VRinds = VRdata.Position;  
                    outLineQ = input(sprintf('Input 1 if you are done drawing the %#d VR outline. ',VR));
                    if outLineQ == 1
                        close all
                    end 
                elseif VR > 1 
                    len = size(VRinds,1);
                    figure;
                    imshow(vesIm,[0 500])
                    fprintf('Draw the %d VR area.',VR);
                    VRdata = drawfreehand(gca);  % manually draw vessel outline
                    % get VR outline coordinates 
                    VRinds2 = VRdata.Position;  
                    outLineQ = input(sprintf('Input 1 if you are done drawing the %#d VR outline. ',VR));
                    if outLineQ == 1
                        close all
                    end 
                    len2 = size(VRinds2,1);
                    VRinds(len+1:len+len2,:) = VRinds2;
                end 
            end 
            len = size(VRinds,1); 
            % convert VR inds to microns 
            VRinds(:,1) = VRinds(:,1)*XpixDist; VRinds(:,2) = VRinds(:,2)*YpixDist;
            for frame = 1:size(im,3)
                if frame == 1 
                    indsVR(:,1:2) = VRinds;
                    indsVR(:,3) = frame;
                elseif frame > 1 
                    len2 = size(indsVR,1);
                    indsVR(len2+1:len2+len,1:2) = VRinds;
                    indsVR(len2+1:len2+len,3) = frame;
                end 
            end 
        end 
        % determine distance of each cluster from the VR space 
        dists = cell(1,max(terminals{mouse}));
        minVRCdists = NaN(length(terminals{mouse}),length(unIdxVals{terminals{mouse}(ccell)}));
        for ccell = 1:length(terminals{mouse})
            for clust = 1:length(unIdxVals{terminals{mouse}(ccell)})
               % find what rows each cluster is located in
                [Crow, ~] = find(idx{terminals{mouse}(ccell)} == unIdxVals{terminals{mouse}(ccell)}(clust)); 
                % identify the x, y, z location of pixels per cluster
                cLocs = inds{terminals{mouse}(ccell)}(Crow,:);  
                % convert cLoc X and Y inds to microns 
                if isempty(cLocs) == 0 
                    cLocs(:,1) = cLocs(:,1)*XpixDist; cLocs(:,2) = cLocs(:,2)*YpixDist; 
                end 
                for VRpoint = 1:size(indsVR,1)
                    for Cpoint = 1:size(cLocs,1)
                        % get euclidean micron distance between each Ca ROI pixel
                        % and BBB cluster pixel 
                        dists{terminals{mouse}(ccell)}{clust}(VRpoint,Cpoint) = sqrt(((cLocs(Cpoint,1)-indsVR(VRpoint,1))^2)+((cLocs(Cpoint,2)-indsVR(VRpoint,2))^2)); 
                    end 
                end 
            end 
        end 
        for ccell = 1:length(terminals{mouse})
            for clust = 1:length(dists{terminals{mouse}(ccell)})
                % determine minimum distance between each Ca ROI and cluster 
                if isempty(dists{terminals{mouse}(ccell)}{clust}) == 0
                    minVRCdists(ccell,clust) = min(min(dists{terminals{mouse}(ccell)}{clust}));
                end 
            end 
        end 
        % make 0s NaNs 
        minVRCdists(minVRCdists == 0) = NaN;
        % resort size and distance data for gscatter 
        if size(minVRCdists,2) < size(clustSize,2)
            minVRCdists(:,size(minVRCdists,2)+1:size(clustSize,2)) = NaN;
        end 
        % resort cluster start time and VR distance data for gscatter 
        clear timeVRDistArray includeX3 includY3 includeXY3
        f3 = cell(1,length(terminals{mouse}));
        for ccell = 1:length(terminals{mouse})
            if ccell == 1 
                timeVRDistArray(:,1) = avClocFrame(ccell,:);
                timeVRDistArray(:,2) = minVRCdists(ccell,:);
                timeVRDistArray(:,3) = ccell;       
                % determine trend line 
                includeX3 =~ isnan(timeVRDistArray(:,1)); includeY3 =~ isnan(timeVRDistArray(:,2));
                % make incude XY that has combined 0 locs 
                [zeroRow, ~] = find(includeY3 == 0);
                includeX3(zeroRow) = 0; includeXY3 = includeX3;                
                timeVRDistX = timeVRDistArray(:,1); timeVRDistY = timeVRDistArray(:,2);  
                if sum(includeXY3) > 1 
                    f3{ccell} = fit(timeVRDistX(includeXY3),timeVRDistY(includeXY3),'poly1');  
                end 
            elseif ccell > 1 
                if ccell == 2
                    len = size(timeVRDistArray,1);   
                end 
                len2 = size(timeVRDistArray,1);       
                timeVRDistArray(len2+1:len2+len,1) = avClocFrame(ccell,:);
                timeVRDistArray(len2+1:len2+len,2) = minVRCdists(ccell,:);
                timeVRDistArray(len2+1:len2+len,3) = ccell;                  
                % determine trend line 
                includeX3 =~ isnan(timeVRDistArray(len2+1:len2+len,1)); includeY3 =~ isnan(timeVRDistArray(len2+1:len2+len,2));
                % make incude XY that has combined 0 locs 
                [zeroRow, ~] = find(includeY3 == 0);
                includeX3(zeroRow) = 0; includeXY3 = includeX3;                
                timeVRDistX = timeVRDistArray(len2+1:len2+len,1); timeVRDistY = timeVRDistArray(len2+1:len2+len,2);   
                if sum(includeXY3) > 1 
                    f3{ccell} = fit(timeVRDistX(includeXY3),timeVRDistY(includeXY3),'poly1');
                end 
            end 
        end 
        % determine average trend line for time vs distance 
        includeX3 =~ isnan(timeVRDistArray(:,1)); includeY3 =~ isnan(timeVRDistArray(:,2));
        % make incude XY that has combined 0 locs 
        [zeroRow, ~] = find(includeY3 == 0);
        includeX3(zeroRow) = 0; includeXY3 = includeX3;                
        timeVRDistX = timeVRDistArray(:,1); timeVRDistY = timeVRDistArray(:,2);   
        if length(find(includeXY3)) > 1
            fav3 = fitlm(timeVRDistX(includeXY3),timeVRDistY(includeXY3),'poly1');
        end 
    end 
elseif ~exist('minACdists','var')
    VRQ = 0;
end 


%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$          
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$  
%% plot distribution of axon distances from the vessel 
if ETAorSTAq == 0 % STA data 
    figure;
    ax=gca;
    histogram(minVAdists,10)
    avVAdists = nanmean(minVAdists); 
    medVAdists = nanmedian(minVAdists); %#ok<*NANMEDIAN>
    avVAdistsLabel = sprintf('Average axon distance from vessel: %.3f',avVAdists);
    medVAdistsLabel = sprintf('Median axon distance from vessel: %.3f',medVAdists);
    ax.FontSize = 15;
    % ax.FontName = 'Times';
    title({'Distribution of Axon Distance from Vessel';avVAdistsLabel;medVAdistsLabel});
    ylabel("Number of Axons")
    xlabel("Distance (microns)") 
end 
%% plot cluster size and pixel amplitude as function of distance from axon
if ETAorSTAq == 0 % STA data 
    figure;
    ax=gca;
    clr = hsv(length(terminals{mouse}));
    gscatter(sizeDistArray(:,1),sizeDistArray(:,2),sizeDistArray(:,3),clr)
    ax.FontSize = 15;
    ax.FontName = 'Times';
    % figure out what axons have clusters to be plotted 
    fullRows = ~isnan(sizeDistArray(:,1));
    axons = unique(sizeDistArray(fullRows,3));
    label = labels(axons);
    legend(label)
    hold all;
    for ccell = 1:length(terminals{mouse})
        fitHandle = plot(f{ccell});
        set(fitHandle,'Color',clr(ccell,:));
    end 
    if length(find(includeXY)) > 1
        fitHandle = plot(fav);
        leg = legend('show');
        set(fitHandle,'Color',[0 0 0],'LineWidth',3);
        leg.String(end) = [];
        rSquared = string(round(fav.Rsquared.Ordinary,2));
        text(200,40000,rSquared,'FontSize',20)
    end 
    ylabel("Size of Cluster (microns squared)")
    xlabel("Distance From Axon (microns)") 
    if clustSpikeQ == 0 
        title('All Clusters');
    elseif clustSpikeQ == 1 
        if clustSpikeQ2 == 0 
            title('Pre Spike Clusters');
        elseif clustSpikeQ2 == 1
            title('Post Spike Clusters');
        end 
    end 
    
    figure;
    ax=gca;
    clr = hsv(length(terminals{mouse}));
    gscatter(ampDistArray(:,1),ampDistArray(:,2),ampDistArray(:,3),clr)
    ax.FontSize = 15;
    ax.FontName = 'Times';
    % figure out what axons have clusters to be plotted 
    fullRows = find(~isnan(ampDistArray(:,1)));
    axons = unique(ampDistArray(fullRows,3));
    label = labels(axons);
    legend(label)
    hold all;
    for ccell = 1:length(terminals{mouse})
        fitHandle = plot(fAmp{ccell});
        set(fitHandle,'Color',clr(ccell,:));
    end 
    if length(find(includeXY)) > 1
        fitHandle = plot(fAmpAv);
        leg = legend('show');
        set(fitHandle,'Color',[0 0 0],'LineWidth',3);
        leg.String(end) = [];
        rSquared = string(round(fAmpAv.Rsquared.Ordinary,2));
        text(220,0.01,rSquared,'FontSize',20)
    end 
    ylabel("Pixel Amplitude of Cluster")
    xlabel("Distance From Axon (microns)") 
    if clustSpikeQ == 0 
        title('All Clusters');
    elseif clustSpikeQ == 1 
        if clustSpikeQ2 == 0 
            title('Pre Spike Clusters');
        elseif clustSpikeQ2 == 1
            title('Post Spike Clusters');
        end 
    end 
end 

%% plot distance from axon and VR space as a function of cluster timing
threshFrame = floor(size(im,3)/2);
if clustSpikeQ == 0 && ETAorSTAq == 0 % STA data 
    figure;
    ax=gca;
    clr = hsv(length(terminals{mouse}));
    gscatter(timeDistArray(:,1),timeDistArray(:,2),timeDistArray(:,3),clr)
    ax.FontSize = 15;
    ax.FontName = 'Times';
    % figure out what axons have clusters to be plotted 
    fullRows = find(~isnan(timeDistArray(:,1)));
    axons = unique(timeDistArray(fullRows,3)); %#ok<FNDSB>
    label = labels(axons);
    legend(label)
    hold on;
    for ccell = 1:length(terminals{mouse})
        fitHandle = plot(f2{ccell});
        set(fitHandle,'Color',clr(ccell,:));
    end 
    if length(find(includeXY)) > 1
        fitHandle = plot(fav2);
        leg = legend('show');
        set(fitHandle,'Color',[0 0 0],'LineWidth',3);
        leg.String(end) = [];
        rSquared = string(round(fav2.Rsquared.Ordinary,2));
        text(27,130,rSquared,'FontSize',20)
    end 
    ylabel("Distance From Axon (microns)")
    if clustSpikeQ3 == 0 
        xlabel("Average BBB Plume Timing") 
    elseif clustSpikeQ3 == 1
        xlabel("BBB Plume Start Time") 
    end 
    title('BBB Plume Distance From Axon Compared to Timing');
    Frames = size(im,3);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
    FrameVals(3) = threshFrame;
    FrameVals(2) = threshFrame - (Frames/5);
    FrameVals(1) = FrameVals(2) - (Frames/5);
    FrameVals(4) = threshFrame + (Frames/5);
    FrameVals(5) = FrameVals(4) + (Frames/5); 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  

    figure;
    ax=gca;
    clr = hsv(length(terminals{mouse}));
    gscatter(timeODistArray(:,1),timeODistArray(:,2),timeODistArray(:,3),clr)
    ax.FontSize = 15;
    ax.FontName = 'Times';
    % figure out what axons have clusters to be plotted 
    fullRows = find(~isnan(timeODistArray(:,1)));
    axons = unique(timeODistArray(fullRows,3));
    label = labels(axons);
    legend(label)
    hold on;
    for ccell = 1:length(terminals{mouse})
        fitHandle = plot(f2O{ccell});
        set(fitHandle,'Color',clr(ccell,:));
    end 
    if length(find(includeXY)) > 1
        fitHandle = plot(fav2O);
        leg = legend('show');
        set(fitHandle,'Color',[0 0 0],'LineWidth',3);
        leg.String(end) = [];
        rSquared = string(round(fav2O.Rsquared.Ordinary,2));
        text(27,380,rSquared,'FontSize',20)
    end 
    ylabel("Distance From Axon (microns)")
    if clustSpikeQ3 == 0 
        xlabel("Average BBB Plume Timing") 
    elseif clustSpikeQ3 == 1
        xlabel("BBB Plume Start Time") 
    end 
    title('BBB Plume Origin Distance From Axon Compared to Timing');
    Frames = size(im,3);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
    FrameVals(3) = threshFrame;
    FrameVals(2) = threshFrame - (Frames/5);
    FrameVals(1) = FrameVals(2) - (Frames/5);
    FrameVals(4) = threshFrame + (Frames/5);
    FrameVals(5) = FrameVals(4) + (Frames/5); 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
end 

if VRQ == 1
    if clustSpikeQ == 0 
        figure;
        ax=gca;
        clr = hsv(length(terminals{mouse}));
        gscatter(timeVRDistArray(:,1),timeVRDistArray(:,2),timeVRDistArray(:,3),clr)
        ax.FontSize = 15;
        ax.FontName = 'Times';
        % figure out what axons have clusters to be plotted 
        fullRows = find(~isnan(timeVRDistArray(:,1)));
        axons = unique(timeVRDistArray(fullRows,3));
        label = labels(axons);
        legend(label)
        hold all;
        for ccell = 1:length(terminals{mouse})
            fitHandle = plot(f3{ccell});
            set(fitHandle,'Color',clr(ccell,:));
        end 
        if length(find(includeXY3)) > 1
            fitHandle = plot(fav3);
            leg = legend('show');
            set(fitHandle,'Color',[0 0 0],'LineWidth',3);
            leg.String(end) = [];
            rSquared = string(round(fav3.Rsquared.Ordinary,2));
            text(30,18,rSquared,'FontSize',20)
        end 
        ylabel("Distance From VR space (microns)")
        if dlightQ == 0 % BBB data 
            title('BBB Plume Distance From VR Space Compared to Timing');
            if clustSpikeQ3 == 0 
                xlabel("Average BBB Plume Timing") 
            elseif clustSpikeQ3 == 1
                xlabel("BBB Plume Start Time") 
            end 
        elseif dlightQ == 1 % dlight data
            title('dlight Distance From VR Space Compared to Timing');
            if clustSpikeQ3 == 0 
                xlabel("Average dlight Timing") 
            elseif clustSpikeQ3 == 1
                xlabel("dlight Start Time") 
            end             
        end 
        Frames = size(im,3);
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
        FrameVals(3) = threshFrame;
        FrameVals(2) = threshFrame - (Frames/5);
        FrameVals(1) = FrameVals(2) - (Frames/5);
        FrameVals(4) = threshFrame + (Frames/5);
        FrameVals(5) = FrameVals(4) + (Frames/5);
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;  
    end 
end 

%% plot distribution of cluster sizes and pixel amplitudes
figure;
ax=gca;
avClustSize = nanmean(clustSize); 
medClustSize = nanmedian(clustSize); %#ok<*NANMEDIAN> 
avClustSizeLabel = sprintf('Average cluster size: %.0f',avClustSize);
medClustSizeLabel = sprintf('Median cluster size: %.0f',medClustSize);
histogram(clustSize,100)
ax.FontSize = 15;
% ax.FontName = 'Times';
if dlightQ == 0 % BBB data 
    if clustSpikeQ == 0 
        title({'Distribution of BBB Plume Sizes';'All Clusters';avClustSizeLabel;medClustSizeLabel});
    elseif clustSpikeQ == 1 
        if clustSpikeQ2 == 0 
            title({'Distribution of BBB Plume Sizes';'Pre-Spike Clusters';avClustSizeLabel;medClustSizeLabel});
        elseif clustSpikeQ2 == 1
            title({'Distribution of BBB Plume Sizes';'Post-Spike Clusters';avClustSizeLabel;medClustSizeLabel});
        end 
    end 
elseif dlightQ == 1 % dlight data
    if clustSpikeQ == 0 
        title({'Distribution of dlight Sizes';'All Clusters';avClustSizeLabel;medClustSizeLabel});
    elseif clustSpikeQ == 1 
        if clustSpikeQ2 == 0 
            title({'Distribution of dlight Sizes';'Pre-Spike Clusters';avClustSizeLabel;medClustSizeLabel});
        elseif clustSpikeQ2 == 1
            title({'Distribution of dlight Sizes';'Post-Spike Clusters';avClustSizeLabel;medClustSizeLabel});
        end 
    end     
end 
if dlightQ == 0 % BBB data 
    ylabel("Number of BBB Plumes")
    xlabel("Size of BBB Plume (microns squared)") 
elseif dlightQ == 1 % dlight data
    ylabel("Number of dlight Clusters")
    xlabel("Size of dlight Clusters (microns squared)") 
end 


figure;
ax=gca;
histogram(clustAmp,100)
avClustAmp = nanmean(clustAmp); 
medClustAmp = nanmedian(clustAmp); %#ok<*NANMEDIAN> 
avClustAmpLabel = sprintf('Average cluster pixel amplitude: %.3f',avClustAmp);
medClustAmpLabel = sprintf('Median cluster pixel amplitude: %.3f',medClustAmp);
ax.FontSize = 15;
% ax.FontName = 'Times';
if dlightQ == 0 % BBB data 
    if clustSpikeQ == 0 
        title({'Distribution of BBB Plume Pixel Amplitudes';'All Clusters';avClustAmpLabel;medClustAmpLabel});
    elseif clustSpikeQ == 1 
        if clustSpikeQ2 == 0 
            title({'Distribution of BBB Plume Pixel Amplitudes';'Pre-Spike Clusters';avClustAmpLabel;medClustAmpLabel});
        elseif clustSpikeQ2 == 1
            title({'Distribution of BBB Plume Pixel Amplitudes';'Post-Spike Clusters';avClustAmpLabel;medClustAmpLabel});
        end 
    end     
elseif dlightQ == 1 % dlight data
    if clustSpikeQ == 0 
        title({'Distribution of dlight Pixel Amplitudes';'All Clusters';avClustAmpLabel;medClustAmpLabel});
    elseif clustSpikeQ == 1 
        if clustSpikeQ2 == 0 
            title({'Distribution of dlight Pixel Amplitudes';'Pre-Spike Clusters';avClustAmpLabel;medClustAmpLabel});
        elseif clustSpikeQ2 == 1
            title({'Distribution of dlight Pixel Amplitudes';'Post-Spike Clusters';avClustAmpLabel;medClustAmpLabel});
        end 
    end     
end 
if dlightQ == 0 % BBB data 
    ylabel("Number of BBB Plumes")
    xlabel("BBB Plume Pixel Amplitudes")     
elseif dlightQ == 1 % dlight data
    ylabel("Number of dlight Clusters")
    xlabel("dlight Pixel Amplitudes")     
end 



%% plot distribution of cluster times
if ~exist('FrameVals','var')
    Frames = size(im,3);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
    FrameVals(3) = threshFrame;
    FrameVals(2) = threshFrame - (Frames/5);
    FrameVals(1) = FrameVals(2) - (Frames/5);
    FrameVals(4) = threshFrame + (Frames/5);
    FrameVals(5) = FrameVals(4) + (Frames/5);
end 
if clustSpikeQ == 0 
    figure;
    ax=gca;
    histogram(avClocFrame,20)
    ax.FontSize = 15;
%     ax.FontName = 'Times';
    if dlightQ == 0 % BBB data
        if clustSpikeQ3 == 0 
            title({'Distribution of BBB Plume Timing';'Average Time'});
        elseif clustSpikeQ3 == 1
            title({'Distribution of BBB Plume Timing';'Start Time'});
        end        
        ylabel("Number of BBB Plumes")
    elseif dlightQ == 1 % dlight data
        if clustSpikeQ3 == 0 
            title({'Distribution of dlight Timing';'Average Time'});
        elseif clustSpikeQ3 == 1
            title({'Distribution of dlight Timing';'Start Time'});
        end      
        ylabel("Number of dlight Clusters")
    end 
    xlabel("Time (s)") 
    Frames = size(im,3);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
    % FrameVals = round((1:FPSstack{mouse}:Frames))+5;
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    % plot pie chart of before vs after spike cluster start times
    numPreSpikeStarts = nansum(nansum(avClocFrame < threshFrame));
    numPostSpikeStarts = nansum(nansum(avClocFrame >= threshFrame));
    preVsPostSpikeStarts = [numPreSpikeStarts,numPostSpikeStarts];
    figure; 
    p = pie(preVsPostSpikeStarts);
    colormap([0 0.4470 0.7410; 0.8500 0.3250 0.0980])
    if ETAorSTAq == 0 % STA data
        legend('Pre-spike clusters','Post-spike clusters')
    elseif ETAorSTAq == 1 % ETA data
        if ETAtype == 0 % opto data 
            legend('Pre-opto clusters','Post-opto clusters')
        elseif ETAtype == 1 % behavior data 
            if ETAtype2 == 0 % stim aligned 
                legend('Pre-stim clusters','Post-stim clusters')
            elseif ETAtype2 == 1 % reward aligned 
                legend('Pre-reward clusters','Post-reward clusters')
            end 
        end 
    end 
    ax=gca; ax.FontSize = 15;
    t1 = p(4); t2 = p(2);
    t1.FontSize = 15; t2.FontSize = 15;

    if ETAorSTAq == 0 % STA data
        for ccell = 1:length(terminals{mouse})
            % plot pie chart of before vs after spike cluster start times per
            % axon 
            threshFrame = floor(size(im,3)/2);
            numPreSpikeStarts(ccell) = nansum(nansum(avClocFrame(ccell,:) < threshFrame));
            numPostSpikeStarts(ccell) = nansum(nansum(avClocFrame(ccell,:) >= threshFrame));
            preVsPostSpikeStarts = [numPreSpikeStarts(ccell),numPostSpikeStarts(ccell)];
            figure; 
            p = pie(preVsPostSpikeStarts);
            colormap([0 0.4470 0.7410; 0.8500 0.3250 0.0980])
            if ETAorSTAq == 0 % STA data
                legend('Pre-spike clusters','Post-spike clusters')
            elseif ETAorSTAq == 1 % ETA data
                if ETAtype == 0 % opto data 
                    legend('Pre-opto clusters','Post-opto clusters')
                elseif ETAtype == 1 % behavior data 
                    if ETAtype2 == 0 % stim aligned 
                        legend('Pre-stim clusters','Post-stim clusters')
                    elseif ETAtype2 == 1 % reward aligned 
                        legend('Pre-reward clusters','Post-reward clusters')
                    end 
                end 
            end 
            ax=gca; ax.FontSize = 15;
            t1 = p(4); t2 = p(2);
            t1.FontSize = 15; t2.FontSize = 15;
            title(sprintf('Axon %d.',terminals{mouse}(ccell)))
        end 
    
        % create pie chart showing number of axons that are mostly pre, mostly
        % post, and evenly split 
        figure;
        totalClusts = numPreSpikeStarts + numPostSpikeStarts;
        preSpikeRatio = numPreSpikeStarts./totalClusts;
        numMostlyPre = sum(preSpikeRatio > 0.5);
        numMostlyPost = sum(preSpikeRatio < 0.5);
        evenPreAndPost = sum(preSpikeRatio == 0.5);
        axonTypes = [numMostlyPre,evenPreAndPost,numMostlyPost];
        p = pie(axonTypes);
        colormap([0 0.4470 0.7410; 0.4250 0.386 0.4195; 0.8500 0.3250 0.0980])
        legend('Listener','Even-Split','Controller')
        ax=gca; ax.FontSize = 15;
        t1 = p(2); t2 = p(4); t3 = p(6);
        t1.FontSize = 15; t2.FontSize = 15; t3.FontSize = 15;
    end 
end 

%% create scatter over box plot of cluster timing per axon
if clustSpikeQ == 0 % if all the spikes are available to look at 
    clear ClocTimeForPlot
    ClocTimeForPlot = avClocFrame';    
    figure;
    ax=gca;
    % plot box plot 
    boxchart(ClocTimeForPlot,'MarkerStyle','none');
    % create the x data needed to overlay the swarmchart on the boxchart 
    x = repmat(1:size(ClocTimeForPlot,2),size(ClocTimeForPlot,1),1);
    % plot swarm chart on top of box plot 
    hold all;
    swarmchart(x,ClocTimeForPlot,[],'red')  
    yline(threshFrame)
    ax.FontSize = 15;
    ax.FontName = 'Times';
    if ETAorSTAq == 0 % STA data
        xlabel("Axon")
    end 
    if dlightQ == 0 % BBB data 
        ylabel("Average BBB Plume Timing")
        if ETAorSTAq == 0 % STA data
            if clustSpikeQ3 == 0
                title({'BBB Plume Timing By Axon';'Average Cluster Time'});
            elseif clustSpikeQ3 == 1
                title({'BBB Plume Timing By Axon';'Cluster Start Time'});
            end     
        elseif ETAorSTAq == 1 % ETA data
            set(gca,'XTick',[]) % removes x axis ticks
            if clustSpikeQ3 == 0
                title({'BBB Plume Timing';'Average Cluster Time'});
            elseif clustSpikeQ3 == 1
                title({'BBB Plume Timing';'Cluster Start Time'});
            end   
        end         
    elseif dlightQ == 1 % dlight data
        ylabel("Average dlight Timing")
        if ETAorSTAq == 0 % STA data
            if clustSpikeQ3 == 0
                title({'dlight Timing By Axon';'Average Cluster Time'});
            elseif clustSpikeQ3 == 1
                title({'dlight Timing By Axon';'Cluster Start Time'});
            end     
        elseif ETAorSTAq == 1 % ETA data
            set(gca,'XTick',[]) % removes x axis ticks
            if clustSpikeQ3 == 0
                title({'dlight Timing';'Average Cluster Time'});
            elseif clustSpikeQ3 == 1
                title({'dlight Timing';'Cluster Start Time'});
            end   
        end         
    end 
    xticklabels(labels)
    Frames = size(im,3);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
    % FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
    ax.YTick = FrameVals;
    ax.YTickLabel = sec_TimeVals;  
end 

%% plot cluster size and pixel amp grouped by pre and post spike
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
if clustSpikeQ == 0
    clearvars data
    CsizeForPlot = clustSize';
    figure;
    ax=gca;
    % plot box plot 
    boxchart(CsizeForPlot,'MarkerStyle','none');
    % create the x data needed to overlay the swarmchart on the boxchart 
    x = repmat(1:length(terminals{mouse}),size(CsizeForPlot,1),1);
    % plot swarm chart on top of box plot 
    hold all;
    swarmchart(x,CsizeForPlot,[],'red')  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    if dlightQ == 0 % BBB data 
        ylabel("BBB Plume Size (microns squared)")
        if ETAorSTAq == 0 % STA data
            xlabel("Axon")  
            title({'BBB Plume Size By Axon';'All Plumes'});
        elseif ETAorSTAq == 1 % ETA data
            set(gca,'XTick',[]) % removes x axis ticks
            title({'BBB Plume Size';'All Plumes'});
        end         
    elseif dlightQ == 1 % dlight data
        ylabel("dlight Cluster Size (microns squared)")
        if ETAorSTAq == 0 % STA data
            xlabel("Axon")  
            title({'dlight Cluster Size By Axon';'All Plumes'});
        elseif ETAorSTAq == 1 % ETA data
            set(gca,'XTick',[]) % removes x axis ticks
            title({'dlight Cluster Size';'All Plumes'});
        end         
    end 
    xticklabels(labels)
    set(gca, 'YScale', 'log')

    CampForPlot = clustAmp';
    figure;
    ax=gca;
    % plot box plot 
    boxchart(CampForPlot,'MarkerStyle','none');
    % create the x data needed to overlay the swarmchart on the boxchart 
    x = repmat(1:length(terminals{mouse}),size(CampForPlot,1),1);
    % plot swarm chart on top of box plot 
    hold all;
    swarmchart(x,CampForPlot,[],'red')  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    if dlightQ == 0 % BBB data 
        ylabel("BBB Plume Pixel Amplitude")
        if ETAorSTAq == 0 % STA data
            xlabel("Axon")  
            title({'BBB Plume Pixel Amplitude By Axon';'All Plumes'});
        elseif ETAorSTAq == 1 % ETA data
            set(gca,'XTick',[]) % removes x axis ticks
            title({'BBB Plume Pixel Amplitude';'All Plumes'});
        end         
    elseif dlightQ == 1 % dlight data
        ylabel("dlight Pixel Amplitude")
        if ETAorSTAq == 0 % STA data
            xlabel("Axon")  
            title({'dlight Pixel Amplitude By Axon';'All Plumes'});
        elseif ETAorSTAq == 1 % ETA data
            set(gca,'XTick',[]) % removes x axis ticks
            title({'dlight Pixel Amplitude';'All Plumes'});
        end         
    end 
    xticklabels(labels)
%     set(gca, 'YScale', 'log')

elseif clustSpikeQ == 1 

    preOrPost = input('Input 0 to update pre-spike array. Input 1 to update post-spike array. ');
    if preOrPost == 0
        CsizeForPlotPre = clustSize'; 
        CampForPlotPre = clustAmp'; 
    elseif preOrPost == 1 
        CsizeForPlotPost = clustSize'; 
        CampForPlotPost = clustAmp'; 
    end 
    preAndPostQ = input('Are both pre and post-spike arrays updated? Input 1 for yes. 0 for no. ');
    if preAndPostQ == 1 
        figure;
        ax=gca;
        % plot box plot 
        boxchart(CsizeForPlotPre,'MarkerStyle','none','BoxFaceColor','r','WhiskerLineColor','r');
        % plot swarm chart on top of box plot 
        hold all;
        boxchart(CsizeForPlotPost,'MarkerStyle','none','BoxFaceColor','b','WhiskerLineColor','b');
        ax.FontSize = 15;
        ax.FontName = 'Times';
        if ETAorSTAq == 0 % STA data
            xlabel("Axon")
        end 
        set(gca, 'YScale', 'log')
        if dlightQ == 0 % BBB data 
            ylabel("BBB Plume Size (microns squared)")
            if ETAorSTAq == 0 % STA data
                if clustSpikeQ3 == 0 
                    title({'BBB Plume Size By Axon';'Pre And Post Spike Plumes';'Average Cluster Time'});   
                elseif clustSpikeQ3 == 1
                    title({'BBB Plume Size By Axon';'Pre And Post Spike Plumes';'Cluster Start Time'});   
                end          
            elseif ETAorSTAq == 1 % ETA data
                if ETAtype == 0 % opto data 
                    if clustSpikeQ3 == 0 
                        title({'BBB Plume Size';'Pre And Post Opto Plumes';'Average Cluster Time'});   
                    elseif clustSpikeQ3 == 1
                        title({'BBB Plume Size';'Pre And Post Opto Plumes';'Cluster Start Time'});   
                    end  
                elseif ETAtype == 1 % behavior data 
                    if ETAtype2 == 0 % stim aligned 
                        if clustSpikeQ3 == 0 
                            title({'BBB Plume Size';'Pre And Post Stim Plumes';'Average Cluster Time'});   
                        elseif clustSpikeQ3 == 1
                            title({'BBB Plume Size';'Pre And Post Stim Plumes';'Cluster Start Time'});   
                        end  
                    elseif ETAtype2 == 1 % reward aligned 
                        if clustSpikeQ3 == 0 
                            title({'BBB Plume Size';'Pre And Post Reward Plumes';'Average Cluster Time'});   
                        elseif clustSpikeQ3 == 1
                            title({'BBB Plume Size';'Pre And Post Reward Plumes';'Cluster Start Time'});   
                        end                    
                    end 
                end 
            end 
            if ETAorSTAq == 0 % STA data 
                legend("Pre-Spike BBB Plume","Post-Spike BBB Plume")
            elseif ETAorSTAq == 1 % ETA data
                set(gca,'XTick',[]) % removes x axis ticks 
                if ETAtype == 0 % opto data 
                  legend("Pre-Opto BBB Plume","Post-Opto BBB Plume")
                elseif ETAtype == 1 % behavior data 
                    if ETAtype2 == 0 % stim aligned 
                        legend("Pre-Stim BBB Plume","Post-Stim BBB Plume")
                    elseif ETAtype2 == 1 % reward aligned 
                        legend("Pre-Reward BBB Plume","Post-Reward BBB Plume")
                    end 
                end 
            end
        elseif dlightQ == 1 % dlight data
            ylabel("dlight Size (microns squared)")
            if ETAorSTAq == 0 % STA data
                if clustSpikeQ3 == 0 
                    title({'dlight Size By Axon';'Pre And Post Spike Clusters';'Average Cluster Time'});   
                elseif clustSpikeQ3 == 1
                    title({'dlight Size By Axon';'Pre And Post Spike Clusters';'Cluster Start Time'});   
                end          
            elseif ETAorSTAq == 1 % ETA data
                if ETAtype == 0 % opto data 
                    if clustSpikeQ3 == 0 
                        title({'dlight Size';'Pre And Post Opto Clusters';'Average Cluster Time'});   
                    elseif clustSpikeQ3 == 1
                        title({'dlight Size';'Pre And Post Opto Clusters';'Cluster Start Time'});   
                    end  
                elseif ETAtype == 1 % behavior data 
                    if ETAtype2 == 0 % stim aligned 
                        if clustSpikeQ3 == 0 
                            title({'dlight Size';'Pre And Post Stim Clusters';'Average Cluster Time'});   
                        elseif clustSpikeQ3 == 1
                            title({'dlight Size';'Pre And Post Stim Clusters';'Cluster Start Time'});   
                        end  
                    elseif ETAtype2 == 1 % reward aligned 
                        if clustSpikeQ3 == 0 
                            title({'dlight Size';'Pre And Post Reward Clusters';'Average Cluster Time'});   
                        elseif clustSpikeQ3 == 1
                            title({'dlight Size';'Pre And Post Reward Clusters';'Cluster Start Time'});   
                        end                    
                    end 
                end 
            end 
            if ETAorSTAq == 0 % STA data 
                legend("Pre-Spike dlight","Post-Spike dlight")
            elseif ETAorSTAq == 1 % ETA data
                set(gca,'XTick',[]) % removes x axis ticks 
                if ETAtype == 0 % opto data 
                  legend("Pre-Opto dlight","Post-Opto dlight")
                elseif ETAtype == 1 % behavior data 
                    if ETAtype2 == 0 % stim aligned 
                        legend("Pre-Stim dlight","Post-Stim dlight")
                    elseif ETAtype2 == 1 % reward aligned 
                        legend("Pre-Reward dlight","Post-Reward dlight")
                    end 
                end 
            end            
        end 
        if dlightQ == 0 % BBB data 
            xticklabels(labels)   
        end 

        figure;
        ax=gca;
        % plot box plot 
        boxchart(CampForPlotPre,'MarkerStyle','none','BoxFaceColor','r','WhiskerLineColor','r');
        % plot swarm chart on top of box plot 
        hold all;
        boxchart(CampForPlotPost,'MarkerStyle','none','BoxFaceColor','b','WhiskerLineColor','b');
        ax.FontSize = 15;
        ax.FontName = 'Times';
        if ETAorSTAq == 0 % STA data
            xlabel("Axon")
        end 
        if dlightQ == 0 % BBB data
            ylabel("BBB Plume Pixel Amplitude")
            if ETAorSTAq == 0 % STA data
                if clustSpikeQ3 == 0 
                    title({'BBB Plume Pixel Amplitude By Axon';'Pre And Post Spike Plumes';'Average Cluster Time'});   
                elseif clustSpikeQ3 == 1
                    title({'BBB Plume Pixel Amplitude By Axon';'Pre And Post Spike Plumes';'Cluster Start Time'});   
                end          
            elseif ETAorSTAq == 1 % ETA data
                if ETAtype == 0 % opto data 
                    if clustSpikeQ3 == 0 
                        title({'BBB Plume Pixel Amplitude';'Pre And Post Opto Plumes';'Average Cluster Time'});   
                    elseif clustSpikeQ3 == 1
                        title({'BBB Plume Pixel Amplitude';'Pre And Post Opto Plumes';'Cluster Start Time'});   
                    end      
                elseif ETAtype == 1 % behavior data 
                    if ETAtype2 == 0 % stim aligned 
                        if clustSpikeQ3 == 0 
                            title({'BBB Plume Pixel Amplitude';'Pre And Post Stim Plumes';'Average Cluster Time'});   
                        elseif clustSpikeQ3 == 1
                            title({'BBB Plume Pixel Amplitude';'Pre And Post Stim Plumes';'Cluster Start Time'});   
                        end    
                    elseif ETAtype2 == 1 % reward aligned 
                         if clustSpikeQ3 == 0 
                            title({'BBB Plume Pixel Amplitude';'Pre And Post Reward Plumes';'Average Cluster Time'});   
                        elseif clustSpikeQ3 == 1
                            title({'BBB Plume Pixel Amplitude';'Pre And Post Reward Plumes';'Cluster Start Time'});   
                        end                    
                    end 
                end 
            end 
            if ETAorSTAq == 0 % STA data 
                legend("Pre-Spike BBB Plume","Post-Spike BBB Plume")
            elseif ETAorSTAq == 1 % ETA data
                set(gca,'XTick',[]) % removes x axis ticks
                if ETAtype == 0 % opto data 
                  legend("Pre-Opto BBB Plume","Post-Opto BBB Plume")
                elseif ETAtype == 1 % behavior data 
                    if ETAtype2 == 0 % stim aligned 
                        legend("Pre-Stim BBB Plume","Post-Stim BBB Plume")
                    elseif ETAtype2 == 1 % reward aligned 
                        legend("Pre-Reward BBB Plume","Post-Reward BBB Plume")
                    end 
                end 
            end
        elseif dlightQ == 1 % dlight data
            ylabel("dlight Pixel Amplitude")
            if ETAorSTAq == 0 % STA data
                if clustSpikeQ3 == 0 
                    title({'dlight Pixel Amplitude By Axon';'Pre And Post Spike Clusters';'Average Cluster Time'});   
                elseif clustSpikeQ3 == 1
                    title({'dlight Pixel Amplitude By Axon';'Pre And Post Spike Clusters';'Cluster Start Time'});   
                end          
            elseif ETAorSTAq == 1 % ETA data
                if ETAtype == 0 % opto data 
                    if clustSpikeQ3 == 0 
                        title({'dlight Pixel Amplitude';'Pre And Post Opto Clusters';'Average Cluster Time'});   
                    elseif clustSpikeQ3 == 1
                        title({'dlight Pixel Amplitude';'Pre And Post Opto Clusters';'Cluster Start Time'});   
                    end      
                elseif ETAtype == 1 % behavior data 
                    if ETAtype2 == 0 % stim aligned 
                        if clustSpikeQ3 == 0 
                            title({'dlight Pixel Amplitude';'Pre And Post Stim Clusters';'Average Cluster Time'});   
                        elseif clustSpikeQ3 == 1
                            title({'dlight Pixel Amplitude';'Pre And Post Stim Clusters';'Cluster Start Time'});   
                        end    
                    elseif ETAtype2 == 1 % reward aligned 
                         if clustSpikeQ3 == 0 
                            title({'dlight Pixel Amplitude';'Pre And Post Reward Clusters';'Average Cluster Time'});   
                        elseif clustSpikeQ3 == 1
                            title({'dlight Pixel Amplitude';'Pre And Post Reward Clusters';'Cluster Start Time'});   
                        end                    
                    end 
                end 
            end 
            if ETAorSTAq == 0 % STA data 
                legend("Pre-Spike dlight","Post-Spike dlight")
            elseif ETAorSTAq == 1 % ETA data
                set(gca,'XTick',[]) % removes x axis ticks
                if ETAtype == 0 % opto data 
                  legend("Pre-Opto dlight","Post-Opto dlight")
                elseif ETAtype == 1 % behavior data 
                    if ETAtype2 == 0 % stim aligned 
                        legend("Pre-Stim dlight","Post-Stim dlight")
                    elseif ETAtype2 == 1 % reward aligned 
                        legend("Pre-Reward dlight","Post-Reward dlight")
                    end 
                end 
            end            
        end 
        if dlightQ == 0 % BBB data
            xticklabels(labels) 
        end 
    end 
end 

if  clustSpikeQ == 1 
    if preAndPostQ == 1 
        % reshape data to plot box and whisker plots 
        reshapedPrePlot = reshape(CsizeForPlotPre,size(CsizeForPlotPre,1)*size(CsizeForPlotPre,2),1);
        reshapedPostPlot = reshape(CsizeForPlotPost,size(CsizeForPlotPost,1)*size(CsizeForPlotPost,2),1);
        data(:,1) = reshapedPrePlot; data(:,2) = reshapedPostPlot;
        figure;
        ax=gca;
        % plot box plot 
        boxchart(data,'MarkerStyle','none','BoxFaceColor','k','WhiskerLineColor','k');
        % plot swarm chart on top of box plot 
        hold all;
        x = repmat(1:size(data,2),size(data,1),1);
        swarmchart(x,data,[],'red') 
        % boxchart(reshapedPostPlot,'MarkerStyle','none','BoxFaceColor','b','WhiskerLineColor','b');
        ax.FontSize = 15;
        ax.FontName = 'Times';
        set(gca, 'YScale', 'log')
        if dlightQ == 0 % BBB data 
            ylabel("BBB Plume Size (microns squared)") 
            if ETAorSTAq == 0 % STA data
                if clustSpikeQ3 == 0 
                    title({'BBB Plume Size By Axon';'Pre And Post Spike Plumes';'Averaged Across Axons';'Average Cluster Time'});  
                elseif clustSpikeQ3 == 1
                    title({'BBB Plume Size By Axon';'Pre And Post Spike Plumes';'Averaged Across Axons';'Cluster Start Time'});  
                end     
            elseif ETAorSTAq == 1 % ETA data
                if ETAtype == 0 % opto data 
                    if clustSpikeQ3 == 0 
                        title({'BBB Plume Size';'Pre And Post Opto Plumes';'Average Cluster Time'});  
                    elseif clustSpikeQ3 == 1
                        title({'BBB Plume Size';'Pre And Post Opto Plumes';'Cluster Start Time'});  
                    end    
                elseif ETAtype == 1 % behavior data 
                    if ETAtype2 == 0 % stim aligned 
                        if clustSpikeQ3 == 0 
                            title({'BBB Plume Size';'Pre And Post Stim Plumes';'Average Cluster Time'});  
                        elseif clustSpikeQ3 == 1
                            title({'BBB Plume Size';'Pre And Post Stim Plumes';'Cluster Start Time'});  
                        end  
                    elseif ETAtype2 == 1 % reward aligned 
                         if clustSpikeQ3 == 0 
                            title({'BBB Plume Size';'Pre And Post Reward Plumes';'Average Cluster Time'});  
                        elseif clustSpikeQ3 == 1
                            title({'BBB Plume Size';'Pre And Post Reward Plumes';'Cluster Start Time'});  
                        end                     
                    end 
                end          
            end             
        elseif dlightQ == 1 % dlight data
            ylabel("dlight Size (microns squared)") 
            if ETAorSTAq == 0 % STA data
                if clustSpikeQ3 == 0 
                    title({'dlight Size By Axon';'Pre And Post Spike Clusters';'Averaged Across Axons';'Average Cluster Time'});  
                elseif clustSpikeQ3 == 1
                    title({'dlight Size By Axon';'Pre And Post Spike Clusters';'Averaged Across Axons';'Cluster Start Time'});  
                end     
            elseif ETAorSTAq == 1 % ETA data
                if ETAtype == 0 % opto data 
                    if clustSpikeQ3 == 0 
                        title({'dlight Size';'Pre And Post Opto Clusters';'Average Cluster Time'});  
                    elseif clustSpikeQ3 == 1
                        title({'dlight Size';'Pre And Post Opto Clusters';'Cluster Start Time'});  
                    end    
                elseif ETAtype == 1 % behavior data 
                    if ETAtype2 == 0 % stim aligned 
                        if clustSpikeQ3 == 0 
                            title({'dlight Size';'Pre And Post Stim Clusters';'Average Cluster Time'});  
                        elseif clustSpikeQ3 == 1
                            title({'dlight Size';'Pre And Post Stim Clusters';'Cluster Start Time'});  
                        end  
                    elseif ETAtype2 == 1 % reward aligned 
                         if clustSpikeQ3 == 0 
                            title({'dlight Size';'Pre And Post Reward Clusters';'Average Cluster Time'});  
                        elseif clustSpikeQ3 == 1
                            title({'dlight Size';'Pre And Post Reward Clusters';'Cluster Start Time'});  
                        end                     
                    end 
                end          
            end             
        end 
        if ETAorSTAq == 0 % STA data 
            avLabels = ["Pre-Spike","Post-Spike"];
        elseif ETAorSTAq == 1 % ETA data
              if ETAtype == 0 % opto data 
                  avLabels = ["Pre-Opto","Post-Opto"];
              elseif ETAtype == 1 % behavior data 
                    if ETAtype2 == 0 % stim aligned 
                        avLabels = ["Pre-Stim","Post-Stim"];
                    elseif ETAtype2 == 1 % reward aligned 
                        avLabels = ["Pre-Reward","Post-Reward"];
                    end 
              end 
        end 
        xticklabels(avLabels)

        % reshape data to plot box and whisker plots 
        reshapedPrePlot = reshape(CampForPlotPre,size(CampForPlotPre,1)*size(CampForPlotPre,2),1);
        reshapedPostPlot = reshape(CampForPlotPost,size(CampForPlotPost,1)*size(CampForPlotPost,2),1);
        data(:,1) = reshapedPrePlot; data(:,2) = reshapedPostPlot;
        figure;
        ax=gca;
        % plot box plot 
        boxchart(data,'MarkerStyle','none','BoxFaceColor','k','WhiskerLineColor','k');
        % plot swarm chart on top of box plot 
        hold all;
        x = repmat(1:size(data,2),size(data,1),1);
        swarmchart(x,data,[],'red') 
        % boxchart(reshapedPostPlot,'MarkerStyle','none','BoxFaceColor','b','WhiskerLineColor','b');
        ax.FontSize = 15;
        ax.FontName = 'Times';
        if dlightQ == 0 % BBB data 
            ylabel("BBB Plume Pixel Amplitude") 
            if ETAorSTAq == 0 % STA data
                if clustSpikeQ3 == 0 
                    title({'BBB Plume Pixel Amplitude By Axon';'Pre And Post Spike Plumes';'Averaged Across Axons';'Average Cluster Time'});  
                elseif clustSpikeQ3 == 1
                    title({'BBB Plume Pixel Amplitude By Axon';'Pre And Post Spike Plumes';'Averaged Across Axons';'Cluster Start Time'});  
                end       
            elseif ETAorSTAq == 1 % ETA data
                if ETAtype == 0 % opto data 
                    if clustSpikeQ3 == 0 
                        title({'BBB Plume Pixel Amplitude';'Pre And Post Opto Plumes';'Average Cluster Time'});  
                    elseif clustSpikeQ3 == 1
                        title({'BBB Plume Pixel Amplitude';'Pre And Post Opto Plumes';'Cluster Start Time'});  
                    end   
                elseif ETAtype == 1 % behavior data 
                    if ETAtype2 == 0 % stim aligned 
                        if clustSpikeQ3 == 0 
                            title({'BBB Plume Pixel Amplitude';'Pre And Post Stim Plumes';'Average Cluster Time'});  
                        elseif clustSpikeQ3 == 1
                            title({'BBB Plume Pixel Amplitude';'Pre And Post Stim Plumes';'Cluster Start Time'});  
                        end                      
                    elseif ETAtype2 == 1 % reward aligned 
                         if clustSpikeQ3 == 0 
                            title({'BBB Plume Pixel Amplitude';'Pre And Post Reward Plumes';'Average Cluster Time'});  
                        elseif clustSpikeQ3 == 1
                            title({'BBB Plume Pixel Amplitude';'Pre And Post Reward Plumes';'Cluster Start Time'});  
                        end                        
                    end 
                end 
            end             
        elseif dlightQ == 1 % dlight data
            ylabel("dlight Pixel Amplitude") 
            if ETAorSTAq == 0 % STA data
                if clustSpikeQ3 == 0 
                    title({'dlight Pixel Amplitude By Axon';'Pre And Post Spike Clusters';'Averaged Across Axons';'Average Cluster Time'});  
                elseif clustSpikeQ3 == 1
                    title({'dlight Pixel Amplitude By Axon';'Pre And Post Spike Clusters';'Averaged Across Axons';'Cluster Start Time'});  
                end       
            elseif ETAorSTAq == 1 % ETA data
                if ETAtype == 0 % opto data 
                    if clustSpikeQ3 == 0 
                        title({'dlight Pixel Amplitude';'Pre And Post Opto Clusters';'Average Cluster Time'});  
                    elseif clustSpikeQ3 == 1
                        title({'dlight Pixel Amplitude';'Pre And Post Opto Clusters';'Cluster Start Time'});  
                    end   
                elseif ETAtype == 1 % behavior data 
                    if ETAtype2 == 0 % stim aligned 
                        if clustSpikeQ3 == 0 
                            title({'dlight Pixel Amplitude';'Pre And Post Stim Clusters';'Average Cluster Time'});  
                        elseif clustSpikeQ3 == 1
                            title({'dlight Pixel Amplitude';'Pre And Post Stim Clusters';'Cluster Start Time'});  
                        end                      
                    elseif ETAtype2 == 1 % reward aligned 
                         if clustSpikeQ3 == 0 
                            title({'dlight Pixel Amplitude';'Pre And Post Reward Clusters';'Average Cluster Time'});  
                        elseif clustSpikeQ3 == 1
                            title({'dlight Pixel Amplitude';'Pre And Post Reward Clusters';'Cluster Start Time'});  
                        end                        
                    end 
                end 
            end             
        end 
        if ETAorSTAq == 0 % STA data 
            avLabels = ["Pre-Spike","Post-Spike"];
        elseif ETAorSTAq == 1 % ETA data
              if ETAtype == 0 % opto data 
                  avLabels = ["Pre-Opto","Post-Opto"];
              elseif ETAtype == 1 % behavior data 
                    if ETAtype2 == 0 % stim aligned 
                        avLabels = ["Pre-Stim","Post-Stim"];
                    elseif ETAtype2 == 1 % reward aligned 
                        avLabels = ["Pre-Reward","Post-Reward"];
                    end 
              end 
        end 
        xticklabels(avLabels)
    end 
end 

%% plot change in cluster size and pixel amplitude over time for each axon and averaged
if clustSpikeQ == 0
    if ETAorSTAq == 0 % STA data 
        clr = hsv(length(terminals{mouse}));
    elseif ETAorSTAq == 1 % ETA data 
        clr = hsv(size(clustSizeTS{terminals{mouse}(ccell)},1));
    end 
    x = 1:size(im,3);
    % make a string array for the axons 
    count = 1; 
    axonString = string(1);
    % plot change in plume size per cluster color coded by axon (STA) or
    % cluster (ETA)
    figure;
    hold all;
    ax=gca;
    count2 = 1;
    axonLabel = string(1);
    for ccell = 1:length(terminals{mouse})
        if isempty(clustSizeTS{terminals{mouse}(ccell)}) == 0 
            axonString(count) = num2str(terminals{mouse}(ccell)); 
            for clust = 1:size(clustSizeTS{terminals{mouse}(ccell)},1)
                if clust == 1
                    if isempty(clustSizeTS{terminals{mouse}(ccell)}) == 0 
                        axonLabel(count2) = axonString(count);
                        count = count + 1;
                        count2 = count2 + 1;
                    end 
                elseif clust > 1 
                    if isempty(clustSizeTS{terminals{mouse}(ccell)}) == 0                         
                        if sum(~isnan(idx{terminals{mouse}(ccell)})) > 0 
                            count2 = count2 + 1;
                            axonLabel(count2) = '';                           
                        end                        
                    end 
                end 
                if ETAorSTAq == 1 % ETA data 
                    h = plot(x,clustSizeTS{terminals{mouse}(ccell)}(clust,:),'Color',clr(clust,:),'LineWidth',2);  
                end 
            end 
            if ETAorSTAq == 0 % STA data 
                h = plot(x,clustSizeTS{terminals{mouse}(ccell)},'Color',clr(ccell,:),'LineWidth',2);   
            end 
        end 
    end     
    if ETAorSTAq == 0 % STA data 
        legend(axonLabel)
    end 
    Frames = size(im,3);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
    % FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
    if dlightQ == 1 % dlight data
        threshFrame = floor(size(im,3)/2);
        FrameVals(3) = threshFrame;
        FrameVals(2) = threshFrame - (Frames/5);
        FrameVals(1) = FrameVals(2) - (Frames/5);
        FrameVals(4) = threshFrame + (Frames/5);
        FrameVals(5) = FrameVals(4) + (Frames/5);        
    end 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    xlabel("Time (s)")
    if dlightQ == 0 % BBB data 
        ylabel("BBB Plume Size (microns squared)") 
        title('Change in BBB Plume Size Over Time')
    elseif dlightQ == 1 % dlight data
        ylabel("dlight Size (microns squared)") 
        title('Change in dlight Size Over Time')        
    end 


    % plot change in plume pixel amplitude per cluster color coded by axon 
    figure;
    hold all;
    ax=gca;
    for ccell = 1:length(terminals{mouse})
        if isempty(clustPixAmpTS{terminals{mouse}(ccell)}) == 0 
            for clust = 1:size(clustSizeTS{terminals{mouse}(ccell)},1)
                if ETAorSTAq == 1 % ETA data
                    h = plot(x,clustPixAmpTS{terminals{mouse}(ccell)}(clust,:),'Color',clr(clust,:),'LineWidth',2);  
                end 
            end 
            if ETAorSTAq == 0 % STA data 
                h = plot(x,clustPixAmpTS{terminals{mouse}(ccell)},'Color',clr(ccell,:),'LineWidth',2);  
            end 
        end 
    end     
    if ETAorSTAq == 0 % STA data 
        legend(axonLabel)
    end 
    Frames = size(im,3);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
    % FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    xlabel("Time (s)");
    if dlightQ == 0 % BBB data 
        ylabel("BBB Plume Pixel Amplitude")
        title('Change in BBB Plume Pixel Amplitude Over Time')
    elseif dlightQ == 1 % dlight data
        ylabel("dlight Pixel Amplitude")
        title('Change in dlight Pixel Amplitude Over Time')        
    end 


    % resort data to plot change in average cluster size per axon
    figure;
    hold all;
    ax=gca;
    avAxonClustSizeTS = NaN(length(terminals{mouse}),size(im,3));
    count = 1;
    for ccell = 1:length(terminals{mouse})
        avAxonClustSizeTS(count,:) = nanmean(clustSizeTS{terminals{mouse}(ccell)},1);  %#ok<*NANMEAN> 
        plot(x,avAxonClustSizeTS(count,:),'Color',clr(ccell,:),'LineWidth',2);      
        count = count + 1;
    end 
    % get the legend labels set up right 
    axons = str2double(axonString);
    [presentAxons,~] = ismember(terminals{mouse},axons);
    presentAxons = ~presentAxons;
    axons = terminals{mouse};
    axons(presentAxons) = NaN;
    axonString = string(axons);
    if ETAorSTAq == 0 % STA data 
        legend(axonString)
    end 
    Frames = size(im,3);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
    % FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    xlabel("Time (s)")
    if dlightQ == 0 % BBB data 
        ylabel("BBB Plume Size (microns squared)") 
        if ETAorSTAq == 0 % STA data 
            title({'Average Change in BBB Plume Size Over Time';'Per Axon'})
        elseif ETAorSTAq == 1 % ETA data 
            title('Average Change in BBB Plume Size Over Time')
        end 
    elseif dlightQ == 1 % dlight data
        ylabel("dlight Size (microns squared)") 
        if ETAorSTAq == 0 % STA data 
            title({'Average Change in dlight Size Over Time';'Per Axon'})
        elseif ETAorSTAq == 1 % ETA data 
            title('Average Change in dlight Size Over Time')
        end         
    end 


     % resort data to plot change in average cluster pixel amplitude per axon
    figure;
    hold all;
    ax=gca;
    avAxonClustPixAmpTS = NaN(length(terminals{mouse}),size(im,3));
    count = 1;
    for ccell = 1:length(terminals{mouse})
        avAxonClustPixAmpTS(count,:) = nanmean(clustPixAmpTS{terminals{mouse}(ccell)},1);  %#ok<*NANMEAN> 
        plot(x,avAxonClustPixAmpTS(count,:),'Color',clr(ccell,:),'LineWidth',2);      
        count = count + 1;
    end 
    if ETAorSTAq == 0 % STA data 
        legend(axonString)
    end 
    Frames = size(im,3);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
    % FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times'; 
    xlabel("Time (s)")
    if dlightQ == 0 % BBB data 
        ylabel("BBB Plume Pixel Amplitude")
        if ETAorSTAq == 0 % STA data 
            title({'Average Change in';'BBB Plume Pixel Amplitude Over Time';'Per Axon'})   
        elseif ETAorSTAq == 1 % ETA data 
            title({'Average Change in';'BBB Plume Pixel Amplitude Over Time'}) 
        end         
    elseif dlightQ == 1 % dlight data
        ylabel("dlight Pixel Amplitude")
        if ETAorSTAq == 0 % STA data 
            title({'Average Change in';'dlight Pixel Amplitude Over Time';'Per Axon'})   
        elseif ETAorSTAq == 1 % ETA data 
            title({'Average Change in';'dlight Pixel Amplitude Over Time'}) 
        end         
    end 


    if ETAorSTAq == 0 % STA data 
        % plot average change in cluster size of all axons w/95% CI 
        figure;
        hold all;
        ax=gca;
        % determine average 
        avAllClustSizeTS = nanmean(avAxonClustSizeTS);
        % determine 95% CI 
        SEM = (nanstd(avAxonClustSizeTS))/(sqrt(size(avAxonClustSizeTS,1))); %#ok<*NANSTD> % Standard Error            
        ts_Low = tinv(0.025,size(avAxonClustSizeTS,1)-1);% T-Score for 95% CI
        ts_High = tinv(0.975,size(avAxonClustSizeTS,1)-1);% T-Score for 95% CI
        CI_Low = (nanmean(avAxonClustSizeTS,1)) + (ts_Low*SEM);  % Confidence Intervals
        CI_High = (nanmean(avAxonClustSizeTS,1)) + (ts_High*SEM);  % Confidence Intervals
        plot(x,avAllClustSizeTS,'k','LineWidth',2);   
        clear v f 
        v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
        v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
        % remove NaNs so face can be made and colored 
        nanRows = isnan(v(:,2));
        v(nanRows,:) = []; f = 1:size(v,1);
        patch('Faces',f,'Vertices',v,'FaceColor','black','EdgeColor','none');
        alpha(0.3)
        Frames = size(im,3);
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
        % FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;  
        ax.FontSize = 15;
        ax.FontName = 'Times';         
        xlabel("Time (s)")        
        if dlightQ == 0 % BBB data 
            ylabel("BBB Plume Size (microns squared)")
            title({'Average Change in BBB Plume Size Over Time';'Across Axons'})
        elseif dlightQ == 1 % dlight data
            ylabel("dlight Size (microns squared)")
            title({'Average Change in dlight Size Over Time';'Across Axons'})            
        end 
    end 
    
    if ETAorSTAq == 0 % STA data
        % plot average change in cluster pixel amplitude of all axons w/95% CI 
        figure;
        hold all;
        ax=gca;
        % determine average 
        avAllClustPixAmpTS = nanmean(avAxonClustPixAmpTS);
        % determine 95% CI 
        SEM = (nanstd(avAxonClustPixAmpTS))/(sqrt(size(avAxonClustPixAmpTS,1))); %#ok<*NANSTD> % Standard Error            
        ts_Low = tinv(0.025,size(avAxonClustPixAmpTS,1)-1);% T-Score for 95% CI
        ts_High = tinv(0.975,size(avAxonClustPixAmpTS,1)-1);% T-Score for 95% CI
        CI_Low = (nanmean(avAxonClustPixAmpTS,1)) + (ts_Low*SEM);  % Confidence Intervals
        CI_High = (nanmean(avAxonClustPixAmpTS,1)) + (ts_High*SEM);  % Confidence Intervals
        plot(x,avAllClustPixAmpTS,'k','LineWidth',2);   
        clear v f 
        v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
        v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
        % remove NaNs so face can be made and colored 
        nanRows = isnan(v(:,2));
        v(nanRows,:) = []; f = 1:size(v,1);
        patch('Faces',f,'Vertices',v,'FaceColor','black','EdgeColor','none');
        alpha(0.3)
        Frames = size(im,3);
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
        % FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;  
        ax.FontSize = 15;
        ax.FontName = 'Times';        
        xlabel("Time (s)")        
        if dlightQ == 0 % BBB data 
            ylabel("BBB Plume Pixel Amplitude") 
            title({'Average Change in'; 'BBB Plume Pixel Amplitude Over Time';'Across Axons'})
        elseif dlightQ == 1 % dlight data
            ylabel("dlight Pixel Amplitude") 
            title({'Average Change in'; 'dlight Pixel Amplitude Over Time';'Across Axons'})            
        end 
    end 
end 

%% plot average BBB plume change in size and pixel amplitude over time for however many groups you want
if clustSpikeQ == 0
    % plot change in cluster size color coded by axon 
    x = 1:size(im,3);
    times = unique(avClocFrame);
    timesLoc = ~isnan(unique(avClocFrame));
    times = times(timesLoc);
    numTraces = length(times);
    clustTimeNumGroups = input(sprintf('How many groups do you want to sort plumes into for averaging? There are %d total plumes. ', numTraces));
    windTime = floor(size(im,3)/FPSstack{mouse});
    timeStart = -(windTime/2); timeEnd = windTime/2;
    if clustTimeNumGroups == 2             
        clr = hsv(clustTimeNumGroups);
        binThreshTime = input('Input the start time threshold for separating plumes with. ');
        % determine time value per frame 
        frameTimes = linspace(timeStart,timeEnd,size(im,3));
        [value, binFrameThresh] = min(abs(frameTimes-binThreshTime));
        binThreshs = [1,binFrameThresh,size(im,3)];
        if clustTimeNumGroups == 2 && binThreshs(2) ~= threshFrame
            binThreshs(2) = threshFrame;
        end 
        binClustTSsizeData = cell(1,clustTimeNumGroups);
        binClustTSpixAmpData = cell(1,clustTimeNumGroups);
        sizeArray = zeros(1,clustTimeNumGroups);
        pixAmpArray = zeros(1,clustTimeNumGroups);
        count = 1; 
        binLabel = string(1);
        figure;
        hold all;
        ax=gca;
        binStartAndEndFrames = zeros(clustTimeNumGroups,2);  
        for bin = 1:clustTimeNumGroups
            % create time (by frame) bins 
            if bin < clustTimeNumGroups
                binStartAndEndFrames(bin,1) = binThreshs(bin);
                binStartAndEndFrames(bin,2) = threshFrame-1;
            elseif bin == clustTimeNumGroups
                binStartAndEndFrames(bin,1) = binThreshs(bin);
                binStartAndEndFrames(bin,2) = size(im,3);                
            end 
            clustStartFrame = cell(1,max(terminals{mouse}));
            % determine cluster start frame 
            for ccell = 1:length(terminals{mouse})               
                [clustLocX, clustLocY] = find(~isnan(clustSizeTS{terminals{mouse}(ccell)}));
                clusts = unique(clustLocX);              
                for clust = 1:length(clusts)
                    clustStartFrame{terminals{mouse}(ccell)}(clust) = min(clustLocY(clustLocX == clust));
                end 
            end 
            % set the current bin boundaries 
            curBinBounds = binStartAndEndFrames(bin,:);           
            for ccell = 1:length(terminals{mouse}) 
                % determine what clusters go into the current bin 
                theseClusts = clustStartFrame{terminals{mouse}(ccell)} >= curBinBounds(1) & clustStartFrame{terminals{mouse}(ccell)} <= curBinBounds(2);
                binClusts = find(theseClusts);                
                % sort clusters into time bins 
                sizeArray(bin) = size(binClustTSsizeData{bin},1);
                binClustTSsizeData{bin}(sizeArray(bin)+1:sizeArray(bin)+length(binClusts),:) = clustSizeTS{terminals{mouse}(ccell)}(binClusts,:);                
                pixAmpArray(bin) = size(binClustTSpixAmpData{bin},1);
                binClustTSpixAmpData{bin}(pixAmpArray(bin)+1:pixAmpArray(bin)+length(binClusts),:) = clustPixAmpTS{terminals{mouse}(ccell)}(binClusts,:);
            end 
            % determine bin labels 
            binString = string(round((binStartAndEndFrames(bin,:)./FPSstack{mouse})-(size(im,3)/FPSstack{mouse}/2),1));
            for clust = 1:size(binClustTSsizeData{bin},1)
                if clust == 1 
                    if isempty(binClustTSsizeData{bin}) == 0                     
                        binLabel(count) = append(binString(1),' to ',binString(2));
                        count = count + 1;
                    end 
                elseif clust > 1
                    if isempty(binClustTSsizeData{bin}) == 0 
                        binLabel(count) = '';
                        count = count + 1;                        
                    end                 
                end 
            end 
            if isempty(binClustTSsizeData{bin}) == 0 
                h = plot(x,binClustTSsizeData{bin},'Color',clr(bin,:),'LineWidth',2); 
            end 
        end
    elseif clustTimeNumGroups > 2 
        clr = hsv(clustTimeNumGroups);
        binFrameSize = floor(size(im,3)/clustTimeNumGroups);
        binThreshs = (1:binFrameSize:size(im,3));
        binStartAndEndFrames = zeros(clustTimeNumGroups,2);   
        clustStartFrame = cell(1,max(terminals{mouse}));
        % determine cluster start frame 
        for ccell = 1:length(terminals{mouse})               
            [clustLocX, clustLocY] = find(~isnan(clustSizeTS{terminals{mouse}(ccell)}));
            clusts = unique(clustLocX);              
            for clust = 1:length(clusts)
                clustStartFrame{terminals{mouse}(ccell)}(clust) = min(clustLocY(clustLocX == clust));
            end 
        end 
        binClustTSsizeData = cell(1,clustTimeNumGroups);
        binClustTSpixAmpData = cell(1,clustTimeNumGroups);
        sizeArray = zeros(1,clustTimeNumGroups);
        pixAmpArray = zeros(1,clustTimeNumGroups);
        count = 1; 
        binLabel = string(1);
        figure;
        hold all;
        ax=gca;
        for bin = 1:clustTimeNumGroups
            % create time (by frame) bins 
            if bin < clustTimeNumGroups
                binStartAndEndFrames(bin,1) = binThreshs(bin);
                binStartAndEndFrames(bin,2) = binThreshs(bin)+binFrameSize-1;
            elseif bin == clustTimeNumGroups
                binStartAndEndFrames(bin,1) = binThreshs(bin);
                binStartAndEndFrames(bin,2) = size(im,3);                
            end 
            % set the current bin boundaries 
            curBinBounds = binStartAndEndFrames(bin,:);           
            for ccell = 1:length(terminals{mouse}) 
                % determine what clusters go into the current bin 
                theseClusts = clustStartFrame{terminals{mouse}(ccell)} >= curBinBounds(1) & clustStartFrame{terminals{mouse}(ccell)} <= curBinBounds(2);
                binClusts = find(theseClusts);                
                % sort clusters into time bins 
                sizeArray(bin) = size(binClustTSsizeData{bin},1);
                binClustTSsizeData{bin}(sizeArray(bin)+1:sizeArray(bin)+length(binClusts),:) = clustSizeTS{terminals{mouse}(ccell)}(binClusts,:);
                pixAmpArray(bin) = size(binClustTSpixAmpData{bin},1);
                binClustTSpixAmpData{bin}(pixAmpArray(bin)+1:pixAmpArray(bin)+length(binClusts),:) = clustPixAmpTS{terminals{mouse}(ccell)}(binClusts,:);
            end 
            % determine bin labels 
            binString = string(round((binStartAndEndFrames(bin,:)./FPSstack{mouse})-(size(im,3)/FPSstack{mouse}/2),1));
            for clust = 1:size(binClustTSsizeData{bin},1)
                if clust == 1 
                    if isempty(binClustTSsizeData{bin}) == 0                     
                        binLabel(count) = append(binString(1),' to ',binString(2));
                        count = count + 1;
                    end 
                elseif clust > 1
                    if isempty(binClustTSsizeData{bin}) == 0 
                        binLabel(count) = '';
                        count = count + 1;                        
                    end                 
                end 
            end 
            if isempty(binClustTSsizeData{bin}) == 0 
                h = plot(x,binClustTSsizeData{bin},'Color',clr(bin,:),'LineWidth',2); 
            end 
        end
    end 
    legend(binLabel)
    Frames = size(im,3);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
    % FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';    
    xlabel("Time (s)")    
    if dlightQ == 0 % BBB data 
        ylabel("BBB Plume Size (microns squared)") 
        title('Change in BBB Plume Size Over Time')
    elseif dlightQ == 1 % dlight data
        ylabel("dlight Size (microns squared)") 
        title('Change in dlight Size Over Time')        
    end 

    
    % plot change in cluster pixel amplitude color coded by axon  
    figure;
    hold all;
    ax=gca;
    if clustTimeNumGroups == 2             
        for bin = 1:clustTimeNumGroups
            if isempty(binClustTSpixAmpData{bin}) == 0 
                h = plot(x,binClustTSpixAmpData{bin},'Color',clr(bin,:),'LineWidth',2); 
            end 
        end
    elseif clustTimeNumGroups > 2 
        for bin = 1:clustTimeNumGroups
            if isempty(binClustTSpixAmpData{bin}) == 0 
                h = plot(x,binClustTSpixAmpData{bin},'Color',clr(bin,:),'LineWidth',2); 
            end 
        end
    end 
    legend(binLabel)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    xlabel("Time (s)")
    if dlightQ == 0 % BBB data 
        ylabel("BBB Plume Pixel Amplitude")     
        title('Change in BBB Plume Pixel Amplitude Over Time')
    elseif dlightQ == 1 % dlight data
        ylabel("dlight Pixel Amplitude")     
        title('Change in dlight Pixel Amplitude Over Time')        
    end 
    
    
    % plot average change in cluster size 
    figure;
    hold all;
    ax=gca;
    avBinClustSizeTS = NaN(clustTimeNumGroups,size(im,3));
    count = 1;
    for bin = 1:clustTimeNumGroups
        if isempty(binClustTSsizeData{bin}) == 0
            avBinClustSizeTS(count,:) = nanmean(binClustTSsizeData{bin},1);  
            plot(x,avBinClustSizeTS(count,:),'Color',clr(bin,:),'LineWidth',2);      
            count = count + 1;
        end 
    end 
    % remove empty strings 
    emptyStrings = find(binLabel == '');
    binLabel(emptyStrings) = [];
    legend(binLabel)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';    
    xlabel("Time (s)")    
    if dlightQ == 0 % BBB data 
        ylabel("BBB Plume Size (microns squared)") 
        title({'Average Change in BBB Plume Size Over Time'})
    elseif dlightQ == 1 % dlight data
        ylabel("dlight Size (microns squared)") 
        title({'Average Change in dlight Size Over Time'})        
    end 

    
    % plot average change in cluster size 
    figure;
    hold all;
    ax=gca;
    avBinClustPixAmpTS = NaN(clustTimeNumGroups,size(im,3));
    count = 1;
    for bin = 1:clustTimeNumGroups
        if isempty(binClustTSpixAmpData{bin}) == 0
            avBinClustPixAmpTS(count,:) = nanmean(binClustTSpixAmpData{bin},1);  
            plot(x,avBinClustPixAmpTS(count,:),'Color',clr(bin,:),'LineWidth',2);      
            count = count + 1;
        end 
    end 
    legend(binLabel)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';     
    xlabel("Time (s)")
    if dlightQ == 0 % BBB data 
        ylabel("BBB Plume Pixel Amplitude")
        title({'Average Change in';'BBB Plume Pixel Amplitude Over Time'})
    elseif dlightQ == 1 % dlight data
        ylabel("dlight Pixel Amplitude")
        title({'Average Change in';'dlight Pixel Amplitude Over Time'})        
    end 

    
    % plot aligned cluster change in size per bin and total average 
    % determine cluster start frame per bin  
    binClustStartFrame = cell(1,clustTimeNumGroups);
    alignedBinClustsSize = cell(1,clustTimeNumGroups);
    avAlignedClustsSize = cell(1,clustTimeNumGroups);
    figure;
    hold all;
    ax=gca;
    for bin = 1:clustTimeNumGroups             
        [clustLocX, clustLocY] = find(~isnan(binClustTSsizeData{bin}));
        clusts = unique(clustLocX);              
        for clust = 1:length(clusts)
            binClustStartFrame{bin}(clust) = min(clustLocY(clustLocX == clust));
        end 
        % align clusters
        % determine longest cluster 
        [longestClustStart,longestClust] = min(binClustStartFrame{bin});
        arrayLen = size(im,3)-longestClustStart+1;
        for clust = 1:size(binClustTSsizeData{bin},1)
            % get data and buffer end as needed 
            data = binClustTSsizeData{bin}(clust,binClustStartFrame{bin}(clust):end);
            data(:,length(data)+1:arrayLen) = NaN;
            % align data 
            alignedBinClustsSize{bin}(clust,:) = data;
        end 
        x = 1:size(alignedBinClustsSize{bin},2);
        % averaged the aligned clusters 
        avAlignedClustsSize{bin} = nanmean(alignedBinClustsSize{bin},1);
        if isempty(binClustTSsizeData{bin}) == 0 
            h = plot(x,avAlignedClustsSize{bin},'Color',clr(bin,:),'LineWidth',2); 
        end 
    end 
    legend(binLabel)
    Frames = size(im,3);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1+timeEnd;
    FrameVals = round((1:FPSstack{mouse}:Frames));
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    xlabel("Time (s)")
    if dlightQ == 0 % BBB data 
        ylabel("BBB Plume Size (microns squared)") 
        title({'Change in BBB Plume Size Over Time';'Clusters Aligned and Averaged'})
    elseif dlightQ == 1 % dlight data
        ylabel("dlight Size (microns squared)") 
        title({'Change in dlight Size Over Time';'Clusters Aligned and Averaged'})        
    end 

    
    % plot aligned cluster change in pixel amplitude per bin and total average 
    % determine cluster start frame per bin  
    alignedBinClustsPixAmp = cell(1,clustTimeNumGroups);
    avAlignedClustsPixAmp = cell(1,clustTimeNumGroups);
    figure;
    hold all;
    ax=gca;
    for bin = 1:clustTimeNumGroups             
        % align clusters
        % determine longest cluster 
        [longestClustStart,longestClust] = min(binClustStartFrame{bin});
        arrayLen = size(im,3)-longestClustStart+1;
        for clust = 1:size(binClustTSpixAmpData{bin},1)
            % get data and buffer end as needed 
            data = binClustTSpixAmpData{bin}(clust,binClustStartFrame{bin}(clust):end);
            data(:,length(data)+1:arrayLen) = NaN;
            % align data 
            alignedBinClustsPixAmp{bin}(clust,:) = data;
        end 
        x = 1:size(alignedBinClustsPixAmp{bin},2);
        % averaged the aligned clusters 
        avAlignedClustsPixAmp{bin} = nanmean(alignedBinClustsPixAmp{bin},1);
        if isempty(binClustTSpixAmpData{bin}) == 0 
            h = plot(x,avAlignedClustsPixAmp{bin},'Color',clr(bin,:),'LineWidth',2); 
        end 
    end 
    legend(binLabel)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times'; 
    xlabel("Time (s)")
    if dlightQ == 0 % BBB data 
        ylabel("BBB Plume Pixel Amplitude")
        title({'Change in BBB Plume Pixel Amplitude Over Time';'Clusters Aligned and Averaged'})
    elseif dlightQ == 1 % dlight data
        ylabel("dlight Pixel Amplitude")
        title({'Change in dlight Pixel Amplitude Over Time';'Clusters Aligned and Averaged'})
    end 

    
    % plot total aligned cluster size average 
    [~,c] = cellfun(@size,alignedBinClustsSize);
    maxLen = max(c);
    if clustTimeNumGroups == 2     
        for bin = 1:clustTimeNumGroups           
            % put data together with appropriate buffering to get total average 
            data = alignedBinClustsSize{bin};
            data(:,size(data,2)+1:maxLen) = NaN;        
            if bin == 1 
                allClusts = data;
            elseif bin == 2 
                allClusts(size(allClusts,1)+1:size(allClusts,1)+size(data,1),:) = data;
            end 
        end 
        % plot average of all axons w/95% CI 
        figure;
        hold all;
        ax=gca;
        % determine average 
        avAllClustSizeTS = nanmean(allClusts);
        x = 1:length(avAllClustSizeTS);
        % determine 95% CI 
        SEM = (nanstd(allClusts))/(sqrt(size(allClusts,1))); %#ok<*NANSTD> % Standard Error            
        ts_Low = tinv(0.025,size(allClusts,1)-1);% T-Score for 95% CI
        ts_High = tinv(0.975,size(allClusts,1)-1);% T-Score for 95% CI
        CI_Low = (nanmean(allClusts,1)) + (ts_Low*SEM);  % Confidence Intervals
        CI_High = (nanmean(allClusts,1)) + (ts_High*SEM);  % Confidence Intervals
        plot(x,avAllClustSizeTS,'k','LineWidth',2);   
        clear v f 
        v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
        v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
        % remove NaNs so face can be made and colored 
        nanRows = isnan(v(:,2));
        v(nanRows,:) = []; f = 1:size(v,1);
        patch('Faces',f,'Vertices',v,'FaceColor','black','EdgeColor','none');
        alpha(0.3)
        % Frames = size(im,3);
        % Frames_pre_stim_start = -((Frames-1)/2); 
        % Frames_post_stim_start = (Frames-1)/2; 
        % sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1+timeEnd;
        % FrameVals = round((1:FPSstack{mouse}:Frames)); 
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;  
        ax.FontSize = 15;
        ax.FontName = 'Times';        
        xlabel("Time (s)")        
        if dlightQ == 0 % BBB data 
            ylabel("BBB Plume Size (microns squared)") 
            title({'Average Aligned Change in BBB Plume Size Over Time';'Across Axons'})
        elseif dlightQ == 1 % dlight data
            ylabel("dlight Size (microns squared)") 
            title({'Average Aligned Change in dlight Size Over Time';'Across Axons'})            
        end 
    end 
    
    % plot total aligned cluster pixel amplitude average 
    if clustTimeNumGroups == 2     
        for bin = 1:clustTimeNumGroups           
            % put data together with appropriate buffering to get total average 
            data = alignedBinClustsPixAmp{bin};
            data(:,size(data,2)+1:maxLen) = NaN;        
            if bin == 1 
                allClusts = data;
            elseif bin == 2 
                allClusts(size(allClusts,1)+1:size(allClusts,1)+size(data,1),:) = data;
            end 
        end 
        % plot average of all axons w/95% CI 
        figure;
        hold all;
        ax=gca;
        % determine average 
        avAllClustSizeTS = nanmean(allClusts);
        x = 1:length(avAllClustSizeTS);
        % determine 95% CI 
        SEM = (nanstd(allClusts))/(sqrt(size(allClusts,1))); %#ok<*NANSTD> % Standard Error            
        ts_Low = tinv(0.025,size(allClusts,1)-1);% T-Score for 95% CI
        ts_High = tinv(0.975,size(allClusts,1)-1);% T-Score for 95% CI
        CI_Low = (nanmean(allClusts,1)) + (ts_Low*SEM);  % Confidence Intervals
        CI_High = (nanmean(allClusts,1)) + (ts_High*SEM);  % Confidence Intervals
        plot(x,avAllClustSizeTS,'k','LineWidth',2);   
        clear v f 
        v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
        v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
        % remove NaNs so face can be made and colored 
        nanRows = isnan(v(:,2));
        v(nanRows,:) = []; f = 1:size(v,1);
        patch('Faces',f,'Vertices',v,'FaceColor','black','EdgeColor','none');
        alpha(0.3)
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;  
        ax.FontSize = 15;
        ax.FontName = 'Times';
        xlabel("Time (s)")
        if dlightQ == 0 % BBB data 
            ylabel("BBB Plume Pixel Amplitude") 
            title({'Average Aligned Change in'; 'BBB Plume Pixel Amplitude Over Time';'Across Axons'})
        elseif dlightQ == 1 % dlight data
            ylabel("dlight Pixel Amplitude") 
            title({'Average Aligned Change in'; 'dlight Pixel Amplitude Over Time';'Across Axons'})            
        end 
    end 
end 

%% plot change in vessel width
%remove rows full of 0s if there are any b = a(any(a,2),:)
mouse = 1;
if ~exist('threshFrame') %#ok<EXIST>
    threshFrame = floor(size(im,3)/2);
end 
% import the data 
regImDir = uigetdir('*.*',sprintf('WHERE IS THE VESSEL WIDTH DATA FOR MOUSE #%d?',mouse));
cd(regImDir);
% get vessel width data 
vDataFullTrace = cell(1,mouseNum);
vDataFullTrace2 = cell(1,mouseNum);
vDataFullTrace3 = cell(1,mouseNum);
VWfileList = dir('**/*VWdata_*.mat'); % list VW data files in current directory 
for vid = 1:length(vidList{mouse})
    VWlabel = VWfileList(vid).name;
    VWmat = matfile(sprintf(VWlabel,vidList{mouse}(vid)));
    Vdata = VWmat.Vdata;       
    if iscell(Vdata{mouse}) == 1
        vDataFullTrace{mouse}{vid} = Vdata; % vDataFullTrace{mouse}{vid}(VWroi)
        % average the VWrois that you want 
        if vid == 1 
            VWrois = input('Input the VW ROIs that you want to average. ');
        end 
        for VWroi = 1:length(VWrois)
            vDataFullTrace2{mouse}{vid}(VWroi,:) = vDataFullTrace{mouse}{vid}{VWroi};
        end 
        vDataFullTrace3{mouse}{vid} = nanmean(vDataFullTrace2{mouse}{vid});
    elseif iscell(Vdata{mouse}) == 0
        vDataFullTrace{mouse}{vid} = Vdata{1}; % vDataFullTrace{mouse}{vid}(VWroi)
    end 
end 
if iscell(Vdata{mouse}) == 1
    clearvars vDataFullTrace vDataFullTrace2 
    vDataFullTrace = vDataFullTrace3; clearvars vDataFullTrace3
end 
if ETAorSTAq == 0 % STA data
    % get the calcium data 
    regImDir = uigetdir('*.*',sprintf('WHERE IS THE CALCIUM DATA FOR MOUSE #%d?',mouse));
    cd(regImDir);
    % get vessel width data 
    cDataFullTrace = cell(1,mouseNum);
    CAfileList = dir('**/*CAdata_*.mat'); % list VW data files in current directory 
    for vid = 1:length(vidList{mouse})
        CAlabel = CAfileList(vid).name;
        CAmat = matfile(sprintf(CAlabel,vidList{mouse}(vid)));
        cDataFullTrace{mouse}{vid} = CAmat.CcellData;  
    end 
end 
% sort the data
if ETAorSTAq == 0 % STA data
    % find CA peaks 
    stdTrace = cell(1,length(vidList{mouse})); 
    sigLocs2 = cell(1,length(vidList{mouse}));
    for vid = 1:length(vidList{mouse})
        for ccell = 1:length(terminals{mouse})
            [peaks, locs] = findpeaks(cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)},'MinPeakProminence',0.1,'MinPeakWidth',2); %0.6,0.8,0.9,1\
            %find the sig peaks (peaks above 2 standard deviations from mean) 
            stdTrace{vid}{terminals{mouse}(ccell)} = std(cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)});  
            count = 1 ; 
            for loc = 1:length(locs)
                if peaks(loc) > stdTrace{vid}{terminals{mouse}(ccell)}*2
                    sigLocs2{vid}{terminals{mouse}(ccell)}(count) = locs(loc);
                    count = count + 1;
                end 
            end 
        end 
    end 
elseif ETAorSTAq == 1 % ETA data 
    % resort state_start_f into sigLocs{vid}{terminals{mouse}(ccell)}(peak) 
    sigLocs2 = cell(1,length(vidList{mouse}));
    for vid = 1:length(vidList{mouse})
        sigLocs2{vid}= state_start_f{mouse}{vid}';
    end 
end 
% combine data, get z score, reseparate data into vids 
if ETAorSTAq == 0 % STA data
    % combine the VW data to get z score of whole experiment
    frameLens = zeros(1,length(vidList{mouse}));
    for vid = 1:length(vidList{mouse})
        if vid == 1 
            frameLen = size(greenStacks{vid},3);
        elseif vid > 1 
            frameLen = frameLen + size(greenStacks{vid},3);
        end 
        frameLens(vid) = size(greenStacks{vid},3);
    end 
    combCAdata = cell(1,max(terminals{mouse}));
    zCAdata = cell(1,max(terminals{mouse}));
    szCAdata = cell(1,length(vidList{mouse}));
    for ccell = 1:length(terminals{mouse})
        for vid = 1:length(vidList{mouse})
            if vid == 1 
                count = length(cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)});
            end 
            for frame = 1:length(cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}) 
                if vid == 1 
                    combCAdata{terminals{mouse}(ccell)}(:,frame) = cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}(:,frame);
                elseif vid > 1 
                    combCAdata{terminals{mouse}(ccell)}(:,count+1) = cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}(:,frame);
                    count = count + 1;                                      
                end 
            end     
        end    
        % z score the CA data  
        zCAdata{terminals{mouse}(ccell)} = zscore(combCAdata{terminals{mouse}(ccell)},0,2);
        clearvars combCAdata
        % resort data back into videos 
        count = 1;
        for vid = 1:length(vidList{mouse})
            for frame = 1:frameLens(vid)  
                if count <= length(zCAdata{terminals{mouse}(ccell)})
                    szCAdata{vid}{terminals{mouse}(ccell)}(:,frame) = zCAdata{terminals{mouse}(ccell)}(:,count); 
                    count = count + 1;
                end 
            end 
        end 
    end 
end 
% combine the VW data to get z score of whole experiment
frameLens = zeros(1,length(vidList{mouse}));
for vid = 1:length(vidList{mouse})
    if vid == 1 
        frameLen = size(greenStacks{vid},3);
    elseif vid > 1 
        frameLen = frameLen + size(greenStacks{vid},3);
    end 
    frameLens(vid) = size(greenStacks{vid},3);
end 
combVWdata = zeros(1,frameLen);
for vid = 1:length(vidList{mouse})
    if vid == 1 
        count = length(vDataFullTrace{mouse}{vid});
    end 
    for frame = 1:length(vDataFullTrace{mouse}{vid}) 
        if vid == 1 
            combVWdata(:,frame) = vDataFullTrace{mouse}{vid}(:,frame);
        elseif vid > 1 
            combVWdata(:,count+1) = vDataFullTrace{mouse}{vid}(:,frame);
            count = count + 1;                                      
        end 
    end     
end 
% z score the VW data  
zVWdata = zscore(combVWdata,0,2);
clearvars combVWdata
% resort data back into videos 
szVWdata = cell(1,length(vidList{mouse}));
count = 1;
for vid = 1:length(vidList{mouse})
    for frame = 1:frameLens(vid)       
        szVWdata{vid}(:,frame) = zVWdata(:,count); 
        count = count + 1;
    end 
end 
% sort data 
windSize = input('How big should the window be around the event/spike in seconds? '); %24
windFrames = floor(windSize*FPSstack{mouse});
lenIts = 1;
if ETAorSTAq == 0 % STA data  
    sortedVWdata = cell(1,length(vidList{mouse}));
    sortedCAdata = cell(1,length(vidList{mouse}));
    vwStackArray2 = cell(1,max(terminals{mouse}));
    caStackArray2 = cell(1,max(terminals{mouse}));
    for ccell = 1:length(terminals{mouse})
        % make sure sigLocs is organized in the correct orientation: 
        % sigLocs{vid}(it,peak)
        [r,c] = size(sigLocs2{1}{terminals{mouse}(ccell)});
        if r ~= lenIts
            for vid = 1:length(vidList{mouse})  
                sigLocs2{vid}{terminals{mouse}(ccell)} = sigLocs2{vid}{terminals{mouse}(ccell)}';
            end 
        end   
        for it = 1:lenIts
            % terminals = terminals{1};
            for vid = 1:length(vidList{mouse})                  
                if isempty(sigLocs2{vid}{terminals{mouse}(ccell)}) == 0 && isempty(szCAdata{vid}) == 0
                    for peak = 1:size(sigLocs2{vid}{terminals{mouse}(ccell)},2)                        
                        start = sigLocs2{vid}{terminals{mouse}(ccell)}(it,peak)-floor((windSize/2)*FPSstack{mouse});
                        stop = sigLocs2{vid}{terminals{mouse}(ccell)}(it,peak)+floor((windSize/2)*FPSstack{mouse});                
                        if start == 0 
                            start = 1 ;
                            stop = start + floor((windSize/2)*FPSstack{mouse}) + floor((windSize/2)*FPSstack{mouse});
                        end        
                        if stop < size(szVWdata{vid},2) && start > 0 && stop < size(szCAdata{vid}{terminals{mouse}(ccell)},2)
                            sortedVWdata{vid}{terminals{mouse}(ccell)}{peak} = szVWdata{vid}(:,start:stop);
                            sortedCAdata{vid}{terminals{mouse}(ccell)}{peak} = szCAdata{vid}{terminals{mouse}(ccell)}(:,start:stop);
                        end 
                    end     
                end                  
            end           
            count = 1;
            for vid = 1:length(vidList{mouse})     
                if length(sortedVWdata) >= vid && isempty(sortedVWdata{vid}) == 0 
                    for peak = 1:size(sortedVWdata{vid}{terminals{mouse}(ccell)},2)  
                        if isempty(sortedVWdata{vid}{terminals{mouse}(ccell)}{peak}) == 0
                            vwStackArray2{terminals{mouse}(ccell)}(count,:) = single(sortedVWdata{vid}{terminals{mouse}(ccell)}{peak});   
                            caStackArray2{terminals{mouse}(ccell)}(count,:) = single(sortedCAdata{vid}{terminals{mouse}(ccell)}{peak}); 
                            count = count + 1;
                        end 
                    end
                end 
            end 
        end        
    end 
elseif ETAorSTAq == 1 % ETA data 
    % make sure sigLocs is organized in the correct orientation: 
    % sigLocs{vid}(it,peak)
    [r,c] = size(sigLocs2{1});
    if r ~= lenIts
        for vid = 1:length(vidList{mouse})  
            sigLocs2{vid} = sigLocs2{vid}';
        end 
    end 
    for it = 1:lenIts
        % terminals = terminals{1};
        sortedVWdata = cell(1,1);
        for vid = 1:length(vidList{mouse})                  
            if isempty(sigLocs2{vid}) == 0
                for peak = 1:size(sigLocs2{vid},2)                        
                    start = sigLocs2{vid}(it,peak)-floor((windSize/2)*FPSstack{mouse});
                    stop = sigLocs2{vid}(it,peak)+floor((windSize/2)*FPSstack{mouse});                
                    if start == 0 
                        start = 1 ;
                        stop = start + floor((windSize/2)*FPSstack{mouse}) + floor((windSize/2)*FPSstack{mouse});
                    end        
                    if stop < size(szVWdata{vid},2) && start > 0 
                        sortedVWdata{vid}{peak} = szVWdata{vid}(:,start:stop);
                    end 
                end     
            end                  
        end            
        count = 1;
        if windFrames ~= length(sortedVWdata{1}{1})
            vwStackArray2 = NaN(1,length(sortedVWdata{1}{1}));
        elseif windFrames == length(sortedVWdata{1}{1})
            vwStackArray2 = NaN(1,windFrames);
        end 
        for vid = 1:length(vidList{mouse})     
            if length(sortedVWdata) >= vid && isempty(sortedVWdata{vid}) == 0 
                for peak = 1:size(sortedVWdata{vid},2)  
                    if isempty(sortedVWdata{vid}{peak}) == 0
                        vwStackArray2(count,:) = single(sortedVWdata{vid}{peak});          
                        count = count + 1;
                    end 
                end
            end 
        end 
    end 
end 
% prep data for plotting 
if ETAorSTAq == 0 % STA data
    avVWdata = cell(1,max(terminals{mouse}));
    avCAdata = cell(1,max(terminals{mouse}));
    SNvwStackArray2 = cell(1,max(terminals{mouse}));
    CIv_Low = cell(1,max(terminals{mouse}));
    CIv_High = cell(1,max(terminals{mouse}));
    CIc_Low = cell(1,max(terminals{mouse}));
    CIc_High = cell(1,max(terminals{mouse}));    
    for ccell = 1:length(terminals{mouse})
        % determine the average 
        avVWdata{terminals{mouse}(ccell)} = nanmean(vwStackArray2{terminals{mouse}(ccell)},1); 
        avCAdata{terminals{mouse}(ccell)} = nanmean(caStackArray2{terminals{mouse}(ccell)},1); 
    end 
    smoothQ = input('Input 0 if you do not want to do temporal smoothing. Input 1 otherwise. ');
    if smoothQ == 0 
        SNvwData = avVWdata;
    end 
    SNcaData = avCAdata;
    for ccell = 1:length(terminals{mouse})
        %temporal smoothing option
        if smoothQ == 1
            if ccell == 1 
                filtTime = input('How many seconds do you want to smooth your data by? '); % our favorite STA trace is smoothed by 0.7 sec
            end 
            filter_rate = FPSstack{mouse}*filtTime; 
            SNvwData{terminals{mouse}(ccell)} = smoothdata(avVWdata{terminals{mouse}(ccell)},2,'movmean',filter_rate);    
            SNvwStackArray2{terminals{mouse}(ccell)} = smoothdata(vwStackArray2{terminals{mouse}(ccell)},2,'movmean',filter_rate);  
        end        
        %DETERMINE 95% CI                       
        SEMv = (nanstd(SNvwStackArray2{terminals{mouse}(ccell)}))/(sqrt(size(SNvwStackArray2{terminals{mouse}(ccell)},1))); %#ok<*NANSTD> % Standard Error            
        tsv_Low = tinv(0.025,size(SNvwStackArray2{terminals{mouse}(ccell)},1)-1);% T-Score for 95% CI
        tsv_High = tinv(0.975,size(SNvwStackArray2{terminals{mouse}(ccell)},1)-1);% T-Score for 95% CI
        CIv_Low{terminals{mouse}(ccell)} = (SNvwData{terminals{mouse}(ccell)}) + (tsv_Low*SEMv);  % Confidence Intervals
        CIv_High{terminals{mouse}(ccell)} = (SNvwData{terminals{mouse}(ccell)}) + (tsv_High*SEMv);  % Confidence Intervals 
        SEMc = (nanstd(caStackArray2{terminals{mouse}(ccell)}))/(sqrt(size(caStackArray2{terminals{mouse}(ccell)},1))); %#ok<*NANSTD> % Standard Error                    
        tsc_Low = tinv(0.025,size(caStackArray2{terminals{mouse}(ccell)},1)-1);% T-Score for 95% CI
        tsc_High = tinv(0.975,size(caStackArray2{terminals{mouse}(ccell)},1)-1);% T-Score for 95% CI
        CIc_Low{terminals{mouse}(ccell)} = (SNcaData{terminals{mouse}(ccell)}) + (tsc_Low*SEMc);  % Confidence Intervals
        CIc_High{terminals{mouse}(ccell)} = (SNcaData{terminals{mouse}(ccell)}) + (tsc_High*SEMc);  % Confidence Intervals         
    end 
elseif ETAorSTAq == 1 % ETA data 
    % determine the average 
    avVWdata = nanmean(vwStackArray2,1);         
    %temporal smoothing option
    smoothQ = input('Input 0 if you do not want to do temporal smoothing. Input 1 otherwise. ');
    if smoothQ == 0 
        SNvwData = avVWdata;
    elseif smoothQ == 1
        filtTime = input('How many seconds do you want to smooth your data by? '); % our favorite STA trace is smoothed by 0.7 sec 
        filter_rate = FPSstack{mouse}*filtTime; 
        SNvwData = smoothdata(avVWdata,2,'movmean',filter_rate);    
        SNvwStackArray2 = smoothdata(vwStackArray2,2,'movmean',filter_rate);    
    end 
    %DETERMINE 95% CI                       
    SEMv = (nanstd(SNvwStackArray2))/(sqrt(size(SNvwStackArray2,1))); %#ok<*NANSTD> % Standard Error            
    tsv_Low = tinv(0.025,size(SNvwStackArray2,1)-1);% T-Score for 95% CI
    tsv_High = tinv(0.975,size(SNvwStackArray2,1)-1);% T-Score for 95% CI
    CIv_Low = (SNvwData) + (tsv_Low*SEMv);  % Confidence Intervals
    CIv_High = (SNvwData) + (tsv_High*SEMv);  % Confidence Intervals    
end 

% plot 
if ETAorSTAq == 0 % STA data    
    % allCAdata(ccell,:) = SNcaData{terminals{mouse}(ccell)};
    allCAdata = nan(length(terminals{mouse}),length(SNcaData{terminals{mouse}(1)}));
    allVWdata = nan(length(terminals{mouse}),length(SNcaData{terminals{mouse}(1)}));
    for ccell = 1:length(terminals{mouse})       
        % code in buffer space for plotting          
        %determine range of data Ca data
        CaDataRange = max(avCAdata{terminals{mouse}(ccell)})-min(avCAdata{terminals{mouse}(ccell)});
        %determine plotting buffer space for Ca data 
        CaBufferSpace = CaDataRange;
        %determine first set of plotting min and max values for Ca data
        CaPlotMin = min(avCAdata{terminals{mouse}(ccell)})-CaBufferSpace;
        CaPlotMax = max(avCAdata{terminals{mouse}(ccell)})+CaBufferSpace; 
        %determine Ca 0 ratio/location 
        % CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);
        %determine range of VW data 
        VWdataRange = max(avVWdata{terminals{mouse}(ccell)})-min(avVWdata{terminals{mouse}(ccell)}); 
        %determine plotting buffer space for BBB data 
        VWbufferSpace = VWdataRange;
        %determine first set of plotting min and max values for BBB data
        VWplotMin = min(avVWdata{terminals{mouse}(ccell)})-VWbufferSpace;
        VWplotMax = max(avVWdata{terminals{mouse}(ccell)})+VWbufferSpace; 
        %determine VW 0 ratio/location
        VWzeroRatio = abs(VWplotMin)/(VWplotMax-VWplotMin);
        %determine how much to shift the CA axis so that the zeros align 
        CAbelowZero = (CaPlotMax-CaPlotMin)*VWzeroRatio;
        CAaboveZero = (CaPlotMax-CaPlotMin)-CAbelowZero;
        % plot data  
        x = 1:length(avVWdata{terminals{mouse}(ccell)});                          
        figure;
        Frames = length(x);
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
        FrameVals = round((1:FPSstack{mouse}:Frames))+4; 
        ax=gca;
        hold all
        plot(SNvwData{terminals{mouse}(ccell)},'k','LineWidth',2)
        patch([x fliplr(x)],[CIv_Low{terminals{mouse}(ccell)} fliplr(CIv_High{terminals{mouse}(ccell)})],'k','EdgeColor','none')
        alpha(0.3)
        % changePt = floor(windFrames/2);
        FrameVals(3) = threshFrame;
        FrameVals(2) = threshFrame - (Frames/5);
        FrameVals(1) = FrameVals(2) - (Frames/5);
        FrameVals(4) = threshFrame + (Frames/5);
        FrameVals(5) = FrameVals(4) + (Frames/5);
        ax.XTick = FrameVals;
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;   
        ax.FontSize = 15;
        ax.FontName = 'Arial';
        xlabel('time (s)','FontName','Arial')
        tempSmoothLabel = sprintf('%.2f second smoothing.',filtTime);
        ylabel({'z-scored vessel width';tempSmoothLabel},'FontName','Arial')
        % xLimStart = floor(10*FPSstack{mouse});
        % set(fig,'position', [500 100 900 800])  
        yyaxis right
        plot(SNcaData{terminals{mouse}(ccell)},'b','LineWidth',2)
        patch([x fliplr(x)],[CIc_Low{terminals{mouse}(ccell)} fliplr(CIc_High{terminals{mouse}(ccell)})],'b','EdgeColor','none')
        alpha(0.3)
        ylabel('z-scored calcium','FontName','Arial')
        axonLabel = sprintf('Axon %d.',terminals{mouse}(ccell));
        title({'Spike-Triggered Average.';axonLabel})
        set(gca,'YColor','b');   
        ylim([-CAbelowZero CAaboveZero])  
        xlim([1 length(SNcaData{terminals{mouse}(ccell)})])
        % put data together for averaged figure 
        allCAdata(ccell,:) = SNcaData{terminals{mouse}(ccell)};
        allVWdata(ccell,:) = SNvwData{terminals{mouse}(ccell)};
    end 
    % plot average change in VW and CA data across axons 
    avAllCAdata = nanmean(allCAdata,1);  
    avAllVWdata = nanmean(allVWdata,1);
    %DETERMINE 95% CI                       
    SEMvAv = (nanstd(allVWdata))/(sqrt(size(allVWdata,1))); %#ok<*NANSTD> % Standard Error     
    tsvAv_Low = tinv(0.025,size(allVWdata,1)-1);% T-Score for 95% CI
    tsvAv_High = tinv(0.975,size(allVWdata,1)-1);% T-Score for 95% CI
    CIvAv_Low = (avAllVWdata) + (tsvAv_Low*SEMvAv);  % Confidence Intervals
    CIvAv_High = (avAllVWdata) + (tsvAv_High*SEMvAv);  % Confidence Intervals 
    SEMcAv = (nanstd(allCAdata))/(sqrt(size(allCAdata,1))); %#ok<*NANSTD> % Standard Error     
    tscAv_Low = tinv(0.025,size(allCAdata,1)-1);% T-Score for 95% CI
    tscAv_High = tinv(0.975,size(allCAdata,1)-1);% T-Score for 95% CI
    CIcAv_Low = (avAllCAdata) + (tscAv_Low*SEMcAv);  % Confidence Intervals
    CIcAv_High = (avAllCAdata) + (tscAv_High*SEMcAv);  % Confidence Intervals     
    % plot 
    % code in buffer space for plotting          
    %determine range of data Ca data
    CaDataRange = max(avAllCAdata)-min(avAllCAdata);
    %determine plotting buffer space for Ca data 
    CaBufferSpace = CaDataRange;
    %determine first set of plotting min and max values for Ca data
    CaPlotMin = min(avAllCAdata)-CaBufferSpace;
    CaPlotMax = max(avAllCAdata)+CaBufferSpace; 
    %determine Ca 0 ratio/location 
    CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);  
    %determine range of VW data 
    VWdataRange = max(avAllVWdata)-min(avAllVWdata); 
    %determine plotting buffer space for BBB data 
    VWbufferSpace = VWdataRange;
    %determine first set of plotting min and max values for BBB data
    VWplotMin = min(avAllVWdata)-VWbufferSpace;
    VWplotMax = max(avAllVWdata)+VWbufferSpace; 
    %determine VW 0 ratio/location
    VWzeroRatio = abs(VWplotMin)/(VWplotMax-VWplotMin);
    %determine how much to shift the CA axis so that the zeros align 
    CAbelowZero = (CaPlotMax-CaPlotMin)*VWzeroRatio;
    CAaboveZero = (CaPlotMax-CaPlotMin)-CAbelowZero; 
    % plot data  
    x = 1:length(avVWdata{terminals{mouse}(ccell)});                          
    fig = figure;
    Frames = length(x);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
    FrameVals = round((1:FPSstack{mouse}:Frames))+4; 
    ax=gca;
    hold all
    plot(avAllVWdata,'k','LineWidth',2)
    patch([x fliplr(x)],[CIvAv_Low fliplr(CIvAv_High)],'k','EdgeColor','none')
    alpha(0.3)
    changePt = floor(windFrames/2);
    FrameVals(3) = threshFrame;
    FrameVals(2) = threshFrame - (Frames/5);
    FrameVals(1) = FrameVals(2) - (Frames/5);
    FrameVals(4) = threshFrame + (Frames/5);
    FrameVals(5) = FrameVals(4) + (Frames/5);
    ax.XTick = FrameVals;
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;   
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    xlabel('time (s)','FontName','Arial')
    tempSmoothLabel = sprintf('%.2f second smoothing.',filtTime);
    ylabel({'z-scored vessel width';tempSmoothLabel},'FontName','Arial')
    xLimStart = floor(10*FPSstack{mouse});
    % set(fig,'position', [500 100 900 800])  
    yyaxis right
    plot(avAllCAdata,'b','LineWidth',2)
    patch([x fliplr(x)],[CIcAv_Low fliplr(CIcAv_High)],'b','EdgeColor','none')
    alpha(0.3)
    ylabel('z-scored calcium','FontName','Arial')
    axonLabel = 'Averaged across axons.';
    title({'Spike-Triggered Average.';axonLabel})
    set(gca,'YColor','b');   
    ylim([-CAbelowZero CAaboveZero])  
    xlim([1 length(SNcaData{terminals{mouse}(ccell)})])
    % put data together for averaged figure 
    allCAdata(ccell,:) = SNcaData{terminals{mouse}(ccell)};
    allVWdata(ccell,:) = SNvwData{terminals{mouse}(ccell)};
elseif ETAorSTAq == 1 % ETA data 
    % plot data          
    x = 1:length(avVWdata);                          
    fig = figure;
    Frames = length(x);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
    FrameVals = round((1:FPSstack{mouse}:Frames))+4; 
    ax=gca;
    hold all
    plot(SNvwData,'k','LineWidth',2)
    patch([x fliplr(x)],[CIv_Low fliplr(CIv_High)],'k','EdgeColor','none')
    alpha(0.3)
    changePt = floor(windFrames/2);
    FrameVals(3) = threshFrame;
    FrameVals(2) = threshFrame - (Frames/5);
    FrameVals(1) = FrameVals(2) - (Frames/5);
    FrameVals(4) = threshFrame + (Frames/5);
    FrameVals(5) = FrameVals(4) + (Frames/5);
    ax.XTick = FrameVals;
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;   
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    xlabel('time (s)','FontName','Arial')
    ylabel('z-scored vessel width','FontName','Arial')
    xLimStart = floor(10*FPSstack{mouse});
    tempSmoothLabel = sprintf('%.2f second smoothing.',filtTime);
    if ETAtype == 0 % opto data 
      title({'Opto-Triggered Average.';tempSmoothLabel})
    elseif ETAtype == 1 % behavior data 
        if ETAtype2 == 0 % stim aligned 
            title({'Stim-Triggered Average.';tempSmoothLabel})
        elseif ETAtype2 == 1 % reward aligned 
            title({'Reward-Triggered Average.';tempSmoothLabel})
        end 
    end 
    xlim([1 length(avVWdata)])
end 


% below is first attempt to write my own clustering algorithm ~ TRYING
% OTHER TECHNIQUES FIRST - DBSCAN CODE ABOVE WORKS WAY BETTER 
%{
% use 
% RightChan{terminals{mouse}(ccell)}(:,:,frame) % the % change vid 
% BW_perim{terminals{mouse}(ccell)}(:,:,frame) % the outline made from the
% % change vid 
incC = cell(1,length(terminals{mouse}));
incR = cell(1,length(terminals{mouse}));
surValCurFrame = cell(1,length(terminals{mouse}));
surValNexFrame = cell(1,length(terminals{mouse}));
surValIncR = cell(1,length(terminals{mouse}));
surValIncC = cell(1,length(terminals{mouse}));
for mouse = 1:mouseNum
    for ccell = 1:length(terminals{mouse})       
        for frame = 2:size(RightChan{terminals{mouse}(ccell)},3)
            % need to dilate BW_perim 
            expandedMask = imdilate(BW_perim{terminals{mouse}(ccell)}(:,:,frame), strel('disk', 1));
            % find values in BBB vid where the expanded mask is 
            [rMask,cMask] = find(expandedMask == 1);
            val = zeros(1,length(rMask));
            for pix = 1:length(rMask)
                val(pix) = RightChan{terminals{mouse}(ccell)}(rMask(pix),cMask(pix),frame);
            end 
            % find where the 0 vals are and remove them and associated
            % indices 
            zeroVals = find(val == 0);
            val(zeroVals) = []; rMask(zeroVals) = []; cMask(zeroVals) = [];             
            valPrevFrame = zeros(1,length(rMask));
            for pix = 1:length(rMask)
                % figure out what the vals were in the previous frame
                valPrevFrame(pix) = RightChan{terminals{mouse}(ccell)}(rMask(pix),cMask(pix),frame-1);
                % find positive % increase around vessel outline   
                if val(pix)-valPrevFrame(pix) > 0 
                    incC{ccell}{frame}(pix) = cMask(pix);
                    incR{ccell}{frame}(pix) = rMask(pix);
                end                 
            end        
            % remove 0s in incCR 
             incC{ccell}{frame}(incC{ccell}{frame}==0) = []; incR{ccell}{frame}(incR{ccell}{frame}==0) = [];            
            if frame < size(RightChan{terminals{mouse}(ccell)},3)               
                for pix = 1:length(incC{ccell}{frame})
                    % determine the indices of surrounding pixels 
                    surPixC = incC{ccell}{frame}(pix)-1:incC{ccell}{frame}(pix)+1;
                    surPixR = incR{ccell}{frame}(pix)-1:incR{ccell}{frame}(pix)+1;                    
                    % determine the values of surrounding pixels in the
                    % next frame 
                    count = 1;
                    for r = 1:length(surPixR) 
                        for c = 1:length(surPixC)
                            if c ~= incC{ccell}{frame}(pix)
                                surValCurFrame{ccell}{frame}(pix,count) = RightChan{terminals{mouse}(ccell)}(surPixR(r),surPixC(c),frame);
                                surValNexFrame{ccell}{frame}(pix,count) = RightChan{terminals{mouse}(ccell)}(surPixR(r),surPixC(c),frame+1);
                                count = count + 1;
                            end                            
                        end                        
                    end                                         
                end 
                % replace 0s with NaNs in surVals 
                surValCurFrame{ccell}{frame}(surValCurFrame{ccell}{frame}==0) = NaN;
                surValNexFrame{ccell}{frame}(surValNexFrame{ccell}{frame}==0) = NaN;
                % figure out if it spreads by looking at surrounding pixels 
                [surValIncR2,surValIncC2] = find((surValNexFrame{ccell}{frame} - surValCurFrame{ccell}{frame}) > 0); 
                surValIncR{ccell}{frame} = surValIncR2; surValIncC{ccell}{frame} = surValIncC2;
            end 
        end                 
    end     
end 

%NEXT: NEED TO FIGURE OUT HOW TO ITERATIVELY KEEP LOOKING FOR GROWTH IN THE
%PLUME 

%}
%}
%%  DBSCAN time locked to axon calcium spikes and opto stim (Data averaged across mice. Must run each animal data through other DBSCAN code and save .mat first.) 
%{
% check to see if there's any data loaded in workspace from previous
% averaging, if so you can add animals to this data set if you want 
if exist('mouseNum','var') == 0
    mouseNum = input('How many animals would you like to average? ');
    mouseNumLabel = input('What are the mouse identifaction numbers? ');
    terminals = cell(1,mouseNum);
    nearVsFarPlotData = cell(1,mouseNum);
    numPixels = cell(1,mouseNum);
    numClusts = cell(1,mouseNum);
    totalNumPixels = nan(1,mouseNum);
    totalNumClusts = nan(1,mouseNum);
    uniqClustPixNums = cell(1,mouseNum);
    totalUniqClustPixNums = nan(1,mouseNum);
    avNumUniqClustPixNums = nan(1,mouseNum);
    medNumUniqClustPixNums = nan(1,mouseNum);
    sizeDistArray = cell(1,mouseNum);
    ampDistArray = cell(1,mouseNum);
    timeDistArray = cell(1,mouseNum);
    timeODistArray = cell(1,mouseNum);
    timeVRDistArray = cell(1,mouseNum);
    FPS = cell(1,mouseNum);
    mouseNumLabelString = strings(1,mouseNum);
    avClocFrame = cell(1,mouseNum);
    axonTypes = nan(mouseNum,3);
    minVAdists = cell(1,mouseNum);
    clustSize = cell(1,mouseNum); 
    clustAmp = cell(1,mouseNum); 
    clustSizeTS = cell(1,mouseNum); 
    clustPixAmpTS = cell(1,mouseNum); 
    avVWdata = cell(1,mouseNum);
    avCAdata = cell(1,mouseNum);
    plumeIdx = cell(1,mouseNum);
    indsV = cell(1,mouseNum);
    unIdxVals = cell(1,mouseNum);
    XpixDist = nan(1,mouseNum);
    YpixDist = nan(1,mouseNum);
    plumeInds = cell(1,mouseNum);
    for mouse = 1:mouseNum
        % import the data for each mouse 
        dir = uigetdir('*.*',sprintf('SELECT FILE LOCATION FOR MOUSE %d?',mouseNumLabel(mouse)));
        cd(dir);
        data = uigetfile('*.*',sprintf('SELECT THE .MAT FILE FOR MOUSE %d',mouseNumLabel(mouse))); 
        dataMat = matfile(data); 
        % know what kind of data set you have 
        if mouse == 1 
            ETAorSTAq = dataMat.ETAorSTAq;
            if ETAorSTAq == 1 % if it's ETA data 
                ETAtype = dataMat.ETAtype; % input('Input 0 if this is opto data. Input 1 for behavior data. ');
                if ETAtype == 1 
                    ETAtype2 = dataMat.ETAtype2; %  input('Input 0 if the data is time locked to the stim. Input 1 if time locked to the reward. ');
                end 
            end 
            clustSpikeQ = dataMat.clustSpikeQ; % clustSpikeQ == 0 (all spikes)
            if clustSpikeQ == 1 % clustSpikeQ == 1 (either pre or post event spikes)
                clustSpikeQ2 = dataMat.clustSpikeQ2; % clustSpikeQ2 == 0 (pre event spikes) clustSpikeQ2 == 1 (post event spikes)
            end 
            clustSpikeQ3 = dataMat.clustSpikeQ3; % clustSpikeQ3 == 0 (average time of BBB plume) clustSpikeQ3 == 1 (BBB plume start time)
            windSize = dataMat.windSize; 
            filtTime = dataMat.filtTime;
        end 
        % import data needed to plot the porportion of clusters that are
        % near the vessel out of total # of clusters 
        terms = dataMat.terminals; 
        terminals{mouse} = terms{1}; clearvars terms; 
        variableInfo = who(dataMat);
        if ismember("nearVsFarPlotData", variableInfo) == 1 % returns true 
            nearVsFarPlotData{mouse} = dataMat.nearVsFarPlotData;                
        end 
        % import data needed to plot the number of pixels per cluster, the number of total pixels and the number of total clusters
        numPixels{mouse} = dataMat.numPixels; 
        totalNumPixels(mouse) = dataMat.totalNumPixels;       
        numClusts{mouse} = dataMat.numClusts;
        totalNumClusts(mouse) = dataMat.totalNumClusts;      
        uniqClustPixNums{mouse} = dataMat.uniqClustPixNums;
        % import data needed to plot the distribution of axon distances from the vessel 
        if ETAorSTAq == 0 % STA data
            minVAdists{mouse} = dataMat.minVAdists;
        end 
        % import data needed to plot cluster size and pixel amplitude as function of distance from axon
        % this data is also needed to plot the distribution of BBB cluster pixel amplitudes and sizes
        sizeDistArray{mouse} = dataMat.sizeDistArray;           
        ampDistArray{mouse} = dataMat.ampDistArray;
        % import data needed to plot distance from axon and VR space as a function of cluster timing
        if ETAorSTAq == 0 % STA data
            timeDistArray{mouse} = dataMat.timeDistArray;   
            timeODistArray{mouse} = dataMat.timeODistArray;   
        end 
        if ismember("timeVRDistArray", variableInfo) == 1 % returns true 
            timeVRDistArray{mouse} = dataMat.timeVRDistArray;              
        end 
        % import data needed to do time conversion (relative to FPS
        % differences across mice) 
        FPS{mouse} = dataMat.FPS; 
        % create legend labels 
        mouseNumLabelString(mouse) = num2str(mouseNumLabel(mouse));
        % import data needed to plot distribution of cluster times 
        avClocFrame{mouse} = dataMat.avClocFrame;
        if ETAorSTAq == 0 % STA data
            axonTypes(mouse,:) = dataMat.axonTypes;
        end
        % import data to plot cluster size and pixel amp all together and grouped by pre and post spike
        clustSize{mouse} = dataMat.clustSize;
        clustAmp{mouse} = dataMat.clustAmp;
        % import data to plot change in cluster size and pixel amplitude over time
        clustSizeTS{mouse} = dataMat.clustSizeTS;
        clustPixAmpTS{mouse} = dataMat.clustPixAmpTS;
        % import data to plot change in vessel width 
        avVWdata{mouse} = dataMat.SNvwData;
        if ETAorSTAq == 0 % STA data
            avCAdata{mouse} = dataMat.avCAdata;
        end 
        % import data to plot plume origin distance from vessel histogram and scatter plot
        % relative to time 
        plumeIdx{mouse} = dataMat.idx;
        data = dataMat.indsV;
        if iscell(data)
            indsV{mouse} = data{1};
        end 
        unIdxVals{mouse} = dataMat.unIdxVals;
        XpixDist(mouse) = dataMat.XpixDist;
        YpixDist(mouse) = dataMat.YpixDist;
        plumeInds{mouse} = dataMat.inds;
    end 
elseif exist('mouseNum','var') == 1
    % FINISH CODING THIS IN LATER WHEN RELEVANT (WHEN I NEED TO ADD ANIMALS TO THE DATA SET), RIGHT NOW THE LOGIC IS
    % CORRECT 
    fprintf("There is data from %d animals: ", mouseNum);
    disp(mouseNumLabel);
    addDataQ = input('Input 1 if you want to add animals to this data set. Input 0 otherwise. ');
    % add animals to this data set if you want 
    if addDataQ == 1 
        addMouseNum = input('How many mice would you like to add to this data set? ');
        for mouse = 1:addMouseNum
        end 
    end 
end 

%% plot the proportion of clusters that are near the vessel out of total # of clusters 
% resort the data for plotting 
AvNearVsFarPlotData = nan(mouseNum,2);
for mouse = 1:mouseNum
    AvNearVsFarPlotData(mouse,:) = mean(nearVsFarPlotData{mouse},1);
end 
% plot stacked bar plot
figure;
subplot(1,2,1)
ax=gca;
ba = bar(AvNearVsFarPlotData,'stacked','FaceColor','flat');
ba(1).CData = [0 0.4470 0.7410];
ba(2).CData = [0.8500 0.3250 0.0980];
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("Number of Clusters")
xlabel('Mouse')
legend("Clusters Near Vessel","Clusters Far from Vessel")
xticklabels(mouseNumLabel)
% plot pie chart 
subplot(1,2,2)
% resort data for averaged pie chart 
totalAvNearVsFarPlotData = mean(AvNearVsFarPlotData,1);
pie(totalAvNearVsFarPlotData);
colormap([0 0.4470 0.7410; 0.8500 0.3250 0.0980])
%% plot the number of pixels per cluster, the number of total pixels and the number of total clusters
% resort data for plotting 
figure;
for mouse = 1:mouseNum
    if mouse == 1 
        NumPixels = numPixels{1};
        NumClusts = numClusts{1};
        UniqClustPixNums = uniqClustPixNums{1};
    elseif mouse > 1
        len = length(NumPixels);
        NumPixels(len+1:length(numPixels{mouse})+len) = numPixels{mouse};
        len2 = length(NumClusts);
        NumClusts(len2+1:length(numClusts{mouse})+len2) = numClusts{mouse};
        len3 = length(UniqClustPixNums);
        UniqClustPixNums(len3+1:length(uniqClustPixNums{mouse})+len3) = uniqClustPixNums{mouse};
    end 
end 
subplot(1,3,1)
histogram(NumPixels,10)
totalPixelNumLabel = sprintf('%.0f microns squared total.',sum(totalNumPixels));
if ETAorSTAq == 0 % STA data
    avPixelNumLabel = sprintf('%.0f average microns squared per axon.',mean(totalNumPixels));
    medPixelNumLabel = sprintf('%.0f median microns squared per axon.',median(totalNumPixels));
elseif  ETAorSTAq == 1 % ETA data
    avPixelNumLabel = sprintf('%.0f average microns squared per animal.',mean(totalNumPixels));
    medPixelNumLabel = sprintf('%.0f median microns squared per animal.',median(totalNumPixels));    
end 
title({totalPixelNumLabel;avPixelNumLabel;medPixelNumLabel})
if ETAorSTAq == 0 % STA data 
    xlabel('microns squared per axon')
    ylabel('number of axons')
elseif ETAorSTAq == 1 % if it's ETA data 
    xlabel('microns squared per animal')
    ylabel('number of animals')   
end 
ax = gca;
ax.FontSize = 15;
subplot(1,3,2)
histogram(NumClusts,10)
totalClustNumLabel = sprintf('%.0f clusters total.',sum(totalNumClusts));
avClustNumLabel = sprintf('%.0f average clusters per animal.',mean(totalNumClusts));
medClustNumLabel = sprintf('%.0f median clusters per animal.',median(totalNumClusts));
title({totalClustNumLabel;avClustNumLabel;medClustNumLabel})
xlabel('number of BBB clusters per animal')
ylabel('number of animals')
ax = gca;
ax.FontSize = 15;
subplot(1,3,3)
histogram(UniqClustPixNums,10)
avUniqClustPixNumsLabel = sprintf('%.0f average microns squared per cluster.',mean(UniqClustPixNums));
medNumUniqClustPixNumsLabel = sprintf('%.0f median microns squared per cluster.',median(UniqClustPixNums));
title({avUniqClustPixNumsLabel;medNumUniqClustPixNumsLabel})
xlabel('microns squared per cluster')
ylabel('number of clusters')
ax = gca;
% set(gca,'XTick',0:1000:100000,'XTickLabelRotation',45)
ax.FontSize = 15;

figure;
histogram(UniqClustPixNums,500)
avUniqClustPixNumsLabel = sprintf('%.0f average microns squared per cluster.',mean(UniqClustPixNums));
medNumUniqClustPixNumsLabel = sprintf('%.0f median microns squared per cluster.',median(UniqClustPixNums));
title({avUniqClustPixNumsLabel;medNumUniqClustPixNumsLabel})
xlabel('microns squared per cluster')
ylabel('number of clusters')
ax = gca;
% set(gca,'XTick',0:1000:100000,'XTickLabelRotation',45)
set(gca, 'XScale', 'log')
ax.FontSize = 15;
%% plot distribution of axon distances from the vessel 
if ETAorSTAq == 0 % STA data 
    if exist('allMinVAdists','var') == 0
        for mouse = 1:mouseNum
            % resort sizeDistArray into one array where column variables relate to
            % animal number not terminal 
            if mouse == 1 
                allMinVAdists(1,:) = minVAdists{mouse};
            elseif mouse > 1
                len = length(allMinVAdists);
                allMinVAdists(1,len+1:length(minVAdists{mouse})+len) = minVAdists{mouse};
            end 
        end 
    end 
    figure;
    ax=gca;
    histogram(allMinVAdists,61) % usually 61
    set(gca,'XTick',0:10:310,'XTickLabelRotation',45)
    avVAdists = nanmean(allMinVAdists); 
    medVAdists = nanmedian(allMinVAdists); %#ok<*NANMEDIAN>
    avVAdistsLabel = sprintf('Average axon distance from vessel: %.3f',avVAdists);
    medVAdistsLabel = sprintf('Median axon distance from vessel: %.3f',medVAdists);
    ax.FontSize = 15;
    % ax.FontName = 'Times';
    title({'Distribution of Axon Distance from Vessel';avVAdistsLabel;medVAdistsLabel});
    ylabel("Number of Axons")
    xlabel("Distance (microns)") 
end 
%% plot cluster size and pixel amplitude as function of distance from axon
if exist('allSizeDistArray','var') == 0
    for mouse = 1:mouseNum
        % resort sizeDistArray into one array where column variables relate to
        % animal number not terminal 
        if mouse == 1 
            allSizeDistArray(:,1) = sizeDistArray{mouse}(:,1);
            allSizeDistArray(:,2) = sizeDistArray{mouse}(:,2);
            allSizeDistArray(:,3) = mouse;
        elseif mouse > 1
            len = size(allSizeDistArray,1);
            allSizeDistArray(len+1:size(sizeDistArray{mouse},1)+len,1) = sizeDistArray{mouse}(:,1);
            allSizeDistArray(len+1:size(sizeDistArray{mouse},1)+len,2) = sizeDistArray{mouse}(:,2);
            allSizeDistArray(len+1:size(sizeDistArray{mouse},1)+len,3) = mouse;
        end 
    end 
end 
if exist('allAmpDistArray','var') == 0
    for mouse = 1:mouseNum
        % resort sizeDistArray into one array where column variables relate to
        % animal number not terminal 
        if mouse == 1 
            allAmpDistArray(:,1) = ampDistArray{mouse}(:,1);
            allAmpDistArray(:,2) = ampDistArray{mouse}(:,2);
            allAmpDistArray(:,3) = mouse;
        elseif mouse > 1
            len = size(allAmpDistArray,1);
            allAmpDistArray(len+1:size(ampDistArray{mouse},1)+len,1) = ampDistArray{mouse}(:,1);
            allAmpDistArray(len+1:size(ampDistArray{mouse},1)+len,2) = ampDistArray{mouse}(:,2);
            allAmpDistArray(len+1:size(ampDistArray{mouse},1)+len,3) = mouse;
        end 
    end 
end 
if ETAorSTAq == 0 % STA data 
    figure;
    ax=gca;
    clr = hsv(mouseNum);
    f = cell(1,mouseNum);
    for mouse = 1:mouseNum
        % calculate f (trend line) for each mouse 
        includeX =~ isnan(sizeDistArray{mouse}(:,1)); includeY =~ isnan(sizeDistArray{mouse}(:,2)); 
        [zeroRow, ~] = find(includeY == 0);
        includeX(zeroRow) = 0; includeXY = includeX;           
        sizeDistX = sizeDistArray{mouse}(:,1); sizeDistY = sizeDistArray{mouse}(:,2);  
        if sum(includeXY) > 1 
            f{mouse} = fit(sizeDistX(includeXY),sizeDistY(includeXY),'poly1');  
        end 
    end    
    gscatter(allSizeDistArray(:,1),allSizeDistArray(:,2),allSizeDistArray(:,3),clr)
    ax.FontSize = 15;
    ax.FontName = 'Times';
    legend(mouseNumLabelString)
    hold all;
    % plot the trend line for each mouse 
    for mouse = 1:mouseNum
        fitHandle = plot(f{mouse});
        set(fitHandle,'Color',clr(mouse,:));
    end 
    % calculate fav (trend line) of all data 
    includeX =~ isnan(allSizeDistArray(:,1)); includeY =~ isnan(allSizeDistArray(:,2));
    [zeroRow, ~] = find(includeY == 0);
    includeX(zeroRow) = 0; includeXY = includeX;                
    sizeDistX = allSizeDistArray(:,1); sizeDistY = allSizeDistArray(:,2);   
    if length(find(includeXY)) > 1
        fav = fitlm(sizeDistX(includeXY),sizeDistY(includeXY),'poly1');
    end 
    % plot trend line for all data 
    if length(find(includeXY)) > 1
        fitHandle = plot(fav);
        leg = legend('show');
        set(fitHandle,'Color',[0 0 0],'LineWidth',3);
        leg.String(end) = [];
        rSquared = string(round(fav.Rsquared.Ordinary,2));
        text(100,20000,rSquared,'FontSize',20)
    end 
    ylabel("Size of Cluster (microns squared)")
    xlabel("Distance From Axon (microns)") 
    if clustSpikeQ == 0 
        title('All Clusters');
    elseif clustSpikeQ == 1 
        if clustSpikeQ2 == 0 
            title('Pre Spike Clusters');
        elseif clustSpikeQ2 == 1
            title('Post Spike Clusters');
        end 
    end 

    figure;
    ax=gca;
    fAmp = cell(1,mouseNum);
    for mouse = 1:mouseNum
        % calculate f (trend line) for each mouse 
        includeX =~ isnan(ampDistArray{mouse}(:,1)); includeY =~ isnan(ampDistArray{mouse}(:,2)); 
        [zeroRow, ~] = find(includeY == 0);
        includeX(zeroRow) = 0; includeXY = includeX;           
        ampDistX = ampDistArray{mouse}(:,1); ampDistY = ampDistArray{mouse}(:,2);  
        if sum(includeXY) > 1 
            fAmp{mouse} = fit(ampDistX(includeXY),ampDistY(includeXY),'poly1');  
        end 
    end  
    gscatter(allAmpDistArray(:,1),allAmpDistArray(:,2),allAmpDistArray(:,3),clr)
    ax.FontSize = 15;
    ax.FontName = 'Times';
    legend(mouseNumLabelString)
    hold all;
    % plot the trend line for each mouse 
    for mouse = 1:mouseNum
        fitHandle = plot(fAmp{mouse});
        set(fitHandle,'Color',clr(mouse,:));
    end 
    % calculate favAmp (trend line) of all data 
    includeX =~ isnan(allAmpDistArray(:,1)); includeY =~ isnan(allAmpDistArray(:,2));
    [zeroRow, ~] = find(includeY == 0);
    includeX(zeroRow) = 0; includeXY = includeX;                
    ampDistX = allAmpDistArray(:,1); ampDistY = allAmpDistArray(:,2);   
    if length(find(includeXY)) > 1
        favAmp = fitlm(ampDistX(includeXY),ampDistY(includeXY),'poly1');
    end 
    % plot trend line for all data 
    if length(find(includeXY)) > 1
        fitHandle = plot(favAmp);
        leg = legend('show');
        set(fitHandle,'Color',[0 0 0],'LineWidth',3);
        leg.String(end) = [];
        rSquared = string(round(favAmp.Rsquared.Ordinary,2));
        text(50,0.05,rSquared,'FontSize',20)
    end 
    ylabel("Pixel Amplitude of Cluster")
    xlabel("Distance From Axon (microns)") 
    if clustSpikeQ == 0 
        title('All Clusters');
    elseif clustSpikeQ == 1 
        if clustSpikeQ2 == 0 
            title('Pre Spike Clusters');
        elseif clustSpikeQ2 == 1
            title('Post Spike Clusters');
        end 
    end 
end 
%% plot distance from axon and VR space as a function of cluster timing
if ETAorSTAq == 0 % STA data 
    clr = hsv(mouseNum);
    figure;
    ax=gca;
    if exist('allTimeDistArray','var') == 0
        for mouse = 1:mouseNum
            % resort DistArray into one array where column variables relate to
            % animal number not terminal 
            if mouse == 1 
                allTimeDistArray(:,1) = ((timeDistArray{mouse}(~isnan(timeDistArray{mouse}(:,1)),1))/FPS{mouse})-windSize/2; % converts frame to time in sec for comparison across mice 
                allTimeDistArray(:,2) = timeDistArray{mouse}(~isnan(timeDistArray{mouse}(:,1)),2);
                allTimeDistArray(:,3) = mouse;
            elseif mouse > 1
                len = size(allTimeDistArray,1);
                allTimeDistArray(len+1:sum(~isnan(timeDistArray{mouse}(:,1)))+len,1) = ((timeDistArray{mouse}(~isnan(timeDistArray{mouse}(:,1)),1))/FPS{mouse})-windSize/2; % converts frame to time in sec for comparison across mice 
                allTimeDistArray(len+1:sum(~isnan(timeDistArray{mouse}(:,1)))+len,2) = timeDistArray{mouse}(~isnan(timeDistArray{mouse}(:,1)),2);
                allTimeDistArray(len+1:sum(~isnan(timeDistArray{mouse}(:,1)))+len,3) = mouse;
            end 
        end 
    end 
    f2 = cell(1,mouseNum);
    for mouse = 1:mouseNum
        % calculate f (trend line) for each mouse 
        includeX =~ isnan(timeDistArray{mouse}(:,1)); includeY =~ isnan(timeDistArray{mouse}(:,2)); 
        [zeroRow, ~] = find(includeY == 0);
        includeX(zeroRow) = 0; includeXY = includeX;           
        timeDistX = timeDistArray{mouse}(:,1); timeDistY = timeDistArray{mouse}(:,2);  
        if sum(includeXY) > 1 
            f2{mouse} = fit(timeDistX(includeXY),timeDistY(includeXY),'poly1');  
        end 
    end  
    gscatter(allTimeDistArray(:,1),allTimeDistArray(:,2),allTimeDistArray(:,3),clr)
    ax.FontSize = 15;
    ax.FontName = 'Times';
    legend(mouseNumLabelString)
    hold all;
    % plot the trend line for each mouse 
    for mouse = 1:mouseNum
        fitHandle = plot(f2{mouse});
        set(fitHandle,'Color',clr(mouse,:));
    end 
    % calculate fav2 (trend line) of all data 
    includeX =~ isnan(allTimeDistArray(:,1)); includeY =~ isnan(allTimeDistArray(:,2));
    [zeroRow, ~] = find(includeY == 0);
    includeX(zeroRow) = 0; includeXY = includeX;                
    timeDistX = allTimeDistArray(:,1); timeDistY = allTimeDistArray(:,2);   
    if length(find(includeXY)) > 1
        fav2 = fitlm(timeDistX(includeXY),timeDistY(includeXY),'poly1');
    end 
    % plot trend line for all data 
    if length(find(includeXY)) > 1
        fitHandle = plot(fav2);
        leg = legend('show');
        set(fitHandle,'Color',[0 0 0],'LineWidth',3);
        leg.String(end) = [];
        rSquared = string(round(fav2.Rsquared.Ordinary,2));
        text(1,200,rSquared,'FontSize',20)
    end    
    ylabel("Distance From Axon (microns)")
    if clustSpikeQ3 == 0 
        xlabel("Average BBB Plume Timing (sec)") 
    elseif clustSpikeQ3 == 1
        xlabel("BBB Plume Start Time (sec)") 
    end 
    title('BBB Plume Distance From Axon Compared to Timing'); 

    % plot the distribution of cluster distances from axon 
    figure;
    ax=gca;
    histogram(allTimeDistArray(:,2),61)
    set(gca,'XTick',0:10:ceil(max(allTimeDistArray(:,2))),'XTickLabelRotation',45)
    avCAdists = nanmean(allTimeDistArray(:,2)); 
    medCAdists = nanmedian(allTimeDistArray(:,2)); %#ok<*NANMEDIAN>
    avCAdistsLabel = sprintf('Average BBB plume distance from axon: %.3f',avCAdists);
    medCAdistsLabel = sprintf('Median BBB plume distance from axon: %.3f',medCAdists);
    ax.FontSize = 15;
    % ax.FontName = 'Times';
    title({'Distribution of BBB Plume Distance from Axon';avCAdistsLabel;medCAdistsLabel});
    ylabel("Number of BBB Plumes")
    xlabel("Distance (microns)") 
    % set(gca, 'XScale', 'log')

    figure;
    ax=gca;
    if exist('allTimeODistArray','var') == 0
        for mouse = 1:mouseNum
            % resort DistArray into one array where column variables relate to
            % animal number not terminal 
            if mouse == 1 
                allTimeODistArray(:,1) = ((timeODistArray{mouse}(:,1))/FPS{mouse})-windSize/2; % converts frame to time in sec for comparison across mice 
                allTimeODistArray(:,2) = timeODistArray{mouse}(:,2);
                allTimeODistArray(:,3) = mouse;
            elseif mouse > 1
                len = size(allTimeODistArray,1);
                allTimeODistArray(len+1:size(timeODistArray{mouse},1)+len,1) = ((timeODistArray{mouse}(:,1))/FPS{mouse})-windSize/2; % converts frame to time in sec for comparison across mice ;
                allTimeODistArray(len+1:size(timeODistArray{mouse},1)+len,2) = timeODistArray{mouse}(:,2);
                allTimeODistArray(len+1:size(timeODistArray{mouse},1)+len,3) = mouse;
            end 
        end 
    end 
    f2O = cell(1,mouseNum);
    for mouse = 1:mouseNum
        % calculate f (trend line) for each mouse 
        includeX =~ isnan(timeODistArray{mouse}(:,1)); includeY =~ isnan(timeODistArray{mouse}(:,2)); 
        [zeroRow, ~] = find(includeY == 0);
        includeX(zeroRow) = 0; includeXY = includeX;           
        timeODistX = timeODistArray{mouse}(:,1); timeODistY = timeODistArray{mouse}(:,2);  
        if sum(includeXY) > 1 
            f2O{mouse} = fit(timeODistX(includeXY),timeODistY(includeXY),'poly1');  
        end 
    end  
    gscatter(allTimeODistArray(:,1),allTimeODistArray(:,2),allTimeODistArray(:,3),clr)
    ax.FontSize = 15;
    ax.FontName = 'Times';
    legend(mouseNumLabelString)
    hold all;
    % plot the trend line for each mouse 
    for mouse = 1:mouseNum
        fitHandle = plot(f2O{mouse});
        set(fitHandle,'Color',clr(mouse,:));
    end 
    % calculate fav2O (trend line) of all data 
    includeX =~ isnan(allTimeODistArray(:,1)); includeY =~ isnan(allTimeODistArray(:,2));
    [zeroRow, ~] = find(includeY == 0);
    includeX(zeroRow) = 0; includeXY = includeX;                
    timeODistX = allTimeODistArray(:,1); timeODistY = allTimeODistArray(:,2);   
    if length(find(includeXY)) > 1
        fav2O = fitlm(timeODistX(includeXY),timeODistY(includeXY),'poly1');
    end 
    % plot trend line for all data 
    if length(find(includeXY)) > 1
        fitHandle = plot(fav2O);
        leg = legend('show');
        set(fitHandle,'Color',[0 0 0],'LineWidth',3);
        leg.String(end) = [];
        rSquared = string(round(fav2O.Rsquared.Ordinary,2));
        text(1,200,rSquared,'FontSize',20)
    end     
    ylabel("Distance From Axon (microns)")
    if clustSpikeQ3 == 0 
        xlabel("Average BBB Plume Timing (sec)") 
    elseif clustSpikeQ3 == 1
        xlabel("BBB Plume Start Time (sec)") 
    end 
    title('BBB Plume Origin Distance From Axon Compared to Timing'); 

    % plot the distribution of cluster origin distances from axon 
    figure;
    ax=gca;
    histogram(allTimeODistArray(:,2),61)
    set(gca,'XTick',0:10:ceil(max(allTimeODistArray(:,2))),'XTickLabelRotation',45)
    avCAdists = nanmean(allTimeODistArray(:,2)); 
    medCAdists = nanmedian(allTimeODistArray(:,2)); %#ok<*NANMEDIAN>
    avCAdistsLabel = sprintf('Average BBB plume origin distance from axon: %.3f',avCAdists);
    medCAdistsLabel = sprintf('Median BBB plume origin distance from axon: %.3f',medCAdists);
    ax.FontSize = 15;
    % ax.FontName = 'Times';
    title({'Distribution of BBB Plume Origin Distance from Axon';avCAdistsLabel;medCAdistsLabel});
    ylabel("Number of BBB Plumes")
    xlabel("Distance (microns)") 
    % set(gca, 'XScale', 'log')

end 
figure;
ax=gca;
if exist('allTimeVRDistArray','var') == 0
    for mouse = 1:mouseNum
        % resort DistArray into one array where column variables relate to
        % animal number not terminal 
        if mouse == 1 
            allTimeVRDistArray(:,1) = ((timeVRDistArray{mouse}(:,1))/FPS{mouse})-windSize/2; % converts frame to time in sec for comparison across mice ;
            allTimeVRDistArray(:,2) = timeVRDistArray{mouse}(:,2);
            allTimeVRDistArray(:,3) = mouse;
        elseif mouse > 1
            len = size(allTimeVRDistArray,1);
            allTimeVRDistArray(len+1:size(timeVRDistArray{mouse},1)+len,1) = ((timeVRDistArray{mouse}(:,1))/FPS{mouse})-windSize/2; % converts frame to time in sec for comparison across mice ;
            allTimeVRDistArray(len+1:size(timeVRDistArray{mouse},1)+len,2) = timeVRDistArray{mouse}(:,2);
            allTimeVRDistArray(len+1:size(timeVRDistArray{mouse},1)+len,3) = mouse;
        end 
    end 
end 
f3 = cell(1,mouseNum);
clr = hsv(mouseNum);
for mouse = 1:mouseNum
    % calculate f (trend line) for each mouse 
    includeX =~ isnan(timeVRDistArray{mouse}(:,1)); includeY =~ isnan(timeVRDistArray{mouse}(:,2)); 
    [zeroRow, ~] = find(includeY == 0);
    includeX(zeroRow) = 0; includeXY = includeX;           
    timeVRDistX = timeVRDistArray{mouse}(:,1); timeVRDistY = timeVRDistArray{mouse}(:,2);  
    if sum(includeXY) > 1 
        f3{mouse} = fit(timeVRDistX(includeXY),timeVRDistY(includeXY),'poly1');  
    end 
end  
gscatter(allTimeVRDistArray(:,1),allTimeVRDistArray(:,2),allTimeVRDistArray(:,3),clr)
ax.FontSize = 15;
ax.FontName = 'Times';
legend(mouseNumLabelString)
hold all;
% plot the trend line for each mouse 
for mouse = 1:mouseNum
    fitHandle = plot(f3{mouse});
    set(fitHandle,'Color',clr(mouse,:));
end 
% calculate fav3 (trend line) of all data 
includeX =~ isnan(allTimeVRDistArray(:,1)); includeY =~ isnan(allTimeVRDistArray(:,2));
[zeroRow, ~] = find(includeY == 0);
includeX(zeroRow) = 0; includeXY = includeX;                
timeVRDistX = allTimeVRDistArray(:,1); timeVRDistY = allTimeVRDistArray(:,2);   
if length(find(includeXY)) > 1
    fav3 = fitlm(timeVRDistX(includeXY),timeVRDistY(includeXY),'poly1');
end 
% plot trend line for all data 
if length(find(includeXY)) > 1
    fitHandle = plot(fav3);
    leg = legend('show');
    set(fitHandle,'Color',[0 0 0],'LineWidth',3);
    leg.String(end) = [];
    rSquared = string(round(fav3.Rsquared.Ordinary,2));
    text(0,130,rSquared,'FontSize',20)
end 
ylabel("Distance From VR space (microns)")
if clustSpikeQ3 == 0 
    xlabel("Average BBB Plume Timing (sec)") 
elseif clustSpikeQ3 == 1
    xlabel("BBB Plume Start Time (sec)") 
end 
title('BBB Plume Distance From VR Space Compared to Timing');

%% plot plume origin distance from vessel histogram, scatter plot relative to time, and plume origin location on vessel 
if exist('allAvClocFrameBoxPlot','var') == 0
    % determine the max length of the data per mouse 
    avClocFrameMouseLen = nan(1,mouseNum);
    for mouse = 1:mouseNum
        avClocFrameMouseLen(mouse) = size(avClocFrame{mouse},1)*size(avClocFrame{mouse},2);
    end 
    maxClocFrameMouseLen = max(avClocFrameMouseLen);
    % resort avClocFrame and convert to seconds centered around 0 
    allAvClocFrameBoxPlot = nan(maxClocFrameMouseLen,mouseNum);
    allAvClocFrameBoxPlot2 = nan(maxClocFrameMouseLen,mouseNum);
    for mouse = 1:mouseNum 
        allAvClocFrameBoxPlot(1:avClocFrameMouseLen(mouse),mouse) = (reshape(avClocFrame{mouse},1,avClocFrameMouseLen(mouse))/FPS{mouse})-windSize/2; % converts frame to time in sec for comparison across mice ;
        for ccell = 1:length(terminals{mouse})
            if ccell == 1 
                len = size(avClocFrame{mouse},2); len1 = 1; len2 = size(avClocFrame{mouse},2);  
                allAvClocFrameBoxPlot2(len1:len2,mouse) = (avClocFrame{mouse}(ccell,:)/FPS{mouse})-windSize/2; % converts frame to time in sec for comparison across mice ;                              
            elseif ccell > 1 
                len1 = len1 + len; len2 = len2 + len;
                allAvClocFrameBoxPlot2(len1:len2,mouse) = (avClocFrame{mouse}(ccell,:)/FPS{mouse})-windSize/2; % converts frame to time in sec for comparison across mice ;
            end 
        end 
    end 
end  

% determine plume origin distance from vessel 
clr = hsv(mouseNum);
dists = cell(1,mouseNum);
minCOVdists = cell(1,mouseNum);
COVdists = cell(1,mouseNum);
timeCOVdistArray = cell(1,mouseNum);
clearvars allTimeCOVdistArray
plumeOriginLocs = cell(1,mouseNum);
frameLen = nan(1,mouseNum);
for mouse = 1:mouseNum
    for ccell = 1:length(terminals{mouse})
        count = 1;
        for clust = 1:length(unIdxVals{mouse}{terminals{mouse}(ccell)})
           % find what rows each cluster is located in
            [Crow, ~] = find(plumeIdx{mouse}{terminals{mouse}(ccell)} == unIdxVals{mouse}{terminals{mouse}(ccell)}(clust)); 
            % identify the x, y, z location of pixels per cluster
            cLocs = plumeInds{mouse}{terminals{mouse}(ccell)}(Crow,:);  
            if isempty(cLocs) == 0 
                % determine the first frame that the cluster appears in 
                cFirstFrame = min(cLocs(:,3));
                [r,~] = find(cLocs(:,3) == cFirstFrame);
                % only select indices from the first time the cluster appears 
                cLocs = cLocs(r,:);
                % save plume origin locs for later 
                plumeOriginLocs{mouse}{ccell}{count} = cLocs;
                count = count + 1;
                % only look at vessel location where the cluster first
                % appears 
                [r,~] = find(indsV{mouse}(:,3) == cFirstFrame);
                clearvars indsVfirst
                indsVfirst = indsV{mouse}(r,:);
                % convert cLoc X and Y inds to microns 
                cLocs(:,1) = cLocs(:,1)*XpixDist(mouse); cLocs(:,2) = cLocs(:,2)*YpixDist(mouse); 
                for Vpoint = 1:size(indsVfirst,1)
                    for Cpoint = 1:size(cLocs,1)
                        % get euclidean micron distance between each vessel pixel
                        % and BBB cluster pixel 
                        dists{mouse}{terminals{mouse}(ccell)}{clust}(Vpoint,Cpoint) = sqrt(((cLocs(Cpoint,1)-indsVfirst(Vpoint,1))^2)+((cLocs(Cpoint,2)-indsVfirst(Vpoint,2))^2)); 
                    end 
                end 
            end
        end 
    end 
    if isempty(dists{mouse}) == 0 
        for ccell = 1:length(terminals{mouse})
            for clust = 1:length(dists{mouse}{terminals{mouse}(ccell)})
                % determine minimum distance between each Ca ROI and cluster 
                if isempty(dists{mouse}{terminals{mouse}(ccell)}{clust}) == 0
                    minCOVdists{mouse}(ccell,clust) = min(min(dists{mouse}{terminals{mouse}(ccell)}{clust}));
                end 
            end 
        end 
        % make 0s NaNs 
        minCOVdists{mouse}(minCOVdists{mouse} == 0) = NaN;
        % resort size and distance data for gscatter 
        if size(minCOVdists{mouse},2) < size(clustSize,2)
            minCOVdists{mouse}(:,size(minCOVdists{mouse},2)+1:size(clustSize,2)) = NaN;
        end 
        % make the distance array the right size so time can be properly
        % assigned 
        if size(minCOVdists{mouse},2) < size(clustSize{mouse},2)
            minCOVdists{mouse}(:,size(minCOVdists{mouse},2):size(clustSize{mouse},2)) = NaN;
        end 
        % resort data 
        for ccell = 1:length(terminals{mouse})
            if ccell == 1 
                COVdists{mouse} = minCOVdists{mouse}(ccell,:);
            elseif ccell > 1 
                len1 = length(COVdists{mouse});
                len2 = size(minCOVdists{mouse}(ccell,:),2);
                COVdists{mouse}(len1+1:len1+len2) = minCOVdists{mouse}(ccell,:);
            end 
        end  
        % determine the number of frames per video for each mouse 
        frameLen(mouse) = floor(windSize*FPS{mouse});
        resampleQ = 1;% UPSAMPLING WORKS BEST input('Input 0 to downsample data. Input 1 to upsample data. ');
        if resampleQ == 0 
            minFrameLen = min(frameLen);
        elseif resampleQ == 1
            minFrameLen = max(frameLen);
        end 
        % fps = minFrameLen/windSize;
        if min(min(allAvClocFrameBoxPlot2)) < 0 
            timeCOVdistArray{mouse}(:,1) = allAvClocFrameBoxPlot2(:,mouse);
        elseif min(min(allAvClocFrameBoxPlot2)) > 0 
            timeCOVdistArray{mouse}(:,1) = (allAvClocFrameBoxPlot2(:,mouse)/FPS{mouse})-((minFrameLen/FPS{mouse})/2); 
        end 
        % timeCOVdistArray{mouse}(:,3) = timeDistArray{mouse}(:,3);
        timeCOVdistArray{mouse}(:,2) = NaN;
        timeCOVdistArray{mouse}(1:length(COVdists{mouse}),2) = COVdists{mouse};
        % sort data for scatter plot 
        if mouse == 1
            allTimeCOVdistArray(:,1) = timeCOVdistArray{mouse}(~isnan(timeCOVdistArray{mouse}(:,1)),1);
            if ETAorSTAq == 0 % STA data 
                allTimeCOVdistArray(:,2) = timeCOVdistArray{mouse}(~isnan(timeCOVdistArray{mouse}(:,1)),2);
            elseif ETAorSTAq == 1 % ETA data
                if ETAtype == 0 % opto data
                    divFactor = ((sum(YpixDist)/length(YpixDist)) + (sum(XpixDist)/length(XpixDist)))/2;
                    allTimeCOVdistArray(:,2) = (timeCOVdistArray{mouse}(~isnan(timeCOVdistArray{mouse}(:,1)),2))/divFactor;
                elseif ETAtype == 1 % behavior data 
                    allTimeCOVdistArray(:,2) = timeCOVdistArray{mouse}(~isnan(timeCOVdistArray{mouse}(:,1)),2);
                end 
            end         
            allTimeCOVdistArray(:,3) = mouse;
        elseif mouse > 1 
            len1 = size(allTimeCOVdistArray,1);
            len2 = sum(~isnan(timeCOVdistArray{mouse}(:,1)));
            allTimeCOVdistArray(len1+1:len1+len2,1) = timeCOVdistArray{mouse}(~isnan(timeCOVdistArray{mouse}(:,1)),1);
            if ETAorSTAq == 0 % STA data 
                allTimeCOVdistArray(len1+1:len1+len2,2) = timeCOVdistArray{mouse}(~isnan(timeCOVdistArray{mouse}(:,1)),2);
            elseif ETAorSTAq == 1 % ETA data
                if ETAtype == 0 % opto data
                    allTimeCOVdistArray(len1+1:len1+len2,2) = (timeCOVdistArray{mouse}(~isnan(timeCOVdistArray{mouse}(:,1)),2))/divFactor;
                elseif ETAtype == 1 % behavior data 
                    allTimeCOVdistArray(len1+1:len1+len2,2) = timeCOVdistArray{mouse}(~isnan(timeCOVdistArray{mouse}(:,1)),2);
                end 
            end     
            allTimeCOVdistArray(len1+1:len1+len2,3) = mouse;        
        end 
    end 
end 

% plot the distribution of cluster orign distances from vessel
figure;
ax=gca;
histogram(allTimeCOVdistArray(:,2),30) % usually bins = 61
set(gca,'XTick',0:10:ceil(max(allTimeCOVdistArray(:,2))*10),'XTickLabelRotation',45)
avCOVdists = nanmean(allTimeCOVdistArray(:,2)); 
medCOVdists = nanmedian(allTimeCOVdistArray(:,2)); %#ok<*NANMEDIAN>
avCOVdistsLabel = sprintf('Average BBB plume origin distance from vessel: %.3f',avCOVdists);
medCOVdistsLabel = sprintf('Median BBB plume origin distance from vessel: %.3f',medCOVdists);
ax.FontSize = 15;
% ax.FontName = 'Times';
title({'Distribution of BBB Plume Origin Distance from Vessel';avCOVdistsLabel;medCOVdistsLabel});
ylabel("Number of BBB Plumes")
xlabel("Distance (microns)") 
% xlim([0 100])

% plot scatter plot of COV distances against time 
figure;
ax=gca;
f2O = cell(1,mouseNum);
for mouse = 1:mouseNum
    if isempty(timeCOVdistArray{mouse}) == 0 
        % calculate f (trend line) for each mouse 
        includeX =~ isnan(timeCOVdistArray{mouse}(:,1)); includeY =~ isnan(timeCOVdistArray{mouse}(:,2)); 
        [zeroRow, ~] = find(includeY == 0);
        includeX(zeroRow) = 0; includeXY = includeX;           
        timeCOVDistX = timeCOVdistArray{mouse}(:,1); timeCOVDistY = timeCOVdistArray{mouse}(:,2);  
        if sum(includeXY) > 1 
            f2O{mouse} = fit(timeCOVDistX(includeXY),timeCOVDistY(includeXY),'poly1');  
        end 
    end 
end  
gscatter(allTimeCOVdistArray(:,1),allTimeCOVdistArray(:,2),allTimeCOVdistArray(:,3),clr)
ax.FontSize = 15;
ax.FontName = 'Times';
legend(mouseNumLabelString)
hold all;
% plot the trend line for each mouse 
for mouse = 1:mouseNum
    fitHandle = plot(f2O{mouse});
    set(fitHandle,'Color',clr(mouse,:));
end 
% calculate fav2O (trend line) of all data 
includeX =~ isnan(allTimeCOVdistArray(:,1)); includeY =~ isnan(allTimeCOVdistArray(:,2));
[zeroRow, ~] = find(includeY == 0);
includeX(zeroRow) = 0; includeXY = includeX;                
timeODistX = allTimeCOVdistArray(:,1); timeODistY = allTimeCOVdistArray(:,2);   
if length(find(includeXY)) > 1
    fav2O = fitlm(timeODistX(includeXY),timeODistY(includeXY),'poly1');
end 
% plot trend line for all data 
if length(find(includeXY)) > 1
    fitHandle = plot(fav2O);
    leg = legend('show');
    set(fitHandle,'Color',[0 0 0],'LineWidth',3);
    leg.String(end) = [];
    rSquared = string(round(fav2O.Rsquared.Ordinary,2));
    text(-2,1,rSquared,'FontSize',20)
end     
ylabel("BBB Plume Distance From Vessel (microns)")
if clustSpikeQ3 == 0 
    xlabel("Average BBB Plume Timing (sec)") 
elseif clustSpikeQ3 == 1
    xlabel("BBB Plume Start Time (sec)") 
end 
title('BBB Plume Origin Distance From Vessel Compared to Timing'); 

% plot BBB plume origins on vessel width outline 
for mouse = 1: mouseNum 
    if ETAorSTAq == 0 % STA data 
        clr = hsv(length(terminals{mouse}));
    end 
    figure;
    % plot vessel outline 
    scatter3(indsV{mouse}(:,1),indsV{mouse}(:,2),indsV{mouse}(:,3),30,'k','filled'); % plot vessel outline 
    % plot the cluster origins 
    hold on; 
    for ccell = 1:length(plumeOriginLocs{mouse})
        for clust = 1:length(plumeOriginLocs{mouse}{ccell})
            if ETAorSTAq == 0 % STA data 
                scatter3(plumeOriginLocs{mouse}{ccell}{clust}(:,1)*XpixDist(mouse),plumeOriginLocs{mouse}{ccell}{clust}(:,2)*YpixDist(mouse),plumeOriginLocs{mouse}{ccell}{clust}(:,3),30,'MarkerFaceColor',clr(ccell,:),'MarkerEdgeColor',clr(ccell,:)); % plot clusters 
            elseif ETAorSTAq == 1 % ETA data
                clr = hsv(length(plumeOriginLocs{mouse}{ccell}));
                if ETAtype == 0 % opto data 
                    scatter3(plumeOriginLocs{mouse}{ccell}{clust}(:,1),plumeOriginLocs{mouse}{ccell}{clust}(:,2),plumeOriginLocs{mouse}{ccell}{clust}(:,3),30,'MarkerFaceColor',clr(clust,:),'MarkerEdgeColor',clr(clust,:)); % plot clusters 
                elseif ETAtype == 1 % behavior data 
                    scatter3(plumeOriginLocs{mouse}{ccell}{clust}(:,1),plumeOriginLocs{mouse}{ccell}{clust}(:,2),plumeOriginLocs{mouse}{ccell}{clust}(:,3),30,'MarkerFaceColor',clr(clust,:),'MarkerEdgeColor',clr(clust,:)); % plot clusters 
                end 
            end                     
        end 
    end 
end 

%% plot distribution of cluster sizes and pixel amplitudes
figure;
ax=gca;
avClustSize = nanmean(allSizeDistArray(:,2)); 
medClustSize = nanmedian(allSizeDistArray(:,2)); %#ok<*NANMEDIAN> 
avClustSizeLabel = sprintf('Average cluster size: %.0f',avClustSize);
medClustSizeLabel = sprintf('Median cluster size: %.0f',medClustSize);
histogram(allSizeDistArray(:,2),10)
ax.FontSize = 15;
% ax.FontName = 'Times';
if clustSpikeQ == 0 
    title({'Distribution of BBB Plume Sizes';'All Clusters';avClustSizeLabel;medClustSizeLabel});
elseif clustSpikeQ == 1 
    if clustSpikeQ2 == 0 
        title({'Distribution of BBB Plume Sizes';'Pre-Spike Clusters';avClustSizeLabel;medClustSizeLabel});
    elseif clustSpikeQ2 == 1
        title({'Distribution of BBB Plume Sizes';'Post-Spike Clusters';avClustSizeLabel;medClustSizeLabel});
    end 
end 
ylabel("Number of BBB Plumes")
xlabel("Size of BBB Plume (microns squared)") 

figure;
ax=gca;
histogram(allAmpDistArray(:,2),100)
avClustAmp = nanmean(allAmpDistArray(:,2)); 
medClustAmp = nanmedian(allAmpDistArray(:,2)); %#ok<*NANMEDIAN> 
avClustAmpLabel = sprintf('Average cluster pixel amplitude: %.3f',avClustAmp);
medClustAmpLabel = sprintf('Median cluster pixel amplitude: %.3f',medClustAmp);
ax.FontSize = 15;
% ax.FontName = 'Times';
if clustSpikeQ == 0 
    title({'Distribution of BBB Plume Pixel Amplitudes';'All Clusters';avClustAmpLabel;medClustAmpLabel});
elseif clustSpikeQ == 1 
    if clustSpikeQ2 == 0 
        title({'Distribution of BBB Plume Pixel Amplitudes';'Pre-Spike Clusters';avClustAmpLabel;medClustAmpLabel});
    elseif clustSpikeQ2 == 1
        title({'Distribution of BBB Plume Pixel Amplitudes';'Post-Spike Clusters';avClustAmpLabel;medClustAmpLabel});
    end 
end 
ylabel("Number of BBB Plumes")
xlabel("BBB Plume Pixel Amplitudes") 
%% plot distribution of cluster times
% resort avClocFrame and convert to seconds centered around 0 
if exist('allAvClocFrame','var') == 0
    for mouse = 1:mouseNum
        if mouse == 1 
            allAvClocFrame = (reshape(avClocFrame{mouse},1,size(avClocFrame{mouse},1)*size(avClocFrame{mouse},2))/FPS{mouse})-windSize/2; % converts frame to time in sec for comparison across mice ;
        elseif mouse > 1
            len = length(allAvClocFrame);
            allAvClocFrame(:,len+1:size(avClocFrame{mouse},1)*size(avClocFrame{mouse},2)+len) = (reshape(avClocFrame{mouse},1,size(avClocFrame{mouse},1)*size(avClocFrame{mouse},2))/FPS{mouse})-windSize/2; % converts frame to time in sec for comparison across mice ;
        end 
    end 
end 
figure;
ax=gca;
histogram(allAvClocFrame,20)
ax.FontSize = 15;
%     ax.FontName = 'Times';
if clustSpikeQ3 == 0 
    title({'Distribution of BBB Plume Timing';'Average Time'});
elseif clustSpikeQ3 == 1
    title({'Distribution of BBB Plume Timing';'Start Time'});
end 
ylabel("Number of BBB Plumes")
xlabel("Time (s)") 
% plot pie chart of before vs after spike cluster start times
numPreSpikeStarts = nansum(nansum(allAvClocFrame < 0)); %#ok<*NANSUM>
numPostSpikeStarts = nansum(nansum(allAvClocFrame >= 0));
preVsPostSpikeStarts = [numPreSpikeStarts,numPostSpikeStarts];
xlim([-2.5 2.5])

figure; 
p = pie(preVsPostSpikeStarts);
pieClr = hsv(2);
colormap(pieClr)
if ETAorSTAq == 0 % STA data
    legend('Pre-spike BBB plumes','Post-spike BBB plumes')
elseif ETAorSTAq == 1 % ETA data
    if ETAtype == 0 % opto data 
        legend('Pre-opto BBB plumes','Post-opto BBB plumes')
    elseif ETAtype == 1 % behavior data 
        if ETAtype2 == 0 % stim aligned 
            legend('Pre-stim BBB plumes','Post-stim BBB plumes')
        elseif ETAtype2 == 1 % reward aligned 
            legend('Pre-reward BBB plumes','Post-reward BBB plumes')
        end 
    end 
end 
ax=gca; ax.FontSize = 15;
t1 = p(4); t2 = p(2);
t1.FontSize = 15; t2.FontSize = 15;

%% create scatter over box plot of cluster timing per axon
figure;
ax = gca;
% plot box plot 
boxchart(allAvClocFrameBoxPlot,'MarkerStyle','none');
% create the x data needed to overlay the swarmchart on the boxchart 
x = repmat(1:size(allAvClocFrameBoxPlot,2),size(allAvClocFrameBoxPlot,1),1);
% plot swarm chart on top of box plot 
hold all;
swarmchart(x,allAvClocFrameBoxPlot,[],'red')  
yline(0)
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Timing")
xlabel("Mouse")
if clustSpikeQ3 == 0
    title({'BBB Plume Timing Per Cluster';'Average Cluster Time'});
elseif clustSpikeQ3 == 1
    title({'BBB Plume Timing Per Cluster';'Cluster Start Time'});
end     
xticklabels(mouseNumLabelString)
%% plot cluster size and pixel amp grouped by pre and post spike
if exist('allCsizeForPlot','var') == 0
    % resort clustSize
    allCsizeForPlot = nan(maxClocFrameMouseLen,mouseNum);
    for mouse = 1:mouseNum 
        allCsizeForPlot(1:avClocFrameMouseLen(mouse),mouse) = reshape(clustSize{mouse},1,avClocFrameMouseLen(mouse)); 
    end 
end  
figure;
ax=gca;
% plot box plot 
boxchart(allCsizeForPlot,'MarkerStyle','none');
% create the x data needed to overlay the swarmchart on the boxchart 
x = repmat(1:mouseNum,size(allCsizeForPlot,1),1);
% plot swarm chart on top of box plot 
hold all;
swarmchart(x,allCsizeForPlot,[],'red')  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Size (microns squared)")
xlabel("Mouse")  
title({'BBB Plume Size Per Cluster';'All Plumes'});
xticklabels(mouseNumLabelString)
set(gca, 'YScale', 'log')

if exist('allCampForPlot','var') == 0
    % resort clustSize
    allCampForPlot = nan(maxClocFrameMouseLen,mouseNum);
    for mouse = 1:mouseNum 
        allCampForPlot(1:avClocFrameMouseLen(mouse),mouse) = reshape(clustAmp{mouse},1,avClocFrameMouseLen(mouse)); 
    end 
end  
figure;
ax=gca;
% plot box plot 
boxchart(allCampForPlot,'MarkerStyle','none');
% create the x data needed to overlay the swarmchart on the boxchart 
x = repmat(1:mouseNum,size(allCampForPlot,1),1);
% plot swarm chart on top of box plot 
hold all;
swarmchart(x,allCampForPlot,[],'red')  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Pixel Amplitude")
xlabel("Mouse")  
title({'BBB Plume Pixel Amplitude Per Cluster';'All Plumes'});
xticklabels(mouseNumLabelString)

[r,c] = find(allAvClocFrameBoxPlot < 0); % find pre event clusters 
% create new variables for pre and post event clusters
PreAllCampForPlot = allCampForPlot; PostAllCampForPlot = allCampForPlot;
PreAllCsizeForPlot = allCsizeForPlot; PostAllCsizeForPlot = allCsizeForPlot;
PostAllCampForPlot(r,c) = NaN; PostAllCsizeForPlot(r,c) = NaN;
[r,c] = find(allAvClocFrameBoxPlot >= 0); % find post event clusters 
PreAllCampForPlot(r,c) = NaN; PreAllCsizeForPlot(r,c) = NaN;

figure;
ax=gca;
% plot box plot 
boxchart(PreAllCsizeForPlot,'MarkerStyle','none','BoxFaceColor','r','WhiskerLineColor','r');
% plot swarm chart on top of box plot 
hold all;
boxchart(PostAllCsizeForPlot,'MarkerStyle','none','BoxFaceColor','b','WhiskerLineColor','b');
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Size (microns squared)")
xlabel("Mouse")
if ETAorSTAq == 0 % STA data
    if clustSpikeQ3 == 0 
        title({'BBB Plume Size';'Pre And Post Spike Plumes';'Average Cluster Time'});   
    elseif clustSpikeQ3 == 1
        title({'BBB Plume Size';'Pre And Post Spike Plumes';'Cluster Start Time'});   
    end          
elseif ETAorSTAq == 1 % ETA data
    if ETAtype == 0 % opto data 
        if clustSpikeQ3 == 0 
            title({'BBB Plume Size';'Pre And Post Opto Plumes';'Average Cluster Time'});   
        elseif clustSpikeQ3 == 1
            title({'BBB Plume Size';'Pre And Post Opto Plumes';'Cluster Start Time'});   
        end  
    elseif ETAtype == 1 % behavior data 
        if ETAtype2 == 0 % stim aligned 
            if clustSpikeQ3 == 0 
                title({'BBB Plume Size';'Pre And Post Stim Plumes';'Average Cluster Time'});   
            elseif clustSpikeQ3 == 1
                title({'BBB Plume Size';'Pre And Post Stim Plumes';'Cluster Start Time'});   
            end  
        elseif ETAtype2 == 1 % reward aligned 
            if clustSpikeQ3 == 0 
                title({'BBB Plume Size';'Pre And Post Reward Plumes';'Average Cluster Time'});   
            elseif clustSpikeQ3 == 1
                title({'BBB Plume Size';'Pre And Post Reward Plumes';'Cluster Start Time'});   
            end                    
        end 
    end 
end 
if ETAorSTAq == 0 % STA data 
    legend("Pre-Spike BBB Plume","Post-Spike BBB Plume")
elseif ETAorSTAq == 1 % ETA data
    if ETAtype == 0 % opto data 
      legend("Pre-Opto BBB Plume","Post-Opto BBB Plume")
    elseif ETAtype == 1 % behavior data 
        if ETAtype2 == 0 % stim aligned 
            legend("Pre-Stim BBB Plume","Post-Stim BBB Plume")
        elseif ETAtype2 == 1 % reward aligned 
            legend("Pre-Reward BBB Plume","Post-Reward BBB Plume")
        end 
    end 
end
xticklabels(mouseNumLabelString)   
set(gca, 'YScale', 'log')

figure;
ax=gca;
% plot box plot 
boxchart(PreAllCampForPlot,'MarkerStyle','none','BoxFaceColor','r','WhiskerLineColor','r');
% plot swarm chart on top of box plot 
hold all;
boxchart(PostAllCampForPlot,'MarkerStyle','none','BoxFaceColor','b','WhiskerLineColor','b');
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Pixel Amplitude")
xlabel("Mouse")
if ETAorSTAq == 0 % STA data
    if clustSpikeQ3 == 0 
        title({'BBB Plume Pixel Amplitude';'Pre And Post Spike Plumes';'Average Cluster Time'});   
    elseif clustSpikeQ3 == 1
        title({'BBB Plume Pixel Amplitude';'Pre And Post Spike Plumes';'Cluster Start Time'});   
    end          
elseif ETAorSTAq == 1 % ETA data
    if ETAtype == 0 % opto data 
        if clustSpikeQ3 == 0 
            title({'BBB Plume Pixel Amplitude';'Pre And Post Opto Plumes';'Average Cluster Time'});   
        elseif clustSpikeQ3 == 1
            title({'BBB Plume Pixel Amplitude';'Pre And Post Opto Plumes';'Cluster Start Time'});   
        end      
    elseif ETAtype == 1 % behavior data 
        if ETAtype2 == 0 % stim aligned 
            if clustSpikeQ3 == 0 
                title({'BBB Plume Pixel Amplitude';'Pre And Post Stim Plumes';'Average Cluster Time'});   
            elseif clustSpikeQ3 == 1
                title({'BBB Plume Pixel Amplitude';'Pre And Post Stim Plumes';'Cluster Start Time'});   
            end    
        elseif ETAtype2 == 1 % reward aligned 
             if clustSpikeQ3 == 0 
                title({'BBB Plume Pixel Amplitude';'Pre And Post Reward Plumes';'Average Cluster Time'});   
            elseif clustSpikeQ3 == 1
                title({'BBB Plume Pixel Amplitude';'Pre And Post Reward Plumes';'Cluster Start Time'});   
            end                    
        end 
    end 
end 
if ETAorSTAq == 0 % STA data 
    legend("Pre-Spike BBB Plume","Post-Spike BBB Plume")
elseif ETAorSTAq == 1 % ETA data
    if ETAtype == 0 % opto data 
      legend("Pre-Opto BBB Plume","Post-Opto BBB Plume")
    elseif ETAtype == 1 % behavior data 
        if ETAtype2 == 0 % stim aligned 
            legend("Pre-Stim BBB Plume","Post-Stim BBB Plume")
        elseif ETAtype2 == 1 % reward aligned 
            legend("Pre-Reward BBB Plume","Post-Reward BBB Plume")
        end 
    end 
end
xticklabels(mouseNumLabelString) 

clearvars data 
% reshape data for plotting 
dataRsize = size(allCsizeForPlot,1); dataCsize = size(allCsizeForPlot,2);
reshapedPre = reshape(PreAllCsizeForPlot,dataRsize*dataCsize,1);
reshapedPost = reshape(PostAllCsizeForPlot,dataRsize*dataCsize,1);
data(:,1) = reshapedPre; data(:,2) = reshapedPost; 
figure;
ax=gca;
% plot box plot 
boxchart(data,'MarkerStyle','none','BoxFaceColor','k','WhiskerLineColor','k');
% plot swarm chart on top of box plot 
hold all;
x = repmat(1:size(data,2),size(data,1),1);
swarmchart(x,data,[],'red') 
% boxchart(reshapedPostPlot,'MarkerStyle','none','BoxFaceColor','b','WhiskerLineColor','b');
ax.FontSize = 15;
ax.FontName = 'Arial';
ylabel("BBB Plume Size (microns squared)") 
if ETAorSTAq == 0 % STA data
    if clustSpikeQ3 == 0 
        title({'BBB Plume Size Across Animals';'Pre And Post Spike Plumes';'Average Cluster Time'});  
    elseif clustSpikeQ3 == 1
        title({'BBB Plume Size Across Animals';'Pre And Post Spike Plumes';'Cluster Start Time'});  
    end     
elseif ETAorSTAq == 1 % ETA data
    if ETAtype == 0 % opto data 
        if clustSpikeQ3 == 0 
            title({'BBB Plume Size Across Animals';'Pre And Post Opto Plumes';'Average Cluster Time'});  
        elseif clustSpikeQ3 == 1
            title({'BBB Plume Size Across Animals';'Pre And Post Opto Plumes';'Cluster Start Time'});  
        end    
    elseif ETAtype == 1 % behavior data 
        if ETAtype2 == 0 % stim aligned 
            if clustSpikeQ3 == 0 
                title({'BBB Plume Size Across Animals';'Pre And Post Stim Plumes';'Average Cluster Time'});  
            elseif clustSpikeQ3 == 1
                title({'BBB Plume Size Across Animals';'Pre And Post Stim Plumes';'Cluster Start Time'});  
            end  
        elseif ETAtype2 == 1 % reward aligned 
             if clustSpikeQ3 == 0 
                title({'BBB Plume Size Across Animals';'Pre And Post Reward Plumes';'Average Cluster Time'});  
            elseif clustSpikeQ3 == 1
                title({'BBB Plume Size Across Animals';'Pre And Post Reward Plumes';'Cluster Start Time'});  
            end                     
        end 
    end          
end 
if ETAorSTAq == 0 % STA data 
    avLabels = ["Pre-Spike","Post-Spike"];
elseif ETAorSTAq == 1 % ETA data
      if ETAtype == 0 % opto data 
          avLabels = ["Pre-Opto","Post-Opto"];
      elseif ETAtype == 1 % behavior data 
            if ETAtype2 == 0 % stim aligned 
                avLabels = ["Pre-Stim","Post-Stim"];
            elseif ETAtype2 == 1 % reward aligned 
                avLabels = ["Pre-Reward","Post-Reward"];
            end 
      end 
end 
xticklabels(avLabels)
set(gca, 'YScale', 'log')

clearvars data 
% reshape data for plotting 
dataRsize = size(allCsizeForPlot,1); dataCsize = size(allCsizeForPlot,2);
reshapedPre = reshape(PreAllCampForPlot,dataRsize*dataCsize,1);
reshapedPost = reshape(PostAllCampForPlot,dataRsize*dataCsize,1);
data(:,1) = reshapedPre; data(:,2) = reshapedPost; 
figure;
ax=gca;
% plot box plot 
boxchart(data,'MarkerStyle','none','BoxFaceColor','k','WhiskerLineColor','k');
% plot swarm chart on top of box plot 
hold all;
x = repmat(1:size(data,2),size(data,1),1);
swarmchart(x,data,[],'red') 
% boxchart(reshapedPostPlot,'MarkerStyle','none','BoxFaceColor','b','WhiskerLineColor','b');
ax.FontSize = 15;
ax.FontName = 'Arial';
ylabel("BBB Plume Pixel Amplitude") 
if ETAorSTAq == 0 % STA data
    if clustSpikeQ3 == 0 
        title({'BBB Plume Pixel Amplitude Across Animals';'Pre And Post Spike Plumes';'Average Cluster Time'});  
    elseif clustSpikeQ3 == 1
        title({'BBB Plume Pixel Amplitude Across Animals';'Pre And Post Spike Plumes';'Cluster Start Time'});  
    end     
elseif ETAorSTAq == 1 % ETA data
    if ETAtype == 0 % opto data 
        if clustSpikeQ3 == 0 
            title({'BBB Plume Pixel Amplitude Across Animals';'Pre And Post Opto Plumes';'Average Cluster Time'});  
        elseif clustSpikeQ3 == 1
            title({'BBB Plume Pixel Amplitude Across Animals';'Pre And Post Opto Plumes';'Cluster Start Time'});  
        end    
    elseif ETAtype == 1 % behavior data 
        if ETAtype2 == 0 % stim aligned 
            if clustSpikeQ3 == 0 
                title({'BBB Plume Pixel Amplitude Across Animals';'Pre And Post Stim Plumes';'Average Cluster Time'});  
            elseif clustSpikeQ3 == 1
                title({'BBB Plume Pixel Amplitude Across Animals';'Pre And Post Stim Plumes';'Cluster Start Time'});  
            end  
        elseif ETAtype2 == 1 % reward aligned 
             if clustSpikeQ3 == 0 
                title({'BBB Plume Pixel Amplitude Across Animals';'Pre And Post Reward Plumes';'Average Cluster Time'});  
            elseif clustSpikeQ3 == 1
                title({'BBB Plume Pixel Amplitude Across Animals';'Pre And Post Reward Plumes';'Cluster Start Time'});  
            end                     
        end 
    end          
end 
if ETAorSTAq == 0 % STA data 
    avLabels = ["Pre-Spike","Post-Spike"];
elseif ETAorSTAq == 1 % ETA data
      if ETAtype == 0 % opto data 
          avLabels = ["Pre-Opto","Post-Opto"];
      elseif ETAtype == 1 % behavior data 
            if ETAtype2 == 0 % stim aligned 
                avLabels = ["Pre-Stim","Post-Stim"];
            elseif ETAtype2 == 1 % reward aligned 
                avLabels = ["Pre-Reward","Post-Reward"];
            end 
      end 
end 
xticklabels(avLabels)
%% plot change in cluster size and pixel amplitude over time
% plot change in cluster size over time for all clusters, color coded by
% mouse 
allAxonsClustSizeTS = cell(1,mouseNum);
allAxonsClustAmpTS = cell(1,mouseNum);
frameLen = nan(1,mouseNum);
for mouse = 1:mouseNum
    % resort data 
    for ccell = 1:length(terminals{mouse})
        if isempty(clustSizeTS{mouse}{terminals{mouse}(ccell)}) == 0
            if ccell == 1 
                allAxonsClustSizeTS{mouse} = clustSizeTS{mouse}{terminals{mouse}(ccell)}; 
                allAxonsClustAmpTS{mouse} = clustPixAmpTS{mouse}{terminals{mouse}(ccell)}; 
            elseif ccell > 1
                len = size(allAxonsClustSizeTS{mouse},1);
                allAxonsClustSizeTS{mouse}(len+1:size(clustSizeTS{mouse}{terminals{mouse}(ccell)},1)+len,:) = clustSizeTS{mouse}{terminals{mouse}(ccell)}; 
                allAxonsClustAmpTS{mouse}(len+1:size(clustPixAmpTS{mouse}{terminals{mouse}(ccell)},1)+len,:) = clustPixAmpTS{mouse}{terminals{mouse}(ccell)}; 
            end 
        end 
    end 
    % determine the number of frames per video for each mouse 
    frameLen(mouse) = size(allAxonsClustSizeTS{mouse},2);
    % replace nans with 0s for down sampling 
    allAxonsClustSizeTS{mouse}(isnan(allAxonsClustSizeTS{mouse}))=0;
    allAxonsClustAmpTS{mouse}(isnan(allAxonsClustAmpTS{mouse}))=0;
end 
resampleQ = 1;% UPSAMPLING WORKS BEST input('Input 0 to downsample data. Input 1 to upsample data. ');
if resampleQ == 0 
    minFrameLen = min(frameLen);
elseif resampleQ == 1
    minFrameLen = max(frameLen);
end 
downAllAxonsClustSizeTS = cell(1,mouseNum);
downAllAxonsClustAmpTS = cell(1,mouseNum);
for mouse = 1:mouseNum
    if isempty(allAxonsClustSizeTS{mouse}) == 0 
        % up sample data 
        downAllAxonsClustSizeTS{mouse} = resample(allAxonsClustSizeTS{mouse},minFrameLen,frameLen(mouse),'Dimension',2);
        downAllAxonsClustAmpTS{mouse} = resample(allAxonsClustAmpTS{mouse},minFrameLen,frameLen(mouse),'Dimension',2);
        % replace 0s and negative going values with nans 
        downAllAxonsClustSizeTS{mouse}(downAllAxonsClustSizeTS{mouse} <= 0) = NaN;
        downAllAxonsClustAmpTS{mouse}(downAllAxonsClustAmpTS{mouse} <= 0) = NaN;
    end 
end 

% go through each row of the up sampled data and remove artifacts 
sizeData = downAllAxonsClustSizeTS;
ampData = downAllAxonsClustAmpTS;
clearvars downAllAxonsClustSizeTS downAllAxonsClustAmpTS
for mouse = 1:mouseNum
    % find the indices that are the same 
    sData = ~isnan(sizeData{mouse});
    for r = 1:size(sData,1)
        for c = 1:size(sData,2)
            val = sData(r,c);
            if c == 1
                if val == 1
                    if sData(r,c+1) == 0 % if the cluster is only 1 frame wide 
                        sizeData{mouse}(r,c) = NaN;
                    end 
                    if sData(r,c+1) == 1 && sData(r,c+2) == 0 % if the cluster is 2 frames wide 
                        sizeData{mouse}(r,c) = NaN;
                        sizeData{mouse}(r,c+1) = NaN;
                    end 
                    if sData(r,c+1) == 1 && sData(r,c+2) == 1 && sData(r,c+3) == 0 % if the cluster is 3 frames wide 
                        sizeData{mouse}(r,c) = NaN;
                        sizeData{mouse}(r,c+1) = NaN;
                        sizeData{mouse}(r,c+2) = NaN;
                    end 
                end 
            elseif c == size(sData,2)
                if val == 1
                    if sData(r,c-1) == 0 % if the cluster is only 1 frame wide 
                        sizeData{mouse}(r,c) = NaN;
                    end 
                    if sData(r,c-1) == 1 && sData(r,c-2) == 0 % if the cluster is 2 frames wide 
                        sizeData{mouse}(r,c) = NaN;
                        sizeData{mouse}(r,c-1) = NaN;
                    end 

                    if sData(r,c-1) == 1 && sData(r,c-2) == 1 && sData(r,c-3) == 0% if the cluster is 3 frames wide 
                        sizeData{mouse}(r,c) = NaN;
                        sizeData{mouse}(r,c-1) = NaN;
                        sizeData{mouse}(r,c-2) = NaN;
                    end 
                end 
            elseif c ~= 1 && c~= size(sData,2)
                if val == 1
                    if sData(r,c-1) == 0 && sData(r,c+1) == 0 % if the cluster is only 1 frame wide 
                        sizeData{mouse}(r,c) = NaN;
                    end 
                    if c ~= size(sData,2)-1
                        if sData(r,c-1) == 0 && sData(r,c+1) == 1 && sData(r,c+2) == 0 % if the cluster is 2 frames wide 
                            sizeData{mouse}(r,c) = NaN;
                            sizeData{mouse}(r,c+1) = NaN;
                        end 
                    end
                    if c ~= size(sData,2)-1 && c ~= size(sData,2)-2
                        if sData(r,c-1) == 0 && sData(r,c+1) == 1 && sData(r,c+2) == 1 && sData(r,c+3) == 0 % if the cluster is 3 frames wide 
                            sizeData{mouse}(r,c) = NaN;
                            sizeData{mouse}(r,c+1) = NaN;
                            sizeData{mouse}(r,c+2) = NaN;
                        end 
                    end 
                     
                end 
            end 
        end 
    end 
    % find the indices that are the same 
    aData = ~isnan(ampData{mouse});
    for r = 1:size(aData,1)
        for c = 1:size(aData,2)
            val = aData(r,c);
            if c == 1
                if val == 1
                    if aData(r,c+1) == 0 % if the cluster is only 1 frame wide 
                        ampData{mouse}(r,c) = NaN;
                    end 
                    if aData(r,c+1) == 1 && aData(r,c+2) == 0 % if the cluster is 2 frames wide 
                        ampData{mouse}(r,c) = NaN;
                        ampData{mouse}(r,c+1) = NaN;
                    end 
                    if aData(r,c+1) == 1 && aData(r,c+2) == 1 && aData(r,c+3) == 0 % if the cluster is 3 frames wide 
                        ampData{mouse}(r,c) = NaN;
                        ampData{mouse}(r,c+1) = NaN;
                        ampData{mouse}(r,c+2) = NaN;
                    end 
                end 
            elseif c == size(aData,2)
                if val == 1
                    if aData(r,c-1) == 0 % if the cluster is only 1 frame wide 
                        ampData{mouse}(r,c) = NaN;
                    end 
                    if aData(r,c-1) == 1 && aData(r,c-2) == 0 % if the cluster is 2 frames wide 
                        ampData{mouse}(r,c) = NaN;
                        ampData{mouse}(r,c-1) = NaN;
                    end 

                    if aData(r,c-1) == 1 && aData(r,c-2) == 1 && aData(r,c-3) == 0% if the cluster is 3 frames wide 
                        ampData{mouse}(r,c) = NaN;
                        ampData{mouse}(r,c-1) = NaN;
                        ampData{mouse}(r,c-2) = NaN;
                    end 
                end 
            elseif c ~= 1 && c~= size(aData,2)
                if val == 1
                    if aData(r,c-1) == 0 && aData(r,c+1) == 0 % if the cluster is only 1 frame wide 
                        ampData{mouse}(r,c) = NaN;
                    end 
                    if c ~= size(sData,2)-1
                        if aData(r,c-1) == 0 && aData(r,c+1) == 1 && aData(r,c+2) == 0 % if the cluster is 2 frames wide 
                            ampData{mouse}(r,c) = NaN;
                            ampData{mouse}(r,c+1) = NaN;
                        end 
                    end 
                    if c ~= size(sData,2)-1 && c ~= size(sData,2)-2
                        if aData(r,c-1) == 0 && aData(r,c+1) == 1 && aData(r,c+2) == 1 && aData(r,c+3) == 0 % if the cluster is 3 frames wide 
                            ampData{mouse}(r,c) = NaN;
                            ampData{mouse}(r,c+1) = NaN;
                            ampData{mouse}(r,c+2) = NaN;
                        end 
                    end 
                end 
            end 
        end 
    end 
end 
downAllAxonsClustSizeTS = sizeData;
downAllAxonsClustAmpTS = ampData;
clearvars sizeData sData ampData aData

clr = hsv(mouseNum);
x = 1:minFrameLen;
figure;
hold all;
ax=gca;
count2 = 1;
mouseTSlabel = string(1);
for mouse = 1:mouseNum
    if isempty(downAllAxonsClustSizeTS{mouse}) == 0 
        for clust = 1:size(downAllAxonsClustSizeTS{mouse},1)
            if clust == 1
                mouseTSlabel(count2) = mouseNumLabelString(mouse);
                count2 = count2 + 1;
            elseif clust > 1                      
                count2 = count2 + 1;
                mouseTSlabel(count2) = '';                                       
            end 
        end 
        h = plot(x,downAllAxonsClustSizeTS{mouse},'Color',clr(mouse,:),'LineWidth',2);   
    end 
end     
legend(mouseTSlabel)
Frames_pre_stim_start = -((minFrameLen-1)/2); 
Frames_post_stim_start = (minFrameLen-1)/2; 
fps = minFrameLen/windSize;
sec_TimeVals = floor(((Frames_pre_stim_start:fps:Frames_post_stim_start)/fps))+1;
threshFrame = floor((minFrameLen-1)/2);
FrameVals(3) = threshFrame;
FrameVals(2) = threshFrame - (minFrameLen/5);
FrameVals(1) = FrameVals(2) - (minFrameLen/5);
FrameVals(4) = threshFrame + (minFrameLen/5);
FrameVals(5) = FrameVals(4) + (minFrameLen/5);
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Size (microns squared)") 
xlabel("Time (s)")
title('Change in BBB Plume Size')
xlim([1 minFrameLen])
% set(gca, 'YScale', 'log')
ylim([0 8000])

% plot change in cluster size over time for all clusters, color coded by
% mouse 
figure;
hold all;
ax=gca;
for mouse = 1:mouseNum
    if isempty(downAllAxonsClustAmpTS{mouse}) == 0 
        h = plot(x,downAllAxonsClustAmpTS{mouse},'Color',clr(mouse,:),'LineWidth',2);   
    end 
end     
legend(mouseTSlabel)
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Pixel Amplitude") 
xlabel("Time (s)")
title('Change in BBB Plume Pixel Amplitude')
xlim([1 minFrameLen])

% plot change in average cluster size per mouse
figure;
hold all;
ax=gca;
avAxonClustSizeTS = nan(mouseNum,minFrameLen);
mouseLabelAvPlot = string(1);
for mouse = 1:mouseNum
    if isempty(downAllAxonsClustSizeTS{mouse}) == 0 
        clearvars v f
        avAxonClustSizeTS(mouse,:) = nanmean(downAllAxonsClustSizeTS{mouse},1);  %#ok<*NANMEAN> 
        plot(x,avAxonClustSizeTS(mouse,:),'Color',clr(mouse,:),'LineWidth',2);  
        % determine 95% CI 
        SEM = (nanstd(downAllAxonsClustSizeTS{mouse}))/(sqrt(size(downAllAxonsClustSizeTS{mouse},1))); %#ok<*NANSTD> % Standard Error            
        ts_Low = tinv(0.025,size(downAllAxonsClustSizeTS{mouse},1)-1);% T-Score for 95% CI
        ts_High = tinv(0.975,size(downAllAxonsClustSizeTS{mouse},1)-1);% T-Score for 95% CI
        CI_Low = (nanmean(downAllAxonsClustSizeTS{mouse},1)) + (ts_Low*SEM);  % Confidence Intervals
        CI_High = (nanmean(downAllAxonsClustSizeTS{mouse},1)) + (ts_High*SEM);  % Confidence Intervals
        % plot the 95% CI 
        v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
        v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
        % remove NaNs so face can be made and colored 
        nanRows = isnan(v(:,2));
        v(nanRows,:) = []; f = 1:size(v,1); %#ok<SAGROW>
        patch('Faces',f,'Vertices',v,'FaceColor',clr(mouse,:),'EdgeColor','none');
        alpha(0.2)
        if mouse == 1 
            mouseLabelAvPlot(mouse) = mouseNumLabelString(mouse);
            count = 3;
            allAnmlsDownClustSizeTS = downAllAxonsClustSizeTS{mouse};
            allAnmlsDownClustAmpTS = downAllAxonsClustAmpTS{mouse};
        elseif mouse > 1 
            mouseLabelAvPlot(count) = mouseNumLabelString(mouse);
            count = count + 2;
            len = size(allAnmlsDownClustSizeTS,1);
            allAnmlsDownClustSizeTS(len+1:len+size(downAllAxonsClustSizeTS{mouse},1),:) = downAllAxonsClustSizeTS{mouse};
            allAnmlsDownClustAmpTS(len+1:len+size(downAllAxonsClustAmpTS{mouse},1),:) = downAllAxonsClustAmpTS{mouse};
        end 
    end
end 
legend(mouseLabelAvPlot)
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Size (microns squared)") 
xlabel("Time (s)")
title('Average Change in BBB Plume Size')
xlim([1 minFrameLen])
% set(gca, 'YScale', 'log')

% plot change in average pixel amplitude per mouse
figure;
hold all;
ax=gca;
avAxonClustAmpTS = nan(mouseNum,minFrameLen);
for mouse = 1:mouseNum
    if isempty(downAllAxonsClustAmpTS{mouse}) == 0 
        avAxonClustAmpTS(mouse,:) = nanmean(downAllAxonsClustAmpTS{mouse},1);  %#ok<*NANMEAN> 
        plot(x,avAxonClustAmpTS(mouse,:),'Color',clr(mouse,:),'LineWidth',2);    
        % determine 95% CI 
        SEM = (nanstd(downAllAxonsClustAmpTS{mouse}))/(sqrt(size(downAllAxonsClustAmpTS{mouse},1))); %#ok<*NANSTD> % Standard Error            
        ts_Low = tinv(0.025,size(downAllAxonsClustAmpTS{mouse},1)-1);% T-Score for 95% CI
        ts_High = tinv(0.975,size(downAllAxonsClustAmpTS{mouse},1)-1);% T-Score for 95% CI
        CI_Low = (nanmean(downAllAxonsClustAmpTS{mouse},1)) + (ts_Low*SEM);  % Confidence Intervals
        CI_High = (nanmean(downAllAxonsClustAmpTS{mouse},1)) + (ts_High*SEM);  % Confidence Intervals
        % plot the 95% CI 
        clear v f 
        v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
        v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
        % remove NaNs so face can be made and colored 
        nanRows = isnan(v(:,2));
        v(nanRows,:) = []; f = 1:size(v,1);
        patch('Faces',f,'Vertices',v,'FaceColor',clr(mouse,:),'EdgeColor','none');
        alpha(0.2)
    end 
end 
legend(mouseLabelAvPlot)
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Pixel Amplitude") 
xlabel("Time (s)")
title('Average Change in BBB Plume Pixel Amplitude')
xlim([1 minFrameLen])

% plot average change in cluster size of all animals w/95% CI 
figure;
hold all;
ax=gca;
% determine average 
avAllClustSizeTS = nanmean(avAxonClustSizeTS);
% determine 95% CI 
SEM = (nanstd(avAxonClustSizeTS))/(sqrt(size(avAxonClustSizeTS,1))); %#ok<*NANSTD> % Standard Error            
ts_Low = tinv(0.025,size(avAxonClustSizeTS,1)-1);% T-Score for 95% CI
ts_High = tinv(0.975,size(avAxonClustSizeTS,1)-1);% T-Score for 95% CI
CI_Low = (nanmean(avAxonClustSizeTS,1)) + (ts_Low*SEM);  % Confidence Intervals
CI_High = (nanmean(avAxonClustSizeTS,1)) + (ts_High*SEM);  % Confidence Intervals
plot(x,avAllClustSizeTS,'k','LineWidth',2);   
clearvars v f 
v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
% remove NaNs so face can be made and colored 
nanRows = isnan(v(:,2));
v(nanRows,:) = []; f = 1:size(v,1);
patch('Faces',f,'Vertices',v,'FaceColor','black','EdgeColor','none');
alpha(0.3)
% FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Size (microns squared)") 
xlabel("Time (s)")
title({'Average Change in BBB Plume Size';'Across Animals'})
xlim([1 minFrameLen])

% plot average change in cluster size of all animals w/95% CI 
figure;
hold all;
ax=gca;
% determine average 
avAllClustAmpTS = nanmean(avAxonClustAmpTS);
% determine 95% CI 
SEM = (nanstd(avAxonClustAmpTS))/(sqrt(size(avAxonClustAmpTS,1))); %#ok<*NANSTD> % Standard Error            
ts_Low = tinv(0.025,size(avAxonClustAmpTS,1)-1);% T-Score for 95% CI
ts_High = tinv(0.975,size(avAxonClustAmpTS,1)-1);% T-Score for 95% CI
CI_Low = (nanmean(avAxonClustAmpTS,1)) + (ts_Low*SEM);  % Confidence Intervals
CI_High = (nanmean(avAxonClustAmpTS,1)) + (ts_High*SEM);  % Confidence Intervals
plot(x,avAllClustAmpTS,'k','LineWidth',2);   
clearvars v f 
v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
% remove NaNs so face can be made and colored 
nanRows = isnan(v(:,2));
v(nanRows,:) = []; f = 1:size(v,1);
patch('Faces',f,'Vertices',v,'FaceColor','black','EdgeColor','none');
alpha(0.3)
% FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Pixel Amplitude") 
xlabel("Time (s)")
title({'Average Change in BBB Plume Plume Pixel Amplitude';'Across Animals'})
xlim([1 minFrameLen])
%% plot average BBB plume change in size and pixel amplitude over time for however many time groups you want
% plot change in cluster size color coded by axon 

x = 1:minFrameLen;
times = unique(allAvClocFrameBoxPlot);
timesLoc = ~isnan(unique(allAvClocFrameBoxPlot));
times = times(timesLoc);
numTraces = length(times);
clustTimeNumGroups = input(sprintf('How many groups do you want to sort plumes into for averaging? There are %d total plumes. ', numTraces));
windTime = floor(minFrameLen/fps);
timeStart = -(windTime/2); timeEnd = windTime/2;
if clustTimeNumGroups == 2             
    clr = hsv(clustTimeNumGroups);
    binThreshTime = input('Input the start time threshold for separating plumes with. ');
    % determine time value per frame 
    frameTimes = linspace(timeStart,timeEnd,minFrameLen);
    [value, binFrameThresh] = min(abs(frameTimes-binThreshTime));
    binThreshs = [1,binFrameThresh,minFrameLen];
    if clustTimeNumGroups == 2 && binThreshs(2) ~= threshFrame
        binThreshs(2) = threshFrame;
    end 
    binClustTSsizeData = cell(1,clustTimeNumGroups);
    binClustTSpixAmpData = cell(1,clustTimeNumGroups);
    sizeArray = zeros(1,clustTimeNumGroups);
    pixAmpArray = zeros(1,clustTimeNumGroups);
    count = 1; 
    binLabel = string(1);
    figure;
    hold all;
    ax=gca;
    binStartAndEndFrames = zeros(clustTimeNumGroups,2);  
    for bin = 1:clustTimeNumGroups
        % create time (by frame) bins 
        if bin < clustTimeNumGroups
            binStartAndEndFrames(bin,1) = binThreshs(bin);
            binStartAndEndFrames(bin,2) = threshFrame-1;
        elseif bin == clustTimeNumGroups
            binStartAndEndFrames(bin,1) = binThreshs(bin);
            binStartAndEndFrames(bin,2) = minFrameLen;                
        end 
        clustStartFrame = cell(1,max(terminals{mouse}));
        % determine cluster start frame 
        for mouse = 1:mouseNum               
            [clustLocX, clustLocY] = find(~isnan(downAllAxonsClustSizeTS{mouse}));
            clusts = unique(clustLocX);              
            for clust = 1:length(clusts)
                clustStartFrame{mouse}(clust) = min(clustLocY(clustLocX == clusts(clust)));
            end 
        end 
        % set the current bin boundaries 
        curBinBounds = binStartAndEndFrames(bin,:);           
        for mouse = 1:length(clustStartFrame)    
            % determine what clusters go into the current bin 
            theseClusts = clustStartFrame{mouse} >= curBinBounds(1) & clustStartFrame{mouse} <= curBinBounds(2);
            binClusts = find(theseClusts);                
            % sort clusters into time bins 
            sizeArray(bin) = size(binClustTSsizeData{bin},1);
            binClustTSsizeData{bin}(sizeArray(bin)+1:sizeArray(bin)+length(binClusts),:) = downAllAxonsClustSizeTS{mouse}(binClusts,:);                
            pixAmpArray(bin) = size(binClustTSpixAmpData{bin},1);
            binClustTSpixAmpData{bin}(pixAmpArray(bin)+1:pixAmpArray(bin)+length(binClusts),:) = downAllAxonsClustAmpTS{mouse}(binClusts,:);
        end 
        % determine bin labels 
        binString = string(round((binStartAndEndFrames(bin,:)./fps)-(minFrameLen/fps/2),1));
        for clust = 1:size(binClustTSsizeData{bin},1)
            if clust == 1 
                if isempty(binClustTSsizeData{bin}) == 0                     
                    binLabel(count) = append(binString(1),' to ',binString(2));
                    count = count + 1;
                end 
            elseif clust > 1
                if isempty(binClustTSsizeData{bin}) == 0 
                    binLabel(count) = '';
                    count = count + 1;                        
                end                 
            end 
        end 
        if isempty(binClustTSsizeData{bin}) == 0 
            h = plot(x,binClustTSsizeData{bin},'Color',clr(bin,:),'LineWidth',2); 
        end    
    end
elseif clustTimeNumGroups > 2 
    if ETAtype2 == 0 % data is aligned to stimulus
        bin3sortQ = 0;
    end 
    if clustTimeNumGroups == 3 && ETAtype2 == 1 % data is aligned to reward 
        bin3sortQ = input('Input 0 to sort the three time bins evenly across time. Input 1 to sort the three time bins specifically. ');
        if bin3sortQ == 1 % below this sorts time bins specifically 
            % define the bin time windows in seconds 
            sensoryBin = [-2.25,-1.25];
            periRewardBin = [-0.75,0.25];
            postRewardBin = [0.75,2.25];
            clr = hsv(clustTimeNumGroups);
            % determine bin start and end frames
            % (binStartAndEndFrames(bin,:)
            binStartAndEndFrames(1,:) = sensoryBin*fps;
            binStartAndEndFrames(2,:) = periRewardBin*fps;
            binStartAndEndFrames(3,:) = postRewardBin*fps;
            binStartAndEndFrames = floor(binStartAndEndFrames + (minFrameLen/2));
            clustStartFrame = cell(1,mouseNum);
            % determine cluster start frame 
            for mouse = 1:mouseNum          
                [clustLocX, clustLocY] = find(~isnan(downAllAxonsClustSizeTS{mouse}));
                clusts = unique(clustLocX);              
                for clust = 1:length(clusts)
                    clustStartFrame{mouse}(clust) = min(clustLocY(clustLocX == clusts(clust)));
                end 
            end 
            binClustTSsizeData = cell(1,clustTimeNumGroups);
            binClustTSpixAmpData = cell(1,clustTimeNumGroups);
            sizeArray = zeros(1,clustTimeNumGroups);
            pixAmpArray = zeros(1,clustTimeNumGroups);
            count = 1; 
            binLabel = string(1);
            figure;
            hold all;
            ax=gca;
            for bin = 1:clustTimeNumGroups
                % set the current bin boundaries 
                curBinBounds = binStartAndEndFrames(bin,:);  
                for mouse = 1:mouseNum
                    % determine what clusters go into the current bin 
                    theseClusts = clustStartFrame{mouse} >= curBinBounds(1) & clustStartFrame{mouse} <= curBinBounds(2);
                    binClusts = find(theseClusts);                
                    % sort clusters into time bins 
                    sizeArray(bin) = size(binClustTSsizeData{bin},1);
                    binClustTSsizeData{bin}(sizeArray(bin)+1:sizeArray(bin)+length(binClusts),:) = downAllAxonsClustSizeTS{mouse}(binClusts,:);
                    pixAmpArray(bin) = size(binClustTSpixAmpData{bin},1);
                    binClustTSpixAmpData{bin}(pixAmpArray(bin)+1:pixAmpArray(bin)+length(binClusts),:) = downAllAxonsClustAmpTS{mouse}(binClusts,:);
                end 
                % determine bin labels 
                binString = string(round((binStartAndEndFrames(bin,:)./fps)-(minFrameLen/fps/2),1));
                for clust = 1:size(binClustTSsizeData{bin},1)
                    if clust == 1 
                        if isempty(binClustTSsizeData{bin}) == 0                     
                            binLabel(count) = append(binString(1),' to ',binString(2));
                            count = count + 1;
                        end 
                    elseif clust > 1
                        if isempty(binClustTSsizeData{bin}) == 0 
                            binLabel(count) = '';
                            count = count + 1;                        
                        end                 
                    end 
                end 
                if isempty(binClustTSsizeData{bin}) == 0 
                    h = plot(x,binClustTSsizeData{bin},'Color',clr(bin,:),'LineWidth',2); 
                end 
            end
        end 
    end 

    % below will evenly distribute bins across time for however many bins
    % there are 
    if clustTimeNumGroups ~= 3 || clustTimeNumGroups == 3 && bin3sortQ == 0 
        clr = hsv(clustTimeNumGroups);
        binFrameSize = floor(minFrameLen/clustTimeNumGroups);
        binThreshs = (1:binFrameSize:minFrameLen);
        binStartAndEndFrames = zeros(clustTimeNumGroups,2);   
        clustStartFrame = cell(1,mouseNum);
        % determine cluster start frame 
        for mouse = 1:mouseNum          
            [clustLocX, clustLocY] = find(~isnan(downAllAxonsClustSizeTS{mouse}));
            clusts = unique(clustLocX);              
            for clust = 1:length(clusts)
                clustStartFrame{mouse}(clust) = min(clustLocY(clustLocX == clusts(clust)));
            end 
        end 
        binClustTSsizeData = cell(1,clustTimeNumGroups);
        binClustTSpixAmpData = cell(1,clustTimeNumGroups);
        sizeArray = zeros(1,clustTimeNumGroups);
        pixAmpArray = zeros(1,clustTimeNumGroups);
        count = 1; 
        binLabel = string(1);
        figure;
        hold all;
        ax=gca;
        for bin = 1:clustTimeNumGroups
            % create time (by frame) bins 
            if bin < clustTimeNumGroups
                binStartAndEndFrames(bin,1) = binThreshs(bin);
                binStartAndEndFrames(bin,2) = binThreshs(bin)+binFrameSize-1;
            elseif bin == clustTimeNumGroups
                binStartAndEndFrames(bin,1) = binThreshs(bin);
                binStartAndEndFrames(bin,2) = minFrameLen;                
            end 
            % set the current bin boundaries 
            curBinBounds = binStartAndEndFrames(bin,:);  
            for mouse = 1:mouseNum
                % determine what clusters go into the current bin 
                theseClusts = clustStartFrame{mouse} >= curBinBounds(1) & clustStartFrame{mouse} <= curBinBounds(2);
                binClusts = find(theseClusts);                
                % sort clusters into time bins 
                sizeArray(bin) = size(binClustTSsizeData{bin},1);
                binClustTSsizeData{bin}(sizeArray(bin)+1:sizeArray(bin)+length(binClusts),:) = downAllAxonsClustSizeTS{mouse}(binClusts,:);
                pixAmpArray(bin) = size(binClustTSpixAmpData{bin},1);
                binClustTSpixAmpData{bin}(pixAmpArray(bin)+1:pixAmpArray(bin)+length(binClusts),:) = downAllAxonsClustAmpTS{mouse}(binClusts,:);
            end 
            % determine bin labels 
            binString = string(round((binStartAndEndFrames(bin,:)./fps)-(minFrameLen/fps/2),1));
            for clust = 1:size(binClustTSsizeData{bin},1)
                if clust == 1 
                    if isempty(binClustTSsizeData{bin}) == 0                     
                        binLabel(count) = append(binString(1),' to ',binString(2));
                        count = count + 1;
                    end 
                elseif clust > 1
                    if isempty(binClustTSsizeData{bin}) == 0 
                        binLabel(count) = '';
                        count = count + 1;                        
                    end                 
                end 
            end 
            if isempty(binClustTSsizeData{bin}) == 0 
                h = plot(x,binClustTSsizeData{bin},'Color',clr(bin,:),'LineWidth',2); 
            end 
        end
    end 
end 
sec_TimeVals = floor(((Frames_pre_stim_start:fps:Frames_post_stim_start)/fps))+1;
FrameVals(3) = threshFrame;
FrameVals(2) = threshFrame - (minFrameLen/5);
FrameVals(1) = FrameVals(2) - (minFrameLen/5);
FrameVals(4) = threshFrame + (minFrameLen/5);
FrameVals(5) = FrameVals(4) + (minFrameLen/5);
legend(binLabel) 
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Size (microns squared)") 
xlabel("Time (s)")
title('Change in BBB Plume Size')
xlim([1 minFrameLen])

% plot change in cluster pixel amplitude color coded by axon  
figure;
hold all;
ax=gca;
if clustTimeNumGroups == 2             
    for bin = 1:clustTimeNumGroups
        if isempty(binClustTSpixAmpData{bin}) == 0 
            h = plot(x,binClustTSpixAmpData{bin},'Color',clr(bin,:),'LineWidth',2); 
        end 
    end
elseif clustTimeNumGroups > 2 
    for bin = 1:clustTimeNumGroups
        if isempty(binClustTSpixAmpData{bin}) == 0 
            h = plot(x,binClustTSpixAmpData{bin},'Color',clr(bin,:),'LineWidth',2); 
        end 
    end
end 
legend(binLabel)
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Pixel Amplitude") 
xlabel("Time (s)")
title('Change in BBB Plume Pixel Amplitude')
xlim([1 minFrameLen])

% plot average change in cluster size 
figure;
hold all;
ax=gca;
avBinClustSizeTS = NaN(clustTimeNumGroups,minFrameLen);
count = 1;
for bin = 1:clustTimeNumGroups
    if isempty(binClustTSsizeData{bin}) == 0
        avBinClustSizeTS(count,:) = nanmean(binClustTSsizeData{bin},1);  
        plot(x,avBinClustSizeTS(count,:),'Color',clr(bin,:),'LineWidth',2);      
        % determine 95% CI 
        SEM = (nanstd(binClustTSsizeData{bin}))/(sqrt(size(binClustTSsizeData{bin},1))); %#ok<*NANSTD> % Standard Error            
        ts_Low = tinv(0.025,size(binClustTSsizeData{bin},1)-1);% T-Score for 95% CI
        ts_High = tinv(0.975,size(binClustTSsizeData{bin},1)-1);% T-Score for 95% CI
        CI_Low = (nanmean(binClustTSsizeData{bin},1)) + (ts_Low*SEM);  % Confidence Intervals
        CI_High = (nanmean(binClustTSsizeData{bin},1)) + (ts_High*SEM);  % Confidence Intervals
        % plot the 95% CI 
        clear v f 
        v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
        v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
        % remove NaNs so face can be made and colored 
        nanRows = isnan(v(:,2));
        v(nanRows,:) = []; f = 1:size(v,1);
        patch('Faces',f,'Vertices',v,'FaceColor',clr(bin,:),'EdgeColor','none');
        alpha(0.2)
        count = count + 1;
    end 
end 
% remove empty strings 
% emptyStrings = find(binLabel == '');
% binLabel(emptyStrings) = [];
count = 1;
binLabel2 = string(1);
for bin = 1:size(avBinClustSizeTS,1)
    if bin == 1 
        binLabel2(bin) = binLabel(count);
        count = count + 2;
    elseif bin > 1 
        binLabel2(count) = binLabel(bin);
        count = count + 2;
    end 
end 
legend(binLabel2)
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Size (microns squared)") 
xlabel("Time (s)")
title({'Average Change in BBB Plume Size'})
xlim([1 minFrameLen])

% plot average change in cluster size 
figure;
hold all;
ax=gca;
avBinClustPixAmpTS = NaN(clustTimeNumGroups,minFrameLen);
count = 1;
for bin = 1:clustTimeNumGroups
    if isempty(binClustTSpixAmpData{bin}) == 0
        avBinClustPixAmpTS(count,:) = nanmean(binClustTSpixAmpData{bin},1);  
        plot(x,avBinClustPixAmpTS(count,:),'Color',clr(bin,:),'LineWidth',2);      
        % determine 95% CI 
        SEM = (nanstd(binClustTSpixAmpData{bin}))/(sqrt(size(binClustTSpixAmpData{bin},1))); %#ok<*NANSTD> % Standard Error            
        ts_Low = tinv(0.025,size(binClustTSpixAmpData{bin},1)-1);% T-Score for 95% CI
        ts_High = tinv(0.975,size(binClustTSpixAmpData{bin},1)-1);% T-Score for 95% CI
        CI_Low = (nanmean(binClustTSpixAmpData{bin},1)) + (ts_Low*SEM);  % Confidence Intervals
        CI_High = (nanmean(binClustTSpixAmpData{bin},1)) + (ts_High*SEM);  % Confidence Intervals
        % plot the 95% CI 
        clear v f 
        v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
        v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
        % remove NaNs so face can be made and colored 
        nanRows = isnan(v(:,2));
        v(nanRows,:) = []; f = 1:size(v,1);
        patch('Faces',f,'Vertices',v,'FaceColor',clr(bin,:),'EdgeColor','none');
        alpha(0.2)
        count = count + 1;
    end 
end 
legend(binLabel2)
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Pixel Amplitude") 
xlabel("Time (s)")
title({'Average Change in';'BBB Plume Pixel Amplitude'})
xlim([1 minFrameLen])

% plot aligned cluster change in size per bin and total average 
% determine cluster start frame per bin  
binClustStartFrame = cell(1,clustTimeNumGroups);
alignedBinClustsSize = cell(1,clustTimeNumGroups);
avAlignedClustsSize = cell(1,clustTimeNumGroups);
figure;
hold all;
ax=gca;
for bin = 1:clustTimeNumGroups    
    % remove rows of all NaNs 
    rows = all(isnan(binClustTSsizeData{bin}),2);
    binClustTSsizeData{bin}(rows,:) = [];
    [clustLocX, clustLocY] = find(~isnan(binClustTSsizeData{bin}));
    clusts = unique(clustLocX);              
    for clust = 1:length(clusts)
        binClustStartFrame{bin}(clust) = min(clustLocY(clustLocX == clusts(clust)));
    end 
    % align clusters
    % determine longest cluster 
    [longestClustStart,longestClust] = min(binClustStartFrame{bin});
    arrayLen = minFrameLen-longestClustStart+1;
    for clust = 1:size(binClustTSsizeData{bin},1)
        % get data and buffer end as needed 
        data = binClustTSsizeData{bin}(clust,binClustStartFrame{bin}(clust):end);
        data(:,length(data)+1:arrayLen) = NaN;
        % align data 
        alignedBinClustsSize{bin}(clust,:) = data;
    end 
    x = 1:size(alignedBinClustsSize{bin},2);
    % averaged the aligned clusters 
    avAlignedClustsSize{bin} = nanmean(alignedBinClustsSize{bin},1);
    if isempty(binClustTSsizeData{bin}) == 0 
        h = plot(x,avAlignedClustsSize{bin},'Color',clr(bin,:),'LineWidth',2); 
        % determine 95% CI 
        SEM = (nanstd(alignedBinClustsSize{bin}))/(sqrt(size(alignedBinClustsSize{bin},1))); %#ok<*NANSTD> % Standard Error            
        ts_Low = tinv(0.025,size(alignedBinClustsSize{bin},1)-1);% T-Score for 95% CI
        ts_High = tinv(0.975,size(alignedBinClustsSize{bin},1)-1);% T-Score for 95% CI
        CI_Low = (nanmean(alignedBinClustsSize{bin},1)) + (ts_Low*SEM);  % Confidence Intervals
        CI_High = (nanmean(alignedBinClustsSize{bin},1)) + (ts_High*SEM);  % Confidence Intervals
        % plot the 95% CI 
        clear v f 
        v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
        v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
        % remove NaNs so face can be made and colored 
        nanRows = isnan(v(:,2));
        v(nanRows,:) = []; f = 1:size(v,1);
        patch('Faces',f,'Vertices',v,'FaceColor',clr(bin,:),'EdgeColor','none');
        alpha(0.2)
    end 
end 
legend(binLabel2)
Frames_pre_stim_start = -((minFrameLen-1)/2); 
Frames_post_stim_start = (minFrameLen-1)/2; 
sec_TimeVals = floor(((Frames_pre_stim_start:fps:Frames_post_stim_start)/fps))+0.5+timeEnd;
FrameVals = round((1:fps:minFrameLen));
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Size (microns squared)") 
xlabel("Time (s)")
title({'Change in BBB Plume Size';'Clusters Aligned and Averaged'})
xlim([1 minFrameLen])
set(gca, 'yscale','log') 

% plot aligned cluster change in pixel amplitude per bin and total average 
% determine cluster start frame per bin  
alignedBinClustsPixAmp = cell(1,clustTimeNumGroups);
avAlignedClustsPixAmp = cell(1,clustTimeNumGroups);
figure;
hold all;
ax=gca;
for bin = 1:clustTimeNumGroups    
    % remove rows of all NaNs 
    rows = all(isnan(binClustTSpixAmpData{bin}),2);
    binClustTSpixAmpData{bin}(rows,:) = [];
    % align clusters
    % determine longest cluster 
    [longestClustStart,longestClust] = min(binClustStartFrame{bin});
    arrayLen = minFrameLen-longestClustStart+1;
    for clust = 1:size(binClustTSpixAmpData{bin},1)
        if clust <= length(binClustStartFrame{bin})
            % get data and buffer end as needed 
            data = binClustTSpixAmpData{bin}(clust,binClustStartFrame{bin}(clust):end);
            data(:,length(data)+1:arrayLen) = NaN;
            % align data 
            alignedBinClustsPixAmp{bin}(clust,:) = data;
        end 
    end 
    x = 1:size(alignedBinClustsPixAmp{bin},2);
    % averaged the aligned clusters 
    avAlignedClustsPixAmp{bin} = nanmean(alignedBinClustsPixAmp{bin},1);
    if isempty(binClustTSpixAmpData{bin}) == 0 
        h = plot(x,avAlignedClustsPixAmp{bin},'Color',clr(bin,:),'LineWidth',2); 
        % determine 95% CI 
        SEM = (nanstd(alignedBinClustsPixAmp{bin}))/(sqrt(size(alignedBinClustsPixAmp{bin},1))); %#ok<*NANSTD> % Standard Error            
        ts_Low = tinv(0.025,size(alignedBinClustsPixAmp{bin},1)-1);% T-Score for 95% CI
        ts_High = tinv(0.975,size(alignedBinClustsPixAmp{bin},1)-1);% T-Score for 95% CI
        CI_Low = (nanmean(alignedBinClustsPixAmp{bin},1)) + (ts_Low*SEM);  % Confidence Intervals
        CI_High = (nanmean(alignedBinClustsPixAmp{bin},1)) + (ts_High*SEM);  % Confidence Intervals
        % plot the 95% CI 
        clear v f 
        v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
        v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
        % remove NaNs so face can be made and colored 
        nanRows = isnan(v(:,2));
        v(nanRows,:) = []; f = 1:size(v,1);
        patch('Faces',f,'Vertices',v,'FaceColor',clr(bin,:),'EdgeColor','none');
        alpha(0.2)
    end 
end 
legend(binLabel2)
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Pixel Amplitude") 
xlabel("Time (s)")
title({'Change in BBB Plume Pixel Amplitude';'Clusters Aligned and Averaged'})
xlim([1 minFrameLen])

% plot total aligned cluster size average 
[~,c] = cellfun(@size,alignedBinClustsSize);
maxLen = max(c);
if clustTimeNumGroups == 2     
    for bin = 1:clustTimeNumGroups           
        % put data together with appropriate buffering to get total average 
        data = alignedBinClustsSize{bin};
        data(:,size(data,2)+1:maxLen) = NaN;        
        if bin == 1 
            allClusts = data;
        elseif bin == 2 
            allClusts(size(allClusts,1)+1:size(allClusts,1)+size(data,1),:) = data;
        end 
    end 
    % plot average of all axons w/95% CI 
    figure;
    hold all;
    ax=gca;
    % determine average 
    avAllClustSizeTS = nanmean(allClusts);
    x = 1:length(avAllClustSizeTS);
    % determine 95% CI 
    SEM = (nanstd(allClusts))/(sqrt(size(allClusts,1))); %#ok<*NANSTD> % Standard Error            
    ts_Low = tinv(0.025,size(allClusts,1)-1);% T-Score for 95% CI
    ts_High = tinv(0.975,size(allClusts,1)-1);% T-Score for 95% CI
    CI_Low = (nanmean(allClusts,1)) + (ts_Low*SEM);  % Confidence Intervals
    CI_High = (nanmean(allClusts,1)) + (ts_High*SEM);  % Confidence Intervals
    plot(x,avAllClustSizeTS,'k','LineWidth',2);   
    clear v f 
    v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
    v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
    % remove NaNs so face can be made and colored 
    nanRows = isnan(v(:,2));
    v(nanRows,:) = []; f = 1:size(v,1);
    patch('Faces',f,'Vertices',v,'FaceColor','black','EdgeColor','none');
    alpha(0.3)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    ylabel("BBB Plume Size (microns squared)") 
    xlabel("Time (s)")
    title({'Average Aligned Change in BBB Plume Size';'Across Axons'})
    xlim([1 minFrameLen])
end 

% plot total aligned cluster pixel amplitude average 
if clustTimeNumGroups == 2     
    for bin = 1:clustTimeNumGroups           
        % put data together with appropriate buffering to get total average 
        data = alignedBinClustsPixAmp{bin};
        data(:,size(data,2)+1:maxLen) = NaN;        
        if bin == 1 
            allClusts = data;
        elseif bin == 2 
            allClusts(size(allClusts,1)+1:size(allClusts,1)+size(data,1),:) = data;
        end 
    end 
    % plot average of all axons w/95% CI 
    figure;
    hold all;
    ax=gca;
    % determine average 
    avAllClustSizeTS = nanmean(allClusts);
    x = 1:length(avAllClustSizeTS);
    % determine 95% CI 
    SEM = (nanstd(allClusts))/(sqrt(size(allClusts,1))); %#ok<*NANSTD> % Standard Error            
    ts_Low = tinv(0.025,size(allClusts,1)-1);% T-Score for 95% CI
    ts_High = tinv(0.975,size(allClusts,1)-1);% T-Score for 95% CI
    CI_Low = (nanmean(allClusts,1)) + (ts_Low*SEM);  % Confidence Intervals
    CI_High = (nanmean(allClusts,1)) + (ts_High*SEM);  % Confidence Intervals
    plot(x,avAllClustSizeTS,'k','LineWidth',2);   
    clear v f 
    v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
    v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
    % remove NaNs so face can be made and colored 
    nanRows = isnan(v(:,2));
    v(nanRows,:) = []; f = 1:size(v,1);
    patch('Faces',f,'Vertices',v,'FaceColor','black','EdgeColor','none');
    alpha(0.3)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    ylabel("BBB Plume Pixel Amplitude") 
    xlabel("Time (s)")
    title({'Average Aligned Change in'; 'BBB Plume Pixel Amplitude';'Across Axons'})
    xlim([1 minFrameLen])
    ylim([0 0.2])
end 

if ETAtype2 == 1 % data is aligned to reward 
    if clustTimeNumGroups == 3 % if we're separating data into sensory, peri-reward, and post reward. 
        sizeInt = cell(1,length(binClustTSsizeData));
        binSz = nan(1,length(binClustTSsizeData));
        % determine the size integral (size of each plume over time)
        for bin = 1:length(binClustTSsizeData)
            sizeInt{bin} = nansum(binClustTSsizeData{bin},2);
            % turn 0s into nans 
            sizeInt{bin}(sizeInt{bin} == 0) = NaN;
            binSz(bin) = length(sizeInt{bin});
        end 
        reshapedData = nan(max(binSz),length(binClustTSsizeData));
        for bin = 1:length(binClustTSsizeData)
            % reshape the data for plotting 
            reshapedData(1:length(sizeInt{bin}),bin) = sizeInt{bin};        
        end 
        figure;
        ax=gca;
        % plot box and whisker plots to compare size across the different time bins 
        boxchart(reshapedData,'MarkerStyle','none','BoxFaceColor','k','WhiskerLineColor','k');
        ax.FontSize = 15;
        ax.FontName = 'Arial';
        ylabel({"BBB Plume Size Integral"; "(microns squared)"}) 
        set(gca,'XTicklabel',{'Sensory','Peri-Reward','Post-Reward'})

        % figure out what traces came form what animal and plot the
        % sensory, peri-reward, and post-reward box plots by animal 
        sumClusts = cell(1,3);
        sizeIntByMouse = cell(3,mouseNum);
        reshapedMsizeInt = cell(1,mouseNum);
        for bin = 1:3
            for mouse = 1:mouseNum
                reshapedMsizeInt{mouse}(1:length(sizeInt{bin}),1:3) = NaN;
            end 
        end 
        for bin = 1:3
            count = 1;
            for mouse = 1:mouseNum
                if isempty(clustStartFrame{mouse}) == 0  
                    if any(clustStartFrame{mouse} >= binStartAndEndFrames(bin,1)) && any(clustStartFrame{mouse} <= binStartAndEndFrames(bin,2))
                        % figure out what plumes come from what mouse 
                        sumClusts{bin}(mouse) = length(find(clustStartFrame{mouse} >= binStartAndEndFrames(bin,1) & clustStartFrame{mouse} <= binStartAndEndFrames(bin,2)));
                        % sort sizeInt by mouse 
                        if mouse == 1 
                            sizeIntByMouse{bin,mouse} = sizeInt{bin}(count:sumClusts{bin}(mouse));
                            count = count + sumClusts{bin}(mouse);
                        elseif mouse > 1 
                            if count+sumClusts{bin}(mouse)-1 <= length(sizeInt{bin})
                                sizeIntByMouse{bin,mouse} = sizeInt{bin}(count:count+sumClusts{bin}(mouse)-1);
                            elseif count+sumClusts{bin}(mouse)-1 > length(sizeInt{bin})
                                sizeIntByMouse{bin,mouse} = sizeInt{bin}(count:length(sizeInt{bin}));
                            end 
                            count = count+sumClusts{bin}(mouse);
                        end 
                    end 
                end 
                % reshape the data for box plotting
                reshapedMsizeInt{mouse}(1:length(sizeIntByMouse{bin,mouse}),bin) = sizeIntByMouse{bin,mouse};
            end 
        end 

        % plot stacked box plots color coded by mouse 
        clr = hsv(mouseNum);

        for mouse = 1:mouseNum
            figure;
            ax=gca;
            % plot box plot 
            boxchart(reshapedMsizeInt{mouse},'MarkerStyle','none','BoxFaceColor',clr(mouse,:),'WhiskerLineColor',clr(mouse,:));
            % plot swarm chart on top of box plot 
            % hold all;
            ax.FontSize = 15;
            ax.FontName = 'Arial';
            ylabel({"BBB Plume Size Integral"; "(microns squared)"})
            set(gca,'XTicklabel',{'Sensory','Peri-Reward','Post-Reward'})
        end 
        ax.YAxis.Scale ="log";
        % set(gca, 'xscale','log') 
    end
end 

%% plot average BBB plume change in size and pixel amplitude over time for axons categorized as listeners, talkers, and both
if ETAorSTAq == 0 % STA data  
    axonTypeQ = input('Input 0 to probabilistically sort axon type. Input 1 to do strict absolute axon type sorting. ');
    clr = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.4250 0.386 0.4195];   
    binString = ["Listener","Controller","Both"];
    % identify what specific axons are listeners, controllers, or both 
    axonTypeList = cell(1,mouseNum);
    listenerAxons = cell(1,mouseNum);
    controllerAxons = cell(1,mouseNum);
    bothAxons = cell(1,mouseNum);
    for mouse = 1:mouseNum
        % identify clusters that come before the spike 
        [rPre,~] = find(((avClocFrame{mouse}/FPS{mouse})-windSize/2) < 0);
        % identify clusters that come after the spike 
        [rPost,~] = find(((avClocFrame{mouse}/FPS{mouse})-windSize/2) >= 0);
        % figure out what axon the clusters belong to 
        count1 = 1; count2 = 1; count3 = 1;
        for ccell = 1:length(terminals{mouse})
            % first column tells you what specific axon it is 
            axonTypeList{mouse}(ccell,1) = terminals{mouse}(ccell);
            % second column tells you how many pre spike clusters there are
            axonTypeList{mouse}(ccell,2) = sum(rPre == ccell);
            % third column tells you how many post spike clusters there are
            axonTypeList{mouse}(ccell,3) = sum(rPost == ccell);
            if axonTypeQ == 0 % probabilistically sort axon type. Input 1 to do strict absolute axon type sorting. ');
                % if an axon is a listener 
                if axonTypeList{mouse}(ccell,2)/(axonTypeList{mouse}(ccell,2)+axonTypeList{mouse}(ccell,3)) > 0.5
                    listenerAxons{mouse}(count1) = ccell;
                    count1 = count1 + 1;
                % if an axon is a controller 
                elseif axonTypeList{mouse}(ccell,2)/(axonTypeList{mouse}(ccell,2)+axonTypeList{mouse}(ccell,3)) < 0.5
                    controllerAxons{mouse}(count2) = ccell;
                    count2 = count2 + 1;  
                % if an axon does both
                elseif axonTypeList{mouse}(ccell,2)/(axonTypeList{mouse}(ccell,2)+axonTypeList{mouse}(ccell,3)) == 0.5
                    bothAxons{mouse}(count3) = ccell;
                    count3 = count3 + 1;                   
                end 
            elseif axonTypeQ == 1 % do strict absolute axon type sorting. ');
                % if an axon is a listener 
                if axonTypeList{mouse}(ccell,2) ~= 0 && axonTypeList{mouse}(ccell,3) == 0 
                    listenerAxons{mouse}(count1) = ccell;
                    count1 = count1 + 1;
                % if an axon is a controller 
                elseif axonTypeList{mouse}(ccell,2) == 0 && axonTypeList{mouse}(ccell,3) ~= 0 
                    controllerAxons{mouse}(count2) = ccell;
                    count2 = count2 + 1;  
                % if an axon does both
                elseif axonTypeList{mouse}(ccell,2) ~= 0 && axonTypeList{mouse}(ccell,3) ~= 0 
                    bothAxons{mouse}(count3) = ccell;
                    count3 = count3 + 1;                   
                end    
            end 
        end 
    end 
    % plot change in cluster size color coded by axon 
    x = 1:minFrameLen;
    figure;
    hold all;
    ax=gca; 
    % figure out what rows in down sampled data correspond to what axons 
    numClustsPerAxon = cell(1,mouseNum);
    axonInds = cell(1,mouseNum);
    for mouse = 1:mouseNum
        count = 1;
        for ccell = 1:length(terminals{mouse})
            numClustsPerAxon{mouse}(ccell) = size(clustSizeTS{mouse}{terminals{mouse}(ccell)},1);
            % create list of indices for axons data location with down sampled data
            for clust = 1:numClustsPerAxon{mouse}(ccell)
                axonInds{mouse}(count) = ccell;
                count = count + 1;
            end            
        end 
    end 
    % sort data 
    binClustTSsizeData = cell(1,3);
    binClustTSpixAmpData = cell(1,3);
    for bin = 1:3
        for mouse = 1:mouseNum
            if mouse == 1 
                if bin == 1 % sort listeners
                    % find the indeces for the specific axons needed by type 
                    loc = ismember(axonInds{mouse},listenerAxons{mouse});
                    % sort data 
                    binClustTSsizeData{bin} = downAllAxonsClustSizeTS{mouse}(loc,:);
                    binClustTSpixAmpData{bin} = downAllAxonsClustAmpTS{mouse}(loc,:);
                elseif bin == 2 % sort controllers 
                    % find the indeces for the specific axons needed by type 
                    loc = ismember(axonInds{mouse},controllerAxons{mouse});
                    % sort data 
                    binClustTSsizeData{bin} = downAllAxonsClustSizeTS{mouse}(loc,:);
                    binClustTSpixAmpData{bin} = downAllAxonsClustAmpTS{mouse}(loc,:);
                elseif bin == 3 % sort bothers  
                    % find the indeces for the specific axons needed by type 
                    loc = ismember(axonInds{mouse},bothAxons{mouse});
                    % sort data 
                    binClustTSsizeData{bin} = downAllAxonsClustSizeTS{mouse}(loc,:);
                    binClustTSpixAmpData{bin} = downAllAxonsClustAmpTS{mouse}(loc,:);
                end 
            elseif mouse > 1
                if bin == 1 % sort listeners
                    % find the indeces for the specific axons needed by type 
                    loc = ismember(axonInds{mouse},listenerAxons{mouse});
                    len1 = size(binClustTSsizeData{bin},1);
                    len2 = nnz(loc);
                    % sort data 
                    binClustTSsizeData{bin}(len1+1:len1+len2,:) = downAllAxonsClustSizeTS{mouse}(loc,:);
                    binClustTSpixAmpData{bin}(len1+1:len1+len2,:) = downAllAxonsClustAmpTS{mouse}(loc,:);
                elseif bin == 2 % sort controllers 
                    % find the indeces for the specific axons needed by type 
                    loc = ismember(axonInds{mouse},controllerAxons{mouse});
                    len1 = size(binClustTSsizeData{bin},1);
                    len2 = nnz(loc);
                    % sort data 
                    binClustTSsizeData{bin}(len1+1:len1+len2,:) = downAllAxonsClustSizeTS{mouse}(loc,:);
                    binClustTSpixAmpData{bin}(len1+1:len1+len2,:) = downAllAxonsClustAmpTS{mouse}(loc,:);
                elseif bin == 3 % sort bothers  
                    % find the indeces for the specific axons needed by type 
                    loc = ismember(axonInds{mouse},bothAxons{mouse});
                    len1 = size(binClustTSsizeData{bin},1);
                    len2 = nnz(loc);
                    % sort data 
                    binClustTSsizeData{bin}(len1+1:len1+len2,:) = downAllAxonsClustSizeTS{mouse}(loc,:);
                    binClustTSpixAmpData{bin}(len1+1:len1+len2,:) = downAllAxonsClustAmpTS{mouse}(loc,:);
                end 
            end 
        end 
    end  
    count = 1 ;
    clearvars binLabel
    for bin = 1:3
        % determine bin labels 
        for clust = 1:size(binClustTSsizeData{bin},1)
            if clust == 1 
                if isempty(binClustTSsizeData{bin}) == 0                     
                    binLabel(count) = binString(bin);
                    count = count + 1;
                end 
            elseif clust > 1
                if isempty(binClustTSsizeData{bin}) == 0 
                    binLabel(count) = '';
                    count = count + 1;                        
                end                 
            end 
        end 
        if isempty(binClustTSsizeData{bin}) == 0 
            h = plot(x,binClustTSsizeData{bin},'Color',clr(bin,:),'LineWidth',2); 
        end 
    end
    sec_TimeVals = floor(((Frames_pre_stim_start:fps:Frames_post_stim_start)/fps))+1;
    FrameVals(3) = threshFrame;
    FrameVals(2) = threshFrame - (minFrameLen/5);
    FrameVals(1) = FrameVals(2) - (minFrameLen/5);
    FrameVals(4) = threshFrame + (minFrameLen/5);
    FrameVals(5) = FrameVals(4) + (minFrameLen/5);
    legend(binLabel) 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Size (microns squared)") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Change in BBB Plume Size';'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Change in BBB Plume Size';'Absolute Axon Types'})
    end 
    xlim([1 minFrameLen])
    
    % plot change in cluster pixel amplitude color coded by axon  
    figure;
    hold all;
    ax=gca;
    for bin = 1:length(binClustTSsizeData)
       h = plot(x,binClustTSpixAmpData{bin},'Color',clr(bin,:),'LineWidth',2); 
    end 
    legend(binLabel)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Pixel Amplitude") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Change in BBB Plume Pixel Amplitude';'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Change in BBB Plume Pixel Amplitude';'Absolute Axon Types'})
    end     
    xlim([1 minFrameLen])
    
    % plot average change in cluster size 
    figure;
    hold all;
    ax=gca;
    avBinClustSizeTS = NaN(3,minFrameLen);
    count = 1;
    for bin = 1:length(binClustTSsizeData)
        if isempty(binClustTSsizeData{bin}) == 0
            avBinClustSizeTS(count,:) = nanmean(binClustTSsizeData{bin},1);  
            plot(x,avBinClustSizeTS(count,:),'Color',clr(bin,:),'LineWidth',2); 
            % determine 95% CI 
            SEM = (nanstd(binClustTSsizeData{bin}))/(sqrt(size(binClustTSsizeData{bin},1))); %#ok<*NANSTD> % Standard Error            
            ts_Low = tinv(0.025,size(binClustTSsizeData{bin},1)-1);% T-Score for 95% CI
            ts_High = tinv(0.975,size(binClustTSsizeData{bin},1)-1);% T-Score for 95% CI
            CI_Low = (nanmean(binClustTSsizeData{bin},1)) + (ts_Low*SEM);  % Confidence Intervals
            CI_High = (nanmean(binClustTSsizeData{bin},1)) + (ts_High*SEM);  % Confidence Intervals
            % plot the 95% CI 
            clear v f 
            v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
            v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
            % remove NaNs so face can be made and colored 
            nanRows = isnan(v(:,2));
            v(nanRows,:) = []; f = 1:size(v,1);
            patch('Faces',f,'Vertices',v,'FaceColor',clr(bin,:),'EdgeColor','none');
            alpha(0.2)
            count = count + 1;
        end 
    end 
    % remove empty strings 
    emptyStrings = find(binLabel == '');
    binLabel(emptyStrings) = [];
    count = 1;
    binLabel2 = string(1);
    for bin = 1:size(avBinClustSizeTS,1)
        if bin == 1 
            binLabel2(bin) = binLabel(count);
            count = count + 2;
        elseif bin > 1 
            binLabel2(count) = binLabel(bin);
            count = count + 2;
        end 
    end 
    legend(binLabel2)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Size (microns squared)") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Average Change in BBB Plume Size';'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Average Change in BBB Plume Size';'Absolute Axon Types'})
    end 
    xlim([1 minFrameLen])
    
    % plot average change in cluster size 
    figure;
    hold all;
    ax=gca;
    avBinClustPixAmpTS = NaN(3,minFrameLen);
    count = 1;
    for bin = 1:length(binClustTSsizeData)
        if isempty(binClustTSpixAmpData{bin}) == 0
            avBinClustPixAmpTS(count,:) = nanmean(binClustTSpixAmpData{bin},1);  
            plot(x,avBinClustPixAmpTS(count,:),'Color',clr(bin,:),'LineWidth',2);     
            % determine 95% CI 
            SEM = (nanstd(binClustTSpixAmpData{bin}))/(sqrt(size(binClustTSpixAmpData{bin},1))); %#ok<*NANSTD> % Standard Error            
            ts_Low = tinv(0.025,size(binClustTSpixAmpData{bin},1)-1);% T-Score for 95% CI
            ts_High = tinv(0.975,size(binClustTSpixAmpData{bin},1)-1);% T-Score for 95% CI
            CI_Low = (nanmean(binClustTSpixAmpData{bin},1)) + (ts_Low*SEM);  % Confidence Intervals
            CI_High = (nanmean(binClustTSpixAmpData{bin},1)) + (ts_High*SEM);  % Confidence Intervals
            % plot the 95% CI 
            clear v f 
            v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
            v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
            % remove NaNs so face can be made and colored 
            nanRows = isnan(v(:,2));
            v(nanRows,:) = []; f = 1:size(v,1);
            patch('Faces',f,'Vertices',v,'FaceColor',clr(bin,:),'EdgeColor','none');
            alpha(0.2)
            count = count + 1;
        end 
    end 
    legend(binLabel2)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Pixel Amplitude") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Average Change in';'BBB Plume Pixel Amplitude';'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Average Change in';'BBB Plume Pixel Amplitude';'Absolute Axon Types'})
    end 
    xlim([1 minFrameLen])
    
    % plot aligned cluster change in size per bin and total average 
    % determine cluster start frame per bin  
    binClustStartFrame = cell(1,3);
    alignedBinClustsSize = cell(1,3);
    avAlignedClustsSize = cell(1,3);
    figure;
    hold all;
    ax=gca;
    for bin = 1:length(binClustTSsizeData)             
        [clustLocX, clustLocY] = find(~isnan(binClustTSsizeData{bin}));
        clusts = unique(clustLocX);              
        for clust = 1:length(clusts)
            binClustStartFrame{bin}(clust) = min(clustLocY(clustLocX == clust));
        end 
        % align clusters
        % determine longest cluster 
        [longestClustStart,longestClust] = min(binClustStartFrame{bin});
        arrayLen = minFrameLen-longestClustStart+1;
        for clust = 1:size(binClustTSsizeData{bin},1)
            % get data and buffer end as needed 
            data = binClustTSsizeData{bin}(clust,binClustStartFrame{bin}(clust):end);
            data(:,length(data)+1:arrayLen) = NaN;
            % align data 
            alignedBinClustsSize{bin}(clust,:) = data;
        end 
        x = 1:size(alignedBinClustsSize{bin},2);
        % averaged the aligned clusters 
        avAlignedClustsSize{bin} = nanmean(alignedBinClustsSize{bin},1);
        if isempty(binClustTSsizeData{bin}) == 0 
            h = plot(x,avAlignedClustsSize{bin},'Color',clr(bin,:),'LineWidth',2); 
            % determine 95% CI 
            SEM = (nanstd(alignedBinClustsSize{bin}))/(sqrt(size(alignedBinClustsSize{bin},1))); %#ok<*NANSTD> % Standard Error            
            ts_Low = tinv(0.025,size(alignedBinClustsSize{bin},1)-1);% T-Score for 95% CI
            ts_High = tinv(0.975,size(alignedBinClustsSize{bin},1)-1);% T-Score for 95% CI
            CI_Low = (nanmean(alignedBinClustsSize{bin},1)) + (ts_Low*SEM);  % Confidence Intervals
            CI_High = (nanmean(alignedBinClustsSize{bin},1)) + (ts_High*SEM);  % Confidence Intervals
            % plot the 95% CI 
            clear v f 
            v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
            v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
            % remove NaNs so face can be made and colored 
            nanRows = isnan(v(:,2));
            v(nanRows,:) = []; f = 1:size(v,1);
            patch('Faces',f,'Vertices',v,'FaceColor',clr(bin,:),'EdgeColor','none');
            alpha(0.2)
        end 
    end 
    legend(binLabel2)
    Frames_pre_stim_start = -((minFrameLen-1)/2); 
    Frames_post_stim_start = (minFrameLen-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:fps:Frames_post_stim_start)/fps))+0.5+timeEnd;
    FrameVals = round((1:fps:minFrameLen));
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Size (microns squared)") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Change in BBB Plume Size';'Clusters Aligned and Averaged';'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Change in BBB Plume Size';'Clusters Aligned and Averaged';'Absolute Axon Types'})
    end     
    xlim([1 minFrameLen])
    
    % plot aligned cluster change in pixel amplitude per bin and total average 
    % determine cluster start frame per bin  
    alignedBinClustsPixAmp = cell(1,3);
    avAlignedClustsPixAmp = cell(1,3);
    figure;
    hold all;
    ax=gca;
    for bin = 1:length(binClustTSsizeData)             
        % align clusters
        % determine longest cluster 
        [longestClustStart,longestClust] = min(binClustStartFrame{bin});
        arrayLen = minFrameLen-longestClustStart+1;
        for clust = 1:size(binClustTSpixAmpData{bin},1)
            % get data and buffer end as needed 
            data = binClustTSpixAmpData{bin}(clust,binClustStartFrame{bin}(clust):end);
            data(:,length(data)+1:arrayLen) = NaN;
            % align data 
            alignedBinClustsPixAmp{bin}(clust,:) = data;
        end 
        x = 1:size(alignedBinClustsPixAmp{bin},2);
        % averaged the aligned clusters 
        avAlignedClustsPixAmp{bin} = nanmean(alignedBinClustsPixAmp{bin},1);
        if isempty(binClustTSpixAmpData{bin}) == 0 
            h = plot(x,avAlignedClustsPixAmp{bin},'Color',clr(bin,:),'LineWidth',2); 
            % determine 95% CI 
            SEM = (nanstd(alignedBinClustsPixAmp{bin}))/(sqrt(size(alignedBinClustsPixAmp{bin},1))); %#ok<*NANSTD> % Standard Error            
            ts_Low = tinv(0.025,size(alignedBinClustsPixAmp{bin},1)-1);% T-Score for 95% CI
            ts_High = tinv(0.975,size(alignedBinClustsPixAmp{bin},1)-1);% T-Score for 95% CI
            CI_Low = (nanmean(alignedBinClustsPixAmp{bin},1)) + (ts_Low*SEM);  % Confidence Intervals
            CI_High = (nanmean(alignedBinClustsPixAmp{bin},1)) + (ts_High*SEM);  % Confidence Intervals
            % plot the 95% CI 
            clear v f 
            v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
            v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
            % remove NaNs so face can be made and colored 
            nanRows = isnan(v(:,2));
            v(nanRows,:) = []; f = 1:size(v,1);
            patch('Faces',f,'Vertices',v,'FaceColor',clr(bin,:),'EdgeColor','none');
            alpha(0.2)
            count = count + 1;
        end 
    end 
    legend(binLabel2)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Pixel Amplitude") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Change in BBB Plume Pixel Amplitude';'Clusters Aligned and Averaged';'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Change in BBB Plume Pixel Amplitude';'Clusters Aligned and Averaged';'Absolute Axon Types'})
    end     
    xlim([1 minFrameLen])
    
    % plot total aligned cluster size average 
    [~,c] = cellfun(@size,alignedBinClustsSize);
    maxLen = max(c);
    for bin = 1:length(binClustTSsizeData)           
        % put data together with appropriate buffering to get total average 
        data = alignedBinClustsSize{bin};
        data(:,size(data,2)+1:maxLen) = NaN;        
        if bin == 1 
            allClusts = data;
        elseif bin > 1 
            allClusts(size(allClusts,1)+1:size(allClusts,1)+size(data,1),:) = data;
        end 
    end 
    % plot average of all axons w/95% CI 
    figure;
    hold all;
    ax=gca;
    % determine average 
    avAllClustSizeTS = nanmean(allClusts);
    x = 1:length(avAllClustSizeTS);
    % determine 95% CI 
    SEM = (nanstd(allClusts))/(sqrt(size(allClusts,1))); %#ok<*NANSTD> % Standard Error            
    ts_Low = tinv(0.025,size(allClusts,1)-1);% T-Score for 95% CI
    ts_High = tinv(0.975,size(allClusts,1)-1);% T-Score for 95% CI
    CI_Low = (nanmean(allClusts,1)) + (ts_Low*SEM);  % Confidence Intervals
    CI_High = (nanmean(allClusts,1)) + (ts_High*SEM);  % Confidence Intervals
    plot(x,avAllClustSizeTS,'k','LineWidth',2);   
    clear v f 
    v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
    v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
    % remove NaNs so face can be made and colored 
    nanRows = isnan(v(:,2));
    v(nanRows,:) = []; f = 1:size(v,1);
    patch('Faces',f,'Vertices',v,'FaceColor','black','EdgeColor','none');
    alpha(0.3)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Size (microns squared)") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Average Aligned Change in BBB Plume Size';'Across Axons';'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Average Aligned Change in BBB Plume Size';'Across Axons';'Absolute Axon Types'})
    end     
    xlim([1 minFrameLen]) 
    
    % plot total aligned cluster pixel amplitude average 
    for bin = 1:length(binClustTSsizeData)           
        % put data together with appropriate buffering to get total average 
        data = alignedBinClustsPixAmp{bin};
        data(:,size(data,2)+1:maxLen) = NaN;        
        if bin == 1 
            allClusts = data;
        elseif bin > 1 
            allClusts(size(allClusts,1)+1:size(allClusts,1)+size(data,1),:) = data;
        end 
    end 
    % plot average of all axons w/95% CI 
    figure;
    hold all;
    ax=gca;
    % determine average 
    avAllClustSizeTS = nanmean(allClusts);
    x = 1:length(avAllClustSizeTS);
    % determine 95% CI 
    SEM = (nanstd(allClusts))/(sqrt(size(allClusts,1))); %#ok<*NANSTD> % Standard Error            
    ts_Low = tinv(0.025,size(allClusts,1)-1);% T-Score for 95% CI
    ts_High = tinv(0.975,size(allClusts,1)-1);% T-Score for 95% CI
    CI_Low = (nanmean(allClusts,1)) + (ts_Low*SEM);  % Confidence Intervals
    CI_High = (nanmean(allClusts,1)) + (ts_High*SEM);  % Confidence Intervals
    plot(x,avAllClustSizeTS,'k','LineWidth',2);   
    clear v f 
    v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
    v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
    % remove NaNs so face can be made and colored 
    nanRows = isnan(v(:,2));
    v(nanRows,:) = []; f = 1:size(v,1);
    patch('Faces',f,'Vertices',v,'FaceColor','black','EdgeColor','none');
    alpha(0.3)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Pixel Amplitude") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Average Aligned Change in'; 'BBB Plume Pixel Amplitude';'Across Axons';'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Average Aligned Change in'; 'BBB Plume Pixel Amplitude';'Across Axons';'Absolute Axon Types'})
    end     
    xlim([1 minFrameLen])
end 
%% plot average BBB plume change in size and pixel amplitude over time for TS data grouped by axon distance from vessel, shortest cluster distance from axon, plume origin distance from vessel, plume origin distance from axon, axon type, or cluster timing 
x = 1:minFrameLen;
distQ = input('Input 0 to plot TS data grouped by close (<10 microns) vs far (>10 microns). Input 1 to set a distance range . ');
if ETAorSTAq == 0 % STA data 
    distQ2 = input('Input 0 to sort by axon distance from vessel. Input 1 to sort by shortest BBB plume distance from axon. Input 2 to sort by BBB plume distance from vessel. Input 3 to sort by BBB plume origin distance from axon. ');
    aTypeQ = input('Input 0 to sort data by axon type. Input 1 to sort data by cluster timing before or after 0 sec. ');
elseif ETAorSTAq == 1 % ETA data 
    distQ2 = 2;
    aTypeQ = 1;
end 
if aTypeQ == 0
    closeAxons = cell(1,mouseNum);
    farAxons  = cell(1,mouseNum);
    closeAxonLoc = cell(1,mouseNum);
    farAxonLoc = cell(1,mouseNum);
    clustDistsAndAxon = cell(1,mouseNum);
    closeClusts = cell(1,mouseNum);
    farClusts = cell(1,mouseNum);
    closeClustLoc = cell(1,mouseNum);
    farClustLoc = cell(1,mouseNum);
    listenerAxonLoc = cell(1,mouseNum);
    controllerAxonLoc = cell(1,mouseNum);
    bothAxonLoc = cell(1,mouseNum);
    closeListenerAxonLocs = cell(1,mouseNum);
    farListenerAxonLocs = cell(1,mouseNum);
    closeControllerAxonLocs = cell(1,mouseNum);
    farControllerAxonLocs = cell(1,mouseNum);
    closeBothAxonLocs = cell(1,mouseNum);
    farBothAxonLocs = cell(1,mouseNum);
    avClocFrameClose = cell(1,mouseNum);
    avClocFrameFar = cell(1,mouseNum);
    closeListenerAxons = cell(1,mouseNum);
    closeControllerAxons = cell(1,mouseNum);
    closeBothAxons= cell(1,mouseNum);
    farListenerAxons = cell(1,mouseNum);
    farControllerAxons = cell(1,mouseNum);
    farBothAxons = cell(1,mouseNum);
    avClocFrameCloseListener = cell(1,mouseNum); 
    avClocFrameCloseController = cell(1,mouseNum);
    avClocFrameCloseBoth = cell(1,mouseNum);
    avClocFrameFarListener = cell(1,mouseNum); 
    avClocFrameFarController = cell(1,mouseNum);
    avClocFrameFarBoth = cell(1,mouseNum);
    % identify the locs for listener, controller, and both axons 
    for mouse = 1:mouseNum
        listenerAxonLoc{mouse} = ismember(axonInds{mouse},listenerAxons{mouse});
        controllerAxonLoc{mouse} = ismember(axonInds{mouse},controllerAxons{mouse});
        bothAxonLoc{mouse} = ismember(axonInds{mouse},bothAxons{mouse});
    end 
    if distQ2 == 0 % group data by axon distance from vessel 
        for mouse = 1:mouseNum
            % identify what axons are close (<10 microns) and far (>10 microns)
            % from vessel
            if distQ == 0
                closeAxons{mouse} = find(minVAdists{mouse} <= 10);
                farAxons{mouse} = find(minVAdists{mouse} > 10);
                avClocFrameClose{mouse} = ((avClocFrame{mouse}((minVAdists{mouse} <= 10),:))/FPS{mouse})-windSize/2;
                avClocFrameFar{mouse} = ((avClocFrame{mouse}((minVAdists{mouse} > 10),:))/FPS{mouse})-windSize/2;
            elseif distQ == 1
                % specify what distance range you want to look at specifically 
                if mouse == 1 
                    distRange = input('What is the range of distances (in microns) that you specifically want to see? Input [min,max]. ');
                end 
                closeAxons{mouse} = find(minVAdists{mouse} >= distRange(1) & minVAdists{mouse} <= distRange(2));
                farAxons{mouse} = find(minVAdists{mouse} < distRange(1) | minVAdists{mouse} > distRange(2));
                avClocFrameClose{mouse} = ((avClocFrame{mouse}((minVAdists{mouse} >= distRange(1) & minVAdists{mouse} <= distRange(2)),:))/FPS{mouse})-windSize/2;
                avClocFrameFar{mouse} = ((avClocFrame{mouse}((minVAdists{mouse} < distRange(1) | minVAdists{mouse} > distRange(2)),:))/FPS{mouse})-windSize/2;
            end     
            closeAxonLoc{mouse} = ismember(axonInds{mouse},closeAxons{mouse});
            farAxonLoc{mouse} = ismember(axonInds{mouse},farAxons{mouse});
            % identify close vs far listeners, controllers, and both axons 
            closeListenerAxonLocs{mouse} = (closeAxonLoc{mouse}+listenerAxonLoc{mouse}) == 2;
            farListenerAxonLocs{mouse} = (farAxonLoc{mouse}+listenerAxonLoc{mouse}) == 2;
            closeControllerAxonLocs{mouse} = (closeAxonLoc{mouse}+controllerAxonLoc{mouse}) == 2;
            farControllerAxonLocs{mouse} = (farAxonLoc{mouse}+controllerAxonLoc{mouse}) == 2; 
            closeBothAxonLocs{mouse} = (closeAxonLoc{mouse}+bothAxonLoc{mouse}) == 2;
            farBothAxonLocs{mouse} = (farAxonLoc{mouse}+bothAxonLoc{mouse}) == 2;
            closeListenerAxons{mouse} = intersect(closeAxons{mouse},listenerAxons{mouse});
            closeControllerAxons{mouse} = intersect(closeAxons{mouse},controllerAxons{mouse});
            closeBothAxons{mouse} = intersect(closeAxons{mouse},bothAxons{mouse}); 
            farListenerAxons{mouse} = intersect(farAxons{mouse},listenerAxons{mouse});
            farControllerAxons{mouse} = intersect(farAxons{mouse},controllerAxons{mouse});
            farBothAxons{mouse} = intersect(farAxons{mouse},bothAxons{mouse}); 
            avClocFrameCloseListener{mouse} =  avClocFrameClose{mouse}(ismember(closeAxons{mouse},closeListenerAxons{mouse}),:);
            avClocFrameCloseController{mouse} =  avClocFrameClose{mouse}(ismember(closeAxons{mouse},closeControllerAxons{mouse}),:);
            avClocFrameCloseBoth{mouse} =  avClocFrameClose{mouse}(ismember(closeAxons{mouse},closeBothAxons{mouse}),:);
            avClocFrameFarListener{mouse} =  avClocFrameFar{mouse}(ismember(farAxons{mouse},farListenerAxons{mouse}),:);
            avClocFrameFarController{mouse} =  avClocFrameFar{mouse}(ismember(farAxons{mouse},farControllerAxons{mouse}),:);
            avClocFrameFarBoth{mouse} =  avClocFrameFar{mouse}(ismember(farAxons{mouse},farBothAxons{mouse}),:);
        end 
    elseif distQ2 == 1 % group data by BBB plume distance from axon 
        closeClustLocPerAxon = cell(1,mouseNum);
        farClustLocPerAxon = cell(1,mouseNum);
        resortedAvClocFrame = cell(1,mouseNum);
        for mouse = 1:mouseNum
            [r,~] = find(~isnan(timeDistArray{mouse}(:,1)));
            clustDistsAndAxon{mouse}(:,1) = timeDistArray{mouse}(r,2); 
            clustDistsAndAxon{mouse}(:,2) = timeDistArray{mouse}(r,3); 
            % identify what BBB plumes are close (<= 10 microns) or far (>
            % 10 microns) from their axon 
            if distQ == 0
                % the below locs organize the cluster by axon 
                closeClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) <= 10; 
                farClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) > 10;
                % sort close/farClustLoc and avCloc so that each row is per axon
                for ccell = 1:size(avClocFrame{mouse},1)
                    closeClustLocPerAxon{mouse}{ccell} = closeClustLoc{mouse}(axonInds{mouse} == ccell);
                    farClustLocPerAxon{mouse}{ccell} = farClustLoc{mouse}(axonInds{mouse} == ccell);
                    data = avClocFrame{mouse}(ccell,:);
                    resortedAvClocFrame{mouse}{ccell} = data(~isnan(data)); % remove nans B = A(~isnan(A))
                end 
                % identify the cluster start frame associated with close
                % and far cluster locs; keep avClocFrameClose/Far with rows per axon
                avClocFrameClose{mouse} = nan(size(avClocFrame{mouse},1),size(avClocFrame{mouse},2));
                avClocFrameFar{mouse} = nan(size(avClocFrame{mouse},1),size(avClocFrame{mouse},2));
                for ccell = 1:size(avClocFrame{mouse},1)
                    clustStartsClose = resortedAvClocFrame{mouse}{ccell}(closeClustLocPerAxon{mouse}{ccell});
                    avClocFrameClose{mouse}(ccell,1:length(clustStartsClose)) = (clustStartsClose/FPS{mouse})-windSize/2;
                    clustStartsFar = resortedAvClocFrame{mouse}{ccell}(farClustLocPerAxon{mouse}{ccell});
                    avClocFrameFar{mouse}(ccell,1:length(clustStartsFar)) = (clustStartsFar/FPS{mouse})-windSize/2;
                end              
            elseif distQ == 1
                % specify what distance range you want to look at specifically 
                if mouse == 1 
                    distRange = input('What is the range of distances (in microns) that you specifically want to see? Input [min,max]. ');
                end 
                % the below locs organize the cluster by axon 
                closeClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) >= distRange(1) & clustDistsAndAxon{mouse}(:,1) <= distRange(2); 
                farClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) < distRange(1) | clustDistsAndAxon{mouse}(:,1) > distRange(2);
                % sort close/farClustLoc and avCloc so that each row is per axon
                for ccell = 1:size(avClocFrame{mouse},1)
                    closeClustLocPerAxon{mouse}{ccell} = closeClustLoc{mouse}(axonInds{mouse} == ccell);
                    farClustLocPerAxon{mouse}{ccell} = farClustLoc{mouse}(axonInds{mouse} == ccell);
                    data = avClocFrame{mouse}(ccell,:);
                    resortedAvClocFrame{mouse}{ccell} = data(~isnan(data)); % remove nans B = A(~isnan(A))
                end 
                % identify the cluster start frame associated with close
                % and far cluster locs; keep avClocFrameClose/Far with rows per axon
                avClocFrameClose{mouse} = nan(size(avClocFrame{mouse},1),size(avClocFrame{mouse},2));
                avClocFrameFar{mouse} = nan(size(avClocFrame{mouse},1),size(avClocFrame{mouse},2));
                for ccell = 1:size(avClocFrame{mouse},1)
                    clustStartsClose = resortedAvClocFrame{mouse}{ccell}(closeClustLocPerAxon{mouse}{ccell});
                    avClocFrameClose{mouse}(ccell,1:length(clustStartsClose)) = (clustStartsClose/FPS{mouse})-windSize/2;
                    clustStartsFar = resortedAvClocFrame{mouse}{ccell}(farClustLocPerAxon{mouse}{ccell});
                    avClocFrameFar{mouse}(ccell,1:length(clustStartsFar)) = (clustStartsFar/FPS{mouse})-windSize/2;
                end  
            end     
            % identify close vs far listeners, controllers, and both axons 
            closeListenerAxonLocs{mouse} = (closeClustLoc{mouse}'+listenerAxonLoc{mouse}) == 2;
            farListenerAxonLocs{mouse} = (farClustLoc{mouse}'+listenerAxonLoc{mouse}) == 2;
            closeControllerAxonLocs{mouse} = (closeClustLoc{mouse}'+controllerAxonLoc{mouse}) == 2;
            farControllerAxonLocs{mouse} = (farClustLoc{mouse}'+controllerAxonLoc{mouse}) == 2; 
            closeBothAxonLocs{mouse} = (closeClustLoc{mouse}'+bothAxonLoc{mouse}) == 2;
            farBothAxonLocs{mouse} = (farClustLoc{mouse}'+bothAxonLoc{mouse}) == 2; 
            avClocFrameCloseListener{mouse} =  avClocFrameClose{mouse}(listenerAxons{mouse},:);
            avClocFrameCloseController{mouse} =  avClocFrameClose{mouse}(controllerAxons{mouse},:);
            avClocFrameCloseBoth{mouse} =  avClocFrameClose{mouse}(bothAxons{mouse},:);
            avClocFrameFarListener{mouse} =  avClocFrameFar{mouse}(listenerAxons{mouse},:);
            avClocFrameFarController{mouse} =  avClocFrameFar{mouse}(controllerAxons{mouse},:);
            avClocFrameFarBoth{mouse} =  avClocFrameFar{mouse}(bothAxons{mouse},:);
        end 
    elseif distQ2 == 2 % group data by BBB plume origin distance from vessel 
        closeClustLocPerAxon = cell(1,mouseNum);
        farClustLocPerAxon = cell(1,mouseNum);
        resortedAvClocFrame = cell(1,mouseNum);
        for mouse = 1:mouseNum
            [r,~] = find(~isnan(timeCOVdistArray{mouse}(:,1)));
            clustDistsAndAxon{mouse}(:,1) = timeCOVdistArray{mouse}(r,2); 
            clustDistsAndAxon{mouse}(:,2) = timeCOVdistArray{mouse}(r,3); 
            % identify what BBB plumes are close (<= 10 microns) or far (>
            % 10 microns) from their axon 
            if distQ == 0
                % the below locs organize the cluster by axon 
                closeClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) <= 10; 
                farClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) > 10;
                % sort close/farClustLoc and avCloc so that each row is per axon
                for ccell = 1:size(avClocFrame{mouse},1)
                    closeClustLocPerAxon{mouse}{ccell} = closeClustLoc{mouse}(axonInds{mouse} == ccell);
                    farClustLocPerAxon{mouse}{ccell} = farClustLoc{mouse}(axonInds{mouse} == ccell);
                    data = avClocFrame{mouse}(ccell,:);
                    resortedAvClocFrame{mouse}{ccell} = data(~isnan(data)); % remove nans B = A(~isnan(A))
                end 
                % identify the cluster start frame associated with close
                % and far cluster locs; keep avClocFrameClose/Far with rows per axon
                avClocFrameClose{mouse} = nan(size(avClocFrame{mouse},1),size(avClocFrame{mouse},2));
                avClocFrameFar{mouse} = nan(size(avClocFrame{mouse},1),size(avClocFrame{mouse},2));
                for ccell = 1:size(avClocFrame{mouse},1)
                    clustStartsClose = resortedAvClocFrame{mouse}{ccell}(closeClustLocPerAxon{mouse}{ccell});
                    avClocFrameClose{mouse}(ccell,1:length(clustStartsClose)) = (clustStartsClose);
                    clustStartsFar = resortedAvClocFrame{mouse}{ccell}(farClustLocPerAxon{mouse}{ccell});
                    avClocFrameFar{mouse}(ccell,1:length(clustStartsFar)) = (clustStartsFar);
                end              
            elseif distQ == 1
                % specify what distance range you want to look at specifically 
                if mouse == 1 
                    distRange = input('What is the range of distances (in microns) that you specifically want to see? Input [min,max]. ');
                end 
                % the below locs organize the cluster by axon 
                closeClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) >= distRange(1) & clustDistsAndAxon{mouse}(:,1) <= distRange(2); 
                farClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) < distRange(1) | clustDistsAndAxon{mouse}(:,1) > distRange(2);
                % sort close/farClustLoc and avCloc so that each row is per axon
                for ccell = 1:size(avClocFrame{mouse},1)
                    closeClustLocPerAxon{mouse}{ccell} = closeClustLoc{mouse}(axonInds{mouse} == ccell);
                    farClustLocPerAxon{mouse}{ccell} = farClustLoc{mouse}(axonInds{mouse} == ccell);
                    data = avClocFrame{mouse}(ccell,:);
                    resortedAvClocFrame{mouse}{ccell} = data(~isnan(data)); % remove nans B = A(~isnan(A))
                end 
                % identify the cluster start frame associated with close
                % and far cluster locs; keep avClocFrameClose/Far with rows per axon
                avClocFrameClose{mouse} = nan(size(avClocFrame{mouse},1),size(avClocFrame{mouse},2));
                avClocFrameFar{mouse} = nan(size(avClocFrame{mouse},1),size(avClocFrame{mouse},2));
                for ccell = 1:size(avClocFrame{mouse},1)
                    clustStartsClose = resortedAvClocFrame{mouse}{ccell}(closeClustLocPerAxon{mouse}{ccell});
                    avClocFrameClose{mouse}(ccell,1:length(clustStartsClose)) = (clustStartsClose);
                    clustStartsFar = resortedAvClocFrame{mouse}{ccell}(farClustLocPerAxon{mouse}{ccell});
                    avClocFrameFar{mouse}(ccell,1:length(clustStartsFar)) = (clustStartsFar);
                end  
            end     
            % identify close vs far listeners, controllers, and both axons 
            closeListenerAxonLocs{mouse} = (closeClustLoc{mouse}'+listenerAxonLoc{mouse}) == 2;
            farListenerAxonLocs{mouse} = (farClustLoc{mouse}'+listenerAxonLoc{mouse}) == 2;
            closeControllerAxonLocs{mouse} = (closeClustLoc{mouse}'+controllerAxonLoc{mouse}) == 2;
            farControllerAxonLocs{mouse} = (farClustLoc{mouse}'+controllerAxonLoc{mouse}) == 2; 
            closeBothAxonLocs{mouse} = (closeClustLoc{mouse}'+bothAxonLoc{mouse}) == 2;
            farBothAxonLocs{mouse} = (farClustLoc{mouse}'+bothAxonLoc{mouse}) == 2; 
            avClocFrameCloseListener{mouse} =  avClocFrameClose{mouse}(listenerAxons{mouse},:);
            avClocFrameCloseController{mouse} =  avClocFrameClose{mouse}(controllerAxons{mouse},:);
            avClocFrameCloseBoth{mouse} =  avClocFrameClose{mouse}(bothAxons{mouse},:);
            avClocFrameFarListener{mouse} =  avClocFrameFar{mouse}(listenerAxons{mouse},:);
            avClocFrameFarController{mouse} =  avClocFrameFar{mouse}(controllerAxons{mouse},:);
            avClocFrameFarBoth{mouse} =  avClocFrameFar{mouse}(bothAxons{mouse},:);
        end 
    elseif distQ2 == 3 % group data by BBB plume origin distance from axon  
        closeClustLocPerAxon = cell(1,mouseNum);
        farClustLocPerAxon = cell(1,mouseNum);
        resortedAvClocFrame = cell(1,mouseNum);
        for mouse = 1:mouseNum
            [r,~] = find(~isnan(timeODistArray{mouse}(:,1)));
            clustDistsAndAxon{mouse}(:,1) = timeODistArray{mouse}(r,2); 
            clustDistsAndAxon{mouse}(:,2) = timeODistArray{mouse}(r,3); 
            % identify what BBB plumes are close (<= 10 microns) or far (>
            % 10 microns) from their axon 
            if distQ == 0
                % the below locs organize the cluster by axon 
                closeClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) <= 10; 
                farClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) > 10;
                % sort close/farClustLoc and avCloc so that each row is per axon
                for ccell = 1:size(avClocFrame{mouse},1)
                    closeClustLocPerAxon{mouse}{ccell} = closeClustLoc{mouse}(axonInds{mouse} == ccell);
                    farClustLocPerAxon{mouse}{ccell} = farClustLoc{mouse}(axonInds{mouse} == ccell);
                    data = avClocFrame{mouse}(ccell,:);
                    resortedAvClocFrame{mouse}{ccell} = data(~isnan(data)); % remove nans B = A(~isnan(A))
                end 
                % identify the cluster start frame associated with close
                % and far cluster locs; keep avClocFrameClose/Far with rows per axon
                avClocFrameClose{mouse} = nan(size(avClocFrame{mouse},1),size(avClocFrame{mouse},2));
                avClocFrameFar{mouse} = nan(size(avClocFrame{mouse},1),size(avClocFrame{mouse},2));
                for ccell = 1:size(avClocFrame{mouse},1)
                    clustStartsClose = resortedAvClocFrame{mouse}{ccell}(closeClustLocPerAxon{mouse}{ccell});
                    avClocFrameClose{mouse}(ccell,1:length(clustStartsClose)) = (clustStartsClose/FPS{mouse})-windSize/2;
                    clustStartsFar = resortedAvClocFrame{mouse}{ccell}(farClustLocPerAxon{mouse}{ccell});
                    avClocFrameFar{mouse}(ccell,1:length(clustStartsFar)) = (clustStartsFar/FPS{mouse})-windSize/2;
                end              
            elseif distQ == 1
                % specify what distance range you want to look at specifically 
                if mouse == 1 
                    distRange = input('What is the range of distances (in microns) that you specifically want to see? Input [min,max]. ');
                end 
                % the below locs organize the cluster by axon 
                closeClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) >= distRange(1) & clustDistsAndAxon{mouse}(:,1) <= distRange(2); 
                farClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) < distRange(1) | clustDistsAndAxon{mouse}(:,1) > distRange(2);
                % sort close/farClustLoc and avCloc so that each row is per axon
                for ccell = 1:size(avClocFrame{mouse},1)
                    closeClustLocPerAxon{mouse}{ccell} = closeClustLoc{mouse}(axonInds{mouse} == ccell);
                    farClustLocPerAxon{mouse}{ccell} = farClustLoc{mouse}(axonInds{mouse} == ccell);
                    data = avClocFrame{mouse}(ccell,:);
                    resortedAvClocFrame{mouse}{ccell} = data(~isnan(data)); % remove nans B = A(~isnan(A))
                end 
                % identify the cluster start frame associated with close
                % and far cluster locs; keep avClocFrameClose/Far with rows per axon
                avClocFrameClose{mouse} = nan(size(avClocFrame{mouse},1),size(avClocFrame{mouse},2));
                avClocFrameFar{mouse} = nan(size(avClocFrame{mouse},1),size(avClocFrame{mouse},2));
                for ccell = 1:size(avClocFrame{mouse},1)
                    clustStartsClose = resortedAvClocFrame{mouse}{ccell}(closeClustLocPerAxon{mouse}{ccell});
                    avClocFrameClose{mouse}(ccell,1:length(clustStartsClose)) = (clustStartsClose/FPS{mouse})-windSize/2;
                    clustStartsFar = resortedAvClocFrame{mouse}{ccell}(farClustLocPerAxon{mouse}{ccell});
                    avClocFrameFar{mouse}(ccell,1:length(clustStartsFar)) = (clustStartsFar/FPS{mouse})-windSize/2;
                end  
            end     
            % identify close vs far listeners, controllers, and both axons 
            closeListenerAxonLocs{mouse} = (closeClustLoc{mouse}'+listenerAxonLoc{mouse}) == 2;
            farListenerAxonLocs{mouse} = (farClustLoc{mouse}'+listenerAxonLoc{mouse}) == 2;
            closeControllerAxonLocs{mouse} = (closeClustLoc{mouse}'+controllerAxonLoc{mouse}) == 2;
            farControllerAxonLocs{mouse} = (farClustLoc{mouse}'+controllerAxonLoc{mouse}) == 2; 
            closeBothAxonLocs{mouse} = (closeClustLoc{mouse}'+bothAxonLoc{mouse}) == 2;
            farBothAxonLocs{mouse} = (farClustLoc{mouse}'+bothAxonLoc{mouse}) == 2; 
            avClocFrameCloseListener{mouse} =  avClocFrameClose{mouse}(listenerAxons{mouse},:);
            avClocFrameCloseController{mouse} =  avClocFrameClose{mouse}(controllerAxons{mouse},:);
            avClocFrameCloseBoth{mouse} =  avClocFrameClose{mouse}(bothAxons{mouse},:);
            avClocFrameFarListener{mouse} =  avClocFrameFar{mouse}(listenerAxons{mouse},:);
            avClocFrameFarController{mouse} =  avClocFrameFar{mouse}(controllerAxons{mouse},:);
            avClocFrameFarBoth{mouse} =  avClocFrameFar{mouse}(bothAxons{mouse},:);
        end 
    end 
    % sort data 
    binClustTSsizeData = cell(1,3);
    binClustTSpixAmpData = cell(1,3);
    binClocFrame = cell(1,3);
    for bin = 1:3
        for loc = 1:2 
            for mouse = 1:mouseNum
                if mouse == 1 
                    if loc == 1 % sort close axons/clusters 
                        if bin == 1 % sort listeners
                            % sort data 
                            binClustTSsizeData{bin}{loc} = downAllAxonsClustSizeTS{mouse}(closeListenerAxonLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc} = downAllAxonsClustAmpTS{mouse}(closeListenerAxonLocs{mouse},:);
                            binClocFrame{bin}{loc} = reshape(avClocFrameCloseListener{mouse},1,size(avClocFrameCloseListener{mouse},1)*size(avClocFrameCloseListener{mouse},2));
                        elseif bin == 2 % sort controllers 
                            % sort data 
                            binClustTSsizeData{bin}{loc} = downAllAxonsClustSizeTS{mouse}(closeControllerAxonLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc} = downAllAxonsClustAmpTS{mouse}(closeControllerAxonLocs{mouse},:);
                            binClocFrame{bin}{loc} = reshape(avClocFrameCloseController{mouse},1,size(avClocFrameCloseController{mouse},1)*size(avClocFrameCloseController{mouse},2));
                        elseif bin == 3 % sort bothers  
                            % sort data 
                            binClustTSsizeData{bin}{loc} = downAllAxonsClustSizeTS{mouse}(closeBothAxonLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc} = downAllAxonsClustAmpTS{mouse}(closeBothAxonLocs{mouse},:);
                            binClocFrame{bin}{loc} = reshape(avClocFrameCloseBoth{mouse},1,size(avClocFrameCloseBoth{mouse},1)*size(avClocFrameCloseBoth{mouse},2));
                        end 
                    elseif loc == 2 % sort far axons/clusters
                        if bin == 1 % sort listeners
                            % sort data 
                            binClustTSsizeData{bin}{loc} = downAllAxonsClustSizeTS{mouse}(farListenerAxonLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc} = downAllAxonsClustAmpTS{mouse}(farListenerAxonLocs{mouse},:);
                            binClocFrame{bin}{loc} = reshape(avClocFrameFarListener{mouse},1,size(avClocFrameFarListener{mouse},1)*size(avClocFrameFarListener{mouse},2));
                        elseif bin == 2 % sort controllers 
                            % sort data 
                            binClustTSsizeData{bin}{loc} = downAllAxonsClustSizeTS{mouse}(farControllerAxonLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc} = downAllAxonsClustAmpTS{mouse}(farControllerAxonLocs{mouse},:);
                            binClocFrame{bin}{loc} = reshape(avClocFrameFarController{mouse},1,size(avClocFrameFarController{mouse},1)*size(avClocFrameFarController{mouse},2));
                        elseif bin == 3 % sort bothers  
                            % sort data 
                            binClustTSsizeData{bin}{loc} = downAllAxonsClustSizeTS{mouse}(farBothAxonLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc} = downAllAxonsClustAmpTS{mouse}(farBothAxonLocs{mouse},:);
                            binClocFrame{bin}{loc} = reshape(avClocFrameFarBoth{mouse},1,size(avClocFrameFarBoth{mouse},1)*size(avClocFrameFarBoth{mouse},2));
                        end 
                    end 
                elseif mouse > 1
                    if loc == 1 % sort close axons/clusters
                        if bin == 1 % sort listeners
                            len1 = size(binClustTSsizeData{bin}{loc},1);
                            len2 = nnz(closeListenerAxonLocs{mouse});
                            len3 = length(binClocFrame{bin}{loc});
                            % sort data 
                            binClustTSsizeData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustSizeTS{mouse}(closeListenerAxonLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustAmpTS{mouse}(closeListenerAxonLocs{mouse},:);
                            binClocFrame{bin}{loc}(len3+1:len3+size(avClocFrameCloseListener{mouse},1)*size(avClocFrameCloseListener{mouse},2)) = reshape(avClocFrameCloseListener{mouse},1,size(avClocFrameCloseListener{mouse},1)*size(avClocFrameCloseListener{mouse},2));
                        elseif bin == 2 % sort controllers 
                            len1 = size(binClustTSsizeData{bin}{loc},1);
                            len2 = nnz(closeControllerAxonLocs{mouse});
                            len3 = length(binClocFrame{bin}{loc});
                            % sort data 
                            binClustTSsizeData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustSizeTS{mouse}(closeControllerAxonLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustAmpTS{mouse}(closeControllerAxonLocs{mouse},:);
                            binClocFrame{bin}{loc}(len3+1:len3+size(avClocFrameCloseController{mouse},1)*size(avClocFrameCloseController{mouse},2)) = reshape(avClocFrameCloseController{mouse},1,size(avClocFrameCloseController{mouse},1)*size(avClocFrameCloseController{mouse},2));
                        elseif bin == 3 % sort bothers  
                            len1 = size(binClustTSsizeData{bin}{loc},1);
                            len2 = nnz(closeBothAxonLocs{mouse});
                            len3 = length(binClocFrame{bin}{loc});
                            % sort data 
                            binClustTSsizeData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustSizeTS{mouse}(closeBothAxonLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustAmpTS{mouse}(closeBothAxonLocs{mouse},:);
                            binClocFrame{bin}{loc}(len3+1:len3+size(avClocFrameCloseBoth{mouse},1)*size(avClocFrameCloseBoth{mouse},2)) = reshape(avClocFrameCloseBoth{mouse},1,size(avClocFrameCloseBoth{mouse},1)*size(avClocFrameCloseBoth{mouse},2));
                        end 
                    elseif loc == 2 % sort far axons/clusters
                        if bin == 1 % sort listeners
                            len1 = size(binClustTSsizeData{bin}{loc},1);
                            len2 = nnz(farListenerAxonLocs{mouse});
                            len3 = length(binClocFrame{bin}{loc});
                            % sort data 
                            binClustTSsizeData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustSizeTS{mouse}(farListenerAxonLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustAmpTS{mouse}(farListenerAxonLocs{mouse},:);
                            binClocFrame{bin}{loc}(len3+1:len3+size(avClocFrameFarListener{mouse},1)*size(avClocFrameFarListener{mouse},2)) =  reshape(avClocFrameFarListener{mouse},1,size(avClocFrameFarListener{mouse},1)*size(avClocFrameFarListener{mouse},2));
                        elseif bin == 2 % sort controllers 
                            len1 = size(binClustTSsizeData{bin}{loc},1);
                            len2 = nnz(farControllerAxonLocs{mouse});
                            len3 = length(binClocFrame{bin}{loc});
                            % sort data 
                            binClustTSsizeData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustSizeTS{mouse}(farControllerAxonLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustAmpTS{mouse}(farControllerAxonLocs{mouse},:);
                            binClocFrame{bin}{loc}(len3+1:len3+size(avClocFrameFarController{mouse},1)*size(avClocFrameFarController{mouse},2)) = reshape(avClocFrameFarController{mouse},1,size(avClocFrameFarController{mouse},1)*size(avClocFrameFarController{mouse},2));
                        elseif bin == 3 % sort bothers  
                            len1 = size(binClustTSsizeData{bin}{loc},1);
                            len2 = nnz(farBothAxonLocs{mouse});
                            len3 = length(binClocFrame{bin}{loc});
                            % sort data 
                            binClustTSsizeData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustSizeTS{mouse}(farBothAxonLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustAmpTS{mouse}(farBothAxonLocs{mouse},:);
                            binClocFrame{bin}{loc}(len3+1:len3+size(avClocFrameFarBoth{mouse},1)*size(avClocFrameFarBoth{mouse},2)) = reshape(avClocFrameFarBoth{mouse},1,size(avClocFrameFarBoth{mouse},1)*size(avClocFrameFarBoth{mouse},2));
                        end 
                    end 
                end 
            end 
        end 
    end 
elseif aTypeQ == 1 
    clr = hsv(2);
    binString = ["Pre-Spike Clusters","Post-Spike Clusters"];   
    closeAxons = cell(1,mouseNum);
    farAxons  = cell(1,mouseNum);
    closeAxonLoc = cell(1,mouseNum);
    farAxonLoc = cell(1,mouseNum);        
    clustDistsAndAxon = cell(1,mouseNum);
    closeClusts = cell(1,mouseNum);
    farClusts = cell(1,mouseNum);
    closeClustLoc = cell(1,mouseNum);
    farClustLoc = cell(1,mouseNum);
    avClocFrameClose = cell(1,mouseNum);
    avClocFrameFar = cell(1,mouseNum);
    beforeLoc = cell(1,mouseNum);
    afterLoc = cell(1,mouseNum);
    reshpdAvClocFrame = cell(1,mouseNum);
    closeBeforeClustLocs = cell(1,mouseNum);
    farBeforeClustLocs = cell(1,mouseNum);
    closeAfterClustLocs = cell(1,mouseNum);
    farAfterClustLocs = cell(1,mouseNum);
    avClocFrameCloseBefore = cell(1,mouseNum);
    avClocFrameCloseAfter = cell(1,mouseNum);
    avClocFrameFarBefore = cell(1,mouseNum);
    avClocFrameFarAfter = cell(1,mouseNum);
    if distQ2 == 0 % group data by axon distance from vessel 
        for mouse = 1:mouseNum
            % identify what axons are close (<10 microns) and far (>10 microns)
            % from vessel
            if distQ == 0
                closeAxons{mouse} = find(minVAdists{mouse} <= 10);
                farAxons{mouse} = find(minVAdists{mouse} > 10);
                avClocFrameClose{mouse} = ((avClocFrame{mouse}((minVAdists{mouse} <= 10),:))/FPS{mouse})-windSize/2;
                avClocFrameFar{mouse} = ((avClocFrame{mouse}((minVAdists{mouse} > 10),:))/FPS{mouse})-windSize/2;
            elseif distQ == 1
                % specify what distance range you want to look at specifically 
                if mouse == 1 
                    distRange = input('What is the range of distances (in microns) that you specifically want to see? Input [min,max]. ');
                end 
                closeAxons{mouse} = find(minVAdists{mouse} >= distRange(1) & minVAdists{mouse} <= distRange(2));
                farAxons{mouse} = find(minVAdists{mouse} < distRange(1) | minVAdists{mouse} > distRange(2));
                avClocFrameClose{mouse} = ((avClocFrame{mouse}((minVAdists{mouse} >= distRange(1) & minVAdists{mouse} <= distRange(2)),:))/FPS{mouse})-windSize/2;
                avClocFrameFar{mouse} = ((avClocFrame{mouse}((minVAdists{mouse} < distRange(1) | minVAdists{mouse} > distRange(2)),:))/FPS{mouse})-windSize/2;                   
            end     
            closeAxonLoc{mouse} = ismember(axonInds{mouse},closeAxons{mouse});
            farAxonLoc{mouse} = ismember(axonInds{mouse},farAxons{mouse});
            data = (avClocFrame{mouse}/FPS{mouse})-windSize/2; % converts frame to time in sec for comparison across mice
            % reshape avClocFrame so clusters are in order of axons 
            for ccell = 1:size(avClocFrame{mouse},1)
                if ccell == 1 
                    reshpdAvClocFrame{mouse} =  data(ccell,~isnan(data(ccell,:)));
                elseif ccell > 1 
                    len = length(reshpdAvClocFrame{mouse});
                    reshpdAvClocFrame{mouse}(len+1:len+sum(~isnan(avClocFrame{mouse}(ccell,:)))) =  data(ccell,~isnan(avClocFrame{mouse}(ccell,:))) ;
                end 
            end 
            % use reshpdAvClocFrame to get the loc of clusters < 0 and >= 0 sec
            beforeLoc{mouse} = reshpdAvClocFrame{mouse} < 0;
            afterLoc{mouse} = reshpdAvClocFrame{mouse} >= 0;
            % identify close vs far clusters that come before and after  
            closeBeforeClustLocs{mouse} = (closeAxonLoc{mouse}+beforeLoc{mouse}) == 2;
            farBeforeClustLocs{mouse} = (farAxonLoc{mouse}+beforeLoc{mouse}) == 2;
            closeAfterClustLocs{mouse} = (closeAxonLoc{mouse}+afterLoc{mouse}) == 2;
            farAfterClustLocs{mouse} = (farAxonLoc{mouse}+afterLoc{mouse}) == 2; 
            avClocFrameCloseBefore{mouse} =  reshpdAvClocFrame{mouse}(closeBeforeClustLocs{mouse});
            avClocFrameCloseAfter{mouse} =  reshpdAvClocFrame{mouse}(closeAfterClustLocs{mouse});
            avClocFrameFarBefore{mouse} =  reshpdAvClocFrame{mouse}(farBeforeClustLocs{mouse});
            avClocFrameFarAfter{mouse} =  reshpdAvClocFrame{mouse}(farAfterClustLocs{mouse});
        end            
    elseif distQ2 == 1 % group data by BBB plume distance from axon 
        closeClustLocPerAxon = cell(1,mouseNum);
        farClustLocPerAxon = cell(1,mouseNum);
        resortedAvClocFrame = cell(1,mouseNum);
        for mouse = 1:mouseNum
            [r,~] = find(~isnan(timeDistArray{mouse}(:,1)));
            clustDistsAndAxon{mouse}(:,1) = timeDistArray{mouse}(r,2); 
            clustDistsAndAxon{mouse}(:,2) = timeDistArray{mouse}(r,3); 
            % identify what BBB plumes are close (<= 10 microns) or far (>
            % 10 microns) from their axon 
            if distQ == 0
                % the below locs organize the cluster by axon 
                closeClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) <= 10; 
                farClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) > 10;               
            elseif distQ == 1
                % specify what distance range you want to look at specifically 
                if mouse == 1 
                    distRange = input('What is the range of distances (in microns) that you specifically want to see? Input [min,max]. ');
                end 
                % the below locs organize the cluster by axon 
                closeClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) >= distRange(1) & clustDistsAndAxon{mouse}(:,1) <= distRange(2); 
                farClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) < distRange(1) | clustDistsAndAxon{mouse}(:,1) > distRange(2);
            end  
            data = (avClocFrame{mouse}/FPS{mouse})-windSize/2; % converts frame to time in sec for comparison across mice
            % reshape avClocFrame so clusters are in order of axons 
            for ccell = 1:size(avClocFrame{mouse},1)
                if ccell == 1 
                    reshpdAvClocFrame{mouse} =  data(ccell,~isnan(data(ccell,:)));
                elseif ccell > 1 
                    len = length(reshpdAvClocFrame{mouse});
                    reshpdAvClocFrame{mouse}(len+1:len+sum(~isnan(avClocFrame{mouse}(ccell,:)))) =  data(ccell,~isnan(avClocFrame{mouse}(ccell,:))) ;
                end 
            end 
            % use reshpdAvClocFrame to get the loc of clusters < 0 and >= 0 sec
            beforeLoc{mouse} = reshpdAvClocFrame{mouse} < 0;
            afterLoc{mouse} = reshpdAvClocFrame{mouse} >= 0;
            % identify close vs far clusters that come before and after  
            closeBeforeClustLocs{mouse} = (closeClustLoc{mouse}'+beforeLoc{mouse}) == 2;
            farBeforeClustLocs{mouse} = (farClustLoc{mouse}'+beforeLoc{mouse}) == 2;
            closeAfterClustLocs{mouse} = (closeClustLoc{mouse}'+afterLoc{mouse}) == 2;
            farAfterClustLocs{mouse} = (farClustLoc{mouse}'+afterLoc{mouse}) == 2; 
            avClocFrameCloseBefore{mouse} =  reshpdAvClocFrame{mouse}(closeBeforeClustLocs{mouse});
            avClocFrameCloseAfter{mouse} =  reshpdAvClocFrame{mouse}(closeAfterClustLocs{mouse});
            avClocFrameFarBefore{mouse} =  reshpdAvClocFrame{mouse}(farBeforeClustLocs{mouse});
            avClocFrameFarAfter{mouse} =  reshpdAvClocFrame{mouse}(farAfterClustLocs{mouse});            
        end
    elseif distQ2 == 2 % group data by BBB plume distance from vessel 
       closeClustLocPerAxon = cell(1,mouseNum);
        farClustLocPerAxon = cell(1,mouseNum);
        resortedAvClocFrame = cell(1,mouseNum);
        for mouse = 1:mouseNum
            if isempty(timeCOVdistArray{mouse}) == 0 
                [r,~] = find(~isnan(timeCOVdistArray{mouse}(:,1)));
                clustDistsAndAxon{mouse}(:,1) = timeCOVdistArray{mouse}(r,2); 
                % clustDistsAndAxon{mouse}(:,2) = timeCOVdistArray{mouse}(r,3); 
                % identify what BBB plumes are close (<= 10 microns) or far (>
                % 10 microns) from their axon 
                if distQ == 0
                    % the below locs organize the cluster by axon 
                    closeClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) <= 10; 
                    farClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) > 10;               
                elseif distQ == 1
                    % specify what distance range you want to look at specifically 
                    if mouse == 1 
                        distRange = input('What is the range of distances (in microns) that you specifically want to see? Input [min,max]. ');
                    end 
                    % the below locs organize the cluster by axon 
                    closeClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) >= distRange(1) & clustDistsAndAxon{mouse}(:,1) <= distRange(2); 
                    farClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) < distRange(1) | clustDistsAndAxon{mouse}(:,1) > distRange(2);
                end  
                data = (avClocFrame{mouse}/FPS{mouse})-windSize/2; % converts frame to time in sec for comparison across mice
                % reshape avClocFrame so clusters are in order of axons 
                for ccell = 1:size(avClocFrame{mouse},1)
                    if ccell == 1 
                        reshpdAvClocFrame{mouse} =  data(ccell,~isnan(data(ccell,:)));
                    elseif ccell > 1 
                        len = length(reshpdAvClocFrame{mouse});
                        reshpdAvClocFrame{mouse}(len+1:len+sum(~isnan(avClocFrame{mouse}(ccell,:)))) =  data(ccell,~isnan(avClocFrame{mouse}(ccell,:))) ;
                    end 
                end 
                % use reshpdAvClocFrame to get the loc of clusters < 0 and >= 0 sec
                beforeLoc{mouse} = reshpdAvClocFrame{mouse} < 0;
                afterLoc{mouse} = reshpdAvClocFrame{mouse} >= 0;
                % identify close vs far clusters that come before and after  
                closeBeforeClustLocs{mouse} = (closeClustLoc{mouse}'+beforeLoc{mouse}) == 2;
                farBeforeClustLocs{mouse} = (farClustLoc{mouse}'+beforeLoc{mouse}) == 2;
                closeAfterClustLocs{mouse} = (closeClustLoc{mouse}'+afterLoc{mouse}) == 2;
                farAfterClustLocs{mouse} = (farClustLoc{mouse}'+afterLoc{mouse}) == 2; 
                avClocFrameCloseBefore{mouse} =  reshpdAvClocFrame{mouse}(closeBeforeClustLocs{mouse});
                avClocFrameCloseAfter{mouse} =  reshpdAvClocFrame{mouse}(closeAfterClustLocs{mouse});
                avClocFrameFarBefore{mouse} =  reshpdAvClocFrame{mouse}(farBeforeClustLocs{mouse});
                avClocFrameFarAfter{mouse} =  reshpdAvClocFrame{mouse}(farAfterClustLocs{mouse});     
            end 
        end
    elseif distQ2 == 3 % group data by BBB plume origin distance from axon
        closeClustLocPerAxon = cell(1,mouseNum);
        farClustLocPerAxon = cell(1,mouseNum);
        resortedAvClocFrame = cell(1,mouseNum);
        for mouse = 1:mouseNum
            [r,~] = find(~isnan(timeODistArray{mouse}(:,1)));
            clustDistsAndAxon{mouse}(:,1) = timeODistArray{mouse}(r,2); 
            clustDistsAndAxon{mouse}(:,2) = timeODistArray{mouse}(r,3); 
            % identify what BBB plumes are close (<= 10 microns) or far (>
            % 10 microns) from their axon 
            if distQ == 0
                % the below locs organize the cluster by axon 
                closeClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) <= 10; 
                farClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) > 10;               
            elseif distQ == 1
                % specify what distance range you want to look at specifically 
                if mouse == 1 
                    distRange = input('What is the range of distances (in microns) that you specifically want to see? Input [min,max]. ');
                end 
                % the below locs organize the cluster by axon 
                closeClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) >= distRange(1) & clustDistsAndAxon{mouse}(:,1) <= distRange(2); 
                farClustLoc{mouse} = clustDistsAndAxon{mouse}(:,1) < distRange(1) | clustDistsAndAxon{mouse}(:,1) > distRange(2);
            end  
            data = (avClocFrame{mouse}/FPS{mouse})-windSize/2; % converts frame to time in sec for comparison across mice
            % reshape avClocFrame so clusters are in order of axons 
            for ccell = 1:size(avClocFrame{mouse},1)
                if ccell == 1 
                    reshpdAvClocFrame{mouse} =  data(ccell,~isnan(data(ccell,:)));
                elseif ccell > 1 
                    len = length(reshpdAvClocFrame{mouse});
                    reshpdAvClocFrame{mouse}(len+1:len+sum(~isnan(avClocFrame{mouse}(ccell,:)))) =  data(ccell,~isnan(avClocFrame{mouse}(ccell,:))) ;
                end 
            end 
            % use reshpdAvClocFrame to get the loc of clusters < 0 and >= 0 sec
            beforeLoc{mouse} = reshpdAvClocFrame{mouse} < 0;
            afterLoc{mouse} = reshpdAvClocFrame{mouse} >= 0;
            % identify close vs far clusters that come before and after  
            closeBeforeClustLocs{mouse} = (closeClustLoc{mouse}'+beforeLoc{mouse}) == 2;
            farBeforeClustLocs{mouse} = (farClustLoc{mouse}'+beforeLoc{mouse}) == 2;
            closeAfterClustLocs{mouse} = (closeClustLoc{mouse}'+afterLoc{mouse}) == 2;
            farAfterClustLocs{mouse} = (farClustLoc{mouse}'+afterLoc{mouse}) == 2; 
            avClocFrameCloseBefore{mouse} =  reshpdAvClocFrame{mouse}(closeBeforeClustLocs{mouse});
            avClocFrameCloseAfter{mouse} =  reshpdAvClocFrame{mouse}(closeAfterClustLocs{mouse});
            avClocFrameFarBefore{mouse} =  reshpdAvClocFrame{mouse}(farBeforeClustLocs{mouse});
            avClocFrameFarAfter{mouse} =  reshpdAvClocFrame{mouse}(farAfterClustLocs{mouse});            
        end   
    end 
    % sort data 
    binClustTSsizeData = cell(1,2);
    binClustTSpixAmpData = cell(1,2);
    binClocFrame = cell(1,2);
    for bin = 1:2
        for loc = 1:2 
            for mouse = 1:mouseNum
                if mouse == 1 
                    if loc == 1 % sort close axons/clusters 
                        if bin == 1 % sort pre event/spike clusters
                            % sort data 
                            binClustTSsizeData{bin}{loc} = downAllAxonsClustSizeTS{mouse}(closeBeforeClustLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc} = downAllAxonsClustAmpTS{mouse}(closeBeforeClustLocs{mouse},:);
                            binClocFrame{bin}{loc} = reshape(avClocFrameCloseBefore{mouse},1,size(avClocFrameCloseBefore{mouse},1)*size(avClocFrameCloseBefore{mouse},2));
                        elseif bin == 2 % sort post event/spike clusters  
                            % sort data 
                            binClustTSsizeData{bin}{loc} = downAllAxonsClustSizeTS{mouse}(closeAfterClustLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc} = downAllAxonsClustAmpTS{mouse}(closeAfterClustLocs{mouse},:);
                            binClocFrame{bin}{loc} = reshape(avClocFrameCloseAfter{mouse},1,size(avClocFrameCloseAfter{mouse},1)*size(avClocFrameCloseAfter{mouse},2));
                        end 
                    elseif loc == 2 % sort far axons/clusters
                        if bin == 1 % sort pre event/spike clusters
                            % sort data 
                            binClustTSsizeData{bin}{loc} = downAllAxonsClustSizeTS{mouse}(farBeforeClustLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc} = downAllAxonsClustAmpTS{mouse}(farBeforeClustLocs{mouse},:);
                            binClocFrame{bin}{loc} = reshape(avClocFrameFarBefore{mouse},1,size(avClocFrameFarBefore{mouse},1)*size(avClocFrameFarBefore{mouse},2));
                        elseif bin == 2 % sort post event/spike clusters                                
                            % sort data 
                            binClustTSsizeData{bin}{loc} = downAllAxonsClustSizeTS{mouse}(farAfterClustLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc} = downAllAxonsClustAmpTS{mouse}(farAfterClustLocs{mouse},:);
                            binClocFrame{bin}{loc} = reshape(avClocFrameFarAfter{mouse},1,size(avClocFrameFarAfter{mouse},1)*size(avClocFrameFarAfter{mouse},2));
                        end 
                    end 
                elseif mouse > 1
                    if loc == 1 % sort close axons/clusters
                        if bin == 1 % sort pre event/spike clusters                                 
                            len1 = size(binClustTSsizeData{bin}{loc},1);
                            len2 = nnz(closeBeforeClustLocs{mouse});
                            len3 = length(binClocFrame{bin}{loc});
                            % sort data 
                            binClustTSsizeData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustSizeTS{mouse}(closeBeforeClustLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustAmpTS{mouse}(closeBeforeClustLocs{mouse},:);
                            binClocFrame{bin}{loc}(len3+1:len3+size(avClocFrameCloseBefore{mouse},1)*size(avClocFrameCloseBefore{mouse},2)) = reshape(avClocFrameCloseBefore{mouse},1,size(avClocFrameCloseBefore{mouse},1)*size(avClocFrameCloseBefore{mouse},2));
                        elseif bin == 2 % sort post event/spike clusters                                 
                            len1 = size(binClustTSsizeData{bin}{loc},1);
                            len2 = nnz(closeAfterClustLocs{mouse});
                            len3 = length(binClocFrame{bin}{loc});
                            % sort data 
                            binClustTSsizeData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustSizeTS{mouse}(closeAfterClustLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustAmpTS{mouse}(closeAfterClustLocs{mouse},:);
                            binClocFrame{bin}{loc}(len3+1:len3+size(avClocFrameCloseAfter{mouse},1)*size(avClocFrameCloseAfter{mouse},2)) = reshape(avClocFrameCloseAfter{mouse},1,size(avClocFrameCloseAfter{mouse},1)*size(avClocFrameCloseAfter{mouse},2));
                        end 
                    elseif loc == 2 % sort far axons/clusters
                        if bin == 1 % sort pre event/spike clusters                                  
                            len1 = size(binClustTSsizeData{bin}{loc},1);
                            len2 = nnz(farBeforeClustLocs{mouse});
                            len3 = length(binClocFrame{bin}{loc});
                            % sort data 
                            binClustTSsizeData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustSizeTS{mouse}(farBeforeClustLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustAmpTS{mouse}(farBeforeClustLocs{mouse},:);
                            binClocFrame{bin}{loc}(len3+1:len3+size(avClocFrameFarBefore{mouse},1)*size(avClocFrameFarBefore{mouse},2)) =  reshape(avClocFrameFarBefore{mouse},1,size(avClocFrameFarBefore{mouse},1)*size(avClocFrameFarBefore{mouse},2));
                        elseif bin == 2 % sort post event/spike clusters                                 
                            len1 = size(binClustTSsizeData{bin}{loc},1);
                            len2 = nnz(farAfterClustLocs{mouse});
                            len3 = length(binClocFrame{bin}{loc});
                            % sort data 
                            binClustTSsizeData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustSizeTS{mouse}(farAfterClustLocs{mouse},:);
                            binClustTSpixAmpData{bin}{loc}(len1+1:len1+len2,:) = downAllAxonsClustAmpTS{mouse}(farAfterClustLocs{mouse},:);
                            binClocFrame{bin}{loc}(len3+1:len3+size(avClocFrameFarAfter{mouse},1)*size(avClocFrameFarAfter{mouse},2)) = reshape(avClocFrameFarAfter{mouse},1,size(avClocFrameFarAfter{mouse},1)*size(avClocFrameFarAfter{mouse},2));
                        end 
                    end 
                end 
            end 
        end 
    end 
end 
clustSizeQ = input('Input 1 to set a size threshold for plotting TS data grouped by axon type and distance. Input 0 otherwise. ');   
if clustSizeQ == 1
    clustSizeThresh = input('What is the cluster size threshold? ');
    % remove all cluster data that does not reach the size threshold 
    binClustTSsizeDataHigh = cell(1,2);
    binClustTSsizeDataLow = cell(1,2);
    binClustTSpixAmpDataHigh = cell(1,2);
    binClustTSpixAmpDataLow = cell(1,2);
    for bin = 1:length(binClustTSsizeData)
        for loc = 1:2 % close axons, far axons
            % find the clusters that meet or exceed the threshold 
            highClusts = any(binClustTSsizeData{bin}{loc} >= clustSizeThresh,2);
            % create data arrays for high and low clusts 
            binClustTSsizeDataHigh{bin}{loc} = binClustTSsizeData{bin}{loc}(highClusts,:);
            binClustTSsizeDataLow{bin}{loc} = binClustTSsizeData{bin}{loc}(~highClusts,:);
            binClustTSpixAmpDataHigh{bin}{loc} = binClustTSpixAmpData{bin}{loc}(highClusts,:);
            binClustTSpixAmpDataLow{bin}{loc} = binClustTSpixAmpData{bin}{loc}(~highClusts,:);
        end 
    end 
    % sort cluster start frame data by size threshold
    binClocFrameHigh = cell(1,3);
    binClocFrameLow = cell(1,3);
    for bin = 1:length(binClustTSsizeData)
        for loc = 1:2 % close axons, far axons  
            % find the clusters that meet or exceed the threshold 
            highClusts = any(binClustTSsizeData{bin}{loc} >= clustSizeThresh,2);
            % create data arrays for high and low clusts 
            cLocs = find(~isnan(binClocFrame{bin}{loc})); 
            binClocFrameHigh{bin}{loc} = binClocFrame{bin}{loc}(cLocs(highClusts));
            binClocFrameLow{bin}{loc} = binClocFrame{bin}{loc}(cLocs(~highClusts));
        end 
    end 
end 
if clustSizeQ == 0
    if aTypeQ == 0 % sort data by axon type 
        % plot pie chart showing proportion of close vs far listeners, controllers,
        % and bothers there are 
        count = 1;
        axonTypePieData = nan(1);
        % resort data for the pie chart 
        for bin = 1:3 % listener, controller, both
            for loc = 1:2 % close axons, far axons 
                axonTypePieData(count) = size(binClustTSsizeData{bin}{loc},1);
                count = count + 1;
            end 
        end 
    
        % create pie chart for pre, post, and evenly split axons separated by
        % distance from vessel  
        figure;
        p = pie(axonTypePieData);
        customColors = [0 0.4470 0.7410; 0.35 0.7970 1; 0.8500 0.3250 0.0980; 1 0.7750 0.5480; 0.4250 0.386 0.4195; 0.7750 0.736 0.7695];
        colormap(customColors)
        if distQ == 0
            axonClusterTypeLabels = ["Close Listener","Far Listener","Close Controller","Far Controller","Close Both","Far Both"];
        elseif distQ == 1 
            axonClusterTypeLabels = ["In Range Listener","Out of Range Listener","In Range Controller","Out of Range Controller","In Range Both","Out of Range Both"];
        end        
        legend(axonClusterTypeLabels)
        if axonTypeQ == 0 % probabilistically sort axon type
            if distQ2 == 0 % group data by axon distance from vessel 
                if distQ == 0
                    title({'Proportion of BBB Plumes by Axon Type';'Close Axons <= 10 microns from Vessel';'Probabilistic Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) Axons from Vessel',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;'Probabilistic Axon Types'})
                end
            elseif distQ2 == 1 % group data by BBB plume distance from axon 
                if distQ == 0
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plumes <= 10 microns from Axon';'Probabilistic Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plumes from Axon',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;'Probabilistic Axon Types'})
                end 
            elseif distQ2 == 2 % group data by BBB plume origin distance from vessel 
                if distQ == 0
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plume Origins <= 10 microns from Vessel';'Probabilistic Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Vessel',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;'Probabilistic Axon Types'})
                end  
            elseif distQ2 == 3 % group data by BBB plume origin distance from axon 
                if distQ == 0
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plume Origins <= 10 microns from Axon';'Probabilistic Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Axon',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;'Probabilistic Axon Types'})
                end                 
            end 
        elseif axonTypeQ == 1 % do strict absolute axon type sorting
            if distQ2 == 0 % group data by axon distance from vessel 
                if distQ == 0
                    title({'Proportion of BBB Plumes by Axon Type';'Close Axons <= 10 microns from Vessel';'Absolute Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) Axons from Vessel',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;'Absolute Axon Types'})
                end
            elseif distQ2 == 1 % group data by BBB plume distance from axon 
                if distQ == 0
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plumes <= 10 microns from Axon';'Absolute Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plumes from Axon',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;'Absolute Axon Types'})
                end 
            elseif distQ2 == 2 % group data by BBB plume origin distance from vessel 
                if distQ == 0
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plume Origins <= 10 microns from Vessel';'Absolute Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Vessel',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;'Absolute Axon Types'})
                end   
            elseif distQ2 == 3 % group data by BBB plume origin distance from axon
                if distQ == 0
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plume Origins <= 10 microns from Axon';'Absolute Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plumes from Axon',distRange(1),distRange(2));
                    title({'Proportion of BBB Plume Origins by Axon Type';rangeLabel;'Absolute Axon Types'})
                end 
            end 
        end 
        ax=gca; ax.FontSize = 12;
        t1 = p(2); t2 = p(4); t3 = p(6); t4 = p(8); t5 = p(10); t6 = p(12);
        t1.FontSize = 15; t2.FontSize = 15; t3.FontSize = 15; t4.FontSize = 15; t5.FontSize = 15; t6.FontSize = 15;

        % create pie chart showing number of axons that are mostly pre, mostly
        % post, and evenly split
        if axonTypeQ == 0 % probabilistically sort axon type
            allAxonTypes = sum(axonTypes,1);
            reSortedAllAxonTypes(1) = allAxonTypes(1); reSortedAllAxonTypes(2) = allAxonTypes(3); reSortedAllAxonTypes(3) = allAxonTypes(2);
            figure;
            p = pie(reSortedAllAxonTypes);
            colormap([0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.4250 0.386 0.4195])
            legend('Listener','Controller','Both')
            if axonTypeQ == 0 % probabilistically sort axon type
                title({'Axon Type';'Probabilistic Axon Types'})
            elseif axonTypeQ == 1 % do strict absolute axon type sorting
                title({'Axon Type';'Absolute Axon Types'})
            end         
            ax=gca; ax.FontSize = 12;
            t1 = p(2); t2 = p(4); t3 = p(6);
            t1.FontSize = 15; t2.FontSize = 15; t3.FontSize = 15;
        elseif axonTypeQ == 1 % do strict absolute axon type sorting
            for mouse = 1:mouseNum
                if mouse == 1 
                    reSortedAllAxonTypes(1) = length(listenerAxons{mouse});
                    reSortedAllAxonTypes(2) = length(controllerAxons{mouse});
                    reSortedAllAxonTypes(3) = length(bothAxons{mouse});
                elseif mouse > 1 
                    len1 = reSortedAllAxonTypes(1);
                    reSortedAllAxonTypes(1) = len1 + length(listenerAxons{mouse});
                    len2 = reSortedAllAxonTypes(2);
                    reSortedAllAxonTypes(2) = len2 + length(controllerAxons{mouse});
                    len3 = reSortedAllAxonTypes(3);
                    reSortedAllAxonTypes(3) = len3 + length(bothAxons{mouse});
                end 
            end 
            figure;
            p = pie(reSortedAllAxonTypes);
            colormap([0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.4250 0.386 0.4195])
            legend('Listener','Controller','Both')
            if axonTypeQ == 0 % probabilistically sort axon type
                title({'Axon Type';'Probabilistic Axon Types'})
            elseif axonTypeQ == 1 % do strict absolute axon type sorting
                title({'Axon Type';'Absolute Axon Types'})
            end         
            ax=gca; ax.FontSize = 12;
            t1 = p(2); t2 = p(4); t3 = p(6);
            t1.FontSize = 15; t2.FontSize = 15; t3.FontSize = 15;
        end 

    elseif aTypeQ == 1 % sort data by cluster timing before or after 0 sec 
        % plot pie chart showing proportion of pre vs post clusters
        % organized by distance 
        count = 1;
        axonTypePieData = nan(1);
        axonTypePieDataBeforeVsAfter = nan(1);
        % resort data for the pie chart 
        for bin = 1:length(binClustTSsizeData)
            for loc = 1:2 % close axons, far axons 
                axonTypePieData(count) = size(binClustTSsizeData{bin}{loc},1);
                count = count + 1;                  
            end 
            axonTypePieDataBeforeVsAfter(bin) = size(binClustTSsizeData{bin}{1},1) + size(binClustTSsizeData{bin}{2},1);
        end 
        figure;
        p = pie(axonTypePieData);
        customColors = [1 0 0;1 0.7 0.7;0 0.5 0.5;0 1 1];
        colormap(customColors)
        if distQ == 0
            axonClusterTypeLabels = ["Close Pre-Spike Clusters","Far Pre-Spike Clusters","Close Post-Spike Clusters","Far Post-Spike Clusters"];
        elseif distQ == 1 
            axonClusterTypeLabels = ["In Range Pre-Spike Clusters","Out of Range Pre-Spike Clusters","In Range Post-Spike Clusters","Out of Range Post-Spike Clusters"];
        end        
        legend(axonClusterTypeLabels)
        if exist('axonTypeQ','var') == 1 
            if axonTypeQ == 0 % probabilistically sort axon type
                if distQ2 == 0 % group data by axon distance from vessel 
                    if distQ == 0
                        title({'Proportion of BBB Plumes by Plume Timing';'Close Axons <= 10 microns from Vessel';'Probabilistic Axon Types'})
                    elseif distQ == 1 
                        rangeLabel = sprintf('In Range (%d-%d microns) Axons from Vessel',distRange(1),distRange(2));
                        title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;'Probabilistic Axon Types'})
                    end
                elseif distQ2 == 1 % group data by BBB plume distance from axon 
                    if distQ == 0
                        title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plumes <= 10 microns from Axon';'Probabilistic Axon Types'})
                    elseif distQ == 1 
                        rangeLabel = sprintf('In Range (%d-%d microns) BBB Plumes from Axon',distRange(1),distRange(2));
                        title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;'Probabilistic Axon Types'})
                    end    
                elseif distQ2 == 2 % group data by BBB plume origin distance from vessel 
                    if distQ == 0
                        title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plume Origins <= 10 microns from Vessel';'Probabilistic Axon Types'})
                    elseif distQ == 1 
                        rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Vessel',distRange(1),distRange(2));
                        title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;'Probabilistic Axon Types'})
                    end      
                elseif distQ2 == 3 % group data by BBB plume origin distance from axon 
                    if distQ == 0
                        title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plume Origins <= 10 microns from Axon';'Probabilistic Axon Types'})
                    elseif distQ == 1 
                        rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Axon',distRange(1),distRange(2));
                        title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;'Probabilistic Axon Types'})
                    end  
                end 
            elseif axonTypeQ == 1 % do strict absolute axon type sorting
                if distQ2 == 0 % group data by axon distance from vessel 
                    if distQ == 0
                        title({'Proportion of BBB Plumes by Plume Timing';'Close Axons <= 10 microns from Vessel';'Absolute Axon Types'})
                    elseif distQ == 1 
                        rangeLabel = sprintf('In Range (%d-%d microns) Axons from Vessel',distRange(1),distRange(2));
                        title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;'Absolute Axon Types'})
                    end
                elseif distQ2 == 1 % group data by BBB plume distance from axon 
                    if distQ == 0
                        title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plumes <= 10 microns from Axon';'Absolute Axon Types'})
                    elseif distQ == 1 
                        rangeLabel = sprintf('In Range (%d-%d microns) BBB Plumes from Axon',distRange(1),distRange(2));
                        title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;'Absolute Axon Types'})
                    end    
                elseif distQ2 == 2 % group data by BBB plume origin distance from vessel 
                    if distQ == 0
                        title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plume Origins <= 10 microns from Vessel';'Absolute Axon Types'})
                    elseif distQ == 1 
                        rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Vessel',distRange(1),distRange(2));
                        title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;'Absolute Axon Types'})
                    end 
                elseif distQ2 == 3 % group data by BBB plume origin distance from axon
                    if distQ == 0
                        title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plume Origins <= 10 microns from Axon';'Absolute Axon Types'})
                    elseif distQ == 1 
                        rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Axon',distRange(1),distRange(2));
                        title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;'Absolute Axon Types'})
                    end                  
                end 
            end 
        elseif exist('axonTypeQ','var') == 0
            if distQ == 0
                title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plume Origins <= 10 microns from Vessel';'Probabilistic Axon Types'})
            elseif distQ == 1 
                rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Vessel',distRange(1),distRange(2));
                title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;'Probabilistic Axon Types'})
            end      
        end 
        ax=gca; ax.FontSize = 12;
        t1 = p(2); t2 = p(4); t3 = p(6); t4 = p(8);
        t1.FontSize = 15; t2.FontSize = 15; t3.FontSize = 15; t4.FontSize = 15;         

        % create pie chart showing number of clusters that are before
        % or after 0 sec (this figure has already been made, but good
        % to double check) 
        figure;
        p = pie(axonTypePieDataBeforeVsAfter);
        clr = hsv(2);
        colormap(clr)
        legend('Pre-Spike BBB Plumes','Post-Spike BBB Plumes')
        if exist('axonTypeQ','var') == 1 
            if axonTypeQ == 0 % probabilistically sort axon type
                title({'Probabilistic Axon Types'})
            elseif axonTypeQ == 1 % do strict absolute axon type sorting
                title({'Absolute Axon Types'})
            end 
        end 

        ax=gca; ax.FontSize = 12;
        t1 = p(2); t2 = p(4);
        t1.FontSize = 15; t2.FontSize = 15; 
    end 
elseif clustSizeQ == 1  
    if aTypeQ == 0 % sort data by axon type 
        % plot pie chart showing proportion of close vs far listeners, controllers,
        % and bothers there are 
        count = 1;
        axonTypePieDataHigh = nan(1);
        axonTypePieDataLow = nan(1);
        % resort data for the pie chart 
        for bin = 1:3 % listener, controller, both
            for loc = 1:2 % close axons, far axons 
                axonTypePieDataHigh(count) = size(binClustTSsizeDataHigh{bin}{loc},1);
                axonTypePieDataLow(count) = size(binClustTSsizeDataLow{bin}{loc},1);
                count = count + 1;
            end 
        end 

        % create pie chart for pre, post, and evenly split axons separated by
        % distance from vessel for plumes that exceed the size threshold
        % and those that do not 
        figure;
        p = pie(axonTypePieDataHigh);
        customColors = [0 0.4470 0.7410; 0.35 0.7970 1; 0.8500 0.3250 0.0980; 1 0.7750 0.5480; 0.4250 0.386 0.4195; 0.7750 0.736 0.7695];
        colormap(customColors)  
        if distQ == 0
            axonClusterTypeLabels = ["Close Listener","Far Listener","Close Controller","Far Controller","Close Both","Far Both"];
        elseif distQ == 1 
            axonClusterTypeLabels = ["In Range Listener","Out of Range Listener","In Range Controller","Out of Range Controller","In Range Both","Out of Range Both"];
        end 
        legend(axonClusterTypeLabels)
        if axonTypeQ == 0 % probabilistically sort axon type
            if distQ2 == 0 % group data by axon distance from vessel 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';'Close Axons <= 10 microns from Vessel';titleLabel;'Probabilistic Axon Types'})
                elseif distQ == 1 
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    rangeLabel = sprintf('In Range (%d-%d microns) Axons from Vessel',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;titleLabel;'Probabilistic Axon Types'})
                end            
            elseif distQ2 == 1 % group data by BBB plume distance from axon 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plumes <= 10 microns from Axon';titleLabel;'Probabilistic Axon Types'})
                elseif distQ == 1 
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plumes from Axon',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;titleLabel;'Probabilistic Axon Types'})
                end  
            elseif distQ2 == 2 % group data by BBB plume origin distance from vessel 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plume Origins <= 10 microns from Vessel';titleLabel;'Probabilistic Axon Types'})
                elseif distQ == 1 
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Vessel',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;titleLabel;'Probabilistic Axon Types'})
                end     
            elseif distQ2 == 3 % group data by BBB plume origin distance from axon
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plume Origins <= 10 microns from Axon';titleLabel;'Probabilistic Axon Types'})
                elseif distQ == 1 
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Axon',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;titleLabel;'Probabilistic Axon Types'})
                end 
            end 
        elseif axonTypeQ == 1 % do strict absolute axon type sorting
            if distQ2 == 0 % group data by axon distance from vessel 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';'Close Axons <= 10 microns from Vessel';titleLabel;'Absolute Axon Types'})
                elseif distQ == 1 
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    rangeLabel = sprintf('In Range (%d-%d microns) Axons from Vessel',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;titleLabel;'Absolute Axon Types'})
                end            
            elseif distQ2 == 1 % group data by BBB plume distance from axon 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plumes <= 10 microns from Axon';titleLabel;'Absolute Axon Types'})
                elseif distQ == 1 
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plumes from Axon',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;titleLabel;'Absolute Axon Types'})
                end  
            elseif distQ2 == 2 % group data by BBB plume origin distance from vessel 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plume Origins <= 10 microns from Vessel';titleLabel;'Absolute Axon Types'})
                elseif distQ == 1 
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Vessel',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;titleLabel;'Absolute Axon Types'})
                end    
            elseif distQ2 == 3 % group data by BBB plume origin distance from axon 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plume Origins <= 10 microns from Axon';titleLabel;'Absolute Axon Types'})
                elseif distQ == 1 
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Axon',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;titleLabel;'Absolute Axon Types'})
                end                  
            end 
        end 
        ax=gca; ax.FontSize = 12;
        t1 = p(2); t2 = p(4); t3 = p(6); t4 = p(8); t5 = p(10); t6 = p(12);
        t1.FontSize = 15; t2.FontSize = 15; t3.FontSize = 15; t4.FontSize = 15; t5.FontSize = 15; t6.FontSize = 15;

        figure;
        p = pie(axonTypePieDataLow);
        customColors = [0 0.4470 0.7410; 0.35 0.7970 1; 0.8500 0.3250 0.0980; 1 0.7750 0.5480; 0.4250 0.386 0.4195; 0.7750 0.736 0.7695];
        colormap(customColors)
        if distQ == 0
            axonClusterTypeLabels = ["Close Listener","Far Listener","Close Controller","Far Controller","Close Both","Far Both"];
        elseif distQ == 1 
            axonClusterTypeLabels = ["In Range Listener","Out of Range Listener","In Range Controller","Out of Range Controller","In Range Both","Out of Range Both"];
        end 
        legend(axonClusterTypeLabels)
        if axonTypeQ == 0 % probabilistically sort axon type
            if distQ2 == 0 % group data by axon distance from vessel \
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';'Close Axons <= 10 microns from Vessel';titleLabel;'Probabilistic Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) Axons from Vessel',distRange(1),distRange(2));
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;titleLabel;'Probabilistic Axon Types'})
                end
            elseif distQ2 == 1 % group data by BBB plume distance from axon 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plumes <= 10 microns from Axon';titleLabel;'Probabilistic Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plumes from Axon',distRange(1),distRange(2));
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;titleLabel;'Probabilistic Axon Types'})
                end            
            elseif distQ2 == 2 % group data by BBB plume origins distance from vessel 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plume Origins <= 10 microns from Vessel';titleLabel;'Probabilistic Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Vessel',distRange(1),distRange(2));
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;titleLabel;'Probabilistic Axon Types'})
                end      
            elseif distQ2 == 3 % group data by BBB plume origin distance from axon
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plume Origins <= 10 microns from Axon';titleLabel;'Probabilistic Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Axon',distRange(1),distRange(2));
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;titleLabel;'Probabilistic Axon Types'})
                end                   
            end 
        elseif axonTypeQ == 1 % do strict absolute axon type sorting
            if distQ2 == 0 % group data by axon distance from vessel 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';'Close Axons <= 10 microns from Vessel';titleLabel;'Absolute Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) Axons from Vessel',distRange(1),distRange(2));
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;titleLabel;'Absolute Axon Types'})
                end
            elseif distQ2 == 1 % group data by BBB plume distance from axon 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plumes <= 10 microns from Axon';titleLabel;'Absolute Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plumes from Axon',distRange(1),distRange(2));
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;titleLabel;'Absolute Axon Types'})
                end            
            elseif distQ2 == 2 % group data by BBB plume origin distance from vessel 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plume Origins <= 10 microns from Vessel';titleLabel;'Absolute Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Vessel',distRange(1),distRange(2));
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;titleLabel;'Absolute Axon Types'})
                end   
            elseif distQ2 == 3 % group data by BBB plume origin distance from axon
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';'Close BBB Plume Origins <= 10 microns from Axon';titleLabel;'Absolute Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Axon',distRange(1),distRange(2));
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Axon Type';rangeLabel;titleLabel;'Absolute Axon Types'})
                end  
            end 
        end 
        ax=gca; ax.FontSize = 12;
        t1 = p(2); t2 = p(4); t3 = p(6); t4 = p(8); t5 = p(10); t6 = p(12);
        t1.FontSize = 15; t2.FontSize = 15; t3.FontSize = 15; t4.FontSize = 15; t5.FontSize = 15; t6.FontSize = 15;
   elseif aTypeQ == 1 % sort data by cluster timing before or after 0 sec     
        % plot pie chart showing proportion of pre vs post 0 sec clusters there are  
        count = 1;
        axonTypePieDataHigh = nan(1);
        axonTypePieDataLow = nan(1);
        % resort data for the pie chart 
        for bin = 1:length(binClustTSsizeData)
            for loc = 1:2 % close axons, far axons 
                axonTypePieDataHigh(count) = size(binClustTSsizeDataHigh{bin}{loc},1);
                axonTypePieDataLow(count) = size(binClustTSsizeDataLow{bin}{loc},1);
                count = count + 1;
            end 
        end 

        % create pie chart for pre, post, and evenly split axons separated by
        % distance from vessel for plumes that exceed the size threshold
        % and those that do not 
        figure;
        p = pie(axonTypePieDataHigh);
        customColors = [1 0 0;1 0.7 0.7;0 0.5 0.5;0 1 1];
        colormap(customColors)
        if distQ == 0
            axonClusterTypeLabels = ["Close Pre-Spike Clusters","Far Pre-Spike Clusters","Close Post-Spike Clusters","Far Post-Spike Clusters"];
        elseif distQ == 1 
            axonClusterTypeLabels = ["In Range Pre-Spike Clusters","Out of Range Pre-Spike Clusters","In Range Post-Spike Clusters","Out of Range Post-Spike Clusters"];
        end    
        legend(axonClusterTypeLabels)
        if axonTypeQ == 0 % probabilistically sort axon type
            if distQ2 == 0 % group data by axon distance from vessel 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';'Close Axons <= 10 microns from Vessel';titleLabel;'Probabilistic Axon Types'})
                elseif distQ == 1 
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    rangeLabel = sprintf('In Range (%d-%d microns) Axons from Vessel',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;titleLabel;'Probabilistic Axon Types'})
                end            
            elseif distQ2 == 1 % group data by BBB plume distance from axon 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plumes <= 10 microns from Axon';titleLabel;'Probabilistic Axon Types'})
                elseif distQ == 1 
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plumes from Axon',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;titleLabel;'Probabilistic Axon Types'})
                end         
            elseif distQ2 == 2 % group data by BBB plume origin distance from vessel 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plume Origins <= 10 microns from Vessel';titleLabel;'Probabilistic Axon Types'})
                elseif distQ == 1 
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Vessel',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;titleLabel;'Probabilistic Axon Types'})
                end  
            elseif distQ2 == 3 % group data by BBB plume origin distance from axon 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plume Origins <= 10 microns from Axon';titleLabel;'Probabilistic Axon Types'})
                elseif distQ == 1 
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Axon',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;titleLabel;'Probabilistic Axon Types'})
                end                  
            end 
        elseif axonTypeQ == 1 % do strict absolute axon type sorting
            if distQ2 == 0 % group data by axon distance from vessel 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';'Close Axons <= 10 microns from Vessel';titleLabel;'Absolute Axon Types'})
                elseif distQ == 1 
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    rangeLabel = sprintf('In Range (%d-%d microns) Axons from Vessel',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;titleLabel;'Absolute Axon Types'})
                end            
            elseif distQ2 == 1 % group data by BBB plume distance from axon 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plumes <= 10 microns from Axon';titleLabel;'Absolute Axon Types'})
                elseif distQ == 1 
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plumes from Axon',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;titleLabel;'Absolute Axon Types'})
                end         
            elseif distQ2 == 2 % group data by BBB plume origin distance from vessel 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plume Origins <= 10 microns from Vessel';titleLabel;'Absolute Axon Types'})
                elseif distQ == 1 
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Vessel',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;titleLabel;'Absolute Axon Types'})
                end  
            elseif distQ2 == 3 % group data by BBB plume origin distance from axon 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plume Origins <= 10 microns from Axon';titleLabel;'Absolute Axon Types'})
                elseif distQ == 1 
                    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Axon',distRange(1),distRange(2));
                    title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;titleLabel;'Absolute Axon Types'})
                end                     
            end 
        end
        ax=gca; ax.FontSize = 12;
        t1 = p(2); t2 = p(4); t3 = p(6); t4 = p(8);
        t1.FontSize = 15; t2.FontSize = 15; t3.FontSize = 15; t4.FontSize = 15; 

        figure;
        p = pie(axonTypePieDataLow);
        customColors = [1 0 0;1 0.7 0.7;0 0.5 0.5;0 1 1];
        colormap(customColors)
        if distQ == 0
            axonClusterTypeLabels = ["Close Pre-Spike Clusters","Far Pre-Spike Clusters","Close Post-Spike Clusters","Far Post-Spike Clusters"];
        elseif distQ == 1 
            axonClusterTypeLabels = ["In Range Pre-Spike Clusters","Out of Range Pre-Spike Clusters","In Range Post-Spike Clusters","Out of Range Post-Spike Clusters"];
        end   
        legend(axonClusterTypeLabels)
        if axonTypeQ == 0 % probabilistically sort axon type
            if distQ2 == 0 % group data by axon distance from vessel 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';'Close Axons <= 10 microns from Vessel';titleLabel;'Probabilistic Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) Axons from Vessel',distRange(1),distRange(2));
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;titleLabel;'Probabilistic Axon Types'})
                end
            elseif distQ2 == 1 % group data by BBB plume distance from axon 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plumes <= 10 microns from Axon';titleLabel;'Probabilistic Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plumes from Axon',distRange(1),distRange(2));
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;titleLabel;'Probabilistic Axon Types'})
                end   
            elseif distQ2 == 2 % group data by BBB plume origin distance from vessel
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plume Origins <= 10 microns from Vessel';titleLabel;'Probabilistic Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Vessel',distRange(1),distRange(2));
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;titleLabel;'Probabilistic Axon Types'})
                end   
            elseif distQ2 == 3 % group data by BBB plume origin distance from axon 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plume Origins <= 10 microns from Axon';titleLabel;'Probabilistic Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Axon',distRange(1),distRange(2));
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;titleLabel;'Probabilistic Axon Types'})
                end   
            end 
        elseif axonTypeQ == 1 % do strict absolute axon type sorting
            if distQ2 == 0 % group data by axon distance from vessel \
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';'Close Axons <= 10 microns from Vessel';titleLabel;'Absolute Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) Axons from Vessel',distRange(1),distRange(2));
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;titleLabel;'Absolute Axon Types'})
                end
            elseif distQ2 == 1 % group data by BBB plume distance from axon 
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plumes <= 10 microns from Axon';titleLabel;'Absolute Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plumes from Axon',distRange(1),distRange(2));
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;titleLabel;'Absolute Axon Types'})
                end   
            elseif distQ2 == 2 % group data by BBB plume origin distance from vessel
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plume Origins <= 10 microns from Vessel';titleLabel;'Absolute Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Vessel',distRange(1),distRange(2));
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;titleLabel;'Absolute Axon Types'})
                end   
            elseif distQ2 == 3 % group data by BBB plume origin distance from axon
                if distQ == 0
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';'Close BBB Plume Origins <= 10 microns from Axon';titleLabel;'Absolute Axon Types'})
                elseif distQ == 1 
                    rangeLabel = sprintf('In Range (%d-%d microns) BBB Plume Origins from Axon',distRange(1),distRange(2));
                    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
                    title({'Proportion of BBB Plumes by Plume Timing';rangeLabel;titleLabel;'Absolute Axon Types'})
                end                  
            end 
        end 
        ax=gca; ax.FontSize = 12;
        t1 = p(2); t2 = p(4); t3 = p(6); t4 = p(8);
        t1.FontSize = 15; t2.FontSize = 15; t3.FontSize = 15; t4.FontSize = 15; 
   end 
end  
if clustSizeQ == 0
    clearvars binLabel
    % plot change in cluster size grouped by axon type and distance 
    count = 1 ;
    count2 = 1; 
    figure;
    ax=gca;
    hold all;
    for bin = 1:length(binClustTSsizeData)
        % determine bin labels 
        for loc = 1:2 % close axons, far axons
            for clust = 1:size(binClustTSsizeData{bin}{loc},1)
                if clust == 1 
                    if isempty(binClustTSsizeData{bin}{loc}) == 0                     
                        binLabel(count) = axonClusterTypeLabels(count2);
                        count = count + 1;
                    end 
                elseif clust > 1
                    if isempty(binClustTSsizeData{bin}{loc}) == 0 
                        binLabel(count) = '';
                        count = count + 1;                        
                    end                 
                end             
            end 
            % plot change in cluster size color coded by axon 
            if isempty(binClustTSsizeData{bin}{loc}) == 0 
                h = plot(x,binClustTSsizeData{bin}{loc},'Color',customColors(count2,:),'LineWidth',2); 
            end 
            count2 = count2 + 1;
        end 
    end
    sec_TimeVals = floor(((Frames_pre_stim_start:fps:Frames_post_stim_start)/fps))+1;
    FrameVals(3) = threshFrame;
    FrameVals(2) = threshFrame - (minFrameLen/5);
    FrameVals(1) = FrameVals(2) - (minFrameLen/5);
    FrameVals(4) = threshFrame + (minFrameLen/5);
    FrameVals(5) = FrameVals(4) + (minFrameLen/5);
    legend(binLabel) 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Size (microns squared)") 
    xlabel("Time (s)")
    if exist('axonTypeQ','var') == 1 
        if axonTypeQ == 0 % probabilistically sort axon type
            if distQ == 0
                title({'Change in BBB Plume Size';'Probabilistic Axon Types'})
            elseif distQ == 1 
                title({'Change in BBB Plume Size';rangeLabel;'Probabilistic Axon Types'})
            end        
        elseif axonTypeQ == 1 % do strict absolute axon type sorting
            if distQ == 0
                title({'Change in BBB Plume Size';'Absolute Axon Types'})
            elseif distQ == 1 
                title({'Change in BBB Plume Size';rangeLabel;'Absolute Axon Types'})
            end 
        end 
    elseif exist('axonTypeQ','var') == 0
        if distQ == 0
            title({'Change in BBB Plume Size'})
        elseif distQ == 1 
            title({'Change in BBB Plume Size';rangeLabel})
        end  
    end 

    xlim([1 minFrameLen])

    % plot change in cluster pixel amplitude grouped by axon type and distance 
    count = 1; 
    figure;
    ax=gca;
    hold all;
    for bin = 1:length(binClustTSsizeData)
        % determine bin labels 
        for loc = 1:2 % close axons, far axons
            % plot change in cluster size color coded by axon 
            if isempty(binClustTSpixAmpData{bin}{loc}) == 0 
                h = plot(x,binClustTSpixAmpData{bin}{loc},'Color',customColors(count,:),'LineWidth',2); 
            end 
            count = count + 1;
        end 
    end
    sec_TimeVals = floor(((Frames_pre_stim_start:fps:Frames_post_stim_start)/fps))+1;
    FrameVals(3) = threshFrame;
    FrameVals(2) = threshFrame - (minFrameLen/5);
    FrameVals(1) = FrameVals(2) - (minFrameLen/5);
    FrameVals(4) = threshFrame + (minFrameLen/5);
    FrameVals(5) = FrameVals(4) + (minFrameLen/5);
    legend(binLabel) 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Pixel Amplitude") 
    xlabel("Time (s)")
    if exist('axonTypeQ','var') == 1 
        if axonTypeQ == 0 % probabilistically sort axon type
            if distQ == 0
                title({'Change in BBB Plume Pixel Amplitude';'Probabilistic Axon Types'})
            elseif distQ == 1 
                title({'Change in BBB Plume Pixel Amplitude';rangeLabel;'Probabilistic Axon Types'})
            end   
        elseif axonTypeQ == 1 % do strict absolute axon type sorting
            if distQ == 0
                title({'Change in BBB Plume Pixel Amplitude';'Absolute Axon Types'})
            elseif distQ == 1 
                title({'Change in BBB Plume Pixel Amplitude';rangeLabel;'Absolute Axon Types'})
            end   
        end             
    elseif exist('axonTypeQ','var') == 0
        if distQ == 0
            title({'Change in BBB Plume Pixel Amplitude'})
        elseif distQ == 1 
            title({'Change in BBB Plume Pixel Amplitude';rangeLabel})
        end   
    end 
    xlim([1 minFrameLen])

    % plot average change in cluster size 
    figure;
    hold all;
    ax=gca;
    avBinClustSizeTS = NaN(3,minFrameLen);
    count = 1;
    clearvars h 
    for bin = 1:length(binClustTSsizeData)
        % determine bin labels 
        for loc = 1:2 % close axons, far axons
            avBinClustSizeTS(count,:) = nanmean(binClustTSsizeData{bin}{loc},1);  
            h{count} = plot(x,avBinClustSizeTS(count,:),'Color',customColors(count,:),'LineWidth',2); 
            % determine 95% CI 
            SEM = (nanstd(binClustTSsizeData{bin}{loc}))/(sqrt(size(binClustTSsizeData{bin}{loc},1))); %#ok<*NANSTD> % Standard Error            
            ts_Low = tinv(0.025,size(binClustTSsizeData{bin}{loc},1)-1);% T-Score for 95% CI
            ts_High = tinv(0.975,size(binClustTSsizeData{bin}{loc},1)-1);% T-Score for 95% CI
            CI_Low = (nanmean(binClustTSsizeData{bin}{loc},1)) + (ts_Low*SEM);  % Confidence Intervals
            CI_High = (nanmean(binClustTSsizeData{bin}{loc},1)) + (ts_High*SEM);  % Confidence Intervals
            % plot the 95% CI 
            clear v f 
            v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
            v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
            % remove NaNs so face can be made and colored 
            nanRows = isnan(v(:,2));
            v(nanRows,:) = []; f = 1:size(v,1);
            patch('Faces',f,'Vertices',v,'FaceColor',customColors(count,:),'EdgeColor','none');
            alpha(0.2);
            count = count + 1;
        end 
    end 
    % remove empty strings 
    emptyStrings = find(binLabel == '');
    binLabel(emptyStrings) = [];
    % determine what categories we have data for by finding rows
    % that are not all NaNs 
    [r,~] = find(all(isnan(avBinClustSizeTS),2));
    r = r';
    dataTypes = 1:size(avBinClustSizeTS,1);
    presData = ismember(dataTypes,r);
    presData = dataTypes(presData);
    binLabel2 = string(1);
    for d = 1:length(presData)
        binLabel2(presData(d)) = binLabel(d);
    end 
    % legend([h{1};h{2};h{3};h{4}],binLabel2)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Size (microns squared)") 
    xlabel("Time (s)")
    if exist('axonTypeQ','var') == 1 
        if axonTypeQ == 0 % probabilistically sort axon type
            if distQ == 0
                title({'Average Change in BBB Plume Size';'Probabilistic Axon Types'})
            elseif distQ == 1 
                title({'Average Change in BBB Plume Size';rangeLabel;'Probabilistic Axon Types'})
            end  
        elseif axonTypeQ == 1 % do strict absolute axon type sorting
            if distQ == 0
                title({'Average Change in BBB Plume Size';'Absolute Axon Types'})
            elseif distQ == 1 
                title({'Average Change in BBB Plume Size';rangeLabel;'Absolute Axon Types'})
            end 
        end         
    elseif exist('axonTypeQ','var') == 0
        if distQ == 0
            title({'Average Change in BBB Plume Size'})
        elseif distQ == 1 
            title({'Average Change in BBB Plume Size';rangeLabel})
        end    
    end 
    xlim([1 minFrameLen])      
    
    % plot average change in cluster size 
    figure;
    hold all;
    ax=gca;
    avBinClustPixAmpTS = NaN(3,minFrameLen);
    count = 1;
    for bin = 1:length(binClustTSsizeData)
        % determine bin labels 
        for loc = 1:2 % close axons, far axons
            avBinClustPixAmpTS(count,:) = nanmean(binClustTSpixAmpData{bin}{loc},1);  
            h{count} = plot(x,avBinClustPixAmpTS(count,:),'Color',customColors(count,:),'LineWidth',2);    
            % determine 95% CI 
            SEM = (nanstd(binClustTSpixAmpData{bin}{loc}))/(sqrt(size(binClustTSpixAmpData{bin}{loc},1))); %#ok<*NANSTD> % Standard Error            
            ts_Low = tinv(0.025,size(binClustTSpixAmpData{bin}{loc},1)-1);% T-Score for 95% CI
            ts_High = tinv(0.975,size(binClustTSpixAmpData{bin}{loc},1)-1);% T-Score for 95% CI
            CI_Low = (nanmean(binClustTSpixAmpData{bin}{loc},1)) + (ts_Low*SEM);  % Confidence Intervals
            CI_High = (nanmean(binClustTSpixAmpData{bin}{loc},1)) + (ts_High*SEM);  % Confidence Intervals
            % plot the 95% CI 
            clear v f 
            v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
            v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
            % remove NaNs so face can be made and colored 
            nanRows = isnan(v(:,2));
            v(nanRows,:) = []; f = 1:size(v,1);
            patch('Faces',f,'Vertices',v,'FaceColor',customColors(count,:),'EdgeColor','none');
            alpha(0.2)
            count = count + 1;
        end 
    end 
    % legend([h{1};h{2};h{3};h{4}],binLabel2)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Pixel Amplitude") 
    xlabel("Time (s)")
    if exist('axonTypeQ','var') == 1 
        if axonTypeQ == 0 % probabilistically sort axon type
            if distQ == 0
                title({'Average Change in BBB Plume Pixel Amplitude';'Probabilistic Axon Types'})
            elseif distQ == 1 
                title({'Average Change in BBB Plume Pixel Amplitude';rangeLabel;'Probabilistic Axon Types'})
            end      
        elseif axonTypeQ == 1 % do strict absolute axon type sorting
            if distQ == 0
                title({'Average Change in BBB Plume Pixel Amplitude';'Absolute Axon Types'})
            elseif distQ == 1 
                title({'Average Change in BBB Plume Pixel Amplitude';rangeLabel;'Absolute Axon Types'})
            end      
        end          
    elseif exist('axonTypeQ','var') == 0
        if distQ == 0
            title({'Average Change in BBB Plume Pixel Amplitude'})
        elseif distQ == 1 
            title({'Average Change in BBB Plume Pixel Amplitude';rangeLabel})
        end    
    end         
    xlim([1 minFrameLen])      
    
    % plot aligned cluster change in size per bin and total average 
    % determine cluster start frame per bin  
    binClustStartFrame = cell(1,3);
    alignedBinClustsSize = cell(1,3);
    avAlignedClustsSize = cell(1,3);
    figure;
    hold all;
    ax=gca;
    count = 1;
    clearvars h 
    for bin = 1:length(binClustTSsizeData)
        for loc = 1:2 % close axons, far axons
            % remove rows of all NaNs 
            rows = all(isnan(binClustTSsizeData{bin}{loc}),2);
            binClustTSsizeData{bin}{loc}(rows,:) = [];
            [clustLocX, clustLocY] = find(~isnan(binClustTSsizeData{bin}{loc}));
            clusts = unique(clustLocX);              
            for clust = 1:length(clusts)
                binClustStartFrame{bin}{loc}(clust) = min(clustLocY(clustLocX == clusts(clust)));
            end 
            if length(binClustStartFrame{bin}) >= loc 
                % align clusters
                % determine longest cluster 
                [longestClustStart,longestClust] = min(binClustStartFrame{bin}{loc});
                arrayLen = minFrameLen-longestClustStart+1;
                for clust = 1:size(binClustTSsizeData{bin}{loc},1)
                    % get data and buffer end as needed 
                    data = binClustTSsizeData{bin}{loc}(clust,binClustStartFrame{bin}{loc}(clust):end);
                    data(:,length(data)+1:arrayLen) = NaN;
                    % align data 
                    alignedBinClustsSize{bin}{loc}(clust,:) = data;
                end 
                x = 1:size(alignedBinClustsSize{bin}{loc},2);
                % averaged the aligned clusters 
                avAlignedClustsSize{bin}{loc} = nanmean(alignedBinClustsSize{bin}{loc},1);
                if isempty(binClustTSsizeData{bin}{loc}) == 0 
                    h{count} = plot(x,avAlignedClustsSize{bin}{loc},'Color',customColors(count,:),'LineWidth',2); 
                    % determine 95% CI 
                    SEM = (nanstd(alignedBinClustsSize{bin}{loc}))/(sqrt(size(alignedBinClustsSize{bin}{loc},1))); %#ok<*NANSTD> % Standard Error            
                    ts_Low = tinv(0.025,size(alignedBinClustsSize{bin}{loc},1)-1);% T-Score for 95% CI
                    ts_High = tinv(0.975,size(alignedBinClustsSize{bin}{loc},1)-1);% T-Score for 95% CI
                    CI_Low = (nanmean(alignedBinClustsSize{bin}{loc},1)) + (ts_Low*SEM);  % Confidence Intervals
                    CI_High = (nanmean(alignedBinClustsSize{bin}{loc},1)) + (ts_High*SEM);  % Confidence Intervals
                    % plot the 95% CI 
                    clear v f 
                    v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
                    v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
                    % remove NaNs so face can be made and colored 
                    nanRows = isnan(v(:,2));
                    v(nanRows,:) = []; f = 1:size(v,1);
                    patch('Faces',f,'Vertices',v,'FaceColor',customColors(count,:),'EdgeColor','none');
                    alpha(0.2)
                end 
            end 
            count = count + 1;
        end 
    end 
    % legend([h{1};h{2};h{3};h{4}],binLabel)
    Frames_pre_stim_start = -((minFrameLen-1)/2); 
    Frames_post_stim_start = (minFrameLen-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:fps:Frames_post_stim_start)/fps))+0.5+timeEnd;
    FrameVals = round((1:fps:minFrameLen));
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Size (microns squared)") 
    xlabel("Time (s)")
    if exist('axonTypeQ','var') == 1 
        if axonTypeQ == 0 % probabilistically sort axon type
            if distQ == 0
                title({'Change in BBB Plume Size';'Clusters Aligned and Averaged';'Probabilistic Axon Types'})
            elseif distQ == 1 
                title({'Change in BBB Plume Size';'Clusters Aligned and Averaged';rangeLabel;'Probabilistic Axon Types'})
            end   
        elseif axonTypeQ == 1 % do strict absolute axon type sorting
            if distQ == 0
                title({'Change in BBB Plume Size';'Clusters Aligned and Averaged';'Absolute Axon Types'})
            elseif distQ == 1 
                title({'Change in BBB Plume Size';'Clusters Aligned and Averaged';rangeLabel;'Absolute Axon Types'})
            end  
        end         
    elseif exist('axonTypeQ','var') == 0
        if distQ == 0
            title({'Change in BBB Plume Size';'Clusters Aligned and Averaged'})
        elseif distQ == 1 
            title({'Change in BBB Plume Size';'Clusters Aligned and Averaged';rangeLabel})
        end           
    end 
    xlim([1 minFrameLen])
    
    % plot aligned cluster change in pixel amplitude per bin and total average 
    % determine cluster start frame per bin  
    alignedBinClustsPixAmp = cell(1,3);
    avAlignedClustsPixAmp = cell(1,3);
    figure;
    hold all;
    ax=gca;
    count = 1;
    for bin = 1:length(binClustTSsizeData)
        for loc = 1:2 % close axons, far axons
            % remove rows of all NaNs 
            rows = all(isnan(binClustTSpixAmpData{bin}{loc}),2);
            binClustTSpixAmpData{bin}{loc}(rows,:) = [];
            if length(binClustStartFrame{bin}) >= loc 
                % align clusters
                % determine longest cluster 
                [longestClustStart,longestClust] = min(binClustStartFrame{bin}{loc});
                arrayLen = minFrameLen-longestClustStart+1;
                for clust = 1:size(binClustTSpixAmpData{bin}{loc},1)
                    % get data and buffer end as needed 
                    data = binClustTSpixAmpData{bin}{loc}(clust,binClustStartFrame{bin}{loc}(clust):end);
                    data(:,length(data)+1:arrayLen) = NaN;
                    % align data 
                    alignedBinClustsPixAmp{bin}{loc}(clust,:) = data;
                end 
                if isempty(alignedBinClustsPixAmp{bin}) == 0
                    x = 1:size(alignedBinClustsPixAmp{bin}{loc},2);
                    % averaged the aligned clusters 
                    avAlignedClustsPixAmp{bin}{loc} = nanmean(alignedBinClustsPixAmp{bin}{loc},1);
                    if isempty(binClustTSpixAmpData{bin}) == 0 
                        h{count} = plot(x,avAlignedClustsPixAmp{bin}{loc},'Color',customColors(count,:),'LineWidth',2); 
                        % determine 95% CI 
                        SEM = (nanstd(alignedBinClustsPixAmp{bin}{loc}))/(sqrt(size(alignedBinClustsPixAmp{bin}{loc},1))); %#ok<*NANSTD> % Standard Error            
                        ts_Low = tinv(0.025,size(alignedBinClustsPixAmp{bin}{loc},1)-1);% T-Score for 95% CI
                        ts_High = tinv(0.975,size(alignedBinClustsPixAmp{bin}{loc},1)-1);% T-Score for 95% CI
                        CI_Low = (nanmean(alignedBinClustsPixAmp{bin}{loc},1)) + (ts_Low*SEM);  % Confidence Intervals
                        CI_High = (nanmean(alignedBinClustsPixAmp{bin}{loc},1)) + (ts_High*SEM);  % Confidence Intervals
                        % plot the 95% CI 
                        clear v f 
                        v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
                        v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
                        % remove NaNs so face can be made and colored 
                        nanRows = isnan(v(:,2));
                        v(nanRows,:) = []; f = 1:size(v,1);
                        patch('Faces',f,'Vertices',v,'FaceColor',customColors(count,:),'EdgeColor','none');
                        alpha(0.2)
                    end 
                end 
            end 
            count = count + 1;
        end 
    end 
    % legend([h{1};h{2};h{3};h{4}],binLabel)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Pixel Amplitude") 
    xlabel("Time (s)")
    if exist('axonTypeQ','var') == 1 
        if axonTypeQ == 0 % probabilistically sort axon type
            if distQ == 0
                title({'Change in BBB Plume Pixel Amplitude';'Clusters Aligned and Averaged';'Probabilistic Axon Types'})
            elseif distQ == 1 
                title({'Change in BBB Plume Pixel Amplitude';'Clusters Aligned and Averaged';rangeLabel;'Probabilistic Axon Types'})
            end  
        elseif axonTypeQ == 1 % do strict absolute axon type sorting
            if distQ == 0
                title({'Change in BBB Plume Pixel Amplitude';'Clusters Aligned and Averaged';'Absolute Axon Types'})
            elseif distQ == 1 
                title({'Change in BBB Plume Pixel Amplitude';'Clusters Aligned and Averaged';rangeLabel;'Absolute Axon Types'})
            end  
        end         
    elseif exist('axonTypeQ','var') == 0
        if distQ == 0
            title({'Change in BBB Plume Pixel Amplitude';'Clusters Aligned and Averaged'})
        elseif distQ == 1 
            title({'Change in BBB Plume Pixel Amplitude';'Clusters Aligned and Averaged';rangeLabel})
        end          
    end 
    xlim([1 minFrameLen])

elseif clustSizeQ == 1  

    % plot the clusters that meet or exceed the threshold 
    % plot change in cluster size grouped by axon type and distance 
    count = 1 ;
    count2 = 1; 
    figure;
    ax=gca;
    hold all;
    clearvars binLabel
    for bin = 1:length(binClustTSsizeData)
        % determine bin labels 
        for loc = 1:2 % close axons, far axons
            for clust = 1:size(binClustTSsizeDataHigh{bin}{loc},1)
                if clust == 1 
                    if isempty(binClustTSsizeDataHigh{bin}{loc}) == 0                     
                        binLabel(count) = axonClusterTypeLabels(count2);
                        count = count + 1;
                    end 
                elseif clust > 1
                    if isempty(binClustTSsizeDataHigh{bin}{loc}) == 0 
                        binLabel(count) = '';
                        count = count + 1;                        
                    end                 
                end             
            end 
            % plot change in cluster size color coded by axon 
            if isempty(binClustTSsizeDataHigh{bin}{loc}) == 0 % BBB plumes that exceed %d microns squared
                h = plot(x,binClustTSsizeDataHigh{bin}{loc},'Color',customColors(count2,:),'LineWidth',2); 
            end 
            count2 = count2 + 1;
        end 
    end
    sec_TimeVals = floor(((Frames_pre_stim_start:fps:Frames_post_stim_start)/fps))+1;
    FrameVals(3) = threshFrame;
    FrameVals(2) = threshFrame - (minFrameLen/5);
    FrameVals(1) = FrameVals(2) - (minFrameLen/5);
    FrameVals(4) = threshFrame + (minFrameLen/5);
    FrameVals(5) = FrameVals(4) + (minFrameLen/5);
    legend(binLabel) 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Size (microns squared)") 
    xlabel("Time (s)")
    titleLabel = sprintf('BBB plumes that exceed %d microns squared.',clustSizeThresh);
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Change in BBB Plume Size';titleLabel;'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Change in BBB Plume Size';titleLabel;'Absolute Axon Types'})
    end 
    xlim([1 minFrameLen])

    % plot change in cluster pixel amplitude grouped by axon type and distance 
    count = 1; 
    figure;
    ax=gca;
    hold all;
    for bin = 1:length(binClustTSsizeData)
        % determine bin labels 
        for loc = 1:2 % close axons, far axons
            % plot change in cluster size color coded by axon 
            if isempty(binClustTSpixAmpDataHigh{bin}{loc}) == 0 
                h = plot(x,binClustTSpixAmpDataHigh{bin}{loc},'Color',customColors(count,:),'LineWidth',2); 
            end 
            count = count + 1;
        end 
    end
    sec_TimeVals = floor(((Frames_pre_stim_start:fps:Frames_post_stim_start)/fps))+1;
    FrameVals(3) = threshFrame;
    FrameVals(2) = threshFrame - (minFrameLen/5);
    FrameVals(1) = FrameVals(2) - (minFrameLen/5);
    FrameVals(4) = threshFrame + (minFrameLen/5);
    FrameVals(5) = FrameVals(4) + (minFrameLen/5);
    legend(binLabel) 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Pixel Amplitude") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Change in BBB Plume Pixel Amplitude';titleLabel;'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Change in BBB Plume Pixel Amplitude';titleLabel;'Absolute Axon Types'})
    end     
    xlim([1 minFrameLen])

    % plot average change in cluster size 
    figure;
    hold all;
    ax=gca;
    avBinClustSizeTS = NaN(3,minFrameLen);
    count = 1;
    count2 = 1;
    legendLabel = string(1);
    for bin = 1:length(binClustTSsizeData)
        % determine bin labels 
        for loc = 1:2 % close axons, far axons
            avBinClustSizeTS(count,:) = nanmean(binClustTSsizeDataHigh{bin}{loc},1);  
            plot(x,avBinClustSizeTS(count,:),'Color',customColors(count,:),'LineWidth',2);  
            % determine 95% CI 
            SEM = (nanstd(binClustTSsizeDataHigh{bin}{loc}))/(sqrt(size(binClustTSsizeDataHigh{bin}{loc},1))); %#ok<*NANSTD> % Standard Error            
            ts_Low = tinv(0.025,size(binClustTSsizeDataHigh{bin}{loc},1)-1);% T-Score for 95% CI
            ts_High = tinv(0.975,size(binClustTSsizeDataHigh{bin}{loc},1)-1);% T-Score for 95% CI
            CI_Low = (nanmean(binClustTSsizeDataHigh{bin}{loc},1)) + (ts_Low*SEM);  % Confidence Intervals
            CI_High = (nanmean(binClustTSsizeDataHigh{bin}{loc},1)) + (ts_High*SEM);  % Confidence Intervals
            % plot the 95% CI 
            clear v f 
            v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
            v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
            % remove NaNs so face can be made and colored 
            nanRows = isnan(v(:,2));
            v(nanRows,:) = []; f = 1:size(v,1);
            patch('Faces',f,'Vertices',v,'FaceColor',customColors(count,:),'EdgeColor','none');
            alpha(0.2)
            % figure out if the whole row is not a nan to update legend
            % label 
            if ~all(isnan(avBinClustSizeTS(count,:)),2)
                legendLabel(count2) = axonClusterTypeLabels(count);
            end 
            count = count + 1;
            count2 = count2 + 1;
        end 
    end 
    count = 1;
    binLabel2 = string(1);
    for bin = 1:size(avBinClustSizeTS,1)
        if bin == 1 
            binLabel2(bin) = legendLabel(count);
            count = count + 2;
        elseif bin > 1 
            binLabel2(count) = legendLabel(bin);
            count = count + 2;
        end 
    end 
    legend(binLabel2)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Size (microns squared)") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Average Change in BBB Plume Size';titleLabel;'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Average Change in BBB Plume Size';titleLabel;'Absolute Axon Types'})
    end   
    xlim([1 minFrameLen]) 
    
    % plot average change in pixel amp. 
    figure;
    hold all;
    ax=gca;
    avBinClustPixAmpTS = NaN(3,minFrameLen);
    count = 1;
    count2 = 1;
    legendLabel = string(1);        
    for bin = 1:length(binClustTSsizeData)
        % determine bin labels 
        for loc = 1:2 % close axons, far axons
            avBinClustPixAmpTS(count,:) = nanmean(binClustTSpixAmpDataHigh{bin}{loc},1);  
            plot(x,avBinClustPixAmpTS(count,:),'Color',customColors(count,:),'LineWidth',2);  
            % determine 95% CI 
            SEM = (nanstd(binClustTSpixAmpDataHigh{bin}{loc}))/(sqrt(size(binClustTSpixAmpDataHigh{bin}{loc},1))); %#ok<*NANSTD> % Standard Error            
            ts_Low = tinv(0.025,size(binClustTSpixAmpDataHigh{bin}{loc},1)-1);% T-Score for 95% CI
            ts_High = tinv(0.975,size(binClustTSpixAmpDataHigh{bin}{loc},1)-1);% T-Score for 95% CI
            CI_Low = (nanmean(binClustTSpixAmpDataHigh{bin}{loc},1)) + (ts_Low*SEM);  % Confidence Intervals
            CI_High = (nanmean(binClustTSpixAmpDataHigh{bin}{loc},1)) + (ts_High*SEM);  % Confidence Intervals
            % plot the 95% CI 
            clear v f 
            v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
            v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
            % remove NaNs so face can be made and colored 
            nanRows = isnan(v(:,2));
            v(nanRows,:) = []; f = 1:size(v,1);
            patch('Faces',f,'Vertices',v,'FaceColor',customColors(count,:),'EdgeColor','none');
            alpha(0.2)
            % figure out if the whole row is not a nan to update legend
            % label 
            if ~all(isnan(avBinClustSizeTS(count,:)),2)
                legendLabel(count2) = axonClusterTypeLabels(count);
            end 
            count = count + 1;
            count2 = count2 + 1;
        end 
    end 
    count = 1;
    binLabel2 = string(1);
    for bin = 1:size(avBinClustSizeTS,1)
        if bin == 1 
            binLabel2(bin) = legendLabel(count);
            count = count + 2;
        elseif bin > 1 
            binLabel2(count) = legendLabel(bin);
            count = count + 2;
        end 
    end 
    legend(binLabel2)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Pixel Amplitude") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Average Change in';'BBB Plume Pixel Amplitude';titleLabel;'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Average Change in';'BBB Plume Pixel Amplitude';titleLabel;'Absolute Axon Types'})
    end 
    xlim([1 minFrameLen]) 

    % plot aligned cluster change in size per bin and total average 
    % determine cluster start frame per bin  
    binClustStartFrame = cell(1,3);
    alignedBinClustsSize = cell(1,3);
    avAlignedClustsSize = cell(1,3);
    figure;
    hold all;
    ax=gca;
    count = 1;
    count2 = 1;
    clearvars legendLabel
    for bin = 1:length(binClustTSsizeData) 
        for loc = 1:2 % close axons, far axons
            if isempty(binClustTSsizeDataHigh{bin}{loc}) == 0 
                [clustLocX, clustLocY] = find(~isnan(binClustTSsizeDataHigh{bin}{loc}));
                clusts = unique(clustLocX);              
                for clust = 1:length(clusts)
                    binClustStartFrame{bin}{loc}(clust) = min(clustLocY(clustLocX == clust));
                end 
                % align clusters
                % determine longest cluster 
                [longestClustStart,longestClust] = min(binClustStartFrame{bin}{loc});
                arrayLen = minFrameLen-longestClustStart+1;
                for clust = 1:size(binClustTSsizeDataHigh{bin}{loc},1)
                    % get data and buffer end as needed 
                    data = binClustTSsizeDataHigh{bin}{loc}(clust,binClustStartFrame{bin}{loc}(clust):end);
                    data(:,length(data)+1:arrayLen) = NaN;
                    % align data 
                    alignedBinClustsSize{bin}{loc}(clust,:) = data;
                end 
                x = 1:size(alignedBinClustsSize{bin}{loc},2);
                % averaged the aligned clusters 
                avAlignedClustsSize{bin}{loc} = nanmean(alignedBinClustsSize{bin}{loc},1);
                h = plot(x,avAlignedClustsSize{bin}{loc},'Color',customColors(count,:),'LineWidth',2); 
                % determine 95% CI 
                SEM = (nanstd(alignedBinClustsSize{bin}{loc}))/(sqrt(size(alignedBinClustsSize{bin}{loc},1))); %#ok<*NANSTD> % Standard Error            
                ts_Low = tinv(0.025,size(alignedBinClustsSize{bin}{loc},1)-1);% T-Score for 95% CI
                ts_High = tinv(0.975,size(alignedBinClustsSize{bin}{loc},1)-1);% T-Score for 95% CI
                CI_Low = (nanmean(alignedBinClustsSize{bin}{loc},1)) + (ts_Low*SEM);  % Confidence Intervals
                CI_High = (nanmean(alignedBinClustsSize{bin}{loc},1)) + (ts_High*SEM);  % Confidence Intervals
                % plot the 95% CI 
                clear v f 
                v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
                v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
                % remove NaNs so face can be made and colored 
                nanRows = isnan(v(:,2));
                v(nanRows,:) = []; f = 1:size(v,1);
                patch('Faces',f,'Vertices',v,'FaceColor',customColors(count,:),'EdgeColor','none');
                alpha(0.2)
                legendLabel(count2) = axonClusterTypeLabels(count); 
                count2 = count2 + 1;                   
            end 
            count = count + 1;  
        end 
    end 
    count = 1;
    binLabel2 = string(1);
    for bin = 1:length(legendLabel)
        if bin == 1 
            binLabel2(bin) = legendLabel(count);
            count = count + 2;
        elseif bin > 1 
            binLabel2(count) = legendLabel(bin);
            count = count + 2;
        end 
    end 
    legend(binLabel2)
    Frames_pre_stim_start = -((minFrameLen-1)/2); 
    Frames_post_stim_start = (minFrameLen-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:fps:Frames_post_stim_start)/fps))+0.5+timeEnd;
    FrameVals = round((1:fps:minFrameLen));
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Size (microns squared)") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Change in BBB Plume Size';'Clusters Aligned and Averaged';titleLabel;'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Change in BBB Plume Size';'Clusters Aligned and Averaged';titleLabel;'Absolute Axon Types'})
    end 
    xlim([1 minFrameLen])
    
    % plot aligned cluster change in pixel amplitude per bin and total average 
    % determine cluster start frame per bin  
    alignedBinClustsPixAmp = cell(1,3);
    avAlignedClustsPixAmp = cell(1,3);
    figure;
    hold all;
    ax=gca;
    count = 1;
    count2 = 1;
    for bin = 1:length(binClustTSsizeData)
        for loc = 1:2 % close axons, far axons
            if isempty(binClustTSpixAmpDataHigh{bin}{loc}) == 0 
                % align clusters
                % determine longest cluster 
                [longestClustStart,longestClust] = min(binClustStartFrame{bin}{loc});
                arrayLen = minFrameLen-longestClustStart+1;
                for clust = 1:size(binClustTSpixAmpDataHigh{bin}{loc},1)
                    % get data and buffer end as needed 
                    data = binClustTSpixAmpDataHigh{bin}{loc}(clust,binClustStartFrame{bin}{loc}(clust):end);
                    data(:,length(data)+1:arrayLen) = NaN;
                    % align data 
                    alignedBinClustsPixAmp{bin}{loc}(clust,:) = data;
                end 
                x = 1:size(alignedBinClustsPixAmp{bin}{loc},2);
                % averaged the aligned clusters 
                avAlignedClustsPixAmp{bin}{loc} = nanmean(alignedBinClustsPixAmp{bin}{loc},1);
                h = plot(x,avAlignedClustsPixAmp{bin}{loc},'Color',customColors(count,:),'LineWidth',2); 
                % determine 95% CI 
                SEM = (nanstd(alignedBinClustsPixAmp{bin}{loc}))/(sqrt(size(alignedBinClustsPixAmp{bin}{loc},1))); %#ok<*NANSTD> % Standard Error            
                ts_Low = tinv(0.025,size(alignedBinClustsPixAmp{bin}{loc},1)-1);% T-Score for 95% CI
                ts_High = tinv(0.975,size(alignedBinClustsPixAmp{bin}{loc},1)-1);% T-Score for 95% CI
                CI_Low = (nanmean(alignedBinClustsPixAmp{bin}{loc},1)) + (ts_Low*SEM);  % Confidence Intervals
                CI_High = (nanmean(alignedBinClustsPixAmp{bin}{loc},1)) + (ts_High*SEM);  % Confidence Intervals
                % plot the 95% CI 
                clear v f 
                v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
                v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
                % remove NaNs so face can be made and colored 
                nanRows = isnan(v(:,2));
                v(nanRows,:) = []; f = 1:size(v,1);
                patch('Faces',f,'Vertices',v,'FaceColor',customColors(count,:),'EdgeColor','none');
                alpha(0.2)
                legendLabel(count2) = axonClusterTypeLabels(count); 
                count2 = count2 + 1;                   
            end 
            count = count + 1;  
        end 
    end 
    legend(binLabel2)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Pixel Amplitude") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Change in BBB Plume Pixel Amplitude';'Clusters Aligned and Averaged';titleLabel;'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Change in BBB Plume Pixel Amplitude';'Clusters Aligned and Averaged';titleLabel;'Absolute Axon Types'})
    end 
    xlim([1 minFrameLen])

    % plot the clusters that are below the threshold 
    % plot change in cluster size grouped by axon type and distance 
    x = 1:minFrameLen;
    count = 1 ;
    count2 = 1; 
    figure;
    ax=gca;
    hold all;
    for bin = 1:length(binClustTSsizeData)
        % determine bin labels 
        for loc = 1:2 % close axons, far axons
            for clust = 1:size(binClustTSsizeDataLow{bin}{loc},1)
                if clust == 1 
                    if isempty(binClustTSsizeDataLow{bin}{loc}) == 0                     
                        binLabel(count) = axonClusterTypeLabels(count2);
                        count = count + 1;
                    end 
                elseif clust > 1
                    if isempty(binClustTSsizeDataLow{bin}{loc}) == 0 
                        binLabel(count) = '';
                        count = count + 1;                        
                    end                 
                end             
            end 
            % plot change in cluster size color coded by axon 
            if isempty(binClustTSsizeDataLow{bin}{loc}) == 0 
                h = plot(x,binClustTSsizeDataLow{bin}{loc},'Color',customColors(count2,:),'LineWidth',2); 
            end 
            count2 = count2 + 1;
        end 
    end
    sec_TimeVals = floor(((Frames_pre_stim_start:fps:Frames_post_stim_start)/fps))+1;
    FrameVals(3) = threshFrame;
    FrameVals(2) = threshFrame - (minFrameLen/5);
    FrameVals(1) = FrameVals(2) - (minFrameLen/5);
    FrameVals(4) = threshFrame + (minFrameLen/5);
    FrameVals(5) = FrameVals(4) + (minFrameLen/5);
    legend(binLabel) 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Size (microns squared)") 
    xlabel("Time (s)")
    titleLabel = sprintf('BBB plumes that do not exceed %d microns squared.',clustSizeThresh);
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Change in BBB Plume Size';titleLabel;'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Change in BBB Plume Size';titleLabel;'Absolute Axon Types'})
    end 
    xlim([1 minFrameLen])

    % plot change in cluster pixel amplitude grouped by axon type and distance 
    count = 1; 
    figure;
    ax=gca;
    hold all;
    for bin = 1:length(binClustTSsizeData)
        % determine bin labels 
        for loc = 1:2 % close axons, far axons
            % plot change in cluster size color coded by axon 
            if isempty(binClustTSpixAmpDataLow{bin}{loc}) == 0 
                h = plot(x,binClustTSpixAmpDataLow{bin}{loc},'Color',customColors(count,:),'LineWidth',2); 
            end 
            count = count + 1;
        end 
    end
    sec_TimeVals = floor(((Frames_pre_stim_start:fps:Frames_post_stim_start)/fps))+1;
    FrameVals(3) = threshFrame;
    FrameVals(2) = threshFrame - (minFrameLen/5);
    FrameVals(1) = FrameVals(2) - (minFrameLen/5);
    FrameVals(4) = threshFrame + (minFrameLen/5);
    FrameVals(5) = FrameVals(4) + (minFrameLen/5);
    legend(binLabel) 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Pixel Amplitude") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Change in BBB Plume Pixel Amplitude';titleLabel;'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Change in BBB Plume Pixel Amplitude';titleLabel;'Absolute Axon Types'})
    end 
    xlim([1 minFrameLen])

    % plot average change in cluster size 
    figure;
    hold all;
    ax=gca;
    avBinClustSizeTS = NaN(3,minFrameLen);
    count = 1;
    count2 = 1;
    legendLabel = string(1);
    for bin = 1:length(binClustTSsizeData)
        % determine bin labels 
        for loc = 1:2 % close axons, far axons
            avBinClustSizeTS(count,:) = nanmean(binClustTSsizeDataLow{bin}{loc},1);  
            plot(x,avBinClustSizeTS(count,:),'Color',customColors(count,:),'LineWidth',2);   
            % determine 95% CI 
            SEM = (nanstd(binClustTSsizeDataLow{bin}{loc}))/(sqrt(size(binClustTSsizeDataLow{bin}{loc},1))); %#ok<*NANSTD> % Standard Error            
            ts_Low = tinv(0.025,size(binClustTSsizeDataLow{bin}{loc},1)-1);% T-Score for 95% CI
            ts_High = tinv(0.975,size(binClustTSsizeDataLow{bin}{loc},1)-1);% T-Score for 95% CI
            CI_Low = (nanmean(binClustTSsizeDataLow{bin}{loc},1)) + (ts_Low*SEM);  % Confidence Intervals
            CI_High = (nanmean(binClustTSsizeDataLow{bin}{loc},1)) + (ts_High*SEM);  % Confidence Intervals
            % plot the 95% CI 
            clear v f 
            v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
            v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
            % remove NaNs so face can be made and colored 
            nanRows = isnan(v(:,2));
            v(nanRows,:) = []; f = 1:size(v,1);
            patch('Faces',f,'Vertices',v,'FaceColor',customColors(count,:),'EdgeColor','none');
            alpha(0.2)
            % figure out if the whole row is not a nan to update legend
            % label 
            if ~all(isnan(avBinClustSizeTS(count,:)),2)
                legendLabel(count2) = axonClusterTypeLabels(count);
            end 
            count = count + 1;
            count2 = count2 + 1;
        end 
    end 
    count = 1;
    binLabel2 = string(1);
    for bin = 1:size(avBinClustSizeTS,1)
        if bin == 1 
            binLabel2(bin) = legendLabel(count);
            count = count + 2;
        elseif bin > 1 
            binLabel2(count) = legendLabel(bin);
            count = count + 2;
        end 
    end 
    legend(binLabel2)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Size (microns squared)") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Average Change in BBB Plume Size';titleLabel;'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Average Change in BBB Plume Size';titleLabel;'Absolute Axon Types'})
    end  
    xlim([1 minFrameLen])

    % plot average change in cluster pix amp 
    figure;
    hold all;
    ax=gca;
    avBinClustPixAmpTS = NaN(3,minFrameLen);
    count = 1;
    count2 = 1;
    legendLabel = string(1);
    for bin = 1:length(binClustTSsizeData)
        % determine bin labels 
        for loc = 1:2 % close axons, far axons
            avBinClustPixAmpTS(count,:) = nanmean(binClustTSpixAmpDataLow{bin}{loc},1);  
            plot(x,avBinClustPixAmpTS(count,:),'Color',customColors(count,:),'LineWidth',2);   
            % determine 95% CI 
            SEM = (nanstd(binClustTSpixAmpDataLow{bin}{loc}))/(sqrt(size(binClustTSpixAmpDataLow{bin}{loc},1))); %#ok<*NANSTD> % Standard Error            
            ts_Low = tinv(0.025,size(binClustTSpixAmpDataLow{bin}{loc},1)-1);% T-Score for 95% CI
            ts_High = tinv(0.975,size(binClustTSpixAmpDataLow{bin}{loc},1)-1);% T-Score for 95% CI
            CI_Low = (nanmean(binClustTSpixAmpDataLow{bin}{loc},1)) + (ts_Low*SEM);  % Confidence Intervals
            CI_High = (nanmean(binClustTSpixAmpDataLow{bin}{loc},1)) + (ts_High*SEM);  % Confidence Intervals
            % plot the 95% CI 
            clear v f 
            v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
            v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
            % remove NaNs so face can be made and colored 
            nanRows = isnan(v(:,2));
            v(nanRows,:) = []; f = 1:size(v,1);
            patch('Faces',f,'Vertices',v,'FaceColor',customColors(count,:),'EdgeColor','none');
            alpha(0.2)
            % figure out if the whole row is not a nan to update legend
            % label 
            if ~all(isnan(avBinClustPixAmpTS(count,:)),2) 
                legendLabel(count2) = axonClusterTypeLabels(count);
            end 
            count = count + 1;
            count2 = count2 + 1;
        end 
    end 
    legend(binLabel2)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Pixel Amplitude") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Average Change in';'BBB Plume Pixel Amplitude';titleLabel;'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Average Change in';'BBB Plume Pixel Amplitude';titleLabel;'Absolute Axon Types'})
    end 
    xlim([1 minFrameLen])

    % plot aligned cluster change in size per bin and total average 
    % determine cluster start frame per bin  
    binClustStartFrame = cell(1,3);
    alignedBinClustsSize = cell(1,3);
    avAlignedClustsSize = cell(1,3);
    figure;
    hold all;
    ax=gca;
    count = 1;
    count2 = 1;
    legendLabel = string(1);
    for bin = 1:length(binClustTSsizeData)    
        for loc = 1:2 % close axons, far axons
            if isempty(binClustTSsizeDataLow{bin}{loc}) == 0
                [clustLocX, clustLocY] = find(~isnan(binClustTSsizeDataLow{bin}{loc}));
                clusts = unique(clustLocX);              
                for clust = 1:length(clusts)
                    binClustStartFrame{bin}{loc}(clust) = min(clustLocY(clustLocX == clust));
                end 
                % align clusters
                % determine longest cluster 
                [longestClustStart,longestClust] = min(binClustStartFrame{bin}{loc});
                arrayLen = minFrameLen-longestClustStart+1;
                for clust = 1:size(binClustTSsizeDataLow{bin}{loc},1)
                    % get data and buffer end as needed 
                    data = binClustTSsizeDataLow{bin}{loc}(clust,binClustStartFrame{bin}{loc}(clust):end);
                    data(:,length(data)+1:arrayLen) = NaN;
                    % align data 
                    alignedBinClustsSize{bin}{loc}(clust,:) = data;
                end 
                x = 1:size(alignedBinClustsSize{bin}{loc},2);
                % averaged the aligned clusters 
                avAlignedClustsSize{bin}{loc} = nanmean(alignedBinClustsSize{bin}{loc},1);
                h = plot(x,avAlignedClustsSize{bin}{loc},'Color',customColors(count,:),'LineWidth',2); 
                % determine 95% CI 
                SEM = (nanstd(alignedBinClustsSize{bin}{loc}))/(sqrt(size(alignedBinClustsSize{bin}{loc},1))); %#ok<*NANSTD> % Standard Error            
                ts_Low = tinv(0.025,size(alignedBinClustsSize{bin}{loc},1)-1);% T-Score for 95% CI
                ts_High = tinv(0.975,size(alignedBinClustsSize{bin}{loc},1)-1);% T-Score for 95% CI
                CI_Low = (nanmean(alignedBinClustsSize{bin}{loc},1)) + (ts_Low*SEM);  % Confidence Intervals
                CI_High = (nanmean(alignedBinClustsSize{bin}{loc},1)) + (ts_High*SEM);  % Confidence Intervals
                % plot the 95% CI 
                clear v f 
                v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
                v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
                % remove NaNs so face can be made and colored 
                nanRows = isnan(v(:,2));
                v(nanRows,:) = []; f = 1:size(v,1);
                patch('Faces',f,'Vertices',v,'FaceColor',customColors(count,:),'EdgeColor','none');
                alpha(0.2)
                legendLabel(count2) = axonClusterTypeLabels(count); 
                count2 = count2 + 1;                   
            end 
            count = count + 1;              
        end           
    end 
    count = 1;
    binLabel2 = string(1);
    for bin = 1:length(legendLabel)
        if bin == 1 
            binLabel2(bin) = legendLabel(count);
            count = count + 2;
        elseif bin > 1 
            binLabel2(count) = legendLabel(bin);
            count = count + 2;
        end 
    end 
    legend(binLabel2)
    Frames_pre_stim_start = -((minFrameLen-1)/2); 
    Frames_post_stim_start = (minFrameLen-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:fps:Frames_post_stim_start)/fps))+0.5+timeEnd;
    FrameVals = round((1:fps:minFrameLen));
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Size (microns squared)") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Change in BBB Plume Size';'Clusters Aligned and Averaged';titleLabel;'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Change in BBB Plume Size';'Clusters Aligned and Averaged';titleLabel;'Absolute Axon Types'})
    end 
    xlim([1 minFrameLen])
    
    % plot aligned cluster change in pixel amplitude per bin and total average 
    % determine cluster start frame per bin  
    alignedBinClustsPixAmp = cell(1,3);
    avAlignedClustsPixAmp = cell(1,3);
    figure;
    hold all;
    ax=gca;
    count = 1;
    count2 = 1;
    legendLabel = string(1);
    for bin = 1:length(binClustTSsizeData)
        for loc = 1:2 % close axons, far axons
            if isempty(binClustTSpixAmpDataLow{bin}{loc}) == 0
                % align clusters
                % determine longest cluster 
                [longestClustStart,longestClust] = min(binClustStartFrame{bin}{loc});
                arrayLen = minFrameLen-longestClustStart+1;
                for clust = 1:size(binClustTSpixAmpDataLow{bin}{loc},1)
                    % get data and buffer end as needed 
                    data = binClustTSpixAmpDataLow{bin}{loc}(clust,binClustStartFrame{bin}{loc}(clust):end);
                    data(:,length(data)+1:arrayLen) = NaN;
                    % align data 
                    alignedBinClustsPixAmp{bin}{loc}(clust,:) = data;
                end 
                x = 1:size(alignedBinClustsPixAmp{bin}{loc},2);
                % averaged the aligned clusters 
                avAlignedClustsPixAmp{bin}{loc} = nanmean(alignedBinClustsPixAmp{bin}{loc},1);
                h = plot(x,avAlignedClustsPixAmp{bin}{loc},'Color',customColors(count,:),'LineWidth',2);
                % determine 95% CI 
                SEM = (nanstd(alignedBinClustsPixAmp{bin}{loc}))/(sqrt(size(alignedBinClustsPixAmp{bin}{loc},1))); %#ok<*NANSTD> % Standard Error            
                ts_Low = tinv(0.025,size(alignedBinClustsPixAmp{bin}{loc},1)-1);% T-Score for 95% CI
                ts_High = tinv(0.975,size(alignedBinClustsPixAmp{bin}{loc},1)-1);% T-Score for 95% CI
                CI_Low = (nanmean(alignedBinClustsPixAmp{bin}{loc},1)) + (ts_Low*SEM);  % Confidence Intervals
                CI_High = (nanmean(alignedBinClustsPixAmp{bin}{loc},1)) + (ts_High*SEM);  % Confidence Intervals
                % plot the 95% CI 
                clear v f 
                v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
                v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
                % remove NaNs so face can be made and colored 
                nanRows = isnan(v(:,2));
                v(nanRows,:) = []; f = 1:size(v,1);
                patch('Faces',f,'Vertices',v,'FaceColor',customColors(count,:),'EdgeColor','none');
                alpha(0.2)
                legendLabel(count2) = axonClusterTypeLabels(count); 
                count2 = count2 + 1;                      
            end 
            count = count + 1;
        end 
    end 
    count = 1;
    binLabel2 = string(1);
    for bin = 1:length(legendLabel)
        if bin == 1 
            binLabel2(bin) = legendLabel(count);
            count = count + 2;
        elseif bin > 1 
            binLabel2(count) = legendLabel(bin);
            count = count + 2;
        end 
    end 
    legend(binLabel2)
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 12;
    ax.FontName = 'Arial';
    ylabel("BBB Plume Pixel Amplitude") 
    xlabel("Time (s)")
    if axonTypeQ == 0 % probabilistically sort axon type
        title({'Change in BBB Plume Pixel Amplitude';'Clusters Aligned and Averaged';titleLabel;'Probabilistic Axon Types'})
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        title({'Change in BBB Plume Pixel Amplitude';'Clusters Aligned and Averaged';titleLabel;'Absolute Axon Types'})
    end 
    xlim([1 minFrameLen])    
end 
if clustSizeQ == 0
    for bin = 1:length(binClustTSsizeData)
        for loc = 1:2 % close axons, far axons
            % plot distribution of cluster start times
            figure;
            ax=gca;
            histogram(binClocFrame{bin}{loc},20)
            ax.FontSize = 15;
            ax.FontName = 'Arial';
            if aTypeQ == 0 % sort data by axon type 
                if bin == 1 
                    binLabel = 'Listener Axons';
                elseif bin == 2
                    binLabel = 'Controller Axons';
                elseif bin == 3
                    binLabel = 'Both Axons';
                end 
            elseif aTypeQ == 1 % sort data by cluster timing before or after 0 sec 
                if bin == 1 
                    binLabel = 'Pre-Spike BBB Plumes';
                elseif bin == 2
                    binLabel = 'Post-Spike BBB Plumes';
                end                     
            end 
            if distQ2 == 0 % group data by axon distance from vessel 
                if distQ == 0
                    if loc == 1
                        locLabel = 'Close Axons';
                    elseif loc == 2
                        locLabel = 'Far Axons';
                    end 
                elseif distQ == 1
                    if loc == 1
                        locLabel = 'In Range Axons';
                    elseif loc == 2
                        locLabel = 'Out of Range Axons';
                    end                 
                end                 
            elseif distQ2 == 1 % group data by BBB plume distance from axon 
                if distQ == 0
                    if loc == 1
                        locLabel = 'BBB Plumes Close to Axon';
                    elseif loc == 2
                        locLabel = 'BBB Plumes Far from Axon';
                    end 
                elseif distQ == 1
                    if loc == 1
                        locLabel = 'BBB Plumes In Range of Axon';
                    elseif loc == 2
                        locLabel = 'BBB Plumes Out of Range of Axon';
                    end                 
                end   
            elseif distQ2 == 2 % group data by BBB plume origin distance from vessel 
                if distQ == 0
                    if loc == 1
                        locLabel = 'BBB Plume Origins Close to Vessel';
                    elseif loc == 2
                        locLabel = 'BBB Plume Origins Far from Vessel';
                    end 
                elseif distQ == 1
                    if loc == 1
                        locLabel = 'BBB Plume Origins In Range of Vessel';
                    elseif loc == 2
                        locLabel = 'BBB Plume Origins Out of Range of Vessel';
                    end                 
                end    
            elseif distQ2 == 3 % group data by BBB plume origin distance from axon 
                if distQ == 0
                    if loc == 1
                        locLabel = 'BBB Plume Origins Close to Axon';
                    elseif loc == 2
                        locLabel = 'BBB Plume Origins Far from Axon';
                    end 
                elseif distQ == 1
                    if loc == 1
                        locLabel = 'BBB Plume Origins In Range of Axon';
                    elseif loc == 2
                        locLabel = 'BBB Plume Origins Out of Range of Axon';
                    end                 
                end                  
            end 
            if exist('axonTypeQ','var') == 1 
                if axonTypeQ == 0 % probabilistically sort axon type
                    if distQ == 0
                        if clustSpikeQ3 == 0 
                            title({'Distribution of BBB Plume Timing';'Average Time';binLabel;locLabel;'Probabilistic Axon Types'});
                        elseif clustSpikeQ3 == 1
                            title({'Distribution of BBB Plume Timing';'Start Time';binLabel;locLabel;'Probabilistic Axon Types'});
                        end         
                    elseif distQ == 1 
                        if clustSpikeQ3 == 0 
                            title({'Distribution of BBB Plume Timing';'Average Time';binLabel;locLabel;rangeLabel;'Probabilistic Axon Types'});
                        elseif clustSpikeQ3 == 1
                            title({'Distribution of BBB Plume Timing';'Start Time';binLabel;locLabel;rangeLabel;'Probabilistic Axon Types'});
                        end          
                    end 
                elseif axonTypeQ == 1 % do strict absolute axon type sorting
                    if distQ == 0
                        if clustSpikeQ3 == 0 
                            title({'Distribution of BBB Plume Timing';'Average Time';binLabel;locLabel;'Absolute Axon Types'});
                        elseif clustSpikeQ3 == 1
                            title({'Distribution of BBB Plume Timing';'Start Time';binLabel;locLabel;'Absolute Axon Types'});
                        end         
                    elseif distQ == 1 
                        if clustSpikeQ3 == 0 
                            title({'Distribution of BBB Plume Timing';'Average Time';binLabel;locLabel;rangeLabel;'Absolute Axon Types'});
                        elseif clustSpikeQ3 == 1
                            title({'Distribution of BBB Plume Timing';'Start Time';binLabel;locLabel;rangeLabel;'Absolute Axon Types'});
                        end          
                    end 
                end                 
            elseif exist('axonTypeQ','var') == 0
                if distQ == 0
                    if clustSpikeQ3 == 0 
                        title({'Distribution of BBB Plume Timing';'Average Time';binLabel;locLabel});
                    elseif clustSpikeQ3 == 1
                        title({'Distribution of BBB Plume Timing';'Start Time';binLabel;locLabel});
                    end         
                elseif distQ == 1 
                    if clustSpikeQ3 == 0 
                        title({'Distribution of BBB Plume Timing';'Average Time';binLabel;locLabel;rangeLabel});
                    elseif clustSpikeQ3 == 1
                        title({'Distribution of BBB Plume Timing';'Start Time';binLabel;locLabel;rangeLabel});
                    end          
                end                 
            end 
            ylabel("Number of BBB Plumes")
            xlabel("Time (s)") 
        end 
    end 
    % combine across axon types 
    closeFarBinClocFrame = cell(1,2);
    for bin = 1:length(binClustTSsizeData)
        for loc = 1:2 % close axons, far axons
            if bin == 1 
                closeFarBinClocFrame{loc} = binClocFrame{bin}{loc};
            elseif bin > 1 
                len = length(closeFarBinClocFrame{loc});
                closeFarBinClocFrame{loc}(len+1:len+length(binClocFrame{bin}{loc})) = binClocFrame{bin}{loc};
            end 
        end 
    end 
    for loc = 1:2 % close axons, far axons
        % plot distribution of cluster start times
        figure;
        ax=gca;
        histogram(closeFarBinClocFrame{loc},20)
        ax.FontSize = 15;
        ax.FontName = 'Arial';
        if distQ2 == 0 % group data by axon distance from vessel 
            if distQ == 0
                if loc == 1
                    locLabel = 'Close Axons';
                elseif loc == 2
                    locLabel = 'Far Axons';
                end 
            elseif distQ == 1
                if loc == 1
                    locLabel = 'In Range Axons';
                elseif loc == 2
                    locLabel = 'Out of Range Axons';
                end                 
            end             
        elseif distQ2 == 1 % group data by BBB plume distance from axon 
            if distQ == 0
                if loc == 1
                    locLabel = 'BBB Plumes Close to Axon';
                elseif loc == 2
                    locLabel = 'BBB Plumes Far from Axon';
                end 
            elseif distQ == 1
                if loc == 1
                    locLabel = 'BBB Plumes In Range of Axon';
                elseif loc == 2
                    locLabel = 'BBB Plumes Out of Range of Axon';
                end                 
            end   
        elseif distQ2 == 2 % group data by BBB plume origin distance from vessel 
            if distQ == 0
                if loc == 1
                    locLabel = 'BBB Plume Origins Close to Vessel';
                elseif loc == 2
                    locLabel = 'BBB Plume Origins Far from Vessel';
                end 
            elseif distQ == 1
                if loc == 1
                    locLabel = 'BBB Plume Origins In Range of Vessel';
                elseif loc == 2
                    locLabel = 'BBB Plume Origins Out of Range of Vessel';
                end                 
            end    
        elseif distQ2 == 3 % group data by BBB plume origin distance from axon 
            if distQ == 0
                if loc == 1
                    locLabel = 'BBB Plume Origins Close to Axon';
                elseif loc == 2
                    locLabel = 'BBB Plume Origins Far from Axon';
                end 
            elseif distQ == 1
                if loc == 1
                    locLabel = 'BBB Plume Origins In Range of Axon';
                elseif loc == 2
                    locLabel = 'BBB Plume Origins Out of Range of Axon';
                end                 
            end 
        end 
        if exist('axonTypeQ','var') == 1 
            if axonTypeQ == 0 % probabilistically sort axon type
                if distQ == 0
                    if clustSpikeQ3 == 0 
                        title({'Distribution of BBB Plume Timing';'Average Time';locLabel;'Probabilistic Axon Types'});
                    elseif clustSpikeQ3 == 1
                        title({'Distribution of BBB Plume Timing';'Start Time';locLabel;'Probabilistic Axon Types'});
                    end         
                elseif distQ == 1 
                    if clustSpikeQ3 == 0 
                        title({'Distribution of BBB Plume Timing';'Average Time';rangeLabel;'Probabilistic Axon Types'});
                    elseif clustSpikeQ3 == 1
                        title({'Distribution of BBB Plume Timing';'Start Time';locLabel;rangeLabel;'Probabilistic Axon Types'});
                    end          
                end 
            elseif axonTypeQ == 1 % do strict absolute axon type sorting
                if distQ == 0
                    if clustSpikeQ3 == 0 
                        title({'Distribution of BBB Plume Timing';'Average Time';locLabel;'Absolute Axon Types'});
                    elseif clustSpikeQ3 == 1
                        title({'Distribution of BBB Plume Timing';'Start Time';locLabel;'Absolute Axon Types'});
                    end         
                elseif distQ == 1 
                    if clustSpikeQ3 == 0 
                        title({'Distribution of BBB Plume Timing';'Average Time';rangeLabel;'Absolute Axon Types'});
                    elseif clustSpikeQ3 == 1
                        title({'Distribution of BBB Plume Timing';'Start Time';locLabel;rangeLabel;'Absolute Axon Types'});
                    end          
                end 
            end             
        elseif exist('axonTypeQ','var') == 0
            if distQ == 0
                if clustSpikeQ3 == 0 
                    title({'Distribution of BBB Plume Timing';'Average Time';locLabel});
                elseif clustSpikeQ3 == 1
                    title({'Distribution of BBB Plume Timing';'Start Time';locLabel});
                end         
            elseif distQ == 1 
                if clustSpikeQ3 == 0 
                    title({'Distribution of BBB Plume Timing';'Average Time';rangeLabel});
                elseif clustSpikeQ3 == 1
                    title({'Distribution of BBB Plume Timing';'Start Time';locLabel;rangeLabel});
                end          
            end             
        end 
        ylabel("Number of BBB Plumes")
        xlabel("Time (s)") 
    end 
elseif clustSizeQ == 1
    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
    for bin = 1:length(binClustTSsizeData)
        for loc = 1:2 % close axons, far axons
            % plot distribution of cluster start times
            figure;
            ax=gca;
            histogram(binClocFrameHigh{bin}{loc},20)
            ax.FontSize = 15;
            ax.FontName = 'Arial';
            if aTypeQ == 0 % sort data by axon type 
                if bin == 1 
                    binLabel = 'Listener Axons';
                elseif bin == 2
                    binLabel = 'Controller Axons';
                elseif bin == 3
                    binLabel = 'Both Axons';
                end 
            elseif aTypeQ == 1 % sort data by cluster timing before or after 0 sec 
                if bin == 1 
                    binLabel = 'Pre-Spike BBB Plumes';
                elseif bin == 2
                    binLabel = 'Post-Spike BBB Plumes';
                end                     
            end 
            if distQ2 == 0 % group data by axon distance from vessel 
                if distQ == 0
                    if loc == 1
                        locLabel = 'Close Axons';
                    elseif loc == 2
                        locLabel = 'Far Axons';
                    end 
                elseif distQ == 1
                    if loc == 1
                        locLabel = 'In Range Axons';
                    elseif loc == 2
                        locLabel = 'Out of Range Axons';
                    end                 
                end                     
            elseif distQ2 == 1 % group data by BBB plume distance from axon 
                if distQ == 0
                    if loc == 1
                        locLabel = 'BBB Plumes Close to Axon';
                    elseif loc == 2
                        locLabel = 'BBB Plumes Far from Axon';
                    end 
                elseif distQ == 1
                    if loc == 1
                        locLabel = 'BBB Plumes In Range of Axon';
                    elseif loc == 2
                        locLabel = 'BBB Plumes Out of Range of Axon';
                    end                 
                end   
            elseif distQ2 == 2 % group data by BBB plume origin distance from vessel 
                if distQ == 0
                    if loc == 1
                        locLabel = 'BBB Plume Origins Close to Vessel';
                    elseif loc == 2
                        locLabel = 'BBB Plume Origins Far from Vessel';
                    end 
                elseif distQ == 1
                    if loc == 1
                        locLabel = 'BBB Plume Origins In Range of Vessel';
                    elseif loc == 2
                        locLabel = 'BBB Plume Origins Out of Range of Vessel';
                    end                 
                end  
            elseif distQ2 == 3 % group data by BBB plume origin distance from axon 
                if distQ == 0
                    if loc == 1
                        locLabel = 'BBB Plume Origins Close to Axon';
                    elseif loc == 2
                        locLabel = 'BBB Plume Origins Far from Axon';
                    end 
                elseif distQ == 1
                    if loc == 1
                        locLabel = 'BBB Plume Origins In Range of Axon';
                    elseif loc == 2
                        locLabel = 'BBB Plume Origins Out of Range of Axon';
                    end                 
                end                 
            end 
            if axonTypeQ == 0 % probabilistically sort axon type
                if distQ == 0
                    if clustSpikeQ3 == 0 
                        title({'Distribution of BBB Plume Timing';'Average Time';binLabel;locLabel;titleLabel;'Probabilistic Axon Types'});
                    elseif clustSpikeQ3 == 1
                        title({'Distribution of BBB Plume Timing';'Start Time';binLabel;locLabel;titleLabel;'Probabilistic Axon Types'});
                    end         
                elseif distQ == 1 
                    if clustSpikeQ3 == 0 
                        title({'Distribution of BBB Plume Timing';'Average Time';binLabel;locLabel;rangeLabel;titleLabel;'Probabilistic Axon Types'});
                    elseif clustSpikeQ3 == 1
                        title({'Distribution of BBB Plume Timing';'Start Time';binLabel;locLabel;rangeLabel;titleLabel;'Probabilistic Axon Types'});
                    end          
                end 
            elseif axonTypeQ == 1 % do strict absolute axon type sorting
                if distQ == 0
                    if clustSpikeQ3 == 0 
                        title({'Distribution of BBB Plume Timing';'Average Time';binLabel;locLabel;titleLabel;'Absolute Axon Types'});
                    elseif clustSpikeQ3 == 1
                        title({'Distribution of BBB Plume Timing';'Start Time';binLabel;locLabel;titleLabel;'Absolute Axon Types'});
                    end         
                elseif distQ == 1 
                    if clustSpikeQ3 == 0 
                        title({'Distribution of BBB Plume Timing';'Average Time';binLabel;locLabel;rangeLabel;titleLabel;'Absolute Axon Types'});
                    elseif clustSpikeQ3 == 1
                        title({'Distribution of BBB Plume Timing';'Start Time';binLabel;locLabel;rangeLabel;titleLabel;'Absolute Axon Types'});
                    end          
                end 
            end 
            ylabel("Number of BBB Plumes")
            xlabel("Time (s)") 
        end 
    end 
    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
    for bin = 1:length(binClustTSsizeData)
        for loc = 1:2 % close axons, far axons
            % plot distribution of cluster start times
            figure;
            ax=gca;
            histogram(binClocFrameLow{bin}{loc},20)
            ax.FontSize = 15;
            ax.FontName = 'Arial';
            if aTypeQ == 0 % sort data by axon type 
                if bin == 1 
                    binLabel = 'Listener Axons';
                elseif bin == 2
                    binLabel = 'Controller Axons';
                elseif bin == 3
                    binLabel = 'Both Axons';
                end 
            elseif aTypeQ == 1 % sort data by cluster timing before or after 0 sec 
                if bin == 1 
                    binLabel = 'Pre-Spike BBB Plumes';
                elseif bin == 2
                    binLabel = 'Post-Spike BBB Plumes';
                end                     
            end 
            if distQ2 == 0 % group data by axon distance from vessel 
                if distQ == 0
                    if loc == 1
                        locLabel = 'Close Axons';
                    elseif loc == 2
                        locLabel = 'Far Axons';
                    end 
                elseif distQ == 1
                    if loc == 1
                        locLabel = 'In Range Axons';
                    elseif loc == 2
                        locLabel = 'Out of Range Axons';
                    end                 
                end                     
            elseif distQ2 == 1 % group data by BBB plume distance from axon 
                if distQ == 0
                    if loc == 1
                        locLabel = 'BBB Plumes Close to Axon';
                    elseif loc == 2
                        locLabel = 'BBB Plumes Far from Axon';
                    end 
                elseif distQ == 1
                    if loc == 1
                        locLabel = 'BBB Plumes In Range of Axon';
                    elseif loc == 2
                        locLabel = 'BBB Plumes Out of Range of Axon';
                    end                 
                end   
            elseif distQ2 == 2 % group data by BBB plume origin distance from vessel 
                if distQ == 0
                    if loc == 1
                        locLabel = 'BBB Plume Origins Close to Vessel';
                    elseif loc == 2
                        locLabel = 'BBB Plume Origins Far from Vessel';
                    end 
                elseif distQ == 1
                    if loc == 1
                        locLabel = 'BBB Plume Origins In Range of Vessel';
                    elseif loc == 2
                        locLabel = 'BBB Plume Origins Out of Range of Vessel';
                    end                 
                end    
            elseif distQ2 == 3 % group data by BBB plume origin distance from axon 
                if distQ == 0
                    if loc == 1
                        locLabel = 'BBB Plume Origins Close to Axon';
                    elseif loc == 2
                        locLabel = 'BBB Plume Origins Far from Axon';
                    end 
                elseif distQ == 1
                    if loc == 1
                        locLabel = 'BBB Plume Origins In Range of Axon';
                    elseif loc == 2
                        locLabel = 'BBB Plume Origins Out of Range of Axon';
                    end                 
                end                 
            end 
            if axonTypeQ == 0 % probabilistically sort axon type
                if distQ == 0
                    if clustSpikeQ3 == 0 
                        title({'Distribution of BBB Plume Timing';'Average Time';binLabel;locLabel;titleLabel;'Probabilistic Axon Types'});
                    elseif clustSpikeQ3 == 1
                        title({'Distribution of BBB Plume Timing';'Start Time';binLabel;locLabel;titleLabel;'Probabilistic Axon Types'});
                    end         
                elseif distQ == 1 
                    if clustSpikeQ3 == 0 
                        title({'Distribution of BBB Plume Timing';'Average Time';binLabel;locLabel;rangeLabel;titleLabel;'Probabilistic Axon Types'});
                    elseif clustSpikeQ3 == 1
                        title({'Distribution of BBB Plume Timing';'Start Time';binLabel;locLabel;rangeLabel;titleLabel;'Probabilistic Axon Types'});
                    end          
                end 
            elseif axonTypeQ == 1 % do strict absolute axon type sorting
                if distQ == 0
                    if clustSpikeQ3 == 0 
                        title({'Distribution of BBB Plume Timing';'Average Time';binLabel;locLabel;titleLabel;'Absolute Axon Types'});
                    elseif clustSpikeQ3 == 1
                        title({'Distribution of BBB Plume Timing';'Start Time';binLabel;locLabel;titleLabel;'Absolute Axon Types'});
                    end         
                elseif distQ == 1 
                    if clustSpikeQ3 == 0 
                        title({'Distribution of BBB Plume Timing';'Average Time';binLabel;locLabel;rangeLabel;titleLabel;'Absolute Axon Types'});
                    elseif clustSpikeQ3 == 1
                        title({'Distribution of BBB Plume Timing';'Start Time';binLabel;locLabel;rangeLabel;titleLabel;'Absolute Axon Types'});
                    end          
                end 
            end 
            ylabel("Number of BBB Plumes")
            xlabel("Time (s)") 
        end 
    end 
    % combine across axon types 
    closeFarBinClocFrameHigh = cell(1,2);
    for bin = 1:length(binClustTSsizeData)
        for loc = 1:2 % close axons, far axons
            if bin == 1 
                closeFarBinClocFrameHigh{loc} = binClocFrameHigh{bin}{loc};
            elseif bin > 1 
                len = length(closeFarBinClocFrameHigh{loc});
                closeFarBinClocFrameHigh{loc}(len+1:len+length(binClocFrameHigh{bin}{loc})) = binClocFrameHigh{bin}{loc};
            end 
        end 
    end 
    closeFarBinClocFrameLow = cell(1,2);
    for bin = 1:length(binClustTSsizeData)
        for loc = 1:2 % close axons, far axons
            if bin == 1 
                closeFarBinClocFrameLow{loc} = binClocFrameLow{bin}{loc};
            elseif bin > 1 
                len = length(closeFarBinClocFrameLow{loc});
                closeFarBinClocFrameLow{loc}(len+1:len+length(binClocFrameLow{bin}{loc})) = binClocFrameLow{bin}{loc};
            end 
        end 
    end 
    titleLabel = sprintf('BBB Plumes that exceed %d microns squared.',clustSizeThresh);
    for loc = 1:2 % close axons, far axons
        % plot distribution of cluster start times
        figure;
        ax=gca;
        histogram(closeFarBinClocFrameHigh{loc},20)
        ax.FontSize = 15;
        ax.FontName = 'Arial';
        if distQ2 == 0 % group data by axon distance from vessel 
            if distQ == 0
                if loc == 1
                    locLabel = 'Close Axons';
                elseif loc == 2
                    locLabel = 'Far Axons';
                end 
            elseif distQ == 1
                if loc == 1
                    locLabel = 'In Range Axons';
                elseif loc == 2
                    locLabel = 'Out of Range Axons';
                end                 
            end                 
        elseif distQ2 == 1 % group data by BBB plume distance from axon 
                if distQ == 0
                    if loc == 1
                        locLabel = 'BBB Plumes Close to Axon';
                    elseif loc == 2
                        locLabel = 'BBB Plumes Far from Axon';
                    end 
                elseif distQ == 1
                    if loc == 1
                        locLabel = 'BBB Plumes In Range of Axon';
                    elseif loc == 2
                        locLabel = 'BBB Plumes Out of Range of Axon';
                    end                 
                end   
        elseif distQ2 == 2 % group data by BBB plume origin distance from vessel 
            if distQ == 0
                if loc == 1
                    locLabel = 'BBB Plume Origins Close to Vessel';
                elseif loc == 2
                    locLabel = 'BBB Plume Origins Far from Vessel';
                end 
            elseif distQ == 1
                if loc == 1
                    locLabel = 'BBB Plume Origins In Range of Vessel';
                elseif loc == 2
                    locLabel = 'BBB Plume Origins Out of Range of Vessel';
                end                 
            end    
        elseif distQ2 == 3 % group data by BBB plume origin distance from axon 
            if distQ == 0
                if loc == 1
                    locLabel = 'BBB Plume Origins Close to Axon';
                elseif loc == 2
                    locLabel = 'BBB Plume Origins Far from Axon';
                end 
            elseif distQ == 1
                if loc == 1
                    locLabel = 'BBB Plume Origins In Range of Axon';
                elseif loc == 2
                    locLabel = 'BBB Plume Origins Out of Range of Axon';
                end                 
            end             
        end 
        if axonTypeQ == 0 % probabilistically sort axon type
            if distQ == 0
                if clustSpikeQ3 == 0 
                    title({'Distribution of BBB Plume Timing';'Average Time';locLabel;titleLabel;'Probabilistic Axon Types'});
                elseif clustSpikeQ3 == 1
                    title({'Distribution of BBB Plume Timing';'Start Time';locLabel;titleLabel;'Probabilistic Axon Types'});
                end         
            elseif distQ == 1 
                if clustSpikeQ3 == 0 
                    title({'Distribution of BBB Plume Timing';'Average Time';locLabel;rangeLabel;titleLabel;'Probabilistic Axon Types'});
                elseif clustSpikeQ3 == 1
                    title({'Distribution of BBB Plume Timing';'Start Time';locLabel;rangeLabel;titleLabel;'Probabilistic Axon Types'});
                end          
            end 
        elseif axonTypeQ == 1 % do strict absolute axon type sorting
            if distQ == 0
                if clustSpikeQ3 == 0 
                    title({'Distribution of BBB Plume Timing';'Average Time';locLabel;titleLabel;'Absolute Axon Types'});
                elseif clustSpikeQ3 == 1
                    title({'Distribution of BBB Plume Timing';'Start Time';locLabel;titleLabel;'Absolute Axon Types'});
                end         
            elseif distQ == 1 
                if clustSpikeQ3 == 0 
                    title({'Distribution of BBB Plume Timing';'Average Time';locLabel;rangeLabel;titleLabel;'Absolute Axon Types'});
                elseif clustSpikeQ3 == 1
                    title({'Distribution of BBB Plume Timing';'Start Time';locLabel;rangeLabel;titleLabel;'Absolute Axon Types'});
                end          
            end 
        end 
        ylabel("Number of BBB Plumes")
        xlabel("Time (s)") 
    end 
    titleLabel = sprintf('BBB Plumes that do not exceed %d microns squared.',clustSizeThresh);
    for loc = 1:2 % close axons, far axons
        % plot distribution of cluster start times
        figure;
        ax=gca;
        histogram(closeFarBinClocFrameLow{loc},20)
        ax.FontSize = 15;
        ax.FontName = 'Arial';
        if distQ2 == 0 % group data by axon distance from vessel 
            if distQ == 0
                if loc == 1
                    locLabel = 'Close Axons';
                elseif loc == 2
                    locLabel = 'Far Axons';
                end 
            elseif distQ == 1
                if loc == 1
                    locLabel = 'In Range Axons';
                elseif loc == 2
                    locLabel = 'Out of Range Axons';
                end                 
            end 
        elseif distQ2 == 1 % group data by BBB plume distance from axon 
                if distQ == 0
                    if loc == 1
                        locLabel = 'BBB Plumes Close to Axon';
                    elseif loc == 2
                        locLabel = 'BBB Plumes Far from Axon';
                    end 
                elseif distQ == 1
                    if loc == 1
                        locLabel = 'BBB Plumes In Range of Axon';
                    elseif loc == 2
                        locLabel = 'BBB Plumes Out of Range of Axon';
                    end                 
                end   
        elseif distQ2 == 2 % group data by BBB plume origin distance from vessel 
            if distQ == 0
                if loc == 1
                    locLabel = 'BBB Plume Origins Close to Vessel';
                elseif loc == 2
                    locLabel = 'BBB Plume Origins Far from Vessel';
                end 
            elseif distQ == 1
                if loc == 1
                    locLabel = 'BBB Plume Origins In Range of Vessel';
                elseif loc == 2
                    locLabel = 'BBB Plume Origins Out of Range of Vessel';
                end                 
            end 
        elseif distQ2 == 3 % group data by BBB plume origin distance from axon 
            if distQ == 0
                if loc == 1
                    locLabel = 'BBB Plume Origins Close to Axon';
                elseif loc == 2
                    locLabel = 'BBB Plume Origins Far from Axon';
                end 
            elseif distQ == 1
                if loc == 1
                    locLabel = 'BBB Plume Origins In Range of Axon';
                elseif loc == 2
                    locLabel = 'BBB Plume Origins Out of Range of Axon';
                end                 
            end             
        end 
        if axonTypeQ == 0 % probabilistically sort axon type
            if distQ == 0
                if clustSpikeQ3 == 0 
                    title({'Distribution of BBB Plume Timing';'Average Time';locLabel;titleLabel;'Probabilistic Axon Types'});
                elseif clustSpikeQ3 == 1
                    title({'Distribution of BBB Plume Timing';'Start Time';locLabel;titleLabel;'Probabilistic Axon Types'});
                end         
            elseif distQ == 1 
                if clustSpikeQ3 == 0 
                    title({'Distribution of BBB Plume Timing';'Average Time';locLabel;rangeLabel;titleLabel;'Probabilistic Axon Types'});
                elseif clustSpikeQ3 == 1
                    title({'Distribution of BBB Plume Timing';'Start Time';locLabel;rangeLabel;titleLabel;'Probabilistic Axon Types'});
                end          
            end 
        elseif axonTypeQ == 1 % do strict absolute axon type sorting
            if distQ == 0
                if clustSpikeQ3 == 0 
                    title({'Distribution of BBB Plume Timing';'Average Time';locLabel;titleLabel;'Absolute Axon Types'});
                elseif clustSpikeQ3 == 1
                    title({'Distribution of BBB Plume Timing';'Start Time';locLabel;titleLabel;'Absolute Axon Types'});
                end         
            elseif distQ == 1 
                if clustSpikeQ3 == 0 
                    title({'Distribution of BBB Plume Timing';'Average Time';locLabel;rangeLabel;titleLabel;'Absolute Axon Types'});
                elseif clustSpikeQ3 == 1
                    title({'Distribution of BBB Plume Timing';'Start Time';locLabel;rangeLabel;titleLabel;'Absolute Axon Types'});
                end          
            end 
        end 
        ylabel("Number of BBB Plumes")
        xlabel("Time (s)") 
    end         
end  
%% plot distribution of axon distances from the vessel and distribution of BBB plume distance from axon color coded by axon type and BBB plume timing 
if ETAorSTAq == 0 % STA data 
    sizeQhist = input('Input 1 to set a size threshold for the BBB plume distance from axon histograms. Input 0 otherwise. ');
    if sizeQhist == 1
        histSizeThresh = input('Input the histogram size threshold for BBB plumes (microns): ');
    end 

    % plot distribution of axon distance from vessel, color coded by axon
    % type 
    % determine what the max and min values are for axon dists from vessel
    minAVdist = min(floor(allMinVAdists));
    maxAVdist = max(ceil(allMinVAdists));
    % determine the number of bins for creating histogram so that each
    % bin = 5 microns 
    numBins = ceil(maxAVdist/5);
    edge = [0,5];
    BinEdges = nan(1,2);
    AdistsByAtype = nan(numBins,3);
    for bin = 1:numBins
        % determine bin edges 
        BinEdges(bin,:) = edge;
        edge = edge+[5,5];
        for mouse = 1:mouseNum
            % sort data into bins organized by axon type (listener,
            % controller, both) 
            if mouse == 1 
                for aType = 1:3
                    if aType == 1
                        [~, c] = find(minVAdists{mouse} > BinEdges(bin,1) & minVAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        AdistsByAtype(bin,aType) = sum(ismember(listenerAxons{mouse},c));
                    elseif aType == 2 
                        [~, c] = find(minVAdists{mouse} > BinEdges(bin,1) & minVAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        AdistsByAtype(bin,aType) = sum(ismember(controllerAxons{mouse},c));
                    elseif aType == 3 
                        [~, c] = find(minVAdists{mouse} > BinEdges(bin,1) & minVAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end                         
                        AdistsByAtype(bin,aType) = sum(ismember(bothAxons{mouse},c));
                    end                 
                end 
            elseif mouse > 1 
                for aType = 1:3
                    if aType == 1
                        [~, c] = find(minVAdists{mouse} > BinEdges(bin,1) & minVAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end                         
                        data = sum(ismember(listenerAxons{mouse},c));
                        AdistsByAtype(bin,aType) = data + AdistsByAtype(bin,aType);
                    elseif aType == 2 
                        [~, c] = find(minVAdists{mouse} > BinEdges(bin,1) & minVAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end                         
                        data = sum(ismember(controllerAxons{mouse},c));
                        AdistsByAtype(bin,aType) = data + AdistsByAtype(bin,aType);
                    elseif aType == 3 
                        [~, c] = find(minVAdists{mouse} > BinEdges(bin,1) & minVAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end                         
                        data = sum(ismember(bothAxons{mouse},c));
                        AdistsByAtype(bin,aType) = data + AdistsByAtype(bin,aType);
                    end                 
                end                 
            end 
        end 
    end 
    % plot distribution of axon distance from vessel, color coded by axon
    % type 
    figure;
    ax=gca;
    ba = bar(AdistsByAtype,'stacked','FaceColor','flat');
    ba(1).CData = [0 0.4470 0.7410];
    ba(2).CData = [0.8500 0.3250 0.0980];
    ba(3).CData = [0.4250 0.386 0.4195];
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    if axonTypeQ == 0 % probabilistically sort axon type
        if sizeQhist == 1
            titleLabel = sprintf('BBB Plumes that exceed %d',histSizeThresh);
            title({'Distribution of Axon Distance from Vessel';titleLabel;'Probabilistic Axon Types'});
        elseif sizeQhist == 0
            title({'Distribution of Axon Distance from Vessel';'Probabilistic Axon Types'});
        end        
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        if sizeQhist == 1
            titleLabel = sprintf('BBB Plumes that exceed %d',histSizeThresh);
            title({'Distribution of Axon Distance from Vessel';titleLabel;'Absolute Axon Types'});
        elseif sizeQhist == 0
            title({'Distribution of Axon Distance from Vessel';'Absolute Axon Types'});
        end 
    end 
    ylabel("Number of Axons")
    xlabel("Distance (microns)") 
    legend("Listener Axons","Controller Axons","Axons that do Both")
    set(gca,'XTick',minAVdist:3:maxAVdist)
    xticks = get(gca,'xtick'); 
    % x = minAVdist:10:maxAVdist;
    scaling  = 5;
    newlabels = arrayfun(@(x) sprintf('%.0f', scaling * x), xticks, 'un', 0);
    set(gca,'xticklabel',newlabels)    

    % plot distribution of BBB plume from axon, color coded by axon
    % type 
    % create dists{mouse} array that contains plume dist data for each
    % mouse 
    BAdists = cell(1,mouseNum);
    for mouse = 1:mouseNum
        BAdists{mouse} = (timeDistArray{mouse}(~isnan(timeDistArray{mouse}(:,1)),2))';
    end 
    % determine what the max and min values are for BBB plume dists from
    % axon 
    minBAdist = min(floor(allTimeDistArray(:,2)));
    maxBAdist = max(ceil(allTimeDistArray(:,2)));
    % determine the number of bins for creating histogram so that each
    % bin = 5 microns 
    numBins = ceil(maxBAdist/5);
    edge = [0,5];
    BinEdges = nan(1,2);
    BdistsByAtype = nan(numBins,3);
    for bin = 1:numBins
        % determine bin edges 
        BinEdges(bin,:) = edge;
        edge = edge+[5,5];
        for mouse = 1:mouseNum           
            % sort data into bins organized by axon type (listener,
            % controller, both) 
            if mouse == 1 
                for aType = 1:3
                    if aType == 1
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        BdistsByAtype(bin,aType) = sum(ismember(ccell,listenerAxons{mouse}));
                    elseif aType == 2 
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        BdistsByAtype(bin,aType) = sum(ismember(ccell,controllerAxons{mouse}));
                    elseif aType == 3 
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        BdistsByAtype(bin,aType) = sum(ismember(ccell,bothAxons{mouse}));
                    end                 
                end                   
            elseif mouse > 1 
                for aType = 1:3
                    if aType == 1
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        data = sum(ismember(ccell,listenerAxons{mouse}));
                        BdistsByAtype(bin,aType) = data + BdistsByAtype(bin,aType);
                    elseif aType == 2 
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        data = sum(ismember(ccell,controllerAxons{mouse}));
                        BdistsByAtype(bin,aType) = data + BdistsByAtype(bin,aType);
                    elseif aType == 3 
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        data = sum(ismember(ccell,bothAxons{mouse}));
                        BdistsByAtype(bin,aType) = data + BdistsByAtype(bin,aType);
                    end                 
                end                 
            end 
        end 
    end 
    % plot distribution of BBB plume from axon, color coded by axon
    % type 
    figure;
    ax=gca;
    ba = bar(BdistsByAtype,'stacked','FaceColor','flat');
    ba(1).CData = [0 0.4470 0.7410];
    ba(2).CData = [0.8500 0.3250 0.0980];
    ba(3).CData = [0.4250 0.386 0.4195];
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    if axonTypeQ == 0 % probabilistically sort axon type
        if sizeQhist == 1
            titleLabel = sprintf('BBB Plumes that exceed %d',histSizeThresh);
            title({'Distribution of BBB Plume Distance from Axon';titleLabel;'Probabilistic Axon Types'});
        elseif sizeQhist == 0
            title({'Distribution of BBB Plume Distance from Axon';'Probabilistic Axon Types'});
        end 
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        if sizeQhist == 1
            titleLabel = sprintf('BBB Plumes that exceed %d',histSizeThresh);
            title({'Distribution of BBB Plume Distance from Axon';titleLabel;'Absolute Axon Types'});
        elseif sizeQhist == 0
            title({'Distribution of BBB Plume Distance from Axon';'Absolute Axon Types'});
        end 
    end 
    ylabel("Number of BBB Plumes")
    xlabel("Distance (microns)") 
    legend("Listener Axons","Controller Axons","Axons that do Both")
    set(gca,'XTick',minBAdist:3:maxBAdist)
    xticks = get(gca,'xtick'); 
    % x = minBAdist:10:maxBAdist;
    scaling  = 5;
    newlabels = arrayfun(@(x) sprintf('%.0f', scaling * x), xticks, 'un', 0);
    set(gca,'xticklabel',newlabels)

    % plot the distribution of plume distances from axon color coded by plume
    % timing before or after the spike/event 
    edge = [0,5];
    BinEdges = nan(1,2);
    BdistsByTtype = nan(numBins,2);
    for bin = 1:numBins
        % determine bin edges 
        BinEdges(bin,:) = edge;
        edge = edge+[5,5];
        for mouse = 1:mouseNum   
            % sort data into bins organized by axon type (listener,
            % controller, both) 
            if mouse == 1 
                for tType = 1:2
                    if tType == 1 % before event/spike
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        BdistsByTtype(bin,tType) = sum(reshpdAvClocFrame{mouse}(c) < 0);
                    elseif tType == 2 % after event/spike 
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end
                        BdistsByTtype(bin,tType) = sum(reshpdAvClocFrame{mouse}(c) >= 0);
                    end                 
                end                   
            elseif mouse > 1 
                for tType = 1:2
                    if tType == 1 % before event/spike
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end
                        data = sum(reshpdAvClocFrame{mouse}(c) < 0);
                        BdistsByTtype(bin,tType) = data + BdistsByTtype(bin,tType);
                    elseif tType == 2 % after event/spike  
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end
                        data = sum(reshpdAvClocFrame{mouse}(c) >= 0);
                        BdistsByTtype(bin,tType) = data + BdistsByTtype(bin,tType);
                    end                 
                end                 
            end 
        end 
    end 
    % plot the distribution of plume distances from axon color coded by plume
    % timing before or after the spike/event 
    figure;
    ax=gca;
    ba = bar(BdistsByTtype,'stacked','FaceColor','flat');
    bar2Clr = hsv(2);
    ba(1).CData = bar2Clr(1,:);
    ba(2).CData = bar2Clr(2,:);
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    if sizeQhist == 1
        titleLabel = sprintf('BBB Plumes that exceed %d',histSizeThresh);
        title({'Distribution of BBB Plume Distance from Axon';titleLabel});
    elseif sizeQhist == 0
        title({'Distribution of BBB Plume Distance from Axon'});
    end 
    ylabel("Number of BBB Plumes")
    xlabel("Distance (microns)") 
    legend("Before 0 sec","After 0 sec")
    set(gca,'XTick',minBAdist:3:maxBAdist)
    xticks = get(gca,'xtick'); 
    x = minBAdist:10:maxBAdist; %#ok<NASGU>
    scaling  = 5;
    newlabels = arrayfun(@(x) sprintf('%.0f', scaling * x), xticks, 'un', 0);
    set(gca,'xticklabel',newlabels)

    % plot distribution of BBB plume origin dist from vessel, color coded by axon
    % type 
    % create dists{mouse} array that contains plume dist data for each
    % mouse 
    BAdists = cell(1,mouseNum);
    for mouse = 1:mouseNum
        BAdists{mouse} = (timeCOVdistArray{mouse}(~isnan(timeCOVdistArray{mouse}(:,1)),2))';
    end 
    % determine what the max and min values are for BBB plume dists from
    % axon 
    minBAdist = min(floor(allTimeDistArray(:,2)));
    maxBAdist = max(ceil(allTimeDistArray(:,2)));
    % determine the number of bins for creating histogram so that each
    % bin = 5 microns 
    numBins = ceil(maxBAdist/5);
    edge = [0,5];
    BinEdges = nan(1,2);
    BdistsByAtype = nan(numBins,3);
    for bin = 1:numBins
        % determine bin edges 
        BinEdges(bin,:) = edge;
        edge = edge+[5,5];
        for mouse = 1:mouseNum           
            % sort data into bins organized by axon type (listener,
            % controller, both) 
            if mouse == 1 
                for aType = 1:3
                    if aType == 1
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        BdistsByAtype(bin,aType) = sum(ismember(ccell,listenerAxons{mouse}));
                    elseif aType == 2 
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        BdistsByAtype(bin,aType) = sum(ismember(ccell,controllerAxons{mouse}));
                    elseif aType == 3 
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        BdistsByAtype(bin,aType) = sum(ismember(ccell,bothAxons{mouse}));
                    end                 
                end                   
            elseif mouse > 1 
                for aType = 1:3
                    if aType == 1
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        data = sum(ismember(ccell,listenerAxons{mouse}));
                        BdistsByAtype(bin,aType) = data + BdistsByAtype(bin,aType);
                    elseif aType == 2 
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        data = sum(ismember(ccell,controllerAxons{mouse}));
                        BdistsByAtype(bin,aType) = data + BdistsByAtype(bin,aType);
                    elseif aType == 3 
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        data = sum(ismember(ccell,bothAxons{mouse}));
                        BdistsByAtype(bin,aType) = data + BdistsByAtype(bin,aType);
                    end                 
                end                 
            end 
        end 
    end 
    % plot distribution of BBB plume origin dist from vessel, color coded by axon
    % type 
    figure;
    ax=gca;
    ba = bar(BdistsByAtype,'stacked','FaceColor','flat');
    ba(1).CData = [0 0.4470 0.7410];
    ba(2).CData = [0.8500 0.3250 0.0980];
    ba(3).CData = [0.4250 0.386 0.4195];
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    if axonTypeQ == 0 % probabilistically sort axon type
        if sizeQhist == 1
            titleLabel = sprintf('BBB Plumes that exceed %d',histSizeThresh);
            title({'Distribution of BBB Plume Origin Distance from Vessel';titleLabel;'Probabilistic Axon Types'});
        elseif sizeQhist == 0
            title({'Distribution of BBB Plume Origin Distance from Vessel';'Probabilistic Axon Types'});
        end 
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        if sizeQhist == 1
            titleLabel = sprintf('BBB Plumes that exceed %d',histSizeThresh);
            title({'Distribution of BBB Plume Origin Distance from Vessel';titleLabel;'Absolute Axon Types'});
        elseif sizeQhist == 0
            title({'Distribution of BBB Plume Origin Distance from Vessel';'Absolute Axon Types'});
        end 
    end 
    ylabel("Number of BBB Plumes")
    xlabel("Distance (microns)") 
    legend("Listener Axons","Controller Axons","Axons that do Both")
    set(gca,'XTick',minBAdist:3:maxBAdist)
    xticks = get(gca,'xtick'); 
    % x = minBAdist:10:maxBAdist;
    scaling  = 5;
    newlabels = arrayfun(@(x) sprintf('%.0f', scaling * x), xticks, 'un', 0);
    set(gca,'xticklabel',newlabels)

    % plot distribution of BBB plume origin dist from vessel, color coded by timing before or after the spike/event 
    edge = [0,5];
    BinEdges = nan(1,2);
    BdistsByTtype = nan(numBins,2);
    for bin = 1:numBins
        % determine bin edges 
        BinEdges(bin,:) = edge;
        edge = edge+[5,5];
        for mouse = 1:mouseNum   
            % sort data into bins organized by axon type (listener,
            % controller, both) 
            if mouse == 1 
                for tType = 1:2
                    if tType == 1 % before event/spike
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        BdistsByTtype(bin,tType) = sum(reshpdAvClocFrame{mouse}(c) < 0);
                    elseif tType == 2 % after event/spike 
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end
                        BdistsByTtype(bin,tType) = sum(reshpdAvClocFrame{mouse}(c) >= 0);
                    end                 
                end                   
            elseif mouse > 1 
                for tType = 1:2
                    if tType == 1 % before event/spike
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end
                        data = sum(reshpdAvClocFrame{mouse}(c) < 0);
                        BdistsByTtype(bin,tType) = data + BdistsByTtype(bin,tType);
                    elseif tType == 2 % after event/spike  
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end
                        data = sum(reshpdAvClocFrame{mouse}(c) >= 0);
                        BdistsByTtype(bin,tType) = data + BdistsByTtype(bin,tType);
                    end                 
                end                 
            end 
        end 
    end 
    % plot distribution of BBB plume origin dist from vessel, color coded by timing before or after the spike/event 
    figure;
    ax=gca;
    ba = bar(BdistsByTtype,'stacked','FaceColor','flat');
    bar2Clr = hsv(2);
    ba(1).CData = bar2Clr(1,:);
    ba(2).CData = bar2Clr(2,:);
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    if sizeQhist == 1
        titleLabel = sprintf('BBB Plumes that exceed %d',histSizeThresh);
        title({'Distribution of BBB Plume Origin Distance from Vessel';titleLabel});
    elseif sizeQhist == 0
        title({'Distribution of BBB Plume Origin Distance from Vessel'});
    end 
    ylabel("Number of BBB Plumes")
    xlabel("Distance (microns)") 
    legend("Before 0 sec","After 0 sec")
    set(gca,'XTick',minBAdist:3:maxBAdist)
    xticks = get(gca,'xtick'); 
    x = minBAdist:10:maxBAdist; %#ok<NASGU>
    scaling  = 5;
    newlabels = arrayfun(@(x) sprintf('%.0f', scaling * x), xticks, 'un', 0);
    set(gca,'xticklabel',newlabels)  

    % plot distribution of BBB plume origin dist from axon, color coded by axon
    % type 
    % create dists{mouse} array that contains plume dist data for each
    % mouse 
    BAdists = cell(1,mouseNum);
    for mouse = 1:mouseNum
        BAdists{mouse} = (timeODistArray{mouse}(~isnan(timeODistArray{mouse}(:,1)),2))';
    end 
    % determine what the max and min values are for BBB plume dists from
    % axon 
    minBAdist = min(floor(allTimeDistArray(:,2)));
    maxBAdist = max(ceil(allTimeDistArray(:,2)));
    % determine the number of bins for creating histogram so that each
    % bin = 5 microns 
    numBins = ceil(maxBAdist/5);
    edge = [0,5];
    BinEdges = nan(1,2);
    BdistsByAtype = nan(numBins,3);
    for bin = 1:numBins
        % determine bin edges 
        BinEdges(bin,:) = edge;
        edge = edge+[5,5];
        for mouse = 1:mouseNum           
            % sort data into bins organized by axon type (listener,
            % controller, both) 
            if mouse == 1 
                for aType = 1:3
                    if aType == 1
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        BdistsByAtype(bin,aType) = sum(ismember(ccell,listenerAxons{mouse}));
                    elseif aType == 2 
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        BdistsByAtype(bin,aType) = sum(ismember(ccell,controllerAxons{mouse}));
                    elseif aType == 3 
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        BdistsByAtype(bin,aType) = sum(ismember(ccell,bothAxons{mouse}));
                    end                 
                end                   
            elseif mouse > 1 
                for aType = 1:3
                    if aType == 1
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        data = sum(ismember(ccell,listenerAxons{mouse}));
                        BdistsByAtype(bin,aType) = data + BdistsByAtype(bin,aType);
                    elseif aType == 2 
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        data = sum(ismember(ccell,controllerAxons{mouse}));
                        BdistsByAtype(bin,aType) = data + BdistsByAtype(bin,aType);
                    elseif aType == 3 
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        ccell = axonInds{mouse}(c);
                        data = sum(ismember(ccell,bothAxons{mouse}));
                        BdistsByAtype(bin,aType) = data + BdistsByAtype(bin,aType);
                    end                 
                end                 
            end 
        end 
    end 
    % plot distribution of BBB plume origin dist from axon, color coded by axon
    % type 
    figure;
    ax=gca;
    ba = bar(BdistsByAtype,'stacked','FaceColor','flat');
    ba(1).CData = [0 0.4470 0.7410];
    ba(2).CData = [0.8500 0.3250 0.0980];
    ba(3).CData = [0.4250 0.386 0.4195];
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    if axonTypeQ == 0 % probabilistically sort axon type
        if sizeQhist == 1
            titleLabel = sprintf('BBB Plumes that exceed %d',histSizeThresh);
            title({'Distribution of BBB Plume Origin Distance from Axon';titleLabel;'Probabilistic Axon Types'});
        elseif sizeQhist == 0
            title({'Distribution of BBB Plume Origin Distance from Axon';'Probabilistic Axon Types'});
        end 
    elseif axonTypeQ == 1 % do strict absolute axon type sorting
        if sizeQhist == 1
            titleLabel = sprintf('BBB Plumes that exceed %d',histSizeThresh);
            title({'Distribution of BBB Plume Origin Distance from Axon';titleLabel;'Absolute Axon Types'});
        elseif sizeQhist == 0
            title({'Distribution of BBB Plume Origin Distance from Axon';'Absolute Axon Types'});
        end 
    end 
    ylabel("Number of BBB Plumes")
    xlabel("Distance (microns)") 
    legend("Listener Axons","Controller Axons","Axons that do Both")
    set(gca,'XTick',minBAdist:3:maxBAdist)
    xticks = get(gca,'xtick'); 
    % x = minBAdist:10:maxBAdist;
    scaling  = 5;
    newlabels = arrayfun(@(x) sprintf('%.0f', scaling * x), xticks, 'un', 0);
    set(gca,'xticklabel',newlabels)
    ylim([0 8])

    % plot distribution of BBB plume origin dist from axon, color coded by timing before or after the spike/event 
    edge = [0,5];
    BinEdges = nan(1,2);
    BdistsByTtype = nan(numBins,2);
    for bin = 1:numBins
        % determine bin edges 
        BinEdges(bin,:) = edge;
        edge = edge+[5,5];
        for mouse = 1:mouseNum   
            % sort data into bins organized by axon type (listener,
            % controller, both) 
            if mouse == 1 
                for tType = 1:2
                    if tType == 1 % before event/spike
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end 
                        BdistsByTtype(bin,tType) = sum(reshpdAvClocFrame{mouse}(c) < 0);
                    elseif tType == 2 % after event/spike 
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end
                        BdistsByTtype(bin,tType) = sum(reshpdAvClocFrame{mouse}(c) >= 0);
                    end                 
                end                   
            elseif mouse > 1 
                for tType = 1:2
                    if tType == 1 % before event/spike
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end
                        data = sum(reshpdAvClocFrame{mouse}(c) < 0);
                        BdistsByTtype(bin,tType) = data + BdistsByTtype(bin,tType);
                    elseif tType == 2 % after event/spike  
                        [~, c] = find(BAdists{mouse} > BinEdges(bin,1) & BAdists{mouse} <= BinEdges(bin,2));
                        if sizeQhist == 1
                            [r, ~] = find(any(downAllAxonsClustSizeTS{mouse} >= histSizeThresh,2));
                            c = intersect(c,r);
                        end
                        data = sum(reshpdAvClocFrame{mouse}(c) >= 0);
                        BdistsByTtype(bin,tType) = data + BdistsByTtype(bin,tType);
                    end                 
                end                 
            end 
        end 
    end 
    % plot distribution of BBB plume origin dist from axon, color coded by timing before or after the spike/event 
    figure;
    ax=gca;
    ba = bar(BdistsByTtype,'stacked','FaceColor','flat');
    bar2Clr = hsv(2);
    ba(1).CData = bar2Clr(1,:);
    ba(2).CData = bar2Clr(2,:);
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    if sizeQhist == 1
        titleLabel = sprintf('BBB Plumes that exceed %d',histSizeThresh);
        title({'Distribution of BBB Plume Origin Distance from Axon';titleLabel});
    elseif sizeQhist == 0
        title({'Distribution of BBB Plume Origin Distance from Axon'});
    end 
    ylabel("Number of BBB Plumes")
    xlabel("Distance (microns)") 
    legend("Before 0 sec","After 0 sec")
    set(gca,'XTick',minBAdist:3:maxBAdist)
    xticks = get(gca,'xtick'); 
    x = minBAdist:10:maxBAdist; %#ok<NASGU>
    scaling  = 5;
    newlabels = arrayfun(@(x) sprintf('%.0f', scaling * x), xticks, 'un', 0);
    set(gca,'xticklabel',newlabels)
end 

%% plot 3D scatter plots showing relationships between 
% 1) axon distance from vessel, BBB plume distance from axon, time 
% 2) axon distance from vessel, BBB plume distance from axon, average BBB plume
% size 
% 3) axon distance from vessel, BBB plume distance from axon, max BBB plume
% size
% 4) axon distance from vessel, BBB plume distance from axon, average BBB plume pixel amplitude  
% 5) axon distance from vessel, BBB plume distance from axon, max BBB plume pixel amplitude 
if ETAorSTAq == 0 % STA data 
    clearvars VAdistBAdistCloc resrtdClustSize VAdistBAdistClocThresh VAdistBAdistClocBefore VAdistBAdistClocAfter VAdistBAdistCampThresh VAdistBAdistCampBefore VAdistBAdistCampAfter VAdistBAdistCampMaxThresh VAdistBAdistCsizeMaxBefore VAdistBAdistCsizeMaxAfter VAdistBAdistCsizeMaxThresh VAdistBAdistCsizeMax VAdistBAdistCampMax VAdistBAdistCampMaxThresh VAdistBAdistCampMaxBefore VAdistBAdistCampMaxAfter VAdistBAdistCamp VAdistBAdistCampThresh VAdistBAdistCampBefore VAdistBAdistCampAfter VAdistBAdistCsizeThresh
    minVAdistsPerC = cell(1,mouseNum);
    resrtdClustSize = cell(1,mouseNum);
    resrtdClustAmp = cell(1,mouseNum);
    % add in option to threshold by size 
    scatter3DClustSizeQ = input('Input 1 to set a BBB plume size threshold for the scatter plot. Input 0 to set time (0 sec) threshold. ');
    if scatter3DClustSizeQ == 1 
        scatter3DClustSizeThresh = input('Input the BBB plume size threshold (microns) for the 3D scatter plot. ');
    end 
    for mouse = 1:mouseNum
        % create a version of minVAdists where axon dist to vessel is given per
        % cluster (use axonInds)
        for clust = 1:length(axonInds{mouse})
            minVAdistsPerC{mouse}(clust) = minVAdists{mouse}(axonInds{mouse}(clust));
        end 
%        resort average cluster size (collapsed across time)
        for ccell = 1:size(clustSize{mouse},1)
            if ccell == 1 
                resrtdClustSize{mouse} = clustSize{mouse}(ccell,(~isnan(clustSize{mouse}(ccell,:))));
                resrtdClustAmp{mouse} = clustAmp{mouse}(ccell,(~isnan(clustAmp{mouse}(ccell,:))));
            elseif ccell > 1 
                len = length(resrtdClustSize{mouse});
                resrtdClustSize{mouse}(len+1:len+length(clustSize{mouse}(ccell,(~isnan(clustSize{mouse}(ccell,:)))))) = clustSize{mouse}(ccell,(~isnan(clustSize{mouse}(ccell,:))));
                resrtdClustAmp{mouse}(len+1:len+length(clustAmp{mouse}(ccell,(~isnan(clustAmp{mouse}(ccell,:)))))) = clustAmp{mouse}(ccell,(~isnan(clustAmp{mouse}(ccell,:))));
            end 
        end 
        % sort data for 3D scatter plot 
        if mouse == 1
            VAdistBAdistCloc(:,1) = minVAdistsPerC{mouse};
            VAdistBAdistCloc(:,2) = BAdists{mouse};
            VAdistBAdistCloc(:,3) = reshpdAvClocFrame{mouse};
        elseif mouse > 1 
            len = size(VAdistBAdistCloc,1);
            VAdistBAdistCloc(len+1:len+length(minVAdistsPerC{mouse}),1) = minVAdistsPerC{mouse};
            VAdistBAdistCloc(len+1:len+length(minVAdistsPerC{mouse}),2) = BAdists{mouse};
            VAdistBAdistCloc(len+1:len+length(minVAdistsPerC{mouse}),3) = reshpdAvClocFrame{mouse};        
        end 
        if scatter3DClustSizeQ == 1 % size threshold 
            % figure out what clusters meet the size threshold 
            theseClusts = any(downAllAxonsClustSizeTS{mouse} >= scatter3DClustSizeThresh,2);
            if mouse == 1
                VAdistBAdistClocThresh(:,1) = minVAdistsPerC{mouse}(theseClusts);
                VAdistBAdistClocThresh(:,2) = BAdists{mouse}(theseClusts);
                VAdistBAdistClocThresh(:,3) = reshpdAvClocFrame{mouse}(theseClusts);
            elseif mouse > 1 
                len = size(VAdistBAdistCloc,1);
                VAdistBAdistClocThresh(len+1:len+length(minVAdistsPerC{mouse}(theseClusts)),1) = minVAdistsPerC{mouse}(theseClusts);
                VAdistBAdistClocThresh(len+1:len+length(minVAdistsPerC{mouse}(theseClusts)),2) = BAdists{mouse}(theseClusts);
                VAdistBAdistClocThresh(len+1:len+length(minVAdistsPerC{mouse}(theseClusts)),3) = reshpdAvClocFrame{mouse}(theseClusts);        
            end 
        elseif scatter3DClustSizeQ == 0 % time (before or after 0 sec)
            clr = hsv(2);
            if mouse == 1
                VAdistBAdistClocBefore(:,1) = minVAdistsPerC{mouse}(beforeLoc{mouse});
                VAdistBAdistClocBefore(:,2) = BAdists{mouse}(beforeLoc{mouse});
                VAdistBAdistClocBefore(:,3) = reshpdAvClocFrame{mouse}(beforeLoc{mouse});
                VAdistBAdistClocAfter(:,1) = minVAdistsPerC{mouse}(afterLoc{mouse});
                VAdistBAdistClocAfter(:,2) = BAdists{mouse}(afterLoc{mouse});
                VAdistBAdistClocAfter(:,3) = reshpdAvClocFrame{mouse}(afterLoc{mouse});
            elseif mouse > 1 
                len = size(VAdistBAdistClocBefore,1);
                VAdistBAdistClocBefore(len+1:len+length(minVAdistsPerC{mouse}(beforeLoc{mouse})),1) = minVAdistsPerC{mouse}(beforeLoc{mouse});
                VAdistBAdistClocBefore(len+1:len+length(minVAdistsPerC{mouse}(beforeLoc{mouse})),2) = BAdists{mouse}(beforeLoc{mouse});
                VAdistBAdistClocBefore(len+1:len+length(minVAdistsPerC{mouse}(beforeLoc{mouse})),3) = reshpdAvClocFrame{mouse}(beforeLoc{mouse});    
                len2 = size(VAdistBAdistClocAfter,1);
                VAdistBAdistClocAfter(len2+1:len2+length(minVAdistsPerC{mouse}(afterLoc{mouse})),1) = minVAdistsPerC{mouse}(afterLoc{mouse});
                VAdistBAdistClocAfter(len2+1:len2+length(minVAdistsPerC{mouse}(afterLoc{mouse})),2) = BAdists{mouse}(afterLoc{mouse});
                VAdistBAdistClocAfter(len2+1:len2+length(minVAdistsPerC{mouse}(afterLoc{mouse})),3) = reshpdAvClocFrame{mouse}(afterLoc{mouse}); 
            end         
        end 
    end 
    % plot scatter plot of axon distance from vessel (minVAdists), BBB plume distance from axon, time
    figure;
    ax = gca;
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    scatter3(VAdistBAdistCloc(:,1),VAdistBAdistCloc(:,2),VAdistBAdistCloc(:,3),'filled')
    if scatter3DClustSizeQ == 1 
        hold on;
        ThreshLegLabel1 = sprintf('BBB Plumes < %d microns squared.',scatter3DClustSizeThresh);
        ThreshLegLabel2 = sprintf('BBB Plumes >= %d microns squared.',scatter3DClustSizeThresh);
        scatter3(VAdistBAdistClocThresh(:,1),VAdistBAdistClocThresh(:,2),VAdistBAdistClocThresh(:,3),'filled')
        legend(ThreshLegLabel1,ThreshLegLabel2)
    elseif scatter3DClustSizeQ == 0 
        hold on;
        scatter3(VAdistBAdistClocBefore(:,1),VAdistBAdistClocBefore(:,2),VAdistBAdistClocBefore(:,3),'filled','MarkerFaceColor',clr(1,:))
        scatter3(VAdistBAdistClocAfter(:,1),VAdistBAdistClocAfter(:,2),VAdistBAdistClocAfter(:,3),'filled','MarkerFaceColor',clr(2,:))
        legend('','Pre-Spike Clusters','Post-Spike Clusters')
    end 
    xlabel('Axon Distance from Vessel (microns)')
    ylabel('BBB Plume Distance from Axon (microns)')
    zlabel('Time (sec)')

    % resort timeODistArray{mouse}(:,2) to look like BAdists, label
    % it BAdists, comment this out, rerun above code, don't save
    % this data (this is just for a specific figure for now! will code
    % better later) 
    % BAdists = cell(1,mouseNum);
    % for mouse = 1:mouseNum
    %     BAdists{mouse} = timeODistArray{mouse}(~isnan(timeODistArray{mouse}(:,1)),2);
    % end 

    % below code plots 2D scatter plot of plume origin distance from axon (x) over
    % time (y) with regression lines for pre vs post spike data points 
    % (for committee meeting)     
    figure;
    scatter(VAdistBAdistCloc(:,2),VAdistBAdistCloc(:,3),'filled')
    if scatter3DClustSizeQ == 1 
        hold on;
        ThreshLegLabel1 = sprintf('BBB Plumes < %d microns squared.',scatter3DClustSizeThresh);
        ThreshLegLabel2 = sprintf('BBB Plumes >= %d microns squared.',scatter3DClustSizeThresh);
        scatter(VAdistBAdistClocThresh(:,2),VAdistBAdistClocThresh(:,3),'filled')
        legend(ThreshLegLabel1,ThreshLegLabel2)
    elseif scatter3DClustSizeQ == 0 
        % determine the trend lines we want 
        fBefore = fitlm(VAdistBAdistClocBefore(:,2),VAdistBAdistClocBefore(:,3),'quadratic');
        fAfter = fitlm(VAdistBAdistClocAfter(:,2),VAdistBAdistClocAfter(:,3),'quadratic');
        % plot scatter
        hold on;
        ax = gca;
        ax.FontSize = 15;
        ax.FontName = 'Arial';
        scatter(VAdistBAdistClocBefore(:,2),VAdistBAdistClocBefore(:,3),'filled','MarkerFaceColor',clr(1,:))
        scatter(VAdistBAdistClocAfter(:,2),VAdistBAdistClocAfter(:,3),'filled','MarkerFaceColor',clr(2,:))
        % plot trend line
        % fitHandle = plot(fBefore);
        % leg = legend('show');
        % set(fitHandle,'Color',clr(1,:),'LineWidth',3);
        % leg.String(end) = [];
        % rSquaredB = string(round(fBefore.Rsquared.Ordinary,2));
        % text(400,-2,rSquaredB,'FontSize',20,'Color',clr(1,:))
        % fitHandle = plot(fAfter);
        % leg = legend('show');
        % set(fitHandle,'Color',clr(2,:),'LineWidth',3);
        % leg.String(end) = [];
        % rSquaredA = string(round(fAfter.Rsquared.Ordinary,2));
        % text(400,2,rSquaredA,'FontSize',20,'Color',clr(2,:))
        legend('','Pre-Spike Clusters','Post-Spike Clusters')
        title('')
    end 
    xlabel('BBB Plume Distance from Axon (microns)')
    ylabel('Time (sec)')
    set(gca, 'xscale','log') 

    logQ = input('Input 1 to plot BBB plume pixel amplitude and size on log scale. ');
    % plot scatter plot of axon distance from vessel, BBB plume distance from axon, average BBB plume
    % size 
    clearvars VAdistBAdistCsize VAdistBAdistCsizeBefore VAdistBAdistCsizeAfter
    for mouse = 1:mouseNum
        % sort data for 3D scatter plot 
        if mouse == 1
            VAdistBAdistCsize(:,1) = minVAdistsPerC{mouse};
            VAdistBAdistCsize(:,2) = BAdists{mouse};
            VAdistBAdistCsize(:,3) = resrtdClustSize{mouse};
        elseif mouse > 1 
            len = size(VAdistBAdistCsize,1);
            VAdistBAdistCsize(len+1:len+length(minVAdistsPerC{mouse}),1) = minVAdistsPerC{mouse};
            VAdistBAdistCsize(len+1:len+length(minVAdistsPerC{mouse}),2) = BAdists{mouse};
            VAdistBAdistCsize(len+1:len+length(minVAdistsPerC{mouse}),3) = resrtdClustSize{mouse};        
        end 
        if scatter3DClustSizeQ == 1 % size threshold 
            % sort data using the size threshold 
            % figure out what clusters meet the size threshold 
            theseClusts = any(downAllAxonsClustSizeTS{mouse} >= scatter3DClustSizeThresh,2);
            if mouse == 1
                VAdistBAdistCsizeThresh(:,1) = minVAdistsPerC{mouse}(theseClusts);
                VAdistBAdistCsizeThresh(:,2) = BAdists{mouse}(theseClusts);
                VAdistBAdistCsizeThresh(:,3) =  resrtdClustSize{mouse}(theseClusts);
            elseif mouse > 1 
                len = size(VAdistBAdistCsizeThresh,1);
                VAdistBAdistCsizeThresh(len+1:len+length(minVAdistsPerC{mouse}(theseClusts)),1) = minVAdistsPerC{mouse}(theseClusts);
                VAdistBAdistCsizeThresh(len+1:len+length(minVAdistsPerC{mouse}(theseClusts)),2) = BAdists{mouse}(theseClusts);
                VAdistBAdistCsizeThresh(len+1:len+length(minVAdistsPerC{mouse}(theseClusts)),3) =  resrtdClustSize{mouse}(theseClusts);        
            end 
        elseif scatter3DClustSizeQ == 0 % time (before or after 0 sec)
            if mouse == 1
                VAdistBAdistCsizeBefore(:,1) = minVAdistsPerC{mouse}(beforeLoc{mouse});
                VAdistBAdistCsizeBefore(:,2) = BAdists{mouse}(beforeLoc{mouse});
                VAdistBAdistCsizeBefore(:,3) =  resrtdClustSize{mouse}(beforeLoc{mouse});
                VAdistBAdistCsizeAfter(:,1) = minVAdistsPerC{mouse}(afterLoc{mouse});
                VAdistBAdistCsizeAfter(:,2) = BAdists{mouse}(afterLoc{mouse});
                VAdistBAdistCsizeAfter(:,3) =  resrtdClustSize{mouse}(afterLoc{mouse});
            elseif mouse > 1 
                len = size(VAdistBAdistCsizeBefore,1);
                VAdistBAdistCsizeBefore(len+1:len+length(minVAdistsPerC{mouse}(beforeLoc{mouse})),1) = minVAdistsPerC{mouse}(beforeLoc{mouse});
                VAdistBAdistCsizeBefore(len+1:len+length(minVAdistsPerC{mouse}(beforeLoc{mouse})),2) = BAdists{mouse}(beforeLoc{mouse});
                VAdistBAdistCsizeBefore(len+1:len+length(minVAdistsPerC{mouse}(beforeLoc{mouse})),3) =  resrtdClustSize{mouse}(beforeLoc{mouse});    
                len2 = size(VAdistBAdistCsizeAfter,1);
                VAdistBAdistCsizeAfter(len2+1:len2+length(minVAdistsPerC{mouse}(afterLoc{mouse})),1) = minVAdistsPerC{mouse}(afterLoc{mouse});
                VAdistBAdistCsizeAfter(len2+1:len2+length(minVAdistsPerC{mouse}(afterLoc{mouse})),2) = BAdists{mouse}(afterLoc{mouse});
                VAdistBAdistCsizeAfter(len2+1:len2+length(minVAdistsPerC{mouse}(afterLoc{mouse})),3) =  resrtdClustSize{mouse}(afterLoc{mouse}); 
            end  
        end 
    end 
    figure;
    ax = gca;
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    scatter3(VAdistBAdistCsize(:,1),VAdistBAdistCsize(:,2),VAdistBAdistCsize(:,3),'filled')
    if scatter3DClustSizeQ == 1 
        hold on;
        scatter3(VAdistBAdistCsizeThresh(:,1),VAdistBAdistCsizeThresh(:,2),VAdistBAdistCsizeThresh(:,3),'filled')
        legend(ThreshLegLabel1,ThreshLegLabel2)
    elseif scatter3DClustSizeQ == 0  
        hold on;
        scatter3(VAdistBAdistCsizeBefore(:,1),VAdistBAdistCsizeBefore(:,2),VAdistBAdistCsizeBefore(:,3),'filled','MarkerFaceColor',clr(1,:))
        scatter3(VAdistBAdistCsizeAfter(:,1),VAdistBAdistCsizeAfter(:,2),VAdistBAdistCsizeAfter(:,3),'filled','MarkerFaceColor',clr(2,:))
        legend('','Pre-Spike Clusters','Post-Spike Clusters')
    end 
    xlabel('Axon Distance from Vessel (microns)')
    ylabel('BBB Plume Distance from Axon (microns)')
    zlabel('Average BBB Plume Size (microns squared)')
    if logQ == 1 
        set(gca, 'xscale','log')   
        set(gca, 'yscale','log') 
    end 
    
    % plot scatter plot of axon distance from vessel, BBB plume distance from
    % axon, max plume size 
    maxSize = cell(1,mouseNum);
    for mouse = 1:mouseNum
        % determine the maximum cluster size 
        for ccell = 1:size(downAllAxonsClustSizeTS{mouse},1)
            maxSize{mouse} = (max(downAllAxonsClustSizeTS{mouse},[],2))';
        end 
        % sort data for 3D scatter plot 
        if mouse == 1
            VAdistBAdistCsizeMax(:,1) = minVAdistsPerC{mouse};
            VAdistBAdistCsizeMax(:,2) = BAdists{mouse};
            VAdistBAdistCsizeMax(:,3) = maxSize{mouse};
        elseif mouse > 1 
            len = size(VAdistBAdistCsizeMax,1);
            VAdistBAdistCsizeMax(len+1:len+length(minVAdistsPerC{mouse}),1) = minVAdistsPerC{mouse};
            VAdistBAdistCsizeMax(len+1:len+length(minVAdistsPerC{mouse}),2) = BAdists{mouse};
            VAdistBAdistCsizeMax(len+1:len+length(minVAdistsPerC{mouse}),3) = maxSize{mouse};        
        end 
        if scatter3DClustSizeQ == 1 % size threshold 
            % sort data using the size threshold 
            % figure out what clusters meet the size threshold 
            theseClusts = any(downAllAxonsClustSizeTS{mouse} >= scatter3DClustSizeThresh,2);
            if mouse == 1
                VAdistBAdistCsizeMaxThresh(:,1) = minVAdistsPerC{mouse}(theseClusts);
                VAdistBAdistCsizeMaxThresh(:,2) = BAdists{mouse}(theseClusts);
                VAdistBAdistCsizeMaxThresh(:,3) = maxSize{mouse}(theseClusts);
            elseif mouse > 1 
                len = size(VAdistBAdistCsizeMaxThresh,1);
                VAdistBAdistCsizeMaxThresh(len+1:len+length(minVAdistsPerC{mouse}(theseClusts)),1) = minVAdistsPerC{mouse}(theseClusts);
                VAdistBAdistCsizeMaxThresh(len+1:len+length(minVAdistsPerC{mouse}(theseClusts)),2) = BAdists{mouse}(theseClusts);
                VAdistBAdistCsizeMaxThresh(len+1:len+length(minVAdistsPerC{mouse}(theseClusts)),3) = maxSize{mouse}(theseClusts);        
            end 
        elseif scatter3DClustSizeQ == 0 % time (before or after 0 sec)
            if mouse == 1
                VAdistBAdistCsizeMaxBefore(:,1) = minVAdistsPerC{mouse}(beforeLoc{mouse});
                VAdistBAdistCsizeMaxBefore(:,2) = BAdists{mouse}(beforeLoc{mouse});
                VAdistBAdistCsizeMaxBefore(:,3) = maxSize{mouse}(beforeLoc{mouse});
                VAdistBAdistCsizeMaxAfter(:,1) = minVAdistsPerC{mouse}(afterLoc{mouse});
                VAdistBAdistCsizeMaxAfter(:,2) = BAdists{mouse}(afterLoc{mouse});
                VAdistBAdistCsizeMaxAfter(:,3) = maxSize{mouse}(afterLoc{mouse});
            elseif mouse > 1 
                len = size(VAdistBAdistCsizeMaxBefore,1);
                VAdistBAdistCsizeMaxBefore(len+1:len+length(minVAdistsPerC{mouse}(beforeLoc{mouse})),1) = minVAdistsPerC{mouse}(beforeLoc{mouse});
                VAdistBAdistCsizeMaxBefore(len+1:len+length(minVAdistsPerC{mouse}(beforeLoc{mouse})),2) = BAdists{mouse}(beforeLoc{mouse});
                VAdistBAdistCsizeMaxBefore(len+1:len+length(minVAdistsPerC{mouse}(beforeLoc{mouse})),3) = maxSize{mouse}(beforeLoc{mouse});    
                len2 = size(VAdistBAdistCsizeMaxAfter,1);
                VAdistBAdistCsizeMaxAfter(len2+1:len2+length(minVAdistsPerC{mouse}(afterLoc{mouse})),1) = minVAdistsPerC{mouse}(afterLoc{mouse});
                VAdistBAdistCsizeMaxAfter(len2+1:len2+length(minVAdistsPerC{mouse}(afterLoc{mouse})),2) = BAdists{mouse}(afterLoc{mouse});
                VAdistBAdistCsizeMaxAfter(len2+1:len2+length(minVAdistsPerC{mouse}(afterLoc{mouse})),3) = maxSize{mouse}(afterLoc{mouse}); 
            end  
        end 
    end 
    figure;
    ax = gca;
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    scatter3(VAdistBAdistCsizeMax(:,1),VAdistBAdistCsizeMax(:,2),VAdistBAdistCsizeMax(:,3),'filled')
    xlabel('Axon Distance from Vessel (microns)')
    ylabel('BBB Plume Distance from Axon (microns)')
    zlabel('Maximum BBB Plume Size (microns squared)')
    if scatter3DClustSizeQ == 1 
        hold on;
        scatter3(VAdistBAdistCsizeMaxThresh(:,1),VAdistBAdistCsizeMaxThresh(:,2),VAdistBAdistCsizeMaxThresh(:,3),'filled')
        legend(ThreshLegLabel1,ThreshLegLabel2)
    elseif scatter3DClustSizeQ == 0 
        hold on;
        scatter3(VAdistBAdistCsizeMaxBefore(:,1),VAdistBAdistCsizeMaxBefore(:,2),VAdistBAdistCsizeMaxBefore(:,3),'filled','MarkerFaceColor',clr(1,:))
        scatter3(VAdistBAdistCsizeMaxAfter(:,1),VAdistBAdistCsizeMaxAfter(:,2),VAdistBAdistCsizeMaxAfter(:,3),'filled','MarkerFaceColor',clr(2,:))
        legend('','Pre-Spike Clusters','Post-Spike Clusters')
    end 
    if logQ == 1 
        set(gca, 'xscale','log')   
        set(gca, 'yscale','log')  
    end 
    
    % plot scatter plot of axon distance from vessel, BBB plume distance from
    % axon, average BBB plume pixel amplitude 
    for mouse = 1:mouseNum
        % sort data for 3D scatter plot 
        if mouse == 1
            VAdistBAdistCamp(:,1) = minVAdistsPerC{mouse};
            VAdistBAdistCamp(:,2) = BAdists{mouse};
            VAdistBAdistCamp(:,3) = resrtdClustAmp{mouse};
        elseif mouse > 1 
            len = size(VAdistBAdistCamp,1);
            VAdistBAdistCamp(len+1:len+length(minVAdistsPerC{mouse}),1) = minVAdistsPerC{mouse};
            VAdistBAdistCamp(len+1:len+length(minVAdistsPerC{mouse}),2) = BAdists{mouse};
            VAdistBAdistCamp(len+1:len+length(minVAdistsPerC{mouse}),3) = resrtdClustAmp{mouse};        
        end 
        if scatter3DClustSizeQ == 1 % size threshold 
            % sort data using the size threshold 
            % figure out what clusters meet the size threshold 
            theseClusts = any(downAllAxonsClustSizeTS{mouse} >= scatter3DClustSizeThresh,2);
            if mouse == 1
                VAdistBAdistCampThresh(:,1) = minVAdistsPerC{mouse}(theseClusts);
                VAdistBAdistCampThresh(:,2) = BAdists{mouse}(theseClusts);
                VAdistBAdistCampThresh(:,3) = resrtdClustAmp{mouse}(theseClusts);
            elseif mouse > 1 
                len = size(VAdistBAdistCampThresh,1);
                VAdistBAdistCampThresh(len+1:len+length(minVAdistsPerC{mouse}(theseClusts)),1) = minVAdistsPerC{mouse}(theseClusts);
                VAdistBAdistCampThresh(len+1:len+length(minVAdistsPerC{mouse}(theseClusts)),2) = BAdists{mouse}(theseClusts);
                VAdistBAdistCampThresh(len+1:len+length(minVAdistsPerC{mouse}(theseClusts)),3) = resrtdClustAmp{mouse}(theseClusts);        
            end 
        elseif scatter3DClustSizeQ == 0 % time (before or after 0 sec)
            if mouse == 1
                VAdistBAdistCampBefore(:,1) = minVAdistsPerC{mouse}(beforeLoc{mouse});
                VAdistBAdistCampBefore(:,2) = BAdists{mouse}(beforeLoc{mouse});
                VAdistBAdistCampBefore(:,3) = resrtdClustAmp{mouse}(beforeLoc{mouse});
                VAdistBAdistCampAfter(:,1) = minVAdistsPerC{mouse}(afterLoc{mouse});
                VAdistBAdistCampAfter(:,2) = BAdists{mouse}(afterLoc{mouse});
                VAdistBAdistCampAfter(:,3) = resrtdClustAmp{mouse}(afterLoc{mouse});
            elseif mouse > 1 
                len = size(VAdistBAdistCampBefore,1);
                VAdistBAdistCampBefore(len+1:len+length(minVAdistsPerC{mouse}(beforeLoc{mouse})),1) = minVAdistsPerC{mouse}(beforeLoc{mouse});
                VAdistBAdistCampBefore(len+1:len+length(minVAdistsPerC{mouse}(beforeLoc{mouse})),2) = BAdists{mouse}(beforeLoc{mouse});
                VAdistBAdistCampBefore(len+1:len+length(minVAdistsPerC{mouse}(beforeLoc{mouse})),3) = resrtdClustAmp{mouse}(beforeLoc{mouse});    
                len2 = size(VAdistBAdistCampAfter,1);
                VAdistBAdistCampAfter(len2+1:len2+length(minVAdistsPerC{mouse}(afterLoc{mouse})),1) = minVAdistsPerC{mouse}(afterLoc{mouse});
                VAdistBAdistCampAfter(len2+1:len2+length(minVAdistsPerC{mouse}(afterLoc{mouse})),2) = BAdists{mouse}(afterLoc{mouse});
                VAdistBAdistCampAfter(len2+1:len2+length(minVAdistsPerC{mouse}(afterLoc{mouse})),3) = resrtdClustAmp{mouse}(afterLoc{mouse}); 
            end  
        end 
    end 
    figure;
    ax = gca;
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    scatter3(VAdistBAdistCamp(:,1),VAdistBAdistCamp(:,2),VAdistBAdistCamp(:,3),'filled')
    xlabel('Axon Distance from Vessel (microns)')
    ylabel('BBB Plume Distance from Axon (microns)')
    zlabel('Average BBB Plume Pixel Amplitude')
    if scatter3DClustSizeQ == 1 
        hold on;
        scatter3(VAdistBAdistCampThresh(:,1),VAdistBAdistCampThresh(:,2),VAdistBAdistCampThresh(:,3),'filled')
        legend(ThreshLegLabel1,ThreshLegLabel2)
    elseif scatter3DClustSizeQ == 0 
        hold on;
        scatter3(VAdistBAdistCampBefore(:,1),VAdistBAdistCampBefore(:,2),VAdistBAdistCampBefore(:,3),'filled','MarkerFaceColor',clr(1,:))
        scatter3(VAdistBAdistCampAfter(:,1),VAdistBAdistCampAfter(:,2),VAdistBAdistCampAfter(:,3),'filled','MarkerFaceColor',clr(2,:))
        legend('','Pre-Spike Clusters','Post-Spike Clusters')
    end 
    if logQ == 1 
        set(gca, 'xscale','log')   
        set(gca, 'yscale','log')   
    end 
    
    % plot scatter plot of axon distance from vessel, BBB plume distance from
    % axon, max BBB plume pixel amplitude 
    clearvars VAdistBAdistCampMax 
    maxClustAmp = cell(1,mouseNum);
    for mouse = 1:mouseNum
        % determine the maximum cluster amp
        for ccell = 1:size(downAllAxonsClustAmpTS{mouse},1)
            maxClustAmp{mouse} = (max(downAllAxonsClustAmpTS{mouse},[],2))';
        end 
        % sort data for 3D scatter plot 
        if mouse == 1
            VAdistBAdistCampMax(:,1) = minVAdistsPerC{mouse};
            VAdistBAdistCampMax(:,2) = BAdists{mouse};
            VAdistBAdistCampMax(:,3) = maxClustAmp{mouse};
        elseif mouse > 1 
            len = size(VAdistBAdistCamp,1);
            VAdistBAdistCampMax(len+1:len+length(minVAdistsPerC{mouse}),1) = minVAdistsPerC{mouse};
            VAdistBAdistCampMax(len+1:len+length(minVAdistsPerC{mouse}),2) = BAdists{mouse};
            VAdistBAdistCampMax(len+1:len+length(minVAdistsPerC{mouse}),3) = maxClustAmp{mouse};        
        end 
        if scatter3DClustSizeQ == 1 % size threshold 
            % sort data using the size threshold 
            % figure out what clusters meet the size threshold 
            theseClusts = any(downAllAxonsClustSizeTS{mouse} >= scatter3DClustSizeThresh,2);
            if mouse == 1
                VAdistBAdistCampMaxThresh(:,1) = minVAdistsPerC{mouse}(theseClusts);
                VAdistBAdistCampMaxThresh(:,2) = BAdists{mouse}(theseClusts);
                VAdistBAdistCampMaxThresh(:,3) = maxClustAmp{mouse}(theseClusts);
            elseif mouse > 1 
                len = size(VAdistBAdistCampMaxThresh,1);
                VAdistBAdistCampMaxThresh(len+1:len+length(minVAdistsPerC{mouse}(theseClusts)),1) = minVAdistsPerC{mouse}(theseClusts);
                VAdistBAdistCampMaxThresh(len+1:len+length(minVAdistsPerC{mouse}(theseClusts)),2) = BAdists{mouse}(theseClusts);
                VAdistBAdistCampMaxThresh(len+1:len+length(minVAdistsPerC{mouse}(theseClusts)),3) = maxClustAmp{mouse}(theseClusts);        
            end 
        elseif scatter3DClustSizeQ == 0 % time (before or after 0 sec)
            if mouse == 1
                VAdistBAdistCampMaxBefore(:,1) = minVAdistsPerC{mouse}(beforeLoc{mouse});
                VAdistBAdistCampMaxBefore(:,2) = BAdists{mouse}(beforeLoc{mouse});
                VAdistBAdistCampMaxBefore(:,3) = maxClustAmp{mouse}(beforeLoc{mouse});
                VAdistBAdistCampMaxAfter(:,1) = minVAdistsPerC{mouse}(afterLoc{mouse});
                VAdistBAdistCampMaxAfter(:,2) = BAdists{mouse}(afterLoc{mouse});
                VAdistBAdistCampMaxAfter(:,3) = maxClustAmp{mouse}(afterLoc{mouse});
            elseif mouse > 1 
                len = size(VAdistBAdistCampMaxBefore,1);
                VAdistBAdistCampMaxBefore(len+1:len+length(minVAdistsPerC{mouse}(beforeLoc{mouse})),1) = minVAdistsPerC{mouse}(beforeLoc{mouse});
                VAdistBAdistCampMaxBefore(len+1:len+length(minVAdistsPerC{mouse}(beforeLoc{mouse})),2) = BAdists{mouse}(beforeLoc{mouse});
                VAdistBAdistCampMaxBefore(len+1:len+length(minVAdistsPerC{mouse}(beforeLoc{mouse})),3) = maxClustAmp{mouse}(beforeLoc{mouse});    
                len2 = size(VAdistBAdistCampMaxAfter,1);
                VAdistBAdistCampMaxAfter(len2+1:len2+length(minVAdistsPerC{mouse}(afterLoc{mouse})),1) = minVAdistsPerC{mouse}(afterLoc{mouse});
                VAdistBAdistCampMaxAfter(len2+1:len2+length(minVAdistsPerC{mouse}(afterLoc{mouse})),2) = BAdists{mouse}(afterLoc{mouse});
                VAdistBAdistCampMaxAfter(len2+1:len2+length(minVAdistsPerC{mouse}(afterLoc{mouse})),3) = maxClustAmp{mouse}(afterLoc{mouse}); 
            end  
        end 
    end 
    figure;
    ax = gca;
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    scatter3(VAdistBAdistCampMax(:,1),VAdistBAdistCampMax(:,2),VAdistBAdistCampMax(:,3),'filled')
    xlabel('Axon Distance from Vessel (microns)')
    ylabel('BBB Plume Distance from Axon (microns)')
    zlabel('Maximum BBB Plume Pixel Amplitude')
    if scatter3DClustSizeQ == 1 
        hold on;
        scatter3(VAdistBAdistCampMaxThresh(:,1),VAdistBAdistCampMaxThresh(:,2),VAdistBAdistCampMaxThresh(:,3),'filled')
        legend(ThreshLegLabel1,ThreshLegLabel2)
    elseif scatter3DClustSizeQ == 0 
        hold on;
        scatter3(VAdistBAdistCampMaxBefore(:,1),VAdistBAdistCampMaxBefore(:,2),VAdistBAdistCampMaxBefore(:,3),'filled','MarkerFaceColor',clr(1,:))
        scatter3(VAdistBAdistCampMaxAfter(:,1),VAdistBAdistCampMaxAfter(:,2),VAdistBAdistCampMaxAfter(:,3),'filled','MarkerFaceColor',clr(2,:))
        legend('','Pre-Spike Clusters','Post-Spike Clusters')
    end 
    if logQ == 1 
        set(gca, 'xscale','log')   
        set(gca, 'yscale','log')   
    end 
end 

%% plot box and whisker plots of max BBB plume pixel amplitude and size
% grouped by pre and post event/0 sec 
if ETAorSTAq == 1 % ETA data 
    maxSize = cell(1,mouseNum);
    maxClustAmp = cell(1,mouseNum);
    for mouse = 1:mouseNum
        % determine the maximum cluster size 
        maxSize{mouse} = (max(downAllAxonsClustSizeTS{mouse},[],2))';
        % determine the maximum cluster amp
        maxClustAmp{mouse} = (max(downAllAxonsClustAmpTS{mouse},[],2))';
    end 
end 
% determine max number of clusts 
for mouse = 1:mouseNum
    totalNumClusts(mouse) = length(maxSize{mouse});
end 
maxNumClusts = max(totalNumClusts);
% resort maxSize 
allMaxCsizeForPlot = nan(maxNumClusts,mouseNum);
allMaxCampForPlot = nan(maxNumClusts,mouseNum);
allClocFrameForPlot = nan(maxNumClusts,mouseNum);
for mouse = 1:mouseNum 
    if isempty(reshpdAvClocFrame{mouse}) == 0 
        allMaxCsizeForPlot(1:totalNumClusts(mouse),mouse) = maxSize{mouse}; 
        allMaxCampForPlot(1:totalNumClusts(mouse),mouse) = maxClustAmp{mouse}; 
        allClocFrameForPlot(1:totalNumClusts(mouse),mouse) = reshpdAvClocFrame{mouse}; 
    end 
end 
figure;
ax=gca;
% plot box plot 
boxchart(allMaxCsizeForPlot,'MarkerStyle','none');
% create the x data needed to overlay the swarmchart on the boxchart 
x = repmat(1:mouseNum,size(allMaxCsizeForPlot,1),1);
% plot swarm chart on top of box plot 
hold all;
swarmchart(x,allMaxCsizeForPlot,[],'red')  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("Max BBB Plume Size (microns squared)")
xlabel("Mouse")  
title({'Max BBB Plume Size Per Cluster';'All Plumes'});
xticklabels(mouseNumLabelString)
set(gca, 'YScale', 'log')

figure;
ax=gca;
% plot box plot 
boxchart(allMaxCampForPlot,'MarkerStyle','none');
% create the x data needed to overlay the swarmchart on the boxchart 
x = repmat(1:mouseNum,size(allMaxCampForPlot,1),1);
% plot swarm chart on top of box plot 
hold all;
swarmchart(x,allMaxCampForPlot,[],'red')  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("Max BBB Plume Pixel Amplitude")
xlabel("Mouse")  
title({'Max BBB Plume Pixel Amplitude Per Cluster';'All Plumes'});
xticklabels(mouseNumLabelString)

[r,c] = find(allClocFrameForPlot < 0); % find pre event clusters 
% create new variables for pre and post event clusters
PreAllMaxCampForPlot = allMaxCampForPlot; PostAllMaxCampForPlot = allMaxCampForPlot;
PreAllMaxCsizeForPlot = allMaxCsizeForPlot; PostAllMaxCsizeForPlot = allMaxCsizeForPlot;
for clust = 1:length(r)
    PostAllMaxCampForPlot(r(clust),c(clust)) = NaN; PostAllMaxCsizeForPlot(r(clust),c(clust)) = NaN;
end 
[r,c] = find(allClocFrameForPlot >= 0); % find post event clusters 
for clust = 1:length(r)
    PreAllMaxCampForPlot(r(clust),c(clust)) = NaN; PreAllMaxCsizeForPlot(r(clust),c(clust)) = NaN;
end 

figure;
ax=gca;
% plot box plot 
boxchart(PreAllMaxCsizeForPlot,'MarkerStyle','none','BoxFaceColor','r','WhiskerLineColor','r');
% plot swarm chart on top of box plot 
hold all;
boxchart(PostAllMaxCsizeForPlot,'MarkerStyle','none','BoxFaceColor','b','WhiskerLineColor','b');
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("Max BBB Plume Size (microns squared)")
xlabel("Mouse")
if ETAorSTAq == 0 % STA data
    if clustSpikeQ3 == 0 
        title({'Max BBB Plume Size';'Pre And Post Spike Plumes';'Average Cluster Time'});   
    elseif clustSpikeQ3 == 1
        title({'Max BBB Plume Size';'Pre And Post Spike Plumes';'Cluster Start Time'});   
    end          
elseif ETAorSTAq == 1 % ETA data
    if ETAtype == 0 % opto data 
        if clustSpikeQ3 == 0 
            title({'Max BBB Plume Size';'Pre And Post Opto Plumes';'Average Cluster Time'});   
        elseif clustSpikeQ3 == 1
            title({'Max BBB Plume Size';'Pre And Post Opto Plumes';'Cluster Start Time'});   
        end  
    elseif ETAtype == 1 % behavior data 
        if ETAtype2 == 0 % stim aligned 
            if clustSpikeQ3 == 0 
                title({'Max BBB Plume Size';'Pre And Post Stim Plumes';'Average Cluster Time'});   
            elseif clustSpikeQ3 == 1
                title({'Max BBB Plume Size';'Pre And Post Stim Plumes';'Cluster Start Time'});   
            end  
        elseif ETAtype2 == 1 % reward aligned 
            if clustSpikeQ3 == 0 
                title({'Max BBB Plume Size';'Pre And Post Reward Plumes';'Average Cluster Time'});   
            elseif clustSpikeQ3 == 1
                title({'Max BBB Plume Size';'Pre And Post Reward Plumes';'Cluster Start Time'});   
            end                    
        end 
    end 
end 
if ETAorSTAq == 0 % STA data 
    legend("Pre-Spike BBB Plume","Post-Spike BBB Plume")
elseif ETAorSTAq == 1 % ETA data
    if ETAtype == 0 % opto data 
      legend("Pre-Opto BBB Plume","Post-Opto BBB Plume")
    elseif ETAtype == 1 % behavior data 
        if ETAtype2 == 0 % stim aligned 
            legend("Pre-Stim BBB Plume","Post-Stim BBB Plume")
        elseif ETAtype2 == 1 % reward aligned 
            legend("Pre-Reward BBB Plume","Post-Reward BBB Plume")
        end 
    end 
end
xticklabels(mouseNumLabelString)   
set(gca, 'YScale', 'log')

figure;
ax=gca;
% plot box plot 
boxchart(PreAllMaxCampForPlot,'MarkerStyle','none','BoxFaceColor','r','WhiskerLineColor','r');
% plot swarm chart on top of box plot 
hold all;
boxchart(PostAllMaxCampForPlot,'MarkerStyle','none','BoxFaceColor','b','WhiskerLineColor','b');
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("Max BBB Plume Pixel Amplitude")
xlabel("Mouse")
if ETAorSTAq == 0 % STA data
    if clustSpikeQ3 == 0 
        title({'Max BBB Plume Pixel Amplitude';'Pre And Post Spike Plumes';'Average Cluster Time'});   
    elseif clustSpikeQ3 == 1
        title({'Max BBB Plume Pixel Amplitude';'Pre And Post Spike Plumes';'Cluster Start Time'});   
    end          
elseif ETAorSTAq == 1 % ETA data
    if ETAtype == 0 % opto data 
        if clustSpikeQ3 == 0 
            title({'Max BBB Plume Pixel Amplitude';'Pre And Post Opto Plumes';'Average Cluster Time'});   
        elseif clustSpikeQ3 == 1
            title({'Max BBB Plume Pixel Amplitude';'Pre And Post Opto Plumes';'Cluster Start Time'});   
        end      
    elseif ETAtype == 1 % behavior data 
        if ETAtype2 == 0 % stim aligned 
            if clustSpikeQ3 == 0 
                title({'Max BBB Plume Pixel Amplitude';'Pre And Post Stim Plumes';'Average Cluster Time'});   
            elseif clustSpikeQ3 == 1
                title({'Max BBB Plume Pixel Amplitude';'Pre And Post Stim Plumes';'Cluster Start Time'});   
            end    
        elseif ETAtype2 == 1 % reward aligned 
             if clustSpikeQ3 == 0 
                title({'Max BBB Plume Pixel Amplitude';'Pre And Post Reward Plumes';'Average Cluster Time'});   
            elseif clustSpikeQ3 == 1
                title({'Max BBB Plume Pixel Amplitude';'Pre And Post Reward Plumes';'Cluster Start Time'});   
            end                    
        end 
    end 
end 
if ETAorSTAq == 0 % STA data 
    legend("Pre-Spike BBB Plume","Post-Spike BBB Plume")
elseif ETAorSTAq == 1 % ETA data
    if ETAtype == 0 % opto data 
      legend("Pre-Opto BBB Plume","Post-Opto BBB Plume")
    elseif ETAtype == 1 % behavior data 
        if ETAtype2 == 0 % stim aligned 
            legend("Pre-Stim BBB Plume","Post-Stim BBB Plume")
        elseif ETAtype2 == 1 % reward aligned 
            legend("Pre-Reward BBB Plume","Post-Reward BBB Plume")
        end 
    end 
end
xticklabels(mouseNumLabelString) 

clearvars data 
% reshape data for plotting 
dataRsize = size(allMaxCsizeForPlot,1); dataCsize = size(allMaxCsizeForPlot,2);
reshapedPre = reshape(PreAllMaxCsizeForPlot,dataRsize*dataCsize,1);
reshapedPost = reshape(PostAllMaxCsizeForPlot,dataRsize*dataCsize,1);
data(:,1) = reshapedPre; data(:,2) = reshapedPost; 
figure;
ax=gca;
% plot box plot 
boxchart(data,'MarkerStyle','none','BoxFaceColor','k','WhiskerLineColor','k');
% plot swarm chart on top of box plot 
hold all;
x = repmat(1:size(data,2),size(data,1),1);
swarmchart(x,data,[],'red') 
% boxchart(reshapedPostPlot,'MarkerStyle','none','BoxFaceColor','b','WhiskerLineColor','b');
ax.FontSize = 15;
ax.FontName = 'Arial';
ylabel("Max BBB Plume Size (microns squared)") 
if ETAorSTAq == 0 % STA data
    if clustSpikeQ3 == 0 
        title({'Max BBB Plume Size Across Animals';'Pre And Post Spike Plumes';'Average Cluster Time'});  
    elseif clustSpikeQ3 == 1
        title({'Max BBB Plume Size Across Animals';'Pre And Post Spike Plumes';'Cluster Start Time'});  
    end     
elseif ETAorSTAq == 1 % ETA data
    if ETAtype == 0 % opto data 
        if clustSpikeQ3 == 0 
            title({'Max BBB Plume Size Across Animals';'Pre And Post Opto Plumes';'Average Cluster Time'});  
        elseif clustSpikeQ3 == 1
            title({'Max BBB Plume Size Across Animals';'Pre And Post Opto Plumes';'Cluster Start Time'});  
        end    
    elseif ETAtype == 1 % behavior data 
        if ETAtype2 == 0 % stim aligned 
            if clustSpikeQ3 == 0 
                title({'Max BBB Plume Size Across Animals';'Pre And Post Stim Plumes';'Average Cluster Time'});  
            elseif clustSpikeQ3 == 1
                title({'Max BBB Plume Size Across Animals';'Pre And Post Stim Plumes';'Cluster Start Time'});  
            end  
        elseif ETAtype2 == 1 % reward aligned 
             if clustSpikeQ3 == 0 
                title({'Max BBB Plume Size Across Animals';'Pre And Post Reward Plumes';'Average Cluster Time'});  
            elseif clustSpikeQ3 == 1
                title({'Max BBB Plume Size Across Animals';'Pre And Post Reward Plumes';'Cluster Start Time'});  
            end                     
        end 
    end          
end 
if ETAorSTAq == 0 % STA data 
    avLabels = ["Pre-Spike","Post-Spike"];
elseif ETAorSTAq == 1 % ETA data
      if ETAtype == 0 % opto data 
          avLabels = ["Pre-Opto","Post-Opto"];
      elseif ETAtype == 1 % behavior data 
            if ETAtype2 == 0 % stim aligned 
                avLabels = ["Pre-Stim","Post-Stim"];
            elseif ETAtype2 == 1 % reward aligned 
                avLabels = ["Pre-Reward","Post-Reward"];
            end 
      end 
end 
xticklabels(avLabels)
set(gca, 'YScale', 'log')

clearvars data 
% reshape data for plotting 
dataRsize = size(allMaxCsizeForPlot,1); dataCsize = size(allMaxCsizeForPlot,2);
reshapedPre = reshape(PreAllMaxCampForPlot,dataRsize*dataCsize,1);
reshapedPost = reshape(PostAllMaxCampForPlot,dataRsize*dataCsize,1);
data(:,1) = reshapedPre; data(:,2) = reshapedPost; 
figure;
ax=gca;
% plot box plot 
boxchart(data,'MarkerStyle','none','BoxFaceColor','k','WhiskerLineColor','k');
% plot swarm chart on top of box plot 
hold all;
x = repmat(1:size(data,2),size(data,1),1);
swarmchart(x,data,[],'red') 
% boxchart(reshapedPostPlot,'MarkerStyle','none','BoxFaceColor','b','WhiskerLineColor','b');
ax.FontSize = 15;
ax.FontName = 'Arial';
ylabel("Max BBB Plume Pixel Amplitude") 
if ETAorSTAq == 0 % STA data
    if clustSpikeQ3 == 0 
        title({'Max BBB Plume Pixel Amplitude Across Animals';'Pre And Post Spike Plumes';'Average Cluster Time'});  
    elseif clustSpikeQ3 == 1
        title({'Max BBB Plume Pixel Amplitude Across Animals';'Pre And Post Spike Plumes';'Cluster Start Time'});  
    end     
elseif ETAorSTAq == 1 % ETA data
    if ETAtype == 0 % opto data 
        if clustSpikeQ3 == 0 
            title({'Max BBB Plume Pixel Amplitude Across Animals';'Pre And Post Opto Plumes';'Average Cluster Time'});  
        elseif clustSpikeQ3 == 1
            title({'Max BBB Plume Pixel Amplitude Across Animals';'Pre And Post Opto Plumes';'Cluster Start Time'});  
        end    
    elseif ETAtype == 1 % behavior data 
        if ETAtype2 == 0 % stim aligned 
            if clustSpikeQ3 == 0 
                title({'Max BBB Plume Pixel Amplitude Across Animals';'Pre And Post Stim Plumes';'Average Cluster Time'});  
            elseif clustSpikeQ3 == 1
                title({'Max BBB Plume Pixel Amplitude Across Animals';'Pre And Post Stim Plumes';'Cluster Start Time'});  
            end  
        elseif ETAtype2 == 1 % reward aligned 
             if clustSpikeQ3 == 0 
                title({'Max BBB Plume Pixel Amplitude Across Animals';'Pre And Post Reward Plumes';'Average Cluster Time'});  
            elseif clustSpikeQ3 == 1
                title({'Max BBB Plume Pixel Amplitude Across Animals';'Pre And Post Reward Plumes';'Cluster Start Time'});  
            end                     
        end 
    end          
end 
if ETAorSTAq == 0 % STA data 
    avLabels = ["Pre-Spike","Post-Spike"];
elseif ETAorSTAq == 1 % ETA data
      if ETAtype == 0 % opto data 
          avLabels = ["Pre-Opto","Post-Opto"];
      elseif ETAtype == 1 % behavior data 
            if ETAtype2 == 0 % stim aligned 
                avLabels = ["Pre-Stim","Post-Stim"];
            elseif ETAtype2 == 1 % reward aligned 
                avLabels = ["Pre-Reward","Post-Reward"];
            end 
      end 
end 
xticklabels(avLabels)
%% DBSCAN to find groups of plumes grouped together by cluster start time, axon distance from vessel, plume distance from axon, max cluster size, max pixel amplitude 

if ETAorSTAq == 0 % STA data
    dataParamQ = input('Input 0 to cluster data based on all paramaters. Input 1 to cluster data based on distance metrics only. ');
    clearvars timeDistsSizeAmpArray rsrtdDownCampTS rsrtdDownCsizeTS
    distsCOV = cell(1,mouseNum);
    for mouse = 1:mouseNum
        if dataParamQ == 0
            if mouse == 1 
                % resort COV dists 
                distsCOV{mouse} = allTimeCOVdistArray(1:length(BAdists{mouse}),2);
                % sort data into one array
                timeDistsSizeAmpArray(:,1) = reshpdAvClocFrame{mouse};
                timeDistsSizeAmpArray(:,2) = minVAdistsPerC{mouse};
                timeDistsSizeAmpArray(:,3) = BAdists{mouse};
                timeDistsSizeAmpArray(:,4) = maxSize{mouse};
                timeDistsSizeAmpArray(:,5) = maxClustAmp{mouse};
                timeDistsSizeAmpArray(:,6) = distsCOV{mouse};
                len = length(BAdists{mouse});
            elseif mouse > 1 
                % resort COV dists 
                if mouse > 2 
                    len = length(BAdists{mouse-1}) + len;
                end 
                len2 = length(BAdists{mouse});
                distsCOV{mouse} = allTimeCOVdistArray(len+1:len+len2,2);
                % sort data into one array
                len1 = size(timeDistsSizeAmpArray,1);
                len2 = length(reshpdAvClocFrame{mouse});
                timeDistsSizeAmpArray(len1+1:len1+len2,1) = reshpdAvClocFrame{mouse};
                timeDistsSizeAmpArray(len1+1:len1+len2,2) = minVAdistsPerC{mouse};
                timeDistsSizeAmpArray(len1+1:len1+len2,3) = BAdists{mouse};
                timeDistsSizeAmpArray(len1+1:len1+len2,4) = maxSize{mouse};
                timeDistsSizeAmpArray(len1+1:len1+len2,5) = maxClustAmp{mouse};  
                timeDistsSizeAmpArray(len1+1:len1+len2,6) = distsCOV{mouse};
            end 
        elseif dataParamQ == 1 
            if mouse == 1 
                % resort COV dists 
                distsCOV{mouse} = allTimeCOVdistArray(1:length(BAdists{mouse}),2);
                % sort data into one array
                timeDistsSizeAmpArray(:,1) = minVAdistsPerC{mouse};
                timeDistsSizeAmpArray(:,2) = BAdists{mouse};
                timeDistsSizeAmpArray(:,3) = distsCOV{mouse};
                len = length(BAdists{mouse});
            elseif mouse > 1 
                % resort COV dists 
                if mouse > 2 
                    len = length(BAdists{mouse-1}) + len;
                end 
                len2 = length(BAdists{mouse});
                distsCOV{mouse} = allTimeCOVdistArray(len+1:len+len2,2);
                % sort data into one array
                len1 = size(timeDistsSizeAmpArray,1);
                len2 = length(reshpdAvClocFrame{mouse});
                timeDistsSizeAmpArray(len1+1:len1+len2,1) = minVAdistsPerC{mouse};
                timeDistsSizeAmpArray(len1+1:len1+len2,2) = BAdists{mouse};
                timeDistsSizeAmpArray(len1+1:len1+len2,3) = distsCOV{mouse};
            end             
        end 
    end
    if dataParamQ == 0
        timeDistsSizeAmpArray(:,7) = allTimeODistArray(~isnan(allTimeODistArray(:,1)),2);
    elseif dataParamQ == 1 
        timeDistsSizeAmpArray(:,4) = allTimeODistArray(~isnan(allTimeODistArray(:,1)),2);
    end 

    % use DBSCAN to identify clusters of BBB plumes that are
    % similar based off of the 5 metrics defined above 
    numP = 3; % number of points a cluster needs to be considered valid
    fixRad = 50; % fixed radius for the search of neighbors 
    [idx,corepts] = dbscan(timeDistsSizeAmpArray,fixRad,numP);
    numGroups = length(unique(idx));
    % how many repeating numbers are there in idx/how many clusters are in the
    % same group? 
    [~,~,ix] = unique(idx);
    repeatingIdx = accumarray(ix,1);
    if any(idx < 0) == 1 %#ok<COMPNOP>
        minVal = min(idx);
        buffer = abs(minVal)+1;
        idx = idx + buffer;
    end 
    groups = unique(idx);
    % resort the downsampled data 
    for mouse = 1:mouseNum
        if mouse == 1
            rsrtdDownCampTS = downAllAxonsClustAmpTS{mouse};
            rsrtdDownCsizeTS = downAllAxonsClustSizeTS{mouse};
        elseif mouse > 1 
            len1 = size(rsrtdDownCampTS,1);
            len2 = size(downAllAxonsClustAmpTS{mouse},1);
            rsrtdDownCampTS(len1+1:len1+len2,:) = downAllAxonsClustAmpTS{mouse}; 
            rsrtdDownCsizeTS(len1+1:len1+len2,:) = downAllAxonsClustSizeTS{mouse}; 
        end 
    end 
    dataTypeQ = input("Input 0 to plot all DBSCAN grouped BBB plume data. Input 1 to plot the groups with more than one BBB plume. Input 2 to plot groups with only one BBB plume. ");
    % sort data into groups based on DBSCAN clustering 
    if dataTypeQ == 0
        CampTSGroupData = cell(1,numGroups);
        CsizeTSGroupData = cell(1,numGroups);
        for group = 1:numGroups
            r = find(idx == groups(group));
            CampTSGroupData{group} = rsrtdDownCampTS(r,:);
            CsizeTSGroupData{group} = rsrtdDownCsizeTS(r,:);
        end 
    elseif dataTypeQ == 1 
        numLargeGroups = length(find(repeatingIdx > 1));
        CampTSGroupData = cell(1,numLargeGroups);
        CsizeTSGroupData = cell(1,numLargeGroups);
        count = 1;
        for group = 1:numGroups
            r = find(idx == groups(group));
            if length(r) > 1
                CampTSGroupData{count} = rsrtdDownCampTS(r,:);
                CsizeTSGroupData{count} = rsrtdDownCsizeTS(r,:);
                count = count + 1;
            end 
        end    
    elseif dataTypeQ == 2 
        numSmallGroups = length(find(repeatingIdx == 1));
        CampTSGroupData = cell(1,numSmallGroups);
        CsizeTSGroupData = cell(1,numSmallGroups);
        count = 1;
        for group = 1:numGroups
            r = find(idx == groups(group));
            if length(r) == 1
                CampTSGroupData{count} = rsrtdDownCampTS(r,:);
                CsizeTSGroupData{count} = rsrtdDownCsizeTS(r,:);
                count = count + 1;
            end 
        end         
    end 

    % plot change in cluster size over time for all clusters, color coded by
    % group
    if dataTypeQ == 0
        clr = hsv(numGroups);
    elseif dataTypeQ == 1 
        clr = hsv(numLargeGroups);
    elseif dataTypeQ == 2 
        clr = hsv(numSmallGroups);
    end 
    x = 1:minFrameLen;
    figure;
    hold all;
    ax=gca;
    count2 = 1;
    mouseTSlabel = string(1);
    for group = 1:length(CsizeTSGroupData)
        h = plot(x,CsizeTSGroupData{group},'Color',clr(group,:),'LineWidth',2);   
    end     
    Frames_pre_stim_start = -((minFrameLen-1)/2); 
    Frames_post_stim_start = (minFrameLen-1)/2; 
    fps = minFrameLen/windSize;
    sec_TimeVals = floor(((Frames_pre_stim_start:fps:Frames_post_stim_start)/fps))+1;
    threshFrame = floor((minFrameLen-1)/2);
    FrameVals(3) = threshFrame;
    FrameVals(2) = threshFrame - (minFrameLen/5);
    FrameVals(1) = FrameVals(2) - (minFrameLen/5);
    FrameVals(4) = threshFrame + (minFrameLen/5);
    FrameVals(5) = FrameVals(4) + (minFrameLen/5);
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    ylabel("BBB Plume Size (microns squared)") 
    xlabel("Time (s)")
    if dataTypeQ == 0
        titleLabel = 'All DBSCAN Groups';
    elseif dataTypeQ == 1 
        titleLabel = 'DBSCAN Groups with > 1 BBB Plumes';
    elseif dataTypeQ == 2
        titleLabel = 'DBSCAN Groups with 1 BBB Plume';
    end 
    title({'Change in BBB Plume Size';titleLabel})
    xlim([1 minFrameLen])
    % set(gca, 'YScale', 'log')
    
    % plot change in cluster amp over time for all clusters, color coded by
    % group
    figure;
    hold all;
    ax=gca;
    for group = 1:length(CsizeTSGroupData)
        h = plot(x,CampTSGroupData{group},'Color',clr(group,:),'LineWidth',2);   
    end     
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    ylabel("BBB Plume Pixel Amplitude") 
    xlabel("Time (s)")
    title({'Change in BBB Plume Pixel Amplitude';titleLabel})
    xlim([1 minFrameLen])
    
    % plot change in average cluster size per group 
    figure;
    hold all;
    ax=gca;
    avAxonClustSizeTS = nan(length(CsizeTSGroupData),minFrameLen);
    for group = 1:length(CsizeTSGroupData)
        clearvars v f
        avAxonClustSizeTS(group,:) = nanmean(CsizeTSGroupData{group},1);  %#ok<*NANMEAN> 
        plot(x,avAxonClustSizeTS(group,:),'Color',clr(group,:),'LineWidth',2);  
        % determine 95% CI 
        SEM = (nanstd(CsizeTSGroupData{group}))/(sqrt(size(CsizeTSGroupData{group},1))); %#ok<*NANSTD> % Standard Error            
        ts_Low = tinv(0.025,size(CsizeTSGroupData{group},1)-1);% T-Score for 95% CI
        ts_High = tinv(0.975,size(CsizeTSGroupData{group},1)-1);% T-Score for 95% CI
        CI_Low = (nanmean(CsizeTSGroupData{group},1)) + (ts_Low*SEM);  % Confidence Intervals
        CI_High = (nanmean(CsizeTSGroupData{group},1)) + (ts_High*SEM);  % Confidence Intervals
        % plot the 95% CI 
        v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
        v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
        % remove NaNs so face can be made and colored 
        nanRows = isnan(v(:,2));
        v(nanRows,:) = []; f = 1:size(v,1); 
        patch('Faces',f,'Vertices',v,'FaceColor',clr(group,:),'EdgeColor','none');
        alpha(0.2)
    end 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    ylabel("BBB Plume Size (microns squared)") 
    xlabel("Time (s)")
    title({'Average Change in BBB Plume Size';titleLabel})
    xlim([1 minFrameLen])
    % set(gca, 'YScale', 'log')
    
    % plot change in average cluster pixel amplitude per group
    figure;
    hold all;
    ax=gca;
    avAxonClustAmpTS = nan(length(CampTSGroupData),minFrameLen);
    for group = 1:length(CampTSGroupData)
        clearvars v f
        avAxonClustAmpTS(group,:) = nanmean(CampTSGroupData{group},1);  %#ok<*NANMEAN> 
        plot(x,avAxonClustAmpTS(group,:),'Color',clr(group,:),'LineWidth',2);  
        % determine 95% CI 
        SEM = (nanstd(CampTSGroupData{group}))/(sqrt(size(CampTSGroupData{group},1))); %#ok<*NANSTD> % Standard Error            
        ts_Low = tinv(0.025,size(CampTSGroupData{group},1)-1);% T-Score for 95% CI
        ts_High = tinv(0.975,size(CampTSGroupData{group},1)-1);% T-Score for 95% CI
        CI_Low = (nanmean(CampTSGroupData{group},1)) + (ts_Low*SEM);  % Confidence Intervals
        CI_High = (nanmean(CampTSGroupData{group},1)) + (ts_High*SEM);  % Confidence Intervals
        % plot the 95% CI 
        v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
        v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
        % remove NaNs so face can be made and colored 
        nanRows = isnan(v(:,2));
        v(nanRows,:) = []; f = 1:size(v,1); 
        patch('Faces',f,'Vertices',v,'FaceColor',clr(group,:),'EdgeColor','none');
        alpha(0.2)
    end 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    ylabel("BBB Plume Pixel Amplitude") 
    xlabel("Time (s)")
    title({'Average Change in BBB Plume Pixel Amplitude';titleLabel})
    xlim([1 minFrameLen])
    % set(gca, 'YScale', 'log')

    % plot average change in cluster size of all animals w/95% CI 
    figure;
    hold all;
    ax=gca;
    % determine average 
    avAllClustSizeTS = nanmean(avAxonClustSizeTS);
    % determine 95% CI 
    SEM = (nanstd(avAxonClustSizeTS))/(sqrt(size(avAxonClustSizeTS,1))); %#ok<*NANSTD> % Standard Error            
    ts_Low = tinv(0.025,size(avAxonClustSizeTS,1)-1);% T-Score for 95% CI
    ts_High = tinv(0.975,size(avAxonClustSizeTS,1)-1);% T-Score for 95% CI
    CI_Low = (nanmean(avAxonClustSizeTS,1)) + (ts_Low*SEM);  % Confidence Intervals
    CI_High = (nanmean(avAxonClustSizeTS,1)) + (ts_High*SEM);  % Confidence Intervals
    plot(x,avAllClustSizeTS,'k','LineWidth',2);   
    clearvars v f 
    v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
    v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
    % remove NaNs so face can be made and colored 
    nanRows = isnan(v(:,2));
    v(nanRows,:) = []; f = 1:size(v,1);
    patch('Faces',f,'Vertices',v,'FaceColor','black','EdgeColor','none');
    alpha(0.3)
    % FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    ylabel("BBB Plume Size (microns squared)") 
    xlabel("Time (s)")
    title({'Average Change in BBB Plume Size';titleLabel})
    xlim([1 minFrameLen])
    
    % plot average change in cluster size of all animals w/95% CI 
    figure;
    hold all;
    ax=gca;
    % determine average 
    avAllClustAmpTS = nanmean(avAxonClustAmpTS);
    % determine 95% CI 
    SEM = (nanstd(avAxonClustAmpTS))/(sqrt(size(avAxonClustAmpTS,1))); %#ok<*NANSTD> % Standard Error            
    ts_Low = tinv(0.025,size(avAxonClustAmpTS,1)-1);% T-Score for 95% CI
    ts_High = tinv(0.975,size(avAxonClustAmpTS,1)-1);% T-Score for 95% CI
    CI_Low = (nanmean(avAxonClustAmpTS,1)) + (ts_Low*SEM);  % Confidence Intervals
    CI_High = (nanmean(avAxonClustAmpTS,1)) + (ts_High*SEM);  % Confidence Intervals
    plot(x,avAllClustAmpTS,'k','LineWidth',2);   
    clearvars v f 
    v(:,1) = x; v(length(x)+1:length(x)*2) = fliplr(x);
    v(1:length(x),2) = CI_Low; v(length(x)+1:length(x)*2,2) = fliplr(CI_High);
    % remove NaNs so face can be made and colored 
    nanRows = isnan(v(:,2));
    v(nanRows,:) = []; f = 1:size(v,1);
    patch('Faces',f,'Vertices',v,'FaceColor','black','EdgeColor','none');
    alpha(0.3)
    % FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    ylabel("BBB Plume Pixel Amplitude") 
    xlabel("Time (s)")
    title({'Average Change in BBB Plume Plume Pixel Amplitude';titleLabel})
    xlim([1 minFrameLen])

    % resort idx into {mouse}{ccell}{clust} using axonInds 
    srtIdx1 = cell(1,mouseNum);
    for mouse = 1: mouseNum 
        if mouse == 1 
            len = length(axonInds{mouse});
            len1 = 1;
            len2 = len;
            srtIdx1{mouse} = idx(1:length(axonInds{mouse}));            
        elseif mouse > 1 
            len = length(axonInds{mouse});  
            len1 = len2 + 1;
            len2 = len1 + len - 1;                               
            srtIdx1{mouse} = idx(len1:len2);            
        end 
    end 
    clearvars idx 
    srtIdx2 = cell(1,mouseNum);
    for mouse = 1: mouseNum 
        for ccell = 1:length(plumeOriginLocs{mouse})
            srtIdx2{mouse}{ccell} = srtIdx1{mouse}(axonInds{mouse} == ccell);
        end 
    end 
    clearvars srtIdx1
    % plot BBB plume origins on vessel width outline color coded by DBSCAN
    % cluster
    unGroupLbl = unique(idx);
    for mouse = 1: mouseNum 
        figure;
        % plot vessel outline 
        scatter3(indsV{mouse}(:,1),indsV{mouse}(:,2),indsV{mouse}(:,3),30,'k','filled'); % plot vessel outline 
        % plot the cluster origins 
        hold on; 
        for ccell = 1:length(plumeOriginLocs{mouse})
            for clust = 1:length(plumeOriginLocs{mouse}{ccell})
                if clust <= length(srtIdx2{mouse}{ccell})
                    scatter3(plumeOriginLocs{mouse}{ccell}{clust}(:,1)*XpixDist(mouse),plumeOriginLocs{mouse}{ccell}{clust}(:,2)*YpixDist(mouse),plumeOriginLocs{mouse}{ccell}{clust}(:,3),30,'MarkerFaceColor',clr((unGroupLbl == srtIdx2{mouse}{ccell}(clust)),:),'MarkerEdgeColor',clr((unGroupLbl == srtIdx2{mouse}{ccell}(clust)),:)); % plot clusters        
                end 
            end 
        end 
    end 
end 

%% plot histogram of maximum plume pixel amplitudes and size (use maxSize
% and maxClustAmp)

% resort max arrays 
for mouse = 1:mouseNum
    if mouse == 1
        allMaxSize = maxSize{mouse};
        allMaxAmp = maxClustAmp{mouse};
    elseif mouse > 1 
        len1 = length(allMaxSize);
        len2 = length(maxSize{mouse});
        allMaxSize(len1+1:len1+len2) = maxSize{mouse};
        allMaxAmp(len1+1:len1+len2) = maxClustAmp{mouse};
    end 
end 

figure;
ax=gca;
avClustSize = nanmean(allMaxSize); 
medClustSize = nanmedian(allMaxSize); %#ok<*NANMEDIAN> 
avClustSizeLabel = sprintf('Average max cluster size: %.0f',avClustSize);
medClustSizeLabel = sprintf('Median max cluster size: %.0f',medClustSize);
histogram(allMaxSize,100)
ax.FontSize = 15;
% ax.FontName = 'Times';
if clustSpikeQ == 0 
    title({'Distribution of Max BBB Plume Sizes';'All Clusters';avClustSizeLabel;medClustSizeLabel});
elseif clustSpikeQ == 1 
    if clustSpikeQ2 == 0 
        title({'Distribution of Max BBB Plume Sizes';'Pre-Spike Clusters';avClustSizeLabel;medClustSizeLabel});
    elseif clustSpikeQ2 == 1
        title({'Distribution of Max BBB Plume Sizes';'Post-Spike Clusters';avClustSizeLabel;medClustSizeLabel});
    end 
end 
ylabel("Number of BBB Plumes")
xlabel("Max Size of BBB Plume (microns squared)") 

figure;
ax=gca;
histogram(allMaxAmp,100)
avClustAmp = nanmean(allMaxAmp); 
medClustAmp = nanmedian(allMaxAmp); %#ok<*NANMEDIAN> 
avClustAmpLabel = sprintf('Average max cluster pixel amplitude: %.3f',avClustAmp);
medClustAmpLabel = sprintf('Median max cluster pixel amplitude: %.3f',medClustAmp);
ax.FontSize = 15;
% ax.FontName = 'Times';
if clustSpikeQ == 0 
    title({'Distribution of Max BBB Plume Pixel Amplitudes';'All Clusters';avClustAmpLabel;medClustAmpLabel});
elseif clustSpikeQ == 1 
    if clustSpikeQ2 == 0 
        title({'Distribution of Max BBB Plume Pixel Amplitudes';'Pre-Spike Clusters';avClustAmpLabel;medClustAmpLabel});
    elseif clustSpikeQ2 == 1
        title({'Distribution of Max BBB Plume Pixel Amplitudes';'Post-Spike Clusters';avClustAmpLabel;medClustAmpLabel});
    end 
end 
ylabel("Number of BBB Plumes")
xlabel("Max BBB Plume Pixel Amplitudes") 

%% plot change in vessel width
% resort data to plot all average change in vessel width per mouse and
% average change in vessel width across mice (data is sorted differently
% depending on type) 
if ETAorSTAq == 0 % STA data  
    allAxonCaData = cell(1,mouseNum);
    allAxonVwData = cell(1,mouseNum);
    downCaData = cell(1,mouseNum);
    downVwData = cell(1,mouseNum);
    avDownCaData = nan(mouseNum,minFrameLen);
    avDownVwData = nan(mouseNum,minFrameLen);
    for mouse = 1:mouseNum
        for ccell = 1:length(terminals{mouse})
            allAxonCaData{mouse}(ccell,:) = avCAdata{mouse}{terminals{mouse}(ccell)};
            allAxonVwData{mouse}(ccell,:) = avVWdata{mouse}{terminals{mouse}(ccell)};
        end 
        % resample data 
        downCaData{mouse} = resample(allAxonCaData{mouse},minFrameLen,frameLen(mouse),'Dimension',2);
        downVwData{mouse} = resample(allAxonVwData{mouse},minFrameLen,frameLen(mouse),'Dimension',2);
        % average within mice 
        avDownCaData(mouse,:) = nanmean(downCaData{mouse},1);
        avDownVwData(mouse,:) = nanmean(downVwData{mouse},1);
    end 
    % average across mice
    AllAvDownCaData = nanmean(avDownCaData,1);
    AllAvDownVwData = nanmean(avDownVwData,1);
    % determine the 95% CI 
    SEMc = (nanstd(avDownCaData))/(sqrt(size(avDownCaData,1))); %#ok<*NANSTD> % Standard Error  
    tsc_Low = tinv(0.025,size(avDownCaData,1)-1);% T-Score for 95% CI
    tsc_High = tinv(0.975,size(avDownCaData,1)-1);% T-Score for 95% CI
    CIc_Low = (AllAvDownCaData) + (tsc_Low*SEMc);  % Confidence Intervals
    CIc_High = (AllAvDownCaData) + (tsc_High*SEMc);  % Confidence Intervals   
    SEMv = (nanstd(avDownVwData))/(sqrt(size(avDownVwData,1))); %#ok<*NANSTD> % Standard Error  
    tsv_Low = tinv(0.025,size(avDownVwData,1)-1);% T-Score for 95% CI
    tsv_High = tinv(0.975,size(avDownVwData,1)-1);% T-Score for 95% CI
    CIv_Low = (AllAvDownVwData) + (tsv_Low*SEMv);  % Confidence Intervals
    CIv_High = (AllAvDownVwData) + (tsv_High*SEMv);  % Confidence Intervals   
elseif ETAorSTAq == 1 % ETA data  
    downVwData = cell(1,mouseNum);
    avDownVwData = nan(mouseNum,minFrameLen);
    for mouse = 1:mouseNum
        if frameLen(mouse) == 0 
            frameLen(mouse) = length(avVWdata{mouse});
        end 
        % resample data 
        downVwData{mouse} = resample(avVWdata{mouse},minFrameLen,frameLen(mouse),'Dimension',2);
        % average within mice
        avDownVwData(mouse,:) = nanmean(downVwData{mouse},1);
    end 
    % average across mice
    AllAvDownVwData = nanmean(avDownVwData,1);
    % determine the 95% CI 
    SEMv = (nanstd(avDownVwData))/(sqrt(size(avDownVwData,1))); %#ok<*NANSTD> % Standard Error  
    tsv_Low = tinv(0.025,size(avDownVwData,1)-1);% T-Score for 95% CI
    tsv_High = tinv(0.975,size(avDownVwData,1)-1);% T-Score for 95% CI
    CIv_Low = (AllAvDownVwData) + (tsv_Low*SEMv);  % Confidence Intervals
    CIv_High = (AllAvDownVwData) + (tsv_High*SEMv);  % Confidence Intervals  
end 
% plot data 
if ETAorSTAq == 0 % STA data     
    % code in buffer space for plotting          
    %determine range of data Ca data
    CaDataRange = max(AllAvDownCaData)-min(AllAvDownCaData);
    %determine plotting buffer space for Ca data 
    CaBufferSpace = CaDataRange;
    %determine first set of plotting min and max values for Ca data
    CaPlotMin = min(AllAvDownCaData)-CaBufferSpace;
    CaPlotMax = max(AllAvDownCaData)+CaBufferSpace; 
    %determine Ca 0 ratio/location 
    % CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);
    %determine range of VW data 
    VWdataRange = max(AllAvDownVwData)-min(AllAvDownVwData); 
    %determine plotting buffer space for BBB data 
    VWbufferSpace = VWdataRange;
    %determine first set of plotting min and max values for BBB data
    VWplotMin = min(AllAvDownVwData)-VWbufferSpace;
    VWplotMax = max(AllAvDownVwData)+VWbufferSpace; 
    %determine VW 0 ratio/location
    VWzeroRatio = abs(VWplotMin)/(VWplotMax-VWplotMin);
    %determine how much to shift the CA axis so that the zeros align 
    CAbelowZero = (CaPlotMax-CaPlotMin)*VWzeroRatio;
    CAaboveZero = (CaPlotMax-CaPlotMin)-CAbelowZero;
    % plot data  
    x = 1:length(AllAvDownVwData);                          
    figure;
    Frames = length(x);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:fps:Frames_post_stim_start)/fps))+1;
    ax=gca;
    hold all
    for mouse = 1:mouseNum
        plot(avDownVwData(mouse,:),'k','LineWidth',2)
    end 
    threshFrame = floor(minFrameLen/2);
    FrameVals(3) = threshFrame;
    FrameVals(2) = threshFrame - (Frames/5);
    FrameVals(1) = FrameVals(2) - (Frames/5);
    FrameVals(4) = threshFrame + (Frames/5);
    FrameVals(5) = FrameVals(4) + (Frames/5);
    ax.XTick = FrameVals;
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;   
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    xlabel('time (s)','FontName','Arial')
    tempSmoothLabel = sprintf('%.2f second smoothing.',filtTime);
    ylabel({'z-scored vessel width';tempSmoothLabel},'FontName','Arial')
    % xLimStart = floor(10*FPSstack{mouse});
    % set(fig,'position', [500 100 900 800])  
    yyaxis right
    for mouse = 1:mouseNum
        plot(avDownCaData(mouse,:),'b-','LineWidth',2)
    end 
    ylabel('z-scored calcium','FontName','Arial')
    title('Vessel Width Time-Locked to Ca Spikes')
    set(gca,'YColor','b');   
    ylim([-CAbelowZero CAaboveZero])  
    xlim([1 minFrameLen])
        
    % plot average change in VW and CA data across mice  
    figure;
    ax=gca;
    hold all
    plot(AllAvDownVwData,'k','LineWidth',2)
    patch([x fliplr(x)],[CIv_Low fliplr(CIv_High)],'k','EdgeColor','none')
    alpha(0.3)
    ax.XTick = FrameVals;
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;   
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    xlabel('time (s)','FontName','Arial')
    tempSmoothLabel = sprintf('%.2f second smoothing.',filtTime);
    ylabel({'z-scored vessel width';tempSmoothLabel},'FontName','Arial')
    % set(fig,'position', [500 100 900 800])  
    yyaxis right
    plot(AllAvDownCaData,'b','LineWidth',2)
    patch([x fliplr(x)],[CIc_Low fliplr(CIc_High)],'b','EdgeColor','none')
    alpha(0.3)
    ylabel('z-scored calcium','FontName','Arial')
    title({'Vessel Width Time-Locked to Ca Spikes';'Across Animals'})
    set(gca,'YColor','b');   
    ylim([-CAbelowZero CAaboveZero])  
    xlim([1 minFrameLen])
elseif ETAorSTAq == 1 % if it's ETA data 
    % plot data  
    x = 1:length(AllAvDownVwData);                          
    figure;
    Frames = length(x);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:fps:Frames_post_stim_start)/fps))+1;
    ax=gca;
    hold all
    for mouse = 1:mouseNum
        plot(avDownVwData(mouse,:),'k','LineWidth',2)
    end 
    threshFrame = floor(minFrameLen/2);
    FrameVals(3) = threshFrame;
    FrameVals(2) = threshFrame - (Frames/5);
    FrameVals(1) = FrameVals(2) - (Frames/5);
    FrameVals(4) = threshFrame + (Frames/5);
    FrameVals(5) = FrameVals(4) + (Frames/5);
    ax.XTick = FrameVals;
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;   
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    xlabel('time (s)','FontName','Arial')
    tempSmoothLabel = sprintf('%.2f second smoothing.',filtTime);
    ylabel({'z-scored vessel width';tempSmoothLabel},'FontName','Arial')
    if ETAtype == 0 % opto data 
      title({'Vessel Width Opto-Triggered Average.'})
    elseif ETAtype == 1 % behavior data 
        if ETAtype2 == 0 % stim aligned 
            title({'Vessel Width Stim-Triggered Average.'})
        elseif ETAtype2 == 1 % reward aligned 
            title({'Vessel Width Reward-Triggered Average.'})
        end 
    end  
    xlim([1 minFrameLen])
        
    % plot average change in VW across mice  
    figure;
    ax=gca;
    hold all
    plot(AllAvDownVwData,'k','LineWidth',2)
    patch([x fliplr(x)],[CIv_Low fliplr(CIv_High)],'k','EdgeColor','none')
    alpha(0.3)
    ax.XTick = FrameVals;
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;   
    ax.FontSize = 15;
    ax.FontName = 'Arial';
    xlabel('time (s)','FontName','Arial')
    tempSmoothLabel = sprintf('%.2f second smoothing.',filtTime);
    ylabel({'z-scored vessel width';tempSmoothLabel},'FontName','Arial')
    % set(fig,'position', [500 100 900 800])  
    if ETAtype == 0 % opto data 
      title({'Vessel Width Opto-Triggered Average.';'Across Animals'})
    elseif ETAtype == 1 % behavior data 
        if ETAtype2 == 0 % stim aligned 
            title({'Vessel Width Stim-Triggered Average.';'Across Animals'})
        elseif ETAtype2 == 1 % reward aligned 
            title({'Vessel Width Reward-Triggered Average.';'Across Animals'})
        end 
    end   
    xlim([1 minFrameLen])
end 
%}
