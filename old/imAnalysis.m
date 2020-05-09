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
    %BBBQ is there in case I want to make ROIs for measuring change in
    %pixel intensity of the cumStacks - this code has not been added in yet
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
[numZplanes] = getUserInput(userInput,"How many Z planes are there?");
% [FPS] = getUserInput(userInput,"FPS"); 
% if cumStacksQ == 1  
%     [dffDataFirst20s,CumDffDataFirst20s,CumData] = makeCumPixWholeEXPstacks(FPS,reg_Stacks,numZplanes,sec_before_stim_start);
% end

%% make sure state start and end frames line up 
[state_start_f,state_end_f,TrialTypes] = makeSureStartEndTrialTypesLineUp(reg_Stacks,state_start_f,state_end_f,TrialTypes,numZplanes);

%% resample velocity data by trial type
if length(vel_wheel_data)*size(reg_Stacks{1},3) > 2^31
    ResampedVel_wheel_data1 = resample(vel_wheel_data,(round(length(vel_wheel_data)/8000)),length(vel_wheel_data));
    ResampedVel_wheel_data = resample(ResampedVel_wheel_data1,size(reg_Stacks{1},3),length(ResampedVel_wheel_data1));
elseif length(vel_wheel_data)*size(reg_Stacks{1},3) < 2^31
    ResampedVel_wheel_data = resample(vel_wheel_data,size(reg_Stacks{1},3),length(vel_wheel_data));
end 

%% get rid of frames/trials where registration gets wonky 
%EVENTUALLY MAKE THIS AUTOMATIC INSTEAD OF HAVING TO INPUT WHAT FRAME THE
%REGISTRATION GETS WONKY 
cutOffFrameQ = input('Does the registration ever get wonky? Yes = 1. No = 0. ');  userInput(UIr,1) = ("Does the registration ever get wonky? Yes = 1. No = 0."); userInput(UIr,2) = (cutOffFrameQ); UIr = UIr+1;
if cutOffFrameQ == 1 
    cutOffFrame = input('Beyond what frame is the registration wonky? ');  userInput(UIr,1) = ("Beyond what frame is the registration wonky?"); userInput(UIr,2) = (cutOffFrame); UIr = UIr+1;
    if pixIntQ == 1 
        reg___Stacks = reg_Stacks; clear reg_Stacks; 
        reg_Stacks = cell(1,numZplanes);
        for zStack = 1:numZplanes
            reg_Stacks{zStack} = reg___Stacks{zStack}(:,:,1:cutOffFrame);
        end 
    end 
    
    if VsegQ == 1
        reg___StacksVesSeg = reg_Stacks; clear reg_Stacks; 
        reg_Stacks = cell(1,numZplanes);
        for zStack = 1:numZplanes
            reg_Stacks{zStack} = reg___StacksVesSeg{zStack}(:,:,1:cutOffFrame);
        end 
    end 
    
    if cumStacksQ == 1 
        reg___Stacks = reg_Stacks; clear reg_Stacks; 
        reg_Stacks = cell(1,numZplanes);
        for zStack = 1:numZplanes
            reg_Stacks{zStack} = reg___Stacks{zStack}(:,:,1:cutOffFrame);
%             CumData{zStack}(:,:,cutOffFrame+1:end) = [];
%             CumDffDataFirst20s{zStack}(:,:,cutOffFrame+1:end) = [];
%             dffDataFirst20s{zStack}(:,:,cutOffFrame+1:end) = [];
        end        
    end 
    
    ResampedVel_wheel__data = ResampedVel_wheel_data; clear ResampedVel_wheel_data; 
    ResampedVel_wheel_data = ResampedVel_wheel__data(1:cutOffFrame);
end 

%% separate stacks by zPlane and trial type 
disp('Organizing Z-Stacks by Trial Type')
%go to the right directory for functions 
[imAn1funcDir] = getUserInput(userInput,'imAnalysis1_functions Directory');
cd(imAn1funcDir);

%find the diffent trial types 
[stimTimes] = getUserInput(userInput,"Stim Time Lengths (sec)"); 
[stimTypeNum] = getUserInput(userInput,"How many different kinds of stimuli were used?");
[uniqueTrialData,uniqueTrialDataOcurr,indices,state_start_f,uniqueTrialDataTemplate] = separateTrialTypes(TrialTypes,state_start_f,state_end_f,stimTimes,numZplanes,FPS,stimTypeNum); 

