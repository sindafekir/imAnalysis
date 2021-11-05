% get the data you need 
% includes batch processing (across mice) option for STA/ETA figure generation
%{
%set the paramaters 
ETAQ = input('Input 1 if you want to plot event/spike triggered averages. Input 0 if otherwise. '); 
STAstackQ = input('Input 1 to import red and green channel stacks to create STA videos. Input 0 otherwise. ');
distQ = input('Input 1 if you want to determine distance of Ca ROIs from vessel. Input 0 otherwise. ');
if STAstackQ == 1 || distQ == 1 
    BGsubQ = input('Input 1 if you want to do background subtraction on your imported image stacks. Input 0 otherwise. ');
    if BGsubQ == 1
        BGsubTypeQ = input('Input 0 to do a simple background subtraction. Input 1 if you want to do row by row background subtraction. ');
    end 
end 
if ETAQ == 1 || STAstackQ == 1 
    optoQ = input('Input 1 if this is an opto exeriment. Input 0 for a behavior experiment. ');
    if optoQ == 1 
        stimStateQ = input('Input 0 if you used flyback stimulation. Input 1 if not. ');
        if stimStateQ == 0 
            state = 8;
        elseif stimStateQ == 1
            state = 7;
        end 
    elseif optoQ == 0 
        state = input('Input the teensy state you care about. ');
    end 
    batchQ = input('Input 1 if you want to batch process across mice. Input 0 otherwise. ');
    if batchQ == 0 
        mouseNum = 1; 
    elseif batchQ == 1 
        mouseNum = input('How many mice are you batch processing? ');
    end 
    FPSstack = cell(1,mouseNum);
    vidList = cell(1,mouseNum);
    for mouse = 1:mouseNum
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
end 
if ETAQ == 1 && STAstackQ == 0 
    BBBQ = input('Input 1 if you want to get BBB data. Input 0 otherwise. ');
    VWQ = input('Input 1 if you want to get vessel width data. Input 0 otherwise. ');
    CAQ = input('Input 1 if you want to get calcium data. Input 0 otherwise. ');
    if CAQ == 1
        tTypeQ = input('Do you want to seperate calcium peaks by trial type (light condition)? No = 0. Yes = 1. ');
    end 
end 
if STAstackQ == 1 && ETAQ == 0
    CAQ = 1;
    if CAQ == 1
        tTypeQ = input('Do you want to seperate calcium peaks by trial type (light condition)? No = 0. Yes = 1. ');
    end 
end 
if ETAQ == 1 && STAstackQ == 1 
    BBBQ = input('Input 1 if you want to get BBB data. Input 0 otherwise. ');
    VWQ = input('Input 1 if you want to get vessel width data. Input 0 otherwise. ');
    CAQ = 1;
    if CAQ == 1
        tTypeQ = input('Do you want to seperate calcium peaks by trial type (light condition)? No = 0. Yes = 1. ');
    end 
end 

if ETAQ == 1
    if BBBQ == 1 
        bDataFullTrace = cell(1,mouseNum);
    end 
    if VWQ == 1 
        vDataFullTrace = cell(1,mouseNum);
    end 
    if CAQ == 1 
        cDataFullTrace = cell(1,mouseNum);
        terminals = cell(1,mouseNum);
    end 
    velWheelQ = input('Input 1 to get wheel data. Input 0 otherwise. '); 
    if velWheelQ == 1 
        wDataFullTrace = cell(1,mouseNum);
    end 
    state_start_f = cell(1,mouseNum);
    TrialTypes = cell(1,mouseNum);
    state_end_f = cell(1,mouseNum);
    trialLengths = cell(1,mouseNum);
    dataDir = cell(1,mouseNum);
elseif STAstackQ == 1 
    mouseNum = 1; 
    if CAQ == 1 
        cDataFullTrace = cell(1,mouseNum);
        terminals = cell(1,mouseNum);
    end 
end 

for mouse = 1:mouseNum
    % get your data 
    if ETAQ == 1
        dirLabel = sprintf('WHERE IS THE DATA FOR MOUSE #%d? ',mouse);
        dataDir{mouse} = uigetdir('*.*',dirLabel);
        cd(dataDir{mouse}); % go to the right directory 
        if BBBQ == 1             
            % get BBB data             
            BBBfileList = dir('**/*BBBdata_*.mat'); % list BBB data files in current directory             
            for vid = 1:length(vidList{mouse})
                BBBlabel = BBBfileList(vid).name;
                BBBmat = matfile(sprintf(BBBlabel,vidList{mouse}(vid)));
                Bdata = BBBmat.Bdata;       
                bDataFullTrace{mouse}{vid} = Bdata;
            end 
        end 
        if VWQ == 1 
            % get vessel width data 
            VWfileList = dir('**/*VWdata_*.mat'); % list VW data files in current directory 
            for vid = 1:length(vidList{mouse})
                VWlabel = VWfileList(vid).name;
                VWmat = matfile(sprintf(VWlabel,vidList{mouse}(vid)));
                Vdata = VWmat.Vdata;       
                vDataFullTrace{mouse}{vid} = Vdata;
            end 
        end 
    end 
    if ETAQ == 1 || STAstackQ == 1 
        if CAQ == 1 
            % get calcium data 
            terminals{mouse} = input(sprintf('What terminals do you care about for mouse #%d? Input in correct order. ',mouse));    
            CAfileList = dir('**/*CAdata_*.mat'); % list VW data files in current directory 
            for vid = 1:length(vidList{mouse})
                CAlabel = CAfileList(vid).name;
                CAmat = matfile(sprintf(CAlabel,vidList{mouse}(vid)));
                CAdata = CAmat.CcellData;       
                cDataFullTrace{mouse}{vid} = CAdata;
            end 
        end 
    end
    
    %get trial data to generate stimulus event triggered averages (ETAs)
    if ETAQ == 1 && optoQ == 1 ||  (exist('tTypeQ','var') == 1 && tTypeQ == 1)                 
        state_end_f2 = cell(1,length(vidList{mouse}));        
        trialLengths2 = cell(1,length(vidList{mouse}));
        velWheelData = cell(1,length(vidList{mouse}));       
        for vid = 1:length(vidList{mouse})
            [~,statestartf,stateendf,~,vel_wheel_data,trialTypes] = makeHDFchart_redBlueStim(state,framePeriod);
            state_start_f{mouse}{vid} = floor(statestartf/FPSadjust);
            state_end_f2{vid} = floor(stateendf/FPSadjust);
            TrialTypes{mouse}{vid} = trialTypes(1:length(statestartf),:);
            trialLengths2{vid} = state_end_f2{vid}-state_start_f{mouse}{vid};
            if velWheelQ == 1 
                velWheelData{vid} = vel_wheel_data;
                %resample wheel data 
                wDataFullTrace{mouse}{vid} = resample(velWheelData{vid},length(bDataFullTrace{mouse}{vid}{1}),length(velWheelData{vid}));
            end 
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
    %                 if abs(trialLengths2{vid}(trial) - stimFrameLengths(frameLength)) < 5
                        state_end_f{mouse}{vid}(trial) = state_start_f{mouse}{vid}(trial) + stimFrameLengths(frameLength);
                        trialLengths{mouse}{vid}(trial) = state_end_f{mouse}{vid}(trial)-state_start_f{mouse}{vid}(trial);
    %                 end 
                end 
            end 
        end    
    end 

    %this gets state start/end frames/times for behavior data. can input whatever value you want for the state  
    if ETAQ == 1 && optoQ == 0 
        velWheelQ = 0;
        state_end_f2 = cell(1,length(vidList{mouse}));
        trialLengths2 = cell(1,length(vidList{mouse}));
        for vid = 1:length(vidList{mouse})
            [statestartf,stateendf] = behavior_FindStateBounds(state,framePeriod);
            %[~,statestartf,stateendf,~,vel_wheel_data,trialTypes] = makeHDFchart_redBlueStim(state,framePeriod);
            state_start_f{mouse}{vid} = floor(statestartf/FPSadjust);
            if isempty(stateendf) == 0
                state_end_f2{vid} = floor(stateendf/FPSadjust);
                trialLengths2{vid} = state_end_f2{vid}-state_start_f{mouse}{vid};
            end 
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
                    state_end_f{mouse}{vid}(trial) = state_start_f{mouse}{vid}(trial) + stimFrameLengths(frameLength);
                    trialLengths{mouse}{vid}(trial) = state_end_f{mouse}{vid}(trial)-state_start_f{mouse}{vid}(trial);
                end 
            end 
        end 
    end 
end 

if STAstackQ == 1
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
        redStacks1{vid} = redRegStacks{2,4};
        greenMat = matfile(sprintf(greenlabel,vidList{mouse}(vid)));       
        greenRegStacks = greenMat.regStacks;
        greenStacks1{vid} = greenRegStacks{2,3};     
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
        for Z = 1:size(redStacks1{1},2)
            redStackArray{vid}(:,:,:,Z) = redStacksBS{vid}{Z};
            greenStackArray{vid}(:,:,:,Z) = greenStacksBS{vid}{Z};
        end 
        redStacks{vid} = mean(redStackArray{vid},4);
        greenStacks{vid} = mean(greenStackArray{vid},4);
    end 
end 

if distQ == 1
    % get registered images 
    regImDir = uigetdir('*.*','WHERE ARE THE REGISTERED IMAGES?');
    cd(regImDir);   
    redlabel = uigetfile('*.*','SELECT .MAT FILE WITH RED REGISTERED IMAGES'); 
    redMat = matfile(redlabel);       
    redRegStacks = redMat.regStacks;
    redStacks1 = redRegStacks{2,2};   
    if BGsubQ == 0 
        redStacks = redStacks1;
    elseif BGsubQ == 1
        if BGsubTypeQ == 0        
            [redStacks_BS,~] = backgroundSubtraction(redStacks1);
            redStacks = redStacks_BS;
        elseif BGsubTypeQ == 1
            [redStacks_BS,~] = backgroundSubtractionPerRow(redStacks1);
            redStacks = redStacks_BS;
        end 
    end 
    %average all the frames per Z plane 
    redZstack = zeros(size(redStacks{1},1),size(redStacks{1},2),length(redStacks));
    for Z = 1:length(redStacks)
        redZstack(:,:,Z) = mean(redStacks{Z},3);
    end 
%     clearvars -except redZstack distQ CaROImasks 
end 

%}

%% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% TO DO NEXT: UPDATE ETA AND STA CODE TO BE ABLE TO DO BATCH PROCESSING 
% - SAVE THE SMOOTHING FOR LAST (SAVE UNSMOOTHED DATA OUT)

%% ETA: organize trial data; can select what trials to plot; can separate trials by ITI length  
%{
dataParseType = input("What data do you need? Peristimulus epoch = 0. Stimulus epoch = 1. ");
if dataParseType == 0 
    sec_before_stim_start = input("How many seconds before the stimulus starts do you want to plot? ");
    sec_after_stim_end = input("How many seconds after stimulus end do you want to plot? ");
elseif dataParseType == 1 
    sec_before_stim_start = 0;
    sec_after_stim_end = 0; 
end 
numTtypes = input('How many different trial types are there? ');

% determine plotting start and end frames 
plotStart = cell(1,length(bDataFullTrace));
plotEnd = cell(1,length(bDataFullTrace));
for vid = 1:length(bDataFullTrace)
%     count = 1;
    for trial = 1:length(state_start_f{vid})  
        if trialLengths{vid}(trial) ~= 0 
            if dataParseType == 0    
                if (state_start_f{vid}(trial) - floor(sec_before_stim_start*FPSstack)) > 0 && state_end_f{vid}(trial) + floor(sec_after_stim_end*FPSstack) < length(bDataFullTrace{vid}{1})
                    plotStart{vid}(trial) = state_start_f{vid}(trial) - floor(sec_before_stim_start*FPSstack);
                    plotEnd{vid}(trial) = state_end_f{vid}(trial) + floor(sec_after_stim_end*FPSstack);                    
                end            
            elseif dataParseType == 1  
                plotStart{vid}(trial) = state_start_f{vid}(trial);
                plotEnd{vid}(trial) = state_end_f{vid}(trial);                
            end   
        end 
    end 
end 

% sort the data  
if CAQ == 1
    Ceta = cell(1,length(cDataFullTrace{1}));
end 
if BBBQ == 1 
    Beta = cell(1,length(bDataFullTrace{1}));
end 
if VWQ == 1
    Veta = cell(1,length(vDataFullTrace{1}));
end 
if velWheelQ == 1 
    Weta = cell(1,numTtypes);
end 

if CAQ == 0 
    ccellLen = 1;
elseif CAQ == 1 
    ccellLen = length(terminals);
end 

% makes faux trial type array for behavior data so all behavior data trials
% (based on selected state) get sorted into the same cell 
% For opto data, the state is either 7 or 8, but there are 4 different
% kinds of trials within those states. 
% For behavior data, you select whatever state you want, but there is only
% one trial type 
if optoQ == 0 
    TrialTypes = cell(1,length(bDataFullTrace));
    for vid = 1:length(bDataFullTrace)  
        TrialTypes{vid}(1:length(plotStart{vid}),1) = 1:length(plotStart{vid});  
        TrialTypes{vid}(1:length(plotStart{vid}),2) = 1;        
    end 
end 

% pick what trials are averaged 
trialQ = input('Input 1 to select what trials to average and plot. Input 0 for all trials. ');
if trialQ == 0
    trialList = cell(1,length(bDataFullTrace));
    for vid = 1:length(bDataFullTrace)   
        trialList{vid} = 1:length(plotStart{vid});
    end 
elseif trialQ == 1 
    trialList{vid} = input(sprintf('What trials do you want to average and plot for vid %d? ',vid));
end 

% figure out ITI length and sort ITI length into trial type 
ITIq = input('Input 1 to separate data based on ITI length. Input 0 otherwise. ');
if ITIq == 1 
    trialLenFrames = cell(1,length(bDataFullTrace));
    trialLenTimes = cell(1,length(bDataFullTrace));
    minMaxTrialLenTimes = cell(1,length(bDataFullTrace));
    for vid = 1:length(bDataFullTrace)  
        if trialList{vid}(1) > 1 
            trialLenFrames{vid}(1) = state_start_f{vid}(trialList{vid}(1))-state_start_f{vid}(trialList{vid}(1)-1);    
        elseif trialList{vid}(1) == 1 
            trialLenFrames{vid}(1) = state_start_f{vid}(trialList{vid}(1))-1;    
        end 
        trialLenFrames{vid}(2:length(trialList{vid})) = state_start_f{vid}(trialList{vid}(2:end))-state_end_f{vid}(trialList{vid}(1:end-1));
        trialLenTimes{vid} = trialLenFrames{vid}/FPSstack;
        minMaxTrialLenTimes{vid}(1) = min(trialLenTimes{vid});
        minMaxTrialLenTimes{vid}(2) = max(trialLenTimes{vid});
        figure; histogram(trialLenTimes{vid})
        display(minMaxTrialLenTimes{vid})
    end 
    trialLenThreshTime = input('Input the ITI thresh (sec) to separate data by. '); 
    trialListHigh = cell(1,length(bDataFullTrace));
    trialListLow = cell(1,length(bDataFullTrace));
    for vid = 1:length(bDataFullTrace) 
        trialListHigh{vid} = trialList{vid}((trialLenTimes{vid} >= trialLenThreshTime));
        trialListLow{vid} = trialList{vid}((trialLenTimes{vid} < trialLenThreshTime));
    end 
    ITIq2 = input(sprintf('Input 1 to plot trials with ITIs greater than %d sec. Input 0 for ITIs lower than %d sec. ',trialLenThreshTime,trialLenThreshTime));
    if ITIq2 == 0
        trialList = trialListLow;
    elseif ITIq2 == 1
        trialList = trialListHigh;
    end 
end 

for ccell = 1:ccellLen
    count1 = 1;
    count2 = 1;
    count3 = 1;
    count4 = 1;
    for vid = 1:length(bDataFullTrace)    
        for trial = 1:length(trialList{vid}) 
            if trialLengths{vid}(trialList{vid}(trial)) ~= 0 
                 if (state_start_f{vid}(trialList{vid}(trial)) - floor(sec_before_stim_start*FPSstack)) > 0 && state_end_f{vid}(trialList{vid}(trial)) + floor(sec_after_stim_end*FPSstack) < length(bDataFullTrace{vid}{1})
                    %if the blue light is on
                    if TrialTypes{vid}(trialList{vid}(trial),2) == 1
                        %if it is a 2 sec trial 
                        if trialLengths{vid}(trialList{vid}(trial)) == floor(2*FPSstack)     
                            if CAQ == 1
                                Ceta{terminals(ccell)}{1}(count1,:) = cDataFullTrace{vid}{terminals(ccell)}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                            end 
                            if BBBQ == 1 
                                for BBBroi = 1:length(bDataFullTrace{1})
                                    Beta{BBBroi}{1}(count1,:) = bDataFullTrace{vid}{BBBroi}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                end 
                            end 
                            if VWQ == 1
                                for VWroi = 1:length(vDataFullTrace{1})
                                    Veta{VWroi}{1}(count1,:) = vDataFullTrace{vid}{VWroi}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                end 
                            end 
                            if velWheelQ == 1 
                                Weta{1}(count1,:) = wDataFullTrace{vid}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                            end 
                            count1 = count1 + 1;                    
                        %if it is a 20 sec trial
                        elseif trialLengths{vid}(trialList{vid}(trial)) == floor(20*FPSstack)
                            if CAQ == 1
                                Ceta{terminals(ccell)}{2}(count2,:) = cDataFullTrace{vid}{terminals(ccell)}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                            end 
                            if BBBQ == 1 
                                for BBBroi = 1:length(bDataFullTrace{1})
                                    Beta{BBBroi}{2}(count2,:) = bDataFullTrace{vid}{BBBroi}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                end 
                            end 
                            if VWQ == 1
                                for VWroi = 1:length(vDataFullTrace{1})
                                    Veta{VWroi}{2}(count2,:) = vDataFullTrace{vid}{VWroi}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                end 
                            end 
                            if velWheelQ == 1 
                                Weta{2}(count2,:) = wDataFullTrace{vid}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                            end 
                            count2 = count2 + 1;
                        end 
                    %if the red light is on 
                    elseif TrialTypes{vid}(trialList{vid}(trial),2) == 2
                        %if it is a 2 sec trial 
                        if trialLengths{vid}(trialList{vid}(trial)) == floor(2*FPSstack)
                            if CAQ == 1
                                Ceta{terminals(ccell)}{3}(count3,:) = cDataFullTrace{vid}{terminals(ccell)}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                            end 
                            if BBBQ == 1 
                                for BBBroi = 1:length(bDataFullTrace{1})
                                    Beta{BBBroi}{3}(count3,:) = bDataFullTrace{vid}{BBBroi}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                end 
                            end 
                            if VWQ == 1
                                for VWroi = 1:length(vDataFullTrace{1})
                                    Veta{VWroi}{3}(count3,:) = vDataFullTrace{vid}{VWroi}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                end
                            end 
                            if velWheelQ == 1 
                                Weta{3}(count3,:) = wDataFullTrace{vid}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                            end 
                            count3 = count3 + 1;                    
                        %if it is a 20 sec trial
                        elseif trialLengths{vid}(trialList{vid}(trial)) == floor(20*FPSstack)
                            if CAQ == 1
                                Ceta{terminals(ccell)}{4}(count4,:) = cDataFullTrace{vid}{terminals(ccell)}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                            end 
                            if BBBQ == 1 
                                for BBBroi = 1:length(bDataFullTrace{1})
                                    Beta{BBBroi}{4}(count4,:) = bDataFullTrace{vid}{BBBroi}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                end 
                            end 
                            if VWQ == 1
                                for VWroi = 1:length(vDataFullTrace{1})
                                    Veta{VWroi}{4}(count4,:) = vDataFullTrace{vid}{VWroi}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                end 
                            end 
                            if velWheelQ == 1 
                                Weta{4}(count4,:) = wDataFullTrace{vid}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                            end 
                            count4 = count4 + 1;
                        end             
                    end 
                end 
            end 
        end         
    end
end 

% remove rows that are all 0 and then add buffer value to each trace to avoid
%negative going values 
for tType = 1:numTtypes
    if CAQ == 1
        for ccell = 1:length(terminals)    
            % replace zero values with NaNs
            nonZeroRowsC = all(Ceta{terminals(ccell)}{tType} == 0,2);
            Ceta{terminals(ccell)}{tType}(nonZeroRowsC,:) = NaN;
            % determine the minimum value, add space (+100)
            minValToAdd = abs(ceil(min(min(Ceta{terminals(ccell)}{tType}))))+100;
            % add min value 
            Ceta{terminals(ccell)}{tType} = Ceta{terminals(ccell)}{tType} + minValToAdd;                        
        end 
    end 
    if BBBQ == 1 
        for BBBroi = 1:length(bDataFullTrace{1})
            % replace zero values with NaNs 
            nonZeroRowsB = all(Beta{BBBroi}{tType} == 0,2);
            Beta{BBBroi}{tType}(nonZeroRowsB,:) = NaN;
            % determine the minimum value, add space (+100)
            minValToAdd = abs(ceil(min(min(Beta{BBBroi}{tType}))))+100;
            % add min value 
            Beta{BBBroi}{tType} = Beta{BBBroi}{tType} + minValToAdd;
        end 
    end 
    if VWQ == 1
        for VWroi = 1:length(vDataFullTrace{1})
            % replace zero values with NaNs
            nonZeroRowsV = all(Veta{VWroi}{tType} == 0,2);
            Veta{VWroi}{tType}(nonZeroRowsV,:) = NaN;
            % determine the minimum value, add space (+100)
            minValToAdd = abs(ceil(min(min(Veta{VWroi}{tType}))))+100;
            % add min value 
            Veta{VWroi}{tType} = Veta{VWroi}{tType} + minValToAdd;
        end 
    end 
    if velWheelQ == 1 
        % replace zero values with NaNs
        nonZeroRowsW = all(Weta{tType} == 0,2);
        Weta{tType}(nonZeroRowsW,:) = NaN;
        % determine the minimum value, add space (+100)
        minValToAdd = abs(ceil(min(min(Weta{tType}{tType}))))+100;
        % add min value 
        Weta{tType}{tType} = Weta{tType}{tType} + minValToAdd;
    end 
end 
%}
%% ETA: smooth trial, normalize, and plot event triggered averages 
%{
%BBBQ = 1; VWQ = 1; CAQ = 1; 
 
smoothQ =  input('Do you want to smooth your data? Yes = 1. No = 0. ');
if smoothQ ==  1
    filtTime = input('How many seconds do you want to smooth your data by? ');
    if CAQ == 1
        sCeta = cell(1,length(cDataFullTrace{1}));
    end 
    if BBBQ == 1 
        sBeta = cell(1,length(bDataFullTrace{1}));
    end 
    if VWQ == 1
        sVeta = cell(1,length(vDataFullTrace{1}));
    end
    if velWheelQ == 1 
        sWeta = cell(1,numTtypes);
    end 
    for tType = 1:numTtypes
        if CAQ == 1
            for ccell = 1:length(terminals)
                for cTrial = 1:size(Ceta{terminals(ccell)}{tType},1)
                    [sC_Data] = MovMeanSmoothData(Ceta{terminals(ccell)}{tType}(cTrial,:),filtTime,FPSstack);
                    sCeta{terminals(ccell)}{tType}(cTrial,:) = sC_Data;
                end 
            end 
        end        
        if BBBQ == 1 
            for BBBroi = 1:length(bDataFullTrace{1})
                for bTrial = 1:size(Beta{BBBroi}{tType},1)
                    [sB_Data] = MovMeanSmoothData(Beta{BBBroi}{tType}(bTrial,:),filtTime,FPSstack);
                    sBeta{BBBroi}{tType}(bTrial,:) = sB_Data;
                end 
            end 
        end 
        if VWQ == 1
            for VWroi = 1:length(vDataFullTrace{1})
                for vTrial = 1:size(Veta{VWroi}{tType},1)
                    [sV_Data] = MovMeanSmoothData(Veta{VWroi}{tType}(vTrial,:),filtTime,FPSstack);
                    sVeta{VWroi}{tType}(vTrial,:) = sV_Data;   
                end 
            end 
        end 
        if velWheelQ == 1 
            for wTrial = 1:size(Weta{tType},1)
                [sW_Data] = MovMeanSmoothData(Weta{tType}(wTrial,:),filtTime,FPSstack);
                sWeta{tType}(wTrial,:) = sW_Data;   
            end 
        end 
    end 
elseif smoothQ == 0
    if CAQ == 1
        sCeta = cell(1,length(cDataFullTrace{1}));
    end 
    if BBBQ == 1 
        sBeta = cell(1,length(bDataFullTrace{1}));
    end 
    if VWQ == 1
        sVeta = cell(1,length(vDataFullTrace{1}));
    end
    if velWheelQ == 1 
        sWeta = cell(1,numTtypes);
    end 
    for tType = 1:numTtypes
        if CAQ == 1
            for ccell = 1:length(terminals)
                for cTrial = 1:size(Ceta{terminals(ccell)}{tType},1)
                    sCeta{terminals(ccell)}{tType}(cTrial,:) = Ceta{terminals(ccell)}{tType}(cTrial,:)-100;
                end 
            end 
        end        
        if BBBQ == 1 
            for BBBroi = 1:length(bDataFullTrace{1})
                for bTrial = 1:size(Beta{BBBroi}{tType},1)
                    sBeta{BBBroi}{tType}(bTrial,:) = Beta{BBBroi}{tType}(bTrial,:)-100;
                end 
            end 
        end 
        if VWQ == 1
            for VWroi = 1:length(vDataFullTrace{1})
                for vTrial = 1:size(Veta{VWroi}{tType},1)
                    sVeta{VWroi}{tType}(vTrial,:) = Veta{VWroi}{tType}(vTrial,:)-100;   
                end 
            end 
        end 
        if velWheelQ == 1 
            for wTrial = 1:size(Weta{tType},1)
                sWeta{tType}(wTrial,:) = Weta{tType}(wTrial,:)-100;   
            end 
        end 
    end 
end 

%baseline data to average value between 0 sec and -baselineInput sec (0 sec being stim
%onset) 
baselineInput = input('How many seconds before the light turns on do you want to baseline to? ');
if CAQ == 1
    nsCeta = cell(1,length(cDataFullTrace{1}));
end 
if BBBQ == 1 
    nsBeta = cell(1,length(bDataFullTrace{1}));
end 
if VWQ == 1
    nsVeta = cell(1,length(vDataFullTrace{1}));
end 
if velWheelQ == 1 
    nsWeta = cell(1,numTtypes);
end 
if dataParseType == 0 %peristimulus data to plot 
    %sec_before_stim_start
    for tType = 1:numTtypes
        if CAQ == 1
            for ccell = 1:length(terminals)
                nsCeta{terminals(ccell)}{tType} = (sCeta{terminals(ccell)}{tType} ./ nanmean(sCeta{terminals(ccell)}{tType}(:,floor((sec_before_stim_start-baselineInput)*FPSstack):floor(sec_before_stim_start*FPSstack)),2))*100; 
            end 
        end 
        if BBBQ == 1 
            for BBBroi = 1:length(bDataFullTrace{1})
                nsBeta{BBBroi}{tType} = (sBeta{BBBroi}{tType} ./ nanmean(sBeta{BBBroi}{tType}(:,floor((sec_before_stim_start-baselineInput)*FPSstack):floor(sec_before_stim_start*FPSstack)),2))*100; 
            end 
        end 
        if VWQ == 1
            for VWroi = 1:length(vDataFullTrace{1})
                nsVeta{VWroi}{tType} = (sVeta{VWroi}{tType} ./ nanmean(sVeta{VWroi}{tType}(:,floor((sec_before_stim_start-baselineInput)*FPSstack):floor(sec_before_stim_start*FPSstack)),2))*100;        
            end 
        end 
        if velWheelQ == 1 
             nsWeta{tType} = (sWeta{tType} ./ nanmean(sWeta{tType}(:,floor((sec_before_stim_start-baselineInput)*FPSstack):floor(sec_before_stim_start*FPSstack)),2))*100; 
        end 
    end    
elseif dataParseType == 1 %only stimulus data to plot 
    if CAQ == 1
        nsCeta = sCeta;
    end 
    if BBBQ == 1 
        nsBeta = sBeta;
    end 
    if VWQ == 1
        nsVeta = sVeta;
    end 
    if velWheelQ == 1 
        nsWeta = sWeta; 
    end 
end 

% set paramaters for plotting 
AVQ = input('Input 1 to average all ROIs. Input 0 otherwise. ');
if AVQ == 1 
    if CAQ == 1 
        termList = 1:length(terminals);
    end 
end 
RedAVQ = input('Input 1 to average across all red trials. Input 0 otherwise.');
if RedAVQ == 1
    tTypeList = 3;
elseif RedAVQ == 0
    tTypeList = 1:numTtypes;
end 
BBBQ = input('Input 1 if you want to plot BBB data. Input 0 otherwise.');
if AVQ == 0 
    if BBBQ == 1
        BBBroi = input('What BBB ROI data do you want to plot? ');
    end 
end 
CAQ = input('Input 1 if you want to plot calcium data. Input 0 otherwise.');
if AVQ == 0 
    if CAQ == 1 
        allTermQ = input('Input 1 to plot all the calcium terminals. Input 0 otherwise. ');    
        if allTermQ == 1
            termList = 1:length(terminals);
        elseif allTermQ == 0
            Term = input('What terminal do you want to plot? ');
            termList = find(terminals == Term); 
        end 
    end 
end 
VWQ = input('Input 1 if you want to plot vessel width data. Input 0 otherwise.');
if AVQ == 0 
    if VWQ == 1
        VWroi = input('What vessel width ROI data do you want to plot? ');
    end 
end 
saveQ = input('Input 1 to save the figures. Input 0 otherwise. ');
if saveQ == 1                
    dir1 = input('What folder are you saving these images in? ');
end 

%sort all ROIs together 
if AVQ == 1   
    allNScETA = cell(1);
    allNSbETA = cell(1);
    allNSvETA = cell(1);
    for tType = 1:numTtypes
        count = 1;
        countB = 1;
        countV = 1;
        if CAQ == 1
            for ccell = termList 
                for trial = 1:size(nsCeta{terminals(ccell)}{tType},1)
                    allNScETA{1}{tType}(count,:) = nsCeta{terminals(ccell)}{tType}(trial,:);
                    count = count + 1;
                end        
            end 
        end 
        if BBBQ == 1
            for BBBroi = 1:length(bDataFullTrace{1})
                for trial = 1:size(nsBeta{BBBroi}{tType},1)
                    allNSbETA{1}{tType}(countB,:) = nsBeta{BBBroi}{tType}(trial,:);
                    countB = countB + 1;
                end 
            end 
        end 
        if VWQ == 1 
            for VWroi = 1:length(vDataFullTrace{1})
                for trial = 1:size(nsBeta{BBBroi}{tType},1)
                    allNSvETA{1}{tType}(countV,:) = nsVeta{VWroi}{tType}(trial,:);
                    countV = countV + 1;
                end 
            end 
        end 
    end 
    if CAQ == 1
        clearvars nsCeta
        nsCeta = allNScETA;
    end 
    if BBBQ == 1
        clearvars nsBeta
        nsBeta = allNSbETA;
    end 
    if VWQ == 1
        clearvars nsVeta
        nsVeta = allNSvETA;
    end 
end 

%sort all red trials together 
if RedAVQ == 1 
    redTrialTtypeInds = [3,4]; %THIS IS CURRENTLY HARD CODED IN, BUT DOESN'T HAVE TO BE. REPLACE EVENTUALLY.
    if AVQ == 1 
        BBBroi = 1;
        VWroi = 1;
    end 
    allRedNScETA = cell(1,length(nsCeta));
    allRedNSbETA = cell(1,numTtypes);
    allRedNSvETA = cell(1,numTtypes);
    count = 1; 
    countB = 1;
    countV = 1;
    for tType = 1:length(redTrialTtypeInds)
        if AVQ == 1
            if CAQ == 1 
                for trial = 1:size(nsCeta{1}{redTrialTtypeInds(tType)},1)
                    allRedNScETA{1}{3}(count,:) = nsCeta{1}{redTrialTtypeInds(tType)}(trial,1:size(nsCeta{1}{redTrialTtypeInds(1)},2)); 
                    count = count + 1;
                end
            end 
        elseif AVQ == 0
            if CAQ == 1 
                for ccell = termList 
                    for trial = 1:size(nsCeta{terminals(ccell)}{redTrialTtypeInds(tType)},1)
                        allRedNScETA{terminals(ccell)}{3}(count,:) = nsCeta{terminals(ccell)}{redTrialTtypeInds(tType)}(trial,1:size(nsCeta{terminals(ccell)}{redTrialTtypeInds(1)},2)); 
                        count = count + 1;
                    end 
                end      
            end 
        end 
        if BBBQ == 1 
            for Btrial = 1:size(nsBeta{BBBroi}{redTrialTtypeInds(tType)},1)
                allRedNSbETA{BBBroi}{3}(countB,:) = nsBeta{BBBroi}{redTrialTtypeInds(tType)}(Btrial,1:size(nsBeta{BBBroi}{redTrialTtypeInds(1)},2));
                countB = countB + 1;
            end 
        end 
        if VWQ == 1 
            for Vtrial = 1:size(nsVeta{VWroi}{redTrialTtypeInds(tType)},1)
                allRedNSvETA{VWroi}{3}(countV,:) = nsVeta{VWroi}{redTrialTtypeInds(tType)}(Vtrial,1:size(nsVeta{VWroi}{redTrialTtypeInds(1)},2));
                countV = countV + 1;
            end         
        end 
    end 
    clearvars nsCeta nsBeta nsVeta
    nsCeta = allRedNScETA; nsBeta = allRedNSbETA; nsVeta = allRedNSvETA;
end 

%  plot 
if AVQ == 0 
    if RedAVQ == 0 && CAQ == 0 
        termList = 1; 
    end 
    if RedAVQ == 1 && CAQ == 0 
        termList = 1; 
    end 
    for ccell = termList
        baselineEndFrame = floor(20*(FPSstack));
        if CAQ == 1
            AVcData = cell(1,length(nsCeta{terminals(ccell)}{tType}));
            SEMc = cell(1,numTtypes);
            STDc = cell(1,numTtypes);
            CI_cLow = cell(1,numTtypes);
            CI_cHigh = cell(1,numTtypes);
        end 
        if BBBQ == 1
            AVbData = cell(1,length(Beta));
            SEMb = cell(1,numTtypes);
            STDb = cell(1,numTtypes);
            CI_bLow = cell(1,numTtypes);
            CI_bHigh = cell(1,numTtypes);
        end 
        if VWQ == 1
            AVvData = cell(1,length(Beta));
            SEMv = cell(1,numTtypes);
            STDv = cell(1,numTtypes);
            CI_vLow = cell(1,numTtypes);
            CI_vHigh = cell(1,numTtypes);
        end 
        for tType = tTypeList          
            if CAQ == 1
                SEMc{terminals(ccell)}{tType} = (nanstd(nsCeta{terminals(ccell)}{tType}))/(sqrt(size(nsCeta{terminals(ccell)}{tType},1))); % Standard Error            
                STDc{terminals(ccell)}{tType} = nanstd(nsCeta{terminals(ccell)}{tType});
                ts_cLow = tinv(0.025,size(nsCeta{terminals(ccell)}{tType},1)-1);% T-Score for 95% CI
                ts_cHigh = tinv(0.975,size(nsCeta{terminals(ccell)}{tType},1)-1);% T-Score for 95% CI
                CI_cLow{terminals(ccell)}{tType} = (nanmean(nsCeta{terminals(ccell)}{tType},1)) + (ts_cLow*SEMc{terminals(ccell)}{tType});  % Confidence Intervals
                CI_cHigh{terminals(ccell)}{tType} = (nanmean(nsCeta{terminals(ccell)}{tType},1)) + (ts_cHigh*SEMc{terminals(ccell)}{tType});  % Confidence Intervals
                x = 1:length(CI_cLow{terminals(ccell)}{tType});
                AVcData{terminals(ccell)}{tType} = nanmean(nsCeta{terminals(ccell)}{tType},1);
            end 
            if BBBQ == 1
                % calculate the 95% confidence interval 
                SEMb{BBBroi}{tType} = (nanstd(nsBeta{BBBroi}{tType}))/(sqrt(size(nsBeta{BBBroi}{tType},1))); % Standard Error            
                STDb{BBBroi}{tType} = nanstd(nsBeta{BBBroi}{tType});
                ts_bLow = tinv(0.025,size(nsBeta{BBBroi}{tType},1)-1);% T-Score for 95% CI
                ts_bHigh = tinv(0.975,size(nsBeta{BBBroi}{tType},1)-1);% T-Score for 95% CI
                CI_bLow{BBBroi}{tType} = (nanmean(nsBeta{BBBroi}{tType},1)) + (ts_bLow*SEMb{BBBroi}{tType});  % Confidence Intervals
                CI_bHigh{BBBroi}{tType} = (nanmean(nsBeta{BBBroi}{tType},1)) + (ts_bHigh*SEMb{BBBroi}{tType});  % Confidence Intervals
                x = 1:length(CI_bLow{BBBroi}{tType});
                AVbData{BBBroi}{tType} = nanmean(nsBeta{BBBroi}{tType},1);
            end 
            if VWQ == 1
                % calculate the 95% confidence interval 
                SEMv{VWroi}{tType} = (nanstd(nsVeta{VWroi}{tType}))/(sqrt(size(nsVeta{VWroi}{tType},1))); % Standard Error            
                STDv{VWroi}{tType} = nanstd(nsVeta{VWroi}{tType});
                ts_vLow = tinv(0.025,size(nsVeta{VWroi}{tType},1)-1);% T-Score for 95% CI
                ts_vHigh = tinv(0.975,size(nsVeta{VWroi}{tType},1)-1);% T-Score for 95% CI
                CI_vLow{VWroi}{tType} = (nanmean(nsVeta{VWroi}{tType},1)) + (ts_vLow*SEMv{VWroi}{tType});  % Confidence Intervals
                CI_vHigh{VWroi}{tType} = (nanmean(nsVeta{VWroi}{tType},1)) + (ts_vHigh*SEMv{VWroi}{tType});  % Confidence Intervals
                x = 1:length(CI_vLow{VWroi}{tType});
                AVvData{VWroi}{tType} = nanmean(nsVeta{VWroi}{tType},1);
            end 
            fig = figure;             
            hold all;
            if tType == 1 || tType == 3 
                Frames = size(nsBeta{BBBroi}{tType},2);        
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack)+1);
                FrameVals = floor((1:FPSstack:Frames)-1); 
            elseif tType == 2 || tType == 4 
                Frames = size(nsBeta{BBBroi}{tType},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack)+10);
                FrameVals = floor((1:FPSstack:Frames)-1); 
            end 
            if BBBQ == 1 
                BBBplot = plot(AVbData{BBBroi}{tType}-100,'r','LineWidth',3);
                patch([x fliplr(x)],[CI_bLow{BBBroi}{tType}-100 fliplr(CI_bHigh{BBBroi}{tType}-100)],[0.5 0 0],'EdgeColor','none')
            end 
            if CAQ == 1 
                CaPlot = plot(AVcData{terminals(ccell)}{tType}-100,'b','LineWidth',3);
                patch([x fliplr(x)],[CI_cLow{terminals(ccell)}{tType}-100 fliplr(CI_cHigh{terminals(ccell)}{tType}-100)],[0 0 0.5],'EdgeColor','none');
                
            end 
            if VWQ == 1
                VWplot = plot(AVvData{VWroi}{tType}-100,'k','LineWidth',3);
                patch([x fliplr(x)],[CI_vLow{VWroi}{tType}-100 fliplr(CI_vHigh{VWroi}{tType}-100)],'k','EdgeColor','none')           
            end 
%             legend('BBB Permeability','Vessel Width')
            if tType == 1 
%                 plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000000 5000000], 'b','LineWidth',2)
%                 plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'b','LineWidth',2) 
            elseif tType == 3 
%                 plot(AVbData{tType},'k','LineWidth',3)
                plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000000 5000000], 'r','LineWidth',2)
%                 plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'k','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'r','LineWidth',2)                      
            elseif tType == 2 
                plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000000 5000000], 'b','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'b','LineWidth',2)   
            elseif tType == 4 
%                 plot(AVbData{tType},'r','LineWidth',3)
                plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000000 5000000], 'r','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'r','LineWidth',2) 
            end
%             colorSet = varycolor(size(nsCeta{terminals(ccell)}{tType},1));            
%             for trial = 1:size(nsCeta{terminals(ccell)}{tType},1)
%                 plot(nsCeta{terminals(ccell)}{tType}(trial,:),'Color',colorSet(trial,:),'LineWidth',1.5)
%             end 
%             legend('DA calcium','BBB permeability','Location','northwest','FontName','Times')
%             legend('vessel width')
%             legend([BBBplot VWplot],{'BBB Permeability' 'Vessel Width'})
            ax=gca;
            ax.XTick = FrameVals;
            ax.XTickLabel = sec_TimeVals;
            ax.FontSize = 30;
            ax.FontName = 'Arial';
%                 xLimStart = 17.8*FPSstack;
%                 xLimEnd = 22*FPSstack;
            xlim([1 length(AVcData{terminals(ccell)}{tType})]) 
%             xlim([1 length(AVbData{BBBroi}{tType})])
%                 xlim([xLimStart xLimEnd])
            ylim([-15 25])
            xlabel('time (s)')
            ylabel('percent change')
            label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
            label1.FontSize = 30;
            label1.FontName = 'Arial';
            label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack))*2),'-k',{'water reward'},'LineWidth',2);
            label2.FontSize = 30;
            label2.FontName = 'Arial';
            % initialize empty string array 
            label = strings;
            if BBBQ == 1
                label = append(label,sprintf('  BBB ROI %d',BBBroi)); 
            end 
            if CAQ == 1 
                label = append(label,sprintf('  Ca ROI %d',terminals(ccell)));
            end 
            if VWQ == 1
                label = append(label,sprintf('  Vessel width ROI %d',VWroi));
            end 
%             title({'Optogenetic Stimulation';'Event Triggered Averages';label},'FontName','Times');
            title({'Event Triggered Averages';label},'FontName','Arial');
            set(fig,'position', [100 100 900 900])
            alpha(0.5) 
           %make the directory and save the images            
            if saveQ == 1                
                if tType == 1
                    label2 = (' 2 sec Blue Light');
                elseif tType == 2
                    label2 = (' 20 sec Blue Light');
                elseif tType == 3
                    label2 = (' 2 sec Red Light');
                elseif tType == 4
                    label2 = (' 20 sec Red Light');
                end   
                dir2 = strrep(dir1,'\','/');
                dir3 = sprintf('%s/%s%s.tif',dir2,label,label2);
                export_fig(dir3)
            end                      
        end 
    end 
elseif AVQ == 1
    baselineEndFrame = floor(20*(FPSstack));
        if CAQ == 1
            AVcData = cell(1,length(nsCeta{1}{tType}));
            SEMc = cell(1,numTtypes);
            STDc = cell(1,numTtypes);
            CI_cLow = cell(1,numTtypes);
            CI_cHigh = cell(1,numTtypes);
        end 
        if BBBQ == 1
            AVbData = cell(1,length(nsBeta{1}{tType}));
            SEMb = cell(1,numTtypes);
            STDb = cell(1,numTtypes);
            CI_bLow = cell(1,numTtypes);
            CI_bHigh = cell(1,numTtypes);
        end 
        if VWQ == 1
            AVvData = cell(1,length(nsVeta{1}{tType}));
            SEMv = cell(1,numTtypes);
            STDv = cell(1,numTtypes);
            CI_vLow = cell(1,numTtypes);
            CI_vHigh = cell(1,numTtypes);
        end 
        for tType = tTypeList            
            if CAQ == 1
                SEMc{1}{tType} = (nanstd(nsCeta{1}{tType}))/(sqrt(size(nsCeta{1}{tType},1))); % Standard Error            
                STDc{1}{tType} = nanstd(nsCeta{1}{tType});
                ts_cLow = tinv(0.025,size(nsCeta{1}{tType},1)-1);% T-Score for 95% CI
                ts_cHigh = tinv(0.975,size(nsCeta{1}{tType},1)-1);% T-Score for 95% CI
                CI_cLow{1}{tType} = (nanmean(nsCeta{1}{tType},1)) + (ts_cLow*SEMc{1}{tType});  % Confidence Intervals
                CI_cHigh{1}{tType} = (nanmean(nsCeta{1}{tType},1)) + (ts_cHigh*SEMc{1}{tType});  % Confidence Intervals
                x = 1:length(CI_cLow{1}{tType});
                AVcData{1}{tType} = nanmean(nsCeta{1}{tType},1);
            end 
            if BBBQ == 1
                % calculate the 95% confidence interval 
                SEMb{1}{tType} = (nanstd(nsBeta{1}{tType}))/(sqrt(size(nsBeta{1}{tType},1))); % Standard Error            
                STDb{1}{tType} = nanstd(nsBeta{1}{tType});
                ts_bLow = tinv(0.025,size(nsBeta{1}{tType},1)-1);% T-Score for 95% CI
                ts_bHigh = tinv(0.975,size(nsBeta{1}{tType},1)-1);% T-Score for 95% CI
                CI_bLow{1}{tType} = (nanmean(nsBeta{1}{tType},1)) + (ts_bLow*SEMb{1}{tType});  % Confidence Intervals
                CI_bHigh{1}{tType} = (nanmean(nsBeta{1}{tType},1)) + (ts_bHigh*SEMb{1}{tType});  % Confidence Intervals
                x = 1:length(CI_bLow{1}{tType});
                AVbData{1}{tType} = nanmean(nsBeta{1}{tType},1);
            end 
            if VWQ == 1
                % calculate the 95% confidence interval 
                SEMv{1}{tType} = (nanstd(nsVeta{1}{tType}))/(sqrt(size(nsVeta{1}{tType},1))); % Standard Error            
                STDv{1}{tType} = nanstd(nsVeta{1}{tType});
                ts_vLow = tinv(0.025,size(nsVeta{1}{tType},1)-1);% T-Score for 95% CI
                ts_vHigh = tinv(0.975,size(nsVeta{1}{tType},1)-1);% T-Score for 95% CI
                CI_vLow{1}{tType} = (nanmean(nsVeta{1}{tType},1)) + (ts_vLow*SEMv{1}{tType});  % Confidence Intervals
                CI_vHigh{1}{tType} = (nanmean(nsVeta{1}{tType},1)) + (ts_vHigh*SEMv{1}{tType});  % Confidence Intervals
                x = 1:length(CI_vLow{1}{tType});
                AVvData{1}{tType} = nanmean(nsVeta{1}{tType},1);
            end 
            fig = figure;             
            hold all;
            if tType == 1 || tType == 3 
                Frames = size(nsBeta{1}{tType},2);        
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack)+1);
                FrameVals = floor((1:FPSstack:Frames)-1); 
            elseif tType == 2 || tType == 4 
                Frames = size(nsBeta{1}{tType},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack)+10);
                FrameVals = floor((1:FPSstack:Frames)-1); 
            end 
            if BBBQ == 1 
                plot(AVbData{1}{tType}-100,'r','LineWidth',3)
                patch([x fliplr(x)],[CI_bLow{1}{tType}-100 fliplr(CI_bHigh{1}{tType}-100)],[0.5 0 0],'EdgeColor','none')
            end 
            if CAQ == 1 
                plot(AVcData{1}{tType}-100,'b','LineWidth',3)
                patch([x fliplr(x)],[CI_cLow{1}{tType}-100 fliplr(CI_cHigh{1}{tType}-100)],[0 0 0.5],'EdgeColor','none')
            end 
            if VWQ == 1
                plot(AVvData{1}{tType}-100,'k','LineWidth',3)
                patch([x fliplr(x)],[CI_vLow{1}{tType}-100 fliplr(CI_vHigh{1}{tType}-100)],'k','EdgeColor','none')            
            end 
            if tType == 1 
                plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'b','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
            elseif tType == 3 
%                 plot(AVbData{tType},'k','LineWidth',3)
                plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'r','LineWidth',2)
%                 plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'k','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2)                      
            elseif tType == 2 
                plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'b','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2)   
            elseif tType == 4 
%                 plot(AVbData{tType},'r','LineWidth',3)
                plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'r','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
            end
%             colorSet = varycolor(size(nsCeta{terminals(ccell)}{tType},1));            
%             for trial = 1:size(nsCeta{terminals(ccell)}{tType},1)
%                 plot(nsCeta{terminals(ccell)}{tType}(trial,:),'Color',colorSet(trial,:),'LineWidth',1.5)
%             end 
%             legend('DA calcium','BBB permeability','Location','northwest','FontName','Times')
%             legend('vessel width')
            ax=gca;
            ax.XTick = FrameVals;
            ax.XTickLabel = sec_TimeVals;
            ax.FontSize = 30;
            ax.FontName = 'Arial';
%                 xLimStart = 18*FPSstack;
%                 xLimEnd = 32*FPSstack;
            xlim([1 length(AVbData{1}{tType})])
%                 xlim([xLimStart xLimEnd])
            ylim([-100 100])
            xlabel('time (s)')
            ylabel('percent change')
            % initialize empty string array 
            label = strings;
            label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
            label1.FontSize = 30;
            label1.FontName = 'Arial';
            label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack))*2),'-k',{'water reward'},'LineWidth',2);
            label2.FontSize = 30;
            label2.FontName = 'Arial';
            if BBBQ == 1
                label = append(label,'  BBB ROIs averaged'); 
            end 
            if CAQ == 1 
                label = append(label,'  Ca ROIs averaged');
            end 
            if VWQ == 1
                label = append(label,'  Vessel width ROIs averaged ');
            end 
            title({'Optogenetic Stimulation';'Event Triggered Averages';label},'FontName','Times');
            title({'Event Triggered Averages';label},'FontName','Arial');
            set(fig,'position', [100 100 900 900])
            alpha(0.5) 
           %make the directory and save the images            
            if saveQ == 1                
                if tType == 1
                    label2 = (' 2 sec Blue Light');
                elseif tType == 2
                    label2 = (' 20 sec Blue Light');
                elseif tType == 3
                    label2 = (' 2 sec Red Light');
                elseif tType == 4
                    label2 = (' 20 sec Red Light');
                end   
                dir2 = strrep(dir1,'\','/');
                dir3 = sprintf('%s/%s%s.tif',dir2,label,label2);
                export_fig(dir3)
            end                 
        end 
end 
%}
%% ETA: average across mice 
% does not take already smooothed/normalized data. Will ask you about
% smoothing/normalizing below 
% will separate data based on trial number and ITI length (so give it all
% the trials per mouse)
%{
%get the data you need 
mouseNum = input('How many mice are there? ');
CAQ = input('Input 1 if there is Ca data to plot. ');
BBBQ = input('Input 1 if there is BBB data to plot. ');
VWQ = input('Input 1 if there is VW data to plot. ');
FPSstack = cell(1,mouseNum); 
Ceta = cell(1,mouseNum); 
Beta = cell(1,mouseNum); 
Veta = cell(1,mouseNum); 
CaROIs = cell(1,mouseNum); 
state_start_f = cell(1,mouseNum); 
state_end_f = cell(1,mouseNum); 
TrialTypes = cell(1,mouseNum);
trialLengths = cell(1,mouseNum);
for mouse = 1:mouseNum
    regImDir = uigetdir('*.*',sprintf('WHERE IS THE ETA DATA FOR MOUSE #%d?',mouse));
    cd(regImDir);
    MatFileName = uigetfile('*.*',sprintf('SELECT THE ETA DATA FOR MOUSE #%d',mouse));
    Mat = matfile(MatFileName);
    FPSstack{mouse} = Mat.FPSstack;
    state_start_f{mouse} = Mat.state_start_f;
    state_end_f{mouse} = Mat.state_end_f;
    TrialTypes{mouse} = Mat.TrialTypes;
    trialLengths{mouse} = Mat.trialLengths;
    if CAQ == 1 
        Ceta{mouse} = Mat.Ceta;
        CaROIs{mouse} = input(sprintf('What are the Ca ROIs for mouse #%d? ',mouse));
    end 
    if BBBQ == 1
        Beta{mouse} = Mat.Beta;
    end 
    if VWQ == 1 
        Veta{mouse} = Mat.Veta;
    end 
end 

%%
% figure out the size you should resample your data to 
%the min length names (dependent on length(tTypes))are hard coded in 
FPSstack2 = zeros(1,mouseNum);
for mouse = 1:mouseNum
    FPSstack2(mouse) = FPSstack{mouse};
end 
minFPSstack = FPSstack2 == min(FPSstack2);
idx = find(minFPSstack ~= 0, 1, 'first');
if CAQ == 1
    if length(Ceta{idx}{CaROIs{idx}(1)}) > 1 
        minLen24 = size(Ceta{idx}{CaROIs{idx}(1)}{2},2);
    end 
    minLen13 = size(Ceta{idx}{CaROIs{idx}(1)}{1},2);
elseif CAQ ~= 1 && BBBQ == 1
    if length(Beta{idx}{1}) > 1 
        minLen24 = size(Beta{idx}{1}{2},2);
    end 
    minLen13 = size(Beta{idx}{1}{1},2);
elseif CAQ ~= 1 && VWQ == 1 
    if length(Veta{idx}{1}) > 1 
        minLen24 = size(Veta{idx}{1}{2},2);
    end 
    minLen13 = size(Veta{idx}{1}{1},2);
end 

%sort data
tTypeNum = max(unique(TrialTypes{1}{1}(:,2))); 

% put all ROI traces together in same array etaArray1{mouse}{tType} and
% resample across mice 
CetaArray1 = cell(1,mouseNum);
BetaArray1 = cell(1,mouseNum);
VetaArray1 = cell(1,mouseNum);
CetaArray = cell(1,tTypeNum);
BetaArray = cell(1,tTypeNum);
VetaArray = cell(1,tTypeNum);
CetaAvs = cell(1,tTypeNum);
BetaAvs = cell(1,tTypeNum);
VetaAvs = cell(1,tTypeNum);
sCetaAvs = cell(1,tTypeNum);
sBetaAvs = cell(1,tTypeNum);
sVetaAvs = cell(1,tTypeNum);
snCetaAvs = cell(1,tTypeNum);
snBetaAvs = cell(1,tTypeNum);
snVetaAvs = cell(1,tTypeNum);
SEMc = cell(1,tTypeNum);
STDc = cell(1,tTypeNum);
CI_cLow = cell(1,tTypeNum);
CI_cHigh = cell(1,tTypeNum);
AVcData = cell(1,tTypeNum);
SEMb = cell(1,tTypeNum);
STDb = cell(1,tTypeNum);
CI_bLow = cell(1,tTypeNum);
CI_bHigh = cell(1,tTypeNum);
AVbData = cell(1,tTypeNum);
SEMv = cell(1,tTypeNum);
STDv = cell(1,tTypeNum);
CI_vLow = cell(1,tTypeNum);
CI_vHigh = cell(1,tTypeNum);
AVvData = cell(1,tTypeNum);
smoothQ =  input('Do you want to smooth your data? Yes = 1. No = 0. ');
if smoothQ == 1 
    filtTime = input('How many seconds do you want to smooth your data by? ');
end
dataParseType = input("What data do you have? Peristimulus = 0. Stimulus on = 1. ");
if dataParseType == 0 %peristimulus data to plot 
    baselineInput = input('How many seconds before the light turns on do you want to baseline to? ');
    sec_before_stim_start = input("How many seconds are there before the stimulus starts? ");
    sec_after_stim_end = input("How many seconds are there after the stimulus ends? ");
    baselineEndFrame = floor(sec_before_stim_start*(FPSstack{idx}));
end 

% make it possible to select what trials you want to average per mouse 
trialQ = input('Input 1 to select what trials to average per mouse. Input 0 otherwise. ');
trials = cell(1,mouseNum);
tTypeTrials = cell(1,mouseNum);
for mouse = 1:mouseNum 
    % figure out what trial type each trial got sorted into 
    for vid = 1:length(TrialTypes{mouse})  
        if trialQ == 1 
            trials{mouse}{vid} = input(sprintf('Input what trials you want to average for mouse %d vid %d. ',mouse,vid));
        elseif trialQ == 0 
            trials{mouse}{vid} = 1:length(trialLengths{mouse}{vid});
        end 
        for trial = 1:length(trials{mouse}{vid})
            %if the blue light is on
            if TrialTypes{mouse}{vid}(trials{mouse}{vid}(trial),2) == 1
                %if it is a 2 sec trial 
                if trialLengths{mouse}{vid}(trials{mouse}{vid}(trial)) == floor(2*FPSstack{mouse})  
                    tTypeTrials{mouse}{vid}{1}(trial) = trials{mouse}{vid}(trial);
                %if it is a 20 sec trial
                elseif trialLengths{mouse}{vid}(trials{mouse}{vid}(trial)) == floor(20*FPSstack{mouse})
                    tTypeTrials{mouse}{vid}{2}(trial) = trials{mouse}{vid}(trial);
                end 
            %if the red light is on 
            elseif TrialTypes{mouse}{vid}(trials{mouse}{vid}(trial),2) == 2
                %if it is a 2 sec trial 
                if trialLengths{mouse}{vid}(trials{mouse}{vid}(trial)) == floor(2*FPSstack{mouse})
                    tTypeTrials{mouse}{vid}{3}(trial) = trials{mouse}{vid}(trial);
                %if it is a 20 sec trial
                elseif trialLengths{mouse}{vid}(trials{mouse}{vid}(trial)) == floor(20*FPSstack{mouse})
                    tTypeTrials{mouse}{vid}{4}(trial) = trials{mouse}{vid}(trial);
                end 
            end                 
        end 
    end      
end 
if CAQ == 1          
    Ctraces= tTypeTrials;            
end 
if BBBQ == 1 
    Btraces= tTypeTrials;
end 
if VWQ == 1 
    Vtraces= tTypeTrials;            
end  

% figure out ITI length and sort ITI length into trial type 
ITIq = input('Input 1 to separate data based on ITI length. Input 0 otherwise. ');
if ITIq == 1
    if CAQ == 1
        trialList = Ctraces; 
    elseif CAQ == 0 && BBBQ == 1 
        trialList = Btraces;
    elseif CAQ == 0 && VWQ == 1
        trialList = Vtraces; 
    end 
    trialLenFrames = cell(1,mouseNum);
    trialLenTimes = cell(1,mouseNum); 
    for mouse = 1:mouseNum 
        for vid = 1:length(state_start_f{mouse})  
            for tType = 1:tTypeNum
                if trialList{mouse}{vid}{tType}(1) > 1                     
                    trialLenFrames{mouse}{vid}{tType}(1) = state_start_f{mouse}{vid}(trialList{mouse}{vid}{tType}(1))-state_start_f{mouse}{vid}(trialList{mouse}{vid}{tType}(1)-1);    
                elseif trialList{mouse}{vid}{tType}(1) == 1 
                    trialLenFrames{mouse}{vid}{tType}(1) = state_start_f{mouse}{vid}(trialList{mouse}{vid}{tType}(1))-1;    
                end 
                trialLenFrames{mouse}{vid}{tType}(2:length(trialList{mouse}{vid}{tType})) = state_start_f{mouse}{vid}(trialList{mouse}{vid}{tType}(2:end))-state_end_f{mouse}{vid}(trialList{mouse}{vid}{tType}(1:end-1));
                trialLenTimes{mouse}{vid}{tType} = trialLenFrames{mouse}{vid}{tType}/FPSstack{mouse};
            end 
        end 
    end 
    trialLenThreshTime = input('Input the ITI thresh (sec) to separate data by. '); 
    trialListHigh = cell(1,mouseNum);
    trialListLow = cell(1,mouseNum); 
    for mouse = 1:mouseNum 
        for vid = 1:length(state_start_f{mouse}) 
            for tType = 1:tTypeNum
                trialListHigh{mouse}{vid}{tType} = trialList{mouse}{vid}{tType}((trialLenTimes{mouse}{vid}{tType} >= trialLenThreshTime));
                trialListLow{mouse}{vid}{tType} = trialList{mouse}{vid}{tType}((trialLenTimes{mouse}{vid}{tType} < trialLenThreshTime));
            end
        end 
    end 
    ITIq2 = input(sprintf('Input 1 to plot trials with ITIs greater than %d sec. Input 0 for ITIs lower than %d sec. ',trialLenThreshTime,trialLenThreshTime));
    if ITIq2 == 0
        trialList = trialListLow;
    elseif ITIq2 == 1
        trialList = trialListHigh;
    end 
    if CAQ == 1
        Ctraces = trialList; 
    end 
    if BBBQ == 1
        Btraces = trialList; 
    end 
    if VWQ == 1
        Vtraces = trialList; 
    end 
end 

% resort eta data into vids 
Ceta2 = cell(1,mouseNum);
Beta2 = cell(1,mouseNum);
Veta2 = cell(1,mouseNum);
for mouse = 1:mouseNum
    for tType = 1:tTypeNum
        if CAQ == 1
            for CaROI = 1:size(CaROIs{mouse},2)
                count = 1;
                for vid = 1:length(state_start_f{mouse}) 
                    for trace = 1:length(trialLengths{mouse}{tType})
                        if count <= size(Ceta{mouse}{CaROIs{mouse}(CaROI)}{tType},1)
                            Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tType}(trace,:) = Ceta{mouse}{CaROIs{mouse}(CaROI)}{tType}(count,:);
                            count = count + 1;
                        end 
                    end 
                end 
            end 
        end 
        if BBBQ == 1 
            for BBBroi = 1:size(Beta{mouse},2)  
                count = 1;
                for vid = 1:length(state_start_f{mouse}) 
                    for trace = 1:length(trialLengths{mouse}{tType})
                        if count <= size(Beta{mouse}{BBBroi}{tType},1)
                            Beta2{mouse}{BBBroi}{vid}{tType}(trace,:) = Beta{mouse}{BBBroi}{tType}(count,:);
                            count = count + 1;
                        end 
                    end 
                end 
            end 
        end 
        if VWQ == 1
            for VWroi = 1:size(Veta{mouse},2)
                count = 1;
                for vid = 1:length(state_start_f{mouse}) 
                    for trace = 1:length(trialLengths{mouse}{tType})
                        if count <= size(Veta{mouse}{VWroi}{tType},1)
                            Veta2{mouse}{VWroi}{vid}{tType}(trace,:) = Veta{mouse}{VWroi}{tType}(count,:);
                            count = count + 1;
                        end 
                    end 
                end 
            end 
        end 
    end 
end 

% select specific trials, resample, and plot data 
snCetaArray = cell(1,tTypeNum);
snBetaArray = cell(1,tTypeNum);
snVetaArray = cell(1,tTypeNum);
for tType = 1:tTypeNum
    Ccounter2 = 1;
    Bcounter2 = 1;
    Vcounter2 = 1;
    for mouse = 1:mouseNum   
        Ccounter = 1;
        Bcounter = 1; 
        Vcounter = 1; 
        Ccounter1 = 1;
        Bcounter1 = 1; 
        Vcounter1 = 1; 
        for vid = 1:length(state_start_f{mouse}) 
            if tType == 1 || tType == 3  
                if CAQ == 1                    
                    for CaROI = 1:size(CaROIs{mouse},2)
                        for trace = 1:length(Ctraces{mouse}{vid}{tType})
                            if size(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tType},1) >= Ctraces{mouse}{vid}{tType}(trace)
                                CetaArray1{mouse}{tType}(Ccounter,:) =  resample(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tType}(Ctraces{mouse}{vid}{tType}(trace),:),minLen13,size(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tType}(Ctraces{mouse}{vid}{tType}(trace),:),2)); 
                                Ccounter = Ccounter + 1; 
                            end 
                        end 
                    end 
                end 
                if BBBQ == 1                     
                    for BBBroi = 1:size(Beta{mouse},2)  
                        for trace = 1:length(Btraces{mouse}{vid}{tType})
                            if size(Beta2{mouse}{BBBroi}{vid}{tType},1) >= Btraces{mouse}{vid}{tType}(trace)
                                BetaArray1{mouse}{tType}(Bcounter,:) =  resample(Beta2{mouse}{BBBroi}{vid}{tType}(Btraces{mouse}{vid}{tType}(trace),:),minLen13,size(Beta2{mouse}{BBBroi}{vid}{tType}(Btraces{mouse}{vid}{tType}(trace),:),2)); %Beta{mouse}{BBBroi}{tType}(trace,:); 
                                Bcounter = Bcounter + 1; 
                            end 
                        end 
                    end 
                end 
                if VWQ == 1                     
                    for VWroi = 1:size(Veta{mouse},2)
                        for trace = 1:length(Vtraces{mouse}{vid}{tType})
                            if size(Veta2{mouse}{VWroi}{vid}{tType},1) >= Vtraces{mouse}{vid}{tType}(trace)
                                VetaArray1{mouse}{tType}(Vcounter,:) = resample(Veta2{mouse}{VWroi}{vid}{tType}(Vtraces{mouse}{vid}{tType}(trace),:),minLen13,size(Veta2{mouse}{VWroi}{vid}{tType}(Vtraces{mouse}{vid}{tType}(trace),:),2));% Veta{mouse}{VWroi}{tType}(trace,:); 
                                Vcounter = Vcounter + 1; 
                            end 
                        end 
                    end 
                end 
            elseif tType == 2 || tType == 4
                if CAQ == 1                    
                    for CaROI = 1:size(CaROIs{mouse},2)
                        for trace = 1:length(Ctraces{mouse}{vid}{tType})
                            CetaArray1{mouse}{tType}(Ccounter1,:) =  resample(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tType}(Ctraces{mouse}{vid}{tType}(trace),:),minLen24,size(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tType}(Ctraces{mouse}{vid}{tType}(trace),:),2)); 
                            Ccounter1 = Ccounter1 + 1; 
                        end 
                    end 
                end 
                if BBBQ == 1 
                    
                    for BBBroi = 1:size(Beta{mouse},2)  
                        for trace = 1:length(Btraces{mouse}{vid}{tType})
                            BetaArray1{mouse}{tType}(Bcounter1,:) =  resample(Beta2{mouse}{BBBroi}{vid}{tType}(Btraces{mouse}{vid}{tType}(trace),:),minLen24,size(Beta2{mouse}{BBBroi}{vid}{tType}(Btraces{mouse}{vid}{tType}(trace),:),2)); %Beta{mouse}{BBBroi}{tType}(trace,:); 
                            Bcounter1 = Bcounter1 + 1; 
                        end 
                    end 
                end 
                if VWQ == 1 
                    for VWroi = 1:size(Veta{mouse},2)
                        for trace = 1:length(Vtraces{mouse}{vid}{tType})
                            VetaArray1{mouse}{tType}(Vcounter1,:) = resample(Veta2{mouse}{VWroi}{vid}{tType}(Vtraces{mouse}{vid}{tType}(trace),:),minLen24,size(Veta2{mouse}{VWroi}{vid}{tType}(Vtraces{mouse}{vid}{tType}(trace),:),2));% Veta{mouse}{VWroi}{tType}(trace,:); 
                            Vcounter1 = Vcounter1 + 1; 
                        end 
                    end 
                end 
            end 
        end 
    end
    for mouse = 1:mouseNum  
        % put all mouse traces together into same array CetaArray{tType}          
        if CAQ == 1
            for trace = 1:size(CetaArray1{mouse}{tType},1)
                CetaArray{tType}(Ccounter2,:) = CetaArray1{mouse}{tType}(trace,:);
                Ccounter2 = Ccounter2 + 1 ; 
            end 
        end    
        if BBBQ == 1
            for trace = 1:size(BetaArray1{mouse}{tType},1)
                BetaArray{tType}(Bcounter2,:) = BetaArray1{mouse}{tType}(trace,:);
                Bcounter2 = Bcounter2 + 1 ; 
            end 
        end  
        if VWQ == 1
            for trace = 1:size(VetaArray1{mouse}{tType},1)
                VetaArray{tType}(Vcounter2,:) = VetaArray1{mouse}{tType}(trace,:);
                Vcounter2 = Vcounter2 + 1 ; 
            end 
        end 
    end 
    %smooth tType data 
    if smoothQ == 0 
        if CAQ == 1
            sCetaAvs{tType} = CetaArray{tType};
        end 
        if BBBQ == 1
            sBetaAvs{tType} = BetaArray{tType};
        end
        if VWQ == 1
            sVetaAvs{tType} = VetaArray{tType};
        end
    elseif smoothQ == 1 
        if CAQ == 1
            sCetaAv =  MovMeanSmoothData(CetaArray{tType},filtTime,FPSstack{idx}); %CetaAvs{tType};
            sCetaAvs{tType} = sCetaAv; 
        end 
        if BBBQ == 1
            sBetaAv =  MovMeanSmoothData(BetaArray{tType},filtTime,FPSstack{idx}); %CetaAvs{tType};
            sBetaAvs{tType} = sBetaAv; 
        end 
        if VWQ == 1
            sVetaAv =  MovMeanSmoothData(VetaArray{tType},filtTime,FPSstack{idx}); %CetaAvs{tType};
            sVetaAvs{tType} = sVetaAv; 
        end
    end 
    % baseline tType data to average value between 0 sec and -baselineInput sec (0 sec being stim
    %onset) 
    if dataParseType == 0 %peristimulus data to plot 
        %sec_before_stim_start       
        if CAQ == 1
            snCetaArray{tType} = ((sCetaAvs{tType} ./ nanmean(sCetaAvs{tType}(:,floor((sec_before_stim_start-baselineInput)*FPSstack{idx}):floor(sec_before_stim_start*FPSstack{idx})),2))*100);              
        end 
        if BBBQ == 1 
            snBetaArray{tType} = ((sBetaAvs{tType} ./ nanmean(sBetaAvs{tType}(:,floor((sec_before_stim_start-baselineInput)*FPSstack{idx}):floor(sec_before_stim_start*FPSstack{idx})),2))*100);              
        end 
        if VWQ == 1
            snVetaArray{tType} = ((sVetaAvs{tType} ./ nanmean(sVetaAvs{tType}(:,floor((sec_before_stim_start-baselineInput)*FPSstack{idx}):floor(sec_before_stim_start*FPSstack{idx})),2))*100);              
        end 
    elseif dataParseType == 1 %only stimulus data to plot 
        if CAQ == 1
            snCetaArray = sCetaAvs; 
        end 
        if BBBQ == 1 
            snBetaArray = sBetaAvs;
        end 
        if VWQ == 1
            snVetaArray = sVetaAvs;
        end 
    end 
    
    % determine 95% CI and av data 
    if CAQ == 1
        SEMc{tType} = (nanstd(snCetaArray{tType}))/(sqrt(size(snCetaArray{tType},1))); % Standard Error            
        STDc{tType} = nanstd(snCetaArray{tType});
        ts_cLow = tinv(0.025,size(snCetaArray{tType},1)-1);% T-Score for 95% CI
        ts_cHigh = tinv(0.975,size(snCetaArray{tType},1)-1);% T-Score for 95% CI
        CI_cLow{tType} = (nanmean(snCetaArray{tType},1)) + (ts_cLow*SEMc{tType});  % Confidence Intervals
        CI_cHigh{tType} = (nanmean(snCetaArray{tType},1)) + (ts_cHigh*SEMc{tType});  % Confidence Intervals
        x = 1:length(CI_cLow{tType});
        AVcData{tType} = nanmean(snCetaArray{tType},1);
    end 
    if BBBQ == 1
        SEMb{tType} = (nanstd(snBetaArray{tType}))/(sqrt(size(snBetaArray{tType},1))); % Standard Error            
        STDb{tType} = nanstd(snBetaArray{tType});
        ts_bLow = tinv(0.025,size(snBetaArray{tType},1)-1);% T-Score for 95% CI
        ts_bHigh = tinv(0.975,size(snBetaArray{tType},1)-1);% T-Score for 95% CI
        CI_bLow{tType} = (nanmean(snBetaArray{tType},1)) + (ts_bLow*SEMb{tType});  % Confidence Intervals
        CI_bHigh{tType} = (nanmean(snBetaArray{tType},1)) + (ts_bHigh*SEMb{tType});  % Confidence Intervals
        x = 1:length(CI_bLow{tType});
        AVbData{tType} = nanmean(snBetaArray{tType},1);
    end 
    if VWQ == 1
        SEMv{tType} = (nanstd(snVetaArray{tType}))/(sqrt(size(snVetaArray{tType},1))); % Standard Error            
        STDv{tType} = nanstd(snVetaArray{tType});
        ts_vLow = tinv(0.025,size(snVetaArray{tType},1)-1);% T-Score for 95% CI
        ts_vHigh = tinv(0.975,size(snVetaArray{tType},1)-1);% T-Score for 95% CI
        CI_vLow{tType} = (nanmean(snVetaArray{tType},1)) + (ts_vLow*SEMv{tType});  % Confidence Intervals
        CI_vHigh{tType} = (nanmean(snVetaArray{tType},1)) + (ts_vHigh*SEMv{tType});  % Confidence Intervals
        x = 1:length(CI_vLow{tType});
        AVvData{tType} = nanmean(snVetaArray{tType},1);
    end 
    % plot Ca data 
    if CAQ == 1 
        fig = figure;             
        hold all;
        Frames = size(AVbData{tType},2);        
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        plot(AVcData{tType}-100,'b','LineWidth',3)
        patch([x fliplr(x)],[CI_cLow{tType}-100 fliplr(CI_cHigh{tType}-100)],[0 0 0.5],'EdgeColor','none')
        if tType == 1 
%             plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000 5000], 'b','LineWidth',2)
%             plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{idx}:Frames_post_stim_start)/FPSstack{idx})+1);
            FrameVals = floor((1:FPSstack{idx}:Frames)-1); 
            label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
            label1.FontSize = 30;
            label1.FontName = 'Arial';
            label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack{idx}))*2),'-k',{'water reward'},'LineWidth',2);
            label2.FontSize = 30;
        elseif tType == 3 
            plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000 5000], 'r','LineWidth',2)
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2)   
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{idx}*2:Frames_post_stim_start)/FPSstack{idx})+1);
            FrameVals = floor((1:FPSstack{idx}*2:Frames)-1); 
        elseif tType == 2 
            plot([round(baselineEndFrame+((FPSstack{idx})*20)) round(baselineEndFrame+((FPSstack{idx})*20))], [-5000 5000], 'b','LineWidth',2)
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2)   
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{idx}*2:Frames_post_stim_start)/FPSstack{idx})+10);
            FrameVals = floor((1:FPSstack{idx}*2:Frames)-1); 
        elseif tType == 4 
            plot([round(baselineEndFrame+((FPSstack{idx})*20)) round(baselineEndFrame+((FPSstack{idx})*20))], [-5000 5000], 'r','LineWidth',2)
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{idx}*2:Frames_post_stim_start)/FPSstack{idx})+10);
            FrameVals = floor((1:FPSstack{idx}*2:Frames)-1); 
        end
        ax=gca;
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;
        ax.FontSize = 30;
        ax.FontName = 'Arial';
        xlim([1 length(AVbData{tType})])
        ylim([-5 5])
        xlabel('time (s)')
        ylabel('percent change')
        % initialize empty string array 
        label = strings;
        label = append(label,'  Calcium Signal');
        title({'Optogenetic Stimulation';'Event Triggered Averages (n = 3)';label},'FontName','Arial');
        set(fig,'position', [100 100 900 900])
        alpha(0.5)        
    end 
    %plot BBB data 
    if BBBQ == 1 
        fig = figure;             
        hold all;
        Frames = size(AVbData{tType},2);        
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        plot(AVbData{tType}-100,'r','LineWidth',3)
        patch([x fliplr(x)],[CI_bLow{tType}-100 fliplr(CI_bHigh{tType}-100)],[0.5 0 0],'EdgeColor','none')
        if tType == 1 
%             plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000 5000], 'b','LineWidth',2)
%             plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{idx}:Frames_post_stim_start)/FPSstack{idx})+1);
            FrameVals = floor((1:FPSstack{idx}:Frames)-1); 
            label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
            label1.FontSize = 30;
            label1.FontName = 'Arial';
            label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack{idx}))*2),'-k',{'water reward'},'LineWidth',2);
            label2.FontSize = 30;
        elseif tType == 3 
            plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000 5000], 'r','LineWidth',2)
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2)    
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{idx}*2:Frames_post_stim_start)/FPSstack{idx})+1);
            FrameVals = floor((1:FPSstack{idx}*2:Frames)-1); 
        elseif tType == 2 
            plot([round(baselineEndFrame+((FPSstack{idx})*20)) round(baselineEndFrame+((FPSstack{idx})*20))], [-5000 5000], 'b','LineWidth',2)
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2)  
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{idx}*2:Frames_post_stim_start)/FPSstack{idx})+10);
            FrameVals = floor((1:FPSstack{idx}*2:Frames)-1); 
        elseif tType == 4 
            plot([round(baselineEndFrame+((FPSstack{idx})*20)) round(baselineEndFrame+((FPSstack{idx})*20))], [-5000 5000], 'r','LineWidth',2)
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{idx}*2:Frames_post_stim_start)/FPSstack{idx})+10);
            FrameVals = floor((1:FPSstack{idx}*2:Frames)-1); 
        end
        ax=gca;
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;
        ax.FontSize = 30;
        ax.FontName = 'Arial';
        xlim([1 length(AVbData{tType})])
        ylim([-2.5 2.5])
        xlabel('time (s)')
        ylabel('percent change')
        % initialize empty string array 
        label = strings;
        label = append(label,'BBB Permeabilty'); 
        title({'Optogenetic Stimulation';'Event Triggered Averages (n = 3)';label},'FontName','Arial');
        set(fig,'position', [100 100 900 900])
        alpha(0.5)      
    end 
    %plot VW data 
    if VWQ == 1
        fig = figure;             
        hold all;
        Frames = size(AVbData{tType},2);        
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2;   
        plot(AVvData{tType}-100,'k','LineWidth',3)
        patch([x fliplr(x)],[CI_vLow{tType}-100 fliplr(CI_vHigh{tType}-100)],'k','EdgeColor','none')            
        if tType == 1 
%             plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000 5000], 'b','LineWidth',2)
%             plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{idx}:Frames_post_stim_start)/FPSstack{idx})+1);
            FrameVals = floor((1:FPSstack{idx}:Frames)-1); 
            label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
            label1.FontSize = 30;
            label1.FontName = 'Arial';
            label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack{idx}))*2),'-k',{'water reward'},'LineWidth',2);
            label2.FontSize = 30;            
        elseif tType == 3 
            plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000 5000], 'r','LineWidth',2)
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2)    
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{idx}*5:Frames_post_stim_start)/FPSstack{idx})+1);
            FrameVals = floor((1:FPSstack{idx}*5:Frames)-1); 
        elseif tType == 2 
            plot([round(baselineEndFrame+((FPSstack{idx})*20)) round(baselineEndFrame+((FPSstack{idx})*20))], [-5000 5000], 'b','LineWidth',2)
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{idx}*5:Frames_post_stim_start)/FPSstack{idx})+10);
            FrameVals = floor((1:FPSstack{idx}*5:Frames)-1); 
        elseif tType == 4 
            plot([round(baselineEndFrame+((FPSstack{idx})*20)) round(baselineEndFrame+((FPSstack{idx})*20))], [-5000 5000], 'r','LineWidth',2)
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{idx}*5:Frames_post_stim_start)/FPSstack{idx})+10);
            FrameVals = floor((1:FPSstack{idx}*5:Frames)-1); 
        end
        ax=gca;
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;
        ax.FontSize = 30;
        ax.FontName = 'Arial';
        xlim([1 length(AVbData{tType})])
        ylim([-0.1 0.25])
        xlabel('time (s)')
        ylabel('percent change')
        % initialize empty string array 
        label = strings;
        label = append(label,'Vessel width ROIs averaged ');
        title({'Optogenetic Stimulation';'Event Triggered Averages';label},'FontName','Arial');
        set(fig,'position', [100 100 900 900])
        alpha(0.5)     
    end 
end 

%% overlay traces 

pCAQ = input('Input 1 to plot calcium data. ');
pBBBQ = input('Input 1 to plot BBB data. ');
pVWQ = input('Input 1 to plot vessel width data. ');
for tType = 1:tTypeNum
    fig = figure;             
    hold all;
    Frames = size(AVbData{tType},2);        
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    if pCAQ == 1 
        plot(AVcData{tType}-100,'b','LineWidth',3)
    end 
    if pBBBQ == 1
        plot(AVbData{tType}-100,'r','LineWidth',3)
        patch([x fliplr(x)],[CI_bLow{tType}-100 fliplr(CI_bHigh{tType}-100)],[0.5 0 0],'EdgeColor','none')
    end 
    if pVWQ == 1 
        plot(AVvData{tType}-100,'k','LineWidth',3)
        patch([x fliplr(x)],[CI_vLow{tType}-100 fliplr(CI_vHigh{tType}-100)],'k','EdgeColor','none')     
    end 
    
    if tType == 1 
%         plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000 5000], 'b','LineWidth',2)
%         plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{idx}*1:Frames_post_stim_start)/FPSstack{idx})+1);
        FrameVals = floor((1:FPSstack{idx}*1:Frames)-1); 
        label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
        label1.FontSize = 30;
        label1.FontName = 'Arial';
        label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack{idx}))*2),'-k',{'water reward'},'LineWidth',2);
        label2.FontSize = 30;    
    elseif tType == 3 
        plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000 5000], 'r','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2)   
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{idx}*1:Frames_post_stim_start)/FPSstack{idx})+1);
        FrameVals = floor((1:FPSstack{idx}*1:Frames)-1); 
    elseif tType == 2 
        plot([round(baselineEndFrame+((FPSstack{idx})*20)) round(baselineEndFrame+((FPSstack{idx})*20))], [-5000 5000], 'b','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2)   
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{idx}*1:Frames_post_stim_start)/FPSstack{idx})+10);
        FrameVals = floor((1:FPSstack{idx}*1:Frames)-1); 
    elseif tType == 4 
        plot([round(baselineEndFrame+((FPSstack{idx})*20)) round(baselineEndFrame+((FPSstack{idx})*20))], [-5000 5000], 'r','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{idx}*1:Frames_post_stim_start)/FPSstack{idx})+10);
        FrameVals = floor((1:FPSstack{idx}*1:Frames)-1); 
    end
    ax=gca;
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;
    ax.FontSize = 30;
    ax.FontName = 'Times';
    xlim([1 length(AVbData{tType})])
    ylim([-5 5])
    xlabel('time (s)')
    ylabel('percent change')
    % initialize empty string array 
    label = strings;
    label = append(label,'  Ca ROIs averaged');
    title({'Optogenetic Stimulation';'Event Triggered Averages';label},'FontName','Times');
    set(fig,'position', [100 100 900 900])
    alpha(0.5)   
end 

%% combine red light trials and overlay traces 

%sort all red trials together %AVcData{tType}
pCAQ = input('Input 1 to plot calcium data. ');
pBBBQ = input('Input 1 to plot BBB data. ');
pVWQ = input('Input 1 to plot vessel width data. ');
redTrialTtypeInds = [3,4]; %THIS IS CURRENTLY HARD CODED IN, BUT DOESN'T HAVE TO BE. REPLACE EVENTUALLY.
if pCAQ == 1 
    allRedAVcData = zeros(1,size(AVcData{1},2));
    allRedAVcDataArray = zeros(1,size(AVcData{1},2));
end 
if pBBBQ == 1 
    allRedAVbData = zeros(1,size(AVcData{1},2));
    allRedAVbDataArray = zeros(1,size(AVcData{1},2));
end 
if VWQ == 1 
    allRedAVvData = zeros(1,size(AVcData{1},2));
    allRedAVvDataArray = zeros(1,size(AVcData{1},2));
end 
count = 1;
for tType = 1:length(redTrialTtypeInds)
    if pCAQ == 1 
        allRedAVcDataArray(tType,:) = AVcData{redTrialTtypeInds(tType)}(1:size(AVcData{1},2)); 
    end 
    if pBBBQ == 1 
        allRedAVbDataArray(tType,:) = AVbData{redTrialTtypeInds(tType)}(1:size(AVcData{1},2)); 
%         for trial = 1:size(snBetaArray{redTrialTtypeInds(tType)},1)
%             allRedAvbDataArray2(count,:) = snBetaArray{redTrialTtypeInds(tType)}(trial,1:429);
%             count = count + 1; 
%         end 
    end 
    if pVWQ == 1 
        allRedAVvDataArray(tType,:) = AVvData{redTrialTtypeInds(tType)}(1:size(AVcData{1},2)); 
    end 
end 
if pCAQ == 1 
    allRedAVcData = nanmean(allRedAVcDataArray,1); 
end 
if pBBBQ == 1 
    allRedAVbData = nanmean(allRedAVbDataArray,1); 
end 
if pVWQ == 1 
    allRedAVvData = nanmean(allRedAVvDataArray,1); 
end 

% determine 95% CI 
% SEMb = (nanstd(allRedAvbDataArray2))/(sqrt(size(allRedAvbDataArray2,1))); % Standard Error            
% STDb = nanstd(allRedAvbDataArray2);
% ts_bLow = tinv(0.025,size(allRedAvbDataArray2,1)-1);% T-Score for 95% CI
% ts_bHigh = tinv(0.975,size(allRedAvbDataArray2,1)-1);% T-Score for 95% CI
% CI_bLow = (nanmean(allRedAvbDataArray2,1)) + (ts_bLow*SEMb);  % Confidence Intervals
% CI_bHigh = (nanmean(allRedAvbDataArray2,1)) + (ts_bHigh*SEMb);  % Confidence Intervals
% x = 1:length(CI_bLow);
% test = nanmean(allRedAvbDataArray2,1);

fig = figure;             
hold all;
Frames = size(AVbData{1},2);        
Frames_pre_stim_start = -((Frames-1)/2); 
Frames_post_stim_start = (Frames-1)/2; 
if pCAQ == 1 
    plot(allRedAVcData-100,'b','LineWidth',3)  
end 
if pBBBQ == 1
    plot(allRedAVbData-100,'r','LineWidth',3)
%     patch([x fliplr(x)],[CI_bLow-100 fliplr(CI_bHigh-100)],'r','EdgeColor','none')   
%     alpha(0.3)
end 
if pVWQ == 1 
    plot(allRedAVvData-100,'k','LineWidth',3)
end 
% plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000 5000], 'r','LineWidth',2)
plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'k:','LineWidth',2)   
sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{idx}*5:Frames_post_stim_start)/FPSstack{idx})+1);
FrameVals = floor((1:FPSstack{idx}*5:Frames)-1); 
ax=gca;
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;
ax.FontSize = 30;
ax.FontName = 'Times';
xlim([1 length(AVbData{1})])
ylim([-5 5])
xlabel('time (s)')
ylabel('BBB permeability percent change')
% initialize empty string array 
label = strings;
label = append(label,'  Ca ROIs averaged');
% title({'Optogenetic Stimulation';'Event Triggered Averages';label},'FontName','Times');
% title({'Optogenetic Stimulation';'of DAT+ VTA Axons'},'FontName','Times');
% legend('BBB Permeability')
set(fig,'position', [100 100 900 900]) 
%}
%% compare terminal calcium activity - create correlograms
%{
AVdata = cell(1,length(nsCeta));
for term = 1:length(terminals)
    for tType = 1:length(nsCeta{terminals(1)})      
        AVdata{term}{tType} = mean(nsCeta{terminals(term)}{tType},1);
    end 
end 

dataQ = input('Input 0 if you want to compare the entire TS. Input 1 if you want to compare stim period data. Input 2 if you want to compare baseline period data.');
if dataQ == 0 
    corData = cell(1,length(nsCeta{terminals(1)}));
    corAVdata = cell(1,length(nsCeta{terminals(1)}));
    for tType = 1:length(nsCeta{terminals(1)})  
       for term1 = 1:length(terminals)
           for term2 = 1:length(terminals)
               for trial = 1:size(nsCeta{terminals(term1)}{tType},1)
                   corData{tType}{trial}(term1,term2) = corr2(nsCeta{terminals(term1)}{tType}(trial,:),nsCeta{terminals(term2)}{tType}(trial,:));                  
               end 
               corAVdata{tType}(term1,term2) = corr2(AVdata{term1}{tType},AVdata{term2}{tType});
           end 
       end 
    end 
elseif dataQ == 1 
    corData = cell(1,length(nsCeta{terminals(1)}));
    corAVdata = cell(1,length(nsCeta{terminals(1)}));
    for tType = 1:length(nsCeta{terminals(1)}) 
       for term1 = 1:length(terminals)
           for term2 = 1:length(terminals)
               stimOnFrame = floor(FPSstack*20);
               if tType == 1 || tType == 3 
                   stimOffFrame = stimOnFrame + floor(FPSstack*20);
               elseif tType == 2 || tType == 4
                   stimOffFrame = stimOnFrame + floor(FPSstack*2);
               end                
               for trial = 1:size(nsCeta{terminals(term1)}{tType},1)                  
                   corData{tType}{trial}(term1,term2) = corr2(nsCeta{terminals(term1)}{tType}(trial,stimOnFrame:stimOffFrame),nsCeta{terminals(term2)}{tType}(trial,stimOnFrame:stimOffFrame));
               end 
               corAVdata{tType}(term1,term2) = corr2(AVdata{term1}{tType}(stimOnFrame:stimOffFrame),AVdata{term2}{tType}(stimOnFrame:stimOffFrame));
           end 
       end 
    end 
elseif dataQ == 2
    corData = cell(1,length(nsCeta{terminals(1)}));
    corAVdata =cell(1,length(nsCeta{terminals(1)}));
    for tType = 1:length(nsCeta{terminals(1)}) 
       for term1 = 1:length(terminals)
           for term2 = 1:length(terminals)
               baselineEndFrame = floor(FPSstack*20);
               for trial = 1:size(nsCeta{terminals(term1)}{tType},1)  
                   corData{tType}{trial}(term1,term2) = corr2(nsCeta{terminals(term1)}{tType}(trial,1:baselineEndFrame),nsCeta{terminals(term2)}{tType}(trial,1:baselineEndFrame));
               end 
               corAVdata{tType}(term1,term2) = corr2(AVdata{term1}{tType}(1:baselineEndFrame),AVdata{term2}{tType}(1:baselineEndFrame));
           end 
       end 
    end 
end 

% plot cross correlelograms 
for tType = 1:length(nsCeta{terminals(1)}) 
    % plot averaged trial data
    figure;
    imagesc(corAVdata{tType})
    colorbar 
    truesize([700 900])
    ax=gca;
    ax.FontSize = 20;
    ax.XTickLabel = terminals;
    ax.YTickLabel = terminals;
    if smoothQ == 0 
       if tType == 1 
           title('2 sec blue stim. Raw data.','FontSize',20);
       elseif tType == 2
           title('20 sec blue stim. Raw data.','FontSize',20);
       elseif tType == 3
           title('2 sec red stim. Raw data.','FontSize',20);
       elseif tType == 4 
           title('20 sec red stim. Raw data.','FontSize',20);
       end 
    elseif smoothQ == 1
       if tType == 1 
           mtitle = sprintf('2 sec blue stim. Data smoothed by %0.2f sec.',filtTime);
           title(mtitle,'FontSize',20);
       elseif tType == 2
           mtitle = sprintf('20 sec blue stim. Data smoothed by %0.2f sec.',filtTime);
           title(mtitle,'FontSize',20);
       elseif tType == 3
           mtitle = sprintf('2 sec red stim. Data smoothed by %0.2f sec.',filtTime);
           title(mtitle,'FontSize',20);
       elseif tType == 4 
           mtitle = sprintf('20 sec red stim. Data smoothed by %0.2f sec.',filtTime);
           title(mtitle,'FontSize',20);
       end 
    end 
   xlabel('terminal')
   ylabel('terminal')
    
   %plot trial data 
   figure;
    if smoothQ == 0 
       if tType == 1 
           sgtitle('2 sec blue stim. Raw data.','FontSize',20);
       elseif tType == 2
           sgtitle('20 sec blue stim. Raw data.','FontSize',20);
       elseif tType == 3
           sgtitle('2 sec red stim. Raw data.','FontSize',20);
       elseif tType == 4 
           sgtitle('20 sec red stim. Raw data.','FontSize',20);
       end 
    elseif smoothQ == 1
       if tType == 1 
           mtitle = sprintf('2 sec blue stim. Data smoothed by %0.2f sec.',filtTime);
           sgtitle(mtitle,'FontSize',20);
       elseif tType == 2
           mtitle = sprintf('20 sec blue stim. Data smoothed by %0.2f sec.',filtTime);
           sgtitle(mtitle,'FontSize',20);
       elseif tType == 3
           mtitle = sprintf('2 sec red stim. Data smoothed by %0.2f sec.',filtTime);
           sgtitle(mtitle,'FontSize',20);
       elseif tType == 4 
           mtitle = sprintf('20 sec red stim. Data smoothed by %0.2f sec.',filtTime);
           sgtitle(mtitle,'FontSize',20);
       end 
    end 
   for trial = 1:size(nsCeta{terminals(term1)}{tType},1)  
       subplot(2,8,trial)
       imagesc(corData{tType}{trial})
       colorbar 
       ax=gca;
       ax.FontSize = 12;
       title(sprintf('Trial #%d.',trial));
%        truesize([200 400])
       xlabel('terminal')
       ylabel('terminal')
       ax.XTick = (1:length(terminals));
       ax.YTick = (1:length(terminals));
       ax.XTickLabel = terminals;
       ax.YTickLabel = terminals;
   end 
end 
%}
%% calcium peak raster plots and PSTHs 
% uses ETA .mat file that contains all trials 
% separates trials based on trial num and ITI length 
%{
% shere is the ETA data?  
etaDir = uigetdir('*.*','WHERE IS THE ETA DATA');
cd(etaDir);
% list the .mat files in the folder 
fileList = dir(fullfile(etaDir,'*.mat'));

% set plotting paramaters 
indCaROIplotQ = input('Input 1 if you want to plot raster plots and PSTHs for each Ca ROI independently. ');
allCaROIplotQ = input('Input 1 if you want to plot PSTH for all Ca ROIs stacked. ');
winSec = input('How many seconds do you want to bin the calcium peak rate PSTHs? '); 
FPSstack2 = zeros(1,size(fileList,1));
fullRaster2 = cell(1,size(fileList,1));
totalPeakNums2 = cell(1,size(fileList,1));    
for mouse = 1:size(fileList,1)
    MatFileName = fileList(mouse).name;
    load(MatFileName,'-regexp','^(?!indCaROIplotQ|allCaROIplotQ|winSec|trialQ|ITIq|trialLenThreshTime|histQ|ITIq2|termQ$)\w')
    winFrames = (winSec*FPSstack);
    % find peaks that are significant relative to the entire data set
    stdTrace = cell(1,length(vidList)); 
    sigPeaks2 = cell(1,length(vidList)); 
    sigLocs2 = cell(1,length(vidList)); 
    for vid = 1:length(vidList)
        for ccell = 1:length(terminals)
            %find the peaks 
            [peaks, locs] = findpeaks(cDataFullTrace{vid}{terminals(ccell)},'MinPeakProminence',0.1,'MinPeakWidth',2); %0.6,0.8,0.9,1\
            %find the sig peaks (peaks above 2 standard deviations from mean) 
            stdTrace{vid}{terminals(ccell)} = std(cDataFullTrace{vid}{terminals(ccell)});  
            count = 1 ; 
            for loc = 1:length(locs)
                if peaks(loc) > stdTrace{vid}{terminals(ccell)}*2
                        sigPeaks2{vid}{terminals(ccell)}(count) = peaks(loc);
                        sigLocs2{vid}{terminals(ccell)}(count) = locs(loc);
                        count = count + 1;  
                end 
            end 
        end 
    end 

    tTypePlotStart = cell(1,length(bDataFullTrace) ); 
    tTypePlotEnd = cell(1,length(bDataFullTrace) );
    for vid = 1:length(bDataFullTrace) 
        count5 = 1; 
        count6 = 1; 
        count7 = 1; 
        count8 = 1; 
        for trial = 1:length(plotStart{vid}) 
            %if the blue light is on
            if TrialTypes{vid}(trial,2) == 1
                %if it is a 2 sec trial 
                if trialLengths{vid}(trial) == floor(2*FPSstack)
                    tTypePlotStart{vid}{1}(count5) = plotStart{vid}(trial);
                    tTypePlotEnd{vid}{1}(count5) = plotEnd{vid}(trial);
                    count5 = count5 + 1;
                %if it is a 20 sec trial
                elseif trialLengths{vid}(trial) == floor(20*FPSstack)
                    tTypePlotStart{vid}{2}(count6) = plotStart{vid}(trial);
                    tTypePlotEnd{vid}{2}(count6) = plotEnd{vid}(trial);
                    count6 = count6 + 1;
                end 
            %if the red light is on 
            elseif TrialTypes{vid}(trial,2) == 2
                %if it is a 2 sec trial 
                if trialLengths{vid}(trial) == floor(2*FPSstack)
                    tTypePlotStart{vid}{3}(count7) = plotStart{vid}(trial);
                    tTypePlotEnd{vid}{3}(count7) = plotEnd{vid}(trial);
                    count7 = count7 + 1;
                %if it is a 20 sec trial
                elseif trialLengths{vid}(trial) == floor(20*FPSstack)
                    tTypePlotStart{vid}{4}(count8) = plotStart{vid}(trial);
                    tTypePlotEnd{vid}{4}(count8) = plotEnd{vid}(trial);
                    count8 = count8 + 1;
                end             
            end 
        end         
    end

    % remove trial start and end frames if they're both 0 
    for vid = 1:length(bDataFullTrace) 
        for tType = 1:numTtypes
            if size(tTypePlotStart{vid},2) >= tType && isempty(tTypePlotStart{vid}{tType}) == 0 
                for trial = 1:size(tTypePlotStart{vid}{tType},2)
                    if tTypePlotStart{vid}{tType}(trial) == 0 && tTypePlotEnd{vid}{tType}(trial) == 0 
                        tTypePlotStart{vid}{tType}(trial) = NaN;
                        tTypePlotEnd{vid}{tType}(trial) = NaN; 
                    end 
                end 
            end 
        end 
    end 

    % sort sigLocs 
    sigPeaks = cell(1,length(bDataFullTrace));
    sigLocs = cell(1,length(bDataFullTrace));
    for vid = 1:length(bDataFullTrace) 
        for ccell = 1:ccellLen
            for tType = 1:numTtypes        
                if size(tTypePlotStart{vid},2) >= tType && isempty(tTypePlotStart{vid}{tType}) == 0
                    for trial = 1:size(tTypePlotStart{vid}{tType},2) 
                        count = 1;
                        for peak = 1:length(sigPeaks2{vid}{terminals(ccell)})
                            if sigLocs2{vid}{terminals(ccell)}(peak) > tTypePlotStart{vid}{tType}(trial) && sigLocs2{vid}{terminals(ccell)}(peak) < tTypePlotEnd{vid}{tType}(trial)
                                sigPeaks{vid}{ccell}{tType}{trial}(count) = sigPeaks2{vid}{terminals(ccell)}(peak); 
                                sigLocs{vid}{ccell}{tType}{trial}(count) = sigLocs2{vid}{terminals(ccell)}(peak); 
                                count = count + 1;
                            end 
                        end
                    end  
                end 
            end 
        end
    end 

    % correct peak location based on plot start and end frames 
    correctedSigLocs = cell(1,length(bDataFullTrace) );
    for vid = 1:length(bDataFullTrace) 
        for ccell = 1:ccellLen
            for tType = 1:numTtypes      
                for trial = 1:length(sigLocs{vid}{ccell}{tType})
                   correctedSigLocs{vid}{ccell}{tType}{trial} = sigLocs{vid}{ccell}{tType}{trial} - tTypePlotStart{vid}{tType}(trial);
                end 
            end 
        end 
    end

    % select trial range that you want to include in PSTH 
    trialList = cell(1,length(sigPeaks));
    if mouse == 1 
        trialQ = input('Input 1 to select what trials to average and plot. Input 0 for all trials. ');
    end 
    if trialQ == 0
        for vid = 1:length(bDataFullTrace) 
            trialList{vid} = 1:length(tTypePlotStart{vid}{numTtypes});       
        end 
    elseif trialQ == 1 
        for vid = 1:length(bDataFullTrace) 
            trialList{vid} = input(sprintf('What trials do you want to average and plot for vid %d Mouse %d? ',vid,mouse));
        end 
    end 

    % figure out ITI length and sort ITI length into trial type 
    if mouse == 1
        ITIq = input('Input 1 to separate data based on ITI length. Input 0 otherwise. ');
    end 
    if ITIq == 0 
        histq = 0; 
    elseif ITIq == 1 
        if mouse == 1
            histQ = input('Input 1 if you want to plot the ITI histogram for each mouse. Input 0 to not see the histograms. ');
        end 
        trialLenFrames = cell(1,length(bDataFullTrace));
        trialLenTimes = cell(1,length(bDataFullTrace));
        minMaxTrialLenTimes = cell(1,length(bDataFullTrace));
        for vid = 1:length(bDataFullTrace)  
            if trialList{vid}(1) > 1 
                trialLenFrames{vid}(1) = state_start_f{vid}(trialList{vid}(1))-state_start_f{vid}(trialList{vid}(1)-1);    
            elseif trialList{vid}(1) == 1 
                trialLenFrames{vid}(1) = state_start_f{vid}(trialList{vid}(1))-1;    
            end 
            trialLenFrames{vid}(2:length(trialList{vid})) = state_start_f{vid}(trialList{vid}(2:end))-state_end_f{vid}(trialList{vid}(1:end-1));
            trialLenTimes{vid} = trialLenFrames{vid}/FPSstack;
            minMaxTrialLenTimes{vid}(1) = min(trialLenTimes{vid});
            minMaxTrialLenTimes{vid}(2) = max(trialLenTimes{vid});
            if histQ == 1 
                figure; histogram(trialLenTimes{vid})
                display(minMaxTrialLenTimes{vid})
            end 
        end 
        if mouse == 1
            trialLenThreshTime = input('Input the ITI thresh (sec) to separate data by. '); 
        end 
        trialListHigh = cell(1,length(bDataFullTrace));
        trialListLow = cell(1,length(bDataFullTrace));
        for vid = 1:length(bDataFullTrace) 
            trialListHigh{vid} = trialList{vid}((trialLenTimes{vid} >= trialLenThreshTime));
            trialListLow{vid} = trialList{vid}((trialLenTimes{vid} < trialLenThreshTime));
        end 
        if mouse == 1 
            ITIq2 = input(sprintf('Input 1 to plot trials with ITIs greater than %d sec. Input 0 for ITIs lower than %d sec. ',trialLenThreshTime,trialLenThreshTime));
        end 
        if ITIq2 == 0
            trialList = trialListLow;
        elseif ITIq2 == 1
            trialList = trialListHigh;
        end 
    end 
    if mouse == 1 
        termQ = input('Input 1 to select what axons are plotted. Input 0 otherwise. ');
    end 
    if termQ == 0
        termList = terminals;
    elseif termQ == 1
        termList = input(sprintf('Input the axons you want to plot for Mouse %d. ',mouse));
    end 

    % the below length sizes are semi hard coded in temporarily 
    Len1_3 = length(sCeta{terminals(1)}{1});
    if length(sCeta{terminals(1)}) > 1 
        Len2_4 = length(sCeta{terminals(1)}{2});
    end 

    % create raster and PSTH for all terminals individually 
    numPeaks = cell(1,length(terminals));
    avTermNumPeaks = cell(1,length(terminals));
    allTermAvPeakNums = cell(1,numTtypes);
    raster2 = cell(1,length(sigPeaks));
    raster3 = cell(1,length(sigPeaks));
    raster = cell(1,length(sigPeaks));
    colNums = cell(1,length(sigPeaks{1}{1}));
    maxColNum = zeros(1,length(sigPeaks{1}{1}));
    meanNumPeaks = cell(1,length(sigPeaks));
    for vid = 1:length(bDataFullTrace)  
        for term = 1:length(termList)   
            for tType = 1:length(sigPeaks{vid}{term})
                count = 1 ;
                for trial = 1:length(trialList{vid})
                    if length(sigPeaks{vid}{(terminals == termList(term))}{tType}) >= trialList{vid}(trial)
                        % create raster plot by binarizing data   
                        if isempty(sigLocs{vid}{(terminals == termList(term))}{tType}{trialList{vid}(trial)}) == 0
                            for peak = 1:length(sigPeaks{vid}{(terminals == termList(term))}{tType}{trialList{vid}(trial)})
                                raster2{(terminals == termList(term))}{tType}(trialList{vid}(count),correctedSigLocs{vid}{(terminals == termList(term))}{tType}{trialList{vid}(trial)}(peak)) = 1;       
                            end 
                        end 
                    end 
                    count = count + 1;
                end 
            end 
        end 
    end 
    for vid = 1:length(bDataFullTrace)  
        for term = 1:length(termList)   
            for tType = 1:length(sigPeaks{vid}{term})
               if isempty(raster2{(terminals == termList(term))}) == 0 
                    raster2{(terminals == termList(term))}{tType} = ~raster2{(terminals == termList(term))}{tType};
                    %make raster plot larger/easier to look at 
                    RowMultFactor = 30;
                    ColMultFactor = 30;
                    raster3{(terminals == termList(term))}{tType} = repelem(raster2{(terminals == termList(term))}{tType},RowMultFactor,ColMultFactor);
                    raster{(terminals == termList(term))}{tType} = raster2{(terminals == termList(term))}{tType};
                    %make rasters the correct length  
                    if tType == 1 || tType == 3
                        raster{(terminals == termList(term))}{tType}(:,length(raster3{(terminals == termList(term))}{tType})+1:Len1_3) = 1;
                    elseif tType == 2 || tType == 4   
                        raster{(terminals == termList(term))}{tType}(:,length(raster3{(terminals == termList(term))}{tType})+1:Len2_4) = 1;
                    end   
                    %this makes the raster larger/easier to see 
                    raster{(terminals == termList(term))}{tType} = repelem(raster{(terminals == termList(term))}{tType},RowMultFactor,ColMultFactor);
                    %create PSTHs 
                    windows = ceil(length(raster2{(terminals == termList(term))}{tType})/winFrames);
                    for win = 1:windows
                        if win == 1 
                            numPeaks{(terminals == termList(term))}{tType}(:,win) = sum(~raster2{(terminals == termList(term))}{tType}(:,1:winFrames),2);
                        elseif win > 1 
                            if ((win-1)*winFrames)+1 < size(raster2{(terminals == termList(term))}{tType},2) && winFrames*win < size(raster2{(terminals == termList(term))}{tType},2)
                                numPeaks{(terminals == termList(term))}{tType}(:,win) = sum(~raster2{(terminals == termList(term))}{tType}(:,((win-1)*winFrames)+1:winFrames*win),2);
                            end 
                        end             
                    end 
               end
            end 
        end 
    end 

    for tType = 1:length(sigPeaks{vid}{term})
        for term = 1:length(termList)           
            if isempty(raster2{(terminals == termList(term))}) == 0 
                %figure out the max number of columns 
                colNums{tType}((terminals == termList(term))) = size(numPeaks{(terminals == termList(term))}{tType},2);
            end 
        end 
    end 
    for tType = 1:length(sigPeaks{vid}{term})
        maxColNum(tType) = max(max(colNums{tType}));
        for term = 1:length(termList)           
            if isempty(raster2{(terminals == termList(term))}) == 0  
                avTermNumPeaks{(terminals == termList(term))}{tType} = nanmean(numPeaks{(terminals == termList(term))}{tType},1);
                %make avTermNumPeaks the same size
                if length(avTermNumPeaks{(terminals == termList(term))}{tType}) < maxColNum(tType)
                    avTermNumPeaks{(terminals == termList(term))}{tType}(:,size(avTermNumPeaks{(terminals == termList(term))}{tType},2):maxColNum(tType)) = 0;
                end    
            end 
        end 
    end 
    for tType = 1:length(sigPeaks{vid}{term})
        for term = 1:length(termList)   
            if isempty(raster2{(terminals == termList(term))}) == 0 
              % determine the mean peak rate 
                meanNumPeaks{(terminals == termList(term))}(tType) = nanmean(avTermNumPeaks{(terminals == termList(term))}{tType}); 
                % divide by the mean peak rate to show the variation in spike
                % rates from the mean 
                avTermNumPeaks{(terminals == termList(term))}{tType} = avTermNumPeaks{(terminals == termList(term))}{tType}/meanNumPeaks{(terminals == termList(term))}(tType);
                allTermAvPeakNums{tType}((terminals == termList(term)),:) = avTermNumPeaks{(terminals == termList(term))}{tType};
            end 
        end 
        % replace rows full of zero with NaNs 
        allTermAvPeakNums{tType}(any(allTermAvPeakNums{tType},2)==0,:)=NaN;
    end 

    if indCaROIplotQ == 1 
        for tType = 1:length(sigPeaks{vid}{term})
            for term = 1:length(termList)       
                if isempty(raster2{(terminals == termList(term))}) == 0 
                    figure; 
                    t = tiledlayout(1,2);
                    t.TileSpacing = 'compact';
                    t.Padding = 'compact';        
                    %plot raster  
                    nexttile
                    imshow(raster{(terminals == termList(term))}{tType})
                    hold all 
        %             stimStartF = floor(FPSstack*20);
                    if tType == 1 || tType == 3 
                        Frames = size(sCeta{BBBroi}{tType},2);        
                        Frames_pre_stim_start = -((Frames-1)/2); 
                        Frames_post_stim_start = (Frames-1)/2; 
                        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack)+1);                
                        FrameVals = floor((1:FPSstack:Frames)-1); 
                        FrameVals = FrameVals*ColMultFactor;
                    elseif tType == 2 || tType == 4 
                        Frames = size(sCeta{BBBroi}{tType},2);
                        Frames_pre_stim_start = -((Frames-1)/2); 
                        Frames_post_stim_start = (Frames-1)/2; 
                        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack)+10);
                        FrameVals = floor((1:FPSstack:Frames)-1); 
                        FrameVals = FrameVals*ColMultFactor;
                    end 
                    if tType == 1 || tType == 2
        %             plot([stimStartF stimStartF], [0 size(raster{term}{tType},1)], 'b','LineWidth',2)
        %             plot([stimStopF stimStopF], [0 size(raster{term}{tType},1)], 'b','LineWidth',2)
                    elseif tType == 3 || tType == 4
        %             plot([stimStartF stimStartF], [0 size(raster{term}{tType},1)], 'r','LineWidth',2)
        %             plot([stimStopF stimStopF], [0 size(raster{term}{tType},1)], 'r','LineWidth',2)
                    end 
        %             label1 = xline(ceil(abs(Frames_pre_stim_start)-10)*ColMultFactor,'-k',{'vibrissal stim'},'LineWidth',2);
        %             label1.FontSize = 30;
        %             label1.FontName = 'Arial';
        %             label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack))*2)*ColMultFactor,'-k',{'water reward'},'LineWidth',2);
        %             label2.FontSize = 30;
        %             label2.FontName = 'Arial';
                    xline(ceil(abs(Frames_pre_stim_start)-10)*ColMultFactor,'-k','LineWidth',2);
                    xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack))*2)*ColMultFactor,'-k','LineWidth',2);
                    ax=gca;
                    axis on 
                    xticks(FrameVals)
                    ax.XTickLabel = sec_TimeVals;
                    yticks((RowMultFactor:RowMultFactor:((size(raster{(terminals == termList(term))}{tType},1)-5)/RowMultFactor))*RowMultFactor)
                    if tType == 1 
                        ylabel('trials')
                    end 
                    ax.YTickLabel = ([RowMultFactor:RowMultFactor:((size(raster{(terminals == termList(term))}{tType},1)-5)/RowMultFactor)]);
                    ax.FontSize = 15;

                    %plot PSTHs
                    nexttile
                    hold all 
            %             stimStartF = floor((FPSstack*20)/winFrames);
                    if tType == 1 || tType == 3 
                        Frames = size(sCeta{BBBroi}{tType},2);        
                        Frames_pre_stim_start = -((Frames-1)/2); 
                        Frames_post_stim_start = (Frames-1)/2; 
                        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack)+1);                
                        FrameVals = floor((1:FPSstack:Frames)-1); 
            %                 FrameVals = (FrameVals/(length(allTermAvPeakNums{tType})+2))+0.5;
                        FrameVals = (FrameVals/(length(allTermAvPeakNums{tType})/3.75))+0.3;
                    elseif tType == 2 || tType == 4 
                        Frames = size(sCeta{BBBroi}{tType},2);
                        Frames_pre_stim_start = -((Frames-1)/2); 
                        Frames_post_stim_start = (Frames-1)/2; 
                        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack)+10);
                        FrameVals = floor((1:FPSstack:Frames)-1); 
                        FrameVals = FrameVals/length(allTermAvPeakNums{tType});
            %                 FrameVals = (FrameVals/(length(allTermAvPeakNums{tType})+2))+0.5;
                        FrameVals = (FrameVals/(length(allTermAvPeakNums{tType})/3.75))+0.5;
                    end 
                    bar(allTermAvPeakNums{tType}((terminals == termList(term)),:),'k')
                    if tType == 1 || tType == 2
            %                 plot([stimStartF stimStartF], [-20 20], 'b','LineWidth',2)
            %                 plot([stimStopF stimStopF], [-20 20], 'b','LineWidth',2)
                    elseif tType == 3 || tType == 4
            %                 plot([stimStartF stimStartF], [-20 20], 'r','LineWidth',2)
            %                 plot([stimStopF stimStopF], [-20 20], 'r','LineWidth',2)
                    end 
                    ind0 = find(sec_TimeVals == 0);
                    ind2 = find(sec_TimeVals == 2);
                    label1 = xline(FrameVals(ind0),'-k',{'vibrissal stim'},'LineWidth',2);
                    label1.FontSize = 30;
                    label1.FontName = 'Arial';
                    label2 = xline(FrameVals(ind2),'-k',{'water reward'},'LineWidth',2);
                    label2.FontSize = 30;
                    label2.FontName = 'Arial';
                    ax=gca;
                    axis on 
                    xticks(FrameVals)
                    ax.XTickLabel = sec_TimeVals;
                    ax.FontSize = 15;
                    if tType == 1 
                        ylabel('number of Ca peaks')
                    end 
                    xlim([1 length(avTermNumPeaks{(terminals == termList(term))}{tType})])
                    ylim([0 0.3])
                    mtitle = sprintf('Terminal %d Ca Peaks. Mouse %d.',terminals((terminals == termList(term))),mouse);
                    sgtitle(mtitle,'Fontsize',25);
                    hold on 
                    xlabel(t,'time (s)','Fontsize',15)
                end 
            end 
        end 
    end 

    % figure out the max number of columns
    colNumsRaster = cell(1,length(raster2{term}));
    maxColNumRaster = zeros(1,1);
    for term = 1:length(termList)
        if isempty(raster2{(terminals == termList(term))}) == 0 
            for tType = 1:length(sigPeaks{1}{terminals == termList(term)})
                colNumsRaster{tType}((terminals == termList(term))) = size(raster2{(terminals == termList(term))}{tType},2);
                maxColNumRaster(tType) = max(colNumsRaster{tType});
            end 
        end 
    end 
    for term = 1:length(termList)
        if isempty(raster2{(terminals == termList(term))}) == 0 
            for tType = 1:length(sigPeaks{1}{terminals == termList(term)})
                %make raster2 cells the same size
                if size(raster2{(terminals == termList(term))}{tType},2) < maxColNumRaster(tType)
                    raster2{(terminals == termList(term))}{tType}(:,size(raster2{(terminals == termList(term))}{tType},2)+1:maxColNumRaster(tType)) = 1;
                end 
            end 
        end 
    end 
    % create full raster            
    fullRaster = cell(1,numTtypes);
    for term = 1:length(termList)
        if isempty(raster2{(terminals == termList(term))}) == 0 
            for tType = 1:length(sigPeaks{1}{terminals == termList(term)})
                rowLen = size(raster2{(terminals == termList(term))}{tType},1);
                if term == 1
                    fullRaster{tType} = raster2{(terminals == termList(term))}{tType};
                elseif term > 1
                    fullRaster{tType}(((term-1)*rowLen)+1:term*rowLen,:) = raster2{(terminals == termList(term))}{tType};
                end 
                % replace rows full of 0s with 1s 
                zeroRows = all(fullRaster{tType} == 0,2);
                fullRaster{tType}(zeroRows,:) = 1;
            end 
        end 
    end 

    % replace rows of zeros with NaNs 
    for tType = 1:length(sigPeaks{1}{terminals == termList(term)})
        allTermAvPeakNums{tType}(any(allTermAvPeakNums{tType},2) == 0,:) = NaN;
    end 

    % average PSTHs across cells/axons
    totalPeakNums = cell(1,numTtypes);
    for tType = 1:length(sigPeaks{1}{terminals == termList(term)})
        totalPeakNums{tType} = nanmean(allTermAvPeakNums{tType});
    end 
    % plot
    if allCaROIplotQ == 1 
        for tType = 1:length(sigPeaks{1}{terminals == termList(term)})
    %         figure 
    %{
    %         plot raster plot of all terminals stacked 
            imshow(fullRaster{tType})
            hold all 
            stimStartF = floor(FPSstack*20);
            if tType == 1 || tType == 3
                stimStopF = stimStartF + floor(FPSstack*2);           
                Frames = size(fullRaster{tType},2);        
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*8:Frames_post_stim_start)/FPSstack)+1);
                FrameVals = floor((1:FPSstack*8:Frames)-1);            
            elseif tType == 2 || tType == 4       
                stimStopF = stimStartF + floor(FPSstack*20);            
                Frames = size(fullRaster{tType},2);        
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*8:Frames_post_stim_start)/FPSstack)+10);
                FrameVals = floor((1:FPSstack*8:Frames)-1);
            end 
            if tType == 1 || tType == 2
            plot([stimStartF stimStartF], [0 size(fullRaster{tType},1)], 'b','LineWidth',2)
            plot([stimStopF stimStopF], [0 size(fullRaster{tType},1)], 'b','LineWidth',2)
            elseif tType == 3 || tType == 4
            plot([stimStartF stimStartF], [0 size(fullRaster{tType},1)], 'r','LineWidth',2)
            plot([stimStopF stimStopF], [0 size(fullRaster{tType},1)], 'r','LineWidth',2)
            end 
            ax=gca;
            axis on 
            xticks(FrameVals)
            ax.XTickLabel = sec_TimeVals;
            yticks(5:10:size(fullRaster{tType},1)-5)
            ax.YTickLabel = ([]);
            ax.FontSize = 15;
            xlabel('time (s)')
            ylabel('trial')     
            %}
            %plot PSTH for all terminals stacked 
            figure
            bar(totalPeakNums{tType},'k')
            stimStartF = floor((FPSstack*20)/winFrames);
            hold all 
            if tType == 1 || tType == 3 
                Frames = size(sCeta{BBBroi}{tType},2);        
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack)+1);                
                FrameVals = floor((1:FPSstack:Frames)-1); 
    %                 FrameVals = (FrameVals/(length(allTermAvPeakNums{tType})+2))+0.5;
                FrameVals = (FrameVals/(length(allTermAvPeakNums{tType})/3.75))+0.3;
            elseif tType == 2 || tType == 4 
                Frames = size(sCeta{BBBroi}{tType},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack)+10);
                FrameVals = floor((1:FPSstack:Frames)-1); 
                FrameVals = FrameVals/length(allTermAvPeakNums{tType});
    %                 FrameVals = (FrameVals/(length(allTermAvPeakNums{tType})+2))+0.5;
                FrameVals = (FrameVals/(length(allTermAvPeakNums{tType})/3.75))+0.5;
            end 
            if tType == 1 || tType == 2
    %             plot([stimStartF stimStartF], [0 size(fullRaster{tType},1)], 'b','LineWidth',2)
    %             plot([stimStopF stimStopF], [0 size(fullRaster{tType},1)], 'b','LineWidth',2)
            elseif tType == 3 || tType == 4
    %             plot([stimStartF stimStartF], [0 size(fullRaster{tType},1)], 'r','LineWidth',2)
    %             plot([stimStopF stimStopF], [0 size(fullRaster{tType},1)], 'r','LineWidth',2)
            end 
            ind0 = find(sec_TimeVals == 0);
            ind2 = find(sec_TimeVals == 2);
            label1 = xline(FrameVals(ind0),'-k',{'vibrissal stim'},'LineWidth',2);
            label1.FontSize = 30;
            label1.FontName = 'Arial';
            label2 = xline(FrameVals(ind2),'-k',{'water reward'},'LineWidth',2);
            label2.FontSize = 30;
            label2.FontName = 'Arial';        
            ylim([0 0.5])
            ax=gca;
            axis on 
            xticks(FrameVals)
            ax.XTickLabel = sec_TimeVals;
            ax.FontSize = 15;
            xlabel('time (s)')
            ylabel('number of Ca peaks')
            label = sprintf('Number of calcium peaks per %0.2f sec. Mouse %d.',winSec, mouse);
            sgtitle(label,'FontSize',25);
        end
    end
    FPSstack2(mouse) = FPSstack;
    fullRaster2{mouse} = fullRaster;
    totalPeakNums2{mouse} = totalPeakNums;
    clearvars -except FPSstack2 fullRaster2 totalPeakNums2 etaDir fileList indCaROIplotQ allCaROIplotQ winSec trialQ ITIq trialLenThreshTime histQ ITIq2 termQ
end 

avQ = input('Input 1 to average PSTHs across mice. ');
if avQ == 1 
    % calcium peak raster plots and PSTHs (multiple mice) 
    % create PSTHs 
    if numel(unique(FPSstack2)) == 1
        minFPS = FPSstack2(1);
    elseif numel(unique(FPSstack2)) > 1
        minFPS = min(FPSstack2);
    end 
    
    % make sure the data is all the same length 
    colNum = zeros(length(totalPeakNums2),size(fullRaster2{1},2));
    for mouse = 1:length(totalPeakNums2)
        for tType = 1:size(fullRaster2{1},2)
            colNum(mouse,tType) = size(totalPeakNums2{mouse}{tType},2);
        end 
    end 
    maxColNum = max(colNum);
    for mouse = 1:length(totalPeakNums2)
        for tType = 1:size(fullRaster2{1},2)
            if size(totalPeakNums2{mouse}{tType},2) < maxColNum
                totalPeakNums2{mouse}{tType}(:,size(totalPeakNums2{mouse}{tType},2):maxColNum) = 0;
            end 
        end 
    end 
    
    % reorganize data for averaging 
    data = cell(1,size(fullRaster2{1},2));
    for mouse = 1:length(totalPeakNums2)
        for tType = 1:size(fullRaster2{1},2)
            data{tType}(mouse,:) = totalPeakNums2{mouse}{tType};
        end 
    end 
    % average data and plot 
    winFrames = (winSec*minFPS);
    secBeforeAndAfterStim = input('How many seconds are there before/after the stimulus? ');
    stimTime = input('How many seconds is the stim on for? ');

    avData = cell(1,size(fullRaster2{1},2));
    for tType = 1:size(fullRaster2{1},2)
        avData{tType} = nanmean(data{tType});
        %plot PSTH for all mice stacked 
        figure
        bar(avData{tType},'k')
        stimStartF = floor((minFPS*secBeforeAndAfterStim)/winFrames);
        hold all 
        if tType == 1 || tType == 3
            stimStopF = (stimStartF + (minFPS*2)/winFrames);           
            Frames = size(data{tType},2);        
    %         sec_TimeVals = (0:winSec*2:winSec*Frames);
            sec_TimeVals = (-secBeforeAndAfterStim:secBeforeAndAfterStim+stimTime);
            FrameVals = (0:2:Frames);            
        elseif tType == 2 || tType == 4       
    %             stimStopF = (stimStartF + (minFPS*20)/winFrames);            
    %             Frames = size(data{tType},2);        
    %             sec_TimeVals = (1:winSec*2:winSec*(Frames+1))-21;
    %             FrameVals = (0:4:Frames);
        end 
        if tType == 1 || tType == 2
    %         plot([stimStartF stimStartF], [0 size(fullRaster{tType},1)], 'b','LineWidth',2)
    %         plot([stimStopF stimStopF], [0 size(fullRaster{tType},1)], 'b','LineWidth',2)
        elseif tType == 3 || tType == 4
    %         plot([stimStartF stimStartF], [0 size(fullRaster{tType},1)], 'r','LineWidth',2)
    %         plot([stimStopF stimStopF], [0 size(fullRaster{tType},1)], 'r','LineWidth',2)
        end 
        label1 = xline(stimStartF,'-k',{'vibrissal stim'},'LineWidth',2);
        label1.FontSize = 30;
        label1.FontName = 'Arial';
        label2 = xline(stimStopF,'-k',{'water reward'},'LineWidth',2);
        label2.FontSize = 30;
        label2.FontName = 'Arial';   
        ylim([0 1])
        ax=gca;
        axis on 
        xticks(FrameVals)
        ax.XTickLabel = sec_TimeVals;
        ax.FontSize = 15;
        xlabel('time (s)')
        ylabel('number of Ca peaks')
        label = sprintf('Number of calcium peaks per %0.2f sec',winSec);
        sgtitle(label,'FontSize',25);
    end 
end 

clearvars

%% overlay the red PSTHs 
%THIS NEEDS TO BE UPDATED TO USE TOTALPEAKNUMS INSTEAD OF THE FULL RASTER
%{
% put red trials together 
%sort all red trials together %AVcData{tType}
redTrialTtypeInds = [3,4]; %THIS IS CURRENTLY HARD CODED IN, BUT DOESN'T HAVE TO BE. REPLACE EVENTUALLY.
numTrials = (size(fullRaster{3},1)+size(fullRaster{4},1));
redRaster = zeros(numTrials,size(fullRaster{3},2));
count = 1;
for tType = 1:length(redTrialTtypeInds)
    for trial = 1:size(fullRaster{redTrialTtypeInds(tType)},1)
        redRaster(count,:) = fullRaster{redTrialTtypeInds(tType)}(trial,1:size(fullRaster{3},2));
        count = count + 1;
    end 
end 

% create PSTHs 
winSec = input('How many seconds do you want to bin the calcium peak rate PSTHs? '); 
winFrames = (winSec*minFPS);
windows = ceil(size(redRaster,2)/winFrames);
numPeaks = zeros(numTrials,windows);
avTermNumPeaks = zeros(1,windows);
for win = 1:windows
    if win == 1 
        numPeaks(:,win) = sum(~redRaster(:,1:winFrames),2);
    elseif win > 1 
        if ((win-1)*winFrames)+1 < size(redRaster,2) && winFrames*win < size(redRaster,2)
            numPeaks(:,win) = nansum(~redRaster(:,((win-1)*winFrames)+1:winFrames*win),2);
        end 
    end 
    avTermNumPeaks = nanmean(numPeaks,1);
end
colNum = ceil(size(redRaster,2)/winFrames); 
if size(avTermNumPeaks,2) < colNum
    avTermNumPeaks(size(avTermNumPeaks,2)+1:colNum) = 0;
end 

%plot PSTH for all mice stacked 
figure
bar(avTermNumPeaks,'k')
stimStartF = floor((minFPS*20)/winFrames);
hold all 
stimStopF = (stimStartF + (minFPS*2)/winFrames);           
Frames = size(avTermNumPeaks,2);        
sec_TimeVals = (0:winSec*4:winSec*Frames)-20;
FrameVals = (0:4:Frames);   
plot([stimStartF stimStartF], [0 size(fullRaster{tType},1)], 'r','LineWidth',2)
plot([stimStopF stimStopF], [0 size(fullRaster{tType},1)], 'r','LineWidth',2)
ylim([0 0.3])
ax=gca;
axis on 
xticks(FrameVals)
ax.XTickLabel = sec_TimeVals;
ax.FontSize = 15;
xlabel('time (s)')
ylabel('number of Ca peaks')
label = sprintf('Number of calcium peaks per %0.2f sec',winSec);
sgtitle(label,'FontSize',25);
%}
%}
%% STA: find calcium peaks per terminal across entire experiment 
%{
% find peaks and then plot where they are in the entire TS 
stdTrace = cell(1,length(vidList));
sigPeaks = cell(1,length(vidList));
sigLocs = cell(1,length(vidList));
for vid = 1:length(vidList)
    for ccell = 1:length(terminals)
        %find the peaks 
%         figure;
%         ax=gca;
%         hold all
        [peaks, locs] = findpeaks(cDataFullTrace{vid}{terminals(ccell)},'MinPeakProminence',0.1,'MinPeakWidth',2); %0.6,0.8,0.9,1\
        %find the sig peaks (peaks above 2 standard deviations from mean) 
        stdTrace{vid}{terminals(ccell)} = std(cDataFullTrace{vid}{terminals(ccell)});  
        count = 1 ; 
        for loc = 1:length(locs)
            if peaks(loc) > stdTrace{vid}{terminals(ccell)}*2
                %if the peaks fall within the time windows used for the BBB
                %trace examples in the DOD figure 
%                 if locs(loc) > 197*FPSstack && locs(loc) < 206.5*FPSstack || locs(loc) > 256*FPSstack && locs(loc) < 265.5*FPSstack || locs(loc) > 509*FPSstack && locs(loc) < 518.5*FPSstack
                    sigPeaks{vid}{terminals(ccell)}(count) = peaks(loc);
                    sigLocs{vid}{terminals(ccell)}(count) = locs(loc);
%                     plot([locs(loc) locs(loc)], [-5000 5000], 'k','LineWidth',2)
                    count = count + 1;
%                 end 
            end 
        end 
        % below is plotting code 
        %{
        Frames = size(cDataFullTrace{vid}{terminals(ccell)},2);
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
%         sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*50:Frames_post_stim_start)/FPSstack)+51);
        sec_TimeVals = floor(((0:2:(Frames/FPSstack))));
        min_TimeVals = round(sec_TimeVals/60,2)+7.03;
        FrameVals = floor((0:(FPSstack*2):Frames)); 

        %smooth the calcium data 
        [ScDataFullTrace] = MovMeanSmoothData(cDataFullTrace{vid}{terminals(ccell)},(2/FPSstack),FPSstack);

%         plot((cDataFullTrace{vid}{terminals(ccell)})+150,'b','LineWidth',3)
%         plot(ScDataFullTrace+150,'b','LineWidth',3)
        plot(bDataFullTrace{vid},'r','LineWidth',3)

%         for trial = 1:size(state_start_f{vid},1)
%             if TrialTypes{vid}(trial,2) == 1
%                 plot([state_start_f{vid}(trial) state_start_f{vid}(trial)], [-5000 5000], 'b','LineWidth',2)
%                 plot([state_end_f{vid}(trial) state_end_f{vid}(trial)], [-5000 5000], 'b','LineWidth',2)
%             elseif TrialTypes{vid}(trial,2) == 2
%                 plot([state_start_f{vid}(trial) state_start_f{vid}(trial)], [-5000 5000], 'r','LineWidth',2)
%                 plot([state_end_f{vid}(trial) state_end_f{vid}(trial)], [-5000 5000], 'r','LineWidth',2)
%             end 
%         end 

        count = 1 ; 
        for loc = 1:length(locs)
            if peaks(loc) > stdTrace{vid}{terminals(ccell)}*2
                sigPeaks{vid}{terminals(ccell)}(count) = peaks(loc);
                sigLocs{vid}{terminals(ccell)}(count) = locs(loc);
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
        xLimStart = 256*FPSstack;
        xLimEnd = 266.5*FPSstack; 
        xlim([0 size(cDataFullTrace{vid}{terminals(ccell)},2)])
        xlim([xLimStart xLimEnd])
        ylim([-23 80])
        xlabel('time (sec)','FontName','Times')
%         if smoothQ ==  1
%             title({sprintf('terminal #%d data',terminals(ccell)); sprintf('smoothed by %0.2f seconds',filtTime)})
%         elseif smoothQ == 0 
%             title(sprintf('terminal #%d raw data',terminals(ccell)))
%         end    
           %}
    end 
end 
if tTypeQ == 1
    %tTypeSigLocs{1} = blue light
    %tTypeSigLocs{2} = red light
    %tTypeSigLocs{3} = ISI
    clear tTypeSigLocs
    tTypeSigLocs = cell(1,length(vidList));
    for ccell = 1:length(terminals)
        count = 1;
        count1 = 1;
        count2 = 1;
        for vid = 1:length(vidList)       
            for peak = 1:length(sigLocs{vid}{terminals(ccell)})  
                %if the peak location is less than all of the
                %state start frames 
                if all(sigLocs{vid}{terminals(ccell)}(peak) < state_start_f{vid})
                    %than that peak is before the first stim and is in an
                    %ISI period 
                    tTypeSigLocs{vid}{terminals(ccell)}{3}(count) = sigLocs{vid}{terminals(ccell)}(peak); 
                    count = count + 1;
                %if the peak location is not in the first ISI period 
                elseif sigLocs{vid}{terminals(ccell)}(peak) > state_start_f{vid}(1)-1                                        
                    %find the trial start frames that are < current peak
                    %location 
                    trials = find(state_start_f{vid} < sigLocs{vid}{terminals(ccell)}(peak)); 
                    trial = max(trials);
                    %if the current peak location is happening during the
                    %stim
                    if sigLocs{vid}{terminals(ccell)}(peak) < state_end_f{vid}(trial)
                        %sort into the correct cell depending on whether
                        %the light is blue or red                        
                        if TrialTypes{vid}(trial,2) == 1                            
                            tTypeSigLocs{vid}{terminals(ccell)}{1}(count1) = sigLocs{vid}{terminals(ccell)}(peak); 
                            count1 = count1 + 1;                      
                        elseif TrialTypes{vid}(trial,2) == 2 
                            tTypeSigLocs{vid}{terminals(ccell)}{2}(count2) = sigLocs{vid}{terminals(ccell)}(peak); 
                            count2 = count2 + 1;
                        end 
                    %if the current peak location is happening after the
                    %stim (in the next ISI)
                    elseif sigLocs{vid}{terminals(ccell)}(peak) > state_end_f{vid}(trial)
                        %sort into the correct cell depending on whether
                        %the light is blue or red 
                        tTypeSigLocs{vid}{terminals(ccell)}{3}(count) = sigLocs{vid}{terminals(ccell)}(peak); 
                        count = count + 1; 
                    end 
                end 
            end
        end 
    end 
       
    %remove all zeros 
    for vid = 1:length(vidList)
        for ccell = 1:length(terminals)    
            for per = 1:3
                if isempty (tTypeSigLocs{vid}{terminals(ccell)}{per}) == 0 
%                 [~,zeroLocs_tTypeSigLocs] = find(~tTypeSigLocs{vid}{terminals(ccell)}{per});
%                 tTypeSigLocs2{vid}{terminals(ccell)}{per} = NaN;          
                    tTypeSigLocs{vid}{terminals(ccell)}{per}(tTypeSigLocs{vid}{terminals(ccell)}{per} == 0) = [];
                end 
            end 
        end 
    end 
end 
%}
%% STA: sort data based on ca peak location 
% when tTypeQ == 0, you can select what trials to plot from and generate
% figures for spikes that occur throughout the entire experiment, during
% the wait period, the stim, and the reward (this was made for analyzing
% behavior data) 
%{
% the below should usually be commented out
% BBBQ = 1; VWQ = 1; CAQ = 1;

windSize = input('How big should the window be around Ca peak in seconds? 24 or 5 sec? ');
% windSize = 24; 
% windSize = 5;
if tTypeQ == 0 
    trialQ = input('Input 1 to plot spikes from specific trials. Input 0 otherwise. ');
    if trialQ == 1
        trials = input('Input what trials you want to plot spikes from. ');
    elseif trialQ == 0
        trials = 1:length(state_start_f{vid});
    end 
    bPerQ = input('Input 1 to plot STAs for spikes at different points in the task. Input 0 otherwise. ');
    if bPerQ == 1
        rewPerLen = input('How long (in sec) is the reward period? ');
        rewPerFlen = floor(rewPerLen*FPSstack);
        %make a lists of all frames where the stim and rew occur
        stimFrames2 = cell(1,length(vidList));
        rewFrames2 = cell(1,length(vidList));
        for vid = 1:length(vidList)
            for trial = 1:length(trials)
                stimFrames2{vid}{trials(trial)} = state_start_f{vid}(trials(trial)):state_end_f{vid}(trials(trial));
                rewFrames2{vid}{trials(trial)} = state_end_f{vid}(trials(trial))+1:state_end_f{vid}(trials(trial))+rewPerFlen+1;
            end 
            stimFrames = arrayfun(@(row) horzcat(stimFrames2{vid}{row, :}), 1:size(stimFrames2{vid}, 1), 'UniformOutput', false);
            rewFrames = arrayfun(@(row) horzcat(rewFrames2{vid}{row, :}), 1:size(rewFrames2{vid}, 1), 'UniformOutput', false);
        end 
    end 
    sortedCdata = cell(1,length(vidList));
    sortedBdata = cell(1,length(vidList));
    sortedVdata = cell(1,length(vidList));
    for vid = 1:length(vidList)
        for ccell = 1:length(terminals)
            for peak = 1:length(sigLocs{vid}{terminals(ccell)})            
                if sigLocs{vid}{terminals(ccell)}(peak)-floor((windSize/2)*FPSstack) > 0 && sigLocs{vid}{terminals(ccell)}(peak)+floor((windSize/2)*FPSstack) < length(cDataFullTrace{vid}{terminals(ccell)})                
                    start = sigLocs{vid}{terminals(ccell)}(peak)-floor((windSize/2)*FPSstack);
                    stop = sigLocs{vid}{terminals(ccell)}(peak)+floor((windSize/2)*FPSstack);                
                    if start == 0 
                        start = 1 ;
                        stop = start + floor((windSize/2)*FPSstack) + floor((windSize/2)*FPSstack);
                    end        
                    if BBBQ == 1
                        for BBBroi = 1:length(bDataFullTrace{1})
                            if trialQ == 0
                                if bPerQ == 0 
                                    sortedBdata{vid}{BBBroi}{terminals(ccell)}{1}(peak,:) = bDataFullTrace{vid}{BBBroi}(start:stop);
                                elseif bPerQ == 1    
                                    % create an STA for peaks regardless of
                                    % when they occur 
                                    sortedBdata{vid}{BBBroi}{terminals(ccell)}{1}(peak,:) = bDataFullTrace{vid}{BBBroi}(start:stop);
                                    %if the peak occured during the
                                    %stimulus 
                                    if ismember(sigLocs{vid}{terminals(ccell)}(peak),stimFrames{vid}) == 1 
                                        sortedBdata{vid}{BBBroi}{terminals(ccell)}{2}(peak,:) = bDataFullTrace{vid}{BBBroi}(start:stop);
                                    %if the peak occured during the reward
                                    elseif ismember(sigLocs{vid}{terminals(ccell)}(peak),rewFrames{vid}) == 1 
                                        sortedBdata{vid}{BBBroi}{terminals(ccell)}{3}(peak,:) = bDataFullTrace{vid}{BBBroi}(start:stop);
                                    %if the peak occured during the ITI
                                    else
                                        sortedBdata{vid}{BBBroi}{terminals(ccell)}{4}(peak,:) = bDataFullTrace{vid}{BBBroi}(start:stop);
                                    end 
                                end 
                            elseif trialQ == 1 
                                if sigLocs{vid}{terminals(ccell)}(peak) > state_start_f{vid}(trials(1)) && sigLocs{vid}{terminals(ccell)}(peak) < state_end_f{vid}(trials(end))
                                    if bPerQ == 0 
                                        sortedBdata{vid}{BBBroi}{terminals(ccell)}{1}(peak,:) = bDataFullTrace{vid}{BBBroi}(start:stop);
                                    elseif bPerQ == 1    
                                        % create an STA for peaks regardless of
                                        % when they occur 
                                        sortedBdata{vid}{BBBroi}{terminals(ccell)}{1}(peak,:) = bDataFullTrace{vid}{BBBroi}(start:stop);
                                        %if the peak occured during the
                                        %stimulus 
                                        if ismember(sigLocs{vid}{terminals(ccell)}(peak),stimFrames{vid}) == 1 
                                            sortedBdata{vid}{BBBroi}{terminals(ccell)}{2}(peak,:) = bDataFullTrace{vid}{BBBroi}(start:stop);
                                        %if the peak occured during the reward
                                        elseif ismember(sigLocs{vid}{terminals(ccell)}(peak),rewFrames{vid}) == 1 
                                            sortedBdata{vid}{BBBroi}{terminals(ccell)}{3}(peak,:) = bDataFullTrace{vid}{BBBroi}(start:stop);
                                        %if the peak occured during the ITI
                                        else
                                            sortedBdata{vid}{BBBroi}{terminals(ccell)}{4}(peak,:) = bDataFullTrace{vid}{BBBroi}(start:stop);
                                        end 
                                    end 
                                end 
                            end 
                        end 
                    end 
                    if trialQ == 0
                        if bPerQ == 0 
                            sortedCdata{vid}{terminals(ccell)}{1}(peak,:) = cDataFullTrace{vid}{terminals(ccell)}(start:stop);
                        elseif bPerQ == 1    
                            % create an STA for peaks regardless of
                            % when they occur 
                            sortedCdata{vid}{terminals(ccell)}{1}(peak,:) = cDataFullTrace{vid}{terminals(ccell)}(start:stop);
                            %if the peak occured during the
                            %stimulus 
                            if ismember(sigLocs{vid}{terminals(ccell)}(peak),stimFrames{vid}) == 1 
                                sortedCdata{vid}{terminals(ccell)}{2}(peak,:) = cDataFullTrace{vid}{terminals(ccell)}(start:stop);
                            %if the peak occured during the reward
                            elseif ismember(sigLocs{vid}{terminals(ccell)}(peak),rewFrames{vid}) == 1 
                                sortedCdata{vid}{terminals(ccell)}{3}(peak,:) = cDataFullTrace{vid}{terminals(ccell)}(start:stop);
                            %if the peak occured during the ITI
                            else
                                sortedCdata{vid}{terminals(ccell)}{4}(peak,:) = cDataFullTrace{vid}{terminals(ccell)}(start:stop);
                            end 
                        end 
                    elseif trialQ == 1
                        if sigLocs{vid}{terminals(ccell)}(peak) > state_start_f{vid}(trials(1)) && sigLocs{vid}{terminals(ccell)}(peak) < state_end_f{vid}(trials(end))
                            if bPerQ == 0 
                                sortedCdata{vid}{terminals(ccell)}{1}(peak,:) = cDataFullTrace{vid}{terminals(ccell)}(start:stop);
                            elseif bPerQ == 1    
                                % create an STA for peaks regardless of
                                % when they occur 
                                sortedCdata{vid}{terminals(ccell)}{1}(peak,:) = cDataFullTrace{vid}{terminals(ccell)}(start:stop);
                                %if the peak occured during the
                                %stimulus 
                                if ismember(sigLocs{vid}{terminals(ccell)}(peak),stimFrames{vid}) == 1 
                                    sortedCdata{vid}{terminals(ccell)}{2}(peak,:) = cDataFullTrace{vid}{terminals(ccell)}(start:stop);
                                %if the peak occured during the reward
                                elseif ismember(sigLocs{vid}{terminals(ccell)}(peak),rewFrames{vid}) == 1 
                                    sortedCdata{vid}{terminals(ccell)}{3}(peak,:) = cDataFullTrace{vid}{terminals(ccell)}(start:stop);
                                %if the peak occured during the ITI
                                else
                                    sortedCdata{vid}{terminals(ccell)}{4}(peak,:) = cDataFullTrace{vid}{terminals(ccell)}(start:stop);
                                end 
                            end 
                        end 
                    end 
                    if VWQ == 1
                        for VWroi = 1:length(vDataFullTrace{1})
                            if trialQ == 0
                                if bPerQ == 0 
                                    sortedVdata{vid}{VWroi}{terminals(ccell)}{1}(peak,:) = vDataFullTrace{vid}{VWroi}(start:stop);
                                elseif bPerQ == 1    
                                    % create an STA for peaks regardless of
                                    % when they occur 
                                    sortedVdata{vid}{VWroi}{terminals(ccell)}{1}(peak,:) = vDataFullTrace{vid}{VWroi}(start:stop);
                                    %if the peak occured during the
                                    %stimulus 
                                    if ismember(sigLocs{vid}{terminals(ccell)}(peak),stimFrames{vid}) == 1 
                                        sortedVdata{vid}{VWroi}{terminals(ccell)}{2}(peak,:) = vDataFullTrace{vid}{VWroi}(start:stop);
                                    %if the peak occured during the reward
                                    elseif ismember(sigLocs{vid}{terminals(ccell)}(peak),rewFrames{vid}) == 1 
                                        sortedVdata{vid}{VWroi}{terminals(ccell)}{3}(peak,:) = vDataFullTrace{vid}{VWroi}(start:stop);
                                    %if the peak occured during the ITI
                                    else
                                        sortedVdata{vid}{VWroi}{terminals(ccell)}{4}(peak,:) = vDataFullTrace{vid}{VWroi}(start:stop);
                                    end 
                                end 
                            elseif trialQ == 1
                                if sigLocs{vid}{terminals(ccell)}(peak) > state_start_f{vid}(trials(1)) && sigLocs{vid}{terminals(ccell)}(peak) < state_end_f{vid}(trials(end))
                                    if bPerQ == 0 
                                        sortedVdata{vid}{VWroi}{terminals(ccell)}{1}(peak,:) = vDataFullTrace{vid}{VWroi}(start:stop);
                                    elseif bPerQ == 1    
                                        % create an STA for peaks regardless of
                                        % when they occur 
                                        sortedVdata{vid}{VWroi}{terminals(ccell)}{1}(peak,:) = vDataFullTrace{vid}{VWroi}(start:stop);
                                        %if the peak occured during the
                                        %stimulus 
                                        if ismember(sigLocs{vid}{terminals(ccell)}(peak),stimFrames{vid}) == 1 
                                            sortedVdata{vid}{VWroi}{terminals(ccell)}{2}(peak,:) = vDataFullTrace{vid}{VWroi}(start:stop);
                                        %if the peak occured during the reward
                                        elseif ismember(sigLocs{vid}{terminals(ccell)}(peak),rewFrames{vid}) == 1 
                                            sortedVdata{vid}{VWroi}{terminals(ccell)}{3}(peak,:) = vDataFullTrace{vid}{VWroi}(start:stop);
                                        %if the peak occured during the ITI
                                        else
                                            sortedVdata{vid}{VWroi}{terminals(ccell)}{4}(peak,:) = vDataFullTrace{vid}{VWroi}(start:stop);
                                        end 
                                    end 
                                end 
                            end 
                        end 
                    end 
                end 
            end 
        end 
    end 
    %replace rows of all 0s w/NaNs
    for vid = 1:length(vidList)
        for ccell = 1:length(terminals) 
            for per = 1:length(sortedCdata{vid}{terminals(ccell)})
                if BBBQ == 1
                    for BBBroi = 1:length(bDataFullTrace{1})
                        nonZeroRowsB = all(sortedBdata{vid}{BBBroi}{terminals(ccell)}{per} == 0,2);
                        sortedBdata{vid}{BBBroi}{terminals(ccell)}{per}(nonZeroRowsB,:) = NaN;
                    end 
                end 
                nonZeroRowsC = all(sortedCdata{vid}{terminals(ccell)}{per} == 0,2);
                sortedCdata{vid}{terminals(ccell)}{per}(nonZeroRowsC,:) = NaN;
                if VWQ == 1
                    for VWroi = 1:length(vDataFullTrace{1})
                        nonZeroRowsV = all(sortedVdata{vid}{VWroi}{terminals(ccell)}{per} == 0,2);
                        sortedVdata{vid}{VWroi}{terminals(ccell)}{per}(nonZeroRowsV,:) = NaN;
                    end 
                end 
            end 
        end 
    end 
    
elseif tTypeQ == 1 
    %sort C,B,V calcium peak time locked data (into different categories depending on whether a light was on and color light) 
    sortedCdata = cell(1,length(vidList));
    sortedBdata = cell(1,length(vidList));
    sortedVdata = cell(1,length(vidList));
    for vid = 1:length(vidList)
        for ccell = 1:length(terminals)
            for per = 1:3                               
                for peak = 1:length(tTypeSigLocs{vid}{terminals(ccell)}{per})                                        
                    if tTypeSigLocs{vid}{terminals(ccell)}{per}(peak)-floor((windSize/2)*FPSstack) > 0 && tTypeSigLocs{vid}{terminals(ccell)}{per}(peak)+floor((windSize/2)*FPSstack) < length(cDataFullTrace{vid}{terminals(ccell)})                                     
                        start = tTypeSigLocs{vid}{terminals(ccell)}{per}(peak)-floor((windSize/2)*FPSstack);
                        stop = tTypeSigLocs{vid}{terminals(ccell)}{per}(peak)+floor((windSize/2)*FPSstack);                
                        if start == 0 
                            start = 1 ;
                            stop = start + floor((windSize/2)*FPSstack) + floor((windSize/2)*FPSstack);
                        end     
                        if BBBQ == 1
                            for BBBroi = 1:length(bDataFullTrace{1})
                                sortedBdata{vid}{BBBroi}{terminals(ccell)}{per}(peak,:) = bDataFullTrace{vid}{BBBroi}(start:stop);
                            end 
                        end 
                        sortedCdata{vid}{terminals(ccell)}{per}(peak,:) = cDataFullTrace{vid}{terminals(ccell)}(start:stop);
                        if VWQ == 1
                            for VWroi = 1:length(vDataFullTrace{1})
                                sortedVdata{vid}{VWroi}{terminals(ccell)}{per}(peak,:) = vDataFullTrace{vid}{VWroi}(start:stop);
                            end 
                        end 
                    end 
                end 
            end 
        end 
    end  
end 
%}
%% STA: smooth and normalize to baseline period
%{
if windSize == 24 
    baselineTime = 5;
elseif windSize == 5
    baselineTime = 0.5;
end 

if tTypeQ == 0 
    %{
    %find the BBB traces that increase after calcium peak onset (changePt) 
    %{
    SNBdataPeaks_IncAfterCa = cell(1,length(vidList));
    nonWeighted_SNBdataPeaks_IncAfterCa = cell(1,length(vidList));
    SNBdataPeaks_NotIncAfterCa = cell(1,length(vidList));
    nonWeighted_SNBdataPeaks_NotIncAfterCa = cell(1,length(vidList));
    for vid = 1:length(vidList)
        for ccell = 1:length(terminals)   
            count1 = 1;
            count2 = 1;
            for peak = 1:size(NBdataPeaks{vid}{terminals(ccell)},1)
                %if pre changePt mean is less than post changePt mean 
                if mean(SNBdataPeaks{vid}{terminals(ccell)}(peak,1:changePt)) < mean(SNBdataPeaks{vid}{terminals(ccell)}(peak,changePt:end))
                    SNBdataPeaks_IncAfterCa{vid}{terminals(ccell)}(count1,:) = SNBdataPeaks{vid}{terminals(ccell)}(peak,:);                              
                    nonWeighted_SNBdataPeaks_IncAfterCa{vid}{terminals(ccell)}(count1,:) = SNonWeightedBdataPeaks{vid}{terminals(ccell)}(peak,:);
                    count1 = count1+1;
                %find the traces that do not increase after calcium peak onset 
                elseif mean(SNBdataPeaks{vid}{terminals(ccell)}(peak,1:changePt)) >= mean(SNBdataPeaks{vid}{terminals(ccell)}(peak,changePt:end))
                    SNBdataPeaks_NotIncAfterCa{vid}{terminals(ccell)}(count2,:) = SNBdataPeaks{vid}{terminals(ccell)}(peak,:);
                    nonWeighted_SNBdataPeaks_NotIncAfterCa{vid}{terminals(ccell)}(count2,:) = SNonWeightedBdataPeaks{vid}{terminals(ccell)}(peak,:);
                    count2 = count2+1;
                end 
            end 
        end 
    end 

    SNBdataPeaks_IncAfterCa_2 = cell(1,length(vidList));
    SNBdataPeaks_NotIncAfterCa_2 = cell(1,length(vidList));
    AVSNBdataPeaks = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
    AVSNBdataPeaksNotInc = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
    %average the BBB traces that increase after calcium peak onset and those
    %that don't
    for vid = 1:length(vidList)
        for ccell = 1:length(terminals)
            if terminals(ccell) <= length(SNBdataPeaks_IncAfterCa{vid}) 
                if isempty(SNBdataPeaks_IncAfterCa{vid}{terminals(ccell)}) == 0 
                    SNBdataPeaks_IncAfterCa_2{terminals(ccell)}(vid,:) = mean(SNBdataPeaks_IncAfterCa{vid}{terminals(ccell)},1);  
                    SNBdataPeaks_NotIncAfterCa_2{terminals(ccell)}(vid,:) = mean(SNBdataPeaks_NotIncAfterCa{vid}{terminals(ccell)},1); 
                end            
            end
            %find all 0 rows and replace with NaNs
            zeroRows = all(SNBdataPeaks_IncAfterCa_2{terminals(ccell)} == 0,2);
            SNBdataPeaks_IncAfterCa_2{terminals(ccell)}(zeroRows,:) = NaN; 
            zeroRowsNotInc = all(SNBdataPeaks_NotIncAfterCa_2{terminals(ccell)} == 0,2);
            SNBdataPeaks_NotIncAfterCa_2{terminals(ccell)}(zeroRowsNotInc,:) = NaN; 
            %create average trace per terminal
            AVSNBdataPeaks{terminals(ccell)} = nansum(SNBdataPeaks_IncAfterCa_2{terminals(ccell)},1);
            AVSNBdataPeaksNotInc{terminals(ccell)} = nansum(SNBdataPeaks_NotIncAfterCa_2{terminals(ccell)},1);
        end 
    end 
%}
    
    %smoothing option
    smoothQ = input('Input 0 to plot non-smoothed data. Input 1 to plot smoothed data. ');
    if smoothQ == 0 
        if BBBQ == 1
            SBdataPeaks = sortedBdata;
        end 
        SCdataPeaks = sortedCdata;
        if VWQ == 1
            SVdataPeaks = sortedVdata;
        end 
    elseif smoothQ == 1
        filtTime = input('How many seconds do you want to smooth your data by? ');
        SBdataPeaks = cell(1,length(vidList));
%         SNCdataPeaks = cell(1,length(vidList));
        SVdataPeaks = cell(1,length(vidList));
        SCdataPeaks = sortedCdata;
        for vid = 1:length(vidList)
            for ccell = 1:length(terminals)
                for per = 1:length(sortedCdata{vid}{terminals(ccell)})
    %                 [sC_Data] = MovMeanSmoothData(sortedCdata{vid}{terminals(ccell)},filtTime,FPSstack);
    %                 SCdataPeaks{vid}{terminals(ccell)} = sC_Data; 
                    if BBBQ == 1
                        for BBBroi = 1:length(bDataFullTrace{1})
                            [sB_Data] = MovMeanSmoothData(sortedBdata{vid}{BBBroi}{terminals(ccell)}{per},filtTime,FPSstack);
                            SBdataPeaks{vid}{BBBroi}{terminals(ccell)}{per} = sB_Data;
                            %remove rows full of 0s if there are any b = a(any(a,2),:)
                            SBdataPeaks{vid}{BBBroi}{terminals(ccell)}{per} = SBdataPeaks{vid}{BBBroi}{terminals(ccell)}{per}(any(SBdataPeaks{vid}{BBBroi}{terminals(ccell)}{per},2),:);
                        end
                    end 
                    if VWQ == 1
                        for VWroi = 1:length(vDataFullTrace{1})
                            [sV_Data] = MovMeanSmoothData(sortedVdata{vid}{VWroi}{terminals(ccell)}{per},filtTime,FPSstack);
                            SVdataPeaks{vid}{VWroi}{terminals(ccell)}{per} = sV_Data;
                            %remove rows full of 0s if there are any b = a(any(a,2),:)
                            SVdataPeaks{vid}{VWroi}{terminals(ccell)}{per} = SVdataPeaks{vid}{VWroi}{terminals(ccell)}{per}(any(SVdataPeaks{vid}{VWroi}{terminals(ccell)}{per},2),:);
                        end 
                    end 
                    %remove rows full of 0s if there are any b = a(any(a,2),:)
                    SCdataPeaks{vid}{terminals(ccell)}{per} = SCdataPeaks{vid}{terminals(ccell)}{per}(any(SCdataPeaks{vid}{terminals(ccell)}{per},2),:);
                end 
            end 
        end 
    end 
   
    %normalize
    if BBBQ == 1
        SNBdataPeaks = cell(1,length(vidList));
        sortedBdata2 = cell(1,length(vidList));
    end 
    if VWQ == 1 
        SNVdataPeaks = cell(1,length(vidList));
        sortedVdata2 = cell(1,length(vidList));
    end     
    SNCdataPeaks = cell(1,length(vidList));    
    sortedCdata2 = cell(1,length(vidList));   
     for vid = 1:length(vidList)
        for ccell = 1:length(terminals)
            for per = 1:length(sortedCdata{vid}{terminals(ccell)})
                if isempty(SBdataPeaks{vid}{BBBroi}{terminals(ccell)}) == 0 
                    %the data needs to be added to because there are some
                    %negative gonig points which mess up the normalizing 
                    if BBBQ == 1
                        for BBBroi = 1:length(bDataFullTrace{1})
                            % determine the minimum value, add space (+100)
                            minValToAdd = abs(ceil(min(min(SBdataPeaks{vid}{BBBroi}{terminals(ccell)}{per}))))+100;
                            % add min value 
                            sortedBdata2{vid}{BBBroi}{terminals(ccell)}{per} = SBdataPeaks{vid}{BBBroi}{terminals(ccell)}{per} + minValToAdd;
                        end
                    end 
                    % determine the minimum value, add space (+100)
                    minValToAdd = abs(ceil(min(min(SCdataPeaks{vid}{terminals(ccell)}{per}))))+100;
                    % add min value
                    sortedCdata2{vid}{terminals(ccell)}{per} = SCdataPeaks{vid}{terminals(ccell)}{per} + minValToAdd;
                    if VWQ == 1
                        for VWroi = 1:length(vDataFullTrace{1})
                            % determine the minimum value, add space (+100)
                            minValToAdd = abs(ceil(min(min(SVdataPeaks{vid}{VWroi}{terminals(ccell)}{per}))))+100;
                            % add min value
                            sortedVdata2{vid}{VWroi}{terminals(ccell)}{per} = SVdataPeaks{vid}{VWroi}{terminals(ccell)}{per} + minValToAdd;
                        end 
                    end 

                    %normalize to baselineTime sec before changePt (calcium peak
                    %onset) BLstart 
                    changePt = floor(size(sortedCdata{1}{terminals(1)}{1},2)/2)-4;
    %                 BLstart = changePt - floor(0.5*FPSstack);
                    BLstart = changePt - floor(baselineTime*FPSstack);
                    if BBBQ == 1
                        for BBBroi = 1:length(bDataFullTrace{1})
                            if isempty(sortedBdata2{vid}{BBBroi}{terminals(ccell)}{per}) == 0
                                SNBdataPeaks{vid}{BBBroi}{terminals(ccell)}{per} = ((sortedBdata2{vid}{BBBroi}{terminals(ccell)}{per})./(nanmean(sortedBdata2{vid}{BBBroi}{terminals(ccell)}{per}(:,BLstart:changePt),2)))*100;
                            end 
                        end 
                    end 
                    if isempty(sortedCdata2{vid}{terminals(ccell)}{per}) == 0 
                        SNCdataPeaks{vid}{terminals(ccell)}{per} = ((sortedCdata2{vid}{terminals(ccell)}{per})./(nanmean(sortedCdata2{vid}{terminals(ccell)}{per}(:,BLstart:changePt),2)))*100;
                    end 
                    if VWQ == 1
                        if isempty(sortedVdata2{vid}{VWroi}{terminals(ccell)}{per}) == 0 
                            for VWroi = 1:length(vDataFullTrace{1})
                                SNVdataPeaks{vid}{VWroi}{terminals(ccell)}{per} = ((sortedVdata2{vid}{VWroi}{terminals(ccell)}{per})./(nanmean(sortedVdata2{vid}{VWroi}{terminals(ccell)}{per}(:,BLstart:changePt),2)))*100;
                            end 
                        end 
                    end 

                    %normalize to the first 0.5 sec (THIS IS JUST A SANITY
                    %CHECK 
                    %{
                    for BBBroi = 1:length(bDataFullTrace{1})
                        NsortedBdata{vid}{BBBroi}{terminals(ccell)} = ((sortedBdata2{vid}{BBBroi}{terminals(ccell)})./(nanmean(sortedBdata2{vid}{BBBroi}{terminals(ccell)}(:,1:floor(0.5*FPSstack)),2)))*100;
                    end 
                    NsortedCdata{vid}{terminals(ccell)} = ((sortedCdata2{vid}{terminals(ccell)})./(nanmean(sortedCdata2{vid}{terminals(ccell)}(:,1:floor(0.5*FPSstack)),2)))*100;
                    if VWQ == 1
                        for VWroi = 1:length(vDataFullTrace{1})
                            NsortedVdata{vid}{VWroi}{terminals(ccell)} = ((sortedVdata2{vid}{VWroi}{terminals(ccell)})./(nanmean(sortedVdata2{vid}{VWroi}{terminals(ccell)}(:,1:floor(0.5*FPSstack)),2)))*100;
                        end 
                    end 
                    %}
                end     
            end 
        end 
     end      
    %} 
elseif tTypeQ == 1 
    %{
    smoothQ = input('Input 0 to plot non-smoothed data. Input 1 to plot smoothed data. ');
    if smoothQ == 0 
        if BBBQ == 1
            SBdataPeaks = sortedBdata;
        end 
        if VWQ == 1
            SVdataPeaks = sortedVdata;
        end 
        SCdataPeaks = sortedCdata;        
    elseif smoothQ == 1
        filtTime = input('How many seconds do you want to smooth your data by? ');
        SBdataPeaks = cell(1,length(vidList));
%         SCdataPeaks = cell(1,length(vidList));
        SVdataPeaks = cell(1,length(vidList));
        SCdataPeaks = sortedCdata;
         for vid = 1:length(vidList)
            for ccell = 1:length(terminals)
                for per = 1:3   
                    if length(sortedBdata{vid}{BBBroi}{terminals(ccell)}) >= per  
                        if isempty(sortedBdata{vid}{BBBroi}{terminals(ccell)}{per}) == 0 
                            for peak = 1:size(sortedBdata{vid}{1}{terminals(ccell)}{per},1)
                                if BBBQ == 1
                                    for BBBroi = 1:length(bDataFullTrace{1})
                                        [SBPeak_Data] = MovMeanSmoothData(sortedBdata{vid}{BBBroi}{terminals(ccell)}{per}(peak,:),filtTime,FPSstack);
                                        SBdataPeaks{vid}{BBBroi}{terminals(ccell)}{per}(peak,:) = SBPeak_Data; 
                                        %remove rows full of 0s if there are any b = a(any(a,2),:)
                                        SBdataPeaks{vid}{BBBroi}{terminals(ccell)}{per} = SBdataPeaks{vid}{BBBroi}{terminals(ccell)}{per}(any(SBdataPeaks{vid}{BBBroi}{terminals(ccell)}{per},2),:);
                                    end 
                                end
    %                             [SCPeak_Data] = MovMeanSmoothData(sortedCdata{vid}{terminals(ccell)}{per}(peak,:),filtTime,FPSstack);
    %                             SCdataPeaks{vid}{terminals(ccell)}{per}(peak,:) = SCPeak_Data;     
                                if VWQ == 1
                                    for VWroi = 1:length(vDataFullTrace{1})
                                        [SVPeak_Data] = MovMeanSmoothData(sortedVdata{vid}{VWroi}{terminals(ccell)}{per}(peak,:),filtTime,FPSstack);
                                        SVdataPeaks{vid}{VWroi}{terminals(ccell)}{per}(peak,:) = SVPeak_Data;   
                                        %remove rows full of 0s if there are any b = a(any(a,2),:)
                                        SVdataPeaks{vid}{VWroi}{terminals(ccell)}{per} = SVdataPeaks{vid}{VWroi}{terminals(ccell)}{per}(any(SVdataPeaks{vid}{VWroi}{terminals(ccell)}{per},2),:);
                                    end 
                                end 
                            end 
                        end
                        %remove rows full of 0s if there are any b = a(any(a,2),:)
                        SCdataPeaks{vid}{terminals(ccell)}{per} = SCdataPeaks{vid}{terminals(ccell)}{per}(any(SCdataPeaks{vid}{terminals(ccell)}{per},2),:);
                    end 
                end 
            end 
         end        
    end  
    
    %normalize
    if BBBQ == 1
        SNBdataPeaks = cell(1,length(vidList));
        sortedBdata2 = cell(1,length(vidList));
    end 
    if VWQ == 1
        SNVdataPeaks = cell(1,length(vidList));
        sortedVdata2 = cell(1,length(vidList));
    end 
    SNCdataPeaks = cell(1,length(vidList));        
    sortedCdata2 = cell(1,length(vidList));    
     for vid = 1:length(vidList)
        for ccell = 1:length(terminals)
            if isempty(sortedBdata{vid}{BBBroi}{terminals(ccell)}) == 0 
                for per = 1:3      
                    if length(sortedBdata{vid}{BBBroi}{terminals(ccell)}) >= per  
                        if isempty(sortedBdata{vid}{BBBroi}{terminals(ccell)}{per}) == 0 
                            %the data needs to be added to because there are some
                            %negative gonig points which mess up the normalizing 
                            if BBBQ == 1
                                for BBBroi = 1:length(bDataFullTrace{1})     
                                    % determine the minimum value, add space (+100)
                                    minValToAdd = abs(ceil(min(min(SBdataPeaks{vid}{BBBroi}{terminals(ccell)}{per}))))+100;
                                    % add min value 
                                    sortedBdata2{vid}{BBBroi}{terminals(ccell)}{per} = SBdataPeaks{vid}{BBBroi}{terminals(ccell)}{per} + minValToAdd;                    
                                end     
                            end 
                            % determine the minimum value, add space (+100)
                            minValToAdd = abs(ceil(min(min(SCdataPeaks{vid}{terminals(ccell)}{per}))))+100;
                            % add min value 
                            sortedCdata2{vid}{terminals(ccell)}{per} = SCdataPeaks{vid}{terminals(ccell)}{per} + minValToAdd;     
                            if VWQ == 1 
                                for VWroi = 1:length(vDataFullTrace{1})     
                                    % determine the minimum value, add space (+100)
                                    minValToAdd = abs(ceil(min(min(SVdataPeaks{vid}{VWroi}{terminals(ccell)}{per}))))+100;
                                    % add min value 
                                    sortedVdata2{vid}{VWroi}{terminals(ccell)}{per} = SVdataPeaks{vid}{VWroi}{terminals(ccell)}{per} + minValToAdd;                 
                                end 
                            end 

                              %this normalizes to the first 1/3 section of the trace
                              %(18 frames) 
            %{
                                NsortedBdata{vid}{terminals(ccell)}{per} = ((sortedBdata2{vid}{terminals(ccell)}{per})./((nanmean(sortedBdata2{vid}{terminals(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3)),2))))*100;
                                NsortedCdata{vid}{terminals(ccell)}{per} = ((sortedCdata2{vid}{terminals(ccell)}{per})./((nanmean(sortedCdata2{vid}{terminals(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3)),2))))*100;
                                NsortedVdata{vid}{terminals(ccell)}{per} = ((sortedVdata2{vid}{terminals(ccell)}{per})./((nanmean(sortedVdata2{vid}{terminals(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3)),2))))*100;            
            %}                     
                              
                            %normalize to baselineTime sec before changePt (calcium peak
                            %onset) BLstart 
                            changePt = floor(size(sortedCdata{1}{terminals(1)}{2},2)/2)-4;
                            BLstart = changePt - floor(baselineTime*FPSstack);
                            if BBBQ == 1
                                for BBBroi = 1:length(bDataFullTrace{1})
                                    if isempty(sortedBdata{vid}{BBBroi}{terminals(ccell)}{per}) == 0 
                                        SNBdataPeaks{vid}{BBBroi}{terminals(ccell)}{per} = ((sortedBdata2{vid}{BBBroi}{terminals(ccell)}{per})./(nanmean(sortedBdata2{vid}{BBBroi}{terminals(ccell)}{per}(:,BLstart:changePt),2)))*100;                
                                    end 
                                end 
                            end 
                            SNCdataPeaks{vid}{terminals(ccell)}{per} = ((sortedCdata2{vid}{terminals(ccell)}{per})./(nanmean(sortedCdata2{vid}{terminals(ccell)}{per}(:,BLstart:changePt),2)))*100;               
                            if VWQ == 1
                                for VWroi = 1:length(vDataFullTrace{1})                    
                                    SNVdataPeaks{vid}{VWroi}{terminals(ccell)}{per} = ((sortedVdata2{vid}{VWroi}{terminals(ccell)}{per})./(nanmean(sortedVdata2{vid}{VWroi}{terminals(ccell)}{per}(:,BLstart:changePt),2)))*100;                    
                                end 
                            end 
                        end 
                    end 
                end 
            end 
        end 
     end 
    %}
end 
%}                     
%% STA 1: plot calcium spike triggered averages (this can plot traces within 2 std from the mean, but all data gets stored)
% if you are averaging, this plots one trace at a time. if not averaging,
% this plots all traces. this also only plots one BBB or VW ROI at once. 
%{
%initialize arrays 
CAQinit = input('Input 1 if you want to initialize Ca data arrays. ');
if CAQinit == 1 
    AVSNCdataPeaks = cell(1,length(sortedCdata{1}));
    AVSNCdataPeaks2 = cell(1,length(sortedCdata{1}));
    clear AVSNCdataPeaks3
    allCTraces = cell(1,length(SNCdataPeaks{1}));
    CTraces = cell(1,length(SNCdataPeaks{1}));
end 
BBBQinit = input('Input 1 if you want to initialize BBB data arrays. ');
if BBBQinit == 1
    AVSNBdataPeaks = cell(1,length(sortedBdata{1}));
    AVSNBdataPeaks2 = cell(1,length(sortedBdata{1}));
    AVSNBdataPeaks3 = cell(1,length(sortedBdata{1}));
    allBTraces = cell(1,length(sortedBdata{1}));
    BTraces = cell(1,length(sortedBdata{1}));
end 
VWQinit = input('Input 1 if you want to initialize vessel width data arrays . ');
if VWQinit == 1
    AVSNVdataPeaks = cell(1,length(sortedVdata{1}));
    AVSNVdataPeaks2 = cell(1,length(sortedVdata{1}));
    AVSNVdataPeaks3 = cell(1,length(sortedVdata{1}));
    allVTraces = cell(1,length(sortedVdata{1}));
    VTraces = cell(1,length(sortedVdata{1}));
end 
saveQ = input('Input 1 to save the figures. Input 0 otherwise. ');
if saveQ == 1                
    dir1 = input('What folder are you saving these images in? ');
end         
VWpQ = input('Input 1 if you want to plot vessel width data. ');
if VWpQ == 1 
    VWROI = input('Input what VW ROI you want to plot. ');
end 
BBBpQ = input('Input 1 if you want to plot BBB data. ');
if BBBpQ == 1
    BBBROI = input('Input what BBB ROI you want to plot. ');
end 
AVQ = input('Input 1 to average across Ca ROIs. Input 0 otherwise. ');
if AVQ == 1
    AVQ2 = input('Input 1 to specify what Ca ROIs to average. Input 0 to average all Ca ROIs. ');
    if AVQ2 == 0 % average all Ca ROIs 
        terms = terminals;
    elseif AVQ2 == 1 % specify what Ca ROIs to average 
        terms = input('Input the Ca ROIs you want to average. ');
    end 
elseif AVQ == 0 
    terms = terminals; 
end 

if tTypeQ == 0 
    %{
    if AVQ == 0 
        for ccell = 1:length(terms)
            for per = 1:length(sortedCdata{vid}{terminals(ccell)})
                fig = figure;
                Frames = size(SNBdataPeaks{1}{1}{terms(ccell)}{per},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack))+1;
                FrameVals = round((1:FPSstack:Frames))+5; 
                ax=gca;
                hold all
                count = 1;
                % sort data 
                for vid = 1:length(vidList)      
                    for peak = 1:size(SNCdataPeaks{vid}{terms(ccell)}{per},1) 
                        if BBBQ == 1
                            for BBBroi = 1:length(sortedBdata{1})
                                allBTraces{BBBroi}{terms(ccell)}{per}(count,:) = (SNBdataPeaks{vid}{BBBroi}{terms(ccell)}{per}(peak,:)-100); 
                                %remove rows full of 0s if there are any b = a(any(a,2),:)
                                allBTraces{BBBroi}{terms(ccell)}{per} = allBTraces{BBBroi}{terms(ccell)}{per}(any(allBTraces{BBBroi}{terms(ccell)}{per},2),:);
                            end 
                        end 
                        if VWQ == 1
                            for VWroi = 1:length(sortedVdata{1})
                                allVTraces{VWroi}{terms(ccell)}{per}(count,:) = (SNVdataPeaks{vid}{VWroi}{terms(ccell)}{per}(peak,:)-100); 
                                %remove rows full of 0s if there are any b = a(any(a,2),:)
                                allVTraces{VWroi}{terms(ccell)}{per} = allVTraces{VWroi}{terms(ccell)}{per}(any(allVTraces{VWroi}{terms(ccell)}{per},2),:);                                    
                            end 
                        end 
                        allCTraces{terms(ccell)}{per}(count,:) = (SNCdataPeaks{vid}{terms(ccell)}{per}(peak,:)-100);
                        %remove rows full of 0s if there are any b = a(any(a,2),:)
                        allCTraces{terms(ccell)}{per} = allCTraces{terms(ccell)}{per}(any(allCTraces{terms(ccell)}{per},2),:);
                        count = count + 1;
                    end 
                end 

                %randomly plot 100 calcium traces - no replacement: each trace can
                %only be plotted once 
                %{
                traceInds = randperm(332);
                for peak = 1:100       
                    plot(allCTraces{terminals(ccell)}(traceInds(peak),:),'b')

                end 
                %}                
                
                if per <= size(allCTraces{terms(ccell)},2)
                    %get averages of all traces
                    if BBBpQ == 1
                        for BBBroi = 1:length(sortedBdata{1})
                            AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} = (nanmean(allBTraces{BBBroi}{terms(ccell)}{per}));
                        end 
                    end 
                    AVSNCdataPeaks2{terms(ccell)}{per} = nanmean(allCTraces{terms(ccell)}{per});
                    if VWpQ == 1
                        for VWroi = 1:length(sortedVdata{1})
                            AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} = (nanmean(allVTraces{VWroi}{terms(ccell)}{per}));
                        end 
                    end 

                    %remove traces that are outliers 
                    %statistically (greater than 2 standard deviations from the
                    %mean 
                    count2 = 1; 
                    count3 = 1;
                    count4 = 1;
                    for peak = 1:size(allCTraces{terms(ccell)}{per},1)
        %                     if allCTraces{terms(ccell)}(peak,:) < AVSNCdataPeaks2{terms(ccell)} + nanstd(allCTraces{terms(ccell)},1)*2 & allCTraces{terms(ccell)}(peak,:) > AVSNCdataPeaks2{terms(ccell)} - nanstd(allCTraces{terms(ccell)},1)*2                     
                        CTraces{terms(ccell)}{per}(count3,:) = (allCTraces{terms(ccell)}{per}(peak,:));
                        count3 = count3 + 1;
        %                     end               
                    end 
                    %remove rows full of zeros if there are any b = a(any(a,2),:)
                    CTraces{terms(ccell)}{per} = CTraces{terms(ccell)}{per}(any(CTraces{terms(ccell)}{per},2),:);
                    if BBBpQ == 1
                        for BBBroi = 1:length(sortedBdata{1})
                            for peak = 1:size(allBTraces{BBBroi}{terms(ccell)}{per},1)
            %                         if allBTraces{BBBroi}{terms(ccell)}(peak,:) < AVSNBdataPeaks2{BBBroi}{terms(ccell)} + nanstd(allBTraces{BBBroi}{terms(ccell)},1)*2  & allBTraces{BBBroi}{terms(ccell)}(peak,:) > AVSNBdataPeaks2{BBBroi}{terms(ccell)} - nanstd(allBTraces{BBBroi}{terms(ccell)},1)*2               
                                        BTraces{BBBroi}{terms(ccell)}{per}(count2,:) = (allBTraces{BBBroi}{terms(ccell)}{per}(peak,:));
                                        count2 = count2 + 1;
    %                                  end 
                            end 
                            %remove rows full of zeros if there are any b = a(any(a,2),:)
                            BTraces{BBBroi}{terms(ccell)}{per} = BTraces{BBBroi}{terms(ccell)}{per}(any(BTraces{BBBroi}{terms(ccell)}{per},2),:);
                        end 
                    end 
                    if VWpQ == 1
                        for VWroi = 1:length(sortedVdata{1})
                            for peak = 1:size(allVTraces{VWroi}{terms(ccell)}{per},1)
            %                         if allVTraces{VWroi}{terms(ccell)}(peak,:) < AVSNVdataPeaks2{VWroi}{terms(ccell)} + nanstd(allVTraces{VWroi}{terms(ccell)},1)*2 & allVTraces{VWroi}{terms(ccell)}(peak,:) > AVSNVdataPeaks2{VWroi}{terms(ccell)} - nanstd(allVTraces{VWroi}{terms(ccell)},1)*2              
                                        VTraces{VWroi}{terms(ccell)}{per}(count4,:) = (allVTraces{VWroi}{terms(ccell)}{per}(peak,:));
                                        count4 = count4 + 1;
            %                         end 
                            end 
                            %remove rows full of zeros if there are any b = a(any(a,2),:)
                            VTraces{VWroi}{terms(ccell)}{per} = VTraces{VWroi}{terms(ccell)}{per}(any(VTraces{VWroi}{terms(ccell)}{per},2),:);
                        end 
                    end 


                    %DETERMINE 95% CI
                    if BBBpQ == 1
                        CI_bLow = cell(1,length(sortedBdata{1}));
                        CI_bHigh = cell(1,length(sortedBdata{1}));
                        for BBBroi = 1:length(sortedBdata{1})
                            SEMb = (nanstd(BTraces{BBBroi}{terms(ccell)}{per}))/(sqrt(size(BTraces{BBBroi}{terms(ccell)}{per},1))); % Standard Error            
                            ts_bLow = tinv(0.025,size(BTraces{BBBroi}{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                            ts_bHigh = tinv(0.975,size(BTraces{BBBroi}{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                            CI_bLow{BBBroi} = (nanmean(BTraces{BBBroi}{terms(ccell)}{per},1)) + (ts_bLow*SEMb);  % Confidence Intervals
                            CI_bHigh{BBBroi} = (nanmean(BTraces{BBBroi}{terms(ccell)}{per},1)) + (ts_bHigh*SEMb);  % Confidence Intervals
                        end 
                    end 

                    SEMc = (nanstd(CTraces{terms(ccell)}{per}))/(sqrt(size(CTraces{terms(ccell)}{per},1))); % Standard Error            
                    ts_cLow = tinv(0.025,size(CTraces{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                    ts_cHigh = tinv(0.975,size(CTraces{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                    CI_cLow = (nanmean(CTraces{terms(ccell)}{per},1)) + (ts_cLow*SEMc);  % Confidence Intervals
                    CI_cHigh = (nanmean(CTraces{terms(ccell)}{per},1)) + (ts_cHigh*SEMc);  % Confidence Intervals

                    if VWpQ == 1
                        CI_vLow = cell(1,length(sortedVdata{1}));
                        CI_vHigh = cell(1,length(sortedVdata{1}));
                        for VWroi = 1:length(sortedVdata{1})
                            SEMv = (nanstd(VTraces{VWroi}{terms(ccell)}{per}))/(sqrt(size(VTraces{VWroi}{terms(ccell)}{per},1))); % Standard Error            
                            ts_vLow = tinv(0.025,size(VTraces{VWroi}{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                            ts_vHigh = tinv(0.975,size(VTraces{VWroi}{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                            CI_vLow{VWroi} = (nanmean(VTraces{VWroi}{terms(ccell)}{per},1)) + (ts_vLow*SEMv);  % Confidence Intervals
                            CI_vHigh{VWroi} = (nanmean(VTraces{VWroi}{terms(ccell)}{per},1)) + (ts_vHigh*SEMv);  % Confidence Intervals
                        end 
                    end 

                    x = 1:length(CI_cLow);

                    %get averages of traces excluding outliers  
                    if BBBpQ == 1
                        for BBBroi = 1:length(sortedBdata{1})
                            AVSNBdataPeaks{BBBroi}{terms(ccell)}{per} = (nanmean(BTraces{BBBroi}{terms(ccell)}{per}));
                        end 
                    end 
                    AVSNCdataPeaks{terms(ccell)}{per} = nanmean(CTraces{terms(ccell)}{per});
                    if VWpQ == 1
                        for VWroi = 1:length(sortedVdata{1})
                            AVSNVdataPeaks{VWroi}{terms(ccell)}{per} = (nanmean(VTraces{VWroi}{terms(ccell)}{per}));
                        end 
                    end 
                    % plot 
                    plot(AVSNCdataPeaks{terms(ccell)}{per},'b','LineWidth',4)
        %             plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
                    ax.XTick = FrameVals;
                    ax.XTickLabel = sec_TimeVals;   
                    ax.FontSize = 25;
                    ax.FontName = 'Times';
                    xlabel('time (s)','FontName','Times')
                    ylabel('calcium signal percent change','FontName','Times')
                    xLimStart = floor(10*FPSstack);
                    xLimEnd = floor(24*FPSstack); 
                    xlim([1 size(AVSNCdataPeaks{terms(ccell)}{per},2)])
                    ylim([-60 100])
                    patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],[0 0 0.5],'EdgeColor','none')            
                    set(fig,'position', [500 100 900 800])
                    alpha(0.3)
                    if per == 1 
                        perLabel = ("Peaks from entire experiment. ");
                    elseif per == 2 
                        perLabel = ("Peaks from stimulus. ");
                    elseif per == 3 
                        perLabel = ("Peaks peaks from reward. ");
                    elseif per == 4 
                        perLabel = ("Peaks from ITI. ");
                    end 
                    %add right y axis tick marks for a specific DOD figure. 
                    yyaxis right 
                    if BBBpQ == 1
                        plot(AVSNBdataPeaks{BBBROI}{terms(ccell)}{per},'r','LineWidth',4)
                        patch([x fliplr(x)],[(CI_bLow{BBBROI}) (fliplr(CI_bHigh{BBBROI}))],[0.5 0 0],'EdgeColor','none')
                        ylabel('BBB permeability percent change','FontName','Times')
                        tlabel = sprintf('Terminal%d_BBBroi%d.',terms(ccell),BBBROI);
    %                     perLabel = 
                        title({sprintf('Terminal %d. BBB ROI %d.',terms(ccell),BBBROI);perLabel})
            %             title('BBB permeability Spike Triggered Average')
                    end 
                    if VWpQ == 1
                        plot(AVSNVdataPeaks{VWROI}{terms(ccell)}{per},'k','LineWidth',4)
                        patch([x fliplr(x)],[(CI_vLow{VWROI}) (fliplr(CI_vHigh{VWROI}))],'k','EdgeColor','none')
                        ylabel('Vessel width percent change','FontName','Times')
                        tlabel = ({sprintf('Terminal%d_VwidthROI%d.',terms(ccell),VWROI);perLabel});
            %             title(sprintf('Terminal %d. Vessel width ROI %d.',terminals(ccell),VWroi))
                        title({sprintf('Terminal %d. VW ROI %d.',terms(ccell),VWROI),perLabel})
                    end 
                    alpha(0.3)
                    set(gca,'YColor',[0 0 0]);
                    %make the directory and save the images   
                    if saveQ == 1  
                        dir2 = strrep(dir1,'\','/');
                        dir3 = sprintf('%s/%s.tif',dir2,tlabel);
                        export_fig(dir3)
                    end
                end 
            end 
        end
        
    elseif AVQ == 1 % average across calcium ROIs 
        for ccell = 1:length(terms) 
            if isempty(SNCdataPeaks{vid}{terms(ccell)}) == 0 
                for per = 1:length(sortedCdata{vid}{terminals(ccell)})
                    if isempty(SNCdataPeaks{vid}{terms(ccell)}{per}) == 0 
                        count = 1;
                        % sort data 
                        for vid = 1:length(vidList)   
                            if isempty(SNCdataPeaks{vid}{terms(ccell)}) == 0 
                                for peak = 1:size(SNCdataPeaks{vid}{terms(ccell)}{per},1) 
                                    if BBBpQ == 1
                                        for BBBroi = 1:length(sortedBdata{1})
                                            allBTraces{BBBroi}{terms(ccell)}{per}(count,:) = (SNBdataPeaks{vid}{BBBroi}{terms(ccell)}{per}(peak,:)-100); 
                                            %remove rows full of zeros if there are any b = a(any(a,2),:)
                                            allBTraces{BBBroi}{terms(ccell)}{per} = allBTraces{BBBroi}{terms(ccell)}{per}(any(allBTraces{BBBroi}{terms(ccell)}{per},2),:);
                                        end 
                                    end 
                                    if VWpQ == 1
                                        for VWroi = 1:length(sortedVdata{1})
                                            allVTraces{VWroi}{terms(ccell)}{per}(count,:) = (SNVdataPeaks{vid}{VWroi}{terms(ccell)}{per}(peak,:)-100); 
                                            %remove rows full of zeros if there are any b = a(any(a,2),:)
                                            allVTraces{VWroi}{terms(ccell)}{per} = allVTraces{VWroi}{terms(ccell)}{per}(any(allVTraces{VWroi}{terms(ccell)}{per},2),:);
                                        end 
                                    end 
                                    allCTraces{terms(ccell)}{per}(count,:) = (SNCdataPeaks{vid}{terms(ccell)}{per}(peak,:)-100);
                                    %remove rows full of zeros if there are any b = a(any(a,2),:)
                                    allCTraces{terms(ccell)}{per} = allCTraces{terms(ccell)}{per}(any(allCTraces{terms(ccell)}{per},2),:);
                                    count = count + 1;
                                end 
                            end 
                        end 

                        %get averages of all traces 
                        if BBBpQ == 1
                            for BBBroi = 1:length(sortedBdata{1})
                                AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} = (nanmean(allBTraces{BBBroi}{terms(ccell)}{per}));
                            end 
                        end 
                        AVSNCdataPeaks2{terms(ccell)}{per} = nanmean(allCTraces{terms(ccell)}{per});
                        if VWpQ == 1
                            for VWroi = 1:length(sortedVdata{1})
                                AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} = (nanmean(allVTraces{VWroi}{terms(ccell)}{per}));
                            end 
                        end 

                        %remove traces that are outliers 
                        %statistically (greater than 2 standard deviations from the
                        %mean 
                        count2 = 1; 
                        count3 = 1;
                        count4 = 1;
                        for peak = 1:size(allCTraces{terms(ccell)}{per},1)
                                if BBBpQ == 1
                                    for BBBroi = 1:length(sortedBdata{1})
            %                         if allBTraces{BBBroi}{terms(ccell)}(peak,:) < AVSNBdataPeaks2{BBBroi}{terms(ccell)} + nanstd(allBTraces{BBBroi}{terms(ccell)},1)*2  & allBTraces{BBBroi}{terms(ccell)}(peak,:) > AVSNBdataPeaks2{BBBroi}{terms(ccell)} - nanstd(allBTraces{BBBroi}{terms(ccell)},1)*2               
                                        BTraces{BBBroi}{terms(ccell)}{per}(count2,:) = (allBTraces{BBBroi}{terms(ccell)}{per}(peak,:));
                                        count2 = count2 + 1;
            %                         end 
                                        %remove rows full of zeros if there are any b = a(any(a,2),:)
                                        BTraces{BBBroi}{terms(ccell)}{per} = BTraces{BBBroi}{terms(ccell)}{per}(any(BTraces{BBBroi}{terms(ccell)}{per},2),:);
                                    end 
                                end 
            %                     if allCTraces{terms(ccell)}(peak,:) < AVSNCdataPeaks2{terms(ccell)} + nanstd(allCTraces{terms(ccell)},1)*2 & allCTraces{terms(ccell)}(peak,:) > AVSNCdataPeaks2{terms(ccell)} - nanstd(allCTraces{terms(ccell)},1)*2                      
                                    CTraces{terms(ccell)}{per}(count3,:) = (allCTraces{terms(ccell)}{per}(peak,:));
                                    count3 = count3 + 1;
                                    %remove rows full of zeros if there are any b = a(any(a,2),:)
                                    CTraces{terms(ccell)}{per} = CTraces{terms(ccell)}{per}(any(CTraces{terms(ccell)}{per},2),:);
            %                     end 
                                if VWpQ == 1
                                    for VWroi = 1:length(sortedVdata{1})
            %                         if allVTraces{VWroi}{terms(ccell)}(peak,:) < AVSNVdataPeaks2{VWroi}{terms(ccell)} + nanstd(allVTraces{VWroi}{terms(ccell)},1)*2 & allVTraces{VWroi}{terms(ccell)}(peak,:) > AVSNVdataPeaks2{VWroi}{terms(ccell)} - nanstd(allVTraces{VWroi}{terms(ccell)},1)*2              
                                        VTraces{VWroi}{terms(ccell)}{per}(count4,:) = (allVTraces{VWroi}{terms(ccell)}{per}(peak,:));
                                        count4 = count4 + 1;
            %                         end 
                                        %remove rows full of zeros if there are any b = a(any(a,2),:)
                                        VTraces{VWroi}{terms(ccell)}{per} = VTraces{VWroi}{terms(ccell)}{per}(any(VTraces{VWroi}{terms(ccell)}{per},2),:);
                                    end 
                                end 
                        end 

                        % get the average of all the traces excluding outliers 
                        if BBBpQ == 1
                            for BBBroi = 1:length(sortedBdata{1})
                                AVSNBdataPeaks3{BBBroi}{per}(ccell,:) = (nanmean(BTraces{BBBroi}{terms(ccell)}{per}));
                            end 
                        end 
                        AVSNCdataPeaks3{per}(ccell,:) = nanmean(CTraces{terms(ccell)}{per});
                        if VWpQ == 1
                            for VWroi = 1:length(sortedVdata{1})
                                AVSNVdataPeaks3{VWroi}{per}(ccell,:) = (nanmean(VTraces{VWroi}{terms(ccell)}{per}));
                            end 
                        end   
                    end 
                end 
            end 
        end       
        for per = 1:length(sortedCdata{1}{terminals(1)})
            if isempty(SNCdataPeaks{1}{terms(1)}{per}) == 0 
                fig = figure;
                Frames = size(AVSNCdataPeaks3{per},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack))+1;
                FrameVals = round((1:FPSstack:Frames))+5; 
                ax=gca;
                hold all

                %DETERMINE 95% CI
                if BBBpQ == 1
                    for BBBroi = 1:length(sortedBdata{1})
                        SEMb = (nanstd(AVSNBdataPeaks3{BBBroi}{per})/(sqrt(size(AVSNBdataPeaks3{BBBroi}{per},1)))); % Standard Error            
                        ts_bLow = tinv(0.025,size(AVSNBdataPeaks3{BBBroi}{per},1)-1);% T-Score for 95% CI
                        ts_bHigh = tinv(0.975,size(AVSNBdataPeaks3{BBBroi}{per},1)-1);% T-Score for 95% CI
                        CI_bLow = (nanmean(AVSNBdataPeaks3{BBBroi}{per},1)) + (ts_bLow*SEMb);  % Confidence Intervals
                        CI_bHigh = (nanmean(AVSNBdataPeaks3{BBBroi}{per},1)) + (ts_bHigh*SEMb);  % Confidence Intervals
                    end 
                end 

                SEMc = (nanstd(AVSNCdataPeaks3{per}))/(sqrt(size(AVSNCdataPeaks3{per},1))); % Standard Error            
                ts_cLow = tinv(0.025,size(AVSNCdataPeaks3{per},1)-1);% T-Score for 95% CI
                ts_cHigh = tinv(0.975,size(AVSNCdataPeaks3{per},1)-1);% T-Score for 95% CI
                CI_cLow = (nanmean(AVSNCdataPeaks3{per},1)) + (ts_cLow*SEMc);  % Confidence Intervals
                CI_cHigh = (nanmean(AVSNCdataPeaks3{per},1)) + (ts_cHigh*SEMc);  % Confidence Intervals

                if VWpQ == 1
                    for VWroi = 1:length(sortedVdata{1})
                        SEMv = (nanstd(AVSNVdataPeaks3{VWroi}{per}))/(sqrt(size(AVSNVdataPeaks3{VWroi}{per},1))); % Standard Error            
                        ts_vLow = tinv(0.025,size(AVSNVdataPeaks3{VWroi}{per},1)-1);% T-Score for 95% CI
                        ts_vHigh = tinv(0.975,size(AVSNVdataPeaks3{VWroi}{per},1)-1);% T-Score for 95% CI
                        CI_vLow = (nanmean(AVSNVdataPeaks3{VWroi}{per},1)) + (ts_vLow*SEMv);  % Confidence Intervals
                        CI_vHigh = (nanmean(AVSNVdataPeaks3{VWroi}{per},1)) + (ts_vHigh*SEMv);  % Confidence Intervals
                    end 
                end 

                x = 1:length(CI_cLow);

                %average across terminals 
                AVSNCdataPeaks{per} = nanmean(AVSNCdataPeaks3{per});
                if BBBpQ == 1
                    for BBBroi = 1:length(sortedBdata{1})
                        AVSNBdataPeaks{BBBroi}{per} = nanmean(AVSNBdataPeaks3{BBBroi}{per});
                    end 
                end 
                if VWpQ == 1
                    for VWroi = 1:length(sortedVdata{1})
                        AVSNVdataPeaks{VWroi}{per} = nanmean(AVSNVdataPeaks3{VWroi}{per});
                    end 
                end 

                % plot 
                plot(AVSNCdataPeaks{per},'b','LineWidth',4)
        %         plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
                ax.XTick = FrameVals;
                ax.XTickLabel = sec_TimeVals;   
                ax.FontSize = 25;
                ax.FontName = 'Times';
                xlabel('time (s)','FontName','Times')
                ylabel('calcium signal percent change','FontName','Times')
                xLimStart = floor(10*FPSstack);
                xLimEnd = floor(24*FPSstack); 
                xlim([1 size(AVSNCdataPeaks{per},2)])
                ylim([-60 100])
                patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],[0 0 0.5],'EdgeColor','none')
                set(fig,'position', [500 100 900 800])
                alpha(0.3)
                if per == 1 
                    perLabel = ("Peaks from entire experiment. ");
                elseif per == 2 
                    perLabel = ("Peaks from stimulus. ");
                elseif per == 3 
                    perLabel = ("Peaks peaks from reward. ");
                elseif per == 4 
                    perLabel = ("Peaks from ITI. ");
                end 
                %add right y axis tick marks for a specific DOD figure. 
                yyaxis right 
                if BBBpQ == 1
                    plot(AVSNBdataPeaks{BBBROI}{per},'r','LineWidth',4)
                    patch([x fliplr(x)],[(CI_bLow) (fliplr(CI_bHigh))],[0.5 0 0],'EdgeColor','none')
                    ylabel('BBB permeability percent change','FontName','Times')
                    title({sprintf('All Terminals Averaged. BBB ROI %d.',BBBROI);perLabel})
        %             title('BBB permeability Spike Triggered Average')
                end 
                if VWpQ == 1
                    plot(AVSNVdataPeaks{VWROI}{per},'k','LineWidth',4)
                    patch([x fliplr(x)],[(CI_vLow) (fliplr(CI_vHigh))],'k','EdgeColor','none')
                    ylabel('Vessel width percent change','FontName','Times')
        %             title(sprintf('Terminal %d. Vessel width ROI %d.',terminals(ccell),VWroi))
                    title({sprintf('All Terminals Averaged. VW ROI %d.',VWROI);perLabel})
                end 
                alpha(0.3)
                set(gca,'YColor',[0 0 0]);
                %make the directory and save the images   
                if saveQ == 1  
                    dir2 = strrep(dir1,'\','/');
                    dir3 = sprintf('%s/%s.tif',dir2,tlabel);
                    export_fig(dir3)
                end   
            end 
        end 
    end 
    %}
elseif tTypeQ == 1
    %{
    if AVQ == 0 
        for ccell = 1:length(terms)       
            for per = 2:3 
                % plot    
                fig = figure; 
                Frames = size(SNBdataPeaks{1}{BBBroi}{terms(ccell)}{3},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack))+1;
                FrameVals = round((1:FPSstack:Frames)+5); 
                ax=gca;
                hold all
                count = 1;
                for vid = 1:length(vidList)
                       if length(sortedBdata{vid}{BBBroi}{terms(ccell)}) >= per  
                            if isempty(sortedBdata{vid}{BBBroi}{terms(ccell)}{per}) == 0 
                                for peak = 1:size(sortedBdata{vid}{BBBroi}{terms(ccell)}{per},1)
                                    if peak <= size(SNBdataPeaks{vid}{BBBroi}{terms(ccell)}{per},1)
                                        if BBBQ == 1
                                            for BBBroi = 1:length(sortedBdata{1})
                                                allBTraces{BBBroi}{terms(ccell)}{per}(count,:) = (SNBdataPeaks{vid}{BBBroi}{terms(ccell)}{per}(peak,:)-100);
                                                %remove rows full of 0s if there are any b = a(any(a,2),:)
                                                allBTraces{BBBroi}{terms(ccell)}{per} = allBTraces{BBBroi}{terms(ccell)}{per}(any(allBTraces{BBBroi}{terms(ccell)}{per},2),:);
                                            end 
                                        end 
                                        allCTraces{terms(ccell)}{per}(count,:) = (SNCdataPeaks{vid}{terms(ccell)}{per}(peak,:)-100);
                                        %remove rows full of 0s if there are any b = a(any(a,2),:)
                                        allCTraces{terms(ccell)}{per} = allCTraces{terms(ccell)}{per}(any(allCTraces{terms(ccell)}{per},2),:);
                                        if VWQ == 1
                                            for VWroi = 1:length(sortedVdata{1})
                                                allVTraces{VWroi}{terms(ccell)}{per}(count,:) = (SNVdataPeaks{vid}{VWroi}{terms(ccell)}{per}(peak,:)-100); 
                                                %remove rows full of 0s if there are any b = a(any(a,2),:)
                                                allVTraces{VWroi}{terms(ccell)}{per} = allVTraces{VWroi}{terms(ccell)}{per}(any(allVTraces{VWroi}{terms(ccell)}{per},2),:);
                                            end 
                                        end 
                                        count = count + 1;
                                    end 
                                end 
                            end
                       end               
                end 

                %get averages of all traces 
                if BBBQ == 1
                    for BBBroi = 1:length(sortedBdata{1})
                        AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} = nanmean(allBTraces{BBBroi}{terms(ccell)}{per},1);
                    end 
                end 
                AVSNCdataPeaks2{terms(ccell)}{per} = nanmean(allCTraces{terms(ccell)}{per},1);
                if VWQ == 1
                    for VWroi = 1:length(sortedVdata{1})
                        AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} = nanmean(allVTraces{VWroi}{terms(ccell)}{per},1);
                    end 
                end 

                %remove traces that are outliers 
                %statistically (greater than 2 standard deviations from the
                %mean 
                count2 = 1; 
                count3 = 1;
                count4 = 1;
                for peak = 1:size(allCTraces{terms(ccell)}{per},1)
    %                     if allCTraces{terms(ccell)}{per}(peak,:) < AVSNCdataPeaks2{terms(ccell)}{per} + nanstd(allCTraces{terms(ccell)}{per},1)*2 & allCTraces{terms(ccell)}{per}(peak,:) > AVSNCdataPeaks2{terms(ccell)}{per} - nanstd(allCTraces{terms(ccell)}{per},1)*2                     
                            CTraces{terms(ccell)}{per}(count3,:) = (allCTraces{terms(ccell)}{per}(peak,:));
                            count3 = count3 + 1;
    %                     end -
                end 
                %remove rows full of zeros if there are any b = a(any(a,2),:)
                CTraces{terms(ccell)}{per} = CTraces{terms(ccell)}{per}(any(CTraces{terms(ccell)}{per},2),:);
                if BBBQ == 1
                    for BBBroi = 1:length(sortedBdata{1})
                        for peak = 1:size(allBTraces{BBBroi}{terms(ccell)}{per},1)
        %                     if allBTraces{BBBroi}{terms(ccell)}{per}(peak,:) < AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} + nanstd(allBTraces{BBBroi}{terms(ccell)}{per},1)*2  & allBTraces{BBBroi}{terms(ccell)}{per}(peak,:) > AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} - nanstd(allBTraces{BBBroi}{terms(ccell)}{per},1)*2               
                                BTraces{BBBroi}{terms(ccell)}{per}(count2,:) = (allBTraces{BBBroi}{terms(ccell)}{per}(peak,:));
                                count2 = count2 + 1;
        %                     end 
                        end 
                        %remove rows full of zeros if there are any b = a(any(a,2),:)
                         BTraces{BBBroi}{terms(ccell)}{per} =  BTraces{BBBroi}{terms(ccell)}{per}(any(BTraces{BBBroi}{terms(ccell)}{per},2),:);
                    end 
                end 
                if VWQ == 1
                    for VWroi = 1:length(sortedVdata{1})
                        for peak = 1:size(allVTraces{VWroi}{terms(ccell)}{per},1)
        %                     if allVTraces{VWroi}{terms(ccell)}{per}(peak,:) < AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} + nanstd(allVTraces{VWroi}{terms(ccell)}{per},1)*2 & allVTraces{VWroi}{terms(ccell)}{per}(peak,:) > AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} - nanstd(allVTraces{VWroi}{terms(ccell)}{per},1)*2              
                                VTraces{VWroi}{terms(ccell)}{per}(count4,:) = (allVTraces{VWroi}{terms(ccell)}{per}(peak,:));
                                count4 = count4 + 1;
        %                     end 
                        end 
                        %remove rows full of zeros if there are any b = a(any(a,2),:)
                        VTraces{VWroi}{terms(ccell)}{per} = VTraces{VWroi}{terms(ccell)}{per}(any(VTraces{VWroi}{terms(ccell)}{per},2),:);
                    end 
                end 

                %calculate the 95% confidence interval
                if BBBQ == 1
                    CI_bLow = cell(1,length(sortedBdata{1}));
                    CI_bHigh = cell(1,length(sortedBdata{1}));
                    for BBBroi = 1:length(sortedBdata{1})
                        SEMb = (nanstd(BTraces{BBBroi}{terms(ccell)}{per}))/(sqrt(size(BTraces{BBBroi}{terms(ccell)}{per},1))); % Standard Error            
                        ts_bLow = tinv(0.025,size(BTraces{BBBroi}{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                        ts_bHigh = tinv(0.975,size(BTraces{BBBroi}{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                        CI_bLow{BBBroi} = (nanmean(BTraces{BBBroi}{terms(ccell)}{per},1)) + (ts_bLow*SEMb);  % Confidence Intervals
                        CI_bHigh{BBBroi} = (nanmean(BTraces{BBBroi}{terms(ccell)}{per},1)) + (ts_bHigh*SEMb);  % Confidence Intervals
                    end 
                end 

                SEMc = (nanstd(CTraces{terms(ccell)}{per}))/(sqrt(size(CTraces{terms(ccell)}{per},1))); % Standard Error            
                ts_cLow = tinv(0.025,size(CTraces{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                ts_cHigh = tinv(0.975,size(CTraces{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                CI_cLow = (nanmean(CTraces{terms(ccell)}{per},1)) + (ts_cLow*SEMc);  % Confidence Intervals
                CI_cHigh = (nanmean(CTraces{terms(ccell)}{per},1)) + (ts_cHigh*SEMc);  % Confidence Intervals

                if VWQ == 1
                    CI_vLow = cell(1,length(sortedVdata{1}));
                    CI_vHigh = cell(1,length(sortedVdata{1}));
                    for VWroi = 1:length(sortedVdata{1})
                        SEMv = (nanstd(VTraces{VWroi}{terms(ccell)}{per}))/(sqrt(size(VTraces{VWroi}{terms(ccell)}{per},1))); % Standard Error            
                        ts_vLow = tinv(0.025,size(VTraces{VWroi}{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                        ts_vHigh = tinv(0.975,size(VTraces{VWroi}{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                        CI_vLow{VWroi} = (nanmean(VTraces{VWroi}{terms(ccell)}{per},1)) + (ts_vLow*SEMv);  % Confidence Intervals
                        CI_vHigh{VWroi} = (nanmean(VTraces{VWroi}{terms(ccell)}{per},1)) + (ts_vHigh*SEMv);  % Confidence Intervals     
                    end 
                end 
                x = 1:length(CI_cLow);

                %get averages
                if BBBQ == 1
                    for BBBroi = 1:length(sortedBdata{1})
                        AVSNBdataPeaks{BBBroi}{terms(ccell)}{per} = nanmean(BTraces{BBBroi}{terms(ccell)}{per},1);
                    end 
                end 
                AVSNCdataPeaks{terms(ccell)}{per} = nanmean(CTraces{terms(ccell)}{per},1);
                if VWQ == 1
                    for VWroi = 1:length(sortedVdata{1})
                        AVSNVdataPeaks{VWroi}{terms(ccell)}{per} = nanmean(VTraces{VWroi}{terms(ccell)}{per},1);
                    end     
                end 

                if isempty(AVSNCdataPeaks{terms(ccell)}{per}) == 0 
                    plot(AVSNCdataPeaks{terms(ccell)}{per},'b','LineWidth',4)
                end 
    %             plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
                ax.XTick = FrameVals;
                ax.XTickLabel = sec_TimeVals;   
                ax.FontSize = 25;
                ax.FontName = 'Times';
                xlabel('time (s)','FontName','Times')
                ylabel('calcium signal percent change','FontName','Times')
                xLimStart = floor(10*FPSstack);
                xLimEnd = floor(24*FPSstack); 
                if isempty(AVSNCdataPeaks{terms(ccell)}{per}) == 0 
                    xlim([1 size(AVSNCdataPeaks{terms(ccell)}{per},2)])
                end 
                ylim([-60 100])

                patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],[0 0 0.5],'EdgeColor','none')
                set(fig,'position', [500 100 900 800])
                alpha(0.3)
                
                if per == 1 
                    perLabel = "Blue Light On";
                elseif per == 2
                    perLabel = "Red Light On";
                elseif per == 3
                    perLabel = "Light Off";
                end 

                %add right y axis tick marks for a specific DOD figure. 
                yyaxis right 
                if BBBpQ == 1
                    if isempty(AVSNBdataPeaks{BBBROI}{terms(ccell)}{per}) == 0 && isempty(CI_cLow) == 0 
                        plot(AVSNBdataPeaks{BBBROI}{terms(ccell)}{per},'r','LineWidth',4)
                        patch([x fliplr(x)],[(CI_bLow{BBBROI}) (fliplr(CI_bHigh{BBBROI}))],[0.5 0 0],'EdgeColor','none')
                        ylabel('BBB permeability percent change','FontName','Times')
                        tlabel = sprintf('Terminal%d_BBBroi%d.',terms(ccell),BBBROI);
                        title({sprintf('Terminal %d. BBB ROI %d.',terms(ccell),BBBROI);perLabel})
            %             title('BBB permeability Spike Triggered Average')
                    end 
                end 
                if VWpQ == 1
                    if isempty(AVSNVdataPeaks{VWROI}{terms(ccell)}{per}) == 0 && isempty(CI_cLow) == 0 
                        plot(AVSNVdataPeaks{VWROI}{terms(ccell)}{per},'k','LineWidth',4)
                        patch([x fliplr(x)],[(CI_vLow{VWROI}) (fliplr(CI_vHigh{VWROI}))],'k','EdgeColor','none')
                        ylabel('Vessel width percent change','FontName','Times')
                        tlabel = sprintf('Terminal%d_VwidthROI%d.',terms(ccell),VWROI);
            %             title(sprintf('Terminal %d. Vessel width ROI %d.',terminals(ccell),VWroi))
                        title({sprintf('Terminal %d. VW ROI %d.',terms(ccell),VWROI);perLabel})
                    end 
                end 
                alpha(0.3)
                set(gca,'YColor',[0 0 0]);
                %make the directory and save the images   
                if saveQ == 1  
                    dir2 = strrep(dir1,'\','/');
                    dir3 = sprintf('%s/%s.tif',dir2,tlabel);
                    export_fig(dir3)
                end        
            end 
        end 
    elseif AVQ == 1 
        % sort data
        for ccell = 1:length(terms)
            AVSNCdataPeaks3 = cell(1,3);
            for per = 2:3
                count = 1;
                for vid = 1:length(vidList)
                   if length(sortedBdata{vid}{BBBroi}{terms(ccell)}) >= per  
                        if isempty(sortedBdata{vid}{BBBroi}{terms(ccell)}{per}) == 0 
                            for peak = 1:size(SNBdataPeaks{vid}{BBBroi}{terms(ccell)}{per},1)
                                if BBBQ == 1
                                    for BBBroi = 1:length(sortedBdata{1})
                                        allBTraces{BBBroi}{terms(ccell)}{per}(count,:) = (SNBdataPeaks{vid}{BBBroi}{terms(ccell)}{per}(peak,:)-100);
                                        %remove rows full of zeros if there are any b = a(any(a,2),:)
                                        allBTraces{BBBroi}{terms(ccell)}{per} = allBTraces{BBBroi}{terms(ccell)}{per}(any(allBTraces{BBBroi}{terms(ccell)}{per},2),:);
                                    end 
                                end 
                                allCTraces{terms(ccell)}{per}(count,:) = (SNCdataPeaks{vid}{terms(ccell)}{per}(peak,:)-100);
                                %remove rows full of zeros if there are any b = a(any(a,2),:)
                                allCTraces{terms(ccell)}{per} = allCTraces{terms(ccell)}{per}(any(allCTraces{terms(ccell)}{per},2),:);
                                if VWQ == 1
                                    for VWroi = 1:length(sortedVdata{1})
                                        allVTraces{VWroi}{terms(ccell)}{per}(count,:) = (SNVdataPeaks{vid}{VWroi}{terms(ccell)}{per}(peak,:)-100);
                                        %remove rows full of zeros if there are any b = a(any(a,2),:)
                                        allVTraces{VWroi}{terms(ccell)}{per} = allVTraces{VWroi}{terms(ccell)}{per}(any(allVTraces{VWroi}{terms(ccell)}{per},2),:);
                                    end 
                                end 
                                count = count + 1;
                            end 
                        end
                   end               
                end 

                %get average of all traces 
                if BBBQ == 1
                    for BBBroi = 1:length(sortedBdata{1})
                        AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} = nanmean(allBTraces{BBBroi}{terms(ccell)}{per},1);
                    end 
                end 
                AVSNCdataPeaks2{terms(ccell)}{per} = nanmean(allCTraces{terms(ccell)}{per},1);
                if VWQ == 1
                    for VWroi = 1:length(sortedVdata{1})
                        AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} = nanmean(allVTraces{VWroi}{terms(ccell)}{per},1);
                    end 
                end 

                %remove traces that are outliers 
                %statistically (greater than 2 standard deviations from the
                %mean )
                count2 = 1; 
                count3 = 1;
                count4 = 1;
                for peak = 1:size(allCTraces{terms(ccell)}{per},1)
                        if BBBQ == 1
                            for BBBroi = 1:length(sortedBdata{1})
    %                         if allBTraces{BBBroi}{terms(ccell)}{per}(peak,:) < AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} + nanstd(allBTraces{BBBroi}{terms(ccell)}{per},1)*2  & allBTraces{BBBroi}{terms(ccell)}{per}(peak,:) > AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} - nanstd(allBTraces{BBBroi}{terms(ccell)}{per},1)*2               
                                BTraces{BBBroi}{terms(ccell)}{per}(count2,:) = (allBTraces{BBBroi}{terms(ccell)}{per}(peak,:));
                                count2 = count2 + 1;
    %                         end 
                                %remove rows full of zeros if there are any b = a(any(a,2),:)
                                BTraces{BBBroi}{terms(ccell)}{per} = BTraces{BBBroi}{terms(ccell)}{per}(any(BTraces{BBBroi}{terms(ccell)}{per},2),:);
                            end 
                        end 
    %                     if allCTraces{terms(ccell)}{per}(peak,:) < AVSNCdataPeaks2{terms(ccell)}{per} + nanstd(allCTraces{terms(ccell)}{per},1)*2 & allCTraces{terms(ccell)}{per}(peak,:) > AVSNCdataPeaks2{terms(ccell)}{per} - nanstd(allCTraces{terms(ccell)}{per},1)*2                      
                            CTraces{terms(ccell)}{per}(count3,:) = (allCTraces{terms(ccell)}{per}(peak,:));
                            count3 = count3 + 1;
                            %remove rows full of zeros if there are any b = a(any(a,2),:)
                            CTraces{terms(ccell)}{per} = CTraces{terms(ccell)}{per}(any(CTraces{terms(ccell)}{per},2),:);
    %                     end 
                        if VWQ == 1
                            for VWroi = 1:length(sortedVdata{1})
    %                         if allVTraces{VWroi}{terms(ccell)}{per}(peak,:) < AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} + nanstd(allVTraces{VWroi}{terms(ccell)}{per},1)*2 & allVTraces{VWroi}{terms(ccell)}{per}(peak,:) > AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} - nanstd(allVTraces{VWroi}{terms(ccell)}{per},1)*2              
                                VTraces{VWroi}{terms(ccell)}{per}(count4,:) = (allVTraces{VWroi}{terms(ccell)}{per}(peak,:));
                                count4 = count4 + 1;
                                %remove rows full of zeros if there are any b = a(any(a,2),:)
                                VTraces{VWroi}{terms(ccell)}{per} = VTraces{VWroi}{terms(ccell)}{per}(any(VTraces{VWroi}{terms(ccell)}{per},2),:);
    %                         end 
                            end 
                        end 
                end 

                % get the average of all the traces excluding outliers 
                if BBBQ == 1 
                    for BBBroi = 1:length(sortedBdata{1})
                        AVSNBdataPeaks3{BBBroi}{per}(ccell,:) = (nanmean(BTraces{BBBroi}{terms(ccell)}{per}));
                    end 
                end 
                AVSNCdataPeaks3{per}(ccell,:) = nanmean(CTraces{terms(ccell)}{per});
                if VWQ == 1
                    for VWroi = 1:length(sortedVdata{1})
                        AVSNVdataPeaks3{VWroi}{per}(ccell,:) = (nanmean(VTraces{VWroi}{terms(ccell)}{per}));
                    end 
                end 
            end 
        end  
        for per = 2:3
            if per == 1 
                    perLabel = "Blue Light On";
                elseif per == 2
                    perLabel = "Red Light On";
                elseif per == 3
                    perLabel = "Light Off";
            end 
            %calculate the 95% confidence interval
            if BBBQ == 1
                CI_bLow = cell(1,length(sortedBdata{1}));
                CI_bHigh = cell(1,length(sortedBdata{1}));
                for BBBroi = 1:length(sortedBdata{1})
                    SEMb = (nanstd(AVSNBdataPeaks3{BBBroi}{per}))/(sqrt(size(AVSNBdataPeaks3{BBBroi}{per},1))); % Standard Error            
                    ts_bLow = tinv(0.025,size(AVSNBdataPeaks3{BBBroi}{per},1)-1);% T-Score for 95% CI
                    ts_bHigh = tinv(0.975,size(AVSNBdataPeaks3{BBBroi}{per},1)-1);% T-Score for 95% CI
                    CI_bLow{BBBroi} = (nanmean(AVSNBdataPeaks3{BBBroi}{per},1)) + (ts_bLow*SEMb);  % Confidence Intervals
                    CI_bHigh{BBBroi} = (nanmean(AVSNBdataPeaks3{BBBroi}{per},1)) + (ts_bHigh*SEMb);  % Confidence Intervals
                end 
            end 

            SEMc = (nanstd(AVSNCdataPeaks3{per}))/(sqrt(size(AVSNCdataPeaks3{per},1))); % Standard Error            
            ts_cLow = tinv(0.025,size(AVSNCdataPeaks3{per},1)-1);% T-Score for 95% CI
            ts_cHigh = tinv(0.975,size(AVSNCdataPeaks3{per},1)-1);% T-Score for 95% CI
            CI_cLow = (nanmean(AVSNCdataPeaks3{per},1)) + (ts_cLow*SEMc);  % Confidence Intervals
            CI_cHigh = (nanmean(AVSNCdataPeaks3{per},1)) + (ts_cHigh*SEMc);  % Confidence Intervals

            if VWQ == 1
                CI_vLow = cell(1,length(sortedVdata{1}));
                CI_vHigh = cell(1,length(sortedVdata{1}));
                for VWroi = 1:length(sortedVdata{1})
                    SEMv = (nanstd(AVSNVdataPeaks3{VWroi}{per}))/(sqrt(size(AVSNVdataPeaks3{VWroi}{per},1))); % Standard Error            
                    ts_vLow = tinv(0.025,size(AVSNVdataPeaks3{VWroi}{per},1)-1);% T-Score for 95% CI
                    ts_vHigh = tinv(0.975,size(AVSNVdataPeaks3{VWroi}{per},1)-1);% T-Score for 95% CI
                    CI_vLow{VWroi} = (nanmean(AVSNVdataPeaks3{VWroi}{per},1)) + (ts_vLow*SEMv);  % Confidence Intervals
                    CI_vHigh{VWroi} = (nanmean(AVSNVdataPeaks3{VWroi}{per},1)) + (ts_vHigh*SEMv);  % Confidence Intervals
                end 
            end 
            x = 1:length(CI_cLow);

            %average across terminals 
            AVSNCdataPeaks{per} = nanmean(AVSNCdataPeaks3{per});
            if BBBQ == 1
                for BBBroi = 1:length(sortedBdata{1})
                    AVSNBdataPeaks{BBBroi}{per} = nanmean(AVSNBdataPeaks3{BBBroi}{per});
                end 
            end 
            if VWQ == 1
                for VWroi = 1:length(sortedVdata{1})
                    AVSNVdataPeaks{VWroi}{per} = nanmean(AVSNVdataPeaks3{VWroi}{per});
                end 
            end 

            % plot    
            fig = figure; 
            Frames = size(AVSNCdataPeaks3{per},2);
            Frames_pre_stim_start = -((Frames-1)/2); 
            Frames_post_stim_start = (Frames-1)/2; 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack))+1;
            FrameVals = round((1:FPSstack:Frames)+5); 
            ax=gca;
            hold all

            plot(AVSNCdataPeaks{per},'b','LineWidth',4)
    %         plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
            ax.XTick = FrameVals;
            ax.XTickLabel = sec_TimeVals;   
            ax.FontSize = 25;
            ax.FontName = 'Times';
            xlabel('time (s)','FontName','Times')
            ylabel('calcium signal percent change','FontName','Times')
            xLimStart = floor(10*FPSstack);
            xLimEnd = floor(24*FPSstack); 
            xlim([1 size(AVSNCdataPeaks{per},2)])
            ylim([-60 100])

            patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],[0 0 0.5],'EdgeColor','none')
            set(fig,'position', [500 100 900 800])
            alpha(0.3)

            %add right y axis tick marks for a specific DOD figure. 
            yyaxis right 
            if BBBQ == 1
                plot(AVSNBdataPeaks{BBBROI}{per},'r','LineWidth',4)
                patch([x fliplr(x)],[(CI_bLow{BBBroi}) (fliplr(CI_bHigh{BBBroi}))],[0.5 0 0],'EdgeColor','none')
                ylabel('BBB permeability percent change','FontName','Times')
                tlabel = sprintf('Terminal%d_BBBroi%d.',terminals(ccell),BBBROI);
                title({sprintf('Terminals Averaged. BBB ROI %d.',BBBROI);perLabel})
            end 
            if VWQ == 1
                plot(AVSNVdataPeaks{VWROI}{per},'k','LineWidth',4)
                patch([x fliplr(x)],[(CI_vLow{VWroi}) (fliplr(CI_vHigh{VWroi}))],'k','EdgeColor','none')
                ylabel('Vessel width percent change','FontName','Times')
                title({sprintf('Terminals Averaged. VW ROI %d.',VWROI);perLabel})
            end 
            alpha(0.3)
            set(gca,'YColor',[0 0 0]);
            %make the directory and save the images   
            if saveQ == 1  
                dir2 = strrep(dir1,'\','/');
                dir3 = sprintf('%s/%s.tif',dir2,tlabel);
                export_fig(dir3)
            end        
        end 
    end 
    %}    
end 

%
 % plot bar plots 
 %{
    for ccell = 3%1:length(terminals)
        maxVals = zeros(1,3);
        maxValInds = zeros(1,3);
        CI_bHigh_maxVals = zeros(1,3);
        CI_bLow_maxVals = zeros(1,3);
%         SEMb_maxVals = zeros(1,3);
%         STDb_maxVals = zeros(1,3);
        flippedHighCI = cell(1,3);
        meanCIpreCaPeak_High = zeros(1,3);
        meanCIpreCaPeak_Low = zeros(1,3);
        meanCIpostCaPeak_High = zeros(1,3);
        meanCIpostCaPeak_Low = zeros(1,3);
        meanValPreCaPeak = zeros(1,3);
        meanValPostCaPeak = zeros(1,3);
        for per = 1:3
            %find max value from changePt to end 
%             [maxVal, maxValInd] = max(AVSNBdataPeaks{terminals(ccell)}{per}(changePt:end));
%             maxValInd = maxValInd + changePt - 1;
%             maxVals(per) = maxVal;
%             maxValInds(per) = maxValInd;

            %get 95% confidence interval of max vals 
%             flippedHighCI{per} = fliplr(CI_bHigh{per});
%             CI_bHigh_maxVals(per) = flippedHighCI{per}(maxValInds(per));
%             CI_bLow_maxVals(per) = CI_bLow{per}(maxValInds(per));
%             SEMb_maxVals(per) = SEMb{per}(maxValInds(per));
%             STDb_maxVals(per) = STDb{per}(maxValInds(per));

            %calculate mean values b/w 0.2 and 1 sec 
            startTval = 2.5 + 0.2;
%             startF = 35;%floor(startTval*FPSstack);
%             endF = 38;%floor(startF+(0.8*FPSstack));
            
            meanValPostCaPeak(per) = nanmean(AVSNBdataPeaks{terminals(ccell)}{per}(startF:endF));
            %calculate mean 95% confidence intervals before and after
            %calcium peak onset 
            flippedHighCI{per} = fliplr(CI_bHigh{per});
            meanCIpostCaPeak_High(per) = nanmean(flippedHighCI{per}(startF:endF));
            meanCIpostCaPeak_Low(per) = nanmean(CI_bLow{per}(startF:endF));                       
        end 

        
        % Plot each number one at a time, calling bar() for each y value.
        barFontSize = 20;
        x = 1:3;
        barColorMap(1,:) = [0 0 1]; %blue
        barColorMap(2,:) = [1 0 0]; %red
        barColorMap(3,:) = [0.3 0.3 0.3]; %black
        fig = figure;
        ax = gca;
        hold all
        for b = 1 : 3
            % Plot one single bar as a separate bar series.
            handleToThisBarSeries(b) = bar(x(b), meanValPostCaPeak(b), 'BarWidth', 0.9);
            % Apply the color to this bar series.
            set(handleToThisBarSeries(b), 'FaceColor', barColorMap(b,:));
            er = errorbar(x,meanValPostCaPeak,meanCIpostCaPeak_Low,meanCIpostCaPeak_High);
            er.LineStyle = 'none';
            er.Color = 'k';
            er.LineWidth = 2;
        end        
        ax.FontSize = 20;
        ylabel('maximum percent change in BBB permeability')
%         xlabel('light condition')
%         barNames = {'blue light','red light','light off'};
%         set(gca,'xticklabel',barNames)
        set(fig,'position', [500 100 800 800])
        set(gca,'xtick',[])       
        dir = sprintf('D:/70kD_RhoB/DAT-Chrimson-GCaMP/SF56_20190718/figures/Terminal12/DAterminal%d_maxChangeInBBBpermFollowingCaPeakAcrossLightConditionsWithCIs_1sSmoothing.tif',terminals(ccell));
%         export_fig(dir)
        if smoothQ == 0 
            title('Data not smoothed')
        elseif smoothQ == 1
            title(sprintf('Data smoothed by %0.2f sec',filtTime))
        end 
    end
    %}
% end 
%}
%% STA 1: plot calcium spike triggered average (average across mice. compare close and far terminals.) 
% takes already smooothed/normalized data 
%{
%get the data you need 
mouseDistQ = input('Input 1 if you already have a .mat file containing multiple mouse Ca ROI distances. Input 0 to make this .mat file. ');
if mouseDistQ == 1 
    regImDir = uigetdir('*.*','WHERE IS THE .MAT FILE THAT CONTAINS INFO ABOUT CA ROI DISTANCES?');
    cd(regImDir);
    MatFileName = uigetfile('*.*','SELECT THE .MAT FILE THAT CONTAINS INFO ABOUT CA ROI DISTANCES?');
    Mat = matfile(MatFileName);
    closeCaROIs = Mat.closeCaROIs;
    farCaROIs = Mat.farCaROIs;
    mouseNum = length(closeCaROIs);
elseif mouseDistQ == 0 
    mouseNum = input('How many mice are there? ');  
end 
% closeCaROI_CaBBBtimeLags = Mat.closeCaROI_CaBBBtimeLags;
% farCaROI_CaBBBtimeLags = Mat.farCaROI_CaBBBtimeLags;
allCTraces3 = cell(1,mouseNum);
allBTraces3 = cell(1,mouseNum);
allVTraces3 = cell(1,mouseNum);
CaROIs = cell(1,mouseNum);
FPSstack = cell(1,mouseNum);
SNCdataPeaks = cell(1,mouseNum);
SNBdataPeaks = cell(1,mouseNum);
SNVdataPeaks = cell(1,mouseNum);
for mouse = 1:mouseNum
    regImDir = uigetdir('*.*',sprintf('WHERE IS THE STA DATA FOR MOUSE #%d?',mouse));
    cd(regImDir);
    MatFileName = uigetfile('*.*',sprintf('SELECT THE STA DATA FOR MOUSE #%d',mouse));
    Mat = matfile(MatFileName);
    FPSstack{mouse} = Mat.FPSstack;
    allCTraces3{mouse} = Mat.allCTraces;
    SNCdataPeaks{mouse} = Mat.SNCdataPeaks;    
    allBTraces3{mouse} = Mat.allBTraces;
    SNBdataPeaks{mouse} = Mat.SNBdataPeaks;
    allVTraces3{mouse} = Mat.allVTraces;
    SNVdataPeaks{mouse} = Mat.SNVdataPeaks;  
    if mouseDistQ == 0
        closeCaROIs{mouse} = input(sprintf('What are the close Ca ROIs for mouse #%d? ',mouse));
        farCaROIs{mouse} = input(sprintf('What are the far Ca ROIs for mouse #%d? ',mouse));
    end 
    CaROIs{mouse} = horzcat(closeCaROIs{mouse},farCaROIs{mouse});
end 
if mouseDistQ == 0 
    saveDir = uigetdir('*.*','WHERE DO YOU WANT TO SAVE THE CA ROI DISTANCE DATA FOR MULTIPLE MICE?');
    cd(saveDir);
    save('CaROIdistances.mat','closeCaROIs','farCaROIs')
end 
tTypeQ = input('Input 1 if data is separated by light condition. Input 0 otherwise. ');

for mouse = 1:mouseNum
    if tTypeQ == 0 
        for per = 1:length(allCTraces3{1}{CaROIs{1}(1)})
            for CAROI = 1:size(CaROIs{mouse},2)
                if isempty(allCTraces3{mouse}{CaROIs{mouse}(CAROI)}) == 0 
                    %remove rows full of 0s/Nans if there are any b = a(any(a,2),:)
                    allCTraces3{mouse}{CaROIs{mouse}(CAROI)}{per} = allCTraces3{mouse}{CaROIs{mouse}(CAROI)}{per}(any(allCTraces3{mouse}{CaROIs{mouse}(CAROI)}{per},2),:);
                    for BBBroi = 1:size(allBTraces3{mouse},2)
                        allBTraces3{mouse}{BBBroi}{CaROIs{mouse}(CAROI)}{per} = allBTraces3{mouse}{BBBroi}{CaROIs{mouse}(CAROI)}{per}(any(allBTraces3{mouse}{BBBroi}{CaROIs{mouse}(CAROI)}{per},2),:);
                    end 
                    for VWroi = 1:size(allVTraces3{mouse},2)
                        allVTraces3{mouse}{VWroi}{CaROIs{mouse}(CAROI)}{per} = allVTraces3{mouse}{VWroi}{CaROIs{mouse}(CAROI)}{per}(any(allVTraces3{mouse}{VWroi}{CaROIs{mouse}(CAROI)}{per},2),:);
                    end 
                end 
            end 
        end 
    elseif tTypeQ == 1
        for per = 1:size(allCTraces3{1}{CaROIs{1}(1)},2)
            for CAROI = 1:size(CaROIs{mouse},2)
                if isempty(allCTraces3{mouse}{CaROIs{mouse}(CAROI)}) == 0 
                    %remove rows full of 0s/Nans if there are any b = a(any(a,2),:)
                    allCTraces3{mouse}{CaROIs{mouse}(CAROI)}{per} = allCTraces3{mouse}{CaROIs{mouse}(CAROI)}{per}(any(allCTraces3{mouse}{CaROIs{mouse}(CAROI)}{per},2),:);
                    for BBBroi = 1:size(allBTraces3{mouse},2)
                        allBTraces3{mouse}{BBBroi}{CaROIs{mouse}(CAROI)}{per} = allBTraces3{mouse}{BBBroi}{CaROIs{mouse}(CAROI)}{per}(any(allBTraces3{mouse}{BBBroi}{CaROIs{mouse}(CAROI)}{per},2),:);
                    end 
                    for VWroi = 1:size(allVTraces3{mouse},2)
                        allVTraces3{mouse}{VWroi}{CaROIs{mouse}(CAROI)}{per} = allVTraces3{mouse}{VWroi}{CaROIs{mouse}(CAROI)}{per}(any(allVTraces3{mouse}{VWroi}{CaROIs{mouse}(CAROI)}{per},2),:);
                    end 
                end 
            end 
        end 
    end 
end 

dataQ = input('Input 1 if you need to resort data/select specific spikes by per. Input 0 otherwise. ');
if dataQ == 1 
    allCTraces = allCTraces3; allBTraces = allBTraces3; allVTraces = allVTraces3;
    orgQ = input('How many different kinds of data organizations are there? ');
    perLoc = zeros(1,orgQ);
    orgMouseNum = zeros(1,orgQ);
    for org = 1:orgQ
        orgMouseNum(org) = input(sprintf('How many mice were #%d organized? ',org));
        perLoc(org) = input(sprintf('What per do you want to average from group #%d mice? ',org));
    end 
    % allBTraces3{mouse}{BBBroi}{CaROIs{mouse}(CAROI)}{per}
    mouseInds = cell(1,orgQ);
    allCTraces3 = cell(1,mouseNum);
    allBTraces3 = cell(1,mouseNum);
    allVTraces3 = cell(1,mouseNum);
    for org = 1:orgQ
        for orgNum = 1:orgMouseNum(org)
            %list indices for mice based on how they're organized 
            if org == 1
                mouseInds{org}(orgNum) = orgNum;
                for CAROI = 1:size(CaROIs{orgNum},2)
                    if isempty(allCTraces{orgNum}{CaROIs{orgNum}(CAROI)}) == 0 
                        allCTraces3{orgNum}{CaROIs{orgNum}(CAROI)}{1} = allCTraces{orgNum}{CaROIs{orgNum}(CAROI)}{perLoc(org)};
                        for BBBroi = 1:size(allBTraces{orgNum},2)
                            allBTraces3{orgNum}{BBBroi}{CaROIs{orgNum}(CAROI)}{1} = allBTraces{orgNum}{BBBroi}{CaROIs{orgNum}(CAROI)}{perLoc(org)};
                        end 
                        for VWroi = 1:size(allVTraces{orgNum},2)
                            allVTraces3{orgNum}{VWroi}{CaROIs{orgNum}(CAROI)}{1} = allVTraces{orgNum}{VWroi}{CaROIs{orgNum}(CAROI)}{perLoc(org)};                          
                        end 
                    end 
                end 
            elseif org > 1 
                mouseInds{org}(orgNum) = orgNum + max(mouseInds{1});
                for CAROI = 1:size(CaROIs{orgNum + max(mouseInds{1})},2)
                    if isempty(allCTraces{orgNum + max(mouseInds{1})}{CaROIs{orgNum + max(mouseInds{1})}(CAROI)}) == 0 
                        allCTraces3{orgNum + max(mouseInds{1})}{CaROIs{orgNum + max(mouseInds{1})}(CAROI)}{1} = allCTraces{orgNum + max(mouseInds{1})}{CaROIs{orgNum + max(mouseInds{1})}(CAROI)}{perLoc(org)};
                        for BBBroi = 1:size(allBTraces{orgNum + max(mouseInds{1})},2)
                            allBTraces3{orgNum + max(mouseInds{1})}{BBBroi}{CaROIs{orgNum + max(mouseInds{1})}(CAROI)}{1} = allBTraces{orgNum + max(mouseInds{1})}{BBBroi}{CaROIs{orgNum + max(mouseInds{1})}(CAROI)}{perLoc(org)};
                        end 
                        for VWroi = 1:size(allVTraces{orgNum + max(mouseInds{1})},2)
                            allVTraces3{orgNum + max(mouseInds{1})}{VWroi}{CaROIs{orgNum + max(mouseInds{1})}(CAROI)}{1} = allVTraces{orgNum + max(mouseInds{1})}{VWroi}{CaROIs{orgNum + max(mouseInds{1})}(CAROI)}{perLoc(org)};                          
                        end 
                    end 
                end                 
            end 
        end 
    end 
end 

% if tTypeQ == 0 
%     if per == 1 
%         perLabel = ("Peaks from entire experiment. ");
%     elseif per == 2 
%         perLabel = ("Peaks from stimulus. ");
%     elseif per == 3 
%         perLabel = ("Peaks peaks from reward. ");
%     elseif per == 4 
%         perLabel = ("Peaks from ITI. ");
%     end 
% elseif tTypeQ == 1 
%     if per == 1 
%         perLabel = ("Blue light on. ");
%     elseif per == 2 
%         perLabel = ("Red light on. ");
%     elseif per == 3 
%         perLabel = ("Light off. ");
%     end 
% end 


%% this plots individual STAs for every BBB and VW ROI per mouse

%set plotting paramaters 
BBBQ = input('Input 1 if you want to plot BBB data. ');
if BBBQ == 1
    BBBroiQ1 = input('Input 1 if you want to average all BBB ROIs. Input 0 otherwise. '); 
    BBBrois = cell(1,mouseNum);
    if BBBroiQ1 == 1
        for mouse = 1:mouseNum
            BBBrois{mouse} = 1:size(allBTraces3{mouse},2); 
        end 
    elseif BBBroiQ1 == 0 
        for mouse = 1:mouseNum
            BBBrois{mouse} = input(sprintf('What BBB ROIs do you want to average for mouse %d? ', mouse)); 
        end      
    end 
end 
VWQ = input('Input 1 if you want to plot vessel width data. ');
if VWQ == 1 
    VWroiNum = zeros(1,mouseNum);
    for mouse = 1:mouseNum
        VWroiNum(mouse) = size(allVTraces3{mouse},2); 
    end 
end 
saveQ = input('Input 1 to save the figures. Input 0 otherwise. ');
if saveQ == 1                
    dir1 = input('What folder are you saving these images in? ');
end 

allBTraces = allBTraces3;
allCTraces = allCTraces3;
allVTraces = allVTraces3;


%optional: remove traces that are greater than 2 standard deviations from the mean 
%{
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%THE BELOW NEEDS TO BE EDITED SO THAT 
%1) IT TAKES IN ALLBCVTRACES AND OUTPUTS ALLBCVTRACES
%2) IT ONLY CHANGES THE MOUSE DATA THAT YOU WANT TO CHANGE 
% MAKE SURE TO DOUBLE CHECK THE LOGIC BELOW WHILE IMPLEMENTING ABOVE
% CHANGES 
traceRemovalQ = input('Input 1 to statistically remove traces. Input 0 otherwise. '); 
if traceRemovalQ == 1 
    traceRemovalMice = input('Input the mice you want to statistically remove traces from? ');
    for mouse = 1:mouseNum
        if ismember(mouse,traceRemovalMice) == 1 %is in traceRemoval mice, do the below code 
            for CAROI = 1:length(CaROIs{traceRemovalMice(mouse)})
                if BBBQ == 1
                    for BBBroi = 1:size(allBTraces2{mouse},2)
                        AVSNBdataPeaks{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)} = nanmean(allBTraces{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)});            
                    end 
                end 
                AVSNCdataPeaks{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(CAROI)} = nanmean(allCTraces{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(CAROI)});
                if VWQ == 1
                    for VWroi = 1:size(allVTraces2{mouse},2)
                        AVSNVdataPeaks{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)} = nanmean(allVTraces{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)});
                    end 
                end 

                count2 = 1; 
                count3 = 1;
                count4 = 1;
                for peak = 1:size(allCTraces{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(CAROI)},1)
                        if BBBQ == 1
                            for BBBroi = 1:size(allBTraces2{mouse},2)
                                if allBTraces{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)}(peak,:) < AVSNBdataPeaks{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)} + nanstd(allBTraces{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)},1)*2  & allBTraces{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)}(peak,:) > AVSNBdataPeaks{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)} - nanstd(allBTraces{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)},1)*2               
                                    BTraces{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)}(count2,:) = (allBTraces{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)}(peak,:));
                                    count2 = count2 + 1;
                                end 
                            end 
                        end 
                        if allCTraces{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(CAROI)}(peak,:) < AVSNCdataPeaks{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(CAROI)} + nanstd(allCTraces{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(CAROI)},1)*2 & allCTraces{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(CAROI)}(peak,:) > AVSNCdataPeaks{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(CAROI)} - nanstd(allCTraces{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(CAROI)},1)*2                     
                            CTraces{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(CAROI)}(count3,:) = (allCTraces{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(CAROI)}(peak,:));
                            count3 = count3 + 1;
                        end 
                        if VWQ == 1
                            for VWroi = 1:size(allVTraces2{mouse},2)
                                if allVTraces{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)}(peak,:) < AVSNVdataPeaks{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)} + nanstd(allVTraces{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)},1)*2 & allVTraces{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)}(peak,:) > AVSNVdataPeaks{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)} - nanstd(allVTraces{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)},1)*2              
                                    VTraces{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)}(count4,:) = (allVTraces{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(CAROI)}(peak,:));
                                    count4 = count4 + 1;
                                end 
                            end 
                        end 
                end 
            end 
            if BBBQ == 1
                allBTraces{traceRemovalMice(mouse)} = BTraces{traceRemovalMice(mouse)};
            end 
            allCTraces{traceRemovalMice(mouse)} = CTraces{traceRemovalMice(mouse)};
            if VWQ == 1
                allVTraces{traceRemovalMice(mouse)} = VTraces{traceRemovalMice(mouse)};
            end
        elseif ismember(mouse,traceRemovalMice) == 0 % if the mouse is not on the list of mice to remove outliers from...THAN DON'T CHANGE ANYTHING 
        end 
    end 
end 
%}

%average the close and far terminals within each animal and plot 
closeCTraces = cell(1,length(closeCaROIs));
farCTraces = cell(1,length(closeCaROIs));
CTraces = cell(1,length(closeCaROIs));
closeCTraceArray = cell(1,length(closeCaROIs));
farCTraceArray = cell(1,length(closeCaROIs));
CTraceArray = cell(1,length(closeCaROIs));
far_AVSNCdataPeaks = cell(1,length(closeCaROIs));
close_AVSNCdataPeaks = cell(1,length(closeCaROIs));
AVSNCdataPeaks = cell(1,length(closeCaROIs));
if BBBQ == 1
    closeBTraces = cell(1,length(closeCaROIs));
    farBTraces = cell(1,length(closeCaROIs));
    BTraces = cell(1,length(closeCaROIs));
    closeBTraceArray = cell(1,length(closeCaROIs));
    farBTraceArray = cell(1,length(closeCaROIs));
    BTraceArray = cell(1,length(closeCaROIs));
    far_AVSNBdataPeaks = cell(1,length(closeCaROIs));
    close_AVSNBdataPeaks = cell(1,length(closeCaROIs));
    AVSNBdataPeaks = cell(1,length(closeCaROIs));
    close_CI_bLow = cell(1,mouseNum);
    close_CI_bHigh = cell(1,mouseNum);
    far_CI_bLow = cell(1,mouseNum);
    far_CI_bHigh = cell(1,mouseNum);
    CI_bLow = cell(1,mouseNum);
    CI_bHigh = cell(1,mouseNum);
end 
if VWQ == 1
    closeVTraces = cell(1,length(closeCaROIs));
    farVTraces = cell(1,length(closeCaROIs));
    VTraces = cell(1,length(closeCaROIs));
    closeVTraceArray = cell(1,length(closeCaROIs));
    farVTraceArray = cell(1,length(closeCaROIs));
    VTraceArray = cell(1,length(closeCaROIs));
    far_AVSNVdataPeaks = cell(1,length(closeCaROIs));
    close_AVSNVdataPeaks = cell(1,length(closeCaROIs));
    AVSNVdataPeaks = cell(1,length(closeCaROIs));
    close_CI_vLow = cell(1,mouseNum);
    close_CI_vHigh = cell(1,mouseNum);
    far_CI_vLow = cell(1,mouseNum);
    far_CI_vHigh = cell(1,mouseNum);
    CI_vLow = cell(1,mouseNum);
    CI_vHigh = cell(1,mouseNum);
end 

TimingQ = input('Input 1 if you want to sort traces based on BBB-Ca peak time gap. Input 0 otherwise. ');
if TimingQ == 1
    TimingQ2 = input('Input 1 to plot positive BBB-Ca timing. Input 0 for negative. ');
end 

%put all similar trials together 
for mouse = 1:mouseNum
    if TimingQ == 0 
        closeCTraces{mouse} = allCTraces{mouse}(closeCaROIs{mouse}); 
        farCTraces{mouse} = allCTraces{mouse}(farCaROIs{mouse});
        CTraces{mouse} = allCTraces{mouse}(CaROIs{mouse});
    elseif TimingQ == 1
        if TimingQ2 == 1 % find close Traces where time lag is positive 
            closeCTraces{mouse} = allCTraces{mouse}(closeCaROIs{mouse}(closeCaROI_CaBBBtimeLags{mouse} > 0));  
            farCTraces{mouse} = allCTraces{mouse}(farCaROIs{mouse}(farCaROI_CaBBBtimeLags{mouse} > 0));
        elseif TimingQ2 == 0 % find close Traces where time lag is negative 
            closeCTraces{mouse} = allCTraces{mouse}(closeCaROIs{mouse}(closeCaROI_CaBBBtimeLags{mouse} < 0));  
            farCTraces{mouse} = allCTraces{mouse}(farCaROIs{mouse}(farCaROI_CaBBBtimeLags{mouse} < 0));
        end           
    end 
    %remove empty cells if there are any b = a(any(a,2),:)
    closeCTraces{mouse} = closeCTraces{mouse}(~cellfun('isempty',closeCTraces{mouse}));
    farCTraces{mouse} = farCTraces{mouse}(~cellfun('isempty',farCTraces{mouse}));
    CTraces{mouse} = CTraces{mouse}(~cellfun('isempty',CTraces{mouse}));
    if BBBQ == 1
        for BBBroi = 1:length(BBBrois{mouse})
            closeBTraces{mouse}{BBBroi} = allBTraces{mouse}{BBBrois{mouse}(BBBroi)}(closeCaROIs{mouse});
            farBTraces{mouse}{BBBroi} = allBTraces{mouse}{BBBrois{mouse}(BBBroi)}(farCaROIs{mouse});
            BTraces{mouse}{BBBroi} = allBTraces{mouse}{BBBrois{mouse}(BBBroi)}(CaROIs{mouse}); 
            %remove empty cells if there are any b = a(any(a,2),:)
            closeBTraces{mouse}{BBBroi} = closeBTraces{mouse}{BBBroi}(~cellfun('isempty',closeBTraces{mouse}{BBBroi}));
            farBTraces{mouse}{BBBroi} = farBTraces{mouse}{BBBroi}(~cellfun('isempty',farBTraces{mouse}{BBBroi}));
            BTraces{mouse}{BBBroi} = BTraces{mouse}{BBBroi}(~cellfun('isempty',BTraces{mouse}{BBBroi}));
        end
    end 
    if VWQ == 1
        for VWroi = 1:VWroiNum(mouse)
            closeVTraces{mouse}{VWroi} = allVTraces{mouse}{VWroi}(closeCaROIs{mouse});
            farVTraces{mouse}{VWroi} = allVTraces{mouse}{VWroi}(farCaROIs{mouse});
            VTraces{mouse}{VWroi} = allVTraces{mouse}{VWroi}(CaROIs{mouse});
            %remove empty cells if there are any b = a(any(a,2),:)
            closeVTraces{mouse}{VWroi} = closeVTraces{mouse}{VWroi}(~cellfun('isempty',closeVTraces{mouse}{VWroi}));
            farVTraces{mouse}{VWroi} = farVTraces{mouse}{VWroi}(~cellfun('isempty',farVTraces{mouse}{VWroi}));
            VTraces{mouse}{VWroi} = VTraces{mouse}{VWroi}(~cellfun('isempty',VTraces{mouse}{VWroi}));
        end 
    end 
end 

% resort data: concatenate all CaROI data 
% output = CaArray{mouse}{per}(concatenated caRoi data)
% output = VW/BBBarray{mouse}{BBB/VWroi}{per}(concatenated caRoi data)
for mouse = 1:mouseNum
    for per = 1:length(allCTraces3{1}{CaROIs{1}(2)})
        for ccell = 1:length(closeCTraces{mouse})
            if isempty(closeCTraces{mouse}{ccell}) == 0 
                if ccell == 1 
                    closeCTraceArray{mouse}{per} = closeCTraces{mouse}{ccell}{per}; 
                    if BBBQ == 1
                        for BBBroi = 1:length(BBBrois{mouse})
                            closeBTraceArray{mouse}{BBBroi}{per} = closeBTraces{mouse}{BBBroi}{ccell}{per}; 
                        end 
                    end 
                    if VWQ == 1
                        for VWroi = 1:VWroiNum(mouse)
                            closeVTraceArray{mouse}{VWroi}{per} = closeVTraces{mouse}{VWroi}{ccell}{per}; 
                        end 
                    end 
                elseif ccell > 1 
                    closeCTraceArray{mouse}{per} = vertcat(closeCTraceArray{mouse}{per},closeCTraces{mouse}{ccell}{per});
                    if BBBQ == 1
                        for BBBroi = 1:length(BBBrois{mouse})
                            closeBTraceArray{mouse}{BBBroi}{per} = vertcat(closeBTraceArray{mouse}{BBBroi}{per},closeBTraces{mouse}{BBBroi}{ccell}{per});
                        end 
                    end 
                    if VWQ == 1
                        for VWroi = 1:VWroiNum(mouse)
                            closeVTraceArray{mouse}{VWroi}{per} = vertcat(closeVTraceArray{mouse}{VWroi}{per},closeVTraces{mouse}{VWroi}{ccell}{per});
                        end 
                    end 
                end
            end 
        end 
        for ccell = 1:length(farCTraces{mouse})
            if isempty(farCTraces{mouse}{ccell}) == 0 
                if ccell == 1 
                    farCTraceArray{mouse}{per} = farCTraces{mouse}{ccell}{per};
                    if BBBQ == 1
                        for BBBroi = 1:length(BBBrois{mouse})
                            farBTraceArray{mouse}{BBBroi}{per} = farBTraces{mouse}{BBBroi}{ccell}{per}; 
                        end 
                    end 
                    if VWQ == 1
                        for VWroi = 1:VWroiNum(mouse)
                            farVTraceArray{mouse}{VWroi}{per} = farVTraces{mouse}{VWroi}{ccell}{per}; 
                        end 
                    end 
                elseif ccell > 1 
                    farCTraceArray{mouse}{per} = vertcat(farCTraceArray{mouse}{per},farCTraces{mouse}{ccell}{per});
                    if BBBQ == 1
                        for BBBroi = 1:length(BBBrois{mouse})
                            farBTraceArray{mouse}{BBBroi}{per} = vertcat(farBTraceArray{mouse}{BBBroi}{per},farBTraces{mouse}{BBBroi}{ccell}{per});
                        end 
                    end 
                    if VWQ == 1
                        for VWroi = 1:VWroiNum(mouse)
                            farVTraceArray{mouse}{VWroi}{per} = vertcat(farVTraceArray{mouse}{VWroi}{per},farVTraces{mouse}{VWroi}{ccell}{per});
                        end 
                    end 
                end
            end 
        end 
        for ccell = 1:length(CTraces{mouse})
            if isempty(CTraces{mouse}{ccell}) == 0 
                if ccell == 1 
                    CTraceArray{mouse}{per} = CTraces{mouse}{ccell}{per};
                    if BBBQ == 1
                        for BBBroi = 1:length(BBBrois{mouse})
                            BTraceArray{mouse}{BBBroi}{per} = BTraces{mouse}{BBBroi}{ccell}{per}; 
                        end 
                    end 
                    if VWQ == 1
                        for VWroi = 1:VWroiNum(mouse)
                            VTraceArray{mouse}{VWroi}{per} = VTraces{mouse}{VWroi}{ccell}{per}; 
                        end 
                    end 
                elseif ccell > 1 
                    CTraceArray{mouse}{per} = vertcat(CTraceArray{mouse}{per},CTraces{mouse}{ccell}{per});
                    if BBBQ == 1
                        for BBBroi = 1:length(BBBrois{mouse})
                            BTraceArray{mouse}{BBBroi}{per} = vertcat(BTraceArray{mouse}{BBBroi}{per},BTraces{mouse}{BBBroi}{ccell}{per});
                        end 
                    end 
                    if VWQ == 1
                        for VWroi = 1:VWroiNum(mouse)
                            VTraceArray{mouse}{VWroi}{per} = vertcat(VTraceArray{mouse}{VWroi}{per},VTraces{mouse}{VWroi}{ccell}{per});
                        end 
                    end 
                end
            end 
        end 

        %DETERMINE 95% CI
        if BBBQ == 1 
            for BBBroi = 1:length(BBBrois{mouse})
                close_SEMb = (nanstd(closeBTraceArray{mouse}{BBBroi}{per}))/(sqrt(size(closeBTraceArray{mouse}{BBBroi}{per},1))); % Standard Error            
                close_ts_bLow = tinv(0.025,size(closeBTraceArray{mouse}{BBBroi}{per},1)-1);% T-Score for 95% CI
                close_ts_bHigh = tinv(0.975,size(closeBTraceArray{mouse}{BBBroi}{per},1)-1);% T-Score for 95% CI
                close_CI_bLow{mouse}{BBBroi}{per} = (nanmean(closeBTraceArray{mouse}{BBBroi}{per},1)) + (close_ts_bLow*close_SEMb);  % Confidence Intervals
                close_CI_bHigh{mouse}{BBBroi}{per} = (nanmean(closeBTraceArray{mouse}{BBBroi}{per},1)) + (close_ts_bHigh*close_SEMb);  % Confidence Intervals

                far_SEMb = (nanstd(farBTraceArray{mouse}{BBBroi}{per}))/(sqrt(size(farBTraceArray{mouse}{BBBroi}{per},1))); % Standard Error            
                far_ts_bLow = tinv(0.025,size(farBTraceArray{mouse}{BBBroi}{per},1)-1);% T-Score for 95% CI
                far_ts_bHigh = tinv(0.975,size(farBTraceArray{mouse}{BBBroi}{per},1)-1);% T-Score for 95% CI
                far_CI_bLow{mouse}{BBBroi}{per} = (nanmean(farBTraceArray{mouse}{BBBroi}{per},1)) + (far_ts_bLow*far_SEMb);  % Confidence Intervals
                far_CI_bHigh{mouse}{BBBroi}{per} = (nanmean(farBTraceArray{mouse}{BBBroi}{per},1)) + (far_ts_bHigh*far_SEMb);  % Confidence Intervals
                
                SEMb = (nanstd(BTraceArray{mouse}{BBBroi}{per}))/(sqrt(size(BTraceArray{mouse}{BBBroi}{per},1))); % Standard Error            
                ts_bLow = tinv(0.025,size(BTraceArray{mouse}{BBBroi}{per},1)-1);% T-Score for 95% CI
                ts_bHigh = tinv(0.975,size(BTraceArray{mouse}{BBBroi}{per},1)-1);% T-Score for 95% CI
                CI_bLow{mouse}{BBBroi}{per} = (nanmean(BTraceArray{mouse}{BBBroi}{per},1)) + (ts_bLow*SEMb);  % Confidence Intervals
                CI_bHigh{mouse}{BBBroi}{per} = (nanmean(BTraceArray{mouse}{BBBroi}{per},1)) + (ts_bHigh*SEMb);  % Confidence Intervals
            end 
        end 

        close_SEMc = (nanstd(closeCTraceArray{mouse}{per}))/(sqrt(size(closeCTraceArray{mouse}{per},1))); % Standard Error            
        close_ts_cLow = tinv(0.025,size(closeCTraceArray{mouse}{per},1)-1);% T-Score for 95% CI
        close_ts_cHigh = tinv(0.975,size(closeCTraceArray{mouse}{per},1)-1);% T-Score for 95% CI
        close_CI_cLow{mouse}{per} = (nanmean(closeCTraceArray{mouse}{per},1)) + (close_ts_cLow*close_SEMc);  % Confidence Intervals
        close_CI_cHigh{mouse}{per} = (nanmean(closeCTraceArray{mouse}{per},1)) + (close_ts_cHigh*close_SEMc);  % Confidence Intervals

        far_SEMc = (nanstd(farCTraceArray{mouse}{per}))/(sqrt(size(farCTraceArray{mouse}{per},1))); % Standard Error            
        far_ts_cLow = tinv(0.025,size(farCTraceArray{mouse}{per},1)-1);% T-Score for 95% CI
        far_ts_cHigh = tinv(0.975,size(farCTraceArray{mouse}{per},1)-1);% T-Score for 95% CI
        far_CI_cLow{mouse}{per} = (nanmean(farCTraceArray{mouse}{per},1)) + (far_ts_cLow*far_SEMc);  % Confidence Intervals
        far_CI_cHigh{mouse}{per} = (nanmean(farCTraceArray{mouse}{per},1)) + (far_ts_cHigh*far_SEMc);  % Confidence Intervals

        SEMc = (nanstd(CTraceArray{mouse}{per}))/(sqrt(size(CTraceArray{mouse}{per},1))); % Standard Error            
        ts_cLow = tinv(0.025,size(CTraceArray{mouse}{per},1)-1);% T-Score for 95% CI
        ts_cHigh = tinv(0.975,size(CTraceArray{mouse}{per},1)-1);% T-Score for 95% CI
        CI_cLow{mouse}{per} = (nanmean(CTraceArray{mouse}{per},1)) + (ts_cLow*SEMc);  % Confidence Intervals
        CI_cHigh{mouse}{per} = (nanmean(CTraceArray{mouse}{per},1)) + (ts_cHigh*SEMc);  % Confidence Intervals

        if VWQ == 1
            for VWroi = 1:VWroiNum(mouse)
                close_SEMv = (nanstd(closeVTraceArray{mouse}{VWroi}{per}))/(sqrt(size(closeVTraceArray{mouse}{VWroi}{per},1))); % Standard Error            
                close_ts_vLow = tinv(0.025,size(closeVTraceArray{mouse}{VWroi}{per},1)-1);% T-Score for 95% CI
                close_ts_vHigh = tinv(0.975,size(closeVTraceArray{mouse}{VWroi}{per},1)-1);% T-Score for 95% CI
                close_CI_vLow{mouse}{VWroi}{per} = (nanmean(closeVTraceArray{mouse}{VWroi}{per},1)) + (close_ts_vLow*close_SEMv);  % Confidence Intervals
                close_CI_vHigh{mouse}{VWroi}{per} = (nanmean(closeVTraceArray{mouse}{VWroi}{per},1)) + (close_ts_vHigh*close_SEMv);  % Confidence Intervals

                far_SEMv = (nanstd(farVTraceArray{mouse}{VWroi}{per}))/(sqrt(size(farVTraceArray{mouse}{VWroi}{per},1))); % Standard Error            
                far_ts_vLow = tinv(0.025,size(farVTraceArray{mouse}{VWroi}{per},1)-1);% T-Score for 95% CI
                far_ts_vHigh = tinv(0.975,size(farVTraceArray{mouse}{VWroi}{per},1)-1);% T-Score for 95% CI
                far_CI_vLow{mouse}{VWroi}{per} = (nanmean(farVTraceArray{mouse}{VWroi}{per},1)) + (far_ts_vLow*far_SEMv);  % Confidence Intervals
                far_CI_vHigh{mouse}{VWroi}{per} = (nanmean(farVTraceArray{mouse}{VWroi}{per},1)) + (far_ts_vHigh*far_SEMv);  % Confidence Intervals
               
                SEMv = (nanstd(VTraceArray{mouse}{VWroi}{per}))/(sqrt(size(VTraceArray{mouse}{VWroi}{per},1))); % Standard Error            
                ts_vLow = tinv(0.025,size(VTraceArray{mouse}{VWroi}{per},1)-1);% T-Score for 95% CI
                ts_vHigh = tinv(0.975,size(VTraceArray{mouse}{VWroi}{per},1)-1);% T-Score for 95% CI
                CI_vLow{mouse}{VWroi}{per} = (nanmean(VTraceArray{mouse}{VWroi}{per},1)) + (ts_vLow*SEMv);  % Confidence Intervals
                CI_vHigh{mouse}{VWroi}{per} = (nanmean(VTraceArray{mouse}{VWroi}{per},1)) + (ts_vHigh*SEMv);  % Confidence Intervals
            end 
        end 

        x = 1:length(close_CI_cLow{mouse}{per});
   
        %get averages
        if BBBQ == 1
            for BBBroi = 1:length(BBBrois{mouse})
                close_AVSNBdataPeaks{mouse}{BBBroi}{per} = nanmean(closeBTraceArray{mouse}{BBBroi}{per},1);
                far_AVSNBdataPeaks{mouse}{BBBroi}{per} = nanmean(farBTraceArray{mouse}{BBBroi}{per},1);
                AVSNBdataPeaks{mouse}{BBBroi}{per} = nanmean(BTraceArray{mouse}{BBBroi}{per},1);
            end 
        end 
        close_AVSNCdataPeaks{mouse}{per} = nanmean(closeCTraceArray{mouse}{per},1);
        far_AVSNCdataPeaks{mouse}{per} = nanmean(farCTraceArray{mouse}{per},1);
        AVSNCdataPeaks{mouse}{per} = nanmean(CTraceArray{mouse}{per},1);
        if VWQ == 1
            for VWroi = 1:VWroiNum(mouse)
                close_AVSNVdataPeaks{mouse}{VWroi}{per} = nanmean(closeVTraceArray{mouse}{VWroi}{per},1);
                far_AVSNVdataPeaks{mouse}{VWroi}{per} = nanmean(farVTraceArray{mouse}{VWroi}{per},1);
                AVSNVdataPeaks{mouse}{VWroi}{per} = nanmean(VTraceArray{mouse}{VWroi}{per},1);
            end 
        end 

        % plot individual Ca ROI traces for all mice at once 
        %{
        if isempty(close_AVSNCdataPeaks{mouse}) == 0
            % plot close Ca ROI data 
            if BBBQ == 1
                for BBBroi = 1:BBBroiNum(mouse)
                    fig = figure;
                    Frames = size(closeCTraceArray{mouse},2);
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
                    FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
                    ax=gca;
                    hold all
                    plot(close_AVSNCdataPeaks{mouse},'b','LineWidth',4)
                    changePt = floor(Frames/2)-floor(0.25*FPSstack{mouse});
                    plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
                    ax.XTick = FrameVals;
                    ax.XTickLabel = sec_TimeVals;   
                    ax.FontSize = 25;
                    ax.FontName = 'Times';
                    xlabel('time (s)','FontName','Times')
                    ylabel('calcium signal percent change','FontName','Times')
                    xLimStart = floor(10*FPSstack{mouse});
                    xLimEnd = floor(24*FPSstack{mouse}); 
                    xlim([1 size(close_AVSNCdataPeaks{mouse},2)])
                    ylim([-60 100])
                    patch([x fliplr(x)],[close_CI_cLow fliplr(close_CI_cHigh)],[0 0 0.5],'EdgeColor','none')
                    set(fig,'position', [500 100 900 800])
                    alpha(0.3)
                    %add right y axis tick marks for a specific DOD figure. 
                    yyaxis right 
                    plot(close_AVSNBdataPeaks{mouse}{BBBroi},'r','LineWidth',4)
                    patch([x fliplr(x)],[(close_CI_bLow{mouse}{BBBroi}) (fliplr(close_CI_bHigh{mouse}{BBBroi}))],[0.5 0 0],'EdgeColor','none')
                    ylabel('BBB permeability percent change','FontName','Times')
                    title(sprintf('Close Terminals. Mouse %d. BBB ROI %d.',mouse,BBBroi))
                    alpha(0.3)
                    set(gca,'YColor',[0 0 0]);     
                end 
            end 

            if VWQ == 1
                for VWroi = 1:VWroiNum(mouse)           
                    fig = figure;
                    Frames = size(closeCTraceArray{mouse},2);
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
                    FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
                    ax=gca;
                    hold all
                    plot(close_AVSNCdataPeaks{mouse},'b','LineWidth',4)
                    changePt = floor(Frames/2)-floor(0.25*FPSstack{mouse});
                    plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
                    ax.XTick = FrameVals;
                    ax.XTickLabel = sec_TimeVals;   
                    ax.FontSize = 25;
                    ax.FontName = 'Times';
                    xlabel('time (s)','FontName','Times')
                    ylabel('calcium signal percent change','FontName','Times')
                    xLimStart = floor(10*FPSstack{mouse});
                    xLimEnd = floor(24*FPSstack{mouse}); 
                    xlim([1 size(close_AVSNCdataPeaks{mouse},2)])
                    ylim([-60 100])
                    patch([x fliplr(x)],[close_CI_cLow fliplr(close_CI_cHigh)],[0 0 0.5],'EdgeColor','none')
                    set(fig,'position', [500 100 900 800])
                    alpha(0.3)
                    %add right y axis tick marks for a specific DOD figure. 
                    yyaxis right 
                    plot(close_AVSNVdataPeaks{mouse}{VWroi},'k','LineWidth',4)
                    patch([x fliplr(x)],[(close_CI_vLow{mouse}{VWroi}) (fliplr(close_CI_vHigh{mouse}{VWroi}))],'k','EdgeColor','none')
                    ylabel('Vessel width percent change','FontName','Times')
                    title(sprintf('Close Terminals. Mouse %d. VW ROI %d.',mouse,VWroi))
                    title(sprintf('Close Terminals. Mouse %d. VW ROI %d.',mouse,VWroi))
                    alpha(0.3)
                    set(gca,'YColor',[0 0 0]);  
                end 
            end 

            % plot far Ca ROI data 
            if BBBQ == 1
                for BBBroi = 1:BBBroiNum(mouse)               
                    fig = figure;
                    Frames = size(closeCTraceArray{mouse},2);
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
                    FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
                    ax=gca;
                    hold all
                    plot(far_AVSNCdataPeaks{mouse},'b','LineWidth',4)
                    changePt = floor(Frames/2)-floor(0.25*FPSstack{mouse});
                    plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
                    ax.XTick = FrameVals;
                    ax.XTickLabel = sec_TimeVals;   
                    ax.FontSize = 25;
                    ax.FontName = 'Times';
                    xlabel('time (s)','FontName','Times')
                    ylabel('calcium signal percent change','FontName','Times')
                    xLimStart = floor(10*FPSstack{mouse});
                    xLimEnd = floor(24*FPSstack{mouse});     
                    xlim([1 size(close_AVSNCdataPeaks{mouse},2)])   
                    ylim([-60 100])
                    patch([x fliplr(x)],[far_CI_cLow fliplr(far_CI_cHigh)],[0 0 0.5],'EdgeColor','none')
                    set(fig,'position', [500 100 900 800])
                    alpha(0.3)
                    %add right y axis tick marks for a specific DOD figure. 
                    yyaxis right            
                    plot(far_AVSNBdataPeaks{mouse}{BBBroi},'r','LineWidth',4)
                    patch([x fliplr(x)],[(far_CI_bLow{mouse}{BBBroi}) (fliplr(far_CI_bHigh{mouse}{BBBroi}))],[0.5 0 0],'EdgeColor','none')
                    ylabel('BBB permeability percent change','FontName','Times')
                    title(sprintf('Far Terminals. Mouse %d. BBB ROI %d.',mouse,BBBroi))
                    alpha(0.3)
                    set(gca,'YColor',[0 0 0]);      
                end 
            end 

            if VWQ == 1
                for VWroi = 1:VWroiNum(mouse)
                    fig = figure;
                    Frames = size(closeCTraceArray{mouse},2);
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
                    FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
                    ax=gca;
                    hold all
                    plot(far_AVSNCdataPeaks{mouse},'b','LineWidth',4)
                    changePt = floor(Frames/2)-floor(0.25*FPSstack{mouse});
                    plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
                    ax.XTick = FrameVals;
                    ax.XTickLabel = sec_TimeVals;   
                    ax.FontSize = 25;
                    ax.FontName = 'Times';
                    xlabel('time (s)','FontName','Times')
                    ylabel('calcium signal percent change','FontName','Times')
                    xLimStart = floor(10*FPSstack{mouse});
                    xLimEnd = floor(24*FPSstack{mouse});     
                    xlim([1 size(close_AVSNCdataPeaks{mouse},2)])   
                    ylim([-60 100])
                    patch([x fliplr(x)],[far_CI_cLow fliplr(far_CI_cHigh)],[0 0 0.5],'EdgeColor','none')
                    set(fig,'position', [500 100 900 800])
                    alpha(0.3)
                    %add right y axis tick marks for a specific DOD figure. 
                    yyaxis right 
                    plot(far_AVSNVdataPeaks{mouse}{VWroi},'k','LineWidth',4)
                    patch([x fliplr(x)],[(far_CI_vLow{mouse}{VWroi}) (fliplr(far_CI_vHigh{mouse}{VWroi}))],'k','EdgeColor','none')
                    ylabel('Vessel width percent change','FontName','Times')
                    title(sprintf('Far Terminals. Mouse %d. VW ROI %d.',mouse,VWroi))
                    title(sprintf('Far Terminals. Mouse %d. VW ROI %d.',mouse,VWroi))
                    alpha(0.3)
                    set(gca,'YColor',[0 0 0]);   
                end 
            end 
        end
        %}
    end 
end 

%% AVERAGE ACROSS MICE 
clear close_Btraces_allMice far_Btraces_allMice close_Ctraces_allMice far_Ctraces_allMice close_Vtraces_allMice far_Vtraces_allMice   

% figure out the size you should resample your data to 
FPSstack2 = zeros(1,mouseNum);
for mouse = 1:mouseNum
    FPSstack2(mouse) = FPSstack{mouse};
end 
minFPSstack = FPSstack2 == min(FPSstack2);
idx = find(minFPSstack ~= 0, 1, 'first');
minLen = length(close_AVSNCdataPeaks{idx}{1});

% mouseNums = [1,2,3,4,5];
mouseNums = input('Input the mice you want to average. ');
counter1 = 1;
counter2 = 1;
counter3 = 1;
counter4 = 1;
counter5 = 1;
counter6 = 1;
counter7 = 1;
counter8 = 1;
counter9 = 1;
% below commented out code is for normalizing for the total number of traces
% per data type 
%{
if BBBQ == 1
    closeBtrace_nums = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
    farBtrace_nums = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
    Btrace_nums = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
end 
closeCtrace_nums = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
farCtrace_nums = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
Ctrace_nums = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
if VWQ == 1
    closeVtrace_nums = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
    farVtrace_nums = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
    Vtrace_nums = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
end 
for mouse = 1:length(mouseNums)
    for per = 1:length(allCTraces3{1}{CaROIs{1}(1)})
        if BBBQ == 1
            for BBBroi = 1:length(BBBrois{mouse})
                 closeBtrace_nums{per}(mouse,BBBroi) = size(closeBTraceArray{mouseNums(mouse)}{BBBroi}{per},1);
                 farBtrace_nums{per}(mouse,BBBroi) = size(farBTraceArray{mouseNums(mouse)}{BBBroi}{per},1);
                 Btrace_nums{per}(mouse,BBBroi) = size(BTraceArray{mouseNums(mouse)}{BBBroi}{per},1);
            end 
        end 
         closeCtrace_nums{per}(mouse) = size(closeCTraceArray{mouseNums(mouse)}{per},1);
         farCtrace_nums{per}(mouse) = size(farCTraceArray{mouseNums(mouse)}{per},1);
         Ctrace_nums{per}(mouse) = size(CTraceArray{mouseNums(mouse)}{per},1);
         if VWQ == 1
             for VWroi = 1:VWroiNum(mouse)
                 closeVtrace_nums{per}(mouse,VWroi) = size(closeVTraceArray{mouseNums(mouse)}{VWroi}{per},1);
                 farVtrace_nums{per}(mouse,VWroi) = size(farVTraceArray{mouseNums(mouse)}{VWroi}{per},1);
                 Vtrace_nums{per}(mouse,VWroi) = size(VTraceArray{mouseNums(mouse)}{VWroi}{per},1);
             end 
         end 
    end 
end 

for per = 1:length(allCTraces3{1}{CaROIs{1}(1)})
    if BBBQ == 1
        totalNum_closeBtraces{per} = sum(sum(closeBtrace_nums{per}));
        totalNum_farBtraces{per} = sum(sum(farBtrace_nums{per}));
        totalNum_Btraces{per} = sum(sum(Btrace_nums{per}));
    end 
    totalNum_closeCtraces{per} = sum(closeCtrace_nums{per});
    totalNum_farCtraces{per} = sum(farCtrace_nums{per});
    totalNum_Ctraces{per} = sum(Ctrace_nums{per});
    if VWQ == 1
        totalNum_closeVtraces{per} = sum(sum(closeVtrace_nums{per}));
        totalNum_farVtraces{per} = sum(sum(farVtrace_nums{per}));
        totalNum_Vtraces{per} = sum(sum(Vtrace_nums{per}));
    end 
end 
%}

close_Ctraces_allMice = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
far_Ctraces_allMice = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
Ctraces_allMice = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
if BBBQ == 1 
    close_Btraces_allMice = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
    far_Btraces_allMice = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
    Btraces_allMice = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
end 
if VWQ == 1 
    close_Vtraces_allMice = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
    far_Vtraces_allMice = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
    Vtraces_allMice = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
end 
for mouse = 1:length(mouseNums)   
    for per = 1:length(allCTraces3{1}{CaROIs{1}(2)})
        %resample and sort data
        if BBBQ == 1
            for BBBroi = 1:length(BBBrois{mouse})
                for trace1 = 1:size(closeBTraceArray{mouseNums(mouse)}{BBBroi}{per},1)
                    close_Btraces_allMice{per}(counter1,:) = (resample(closeBTraceArray{mouseNums(mouse)}{BBBroi}{per}(trace1,:),minLen,size(closeBTraceArray{mouseNums(mouse)}{BBBroi}{per},2)));% * (size(closeBTraceArray{mouseNums(mouse)}{BBBroi},1)/totalNum_closeBtraces);                              
                    counter1 = counter1 + 1;
                end 
                for trace1 = 1:size(farBTraceArray{mouseNums(mouse)}{BBBroi}{per},1)
                    far_Btraces_allMice{per}(counter2,:) = resample(farBTraceArray{mouseNums(mouse)}{BBBroi}{per}(trace1,:),minLen,size(farBTraceArray{mouseNums(mouse)}{BBBroi}{per},2));% * (size(farBTraceArray{mouseNums(mouse)}{BBBroi},1)/totalNum_farBtraces);                     
                    counter2 = counter2 + 1;
                end 
                for trace1 = 1:size(BTraceArray{mouseNums(mouse)}{BBBroi}{per},1)
                    Btraces_allMice{per}(counter7,:) = resample(BTraceArray{mouseNums(mouse)}{BBBroi}{per}(trace1,:),minLen,size(BTraceArray{mouseNums(mouse)}{BBBroi}{per},2));% * (size(farBTraceArray{mouseNums(mouse)}{BBBroi},1)/totalNum_farBtraces);  
                    counter7 = counter7 + 1;
                end 
            end    
        end 
        for trace2 = 1:size(closeCTraceArray{mouseNums(mouse)}{per},1)
            close_Ctraces_allMice{per}(counter3,:) = (resample(closeCTraceArray{mouseNums(mouse)}{per}(trace2,:),minLen,size(closeCTraceArray{mouseNums(mouse)}{per},2)));% * (size(closeCTraceArray{mouseNums(mouse)},1)/totalNum_closeCtraces);           
            counter3 = counter3 + 1;
        end 
        for trace2 = 1:size(farCTraceArray{mouseNums(mouse)}{per},1)
            far_Ctraces_allMice{per}(counter4,:) = resample(farCTraceArray{mouseNums(mouse)}{per}(trace2,:),minLen,size(farCTraceArray{mouseNums(mouse)}{per},2));% * * (size(farCTraceArray{mouseNums(mouse)},1)/totalNum_farCtraces);  
            counter4 = counter4 + 1;
        end   
        for trace2 = 1:size(CTraceArray{mouseNums(mouse)}{per},1)
            Ctraces_allMice{per}(counter8,:) = resample(CTraceArray{mouseNums(mouse)}{per}(trace2,:),minLen,size(CTraceArray{mouseNums(mouse)}{per},2));% * * (size(farCTraceArray{mouseNums(mouse)},1)/totalNum_farCtraces);  
            counter8 = counter8 + 1;
        end   
        if VWQ == 1
            for VWroi = 1:VWroiNum(mouse)
                for trace3 = 1:size(closeVTraceArray{mouseNums(mouse)}{VWroi}{per},1)                  
                    close_Vtraces_allMice{per}(counter5,:) = (resample(closeVTraceArray{mouseNums(mouse)}{VWroi}{per}(trace3,:),minLen,size(closeVTraceArray{mouseNums(mouse)}{VWroi}{per},2)));% * * (size(closeVTraceArray{mouseNums(mouse)}{VWroi},1)/totalNum_closeVtraces);                               
                    counter5 = counter5 + 1;
                end 
                for trace3 = 1:size(farVTraceArray{mouseNums(mouse)}{VWroi}{per},1)                    
                    far_Vtraces_allMice{per}(counter6,:) = resample(farVTraceArray{mouseNums(mouse)}{VWroi}{per}(trace3,:),minLen,size(farVTraceArray{mouseNums(mouse)}{VWroi}{per},2));% * * (size(farVTraceArray{mouseNums(mouse)}{VWroi},1)/totalNum_farVtraces);                    
                    counter6 = counter6 + 1;
                end 
                for trace3 = 1:size(VTraceArray{mouseNums(mouse)}{VWroi}{per},1)
                    Vtraces_allMice{per}(counter9,:) = resample(VTraceArray{mouseNums(mouse)}{VWroi}{per}(trace3,:),minLen,size(VTraceArray{mouseNums(mouse)}{VWroi}{per},2));% * * (size(farVTraceArray{mouseNums(mouse)}{VWroi},1)/totalNum_farVtraces);  
                    counter9 = counter9 + 1;
                end 
            end 
        end 
    end 
end 

%remove rows full of 0s/Nans if there are any b = a(any(a,2),:)
for mouse = 1:length(mouseNums)   
    for per = 1:length(allCTraces3{1}{CaROIs{1}(2)})
        if BBBQ == 1 
            for BBBroi = 1:length(BBBrois{mouse})
                close_Btraces_allMice{per} = close_Btraces_allMice{per}(any(close_Btraces_allMice{per},2),:);
                far_Btraces_allMice{per} = far_Btraces_allMice{per}(any(far_Btraces_allMice{per},2),:);
                Btraces_allMice{per} = Btraces_allMice{per}(any(Btraces_allMice{per},2),:);  
            end 
        end 
        close_Ctraces_allMice{per} = close_Ctraces_allMice{per}(any(close_Ctraces_allMice{per},2),:);
        far_Ctraces_allMice{per} = far_Ctraces_allMice{per}(any(far_Ctraces_allMice{per},2),:);
        Ctraces_allMice{per} = Ctraces_allMice{per}(any(Ctraces_allMice{per},2),:);
        if VWQ == 1
            for VWroi = 1:VWroiNum(mouse)
                close_Vtraces_allMice{per} = close_Vtraces_allMice{per}(any(close_Vtraces_allMice{per},2),:);
                far_Vtraces_allMice{per} = far_Vtraces_allMice{per}(any(far_Vtraces_allMice{per},2),:);
                Vtraces_allMice{per} = Vtraces_allMice{per}(any(Vtraces_allMice{per},2),:);
            end 
        end 
    end 
end 

% plotting code below 
close_avCdata = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
far_avCdata = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
avCdata = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
if BBBQ == 1 
    close_avBdata = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
    far_avBdata = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
    avBdata = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
end 
if VWQ == 1 
    close_avVdata = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
    far_avVdata = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
    avVdata = cell(1,length(allCTraces3{1}{CaROIs{1}(1)}));
end 
for per = 1:length(allCTraces3{1}{CaROIs{1}(2)})
    %average the data 
    if BBBQ == 1
        close_avBdata{per} = nanmean(close_Btraces_allMice{per},1);
        far_avBdata{per} = nanmean(far_Btraces_allMice{per},1);
        avBdata{per} = nanmean(Btraces_allMice{per},1);
    end 
    close_avCdata{per} = nanmean(close_Ctraces_allMice{per},1);
    far_avCdata{per} = nanmean(far_Ctraces_allMice{per},1);
    avCdata{per} = nanmean(Ctraces_allMice{per},1);
    if VWQ == 1
        close_avVdata{per} = nanmean(close_Vtraces_allMice{per},1);
        far_avVdata{per} = nanmean(far_Vtraces_allMice{per},1);
        avVdata{per} = nanmean(Vtraces_allMice{per},1);
    end 

    %DETERMINE 95% CI
    if BBBQ == 1 
        close_SEMb = (nanstd(close_Btraces_allMice{per}))/(sqrt(size(close_Btraces_allMice{per},1))); % Standard Error            
        close_ts_bLow = tinv(0.025,size(close_Btraces_allMice{per},1)-1);% T-Score for 95% CI
        close_ts_bHigh = tinv(0.975,size(close_Btraces_allMice{per},1)-1);% T-Score for 95% CI
        close_CI_bLow = (nanmean(close_Btraces_allMice{per},1)) + (close_ts_bLow*close_SEMb);  % Confidence Intervals
        close_CI_bHigh = (nanmean(close_Btraces_allMice{per},1)) + (close_ts_bHigh*close_SEMb);  % Confidence Intervals        
        far_SEMb = (nanstd(far_Btraces_allMice{per}))/(sqrt(size(far_Btraces_allMice{per},1))); % Standard Error            
        far_ts_bLow = tinv(0.025,size(far_Btraces_allMice{per},1)-1);% T-Score for 95% CI
        far_ts_bHigh = tinv(0.975,size(far_Btraces_allMice{per},1)-1);% T-Score for 95% CI
        far_CI_bLow = (nanmean(far_Btraces_allMice{per},1)) + (far_ts_bLow*far_SEMb);  % Confidence Intervals
        far_CI_bHigh = (nanmean(far_Btraces_allMice{per},1)) + (far_ts_bHigh*far_SEMb);  % Confidence Intervals
        SEMb = (nanstd(Btraces_allMice{per}))/(sqrt(size(Btraces_allMice{per},1))); % Standard Error            
        ts_bLow = tinv(0.025,size(Btraces_allMice{per},1)-1);% T-Score for 95% CI
        ts_bHigh = tinv(0.975,size(Btraces_allMice{per},1)-1);% T-Score for 95% CI
        CI_bLow = (nanmean(Btraces_allMice{per},1)) + (ts_bLow*SEMb);  % Confidence Intervals
        CI_bHigh = (nanmean(Btraces_allMice{per},1)) + (ts_bHigh*SEMb);  % Confidence Intervals
    end 
    close_SEMc = (nanstd(close_Ctraces_allMice{per}))/(sqrt(size(close_Ctraces_allMice{per},1))); % Standard Error            
    close_ts_cLow = tinv(0.025,size(close_Ctraces_allMice{per},1)-1);% T-Score for 95% CI
    close_ts_cHigh = tinv(0.975,size(close_Ctraces_allMice{per},1)-1);% T-Score for 95% CI
    close_CI_cLow = (nanmean(close_Ctraces_allMice{per},1)) + (close_ts_cLow*close_SEMc);  % Confidence Intervals
    close_CI_cHigh = (nanmean(close_Ctraces_allMice{per},1)) + (close_ts_cHigh*close_SEMc);  % Confidence Intervals   
    far_SEMc = (nanstd(far_Ctraces_allMice{per}))/(sqrt(size(far_Ctraces_allMice{per},1))); % Standard Error            
    far_ts_cLow = tinv(0.025,size(far_Ctraces_allMice{per},1)-1);% T-Score for 95% CI
    far_ts_cHigh = tinv(0.975,size(far_Ctraces_allMice{per},1)-1);% T-Score for 95% CI
    far_CI_cLow = (nanmean(far_Ctraces_allMice{per},1)) + (far_ts_cLow*far_SEMc);  % Confidence Intervals
    far_CI_cHigh = (nanmean(far_Ctraces_allMice{per},1)) + (far_ts_cHigh*far_SEMc);  % Confidence Intervals
    SEMc = (nanstd(Ctraces_allMice{per}))/(sqrt(size(Ctraces_allMice{per},1))); % Standard Error            
    ts_cLow = tinv(0.025,size(Ctraces_allMice{per},1)-1);% T-Score for 95% CI
    ts_cHigh = tinv(0.975,size(Ctraces_allMice{per},1)-1);% T-Score for 95% CI
    CI_cLow = (nanmean(Ctraces_allMice{per},1)) + (ts_cLow*SEMc);  % Confidence Intervals
    CI_cHigh = (nanmean(Ctraces_allMice{per},1)) + (ts_cHigh*SEMc);  % Confidence Intervals
    if VWQ == 1
        close_SEMv = (nanstd(close_Vtraces_allMice{per}))/(sqrt(size(close_Vtraces_allMice{per},1))); % Standard Error            
        close_ts_vLow = tinv(0.025,size(close_Vtraces_allMice{per},1)-1);% T-Score for 95% CI
        close_ts_vHigh = tinv(0.975,size(close_Vtraces_allMice{per},1)-1);% T-Score for 95% CI
        close_CI_vLow = (nanmean(close_Vtraces_allMice{per},1)) + (close_ts_vLow*close_SEMv);  % Confidence Intervals
        close_CI_vHigh = (nanmean(close_Vtraces_allMice{per},1)) + (close_ts_vHigh*close_SEMv);  % Confidence Intervals      
        far_SEMv = (nanstd(far_Vtraces_allMice{per}))/(sqrt(size(far_Vtraces_allMice{per},1))); % Standard Error            
        far_ts_vLow = tinv(0.025,size(far_Vtraces_allMice{per},1)-1);% T-Score for 95% CI
        far_ts_vHigh = tinv(0.975,size(far_Vtraces_allMice{per},1)-1);% T-Score for 95% CI
        far_CI_vLow = (nanmean(far_Vtraces_allMice{per},1)) + (far_ts_vLow*far_SEMv);  % Confidence Intervals
        far_CI_vHigh = (nanmean(far_Vtraces_allMice{per},1)) + (far_ts_vHigh*far_SEMv);  % Confidence Intervals
        SEMv = (nanstd(Vtraces_allMice{per}))/(sqrt(size(Vtraces_allMice{per},1))); % Standard Error            
        ts_vLow = tinv(0.025,size(Vtraces_allMice{per},1)-1);% T-Score for 95% CI
        ts_vHigh = tinv(0.975,size(Vtraces_allMice{per},1)-1);% T-Score for 95% CI
        CI_vLow = (nanmean(Vtraces_allMice{per},1)) + (ts_vLow*SEMv);  % Confidence Intervals
        CI_vHigh = (nanmean(Vtraces_allMice{per},1)) + (ts_vHigh*SEMv);  % Confidence Intervals
    end 

    x = 1:length(close_CI_cLow);

    % plotting code below 
    Frames = minLen;
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:min(FPSstack2):Frames_post_stim_start)/min(FPSstack2)))+1; %min(FPSstack)
    if Frames > 100
        FrameVals = round((1:min(FPSstack2):Frames))+10;
    elseif Frames < 100
        FrameVals = round((1:min(FPSstack2):Frames))+5; 
    end 
    Bcolors = [1,0,0;1,0.5,0;1,1,0];
    Ccolors = [0,0,1;0,0.5,1;0,1,1];
    Vcolors = [0,0,0;0.4,0.4,0.4;0.7,0.7,0.7];
    if dataQ == 0 
        if tTypeQ == 0 
            if per == 1 
                perLabel = ("Peaks from entire experiment. ");
            elseif per == 2 
                perLabel = ("Peaks from stimulus. ");
            elseif per == 3 
                perLabel = ("Peaks peaks from reward. ");
            elseif per == 4 
                perLabel = ("Peaks from ITI. ");
            end 
        elseif tTypeQ == 1 
            if per == 1 
                perLabel = ("Blue light on. ");
            elseif per == 2 
                perLabel = ("Red light on. ");
            elseif per == 3 
                perLabel = ("Light off. ");
            end 
        end 
    elseif dataQ == 1 
        perLabel = input('Input the per label. ');
    end 
    
    % plot close and far Ca ROI and BBB data (all mice averaged) overlaid 
    if BBBQ == 1
        fig = figure;
        ax=gca;
        hold all
        plot(close_avCdata{per},'Color',Ccolors(1,:),'LineWidth',4)
        patch([x fliplr(x)],[close_CI_cLow fliplr(close_CI_cHigh)],Ccolors(1,:),'EdgeColor','none')
        alpha(0.3)
        plot(far_avCdata{per},'Color',Ccolors(2,:),'LineWidth',4)
        patch([x fliplr(x)],[far_CI_cLow fliplr(far_CI_cHigh)],Ccolors(2,:),'EdgeColor','none')
    %     plot(avCdata,'b','LineWidth',4)
    %     patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],'b','EdgeColor','none')
        alpha(0.3)
        changePt = floor(Frames/2)-floor(0.25*min(FPSstack2));
        % plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;   
        ax.FontSize = 25;
        ax.FontName = 'Times';
        xlabel('time (s)','FontName','Times')
        ylabel('calcium signal percent change','FontName','Times')
        xLimStart = floor(10*min(FPSstack2));
        xLimEnd = floor(24*min(FPSstack2)); 
        xlim([1 minLen])
        ylim([-45 130])
        set(fig,'position', [500 100 900 800])
        alpha(0.3)
        %add right y axis tick marks for a specific DOD figure. 
        yyaxis right 
        p(1) = plot(close_avBdata{per},'Color',Bcolors(1,:),'LineWidth',4);
        patch([x fliplr(x)],[(close_CI_bLow) (fliplr(close_CI_bHigh))],Bcolors(1,:),'EdgeColor','none')
        alpha(0.3)
        p(2) = plot(far_avBdata{per},'-','Color',Bcolors(2,:),'LineWidth',4);
        patch([x fliplr(x)],[(far_CI_bLow) (fliplr(far_CI_bHigh))],Bcolors(2,:),'EdgeColor','none')
        alpha(0.3)
        legend([p(1) p(2)],'Close Terminals','Far Terminals')
        ylabel('BBB permeability percent change','FontName','Times')
        title({'All mice Averaged.';perLabel})
        ylim([-0.1 0.25])
        alpha(0.3)
        set(gca,'YColor',[0 0 0]);   

        fig = figure;
        ax=gca;
        hold all
        plot(avCdata{per},'b','LineWidth',4)
        patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],'b','EdgeColor','none')
        alpha(0.3)
        % plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;   
        ax.FontSize = 25;
        ax.FontName = 'Times';
        xlabel('time (s)','FontName','Times')
        ylabel('calcium signal percent change','FontName','Times')
        xlim([1 minLen])
    %     ylim([-45 130])
        ylim([-1 3])
        set(fig,'position', [500 100 900 800])
        alpha(0.3)
        title({'All mice Averaged.';perLabel})
        %add right y axis tick marks for a specific DOD figure. 
    %     plot(opto_allRedAVbData_3,'r:','LineWidth',4);
    %     patch([opto_x_2 fliplr(opto_x_2)],[(opto_CI_bLow_3) (fliplr(opto_CI_bHigh_3))],'r','EdgeColor','none')
    %     alpha(0.3)
    %     ylabel({'Optogenetically Triggered';'BBB Permeability Percent Change'},'FontName','Times')
        yyaxis right 
        p(1) = plot(avBdata{per},'r','LineWidth',4);
        patch([x fliplr(x)],[(CI_bLow) (fliplr(CI_bHigh))],'r','EdgeColor','none')
        alpha(0.3)
    %     plot(avBdata_redLight,'r','LineWidth',4)
    %     plot(avBdata_lightOff,'k','LineWidth',4)
    %     plot(test,'r:','LineWidth',4) % this is resampled opto data
    %     alpha(0.3)
%         plot([123 123], [-5000 5000], 'k:','LineWidth',2)  
    %     legend([p(1) p(2)],'Close Terminals','Far Terminals')
        ylabel({'Spike Triggered';'BBB Permeability Percent Change'},'FontName','Times')
    %     title({'DAT+ Axon Spike Triggered Average';'Red Light'})
        ylim([-0.1 0.25])
        set(gca,'YColor',[0 0 0]);  
    %     legend('STA Red Light','STA Light Off', 'Optogenetic ETA')
    end 

    % plot close and far Ca ROI and VW data (all mice averaged) overlaid 
    if VWQ == 1
        fig = figure;
        ax=gca;
        hold all
        plot(close_avCdata{per},'Color',Ccolors(1,:),'LineWidth',4)
        patch([x fliplr(x)],[close_CI_cLow fliplr(close_CI_cHigh)],Ccolors(1,:),'EdgeColor','none')
        alpha(0.3)
        plot(far_avCdata{per},'Color',Ccolors(2,:),'LineWidth',4)
        patch([x fliplr(x)],[far_CI_cLow fliplr(far_CI_cHigh)],Ccolors(2,:),'EdgeColor','none')
        alpha(0.3)
        changePt = floor(Frames/2)-floor(0.25*min(FPSstack2));
        % plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;   
        ax.FontSize = 25;
        ax.FontName = 'Times';
        xlabel('time (s)','FontName','Times')
        ylabel('Calcium Signal Percent Change','FontName','Times')
        xLimStart = floor(10*min(FPSstack2));
        xLimEnd = floor(24*min(FPSstack2)); 
        xlim([1 minLen])
        ylim([-10 150])
        set(fig,'position', [500 100 900 800])
        alpha(0.3)
        %add right y axis tick marks for a specific DOD figure. 
        yyaxis right 
        p(1) = plot(close_avVdata{per},'Color',Vcolors(1,:),'LineWidth',4);
        patch([x fliplr(x)],[(close_CI_vLow) (fliplr(close_CI_vHigh))],Vcolors(1,:),'EdgeColor','none')
        alpha(0.3)
        p(2) = plot(far_avVdata{per},'-','Color',Vcolors(2,:),'LineWidth',4);
        patch([x fliplr(x)],[(far_CI_vLow) (fliplr(far_CI_vHigh))],Vcolors(2,:),'EdgeColor','none')
        alpha(0.3)
        legend([p(1) p(2)],'Close Terminals','Far Terminals')
        ylabel('Vessel Width Percent Change','FontName','Times')
    %     title('Close Terminals. All mice Averaged.')
        title({'All mice Averaged.';perLabel})
        ylim([-0.02 0.02])
        alpha(0.3)
        set(gca,'YColor',[0 0 0]);   

        fig = figure;
        ax=gca;
        hold all
        plot(avCdata{per},'b','LineWidth',4)
        patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],'b','EdgeColor','none')
        alpha(0.3)
        % plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;   
        ax.FontSize = 25;
        ax.FontName = 'Times';
        xlabel('time (s)','FontName','Times')
        ylabel('Calcium Signal Percent Change','FontName','Times')
        xlim([1 minLen])
        ylim([-45 130])
        set(fig,'position', [500 100 900 800])
        alpha(0.3)
        %add right y axis tick marks for a specific DOD figure. 
        yyaxis right 
        p(1) = plot(avVdata{per},'k','LineWidth',4);
        patch([x fliplr(x)],[(CI_vLow) (fliplr(CI_vHigh))],'k','EdgeColor','none')
        alpha(0.3)
    %     legend([p(1) p(2)],'Close Terminals','Far Terminals')
        ylabel('Vessel Width Percent Change','FontName','Times')
    %     title('Close Terminals. All mice Averaged.')
        title({'All mice Averaged.';perLabel})
        ylim([-0.1 0.25])
        alpha(0.3)
        set(gca,'YColor',[0 0 0]);   
    end 
end 

%}
%% STA 2: plot calcium spike triggered averages (this can plot traces within 2 std from the mean, but all data gets stored)
% takes already smooothed/normalized data 
% this assumes you are averaging, asks how many different groups you want
% to average, and then plots multiple averages overlaid on the same figure. This generates figures for all BBB and VW ROIs at once 
% updated so that you can plot multiple STAs for spikes taken from
% different parts of the behavior (tType == 0) (ITI, stim, and reward)
%{
%define how many groups you want to create average traces for and what Ca
%ROIs fall into these groups 
numGroups = input('How many groups do you want to average? ');
terms = cell(1,length(numGroups)); 
for groupNum = 1:numGroups
    terms{groupNum} = input(sprintf('Input the Ca ROIs you want to average for group #%d. ',groupNum));
end 

%initialize arrays 
AVSNCdataPeaks = cell(1,numGroups);
AVSNCdataPeaks2 = cell(1,numGroups);
AVSNCdataPeaks3 = cell(1,numGroups); 

BBBQ = input('Input 1 if you want to plot BBB data. ');
if BBBQ == 1
    BBBroiQ1 = input('Input 1 if you want to plot all BBB ROIs. Input 0 otherwise. '); 
    if BBBroiQ1 == 1
        BBBrois = 1:length(sortedBdata{1});
    elseif BBBroiQ1 == 0 
        BBBrois = input('Input the BBB ROIs you want to plot. ');
    end 
    AVSNBdataPeaks = cell(1,numGroups);
    AVSNBdataPeaks2 = cell(1,numGroups);
    AVSNBdataPeaks3 = cell(1,numGroups); 
end 

VWQ = input('Input 1 if you want to plot vessel width data. ');
if VWQ == 1
    AVSNVdataPeaks = cell(1,numGroups);
    AVSNVdataPeaks2 = cell(1,numGroups);
    AVSNVdataPeaks3 = cell(1,numGroups); 
end 

saveQ = input('Input 1 to save the figures. Input 0 otherwise. ');
if saveQ == 1                
    dir1 = input('What folder are you saving these images in? ');
end 

if tTypeQ == 0 
    %{
    allCTraces = cell(1,numGroups);
    CTraces = cell(1,numGroups);
    if BBBQ == 1
        allBTraces = cell(1,numGroups);
        BTraces = cell(1,numGroups);
    end 
    if VWQ == 1
        allVTraces = cell(1,numGroups);
        VTraces = cell(1,numGroups);
    end 
    for groupNum = 1:numGroups
        for ccell = 1:length(terms{groupNum})     
            for per = 1:length(sortedCdata{vid}{terminals(ccell)})
                if isempty(sortedCdata2{vid}{terminals(ccell)}{per}) == 0 
                    count1 = 1;
                    % sort C data
                    for vid = 1:length(vidList)   
                        if isempty(sortedCdata{vid}{terms{groupNum}(ccell)}) == 0
                            for peak = 1:size(SNCdataPeaks{vid}{terms{groupNum}(ccell)}{per},1) 
                                allCTraces{groupNum}{terms{groupNum}(ccell)}{per}(count1,:) = (SNCdataPeaks{vid}{terms{groupNum}(ccell)}{per}(peak,:)-100);
                                count1 = count1 + 1;
                            end 
                            %remove rows full of 0s if there are any b = a(any(a,2),:)
                            allCTraces{groupNum}{terms{groupNum}(ccell)}{per} = allCTraces{groupNum}{terms{groupNum}(ccell)}{per}(any(allCTraces{groupNum}{terms{groupNum}(ccell)}{per},2),:);
                        end
                    end     

                    % sort B data
                    if BBBQ == 1
                        for BBBroi = 1:length(BBBrois)
                            count2 = 1;
                            for vid = 1:length(vidList)  
                                if isempty(sortedBdata{vid}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}) == 0
                                    for peak = 1:size(SNCdataPeaks{vid}{terms{groupNum}(ccell)}{per},1) 
                                        allBTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per}(count2,:) = (SNBdataPeaks{vid}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per}(peak,:)-100); 
                                        count2 = count2 + 1;
                                    end
                                    %remove rows full of 0s if there are any b = a(any(a,2),:)
                                    allBTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per} = allBTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per}(any(allBTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per},2),:);
                                end
                            end 
                        end 
                    end 

                    % sort V data
                    if VWQ == 1
                        for VWroi = 1:length(sortedVdata{1})
                            count3 = 1;
                            for vid = 1:length(vidList)     
                                if isempty(sortedVdata{vid}{VWroi}{terms{groupNum}(ccell)}) == 0
                                    for peak = 1:size(SNCdataPeaks{vid}{terms{groupNum}(ccell)}{per},1) 
                                        allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per}(count3,:) = (SNVdataPeaks{vid}{VWroi}{terms{groupNum}(ccell)}{per}(peak,:)-100); 
                                        count3 = count3 + 1;
                                    end 
                                    %remove rows full of 0s if there are any b = a(any(a,2),:)
                                    allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per} = allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per}(any(allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per},2),:);
                                end
                            end 
                        end 
                    end 

                    %get averages of all traces 
                    if BBBQ == 1
                        for BBBroi = 1:length(BBBrois)
                            if isempty(sortedBdata{vid}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}) == 0
                                AVSNBdataPeaks2{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per} = (nanmean(allBTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per}));
                            end 
                        end 
                    end 
                    if isempty(sortedCdata{vid}{terms{groupNum}(ccell)}) == 0
                        AVSNCdataPeaks2{groupNum}{terms{groupNum}(ccell)}{per} = nanmean(allCTraces{groupNum}{terms{groupNum}(ccell)}{per});
                    end 
                    if VWQ == 1
                        for VWroi = 1:length(sortedVdata{1})
                            if isempty(sortedVdata{vid}{VWroi}{terms{groupNum}(ccell)}) == 0
                                AVSNVdataPeaks2{groupNum}{VWroi}{terms{groupNum}(ccell)}{per} = (nanmean(allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per}));
                            end 
                        end 
                    end 

                    %remove traces that are outliers 
                    %statistically (greater than 2 standard deviations from the
                    %mean 
                    count2 = 1; 
                    count3 = 1;
                    count4 = 1;
                    if isempty(sortedCdata{vid}{terms{groupNum}(ccell)}) == 0
                        for peak = 1:size(allCTraces{groupNum}{terms{groupNum}(ccell)}{per},1)
                            if BBBQ == 1
                                for BBBroi = 1:length(BBBrois)
                                    if isempty(sortedBdata{vid}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}) == 0
                %                         if allBTraces{groupNum}{BBBroi}{terms{groupNum}(ccell)}(peak,:) < AVSNBdataPeaks2{groupNum}{BBBroi}{terms{groupNum}(ccell)} + nanstd(allBTraces{groupNum}{BBBroi}{terms{groupNum}(ccell)},1)*2  & allBTraces{groupNum}{BBBroi}{terms{groupNum}(ccell)}(peak,:) > AVSNBdataPeaks2{groupNum}{BBBroi}{terms{groupNum}(ccell)} - nanstd(allBTraces{groupNum}{BBBroi}{terms{groupNum}(ccell)},1)*2               
                                            BTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per}(count2,:) = (allBTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per}(peak,:));
                                            count2 = count2 + 1;
                %                         end 
                                    %remove rows full of zeros if there are any b = a(any(a,2),:)
                                    BTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per} = BTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per}(any(BTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per},2),:);
                                    end 
                                end 
                            end 

            %                     if allCTraces{groupNum}{terms{groupNum}(ccell)}(peak,:) < AVSNCdataPeaks2{groupNum}{terms{groupNum}(ccell)} + nanstd(allCTraces{groupNum}{terms{groupNum}(ccell)},1)*2 & allCTraces{groupNum}{terms{groupNum}(ccell)}(peak,:) > AVSNCdataPeaks2{groupNum}{terms{groupNum}(ccell)} - nanstd(allCTraces{groupNum}{terms{groupNum}(ccell)},1)*2                      
                                    CTraces{groupNum}{terms{groupNum}(ccell)}{per}(count3,:) = (allCTraces{groupNum}{terms{groupNum}(ccell)}{per}(peak,:));
                                    count3 = count3 + 1;
                                    %remove rows full of zeros if there are any b = a(any(a,2),:)
                                    CTraces{groupNum}{terms{groupNum}(ccell)}{per} = CTraces{groupNum}{terms{groupNum}(ccell)}{per}(any(CTraces{groupNum}{terms{groupNum}(ccell)}{per},2),:);
            %                     end 

                            if VWQ == 1
                                for VWroi = 1:length(sortedVdata{1})
                                    if isempty(sortedVdata{vid}{VWroi}{terms{groupNum}(ccell)}) == 0
                %                         if allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}(peak,:) < AVSNVdataPeaks2{groupNum}{VWroi}{terms{groupNum}(ccell)} + nanstd(allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)},1)*2 & allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}(peak,:) > AVSNVdataPeaks2{groupNum}{VWroi}{terms{groupNum}(ccell)} - nanstd(allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)},1)*2              
                                            VTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per}(count4,:) = (allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per}(peak,:));
                                            count4 = count4 + 1;
                                            %remove rows full of zeros if there are any b = a(any(a,2),:)
                                            VTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per} = VTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per}(any(VTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per},2),:);
                %                         end 
                                    end 
                                end 
                            end 
                        end
                    end 

                    % get the average of all the traces excluding outliers 
                    if BBBQ == 1
                        for BBBroi = 1:length(BBBrois)
                            if isempty(sortedBdata{vid}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}) == 0
                                AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per}(ccell,:) = (nanmean(BTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per}));
                            end 
                        end 
                    end 
                    if isempty(sortedCdata{vid}{terms{groupNum}(ccell)}) == 0
                        AVSNCdataPeaks3{groupNum}{per}(ccell,:) = nanmean(CTraces{groupNum}{terms{groupNum}(ccell)}{per});
                    end 
                    if VWQ == 1
                        for VWroi = 1:length(sortedVdata{1})
                            if isempty(sortedVdata{vid}{VWroi}{terms{groupNum}(ccell)}) == 0
                                AVSNVdataPeaks3{groupNum}{VWroi}{per}(ccell,:) = (nanmean(VTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per}));
                            end 
                        end 
                    end   
                end 
            end 
        end    
    end 
    
    
        


    Frames = size(AVSNCdataPeaks3{groupNum}{1},2);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack))+1;
    if Frames > 100
        FrameVals = round((1:FPSstack:Frames))+11;
    elseif Frames < 100
        FrameVals = round((1:FPSstack:Frames))+5; 
    end 
    if BBBQ == 1
        for BBBroi = 1:length(BBBrois)
            for per = 1:length(sortedCdata{vid}{terminals(ccell)})
                if isempty(sortedCdata2{vid}{terminals(ccell)}{per}) == 0 
                    fig = figure;
                    ax=gca;
                    hold all

                    CI_bLow = cell(1,numGroups);
                    CI_bHigh = cell(1,numGroups);
                    CI_cLow = cell(1,numGroups);
                    CI_cHigh = cell(1,numGroups);
                    for groupNum = 1:numGroups
                        %DETERMINE 95% CI            
                        SEMb = (nanstd(AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per})/(sqrt(size(AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per},1)))); % Standard Error            
                        ts_bLow = tinv(0.025,size(AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per},1)-1);% T-Score for 95% CI
                        ts_bHigh = tinv(0.975,size(AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per},1)-1);% T-Score for 95% CI
                        CI_bLow{groupNum} = (nanmean(AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per},1)) + (ts_bLow*SEMb);  % Confidence Intervals
                        CI_bHigh{groupNum} = (nanmean(AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per},1)) + (ts_bHigh*SEMb);  % Confidence Intervals

                        SEMc = (nanstd(AVSNCdataPeaks3{groupNum}{per}))/(sqrt(size(AVSNCdataPeaks3{groupNum}{per},1))); % Standard Error            
                        ts_cLow = tinv(0.025,size(AVSNCdataPeaks3{groupNum}{per},1)-1);% T-Score for 95% CI
                        ts_cHigh = tinv(0.975,size(AVSNCdataPeaks3{groupNum}{per},1)-1);% T-Score for 95% CI
                        CI_cLow{groupNum} = (nanmean(AVSNCdataPeaks3{groupNum}{per},1)) + (ts_cLow*SEMc);  % Confidence Intervals
                        CI_cHigh{groupNum} = (nanmean(AVSNCdataPeaks3{groupNum}{per},1)) + (ts_cHigh*SEMc);  % Confidence Intervals

                        x = 1:length(CI_cLow{groupNum});

                        %average across terminals 
                        if length(terms{groupNum}) > 1 
                            AVSNCdataPeaks{groupNum}{per} = nanmean(AVSNCdataPeaks3{groupNum}{per});
                            AVSNBdataPeaks{groupNum}{BBBrois(BBBroi)}{per} = nanmean(AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per});
                        elseif length(terms{groupNum}) == 1
                            AVSNCdataPeaks{groupNum}{per} = AVSNCdataPeaks3{groupNum}{per};
                            AVSNBdataPeaks{groupNum}{BBBrois(BBBroi)}{per} = AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per};
                        end 
                    end 

                    % plot 
                    Ccolors = [0,0,1;0,0.5,1;0,1,1];
                    for groupNum = 1:numGroups
                        plot(AVSNCdataPeaks{groupNum}{per},'Color',Ccolors(groupNum,:),'LineWidth',4)
                        patch([x fliplr(x)],[CI_cLow{groupNum} fliplr(CI_cHigh{groupNum})],Ccolors(groupNum,:),'EdgeColor','none')
                        alpha(0.3)
                    end 
                %         plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
                    ax.XTick = FrameVals;
                    ax.XTickLabel = sec_TimeVals;   
                    ax.FontSize = 25;
                    ax.FontName = 'Times';
                    xlabel('time (s)','FontName','Times')
                    ylabel('calcium signal percent change','FontName','Times')
                    xLimStart = floor(10*FPSstack);
                    xLimEnd = floor(24*FPSstack); 
                    xlim([1 size(AVSNCdataPeaks{1}{1},2)])
                    ylim([-60 100])          
                    set(fig,'position', [500 100 900 800])

                    yyaxis right   
                    Bcolors = [1,0,0;1,0.5,0;1,1,0];
                    p = zeros(1,numGroups);
                    for groupNum = 1:numGroups
                        p(groupNum) = plot(AVSNBdataPeaks{groupNum}{BBBrois(BBBroi)}{per},'Color',Bcolors(groupNum,:),'LineWidth',4,'LineStyle','-');
                        patch([x fliplr(x)],[CI_bLow{groupNum} (fliplr(CI_bHigh{groupNum}))],Bcolors(groupNum,:),'EdgeColor','none')
                        alpha(0.3)
                    end 
                    legend([p(1) p(2)],'Close Terminals','Far Terminals')
                    ylabel('BBB permeability percent change','FontName','Times')
                    if per == 1 
                        perLabel = ("Peaks from entire experiment. ");
                    elseif per == 2 
                        perLabel = ("Peaks from stimulus. ");
                    elseif per == 3 
                        perLabel = ("Peaks peaks from reward. ");
                    elseif per == 4 
                        perLabel = ("Peaks from ITI. ");
                    end 
                    title({sprintf('All Terminals Averaged. BBB ROI %d.',BBBrois(BBBroi));perLabel})
                    alpha(0.3)
                    set(gca,'YColor',[0 0 0]);
                    %make the directory and save the images   
                    if saveQ == 1  
                        dir2 = strrep(dir1,'\','/');
                        dir3 = sprintf('%s/%s.tif',dir2,tlabel);
                        export_fig(dir3)
                    end      
                end 
            end 
        end 
    end 

    if VWQ == 1
        for VWroi = 1:length(sortedVdata{1})
            for per = 1:length(sortedCdata{vid}{terminals(ccell)})
                if isempty(sortedCdata2{vid}{terminals(ccell)}{per}) == 0 
                    fig = figure; 
                    ax=gca;
                    hold all

                    CI_cLow = cell(1,numGroups);
                    CI_cHigh = cell(1,numGroups);
                    CI_vLow = cell(1,numGroups);
                    CI_vHigh = cell(1,numGroups);
                    for groupNum = 1:numGroups
                        %DETERMINE 95% CI            
                        SEMc = (nanstd(AVSNCdataPeaks3{groupNum}{per}))/(sqrt(size(AVSNCdataPeaks3{groupNum}{per},1))); % Standard Error            
                        ts_cLow = tinv(0.025,size(AVSNCdataPeaks3{groupNum}{per},1)-1);% T-Score for 95% CI
                        ts_cHigh = tinv(0.975,size(AVSNCdataPeaks3{groupNum}{per},1)-1);% T-Score for 95% CI
                        CI_cLow{groupNum} = (nanmean(AVSNCdataPeaks3{groupNum}{per},1)) + (ts_cLow*SEMc);  % Confidence Intervals
                        CI_cHigh{groupNum} = (nanmean(AVSNCdataPeaks3{groupNum}{per},1)) + (ts_cHigh*SEMc);  % Confidence Intervals

                        SEMv = (nanstd(AVSNVdataPeaks3{groupNum}{VWroi}{per}))/(sqrt(size(AVSNVdataPeaks3{groupNum}{VWroi}{per},1))); % Standard Error            
                        ts_vLow = tinv(0.025,size(AVSNVdataPeaks3{groupNum}{VWroi}{per},1)-1);% T-Score for 95% CI
                        ts_vHigh = tinv(0.975,size(AVSNVdataPeaks3{groupNum}{VWroi}{per},1)-1);% T-Score for 95% CI
                        CI_vLow{groupNum} = (nanmean(AVSNVdataPeaks3{groupNum}{VWroi}{per},1)) + (ts_vLow*SEMv);  % Confidence Intervals
                        CI_vHigh{groupNum} = (nanmean(AVSNVdataPeaks3{groupNum}{VWroi}{per},1)) + (ts_vHigh*SEMv);  % Confidence Intervals

                        x = 1:length(CI_cLow{groupNum});

                        %average across terminals 
                        if length(terms{groupNum}) > 1 
                            AVSNCdataPeaks{groupNum}{per} = nanmean(AVSNCdataPeaks3{groupNum}{per});
                            AVSNVdataPeaks{groupNum}{VWroi}{per} = nanmean(AVSNVdataPeaks3{groupNum}{VWroi}{per});
                        elseif length(terms{groupNum}) == 1
                            AVSNCdataPeaks{groupNum}{per} = AVSNCdataPeaks3{groupNum}{per};
                            AVSNVdataPeaks{groupNum}{VWroi}{per} = AVSNVdataPeaks3{groupNum}{VWroi}{per};
                        end 
                    end 
                    % plot 
                    Ccolors = [0,0,1;0,0.5,1;0,1,1];
                    for groupNum = 1:numGroups
                        plot(AVSNCdataPeaks{groupNum}{per},'Color',Ccolors(groupNum,:),'LineWidth',4)
                        patch([x fliplr(x)],[CI_cLow{groupNum} fliplr(CI_cHigh{groupNum})],Ccolors(groupNum,:),'EdgeColor','none')
                        alpha(0.3)
                    end 
                %         plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
                    ax.XTick = FrameVals;
                    ax.XTickLabel = sec_TimeVals;   
                    ax.FontSize = 25;
                    ax.FontName = 'Times';
                    xlabel('time (s)','FontName','Times')
                    ylabel('calcium signal percent change','FontName','Times')
                    xLimStart = floor(10*FPSstack);
                    xLimEnd = floor(24*FPSstack); 
                    xlim([1 size(AVSNCdataPeaks{1}{1},2)])
                    ylim([-60 100])          
                    set(fig,'position', [500 100 900 800])

                    yyaxis right   
                    Vcolors = [0,0,0;0.4,0.4,0.4;0.7,0.7,0.7];
                    p = zeros(1,numGroups);
                    for groupNum = 1:numGroups
                        p(groupNum) = plot(AVSNVdataPeaks{groupNum}{VWroi}{per},'Color',Vcolors(groupNum,:),'LineWidth',4,'LineStyle','-');
                        patch([x fliplr(x)],[CI_vLow{groupNum} (fliplr(CI_vHigh{groupNum}))],Vcolors(groupNum,:),'EdgeColor','none')
                        alpha(0.3)
                    end 
                    legend([p(1) p(2)],'Close Terminals','Far Terminals')
                    ylabel('vessel width percent change','FontName','Times')
                    if per == 1 
                        perLabel = ("Peaks from entire experiment. ");
                    elseif per == 2 
                        perLabel = ("Peaks from stimulus. ");
                    elseif per == 3 
                        perLabel = ("Peaks peaks from reward. ");
                    elseif per == 4 
                        perLabel = ("Peaks from ITI. ");
                    end 
                    title({sprintf('All Terminals Averaged. VW ROI %d.',VWroi);perLabel})      
                    alpha(0.3)
                    set(gca,'YColor',[0 0 0]);
                    %make the directory and save the images   
                    if saveQ == 1  
                        dir2 = strrep(dir1,'\','/');
                        dir3 = sprintf('%s/%s.tif',dir2,tlabel);
                        export_fig(dir3)
                    end      
                end 
            end 
        end 
    end
    
    %}
elseif tTypeQ == 1
    %{
    allCTraces = cell(1,numGroups);
    CTraces = cell(1,numGroups);
    if BBBQ == 1
        allBTraces = cell(1,numGroups);
        BTraces = cell(1,numGroups);
    end 
    if VWQ == 1
        allVTraces = cell(1,numGroups);
        VTraces = cell(1,numGroups);
    end 

    for groupNum = 1:numGroups
        for ccell = 1:length(terms{groupNum})    
            for per = 2:3 
                count1 = 1;
                % sort C data
                for vid = 1:length(vidList)      
                    if isempty(sortedCdata{vid}{terms{groupNum}(ccell)}) == 0 && per <= size(sortedCdata{vid}{terms{groupNum}(ccell)},2)
                        if isempty(sortedCdata{vid}{terms{groupNum}(ccell)}{per}) == 0 %sortedCdata{vid}{terminals(ccell)}{per}(peak,:)
                            for peak = 1:size(SNCdataPeaks{vid}{terms{groupNum}(ccell)}{per},1) %SNCdataPeaks{vid}{terminals(ccell)}{per}
                                allCTraces{groupNum}{terms{groupNum}(ccell)}{per}(count1,:) = (SNCdataPeaks{vid}{terms{groupNum}(ccell)}{per}(peak,:)-100); 
                                count1 = count1 + 1;
                            end 
                        end
                    end 
                end         
                %remove rows full of 0s if there are any b = a(any(a,2),:)
                allCTraces{groupNum}{terms{groupNum}(ccell)}{per} = allCTraces{groupNum}{terms{groupNum}(ccell)}{per}(any(allCTraces{groupNum}{terms{groupNum}(ccell)}{per},2),:);
                % sort B data
                if BBBQ == 1
                    for BBBroi = 1:length(BBBrois)
                        count2 = 1;
                        for vid = 1:length(vidList)    
                            if isempty(sortedBdata{vid}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}) == 0 && per <= size(sortedCdata{vid}{terms{groupNum}(ccell)},2)
                                if isempty(sortedBdata{vid}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per}) == 0
                                    for peak = 1:size(SNCdataPeaks{vid}{terms{groupNum}(ccell)}{per},1) 
                                        allBTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per}(count2,:) = (SNBdataPeaks{vid}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per}(peak,:)-100); 
                                        count2 = count2 + 1;
                                    end 
                                end
                            end 
                        end
                        %remove rows full of 0s if there are any b = a(any(a,2),:)
                        allBTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per} = allBTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per}(any(allBTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per},2),:);
                    end 
                end 

                % sort V data
                if VWQ == 1
                    for VWroi = 1:length(sortedVdata{1})
                        count3 = 1;
                        for vid = 1:length(vidList) 
                            if isempty(sortedVdata{vid}{VWroi}{terms{groupNum}(ccell)}) == 0 && per <= size(sortedCdata{vid}{terms{groupNum}(ccell)},2)
                                if isempty(sortedVdata{vid}{VWroi}{terms{groupNum}(ccell)}{per}) == 0
                                    for peak = 1:size(SNCdataPeaks{vid}{terms{groupNum}(ccell)}{per},1) 
                                        allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per}(count3,:) = (SNVdataPeaks{vid}{VWroi}{terms{groupNum}(ccell)}{per}(peak,:)-100); 
                                        count3 = count3 + 1;
                                    end 
                                end
                            end 
                        end 
                        %remove rows full of 0s if there are any b = a(any(a,2),:)
                        allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per} = allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per}(any(allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per},2),:);
                    end 
                end             

                %get averages of all traces 
                if BBBQ == 1
                    for BBBroi = 1:length(BBBrois)
                        AVSNBdataPeaks2{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per} = (nanmean(allBTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per}));
                    end 
                end 
                AVSNCdataPeaks2{groupNum}{terms{groupNum}(ccell)}{per} = nanmean(allCTraces{groupNum}{terms{groupNum}(ccell)}{per});
                if VWQ == 1
                    for VWroi = 1:length(sortedVdata{1})
                        AVSNVdataPeaks2{groupNum}{VWroi}{terms{groupNum}(ccell)}{per} = (nanmean(allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per}));
                    end 
                end                         

                %remove traces that are outliers 
                %statistically (greater than 2 standard deviations from the
                %mean 
                count2 = 1; 
                count3 = 1;
                count4 = 1;
                for peak = 1:size(allCTraces{groupNum}{terms{groupNum}(ccell)}{per},1)
                    if BBBQ == 1
                        for BBBroi = 1:length(BBBrois)
    %                         if allBTraces{groupNum}{BBBroi}{terms{groupNum}(ccell)}{per}(peak,:) < AVSNBdataPeaks2{groupNum}{BBBroi}{terms{groupNum}(ccell)}{per} + nanstd(allBTraces{groupNum}{BBBroi}{terms{groupNum}(ccell)}{per},1)*2  & allBTraces{groupNum}{BBBroi}{terms{groupNum}(ccell)}{per}(peak,:) > AVSNBdataPeaks2{groupNum}{BBBroi}{terms{groupNum}(ccell)}{per} - nanstd(allBTraces{groupNum}{BBBroi}{terms{groupNum}(ccell)}{per},1)*2               
                                BTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per}(count2,:) = (allBTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per}(peak,:));
                                count2 = count2 + 1;
                                %remove rows full of zeros if there are any b = a(any(a,2),:)
                                BTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per} = BTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per}(any(BTraces{groupNum}{BBBrois(BBBroi)}{terms{groupNum}(ccell)}{per},2),:);
    %                         end 
                        end 
                    end 
    %                     if allCTraces{groupNum}{terms{groupNum}(ccell)}{per}(peak,:) < AVSNCdataPeaks2{groupNum}{terms{groupNum}(ccell)}{per} + nanstd(allCTraces{groupNum}{terms{groupNum}(ccell)}{per},1)*2 & allCTraces{groupNum}{terms{groupNum}(ccell)}{per}(peak,:) > AVSNCdataPeaks2{groupNum}{terms{groupNum}(ccell)}{per} - nanstd(allCTraces{groupNum}{terms{groupNum}(ccell)}{per},1)*2                      
                            CTraces{groupNum}{terms{groupNum}(ccell)}{per}(count3,:) = (allCTraces{groupNum}{terms{groupNum}(ccell)}{per}(peak,:));
                            count3 = count3 + 1;
                            %remove rows full of zeros if there are any b = a(any(a,2),:)
                            CTraces{groupNum}{terms{groupNum}(ccell)}{per} = CTraces{groupNum}{terms{groupNum}(ccell)}{per}(any(CTraces{groupNum}{terms{groupNum}(ccell)}{per},2),:);
    %                     end 
                    if VWQ == 1
                        for VWroi = 1:length(sortedVdata{1})
    %                         if allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per}(peak,:) < AVSNVdataPeaks2{groupNum}{VWroi}{terms{groupNum}(ccell)}{per} + nanstd(allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per},1)*2 & allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per}(peak,:) > AVSNVdataPeaks2{groupNum}{VWroi}{terms{groupNum}(ccell)}{per} - nanstd(allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per},1)*2              
                                VTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per}(count4,:) = (allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per}(peak,:));
                                count4 = count4 + 1;
                                %remove rows full of zeros if there are any b = a(any(a,2),:)
                                VTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per} = VTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per}(any(VTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}{per},2),:);
    %                         end 
                        end 
                    end 
                end
            end 
        end 
    end 
    % get the average of all the traces excluding outliers 
    for groupNum = 1:numGroups
        for per = 2:3 
            if BBBQ == 1
                for BBBroi = 1:length(BBBrois)
                    %identify what Ca ROIs are left (this is important if
                    %traces where statistically removed 
                    BcaROIs = find(~cellfun(@isempty,BTraces{groupNum}{BBBrois(BBBroi)}));
                    for ccell = 1:length(BcaROIs) 
                        if size(BTraces{groupNum}{BBBrois(BBBroi)}{BcaROIs(ccell)}{per},1) > 1 
                            AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per}(ccell,:) = nanmean(BTraces{groupNum}{BBBrois(BBBroi)}{BcaROIs(ccell)}{per});
                        elseif size(BTraces{groupNum}{BBBrois(BBBroi)}{BcaROIs(ccell)}{per},1) == 1 
                            AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per}(ccell,:) = BTraces{groupNum}{BBBrois(BBBroi)}{BcaROIs(ccell)}{per};
                        end 
                    end 
                end 
            end 
            %identify what Ca ROIs are left (this is important if
            %traces where statistically removed 
            CcaROIs = find(~cellfun(@isempty,CTraces{groupNum}));
            for ccell = 1:length(CcaROIs) 
                if size(CTraces{groupNum}{CcaROIs(ccell)}{per},1) > 1 
                    AVSNCdataPeaks3{groupNum}{per}(ccell,:) = nanmean(CTraces{groupNum}{CcaROIs(ccell)}{per});
                elseif size(CTraces{groupNum}{CcaROIs(ccell)}{per},1) == 1 
                    AVSNCdataPeaks3{groupNum}{per}(ccell,:) = CTraces{groupNum}{CcaROIs(ccell)}{per};
                end 
            end 
            if VWQ == 1
                for VWroi = 1:length(sortedVdata{1})
                    %identify what Ca ROIs are left (this is important if
                    %traces where statistically removed 
                    VcaROIs = find(~cellfun(@isempty,VTraces{groupNum}{VWroi}));
                    for ccell = 1:length(VcaROIs) 
                        if size(VTraces{groupNum}{VWroi}{VcaROIs(ccell)}{per},1) > 1 
                            AVSNVdataPeaks3{groupNum}{VWroi}{per}(ccell,:) = nanmean(VTraces{groupNum}{VWroi}{VcaROIs(ccell)}{per});
                        elseif size(VTraces{groupNum}{VWroi}{VcaROIs(ccell)}{per},1) == 1 
                            AVSNVdataPeaks3{groupNum}{VWroi}{per}(ccell,:) = VTraces{groupNum}{VWroi}{VcaROIs(ccell)}{per};
                        end 
                    end 
                end 
            end   
        end 
    end 
    
    Frames = size(AVSNCdataPeaks3{groupNum}{per},2);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack))+1;
    if Frames > 100
        FrameVals = round((1:FPSstack:Frames))+11;
    elseif Frames < 100
        FrameVals = round((1:FPSstack:Frames))+5; 
    end 
    
    if BBBQ == 1
        for BBBroi = 1:length(BBBrois)
            for per = 2:3 
                fig = figure;
                ax=gca;
                hold all

                CI_bLow = cell(1,numGroups);
                CI_bHigh = cell(1,numGroups);
                CI_cLow = cell(1,numGroups);
                CI_cHigh = cell(1,numGroups);
                for groupNum = 1:numGroups
                    %DETERMINE 95% CI            
                    SEMb = (nanstd(AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per})/(sqrt(size(AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per},1)))); % Standard Error            
                    ts_bLow = tinv(0.025,size(AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per},1)-1);% T-Score for 95% CI
                    ts_bHigh = tinv(0.975,size(AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per},1)-1);% T-Score for 95% CI
                    CI_bLow{groupNum}{per} = (nanmean(AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per},1)) + (ts_bLow*SEMb);  % Confidence Intervals
                    CI_bHigh{groupNum}{per} = (nanmean(AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per},1)) + (ts_bHigh*SEMb);  % Confidence Intervals

                    SEMc = (nanstd(AVSNCdataPeaks3{groupNum}{per}))/(sqrt(size(AVSNCdataPeaks3{groupNum}{per},1))); % Standard Error            
                    ts_cLow = tinv(0.025,size(AVSNCdataPeaks3{groupNum}{per},1)-1);% T-Score for 95% CI
                    ts_cHigh = tinv(0.975,size(AVSNCdataPeaks3{groupNum}{per},1)-1);% T-Score for 95% CI
                    CI_cLow{groupNum}{per} = (nanmean(AVSNCdataPeaks3{groupNum}{per},1)) + (ts_cLow*SEMc);  % Confidence Intervals
                    CI_cHigh{groupNum}{per} = (nanmean(AVSNCdataPeaks3{groupNum}{per},1)) + (ts_cHigh*SEMc);  % Confidence Intervals

                    x = 1:length(CI_cLow{groupNum}{per});

                    %average across terminals
                    if size(AVSNCdataPeaks3{groupNum}{per},1) > 1 
                        AVSNCdataPeaks{groupNum}{per} = nanmean(AVSNCdataPeaks3{groupNum}{per});
                        AVSNBdataPeaks{groupNum}{BBBrois(BBBroi)}{per} = nanmean(AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per});
                    elseif size(AVSNCdataPeaks3{groupNum}{per},1) == 1
                        AVSNCdataPeaks{groupNum}{per} = (AVSNCdataPeaks3{groupNum}{per});
                        AVSNBdataPeaks{groupNum}{BBBrois(BBBroi)}{per} = (AVSNBdataPeaks3{groupNum}{BBBrois(BBBroi)}{per});
                    end 
                end 

                % plot 
                Ccolors = [0,0,1;0,0.5,1;0,1,1];
                for groupNum = 1:numGroups
                    plot(AVSNCdataPeaks{groupNum}{per},'Color',Ccolors(groupNum,:),'LineWidth',4)
                    patch([x fliplr(x)],[CI_cLow{groupNum}{per} fliplr(CI_cHigh{groupNum}{per})],Ccolors(groupNum,:),'EdgeColor','none')
                    alpha(0.3)
                end 
            %         plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
                ax.XTick = FrameVals;
                ax.XTickLabel = sec_TimeVals;   
                ax.FontSize = 25;
                ax.FontName = 'Times';
                xlabel('time (s)','FontName','Times')
                ylabel('calcium signal percent change','FontName','Times')
                xLimStart = floor(10*FPSstack);
                xLimEnd = floor(24*FPSstack); 
                xlim([1 size(AVSNCdataPeaks{1}{per},2)])
                ylim([-60 100])          
                set(fig,'position', [500 100 900 800])

                yyaxis right   
                Bcolors = [1,0,0;1,0.5,0;1,1,0];
                p = zeros(1,numGroups);
                for groupNum = 1:numGroups
                    p(groupNum) = plot(AVSNBdataPeaks{groupNum}{BBBrois(BBBroi)}{per},'Color',Bcolors(groupNum,:),'LineWidth',4,'LineStyle','-');
                    patch([x fliplr(x)],[CI_bLow{groupNum}{per} (fliplr(CI_bHigh{groupNum}{per}))],Bcolors(groupNum,:),'EdgeColor','none')
                    alpha(0.3)
                end 
                legend([p(1) p(2)],'Close Terminals','Far Terminals')
                ylabel('BBB permeability percent change','FontName','Times')
                if per == 1 
                    perLabel = "Blue Light On";
                elseif per == 2
                    perLabel = "Red Light On";
                elseif per == 3
                    perLabel = "Light Off";
                end 
                title({sprintf('All Terminals Averaged. BBB ROI %d.',BBBrois(BBBroi));perLabel})
                alpha(0.3)
                set(gca,'YColor',[0 0 0]);
                %make the directory and save the images   
                if saveQ == 1  
                    dir2 = strrep(dir1,'\','/');
                    dir3 = sprintf('%s/%s.tif',dir2,tlabel);
                    export_fig(dir3)
                end     
            end 
        end 
    end 

    if VWQ == 1
        for VWroi = 1:length(sortedVdata{1})
            for per = 2:3 
                fig = figure;
                ax=gca;
                hold all

                CI_cLow = cell(1,numGroups);
                CI_cHigh = cell(1,numGroups);
                CI_vLow = cell(1,numGroups);
                CI_vHigh = cell(1,numGroups);
                for groupNum = 1:numGroups
                    %DETERMINE 95% CI            
                    SEMc = (nanstd(AVSNCdataPeaks3{groupNum}{per}))/(sqrt(size(AVSNCdataPeaks3{groupNum}{per},1))); % Standard Error            
                    ts_cLow = tinv(0.025,size(AVSNCdataPeaks3{groupNum}{per},1)-1);% T-Score for 95% CI
                    ts_cHigh = tinv(0.975,size(AVSNCdataPeaks3{groupNum}{per},1)-1);% T-Score for 95% CI
                    CI_cLow{groupNum}{per} = (nanmean(AVSNCdataPeaks3{groupNum}{per},1)) + (ts_cLow*SEMc);  % Confidence Intervals
                    CI_cHigh{groupNum}{per} = (nanmean(AVSNCdataPeaks3{groupNum}{per},1)) + (ts_cHigh*SEMc);  % Confidence Intervals

                    SEMv = (nanstd(AVSNVdataPeaks3{groupNum}{VWroi}{per}))/(sqrt(size(AVSNVdataPeaks3{groupNum}{VWroi}{per},1))); % Standard Error            
                    ts_vLow = tinv(0.025,size(AVSNVdataPeaks3{groupNum}{VWroi}{per},1)-1);% T-Score for 95% CI
                    ts_vHigh = tinv(0.975,size(AVSNVdataPeaks3{groupNum}{VWroi}{per},1)-1);% T-Score for 95% CI
                    CI_vLow{groupNum}{per} = (nanmean(AVSNVdataPeaks3{groupNum}{VWroi}{per},1)) + (ts_vLow*SEMv);  % Confidence Intervals
                    CI_vHigh{groupNum}{per} = (nanmean(AVSNVdataPeaks3{groupNum}{VWroi}{per},1)) + (ts_vHigh*SEMv);  % Confidence Intervals

                    x = 1:length(CI_cLow{groupNum}{per});

                    %average across terminals 
                    if size(AVSNCdataPeaks3{groupNum}{per},1) > 1 
                        AVSNCdataPeaks{groupNum}{per} = nanmean(AVSNCdataPeaks3{groupNum}{per});
                        AVSNVdataPeaks{groupNum}{VWroi}{per} = nanmean(AVSNVdataPeaks3{groupNum}{VWroi}{per});
                    elseif size(AVSNCdataPeaks3{groupNum}{per},1) == 1 
                        AVSNCdataPeaks{groupNum}{per} = (AVSNCdataPeaks3{groupNum}{per});
                        AVSNVdataPeaks{groupNum}{VWroi}{per} = (AVSNVdataPeaks3{groupNum}{VWroi}{per});                        
                    end 
                end 
                % plot 
                Ccolors = [0,0,1;0,0.5,1;0,1,1];
                for groupNum = 1:numGroups
                    plot(AVSNCdataPeaks{groupNum}{per},'Color',Ccolors(groupNum,:),'LineWidth',4)
                    patch([x fliplr(x)],[CI_cLow{groupNum}{per} fliplr(CI_cHigh{groupNum}{per})],Ccolors(groupNum,:),'EdgeColor','none')
                    alpha(0.3)
                end 
            %         plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
                ax.XTick = FrameVals;
                ax.XTickLabel = sec_TimeVals;   
                ax.FontSize = 25;
                ax.FontName = 'Times';
                xlabel('time (s)','FontName','Times')
                ylabel('calcium signal percent change','FontName','Times')
                xLimStart = floor(10*FPSstack);
                xLimEnd = floor(24*FPSstack); 
                xlim([1 size(AVSNCdataPeaks{1}{per},2)])
                ylim([-60 100])          
                set(fig,'position', [500 100 900 800])

                yyaxis right   
                Vcolors = [0,0,0;0.4,0.4,0.4;0.7,0.7,0.7];
                p = zeros(1,numGroups);
                for groupNum = 1:numGroups
                    p(groupNum) = plot(AVSNVdataPeaks{groupNum}{VWroi}{per},'Color',Vcolors(groupNum,:),'LineWidth',4,'LineStyle','-');
                    patch([x fliplr(x)],[CI_vLow{groupNum}{per} (fliplr(CI_vHigh{groupNum}{per}))],Vcolors(groupNum,:),'EdgeColor','none')
                    alpha(0.3)
                end 
                if per == 1 
                    perLabel = "Blue Light On";
                elseif per == 2
                    perLabel = "Red Light On";
                elseif per == 3
                    perLabel = "Light Off";
                end 
                legend([p(1) p(2)],'Close Terminals','Far Terminals')
                ylabel('vessel width percent change','FontName','Times')
                title({sprintf('All Terminals Averaged. VW ROI %d.',VWroi);perLabel})      
                alpha(0.3)
                set(gca,'YColor',[0 0 0]);
                %make the directory and save the images   
                if saveQ == 1  
                    dir2 = strrep(dir1,'\','/');
                    dir3 = sprintf('%s/%s.tif',dir2,tlabel);
                    export_fig(dir3)
                end      
            end 
        end 
    end
    
    %}    
end 
%}
%% sort red and green channel stacks based on ca peak location 
%{
windSize = input('How big should the window be around Ca peak in seconds? '); %24
if tTypeQ == 0 
    sortedGreenStacks = cell(1,length(vidList));
    sortedRedStacks = cell(1,length(vidList));
    for vid = 1:length(vidList)
        for ccell = 1:length(terminals)
            for peak = 1:length(sigLocs{vid}{terminals(ccell)})            
                if sigLocs{vid}{terminals(ccell)}(peak)-floor((windSize/2)*FPSstack) > 0 && sigLocs{vid}{terminals(ccell)}(peak)+floor((windSize/2)*FPSstack) < length(cDataFullTrace{vid}{terminals(ccell)})                
                    start = sigLocs{vid}{terminals(ccell)}(peak)-floor((windSize/2)*FPSstack);
                    stop = sigLocs{vid}{terminals(ccell)}(peak)+floor((windSize/2)*FPSstack);                
                    if start == 0 
                        start = 1 ;
                        stop = start + floor((windSize/2)*FPSstack) + floor((windSize/2)*FPSstack);
                    end                
                    sortedGreenStacks{vid}{terminals(ccell)}{peak} = greenStacks{vid}(:,:,start:stop);
                    sortedRedStacks{vid}{terminals(ccell)}{peak} = redStacks{vid}(:,:,start:stop);
                end 
            end 
        end 
    end 
elseif tTypeQ == 1
    %tTypeSigLocs{vid}{CaROI}{1} = blue light
    %tTypeSigLocs{vid}{CaROI}{2} = red light
    %tTypeSigLocs{vid}{CaROI}{3} = ISI
    sortedGreenStacks = cell(1,length(vidList));
    sortedRedStacks = cell(1,length(vidList));
    for vid = 1:length(vidList)  
        for ccell = 1:length(terminals)   
            for per = 1:3 
                for peak = 1:length(tTypeSigLocs{vid}{terminals(ccell)}{per})                    
                    if tTypeSigLocs{vid}{terminals(ccell)}{per}(peak)-floor((windSize/2)*FPSstack) > 0 && tTypeSigLocs{vid}{terminals(ccell)}{per}(peak)+floor((windSize/2)*FPSstack) < length(cDataFullTrace{vid}{terminals(ccell)})                                     
                        start = tTypeSigLocs{vid}{terminals(ccell)}{per}(peak)-floor((windSize/2)*FPSstack);
                        stop = tTypeSigLocs{vid}{terminals(ccell)}{per}(peak)+floor((windSize/2)*FPSstack); 
                        if start == 0 
                            start = 1 ;
                            stop = start + floor((windSize/2)*FPSstack) + floor((windSize/2)*FPSstack);
                        end                
                        sortedGreenStacks{vid}{terminals(ccell)}{per}{peak} = greenStacks{vid}(:,:,start:stop);
                        sortedRedStacks{vid}{terminals(ccell)}{per}{peak} = redStacks{vid}(:,:,start:stop);
                    end 
                end 
            end 
        end 
    end   
end 
%}
%% create red and green channel stack averages around calcium peak location (STA stacks) 
%{
% average calcium peak aligned traces across videos 
if tTypeQ == 0 
    greenStackArray2 = cell(1,length(vidList));
    redStackArray2 = cell(1,length(vidList));
    avGreenStack2 = cell(1,length(sortedGreenStacks{1}));
    avRedStack2 = cell(1,length(sortedGreenStacks{1}));
    avGreenStack = cell(1,length(sortedGreenStacks{1}));
    avRedStack = cell(1,length(sortedGreenStacks{1}));
    for ccell = 1:length(terminals)
        for vid = 1:length(vidList)    
            count = 1;
            for peak = 1:size(sortedGreenStacks{vid}{terminals(ccell)},2)  
                if isempty(sortedGreenStacks{vid}{terminals(ccell)}{peak}) == 0
                    greenStackArray2{vid}{terminals(ccell)}(:,:,:,count) = sortedGreenStacks{vid}{terminals(ccell)}{peak};
                    redStackArray2{vid}{terminals(ccell)}(:,:,:,count) = sortedRedStacks{vid}{terminals(ccell)}{peak};
                    count = count + 1;
                end 
            end
            avGreenStack2{terminals(ccell)}(:,:,:,vid) = nanmean(greenStackArray2{vid}{terminals(ccell)},4);
            avRedStack2{terminals(ccell)}(:,:,:,vid) = nanmean(redStackArray2{vid}{terminals(ccell)},4);
        end 
        avGreenStack{terminals(ccell)} = nanmean(avGreenStack2{terminals(ccell)},4)+100;
        avRedStack{terminals(ccell)} = nanmean(avRedStack2{terminals(ccell)},4)+100;
    end 
elseif tTypeQ == 1
    per = input('Input lighting condition you care about. Blue = 1. Red = 2. Light off = 3. ');
    greenStackArray2 = cell(1,length(vidList));
    redStackArray2 = cell(1,length(vidList));
    avGreenStack2 = cell(1,length(sortedGreenStacks{1}));
    avRedStack2 = cell(1,length(sortedGreenStacks{1}));
    avGreenStack = cell(1,length(sortedGreenStacks{1}));
    avRedStack = cell(1,length(sortedGreenStacks{1}));
    for ccell = 1:length(terminals)
        for vid = 1:length(vidList)    
            count = 1;
            for peak = 1:size(sortedGreenStacks{vid}{terminals(ccell)}{per},2)  
                if isempty(sortedGreenStacks{vid}{terminals(ccell)}{per}{peak}) == 0
                    greenStackArray2{vid}{terminals(ccell)}(:,:,:,count) = sortedGreenStacks{vid}{terminals(ccell)}{per}{peak};
                    redStackArray2{vid}{terminals(ccell)}(:,:,:,count) = sortedRedStacks{vid}{terminals(ccell)}{per}{peak};
                    count = count + 1;
                end 
            end
            avGreenStack2{terminals(ccell)}(:,:,:,vid) = nanmean(greenStackArray2{vid}{terminals(ccell)},4);
            avRedStack2{terminals(ccell)}(:,:,:,vid) = nanmean(redStackArray2{vid}{terminals(ccell)},4);
        end 
        avGreenStack{terminals(ccell)} = nanmean(avGreenStack2{terminals(ccell)},4)+100;
        avRedStack{terminals(ccell)} = nanmean(avRedStack2{terminals(ccell)},4)+100;
    end 
end 
clearvars sortedGreenStacks sortedRedStacks greenStackArray2 redStackArray2 avGreenStack2 avRedStack2

changePt = floor(length(avGreenStack{terminals(ccell)})/2)-2; 
BLstart = changePt - floor(0.5*FPSstack);
NgreenStackAv = cell(1,length(avGreenStack));
NredStackAv = cell(1,length(avGreenStack));
% normalize to baseline period 
for ccell = 1:length(terminals)
    NgreenStackAv{terminals(ccell)} = ((avGreenStack{terminals(ccell)}./ (nanmean(avGreenStack{terminals(ccell)}(:,:,BLstart:changePt),3)))*100)-100;
    NredStackAv{terminals(ccell)} = ((avRedStack{terminals(ccell)}./ (nanmean(avRedStack{terminals(ccell)}(:,:,BLstart:changePt),3)))*100)-100;
end 

%temporal smoothing option
smoothQ = input('Input 0 if you do not want to do temporal smoothing. Input 1 otherwise.');
if smoothQ == 0 
    SNgreenStackAv = NgreenStackAv;
    SNredStackAv = NredStackAv;
elseif smoothQ == 1
    filtTime = input('How many seconds do you want to smooth your data by? '); % our favorite STA trace is smoothed by 0.7 sec 
    filter_rate = FPSstack*filtTime; 
    tempFiltChanQ= input('Input 0 to temporally smooth both channels. Input 1 otherwise. ');
    if tempFiltChanQ == 0
        SNredStackAv = cell(1,length(NgreenStackAv));
        SNgreenStackAv = cell(1,length(NgreenStackAv));
        for ccell = 1:length(terminals)
            SNredStackAv{terminals(ccell)} = smoothdata(NredStackAv{terminals(ccell)},3,'movmean',filter_rate);
            SNgreenStackAv{terminals(ccell)} = smoothdata(NgreenStackAv{terminals(ccell)},3,'movmean',filter_rate);
        end 
    elseif tempFiltChanQ == 1
        tempSmoothChanQ = input('Input 0 to temporally smooth green channel. Input 1 for red channel. ');
        if tempSmoothChanQ == 0
            SNredStackAv = NredStackAv;
            SNgreenStackAv = cell(1,length(NgreenStackAv));
            for ccell = 1:length(terminals)
                SNgreenStackAv{terminals(ccell)} = smoothdata(NgreenStackAv{terminals(ccell)},3,'movmean',filter_rate);
            end 
        elseif tempSmoothChanQ == 1
            SNredStackAv = cell(1,length(NgreenStackAv));
            SNgreenStackAv = NgreenStackAv;
            for ccell = 1:length(terminals)
                SNredStackAv{terminals(ccell)} = smoothdata(NredStackAv{terminals(ccell)},3,'movmean',filter_rate);               
            end 
        end 
    end 
end 
clearvars NgreenStackAv NredStackAv

%spatial smoothing option
spatSmoothQ = input('Input 0 if you do not want to do spatial smoothing. Input 1 otherwise.');
if spatSmoothQ == 1 
    spatSmoothTypeQ = input('Input 0 to do gaussian spatial smoothing. Input 1 to do convolution spatial smoothing (using NxN array of 0.125 values). ');
    spatFiltChanQ= input('Input 0 to spatially smooth both channels. Input 1 otherwise. ');
    if spatFiltChanQ == 0 % if you want to spatially smooth both channels 
        redIn = SNredStackAv; 
        greenIn = SNgreenStackAv;
        clearvars SNredStackAv SNgreenStackAv
        if spatSmoothTypeQ == 0 % if you want to use gaussian spatial smoothing 
            sigma = input('What sigma do you want to use for Gaussian spatial filtering? ');
                for ccell = 1:length(terminals)
                    SNredStackAv{terminals(ccell)} = imgaussfilt(redIn{terminals(ccell)},sigma);
                    SNgreenStackAv{terminals(ccell)} = imgaussfilt(greenIn{terminals(ccell)},sigma);
                end 
        elseif spatSmoothTypeQ == 1 % if you want to use convolution smoothing 
            % create your kernal for smoothing by convolution 
            kernalSize = input('What size NxN array do you want to use for convolution spatial filtering? ');
            K = 0.125*ones(kernalSize);
                for ccell = 1:length(terminals)
                    SNredStackAv{terminals(ccell)} = convn(redIn{terminals(ccell)},K,'same');
                    SNgreenStackAv{terminals(ccell)} = convn(greenIn{terminals(ccell)},K,'same');
                end 
        end 
    elseif spatFiltChanQ == 1 % if you only want to spatially smooth one channel 
        spatSmoothChanQ = input('Input 0 to spatially smooth the green channel. Input 1 for the red channel. ');
        if spatSmoothTypeQ == 0 % if you want to use gaussian spatial smoothing 
            sigma = input('What sigma do you want to use for Gaussian spatial filtering? ');
            if spatSmoothChanQ == 0 % if you want to spatially smooth the green channel 
                greenIn = SNgreenStackAv;
                clearvars SNgreenStackAv
                for ccell = 1:length(terminals)
                    SNgreenStackAv{terminals(ccell)} = imgaussfilt(greenIn{terminals(ccell)},sigma);
                end 
            elseif spatSmoothChanQ == 1 % if you want to spatially smooth the red channel 
                redIn = SNredStackAv; 
                clearvars SNredStackAv 
                for ccell = 1:length(terminals)
                    SNredStackAv{terminals(ccell)} = imgaussfilt(redIn{terminals(ccell)},sigma);
                end 
            end        
        elseif spatSmoothTypeQ == 1 % if you want to use convolution smoothing 
            % create your kernal for smoothing by convolution 
            kernalSize = input('What size NxN array do you want to use for convolution spatial filtering? ');
            K = 0.125*ones(kernalSize);
            if spatSmoothChanQ == 0 % if you want to spatially smooth the green channel 
                greenIn = SNgreenStackAv;
                clearvars SNgreenStackAv
                for ccell = 1:length(terminals)
                    SNgreenStackAv{terminals(ccell)} = convn(greenIn{terminals(ccell)},K,'same');
                end 
            elseif spatSmoothChanQ == 1 % if you want to spatially smooth the red channel 
                redIn = SNredStackAv; 
                clearvars SNredStackAv 
                for ccell = 1:length(terminals)
                    SNredStackAv{terminals(ccell)} = convn(redIn{terminals(ccell)},K,'same');
                end 
            end                          
        end 
    end 
end 

% black out the pixels that are part of calcium ROIs 
blackOutCaROIQ = input('Input 1 if you want to black out pixels in Ca ROIs. Input 0 otherwise. ');
if blackOutCaROIQ == 1         
    CaROImaskDir = uigetdir('*.*','WHERE ARE THE CA ROI COORDINATES?');
    cd(CaROImaskDir);
    CaROImaskFileName = uigetfile('*.*','GET THE CA ROI COORDINATES'); 
    CaROImaskMat = matfile(CaROImaskFileName); 
    CaROImasks = CaROImaskMat.CaROImasks; 
    % combine Ca ROIs from different planes in Z into one plane 
    numZplanes = input('How many planes in Z are there? ');
    combo = cell(1,numZplanes-1);
    for it = 1:numZplanes-1
        if it == 1 
            combo{it} = or(CaROImasks{1},CaROImasks{2});
        elseif it > 1
            combo{it} = or(combo{it-1},CaROImasks{it+1});
        end 
    end         
    %make your combined Ca ROI mask the right size for applying to a 3D
    %arrray 
    ind = length(combo);
    ThreeDCaMask = repmat(combo{ind},1,1,size(SNredStackAv{terminals(ccell)},3));
    %apply new mask to the right channel 
    rightChan = input('Input 0 if BBB data is in the green chanel. Input 1 if BBB data is in the red channel. ');
    if rightChan == 0     
        RightChan = SNgreenStackAv;
        otherChan = SNredStackAv;
    elseif rightChan == 1
        RightChan = SNredStackAv;
        otherChan = SNgreenStackAv;
    end     
    for ccell = 1:length(terminals)
        RightChan{terminals(ccell)}(ThreeDCaMask) = 0;
    end 
end 
clearvars SNgreenStackAv SNredStackAv

AVQ = input('Input 1 to average STA videos. Input 0 otherwise. ');
if AVQ == 0 
    % create outline of vessel to overlay the %change BBB perm stack 
    segmentVessel = 1;
    while segmentVessel == 1 
        %select the correct channel for vessel segmentation  
        vesChan = rightChan;
        if rightChan == 0     
            vesChan = avGreenStack;
        elseif rightChan == 1
            vesChan = avRedStack;
        end     
        % apply Ca ROI mask to the appropriate channel to black out these
        % pixels 
        for ccell = 1:length(terminals)
            vesChan{terminals(ccell)}(ThreeDCaMask) = 0;
        end 
        %segment the vessel (small sample of the data) 
        CaROI = input('What Ca ROI do you want to use to create the segmentation algorithm? ');    
        imageSegmenter(mean(vesChan{CaROI},3))
        continu = input('Is the image segmenter closed? Yes = 1. No = 0. ');
        while continu == 1 
            BWstacks = cell(1,length(vesChan));
            BW_perim = cell(1,length(vesChan));
            segOverlays = cell(1,length(vesChan));    
            for ccell = 1:length(terminals)
                for frame = 1:size(vesChan{terminals(ccell)},3)
    %                     [BW,~] = segmentImageVesselFOV_SF58(vesChan{terminals(ccell)}(:,:,frame));
                    [BW,~] = segmentImageVesselFOV(vesChan{terminals(ccell)}(:,:,frame));
                    BWstacks{terminals(ccell)}(:,:,frame) = BW; 
                    %get the segmentation boundaries 
                    BW_perim{terminals(ccell)}(:,:,frame) = bwperim(BW);
                    %overlay segmentation boundaries on data
                    segOverlays{terminals(ccell)}(:,:,:,frame) = imoverlay(mat2gray(vesChan{terminals(ccell)}(:,:,frame)), BW_perim{terminals(ccell)}(:,:,frame), [.3 1 .3]);   
                end   
            end 
            continu = 0;
        end 
        %play segmentation boundaries over images 
        implay(segOverlays{CaROI})
        %ask about segmentation quality 
        segmentVessel = input("Does the vessel need to be segmented again? Yes = 1. No = 0. ");
        if segmentVessel == 1
            clear BWthreshold BWopenRadius BW se boundaries
        end 
    end
end 

cMapQ = input('Input 0 to create a color map that is red for positive % change and green for negative % change. Input 1 to create a colormap for only positive going values. ');
if cMapQ == 0
    % Create colormap that is green for positive, red for negative,
    % and a chunk inthe middle that is black.
    greenColorMap = [zeros(1, 132), linspace(0, 1, 124)];
    redColorMap = [linspace(1, 0, 124), zeros(1, 132)];
    cMap = [redColorMap; greenColorMap; zeros(1, 256)]';
elseif cMapQ == 1
    % Create colormap that is green at max and black at min
    greenColorMap = linspace(0, 1, 256);
    cMap = [zeros(1, 256); greenColorMap; zeros(1, 256)]';
end 

%save the other channel first to ensure that all Ca ROIs show an average
%peak in the same frame 
dir1 = uigetdir('*.*','WHERE DO YOU WANT TO SAVE THE IMAGES?'); % get the directory where you want to save your images 
dir2 = strrep(dir1,'\','/'); % change the direction of the slashes 
CaROItimingCheckQ = input('Do you need to save the Ca data? Input 1 for yes. 0 for no. ');
if CaROItimingCheckQ == 1 
    for ccell = 1:length(terminals)
        %create a new folder per calcium ROI 
        newFolder = sprintf('CaROI_%d_calciumSignal',terminals(ccell));
        mkdir(dir2,newFolder)
         for frame = 1:size(vesChan{terminals(ccell)},3)    
            figure('Visible','off');     
            imagesc(otherChan{terminals(ccell)}(:,:,frame),[10,30])
            %save current figure to file 
            filename = sprintf('%s/CaROI_%d_calciumSignal/CaROI_%d_frame%d',dir2,terminals(ccell),terminals(ccell),frame);
            saveas(gca,[filename '.png'])
         end 
    end 
end 

% conditional statement that ensures you checked the other channel
% to make sure Ca ROIs show an average peak in the same frame, before
% moving onto the next step 
CaFrameQ = input('Input 1 if you if you checked to make sure averaged Ca events happened in the same frame per ROI. And the anatomy is correct. ');
if CaFrameQ == 1 
    CaEventFrame = input('What frame did the Ca events happen in? ');
    if AVQ == 0  
        %overlay vessel outline and GCaMP activity of the specific Ca ROI on top of %change images, black out pixels where
        %the vessel is (because they're distracting), and save these images to a
        %folder of your choosing (there will be subFolders per calcium ROI)
        for ccell = 1:length(terminals)
            %black out pixels that belong to vessels         
            RightChan{terminals(ccell)}(BWstacks{terminals(ccell)}) = 0;
            %find the upper and lower bounds of your data (per calcium ROI) 
            maxValue = max(max(max(max(RightChan{terminals(ccell)}))));
            bounds = [maxValue,-(maxValue)];
            %determine the absolute difference between the max and min % change
            boundsAbsDiff = abs(diff(bounds,1,2));
            boundsAbs = abs(bounds);
            minBound = -(ceil(max(boundsAbs))); 
            maxBound = ceil(max(boundsAbs)); 
            %create a new folder per calcium ROI 
            newFolder = sprintf('CaROI_%d_BBBsignal',terminals(ccell));
            mkdir(dir2,newFolder)
            %overlay segmentation boundaries on the % change image stack and save
            %images
            for frame = 1:size(vesChan{terminals(ccell)},3)   
                % get the x-y coordinates of the Ca ROI         
                % find the pixels that are over 20 in value 
                clearvars CAy CAx
                [CAy, CAx] = find(otherChan{terminals(ccell)}(:,:,frame) >= 20);  % x and y are column vectors.
                figure('Visible','off');     
                % create the % change image with the right white and black point
                % boundaries and colormap 
        %         imagesc(RightChan{terminals(ccell)}(:,:,frame),[minBound,maxBound]); colormap(cMap); colorbar    %this makes the max point the max % change and the min point the inverse of the max % change     
    %             imagesc(RightChan{terminals(ccell)}(:,:,frame),[-5,5]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',-5:2.5:5)%this makes the max point 5% and the min point -5%     
    %             imagesc(RightChan{terminals(ccell)}(:,:,frame),[-2.5,2.5]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',[-2.5,-1.5,-0.5,0,0.5,1.5,2.5])%this makes the max point 2.5% and the min point -2.5%   
    %             imagesc(RightChan{terminals(ccell)}(:,:,frame),[-1,1]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',-1:0.5:1)%this makes the max point 1% and the min point -1% 
    %             imagesc(RightChan{terminals(ccell)}(:,:,frame),[-2,2]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',-2:1:2)%this makes the max point 1% and the min point -1% 
    %             imagesc(RightChan{terminals(ccell)}(:,:,frame),[-8,8]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',-8:2:8)%this makes the max point 1% and the min point -1% 
    %             imagesc(RightChan{terminals(ccell)}(:,:,frame),[-3,3]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',-3:1.5:3)%this makes the max point 1% and the min point -1% 
%                 imagesc(RightChan{terminals(ccell)}(:,:,frame),[0,3]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',0:0.5:3)%this makes the max point 1% and the min point -1% 
%                 imagesc(RightChan{terminals(ccell)}(:,:,frame),[0,2]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',0:0.5:2)%this makes the max point 1% and the min point -1% 
%                  imagesc(RightChan{terminals(ccell)}(:,:,frame),[0,5]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',0:1:5)%this makes the max point 1% and the min point -1% 
%                 imagesc(RightChan{terminals(ccell)}(:,:,frame),[0,1]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',0:0.25:1)%this makes the max point 1% and the min point -1% 
    %             imagesc(RightChan{terminals(ccell)}(:,:,frame),[0,0.75]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',0:0.25:0.75)%this makes the max point 1% and the min point -1% 
%                 imagesc(RightChan{terminals(ccell)}(:,:,frame),[0,0.5]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',0:0.25:0.5)%this makes the max point 1% and the min point -1% 
%                 imagesc(RightChan{terminals(ccell)}(:,:,frame),[0,0.25]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',0:0.05:0.25)%this makes the max point 1% and the min point -1% 
                imagesc(RightChan{terminals(ccell)}(:,:,frame),[0,2.5]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',0:0.5:2.5)%this makes the max point 1% and the min point -1% 

                % get the x-y coordinates of the vessel outline
                [y, x] = find(BW_perim{terminals(ccell)}(:,:,frame));  % x and y are column vectors.     
                % plot the vessel outline over the % change image 
                hold on;
                scatter(x,y,'white','.');
                % plot the GCaMP signal marker in the right frame 
                if frame == CaEventFrame || frame == (CaEventFrame-1) || frame == (CaEventFrame+1)
                    hold on;
                    scatter(CAx,CAy,100,'white','filled');
                    %get border coordinates 
                    colLen = size(RightChan{terminals(ccell)},2);
                    rowLen = size(RightChan{terminals(ccell)},1);
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
                    scatter(edg_x,edg_y,200,'white','filled','square');               
                end 
                ax = gca;
                ax.Visible = 'off';
                ax.FontSize = 20;
                %save current figure to file 
                filename = sprintf('%s/CaROI_%d_BBBsignal/CaROI_%d_frame%d',dir2,terminals(ccell),terminals(ccell),frame);
                saveas(gca,[filename '.png'])
            end     
        end 
    elseif AVQ == 1
        termsToAv = input('Input what terminal STA videos you want to average. '); 
        STAterms = zeros(size(RightChan{termsToAv(1)},1),size(RightChan{termsToAv(1)},2),size(RightChan{termsToAv(1)},3),length(termsToAv));
        STAtermsVesChans = zeros(size(RightChan{termsToAv(1)},1),size(RightChan{termsToAv(1)},2),size(RightChan{termsToAv(1)},3),length(termsToAv));        
        for termToAv = 1:length(termsToAv)
            %create 4D array containing all relevant terminals 
            STAterms(:,:,:,termToAv) = RightChan{termsToAv(termToAv)};
            STAtermsVesChans(:,:,:,termToAv) = vesChan{termsToAv(termToAv)};
        end 
        % average terminals of your choosing 
        STAav = mean(STAterms,4);
        STAavVesVid = mean(STAtermsVesChans,4);
        
        clear BW BWstacks BW_perim segOverlays
        BWstacks = zeros(size(RightChan{termsToAv(1)},1),size(RightChan{termsToAv(1)},2),size(RightChan{termsToAv(1)},3));
        BW_perim = zeros(size(RightChan{termsToAv(1)},1),size(RightChan{termsToAv(1)},2),size(RightChan{termsToAv(1)},3));
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
                    scatter(edg_x,edg_y,200,'white','filled','square');               
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
    end 
end 
%}
%% average 3 frames (of STA videos) around a specific time point
%{
%specify what time point you want to see 
timePoint = input('What time point do you want to see? (0 sec being when the calcium spike peaks). ');
%figure out what frames correspond to around that time point 
framePoint = CaEventFrame + floor(timePoint*FPSstack);
frames = [framePoint-1,framePoint,framePoint+1];
%specify what Ca ROIs you want to see 
CaROIq = input('Input 0 to look at all the Ca ROIs. Input 1 to select a specific Ca ROI. ');
if CaROIq == 0 
    snapShot = cell(1,length(RightChan));
    for ccell = 1:length(terminals)
        snapShot{terminals(ccell)} = (RightChan{terminals(ccell)}(:,:,frames(1))+RightChan{terminals(ccell)}(:,:,frames(2))+RightChan{terminals(ccell)}(:,:,frames(3)));
        figure('Visible','on'); 
        imagesc(snapShot{terminals(ccell)},[0,0.5]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',0:0.25:0.5)
        % get the x-y coordinates of the vessel outline
        [y, x] = find(BW_perim{terminals(ccell)}(:,:,framePoint));  % x and y are column vectors. 
        hold on;
        scatter(x,y,'white','.');
        ax = gca;
        ax.Visible = 'off';
        ax.FontSize = 20;
    end 
elseif CaROIq == 1 
    CaROI = input('What Ca ROI do you want to see? ');
    snapShot{terminals(ccell)} = (RightChan{CaROI}(:,:,frames(1))+RightChan{CaROI}(:,:,frames(2))+RightChan{CaROI}(:,:,frames(3)));
    figure('Visible','on'); 
    imagesc(snapShot{CaROI},[0,0.5]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',0:0.25:0.5)
    % get the x-y coordinates of the vessel outline
    [y, x] = find(BW_perim{CaROI}(:,:,framePoint));  % x and y are column vectors. 
    hold on;
    scatter(x,y,'white','.');
    ax = gca;
    ax.Visible = 'off';
    ax.FontSize = 20;
end 
%}
%% create composite stack
%THIS NEEDS FURTHER EDITING BECAUSE THE COMPOSITE STACK IS REALLY DIM
%{
%convert gray scale images to red green channel images
redGrayIndex = uint8(SNredStackAv(:,:,:));
greenGrayIndex = uint8(SNgreenStackAv(:,:,:));
%create custom color maps 
redMap = customcolormap([0 0.99 1], [1 0 0; 0.5 0 0 ;0 0 0]);
greenMap = customcolormap([0 0.97 1], [0 1 0; 0 0.5 0 ;0 0 0]);
% colorbar;
% colormap(blueMap);
% axis off;
for frame = 1:size(redGrayIndex,3)
    red(:,:,:,frame) = ind2rgb(redGrayIndex(:,:,frame),redMap);   
    green(:,:,:,frame) = ind2rgb(greenGrayIndex(:,:,frame),greenMap);   
    %imfuse is fucking up the color maps 
    redGreen(:,:,:,frame) = imfuse(red(:,:,:,frame),green(:,:,:,frame),'ColorChannels',[1 2 0],'Scaling','none');
end 

implay(redGreen)
%}
%% create multiple BBB ROIs 
%{
% numROIs = input("How many BBB perm ROIs are we making? "); 
% %for display purposes mostly: average across frames 
% stackAVsIm = mean(redStackAv,3);
% %create the ROI boundaries           
% ROIboundDatas = cell(1,numROIs);
% for VROI = 1:numROIs 
%     label = sprintf('Create ROI %d for BBB perm analysis',VROI);
%     disp(label);
%     [~,xmins,ymins,widths,heights] = firstTimeCreateROIs(1, stackAVsIm);
%     ROIboundData{1} = xmins;
%     ROIboundData{2} = ymins;
%     ROIboundData{3} = widths;
%     ROIboundData{4} = heights;
%     ROIboundDatas{VROI} = ROIboundData;
% end

SNROIstacks = cell(1,numROIs);
ROIstacks = cell(1,numROIs);
for VROI = 1:numROIs
    %use the ROI boundaries to generate ROIstacks 
    xmins = ROIboundDatas{VROI}{1};
    ymins = ROIboundDatas{VROI}{2};
    widths = ROIboundDatas{VROI}{3};
    heights = ROIboundDatas{VROI}{4};
    [SNROI_stacks] = make_ROIs_notfirst_time(SNredStackAv,xmins,ymins,widths,heights);
    SNROIstacks{VROI} = SNROI_stacks{1};
    [ROI_stacks] = make_ROIs_notfirst_time(redStackAv,xmins,ymins,widths,heights);
    ROIstacks{VROI} = ROI_stacks{1};
end 

%create mask of where vessels are - frame by frame 
BWstacks = cell(1,numROIs);
BW_perim = cell(1,numROIs);
segOverlays = cell(1,numROIs);         
for VROI = 1:numROIs  
    BWstacks{VROI} = zeros(size(ROIstacks{VROI},1),size(ROIstacks{VROI},2),size(ROIstacks{VROI},3));
    for frame = 1:size(ROIstacks{VROI},3)
%         [BW,~] = segmentImageBBB(ROIstacks{VROI}(:,:,frame));
%         BWstacks{VROI}(:,:,frame) = BW; 
        %get the segmentation boundaries 
        BW_perim{VROI}(:,:,frame) = bwperim(BWstacks{VROI}(:,:,frame));
        %overlay segmentation boundaries on data
        segOverlays{VROI}(:,:,:,frame) = imoverlay(mat2gray(ROIstacks{VROI}(:,:,frame)), BW_perim{VROI}(:,:,frame), [.3 1 .3]);
    end               
end      
% 
% %check segmentation 
% if numROIs == 1 
%     %play segmentation boundaries over images 
%     implay(segOverlays{1})
% elseif numROIs > 1 
%     VROI = input("What BBB ROI do you want to see? ");
%     %play segmentation boundaries over images 
%     implay(segOverlays{VROI})
% end 

% invert the mask
BWstacksInv = cell(1,numROIs);
for VROI = 1:numROIs                
    for frame = 1:size(ROIstacks{VROI},3)                            
        BWstacksInv{VROI}(:,:,frame) = ~(BWstacks{VROI}(:,:,frame)); 
    end         
end 

%apply the mask and get pixel intensities
meanPixIntArray = cell(1,numROIs);
for VROI = 1:numROIs           
    for frame = 1:size(ROIstacks{VROI},3)   
        stats = regionprops(BWstacksInv{VROI}(:,:,frame),SNROIstacks{VROI}(:,:,frame),'MeanIntensity');
        for stat = 1:length(stats)
            ROIpixInts(stat) = stats(stat).MeanIntensity;
        end 
        meanPixIntArray{VROI}(frame) = mean(ROIpixInts);   
    end 
end 

% plot BBB ROI pixel intensities 
figure;
Frames = length(avSortedCdata{terminals(ccell)});
Frames_pre_stim_start = -((Frames-1)/2); 
Frames_post_stim_start = (Frames-1)/2; 
sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack))+1;
FrameVals = round((1:FPSstack:Frames)+5); 
ax=gca;
hold all
plot(SNavCdata{term},'b','LineWidth',2);
for VROI = 1:numROIs
    plot(meanPixIntArray{VROI},'LineWidth',2);
end 
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;   
ax.FontSize = 20;
xlabel('time (s)')
ylabel('percent change')
xlim([0 length(SNavCdata{terminals(ccell)})])
ylim([-20 100])
legend('Terminal 12 calcium','BBB ROI 1','BBB ROI 2','BBB ROI 3','BBB ROI 4','BBB ROI 5') %'Terminal 12 calcium',
if smoothQ == 0 
    title(sprintf('DA terminal #%d.',term))
elseif smoothQ == 1
    title(sprintf('DA terminal #%d. %0.2f sec smoothing.',term,filtTime))
end 


%% show all trials that go into BBB trace for terminal 12 

%% create stacks that are seperated by trial type 
%}
%% determine how far away each terminal is from the vessel of interest (the minimum distance) 
%{
if distQ == 1 
    % get the Ca ROI coordinates 
    CaROImaskDir = uigetdir('*.*','WHERE ARE THE CA ROI COORDINATES?');
    cd(CaROImaskDir);
    CaROImaskFileName = uigetfile('*.*','GET THE CA ROI COORDINATES'); 
    CaROImaskMat = matfile(CaROImaskFileName); 
    CaROImasks = CaROImaskMat.ROIorders; 
    CaROImask = CaROImasks;
    terminals = input('What Ca ROIs do you care about? '); 
    XpixDist = input('How many microns per pixel are there in the X direction? '); 
    YpixDist = input('How many microns per pixel are there in the Y direction? '); 
    ZpixDist = input('How many microns per pixel are there in the Z direction? '); 
    %get all of the coordinates - for the vessel you care about and all of
    %the Ca ROIs you care about 
    Vinds = cell(1,length(CaROImasks));
    CaROIinds = cell(1,length(CaROImasks));
    distsMicrons = cell(1,length(CaROImasks));
    minDistsMicrons1 = zeros(length(CaROImasks),length(terminals)); 
    for z = 1:length(CaROImasks)
        imshow(redZstack(:,:,z),[0 1000])
        ROIdata = drawfreehand(gca);  % manually draw vessel outline
        %get the vessel outline coordinates 
        Vinds{z} = ROIdata.Position;
        VxMicrons = (Vinds{z}(:,2))*XpixDist;
        VyMicrons = (Vinds{z}(:,1))*YpixDist;
        outLineQ = input(sprintf('Input 1 if you are done drawing the outline for Z = %d. ',z));
        if outLineQ == 1
            close all
        end 
        %get the coordinates for every Ca ROI
        for ccell = 1:length(terminals)
            [CaROIx,CaROIy] = find(CaROImasks{z} == terminals(ccell));
            CaROIinds{z}{ccell}(:,2) = CaROIx;
            CaROIinds{z}{ccell}(:,1) = CaROIy; 
            if  isempty(CaROIinds{z}{ccell}) == 0 
                CaROIxMicrons = CaROIx*XpixDist; 
                CaROIyMicrons = CaROIy*YpixDist;            
                %determine the euclidean distance in pixels between each Ca ROI
                %pixel and hand drawn vessel outline
                for CaROIcoord = 1:size(CaROIinds{z}{ccell},1)
                    for Vcoord = 1:size(Vinds{z},1)
                        distsMicrons{z}{ccell}(CaROIcoord,Vcoord) = sqrt(((VxMicrons(Vcoord)-CaROIxMicrons(CaROIcoord))^2)+((VyMicrons(Vcoord)-CaROIyMicrons(CaROIcoord))^2)+(((z*ZpixDist)-(z*ZpixDist))^2)); 
                    end 
                end 
                %determine the minimum distance in pixels between every Ca ROI
                %and the vessel part 1 
                minDistsMicrons1(z,ccell) = min(min(distsMicrons{z}{ccell})); 
            end 
        end       
    end 
    %remove zeros from the minDistsMicrons1 array - these zeros are only
    %there because that particular Ca ROI isn't in that plane in Z 
    minDistsMicrons1(minDistsMicrons1 == 0) = NaN;
    %determine the minimum distance in pixels between every Ca ROI
    %and the vessel part 2 
    minDistsMicrons = zeros(1,length(terminals));
    for ccell = 1:length(terminals)
        minDistsMicrons(ccell) = min(minDistsMicrons1(:,ccell));
    end 
end 
%}
%% compare min distance each Ca ROI is from the vessel with when the BBB signal peaks 
%{
%get the BBB data 
dataDir = uigetdir('*.*','WHERE IS THE BBB STA DATA?');
cd(dataDir);
dataDirFileName = uigetfile('*.*','GET THE BBB STA DATA'); 
dataMat = matfile(dataDirFileName); 
AVSNBdataPeaks = dataMat.AVSNBdataPeaks; 

framePeriod = input('What is the frame period? ');
FPS = 1/framePeriod; 
FPSstack = FPS/3;
CaPeakFrame = input('In what frame does the Ca signal peak? ');

BBBroi = input('What BBB ROI do you care about? ');
lightQ = input('Input 0 for all light conditions. Input 1 to be more specific. ');

if lightQ == 0 
    %find when the BBB signal peaks (within 5 sec around the calcium peak.
    %this is 2.5 seconds either side of 0 sec. 0 being when the calcium signal
    %peaks)
    maxBBBvals = zeros(1,length(terminals));
    maxBBBvalInds = zeros(1,length(terminals));
    maxBBBvalTimePoints = zeros(1,length(terminals));
    for ccell = 1:length(terminals)
        %find max value 
        maxBBBvals(ccell) = max(AVSNBdataPeaks{BBBroi}{terminals(ccell)});
        %find index of each BBB max value 
        maxBBBvalInds(ccell) = find(AVSNBdataPeaks{BBBroi}{terminals(ccell)} == maxBBBvals(ccell));
        %convert index to time in sec relative to 0 sec = when the calcium peak
        %occurs 
        maxBBBvalTimePoints(ccell) = (maxBBBvalInds(ccell)-CaPeakFrame)/FPSstack;
    end 
elseif lightQ == 1   
    %find when the BBB signal peaks (within 5 sec around the calcium peak.
    %this is 2.5 seconds either side of 0 sec. 0 being when the calcium signal
    %peaks)
    maxBBBvals = cell(1,3);
    maxBBBvalInds = cell(1,3);
    maxBBBvalTimePoints = cell(1,3);
    for per = 1:3 
        for ccell = 1:length(terminals)
            %find max value 
            maxBBBvals{per}(ccell) = max(AVSNBdataPeaks{BBBroi}{terminals(ccell)}{per});
            %find index of each BBB max value 
            maxBBBvalInds{per}(ccell) = find(AVSNBdataPeaks{BBBroi}{terminals(ccell)}{per} == maxBBBvals{per}(ccell));
            %convert index to time in sec relative to 0 sec = when the calcium peak
            %occurs 
            maxBBBvalTimePoints{per}(ccell) = (maxBBBvalInds{per}(ccell)-CaPeakFrame)/FPSstack;
        end   
    end 
end 

%%
if lightQ == 0 
    figure;
    scatter(minDistsMicrons,maxBBBvalTimePoints,'k','filled')
    hold on;
    for term = 1:length(terminals)
        text(minDistsMicrons(term),maxBBBvalTimePoints(term),num2str(terminals(term)),'FontSize',20)
    end 
    ax = gca;
    ax.FontSize = 25;
    ax.FontName = 'Times';
%     xlabel({'Distance From Where Vessel';'Branches (microns)'},'FontName','Times')
    xlabel('Distance From Vessel (microns)','FontName','Times')
    ylabel({'Time Lag Between Ca';'and BBB Perm Peaks (s)'},'FontName','Times')

    figure;
    scatter(minDistsMicrons,maxBBBvals,'k','filled')
    hold on;
    for term = 1:length(terminals)
        text(minDistsMicrons(term),maxBBBvals(term),num2str(terminals(term)),'FontSize',20)
    end 
    ax = gca;
    ax.FontSize = 25;
    ax.FontName = 'Times';
%     xlabel({'Distance From Where Vessel';'Branches (microns)'},'FontName','Times')
    xlabel('Distance From Vessel (microns)','FontName','Times')
    ylabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')

    figure;
    scatter(maxBBBvals,maxBBBvalTimePoints,'k','filled')
    hold on;
    for term = 1:length(terminals)
        text(maxBBBvals(term),maxBBBvalTimePoints(term),num2str(terminals(term)),'FontSize',20)
    end 
    ax = gca;
    ax.FontSize = 25;
    ax.FontName = 'Times';
    xlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
    ylabel({'Time Lag Between Ca';'and BBB Perm Peaks'},'FontName','Times')
elseif lightQ == 1
    per = input('Input 1 for blue light period. Input 2 for red light period. Input 3 for light off period. ');
    figure;
    scatter(minDistsMicrons,maxBBBvalTimePoints{per},'k','filled')
    hold on;
    for term = 1:length(terminals)
        text(minDistsMicrons(term),maxBBBvalTimePoints{per}(term),num2str(terminals(term)),'FontSize',20)
    end 
    ax = gca;
    ax.FontSize = 25;
    ax.FontName = 'Times';
%     xlabel({'Distance From Where Vessel';'Branches (microns)'},'FontName','Times')
    xlabel('Distance From Vessel (microns)','FontName','Times')
    ylabel({'Time Lag Between Ca';'and BBB Perm Peaks (s)'},'FontName','Times')

    figure;
    scatter(minDistsMicrons,maxBBBvals{per},'k','filled')
    hold on;
    for term = 1:length(terminals)
        text(minDistsMicrons(term),maxBBBvals{per}(term),num2str(terminals(term)),'FontSize',20)
    end 
    ax = gca;
    ax.FontSize = 25;
    ax.FontName = 'Times';
%     xlabel({'Distance From Where Vessel';'Branches (microns)'},'FontName','Times')
    xlabel('Distance From Vessel (microns)','FontName','Times')
    ylabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')

    figure;
    scatter(maxBBBvals{per},maxBBBvalTimePoints{per},'k','filled')
    hold on;
    for term = 1:length(terminals)
        text(maxBBBvals{per}(term),maxBBBvalTimePoints{per}(term),num2str(terminals(term)),'FontSize',20)
    end 
    ax = gca;
    ax.FontSize = 25;
    ax.FontName = 'Times';
    xlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
    ylabel({'Time Lag Between Ca';'and BBB Perm Peaks'},'FontName','Times')
end 

%}
%% get distance, BBB peak, and Ca peak data (across mice) and sort the data 
%{
mouseNum = input('How many mice do you want to use to create scatter plots of vessel-Ca ROI distance and BBB perm metrics? ');
minDistsMicrons = cell(1,mouseNum);
maxBBBvalTimePoints = cell(1,mouseNum);
maxBBBvals = cell(1,mouseNum);
for mouse = 1:mouseNum
    dataDir = uigetdir('*.*',sprintf('WHERE IS THE DISTANCE VS BBB PERM DATA FOR MOUSE %d',mouse));
    cd(dataDir);
    dataDirFileName = uigetfile('*.*',sprintf('GET THE DISTANCE VS BBB PERM DATA FOR MOUSE %d',mouse)); 
    dataMat = matfile(dataDirFileName); 
    minDistsMicrons{mouse} = dataMat.minDistsMicrons; 
    maxBBBvalTimePoints{mouse} = dataMat.maxBBBvalTimePoints; 
    maxBBBvals{mouse} = dataMat.maxBBBvals; 
end 

if lightQ == 0 
    for mouse = 2:mouseNum
        if mouse == 2  
           minDistMicronsAllMice = horzcat(minDistsMicrons{1},minDistsMicrons{mouse});
           maxBBBvalTimePointsAllMice = horzcat(maxBBBvalTimePoints{1},maxBBBvalTimePoints{mouse});
           maxBBBvalsAllMice = horzcat(maxBBBvals{1},maxBBBvals{mouse});
        elseif mouse > 2 
           minDistMicronsAllMice = horzcat(minDistMicronsAllMice,minDistsMicrons{mouse});
           maxBBBvalTimePointsAllMice = horzcat(maxBBBvalTimePointsAllMice,maxBBBvalTimePoints{mouse});
           maxBBBvalsAllMice = horzcat(maxBBBvalsAllMice,maxBBBvals{mouse});
        end 
    end 
    
%     clear minDistMicronsAllMice2
%     count = 1; 
%     for term = 1:length(minDistMicronsAllMice)
%         if maxBBBvalTimePointsAllMice(term) > -1 && maxBBBvalTimePointsAllMice(term) < 0
%             minDistMicronsAllMice2(count) = minDistMicronsAllMice(term);
%             count = count + 1;
%         end 
%     end 
elseif lightQ == 1
    maxBBBvalTimePointsAllMice = cell(1,3);
    maxBBBvalsAllMice = cell(1,3);
    for per = 1:3 
        for mouse = 2:mouseNum
            if mouse == 2  
               minDistMicronsAllMice = horzcat(minDistsMicrons{1},minDistsMicrons{mouse});
               maxBBBvalTimePointsAllMice{per} = horzcat(maxBBBvalTimePoints{1}{per},maxBBBvalTimePoints{mouse}{per});
               maxBBBvalsAllMice{per} = horzcat(maxBBBvals{1}{per},maxBBBvals{mouse}{per});
            elseif mouse > 2 
%                minDistMicronsAllMice = horzcat(minDistMicronsAllMice,minDistsMicrons{mouse});
               maxBBBvalTimePointsAllMice{per} = horzcat(maxBBBvalTimePointsAllMice{per},maxBBBvalTimePoints{mouse}{per});
               maxBBBvalsAllMice{per} = horzcat(maxBBBvalsAllMice{per},maxBBBvals{mouse}{per});
            end 
        end 
    end 
end 
%}
%% compare min distance each Ca ROI is from the vessel with when the BBB signal peaks (across mice)
%{
% scatter plots. each mouse a different color. each mouse gets regression
% line. 
%
%@@@@@@@@@@@@@@@@  ONE  @@@@@@@@@@@@@@@@@@@
figure;
color = [1 0 0; .1 0 .1; 0.2 0.6 .7; 1 0.2 1; 1 .6 0];
for mouse = 1:mouseNum
    scatter(minDistsMicrons{mouse},maxBBBvalTimePoints{mouse},'filled','MarkerFaceColor',color(mouse,:))
    hold on;
    % Do the regression with polyfit.  Fit a straight line through the noisy y values.
    fit = polyfit(minDistsMicrons{mouse},maxBBBvalTimePoints{mouse},1);
    % Make 50 fitted samples from 0 to max min distance
    xFit = linspace(0, 50, 50);
    % Get the estimated values with polyval()
    yFit = polyval(fit, xFit);
    % Plot the fit
    plot(xFit, yFit, 'MarkerFaceColor',color(mouse,:), 'MarkerSize', 15, 'LineWidth', 2);
end 
ax = gca;
ax.FontSize = 25;
ax.FontName = 'Times';
xlabel({'Distance From Where Vessel';'Branches (microns)'},'FontName','Times')
ylabel({'Time Lag Between Ca';'and BBB Perm Peaks (s)'},'FontName','Times')
xlim([0 48])

%@@@@@@@@@@@@@@@@  TWO  @@@@@@@@@@@@@@@@@@@
figure;
for mouse = 1:mouseNum
    scatter(minDistsMicrons{mouse},maxBBBvals{mouse},'filled','MarkerFaceColor',color(mouse,:))
    hold on;
    % Do the regression with polyfit.  Fit a straight line through the noisy y values.
    fit = polyfit(minDistsMicrons{mouse},maxBBBvals{mouse},1);
    % Make 50 fitted samples from 0 to max min distance
    xFit = linspace(0, 50, 50);
    % Get the estimated values with polyval()
    yFit = polyval(fit, xFit);
    % Plot the fit
    plot(xFit, yFit, 'MarkerFaceColor',color(mouse,:), 'MarkerSize', 15, 'LineWidth', 2);
end 
ax = gca;
ax.FontSize = 25;
ax.FontName = 'Times';
xlabel({'Distance From Where Vessel';'Branches (microns)'},'FontName','Times')
ylabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
xlim([0 48])

%@@@@@@@@@@@@@@@@  THREE  @@@@@@@@@@@@@@@@@@@
figure;
for mouse = 1:mouseNum
    scatter(maxBBBvals{mouse},maxBBBvalTimePoints{mouse},'filled','MarkerFaceColor',color(mouse,:))
    hold on;
    % Do the regression with polyfit.  Fit a straight line through the noisy y values.
    fit = polyfit(maxBBBvals{mouse},maxBBBvalTimePoints{mouse},1);
    % Make 50 fitted samples from 0 to max min distance
    xFit = linspace(0, 1.6, 50);
    % Get the estimated values with polyval()
    yFit = polyval(fit, xFit);
    % Plot the fit
    plot(xFit, yFit, 'MarkerFaceColor',color(mouse,:), 'MarkerSize', 15, 'LineWidth', 2);
end  
ax = gca;
ax.FontSize = 25;
ax.FontName = 'Times';
xlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
ylabel({'Time Lag Between Ca';'and BBB Perm Peaks'},'FontName','Times')
xlim([0 1.6])

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% all black. one regression line for all animals combined. 

%@@@@@@@@@@@@@@@@  ONE  @@@@@@@@@@@@@@@@@@@
figure;
for mouse = 2:mouseNum
    if mouse == 2 && mouseNum == 2 
       minDistMicronsAllMice = horzcat(minDistsMicrons{1},minDistsMicrons{mouse});
       maxBBBvalTimePointsAllMice = horzcat(maxBBBvalTimePoints{1},maxBBBvalTimePoints{mouse});
    elseif mouse == 2 && mouseNum > 2 
       miceData1 = horzcat(minDistsMicrons{1},minDistsMicrons{mouse});
       miceData2 = horzcat(maxBBBvalTimePoints{1},maxBBBvalTimePoints{mouse});
    elseif mouse > 2
       minDistMicronsAllMice = horzcat(miceData1,minDistsMicrons{mouse});
       maxBBBvalTimePointsAllMice = horzcat(miceData2,maxBBBvalTimePoints{mouse});
    end 
end 
scatter(minDistMicronsAllMice,maxBBBvalTimePointsAllMice,'filled','k')
hold on;
% Do the regression with polyfit.  Fit a straight line through the noisy y values.
fit = polyfit(minDistMicronsAllMice,maxBBBvalTimePointsAllMice,1);
% Make 50 fitted samples from 0 to max min distance
xFit = linspace(0, 50, 50);
% Get the estimated values with polyval()
yFit = polyval(fit, xFit);
% Plot the fit
plot(xFit, yFit, 'k', 'MarkerSize', 15, 'LineWidth', 2);
ax = gca;
ax.FontSize = 25;
ax.FontName = 'Times';
xlabel({'Distance From Where Vessel';'Branches (microns)'},'FontName','Times')
ylabel({'Time Lag Between Ca';'and BBB Perm Peaks (s)'},'FontName','Times')
xlim([0 48])

%@@@@@@@@@@@@@@@@  TWO  @@@@@@@@@@@@@@@@@@@
figure;
for mouse = 2:mouseNum
    if mouse == 2 && mouseNum == 2 
       minDistMicronsAllMice = horzcat(minDistsMicrons{1},minDistsMicrons{mouse});
       maxBBBvalsAllMice = horzcat(maxBBBvals{1},maxBBBvals{mouse});
    elseif mouse == 2
       miceData1 = horzcat(minDistsMicrons{1},minDistsMicrons{mouse});
       miceData2 = horzcat(maxBBBvals{1},maxBBBvals{mouse});
    elseif mouse > 2 && mouseNum > 2 
       minDistMicronsAllMice = horzcat(miceData1,minDistsMicrons{mouse});
       maxBBBvalsAllMice = horzcat(miceData2,maxBBBvals{mouse});
    end 
end 
scatter(minDistMicronsAllMice,maxBBBvalsAllMice,'filled','k')
hold on;
% Do the regression with polyfit.  Fit a straight line through the noisy y values.
fit = polyfit(minDistsMicrons{mouse},maxBBBvals{mouse},1);
% Make 50 fitted samples from 0 to max min distance
xFit = linspace(0, 50, 50);
% Get the estimated values with polyval()
yFit = polyval(fit, xFit);
% Plot the fit
plot(xFit, yFit, 'k', 'MarkerSize', 15, 'LineWidth', 2);
ax = gca;
ax.FontSize = 25;
ax.FontName = 'Times';
xlabel({'Distance From Where Vessel';'Branches (microns)'},'FontName','Times')
ylabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
xlim([0 48])

%@@@@@@@@@@@@@@@@  THREE  @@@@@@@@@@@@@@@@@@@
figure;
for mouse = 2:mouseNum
    if mouse == 2
       miceData1 = horzcat(maxBBBvals{1},maxBBBvals{mouse});
       miceData2 = horzcat(maxBBBvalTimePoints{1},maxBBBvalTimePoints{mouse});
    elseif mouse > 2
       maxBBBvalsAllMice = horzcat(miceData1,maxBBBvals{mouse});
       maxBBBvalTimePointsAllMice = horzcat(miceData2,maxBBBvalTimePoints{mouse});
    end 
end 
scatter(maxBBBvalsAllMice,maxBBBvalTimePointsAllMice,'filled','k')
hold on;
% Do the regression with polyfit.  Fit a straight line through the noisy y values.
fit = polyfit(maxBBBvals{mouse},maxBBBvalTimePoints{mouse},1);
% Make 50 fitted samples from 0 to max min distance
xFit = linspace(0, 1.6, 50);
% Get the estimated values with polyval()
yFit = polyval(fit, xFit);
% Plot the fit
plot(xFit, yFit, 'k', 'MarkerSize', 15, 'LineWidth', 2);
ax = gca;
ax.FontSize = 25;
ax.FontName = 'Times';
xlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
ylabel({'Time Lag Between Ca';'and BBB Perm Peaks'},'FontName','Times')
xlim([0 1.6])
%}
%% 3D scatter plot of Ca ROI distance metric, BBB perm-Ca Peak time delay, and BBB perm max peak amp
%{
% 3D scatter plot. each mouse a different color. 
figure;
color = [1 0 0; .1 0 .1; 0.2 0.6 .7];
rotate3d on
for mouse = 1:length(minDistsMicrons)
    scatter3(minDistsMicrons{mouse},maxBBBvalTimePoints{mouse},maxBBBvals{mouse},'filled','MarkerFaceColor',color(mouse,:))
    hold on;
    %3D ordinary least squares regression 
    %{
    %put data in same array for convenience 
    data(:,1) = minDistsMicrons{mouse}';
    data(:,2) = maxBBBvalTimePoints{mouse}';
    data(:,3) = maxBBBvals{mouse}';
    % best-fit plane
    C = [data(:,1) data(:,2) ones(size(data,1),1)] \ data(:,3);    % coefficients
    % evaluate it on a regular grid covering the domain of the data
    [xx,yy] = meshgrid(0:2:50, -3:.5:3);
    zz = C(1)*xx + C(2)*yy + C(3);
    line(data(:,1), data(:,2), data(:,3), 'LineStyle','none', ...
    'Marker','.', 'MarkerSize',25, 'Color',color(mouse,:))
    surface(xx, yy, zz, ...
    'FaceColor','interp', 'EdgeColor',color(mouse,:), 'FaceAlpha',0.2)
    clear data 
    %}
end 
ax = gca;
ax.FontSize = 25;
ax.FontName = 'Times';
% xlabel({'Distance From Where Vessel';'Branches (microns)'},'FontName','Times')
xlabel('Distance From  Vessel(microns)','FontName','Times')
ylabel({'Time Lag Between Ca';'and BBB Perm Peaks (s)'},'FontName','Times')
zlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
% xlim([0 48])

% 3D scatter plot. All mice same color 
for mouse = 2:mouseNum
    if mouse == 2
       miceData1 = horzcat(minDistsMicrons{1},minDistsMicrons{mouse});
       miceData2 = horzcat(maxBBBvalTimePoints{1},maxBBBvalTimePoints{mouse});
       miceData3 = horzcat(maxBBBvals{1},maxBBBvals{mouse});
    elseif mouse > 2
       minDistMicronsAllMice = horzcat(miceData1,minDistsMicrons{mouse});
       maxBBBvalTimePointsAllMice = horzcat(miceData2,maxBBBvalTimePoints{mouse});
       maxBBBvalsAllMice = horzcat(miceData3,maxBBBvals{mouse});
    end 
end 
figure;
rotate3d on
scatter3(minDistMicronsAllMice,maxBBBvalTimePointsAllMice,maxBBBvalsAllMice,'filled','k')
hold on;
%3D ordinary least squares regression 
%{
%put data in same array for convenience 
data(:,1) = minDistMicronsAllMice';
data(:,2) = maxBBBvalTimePointsAllMice';
data(:,3) = maxBBBvalsAllMice';
% best-fit plane
C = [data(:,1) data(:,2) ones(size(data,1),1)] \ data(:,3);    % coefficients
% evaluate it on a regular grid covering the domain of the data
[xx,yy] = meshgrid(0:2:50, -3:.5:3);
zz = C(1)*xx + C(2)*yy + C(3);
line(data(:,1), data(:,2), data(:,3), 'LineStyle','none', ...
'Marker','.', 'MarkerSize',25, 'Color','k')
surface(xx, yy, zz, ...
'FaceColor','interp', 'EdgeColor','k', 'FaceAlpha',0.2)
%}
scatter3(minDistMicronsAllMice(3),maxBBBvalTimePointsAllMice(3),maxBBBvalsAllMice(3),'filled','r')
ax = gca;
ax.FontSize = 20;
ax.FontName = 'Times';
% xlabel({'Distance From Where Vessel';'Branches (microns)'},'FontName','Times')
xlabel('Distance From  Vessel(microns)','FontName','Times')
ylabel({'Time Lag Between Ca';'and BBB Perm Peaks (s)'},'FontName','Times')
zlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
% xlim([0 48])
clear data
%}
%% plot data 2D distance x time lag. make the size of the dot related to BBB peak amplitude (across mice)
%{
if lightQ == 0
    % 2D scatter plot. each mouse a different color. 
    figure;
    color = [1 0 0; .1 0 .1; 0.2 0.6 .7; 1 0.2 1; 1 .6 0];
%     color = [1 0.2 1; 1 .6 0];
%     color = [1 0 0; .1 0 .1; 0.2 0.6 .7];
%     color = [1 0 0; 0.3 1 0.3; 0.2 0.6 .7];
%     mouseTerms = cell(1,length(minDistsMicrons));
    for mouse = 1:length(minDistsMicrons)
%         mouseTerms{mouse} = input(sprintf('What Ca ROIs do you care about for mouse #%d? ',mouse)); 
        for point = 1:length(minDistsMicrons{mouse})
            scatter(minDistsMicrons{mouse}(point),maxBBBvalTimePoints{mouse}(point),maxBBBvals{mouse}(point)*100,'filled','MarkerFaceColor',color(mouse,:)) 
            hold on;
%             text(minDistsMicrons{mouse}(point)+0.5,maxBBBvalTimePoints{mouse}(point),num2str(mouseTerms{mouse}(point)),'FontSize',20)
        end  
        
    end 
    ax = gca;
    ax.FontSize = 25;
    ax.FontName = 'Times';
%     xlabel({'Distance From Where Vessel';'Branches (microns)'},'FontName','Times')
    xlabel('Distance From  Vessel (microns)','FontName','Times')
    ylabel({'Time Lag Between Ca';'and BBB Perm Peaks (s)'},'FontName','Times')
    zlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
    

    % 2D scatter plot. All mice same color      
    figure;
    for point = 1:length(minDistMicronsAllMice)
        scatter(minDistMicronsAllMice(point),maxBBBvalTimePointsAllMice(point),maxBBBvalsAllMice(point)*100,'filled','k') 
        hold on;
    end  
    % Do the regression with polyfit.  Fit a straight line through the noisy y values.
    fit = polyfit(minDistMicronsAllMice,maxBBBvalTimePointsAllMice,1);
    % Make 50 fitted samples from 0 to max min distance
    xFit = linspace(0, 200, 200);
    % Get the estimated values with polyval()
    yFit = polyval(fit, xFit);
    % Plot the fit
%     plot(xFit, yFit, 'k', 'MarkerSize', 15, 'LineWidth', 2);
    ax = gca;
    ax.FontSize = 25;
    ax.FontName = 'Times';
%     xlabel({'Distance From Where Vessel';'Enters Brain (microns)'},'FontName','Times')
    xlabel('Distance From  Vessel (microns)','FontName','Times')
    ylabel({'Time Lag Between Ca';'and BBB Perm Peaks (s)'},'FontName','Times')
    zlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
    scatter(minDistsMicrons{1}(3),maxBBBvalTimePoints{1}(3),maxBBBvals{1}(3)*100,'filled','r') 
    % scatter(minDistsMicrons{3}(10),maxBBBvalTimePoints{3}(10),maxBBBvals{3}(10)*100,'filled','b') 
    xlim([0 50])
    
elseif lightQ == 1 
    
    per = input('Input 1 for blue light period. Input 2 for red light period. Input 3 for light off period. ');
    % 2D scatter plot. each mouse a different color. 
    figure;
    color = [1 0.2 1; 1 .6 0];
%     color = [1 0 0; .1 0 .1; 0.2 0.6 .7; 1 0.2 1; 1 .6 0];
%     color = [1 0 0; .1 0 .1; 0.2 0.6 .7];
%     mouseTerms = cell(1,length(minDistsMicrons));
    for mouse = 1:length(minDistsMicrons)
%         mouseTerms{mouse} = input(sprintf('What Ca ROIs do you care about for mouse #%d? ',mouse)); 
        for point = 1:length(minDistsMicrons{mouse})
            scatter(minDistsMicrons{mouse}(point),maxBBBvalTimePoints{mouse}{per}(point),maxBBBvals{mouse}{per}(point)*100,'filled','MarkerFaceColor',color(mouse,:)) 
            hold on;
%             text(minDistsMicrons{mouse}(point)+0.2,maxBBBvalTimePoints{mouse}{per}(point),num2str(mouseTerms{mouse}(point)),'FontSize',20)
        end  
    end 
    ax = gca;
    ax.FontSize = 25;
    ax.FontName = 'Times';
%     xlabel({'Distance From Where Vessel';'Branches (microns)'},'FontName','Times')
    xlabel('Distance From  Vessel (microns)','FontName','Times')
    ylabel({'Time Lag Between Ca';'and BBB Perm Peaks (s)'},'FontName','Times')
    zlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')

    % 2D scatter plot. All mice same color 
    figure;
    for point = 1:length(minDistMicronsAllMice)
        scatter(minDistMicronsAllMice(point),maxBBBvalTimePointsAllMice{per}(point),maxBBBvalsAllMice{per}(point)*100,'filled','k') 
        hold on;
    end  
    % Do the regression with polyfit.  Fit a straight line through the noisy y values.
    fit = polyfit(minDistMicronsAllMice,maxBBBvalTimePointsAllMice{per},1);
    % Make 50 fitted samples from 0 to max min distance
    xFit = linspace(0, 200, 200);
    % Get the estimated values with polyval()
    yFit = polyval(fit, xFit);
    % Plot the fit
%     plot(xFit, yFit, 'k', 'MarkerSize', 15, 'LineWidth', 2);
    ax = gca;
    ax.FontSize = 25;
    ax.FontName = 'Times';
    xlabel({'Distance From Where Vessel';'Branches (microns)'},'FontName','Times')
%     xlabel('Distance From  Vessel (microns)','FontName','Times')
    ylabel({'Time Lag Between Ca';'and BBB Perm Peaks (s)'},'FontName','Times')
    zlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
    scatter(minDistsMicrons{1}(3),maxBBBvalTimePoints{1}{per}(3),maxBBBvals{1}{per}(3)*100,'filled','r') 
    % scatter(minDistsMicrons{3}(10),maxBBBvalTimePoints{3}(10),maxBBBvals{3}(10)*100,'filled','b') 
%     xlim([0 120])
end 
%}
%% make nice histograms of Ca ROI to vessel distance and BBB data 
%{
if lightQ == 0 
    
    figure;
%      [~,edges] = histcounts(log10(minDistMicronsAllMice),20);
%      h = histogram(minDistMicronsAllMice,10.^edges);
%      set(gca, 'xscale','log')   
    h = histogram(minDistMicronsAllMice,20);
    ax = gca;
    ax.FontSize = 25;
    ax.FontName = 'Arial';
%     xlabel({'Distance From Where Vessel';'Branches (microns)'},'FontName','Times')
    xlabel('Distance From  Vessel (microns)','FontName','Arial')
    ylabel('Number of Terminals','FontName','Arial')
    h.FaceColor = [0 0.3 0.3];
%     title({'DA terminals with Ca-BBB time lags','between -1 and 0 sec'});
%     ylim([0 8])
%     xlim([0 50])
   
    figure;
    h = histogram(maxBBBvalTimePointsAllMice,20);
    ax = gca;
    ax.FontSize =25;
    ax.FontName = 'Times';
    xlabel({'Time Lag Between Ca';'and BBB Perm Peaks (s)'},'FontName','Times')
    ylabel('Number of Terminals','FontName','Times')
    h.FaceColor = [0 0.3 0.3];
    
    figure;
%     h = histogram(maxBBBvalsAllMice,20);
     [~,edges] = histcounts(log10(maxBBBvalsAllMice),20);
     h = histogram(maxBBBvalsAllMice,10.^edges);
     set(gca, 'xscale','log')   
    ax = gca;
    ax.FontSize = 50;
    ax.FontName = 'Times';
    xlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
    ylabel('Number of Terminals','FontName','Times')
    h.FaceColor = [0 0.3 0.3];
    
elseif lightQ == 1 
    
    per = input('Input 1 for blue light period. Input 2 for red light period. Input 3 for light off period. ');
    
    figure;
     [~,edges] = histcounts(log10(minDistMicronsAllMice),20);
     h = histogram(minDistMicronsAllMice,10.^edges);
     set(gca, 'xscale','log')    
%     h = histogram(minDistMicronsAllMice,20);
    ax = gca;
    ax.FontSize = 50;
    ax.FontName = 'Times';
%     xlabel({'Distance From Where Vessel';'Branches (microns)'},'FontName','Times')
    xlabel('Distance From  Vessel (microns)','FontName','Times')
    ylabel('Number of Terminals','FontName','Times')
    h.FaceColor = [0 0.3 0.3];
    
    figure;
    h = histogram(maxBBBvalTimePointsAllMice{per},20);
    ax = gca;
    ax.FontSize = 25;
    ax.FontName = 'Times';
    xlabel({'Time Lag Between Ca';'and BBB Perm Peaks (s)'},'FontName','Times')
    ylabel('Number of Terminals','FontName','Times')
    h.FaceColor = [0 0.3 0.3];
    
    figure;
%     h = histogram(maxBBBvalsAllMice{per},20);
    [~,edges] = histcounts(log10(maxBBBvalsAllMice{per}),20);
    h = histogram(maxBBBvalsAllMice{per},10.^edges);
    set(gca, 'xscale','log')  
    ax = gca;
    ax.FontSize = 50;
    ax.FontName = 'Times';
    xlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
    ylabel('Number of Terminals','FontName','Times')
    h.FaceColor = [0 0.3 0.3];
end 
%}
%% make multi-color histograms of Ca ROI to vessel distance and BBB data
%{
clear minDistMicrons_LowGroup maxBBBvalTimePoints_LowGroup maxBBBvals_LowGroup minDistMicrons_HighGroup maxBBBvalTimePoints_HighGroup maxBBBvals_HighGroup

if lightQ == 0 
   %{
    %create groups 
    %starting off simple - just do two colors/groups 
    %Ca ROIs are broken down into two groups based on their distance 
    distCutOff = input('What Ca ROI to vessel distance (in microns) is your cut off point? ');
%     minDistMicrons_LowGroup = zeros(1,sum(minDistMicronsAllMice(:) < distCutOff));
%     maxBBBvalTimePoints_LowGroup = zeros(1,sum(minDistMicronsAllMice(:) < distCutOff));
%     maxBBBvals_LowGroup = zeros(1,sum(minDistMicronsAllMice(:) < distCutOff));
%     minDistMicrons_HighGroup = zeros(1,sum(minDistMicronsAllMice(:) > distCutOff));
%     maxBBBvalTimePoints_HighGroup = zeros(1,sum(minDistMicronsAllMice(:) > distCutOff));
%     maxBBBvals_HighGroup = zeros(1,sum(minDistMicronsAllMice(:) > distCutOff));
    counter1 = 1;
    counter2 = 1;
    for term = 1:length(minDistMicronsAllMice)
        if maxBBBvalsAllMice(term) > 10
            if minDistMicronsAllMice(term) < distCutOff
                minDistMicrons_LowGroup(counter1) = minDistMicronsAllMice(term); 
                maxBBBvalTimePoints_LowGroup(counter1) = maxBBBvalTimePointsAllMice(term); 
                maxBBBvals_LowGroup(counter1) = maxBBBvalsAllMice(term); 
                counter1 = counter1 + 1;
            elseif minDistMicronsAllMice(term) > distCutOff
                minDistMicrons_HighGroup(counter2) = minDistMicronsAllMice(term); 
                maxBBBvalTimePoints_HighGroup(counter2) = maxBBBvalTimePointsAllMice(term); 
                maxBBBvals_HighGroup(counter2) = maxBBBvalsAllMice(term);
                counter2 = counter2 + 1;
            end 
        end
    end 

    %@@@@@@@@@@@@@@
    counter1 = 1;
    counter2 = 1;
    for term = 1:length(minDistMicronsAllMice)       
        if  maxBBBvalTimePointsAllMice(term) < -1 
            minDistMicrons_LowGroup(counter1) = minDistMicronsAllMice(term); 
            maxBBBvalTimePoints_LowGroup(counter1) = maxBBBvalTimePointsAllMice(term); 
            maxBBBvals_LowGroup(counter1) = maxBBBvalsAllMice(term); 
            counter1 = counter1 + 1;
        elseif maxBBBvalTimePointsAllMice(term) > -1 && maxBBBvalTimePointsAllMice(term) < 0
            minDistMicrons_HighGroup(counter2) = minDistMicronsAllMice(term); 
            maxBBBvalTimePoints_HighGroup(counter2) = maxBBBvalTimePointsAllMice(term); 
            maxBBBvals_HighGroup(counter2) = maxBBBvalsAllMice(term);
            counter2 = counter2 + 1;
        end       
    end 
    
    figure;
    binRange = linspace(0,max(maxBBBvalsAllMice),22);
    % linear
    h1 = histcounts(minDistMicrons_LowGroup,[binRange Inf]);
    h2 = histcounts(minDistMicrons_HighGroup,[binRange Inf]);   
    b = bar(binRange,[h1;h2]',1);  
    b(1).FaceColor = [0 0.3 0.3];
    b(2).FaceColor = [0 0.9 0.9];
    ax = gca;
    ax.FontSize = 25;
    ax.FontName = 'Times';
    ylabel('Number of Terminals','FontName','Times')
    xlabel('Distance From Vessel (microns)','FontName','Times')
    xlim([-5 50])
%     legend('<-1 sec CA-BBB time lag','-1-0 sec Ca-BBB time lag')
    legend('-1-0 sec Ca-BBB time lag')
    
    % plot    
    figure;
    binRange = linspace(-2.5,2.5,22);
    h1 = histcounts(maxBBBvalTimePoints_LowGroup,[binRange Inf]);
    h2 = histcounts(maxBBBvalTimePoints_HighGroup,[binRange Inf]);   
    b = bar(binRange,[h1;h2]',1);  
    b(1).FaceColor = [0 0.3 0.3];
    b(2).FaceColor = [0 0.9 0.9];
    ax = gca;
    ax.FontSize =25;
    ax.FontName = 'Times';
    xlabel({'Time Lag Between Ca';'and BBB Perm Peaks (s)'},'FontName','Times')
    ylabel('Number of Terminals','FontName','Times')
    legend(sprintf('< %d microns',distCutOff),sprintf('> %d microns',distCutOff))
 
 
    figure;
    binRange = linspace(0,max(maxBBBvalsAllMice),22);
    % linear
    h1 = histcounts(maxBBBvals_LowGroup,[binRange Inf]);
    h2 = histcounts(maxBBBvals_HighGroup,[binRange Inf]);   
    b = bar(binRange,[h1;h2]',1);  
    b(1).FaceColor = [0 0.3 0.3];
    b(2).FaceColor = [0 0.9 0.9];
    ax = gca;
    ax.FontSize = 25;
    ax.FontName = 'Times';
    xlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
    ylabel('Number of Terminals','FontName','Times')
%     legend(sprintf('< %d microns',distCutOff),sprintf('> %d microns',distCutOff))
 
    
    figure;
    binRange = linspace(0,max(maxBBBvalsAllMice),22);
    % log scale 
    [h1,edges1] = histcounts(log10(maxBBBvals_LowGroup),length(binRange));
    [h2,edges2] = histcounts(log10(maxBBBvals_HighGroup),length(binRange));
    b = bar(10.^edges1(1:length(edges1)-1)',[h1;h2]',1);  
    b(1).FaceColor = [0 0.3 0.3];
    b(2).FaceColor = [0 0.9 0.9];    
    set(gca, 'xscale','log') 
    ax = gca;
    ax.FontSize = 25;
    ax.FontName = 'Times';
    xlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
    ylabel('Number of Terminals','FontName','Times')
    legend(sprintf('< %d microns',distCutOff),sprintf('> %d microns',distCutOff))
    %}
elseif lightQ == 1 
    %{
    %create groups 
    %starting off simple - just do two colors/groups 
    %Ca ROIs are broken down into two groups based on their distance 
    distCutOff = input('What Ca ROI to vessel distance (in microns) is your cut off point? ');
    per = input('Input 3 for light off period. Input 2 for red light. Input 1 for blue light. ');
%     minDistMicrons_LowGroup = zeros(1,sum(minDistMicronsAllMice(:) < distCutOff));
%     maxBBBvalTimePoints_LowGroup = zeros(1,sum(minDistMicronsAllMice(:) < distCutOff));
%     maxBBBvals_LowGroup = zeros(1,sum(minDistMicronsAllMice(:) < distCutOff));
%     minDistMicrons_HighGroup = zeros(1,sum(minDistMicronsAllMice(:) > distCutOff));
%     maxBBBvalTimePoints_HighGroup = zeros(1,sum(minDistMicronsAllMice(:) > distCutOff));
%     maxBBBvals_HighGroup = zeros(1,sum(minDistMicronsAllMice(:) > distCutOff));
    counter1 = 1;
    counter2 = 1;
    for term = 1:length(minDistMicronsAllMice)
        if maxBBBvalsAllMice{per}(term) > 10
            if minDistMicronsAllMice(term) < distCutOff
                minDistMicrons_LowGroup(counter1) = minDistMicronsAllMice(term); 
                maxBBBvalTimePoints_LowGroup(counter1) = maxBBBvalTimePointsAllMice{per}(term); 
                maxBBBvals_LowGroup(counter1) = maxBBBvalsAllMice{per}(term); 
                counter1 = counter1 + 1;
            elseif minDistMicronsAllMice(term) > distCutOff
                minDistMicrons_HighGroup(counter2) = minDistMicronsAllMice(term); 
                maxBBBvalTimePoints_HighGroup(counter2) = maxBBBvalTimePointsAllMice{per}(term); 
                maxBBBvals_HighGroup(counter2) = maxBBBvalsAllMice{per}(term);
                counter2 = counter2 + 1;
            end
        end 
    end 

    % plot    
    figure;
    binRange = linspace(-2.5,2.5,22);
    h1 = histcounts(maxBBBvalTimePoints_LowGroup,[binRange Inf]);
    h2 = histcounts(maxBBBvalTimePoints_HighGroup,[binRange Inf]);   
    b = bar(binRange,[h1;h2]',1);  
    b(1).FaceColor = [0 0.3 0.3];
    b(2).FaceColor = [0 0.9 0.9];
    ax = gca;
    ax.FontSize =25;
    ax.FontName = 'Times';
    xlabel({'Time Lag Between Ca';'and BBB Perm Peaks (s)'},'FontName','Times')
    ylabel('Number of Terminals','FontName','Times')
    legend(sprintf('< %d microns',distCutOff),sprintf('> %d microns',distCutOff))
 
 
    figure;
    binRange = linspace(0,max(maxBBBvalsAllMice{per}),22);
    % linear
    h1 = histcounts(maxBBBvals_LowGroup,[binRange Inf]);
    h2 = histcounts(maxBBBvals_HighGroup,[binRange Inf]);   
    b = bar(binRange,[h1;h2]',1);  
    b(1).FaceColor = [0 0.3 0.3];
    b(2).FaceColor = [0 0.9 0.9];
    ax = gca;
    ax.FontSize = 25;
    ax.FontName = 'Times';
    xlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
    ylabel('Number of Terminals','FontName','Times')
    legend(sprintf('< %d microns',distCutOff),sprintf('> %d microns',distCutOff))
    
    figure;
    binRange = linspace(0,max(maxBBBvalsAllMice{per}),22);
    % log scale 
    [h1,edges1] = histcounts(log10(maxBBBvals_LowGroup),length(binRange));
    [h2,edges2] = histcounts(log10(maxBBBvals_HighGroup),length(binRange));
    b = bar(10.^edges1(1:length(edges1)-1)',[h1;h2]');  
    b(1).FaceColor = [0 0.3 0.3];
    b(2).FaceColor = [0 0.9 0.9];    
    set(gca, 'xscale','log') 
    ax = gca;
    ax.FontSize = 25;
    ax.FontName = 'Times';
    xlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
    ylabel('Number of Terminals','FontName','Times')
    legend(sprintf('< %d microns',distCutOff),sprintf('> %d microns',distCutOff))
    %}
end 
%}
%% fit the distributions and overlay the fits 
%{
clear maxBBBvals_HighGroup maxBBBvals_LowGroup maxBBBvalTimePoints_HighGroup maxBBBvalTimePoints_LowGroup minDistMicrons_HighGroup minDistMicrons_LowGroup

distCutOff = input('What Ca ROI to vessel distance (in microns) is your cut off point? ');
if lightQ == 0 
    %create groups 
    %starting off simple - just do two colors/groups 
    %Ca ROIs are broken down into two groups based on their distance 
%     minDistMicrons_LowGroup = zeros(1,sum(minDistMicronsAllMice(:) < distCutOff));
%     maxBBBvalTimePoints_LowGroup = zeros(1,sum(minDistMicronsAllMice(:) < distCutOff));
%     maxBBBvals_LowGroup = zeros(1,sum(minDistMicronsAllMice(:) < distCutOff));
%     minDistMicrons_HighGroup = zeros(1,sum(minDistMicronsAllMice(:) > distCutOff));
%     maxBBBvalTimePoints_HighGroup = zeros(1,sum(minDistMicronsAllMice(:) > distCutOff));
%     maxBBBvals_HighGroup = zeros(1,sum(minDistMicronsAllMice(:) > distCutOff));
    counter1 = 1;
    counter2 = 1;
    for term = 1:length(minDistMicronsAllMice)
        if maxBBBvalsAllMice(term) > 10
            if minDistMicronsAllMice(term) < distCutOff
                minDistMicrons_LowGroup(counter1) = minDistMicronsAllMice(term); 
                maxBBBvalTimePoints_LowGroup(counter1) = maxBBBvalTimePointsAllMice(term); 
                maxBBBvals_LowGroup(counter1) = maxBBBvalsAllMice(term); 
                counter1 = counter1 + 1;
            elseif minDistMicronsAllMice(term) > distCutOff
                minDistMicrons_HighGroup(counter2) = minDistMicronsAllMice(term); 
                maxBBBvalTimePoints_HighGroup(counter2) = maxBBBvalTimePointsAllMice(term); 
                maxBBBvals_HighGroup(counter2) = maxBBBvalsAllMice(term);
                counter2 = counter2 + 1;
            end 
        end 
    end 
elseif lightQ == 1 
    %create groups 
    %starting off simple - just do two colors/groups 
    %Ca ROIs are broken down into two groups based on their distance 
    per = input('Input 3 for light off period. Input 2 for red light. Input 1 for blue light. ');
%     minDistMicrons_LowGroup = zeros(1,sum(minDistMicronsAllMice(:) < distCutOff));
%     maxBBBvalTimePoints_LowGroup = zeros(1,sum(minDistMicronsAllMice(:) < distCutOff));
%     maxBBBvals_LowGroup = zeros(1,sum(minDistMicronsAllMice(:) < distCutOff));
%     minDistMicrons_HighGroup = zeros(1,sum(minDistMicronsAllMice(:) > distCutOff));
%     maxBBBvalTimePoints_HighGroup = zeros(1,sum(minDistMicronsAllMice(:) > distCutOff));
%     maxBBBvals_HighGroup = zeros(1,sum(minDistMicronsAllMice(:) > distCutOff));
    counter1 = 1;
    counter2 = 1;
    for term = 1:length(minDistMicronsAllMice)
        if maxBBBvalsAllMice{per}(term) > 10
            if minDistMicronsAllMice(term) < distCutOff
                minDistMicrons_LowGroup(counter1) = minDistMicronsAllMice(term); 
                maxBBBvalTimePoints_LowGroup(counter1) = maxBBBvalTimePointsAllMice{per}(term); 
                maxBBBvals_LowGroup(counter1) = maxBBBvalsAllMice{per}(term); 
                counter1 = counter1 + 1;
            elseif minDistMicronsAllMice(term) > distCutOff
                minDistMicrons_HighGroup(counter2) = minDistMicronsAllMice(term); 
                maxBBBvalTimePoints_HighGroup(counter2) = maxBBBvalTimePointsAllMice{per}(term); 
                maxBBBvals_HighGroup(counter2) = maxBBBvalsAllMice{per}(term);
                counter2 = counter2 + 1;
            end 
        end 
    end 
end 


pd1 = fitdist(maxBBBvalTimePoints_LowGroup','Kernel','BandWidth',0.5); %kernel distribution builds the pdf by creating an individual probability density curve for each data value, then summing the smooth curves. This approach creates one smooth, continuous probability density function for the data set.
pd2 = fitdist(maxBBBvalTimePoints_HighGroup','Kernel','BandWidth',0.5); %kernel good for nonparametric data 
xVals = linspace(-2.5,2.5,22);
yVals1 = pdf(pd1,xVals);
yVals2 = pdf(pd2,xVals);
figure;
plot(xVals,yVals1,'Color',[0 0.3 0.3],'LineWidth',3); hold on;
plot(xVals,yVals2,'Color',[0 0.9 0.9],'LineWidth',3)
ax = gca;
ax.FontSize =25;
ax.FontName = 'Times';
xlabel({'Time Lag Between Ca';'and BBB Perm Peaks (s)'},'FontName','Times')
ylabel('Number of Terminals','FontName','Times')
legend(sprintf('< %d microns',distCutOff),sprintf('> %d microns',distCutOff))

pd1 = fitdist(maxBBBvals_LowGroup','Kernel','BandWidth',5); %kernel distribution builds the pdf by creating an individual probability density curve for each data value, then summing the smooth curves. This approach creates one smooth, continuous probability density function for the data set.
pd2 = fitdist(maxBBBvals_HighGroup','Kernel','BandWidth',5); %kernel good for nonparametric data 
xVals = linspace(0,50,22);
yVals1 = pdf(pd1,xVals);
yVals2 = pdf(pd2,xVals);
figure;
plot(xVals,yVals1,'Color',[0 0.3 0.3],'LineWidth',3); hold on;
plot(xVals,yVals2,'Color',[0 0.9 0.9],'LineWidth',3)
ax = gca;
ax.FontSize =25;
ax.FontName = 'Times';
xlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
ylabel('Number of Terminals','FontName','Times')
legend(sprintf('< %d microns',distCutOff),sprintf('> %d microns',distCutOff))
xlim([0 50])

pd1 = fitdist(maxBBBvals_LowGroup','Kernel','BandWidth',5); %kernel distribution builds the pdf by creating an individual probability density curve for each data value, then summing the smooth curves. This approach creates one smooth, continuous probability density function for the data set.
pd2 = fitdist(maxBBBvals_HighGroup','Kernel','BandWidth',5); %kernel good for nonparametric data 
xVals = linspace(0,50,22);
yVals1 = pdf(pd1,xVals);
yVals2 = pdf(pd2,xVals);
figure;
plot(xVals,yVals1,'Color',[0 0.3 0.3],'LineWidth',3); hold on;
plot(xVals,yVals2,'Color',[0 0.9 0.9],'LineWidth',3)
ax = gca;
ax.FontSize =25;
ax.FontName = 'Times';
xlabel({'Amplitude of';'BBB Perm Peak'},'FontName','Times')
ylabel('Number of Terminals','FontName','Times')
legend(sprintf('< %d microns',distCutOff),sprintf('> %d microns',distCutOff))
set(gca, 'xscale','log')   
xlim([0 50])

%}
%% figure out what Ca ROIs fall into distance (from vessel) categories 
%{
distCutOff = input('What Ca ROI to vessel distance (in microns) is your cut off point? ');
closeCaROIs = cell(1,mouseNum);
closeCaROIDists = cell(1,mouseNum);
% closeCaROI_CaBBBtimeLags = cell(1,mouseNum);
farCaROIs = cell(1,mouseNum);
farCaROIDists = cell(1,mouseNum);
% farCaROI_CaBBBtimeLags = cell(1,mouseNum);
% mouseTerms = cell(1,mouseNum);
for mouse = 1:mouseNum
%     mouseTerms{mouse} = input(sprintf('What Ca ROIs do you care about for mouse %d ', mouse));
    
    closeCaROIs{mouse} = mouseTerms{mouse}((minDistsMicrons{mouse} < distCutOff));
    closeCaROIDists{mouse} = minDistsMicrons{mouse}((minDistsMicrons{mouse} < distCutOff));
%     closeCaROI_CaBBBtimeLags{mouse} = maxBBBvalTimePoints{mouse}((minDistsMicrons{mouse} < distCutOff));
    farCaROIs{mouse} = mouseTerms{mouse}((minDistsMicrons{mouse} > distCutOff));
    farCaROIDists{mouse} = minDistsMicrons{mouse}((minDistsMicrons{mouse} > distCutOff));
%     farCaROI_CaBBBtimeLags{mouse} = maxBBBvalTimePoints{mouse}((minDistsMicrons{mouse} > distCutOff));
end 
% clearvars -except closeCaROIs closeCaROIDists closeCaROI_CaBBBtimeLags farCaROIs farCaROIDists farCaROI_CaBBBtimeLags
%}