%% get the data you need 
%ALL OF THE CODE BELOW HAS BEEN WRITTEN TO SORT, AVERAGE, AND PLOT CALCIUM
%PEAK ALIGNED DATA - DON'T NEED THIS YET...
%{
temp = matfile('SF56_20190718_ROI2_8_CVBdata_F-SB_terminalWOnoiseFloor_CaPeakAlignedData_2frameMinWidth.mat');
sortedCdata8 = temp.sortedCdata; 
sortedBdata8 = temp.sortedBdata;
sortedVdata8 = temp.sortedVdata; 

%% put all like data into the same cell array 

CdataArray(1,:) = sortedCdata1;
CdataArray(2,:) = sortedCdata2;
CdataArray(3,:) = sortedCdata3;
CdataArray(4,:) = sortedCdata4;
CdataArray(5,:) = sortedCdata5;
CdataArray(6,:) = sortedCdata7;
CdataArray(7,:) = sortedCdata8;

BdataArray(1,:) = sortedBdata1;
BdataArray(2,:) = sortedBdata2;
BdataArray(3,:) = sortedBdata3;
BdataArray(4,:) = sortedBdata4;
BdataArray(5,:) = sortedBdata5;
BdataArray(6,:) = sortedBdata7;
BdataArray(7,:) = sortedBdata8;

VdataArray(1,:) = sortedVdata1;
VdataArray(2,:) = sortedVdata2;
VdataArray(3,:) = sortedVdata3;
VdataArray(4,:) = sortedVdata4;
VdataArray(5,:) = sortedVdata5;
VdataArray(6,:) = sortedVdata7;
VdataArray(7,:) = sortedVdata8;

%% determine weights from number of peaks per video per terminal 

numPeaks = zeros(size(CdataArray,1),size(CdataArray,2));
totalPeaks = zeros(1,size(CdataArray,2));
weights = zeros(size(CdataArray,1),size(CdataArray,2));
for term = 1:size(CdataArray,2)
    for vid = 1:size(CdataArray,1)
        numPeaks(vid,term) = size(CdataArray{vid,term},1);
    end 
    totalPeaks(term) = sum(numPeaks(:,term));
    weights(:,term) = numPeaks(:,term)./totalPeaks(term);
end 


%% determine weighted average 

avCarray = cell(1,size(CdataArray,2));
avCterm = zeros(size(CdataArray,2),length(CdataArray{1}));
avBarray = cell(1,size(CdataArray,2));
avBterm = zeros(size(CdataArray,2),length(CdataArray{1}));
avVarray = cell(1,size(CdataArray,2));
avVterm = zeros(size(CdataArray,2),length(CdataArray{1}));
for term = 1:size(CdataArray,2)
    for vid = 1:size(CdataArray,1)
        if isempty(CdataArray{vid,term}) == 0 
            avCarray{term}(vid,:) = (nanmean(CdataArray{vid,term},1))*weights(vid,term);
            avBarray{term}(vid,:) = (nanmean(BdataArray{vid,term},1))*weights(vid,term);
            avVarray{term}(vid,:) = (nanmean(VdataArray{vid,term},1))*weights(vid,term);
        end 
    end
    avCterm(term,:) = sum(avCarray{term},1);
    avBterm(term,:) = sum(avBarray{term},1);
    avVterm(term,:) = sum(avVarray{term},1);
end 

avC = nanmean(avCterm,1);
avB = nanmean(avBterm,1);
avV = nanmean(avVterm,1);

%% normalize to baseline period and plot


%normalize to baseline period 
baselinePer = floor(length(avC)/3);
avC2 = ((avC-mean(avC(1:baselinePer)))/mean(avC(1:baselinePer)))*100;
avB2 = ((avB-mean(avB(1:baselinePer)))/mean(avB(1:baselinePer)))*100;
avV2 = ((avV-mean(avV(1:baselinePer)))/mean(avV(1:baselinePer)))*100;


avCterm2 = ((avCterm-mean(avCterm(:,1:baselinePer),2))./mean(avCterm(:,1:baselinePer),2))*100;
avBterm2 = ((avBterm-mean(avBterm(:,1:baselinePer),2))./mean(avBterm(:,1:baselinePer),2))*100;
avVterm2 = ((avVterm-mean(avVterm(:,1:baselinePer),2))./mean(avVterm(:,1:baselinePer),2))*100;

%%
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
plot(avB2,'r','LineWidth',2);
plot(avC2,'b','LineWidth',2);
% plot(avV2,'k','LineWidth',2);
% varargout = boundedline(1:size(avB2,2),avB2,semB2,'r','transparency', 0.3,'alpha');                                                                             
% varargout = boundedline(1:size(avC2,2),avC2,semC2,'b','transparency', 0.3,'alpha'); 
% varargout = boundedline(1:size(avV2,2),avV2,semV2,'k','transparency', 0.3,'alpha'); 
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;
ax.FontSize = 20;
xlim([0 length(avC)])
ylim([-200 200])
legend('BBB data','DA calcium','Vessel width')
% legend('BBB data','DA calcium')
xlabel('time (s)')
ylabel('percent change')
% title(sprintf('%d calcium peaks',length(peaks)))


%% plot terminal data 
terminals = [13, 20, 12, 16, 11, 15, 10, 8, 9, 7, 4];

for term = 1:size(CdataArray,2)
    
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
    plot(avBterm2(term,:),'r','LineWidth',2);
    plot(avCterm2(term,:),'b','LineWidth',2);
%     plot(avVterm2(term,:),'k','LineWidth',2);
    % varargout = boundedline(1:size(avB2,2),avB2,semB2,'r','transparency', 0.3,'alpha');                                                                             
    % varargout = boundedline(1:size(avC2,2),avC2,semC2,'b','transparency', 0.3,'alpha'); 
    % varargout = boundedline(1:size(avV2,2),avV2,semV2,'k','transparency', 0.3,'alpha'); 
    ax.XTick = FrameVals;
    ax.XTickLabel = sec_TimeVals;
    ax.FontSize = 20;
    xlim([0 length(avC)])
    ylim([-200 200])
    legend('BBB data','DA calcium','Vessel width')
    % legend('BBB data','DA calcium')
    xlabel('time (s)')
    ylabel('percent change')
    title(sprintf('Terminal %d',terminals(term))) 
   
end 
%}

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