if volIm == 1
    %separate the Z-stacks 
    sortedStacks = cell(1,length(reg_Stacks));
    for Zstack = 1:length(reg_Stacks)
          [sorted_Stacks,indices] = eventTriggeredAverages_STACKS2(reg_Stacks{Zstack},state_start_f,FPS,indices,uniqueTrialData,uniqueTrialDataOcurr,userInput,numZplanes);
          sortedStacks{Zstack} = sorted_Stacks;           
    end 
elseif volIm == 0
    %separate the Z-stacks      
      [sorted_Stacks,indices] = eventTriggeredAverages_STACKS2(reg_Stacks{1},state_start_f,FPS,indices,uniqueTrialData,uniqueTrialDataOcurr,userInput,numZplanes);
      sortedStacks{1} = sorted_Stacks;           
end 
        
[sortedStacks,~,~] = removeEmptyCells(sortedStacks,indices);

%below removes indices in cells where sortedStacks is blank 
for trialType = 1:size(sortedStacks{1},2)
    if isempty(sortedStacks{1}{trialType}) == 1 
        indices{trialType} = [];         
    end 
end 

if cumStacksQ == 1  
    [dffStacks,CumDffStacks,CumStacks] = makeCumPixStacksPerTrial(sortedStacks,FPS,numZplanes,sec_before_stim_start);
end

%% vessel segmentation
if VsegQ == 1
        [sortedData,userInput,UIr,ROIboundData] = segmentVessels(reg_Stacks,volIm,UIr,userInput,state_start_f,FPS,indices,uniqueTrialData,uniqueTrialDataOcurr,numZplanes);
end 

%% measure changes in calcium dynamics and BBB permeability 
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
% %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% 
%           CaROImasks{1}(CaROImasks{1}==9)=0; CaROImasks{3}(CaROImasks{3}==11)=0; CaROImasks{1}(CaROImasks{1}==3)=0; CaROImasks{3}(CaROImasks{3}==8)=0;%CaROImasks{2}(CaROImasks{2}==10)=0;
%           figure;imagesc(CaROImasks{1});grid on;figure;imagesc(CaROImasks{2});grid on;figure;imagesc(CaROImasks{3});grid on
%         
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
            meanPixIntArray = cell(1,ROIinds(maxCells));
            for ccell = 1:maxCells %cell starts at 2 because that's where our cell identity labels begins (see identifyROIsAcrossZ function)
                %find the number of z planes a cell/terminal appears in 
                count = 1;
                %this figures out what planes in Z each cell occurs in (cellZ)
                for Z = 1:length(CaROImasks)                
                    if ismember(ROIinds(ccell),CaROImasks{Z}) == 1 
                        cellInd = max(unique(ROIorders{Z}(CaROImasks{Z} == ROIinds(ccell))));
                        for frame = 1:length(reg_Stacks{Z})
                            stats = regionprops(ROIorders{Z},reg_Stacks{Z}(:,:,frame),'MeanIntensity');
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
            
             dataMeds = cell(1,ROIinds(maxCells));
             DFOF = cell(1,ROIinds(maxCells));
             dataSlidingBLs = cell(1,ROIinds(maxCells));
             DFOFsubSBLs = cell(1,ROIinds(maxCells));
             zData = cell(1,ROIinds(maxCells));
             for ccell = 1:maxCells     
                    for z = 1:size(meanPixIntArray{ROIinds(ccell)},1)     
                        %get median value per trace
                        dataMed = nanmedian(meanPixIntArray{ROIinds(ccell)}(z,:));     
                        dataMeds{ROIinds(ccell)}(z,:) = dataMed;
                        %compute DF/F using means  
                        DFOF{ROIinds(ccell)}(z,:) = (meanPixIntArray{ROIinds(ccell)}(z,:)-dataMeds{ROIinds(ccell)}(z,:))./dataMeds{ROIinds(ccell)}(z,:);                         
                        %get sliding baseline 
                        [dataSlidingBL]=slidingBaseline(DFOF{ROIinds(ccell)}(z,:),floor((FPS/numZplanes)*10),0.5); %0.5 quantile thresh = the median value                 
                        dataSlidingBLs{ROIinds(ccell)}(z,:) = dataSlidingBL;                       
                        %subtract sliding baseline from DF/F
                        DFOFsubSBLs{ROIinds(ccell)}(z,:) = DFOF{ROIinds(ccell)}(z,:)-dataSlidingBLs{ROIinds(ccell)}(z,:);
                        %z-score data 
                        zData{ROIinds(ccell)}(z,:) = zscore(DFOFsubSBLs{ROIinds(ccell)}(z,:));
                    end
             end

            %sort calcium data by trial type 
            for ccell = 1:maxCells
                for Z = 1:size(zData{ROIinds(ccell)},1)  
                    [sortedStatArray,indices] = eventTriggeredAverages(zData{ROIinds(ccell)}(Z,:),state_start_f,FPS,indices,uniqueTrialData,uniqueTrialDataOcurr,userInput,numZplanes);            
                    sortedData{ROIinds(ccell)}(Z,:) = sortedStatArray;
                end                  
            end            
        end 
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

