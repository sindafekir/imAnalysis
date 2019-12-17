% make sure we know where the functions are 
imAnalysisDir = uigetdir('*.*','WHERE IS THE imAnalysis FOLDER? ');  
imAn1str = '\imAnalysis1_functions';
imAn2str = '\imAnalysis2_functions';
imAnDirs = [imAnalysisDir,imAn1str;imAnalysisDir,imAn2str];

%% register images
[regStacks,userInput,UIr,state_start_f,state_end_f,vel_wheel_data,TrialTypes,HDFchart] = imRegistration(imAnDirs);

%% set what data you want to plot 
dataParseType = input('What data do you need? Peristimulus epoch = 0. Stimulus epoch = 1. '); userInput(UIr,1) = ("What data do you need? Peristimulus epoch = 0. Stimulus epoch = 1."); userInput(UIr,2) = (dataParseType); UIr = UIr+1;    
if dataParseType == 0 
    sec_before_stim_start = input("How many seconds before the stimulus starts do you want to plot? "); userInput(UIr,1) = ("How many seconds before the stimulus starts do you want to plot?"); userInput(UIr,2) = (sec_before_stim_start); UIr = UIr+1;
    sec_after_stim_end = input("How many seconds after stimulus end do you want to plot? "); userInput(UIr,1) = ("How many seconds after stimulus end do you want to plot?"); userInput(UIr,2) = (sec_after_stim_end); UIr = UIr+1;
end 

%% set up analysis pipeline 
VsegQ = input('Do you need to measure vessel width? Yes = 1. No = 0. '); userInput(UIr,1) = ("Do you need to measure vessel width? Yes = 1. No = 0."); userInput(UIr,2) = (VsegQ); UIr = UIr+1;    
pixIntQ = input('Do you need to measure changes in pixel intensity? Yes = 1. No = 0. '); userInput(UIr,1) = ("Do you need to measure changes in pixel intensity? Yes = 1. No = 0."); userInput(UIr,2) = (pixIntQ); UIr = UIr+1; 
if pixIntQ == 1
    CaQ = input('Do you need to measure changes in calcium dynamics? Yes = 1. No = 0. '); userInput(UIr,1) = ("Do you need to measure changes in calcium dynamics? Yes = 1. No = 0."); userInput(UIr,2) = (CaQ); UIr = UIr+1; 
    BBBQ = input('Do you need to measure changes in BBB permeability? Yes = 1. No = 0. '); userInput(UIr,1) = ("Do you need to measure changes in BBB permeability? Yes = 1. No = 0."); userInput(UIr,2) = (BBBQ); UIr = UIr+1; 
end 
cumStacksQ = input('Do you want to generate cumulative pixel intensity stacks? Yes = 1. No = 0. '); userInput(UIr,1) = ("Do you want to generate cumulative pixel intensity stacks? Yes = 1. No = 0."); userInput(UIr,2) = (cumStacksQ); UIr = UIr+1; 

%% select registration method that's most appropriate for making the dff and cum pix int stacks 
[volIm] = getUserInput(userInput,'Is this volume imaging data? Yes = 1. Not = 0.');
if cumStacksQ == 1 || pixIntQ == 1 
    if volIm == 0
        regTypeDim = 0; userInput(UIr,1) = ("What registration dimension is best for pixel intensity analysis? 2D = 0. 3D = 1."); userInput(UIr,2) = (regTypeDim); UIr = UIr+1;
    elseif volIm == 1 
        regTypeDim = input("What registration dimension is best for pixel intensity analysis? 2D = 0. 3D = 1. "); userInput(UIr,1) = ("What registration dimension is best for pixel intensity analysis? 2D = 0. 3D = 1."); userInput(UIr,2) = (regTypeDim); UIr = UIr+1;
    end 
    regTypeTemp = input("What registration template is best for pixel intensity analysis? red = 0. green = 1. "); userInput(UIr,1) = ("What registration template is best for pixel intensity analysis? red = 0. green = 1."); userInput(UIr,2) = (regTypeTemp); UIr = UIr+1;

    [reg__Stacks] = pickRegStack(regStacks,regTypeDim,regTypeTemp);
    [reg_Stacks,BG_ROIboundData] = backgroundSubtraction(reg__Stacks);
