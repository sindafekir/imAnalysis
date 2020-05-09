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
%         [RSCdata] = MovMeanSmoothData(RCdata,filtTime,FPS);
%         [SVdata] = MovMeanSmoothData(Vdata,filtTime,FPS);
    elseif ccellQ == 1 
        if termQ == 0
            SCdata = cell(1,length(CcellData));
            RSCdata = cell(1,length(CcellData));
            for ccell = 1:length(CcellData)
                if isempty(CcellData{ccell}) == 0 
                    [SC_data] = MovMeanSmoothData(CcellData{ccell},filtTime,FPS);
%                     [RSC_data] = MovMeanSmoothData(RCcellData{ccell},filtTime,FPS);
                    SCdata{ccell} = SC_data;
%                     RSCdata{ccell} = RSC_data;
                end 
            end 
        elseif termQ == 1 
            SCdata = cell(1,length(terminals));
            RSCdata = cell(1,length(terminals));
            for ccell = 1:length(terminals)
                if isempty(CcellData{terminals(ccell)}) == 0 
                    [SC_data] = MovMeanSmoothData(CcellData{terminals(ccell)},filtTime,FPS);
%                     [RSC_data] = MovMeanSmoothData(RCcellData{terminals(ccell)},filtTime,FPS);
                    SCdata{ccell} = SC_data;
%                     RSCdata{ccell} = RSC_data;
                end 
            end     
        end 
    end       
elseif smoothQ == 0
    if ccellQ == 0
%         SBdata = Bdata;
        SCdata = Cdata;
%         RSCdata = RCdata;
%         SVdata = Vdata;
    elseif ccellQ == 1 
        if termQ == 0
            SCdata = cell(1,length(CcellData));
            RSCdata = cell(1,length(CcellData));
            for ccell = 1:length(CcellData)
                if isempty(CcellData{ccell}) == 0
                    SCdata{ccell} = CcellData{ccell};
%                     RSCdata{ccell} = RCcellData{ccell};
                end 
            end
        elseif termQ == 1
%             SBdata = Bdata;
%             SVdata = Vdata;
            SCdata = cell(1,length(terminals));
%             RSCdata = cell(1,length(terminals));
            for ccell = 1:length(terminals)
                if isempty(CcellData{terminals(ccell)}) == 0
                    SCdata{ccell} = CcellData{terminals(ccell)};
%                     RSCdata{ccell} = RCcellData{terminals(ccell)};
                end 
            end
        end 
    end 
end

%% prep trial type data 
[framePeriod] = getUserInput(userInput,'What is the framePeriod? ');
[state] = getUserInput(userInput,'What teensy state does the stimulus happen in?');
[HDFchart,state_start_f,state_end_f,FPS,vel_wheel_data,TrialTypes] = makeHDFchart_redBlueStim(state,framePeriod);

TrialTypes = TrialTypes(1:length(state_start_f),:);
state_start_f = floor(state_start_f/3);
state_end_f = floor(state_end_f/3);
trialLength = state_end_f - state_start_f;

%% find peaks and then plot where they are in the entire TS 
%{
clear diffCdata
if ccellQ ==  1
    if termQ == 0 
        for ccell = 1:length(CcellData)
            if isempty(CcellData{ccell}) == 0
                [peaks, locs] = findpeaks(SCdata{ccell},'MinPeakProminence',5000); %0.6,0.8,0.9,1

                FPSstack = FPS/3; 
                Frames = size(SCdata{ccell},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*50:Frames_post_stim_start)/FPSstack)+102);
                min_TimeVals = round(sec_TimeVals/60,2);
                FrameVals = round((1:FPSstack*50:Frames)-1); 
                figure;
                ax=gca;
                hold all
                % plot(Bdata,'r','LineWidth',3);
%                 diffCdata{ccell} = SCdata{ccell} - RSCdata{ccell};
                plot(SCdata{ccell},'Color',[0 0.5 0],'LineWidth',1)
    %             plot(RSCdata{ccell},'r','LineWidth',1)
