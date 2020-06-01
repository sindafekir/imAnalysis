% get the data you need 
%REMOVE THE CODE THAT GETS TTYPE DATA BECAUSE WE ONLY NEED THE FULL EXP
%DATA - THIS CODE SEPARATES DATA INTO TTYPE BELOW - THIS IS BETTER SO THE
%SAME DATA GETS USED FOR EVERYTHING 
%{
% get calcium data 
% vidList = [1,2,3,4,5,7]; %SF56
vidList = [1,2,3,4,5,6]; %SF57
tData = cell(1,length(vidList));
cDataFullTrace = cell(1,length(vidList));
for vid = 1:length(vidList)
%     temp1 = matfile(sprintf('SF56_20190718_ROI2_%d_Fdata_termTtype.mat',vidList(vid)));
    temp1 = matfile(sprintf('SF57_20190717_ROI1_%d_Fdata.mat',vidList(vid)));
    tData{vid} = temp1.GtTdataTerm;  
    cDataFullTrace{vid} = temp1.CcellData;  
end 
FPSstack = temp1.FPSstack;
framePeriod = temp1.framePeriod;
state = 8;
terminals = [13,20,12,16,11,15,10,8,9,7,4]; %SF56
% terminals = [17,15,12,10,8,7,6,5,4,3]; %SF57

% get vessel width and BBB full exp traces
% bDataFullTrace = cell(1,length(vidList));
vDataFullTrace = cell(1,length(vidList));
for vid = 1:length(vidList)
%     temp2 = matfile(sprintf('SF56_20190718_ROI2_%d_CVBdata_F-SB_terminalWOnoiseFloor_CaPeakAlignedData.mat',vidList(vid)));
%     temp2 = matfile(sprintf('SF56_20190718_ROI2_%d_Vdata.mat',vidList(vid)));
    temp2 = matfile(sprintf('SF56_20190718_ROI2_%d_Vdata_V2.mat',vidList(vid)));       
    vDataFullTrace{vid} = temp2.Vdata; 
%     bDataFullTrace{vid} = Bdata(1:length(vDataFullTrace{vid})); 
end 

%get vessel width and BBB trial type data
% temp3 = matfile('SF56_20190718_ROI2_1-5_7_10_BBB.mat');
% Bdata = temp3.dataToPlot;
% 
% temp4 = matfile('SF56_20190718_ROI2_1-3_5_7_VW.mat');
% Vdata = temp4.dataToPlot;

%get ROI indices
% temp5 = matfile('SF56_20190718_ROI2_1-3_5_7_VW_and_1-5_7_10CaData.mat');
temp5 = matfile('SF57_20190717_DAca_V1-3.mat');
ROIinds = temp5.ROIinds;

% get trial type data 
TrialTypes = cell(1,length(vidList));
state_start_f = cell(1,length(vidList));
state_end_f = cell(1,length(vidList));
trialLengths = cell(1,length(vidList));
for vid = 1:length(vidList)
    [~,stateStartF,stateEndF,FPS,vel_wheel_data,TrialType] = makeHDFchart_redBlueStim(state,framePeriod);
    TrialTypes{vid} = TrialType(1:length(stateStartF),:);
    state_start_f{vid} = floor(stateStartF/3);
    state_end_f{vid} = floor(stateEndF/3);
    trialLengths{vid} = state_end_f{vid} - state_start_f{vid};
    
    %make sure the trial lengths are the same per trial type 
    %set ideal trial lengths 
    lenT1 = floor(FPSstack*2); % 2 second trials 
    lenT2 = floor(FPSstack*20); % 20 second trials 
    %identify current trial lengths 
    [kIdx,kMeans] = kmeans(trialLength{vid},2);
    %edit kMeans list so trialLengths is what they should be 
    for len = 1:length(kMeans)
        if kMeans(len)-lenT1 < abs(kMeans(len)-lenT2)
            kMeans(len) = lenT1;
        elseif kMeans(len)-lenT1 > abs(kMeans(len)-lenT2)
            kMeans(len) = lenT2;
        end 
    end 
    %change state_end_f so all trial lengths match up 
    for trial = 1:length(state_start_f{vid})
        state_end_f{vid}(trial,1) = state_start_f{vid}(trial)+kMeans(kIdx(trial));
    end 
    trialLength{vid} = state_end_f{vid} - state_start_f{vid};   
end 

% get red and green channel image stacks 
redStacks = cell(1,length(vidList));
for vid = 1:length(vidList)
    temp6 = matfile(sprintf('SF56_20190718_ROI2_%d_CVBdata_F-SB_terminalWOnoiseFloor_CaPeakAlignedData.mat',vidList(vid)));
    redStacks{vid} = temp6.inputStacks;
end 

greenStacks = cell(1,length(vidList));
Zstacks = cell(1,length(vidList));
imArrays = cell(1,length(vidList));
for vid = 1:length(vidList)
    temp6 = matfile(sprintf('SF56_20190718_ROI2_%d_regIms_green.mat',vidList(vid)));
    Zstack = temp6.regStacks;
    Zstacks{vid} = Zstack{2,3};
    for Z = 1:size(Zstacks{vid},2)
        imArrays{vid}(:,:,:,Z) = Zstacks{vid}{Z};
    end 
    greenStacks{vid} = mean(imArrays{vid},4);
end 
%}
%% reorganize trial data 
%REMOVE THIS IS NOW OBSOLETE 
%{
Cdata = cell(1,length(tData{1}{1}));
for term = 1:length(tData{1}{1})
    for tType = 1:length(tData{1})
        trial2 = 1; 
        for vid = 1:length(tData)            
            if isempty(tData{vid}{tType}) == 0 
                for trial = 1:size(tData{vid}{tType}{term},1)
                    Cdata{term}{tType}(trial2,:) = tData{vid}{tType}{term}(trial,:); 
                    trial2 = trial2 + 1;
                end 
            end             
        end 
    end 
end 

%average across z and different vessel segments 
VdataNoROIarray = cell(1,length(Vdata));
VdataNoROI = cell(1,length(Vdata));
VdataNoZ = cell(1,length(Bdata));
VdataNoZarray = cell(1,length(Bdata));
for tType = 1:length(Bdata) 
    for z = 1:length(Vdata)        
        for ROI = 1:length(Vdata{z})   
            for trial = 1:length(Vdata{z}{ROI}{tType})
                VdataNoROIarray{z}{tType}{trial}(ROI,:) = Vdata{z}{ROI}{tType}{trial};             
                VdataNoROI{z}{tType}{trial} = nanmean(VdataNoROIarray{z}{tType}{trial},1);
                VdataNoZarray{tType}{trial}(z,:) = VdataNoROI{z}{tType}{trial};                
                VdataNoZ{tType}{trial} = nanmean(VdataNoZarray{tType}{trial},1);
            end
        end 
        
    end 
end 
clear Vdata 
Vdata = VdataNoZ;

%resample if you need to
for tType = 1:length(Bdata)
    for trial = 1:length(Bdata{tType})
        if length(Cdata{1}{tType}) ~= length(Bdata{tType}{trial})
            Bdata{tType}{trial} = resample(Bdata{tType}{trial},length(Cdata{1}{tType}),length(Bdata{tType}{trial}));
        end 
    end 
    for trial = 1:length(Vdata{tType})
        if length(Cdata{1}{tType}) ~= length(Vdata{tType}{trial})
            Vdata{tType}{trial} = resample(Vdata{tType}{trial},length(Cdata{1}{tType}),length(Vdata{tType}{trial}));
        end 
    end 
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

%determine plotting start and end frames 
plotStart = cell(1,length(cDataFullTrace));
plotEnd = cell(1,length(cDataFullTrace));
for vid = 1:length(cDataFullTrace)
    count = 1;
    for trial = 1:length(trialLengths{vid})                       
        if dataParseType == 0    
            if (state_start_f{vid}(trial) - floor(sec_before_stim_start*FPSstack)) > 0 && state_end_f{vid}(trial) + floor(sec_after_stim_end*FPSstack) < length(cDataFullTrace{vid}{terminals(ccell)})
                plotStart{vid}(count) = state_start_f{vid}(trial) - floor(sec_before_stim_start*FPSstack);
                plotEnd{vid}(count) = state_end_f{vid}(trial) + floor(sec_after_stim_end*FPSstack);
                count = count + 1;
            end            
        elseif dataParseType == 1  
            plotStart{vid}(count) = state_start_f{vid}(trial);
            plotEnd{vid}(count) = state_end_f{vid}(trial);
            count = count + 1;
        end    
    end 
end 

%sort the data             
Ceta = cell(1,length(cDataFullTrace{1}));
Beta = cell(1,numTtypes);
Veta = cell(1,numTtypes);
for ccell = 1:length(terminals)
    count1 = 1;
    count2 = 1;
    count3 = 1;
    count4 = 1;
    for vid = 1:length(cDataFullTrace)    
        for trial = 1:length(plotStart{vid})        
            %if the blue light is on
            if TrialTypes{vid}(trial,2) == 1
                %if it is a 2 sec trial 
                if trialLengths{vid}(trial) == lenT1      
                    Ceta{terminals(ccell)}{1}(count1,:) = cDataFullTrace{vid}{terminals(ccell)}(plotStart{vid}(trial):plotEnd{vid}(trial));
                    Beta{1}(count1,:) = bDataFullTrace{vid}(plotStart{vid}(trial):plotEnd{vid}(trial));
                    Veta{1}(count1,:) = vDataFullTrace{vid}(plotStart{vid}(trial):plotEnd{vid}(trial));
                    count1 = count1 + 1;                    
                %if it is a 20 sec trial
                elseif trialLengths{vid}(trial) == lenT2
                    Ceta{terminals(ccell)}{2}(count2,:) = cDataFullTrace{vid}{terminals(ccell)}(plotStart{vid}(trial):plotEnd{vid}(trial));
                    Beta{2}(count1,:) = bDataFullTrace{vid}(plotStart{vid}(trial):plotEnd{vid}(trial));
                    Veta{2}(count1,:) = vDataFullTrace{vid}(plotStart{vid}(trial):plotEnd{vid}(trial));
                    count2 = count2 + 1;
                end 
            %if the red light is on 
            elseif TrialTypes{vid}(trial,2) == 2
                %if it is a 2 sec trial 
                if trialLengths{vid}(trial) == lenT1 
                    Ceta{terminals(ccell)}{3}(count3,:) = cDataFullTrace{vid}{terminals(ccell)}(plotStart{vid}(trial):plotEnd{vid}(trial));
                    Beta{3}(count1,:) = bDataFullTrace{vid}(plotStart{vid}(trial):plotEnd{vid}(trial));
                    Veta{3}(count1,:) = vDataFullTrace{vid}(plotStart{vid}(trial):plotEnd{vid}(trial));
                    count3 = count3 + 1;                    
                %if it is a 20 sec trial
                elseif trialLengths{vid}(trial) == lenT2
                    Ceta{terminals(ccell)}{4}(count4,:) = cDataFullTrace{vid}{terminals(ccell)}(plotStart{vid}(trial):plotEnd{vid}(trial));
                    Beta{4}(count1,:) = bDataFullTrace{vid}(plotStart{vid}(trial):plotEnd{vid}(trial));
                    Veta{4}(count1,:) = vDataFullTrace{vid}(plotStart{vid}(trial):plotEnd{vid}(trial));
                    count4 = count4 + 1;
                end             
            end 
        end         
    end
end 

%remove rows that are all 0 and then add 100 to each trace to avoid
%negative going values 
for tType = 1:numTtypes
    for ccell = 1:length(terminals)    
        nonZeroRowsC = all(Ceta{terminals(ccell)}{tType} == 0,2);
        Ceta{terminals(ccell)}{tType}(nonZeroRowsC,:) = NaN;
        Ceta{terminals(ccell)}{tType} = Ceta{terminals(ccell)}{tType} + 100;
    end 
    nonZeroRowsB = all(Beta{tType} == 0,2);
    Beta{tType}(nonZeroRowsB,:) = NaN;
    Beta{tType} = Beta{tType} + 100;
    nonZeroRowsV = all(Veta{tType} == 0,2);
    Veta{tType}(nonZeroRowsV,:) = NaN;
    Veta{tType} = Veta{tType} + 100;
end 
%}
%% baseline if plotting peristimulus data then smooth trial data if you want
%{
%baseline data to average value between 0 sec and -2 sec (0 sec being stim
%onset) 
nCeta = cell(1,length(cDataFullTrace{1}));
nBeta = cell(1,numTtypes);
nVeta = cell(1,numTtypes);
if dataParseType == 0 %peristimulus data to plot 
    %sec_before_stim_start
    for tType = 1:numTtypes
        for ccell = 1:length(terminals)
            nCeta{terminals(ccell)}{tType} = (Ceta{terminals(ccell)}{tType} ./ mean(Ceta{terminals(ccell)}{tType}(:,floor((sec_before_stim_start-2)*FPSstack):floor(sec_before_stim_start*FPSstack)),2))*100; 
        end 
        nBeta{tType} = (Beta{tType} ./ nanmean(Beta{tType}(:,floor((sec_before_stim_start-2)*FPSstack):floor(sec_before_stim_start*FPSstack)),2))*100; 
        nVeta{tType} = (Veta{tType} ./ nanmean(Veta{tType}(:,floor((sec_before_stim_start-2)*FPSstack):floor(sec_before_stim_start*FPSstack)),2))*100; 
    end 
    
elseif dataParseType == 1 %only stimulus data to plot 
    nCeta = Ceta;
    nBeta = Beta;
    nVeta = Veta;
end 

smoothQ =  input('Do you want to smooth your data? Yes = 1. No = 0. ');
if smoothQ ==  1
    filtTime = input('How many seconds do you want to smooth your data by? ');
    nsCeta = cell(1,length(cDataFullTrace{1}));
    nsBeta = cell(1,numTtypes);
    nsVeta = cell(1,numTtypes);
    for tType = 1:numTtypes
        for ccell = 1:length(terminals)
            for cTrial = 1:size(nCeta{terminals(ccell)}{tType},1)
                [sC_Data] = MovMeanSmoothData(nCeta{terminals(ccell)}{tType}(cTrial,:),filtTime,FPSstack);
                nsCeta{terminals(ccell)}{tType}(cTrial,:) = sC_Data-100;
            end 
        end 
        for vTrial = 1:size(nBeta{tType},1)
            [sB_Data] = MovMeanSmoothData(nBeta{tType}(vTrial,:),filtTime,FPSstack);
            nsBeta{tType}(vTrial,:) = sB_Data-100;
            [sV_Data] = MovMeanSmoothData(nVeta{tType}(vTrial,:),filtTime,FPSstack);
            nsVeta{tType}(vTrial,:) = sV_Data-100;            
        end 
    end 
elseif smoothQ == 0
    nsCeta = cell(1,length(cDataFullTrace{1}));
    nsBeta = cell(1,numTtypes);
    nsVeta = cell(1,numTtypes);
    for tType = 1:numTtypes
        for ccell = 1:length(terminals)
            nsCeta{terminals(ccell)}{tType} = nCeta{terminals(ccell)}{tType}-100;
        end 
        nsBeta{tType} = nBeta{tType}-100;
        nsVeta{tType} = nVeta{tType}-100;
    end 
end 
%}
%% plot event triggered averages per terminal 
%{
%average across all terminals
%THIS IS TEMPORARY CODE - NEED TO EVENTUALLY EDIT THE AVERAGE PLOTTING CODE
%TWO SECTIONS DOWN 
allNScETA = cell(1,length(nsCeta));
for tType = 1:numTtypes
    count = 1;
    for ccell = 3%1:length(terminals)
%     SEMdata = cell(1,length(nsCeta{1}));
        if isempty(nsCeta{terminals(ccell)}{tType}) == 0    
            for trial = 1:size(nsCeta{terminals(ccell)}{tType},1)
                allNScETA{terminals(1)}{tType}(count,:) = nsCeta{terminals(ccell)}{tType}(trial,:);
                count = count + 1;
            end 
        end 
    end 
end 

%average all the red light trials together (2 and 20 second trials) 
redTrialTtypeInds = [3,4]; %THIS IS CURRENTLY HARD CODED IN, BUT DOESN'T HAVE TO BE. REPLACE EVENTUALLY.
allRedNScETA = cell(1,length(nsCeta));
allRedNSbETA = cell(1,numTtypes);
count = 1; 
countB = 1;
for tType = 1:length(redTrialTtypeInds)    
    for trial = 1:size(allNScETA{terminals(1)}{redTrialTtypeInds(tType)},1)
        allRedNScETA{terminals(1)}{3}(count,:) = allNScETA{terminals(1)}{redTrialTtypeInds(tType)}(trial,1:469); 
        count = count + 1;
    end 
    for Btrial = 1:size(nsBeta{redTrialTtypeInds(tType)},1)
        allRedNSbETA{3}(countB,:) = nsBeta{redTrialTtypeInds(tType)}(Btrial,1:469);
        countB = countB + 1;
    end 
end 

%allRedNScETA is taking the place of nsCeta

for ccell = 1%:length(terminals)
    baselineEndFrame = floor(20*(FPSstack));
    AVcData = cell(1,length(nsCeta{terminals(ccell)}{tType}));
    AVbData = cell(1,length(nsCeta{terminals(ccell)}{tType}));
    AVvData = cell(1,length(nsCeta{terminals(ccell)}{tType}));
    SEMb = cell(1,numTtypes);
    STDb = cell(1,numTtypes);
    CI_bLow = cell(1,numTtypes);
    CI_bHigh = cell(1,numTtypes);
    SEMc = cell(1,numTtypes);
    STDc = cell(1,numTtypes);
    CI_cLow = cell(1,numTtypes);
    CI_cHigh = cell(1,numTtypes);
%     fig = figure;
    for tType = 3%:4%1:numTtypes
%     SEMdata = cell(1,length(nsCeta{1}));
        if isempty(nsCeta{terminals(ccell)}{tType}) == 0          
            % calculate the 95% confidence interval 
            SEMb{tType} = (nanstd(allRedNSbETA{tType}))/(sqrt(size(allRedNSbETA{tType},1))); % Standard Error            
            STDb{tType} = nanstd(allRedNSbETA{tType});
            ts_bLow = tinv(0.025,size(allRedNSbETA{tType},1)-1);% T-Score for 95% CI
            ts_bHigh = tinv(0.975,size(allRedNSbETA{tType},1)-1);% T-Score for 95% CI
            CI_bLow{tType} = (nanmean(allRedNSbETA{tType},1)) + (ts_bLow*SEMb{tType});  % Confidence Intervals
            CI_bHigh{tType} = (nanmean(allRedNSbETA{tType},1)) + (ts_bHigh*SEMb{tType});  % Confidence Intervals
            
            SEMc{terminals(ccell)}{tType} = (nanstd(nsCeta{terminals(ccell)}{tType}))/(sqrt(size(nsCeta{terminals(ccell)}{tType},1))); % Standard Error            
            STDc{terminals(ccell)}{tType} = nanstd(nsCeta{terminals(ccell)}{tType});
            ts_cLow = tinv(0.025,size(nsCeta{terminals(ccell)}{tType},1)-1);% T-Score for 95% CI
            ts_cHigh = tinv(0.975,size(nsCeta{terminals(ccell)}{tType},1)-1);% T-Score for 95% CI
            CI_cLow{terminals(ccell)}{tType} = (nanmean(nsCeta{terminals(ccell)}{tType},1)) + (ts_cLow*SEMb{tType});  % Confidence Intervals
            CI_cHigh{terminals(ccell)}{tType} = (nanmean(nsCeta{terminals(ccell)}{tType},1)) + (ts_cHigh*SEMb{tType});  % Confidence Intervals
            
            x = 1:length(CI_bLow{tType});

            AVcData{tType} = nanmean(nsCeta{terminals(ccell)}{tType},1);
%             AVbData{tType} = nanmean(allRedNSbETA{tType},1);
            AVbData{tType} = nanmean(allRedNSbETA{tType},1);
            AVvData{tType} = nanmean(nsVeta{tType},1);
%             SEMdata{tType} = std(nsCeta{terminals(ccell)}{tType},1)/sqrt(size(nsCeta{terminals(ccell)}{tType},1));
            fig = figure;             
            hold all;
            if tType == 1 || tType == 3 
                Frames = size(nsCeta{terminals(ccell)}{tType},2);        
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*1:Frames_post_stim_start)/FPSstack)+1);
                FrameVals = floor((1:FPSstack*1:Frames)-1); 
            elseif tType == 2 || tType == 4 
                Frames = size(nsCeta{terminals(ccell)}{tType},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*1:Frames_post_stim_start)/FPSstack)+10);
                FrameVals = floor((1:FPSstack*1:Frames)-1); 
            end 