end
%% select registration method that's most appropriate for vessel segmentation 
if VsegQ == 1
    if volIm == 0
        regTypeDimVesSeg = 0; userInput(UIr,1) = ("What registration dimension is best for vessel segmentation? 2D = 0. 3D = 1."); userInput(UIr,2) = (regTypeDimVesSeg); UIr = UIr+1;
    elseif volIm == 1 
        regTypeDimVesSeg = input("What registration dimension is best for vessel segmentation? 2D = 0. 3D = 1. "); userInput(UIr,1) = ("What registration dimension is best for vessel segmentation? 2D = 0. 3D = 1."); userInput(UIr,2) = (regTypeDimVesSeg); UIr = UIr+1;
    end 
    regTypeTempVesSeg = input("What registration template is best for vessel segmentation? red = 0. green = 1. "); userInput(UIr,1) = ("What registration template is best for vessel segmentation? red = 0. green = 1."); userInput(UIr,2) = (regTypeTempVesSeg); UIr = UIr+1;

    [reg__StacksVesSeg] = pickRegStack(regStacks,regTypeDimVesSeg,regTypeTempVesSeg);
    [reg_Stacks,BG_ROIboundData] = backgroundSubtraction(reg__StacksVesSeg);
end 

%% make cumulative, diff-cumulative, and DF/F stacks to output for calcium and BBB perm analysis 
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%EDIT-DO SLIDING BASELINE / Z-SCORING 
[FPS] = getUserInput(userInput,"FPS"); 
if cumStacksQ == 1  
    [dffDataFirst20s,CumDffDataFirst20s,CumData] = makeCumPixWholeEXPstacks(FPS,reg_Stacks);
end

%% make sure state start and end frames line up 
[numZplanes] = getUserInput(userInput,"How many Z planes are there?");
[state_start_f,state_end_f,TrialTypes] = makeSureStartEndTrialTypesLineUp(reg_Stacks,state_start_f,state_end_f,TrialTypes,numZplanes);

%% resample velocity data by trial type 
[ResampedVel_wheel_data] = resampleWheelData(reg_Stacks,vel_wheel_data);

%% get rid of frames/trials where registration gets wonky 
%EVENTUALLY MAKE THIS AUTOMATIC INSTEAD OF HAVING TO INPUT WHAT FRAME THE
%REGISTRATION GETS WONKY 
cutOffFrameQ = input('Does the registration ever get wonky? Yes = 1. No = 0. ');  userInput(UIr,1) = ("Does the registration ever get wonky? Yes = 1. No = 0."); userInput(UIr,2) = (cutOffFrameQ); UIr = UIr+1;
if cutOffFrameQ == 1 
    cutOffFrame = input('Beyond what frame is the registration wonky? ');  userInput(UIr,1) = ("Beyond what frame is the registration wonky?"); userInput(UIr,2) = (cutOffFrame); UIr = UIr+1;
    if cumStacksQ == 1 || pixIntQ == 1 
        reg___Stacks = reg_Stacks; clear reg_Stacks; 
        for zStack = 1:numZplanes
            reg_Stacks{zStack} = reg___Stacks{zStack}(:,:,1:cutOffFrame);
        end 
    end 
    
    if VsegQ == 1
        reg___StacksVesSeg = reg_Stacks; clear reg_Stacks; 
        for zStack = 1:numZplanes
            reg_Stacks{zStack} = reg___StacksVesSeg{zStack}(:,:,1:cutOffFrame);
        end 
    end 
    
    ResampedVel_wheel__data = ResampedVel_wheel_data; clear ResampedVel_wheel_data; 
    ResampedVel_wheel_data = ResampedVel_wheel__data(1:cutOffFrame);
