% get the data you need 
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
bDataFullTrace = cell(1,length(vidList));
vDataFullTrace = cell(1,length(vidList));
for vid = 1:length(vidList)
%     temp2 = matfile(sprintf('SF56_20190718_ROI2_%d_CVBdata_F-SB_terminalWOnoiseFloor_CaPeakAlignedData.mat',vidList(vid)));
    temp2 = matfile(sprintf('SF57_20190717_ROI1_%d_BV_wholeVid.mat',vidList(vid)));       
    vDataFullTrace{vid} = temp2.Vdata; 
%     Bdata = temp2.Bdata;
    bDataFullTrace{vid} = Bdata(1:length(vDataFullTrace{vid})); 
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
trialLength = cell(1,length(vidList));
for vid = 1:length(vidList)
    [~,stateStartF,stateEndF,FPS,vel_wheel_data,TrialType] = makeHDFchart_redBlueStim(state,framePeriod);
    TrialTypes{vid} = TrialType(1:length(stateStartF),:);
    state_start_f{vid} = floor(stateStartF/3);
    state_end_f{vid} = floor(stateEndF/3);
    trialLength{vid} = state_end_f{vid} - state_start_f{vid};
    
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
%% smooth trial data if you want
%{
smoothQ =  input('Do you want to smooth your data? Yes = 1. No = 0. ');
if smoothQ ==  1
    filtTime = input('How many seconds do you want to smooth your data by? ');
    sCdata = cell(1,length(Cdata));
    for term = 1:length(Cdata)
        for tType = 1:length(Cdata{1})   
            for trial = 1:size(Cdata{term}{tType},1)
                [sC_Data] = MovMeanSmoothData(Cdata{term}{tType}(trial,:),filtTime,FPSstack);
                sCdata{term}{tType}(trial,:) = sC_Data; 
            end 
        end 
    end 
    
    sBdata = cell(1,length(Bdata));
    for tType = 1:length(Bdata)   
        for trial = 1:length(Bdata{tType})
            [sB_Data] = MovMeanSmoothData(Bdata{tType}{trial},filtTime,FPSstack);
            sBdata{tType}(trial,:) = sB_Data;             
        end 
    end 

    sVdata = cell(1,length(Vdata));
    for tType = 1:length(Vdata)   
        for trial = 1:length(Vdata{tType})
            [sV_Data] = MovMeanSmoothData(Vdata{tType}{trial},filtTime,FPSstack);
            sVdata{tType}(trial,:) = sV_Data;             
        end 
    end     
    
elseif smoothQ == 0
    sCdata = Cdata; 
    sBdata = cell(1,length(Bdata));
    for tType = 1:length(Bdata)   
        for trial = 1:length(Bdata{tType})
            sBdata{tType}(trial,:) = Bdata{tType}{trial};
        end 
    end 
    sVdata = cell(1,length(Vdata));
    for tType = 1:length(Vdata)   
        for trial = 1:length(Vdata{tType})
            sVdata{tType}(trial,:) = Vdata{tType}{trial};
        end 
    end     
end 
%}
%% plot event triggered averages per terminal 
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
            colorSet = varycolor(size(Data{term}{tType},1));
            for trial = 1:size(Data{term}{tType},1)
                plot(sData{term}{tType}(trial,:),'Color',colorSet(trial,:),'LineWidth',1.5)
            end 
            plot(AVdata{tType},'k','LineWidth',3)
            ax=gca;
            ax.XTick = FrameVals;
            ax.XTickLabel = sec_TimeVals;
            ax.FontSize = 20;
            xlim([0 Frames])
            ylim([-200 200])
            xlabel('time (s)')
            if smoothQ == 1
                title(sprintf('Terminal #%d data smoothed by %0.2f sec',terminals(term),filtTime));
            elseif smoothQ == 0
                title(sprintf('Terminal #%d raw data',terminals(term)));
            end 
        end 
    end 
end 

% plot event triggered averages per terminal (trials staggered) 
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

