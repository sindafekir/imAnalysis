%% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% WHEN ANALYZING VOLUME IMAGING DATA - MAKE SURE THE STIM START AND END
% FRAMES MAKE SENSE!!!!!!
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% get the data you need 
% includes batch processing (across mice) option for STA/ETA figure generation
%{
%set the paramaters 
ETAQ = input('Input 1 if you want to plot event/spike triggered averages. Input 0 if otherwise. '); 
STAstackQ = input('Input 1 to import red and green channel stacks to create STA videos. Input 0 otherwise. ');
ETAstackQ = input('Input 1 to import red and green channel stacks to create ETA videos. Input 0 otherwise. '); 
distQ = input('Input 1 if you want to determine distance of Ca ROIs from vessel. Input 0 otherwise. ');
if STAstackQ == 1 || distQ == 1 || ETAstackQ == 1 
    BGsubQ = input('Input 1 if you want to do background subtraction on your imported image stacks. Input 0 otherwise. ');
    if BGsubQ == 1
        BGsubTypeQ = input('Input 0 to do a simple background subtraction. Input 1 if you want to do row by row background subtraction. ');
    end 
end 
if ETAQ == 1 || STAstackQ == 1 || ETAstackQ == 1
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
if ETAQ == 1 || STAstackQ == 1 
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
            dirLabel = sprintf('WHERE IS THE DATA FOR MOUSE #%d? ',mouse);
            dataDir{mouse} = uigetdir('*.*',dirLabel);
            cd(dataDir{mouse}); % go to the right directory 
            if CAQ == 1 
                % get calcium data 
                terminals{mouse} = input(sprintf('What terminals do you care about for mouse #%d? Input in correct order. ',mouse));    
                CAfileList = dir('**/*CAdata_*.mat'); % list data files in current directory 
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
                [~,statestartf,stateendf,~,vel_wheel_data,trialTypes] = makeHDFchart_redBlueStim(state,framePeriod,vidList{mouse}(vid),mouse);
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
                        [~,c] = min(abs(trialLengths2{vid}(trial)-stimFrameLengths));
                        trialLengths{mouse}{vid}(trial) = stimFrameLengths(c);
                        state_end_f{mouse}{vid}(trial) = state_start_f{mouse}{vid}(trial) + stimFrameLengths(c);
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
                        % determine the correct length of frames per trial
                        % (accounts for rounding/discrete time issues 
                        [~,c] = min(abs(trialLengths2{vid}(trial)-stimFrameLengths));
                        trialLengths{mouse}{vid}(trial) = stimFrameLengths(c);
                        state_end_f{mouse}{vid}(trial) = state_start_f{mouse}{vid}(trial) + stimFrameLengths(c);
                    end 
                end 
            end 
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
            redStacks1{vid} = redRegStacks{2,4};
        elseif size(redRegStacks,2) == 2 
            redStacks1{vid} = redRegStacks{2,2};
        end 
        greenMat = matfile(sprintf(greenlabel,vidList{mouse}(vid)));       
        greenRegStacks = greenMat.regStacks;        
        if size(greenRegStacks,2) > 2 
            greenStacks1{vid} = greenRegStacks{2,3};
        elseif size(greenRegStacks,2) == 2 
            greenStacks1{vid} = greenRegStacks{2,1};
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
        for Z = 1:size(redStacks1{1},2)
            redStackArray{vid}(:,:,:,Z) = redStacksBS{vid}{Z};
            greenStackArray{vid}(:,:,:,Z) = greenStacksBS{vid}{Z};
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
    state_end_f2 = cell(1,length(vidList{mouse}));
    trialLengths2 = cell(1,length(vidList{mouse}));
    for vid = 1:length(vidList{mouse})
        [statestartf,stateendf] = behavior_FindStateBounds(state,framePeriod);
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
                % determine the correct length of frames per trial
                % (accounts for rounding/discrete time issues 
                [~,c] = min(abs(trialLengths2{vid}(trial)-stimFrameLengths));
                trialLengths{mouse}{vid}(trial) = stimFrameLengths(c);
                state_end_f{mouse}{vid}(trial) = state_start_f{mouse}{vid}(trial) + stimFrameLengths(c);
            end 
        end 
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
%% ETA: organize trial data; can select what trials to plot; can separate trials by ITI length
% smooth, normalize, and plot data (per mouse - optimized for batch
% processing. saves the data out per mouse)
%{
% get the data if it already isn't in the workspace 
workspaceQ = input('Input 1 if batch data is already in the workspace. Input 0 otherwise. ');
if workspaceQ == 1
    dataDir = cell(1,mouseNum);
    for mouse = 1:mouseNum
        dirLabel = sprintf('WHERE DO YOU WANT TO SAVE OUT THE DATA FOR MOUSE #%d? ',mouse);
        dataDir{mouse} = uigetdir('*.*',dirLabel);
    end 
elseif workspaceQ == 0 
    dataOrgQ = input('Input 1 if the batch processing data is saved in one .mat file. Input 0 if you need to open multiple .mat files (one per animal). ');
    if dataOrgQ == 1 
        dirLabel = 'WHERE IS THE BATCH DATA? ';
        dataDir2 = uigetdir('*.*',dirLabel);
        cd(dataDir2); % go to the right directory 
        uiopen('*.mat'); % get data                  
        mouseNum = input('How many mice are there? ');
        dataDir = cell(1,mouseNum);
        for mouse = 1:mouseNum
            dirLabel = sprintf('WHERE DO YOU WANT TO SAVE OUT THE DATA FOR MOUSE #%d? ',mouse);
            dataDir{mouse} = uigetdir('*.*',dirLabel);
        end 
    elseif dataOrgQ == 0
        mouseNum = input('How many mice are there? ');
        dataDir2 = cell(1,mouseNum);
        dataDir = cell(1,mouseNum);
        bDataFullTrace1 = cell(1,mouseNum);
        cDataFullTrace1 = cell(1,mouseNum);
        vDataFullTrace1 = cell(1,mouseNum);
        terminals1 = cell(1,mouseNum);
        state_start_f1 = cell(1,mouseNum);
        TrialTypes1 = cell(1,mouseNum);
        state_end_f1 = cell(1,mouseNum);
        trialLengths1 = cell(1,mouseNum);
        FPSstack1 = cell(1,mouseNum);
        vidList1 = cell(1,mouseNum);
        for mouse = 1:mouseNum
            dirLabel = sprintf('WHERE IS THE DATA FOR MOUSE #%d? ',mouse);
            dataDir2{mouse} = uigetdir('*.*',dirLabel);
            cd(dataDir2{mouse}); % go to the right directory 
            uiopen('*.mat'); % get data  
            if BBBQ == 1     
                bDataFullTrace1{mouse} = bDataFullTrace;
            end 
            if CAQ == 1
                cDataFullTrace1{mouse} = cDataFullTrace;
                terminals1{mouse} = terminals;
            end 
            if VWQ == 1 
                vDataFullTrace1{mouse} = vDataFullTrace;
            end 
            state_start_f1{mouse} = state_start_f;            
            TrialTypes1{mouse} = TrialTypes;
            state_end_f1{mouse} = state_end_f;              
            trialLengths1{mouse} = trialLengths;      
            FPSstack1{mouse} = FPSstack;             
            vidList1{mouse} = vidList;                            
            dirLabel = sprintf('WHERE DO YOU WANT TO SAVE OUT THE DATA FOR MOUSE #%d? ',mouse);
            dataDir{mouse} = uigetdir('*.*',dirLabel);       
        end 
        clear bDataFullTrace cDataFullTrace vDataFullTrace terminals state_start_f TrialTypes state_end_f trialLengths FPSstack vidList
        bDataFullTrace = bDataFullTrace1;
        cDataFullTrace = cDataFullTrace1;
        vDataFullTrace = vDataFullTrace1;
        terminals = terminals1;
        state_start_f = state_start_f1;
        TrialTypes = TrialTypes1;
        state_end_f = state_end_f1;
        trialLengths = trialLengths1;
        FPSstack = FPSstack1;
        vidList = vidList1;
    end 
end 

% set initial paramaters 
dataParseType = input("What data do you need? Peristimulus epoch = 0. Stimulus epoch = 1. ");
if dataParseType == 0 
    sec_before_stim_start = input("How many seconds before the stimulus starts do you want to plot? ");
    sec_after_stim_end = input("How many seconds after stimulus end do you want to plot? ");
elseif dataParseType == 1 
    sec_before_stim_start = 0;
    sec_after_stim_end = 0; 
end 
numTtypes = input('How many different trial types are there? ');

%% generate the figures and save the data out per mouse 

saveDataQ = input('Input 1 to save the data out. '); 
trialData = cell(1,mouseNum);
tTypes = cell(1,mouseNum); 
vidCheck = cell(1,mouseNum); 
for mouse = 1:mouseNum
    dir1 = dataDir{mouse};   
    % determine plotting start and end frames 
    plotStart = cell(1,length(bDataFullTrace{mouse}));
    plotEnd = cell(1,length(bDataFullTrace{mouse}));
    for vid = 1:length(bDataFullTrace{mouse})
    %     count = 1;
        for trial = 1:length(state_start_f{mouse}{vid})  
            if trialLengths{mouse}{vid}(trial) ~= 0 
                if dataParseType == 0    
                    if (state_start_f{mouse}{vid}(trial) - floor(sec_before_stim_start*FPSstack{mouse})) > 0 && state_end_f{mouse}{vid}(trial) + floor(sec_after_stim_end*FPSstack{mouse}) < length(bDataFullTrace{mouse}{vid}{1})
                        plotStart{vid}(trial) = state_start_f{mouse}{vid}(trial) - floor(sec_before_stim_start*FPSstack{mouse});
                        plotEnd{vid}(trial) = state_end_f{mouse}{vid}(trial) + floor(sec_after_stim_end*FPSstack{mouse});                    
                    end            
                elseif dataParseType == 1  
                    plotStart{vid}(trial) = state_start_f{mouse}{vid}(trial);
                    plotEnd{vid}(trial) = state_end_f{mouse}{vid}(trial);                
                end   
            end 
        end 
    end 

    % sort the data  
    if CAQ == 1
        Ceta = cell(1,length(cDataFullTrace{mouse}{1}));
    end 
    if BBBQ == 1 
        Beta = cell(1,length(bDataFullTrace{mouse}{1}));
    end 
    if VWQ == 1
        Veta = cell(1,length(vDataFullTrace{mouse}{1}));
    end 
    if velWheelQ == 1 
        Weta = cell(1,numTtypes);
    end 

    if CAQ == 0 
        ccellLen = 1;
    elseif CAQ == 1 
        ccellLen = length(terminals{mouse});
    end 

    % makes faux trial type array for behavior data so all behavior data trials
    % (based on selected state) get sorted into the same cell 
    % For opto data, the state is either 7 or 8, but there are 4 different
    % kinds of trials within those states. 
    % For behavior data, you select whatever state you want, but there is only
    % one trial type 
    if optoQ == 0 
        TrialTypes{mouse} = cell(1,length(bDataFullTrace{mouse}));
        for vid = 1:length(bDataFullTrace{mouse})  
            TrialTypes{mouse}{vid}(1:length(plotStart{vid}),1) = 1:length(plotStart{vid});  
            TrialTypes{mouse}{vid}(1:length(plotStart{vid}),2) = 1;        
        end 
    end 

    % pick what trials are averaged 
    if mouse == 1 
        trialQ = input('Input 1 to select what trials to average and plot. Input 0 for all trials. ');
    end 
    if trialQ == 0
        trialList = cell(1,length(bDataFullTrace{mouse}));
        for vid = 1:length(bDataFullTrace{mouse})   
            trialList{vid} = 1:length(plotStart{vid});
        end 
    elseif trialQ == 1 
        trialList{vid} = input(sprintf('What trials do you want to average and plot for mouse #%d vid #%d? ',mouse,vid));
    end 

    % figure out ITI length and sort ITI length into trial type 
    if mouse == 1 
        ITIq = input('Input 1 to separate data based on ITI length. Input 0 otherwise. ');
    end 
    if ITIq == 1 
        trialLenFrames = cell(1,length(bDataFullTrace{mouse}));
        trialLenTimes = cell(1,length(bDataFullTrace{mouse}));
        minMaxTrialLenTimes = cell(1,length(bDataFullTrace{mouse}));
        for vid = 1:length(bDataFullTrace{mouse})  
            if trialList{vid}(1) > 1 
                trialLenFrames{vid}(1) = state_start_f{mouse}{vid}(trialList{vid}(1))-state_start_f{mouse}{vid}(trialList{vid}(1)-1);    
            elseif trialList{vid}(1) == 1 
                trialLenFrames{vid}(1) = state_start_f{mouse}{vid}(trialList{vid}(1))-1;    
            end 
            trialLenFrames{vid}(2:length(trialList{vid})) = state_start_f{mouse}{vid}(trialList{vid}(2:end))-state_end_f{mouse}{vid}(trialList{vid}(1:end-1));
            trialLenTimes{vid} = trialLenFrames{vid}/FPSstack{mouse};
            minMaxTrialLenTimes{vid}(1) = min(trialLenTimes{vid});
            minMaxTrialLenTimes{vid}(2) = max(trialLenTimes{vid});
            figure; histogram(trialLenTimes{vid})
            display(minMaxTrialLenTimes{vid})
        end 
        trialLenThreshTime = input(sprintf('Input the ITI thresh (sec) to separate data by for mouse #%d vid #%d. ',mouse,vid)); 
        trialListHigh = cell(1,length(bDataFullTrace{mouse}));
        trialListLow = cell(1,length(bDataFullTrace{mouse}));
        for vid = 1:length(bDataFullTrace{mouse}) 
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
    %sort data 
    for ccell = 1:ccellLen
        count1 = 1;
        count2 = 1;
        count3 = 1;
        count4 = 1;
        for vid = 1:length(bDataFullTrace{mouse})    
            for trial = 1:length(trialList{vid}) 
                if trialLengths{mouse}{vid}(trialList{vid}(trial)) ~= 0 
                     if (state_start_f{mouse}{vid}(trialList{vid}(trial)) - floor(sec_before_stim_start*FPSstack{mouse})) > 0 && state_end_f{mouse}{vid}(trialList{vid}(trial)) + floor(sec_after_stim_end*FPSstack{mouse}) < length(bDataFullTrace{mouse}{vid}{1})
                        %if the blue light is on
                        if TrialTypes{mouse}{vid}(trialList{vid}(trial),2) == 1
                            %if it is a 2 sec trial 
                            if trialLengths{mouse}{vid}(trialList{vid}(trial)) == floor(2*FPSstack{mouse})     
                                if CAQ == 1
                                    Ceta{terminals{mouse}(ccell)}{1}(count1,:) = cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                end 
                                if BBBQ == 1 
                                    for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                                        Beta{BBBroi}{1}(count1,:) = bDataFullTrace{mouse}{vid}{BBBroi}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                    end 
                                end 
                                if VWQ == 1
                                    for VWroi = 1:length(vDataFullTrace{mouse}{1})
                                        Veta{VWroi}{1}(count1,:) = vDataFullTrace{mouse}{vid}{VWroi}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                    end 
                                end 
                                if velWheelQ == 1 
                                    Weta{1}(count1,:) = wDataFullTrace{mouse}{vid}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                end 
                                count1 = count1 + 1;                    
                            %if it is a 20 sec trial
                            elseif trialLengths{mouse}{vid}(trialList{vid}(trial)) == floor(20*FPSstack{mouse})
                                if CAQ == 1
                                    Ceta{terminals{mouse}(ccell)}{2}(count2,:) = cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                end 
                                if BBBQ == 1 
                                    for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                                        Beta{BBBroi}{2}(count2,:) = bDataFullTrace{mouse}{vid}{BBBroi}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                    end 
                                end 
                                if VWQ == 1
                                    for VWroi = 1:length(vDataFullTrace{mouse}{1})
                                        Veta{VWroi}{2}(count2,:) = vDataFullTrace{mouse}{vid}{VWroi}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                    end 
                                end 
                                if velWheelQ == 1 
                                    Weta{2}(count2,:) = wDataFullTrace{mouse}{vid}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                end 
                                count2 = count2 + 1;
                            end 
                        %if the red light is on 
                        elseif TrialTypes{mouse}{vid}(trialList{vid}(trial),2) == 2
                            %if it is a 2 sec trial 
                            if trialLengths{mouse}{vid}(trialList{vid}(trial)) == floor(2*FPSstack{mouse})
                                if CAQ == 1
                                    Ceta{terminals{mouse}(ccell)}{3}(count3,:) = cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                end 
                                if BBBQ == 1 
                                    for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                                        Beta{BBBroi}{3}(count3,:) = bDataFullTrace{mouse}{vid}{BBBroi}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                    end 
                                end 
                                if VWQ == 1
                                    for VWroi = 1:length(vDataFullTrace{mouse}{1})
                                        Veta{VWroi}{3}(count3,:) = vDataFullTrace{mouse}{vid}{VWroi}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                    end
                                end 
                                if velWheelQ == 1 
                                    Weta{3}(count3,:) = wDataFullTrace{mouse}{vid}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                end 
                                count3 = count3 + 1;                    
                            %if it is a 20 sec trial
                            elseif trialLengths{mouse}{vid}(trialList{vid}(trial)) == floor(20*FPSstack{mouse})
                                if CAQ == 1
                                    Ceta{terminals{mouse}(ccell)}{4}(count4,:) = cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                end 
                                if BBBQ == 1 
                                    for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                                        Beta{BBBroi}{4}(count4,:) = bDataFullTrace{mouse}{vid}{BBBroi}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                    end 
                                end 
                                if VWQ == 1
                                    for VWroi = 1:length(vDataFullTrace{mouse}{1})
                                        Veta{VWroi}{4}(count4,:) = vDataFullTrace{mouse}{vid}{VWroi}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                                    end 
                                end 
                                if velWheelQ == 1 
                                    Weta{4}(count4,:) = wDataFullTrace{mouse}{vid}(plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
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
            for ccell = 1:length(terminals{mouse})    
                % replace zero values with NaNs
                nonZeroRowsC = all(Ceta{terminals{mouse}(ccell)}{tType} == 0,2);
                Ceta{terminals{mouse}(ccell)}{tType}(nonZeroRowsC,:) = NaN;
                % determine the minimum value, add space (+100)
                minValToAdd = abs(ceil(min(min(Ceta{terminals{mouse}(ccell)}{tType}))))+100;
                % add min value 
                Ceta{terminals{mouse}(ccell)}{tType} = Ceta{terminals{mouse}(ccell)}{tType} + minValToAdd;                        
            end 
        end 
        if BBBQ == 1 
            for BBBroi = 1:length(bDataFullTrace{mouse}{1})
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
            for VWroi = 1:length(vDataFullTrace{mouse}{1})
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
    
    % make sure tType index is known for given ttype num 
    if optoQ == 1 
        % check to see if red or blue opto lights were used       
        for vid = 1:length(TrialTypes{mouse})   
            % combine trialTypes and trialLengths 
            trialData{mouse}{vid}(:,1) = TrialTypes{mouse}{vid}(:,2);
            trialData{mouse}{vid}(:,2) = trialLengths{mouse}{vid};
            % determine the combination of trialTypes and lengths that
            % occur per vid 
            %if the blue light is on for 2 seconds
            if any(ismember(trialData{mouse}{vid},[1,floor(2*FPSstack{mouse})],'rows') == 1)
                tTypes{mouse}{vid}(1) = 1;              
            end 
            %if the blue light is on for 20 seconds 
            if any(ismember(trialData{mouse}{vid},[1,floor(20*FPSstack{mouse})],'rows') == 1)
                tTypes{mouse}{vid}(2) = 2;
            end 
            %if the red light is on for 2 seconds 
            if any(ismember(trialData{mouse}{vid},[2,floor(2*FPSstack{mouse})],'rows') == 1)
                tTypes{mouse}{vid}(3) = 3;
            end 
            %if the red light is on for 20 seconds    
            if any(ismember(trialData{mouse}{vid},[2,floor(20*FPSstack{mouse})],'rows') == 1)
                tTypes{mouse}{vid}(4) = 4;
            end 
            if any(tTypes{mouse}{vid} == 1)
                vidCheck{mouse}(vid,1) = 1;
            end 
            if any(tTypes{mouse}{vid} == 2)
                vidCheck{mouse}(vid,2) = 2;
            end 
            if any(tTypes{mouse}{vid} == 3)
                vidCheck{mouse}(vid,3) = 3;
            end 
            if any(tTypes{mouse}{vid} == 4)
                vidCheck{mouse}(vid,4) = 4;
            end             
        end  
        if sum(any(vidCheck{mouse} == 1)) > 0  
            tTypeInds(1) = 1;
        end 
        if sum(any(vidCheck{mouse} == 2)) > 0 
            tTypeInds(2) = 2;
        end 
        if sum(any(vidCheck{mouse} == 3)) > 0 
            tTypeInds(3) = 3;
        end 
        if sum(any(vidCheck{mouse} == 4)) > 0 
            tTypeInds(4) = 4; 
        end 
    elseif optoQ == 0
        tTypeInds = 1;
    end 
    if optoQ == 1 
        % make sure the number of trialTypes in the data matches up with what
        % you think it should
        if length(nonzeros(unique(vidCheck{mouse}))) == numTtypes 
            % make sure the trial type index is known for the code below
            tTypeInds = nonzeros(unique(vidCheck{mouse}));
        elseif length(nonzeros(unique(vidCheck{mouse}))) ~= numTtypes
            disp('The number of trial types in the data does not match up with the number of trial types inputed by user!!!');
        end 
    end 
    
    % smooth data
    if mouse == 1 
        smoothQ =  input('Do you want to smooth your data? Yes = 1. No = 0. ');
    end 
    if smoothQ ==  1
        if mouse == 1             
            filtTime = input('How many seconds do you want to smooth your data by? ');
        end 
        if CAQ == 1
            sCeta = cell(1,length(cDataFullTrace{mouse}{1}));
        end 
        if BBBQ == 1 
            sBeta = cell(1,length(bDataFullTrace{mouse}{1}));
        end 
        if VWQ == 1
            sVeta = cell(1,length(vDataFullTrace{mouse}{1}));
        end
        if velWheelQ == 1 
            sWeta = cell(1,numTtypes);
        end 
        for tType = 1:numTtypes
            if CAQ == 1
                for ccell = 1:length(terminals{mouse})
                    for cTrial = 1:size(Ceta{terminals{mouse}(ccell)}{tTypeInds(tType)},1)
                        [sC_Data] = MovMeanSmoothData(Ceta{terminals{mouse}(ccell)}{tTypeInds(tType)}(cTrial,:),filtTime,FPSstack{mouse});
                        sCeta{terminals{mouse}(ccell)}{tTypeInds(tType)}(cTrial,:) = sC_Data;
                    end 
                end 
            end        
            if BBBQ == 1 
                for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                    for bTrial = 1:size(Beta{BBBroi}{tTypeInds(tType)},1)
                        [sB_Data] = MovMeanSmoothData(Beta{BBBroi}{tTypeInds(tType)}(bTrial,:),filtTime,FPSstack{mouse});
                        sBeta{BBBroi}{tTypeInds(tType)}(bTrial,:) = sB_Data;
                    end 
                end 
            end 
            if VWQ == 1
                for VWroi = 1:length(vDataFullTrace{mouse}{1})
                    for vTrial = 1:size(Veta{VWroi}{tTypeInds(tType)},1)
                        [sV_Data] = MovMeanSmoothData(Veta{VWroi}{tTypeInds(tType)}(vTrial,:),filtTime,FPSstack{mouse});
                        sVeta{VWroi}{tTypeInds(tType)}(vTrial,:) = sV_Data;   
                    end 
                end 
            end 
            if velWheelQ == 1 
                for wTrial = 1:size(Weta{tTypeInds(tType)},1)
                    [sW_Data] = MovMeanSmoothData(Weta{tTypeInds(tType)}(wTrial,:),filtTime,FPSstack{mouse});
                    sWeta{tTypeInds(tType)}(wTrial,:) = sW_Data;   
                end 
            end 
        end 
    elseif smoothQ == 0
        if CAQ == 1
            sCeta = cell(1,length(cDataFullTrace{mouse}{1}));
        end 
        if BBBQ == 1 
            sBeta = cell(1,length(bDataFullTrace{mouse}{1}));
        end 
        if VWQ == 1
            sVeta = cell(1,length(vDataFullTrace{mouse}{1}));
        end
        if velWheelQ == 1 
            sWeta = cell(1,numTtypes);
        end 
        for tType = 1:numTtypes
            if CAQ == 1
                for ccell = 1:length(terminals{mouse})
                    for cTrial = 1:size(Ceta{terminals{mouse}(ccell)}{tTypeInds(tType)},1)
                        sCeta{terminals{mouse}(ccell)}{tTypeInds(tType)}(cTrial,:) = Ceta{terminals{mouse}(ccell)}{tTypeInds(tType)}(cTrial,:)-100;
                    end 
                end 
            end        
            if BBBQ == 1 
                for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                    for bTrial = 1:size(Beta{BBBroi}{tTypeInds(tType)},1)
                        sBeta{BBBroi}{tTypeInds(tType)}(bTrial,:) = Beta{BBBroi}{tTypeInds(tType)}(bTrial,:)-100;
                    end 
                end 
            end 
            if VWQ == 1
                for VWroi = 1:length(vDataFullTrace{mouse}{1})
                    for vTrial = 1:size(Veta{VWroi}{tTypeInds(tType)},1)
                        sVeta{VWroi}{tTypeInds(tType)}(vTrial,:) = Veta{VWroi}{tTypeInds(tType)}(vTrial,:)-100;   
                    end 
                end 
            end 
            if velWheelQ == 1 
                for wTrial = 1:size(Weta{tTypeInds(tType)},1)
                    sWeta{tTypeInds(tType)}(wTrial,:) = Weta{tTypeInds(tType)}(wTrial,:)-100;   
                end 
            end 
        end 
    end 
    
    % baseline data to average value between 0 sec and -baselineInput sec (0 sec being stim
    %onset) 
    if mouse == 1 
        baselineInput = input('How many seconds before the light turns on do you want to baseline to? ');
    end 
    if CAQ == 1
        nsCeta = cell(1,length(cDataFullTrace{mouse}{1}));
    end 
    if BBBQ == 1 
        nsBeta = cell(1,length(bDataFullTrace{mouse}{1}));
    end 
    if VWQ == 1
        nsVeta = cell(1,length(vDataFullTrace{mouse}{1}));
    end 
    if velWheelQ == 1 
        nsWeta = cell(1,numTtypes);
    end 
    if dataParseType == 0 %peristimulus data to plot 
        %sec_before_stim_start
        for tType = 1:numTtypes
            if CAQ == 1
                if isempty(sCeta{terminals{mouse}(ccell)}{tTypeInds(tType)}) == 0 
                    for ccell = 1:length(terminals{mouse})
                        nsCeta{terminals{mouse}(ccell)}{tTypeInds(tType)} = (sCeta{terminals{mouse}(ccell)}{tTypeInds(tType)} ./ nanmean(sCeta{terminals{mouse}(ccell)}{tTypeInds(tType)}(:,floor((sec_before_stim_start-baselineInput)*FPSstack{mouse}):floor(sec_before_stim_start*FPSstack{mouse})),2))*100; 
                    end 
                end 
            end 
            if BBBQ == 1 
                if isempty(sBeta{BBBroi}{tTypeInds(tType)}) == 0 
                    for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                        nsBeta{BBBroi}{tTypeInds(tType)} = (sBeta{BBBroi}{tTypeInds(tType)} ./ nanmean(sBeta{BBBroi}{tTypeInds(tType)}(:,floor((sec_before_stim_start-baselineInput)*FPSstack{mouse}):floor(sec_before_stim_start*FPSstack{mouse})),2))*100; 
                    end 
                end 
            end 
            if VWQ == 1
                if isempty(sVeta{VWroi}{tTypeInds(tType)}) == 0 
                    for VWroi = 1:length(vDataFullTrace{mouse}{1})
                        nsVeta{VWroi}{tTypeInds(tType)} = (sVeta{VWroi}{tTypeInds(tType)} ./ nanmean(sVeta{VWroi}{tTypeInds(tType)}(:,floor((sec_before_stim_start-baselineInput)*FPSstack{mouse}):floor(sec_before_stim_start*FPSstack{mouse})),2))*100;        
                    end 
                end 
            end 
            if velWheelQ == 1 
                if isempty(sWeta{tTypeInds(tType)}) == 0 
                    nsWeta{tTypeInds(tType)} = (sWeta{tTypeInds(tType)} ./ nanmean(sWeta{tTypeInds(tType)}(:,floor((sec_before_stim_start-baselineInput)*FPSstack{mouse}):floor(sec_before_stim_start*FPSstack{mouse})),2))*100; 
            
                end 
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
    if mouse == 1 
        AVQ = input('Input 1 to average all ROIs. Input 0 otherwise. ');
        if optoQ == 1 
            RedAVQ = input('Input 1 to average across all red trials. Input 0 otherwise. ');
        elseif optoQ == 0 
            RedAVQ = 0; 
        end 
    end 
    if AVQ == 1 
        if CAQ == 1 
            termList = 1:length(terminals{mouse});
        end 
    end 
    if RedAVQ == 1
        tTypeList = 3;
    elseif RedAVQ == 0
        tTypeList = 1:numTtypes;
    end 
    if mouse == 1 
        if BBBQ == 1 
            BBBpQ = input('Input 1 if you want to plot BBB data. Input 0 otherwise.');
        end 
        if CAQ == 1 
            CApQ = input('Input 1 if you want to plot calcium data. Input 0 otherwise.');
        end 
        if VWQ == 1 
            VWpQ = input('Input 1 if you want to plot vessel width data. Input 0 otherwise.');
        end 
        saveQ = input('Input 1 to save the figures. Input 0 otherwise. ');
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
                for ccell = 1:length(terminals{mouse})
                    for trial = 1:size(nsCeta{terminals{mouse}(ccell)}{tTypeInds(tType)},1)
                        allNScETA{1}{tTypeInds(tType)}(count,:) = nsCeta{terminals{mouse}(ccell)}{tTypeInds(tType)}(trial,:);
                        count = count + 1;
                    end        
                end 
            end 
            if BBBQ == 1
                for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                    for trial = 1:size(nsBeta{BBBroi}{tTypeInds(tType)},1)
                        allNSbETA{1}{tTypeInds(tType)}(countB,:) = nsBeta{BBBroi}{tTypeInds(tType)}(trial,:);
                        countB = countB + 1;
                    end 
                end 
            end 
            if VWQ == 1 
                for VWroi = 1:length(vDataFullTrace{mouse}{1})
                    for trial = 1:size(nsBeta{BBBroi}{tTypeInds(tType)},1)
                        allNSvETA{1}{tTypeInds(tType)}(countV,:) = nsVeta{VWroi}{tTypeInds(tType)}(trial,:);
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
                    for ccell = 1:length(terminals{mouse})
                        for trial = 1:size(nsCeta{terminals{mouse}(ccell)}{redTrialTtypeInds(tType)},1)
                            allRedNScETA{terminals{mouse}(ccell)}{3}(count,:) = nsCeta{terminals{mouse}(ccell)}{redTrialTtypeInds(tType)}(trial,1:size(nsCeta{terminals{mouse}(ccell)}{redTrialTtypeInds(1)},2)); 
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

    if AVQ == 0 
        % THE BELOW CODE (RELATED TO REDAVQ) MAY NEED TO BE UPDATED 
        if RedAVQ == 0 && CAQ == 0 
            termList = 1; 
        end 
        if RedAVQ == 1 && CAQ == 0 
            termList = 1; 
        end 
 
        baselineEndFrame = sec_before_stim_start*FPSstack{mouse};
        % plot calcium data ETAs 
        if CApQ == 1 
            for ccell = 1:length(terminals{mouse})
                % initialize arrays 
                AVcData = cell(1,length(terminals{mouse}));
                SEMc = cell(1,numTtypes);
                STDc = cell(1,numTtypes);
                CI_cLow = cell(1,numTtypes);
                CI_cHigh = cell(1,numTtypes);
                for tType = tTypeList    
                    % calculate the 95% confidence interval 
                    SEMc{terminals{mouse}(ccell)}{tTypeInds(tType)} = (nanstd(nsCeta{terminals{mouse}(ccell)}{tTypeInds(tType)}))/(sqrt(size(nsCeta{terminals{mouse}(ccell)}{tTypeInds(tType)},1))); % Standard Error            
                    STDc{terminals{mouse}(ccell)}{tTypeInds(tType)} = nanstd(nsCeta{terminals{mouse}(ccell)}{tTypeInds(tType)});
                    ts_cLow = tinv(0.025,size(nsCeta{terminals{mouse}(ccell)}{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                    ts_cHigh = tinv(0.975,size(nsCeta{terminals{mouse}(ccell)}{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                    CI_cLow{terminals{mouse}(ccell)}{tTypeInds(tType)} = (nanmean(nsCeta{terminals{mouse}(ccell)}{tTypeInds(tType)},1)) + (ts_cLow*SEMc{terminals{mouse}(ccell)}{tTypeInds(tType)});  % Confidence Intervals
                    CI_cHigh{terminals{mouse}(ccell)}{tTypeInds(tType)} = (nanmean(nsCeta{terminals{mouse}(ccell)}{tTypeInds(tType)},1)) + (ts_cHigh*SEMc{terminals{mouse}(ccell)}{tTypeInds(tType)});  % Confidence Intervals
                    x = 1:length(CI_cLow{terminals{mouse}(ccell)}{tTypeInds(tType)});
                    AVcData{terminals{mouse}(ccell)}{tTypeInds(tType)} = nanmean(nsCeta{terminals{mouse}(ccell)}{tTypeInds(tType)},1);

                    fig = figure;             
                    hold all;
                    if tTypeInds(tType) == 1 || tTypeInds(tType) == 3 
                        Frames = size(nsCeta{terminals{mouse}(ccell)}{tTypeInds(tType)},2);        
                        Frames_pre_stim_start = -((Frames-1)/2); 
                        Frames_post_stim_start = (Frames-1)/2; 
                        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}*2:Frames_post_stim_start)/FPSstack{mouse})+1);
                        FrameVals = floor((1:FPSstack{mouse}*2:Frames)-1); 
                    elseif tTypeInds(tType) == 2 || tTypeInds(tType) == 4 
                        Frames = size(nsCeta{terminals{mouse}(ccell)}{tTypeInds(tType)},2);
                        Frames_pre_stim_start = -((Frames-1)/2); 
                        Frames_post_stim_start = (Frames-1)/2; 
                        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}*2:Frames_post_stim_start)/FPSstack{mouse})+10);
                        FrameVals = floor((1:FPSstack{mouse}*2:Frames)-1); 
                    end 

                    CaPlot = plot(AVcData{terminals{mouse}(ccell)}{tTypeInds(tType)}-100,'b','LineWidth',3);
                    patch([x fliplr(x)],[CI_cLow{terminals{mouse}(ccell)}{tTypeInds(tType)}-100 fliplr(CI_cHigh{terminals{mouse}(ccell)}{tTypeInds(tType)}-100)],[0 0 0.5],'EdgeColor','none');
                    if optoQ == 1 
                        if tTypeInds(tType) == 1 
                            plot([round(baselineEndFrame+((FPSstack{mouse})*2)) round(baselineEndFrame+((FPSstack{mouse})*2))], [-5000000 5000000], 'b','LineWidth',2)
                            plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'b','LineWidth',2) 
                        elseif tTypeInds(tType) == 3 
            %                 plot(AVbData{tType},'k','LineWidth',3)
                            plot([round(baselineEndFrame+((FPSstack{mouse})*2)) round(baselineEndFrame+((FPSstack{mouse})*2))], [-5000000 5000000], 'r','LineWidth',2)
            %                 plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'k','LineWidth',2)
                            plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'r','LineWidth',2)                      
                        elseif tTypeInds(tType) == 2 
                            plot([round(baselineEndFrame+((FPSstack{mouse})*20)) round(baselineEndFrame+((FPSstack{mouse})*20))], [-5000000 5000000], 'b','LineWidth',2)
                            plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'b','LineWidth',2)   
                        elseif tTypeInds(tType) == 4 
            %                 plot(AVbData{tType},'r','LineWidth',3)
                            plot([round(baselineEndFrame+((FPSstack{mouse})*20)) round(baselineEndFrame+((FPSstack{mouse})*20))], [-5000000 5000000], 'r','LineWidth',2)
                            plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'r','LineWidth',2) 
                        end
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
                    xlim([1 length(AVcData{terminals{mouse}(ccell)}{tTypeInds(tType)})]) 
        %             xlim([1 length(AVbData{BBBroi}{tType})])
        %                 xlim([xLimStart xLimEnd])
                    ylim([min(AVcData{terminals{mouse}(ccell)}{tTypeInds(tType)}-400) max(AVcData{terminals{mouse}(ccell)}{tTypeInds(tType)})+300])
                    xlabel('time (s)')
                    ylabel('percent change')
                    if optoQ == 0 % behavior data 
                        label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
                        label1.FontSize = 30;
                        label1.FontName = 'Arial';
                        label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack{mouse}))*2),'-k',{'water reward'},'LineWidth',2);
                        label2.FontSize = 30;
                        label2.FontName = 'Arial';
                    end 
                    % initialize empty string array 
                    label = strings;
                    label = append(label,sprintf('  Mouse #%d Ca ROI #%d',mouse,terminals{mouse}(ccell)));
                    if optoQ == 1 % opto data 
                        title({'Optogenetic Stimulation';'Event Triggered Averages';label},'FontName','Times');
                    end 
                    if optoQ == 0 % behavior data 
                        title({'Behavior Event Triggered Averages';label},'FontName','Arial');
                    end 
                    set(fig,'position', [100 100 900 900])
                    alpha(0.5) 
                   
                   % save the images
                    if saveQ == 1     
                        if optoQ == 1 % opto exp 
                            if tTypeInds(tType) == 1
                                label2 = (' 2 sec Blue Light');
                            elseif tTypeInds(tType) == 2
                                label2 = (' 20 sec Blue Light');
                            elseif tTypeInds(tType) == 3
                                label2 = (' 2 sec Red Light');
                            elseif tTypeInds(tType) == 4
                                label2 = (' 20 sec Red Light');
                            end   
                        elseif optoQ == 0 % behavior exp
                            label2 = ('Behavior Data'); 
                        end 
                        dir2 = strrep(dir1,'\','/');
                        dir3 = sprintf('%s/%s%s.tif',dir2,label,label2);
                        export_fig(dir3)
                    end                      
                end 
            end 
        end 
        
        % plot BBB data ETAs 
        if BBBpQ == 1 
            for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                % initialize arrays 
                AVbData = cell(1,length(Beta));
                SEMb = cell(1,numTtypes);
                STDb = cell(1,numTtypes);
                CI_bLow = cell(1,numTtypes);
                CI_bHigh = cell(1,numTtypes);
                for tType = tTypeList                          
                    % calculate the 95% confidence interval 
                    SEMb{BBBroi}{tTypeInds(tType)} = (nanstd(nsBeta{BBBroi}{tTypeInds(tType)}))/(sqrt(size(nsBeta{BBBroi}{tTypeInds(tType)},1))); % Standard Error            
                    STDb{BBBroi}{tTypeInds(tType)} = nanstd(nsBeta{BBBroi}{tTypeInds(tType)});
                    ts_bLow = tinv(0.025,size(nsBeta{BBBroi}{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                    ts_bHigh = tinv(0.975,size(nsBeta{BBBroi}{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                    CI_bLow{BBBroi}{tTypeInds(tType)} = (nanmean(nsBeta{BBBroi}{tTypeInds(tType)},1)) + (ts_bLow*SEMb{BBBroi}{tTypeInds(tType)});  % Confidence Intervals
                    CI_bHigh{BBBroi}{tTypeInds(tType)} = (nanmean(nsBeta{BBBroi}{tTypeInds(tType)},1)) + (ts_bHigh*SEMb{BBBroi}{tTypeInds(tType)});  % Confidence Intervals
                    x = 1:length(CI_bLow{BBBroi}{tTypeInds(tType)});
                    AVbData{BBBroi}{tTypeInds(tType)} = nanmean(nsBeta{BBBroi}{tTypeInds(tType)},1);
                    
                    fig = figure;             
                    hold all;
                    if tTypeInds(tType) == 1 || tTypeInds(tType) == 3 
                        Frames = size(nsBeta{BBBroi}{tTypeInds(tType)},2);        
                        Frames_pre_stim_start = -((Frames-1)/2); 
                        Frames_post_stim_start = (Frames-1)/2; 
                        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}*2:Frames_post_stim_start)/FPSstack{mouse})+1);
                        FrameVals = floor((1:FPSstack{mouse}*2:Frames)-1); 
                    elseif tTypeInds(tType) == 2 || tTypeInds(tType) == 4 
                        Frames = size(nsBeta{BBBroi}{tTypeInds(tType)},2);
                        Frames_pre_stim_start = -((Frames-1)/2); 
                        Frames_post_stim_start = (Frames-1)/2; 
                        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}*2:Frames_post_stim_start)/FPSstack{mouse})+10);
                        FrameVals = floor((1:FPSstack{mouse}*2:Frames)-1); 
                    end 

                    BBBplot = plot(AVbData{BBBroi}{tTypeInds(tType)}-100,'r','LineWidth',3);
                    patch([x fliplr(x)],[CI_bLow{BBBroi}{tTypeInds(tType)}-100 fliplr(CI_bHigh{BBBroi}{tTypeInds(tType)}-100)],[0.5 0 0],'EdgeColor','none')
                    if optoQ == 1 
                        if tTypeInds(tType) == 1 
                            plot([round(baselineEndFrame+((FPSstack{mouse})*2)) round(baselineEndFrame+((FPSstack{mouse})*2))], [-5000000 5000000], 'b','LineWidth',2)
                            plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'b','LineWidth',2) 
                        elseif tTypeInds(tType) == 3 
                            plot([round(baselineEndFrame+((FPSstack{mouse})*2)) round(baselineEndFrame+((FPSstack{mouse})*2))], [-5000000 5000000], 'r','LineWidth',2)
                            plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'r','LineWidth',2)                      
                        elseif tTypeInds(tType) == 2 
                            plot([round(baselineEndFrame+((FPSstack{mouse})*20)) round(baselineEndFrame+((FPSstack{mouse})*20))], [-5000000 5000000], 'b','LineWidth',2)
                            plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'b','LineWidth',2)   
                        elseif tTypeInds(tType) == 4 
                            plot([round(baselineEndFrame+((FPSstack{mouse})*20)) round(baselineEndFrame+((FPSstack{mouse})*20))], [-5000000 5000000], 'r','LineWidth',2)
                            plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'r','LineWidth',2) 
                        end
                    end 
                    ax=gca;
                    ax.XTick = FrameVals;
                    ax.XTickLabel = sec_TimeVals;
                    ax.FontSize = 30;
                    ax.FontName = 'Arial';
                    xlim([1 length(AVbData{BBBroi}{tTypeInds(tType)})]) 
                    ylim([min(AVbData{BBBroi}{tTypeInds(tType)}-400) max(AVbData{BBBroi}{tTypeInds(tType)})+300])
                    xlabel('time (s)')
                    ylabel('percent change')
                    if optoQ == 0 % behavior data 
                        label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
                        label1.FontSize = 30;
                        label1.FontName = 'Arial';
                        label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack{mouse}))*2),'-k',{'water reward'},'LineWidth',2);
                        label2.FontSize = 30;
                        label2.FontName = 'Arial';
                    end 
                    % initialize empty string array 
                    label = strings;
                    label = append(label,sprintf('  Mouse #%d BBB ROI #%d',mouse,BBBroi));
                    if optoQ == 1 % opto data 
                        title({'Optogenetic Stimulation';'Event Triggered Averages';label},'FontName','Times');
                    end 
                    if optoQ == 0 % behavior data 
                        title({'Behavior Event Triggered Averages';label},'FontName','Arial');
                    end 
                    set(fig,'position', [100 100 900 900])
                    alpha(0.5) 
                   % save the images
                    if saveQ == 1     
                        if optoQ == 1 % opto exp 
                            if tTypeInds(tType) == 1
                                label2 = (' 2 sec Blue Light');
                            elseif tTypeInds(tType) == 2
                                label2 = (' 20 sec Blue Light');
                            elseif tTypeInds(tType) == 3
                                label2 = (' 2 sec Red Light');
                            elseif tTypeInds(tType) == 4
                                label2 = (' 20 sec Red Light');
                            end   
                        elseif optoQ == 0 % behavior exp
                            label2 = ('Behavior Data'); 
                        end 
                        dir2 = strrep(dir1,'\','/');
                        dir3 = sprintf('%s/%s%s.tif',dir2,label,label2);
                        export_fig(dir3)
                    end                        
                end 
            end 
        end 
        
        % plot VW data ETAs 
        if VWpQ == 1 
            for VWroi = 1:length(vDataFullTrace{mouse}{1})
                % initialize arrays 
                AVvData = cell(1,length(Beta));
                SEMv = cell(1,numTtypes);
                STDv = cell(1,numTtypes);
                CI_vLow = cell(1,numTtypes);
                CI_vHigh = cell(1,numTtypes);
                for tType = tTypeList                          
                    % calculate the 95% confidence interval 
                    SEMv{VWroi}{tTypeInds(tType)} = (nanstd(nsVeta{VWroi}{tTypeInds(tType)}))/(sqrt(size(nsVeta{VWroi}{tTypeInds(tType)},1))); % Standard Error            
                    STDv{VWroi}{tTypeInds(tType)} = nanstd(nsVeta{VWroi}{tTypeInds(tType)});
                    ts_vLow = tinv(0.025,size(nsVeta{VWroi}{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                    ts_vHigh = tinv(0.975,size(nsVeta{VWroi}{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                    CI_vLow{VWroi}{tTypeInds(tType)} = (nanmean(nsVeta{VWroi}{tTypeInds(tType)},1)) + (ts_vLow*SEMv{VWroi}{tTypeInds(tType)});  % Confidence Intervals
                    CI_vHigh{VWroi}{tTypeInds(tType)} = (nanmean(nsVeta{VWroi}{tTypeInds(tType)},1)) + (ts_vHigh*SEMv{VWroi}{tTypeInds(tType)});  % Confidence Intervals
                    x = 1:length(CI_vLow{VWroi}{tTypeInds(tType)});
                    AVvData{VWroi}{tTypeInds(tType)} = nanmean(nsVeta{VWroi}{tTypeInds(tType)},1);
                    
                    fig = figure;             
                    hold all;
                    if tTypeInds(tType) == 1 || tTypeInds(tType) == 3 
                        Frames = size(nsVeta{VWroi}{tTypeInds(tType)},2);        
                        Frames_pre_stim_start = -((Frames-1)/2); 
                        Frames_post_stim_start = (Frames-1)/2; 
                        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}*2:Frames_post_stim_start)/FPSstack{mouse})+1);
                        FrameVals = floor((1:FPSstack{mouse}*2:Frames)-1); 
                    elseif tTypeInds(tType) == 2 || tTypeInds(tType) == 4 
                        Frames = size(nsVeta{VWroi}{tTypeInds(tType)},2);
                        Frames_pre_stim_start = -((Frames-1)/2); 
                        Frames_post_stim_start = (Frames-1)/2; 
                        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}*2:Frames_post_stim_start)/FPSstack{mouse})+10);
                        FrameVals = floor((1:FPSstack{mouse}*2:Frames)-1); 
                    end 

                    VWplot = plot(AVvData{VWroi}{tTypeInds(tType)}-100,'k','LineWidth',3);
                    patch([x fliplr(x)],[CI_vLow{VWroi}{tTypeInds(tType)}-100 fliplr(CI_vHigh{VWroi}{tTypeInds(tType)}-100)],'k','EdgeColor','none')   
                    if optoQ == 1 
                        if tTypeInds(tType) == 1 
                            plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000000 5000000], 'b','LineWidth',2)
                            plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'b','LineWidth',2) 
                        elseif tTypeInds(tType) == 3 
                            plot([round(baselineEndFrame+((FPSstack{mouse})*2)) round(baselineEndFrame+((FPSstack{mouse})*2))], [-5000000 5000000], 'r','LineWidth',2)
                            plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'r','LineWidth',2)                      
                        elseif tTypeInds(tType) == 2 
                            plot([round(baselineEndFrame+((FPSstack{mouse})*20)) round(baselineEndFrame+((FPSstack{mouse})*20))], [-5000000 5000000], 'b','LineWidth',2)
                            plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'b','LineWidth',2)   
                        elseif tTypeInds(tType) == 4 
                            plot([round(baselineEndFrame+((FPSstack{mouse})*20)) round(baselineEndFrame+((FPSstack{mouse})*20))], [-5000000 5000000], 'r','LineWidth',2)
                            plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'r','LineWidth',2) 
                        end
                    end 
                    ax=gca;
                    ax.XTick = FrameVals;
                    ax.XTickLabel = sec_TimeVals;
                    ax.FontSize = 30;
                    ax.FontName = 'Arial';
                    xlim([1 length(AVvData{VWroi}{tTypeInds(tType)})]) 
                    ylim([min(AVvData{VWroi}{tTypeInds(tType)}-400) max(AVvData{VWroi}{tTypeInds(tType)})+300])
                    xlabel('time (s)')
                    ylabel('percent change')
                    if optoQ == 0 % behavior data 
                        label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
                        label1.FontSize = 30;
                        label1.FontName = 'Arial';
                        label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack{mouse}))*2),'-k',{'water reward'},'LineWidth',2);
                        label2.FontSize = 30;
                        label2.FontName = 'Arial';
                    end 
                    % initialize empty string array 
                    label = strings;
                    label = append(label,sprintf('  Mouse #%d VW ROI #%d',mouse,VWroi));
                    if optoQ == 1 % opto data 
                        title({'Optogenetic Stimulation';'Event Triggered Averages';label},'FontName','Times');
                    end 
                    if optoQ == 0 % behavior data 
                        title({'Behavior Event Triggered Averages';label},'FontName','Arial');
                    end 
                    set(fig,'position', [100 100 900 900])
                    alpha(0.5) 
                   % save the images
                    if saveQ == 1     
                        if optoQ == 1 % opto exp 
                            if tTypeInds(tType) == 1
                                label2 = (' 2 sec Blue Light');
                            elseif tTypeInds(tType) == 2
                                label2 = (' 20 sec Blue Light');
                            elseif tTypeInds(tType) == 3
                                label2 = (' 2 sec Red Light');
                            elseif tTypeInds(tType) == 4
                                label2 = (' 20 sec Red Light');
                            end   
                        elseif optoQ == 0 % behavior exp
                            label2 = ('Behavior Data'); 
                        end 
                        dir2 = strrep(dir1,'\','/');
                        dir3 = sprintf('%s/%s%s.tif',dir2,label,label2);
                        export_fig(dir3)
                    end                       
                end 
            end 
        end 
    elseif AVQ == 1
        if mouse == 1 
            overlayQ = input('Input 1 to overlay the averaged images. Input 0 otherwise. '); 
        end 
        baselineEndFrame = sec_before_stim_start*FPSstack{mouse};
        % plot CA data 
        if CApQ == 1
            % initialize arrays 
            AVcData = cell(1,length(nsCeta{1}{tTypeInds(tType)}));
            SEMc = cell(1,numTtypes);
            STDc = cell(1,numTtypes);
            CI_cLow = cell(1,numTtypes);
            CI_cHigh = cell(1,numTtypes);
            for tType = tTypeList  
                if isempty(nsCeta{1}{tTypeInds(tType)}) == 0 
                    % calculate the 95% confidence interval 
                    SEMc{1}{tTypeInds(tType)} = (nanstd(nsCeta{1}{tTypeInds(tType)}))/(sqrt(size(nsCeta{1}{tTypeInds(tType)},1))); % Standard Error            
                    STDc{1}{tTypeInds(tType)} = nanstd(nsCeta{1}{tTypeInds(tType)});
                    ts_cLow = tinv(0.025,size(nsCeta{1}{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                    ts_cHigh = tinv(0.975,size(nsCeta{1}{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                    CI_cLow{1}{tTypeInds(tType)} = (nanmean(nsCeta{1}{tTypeInds(tType)},1)) + (ts_cLow*SEMc{1}{tTypeInds(tType)});  % Confidence Intervals
                    CI_cHigh{1}{tTypeInds(tType)} = (nanmean(nsCeta{1}{tTypeInds(tType)},1)) + (ts_cHigh*SEMc{1}{tTypeInds(tType)});  % Confidence Intervals
                    x = 1:length(CI_cLow{1}{tTypeInds(tType)});
                    AVcData{1}{tTypeInds(tType)} = nanmean(nsCeta{1}{tTypeInds(tType)},1);
                    if overlayQ == 0 
                        fig = figure;             
                        hold all;
                        if tTypeInds(tType) == 1 || tTypeInds(tType) == 3 
                            Frames = size(nsCeta{1}{tTypeInds(tType)},2);        
                            Frames_pre_stim_start = -((Frames-1)/2); 
                            Frames_post_stim_start = (Frames-1)/2; 
                            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}*2:Frames_post_stim_start)/FPSstack{mouse})+1);
                            FrameVals = floor((1:FPSstack{mouse}*2:Frames)-1); 
                        elseif tTypeInds(tType) == 2 || tTypeInds(tType) == 4 
                            Frames = size(nsCeta{1}{tTypeInds(tType)},2);
                            Frames_pre_stim_start = -((Frames-1)/2); 
                            Frames_post_stim_start = (Frames-1)/2; 
                            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}*2:Frames_post_stim_start)/FPSstack{mouse})+10);
                            FrameVals = floor((1:FPSstack{mouse}*2:Frames)-1); 
                        end 

                        plot(AVcData{1}{tTypeInds(tType)}-100,'b','LineWidth',3)
                        patch([x fliplr(x)],[CI_cLow{1}{tTypeInds(tType)}-100 fliplr(CI_cHigh{1}{tTypeInds(tType)}-100)],[0 0 0.5],'EdgeColor','none')
                        if optoQ == 1 
                            if tTypeInds(tType) == 1 
                                plot([round(baselineEndFrame+((FPSstack{mouse})*2)) round(baselineEndFrame+((FPSstack{mouse})*2))], [-5000 5000], 'b','LineWidth',2)
                                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
                            elseif tTypeInds(tType) == 3 
                                plot([round(baselineEndFrame+((FPSstack{mouse})*2)) round(baselineEndFrame+((FPSstack{mouse})*2))], [-5000 5000], 'r','LineWidth',2)
                                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2)                      
                            elseif tTypeInds(tType) == 2 
                                plot([round(baselineEndFrame+((FPSstack{mouse})*20)) round(baselineEndFrame+((FPSstack{mouse})*20))], [-5000 5000], 'b','LineWidth',2)
                                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2)   
                            elseif tTypeInds(tType) == 4 
                                plot([round(baselineEndFrame+((FPSstack{mouse})*20)) round(baselineEndFrame+((FPSstack{mouse})*20))], [-5000 5000], 'r','LineWidth',2)
                                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
                            end
                        end 
                        ax=gca;
                        ax.XTick = FrameVals;
                        ax.XTickLabel = sec_TimeVals;
                        ax.FontSize = 30;
                        ax.FontName = 'Arial';
                        xlim([1 length(AVcData{1}{tTypeInds(tType)})])
                        ylim([min(AVcData{1}{tTypeInds(tType)}-400) max(AVcData{1}{tTypeInds(tType)})+300])
                        xlabel('time (s)')
                        ylabel('percent change')
                        % initialize empty string array 
                        if optoQ == 0 % behavior data 
                            label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
                            label1.FontSize = 30;
                            label1.FontName = 'Arial';
                            label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack{mouse}))*2),'-k',{'water reward'},'LineWidth',2);
                            label2.FontSize = 30;
                            label2.FontName = 'Arial';
                        end 
                        label = strings;
                        label = append(label,sprintf('  Ca ROIs averaged. Mouse #%d.',mouse));
                        if optoQ == 1 % opto data 
                            title({'Optogenetic Stimulation';'Event Triggered Averages';label},'FontName','Times');
                        end 
                        if optoQ == 0 % behavior data 
                            title({'Event Triggered Averages';label},'FontName','Arial');
                        end 
                        set(fig,'position', [100 100 900 900])
                        alpha(0.5) 
                    end 

                   % save the images
                    if saveQ == 1     
                        if optoQ == 1 % opto exp 
                            if tTypeInds(tType) == 1
                                label2 = (' 2 sec Blue Light');
                            elseif tTypeInds(tType) == 2
                                label2 = (' 20 sec Blue Light');
                            elseif tTypeInds(tType) == 3
                                label2 = (' 2 sec Red Light');
                            elseif tTypeInds(tType) == 4
                                label2 = (' 20 sec Red Light');
                            end   
                        elseif optoQ == 0 % behavior exp
                            label2 = ('Behavior Data'); 
                        end 
                        dir2 = strrep(dir1,'\','/');
                        dir3 = sprintf('%s/%s%s.tif',dir2,label,label2);
                        export_fig(dir3)
                    end 
                end                
            end 
        end 
        
        % plot BBB data 
        if BBBpQ == 1
            % initialize arrays 
            AVbData = cell(1,length(nsBeta{1}{tTypeInds(tType)}));
            SEMb = cell(1,numTtypes);
            STDb = cell(1,numTtypes);
            CI_bLow = cell(1,numTtypes);
            CI_bHigh = cell(1,numTtypes);
            for tType = tTypeList  
                if isempty(nsBeta{1}{tTypeInds(tType)}) == 0 
                    % calculate the 95% confidence interval 
                    SEMb{1}{tTypeInds(tType)} = (nanstd(nsBeta{1}{tTypeInds(tType)}))/(sqrt(size(nsBeta{1}{tTypeInds(tType)},1))); % Standard Error            
                    STDb{1}{tTypeInds(tType)} = nanstd(nsBeta{1}{tTypeInds(tType)});
                    ts_bLow = tinv(0.025,size(nsBeta{1}{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                    ts_bHigh = tinv(0.975,size(nsBeta{1}{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                    CI_bLow{1}{tTypeInds(tType)} = (nanmean(nsBeta{1}{tTypeInds(tType)},1)) + (ts_bLow*SEMb{1}{tTypeInds(tType)});  % Confidence Intervals
                    CI_bHigh{1}{tTypeInds(tType)} = (nanmean(nsBeta{1}{tTypeInds(tType)},1)) + (ts_bHigh*SEMb{1}{tTypeInds(tType)});  % Confidence Intervals
                    x = 1:length(CI_bLow{1}{tTypeInds(tType)});
                    AVbData{1}{tTypeInds(tType)} = nanmean(nsBeta{1}{tTypeInds(tType)},1);
                    if overlayQ == 0 
                        fig = figure;             
                        hold all;
                        if tTypeInds(tType) == 1 || tTypeInds(tType) == 3 
                            Frames = size(nsBeta{1}{tTypeInds(tType)},2);        
                            Frames_pre_stim_start = -((Frames-1)/2); 
                            Frames_post_stim_start = (Frames-1)/2; 
                            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}*2:Frames_post_stim_start)/FPSstack{mouse})+1);
                            FrameVals = floor((1:FPSstack{mouse}*2:Frames)-1); 
                        elseif tTypeInds(tType) == 2 || tTypeInds(tType) == 4 
                            Frames = size(nsBeta{1}{tTypeInds(tType)},2);
                            Frames_pre_stim_start = -((Frames-1)/2); 
                            Frames_post_stim_start = (Frames-1)/2; 
                            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}*2:Frames_post_stim_start)/FPSstack{mouse})+10);
                            FrameVals = floor((1:FPSstack{mouse}*2:Frames)-1); 
                        end 

                        plot(AVbData{1}{tTypeInds(tType)}-100,'r','LineWidth',3)
                        patch([x fliplr(x)],[CI_bLow{1}{tTypeInds(tType)}-100 fliplr(CI_bHigh{1}{tTypeInds(tType)}-100)],[0.5 0 0],'EdgeColor','none')
                        if optoQ == 1 
                            if tTypeInds(tType) == 1 
                                plot([round(baselineEndFrame+((FPSstack{mouse})*2)) round(baselineEndFrame+((FPSstack{mouse})*2))], [-5000 5000], 'b','LineWidth',2)
                                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
                            elseif tTypeInds(tType) == 3 
                                plot([round(baselineEndFrame+((FPSstack{mouse})*2)) round(baselineEndFrame+((FPSstack{mouse})*2))], [-5000 5000], 'r','LineWidth',2)
                                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2)                      
                            elseif tTypeInds(tType) == 2 
                                plot([round(baselineEndFrame+((FPSstack{mouse})*20)) round(baselineEndFrame+((FPSstack{mouse})*20))], [-5000 5000], 'b','LineWidth',2)
                                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2)   
                            elseif tTypeInds(tType) == 4 
                                plot([round(baselineEndFrame+((FPSstack{mouse})*20)) round(baselineEndFrame+((FPSstack{mouse})*20))], [-5000 5000], 'r','LineWidth',2)
                                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
                            end
                        end 
                        ax=gca;
                        ax.XTick = FrameVals;
                        ax.XTickLabel = sec_TimeVals;
                        ax.FontSize = 30;
                        ax.FontName = 'Arial';
                        xlim([1 length(AVbData{1}{tTypeInds(tType)})])
                        ylim([min(AVbData{1}{tTypeInds(tType)}-400) max(AVbData{1}{tTypeInds(tType)})+300])
                        xlabel('time (s)')
                        ylabel('percent change')
                        % initialize empty string array 
                        if optoQ == 0 % behavior data 
                            label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
                            label1.FontSize = 30;
                            label1.FontName = 'Arial';
                            label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack{mouse}))*2),'-k',{'water reward'},'LineWidth',2);
                            label2.FontSize = 30;
                            label2.FontName = 'Arial';
                        end 
                        label = strings;
                        label = append(label,sprintf('  BBB ROIs averaged. Mouse #%d.',mouse));
                        if optoQ == 1 % opto data 
                            title({'Optogenetic Stimulation';'Event Triggered Averages';label},'FontName','Times');
                        end 
                        if optoQ == 0 % behavior data 
                            title({'Event Triggered Averages';label},'FontName','Arial');
                        end 
                        set(fig,'position', [100 100 900 900])
                        alpha(0.5) 
                    end 

                    % save the images
                    if saveQ == 1     
                        if optoQ == 1 % opto exp 
                            if tTypeInds(tType) == 1
                                label2 = (' 2 sec Blue Light');
                            elseif tTypeInds(tType) == 2
                                label2 = (' 20 sec Blue Light');
                            elseif tTypeInds(tType) == 3
                                label2 = (' 2 sec Red Light');
                            elseif tTypeInds(tType) == 4
                                label2 = (' 20 sec Red Light');
                            end   
                        elseif optoQ == 0 % behavior exp
                            label2 = ('Behavior Data'); 
                        end 
                        dir2 = strrep(dir1,'\','/');
                        dir3 = sprintf('%s/%s%s.tif',dir2,label,label2);
                        export_fig(dir3)
                    end                  
                end 
            end 
        end  
        
        % plot VW data 
        if VWpQ == 1
            % initialize arrays 
            AVvData = cell(1,length(nsVeta{1}{tTypeInds(tType)}));
            SEMv = cell(1,numTtypes);
            STDv = cell(1,numTtypes);
            CI_vLow = cell(1,numTtypes);
            CI_vHigh = cell(1,numTtypes);
            for tType = tTypeList 
                if isempty(nsVeta{1}{tTypeInds(tType)}) == 0 
                    % calculate the 95% confidence interval 
                    SEMv{1}{tTypeInds(tType)} = (nanstd(nsVeta{1}{tTypeInds(tType)}))/(sqrt(size(nsVeta{1}{tTypeInds(tType)},1))); % Standard Error            
                    STDv{1}{tTypeInds(tType)} = nanstd(nsVeta{1}{tTypeInds(tType)});
                    ts_vLow = tinv(0.025,size(nsVeta{1}{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                    ts_vHigh = tinv(0.975,size(nsVeta{1}{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                    CI_vLow{1}{tTypeInds(tType)} = (nanmean(nsVeta{1}{tTypeInds(tType)},1)) + (ts_vLow*SEMv{1}{tTypeInds(tType)});  % Confidence Intervals
                    CI_vHigh{1}{tTypeInds(tType)} = (nanmean(nsVeta{1}{tTypeInds(tType)},1)) + (ts_vHigh*SEMv{1}{tTypeInds(tType)});  % Confidence Intervals
                    x = 1:length(CI_vLow{1}{tTypeInds(tType)});
                    AVvData{1}{tTypeInds(tType)} = nanmean(nsVeta{1}{tTypeInds(tType)},1);
                    if overlayQ == 0 
                        fig = figure;             
                        hold all;
                        if tTypeInds(tType) == 1 || tTypeInds(tType) == 3 
                            Frames = size(nsVeta{1}{tTypeInds(tType)},2);        
                            Frames_pre_stim_start = -((Frames-1)/2); 
                            Frames_post_stim_start = (Frames-1)/2; 
                            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}*2:Frames_post_stim_start)/FPSstack{mouse})+1);
                            FrameVals = floor((1:FPSstack{mouse}*2:Frames)-1); 
                        elseif tTypeInds(tType) == 2 || tTypeInds(tType) == 4 
                            Frames = size(nsVeta{1}{tTypeInds(tType)},2);
                            Frames_pre_stim_start = -((Frames-1)/2); 
                            Frames_post_stim_start = (Frames-1)/2; 
                            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}*2:Frames_post_stim_start)/FPSstack{mouse})+10);
                            FrameVals = floor((1:FPSstack{mouse}*2:Frames)-1); 
                        end 

                        plot(AVvData{1}{tTypeInds(tType)}-100,'k','LineWidth',3)
                        patch([x fliplr(x)],[CI_vLow{1}{tTypeInds(tType)}-100 fliplr(CI_vHigh{1}{tTypeInds(tType)}-100)],'k','EdgeColor','none')  
                        if optoQ == 1 
                            if tTypeInds(tType) == 1 
                                plot([round(baselineEndFrame+((FPSstack{mouse})*2)) round(baselineEndFrame+((FPSstack{mouse})*2))], [-5000 5000], 'b','LineWidth',2)
                                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
                            elseif tTypeInds(tType) == 3 
                                plot([round(baselineEndFrame+((FPSstack{mouse})*2)) round(baselineEndFrame+((FPSstack{mouse})*2))], [-5000 5000], 'r','LineWidth',2)
                                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2)                      
                            elseif tTypeInds(tType) == 2 
                                plot([round(baselineEndFrame+((FPSstack{mouse})*20)) round(baselineEndFrame+((FPSstack{mouse})*20))], [-5000 5000], 'b','LineWidth',2)
                                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2)   
                            elseif tTypeInds(tType) == 4 
                                plot([round(baselineEndFrame+((FPSstack{mouse})*20)) round(baselineEndFrame+((FPSstack{mouse})*20))], [-5000 5000], 'r','LineWidth',2)
                                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
                            end
                        end 
                        ax=gca;
                        ax.XTick = FrameVals;
                        ax.XTickLabel = sec_TimeVals;
                        ax.FontSize = 30;
                        ax.FontName = 'Arial';
                        xlim([1 length(AVvData{1}{tTypeInds(tType)})])
                        ylim([min(AVvData{1}{tTypeInds(tType)}-400) max(AVvData{1}{tTypeInds(tType)})+300])
                        xlabel('time (s)')
                        ylabel('percent change')
                        % initialize empty string array 
                        if optoQ == 0 % behavior data 
                            label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
                            label1.FontSize = 30;
                            label1.FontName = 'Arial';
                            label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack{mouse}))*2),'-k',{'water reward'},'LineWidth',2);
                            label2.FontSize = 30;
                            label2.FontName = 'Arial';
                        end 
                        label = strings;
                        label = append(label,sprintf('  VW ROIs averaged. Mouse #%d.',mouse));
                        if optoQ == 1 % opto data 
                            title({'Optogenetic Stimulation';'Event Triggered Averages';label},'FontName','Times');
                        end 
                        if optoQ == 0 % behavior data 
                            title({'Event Triggered Averages';label},'FontName','Arial');
                        end 
                        set(fig,'position', [100 100 900 900])
                        alpha(0.5) 
                    end 
                    % save the images
                    if saveQ == 1     
                        if optoQ == 1 % opto exp 
                            if tTypeInds(tType) == 1
                                label2 = (' 2 sec Blue Light');
                            elseif tTypeInds(tType) == 2
                                label2 = (' 20 sec Blue Light');
                            elseif tTypeInds(tType) == 3
                                label2 = (' 2 sec Red Light');
                            elseif tTypeInds(tType) == 4
                                label2 = (' 20 sec Red Light');
                            end   
                        elseif optoQ == 0 % behavior exp
                            label2 = ('Behavior Data'); 
                        end 
                        dir2 = strrep(dir1,'\','/');
                        dir3 = sprintf('%s/%s%s.tif',dir2,label,label2);
                        export_fig(dir3)
                    end   
                end 
            end 
        end    
        %%
        if overlayQ == 1
            baselineEndFrame = sec_before_stim_start*FPSstack{mouse};            
            for tType = tTypeList                        
                fig = figure;             
                hold all;
                if tTypeInds(tType) == 1 || tTypeInds(tType) == 3 
                    Frames = size(nsCeta{1}{tTypeInds(tType)},2);        
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}*1:Frames_post_stim_start)/FPSstack{mouse})+1);
                    FrameVals = floor((1:FPSstack{mouse}*1:Frames)-1); 
                elseif tTypeInds(tType) == 2 || tTypeInds(tType) == 4 
                    Frames = size(nsCeta{1}{tTypeInds(tType)},2);
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}*1:Frames_post_stim_start)/FPSstack{mouse})+10);
                    FrameVals = floor((1:FPSstack{mouse}*1:Frames)-1); 
                end 
                if CApQ == 1
                    plot(AVcData{1}{tTypeInds(tType)}-100,'b','LineWidth',3)                    
%                     patch([x fliplr(x)],[CI_cLow{1}{tTypeInds(tType)}-100 fliplr(CI_cHigh{1}{tTypeInds(tType)}-100)],[0 0 0.5],'EdgeColor','none')
                    alpha(0.5)
                    ylabel('calcium percent change')
                end 
                if optoQ == 1 
                    if tTypeInds(tType) == 1 
                        plot([round(baselineEndFrame+((FPSstack{mouse})*2)) round(baselineEndFrame+((FPSstack{mouse})*2))], [-5000 5000], 'b','LineWidth',2)
                        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
                    elseif tTypeInds(tType) == 3 
                        plot([round(baselineEndFrame+((FPSstack{mouse})*2)) round(baselineEndFrame+((FPSstack{mouse})*2))], [-5000 5000], 'r','LineWidth',2)
                        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2)                      
                    elseif tTypeInds(tType) == 2 
                        plot([round(baselineEndFrame+((FPSstack{mouse})*20)) round(baselineEndFrame+((FPSstack{mouse})*20))], [-5000 5000], 'b','LineWidth',2)
                        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2)   
                    elseif tTypeInds(tType) == 4 
                        plot([round(baselineEndFrame+((FPSstack{mouse})*20)) round(baselineEndFrame+((FPSstack{mouse})*20))], [-5000 5000], 'r','LineWidth',2)
                        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
                    end
                end 
                ax=gca;
                ax.XTick = FrameVals;
                ax.XTickLabel = sec_TimeVals;
                ax.FontSize = 30;
                ax.FontName = 'Arial';
                xlim([1 length(AVcData{1}{tTypeInds(tType)})])
%                 ylim([min(AVcData{1}{tTypeInds(tType)}-400) max(AVcData{1}{tTypeInds(tType)})+300])
                xlabel('time (s)')
                
                % initialize empty string array 
                if optoQ == 0 % behavior data 
%                     label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
%                     label1.FontSize = 30;
%                     label1.FontName = 'Arial';
% %                     label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack{mouse}))*2),'-k',{'water reward'},'LineWidth',2);
%                     label2.FontSize = 30;
%                     label2.FontName = 'Arial';
                    %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                    plot([round(baselineEndFrame+((FPSstack{mouse})*2))-1 round(baselineEndFrame+((FPSstack{mouse})*2))-1], [-5000 5000], 'k','LineWidth',2)
                    plot([baselineEndFrame-1 baselineEndFrame-1], [-5000 5000], 'k','LineWidth',2) 
                        %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                end 
                label = strings;
                label = append(label,sprintf('  Ca ROIs averaged. Mouse #%d.',mouse));
                if optoQ == 1 % opto data 
                    title({'Optogenetic Stimulation';'Event Triggered Averages';label},'FontName','Times');
                end 
                if optoQ == 0 % behavior data 
                    title({'Event Triggered Averages';label},'FontName','Arial');
                end 
                set(fig,'position', [100 100 900 900])
                alpha(0.5)
                if BBBpQ == 1
                    yyaxis right 
                    plot(AVbData{1}{tTypeInds(tType)}-100,'r','LineWidth',3)
                    patch([x fliplr(x)],[CI_bLow{1}{tTypeInds(tType)}-100 fliplr(CI_bHigh{1}{tTypeInds(tType)}-100)],[0.5 0 0],'EdgeColor','none')
                    ylabel('BBB percent change')
                    set(gca,'YColor',[0 0 0]);   
                    alpha(0.5)
                end 
                if VWpQ == 1
                    yyaxis left 
                    plot(AVvData{1}{tTypeInds(tType)}-100,'k','LineWidth',3)
%                     patch([x fliplr(x)],[CI_vLow{1}{tTypeInds(tType)}-100 fliplr(CI_vHigh{1}{tTypeInds(tType)}-100)],'k','EdgeColor','none')  
                    ylabel('VW percent change')
                    set(gca,'YColor',[0 0 0]);   
                    alpha(0.5)
                end 
                
            end 
        end 
    end 
    fileName = sprintf('ETAfigDataMouse%d.mat',mouse);
    if saveDataQ == 1 
        save(fullfile(dir1,fileName));
    end 
end 

%}
%}
%% ETA: average across mice 
% does not take already smooothed/normalized data. Will ask you about
% smoothing/normalizing below 
% will separate data based on trial number and ITI length (so give it all
% the trials per mouse
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
    if ~iscell(Mat.FPSstack)
        FPSstack{mouse} = Mat.FPSstack;
        state_start_f{mouse} = Mat.state_start_f;
        TrialTypes{mouse} = Mat.TrialTypes;
        state_end_f{mouse} = Mat.state_end_f;
        trialLengths{mouse} = Mat.trialLengths;
    elseif iscell(Mat.FPSstack)
        if mouse == 1 
            FPSstack = Mat.FPSstack;
            state_start_f = Mat.state_start_f;
            TrialTypes = Mat.TrialTypes;
            state_end_f = Mat.state_end_f;
            trialLengths = Mat.trialLengths;
        end 
    end 
    optoQ = Mat.optoQ; 
end 

dataSetQ = input('Input 1 to load another data set and append to the relevant variables. '); 
while dataSetQ == 1
    %get the additional data you need 
    mouseNum2 = input('How many mice are there? ');
    FPSstack2 = cell(1,mouseNum2); 
    Ceta2 = cell(1,mouseNum2); 
    Beta2 = cell(1,mouseNum2); 
    Veta2 = cell(1,mouseNum2); 
    CaROIs2 = cell(1,mouseNum2); 
    state_start_f2 = cell(1,mouseNum2); 
    state_end_f2 = cell(1,mouseNum2); 
    TrialTypes2 = cell(1,mouseNum2);
    trialLengths2 = cell(1,mouseNum2);
    for mouse = 1:mouseNum2
        regImDir = uigetdir('*.*',sprintf('WHERE IS THE ETA DATA FOR MOUSE #%d?',mouse));
        cd(regImDir);
        MatFileName = uigetfile('*.*',sprintf('SELECT THE ETA DATA FOR MOUSE #%d',mouse));
        Mat = matfile(MatFileName);
        if CAQ == 1 
            Ceta2{mouse} = Mat.Ceta;
            CaROIs2{mouse} = input(sprintf('What are the Ca ROIs for mouse #%d? ',mouse));
        end 
        if BBBQ == 1
            Beta2{mouse} = Mat.Beta;
        end 
        if VWQ == 1 
            Veta2{mouse} = Mat.Veta;
        end 
        if ~iscell(Mat.FPSstack)
            FPSstack2{mouse} = Mat.FPSstack;
            state_start_f2{mouse} = Mat.state_start_f;
            TrialTypes2{mouse} = Mat.TrialTypes;
            state_end_f2{mouse} = Mat.state_end_f;
            trialLengths2{mouse} = Mat.trialLengths;
        elseif iscell(Mat.FPSstack)
            if mouse == 1 
                FPSstack2 = Mat.FPSstack;
                state_start_f2 = Mat.state_start_f;
                TrialTypes2 = Mat.TrialTypes;
                state_end_f2 = Mat.state_end_f;
                trialLengths2 = Mat.trialLengths;
            end 
        end 
    end 
    % append new data to original variables 
    mouseNum1 = mouseNum; mouseNum = mouseNum + mouseNum2;
    for mouse = 1:mouseNum2
        if CAQ == 1 
            Ceta{mouseNum1+mouse} = Ceta2{mouse};
            CaROIs{mouseNum1+mouse} = CaROIs2{mouse};
        end 
        if BBBQ == 1
            Beta{mouseNum1+mouse} = Beta2{mouse};
        end 
        if VWQ == 1 
            Veta{mouseNum1+mouse} = Veta2{mouse};
        end 
        FPSstack{mouseNum1+mouse} = FPSstack2{mouse};
        state_start_f{mouseNum1+mouse} = state_start_f2{mouse};
        TrialTypes{mouseNum1+mouse} = TrialTypes2{mouse};
        state_end_f{mouseNum1+mouse} = state_end_f2{mouse};
        trialLengths{mouseNum1+mouse} = trialLengths2{mouse};
    end
    dataSetQ = input('Input 1 to load another data set and append to the relevant variables. Input 0 otherwise. '); 
end 

%% figure out the size you should resample your data to 
%the min length names (dependent on length(tTypes))are hard coded in 

% FPSstack2 = zeros(1,mouseNum);
% for mouse = 1:mouseNum
%     FPSstack2(mouse) = FPSstack{mouse};
% end 
FPSstack2 = zeros(1,mouseNum);
for mouse = 1:mouseNum
    FPSstack2(mouse) = FPSstack{mouse};
end 

minFPSstack = FPSstack2 == min(FPSstack2);
idx = find(minFPSstack ~= 0, 1, 'first');

%sort data
tTypeNum = input('How many different trial types are there? '); 

clearvars tTypeInds
% make sure tType index is known for given ttype num 
if optoQ == 1 
    uniqueLightTypes = cell(1,mouseNum);
    uniqueTrialLengths = cell(1,mouseNum);
    tTypes = cell(1,mouseNum);
    trialData = cell(1,mouseNum); 
    vidCheck = cell(1,mouseNum); 
    mouseCheck = zeros(1,mouseNum); 
    % check to see if red or blue opto lights were used    
    for mouse = 1:mouseNum
        for vid = 1:length(TrialTypes{mouse})   
            % combine trialTypes and trialLengths 
            trialData{mouse}{vid}(:,1) = TrialTypes{mouse}{vid}(:,2);
            trialData{mouse}{vid}(:,2) = trialLengths{mouse}{vid};
            % determine the combination of trialTypes and lengths that
            % occur per vid 
            %if the blue light is on for 2 seconds
            if any(ismember(trialData{mouse}{vid},[1,floor(2*FPSstack{mouse})],'rows') == 1)
                tTypes{mouse}{vid}(1) = 1;              
            end 
            %if the blue light is on for 20 seconds 
            if any(ismember(trialData{mouse}{vid},[1,floor(20*FPSstack{mouse})],'rows') == 1)
                tTypes{mouse}{vid}(2) = 2;
            end 
            %if the red light is on for 2 seconds 
            if any(ismember(trialData{mouse}{vid},[2,floor(2*FPSstack{mouse})],'rows') == 1)
                tTypes{mouse}{vid}(3) = 3;
            end 
            %if the red light is on for 20 seconds    
            if any(ismember(trialData{mouse}{vid},[2,floor(20*FPSstack{mouse})],'rows') == 1)
                tTypes{mouse}{vid}(4) = 4;
            end 
            if any(tTypes{mouse}{vid} == 1)
                vidCheck{mouse}(vid,1) = 1;
            end 
            if any(tTypes{mouse}{vid} == 2)
                vidCheck{mouse}(vid,2) = 2;
            end 
            if any(tTypes{mouse}{vid} == 3)
                vidCheck{mouse}(vid,3) = 3;
            end 
            if any(tTypes{mouse}{vid} == 4)
                vidCheck{mouse}(vid,4) = 4;
            end             
        end  
        if sum(any(vidCheck{mouse} == 1)) > 0  
            mouseCheck(mouse,1) = 1; 
        end 
        if sum(any(vidCheck{mouse} == 2)) > 0 
            mouseCheck(mouse,2) = 2; 
        end 
        if sum(any(vidCheck{mouse} == 3)) > 0 
            mouseCheck(mouse,3) = 3; 
        end 
        if sum(any(vidCheck{mouse} == 4)) > 0 
            mouseCheck(mouse,4) = 4; 
        end 
    end 
    if sum(any(mouseCheck == 1)) > 0 
        tTypeInds(1) = 1;
    end 
    if sum(any(mouseCheck == 2)) > 0 
        tTypeInds(2) = 2;
    end 
    if sum(any(mouseCheck == 3)) > 0 
        tTypeInds(3) = 3;
    end 
    if sum(any(mouseCheck == 4)) > 0 
        tTypeInds(4) = 4;
    end 
elseif optoQ == 0
    tTypeInds = 1;
end 
% make sure the number of trialTypes in the data matches up with what
% you think it should
tTnum = nnz(tTypeInds);
if tTnum ~= tTypeNum
    disp('The number of trial types in the data does not match up with the number of trial types inputed by user!!!');
end 

% determine min len for each trial type/length
if CAQ == 1
    if any(tTypeInds == 1) && any(tTypeInds == 3)
        minLen13 = min(nonzeros([size(Ceta{idx}{CaROIs{idx}(1)}{1},2),size(Ceta{idx}{CaROIs{idx}(1)}{3},2)]));
    elseif any(tTypeInds == 1) && ~any(tTypeInds == 3)
        minLen13 = size(Ceta{idx}{CaROIs{idx}(1)}{1},2);
    elseif ~any(tTypeInds == 1) && any(tTypeInds == 3)
        minLen13 = size(Ceta{idx}{CaROIs{idx}(1)}{3},2);
    end 
    if any(tTypeInds == 2) && any(tTypeInds == 4)
        minLen24 = min(nonzeros([size(Ceta{idx}{CaROIs{idx}(1)}{2},2),size(Ceta{idx}{CaROIs{idx}(1)}{4},2)]));
    elseif any(tTypeInds == 2) && ~any(tTypeInds == 4)
        minLen24 = size(Ceta{idx}{CaROIs{idx}(1)}{2},2);
    elseif ~any(tTypeInds == 2) && any(tTypeInds == 4)
        minLen24 = size(Ceta{idx}{CaROIs{idx}(1)}{4},2);
    end 
elseif CAQ ~= 1 && BBBQ == 1
    if any(tTypeInds == 1) && any(tTypeInds == 3)
        minLen13 = min(nonzeros([size(Beta{idx}{1}{1},2),size(Beta{idx}{1}{3},2)]));
    elseif any(tTypeInds == 1) && ~any(tTypeInds == 3)
        minLen13 = size(Beta{idx}{1}{1},2);
    elseif ~any(tTypeInds == 1) && any(tTypeInds == 3)
        minLen13 = size(Beta{idx}{1}{3},2);
    end 
    if any(tTypeInds == 2) && any(tTypeInds == 4)
        minLen24 = min(nonzeros([size(Beta{idx}{1}{2},2),size(Beta{idx}{1}{4},2)]));
    elseif any(tTypeInds == 2) && ~any(tTypeInds == 4)
        minLen24 = size(Beta{idx}{1}{2},2);
    elseif ~any(tTypeInds == 2) && any(tTypeInds == 4)
        minLen24 = size(Beta{idx}{1}{4},2);
    end 
elseif CAQ ~= 1 && VWQ == 1 
    if any(tTypeInds == 1) && any(tTypeInds == 3)
        minLen13 = min(nonzeros([size(Veta{idx}{1}{1},2),size(Veta{idx}{1}{3},2)]));
    elseif any(tTypeInds == 1) && ~any(tTypeInds == 3)
        minLen13 = size(Veta{idx}{1}{1},2);
    elseif ~any(tTypeInds == 1) && any(tTypeInds == 3)
        minLen13 = size(Veta{idx}{1}{3},2);
    end 
    if any(tTypeInds == 2) && any(tTypeInds == 4)
        minLen24 = min(nonzeros([size(Veta{idx}{1}{2},2),size(Veta{idx}{1}{4},2)]));
    elseif any(tTypeInds == 2) && ~any(tTypeInds == 4)
        minLen24 = size(Veta{idx}{1}{2},2);
    elseif ~any(tTypeInds == 2) && any(tTypeInds == 4)
        minLen24 = size(Veta{idx}{1}{4},2);
    end 
end 

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
    baselineEndFrame = floor(sec_before_stim_start*(FPSstack2(idx)));
end 

% make it possible to select what trials you want to average per mouse 
trialAVQ = input('Input 1 if you want to select specific trials to average. Input 0 otherwise. ');
if trialAVQ == 0   
    trials = cell(1,mouseNum);
    tTypeTrials = cell(1,mouseNum);
    for mouse = 1:mouseNum 
        % figure out what trial type each trial got sorted into 
        count1 = 1;
        count2 = 1;
        count3 = 1;
        count4 = 1;
        for vid = 1:length(TrialTypes{mouse})  
            trials{mouse}{vid} = 1:length(trialLengths{mouse}{vid});          
            for trial = 1:length(trials{mouse}{vid})
                %if the blue light is on
                if TrialTypes{mouse}{vid}(trials{mouse}{vid}(trial),2) == 1
                    %if it is a 2 sec trial 
                    if trialLengths{mouse}{vid}(trials{mouse}{vid}(trial)) == floor(2*FPSstack2(mouse))  
                        tTypeTrials{mouse}{vid}{1}(count1) = trials{mouse}{vid}(trial);
                        count1 = count1 + 1;
                    %if it is a 20 sec trial
                    elseif trialLengths{mouse}{vid}(trials{mouse}{vid}(trial)) == floor(20*FPSstack2(mouse))
                        tTypeTrials{mouse}{vid}{2}(count2) = trials{mouse}{vid}(trial);
                        count2 = count2 + 1;
                    end 
                %if the red light is on 
                elseif TrialTypes{mouse}{vid}(trials{mouse}{vid}(trial),2) == 2
                    %if it is a 2 sec trial 
                    if trialLengths{mouse}{vid}(trials{mouse}{vid}(trial)) == floor(2*FPSstack2(mouse))
                        tTypeTrials{mouse}{vid}{3}(count3) = trials{mouse}{vid}(trial);
                        count3 = count3 + 1;
                    %if it is a 20 sec trial
                    elseif trialLengths{mouse}{vid}(trials{mouse}{vid}(trial)) == floor(20*FPSstack2(mouse))
                        tTypeTrials{mouse}{vid}{4}(count4) = trials{mouse}{vid}(trial);
                        count4 = count4 + 1;
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
elseif trialAVQ == 1 
    trialAVQ2 = input('Input 1 if you want to average multiple groups of trials. Input 0 for one group. '); 
    if trialAVQ2 == 0 
        trials = cell(1,mouseNum);
        tTypeTrials = cell(1,mouseNum);
        for mouse = 1:mouseNum 
            % figure out what trial type each trial got sorted into 
            count1 = 1;
            count2 = 1;
            count3 = 1;
            count4 = 1;
            for vid = 1:length(TrialTypes{mouse})  
                trials{mouse}{vid} = input(sprintf('Input what trials you want to average for mouse %d vid %d. ',mouse,vid));
                for trial = 1:length(trials{mouse}{vid})
                    %if the blue light is on
                    if TrialTypes{mouse}{vid}(trials{mouse}{vid}(trial),2) == 1
                        %if it is a 2 sec trial 
                        if trialLengths{mouse}{vid}(trials{mouse}{vid}(trial)) == floor(2*FPSstack2(mouse))  
                            tTypeTrials{mouse}{vid}{1}(count1) = trials{mouse}{vid}(trial);
                            count1 = count1 + 1;
                        %if it is a 20 sec trial
                        elseif trialLengths{mouse}{vid}(trials{mouse}{vid}(trial)) == floor(20*FPSstack2(mouse))
                            tTypeTrials{mouse}{vid}{2}(count2) = trials{mouse}{vid}(trial);
                            count2 = count2 + 1;
                        end 
                    %if the red light is on 
                    elseif TrialTypes{mouse}{vid}(trials{mouse}{vid}(trial),2) == 2
                        %if it is a 2 sec trial 
                        if trialLengths{mouse}{vid}(trials{mouse}{vid}(trial)) == floor(2*FPSstack2(mouse))
                            tTypeTrials{mouse}{vid}{3}(count3) = trials{mouse}{vid}(trial);
                            count3 = count3 + 1;
                        %if it is a 20 sec trial
                        elseif trialLengths{mouse}{vid}(trials{mouse}{vid}(trial)) == floor(20*FPSstack2(mouse))
                            tTypeTrials{mouse}{vid}{4}(count4) = trials{mouse}{vid}(trial);
                            count4 = count4 + 1;
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
    elseif trialAVQ2 == 1
        trialGroupLen = input('How many trials do you want to average together per group? ');
        trialGroupMaxQ = input('Input 1 if you want to limit how many overall trials you are averaging into groups. Input 0 otherwise. ');
        if trialGroupMaxQ == 1
            trialGroupMax = cell(1,mouseNum);
            value = input('What is the maximum trial that you want to average into groups? ');
            for mouse = 1:mouseNum 
                for vid = 1:length(TrialTypes{mouse})
                    trialGroupMax{mouse}{vid} = value;
                end 
            end 
        elseif trialGroupMaxQ == 0
            trialGroupMax = cell(1,mouseNum);
            for mouse = 1:mouseNum 
                for vid = 1:length(TrialTypes{mouse}) 
                    trialGroupMax{mouse}{vid} = length(trialLengths{mouse}{vid});   
                end 
            end 
        end 
    
        % figure out the grouping of trials based on the size of each group and
        % the maximum number of trials to be grouped for averaging 
        numGroups = cell(1,mouseNum);
        sortedGroupTrials = cell(1,mouseNum);
        trials = cell(1,mouseNum);
        for mouse = 1:mouseNum 
            for vid = 1:length(TrialTypes{mouse})
                % figure out how many groups there are 
                if floor(trialGroupMax{mouse}{vid}/trialGroupLen) == trialGroupMax{mouse}{vid}/trialGroupLen % if groupMax/groupLen is an integer
                    numGroups{mouse}{vid} = trialGroupMax{mouse}{vid}/trialGroupLen;
                elseif floor(trialGroupMax{mouse}{vid}/trialGroupLen) ~= trialGroupMax{mouse}{vid}/trialGroupLen % if groupMax/groupLen is not an integer
                    numGroups{mouse}{vid} = floor(trialGroupMax{mouse}{vid}/trialGroupLen);
                end 
                % figure out what trials go to what groups 
                trials{mouse}{vid} = 1:length(trialLengths{mouse}{vid});
                count = 1;
                for group = 1:numGroups{mouse}{vid}
                    count1 = 1; count2 = 1; count3 = 1; count4 = 1;
                    for trial = 1:trialGroupLen                                      
                        %if the blue light is on
                        if TrialTypes{mouse}{vid}(trials{mouse}{vid}(trial),2) == 1
                            %if it is a 2 sec trial 
                            if trialLengths{mouse}{vid}(trials{mouse}{vid}(trial)) == floor(2*FPSstack2(mouse))  
                                sortedGroupTrials{mouse}{vid}{1}{group}(count1) = trials{mouse}{vid}(count);  
                                count1 = count1 + 1;
                                count = count + 1;                  
                            %if it is a 20 sec trial
                            elseif trialLengths{mouse}{vid}(trials{mouse}{vid}(trial)) == floor(20*FPSstack2(mouse))
                                sortedGroupTrials{mouse}{vid}{2}{group}(count2) = trials{mouse}{vid}(count);  
                                count2 = count2 + 1;
                                count = count + 1; 
                            end 
                        %if the red light is on 
                        elseif TrialTypes{mouse}{vid}(trials{mouse}{vid}(trial),2) == 2
                            %if it is a 2 sec trial 
                            if trialLengths{mouse}{vid}(trials{mouse}{vid}(trial)) == floor(2*FPSstack2(mouse))
                                sortedGroupTrials{mouse}{vid}{3}{group}(count3) = trials{mouse}{vid}(count);  
                                count3 = count3 + 1;
                                count = count + 1; 
                            %if it is a 20 sec trial
                            elseif trialLengths{mouse}{vid}(trials{mouse}{vid}(trial)) == floor(20*FPSstack2(mouse))
                                sortedGroupTrials{mouse}{vid}{4}{group}(count4) = trials{mouse}{vid}(count);  
                                count4 = count4 + 1;
                                count = count + 1; 
                            end 
                        end                                   
                    end 
                end   
            end 
        end 
        if CAQ == 1          
            Ctraces2= sortedGroupTrials;            
        end 
        if BBBQ == 1 
            Btraces2= sortedGroupTrials;
        end 
        if VWQ == 1 
            Vtraces2= sortedGroupTrials;            
        end         
    end 
end 

if trialAVQ == 0 || (trialAVQ == 1 && trialAVQ2 == 0)
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
end 

% remove 0s b = a(any(a,2),:)
if CAQ == 1 
    trialList = Ctraces;
elseif CAQ ~= 1 && BBBQ == 1 
    trialList = Btraces;
elseif CAQ ~= 1 && BBBQ ~= 1 && VWQ == 1
    trialList = Vtraces;
elseif CAQ ~= 1 && VWQ ~= 1 && BBB == 1
    trialList = Btraces;
elseif CAQ ~= 1 && VWQ == 1 && BBB == 1
    trialList = Btraces;
end 
if length(nonzeros(tTypeInds))~= tTypeNum
    disp("The number of trial types does not match up with input! ");
elseif length(nonzeros(tTypeInds))== tTypeNum
    tTypeInds2 = nonzeros(tTypeInds);
    tTypeInds = tTypeInds2;
end 
trials2 = cell(1,mouseNum);
for mouse = 1:mouseNum
    for vid = 1:length(state_start_f{mouse}) 
        for tType = 1:tTypeNum
            if length(trialList{mouse}{vid}) >= tTypeInds(tType) && isempty(trialList{mouse}{vid}{tTypeInds(tType)}) == 0 
                trials2{mouse}{vid}{tTypeInds(tType)} = nonzeros(trialList{mouse}{vid}{tTypeInds(tType)});
            end 
        end 
    end 
end 
if CAQ == 1
    Ctraces = trials2;
end 
if BBBQ == 1
    Btraces = trials2;
end 
if VWQ == 1
    Vtraces = trials2;
end 

% resort eta data into vids
tTypeInds = nonzeros(unique(tTypeInds));
Ceta2 = cell(1,mouseNum);
Beta2 = cell(1,mouseNum);
Veta2 = cell(1,mouseNum);
Ceta22 = cell(1,mouseNum);
Beta22 = cell(1,mouseNum);
Veta22 = cell(1,mouseNum);
if CAQ == 1
    for mouse = 1:mouseNum
        for CaROI = 1:size(CaROIs{mouse},2)                         
            for tType = 1:tTypeNum
                for vid = 1:length(state_start_f{mouse})  
                    if trialAVQ == 0 || (trialAVQ == 1 && trialAVQ2 == 0)                                        
                         if  tTypeInds(tType) <= length(Ctraces{mouse}{vid}) && isempty(Ctraces{mouse}{vid}{tTypeInds(tType)}) == 0                          
                            for trace = 1:nnz(Ctraces{mouse}{vid}{tTypeInds(tType)})                                
                                if Ctraces{mouse}{vid}{tTypeInds(tType)}(trace) <= size(Ceta{mouse}{CaROIs{mouse}(CaROI)}{tTypeInds(tType)},1)                                    
                                    Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}(trace,:) = Ceta{mouse}{CaROIs{mouse}(CaROI)}{tTypeInds(tType)}(Ctraces{mouse}{vid}{tTypeInds(tType)}(trace),:);                             
                                end 
                            end  
                         end 
                    end 
                    if trialAVQ == 1 && trialAVQ2 == 1                        
                        for group = 1:numGroups{mouse}{vid}
                            for trace = 1:nnz(Ctraces2{mouse}{vid}{tTypeInds(tType)}{group}) 
                                if Ctraces2{mouse}{vid}{tTypeInds(tType)}{group}(trace) <= size(Ceta{mouse}{CaROIs{mouse}(CaROI)}{tTypeInds(tType)},1)   
                                    Ceta22{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}{group}(trace,:) = Ceta{mouse}{CaROIs{mouse}(CaROI)}{tTypeInds(tType)}(Ctraces2{mouse}{vid}{tTypeInds(tType)}{group}(trace),:);                             
                                end                                
                            end 
                        end 
                    end                                                  
                end               
            end                
        end 
    end 
end 
if BBBQ == 1 
    for mouse = 1:mouseNum
        for BBBroi = 1:size(Beta{mouse},2) 
            for tType = 1:tTypeNum            
                for vid = 1:length(state_start_f{mouse})
                    if trialAVQ == 0 || (trialAVQ == 1 && trialAVQ2 == 0)                  
                        if  tTypeInds(tType) <= length(Btraces{mouse}{vid}) && isempty(Btraces{mouse}{vid}{tTypeInds(tType)}) == 0                          
                            for trace = 1:nnz(Btraces{mouse}{vid}{tTypeInds(tType)})                            
                                if Btraces{mouse}{vid}{tTypeInds(tType)}(trace) <= size(Beta{mouse}{BBBroi}{tTypeInds(tType)},1)                                
                                    Beta2{mouse}{BBBroi}{vid}{tTypeInds(tType)}(trace,:) = Beta{mouse}{BBBroi}{tTypeInds(tType)}(Btraces{mouse}{vid}{tTypeInds(tType)}(trace),:);
                                end 
                            end 
                        end 
                    end 
                    if trialAVQ == 1 && trialAVQ2 == 1 
                        for group = 1:numGroups{mouse}{vid}
                            for trace = 1:nnz(Btraces2{mouse}{vid}{tTypeInds(tType)}{group}) 
                                if Btraces2{mouse}{vid}{tTypeInds(tType)}{group}(trace) <= size(Beta{mouse}{BBBroi}{tTypeInds(tType)},1)    
                                    Beta22{mouse}{BBBroi}{vid}{tTypeInds(tType)}{group}(trace,:) = Beta{mouse}{BBBroi}{tTypeInds(tType)}(Btraces2{mouse}{vid}{tTypeInds(tType)}{group}(trace),:);                             
                                end                                
                            end 
                        end   
                    end                     
                end 
            end 
        end 
    end 
end 
if VWQ == 1
    for mouse = 1:mouseNum
        for VWroi = 1:size(Veta{mouse},2)          
            for tType = 1:tTypeNum
                count3 = 1;
                for vid = 1:length(state_start_f{mouse}) 
                    if trialAVQ == 0 || (trialAVQ == 1 && trialAVQ2 == 0)    
                        if  tTypeInds(tType) <= length(Vtraces{mouse}{vid}) && isempty(Vtraces{mouse}{vid}{tTypeInds(tType)}) == 0                            
                            for trace = 1:nnz(Vtraces{mouse}{vid}{tTypeInds(tType)})                              
                                if Vtraces{mouse}{vid}{tTypeInds(tType)}(trace) <= size(Veta{mouse}{VWroi}{tTypeInds(tType)},1)                                
                                    Veta2{mouse}{VWroi}{vid}{tTypeInds(tType)}(trace,:) = Veta{mouse}{VWroi}{tTypeInds(tType)}(Vtraces{mouse}{vid}{tTypeInds(tType)}(trace),:);
                                    count3 = count3 + 1;
                                end 
                            end            
                        end 
                    end 
                    if trialAVQ == 1 && trialAVQ2 == 1
                        for group = 1:numGroups{mouse}{vid}
                            for trace = 1:nnz(Vtraces2{mouse}{vid}{tTypeInds(tType)}{group}) 
                                if Vtraces2{mouse}{vid}{tTypeInds(tType)}{group}(trace) <= size(Veta{mouse}{VWroi}{tTypeInds(tType)},1)     
                                    Veta22{mouse}{VWroi}{vid}{tTypeInds(tType)}{group}(trace,:) = Veta{mouse}{VWroi}{tTypeInds(tType)}(Vtraces2{mouse}{vid}{tTypeInds(tType)}{group}(trace),:);                             
                                end                                
                            end 
                        end   
                    end                                        
                end 
            end 
        end 
    end 
end 

%% select specific trials, resample, and plot data 

% numBS = input('How many trials do you want to bootstrap to? '); 
% numBScData = numBS; 
% numBSvData = numBS; 
% numBSbData = numBS; 
if trialAVQ == 0 || (trialAVQ == 1 && trialAVQ2 == 0)    
    plotAVQ = input("Input 1 to plot averaged data. Input 0 to plot individual traces. ");
end 
snCetaArray = cell(1,tTypeNum);
snBetaArray = cell(1,tTypeNum);
snVetaArray = cell(1,tTypeNum);
BScData = cell(1,tTypeNum);
BSbData = cell(1,tTypeNum);
BSvData = cell(1,tTypeNum);
avBScData = cell(1,tTypeNum);
avBSbData = cell(1,tTypeNum);
avBSvData = cell(1,tTypeNum);
CI_cbsLow = cell(1,tTypeNum);
CI_cbsHigh = cell(1,tTypeNum);
CI_bbsLow = cell(1,tTypeNum);
CI_bbsHigh = cell(1,tTypeNum);
CI_vbsLow = cell(1,tTypeNum);
CI_vbsHigh = cell(1,tTypeNum);
shuff_snCetaArray = cell(1,tTypeNum);
shuff_snBetaArray = cell(1,tTypeNum);
shuff_snVetaArray = cell(1,tTypeNum);
CI_cshLow = cell(1,tTypeNum);
CI_cshHigh = cell(1,tTypeNum);
CI_bshLow = cell(1,tTypeNum);
CI_bshHigh = cell(1,tTypeNum);
CI_vshLow = cell(1,tTypeNum);
CI_vshHigh = cell(1,tTypeNum);
avSHcData = cell(1,tTypeNum);
avSHbData = cell(1,tTypeNum);
avSHvData = cell(1,tTypeNum);
BScshData = cell(1,tTypeNum);
BSvshData = cell(1,tTypeNum);
BSbshData = cell(1,tTypeNum);
CetaArray2 = cell(1,mouseNum);
BetaArray2 = cell(1,mouseNum);
VetaArray2 = cell(1,mouseNum);
CetaArray3 = cell(1,tTypeNum );
BetaArray3 = cell(1,tTypeNum );
VetaArray3 = cell(1,tTypeNum );
CetaArray4 = cell(1,tTypeNum );
BetaArray4 = cell(1,tTypeNum );
VetaArray4 = cell(1,tTypeNum );
sCetaAvs4 = cell(1,tTypeNum );
sBetaAvs4 = cell(1,tTypeNum );
sVetaAvs4 = cell(1,tTypeNum );
snCetaArray4 = cell(1,tTypeNum );
snBetaArray4 = cell(1,tTypeNum );
snVetaArray4 = cell(1,tTypeNum );
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
        if tTypeInds(tType) == 1 || tTypeInds(tType) == 3  
          if CAQ == 1                         
            for CaROI = 1:size(CaROIs{mouse},2)
                if trialAVQ == 0 || (trialAVQ == 1 && trialAVQ2 == 0)
                    for vid = 1:length(Ceta2{mouse}{CaROIs{mouse}(CaROI)})  
                        if tTypeInds(tType) <= length(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}) && isempty(Ceta2{mouse}{CaROIs{mouse}(1)}{vid}{tTypeInds(tType)}) == 0  
                            for trace = 1:size(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)},1)
                                CetaArray1{mouse}{tTypeInds(tType)}(Ccounter,:) =  resample(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}(trace,:),minLen13,size(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}(trace,:),2)); 
                                CetaArray2{mouse}{tTypeInds(tType)}{trace}(Ccounter,:) =  resample(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}(trace,:),minLen13,size(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}(trace,:),2)); 
                                Ccounter = Ccounter + 1;  
                                %remove rows with 0's 
                                CetaArray2{mouse}{tTypeInds(tType)}{trace} = CetaArray2{mouse}{tTypeInds(tType)}{trace}(any(CetaArray2{mouse}{tTypeInds(tType)}{trace},2),:);
                            end   
                        end 
                    end     
                end 
                if trialAVQ == 1 && trialAVQ2 == 1                   
                    for vid = 1:length(Ceta22{mouse}{CaROIs{mouse}(CaROI)})                          
                        if tTypeInds(tType) <= length(Ceta22{mouse}{CaROIs{mouse}(CaROI)}{vid}) && isempty(Ceta22{mouse}{CaROIs{mouse}(1)}{vid}{tTypeInds(tType)}) == 0  
                            for group = 1:numGroups{mouse}{vid}                                                               
                                for trace = 1:size(Ceta22{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}{group},1)
                                    CetaArray1{mouse}{tTypeInds(tType)}{group}(Ccounter,:) =  resample(Ceta22{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}{group}(trace,:),minLen13,size(Ceta22{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}{group}(trace,:),2)); 
                                    CetaArray2{mouse}{tTypeInds(tType)}{group}{trace}(Ccounter,:) =  resample(Ceta22{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}{group}(trace,:),minLen13,size(Ceta22{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}{group}(trace,:),2)); 
                                    Ccounter = Ccounter + 1;  
                                    %remove rows with 0's 
                                    CetaArray2{mouse}{tTypeInds(tType)}{group}{trace} = CetaArray2{mouse}{tTypeInds(tType)}{group}{trace}(any(CetaArray2{mouse}{tTypeInds(tType)}{group}{trace},2),:);
                                end   
                            end 
                        end 
                    end
                    
                end 
            end 
          end 
            if BBBQ == 1                     
                for BBBroi = 1:size(Beta{mouse},2)
                    if trialAVQ == 0 || (trialAVQ == 1 && trialAVQ2 == 0)
                        for vid = 1:length(Beta2{mouse}{BBBroi})  
                            if tTypeInds(tType) <= length(Beta2{mouse}{BBBroi}{vid}) && isempty(Beta2{mouse}{BBBroi}{vid}{tTypeInds(tType)}) == 0        
                                for trace = 1:size(Beta2{mouse}{BBBroi}{vid}{tTypeInds(tType)},1)
                                    BetaArray1{mouse}{tTypeInds(tType)}(Bcounter,:) =  resample(Beta2{mouse}{BBBroi}{vid}{tTypeInds(tType)}(trace,:),minLen13,size(Beta2{mouse}{BBBroi}{vid}{tTypeInds(tType)}(trace,:),2)); %Beta{mouse}{BBBroi}{tTypeInds(tType)}(trace,:); 
                                    BetaArray2{mouse}{tTypeInds(tType)}{trace}(Bcounter,:) =  resample(Beta2{mouse}{BBBroi}{vid}{tTypeInds(tType)}(trace,:),minLen13,size(Beta2{mouse}{BBBroi}{vid}{tTypeInds(tType)}(trace,:),2)); 
                                    Bcounter = Bcounter + 1;  
                                    %remove rows with 0's 
                                    BetaArray2{mouse}{tTypeInds(tType)}{trace} = BetaArray2{mouse}{tTypeInds(tType)}{trace}(any(BetaArray2{mouse}{tTypeInds(tType)}{trace},2),:);
                                end                                    
                            end 
                        end 
                    end 
                    if trialAVQ == 1 && trialAVQ2 == 1                                                 
                        for vid = 1:length(Beta22{mouse}{BBBroi})  
                            if tTypeInds(tType) <= length(Beta22{mouse}{BBBroi}{vid}) && isempty(Beta22{mouse}{BBBroi}{vid}{tTypeInds(tType)}) == 0    
                                for group = 1:numGroups{mouse}{vid}
                                    for trace = 1:size(Beta22{mouse}{BBBroi}{vid}{tTypeInds(tType)}{group},1)
                                        BetaArray1{mouse}{tTypeInds(tType)}{group}(Bcounter,:) =  resample(Beta22{mouse}{BBBroi}{vid}{tTypeInds(tType)}{group}(trace,:),minLen13,size(Beta22{mouse}{BBBroi}{vid}{tTypeInds(tType)}{group}(trace,:),2)); %Beta{mouse}{BBBroi}{tTypeInds(tType)}(trace,:); 
                                        BetaArray2{mouse}{tTypeInds(tType)}{group}{trace}(Bcounter,:) =  resample(Beta22{mouse}{BBBroi}{vid}{tTypeInds(tType)}{group}(trace,:),minLen13,size(Beta22{mouse}{BBBroi}{vid}{tTypeInds(tType)}{group}(trace,:),2)); 
                                        Bcounter = Bcounter + 1;  
                                        %remove rows with 0's 
                                        BetaArray2{mouse}{tTypeInds(tType)}{group}{trace} = BetaArray2{mouse}{tTypeInds(tType)}{group}{trace}(any(BetaArray2{mouse}{tTypeInds(tType)}{group}{trace},2),:);
                                    end   
                                end 
                            end 
                        end                                                 
                    end 
                end 
            end 
            if VWQ == 1                     
                for VWroi = 1:size(Veta{mouse},2) 
                    if trialAVQ == 0 || (trialAVQ == 1 && trialAVQ2 == 0)
                        for vid = 1:length(Veta2{mouse}{VWroi})  
                            if tTypeInds(tType) <= length(Veta2{mouse}{VWroi}{vid}) && isempty(Veta2{mouse}{VWroi}{vid}{tTypeInds(tType)}) == 0 
                                for trace = 1:size(Veta2{mouse}{VWroi}{vid}{tTypeInds(tType)},1)
                                    VetaArray1{mouse}{tTypeInds(tType)}(Vcounter,:) = resample(Veta2{mouse}{VWroi}{vid}{tTypeInds(tType)}(trace,:),minLen13,size(Veta2{mouse}{VWroi}{vid}{tTypeInds(tType)}(trace,:),2));% Veta{mouse}{VWroi}{tTypeInds(tType)}(trace,:); 
                                    VetaArray2{mouse}{tTypeInds(tType)}{trace}(Vcounter,:) =  resample(Veta2{mouse}{VWroi}{vid}{tTypeInds(tType)}(trace,:),minLen13,size(Veta2{mouse}{VWroi}{vid}{tTypeInds(tType)}(trace,:),2)); 
                                    Vcounter = Vcounter + 1;  
                                    %remove rows with 0's 
                                    VetaArray2{mouse}{tTypeInds(tType)}{trace} = VetaArray2{mouse}{tTypeInds(tType)}{trace}(any(VetaArray2{mouse}{tTypeInds(tType)}{trace},2),:);
                                end 
                            end 
                        end 
                    end 
                    if trialAVQ == 1 && trialAVQ2 == 1                          
                        for vid = 1:length(Veta22{mouse}{VWroi})  
                            if tTypeInds(tType) <= length(Veta22{mouse}{VWroi}{vid}) && isempty(Veta22{mouse}{VWroi}{vid}{tTypeInds(tType)}) == 0 
                                for group = 1:numGroups{mouse}{vid}
                                    for trace = 1:size(Veta22{mouse}{VWroi}{vid}{tTypeInds(tType)}{group},1)
                                        VetaArray1{mouse}{tTypeInds(tType)}{group}(Vcounter,:) = resample(Veta22{mouse}{VWroi}{vid}{tTypeInds(tType)}{group}(trace,:),minLen13,size(Veta22{mouse}{VWroi}{vid}{tTypeInds(tType)}{group}(trace,:),2));% Veta{mouse}{VWroi}{tTypeInds(tType)}(trace,:); 
                                        VetaArray2{mouse}{tTypeInds(tType)}{group}{trace}(Vcounter,:) =  resample(Veta22{mouse}{VWroi}{vid}{tTypeInds(tType)}{group}(trace,:),minLen13,size(Veta22{mouse}{VWroi}{vid}{tTypeInds(tType)}{group}(trace,:),2)); 
                                        Vcounter = Vcounter + 1;  
                                        %remove rows with 0's 
                                        VetaArray2{mouse}{tTypeInds(tType)}{group}{trace} = VetaArray2{mouse}{tTypeInds(tType)}{group}{trace}(any(VetaArray2{mouse}{tTypeInds(tType)}{group}{trace},2),:);
                                    end 
                                end 
                            end 
                        end 
                    end 
                end 
            end        
        elseif tTypeInds(tType) == 2 || tTypeInds(tType) == 4
            if CAQ == 1                    
                for CaROI = 1:size(CaROIs{mouse},2)
                    if trialAVQ == 0 || (trialAVQ == 1 && trialAVQ2 == 0)
                        for vid = 1:length(Ceta2{mouse}{CaROIs{mouse}(CaROI)})  
                            if tTypeInds(tType) <= length(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}) && isempty(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}) == 0  
                                for trace = 1:size(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)},1)
                                    CetaArray1{mouse}{tTypeInds(tType)}(Ccounter1,:) =  resample(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}(trace,:),minLen24,size(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}(trace,:),2));                                
                                    CetaArray2{mouse}{tTypeInds(tType)}{trace}(Ccounter,:) =  resample(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}(trace,:),minLen24,size(Ceta2{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}(trace,:),2)); 
                                    Ccounter = Ccounter + 1;  
                                    %remove rows with 0's 
                                    CetaArray2{mouse}{tTypeInds(tType)}{trace} = CetaArray2{mouse}{tTypeInds(tType)}{trace}(any(CetaArray2{mouse}{tTypeInds(tType)}{trace},2),:);
                                end 
                            end 
                        end 
                    end  
                    if trialAVQ == 1 && trialAVQ2 == 1                            
                        for vid = 1:length(Ceta22{mouse}{CaROIs{mouse}(CaROI)})  
                            if tTypeInds(tType) <= length(Ceta22{mouse}{CaROIs{mouse}(CaROI)}{vid}) && isempty(Ceta22{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}) == 0  
                                for group = 1:numGroups{mouse}{vid}
                                    for trace = 1:size(Ceta22{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}{group},1)
                                        CetaArray1{mouse}{tTypeInds(tType)}{group}(Ccounter1,:) =  resample(Ceta22{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}{group}(trace,:),minLen24,size(Ceta22{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}{group}(trace,:),2));                                
                                        CetaArray2{mouse}{tTypeInds(tType)}{group}{trace}(Ccounter,:) =  resample(Ceta22{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}{group}(trace,:),minLen24,size(Ceta22{mouse}{CaROIs{mouse}(CaROI)}{vid}{tTypeInds(tType)}{group}(trace,:),2)); 
                                        Ccounter = Ccounter + 1;  
                                        %remove rows with 0's 
                                        CetaArray2{mouse}{tTypeInds(tType)}{group}{trace} = CetaArray2{mouse}{tTypeInds(tType)}{group}{trace}(any(CetaArray2{mouse}{tTypeInds(tType)}{group}{trace},2),:);
                                    end 
                                end 
                            end 
                        end                                                 
                    end 
                end 
            end 
            if BBBQ == 1                    
                for BBBroi = 1:size(Beta{mouse},2) 
                    if trialAVQ == 0 || (trialAVQ == 1 && trialAVQ2 == 0)
                        for vid = 1:length(Beta2{mouse}{BBBroi})  
                            if tTypeInds(tType) <= length(Beta2{mouse}{BBBroi}{vid}) && isempty(Beta2{mouse}{BBBroi}{vid}{tTypeInds(tType)}) == 0    
                                for trace = 1:size(Beta2{mouse}{BBBroi}{vid}{tTypeInds(tType)},1)
                                    BetaArray1{mouse}{tTypeInds(tType)}(Bcounter1,:) =  resample(Beta2{mouse}{BBBroi}{vid}{tTypeInds(tType)}(trace,:),minLen24,size(Beta2{mouse}{BBBroi}{vid}{tTypeInds(tType)}(trace,:),2)); %Beta{mouse}{BBBroi}{tTypeInds(tType)}(trace,:); 
                                    BetaArray2{mouse}{tTypeInds(tType)}{trace}(Bcounter,:) =  resample(Beta2{mouse}{BBBroi}{vid}{tTypeInds(tType)}(trace,:),minLen24,size(Beta2{mouse}{BBBroi}{vid}{tTypeInds(tType)}(trace,:),2)); 
                                    Bcounter = Bcounter + 1;  
                                    %remove rows with 0's 
                                    BetaArray2{mouse}{tTypeInds(tType)}{trace} = BetaArray2{mouse}{tTypeInds(tType)}{trace}(any(BetaArray2{mouse}{tTypeInds(tType)}{trace},2),:);
                                end 
                            end                             
                        end 
                    end 
                    if trialAVQ == 1 && trialAVQ2 == 1  
                        for vid = 1:length(Beta22{mouse}{BBBroi})  
                            if tTypeInds(tType) <= length(Beta22{mouse}{BBBroi}{vid}) && isempty(Beta22{mouse}{BBBroi}{vid}{tTypeInds(tType)}) == 0    
                                for group = 1:numGroups{mouse}{vid}
                                    for trace = 1:size(Beta22{mouse}{BBBroi}{vid}{tTypeInds(tType)}{group},1)
                                        BetaArray1{mouse}{tTypeInds(tType)}{group}(Bcounter1,:) =  resample(Beta22{mouse}{BBBroi}{vid}{tTypeInds(tType)}{group}(trace,:),minLen24,size(Beta22{mouse}{BBBroi}{vid}{tTypeInds(tType)}{group}(trace,:),2)); %Beta{mouse}{BBBroi}{tTypeInds(tType)}(trace,:); 
                                        BetaArray2{mouse}{tTypeInds(tType)}{group}{trace}(Bcounter,:) =  resample(Beta22{mouse}{BBBroi}{vid}{tTypeInds(tType)}{group}(trace,:),minLen24,size(Beta22{mouse}{BBBroi}{vid}{tTypeInds(tType)}{group}(trace,:),2)); 
                                        Bcounter = Bcounter + 1;  
                                        %remove rows with 0's 
                                        BetaArray2{mouse}{tTypeInds(tType)}{group}{trace} = BetaArray2{mouse}{tTypeInds(tType)}{group}{trace}(any(BetaArray2{mouse}{tTypeInds(tType)}{group}{trace},2),:);
                                    end 
                                end 
                            end                             
                        end                                                                         
                    end 
                end 
            end 
            if VWQ == 1 
                for VWroi = 1:size(Veta{mouse},2)
                    if trialAVQ == 0 || (trialAVQ == 1 && trialAVQ2 == 0)
                        for vid = 1:length(Veta2{mouse}{VWroi})  
                            if tTypeInds(tType) <= length(Veta2{mouse}{VWroi}{vid}) && isempty(Veta2{mouse}{VWroi}{vid}{tTypeInds(tType)}) == 0 
                                for trace = 1:size(Veta2{mouse}{VWroi}{vid}{tTypeInds(tType)},1)
                                    VetaArray1{mouse}{tTypeInds(tType)}(Vcounter1,:) = resample(Veta2{mouse}{VWroi}{vid}{tTypeInds(tType)}(trace,:),minLen24,size(Veta2{mouse}{VWroi}{vid}{tTypeInds(tType)}(trace,:),2));% Veta{mouse}{VWroi}{tTypeInds(tType)}(trace,:); 
                                    VetaArray2{mouse}{tTypeInds(tType)}{trace}(Vcounter,:) =  resample(Veta2{mouse}{VWroi}{vid}{tTypeInds(tType)}(trace,:),minLen24,size(Veta2{mouse}{VWroi}{vid}{tTypeInds(tType)}(trace,:),2)); 
                                    Vcounter = Vcounter + 1;  
                                    %remove rows with 0's 
                                    VetaArray2{mouse}{tTypeInds(tType)}{trace} = VetaArray2{mouse}{tTypeInds(tType)}{trace}(any(VetaArray2{mouse}{tTypeInds(tType)}{trace},2),:);
                                end 
                            end 
                        end 
                    end 
                    if trialAVQ == 1 && trialAVQ2 == 1                                                  
                        for vid = 1:length(Veta22{mouse}{VWroi})  
                            if tTypeInds(tType) <= length(Veta22{mouse}{VWroi}{vid}) && isempty(Veta22{mouse}{VWroi}{vid}{tTypeInds(tType)}) == 0 
                                for group = 1:numGroups{mouse}{vid}
                                    for trace = 1:size(Veta22{mouse}{VWroi}{vid}{tTypeInds(tType)}{group},1)
                                        VetaArray1{mouse}{tTypeInds(tType)}{group}(Vcounter1,:) = resample(Veta22{mouse}{VWroi}{vid}{tTypeInds(tType)}{group}(trace,:),minLen24,size(Veta22{mouse}{VWroi}{vid}{tTypeInds(tType)}{group}(trace,:),2));% Veta{mouse}{VWroi}{tTypeInds(tType)}(trace,:); 
                                        VetaArray2{mouse}{tTypeInds(tType)}{group}{trace}(Vcounter,:) =  resample(Veta22{mouse}{VWroi}{vid}{tTypeInds(tType)}{group}(trace,:),minLen24,size(Veta22{mouse}{VWroi}{vid}{tTypeInds(tType)}{group}(trace,:),2)); 
                                        Vcounter = Vcounter + 1;  
                                        %remove rows with 0's 
                                        VetaArray2{mouse}{tTypeInds(tType)}{group}{trace} = VetaArray2{mouse}{tTypeInds(tType)}{group}{trace}(any(VetaArray2{mouse}{tTypeInds(tType)}{group}{trace},2),:);
                                    end 
                                end 
                            end 
                        end                                                                        
                    end 
                end 
            end 
        end                     
    end
      
    if trialAVQ == 1 && trialAVQ2 == 1
        numGroups2 = cell(1,mouseNum);
        for mouse = 1:mouseNum
            for vid = 1:length(Veta22{mouse}{VWroi}) 
                if vid == 1 
                    numGroups2{mouse} = numGroups{mouse}{vid};
                elseif vid > 1
                    numGroups2{mouse} = numGroups{mouse}{vid} + numGroups2{mouse};
                end                
            end 
        end 
    end 
    
    
    Ccount = 1;
    Bcount = 1;
    Vcount = 1;
    for mouse = 1:mouseNum         
        if isempty(CetaArray1{mouse}) == 0 
            if tTypeInds(tType) <= length(CetaArray1{mouse}) && isempty(CetaArray1{mouse}{tTypeInds(tType)}) == 0 
                if trialAVQ == 0 || (trialAVQ == 1 && trialAVQ2 == 0)              
                    % put all mouse traces together into same array CetaArray{tType}          
                    if CAQ == 1
                        for trace = 1:size(CetaArray1{mouse}{tTypeInds(tType)},1)
                            CetaArray{tTypeInds(tType)}(Ccounter2,:) = CetaArray1{mouse}{tTypeInds(tType)}(trace,:);
                            Ccounter2 = Ccounter2 + 1 ; 
                        end                     
                        for trial = 1:size(CetaArray2{mouse}{tTypeInds(tType)},2)
                            for trace = 1:size(CetaArray2{mouse}{tTypeInds(tType)}{trial},1)
                                CetaArray3{tTypeInds(tType)}{trial}(Ccount,:) = CetaArray2{mouse}{tTypeInds(tType)}{trial}(trace,:);
                                Ccount = Ccount + 1;
                            end 
                            % remove rows with zeros 
                            CetaArray3{tTypeInds(tType)}{trial} = CetaArray3{tTypeInds(tType)}{trial}(any(CetaArray3{tTypeInds(tType)}{trial},2),:);
                            CetaArray4{tTypeInds(tType)}(trial,:) = nanmean(CetaArray3{tTypeInds(tType)}{trial},1);
                        end 
                    end    
                    if BBBQ == 1
                        for trace = 1:size(BetaArray1{mouse}{tTypeInds(tType)},1)
                            BetaArray{tTypeInds(tType)}(Bcounter2,:) = BetaArray1{mouse}{tTypeInds(tType)}(trace,:);
                            Bcounter2 = Bcounter2 + 1 ; 
                        end                     
                        for trial = 1:size(BetaArray2{mouse}{tTypeInds(tType)},2)
                            for trace = 1:size(BetaArray2{mouse}{tTypeInds(tType)}{trial},1)
                                BetaArray3{tTypeInds(tType)}{trial}(Bcount,:) = BetaArray2{mouse}{tTypeInds(tType)}{trial}(trace,:);
                                Bcount = Bcount + 1;
                            end 
                            % remove rows with zeros 
                            BetaArray3{tTypeInds(tType)}{trial} = BetaArray3{tTypeInds(tType)}{trial}(any(BetaArray3{tTypeInds(tType)}{trial},2),:);
                            BetaArray4{tTypeInds(tType)}(trial,:) = nanmean(BetaArray3{tTypeInds(tType)}{trial},1);
                        end                                         
                    end  
                    if VWQ == 1
                        for trace = 1:size(VetaArray1{mouse}{tTypeInds(tType)},1)
                            VetaArray{tTypeInds(tType)}(Vcounter2,:) = VetaArray1{mouse}{tTypeInds(tType)}(trace,:);
                            Vcounter2 = Vcounter2 + 1 ; 
                        end 
                        for trial = 1:size(VetaArray2{mouse}{tTypeInds(tType)},2)
                            for trace = 1:size(VetaArray2{mouse}{tTypeInds(tType)}{trial},1)
                                VetaArray3{tTypeInds(tType)}{trial}(Vcount,:) = VetaArray2{mouse}{tTypeInds(tType)}{trial}(trace,:);
                                Vcount = Vcount + 1;
                            end 
                            % remove rows with zeros 
                            VetaArray3{tTypeInds(tType)}{trial} = VetaArray3{tTypeInds(tType)}{trial}(any(VetaArray3{tTypeInds(tType)}{trial},2),:);
                            VetaArray4{tTypeInds(tType)}(trial,:) = nanmean(VetaArray3{tTypeInds(tType)}{trial},1);
                        end                                      
                    end 
                end 
                if trialAVQ == 1 && trialAVQ2 == 1  
                    for group = 1:numGroups2{mouse}
                        % put all mouse traces together into same array CetaArray{tType}          
                        if CAQ == 1
                            for trace = 1:size(CetaArray1{mouse}{tTypeInds(tType)}{group},1)
                                CetaArray{tTypeInds(tType)}{group}(Ccounter2,:) = CetaArray1{mouse}{tTypeInds(tType)}{group}(trace,:);
                                Ccounter2 = Ccounter2 + 1 ; 
                            end                     
                            for trial = 1:size(CetaArray2{mouse}{tTypeInds(tType)}{group},2)
                                for trace = 1:size(CetaArray2{mouse}{tTypeInds(tType)}{group}{trial},1)
                                    CetaArray3{tTypeInds(tType)}{group}{trial}(Ccount,:) = CetaArray2{mouse}{tTypeInds(tType)}{group}{trial}(trace,:);
                                    Ccount = Ccount + 1;
                                end 
                                % remove rows with zeros 
                                CetaArray3{tTypeInds(tType)}{group}{trial} = CetaArray3{tTypeInds(tType)}{group}{trial}(any(CetaArray3{tTypeInds(tType)}{group}{trial},2),:);
                                CetaArray4{tTypeInds(tType)}{group}(trial,:) = nanmean(CetaArray3{tTypeInds(tType)}{group}{trial},1);
                            end 
                        end    
                        if BBBQ == 1
                            for trace = 1:size(BetaArray1{mouse}{tTypeInds(tType)}{group},1)
                                BetaArray{tTypeInds(tType)}{group}(Bcounter2,:) = BetaArray1{mouse}{tTypeInds(tType)}{group}(trace,:);
                                Bcounter2 = Bcounter2 + 1 ; 
                            end                     
                            for trial = 1:size(BetaArray2{mouse}{tTypeInds(tType)}{group},2)
                                for trace = 1:size(BetaArray2{mouse}{tTypeInds(tType)}{group}{trial},1)
                                    BetaArray3{tTypeInds(tType)}{group}{trial}(Bcount,:) = BetaArray2{mouse}{tTypeInds(tType)}{group}{trial}(trace,:);
                                    Bcount = Bcount + 1;
                                end 
                                % remove rows with zeros 
                                BetaArray3{tTypeInds(tType)}{group}{trial} = BetaArray3{tTypeInds(tType)}{group}{trial}(any(BetaArray3{tTypeInds(tType)}{group}{trial},2),:);
                                BetaArray4{tTypeInds(tType)}{group}(trial,:) = nanmean(BetaArray3{tTypeInds(tType)}{group}{trial},1);
                            end                                         
                        end  
                        if VWQ == 1
                            for trace = 1:size(VetaArray1{mouse}{tTypeInds(tType)}{group},1)
                                VetaArray{tTypeInds(tType)}{group}(Vcounter2,:) = VetaArray1{mouse}{tTypeInds(tType)}{group}(trace,:);
                                Vcounter2 = Vcounter2 + 1 ; 
                            end 
                            for trial = 1:size(VetaArray2{mouse}{tTypeInds(tType)}{group},2)
                                for trace = 1:size(VetaArray2{mouse}{tTypeInds(tType)}{group}{trial},1)
                                    VetaArray3{tTypeInds(tType)}{group}{trial}(Vcount,:) = VetaArray2{mouse}{tTypeInds(tType)}{group}{trial}(trace,:);
                                    Vcount = Vcount + 1;
                                end 
                                % remove rows with zeros 
                                VetaArray3{tTypeInds(tType)}{group}{trial} = VetaArray3{tTypeInds(tType)}{group}{trial}(any(VetaArray3{tTypeInds(tType)}{group}{trial},2),:);
                                VetaArray4{tTypeInds(tType)}{group}(trial,:) = nanmean(VetaArray3{tTypeInds(tType)}{group}{trial},1);
                            end                                      
                        end                         
                    end 
                end  
            end                       
        end       
    end 
    if isempty(CetaArray{tTypeInds(tType)}) == 0 
        if trialAVQ == 0 || (trialAVQ == 1 && trialAVQ2 == 0)
            %smooth tType data 
            if smoothQ == 0 
                if CAQ == 1
                    sCetaAvs{tTypeInds(tType)} = CetaArray{tTypeInds(tType)}+1000;
                    sCetaAvs4{tTypeInds(tType)} = CetaArray4{tTypeInds(tType)}+1000;
                end 
                if BBBQ == 1
                    sBetaAvs{tTypeInds(tType)} = BetaArray{tTypeInds(tType)}+100;
                    sBetaAvs4{tTypeInds(tType)} = BetaArray4{tTypeInds(tType)}+100;
                end
                if VWQ == 1
                    sVetaAvs{tTypeInds(tType)} = VetaArray{tTypeInds(tType)}+100;
                    sVetaAvs4{tTypeInds(tType)} = VetaArray4{tTypeInds(tType)}+100;
                end
            elseif smoothQ == 1 
                if CAQ == 1
                    sCetaAv =  MovMeanSmoothData(CetaArray{tTypeInds(tType)},filtTime,FPSstack2(idx)); %CetaAvs{tTypeInds(tType)};
                    sCetaAvs{tTypeInds(tType)} = sCetaAv+100; 
                    sCetaAv4 =  MovMeanSmoothData(CetaArray4{tTypeInds(tType)},filtTime,FPSstack2(idx)); %CetaAvs{tTypeInds(tType)};
                    sCetaAvs4{tTypeInds(tType)} = sCetaAv4+100; 
                end 
                if BBBQ == 1
                    sBetaAv =  MovMeanSmoothData(BetaArray{tTypeInds(tType)},filtTime,FPSstack2(idx)); %CetaAvs{tTypeInds(tType)};
                    sBetaAvs{tTypeInds(tType)} = sBetaAv+100; 
                    sBetaAv4 =  MovMeanSmoothData(BetaArray4{tTypeInds(tType)},filtTime,FPSstack2(idx)); %CetaAvs{tTypeInds(tType)};
                    sBetaAvs4{tTypeInds(tType)} = sBetaAv4+100; 
                end 
                if VWQ == 1
                    sVetaAv =  MovMeanSmoothData(VetaArray{tTypeInds(tType)},filtTime,FPSstack2(idx)); %CetaAvs{tTypeInds(tType)};
                    sVetaAvs{tTypeInds(tType)} = sVetaAv+100; 
                    sVetaAv4 =  MovMeanSmoothData(VetaArray4{tTypeInds(tType)},filtTime,FPSstack2(idx)); %CetaAvs{tTypeInds(tType)};
                    sVetaAvs4{tTypeInds(tType)} = sVetaAv4+100; 
                end
            end 
            % baseline tType data to average value between 0 sec and -baselineInput sec (0 sec being stim
            %onset) 
            if dataParseType == 0 %peristimulus data to plot 
                %sec_before_stim_start       
                if CAQ == 1
                    snCetaArray{tTypeInds(tType)} = ((sCetaAvs{tTypeInds(tType)} ./ nanmean(sCetaAvs{tTypeInds(tType)}(:,floor((sec_before_stim_start-baselineInput)*FPSstack2(idx)):floor(sec_before_stim_start*FPSstack2(idx))),2))*100);    
                    snCetaArray4{tTypeInds(tType)} = ((sCetaAvs4{tTypeInds(tType)} ./ nanmean(sCetaAvs4{tTypeInds(tType)}(:,floor((sec_before_stim_start-baselineInput)*FPSstack2(idx)):floor(sec_before_stim_start*FPSstack2(idx))),2))*100);              
                end 
                if BBBQ == 1 
                    snBetaArray{tTypeInds(tType)} = ((sBetaAvs{tTypeInds(tType)} ./ nanmean(sBetaAvs{tTypeInds(tType)}(:,floor((sec_before_stim_start-baselineInput)*FPSstack2(idx)):floor(sec_before_stim_start*FPSstack2(idx))),2))*100);    
                    snBetaArray4{tTypeInds(tType)} = ((sBetaAvs4{tTypeInds(tType)} ./ nanmean(sBetaAvs4{tTypeInds(tType)}(:,floor((sec_before_stim_start-baselineInput)*FPSstack2(idx)):floor(sec_before_stim_start*FPSstack2(idx))),2))*100);          
                end 
                if VWQ == 1
                    snVetaArray{tTypeInds(tType)} = ((sVetaAvs{tTypeInds(tType)} ./ nanmean(sVetaAvs{tTypeInds(tType)}(:,floor((sec_before_stim_start-baselineInput)*FPSstack2(idx)):floor(sec_before_stim_start*FPSstack2(idx))),2))*100); 
                    snVetaArray4{tTypeInds(tType)} = ((sVetaAvs4{tTypeInds(tType)} ./ nanmean(sVetaAvs4{tTypeInds(tType)}(:,floor((sec_before_stim_start-baselineInput)*FPSstack2(idx)):floor(sec_before_stim_start*FPSstack2(idx))),2))*100);
                end 
            elseif dataParseType == 1 %only stimulus data to plot 
                if CAQ == 1
                    snCetaArray = sCetaAvs; 
                    snCetaArray4 = sCetaAvs4; 
                end 
                if BBBQ == 1 
                    snBetaArray = sBetaAvs;
                    snBetaArray4 = sBetaAvs4;
                end 
                if VWQ == 1
                    snVetaArray = sVetaAvs;
                    snVetaArray4 = sVetaAvs4;
                end 
            end 

            % determine 95% CI and av data 
            if CAQ == 1
                SEMc{tTypeInds(tType)} = (nanstd(snCetaArray{tTypeInds(tType)}))/(sqrt(size(snCetaArray{tTypeInds(tType)},1))); % Standard Error            
                STDc{tTypeInds(tType)} = nanstd(snCetaArray{tTypeInds(tType)});
                ts_cLow = tinv(0.025,size(snCetaArray{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                ts_cHigh = tinv(0.975,size(snCetaArray{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                CI_cLow{tTypeInds(tType)} = (nanmean(snCetaArray{tTypeInds(tType)},1)) + (ts_cLow*SEMc{tTypeInds(tType)});  % Confidence Intervals
                CI_cHigh{tTypeInds(tType)} = (nanmean(snCetaArray{tTypeInds(tType)},1)) + (ts_cHigh*SEMc{tTypeInds(tType)});  % Confidence Intervals
                x = 1:length(CI_cLow{tTypeInds(tType)});
                AVcData{tTypeInds(tType)} = nanmean(snCetaArray{tTypeInds(tType)},1);
    %             % bootstrap the data 
    %             %numBScData = (10000); %size(snCetaArray{tTypeInds(tType)},1)*6;            
    %             for trace = 1:numBScData
    %                 BScData{tTypeInds(tType)}(trace,:) = snCetaArray{tTypeInds(tType)}(randsample(size(snCetaArray{tTypeInds(tType)},1),1),:); 
    %             end 
    %             SEMcbs = (nanstd(BScData{tTypeInds(tType)}))/(sqrt(size(BScData{tTypeInds(tType)},1))); % Standard Error            
    %             STDcbs = nanstd(BScData{tTypeInds(tType)});
    %             ts_cbsLow = tinv(0.025,size(BScData{tTypeInds(tType)},1)-1);% T-Score for 95% CI
    %             ts_cbsHigh = tinv(0.975,size(BScData{tTypeInds(tType)},1)-1);% T-Score for 95% CI
    %             CI_cbsLow{tTypeInds(tType)} = (nanmean(BScData{tTypeInds(tType)},1)) + (ts_cbsLow*SEMcbs);  % Confidence Intervals
    %             CI_cbsHigh{tTypeInds(tType)} = (nanmean(BScData{tTypeInds(tType)},1)) + (ts_cbsHigh*SEMcbs);  % Confidence Intervals
    %             avBScData{tTypeInds(tType)} = nanmean(BScData{tTypeInds(tType)},1); 
                % create shuffled trace            
                [M,N] = size(snCetaArray{tTypeInds(tType)}); % get size of previous arrays            
                rowIndex = repmat((1:M)',[1 N]); % Preserve the row indices           
                [~,randomizedColIndex] = sort(rand(M,N),2); % Get randomized column indices by sorting a second random array           
                newLinearIndex = sub2ind([M,N],rowIndex,randomizedColIndex); % Need to use linear indexing to create B
                shuff_snCetaArray{tTypeInds(tType)} = snCetaArray{tTypeInds(tType)}(newLinearIndex);
                SEMcsh = (nanstd(shuff_snCetaArray{tTypeInds(tType)}))/(sqrt(size(shuff_snCetaArray{tTypeInds(tType)},1))); % Standard Error            
                STDcsh = nanstd(shuff_snCetaArray{tTypeInds(tType)});
                ts_cshLow = tinv(0.025,size(shuff_snCetaArray{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                ts_cshHigh = tinv(0.975,size(shuff_snCetaArray{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                CI_cshLow{tTypeInds(tType)} = (nanmean(shuff_snCetaArray{tTypeInds(tType)},1)) + (ts_cshLow*SEMcsh);  % Confidence Intervals
                CI_cshHigh{tTypeInds(tType)} = (nanmean(shuff_snCetaArray{tTypeInds(tType)},1)) + (ts_cshHigh*SEMcsh);  % Confidence Intervals
                avSHcData{tTypeInds(tType)} = nanmean(shuff_snCetaArray{tTypeInds(tType)},1);        
                % smooth the shuffled trace 
                if smoothQ == 1 
                    avSHcData{tTypeInds(tType)} =  MovMeanSmoothData(avSHcData{tTypeInds(tType)},filtTime,FPSstack2(idx));
                    CI_cshLow{tTypeInds(tType)} =  MovMeanSmoothData(CI_cshLow{tTypeInds(tType)},filtTime,FPSstack2(idx));
                    CI_cshHigh{tTypeInds(tType)} =  MovMeanSmoothData(CI_cshHigh{tTypeInds(tType)},filtTime,FPSstack2(idx));
                end 
    %             % bootstrap the shuffled trace 
    %             for trace = 1:numBScData
    %                 BScshData{tTypeInds(tType)}(trace,:) = shuff_snCetaArray{tTypeInds(tType)}(randsample(size(shuff_snCetaArray{tTypeInds(tType)},1),1),:); 
    %             end             
    %             SEMcsh = (nanstd(BScshData{tTypeInds(tType)}))/(sqrt(size(BScshData{tTypeInds(tType)},1))); % Standard Error            
    %             STDcsh = nanstd(BScshData{tTypeInds(tType)});
    %             ts_cshLow = tinv(0.025,size(BScshData{tTypeInds(tType)},1)-1);% T-Score for 95% CI
    %             ts_cshHigh = tinv(0.975,size(BScshData{tTypeInds(tType)},1)-1);% T-Score for 95% CI
    %             CI_cshLow{tTypeInds(tType)} = (nanmean(BScshData{tTypeInds(tType)},1)) + (ts_cshLow*SEMcsh);  % Confidence Intervals
    %             CI_cshHigh{tTypeInds(tType)} = (nanmean(BScshData{tTypeInds(tType)},1)) + (ts_cshHigh*SEMcsh);  % Confidence Intervals
    %             avSHcData{tTypeInds(tType)} = nanmean(BScshData{tTypeInds(tType)},1); 
            end 
            if BBBQ == 1
                SEMb{tTypeInds(tType)} = (nanstd(snBetaArray{tTypeInds(tType)}))/(sqrt(size(snBetaArray{tTypeInds(tType)},1))); % Standard Error            
                STDb{tTypeInds(tType)} = nanstd(snBetaArray{tTypeInds(tType)});
                ts_bLow = tinv(0.025,size(snBetaArray{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                ts_bHigh = tinv(0.975,size(snBetaArray{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                CI_bLow{tTypeInds(tType)} = (nanmean(snBetaArray{tTypeInds(tType)},1)) + (ts_bLow*SEMb{tTypeInds(tType)});  % Confidence Intervals
                CI_bHigh{tTypeInds(tType)} = (nanmean(snBetaArray{tTypeInds(tType)},1)) + (ts_bHigh*SEMb{tTypeInds(tType)});  % Confidence Intervals
                x = 1:length(CI_bLow{tTypeInds(tType)});
                AVbData{tTypeInds(tType)} = nanmean(snBetaArray{tTypeInds(tType)},1);
    %             %bootstrap the data 
    %             %numBSbData =  (10000); %size(snBetaArray{tTypeInds(tType)},1)*6;            
    %             for trace = 1:numBSbData
    %                 BSbData{tTypeInds(tType)}(trace,:) = snBetaArray{tTypeInds(tType)}(randsample(size(snBetaArray{tTypeInds(tType)},1),1),:); 
    %             end 
    %             SEMbbs = (nanstd(BSbData{tTypeInds(tType)}))/(sqrt(size(BSbData{tTypeInds(tType)},1))); % Standard Error            
    %             STDbbs = nanstd(BSbData{tTypeInds(tType)});
    %             ts_bbsLow = tinv(0.025,size(BSbData{tTypeInds(tType)},1)-1);% T-Score for 95% CI
    %             ts_bbsHigh = tinv(0.975,size(BSbData{tTypeInds(tType)},1)-1);% T-Score for 95% CI
    %             CI_bbsLow{tTypeInds(tType)} = (nanmean(BSbData{tTypeInds(tType)},1)) + (ts_bbsLow*SEMbbs);  % Confidence Intervals
    %             CI_bbsHigh{tTypeInds(tType)} = (nanmean(BSbData{tTypeInds(tType)},1)) + (ts_bbsHigh*SEMbbs);  % Confidence Intervals
    %             avBSbData{tTypeInds(tType)} = nanmean(BSbData{tTypeInds(tType)},1); 
                % create shuffled trace            
                [M,N] = size(snBetaArray{tTypeInds(tType)}); % get size of previous arrays            
                rowIndex = repmat((1:M)',[1 N]); % Preserve the row indices           
                [~,randomizedColIndex] = sort(rand(M,N),2); % Get randomized column indices by sorting a second random array           
                newLinearIndex = sub2ind([M,N],rowIndex,randomizedColIndex); % Need to use linear indexing to create B
                shuff_snBetaArray{tTypeInds(tType)} = snBetaArray{tTypeInds(tType)}(newLinearIndex);
                SEMbsh = (nanstd(shuff_snBetaArray{tTypeInds(tType)}))/(sqrt(size(shuff_snBetaArray{tTypeInds(tType)},1))); % Standard Error            
                STDbsh = nanstd(shuff_snBetaArray{tTypeInds(tType)});
                ts_bshLow = tinv(0.025,size(shuff_snBetaArray{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                ts_bshHigh = tinv(0.975,size(shuff_snBetaArray{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                CI_bshLow{tTypeInds(tType)} = (nanmean(shuff_snBetaArray{tTypeInds(tType)},1)) + (ts_bshLow*SEMbsh);  % Confidence Intervals
                CI_bshHigh{tTypeInds(tType)} = (nanmean(shuff_snBetaArray{tTypeInds(tType)},1)) + (ts_bshHigh*SEMbsh);  % Confidence Intervals
                avSHbData{tTypeInds(tType)} = nanmean(shuff_snBetaArray{tTypeInds(tType)},1);  
                % smooth the shuffled trace 
                if smoothQ == 1 
                    avSHbData{tTypeInds(tType)} =  MovMeanSmoothData(avSHbData{tTypeInds(tType)},filtTime,FPSstack2(idx));
                    CI_bshLow{tTypeInds(tType)} =  MovMeanSmoothData(CI_bshLow{tTypeInds(tType)},filtTime,FPSstack2(idx));
                    CI_bshHigh{tTypeInds(tType)} =  MovMeanSmoothData(CI_bshHigh{tTypeInds(tType)},filtTime,FPSstack2(idx));
                end 
    %             % bootstrap the shuffled trace 
    %             for trace = 1:numBSbData
    %                 BSbshData{tTypeInds(tType)}(trace,:) = shuff_snBetaArray{tTypeInds(tType)}(randsample(size(shuff_snBetaArray{tTypeInds(tType)},1),1),:); 
    %             end                   
    %             SEMbsh = (nanstd(BSbshData{tTypeInds(tType)}))/(sqrt(size(BSbshData{tTypeInds(tType)},1))); % Standard Error            
    %             STDbsh = nanstd(BSbshData{tTypeInds(tType)});
    %             ts_bshLow = tinv(0.025,size(BSbshData{tTypeInds(tType)},1)-1);% T-Score for 95% CI
    %             ts_bshHigh = tinv(0.975,size(BSbshData{tTypeInds(tType)},1)-1);% T-Score for 95% CI
    %             CI_bshLow{tTypeInds(tType)} = (nanmean(BSbshData{tTypeInds(tType)},1)) + (ts_bshLow*SEMbsh);  % Confidence Intervals
    %             CI_bshHigh{tTypeInds(tType)} = (nanmean(BSbshData{tTypeInds(tType)},1)) + (ts_bshHigh*SEMbsh);  % Confidence Intervals
    %             avSHbData{tTypeInds(tType)} = nanmean(BSbshData{tTypeInds(tType)},1); 
            end 
            if VWQ == 1
                SEMv{tTypeInds(tType)} = (nanstd(snVetaArray{tTypeInds(tType)}))/(sqrt(size(snVetaArray{tTypeInds(tType)},1))); % Standard Error            
                STDv{tTypeInds(tType)} = nanstd(snVetaArray{tTypeInds(tType)});
                ts_vLow = tinv(0.025,size(snVetaArray{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                ts_vHigh = tinv(0.975,size(snVetaArray{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                CI_vLow{tTypeInds(tType)} = (nanmean(snVetaArray{tTypeInds(tType)},1)) + (ts_vLow*SEMv{tTypeInds(tType)});  % Confidence Intervals
                CI_vHigh{tTypeInds(tType)} = (nanmean(snVetaArray{tTypeInds(tType)},1)) + (ts_vHigh*SEMv{tTypeInds(tType)});  % Confidence Intervals
                x = 1:length(CI_vLow{tTypeInds(tType)});
                AVvData{tTypeInds(tType)} = nanmean(snVetaArray{tTypeInds(tType)},1);
    %             %bootstrap the data 
    %             %numBSvData = (10000);%size(snVetaArray{tTypeInds(tType)},1)*6;            
    %             for trace = 1:numBSvData
    %                 BSvData{tTypeInds(tType)}(trace,:) = snVetaArray{tTypeInds(tType)}(randsample(size(snVetaArray{tTypeInds(tType)},1),1),:); 
    %             end 
    %             SEMvbs = (nanstd(BSvData{tTypeInds(tType)}))/(sqrt(size(BSvData{tTypeInds(tType)},1))); % Standard Error            
    %             STDvbs = nanstd(BSvData{tTypeInds(tType)});
    %             ts_vbsLow = tinv(0.025,size(BSvData{tTypeInds(tType)},1)-1);% T-Score for 95% CI
    %             ts_vbsHigh = tinv(0.975,size(BSvData{tTypeInds(tType)},1)-1);% T-Score for 95% CI
    %             CI_vbsLow{tTypeInds(tType)} = (nanmean(BSvData{tTypeInds(tType)},1)) + (ts_vbsLow*SEMvbs);  % Confidence Intervals
    %             CI_vbsHigh{tTypeInds(tType)} = (nanmean(BSvData{tTypeInds(tType)},1)) + (ts_vbsHigh*SEMvbs);  % Confidence Intervals
    %             avBSvData{tTypeInds(tType)} = nanmean(BSvData{tTypeInds(tType)},1);   
                % create shuffled trace            
                [M,N] = size(snVetaArray{tTypeInds(tType)}); % get size of previous arrays            
                rowIndex = repmat((1:M)',[1 N]); % Preserve the row indices           
                [~,randomizedColIndex] = sort(rand(M,N),2); % Get randomized column indices by sorting a second random array           
                newLinearIndex = sub2ind([M,N],rowIndex,randomizedColIndex); % Need to use linear indexing to create B
                shuff_snVetaArray{tTypeInds(tType)} = snVetaArray{tTypeInds(tType)}(newLinearIndex);
                SEMvsh = (nanstd(shuff_snVetaArray{tTypeInds(tType)}))/(sqrt(size(shuff_snVetaArray{tTypeInds(tType)},1))); % Standard Error            
                STDvsh = nanstd(shuff_snVetaArray{tTypeInds(tType)});
                ts_vshLow = tinv(0.025,size(shuff_snVetaArray{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                ts_vshHigh = tinv(0.975,size(shuff_snVetaArray{tTypeInds(tType)},1)-1);% T-Score for 95% CI
                CI_vshLow{tTypeInds(tType)} = (nanmean(shuff_snVetaArray{tTypeInds(tType)},1)) + (ts_vshLow*SEMvsh);  % Confidence Intervals
                CI_vshHigh{tTypeInds(tType)} = (nanmean(shuff_snVetaArray{tTypeInds(tType)},1)) + (ts_vshHigh*SEMvsh);  % Confidence Intervals
                avSHvData{tTypeInds(tType)} = nanmean(shuff_snVetaArray{tTypeInds(tType)},1); 
                % smooth the shuffled trace 
                if smoothQ == 1 
                    avSHvData{tTypeInds(tType)} =  MovMeanSmoothData(avSHvData{tTypeInds(tType)},filtTime,FPSstack2(idx));
                    CI_vshLow{tTypeInds(tType)} =  MovMeanSmoothData(CI_vshLow{tTypeInds(tType)},filtTime,FPSstack2(idx));
                    CI_vshHigh{tTypeInds(tType)} =  MovMeanSmoothData(CI_vshHigh{tTypeInds(tType)},filtTime,FPSstack2(idx));
                end 
    %             % bootstrap the shuffled trace 
    %             for trace = 1:numBSvData
    %                 BSvshData{tTypeInds(tType)}(trace,:) = shuff_snVetaArray{tTypeInds(tType)}(randsample(size(shuff_snVetaArray{tTypeInds(tType)},1),1),:); 
    %             end                  
    %             SEMvsh = (nanstd(BSvshData{tTypeInds(tType)}))/(sqrt(size(BSvshData{tTypeInds(tType)},1))); % Standard Error            
    %             STDvsh = nanstd(BSvshData{tTypeInds(tType)});
    %             ts_vshLow = tinv(0.025,size(BSvshData{tTypeInds(tType)},1)-1);% T-Score for 95% CI
    %             ts_vshHigh = tinv(0.975,size(BSvshData{tTypeInds(tType)},1)-1);% T-Score for 95% CI
    %             CI_vshLow{tTypeInds(tType)} = (nanmean(BSvshData{tTypeInds(tType)},1)) + (ts_vshLow*SEMvsh);  % Confidence Intervals
    %             CI_vshHigh{tTypeInds(tType)} = (nanmean(BSvshData{tTypeInds(tType)},1)) + (ts_vshHigh*SEMvsh);  % Confidence Intervals
    %             avSHvData{tTypeInds(tType)} = nanmean(BSvshData{tTypeInds(tType)},1);                       
            end 
            % plot Ca data 
            if CAQ == 1 
                fig = figure;             
                hold all;
                Frames = size(AVbData{tTypeInds(tType)},2);        
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                if plotAVQ == 1
%                     plot(avSHcData{tTypeInds(tType)}-100,'color',[0.5 0.5 0.5],'LineWidth',3)      
%                     patch([x fliplr(x)],[CI_cshLow{tTypeInds(tType)}-100 fliplr(CI_cshHigh{tTypeInds(tType)}-100)],[0.5 0.5 0.5],'EdgeColor','none')
%                     AVcData1_40 = AVcData; CI_cLow1_40 = CI_cLow; CI_cHigh1_40 = CI_cHigh;
%                     plot(AVcData1_40{tTypeInds(tType)}-100,'b','LineWidth',3)
%                     patch([x fliplr(x)],[CI_cLow1_40{tTypeInds(tType)}-100 fliplr(CI_cHigh1_40{tTypeInds(tType)}-100)],[0 0 0.5],'EdgeColor','none')
                    plot(AVcData{tTypeInds(tType)}-100,'b','LineWidth',3)
                    patch([x fliplr(x)],[CI_cLow{tTypeInds(tType)}-100 fliplr(CI_cHigh{tTypeInds(tType)}-100)],[0 0 0.5],'EdgeColor','none')
                elseif plotAVQ == 0 
    %                 colorMap = jet(size(CetaArray4{tTypeInds(tType)},1));
%                     colorMap = [zeros(size(CetaArray4{tTypeInds(tType)},1),1),linspace(0,1,size(CetaArray4{tTypeInds(tType)},1))',linspace(0,1,size(CetaArray4{tTypeInds(tType)},1))']; % from black to light blue 
                    colorMap = [linspace(0,0.7,size(CetaArray4{tTypeInds(tType)},1))',linspace(0,0.7,size(CetaArray4{tTypeInds(tType)},1))',linspace(1,1,size(CetaArray4{tTypeInds(tType)},1))']; % from dark blue to light blue
                    for trace = 1:size(CetaArray4{tTypeInds(tType)},1)
                        plot(snCetaArray4{tTypeInds(tType)}(trace,:)-100,'color',colorMap(trace,:),'LineWidth',2);
                    end 
                end 
                if tTypeInds(tType) == 1 
                    if optoQ == 0
                        label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'CS+'},'LineWidth',2);
                        label1.FontSize = 30;
                        label1.FontName = 'Arial';
                        label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack2(idx)))*2),'-k',{'Reward'},'LineWidth',2);
                        label2.FontSize = 30;
                        label3 = ('Behavior Data');
                    elseif optoQ == 1 
                        plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000000 5000000], 'k','LineWidth',2)
                        plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
                        label3 = ('2 sec Blue Light');
                    end 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx):Frames_post_stim_start)/FPSstack2(idx))+1);
                    FrameVals = floor((1:FPSstack2(idx):Frames)-1);            
                elseif tTypeInds(tType) == 3 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*2)) round(baselineEndFrame+((FPSstack2(idx))*2))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+1);
                    FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
                    label3 = ('2 sec Red Light');
                elseif tTypeInds(tType) == 2 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+10);
                    FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
                    label3 = ('20 sec Blue Light');
                elseif tTypeInds(tType) == 4 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+10);
                    FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
                    label3 = ('20 sec Red Light');
                end
                ax=gca;
                ax.XTick = FrameVals;
                ax.XTickLabel = sec_TimeVals;
                ax.FontSize = 30;
                ax.FontName = 'Arial';
%                 xlim([1 length(AVcData{tTypeInds(tType)})])
%                 ylim([min(AVcData{tTypeInds(tType)}-400) max(AVcData{tTypeInds(tType)})+300])
                xlim([(sec_before_stim_start-0.9)*FPSstack{idx} (sec_before_stim_start+6)*FPSstack{idx}])
                ylim([-2.7 3])
                xlabel('time (s)')
                ylabel('calcium percent change')
                % initialize empty string array 
                label = strings;
                label = append(label,sprintf('  Calcium Signal. N = %d.',mouseNum));        
%                 if optoQ == 1 % opto data 
%                     title({'Optogenetic Stimulation Event Triggered Averages';label;label3},'FontName','Arial');
%                 end 
%                 if optoQ == 0 % behavior data 
%                     title({'Behavior Event Triggered Averages';label;label3},'FontName','Arial');
%                 end 
                set(fig,'position', [100 100 900 900])
                alpha(0.3)        

    %             % plot bootstrapped data with shuffled baseline 
    %             fig = figure;             
    %             hold all;
    %             Frames = size(AVbData{tTypeInds(tType)},2);        
    %             Frames_pre_stim_start = -((Frames-1)/2); 
    %             Frames_post_stim_start = (Frames-1)/2; 
    %             plot(avSHcData{tTypeInds(tType)}-100,'color',[0.5 0.5 0.5],'LineWidth',3)      
    %             patch([x fliplr(x)],[CI_cshLow{tTypeInds(tType)}-100 fliplr(CI_cshHigh{tTypeInds(tType)}-100)],[0.5 0.5 0.5],'EdgeColor','none')
    %             plot(avBScData{tTypeInds(tType)}-100,'b','LineWidth',3)
    %             patch([x fliplr(x)],[CI_cbsLow{tTypeInds(tType)}-100 fliplr(CI_cbsHigh{tTypeInds(tType)}-100)],[0 0 0.5],'EdgeColor','none')
    %             if tTypeInds(tType) == 1 
    %                 if optoQ == 0
    %                     label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
    %                     label1.FontSize = 30;
    %                     label1.FontName = 'Arial';
    %                     label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack2(idx)))*2),'-k',{'water reward'},'LineWidth',2);
    %                     label2.FontSize = 30;
    %                     label3 = ('Behavior Data');
    %                 elseif optoQ == 1 
    %                     plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000000 5000000], 'k','LineWidth',2)
    %                     plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
    %                     label3 = ('2 sec Blue Light');
    %                 end 
    %                 sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx):Frames_post_stim_start)/FPSstack2(idx))+1);
    %                 FrameVals = floor((1:FPSstack2(idx):Frames)-1);            
    %             elseif tTypeInds(tType) == 3 
    %                 plot([round(baselineEndFrame+((FPSstack2(idx))*2)) round(baselineEndFrame+((FPSstack2(idx))*2))], [-5000000 5000000], 'k','LineWidth',2)
    %                 plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
    %                 sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+1);
    %                 FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
    %                 label3 = ('2 sec Red Light');
    %             elseif tTypeInds(tType) == 2 
    %                 plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
    %                 plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
    %                 sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+10);
    %                 FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
    %                 label3 = ('20 sec Blue Light');
    %             elseif tTypeInds(tType) == 4 
    %                 plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
    %                 plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
    %                 sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+10);
    %                 FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
    %                 label3 = ('20 sec Red Light');
    %             end
    %             ax=gca;
    %             ax.XTick = FrameVals;
    %             ax.XTickLabel = sec_TimeVals;
    %             ax.FontSize = 30;
    %             ax.FontName = 'Arial';
    %             xlim([1 length(AVcData{tTypeInds(tType)})])
    %             ylim([min(AVcData{tTypeInds(tType)}-400) max(AVcData{tTypeInds(tType)})+300])
    %             xlabel('time (s)')
    %             ylabel('calcium percent change')
    %             % initialize empty string array 
    %             label = strings;
    %             label = append(label,sprintf('  Calcium Signal. N = %d.',mouseNum));        
    %     %         title({'Optogenetic Stimulation';'Event Triggered Averages (n = 3)';label},'FontName','Arial');
    %             if optoQ == 1 % opto data 
    %                 title({'Optogenetic Stimulation Event Triggered Averages';label;label3;'Bootstrapped Data with Shuffled Baseline'},'FontName','Arial');
    %             end 
    %             if optoQ == 0 % behavior data 
    %                 title({'Behavior Event Triggered Averages';label;label3;'Bootstrapped Data with Shuffled Baseline'},'FontName','Arial');
    %             end 
    %             set(fig,'position', [100 100 900 900])
    %             alpha(0.3)                        
            end 

            %plot BBB data 
            if BBBQ == 1 
                fig = figure;             
                hold all;
                Frames = size(AVbData{tTypeInds(tType)},2);        
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                if plotAVQ == 1
%                     plot(avSHbData{tTypeInds(tType)}-104,'color',[0.5 0.5 0.5],'LineWidth',3)        
%                     patch([x fliplr(x)],[CI_bshLow{tTypeInds(tType)}-104 fliplr(CI_bshHigh{tTypeInds(tType)}-104)],[0.5 0.5 0.5],'EdgeColor','none') 
%                     AVbData1_40 = AVbData; CI_bLow1_40 = CI_bLow; CI_bHigh1_40 = CI_bHigh;
%                     plot(AVbData1_40{tTypeInds(tType)}-100,'Color',[0.7 0.5 0.5],'LineWidth',3)
%                     patch([x fliplr(x)],[CI_bLow1_40{tTypeInds(tType)}-100 fliplr(CI_bHigh1_40{tTypeInds(tType)}-100)],[0.7 0.5 0.5],'EdgeColor','none')
                    plot(AVbData{tTypeInds(tType)}-100,'r','LineWidth',3)
                    patch([x fliplr(x)],[CI_bLow{tTypeInds(tType)}-100 fliplr(CI_bHigh{tTypeInds(tType)}-100)],[0.5 0 0],'EdgeColor','none')
                elseif plotAVQ == 0
    %                 colorMap = [linspace(0,1,size(BetaArray4{tTypeInds(tType)},1))', zeros(size(BetaArray4{tTypeInds(tType)},1),2)]; % black to red 
%                     colorMap = [linspace(0,1,size(BetaArray4{tTypeInds(tType)},1))', linspace(0,0.5,size(BetaArray4{tTypeInds(tType)},1))',linspace(0,0.5,size(BetaArray4{tTypeInds(tType)},1))']; % black to light red 
                    colorMap = [linspace(1,1,size(BetaArray4{tTypeInds(tType)},1))', linspace(0,0.6,size(BetaArray4{tTypeInds(tType)},1))',linspace(0,0.6,size(BetaArray4{tTypeInds(tType)},1))']; % dark red to light red 
  %                 colorMap = jet(size(CetaArray4{tTypeInds(tType)},1));
                    for trace = 1:size(BetaArray4{tTypeInds(tType)},1)
                        plot(snBetaArray4{tTypeInds(tType)}(trace,:)-100,'color',colorMap(trace,:),'LineWidth',2);
                    end                 
                end 
                if tTypeInds(tType) == 1 
                    if optoQ == 0
                        label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'CS+'},'LineWidth',2);
                        label1.FontSize = 30;
                        label1.FontName = 'Arial';
                        label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack2(idx)))*2),'-k',{'Reward'},'LineWidth',2);
                        label2.FontSize = 30;
                        label3 = ('Behavior Data');
                    elseif optoQ == 1 
                        plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000000 5000000], 'k','LineWidth',2)
                        plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
                        label3 = ('2 sec Blue Light');
                    end 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx):Frames_post_stim_start)/FPSstack2(idx))+1);
                    FrameVals = floor((1:FPSstack2(idx):Frames)-1);            
                elseif tTypeInds(tType) == 3 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*2)) round(baselineEndFrame+((FPSstack2(idx))*2))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+1);
                    FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
                    label3 = ('2 sec Red Light');
                elseif tTypeInds(tType) == 2 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+10);
                    FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
                    label3 = ('20 sec Blue Light');
                elseif tTypeInds(tType) == 4 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*1:Frames_post_stim_start)/FPSstack2(idx))+10);
                    FrameVals = floor((1:FPSstack2(idx)*1:Frames)-1); 
                    label3 = ('20 sec Red Light');
                end
                ax=gca;
                ax.XTick = FrameVals;
                ax.XTickLabel = sec_TimeVals;
                ax.FontSize = 30;
                ax.FontName = 'Arial';
%                 xlim([1 length(AVbData{tTypeInds(tType)})])
%                 ylim([min(AVbData{tTypeInds(tType)}-400) max(AVbData{tTypeInds(tType)})+300])
                xlim([(sec_before_stim_start-0.9)*FPSstack{idx} (sec_before_stim_start+6)*FPSstack{idx}])
                ylim([-10 30])
                xlabel('time (s)')
                ylabel('BBB percent change')
                % initialize empty string array 
                label = strings;
                label = append(label,sprintf('BBB Permeabilty. N = %d.',mouseNum));       
%                 if optoQ == 1 % opto data 
%                     title({'Optogenetic Stimulation Event Triggered Averages';label;label3},'FontName','Arial');
%                 end 
%                 if optoQ == 0 % behavior data 
%                     title({'Behavior Event Triggered Averages';label;label3},'FontName','Arial');
%                 end 
                set(fig,'position', [100 100 900 900])
                alpha(0.3)   

    %             % plot bootstrapped and shuffled baseline data 
    %             fig = figure;             
    %             hold all;
    %             Frames = size(AVbData{tTypeInds(tType)},2);        
    %             Frames_pre_stim_start = -((Frames-1)/2); 
    %             Frames_post_stim_start = (Frames-1)/2; 
    %             plot(avSHbData{tTypeInds(tType)}-100,'color',[0.5 0.5 0.5],'LineWidth',3)        
    %             patch([x fliplr(x)],[CI_bshLow{tTypeInds(tType)}-100 fliplr(CI_bshHigh{tTypeInds(tType)}-100)],[0.5 0.5 0.5],'EdgeColor','none')            
    %             plot(avBSbData{tTypeInds(tType)}-100,'r','LineWidth',3)
    %             patch([x fliplr(x)],[CI_bbsLow{tTypeInds(tType)}-100 fliplr(CI_bbsHigh{tTypeInds(tType)}-100)],[0.5 0 0],'EdgeColor','none')
    %             if tTypeInds(tType) == 1 
    %                 if optoQ == 0
    %                     label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
    %                     label1.FontSize = 30;
    %                     label1.FontName = 'Arial';
    %                     label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack2(idx)))*2),'-k',{'water reward'},'LineWidth',2);
    %                     label2.FontSize = 30;
    %                     label3 = ('Behavior Data');
    %                 elseif optoQ == 1 
    %                     plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000000 5000000], 'k','LineWidth',2)
    %                     plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
    %                     label3 = ('2 sec Blue Light');
    %                 end 
    %                 sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx):Frames_post_stim_start)/FPSstack2(idx))+1);
    %                 FrameVals = floor((1:FPSstack2(idx):Frames)-1);            
    %             elseif tTypeInds(tType) == 3 
    %                 plot([round(baselineEndFrame+((FPSstack2(idx))*2)) round(baselineEndFrame+((FPSstack2(idx))*2))], [-5000000 5000000], 'k','LineWidth',2)
    %                 plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
    %                 sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+1);
    %                 FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
    %                 label3 = ('2 sec Red Light');
    %             elseif tTypeInds(tType) == 2 
    %                 plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
    %                 plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
    %                 sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+10);
    %                 FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
    %                 label3 = ('20 sec Blue Light');
    %             elseif tTypeInds(tType) == 4 
    %                 plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
    %                 plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
    %                 sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*1:Frames_post_stim_start)/FPSstack2(idx))+10);
    %                 FrameVals = floor((1:FPSstack2(idx)*1:Frames)-1); 
    %                 label3 = ('20 sec Red Light');
    %             end
    %             ax=gca;
    %             ax.XTick = FrameVals;
    %             ax.XTickLabel = sec_TimeVals;
    %             ax.FontSize = 30;
    %             ax.FontName = 'Arial';
    %             xlim([1 length(AVbData{tTypeInds(tType)})])
    %             ylim([min(AVbData{tTypeInds(tType)}-400) max(AVbData{tTypeInds(tType)})+300])
    %             xlabel('time (s)')
    %             ylabel('BBB percent change')
    %             % initialize empty string array 
    %             label = strings;
    %             label = append(label,sprintf('BBB Permeabilty. N = %d.',mouseNum));       
    %     %         title({'Optogenetic Stimulation';'Event Triggered Averages (n = 3)';label},'FontName','Arial');
    %             if optoQ == 1 % opto data 
    %                 title({'Optogenetic Stimulation Event Triggered Averages';label;label3;'Bootstrapped Data with Shuffled Baseline'},'FontName','Arial');
    %             end 
    %             if optoQ == 0 % behavior data 
    %                 title({'Behavior Event Triggered Averages';label;label3;'Bootstrapped Data with Shuffled Baseline'},'FontName','Arial');
    %             end 
    %             set(fig,'position', [100 100 900 900])
    %             alpha(0.3)                             
            end 

            %plot VW data 
            if VWQ == 1
                fig = figure;             
                hold all;
                Frames = size(AVvData{tTypeInds(tType)},2);        
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2;  
                if plotAVQ == 1
%                     plot(avSHvData{tTypeInds(tType)}-100.1,'color',[0.5 0.5 0.5],'LineWidth',3)        
%                     patch([x fliplr(x)],[CI_vshLow{tTypeInds(tType)}-100.1 fliplr(CI_vshHigh{tTypeInds(tType)}-100.1)],[0.5 0.5 0.5],'EdgeColor','none') 
%                     AVvData1_40 = AVvData; CI_vLow1_40 = CI_vLow; CI_vHigh1_40 = CI_vHigh;
%                     plot(AVvData1_40{tTypeInds(tType)}-100,'Color',[0.5 0.5 0.5],'LineWidth',3)
%                     patch([x fliplr(x)],[CI_vLow1_40{tTypeInds(tType)}-100 fliplr(CI_vHigh1_40{tTypeInds(tType)}-100)],[0.5 0.5 0.5],'EdgeColor','none')  
                    plot(AVvData{tTypeInds(tType)}-100,'k','LineWidth',3)
                    patch([x fliplr(x)],[CI_vLow{tTypeInds(tType)}-100 fliplr(CI_vHigh{tTypeInds(tType)}-100)],'k','EdgeColor','none')
                elseif plotAVQ == 0
%                     colorMap = [linspace(0,0.8,size(VetaArray4{tTypeInds(tType)},1))',linspace(0,0.8,size(VetaArray4{tTypeInds(tType)},1))',linspace(0,0.8,size(VetaArray4{tTypeInds(tType)},1))']; %black to gray
    %                 colorMap = jet(size(CetaArray4{tTypeInds(tType)},1)); 
                    colorMap = [linspace(0,0.6,size(CetaArray4{tTypeInds(tType)},1))',linspace(0,0.6,size(CetaArray4{tTypeInds(tType)},1))',linspace(0,0.6,size(CetaArray4{tTypeInds(tType)},1))']; %black to slightly darker gray
                    for trace = 1:size(VetaArray4{tTypeInds(tType)},1)
                        plot(snVetaArray4{tTypeInds(tType)}(trace,:)-100,'color',colorMap(trace,:),'LineWidth',2);
                    end 
                end     
                if tTypeInds(tType) == 1 
                    if optoQ == 0
                        label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'CS+'},'LineWidth',2);
                        label1.FontSize = 30;
                        label1.FontName = 'Arial';
                        label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack2(idx)))*2),'-k',{'Reward'},'LineWidth',2);
                        label2.FontSize = 30;
                        label3 = ('Behavior Data');
                    elseif optoQ == 1 
                        plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000000 5000000], 'k','LineWidth',2)
                        plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
                        label3 = ('2 sec Blue Light');
                    end 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx):Frames_post_stim_start)/FPSstack2(idx))+1);
                    FrameVals = floor((1:FPSstack2(idx):Frames)-1);            
                elseif tTypeInds(tType) == 3 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*2)) round(baselineEndFrame+((FPSstack2(idx))*2))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+1);
                    FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
                    label3 = ('2 sec Red Light');
                elseif tTypeInds(tType) == 2 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+10);
                    FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
                    label3 = ('20 sec Blue Light');
                elseif tTypeInds(tType) == 4 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+10);
                    FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
                    label3 = ('20 sec Red Light');
                end
                ax=gca;
                ax.XTick = FrameVals;
                ax.XTickLabel = sec_TimeVals;
                ax.FontSize = 30;
                ax.FontName = 'Arial';
%                 xlim([1 length(AVvData{tTypeInds(tType)})])
%                 ylim([min(AVvData{tTypeInds(tType)}-400) max(AVvData{tTypeInds(tType)})+300])
                xlim([(sec_before_stim_start-0.9)*FPSstack{idx} (sec_before_stim_start+6)*FPSstack{idx}])
                ylim([-0.3 0.6])
                xlabel('time (s)')
                ylabel('vessel width percent change')
                % initialize empty string array 
                label = strings;
                label = append(label,sprintf('Vessel width ROIs averaged. N = %d.',mouseNum));
%                 if optoQ == 1 % opto data 
%                     title({'Optogenetic Stimulation Event Triggered Averages';label;label3},'FontName','Arial');
%                 end 
%                 if optoQ == 0 % behavior data 
%                     title({'Behavior Event Triggered Averages';label;label3},'FontName','Arial');
%                 end 
                set(fig,'position', [100 100 900 900])
                alpha(0.3)   

    %         % plot bootstrapped and shuffeld baseline data 
    %             fig = figure;             
    %             hold all;
    %             Frames = size(AVvData{tTypeInds(tType)},2);        
    %             Frames_pre_stim_start = -((Frames-1)/2); 
    %             Frames_post_stim_start = (Frames-1)/2;   
    %             plot(avSHvData{tTypeInds(tType)}-100,'color',[0.5 0.5 0.5],'LineWidth',3)        
    %             patch([x fliplr(x)],[CI_vshLow{tTypeInds(tType)}-100 fliplr(CI_vshHigh{tTypeInds(tType)}-100)],[0.5 0.5 0.5],'EdgeColor','none')              
    %             plot(avBSvData{tTypeInds(tType)}-100,'k','LineWidth',3)
    %             patch([x fliplr(x)],[CI_vbsLow{tTypeInds(tType)}-100 fliplr(CI_vbsHigh{tTypeInds(tType)}-100)],'k','EdgeColor','none')            
    %             if tTypeInds(tType) == 1 
    %                 if optoQ == 0
    %                     label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
    %                     label1.FontSize = 30;
    %                     label1.FontName = 'Arial';
    %                     label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack2(idx)))*2),'-k',{'water reward'},'LineWidth',2);
    %                     label2.FontSize = 30;
    %                     label3 = ('Behavior Data');
    %                 elseif optoQ == 1 
    %                     plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000000 5000000], 'k','LineWidth',2)
    %                     plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
    %                     label3 = ('2 sec Blue Light');
    %                 end 
    %                 sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx):Frames_post_stim_start)/FPSstack2(idx))+1);
    %                 FrameVals = floor((1:FPSstack2(idx):Frames)-1);            
    %             elseif tTypeInds(tType) == 3 
    %                 plot([round(baselineEndFrame+((FPSstack2(idx))*2)) round(baselineEndFrame+((FPSstack2(idx))*2))], [-5000000 5000000], 'k','LineWidth',2)
    %                 plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
    %                 sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+1);
    %                 FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
    %                 label3 = ('2 sec Red Light');
    %             elseif tTypeInds(tType) == 2 
    %                 plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
    %                 plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
    %                 sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+10);
    %                 FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
    %                 label3 = ('20 sec Blue Light');
    %             elseif tTypeInds(tType) == 4 
    %                 plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
    %                 plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
    %                 sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+10);
    %                 FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
    %                 label3 = ('20 sec Red Light');
    %             end
    %             ax=gca;
    %             ax.XTick = FrameVals;
    %             ax.XTickLabel = sec_TimeVals;
    %             ax.FontSize = 30;
    %             ax.FontName = 'Arial';
    %             xlim([1 length(AVvData{tTypeInds(tType)})])
    %             ylim([min(AVvData{tTypeInds(tType)}-400) max(AVvData{tTypeInds(tType)})+300])
    %             xlabel('time (s)')
    %             ylabel('vessel width percent change')
    %             % initialize empty string array 
    %             label = strings;
    %             label = append(label,sprintf('Vessel width ROIs averaged. N = %d.',mouseNum));
    %             if optoQ == 1 % opto data 
    %                 title({'Optogenetic Stimulation Event Triggered Averages';label;label3;'Bootstrapped Data with Shuffled Baseline'},'FontName','Arial');
    %             end 
    %             if optoQ == 0 % behavior data 
    %                 title({'Behavior Event Triggered Averages';label;label3;'Bootstrapped Data with Shuffled Baseline'},'FontName','Arial');
    %             end 
    %             set(fig,'position', [100 100 900 900])
    %             alpha(0.3)                             
            end 
        end 
        if trialAVQ == 1 && trialAVQ2 == 1  
            for group = 1:numGroups2{1}
                %smooth tType data 
                if smoothQ == 0 
                    if CAQ == 1
                        sCetaAvs{tTypeInds(tType)}{group} = CetaArray{tTypeInds(tType)}{group}+1000;
                        sCetaAvs4{tTypeInds(tType)}{group} = CetaArray4{tTypeInds(tType)}{group}+1000;
                    end 
                    if BBBQ == 1
                        sBetaAvs{tTypeInds(tType)}{group} = BetaArray{tTypeInds(tType)}{group}+100;
                        sBetaAvs4{tTypeInds(tType)}{group} = BetaArray4{tTypeInds(tType)}{group}+100;
                    end
                    if VWQ == 1
                        sVetaAvs{tTypeInds(tType)}{group} = VetaArray{tTypeInds(tType)}{group}+100;
                        sVetaAvs4{tTypeInds(tType)}{group} = VetaArray4{tTypeInds(tType)}{group}+100;
                    end
                elseif smoothQ == 1 
                    if CAQ == 1
                        sCetaAv =  MovMeanSmoothData(CetaArray{tTypeInds(tType)}{group},filtTime,FPSstack2(idx)); %CetaAvs{tTypeInds(tType)};
                        sCetaAvs{tTypeInds(tType)}{group} = sCetaAv+100; 
                        sCetaAv4 =  MovMeanSmoothData(CetaArray4{tTypeInds(tType)}{group},filtTime,FPSstack2(idx)); %CetaAvs{tTypeInds(tType)};
                        sCetaAvs4{tTypeInds(tType)}{group} = sCetaAv4+100; 
                    end 
                    if BBBQ == 1
                        sBetaAv =  MovMeanSmoothData(BetaArray{tTypeInds(tType)}{group},filtTime,FPSstack2(idx)); %CetaAvs{tTypeInds(tType)};
                        sBetaAvs{tTypeInds(tType)}{group} = sBetaAv+100; 
                        sBetaAv4 =  MovMeanSmoothData(BetaArray4{tTypeInds(tType)}{group},filtTime,FPSstack2(idx)); %CetaAvs{tTypeInds(tType)};
                        sBetaAvs4{tTypeInds(tType)}{group} = sBetaAv4+100; 
                    end 
                    if VWQ == 1
                        sVetaAv =  MovMeanSmoothData(VetaArray{tTypeInds(tType)}{group},filtTime,FPSstack2(idx)); %CetaAvs{tTypeInds(tType)};
                        sVetaAvs{tTypeInds(tType)}{group} = sVetaAv+100; 
                        sVetaAv4 =  MovMeanSmoothData(VetaArray4{tTypeInds(tType)}{group},filtTime,FPSstack2(idx)); %CetaAvs{tTypeInds(tType)};
                        sVetaAvs4{tTypeInds(tType)}{group} = sVetaAv4+100; 
                    end
                end 
                % baseline tType data to average value between 0 sec and -baselineInput sec (0 sec being stim
                %onset) 
                if dataParseType == 0 %peristimulus data to plot 
                    %sec_before_stim_start       
                    if CAQ == 1
                        snCetaArray{tTypeInds(tType)}{group} = ((sCetaAvs{tTypeInds(tType)}{group} ./ nanmean(sCetaAvs{tTypeInds(tType)}{group}(:,floor((sec_before_stim_start-baselineInput)*FPSstack2(idx)):floor(sec_before_stim_start*FPSstack2(idx))),2))*100);    
                        snCetaArray4{tTypeInds(tType)}{group} = ((sCetaAvs4{tTypeInds(tType)}{group} ./ nanmean(sCetaAvs4{tTypeInds(tType)}{group}(:,floor((sec_before_stim_start-baselineInput)*FPSstack2(idx)):floor(sec_before_stim_start*FPSstack2(idx))),2))*100);              
                    end 
                    if BBBQ == 1 
                        snBetaArray{tTypeInds(tType)}{group} = ((sBetaAvs{tTypeInds(tType)}{group} ./ nanmean(sBetaAvs{tTypeInds(tType)}{group}(:,floor((sec_before_stim_start-baselineInput)*FPSstack2(idx)):floor(sec_before_stim_start*FPSstack2(idx))),2))*100);    
                        snBetaArray4{tTypeInds(tType)}{group} = ((sBetaAvs4{tTypeInds(tType)}{group} ./ nanmean(sBetaAvs4{tTypeInds(tType)}{group}(:,floor((sec_before_stim_start-baselineInput)*FPSstack2(idx)):floor(sec_before_stim_start*FPSstack2(idx))),2))*100);          
                    end 
                    if VWQ == 1
                        snVetaArray{tTypeInds(tType)}{group} = ((sVetaAvs{tTypeInds(tType)}{group} ./ nanmean(sVetaAvs{tTypeInds(tType)}{group}(:,floor((sec_before_stim_start-baselineInput)*FPSstack2(idx)):floor(sec_before_stim_start*FPSstack2(idx))),2))*100); 
                        snVetaArray4{tTypeInds(tType)}{group} = ((sVetaAvs4{tTypeInds(tType)}{group} ./ nanmean(sVetaAvs4{tTypeInds(tType)}{group}(:,floor((sec_before_stim_start-baselineInput)*FPSstack2(idx)):floor(sec_before_stim_start*FPSstack2(idx))),2))*100);
                    end 
                elseif dataParseType == 1 %only stimulus data to plot 
                    if CAQ == 1
                        snCetaArray = sCetaAvs; 
                        snCetaArray4 = sCetaAvs4; 
                    end 
                    if BBBQ == 1 
                        snBetaArray = sBetaAvs;
                        snBetaArray4 = sBetaAvs4;
                    end 
                    if VWQ == 1
                        snVetaArray = sVetaAvs;
                        snVetaArray4 = sVetaAvs4;
                    end 
                end 
            end 
        end  
    end 
end 

snCetaArray5 = cell(1,tTypeNum);
snBetaArray5 = cell(1,tTypeNum);
snVetaArray5 = cell(1,tTypeNum);
for tType = 1:tTypeNum
    if isempty(CetaArray{tTypeInds(tType)}) == 0
        if trialAVQ == 1 && trialAVQ2 == 1              
            % plot Ca data 
            if CAQ == 1 
                fig = figure;             
                hold all;
                Frames = size(CetaArray4{tTypeInds(tType)}{1},2);        
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
%                 colorMap = jet(size(CetaArray4{tTypeInds(tType)},1));
                for group = 1:numGroups2{1}                    
                    snCetaArray5{tTypeInds(tType)}(group,:) = nanmean(snCetaArray4{tTypeInds(tType)}{group},1);                                                          
                end 
%                 colorMap = [zeros(size(snCetaArray5{tTypeInds(tType)},1),1),linspace(0,1,size(snCetaArray5{tTypeInds(tType)},1))',linspace(0,1,size(snCetaArray5{tTypeInds(tType)},1))']; % from black to light blue 
                colorMap = [linspace(0,0.7,size(snCetaArray5{tTypeInds(tType)},1))',linspace(0,0.7,size(snCetaArray5{tTypeInds(tType)},1))',linspace(1,1,size(snCetaArray5{tTypeInds(tType)},1))']; % from dark blue to light blue 
                for trace = 1:size(snCetaArray5{tTypeInds(tType)},1)
                    plot(snCetaArray5{tTypeInds(tType)}(trace,:)-100,'color',colorMap(trace,:),'LineWidth',2);
                end                                
                if tTypeInds(tType) == 1 
                    if optoQ == 0
                        label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
                        label1.FontSize = 30;
                        label1.FontName = 'Arial';
                        label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack2(idx)))*2),'-k',{'water reward'},'LineWidth',2);
                        label2.FontSize = 30;
                        label3 = ('Behavior Data');
                    elseif optoQ == 1 
                        plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000000 5000000], 'k','LineWidth',2)
                        plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
                        label3 = ('2 sec Blue Light');
                    end 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx):Frames_post_stim_start)/FPSstack2(idx))+1);
                    FrameVals = floor((1:FPSstack2(idx):Frames)-1);            
                elseif tTypeInds(tType) == 3 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*2)) round(baselineEndFrame+((FPSstack2(idx))*2))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+1);
                    FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
                    label3 = ('2 sec Red Light');
                elseif tTypeInds(tType) == 2 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+10);
                    FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
                    label3 = ('20 sec Blue Light');
                elseif tTypeInds(tType) == 4 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+10);
                    FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
                    label3 = ('20 sec Red Light');
                end
                ax=gca;
                ax.XTick = FrameVals;
                ax.XTickLabel = sec_TimeVals;
                ax.FontSize = 30;
                ax.FontName = 'Arial';
                xlim([1 length(snCetaArray5{tTypeInds(tType)})])
                ylim([min(min(snCetaArray5{tTypeInds(tType)}-400)) max(max(snCetaArray5{tTypeInds(tType)}))+300])
                xlabel('time (s)')
                ylabel('calcium percent change')
                % initialize empty string array 
                label = strings;
                label = append(label,sprintf('  Calcium Signal. N = %d.',mouseNum));        
        %         title({'Optogenetic Stimulation';'Event Triggered Averages (n = 3)';label},'FontName','Arial');
                if optoQ == 1 % opto data 
                    title({'Optogenetic Stimulation Event Triggered Averages';label;label3},'FontName','Arial');
                end 
                if optoQ == 0 % behavior data 
                    title({'Behavior Event Triggered Averages';label;label3},'FontName','Arial');
                end 
                set(fig,'position', [100 100 900 900])
                alpha(0.3)                                
            end 

            %plot BBB data 
            if BBBQ == 1 
                fig = figure;             
                hold all;
                Frames = size(snBetaArray4{tTypeInds(tType)}{1},2);        
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                for group = 1:numGroups2{1}                    
                    snBetaArray5{tTypeInds(tType)}(group,:) = nanmean(snBetaArray4{tTypeInds(tType)}{group},1);                                                          
                end                 
%                 colorMap = [linspace(0,1,size(snBetaArray5{tTypeInds(tType)},1))', linspace(0,0.5,size(snBetaArray5{tTypeInds(tType)},1))',linspace(0,0.5,size(snBetaArray5{tTypeInds(tType)},1))']; % black to light red 
                colorMap = [linspace(1,1,size(snBetaArray5{tTypeInds(tType)},1))', linspace(0,0.6,size(snBetaArray5{tTypeInds(tType)},1))',linspace(0,0.6,size(snBetaArray5{tTypeInds(tType)},1))']; % dark red to light red             
                %                 colorMap = jet(size(CetaArray4{tTypeInds(tType)},1));
                for trace = 1:size(snBetaArray5{tTypeInds(tType)},1)
                    plot(snBetaArray5{tTypeInds(tType)}(trace,:)-100,'color',colorMap(trace,:),'LineWidth',2);
                end                               
                if tTypeInds(tType) == 1 
                    if optoQ == 0
                        label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
                        label1.FontSize = 30;
                        label1.FontName = 'Arial';
                        label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack2(idx)))*2),'-k',{'water reward'},'LineWidth',2);
                        label2.FontSize = 30;
                        label3 = ('Behavior Data');
                    elseif optoQ == 1 
                        plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000000 5000000], 'k','LineWidth',2)
                        plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
                        label3 = ('2 sec Blue Light');
                    end 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx):Frames_post_stim_start)/FPSstack2(idx))+1);
                    FrameVals = floor((1:FPSstack2(idx):Frames)-1);            
                elseif tTypeInds(tType) == 3 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*2)) round(baselineEndFrame+((FPSstack2(idx))*2))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+1);
                    FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
                    label3 = ('2 sec Red Light');
                elseif tTypeInds(tType) == 2 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+10);
                    FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
                    label3 = ('20 sec Blue Light');
                elseif tTypeInds(tType) == 4 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*1:Frames_post_stim_start)/FPSstack2(idx))+10);
                    FrameVals = floor((1:FPSstack2(idx)*1:Frames)-1); 
                    label3 = ('20 sec Red Light');
                end
                ax=gca;
                ax.XTick = FrameVals;
                ax.XTickLabel = sec_TimeVals;
                ax.FontSize = 30;
                ax.FontName = 'Arial';
                xlim([1 length(snBetaArray5{tTypeInds(tType)})])
                ylim([min(min(snBetaArray5{tTypeInds(tType)}-400)) max(max(snBetaArray5{tTypeInds(tType)}))+300])
                xlabel('time (s)')
                ylabel('BBB percent change')
                % initialize empty string array 
                label = strings;
                label = append(label,sprintf('BBB Permeabilty. N = %d.',mouseNum));       
        %         title({'Optogenetic Stimulation';'Event Triggered Averages (n = 3)';label},'FontName','Arial');
                if optoQ == 1 % opto data 
                    title({'Optogenetic Stimulation Event Triggered Averages';label;label3},'FontName','Arial');
                end 
                if optoQ == 0 % behavior data 
                    title({'Behavior Event Triggered Averages';label;label3},'FontName','Arial');
                end 
                set(fig,'position', [100 100 900 900])
                alpha(0.3)                               
            end 

            %plot VW data 
            if VWQ == 1
                fig = figure;             
                hold all;
                Frames = size(snVetaArray4{tTypeInds(tType)}{1},2);        
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                for group = 1:numGroups2{1}                    
                    snVetaArray5{tTypeInds(tType)}(group,:) = nanmean(snVetaArray4{tTypeInds(tType)}{group},1);                                                          
                end                                                
%                 colorMap = [linspace(0,0.8,size(snVetaArray5{tTypeInds(tType)},1))',linspace(0,0.8,size(snVetaArray5{tTypeInds(tType)},1))',linspace(0,0.8,size(snVetaArray5{tTypeInds(tType)},1))']; %black to gray
                colorMap = [linspace(0,0.6,size(snVetaArray5{tTypeInds(tType)},1))',linspace(0,0.6,size(snVetaArray5{tTypeInds(tType)},1))',linspace(0,0.6,size(snVetaArray5{tTypeInds(tType)},1))']; %black to slightly darker gray
%                 colorMap = jet(size(CetaArray4{tTypeInds(tType)},1));                
                for trace = 1:size(snVetaArray5{tTypeInds(tType)},1)
                    plot(snVetaArray5{tTypeInds(tType)}(trace,:)-100,'color',colorMap(trace,:),'LineWidth',2);
                end              
                if tTypeInds(tType) == 1 
                    if optoQ == 0
                        label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
                        label1.FontSize = 30;
                        label1.FontName = 'Arial';
                        label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack2(idx)))*2),'-k',{'water reward'},'LineWidth',2);
                        label2.FontSize = 30;
                        label3 = ('Behavior Data');
                    elseif optoQ == 1 
                        plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000000 5000000], 'k','LineWidth',2)
                        plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
                        label3 = ('2 sec Blue Light');
                    end 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx):Frames_post_stim_start)/FPSstack2(idx))+1);
                    FrameVals = floor((1:FPSstack2(idx):Frames)-1);            
                elseif tTypeInds(tType) == 3 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*2)) round(baselineEndFrame+((FPSstack2(idx))*2))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+1);
                    FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
                    label3 = ('2 sec Red Light');
                elseif tTypeInds(tType) == 2 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2)   
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+10);
                    FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
                    label3 = ('20 sec Blue Light');
                elseif tTypeInds(tType) == 4 
                    plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], 'k','LineWidth',2)
                    plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], 'k','LineWidth',2) 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+10);
                    FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
                    label3 = ('20 sec Red Light');
                end
                ax=gca;
                ax.XTick = FrameVals;
                ax.XTickLabel = sec_TimeVals;
                ax.FontSize = 30;
                ax.FontName = 'Arial';
                xlim([1 length(snVetaArray5{tTypeInds(tType)})])
                ylim([min(min(snVetaArray5{tTypeInds(tType)}-400)) max(max(snVetaArray5{tTypeInds(tType)}))+300])
                xlabel('time (s)')
                ylabel('vessel width percent change')
                % initialize empty string array 
                label = strings;
                label = append(label,sprintf('Vessel width ROIs averaged. N = %d.',mouseNum));
                if optoQ == 1 % opto data 
                    title({'Optogenetic Stimulation Event Triggered Averages';label;label3},'FontName','Arial');
                end 
                if optoQ == 0 % behavior data 
                    title({'Behavior Event Triggered Averages';label;label3},'FontName','Arial');
                end 
                set(fig,'position', [100 100 900 900])
                alpha(0.3)                              
            end                  
        end  
    end 
end 

%% overlay traces 
pCAQ = input('Input 1 to plot calcium data. ');
pBBBQ = input('Input 1 to plot BBB data. ');
pVWQ = input('Input 1 to plot vessel width data. ');
BSQ = input('Input 1 to plot bootstrapped data. Input 0 otherwise. ');
for tType = 1:tTypeNum
    fig = figure;             
    hold all;
    Frames = size(AVbData{tTypeInds(tType)},2);        
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    if pCAQ == 1 
        x = 1:length(CI_cLow{tTypeInds(tType)});
        if BSQ == 0 
            plot(AVcData{tTypeInds(tType)}-100,'b','LineWidth',3)        
            patch([x fliplr(x)],[CI_cLow{tTypeInds(tType)}-100 fliplr(CI_cHigh{tTypeInds(tType)}-100)],'b','EdgeColor','none')
%             plot(avSHcData{tTypeInds(tType)}-100,'color',[0.5 0.5 0.5],'LineWidth',3)        
%             patch([x fliplr(x)],[CI_cshLow{tTypeInds(tType)}-100 fliplr(CI_cshHigh{tTypeInds(tType)}-100)],[0.5 0.5 0.5],'EdgeColor','none')
        elseif BSQ == 1
            plot(avBScData{tTypeInds(tType)}-100,'b','LineWidth',3)        
            patch([x fliplr(x)],[CI_cbsLow{tTypeInds(tType)}-100 fliplr(CI_cbsHigh{tTypeInds(tType)}-100)],'b','EdgeColor','none')
%             plot(avSHcData{tTypeInds(tType)}-100,'color',[0.5 0.5 0.5],'LineWidth',3)        
%             patch([x fliplr(x)],[CI_cshLow{tTypeInds(tType)}-100 fliplr(CI_cshHigh{tTypeInds(tType)}-100)],[0.5 0.5 0.5],'EdgeColor','none')
        end 
        alpha(0.3) 
        ylim([-0.5 1])
    end          
    if tTypeInds(tType) == 1 
        if optoQ == 0
            plot([ceil(abs(Frames_pre_stim_start)-10) ceil(abs(Frames_pre_stim_start)-10)], [-5000000 5000000], '-k','LineWidth',2)
            plot([(ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack2(idx)))*2) (ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack2(idx)))*2)], [-5000000 5000000], '-k','LineWidth',2)
            
            label1 = xline(ceil(abs(Frames_pre_stim_start)-10),'-k',{'vibrissal stim'},'LineWidth',2);
            label1.FontSize = 30;
            label1.FontName = 'Arial';
            label2 = xline((ceil(abs(Frames_pre_stim_start)-10)+(round(FPSstack2(idx)))*2),'-k',{'water reward'},'LineWidth',2);
            label2.FontSize = 30;
            label3 = ('Behavior Data');
        elseif optoQ == 1 
            plot([round(baselineEndFrame+((FPSstack{idx})*2)) round(baselineEndFrame+((FPSstack{idx})*2))], [-5000000 5000000], '-k','LineWidth',2)
            plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], '-k','LineWidth',2) 
            label3 = ('2 sec Blue Light');
        end 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx):Frames_post_stim_start)/FPSstack2(idx))+1);
        FrameVals = floor((1:FPSstack2(idx):Frames)-1);            
    elseif tTypeInds(tType) == 3 
        plot([round(baselineEndFrame+((FPSstack2(idx))*2)) round(baselineEndFrame+((FPSstack2(idx))*2))], [-5000000 5000000], '-k','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], '-k','LineWidth',2)   
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+1);
        FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
        label3 = ('2 sec Red Light');
    elseif tTypeInds(tType) == 2 
        plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], '-k','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], '-k','LineWidth',2)   
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*2:Frames_post_stim_start)/FPSstack2(idx))+10);
        FrameVals = floor((1:FPSstack2(idx)*2:Frames)-1); 
        label3 = ('20 sec Blue Light');
    elseif tTypeInds(tType) == 4 
        plot([round(baselineEndFrame+((FPSstack2(idx))*20)) round(baselineEndFrame+((FPSstack2(idx))*20))], [-5000000 5000000], '-k','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000000 5000000], '-k','LineWidth',2) 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*1:Frames_post_stim_start)/FPSstack2(idx))+10);
        FrameVals = floor((1:FPSstack2(idx)*1:Frames)-1); 
        label3 = ('20 sec Red Light');
    end
    if optoQ == 1 % opto data 
        title({'Optogenetic Stimulation Event Triggered Averages';label;label3},'FontName','Arial');
    end 
    if optoQ == 0 % behavior data 
        title({'Behavior Event Triggered Averages';label;label3},'FontName','Arial');
    end 
    ax=gca;
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;
    ax.FontSize = 30;
    ax.FontName = 'Arial';
    xlim([1 length(AVvData{tTypeInds(tType)})])
%     ylim([min(AVvData{tTypeInds(tType)}-400) max(AVvData{tTypeInds(tType)})+300])
    xlabel('time (s)')
    ylabel('calcium percent change')
    % initialize empty string array 
    label = strings;
    label = append(label,sprintf('BBB Permeabilty. N = %d.',mouseNum));       
%         title({'Optogenetic Stimulation';'Event Triggered Averages (n = 3)';label},'FontName','Arial');
    if optoQ == 1 % opto data 
        title({'Optogenetic Stimulation Event Triggered Averages';label;label3},'FontName','Arial');
    end 
    if optoQ == 0 % behavior data 
        title({'Behavior Event Triggered Averages';label;label3},'FontName','Arial');
    end 
    if pBBBQ == 1
        %add right y axis tick marks 
%         yyaxis right 
        x = 1:length(CI_bLow{tTypeInds(tType)});
        if BSQ == 0
            plot(AVbData{tTypeInds(tType)}-100,'r','LineWidth',3)        
            patch([x fliplr(x)],[CI_bLow{tTypeInds(tType)}-100 fliplr(CI_bHigh{tTypeInds(tType)}-100)],[0.5 0 0],'EdgeColor','none')
%             plot(avSHbData{tTypeInds(tType)}-100,'-','color',[0.5 0.5 0.5],'LineWidth',3)        
%             patch([x fliplr(x)],[CI_bshLow{tTypeInds(tType)}-100 fliplr(CI_bshHigh{tTypeInds(tType)}-100)],[0.5 0.5 0.5],'EdgeColor','none')
        elseif BSQ == 1
            plot(avBSbData{tTypeInds(tType)}-100,'r','LineWidth',3)        
            patch([x fliplr(x)],[CI_bbsLow{tTypeInds(tType)}-100 fliplr(CI_bbsHigh{tTypeInds(tType)}-100)],[0.5 0 0],'EdgeColor','none')
%             plot(avSHbData{tTypeInds(tType)}-100,'color',[0.5 0.5 0.5],'LineWidth',3)        
%             patch([x fliplr(x)],[CI_bshLow{tTypeInds(tType)}-100 fliplr(CI_bshHigh{tTypeInds(tType)}-100)],[0.5 0.5 0.5],'EdgeColor','none')
        end 
        alpha(0.3) 
        ylabel('BBB percent change')
%         ylim([-10 20])
        ylim([-0.6 4])
        set(gca,'YColor',[0 0 0]);   
%         set(gca, 'YScale', 'log')
    end 
    if pVWQ == 1 
        %add right y axis tick marks 
%         yyaxis right
        x = 1:length(CI_vLow{tTypeInds(tType)});
        if BSQ == 0
            plot(AVvData{tTypeInds(tType)}-100,'k','LineWidth',3)
            patch([x fliplr(x)],[CI_vLow{tTypeInds(tType)}-100 fliplr(CI_vHigh{tTypeInds(tType)}-100)],'k','EdgeColor','none')
%             plot(avSHvData{tTypeInds(tType)}-100,'color',[0.5 0.5 0.5],'LineWidth',3)        
%             patch([x fliplr(x)],[CI_vshLow{tTypeInds(tType)}-100 fliplr(CI_vshHigh{tTypeInds(tType)}-100)],[0.5 0.5 0.5],'EdgeColor','none')
        elseif BSQ == 1
            plot(avBSvData{tTypeInds(tType)}-100,'k','LineWidth',3)        
            patch([x fliplr(x)],[CI_vbsLow{tTypeInds(tType)}-100 fliplr(CI_vbsHigh{tTypeInds(tType)}-100)],'k','EdgeColor','none')
            plot(avSHvData{tTypeInds(tType)}-100,'color',[0.5 0.5 0.5],'LineWidth',3)        
            patch([x fliplr(x)],[CI_vshLow{tTypeInds(tType)}-100 fliplr(CI_vshHigh{tTypeInds(tType)}-100)],[0.5 0.5 0.5],'EdgeColor','none')
        end          
        alpha(0.5) 
        ylabel('vessel width percent change')
%         ylim([-10 20])
        ylim([-0.6 4])
        set(gca,'YColor',[0 0 0]);   
%         set(gca, 'YScale', 'log')
    end    
    set(fig,'position', [100 100 900 900])
    alpha(0.3)      
end 

%% combine red light trials and overlay traces 

%sort all red trials together %AVcData{tType}
pCAQ = input('Input 1 to plot calcium data. ');
pBBBQ = input('Input 1 to plot BBB data. ');
pVWQ = input('Input 1 to plot vessel width data. ');
scaleQ = input('Input 1 to plot data zoomed out. Input 0 otherwise. '); 
redTrialTtypeInds = [3,4]; %THIS IS CURRENTLY HARD CODED IN, BUT DOESN'T HAVE TO BE. REPLACE EVENTUALLY.
countC = 1;
countB = 1;
countV = 1;
sortedBdata = zeros(size(snBetaArray{3},1)+size(snBetaArray{4},1),size(snBetaArray{3},2));
sortedCdata = zeros(size(snCetaArray{3},1)+size(snCetaArray{4},1),size(snCetaArray{3},2));
sortedVdata = zeros(size(snVetaArray{3},1)+size(snVetaArray{4},1),size(snVetaArray{3},2));
for tType = 1:length(redTrialTtypeInds)
    if pCAQ == 1 
        for trace = 1:size(snCetaArray{redTrialTtypeInds(tType)},1)
            sortedCdata(countC,:) = snCetaArray{redTrialTtypeInds(tType)}(trace,1:size(snCetaArray{3},2));
            countC = countC + 1;
        end 
        %determine 95% CI
        SEMc = (nanstd(sortedCdata))/(sqrt(size(sortedCdata,1))); % Standard Error            
        STDc = nanstd(sortedCdata);
        ts_cLow = tinv(0.025,size(sortedCdata,1)-1);% T-Score for 95% CI
        ts_cHigh = tinv(0.975,size(sortedCdata,1)-1);% T-Score for 95% CI
        CI_cLow = (nanmean(sortedCdata,1)) + (ts_cLow*SEMc);  % Confidence Intervals
        CI_cHigh = (nanmean(sortedCdata,1)) + (ts_cHigh*SEMc);  % Confidence Intervals
        x = 1:length(CI_cLow);
        allRedAVcData = nanmean(sortedCdata,1); 
    end 
    if pBBBQ == 1 
        % sort data 
        for trace = 1:size(snBetaArray{redTrialTtypeInds(tType)},1)
            sortedBdata(countB,:) = snBetaArray{redTrialTtypeInds(tType)}(trace,1:size(snBetaArray{3},2));
            countB = countB + 1;
        end 
        %determine 95% CI
        SEMb = (nanstd(sortedBdata))/(sqrt(size(sortedBdata,1))); % Standard Error            
        STDb = nanstd(sortedBdata);
        ts_bLow = tinv(0.025,size(sortedBdata,1)-1);% T-Score for 95% CI
        ts_bHigh = tinv(0.975,size(sortedBdata,1)-1);% T-Score for 95% CI
        CI_bLow = (nanmean(sortedBdata,1)) + (ts_bLow*SEMb);  % Confidence Intervals
        CI_bHigh = (nanmean(sortedBdata,1)) + (ts_bHigh*SEMb);  % Confidence Intervals
        x = 1:length(CI_bLow);
        allRedAVbData = nanmean(sortedBdata,1); 
    end 
    if pVWQ == 1 
       for trace = 1:size(snVetaArray{redTrialTtypeInds(tType)},1)
            sortedVdata(countV,:) = snVetaArray{redTrialTtypeInds(tType)}(trace,1:size(snVetaArray{3},2));
            countV = countV + 1;
        end 
        %determine 95% CI
        SEMv = (nanstd(sortedVdata))/(sqrt(size(sortedVdata,1))); % Standard Error            
        STDv = nanstd(sortedVdata);
        ts_vLow = tinv(0.025,size(sortedVdata,1)-1);% T-Score for 95% CI
        ts_vHigh = tinv(0.975,size(sortedVdata,1)-1);% T-Score for 95% CI
        CI_vLow = (nanmean(sortedVdata,1)) + (ts_vLow*SEMv);  % Confidence Intervals
        CI_vHigh = (nanmean(sortedVdata,1)) + (ts_vHigh*SEMv);  % Confidence Intervals
        x = 1:length(CI_vLow);
        allRedAVvData = nanmean(sortedVdata,1); 
    end 
end 

fig = figure;             
hold all;
Frames = size(AVbData{1},2);        
Frames_pre_stim_start = -((Frames-1)/2); 
Frames_post_stim_start = (Frames-1)/2; 
if pCAQ == 1 
    plot(allRedAVcData-100,'b','LineWidth',3) 
%     patch([x fliplr(x)],[CI_cLow-100 fliplr(CI_cHigh-100)],'b','EdgeColor','none')   
    alpha(0.3)
    set(gca,'YColor',[0 0 0]);
%     ylabel('calcium percent change')
end 
if pBBBQ == 1
%     yyaxis right 
    plot(allRedAVbData-100,'r','LineWidth',3)
%     ylabel('BBB permeability percent change')
    patch([x fliplr(x)],[CI_bLow-100 fliplr(CI_bHigh-100)],'r','EdgeColor','none')   
    alpha(0.3)
    set(gca,'YColor',[0 0 0]);
end 
if pVWQ == 1 
    plot(allRedAVvData-100,'k','LineWidth',3)
%     ylabel('vessel width percent change')
    patch([x fliplr(x)],[CI_vLow-100 fliplr(CI_vHigh-100)],'k','EdgeColor','none')   
    alpha(0.3)
    set(gca,'YColor',[0 0 0]);
end 
plot([baselineEndFrame baselineEndFrame], [-5000 5000],'--k','LineWidth',2)   
if scaleQ == 1 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*5:Frames_post_stim_start)/FPSstack2(idx))+1);
    FrameVals = floor((1:FPSstack2(idx)*5:Frames)-1); 
elseif scaleQ == 0
    sec_TimeVals = round(((Frames_pre_stim_start:FPSstack2(idx)*0.5:Frames_post_stim_start)/FPSstack2(idx))+0.9,1);
    FrameVals = floor((1:FPSstack2(idx)*0.5:Frames)-1); 
end 
ax=gca;
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;
ax.FontSize = 30;
ax.FontName = 'Arial';
xlim([1 length(AVvData{1})])
% ylim([-5 5])
ylim([-0.6 4])
xlabel('time (s)')
% initialize empty string array 
label = strings;
label = append(label,'  Ca ROIs averaged');
% title({'Optogenetic Stimulation';'Event Triggered Averages';label},'FontName','Times');
% title({'Optogenetic Stimulation';'of DAT+ VTA Axons'},'FontName','Times');
% legend('BBB Permeability')
set(fig,'position', [100 100 900 900]) 
% set(gca, 'YScale', 'log')

%----------------------------------------------------------
% Bootstrap the red trial data and replot (this includes baseline shuffle)
%determine how many bootstrapped samples you need to have 6x the original
%data set 
if pCAQ == 1 
    numBScData = size(sortedCdata,1)*6;
    BScData = zeros(size(sortedCdata,1)*6,size(sortedCdata,2));
    for trace = 1:numBScData
        BScData(trace,:) = sortedCdata(randsample(size(sortedCdata,1),1),:); 
    end 
    %determine 95% CI
    SEMc = (nanstd(BScData))/(sqrt(size(BScData,1))); % Standard Error            
    STDc = nanstd(BScData);
    ts_cLow = tinv(0.025,size(BScData,1)-1);% T-Score for 95% CI
    ts_cHigh = tinv(0.975,size(BScData,1)-1);% T-Score for 95% CI
    CI_cLow = (nanmean(BScData,1)) + (ts_cLow*SEMc);  % Confidence Intervals
    CI_cHigh = (nanmean(BScData,1)) + (ts_cHigh*SEMc);  % Confidence Intervals
    x = 1:length(CI_cLow);
    allRedAVcData = nanmean(BScData,1); 
end 
if pBBBQ == 1 
    numBSbData = size(sortedBdata,1)*6;
    BSbData = zeros(size(sortedBdata,1)*6,size(sortedBdata,2));
    for trace = 1:numBSbData
        BSbData(trace,:) = sortedBdata(randsample(size(sortedBdata,1),1),:); 
    end 
    %determine 95% CI
    SEMb = (nanstd(BSbData))/(sqrt(size(BSbData,1))); % Standard Error            
    STDb = nanstd(BSbData);
    ts_bLow = tinv(0.025,size(BSbData,1)-1);% T-Score for 95% CI
    ts_bHigh = tinv(0.975,size(BSbData,1)-1);% T-Score for 95% CI
    CI_bLow = (nanmean(BSbData,1)) + (ts_bLow*SEMb);  % Confidence Intervals
    CI_bHigh = (nanmean(BSbData,1)) + (ts_bHigh*SEMb);  % Confidence Intervals
    x = 1:length(CI_bLow);
    allRedAVbData = nanmean(BSbData,1); 
end 
if pVWQ == 1 
    numBSvData = size(sortedVdata,1)*6;
    BSvData = zeros(size(sortedVdata,1)*6,size(sortedVdata,2));
    for trace = 1:numBSvData
        BSvData(trace,:) = sortedVdata(randsample(size(sortedVdata,1),1),:); 
    end 
    %determine 95% CI
    SEMv = (nanstd(BSvData))/(sqrt(size(BSvData,1))); % Standard Error            
    STDv = nanstd(BSvData);
    ts_vLow = tinv(0.025,size(BSvData,1)-1);% T-Score for 95% CI
    ts_vHigh = tinv(0.975,size(BSvData,1)-1);% T-Score for 95% CI
    CI_vLow = (nanmean(BSvData,1)) + (ts_vLow*SEMv);  % Confidence Intervals
    CI_vHigh = (nanmean(BSvData,1)) + (ts_vHigh*SEMv);  % Confidence Intervals
    x = 1:length(CI_vLow);
    allRedAVvData = nanmean(BSvData,1); 
end 
%plot 
fig = figure;             
hold all;
Frames = size(AVbData{1},2);        
Frames_pre_stim_start = -((Frames-1)/2); 
Frames_post_stim_start = (Frames-1)/2; 
if pCAQ == 1 
    plot(allRedAVcData-100,'b','LineWidth',3) 
    patch([x fliplr(x)],[CI_cLow-100 fliplr(CI_cHigh-100)],'b','EdgeColor','none')   
    alpha(0.3)
    set(gca,'YColor',[0 0 0]);
%     ylabel('calcium percent change')
end 
if pBBBQ == 1
%     yyaxis right 
    plot(allRedAVbData-100,'r','LineWidth',3)
%     ylabel('BBB permeability percent change')
    patch([x fliplr(x)],[CI_bLow-100 fliplr(CI_bHigh-100)],'r','EdgeColor','none')   
    alpha(0.3)
    set(gca,'YColor',[0 0 0]);
end 
if pVWQ == 1 
    plot(allRedAVvData-100,'k','LineWidth',3)
%     ylabel('vessel width percent change')
    patch([x fliplr(x)],[CI_vLow-100 fliplr(CI_vHigh-100)],'k','EdgeColor','none')   
    alpha(0.3)
    set(gca,'YColor',[0 0 0]);
end 
plot([baselineEndFrame baselineEndFrame], [-5000 5000],'--k','LineWidth',2)   
if scaleQ == 1 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack2(idx)*5:Frames_post_stim_start)/FPSstack2(idx))+1);
    FrameVals = floor((1:FPSstack2(idx)*5:Frames)-1); 
elseif scaleQ == 0
    sec_TimeVals = round(((Frames_pre_stim_start:FPSstack2(idx)*0.5:Frames_post_stim_start)/FPSstack2(idx))+0.9,1);
    FrameVals = floor((1:FPSstack2(idx)*0.5:Frames)-1); 
end 
ax=gca;
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;
ax.FontSize = 30;
ax.FontName = 'Arial';
xlim([1 length(AVvData{1})])
% ylim([-5 5])
ylim([-0.6 4])
xlabel('time (s)')
% initialize empty string array 
label = strings;
label = append(label,'  Ca ROIs averaged');
% title({'Optogenetic Stimulation';'Event Triggered Averages';label},'FontName','Arial');
title({'Bootstrapped Data'},'FontName','Arial');
% legend('BBB Permeability')
set(fig,'position', [100 100 900 900]) 
% set(gca, 'YScale', 'log')

%}
%% make ETA VID/STACK avaerage (one animal at a time)
%{
dataScrambleQ = input("Input 1 if you need to remove frames due to data scramble. "); 
if dataScrambleQ == 1 
    for vid = 1:length(greenStacks) 
        cutOffFrame = input(sprintf("What is the cut off frame for vid %d? ", vid));
        greenStacks{vid} = greenStacks{vid}(:,:,1:cutOffFrame);
        redStacks{vid} = redStacks{vid}(:,:,1:cutOffFrame);
    end     
end 

saveDataQ = input('Input 1 to save the data out. '); 
mouse = 1;
dataParseType = input("What data do you have? Peristimulus = 0. Stimulus on = 1. ");
if dataParseType == 0 %peristimulus data to plot 
    sec_before_stim_start = input("How many seconds are there before the stimulus starts? ");
    sec_after_stim_end = input("How many seconds are there after the stimulus ends? ");
    baselineEndFrame = floor(sec_before_stim_start*(FPSstack{mouse}));
end 
plotStart = cell(1,length(greenStacks));
plotEnd = cell(1,length(greenStacks));
% determine plotting start and end frames 
for vid = 1:length(greenStacks)    
    for trial = 1:length(state_start_f{mouse}{vid})         
        if trialLengths{mouse}{vid}(trial) ~= 0             
            if dataParseType == 0                   
                if (state_start_f{mouse}{vid}(trial) - floor(sec_before_stim_start*FPSstack{mouse})) > 0 && state_end_f{mouse}{vid}(trial) + floor(sec_after_stim_end*FPSstack{mouse}) < size(greenStacks{vid},3)
                    
                    plotStart{vid}(trial) = state_start_f{mouse}{vid}(trial) - floor(sec_before_stim_start*FPSstack{mouse});
                    plotEnd{vid}(trial) = state_end_f{mouse}{vid}(trial) + floor(sec_after_stim_end*FPSstack{mouse});                    
                end            
            elseif dataParseType == 1  
                plotStart{vid}(trial) = state_start_f{mouse}{vid}(trial);
                plotEnd{vid}(trial) = state_end_f{mouse}{vid}(trial);                
            end   
        end 
    end 
end 

% makes faux trial type array for behavior data so all behavior data trials
% (based on selected state) get sorted into the same cell 
% For opto data, the state is either 7 or 8, but there are 4 different
% kinds of trials within those states. 
% For behavior data, you select whatever state you want, but there is only
% one trial type 
if optoQ == 0 
    TrialTypes{mouse} = cell(1,length(bDataFullTrace{mouse}));
    for vid = 1:length(bDataFullTrace{mouse})  
        TrialTypes{mouse}{vid}(1:length(plotStart{vid}),1) = 1:length(plotStart{vid});  
        TrialTypes{mouse}{vid}(1:length(plotStart{vid}),2) = 1;        
    end 
end 

% pick what trials are averaged 
if mouse == 1 
    trialQ = input('Input 1 to select what trials to average and plot. Input 0 for all trials. ');
end 
if trialQ == 0
    trialList = cell(1,length(greenStacks));
    for vid = 1:length(state_start_f{mouse})   
        trialList{vid} = 1:length(plotStart{vid});
    end 
elseif trialQ == 1 
    trialList = cell(1,length(greenStacks));
    for vid = 1:length(state_start_f{mouse})   
        trialList{vid} = input(sprintf('What trials do you want to average and plot for vid #%d? ',vid));
    end 
end 

% figure out ITI length and sort ITI length into trial type 
if mouse == 1 
    ITIq = input('Input 1 to separate data based on ITI length. Input 0 otherwise. ');
end 
if ITIq == 1 
    trialLenFrames = cell(1,length(greenStacks));
    trialLenTimes = cell(1,length(greenStacks));
    minMaxTrialLenTimes = cell(1,length(greenStacks));   
    for vid = 1:length(state_start_f{mouse})          
        if trialList{vid}(1) > 1 
            trialLenFrames{vid}(1) = state_start_f{mouse}{vid}(trialList{vid}(1))-state_start_f{mouse}{vid}(trialList{vid}(1)-1);    
        elseif trialList{vid}(1) == 1 
            trialLenFrames{vid}(1) = state_start_f{mouse}{vid}(trialList{vid}(1))-1;    
        end 
        trialLenFrames{vid}(2:length(trialList{vid})) = state_start_f{mouse}{vid}(trialList{vid}(2:end))-state_end_f{mouse}{vid}(trialList{vid}(1:end-1));
        trialLenTimes{vid} = trialLenFrames{vid}/FPSstack{mouse};
        minMaxTrialLenTimes{vid}(1) = min(trialLenTimes{vid});
        minMaxTrialLenTimes{vid}(2) = max(trialLenTimes{vid});
        figure; histogram(trialLenTimes{vid})
        display(minMaxTrialLenTimes{vid})
    end 
    trialLenThreshTime = input(sprintf('Input the ITI thresh (sec) to separate data by for mouse #%d vid #%d. ',mouse,vid)); 
    trialListHigh = cell(1,length(bDataFullTrace{mouse}));
    trialListLow = cell(1,length(bDataFullTrace{mouse}));
    for vid = 1:length(bDataFullTrace{mouse}) 
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

% sort data 
count1 = 1;
count2 = 1;
count3 = 1;
count4 = 1;
clearvars etaGstack etaRstack
for vid = 1:length(state_start_f{mouse}) 
    for trial = 1:length(trialList{vid}) 
        if trialLengths{mouse}{vid}(trialList{vid}(trial)) ~= 0 
             if (state_start_f{mouse}{vid}(trialList{vid}(trial)) - floor(sec_before_stim_start*FPSstack{mouse})) > 0 && state_end_f{mouse}{vid}(trialList{vid}(trial)) + floor(sec_after_stim_end*FPSstack{mouse}) < size(greenStacks{vid},3)
                %if the blue light is on
                if TrialTypes{mouse}{vid}(trialList{vid}(trial),2) == 1
                    %if it is a 2 sec trial 
                    if trialLengths{mouse}{vid}(trialList{vid}(trial)) == floor(2*FPSstack{mouse})                             
                        etaGstack{1}{count1} = greenStacks{vid}(:,:,plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                        etaRstack{1}{count1} = redStacks{vid}(:,:,plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                        count1 = count1 + 1;                    
                    %if it is a 20 sec trial
                    elseif trialLengths{mouse}{vid}(trialList{vid}(trial)) == floor(20*FPSstack{mouse})
                        etaGstack{2}{count2} = greenStacks{vid}(:,:,plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial))); 
                        etaRstack{2}{count2} = redStacks{vid}(:,:,plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial))); 
                        count2 = count2 + 1;
                    end 
                %if the red light is on 
                elseif TrialTypes{mouse}{vid}(trialList{vid}(trial),2) == 2
                    %if it is a 2 sec trial 
                    if trialLengths{mouse}{vid}(trialList{vid}(trial)) == floor(2*FPSstack{mouse})
                        etaGstack{3}{count3} = greenStacks{vid}(:,:,plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                        etaRstack{3}{count3} = redStacks{vid}(:,:,plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                        count3 = count3 + 1;                    
                    %if it is a 20 sec trial
                    elseif trialLengths{mouse}{vid}(trialList{vid}(trial)) == floor(20*FPSstack{mouse})
                        etaGstack{4}{count4} = greenStacks{vid}(:,:,plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                        etaRstack{4}{count4} = redStacks{vid}(:,:,plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                        count4 = count4 + 1;
                    end             
                end 
            end 
        end 
    end         
end

numTtypes = input('How many different trial types are there? ');
% figure out what kind of trial you have based on its location 
tTypes = find(~cellfun(@isempty,etaGstack));
% remove rows that are all 0 and then add buffer value to each trace to avoid
%negative going values 
etaGstack2 = cell(1,length(tTypes));
etaRstack2 = cell(1,length(tTypes));
for tType = 1:length(tTypes)              
    % find valid (not empty trials)
    trials = find(~cellfun(@isempty,etaGstack{tTypes(tType)}));
    for trial = 1:length(trials)
        etaGstack2{tTypes(tType)}(:,:,:,trial) = etaGstack{tTypes(tType)}{trials(trial)};
        etaRstack2{tTypes(tType)}(:,:,:,trial) = etaRstack{tTypes(tType)}{trials(trial)};
    end 
end
clearvars etaGstack etaRstack
etaGstack = etaGstack2;
etaRstack = etaRstack2;
for tType = 1:length(tTypes)     
    % determine the minimum value, add space (+100)
    minValToAddG = abs(ceil(min(min(min(min(etaGstack{tTypes(tType)}))))))+100;
    minValToAddR = abs(ceil(min(min(min(min(etaRstack{tTypes(tType)}))))))+100;
    % add min value 
    etaGstack{tTypes(tType)} = etaGstack{tTypes(tType)} + minValToAddG;    
    etaRstack{tTypes(tType)} = etaRstack{tTypes(tType)} + minValToAddR; 
end 

% make sure tType index is known for given ttype num 
if optoQ == 1 
    tTypes = cell(1);
    % check to see if red or blue opto lights were used       
    for vid = 1:length(TrialTypes{mouse})   
        % combine trialTypes and trialLengths 
        trialData{mouse}{vid}(:,1) = TrialTypes{mouse}{vid}(:,2);
        trialData{mouse}{vid}(:,2) = trialLengths{mouse}{vid};
        % determine the combination of trialTypes and lengths that
        % occur per vid 
        %if the blue light is on for 2 seconds
        if any(ismember(trialData{mouse}{vid},[1,floor(2*FPSstack{mouse})],'rows') == 1)
            tTypes{mouse}{vid}(1) = 1;              
        end 
        %if the blue light is on for 20 seconds 
        if any(ismember(trialData{mouse}{vid},[1,floor(20*FPSstack{mouse})],'rows') == 1)
            tTypes{mouse}{vid}(2) = 2;
        end 
        %if the red light is on for 2 seconds 
        if any(ismember(trialData{mouse}{vid},[2,floor(2*FPSstack{mouse})],'rows') == 1)
            tTypes{mouse}{vid}(3) = 3;
        end 
        %if the red light is on for 20 seconds    
        if any(ismember(trialData{mouse}{vid},[2,floor(20*FPSstack{mouse})],'rows') == 1)
            tTypes{mouse}{vid}(4) = 4;
        end 
        
        if any(tTypes{mouse}{vid} == 1)
            vidCheck{mouse}(vid,1) = 1;
        end 
        if any(tTypes{mouse}{vid} == 2)
            vidCheck{mouse}(vid,2) = 2;
        end 
        if any(tTypes{mouse}{vid} == 3)
            vidCheck{mouse}(vid,3) = 3;
        end 
        if any(tTypes{mouse}{vid} == 4)
            vidCheck{mouse}(vid,4) = 4;
        end             
    end  
    if sum(any(vidCheck{mouse} == 1)) > 0  
        tTypeInds(1) = 1;
    end 
    if sum(any(vidCheck{mouse} == 2)) > 0 
        tTypeInds(2) = 2;
    end 
    if sum(any(vidCheck{mouse} == 3)) > 0 
        tTypeInds(3) = 3;
    end 
    if sum(any(vidCheck{mouse} == 4)) > 0 
        tTypeInds(4) = 4; 
    end 
elseif optoQ == 0
    tTypeInds = 1;
end 
if optoQ == 1 
    % make sure the number of trialTypes in the data matches up with what
    % you think it should
    if length(nonzeros(unique(vidCheck{mouse}))) == numTtypes 
        % make sure the trial type index is known for the code below
        tTypeInds = nonzeros(unique(vidCheck{mouse}));
    elseif length(nonzeros(unique(vidCheck{mouse}))) ~= numTtypes
        disp('The number of trial types in the data does not match up with the number of trial types inputed by user!!!');
    end 
end 

% average ETA aligned stacks 
tTypes = find(~cellfun(@isempty,etaGstack));
etaGstackAv = cell(1,length(tTypes));
etaRstackAv = cell(1,length(tTypes));
for tType = 1:length(tTypes) 
    etaGstackAv{tTypes(tType)} = nanmean(etaGstack{tTypes(tType)},4);
    etaRstackAv{tTypes(tType)} = nanmean(etaRstack{tTypes(tType)},4);
end 

changePt = floor(length(etaGstackAv{tTypes(1)})/2)-2; 
secBLnorm = input("How many seconds before stim start do you want to baseline to? ");
BLstart = changePt - floor(secBLnorm*FPSstack{mouse});
NgreenStackAv = cell(1,length(etaGstackAv));
NredStackAv = cell(1,length(etaGstackAv));
% normalize to baseline period 
for tType = 1:length(tTypes)
    NgreenStackAv{tTypes(tType)} = ((etaGstackAv{tTypes(tType)}./ (nanmean(etaGstackAv{tTypes(tType)}(:,:,BLstart:changePt),3)))*100)-100;
    NredStackAv{tTypes(tType)} = ((etaRstackAv{tTypes(tType)}./ (nanmean(etaRstackAv{tTypes(tType)}(:,:,BLstart:changePt),3)))*100)-100;
end 

%temporal smoothing option
smoothQ = input('Input 0 if you do not want to do temporal smoothing. Input 1 otherwise.');
if smoothQ == 0 
    SNgreenStackAv = NgreenStackAv;
    SNredStackAv = NredStackAv;
elseif smoothQ == 1
    filtTime = input('How many seconds do you want to smooth your data by? '); % our favorite STA trace is smoothed by 0.7 sec 
    filter_rate = FPSstack{mouse}*filtTime; 
    tempFiltChanQ= input('Input 0 to temporally smooth both channels. Input 1 otherwise. ');
    if tempFiltChanQ == 0
        SNredStackAv = cell(1,length(NgreenStackAv));
        SNgreenStackAv = cell(1,length(NgreenStackAv));        
        for tType = 1:length(tTypes)
            SNredStackAv{tTypes(tType)} = smoothdata(NredStackAv{tTypes(tType)},3,'movmean',filter_rate);
            SNgreenStackAv{tTypes(tType)} = smoothdata(NgreenStackAv{tTypes(tType)},3,'movmean',filter_rate);
        end         
    elseif tempFiltChanQ == 1
        tempSmoothChanQ = input('Input 0 to temporally smooth green channel. Input 1 for red channel. ');
        if tempSmoothChanQ == 0
            SNredStackAv = NredStackAv;
            SNgreenStackAv = cell(1,length(NgreenStackAv));
            for tType = 1:length(tTypes)
                SNgreenStackAv{tTypes(tType)} = smoothdata(NgreenStackAv{tTypes(tType)},3,'movmean',filter_rate);
            end 
        elseif tempSmoothChanQ == 1
            SNredStackAv = cell(1,length(NgreenStackAv));
            SNgreenStackAv = NgreenStackAv;
            for tType = 1:length(tTypes)
                SNredStackAv{tTypes(tType)} = smoothdata(NredStackAv{tTypes(tType)},3,'movmean',filter_rate);               
            end 
        end 
    end 
end 
clearvars NgreenStackAv NredStackAv

% spatial smoothing option
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
                for tType = 1:length(tTypes)
                    SNredStackAv{tTypes(tType)} = imgaussfilt(redIn{tTypes(tType)},sigma);
                    SNgreenStackAv{tTypes(tType)} = imgaussfilt(greenIn{tTypes(tType)},sigma);
                end 
        elseif spatSmoothTypeQ == 1 % if you want to use convolution smoothing 
            % create your kernal for smoothing by convolution 
            kernalSize = input('What size NxN array do you want to use for convolution spatial filtering? ');
            K = 0.125*ones(kernalSize);
                for tType = 1:length(tTypes)
                    SNredStackAv{tTypes(tType)} = convn(redIn{tTypes(tType)},K,'same');
                    SNgreenStackAv{tTypes(tType)} = convn(greenIn{tTypes(tType)},K,'same');
                end 
        end 
    elseif spatFiltChanQ == 1 % if you only want to spatially smooth one channel 
        spatSmoothChanQ = input('Input 0 to spatially smooth the green channel. Input 1 for the red channel. ');
        if spatSmoothTypeQ == 0 % if you want to use gaussian spatial smoothing 
            sigma = input('What sigma do you want to use for Gaussian spatial filtering? ');
            if spatSmoothChanQ == 0 % if you want to spatially smooth the green channel 
                greenIn = SNgreenStackAv;
                clearvars SNgreenStackAv
                for tType = 1:length(tTypes)
                    SNgreenStackAv{tTypes(tType)} = imgaussfilt(greenIn{tTypes(tType)},sigma);
                end 
            elseif spatSmoothChanQ == 1 % if you want to spatially smooth the red channel 
                redIn = SNredStackAv; 
                clearvars SNredStackAv 
                for tType = 1:length(tTypes)
                    SNredStackAv{tTypes(tType)} = imgaussfilt(redIn{tTypes(tType)},sigma);
                end 
            end        
        elseif spatSmoothTypeQ == 1 % if you want to use convolution smoothing 
            % create your kernal for smoothing by convolution 
            kernalSize = input('What size NxN array do you want to use for convolution spatial filtering? ');
            K = 0.125*ones(kernalSize);
            if spatSmoothChanQ == 0 % if you want to spatially smooth the green channel 
                greenIn = SNgreenStackAv;
                clearvars SNgreenStackAv
                for tType = 1:length(tTypes)
                    SNgreenStackAv{tTypes(tType)} = convn(greenIn{tTypes(tType)},K,'same');
                end 
            elseif spatSmoothChanQ == 1 % if you want to spatially smooth the red channel 
                redIn = SNredStackAv; 
                clearvars SNredStackAv 
                for tType = 1:length(tTypes)
                    SNredStackAv{tTypes(tType)} = convn(redIn{tTypes(tType)},K,'same');
                end 
            end                          
        end 
    end 
end 

cMapQ = input('Input 0 to create a color map that is green for positive % change and red for negative % change. Input 1 to create a colormap for only positive going values. ');
if cMapQ == 0
    % Create colormap that is green for positive, red for negative,
    % and a chunk inthe middle that is black.
    % these colors have more black in them 
    greenColorMap = [zeros(1, 156), linspace(0, 1, 100)];
    redColorMap = [linspace(1, 0, 100), zeros(1, 156)];
    % these are the original colors 
%     greenColorMap = [zeros(1, 132), linspace(0, 1, 124)];
%     redColorMap = [linspace(1, 0, 124), zeros(1, 132)];
    cMap = [redColorMap; greenColorMap; zeros(1, 256)]';
elseif cMapQ == 1
    % Create colormap that is green at max and black at min
    greenColorMap = linspace(0, 1, 256);
    cMap = [zeros(1, 256); greenColorMap; zeros(1, 256)]';
end 

%% play and save green channel 
if exist('SNgreenStackAv','var') == 1
    if exist('SNredStackAv','var') == 1
        redOutlineQ = input("Input 1 if you want to plot a red channel outline. ");
        if redOutlineQ == 1 
            redOutlineQ2 = 1;
        end 
        while redOutlineQ == 1   
            %compile red channel images for all videos (to make cleanest
            %average) 
            for vid = 1:length(redStacks)
                if vid == 1
                    Rstack = redStacks{vid};
                elseif vid > 1
                    curLen = size(Rstack,3);
                    futLen = curLen + size(redStacks{vid},3);
                    Rstack(:,:,curLen:futLen) = redStacks{vid};
                end 
            end   
            % average the red images 
            Rav = nanmean(Rstack,3);
            % outline the vessels     
            imshow(Rav,[0 50])
            outline = drawfreehand(gca);  % manually draw vessel outline
            % get the vessel outline coordinates 
            Vinds = outline.Position;
            outLineQ = input(sprintf('Input 1 if you are done drawing the outline '));
            if outLineQ == 1
                close all
            end 
            % turn outline coordinates into mask 
            BW = poly2mask(Vinds(:,1),Vinds(:,2),size(Rav,1),size(Rav,2));           
            % Active contour
            iterations = 3;
            BW = activecontour(Rav, BW, iterations, 'Chan-Vese');
            %get the segmentation boundaries 
            BW_perim = bwperim(BW);
            %overlay segmentation boundaries on data
            overlay = imoverlay(mat2gray(Rav), BW_perim, [.3 1 .3]);
            imshow(overlay)
            redOutlineQ = input("Input 0 if the outline is done. "); 
        end 
    end 
    for tType = 1:length(tTypes)        
        %find the upper and lower bounds of your data (per calcium ROI) 
        maxValueG = max(max(max(max(SNgreenStackAv{tTypes(tType)}))));
        minValueG = min(min(min(min(SNgreenStackAv{tTypes(tType)}))));  
        minMaxAbsVals = [abs(minValueG),abs(maxValueG)];
        maxAbVal = max(minMaxAbsVals);
        %prepare folder for saving the images out as .pngs 
        if saveDataQ == 1 
            mouseLabel = input('Input a label for this animal. '); 
            dirLabel = sprintf('WHERE DO YOU WANT TO SAVE OUT THE DATA FOR %s? ',mouseLabel);
            dir1 = uigetdir('*.*',dirLabel);    
            dir2 = strrep(dir1,'\','/'); % change the direction of the slashes 
            %create a new folder 
            newFolder = sprintf('%s_GreenChannelETAav',mouseLabel);
            mkdir(dir2,newFolder)
        end                
        % play images 
        for frame = 1:size(SNgreenStackAv{tTypes(tType)},3)
            % create the % change image with the right white and black point
            % boundaries and colormap 
            imagesc(SNgreenStackAv{tTypes(tType)}(:,:,frame),[-maxAbVal,maxAbVal]); colormap(cMap); colorbar    %this makes the max point the max % change and the min point the inverse of the max % change                 
            % plot markers to indicate when the stim is on
            if frame >= changePt && frame <= floor(changePt + (FPSstack{1}*2))
                %get border coordinates 
                colLen = size(SNgreenStackAv{tTypes(tType)},2);
                rowLen = size(SNgreenStackAv{tTypes(tType)},1);
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
                scatter(edg_x,edg_y,15,'red','filled','square'); 
            end 
            % plot vessel outline 
            if exist('SNredStackAv','var') == 1
                if redOutlineQ2 == 1  
                    hold on; 
                    scatter(Vinds(:,1),Vinds(:,2),10,'white','filled','square')
                end 
            end             
            ax = gca;
            ax.Visible = 'off';
            ax.FontSize = 20; 
            if saveDataQ == 1 
                %save current figure to file 
                filename = sprintf('%s/%s_GreenChannelETAav/%s_GreenChannelETAav_frame%d',dir2,mouseLabel,mouseLabel,frame);
                saveas(gca,[filename '.png'])
            end 
            close all
        end     
    end 
end 
    

%% play and save red channel 
if exist('SNredStackAv','var') == 1
    for tType = 1:length(tTypes)        
        %find the upper and lower bounds of your data (per calcium ROI) 
        maxValueG = max(max(max(max(SNredStackAv{tTypes(tType)}))));
        minValueG = min(min(min(min(SNredStackAv{tTypes(tType)}))));
        minMaxAbsVals = [abs(minValueG),abs(maxValueG)];
        maxAbVal = max(minMaxAbsVals);
        %prepare folder for saving the images out as .pngs 
        if saveDataQ == 1 
            %create a new folder 
            newFolder = sprintf('%s_RedChannelETAav',mouseLabel);
            mkdir(dir2,newFolder)
        end                
        
        % play images 
        for frame = 1:size(SNredStackAv{tTypes(tType)},3)
            % create the % change image with the right white and black point
            % boundaries and colormap 
            imagesc(SNredStackAv{tTypes(tType)}(:,:,frame),[-maxAbVal,maxAbVal]); colormap(cMap); colorbar    %this makes the max point the max % change and the min point the inverse of the max % change     
            % plot markers to indicate when the stim is on
            if frame >= changePt && frame <= floor(changePt + (FPSstack{1}*2))
                %get border coordinates 
                colLen = size(SNredStackAv{tTypes(tType)},2);
                rowLen = size(SNredStackAv{tTypes(tType)},1);
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
                scatter(edg_x,edg_y,15,'red','filled','square'); 
            end 
            ax = gca;
            ax.Visible = 'off';
            ax.FontSize = 20; 
            if saveDataQ == 1 
                %save current figure to file 
                filename = sprintf('%s/%s_RedChannelETAav/%s_RedChannelETAav_frame%d',dir2,mouseLabel,mouseLabel,frame);
                saveas(gca,[filename '.png'])
            end 
            close all
        end     
    end 
end 
       
if saveDataQ == 1 
    fileName = sprintf('%s_RedandGreenChannelETAav',mouseLabel);
    save(fullfile(dir1,fileName),"SNgreenStackAv","SNredStackAv","FPSstack");
end 
%}

% TO DO
% 3) DO Z-SCORING TO FIND ACTIVE PIXELS
% 4) MAKE MASK OF ACTIVE PIXELS AND CREATE RED CHANNEL STA VIDS BASED ON
% ACTIVE PIXEL ACTIVITY PEAKS 

%% make ETA VID/STACKs per trial (one animal at a time)
%{

dataScrambleQ = input("Input 1 if you need to remove frames due to data scramble. "); 
if dataScrambleQ == 1 
    for vid = 1:length(greenStacks) 
        cutOffFrame = input(sprintf("What is the cut off frame for vid %d? ", vid));
        greenStacks{vid} = greenStacks{vid}(:,:,1:cutOffFrame);
        redStacks{vid} = redStacks{vid}(:,:,1:cutOffFrame);
    end     
end 

saveDataQ = input('Input 1 to save the data out. '); 
mouse = 1;
dataParseType = input("What data do you have? Peristimulus = 0. Stimulus on = 1. ");
if dataParseType == 0 %peristimulus data to plot 
    sec_before_stim_start = input("How many seconds are there before the stimulus starts? ");
    sec_after_stim_end = input("How many seconds are there after the stimulus ends? ");
    baselineEndFrame = floor(sec_before_stim_start*(FPSstack{mouse}));
end 
plotStart = cell(1,length(greenStacks));
plotEnd = cell(1,length(greenStacks));
% determine plotting start and end frames 
for vid = 1:length(greenStacks)    
    for trial = 1:length(state_start_f{mouse}{vid})         
        if trialLengths{mouse}{vid}(trial) ~= 0             
            if dataParseType == 0                   
                if (state_start_f{mouse}{vid}(trial) - floor(sec_before_stim_start*FPSstack{mouse})) > 0 && state_end_f{mouse}{vid}(trial) + floor(sec_after_stim_end*FPSstack{mouse}) < size(greenStacks{vid},3)
                    
                    plotStart{vid}(trial) = state_start_f{mouse}{vid}(trial) - floor(sec_before_stim_start*FPSstack{mouse});
                    plotEnd{vid}(trial) = state_end_f{mouse}{vid}(trial) + floor(sec_after_stim_end*FPSstack{mouse});                    
                end            
            elseif dataParseType == 1  
                plotStart{vid}(trial) = state_start_f{mouse}{vid}(trial);
                plotEnd{vid}(trial) = state_end_f{mouse}{vid}(trial);                
            end   
        end 
    end 
end 

% makes faux trial type array for behavior data so all behavior data trials
% (based on selected state) get sorted into the same cell 
% For opto data, the state is either 7 or 8, but there are 4 different
% kinds of trials within those states. 
% For behavior data, you select whatever state you want, but there is only
% one trial type 
if optoQ == 0 
    TrialTypes{mouse} = cell(1,length(bDataFullTrace{mouse}));
    for vid = 1:length(bDataFullTrace{mouse})  
        TrialTypes{mouse}{vid}(1:length(plotStart{vid}),1) = 1:length(plotStart{vid});  
        TrialTypes{mouse}{vid}(1:length(plotStart{vid}),2) = 1;        
    end 
end 

% this pre-selects all the trials 
trialList = cell(1,length(greenStacks));
for vid = 1:length(state_start_f{mouse})   
    trialList{vid} = 1:length(plotStart{vid});
end 

% sort data 
count1 = 1;
count2 = 1;
count3 = 1;
count4 = 1;
clearvars etaGstack etaRstack
for vid = 1:length(state_start_f{mouse}) 
    for trial = 1:length(trialList{vid}) 
        if trialLengths{mouse}{vid}(trialList{vid}(trial)) ~= 0 
             if (state_start_f{mouse}{vid}(trialList{vid}(trial)) - floor(sec_before_stim_start*FPSstack{mouse})) > 0 && state_end_f{mouse}{vid}(trialList{vid}(trial)) + floor(sec_after_stim_end*FPSstack{mouse}) < size(greenStacks{vid},3)
                %if the blue light is on
                if TrialTypes{mouse}{vid}(trialList{vid}(trial),2) == 1
                    %if it is a 2 sec trial 
                    if trialLengths{mouse}{vid}(trialList{vid}(trial)) == floor(2*FPSstack{mouse})                             
                        etaGstack{1}{count1} = greenStacks{vid}(:,:,plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                        etaRstack{1}{count1} = redStacks{vid}(:,:,plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                        count1 = count1 + 1;                    
                    %if it is a 20 sec trial
                    elseif trialLengths{mouse}{vid}(trialList{vid}(trial)) == floor(20*FPSstack{mouse})
                        etaGstack{2}{count2} = greenStacks{vid}(:,:,plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial))); 
                        etaRstack{2}{count2} = redStacks{vid}(:,:,plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial))); 
                        count2 = count2 + 1;
                    end 
                %if the red light is on 
                elseif TrialTypes{mouse}{vid}(trialList{vid}(trial),2) == 2
                    %if it is a 2 sec trial 
                    if trialLengths{mouse}{vid}(trialList{vid}(trial)) == floor(2*FPSstack{mouse})
                        etaGstack{3}{count3} = greenStacks{vid}(:,:,plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                        etaRstack{3}{count3} = redStacks{vid}(:,:,plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                        count3 = count3 + 1;                    
                    %if it is a 20 sec trial
                    elseif trialLengths{mouse}{vid}(trialList{vid}(trial)) == floor(20*FPSstack{mouse})
                        etaGstack{4}{count4} = greenStacks{vid}(:,:,plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                        etaRstack{4}{count4} = redStacks{vid}(:,:,plotStart{vid}(trialList{vid}(trial)):plotEnd{vid}(trialList{vid}(trial)));
                        count4 = count4 + 1;
                    end             
                end 
            end 
        end 
    end         
end

numTtypes = input('How many different trial types are there? ');
% figure out what kind of trial you have based on its location 
tTypes = find(~cellfun(@isempty,etaGstack));
% remove rows that are all 0 and then add buffer value to each trace to avoid
%negative going values 
etaGstack2 = cell(1,length(tTypes));
etaRstack2 = cell(1,length(tTypes));
for tType = 1:length(tTypes)              
    % find valid (not empty trials)
    trials = find(~cellfun(@isempty,etaGstack{tTypes(tType)}));
    for trial = 1:length(trials)
        etaGstack2{tTypes(tType)}{trials(trial)} = etaGstack{tTypes(tType)}{trials(trial)};
        etaRstack2{tTypes(tType)}{trials(trial)} = etaRstack{tTypes(tType)}{trials(trial)};
    end 
end

clearvars etaGstack etaRstack
etaGstack = etaGstack2;
etaRstack = etaRstack2;
minValToAddG = cell(1,length(tTypes));
minValToAddR = cell(1,length(tTypes));
for tType = 1:length(tTypes)         
    for trial = 1:length(etaGstack{tTypes(tType)})
        % determine the minimum value, add space (+100)
        minValToAddG{tTypes(tType)}(trials(trial)) = abs(ceil(min(min(min(min(etaGstack{tTypes(tType)}{trials(trial)}))))))+100;
        minValToAddR{tTypes(tType)}(trials(trial)) = abs(ceil(min(min(min(min(etaRstack{tTypes(tType)}{trials(trial)}))))))+100;
        % add min value 
        etaGstack{tTypes(tType)}{trials(trial)} = etaGstack{tTypes(tType)}{trials(trial)} + minValToAddG{tTypes(tType)}(trials(trial));    
        etaRstack{tTypes(tType)}{trials(trial)} = etaRstack{tTypes(tType)}{trials(trial)} + minValToAddR{tTypes(tType)}(trials(trial)); 
    end 
end 

% make sure tType index is known for given ttype num 
if optoQ == 1 
    tTypes2 = cell(1,mouseNum);
    vidCheck =  cell(1,mouseNum);
    trialData =  cell(1,mouseNum);
    % check to see if red or blue opto lights were used       
    for vid = 1:length(TrialTypes{mouse})   
        % combine trialTypes and trialLengths 
        trialData{mouse}{vid}(:,1) = TrialTypes{mouse}{vid}(:,2);
        trialData{mouse}{vid}(:,2) = trialLengths{mouse}{vid};
        % determine the combination of trialTypes and lengths that
        % occur per vid 
        %if the blue light is on for 2 seconds
        if any(ismember(trialData{mouse}{vid},[1,floor(2*FPSstack{mouse})],'rows') == 1)
            tTypes2{mouse}{vid}(1) = 1;              
        end 
        %if the blue light is on for 20 seconds 
        if any(ismember(trialData{mouse}{vid},[1,floor(20*FPSstack{mouse})],'rows') == 1)
            tTypes2{mouse}{vid}(2) = 2;
        end 
        %if the red light is on for 2 seconds 
        if any(ismember(trialData{mouse}{vid},[2,floor(2*FPSstack{mouse})],'rows') == 1)
            tTypes2{mouse}{vid}(3) = 3;
        end 
        %if the red light is on for 20 seconds    
        if any(ismember(trialData{mouse}{vid},[2,floor(20*FPSstack{mouse})],'rows') == 1)
            tTypes2{mouse}{vid}(4) = 4;
        end 
        
        if any(tTypes2{mouse}{vid} == 1)
            vidCheck{mouse}(vid,1) = 1;
        end 
        if any(tTypes2{mouse}{vid} == 2)
            vidCheck{mouse}(vid,2) = 2;
        end 
        if any(tTypes2{mouse}{vid} == 3)
            vidCheck{mouse}(vid,3) = 3;
        end 
        if any(tTypes2{mouse}{vid} == 4)
            vidCheck{mouse}(vid,4) = 4;
        end             
    end  
    if sum(any(vidCheck{mouse} == 1)) > 0  
        tTypeInds(1) = 1;
    end 
    if sum(any(vidCheck{mouse} == 2)) > 0 
        tTypeInds(2) = 2;
    end 
    if sum(any(vidCheck{mouse} == 3)) > 0 
        tTypeInds(3) = 3;
    end 
    if sum(any(vidCheck{mouse} == 4)) > 0 
        tTypeInds(4) = 4; 
    end 
elseif optoQ == 0
    tTypeInds = 1;
end 
if optoQ == 1 
    % make sure the number of trialTypes in the data matches up with what
    % you think it should
    if length(nonzeros(unique(vidCheck{mouse}))) == numTtypes 
        % make sure the trial type index is known for the code below
        tTypeInds = nonzeros(unique(vidCheck{mouse}));
    elseif length(nonzeros(unique(vidCheck{mouse}))) ~= numTtypes
        disp('The number of trial types in the data does not match up with the number of trial types inputed by user!!!');
    end 
end 

secBLnorm = input("How many seconds before stim start do you want to baseline to? ");
NgreenStackAv = cell(1,length(etaGstack));
NredStackAv = cell(1,length(etaGstack));
% normalize to baseline period 
for tType = 1:length(tTypes)
    changePt = floor(length(etaGstack{tTypes(tType)}{1})/2)-2; 
    BLstart = changePt - floor(secBLnorm*FPSstack{mouse});    
    for trial = 1:length(etaGstack{tTypes(tType)})
        NgreenStackAv{tTypes(tType)}{trial} = ((etaGstack{tTypes(tType)}{trial}./ (nanmean(etaGstack{tTypes(tType)}{trial}(:,:,BLstart:changePt),3)))*100)-100;
        NredStackAv{tTypes(tType)}{trial} = ((etaRstack{tTypes(tType)}{trial}./ (nanmean(etaRstack{tTypes(tType)}{trial}(:,:,BLstart:changePt),3)))*100)-100;
    end 
end 

% temporal smoothing option
smoothQ = input('Input 0 if you do not want to do temporal smoothing. Input 1 otherwise.');
if smoothQ == 0 
    SNgreenStackAv = NgreenStackAv;
    SNredStackAv = NredStackAv;
elseif smoothQ == 1
    filtTime = input('How many seconds do you want to smooth your data by? '); % our favorite STA trace is smoothed by 0.7 sec 
    filter_rate = FPSstack{mouse}*filtTime; 
    tempFiltChanQ= input('Input 0 to temporally smooth both channels. Input 1 otherwise. ');
    if tempFiltChanQ == 0
        SNredStackAv = cell(1,length(NgreenStackAv));
        SNgreenStackAv = cell(1,length(NgreenStackAv));        
        for tType = 1:length(tTypes)
            for trial = 1:length(etaGstack{tTypes(tType)})
                SNredStackAv{tTypes(tType)}{trial} = smoothdata(NredStackAv{tTypes(tType)}{trial},3,'movmean',filter_rate);
                SNgreenStackAv{tTypes(tType)}{trial} = smoothdata(NgreenStackAv{tTypes(tType)}{trial},3,'movmean',filter_rate);
            end 
        end         
    elseif tempFiltChanQ == 1
        tempSmoothChanQ = input('Input 0 to temporally smooth green channel. Input 1 for red channel. ');
        if tempSmoothChanQ == 0
            SNredStackAv = NredStackAv;
            SNgreenStackAv = cell(1,length(NgreenStackAv));
            for tType = 1:length(tTypes)
                for trial = 1:length(etaGstack{tTypes(tType)})
                    SNgreenStackAv{tTypes(tType)}{trial} = smoothdata(NgreenStackAv{tTypes(tType)}{trial},3,'movmean',filter_rate);
                end 
            end 
        elseif tempSmoothChanQ == 1
            SNredStackAv = cell(1,length(NgreenStackAv));
            SNgreenStackAv = NgreenStackAv;
            for tType = 1:length(tTypes)
                for trial = 1:length(etaGstack{tTypes(tType)})
                    SNredStackAv{tTypes(tType)}{trial} = smoothdata(NredStackAv{tTypes(tType)}{trial},3,'movmean',filter_rate); 
                end 
            end 
        end 
    end 
end 
clearvars NgreenStackAv NredStackAv

% spatial smoothing option
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
                for tType = 1:length(tTypes)
                    for trial = 1:length(etaGstack{tTypes(tType)})
                        SNredStackAv{tTypes(tType)}{trial} = imgaussfilt(redIn{tTypes(tType)}{trial},sigma);
                        SNgreenStackAv{tTypes(tType)}{trial} = imgaussfilt(greenIn{tTypes(tType)}{trial},sigma);
                    end 
                end 
        elseif spatSmoothTypeQ == 1 % if you want to use convolution smoothing 
            % create your kernal for smoothing by convolution 
            kernalSize = input('What size NxN array do you want to use for convolution spatial filtering? ');
            K = 0.125*ones(kernalSize);
                for tType = 1:length(tTypes)
                    for trial = 1:length(etaGstack{tTypes(tType)})
                        SNredStackAv{tTypes(tType)}{trial} = convn(redIn{tTypes(tType)}{trial},K,'same');
                        SNgreenStackAv{tTypes(tType)}{trial} = convn(greenIn{tTypes(tType)}{trial},K,'same');
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
                for tType = 1:length(tTypes)
                    for trial = 1:length(etaGstack{tTypes(tType)})
                        SNgreenStackAv{tTypes(tType)}{trial} = imgaussfilt(greenIn{tTypes(tType)}{trial},sigma);
                    end 
                end 
            elseif spatSmoothChanQ == 1 % if you want to spatially smooth the red channel 
                redIn = SNredStackAv; 
                clearvars SNredStackAv 
                for tType = 1:length(tTypes)
                    for trial = 1:length(etaGstack{tTypes(tType)})
                        SNredStackAv{tTypes(tType)}{trial} = imgaussfilt(redIn{tTypes(tType)}{trial},sigma);
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
                for tType = 1:length(tTypes)
                    for trial = 1:length(etaGstack{tTypes(tType)})
                        SNgreenStackAv{tTypes(tType)}{trial} = convn(greenIn{tTypes(tType)}{trial},K,'same');
                    end 
                end 
            elseif spatSmoothChanQ == 1 % if you want to spatially smooth the red channel 
                redIn = SNredStackAv; 
                clearvars SNredStackAv 
                for tType = 1:length(tTypes)
                    for trial = 1:length(etaGstack{tTypes(tType)})
                        SNredStackAv{tTypes(tType)}{trial} = convn(redIn{tTypes(tType)}{trial},K,'same');
                    end 
                end 
            end                          
        end 
    end 
end 

cMapQ = input('Input 0 to create a color map that is green for positive % change and red for negative % change. Input 1 to create a colormap for only positive going values. ');
if cMapQ == 0
    % Create colormap that is green for positive, red for negative,
    % and a chunk inthe middle that is black.
    % these colors have more black in them 
%     greenColorMap = [zeros(1, 156), linspace(0, 1, 100)];
%     redColorMap = [linspace(1, 0, 100), zeros(1, 156)];
    % these are the original colors 
    greenColorMap = [zeros(1, 132), linspace(0, 1, 124)];
    redColorMap = [linspace(1, 0, 124), zeros(1, 132)];
    cMap = [redColorMap; greenColorMap; zeros(1, 256)]';
elseif cMapQ == 1
    % Create colormap that is green at max and black at min
    greenColorMap = linspace(0, 1, 256);
    cMap = [zeros(1, 256); greenColorMap; zeros(1, 256)]';
end 

%% play and save green channel 
if exist('SNgreenStackAv','var') == 1
    if exist('SNredStackAv','var') == 1
        redOutlineQ = input("Input 1 if you want to plot a red channel outline. ");
        if redOutlineQ == 1 
            redOutlineQ2 = 1;
        end 
        while redOutlineQ == 1   
            newOutlineQ = input("Input 1 if you need to make a new vessel outline. Input 0 otherwise. ");
            if newOutlineQ == 1            
                %compile red channel images for all videos (to make cleanest
                %average) 
                for vid = 1:length(redStacks)
                    if vid == 1
                        Rstack = redStacks{vid};
                    elseif vid > 1
                        curLen = size(Rstack,3);
                        futLen = curLen + size(redStacks{vid},3);
                        Rstack(:,:,curLen:futLen) = redStacks{vid};
                    end 
                end   
                % average the red images 
                Rav = nanmean(Rstack,3);
                % outline the vessels     
                imshow(Rav,[0 50])
                outline = drawfreehand(gca);  % manually draw vessel outline
                % get the vessel outline coordinates 
                Vinds = outline.Position;
                outLineQ = input(sprintf('Input 1 if you are done drawing the outline '));
                if outLineQ == 1
                    close all
                end 
                % turn outline coordinates into mask 
                BW = poly2mask(Vinds(:,1),Vinds(:,2),size(Rav,1),size(Rav,2));           
                % Active contour
                iterations = 3;
                BW = activecontour(Rav, BW, iterations, 'Chan-Vese');
                %get the segmentation boundaries 
                BW_perim = bwperim(BW);
                %overlay segmentation boundaries on data
                overlay = imoverlay(mat2gray(Rav), BW_perim, [.3 1 .3]);
                imshow(overlay)
                redOutlineQ = input("Input 0 if the outline is done. "); 
            elseif newOutlineQ == 0
                redOutlineQ = 0;                
            end 
        end 
    end 
    for tType = 1:length(tTypes)    
        for trial = 2:length(etaGstack{tTypes(tType)})
            %find the upper and lower bounds of your data (per calcium ROI) 
            maxValueG = max(max(max(max(SNgreenStackAv{tTypes(tType)}{trial}))));
            minValueG = min(min(min(min(SNgreenStackAv{tTypes(tType)}{trial}))));  
            minMaxAbsVals = [abs(minValueG),abs(maxValueG)];
            maxAbVal = max(minMaxAbsVals);
            %prepare folder for saving the images out as .pngs 
            if saveDataQ == 1 
                if trial == 1 
                    mouseLabel = input('Input a label for this animal. '); 
                    dirLabel = sprintf('WHERE DO YOU WANT TO SAVE OUT THE DATA FOR %s? ',mouseLabel);
                    dir1 = uigetdir('*.*',dirLabel);    
                    dir2 = strrep(dir1,'\','/'); % change the direction of the slashes 
                end                 
                %create a new folder 
                newFolder = sprintf('%s_GreenChannelETAav_trial%d',mouseLabel,trial);
                mkdir(dir2,newFolder)
            end                
            % play images 
            for frame = 1:size(SNgreenStackAv{tTypes(tType)}{trial},3)
                % create the % change image with the right white and black point
                % boundaries and colormap 
                imagesc(SNgreenStackAv{tTypes(tType)}{trial}(:,:,frame),[-maxAbVal,maxAbVal]); colormap(cMap); colorbar    %this makes the max point the max % change and the min point the inverse of the max % change                 
                % plot markers to indicate when the stim is on
                if frame >= changePt && frame <= floor(changePt + (FPSstack{1}*2))
                    %get border coordinates 
                    colLen = size(SNgreenStackAv{tTypes(tType)}{trial},2);
                    rowLen = size(SNgreenStackAv{tTypes(tType)}{trial},1);
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
                    scatter(edg_x,edg_y,15,'red','filled','square'); 
                end 
                % plot vessel outline 
                if exist('SNredStackAv','var') == 1
                    if redOutlineQ2 == 1  
                        hold on; 
                        scatter(Vinds(:,1),Vinds(:,2),10,'white','filled','square')
                    end 
                end             
                ax = gca;
                ax.Visible = 'off';
                ax.FontSize = 20; 
                if saveDataQ == 1 
                    %save current figure to file 
                    filename = sprintf('%s/%s_GreenChannelETAav_trial%d/%s_trial%d_GreenChannelETAav_frame%d',dir2,mouseLabel,trial,mouseLabel,trial,frame);
                    saveas(gca,[filename '.png'])
                end 
                close all
            end     
        end 
    end 
end 
    

%% play and save red channel 
if exist('SNredStackAv','var') == 1
    for tType = 1:length(tTypes)     
        for trial = 1:length(etaGstack{tTypes(tType)})
            %find the upper and lower bounds of your data (per calcium ROI) 
            maxValueG = max(max(max(max(SNredStackAv{tTypes(tType)}{trial}))));
            minValueG = min(min(min(min(SNredStackAv{tTypes(tType)}{trial}))));
            minMaxAbsVals = [abs(minValueG),abs(maxValueG)];
            maxAbVal = max(minMaxAbsVals);
            %prepare folder for saving the images out as .pngs 
            if saveDataQ == 1 
                %create a new folder 
                newFolder = sprintf('%s_RedChannelETAav_trial%d',mouseLabel,trial);
                mkdir(dir2,newFolder)
            end                

            % play images 
            for frame = 1:size(SNredStackAv{tTypes(tType)}{trial},3)
                % create the % change image with the right white and black point
                % boundaries and colormap 
                imagesc(SNredStackAv{tTypes(tType)}{trial}(:,:,frame),[-maxAbVal,maxAbVal]); colormap(cMap); colorbar    %this makes the max point the max % change and the min point the inverse of the max % change     
                % plot markers to indicate when the stim is on
                if frame >= changePt && frame <= floor(changePt + (FPSstack{1}*2))
                    %get border coordinates 
                    colLen = size(SNredStackAv{tTypes(tType)}{trial},2);
                    rowLen = size(SNredStackAv{tTypes(tType)}{trial},1);
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
                    scatter(edg_x,edg_y,15,'red','filled','square'); 
                end 
                ax = gca;
                ax.Visible = 'off';
                ax.FontSize = 20; 
                if saveDataQ == 1 
                    %save current figure to file 
                    filename = sprintf('%s/%s_RedChannelETAav_trial%d/%s_trial%d_RedChannelETAav_frame%d',dir2,mouseLabel,trial,mouseLabel,trial,frame);
                    saveas(gca,[filename '.png'])
                end 
                close all
            end     
        end 
    end 
end 
       
if saveDataQ == 1 
    fileName = sprintf('%s_RedandGreenChannelETAsingleTrial',mouseLabel);
    save(fullfile(dir1,fileName),"SNgreenStackAv","SNredStackAv","FPSstack");
end 
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
%% compare terminal calcium activity with BBB and VW data - create
%correlograms and run FT on the data (this just assumes you have Ca, VW, and BBB data
%for simplicity)
%newer version - takes c/v/bDataFullTrace from batch .mat files 
%{
%import entire time series data 
regImDir = uigetdir('*.*','WHERE IS THE (BATCH) DATA?');
cd(regImDir);
MatFileName = uigetfile('*.*','SELECT (BATCH) DATA');
Mat = matfile(MatFileName);
cDataFullTrace  = Mat.cDataFullTrace;
CaROIs = Mat.terminals;
bDataFullTrace = Mat.bDataFullTrace;
vDataFullTrace = Mat.vDataFullTrace;
FPSstack = Mat.FPSstack;
  
dataSetQ = input('Input 1 to load another data set and append to the relevant variables. '); 
while dataSetQ == 1
    regImDir = uigetdir('*.*','WHERE IS THE (BATCH) DATA?');
    cd(regImDir);
    MatFileName = uigetfile('*.*','SELECT (BATCH) DATA');
    Mat = matfile(MatFileName);
    cDataFullTrace2  = Mat.cDataFullTrace;
    CaROIs2 = Mat.terminals;
    bDataFullTrace2 = Mat.bDataFullTrace;
    vDataFullTrace2 = Mat.vDataFullTrace;
    FPSstack2 = Mat.FPSstack;
    
    % append new data to original variables 
    mouseNum = length(cDataFullTrace);
    mouseNum2 = length(cDataFullTrace2);
    for mouse = 1:mouseNum2
        cDataFullTrace{mouseNum+mouse} = cDataFullTrace2{mouse};   
        CaROIs{mouseNum+mouse} = CaROIs2{mouse}; 
        bDataFullTrace{mouseNum+mouse} = bDataFullTrace2{mouse};    
        vDataFullTrace{mouseNum+mouse} = vDataFullTrace2{mouse};  
        FPSstack{mouseNum+mouse} = FPSstack2{mouse}; 
    end
    dataSetQ = input('Input 1 to load another data set and append to the relevant variables. Input 0 otherwise. '); 
end 

%% smooth the data 
smoothQ = input('Input 1 to smooth the data. Input 0 otherwise. ');
if smoothQ == 0 
    scDataFullTrace = cDataFullTrace;
    sbDataFullTrace = bDataFullTrace;
    svDataFullTrace = vDataFullTrace;
elseif smoothQ == 1
    filtTime = input('How many seconds do you want to smooth your data by? ');
    scDataFullTrace = cell(1,length(cDataFullTrace));
    sbDataFullTrace = cell(1,length(cDataFullTrace));
    svDataFullTrace = cell(1,length(cDataFullTrace));
    for mouse = 1:length(cDataFullTrace)
        for vid = 1:length(cDataFullTrace{mouse})
            for CAroi = 1:length(CaROIs{mouse})
                scDataFullTrace{mouse}{vid}{CaROIs{mouse}(CAroi)} =  MovMeanSmoothData(cDataFullTrace{mouse}{vid}{CaROIs{mouse}(CAroi)},filtTime,FPSstack{mouse});
            end 
            for BBBroi = 1:length(bDataFullTrace{mouse}{vid})
                sbDataFullTrace{mouse}{vid}{BBBroi} =  MovMeanSmoothData(bDataFullTrace{mouse}{vid}{BBBroi},filtTime,FPSstack{mouse});
            end 
            for VWroi = 1:length(vDataFullTrace{mouse}{vid})
                svDataFullTrace{mouse}{vid}{VWroi} =  MovMeanSmoothData(vDataFullTrace{mouse}{vid}{VWroi},filtTime,FPSstack{mouse});
            end 
        end 
    end 
end 

%% xcorr the data per mouse 
corrFigQ = input('Input 1 to display the correlograms per mouse. ');
%compare Ca data across axons w/time lag 
CaCorrs = cell(1,length(cDataFullTrace));
CaCorrs2 = cell(1,length(cDataFullTrace));
avVidCorrs = cell(1,length(cDataFullTrace));
for mouse = 1:length(cDataFullTrace)
    for vid = 1:length(cDataFullTrace{mouse})
        for term1 = 1:length(CaROIs{mouse})
            for term2 = 1:length(CaROIs{mouse})
%                 [c{mouse}{vid},lags{mouse}{vid}] = xcorr(cDataFullTrace{mouse}{vid}{CaROIs{mouse}(term1)},cDataFullTrace{mouse}{vid}{CaROIs{mouse}(term2)});
                CaCorrs{mouse}{vid}(term1,term2) = corr2(scDataFullTrace{mouse}{vid}{CaROIs{mouse}(term1)},scDataFullTrace{mouse}{vid}{CaROIs{mouse}(term2)});
                CaCorrs2{mouse}{term1,term2}(vid) = CaCorrs{mouse}{vid}(term1,term2);
                avVidCorrs{mouse}(term1,term2) = nanmean(CaCorrs2{mouse}{term1,term2}(vid));
            end             
        end 
        % plot correlograms of 0 time lagged data (per vid)
        %{
        figure;
        imagesc(CaCorrs{mouse}{vid})
        colorbar 
        truesize([700 900])
        ax=gca;
        ax.FontSize = 20;
        ax.XTickLabel = CaROIs{mouse};
        ax.YTickLabel = CaROIs{mouse};
        xlabel('axon')
        ylabel('axon')
        title(sprintf('Axon Ca Correlogram. Mouse %d. Vid %d. ',mouse,vid),'FontSize',20);
        %}
    end 
    if corrFigQ == 1 
        figure;
        imagesc(avVidCorrs{mouse})
        colorbar 
        truesize([700 900])
        ax=gca;
        ax.FontSize = 20;
        xticks(1:length(CaROIs{mouse}))
        yticks(1:length(CaROIs{mouse}))
        ax.XTickLabel = CaROIs{mouse};
        ax.YTickLabel = CaROIs{mouse};
        xlabel('axon')
        ylabel('axon')
        title(sprintf('Axon Ca Correlogram. Mouse %d. %.2f sec smoothing.',mouse,filtTime),'FontSize',20);
    end 
end 

% determine what Ca correlations are significant (correlation coefficient of 0.8 or greater)
minCorr = zeros(1,length(cDataFullTrace));
maxCorr = zeros(1,length(cDataFullTrace));
minCorrAxons = cell(1,length(cDataFullTrace));
maxCorrAxons = cell(1,length(cDataFullTrace));
for mouse = 1:length(cDataFullTrace)
    % convert diagonal values to NANs 
    for self = 1:length(CaROIs{mouse})
        avVidCorrs{mouse}(self,self) = NaN; 
    end 
    % find min and max correlated axons per mouse 
    minCorr(mouse) = (min(min(avVidCorrs{mouse})));
    maxCorr(mouse) = (max(max(avVidCorrs{mouse})));
    [r,c] = find(avVidCorrs{mouse} == minCorr(mouse));
    minCorrAxons{1,mouse} = [CaROIs{mouse}(r);CaROIs{mouse}(c)];    
    [~,idx] = unique(sort(minCorrAxons{1,mouse},2),'rows','stable');
    minCorrAxons{1,mouse} = minCorrAxons{1,mouse}(idx,:);       
    minCorrAxons{2,mouse} = minCorr(mouse);
    [r,c] = find(avVidCorrs{mouse} == maxCorr(mouse));
    maxCorrAxons{1,mouse} = [CaROIs{mouse}(r);CaROIs{mouse}(c)];
    [~,idx] = unique(sort(maxCorrAxons{1,mouse},2),'rows','stable');
    maxCorrAxons{1,mouse} = maxCorrAxons{1,mouse}(idx,:);  
    maxCorrAxons{2,mouse} = maxCorr(mouse);
    % determine if any of the max correlations are significant 
    if maxCorrAxons{2,mouse} >= 0.8
        fprintf('Mouse %d shows significant correlation between axons.',mouse)
    end 
end 

%% compare Ca data with BBB data 

timeLagQ = input('Input 1 if you want to test the correlation between Ca axon data with time-lagged BBB data. ');
if timeLagQ == 1
    timeLag = input('Input time lag (sec). ');
end
corrFigQ = input('Input 1 to display the correlograms per mouse. ');
CaBBBCorrs = cell(1,length(cDataFullTrace));
CaBBBCorrs2 = cell(1,length(cDataFullTrace));
avCaBBBvidCorrs = cell(1,length(cDataFullTrace));
for mouse = 1:length(cDataFullTrace)
    for vid = 1:length(cDataFullTrace{mouse})
        for term1 = 1:length(CaROIs{mouse})
            for BBBroi = 1:length(sbDataFullTrace{mouse}{vid})
%                 [c{mouse}{vid},lags{mouse}{vid}] = xcorr(cDataFullTrace{mouse}{vid}{CaROIs{mouse}(term1)},cDataFullTrace{mouse}{vid}{CaROIs{mouse}(term2)});
                if timeLagQ == 0 
                    if length(scDataFullTrace{mouse}{vid}{CaROIs{mouse}(term1)}) ~= length(sbDataFullTrace{mouse}{vid}{BBBroi})
                        minLen = min(length(scDataFullTrace{mouse}{vid}{CaROIs{mouse}(term1)}),length(sbDataFullTrace{mouse}{vid}{BBBroi}));
                        CaBBBCorrs{mouse}{vid}(term1,BBBroi) = corr2(scDataFullTrace{mouse}{vid}{CaROIs{mouse}(term1)}(1:minLen),sbDataFullTrace{mouse}{vid}{BBBroi}(1:minLen));                       
                        CaBBBCorrs2{mouse}{term1,BBBroi}(vid) = CaBBBCorrs{mouse}{vid}(term1,BBBroi);                        
                        avCaBBBvidCorrs{mouse}(term1,BBBroi) = nanmean(CaBBBCorrs2{mouse}{term1,BBBroi}(vid));                        
                    elseif length(scDataFullTrace{mouse}{vid}{CaROIs{mouse}(term1)}) == length(sbDataFullTrace{mouse}{vid}{BBBroi})
                        CaBBBCorrs{mouse}{vid}(term1,BBBroi) = corr2(scDataFullTrace{mouse}{vid}{CaROIs{mouse}(term1)},sbDataFullTrace{mouse}{vid}{BBBroi});
                        CaBBBCorrs2{mouse}{term1,BBBroi}(vid) = CaBBBCorrs{mouse}{vid}(term1,BBBroi);
                        avCaBBBvidCorrs{mouse}(term1,BBBroi) = nanmean(CaBBBCorrs2{mouse}{term1,BBBroi}(vid));
                    end   
                elseif timeLagQ == 1
                    timeLagFrames = floor(timeLag*(FPSstack{mouse}));
                    if length(timeLagFrames:length(sbDataFullTrace{mouse}{vid}{BBBroi})-timeLagFrames) ~= length(scDataFullTrace{mouse}{vid}{CaROIs{mouse}(term1)})
                        CaBBBCorrs{mouse}{vid}(term1,BBBroi) = corr2(scDataFullTrace{mouse}{vid}{CaROIs{mouse}(term1)}(1:length(timeLagFrames:length(sbDataFullTrace{mouse}{vid}{BBBroi})-timeLagFrames)),sbDataFullTrace{mouse}{vid}{BBBroi}(timeLagFrames:length(sbDataFullTrace{mouse}{vid}{BBBroi})-timeLagFrames));
                        CaBBBCorrs2{mouse}{term1,BBBroi}(vid) = CaBBBCorrs{mouse}{vid}(term1,BBBroi);
                        avCaBBBvidCorrs{mouse}(term1,BBBroi) = nanmean(CaBBBCorrs2{mouse}{term1,BBBroi}(vid));                        
                    end 
                end                       
            end             
        end 
        %{
        % plot correlograms of 0 time lagged data 
        figure;
        imshow(CaBBBCorrs{mouse}{vid},[0,1]);
        ax = gca;
        ax.FontSize = 20;
        axis on
        yticks(1:length(CaROIs{mouse}))
        yticklabels(CaROIs{mouse})
        xticks(1:length(bDataFullTrace{mouse}{vid}))
        colorbar 
        truesize([700 900])
        ylabel('axon')
        xlabel('BBB ROI')
        if timeLagQ == 0 
            title(sprintf('Axon Ca-BBB Correlogram. Mouse %d. Vid %d. ',mouse,vid),'FontSize',20);
        elseif timeLagQ == 1 
            title(sprintf('Axon Ca-BBB Correlogram. Mouse %d. Vid %d. %.2f sec time lag. ',mouse,vid,timeLag),'FontSize',20);
        end 
        colormap default
        %}
    end
    if corrFigQ == 1 
        % plot correlograms of 0 time lagged data 
        figure;
        imshow(avCaBBBvidCorrs{mouse},[0,1]);
        ax = gca;
        ax.FontSize = 20;
        axis on
        yticks(1:length(CaROIs{mouse}))
        yticklabels(CaROIs{mouse})
        xticks(1:length(bDataFullTrace{mouse}{vid}))
        colorbar 
        truesize([700 900])
        ylabel('axon')
        xlabel('BBB ROI')
        if timeLagQ == 0 
            title(sprintf('Axon Ca-BBB Correlogram. Mouse %d. %.2f sec smoothing. ',mouse,filtTime),'FontSize',20);
        elseif timeLagQ == 1 
            title(sprintf('Axon Ca-BBB Correlogram. Mouse %d. %.2f sec time lag.  %.2f sec smoothing.',mouse,timeLag,filtTime),'FontSize',20);
        end 
        colormap default    
    end 
end 

% determine what Ca correlations are significant (correlation coefficient of 0.8 or greater)
minCorr = zeros(1,length(cDataFullTrace));
maxCorr = zeros(1,length(cDataFullTrace));
minCorrAxonsBBB = cell(1,length(cDataFullTrace));
maxCorrAxonsBBB = cell(1,length(cDataFullTrace));
for mouse = 1:length(cDataFullTrace)
    % find min and max correlated axons per mouse 
    minCorr(mouse) = (min(min(avCaBBBvidCorrs{mouse})));
    maxCorr(mouse) = (max(max(avCaBBBvidCorrs{mouse})));
    [r,c] = find(avCaBBBvidCorrs{mouse} == minCorr(mouse));
    minCorrAxonsBBB{1,mouse} = [CaROIs{mouse}(r);c];        
    minCorrAxonsBBB{2,mouse} = minCorr(mouse);  
    [r,c] = find(avCaBBBvidCorrs{mouse} == maxCorr(mouse));    
    maxCorrAxonsBBB{1,mouse} = [CaROIs{mouse}(r);c];
    maxCorrAxonsBBB{2,mouse} = maxCorr(mouse);
    % determine if any of the max correlations are significant 
    if maxCorrAxonsBBB{2,mouse} >= 0.8
        fprintf('Mouse %d shows significant correlation between axons.',mouse)
    end 
end 

%}
%% calcium peak raster plots and PSTHs for multiple animals at once 
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
relativeToMean = input('Input 1 if you want to plot spike rate relative to mean. Input 0 to plot raw spike rate. ');

%%
FPSstack2 = zeros(1,size(fileList,1));
fullRaster2 = cell(1,size(fileList,1));
totalPeakNums2 = cell(1,size(fileList,1));   
mean_ISIdiffsWholeExp_maxBin = cell(1,size(fileList,1));   
medISI = cell(1,size(fileList,1));  

for mouse = 1:size(fileList,1)
    
    MatFileName = fileList(mouse).name;
    load(MatFileName,'-regexp','^(?!indCaROIplotQ|allCaROIplotQ|winSec|trialQ|ITIq|trialLenThreshTime|histQ|ITIq2|termQ$)\w')
    
    winFrames = (winSec*FPSstack);
    % find peaks that are significant relative to the entire data set
    stdTrace = cell(1,length(vidList)); 
    sigPeaks2 = cell(1,length(vidList)); 
    sigLocs2 = cell(1,length(vidList)); 
    ISIdiffsWholeExp = cell(1,length(vidList));     
    ISIdiffsWholeExp_0to5sec = cell(1,length(vidList)); 
    ISIdiffsWholeExp_maxBin = cell(1,length(vidList));     
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
            
            % determine interspike intervals (by frame) throughout entire
            % experiment in seconds 
            ISIdiffsWholeExp{vid}{terminals(ccell)} = (diff(sigLocs2{vid}{terminals(ccell)}))/FPSstack;
            % keep only ISIs between 0 and 5 seconds 
            ISIdiffsWholeExp_0to5sec{vid}{terminals(ccell)} = ISIdiffsWholeExp{vid}{terminals(ccell)}(find(ISIdiffsWholeExp{vid}{terminals(ccell)} > 0 & ISIdiffsWholeExp{vid}{terminals(ccell)} < 5));
            
%             % plot ISI distribution per axon 
%             figure
%             histogram(ISIdiffsWholeExp{vid}{terminals(ccell)},100,'FaceColor','k')
%             hold all 
%             ax=gca;
%             ax.FontSize = 15;
%             ylabel('Number of Spikes')
%             xlabel('Inter-Spike Interval (sec)')
%             label = sprintf('Distribution of Interspike Intervals. Mouse %d. Axon %d.', mouse,terminals(ccell));
%             sgtitle(label,'FontSize',25);     

            % plot ISI distribution (of ISIs between 0 and 5 seconds) per axon
            figure
            hObj = histogram(ISIdiffsWholeExp_0to5sec{vid}{terminals(ccell)},10,'FaceColor','k');
            hold all 
            ax=gca;
            ax.FontSize = 15;
            ylabel('Number of Spikes')
            xlabel('Inter-Spike Interval (sec)')
            label = sprintf('Distribution of Interspike Intervals. Mouse %d. Axon %d.', mouse,terminals(ccell));
            sgtitle(label,'FontSize',25);     
            
            [M,I] = max(hObj.Values);
            binEdges = hObj.BinEdges;
            maxBinEdges = binEdges(I:I+1);
            % keep only ISIs between maxBinEdges
            ISIdiffsWholeExp_maxBin{vid}{terminals(ccell)} = ISIdiffsWholeExp{vid}{terminals(ccell)}(find(ISIdiffsWholeExp{vid}{terminals(ccell)} > maxBinEdges(1) & ISIdiffsWholeExp{vid}{terminals(ccell)} < maxBinEdges(2)));
            % determine mean value of the max bin in the histogram above
            mean_ISIdiffsWholeExp_maxBin{mouse}(vid,ccell) = mean(ISIdiffsWholeExp_maxBin{vid}{terminals(ccell)});
            % plot the mean value of the max bin on the histogram above 
            text(maxBinEdges(1),M-1,{mean_ISIdiffsWholeExp_maxBin{mouse}(vid,ccell)},'FontSize',20);
            
            % determine the median ISI per axon 
            medISI{mouse}(vid,ccell) = median(ISIdiffsWholeExp{vid}{terminals(ccell)});           
        end 
    end 
    
%     % plot median ISI (of each axon) distribution
%     figure
%     histogram(medISI{mouse},50,'FaceColor','k')
%     hold all 
%     ax=gca;
%     ax.FontSize = 15;
%     ylabel('Number of Axons')
%     xlabel('Median Inter-Spike Interval (sec)')
%     label = sprintf('Distribution of Median Interspike Intervals. Mouse %d.', mouse);
%     sgtitle(label,'FontSize',25);     
% 
%     % plot mean value of max bin ISI (of each axon) distribution
%     figure
%     histogram(mean_ISIdiffsWholeExp_maxBin{mouse},50,'FaceColor','k')
%     hold all 
%     ax=gca;
%     ax.FontSize = 15;
%     ylabel('Number of Axons')
%     xlabel('Median Inter-Spike Interval (sec)')
%     label = sprintf('Distribution of Mean Interspike Interval for Most Common Histogram Bin. Mouse %d.', mouse);
%     sgtitle(label,'FontSize',25);   

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
                if relativeToMean == 1 
                    % determine the mean peak rate 
                    meanNumPeaks{(terminals == termList(term))}(tType) = nanmean(avTermNumPeaks{(terminals == termList(term))}{tType}); 
                    % divide by the mean peak rate to show the variation in spike
                    % rates from the mean 
                    avTermNumPeaks{(terminals == termList(term))}{tType} = avTermNumPeaks{(terminals == termList(term))}{tType}/meanNumPeaks{(terminals == termList(term))}(tType);                                  
                end               
                % sort data 
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
    
    % THIS IS MATHMATICALLY DOES NOT DO WHAT I WANT, BUT WORKS PROGRAMATICALLY 
    % plots ISI distribution per mouse (averaged across trials) 
    %{
    % determine ISI 
    ISIdiffs = cell(1,length(bDataFullTrace));
    ISIframeMatrix = cell(1,length(termList));
    ISIs = cell(1,length(termList));
    avISIs = cell(1,length(sigPeaks{vid}{term}));
    for vid = 1:length(bDataFullTrace)
        for term = 1:length(termList)   
            for tType = 1:length(sigPeaks{vid}{term})
                count = 1 ;
                for trial = 1:length(trialList{vid})
                    if length(sigPeaks{vid}{(terminals == termList(term))}{tType}) >= trialList{vid}(trial)
                        if isempty(correctedSigLocs{vid}{(terminals == termList(term))}{tType}{trial}) == 0

                            % spikes already found in correctedSigLocs 
                            % get diff of spike locations (this is the
                            % ISI by frame 
                            ISIdiffs{(terminals == termList(term))}{tType}{count} = diff(correctedSigLocs{vid}{(terminals == termList(term))}{tType}{trial});
                            % create matrix of ISI lengths in correct frame
                            if isempty(ISIdiffs{(terminals == termList(term))}{tType}{count}) == 0 
                                for peak = 1:length(ISIdiffs{(terminals == termList(term))}{tType}{count})                                    
                                    ISIframeMatrix{(terminals == termList(term))}{tType}(count,correctedSigLocs{vid}{(terminals == termList(term))}{tType}{trial}(peak):correctedSigLocs{vid}{(terminals == termList(term))}{tType}{trial}(peak+1)) = ISIdiffs{(terminals == termList(term))}{tType}{count}(peak);
                                end 
                            end    
                            count = count + 1;
                        end                        
                        
                    end 
                end 
                % fill out the empty rows 
                ISIframeMatrix{(terminals == termList(term))}{tType}(size(ISIframeMatrix{(terminals == termList(term))}{tType},1)+1:size(raster2{(terminals == termList(term))}{tType},1),:) = 0;                
                % average ISIframeMatrix into bins as was done for numpeaks
                for win = 1:windows
                    if win == 1 
                        ISIs{(terminals == termList(term))}{tType}(:,win) = sum(ISIframeMatrix{(terminals == termList(term))}{tType}(:,1:winFrames),2);
                    elseif win > 1 
                        if ((win-1)*winFrames)+1 < size(raster2{(terminals == termList(term))}{tType},2) && winFrames*win < size(raster2{(terminals == termList(term))}{tType},2)
                            ISIs{(terminals == termList(term))}{tType}(:,win) = sum(ISIframeMatrix{(terminals == termList(term))}{tType}(:,((win-1)*winFrames)+1:winFrames*win),2);
                        end 
                    end             
                end 
                               
            end 
        end 
    end    
    % determine the average ISI across trials 
    for term = 1:length(termList)   
        for tType = 1:length(sigPeaks{vid}{term})            
            avISIs{tType}(term,:) = nanmean(ISIs{(terminals == termList(term))}{tType},1); 
        end 
    end 
    
    %plot ISI for all terminals averaged
    avISI = cell(1,length(sigPeaks{1}{terminals == termList(term)}));
    for tType = 1:length(sigPeaks{1}{terminals == termList(term)})
        % replace rows of zeros with NaNs 
        avISIs{tType}(any(avISIs{tType},2) == 0,:) = NaN;
        % convert avISIs from frame to seconds and sort into the
        % same array for averaging across terminals 
        avISIs{tType} = avISIs{tType}/FPSstack;    
        avISI{tType} = nanmean(avISIs{tType},1);
   
        figure
        bar(avISI{tType},'k')
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
        ylabel('Inter-Spike Interval (sec)')
        label = sprintf('Inter-Spike Interval per %0.2f sec. Mouse %d.',winSec, mouse);
        sgtitle(label,'FontSize',25);        
    end                      
    %}

    clearvars -except FPSstack2 fullRaster2 totalPeakNums2 etaDir fileList indCaROIplotQ allCaROIplotQ winSec trialQ ITIq trialLenThreshTime histQ ITIq2 termQ mean_ISIdiffsWholeExp_maxBin medISI relativeToMean         

end 

%%
    
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

ISImedAndModeQ = input('Input 1 to plot the distribution of median and mode ISIs. ');
if ISImedAndModeQ == 1
    % put data into the same array 
    count = 1;
    mean_ISIdiffsWholeExp_maxBin_array = zeros(1,1);
    medISI_array = zeros(1,1);
    for mouse = 1:size(fileList,1)
        for axon = 1:length(mean_ISIdiffsWholeExp_maxBin{mouse})
            mean_ISIdiffsWholeExp_maxBin_array(count) = mean_ISIdiffsWholeExp_maxBin{mouse}(axon);
            medISI_array(count) = medISI{mouse}(axon);
            count = count + 1;
        end        
    end 

    % plot highest probability ISI distributions for all mice together
    figure
    histogram(mean_ISIdiffsWholeExp_maxBin_array,10,'FaceColor','k');
    hold all 
    ax=gca;
    ax.FontSize = 15;
    ylabel('Number of Axons')
    xlabel('Inter-Spike Interval (sec)')
    label = 'Distribution of Highest Probability Interspike Intervals Across Mice';
    sgtitle(label,'FontSize',25);     
    
    % plot median ISI distributions for all mice together
    figure
    histogram(medISI_array,10,'FaceColor','k');
    hold all 
    ax=gca;
    ax.FontSize = 15;
    ylabel('Number of Axons')
    xlabel('Inter-Spike Interval (sec)')
    label = 'Distribution of Median Interspike Intervals Across Mice';
    sgtitle(label,'FontSize',25);  
end 
% clearvars

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
%% STA: find calcium peaks per terminal across entire experiment, sort data
% based on ca peak location, smooth and normalize to baseline period, and
% plot calcium spike triggered averages (per mouse - optimized for batch
% processing, saves the data out per mouse)
%{
% get the data if it already isn't in the workspace 
workspaceQ = input('Input 1 if batch data is already in the workspace. Input 0 otherwise. ');
if workspaceQ == 1 
    dataDir = cell(1,mouseNum);
    for mouse = 1:mouseNum
        dirLabel = sprintf('WHERE DO YOU WANT TO SAVE OUT THE DATA FOR MOUSE #%d? ',mouse);
        dataDir{mouse} = uigetdir('*.*',dirLabel);
    end 
elseif workspaceQ == 0 
    dataOrgQ = input('Input 1 if the batch processing data is saved in one .mat file. Input 0 if you need to open multiple .mat files (one per animal). ');
    if dataOrgQ == 1 
        dirLabel = 'WHERE IS THE BATCH DATA? ';
        dataDir2 = uigetdir('*.*',dirLabel);
        cd(dataDir2); % go to the right directory 
        uiopen('*.mat'); % get data          
        dataDir = cell(1,mouseNum);
        for mouse = 1:mouseNum
            dirLabel = sprintf('WHERE DO YOU WANT TO SAVE OUT THE DATA FOR MOUSE #%d? ',mouse);
            dataDir{mouse} = uigetdir('*.*',dirLabel);
        end 
    elseif dataOrgQ == 0
        mouseNum = input('How many mice are there? ');
        dataDir2 = cell(1,mouseNum);
        dataDir = cell(1,mouseNum);
        bDataFullTrace1 = cell(1,mouseNum);
        cDataFullTrace1 = cell(1,mouseNum);
        vDataFullTrace1 = cell(1,mouseNum);
        terminals1 = cell(1,mouseNum);
        state_start_f1 = cell(1,mouseNum);
        TrialTypes1 = cell(1,mouseNum);
        state_end_f1 = cell(1,mouseNum);
        trialLengths1 = cell(1,mouseNum);
        FPSstack1 = cell(1,mouseNum);
        vidList1 = cell(1,mouseNum);
        for mouse = 1:mouseNum
            dirLabel = sprintf('WHERE IS THE DATA FOR MOUSE #%d? ',mouse);
            dataDir2{mouse} = uigetdir('*.*',dirLabel);
            cd(dataDir2{mouse}); % go to the right directory 
            uiopen('*.mat'); % get data  
            if BBBQ == 1     
                bDataFullTrace1{mouse} = bDataFullTrace;
            end 
            if CAQ == 1
                cDataFullTrace1{mouse} = cDataFullTrace;
                terminals1{mouse} = terminals;
            end 
            if VWQ == 1 
                vDataFullTrace1{mouse} = vDataFullTrace;
            end 
            state_start_f1{mouse} = state_start_f;            
%             TrialTypes1{mouse} = TrialTypes;
            state_end_f1{mouse} = state_end_f;              
            trialLengths1{mouse} = trialLengths;      
            FPSstack1{mouse} = FPSstack;             
            vidList1{mouse} = vidList;     
            dirLabel = sprintf('WHERE DO YOU WANT TO SAVE OUT THE DATA FOR MOUSE #%d? ',mouse);
            dataDir{mouse} = uigetdir('*.*',dirLabel);   
        end 
        clear bDataFullTrace cDataFullTrace vDataFullTrace terminals state_start_f TrialTypes state_end_f trialLengths FPSstack vidList
        bDataFullTrace = bDataFullTrace1;
        cDataFullTrace = cDataFullTrace1;
        vDataFullTrace = vDataFullTrace1;
        terminals = terminals1;
        state_start_f = state_start_f1;
%         TrialTypes = TrialTypes1;
        state_end_f = state_end_f1;
        trialLengths = trialLengths1;
        FPSstack = FPSstack1;
        vidList = vidList1;
    end 
end 

%%
optoQ = input('Input 1 if this is opto data. Input 0 if this is behavior data. ');
if optoQ == 1
    tTypeQ = input('Input 1 to separate data by light condition. Input 0 otherwise. ');
end 

dataSaveQ = input('Input 1 to save the data out. '); 
for mouse = 1:mouseNum
    dir1 = dataDir{mouse};   
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
    if tTypeQ == 1
        %tTypeSigLocs{1} = blue light
        %tTypeSigLocs{2} = red light
        %tTypeSigLocs{3} = ISI
        clear tTypeSigLocs
        tTypeSigLocs = cell(1,length(vidList{mouse}));
        for ccell = 1:length(terminals{mouse})
            count = 1;
            count1 = 1;
            count2 = 1;
            for vid = 1:length(vidList{mouse})       
                for peak = 1:length(sigLocs{vid}{terminals{mouse}(ccell)})  
                    %if the peak location is less than all of the
                    %state start frames 
                    if all(sigLocs{vid}{terminals{mouse}(ccell)}(peak) < state_start_f{mouse}{vid})
                        %than that peak is before the first stim and is in an
                        %ISI period 
                        tTypeSigLocs{vid}{terminals{mouse}(ccell)}{3}(count) = sigLocs{vid}{terminals{mouse}(ccell)}(peak); 
                        count = count + 1;
                    %if the peak location is not in the first ISI period 
                    elseif sigLocs{vid}{terminals{mouse}(ccell)}(peak) > state_start_f{mouse}{vid}(1)-1                                        
                        %find the trial start frames that are < current peak
                        %location 
                        trials = find(state_start_f{mouse}{vid} < sigLocs{vid}{terminals{mouse}(ccell)}(peak)); 
                        trial = max(trials);
                        %if the current peak location is happening during the
                        %stim
                        if sigLocs{vid}{terminals{mouse}(ccell)}(peak) < state_end_f{mouse}{vid}(trial)
                            %sort into the correct cell depending on whether
                            %the light is blue or red                        
                            if TrialTypes{mouse}{vid}(trial,2) == 1                            
                                tTypeSigLocs{vid}{terminals{mouse}(ccell)}{1}(count1) = sigLocs{vid}{terminals{mouse}(ccell)}(peak); 
                                count1 = count1 + 1;                      
                            elseif TrialTypes{mouse}{vid}(trial,2) == 2 
                                tTypeSigLocs{vid}{terminals{mouse}(ccell)}{2}(count2) = sigLocs{vid}{terminals{mouse}(ccell)}(peak); 
                                count2 = count2 + 1;
                            end 
                        %if the current peak location is happening after the
                        %stim (in the next ISI)
                        elseif sigLocs{vid}{terminals{mouse}(ccell)}(peak) > state_end_f{mouse}{vid}(trial)
                            %sort into the correct cell depending on whether
                            %the light is blue or red 
                            tTypeSigLocs{vid}{terminals{mouse}(ccell)}{3}(count) = sigLocs{vid}{terminals{mouse}(ccell)}(peak); 
                            count = count + 1; 
                        end 
                    end 
                end
            end 
        end 

        %remove all zeros 
        for vid = 1:length(vidList{mouse})
            for ccell = 1:length(terminals{mouse})    
                for per = 1:3
                    if isempty (tTypeSigLocs{vid}{terminals{mouse}(ccell)}{per}) == 0 
    %                 [~,zeroLocs_tTypeSigLocs] = find(~tTypeSigLocs{vid}{terminals{mouse}(ccell)}{per});
    %                 tTypeSigLocs2{vid}{terminals{mouse}(ccell)}{per} = NaN;          
                        tTypeSigLocs{vid}{terminals{mouse}(ccell)}{per}(tTypeSigLocs{vid}{terminals{mouse}(ccell)}{per} == 0) = [];
                    end 
                end 
            end 
        end 
    end 
    
    % STA: sort data based on ca peak location 
    % when tTypeQ == 0, you can select what trials to plot from and generate
    % figures for spikes that occur throughout the entire experiment, during
    % the wait period, the stim, and the reward (this was made for analyzing
    % behavior data)   

    windSize = 24;
    if tTypeQ == 0 
        if mouse == 1 
            trialQ = input('Input 1 to plot spikes from specific trials. Input 0 otherwise. ');
            if optoQ == 0 
                bPerQ = input('Input 1 to plot STAs for spikes at different points in the task. Input 0 otherwise. ');
            elseif optoQ == 1
                bPerQ = 0;
            end 
        end 

        if trialQ == 1
            for vid = 1:length(vidList{mouse})
                trials{mouse}{vid} = input(sprintf('Input what trials you want to plot spikes from for mouse #%d vid #%d. ',mouse,vid));
            end 
        elseif trialQ == 0
            for vid = 1:length(vidList{mouse})
                trials{mouse}{vid} = 1:length(state_start_f{mouse}{vid});
            end 
        end 
        if bPerQ == 1
            if mouse == 1 
                rewPerLen = input('How long (in sec) is the reward period? ');
            end 
            rewPerFlen = floor(rewPerLen*FPSstack{mouse});
            %make a lists of all frames where the stim and rew occur
            stimFrames2 = cell(1,length(vidList{mouse}));
            rewFrames2 = cell(1,length(vidList{mouse}));
            for vid = 1:length(vidList{mouse})
                for trial = 1:length(trials{mouse}{vid})
                    stimFrames2{vid}{trials{mouse}{vid}(trial)} = state_start_f{mouse}{vid}(trials{mouse}{vid}(trial)):state_end_f{mouse}{vid}(trials{mouse}{vid}(trial));
                    rewFrames2{vid}{trials{mouse}{vid}(trial)} = state_end_f{mouse}{vid}(trials{mouse}{vid}(trial))+1:state_end_f{mouse}{vid}(trials{mouse}{vid}(trial))+rewPerFlen+1;
                end 
                stimFrames = arrayfun(@(row) horzcat(stimFrames2{vid}{row, :}), 1:size(stimFrames2{vid}, 1), 'UniformOutput', false);
                rewFrames = arrayfun(@(row) horzcat(rewFrames2{vid}{row, :}), 1:size(rewFrames2{vid}, 1), 'UniformOutput', false);
            end 
        end 
        sortedCdata = cell(1,length(vidList{mouse}));
        sortedBdata = cell(1,length(vidList{mouse}));
        sortedVdata = cell(1,length(vidList{mouse}));
        for vid = 1:length(vidList{mouse})
            for ccell = 1:length(terminals{mouse})
                for peak = 1:length(sigLocs{vid}{terminals{mouse}(ccell)})            
                    if sigLocs{vid}{terminals{mouse}(ccell)}(peak)-floor((windSize/2)*FPSstack{mouse}) > 0 && sigLocs{vid}{terminals{mouse}(ccell)}(peak)+floor((windSize/2)*FPSstack{mouse}) < length(cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)})                
                        start = sigLocs{vid}{terminals{mouse}(ccell)}(peak)-floor((windSize/2)*FPSstack{mouse});
                        stop = sigLocs{vid}{terminals{mouse}(ccell)}(peak)+floor((windSize/2)*FPSstack{mouse});                
                        if start == 0 
                            start = 1 ;
                            stop = start + floor((windSize/2)*FPSstack{mouse}) + floor((windSize/2)*FPSstack{mouse});
                        end        
                        if BBBQ == 1
                            for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                                if trialQ == 0
                                    if bPerQ == 0 
                                        sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{1}(peak,:) = bDataFullTrace{mouse}{vid}{BBBroi}(start:stop);
                                    elseif bPerQ == 1    
                                        % create an STA for peaks regardless of
                                        % when they occur 
                                        sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{1}(peak,:) = bDataFullTrace{mouse}{vid}{BBBroi}(start:stop);
                                        %if the peak occured during the
                                        %stimulus 
                                        if ismember(sigLocs{vid}{terminals{mouse}(ccell)}(peak),stimFrames{vid}) == 1 
                                            sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{2}(peak,:) = bDataFullTrace{mouse}{vid}{BBBroi}(start:stop);
                                        %if the peak occured during the reward
                                        elseif ismember(sigLocs{vid}{terminals{mouse}(ccell)}(peak),rewFrames{vid}) == 1 
                                            sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{3}(peak,:) = bDataFullTrace{mouse}{vid}{BBBroi}(start:stop);
                                        %if the peak occured during the ITI
                                        else
                                            sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{4}(peak,:) = bDataFullTrace{mouse}{vid}{BBBroi}(start:stop);
                                        end 
                                    end 
                                elseif trialQ == 1 
                                    if sigLocs{vid}{terminals{mouse}(ccell)}(peak) > state_start_f{mouse}{vid}(trials{mouse}{vid}(1)) && sigLocs{vid}{terminals{mouse}(ccell)}(peak) < state_end_f{mouse}{vid}(trials{mouse}{vid}(end))
                                        if bPerQ == 0 
                                            sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{1}(peak,:) = bDataFullTrace{mouse}{vid}{BBBroi}(start:stop);
                                        elseif bPerQ == 1    
                                            % create an STA for peaks regardless of
                                            % when they occur 
                                            sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{1}(peak,:) = bDataFullTrace{mouse}{vid}{BBBroi}(start:stop);
                                            %if the peak occured during the
                                            %stimulus 
                                            if ismember(sigLocs{vid}{terminals{mouse}(ccell)}(peak),stimFrames{vid}) == 1 
                                                sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{2}(peak,:) = bDataFullTrace{mouse}{vid}{BBBroi}(start:stop);
                                            %if the peak occured during the reward
                                            elseif ismember(sigLocs{vid}{terminals{mouse}(ccell)}(peak),rewFrames{vid}) == 1 
                                                sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{3}(peak,:) = bDataFullTrace{mouse}{vid}{BBBroi}(start:stop);
                                            %if the peak occured during the ITI
                                            else
                                                sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{4}(peak,:) = bDataFullTrace{mouse}{vid}{BBBroi}(start:stop);
                                            end 
                                        end 
                                    end 
                                end 
                            end 
                        end 
                        if trialQ == 0
                            if bPerQ == 0 
                                sortedCdata{vid}{terminals{mouse}(ccell)}{1}(peak,:) = cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}(start:stop);
                            elseif bPerQ == 1    
                                % create an STA for peaks regardless of
                                % when they occur 
                                sortedCdata{vid}{terminals{mouse}(ccell)}{1}(peak,:) = cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}(start:stop);
                                %if the peak occured during the
                                %stimulus 
                                if ismember(sigLocs{vid}{terminals{mouse}(ccell)}(peak),stimFrames{vid}) == 1 
                                    sortedCdata{vid}{terminals{mouse}(ccell)}{2}(peak,:) = cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}(start:stop);
                                %if the peak occured during the reward
                                elseif ismember(sigLocs{vid}{terminals{mouse}(ccell)}(peak),rewFrames{vid}) == 1 
                                    sortedCdata{vid}{terminals{mouse}(ccell)}{3}(peak,:) = cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}(start:stop);
                                %if the peak occured during the ITI
                                else
                                    sortedCdata{vid}{terminals{mouse}(ccell)}{4}(peak,:) = cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}(start:stop);
                                end 
                            end 
                        elseif trialQ == 1
                            if sigLocs{vid}{terminals{mouse}(ccell)}(peak) > state_start_f{mouse}{vid}(trials{mouse}{vid}(1)) && sigLocs{vid}{terminals{mouse}(ccell)}(peak) < state_end_f{mouse}{vid}(trials{mouse}{vid}(end))
                                if bPerQ == 0 
                                    sortedCdata{vid}{terminals{mouse}(ccell)}{1}(peak,:) = cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}(start:stop);
                                elseif bPerQ == 1    
                                    % create an STA for peaks regardless of
                                    % when they occur 
                                    sortedCdata{vid}{terminals{mouse}(ccell)}{1}(peak,:) = cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}(start:stop);
                                    %if the peak occured during the
                                    %stimulus 
                                    if ismember(sigLocs{vid}{terminals{mouse}(ccell)}(peak),stimFrames{vid}) == 1 
                                        sortedCdata{vid}{terminals{mouse}(ccell)}{2}(peak,:) = cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}(start:stop);
                                    %if the peak occured during the reward
                                    elseif ismember(sigLocs{vid}{terminals{mouse}(ccell)}(peak),rewFrames{vid}) == 1 
                                        sortedCdata{vid}{terminals{mouse}(ccell)}{3}(peak,:) = cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}(start:stop);
                                    %if the peak occured during the ITI
                                    else
                                        sortedCdata{vid}{terminals{mouse}(ccell)}{4}(peak,:) = cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}(start:stop);
                                    end 
                                end 
                            end 
                        end 
                        if VWQ == 1
                            for VWroi = 1:length(vDataFullTrace{mouse}{1})
                                if trialQ == 0
                                    if bPerQ == 0 
                                        sortedVdata{vid}{VWroi}{terminals{mouse}(ccell)}{1}(peak,:) = vDataFullTrace{mouse}{vid}{VWroi}(start:stop);
                                    elseif bPerQ == 1    
                                        % create an STA for peaks regardless of
                                        % when they occur 
                                        sortedVdata{vid}{VWroi}{terminals{mouse}(ccell)}{1}(peak,:) = vDataFullTrace{mouse}{vid}{VWroi}(start:stop);
                                        %if the peak occured during the
                                        %stimulus 
                                        if ismember(sigLocs{vid}{terminals{mouse}(ccell)}(peak),stimFrames{vid}) == 1 
                                            sortedVdata{vid}{VWroi}{terminals{mouse}(ccell)}{2}(peak,:) = vDataFullTrace{mouse}{vid}{VWroi}(start:stop);
                                        %if the peak occured during the reward
                                        elseif ismember(sigLocs{vid}{terminals{mouse}(ccell)}(peak),rewFrames{vid}) == 1 
                                            sortedVdata{vid}{VWroi}{terminals{mouse}(ccell)}{3}(peak,:) = vDataFullTrace{mouse}{vid}{VWroi}(start:stop);
                                        %if the peak occured during the ITI
                                        else
                                            sortedVdata{vid}{VWroi}{terminals{mouse}(ccell)}{4}(peak,:) = vDataFullTrace{mouse}{vid}{VWroi}(start:stop);
                                        end 
                                    end 
                                elseif trialQ == 1
                                    if sigLocs{vid}{terminals{mouse}(ccell)}(peak) > state_start_f{mouse}{vid}(trials{mouse}{vid}(1)) && sigLocs{vid}{terminals{mouse}(ccell)}(peak) < state_end_f{mouse}{vid}(trials{mouse}{vid}(end))
                                        if bPerQ == 0 
                                            sortedVdata{vid}{VWroi}{terminals{mouse}(ccell)}{1}(peak,:) = vDataFullTrace{mouse}{vid}{VWroi}(start:stop);
                                        elseif bPerQ == 1    
                                            % create an STA for peaks regardless of
                                            % when they occur 
                                            sortedVdata{vid}{VWroi}{terminals{mouse}(ccell)}{1}(peak,:) = vDataFullTrace{mouse}{vid}{VWroi}(start:stop);
                                            %if the peak occured during the
                                            %stimulus 
                                            if ismember(sigLocs{vid}{terminals{mouse}(ccell)}(peak),stimFrames{vid}) == 1 
                                                sortedVdata{vid}{VWroi}{terminals{mouse}(ccell)}{2}(peak,:) = vDataFullTrace{mouse}{vid}{VWroi}(start:stop);
                                            %if the peak occured during the reward
                                            elseif ismember(sigLocs{vid}{terminals{mouse}(ccell)}(peak),rewFrames{vid}) == 1 
                                                sortedVdata{vid}{VWroi}{terminals{mouse}(ccell)}{3}(peak,:) = vDataFullTrace{mouse}{vid}{VWroi}(start:stop);
                                            %if the peak occured during the ITI
                                            else
                                                sortedVdata{vid}{VWroi}{terminals{mouse}(ccell)}{4}(peak,:) = vDataFullTrace{mouse}{vid}{VWroi}(start:stop);
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
        for vid = 1:length(vidList{mouse})
            for ccell = 1:length(terminals{mouse}) 
                for per = 1:length(sortedCdata{vid}{terminals{mouse}(ccell)})
                    if BBBQ == 1
                        for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                            nonZeroRowsB = all(sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{per} == 0,2);
                            sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{per}(nonZeroRowsB,:) = NaN;
                        end 
                    end 
                    nonZeroRowsC = all(sortedCdata{vid}{terminals{mouse}(ccell)}{per} == 0,2);
                    sortedCdata{vid}{terminals{mouse}(ccell)}{per}(nonZeroRowsC,:) = NaN;
                    if VWQ == 1
                        for VWroi = 1:length(vDataFullTrace{mouse}{1})
                            nonZeroRowsV = all(sortedVdata{vid}{VWroi}{terminals{mouse}(ccell)}{per} == 0,2);
                            sortedVdata{vid}{VWroi}{terminals{mouse}(ccell)}{per}(nonZeroRowsV,:) = NaN;
                        end 
                    end 
                end 
            end 
        end 

    elseif tTypeQ == 1 
        %sort C,B,V calcium peak time locked data (into different categories depending on whether a light was on and color light) 
        sortedCdata = cell(1,length(vidList{mouse}));
        sortedBdata = cell(1,length(vidList{mouse}));
        sortedVdata = cell(1,length(vidList{mouse}));
        for vid = 1:length(vidList{mouse})
            for ccell = 1:length(terminals{mouse})
                for per = 1:length(sortedCdata{vid}{terminals{mouse}(ccell)})                               
                    for peak = 1:length(tTypeSigLocs{vid}{terminals{mouse}(ccell)}{per})                                        
                        if tTypeSigLocs{vid}{terminals{mouse}(ccell)}{per}(peak)-floor((windSize/2)*FPSstack{mouse}) > 0 && tTypeSigLocs{vid}{terminals{mouse}(ccell)}{per}(peak)+floor((windSize/2)*FPSstack{mouse}) < length(cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)})                                     
                            start = tTypeSigLocs{vid}{terminals{mouse}(ccell)}{per}(peak)-floor((windSize/2)*FPSstack{mouse});
                            stop = tTypeSigLocs{vid}{terminals{mouse}(ccell)}{per}(peak)+floor((windSize/2)*FPSstack{mouse});                
                            if start == 0 
                                start = 1 ;
                                stop = start + floor((windSize/2)*FPSstack{mouse}) + floor((windSize/2)*FPSstack{mouse});
                            end     
                            if BBBQ == 1
                                for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                                    sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{per}(peak,:) = bDataFullTrace{mouse}{vid}{BBBroi}(start:stop);
                                end 
                            end 
                            sortedCdata{vid}{terminals{mouse}(ccell)}{per}(peak,:) = cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)}(start:stop);
                            if VWQ == 1
                                for VWroi = 1:length(vDataFullTrace{mouse}{1})
                                    sortedVdata{vid}{VWroi}{terminals{mouse}(ccell)}{per}(peak,:) = vDataFullTrace{mouse}{vid}{VWroi}(start:stop);
                                end 
                            end 
                        end 
                    end 
                end 
            end 
        end  
    end     

    % STA: smooth and normalize to baseline period
    baselineTime = input('How many seconds (pre-spike) do you want to normalize to? '); % baselineTime used to = 5;
    if tTypeQ == 0     
        %find the BBB traces that increase after calcium peak onset (changePt) 
        % THIS CODE LIKELY NEEDS TO BE PUT AFTER THE SMOOTHING AND
        % NORMALIZING 
        %{
        SNBdataPeaks_IncAfterCa = cell(1,length(vidList{mouse}));
        nonWeighted_SNBdataPeaks_IncAfterCa = cell(1,length(vidList{mouse}));
        SNBdataPeaks_NotIncAfterCa = cell(1,length(vidList{mouse}));
        nonWeighted_SNBdataPeaks_NotIncAfterCa = cell(1,length(vidList{mouse}));
        for vid = 1:length(vidList{mouse})
            for ccell = 1:length(terminals{mouse})   
                count1 = 1;
                count2 = 1;
                for peak = 1:size(NBdataPeaks{vid}{terminals{mouse}(ccell)},1)
                    %if pre changePt mean is less than post changePt mean 
                    if mean(SNBdataPeaks{vid}{terminals{mouse}(ccell)}(peak,1:changePt)) < mean(SNBdataPeaks{vid}{terminals{mouse}(ccell)}(peak,changePt:end))
                        SNBdataPeaks_IncAfterCa{vid}{terminals{mouse}(ccell)}(count1,:) = SNBdataPeaks{vid}{terminals{mouse}(ccell)}(peak,:);                              
                        nonWeighted_SNBdataPeaks_IncAfterCa{vid}{terminals{mouse}(ccell)}(count1,:) = SNonWeightedBdataPeaks{vid}{terminals{mouse}(ccell)}(peak,:);
                        count1 = count1+1;
                    %find the traces that do not increase after calcium peak onset 
                    elseif mean(SNBdataPeaks{vid}{terminals{mouse}(ccell)}(peak,1:changePt)) >= mean(SNBdataPeaks{vid}{terminals{mouse}(ccell)}(peak,changePt:end))
                        SNBdataPeaks_NotIncAfterCa{vid}{terminals{mouse}(ccell)}(count2,:) = SNBdataPeaks{vid}{terminals{mouse}(ccell)}(peak,:);
                        nonWeighted_SNBdataPeaks_NotIncAfterCa{vid}{terminals{mouse}(ccell)}(count2,:) = SNonWeightedBdataPeaks{vid}{terminals{mouse}(ccell)}(peak,:);
                        count2 = count2+1;
                    end 
                end 
            end 
        end 

        SNBdataPeaks_IncAfterCa_2 = cell(1,length(vidList{mouse}));
        SNBdataPeaks_NotIncAfterCa_2 = cell(1,length(vidList{mouse}));
        AVSNBdataPeaks = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
        AVSNBdataPeaksNotInc = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
        %average the BBB traces that increase after calcium peak onset and those
        %that don't
        for vid = 1:length(vidList{mouse})
            for ccell = 1:length(terminals{mouse})
                if terminals{mouse}(ccell) <= length(SNBdataPeaks_IncAfterCa{vid}) 
                    if isempty(SNBdataPeaks_IncAfterCa{vid}{terminals{mouse}(ccell)}) == 0 
                        SNBdataPeaks_IncAfterCa_2{terminals{mouse}(ccell)}(vid,:) = mean(SNBdataPeaks_IncAfterCa{vid}{terminals{mouse}(ccell)},1);  
                        SNBdataPeaks_NotIncAfterCa_2{terminals{mouse}(ccell)}(vid,:) = mean(SNBdataPeaks_NotIncAfterCa{vid}{terminals{mouse}(ccell)},1); 
                    end            
                end
                %find all 0 rows and replace with NaNs
                zeroRows = all(SNBdataPeaks_IncAfterCa_2{terminals{mouse}(ccell)} == 0,2);
                SNBdataPeaks_IncAfterCa_2{terminals{mouse}(ccell)}(zeroRows,:) = NaN; 
                zeroRowsNotInc = all(SNBdataPeaks_NotIncAfterCa_2{terminals{mouse}(ccell)} == 0,2);
                SNBdataPeaks_NotIncAfterCa_2{terminals{mouse}(ccell)}(zeroRowsNotInc,:) = NaN; 
                %create average trace per terminal
                AVSNBdataPeaks{terminals{mouse}(ccell)} = nansum(SNBdataPeaks_IncAfterCa_2{terminals{mouse}(ccell)},1);
                AVSNBdataPeaksNotInc{terminals{mouse}(ccell)} = nansum(SNBdataPeaks_NotIncAfterCa_2{terminals{mouse}(ccell)},1);
            end 
        end 
        %}
        
        %smoothing option
        if mouse == 1 
            smoothQ = input('Input 0 to plot non-smoothed data. Input 1 to plot smoothed data. ');
        end         
        if smoothQ == 0 
            if BBBQ == 1
                SBdataPeaks = sortedBdata;
            end 
            SCdataPeaks = sortedCdata;
            if VWQ == 1
                SVdataPeaks = sortedVdata;
            end 
        elseif smoothQ == 1
            if mouse == 1 
                filtTime = input('How many seconds do you want to smooth your data by? ');
            end             
            SBdataPeaks = cell(1,length(vidList{mouse}));
    %         SNCdataPeaks = cell(1,length(vidList{mouse}));
            SVdataPeaks = cell(1,length(vidList{mouse}));
            SCdataPeaks = sortedCdata;
            for vid = 1:length(vidList{mouse})
                for ccell = 1:length(terminals{mouse})
                    for per = 1:length(sortedCdata{vid}{terminals{mouse}(ccell)})
        %                 [sC_Data] = MovMeanSmoothData(sortedCdata{vid}{terminals{mouse}(ccell)},filtTime,FPSstack{mouse});
        %                 SCdataPeaks{vid}{terminals{mouse}(ccell)} = sC_Data; 
                        if BBBQ == 1
                            for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                                [sB_Data] = MovMeanSmoothData(sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{per},filtTime,FPSstack{mouse});
                                SBdataPeaks{vid}{BBBroi}{terminals{mouse}(ccell)}{per} = sB_Data;
                                %remove rows full of 0s if there are any b = a(any(a,2),:)
                                SBdataPeaks{vid}{BBBroi}{terminals{mouse}(ccell)}{per} = SBdataPeaks{vid}{BBBroi}{terminals{mouse}(ccell)}{per}(any(SBdataPeaks{vid}{BBBroi}{terminals{mouse}(ccell)}{per},2),:);
                            end
                        end 
                        if VWQ == 1
                            for VWroi = 1:length(vDataFullTrace{mouse}{1})
                                [sV_Data] = MovMeanSmoothData(sortedVdata{vid}{VWroi}{terminals{mouse}(ccell)}{per},filtTime,FPSstack{mouse});
                                SVdataPeaks{vid}{VWroi}{terminals{mouse}(ccell)}{per} = sV_Data;
                                %remove rows full of 0s if there are any b = a(any(a,2),:)
                                SVdataPeaks{vid}{VWroi}{terminals{mouse}(ccell)}{per} = SVdataPeaks{vid}{VWroi}{terminals{mouse}(ccell)}{per}(any(SVdataPeaks{vid}{VWroi}{terminals{mouse}(ccell)}{per},2),:);
                            end 
                        end 
                        %remove rows full of 0s if there are any b = a(any(a,2),:)
                        SCdataPeaks{vid}{terminals{mouse}(ccell)}{per} = SCdataPeaks{vid}{terminals{mouse}(ccell)}{per}(any(SCdataPeaks{vid}{terminals{mouse}(ccell)}{per},2),:);
                    end 
                end 
            end 
        end 

        %normalize
        if BBBQ == 1
            SNBdataPeaks = cell(1,length(vidList{mouse}));
            sortedBdata2 = cell(1,length(vidList{mouse}));
        end 
        if VWQ == 1 
            SNVdataPeaks = cell(1,length(vidList{mouse}));
            sortedVdata2 = cell(1,length(vidList{mouse}));
        end     
        SNCdataPeaks = cell(1,length(vidList{mouse}));    
        sortedCdata2 = cell(1,length(vidList{mouse}));   
         for vid = 1:length(vidList{mouse})
            for ccell = 1:length(terminals{mouse})
                for per = 1:length(sortedCdata{vid}{terminals{mouse}(ccell)})
                    if isempty(SBdataPeaks{vid}{BBBroi}{terminals{mouse}(ccell)}) == 0 
                        %the data needs to be added to because there are some
                        %negative gonig points which mess up the normalizing 
                        if BBBQ == 1
                            for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                                % determine the minimum value, add space (+100)
                                minValToAdd = abs(ceil(min(min(SBdataPeaks{vid}{BBBroi}{terminals{mouse}(ccell)}{per}))))+100;
                                % add min value 
                                sortedBdata2{vid}{BBBroi}{terminals{mouse}(ccell)}{per} = SBdataPeaks{vid}{BBBroi}{terminals{mouse}(ccell)}{per} + minValToAdd;
                            end
                        end 
                        % determine the minimum value, add space (+100)
                        minValToAdd = abs(ceil(min(min(SCdataPeaks{vid}{terminals{mouse}(ccell)}{per}))))+100;
                        % add min value
                        sortedCdata2{vid}{terminals{mouse}(ccell)}{per} = SCdataPeaks{vid}{terminals{mouse}(ccell)}{per} + minValToAdd;
                        if VWQ == 1
                            for VWroi = 1:length(vDataFullTrace{mouse}{1})
                                % determine the minimum value, add space (+100)
                                minValToAdd = abs(ceil(min(min(SVdataPeaks{vid}{VWroi}{terminals{mouse}(ccell)}{per}))))+100;
                                % add min valuedataDir = cell(1,mouseNum);
                                sortedVdata2{vid}{VWroi}{terminals{mouse}(ccell)}{per} = SVdataPeaks{vid}{VWroi}{terminals{mouse}(ccell)}{per} + minValToAdd;
                            end 
                        end 

                        %normalize to baselineTime sec before changePt (calcium peak
                        %onset) BLstart 
                        if isempty(sortedCdata{1}{terminals{mouse}(1)}{1}) == 0
                            changePt = floor(size(sortedCdata{1}{terminals{mouse}(1)}{1},2)/2)-4;
                        elseif isempty(sortedCdata{1}{terminals{mouse}(1)}{1}) == 1 && isempty(sortedCdata{1}{terminals{mouse}(1)}{2}) == 0
                            changePt = floor(size(sortedCdata{1}{terminals{mouse}(1)}{2},2)/2)-4;
                        end 
        %                 BLstart = changePt - floor(0.5*FPSstack{mouse});
                        BLstart = changePt - floor(baselineTime*FPSstack{mouse});
                        if BBBQ == 1
                            for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                                if isempty(sortedBdata2{vid}{BBBroi}{terminals{mouse}(ccell)}{per}) == 0
                                    SNBdataPeaks{vid}{BBBroi}{terminals{mouse}(ccell)}{per} = ((sortedBdata2{vid}{BBBroi}{terminals{mouse}(ccell)}{per})./(nanmean(sortedBdata2{vid}{BBBroi}{terminals{mouse}(ccell)}{per}(:,BLstart:changePt),2)))*100;
                                end 
                            end 
                        end 
                        if isempty(sortedCdata2{vid}{terminals{mouse}(ccell)}{per}) == 0 
                            SNCdataPeaks{vid}{terminals{mouse}(ccell)}{per} = ((sortedCdata2{vid}{terminals{mouse}(ccell)}{per})./(nanmean(sortedCdata2{vid}{terminals{mouse}(ccell)}{per}(:,BLstart:changePt),2)))*100;
                        end 
                        if VWQ == 1
                            if isempty(sortedVdata2{vid}{VWroi}{terminals{mouse}(ccell)}{per}) == 0 
                                for VWroi = 1:length(vDataFullTrace{mouse}{1})
                                    SNVdataPeaks{vid}{VWroi}{terminals{mouse}(ccell)}{per} = ((sortedVdata2{vid}{VWroi}{terminals{mouse}(ccell)}{per})./(nanmean(sortedVdata2{vid}{VWroi}{terminals{mouse}(ccell)}{per}(:,BLstart:changePt),2)))*100;
                                end 
                            end 
                        end 

                        %normalize to the first 0.5 sec (THIS IS JUST A SANITY
                        %CHECK 
                        %{
                        for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                            NsortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)} = ((sortedBdata2{vid}{BBBroi}{terminals{mouse}(ccell)})./(nanmean(sortedBdata2{vid}{BBBroi}{terminals{mouse}(ccell)}(:,1:floor(0.5*FPSstack{mouse})),2)))*100;
                        end 
                        NsortedCdata{vid}{terminals{mouse}(ccell)} = ((sortedCdata2{vid}{terminals{mouse}(ccell)})./(nanmean(sortedCdata2{vid}{terminals{mouse}(ccell)}(:,1:floor(0.5*FPSstack{mouse})),2)))*100;
                        if VWQ == 1
                            for VWroi = 1:length(vDataFullTrace{mouse}{1})
                                NsortedVdata{vid}{VWroi}{terminals{mouse}(ccell)} = ((sortedVdata2{vid}{VWroi}{terminals{mouse}(ccell)})./(nanmean(sortedVdata2{vid}{VWroi}{terminals{mouse}(ccell)}(:,1:floor(0.5*FPSstack{mouse})),2)))*100;
                            end 
                        end 
                        %}
                    end     
                end 
            end 
         end     
    elseif tTypeQ == 1   
        if mouse == 1 
            smoothQ = input('Input 0 to plot non-smoothed data. Input 1 to plot smoothed data. ');
        end         
        if smoothQ == 0 
            if BBBQ == 1
                SBdataPeaks = sortedBdata;
            end 
            if VWQ == 1
                SVdataPeaks = sortedVdata;
            end 
            SCdataPeaks = sortedCdata;        
        elseif smoothQ == 1
            if mouse == 1 
                filtTime = input('How many seconds do you want to smooth your data by? ');
            end 
            SBdataPeaks = cell(1,length(vidList{mouse}));
    %         SCdataPeaks = cell(1,length(vidList{mouse}));
            SVdataPeaks = cell(1,length(vidList{mouse}));
            SCdataPeaks = sortedCdata;
             for vid = 1:length(vidList{mouse})
                for ccell = 1:length(terminals{mouse})
                    for per = 1:length(sortedCdata{vid}{terminals{mouse}(ccell)})   
                        if length(sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}) >= per  
                            if isempty(sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{per}) == 0 
                                for peak = 1:size(sortedBdata{vid}{1}{terminals{mouse}(ccell)}{per},1)
                                    if BBBQ == 1
                                        for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                                            [SBPeak_Data] = MovMeanSmoothData(sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{per}(peak,:),filtTime,FPSstack{mouse});
                                            SBdataPeaks{vid}{BBBroi}{terminals{mouse}(ccell)}{per}(peak,:) = SBPeak_Data; 
                                            %remove rows full of 0s if there are any b = a(any(a,2),:)
                                            SBdataPeaks{vid}{BBBroi}{terminals{mouse}(ccell)}{per} = SBdataPeaks{vid}{BBBroi}{terminals{mouse}(ccell)}{per}(any(SBdataPeaks{vid}{BBBroi}{terminals{mouse}(ccell)}{per},2),:);
                                        end 
                                    end
        %                             [SCPeak_Data] = MovMeanSmoothData(sortedCdata{vid}{terminals{mouse}(ccell)}{per}(peak,:),filtTime,FPSstack{mouse});
        %                             SCdataPeaks{vid}{terminals{mouse}(ccell)}{per}(peak,:) = SCPeak_Data;     
                                    if VWQ == 1
                                        for VWroi = 1:length(vDataFullTrace{mouse}{1})
                                            [SVPeak_Data] = MovMeanSmoothData(sortedVdata{vid}{VWroi}{terminals{mouse}(ccell)}{per}(peak,:),filtTime,FPSstack{mouse});
                                            SVdataPeaks{vid}{VWroi}{terminals{mouse}(ccell)}{per}(peak,:) = SVPeak_Data;   
                                            %remove rows full of 0s if there are any b = a(any(a,2),:)
                                            SVdataPeaks{vid}{VWroi}{terminals{mouse}(ccell)}{per} = SVdataPeaks{vid}{VWroi}{terminals{mouse}(ccell)}{per}(any(SVdataPeaks{vid}{VWroi}{terminals{mouse}(ccell)}{per},2),:);
                                        end 
                                    end 
                                end 
                            end
                            %remove rows full of 0s if there are any b = a(any(a,2),:)
                            SCdataPeaks{vid}{terminals{mouse}(ccell)}{per} = SCdataPeaks{vid}{terminals{mouse}(ccell)}{per}(any(SCdataPeaks{vid}{terminals{mouse}(ccell)}{per},2),:);
                        end 
                    end 
                end 
             end        
        end  

        %normalize
        if BBBQ == 1
            SNBdataPeaks = cell(1,length(vidList{mouse}));
            sortedBdata2 = cell(1,length(vidList{mouse}));
        end 
        if VWQ == 1
            SNVdataPeaks = cell(1,length(vidList{mouse}));
            sortedVdata2 = cell(1,length(vidList{mouse}));
        end 
        SNCdataPeaks = cell(1,length(vidList{mouse}));        
        sortedCdata2 = cell(1,length(vidList{mouse}));    
         for vid = 1:length(vidList{mouse})
            for ccell = 1:length(terminals{mouse})
                if isempty(sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}) == 0 
                    for per = 1:length(sortedCdata{vid}{terminals{mouse}(ccell)})      
                        if length(sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}) >= per  
                            if isempty(sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{per}) == 0 
                                %the data needs to be added to because there are some
                                %negative gonig points which mess up the normalizing 
                                if BBBQ == 1
                                    for BBBroi = 1:length(bDataFullTrace{mouse}{1})     
                                        % determine the minimum value, add space (+100)
                                        minValToAdd = abs(ceil(min(min(SBdataPeaks{vid}{BBBroi}{terminals{mouse}(ccell)}{per}))))+100;
                                        % add min value 
                                        sortedBdata2{vid}{BBBroi}{terminals{mouse}(ccell)}{per} = SBdataPeaks{vid}{BBBroi}{terminals{mouse}(ccell)}{per} + minValToAdd;                    
                                    end     
                                end 
                                % determine the minimum value, add space (+100)
                                minValToAdd = abs(ceil(min(min(SCdataPeaks{vid}{terminals{mouse}(ccell)}{per}))))+100;
                                % add min value 
                                sortedCdata2{vid}{terminals{mouse}(ccell)}{per} = SCdataPeaks{vid}{terminals{mouse}(ccell)}{per} + minValToAdd;     
                                if VWQ == 1 
                                    for VWroi = 1:length(vDataFullTrace{mouse}{1})     
                                        % determine the minimum value, add space (+100)
                                        minValToAdd = abs(ceil(min(min(SVdataPeaks{vid}{VWroi}{terminals{mouse}(ccell)}{per}))))+100;
                                        % add min value 
                                        sortedVdata2{vid}{VWroi}{terminals{mouse}(ccell)}{per} = SVdataPeaks{vid}{VWroi}{terminals{mouse}(ccell)}{per} + minValToAdd;                 
                                    end 
                                end 

                                  %this normalizes to the first 1/3 section of the trace
                                  %(18 frames) 
                %{
                                    NsortedBdata{vid}{terminals{mouse}(ccell)}{per} = ((sortedBdata2{vid}{terminals{mouse}(ccell)}{per})./((nanmean(sortedBdata2{vid}{terminals{mouse}(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals{mouse}(ccell)})/3)),2))))*100;
                                    NsortedCdata{vid}{terminals{mouse}(ccell)}{per} = ((sortedCdata2{vid}{terminals{mouse}(ccell)}{per})./((nanmean(sortedCdata2{vid}{terminals{mouse}(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals{mouse}(ccell)})/3)),2))))*100;
                                    NsortedVdata{vid}{terminals{mouse}(ccell)}{per} = ((sortedVdata2{vid}{terminals{mouse}(ccell)}{per})./((nanmean(sortedVdata2{vid}{terminals{mouse}(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals{mouse}(ccell)})/3)),2))))*100;            
                %}                     

                                %normalize to baselineTime sec before changePt (calcium peak
                                %onset) BLstart 
                                if isempty(sortedCdata{1}{terminals{mouse}(1)}{1}) == 0
                                    changePt = floor(size(sortedCdata{1}{terminals{mouse}(1)}{1},2)/2)-4;
                                elseif isempty(sortedCdata{1}{terminals{mouse}(1)}{1}) == 1 && isempty(sortedCdata{1}{terminals{mouse}(1)}{2}) == 0
                                    changePt = floor(size(sortedCdata{1}{terminals{mouse}(1)}{2},2)/2)-4;
                                end                                 
                                BLstart = changePt - floor(baselineTime*FPSstack{mouse});
                                if BBBQ == 1
                                    for BBBroi = 1:length(bDataFullTrace{mouse}{1})
                                        if isempty(sortedBdata{vid}{BBBroi}{terminals{mouse}(ccell)}{per}) == 0 
                                            SNBdataPeaks{vid}{BBBroi}{terminals{mouse}(ccell)}{per} = ((sortedBdata2{vid}{BBBroi}{terminals{mouse}(ccell)}{per})./(nanmean(sortedBdata2{vid}{BBBroi}{terminals{mouse}(ccell)}{per}(:,BLstart:changePt),2)))*100;                
                                        end 
                                    end 
                                end 
                                SNCdataPeaks{vid}{terminals{mouse}(ccell)}{per} = ((sortedCdata2{vid}{terminals{mouse}(ccell)}{per})./(nanmean(sortedCdata2{vid}{terminals{mouse}(ccell)}{per}(:,BLstart:changePt),2)))*100;               
                                if VWQ == 1
                                    for VWroi = 1:length(vDataFullTrace{mouse}{1})                    
                                        SNVdataPeaks{vid}{VWroi}{terminals{mouse}(ccell)}{per} = ((sortedVdata2{vid}{VWroi}{terminals{mouse}(ccell)}{per})./(nanmean(sortedVdata2{vid}{VWroi}{terminals{mouse}(ccell)}{per}(:,BLstart:changePt),2)))*100;                    
                                    end 
                                end 
                            end 
                        end 
                    end 
                end 
            end 
         end 
    end 
    
    % STA 1: plot calcium spike triggered averages (this can plot traces
    % within 2 std from the mean, but all data gets stored). Automatically
    % plots all VW and BBB ROIs whether you are averaging Ca ROIs or not
    % and then saves these figures out (if you choose to plot them), as
    % well as the .mat file per mouse 

    %initialize arrays 
    if CAQ == 1 
        AVSNCdataPeaks = cell(1,length(sortedCdata{1}));
        AVSNCdataPeaks2 = cell(1,length(sortedCdata{1}));
        AVSNCdataPeaks3 = cell(1,length(sortedCdata{1}));
        allCTraces = cell(1,length(SNCdataPeaks{1}));
        CTraces = cell(1,length(SNCdataPeaks{1}));
    end 
    if BBBQ == 1
        AVSNBdataPeaks = cell(1,length(sortedBdata{1}));
        AVSNBdataPeaks2 = cell(1,length(sortedBdata{1}));
        AVSNBdataPeaks3 = cell(1,length(sortedBdata{1}));
        allBTraces = cell(1,length(sortedBdata{1}));
        BTraces = cell(1,length(sortedBdata{1}));
    end 
    if VWQ == 1
        AVSNVdataPeaks = cell(1,length(sortedVdata{1}));
        AVSNVdataPeaks2 = cell(1,length(sortedVdata{1}));
        AVSNVdataPeaks3 = cell(1,length(sortedVdata{1}));
        allVTraces = cell(1,length(sortedVdata{1}));
        VTraces = cell(1,length(sortedVdata{1}));
    end 
    if mouse == 1 
        saveQ = input('Input 1 to save the figures. Input 0 otherwise. ');
        VWpQ = input('Input 1 if you want to plot vessel width data. ');
        BBBpQ = input('Input 1 if you want to plot BBB data. ');
        AVQ = input('Input 1 to average across Ca ROIs. Input 0 otherwise. ');
        if BBBpQ == 1 
            BBBroiAVq = input('Input 1 to average across BBB ROIs. ');
        end 
    end     
    if AVQ == 1
        if mouse == 1
            AVQ2 = input('Input 1 to specify what Ca ROIs to average. Input 0 to average all Ca ROIs. ');
        end 
        if AVQ2 == 0 % average all Ca ROIs 
            terms = terminals{mouse};
        elseif AVQ2 == 1 % specify what Ca ROIs to average 
            terms = input(sprintf('Input the Ca ROIs you want to average for mouse #%d. ',mouse));
        end 
    elseif AVQ == 0 
        terms = terminals{mouse}; 
    end 

    if tTypeQ == 0 
        if AVQ == 0 
            for ccell = 1:length(terms)
                for per = 1:length(sortedCdata{vid}{terminals{mouse}(ccell)})
                    Frames = size(SNBdataPeaks{1}{1}{terms(ccell)}{per},2);
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
                    FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
                    count = 1;
                    % sort data 
                    for vid = 1:length(vidList{mouse})      
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
                        plot(allCTraces{terminals{mouse}(ccell)}(traceInds(peak),:),'b')

                    end 
                    %}                

                    if per <= size(allCTraces{terms(ccell)},2)
                        %get averages of all traces
                        if BBBQ == 1
                            for BBBroi = 1:length(sortedBdata{1})
                                AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} = (nanmean(allBTraces{BBBroi}{terms(ccell)}{per}));
                            end 
                        end 
                        AVSNCdataPeaks2{terms(ccell)}{per} = nanmean(allCTraces{terms(ccell)}{per});
                        if VWQ == 1
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
                        if BBBQ == 1
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
                        if VWQ == 1
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

                        %get averages of traces excluding outliers  
                        if BBBQ == 1
                            for BBBroi = 1:length(sortedBdata{1})
                                AVSNBdataPeaks{BBBroi}{terms(ccell)}{per} = (nanmean(BTraces{BBBroi}{terms(ccell)}{per}));
                            end 
                        end 
                        AVSNCdataPeaks{terms(ccell)}{per} = nanmean(CTraces{terms(ccell)}{per});
                        if VWQ == 1
                            for VWroi = 1:length(sortedVdata{1})
                                AVSNVdataPeaks{VWroi}{terms(ccell)}{per} = (nanmean(VTraces{VWroi}{terms(ccell)}{per}));
                            end 
                        end 

                        % plot 
                        if BBBpQ == 1 
                            for BBBroi = 1:length(sortedBdata{1})
                                %determine range of data Ca data
                                CaDataRange = max(AVSNCdataPeaks{terms(ccell)}{per})-min(AVSNCdataPeaks{terms(ccell)}{per});
                                %determine plotting buffer space for Ca data 
                                CaBufferSpace = CaDataRange;
                                %determine first set of plotting min and max values for Ca data
                                CaPlotMin = min(AVSNCdataPeaks{terms(ccell)}{per})-CaBufferSpace;
                                CaPlotMax = max(AVSNCdataPeaks{terms(ccell)}{per})+CaBufferSpace; 
                                %determine Ca 0 ratio/location 
                                CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);

                                %determine range of BBB data 
                                BBBdataRange = max(AVSNBdataPeaks{BBBroi}{terms(ccell)}{per})-min(AVSNBdataPeaks{BBBroi}{terms(ccell)}{per});
                                %determine plotting buffer space for BBB data 
                                BBBbufferSpace = BBBdataRange;
                                %determine first set of plotting min and max values for BBB data
                                BBBplotMin = min(AVSNBdataPeaks{BBBroi}{terms(ccell)}{per})-BBBbufferSpace;
                                BBBplotMax = max(AVSNBdataPeaks{BBBroi}{terms(ccell)}{per})+BBBbufferSpace;
                                %determine BBB 0 ratio/location
                                BBBzeroRatio = abs(BBBplotMin)/(BBBplotMax-BBBplotMin);
                                %determine how much to shift the BBB axis so that the zeros align 
                                BBBbelowZero = (BBBplotMax-BBBplotMin)*CaZeroRatio;
                                BBBaboveZero = (BBBplotMax-BBBplotMin)-BBBbelowZero;
 
                                fig = figure;
                                ax=gca;
                                hold all
                                plot(AVSNCdataPeaks{terms(ccell)}{per},'b','LineWidth',4)
                    %             plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
                                ax.XTick = FrameVals;
                                ax.XTickLabel = sec_TimeVals;   
                                ax.FontSize = 25;
                                ax.FontName = 'Times';
                                xlabel('time (s)','FontName','Times')
                                ylabel('calcium signal percent change','FontName','Times')
    %                             xLimStart = floor(10*FPSstack{mouse});
    %                             xLimEnd = floor(24*FPSstack{mouse}); 
                                xlim([1 size(AVSNCdataPeaks{terms(ccell)}{per},2)])
                                ylim([min(AVSNCdataPeaks{terms(ccell)}{per}-CaBufferSpace) max(AVSNCdataPeaks{terms(ccell)}{per}+CaBufferSpace)])
%                                 patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],[0 0 0.5],'EdgeColor','none')            
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
                                plot(AVSNBdataPeaks{BBBroi}{terms(ccell)}{per},'r','LineWidth',4)
                                patch([x fliplr(x)],[(CI_bLow{BBBroi}) (fliplr(CI_bHigh{BBBroi}))],[0.5 0 0],'EdgeColor','none')
                                ylabel('BBB permeability percent change','FontName','Times')
                                tlabel = sprintf('Mouse #%d. Ca ROI #%d. BBB ROI #%d. ',mouse,terms(ccell),BBBroi);
            %                     perLabel = 
                                title({sprintf('Mouse #%d. Ca ROI #%d. BBB ROI #%d.',mouse,terms(ccell),BBBroi);perLabel})
                    %             title('BBB permeability Spike Triggered Average')
                                alpha(0.3)
                                set(gca,'YColor',[0 0 0]);
                                ylim([-BBBbelowZero BBBaboveZero])
                                %make the directory and save the images   
                                if saveQ == 1  
                                    dir2 = strrep(dir1,'\','/');
                                    dir3 = sprintf('%s/%s%s.tif',dir2,tlabel,perLabel);
                                    export_fig(dir3)
                                end
                            end 
                        end 
                        
                        if VWpQ == 1 
                            for VWroi = 1:length(sortedVdata{1})
                                %determine range of data Ca data
                                CaDataRange = max(AVSNCdataPeaks{terms(ccell)}{per})-min(AVSNCdataPeaks{terms(ccell)}{per});
                                %determine plotting buffer space for Ca data 
                                CaBufferSpace = CaDataRange;
                                %determine first set of plotting min and max values for Ca data
                                CaPlotMin = min(AVSNCdataPeaks{terms(ccell)}{per})-CaBufferSpace;
                                CaPlotMax = max(AVSNCdataPeaks{terms(ccell)}{per})+CaBufferSpace; 
                                %determine Ca 0 ratio/location 
                                CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);

                                %determine range of BBB data 
                                VWdataRange = max(AVSNVdataPeaks{VWroi}{terms(ccell)}{per})-min(AVSNVdataPeaks{VWroi}{terms(ccell)}{per});
                                %determine plotting buffer space for BBB data 
                                VWbufferSpace = VWdataRange;
                                %determine first set of plotting min and max values for BBB data
                                VWplotMin = min(AVSNVdataPeaks{VWroi}{terms(ccell)}{per})-VWbufferSpace;
                                VWplotMax = max(AVSNVdataPeaks{VWroi}{terms(ccell)}{per})+VWbufferSpace;
                                %determine BBB 0 ratio/location
                                VWzeroRatio = abs(VWplotMin)/(VWplotMax-VWplotMin);
                                %determine how much to shift the BBB axis so that the zeros align 
                                VWbelowZero = (VWplotMax-VWplotMin)*CaZeroRatio;
                                VWaboveZero = (VWplotMax-VWplotMin)-VWbelowZero;                                

                                fig = figure;
                                ax=gca;
                                hold all
                                plot(AVSNCdataPeaks{terms(ccell)}{per},'b','LineWidth',4)
                    %             plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
                                ax.XTick = FrameVals;
                                ax.XTickLabel = sec_TimeVals;   
                                ax.FontSize = 25;
                                ax.FontName = 'Times';
                                xlabel('time (s)','FontName','Times')
                                ylabel('calcium signal percent change','FontName','Times')
                                xLimStart = floor(10*FPSstack{mouse});
                                xLimEnd = floor(24*FPSstack{mouse}); 
                                xlim([1 size(AVSNCdataPeaks{terms(ccell)}{per},2)])
                                ylim([-60 100])
                                ylim([min(AVSNCdataPeaks{terms(ccell)}{per}-CaBufferSpace) max(AVSNCdataPeaks{terms(ccell)}{per}+CaBufferSpace)])
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
                                plot(AVSNVdataPeaks{VWroi}{terms(ccell)}{per},'k','LineWidth',4)
                                patch([x fliplr(x)],[(CI_vLow{VWroi}) (fliplr(CI_vHigh{VWroi}))],'k','EdgeColor','none')
                                ylabel('Vessel width percent change','FontName','Times')
                                tlabel = ({sprintf('Mouse #%d. Ca ROI #%d. VW ROI #%d. ',mouse,terms(ccell),VWroi);perLabel});
                    %             title(sprintf('Terminal %d. Vessel width ROI %d.',terminals{mouse}(ccell),VWroi))
                                title({sprintf('Mouse #%d. Ca ROI #%d. VW ROI #%d.',mouse,terms(ccell),VWroi),perLabel})
                                alpha(0.3)
                                set(gca,'YColor',[0 0 0]);
                                ylim([-VWbelowZero VWaboveZero])
                                %make the directory and save the images   
                                if saveQ == 1  
                                    dir2 = strrep(dir1,'\','/');
                                    dir3 = sprintf('%s/%s%s.tif',dir2,tlabel,perLabel);
                                    export_fig(dir3)
                                end
                            end 
                        end 
                    end 
                end 
            end
            
        elseif AVQ == 1 % average across calcium ROIs 
            for ccell = 1:length(terms) 
                if isempty(SNCdataPeaks{vid}{terms(ccell)}) == 0 
                    for per = 1:length(sortedCdata{vid}{terminals{mouse}(ccell)})
                        if isempty(SNCdataPeaks{vid}{terms(ccell)}{per}) == 0 
                            count = 1;
                            % sort data 
                            for vid = 1:length(vidList{mouse})   
                                if isempty(SNCdataPeaks{vid}{terms(ccell)}) == 0 
                                    for peak = 1:size(SNCdataPeaks{vid}{terms(ccell)}{per},1) 
                                        if BBBQ == 1
                                            for BBBroi = 1:length(sortedBdata{1})
                                                allBTraces{BBBroi}{terms(ccell)}{per}(count,:) = (SNBdataPeaks{vid}{BBBroi}{terms(ccell)}{per}(peak,:)-100); 
                                                %remove rows full of zeros if there are any b = a(any(a,2),:)
                                                allBTraces{BBBroi}{terms(ccell)}{per} = allBTraces{BBBroi}{terms(ccell)}{per}(any(allBTraces{BBBroi}{terms(ccell)}{per},2),:);
                                            end 
                                        end 
                                        if VWQ == 1
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
                            if BBBQ == 1
                                for BBBroi = 1:length(sortedBdata{1})
                                    AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} = (nanmean(allBTraces{BBBroi}{terms(ccell)}{per}));
                                end 
                            end 
                            AVSNCdataPeaks2{terms(ccell)}{per} = nanmean(allCTraces{terms(ccell)}{per});
                            if VWQ == 1
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
                                    if BBBQ == 1
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
                                    if VWQ == 1
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
                end 
            end       
            for per = 1:length(sortedCdata{1}{terminals{mouse}(1)})
                if isempty(SNCdataPeaks{1}{terms(1)}{per}) == 0 
                    Frames = size(AVSNCdataPeaks3{per},2);
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
                    FrameVals = round((1:FPSstack{mouse}:Frames))+9; 

                    %DETERMINE 95% CI
                    if BBBQ == 1
                        CI_bLow = cell(1,length(sortedBdata{1}));
                        CI_bHigh = cell(1,length(sortedBdata{1}));
                        for BBBroi = 1:length(sortedBdata{1})
                            SEMb = (nanstd(AVSNBdataPeaks3{BBBroi}{per})/(sqrt(size(AVSNBdataPeaks3{BBBroi}{per},1)))); % Standard Error            
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
                    if BBBpQ == 1 
                        for BBBroi = 1:length(sortedBdata{1})
                            %determine range of data Ca data
                            CaDataRange = max(AVSNCdataPeaks{per})-min(AVSNCdataPeaks{per});
                            %determine plotting buffer space for Ca data 
                            CaBufferSpace = CaDataRange;
                            %determine first set of plotting min and max values for Ca data
                            CaPlotMin = min(AVSNCdataPeaks{per})-CaBufferSpace;
                            CaPlotMax = max(AVSNCdataPeaks{per})+CaBufferSpace; 
                            %determine Ca 0 ratio/location 
                            CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);

                            %determine range of BBB data 
                            BBBdataRange = max(AVSNBdataPeaks{BBBroi}{per})-min(AVSNBdataPeaks{BBBroi}{per});
                            %determine plotting buffer space for BBB data 
                            BBBbufferSpace = BBBdataRange;
                            %determine first set of plotting min and max values for BBB data
                            BBBplotMin = min(AVSNBdataPeaks{BBBroi}{per})-BBBbufferSpace;
                            BBBplotMax = max(AVSNBdataPeaks{BBBroi}{per})+BBBbufferSpace;
                            %determine BBB 0 ratio/location
                            BBBzeroRatio = abs(BBBplotMin)/(BBBplotMax-BBBplotMin);
                            %determine how much to shift the BBB axis so that the zeros align 
                            BBBbelowZero = (BBBplotMax-BBBplotMin)*CaZeroRatio;
                            BBBaboveZero = (BBBplotMax-BBBplotMin)-BBBbelowZero;
                                                        
                            fig = figure;
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
%                             xLimStart = floor(10*FPSstack{mouse});
%                             xLimEnd = floor(24*FPSstack{mouse}); 
                            xlim([1 size(AVSNCdataPeaks{per},2)])
                            ylim([min(AVSNCdataPeaks{per}-CaBufferSpace) max(AVSNCdataPeaks{per}+CaBufferSpace)])
%                             patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],[0 0 0.5],'EdgeColor','none')
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
                            plot(AVSNBdataPeaks{BBBroi}{per},'r','LineWidth',4)
                            patch([x fliplr(x)],[(CI_bLow{BBBroi}) (fliplr(CI_bHigh{BBBroi}))],[0.5 0 0],'EdgeColor','none')
                            ylabel('BBB permeability percent change','FontName','Times')
                            title({sprintf('Mouse #%d. All Ca ROIs Averaged. BBB ROI #%d.',mouse,BBBroi);perLabel})
                            tlabel = sprintf('Mouse #%d. All Ca ROIs Averaged. BBB ROI #%d. ',mouse,BBBroi);
                %             title('BBB permeability Spike Triggered Average')
                            alpha(0.3)
                            set(gca,'YColor',[0 0 0]);
                            ylim([-BBBbelowZero BBBaboveZero])
                            %make the directory and save the images   
                            if saveQ == 1  
                                dir2 = strrep(dir1,'\','/');
                                dir3 = sprintf('%s/%s%s.tif',dir2,tlabel,perLabel);
                                export_fig(dir3)
                            end                               
                        end 
                    end 
                    
                    if VWpQ == 1 
                        for VWroi = 1:length(sortedVdata{1})
                            %determine range of data Ca data
                            CaDataRange = max(AVSNCdataPeaks{per})-min(AVSNCdataPeaks{per});
                            %determine plotting buffer space for Ca data 
                            CaBufferSpace = CaDataRange;
                            %determine first set of plotting min and max values for Ca data
                            CaPlotMin = min(AVSNCdataPeaks{per})-CaBufferSpace;
                            CaPlotMax = max(AVSNCdataPeaks{per})+CaBufferSpace; 
                            %determine Ca 0 ratio/location 
                            CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);

                            %determine range of BBB data 
                            VWdataRange = max(AVSNVdataPeaks{VWroi}{per})-min(AVSNVdataPeaks{VWroi}{per});
                            %determine plotting buffer space for BBB data 
                            VWbufferSpace = VWdataRange;
                            %determine first set of plotting min and max values for BBB data
                            VWplotMin = min(AVSNVdataPeaks{VWroi}{per})-VWbufferSpace;
                            VWplotMax = max(AVSNVdataPeaks{VWroi}{per})+VWbufferSpace;
                            %determine BBB 0 ratio/location
                            VWzeroRatio = abs(VWplotMin)/(VWplotMax-VWplotMin);
                            %determine how much to shift the BBB axis so that the zeros align 
                            VWbelowZero = (VWplotMax-VWplotMin)*CaZeroRatio;
                            VWaboveZero = (VWplotMax-VWplotMin)-VWbelowZero;   
                            
                            fig = figure;
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
                            xLimStart = floor(10*FPSstack{mouse});
                            xLimEnd = floor(24*FPSstack{mouse}); 
                            xlim([1 size(AVSNCdataPeaks{per},2)])
                            ylim([min(AVSNCdataPeaks{per}-CaBufferSpace) max(AVSNCdataPeaks{per}+CaBufferSpace)])
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
                            plot(AVSNVdataPeaks{VWroi}{per},'k','LineWidth',4)
                            patch([x fliplr(x)],[(CI_vLow{VWroi}) (fliplr(CI_vHigh{VWroi}))],'k','EdgeColor','none')
                            ylabel('Vessel width percent change','FontName','Times')
                %             title(sprintf('Terminal %d. Vessel width ROI %d.',terminals{mouse}(ccell),VWroi))
                            title({sprintf('Mouse #%d. All Ca ROIs Averaged. VW ROI %d.',mouse,VWroi);perLabel})
                            tlabel = sprintf('Mouse #%d. All Ca ROIs Averaged. VW ROI #%d. ',mouse,VWroi);
                            alpha(0.3)
                            set(gca,'YColor',[0 0 0]);
                            ylim([-VWbelowZero VWaboveZero])
                            %make the directory and save the images   
                            if saveQ == 1  
                                dir2 = strrep(dir1,'\','/');
                                dir3 = sprintf('%s/%s%s.tif',dir2,tlabel,perLabel);
                                export_fig(dir3)
                            end   
                        end 
                    end 
                end 
            end 
        end 
        
    elseif tTypeQ == 1
        if AVQ == 0 
            for ccell = 1:length(terms)       
                for per = 1:length(sortedCdata{vid}{terminals{mouse}(ccell)})
                    % plot    
                    Frames = size(SNBdataPeaks{1}{BBBroi}{terms(ccell)}{3},2);
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
                    FrameVals = round((1:FPSstack{mouse}:Frames)+5); 
                    count = 1;
                    for vid = 1:length(vidList{mouse})
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
                    
                    % plot 
                    if BBBpQ == 1
                        for BBBroi = 1:length(sortedBdata{1})
                            %determine range of data Ca data
                            CaDataRange = max(AVSNCdataPeaks{terms(ccell)}{per})-min(AVSNCdataPeaks{terms(ccell)}{per});
                            %determine plotting buffer space for Ca data 
                            CaBufferSpace = CaDataRange;
                            %determine first set of plotting min and max values for Ca data
                            CaPlotMin = min(AVSNCdataPeaks{terms(ccell)}{per})-CaBufferSpace;
                            CaPlotMax = max(AVSNCdataPeaks{terms(ccell)}{per})+CaBufferSpace; 
                            %determine Ca 0 ratio/location 
                            CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);

                            %determine range of BBB data 
                            BBBdataRange = max(AVSNBdataPeaks{BBBroi}{terms(ccell)}{per})-min(AVSNBdataPeaks{BBBroi}{terms(ccell)}{per});
                            %determine plotting buffer space for BBB data 
                            BBBbufferSpace = BBBdataRange;
                            %determine first set of plotting min and max values for BBB data
                            BBBplotMin = min(AVSNBdataPeaks{BBBroi}{terms(ccell)}{per})-BBBbufferSpace;
                            BBBplotMax = max(AVSNBdataPeaks{BBBroi}{terms(ccell)}{per})+BBBbufferSpace;
                            %determine BBB 0 ratio/location
                            BBBzeroRatio = abs(BBBplotMin)/(BBBplotMax-BBBplotMin);
                            %determine how much to shift the BBB axis so that the zeros align 
                            BBBbelowZero = (BBBplotMax-BBBplotMin)*CaZeroRatio;
                            BBBaboveZero = (BBBplotMax-BBBplotMin)-BBBbelowZero;
                            
                            fig = figure;
                            ax=gca;
                            hold all
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
%                             xLimStart = floor(10*FPSstack{mouse});
%                             xLimEnd = floor(24*FPSstack{mouse}); 
                            if isempty(AVSNCdataPeaks{terms(ccell)}{per}) == 0 
                                xlim([1 size(AVSNCdataPeaks{terms(ccell)}{per},2)])
                            end 
                            ylim([min(AVSNCdataPeaks{terms(ccell)}{per}-CaBufferSpace) max(AVSNCdataPeaks{terms(ccell)}{per}+CaBufferSpace)])
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
                            if isempty(AVSNBdataPeaks{BBBroi}{terms(ccell)}{per}) == 0 && isempty(CI_cLow) == 0 
                                plot(AVSNBdataPeaks{BBBroi}{terms(ccell)}{per},'r','LineWidth',4)
                                patch([x fliplr(x)],[(CI_bLow{BBBroi}) (fliplr(CI_bHigh{BBBroi}))],[0.5 0 0],'EdgeColor','none')
                                ylabel('BBB permeability percent change','FontName','Times')
                                tlabel = sprintf('Mouse #%d. Ca ROI #%d. BBB ROI #%d. ',mouse,terms(ccell),BBBroi);
                                title({sprintf('Mouse #%d. Ca ROI #%d. BBB ROI #%d.',mouse,terms(ccell),BBBroi);perLabel})
                    %             title('BBB permeability Spike Triggered Average')
                            end 
                            alpha(0.3)
                            set(gca,'YColor',[0 0 0]);
                            ylim([-BBBbelowZero BBBaboveZero])
                            %make the directory and save the images   
                            if saveQ == 1  
                                dir2 = strrep(dir1,'\','/');
                                dir3 = sprintf('%s/%s%s.tif',dir2,tlabel,perLabel);
                                export_fig(dir3)
                            end                              
                        end 
                    end 
                    
                    if VWpQ == 1
                        for VWroi = 1:length(sortedVdata{1})
                            %determine range of data Ca data
                            CaDataRange = max(AVSNCdataPeaks{terms(ccell)}{per})-min(AVSNCdataPeaks{terms(ccell)}{per});
                            %determine plotting buffer space for Ca data 
                            CaBufferSpace = CaDataRange;
                            %determine first set of plotting min and max values for Ca data
                            CaPlotMin = min(AVSNCdataPeaks{terms(ccell)}{per})-CaBufferSpace;
                            CaPlotMax = max(AVSNCdataPeaks{terms(ccell)}{per})+CaBufferSpace; 
                            %determine Ca 0 ratio/location 
                            CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);

                            %determine range of BBB data 
                            VWdataRange = max(AVSNVdataPeaks{VWroi}{terms(ccell)}{per})-min(AVSNVdataPeaks{VWroi}{terms(ccell)}{per});
                            %determine plotting buffer space for BBB data 
                            VWbufferSpace = VWdataRange;
                            %determine first set of plotting min and max values for BBB data
                            VWplotMin = min(AVSNVdataPeaks{VWroi}{terms(ccell)}{per})-VWbufferSpace;
                            VWplotMax = max(AVSNVdataPeaks{VWroi}{terms(ccell)}{per})+VWbufferSpace;
                            %determine BBB 0 ratio/location
                            VWzeroRatio = abs(VWplotMin)/(VWplotMax-VWplotMin);
                            %determine how much to shift the BBB axis so that the zeros align 
                            VWbelowZero = (VWplotMax-VWplotMin)*CaZeroRatio;
                            VWaboveZero = (VWplotMax-VWplotMin)-VWbelowZero;    

                            fig = figure;
                            ax=gca;
                            hold all
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
                            xLimStart = floor(10*FPSstack{mouse});
                            xLimEnd = floor(24*FPSstack{mouse}); 
                            if isempty(AVSNCdataPeaks{terms(ccell)}{per}) == 0 
                                xlim([1 size(AVSNCdataPeaks{terms(ccell)}{per},2)])
                            end 
                            ylim([min(AVSNCdataPeaks{terms(ccell)}{per}-CaBufferSpace) max(AVSNCdataPeaks{terms(ccell)}{per}+CaBufferSpace)])
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
                            if isempty(AVSNVdataPeaks{VWroi}{terms(ccell)}{per}) == 0 && isempty(CI_cLow) == 0 
                                plot(AVSNVdataPeaks{VWroi}{terms(ccell)}{per},'k','LineWidth',4)
                                patch([x fliplr(x)],[(CI_vLow{VWroi}) (fliplr(CI_vHigh{VWroi}))],'k','EdgeColor','none')
                                ylabel('Vessel width percent change','FontName','Times')
                                tlabel = sprintf('Mouse #%d. Ca ROI #%d. VW ROI #%d. ',mouse,terms(ccell),VWroi);
                    %             title(sprintf('Terminal %d. Vessel width ROI %d.',terminals{mouse}(ccell),VWroi))
                                title({sprintf('Mouse #%d. Ca ROI #%d. VW ROI #%d.',mouse,terms(ccell),VWroi);perLabel})
                            end 
                            alpha(0.3)
                            set(gca,'YColor',[0 0 0]);
                            ylim([-VWbelowZero VWaboveZero])
                            %make the directory and save the images   
                            if saveQ == 1  
                                dir2 = strrep(dir1,'\','/');
                                dir3 = sprintf('%s/%s%s.tif',dir2,tlabel,perLabel);
                                export_fig(dir3)
                            end                              
                        end 
                    end 
                end 
            end 
        elseif AVQ == 1 
            % sort data
            for ccell = 1:length(terms)
                AVSNCdataPeaks3 = cell(1,3);
                for per = 1:length(sortedCdata{vid}{terminals{mouse}(ccell)})
                    count = 1;
                    for vid = 1:length(vidList{mouse})
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
            for per = 1:length(sortedCdata{vid}{terminals{mouse}(ccell)})
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
                if BBBpQ == 1
                    for BBBroi = 1:length(sortedBdata{1}) 
                        %determine range of data Ca data
                        CaDataRange = max(AVSNCdataPeaks{per})-min(AVSNCdataPeaks{per});
                        %determine plotting buffer space for Ca data 
                        CaBufferSpace = CaDataRange;
                        %determine first set of plotting min and max values for Ca data
                        CaPlotMin = min(AVSNCdataPeaks{per})-CaBufferSpace;
                        CaPlotMax = max(AVSNCdataPeaks{per})+CaBufferSpace; 
                        %determine Ca 0 ratio/location 
                        CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);

                        %determine range of BBB data 
                        BBBdataRange = max(AVSNBdataPeaks{BBBroi}{per})-min(AVSNBdataPeaks{BBBroi}{per});
                        %determine plotting buffer space for BBB data 
                        BBBbufferSpace = BBBdataRange;
                        %determine first set of plotting min and max values for BBB data
                        BBBplotMin = min(AVSNBdataPeaks{BBBroi}{per})-BBBbufferSpace;
                        BBBplotMax = max(AVSNBdataPeaks{BBBroi}{per})+BBBbufferSpace;
                        %determine BBB 0 ratio/location
                        BBBzeroRatio = abs(BBBplotMin)/(BBBplotMax-BBBplotMin);
                        %determine how much to shift the BBB axis so that the zeros align 
                        BBBbelowZero = (BBBplotMax-BBBplotMin)*CaZeroRatio;
                        BBBaboveZero = (BBBplotMax-BBBplotMin)-BBBbelowZero;
                        
                        fig = figure; 
                        Frames = size(AVSNCdataPeaks3{per},2);
                        Frames_pre_stim_start = -((Frames-1)/2); 
                        Frames_post_stim_start = (Frames-1)/2; 
                        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
                        FrameVals = round((1:FPSstack{mouse}:Frames)+5); 
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
%                         xLimStart = floor(10*FPSstack{mouse});
%                         xLimEnd = floor(24*FPSstack{mouse}); 
                        xlim([1 size(AVSNCdataPeaks{per},2)])
                        ylim([min(AVSNCdataPeaks{per}-CaBufferSpace) max(AVSNCdataPeaks{per}+CaBufferSpace)])
                        patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],[0 0 0.5],'EdgeColor','none')
                        set(fig,'position', [500 100 900 800])
                        alpha(0.3)

                        %add right y axis tick marks for a specific DOD figure. 
                        yyaxis right 
                        plot(AVSNBdataPeaks{BBBroi}{per},'r','LineWidth',4)
                        patch([x fliplr(x)],[(CI_bLow{BBBroi}) (fliplr(CI_bHigh{BBBroi}))],[0.5 0 0],'EdgeColor','none')
                        ylabel('BBB permeability percent change','FontName','Times')
                        tlabel = sprintf('Mouse #%d. All Ca ROIs Averaged. BBB ROI #%d. ',mouse,BBBroi);
                        title({sprintf('Mouse #%d. All Ca ROIs Averaged. BBB ROI #%d.',mouse,BBBroi);perLabel})                      
                        alpha(0.3)
                        set(gca,'YColor',[0 0 0]);
                        ylim([-BBBbelowZero BBBaboveZero])
                        %make the directory and save the images   
                        if saveQ == 1  
                            dir2 = strrep(dir1,'\','/');
                            dir3 = sprintf('%s/%s%s.tif',dir2,tlabel,perLabel);
                            export_fig(dir3)
                        end 
                    end 
                end
                
                if VWpQ == 1
                    for VWroi = 1:length(sortedVdata{1})
                        %determine range of data Ca data
                        CaDataRange = max(AVSNCdataPeaks{per})-min(AVSNCdataPeaks{per});
                        %determine plotting buffer space for Ca data 
                        CaBufferSpace = CaDataRange;
                        %determine first set of plotting min and max values for Ca data
                        CaPlotMin = min(AVSNCdataPeaks{per})-CaBufferSpace;
                        CaPlotMax = max(AVSNCdataPeaks{per})+CaBufferSpace; 
                        %determine Ca 0 ratio/location 
                        CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);

                        %determine range of BBB data 
                        VWdataRange = max(AVSNVdataPeaks{VWroi}{per})-min(AVSNVdataPeaks{VWroi}{per});
                        %determine plotting buffer space for BBB data 
                        VWbufferSpace = VWdataRange;
                        %determine first set of plotting min and max values for BBB data
                        VWplotMin = min(AVSNVdataPeaks{VWroi}{per})-VWbufferSpace;
                        VWplotMax = max(AVSNVdataPeaks{VWroi}{per})+VWbufferSpace;
                        %determine BBB 0 ratio/location
                        VWzeroRatio = abs(VWplotMin)/(VWplotMax-VWplotMin);
                        %determine how much to shift the BBB axis so that the zeros align 
                        VWbelowZero = (VWplotMax-VWplotMin)*CaZeroRatio;
                        VWaboveZero = (VWplotMax-VWplotMin)-VWbelowZero;       

                        fig = figure; 
                        Frames = size(AVSNCdataPeaks3{per},2);
                        Frames_pre_stim_start = -((Frames-1)/2); 
                        Frames_post_stim_start = (Frames-1)/2; 
                        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
                        FrameVals = round((1:FPSstack{mouse}:Frames)+5); 
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
                        xLimStart = floor(10*FPSstack{mouse});
                        xLimEnd = floor(24*FPSstack{mouse}); 
                        xlim([1 size(AVSNCdataPeaks{per},2)])
                        ylim([min(AVSNCdataPeaks{per}-CaBufferSpace) max(AVSNCdataPeaks{per}+CaBufferSpace)])
                        patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],[0 0 0.5],'EdgeColor','none')
                        set(fig,'position', [500 100 900 800])
                        alpha(0.3)

                        %add right y axis tick marks for a specific DOD figure. 
                        yyaxis right 
                        plot(AVSNVdataPeaks{VWroi}{per},'k','LineWidth',4)
                        patch([x fliplr(x)],[(CI_vLow{VWroi}) (fliplr(CI_vHigh{VWroi}))],'k','EdgeColor','none')
                        ylabel('Vessel width percent change','FontName','Times')
                        title({sprintf('Mouse #%d. All Ca ROIs Averaged. VW ROI #%d.',mouse,VWroi);perLabel})
                        tlabel = sprintf('Mouse #%d. All Ca ROIs Averaged. VW ROI #%d. ',mouse,VWroi);
                        alpha(0.3)
                        set(gca,'YColor',[0 0 0]);
                        ylim([-VWbelowZero VWaboveZero])
                        %make the directory and save the images   
                        if saveQ == 1  
                            dir2 = strrep(dir1,'\','/');
                            dir3 = sprintf('%s/%s%s.tif',dir2,tlabel,perLabel);
                            export_fig(dir3)
                        end 
                    end 
                end 
            end 
        end 
    end 

     % plot bar plots 
     %{
        for ccell = 3%1:length(terminals{mouse})
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
    %             [maxVal, maxValInd] = max(AVSNBdataPeaks{terminals{mouse}(ccell)}{per}(changePt:end));
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
    %             startF = 35;%floor(startTval*FPSstack{mouse});
    %             endF = 38;%floor(startF+(0.8*FPSstack{mouse}));

                meanValPostCaPeak(per) = nanmean(AVSNBdataPeaks{terminals{mouse}(ccell)}{per}(startF:endF));
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
            dir = sprintf('D:/70kD_RhoB/DAT-Chrimson-GCaMP/SF56_20190718/figures/Terminal12/DAterminal%d_maxChangeInBBBpermFollowingCaPeakAcrossLightConditionsWithCIs_1sSmoothing.tif',terminals{mouse}(ccell));
    %         export_fig(dir)
            if smoothQ == 0 
                title('Data not smoothed')
            elseif smoothQ == 1
                title(sprintf('Data smoothed by %0.2f sec',filtTime))
            end 
        end
        %}
     
    % save the .mat file per mouse
    if tTypeQ == 0 
        fileName = sprintf('STAfigData_allLightConditions_%d.mat',mouse);
    elseif tTypeQ == 1 
        fileName = sprintf('STAfigData_dataSeparatedByLightCondition_%d.mat',mouse);
    end 
    
    % average across BBB ROIs 
    if BBBroiAVq
        AVSNBdataPeaks4 = cell(1,length(AVSNBdataPeaks3{1}));
        for per = 1:length(AVSNBdataPeaks3{1})
            count = 1; 
            for BBBroi = 1:length(sortedBdata{1}) 
                for trace = 1:size(AVSNBdataPeaks3{BBBroi}{per},1)
                    AVSNBdataPeaks4{per}(count,:) =  AVSNBdataPeaks3{BBBroi}{per}(trace,:);
                    count = count + 1; 
                end                
            end   
            %calculate the 95% confidence interval
            SEMb = (nanstd(AVSNBdataPeaks4{per}))/(sqrt(size(AVSNBdataPeaks4{per},1))); % Standard Error            
            ts_bLow = tinv(0.025,size(AVSNBdataPeaks4{per},1)-1);% T-Score for 95% CI
            ts_bHigh = tinv(0.975,size(AVSNBdataPeaks4{per},1)-1);% T-Score for 95% CI
            CI_bLow = (nanmean(AVSNBdataPeaks4{per},1)) + (ts_bLow*SEMb);  % Confidence Intervals
            CI_bHigh = (nanmean(AVSNBdataPeaks4{per},1)) + (ts_bHigh*SEMb);  % Confidence Intervals  
            %average
            AVSNCdataPeaks{per} = nanmean(AVSNCdataPeaks3{per});
            AVSNBdataPeaks{per} = nanmean(AVSNBdataPeaks4{per});

            %determine range of data Ca data
            CaDataRange = max(AVSNCdataPeaks{per})-min(AVSNCdataPeaks{per});
            %determine plotting buffer space for Ca data 
            CaBufferSpace = CaDataRange;
            %determine first set of plotting min and max values for Ca data
            CaPlotMin = min(AVSNCdataPeaks{per})-CaBufferSpace;
            CaPlotMax = max(AVSNCdataPeaks{per})+CaBufferSpace; 
            %determine Ca 0 ratio/location 
            CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);

            %determine range of BBB data 
            BBBdataRange = max(AVSNBdataPeaks{per})-min(AVSNBdataPeaks{per});
            %determine plotting buffer space for BBB data 
            BBBbufferSpace = BBBdataRange;
            %determine first set of plotting min and max values for BBB data
            BBBplotMin = min(AVSNBdataPeaks{per})-BBBbufferSpace;
            BBBplotMax = max(AVSNBdataPeaks{per})+BBBbufferSpace;
            %determine BBB 0 ratio/location
            BBBzeroRatio = abs(BBBplotMin)/(BBBplotMax-BBBplotMin);
            %determine how much to shift the BBB axis so that the zeros align 
            BBBbelowZero = (BBBplotMax-BBBplotMin)*CaZeroRatio;
            BBBaboveZero = (BBBplotMax-BBBplotMin)-BBBbelowZero;
            
            if per == 1 
                perLabel = ("Peaks from entire experiment. ");
            elseif per == 2 
                perLabel = ("Peaks from stimulus. ");
            elseif per == 3 
                perLabel = ("Peaks peaks from reward. ");
            elseif per == 4 
                perLabel = ("Peaks from ITI. ");
            end 

            fig = figure; 
            Frames = size(AVSNCdataPeaks3{per},2);
            Frames_pre_stim_start = -((Frames-1)/2); 
            Frames_post_stim_start = (Frames-1)/2; 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
            FrameVals = round((1:FPSstack{mouse}:Frames)+9); 
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
%                         xLimStart = floor(10*FPSstack{mouse});
%                         xLimEnd = floor(24*FPSstack{mouse}); 
            xlim([1 size(AVSNCdataPeaks{per},2)])
            ylim([min(AVSNCdataPeaks{per}-CaBufferSpace) max(AVSNCdataPeaks{per}+CaBufferSpace)])
%             patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],[0 0 0.5],'EdgeColor','none')
            set(fig,'position', [500 100 900 800])
            alpha(0.3)

            %add right y axis tick marks for a specific DOD figure. 
            yyaxis right 
            plot(AVSNBdataPeaks{per},'r','LineWidth',4)
            patch([x fliplr(x)],[(CI_bLow) (fliplr(CI_bHigh))],[0.5 0 0],'EdgeColor','none')
            ylabel('BBB permeability percent change','FontName','Times')
            tlabel = sprintf('Mouse #%d. All Ca ROIs Averaged. BBB ROIs Averaged. ',mouse);
            title({sprintf('Mouse #%d. All Ca ROIs Averaged. BBB ROIs Averaged.',mouse);perLabel})                      
            alpha(0.3)
            set(gca,'YColor',[0 0 0]);
            ylim([-BBBbelowZero BBBaboveZero])
            %make the directory and save the images   
            if saveQ == 1  
                dir2 = strrep(dir1,'\','/');
                dir3 = sprintf('%s/%s%s.tif',dir2,tlabel,perLabel);
                export_fig(dir3)
            end             
        end 
    end
    
    if dataSaveQ == 1 
        save(fullfile(dir1,fileName));
    end     
end 


%}                     
%% STA: plot calcium spike triggered average (average across mice. compare close and far terminals.) 
% optimized for batch processing
% takes unsmoothed data and asks about smoothing
%{
%get the data you need 
mouseDistQ = input('Input 1 if you already have a .mat file mouse Ca ROI distances (for all data sets). Input 0 to make this .mat file. ');
if mouseDistQ == 1 
    regImDir = uigetdir('*.*','WHERE IS THE .MAT FILE THAT CONTAINS INFO ABOUT CA ROI DISTANCES?');
    cd(regImDir);
    MatFileName = uigetfile('*.*','SELECT THE .MAT FILE THAT CONTAINS INFO ABOUT CA ROI DISTANCES?');
    Mat = matfile(MatFileName);
    closeCaROIs = Mat.closeCaROIs;
    farCaROIs = Mat.farCaROIs; 
    totalMouseNums = length(farCaROIs);
end 
CaROIs = cell(1,totalMouseNums);
for mouse = 1:totalMouseNums
    if mouseDistQ == 0
        closeCaROIs{mouse} = input(sprintf('What are the close Ca ROIs for mouse #%d? ',mouse));
        farCaROIs{mouse} = input(sprintf('What are the far Ca ROIs for mouse #%d? ',mouse));
    end 
    CaROIs{mouse} = horzcat(closeCaROIs{mouse},farCaROIs{mouse});
end 
terminals = CaROIs;
CAQ = input('Input 1 if there is Ca data to plot. ');
BBBQ = input('Input 1 if there is BBB data to plot. ');
VWQ = input('Input 1 if there is VW data to plot. ');
mouseNum = input('How many mice are there? ');  
sortedCdata = cell(1,mouseNum);
sortedVdata = cell(1,mouseNum);
sortedBdata = cell(1,mouseNum);
FPSstack = cell(1,mouseNum);
vidList = cell(1,mouseNum);
for mouse = 1:mouseNum
    regImDir = uigetdir('*.*',sprintf('WHERE IS THE STA DATA FOR MOUSE #%d?',mouse));
    cd(regImDir);
    MatFileName = uigetfile('*.*',sprintf('SELECT THE STA DATA FOR MOUSE #%d',mouse));
    Mat = matfile(MatFileName);   
    if CAQ == 1
        sortedCdata{mouse} = Mat.sortedCdata;
    end 
    if VWQ == 1 
        sortedVdata{mouse} = Mat.sortedVdata;
    end 
    if BBBQ == 1
        sortedBdata{mouse} = Mat.sortedBdata;
    end 
    if ~iscell(Mat.FPSstack)
        FPSstack{mouse} = Mat.FPSstack;
        vidList{mouse} = Mat.vidList;
    elseif iscell(Mat.FPSstack)
        if mouse == 1 
            FPSstack = Mat.FPSstack;
            vidList = Mat.vidList;
        end 
    end 
end 

dataSetQ = input('Input 1 to load another data set and append to the relevant variables. '); 
while dataSetQ == 1
    %get the additional data you need 
    mouseNum2 = input('How many mice are there? ');
    sortedCdata2 = cell(1,mouseNum);
    sortedVdata2 = cell(1,mouseNum);
    sortedBdata2 = cell(1,mouseNum);
    FPSstack2 = cell(1,mouseNum);
    vidList2 = cell(1,mouseNum);
    for mouse = 1:mouseNum2
        regImDir = uigetdir('*.*',sprintf('WHERE IS THE STA DATA FOR MOUSE #%d?',mouse));
        cd(regImDir);
        MatFileName = uigetfile('*.*',sprintf('SELECT THE STA DATA FOR MOUSE #%d',mouse));
        Mat = matfile(MatFileName);   
        if CAQ == 1
            sortedCdata2{mouse} = Mat.sortedCdata;
        end 
        if VWQ == 1 
            sortedVdata2{mouse} = Mat.sortedVdata;
        end 
        if BBBQ == 1
            sortedBdata2{mouse} = Mat.sortedBdata;
        end 
        if ~iscell(Mat.FPSstack)
            FPSstack2{mouse} = Mat.FPSstack;
            vidList2{mouse} = Mat.vidList;
        elseif iscell(Mat.FPSstack)
            if mouse == 1 
                FPSstack2 = Mat.FPSstack;
                vidList2 = Mat.vidList;
            end 
        end 
    end 
    % append new data to original variables 
    mouseNum1 = mouseNum; mouseNum = mouseNum + mouseNum2;
    for mouse = 1:mouseNum2
        if CAQ == 1 
            sortedCdata{mouseNum1+mouse} = sortedCdata2{mouse};
        end 
        if BBBQ == 1
            sortedBdata{mouseNum1+mouse} = sortedBdata2{mouse};
        end 
        if VWQ == 1 
            sortedVdata{mouseNum1+mouse} = sortedVdata2{mouse};
        end 
        FPSstack{mouseNum1+mouse} = FPSstack2{mouse};
        vidList{mouseNum1+mouse} = vidList2{mouse};
    end
    dataSetQ = input('Input 1 to load another data set and append to the relevant variables. Input 0 otherwise. '); 
end

if mouseDistQ == 0 
    saveDir = uigetdir('*.*','WHERE DO YOU WANT TO SAVE THE CA ROI DISTANCE DATA FOR MULTIPLE MICE?');
    cd(saveDir);
    save('CaROIdistances.mat','closeCaROIs','farCaROIs')
end 

%% sort data 
SCdataPeaks = cell(1,mouseNum);
SNCdataPeaks = cell(1,mouseNum);
sortedCdata2 = cell(1,mouseNum);
allCTraces3 = cell(1,mouseNum);
if BBBQ == 1
    SBdataPeaks = cell(1,mouseNum);
    SNBdataPeaks = cell(1,mouseNum);
    sortedBdata2 = cell(1,mouseNum);
    allBTraces3 = cell(1,mouseNum);
end 
if VWQ == 1 
    SVdataPeaks = cell(1,mouseNum);
    SNVdataPeaks = cell(1,mouseNum);
    sortedVdata2 = cell(1,mouseNum);
    allVTraces3 = cell(1,mouseNum);
end     
baselineTime = 5;
for mouse = 1:mouseNum   
    %smoothing option
    if mouse == 1 
        smoothQ = input('Input 0 to plot non-smoothed data. Input 1 to plot smoothed data. ');
    end         
    if smoothQ == 0 
        if BBBQ == 1
            SBdataPeaks{mouse} = sortedBdata{mouse};
        end 
        SCdataPeaks{mouse} = sortedCdata{mouse};
        if VWQ == 1
            SVdataPeaks{mouse} = sortedVdata{mouse};
        end 
    elseif smoothQ == 1
        if mouse == 1 
            filtTime = input('How many seconds do you want to smooth your data by? ');
        end             
        SCdataPeaks{mouse} = sortedCdata{mouse};
        for vid = 1:length(vidList{mouse})
            for ccell = 1:length(terminals{mouse})
               if vid <= length(sortedCdata{mouse}) 
                    for per = 1:length(sortedCdata{mouse}{vid}{terminals{mouse}(ccell)}) 
                        if isempty(sortedCdata{mouse}{vid}{terminals{mouse}(ccell)}{per}) == 0 
                            if BBBQ == 1
                                for BBBroi = 1:length(sortedBdata{mouse}{vid})
                                    [sB_Data] = MovMeanSmoothData(sortedBdata{mouse}{vid}{BBBroi}{terminals{mouse}(ccell)}{per},filtTime,FPSstack{mouse});
                                    SBdataPeaks{mouse}{vid}{BBBroi}{terminals{mouse}(ccell)}{per} = sB_Data;
                                    %remove rows full of 0s if there are any b = a(any(a,2),:)
                                    SBdataPeaks{mouse}{vid}{BBBroi}{terminals{mouse}(ccell)}{per} = SBdataPeaks{mouse}{vid}{BBBroi}{terminals{mouse}(ccell)}{per}(any(SBdataPeaks{mouse}{vid}{BBBroi}{terminals{mouse}(ccell)}{per},2),:);
                                end
                            end 
                            if VWQ == 1
                                for VWroi = 1:length(sortedVdata{mouse}{vid})
                                    [sV_Data] = MovMeanSmoothData(sortedVdata{mouse}{vid}{VWroi}{terminals{mouse}(ccell)}{per},filtTime,FPSstack{mouse});
                                    SVdataPeaks{mouse}{vid}{VWroi}{terminals{mouse}(ccell)}{per} = sV_Data;
                                    %remove rows full of 0s if there are any b = a(any(a,2),:)
                                    SVdataPeaks{mouse}{vid}{VWroi}{terminals{mouse}(ccell)}{per} = SVdataPeaks{mouse}{vid}{VWroi}{terminals{mouse}(ccell)}{per}(any(SVdataPeaks{mouse}{vid}{VWroi}{terminals{mouse}(ccell)}{per},2),:);
                                end 
                            end 
                            %remove rows full of 0s if there are any b = a(any(a,2),:)
                            SCdataPeaks{mouse}{vid}{terminals{mouse}(ccell)}{per} = SCdataPeaks{mouse}{vid}{terminals{mouse}(ccell)}{per}(any(SCdataPeaks{mouse}{vid}{terminals{mouse}(ccell)}{per},2),:);                 
                        end 
                    end
               end 
            end 
        end 
    end     
    
    %normalize
     for vid = 1:length(vidList{mouse})
        for ccell = 1:length(terminals{mouse})
            if vid <= length(sortedCdata{mouse}) 
                for per = 1:length(sortedCdata{mouse}{vid}{terminals{mouse}(ccell)})
                    if isempty(sortedCdata{mouse}{vid}{terminals{mouse}(ccell)}{per}) == 0 
                        %the data needs to be added to because there are some
                        %negative gonig points which mess up the normalizing 
                        if BBBQ == 1
                            for BBBroi = 1:length(sortedBdata{mouse}{vid})
                                % determine the minimum value, add space (+100)
                                minValToAdd = abs(ceil(min(min(SBdataPeaks{mouse}{vid}{BBBroi}{terminals{mouse}(ccell)}{per}))))+100;
                                % add min value 
                                sortedBdata2{mouse}{vid}{BBBroi}{terminals{mouse}(ccell)}{per} = SBdataPeaks{mouse}{vid}{BBBroi}{terminals{mouse}(ccell)}{per} + minValToAdd;
                            end
                        end 
                        % determine the minimum value, add space (+100)
                        minValToAdd = abs(ceil(min(min(SCdataPeaks{mouse}{vid}{terminals{mouse}(ccell)}{per}))))+100;
                        % add min value
                        sortedCdata2{mouse}{vid}{terminals{mouse}(ccell)}{per} = SCdataPeaks{mouse}{vid}{terminals{mouse}(ccell)}{per} + minValToAdd;
                        if VWQ == 1
                            for VWroi = 1:length(sortedVdata{mouse}{vid})
                                % determine the minimum value, add space (+100)
                                minValToAdd = abs(ceil(min(min(SVdataPeaks{mouse}{vid}{VWroi}{terminals{mouse}(ccell)}{per}))))+100;
                                % add min value
                                sortedVdata2{mouse}{vid}{VWroi}{terminals{mouse}(ccell)}{per} = SVdataPeaks{mouse}{vid}{VWroi}{terminals{mouse}(ccell)}{per} + minValToAdd;
                            end 
                        end 

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

                        if BBBQ == 1
                            for BBBroi = 1:length(sortedBdata{mouse}{vid})
                                if isempty(sortedBdata2{mouse}{vid}{BBBroi}{terminals{mouse}(ccell)}{per}) == 0
                                    SNBdataPeaks{mouse}{vid}{BBBroi}{terminals{mouse}(ccell)}{per} = ((sortedBdata2{mouse}{vid}{BBBroi}{terminals{mouse}(ccell)}{per})./(nanmean(sortedBdata2{mouse}{vid}{BBBroi}{terminals{mouse}(ccell)}{per}(:,BLstart:changePt),2)))*100;
                                end 
                            end 
                        end 
                        if isempty(sortedCdata2{mouse}{vid}{terminals{mouse}(ccell)}{per}) == 0 
                            SNCdataPeaks{mouse}{vid}{terminals{mouse}(ccell)}{per} = ((sortedCdata2{mouse}{vid}{terminals{mouse}(ccell)}{per})./(nanmean(sortedCdata2{mouse}{vid}{terminals{mouse}(ccell)}{per}(:,BLstart:changePt),2)))*100;
                        end 
                        if VWQ == 1
                            if isempty(sortedVdata2{mouse}{vid}{VWroi}{terminals{mouse}(ccell)}{per}) == 0 
                                for VWroi = 1:length(sortedVdata{mouse}{vid})
                                    SNVdataPeaks{mouse}{vid}{VWroi}{terminals{mouse}(ccell)}{per} = ((sortedVdata2{mouse}{vid}{VWroi}{terminals{mouse}(ccell)}{per})./(nanmean(sortedVdata2{mouse}{vid}{VWroi}{terminals{mouse}(ccell)}{per}(:,BLstart:changePt),2)))*100;
                                end 
                            end 
                        end 
                    end               
                end
            end 
        end 
     end     
    
    count = 1;
    for vid = 1:length(vidList{mouse})  
        if vid <= length(sortedCdata{mouse}) 
            for per = 1:length(sortedCdata{mouse}{vid}{terminals{mouse}(ccell)})
                for ccell = 1:size(CaROIs{mouse},2)
                    if isempty(SBdataPeaks{mouse}{vid}{BBBroi}{terminals{mouse}(ccell)}) == 0 
                        if isempty(SBdataPeaks{mouse}{vid}{BBBroi}{terminals{mouse}(ccell)}{per}) == 0 
                            for peak = 1:size(SNCdataPeaks{mouse}{vid}{terminals{mouse}(ccell)}{per},1) 
                                if BBBQ == 1
                                    for BBBroi = 1:length(sortedBdata{mouse}{vid})
                                        allBTraces3{mouse}{BBBroi}{terminals{mouse}(ccell)}{per}(count,:) = (SNBdataPeaks{mouse}{vid}{BBBroi}{terminals{mouse}(ccell)}{per}(peak,:)-100); 
                                        %remove rows full of 0s if there are any b = a(any(a,2),:)
                                        allBTraces3{mouse}{BBBroi}{terminals{mouse}(ccell)}{per} = allBTraces3{mouse}{BBBroi}{terminals{mouse}(ccell)}{per}(any(allBTraces3{mouse}{BBBroi}{terminals{mouse}(ccell)}{per},2),:);
                                    end 
                                end 
                                if VWQ == 1
                                    for VWroi = 1:length(sortedVdata{mouse}{vid})
                                        allVTraces3{mouse}{VWroi}{terminals{mouse}(ccell)}{per}(count,:) = (SNVdataPeaks{mouse}{vid}{VWroi}{terminals{mouse}(ccell)}{per}(peak,:)-100); 
                                        %remove rows full of 0s if there are any b = a(any(a,2),:)
                                        allVTraces3{mouse}{VWroi}{terminals{mouse}(ccell)}{per} = allVTraces3{mouse}{VWroi}{terminals{mouse}(ccell)}{per}(any(allVTraces3{mouse}{VWroi}{terminals{mouse}(ccell)}{per},2),:);                                    
                                    end 
                                end 
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
    end 
end 

%%
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


%% this plots individual STAs for every BBB and VW ROI per mouse as well as BBB VW ROI av per mouse 

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

% create colors for plotting 
Bcolors = [1,0,0;1,0.5,0;1,1,0];
Ccolors = [0,0,1;0,0.5,1;0,1,1];
Vcolors = [0,0,0;0.4,0.4,0.4;0.7,0.7,0.7];

% resort data: concatenate all CaROI data 
% output = CaArray{mouse}{per}(concatenated caRoi data)
% output = VW/BBBarray{mouse}{BBB/VWroi}{per}(concatenated caRoi data)
close_CI_cLow = cell(1,mouseNum);
close_CI_cHigh = cell(1,mouseNum);
far_CI_cLow = cell(1,mouseNum);
far_CI_cHigh = cell(1,mouseNum);
CI_cLow = cell(1,mouseNum);
CI_cHigh = cell(1,mouseNum);
close_AVSNBdataPeaksArray = cell(1,mouseNum);
far_AVSNBdataPeaksArray = cell(1,mouseNum);
close_AVSNVdataPeaksArray = cell(1,mouseNum);
far_AVSNVdataPeaksArray = cell(1,mouseNum);
close_CI_bLow_BBBroiAV = cell(1,mouseNum);
close_CI_bHigh_BBBroiAV = cell(1,mouseNum);
far_CI_bLow_BBBroiAV = cell(1,mouseNum);
far_CI_bHigh_BBBroiAV = cell(1,mouseNum);
close_CI_vLow_VWroiAV = cell(1,mouseNum);
close_CI_vHigh_VWroiAV = cell(1,mouseNum);
far_CI_vLow_VWroiAV = cell(1,mouseNum);
far_CI_vHigh_VWroiAV = cell(1,mouseNum);
for mouse = 1:mouseNum
    for per = 1:length(allCTraces3{mouse}{CaROIs{mouse}(2)})
        if isempty(allCTraces3{mouse}{CaROIs{mouse}(2)}{per}) == 0 
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
                count = 1;
                count2 = 1;
                for BBBroi = 1:length(BBBrois{mouse})
                    close_AVSNBdataPeaks{mouse}{BBBroi}{per} = nanmean(closeBTraceArray{mouse}{BBBroi}{per},1);
                    far_AVSNBdataPeaks{mouse}{BBBroi}{per} = nanmean(farBTraceArray{mouse}{BBBroi}{per},1);
                    AVSNBdataPeaks{mouse}{BBBroi}{per} = nanmean(BTraceArray{mouse}{BBBroi}{per},1);                    
                    for trace = 1:size(closeBTraceArray{mouse}{BBBroi}{per},1)
                        close_AVSNBdataPeaksArray{mouse}{per}(count,:) = closeBTraceArray{mouse}{BBBroi}{per}(trace,:);
                        count = count + 1;
                    end                    
                    for trace = 1:size(closeBTraceArray{mouse}{BBBroi}{per},1)
                        far_AVSNBdataPeaksArray{mouse}{per}(count2,:) = nanmean(farBTraceArray{mouse}{BBBroi}{per},1);
                        count2 = count2 + 1;
                    end 
                end 
                % determine 95% CI across BBB ROIs 
                close_SEMb = (nanstd(close_AVSNBdataPeaksArray{mouse}{per}))/(sqrt(size(close_AVSNBdataPeaksArray{mouse}{per},1))); % Standard Error            
                close_ts_bLow = tinv(0.025,size(close_AVSNBdataPeaksArray{mouse}{per},1)-1);% T-Score for 95% CI
                close_ts_bHigh = tinv(0.975,size(close_AVSNBdataPeaksArray{mouse}{per},1)-1);% T-Score for 95% CI
                close_CI_bLow_BBBroiAV{mouse}{per} = (nanmean(close_AVSNBdataPeaksArray{mouse}{per},1)) + (close_ts_bLow*close_SEMb);  % Confidence Intervals
                close_CI_bHigh_BBBroiAV{mouse}{per} = (nanmean(close_AVSNBdataPeaksArray{mouse}{per},1)) + (close_ts_bHigh*close_SEMb);  
                
                far_SEMb = (nanstd(far_AVSNBdataPeaksArray{mouse}{per}))/(sqrt(size(far_AVSNBdataPeaksArray{mouse}{per},1))); % Standard Error            
                far_ts_bLow = tinv(0.025,size(far_AVSNBdataPeaksArray{mouse}{per},1)-1);% T-Score for 95% CI
                far_ts_bHigh = tinv(0.975,size(far_AVSNBdataPeaksArray{mouse}{per},1)-1);% T-Score for 95% CI
                far_CI_bLow_BBBroiAV{mouse}{per} = (nanmean(far_AVSNBdataPeaksArray{mouse}{per},1)) + (far_ts_bLow*far_SEMb);  % Confidence Intervals
                far_CI_bHigh_BBBroiAV{mouse}{per} = (nanmean(far_AVSNBdataPeaksArray{mouse}{per},1)) + (far_ts_bHigh*far_SEMb);  
            end 
            close_AVSNCdataPeaks{mouse}{per} = nanmean(closeCTraceArray{mouse}{per},1);
            far_AVSNCdataPeaks{mouse}{per} = nanmean(farCTraceArray{mouse}{per},1);
            AVSNCdataPeaks{mouse}{per} = nanmean(CTraceArray{mouse}{per},1);
            if VWQ == 1
                count = 1;
                count2 = 1;
                for VWroi = 1:VWroiNum(mouse)
                    close_AVSNVdataPeaks{mouse}{VWroi}{per} = nanmean(closeVTraceArray{mouse}{VWroi}{per},1);
                    far_AVSNVdataPeaks{mouse}{VWroi}{per} = nanmean(farVTraceArray{mouse}{VWroi}{per},1);
                    AVSNVdataPeaks{mouse}{VWroi}{per} = nanmean(VTraceArray{mouse}{VWroi}{per},1);
                    for trace = 1:size(closeVTraceArray{mouse}{VWroi}{per},1)
                        close_AVSNVdataPeaksArray{mouse}{per}(count,:) = closeVTraceArray{mouse}{VWroi}{per}(trace,:);
                        count = count + 1;
                    end                    
                    for trace = 1:size(closeVTraceArray{mouse}{VWroi}{per},1)
                        far_AVSNVdataPeaksArray{mouse}{per}(count2,:) = nanmean(farVTraceArray{mouse}{VWroi}{per},1);
                        count2 = count2 + 1;
                    end 
                end 
                % determine 95% CI across BBB ROIs 
                close_SEMv = (nanstd(close_AVSNVdataPeaksArray{mouse}{per}))/(sqrt(size(close_AVSNVdataPeaksArray{mouse}{per},1))); % Standard Error            
                close_ts_vLow = tinv(0.025,size(close_AVSNVdataPeaksArray{mouse}{per},1)-1);% T-Score for 95% CI
                close_ts_vHigh = tinv(0.975,size(close_AVSNVdataPeaksArray{mouse}{per},1)-1);% T-Score for 95% CI
                close_CI_vLow_VWroiAV{mouse}{per} = (nanmean(close_AVSNVdataPeaksArray{mouse}{per},1)) + (close_ts_vLow*close_SEMv);  % Confidence Intervals
                close_CI_vHigh_VWroiAV{mouse}{per} = (nanmean(close_AVSNVdataPeaksArray{mouse}{per},1)) + (close_ts_vHigh*close_SEMv);  
                
                far_SEMv = (nanstd(far_AVSNVdataPeaksArray{mouse}{per}))/(sqrt(size(far_AVSNVdataPeaksArray{mouse}{per},1))); % Standard Error            
                far_ts_vLow = tinv(0.025,size(far_AVSNVdataPeaksArray{mouse}{per},1)-1);% T-Score for 95% CI
                far_ts_vHigh = tinv(0.975,size(far_AVSNVdataPeaksArray{mouse}{per},1)-1);% T-Score for 95% CI
                far_CI_vLow_VWroiAV{mouse}{per} = (nanmean(far_AVSNVdataPeaksArray{mouse}{per},1)) + (far_ts_vLow*far_SEMv);  % Confidence Intervals
                far_CI_vHigh_VWroiAV{mouse}{per} = (nanmean(far_AVSNVdataPeaksArray{mouse}{per},1)) + (far_ts_vHigh*far_SEMv);
            end 
            
            % plot individual Ca ROI traces for all mice at once 
            if isempty(close_AVSNCdataPeaks{mouse}) == 0
                % plot close and far data 
                if BBBQ == 1
                    for BBBroi = 1:length(BBBrois{mouse})
                        %determine range of data Ca data
                        CaDataRange = max(close_AVSNCdataPeaks{mouse}{per})-min(close_AVSNCdataPeaks{mouse}{per});
                        %determine plotting buffer space for Ca data 
                        CaBufferSpace = CaDataRange;
                        %determine first set of plotting min and max values for Ca data
                        CaPlotMin = min(close_AVSNCdataPeaks{mouse}{per})-CaBufferSpace;
                        CaPlotMax = max(close_AVSNCdataPeaks{mouse}{per})+CaBufferSpace; 
                        %determine Ca 0 ratio/location 
                        CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);

                        %determine range of BBB data 
                        BBBdataRange = max(close_AVSNBdataPeaks{mouse}{BBBroi}{per})-min(close_AVSNBdataPeaks{mouse}{BBBroi}{per});
                        %determine plotting buffer space for BBB data 
                        BBBbufferSpace = BBBdataRange;
                        %determine first set of plotting min and max values for BBB data
                        BBBplotMin = min(close_AVSNBdataPeaks{mouse}{BBBroi}{per})-BBBbufferSpace;
                        BBBplotMax = max(close_AVSNBdataPeaks{mouse}{BBBroi}{per})+BBBbufferSpace;
                        %determine BBB 0 ratio/location
                        BBBzeroRatio = abs(BBBplotMin)/(BBBplotMax-BBBplotMin);
                        %determine how much to shift the BBB axis so that the zeros align 
                        BBBbelowZero = (BBBplotMax-BBBplotMin)*CaZeroRatio;
                        BBBaboveZero = (BBBplotMax-BBBplotMin)-BBBbelowZero;
                        
                        
                        fig = figure;
                        Frames = size(closeCTraceArray{mouse}{per},2);
                        Frames_pre_stim_start = -((Frames-1)/2); 
                        Frames_post_stim_start = (Frames-1)/2; 
                        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
                        FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
                        ax=gca;
                        hold all
                        plot(close_AVSNCdataPeaks{mouse}{per},'Color',Ccolors(1,:),'LineWidth',4)
                        patch([x fliplr(x)],[close_CI_cLow{mouse}{per} fliplr(close_CI_cHigh{mouse}{per})],Ccolors(1,:),'EdgeColor','none')
                        plot(far_AVSNCdataPeaks{mouse}{per},'Color',Ccolors(2,:),'LineWidth',4)
                        patch([x fliplr(x)],[far_CI_cLow{mouse}{per} fliplr(far_CI_cHigh{mouse}{per})],Ccolors(2,:),'EdgeColor','none')
                        changePt = floor(Frames/2)-floor(0.25*FPSstack{mouse});
                        ax.XTick = FrameVals;
                        ax.XTickLabel = sec_TimeVals;   
                        ax.FontSize = 25;
                        ax.FontName = 'Times';
                        xlabel('time (s)','FontName','Times')
                        ylabel('calcium signal percent change','FontName','Times')
                        xLimStart = floor(10*FPSstack{mouse});
                        xLimEnd = floor(24*FPSstack{mouse}); 
                        xlim([1 size(close_AVSNCdataPeaks{mouse}{per},2)])
                        ylim([min(close_AVSNCdataPeaks{mouse}{per}-CaBufferSpace) max(close_AVSNCdataPeaks{mouse}{per}+CaBufferSpace)])
                        set(fig,'position', [500 100 900 800])
                        alpha(0.3)
                        %add right y axis tick marks for a specific DOD figure. 
                        yyaxis right 
                        p(1) = plot(close_AVSNBdataPeaks{mouse}{BBBroi}{per},'Color',Bcolors(1,:),'LineWidth',4);
                        patch([x fliplr(x)],[(close_CI_bLow{mouse}{BBBroi}{per}) (fliplr(close_CI_bHigh{mouse}{BBBroi}{per}))],Bcolors(1,:),'EdgeColor','none')
                        p(2) = plot(far_AVSNBdataPeaks{mouse}{BBBroi}{per},'-','Color',Bcolors(2,:),'LineWidth',4);
                        patch([x fliplr(x)],[(far_CI_bLow{mouse}{BBBroi}{per}) (fliplr(far_CI_bHigh{mouse}{BBBroi}{per}))],Bcolors(2,:),'EdgeColor','none')
                        ylabel('BBB permeability percent change','FontName','Times')
                        title(sprintf('Close Terminals. Mouse %d. BBB ROI %d.',mouse,BBBroi))
                        alpha(0.3)
                        legend([p(1) p(2)],'Close Terminals','Far Terminals')
                        set(gca,'YColor',[0 0 0]);   
                        ylim([-BBBbelowZero BBBaboveZero])
                    end 
                    
                    fig = figure;
                    Frames = size(closeCTraceArray{mouse}{per},2);
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
                    FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
                    ax=gca;
                    hold all
                    plot(close_AVSNCdataPeaks{mouse}{per},'Color',Ccolors(1,:),'LineWidth',4)
                    patch([x fliplr(x)],[close_CI_cLow{mouse}{per} fliplr(close_CI_cHigh{mouse}{per})],Ccolors(1,:),'EdgeColor','none')
                    plot(far_AVSNCdataPeaks{mouse}{per},'Color',Ccolors(2,:),'LineWidth',4)
                    patch([x fliplr(x)],[far_CI_cLow{mouse}{per} fliplr(far_CI_cHigh{mouse}{per})],Ccolors(2,:),'EdgeColor','none')
                    changePt = floor(Frames/2)-floor(0.25*FPSstack{mouse});
                    ax.XTick = FrameVals;
                    ax.XTickLabel = sec_TimeVals;   
                    ax.FontSize = 25;
                    ax.FontName = 'Times';
                    xlabel('time (s)','FontName','Times')
                    ylabel('calcium signal percent change','FontName','Times')
                    xLimStart = floor(10*FPSstack{mouse});
                    xLimEnd = floor(24*FPSstack{mouse}); 
                    xlim([1 size(close_AVSNCdataPeaks{mouse}{per},2)])
                    ylim([min(close_AVSNCdataPeaks{mouse}{per}-CaBufferSpace) max(close_AVSNCdataPeaks{mouse}{per}+CaBufferSpace)])
                    set(fig,'position', [500 100 900 800])
                    alpha(0.3)
                    %add right y axis tick marks for a specific DOD figure. 
                    yyaxis right 
                    p(1) = plot(nanmean(close_AVSNBdataPeaksArray{mouse}{per},1),'Color',Bcolors(1,:),'LineWidth',4);
                    patch([x fliplr(x)],[(close_CI_bLow_BBBroiAV{mouse}{per}) (fliplr(close_CI_bHigh_BBBroiAV{mouse}{per}))],Bcolors(1,:),'EdgeColor','none')
                    p(2) = plot(nanmean(far_AVSNBdataPeaksArray{mouse}{per},1),'-','Color',Bcolors(2,:),'LineWidth',4);
                    patch([x fliplr(x)],[(far_CI_bLow_BBBroiAV{mouse}{per}) (fliplr(far_CI_bHigh_BBBroiAV{mouse}{per}))],Bcolors(2,:),'EdgeColor','none')
                    ylabel('BBB permeability percent change','FontName','Times')
                    title(sprintf('Close Terminals. Mouse %d. BBB ROIs Averaged.',mouse))
                    alpha(0.3)
                    legend([p(1) p(2)],'Close Terminals','Far Terminals')
                    set(gca,'YColor',[0 0 0]);   
                    ylim([-BBBbelowZero BBBaboveZero])                    
                end 

                if VWQ == 1
                    for VWroi = 1:VWroiNum(mouse)     
                        %determine range of data Ca data
                        CaDataRange = max(close_AVSNCdataPeaks{mouse}{per})-min(close_AVSNCdataPeaks{mouse}{per});
                        %determine plotting buffer space for Ca data 
                        CaBufferSpace = CaDataRange;
                        %determine first set of plotting min and max values for Ca data
                        CaPlotMin = min(close_AVSNCdataPeaks{mouse}{per})-CaBufferSpace;
                        CaPlotMax = max(close_AVSNCdataPeaks{mouse}{per})+CaBufferSpace; 
                        %determine Ca 0 ratio/location 
                        CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);

                        %determine range of BBB data 
                        VWdataRange = max(close_AVSNVdataPeaks{mouse}{VWroi}{per})-min(close_AVSNVdataPeaks{mouse}{VWroi}{per});
                        %determine plotting buffer space for BBB data 
                        VWbufferSpace = VWdataRange;
                        %determine first set of plotting min and max values for BBB data
                        VWplotMin = min(close_AVSNVdataPeaks{mouse}{VWroi}{per})-VWbufferSpace;
                        VWplotMax = max(close_AVSNVdataPeaks{mouse}{VWroi}{per})+VWbufferSpace;
                        %determine BBB 0 ratio/location
                        VWzeroRatio = abs(VWplotMin)/(VWplotMax-VWplotMin);
                        %determine how much to shift the BBB axis so that the zeros align 
                        VWbelowZero = (VWplotMax-VWplotMin)*CaZeroRatio;
                        VWaboveZero = (VWplotMax-VWplotMin)-VWbelowZero;
                        
                        
                        fig = figure;
                        Frames = size(closeCTraceArray{mouse}{per},2);
                        Frames_pre_stim_start = -((Frames-1)/2); 
                        Frames_post_stim_start = (Frames-1)/2; 
                        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
                        FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
                        ax=gca;
                        hold all
                        plot(close_AVSNCdataPeaks{mouse}{per},'Color',Ccolors(1,:),'LineWidth',4)
                        patch([x fliplr(x)],[close_CI_cLow{mouse}{per} fliplr(close_CI_cHigh{mouse}{per})],Ccolors(1,:),'EdgeColor','none')
                        plot(far_AVSNCdataPeaks{mouse}{per},'Color',Ccolors(2,:),'LineWidth',4)
                        patch([x fliplr(x)],[far_CI_cLow{mouse}{per} fliplr(far_CI_cHigh{mouse}{per})],Ccolors(2,:),'EdgeColor','none')
                        changePt = floor(Frames/2)-floor(0.25*FPSstack{mouse});
                        ax.XTick = FrameVals;
                        ax.XTickLabel = sec_TimeVals;   
                        ax.FontSize = 25;
                        ax.FontName = 'Times';
                        xlabel('time (s)','FontName','Times')
                        ylabel('calcium signal percent change','FontName','Times')
                        xLimStart = floor(10*FPSstack{mouse});
                        xLimEnd = floor(24*FPSstack{mouse}); 
                        xlim([1 size(close_AVSNCdataPeaks{mouse}{per},2)])
                        ylim([min(close_AVSNCdataPeaks{mouse}{per}-CaBufferSpace) max(close_AVSNCdataPeaks{mouse}{per}+CaBufferSpace)])
                        set(fig,'position', [500 100 900 800])
                        alpha(0.3)
                        %add right y axis tick marks for a specific DOD figure. 
                        yyaxis right 
                        p(1) = plot(close_AVSNVdataPeaks{mouse}{VWroi}{per},'Color',Vcolors(1,:),'LineWidth',4);
                        patch([x fliplr(x)],[(close_CI_vLow{mouse}{VWroi}{per}) (fliplr(close_CI_vHigh{mouse}{VWroi}{per}))],Vcolors(1,:),'EdgeColor','none')
                        p(2) = plot(far_AVSNVdataPeaks{mouse}{VWroi}{per},'-','Color',Vcolors(2,:),'LineWidth',4);
                        patch([x fliplr(x)],[(far_CI_vLow{mouse}{VWroi}{per}) (fliplr(far_CI_vHigh{mouse}{VWroi}{per}))],Vcolors(2,:),'EdgeColor','none')
                        ylabel('VW permeability percent change','FontName','Times')
                        title(sprintf('Close Terminals. Mouse %d. VW ROI %d.',mouse,VWroi))
                        alpha(0.3)
                        legend([p(1) p(2)],'Close Terminals','Far Terminals')
                        set(gca,'YColor',[0 0 0]);   
                        ylim([-VWbelowZero VWaboveZero])
                    end 
                    
                    fig = figure;
                    Frames = size(closeCTraceArray{mouse}{per},2);
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
                    FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
                    ax=gca;
                    hold all
                    plot(close_AVSNCdataPeaks{mouse}{per},'Color',Ccolors(1,:),'LineWidth',4)
                    patch([x fliplr(x)],[close_CI_cLow{mouse}{per} fliplr(close_CI_cHigh{mouse}{per})],Ccolors(1,:),'EdgeColor','none')
                    plot(far_AVSNCdataPeaks{mouse}{per},'Color',Ccolors(2,:),'LineWidth',4)
                    patch([x fliplr(x)],[far_CI_cLow{mouse}{per} fliplr(far_CI_cHigh{mouse}{per})],Ccolors(2,:),'EdgeColor','none')
                    changePt = floor(Frames/2)-floor(0.25*FPSstack{mouse});
                    ax.XTick = FrameVals;
                    ax.XTickLabel = sec_TimeVals;   
                    ax.FontSize = 25;
                    ax.FontName = 'Times';
                    xlabel('time (s)','FontName','Times')
                    ylabel('calcium signal percent change','FontName','Times')
                    xLimStart = floor(10*FPSstack{mouse});
                    xLimEnd = floor(24*FPSstack{mouse}); 
                    xlim([1 size(close_AVSNCdataPeaks{mouse}{per},2)])
                    ylim([min(close_AVSNCdataPeaks{mouse}{per}-CaBufferSpace) max(close_AVSNCdataPeaks{mouse}{per}+CaBufferSpace)])
                    set(fig,'position', [500 100 900 800])
                    alpha(0.3)
                    %add right y axis tick marks for a specific DOD figure. 
                    yyaxis right 
                    p(1) = plot(nanmean(close_AVSNVdataPeaksArray{mouse}{per},1),'Color',Vcolors(1,:),'LineWidth',4);
                    patch([x fliplr(x)],[(close_CI_vLow_VWroiAV{mouse}{per}) (fliplr(close_CI_vHigh_VWroiAV{mouse}{per}))],Vcolors(1,:),'EdgeColor','none')
                    p(2) = plot(nanmean(far_AVSNVdataPeaksArray{mouse}{per},1),'-','Color',Vcolors(2,:),'LineWidth',4);
                    patch([x fliplr(x)],[(far_CI_vLow_VWroiAV{mouse}{per}) (fliplr(far_CI_vHigh_VWroiAV{mouse}{per}))],Vcolors(2,:),'EdgeColor','none')
                    ylabel('VW permeability percent change','FontName','Times')
                    title(sprintf('Close Terminals. Mouse %d. VW ROIs Averaged.',mouse))
                    alpha(0.3)
                    legend([p(1) p(2)],'Close Terminals','Far Terminals')
                    set(gca,'YColor',[0 0 0]);   
                    ylim([-VWbelowZero VWaboveZero])                    
                end 
            end
        end 
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
                if BBBroi <= length(closeBTraceArray{mouseNums(mouse)})
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
                if VWroi <= length(closeVTraceArray{mouseNums(mouse)})
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

realMouseNum = input('How many unique mice are apart of this data set? ');
CaROIcount1 = zeros(1,mouseNum);
spikeCount1 = cell(1,length(allCTraces3{mouse}{CaROIs{mouse}(2)}));
spikeCount = cell(1,length(allCTraces3{mouse}{CaROIs{mouse}(2)}));
count = 1;
for mouse = 1:mouseNum
    CaROIcount1(mouse) = length(CaROIs{mouse});
    for per = 1:length(allCTraces3{mouse}{CaROIs{mouse}(2)})
        if isempty(allCTraces3{mouse}{CaROIs{mouse}(2)}{per}) == 0 
            for ccell = 1:length(closeCTraces{mouse})
                if isempty(closeCTraces{mouse}{ccell}) == 0 
                    if isempty(allCTraces3{mouse}{terminals{mouse}(ccell)}) == 0
                        spikeCount1{per}(count) = size(allCTraces3{mouse}{terminals{mouse}(ccell)}{per},1);
                        count = count + 1;
                    end 
                end 
            end 
        end 
        spikeCount{per} = sum(spikeCount1{per});
    end 
end 
CaROIcount = sum(CaROIcount1);

%% plot
for per = 1:length(allCTraces3{1}{CaROIs{1}(2)})
    if isempty(allCTraces3{1}{CaROIs{1}(2)}{per}) == 0 
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
            %bootstrap the data then determine 95% CI of bootstrapped data 
            %determine how many bootstrapped samples you need to have 6x the original
            %data set 
            numBSbData = (50000);%size(Btraces_allMice{per},1)*6;
            BSbData = zeros(size(Btraces_allMice{per},1)*6,size(Btraces_allMice{per},2));
            for trace = 1:numBSbData
                BSbData(trace,:) = Btraces_allMice{per}(randsample(size(Btraces_allMice{per},1),1),:); 
            end 
            SEMbbs = (nanstd(BSbData))/(sqrt(size(BSbData,1))); % Standard Error            
            STDbbs = nanstd(BSbData);
            ts_bbsLow = tinv(0.025,size(BSbData,1)-1);% T-Score for 95% CI
            ts_bbsHigh = tinv(0.975,size(BSbData,1)-1);% T-Score for 95% CI
            CI_bbsLow = (nanmean(BSbData,1)) + (ts_bbsLow*SEMbbs);  % Confidence Intervals
            CI_bbsHigh = (nanmean(BSbData,1)) + (ts_bbsHigh*SEMbbs);  % Confidence Intervals
            BSbMean = nanmean(BSbData,1);
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
        %bootstrap the data then determine 95% CI of bootstrapped data 
        %determine how many bootstrapped samples you need to have 6x the original
        %data set 
        numBScData = (50000);%size(Ctraces_allMice{per},1)*6;
        BScData = zeros(size(Ctraces_allMice{per},1)*6,size(Ctraces_allMice{per},2));
        for trace = 1:numBScData
            BScData(trace,:) = Ctraces_allMice{per}(randsample(size(Ctraces_allMice{per},1),1),:); 
        end 
        SEMcbs = (nanstd(BScData))/(sqrt(size(BScData,1))); % Standard Error            
        STDcbs = nanstd(BScData);
        ts_cbsLow = tinv(0.025,size(BScData,1)-1);% T-Score for 95% CI
        ts_cbsHigh = tinv(0.975,size(BScData,1)-1);% T-Score for 95% CI
        CI_cbsLow = (nanmean(BScData,1)) + (ts_cbsLow*SEMcbs);  % Confidence Intervals
        CI_cbsHigh = (nanmean(BScData,1)) + (ts_cbsHigh*SEMcbs);  % Confidence Intervals
        BScMean = nanmean(BScData,1);
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
            %bootstrap the data then determine 95% CI of bootstrapped data 
            %determine how many bootstrapped samples you need to have 6x the original
            %data set 
            numBSvData = size(Vtraces_allMice{per},1)*6;
            BSvData = zeros(size(Vtraces_allMice{per},1)*6,size(Vtraces_allMice{per},2));
            for trace = 1:numBSvData
                BSvData(trace,:) = Vtraces_allMice{per}(randsample(size(Vtraces_allMice{per},1),1),:); 
            end 
            SEMvbs = (nanstd(BSvData))/(sqrt(size(BSvData,1))); % Standard Error            
            STDvbs = nanstd(BSvData);
            ts_vbsLow = tinv(0.025,size(BSvData,1)-1);% T-Score for 95% CI
            ts_vbsHigh = tinv(0.975,size(BSvData,1)-1);% T-Score for 95% CI
            CI_vbsLow = (nanmean(BSvData,1)) + (ts_vbsLow*SEMvbs);  % Confidence Intervals
            CI_vbsHigh = (nanmean(BSvData,1)) + (ts_vbsHigh*SEMvbs);  % Confidence Intervals
            BSvMean = nanmean(BSvData,1);
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
            if per == 1 
                tTypeQ = input('Input 0 if this is behavior data. Input 1 if this is opto data. ');
            end 
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
                if length(allCTraces3{1}{CaROIs{1}(2)}) == 1 
                    perLabel = ('Peaks from entire experiment. ');
                elseif length(allCTraces3{1}{CaROIs{1}(2)}) > 1 
                    if per == 1 
                        perLabel = ("Blue light on. ");
                    elseif per == 2 
                        perLabel = ("Red light on. ");
                    elseif per == 3 
                        perLabel = ("Light off. ");
                    end                     
                end 
            end 
        elseif dataQ == 1 
            perLabel = input('Input the per label. ');
        end 

        % plot close and far Ca ROI and BBB data (all mice averaged) overlaid 
        if BBBQ == 1
            %determine range of data Ca data
            CaDataRange = max(avCdata{per})-min(avCdata{per});
            %determine plotting buffer space for Ca data 
            CaBufferSpace = CaDataRange;
            %determine first set of plotting min and max values for Ca data
            CaPlotMin = min(avCdata{per})-CaBufferSpace;
            CaPlotMax = max(avCdata{per})+CaBufferSpace; 
            %determine Ca 0 ratio/location 
            CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);

            %determine range of BBB data 
            BBBdataRange = max(avBdata{per})-min(avBdata{per});
            %determine plotting buffer space for BBB data 
            BBBbufferSpace = BBBdataRange;
            %determine first set of plotting min and max values for BBB data
            BBBplotMin = min(avBdata{per})-BBBbufferSpace;
            BBBplotMax = max(avBdata{per})+BBBbufferSpace;
            %determine BBB 0 ratio/location
            BBBzeroRatio = abs(BBBplotMin)/(BBBplotMax-BBBplotMin);
            %determine how much to shift the BBB axis so that the zeros align 
            BBBbelowZero = (BBBplotMax-BBBplotMin)*CaZeroRatio;
            BBBaboveZero = (BBBplotMax-BBBplotMin)-BBBbelowZero;

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
            ax.XTick = FrameVals;
            ax.XTickLabel = sec_TimeVals;   
            ax.FontSize = 25;
            ax.FontName = 'Arial';
            xlabel('time (s)','FontName','Arial')
            ylabel('calcium signal percent change','FontName','Arial')
            xLimStart = floor(10*min(FPSstack2));
            xLimEnd = floor(24*min(FPSstack2)); 
            xlim([1 minLen])
            ylim([min(avCdata{per}-CaBufferSpace) max(avCdata{per}+CaBufferSpace)])
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
            ylabel('BBB permeability percent change','FontName','Arial')
            title({'All mice Averaged.';perLabel})
            ylim([-BBBbelowZero BBBaboveZero])
            alpha(0.3)
            set(gca,'YColor',[0 0 0]);              
            txt = {sprintf('%d animals',realMouseNum),sprintf('%d sessions',mouseNum),sprintf('%d Ca ROIs',CaROIcount),sprintf('%d Ca spikes',spikeCount{per})};
            text(2,-7,txt,'FontSize',14)
            
            fig = figure;
            ax=gca;
            hold all
            plot(avCdata{per},'b','LineWidth',4)
            patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],'b','EdgeColor','none')
            alpha(0.3)
            ax.XTick = FrameVals;
            ax.XTickLabel = sec_TimeVals;   
            ax.FontSize = 25;
            ax.FontName = 'Arial';
            xlabel('time (s)','FontName','Arial')
            ylabel('calcium signal percent change','FontName','Arial')
            xlim([1 minLen])
%             ylim([min(avCdata{per}-CaBufferSpace) max(avCdata{per}+CaBufferSpace)])
            set(fig,'position', [500 100 900 800])
            alpha(0.3)
            title({'All mice Averaged.';perLabel})
            yyaxis right 
            p(1) = plot(avBdata{per},'r','LineWidth',4);
            patch([x fliplr(x)],[(CI_bLow) (fliplr(CI_bHigh))],'r','EdgeColor','none')
            alpha(0.3)
        %     legend([p(1) p(2)],'Close Terminals','Far Terminals')
            ylabel({'BBB Permeability Percent Change'},'FontName','Arial')
        %     title({'DAT+ Axon Spike Triggered Average';'Red Light'})
            set(gca,'YColor',[0 0 0]); 
%             ylim([-BBBbelowZero BBBaboveZero])
            ylim([-0.6 4])
        %     legend('STA Red Light','STA Light Off', 'Optogenetic ETA')
            text(2,-7,txt,'FontSize',14)
%             set(gca, 'YScale', 'log')

            fig = figure;
            ax=gca;
            hold all
            plot(BScMean,'b','LineWidth',4)
            patch([x fliplr(x)],[ CI_cbsLow fliplr(CI_cbsHigh)],'b','EdgeColor','none')
            alpha(0.3)
            ax.XTick = FrameVals;
            ax.XTickLabel = sec_TimeVals;   
            ax.FontSize = 25;
            ax.FontName = 'Arial';
            xlabel('time (s)','FontName','Arial')
            ylabel('calcium signal percent change','FontName','Arial')
            xlim([1 minLen])
%             ylim([min(avCdata{per}-CaBufferSpace) max(avCdata{per}+CaBufferSpace)])
            set(fig,'position', [500 100 900 800])
            alpha(0.3)
            title({'All mice Averaged. Bootstrapped. ';perLabel})
            yyaxis right 
            p(1) = plot(BSbMean,'r','LineWidth',4);
            patch([x fliplr(x)],[(CI_bbsLow) (fliplr(CI_bbsHigh))],'r','EdgeColor','none')
            alpha(0.3)
        %     legend([p(1) p(2)],'Close Terminals','Far Terminals')
            ylabel({'BBB Permeability Percent Change'},'FontName','Arial')
        %     title({'DAT+ Axon Spike Triggered Average';'Red Light'})
            set(gca,'YColor',[0 0 0]); 
%             ylim([-BBBbelowZero BBBaboveZero])
            ylim([-0.6 4])
        %     legend('STA Red Light','STA Light Off', 'Optogenetic ETA')
            text(2,-7,txt,'FontSize',14)
%             set(gca, 'YScale', 'log')
        end 

        % plot close and far Ca ROI and VW data (all mice averaged) overlaid 
        if VWQ == 1
            %determine range of data Ca data
            CaDataRange = max(avCdata{per})-min(avCdata{per});
            %determine plotting buffer space for Ca data 
            CaBufferSpace = CaDataRange;
            %determine first set of plotting min and max values for Ca data
            CaPlotMin = min(avCdata{per})-CaBufferSpace;
            CaPlotMax = max(avCdata{per})+CaBufferSpace; 
            %determine Ca 0 ratio/location 
            CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);

            %determine range of BBB data 
            VWdataRange = max(avVdata{per})-min(avVdata{per});
            %determine plotting buffer space for BBB data 
            VWbufferSpace = VWdataRange;
            %determine first set of plotting min and max values for BBB data
            VWplotMin = min(avVdata{per})-VWbufferSpace;
            VWplotMax = max(avVdata{per})+VWbufferSpace;
            %determine BBB 0 ratio/location
            VWzeroRatio = abs(VWplotMin)/(VWplotMax-VWplotMin);
            %determine how much to shift the BBB axis so that the zeros align 
            VWbelowZero = (VWplotMax-VWplotMin)*CaZeroRatio;
            VWaboveZero = (VWplotMax-VWplotMin)-VWbelowZero;  
                        
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
            ax.FontName = 'Arial';
            xlabel('time (s)','FontName','Arial')
            ylabel('Calcium Signal Percent Change','FontName','Arial')
            xLimStart = floor(10*min(FPSstack2));
            xLimEnd = floor(24*min(FPSstack2)); 
            xlim([1 minLen])
            ylim([min(avCdata{per}-CaBufferSpace) max(avCdata{per}+CaBufferSpace)])
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
            ylabel('Vessel Width Percent Change','FontName','Arial')
        %     title('Close Terminals. All mice Averaged.')
            title({'All mice Averaged.';perLabel})
            ylim([-0.02 0.02])
            alpha(0.3)
            set(gca,'YColor',[0 0 0]);  
            ylim([-VWbelowZero VWaboveZero])
            txt = {sprintf('%d animals',realMouseNum),sprintf('%d sessions',mouseNum),sprintf('%d Ca ROIs',CaROIcount),sprintf('%d Ca spikes',spikeCount{per})};
            text(2,-0.02,txt,'FontSize',14)

            fig = figure;
            ax=gca;
            hold all
            plot(avCdata{per},'b','LineWidth',4)
            patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],'b','EdgeColor','none')
            alpha(0.3)
            ax.XTick = FrameVals;
            ax.XTickLabel = sec_TimeVals;   
            ax.FontSize = 25;
            ax.FontName = 'Arial';
            xlabel('time (s)','FontName','Arial')
            ylabel('Calcium Signal Percent Change','FontName','Arial')
            xlim([1 minLen])
            ylim([min(avCdata{per}-CaBufferSpace) max(avCdata{per}+CaBufferSpace)])
            set(fig,'position', [500 100 900 800])
            alpha(0.3)
            %add right y axis tick marks for a specific DOD figure. 
            yyaxis right 
            p(1) = plot(avVdata{per},'k','LineWidth',4);
            patch([x fliplr(x)],[(CI_vLow) (fliplr(CI_vHigh))],'k','EdgeColor','none')
            alpha(0.3)
        %     legend([p(1) p(2)],'Close Terminals','Far Terminals')
            ylabel('Vessel Width Percent Change','FontName','Arial')
        %     title('Close Terminals. All mice Averaged.')
            title({'All mice Averaged.';perLabel})
            ylim([-0.6 1.2])
            alpha(0.3)
            set(gca,'YColor',[0 0 0]);   
            ylim([-VWbelowZero VWaboveZero])
            text(2,-0.02,txt,'FontSize',14)
            
            fig = figure;
            ax=gca;
            hold all
            plot(BScMean,'b','LineWidth',4)
            patch([x fliplr(x)],[CI_cbsLow fliplr(CI_cbsHigh)],'b','EdgeColor','none')
            alpha(0.3)
            ax.XTick = FrameVals;
            ax.XTickLabel = sec_TimeVals;   
            ax.FontSize = 25;
            ax.FontName = 'Arial';
            xlabel('time (s)','FontName','Arial')
            ylabel('Calcium Signal Percent Change','FontName','Arial')
            xlim([1 minLen])
            ylim([min(avCdata{per}-CaBufferSpace) max(avCdata{per}+CaBufferSpace)])
            set(fig,'position', [500 100 900 800])
            alpha(0.3)
            %add right y axis tick marks for a specific DOD figure. 
            yyaxis right 
            p(1) = plot(BSvMean{per},'k','LineWidth',4);
            patch([x fliplr(x)],[(CI_vbsLow) (fliplr(CI_vbsHigh))],'k','EdgeColor','none')
            alpha(0.3)
        %     legend([p(1) p(2)],'Close Terminals','Far Terminals')
            ylabel('Vessel Width Percent Change','FontName','Arial')
        %     title('Close Terminals. All mice Averaged.')
            title({'All mice Averaged.';perLabel})
            ylim([-0.6 1.2])
            alpha(0.3)
            set(gca,'YColor',[0 0 0]);   
            ylim([-VWbelowZero VWaboveZero])
            text(2,-0.02,txt,'FontSize',14)
        end 
    end 
end 

%}
%% (STA stacks) create red and green channel stack averages around calcium peak location (one animal at a time) 
% original code - does % change
% option to high pass filter the video 
% can create shuffled spikes 
%{

greenStacksOrigin = greenStacks;
redStacksOrigin = redStacks;
spikeQ = input("Input 0 to use real calcium spikes. Input 1 to use randomized spikes (based on ISI STD). "); 
% sort red and green channel stacks based on ca peak location 
mouse = 1 ;   
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
if spikeQ == 1   
    spikeISIs = cell(1,length(vidList{mouse})); 
    ISIstds = cell(1,length(vidList{mouse})); 
    randSpikes = cell(1,length(vidList{mouse})); 
    ISImean = cell(1,length(vidList{mouse}));
    randISIs = cell(1,length(vidList{mouse}));
    randSigLocs = cell(1,length(vidList{mouse}));
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
            randSigLocs{vid}{terminals{mouse}(ccell)} = cumsum(randISIs{vid}{terminals{mouse}(ccell)});
        end 
    end                 
    sigLocs = randSigLocs;
end 
clearvars peaks locs 
% crop the imaging data if you want to; better to do this up here to
% maximize computational speed ~ 
rightChan = input('Input 0 if BBB data is in the green chanel. Input 1 if BBB data is in the red channel. ');
cropQ = input("Input 1 if you want to crop the image. Input 0 otherwise. ");
% ask user where to crop image     
if cropQ == 1 
    %select the correct channel to view for cropping 
    if rightChan == 0     
        hold off;
        cropIm = nanmean(greenStacksOrigin{1},3);
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
    if rightChan == 0  
        vesGreenStack = greenStacks;
    elseif rightChan == 1
        vesRedStack = redStacks;
    end 
    clearvars greenSlidingBL redSlidingBL greenStacks redStacks
    greenStacks = hpfGreen;
    redStacks = hpfRed;
elseif highPassQ == 0 
    if rightChan == 0  
        vesGreenStack = greenStacks;
    elseif rightChan == 1
        vesRedStack = redStacks;
    end     
end 
%sort data 
windSize = input('How big should the window be around Ca peak in seconds? '); %24
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
            for peak = 1:length(sigLocs{vid}{terminals{mouse}(ccell)})            
                if sigLocs{vid}{terminals{mouse}(ccell)}(peak)-floor((windSize/2)*FPSstack{mouse}) > 0 && sigLocs{vid}{terminals{mouse}(ccell)}(peak)+floor((windSize/2)*FPSstack{mouse}) < length(cDataFullTrace{mouse}{vid}{terminals{mouse}(ccell)})                
                    start = sigLocs{vid}{terminals{mouse}(ccell)}(peak)-floor((windSize/2)*FPSstack{mouse});
                    stop = sigLocs{vid}{terminals{mouse}(ccell)}(peak)+floor((windSize/2)*FPSstack{mouse});                
                    if start == 0 
                        start = 1 ;
                        stop = start + floor((windSize/2)*FPSstack{mouse}) + floor((windSize/2)*FPSstack{mouse});
                    end                
                    sortedGreenStacks{vid}{terminals{mouse}(ccell)}{peak} = greenStacks{vid}(:,:,start:stop);
                    sortedRedStacks{vid}{terminals{mouse}(ccell)}{peak} = redStacks{vid}(:,:,start:stop);
                    if rightChan == 0     
                        VesSortedGreenStacks{vid}{terminals{mouse}(ccell)}{peak} = vesGreenStack{vid}(:,:,start:stop);
                    elseif rightChan == 1
                        VesSortedRedStacks{vid}{terminals{mouse}(ccell)}{peak} = vesRedStack{vid}(:,:,start:stop);
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
                        sortedGreenStacks{vid}{terminals{mouse}(ccell)}{per}{peak} = greenStacks{vid}(:,:,start:stop);
                        sortedRedStacks{vid}{terminals{mouse}(ccell)}{per}{peak} = redStacks{vid}(:,:,start:stop);
                    end 
                end 
            end 
        end 
    end   
end 
clearvars greenStacks redStacks start stop sigLocs sigPeaks 
% average calcium peak aligned traces across videos 
if tTypeQ == 0 
    greenStackArray2 = cell(1,length(vidList{mouse}));
    avGreenStack2 = cell(1,length(sortedGreenStacks{1}));
    avGreenStack = cell(1,length(sortedGreenStacks{1}));
    if rightChan == 0     
        VesGreenStackArray2 = cell(1,length(vidList{mouse})); 
        VesAvGreenStack2 = cell(1,length(vidList{mouse})); 
        VesAvGreenStack = cell(1,length(vidList{mouse}));
    end      
    for ccell = 1:length(terminals{mouse})
        for vid = 1:length(vidList{mouse})    
            count = 1;
            for peak = 1:size(sortedGreenStacks{vid}{terminals{mouse}(ccell)},2)  
                if isempty(sortedGreenStacks{vid}{terminals{mouse}(ccell)}{peak}) == 0
                    greenStackArray2{vid}{terminals{mouse}(ccell)}(:,:,:,count) = single(sortedGreenStacks{vid}{terminals{mouse}(ccell)}{peak});
                    if rightChan == 0
                        VesGreenStackArray2{vid}{terminals{mouse}(ccell)}(:,:,:,count) = single(VesSortedGreenStacks{vid}{terminals{mouse}(ccell)}{peak});
                    end                       
                    count = count + 1;
                end 
            end
        end 
    end 
    clearvars sortedGreenStacks VesSortedGreenStacks
    for ccell = 1:length(terminals{mouse})
        for vid = 1:length(vidList{mouse})    
            avGreenStack2{terminals{mouse}(ccell)}(:,:,:,vid) = nanmean(greenStackArray2{vid}{terminals{mouse}(ccell)},4);
            if rightChan == 0
                VesAvGreenStack2{terminals{mouse}(ccell)}(:,:,:,vid) = nanmean(VesGreenStackArray2{vid}{terminals{mouse}(ccell)},4);
            end             
        end 
    end 
    clearvars greenStackArray2 VesGreenStackArray2
    for ccell = 1:length(terminals{mouse})
        avGreenStack{terminals{mouse}(ccell)} = nanmean(avGreenStack2{terminals{mouse}(ccell)},4)+100;
        if rightChan == 0
            VesAvGreenStack{terminals{mouse}(ccell)} = nanmean(VesAvGreenStack2{terminals{mouse}(ccell)},4)+100;
        end         
    end 
    clearvars avGreenStack2 VesAvGreenStack2
    redStackArray2 = cell(1,length(vidList{mouse}));
    avRedStack2 = cell(1,length(sortedRedStacks{1}));
    avRedStack = cell(1,length(sortedRedStacks{1}));
    if rightChan == 1     
        VesRedStackArray2 = cell(1,length(vidList{mouse})); 
        VesAvRedStack2 = cell(1,length(vidList{mouse})); 
        VesAvRedStack = cell(1,length(vidList{mouse}));
    end      
    for ccell = 1:length(terminals{mouse})
        for vid = 1:length(vidList{mouse})    
            count = 1;
            for peak = 1:size(sortedRedStacks{vid}{terminals{mouse}(ccell)},2)  
                if isempty(sortedRedStacks{vid}{terminals{mouse}(ccell)}{peak}) == 0
                    redStackArray2{vid}{terminals{mouse}(ccell)}(:,:,:,count) = single(sortedRedStacks{vid}{terminals{mouse}(ccell)}{peak});
                    if rightChan == 1
                        VesRedStackArray2{vid}{terminals{mouse}(ccell)}(:,:,:,count) = single(VesSortedRedStacks{vid}{terminals{mouse}(ccell)}{peak});
                    end                     
                    count = count + 1;
                end 
            end
        end 
    end   
    clearvars sortedRedStacks VesSortedRedStacks
    for ccell = 1:length(terminals{mouse})
        for vid = 1:length(vidList{mouse})    
            avRedStack2{terminals{mouse}(ccell)}(:,:,:,vid) = nanmean(redStackArray2{vid}{terminals{mouse}(ccell)},4); %#ok<*NANMEAN> 
            if rightChan == 1
                VesAvRedStack2{terminals{mouse}(ccell)}(:,:,:,vid) = nanmean(VesRedStackArray2{vid}{terminals{mouse}(ccell)},4);
            end             
        end 
    end       
    clearvars redStackArray2 VesRedStackArray2
    for ccell = 1:length(terminals{mouse})
        avRedStack{terminals{mouse}(ccell)} = nanmean(avRedStack2{terminals{mouse}(ccell)},4)+100;
        if rightChan == 1
            VesAvRedStack{terminals{mouse}(ccell)} = nanmean(VesAvRedStack2{terminals{mouse}(ccell)},4)+100;
        end         
    end       
    clearvars avRedStack2 VesAvRedStack2   
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
        avGreenStack{terminals{mouse}(ccell)} = nanmean(avGreenStack2{terminals{mouse}(ccell)},4)+100;
        avRedStack{terminals{mouse}(ccell)} = nanmean(avRedStack2{terminals{mouse}(ccell)},4)+100;
    end 
    clearvars sortedGreenStacks sortedRedStacks greenStackArray2 redStackArray2 avGreenStack2 avRedStack2
end 
changePt = floor(size(avGreenStack{terminals{mouse}(ccell)},3)/2)-2; 
normTime = input("How many seconds before the calcium peak do you want to baseline to? ");
BLstart = changePt - floor(normTime*FPSstack{mouse});
NgreenStackAv = cell(1,length(avGreenStack));
NredStackAv = cell(1,length(avGreenStack));
if rightChan == 0     
    vesNgreenStackAv = cell(1,length(avGreenStack));
elseif rightChan == 1
    vesNredStackAv = cell(1,length(avGreenStack));
end     
% normalize to baseline period 
for ccell = 1:length(terminals{mouse})
    NgreenStackAv{terminals{mouse}(ccell)} = ((avGreenStack{terminals{mouse}(ccell)}./ (nanmean(avGreenStack{terminals{mouse}(ccell)}(:,:,BLstart:changePt),3)))*100)-100;
    NredStackAv{terminals{mouse}(ccell)} = ((avRedStack{terminals{mouse}(ccell)}./ (nanmean(avRedStack{terminals{mouse}(ccell)}(:,:,BLstart:changePt),3)))*100)-100;
    if rightChan == 0     
        vesNgreenStackAv{terminals{mouse}(ccell)} = ((avGreenStack{terminals{mouse}(ccell)}./ (nanmean(VesAvGreenStack{terminals{mouse}(ccell)}(:,:,BLstart:changePt),3)))*100)-100;
    elseif rightChan == 1
        vesNredStackAv{terminals{mouse}(ccell)} = ((avRedStack{terminals{mouse}(ccell)}./ (nanmean(VesAvRedStack{terminals{mouse}(ccell)}(:,:,BLstart:changePt),3)))*100)-100;
    end      
end 
%select the correct channel for vessel segmentation  
if rightChan == 0     
    vesChan = VesAvGreenStack;
elseif rightChan == 1
    vesChan = VesAvRedStack;
end    
clearvars avGreenStack avRedStack 
%temporal smoothing option
smoothQ = input('Input 0 if you do not want to do temporal smoothing. Input 1 otherwise.');
if smoothQ == 0 
    SNgreenStackAv = NgreenStackAv;
    SNredStackAv = NredStackAv;
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
            for ccell = 1:length(terminals{mouse})
                SNredStackAv{terminals{mouse}(ccell)} = imgaussfilt(redIn{terminals{mouse}(ccell)},sigma);
                SNgreenStackAv{terminals{mouse}(ccell)} = imgaussfilt(greenIn{terminals{mouse}(ccell)},sigma);
            end 
        elseif spatSmoothTypeQ == 1 % if you want to use convolution smoothing 
            % create your kernal for smoothing by convolution  
            kernalSize = input('What size NxN array do you want to use for convolution spatial filtering? ');
            K = 0.125*ones(kernalSize);
            for ccell = 1:length(terminals{mouse})
                SNredStackAv{terminals{mouse}(ccell)} = convn(redIn{terminals{mouse}(ccell)},K,'same');
                SNgreenStackAv{terminals{mouse}(ccell)} = convn(greenIn{terminals{mouse}(ccell)},K,'same');
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
                end 
            elseif spatSmoothChanQ == 1 % if you want to spatially smooth the red channel 
                redIn = SNredStackAv; 
                clearvars SNredStackAv 
                for ccell = 1:length(terminals{mouse})
                    SNredStackAv{terminals{mouse}(ccell)} = imgaussfilt(redIn{terminals{mouse}(ccell)},sigma);
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
                end 
            elseif spatSmoothChanQ == 1 % if you want to spatially smooth the red channel 
                redIn = SNredStackAv; 
                clearvars SNredStackAv 
                for ccell = 1:length(terminals{mouse})
                    SNredStackAv{terminals{mouse}(ccell)} = convn(redIn{terminals{mouse}(ccell)},K,'same');
                end 
            end                          
        end 
    end 
end 
clearvars redIn greenIn 
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
    ind = length(combo);
    ThreeDCaMask = logical(repmat(combo{ind},1,1,size(SNredStackAv{terminals{mouse}(ccell)},3)));
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
if AVQ == 0 
    % create outline of vessel to overlay the %change BBB perm stack 
    segmentVessel = 1;
    segQ = input('Input 1 if you need to create a new vessel segmentation algorithm. Input 0 otherwise. ');
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
                    [BW,~] = segmentImage57_STAvid_20230222(vesChan{terminals{mouse}(ccell)}(:,:,frame));
                    BWstacks{terminals{mouse}(ccell)}(:,:,frame) = BW; 
                    %get the segmentation boundaries 
                    BW_perim{terminals{mouse}(ccell)}(:,:,frame) = bwperim(BW);
                    %overlay segmentation boundaries on data
                    segOverlays{terminals{mouse}(ccell)}(:,:,:,frame) = imoverlay(mat2gray(vesChan{terminals{mouse}(ccell)}(:,:,frame)), BW_perim{terminals{mouse}(ccell)}(:,:,frame), [.3 1 .3]);   
                end   
            end 
            continu = 0;
        end 
        %play segmentation boundaries over images 
        if segQ == 1 
            implay(segOverlays{CaROI})
        end 
        %ask about segmentation quality 
        if segQ == 1               
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
    greenColorMap = linspace(0, 1, 256);
    % green colorbar with less green
%     greenColorMap = [zeros(1, 60), linspace(0, 1, 196)];
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



%% conditional statement that ensures you checked the other channel

% to make sure Ca ROIs show an average peak in the same frame, before
% moving onto the next step 
CaFrameQ = input('Input 1 if you if you checked to make sure averaged Ca events happened in the same frame per ROI. And the anatomy is correct. ');
vesBlackQ = input('Input 1 to black out vessel. '); 
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
                    RightChan{terminals{mouse}(ccell)}(BWstacks{terminals{mouse}(ccell)}) = 0;
                end 
                %find the upper and lower bounds of your data (per calcium ROI) 
                maxValue = max(max(max(max(RightChan{terminals{mouse}(ccell)}))));
                minValue = min(min(min(min(RightChan{terminals{mouse}(ccell)}))));
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
                                    [~,xmins,ymins,widths,heights] = firstTimeCreateROIs(1,RightChan{terminals{mouse}(ccell)}(:,:,frame));
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
                            [ROI_stacks] = make_ROIs_notfirst_time(RightChan{terminals{mouse}(ccell)}(:,:,frame),xmins,ymins,widths,heights);
                            ROIstacks{terminals{mouse}(ccell)}{BBBroi}(:,:,frame) = ROI_stacks{1};
                        end 
                    end 
                    % create the % change image with the right white and black point
                    % boundaries and colormap 
                    if cMapQ == 0
                        imagesc(RightChan{terminals{mouse}(ccell)}(:,:,frame),[-maxAbVal,maxAbVal]); colormap(cMap); colorbar%this makes the max point 1% and the min point -1% 
                    elseif cMapQ == 1 
                        imagesc(RightChan{terminals{mouse}(ccell)}(:,:,frame),[0,maxAbVal/3]); colormap(cMap); colorbar%this makes the max point 1% and the min point -1% 
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
                        colLen = size(RightChan{terminals{mouse}(ccell)},2);
                        rowLen = size(RightChan{terminals{mouse}(ccell)},1);
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
                    if spikeQ == 0 
                        filename = sprintf('%s/CaROI_%d_BBBsignal/CaROI_%d_frame%d',dir2,terminals{mouse}(ccell),terminals{mouse}(ccell),frame);
                    elseif spikeQ == 1
                        filename = sprintf('%s/CaROI_%d_BBBsignal/CaROI_%d_frame%d_randGenSpikes',dir2,terminals{mouse}(ccell),terminals{mouse}(ccell),frame);
                    end                    
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
        
        clearvars BW BWstacks BW_perim segOverlays
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
%% (STA stacks) create red and green channel stack averages around calcium peak location (one animal at a time) 
% z scores the entire stack before sorting into windows for averaging 
% option to high pass filter the video 
% can create shuffled and bootrapped x100 spikes 
% (must save out non-shuffled STA vids before making
% shuffled and bootstrapped STA vids to create binary vids for DBscan)
%{
greenStacksOrigin = greenStacks;
redStacksOrigin = redStacks;
spikeQ = input("Input 0 to use real calcium spikes. Input 1 to use randomized and bootstrapped spikes (based on ISI STD). "); 
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
                        sigPeaks{vid}{terminals{mouse}(ccell)}(count) = gpuArray(peaks(loc));
                        sigLocs{vid}{terminals{mouse}(ccell)}(count) = gpuArray(locs(loc));
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
    for it = 1:100
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
    %         clearvars sortedGreenStacks VesSortedGreenStacks
            clearvars VesSortedGreenStacks
            redStackArray2 = cell(1,max(terminals{mouse}));
            if rightChan == 1     
                VesRedStackArray2 = cell(1,max(terminals{mouse}));
            end  
            for ccell = 1:length(terminals{mouse})
                count = 1;
                for vid = 1:length(vidList{mouse})        
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
                        SEM = (nanstd(avGreenStack{terminals{mouse}(ccell)},0,3))/(sqrt(size(avGreenStack{terminals{mouse}(ccell)},3))); % Standard Error 
%                         ts_High = tinv(0.975,size(avGreenStack{terminals{mouse}(ccell)},3)-1);% T-Score for 95% CI
%                         ts_Low =  tinv(0.025,size(avGreenStack{terminals{mouse}(ccell)},3)-1);% T-Score for 95% CI
                        ts_High = tinv(0.995,size(avGreenStack{terminals{mouse}(ccell)},3)-1);% T-Score for 99% CI
                        ts_Low =  tinv(0.005,size(avGreenStack{terminals{mouse}(ccell)},3)-1);% T-Score for 99% CI
                        if HighLowQ == 0
                            CI_Low{terminals{mouse}(ccell)}(:,:,:,it) = (avGreenStack{terminals{mouse}(ccell)}) + (ts_Low*SEM); 
                        elseif HighLowQ == 1 
                            CI_High{terminals{mouse}(ccell)}(:,:,:,it) = (avGreenStack{terminals{mouse}(ccell)}) + (ts_High*SEM);  % Confidence Intervals  
                        end 
                    elseif rightChan == 1 % BBB data is in red channel 
                        SEM = (nanstd(avRedStack{terminals{mouse}(ccell)},0,3))/(sqrt(size(avRedStack{terminals{mouse}(ccell)},3))); % Standard Error 
%                         ts_High = tinv(0.975,size(avRedStack{terminals{mouse}(ccell)},3)-1);% T-Score for 95% CI
%                         ts_Low =  tinv(0.025,size(avRedStack{terminals{mouse}(ccell)},3)-1);% T-Score for 95% CI
                        ts_High = tinv(0.995,size(avRedStack{terminals{mouse}(ccell)},3)-1);% T-Score for 99% CI
                        ts_Low =  tinv(0.005,size(avRedStack{terminals{mouse}(ccell)},3)-1);% T-Score for 99% CI
                        if HighLowQ == 0
                            CI_Low{terminals{mouse}(ccell)}(:,:,:,it) = (avRedStack{terminals{mouse}(ccell)}) + (ts_Low*SEM);   
                        elseif HighLowQ == 1 
                            CI_High{terminals{mouse}(ccell)}(:,:,:,it) = (avRedStack{terminals{mouse}(ccell)}) + (ts_High*SEM);  % Confidence Intervals  
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
    ind = length(combo);
    ThreeDCaMask = logical(repmat(combo{ind},1,1,size(SNredStackAv{terminals{mouse}(ccell)},3)));
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
                    [BW,~] = segmentImage57_STAvid_20230214zScored(vesChan{terminals{mouse}(ccell)}(:,:,frame));
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
%% saves out STA stack compatible optical flow 
%{
CaEventFrame = input('What frame did the Ca events happen in? ');
mouse = 1;
vectorMask = cell(1,length(BWstacks));
opflow = cell(length(terminals{mouse}),size(BWstacks{terminals{mouse}(1)},3)-1);
I = cell(1,length(BWstacks));
I2 = cell(1,length(BWstacks));
for ccell = 1:length(terminals{mouse})
    I{terminals{mouse}(ccell)} = RightChan{terminals{mouse}(ccell)};
    I2{terminals{mouse}(ccell)} = RightChan{terminals{mouse}(ccell)}; 
    for frame = 1:size(BWstacks{terminals{mouse}(ccell)},3)
        % to only get optical flow vessels near vessel, make vessel outline mask
        % larger 
        radius = 4;
        decomposition = 0;
        se = strel('disk', radius, decomposition);               
        vectorMask{terminals{mouse}(ccell)}(:,:,frame) = imdilate(BWstacks{terminals{mouse}(ccell)}(:,:,frame),se);               
    end 
    % apply mask to orignal image to only get vectors of interest 
    I{terminals{mouse}(ccell)}(~vectorMask{terminals{mouse}(ccell)}) = 0;
end         
for ccell = 1:length(terminals{mouse})
    % get the x-y coordinates of the Ca ROI         
    clearvars CAy CAx
    if ismember("ROIorders", variableInfo) == 1 % returns true
        [CAyf, CAxf] = find(ROIorders{1} == terminals{mouse}(ccell));  % x and y are column vectors.
    elseif ismember("ROIorders", variableInfo) == 0 % returns true
        [CAyf, CAxf] = find(CaROImasks{1} == terminals{mouse}(ccell));  % x and y are column vectors.
    end        
    %create a new folder per calcium ROI
    newFolder = sprintf('CaROI_%d_BBBsignal',terminals{mouse}(ccell));
    mkdir(dir2,newFolder)
    %find the upper and lower bounds of your data (per calcium ROI and filter ) 
    maxValue = max(max(max(max(I{terminals{mouse}(ccell)}))));
    minValue = min(min(min(min(I{terminals{mouse}(ccell)}))));
    minMaxAbsVals = [abs(minValue),abs(maxValue)];
    maxAbVal = max(minMaxAbsVals);           
    for frame = 1:size(BWstacks{terminals{mouse}(ccell)},3)-1  
        % determine optical flow  
        im1 = I{terminals{mouse}(ccell)}(:,:,frame);
        im2 = I{terminals{mouse}(ccell)}(:,:,frame+1);
        opflow{ccell,frame} = opticalFlow(im1,im2);
        % plotting code 
        h = figure('Visible','off');  
        movegui(h);
        hViewPanel = uipanel(h,'Position',[0 0 1 1],'Title','Plot of Optical Flow Vectors');
        hPlot = axes(hViewPanel);
        % create the % change image with the right white and black point
        % boundaries and colormap 
        if cMapQ == 0
            imagesc(I2{terminals{mouse}(ccell)}(:,:,frame),[-maxAbVal,maxAbVal]); colormap(cMap); colorbar%this makes the max point 1% and the min point -1% 
        elseif cMapQ == 1 
            imagesc(I2{terminals{mouse}(ccell)}(:,:,frame),[0,maxAbVal/3]); colormap(cMap); colorbar%this makes the max point 1% and the min point -1% 
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
        % plot where the axon is located in gray 
        scatter(CAxf,CAyf,axonPixSize,[0.5 0.5 0.5],'filled','square');
        % plot the GCaMP signal marker in the right frame 
        if frame == CaEventFrame || frame == (CaEventFrame-1) || frame == (CaEventFrame+1)
            hold on;
            scatter(CAxf,CAyf,axonPixSize,[0 0 1],'filled','square');
            %get border coordinates 
            colLen = size(I{terminals{mouse}(ccell)},2);
            rowLen = size(I{terminals{mouse}(ccell)},1);
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
        hold on
        if frame > 1 
            plot(opflow{ccell,frame-1},'DecimationFactor',[4 4],'ScaleFactor',3,'Parent',hPlot);
        end 
        hold off  
        ax.Visible = 'off';
        ax.FontSize = 20;
        %save current figure to file 
        filename = sprintf('%s/CaROI_%d_BBBsignal/CaROI_%d_frame%d',dir2,terminals{mouse}(ccell),terminals{mouse}(ccell),frame);
        saveas(gca,[filename '.png'])        
    end 
end 
%}
%% saves out STA stack compatible optical flow with PCA filtering 
%{
CaEventFrame = input('What frame did the Ca events happen in? ');
vectorMask = cell(1,length(BWstacks));
opflow = cell(length(terminals{mouse}),size(BWstacks{terminals{mouse}(1)},3)-1);
I2 = cell(1,length(BWstacks));
for mouse = 1:mouseNum
    figfilter = cell(1,length(BWstacks));
    for ccell = 1:length(terminals{mouse})         
        % do the pca and filter the data using PCA filters 
        I = RightChan{terminals{mouse}(ccell)}; % 
%         I = SNvesChan{terminals{mouse}(ccell)}; % I tried to
%         look at the non-z scored, but smoothed raw data and that wasn't
%         easy to see anyways. best bet is the z-scored data alone 
        % reshape data so that each row = observations = frames and col =
        % components = pixels 
        X = reshape(I,size(I,1)*size(I,2),size(I,3));
        % do the pca 
        [coeff, score, latent, tsquared, explained,~] = pca(X,'Economy',false);                         
        % Multiply the original data by the principal component vectors to get the
        % projections of the original data on the principal component vector space.
        Itransformed = X*coeff;
        Ipc = reshape(Itransformed,size(I,1),size(I,2),size(I,3));        
        for filt = 1:5
            fig = Ipc(:,:,filt);
            % normalize
            figMax = max(max(Ipc(:,:,filt)));
            norm = fig./figMax;
            % multiply I by fig1 filter 
            figMask = repmat(norm,1,1,size(I,3));
            figfilter{terminals{mouse}(ccell)}{filt} = figMask.*I; 
        
            I2{terminals{mouse}(ccell)}{filt} = figfilter{terminals{mouse}(ccell)}{filt};
            for frame = 1:size(I2{terminals{mouse}(ccell)}{filt},3)
                % to only get optical flow vessels near vessel, make vessel outline mask
                % larger 
                radius = 4;
                decomposition = 0;
                se = strel('disk', radius, decomposition);               
                vectorMask{terminals{mouse}(ccell)}(:,:,frame) = imdilate(BWstacks{terminals{mouse}(ccell)}(:,:,frame),se);               
            end 
            % apply mask to orignal image to only get vectors of interest 
            I2{terminals{mouse}(ccell)}{filt}(~vectorMask{terminals{mouse}(ccell)}) = 0;
        end                
    end 
end 
for mouse = 1:mouseNum
    for ccell = 1:length(terminals{mouse})  
        % get the x-y coordinates of the Ca ROI         
        clearvars CAy CAx
        if ismember("ROIorders", variableInfo) == 1 % returns true
            [CAyf, CAxf] = find(ROIorders{1} == terminals{mouse}(ccell));  % x and y are column vectors.
        elseif ismember("ROIorders", variableInfo) == 0 % returns true
            [CAyf, CAxf] = find(CaROImasks{1} == terminals{mouse}(ccell));  % x and y are column vectors.
        end  
        for filt = 1:5
            %create a new folder per calcium ROI and filter 
            newFolder = sprintf('CaROI_%d_BBBsignal',terminals{mouse}(ccell));
            mkdir(dir2,newFolder)
            dir3 = append(dir2,'/',newFolder);
            newFolder2 = sprintf('PCAfilter_%d',filt);
            mkdir(dir3,newFolder2)
            %find the upper and lower bounds of your data (per calcium ROI and filter ) 
            maxValue = max(max(max(max(figfilter{terminals{mouse}(ccell)}{filt}))));
            minValue = min(min(min(min(figfilter{terminals{mouse}(ccell)}{filt}))));
            minMaxAbsVals = [abs(minValue),abs(maxValue)];
            maxAbVal = max(minMaxAbsVals);
            for frame = 1:size(figfilter{terminals{mouse}(ccell)}{filt},3)
                % determine optical flow  
                if frame < size(figfilter{terminals{mouse}(ccell)}{filt},3)
                    im1 = I2{terminals{mouse}(ccell)}{filt}(:,:,frame);
                    im2 = I2{terminals{mouse}(ccell)}{filt}(:,:,frame+1);
                    opflow{ccell,frame} = opticalFlow(im1,im2);    
                end 
                % plotting code                 
                h = figure('Visible','off');    
                movegui(h);
                hViewPanel = uipanel(h,'Position',[0 0 1 1],'Title','Plot of Optical Flow Vectors');
                hPlot = axes(hViewPanel);
                % create the % change image with the right white and black point
                % boundaries and colormap 
                if cMapQ == 0
                    imagesc(figfilter{terminals{mouse}(ccell)}{filt}(:,:,frame),[-maxAbVal,maxAbVal]); colormap(cMap); colorbar%this makes the max point 1% and the min point -1% 
                elseif cMapQ == 1 
                    imagesc(figfilter{terminals{mouse}(ccell)}{filt}(:,:,frame),[0,maxAbVal/3]); colormap(cMap); colorbar%this makes the max point 1% and the min point -1% 
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
                % plot where the axon is located in gray 
                scatter(CAxf,CAyf,axonPixSize,[0.5 0.5 0.5],'filled','square');
                % plot the GCaMP signal marker in the right frame 
                if frame == CaEventFrame || frame == (CaEventFrame-1) || frame == (CaEventFrame+1)
                    hold on;
                    scatter(CAxf,CAyf,axonPixSize,[0 0 1],'filled','square');
                    %get border coordinates 
                    colLen = size(RightChan{terminals{mouse}(ccell)},2);
                    rowLen = size(RightChan{terminals{mouse}(ccell)},1);
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
                hold on
                if frame > 1 
                    plot(opflow{ccell,frame-1},'DecimationFactor',[4 4],'ScaleFactor',3,'Parent',hPlot);
                end                                
                ax.Visible = 'off';
                ax.FontSize = 20;
                %save current figure to file 
                filename = sprintf('%s/CaROI_%d_BBBsignal/PCAfilter_%d/CaROI_%d_PCAfilter_%d_frame%d',dir2,terminals{mouse}(ccell),filt,terminals{mouse}(ccell),filt,frame);
                saveas(gca,[filename '.png'])
            end             
        end                           
    end 
end         

%}
%% creates STA stack compatiple (not-PCA filtered) STA plots for 
% green and red pixel amp 
% vector amplitude 
%{
Vid = RightChan; 
regImDir = uigetdir('*.*',sprintf('WHERE IS THE STA DATA FOR MOUSE #%d?',mouse));
cd(regImDir);
MatFileName = uigetfile('*.*',sprintf('SELECT THE STA DATA FOR MOUSE #%d',mouse));
Mat = matfile(MatFileName);                  
sortedCdata{mouse} = Mat.sortedCdata;               
%% green and red pixel amp         
baselineTime = normTime;  
allCTraces3 = cell(1,mouseNum);
sortedCdata2 = cell(1,mouseNum);
SNCdataPeaks = cell(1,mouseNum);
SCdataPeaks = cell(1,mouseNum);
CTraces = cell(1,mouseNum);
CTraceArray = cell(1,mouseNum);
CI_cLow = cell(1,mouseNum);
CI_cHigh = cell(1,mouseNum);
AVSNCdataPeaks = cell(1,mouseNum);
greenSum = zeros(length(terminals{mouse}),53);
redSum = zeros(length(terminals{mouse}),53);
vectorMask = cell(1,mouseNum);
mouse = 1;
vidQ = input('Input 0 to look at red and green sums of entire vid. Input 1 to look just near vessel. ');
vidQ2 = input('Input 1 to black out pixels inside of the vessel. ');
if vidQ2 == 1     
    vidQ3 = input('Input 1 to black out out pixels that are far from the axon. ');
end 
% plots figure per calcium ROI 
for ccell = 1:length(terminals{mouse}) 
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
    CTraces{mouse} = allCTraces{mouse}(CaROIs{mouse}(ccell));                                      
    %remove empty cells if there are any b = a(any(a,2),:)
    CTraces{mouse} = CTraces{mouse}(~cellfun('isempty',CTraces{mouse}));                               
    % create colors for plotting 
    Bcolors = [1,0,0;1,0.5,0;1,1,0];
    Ccolors = [0,0,1;0,0.5,1;0,1,1];
    % resort data: concatenate all CaROI data 
    % output = CaArray{mouse}{per}(concatenated caRoi data)
    % output = VW/BBBarray{mouse}{BBB/VWroi}{per}(concatenated caRoi data)  
    for per = 1:length(allCTraces3{mouse}{CaROIs{mouse}(1)})
        if isempty(allCTraces3{mouse}{CaROIs{mouse}(1)}{per}) == 0                                                                                               
            if isempty(CTraces{mouse}{per}) == 0 
                if ccell == 1 
                    CTraceArray{mouse}{per} = CTraces{mouse}{per}{1};                              
                elseif ccell > 1 
                    CTraceArray{mouse}{per} = vertcat(CTraceArray{mouse}{per},CTraces{mouse}{per}{1});                             
                end
            end 
            %DETERMINE 95% CI                       
            SEMc = (nanstd(CTraces{mouse}{per}{1}))/(sqrt(size(CTraces{mouse}{per}{1},1))); % Standard Error            
            ts_cLow = tinv(0.025,size(CTraces{mouse}{per}{1},1)-1);% T-Score for 95% CI
            ts_cHigh = tinv(0.975,size(CTraces{mouse}{per}{1},1)-1);% T-Score for 95% CI
            CI_cLow{mouse}{per} = (nanmean(CTraces{mouse}{per}{1},1)) + (ts_cLow*SEMc);  % Confidence Intervals
            CI_cHigh{mouse}{per} = (nanmean(CTraces{mouse}{per}{1},1)) + (ts_cHigh*SEMc);  % Confidence Intervals 
            x = 1:53;
            %get averages
            AVSNCdataPeaks{mouse}{per} = nanmean(CTraces{mouse}{per}{1},1);  
            % plot data      
            %determine range of data Ca data
            CaDataRange = max(AVSNCdataPeaks{mouse}{per})-min(AVSNCdataPeaks{mouse}{per});
            %determine plotting buffer space for Ca data 
            CaBufferSpace = CaDataRange;
            %determine first set of plotting min and max values for Ca data
            CaPlotMin = min(AVSNCdataPeaks{mouse}{per})-CaBufferSpace;
            CaPlotMax = max(AVSNCdataPeaks{mouse}{per})+CaBufferSpace; 
            %determine Ca 0 ratio/location 
            CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);            
            for frame = 1:size(Vid{terminals{mouse}(ccell)},3)
                % to only get optical flow vessels near vessel, make vessel outline mask
                % larger 
                radius = 4;
                decomposition = 0;
                se = strel('disk', radius, decomposition);               
                vectorMask{mouse}{terminals{mouse}(ccell)}(:,:,frame) = imdilate(BWstacks{terminals{mouse}(ccell)}(:,:,frame),se);               
            end 
            % apply mask to orignal image to only get vectors of interest 
            Vid2 = Vid;
            Vid2{terminals{mouse}(ccell)}(~vectorMask{mouse}{terminals{mouse}(ccell)}) = 0;    
            if vidQ == 0 
                sumVid = Vid;
            elseif vidQ == 1 
                sumVid = Vid2;
            end 
            %black out pixels inside of vessel  
            if vidQ2 == 1 
                sumVid{terminals{mouse}(ccell)}(BWstacks{terminals{mouse}(ccell)}) = 0;
                % black out pixels that are far from the axon 
                if vidQ3 == 1                    
                    if ismember("ROIorders", variableInfo) == 1 
                        caLoc = ROIorders{1};
                    elseif ismember("ROIorders", variableInfo) == 0 
                        caLoc = CaROImasks{1};
                    end
                    caLoc(caLoc ~= terminals{mouse}(ccell)) = 0;
                    caLoc(caLoc == terminals{mouse}(ccell)) = 1;
                    caLoc = logical(caLoc);
                    % make vessel outline mask
                    radius = 6;
                    decomposition = 0;
                    se = strel('disk', radius, decomposition);               
                    caLocMask = imdilate(caLoc,se);       
                    caLocMasks = repmat(caLocMask,1,1,size(Vid{terminals{mouse}(ccell)},3));
                    % black out pixels that are far from vessel 
                    sumVid{terminals{mouse}(ccell)}(~caLocMasks) = 0;
                end 
            end 
            % get green and red amp data 
            for frame = 1:size(sumVid{terminals{mouse}(ccell)},3)      
                curFrame = sumVid{terminals{mouse}(ccell)}(:,:,frame);
                greenSum(ccell,frame) = sum(curFrame(curFrame>0));
                redSum(ccell,frame) = abs(sum(curFrame(curFrame<0)));
            end       
            % determine range of color amp data  
            greenMax = max(greenSum(ccell,:)); redMax = max(redSum(ccell,:)); 
            maxVals = [greenMax,redMax]; maxVal = max(maxVals);
            greenMin = min(greenSum(ccell,:)); redMin = min(redSum(ccell,:)); 
            minVals = [greenMin,redMin]; minVal = min(minVals);
            colorRange = maxVal - minVal;                        
            % determine plotting buffer space for color data 
            colorBufferSpace = colorRange;            
            % determine first set of plotting min and max values for color data
            colorPlotMin = minVal - colorBufferSpace;
            colorPlotMax = maxVal + colorBufferSpace;             
            % determine color 0 ratio/location
            colorZeroRatio = abs(colorPlotMin)/(colorPlotMax-colorPlotMin);            
            % determine how much to shift the color axis so that the zeros align 
            colorBelowZero = (colorPlotMax-colorPlotMin)*CaZeroRatio;
            colorAboveZero = (colorPlotMax-colorPlotMin)-colorBelowZero;                  
            % plot 
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
            % add right y axis tick marks for a specific DOD figure. 
            yyaxis right 
            p(1) = plot(greenSum(ccell,:),'green','LineWidth',4);
            p(1) = plot(redSum(ccell,:),'red','LineWidth',4,'LineStyle','-');
%                             patch([x fliplr(x)],[(close_CI_bLow{mouse}{BBBroi}{per}) (fliplr(close_CI_bHigh{mouse}{BBBroi}{per}))],Bcolors(1,:),'EdgeColor','none')
            if vidQ == 0 
                ylabel('Red and Green Amplitude Whole Vid','FontName','Times')
            elseif vidQ == 1 
                ylabel('Red and Green Amplitude Near Vessel','FontName','Times')
            end 
            title(sprintf('Axon %d',terminals{mouse}(ccell)))
            alpha(0.3)
%                             legend([p(1) p(2)],'Close Terminals','Far Terminals')
            set(gca,'YColor',[0 0 0]);   
            ylim([-colorBelowZero colorAboveZero])   
            xlim([1 53])
            % save the plots out 
            if vidQ == 0
                label = sprintf('%s/Axon%d_wholeVid_redGreenAmp.tif',dir2,terminals{mouse}(ccell));
            elseif vidQ == 1 
                label = sprintf('%s/Axon%d_nearVessel_redGreenAmp.tif',dir2,terminals{mouse}(ccell));
            end 
            export_fig(label)                        
        end 
    end       
end 
% plots av figure of all calcium ROI 
mouse = 1; 
per = 1; 
%DETERMINE 95% CI                       
SEMc = (nanstd(CTraceArray{mouse}{per}))/(sqrt(size(CTraceArray{mouse}{per},1))); % Standard Error            
ts_cLow = tinv(0.025,size(CTraceArray{mouse}{per},1)-1);% T-Score for 95% CI
ts_cHigh = tinv(0.975,size(CTraceArray{mouse}{per},1)-1);% T-Score for 95% CI
CI_cLow{mouse}{per} = (nanmean(CTraceArray{mouse}{per},1)) + (ts_cLow*SEMc);  % Confidence Intervals
CI_cHigh{mouse}{per} = (nanmean(CTraceArray{mouse}{per},1)) + (ts_cHigh*SEMc);  % Confidence Intervals 
x = 1:53;
%get averages
AVSNCdataPeaks{mouse}{per} = nanmean(CTraceArray{mouse}{per},1);  
%DETERMINE 95% of green and red amps and average (across axons)                      
SEMg = (nanstd(greenSum))/(sqrt(size(greenSum,1))); % Standard Error                 
ts_gLow = tinv(0.025,size(greenSum,1)-1);% T-Score for 95% CI           
ts_gHigh = tinv(0.975,size(greenSum,1)-1);% T-Score for 95% CI           
CI_gLow = (nanmean(greenSum,1)) + (ts_gLow*SEMg);  % Confidence Intervals
CI_gHigh = (nanmean(greenSum,1)) + (ts_gHigh*SEMg);  % Confidence Intervals 
%get average
AVSNGdataPeaks = nanmean(greenSum,1);  
SEMr = (nanstd(redSum))/(sqrt(size(redSum,1))); % Standard Error                 
ts_rLow = tinv(0.025,size(redSum,1)-1);% T-Score for 95% CI           
ts_rHigh = tinv(0.975,size(redSum,1)-1);% T-Score for 95% CI           
CI_rLow = (nanmean(redSum,1)) + (ts_rLow*SEMr);  % Confidence Intervals
CI_rHigh = (nanmean(redSum,1)) + (ts_rHigh*SEMr);  % Confidence Intervals 
%get average
AVSNRdataPeaks = nanmean(redSum,1);  

% plot 
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
% add right y axis tick marks for a specific DOD figure. 
yyaxis right 
p(1) = plot(AVSNGdataPeaks,'green','LineWidth',4);
patch([x fliplr(x)],[CI_gLow fliplr(CI_gHigh)],'green','EdgeColor','none')
p(1) = plot(AVSNRdataPeaks,'red','LineWidth',4,'LineStyle','-');
patch([x fliplr(x)],[CI_rLow fliplr(CI_rHigh)],'red','EdgeColor','none')
%                             patch([x fliplr(x)],[(close_CI_bLow{mouse}{BBBroi}{per}) (fliplr(close_CI_bHigh{mouse}{BBBroi}{per}))],Bcolors(1,:),'EdgeColor','none')
if vidQ == 0 
    ylabel('Red and Green Amplitude Whole Vid','FontName','Times')
elseif vidQ == 1 
    ylabel('Red and Green Amplitude Near Vessel','FontName','Times')
end 
title(sprintf('Axons Averaged'))
alpha(0.3)
%                             legend([p(1) p(2)],'Close Terminals','Far Terminals')
set(gca,'YColor',[0 0 0]);   
ylim([-colorBelowZero colorAboveZero])   
xlim([1 53])
% save the plots out 
if vidQ == 0
    label = sprintf('%s/AxonAverage_wholeVid_redGreenAmp.tif',dir2);
elseif vidQ == 1 
    label = sprintf('%s/AxonAverage_nearVessel_redGreenAmp.tif',dir2);
end 
export_fig(label)     

%% vector amplitude         
baselineTime = normTime;  
allCTraces3 = cell(1,mouseNum);
sortedCdata2 = cell(1,mouseNum);
SNCdataPeaks = cell(1,mouseNum);
SCdataPeaks = cell(1,mouseNum);
CTraces = cell(1,mouseNum);
CTraceArray = cell(1,mouseNum);
CI_cLow = cell(1,mouseNum);
CI_cHigh = cell(1,mouseNum);
AVSNCdataPeaks = cell(1,mouseNum);
greenSum = zeros(length(terminals{mouse}),size(BWstacks{terminals{mouse}(1)},3));
redSum = zeros(length(terminals{mouse}),size(BWstacks{terminals{mouse}(1)},3));
vectorMask = cell(1,mouseNum);
opflow = cell(length(terminals{mouse}),size(BWstacks{terminals{mouse}(1)},3)-1);
sumVel = zeros(length(terminals{mouse}),size(BWstacks{terminals{mouse}(1)},3));
mouse = 1;
vidQ = input('Input 0 to look at red and green sums of entire vid. Input 1 to look just near vessel. ');
vidQ2 = input('Input 1 to black out pixels inside of the vessel. ');
if vidQ2 == 1     
    vidQ3 = input('Input 1 to black out out pixels that are far from the axon. ');
end 
% plots figure per calcium ROI 
for ccell = 1:length(terminals{mouse}) 
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
    CTraces{mouse} = allCTraces{mouse}(CaROIs{mouse}(ccell));                                      
    %remove empty cells if there are any b = a(any(a,2),:)
    CTraces{mouse} = CTraces{mouse}(~cellfun('isempty',CTraces{mouse}));                               
    % create colors for plotting 
    Bcolors = [1,0,0;1,0.5,0;1,1,0];
    Ccolors = [0,0,1;0,0.5,1;0,1,1];
    % resort data: concatenate all CaROI data 
    % output = CaArray{mouse}{per}(concatenated caRoi data)
    % output = VW/BBBarray{mouse}{BBB/VWroi}{per}(concatenated caRoi data)  
    for per = 1:length(allCTraces3{mouse}{CaROIs{mouse}(1)})
        if isempty(allCTraces3{mouse}{CaROIs{mouse}(1)}{per}) == 0                                                                                               
            if isempty(CTraces{mouse}{per}) == 0 
                if ccell == 1 
                    CTraceArray{mouse}{per} = CTraces{mouse}{per}{1};                              
                elseif ccell > 1 
                    CTraceArray{mouse}{per} = vertcat(CTraceArray{mouse}{per},CTraces{mouse}{per}{1});                             
                end
            end 
            %DETERMINE 95% CI                       
            SEMc = (nanstd(CTraces{mouse}{per}{1}))/(sqrt(size(CTraces{mouse}{per}{1},1))); % Standard Error            
            ts_cLow = tinv(0.025,size(CTraces{mouse}{per}{1},1)-1);% T-Score for 95% CI
            ts_cHigh = tinv(0.975,size(CTraces{mouse}{per}{1},1)-1);% T-Score for 95% CI
            CI_cLow{mouse}{per} = (nanmean(CTraces{mouse}{per}{1},1)) + (ts_cLow*SEMc);  % Confidence Intervals
            CI_cHigh{mouse}{per} = (nanmean(CTraces{mouse}{per}{1},1)) + (ts_cHigh*SEMc);  % Confidence Intervals 
            x = 1:53;
            %get averages
            AVSNCdataPeaks{mouse}{per} = nanmean(CTraces{mouse}{per}{1},1);  
            % plot data      
            %determine range of data Ca data
            CaDataRange = max(AVSNCdataPeaks{mouse}{per})-min(AVSNCdataPeaks{mouse}{per});
            %determine plotting buffer space for Ca data 
            CaBufferSpace = CaDataRange;
            %determine first set of plotting min and max values for Ca data
            CaPlotMin = min(AVSNCdataPeaks{mouse}{per})-CaBufferSpace;
            CaPlotMax = max(AVSNCdataPeaks{mouse}{per})+CaBufferSpace; 
            %determine Ca 0 ratio/location 
            CaZeroRatio = abs(CaPlotMin)/(CaPlotMax-CaPlotMin);            
            for frame = 1:size(I2{terminals{mouse}(ccell)},3)
                % to only get optical flow vessels near vessel, make vessel outline mask
                % larger 
                radius = 4;
                decomposition = 0;
                se = strel('disk', radius, decomposition);               
                vectorMask{mouse}{terminals{mouse}(ccell)}(:,:,frame) = imdilate(BWstacks{terminals{mouse}(ccell)}(:,:,frame),se);               
            end 
            % apply mask to orignal image to only get vectors of interest 
            Vid2 = Vid;
            Vid2{terminals{mouse}(ccell)}(~vectorMask{mouse}{terminals{mouse}(ccell)}) = 0;    
            if vidQ == 0 
                sumVid = Vid;
            elseif vidQ == 1 
                sumVid = Vid2;
            end 
            %black out pixels inside of vessel  
            if vidQ2 == 1 
                sumVid{terminals{mouse}(ccell)}(BWstacks{terminals{mouse}(ccell)}) = 0;
                % black out pixels that are far from the axon 
                if vidQ3 == 1                    
                    if ismember("ROIorders", variableInfo) == 1 
                        caLoc = ROIorders{1};
                    elseif ismember("ROIorders", variableInfo) == 0 
                        caLoc = CaROImasks{1};
                    end
                    caLoc(caLoc ~= terminals{mouse}(ccell)) = 0;
                    caLoc(caLoc == terminals{mouse}(ccell)) = 1;
                    caLoc = logical(caLoc);
                    % make vessel outline mask
                    radius = 6;
                    decomposition = 0;
                    se = strel('disk', radius, decomposition);               
                    caLocMask = imdilate(caLoc,se);       
                    caLocMasks = repmat(caLocMask,1,1,size(Vid{terminals{mouse}(ccell)},3));
                    % black out pixels that are far from vessel 
                    sumVid{terminals{mouse}(ccell)}(~caLocMasks) = 0;
                end 
            end 
            % calculate op flow vectors from sumVid     
            for frame = 1:size(sumVid{terminals{mouse}(ccell)},3)
                % determine optical flow  
                if frame < size(sumVid{terminals{mouse}(ccell)},3)
                    im1 = sumVid{terminals{mouse}(ccell)}(:,:,frame);
                    im2 = sumVid{terminals{mouse}(ccell)}(:,:,frame+1);
                    opflow{ccell,frame} = opticalFlow(im1,im2);
                    sumVel(ccell,frame+1) = sum(sum(opflow{ccell,frame}.Magnitude)); 
                end                                 
            end       
            % determine range of color amp data             
            velMax = max(sumVel(ccell,:));                        
            velMin = min(sumVel(ccell,:));          
            velRange = velMax - velMin;                                      
            % determine plotting buffer space for color data           
            velBufferSpace = velRange;            
            % determine first set of plotting min and max values for color data
            velPlotMin = velMin - velBufferSpace;            
            velPlotMax = velMax + velBufferSpace;               
            % determine color 0 ratio/location
            velZeroRatio = abs(velPlotMin)/(velPlotMax-velPlotMin);            
            % determine how much to shift the color axis so that the zeros align 
            velBelowZero = (velPlotMax-velPlotMin)*CaZeroRatio;
            velAboveZero = (velPlotMax-velPlotMin)-velBelowZero;                  
            % plot 
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
            % add right y axis tick marks for a specific DOD figure. 
            yyaxis right 
            p(1) = plot(sumVel(ccell,:),'k','LineWidth',4);
%                             patch([x fliplr(x)],[(close_CI_bLow{mouse}{BBBroi}{per}) (fliplr(close_CI_bHigh{mouse}{BBBroi}{per}))],Bcolors(1,:),'EdgeColor','none')
            if vidQ == 0 
                ylabel('Pixel Velocity Amplitude Whole Vid','FontName','Times')
            elseif vidQ == 1 
                ylabel('Pixel Velocity Amplitude Near Vessel','FontName','Times')
            end 
            title(sprintf('Axon %d',terminals{mouse}(ccell)))
            alpha(0.3)
%                             legend([p(1) p(2)],'Close Terminals','Far Terminals')
            set(gca,'YColor',[0 0 0]);   
            ylim([-velBelowZero velAboveZero])   
            xlim([1 53])
            % save the plots out 
            if vidQ == 0
                label = sprintf('%s/Axon%d_wholeVid_pixelVelocityAmp.tif',dir2,terminals{mouse}(ccell));
            elseif vidQ == 1 
                label = sprintf('%s/Axon%d_nearVessel_pixelVelocityAmp.tif',dir2,terminals{mouse}(ccell));
            end 
            export_fig(label)                        
        end 
    end       
end 
% plots av figure of all calcium ROI 
mouse = 1; 
per = 1; 
%DETERMINE 95% CI                       
SEMc = (nanstd(CTraceArray{mouse}{per}))/(sqrt(size(CTraceArray{mouse}{per},1))); % Standard Error            
ts_cLow = tinv(0.025,size(CTraceArray{mouse}{per},1)-1);% T-Score for 95% CI
ts_cHigh = tinv(0.975,size(CTraceArray{mouse}{per},1)-1);% T-Score for 95% CI
CI_cLow{mouse}{per} = (nanmean(CTraceArray{mouse}{per},1)) + (ts_cLow*SEMc);  % Confidence Intervals
CI_cHigh{mouse}{per} = (nanmean(CTraceArray{mouse}{per},1)) + (ts_cHigh*SEMc);  % Confidence Intervals 
x = 1:53;
%get averages
AVSNCdataPeaks{mouse}{per} = nanmean(CTraceArray{mouse}{per},1);  
%DETERMINE 95% of green and red amps and average (across axons)                      
SEMv = (nanstd(sumVel))/(sqrt(size(sumVel,1))); % Standard Error                 
ts_vLow = tinv(0.025,size(sumVel,1)-1);% T-Score for 95% CI           
ts_vHigh = tinv(0.975,size(sumVel,1)-1);% T-Score for 95% CI           
CI_vLow = (nanmean(sumVel,1)) + (ts_vLow*SEMv);  % Confidence Intervals
CI_vHigh = (nanmean(sumVel,1)) + (ts_vHigh*SEMv);  % Confidence Intervals 
%get average
AVSNVdataPeaks = nanmean(sumVel,1);   

% plot 
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
% add right y axis tick marks for a specific DOD figure. 
yyaxis right 
p(1) = plot(AVSNVdataPeaks,'k','LineWidth',4);
patch([x fliplr(x)],[CI_vLow fliplr(CI_vHigh)],'k','EdgeColor','none')
%                             patch([x fliplr(x)],[(close_CI_bLow{mouse}{BBBroi}{per}) (fliplr(close_CI_bHigh{mouse}{BBBroi}{per}))],Bcolors(1,:),'EdgeColor','none')
if vidQ == 0 
    ylabel('Pixel Velocity Amplitude Whole Vid','FontName','Times')
elseif vidQ == 1 
    ylabel('Pixel Velocity Amplitude Near Vessel','FontName','Times')
end 
title(sprintf('Axons Averaged'))
alpha(0.3)
%                             legend([p(1) p(2)],'Close Terminals','Far Terminals')
set(gca,'YColor',[0 0 0]);   
ylim([-velBelowZero velAboveZero])   
xlim([1 53])
% save the plots out 
if vidQ == 0
    label = sprintf('%s/AxonAverage_wholeVid_pixelVelocityAmp.tif',dir2);
elseif vidQ == 1 
    label = sprintf('%s/AxonAverage_nearVessel_pixelVelocityAmp.tif',dir2);
end 
export_fig(label)     
%}
%% make diff STA vids: subtract STA bootstrapped vids from STA vids 
%{
% first import the .mat file containing the STA (real spike vids) that you
% want to subtract from 

% ask where the bootsrapped vids are located 
dir1 = uigetdir('*.*','WHERE ARE THE BOOTSTRAPPED VIDEOS?'); % get the directory where you want to save your images 
dir2 = strrep(dir1,'\','/'); % change the direction of the slashes 
bootNum = 6;
% average the videos to make bootstrapped vids 
sortedVids = cell(1,length(RightChan));
clear RightChan
RightChan2 = cell(1,max(terminals{1}));
allVids = cell(1,bootNum);
for boot = 1:bootNum
    filename = sprintf('rightChan_%d.mat',boot);
    filename2 = append(dir2,'/',filename);
    load(filename2,"RightChan")
    allVids{boot} = RightChan;
    for ccell = 1:length(terminals{mouse})
        sortedVids{terminals{mouse}(ccell)}(:,:,:,4) = allVids{boot}{terminals{mouse}(ccell)};
        RightChan2{terminals{mouse}(ccell)} = nanmean(sortedVids{terminals{mouse}(ccell)},4);
    end 
end 
clear sortedVids allVids
% subtract the STA bootstrapped vids (RightChan2) from the real STA vids
% (RightChan) 
diffStack = cell(1,max(terminals{mouse}));
for ccell = 1:length(terminals{mouse})
    diffStack{terminals{mouse}(ccell)} = RightChan{terminals{mouse}(ccell)}-RightChan2{terminals{mouse}(ccell)};
end 
% save out the diff vids 
dir3 = uigetdir('*.*','WHERE DO YOU WANT TO SAVE THE IMAGES?'); % get the directory where you want to save your images 
dir4 = strrep(dir3,'\','/'); % change the direction of the slashes 

%% to make sure Ca ROIs show an average peak in the same frame, before
% moving onto the next step 
RightChan = diffStack;
CaFrameQ = input('Input 1 if you if you checked to make sure averaged Ca events happened in the same frame per ROI. And the anatomy is correct. ');
vesBlackQ = input('Input 1 to black out vessel. '); 
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
                    RightChan{terminals{mouse}(ccell)}(BWstacks{terminals{mouse}(ccell)}) = 0; 
                end                            
                %find the upper and lower bounds of your data (per calcium ROI) 
                maxValue = max(max(max(max(RightChan{terminals{mouse}(ccell)}))));
                minValue = min(min(min(min(RightChan{terminals{mouse}(ccell)}))));
                minMaxAbsVals = [abs(minValue),abs(maxValue)];
                maxAbVal = max(minMaxAbsVals);
                % ask user where to crop image
                if ccell == 1   
                    if BBBtraceQ == 1 
                        BBBtraceNumQ = input("How manny BBB traces do you want to generate? ");
                    end                 
                end            
                %create a new folder per calcium ROI 
                newFolder = sprintf('CaROI_%d_BBBsignal_diffImage',terminals{mouse}(ccell));
                mkdir(dir4,newFolder)
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
                                    [~,xmins,ymins,widths,heights] = firstTimeCreateROIs(1,RightChan{terminals{mouse}(ccell)}(:,:,frame));
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
                            [ROI_stacks] = make_ROIs_notfirst_time(RightChan{terminals{mouse}(ccell)}(:,:,frame),xmins,ymins,widths,heights);
                            ROIstacks{terminals{mouse}(ccell)}{BBBroi}(:,:,frame) = ROI_stacks{1};
                        end 
                    end 
                    % create the % change image with the right white and black point
                    % boundaries and colormap 
                    if cMapQ == 0
                        imagesc(RightChan{terminals{mouse}(ccell)}(:,:,frame),[-maxAbVal,maxAbVal]); colormap(cMap); colorbar%this makes the max point 1% and the min point -1% 
                    elseif cMapQ == 1 
                        imagesc(RightChan{terminals{mouse}(ccell)}(:,:,frame),[0,maxAbVal/3]); colormap(cMap); colorbar%this makes the max point 1% and the min point -1% 
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
                        colLen = size(RightChan{terminals{mouse}(ccell)},2);
                        rowLen = size(RightChan{terminals{mouse}(ccell)},1);
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
                    filename = sprintf('%s/CaROI_%d_BBBsignal_diffImage/CaROI_%d_frame%d_diffImage',dir4,terminals{mouse}(ccell),terminals{mouse}(ccell),frame);
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
                        SEMc = (nanstd(CTraceArray{mouse}{per}))/(sqrt(size(CTraceArray{mouse}{per},1))); % Standard Error            
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
        
        clearvars BW BWstacks BW_perim segOverlays
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
                    scatter(edg_x,edg_y,15,'white','filled','square');               
                end 
                ax = gca;
                ax.Visible = 'off';
                ax.FontSize = 20;
                %save current figure to file 
                termsString1 = string(termsToAv);
                termsString = join(termsString1,'_');
                filename = sprintf('%s/CaROIs_%s_frame%d',dir4,termsString,frame);
                saveas(gca,[filename '.png'])
            end 
        end 
        clearvars STAterms STAtermsVesChans STAav STAavVesVid BWstacks BW_perim segOverlays
    end 
end 
%}
%% use red green pixel amp figures to group axons into listeners vs talkers
% PLAY AROUND WITH FINDING PEAKS - PLOTTING CODE IS ALL WORKING 
% PUT ON HOLD FOR NOW - BELOW CODE IS MORE PROMISING 
%{

mouse = 1;
Gpeaks = cell(1,length(terminals{mouse}));
Glocs = cell(1,length(terminals{mouse}));
Rpeaks = cell(1,length(terminals{mouse}));
Rlocs = cell(1,length(terminals{mouse}));
stdG = zeros(1,length(terminals{mouse}));
stdR = zeros(1,length(terminals{mouse}));
sigGpeaks = cell(1,length(terminals{mouse}));
sigGlocs = cell(1,length(terminals{mouse}));
sigRpeaks = cell(1,length(terminals{mouse}));
sigRlocs = cell(1,length(terminals{mouse}));
for ccell = 1:length(terminals{mouse})
    [Gpeaks{ccell}, Glocs{ccell}] = findpeaks(greenSum(ccell,:),'MinPeakProminence',0.1,'MinPeakWidth',2); %0.6,0.8,0.9,1\
    [Rpeaks{ccell}, Rlocs{ccell}] = findpeaks(redSum(ccell,:),'MinPeakProminence',0.1,'MinPeakWidth',2); %0.6,0.8,0.9,1\   
    %find the sig peaks (peaks above 2 standard deviations from mean) 
    stdG(ccell) = std(greenSum(ccell,:)); 
    stdR(ccell) = std(redSum(ccell,:)); 
    count = 1 ; 
    for loc = 1:length(Gpeaks{ccell})
        if Gpeaks{ccell}(loc) > stdG(ccell)*2
            sigGpeaks{ccell}(count) = Gpeaks{ccell}(loc);
            sigGlocs{ccell}(count) = Gpeaks{ccell}(loc);
            count = count + 1;
        end 
    end 
    count = 1 ; 
    for loc = 1:length(Rpeaks{ccell})
        if Rpeaks{ccell}(loc) > stdG(ccell)*2
            sigRpeaks{ccell}(count) = Rpeaks{ccell}(loc);
            sigRlocs{ccell}(count) = Rpeaks{ccell}(loc);
            count = count + 1;
        end 
    end    
    % plot the traces with the sigPeaks marked 
    % determine range of color amp data  
    greenMax = max(greenSum(ccell,:)); redMax = max(redSum(ccell,:)); 
    maxVals = [greenMax,redMax]; maxVal = max(maxVals);
    greenMin = min(greenSum(ccell,:)); redMin = min(redSum(ccell,:)); 
    minVals = [greenMin,redMin]; minVal = min(minVals);
    colorRange = maxVal - minVal;                        
    % determine plotting buffer space for color data 
    colorBufferSpace = colorRange;            
    % determine first set of plotting min and max values for color data
    colorPlotMin = minVal - colorBufferSpace;
    colorPlotMax = maxVal + colorBufferSpace;             
    % determine color 0 ratio/location
    colorZeroRatio = abs(colorPlotMin)/(colorPlotMax-colorPlotMin);            
    % determine how much to shift the color axis so that the zeros align 
    colorBelowZero = (colorPlotMax-colorPlotMin)*CaZeroRatio;
    colorAboveZero = (colorPlotMax-colorPlotMin)-colorBelowZero;        
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
    ylim([min(AVSNCdataPeaks{mouse}{per}-CaBufferSpace) max(AVSNCdataPeaks{mouse}{per}+CaBufferSpace)])
    set(fig,'position', [500 100 900 800])
    alpha(0.3)
    % add right y axis tick marks for a specific DOD figure. 
    yyaxis right 
    p(1) = plot(greenSum(ccell,:),'green','LineWidth',4);
    p(1) = plot(redSum(ccell,:),'red','LineWidth',4,'LineStyle','-');
%                             patch([x fliplr(x)],[(close_CI_bLow{mouse}{BBBroi}{per}) (fliplr(close_CI_bHigh{mouse}{BBBroi}{per}))],Bcolors(1,:),'EdgeColor','none')
    if vidQ == 0 
        ylabel('Red and Green Amplitude Whole Vid','FontName','Times')
    elseif vidQ == 1 
        ylabel('Red and Green Amplitude Near Vessel','FontName','Times')
    end 
    title(sprintf('Axon %d',terminals{mouse}(ccell)))
    alpha(0.3)
%                             legend([p(1) p(2)],'Close Terminals','Far Terminals')
    set(gca,'YColor',[0 0 0]);   
    ylim([-colorBelowZero colorAboveZero])   
    xlim([1 53])
    for peak = 1:length(sigGlocs{ccell})
        plot([sigGlocs{ccell}(peak) sigGlocs{ccell}(peak)], [-5000 5000], 'g','LineWidth',2,'LineStyle','-')
    end 
    for peak = 1:length(sigRlocs{ccell})
        plot([sigRlocs{ccell}(peak) sigRlocs{ccell}(peak)], [-5000 5000], 'r','LineWidth',2,'LineStyle','-')
    end 
    % save the plots out 
    if vidQ == 0
        label = sprintf('%s/Axon%d_wholeVid_redGreenAmp.tif',dir2,terminals{mouse}(ccell));
    elseif vidQ == 1 
        label = sprintf('%s/Axon%d_nearVessel_redGreenAmp.tif',dir2,terminals{mouse}(ccell));
    end 
%     export_fig(label)        
end 

               
%}
%%  BBB plume code (one animal at a time) 
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% NEXT: 

% 12) THEN PLOT PIXEL AMP, 
% 13) PLOT PLUME TIMING ON SIDE WITH AVERAGE PIXEL AMP
% 10) PLOT WHEN PLUME TOUCHES VESSEL RELATIVE TO IT'S OWN EXISTANCE TO
% FIGURE OUT PLUME MOVEMENT DIRECTION 
% 11) PLOT LIKLIHOOD OF PLUME MOVING AWAY VS TOWARDS VESSEL 
% 14) CLUSTER VELOCITY AS FUNCTION OF
% DISTANCE 
% ON TOP 


% TO GROUP AXONS INTO LISTENERS VS TALKERS 
% AVERAGE ACROSS MICE: Notes: first just make binarySTA for multiple mice
% and import that, then rewrite bottom code for multiple binarySTA vids. 
% 
% IF TOP APPROACH IS TOO SLOW
% make different avClocFrame variable for
% cluster start and average time, go through all figures and make sure
% variables are unique so I can pull variables per mouse for
% averaging/plotting together 

% DBSCAN/STA VIDS TIME LOCKED TO OPTO STIM AND BEHAVIOR 


mouse = 1;
vidQ2 = input('Input 1 to black out pixels inside of vessel. ');
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
for ccell = 1:length(terminals{mouse})
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
        % determine if cLocs are near the vessel 
        cLocsNearVes = ismember(indsV2{terminals{mouse}(ccell)},cLocs,'rows');
        if ~any(cLocsNearVes == 1) == 1 % if the cluster is not near the vessel 
            % delete cluster that is not near the vessel 
            inds{terminals{mouse}(ccell)}(Crow,:) = NaN; 
            idx{terminals{mouse}(ccell)}(Crow,:) = NaN; 
            CsNotNearVessel{terminals{mouse}(ccell)}(count) = unIdxVals{terminals{mouse}(ccell)}(clust);
            count = count + 1;            
        end 
        % determine cluster size 
        clustSize(ccell,clust) = sum(idx{terminals{mouse}(ccell)}(:) == unIdxVals{terminals{mouse}(ccell)}(clust));
        % determine cluster pixel amplitude 
        pixAmp = nan(1,size(cLocs,1));
        for pix = 1:length(pixAmp)
            pixAmp(pix) = RightChan{terminals{mouse}(ccell)}(cLocs(pix,2),cLocs(pix,1),cLocs(pix,3));
        end 
        clustAmp(ccell,clust) =  nansum(pixAmp); %#ok<*NANSUM> 
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
    if ismember("ROIorders", variableInfo) == 1 % returns true
        [CAyf, CAxf] = find(ROIorders{1} == terminals{mouse}(ccell));  % x and y are column vectors.
    elseif ismember("ROIorders", variableInfo) == 0 % returns true
        [CAyf, CAxf] = find(CaROImasks{1} == terminals{mouse}(ccell));  % x and y are column vectors.
    end   
    % create axon x, y, z matrix 
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
    % plot axon location 
    hold on; scatter3(indsA{terminals{mouse}(ccell)}(:,1),indsA{terminals{mouse}(ccell)}(:,2),indsA{terminals{mouse}(ccell)}(:,3),30,'r'); % plot axon 
    title(sprintf('Axon %d',terminals{mouse}(ccell)));  
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

%% plot the proportion of clusters that are near the vessel out of total # of clusters 
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
clustSpikeQ3 = input('Input 0 to get average cluster timing. 1 to get start of cluster timing. ');
if clustSpikeQ == 1
    clustSpikeQ2 = input('Input 0 to see pre spike clusters. Input 1 to see post spike clusters. ');     
end 

% determine largest number of clusters across all axons
[s, ~] = cellfun(@size,unIdxVals);
maxNumClusts = max(s);
avClocFrame = NaN(length(terminals{mouse}),maxNumClusts);
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
            clustPixAmpTS{terminals{mouse}(ccell)}(clust,frame) = nansum(pixAmp); %#ok<*NANSUM> 
            % get change in cluster size 
            clustSizeTS{terminals{mouse}(ccell)}(clust,frame) = length(find(cLocs(:,3)==frame));
        end  
    end 
    % remove clusters that start at the first frame and decrease over
    % time 
    [earlyClusts, ~] = find(clustSizeTS{terminals{mouse}(ccell)}(:,1) > 0);
    % determine trend line     
    for clust = 1:length(earlyClusts)
        clustFit{ccell,clust} = fit((1:sum(~isnan(clustSizeTS{terminals{mouse}(ccell)}(earlyClusts(clust),:))))',(clustSizeTS{terminals{mouse}(ccell)}(earlyClusts(clust),1:sum(~isnan(clustSizeTS{terminals{mouse}(ccell)}(earlyClusts(clust),:)))))','poly1');
        if clustFit{ccell,clust}.p1 < 0 % if the slope is negative 
            % find what rows each cluster is located in
            [Crow, ~] = find(idx{terminals{mouse}(ccell)} == earlyClusts(clust)-1); 
            % remove the cluster 
            inds{terminals{mouse}(ccell)}(Crow,:) = NaN; 
            idx{terminals{mouse}(ccell)}(Crow,:) = NaN; 
            clustSize(ccell,earlyClusts(clust)) = NaN;
            clustAmp(ccell,earlyClusts(clust)) = NaN;
            clustSizeTS{terminals{mouse}(ccell)}(earlyClusts(clust),:) = NaN;
            avClocFrame(ccell,earlyClusts(clust)) = NaN;
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

% determine distance of each cluster from each axon 
dists = cell(1,max(terminals{mouse}));
minACdists = NaN(length(terminals{mouse}),length(unIdxVals{terminals{mouse}(ccell)}));
for ccell = 1:length(terminals{mouse})
    for clust = 1:length(unIdxVals{terminals{mouse}(ccell)})
       % find what rows each cluster is located in
        [Crow, ~] = find(idx{terminals{mouse}(ccell)} == unIdxVals{terminals{mouse}(ccell)}(clust)); 
        % identify the x, y, z location of pixels per cluster
        cLocs = inds{terminals{mouse}(ccell)}(Crow,:);  
        for Apoint = 1:size(indsA{terminals{mouse}(ccell)},1)
            for Cpoint = 1:size(cLocs,1)
                % get euclidean pixel distance between each Ca ROI pixel
                % and BBB cluster pixel 
                dists{terminals{mouse}(ccell)}{clust}(Apoint,Cpoint) = sqrt(((cLocs(Cpoint,1)-indsA{terminals{mouse}(ccell)}(Apoint,1))^2)+((cLocs(Cpoint,2)-indsA{terminals{mouse}(ccell)}(Apoint,2))^2)+((cLocs(Cpoint,3)-indsA{terminals{mouse}(ccell)}(Apoint,3))^2)); 
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
clear sizeDistArray includeX includY includeXY
labels = strings(1,length(terminals{mouse}));
f = cell(1,length(terminals{mouse}));
for ccell = 1:length(terminals{mouse})
    if ccell == 1 
        sizeDistArray(:,1) = minACdists(ccell,:);
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
        sizeDistArray(len2+1:len2+len,1) = minACdists(ccell,:);
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
    fav = fit(sizeDistX(includeXY),sizeDistY(includeXY),'poly1');
end 

clear ampDistArray includeX includY includeXY
fAmp = cell(1,length(terminals{mouse}));
for ccell = 1:length(terminals{mouse})
    if ccell == 1 
        ampDistArray(:,1) = minACdists(ccell,:);
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
        ampDistArray(len2+1:len2+len,1) = minACdists(ccell,:);
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
    fAmpAv = fit(ampDistX(includeXY),ampDistY(includeXY),'poly1');
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
    fav2 = fit(timeDistX(includeXY2),timeDistY(includeXY2),'poly1');
end 

% determine cluster distance from VR space if you want 
VRQ = input('Input 1 to determine the distance of each axon from the VR space. ');
if VRQ == 1 
    drawVRQ = input('Input 1 to draw VR space outline. ');
    if drawVRQ == 1 
        vesIm = nanmean(vesChan{terminals{mouse}(1)},3);
        imshow(vesIm,[0 500])
        VRdata = drawfreehand(gca);  % manually draw vessel outline
        % get VR outline coordinates 
        VRinds = VRdata.Position;    
        outLineQ = input('Input 1 if you are done drawing the VR outline. ');
        if outLineQ == 1
            close all
        end 
        len = size(VRinds,1); 
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
    for ccell = 5:length(terminals{mouse})
        for clust = 1:length(unIdxVals{terminals{mouse}(ccell)})
           % find what rows each cluster is located in
            [Crow, ~] = find(idx{terminals{mouse}(ccell)} == unIdxVals{terminals{mouse}(ccell)}(clust)); 
            % identify the x, y, z location of pixels per cluster
            cLocs = inds{terminals{mouse}(ccell)}(Crow,:);  
            for VRpoint = 1:size(indsVR,1)
                for Cpoint = 1:size(cLocs,1)
                    % get euclidean pixel distance between each Ca ROI pixel
                    % and BBB cluster pixel 
                    dists{terminals{mouse}(ccell)}{clust}(VRpoint,Cpoint) = sqrt(((cLocs(Cpoint,1)-indsVR(VRpoint,1))^2)+((cLocs(Cpoint,2)-indsVR(VRpoint,2))^2)+((cLocs(Cpoint,3)-indsVR(VRpoint,3))^2)); 
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
        fav3 = fit(timeVRDistX(includeXY3),timeVRDistY(includeXY3),'poly1');
    end 
end 


%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$               
%% plot cluster size and pixel amplitude as function of distance from axon 

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
hold on;
for ccell = 1:length(terminals{mouse})
    fitHandle = plot(f{ccell});
    set(fitHandle,'Color',clr(ccell,:));
end 
if length(find(includeXY)) > 1
    fitHandle = plot(fav);
    leg = legend('show');
    set(fitHandle,'Color',[0 0 0],'LineWidth',3);
    leg.String(end) = [];
end 
ylabel("Size of Cluster")
xlabel("Distance From Axon") 
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
hold on;
for ccell = 1:length(terminals{mouse})
    fitHandle = plot(fAmp{ccell});
    set(fitHandle,'Color',clr(ccell,:));
end 
if length(find(includeXY)) > 1
    fitHandle = plot(fAmpAv);
    leg = legend('show');
    set(fitHandle,'Color',[0 0 0],'LineWidth',3);
    leg.String(end) = [];
end 
ylabel("Pixel Amplitude of Cluster")
xlabel("Distance From Axon") 
if clustSpikeQ == 0 
    title('All Clusters');
elseif clustSpikeQ == 1 
    if clustSpikeQ2 == 0 
        title('Pre Spike Clusters');
    elseif clustSpikeQ2 == 1
        title('Post Spike Clusters');
    end 
end 

%% plot distance from axon as a function of cluster timing
if clustSpikeQ == 0 
    figure;
    ax=gca;
    clr = hsv(length(terminals{mouse}));
    gscatter(timeDistArray(:,1),timeDistArray(:,2),timeDistArray(:,3),clr)
    ax.FontSize = 15;
    ax.FontName = 'Times';
    % figure out what axons have clusters to be plotted 
    fullRows = find(~isnan(timeDistArray(:,1)));
    axons = unique(timeDistArray(fullRows,3));
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
    end 
    ylabel("Distance From Axon")
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
    FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
end 

%% plot VR-BBB plume distance as function of BBB plume timing 
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
        hold on;
        for ccell = 1:length(terminals{mouse})
            fitHandle = plot(f3{ccell});
            set(fitHandle,'Color',clr(ccell,:));
        end 
        if length(find(includeXY)) > 1
            fitHandle = plot(fav3);
            leg = legend('show');
            set(fitHandle,'Color',[0 0 0],'LineWidth',3);
            leg.String(end) = [];
        end 
        ylabel("Distance From VR space")
        if clustSpikeQ3 == 0 
            xlabel("Average BBB Plume Timing") 
        elseif clustSpikeQ3 == 1
            xlabel("BBB Plume Start Time") 
        end 
        title('BBB Plume Distance From VR Space Compared to Timing');
        Frames = size(im,3);
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
        FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;  
    end 
end 


%% plot distribution of cluster sizes and pixel amplitudes 
figure;
ax=gca;
histogram(sizeDistArray(:,2),100)
ax.FontSize = 15;
ax.FontName = 'Times';
if clustSpikeQ == 0 
    title({'Distribution of BBB Plume Sizes';'All Clusters'});
elseif clustSpikeQ == 1 
    if clustSpikeQ2 == 0 
        title({'Distribution of BBB Plume Sizes';'Pre-Spike Clusters'});
    elseif clustSpikeQ2 == 1
        title({'Distribution of BBB Plume Sizes';'Post-Spike Clusters'});
    end 
end 
ylabel("Number of BBB Plumes")
xlabel("Size of BBB Plume") 

figure;
ax=gca;
histogram(ampDistArray(:,2),100)
ax.FontSize = 15;
ax.FontName = 'Times';
if clustSpikeQ == 0 
    title({'Distribution of BBB Plume Pixel Amplitudes';'All Clusters'});
elseif clustSpikeQ == 1 
    if clustSpikeQ2 == 0 
        title({'Distribution of BBB Plume Pixel Amplitudes';'Pre-Spike Clusters'});
    elseif clustSpikeQ2 == 1
        title({'Distribution of BBB Plume Pixel Amplitudes';'Post-Spike Clusters'});
    end 
end 
ylabel("Number of BBB Plumes")
xlabel("BBB Plume Pixel Amplitudes") 

%% plot distribution of cluster times 
if clustSpikeQ == 0 
    figure;
    ax=gca;
    histogram(avClocFrame,20)
    ax.FontSize = 15;
    ax.FontName = 'Times';
    if clustSpikeQ3 == 0 
        title({'Distribution of BBB Plume Timing';'Average Time'});
    elseif clustSpikeQ3 == 1
        title({'Distribution of BBB Plume Timing';'Start Time'});
    end 
    ylabel("Number of BBB Plumes")
    xlabel("Time (s)") 
    Frames = size(im,3);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
    FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
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
    yline(frameThresh)
    ax.FontSize = 15;
    ax.FontName = 'Times';
    ylabel("Average BBB Plume Timing")
    xlabel("Axon")
    if clustSpikeQ3 == 0
        title({'BBB Plume Timing By Axon';'Average Cluster Time'});
    elseif clustSpikeQ3 == 1
        title({'BBB Plume Timing By Axon';'Cluster Start Time'});
    end     
    xticklabels(labels)
    Frames = size(im,3);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
    FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
    ax.YTick = FrameVals;
    ax.YTickLabel = sec_TimeVals;  
end 

%% plot cluster size and pixel amp grouped by pre and post spike 

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
    ylabel("BBB Plume Size")
    xlabel("Axon")  
    title({'BBB Plume Size By Axon';'All Plumes'});
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
    ylabel("BBB Plume Pixel Amplitude")
    xlabel("Axon")  
    title({'BBB Plume Pixel Amplitude By Axon';'All Plumes'});
    xticklabels(labels)
    set(gca, 'YScale', 'log')
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
        ylabel("BBB Plume Size")
        xlabel("Axon")  
        if clustSpikeQ3 == 0 
            title({'BBB Plume Size By Axon';'Pre And Post Spike Plumes';'Average Cluster Time'});   
        elseif clustSpikeQ3 == 1
            title({'BBB Plume Size By Axon';'Pre And Post Spike Plumes';'Cluster Start Time'});   
        end          
        legend("Pre-Spike BBB Plume","Post-Spike BBB Plume")
        xticklabels(labels)   

        figure;
        ax=gca;
        % plot box plot 
        boxchart(CampForPlotPre,'MarkerStyle','none','BoxFaceColor','r','WhiskerLineColor','r');
        % plot swarm chart on top of box plot 
        hold all;
        boxchart(CampForPlotPost,'MarkerStyle','none','BoxFaceColor','b','WhiskerLineColor','b');
        ax.FontSize = 15;
        ax.FontName = 'Times';
        ylabel("BBB Plume Pixel Amplitude")
        xlabel("Axon")  
        if clustSpikeQ3 == 0 
            title({'BBB Plume Pixel Amplitude By Axon';'Pre And Post Spike Plumes';'Average Cluster Time'});   
        elseif clustSpikeQ3 == 1
            title({'BBB Plume Pixel Amplitude By Axon';'Pre And Post Spike Plumes';'Cluster Start Time'});   
        end          
        legend("Pre-Spike BBB Plume","Post-Spike BBB Plume")
        xticklabels(labels) 
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
        ylabel("BBB Plume Size") 
            if clustSpikeQ3 == 0 
                title({'BBB Plume Size By Axon';'Pre And Post Spike Plumes';'Averaged Across Axons';'Average Cluster Time'});  
            elseif clustSpikeQ3 == 1
                title({'BBB Plume Size By Axon';'Pre And Post Spike Plumes';'Averaged Across Axons';'Cluster Start Time'});  
            end             
        avLabels = ["Pre-Spike","Post-Spike"];
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
        ylabel("BBB Plume Pixel Amplitude") 
            if clustSpikeQ3 == 0 
                title({'BBB Plume Pixel Amplitude By Axon';'Pre And Post Spike Plumes';'Averaged Across Axons';'Average Cluster Time'});  
            elseif clustSpikeQ3 == 1
                title({'BBB Plume Pixel Amplitude By Axon';'Pre And Post Spike Plumes';'Averaged Across Axons';'Cluster Start Time'});  
            end             
        avLabels = ["Pre-Spike","Post-Spike"];
        xticklabels(avLabels)
    end 
end 


%% plot change in cluster size over time for each axon and averaged 
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% PICK UP HERE: PLOT PIXAMP OVER TIME 

if clustSpikeQ == 0
    clr = hsv(length(terminals{mouse}));
    x = 1:size(im,3);
    % make a string array for the axons 
    count = 1; 
    axonString = string(1);
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
            end 
            h = plot(x,clustSizeTS{terminals{mouse}(ccell)},'Color',clr(ccell,:),'LineWidth',2);   
        end 
    end     
    legend(axonLabel)
    Frames = size(im,3);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
    FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    ylabel("BBB Plume Size") 
    xlabel("Time (s)")
    title('Change in BBB Plume Size Over Time')
       
    % resort data to plot average cluster per axon
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
    legend(axonString)
    Frames = size(im,3);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
    FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    ylabel("BBB Plume Size") 
    xlabel("Time (s)")
    title({'Average Change in BBB Plume Size Over Time';'Per Axons'})
    
    % plot average of all axons w/95% CI 
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
    FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    ylabel("BBB Plume Size") 
    xlabel("Time (s)")
    title({'Average Change in BBB Plume Size Over Time';'Across Axons'})
end 

%% plot average BBB plume change in size over time for however many groups
% you want 
clustTimeGroupQ = input('Input 1 if you want to plot the average change in BBB plume size based on plume start time? ');
x = 1:size(im,3);
if clustTimeGroupQ == 1 
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
        binClustTSdata = cell(1,clustTimeNumGroups);
        sizeArray = zeros(1,clustTimeNumGroups);
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
                binStartAndEndFrames(bin,2) = binFrameThresh-1;
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
                sizeArray(bin) = size(binClustTSdata{bin},1);
                binClustTSdata{bin}(sizeArray(bin)+1:sizeArray(bin)+length(binClusts),:) = clustSizeTS{terminals{mouse}(ccell)}(binClusts,:);
            end 
            % determine bin labels 
            binString = string(round((binStartAndEndFrames(bin,:)./FPSstack{mouse})-(size(im,3)/FPSstack{mouse}/2),1));
            for clust = 1:size(binClustTSdata{bin},1)
                if clust == 1 
                    if isempty(binClustTSdata{bin}) == 0                     
                        binLabel(count) = append(binString(1),' to ',binString(2));
                        count = count + 1;
                    end 
                elseif clust > 1
                    if isempty(binClustTSdata{bin}) == 0 
                        binLabel(count) = '';
                        count = count + 1;                        
                    end                 
                end 
            end 
            if isempty(binClustTSdata{bin}) == 0 
                h = plot(x,binClustTSdata{bin},'Color',clr(bin,:),'LineWidth',2); 
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
        binClustTSdata = cell(1,clustTimeNumGroups);
        sizeArray = zeros(1,clustTimeNumGroups);
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
                sizeArray(bin) = size(binClustTSdata{bin},1);
                binClustTSdata{bin}(sizeArray(bin)+1:sizeArray(bin)+length(binClusts),:) = clustSizeTS{terminals{mouse}(ccell)}(binClusts,:);
            end 
            % determine bin labels 
            binString = string(round((binStartAndEndFrames(bin,:)./FPSstack{mouse})-(size(im,3)/FPSstack{mouse}/2),1));
            for clust = 1:size(binClustTSdata{bin},1)
                if clust == 1 
                    if isempty(binClustTSdata{bin}) == 0                     
                        binLabel(count) = append(binString(1),' to ',binString(2));
                        count = count + 1;
                    end 
                elseif clust > 1
                    if isempty(binClustTSdata{bin}) == 0 
                        binLabel(count) = '';
                        count = count + 1;                        
                    end                 
                end 
            end 
            if isempty(binClustTSdata{bin}) == 0 
                h = plot(x,binClustTSdata{bin},'Color',clr(bin,:),'LineWidth',2); 
            end 
        end
    end 
end 
legend(binLabel)
Frames = size(im,3);
Frames_pre_stim_start = -((Frames-1)/2); 
Frames_post_stim_start = (Frames-1)/2; 
sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1;
FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Size") 
xlabel("Time (s)")
title('Change in BBB Plume Size Over Time')

% plot average change in cluster size 
figure;
hold all;
ax=gca;
avBinClustSizeTS = NaN(clustTimeNumGroups,size(im,3));
count = 1;
for bin = 1:clustTimeNumGroups
    if isempty(binClustTSdata{bin}) == 0
        avBinClustSizeTS(count,:) = nanmean(binClustTSdata{bin},1);  
        plot(x,avBinClustSizeTS(count,:),'Color',clr(bin,:),'LineWidth',2);      
        count = count + 1;
    end 
end 
% remove empty strings 
emptyStrings = find(binLabel == '');
binLabel(emptyStrings) = [];
legend(binLabel)
Frames = size(im,3);
Frames_pre_stim_start = -((Frames-1)/2); 
Frames_post_stim_start = (Frames-1)/2; 
sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1+timeEnd;
FrameVals = round((1:FPSstack{mouse}:Frames))+5; 
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Size") 
xlabel("Time (s)")
title({'Average Change in BBB Plume Size Over Time'})

% plot aligned clusters per bin and total average 
% determine cluster start frame per bin  
binClustStartFrame = cell(1,clustTimeNumGroups);
alignedBinClusts = cell(1,clustTimeNumGroups);
avAlignedClusts = cell(1,clustTimeNumGroups);
figure;
hold all;
ax=gca;
for bin = 1:clustTimeNumGroups             
    [clustLocX, clustLocY] = find(~isnan(binClustTSdata{bin}));
    clusts = unique(clustLocX);              
    for clust = 1:length(clusts)
        binClustStartFrame{bin}(clust) = min(clustLocY(clustLocX == clust));
    end 
    % align clusters
    % determine longest cluster 
    [longestClustStart,longestClust] = min(binClustStartFrame{bin});
    arrayLen = size(im,3)-longestClustStart+1;
    for clust = 1:size(binClustTSdata{bin},1)
        % get data and buffer end as needed 
        data = binClustTSdata{bin}(clust,binClustStartFrame{bin}(clust):end);
        data(:,length(data)+1:arrayLen) = NaN;
        % align data 
        alignedBinClusts{bin}(clust,:) = data;
    end 
    x = 1:size(alignedBinClusts{bin},2);
    % averaged the aligned clusters 
    avAlignedClusts{bin} = nanmean(alignedBinClusts{bin},1);
    if isempty(binClustTSdata{bin}) == 0 
        h = plot(x,avAlignedClusts{bin},'Color',clr(bin,:),'LineWidth',2); 
    end 
end 
legend(binLabel)
Frames = size(im,3);
Frames_pre_stim_start = -((Frames-1)/2); 
Frames_post_stim_start = (Frames-1)/2; 
sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1+timeEnd-0.5;
FrameVals = round((1:FPSstack{mouse}:Frames)); 
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;  
ax.FontSize = 15;
ax.FontName = 'Times';
ylabel("BBB Plume Size") 
xlabel("Time (s)")
title({'Change in BBB Plume Size Over Time';'Clusters Aligned and Averaged'})

% plot total aligned cluster average 
[r,c] = cellfun(@size,alignedBinClusts);
maxLen = max(c);
if clustTimeNumGroups == 2     
    for bin = 1:clustTimeNumGroups           
        % put data together with appropriate buffering to get total average 
        data = alignedBinClusts{bin};
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
    Frames = size(im,3);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack{mouse}:Frames_post_stim_start)/FPSstack{mouse}))+1+timeEnd-0.5;
    FrameVals = round((1:FPSstack{mouse}:Frames)); 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;  
    ax.FontSize = 15;
    ax.FontName = 'Times';
    ylabel("BBB Plume Size") 
    xlabel("Time (s)")
    title({'Average Aligned Change in BBB Plume Size Over Time';'Across Axons'})
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
%% run FT on BBB data 
% takes ETA data files 
%{
% where is the ETA data?  
etaDir = uigetdir('*.*','WHERE IS THE ETA DATA');
cd(etaDir);
% list the .mat files in the folder 
fileList = dir(fullfile(etaDir,'*.mat'));


%%
selectData2plot = input('Input 1 to plot BBB data. Input 2 to plot VW data. Input 3 to plot Ca data. ');
% do Fourier transform 
Bdata = cell(1,size(fileList,1));
Vdata = cell(1,size(fileList,1));
Cdata = cell(1,size(fileList,1));
FPSstack = zeros(1,size(fileList,1));
P1 = cell(1,size(fileList,1));
f = cell(1,size(fileList,1));
PSlen = zeros(size(fileList,1),1);
terminals = cell(1,size(fileList,1));
for mouse = 1:size(fileList,1)    
    MatFileName = fileList(mouse).name;        
    Mat = matfile(MatFileName);
    Bdata{mouse} = Mat.Bdata;
    Vdata{mouse} = Mat.Vdata;
    Cdata{mouse} = Mat.CAdata;
    terminals{mouse} = Mat.terminals;
    FPSstack(mouse) = Mat.FPSstack;
    if selectData2plot == 1
        data = Bdata;
        label = 'BBB data';
    elseif selectData2plot == 2
        data = Vdata;
        label = 'Vessel Width data';
    elseif selectData2plot == 3
        data = Cdata;
        label = 'Calcium data';
    end 
    if selectData2plot == 1 || selectData2plot == 2
        for roi = 1:length(data{mouse})
            % set paramaters
            Fs = FPSstack(mouse);            % Sampling frequency                    
            T = 1/Fs;             % Sampling period       
            L = length(data{mouse}{roi})/FPSstack(mouse);             % Length of signal (in ms)
            t = (0:L-1)*T;        % Time vector
            % do FT 
            Y = fft(data{mouse}{roi});
            P2 = abs(Y/L);
            P1{mouse}{roi} = P2(1:L/2+1);
            P1{mouse}{roi}(2:end-1) = 2*P1{mouse}{roi}(2:end-1);
            f{mouse}{roi} = Fs*(0:(L/2))/L;        
            % determine length of power spectrums 
            PSlen(mouse,roi) = length(P1{mouse}{roi});
        end 
    elseif selectData2plot == 3
        for roi = 1:length(terminals{mouse})
            % set paramaters
            Fs = FPSstack(mouse);            % Sampling frequency                    
            T = 1/Fs;             % Sampling period       
            L = length(data{mouse}{terminals{mouse}(roi)})/FPSstack(mouse);             % Length of signal (in ms)
            t = (0:L-1)*T;        % Time vector
            % do FT 
            Y = fft(data{mouse}{terminals{mouse}(roi)});
            P2 = abs(Y/L);
            P1{mouse}{terminals{mouse}(roi)} = P2(1:L/2+1);
            P1{mouse}{terminals{mouse}(roi)}(2:end-1) = 2*P1{mouse}{terminals{mouse}(roi)}(2:end-1);
            f{mouse}{terminals{mouse}(roi)} = Fs*(0:(L/2))/L;        
            % determine length of power spectrums 
            PSlen(mouse,terminals{mouse}(roi)) = length(P1{mouse}{terminals{mouse}(roi)});
        end         
    end 
end 
xlimQ = input('Input 1 if you want to set x axis limits when plotting. ');
if xlimQ == 1 
    xLow = input('What is the x axis min? ');
    xHigh = input('What is the x axis max? ');
end 
% determine the non-zero min length of the power spectrums 
minPSlen = min(min(PSlen(PSlen>0)));
avQ = input('Input 1 if you want to average the power spectrums across mice. Input 0 otherwise. ');
% plot power spectrums 
dataArray = zeros(1,minPSlen);
fArray = zeros(1,minPSlen);
count = 1;
for mouse = 1:size(fileList,1) 
    if selectData2plot == 1 || selectData2plot == 2
        for roi = 1:length(data{mouse})
            if avQ == 0 
                figure        
                plot(f{mouse}{roi},P1{mouse}{roi}) 
                title({'Single-Sided Amplitude Spectrum of S(t)';sprintf('Mouse %d ROI %d',mouse,roi);label})
                xlabel('f (Hz)')
                ylabel('|P1(f)|')
                if xlimQ == 1 
                    xlim([xLow xHigh])
                end 
            elseif avQ == 1
                dataArray(count,:) = P1{mouse}{roi}(1:minPSlen);
                fArray(count,:) = f{mouse}{roi}(1:minPSlen);
                count = count + 1;
            end 
        end 
    elseif selectData2plot == 3 
        for roi = 1:length(terminals{mouse})
            if avQ == 0 
                figure        
                plot(f{mouse}{terminals{mouse}(roi)},P1{mouse}{terminals{mouse}(roi)}) 
                title({'Single-Sided Amplitude Spectrum of S(t)';sprintf('Mouse %d ROI %d',mouse,terminals{mouse}(roi));label})
                xlabel('f (Hz)')
                ylabel('|P1(f)|')
                if xlimQ == 1 
                    xlim([xLow xHigh])
                end 
            elseif avQ == 1
                dataArray(count,:) = P1{mouse}{terminals{mouse}(roi)}(1:minPSlen);
                fArray(count,:) = f{mouse}{terminals{mouse}(roi)}(1:minPSlen);
                count = count + 1;
            end 
        end         
    end 
end 
% plot averaged data 
if avQ == 1 
    avData = nanmean(dataArray);
    avF = nanmean(fArray);
    figure        
    plot(avF,avData) 
    title({'Single-Sided Amplitude Spectrum of S(t)';sprintf('%s Averaged Across Mice',label)})
    xlabel('f (Hz)')
    ylabel('|P1(f)|')
    if xlimQ == 1 
        xlim([xLow xHigh])
    end 
end 





%}
