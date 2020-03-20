%% find peaks and then plot where they are in the entire TS 

[peaks, locs] = findpeaks(Cdata,'MinPeakProminence',0.08);

FPSstack = FPS;%/3; 
Frames = size(Cdata,2);
Frames_pre_stim_start = -((Frames-1)/2); 
Frames_post_stim_start = (Frames-1)/2; 
sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+10);
FrameVals = round((1:FPSstack*2:Frames)-1); 
ax=gca;
hold all
plot(Bdata,'r','LineWidth',3);plot(Cdata,'b','LineWidth',2)
for loc = 1:length(locs)
    plot([locs(loc) locs(loc)], [-5000 5000], 'k','LineWidth',2)
end 
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;
ax.FontSize = 20;
xlim([0 length(Cdata)])
ylim([-1 1])

%% sort data based on ca peak location 

windSize = input('How big should the window be around Ca peak in seconds?');
sortedBdata = zeros(1,round((windSize*FPS)+1));
sortedCdata = zeros(1,round((windSize*FPS)+1));
for peak = 1:length(locs)
    if locs(peak)-(windSize/2)*FPS > 0 && locs(peak)+(windSize/2)*FPS < length(Cdata)
        sortedBdata(peak,:) = Bdata(locs(peak)-(windSize/2)*FPS:locs(peak)+(windSize/2)*FPS);
        sortedCdata(peak,:) = Cdata(locs(peak)-(windSize/2)*FPS:locs(peak)+(windSize/2)*FPS);
    end 
end 

%replace rows of all 0s w/NaNs
nonZeroRowsB = all(sortedBdata == 0,2);
sortedBdata(nonZeroRowsB,:) = NaN;
nonZeroRowsC = all(sortedCdata == 0,2);
sortedCdata(nonZeroRowsC,:) = NaN;

%% average and plot 

avB = nanmean(sortedBdata,1);
avC = nanmean(sortedCdata,1);
% varB = nanvar(sortedBdata,1);
% varC = nanvar(sortedCdata,1);
semB = ((nanstd(sortedBdata,1)))/(sqrt(size(sortedBdata,1)));
semC = ((nanstd(sortedCdata,1)))/(sqrt(size(sortedCdata,1)));

Frames = size(avC,2);
Frames_pre_stim_start = -((Frames-1)/2); 
Frames_post_stim_start = (Frames-1)/2; 
% sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack:Frames_post_stim_start)/FPSstack));
% FrameVals = round((1:FPSstack:Frames)-5); 
ax=gca;
hold all
plot(avB,'r','LineWidth',3);plot(avC,'b','LineWidth',2)
varargout = boundedline(1:size(avB,2),avB,semB,'r','transparency', 0.3,'alpha');                                                                             
varargout = boundedline(1:size(avC,2),avC,semC,'b','transparency', 0.3,'alpha');                                                                             
plot([24 24], [-5000 5000], 'k','LineWidth',2)
ax.XTick = FrameVals;
ax.XTickLabel = sec_TimeVals;
ax.FontSize = 20;
xlim([0 length(avC)])
ylim([-1 1])
