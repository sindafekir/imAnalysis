% get the data you need 
%{
%set the paramaters 
ETAQ = input('Input 1 if you want to plot event triggered averages. Input 0 if otherwise. '); 
STAstackQ = input('Input 1 to import red and green channel stacks to create STA videos. Input 0 otherwise. ');
distQ = input('Input 1 if you want to determine distance of Ca ROIs from vessel. Input 0 otherwise. ');
if STAstackQ == 1 || distQ == 1 
    BGsubQ = input('Input 1 if you want to do background subtraction on your imported image stacks. Input 0 otherwise. ');
    if BGsubQ == 1
        BGsubTypeQ = input('Input 0 to select one background region and do a simple background subtraction of the mean pixel intensity of that region. Input 1 if you want to do row by row background subtraction. ');
    end 
end 
if ETAQ == 1 || STAstackQ == 1 
    stimStateQ = input('Input 0 if you used flyback stimulation. Input 1 if not. ');
    if stimStateQ == 0 
        state = 8;
    elseif stimStateQ == 1
        state = 7;
    end 
    framePeriod = input('What is the frame period? ');
    FPS = 1/framePeriod; 
    FPSstack = FPS/3;
    vidList = input('What videos are you analyzing? ');
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

% get your data 
if ETAQ == 1
    if BBBQ == 1 
        % get BBB data 
        BBBDir = uigetdir('*.*','WHERE IS THE BBB DATA?');
        cd(BBBDir);
        BBBlabel = input('Give a string example of what the BBB data is labeled as. Put %d in place of where the vid number is. '); % example: SF56_20190718_ROI2_vid1_BBB = SF56_20190718_ROI2_vid%d_BBB
        bDataFullTrace = cell(1,length(vidList));
        for vid = 1:length(vidList)
            BBBmat = matfile(sprintf(BBBlabel,vidList(vid)));
            Bdata = BBBmat.Bdata;       
            bDataFullTrace{vid} = Bdata;
        end 
    end 
    if VWQ == 1 
        % get vessel width data 
        VwDir = uigetdir('*.*','WHERE IS THE VESSEL WIDTH DATA?');
        cd(VwDir);
        VWlabel = input('Give a string example of what the vessel width data is labeled as. Put %d in place of where the vid number is. '); % example: SF56_20190718_ROI2_vid1_BBB = SF56_20190718_ROI2_vid%d_BBB
        vDataFullTrace = cell(1,length(vidList));
        for vid = 1:length(vidList)
            VWmat = matfile(sprintf(VWlabel,vidList(vid)));
            Vdata = VWmat.Vdata;       
            vDataFullTrace{vid} = Vdata;
        end 
    end 
end 
if ETAQ == 1 || STAstackQ == 1 
    if CAQ == 1 
        % get calcium data 
        CaDir = uigetdir('*.*','WHERE IS THE CALCIUM DATA?');
        cd(CaDir);
        CAlabel = input('Give a string example of what the calcium data is labeled as. Put %d in place of where the vid number is. '); % example: SF56_20190718_ROI2_vid1_BBB = SF56_20190718_ROI2_vid%d_BBB
        terminals = input('What terminals do you care about? Input in correct order. ');
        cDataFullTrace = cell(1,length(vidList));
        for vid = 1:length(vidList)
            CAmat = matfile(sprintf(CAlabel,vidList(vid)));
            CAdata = CAmat.CcellData;       
            cDataFullTrace{vid} = CAdata;
        end 
    end 
end

%get trial data to generate stimulus event triggered averages (ETAs)
if ETAQ == 1 ||  (exist('tTypeQ','var') == 1 && tTypeQ == 1)
    velWheelQ = input('Input 1 to get wheel data. Input 0 otherwise. ');
    state_start_f = cell(1,length(vidList));
    state_end_f2 = cell(1,length(vidList));
    TrialTypes = cell(1,length(vidList));
    trialLengths2 = cell(1,length(vidList));
    velWheelData = cell(1,length(vidList));
    wDataFullTrace = cell(1,length(vidList));
    for vid = 1:length(vidList)
        [~,statestartf,stateendf,~,vel_wheel_data,trialTypes] = makeHDFchart_redBlueStim(state,framePeriod);
        state_start_f{vid} = floor(statestartf/3);
        state_end_f2{vid} = floor(stateendf/3);
        TrialTypes{vid} = trialTypes(1:length(statestartf),:);
        trialLengths2{vid} = state_end_f2{vid}-state_start_f{vid};
        if velWheelQ == 1 
            velWheelData{vid} = vel_wheel_data;
            %resample wheel data 
            wDataFullTrace{vid} = resample(velWheelData{vid},length(bDataFullTrace{vid}{1}),length(velWheelData{vid}));
        end 
    end 
    
    % this fixes discrete time rounding errors to ensure the stimuli are
    % all the correct number of frames long 
    stimTimeLengths = input('How many seconds are the stims on for? ');
    stimFrameLengths = floor(stimTimeLengths*FPSstack);
    state_end_f = cell(1,length(vidList));
    trialLengths = cell(1,length(vidList));
    for frameLength = 1:length(stimFrameLengths)
        for vid = 1:length(vidList)
            for trial = 1:length(state_start_f{vid})
                if abs(trialLengths2{vid}(trial) - stimFrameLengths(frameLength)) < 5
                    state_end_f{vid}(trial) = state_start_f{vid}(trial) + stimFrameLengths(frameLength);
                    trialLengths{vid}(trial) = state_end_f{vid}(trial)-state_start_f{vid}(trial);
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
    greenStacks1 = cell(1,length(vidList));
    redStacks1 = cell(1,length(vidList));
    greenStacksBS = cell(1,length(vidList));
    redStacksBS = cell(1,length(vidList));
    redStackArray = cell(1,length(vidList));
    greenStackArray = cell(1,length(vidList));
    greenStacks = cell(1,length(vidList));
    redStacks = cell(1,length(vidList));
    for vid = 1:length(vidList)
        cd(regImDir);
        redMat = matfile(sprintf(redlabel,vidList(vid)));       
        redRegStacks = redMat.regStacks;
        redStacks1{vid} = redRegStacks{2,4};
        greenMat = matfile(sprintf(greenlabel,vidList(vid)));       
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
    redStacks1 = redRegStacks{2,4};   
    if BGsubQ == 0 
        redStacks = redStacks1;
    elseif BGsubQ == 1
        if BGsubTypeQ == 0        
            [redStacks_BS,BG_ROIboundData,CaROImasks] = backgroundSubtraction(redStacks1);
            redStacks = redStacks_BS;
        elseif BGsubTypeQ == 1
            [redStacks_BS,BG_ROIboundData,CaROImasks] = backgroundSubtractionPerRow(redStacks1);
            redStacks = redStacks_BS;
        end 
    end 
    %average all the frames per Z plane 
    redZstack = zeros(size(redStacks{1},1),size(redStacks{1},2),length(redStacks));
    for Z = 1:length(redStacks)
        redZstack(:,:,Z) = mean(redStacks{Z},3);
    end 
    clearvars -except redZstack distQ CaROImasks 
end 
%}
%% organize trial data 
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
    count = 1;
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
for ccell = 1:ccellLen
    count1 = 1;
    count2 = 1;
    count3 = 1;
    count4 = 1;
    for vid = 1:length(bDataFullTrace)    
        for trial = 1:length(plotStart{vid}) 
            if trialLengths{vid}(trial) ~= 0 
                 if (state_start_f{vid}(trial) - floor(sec_before_stim_start*FPSstack)) > 0 && state_end_f{vid}(trial) + floor(sec_after_stim_end*FPSstack) < length(bDataFullTrace{vid}{1})
                    %if the blue light is on
                    if TrialTypes{vid}(trial,2) == 1
                        %if it is a 2 sec trial 
                        if trialLengths{vid}(trial) == floor(2*FPSstack)     
                            if CAQ == 1
                                Ceta{terminals(ccell)}{1}(count1,:) = cDataFullTrace{vid}{terminals(ccell)}(plotStart{vid}(trial):plotEnd{vid}(trial));
                            end 
                            if BBBQ == 1 
                                for BBBroi = 1:length(bDataFullTrace{1})
                                    Beta{BBBroi}{1}(count1,:) = bDataFullTrace{vid}{BBBroi}(plotStart{vid}(trial):plotEnd{vid}(trial));
                                end 
                            end 
                            if VWQ == 1
                                for VWroi = 1:length(vDataFullTrace{1})
                                    Veta{VWroi}{1}(count1,:) = vDataFullTrace{vid}{VWroi}(plotStart{vid}(trial):plotEnd{vid}(trial));
                                end 
                            end 
                            if velWheelQ == 1 
                                Weta{1}(count1,:) = wDataFullTrace{vid}(plotStart{vid}(trial):plotEnd{vid}(trial));
                            end 
                            count1 = count1 + 1;                    
                        %if it is a 20 sec trial
                        elseif trialLengths{vid}(trial) == floor(20*FPSstack)
                            if CAQ == 1
                                Ceta{terminals(ccell)}{2}(count2,:) = cDataFullTrace{vid}{terminals(ccell)}(plotStart{vid}(trial):plotEnd{vid}(trial));
                            end 
                            if BBBQ == 1 
                                for BBBroi = 1:length(bDataFullTrace{1})
                                    Beta{BBBroi}{2}(count2,:) = bDataFullTrace{vid}{BBBroi}(plotStart{vid}(trial):plotEnd{vid}(trial));
                                end 
                            end 
                            if VWQ == 1
                                for VWroi = 1:length(vDataFullTrace{1})
                                    Veta{VWroi}{2}(count2,:) = vDataFullTrace{vid}{VWroi}(plotStart{vid}(trial):plotEnd{vid}(trial));
                                end 
                            end 
                            if velWheelQ == 1 
                                Weta{2}(count2,:) = wDataFullTrace{vid}(plotStart{vid}(trial):plotEnd{vid}(trial));
                            end 
                            count2 = count2 + 1;
                        end 
                    %if the red light is on 
                    elseif TrialTypes{vid}(trial,2) == 2
                        %if it is a 2 sec trial 
                        if trialLengths{vid}(trial) == floor(2*FPSstack)
                            if CAQ == 1
                                Ceta{terminals(ccell)}{3}(count3,:) = cDataFullTrace{vid}{terminals(ccell)}(plotStart{vid}(trial):plotEnd{vid}(trial));
                            end 
                            if BBBQ == 1 
                                for BBBroi = 1:length(bDataFullTrace{1})
                                    Beta{BBBroi}{3}(count3,:) = bDataFullTrace{vid}{BBBroi}(plotStart{vid}(trial):plotEnd{vid}(trial));
                                end 
                            end 
                            if VWQ == 1
                                for VWroi = 1:length(vDataFullTrace{1})
                                    Veta{VWroi}{3}(count3,:) = vDataFullTrace{vid}{VWroi}(plotStart{vid}(trial):plotEnd{vid}(trial));
                                end
                            end 
                            if velWheelQ == 1 
                                Weta{3}(count3,:) = wDataFullTrace{vid}(plotStart{vid}(trial):plotEnd{vid}(trial));
                            end 
                            count3 = count3 + 1;                    
                        %if it is a 20 sec trial
                        elseif trialLengths{vid}(trial) == floor(20*FPSstack)
                            if CAQ == 1
                                Ceta{terminals(ccell)}{4}(count4,:) = cDataFullTrace{vid}{terminals(ccell)}(plotStart{vid}(trial):plotEnd{vid}(trial));
                            end 
                            if BBBQ == 1 
                                for BBBroi = 1:length(bDataFullTrace{1})
                                    Beta{BBBroi}{4}(count4,:) = bDataFullTrace{vid}{BBBroi}(plotStart{vid}(trial):plotEnd{vid}(trial));
                                end 
                            end 
                            if VWQ == 1
                                for VWroi = 1:length(vDataFullTrace{1})
                                    Veta{VWroi}{4}(count4,:) = vDataFullTrace{vid}{VWroi}(plotStart{vid}(trial):plotEnd{vid}(trial));
                                end 
                            end 
                            if velWheelQ == 1 
                                Weta{4}(count4,:) = wDataFullTrace{vid}(plotStart{vid}(trial):plotEnd{vid}(trial));
                            end 
                            count4 = count4 + 1;
                        end             
                    end 
                end 
            end 
        end         
    end
