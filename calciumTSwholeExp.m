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

% if this is the first video of the data set 
if vidNumQ == 0
    framePeriod = input("What is the framePeriod? ");
    FPS = 1/framePeriod; 
    volQ = input('Input 1 if this is volume imaging data. Input 0 for 2D data. ');
    if volQ == 1 
        numZplanes = input('How many Z planes are there? ');
    elseif volQ == 0
        downSampleQ = input('Input 1 if frame averaging (over time) was done. ');
        numZplanes = 1;
        if downSampleQ == 1
            numZplanes = input('By what factor was the imaging data down sampled? ');
        end 
    end 
    FPSstack = FPS/numZplanes;    
    
%     CaROImaskDir = uigetdir('*.*','WHERE ARE THE CA ROI COORDINATES?');
%     cd(CaROImaskDir);
%     CaROImaskFileName = uigetfile('*.*','GET THE CA ROI COORDINATES'); 
%     CaROImaskMat = matfile(CaROImaskFileName); 
%     CaROImasks = CaROImaskMat.CaROImasks; 
%     ROIorders = CaROImaskMat.ROIorders;
    
% if this is not the first video of the data set
elseif vidNumQ == 1 
    % get the background subtraction ROI coordinates 
    BGROIDir = uigetdir('*.*','WHERE IS THE .MAT FILE FOR THE PREVIOUS VIDEO?');    
    cd(BGROIDir);   
    BGROIMatFileName = uigetfile('*.*','GET PARAMATERS FROM PREVIOUS VIDEO .MAT FILE');    
    BGROIeMat = matfile(BGROIMatFileName);    
    BG_ROIboundData = BGROIeMat.BG_ROIboundData;
    FPSstack = BGROIeMat.FPSstack;
    numZplanes = BGROIeMat.numZplanes;    
    CaROImasks = BGROIeMat.CaROImasks; 
    ROIorders = BGROIeMat.ROIorders;
    BGsubQ = BGROIeMat.BGsubQ;
    BGsubTypeQ = BGROIeMat.BGsubTypeQ;
    volQ = BGROIeMat.volQ;
end 

if volQ == 1 
    if chColor == 0 % green channel 
        data = regStacks{2,3};
    elseif chColor == 1 % red channel 
        data = regStacks{2,4};
    end 
elseif volQ == 0 
    if chColor == 0 % green channel 
        data = regStacks{2,1};
    elseif chColor == 1 % red channel 
        data = regStacks{2,2};
    end 
end 

%% do background subtraction 

%select rows that do not have vessels or GCaMP in them 
if vidNumQ == 0 
    BGsubQ = input('Input 1 if you want to do background subtraction on your imported image stacks. Input 0 otherwise. ');
    if BGsubQ == 0 
        input_Stacks = data;
    elseif BGsubQ == 1
        BGsubTypeQ = input('Input 0 to do a simple background subtraction. Input 1 if you want to do row by row background subtraction. ');
        if BGsubTypeQ == 0 
            [input_Stacks,BG_ROIboundData] = backgroundSubtraction(data);
        elseif BGsubTypeQ == 1
            [input_Stacks,BG_ROIboundData] = backgroundSubtractionPerRow(data);
        end 
    end 
elseif vidNumQ == 1   
    if BGsubQ == 0 
        input_Stacks = data;
    elseif BGsubQ == 1
        if BGsubTypeQ == 0 
            [input_Stacks] = backgroundSubtraction2(data,BG_ROIboundData);
        elseif BGsubTypeQ == 1
            [input_Stacks] = backgroundSubtractionPerRow2(data,BG_ROIboundData);
        end 
    end  
end 

%% get rid of frames/trials where registration gets wonky 
cutOffFrameQ = input('Does the registration ever get wonky? Yes = 1. No = 0. '); 
if cutOffFrameQ == 1 
    cutOffFrame = input('Beyond what frame is the registration wonky? ');  
    Ims = cell(1,length(input_Stacks));
    for Z = 1:length(input_Stacks)
        Ims{Z} = input_Stacks{Z}(:,:,1:cutOffFrame);  
    end 