%         %create plots per terminal  
%         subplot(2,2,tType)
%         hold all 
%         stimStartF = floor((FPSstack*20)/winFrames);
%         if tType == 1 || tType == 3
%             stimStopF = stimStartF + floor((FPSstack*2)/winFrames);           
%             Frames = size(avTermNumPeaks{term}{tType},2);        
%             sec_TimeVals = (0:winSec*2:winSec*Frames)-20;
%             FrameVals = (0:2:Frames);            
%         elseif tType == 2 || tType == 4       
%             stimStopF = stimStartF + floor((FPSstack*20)/winFrames);            
%             Frames = size(avTermNumPeaks{term}{tType},2);        
%             sec_TimeVals = (1:winSec*2:winSec*(Frames+1))-21;
%             FrameVals = (0:2:Frames);
%         end 
%         if tType == 1 || tType == 2
%         plot([stimStartF stimStartF], [-20 20], 'b','LineWidth',2)
%         plot([stimStopF stimStopF], [-20 20], 'b','LineWidth',2)
%         elseif tType == 3 || tType == 4
%         plot([stimStartF stimStartF], [-20 20], 'r','LineWidth',2)
%         plot([stimStopF stimStopF], [-20 20], 'r','LineWidth',2)
%         end 
%         for trial = 1:size(numPeaks{term}{tType},1)
%             plot(numPeaks{term}{tType}(trial,:))
%         end 
%         plot(avTermNumPeaks{term}{tType},'k','LineWidth',2)
% 
%         ax=gca;
%         axis on 
%         xticks(FrameVals)
%         ax.XTickLabel = sec_TimeVals;
% %         yticks(5:10:size(avTermNumPeaks{term}{tType},1)-5)
% %         ax.YTickLabel = ([]);
%         ax.FontSize = 10;
%         xlabel('time (s)')
%         ylabel('trial')
%         xlim([1 length(avTermNumPeaks{term}{tType})])
%         ylim([-1 5])
%         mtitle = sprintf('Number of calcium peaks. Terminal %d.',terminals(term));
%         sgtitle(mtitle);
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
    for term = 1:length(Cdata)
        plot(allTermAvPeakNums{tType}(term,:),'Color',colorSet(term,:),'LineWidth',1.5)
    end 
    plot(mean(allTermAvPeakNums{tType}),'Color','k','LineWidth',2)
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
    ylim([-3 5])
    sgtitle('Number of calcium peaks per terminal');
    legend('terminal 17','terminal 15','terminal 12','terminal 10','terminal 8','terminal 7','terminal 6','terminal 5','terminal 4','terminal 3')