end 

% remove rows that are all 0 and then add 100 to each trace to avoid
%negative going values 
for tType = 1:numTtypes
    if CAQ == 1
        for ccell = 1:length(terminals)    
            nonZeroRowsC = all(Ceta{terminals(ccell)}{tType} == 0,2);
            Ceta{terminals(ccell)}{tType}(nonZeroRowsC,:) = NaN;
            Ceta{terminals(ccell)}{tType} = Ceta{terminals(ccell)}{tType} + 100;
        end 
    end 
    if BBBQ == 1 
        for BBBroi = 1:length(bDataFullTrace{1})
            nonZeroRowsB = all(Beta{BBBroi}{tType} == 0,2);
            Beta{BBBroi}{tType}(nonZeroRowsB,:) = NaN;
            Beta{BBBroi}{tType} = Beta{BBBroi}{tType} + 100;
        end 
    end 
    if VWQ == 1
        for VWroi = 1:length(vDataFullTrace{1})
            nonZeroRowsV = all(Veta{VWroi}{tType} == 0,2);
            Veta{VWroi}{tType}(nonZeroRowsV,:) = NaN;
            Veta{VWroi}{tType} = Veta{VWroi}{tType} + 100;
        end 
    end 
    if velWheelQ == 1 
        nonZeroRowsW = all(Weta{tType} == 0,2);
        Weta{tType}(nonZeroRowsW,:) = NaN;
        Weta{tType} = Weta{tType} + 100;
    end 
end 
%}
%% baseline, smooth trial, and plot trial data 
% ADD IN LOGIC TO PLOT WHEEL VELOCITY DATA 
%{
%baseline data to average value between 0 sec and -2 sec (0 sec being stim
%onset) 
if CAQ == 1
    nCeta = cell(1,length(cDataFullTrace{1}));
end 
if BBBQ == 1 
    nBeta = cell(1,length(bDataFullTrace{1}));
end 
if VWQ == 1
    nVeta = cell(1,length(vDataFullTrace{1}));
end 
if velWheelQ == 1 
    nWeta = cell(1,numTtypes);
end 
if dataParseType == 0 %peristimulus data to plot 
    %sec_before_stim_start
    for tType = 1:numTtypes
        if CAQ == 1
            for ccell = 1:length(terminals)
                nCeta{terminals(ccell)}{tType} = (Ceta{terminals(ccell)}{tType} ./ mean(Ceta{terminals(ccell)}{tType}(:,floor((sec_before_stim_start-2)*FPSstack):floor(sec_before_stim_start*FPSstack)),2))*100; 
            end 
        end 
        if BBBQ == 1 
            for BBBroi = 1:length(bDataFullTrace{1})
                nBeta{BBBroi}{tType} = (Beta{BBBroi}{tType} ./ nanmean(Beta{BBBroi}{tType}(:,floor((sec_before_stim_start-2)*FPSstack):floor(sec_before_stim_start*FPSstack)),2))*100; 
            end 
        end 
        if VWQ == 1
            for VWroi = 1:length(vDataFullTrace{1})
                nVeta{VWroi}{tType} = (Veta{VWroi}{tType} ./ nanmean(Veta{VWroi}{tType}(:,floor((sec_before_stim_start-2)*FPSstack):floor(sec_before_stim_start*FPSstack)),2))*100;        
            end 
        end 
        if velWheelQ == 1 
             nWeta{tType} = (Weta{tType} ./ nanmean(Weta{tType}(:,floor((sec_before_stim_start-2)*FPSstack):floor(sec_before_stim_start*FPSstack)),2))*100; 
        end 
    end    
elseif dataParseType == 1 %only stimulus data to plot 
    if CAQ == 1
        nCeta = Ceta;
    end 
    if BBBQ == 1 
        nBeta = Beta;
    end 
    if VWQ == 1
        nVeta = Veta;
    end 
    if velWheelQ == 1 
        nWeta = Weta; 
    end 
end 

smoothQ =  input('Do you want to smooth your data? Yes = 1. No = 0. ');
if smoothQ ==  1
    filtTime = input('How many seconds do you want to smooth your data by? ');
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
    for tType = 1:numTtypes
        if CAQ == 1
            for ccell = 1:length(terminals)
                for cTrial = 1:size(nCeta{terminals(ccell)}{tType},1)
                    [sC_Data] = MovMeanSmoothData(nCeta{terminals(ccell)}{tType}(cTrial,:),filtTime,FPSstack);
                    nsCeta{terminals(ccell)}{tType}(cTrial,:) = sC_Data-100;
                end 
            end 
        end        
        if BBBQ == 1 
            for BBBroi = 1:length(bDataFullTrace{1})
                for bTrial = 1:size(nBeta{BBBroi}{tType},1)
                    [sB_Data] = MovMeanSmoothData(nBeta{BBBroi}{tType}(bTrial,:),filtTime,FPSstack);
                    nsBeta{BBBroi}{tType}(bTrial,:) = sB_Data-100;
                end 
            end 
        end 
        if VWQ == 1
            for VWroi = 1:length(vDataFullTrace{1})
                for vTrial = 1:size(nVeta{VWroi}{tType},1)
                    [sV_Data] = MovMeanSmoothData(nVeta{VWroi}{tType}(vTrial,:),filtTime,FPSstack);
                    nsVeta{VWroi}{tType}(vTrial,:) = sV_Data-100;   
                end 
            end 
        end 
        if velWheelQ == 1 
            for wTrial = 1:size(nWeta{tType},1)
                [sW_Data] = MovMeanSmoothData(nWeta{tType}(wTrial,:),filtTime,FPSstack);
                nsWeta{tType}(wTrial,:) = sW_Data-100;   
            end 
        end 
    end 
elseif smoothQ == 0
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
    for tType = 1:numTtypes
        if CAQ == 1
            for ccell = 1:length(terminals)
                for cTrial = 1:size(nCeta{terminals(ccell)}{tType},1)
                    nsCeta{terminals(ccell)}{tType}(cTrial,:) = nCeta{terminals(ccell)}{tType}(cTrial,:)-100;
                end 
            end 
        end        
        if BBBQ == 1 
            for BBBroi = 1:length(bDataFullTrace{1})
                for bTrial = 1:size(nBeta{BBBroi}{tType},1)
                    nsBeta{BBBroi}{tType}(bTrial,:) = nBeta{BBBroi}{tType}(bTrial,:)-100;
                end 
            end 
        end 
        if VWQ == 1
            for VWroi = 1:length(vDataFullTrace{1})
                for vTrial = 1:size(nVeta{VWroi}{tType},1)
                    nsVeta{VWroi}{tType}(vTrial,:) = nVeta{VWroi}{tType}(vTrial,:)-100;   
                end 
            end 
        end 
        if velWheelQ == 1 
            for wTrial = 1:size(nWeta{tType},1)
                nsWeta{tType}(wTrial,:) = nWeta{tType}(wTrial,:)-100;   
            end 
        end 
    end 
end 

%% set paramaters for plotting 
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
BBBpQ = input('Input 1 if you want to plot BBB data. Input 0 otherwise.');
if AVQ == 0 
    if BBBpQ == 1
        BBBroi = input('What BBB ROI data do you want to plot? ');
    end 
end 
CApQ = input('Input 1 if you want to plot calcium data. Input 0 otherwise.');
if AVQ == 0 
    if CApQ == 1 
        allTermQ = input('Input 1 to plot all the calcium terminals. Input 0 otherwise. ');    
        if allTermQ == 1
            termList = 1:length(terminals);
        elseif allTermQ == 0
            Term = input('What terminal do you want to plot? ');
            termList = find(terminals == Term); 
        end 
    end 
end 
VWpQ = input('Input 1 if you want to plot vessel width data. Input 0 otherwise.');
if AVQ == 0 
    if VWpQ == 1
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
        for Btrial = 1:size(nsBeta{BBBroi}{redTrialTtypeInds(tType)},1)
            allRedNSbETA{BBBroi}{3}(countB,:) = nsBeta{BBBroi}{redTrialTtypeInds(tType)}(Btrial,1:size(nsBeta{BBBroi}{redTrialTtypeInds(1)},2));
            countB = countB + 1;
        end 
        for Vtrial = 1:size(nsVeta{VWroi}{redTrialTtypeInds(tType)},1)
            allRedNSvETA{VWroi}{3}(countV,:) = nsVeta{VWroi}{redTrialTtypeInds(tType)}(Vtrial,1:size(nsVeta{VWroi}{redTrialTtypeInds(1)},2));
            countV = countV + 1;
        end         
    end 
    clearvars nsCeta nsBeta nsVeta
    nsCeta = allRedNScETA; nsBeta = allRedNSbETA; nsVeta = allRedNSvETA;
end 

% plot 
if AVQ == 0 
    if RedAVQ == 0 && CApQ == 0 
        termList = 1; 
    end 
    if RedAVQ == 1 && CApQ == 0 
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
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*1:Frames_post_stim_start)/FPSstack)+1);
                FrameVals = floor((1:FPSstack*1:Frames)-1); 
            elseif tType == 2 || tType == 4 
                Frames = size(nsBeta{BBBroi}{tType},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*1:Frames_post_stim_start)/FPSstack)+10);
                FrameVals = floor((1:FPSstack*1:Frames)-1); 
            end 
            if BBBpQ == 1 
                plot(AVbData{BBBroi}{tType},'r','LineWidth',3)
                patch([x fliplr(x)],[CI_bLow{BBBroi}{tType} fliplr(CI_bHigh{BBBroi}{tType})],[0.5 0 0],'EdgeColor','none')
            end 
            if CApQ == 1 
                plot(AVcData{terminals(ccell)}{tType},'b','LineWidth',3)
                patch([x fliplr(x)],[CI_cLow{terminals(ccell)}{tType} fliplr(CI_cHigh{terminals(ccell)}{tType})],[0 0 0.5],'EdgeColor','none')
            end 
            if VWpQ == 1
                plot(AVvData{VWroi}{tType},'k','LineWidth',3)
                patch([x fliplr(x)],[CI_vLow{VWroi}{tType} fliplr(CI_vHigh{VWroi}{tType})],'k','EdgeColor','none')            
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
            ax.FontName = 'Times';