%% get the data you need 
vidList = [1,2,3,4,5,7];
tData = cell(1,length(vidList));
for vid = 1:length(vidList)
    temp = matfile(sprintf('SF56_20190718_ROI2_%d_Fdata_termTtype.mat',vidList(vid)));
    tData{vid} = temp.GtTdataTerm; 
end 
FPSstack = temp.FPSstack;

%% reorganize data 
Data = cell(1,length(tData{1}{1}));
for term = 1:length(tData{1}{1})
    for tType = 1:length(tData{1})
        trial2 = 1; 
        for vid = 1:length(tData)            
            if isempty(tData{vid}{tType}) == 0 
                for trial = 1:size(tData{vid}{tType}{term},1)
                    Data{term}{tType}(trial2,:) = tData{vid}{tType}{term}(trial,:); 
                    trial2 = trial2 + 1;
                end 
            end             
        end 
    end 
end 

%% smooth data if you want
terminals = [13, 20, 12, 16, 11, 15, 10, 8, 9, 7, 4];
smoothQ =  input('Do you want to smooth your data? Yes = 1. No = 0. ');
if smoothQ ==  1
    filtTime = input('How many seconds do you want to smooth your data by? ');
    sData = cell(1,length(Data));
    for term = 1:length(Data)
        for tType = 1:length(Data{1})   
            for trial = 1:size(Data{term}{tType},1)
                [s_Data] = MovMeanSmoothData(Data{term}{tType}(trial,:),filtTime,FPSstack);
                sData{term}{tType}(trial,:) = s_Data; 
            end 
        end 
    end 
elseif smoothQ == 0
    sData = Data; 
end 

%% plot event triggered averages per terminal 
%{
for term = 1:length(Data)
    AVdata = cell(1,length(Data{1}));
    SEMdata = cell(1,length(Data{1}));
    baselineEndFrame = floor(20*(FPSstack));
    for tType = 1:length(Data{1})      
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
            for trial = 1:size(Data{term}{tType},1)
                plot(sData{term}{tType}(trial,:),'LineWidth',1)
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
%}

%% compare terminal calcium activity 

AVdata = cell(1,length(Data));
for term = 1:length(Data)
    for tType = 1:length(Data{1})      
        AVdata{term}{tType} = mean(sData{term}{tType},1);
    end 
end 

dataQ = input('Input 0 if you want to compare the entire TS. Input 1 if you want to compare stim period data. ');
if dataQ == 0 
    corData = cell(1,length(Data{1}));
    corAVdata = cell(1,length(Data{1}));
    for tType = 1:length(Data{1})    
       for term1 = 1:length(Data)
           for term2 = 1:length(Data)
               for trial = 1:size(Data{1}{tType},1)
                   corData{tType}{trial}(term1,term2) = corr2(sData{term1}{tType}(trial,:),sData{term2}{tType}(trial,:));                  
               end 
               corAVdata{tType}(term1,term2) = corr2(AVdata{term1}{tType},AVdata{term2}{tType});
           end 
       end 
    end 
