% % Bdata = (zData{1} + zData{2})/2;
% % Bdata = zData{1};
% 
% Blength = length(Bdata);
% Clength = length(Cdata);
% Vlength = length(Vdata);
% 
% if Blength < Clength && Blength < Vlength
%     Cdata = Cdata(1:length(Bdata));
%     Vdata = Vdata(1:length(Bdata));
% elseif Clength < Vlength && Clength < Blength
%     Vdata = Vdata(1:length(Cdata));
%     Bdata = Bdata(1:length(Cdata));    
% elseif Vlength < Clength && Vlength < Blength
%     Cdata = Cdata(1:length(Vdata));
%     Bdata = Bdata(1:length(Vdata));
% end 

%% smooth data 
clear SCdata RSCdata
ccellQ = input('Input 0 if you want to average calcium traces of all terminals. Input 1 if you do not want to immediately average all terminals. ');
if ccellQ == 1 
    termQ = input('Input 0 if you want to plot all terminals. Input 1 if you want to specify what terminals to plot. ');
elseif ccellQ == 0
    termQ = 0 ;
end 
if termQ == 1 
    terminals = input('What terminals do you want to average? ');
end 
smoothQ =  input('Do you want to smooth your data? Yes = 1. No = 0. ');

if smoothQ ==  1
    filtTime = input('How many seconds do you want to smooth your data by? ');
    if ccellQ == 0
%         [SBdata] = MovMeanSmoothData(Bdata,filtTime,FPS);
        [SCdata] = MovMeanSmoothData(Cdata,filtTime,FPS);
        [RSCdata] = MovMeanSmoothData(RCdata,filtTime,FPS);
%         [SVdata] = MovMeanSmoothData(Vdata,filtTime,FPS);
    elseif ccellQ == 1 
        if termQ == 0
            SCdata = cell(1,length(CcellData));
            RSCdata = cell(1,length(CcellData));
            for ccell = 1:length(CcellData)
                if isempty(CcellData{ccell}) == 0 
                    [SC_data] = MovMeanSmoothData(CcellData{ccell},filtTime,FPS);
                    [RSC_data] = MovMeanSmoothData(RCcellData{ccell},filtTime,FPS);
                    SCdata{ccell} = SC_data;
                    RSCdata{ccell} = RSC_data;
                end 
            end 
        elseif termQ == 1 
            SCdata = cell(1,length(terminals));
            RSCdata = cell(1,length(terminals));
            for ccell = 1:length(terminals)
                if isempty(CcellData{terminals(ccell)}) == 0 
                    [SC_data] = MovMeanSmoothData(CcellData{terminals(ccell)},filtTime,FPS);
                    [RSC_data] = MovMeanSmoothData(RCcellData{terminals(ccell)},filtTime,FPS);
                    SCdata{ccell} = SC_data;
                    RSCdata{ccell} = RSC_data;
                end 
            end     
        end 
    end       
elseif smoothQ == 0
    if ccellQ == 0
%         SBdata = Bdata;
        SCdata = Cdata;
        RSCdata = RCdata;
%         SVdata = Vdata;
    elseif ccellQ == 1 
        if termQ == 0
            SCdata = cell(1,length(CcellData));
            RSCdata = cell(1,length(CcellData));
            for ccell = 1:length(CcellData)
                if isempty(CcellData{ccell}) == 0
                    SCdata{ccell} = CcellData{ccell};
                    RSCdata{ccell} = RCcellData{ccell};
                end 
            end
        elseif termQ == 1
            SCdata = cell(1,length(terminals));
            RSCdata = cell(1,length(terminals));
            for ccell = 1:length(terminals)
                if isempty(CcellData{terminals(ccell)}) == 0
                    SCdata{ccell} = CcellData{terminals(ccell)};
                    RSCdata{ccell} = RCcellData{terminals(ccell)};
                end 
            end
        end 
    end 
end

% 27, 20, 14,10,15,13,11,8,5,4

%% prep trial type data 
% 
% TrialTypes = TrialTypes(1:length(state_start_f),:);
% state_start_f = floor(state_start_f/3);
% state_end_f = floor(state_end_f/3);
% trialLength = state_end_f - state_start_f;

