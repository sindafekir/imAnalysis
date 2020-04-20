%% get userInput
temp = matfile('SF56_20190718_ROI2_1_regIms_green.mat');
% userInput = temp.userInput; 
regStacks = temp.regStacks;

%% make HDF chart and get wheel data  
% disp('Making HDF Chart')
% [imAn1funcDir] = getUserInput(userInput,'imAnalysis1_functions Directory');
% cd(imAn1funcDir);
% [framePeriod] = getUserInput(userInput,'What is the framePeriod? ');
% [state] = getUserInput(userInput,'What teensy state does the stimulus happen in?');
% [HDFchart,state_start_f,state_end_f,FPS,vel_wheel_data,TrialTypes] = makeHDFchart_redBlueStim(state,framePeriod);
% 
%% sort data into 2 sec blue, 20 sec blue, 2 sec red, 20 sec red, baseline periods  
% disp('Sorting Data')
% %go to the right directory for functions 
% [imAn1funcDir] = getUserInput(userInput,'imAnalysis1_functions Directory');
% cd(imAn1funcDir);
% 
% %find the diffent trial types 
% [stimTimes] = getUserInput(userInput,"Stim Time Lengths (sec)"); 
% [stimTypeNum] = getUserInput(userInput,"How many different kinds of stimuli were used?");
% [uniqueTrialData,uniqueTrialDataOcurr,indices,state_start_f,uniqueTrialDataTemplate] = separateTrialTypes(TrialTypes,state_start_f,state_end_f,stimTimes,numZplanes,FPS,stimTypeNum); 
% 
% %sort data 
% [sortedBdata,indices] = eventTriggeredAverages2(Bdata,state_start_f,indices,uniqueTrialData,uniqueTrialDataOcurr,numZplanes);
% [sortedCdata,~] = eventTriggeredAverages2(Cdata,state_start_f,indices,uniqueTrialData,uniqueTrialDataOcurr,numZplanes);
% [sortedVdata,~] = eventTriggeredAverages2(Vdata,state_start_f,indices,uniqueTrialData,uniqueTrialDataOcurr,numZplanes);
% 
% %figure out total time (s) spent in red light, blue light, and ISI periods 
% numFrames = zeros(1,length(sortedBdata));
% for tType = 1:length(sortedBdata)
%     if isempty(sortedBdata{tType}) == 0 
%         for per = 1:length(sortedBdata{tType})
%             if isempty(sortedBdata{tType}{per}) == 0 
%                 if per == 1 
%                     num_Frames = length(sortedBdata{tType}{per});
%                 else
%                     num_Frames = num_Frames + length(sortedBdata{tType}{per});
%                 end 
%             end 
%         end 
%         numFrames(tType) = num_Frames; 
%     end 
% end 
% 
% numSeconds = numFrames/FPSstack; 

  
%% smooth data 
% smoothQ = input('Do you want to smooth your data? Yes = 1. No = 0. ');
% if smoothQ ==  1
%     filtTime = input('How many seconds do you want to smooth your data by? '); 
%     SBdata = cell(1,length(sortedBdata));
%     SCdata = cell(1,length(sortedCdata));
%     SVdata = cell(1,length(sortedVdata));
%     for tType = 1:length(sortedBdata)
%         for per = 1:length(sortedBdata{tType})
%             if isempty(sortedBdata{tType}{per}) == 0
%                 [SB_data] = MovMeanSmoothData(sortedBdata{tType}{per},filtTime,FPS);
%                 [SC_data] = MovMeanSmoothData(sortedCdata{tType}{per},filtTime,FPS);
%                 [SV_data] = MovMeanSmoothData(sortedVdata{tType}{per},filtTime,FPS);
%                 SBdata{tType}{per} = SB_data; 
%                 SCdata{tType}{per} = SC_data; 
%                 SVdata{tType}{per} = SV_data; 
%             end 
%         end 
%     end 
% elseif smoothQ == 0
%     SBdata = sortedBdata;
%     SCdata = sortedCdata;
%     SVdata = sortedVdata;
% end

%% find calcium peaks 
peaks = cell(1,length(sortedBdata));
locs = cell(1,length(sortedBdata));
for tType = 1:length(sortedBdata)
    for per = 1:length(sortedBdata{tType})
        if isempty(sortedBdata{tType}{per}) == 0
            [peaks1, locs1] = findpeaks(SCdata{tType}{per},'MinPeakProminence',0.8); %0.01 \\0.6,0.8,0.9 these values are too large for how small the stim incriments are 
            peaks{tType}{per} = peaks1;
            locs{tType}{per} = locs1;
        end 
    end
end 



%% sort data based on ca peak location 
FPSstack = FPS/3;