%                 xLimStart = 17.8*FPSstack;
%                 xLimEnd = 22*FPSstack;
            xlim([1 length(AVbData{BBBroi}{tType})])
%                 xlim([xLimStart xLimEnd])
            ylim([-100 100])
            xlabel('time (s)')
            ylabel('percent change')
            % initialize empty string array 
            label = strings;
            if BBBpQ == 1
                label = append(label,sprintf('BBB ROI %d',BBBroi)); 
            end 
            if CApQ == 1 
                label = append(label,sprintf('  Ca ROI %d',terminals(ccell)));
            end 
            if VWpQ == 1
                label = append(label,sprintf('Vessel width ROI %d',VWroi));
            end 
            title({'Optogenetic Stimulation';'Event Triggered Averages';label},'FontName','Times');
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
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*1:Frames_post_stim_start)/FPSstack)+1);
                FrameVals = floor((1:FPSstack*1:Frames)-1); 
            elseif tType == 2 || tType == 4 
                Frames = size(nsBeta{1}{tType},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*1:Frames_post_stim_start)/FPSstack)+10);
                FrameVals = floor((1:FPSstack*1:Frames)-1); 
            end 
            if BBBpQ == 1 
                plot(AVbData{1}{tType},'r','LineWidth',3)
                patch([x fliplr(x)],[CI_bLow{1}{tType} fliplr(CI_bHigh{1}{tType})],[0.5 0 0],'EdgeColor','none')
            end 
            if CApQ == 1 
                plot(AVcData{1}{tType},'b','LineWidth',3)
                patch([x fliplr(x)],[CI_cLow{1}{tType} fliplr(CI_cHigh{1}{tType})],[0 0 0.5],'EdgeColor','none')
            end 
            if VWpQ == 1
                plot(AVvData{1}{tType},'k','LineWidth',3)
                patch([x fliplr(x)],[CI_vLow{1}{tType} fliplr(CI_vHigh{1}{tType})],'k','EdgeColor','none')            
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
            ax.FontName = 'Times';
%                 xLimStart = 18*FPSstack;
%                 xLimEnd = 32*FPSstack;
            xlim([1 length(AVbData{1}{tType})])
%                 xlim([xLimStart xLimEnd])
            ylim([-100 100])
            xlabel('time (s)')
            ylabel('percent change')
            % initialize empty string array 
            label = strings;
            if BBBpQ == 1
                label = append(label,'BBB ROIs averaged'); 
            end 
            if CApQ == 1 
                label = append(label,'  Ca ROIs averaged');
            end 
            if VWpQ == 1
                label = append(label,'Vessel width ROIs averaged ');
            end 
            title({'Optogenetic Stimulation';'Event Triggered Averages';label},'FontName','Times');
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
%% plot event triggered averages per terminal (trials staggered) 
%NEEDS TO BE EDITED FOR THE NEW VARIABLE NAMES/ORGANIZATION 
%{
for term = 1:length(Data)
    AVdata = cell(1,length(Data{1}));
    SEMdata = cell(1,length(Data{1}));
    baselineEndFrame = floor(20*(FPSstack));
    for tType = 4%1:length(Data{1})      
        if isempty(Data{term}{tType}) == 0          
            AVdata{tType} = mean(sData{term}{tType},1);
            SEMdata{tType} = std(sData{term}{tType},1)/sqrt(size(Data{term}{tType},1));
            figure;             
            hold all;
            if tType == 1 || tType == 3 
                Frames = size(Data{term}{tType},2);        
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+1);
                FrameVals = floor((1:FPSstack*2:Frames)-1); 
            elseif tType == 2 || tType == 4 
                Frames = size(Data{term}{tType},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+10);
                FrameVals = floor((1:FPSstack*2:Frames)-1); 
            end 
            colorSet = varycolor(size(Data{term}{tType},1));
            yStagTerm = 300;
            trialList = cell(1,size(Data{term}{tType},1));
            for trial = 1:size(Data{term}{tType},1)
                plot(sData{term}{tType}(trial,:)+yStagTerm,'LineWidth',1,'Color',colorSet(trial,:),'LineWidth',1.5)
                yStagTerm = yStagTerm + 300;
                trialList{trial} = sprintf('trial %d',trial);
            end 
            if tType == 1 
                plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'b','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
        %                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
        %                 alpha(0.5)   
            elseif tType == 3 
                plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'r','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
        %                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
        %                 alpha(0.5)                       
            elseif tType == 2 
                plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'b','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
        %                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
        %                 alpha(0.5)   
            elseif tType == 4 
                plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'r','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
        %                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
        %                 alpha(0.5)  
            end
            ax=gca;
            ax.XTick = FrameVals;
            ax.XTickLabel = sec_TimeVals;
            ax.FontSize = 20;
            xlim([0 Frames])
            ylim([0 2500])
            xlabel('time (s)')
            if smoothQ == 1
                title(sprintf('Terminal #%d data smoothed by %0.2f sec',terminals(term),filtTime));
            elseif smoothQ == 0
                title(sprintf('Terminal #%d raw data',terminals(term)));
            end          
            legend(trialList)
        end 
    end 
end 
%}
%% plot event triggered averages of relevant terminals averaged together 
%NEEDS TO BE EDITED FOR THE NEW VARIABLE NAMES/ORGANIZATION 
%{
%define the terminals you want to average 
% terms = input('What terminals do you want to average? ');

termGdata = cell(1,length(Cdata{1}));
for tType = 1:length(Cdata{1}) 
    for term = 1:length(terms)
        ind = find(terminals == (terms(term)));
        if term == 1 
            termGdata{tType} = sCdata{ind}{tType};
        elseif term > 1
            termGdata{tType}(((term-1)*size(Cdata{ind}{tType},1))+1:term*size(Cdata{ind}{tType},1),:) = sCdata{ind}{tType};
        end          
    end 
end 

cAVdata = cell(1,length(Cdata{1}));
cSEMdata = cell(1,length(Cdata{1}));
bAVdata = cell(1,length(Cdata{1}));
bSEMdata = cell(1,length(Cdata{1}));
vAVdata = cell(1,length(Cdata{1}));
vSEMdata = cell(1,length(Cdata{1}));
baselineEndFrame = floor(20*(FPSstack));
for tType = 4%1:length(cData{1}) 
    cAVdata{tType} = nanmean(termGdata{tType},1);
    cSEMdata{tType} = std(termGdata{tType},1)/sqrt(size(termGdata{tType},1));    
    bAVdata{tType} = nanmean(sBdata{tType},1);
    bSEMdata{tType} = std(sBdata{tType},1)/sqrt(size(sBdata{tType},1));    
    vAVdata{tType} = nanmean(sVdata{tType},1);
    vSEMdata{tType} = std(sVdata{tType},1)/sqrt(size(sVdata{tType},1));
    
    figure;                 
    hold all;
    if tType == 1 || tType == 3 
        Frames = size(termGdata{tType},2);        
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+1);
        FrameVals = floor((1:FPSstack*2:Frames)-1); 
    elseif tType == 2 || tType == 4 
        Frames = size(termGdata{tType},2);
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+10);
        FrameVals = floor((1:FPSstack*2:Frames)-1); 
    end 
    if tType == 1 
        plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'b','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
%                 alpha(0.5)   
    elseif tType == 3 
        plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'r','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
%                 alpha(0.5)                       
    elseif tType == 2 
        plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'b','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
%                 alpha(0.5)   
    elseif tType == 4 
        plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'r','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
%                 alpha(0.5)  
    end
    for trial = 1:size(termGdata{tType},1)
        plot(termGdata{tType}(trial,:),'LineWidth',1)
    end 
    plot(cAVdata{tType},'k','LineWidth',3)
    ax=gca;
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;
    ax.FontSize = 20;
    xlim([0 Frames])
    ylim([-200 200])
    xlabel('time (s)')
    if smoothQ == 1
        title(sprintf('calcium data smoothed by %0.2f sec',filtTime));
    elseif smoothQ == 0
        title('raw calcium data');
    end 
end 

for tType = 4%1:length(cData{1}) 
    figure;                 
    hold all;
    if tType == 1 || tType == 3 
        Frames = size(termGdata{tType},2);        
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+1);
        FrameVals = floor((1:FPSstack*2:Frames)-1); 
    elseif tType == 2 || tType == 4 
        Frames = size(termGdata{tType},2);
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+10);
        FrameVals = floor((1:FPSstack*2:Frames)-1); 
    end 
    if tType == 1 
        plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'b','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
%                 alpha(0.5)   
    elseif tType == 3 
        plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'r','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
%                 alpha(0.5)                       
    elseif tType == 2 
        plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'b','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
%                 alpha(0.5)   
    elseif tType == 4 
        plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'r','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
%                 alpha(0.5)  
    end
    for trial = 1:size(sBdata{tType},1)
        plot(sBdata{tType}(trial,:),'LineWidth',1)
    end 
    plot(bAVdata{tType},'k','LineWidth',3)
    ax=gca;
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;
    ax.FontSize = 20;
    xlim([0 Frames])
    ylim([-3 3])
    xlabel('time (s)')
    if smoothQ == 1
        title(sprintf('BBB data smoothed by %0.2f sec',filtTime));
    elseif smoothQ == 0
        title('raw BBB data');
    end 
end 

for tType = 4%1:length(cData{1}) 
    figure;                 
    hold all;
    if tType == 1 || tType == 3 
        Frames = size(termGdata{tType},2);        
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+1);
        FrameVals = floor((1:FPSstack*2:Frames)-1); 
    elseif tType == 2 || tType == 4 
        Frames = size(termGdata{tType},2);
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+10);
        FrameVals = floor((1:FPSstack*2:Frames)-1); 
    end 
    if tType == 1 
        plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'b','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
%                 alpha(0.5)   
    elseif tType == 3 
        plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'r','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
%                 alpha(0.5)                       
    elseif tType == 2 
        plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'b','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
%                 alpha(0.5)   
    elseif tType == 4 
        plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'r','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