%% find peaks and then plot where they are in the entire TS 
clear diffCdata
if ccellQ ==  1
    if termQ == 0 
        for ccell = 1:length(CcellData)
            if isempty(CcellData{ccell}) == 0
                [peaks, locs] = findpeaks(SCdata{ccell},'MinPeakProminence',50); %0.6,0.8,0.9,1

                FPSstack = FPS/3; 
                Frames = size(SCdata{ccell},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*50:Frames_post_stim_start)/FPSstack)+473);
                min_TimeVals = round(sec_TimeVals/60,2);
                FrameVals = round((1:FPSstack*50:Frames)-1); 
                figure;
                ax=gca;
                hold all
                % plot(Bdata,'r','LineWidth',3);
                diffCdata{ccell} = SCdata{ccell} - RSCdata{ccell};
    %             plot(SCdata{ccell},'g','LineWidth',1)
    %             plot(RSCdata{ccell},'r','LineWidth',1)
                plot(diffCdata{ccell},'k','LineWidth',1)
%                 for loc = 1:length(locs)
%                     plot([locs(loc) locs(loc)], [-5000 5000], 'k','LineWidth',2)
%                 end 
                for trial = 1:size(TrialTypes,1)
                    if TrialTypes(trial,2) == 1
                        plot([state_start_f(trial) state_start_f(trial)], [-5000 5000], 'b','LineWidth',0.5)
                        plot([state_end_f(trial) state_end_f(trial)], [-5000 5000], 'b','LineWidth',0.5)
                    elseif TrialTypes(trial,2) == 2
                        plot([state_start_f(trial) state_start_f(trial)], [-5000 5000], 'r','LineWidth',0.5)
                        plot([state_end_f(trial) state_end_f(trial)], [-5000 5000], 'r','LineWidth',0.5)
                    end 
                end 
                ax.XTick = FrameVals;
                ax.XTickLabel = min_TimeVals;
                ax.FontSize = 20;
                xlim([0 length(Cdata)])
                ylim([-1.5 1.5])
                xlabel('time (min)')
                if smoothQ ==  1
                    title({sprintf('terminal #%d data',ccell); sprintf('smoothed by %0.2f seconds',filtTime)})
                elseif smoothQ == 0 
                    title(sprintf('terminal #%d raw data',ccell))
                end 
                legend('green - red channel')
            end 
        end 
    elseif termQ == 1 
        for ccell = 1:length(terminals)
            if isempty(CcellData{terminals(ccell)}) == 0
                [peaks, locs] = findpeaks(SCdata{ccell},'MinPeakProminence',5); %0.6,0.8,0.9,1

                FPSstack = FPS/3; 
                Frames = size(SCdata{ccell},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*50:Frames_post_stim_start)/FPSstack)+473);
                min_TimeVals = round(sec_TimeVals/60,2);
                FrameVals = round((1:FPSstack*50:Frames)-1); 
                figure;
                ax=gca;
                hold all
                % plot(Bdata,'r','LineWidth',3);
                diffCdata{ccell} = SCdata{ccell} - RSCdata{ccell};
    %             plot(SCdata{ccell},'g','LineWidth',1)
    %             plot(RSCdata{ccell},'r','LineWidth',1)
                plot(diffCdata{ccell},'k','LineWidth',1)
%                 for loc = 1:length(locs)
%                     plot([locs(loc) locs(loc)], [-5000 5000], 'k','LineWidth',2)
%                 end 
                for trial = 1:size(TrialTypes,1)
                    if TrialTypes(trial,2) == 1
                        plot([state_start_f(trial) state_start_f(trial)], [-5000 5000], 'b','LineWidth',0.5)
                        plot([state_end_f(trial) state_end_f(trial)], [-5000 5000], 'b','LineWidth',0.5)
                    elseif TrialTypes(trial,2) == 2
                        plot([state_start_f(trial) state_start_f(trial)], [-5000 5000], 'r','LineWidth',0.5)
                        plot([state_end_f(trial) state_end_f(trial)], [-5000 5000], 'r','LineWidth',0.5)
                    end 
                end 
                ax.XTick = FrameVals;
                ax.XTickLabel = min_TimeVals;
                ax.FontSize = 20;
                xlim([0 length(Cdata)])
                ylim([-1.5 1.5])
                xlabel('time (min)')
                if smoothQ ==  1
                    title({sprintf('terminal #%d data',ccell); sprintf('smoothed by %0.2f seconds',filtTime)})
                elseif smoothQ == 0 
                    title(sprintf('terminal #%d raw data',ccell))
                end 
                legend('green - red channel')
            end 
        end 
        
    end 