%             plot(AVcData{tType},'b','LineWidth',3)
            plot(AVbData{tType},'r','LineWidth',3)
            patch([x fliplr(x)],[CI_bLow{tType} fliplr(CI_bHigh{tType})],[0.5 0 0],'EdgeColor','none')
%             patch([x fliplr(x)],[CI_cLow{terminals(ccell)}{tType} fliplr(CI_cHigh{terminals(ccell)}{tType})],[0 0 0.5],'EdgeColor','none')
%             patch([x fliplr(x)],[CI_cLow{per} fliplr(CI_cHigh{per})],[0 0 0.5],'EdgeColor','none')
%             plot(AVvData{tType},'Color',[0.5 0 0],'LineWidth',3)
            if tType == 1 
                plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'b','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
            elseif tType == 3 
%                 plot(AVbData{tType},'k','LineWidth',3)
                plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'k','LineWidth',2)
                plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'k','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'k','LineWidth',2)                      
            elseif tType == 2 
                plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'b','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2)   
            elseif tType == 4 
%                 plot(AVbData{tType},'r','LineWidth',3)
                plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'k','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'k','LineWidth',2) 
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
            ax.FontSize = 25;
            ax.FontName = 'Times';
            xlimStart = floor(18*FPSstack);
            xlimEnd = floor(32*FPSstack);
            xlim([xlimStart xlimEnd])            
            ylim([-15 30])
            xlabel('time (s)')
            ylabel('percent change')