elseif dataQ == 1 
    corData = cell(1,length(Data{1}));
    corAVdata = cell(1,length(Data{1}));
    for tType = 1:length(Data{1})    
       for term1 = 1:length(Data)
           for term2 = 1:length(Data)
               stimOnFrame = floor(FPSstack*20);
               if tType == 1 || tType == 3 
                   stimOffFrame = stimOnFrame + floor(FPSstack*20);
               elseif tType == 2 || tType == 4
                   stimOffFrame = stimOnFrame + floor(FPSstack*2);
               end 
               for trial = 1:size(Data{1}{tType},1)
                   corData{tType}{trial}(term1,term2) = corr2(sData{term1}{tType}(trial,stimOnFrame:stimOffFrame),sData{term2}{tType}(trial,stimOnFrame:stimOffFrame));
               end 
               corAVdata{tType}(term1,term2) = corr2(AVdata{term1}{tType}(stimOnFrame:stimOffFrame),AVdata{term2}{tType}(stimOnFrame:stimOffFrame));
           end 
       end 
    end 
end 

% plot cross correlelograms 
for tType = 1:length(Data{1})
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
   for trial = 1:size(Data{1}{tType},1)
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

%% CALCIUM PEAK RASTER PLOTS 
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Len1_3 = length(sData{1}{1});
Len2_4 = length(sData{1}{2});

% peaks = cell(1,length(Data));
locs = cell(1,length(Data));
stdTrace = cell(1,length(Data));
sigPeaks = cell(1,length(Data));
sigPeakLocs = cell(1,length(Data));
clear raster raster2 raster3 
for term = 1:length(Data)
%     figure;
    for tType = 1:length(Data{1})   
        for trial = 1:size(Data{term}{tType},1)
            %identify where the peaks are 
            [peak, loc] = findpeaks(sData{term}{tType}(trial,:),'MinPeakProminence',0.1,'MinPeakWidth',3); %0.6,0.8,0.9,1
            peaks{term}{tType}{trial} = peak;
            locs{term}{tType}{trial} = loc;
            stdTrace{term}(trial,tType) = std(sData{term}{tType}(trial,:));
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
    for tType = 1:length(peaks{1})   
        for trial = 1:size(peaks{term}{tType},1)
            if isempty(peaks{term}{tType}{trial}) == 0
                raster2{term}{tType} = ~raster2{term}{tType};
                %make raster plot larger/easier to look at 
                multFactor = 10;
                raster3{term}{tType} = repelem(raster2{term}{tType},multFactor,1);
                raster{term}{tType} = repelem(raster2{term}{tType},multFactor,1);
                %make rasters the correct length  
                if tType == 1 || tType == 3
                    raster{term}{tType}(:,length(raster3{term}{tType})+1:Len1_3) = 1;
                elseif tType == 2 || tType == 4   
                    raster{term}{tType}(:,length(raster3{term}{tType})+1:Len2_4) = 1;
                end 
        %         
        %         %create image 
        %         subplot(2,2,tType)
        %         imshow(raster{term}{tType})
        %         hold all 
        %         stimStartF = floor(FPSstack*20);
        %         if tType == 1 || tType == 3
        %             stimStopF = stimStartF + floor(FPSstack*2);           
        %             Frames = size(raster{term}{tType},2);        
        %             Frames_pre_stim_start = -((Frames-1)/2); 
        %             Frames_post_stim_start = (Frames-1)/2; 
        %             sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*4:Frames_post_stim_start)/FPSstack)+1);
        %             FrameVals = floor((1:FPSstack*4:Frames)-1);            
        %         elseif tType == 2 || tType == 4       
        %             stimStopF = stimStartF + floor(FPSstack*20);            
        %             Frames = size(raster{term}{tType},2);        
        %             Frames_pre_stim_start = -((Frames-1)/2); 
        %             Frames_post_stim_start = (Frames-1)/2; 
        %             sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*4:Frames_post_stim_start)/FPSstack)+10);
        %             FrameVals = floor((1:FPSstack*4:Frames)-1);
        %         end 
        %         if tType == 1 || tType == 2
        %         plot([stimStartF stimStartF], [0 size(raster{term}{tType},1)], 'b','LineWidth',2)
        %         plot([stimStopF stimStopF], [0 size(raster{term}{tType},1)], 'b','LineWidth',2)
        %         elseif tType == 3 || tType == 4
        %         plot([stimStartF stimStartF], [0 size(raster{term}{tType},1)], 'r','LineWidth',2)
        %         plot([stimStopF stimStopF], [0 size(raster{term}{tType},1)], 'r','LineWidth',2)
        %         end 
        % 
        %         ax=gca;
        %         axis on 
        %         xticks(FrameVals)
        %         ax.XTickLabel = sec_TimeVals;
        %         yticks(5:10:size(raster{term}{tType},1)-5)
        %         ax.YTickLabel = ([]);
        %         ax.FontSize = 15;
        %         xlabel('time (s)')
        %         ylabel('trial')
        %         sgtitle(sprintf('Terminal %d',terminals(term)))
            end 
        end 
    end 