%                 alpha(0.5)  
    end
    for trial = 1:size(sVdata{tType},1)
        plot(sVdata{tType}(trial,:),'LineWidth',1)
    end 
    plot(vAVdata{tType},'k','LineWidth',3)
    ax=gca;
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;
    ax.FontSize = 20;
    xlim([0 Frames])
    ylim([-3 3])
    xlabel('time (s)')
    if smoothQ == 1
        title(sprintf('vessel width smoothed by %0.2f sec',filtTime));
    elseif smoothQ == 0
        title('raw vessel width');
    end 
end 

%}
%% compare terminal calcium activity - create correlograms
%{
AVdata = cell(1,length(Cdata));
for term = 1:length(Cdata)
    for tType = 1:length(Cdata{1})      
        AVdata{term}{tType} = mean(sCdata{term}{tType},1);
    end 
end 

dataQ = input('Input 0 if you want to compare the entire TS. Input 1 if you want to compare stim period data. Input 2 if you want to compare baseline period data.');
if dataQ == 0 
    corData = cell(1,length(Cdata{1}));
    corAVdata = cell(1,length(Cdata{1}));
    for tType = 1:length(Cdata{1})    
       for term1 = 1:length(Cdata)
           for term2 = 1:length(Cdata)
               for trial = 1:size(Cdata{1}{tType},1)
                   corData{tType}{trial}(term1,term2) = corr2(sCdata{term1}{tType}(trial,:),sCdata{term2}{tType}(trial,:));                  
               end 
               corAVdata{tType}(term1,term2) = corr2(AVdata{term1}{tType},AVdata{term2}{tType});
           end 
       end 
    end 
elseif dataQ == 1 
    corData = cell(1,length(Cdata{1}));
    corAVdata = cell(1,length(Cdata{1}));
    for tType = 1:length(Cdata{1})    
       for term1 = 1:length(Cdata)
           for term2 = 1:length(Cdata)
               stimOnFrame = floor(FPSstack*20);
               if tType == 1 || tType == 3 
                   stimOffFrame = stimOnFrame + floor(FPSstack*20);
               elseif tType == 2 || tType == 4
                   stimOffFrame = stimOnFrame + floor(FPSstack*2);
               end 
               for trial = 1:size(Cdata{1}{tType},1)
                   corData{tType}{trial}(term1,term2) = corr2(sCdata{term1}{tType}(trial,stimOnFrame:stimOffFrame),sCdata{term2}{tType}(trial,stimOnFrame:stimOffFrame));
               end 
               corAVdata{tType}(term1,term2) = corr2(AVdata{term1}{tType}(stimOnFrame:stimOffFrame),AVdata{term2}{tType}(stimOnFrame:stimOffFrame));
           end 
       end 
    end 
elseif dataQ == 2
    corData = cell(1,length(Cdata{1}));
    corAVdata = cell(1,length(Cdata{1}));
    for tType = 1:length(Cdata{1})    
       for term1 = 1:length(Cdata)
           for term2 = 1:length(Cdata)
               baselineEndFrame = floor(FPSstack*20);
               for trial = 1:size(Cdata{1}{tType},1)
                   corData{tType}{trial}(term1,term2) = corr2(sCdata{term1}{tType}(trial,1:baselineEndFrame),sCdata{term2}{tType}(trial,1:baselineEndFrame));
               end 
               corAVdata{tType}(term1,term2) = corr2(AVdata{term1}{tType}(1:baselineEndFrame),AVdata{term2}{tType}(1:baselineEndFrame));
           end 
       end 
    end 
end 

% plot cross correlelograms 
for tType = 1:length(Cdata{1})
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
   for trial = 1:size(Cdata{1}{tType},1)
       subplot(2,4,trial)
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
%% calcium peak raster plots 
%{
Len1_3 = length(sCdata{1}{1});
Len2_4 = length(sCdata{1}{2});

% peaks = cell(1,length(Data));
locs = cell(1,length(Cdata));
stdTrace = cell(1,length(Cdata));
sigPeaks = cell(1,length(Cdata));
sigPeakLocs = cell(1,length(Cdata));
clear raster raster2 raster3 
for term = 1:length(Cdata)
    for tType = 1:length(Cdata{1})   
        for trial = 1:size(Cdata{term}{tType},1)
            %identify where the peaks are 
            [peak, loc] = findpeaks(sCdata{term}{tType}(trial,:),'MinPeakProminence',0.1,'MinPeakWidth',2); %0.6,0.8,0.9,1
            peaks{term}{tType}{trial} = peak;
            locs{term}{tType}{trial} = loc;
            stdTrace{term}(trial,tType) = std(sCdata{term}{tType}(trial,:));
            count = 1;
            if isempty(peaks{term}{tType}{trial}) == 0 
                for ind = 1:length(peaks{term}{tType}{trial})
                    if peaks{term}{tType}{trial}(ind) > stdTrace{term}(trial,tType)*2
                        sigPeakLocs{term}{tType}{trial}(count) = locs{term}{tType}{trial}(ind);
                        sigPeaks{term}{tType}{trial}(count) = peaks{term}{tType}{trial}(ind);                   
                        %create raster plot by binarizing data                      
                        raster2{term}{tType}(trial,sigPeakLocs{term}{tType}{trial}(count)) = 1;
                       count = count + 1;
                    end                
                end 
            end 
        end 
    end 
end 

for term = 1:length(peaks)
%     figure;
    for tType = 1:length(raster2{term})   
        for trial = 1:size(peaks{term}{tType},1)
            if isempty(peaks{term}{tType}{trial}) == 0
                raster2{term}{tType} = ~raster2{term}{tType};
                %make raster plot larger/easier to look at 
                RowMultFactor = 10;
                ColMultFactor = 1;
                raster3{term}{tType} = repelem(raster2{term}{tType},RowMultFactor,ColMultFactor);
                raster{term}{tType} = repelem(raster2{term}{tType},RowMultFactor,ColMultFactor);
                %make rasters the correct length  
                if tType == 1 || tType == 3
                    raster{term}{tType}(:,length(raster3{term}{tType})+1:Len1_3) = 1;
                elseif tType == 2 || tType == 4   
                    raster{term}{tType}(:,length(raster3{term}{tType})+1:Len2_4) = 1;
                end 
%        
%                 %create image 
%                 subplot(2,2,tType)
%                 imshow(raster{term}{tType})
%                 hold all 
%                 stimStartF = floor(FPSstack*20);
%                 if tType == 1 || tType == 3
%                     stimStopF = stimStartF + floor(FPSstack*2);           
%                     Frames = size(raster{term}{tType},2);        
%                     Frames_pre_stim_start = -((Frames-1)/2); 
%                     Frames_post_stim_start = (Frames-1)/2; 
%                     sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*4:Frames_post_stim_start)/FPSstack)+1);
%                     FrameVals = floor((1:FPSstack*4:Frames)-1);            
%                 elseif tType == 2 || tType == 4       
%                     stimStopF = stimStartF + floor(FPSstack*20);            
%                     Frames = size(raster{term}{tType},2);        
%                     Frames_pre_stim_start = -((Frames-1)/2); 
%                     Frames_post_stim_start = (Frames-1)/2; 
%                     sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*4:Frames_post_stim_start)/FPSstack)+10);
%                     FrameVals = floor((1:FPSstack*4:Frames)-1);
%                 end 
%                 if tType == 1 || tType == 2
%                 plot([stimStartF stimStartF], [0 size(raster{term}{tType},1)], 'b','LineWidth',2)
%                 plot([stimStopF stimStopF], [0 size(raster{term}{tType},1)], 'b','LineWidth',2)
%                 elseif tType == 3 || tType == 4
%                 plot([stimStartF stimStartF], [0 size(raster{term}{tType},1)], 'r','LineWidth',2)
%                 plot([stimStopF stimStopF], [0 size(raster{term}{tType},1)], 'r','LineWidth',2)
%                 end 
%         
%                 ax=gca;
%                 axis on 
%                 xticks(FrameVals)
%                 ax.XTickLabel = sec_TimeVals;
%                 yticks(5:10:size(raster{term}{tType},1)-5)
%                 ax.YTickLabel = ([]);
%                 ax.FontSize = 15;
%                 xlabel('time (s)')
%                 ylabel('trial')
%                 sgtitle(sprintf('Terminal %d',terminals(term)))
            end 
        end 
    end 
end 

%
 %create raster for all terminals stacked 
for term = 1:length(Cdata)
    for tType = 1:length(raster2{term})  
        curRowSize = size(raster{term}{tType},1);
        if curRowSize < size(sCdata{term}{tType},1)*RowMultFactor 
            raster{term}{tType}(curRowSize+1:size(sCdata{term}{tType},1)*RowMultFactor,:) = 1;
        end    
    end 
end 

clear fullRaster
fullRaster = cell(1,length(Cdata{1}));
for term = 1:length(Cdata)
    for tType = 1:length(raster2{term})
        rowLen = size(raster{term}{tType},1);
        
        if term == 1
            fullRaster{tType} = raster{term}{tType};
        elseif term > 1
            fullRaster{tType}(((term-1)*rowLen)+1:term*rowLen,:) = raster{term}{tType};
        end 
    end 