%             if smoothQ == 1
%                 title(sprintf('Terminal #%d data smoothed by %0.2f sec',terminals(ccell),filtTime));
%             elseif smoothQ == 0
%                 title(sprintf('Terminal #%d data',terminals(ccell)));
%             end 
            title({'Optogenetic Stimulation';'Event Triggered Averages'},'FontName','Times');
            
            set(fig,'position', [500 100 800 800])
            if tType == 1
                dir = sprintf('D:/70kD_RhoB/DAT-Chrimson-GCaMP/SF56_20190718/figures/ETAs_Vwidth_V2/DAterminal%d_ETA_2secBlueLight.tif',terminals(ccell));
            elseif tType == 2
                dir = sprintf('D:/70kD_RhoB/DAT-Chrimson-GCaMP/SF56_20190718/figures/ETAs_Vwidth_V2/DAterminal%d_ETA_20secBlueLight.tif',terminals(ccell));
            elseif tType == 3
                dir = sprintf('D:/70kD_RhoB/DAT-Chrimson-GCaMP/SF56_20190718/figures/ETAs_Vwidth_V2/DAterminal%d_ETA_2secRedLight.tif',terminals(ccell));
            elseif tType == 4
                dir = sprintf('D:/70kD_RhoB/DAT-Chrimson-GCaMP/SF56_20190718/figures/ETAs_Vwidth_V2/DAterminal%d_ETA_20secRedLight.tif',terminals(ccell));
            end                            