%% average dff, cum dff,cum stacks across all trials, ALSO average pix intensity/vessel width data if applicable
%{
if cumStacksQ == 1 
%     CumDff_Stacks = cell(1,numZplanes);
%     Cum_Stacks = cell(1,numZplanes);
%     dff_Stacks = cell(1,numZplanes);
%     AVcumDffStacks = cell(1,numZplanes);
%     AVcumStacks = cell(1,numZplanes);
%     AVdffStacks = cell(1,numZplanes);
    AVStacks = cell(1,numZplanes);
    for Z = 1:numZplanes
        for trialType = 1:size(sortedStacks{1},2)
            if isempty(sortedStacks{Z}{trialType}) == 0
                for trial = 1:length(CumDffStacks{Z}{trialType})
% %                     CumDff_Stacks{Z}{trialType}(:,:,:,trial) = CumDffStacks{Z}{trialType}{trial};
% %                     Cum_Stacks{Z}{trialType}(:,:,:,trial) = CumStacks{Z}{trialType}{trial};
% %                     dff_Stacks{Z}{trialType}(:,:,:,trial) = dffStacks{Z}{trialType}{trial};
                    sorted_Stacks{Z}{trialType}(:,:,:,trial) = sortedStacks{Z}{trialType}{trial};
                end 
%                 AVcumDffStacks{Z}{trialType} = mean(CumDff_Stacks{Z}{trialType},4);
%                 AVcumStacks{Z}{trialType} = mean(Cum_Stacks{Z}{trialType},4);
%                 AVdffStacks{Z}{trialType} = mean(dff_Stacks{Z}{trialType},4);
                AVStacks{Z}{trialType} = mean(sorted_Stacks{Z}{trialType},4);
            end 
        
        end 
    end 
end 

if pixIntQ == 1        
    sortedStats_Array = cell(1,ROIinds(maxCells));
    AVsortedData = cell(1,ROIinds(maxCells));
    for ccell = 1:maxCells       
        for z = 1:size(sortedData{ROIinds(ccell)},1)
            for trialType = 1:size(sortedData{ROIinds(ccell)},2) 
                if isempty(sortedData{ROIinds(ccell)}{z,trialType}) == 0
                    for trial = 1:length(sortedData{ROIinds(ccell)}{z,trialType})
                         sortedStats_Array{ROIinds(ccell)}{z,trialType}(:,:,:,trial) = sortedData{ROIinds(ccell)}{z,trialType}{trial};
                    end 
                    AVsortedData{ROIinds(ccell)}{z,trialType}(1,:) = mean(sortedStats_Array{ROIinds(ccell)}{z,trialType},4);
                end 
            end 
        end 
    end        
end 

if VsegQ == 1
    for z = 1:length(sortedData)
        for ROI = 1:size(sortedData{1},2)
            for trialType = 1:size(sortedData{1}{1},2)   
                if isempty(sortedData{z}{ROI}{trialType}) == 0                  
                    for trial = 1:length(sortedData{z}{ROI}{trialType})  
                        if isempty(sortedData{z}{ROI}{trialType}{trial}) == 0  
                            sortedStats_Array{z}{ROI}{trialType}(:,:,:,trial) = sortedData{z}{ROI}{trialType}{trial};
                        end 
                    end 
                    AVsortedData{z}{ROI}{trialType}(1,:) = mean(sortedStats_Array{z}{ROI}{trialType},4);
                end               
            end            
        end 
    end 
end 

sortedWheel_Data = cell(1,size(sortedStacks{1},2));
AVwheelData = cell(1,size(sortedStacks{1},2));
for trialType = 1:size(sortedStacks{1},2)   
    if isempty(sortedWheelData{trialType}) == 0
        for trial = 1:length(sortedWheelData{trialType})
            if isempty(sortedWheelData{trialType}{trial}) == 0
                sortedWheel_Data{trialType}(:,:,:,trial) = sortedWheelData{trialType}{trial};
            end 
        end   
        AVwheelData{trialType}(1,:) = mean(sortedWheel_Data{trialType},4); 
    end 
end 
%}

%% reorganize data so that the trials are grouped together by type