%                 plot(diffCdata{ccell},'k','LineWidth',1)
%                 for loc = 1:length(locs)
%                     plot([locs(loc) locs(loc)], [-5000 5000], 'k','LineWidth',2)
%                 end 
                for trial = 1:size(state_start_f,1)
                    if TrialTypes(trial,2) == 1
                        plot([state_start_f(trial) state_start_f(trial)], [-5000 5000], 'b','LineWidth',1)
                        plot([state_end_f(trial) state_end_f(trial)], [-5000 5000], 'b','LineWidth',0.5)
                    elseif TrialTypes(trial,2) == 2
                        plot([state_start_f(trial) state_start_f(trial)], [-5000 5000], 'r','LineWidth',1)
                        plot([state_end_f(trial) state_end_f(trial)], [-5000 5000], 'r','LineWidth',0.5)
                    end 
                end 
                ax.XTick = FrameVals;
                ax.XTickLabel = min_TimeVals;
                ax.FontSize = 20;
                xlim([0 length(Cdata)])
                ylim([-200 500])
                xlabel('time (min)')
                if smoothQ ==  1
                    title({sprintf('terminal #%d data',ccell); sprintf('smoothed by %0.2f seconds',filtTime)})
                elseif smoothQ == 0 
                    title(sprintf('terminal #%d raw data',ccell))
                end 
%                 legend('green - red channel')
            end 
        end 
    elseif termQ == 1 
        stdTrace = cell(1,length(terminals));
        sigPeaks = cell(1,length(terminals));
        sigLocs = cell(1,length(terminals));
        for ccell = 1:length(terminals)
            if isempty(CcellData{terminals(ccell)}) == 0
                [peaks, locs] = findpeaks(SCdata{ccell},'MinPeakProminence',0.1,'MinPeakWidth',2); %0.6,0.8,0.9,1

                FPSstack = FPS/3; 
                Frames = size(SCdata{ccell},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*50:Frames_post_stim_start)/FPSstack)+51);
                min_TimeVals = round(sec_TimeVals/60,2);
                FrameVals = round((1:FPSstack*50:Frames)-1); 
                figure;
                ax=gca;
                hold all
                % plot(Bdata,'r','LineWidth',3);
%                 diffCdata{ccell} = SCdata{ccell} - RSCdata{ccell};
                plot(SCdata{ccell},'g','LineWidth',1)
    %             plot(RSCdata{ccell},'r','LineWidth',1)
%                 plot(diffCdata{ccell},'k','LineWidth',1)
                stdTrace{ccell} = std(SCdata{ccell});  
                count = 1 ; 
                for loc = 1:length(locs)
                    if peaks(loc) > stdTrace{ccell}*3
                        sigPeaks{ccell}(count) = peaks(loc);
                        sigLocs{ccell}(count) = locs(loc);
                        plot([locs(loc) locs(loc)], [-5000 5000], 'k','LineWidth',2)
                        count = count + 1;
                    end 
                end 
                for trial = 1:size(state_start_f,1)
                    if TrialTypes(trial,2) == 1
                        plot([state_start_f(trial) state_start_f(trial)], [-5000 5000], 'b','LineWidth',2)
                        plot([state_end_f(trial) state_end_f(trial)], [-5000 5000], 'b','LineWidth',2)
                    elseif TrialTypes(trial,2) == 2
                        plot([state_start_f(trial) state_start_f(trial)], [-5000 5000], 'r','LineWidth',2)
                        plot([state_end_f(trial) state_end_f(trial)], [-5000 5000], 'r','LineWidth',2)
                    end 
                end 
                ax.XTick = FrameVals;
                ax.XTickLabel = min_TimeVals;
                ax.FontSize = 20;
                xlim([0 length(Cdata)])
                ylim([-200 200])
                xlabel('time (min)')
                if smoothQ ==  1
                    title({sprintf('terminal #%d data',terminals(ccell)); sprintf('smoothed by %0.2f seconds',filtTime)})
                elseif smoothQ == 0 
                    title(sprintf('terminal #%d raw data',terminals(ccell)))
                end 
%                 legend('green - red channel')
            end 
        end 
        
    end 