elseif cutOffFrameQ == 0 
    Ims = input_Stacks;
end 

clear inputStacks
%% create CaROImask 
if vidNumQ == 0
    if volQ == 1
        [imThresh,CaROImasks,ROIorders] = identifyROIsAcrossZ(Ims);
    elseif volQ == 0 
        [imThresh,CaROImasks,ROIorders] = identifyROIs(Ims);
    end 
    masksDoneQ = input('Do the calcium ROIs need to be hand edited? Yes = 1. No = 0.');
    if masksDoneQ == 1
        %return stops the script so you can edit the CaROI mask using the below
        %code: 
%         ROIorders{1}(ROIorders{1}==20)=0; ROIorders{1}(ROIorders{1}==21)=0; %ROIorders{1}(ROIorders{1}==19)=0; %CaROImasks{3}(CaROImasks{3}==8)=0;%CaROImasks{2}(CaROImasks{2}==10)=0;
%         figure;imagesc(ROIorders{1});grid on;%figure;imagesc(CaROImasks{2});grid on;figure;imagesc(CaROImasks{3});grid on    
        return
    end 
end 


%% apply CaROImask and process data 

%determine the indices left for the edited CaROImasks or else
%there will be indexing problems below through iteration 
ROIinds = unique([ROIorders{:}]);
%remove zero
ROIinds(ROIinds==0) = [];
meanPixIntArray = cell(1,length(CaROImasks));
%find the number of z planes a cell/terminal appears in 
%this figures out what planes in Z each cell occurs in (cellZ)
for Z = 1:length(CaROImasks)                
    for frame = 1:length(Ims{Z})
        stats = regionprops(ROIorders{Z},Ims{Z}(:,:,frame),'MeanIntensity');
        for ROIind = 1:length(ROIinds)
            meanPixIntArray{ROIinds(ROIind)}(Z,frame) = stats(ROIinds(ROIind)).MeanIntensity;
            %turn all rows of zeros into NaN    
            allZeroRows = find(all(meanPixIntArray{ROIinds(ROIind)} == 0,2));
            for row = 1:length(allZeroRows)
                meanPixIntArray{ROIinds(ROIind)}(allZeroRows(row),:) = NaN; 
            end 
        end         
    end 
end 

dataSlidingBLs = cell(1,length(ROIinds));
FsubSBLs = cell(1,length(ROIinds) );
 for ccell = 1:length(ROIinds)     
        for z = 1:size(meanPixIntArray{ROIinds(ccell)},1)     
            %get sliding baseline 
            [dataSlidingBL]=slidingBaseline(meanPixIntArray{ROIinds(ccell)}(z,:),floor((FPSstack/numZplanes)*10),0.5); %0.5 quantile thresh = the median value
            dataSlidingBLs{ROIinds(ccell)}(z,:) = dataSlidingBL;                       
            %subtract sliding baseline from F trace 
            FsubSBLs{ROIinds(ccell)}(z,:) = meanPixIntArray{ROIinds(ccell)}(z,:)-dataSlidingBLs{ROIinds(ccell)}(z,:);
        end
 end        

%% average across z 

CcellData = cell(1,length(ROIinds));
nonSLBLsubData = cell(1,length(ROIinds));
 for ccell = 1:length(ROIinds)
       CcellData{ROIinds(ccell)} = nanmean(FsubSBLs{ROIinds(ccell)},1);
       nonSLBLsubData{ROIinds(ccell)} = nanmean(meanPixIntArray{ROIinds(ccell)},1);
 end 

%% plot calcium traces per Ca ROI to get an idea for what Ca ROIs hit a noise floor 

 for ccell = 1:length(ROIinds)
     figure;
     plot(CcellData{ROIinds(ccell)})
%      plot(nonSLBLsubData{ROIinds(ccell)})
     title(sprintf('Ca ROI %d',ROIinds(ccell)))
 end 


 
 
