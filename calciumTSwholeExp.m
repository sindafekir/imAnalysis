% function [TSdataBBBperm] = calciumTSwholeExp(regStacks,userInput)
%% get just the data you need 
% temp = matfile('SF56_20190718_ROI2_1_regIms_green.mat');
% userInput = temp.userInput; 
% CaROImasks = temp.CaROImasks; 
% ROIorders = temp.ROIorders; 

inputStacks = regStacks{2,3};

%% get rid of frames/trials where registration gets wonky 
%EVENTUALLY MAKE THIS AUTOMATIC INSTEAD OF HAVING TO INPUT WHAT FRAME THE
%REGISTRATION GETS WONKY 
cutOffFrameQ = input('Does the registration ever get wonky? Yes = 1. No = 0. ');  userInput(UIr,1) = ("Does the registration ever get wonky? Yes = 1. No = 0."); userInput(UIr,2) = (cutOffFrameQ); UIr = UIr+1;
if cutOffFrameQ == 1 
    cutOffFrame = input('Beyond what frame is the registration wonky? ');  userInput(UIr,1) = ("Beyond what frame is the registration wonky?"); userInput(UIr,2) = (cutOffFrame); 
    Ims = cell(1,length(inputStacks));
    for Z = 1:length(inputStacks)
        Ims{Z} = inputStacks{Z}(:,:,1:cutOffFrame);  
    end 
elseif cutOffFrameQ == 0 
    Ims = inputStacks;
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

[FPS] = getUserInput(userInput,"FPS"); 
 dataMeds = cell(1,ROIinds(maxCells));
 DFOF = cell(1,ROIinds(maxCells));
 dataSlidingBLs = cell(1,ROIinds(maxCells));
 DFOFsubSBLs = cell(1,ROIinds(maxCells));
 zData = cell(1,length(ROIinds));
 count = 1;
 for ccell = 1:maxCells     
        for z = 1:size(meanPixIntArray{ROIinds(ccell)},1)     
            %get median value per trace
            dataMed = median(meanPixIntArray{ROIinds(ccell)}(z,:));     
            dataMeds{ROIinds(ccell)}(z,:) = dataMed;
            %compute DF/F using means  
            DFOF{ROIinds(ccell)}(z,:) = (meanPixIntArray{ROIinds(ccell)}(z,:)-dataMeds{ROIinds(ccell)}(z,:))./dataMeds{ROIinds(ccell)}(z,:);                         
            %get sliding baseline 
            [dataSlidingBL]=slidingBaseline(DFOF{ROIinds(ccell)}(z,:),floor((FPS/numZplanes)*10),0.5); %0.5 quantile thresh = the median value                 
            dataSlidingBLs{ROIinds(ccell)}(z,:) = dataSlidingBL;                       
            %subtract sliding baseline from DF/F
            DFOFsubSBLs{ROIinds(ccell)}(z,:) = DFOF{ROIinds(ccell)}(z,:)-dataSlidingBLs{ROIinds(ccell)}(z,:);
            %z-score data 
            zData{count}(z,:) = zscore(DFOFsubSBLs{ROIinds(ccell)}(z,:));
        end
        count = count + 1 ;
 end        

 % average across z and cells 
 zData2 = cell(1,length(zData));
 zData2array = zeros(length(zData),size(zData{1},2));
 for ccell = 1:length(zData)
     zData2{ccell} = nanmean(zData{ccell},1);
     zData2array(ccell,:) = zData2{ccell};
 end 
 Cdata = nanmean(zData2array,1);
 
 
 %% PLAYGROUND 
 
 plot(Cdata)
 
 clearvars -except Cdata
 
%  Cdata = Cdata(1:1716);
 
% inputStacks = (Ims{1} + Ims{2} + Ims{3})/3;

% inputStacks = Ims{1};

% end 