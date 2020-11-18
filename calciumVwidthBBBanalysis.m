% get the data you need 
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
%% baseline, smooth trial, and plot event triggered averages                                                                                                                                       
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
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*5:Frames_post_stim_start)/FPSstack)+1);
                FrameVals = floor((1:FPSstack*5:Frames)-1); 
            elseif tType == 2 || tType == 4 
                Frames = size(nsBeta{BBBroi}{tType},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*5:Frames_post_stim_start)/FPSstack)+10);
                FrameVals = floor((1:FPSstack*5:Frames)-1); 
            end 
            if BBBQ == 1 
                plot(AVbData{BBBroi}{tType},'r','LineWidth',3)
                patch([x fliplr(x)],[CI_bLow{BBBroi}{tType} fliplr(CI_bHigh{BBBroi}{tType})],[0.5 0 0],'EdgeColor','none')
            end 
            if CAQ == 1 
                plot(AVcData{terminals(ccell)}{tType},'b','LineWidth',3)
                patch([x fliplr(x)],[CI_cLow{terminals(ccell)}{tType} fliplr(CI_cHigh{terminals(ccell)}{tType})],[0 0 0.5],'EdgeColor','none')
            end 
            if VWQ == 1
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
            if BBBQ == 1
                label = append(label,sprintf('BBB ROI %d',BBBroi)); 
            end 
            if CAQ == 1 
                label = append(label,sprintf('  Ca ROI %d',terminals(ccell)));
            end 
            if VWQ == 1
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
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*5:Frames_post_stim_start)/FPSstack)+1);
                FrameVals = floor((1:FPSstack*5:Frames)-1); 
            elseif tType == 2 || tType == 4 
                Frames = size(nsBeta{1}{tType},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*5:Frames_post_stim_start)/FPSstack)+10);
                FrameVals = floor((1:FPSstack*5:Frames)-1); 
            end 
            if BBBQ == 1 
                plot(AVbData{1}{tType},'r','LineWidth',3)
                patch([x fliplr(x)],[CI_bLow{1}{tType} fliplr(CI_bHigh{1}{tType})],[0.5 0 0],'EdgeColor','none')
            end 
            if CAQ == 1 
                plot(AVcData{1}{tType},'b','LineWidth',3)
                patch([x fliplr(x)],[CI_cLow{1}{tType} fliplr(CI_cHigh{1}{tType})],[0 0 0.5],'EdgeColor','none')
            end 
            if VWQ == 1
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
            if BBBQ == 1
                label = append(label,'BBB ROIs averaged'); 
            end 
            if CAQ == 1 
                label = append(label,'  Ca ROIs averaged');
            end 
            if VWQ == 1
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
%% sort data based on ca peak location 
%{
windSize = input('How big should the window be around Ca peak in seconds? ');
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
                    if VWQ == 1
                        for VWroi = 1:length(vDataFullTrace{1})
                            sortedVdata{vid}{VWroi}{terminals(ccell)}(peak,:) = vDataFullTrace{vid}{VWroi}(start:stop);
                        end 
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
            if VWQ == 1
                for VWroi = 1:length(vDataFullTrace{1})
                    nonZeroRowsV = all(sortedVdata{vid}{VWroi}{terminals(ccell)} == 0,2);
                    sortedVdata{vid}{VWroi}{terminals(ccell)}(nonZeroRowsV,:) = NaN;
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
                        for BBBroi = 1:length(bDataFullTrace{1})
                            sortedBdata{vid}{BBBroi}{terminals(ccell)}{per}(peak,:) = bDataFullTrace{vid}{BBBroi}(start:stop);
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
%% normalize to baseline period and plot calcium peak aligned data
%PICK UP HERE- THE SMOOTHING OPTION ISN'T SMOOTHING - WELL ATLEAST, WHEN I
%GO TO PLOT, I DON'T SEE SMOOTHED DATA 


%find where calcium peak onset is 
% changePt = floor(size(sortedCdata{1}{terminals(1)}{1},2)/2)-floor(0.25*FPSstack);    

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
        for vid = 1:length(vidList)
            for ccell = 1:length(terminals)
%                 [sC_Data] = MovMeanSmoothData(sortedCdata{vid}{terminals(ccell)},filtTime,FPSstack);
%                 SCdataPeaks{vid}{terminals(ccell)} = sC_Data; 
                if BBBQ == 1
                    for BBBroi = 1:length(bDataFullTrace{1})
                        [sB_Data] = MovMeanSmoothData(sortedBdata{vid}{BBBroi}{terminals(ccell)},filtTime,FPSstack);
                        SBdataPeaks{vid}{BBBroi}{terminals(ccell)} = sB_Data;
                    end
                end 
                if VWQ == 1
                    for VWroi = 1:length(vDataFullTrace{1})
                        [sV_Data] = MovMeanSmoothData(sortedVdata{vid}{VWroi}{terminals(ccell)},filtTime,FPSstack);
                        SVdataPeaks{vid}{VWroi}{terminals(ccell)} = sV_Data;
                    end 
                end 
            end 
        end 
        SCdataPeaks = sortedCdata;
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
            if isempty(SBdataPeaks{vid}{BBBroi}{terminals(ccell)}) == 0 

                %the data needs to be added to because there are some
                %negative gonig points which mess up the normalizing 
                if BBBQ == 1
                    for BBBroi = 1:length(bDataFullTrace{1})
                        sortedBdata2{vid}{BBBroi}{terminals(ccell)} = SBdataPeaks{vid}{BBBroi}{terminals(ccell)} + 100;
                    end
                end 
                sortedCdata2{vid}{terminals(ccell)} = SCdataPeaks{vid}{terminals(ccell)} + 100;
                if VWQ == 1
                    for VWroi = 1:length(vDataFullTrace{1})
                        sortedVdata2{vid}{VWroi}{terminals(ccell)} = SVdataPeaks{vid}{VWroi}{terminals(ccell)} + 100;
                    end 
                end 
                
                %normalize to 5 sec before changePt (calcium peak
                %onset) BLstart 
                changePt = floor(size(sortedCdata{1}{terminals(1)},2)/2)-4;
%                 BLstart = changePt - floor(0.5*FPSstack);
                BLstart = changePt - floor(5*FPSstack);
                if BBBQ == 1
                    for BBBroi = 1:length(bDataFullTrace{1})
                        SNBdataPeaks{vid}{BBBroi}{terminals(ccell)} = ((sortedBdata2{vid}{BBBroi}{terminals(ccell)})./(nanmean(sortedBdata2{vid}{BBBroi}{terminals(ccell)}(:,BLstart:changePt),2)))*100;
                    end 
                end 
                SNCdataPeaks{vid}{terminals(ccell)} = ((sortedCdata2{vid}{terminals(ccell)})./(nanmean(sortedCdata2{vid}{terminals(ccell)}(:,BLstart:changePt),2)))*100;
                if VWQ == 1
                    for VWroi = 1:length(vDataFullTrace{1})
                        SNVdataPeaks{vid}{VWroi}{terminals(ccell)} = ((sortedVdata2{vid}{VWroi}{terminals(ccell)})./(nanmean(sortedVdata2{vid}{VWroi}{terminals(ccell)}(:,BLstart:changePt),2)))*100;
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
     

    %} 
elseif tTypeQ == 1 

    smoothQ = input('Input 0 to plot non-smoothed data. Input 1 to plot smoothed data.');
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
                                    end 
                                end
    %                             [SCPeak_Data] = MovMeanSmoothData(sortedCdata{vid}{terminals(ccell)}{per}(peak,:),filtTime,FPSstack);
    %                             SCdataPeaks{vid}{terminals(ccell)}{per}(peak,:) = SCPeak_Data;     
                                if VWQ == 1
                                    for VWroi = 1:length(vDataFullTrace{1})
                                        [SVPeak_Data] = MovMeanSmoothData(sortedVdata{vid}{VWroi}{terminals(ccell)}{per}(peak,:),filtTime,FPSstack);
                                        SVdataPeaks{vid}{VWroi}{terminals(ccell)}{per}(peak,:) = SVPeak_Data;     
                                    end 
                                end 
                            end 
                        end 
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
                                    sortedBdata2{vid}{BBBroi}{terminals(ccell)}{per} = SBdataPeaks{vid}{BBBroi}{terminals(ccell)}{per} + 100;                       
                                end     
                            end 
                            sortedCdata2{vid}{terminals(ccell)}{per} = SCdataPeaks{vid}{terminals(ccell)}{per} + 100;     
                            if VWQ == 1 
                                for VWroi = 1:length(vDataFullTrace{1})                   
                                    sortedVdata2{vid}{VWroi}{terminals(ccell)}{per} = SVdataPeaks{vid}{VWroi}{terminals(ccell)}{per} + 100;                 
                                end 
                            end 

                              %this normalizes to the first 1/3 section of the trace
                              %(18 frames) 
            %{
                                NsortedBdata{vid}{terminals(ccell)}{per} = ((sortedBdata2{vid}{terminals(ccell)}{per})./((nanmean(sortedBdata2{vid}{terminals(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3)),2))))*100;
                                NsortedCdata{vid}{terminals(ccell)}{per} = ((sortedCdata2{vid}{terminals(ccell)}{per})./((nanmean(sortedCdata2{vid}{terminals(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3)),2))))*100;
                                NsortedVdata{vid}{terminals(ccell)}{per} = ((sortedVdata2{vid}{terminals(ccell)}{per})./((nanmean(sortedVdata2{vid}{terminals(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3)),2))))*100;            
            %}                     
                              
                            %normalize to 5 sec before changePt (calcium peak
                            %onset) BLstart 
                            changePt = floor(size(sortedCdata{1}{terminals(1)}{1},2)/2)-4;
                            BLstart = changePt - floor(5*FPSstack);
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
%% plot calcium spike triggered averages (this can plot traces within 2 std from the mean, but all data gets stored)
% if you are averaging, this plots one trace at a time. if not averaging,
% this plots all traces. this also only plots one BBB or VW ROI at once. 
%{
%  clear AVSNCdataPeaks AVSNCdataPeaks2 AVSNCdataPeaks3 AVSNBdataPeaks AVSNBdataPeaks2 AVSNBdataPeaks3 AVSNVdataPeaks AVSNVdataPeaks2 AVSNVdataPeaks3 BTraces VTraces CTraces

if tTypeQ == 1 
    per = input('Input 1 for blue light period. Input 2 for red light period. Input 3 for light off period. '); 
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
    clear AVSNCdataPeaks AVSNCdataPeaks2 AVSNCdataPeaks3
elseif tTypeQ == 1 
    if AVQ == 0 
        for ccell = 1:length(terms)
            AVSNCdataPeaks{terms(ccell)}{per} = [] ; AVSNCdataPeaks2{terms(ccell)}{per} = [] ; AVSNCdataPeaks3{terms(ccell)}{per} = [] ;
        end 
    elseif AVQ == 1
        AVSNCdataPeaks{per} = [] ;
        AVSNCdataPeaks3{per} = [] ;
        for ccell = 1:length(terms)
             AVSNCdataPeaks2{terms(ccell)}{per} = [] ; 
        end 
    end 
end 

BBBQ = input('Input 1 if you want to plot BBB data. ');
if BBBQ == 1
    BBBroi = input('What BBB ROI do you want to plot? ');
    if tTypeQ == 0 
        AVSNBdataPeaks{BBBroi} = [] ; AVSNBdataPeaks2{BBBroi} = [] ; AVSNBdataPeaks3{BBBroi} = [] ;
    elseif tTypeQ == 1
        if AVQ == 0 
            for ccell = 1:length(terms)
                AVSNBdataPeaks{BBBroi}{terms(ccell)}{per} = [] ; AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} = [] ; AVSNBdataPeaks3{BBBroi}{terms(ccell)}{per} = [] ;
            end 
        elseif AVQ == 1 % if AVQ == 1 AVSNBdataPeaks3{BBBroi}{per}(ccell,:)
            AVSNBdataPeaks{BBBroi}{per} = [] ; 
            AVSNBdataPeaks3{BBBroi}{per} = [] ;
            for ccell = 1:length(terms)
                AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} = [] ; 
            end 
        end 
    end 
end 

VWQ = input('Input 1 if you want to plot vessel width data. ');
if VWQ == 1
    VWroi = input('What vessel width ROI do you want to plot? ');
    if tTypeQ == 0 
        AVSNVdataPeaks{VWroi} = [] ; AVSNVdataPeaks2{VWroi} = [] ; AVSNVdataPeaks3{VWroi} = [] ;
    elseif tTypeQ == 1
        if AVQ == 0 
            for ccell = 1:length(terms)
                AVSNVdataPeaks{VWroi}{terms(ccell)}{per} = [] ; AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} = [] ; AVSNVdataPeaks3{VWroi}{terms(ccell)}{per} = [] ;
            end 
        elseif AVQ == 1 
            AVSNVdataPeaks{VWroi}{per} = [] ; 
            AVSNVdataPeaks3{VWroi}{per} = [] ;
            for ccell = 1:length(terms)
                AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} = [] ; 
            end 
        end 
    end 
end 

saveQ = input('Input 1 to save the figures. Input 0 otherwise. ');
if saveQ == 1                
    dir1 = input('What folder are you saving these images in? ');
end 