elseif  ccellQ ==  0
    [peaks, locs] = findpeaks(SCdata,'MinPeakProminence',5000); %0.6,0.8,0.9,1

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
%     diffCdata = SCdata - RSCdata;
    plot(SCdata,'Color',[0 0.5 0],'LineWidth',1)
%     plot(SCdata,'k','LineWidth',1)
%     plot(RSCdata,'r','LineWidth',1)
%     plot(diffCdata,'k','LineWidth',1)
    for loc = 1:length(locs)
        plot([locs(loc) locs(loc)], [-5000 5000], 'k','LineWidth',2)
    end 
    for trial = 1:size(state_start_f,1)
        if TrialTypes(trial,2) == 1
            plot([state_start_f(trial) state_start_f(trial)], [-5000 5000], 'b','LineWidth',1)
            plot([state_end_f(trial) state_end_f(trial)], [-5000 5000], 'b','LineWidth',1)
        elseif TrialTypes(trial,2) == 2
            plot([state_start_f(trial) state_start_f(trial)], [-5000 5000], 'r','LineWidth',1)
            plot([state_end_f(trial) state_end_f(trial)], [-5000 5000], 'r','LineWidth',1)
        end 
    end 
    ax.XTick = FrameVals;
    ax.XTickLabel = min_TimeVals;
    ax.FontSize = 20;
    xlim([0 length(Cdata)])
%     ylim([-1.5 1.5])
    xlabel('time (min)')
    if smoothQ ==  1
        title({'data averaged across all terminals'; sprintf('smoothed by %0.2f seconds',filtTime)})
    elseif smoothQ == 0 
        title('raw data averaged across all terminals')
    end 
%     legend('green - red channel')
end 


%% sort data based on ca peak location 

windSize = 5; %input('How big should the window be around Ca peak in seconds?');

if ccellQ ==  0
%         sortedBdata = zeros(1,floor((windSize*FPS)+1));
        sortedCdata = zeros(1,floor((windSize*FPS)+1));
%         sortedVdata = zeros(1,floor((windSize*FPS)+1));
        % sortedWdata = zeros(1,round((windSize*FPS)+1));
        for peak = 1:length(sigLocs)
            if sigLocs(peak)-(windSize/2)*FPS > 0 && sigLocs(peak)+(windSize/2)*FPS < length(Cdata)
                start = floor(sigLocs(peak)-(windSize/2)*FPS);
                stop = floor(start + (windSize*FPS));%round(locs(peak)+(windSize/2)*FPS);
                if start == 0 
                    start = 1 ;
                    stop = floor(start + (windSize*FPS));
                end 
        %         sortedBdata(peak,:) = SBdata(start:stop);
                sortedCdata(peak,:) = SCdata(start:stop);
        %         sortedVdata(peak,:) = SVdata(start:stop);
            end 
        end 

        %replace rows of all 0s w/NaNs
        % nonZeroRowsB = all(sortedBdata == 0,2);
        % sortedBdata(nonZeroRowsB,:) = NaN;
        nonZeroRowsC = all(sortedCdata == 0,2);
        sortedCdata(nonZeroRowsC,:) = NaN;
        % nonZeroRowsV = all(sortedVdata == 0,2);
        % sortedVdata(nonZeroRowsV,:) = NaN;
        % nonZeroRowsW = all(sortedWdata == 0,2);
        % sortedWdata(nonZeroRowsW,:) = NaN;
