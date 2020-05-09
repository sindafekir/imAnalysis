% function [TSdataBBBperm] = calciumTSwholeExp(regStacks,userInput)
%% get just the data you need 
temp1 = matfile('SF57_20190717_ROI1_9_regIms_green.mat');
regStacks = temp1.regStacks;
numZplanes = temp1.numZplanes ;

temp2 = matfile('SF57_20190717_DAca_V1-6_8_vesAndCalciumData.mat');
userInput = temp2.userInput; 
CaROImasks = temp2.CaROImasks; 
ROIorders = temp2.ROIorders; 

%% do background subtraction 
input_Stacks = regStacks{2,3};
[inputStacks,BG_ROIboundData] = backgroundSubtraction(input_Stacks);

%% get rid of frames/trials where registration gets wonky 
%EVENTUALLY MAKE THIS AUTOMATIC INSTEAD OF HAVING TO INPUT WHAT FRAME THE
%REGISTRATION GETS WONKY 
cutOffFrameQ = input('Does the registration ever get wonky? Yes = 1. No = 0. '); 
if cutOffFrameQ == 1 
    cutOffFrame = input('Beyond what frame is the registration wonky? ');  
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
%  dataMeds = cell(1,ROIinds(maxCells));
%  DFOF = cell(1,ROIinds(maxCells));
 dataSlidingBLs = cell(1,ROIinds(maxCells));
FsubSBLs = cell(1,ROIinds(maxCells));
%  zData = cell(1,length(ROIinds));
%  count = 1;
 for ccell = 1:maxCells     
        for z = 1:size(meanPixIntArray{ROIinds(ccell)},1)     
%             %get median value per trace
%             dataMed = median(meanPixIntArray{ROIinds(ccell)}(z,:));     
%             dataMeds{ROIinds(ccell)}(z,:) = dataMed;
%             %compute DF/F using means  
%             DFOF{ROIinds(ccell)}(z,:) = (meanPixIntArray{ROIinds(ccell)}(z,:)-dataMeds{ROIinds(ccell)}(z,:))./dataMeds{ROIinds(ccell)}(z,:);                         
            %get sliding baseline 
%             [dataSlidingBL]=slidingBaseline(DFOF{ROIinds(ccell)}(z,:),floor((FPS/numZplanes)*10),0.5); %0.5 quantile thresh = the median value      
            [dataSlidingBL]=slidingBaseline(meanPixIntArray{ROIinds(ccell)}(z,:),floor((FPS/numZplanes)*10),0.5); %0.5 quantile thresh = the median value
            dataSlidingBLs{ROIinds(ccell)}(z,:) = dataSlidingBL;                       
%             %subtract sliding baseline from DF/F
%             DFOFsubSBLs{ROIinds(ccell)}(z,:) = DFOF{ROIinds(ccell)}(z,:)-dataSlidingBLs{ROIinds(ccell)}(z,:);
            %subtract sliding baseline from F trace 
            FsubSBLs{ROIinds(ccell)}(z,:) = meanPixIntArray{ROIinds(ccell)}(z,:)-dataSlidingBLs{ROIinds(ccell)}(z,:);

            %z-score data 
%             zData{ROIinds(ccell)}(z,:) = zscore(DFOFsubSBLs{ROIinds(ccell)}(z,:));
        end
%         count = count + 1 ;
 end        

%% average across z and cells 
%  zData2 = cell(1,length(zData));
%  zData2array = zeros(length(zData),size(zData{1},2));
meanPixIntArray2 = cell(1,length(meanPixIntArray));
meanPixIntArray3 = zeros(length(meanPixIntArray),size(meanPixIntArray{2},2));
dataSlidingBLs2 = cell(1,length(meanPixIntArray));
dataSlidingBLs3 = zeros(length(meanPixIntArray),size(meanPixIntArray{2},2));
FsubSBLs2 = cell(1,length(meanPixIntArray));
FsubSBLs3 = zeros(length(meanPixIntArray),size(meanPixIntArray{2},2));
 for ccell = 1:maxCells
%      zData2{ROIinds(ccell)} = nanmean(zData{ROIinds(ccell)},1);
%      zData2array(ROIinds(ccell),:) = zData2{ROIinds(ccell)};
       meanPixIntArray2{ROIinds(ccell)} = nanmean(meanPixIntArray{ROIinds(ccell)},1);
       meanPixIntArray3(ROIinds(ccell),:) = meanPixIntArray2{ROIinds(ccell)};
       dataSlidingBLs2{ROIinds(ccell)} = nanmean(dataSlidingBLs{ROIinds(ccell)},1);
       dataSlidingBLs3(ROIinds(ccell),:) = dataSlidingBLs2{ROIinds(ccell)};
       FsubSBLs2{ROIinds(ccell)} = nanmean(FsubSBLs{ROIinds(ccell)},1);
       FsubSBLs3(ROIinds(ccell),:) = FsubSBLs2{ROIinds(ccell)};
 end 