end 


%% separate stacks by zPlane and trial type 
disp('Organizing Z-Stacks by Trial Type')
%find the diffent trial types 
[stimTimes] = getUserInput(userInput,"Stim Time Lengths (sec)"); 
[uniqueTrialData,uniqueTrialDataOcurr,indices,state_start_f] = separateTrialTypes(TrialTypes,state_start_f,state_end_f,stimTimes,numZplanes,FPS);
uniqueTrialDataTemplate = uniqueTrialData; 

if volIm == 1
    %separate the Z-stacks 
    for Zstack = 1:length(reg_Stacks)
          [sorted_Stacks,indices] = eventTriggeredAverages_STACKS(reg_Stacks{Zstack},state_start_f,FPS,indices,uniqueTrialData,uniqueTrialDataOcurr,userInput,numZplanes);
          sortedStacks{Zstack} = sorted_Stacks;           
    end 
elseif volIm == 0
    %separate the Z-stacks     
      [sorted_Stacks,indices] = eventTriggeredAverages_STACKS2(reg_Stacks{1},state_start_f,FPS,indices,uniqueTrialData,uniqueTrialDataOcurr,userInput,numZplanes);
      sortedStacks{1} = sorted_Stacks;           
end 

[sortedStacks,~] = removeEmptyCells(sortedStacks,indices);

%below removes indices in cells where sortedStacks is blank 
for trialType = 1:size(sortedStacks{1},2)
    if isempty(sortedStacks{1}{trialType}) == 1 
        indices{trialType} = [];         
    end 
end 

if cumStacksQ == 1  
    [dffStacks,CumDffStacks,CumStacks] = makeCumPixStacksPerTrial(sortedStacks);
end 

%% vessel segmentation 
if VsegQ == 1
        [sortedData,userInput,UIr,ROIboundData] = segmentVessels(reg_Stacks,volIm,UIr,userInput,state_start_f,FPS,indices,uniqueTrialData,uniqueTrialDataOcurr,numZplanes);
end 