%     %create image 
%     subplot(2,2,tType)
%     imshow(fullRaster{tType})
%     hold all 
%     stimStartF = floor(FPSstack*20);
%     if tType == 1 || tType == 3
%         stimStopF = stimStartF + floor(FPSstack*2);           
%         Frames = size(fullRaster{tType},2);        
%         Frames_pre_stim_start = -((Frames-1)/2); 
%         Frames_post_stim_start = (Frames-1)/2; 
%         sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*4:Frames_post_stim_start)/FPSstack)+1);
%         FrameVals = floor((1:FPSstack*4:Frames)-1);            
%     elseif tType == 2 || tType == 4       
%         stimStopF = stimStartF + floor(FPSstack*20);            
%         Frames = size(fullRaster{tType},2);        
%         Frames_pre_stim_start = -((Frames-1)/2); 
%         Frames_post_stim_start = (Frames-1)/2; 
%         sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*4:Frames_post_stim_start)/FPSstack)+10);
%         FrameVals = floor((1:FPSstack*4:Frames)-1);
%     end 
%     if tType == 1 || tType == 2
%     plot([stimStartF stimStartF], [0 size(fullRaster{tType},1)], 'b','LineWidth',2)
%     plot([stimStopF stimStopF], [0 size(fullRaster{tType},1)], 'b','LineWidth',2)
%     elseif tType == 3 || tType == 4
%     plot([stimStartF stimStartF], [0 size(fullRaster{tType},1)], 'r','LineWidth',2)
%     plot([stimStopF stimStopF], [0 size(fullRaster{tType},1)], 'r','LineWidth',2)
%     end 
% 
%     ax=gca;
%     axis on 
%     xticks(FrameVals)
%     ax.XTickLabel = sec_TimeVals;
%     yticks(5:10:size(fullRaster{tType},1)-5)
%     ax.YTickLabel = ([]);
%     ax.FontSize = 10;
%     xlabel('time (s)')
%     ylabel('trial')
%     sgtitle(sprintf('Terminal %d',terminals(term)))
end
%}
%% plot peak rate per every n seconds 
%{
winSec = input('How many seconds do you want to know the calcium peak rate? '); 
winFrames = floor(winSec*FPSstack);
numPeaks = cell(1,length(Cdata));
avTermNumPeaks = cell(1,length(Cdata));
%     figure

for term = 1:length(Cdata)
    for tType = 1:length(raster2{term})
        windows = ceil(length(raster2{term}{tType})/winFrames);
        for win = 1:windows
            if win == 1 
                numPeaks{term}{tType}(:,win) = sum(~raster2{term}{tType}(:,1:winFrames),2);
            elseif win > 1 
                if ((win-1)*winFrames)+1 < length(raster2{term}{tType}) && winFrames*win < length(raster2{term}{tType})
                    numPeaks{term}{tType}(:,win) = sum(~raster2{term}{tType}(:,((win-1)*winFrames)+1:winFrames*win),2);
                end 
            end 
            avTermNumPeaks{term}{tType} = nanmean(numPeaks{term}{tType},1);
        end
        %create raster plots per terminal
        %{
        subplot(2,2,tType)
        hold all 
        stimStartF = floor((FPSstack*20)/winFrames);
        if tType == 1 || tType == 3
            stimStopF = stimStartF + floor((FPSstack*2)/winFrames);           
            Frames = size(avTermNumPeaks{term}{tType},2);        
            sec_TimeVals = (0:winSec*2:winSec*Frames)-20;
            FrameVals = (0:2:Frames);            
        elseif tType == 2 || tType == 4       
            stimStopF = stimStartF + floor((FPSstack*20)/winFrames);            
            Frames = size(avTermNumPeaks{term}{tType},2);        
            sec_TimeVals = (1:winSec*2:winSec*(Frames+1))-21;
            FrameVals = (0:2:Frames);
        end 
        if tType == 1 || tType == 2
        plot([stimStartF stimStartF], [-20 20], 'b','LineWidth',2)
        plot([stimStopF stimStopF], [-20 20], 'b','LineWidth',2)
        elseif tType == 3 || tType == 4
        plot([stimStartF stimStartF], [-20 20], 'r','LineWidth',2)
        plot([stimStopF stimStopF], [-20 20], 'r','LineWidth',2)
        end 
        for trial = 1:size(numPeaks{term}{tType},1)
            plot(numPeaks{term}{tType}(trial,:))
        end 
        plot(avTermNumPeaks{term}{tType},'k','LineWidth',2)

        ax=gca;
        axis on 
        xticks(FrameVals)
        ax.XTickLabel = sec_TimeVals;
%         yticks(5:10:size(avTermNumPeaks{term}{tType},1)-5)
%         ax.YTickLabel = ([]);
        ax.FontSize = 10;
        xlabel('time (s)')
        ylabel('trial')
        xlim([1 length(avTermNumPeaks{term}{tType})])
        ylim([-1 5])
        mtitle = sprintf('Number of calcium peaks. Terminal %d.',terminals(term));
        sgtitle(mtitle);
        %}
    end 
end 

allTermAvPeakNums = cell(1,length(Cdata{1}));
for term = 1:length(Cdata)
    for tType = 1:length(raster2{term})
        colNum = floor(length(sCdata{term}{tType})/winFrames); 
        if length(avTermNumPeaks{term}{tType}) < colNum
            avTermNumPeaks{term}{tType}(length(avTermNumPeaks{term}{tType})+1:colNum) = 0;
        end 
        allTermAvPeakNums{tType}(term,:) = avTermNumPeaks{term}{tType};
    end 
end 

%plot num peaks for all terminals (terminal traces overlaid)
%{
fig = figure;
for term = 3%1:length(Cdata)   
    for tType = 1:length(Cdata{1})
        subplot(2,2,tType)
        hold all 
        stimStartF = floor((FPSstack*20)/winFrames);
        if tType == 1 || tType == 3
            stimStopF = stimStartF + floor((FPSstack*2)/winFrames);           
            Frames = size(allTermAvPeakNums{tType},2);        
            sec_TimeVals = (0:winSec*2:winSec*Frames)-20;
            FrameVals = (0:2:Frames);            
        elseif tType == 2 || tType == 4       
            stimStopF = stimStartF + floor((FPSstack*20)/winFrames);            
            Frames = size(allTermAvPeakNums{tType},2);        
            sec_TimeVals = (1:winSec*2:winSec*(Frames+1))-21;
            FrameVals = (0:2:Frames);
        end 
        colorSet = varycolor(length(Cdata));
%         for term = 1:length(Cdata)
            plot(allTermAvPeakNums{tType}(term,:),'Color',colorSet(term,:),'LineWidth',1.5)
%         end 
%         plot(mean(allTermAvPeakNums{tType}),'Color','k','LineWidth',2)
    %     for col = 1:length(allTermAvPeakNums{tType})
    %         scatter(linspace(col,col,size(allTermAvPeakNums{tType},1)),allTermAvPeakNums{tType}(:,col))
    %     end 
        if tType == 1 || tType == 2
%             plot([stimStartF stimStartF], [-20 20], 'b','LineWidth',2)
%             plot([stimStopF stimStopF], [-20 20], 'b','LineWidth',2)
        elseif tType == 3 || tType == 4
%             plot([stimStartF stimStartF], [-20 20], 'r','LineWidth',2)
%             plot([stimStopF stimStopF], [-20 20], 'r','LineWidth',2)
        end 
        ax=gca;
        axis on 
%         xticks(FrameVals)
%         ax.XTickLabel = sec_TimeVals;
    %         yticks(5:10:size(avTermNumPeaks{term}{tType},1)-5)
    %         ax.YTickLabel = ([]);
        ax.FontSize = 10;
        xlabel('time (s)')
        ylabel('number of peaks')
        xlim([0 length(avTermNumPeaks{term}{tType})])
        ylim([-1 2])
%         label = sprintf('Number of calcium peaks. Terminal %d.',terminals(term));
        label = 'Number of calcium peaks';
        sgtitle(label);
%         legend('terminal 13','terminal 20','terminal 12','terminal 16','terminal 11','terminal 15','terminal 10','terminal 8','terminal 9','terminal 7','terminal 4','Location','EastOutside')
    end 
    set(fig,'position', [500 100 1800 800])
%     dir = sprintf('D:/70kD_RhoB/DAT-Chrimson-GCaMP/SF56_20190718/figures/CaPeakPSTHs/DAterminal%d_PSTH.tif',terminals(term));  
    dir = 'D:/70kD_RhoB/DAT-Chrimson-GCaMP/SF56_20190718/figures/CaPeakPSTHs/DAtermPSTHs.tif'; 
%     export_fig(dir)
end 
%}

%plot num peaks for all terminals (terminal traces stacked - not overlaid)
%{
figure;
for tType = 1:length(Cdata{1})
    subplot(2,2,tType)
    hold all 
    stimStartF = floor((FPSstack*20)/winFrames);
    if tType == 1 || tType == 3
        stimStopF = stimStartF + floor((FPSstack*2)/winFrames);           
        Frames = size(allTermAvPeakNums{tType},2);        
        sec_TimeVals = (0:winSec*2:winSec*Frames)-20;
        FrameVals = (0:2:Frames);            
    elseif tType == 2 || tType == 4       
        stimStopF = stimStartF + floor((FPSstack*20)/winFrames);            
        Frames = size(allTermAvPeakNums{tType},2);        
        sec_TimeVals = (1:winSec*2:winSec*(Frames+1))-21;
        FrameVals = (0:2:Frames);
    end 
    colorSet = varycolor(length(Cdata));
    yStagTerm = 0.7;
    for term = 1:length(Cdata)
        plot(allTermAvPeakNums{tType}(term,:)+yStagTerm,'Color',colorSet(term,:),'LineWidth',1.5)
        yStagTerm = yStagTerm + 0.7;
    end 
%     plot(mean(allTermAvPeakNums{tType}),'Color','k','LineWidth',2)
%     plot(allTermAvPeakNums{tType},'Color','k')
%     for col = 1:length(allTermAvPeakNums{tType})
%         scatter(linspace(col,col,size(allTermAvPeakNums{tType},1)),allTermAvPeakNums{tType}(:,col))
%     end 
    if tType == 1 || tType == 2
        plot([stimStartF stimStartF], [-20 20], 'b','LineWidth',2)
        plot([stimStopF stimStopF], [-20 20], 'b','LineWidth',2)
    elseif tType == 3 || tType == 4
        plot([stimStartF stimStartF], [-20 20], 'r','LineWidth',2)
        plot([stimStopF stimStopF], [-20 20], 'r','LineWidth',2)
    end 
    ax=gca;
    axis on 
    xticks(FrameVals)
    ax.XTickLabel = sec_TimeVals;
%         yticks(5:10:size(avTermNumPeaks{term}{tType},1)-5)
%         ax.YTickLabel = ([]);
    ax.FontSize = 10;
    xlabel('time (s)')
    ylabel('number of peaks')
    xlim([0 length(avTermNumPeaks{term}{tType})])
    ylim([0 8.5])
    sgtitle('Number of calcium peaks per terminal');
    legend('terminal 17','terminal 15','terminal 12','terminal 10','terminal 8','terminal 7','terminal 6','terminal 5','terminal 4','terminal 3')
end 
%}

%plot histogram of num peaks for all terminals
%THIS IS NOT COMPLETE 
%{
fig = figure;
for term = 3%1:length(Cdata)   
    for tType = 1:length(Cdata{1})
        subplot(2,2,tType)
        hold all 
        stimStartF = floor((FPSstack*20)/winFrames);
        if tType == 1 || tType == 3
            stimStopF = stimStartF + floor((FPSstack*2)/winFrames);           
            Frames = size(allTermAvPeakNums{tType},2);        
            sec_TimeVals = (0:winSec*2:winSec*Frames)-20;
            FrameVals = (0:2:Frames);            
        elseif tType == 2 || tType == 4       
            stimStopF = stimStartF + floor((FPSstack*20)/winFrames);            
            Frames = size(allTermAvPeakNums{tType},2);        
            sec_TimeVals = (1:winSec*2:winSec*(Frames+1))-21;
            FrameVals = (0:2:Frames);
        end 
        data = allTermAvPeakNums{tType}(term,:);
        histogram(data,5)
        if tType == 1
            title('2 sec blue stim')
        elseif tType == 2
            title('20 sec blue stim')
        elseif tType == 3
            title('2 sec red stim')
        elseif tType == 4
            title('20 sec red stim')
        end 
        label = sprintf('Number of calcium peaks per %0.2f sec',winSec);
        sgtitle(label);
%         legend('terminal 13','terminal 20','terminal 12','terminal 16','terminal 11','terminal 15','terminal 10','terminal 8','terminal 9','terminal 7','terminal 4','Location','EastOutside')
    end 
    set(fig,'position', [500 100 1800 800])
%     dir = sprintf('D:/70kD_RhoB/DAT-Chrimson-GCaMP/SF56_20190718/figures/CaPeakPSTHs/DAterminal%d_PSTH.tif',terminals(term));  
    dir = 'D:/70kD_RhoB/DAT-Chrimson-GCaMP/SF56_20190718/figures/CaPeakPSTHs/DAtermPSTHs.tif'; 
%     export_fig(dir)
end 
%}

%}
%% find calcium peaks per terminal across entire experiment 
%{
if tTypeQ == 0 
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
elseif tTypeQ == 1
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
%% sort data based on ca peak location 
%{
windSize = input('How big should the window be around Ca peak in seconds?');
% windSize = 24; 
% windSize = 5;
if tTypeQ == 0 
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
                    for BBBroi = 1:length(bDataFullTrace{1})
                        sortedBdata{vid}{BBBroi}{terminals(ccell)}(peak,:) = bDataFullTrace{vid}{BBBroi}(start:stop);
                    end 
                    sortedCdata{vid}{terminals(ccell)}(peak,:) = cDataFullTrace{vid}{terminals(ccell)}(start:stop);
                    for VWroi = 1:length(vDataFullTrace{1})
                        sortedVdata{vid}{VWroi}{terminals(ccell)}(peak,:) = vDataFullTrace{vid}{VWroi}(start:stop);
                    end 
                end 
            end 
        end 
    end 
    %replace rows of all 0s w/NaNs
    for vid = 1:length(vidList)
        for ccell = 1:length(terminals)    
            for BBBroi = 1:length(bDataFullTrace{1})
                nonZeroRowsB = all(sortedBdata{vid}{BBBroi}{terminals(ccell)} == 0,2);
                sortedBdata{vid}{BBBroi}{terminals(ccell)}(nonZeroRowsB,:) = NaN;
            end 
            nonZeroRowsC = all(sortedCdata{vid}{terminals(ccell)} == 0,2);
            sortedCdata{vid}{terminals(ccell)}(nonZeroRowsC,:) = NaN;
            for VWroi = 1:length(vDataFullTrace{1})
                nonZeroRowsV = all(sortedVdata{vid}{VWroi}{terminals(ccell)} == 0,2);
                sortedVdata{vid}{VWroi}{terminals(ccell)}(nonZeroRowsV,:) = NaN;
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
                        for BBBroi = 1:length(bDataFullTrace{1})
                            sortedBdata{vid}{BBBroi}{terminals(ccell)}{per}(peak,:) = bDataFullTrace{vid}{BBBroi}(start:stop);
                        end 
                        sortedCdata{vid}{terminals(ccell)}{per}(peak,:) = cDataFullTrace{vid}{terminals(ccell)}(start:stop);
                        for VWroi = 1:length(vDataFullTrace{1})
                            sortedVdata{vid}{VWroi}{terminals(ccell)}{per}(peak,:) = vDataFullTrace{vid}{VWroi}(start:stop);
                        end 
                    end 
                end 
            end 
        end 
    end  
end 
%}
%% normalize to baseline period and plot calcium peak aligned data
%{
if tTypeQ == 0 
    %{
    %find where calcium peak onset is 
    changePt = 23;

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
     
    %normalize
    NsortedBdata = cell(1,length(vidList));
    NsortedCdata = cell(1,length(vidList));
    NsortedVdata = cell(1,length(vidList));
    sortedBdata2 = cell(1,length(vidList));
    sortedCdata2 = cell(1,length(vidList));
    sortedVdata2 = cell(1,length(vidList));
     for vid = 1:length(vidList)
        for ccell = 1:length(terminals)
            if isempty(sortedBdata{vid}{BBBroi}{terminals(ccell)}) == 0 

                %the data needs to be added to because there are some
                %negative gonig points which mess up the normalizing 
                for BBBroi = 1:length(bDataFullTrace{1})
                    sortedBdata2{vid}{BBBroi}{terminals(ccell)} = sortedBdata{vid}{BBBroi}{terminals(ccell)} + 100;
                end
                sortedCdata2{vid}{terminals(ccell)} = sortedCdata{vid}{terminals(ccell)} + 100;
                for VWroi = 1:length(vDataFullTrace{1})
                    sortedVdata2{vid}{VWroi}{terminals(ccell)} = sortedVdata{vid}{VWroi}{terminals(ccell)} + 100;
                end 

                %normalize to 0.5 sec before changePt (calcium peak
                %onset) BLstart 
                BLstart = changePt - floor(0.5*FPSstack);
                for BBBroi = 1:length(bDataFullTrace{1})
                    NsortedBdata{vid}{BBBroi}{terminals(ccell)} = ((sortedBdata2{vid}{BBBroi}{terminals(ccell)})./(nanmean(sortedBdata2{vid}{BBBroi}{terminals(ccell)}(:,BLstart:changePt),2)))*100;
                end 
                NsortedCdata{vid}{terminals(ccell)} = ((sortedCdata2{vid}{terminals(ccell)})./(nanmean(sortedCdata2{vid}{terminals(ccell)}(:,BLstart:changePt),2)))*100;
                for VWroi = 1:length(vDataFullTrace{1})
                    NsortedVdata{vid}{VWroi}{terminals(ccell)} = ((sortedVdata2{vid}{VWroi}{terminals(ccell)})./(nanmean(sortedVdata2{vid}{VWroi}{terminals(ccell)}(:,BLstart:changePt),2)))*100;
                end 
            end        
        end 
     end 
     
    %smoothing option
    smoothQ = 1;%input('Input 0 to plot non-smoothed data. Input 1 to plot smoothed data.');
    if smoothQ == 0 
%         SNavCdata = NavCdata;
%         SNavBdata = NavBdata;
%         SNavVdata = NavVdata;
    elseif smoothQ == 1
        filtTime = 0.7;%input('How many seconds do you want to smooth your data by? ');
        SNBdataPeaks = cell(1,length(vidList));
%         SNCdataPeaks = cell(1,length(vidList));
        SNVdataPeaks = cell(1,length(vidList));
        for vid = 1:length(vidList)
            for ccell = 1:length(terminals)
%                 [sC_Data] = MovMeanSmoothData(NsortedCdata{vid}{terminals(ccell)},filtTime,FPSstack);
%                 SNCdataPeaks{vid}{terminals(ccell)} = sC_Data; 
                for BBBroi = 1:length(bDataFullTrace{1})
                    [sB_Data] = MovMeanSmoothData(NsortedBdata{vid}{BBBroi}{terminals(ccell)},filtTime,FPSstack);
                    SNBdataPeaks{vid}{BBBroi}{terminals(ccell)} = sB_Data;
                end
                for VWroi = 1:length(vDataFullTrace{1})
                    [sV_Data] = MovMeanSmoothData(NsortedVdata{vid}{VWroi}{terminals(ccell)},filtTime,FPSstack);
                    SNVdataPeaks{vid}{VWroi}{terminals(ccell)} = sV_Data;
                end 
            end 
        end 
        SNCdataPeaks = NsortedCdata;
    end 
    %} 
elseif tTypeQ == 1 
    %{
    %find where calcium peak onset is 
%     changePt = (findchangepts(SNavCdata{terminals(ccell)}))-1;
    
    %normalize
    NsortedBdata = cell(1,length(vidList));
    NsortedCdata = cell(1,length(vidList));
    NsortedVdata = cell(1,length(vidList));
    sortedBdata2 = cell(1,length(vidList));
    sortedCdata2 = cell(1,length(vidList));
    sortedVdata2 = cell(1,length(vidList));
     for vid = 1:length(vidList)
        for ccell = 1:length(terminals)
            for per = 1:3   
                if isempty(sortedBdata{vid}{terminals(ccell)}{per}) == 0 
                    
                    %the data needs to be added to because there are some
                    %negative gonig points which mess up the normalizing 
                    sortedBdata2{vid}{terminals(ccell)}{per} = sortedBdata{vid}{terminals(ccell)}{per} + 100;
                    sortedCdata2{vid}{terminals(ccell)}{per} = sortedCdata{vid}{terminals(ccell)}{per} + 100;
                    sortedVdata2{vid}{terminals(ccell)}{per} = sortedVdata{vid}{terminals(ccell)}{per} + 100;
                     
                      %this normalizes to the first 1/3 section of the trace
                      %(18 frames) 
%{
%                     NsortedBdata{vid}{terminals(ccell)}{per} = ((sortedBdata2{vid}{terminals(ccell)}{per})./((nanmean(sortedBdata2{vid}{terminals(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3)),2))))*100;
%                     NsortedCdata{vid}{terminals(ccell)}{per} = ((sortedCdata2{vid}{terminals(ccell)}{per})./((nanmean(sortedCdata2{vid}{terminals(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3)),2))))*100;
%                     NsortedVdata{vid}{terminals(ccell)}{per} = ((sortedVdata2{vid}{terminals(ccell)}{per})./((nanmean(sortedVdata2{vid}{terminals(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3)),2))))*100;            
%}                     
                    %normalize to 0.5 sec before changePt (calcium peak
                    %onset) BLstart 
                    BLstart = changePt - floor(0.5*FPSstack);
                    NsortedBdata{vid}{terminals(ccell)}{per} = ((sortedBdata2{vid}{terminals(ccell)}{per})./(nanmean(sortedBdata2{vid}{terminals(ccell)}{per}(:,BLstart:changePt),2)))*100;
                    NsortedCdata{vid}{terminals(ccell)}{per} = ((sortedCdata2{vid}{terminals(ccell)}{per})./(nanmean(sortedCdata2{vid}{terminals(ccell)}{per}(:,BLstart:changePt),2)))*100;
                    NsortedVdata{vid}{terminals(ccell)}{per} = ((sortedVdata2{vid}{terminals(ccell)}{per})./(nanmean(sortedVdata2{vid}{terminals(ccell)}{per}(:,BLstart:changePt),2)))*100;

                end 
            end 
        end 
     end 
    
    smoothQ = input('Input 0 to plot non-smoothed data. Input 1 to plot smoothed data.');
    if smoothQ == 0 
        SNBdataPeaks = NsortedBdata;
        SNCdataPeaks = NsortedCdata;
        SNVdataPeaks = NsortedVdata;
    elseif smoothQ == 1
        filtTime = input('How many seconds do you want to smooth your data by? ');
        SNBdataPeaks = cell(1,length(vidList));
        SNCdataPeaks = cell(1,length(vidList));
        SNVdataPeaks = cell(1,length(vidList));
         for vid = 1:length(vidList)
            for ccell = 1:length(terminals)
                for per = 1:3   
                    if isempty(sortedBdata{vid}{terminals(ccell)}{per}) == 0 
                        for peak = 1:size(sortedBdata{vid}{terminals(ccell)}{per},1)
                            [SBPeak_Data] = MovMeanSmoothData(NsortedBdata{vid}{terminals(ccell)}{per}(peak,:),filtTime,FPSstack);
                            SNBdataPeaks{vid}{terminals(ccell)}{per}(peak,:) = SBPeak_Data;                            
                            [SCPeak_Data] = MovMeanSmoothData(NsortedCdata{vid}{terminals(ccell)}{per}(peak,:),filtTime,FPSstack);
                            SNCdataPeaks{vid}{terminals(ccell)}{per}(peak,:) = SCPeak_Data;                          
                            [SVPeak_Data] = MovMeanSmoothData(NsortedVdata{vid}{terminals(ccell)}{per}(peak,:),filtTime,FPSstack);
                            SNVdataPeaks{vid}{terminals(ccell)}{per}(peak,:) = SVPeak_Data;                            
                        end 
                    end 
                end 
            end 
         end        
    end  
    %}
end 
%}                     
%% plot calcium spike triggered averages 
%{
BBBQ = input('Input 1 if you want to plot BBB data. ');
if BBBQ == 1
    BBBroi = input('What BBB ROI do you want to plot? ');
end 
VWQ = input('Input 1 if you want to plot vessel width data. ');
if VWQ == 1
    VWroi = input('What vessel width ROI do you want to plot? ');
end 
saveQ = input('Input 1 to save the figures. Input 0 otherwise. ');
if saveQ == 1                
    dir1 = input('What folder are you saving these images in? ');
end 

if tTypeQ == 0 
    %{
    allCTraces = cell(1,length(SNCdataPeaks{1}));
    allBTraces = cell(1,length(SNCdataPeaks{1}));
    allVTraces = cell(1,length(SNCdataPeaks{1}));
    for ccell = 1:length(terminals)
        % plot 
        fig = figure;
        Frames = size(SNBdataPeaks{1}{BBBroi}{terminals(ccell)},2);
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack))+1;
        FrameVals = round((1:FPSstack:Frames))+5; 
        ax=gca;
        hold all
        count = 1;
        for vid = 1:length(vidList)      
            if isempty(sortedBdata{vid}{BBBroi}{terminals(ccell)}) == 0
                for peak = 1:size(SNCdataPeaks{vid}{terminals(ccell)},1)                    
                    allBTraces{BBBroi}{terminals(ccell)}(count,:) = (SNBdataPeaks{vid}{BBBroi}{terminals(ccell)}(peak,:)-100); 
                    allVTraces{VWroi}{terminals(ccell)}(count,:) = (SNVdataPeaks{vid}{VWroi}{terminals(ccell)}(peak,:)-100); 
                    allCTraces{terminals(ccell)}(count,:) = (SNCdataPeaks{vid}{terminals(ccell)}(peak,:)-100);
%                     plot(allCTraces{terminals(ccell)}(count,:),'b')
%                     plot(allBTraces{BBBroi}{terminals(ccell)}(count,:),'r')
                    count = count + 1;
                end 
            end
        end 
        
%         %randomly plot 100 calcium traces - no replacement: each trace can
%         %only be plotted once 
%         traceInds = randperm(332);
%         for peak = 1:100       
%             plot(allCTraces{terminals(ccell)}(traceInds(peak),:),'b')
%             
%         end 
        
%         
%         for peak = 1:size(allBTraces{terminals(ccell)})
%         end 
%         plot(allBTraces{terminals(ccell)}(countB,:))

        %DETERMINE 95% CI
        SEMb = (nanstd(allBTraces{BBBroi}{terminals(ccell)}))/(sqrt(size(allBTraces{BBBroi}{terminals(ccell)},1))); % Standard Error            
        ts_bLow = tinv(0.025,size(allBTraces{BBBroi}{terminals(ccell)},1)-1);% T-Score for 95% CI
        ts_bHigh = tinv(0.975,size(allBTraces{BBBroi}{terminals(ccell)},1)-1);% T-Score for 95% CI
        CI_bLow = (nanmean(allBTraces{BBBroi}{terminals(ccell)},1)) + (ts_bLow*SEMb);  % Confidence Intervals
        CI_bHigh = (nanmean(allBTraces{BBBroi}{terminals(ccell)},1)) + (ts_bHigh*SEMb);  % Confidence Intervals
        
        SEMc = (nanstd(allCTraces{terminals(ccell)}))/(sqrt(size(allCTraces{terminals(ccell)},1))); % Standard Error            
        ts_cLow = tinv(0.025,size(allCTraces{terminals(ccell)},1)-1);% T-Score for 95% CI
        ts_cHigh = tinv(0.975,size(allCTraces{terminals(ccell)},1)-1);% T-Score for 95% CI
        CI_cLow = (nanmean(allCTraces{terminals(ccell)},1)) + (ts_cLow*SEMc);  % Confidence Intervals
        CI_cHigh = (nanmean(allCTraces{terminals(ccell)},1)) + (ts_cHigh*SEMc);  % Confidence Intervals
        
        SEMv = (nanstd(allVTraces{VWroi}{terminals(ccell)}))/(sqrt(size(allVTraces{VWroi}{terminals(ccell)},1))); % Standard Error            
        ts_vLow = tinv(0.025,size(allVTraces{VWroi}{terminals(ccell)},1)-1);% T-Score for 95% CI
        ts_vHigh = tinv(0.975,size(allVTraces{VWroi}{terminals(ccell)},1)-1);% T-Score for 95% CI
        CI_vLow = (nanmean(allVTraces{VWroi}{terminals(ccell)},1)) + (ts_vLow*SEMv);  % Confidence Intervals
        CI_vHigh = (nanmean(allVTraces{VWroi}{terminals(ccell)},1)) + (ts_vHigh*SEMv);  % Confidence Intervals

        x = 1:length(CI_cLow);

        
        AVSNBdataPeaks{BBBroi}{terminals(ccell)} = (nanmean(allBTraces{BBBroi}{terminals(ccell)}));
        AVSNCdataPeaks{terminals(ccell)} = nanmean(allCTraces{terminals(ccell)});
        AVSNVdataPeaks{VWroi}{terminals(ccell)} = (nanmean(allVTraces{VWroi}{terminals(ccell)}));
        
        plot(AVSNCdataPeaks{terminals(ccell)},'b','LineWidth',4)
%         plot(AVSNBdataPeaks{BBBroi}{terminals(ccell)},'r','LineWidth',4)
        plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;   
        ax.FontSize = 25;
        ax.FontName = 'Times';
        xlabel('time (s)','FontName','Times')
        ylabel('calcium signal percent change','FontName','Times')
        xLimStart = floor(10*FPSstack);
        xLimEnd = floor(24*FPSstack); 
%         xlim([xLimStart xLimEnd])
%         xlim([1 xLimEnd])
        xlim([1 size(AVSNBdataPeaks{BBBroi}{terminals(ccell)},2)])
%         ylim([-1.25 2])
        ylim([-60 100])
%         legend('DA calcium','BBB data')
           
        
        patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],[0 0 0.5],'EdgeColor','none')