%resort the indices 
 indS = cell(1,size(sortedStacks{1},2));
 indI = cell(1,size(sortedStacks{1},2));
 for trialType = 1:size(sortedStacks{1},2)   
    [S, I] = sort(indices{trialType});
    indS{trialType} = S;
    indI{trialType} = I;
 end 

%figure out max column of data types available 
tTypeInds = zeros(1,size(sortedStacks{1},2));
for trialType = 1:size(sortedStacks{1},2)
    if ismember(uniqueTrialData(trialType,:),uniqueTrialDataTemplate,'rows') == 1 
        [~, idx] = ismember(uniqueTrialData(trialType,:),uniqueTrialDataTemplate,'rows');
        tTypeInds(trialType) = idx; 
    end 
end 
maxTtypeInd = max(tTypeInds);

%sort data into correct spot based on trial type 
if pixIntQ == 1 
    sortedData2 = cell(1,ROIinds(maxCells));
    for ccell = 1:maxCells    
        for z = 1:size(sortedData{ROIinds(ccell)},1)  
            for trialType = 1:maxTtypeInd 
                if ismember(uniqueTrialDataTemplate(trialType,:),uniqueTrialData,'rows') == 1
                    [~, idxStart] = ismember(uniqueTrialDataTemplate(trialType,:),uniqueTrialData,'rows');  
                    [~, idxFin] = ismember(uniqueTrialDataTemplate(trialType,:),uniqueTrialDataTemplate,'rows');
                    
                    indI2{idxFin} = indI{idxStart};
                    indices2{idxFin} = indices{idxStart};                   
                    sortedData2{ROIinds(ccell)}{z,idxFin} = sortedData{ROIinds(ccell)}{z,idxStart};                    
                end 
            end
        end 
    end 
    indices2 = indices2';
end 

if VsegQ == 1
    for z = 1:length(sortedData)
        for ROI = 1:size(sortedData{1},2)
            for trialType = 1:maxTtypeInd        
                if ismember(uniqueTrialDataTemplate(trialType,:),uniqueTrialData,'rows') == 1
                    [~, idxStart] = ismember(uniqueTrialDataTemplate(trialType,:),uniqueTrialData,'rows');  
                    [~, idxFin] = ismember(uniqueTrialDataTemplate(trialType,:),uniqueTrialDataTemplate,'rows');
                    
                    indI2{idxFin} = indI{idxStart};
                    indices2{idxFin} = indices{idxStart};                   
                    sortedData2{z}{ROI}{idxFin} = sortedData{z}{ROI}{idxStart};                    
                end 
            end          
        end 
    end 
    indices2 = indices2';
end 

if cumStacksQ == 1
    sortedStacks2 = cell(1,length(sortedStacks));
%     CumStacks2 = cell(1,length(sortedStacks));
%     CumDffStacks2 = cell(1,length(sortedStacks));
%     dffStacks2 = cell(1,length(sortedStacks));
%     AVStacks2 = cell(1,length(sortedStacks));
%     AVcumStacks2 = cell(1,length(sortedStacks));
%     AVcumDffStacks2 = cell(1,length(sortedStacks));
%     AVdffStacks2 = cell(1,length(sortedStacks));
    for z = 1:length(sortedStacks)
        for trialType = 1:maxTtypeInd     
            if ismember(uniqueTrialDataTemplate(trialType,:),uniqueTrialData,'rows') == 1
                [~, idxStart] = ismember(uniqueTrialDataTemplate(trialType,:),uniqueTrialData,'rows');  
                [~, idxFin] = ismember(uniqueTrialDataTemplate(trialType,:),uniqueTrialDataTemplate,'rows');

                indI2{idxFin} = indI{idxStart};
                indices2{idxFin} = indices{idxStart};                   
                sortedStacks2{z}{idxFin} = sortedStacks{z}{idxStart};  
%                 CumStacks2{z}{idxFin} = CumStacks{z}{idxStart};
%                 CumDffStacks2{z}{idxFin} = CumDffStacks{z}{idxStart};
%                 dffStacks2{z}{idxFin} = dffStacks{z}{idxStart};
%                 AVStacks2{z}{idxFin} = AVStacks{z}{idxStart};  
%                 AVcumStacks2{z}{idxFin} = AVcumStacks{z}{idxStart};
%                 AVcumDffStacks2{z}{idxFin} = AVcumDffStacks{z}{idxStart};
%                 AVdffStacks2{z}{idxFin} = AVdffStacks{z}{idxStart};
            end 
        end          
    end 
    indices2 = indices2';
end 