%% measure changes in calcium dynamics and BBB permeability 
%EVENTUALLY ADD BBB STUFF IN 
if pixIntQ == 1
    if CaQ == 1    
        if volIm == 1
            [CaROImasks,userInput,ROIorders] = identifyROIsAcrossZ(reg_Stacks,userInput,UIr,numZplanes);
        elseif volIm == 0 
            [CaROImasks,userInput,ROIorders] = identifyROIs(reg_Stacks,userInput,UIr);
        end 
        
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%         %EDIT CALCIUM ROI MASKS BY HAND!!!!!
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%         CaROImasks{3}(CaROImasks{3}==15)=3;% CaROImasks{1}(CaROImasks{1}==1)=2; CaROImasks{1}(CaROImasks{1}==6)=0; CaROImasks{1}(CaROImasks{1}==4)=0;CaROImasks{1}(CaROImasks{1}==14)=0;
%         figure;imagesc(CaROImasks{3});grid on
        
        masksDoneQ = input('Have the calcium ROI masks been hand edited? Yes = 1. No = 0.');
        if masksDoneQ == 1 
            %determine the indices left for the edited CaROImasks or else
            %there will be indexing problems below through iteration 
            ROIinds = unique([CaROImasks{:}]);
            %remove zero
            ROIinds(ROIinds==0) = [];
            %find max number of cells/terminals 
            maxCells = length(ROIinds);
            %determine change in pixel intensity sorted by cell identity
            %across Z 
            for cell = 1:maxCells %cell starts at 2 because that's where our cell identity labels begins (see identifyROIsAcrossZ function)
                %find the number of z planes a cell/terminal appears in 
                count = 1;
                %this figures out what planes in Z each cell occurs in (cellZ)
                for Z = 1:length(CaROImasks)                
                    if ismember(ROIinds(cell),CaROImasks{Z}) == 1 
                        cellInd = max(unique(ROIorders{Z}(CaROImasks{Z} == ROIinds(cell))));
                        for frame = 1:length(reg_Stacks{Z})
                            stats = regionprops(ROIorders{Z},reg_Stacks{Z}(:,:,frame),'MeanIntensity');
                            meanPixIntArray{ROIinds(cell)}(Z,frame) = stats(cellInd).MeanIntensity;
                        end 
                    end 
                end 
                %turn all rows of zeros into NaNs
                allZeroRows = find(all(meanPixIntArray{ROIinds(cell)} == 0,2));
                for row = 1:length(allZeroRows)
                    meanPixIntArray{ROIinds(cell)}(allZeroRows(row),:) = NaN; 
                end 
            end 
            
             for cell = 1:maxCells     
                    for z = 1:size(meanPixIntArray{ROIinds(cell)},1)     
                        %get median value per trace
                        dataMed = nanmedian(meanPixIntArray{ROIinds(cell)}(z,:));     
                        dataMeds{ROIinds(cell)}(z,:) = dataMed;
                        %compute DF/F using means  
                        DFOF{ROIinds(cell)}(z,:) = (meanPixIntArray{ROIinds(cell)}(z,:)-dataMeds{ROIinds(cell)}(z,:))./dataMeds{ROIinds(cell)}(z,:);                         
                        %get sliding baseline 
                        [dataSlidingBL]=slidingBaseline(DFOF{ROIinds(cell)}(z,:),floor((FPS/numZplanes)*10),0.5); %0.5 quantile thresh = the median value                 
                        dataSlidingBLs{ROIinds(cell)}(z,:) = dataSlidingBL;                       
                        %subtract sliding baseline from DF/F
                        DFOFsubSBLs{ROIinds(cell)}(z,:) = DFOF{ROIinds(cell)}(z,:)-dataSlidingBLs{ROIinds(cell)}(z,:);
                        %z-score data 
                        zData{ROIinds(cell)}(z,:) = zscore(DFOFsubSBLs{ROIinds(cell)}(z,:));
                    end
             end

            %sort calcium data by trial type 
            for cell = 1:maxCells
                for Z = 1:size(zData{ROIinds(cell)},1)                
                    [sortedStatArray,indices] = eventTriggeredAverages(zData{ROIinds(cell)}(Z,:),state_start_f,FPS,indices,uniqueTrialData,uniqueTrialDataOcurr,userInput,numZplanes);            
                    sortedData{ROIinds(cell)}(Z,:) = sortedStatArray;
                end                  
            end            
        end 
    end 
    if BBBQ == 1
        %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        %PUT BBB SEGMENTATION CODE HERE 
        %MAKE THE OUTPUT HERE ALSO BE sortedData 
    end 
end

%% wheel data work goes here 
%get median wheel value 
WdataMed = median(ResampedVel_wheel_data);     
%compute Dv/v using means  
DVOV = (ResampedVel_wheel_data-WdataMed)./WdataMed;      
%get sliding baseline 
[WdataSlidingBL]=slidingBaseline(DVOV,floor((FPS/numZplanes)*10),0.5); %0.5 quantile thresh = the median value                                   
%subtract sliding baseline from Dv/v
DVOVsubSBLs = DVOV-WdataSlidingBL;
%z-score wheel data 
zWData = zscore(DVOVsubSBLs);
%sort wheel data                    
[sortedWheelData,~] = eventTriggeredAverages(zWData,state_start_f,FPS,indices,uniqueTrialData,uniqueTrialDataOcurr,userInput,numZplanes);

