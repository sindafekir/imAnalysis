%% set paramaters
% vidList = [7]; %SF56

vidNumQ = input('Input 0 if this is the first video. Input 1 otherwise. ');
chColor = input('Input 0 for green channel. Input 1 for red channel. '); 

%% get the data you need 

% get registered images 
regImDir = uigetdir('*.*','WHERE ARE THE REGISTERED IMAGES?');
cd(regImDir);
regMatFileName = uigetfile('*.*','GET THE REGISTERED IMAGES');
regMat = matfile(regMatFileName);
regStacks = regMat.regStacks;

if chColor == 0 % green channel 
    data = regStacks{2,3};
elseif chColor == 1 % red channel 
    data = regStacks{2,4};
end 

% if this is not the first video of the data set 
if vidNumQ == 0
    numZplanes = input('How many Z planes are there? ');
    framePeriod = input("What is the framePeriod? ");
    FPS = 1/framePeriod; 
    FPSstack = FPS/3;
elseif vidNumQ == 1 
    % get the background subtraction ROI coordinates 
    BGROIDir = uigetdir('*.*','WHERE ARE THE ROI COORDINATES?');    
    cd(BGROIDir);   
    BGROIMatFileName = uigetfile('*.*','GET THE ROI COORDINATES');    
    BGROIeMat = matfile(BGROIMatFileName);    
    BG_ROIboundData = BGROIeMat.BG_ROIboundData;
    FPSstack = BGROIeMat.FPSstack;
    numZplanes = BGROIeMat.numZplanes;
    ROIboundDatas = BGROIeMat.ROIboundDatas;
    numROIs = BGROIeMat.numROIs;
    BBBROIsToSegment = BGROIeMat.BBBROIsToSegment;
end 

%% do background subtraction 
if vidNumQ == 0 
    [input_Stacks,BG_ROIboundData] = backgroundSubtraction(data);
elseif vidNumQ == 1   
    [input_Stacks] = backgroundSubtraction2(data,BG_ROIboundData);
end 

%% average registered imaging data across planes in Z 
clear inputStackArray
inputStackArray = zeros(size(regStacks{2,4}{1},1),size(regStacks{2,4}{1},2),size(regStacks{2,4}{1},3),size(regStacks{2,4},2));
for Z = 1:size(regStacks{2,4},2)
    inputStackArray(:,:,:,Z) = input_Stacks{Z};
end 
inputStacks = mean(inputStackArray,4);

%% get rid of frames/trials where registration gets wonky 
cutOffFrameQ = input('Does the registration ever get wonky? Yes = 1. No = 0. ');  
if cutOffFrameQ == 1 
    cutOffFrame = input('Beyond what frame is the registration wonky? ');  
    Ims = inputStacks(:,:,1:cutOffFrame);  
elseif cutOffFrameQ == 0 
    Ims = inputStacks;
end 
clear inputStacks
inputStacks = Ims; 

%% create non-vascular ROI- x-y plane 

if vidNumQ == 0 
    numROIs = input("How many BBB perm ROIs are we making? "); 
    %for display purposes mostly: average across frames 
    stackAVsIm = mean(inputStacks,3);
    %create the ROI boundaries           
    ROIboundDatas = cell(1,numROIs);
    for VROI = 1:numROIs 
        disp('Create your ROI for BBB perm analysis');
        [~,xmins,ymins,widths,heights] = firstTimeCreateROIs(1, stackAVsIm);
        ROIboundData{1} = xmins;
        ROIboundData{2} = ymins;
        ROIboundData{3} = widths;
        ROIboundData{4} = heights;
        ROIboundDatas{VROI} = ROIboundData;
    end
    ROIstacks = cell(1,numROIs);
    for VROI = 1:numROIs
        %use the ROI boundaries to generate ROIstacks 
        xmins = ROIboundDatas{VROI}{1};
        ymins = ROIboundDatas{VROI}{2};
        widths = ROIboundDatas{VROI}{3};
        heights = ROIboundDatas{VROI}{4};
        [ROI_stacks] = make_ROIs_notfirst_time(inputStacks,xmins,ymins,widths,heights);
        ROIstacks{VROI} = ROI_stacks{1};
    end 
elseif vidNumQ == 1 
    ROIstacks = cell(1,numROIs);
    for VROI = 1:numROIs
        %use the ROI boundaries to generate ROIstacks 
        xmins = ROIboundDatas{VROI}{1};
        ymins = ROIboundDatas{VROI}{2};
        widths = ROIboundDatas{VROI}{3};
        heights = ROIboundDatas{VROI}{4};
        [ROI_stacks] = make_ROIs_notfirst_time(inputStacks,xmins,ymins,widths,heights);
        ROIstacks{VROI} = ROI_stacks{1};
    end 