if tTypeQ == 0 
    %{
    if AVQ == 0 
        allCTraces = cell(1,length(SNCdataPeaks{1}));
        allBTraces = cell(1,length(SNCdataPeaks{1}));
        allVTraces = cell(1,length(SNCdataPeaks{1}));
        CTraces = cell(1,length(SNCdataPeaks{1}));
        BTraces = cell(1,length(SNCdataPeaks{1}));
        VTraces = cell(1,length(SNCdataPeaks{1}));
        for ccell = 1:length(terms)
            fig = figure;
            Frames = size(SNBdataPeaks{1}{BBBroi}{terms(ccell)},2);
            Frames_pre_stim_start = -((Frames-1)/2); 
            Frames_post_stim_start = (Frames-1)/2; 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack))+1;
            FrameVals = round((1:FPSstack:Frames))+5; 
            ax=gca;
            hold all
            count = 1;
            % sort data 
            for vid = 1:length(vidList)      
                if isempty(sortedBdata{vid}{BBBroi}{terms(ccell)}) == 0
                    for peak = 1:size(SNCdataPeaks{vid}{terms(ccell)},1) 
                        if BBBQ == 1
                            allBTraces{BBBroi}{terms(ccell)}(count,:) = (SNBdataPeaks{vid}{BBBroi}{terms(ccell)}(peak,:)-100); 
                        end 
                        if VWQ == 1
                            allVTraces{VWroi}{terms(ccell)}(count,:) = (SNVdataPeaks{vid}{VWroi}{terms(ccell)}(peak,:)-100); 
                        end 
                        allCTraces{terms(ccell)}(count,:) = (SNCdataPeaks{vid}{terms(ccell)}(peak,:)-100);
                        count = count + 1;
                    end 
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
            
            %get averages of all traces
            if BBBQ == 1
                AVSNBdataPeaks2{BBBroi}{terms(ccell)} = (nanmean(allBTraces{BBBroi}{terms(ccell)}));
            end 
            AVSNCdataPeaks2{terms(ccell)} = nanmean(allCTraces{terms(ccell)});
            if VWQ == 1
                AVSNVdataPeaks2{VWroi}{terms(ccell)} = (nanmean(allVTraces{VWroi}{terms(ccell)}));
            end 
            
            %remove traces that are outliers 
            %statistically (greater than 2 standard deviations from the
            %mean 
            count2 = 1; 
            count3 = 1;
            count4 = 1;
            for peak = 1:size(allCTraces{terms(ccell)},1)
                    if BBBQ == 1
%                         if allBTraces{BBBroi}{terms(ccell)}(peak,:) < AVSNBdataPeaks2{BBBroi}{terms(ccell)} + nanstd(allBTraces{BBBroi}{terms(ccell)},1)*2  & allBTraces{BBBroi}{terms(ccell)}(peak,:) > AVSNBdataPeaks2{BBBroi}{terms(ccell)} - nanstd(allBTraces{BBBroi}{terms(ccell)},1)*2               
                            BTraces{BBBroi}{terms(ccell)}(count2,:) = (allBTraces{BBBroi}{terms(ccell)}(peak,:));
                            count2 = count2 + 1;
%                         end 
                    end 
%                     if allCTraces{terms(ccell)}(peak,:) < AVSNCdataPeaks2{terms(ccell)} + nanstd(allCTraces{terms(ccell)},1)*2 & allCTraces{terms(ccell)}(peak,:) > AVSNCdataPeaks2{terms(ccell)} - nanstd(allCTraces{terms(ccell)},1)*2                     
                        CTraces{terms(ccell)}(count3,:) = (allCTraces{terms(ccell)}(peak,:));
                        count3 = count3 + 1;
%                     end 
                    if VWQ == 1
%                         if allVTraces{VWroi}{terms(ccell)}(peak,:) < AVSNVdataPeaks2{VWroi}{terms(ccell)} + nanstd(allVTraces{VWroi}{terms(ccell)},1)*2 & allVTraces{VWroi}{terms(ccell)}(peak,:) > AVSNVdataPeaks2{VWroi}{terms(ccell)} - nanstd(allVTraces{VWroi}{terms(ccell)},1)*2              
                            VTraces{VWroi}{terms(ccell)}(count4,:) = (allVTraces{VWroi}{terms(ccell)}(peak,:));
                            count4 = count4 + 1;
%                         end 
                    end 
            end 

            %DETERMINE 95% CI
            if BBBQ == 1
                SEMb = (nanstd(BTraces{BBBroi}{terms(ccell)}))/(sqrt(size(BTraces{BBBroi}{terms(ccell)},1))); % Standard Error            
                ts_bLow = tinv(0.025,size(BTraces{BBBroi}{terms(ccell)},1)-1);% T-Score for 95% CI
                ts_bHigh = tinv(0.975,size(BTraces{BBBroi}{terms(ccell)},1)-1);% T-Score for 95% CI
                CI_bLow = (nanmean(BTraces{BBBroi}{terms(ccell)},1)) + (ts_bLow*SEMb);  % Confidence Intervals
                CI_bHigh = (nanmean(BTraces{BBBroi}{terms(ccell)},1)) + (ts_bHigh*SEMb);  % Confidence Intervals
            end 
            
            SEMc = (nanstd(CTraces{terms(ccell)}))/(sqrt(size(CTraces{terms(ccell)},1))); % Standard Error            
            ts_cLow = tinv(0.025,size(CTraces{terms(ccell)},1)-1);% T-Score for 95% CI
            ts_cHigh = tinv(0.975,size(CTraces{terms(ccell)},1)-1);% T-Score for 95% CI
            CI_cLow = (nanmean(CTraces{terms(ccell)},1)) + (ts_cLow*SEMc);  % Confidence Intervals
            CI_cHigh = (nanmean(CTraces{terms(ccell)},1)) + (ts_cHigh*SEMc);  % Confidence Intervals

            if VWQ == 1
                SEMv = (nanstd(VTraces{VWroi}{terms(ccell)}))/(sqrt(size(VTraces{VWroi}{terms(ccell)},1))); % Standard Error            
                ts_vLow = tinv(0.025,size(VTraces{VWroi}{terms(ccell)},1)-1);% T-Score for 95% CI
                ts_vHigh = tinv(0.975,size(VTraces{VWroi}{terms(ccell)},1)-1);% T-Score for 95% CI
                CI_vLow = (nanmean(VTraces{VWroi}{terms(ccell)},1)) + (ts_vLow*SEMv);  % Confidence Intervals
                CI_vHigh = (nanmean(VTraces{VWroi}{terms(ccell)},1)) + (ts_vHigh*SEMv);  % Confidence Intervals
            end 

            x = 1:length(CI_cLow);

            %get averages of traces excluding outliers  
            if BBBQ == 1
                AVSNBdataPeaks{BBBroi}{terms(ccell)} = (nanmean(BTraces{BBBroi}{terms(ccell)}));
            end 
            AVSNCdataPeaks{terms(ccell)} = nanmean(CTraces{terms(ccell)});
            if VWQ == 1
                AVSNVdataPeaks{VWroi}{terms(ccell)} = (nanmean(VTraces{VWroi}{terms(ccell)}));
            end 
            % plot 
            plot(AVSNCdataPeaks{terms(ccell)},'b','LineWidth',4)
%             plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
            ax.XTick = FrameVals;
            ax.XTickLabel = sec_TimeVals;   
            ax.FontSize = 25;
            ax.FontName = 'Times';
            xlabel('time (s)','FontName','Times')
            ylabel('calcium signal percent change','FontName','Times')
            xLimStart = floor(10*FPSstack);
            xLimEnd = floor(24*FPSstack); 
            xlim([1 size(AVSNCdataPeaks{terms(ccell)},2)])
            ylim([-60 100])
            patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],[0 0 0.5],'EdgeColor','none')            
            set(fig,'position', [500 100 900 800])
            alpha(0.3)

            %add right y axis tick marks for a specific DOD figure. 
            yyaxis right 
            if BBBQ == 1
                plot(AVSNBdataPeaks{BBBroi}{terms(ccell)},'r','LineWidth',4)
                patch([x fliplr(x)],[(CI_bLow) (fliplr(CI_bHigh))],[0.5 0 0],'EdgeColor','none')
                ylabel('BBB permeability percent change','FontName','Times')
                tlabel = sprintf('Terminal%d_BBBroi%d.',terms(ccell),BBBroi);
                title(sprintf('Terminal %d. BBB ROI %d.',terms(ccell),BBBroi))
    %             title('BBB permeability Spike Triggered Average')
                
            end 
            if VWQ == 1
                plot(AVSNVdataPeaks{VWroi}{terms(ccell)},'k','LineWidth',4)
                patch([x fliplr(x)],[(CI_vLow) (fliplr(CI_vHigh))],'k','EdgeColor','none')
                ylabel('Vessel width percent change','FontName','Times')
                tlabel = sprintf('Terminal%d_VwidthROI%d.',terms(ccell),VWroi);
    %             title(sprintf('Terminal %d. Vessel width ROI %d.',terminals(ccell),VWroi))
                title(sprintf('Terminal %d. VW ROI %d.',terms(ccell),VWroi))
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
        
    elseif AVQ == 1 % average across calcium ROIs 
        allCTraces = cell(1,length(SNCdataPeaks{1}));
        allBTraces = cell(1,length(SNCdataPeaks{1}));
        allVTraces = cell(1,length(SNCdataPeaks{1}));
        CTraces = cell(1,length(SNCdataPeaks{1}));
        BTraces = cell(1,length(SNCdataPeaks{1}));
        VTraces = cell(1,length(SNCdataPeaks{1}));
        for ccell = 1:length(terms)            
            count = 1;
            % sort data 
            for vid = 1:length(vidList)      
                if isempty(sortedBdata{vid}{BBBroi}{terms(ccell)}) == 0
                    for peak = 1:size(SNCdataPeaks{vid}{terms(ccell)},1) 
                        if BBBQ == 1
                            allBTraces{BBBroi}{terms(ccell)}(count,:) = (SNBdataPeaks{vid}{BBBroi}{terms(ccell)}(peak,:)-100); 
                        end 
                        if VWQ == 1
                            allVTraces{VWroi}{terms(ccell)}(count,:) = (SNVdataPeaks{vid}{VWroi}{terms(ccell)}(peak,:)-100); 
                        end 
                        allCTraces{terms(ccell)}(count,:) = (SNCdataPeaks{vid}{terms(ccell)}(peak,:)-100);
                        count = count + 1;
                    end 
                end
            end 
            
            %get averages of all traces 
            if BBBQ == 1
                AVSNBdataPeaks2{BBBroi}{terms(ccell)} = (nanmean(allBTraces{BBBroi}{terms(ccell)}));
            end 
            AVSNCdataPeaks2{terms(ccell)} = nanmean(allCTraces{terms(ccell)});
            if VWQ == 1
                AVSNVdataPeaks2{VWroi}{terms(ccell)} = (nanmean(allVTraces{VWroi}{terms(ccell)}));
            end 
            
            %remove traces that are outliers 
            %statistically (greater than 2 standard deviations from the
            %mean 
            count2 = 1; 
            count3 = 1;
            count4 = 1;
            for peak = 1:size(allCTraces{terms(ccell)},1)
                    if BBBQ == 1
%                         if allBTraces{BBBroi}{terms(ccell)}(peak,:) < AVSNBdataPeaks2{BBBroi}{terms(ccell)} + nanstd(allBTraces{BBBroi}{terms(ccell)},1)*2  & allBTraces{BBBroi}{terms(ccell)}(peak,:) > AVSNBdataPeaks2{BBBroi}{terms(ccell)} - nanstd(allBTraces{BBBroi}{terms(ccell)},1)*2               
                            BTraces{BBBroi}{terms(ccell)}(count2,:) = (allBTraces{BBBroi}{terms(ccell)}(peak,:));
                            count2 = count2 + 1;
%                         end 
                    end 
%                     if allCTraces{terms(ccell)}(peak,:) < AVSNCdataPeaks2{terms(ccell)} + nanstd(allCTraces{terms(ccell)},1)*2 & allCTraces{terms(ccell)}(peak,:) > AVSNCdataPeaks2{terms(ccell)} - nanstd(allCTraces{terms(ccell)},1)*2                      
                        CTraces{terms(ccell)}(count3,:) = (allCTraces{terms(ccell)}(peak,:));
                        count3 = count3 + 1;
%                     end 
                    if VWQ == 1
%                         if allVTraces{VWroi}{terms(ccell)}(peak,:) < AVSNVdataPeaks2{VWroi}{terms(ccell)} + nanstd(allVTraces{VWroi}{terms(ccell)},1)*2 & allVTraces{VWroi}{terms(ccell)}(peak,:) > AVSNVdataPeaks2{VWroi}{terms(ccell)} - nanstd(allVTraces{VWroi}{terms(ccell)},1)*2              
                            VTraces{VWroi}{terms(ccell)}(count4,:) = (allVTraces{VWroi}{terms(ccell)}(peak,:));
                            count4 = count4 + 1;
%                         end 
                    end 
            end 
            
            % get the average of all the traces excluding outliers 
            if BBBQ == 1
                AVSNBdataPeaks3{BBBroi}(ccell,:) = (nanmean(BTraces{BBBroi}{terms(ccell)}));
            end 
            AVSNCdataPeaks3(ccell,:) = nanmean(CTraces{terms(ccell)});
            if VWQ == 1
                AVSNVdataPeaks3{VWroi}(ccell,:) = (nanmean(VTraces{VWroi}{terms(ccell)}));
            end     
        end       
        
        fig = figure;
        Frames = size(AVSNCdataPeaks3,2);
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack))+1;
        FrameVals = round((1:FPSstack:Frames))+5; 
        ax=gca;
        hold all

        %DETERMINE 95% CI
        if BBBQ == 1
            SEMb = (nanstd(AVSNBdataPeaks3{BBBroi})/(sqrt(size(AVSNBdataPeaks3{BBBroi},1)))); % Standard Error            
            ts_bLow = tinv(0.025,size(AVSNBdataPeaks3{BBBroi},1)-1);% T-Score for 95% CI
            ts_bHigh = tinv(0.975,size(AVSNBdataPeaks3{BBBroi},1)-1);% T-Score for 95% CI
            CI_bLow = (nanmean(AVSNBdataPeaks3{BBBroi},1)) + (ts_bLow*SEMb);  % Confidence Intervals
            CI_bHigh = (nanmean(AVSNBdataPeaks3{BBBroi},1)) + (ts_bHigh*SEMb);  % Confidence Intervals
        end 

        SEMc = (nanstd(AVSNCdataPeaks3))/(sqrt(size(AVSNCdataPeaks3,1))); % Standard Error            
        ts_cLow = tinv(0.025,size(AVSNCdataPeaks3,1)-1);% T-Score for 95% CI
        ts_cHigh = tinv(0.975,size(AVSNCdataPeaks3,1)-1);% T-Score for 95% CI
        CI_cLow = (nanmean(AVSNCdataPeaks3,1)) + (ts_cLow*SEMc);  % Confidence Intervals
        CI_cHigh = (nanmean(AVSNCdataPeaks3,1)) + (ts_cHigh*SEMc);  % Confidence Intervals

        if VWQ == 1
            SEMv = (nanstd(AVSNVdataPeaks3{VWroi}))/(sqrt(size(AVSNVdataPeaks3{VWroi},1))); % Standard Error            
            ts_vLow = tinv(0.025,size(AVSNVdataPeaks3{VWroi},1)-1);% T-Score for 95% CI
            ts_vHigh = tinv(0.975,size(AVSNVdataPeaks3{VWroi},1)-1);% T-Score for 95% CI
            CI_vLow = (nanmean(AVSNVdataPeaks3{VWroi},1)) + (ts_vLow*SEMv);  % Confidence Intervals
            CI_vHigh = (nanmean(AVSNVdataPeaks3{VWroi},1)) + (ts_vHigh*SEMv);  % Confidence Intervals
        end 

        x = 1:length(CI_cLow);
        
        %average across terminals 
        AVSNCdataPeaks = nanmean(AVSNCdataPeaks3);
        if BBBQ == 1
            AVSNBdataPeaks{BBBroi} = nanmean(AVSNBdataPeaks3{BBBroi});
        end 
        if VWQ == 1
            AVSNVdataPeaks{VWroi} = nanmean(AVSNVdataPeaks3{VWroi});
        end 
        
        % plot 
        plot(AVSNCdataPeaks,'b','LineWidth',4)