elseif ccellQ == 1 
    if termQ == 0
        sortedCdata = cell(1,floor(length(CcellData)));
        for ccell = 1:length(CcellData)
            if isempty(CcellData{ccell}) == 0
        
                for peak = 1:length(sigLocs{ccell})
                    if sigLocs{ccell}(peak)-(windSize/2)*FPS > 0 && sigLocs{ccell}(peak)+(windSize/2)*FPS < length(Cdata)
                        start = floor(sigLocs{ccell}(peak)-(windSize/2)*FPS);
                        stop = floor(start + (windSize*FPS));%round(locs(peak)+(windSize/2)*FPS);
                        if start == 0 
                            start = 1 ;
                            stop = floor(start + (windSize*FPS));
                        end 
                %         sortedBdata(peak,:) = SBdata(start:stop);
                        sortedCdata{ccell}(peak,:) = SCdata{ccell}(start:stop);
                %         sortedVdata(peak,:) = SVdata(start:stop);
                    end 
                end 

                %replace rows of all 0s w/NaNs
                % nonZeroRowsB = all(sortedBdata == 0,2);
                % sortedBdata(nonZeroRowsB,:) = NaN;
                nonZeroRowsC = all(sortedCdata{ccell} == 0,2);
                sortedCdata{ccell}(nonZeroRowsC,:) = NaN;
                % nonZeroRowsV = all(sortedVdata == 0,2);
                % sortedVdata(nonZeroRowsV,:) = NaN;
                % nonZeroRowsW = all(sortedWdata == 0,2);
                % sortedWdata(nonZeroRowsW,:) = NaN;  
            end 
        end 
        
    elseif termQ == 1 
        sortedCdata = cell(1,length(terminals));
        sortedBdata = cell(1,length(terminals));
        sortedVdata = cell(1,length(terminals));
        for ccell = 1:length(terminals)
            if isempty(CcellData{terminals(ccell)}) == 0
        
                for peak = 1:length(sigLocs{ccell})
                    if sigLocs{ccell}(peak)-(windSize/2)*FPS > 0 && sigLocs{ccell}(peak)+(windSize/2)*FPS < length(Cdata)
                        start = floor(sigLocs{ccell}(peak)-(windSize/2)*FPS);
                        stop = floor(start + (windSize*FPS));%round(locs(peak)+(windSize/2)*FPS);
                        if start == 0 
                            start = 1 ;
                            stop = floor(start + (windSize*FPS));
                        end 
                        sortedBdata{ccell}(peak,:) = SBdata(start:stop);
                        sortedCdata{ccell}(peak,:) = SCdata{ccell}(start:stop);
                        sortedVdata{ccell}(peak,:) = SVdata(start:stop);
                    end 
                end 

                %replace rows of all 0s w/NaNs
                nonZeroRowsB = all(sortedBdata{ccell} == 0,2);
                sortedBdata{ccell}(nonZeroRowsB,:) = NaN;
                nonZeroRowsC = all(sortedCdata{ccell} == 0,2);
                sortedCdata{ccell}(nonZeroRowsC,:) = NaN;
                nonZeroRowsV = all(sortedVdata{ccell} == 0,2);
                sortedVdata{ccell}(nonZeroRowsV,:) = NaN;
                % nonZeroRowsW = all(sortedWdata == 0,2);
                % sortedWdata(nonZeroRowsW,:) = NaN;  
            end 
        end 
    end 
end 

%% average and plot calcium peak aligned data 
%BELOW DOES NOT HAVE OPTION FOR DOING SINGLE TERMINAL DATA SORTING OR
%PLOTTING...YET

%average across peaks and terminals 
avC1 = zeros(length(sortedCdata),size(sortedCdata{1},2));
avB1 = zeros(length(sortedBdata),size(sortedBdata{1},2));
avV1 = zeros(length(sortedVdata),size(sortedVdata{1},2));
for term = 1:length(sortedCdata)
    if isempty(sortedCdata{term}) == 0 
        avC1(term,:) = nanmean(sortedCdata{term},1);
        avB1(term,:) = nanmean(sortedBdata{term},1);
        avV1(term,:) = nanmean(sortedVdata{term},1);
    end 
end 


avB2 = nanmean(avB1,1);
avC2 = nanmean(avC1,1);
avV2 = nanmean(avV1,1);

%normalize to baseline period 
baselinePer = floor(length(avC2)/3);
avC = ((avC2-mean(avC2(1:baselinePer)))/mean(avC2(1:baselinePer)))*100;
avB = ((avB2-mean(avB2(1:baselinePer)))/mean(avB2(1:baselinePer)))*100;
avV = ((avV2-mean(avV2(1:baselinePer)))/mean(avV2(1:baselinePer)))*100;

semB1 = ((nanstd(avB1,1)))/(sqrt(size(avB1,1)));
semC1 = ((nanstd(avC1,1)))/(sqrt(size(avC1,1)));
semV1 = ((nanstd(avV1,1)))/(sqrt(size(avV1,1)));

