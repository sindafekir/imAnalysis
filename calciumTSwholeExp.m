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
    CaROImaskDir = uigetdir('*.*','WHERE ARE THE CA ROI COORDINATES?');
    cd(CaROImaskDir);
    CaROImaskFileName = uigetfile('*.*','GET THE CA ROI COORDINATES'); 
    CaROImaskMat = matfile(CaROImaskFileName); 
    CaROImasks = CaROImaskMat.CaROImasks; 
    ROIorders = CaROImaskMat.ROIorders;
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
    CaROImasks = BGROIeMat.CaROImasks; 
    ROIorders = BGROIeMat.ROIorders;
end 

%% do background subtraction 
%select rows that do not have vessels or GCaMP in them 
if vidNumQ == 0 
    [input_Stacks,BG_ROIboundData] = backgroundSubtractionPerRow(data);
elseif vidNumQ == 1   
    [input_Stacks] = backgroundSubtractionPerRow2(data,BG_ROIboundData);
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
%% apply CaROImask and process data 

%determine the indices left for the edited CaROImasks or else
%there will be indexing problems below through iteration 
ROIinds = unique([CaROImasks{:}]);
%remove zero
ROIinds(ROIinds==0) = [];
%find max number of cells/terminals 
maxCells = length(ROIinds);

meanPixIntArray = cell(1,ROIinds(maxCells));
for ccell = 1:maxCells %cell starts at 2 because that's where our cell identity labels begins (see identifyROIsAcrossZ function)
    %find the number of z planes a cell/terminal appears in 
    %this figures out what planes in Z each cell occurs in (cellZ)
    for Z = 1:length(CaROImasks)                
        if ismember(ROIinds(ccell),CaROImasks{Z}) == 1 
            cellInd = max(unique(ROIorders{Z}(CaROImasks{Z} == ROIinds(ccell))));
            for frame = 1:length(Ims{Z})
                stats = regionprops(ROIorders{Z},Ims{Z}(:,:,frame),'MeanIntensity');
                meanPixIntArray{ROIinds(ccell)}(Z,frame) = stats(cellInd).MeanIntensity;
            end 
        end 
    end 
    %turn all rows of zeros into NaNs
    allZeroRows = find(all(meanPixIntArray{ROIinds(ccell)} == 0,2));
    for row = 1:length(allZeroRows)
        meanPixIntArray{ROIinds(ccell)}(allZeroRows(row),:) = NaN; 
    end 
end 

dataSlidingBLs = cell(1,ROIinds(maxCells));
FsubSBLs = cell(1,ROIinds(maxCells));
 for ccell = 1:maxCells     
        for z = 1:size(meanPixIntArray{ROIinds(ccell)},1)     
            %get sliding baseline 
            [dataSlidingBL]=slidingBaseline(meanPixIntArray{ROIinds(ccell)}(z,:),floor((FPSstack/numZplanes)*10),0.5); %0.5 quantile thresh = the median value
            dataSlidingBLs{ROIinds(ccell)}(z,:) = dataSlidingBL;                       
            %subtract sliding baseline from F trace 
            FsubSBLs{ROIinds(ccell)}(z,:) = meanPixIntArray{ROIinds(ccell)}(z,:)-dataSlidingBLs{ROIinds(ccell)}(z,:);
        end
 end        

%% average across z 

CcellData = cell(1,length(meanPixIntArray));
 for ccell = 1:maxCells
       CcellData{ROIinds(ccell)} = nanmean(FsubSBLs{ROIinds(ccell)},1);
 end 






 
 