%             export_fig(dir)
            alpha(0.5) 
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

% find peaks and then plot where they are in the entire TS 
stdTrace = cell(1,length(vidList));
sigPeaks = cell(1,length(vidList));
sigLocs = cell(1,length(vidList));
for vid = 1%:length(vidList)
    for ccell = 3%1:length(terminals)
        %find the peaks 
%         figure;
        ax=gca;
        hold all
        [peaks, locs] = findpeaks(cDataFullTrace{vid}{terminals(ccell)},'MinPeakProminence',0.1,'MinPeakWidth',2); %0.6,0.8,0.9,1\
        %find the sig peaks (peaks above 2 standard deviations from mean) 
        stdTrace{vid}{terminals(ccell)} = std(cDataFullTrace{vid}{terminals(ccell)});  

              
        % below is plotting code 
        
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
        plot(ScDataFullTrace+150,'b','LineWidth',3)
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

        legend('Calcium signal','BBB permeability','Calcium peak','Location','NorthWest')


        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;
        ax.FontSize = 25;
        ax.FontName = 'Times';
        xLimStart = 509.9*FPSstack;
        xLimEnd = 520.5*FPSstack; 
%         xlim([0 size(cDataFullTrace{vid}{terminals(ccell)},2)])
        xlim([xLimStart xLimEnd])
        ylim([-60 350])
        xlabel('time (sec)','FontName','Times')