elseif  ccellQ ==  0
    [peaks, locs] = findpeaks(SCdata,'MinPeakProminence',5); %0.6,0.8,0.9,1

    FPSstack = FPS/3; 
    Frames = size(SCdata,2);
    Frames_pre_stim_start = -((Frames-1)/2); 
    Frames_post_stim_start = (Frames-1)/2; 
    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*50:Frames_post_stim_start)/FPSstack)+473);
    min_TimeVals = round(sec_TimeVals/60,2);
    FrameVals = round((1:FPSstack*50:Frames)-1); 
    figure;
    ax=gca;
    hold all
    % plot(Bdata,'r','LineWidth',3);
    diffCdata = SCdata - RSCdata;
%     plot(SCdata,'g','LineWidth',1)
%     plot(RSCdata,'r','LineWidth',1)
    plot(diffCdata,'k','LineWidth',1)
    for loc = 1:length(locs)
        plot([locs(loc) locs(loc)], [-5000 5000], 'k','LineWidth',2)
    end 
    for trial = 1:size(TrialTypes,1)
        if TrialTypes(trial,2) == 1
            plot([state_start_f(trial) state_start_f(trial)], [-5000 5000], 'b','LineWidth',0.5)
            plot([state_end_f(trial) state_end_f(trial)], [-5000 5000], 'b','LineWidth',0.5)
        elseif TrialTypes(trial,2) == 2
            plot([state_start_f(trial) state_start_f(trial)], [-5000 5000], 'r','LineWidth',0.5)
            plot([state_end_f(trial) state_end_f(trial)], [-5000 5000], 'r','LineWidth',0.5)
        end 
    end 
    ax.XTick = FrameVals;
    ax.XTickLabel = min_TimeVals;
    ax.FontSize = 20;
    xlim([0 length(Cdata)])
    ylim([-1.5 1.5])
    xlabel('time (min)')
    if smoothQ ==  1
        title({'data averaged across all terminals'; sprintf('smoothed by %0.2f seconds',filtTime)})
    elseif smoothQ == 0 
        title('raw data averaged across all terminals')
    end 
    legend('green - red channel')
end 