%  Cdata = nanmean(zData2array,1);
%  CcellData = zData2; 
Fdata = nanmean(meanPixIntArray3,1);
slidingBL = nanmean(dataSlidingBLs3,1);
FsubBLdata = nanmean(FsubSBLs3,1);

avFdata = Fdata;
terminalFData = meanPixIntArray2;

avFsubSB = FsubBLdata; 
terminalFsubSB = FsubSBLs2;
 
 
%% seperate data into trialTypes 
Cdata = avFsubSB; CcellData = terminalFsubSB;

termQ = input('Input 0 if you want to plot all terminals. Input 1 if you want to specify what terminals to plot. ');
if termQ == 1 
    terminals = input('What terminals do you want to average? ');
end 

if termQ == 0
    SCdata = cell(1,length(CcellData));
    RSCdata = cell(1,length(CcellData));
    for ccell = 1:length(CcellData)
        if isempty(CcellData{ccell}) == 0
            SCdata{ccell} = CcellData{ccell};
        end 
    end
elseif termQ == 1
    SCdata = cell(1,length(terminals));
    for ccell = 1:length(terminals)
        if isempty(CcellData{terminals(ccell)}) == 0
            SCdata{ccell} = CcellData{terminals(ccell)};
        end 
    end
end 

% prep trial type data 
[framePeriod] = getUserInput(userInput,'What is the framePeriod? ');
[state] = getUserInput(userInput,'What teensy state does the stimulus happen in?');
[HDFchart,state_start_f,state_end_f,FPS,vel_wheel_data,TrialTypes] = makeHDFchart_redBlueStim(state,framePeriod);

TrialTypes = TrialTypes(1:length(state_start_f),:);
state_start_f = floor(state_start_f/3);
state_end_f = floor(state_end_f/3);
trialLength = state_end_f - state_start_f;


% sort data into different trial types to see effects of stims 
clearvars diffAV diffSEM tTdata GtTdataTerm

%make sure the trial lengths are the same per trial type 
%set ideal trial lengths 
lenT1 = floor(FPSstack*2); % 2 second trials 
lenT2 = floor(FPSstack*20); % 20 second trials 
%identify current trial lengths 
[kIdx,kMeans] = kmeans(trialLength,2);
%edit kMeans list so trialLengths is what they should be 
for len = 1:length(kMeans)
    if kMeans(len)-lenT1 < abs(kMeans(len)-lenT2)
        kMeans(len) = lenT1;
    elseif kMeans(len)-lenT1 > abs(kMeans(len)-lenT2)
        kMeans(len) = lenT2;
    end 
end 
%change state_end_f so all trial lengths match up 
for trial = 1:length(state_start_f)
    state_end_f(trial,1) = state_start_f(trial)+kMeans(kIdx(trial));
end 
trialLength = state_end_f - state_start_f;

%reogranize diff data so I can get the SEM 
greenCarray = zeros(length(SCdata),length(SCdata{2}));
for ccell = 1:length(SCdata)
    if isempty(SCdata{ccell}) == 0 
        greenCarray(ccell,:) = SCdata{ccell};
    end 
end 
%replace rows of all 0s w/NaNs
nonZeroRows = all(greenCarray == 0,2);
greenCarray(nonZeroRows,:) = NaN;

%get AV and SEM 
greenSEM = nanstd(greenCarray,1)/sqrt(size(greenCarray,1));
greenAV = nanmean(greenCarray,1);


for term = 1:size(greenCarray,1)
    count1 = 1;count2 = 1;count3 = 1;count4 = 1;
    for trial = 1:size(state_start_f,1)
        if state_start_f(trial)-floor(FPSstack*20) > 0 && state_end_f(trial)+floor(FPSstack*20) < length(greenAV)
            if TrialTypes(trial,2) == 1 % blue trials 
                if trialLength(trial) == floor(FPSstack*2)
                    GtTdata{1}(count1,:) = greenAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20)); 
                    GtTdataTerm{1}{term}(count1,:) = greenCarray(term,state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                    count1 = count1+1;
                elseif trialLength(trial) == floor(FPSstack*20)
                    GtTdata{2}(count2,:) = greenAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                    GtTdataTerm{2}{term}(count2,:) = greenCarray(term,state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                    count2 = count2+1;
                end 
            elseif TrialTypes(trial,2) == 2 % red trials 
                if trialLength(trial) == floor(FPSstack*2)
                    GtTdata{3}(count3,:) = greenAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                    GtTdataTerm{3}{term}(count3,:) = greenCarray(term,state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                    count3 = count3+1;
                elseif trialLength(trial) == floor(FPSstack*20)
                    GtTdata{4}(count4,:) = greenAV(state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                    GtTdataTerm{4}{term}(count4,:) = greenCarray(term,state_start_f(trial)-floor(FPSstack*20):state_end_f(trial)+floor(FPSstack*20));
                    count4 = count4+1;
                end 
            end 
        end 
    end 
end