semC = ((semC1))/mean(semC1(1:baselinePer))*100;
semB = ((semB1))/mean(semB1(1:baselinePer))*100;
semV = ((semV1))/mean(semV1(1:baselinePer))*100;

figure;
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
% varargout = boundedline(1:size(avB,2),avB,semB,'r','transparency', 0.3,'alpha');                                                                             
% varargout = boundedline(1:size(avC,2),avC,semC,'b','transparency', 0.3,'alpha'); 
% varargout = boundedline(1:size(avV,2),avV,semV,'k','transparency', 0.3,'alpha'); 
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;
ax.FontSize = 20;
xlim([0 length(avC)])
ylim([-200 200])
% legend('BBB data','DA calcium','Vessel width')
xlabel('time (s)')
ylabel('percent change')
% title(sprintf('%d calcium peaks',length(peaks)))
%}

%% sort data into different trial types to see effects of stims 
%THIS IS SET UP FOR DIFFCDATA THAT SHOWS INDIVIDUAL TERMINAL ACTIVITY - TO
%GET SEM 
clearvars diffAV diffSEM tTdata GtTdataTerm

%make sure the trial lengths are the same per trial type 
%set ideal trial lengths 
lenT1 = floor(FPSstack*2); % 2 second trials 
lenT2 = floor(FPSstack*20); % 20 second trials 
%identify current trial lengths 
[kIdx,kMeans] = kmeans(trialLength,2);
%edit kMeans list so trialLengths is what they should be 
for len = 1:length(kMeans)
    if kMeans(len)-lenT1 < abs(kMeans(len)-lenT2)
        kMeans(len) = lenT1;
    elseif kMeans(len)-lenT1 > abs(kMeans(len)-lenT2)
        kMeans(len) = lenT2;
    end 
end 
%change state_end_f so all trial lengths match up 
for trial = 1:length(state_start_f)
    state_end_f(trial,1) = state_start_f(trial)+kMeans(kIdx(trial));
end 
trialLength = state_end_f - state_start_f;

%reogranize diff data so I can get the SEM 
% diffCarray = zeros(length(diffCdata),length(diffCdata{1}));
greenCarray = zeros(length(SCdata),length(SCdata{2}));
% redCarray = zeros(length(diffCdata),length(diffCdata{1}));
for ccell = 1:length(SCdata)
    if isempty(SCdata{ccell}) == 0 
%         diffCarray(ccell,:) = diffCdata{ccell};
        greenCarray(ccell,:) = SCdata{ccell};
%         redCarray(ccell,:) = RSCdata{ccell};
    end 
end 
%replace rows of all 0s w/NaNs
nonZeroRows = all(greenCarray == 0,2);
% diffCarray(nonZeroRows,:) = NaN;
greenCarray(nonZeroRows,:) = NaN;
% redCarray(nonZeroRows,:) = NaN;

%get AV and SEM 
% diffSEM = nanstd(diffCarray,1)/sqrt(size(diffCarray,1));
% diffAV = nanmean(diffCarray,1);
greenSEM = nanstd(greenCarray,1)/sqrt(size(greenCarray,1));
greenAV = nanmean(greenCarray,1);
% redSEM = nanstd(redCarray,1)/sqrt(size(redCarray,1));
% redAV = nanmean(redCarray,1);


