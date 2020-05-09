function [sortedData,userInput,UIr,ROIboundDatas] = segmentVessels(reg_Stacks,volIm,UIr,userInput,state_start_f,FPS,indices,uniqueTrialData,uniqueTrialDataOcurr,numZplanes)
%% create vessel segmentation ROIs - rotate if needed 
[imAn1funcDir] = getUserInput(userInput,'imAnalysis1_functions Directory');
cd(imAn1funcDir); 
numROIs = input("How many ROIs are we making? "); userInput(UIr,1) = ("How many ROIs are we making?"); userInput(UIr,2) = (numROIs); UIr = UIr+1;

rotStackAngles = zeros(1,numROIs);
ROIboundDatas = cell(1,numROIs);
for VROI = 1:numROIs 
    %rotate all the planes in Z per vessel ROI 
    [rotStacks,rotateImAngle] = rotateStack(reg_Stacks);       
    rotStackAngles(VROI) = rotateImAngle;    

    %create your ROI and apply it to all planes in Z 
    disp('Create your ROI for vessel segmentation');

    for stack = 1:length(rotStacks)   
        if stack == 1
            [ROI_stacks,xmins,ymins,widths,heights] = firstTimeCreateROIs(1,rotStacks{stack});
            ROIboundData{1} = xmins;
            ROIboundData{2} = ymins;
            ROIboundData{3} = widths;
            ROIboundData{4} = heights;
            ROIstacks{stack}{VROI} = ROI_stacks;

        elseif stack > 1 
            xmins = ROIboundData{1};
            ymins = ROIboundData{2};
            widths = ROIboundData{3};
            heights = ROIboundData{4};
            [ROI_stacks] = make_ROIs_notfirst_time(rotStacks{stack},xmins,ymins,widths,heights);
            ROIstacks{stack}{VROI} = ROI_stacks;
        end 
    end 
    ROIboundDatas{VROI} = ROIboundData;
end 


rotStackAngles = string(rotStackAngles);
rotStackAnglesJoined = join(rotStackAngles);
userInput(UIr,1) = ("ROI Rotation Angles"); userInput(UIr,2) = (rotStackAnglesJoined); UIr = UIr+1;


%% segment the vessels, get vessel width, and check segmentation
segmentVessel = 1;
while segmentVessel == 1 
    %display last image of first ROI z stacks to pick the one that is most dim
    %for making segmentation algorithm 
    disp('Pick a Z-stack to use for segmentation algorithm based on these pics.'); 
    for Zstack = 1:length(rotStacks)
        figure;
        imshow(rotStacks{Zstack}(:,:,end),[0 1800])
    end
    dispIm = input('What Z-stack is most dim and should be used for segmentation algorithm? '); userInput(UIr,1) = ("What Z-stack is most dim and should be used for segmentation algorithm?"); userInput(UIr,2) = (dispIm); UIr = UIr+1;

    %segment the vessel (small sample of the data) 
    imageSegmenter(ROIstacks{dispIm}{1}{1}(:,:,end));
    continu = input('Is the image segmenter closed? Yes = 1. No = 0. ');
    while continu == 1 
        BWstacks = cell(1,length(rotStacks));
        BW_perim = cell(1,length(rotStacks));
        segOverlays = cell(1,length(rotStacks));
        for Zstack = 1:length(rotStacks)
            for VROI = 1:numROIs 
                for frame = 1:500
                    [BW,~] = segmentImage(ROIstacks{Zstack}{VROI}{1}(:,:,frame));
                    BWstacks{Zstack}{VROI}(:,:,frame) = BW; 
                    %BWstacks{Z}{trialType}{trial}{VROI}(:,:,frame) = BW;
                    %get the segmentation boundaries 
                    BW_perim{Zstack}{VROI}(:,:,frame) = bwperim(BW);
                    %overlay segmentation boundaries on data
                    segOverlays{Zstack}{VROI}(:,:,:,frame) = imoverlay(mat2gray(ROIstacks{Zstack}{VROI}{1}(:,:,frame)), BW_perim{Zstack}{VROI}(:,:,frame), [.3 1 .3]);   
                end 
            end 
        end 
        continu = 0;
    end 
    
    %check segmentation 
    if volIm == 1
         Z = input("What Z plane do you want to see? ");
    elseif volIm == 0 
        Z = 1; 
    end 
    VROI = input("What vessel ROI do you want to see? ");
    
    %play segmentation boundaries over images 
    implay(segOverlays{Z}{VROI})

    segmentVessel = input("Does the vessel need to be segmented again? Yes = 1. No = 0. ");
    if segmentVessel == 1
        clear BWthreshold BWopenRadius BW se boundaries
    end 