%         if smoothQ ==  1
%             title({sprintf('terminal #%d data',terminals(ccell)); sprintf('smoothed by %0.2f seconds',filtTime)})
%         elseif smoothQ == 0 
%             title(sprintf('terminal #%d raw data',terminals(ccell)))
%         end        
        %}
    end 
end 
%}
%% sort data based on ca peak location 
%{
tTypeQ = input('Do you want to seperate peaks by trial type? No = 0. Yes = 1. ');
windSize = 24; %input('How big should the window be around Ca peak in seconds?');
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
                    sortedBdata{vid}{terminals(ccell)}(peak,:) = bDataFullTrace{vid}(start:stop);
                    sortedCdata{vid}{terminals(ccell)}(peak,:) = cDataFullTrace{vid}{terminals(ccell)}(start:stop);
                    sortedVdata{vid}{terminals(ccell)}(peak,:) = vDataFullTrace{vid}(start:stop);
                end 
            end 
        end 
    end 
    %replace rows of all 0s w/NaNs
    for vid = 1:length(vidList)
        for ccell = 1:length(terminals)    
            nonZeroRowsB = all(sortedBdata{vid}{terminals(ccell)} == 0,2);
            sortedBdata{vid}{terminals(ccell)}(nonZeroRowsB,:) = NaN;
            nonZeroRowsC = all(sortedCdata{vid}{terminals(ccell)} == 0,2);
            sortedCdata{vid}{terminals(ccell)}(nonZeroRowsC,:) = NaN;
            nonZeroRowsV = all(sortedVdata{vid}{terminals(ccell)} == 0,2);
            sortedVdata{vid}{terminals(ccell)}(nonZeroRowsV,:) = NaN;
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
    
    %sort C,B,V data 
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
                        sortedBdata{vid}{terminals(ccell)}{per}(peak,:) = bDataFullTrace{vid}(start:stop);
                        sortedCdata{vid}{terminals(ccell)}{per}(peak,:) = cDataFullTrace{vid}{terminals(ccell)}(start:stop);
                        sortedVdata{vid}{terminals(ccell)}{per}(peak,:) = vDataFullTrace{vid}(start:stop);
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
%     changePt = (findchangepts(SNavCdata{terminals(ccell)}))-1;

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
            if isempty(sortedBdata{vid}{terminals(ccell)}) == 0 

                %the data needs to be added to because there are some
                %negative gonig points which mess up the normalizing 
                sortedBdata2{vid}{terminals(ccell)} = sortedBdata{vid}{terminals(ccell)} + 100;
                sortedCdata2{vid}{terminals(ccell)} = sortedCdata{vid}{terminals(ccell)} + 100;
                sortedVdata2{vid}{terminals(ccell)} = sortedVdata{vid}{terminals(ccell)} + 100;

                %normalize to 0.5 sec before changePt (calcium peak
                %onset) BLstart 
                BLstart = changePt - floor(0.5*FPSstack);
                NsortedBdata{vid}{terminals(ccell)} = ((sortedBdata2{vid}{terminals(ccell)})./(nanmean(sortedBdata2{vid}{terminals(ccell)}(:,BLstart:changePt),2)))*100;
                NsortedCdata{vid}{terminals(ccell)} = ((sortedCdata2{vid}{terminals(ccell)})./(nanmean(sortedCdata2{vid}{terminals(ccell)}(:,BLstart:changePt),2)))*100;
                NsortedVdata{vid}{terminals(ccell)} = ((sortedVdata2{vid}{terminals(ccell)})./(nanmean(sortedVdata2{vid}{terminals(ccell)}(:,BLstart:changePt),2)))*100;
            end        
        end 
     end 
     
    %smoothing option
    smoothQ = 1;%input('Input 0 to plot non-smoothed data. Input 1 to plot smoothed data.');
    if smoothQ == 0 
        SNavCdata = NavCdata;
        SNavBdata = NavBdata;
        SNavVdata = NavVdata;
    elseif smoothQ == 1
        filtTime = 0.7;%input('How many seconds do you want to smooth your data by? ');
        SNBdataPeaks = cell(1,length(vidList));
        SNCdataPeaks = cell(1,length(vidList));
        SNVdataPeaks = cell(1,length(vidList));
        for vid = 1:length(vidList)
            for ccell = 1:length(terminals)
%                 [sC_Data] = MovMeanSmoothData(NsortedCdata{vid}{terminals(ccell)},filtTime,FPSstack);
%                 SNCdataPeaks{vid}{terminals(ccell)} = sC_Data;                
                [sB_Data] = MovMeanSmoothData(NsortedBdata{vid}{terminals(ccell)},filtTime,FPSstack);
                SNBdataPeaks{vid}{terminals(ccell)} = sB_Data;
                [sV_Data] = MovMeanSmoothData(NsortedVdata{vid}{terminals(ccell)},filtTime,FPSstack);
                SNVdataPeaks{vid}{terminals(ccell)} = sV_Data;
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

% plot
startF = 32;%floor(startTval*FPSstack);
endF = 40;%floor(startF+(0.8*FPSstack));
            
            
% plot calcium spike triggered averages 
if tTypeQ == 0 
  %{
    allCTraces = cell(1,length(SNCdataPeaks{1}));
    for ccell = 3%1:length(terminals)
        % plot 
        fig = figure;
        Frames = length(SNBdataPeaks{1}{terminals(ccell)});
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack));
        FrameVals = round((1:FPSstack:Frames)); 
        ax=gca;
        hold all
        count = 1;
        for vid = 1:length(vidList)      
            if isempty(sortedBdata{vid}{terminals(ccell)}) == 0
                for peak = 1:size(SNCdataPeaks{vid}{terminals(ccell)},1)                    
                    allBTraces{terminals(ccell)}(count,:) = (SNBdataPeaks{vid}{terminals(ccell)}(peak,:)-100); 
                    allCTraces{terminals(ccell)}(count,:) = (SNCdataPeaks{vid}{terminals(ccell)}(peak,:)-100);
                    count = count + 1;
                end 
            end
        end 