%         plot([changePt changePt], [-100000 100000], 'k:','LineWidth',4)
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;   
        ax.FontSize = 25;
        ax.FontName = 'Times';
        xlabel('time (s)','FontName','Times')
        ylabel('calcium signal percent change','FontName','Times')
        xLimStart = floor(10*FPSstack);
        xLimEnd = floor(24*FPSstack); 
        xlim([1 size(AVSNCdataPeaks,2)])
        ylim([-60 100])

        patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],[0 0 0.5],'EdgeColor','none')
        set(fig,'position', [500 100 900 800])
        alpha(0.3)

        %add right y axis tick marks for a specific DOD figure. 
        yyaxis right 
        if BBBQ == 1
            plot(AVSNBdataPeaks{BBBroi},'r','LineWidth',4)
            patch([x fliplr(x)],[(CI_bLow) (fliplr(CI_bHigh))],[0.5 0 0],'EdgeColor','none')
            ylabel('BBB permeability percent change','FontName','Times')
            title(sprintf('All Terminals Averaged. BBB ROI %d.',BBBroi))
%             title('BBB permeability Spike Triggered Average')
        end 
        if VWQ == 1
            plot(AVSNVdataPeaks{VWroi},'k','LineWidth',4)
            patch([x fliplr(x)],[(CI_vLow) (fliplr(CI_vHigh))],'k','EdgeColor','none')
            ylabel('Vessel width percent change','FontName','Times')
%             title(sprintf('Terminal %d. Vessel width ROI %d.',terminals(ccell),VWroi))
            title(sprintf('All Terminals Averaged. VW ROI %d.',VWroi))
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
    if AVQ == 0 
        allCTraces = cell(1,length(SNCdataPeaks{1}));
        allBTraces = cell(1,length(SNCdataPeaks{1}));
        allVTraces = cell(1,length(SNCdataPeaks{1}));
        for ccell = 1:length(terms)
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
                                allBTraces{BBBroi}{terms(ccell)}{per}(count,:) = (SNBdataPeaks{vid}{BBBroi}{terms(ccell)}{per}(peak,:)-100);
                                allCTraces{terms(ccell)}{per}(count,:) = (SNCdataPeaks{vid}{terms(ccell)}{per}(peak,:)-100);
                                if VWQ == 1
                                    allVTraces{VWroi}{terms(ccell)}{per}(count,:) = (SNVdataPeaks{vid}{VWroi}{terms(ccell)}{per}(peak,:)-100);  
                                end 
                                count = count + 1;
                            end 
                        end
                   end               
            end 
            
            %get averages of all traces 
            if BBBQ == 1
                AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} = nanmean(allBTraces{BBBroi}{terms(ccell)}{per},1);
            end 
            AVSNCdataPeaks2{terms(ccell)}{per} = nanmean(allCTraces{terms(ccell)}{per},1);
            if VWQ == 1
                AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} = nanmean(allVTraces{VWroi}{terms(ccell)}{per},1);
            end 
            
            %remove traces that are outliers 
            %statistically (greater than 2 standard deviations from the
            %mean 
            count2 = 1; 
            count3 = 1;
            count4 = 1;
            for peak = 1:size(allCTraces{terms(ccell)}{per},1)
                    if BBBQ == 1
%                         if allBTraces{BBBroi}{terms(ccell)}{per}(peak,:) < AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} + nanstd(allBTraces{BBBroi}{terms(ccell)}{per},1)*2  & allBTraces{BBBroi}{terms(ccell)}{per}(peak,:) > AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} - nanstd(allBTraces{BBBroi}{terms(ccell)}{per},1)*2               
                            BTraces{BBBroi}{terms(ccell)}{per}(count2,:) = (allBTraces{BBBroi}{terms(ccell)}{per}(peak,:));
                            count2 = count2 + 1;
%                         end 
                    end 
%                     if allCTraces{terms(ccell)}{per}(peak,:) < AVSNCdataPeaks2{terms(ccell)}{per} + nanstd(allCTraces{terms(ccell)}{per},1)*2 & allCTraces{terms(ccell)}{per}(peak,:) > AVSNCdataPeaks2{terms(ccell)}{per} - nanstd(allCTraces{terms(ccell)}{per},1)*2                     
                        CTraces{terms(ccell)}{per}(count3,:) = (allCTraces{terms(ccell)}{per}(peak,:));
                        count3 = count3 + 1;
%                     end 
                    if VWQ == 1
%                         if allVTraces{VWroi}{terms(ccell)}{per}(peak,:) < AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} + nanstd(allVTraces{VWroi}{terms(ccell)}{per},1)*2 & allVTraces{VWroi}{terms(ccell)}{per}(peak,:) > AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} - nanstd(allVTraces{VWroi}{terms(ccell)}{per},1)*2              
                            VTraces{VWroi}{terms(ccell)}{per}(count4,:) = (allVTraces{VWroi}{terms(ccell)}{per}(peak,:));
                            count4 = count4 + 1;
