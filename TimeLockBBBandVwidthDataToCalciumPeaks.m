% Bdata = (zData{1} + zData{2})/2;
% Bdata = zData{1};
Blength = length(Bdata);
Clength = length(Cdata);
Vlength = length(Vdata);

if Blength < Clength && Blength < Vlength
    Cdata = Cdata(1:length(Bdata));
    Vdata = Vdata(1:length(Bdata));
elseif Clength < Vlength && Clength < Blength
    Vdata = Vdata(1:length(Cdata));
    Bdata = Bdata(1:length(Cdata));    
elseif Vlength < Clength && Vlength < Blength
    Cdata = Cdata(1:length(Vdata));
    Bdata = Bdata(1:length(Vdata));
end 

%% smooth data 

smoothQ = 0; %input('Do you want to smooth your data? Yes = 1. No = 0. ');
if smoothQ ==  1
    filtTime = input('How many seconds do you want to smooth your data by? ');         
    [SBdata] = MovMeanSmoothData(Bdata,filtTime,FPS);
    [SCdata] = MovMeanSmoothData(Cdata,filtTime,FPS);
    [SVdata] = MovMeanSmoothData(Vdata,filtTime,FPS);
elseif smoothQ == 0
    SBdata = Bdata;
    SCdata = Cdata;
    SVdata = Vdata;
end

%% find peaks and then plot where they are in the entire TS 

[peaks, locs] = findpeaks(SCdata,'MinPeakProminence',1); %0.6,0.8,0.9,1
% 
% FPSstack = FPS;%/3; 
% Frames = size(Cdata,2);
% Frames_pre_stim_start = -((Frames-1)/2); 
% Frames_post_stim_start = (Frames-1)/2; 
% sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+10);
% FrameVals = round((1:FPSstack*2:Frames)-1); 
% ax=gca;
% hold all
% plot(Bdata,'r','LineWidth',3);
% plot(Cdata,'b','LineWidth',1)
% for loc = 1:length(locs)
%     plot([locs(loc) locs(loc)], [-5000 5000], 'k','LineWidth',2)
% end 
% ax.XTick = FrameVals;
% ax.XTickLabel = sec_TimeVals;
% ax.FontSize = 20;
% xlim([0 length(Cdata)])
% ylim([-1 1])

%% sort data based on ca peak location 

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