end 
% 
% %plot num peaks for all terminals (terminal traces stacked - not overlaid)
% figure;
% for tType = 1:length(Cdata{1})
%     subplot(2,2,tType)
%     hold all 
%     stimStartF = floor((FPSstack*20)/winFrames);
%     if tType == 1 || tType == 3
%         stimStopF = stimStartF + floor((FPSstack*2)/winFrames);           
%         Frames = size(allTermAvPeakNums{tType},2);        
%         sec_TimeVals = (0:winSec*2:winSec*Frames)-20;
%         FrameVals = (0:2:Frames);            
%     elseif tType == 2 || tType == 4       
%         stimStopF = stimStartF + floor((FPSstack*20)/winFrames);            
%         Frames = size(allTermAvPeakNums{tType},2);        
%         sec_TimeVals = (1:winSec*2:winSec*(Frames+1))-21;
%         FrameVals = (0:2:Frames);
%     end 
%     colorSet = varycolor(length(Cdata));
%     yStagTerm = 0.7;
%     for term = 1:length(Cdata)
%         plot(allTermAvPeakNums{tType}(term,:)+yStagTerm,'Color',colorSet(term,:),'LineWidth',1.5)
%         yStagTerm = yStagTerm + 0.7;
%     end 
% %     plot(mean(allTermAvPeakNums{tType}),'Color','k','LineWidth',2)
% %     plot(allTermAvPeakNums{tType},'Color','k')
% %     for col = 1:length(allTermAvPeakNums{tType})
% %         scatter(linspace(col,col,size(allTermAvPeakNums{tType},1)),allTermAvPeakNums{tType}(:,col))
% %     end 
%     if tType == 1 || tType == 2
%         plot([stimStartF stimStartF], [-20 20], 'b','LineWidth',2)
%         plot([stimStopF stimStopF], [-20 20], 'b','LineWidth',2)
%     elseif tType == 3 || tType == 4
%         plot([stimStartF stimStartF], [-20 20], 'r','LineWidth',2)
%         plot([stimStopF stimStopF], [-20 20], 'r','LineWidth',2)
%     end 
%     ax=gca;
%     axis on 
%     xticks(FrameVals)
%     ax.XTickLabel = sec_TimeVals;
% %         yticks(5:10:size(avTermNumPeaks{term}{tType},1)-5)
% %         ax.YTickLabel = ([]);
%     ax.FontSize = 10;
%     xlabel('time (s)')
%     ylabel('number of peaks')
%     xlim([0 length(avTermNumPeaks{term}{tType})])
%     ylim([0 8.5])
%     sgtitle('Number of calcium peaks per terminal');
%     legend('terminal 17','terminal 15','terminal 12','terminal 10','terminal 8','terminal 7','terminal 6','terminal 5','terminal 4','terminal 3')
% end 
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
        [peaks, locs] = findpeaks(cDataFullTrace{vid}{terminals(ccell)},'MinPeakProminence',0.1,'MinPeakWidth',2); %0.6,0.8,0.9,1\
        %find the sig peaks (peaks above 2 standard deviations from mean) 
        stdTrace{vid}{terminals(ccell)} = std(cDataFullTrace{vid}{terminals(ccell)});  
        count = 1 ; 
        for loc = 1:length(locs)
            if peaks(loc) > stdTrace{vid}{terminals(ccell)}*2
                sigPeaks{vid}{terminals(ccell)}(count) = peaks(loc);
                sigLocs{vid}{terminals(ccell)}(count) = locs(loc);
                plot([locs(loc) locs(loc)], [-5000 5000], 'k','LineWidth',2)
                count = count + 1;
            end 
        end 
                
        % below is plotting code 
        %{
        Frames = size(cDataFullTrace{vid}{ind},2);
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*50:Frames_post_stim_start)/FPSstack)+51);
        min_TimeVals = round(sec_TimeVals/60,2);
        FrameVals = round((1:FPSstack*50:Frames)-1); 
        figure;
        ax=gca;
        hold all
        plot(cDataFullTrace{vid}{ind},'Color',[0 0.5 0],'LineWidth',1)
        for trial = 1:size(state_start_f{vid},1)
            if TrialTypes{vid}(trial,2) == 1
                plot([state_start_f{vid}(trial) state_start_f{vid}(trial)], [-5000 5000], 'b','LineWidth',2)
                plot([state_end_f{vid}(trial) state_end_f{vid}(trial)], [-5000 5000], 'b','LineWidth',2)
            elseif TrialTypes{vid}(trial,2) == 2
                plot([state_start_f{vid}(trial) state_start_f{vid}(trial)], [-5000 5000], 'r','LineWidth',2)
                plot([state_end_f{vid}(trial) state_end_f{vid}(trial)], [-5000 5000], 'r','LineWidth',2)
            end 
        end 
        ax.XTick = FrameVals;
        ax.XTickLabel = min_TimeVals;
        ax.FontSize = 20;
        xlim([0 size(cDataFullTrace{vid}{ind},2)])
        ylim([-200 200])
        xlabel('time (min)')
        if smoothQ ==  1
            title({sprintf('terminal #%d data',terminals(ccell)); sprintf('smoothed by %0.2f seconds',filtTime)})
        elseif smoothQ == 0 
            title(sprintf('terminal #%d raw data',terminals(ccell)))
        end        
        %}
    end 