end 

%% segment the BBB ROIs - goal: identify non-vascular/non-terminal space 

if vidNumQ == 0 
    BBBROIsToSegment = input('What BBB ROIs have vessels in them? ');
end 
    
segQ = 1; 
while segQ == 1     
    %segment the vessel (small sample of the data) 
    VROI = input("What BBB ROI do you want to use to make segmentation algorithm? ");
    imageSegmenter(mean(ROIstacks{VROI},3))
    continu = input('Is the image segmenter closed? Yes = 1. No = 0. ');
    while continu == 1 
        BWstacks = cell(1,numROIs);
        BW_perim = cell(1,numROIs);
        segOverlays = cell(1,numROIs);         
        for VROI = 2%:length(BBBROIsToSegment)                    
            for frame = 1:size(ROIstacks{BBBROIsToSegment(VROI)},3)
                [BW,~] = segmentImageBBB(ROIstacks{BBBROIsToSegment(VROI)}(:,:,frame));
                BWstacks{BBBROIsToSegment(VROI)}(:,:,frame) = BW; 
                %get the segmentation boundaries 
                BW_perim{BBBROIsToSegment(VROI)}(:,:,frame) = bwperim(BW);
                %overlay segmentation boundaries on data
                segOverlays{BBBROIsToSegment(VROI)}(:,:,:,frame) = imoverlay(mat2gray(ROIstacks{BBBROIsToSegment(VROI)}(:,:,frame)), BW_perim{BBBROIsToSegment(VROI)}(:,:,frame), [.3 1 .3]);
            end               
        end      
        continu = 0;
    end 
    %check segmentation 
    if numROIs == 1 
        %play segmentation boundaries over images 
        implay(segOverlays{1})
    elseif numROIs > 1 
        VROI = input("What BBB ROI do you want to see? ");
        %play segmentation boundaries over images 
        implay(segOverlays{VROI})
    end 
    segQ = input('Does segmentation need to be redone? Yes = 1. No = 0. ');    
end 

%% invert the mask

BWstacksInv = cell(1,numROIs);
for VROI = 1:length(BBBROIsToSegment)                
    for frame = 1:size(ROIstacks{BBBROIsToSegment(VROI)},3)                            
        BWstacksInv{BBBROIsToSegment(VROI)}(:,:,frame) = ~(BWstacks{BBBROIsToSegment(VROI)}(:,:,frame)); 
    end         
end 

%% get pixel intensity value of extravascular space and within vessels 

meanPixIntArray = cell(1,numROIs); % pixel intensity outside of the vessel 
wVmeanPixIntArray = cell(1,numROIs); % pixel intensity within vessel 
for VROI = 1:numROIs           
    % if the BBB ROI has a vessel in it 
    if ismember(VROI,BBBROIsToSegment) == 1 
        for frame = 1:size(ROIstacks{VROI},3)                            
            stats = regionprops(BWstacksInv{VROI}(:,:,frame),ROIstacks{VROI}(:,:,frame),'MeanIntensity');       
            wVstats = regionprops(BWstacks{VROI}(:,:,frame),ROIstacks{VROI}(:,:,frame),'MeanIntensity');           
            ROIpixInts = zeros(1,length(stats));
            WvROIpixInts = zeros(1,length(stats));
            for stat = 1:length(stats)
                ROIpixInts(stat) = stats(stat).MeanIntensity;
            end 
            for stat = 1:length(wVstats)
                WvROIpixInts(stat) = wVstats(stat).MeanIntensity;
            end 
            meanPixIntArray{VROI}(frame) = mean(ROIpixInts);  
            wVmeanPixIntArray{VROI}(frame) = mean(WvROIpixInts);         
        end 
        % turn all rows full of zeros into NaNs 
        allZeroRows = find(all(meanPixIntArray{VROI} == 0,2));
        for row = 1:length(allZeroRows)
            meanPixIntArray{VROI} = NaN; 
        end    
        wVallZeroRows = find(all(wVmeanPixIntArray{VROI} == 0,2));
        for row = 1:length(wVallZeroRows)
            wVmeanPixIntArray{VROI} = NaN; 
        end 
    % if the BBB ROI does not have a vessel in it
    elseif ismember(VROI,BBBROIsToSegment) == 0       
        for frame = 1:size(ROIstacks{VROI},3)       
            meanPixIntArray{VROI}(frame) = mean(mean(ROIstacks{VROI}(:,:,frame)));         
        end 
        % turn all rows full of zeros into NaNs 
        allZeroRows = find(all(meanPixIntArray{VROI} == 0,2));
        for row = 1:length(allZeroRows)
            meanPixIntArray{VROI} = NaN; 
        end           
    end 
