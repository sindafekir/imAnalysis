
%{

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


%% make cumulative pixel intensity images 

% cumIms = cell(1,numROIs);
cumFull = zeros(size(inputStacks,1),size(inputStacks,2),size(inputStacks,3));
% for VROI = 1:numROIs
    for frame = 1:size(Data{VROI},2)
        if frame == 1
%             cumIms{VROI}(:,:,frame) = ROIstacks{VROI}(:,:,frame); 
            cumFull(:,:,frame) = inputStacks(:,:,frame); 
            
        elseif frame > 1 && frame < size(Data{VROI},2)    
%             cumIms{VROI}(:,:,frame) = ROIstacks{VROI}(:,:,frame)+cumIms{VROI}(:,:,frame-1);
            cumFull(:,:,frame) = inputStacks(:,:,frame)+cumFull(:,:,frame-1); 
        end 
    end 
% end 



%%
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%THE BELOW CODE IS FOR AVERAGING ACROSS MICE 

%% import just the data you need 
temp = matfile('63-64-WT6_70FITC_BBB_wholeExp');
cumData_WT6_ROI4 = temp.cumData;
wVcumData_WT6_ROI4 = temp.wVcumData;
FPS_WT6_ROI4 = temp.FPS;

%% put data into same cell array for simplicity 
%cumData{mouse}{ROI}
cumData{1}{1} = cumData_63_ROI1;
cumData{1}{2} = cumData_63_ROI2;
cumData{2}{1} = cumData_64_ROI1;
cumData{2}{2} = cumData_WT6_ROI3;
cumData{3}{1} = cumData_WT6_ROI4;

wVcumData{1}{1} = wVcumData_63_ROI1;
wVcumData{1}{2} = wVcumData_63_ROI2;
wVcumData{2}{1} = wVcumData_64_ROI1;
wVcumData{2}{2} = wVcumData_WT6_ROI3;
wVcumData{3}{1} = wVcumData_WT6_ROI4;

FPS{1}{1} = FPS_63_ROI1;
FPS{1}{2} = FPS_63_ROI2;
FPS{2}{1} = FPS_64_ROI1;
FPS{2}{2} = FPS_WT6_ROI3;
FPS{3}{1} = FPS_WT6_ROI4;


%% get just the first 25 mins of the data 

cumData45min = cell(1,length(cumData));
wVcumData45min = cell(1,length(cumData));
for mouse = 1:length(cumData)
    for ROI = 1:length(cumData{mouse})
        for FOV = 1: length(cumData{mouse}{ROI})
            cumData45min{mouse}{ROI}{FOV} = cumData{mouse}{ROI}{FOV}(1:FPS{mouse}{ROI}*(25*60));
            wVcumData45min{mouse}{ROI}{FOV}= wVcumData{mouse}{ROI}{FOV}(1:FPS{mouse}{ROI}*(25*60));
        end 
    end 
end 



%% average across FOV 

cumDataArray = cell(1,length(cumData));
wVcumDataArray = cell(1,length(cumData));
cumData45minAv1 = cell(1,length(cumData));
wVcumData45minAv1 = cell(1,length(cumData));
for mouse = 1:length(cumData)
    for ROI = 1:length(cumData{mouse})
        for FOV = 1: length(cumData{mouse}{ROI})
            cumDataArray{mouse}{ROI}(FOV,:) = cumData45min{mouse}{ROI}{FOV};
            wVcumDataArray{mouse}{ROI}(FOV,:)= wVcumData45min{mouse}{ROI}{FOV};
        end 
        cumData45minAv1{mouse}{ROI} = mean(cumDataArray{mouse}{ROI},1);
        wVcumData45minAv1{mouse}{ROI} = mean(wVcumDataArray{mouse}{ROI},1);
    end 
end 

%% resample and average across ROIs 

RcumData45minAv1 = cell(1,length(cumData));
RwVcumData45minAv1 = cell(1,length(cumData));
RcumData45minAv = cell(1,length(cumData));
RwVcumData45minAv = cell(1,length(cumData));
for mouse = 1:length(cumData)
    % figure out what value to upsample to (resLen) within mice 
    if length(cumData{mouse}) == 1 
        resLen = length(cumData45minAv1{mouse}{1});
    elseif length(cumData{mouse}) == 2 
        len1 = length(cumData45minAv1{mouse}{1});
        len2 = length(cumData45minAv1{mouse}{2});
        if len1>len2
            resLen = len1;
        elseif len2>len1
            resLen = len2;
        end 
    end 
   
    for ROI = 1:length(cumData{mouse})
        %upsample 
        RcumData45minAv1{mouse}(ROI,:) = resample(cumData45minAv1{mouse}{ROI},resLen,length(cumData45minAv1{mouse}{ROI}));
        RwVcumData45minAv1{mouse}(ROI,:) = resample(wVcumData45minAv1{mouse}{ROI},resLen,length(wVcumData45minAv1{mouse}{ROI}));
    end 
    
    %average 
    RcumData45minAv{mouse} = mean(RcumData45minAv1{mouse},1);
    RwVcumData45minAv{mouse} = mean(RwVcumData45minAv1{mouse},1) ;
   
end 

%% resample across mice 

%figure out what value to upsample to across mice (resLen2)
lens(1) = length(RcumData45minAv{1});
lens(2) = length(RcumData45minAv{2});
lens(3) = length(RcumData45minAv{3});
% lens(4) = length(RcumData45minAv{4});

resLen = max(lens);

for mouse = 1:length(cumData)
    %resample across mice 
    miceCumData(mouse,:) = resample(RcumData45minAv{mouse},resLen,length(RcumData45minAv{mouse}));
    miceCumWvData(mouse,:) = resample(RwVcumData45minAv{mouse},resLen,length(RwVcumData45minAv{mouse}));      
end 

%get average and var across mice 
AVmiceCumData = nanmean(miceCumData,1);
VARmiceCumData = (nanstd(miceCumData,1))/(sqrt(size(miceCumData,1)));
AVmiceCumWvData = nanmean(miceCumWvData,1);
VARmiceCumWvData = (nanstd(miceCumWvData,1))/(sqrt(size(miceCumWvData,1)));


%% plot 
FPS = size(AVmiceCumData,2)/(25*60);
FPM = FPS*60;

figure;
ax = gca;
hold all; 
plot(AVmiceCumData,'r','LineWidth',3);
plot(NC_AVmiceCumData,'k','LineWidth',3);
% plot(AVmiceCumWvData,'k','LineWidth',3);
varargout = boundedline(1:size(AVmiceCumData,2),AVmiceCumData,VARmiceCumData,'r','transparency', 0.1,'alpha');    
varargout = boundedline(1:size(NC_AVmiceCumData,2),NC_AVmiceCumData,NC_VARmiceCumData,'k','transparency', 0.1,'alpha'); 
% varargout = boundedline(1:size(AVmiceCumWvData,2),AVmiceCumWvData,VARmiceCumWvData,'k','transparency', 0.1,'alpha'); 
%set time in x axis 
min_TimeVals = ceil(0:5:(size(AVmiceCumData,2)/FPM));
FrameVals = ceil(0:(size(AVmiceCumData,2)/((size(AVmiceCumData,2)/FPM)/5)):size(AVmiceCumData,2));
ax.XTick = FrameVals;
ax.XTickLabel = min_TimeVals;
ax.FontSize = 20;
legend('Chrimson(+) mice','Chrimson(-) mice')
xlabel('time (min)');
ylabel('normalized pixel intensity')
title('Chrimson(-) mice')
ylim([-100 800])

figure; 
hold all; 
ax = gca;
for mouse = 1:size(miceCumData,1)
    plot(miceCumData(mouse,:),'r','LineWidth',3);
%     plot(miceCumWvData(mouse,:),'k','LineWidth',3);
end 
%set time in x axis 
% min_TimeVals = floor(0:5:(size(AVmiceCumData,2)/FPM));
FrameVals = floor(0:(size(AVmiceCumData,2)/((size(AVmiceCumData,2)/FPM)/5)):size(AVmiceCumData,2));
ax.XTick = FrameVals;
ax.XTickLabel = min_TimeVals;
ax.FontSize = 20;
% legend('Outside vessel','Inside vessel')
xlabel('time (min)');
ylabel('normalized pixel intensity')
title('Chrimson(+) mice')
ylim([-100 800])
xlim([0 17030])




 %}