%% sort data based on ca peak location 
%BELOW DOES NOT HAVE OPTION FOR DOING SINGLE TERMINAL DATA SORTING OR
%PLOTTING...YET
%{
windSize = 5; %input('How big should the window be around Ca peak in seconds?');
sortedBdata = zeros(1,floor((windSize*FPS)+1));
sortedCdata = zeros(1,floor((windSize*FPS)+1));
sortedVdata = zeros(1,floor((windSize*FPS)+1));
% sortedWdata = zeros(1,round((windSize*FPS)+1));
for peak = 1:length(locs)
    if locs(peak)-(windSize/2)*FPS > 0 && locs(peak)+(windSize/2)*FPS < length(Cdata)
        start = floor(locs(peak)-(windSize/2)*FPS);
        stop = floor(start + (windSize*FPS));%round(locs(peak)+(windSize/2)*FPS);
        if start == 0 
            start = 1 ;
            stop = floor(start + (windSize*FPS));
        end 
        sortedBdata(peak,:) = SBdata(start:stop);
        sortedCdata(peak,:) = SCdata(start:stop);
        sortedVdata(peak,:) = SVdata(start:stop);
    end 
end 

%replace rows of all 0s w/NaNs
nonZeroRowsB = all(sortedBdata == 0,2);
sortedBdata(nonZeroRowsB,:) = NaN;
nonZeroRowsC = all(sortedCdata == 0,2);
sortedCdata(nonZeroRowsC,:) = NaN;
nonZeroRowsV = all(sortedVdata == 0,2);
sortedVdata(nonZeroRowsV,:) = NaN;
% nonZeroRowsW = all(sortedWdata == 0,2);
% sortedWdata(nonZeroRowsW,:) = NaN;


%% average and plot 
FPSstack = FPS;

figure;
avB = nanmean(sortedBdata,1);
avC = nanmean(sortedCdata,1);
avV = nanmean(sortedVdata,1);
% avW = nanmean(sortedWdata,1);
semB = ((nanstd(sortedBdata,1)))/(sqrt(size(sortedBdata,1)));
semC = ((nanstd(sortedCdata,1)))/(sqrt(size(sortedCdata,1)));
semV = ((nanstd(sortedVdata,1)))/(sqrt(size(sortedVdata,1)));
% semW = ((nanstd(sortedWdata,1)))/(sqrt(size(sortedWdata,1)));


Frames = size(avC,2);
Frames_pre_stim_start = -((Frames-1)/2); 
Frames_post_stim_start = (Frames-1)/2; 
sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack));
FrameVals = round((1:FPSstack:Frames)-5); 
ax=gca;
hold all
% for row = 1:5
%     plot(sortedBdata(row,:),'r','LineWidth',2)
%     plot(sortedCdata(row,:),'b','LineWidth',2)
% end 
plot(avB,'r','LineWidth',2);
plot(avC,'b','LineWidth',2);
plot(avV,'k','LineWidth',2);
varargout = boundedline(1:size(avB,2),avB,semB,'r','transparency', 0.3,'alpha');                                                                             
varargout = boundedline(1:size(avC,2),avC,semC,'b','transparency', 0.3,'alpha'); 
varargout = boundedline(1:size(avV,2),avV,semV,'k','transparency', 0.3,'alpha'); 
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;
ax.FontSize = 20;
xlim([0 length(avC)])
ylim([-1 1])
legend('BBB data','DA calcium','Vessel width')
title(sprintf('%d calcium peaks',length(peaks)))
%}

%% sort diff data into different trial types to see effects of stims 
%THIS IS SET UP FOR DIFFCDATA THAT SHOWS INDIVIDUAL TERMINAL ACTIVITY - TO
%GET SEM 
clearvars diffAV diffSEM tTdata

%reogranize diff data so I can get the SEM 
diffCarray = zeros(length(diffCdata),length(diffCdata{1}));
greenCarray = zeros(length(diffCdata),length(diffCdata{1}));
redCarray = zeros(length(diffCdata),length(diffCdata{1}));
for ccell = 1:length(diffCdata)
    if isempty(diffCdata{ccell}) == 0 
        diffCarray(ccell,:) = diffCdata{ccell};
        greenCarray(ccell,:) = SCdata{ccell};
        redCarray(ccell,:) = RSCdata{ccell};
    end 
end 
%replace rows of all 0s w/NaNs
nonZeroRows = all(diffCarray == 0,2);
diffCarray(nonZeroRows,:) = NaN;
greenCarray(nonZeroRows,:) = NaN;
redCarray(nonZeroRows,:) = NaN;
%get AV and SEM 
diffSEM = nanstd(diffCarray,1)/sqrt(size(diffCarray,1));
diffAV = nanmean(diffCarray,1);
greenSEM = nanstd(greenCarray,1)/sqrt(size(greenCarray,1));
greenAV = nanmean(greenCarray,1);
redSEM = nanstd(redCarray,1)/sqrt(size(redCarray,1));
redAV = nanmean(redCarray,1);