end 

           
%% subtract sliding baseline from raw traces  
       
% dataMeds = cell(1,numROIs);
% DFOF = cell(1,numROIs);
dataSlidingBLs = cell(1,numROIs);
wVdataSlidingBLs = cell(1,numROIs);
Data = cell(1,numROIs);
WvData = cell(1,numROIs);
% zData = cell(1,numROIs);
for VROI = 1:numROIs 
    % if the BBB ROI has a vessel in it 
    if ismember(VROI,BBBROIsToSegment) == 1 
        %get sliding baseline 
        [dataSlidingBL]=slidingBaseline(meanPixIntArray{VROI},floor((FPSstack)*10),0.5); %0.5 quantile thresh = the median value                 
        dataSlidingBLs{VROI} = dataSlidingBL;   
        [wVdataSlidingBL]=slidingBaseline(wVmeanPixIntArray{VROI},floor((FPSstack)*10),0.5); %0.5 quantile thresh = the median value                 
        wVdataSlidingBLs{VROI} = wVdataSlidingBL;    
        %subtract sliding baseline from F
        Data{VROI} = meanPixIntArray{VROI}-dataSlidingBLs{VROI}; 
        WvData{VROI} = wVmeanPixIntArray{VROI}-wVdataSlidingBLs{VROI}; 
    % if the BBB ROI does not have a vessel in it
    elseif ismember(VROI,BBBROIsToSegment) == 0         
        %get sliding baseline 
        [dataSlidingBL]=slidingBaseline(meanPixIntArray{VROI},floor((FPSstack)*10),0.5); %0.5 quantile thresh = the median value                 
        dataSlidingBLs{VROI} = dataSlidingBL;       
        %subtract sliding baseline from F
        Data{VROI} = meanPixIntArray{VROI}-dataSlidingBLs{VROI};        
    end 
end 

%% create cumulative pixel intensity traces 

cumData = cell(1,numROIs);
wVcumData = cell(1,numROIs);
for VROI = 1:numROIs
    % if the BBB ROI has a vessel in it 
    if ismember(VROI,BBBROIsToSegment) == 1 
        for frame = 1:size(Data{VROI},2)
            if frame == 1 
                cumData{VROI}(frame) = Data{VROI}(frame);
                wVcumData{VROI}(frame) = WvData{VROI}(frame);
            elseif frame > 1 && frame < size(Data{VROI},2)
                cumData{VROI}(frame) = Data{VROI}(frame)+cumData{VROI}(frame-1);
                wVcumData{VROI}(frame) = WvData{VROI}(frame)+wVcumData{VROI}(frame-1);
            end 
        end 
    % if the BBB ROI does not have a vessel in it
    elseif ismember(VROI,BBBROIsToSegment) == 0   
        for frame = 1:size(Data{VROI},2)
            if frame == 1 
                cumData{VROI}(frame) = Data{VROI}(frame);
            elseif frame > 1 && frame < size(Data{VROI},2)
                cumData{VROI}(frame) = Data{VROI}(frame)+cumData{VROI}(frame-1);
            end 
        end 
    end 
end 

%% plot cumulative pixel intensity plots for BBB ROIs that have vessels in them 

FPM = FPSstack*60;
for VROI = 1:size(cumData,2)   
    % if the BBB ROI has a vessel in it 
    if ismember(VROI,BBBROIsToSegment) == 1 
        figure;
        ax = gca;
        hold all; plot(cumData{VROI},'r','LineWidth',3);plot(wVcumData{VROI},'k','LineWidth',3)
        %set time in x axis 
        min_TimeVals = floor(0:5:(size(cumData{VROI},2)/FPM));
        FrameVals = floor(0:(size(cumData{VROI},2)/((size(cumData{VROI},2)/FPM)/5)):size(cumData{VROI},2));
        ax.XTick = FrameVals;
        ax.XTickLabel = min_TimeVals;
        ax.FontSize = 20;
        legend('Outside vessel','Inside vessel')
        xlabel('time (min)');
        ylabel('pixel intensity rate change')
        title(sprintf('BBB ROI %d',VROI));
    end 
end 

Bdata = Data;