end

%segment the vessel (all the data) 
disp('Vessel Segmentation')
parfor Zstack = 1:length(rotStacks)
    for VROI = 1:numROIs 
        for frame = 1:size(ROIstacks{1}{1}{1},3)
            [BW,~] = segmentImage(ROIstacks{Zstack}{VROI}{1}(:,:,frame));
            BWstacks{Zstack}{VROI}(:,:,frame) = BW; 
        end 
    end 
end 

%get vessel width 
for Zstack = 1:length(BWstacks)
    for VROI = 1:numROIs
        [vesselDiam,bounds] = findVesWidth(BWstacks{Zstack}{VROI});
        boundaries{Zstack}{VROI} = bounds;
        vessel_diam{Zstack}{VROI} = vesselDiam;
    end 
end 

%remove outliers = max and min value 
maxVDval = zeros(length(BWstacks),numROIs);
minVDval = zeros(length(BWstacks),numROIs);
for Zstack = 1:length(BWstacks)
    for VROI = 1:numROIs
        maxVDval(Zstack,VROI) = max(vessel_diam{Zstack}{VROI});
        minVDval(Zstack,VROI) = min(vessel_diam{Zstack}{VROI});
    end 
end 

%interpolate (average) data at frames that are max or min 
parfor Zstack = 1:length(BWstacks)
    for VROI = 1:numROIs 
        for frame = 2:size(ROIstacks{1}{1}{1},3)-1 %to avoid edges since i'm interpolating 
            if vessel_diam{Zstack}{VROI}(:,frame) == maxVDval(Zstack,VROI) || vessel_diam{Zstack}{VROI}(:,frame) == minVDval(Zstack,VROI)
                vessel_diam2{Zstack}{VROI}(:,frame) = (vessel_diam{Zstack}{VROI}(:,frame-1) + vessel_diam{Zstack}{VROI}(:,frame+1)) / 2 ; 
            elseif vessel_diam{Zstack}{VROI}(:,frame) ~= maxVDval(Zstack,VROI) || vessel_diam{Zstack}{VROI}(:,frame) ~= minVDval(Zstack,VROI)
                vessel_diam2{Zstack}{VROI}(:,frame) = vessel_diam{Zstack}{VROI}(:,frame);
            end 
        end 
    end 
end 

dataMeds = cell(1,length(BWstacks));
DFOF = cell(1,length(BWstacks));
dataSlidingBLs = cell(1,length(BWstacks));
DFOFsubSBLs = cell(1,length(BWstacks));
zVData = cell(1,length(BWstacks));
for z = 1:length(BWstacks)
    for VROI = 1:numROIs   
        %get median value per trace
        dataMed = median(vessel_diam2{z}{VROI});     
        dataMeds{z}(VROI,:) = dataMed;        
        %compute DF/F using means  
        DFOF{z}(VROI,:) = (vessel_diam2{z}{VROI}-dataMeds{z}(VROI,:))./dataMeds{z}(VROI,:);              
        %get sliding baseline 
        [dataSlidingBL]=slidingBaseline(DFOF{z}(VROI,:),floor((FPS/numZplanes)*10),0.5); %0.5 quantile thresh = the median value                 
        dataSlidingBLs{z}(VROI,:) = dataSlidingBL;     
        %subtract sliding baseline from DF/F
        DFOFsubSBLs{z}(VROI,:) = DFOF{z}(VROI,:)-dataSlidingBLs{z}(VROI,:);        
        %z-score data 
        zVData{z}(VROI,:) = zscore(DFOFsubSBLs{z}(VROI,:));
    end
end


%% separate data by trial type 
disp('Organizing Data by Trial Type')

%separate the data 
sortedData = cell(1,length(BWstacks));
for Zstack = 1:length(BWstacks)
  for VROI = 1:numROIs
      [sorted_Data] = eventTriggeredAverages(zVData{Zstack}(VROI,:),state_start_f,FPS,indices,uniqueTrialData,uniqueTrialDataOcurr,userInput,numZplanes);
      sortedData{Zstack}{VROI} = sorted_Data;           
  end 
end 

end 