%% average dff, cum dff, and cum stacks across all trials
if cumStacksQ == 1 
    for Z = 1:numZplanes
        for trialType = 1:size(sortedData{ROIinds(cell)},2) 
            for trial = 1:length(sortedWheelData{trialType})
                CumDff_Stacks{Z}{trialType}(:,:,:,trial) = CumDffStacks{Z}{trialType}{trial};
                Cum_Stacks{Z}{trialType}(:,:,:,trial) = CumStacks{Z}{trialType}{trial};
                dff_Stacks{Z}{trialType}(:,:,:,trial) = dffStacks{Z}{trialType}{trial};
                sorted_Stacks{Z}{trialType}(:,:,:,trial) = sortedStacks{Z}{trialType}{trial};
            end 
            AVcumDffStacks{Z}{trialType} = mean(CumDff_Stacks{Z}{trialType},4);
            AVcumStacks{Z}{trialType} = mean(Cum_Stacks{Z}{trialType},4);
            AVdffStacks{Z}{trialType} = mean(dff_Stacks{Z}{trialType},4);
            AVStacks{Z}{trialType} = mean(sorted_Stacks{Z}{trialType},4);        
        end 
    end 
end 

if pixIntQ == 1        
    for cell = 1:maxCells       
        for z = 1:size(sortedData{ROIinds(cell)},1)
            for trialType = 1:size(sortedData{ROIinds(cell)},2) 
                for trial = 1:length(sortedData{ROIinds(cell)}{z,trialType})
                     sortedStats_Array{ROIinds(cell)}{z,trialType}(:,:,:,trial) = sortedData{ROIinds(cell)}{z,trialType}{trial};
                end 
                AVsortedData{ROIinds(cell)}{z,trialType}(1,:) = mean(sortedStats_Array{ROIinds(cell)}{z,trialType},4);
            end 
        end 
    end        
end 

if VsegQ == 1
    for z = 1:length(sortedData)
        for ROI = 1:size(sortedData{1},2)
            for trialType = 1:size(sortedData{1}{1},2)                  
                for trial = 1:length(sortedData{z}{ROI}{trialType})                    
                     sortedStats_Array{z}{ROI}{trialType}(:,:,:,trial) = sortedData{z}{ROI}{trialType}{trial};
                end 
                AVsortedData{z}{ROI}{trialType}(1,:) = mean(sortedStats_Array{z}{ROI}{trialType},4);
            end            
        end 
    end 
end 

for trialType = 1:size(sortedData{2},2)   
    for trial = 1:length(sortedWheelData{trialType})
        sortedWheel_Data{trialType}(:,:,:,trial) = sortedWheelData{trialType}{trial};
    end 
    AVwheelData{trialType}(1,:) = mean(sortedWheel_Data{trialType},4);     
end 

%% plot 

%resort the indices 
for trialType = 1:size(sortedData{2}{1},2) 
    [S, I] = sort(indices{trialType});
    indS{trialType} = S;
    indI{trialType} = I;
end 

if pixIntQ == 1    
    for cell = 1:maxCells  
        for z = 1:size(sortedData{ROIinds(cell)},1)
            for trialType = 1:size(sortedData{ROIinds(cell)},2) 
                dataToPlot{ROIinds(cell)}{z,trialType} = sortedData{ROIinds(cell)}{z,trialType}(indI{trialType}(1:length(sortedData{ROIinds(cell)}{z,trialType})));     
            end        
        end 
    end 
end 

if VsegQ == 1  
    for z = 1:length(sortedData)
        for ROI = 1:size(sortedData{1},2)             
            for trialType = 1:size(sortedData{1}{1},2)                          
                dataToPlot{z}{ROI}{trialType} = sortedData{z}{ROI}{trialType}(indI{trialType});     
            end        
        end 
    end 
    maxCells = size(sortedData{1},2);
end 

for trialType = 1:size(sortedData{2}{1},2) 
    wheelDataToPlot{trialType} = sortedWheelData{trialType}(indI{trialType});             
end 
   

%clearvars -except dataToPlot AVsortedData wheelDataToPlot AVwheelData userInput FPS dataMin dataMax velMin velMax HDFchart numZplanes BG_ROIboundData CaROImasks uniqueTrialDataTemplate maxCells ROIorders ROIinds ROIboundData sec_before_stim_start 