trialLengths = state_end_f - state_start_f;
lengthGroups = kmeans(trialLengths,2);
count1 = 1;count2 = 1;count3 = 1;count4 = 1;
for trial = 1:size(TrialTypes,1)
    if state_start_f(trial)-floor(FPSstack*20) > 0 && state_end_f(trial)+floor(FPSstack*20) < length(diffAV)
        if TrialTypes(trial,2) == 1 % blue trials 
            if trialLengths(trial) == floor(FPSstack*2)
                tTdata{1}(count1,:) = diffAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20)); 
                GtTdata{1}(count1,:) = greenAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20)); 
                RtTdata{1}(count1,:) = redAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20)); 
                count1 = count1+1;
            elseif trialLengths(trial) == floor(FPSstack*20)
                tTdata{2}(count2,:) = diffAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                GtTdata{2}(count2,:) = greenAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                RtTdata{2}(count2,:) = redAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                count2 = count2+1;
            end 
        elseif TrialTypes(trial,2) == 2 % red trials 
            if trialLengths(trial) == floor(FPSstack*2)
                tTdata{3}(count3,:) = diffAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                GtTdata{3}(count3,:) = greenAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                RtTdata{3}(count3,:) = redAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                count3 = count3+1;
            elseif trialLengths(trial) == floor(FPSstack*20)
                tTdata{4}(count4,:) = diffAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                GtTdata{4}(count4,:) = greenAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                RtTdata{4}(count4,:) = redAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                count4 = count4+1;
            end 
        end 
    end 
end 

%% plot trialType data
AVtTdata = cell(1,length(tTdata));
SEMtTdata = cell(1,length(tTdata));
AVGtTdata = cell(1,length(tTdata));
SEMGtTdata = cell(1,length(tTdata));
AVRtTdata = cell(1,length(tTdata));
SEMRtTdata = cell(1,length(tTdata));
baselineEndFrame = floor(20*(FPSstack));
for tType = 1:length(tTdata)
    AVtTdata{tType} = mean(tTdata{tType},1);
    SEMtTdata{tType} = std(tTdata{tType},1)/sqrt(size(tTdata{tType},1));
    AVGtTdata{tType} = mean(GtTdata{tType},1);
    SEMGtTdata{tType} = std(GtTdata{tType},1)/sqrt(size(GtTdata{tType},1));
    AVRtTdata{tType} = mean(RtTdata{tType},1);
    SEMRtTdata{tType} = std(RtTdata{tType},1)/sqrt(size(RtTdata{tType},1));
    figure; 
    hold all;
    if tType == 1 || tType == 3 
        Frames = size(AVtTdata{tType},2);        
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+1);
        FrameVals = floor((1:FPSstack*2:Frames)-1); 
    elseif tType == 2 || tType == 4 
        Frames = size(AVtTdata{tType},2);
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+10);
        FrameVals = floor((1:FPSstack*2:Frames)-1); 
    end 
    
    if tType == 1 
        plot([round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2))], [-5000 5000], 'b','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
%                 alpha(0.5)   
    elseif tType == 3 
        plot([round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2))], [-5000 5000], 'r','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
%                 alpha(0.5)                       
    elseif tType == 2 
        plot([round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20))], [-5000 5000], 'b','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
%                 alpha(0.5)   
    elseif tType == 4 
        plot([round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20))], [-5000 5000], 'r','LineWidth',2)
        plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
%                 alpha(0.5)  
    end

    
%     varargout = boundedline(1:size(AVtTdata{tType},2),AVtTdata{tType},SEMtTdata{tType},'k','transparency', 0.5);
    for trial = 1:size(tTdata{tType},1)
%         plot(RtTdata{tType}(trial,:),'LineWidth',1)
        plot(GtTdata{tType}(trial,:),'LineWidth',1)
%         plot(tTdata{tType}(trial,:),'LineWidth',1)
    end 
%     plot(AVRtTdata{tType},'Color',[0.5 0 0],'LineWidth',3)
    plot(AVGtTdata{tType},'Color',[0 0.5 0],'LineWidth',3)
%     plot(AVtTdata{tType},'k','LineWidth',3)
    if tType == 1 || tType == 2
    elseif tType == 3 || tType == 4
    end 
    ax=gca;
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;
    ax.FontSize = 20;
    xlim([0 Frames])
    ylim([-1.5 1.5])
    xlabel('time (s)')
    if smoothQ == 1
        title(sprintf('data smoothed by %0.2f sec',filtTime));
    elseif smoothQ == 0
        title('raw data')
    end 
    
end 