%         
%         for peak = 1:size(allBTraces{terminals(ccell)})
%         end 
%         plot(allBTraces{terminals(ccell)}(countB,:))

        %DETERMINE 95% CI
        SEMb = (nanstd(allBTraces{terminals(ccell)}))/(sqrt(size(allBTraces{terminals(ccell)},1))); % Standard Error            
        ts_bLow = tinv(0.025,size(allBTraces{terminals(ccell)},1)-1);% T-Score for 95% CI
        ts_bHigh = tinv(0.975,size(allBTraces{terminals(ccell)},1)-1);% T-Score for 95% CI
        CI_bLow = (nanmean(allBTraces{terminals(ccell)},1)) + (ts_bLow*SEMb);  % Confidence Intervals
        CI_bHigh = (nanmean(allBTraces{terminals(ccell)},1)) + (ts_bHigh*SEMb);  % Confidence Intervals
        
        SEMc = (nanstd(allCTraces{terminals(ccell)}))/(sqrt(size(allCTraces{terminals(ccell)},1))); % Standard Error            
        ts_cLow = tinv(0.025,size(allCTraces{terminals(ccell)},1)-1);% T-Score for 95% CI
        ts_cHigh = tinv(0.975,size(allCTraces{terminals(ccell)},1)-1);% T-Score for 95% CI
        CI_cLow = (nanmean(allCTraces{terminals(ccell)},1)) + (ts_cLow*SEMc);  % Confidence Intervals
        CI_cHigh = (nanmean(allCTraces{terminals(ccell)},1)) + (ts_cHigh*SEMc);  % Confidence Intervals

        x = 1:length(CI_cLow);

        
        AVSNBdataPeaks{terminals(ccell)} = (nanmean(allBTraces{terminals(ccell)}))-0.3;
        AVSNCdataPeaks{terminals(ccell)} = nanmean(allCTraces{terminals(ccell)});
        
        plot(AVSNCdataPeaks{terminals(ccell)},'b','LineWidth',4)
        plot([131 131], [-100000 100000], 'k:','LineWidth',4)
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;   
        ax.FontSize = 25;
        ax.FontName = 'Times';
        xlabel('time (s)','FontName','Times')
        ylabel('calcium signal percent change','FontName','Times')
        xLimStart = floor(10*FPSstack);
        xLimEnd = floor(24*FPSstack); 
        xlim([xLimStart xLimEnd])