end 
%}
%% sort data based on ca peak location 

tTypeQ = input('Do you want to seperate peaks by trial type? No = 0. Yes = 1. ');
windSize = 5; %input('How big should the window be around Ca peak in seconds?');
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
%% average calcium peak aligned data - normalized to number of peaks per video 
%{
% determine weights from number of peaks per video per terminal 
numPeaks = zeros(length(vidList),length(sortedCdata{1}));
for vid = 1:length(vidList)
    for ccell = 1:length(terminals)
        numPeaks(vid,terminals(ccell)) = size(sortedCdata{vid}{terminals(ccell)},1);
    end 
end 
totalPeaks = sum(numPeaks,1);
weights = numPeaks ./ totalPeaks;

% determine weighted average and SEM- across videos - normalized by peak number  
avCweighted = cell(1,length(vidList));
avBweighted = cell(1,length(vidList));
avVweighted = cell(1,length(vidList));
semCweighted = cell(1,length(vidList));
semBweighted = cell(1,length(vidList));
semVweighted = cell(1,length(vidList));
avCweighted2 = cell(1,length(sortedCdata{1}));
avBweighted2 = cell(1,length(sortedCdata{1}));
avVweighted2 = cell(1,length(sortedCdata{1}));
semCweighted2 = cell(1,length(sortedCdata{1}));
semBweighted2 = cell(1,length(sortedCdata{1}));
semVweighted2 = cell(1,length(sortedCdata{1}));
avSortedCdata = cell(1,length(sortedCdata{1}));
avSortedBdata = cell(1,length(sortedCdata{1}));
avSortedVdata = cell(1,length(sortedCdata{1}));
semSortedCdata = cell(1,length(sortedCdata{1}));
semSortedBdata = cell(1,length(sortedCdata{1}));
semSortedVdata = cell(1,length(sortedCdata{1}));
for vid = 1:length(vidList)
    for ccell = 1:length(terminals)
        avCweighted{vid}{terminals(ccell)} = nanmean((sortedCdata{vid}{terminals(ccell)})*weights(vid,terminals(ccell)),1);
        avBweighted{vid}{terminals(ccell)} = nanmean((sortedBdata{vid}{terminals(ccell)})*weights(vid,terminals(ccell)),1);
        avVweighted{vid}{terminals(ccell)} = nanmean((sortedVdata{vid}{terminals(ccell)})*weights(vid,terminals(ccell)),1);        
        semCweighted{vid}{terminals(ccell)} = (std(sortedCdata{vid}{terminals(ccell)}))/sqrt(length(sortedCdata{vid}{terminals(ccell)}))*weights(vid,terminals(ccell));
        semBweighted{vid}{terminals(ccell)} = (std(sortedBdata{vid}{terminals(ccell)}))/sqrt(length(sortedBdata{vid}{terminals(ccell)}))*weights(vid,terminals(ccell));
        semVweighted{vid}{terminals(ccell)} = (std(sortedVdata{vid}{terminals(ccell)}))/sqrt(length(sortedVdata{vid}{terminals(ccell)}))*weights(vid,terminals(ccell));        
        if isempty(avCweighted{vid}{terminals(ccell)}) == 0 
            avCweighted2{terminals(ccell)}(vid,:) = avCweighted{vid}{terminals(ccell)};
            avBweighted2{terminals(ccell)}(vid,:) = avBweighted{vid}{terminals(ccell)};
            avVweighted2{terminals(ccell)}(vid,:) = avVweighted{vid}{terminals(ccell)};
            semCweighted2{terminals(ccell)}(vid,:) = semCweighted{vid}{terminals(ccell)};
            semBweighted2{terminals(ccell)}(vid,:) = semBweighted{vid}{terminals(ccell)};
            semVweighted2{terminals(ccell)}(vid,:) = semVweighted{vid}{terminals(ccell)};
        end 
        avSortedCdata{terminals(ccell)} = sum(avCweighted2{terminals(ccell)},1);
        avSortedBdata{terminals(ccell)} = sum(avBweighted2{terminals(ccell)},1);
        avSortedVdata{terminals(ccell)} = sum(avVweighted2{terminals(ccell)},1);
        semSortedCdata{terminals(ccell)} = sum(semCweighted2{terminals(ccell)},1);
        semSortedBdata{terminals(ccell)} = sum(semBweighted2{terminals(ccell)},1);
        semSortedVdata{terminals(ccell)} = sum(semVweighted2{terminals(ccell)},1);
    end 
end 
%}
%% normalize to baseline period and plot calcium peak aligned data
if tTypeQ == 0 
    %below gives me ability to plot single peak BBB traces 
    BdataPeaks = cell(1,length(vidList));
    NBdataPeaks = cell(1,length(vidList));
    normNonWeighted_BdataPeaks = cell(1,length(vidList));
    for vid = 1:length(vidList)
        for ccell = 1:length(terminals)
           %created weighted data to normalize for number of peaks per video -
           %helps with averaging across videos 
           BdataPeaks{vid}{terminals(ccell)} = (sortedBdata{vid}{terminals(ccell)})*weights(vid,terminals(ccell));
           %normalize to baseline period           
           NBdataPeaks{vid}{terminals(ccell)} = (BdataPeaks{vid}{terminals(ccell)}-mean(mean((BdataPeaks{vid}{terminals(ccell)}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3))))))/(mean(mean(BdataPeaks{vid}{terminals(ccell)}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3)))))*100;
           normNonWeighted_BdataPeaks{vid}{terminals(ccell)} = (sortedBdata{vid}{terminals(ccell)}-mean(mean((sortedBdata{vid}{terminals(ccell)}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3))))))/(mean(mean(sortedBdata{vid}{terminals(ccell)}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3)))))*100;
        end 
    end 

    smoothQ = input('Input 0 to plot non-smoothed data. Input 1 to plot smoothed data.');
    if smoothQ == 0 
        SNBdataPeaks = NBdataPeaks;
    elseif smoothQ == 1
        filtTime = input('How many seconds do you want to smooth your data by? ');
        SNBdataPeaks = cell(1,length(vidList));
        SNonWeightedBdataPeaks = cell(1,length(vidList));
        for vid = 1:length(vidList)
            for ccell = 1:length(terminals)
                for peak = 1:size(NBdataPeaks{vid}{terminals(ccell)},1)
                    [SBPeak_Data] = MovMeanSmoothData(NBdataPeaks{vid}{terminals(ccell)}(peak,:),filtTime,FPSstack);
                    SNBdataPeaks{vid}{terminals(ccell)}(peak,:) = SBPeak_Data;

                    [SNonWeighted_Data] = MovMeanSmoothData(normNonWeighted_BdataPeaks{vid}{terminals(ccell)}(peak,:),filtTime,FPSstack);
                    SNonWeightedBdataPeaks{vid}{terminals(ccell)}(peak,:) = SNonWeighted_Data;                
                end 
            end 
        end 
    end 

    %find where calcium peak onset is 
    changePt = (findchangepts(SNavCdata{terminals(ccell)}))-1;

    %find the BBB traces that increase after calcium peak onset (changePt) 
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

    %normalize averaged data to baseline period 
    NavCdata = cell(1,length(avSortedCdata));
    NavBdata = cell(1,length(avSortedCdata));
    NavVdata = cell(1,length(avSortedCdata));
    NsemCdata = cell(1,length(avSortedCdata));
    NsemBdata = cell(1,length(avSortedCdata));
    NsemVdata = cell(1,length(avSortedCdata));
    for ccell = 1:length(terminals)
        NavCdata{terminals(ccell)} = ((avSortedCdata{terminals(ccell)}-mean(avSortedCdata{terminals(ccell)}(1:floor(length(avSortedCdata{terminals(ccell)})/3))))/mean(avSortedCdata{terminals(ccell)}(1:floor(length(avSortedCdata{terminals(ccell)})/3))))*100;
        NavBdata{terminals(ccell)} = ((avSortedBdata{terminals(ccell)}-mean(avSortedBdata{terminals(ccell)}(1:floor(length(avSortedBdata{terminals(ccell)})/3))))/mean(avSortedBdata{terminals(ccell)}(1:floor(length(avSortedBdata{terminals(ccell)})/3))))*100;
        NavVdata{terminals(ccell)} = ((avSortedVdata{terminals(ccell)}-mean(avSortedVdata{terminals(ccell)}(1:floor(length(avSortedVdata{terminals(ccell)})/3))))/mean(avSortedVdata{terminals(ccell)}(1:floor(length(avSortedVdata{terminals(ccell)})/3))))*100;    
        NsemCdata{terminals(ccell)} = ((semSortedCdata{terminals(ccell)}-mean(semSortedCdata{terminals(ccell)}(1:floor(length(semSortedCdata{terminals(ccell)})/3))))/mean(semSortedCdata{terminals(ccell)}(1:floor(length(semSortedCdata{terminals(ccell)})/3))))*100;
        NsemBdata{terminals(ccell)} = ((semSortedBdata{terminals(ccell)}-mean(semSortedBdata{terminals(ccell)}(1:floor(length(semSortedBdata{terminals(ccell)})/3))))/mean(semSortedBdata{terminals(ccell)}(1:floor(length(semSortedBdata{terminals(ccell)})/3))))*100;
        NsemVdata{terminals(ccell)} = ((semSortedVdata{terminals(ccell)}-mean(semSortedVdata{terminals(ccell)}(1:floor(length(semSortedVdata{terminals(ccell)})/3))))/mean(semSortedVdata{terminals(ccell)}(1:floor(length(semSortedVdata{terminals(ccell)})/3)))*100);
    end    

    %smoothing option
    if smoothQ == 0 
        SNavCdata = NavCdata;
        SNavBdata = NavBdata;
        SNavVdata = NavVdata;
        SNsemCdata = NsemCdata;
        SNsemBdata = NsemBdata;
        SNsemVdata = NsemVdata;
    elseif smoothQ == 1
        SNavCdata = cell(1,length(NavCdata));
        SNavBdata = cell(1,length(NavCdata));
        SNavVdata = cell(1,length(NavCdata));
        SNsemCdata = cell(1,length(NavCdata));
        SNsemBdata = cell(1,length(NavCdata));
        SNsemVdata = cell(1,length(NavCdata));
        for ccell = 1:length(terminals)
            [sC_Data] = MovMeanSmoothData(NavCdata{terminals(ccell)},filtTime,FPSstack);
            SNavCdata{terminals(ccell)} = sC_Data;
            [sB_Data] = MovMeanSmoothData(NavBdata{terminals(ccell)},filtTime,FPSstack);
            SNavBdata{terminals(ccell)} = sB_Data;
            [sV_Data] = MovMeanSmoothData(NavVdata{terminals(ccell)},filtTime,FPSstack);
            SNavVdata{terminals(ccell)} = sV_Data;
            [sCsem_Data] = MovMeanSmoothData(NsemCdata{terminals(ccell)},filtTime,FPSstack);
            SNsemCdata{terminals(ccell)} = sCsem_Data;
            [sBsem_Data] = MovMeanSmoothData(NsemBdata{terminals(ccell)},filtTime,FPSstack);
            SNsemBdata{terminals(ccell)} = sBsem_Data;
            [sVsem_Data] = MovMeanSmoothData(NsemVdata{terminals(ccell)},filtTime,FPSstack);
            SNsemVdata{terminals(ccell)} = sVsem_Data;
        end 
    end 