windSize = 1; %input('How big should the window be around Ca peak in seconds?');
BdataPeaks = cell(1,length(sortedBdata));
CdataPeaks = cell(1,length(sortedBdata));
VdataPeaks = cell(1,length(sortedBdata));
for tType = 1:length(sortedBdata)
    for per = 1:length(sortedBdata{tType})
        if isempty(locs{tType}{per}) == 0
            for peak = 1:length(locs{tType}{per})
                if locs{tType}{per}(peak)-(windSize/2)*FPSstack > 0 && locs{tType}{per}(peak)+(windSize/2)*FPSstack < length(SBdata{tType}{per})
                    start = ceil(locs{tType}{per}(peak)-(windSize/2)*FPSstack);
                    stop = ceil(start + (windSize*FPSstack));
                    if start == 0 
                        start = 1 ;
                        stop = ceil(start + (windSize*FPSstack));
                    end 
                    if stop == length(SBdata{tType}{per}) || stop < length(SBdata{tType}{per})
                        BdataPeaks{tType}{per}(peak,:) = SBdata{tType}{per}(start:stop);
                        CdataPeaks{tType}{per}(peak,:) = SCdata{tType}{per}(start:stop);
                        VdataPeaks{tType}{per}(peak,:) = SVdata{tType}{per}(start:stop);
                    end 
                    
                end 
            end 
        end
    end 
end 

for tType = 1:length(BdataPeaks)
    for per = 1:length(BdataPeaks{tType})
        if isempty(BdataPeaks{tType}{per}) == 0
            %replace rows of all 0s w/NaNs
            nonZeroRowsB = all(BdataPeaks{tType}{per} == 0,2);
            BdataPeaks{tType}{per}(nonZeroRowsB,:) = NaN;
            nonZeroRowsC = all(CdataPeaks{tType}{per} == 0,2);
            CdataPeaks{tType}{per}(nonZeroRowsC,:) = NaN;
            nonZeroRowsV = all(VdataPeaks{tType}{per} == 0,2);
            VdataPeaks{tType}{per}(nonZeroRowsV,:) = NaN;
        end 
    end 
end 

%% average data
%resort the data for averaging 
for tType = 1:length(BdataPeaks)
    counter3 = 1; 
    if isempty(BdataPeaks{tType}) == 0 
        for per = 1:length(BdataPeaks{tType})
            if isempty(BdataPeaks{tType}{per}) == 0
                if counter3 == 1 
                    RBdataPeaks{tType}(counter3:size(BdataPeaks{tType}{per},1),:) = BdataPeaks{tType}{per};
                    RCdataPeaks{tType}(counter3:size(CdataPeaks{tType}{per},1),:) = CdataPeaks{tType}{per};
                    RVdataPeaks{tType}(counter3:size(VdataPeaks{tType}{per},1),:) = VdataPeaks{tType}{per};
                elseif counter3 > 1
                    RBdataPeaks{tType}(counter3:counter3+size(BdataPeaks{tType}{per},1)-1,:) = BdataPeaks{tType}{per};
                    RCdataPeaks{tType}(counter3:counter3+size(CdataPeaks{tType}{per},1)-1,:) = CdataPeaks{tType}{per};
                    RVdataPeaks{tType}(counter3:counter3+size(VdataPeaks{tType}{per},1)-1,:) = VdataPeaks{tType}{per};
                end
            end 
            counter3 = counter3 + length(BdataPeaks{tType}{per})-1;
        end 
    end 
end 

for tType = 1:length(BdataPeaks)
    if isempty(BdataPeaks{tType}) == 0 
        %replace rows of all 0s w/NaNs
        nonZeroRowsRB = all(RBdataPeaks{tType} == 0,2);
        RBdataPeaks{tType}(nonZeroRowsRB,:) = NaN;
        nonZeroRowsRC = all(RCdataPeaks{tType} == 0,2);
        RCdataPeaks{tType}(nonZeroRowsRC,:) = NaN;
        nonZeroRowsRV = all(RVdataPeaks{tType} == 0,2);
        RVdataPeaks{tType}(nonZeroRowsRV,:) = NaN;
    end 
end 

%get number of non NaN rows to get peak number 

for tType = 1:length(RBdataPeaks)
    if isempty(RBdataPeaks{tType}) == 0 
        nonNanRowsPerColumn(tType,:) = sum(~isnan(RBdataPeaks{tType}),1);
        peakNums(tType) = nonNanRowsPerColumn(tType,1);
    end 
end 


%put all blue and red stim trials together 
% RBdataPeaks2{1} = vertcat(RBdataPeaks{1},RBdataPeaks{2});
% RBdataPeaks2{2} = vertcat(RBdataPeaks{3},RBdataPeaks{4});
% RBdataPeaks2{3} = RBdataPeaks{5};
% 
% RCdataPeaks2{1} = vertcat(RCdataPeaks{1},RCdataPeaks{2});
% RCdataPeaks2{2} = vertcat(RCdataPeaks{3},RCdataPeaks{4});
% RCdataPeaks2{3} = RCdataPeaks{5};
% 
% RVdataPeaks2{1} = vertcat(RVdataPeaks{1},RVdataPeaks{2});
% RVdataPeaks2{2} = vertcat(RVdataPeaks{3},RVdataPeaks{4});
% RVdataPeaks2{3} = RVdataPeaks{5};