end 

%%
 %create raster for all terminals stacked 
for tType = 1:length(Data{1})   
    for term = 1:length(Data)
        curSize = size(raster{term}{tType},1);
        if curSize < size(sData{term}{tType},1)*multFactor 
            raster{term}{tType}(curSize+1:size(sData{term}{tType},1)*multFactor,:) = 1;
        end    
    end 
end 

clear fullRaster
fullRaster = cell(1,length(Data{1}));
for tType = 1:length(Data{1})   
    rowLen = size(raster{term}{tType},1);
    for term = 1:length(Data)
        if term == 1
            fullRaster{tType} = raster{term}{tType};
        elseif term > 1
            fullRaster{tType}(((term-1)*rowLen)+1:term*rowLen,:) = raster{term}{tType};
        end 
    end 
    %create image 
    subplot(2,2,tType)
    imshow(fullRaster{tType})
    hold all 
    stimStartF = floor(FPSstack*20);
    if tType == 1 || tType == 3
        stimStopF = stimStartF + floor(FPSstack*2);           
        Frames = size(fullRaster{tType},2);        
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*4:Frames_post_stim_start)/FPSstack)+1);
        FrameVals = floor((1:FPSstack*4:Frames)-1);            
    elseif tType == 2 || tType == 4       
        stimStopF = stimStartF + floor(FPSstack*20);            
        Frames = size(fullRaster{tType},2);        
        Frames_pre_stim_start = -((Frames-1)/2); 
        Frames_post_stim_start = (Frames-1)/2; 
        sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*4:Frames_post_stim_start)/FPSstack)+10);
        FrameVals = floor((1:FPSstack*4:Frames)-1);
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
    ax.FontSize = 10;
    xlabel('time (s)')
    ylabel('trial')
%     sgtitle(sprintf('Terminal %d',terminals(term)))
end

%%
% plot peak rate per every n seconds 
winSec = input('How many seconds do you want to know the calcium peak rate? '); 
winFrames = floor(winSec*FPSstack);
numPeaks = cell(1,length(Data));
avTermNumPeaks = cell(1,length(Data));
for term = 1:length(Data)
%     figure
    for tType = 1:length(Data{1})
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

%plot num peaks for all terminals
allTermAvPeakNums = cell(1,length(Data{1}));
for term = 1:length(Data)
    for tType = 1:length(Data{1})
        colNum = floor(length(sData{term}{tType})/winFrames); 
        if length(avTermNumPeaks{term}{tType}) < colNum
            avTermNumPeaks{term}{tType}(length(avTermNumPeaks{term}{tType})+1:colNum) = 0;
        end 
        allTermAvPeakNums{tType}(term,:) = avTermNumPeaks{term}{tType};
    end 
end 

for tType = 1:length(Data{1})

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
    if tType == 1 || tType == 2
    plot([stimStartF stimStartF], [-20 20], 'b','LineWidth',2)
    plot([stimStopF stimStopF], [-20 20], 'b','LineWidth',2)
    elseif tType == 3 || tType == 4
    plot([stimStartF stimStartF], [-20 20], 'r','LineWidth',2)
    plot([stimStopF stimStopF], [-20 20], 'r','LineWidth',2)
    end 
    for term = 1:length(Data)
        plot(allTermAvPeakNums{tType}(term,:))
    end 
    plot(mean(allTermAvPeakNums{tType},1),'k','LineWidth',2)

    ax=gca;
    axis on 
    xticks(FrameVals)
    ax.XTickLabel = sec_TimeVals;
%         yticks(5:10:size(avTermNumPeaks{term}{tType},1)-5)
%         ax.YTickLabel = ([]);
    ax.FontSize = 10;
    xlabel('time (s)')
    ylabel('number of peaks')
    xlim([1 length(avTermNumPeaks{term}{tType})])
    ylim([-0.5 1])
    sgtitle('Number of calcium peaks per terminal');
end 