elseif tTypeQ == 1 
    
    %normalize to baseline period
    NsortedBdata = cell(1,length(vidList));
    NsortedCdata = cell(1,length(vidList));
    NsortedVdata = cell(1,length(vidList));
     for vid = 1:length(vidList)
        for ccell = 1:length(terminals)
            for per = 1:3   
                if isempty(sortedBdata{vid}{terminals(ccell)}{per}) == 0 
                    NsortedBdata{vid}{terminals(ccell)}{per} = ((sortedBdata{vid}{terminals(ccell)}{per} - (mean(sortedBdata{vid}{terminals(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3)),2)))./((mean(sortedBdata{vid}{terminals(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3)),2))))*100;
                    NsortedCdata{vid}{terminals(ccell)}{per} = ((sortedCdata{vid}{terminals(ccell)}{per} - (mean(sortedCdata{vid}{terminals(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3)),2)))./((mean(sortedCdata{vid}{terminals(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3)),2))))*100;
                    NsortedVdata{vid}{terminals(ccell)}{per} = ((sortedVdata{vid}{terminals(ccell)}{per} - (mean(sortedVdata{vid}{terminals(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3)),2)))./((mean(sortedVdata{vid}{terminals(ccell)}{per}(:,1:floor(length(avSortedCdata{terminals(ccell)})/3)),2))))*100;            
                end 
            end 
        end 
     end 
    
    smoothQ = input('Input 0 to plot non-smoothed data. Input 1 to plot smoothed data.');
    if smoothQ == 0 
        SNsortedBdata = NsortedBdata;
        SNsortedCdata = NsortedCdata;
        SNsortedVdata = NsortedVdata;
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
end 
%% plot
if tTypeQ == 0 
    allTraces = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
    AVSNBdataPeaks_nonWeightedAv = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
    for ccell = 1:length(terminals)
        % plot 
        figure;
        Frames = length(avSortedCdata{terminals(ccell)});
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack))+1;
        FrameVals = round((1:FPSstack:Frames)+5); 
        ax=gca;
        hold all
    %     plot(SNavVdata{terminals(ccell)},'k','LineWidth',2)
    %     varargout = boundedline(1:size(SNavCdata{terminals(ccell)},2),SNavCdata{terminals(ccell)},SNsemCdata{terminals(ccell)},'b','transparency', 0.3,'alpha'); 
    %     varargout = boundedline(1:size(SNavBdata{terminals(ccell)},2),SNavBdata{terminals(ccell)},SNsemBdata{terminals(ccell)},'r','transparency', 0.3,'alpha');
    %     varargout = boundedline(1:size(SNavVdata{terminals(ccell)},2),SNavVdata{terminals(ccell)},SNsemVdata{terminals(ccell)},'k','transparency', 0.3,'alpha');
        testCount = 1;
    %     for vid = 1:length(vidList)
        for vid = 1:size(SNBdataPeaks_IncAfterCa_2{terminals(ccell)},1)
            if terminals(ccell) <= length(SNBdataPeaks_IncAfterCa{vid})
                for peak = 1:size(SNBdataPeaks_NotIncAfterCa{vid}{terminals(ccell)},1)
    %                 %if the BBB trace is greater after calcium peak onset
    %                 %(changePt) than before             
    %                 plot(SNBdataPeaks_IncAfterCa{vid}{terminals(ccell)}(peak,:))  

                    allTraces{terminals(ccell)}(testCount,:) = nonWeighted_SNBdataPeaks_NotIncAfterCa{vid}{terminals(ccell)}(peak,:);
                    plot(allTraces{terminals(ccell)}(testCount,:))
                    testCount = testCount + 1;               
                end 
            end
    %         plot(SNBdataPeaks_NotIncAfterCa_2{terminals(ccell)}(vid,:),'LineWidth',2) 
        end 
        AVSNBdataPeaks_nonWeightedAv{terminals(ccell)} = nanmean(allTraces{terminals(ccell)});
        plot(AVSNBdataPeaks_nonWeightedAv{terminals(ccell)},'r','LineWidth',4)
        plot(SNavCdata{terminals(ccell)},'b','LineWidth',4)
    %     plot(SNavBdata{terminals(ccell)},'r','LineWidth',2)
    %     plot(AVSNBdataPeaks{terminals(ccell)},'r','LineWidth',4)   %way #2 of averaging (weighted average)  
    %     plot(AVSNBdataPeaksNotInc{terminals(ccell)},'r','LineWidth',4) 
        plot([changePt changePt], [-100000 100000], 'k','LineWidth',4)
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;   
        ax.FontSize = 20;
        xlabel('time (s)')
        ylabel('percent change')
        xlim([0 length(SNavCdata{terminals(ccell)})])
        ylim([-800 1000])
    %     legend('DA calcium','BBB data')
        if smoothQ == 0 
            title(sprintf('DA terminal #%d.',terminals(ccell)))
        elseif smoothQ == 1
            title(sprintf('DA terminal #%d. %0.2f sec smoothing.',terminals(ccell),filtTime))
        end 
    end