%         legend('BBB permeability','Calcium signal','Calcium peak onset','Location','northwest');

%         title(sprintf('DA terminal #%d. All light Conditions',terminals(ccell)))
%         title('BBB Permeability Spike Triggered Average','FontName','Times')
        set(fig,'position', [500 100 900 800])
        alpha(0.3)

        %add right y axis tick marks for a specific DOD figure. 
        yyaxis right 
        if BBBQ == 1
            plot(AVSNBdataPeaks{BBBroi}{terminals(ccell)},'r','LineWidth',4)
            patch([x fliplr(x)],[(CI_bLow) (fliplr(CI_bHigh))],[0.5 0 0],'EdgeColor','none')
            ylabel('BBB permeability percent change','FontName','Times')
            tlabel = sprintf('Terminal%d_BBBroi%d.',terminals(ccell),BBBroi);
            title(sprintf('Terminal %d. BBB ROI %d.',terminals(ccell),BBBroi))
%             title('BBB permeability Spike Triggered Average')
        end 
        if VWQ == 1
            plot(AVSNVdataPeaks{VWroi}{terminals(ccell)},'k','LineWidth',4)
            patch([x fliplr(x)],[(CI_vLow) (fliplr(CI_vHigh))],'k','EdgeColor','none')
            ylabel('Vessel width percent change','FontName','Times')
            tlabel = sprintf('Terminal%d_VwidthROI%d.',terminals(ccell),VWroi);