for term = 1:size(greenCarray,1)
    count1 = 1;count2 = 1;count3 = 1;count4 = 1;
    for trial = 1:size(state_start_f,1)
        if state_start_f(trial)-floor(FPSstack*20) > 0 && state_end_f(trial)+floor(FPSstack*20) < length(greenAV)
            if TrialTypes(trial,2) == 1 % blue trials 
                if trialLength(trial) == floor(FPSstack*2)
    %                 tTdata{1}(count1,:) = diffAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20)); 
                    GtTdata{1}(count1,:) = greenAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20)); 
                    GtTdataTerm{1}{term}(count1,:) = greenCarray(term,state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
    %                 RtTdata{1}(count1,:) = redAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20)); 
                    count1 = count1+1;
                elseif trialLength(trial) == floor(FPSstack*20)
    %                 tTdata{2}(count2,:) = diffAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                    GtTdata{2}(count2,:) = greenAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                    GtTdataTerm{2}{term}(count2,:) = greenCarray(term,state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
    %                 RtTdata{2}(count2,:) = redAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                    count2 = count2+1;
                end 
            elseif TrialTypes(trial,2) == 2 % red trials 
                if trialLength(trial) == floor(FPSstack*2)
    %                 tTdata{3}(count3,:) = diffAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                    GtTdata{3}(count3,:) = greenAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                    GtTdataTerm{3}{term}(count3,:) = greenCarray(term,state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
    %                 RtTdata{3}(count3,:) = redAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                    count3 = count3+1;
                elseif trialLength(trial) == floor(FPSstack*20)
    %                 tTdata{4}(count4,:) = diffAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                    GtTdata{4}(count4,:) = greenAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                    GtTdataTerm{4}{term}(count4,:) = greenCarray(term,state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
    %                 RtTdata{4}(count4,:) = redAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                    count4 = count4+1;
                end 
            end 
        end 
    end 
end

%% organize trialType data averaged across all relevant terminals 
%{
% AVtTdata = cell(1,length(tTdata));
% SEMtTdata = cell(1,length(tTdata));
AVGtTdata = cell(1,length(GtTdata));
SEMGtTdata = cell(1,length(GtTdata));
% AVRtTdata = cell(1,length(tTdata));
% SEMRtTdata = cell(1,length(tTdata));
baselineEndFrame = floor(20*(FPSstack));
for tType = 1:length(GtTdata)
    if isempty(GtTdata{tType}) == 0 
    %     AVtTdata{tType} = mean(tTdata{tType},1);
    %     SEMtTdata{tType} = std(tTdata{tType},1)/sqrt(size(tTdata{tType},1));
        AVGtTdata{tType} = mean(GtTdata{tType},1);
        SEMGtTdata{tType} = std(GtTdata{tType},1)/sqrt(size(GtTdata{tType},1));
    %     AVRtTdata{tType} = mean(RtTdata{tType},1);
    %     SEMRtTdata{tType} = std(RtTdata{tType},1)/sqrt(size(RtTdata{tType},1));
        figure; 
        hold all;
        if tType == 1 || tType == 3 
            Frames = size(AVGtTdata{tType},2);        
            Frames_pre_stim_start = -((Frames-1)/2); 
            Frames_post_stim_start = (Frames-1)/2; 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+1);
            FrameVals = floor((1:FPSstack*2:Frames)-1); 
        elseif tType == 2 || tType == 4 
            Frames = size(AVGtTdata{tType},2);
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
        for trial = 1:size(GtTdata{tType},1)
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
        ylim([-200 200])
        xlabel('time (s)')
        if smoothQ == 1
            title(sprintf('data smoothed by %0.2f sec',filtTime));
        elseif smoothQ == 0
            title('raw data')
        end 
    end 
end

%% plot trialType data per terminal 

for term = 1:size(GtTdataTerm{4},2)
    AVGtTdata = cell(1,length(GtTdataTerm));
    SEMGtTdata = cell(1,length(GtTdataTerm));
    baselineEndFrame = floor(20*(FPSstack));
    for tType = 1:length(GtTdataTerm)
        if isempty(GtTdataTerm{tType}) == 0 
            AVGtTdata{tType} = mean(GtTdataTerm{tType}{term},1);
            SEMGtTdata{tType} = std(GtTdataTerm{tType}{term},1)/sqrt(size(GtTdataTerm{tType}{term},1));
            figure; 
            hold all;
            if tType == 1 || tType == 3 
                Frames = size(AVGtTdata{tType},2);        
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+1);
                FrameVals = floor((1:FPSstack*2:Frames)-1); 
            elseif tType == 2 || tType == 4 
                Frames = size(AVGtTdata{tType},2);
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
            for trial = 1:size(GtTdataTerm{tType}{term},1)
                plot(GtTdataTerm{tType}{term}(trial,:),'LineWidth',1)
            end 
            plot(AVGtTdata{tType},'Color',[0 0.5 0],'LineWidth',3)
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
%}