%         ylim([-1.25 2])
        ylim([-45 100])
%         legend('DA calcium','BBB data')
        
        
        patch([x fliplr(x)],[CI_cLow fliplr(CI_cHigh)],[0 0 0.5],'EdgeColor','none')
%         legend('BBB permeability','Calcium signal','Calcium peak onset','Location','northwest');

%         title(sprintf('DA terminal #%d. All light Conditions',terminals(ccell)))
        title('BBB Permeability Spike Triggered Average','FontName','Times')
        set(fig,'position', [500 100 900 800])
        alpha(0.3)
        dir = sprintf('D:/70kD_RhoB/DAT-Chrimson-GCaMP/SF56_20190718/figures/Terminal12/DAterminal%d_1sSmoothingWithCI_allLightConditions.tif',terminals(ccell));
%             export_fig(dir)         

        %add right y axis tick marks for a specific DOD figure. 
        yyaxis right 
        plot(AVSNBdataPeaks{terminals(ccell)},'r','LineWidth',4)
        patch([x fliplr(x)],[(CI_bLow)-0.3 (fliplr(CI_bHigh))-0.3],[0.5 0 0],'EdgeColor','none')
        alpha(0.3)
        set(gca,'YColor',[0 0 0]);
        ylabel('BBB permeability percent change','FontName','Times')
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
windSize = 5; %input('How big should the window be around Ca peak in seconds?');
sortedGreenStacks = cell(1,length(vidList));
sortedRedStacks = cell(1,length(vidList));
for vid = 1:length(vidList)
    for ccell = 1%:length(terminals)
        ind = find(ROIinds == terminals(ccell));
        for peak = 1:length(sigLocs{vid}{terminals(3)})            
            if sigLocs{vid}{ind}(peak)-floor((windSize/2)*FPSstack) > 0 && sigLocs{vid}{ind}(peak)+floor((windSize/2)*FPSstack) < length(cDataFullTrace{vid}{ind})                
                start = sigLocs{vid}{ind}(peak)-floor((windSize/2)*FPSstack);
                stop = sigLocs{vid}{ind}(peak)+floor((windSize/2)*FPSstack);                
                if start == 0 
                    start = 1 ;
                    stop = start + floor((windSize/2)*FPSstack) + floor((windSize/2)*FPSstack);
                end                
                sortedGreenStacks{vid}{ccell}{peak} = greenStacks{vid}(:,:,start:stop);
                sortedRedStacks{vid}{ccell}{peak} = redStacks{vid}(:,:,start:stop);
            end 
        end 
    end 