%             title(sprintf('Terminal %d. Vessel width ROI %d.',terminals(ccell),VWroi))
            title('Vessel Width Spike Triggered Average')
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
    %}
elseif tTypeQ == 1
    %{
    allBTraces = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
    allCTraces = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
    allVTraces = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
%     AVSNBdataPeaks = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
%     AVSNCdataPeaks = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
%     AVSNVdataPeaks = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
%     Btraces = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
%     Ctraces = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
%     Vtraces = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
    for ccell = 3%1:length(terminals)
        % plot    
        
        for per = 1:3
           fig = figure; 
            Frames = length(avSortedCdata{terminals(ccell)});
            Frames_pre_stim_start = -((Frames-1)/2); 
            Frames_post_stim_start = (Frames-1)/2; 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack))+1;
            FrameVals = round((1:FPSstack:Frames)+5); 
            ax=gca;
            hold all
            count = 1;
            for vid = 1:length(vidList)
                   if isempty(sortedBdata{vid}{terminals(ccell)}{per}) == 0 
                        for peak = 1:size(sortedBdata{vid}{terminals(ccell)}{per},1)
                            allBTraces{terminals(ccell)}{per}(count,:) = (SNBdataPeaks{vid}{terminals(ccell)}{per}(peak,:)-100);
                            allCTraces{terminals(ccell)}{per}(count,:) = (SNCdataPeaks{vid}{terminals(ccell)}{per}(peak,:)-100);
                            allVTraces{terminals(ccell)}{per}(count,:) = (SNVdataPeaks{vid}{terminals(ccell)}{per}(peak,:)-100);  
                            count = count + 1;
                        end 
                   end               
            end 
        
        
            %remove traces that are outliers 
            %{
            %statistically
            count2 = 1; 
            count3 = 1;
            count4 = 1;
            for peak = 1:size(allBTraces{terminals(ccell)}{per},1)
%                 if allBTraces{terminals(ccell)}(peak,:) < nanstd(allBTraces{terminals(ccell)},1)*3                  
                    Btraces{terminals(ccell)}{per}(count2,:) = (allBTraces{terminals(ccell)}{per}(peak,:))-100;
                    count2 = count2 + 1;
%                 end 
%                 if allCTraces{terminals(ccell)}(peak,:) < nanstd(allCTraces{terminals(ccell)},1)*3                    
                    Ctraces{terminals(ccell)}{per}(count3,:) = (allCTraces{terminals(ccell)}{per}(peak,:))-100;
                    count3 = count3 + 1;
%                 end 
%                 if allVTraces{terminals(ccell)}(peak,:) < nanstd(allVTraces{terminals(ccell)},1)*3%*0.000000000003                    
                    Vtraces{terminals(ccell)}{per}(count4,:) = (allVTraces{terminals(ccell)}{per}(peak,:))-100;
                    count4 = count4 + 1;
%                 end 
            end 
            
            %remove traces that are outliers by removing the trace with the lowest value
            
%             [BminVal,BminInd] = max(Btraces{terminals(ccell)}(:));
%             [Brow,~] = find(Btraces{terminals(ccell)} == BminVal);
%             Btraces{terminals(ccell)}(Brow,:) = [];
% 
%             [CminVal,CminInd] = min(Ctraces{terminals(ccell)}(:));
%             [Crow,~] = find(Ctraces{terminals(ccell)} == CminVal);
%             Ctraces{terminals(ccell)}(Crow,:) = [];
%             
%             [VminVal,VminInd] = min(Vtraces{terminals(ccell)}(:));
%             [Vrow,~] = find(Vtraces{terminals(ccell)} == VminVal);
%             Vtraces{terminals(ccell)}(Vrow,:) = [];
                

            
            %remove specific trace
%             Btraces{terminals(ccell)}(123,:) = [];
%}

            %calculate the 95% confidence interval
            %{
            SEMcSpont = (std(allCTraces{terminals(ccell)}{3}))/(sqrt(size(allCTraces{terminals(ccell)}{3},1))); % Standard Error            
            ts_cSpontLow = tinv(0.025,size(allCTraces{terminals(ccell)}{3},1)-1);% T-Score for 95% CI
            ts_cSpontHigh = tinv(0.975,size(allCTraces{terminals(ccell)}{3},1)-1);% T-Score for 95% CI
            CI_cSpontLow = (nanmean(allCTraces{terminals(ccell)}{3},1)) + (ts_cSpontLow*SEMcSpont);  % Confidence Intervals
            CI_cSpontHigh = (nanmean(allCTraces{terminals(ccell)}{3},1)) + (ts_cSpontHigh*SEMcSpont);  % Confidence Intervals
            
            SEMcBlue = (std(allCTraces{terminals(ccell)}{1}))/(sqrt(size(allCTraces{terminals(ccell)}{1},1))); % Standard Error            
            ts_cBlueLow = tinv(0.025,size(allCTraces{terminals(ccell)}{1},1)-1);% T-Score for 95% CI
            ts_cBlueHigh = tinv(0.975,size(allCTraces{terminals(ccell)}{1},1)-1);% T-Score for 95% CI
            CI_cBlueLow = (nanmean(allCTraces{terminals(ccell)}{1},1)) + (ts_cBlueLow*SEMcBlue);  % Confidence Intervals
            CI_cBlueHigh = (nanmean(allCTraces{terminals(ccell)}{1},1)) + (ts_cBlueHigh*SEMcBlue);  % Confidence Intervals
            
            SEMcRed = (std(allCTraces{terminals(ccell)}{2}))/(sqrt(size(allCTraces{terminals(ccell)}{2},1))); % Standard Error            
            ts_cRedLow = tinv(0.025,size(allCTraces{terminals(ccell)}{2},1)-1);% T-Score for 95% CI
            ts_cRedHigh = tinv(0.975,size(allCTraces{terminals(ccell)}{2},1)-1);% T-Score for 95% CI
            CI_cRedLow = (nanmean(allCTraces{terminals(ccell)}{2},1)) + (ts_cRedLow*SEMcRed);  % Confidence Intervals
            CI_cRedHigh = (nanmean(allCTraces{terminals(ccell)}{2},1)) + (ts_cRedHigh*SEMcRed);  % Confidence Intervals
       %}