elseif tTypeQ == 1
    
    allBTraces = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
    allCTraces = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
    AVSNBdataPeaks = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
    AVSNCdataPeaks = cell(1,length(SNBdataPeaks_IncAfterCa{4}));
    for ccell = 3%1:length(terminals)
        % plot 
        for per = 1:3
            figure;
            Frames = length(avSortedCdata{terminals(ccell)});
            Frames_pre_stim_start = -((Frames-1)/2); 
            Frames_post_stim_start = (Frames-1)/2; 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack))+1;
            FrameVals = round((1:FPSstack:Frames)+5); 
            ax=gca;
            hold all
            testCount = 1;
            for vid = 1:length(vidList)
                   if isempty(sortedBdata{vid}{terminals(ccell)}{per}) == 0 
                        for peak = 1:size(sortedBdata{vid}{terminals(ccell)}{per},1)
                            allBTraces{terminals(ccell)}(testCount,:) = SNBdataPeaks{vid}{terminals(ccell)}{per}(peak,:);
                            plot(allBTraces{terminals(ccell)}(testCount,:),'r')
                            allCTraces{terminals(ccell)}(testCount,:) = SNCdataPeaks{vid}{terminals(ccell)}{per}(peak,:);
%                             plot(allCTraces{terminals(ccell)}(testCount,:),'b')
                            testCount = testCount + 1;               
                        end 
                   end               
            end 
            AVSNBdataPeaks{terminals(ccell)} = nanmean(allBTraces{terminals(ccell)},1);
            AVSNCdataPeaks{terminals(ccell)} = nanmean(allCTraces{terminals(ccell)},1);
            plot(AVSNBdataPeaks{terminals(ccell)},'k','LineWidth',4)
            plot(AVSNCdataPeaks{terminals(ccell)},'b','LineWidth',4)
    %         plot(SNavCdata{terminals(ccell)},'b','LineWidth',4)
            plot([changePt changePt], [-100000 100000], 'k','LineWidth',4)
            ax.XTick = FrameVals;
            ax.XTickLabel = sec_TimeVals;   
            ax.FontSize = 20;
            xlabel('time (s)')
            ylabel('percent change')
            xlim([0 length(SNavCdata{terminals(ccell)})])
            ylim([-800 1000])
        %     legend('DA calcium','BBB data')
            if smoothQ == 0 
                if per == 1 
                    title(sprintf('DA terminal #%d. Blue light on.',terminals(ccell)))
                elseif per == 2
                    title(sprintf('DA terminal #%d. Red light on.',terminals(ccell)))
                elseif per == 3
                    title(sprintf('DA terminal #%d. ISI period.',terminals(ccell)))
                end                 
            elseif smoothQ == 1                
                if per == 1 
                    title(sprintf('DA terminal #%d. %0.2f sec smoothing. Blue light on.',terminals(ccell),filtTime))
                elseif per == 2
                    title(sprintf('DA terminal #%d. %0.2f sec smoothing. Red light on.',terminals(ccell),filtTime))
                elseif per == 3
                    title(sprintf('DA terminal #%d. %0.2f sec smoothing. ISI period.',terminals(ccell),filtTime))
                end               
            end 
        end
    end 
end 
    

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