end 
%}
%% create red and green channel stack averages around calcium peak location 
%{
% create weighted average stacks - normalized by peak number  
avGreenWeighted = cell(1,length(vidList));
avRedWeighted = cell(1,length(vidList));
avGreenWeighted2 = cell(1);
avRedWeighted2 = cell(1);
for vid = 1:length(vidList)
    for ccell = 1%:length(terminals)
        ind = find(ROIinds == terminals(ccell));
        for peak = 1:size(sortedGreenStacks{vid}{ccell},2)  
            avGreenWeighted{vid}{ccell}(:,:,:,peak) = (sortedGreenStacks{vid}{ccell}{peak})*weights(vid,ind);
            avRedWeighted{vid}{ccell}(:,:,:,peak) = (sortedRedStacks{vid}{ccell}{peak})*weights(vid,ind);
        end
        avGreenWeighted2{ccell}(:,:,:,vid) = nanmean(avGreenWeighted{vid}{ccell},4);
        avRedWeighted2{ccell}(:,:,:,vid) = nanmean(avRedWeighted{vid}{ccell},4);
    end 
end 
greenStackAv = sum(avGreenWeighted2{ccell},4);
redStackAv = sum(avRedWeighted2{ccell},4);

% normalize to baseline period 
NgreenStackAv = ((greenStackAv-mean(greenStackAv(:,:,1:floor(size(greenStackAv,3)/3)),3))./(mean(greenStackAv(:,:,1:floor(size(greenStackAv,3)/3)),3)))*100;
NredStackAv = ((redStackAv-mean(redStackAv(:,:,1:floor(size(redStackAv,3)/3)),3))./(mean(redStackAv(:,:,1:floor(size(redStackAv,3)/3)),3)))*100;

%smoothing option
smoothQ = input('Input 0 to plot non-smoothed data. Input 1 to plot smoothed data.');
if smoothQ == 0 
    SNgreenStackAv = NgreenStackAv;
    SNredStackAv = NredStackAv;
elseif smoothQ == 1
    filtTime = input('How many seconds do you want to smooth your data by? ');
    filter_rate = FPSstack*filtTime; 
    SNgreenStackAv = smoothdata(NgreenStackAv,3,'movmean',filter_rate);
    SNredStackAv = smoothdata(NredStackAv,3,'movmean',filter_rate);
end 
%}
%% save the stack 
%{
%set saving parameters
channel = input('Input 0 to save green channel. Input 1 to save red channel. ');
if channel == 0 
    color = 'Green';
    Ims = SNgreenStackAv;
elseif channel == 1
    color = 'Red';
    Ims = SNredStackAv;
end 
term = input('What terminal data are we saving? ');
dir1 = input('What folder are you saving these images in? ');
dir2 = strrep(dir1,'\','/');
dir3 = (sprintf('%s/SmoothedNormalized%sStackAv_Terminal%dCalciumSpikes',dir2,color,term));

%make image gray scale 16 bit
% Ims_index = uint16((Ims - min(Ims(:))) * (65536 / (max(Ims(:)) - min(Ims(:)))));
Ims_index = uint16(Ims(:,:,:));

%make the directory and save the images 
mkdir(dir3);
for frame = 1:size(SNgreenStackAv,3)
    folder = sprintf('%s/%s_Im_%d.tif',dir3,color,frame');
    imwrite(Ims_index(:,:,frame),folder);
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

%IN IMAGEJ SAVE AS TIFF STACK - THEN JUST CONVERT TIFF TO AVI ELSEWHERE 