%             SEMb{per} = (std(allBTraces{terminals(ccell)}{per}))/(sqrt(size(allBTraces{terminals(ccell)}{per},1))); % Standard Error            
%             STDb{per} = std(allBTraces{terminals(ccell)}{per});
%             ts_bLow = tinv(0.025,size(allBTraces{terminals(ccell)}{per},1)-1);% T-Score for 95% CI
%             ts_bHigh = tinv(0.975,size(allBTraces{terminals(ccell)}{per},1)-1);% T-Score for 95% CI
%             CI_bLow{per} = (nanmean(allBTraces{terminals(ccell)}{per},1)) + (ts_bLow*SEMb{per});  % Confidence Intervals
%             CI_bHigh{per} = (nanmean(allBTraces{terminals(ccell)}{per},1)) + (ts_bHigh*SEMb{per});  % Confidence Intervals
            
            x = 1:length(CI_cBlueLow);
                    
            %plot single traces
            %{
%            for peak = 1:size(Btraces{terminals(ccell)}{per},1)
%                plot(Btraces{terminals(ccell)}{per}(peak,:),'r')                 
%            end 
%            for peak = 1:size(Ctraces{terminals(ccell)}{per},1)
%                plot(Ctraces{terminals(ccell)}{per}(peak,:),'b')                 
%            end 
%            for peak = 1:size(Vtraces{terminals(ccell)}{per},1)
%                plot(Vtraces{terminals(ccell)}{per}(peak,:),'Color',[0.5 0 0])                 
%            end            

%}
            
            %get averages
            AVSNBdataPeaks{terminals(ccell)}{per} = nanmean(allBTraces{terminals(ccell)}{per},1);
            AVSNCdataPeaks{terminals(ccell)}{per} = nanmean(allCTraces{terminals(ccell)}{per},1);
            AVSNVdataPeaks{terminals(ccell)}{per} = nanmean(allVTraces{terminals(ccell)}{per},1);
            %plot the averages
%             plot(AVSNBdataPeaks{terminals(ccell)}{per},'r','LineWidth',4)            
           %{
           AVSNCdataPeaks1{terminals(ccell)}{1} = nanmean(allCTraces{terminals(ccell)}{1},1);
           AVSNCdataPeaks2{terminals(ccell)}{2} = nanmean(allCTraces{terminals(ccell)}{2},1);
           AVSNCdataPeaks3{terminals(ccell)}{3} = nanmean(allCTraces{terminals(ccell)}{3},1);
           
            plot(AVSNCdataPeaks3{terminals(ccell)}{3},'k','LineWidth',4)  
            plot(AVSNCdataPeaks1{terminals(ccell)}{1},'b','LineWidth',4)         
            plot(AVSNCdataPeaks2{terminals(ccell)}{2},'r','LineWidth',4)
            %}
            plot([changePt changePt], [-10000000 10000000], 'k:','LineWidth',4)
%             plot([startF startF], [-10000000 10000000], 'k','LineWidth',2)
%             plot([endF endF], [-10000000 10000000], 'k','LineWidth',2)
            patch([x fliplr(x)],[CI_cSpontLow fliplr(CI_cSpontHigh)],[0.5 0.5 0.5],'EdgeColor','none')
            patch([x fliplr(x)],[CI_cBlueLow fliplr(CI_cBlueHigh)],[0 0 0.5],'EdgeColor','none')  
            patch([x fliplr(x)],[CI_cRedLow fliplr(CI_cRedHigh)],[0.5 0 0],'EdgeColor','none')
%             patch([x fliplr(x)],[CI_bLow{per} fliplr(CI_bHigh{per})],[0.5 0 0],'EdgeColor','none')
          
%             plot(AVSNVdataPeaks{terminals(ccell)}{per},'Color',[0.5 0 0],'LineWidth',4) %'Color',[0.5 0 0]
%             label2 = sprintf('Terminal %d calcium',terminals(ccell));
 
%             legend('BBB signal',label2,'Calcium peak onset','Location','northwest');
%             legend('Vessel width','Calcium peak onset','Location','northwest');
%             legend('BBB signal','Calcium peak onset','Location','northwest');
            legend('spontaneous','blue light on','red light on','calcium peak onset','Location','northwest','FontName','Times');
            
            ax.XTick = FrameVals;
            ax.XTickLabel = sec_TimeVals;   
            ax.FontSize = 25;
            ax.FontName = 'Times';
            xlabel('time (s)','FontName','Times')
            ylabel('percent change','FontName','Times')
            xlim([1 length(AVSNBdataPeaks{terminals(ccell)}{per})])
            ylim([-25 120])
%             ylim([-2 3])
        %     legend('DA calcium','BBB data')
        
%             per = 1;    
            if smoothQ == 0 
                if per == 1 
%                     title(sprintf('DA terminal #%d. Blue light on.',terminals(ccell)))
                    title('DA Terminal GCaMP6s Spike Triggered Averages','FontName','Times')
                elseif per == 2
                    title(sprintf('DA terminal #%d. Red light on.',terminals(ccell)))
                elseif per == 3
                    title(sprintf('DA terminal #%d. ISI period.',terminals(ccell)))
                end                 
            elseif smoothQ == 1                
                if per == 1 
                    title(sprintf('DA terminal #%d. Blue light on.',terminals(ccell)))
                elseif per == 2
                    title(sprintf('DA terminal #%d. Red light on.',terminals(ccell)))
                elseif per == 3
                    title(sprintf('DA terminal #%d. Lights off.',terminals(ccell)))
                end               
            end 
            set(fig,'position', [500 100 900 800])
            
            if per == 1 
                dir = sprintf('D:/70kD_RhoB/DAT-Chrimson-GCaMP/SF56_20190718/figures/Terminal12/DAterminal%d_1sSmoothingWithCI.tif',terminals(ccell));
            elseif per == 2
                dir = sprintf('D:/70kD_RhoB/DAT-Chrimson-GCaMP/SF56_20190718/figures/Terminal12/DAterminal%d_redLight_1sSmoothingWithCI.tif',terminals(ccell));
            elseif per == 3
                dir = sprintf('D:/70kD_RhoB/DAT-Chrimson-GCaMP/SF56_20190718/figures/Terminal12/DAterminal%d_lightOff_1sSmoothingWithCI.tif',terminals(ccell));
            end                                                   
            alpha(0.3)   % set all patches transparency to 0.3
%             export_fig(dir) 
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
    spatFiltChanQ= input('Input 0 to temporally smooth both channels. Input 1 otherwise. ');
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
%             imagesc(RightChan{terminals(ccell)}(:,:,frame),[0,3]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',0:0.5:3)%this makes the max point 1% and the min point -1% 
%             imagesc(RightChan{terminals(ccell)}(:,:,frame),[0,5]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',0:1:5)%this makes the max point 1% and the min point -1% 
%             imagesc(RightChan{terminals(ccell)}(:,:,frame),[0,1]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',0:0.25:1)%this makes the max point 1% and the min point -1% 
%             imagesc(RightChan{terminals(ccell)}(:,:,frame),[0,0.75]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',0:0.25:0.75)%this makes the max point 1% and the min point -1% 
            imagesc(RightChan{terminals(ccell)}(:,:,frame),[0,0.5]); colormap(cMap); cbh = colorbar; set(cbh,'YTick',0:0.25:0.5)%this makes the max point 1% and the min point -1% 

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
%% determine how far away each terminal is from the vessel of interest 
if distQ == 1
    
end 