%average 
for tType = 1:length(RBdataPeaks)
    if isempty(RBdataPeaks{tType}) == 0 
        avB(tType,:) = nanmean(RBdataPeaks{tType},1);
        avC(tType,:) = nanmean(RCdataPeaks{tType},1);
        avV(tType,:) = nanmean(RVdataPeaks{tType},1);
        semB(tType,:) = ((nanstd(RBdataPeaks{tType},1)))/(sqrt(size(RBdataPeaks{tType},1)));
        semC(tType,:) = ((nanstd(RCdataPeaks{tType},1)))/(sqrt(size(RCdataPeaks{tType},1)));
        semV(tType,:) = ((nanstd(RVdataPeaks{tType},1)))/(sqrt(size(RVdataPeaks{tType},1)));
    end 
end 


%replace rows of all 0s w/NaNs
nonZeroRowsAvB = all(avB == 0,2);
avB(nonZeroRowsAvB,:) = NaN;
nonZeroRowsAvC = all(avC == 0,2);
avC(nonZeroRowsAvC,:) = NaN;
nonZeroRowsAvV = all(avV == 0,2);
avV(nonZeroRowsAvV,:) = NaN;

%% determine ratio of peaks to number of secodns per blue light, red light, and ISI period 
peak2timeRatio = peakNums./numSeconds; 

p2tAvB = zeros(size(avB,1),size(avB,2));
p2tAvC = zeros(size(avB,1),size(avB,2));
p2tAvV = zeros(size(avB,1),size(avB,2));
p2tSemB = zeros(size(avB,1),size(avB,2));
p2tSemC = zeros(size(avB,1),size(avB,2));
p2tSemV = zeros(size(avB,1),size(avB,2));
for tType = 1:size(avB,1)
    p2tAvB(tType,:) = avB(tType,:)*peak2timeRatio(tType);
    p2tAvC(tType,:) = avC(tType,:)*peak2timeRatio(tType);
    p2tAvV(tType,:) = avV(tType,:)*peak2timeRatio(tType);
    
    p2tSemB(tType,:) = semB(tType,:)*peak2timeRatio(tType);
    p2tSemC(tType,:) = semC(tType,:)*peak2timeRatio(tType);
    p2tSemV(tType,:) = semV(tType,:)*peak2timeRatio(tType);
end 



%% plot 
figure;
for tType = 1:length(RBdataPeaks)
    if isempty(BdataPeaks{tType}) == 0 
        subplot(2,3,tType)
        hold all
        ax=gca;
        Frames = size(avC,2);
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        acc = 0.25;
    %     sec_TimeVals = ((Frames_pre_stim_start:FPSstack/10:Frames_post_stim_start)/FPSstack)-0;
        sec_TimeVals = round((Frames_pre_stim_start:FPSstack/4:Frames_post_stim_start)/FPSstack,1);

        FrameVals = floor((1:FPSstack/4:Frames+1)); 
        % for row = 1:5
        %     plot(sortedBdata(row,:),'r','LineWidth',2)
        %     plot(sortedCdata(row,:),'b','LineWidth',2)
        % end 
        plot(p2tAvB(tType,:),'r','LineWidth',2);
        plot(p2tAvC(tType,:),'b','LineWidth',2);
        plot(p2tAvV(tType,:),'k','LineWidth',2);
        varargout = boundedline(1:size(p2tAvB,2),p2tAvB(tType,:),p2tSemB(tType,:),'r','transparency', 0.3,'alpha');                                                                             
        varargout = boundedline(1:size(p2tAvC,2),p2tAvC(tType,:),p2tSemC(tType,:),'b','transparency', 0.3,'alpha'); 
        varargout = boundedline(1:size(p2tAvV,2),p2tAvV(tType,:),p2tSemV(tType,:),'k','transparency', 0.3,'alpha'); 
        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;
        ax.FontSize = 20;
        xlim([0 length(avC)])
        ylim([-1 1])
    %     legend('BBB data','DA calcium','Vessel width')
        if tType == 1 
            title({sprintf('%.3f calcium peaks per second.',peak2timeRatio(tType));'2 sec blue stim'})
        elseif tType == 2 
            title({sprintf('%.3f calcium peaks per second.',peak2timeRatio(tType));'20 sec blue stim'})
        elseif tType == 3 
            title({sprintf('%.3f calcium peaks per second.',peak2timeRatio(tType));'2 sec red stim'})
        elseif tType == 4 
            title({sprintf('%.3f calcium peaks per second.',peak2timeRatio(tType));'20 sec red stim'})
        elseif tType == 5 
            title({sprintf('%.3f calcium peaks per second.',peak2timeRatio(tType));'baseline/ISI'})
        end 
    end
end 
%%
clearvars BdataPeaks CdataPeaks VdataPeaks RBdataPeaks RCdataPeaks RVdataPeaks avB avC avV semB semC semV peakNums nonNanRowsPerColumn p2tAvB p2tAvC p2tAvV p2tSemB p2tSemC p2tSemV