%                         end 
                    end 
            end 

            %calculate the 95% confidence interval
            if BBBQ == 1
                SEMb = (nanstd(BTraces{BBBroi}{terms(ccell)}{per}))/(sqrt(size(BTraces{BBBroi}{terms(ccell)}{per},1))); % Standard Error            
                ts_bLow = tinv(0.025,size(BTraces{BBBroi}{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                ts_bHigh = tinv(0.975,size(BTraces{BBBroi}{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                CI_bLow = (nanmean(BTraces{BBBroi}{terms(ccell)}{per},1)) + (ts_bLow*SEMb);  % Confidence Intervals
                CI_bHigh = (nanmean(BTraces{BBBroi}{terms(ccell)}{per},1)) + (ts_bHigh*SEMb);  % Confidence Intervals
            end 
            
            SEMc = (nanstd(CTraces{terms(ccell)}{per}))/(sqrt(size(CTraces{terms(ccell)}{per},1))); % Standard Error            
            ts_cLow = tinv(0.025,size(CTraces{terms(ccell)}{per},1)-1);% T-Score for 95% CI
            ts_cHigh = tinv(0.975,size(CTraces{terms(ccell)}{per},1)-1);% T-Score for 95% CI
            CI_cLow = (nanmean(CTraces{terms(ccell)}{per},1)) + (ts_cLow*SEMc);  % Confidence Intervals
            CI_cHigh = (nanmean(CTraces{terms(ccell)}{per},1)) + (ts_cHigh*SEMc);  % Confidence Intervals

            if VWQ == 1
                SEMv = (nanstd(VTraces{VWroi}{terms(ccell)}{per}))/(sqrt(size(VTraces{VWroi}{terms(ccell)}{per},1))); % Standard Error            
                ts_vLow = tinv(0.025,size(VTraces{VWroi}{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                ts_vHigh = tinv(0.975,size(VTraces{VWroi}{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                CI_vLow = (nanmean(VTraces{VWroi}{terms(ccell)}{per},1)) + (ts_vLow*SEMv);  % Confidence Intervals
                CI_vHigh = (nanmean(VTraces{VWroi}{terms(ccell)}{per},1)) + (ts_vHigh*SEMv);  % Confidence Intervals        
            end 
            x = 1:length(CI_cLow);

            %get averages
            if BBBQ == 1
                AVSNBdataPeaks{BBBroi}{terms(ccell)}{per} = nanmean(BTraces{BBBroi}{terms(ccell)}{per},1);
            end 
            AVSNCdataPeaks{terms(ccell)}{per} = nanmean(CTraces{terms(ccell)}{per},1);
            if VWQ == 1
                AVSNVdataPeaks{VWroi}{terms(ccell)}{per} = nanmean(VTraces{VWroi}{terms(ccell)}{per},1);
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

            %add right y axis tick marks for a specific DOD figure. 
            yyaxis right 
            if BBBQ == 1
                if isempty(AVSNBdataPeaks{BBBroi}{terms(ccell)}{per}) == 0 && isempty(CI_cLow) == 0 
                    plot(AVSNBdataPeaks{BBBroi}{terms(ccell)}{per},'r','LineWidth',4)
                    patch([x fliplr(x)],[(CI_bLow) (fliplr(CI_bHigh))],[0.5 0 0],'EdgeColor','none')
                    ylabel('BBB permeability percent change','FontName','Times')
                    tlabel = sprintf('Terminal%d_BBBroi%d.',terms(ccell),BBBroi);
                    title(sprintf('Terminal %d. BBB ROI %d.',terms(ccell),BBBroi))
        %             title('BBB permeability Spike Triggered Average')
                end 
            end 
            if VWQ == 1
                if isempty(AVSNVdataPeaks{VWroi}{terms(ccell)}{per}) == 0 && isempty(CI_cLow) == 0 
                    plot(AVSNVdataPeaks{VWroi}{terms(ccell)}{per},'k','LineWidth',4)
                    patch([x fliplr(x)],[(CI_vLow) (fliplr(CI_vHigh))],'k','EdgeColor','none')
                    ylabel('Vessel width percent change','FontName','Times')
                    tlabel = sprintf('Terminal%d_VwidthROI%d.',terms(ccell),VWroi);
        %             title(sprintf('Terminal %d. Vessel width ROI %d.',terminals(ccell),VWroi))
                    title(sprintf('Terminal %d. VW ROI %d.',terms(ccell),VWroi))
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
    elseif AVQ == 1 
        allCTraces = cell(1,length(SNCdataPeaks{1}));
        allBTraces = cell(1,length(SNCdataPeaks{1}));
        allVTraces = cell(1,length(SNCdataPeaks{1}));
        CTraces = cell(1,length(SNCdataPeaks{1}));
        BTraces = cell(1,length(SNCdataPeaks{1}));
        VTraces = cell(1,length(SNCdataPeaks{1}));
        % sort data
        for ccell = 1:length(terms)
            count = 1;
            for vid = 1:length(vidList)
               if length(sortedBdata{vid}{BBBroi}{terms(ccell)}) >= per  
                    if isempty(sortedBdata{vid}{BBBroi}{terms(ccell)}{per}) == 0 
                        for peak = 1:size(sortedBdata{vid}{BBBroi}{terms(ccell)}{per},1)
                            allBTraces{BBBroi}{terms(ccell)}{per}(count,:) = (SNBdataPeaks{vid}{BBBroi}{terms(ccell)}{per}(peak,:)-100);
                            allCTraces{terms(ccell)}{per}(count,:) = (SNCdataPeaks{vid}{terms(ccell)}{per}(peak,:)-100);
                            if VWQ == 1
                                allVTraces{VWroi}{terms(ccell)}{per}(count,:) = (SNVdataPeaks{vid}{VWroi}{terms(ccell)}{per}(peak,:)-100);  
                            end 
                            count = count + 1;
                        end 
                    end
               end               
            end 
            
            %get average of all traces 
            if BBBQ == 1
                AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} = nanmean(allBTraces{BBBroi}{terms(ccell)}{per},1);
            end 
            AVSNCdataPeaks2{terms(ccell)}{per} = nanmean(allCTraces{terms(ccell)}{per},1);
            if VWQ == 1
                AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} = nanmean(allVTraces{VWroi}{terms(ccell)}{per},1);
            end 

            %remove traces that are outliers 
            %statistically (greater than 2 standard deviations from the
            %mean )
            count2 = 1; 
            count3 = 1;
            count4 = 1;
            for peak = 1:size(allCTraces{terms(ccell)}{per},1)
                    if BBBQ == 1
                        if allBTraces{BBBroi}{terms(ccell)}{per}(peak,:) < AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} + nanstd(allBTraces{BBBroi}{terms(ccell)}{per},1)*2  & allBTraces{BBBroi}{terms(ccell)}{per}(peak,:) > AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} - nanstd(allBTraces{BBBroi}{terms(ccell)}{per},1)*2               
                            BTraces{BBBroi}{terms(ccell)}{per}(count2,:) = (allBTraces{BBBroi}{terms(ccell)}{per}(peak,:));
                            count2 = count2 + 1;
                        end 
                    end 
                    if allCTraces{terms(ccell)}{per}(peak,:) < AVSNCdataPeaks2{terms(ccell)}{per} + nanstd(allCTraces{terms(ccell)}{per},1)*2 & allCTraces{terms(ccell)}{per}(peak,:) > AVSNCdataPeaks2{terms(ccell)}{per} - nanstd(allCTraces{terms(ccell)}{per},1)*2                      
                        CTraces{terms(ccell)}(count3,:) = (allCTraces{terms(ccell)}{per}(peak,:));
                        count3 = count3 + 1;
                    end 
                    if VWQ == 1
                        if allVTraces{VWroi}{terms(ccell)}{per}(peak,:) < AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} + nanstd(allVTraces{VWroi}{terms(ccell)}{per},1)*2 & allVTraces{VWroi}{terms(ccell)}{per}(peak,:) > AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} - nanstd(allVTraces{VWroi}{terms(ccell)}{per},1)*2              
                            VTraces{VWroi}{terms(ccell)}{per}(count4,:) = (allVTraces{VWroi}{terms(ccell)}{per}(peak,:));
                            count4 = count4 + 1;
                        end 
                    end 
            end 
            
            % get the average of all the traces excluding outliers 
            if BBBQ == 1 
                AVSNBdataPeaks3{BBBroi}{per}(ccell,:) = (nanmean(BTraces{BBBroi}{terms(ccell)}{per}));
            end 
            AVSNCdataPeaks3{per}(ccell,:) = nanmean(CTraces{terms(ccell)});
            if VWQ == 1
                AVSNVdataPeaks3{VWroi}{per}(ccell,:) = (nanmean(VTraces{VWroi}{terms(ccell)}{per}));
            end 
        end  

        %calculate the 95% confidence interval
        if BBBQ == 1
            SEMb = (nanstd(AVSNBdataPeaks3{BBBroi}{per}))/(sqrt(size(AVSNBdataPeaks3{BBBroi}{per},1))); % Standard Error            
            ts_bLow = tinv(0.025,size(AVSNBdataPeaks3{BBBroi}{per},1)-1);% T-Score for 95% CI
            ts_bHigh = tinv(0.975,size(AVSNBdataPeaks3{BBBroi}{per},1)-1);% T-Score for 95% CI
            CI_bLow = (nanmean(AVSNBdataPeaks3{BBBroi}{per},1)) + (ts_bLow*SEMb);  % Confidence Intervals
            CI_bHigh = (nanmean(AVSNBdataPeaks3{BBBroi}{per},1)) + (ts_bHigh*SEMb);  % Confidence Intervals
        end 
        
        SEMc = (nanstd(AVSNCdataPeaks3{per}))/(sqrt(size(AVSNCdataPeaks3{per},1))); % Standard Error            
        ts_cLow = tinv(0.025,size(AVSNCdataPeaks3{per},1)-1);% T-Score for 95% CI
        ts_cHigh = tinv(0.975,size(AVSNCdataPeaks3{per},1)-1);% T-Score for 95% CI
        CI_cLow = (nanmean(AVSNCdataPeaks3{per},1)) + (ts_cLow*SEMc);  % Confidence Intervals
        CI_cHigh = (nanmean(AVSNCdataPeaks3{per},1)) + (ts_cHigh*SEMc);  % Confidence Intervals

        if VWQ == 1
            SEMv = (nanstd(AVSNVdataPeaks3{VWroi}{per}))/(sqrt(size(AVSNVdataPeaks3{VWroi}{per},1))); % Standard Error            
            ts_vLow = tinv(0.025,size(AVSNVdataPeaks3{VWroi}{per},1)-1);% T-Score for 95% CI
            ts_vHigh = tinv(0.975,size(AVSNVdataPeaks3{VWroi}{per},1)-1);% T-Score for 95% CI
            CI_vLow = (nanmean(AVSNVdataPeaks3{VWroi}{per},1)) + (ts_vLow*SEMv);  % Confidence Intervals
            CI_vHigh = (nanmean(AVSNVdataPeaks3{VWroi}{per},1)) + (ts_vHigh*SEMv);  % Confidence Intervals        
        end 
        x = 1:length(CI_cLow);
        
        %average across terminals 
        AVSNCdataPeaks{per} = nanmean(AVSNCdataPeaks3{per});
        if BBBQ == 1
            AVSNBdataPeaks{BBBroi}{per} = nanmean(AVSNBdataPeaks3{BBBroi}{per});
        end 
        if VWQ == 1
            AVSNVdataPeaks{VWroi}{per} = nanmean(AVSNVdataPeaks3{VWroi}{per});
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
            plot(AVSNBdataPeaks{BBBroi}{per},'r','LineWidth',4)
            patch([x fliplr(x)],[(CI_bLow) (fliplr(CI_bHigh))],[0.5 0 0],'EdgeColor','none')
            ylabel('BBB permeability percent change','FontName','Times')
            tlabel = sprintf('Terminal%d_BBBroi%d.',terminals(ccell),BBBroi);
            title(sprintf('Terminals Averaged. BBB ROI %d.',BBBroi))
        end 
        if VWQ == 1
            plot(AVSNVdataPeaks{VWroi}{per},'k','LineWidth',4)
            patch([x fliplr(x)],[(CI_vLow) (fliplr(CI_vHigh))],'k','EdgeColor','none')
            ylabel('Vessel width percent change','FontName','Times')

            title(sprintf('Terminals Averaged. VW ROI %d.',VWroi))
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

%% plot calcium spike triggered averages (this can plot traces within 2 std from the mean, but all data gets stored)
% this assumes you are averaging, asks how many different groups you want
% to average, and then plots multiple averages overlaid on the same figure. This generates figures for all BBB and VW ROIs at once  

if tTypeQ == 1 
    per = input('Input 1 for blue light period. Input 2 for red light period. Input 3 for light off period. '); 
end 

%define how many groups you want to create average traces for and what Ca
%ROIs fall into these groups 
numGroups = input('How many groups do you want to average? ');
terms = cell(1,length(numGroups)); 
for groupNum = 1:numGroups
    terms{groupNum} = input(sprintf('Input the Ca ROIs you want to average for group #%d. ',groupNum));
end 

%this clears the arrays so you don't get residue traces from previously
%made plots 
if tTypeQ == 0
    clear AVSNCdataPeaks AVSNCdataPeaks2 AVSNCdataPeaks3
elseif tTypeQ == 1 
    AVSNCdataPeaks{per} = [] ;
    AVSNCdataPeaks3{per} = [] ;
    for groupNum = 1:numGroups
        for ccell = 1:length(terms{groupNum})
             AVSNCdataPeaks2{terms{groupNum}(ccell)}{per} = [] ; 
        end 
    end 
end 

BBBQ = input('Input 1 if you want to plot BBB data. ');
if BBBQ == 1
    if tTypeQ == 0 
        for BBBroi = 1:length(sortedBdata{1})
            AVSNBdataPeaks{BBBroi} = [] ; AVSNBdataPeaks2{BBBroi} = [] ; AVSNBdataPeaks3{BBBroi} = [] ;
        end 
    elseif tTypeQ == 1
        if AVQ == 0 
            for BBBroi = 1:length(sortedBdata{1})
                for groupNum = 1:numGroups
                    for ccell = 1:length(terms{groupNum})
                        AVSNBdataPeaks{BBBroi}{terms{groupNum}(ccell)}{per} = [] ; AVSNBdataPeaks2{BBBroi}{terms{groupNum}(ccell)}{per} = [] ; AVSNBdataPeaks3{BBBroi}{terms(ccell)}{per} = [] ;
                    end 
                end 
            end 
        elseif AVQ == 1 % if AVQ == 1 AVSNBdataPeaks3{BBBroi}{per}(ccell,:)
            for BBBroi = 1:length(sortedBdata{1})
                AVSNBdataPeaks{BBBroi}{per} = [] ; 
                AVSNBdataPeaks3{BBBroi}{per} = [] ;
                for groupNum = 1:numGroups
                    for ccell = 1:length(terms{groupNum})
                        AVSNBdataPeaks2{BBBroi}{terms{groupNum}(ccell)}{per} = [] ; 
                    end 
                end 
            end 
        end 
    end 
end 

VWQ = input('Input 1 if you want to plot vessel width data. ');
if VWQ == 1
    if tTypeQ == 0 
        for VWroi = 1:length(sortedVdata{1})
            AVSNVdataPeaks{VWroi} = [] ; AVSNVdataPeaks2{VWroi} = [] ; AVSNVdataPeaks3{VWroi} = [] ;
        end 
    elseif tTypeQ == 1
        if AVQ == 0 
            for VWroi = 1:length(sortedVdata{1})
                for groupNum = 1:numGroups
                    for ccell = 1:length(terms{groupNum})
                        AVSNVdataPeaks{VWroi}{terms{groupNum}(ccell)}{per} = [] ; AVSNVdataPeaks2{VWroi}{terms{groupNum}(ccell)}{per} = [] ; AVSNVdataPeaks3{VWroi}{terms(ccell)}{per} = [] ;
                    end 
                end 
            end 
        elseif AVQ == 1 
            for VWroi = 1:length(sortedVdata{1})
                AVSNVdataPeaks{VWroi}{per} = [] ; 
                AVSNVdataPeaks3{VWroi}{per} = [] ;
                for groupNum = 1:numGroups
                    for ccell = 1:length(terms{groupNum})
                        AVSNVdataPeaks2{VWroi}{terms{groupNum}(ccell)}{per} = [] ; 
                    end 
                end 
            end 
        end 
    end 
end 

saveQ = input('Input 1 to save the figures. Input 0 otherwise. ');
if saveQ == 1                
    dir1 = input('What folder are you saving these images in? ');
end 


if tTypeQ == 0 
    
    allCTraces = cell(1,length(SNCdataPeaks{1}));
    CTraces = cell(1,length(SNCdataPeaks{1}));
    if BBBQ == 1
        allBTraces = cell(1,length(SNCdataPeaks{1}));
        BTraces = cell(1,length(SNCdataPeaks{1}));
    end 
    if VWQ == 1
        allVTraces = cell(1,length(SNCdataPeaks{1}));
        VTraces = cell(1,length(SNCdataPeaks{1}));
    end 

    for groupNum = 1:numGroups
        for ccell = 1:length(terms{groupNum})            
            count1 = 1;
            % sort C data
            for vid = 1:length(vidList)      
                if isempty(sortedCdata{vid}{terms{groupNum}(ccell)}) == 0
                    for peak = 1:size(SNCdataPeaks{vid}{terms{groupNum}(ccell)},1) 
                        allCTraces{groupNum}{terms{groupNum}(ccell)}(count1,:) = (SNCdataPeaks{vid}{terms{groupNum}(ccell)}(peak,:)-100);
                        count1 = count1 + 1;
                    end 
                end
            end         
            % sort B data
            if BBBQ == 1
                for BBBroi = 1:length(sortedBdata{1})
                    count2 = 1;
                    for vid = 1:length(vidList)    
                        if isempty(sortedBdata{vid}{BBBroi}{terms{groupNum}(ccell)}) == 0
                            for peak = 1:size(SNCdataPeaks{vid}{terms{groupNum}(ccell)},1) 
                                allBTraces{groupNum}{BBBroi}{terms{groupNum}(ccell)}(count2,:) = (SNBdataPeaks{vid}{BBBroi}{terms{groupNum}(ccell)}(peak,:)-100); 
                                count2 = count2 + 1;
                            end 
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
                            for peak = 1:size(SNCdataPeaks{vid}{terms{groupNum}(ccell)},1) 
                                allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}(count3,:) = (SNVdataPeaks{vid}{VWroi}{terms{groupNum}(ccell)}(peak,:)-100); 
                                count3 = count3 + 1;
                            end 
                        end
                    end 
                end 
            end 

            %get averages of all traces 
            if BBBQ == 1
                for BBBroi = 1:length(sortedBdata{1})
                    AVSNBdataPeaks2{groupNum}{BBBroi}{terms{groupNum}(ccell)} = (nanmean(allBTraces{groupNum}{BBBroi}{terms{groupNum}(ccell)}));
                end 
            end 
            AVSNCdataPeaks2{groupNum}{terms{groupNum}(ccell)} = nanmean(allCTraces{groupNum}{terms{groupNum}(ccell)});
            if VWQ == 1
                for VWroi = 1:length(sortedVdata{1})
                    AVSNVdataPeaks2{groupNum}{VWroi}{terms{groupNum}(ccell)} = (nanmean(allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}));
                end 
            end 

            %remove traces that are outliers 
            %statistically (greater than 2 standard deviations from the
            %mean 
            count2 = 1; 
            count3 = 1;
            count4 = 1;
            for peak = 1:size(allCTraces{groupNum}{terms{groupNum}(ccell)},1)
                if BBBQ == 1
                    for BBBroi = 1:length(sortedBdata{1})
    %                         if allBTraces{BBBroi}{terms(ccell)}(peak,:) < AVSNBdataPeaks2{BBBroi}{terms(ccell)} + nanstd(allBTraces{BBBroi}{terms(ccell)},1)*2  & allBTraces{BBBroi}{terms(ccell)}(peak,:) > AVSNBdataPeaks2{BBBroi}{terms(ccell)} - nanstd(allBTraces{BBBroi}{terms(ccell)},1)*2               
                            BTraces{groupNum}{BBBroi}{terms{groupNum}(ccell)}(count2,:) = (allBTraces{groupNum}{BBBroi}{terms{groupNum}(ccell)}(peak,:));
                            count2 = count2 + 1;
    %                         end 
                    end 
                end 
    %                     if allCTraces{terms(ccell)}(peak,:) < AVSNCdataPeaks2{terms(ccell)} + nanstd(allCTraces{terms(ccell)},1)*2 & allCTraces{terms(ccell)}(peak,:) > AVSNCdataPeaks2{terms(ccell)} - nanstd(allCTraces{terms(ccell)},1)*2                      
                    CTraces{groupNum}{terms{groupNum}(ccell)}(count3,:) = (allCTraces{groupNum}{terms{groupNum}(ccell)}(peak,:));
                    count3 = count3 + 1;
    %                     end 
                if VWQ == 1
                    for VWroi = 1:length(sortedVdata{1})
    %                         if allVTraces{VWroi}{terms(ccell)}(peak,:) < AVSNVdataPeaks2{VWroi}{terms(ccell)} + nanstd(allVTraces{VWroi}{terms(ccell)},1)*2 & allVTraces{VWroi}{terms(ccell)}(peak,:) > AVSNVdataPeaks2{VWroi}{terms(ccell)} - nanstd(allVTraces{VWroi}{terms(ccell)},1)*2              
                            VTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}(count4,:) = (allVTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}(peak,:));
                            count4 = count4 + 1;
    %                         end 
                    end 
                end 
            end

            % get the average of all the traces excluding outliers 
            if BBBQ == 1
                for BBBroi = 1:length(sortedBdata{1})
                    AVSNBdataPeaks3{groupNum}{BBBroi}(ccell,:) = (nanmean(BTraces{groupNum}{BBBroi}{terms{groupNum}(ccell)}));
                end 
            end 
            AVSNCdataPeaks3{groupNum}(ccell,:) = nanmean(CTraces{groupNum}{terms{groupNum}(ccell)});
            if VWQ == 1
                for VWroi = 1:length(sortedVdata{1})
                    AVSNVdataPeaks3{groupNum}{VWroi}(ccell,:) = (nanmean(VTraces{groupNum}{VWroi}{terms{groupNum}(ccell)}));
                end 
            end     
        end    
    end 

    if BBBQ == 1
        for BBBroi = 1:length(sortedBdata{1})
            fig = figure;
            Frames = size(AVSNCdataPeaks3{groupNum},2);
            Frames_pre_stim_start = -((Frames-1)/2); 
            Frames_post_stim_start = (Frames-1)/2; 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack))+1;
            FrameVals = round((1:FPSstack:Frames))+11; 
            ax=gca;
            hold all
            
            CI_bLow = cell(1,numGroups);
            CI_bHigh = cell(1,numGroups);
            CI_cLow = cell(1,numGroups);
            CI_cHigh = cell(1,numGroups);
            for groupNum = 1:numGroups
                %DETERMINE 95% CI            
                SEMb = (nanstd(AVSNBdataPeaks3{groupNum}{BBBroi})/(sqrt(size(AVSNBdataPeaks3{groupNum}{BBBroi},1)))); % Standard Error            
                ts_bLow = tinv(0.025,size(AVSNBdataPeaks3{groupNum}{BBBroi},1)-1);% T-Score for 95% CI
                ts_bHigh = tinv(0.975,size(AVSNBdataPeaks3{groupNum}{BBBroi},1)-1);% T-Score for 95% CI
                CI_bLow{groupNum} = (nanmean(AVSNBdataPeaks3{groupNum}{BBBroi},1)) + (ts_bLow*SEMb);  % Confidence Intervals
                CI_bHigh{groupNum} = (nanmean(AVSNBdataPeaks3{groupNum}{BBBroi},1)) + (ts_bHigh*SEMb);  % Confidence Intervals
                
                SEMc = (nanstd(AVSNCdataPeaks3{groupNum}))/(sqrt(size(AVSNCdataPeaks3{groupNum},1))); % Standard Error            
                ts_cLow = tinv(0.025,size(AVSNCdataPeaks3{groupNum},1)-1);% T-Score for 95% CI
                ts_cHigh = tinv(0.975,size(AVSNCdataPeaks3{groupNum},1)-1);% T-Score for 95% CI
                CI_cLow{groupNum} = (nanmean(AVSNCdataPeaks3{groupNum},1)) + (ts_cLow*SEMc);  % Confidence Intervals
                CI_cHigh{groupNum} = (nanmean(AVSNCdataPeaks3{groupNum},1)) + (ts_cHigh*SEMc);  % Confidence Intervals

                x = 1:length(CI_cLow{groupNum});

                %average across terminals 
                AVSNCdataPeaks{groupNum} = nanmean(AVSNCdataPeaks3{groupNum});
                AVSNBdataPeaks{groupNum}{BBBroi} = nanmean(AVSNBdataPeaks3{groupNum}{BBBroi});
            end 

            % plot 
            Ccolors = [0,0,1;0,0.5,1;0,1,1];
            for groupNum = 1:numGroups
                plot(AVSNCdataPeaks{groupNum},'Color',Ccolors(groupNum,:),'LineWidth',4)
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
            xlim([1 size(AVSNCdataPeaks{1},2)])
            ylim([-60 100])          
            set(fig,'position', [500 100 900 800])
            
            yyaxis right   
            Bcolors = [1,0,0;1,0.5,0;1,1,0];
            p = zeros(1,numGroups);
            for groupNum = 1:numGroups
                p(groupNum) = plot(AVSNBdataPeaks{groupNum}{BBBroi},'Color',Bcolors(groupNum,:),'LineWidth',4,'LineStyle','-');
                patch([x fliplr(x)],[CI_bLow{groupNum} (fliplr(CI_bHigh{groupNum}))],Bcolors(groupNum,:),'EdgeColor','none')
                alpha(0.3)
            end 
            legend([p(1) p(2)],'Close Terminals','Far Terminals')
            ylabel('BBB permeability percent change','FontName','Times')
            title(sprintf('All Terminals Averaged. BBB ROI %d.',BBBroi))
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

    if VWQ == 1
        for VWroi = 1:length(sortedVdata{1})
            fig = figure;
            Frames = size(AVSNCdataPeaks3{groupNum},2);
            Frames_pre_stim_start = -((Frames-1)/2); 
            Frames_post_stim_start = (Frames-1)/2; 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack))+1;
            FrameVals = round((1:FPSstack:Frames))+11; 
            ax=gca;
            hold all
            
            CI_cLow = cell(1,numGroups);
            CI_cHigh = cell(1,numGroups);
            CI_vLow = cell(1,numGroups);
            CI_vHigh = cell(1,numGroups);
            for groupNum = 1:numGroups
                %DETERMINE 95% CI            
                SEMc = (nanstd(AVSNCdataPeaks3{groupNum}))/(sqrt(size(AVSNCdataPeaks3{groupNum},1))); % Standard Error            
                ts_cLow = tinv(0.025,size(AVSNCdataPeaks3{groupNum},1)-1);% T-Score for 95% CI
                ts_cHigh = tinv(0.975,size(AVSNCdataPeaks3{groupNum},1)-1);% T-Score for 95% CI
                CI_cLow{groupNum} = (nanmean(AVSNCdataPeaks3{groupNum},1)) + (ts_cLow*SEMc);  % Confidence Intervals
                CI_cHigh{groupNum} = (nanmean(AVSNCdataPeaks3{groupNum},1)) + (ts_cHigh*SEMc);  % Confidence Intervals

                SEMv = (nanstd(AVSNVdataPeaks3{groupNum}{VWroi}))/(sqrt(size(AVSNVdataPeaks3{groupNum}{VWroi},1))); % Standard Error            
                ts_vLow = tinv(0.025,size(AVSNVdataPeaks3{groupNum}{VWroi},1)-1);% T-Score for 95% CI
                ts_vHigh = tinv(0.975,size(AVSNVdataPeaks3{groupNum}{VWroi},1)-1);% T-Score for 95% CI
                CI_vLow{groupNum} = (nanmean(AVSNVdataPeaks3{groupNum}{VWroi},1)) + (ts_vLow*SEMv);  % Confidence Intervals
                CI_vHigh{groupNum} = (nanmean(AVSNVdataPeaks3{groupNum}{VWroi},1)) + (ts_vHigh*SEMv);  % Confidence Intervals
              
                x = 1:length(CI_cLow{groupNum});

                %average across terminals 
                AVSNCdataPeaks{groupNum} = nanmean(AVSNCdataPeaks3{groupNum});
                AVSNVdataPeaks{groupNum}{VWroi} = nanmean(AVSNVdataPeaks3{groupNum}{VWroi});
            end 
            % plot 
            Ccolors = [0,0,1;0,0.5,1;0,1,1];
            for groupNum = 1:numGroups
                plot(AVSNCdataPeaks{groupNum},'Color',Ccolors(groupNum,:),'LineWidth',4)
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
            xlim([1 size(AVSNCdataPeaks{1},2)])
            ylim([-60 100])          
            set(fig,'position', [500 100 900 800])
            
            yyaxis right   
            Vcolors = [0,0,0;0.4,0.4,0.4;0.7,0.7,0.7];
            p = zeros(1,numGroups);
            for groupNum = 1:numGroups
                p(groupNum) = plot(AVSNVdataPeaks{groupNum}{VWroi},'Color',Vcolors(groupNum,:),'LineWidth',4,'LineStyle','-');
                patch([x fliplr(x)],[CI_vLow{groupNum} (fliplr(CI_vHigh{groupNum}))],Vcolors(groupNum,:),'EdgeColor','none')
                alpha(0.3)
            end 
            legend([p(1) p(2)],'Close Terminals','Far Terminals')
            ylabel('BBB permeability percent change','FontName','Times')
            title(sprintf('All Terminals Averaged. VW ROI %d.',VWroi))      
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
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
elseif tTypeQ == 1
   %{
    if AVQ == 0 
        allCTraces = cell(1,length(SNCdataPeaks{1}));
        allBTraces = cell(1,length(SNCdataPeaks{1}));
        allVTraces = cell(1,length(SNCdataPeaks{1}));
        for ccell = 1:length(terms)
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
                                allBTraces{BBBroi}{terms(ccell)}{per}(count,:) = (SNBdataPeaks{vid}{BBBroi}{terms(ccell)}{per}(peak,:)-100);
                                allCTraces{terms(ccell)}{per}(count,:) = (SNCdataPeaks{vid}{terms(ccell)}{per}(peak,:)-100);
                                if VWQ == 1
                                    allVTraces{VWroi}{terms(ccell)}{per}(count,:) = (SNVdataPeaks{vid}{VWroi}{terms(ccell)}{per}(peak,:)-100);  
                                end 
                                count = count + 1;
                            end 
                        end
                   end               
            end 
            
            %get averages of all traces 
            if BBBQ == 1
                AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} = nanmean(allBTraces{BBBroi}{terms(ccell)}{per},1);
            end 
            AVSNCdataPeaks2{terms(ccell)}{per} = nanmean(allCTraces{terms(ccell)}{per},1);
            if VWQ == 1
                AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} = nanmean(allVTraces{VWroi}{terms(ccell)}{per},1);
            end 
            
            %remove traces that are outliers 
            %statistically (greater than 2 standard deviations from the
            %mean 
            count2 = 1; 
            count3 = 1;
            count4 = 1;
            for peak = 1:size(allCTraces{terms(ccell)}{per},1)
                    if BBBQ == 1
%                         if allBTraces{BBBroi}{terms(ccell)}{per}(peak,:) < AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} + nanstd(allBTraces{BBBroi}{terms(ccell)}{per},1)*2  & allBTraces{BBBroi}{terms(ccell)}{per}(peak,:) > AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} - nanstd(allBTraces{BBBroi}{terms(ccell)}{per},1)*2               
                            BTraces{BBBroi}{terms(ccell)}{per}(count2,:) = (allBTraces{BBBroi}{terms(ccell)}{per}(peak,:));
                            count2 = count2 + 1;
