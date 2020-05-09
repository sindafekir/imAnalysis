function [sortedData,userInput] = segmentVessels2(reg_Stacks,userInput,state_start_f,FPS,indices,uniqueTrialData,uniqueTrialDataOcurr,numZplanes,ROIboundData)
%% create vessel segmentation ROIs - rotate if needed 
[imAn2funcDir] = getUserInput(userInput,'imAnalysis2_functions Directory');
cd(imAn2funcDir);
[numROIs] = getUserInput(userInput,"How many ROIs are we making?");
[ROIrotAngles] = getUserInput(userInput,"ROI Rotation Angles");

if numROIs > 1 
    for VROI = 1:numROIs 
        %rotate all the planes in Z per vessel ROI 
        [rotStacks] = rotateStack2(reg_Stacks,ROIrotAngles(VROI)); 

        %create your ROI and apply it to all planes in Z 
        ROIstacks = cell(1,length(rotStacks));
        for stack = 1:length(rotStacks)   
                xmins = ROIboundData{VROI}{1};
                ymins = ROIboundData{VROI}{2};
                widths = ROIboundData{VROI}{3};
                heights = ROIboundData{VROI}{4};
                [ROI_stacks] = make_ROIs_notfirst_time(rotStacks{stack},xmins,ymins,widths,heights);
                ROIstacks{stack}{VROI} = ROI_stacks;     
        end 
    end 
elseif numROIs == 1 
    %rotate all the planes in Z per vessel ROI 
    [rotStacks] = rotateStack2(reg_Stacks,ROIrotAngles); 

    %create your ROI and apply it to all planes in Z 
    ROIstacks = cell(1,length(rotStacks));
    for stack = 1:length(rotStacks)   
            xmins = ROIboundData{1};
            ymins = ROIboundData{2};
            widths = ROIboundData{3};
            heights = ROIboundData{4};
            [ROI_stacks] = make_ROIs_notfirst_time(rotStacks{stack},xmins,ymins,widths,heights);
            ROIstacks{stack}{1} = ROI_stacks;     
    end 
end 

%% segment the vessels, get vessel width, and check segmentation

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

boundaries = cell(1,length(rotStacks));
vessel_diam = cell(1,length(rotStacks));
%get vessel width 
for Zstack = 1:length(BWstacks)
    for VROI = 1:numROIs
        [vesselDiam,bounds] = findVesWidth(BWstacks{Zstack}{VROI});
        boundaries{Zstack}{VROI} = bounds;
        vessel_diam{Zstack}{VROI} = vesselDiam;
    end 
end 

maxVDval = zeros(length(BWstacks),numROIs);
minVDval = zeros(length(BWstacks),numROIs);
%remove outliers = max and min value 
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