%sort wheel data into correct spot based on trial type 
for trialType = 1:maxTtypeInd 
    if ismember(uniqueTrialDataTemplate(trialType,:),uniqueTrialData,'rows') == 1
        [~, idxStart] = ismember(uniqueTrialDataTemplate(trialType,:),uniqueTrialData,'rows');  
        [~, idxFin] = ismember(uniqueTrialDataTemplate(trialType,:),uniqueTrialDataTemplate,'rows');
                  
        sortedWheelData2{idxFin} = sortedWheelData{idxStart};                    
    end     
end

%% reorder trials from earliest to latest occurance in time %
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@    FIX THIS LATER    @@@@@@@@@@@@@@@@@@@@@@@@@@@@
%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
% 
% dataToPlot = sortedData2;
% wheelDataToPlot = sortedWheelData2;

sortedStacks = sortedStacks2;
wheelDataToPlot = sortedWheelData2;

%{
% if pixIntQ == 1    
%     dataToPlot = cell(1,ROIinds(maxCells));
%     for ccell = 1:maxCells  
%         for z = 1:size(sortedData2{ROIinds(ccell)},1)
%             for trialType = 1:maxTtypeInd 
%                 if isempty(sortedData2{ROIinds(ccell)}{z,trialType}) == 0
%                     dataToPlot{ROIinds(ccell)}{z,trialType} = sortedData2{ROIinds(ccell)}{z,trialType}(indI2{trialType}(1:length(sortedData2{ROIinds(ccell)}{z,trialType})));     
%                 end 
%             end 
%         end 
%     end 
% end 
% 
% if VsegQ == 1  
%     for z = 1:length(sortedData)
%         for ROI = 1:size(sortedData{1},2)             
%             for trialType = 1:maxTtypeInd     
%                 if isempty(sortedData2{z}{ROI}{trialType}) == 0
%                     dataToPlot{z}{ROI}{trialType} = sortedData2{z}{ROI}{trialType}(indI2{trialType});     
%                 end   
%             end 
%         end 
%     end 
% end 
% 
% if cumStacksQ == 1 
%     clear sortedStacks CumStacks CumDffStacks dffStacks AVStacks AVcumStacks AVcumDffStacks AVdffStacks;
% %     AVStacks = AVStacks2; AVcumStacks = AVcumStacks2; AVcumDffStacks = AVcumDffStacks2; AVdffStacks = AVdffStacks2;
%     sortedStacks = cell(1,length(sortedStacks2));
%     CumStacks = cell(1,length(sortedStacks2));
%     CumDffStacks = cell(1,length(sortedStacks2));
%     dffStacks = cell(1,length(sortedStacks2));
%     for z = 1:length(sortedStacks2)        
%         for trialType = 1:maxTtypeInd     
%             if isempty(sortedStacks2{z}{trialType}) == 0
%                 sortedStacks{z}{trialType} = sortedStacks2{z}{trialType}(indI2{trialType});    
% %                 CumStacks{z}{trialType} = CumStacks2{z}{trialType}(indI2{trialType}); 
% %                 CumDffStacks{z}{trialType} = CumDffStacks2{z}{trialType}(indI2{trialType}); 
% %                 dffStacks{z}{trialType} = dffStacks2{z}{trialType}(indI2{trialType}); 
%             end   
%         end  
%     end 
% end 
%  
% wheelDataToPlot = cell(1,maxTtypeInd);
% for trialType = 1:maxTtypeInd 
%     if isempty(sortedWheelData2{trialType}) == 0 
%         wheelDataToPlot{trialType} = sortedWheelData2{trialType}(indI2{trialType});  
%     end 
% end 
%}

%% clear unecessary values 

if cumStacksQ == 1
    clearvars -except dataToPlot AVsortedData wheelDataToPlot AVwheelData userInput FPS dataMin dataMax velMin velMax HDFchart numZplanes BG_ROIboundData CaROImasks uniqueTrialDataTemplate maxCells ROIorders ROIinds ROIboundData sec_before_stim_start sortedStacks CumStacks CumDffStacks dffStacks CumData CumDffDataFirst20s dffDataFirst20s AVcumDffStacks AVcumStacks AVdffStacks AVStacks
elseif  VsegQ == 1 || pixIntQ == 1
    clearvars -except dataToPlot AVsortedData wheelDataToPlot AVwheelData userInput FPS dataMin dataMax velMin velMax HDFchart numZplanes BG_ROIboundData CaROImasks uniqueTrialDataTemplate maxCells ROIorders ROIinds ROIboundData sec_before_stim_start
end 
%}