%                         end 
                    end 
%                     if allCTraces{terms(ccell)}{per}(peak,:) < AVSNCdataPeaks2{terms(ccell)}{per} + nanstd(allCTraces{terms(ccell)}{per},1)*2 & allCTraces{terms(ccell)}{per}(peak,:) > AVSNCdataPeaks2{terms(ccell)}{per} - nanstd(allCTraces{terms(ccell)}{per},1)*2                     
                        CTraces{terms(ccell)}{per}(count3,:) = (allCTraces{terms(ccell)}{per}(peak,:));
                        count3 = count3 + 1;
%                     end 
                    if VWQ == 1
%                         if allVTraces{VWroi}{terms(ccell)}{per}(peak,:) < AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} + nanstd(allVTraces{VWroi}{terms(ccell)}{per},1)*2 & allVTraces{VWroi}{terms(ccell)}{per}(peak,:) > AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} - nanstd(allVTraces{VWroi}{terms(ccell)}{per},1)*2              
                            VTraces{VWroi}{terms(ccell)}{per}(count4,:) = (allVTraces{VWroi}{terms(ccell)}{per}(peak,:));
                            count4 = count4 + 1;
%                         end 
                    end 
            end 

            %calculate the 95% confidence interval
            if BBBQ == 1
                SEMb = (nanstd(BTraces{BBBroi}{terms(ccell)}{per}))/(sqrt(size(BTraces{BBBroi}{terms(ccell)}{per},1))); % Standard Error            
                ts_bLow = tinv(0.025,size(BTraces{BBBroi}{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                ts_bHigh = tinv(0.975,size(BTraces{BBBroi}{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                CI_bLow = (nanmean(BTraces{BBBroi}{terms(ccell)}{per},1)) + (ts_bLow*SEMb);  % Confidence Intervals
                CI_bHigh = (nanmean(BTraces{BBBroi}{terms(ccell)}{per},1)) + (ts_bHigh*SEMb);  % Confidence Intervals
            end 
            
            SEMc = (nanstd(CTraces{terms(ccell)}{per}))/(sqrt(size(CTraces{terms(ccell)}{per},1))); % Standard Error            
            ts_cLow = tinv(0.025,size(CTraces{terms(ccell)}{per},1)-1);% T-Score for 95% CI
            ts_cHigh = tinv(0.975,size(CTraces{terms(ccell)}{per},1)-1);% T-Score for 95% CI
            CI_cLow = (nanmean(CTraces{terms(ccell)}{per},1)) + (ts_cLow*SEMc);  % Confidence Intervals
            CI_cHigh = (nanmean(CTraces{terms(ccell)}{per},1)) + (ts_cHigh*SEMc);  % Confidence Intervals

            if VWQ == 1
                SEMv = (nanstd(VTraces{VWroi}{terms(ccell)}{per}))/(sqrt(size(VTraces{VWroi}{terms(ccell)}{per},1))); % Standard Error            
                ts_vLow = tinv(0.025,size(VTraces{VWroi}{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                ts_vHigh = tinv(0.975,size(VTraces{VWroi}{terms(ccell)}{per},1)-1);% T-Score for 95% CI
                CI_vLow = (nanmean(VTraces{VWroi}{terms(ccell)}{per},1)) + (ts_vLow*SEMv);  % Confidence Intervals
                CI_vHigh = (nanmean(VTraces{VWroi}{terms(ccell)}{per},1)) + (ts_vHigh*SEMv);  % Confidence Intervals        
            end 
            x = 1:length(CI_cLow);

            %get averages
            if BBBQ == 1
                AVSNBdataPeaks{BBBroi}{terms(ccell)}{per} = nanmean(BTraces{BBBroi}{terms(ccell)}{per},1);
            end 
            AVSNCdataPeaks{terms(ccell)}{per} = nanmean(CTraces{terms(ccell)}{per},1);
            if VWQ == 1
                AVSNVdataPeaks{VWroi}{terms(ccell)}{per} = nanmean(VTraces{VWroi}{terms(ccell)}{per},1);
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

            %add right y axis tick marks for a specific DOD figure. 
            yyaxis right 
            if BBBQ == 1
                if isempty(AVSNBdataPeaks{BBBroi}{terms(ccell)}{per}) == 0 && isempty(CI_cLow) == 0 
                    plot(AVSNBdataPeaks{BBBroi}{terms(ccell)}{per},'r','LineWidth',4)
                    patch([x fliplr(x)],[(CI_bLow) (fliplr(CI_bHigh))],[0.5 0 0],'EdgeColor','none')
                    ylabel('BBB permeability percent change','FontName','Times')
                    tlabel = sprintf('Terminal%d_BBBroi%d.',terms(ccell),BBBroi);
                    title(sprintf('Terminal %d. BBB ROI %d.',terms(ccell),BBBroi))
        %             title('BBB permeability Spike Triggered Average')
                end 
            end 
            if VWQ == 1
                if isempty(AVSNVdataPeaks{VWroi}{terms(ccell)}{per}) == 0 && isempty(CI_cLow) == 0 
                    plot(AVSNVdataPeaks{VWroi}{terms(ccell)}{per},'k','LineWidth',4)
                    patch([x fliplr(x)],[(CI_vLow) (fliplr(CI_vHigh))],'k','EdgeColor','none')
                    ylabel('Vessel width percent change','FontName','Times')
                    tlabel = sprintf('Terminal%d_VwidthROI%d.',terms(ccell),VWroi);
        %             title(sprintf('Terminal %d. Vessel width ROI %d.',terminals(ccell),VWroi))
                    title(sprintf('Terminal %d. VW ROI %d.',terms(ccell),VWroi))
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
    elseif AVQ == 1 
        allCTraces = cell(1,length(SNCdataPeaks{1}));
        allBTraces = cell(1,length(SNCdataPeaks{1}));
        allVTraces = cell(1,length(SNCdataPeaks{1}));
        CTraces = cell(1,length(SNCdataPeaks{1}));
        BTraces = cell(1,length(SNCdataPeaks{1}));
        VTraces = cell(1,length(SNCdataPeaks{1}));
        % sort data
        for ccell = 1:length(terms)
            count = 1;
            for vid = 1:length(vidList)
               if length(sortedBdata{vid}{BBBroi}{terms(ccell)}) >= per  
                    if isempty(sortedBdata{vid}{BBBroi}{terms(ccell)}{per}) == 0 
                        for peak = 1:size(sortedBdata{vid}{BBBroi}{terms(ccell)}{per},1)
                            allBTraces{BBBroi}{terms(ccell)}{per}(count,:) = (SNBdataPeaks{vid}{BBBroi}{terms(ccell)}{per}(peak,:)-100);
                            allCTraces{terms(ccell)}{per}(count,:) = (SNCdataPeaks{vid}{terms(ccell)}{per}(peak,:)-100);
                            if VWQ == 1
                                allVTraces{VWroi}{terms(ccell)}{per}(count,:) = (SNVdataPeaks{vid}{VWroi}{terms(ccell)}{per}(peak,:)-100);  
                            end 
                            count = count + 1;
                        end 
                    end
               end               
            end 
            
            %get average of all traces 
            if BBBQ == 1
                AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} = nanmean(allBTraces{BBBroi}{terms(ccell)}{per},1);
            end 
            AVSNCdataPeaks2{terms(ccell)}{per} = nanmean(allCTraces{terms(ccell)}{per},1);
            if VWQ == 1
                AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} = nanmean(allVTraces{VWroi}{terms(ccell)}{per},1);
            end 

            %remove traces that are outliers 
            %statistically (greater than 2 standard deviations from the
            %mean )
            count2 = 1; 
            count3 = 1;
            count4 = 1;
            for peak = 1:size(allCTraces{terms(ccell)}{per},1)
                    if BBBQ == 1
                        if allBTraces{BBBroi}{terms(ccell)}{per}(peak,:) < AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} + nanstd(allBTraces{BBBroi}{terms(ccell)}{per},1)*2  & allBTraces{BBBroi}{terms(ccell)}{per}(peak,:) > AVSNBdataPeaks2{BBBroi}{terms(ccell)}{per} - nanstd(allBTraces{BBBroi}{terms(ccell)}{per},1)*2               
                            BTraces{BBBroi}{terms(ccell)}{per}(count2,:) = (allBTraces{BBBroi}{terms(ccell)}{per}(peak,:));
                            count2 = count2 + 1;
                        end 
                    end 
                    if allCTraces{terms(ccell)}{per}(peak,:) < AVSNCdataPeaks2{terms(ccell)}{per} + nanstd(allCTraces{terms(ccell)}{per},1)*2 & allCTraces{terms(ccell)}{per}(peak,:) > AVSNCdataPeaks2{terms(ccell)}{per} - nanstd(allCTraces{terms(ccell)}{per},1)*2                      
                        CTraces{terms(ccell)}(count3,:) = (allCTraces{terms(ccell)}{per}(peak,:));
                        count3 = count3 + 1;
                    end 
                    if VWQ == 1
                        if allVTraces{VWroi}{terms(ccell)}{per}(peak,:) < AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} + nanstd(allVTraces{VWroi}{terms(ccell)}{per},1)*2 & allVTraces{VWroi}{terms(ccell)}{per}(peak,:) > AVSNVdataPeaks2{VWroi}{terms(ccell)}{per} - nanstd(allVTraces{VWroi}{terms(ccell)}{per},1)*2              
                            VTraces{VWroi}{terms(ccell)}{per}(count4,:) = (allVTraces{VWroi}{terms(ccell)}{per}(peak,:));
                            count4 = count4 + 1;
                        end 
                    end 
            end 
            
            % get the average of all the traces excluding outliers 
            if BBBQ == 1 
                AVSNBdataPeaks3{BBBroi}{per}(ccell,:) = (nanmean(BTraces{BBBroi}{terms(ccell)}{per}));
            end 
            AVSNCdataPeaks3{per}(ccell,:) = nanmean(CTraces{terms(ccell)});
            if VWQ == 1
                AVSNVdataPeaks3{VWroi}{per}(ccell,:) = (nanmean(VTraces{VWroi}{terms(ccell)}{per}));
            end 
        end  

        %calculate the 95% confidence interval
        if BBBQ == 1
            SEMb = (nanstd(AVSNBdataPeaks3{BBBroi}{per}))/(sqrt(size(AVSNBdataPeaks3{BBBroi}{per},1))); % Standard Error            
            ts_bLow = tinv(0.025,size(AVSNBdataPeaks3{BBBroi}{per},1)-1);% T-Score for 95% CI
            ts_bHigh = tinv(0.975,size(AVSNBdataPeaks3{BBBroi}{per},1)-1);% T-Score for 95% CI
            CI_bLow = (nanmean(AVSNBdataPeaks3{BBBroi}{per},1)) + (ts_bLow*SEMb);  % Confidence Intervals
            CI_bHigh = (nanmean(AVSNBdataPeaks3{BBBroi}{per},1)) + (ts_bHigh*SEMb);  % Confidence Intervals
        end 
        
        SEMc = (nanstd(AVSNCdataPeaks3{per}))/(sqrt(size(AVSNCdataPeaks3{per},1))); % Standard Error            
        ts_cLow = tinv(0.025,size(AVSNCdataPeaks3{per},1)-1);% T-Score for 95% CI
        ts_cHigh = tinv(0.975,size(AVSNCdataPeaks3{per},1)-1);% T-Score for 95% CI
        CI_cLow = (nanmean(AVSNCdataPeaks3{per},1)) + (ts_cLow*SEMc);  % Confidence Intervals
        CI_cHigh = (nanmean(AVSNCdataPeaks3{per},1)) + (ts_cHigh*SEMc);  % Confidence Intervals

        if VWQ == 1
            SEMv = (nanstd(AVSNVdataPeaks3{VWroi}{per}))/(sqrt(size(AVSNVdataPeaks3{VWroi}{per},1))); % Standard Error            
            ts_vLow = tinv(0.025,size(AVSNVdataPeaks3{VWroi}{per},1)-1);% T-Score for 95% CI
            ts_vHigh = tinv(0.975,size(AVSNVdataPeaks3{VWroi}{per},1)-1);% T-Score for 95% CI
            CI_vLow = (nanmean(AVSNVdataPeaks3{VWroi}{per},1)) + (ts_vLow*SEMv);  % Confidence Intervals
            CI_vHigh = (nanmean(AVSNVdataPeaks3{VWroi}{per},1)) + (ts_vHigh*SEMv);  % Confidence Intervals        
        end 
        x = 1:length(CI_cLow);
        
        %average across terminals 
        AVSNCdataPeaks{per} = nanmean(AVSNCdataPeaks3{per});
        if BBBQ == 1
            AVSNBdataPeaks{BBBroi}{per} = nanmean(AVSNBdataPeaks3{BBBroi}{per});
        end 
        if VWQ == 1
            AVSNVdataPeaks{VWroi}{per} = nanmean(AVSNVdataPeaks3{VWroi}{per});
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
            plot(AVSNBdataPeaks{BBBroi}{per},'r','LineWidth',4)
            patch([x fliplr(x)],[(CI_bLow) (fliplr(CI_bHigh))],[0.5 0 0],'EdgeColor','none')
            ylabel('BBB permeability percent change','FontName','Times')
            tlabel = sprintf('Terminal%d_BBBroi%d.',terminals(ccell),BBBroi);
            title(sprintf('Terminals Averaged. BBB ROI %d.',BBBroi))
        end 
        if VWQ == 1
            plot(AVSNVdataPeaks{VWroi}{per},'k','LineWidth',4)
            patch([x fliplr(x)],[(CI_vLow) (fliplr(CI_vHigh))],'k','EdgeColor','none')
            ylabel('Vessel width percent change','FontName','Times')

            title(sprintf('Terminals Averaged. VW ROI %d.',VWroi))
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
end 

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%% plot calcium spike triggered average (average across mice. compare close and far terminals.) 
%{
%get the data you need 
regImDir = uigetdir('*.*','WHERE ARE THE CLOSE CALCIUM ROI VALUES?');
cd(regImDir);
MatFileName = uigetfile('*.*','GET THE CLOSE/FAR CALCIUM ROI VALUES');
Mat = matfile(MatFileName);
closeCaROIs = Mat.closeCaROIs;
farCaROIs = Mat.farCaROIs;
closeCaROI_CaBBBtimeLags = Mat.closeCaROI_CaBBBtimeLags;
farCaROI_CaBBBtimeLags = Mat.farCaROI_CaBBBtimeLags;
allCTraces = cell(1,length(closeCaROIs));
allBTraces = cell(1,length(closeCaROIs));
allVTraces = cell(1,length(closeCaROIs));
CaROIs = cell(1,length(closeCaROIs));
FPSstack = cell(1,length(closeCaROIs));
SNCdataPeaks = cell(1,length(closeCaROIs));
SNBdataPeaks = cell(1,length(closeCaROIs));
SNVdataPeaks = cell(1,length(closeCaROIs));
for mouse = 1:length(closeCaROIs)
    regImDir = uigetdir('*.*',sprintf('WHERE IS THE STA DATA FOR MOUSE #%d?',mouse));
    cd(regImDir);
    MatFileName = uigetfile('*.*',sprintf('SELECT THE STA DATA FOR MOUSE #%d',mouse));
    Mat = matfile(MatFileName);
%     FPSstack{mouse} = Mat.FPSstack;
%     allCTraces{mouse} = Mat.allCTraces;
%     SNCdataPeaks{mouse} = Mat.SNCdataPeaks;    
%     allBTraces{mouse} = Mat.allBTraces;
%     SNBdataPeaks{mouse} = Mat.SNBdataPeaks;
    allVTraces{mouse} = Mat.allVTraces;
    SNVdataPeaks{mouse} = Mat.SNVdataPeaks;    
%     CaROIs{mouse} = input(sprintf('What are the Ca ROIs for mouse #%d? ',mouse));
end 
tTypeQ = Mat.tTypeQ;

%%

%set plotting paramaters 
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

%
if tTypeQ == 1
    clear allBTraces allCTraces allVTraces
    per = input('Input 1 for blue light period. Input 2 for red light period. Input 3 for light off period. '); 
    for mouse = 1:length(closeCaROIs)
        count = 1;
        for vid = 1:length(SNBdataPeaks{mouse})
            for term = 1:length(CaROIs{mouse})
                if size(SNBdataPeaks{mouse}{vid}{BBBroi}{CaROIs{mouse}(term)},2) >= per
                    for peak = 1:size(SNBdataPeaks{mouse}{vid}{BBBroi}{CaROIs{mouse}(term)}{per},1)
                        allBTraces{mouse}{BBBroi}{CaROIs{mouse}(term)}(count,:) = (SNBdataPeaks{mouse}{vid}{BBBroi}{CaROIs{mouse}(term)}{per}(peak,:)-100);
                        allCTraces{mouse}{CaROIs{mouse}(term)}(count,:) = (SNCdataPeaks{mouse}{vid}{CaROIs{mouse}(term)}{per}(peak,:)-100);
                        if VWQ == 1
                            allVTraces{mouse}{VWroi}{CaROIs{mouse}(term)}(count,:) = (SNVdataPeaks{mouse}{vid}{VWroi}{CaROIs{mouse}(term)}{per}(peak,:)-100);  
                        end 
                        count = count + 1;
                    end 
                end 
            end 
        end 
    end
end 

%optional: remove traces that are greater than 2 standard deviations from the mean 
traceRemovalQ = input('Input 1 to statistically remove traces. Input 0 otherwise. '); 
if traceRemovalQ == 1 
    traceRemovalMice = input('Input the mice you want to statistically remove traces from? ');
    for mouse = 1:length(traceRemovalMice)
        for term = 1:length(CaROIs{traceRemovalMice(mouse)})
            if BBBQ == 1
                AVSNBdataPeaks{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(term)} = nanmean(allBTraces{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(term)});
            end 
            AVSNCdataPeaks{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(term)} = nanmean(allCTraces{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(term)});
            if VWQ == 1
                AVSNVdataPeaks{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(term)} = nanmean(allVTraces{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(term)});
            end 
            
            count2 = 1; 
            count3 = 1;
            count4 = 1;
            for peak = 1:size(allCTraces{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(term)},1)
                    if BBBQ == 1
                        if allBTraces{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(term)}(peak,:) < AVSNBdataPeaks{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(term)} + nanstd(allBTraces{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(term)},1)*2  & allBTraces{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(term)}(peak,:) > AVSNBdataPeaks{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(term)} - nanstd(allBTraces{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(term)},1)*2               
                            BTraces{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(term)}(count2,:) = (allBTraces{traceRemovalMice(mouse)}{BBBroi}{CaROIs{traceRemovalMice(mouse)}(term)}(peak,:));
                            count2 = count2 + 1;
                        end 
                    end 
                    if allCTraces{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(term)}(peak,:) < AVSNCdataPeaks{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(term)} + nanstd(allCTraces{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(term)},1)*2 & allCTraces{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(term)}(peak,:) > AVSNCdataPeaks{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(term)} - nanstd(allCTraces{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(term)},1)*2                     
                        CTraces{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(term)}(count3,:) = (allCTraces{traceRemovalMice(mouse)}{CaROIs{traceRemovalMice(mouse)}(term)}(peak,:));
                        count3 = count3 + 1;
                    end 
                    if VWQ == 1
                        if allVTraces{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(term)}(peak,:) < AVSNVdataPeaks{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(term)} + nanstd(allVTraces{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(term)},1)*2 & allVTraces{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(term)}(peak,:) > AVSNVdataPeaks{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(term)} - nanstd(allVTraces{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(term)},1)*2              
                            VTraces{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(term)}(count4,:) = (allVTraces{traceRemovalMice(mouse)}{VWroi}{CaROIs{traceRemovalMice(mouse)}(term)}(peak,:));
                            count4 = count4 + 1;
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
    end 
end 

%average the close and far terminals within each animal and plot 
closeCTraces = cell(1,length(closeCaROIs));
farCTraces = cell(1,length(closeCaROIs));
closeCTraceArray = cell(1,length(closeCaROIs));
farCTraceArray = cell(1,length(closeCaROIs));
closeBTraces = cell(1,length(closeCaROIs));
farBTraces = cell(1,length(closeCaROIs));
closeBTraceArray = cell(1,length(closeCaROIs));
farBTraceArray = cell(1,length(closeCaROIs));
closeVTraces = cell(1,length(closeCaROIs));
farVTraces = cell(1,length(closeCaROIs));
closeVTraceArray = cell(1,length(closeCaROIs));
farVTraceArray = cell(1,length(closeCaROIs));
far_AVSNBdataPeaks = cell(1,length(closeCaROIs));
far_AVSNCdataPeaks = cell(1,length(closeCaROIs));
far_AVSNVdataPeaks = cell(1,length(closeCaROIs));
close_AVSNBdataPeaks = cell(1,length(closeCaROIs));
close_AVSNCdataPeaks = cell(1,length(closeCaROIs));
close_AVSNVdataPeaks = cell(1,length(closeCaROIs));
TimingQ = input('Input 1 if you care about timing. Input 0 otherwise. ');
if TimingQ == 1
    TimingQ2 = input('Input 1 to plot positive BBB-Ca timing. Input 0 for negative. ');
end 
for mouse = 1:length(closeCaROIs)
    
    %put all similar trials together 
    if TimingQ == 0 
        closeCTraces{mouse} = allCTraces{mouse}(closeCaROIs{mouse}); 
        farCTraces{mouse} = allCTraces{mouse}(farCaROIs{mouse});
    elseif TimingQ == 1
        if TimingQ2 == 1 % find close Traces where time lag is positive 
            closeCTraces{mouse} = allCTraces{mouse}(closeCaROIs{mouse}(closeCaROI_CaBBBtimeLags{mouse} > 0));  
            farCTraces{mouse} = allCTraces{mouse}(farCaROIs{mouse}(farCaROI_CaBBBtimeLags{mouse} > 0));
        elseif TimingQ2 == 0 % find close Traces where time lag is negative 
            closeCTraces{mouse} = allCTraces{mouse}(closeCaROIs{mouse}(closeCaROI_CaBBBtimeLags{mouse} < 0));  
            farCTraces{mouse} = allCTraces{mouse}(farCaROIs{mouse}(farCaROI_CaBBBtimeLags{mouse} < 0));
        end           
    end 

    if BBBQ == 1
        closeBTraces{mouse} = allBTraces{mouse}{BBBroi}(closeCaROIs{mouse});
        farBTraces{mouse} = allBTraces{mouse}{BBBroi}(farCaROIs{mouse});
    end 
    if VWQ == 1
        closeVTraces{mouse} = allVTraces{mouse}{VWroi}(closeCaROIs{mouse});
        farVTraces{mouse} = allVTraces{mouse}{VWroi}(farCaROIs{mouse});
    end 
    if length(closeCTraces{mouse}) == 1
        closeCTraceArray{mouse} = closeCTraces{mouse}{1};
        if BBBQ == 1
            closeBTraceArray{mouse} = closeBTraces{mouse}{1};
        end 
        if VWQ == 1
            closeVTraceArray{mouse} = closeVTraces{mouse}{1};
        end 
    end 
    for closeTrace = 2:length(closeCTraces{mouse})
        if closeTrace == 2
            closeCTraceArray{mouse} = vertcat(closeCTraces{mouse}{1},closeCTraces{mouse}{closeTrace});
            if BBBQ == 1
                closeBTraceArray{mouse} = vertcat(closeBTraces{mouse}{1},closeBTraces{mouse}{closeTrace});
            end 
            if VWQ == 1
                closeVTraceArray{mouse} = vertcat(closeVTraces{mouse}{1},closeVTraces{mouse}{closeTrace});
            end 
        elseif closeTrace > 2 
            closeCTraceArray{mouse} = vertcat(closeCTraceArray{mouse},closeCTraces{mouse}{closeTrace});
            if BBBQ == 1
                closeBTraceArray{mouse} = vertcat(closeBTraceArray{mouse},closeBTraces{mouse}{closeTrace});
            end 
            if VWQ == 1
                closeVTraceArray{mouse} = vertcat(closeVTraceArray{mouse},closeVTraces{mouse}{closeTrace});
            end 
        end 
    end 
    

    if length(farCTraces{mouse}) == 1
        farCTraceArray{mouse} = farCTraces{mouse}{1};
        if BBBQ == 1
            farBTraceArray{mouse} = farBTraces{mouse}{1};
        end 
        if VWQ == 1
            farVTraceArray{mouse} = farVTraces{mouse}{1};
        end 
    end 
    for farTrace = 2:length(farCTraces{mouse})
        if farTrace == 2
            farCTraceArray{mouse} = vertcat(farCTraces{mouse}{1},farCTraces{mouse}{farTrace});
            if BBBQ == 1
                farBTraceArray{mouse} = vertcat(farBTraces{mouse}{1},farBTraces{mouse}{farTrace});
            end 
            if VWQ == 1
                farVTraceArray{mouse} = vertcat(farVTraces{mouse}{1},farVTraces{mouse}{farTrace});
            end 
        elseif farTrace > 2 
            farCTraceArray{mouse} = vertcat(farCTraceArray{mouse},farCTraces{mouse}{farTrace});
            if BBBQ == 1
                farBTraceArray{mouse} = vertcat(farBTraceArray{mouse},farBTraces{mouse}{farTrace});
            end 
            if VWQ == 1
                farVTraceArray{mouse} = vertcat(farVTraceArray{mouse},farVTraces{mouse}{farTrace});
            end 
        end 
    end 

    %DETERMINE 95% CI
    if BBBQ == 1 
        close_SEMb = (nanstd(closeBTraceArray{mouse}))/(sqrt(size(closeBTraceArray{mouse},1))); % Standard Error            
        close_ts_bLow = tinv(0.025,size(closeBTraceArray{mouse},1)-1);% T-Score for 95% CI
        close_ts_bHigh = tinv(0.975,size(closeBTraceArray{mouse},1)-1);% T-Score for 95% CI
        close_CI_bLow = (nanmean(closeBTraceArray{mouse},1)) + (close_ts_bLow*close_SEMb);  % Confidence Intervals
        close_CI_bHigh = (nanmean(closeBTraceArray{mouse},1)) + (close_ts_bHigh*close_SEMb);  % Confidence Intervals

        far_SEMb = (nanstd(farBTraceArray{mouse}))/(sqrt(size(farBTraceArray{mouse},1))); % Standard Error            
        far_ts_bLow = tinv(0.025,size(farBTraceArray{mouse},1)-1);% T-Score for 95% CI
        far_ts_bHigh = tinv(0.975,size(farBTraceArray{mouse},1)-1);% T-Score for 95% CI
        far_CI_bLow = (nanmean(farBTraceArray{mouse},1)) + (far_ts_bLow*far_SEMb);  % Confidence Intervals
        far_CI_bHigh = (nanmean(farBTraceArray{mouse},1)) + (far_ts_bHigh*far_SEMb);  % Confidence Intervals
    end 

    close_SEMc = (nanstd(closeCTraceArray{mouse}))/(sqrt(size(closeCTraceArray{mouse},1))); % Standard Error            
    close_ts_cLow = tinv(0.025,size(closeCTraceArray{mouse},1)-1);% T-Score for 95% CI
    close_ts_cHigh = tinv(0.975,size(closeCTraceArray{mouse},1)-1);% T-Score for 95% CI
    close_CI_cLow = (nanmean(closeCTraceArray{mouse},1)) + (close_ts_cLow*close_SEMc);  % Confidence Intervals
    close_CI_cHigh = (nanmean(closeCTraceArray{mouse},1)) + (close_ts_cHigh*close_SEMc);  % Confidence Intervals

    far_SEMc = (nanstd(farCTraceArray{mouse}))/(sqrt(size(farCTraceArray{mouse},1))); % Standard Error            
    far_ts_cLow = tinv(0.025,size(farCTraceArray{mouse},1)-1);% T-Score for 95% CI
    far_ts_cHigh = tinv(0.975,size(farCTraceArray{mouse},1)-1);% T-Score for 95% CI
    far_CI_cLow = (nanmean(farCTraceArray{mouse},1)) + (far_ts_cLow*far_SEMc);  % Confidence Intervals
    far_CI_cHigh = (nanmean(farCTraceArray{mouse},1)) + (far_ts_cHigh*far_SEMc);  % Confidence Intervals

    if VWQ == 1
        close_SEMv = (nanstd(closeVTraceArray{mouse}))/(sqrt(size(closeVTraceArray{mouse},1))); % Standard Error            
        close_ts_vLow = tinv(0.025,size(closeVTraceArray{mouse},1)-1);% T-Score for 95% CI
        close_ts_vHigh = tinv(0.975,size(closeVTraceArray{mouse},1)-1);% T-Score for 95% CI
        close_CI_vLow = (nanmean(closeVTraceArray{mouse},1)) + (close_ts_vLow*close_SEMv);  % Confidence Intervals
        close_CI_vHigh = (nanmean(closeVTraceArray{mouse},1)) + (close_ts_vHigh*close_SEMv);  % Confidence Intervals

        far_SEMv = (nanstd(farVTraceArray{mouse}))/(sqrt(size(farVTraceArray{mouse},1))); % Standard Error            
        far_ts_vLow = tinv(0.025,size(farVTraceArray{mouse},1)-1);% T-Score for 95% CI
        far_ts_vHigh = tinv(0.975,size(farVTraceArray{mouse},1)-1);% T-Score for 95% CI
        far_CI_vLow = (nanmean(farVTraceArray{mouse},1)) + (far_ts_vLow*far_SEMv);  % Confidence Intervals
        far_CI_vHigh = (nanmean(farVTraceArray{mouse},1)) + (far_ts_vHigh*far_SEMv);  % Confidence Intervals
    end 

    x = 1:length(close_CI_cLow);

    %get averages
    if BBBQ == 1
        close_AVSNBdataPeaks{mouse}{BBBroi} = nanmean(closeBTraceArray{mouse},1);
        far_AVSNBdataPeaks{mouse}{BBBroi} = nanmean(farBTraceArray{mouse},1);
    end 
    close_AVSNCdataPeaks{mouse} = nanmean(closeCTraceArray{mouse},1);
    far_AVSNCdataPeaks{mouse} = nanmean(farCTraceArray{mouse},1);
    if VWQ == 1
        close_AVSNVdataPeaks{mouse}{VWroi} = nanmean(closeVTraceArray{mouse},1);
        far_AVSNVdataPeaks{mouse}{VWroi} = nanmean(farVTraceArray{mouse},1);
    end 

    if isempty(close_AVSNCdataPeaks{mouse}) == 0
        % plot close Ca ROI data 
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
        if BBBQ == 1
            plot(close_AVSNBdataPeaks{mouse}{BBBroi},'r','LineWidth',4)
            patch([x fliplr(x)],[(close_CI_bLow) (fliplr(close_CI_bHigh))],[0.5 0 0],'EdgeColor','none')
            ylabel('BBB permeability percent change','FontName','Times')
            title(sprintf('Close Terminals. Mouse %d. BBB ROI %d.',mouse,BBBroi))
    %             title('BBB permeability Spike Triggered Average')
        end 
        if VWQ == 1
            plot(close_AVSNVdataPeaks{mouse}{VWroi},'k','LineWidth',4)
            patch([x fliplr(x)],[(close_CI_vLow) (fliplr(close_CI_vHigh))],'k','EdgeColor','none')
            ylabel('Vessel width percent change','FontName','Times')
            title(sprintf('Close Terminals. Mouse %d. VW ROI %d.',mouse,VWroi))
    %             title(sprintf('Terminal %d. Vessel width ROI %d.',terminals(ccell),VWroi))
            title(sprintf('Close Terminals. Mouse %d. VW ROI %d.',mouse,VWroi))
        end 
        alpha(0.3)
        set(gca,'YColor',[0 0 0]);       

        % plot far Ca ROI data 
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
        if BBBQ == 1
            plot(far_AVSNBdataPeaks{mouse}{BBBroi},'r','LineWidth',4)
            patch([x fliplr(x)],[(far_CI_bLow) (fliplr(far_CI_bHigh))],[0.5 0 0],'EdgeColor','none')
            ylabel('BBB permeability percent change','FontName','Times')
            title(sprintf('Far Terminals. Mouse %d. BBB ROI %d.',mouse,BBBroi))
    %             title('BBB permeability Spike Triggered Average')
        end 
        if VWQ == 1
            plot(far_AVSNVdataPeaks{mouse}{VWroi},'k','LineWidth',4)
            patch([x fliplr(x)],[(far_CI_vLow) (fliplr(far_CI_vHigh))],'k','EdgeColor','none')
            ylabel('Vessel width percent change','FontName','Times')
            title(sprintf('Far Terminals. Mouse %d. VW ROI %d.',mouse,VWroi))
    %             title(sprintf('Terminal %d. Vessel width ROI %d.',terminals(ccell),VWroi))
            title(sprintf('Far Terminals. Mouse %d. VW ROI %d.',mouse,VWroi))
        end 
        alpha(0.3)
        set(gca,'YColor',[0 0 0]);               
    end 
end 

%% AVERAGE ACROSS MICE 
clear close_Btraces_allMice far_Btraces_allMice close_Ctraces_allMice far_Ctraces_allMice close_Vtraces_allMice far_Vtraces_allMice   

% resample data (closeBTraceArray)
FPSstack2 = zeros(1,length(FPSstack));
for mouse = 1:length(FPSstack)
    FPSstack2(mouse) = FPSstack{mouse};
end 
minFPSstack = FPSstack2 == min(FPSstack2);
idx = find(minFPSstack ~= 0, 1, 'first');
minLen = length(close_AVSNCdataPeaks{idx});

% mouseNums = [1,2,3,4,5];
mouseNums = input('Input the mice you want to average. ');
counter1 = 1;
counter2 = 1;
counter3 = 1;
counter4 = 1;
counter5 = 1;
counter6 = 1;
if BBBQ == 1
    closeBtrace_nums = zeros(1,length(mouseNums));
    farBtrace_nums = zeros(1,length(mouseNums));
end 
closeCtrace_nums = zeros(1,length(mouseNums));
farCtrace_nums = zeros(1,length(mouseNums));
if VWQ == 1
    closeVtrace_nums = zeros(1,length(mouseNums));
    farVtrace_nums = zeros(1,length(mouseNums));
end 
for mouse = 1:length(mouseNums)
    if BBBQ == 1
         closeBtrace_nums(mouse) = size(closeBTraceArray{mouseNums(mouse)},1);
         farBtrace_nums(mouse) = size(farBTraceArray{mouseNums(mouse)},1);
    end 
     closeCtrace_nums(mouse) = size(closeCTraceArray{mouseNums(mouse)},1);
     farCtrace_nums(mouse) = size(farCTraceArray{mouseNums(mouse)},1);
     if VWQ == 1
         closeVtrace_nums(mouse) = size(closeVTraceArray{mouseNums(mouse)},1);
         farVtrace_nums(mouse) = size(farVTraceArray{mouseNums(mouse)},1);
     end 
end 
if BBBQ == 1
    totalNum_closeBtraces = sum(closeBtrace_nums);
    totalNum_farBtraces = sum(farBtrace_nums);
end 
totalNum_closeCtraces = sum(closeCtrace_nums);
totalNum_farCtraces = sum(farCtrace_nums);
if VWQ == 1
    totalNum_closeVtraces = sum(closeVtrace_nums);
    totalNum_farVtraces = sum(farVtrace_nums);
end 
for mouse = 1:length(mouseNums)   
    %resample, scale by number of traces, and sort data
    if BBBQ == 1
        for trace1 = 1:size(closeBTraceArray{mouseNums(mouse)},1)
            close_Btraces_allMice(counter1,:) = (resample(closeBTraceArray{mouseNums(mouse)}(trace1,:),minLen,size(closeBTraceArray{mouseNums(mouse)},2))) * (size(closeBTraceArray{mouseNums(mouse)},1)/totalNum_closeBtraces);           
            counter1 = counter1 + 1;
        end 
        for trace1 = 1:size(farBTraceArray{mouseNums(mouse)},1)
            far_Btraces_allMice(counter2,:) = resample(farBTraceArray{mouseNums(mouse)}(trace1,:),minLen,size(farBTraceArray{mouseNums(mouse)},2)) * (size(farBTraceArray{mouseNums(mouse)},1)/totalNum_farBtraces);  
            counter2 = counter2 + 1;
        end 
    end 
    for trace2 = 1:size(closeCTraceArray{mouseNums(mouse)},1)
        close_Ctraces_allMice(counter3,:) = (resample(closeCTraceArray{mouseNums(mouse)}(trace2,:),minLen,size(closeCTraceArray{mouseNums(mouse)},2)));% * (size(closeCTraceArray{mouseNums(mouse)},1)/totalNum_closeCtraces);           
        counter3 = counter3 + 1;
    end 
    for trace2 = 1:size(farCTraceArray{mouseNums(mouse)},1)
        far_Ctraces_allMice(counter4,:) = resample(farCTraceArray{mouseNums(mouse)}(trace2,:),minLen,size(farCTraceArray{mouseNums(mouse)},2));% * (size(farCTraceArray{mouseNums(mouse)},1)/totalNum_farCtraces);  
        counter4 = counter4 + 1;
    end         
    if VWQ == 1
        for trace3 = 1:size(closeVTraceArray{mouseNums(mouse)},1)
            close_Vtraces_allMice(counter5,:) = (resample(closeVTraceArray{mouseNums(mouse)}(trace3,:),minLen,size(closeVTraceArray{mouseNums(mouse)},2)));% * (size(closeVTraceArray{mouseNums(mouse)},1)/totalNum_closeVtraces);           
            counter5 = counter5 + 1;
        end 
        for trace3 = 1:size(farVTraceArray{mouseNums(mouse)},1)
            far_Vtraces_allMice(counter6,:) = resample(farVTraceArray{mouseNums(mouse)}(trace3,:),minLen,size(farVTraceArray{mouseNums(mouse)},2));% * (size(farVTraceArray{mouseNums(mouse)},1)/totalNum_farVtraces);  
            counter6 = counter6 + 1;
        end 
    end 
end 

%average the data 
if BBBQ == 1
    close_avBdata = nanmean(close_Btraces_allMice,1);
    far_avBdata = nanmean(far_Btraces_allMice,1);
end 
close_avCdata = nanmean(close_Ctraces_allMice,1);
far_avCdata = nanmean(far_Ctraces_allMice,1);
if VWQ == 1
    close_avVdata = nanmean(close_Vtraces_allMice,1);
    far_avVdata = nanmean(far_Vtraces_allMice,1);
end 

%DETERMINE 95% CI
if BBBQ == 1 
    close_SEMb = (nanstd(close_Btraces_allMice))/(sqrt(size(close_Btraces_allMice,1))); % Standard Error            
    close_ts_bLow = tinv(0.025,size(close_Btraces_allMice,1)-1);% T-Score for 95% CI
    close_ts_bHigh = tinv(0.975,size(close_Btraces_allMice,1)-1);% T-Score for 95% CI
    close_CI_bLow = (nanmean(close_Btraces_allMice,1)) + (close_ts_bLow*close_SEMb);  % Confidence Intervals
    close_CI_bHigh = (nanmean(close_Btraces_allMice,1)) + (close_ts_bHigh*close_SEMb);  % Confidence Intervals        
    far_SEMb = (nanstd(far_Btraces_allMice))/(sqrt(size(far_Btraces_allMice,1))); % Standard Error            
    far_ts_bLow = tinv(0.025,size(far_Btraces_allMice,1)-1);% T-Score for 95% CI
    far_ts_bHigh = tinv(0.975,size(far_Btraces_allMice,1)-1);% T-Score for 95% CI
    far_CI_bLow = (nanmean(far_Btraces_allMice,1)) + (far_ts_bLow*far_SEMb);  % Confidence Intervals
    far_CI_bHigh = (nanmean(far_Btraces_allMice,1)) + (far_ts_bHigh*far_SEMb);  % Confidence Intervals
end 
close_SEMc = (nanstd(close_Ctraces_allMice))/(sqrt(size(close_Ctraces_allMice,1))); % Standard Error            
close_ts_cLow = tinv(0.025,size(close_Ctraces_allMice,1)-1);% T-Score for 95% CI
close_ts_cHigh = tinv(0.975,size(close_Ctraces_allMice,1)-1);% T-Score for 95% CI
close_CI_cLow = (nanmean(close_Ctraces_allMice,1)) + (close_ts_cLow*close_SEMc);  % Confidence Intervals
close_CI_cHigh = (nanmean(close_Ctraces_allMice,1)) + (close_ts_cHigh*close_SEMc);  % Confidence Intervals   
far_SEMc = (nanstd(far_Ctraces_allMice))/(sqrt(size(far_Ctraces_allMice,1))); % Standard Error            
far_ts_cLow = tinv(0.025,size(far_Ctraces_allMice,1)-1);% T-Score for 95% CI
far_ts_cHigh = tinv(0.975,size(far_Ctraces_allMice,1)-1);% T-Score for 95% CI
far_CI_cLow = (nanmean(far_Ctraces_allMice,1)) + (far_ts_cLow*far_SEMc);  % Confidence Intervals
far_CI_cHigh = (nanmean(far_Ctraces_allMice,1)) + (far_ts_cHigh*far_SEMc);  % Confidence Intervals
if VWQ == 1
    close_SEMv = (nanstd(close_Vtraces_allMice))/(sqrt(size(close_Vtraces_allMice,1))); % Standard Error            
    close_ts_vLow = tinv(0.025,size(close_Vtraces_allMice,1)-1);% T-Score for 95% CI
    close_ts_vHigh = tinv(0.975,size(close_Vtraces_allMice,1)-1);% T-Score for 95% CI
    close_CI_vLow = (nanmean(close_Vtraces_allMice,1)) + (close_ts_vLow*close_SEMv);  % Confidence Intervals
    close_CI_vHigh = (nanmean(close_Vtraces_allMice,1)) + (close_ts_vHigh*close_SEMv);  % Confidence Intervals      
    far_SEMv = (nanstd(far_Vtraces_allMice))/(sqrt(size(far_Vtraces_allMice,1))); % Standard Error            
    far_ts_vLow = tinv(0.025,size(far_Vtraces_allMice,1)-1);% T-Score for 95% CI
    far_ts_vHigh = tinv(0.975,size(far_Vtraces_allMice,1)-1);% T-Score for 95% CI
    far_CI_vLow = (nanmean(far_Vtraces_allMice,1)) + (far_ts_vLow*far_SEMv);  % Confidence Intervals
    far_CI_vHigh = (nanmean(far_Vtraces_allMice,1)) + (far_ts_vHigh*far_SEMv);  % Confidence Intervals
end 
x = 1:length(close_CI_cLow);

% plot close Ca ROI data (all mice averaged) 
fig = figure;
Frames = minLen;
Frames_pre_stim_start = -((Frames-1)/2); 
Frames_post_stim_start = (Frames-1)/2; 
sec_TimeVals = floor(((Frames_pre_stim_start:min(FPSstack2):Frames_post_stim_start)/min(FPSstack2)))+1; %min(FPSstack)
FrameVals = round((1:min(FPSstack2):Frames))+5; 
ax=gca;
hold all
plot(close_avCdata,'b','LineWidth',4)
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
ylim([-10 50])
patch([x fliplr(x)],[close_CI_cLow fliplr(close_CI_cHigh)],[0 0 0.5],'EdgeColor','none')
set(fig,'position', [500 100 900 800])
alpha(0.3)
%add right y axis tick marks for a specific DOD figure. 
yyaxis right 
if BBBQ == 1
    plot(close_avBdata,'r','LineWidth',4)
    patch([x fliplr(x)],[(close_CI_bLow) (fliplr(close_CI_bHigh))],[0.5 0 0],'EdgeColor','none')
    ylabel('BBB permeability percent change','FontName','Times')
    title(sprintf('Close Terminals. All mice Averaged. BBB ROI %d.',BBBroi))
    ylim([-1 4])
end 
if VWQ == 1
    plot(close_avVdata,'k','LineWidth',4)
    patch([x fliplr(x)],[(close_CI_vLow) (fliplr(close_CI_vHigh))],'k','EdgeColor','none')
    ylabel('Vessel width percent change','FontName','Times')
    title(sprintf('Close Terminals. All mice Averaged. VW ROI %d.',VWroi))
    ylim([-0.01 0.02])
end 
alpha(0.3)
set(gca,'YColor',[0 0 0]);     

% plot far Ca ROI data (all mice averaged) 
fig = figure;
Frames = minLen;
Frames_pre_stim_start = -((Frames-1)/2); 
Frames_post_stim_start = (Frames-1)/2; 
sec_TimeVals = floor(((Frames_pre_stim_start:min(FPSstack2):Frames_post_stim_start)/min(FPSstack2)))+1; %min(FPSstack)
FrameVals = round((1:min(FPSstack2):Frames))+5; 
ax=gca;
hold all
plot(far_avCdata,'b','LineWidth',4)
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
ylim([-10 50])
patch([x fliplr(x)],[far_CI_cLow fliplr(far_CI_cHigh)],[0 0 0.5],'EdgeColor','none')
set(fig,'position', [500 100 900 800])
alpha(0.3)
%add right y axis tick marks for a specific DOD figure. 
yyaxis right 
if BBBQ == 1
    plot(far_avBdata,'r','LineWidth',4)
    patch([x fliplr(x)],[(far_CI_bLow) (fliplr(far_CI_bHigh))],[0.5 0 0],'EdgeColor','none')
    ylabel('BBB permeability percent change','FontName','Times')
    title(sprintf('Far Terminals. All mice Averaged. BBB ROI %d.',BBBroi))
%             title('BBB permeability Spike Triggered Average')
    ylim([-1 4])
end 
if VWQ == 1
    plot(far_avVdata,'k','LineWidth',4)
    patch([x fliplr(x)],[(far_CI_vLow) (fliplr(far_CI_vHigh))],'k','EdgeColor','none')
    ylabel('Vessel width percent change','FontName','Times')
    title(sprintf('Far Terminals. All mice Averaged. VW ROI %d.',VWroi))
    ylim([-0.01 0.02])
end 
alpha(0.3)
set(gca,'YColor',[0 0 0]);     
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
    ax.FontName = 'Times';
%     xlabel({'Distance From Where Vessel';'Branches (microns)'},'FontName','Times')
    xlabel('Distance From  Vessel (microns)','FontName','Times')
    ylabel('Number of Terminals','FontName','Times')
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
closeCaROI_CaBBBtimeLags = cell(1,mouseNum);
farCaROIs = cell(1,mouseNum);
farCaROIDists = cell(1,mouseNum);
farCaROI_CaBBBtimeLags = cell(1,mouseNum);
for mouse = 1:mouseNum
    closeCaROIs{mouse} = mouseTerms{mouse}((minDistsMicrons{mouse} < distCutOff));
    closeCaROIDists{mouse} = minDistsMicrons{mouse}((minDistsMicrons{mouse} < distCutOff));
    closeCaROI_CaBBBtimeLags{mouse} = maxBBBvalTimePoints{mouse}((minDistsMicrons{mouse} < distCutOff));
    farCaROIs{mouse} = mouseTerms{mouse}((minDistsMicrons{mouse} > distCutOff));
    farCaROIDists{mouse} = minDistsMicrons{mouse}((minDistsMicrons{mouse} > distCutOff));
    farCaROI_CaBBBtimeLags{mouse} = maxBBBvalTimePoints{mouse}((minDistsMicrons{mouse} > distCutOff));
end 
clearvars -except closeCaROIs closeCaROIDists closeCaROI_CaBBBtimeLags farCaROIs farCaROIDists farCaROI_CaBBBtimeLags
%}