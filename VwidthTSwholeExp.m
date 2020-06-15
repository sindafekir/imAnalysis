%% set paramaters

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

% if this is the first video of the data set 
if vidNumQ == 0
    numZplanes = input('How many Z planes are there? ');
    framePeriod = input("What is the framePeriod? ");
    FPS = 1/framePeriod; 
    FPSstack = FPS/3;
% if this is not the first video of the data set
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
    rotStackAngles = BGROIeMat.rotStackAngles;
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


%% create vessel segmentation ROIs - rotate if needed 
if vidNumQ == 0 
    numROIs = input("How many ROIs are we making? ");
    rotStackAngles = zeros(1,numROIs);
    ROIboundDatas = cell(1,numROIs); 
    ROIstacks = cell(1,numROIs);
    for VROI = 1:numROIs 
        %rotate 
        [rotStack,rotateImAngle] = rotateStack(Ims);       
        rotStackAngles(VROI) = rotateImAngle;    
        %create your ROI boundaries 
        disp('Create your ROI for vessel segmentation');                 
        [~,xmins,ymins,widths,heights] = firstTimeCreateROIs(1,rotStack);
        ROIboundData{1} = xmins;
        ROIboundData{2} = ymins;
        ROIboundData{3} = widths;
        ROIboundData{4} = heights;
        ROIboundDatas{VROI} = ROIboundData;
        %use the ROI boundaries to generate ROIstacks 
        xmins = ROIboundDatas{VROI}{1};
        ymins = ROIboundDatas{VROI}{2};
        widths = ROIboundDatas{VROI}{3};
        heights = ROIboundDatas{VROI}{4};
        [ROI_stacks] = make_ROIs_notfirst_time(rotStack,xmins,ymins,widths,heights);
        ROIstacks{VROI} = ROI_stacks{1};
    end         
elseif vidNumQ == 1 
    ROIstacks = cell(1,numROIs);
    for VROI = 1:numROIs
        %rotate
        [rotStack] = rotateStack2(Ims,rotStackAngles(VROI)); 
        %use the ROI boundaries to generate ROIstacks 
        xmins = ROIboundDatas{VROI}{1};
        ymins = ROIboundDatas{VROI}{2};
        widths = ROIboundDatas{VROI}{3};
        heights = ROIboundDatas{VROI}{4};
        [ROI_stacks] = make_ROIs_notfirst_time(rotStack,xmins,ymins,widths,heights);
        ROIstacks{VROI} = ROI_stacks{1};
    end 
end 

%% segment the vessels, get vessel width, and check segmentation
segmentVessel = 1;
while segmentVessel == 1 

    %segment the vessel (small sample of the data) 
    VROI = input("What vessel width ROI do you want to use to make segmentation algorithm? ");
    imageSegmenter(mean(ROIstacks{VROI},3))
    continu = input('Is the image segmenter closed? Yes = 1. No = 0. ');
    while continu == 1 
        BWstacks = cell(1,numROIs);
        BW_perim = cell(1,numROIs);
        segOverlays = cell(1,length(rotStack));        
        for VROI = 1:numROIs 
            for frame = 1:500
                [BW,~] = segmentImage(ROIstacks{VROI}(:,:,frame));
                BWstacks{VROI}(:,:,frame) = BW; 
                %get the segmentation boundaries 
                BW_perim{VROI}(:,:,frame) = bwperim(BW);
                %overlay segmentation boundaries on data
                segOverlays{VROI}(:,:,:,frame) = imoverlay(mat2gray(ROIstacks{VROI}(:,:,frame)), BW_perim{VROI}(:,:,frame), [.3 1 .3]);   
            end 
        end        
        continu = 0;
    end 
    
    %check segmentation 
    if numROIs == 1 
        VROI = 1;
        %play segmentation boundaries over images 
        implay(segOverlays{VROI})
    elseif numROIs > 1
        VROI = input("What vessel ROI do you want to see? ");
        %play segmentation boundaries over images 
        implay(segOverlays{VROI})
    end 


    segmentVessel = input("Does the vessel need to be segmented again? Yes = 1. No = 0. ");
    if segmentVessel == 1
        clear BWthreshold BWopenRadius BW se boundaries
    end 
end

%%
%segment the vessel (all the data) 
disp('Vessel Segmentation')
for VROI = 1:numROIs 
    for frame = 1:size(ROIstacks{VROI},3)
        [BW,~] = segmentImage(ROIstacks{VROI}(:,:,frame));
        BWstacks{VROI}(:,:,frame) = BW; 
    end 
end 

boundaries = cell(1,numROIs);
vessel_diam = cell(1,numROIs);
%get vessel width 
for VROI = 1:numROIs
    [vesselDiam,bounds] = findVesWidth(BWstacks{VROI});
    boundaries{VROI} = bounds;
    vessel_diam{VROI} = vesselDiam;
end 

%remove outliers = max and min value 
maxVDval = zeros(1,numROIs);
minVDval = zeros(1,numROIs);
for VROI = 1:numROIs
    maxVDval(VROI) = max(vessel_diam{VROI});
    minVDval(VROI) = min(vessel_diam{VROI});
end 

%% interpolate (average) data at frames that are max or min 
vessel_diam2 = cell(1,numROIs);
for VROI = 1:numROIs 
    for frame = 2:size(ROIstacks{VROI},3) %to avoid edges since i'm interpolating 
        if vessel_diam{VROI}(:,frame) == maxVDval(VROI) || vessel_diam{VROI}(:,frame) == minVDval(VROI) && frame ~= size(ROIstacks{VROI},3)
            vessel_diam2{VROI}(:,frame) = (vessel_diam{VROI}(:,frame-1) + vessel_diam{VROI}(:,frame+1)) / 2 ; 
        elseif vessel_diam{VROI}(:,frame) ~= maxVDval(VROI) || vessel_diam{VROI}(:,frame) ~= minVDval(VROI) 
            vessel_diam2{VROI}(:,frame) = vessel_diam{VROI}(:,frame);
        end 
        if frame == size(ROIstacks{VROI},3)
            if vessel_diam{VROI}(:,frame) == maxVDval(VROI) || vessel_diam{VROI}(:,frame) == minVDval(VROI) 
                vessel_diam2{VROI}(:,frame) = vessel_diam{VROI}(:,frame-1); 
            elseif vessel_diam{VROI}(:,frame) ~= maxVDval(VROI) || vessel_diam{VROI}(:,frame) ~= minVDval(VROI) 
                vessel_diam2{VROI}(:,frame) = vessel_diam{VROI}(:,frame);
            end 
        end 
    end 
end 


%% subtract sliding baseline from raw traces 

dataSlidingBLs = cell(1,numROIs);
Data = cell(1,length(BWstacks));
for VROI = 1:numROIs              
    %get sliding baseline 
    [dataSlidingBL]=slidingBaseline(vessel_diam2{VROI},floor((FPSstack)*10),0.5); %0.5 quantile thresh = the median value                 
    dataSlidingBLs{VROI} = dataSlidingBL;     
    %subtract sliding baseline from F
    Data{VROI} = vessel_diam2{VROI}-dataSlidingBLs{VROI};        
end

Vdata = Data;


