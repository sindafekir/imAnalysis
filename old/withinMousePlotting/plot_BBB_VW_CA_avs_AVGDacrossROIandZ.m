function plot_BBB_VW_CA_avs_AVGDacrossROIandZ(BdataToPlot,CdataToPlot,VdataToPlot,userInput,FPS,numZplanes,sec_before_stim_start)

BBBQ = input('Do you want to plot BBB data? Yes = 1. No = 0. ');
VwQ = input('Do you want to plot vessel width? Yes = 1. No = 0. ');
CaQ = input('Do you want to plot calcium data? Yes = 1. No = 0. ');

%% average across ROIs and z planes 
if BBBQ == 1
    %BBB data 
    BAVdataToPlot1_array = cell(1,length(BdataToPlot));
    BAVdataToPlot1 = cell(1,length(BdataToPlot));
    BAVdataToPlot2_array = cell(1,size(BdataToPlot{1},2));
    BAVdataToPlot = cell(1,size(BdataToPlot{1},2));
    for Z = 1:length(BdataToPlot)
        for trialType = 1:size(BdataToPlot{Z},2)

            if isempty(BdataToPlot{Z}{trialType}) == 0 
                for trial = 1:size(BdataToPlot{Z}{trialType},2)
                    for VROI = 1:size(BdataToPlot{Z}{trialType}{trial},2)
                        BAVdataToPlot1_array{Z}{trialType}{trial}(VROI,:) = BdataToPlot{Z}{trialType}{trial}{VROI};
                        BAVdataToPlot1{Z}{trialType}{trial} = nanmean(BAVdataToPlot1_array{Z}{trialType}{trial},1);


                        BAVdataToPlot2_array{trialType}{trial}(Z,:) = BAVdataToPlot1{Z}{trialType}{trial};
                        BAVdataToPlot{trialType}{trial} = nanmean(BAVdataToPlot2_array{trialType}{trial},1);
                    end 
                end 
            end 

        end 
    end 
end 

if CaQ == 1
    %calcium data 
    ROI = 1;
    CAVdataToPlot2_array = cell(1,size(CdataToPlot{ROIinds(1)},2));
    CAVdataToPlot = cell(1,size(CdataToPlot{ROIinds(1)},2));
    for ccell = 1:maxCells
        for trialType = 1:size(CdataToPlot{ROIinds(ccell)},2) 
            for Z = 1:size(CdataToPlot{ROIinds(ccell)},1) 
                if ismember(ROIinds(ccell),CaROImasks{Z}) == 1 
    %                 cellROI = max(unique(ROIorders{Z}(CaROImasks{Z} == ROIROIs(ccell))));
                    for trial = 1:length(CdataToPlot{ROIinds(ccell)}{Z,trialType})    
                        if isempty(CdataToPlot{ROIinds(ccell)}{Z,trialType}{trial})==0
                            CAVdataToPlot1_array{ROI}{trialType}{trial}(Z,:) = CdataToPlot{ROIinds(ccell)}{Z,trialType}{trial};                   
                            CAVdataToPlot1{ROI}{trialType}{trial} = nanmean(CAVdataToPlot1_array{ROI}{trialType}{trial},1);

                            CAVdataToPlot2_array{trialType}{trial}(ROI,:) = CAVdataToPlot1{ROI}{trialType}{trial};
                            CAVdataToPlot{trialType}{trial} = nanmean(CAVdataToPlot2_array{trialType}{trial},1);
                        end 

                    end 
                end 
            end 
        end 
        ROI = ROI+1;
    end 
end 

if VwQ == 1 
    %vessel width data 
    VAVdataToPlot1_array = cell(1,length(VdataToPlot));
    VAVdataToPlot1 = cell(1,length(VdataToPlot));
    VAVdataToPlot2_array = cell(1,size(VdataToPlot{1}{1},2));
    VAVdataToPlot = cell(1,size(VdataToPlot{1}{1},2));
    for z = 1:length(VdataToPlot)
        for ROI = 1:size(VdataToPlot{z},2)
            for trialType = 1:size(VdataToPlot{1}{1},2)   
                if isempty(VdataToPlot{z}{ROI}{trialType}) == 0                  
                    for trial = 1:length(VdataToPlot{z}{ROI}{trialType})      
                         if isempty(VdataToPlot{z}{ROI}{trialType}{trial}) == 0    

                            VAVdataToPlot1_array{z}{trialType}{trial}(ROI,:) = VdataToPlot{z}{ROI}{trialType}{trial};
                            VAVdataToPlot1{z}{trialType}{trial} = nanmean(VAVdataToPlot1_array{z}{trialType}{trial},1);

                            VAVdataToPlot2_array{trialType}{trial}(z,:) = VAVdataToPlot1{z}{trialType}{trial};
                            VAVdataToPlot{trialType}{trial} = nanmean(VAVdataToPlot2_array{trialType}{trial},1);
                         end 
                    end 
                end 
            end 
        end 
    end 
end 


%% smooth data if you want 
smoothQ = input('Do you want to smooth your data? Yes = 1. No = 0. ');

if smoothQ == 1 
%     UIr = size(userInput,1)+1;
    filtTime = input('How many seconds do you want to smooth your data by? ');% userInput(UIr,1) = ("How many seconds do you want to smooth your data by? "); userInput(UIr,2) = (filtTime); UIr = UIr+1;

    if BBBQ == 1
        % BBB data 
        BfiltData = cell(1,size(BAVdataToPlot,2));
        for trialType = 1:size(BAVdataToPlot,2)             
            if isempty(BAVdataToPlot{trialType}) == 0 
                for trial = 1:size(BAVdataToPlot{trialType},2)
                    [BfiltD] = MovMeanSmoothData(BAVdataToPlot{trialType}{trial},filtTime,FPS);
                    BfiltData{trialType}{trial} = BfiltD;
                end 
            end 
        end 
    end 
    
    if CaQ == 1
        % calcium data 
        CfiltData = cell(1,length(CAVdataToPlot));
        for trialType = 1:size(CAVdataToPlot,2)             
            if isempty(CAVdataToPlot{trialType}) == 0 
                for trial = 1:size(CAVdataToPlot{trialType},2)                 
                    [CfiltD] = MovMeanSmoothData(CAVdataToPlot{trialType}{trial},filtTime,FPS);
                    CfiltData{trialType}{trial} = CfiltD;                 
                end
            end 
        end 
    end 
    
    if VwQ == 1
        % vessel width data 
        VfiltData = cell(1,size(VAVdataToPlot,2));
        for trialType = 1:size(VAVdataToPlot,2)   
            if isempty(VAVdataToPlot{trialType}) == 0                  
                for trial = 1:length(VAVdataToPlot{trialType})                         
                    [VfiltD] = MovMeanSmoothData(VAVdataToPlot{trialType}{trial},filtTime,FPS);
                    VfiltData{trialType}{trial} = VfiltD;                        
                end 
            end 
        end
    end 
%      
    
elseif smoothQ == 0 
    if BBBQ == 1
       % BBB data 
        BfiltData = cell(1,size(BAVdataToPlot,2));
        for trialType = 1:size(BAVdataToPlot,2)             
            if isempty(BAVdataToPlot{trialType}) == 0 
                for trial = 1:size(BAVdataToPlot{trialType},2)
                    BfiltData{trialType}{trial} = BAVdataToPlot{trialType}{trial};
                end 
            end 
        end 
    end 
    
    if CaQ == 1    
        % calcium data 
        CfiltData = cell(1,length(CAVdataToPlot));
        for trialType = 1:size(CAVdataToPlot,2)             
            if isempty(CAVdataToPlot{trialType}) == 0 
                for trial = 1:size(CAVdataToPlot{trialType},2)
                    CfiltData{trialType}{trial} = CAVdataToPlot{trialType}{trial};
                end 
            end 
        end 
    end 

    if VwQ == 1
        % vessel data 
        VfiltData = cell(1,size(VAVdataToPlot,2));
        for trialType = 1:size(VAVdataToPlot,2)   
            if isempty(VAVdataToPlot{trialType}) == 0                  
                for trial = 1:length(VAVdataToPlot{trialType})    
                    VfiltData{trialType}{trial} = VAVdataToPlot{trialType}{trial};                        
                end 
            end 
        end
    end 
    
end 


% average across trials
if BBBQ == 1
    % BBB data 
    BAVarray = cell(1,size(BAVdataToPlot,2));
    BAVdata = cell(1,size(BAVdataToPlot,2));
    BSEMdata = cell(1,size(BAVdataToPlot,2));
    for trialType = 1:size(BAVdataToPlot,2)
        if isempty(BAVdataToPlot{trialType}) == 0 
            for trial = 1:size(BAVdataToPlot{trialType},2)
                BAVarray{trialType}(trial,:) = BfiltData{trialType}{trial};
            end 
            BAVdata{trialType}= nanmean(BAVarray{trialType},1);
            BSEMdata{trialType} = (nanstd(BAVarray{trialType},1))/(sqrt(size(BfiltData{trialType},2)));
        end      
    end 
end 

if CaQ == 1
    % calcium data 
    %average across trials
    CAVarray = cell(1,length(CAVdataToPlot));
    CAVdata = cell(1,length(CAVdataToPlot));
    CSEMdata = cell(1,size(CAVdataToPlot,2));
    for trialType = 1:size(CAVdataToPlot,2)
        if isempty(CfiltData{trialType}) == 0 
            for trial = 1:size(CAVdataToPlot{trialType},2)
                if isempty(CfiltData{trialType}{trial}) == 0 
                    CAVarray{trialType}(trial,:) = CfiltData{trialType}{trial};
                    CAVdata{trialType} = nanmean(CAVarray{trialType},1);
                    CSEMdata{trialType} = (nanstd(CAVarray{trialType},1))/(sqrt(size(CfiltData{trialType},2)));
                end 
            end 
        end   
    end 
end 

if VwQ == 1 
    % vessel width data 
    VAVarray = cell(1,size(VAVdataToPlot,2) );
    VAVdata = cell(1,size(VAVdataToPlot,2) );
    VSEMdata = cell(1,size(VAVdataToPlot,2) );
    for trialType = 1:size(VAVdataToPlot,2)   
        if isempty(VAVdataToPlot{trialType}) == 0                  
            for trial = 1:length(VAVdataToPlot{trialType})    
                if isempty(VAVdataToPlot{trialType}{trial}) == 0 
                    VAVarray{trialType}(trial,:) = VfiltData{trialType}{trial};
                end 
            end 
            VAVdata{trialType} = nanmean(VAVarray{trialType},1);
            VSEMdata{trialType} = (nanstd(VAVarray{trialType},1))/(sqrt(size(VAVdataToPlot{trialType},2)));
         end 
    end 
end 


%% plot 
dataMin = input("data Y axis MIN: ");
dataMax = input("data Y axis MAX: ");
FPSstack = FPS/numZplanes;
baselineEndFrame = round(sec_before_stim_start*(FPSstack));

if BBBQ == 1 
    dataToPlot = BAVdataToPlot;
end 
if VwQ == 1 
    dataToPlot = VAVdataToPlot;
end 
if CaQ == 1 
    dataToPlot = CAVdataToPlot;
end 

for trialType = 1:size(dataToPlot,2)  
    if isempty(dataToPlot{trialType}) == 0

        figure;
        %set time in x axis            
        if trialType == 1 || trialType == 3 
            Frames = size(dataToPlot{trialType}{2},2);                
            Frames_pre_stim_start = -((Frames-1)/2); 
            Frames_post_stim_start = (Frames-1)/2; 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+2);
            FrameVals = round((1:FPSstack*2:Frames)-1); 
        elseif trialType == 2 || trialType == 4 
            Frames = size(dataToPlot{trialType}{2},2);
            Frames_pre_stim_start = -((Frames-1)/2); 
            Frames_post_stim_start = (Frames-1)/2; 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+11);
            FrameVals = round((1:FPSstack*2:Frames)-1); 
        end 
        
        ax=gca;
        if BBBQ == 1 
            plot(BAVdata{trialType},'r')
        end 
        hold all;     
        if CaQ == 1
            plot(CAVdata{trialType},'b')
        end 
        if VwQ == 1
         plot(VAVdata{trialType},'k')
        end 
        
        if BBBQ == 1 
            varargout = boundedline(1:size(BAVdata{trialType},2),BAVdata{trialType},BSEMdata{trialType},'r','transparency', 0.3,'alpha');  
        end 
        if CaQ == 1
            varargout = boundedline(1:size(CAVdata{trialType},2),CAVdata{trialType},CSEMdata{trialType},'b','transparency', 0.3,'alpha');   
        end 
        if VwQ == 1            
            varargout = boundedline(1:size(VAVdata{trialType},2),VAVdata{trialType},VSEMdata{trialType},'k','transparency', 0.3,'alpha');                        
        end 

        ax.XTick = FrameVals;
        ax.XTickLabel = sec_TimeVals;
        ax.FontSize = 20;
        if trialType == 1 
            plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'b','LineWidth',3)
            %patch([baselineEndFrame round(baselineEndFrame+((FPSstack/numZplanes)*2)) round(baselineEndFrame+((FPSstack/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
            %alpha(0.4)   
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',3) 
        elseif trialType == 3 
            plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'r','LineWidth',3)
            %patch([baselineEndFrame round(baselineEndFrame+((FPSstack/numZplanes)*2)) round(baselineEndFrame+((FPSstack/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
            %alpha(0.4)     
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',3) 
        elseif trialType == 2 
            plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'b','LineWidth',3)
            %patch([baselineEndFrame round(baselineEndFrame+((FPSstack/numZplanes)*20)) round(baselineEndFrame+((FPSstack/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
            %alpha(0.4)   
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',3) 
        elseif trialType == 4 
            plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'r','LineWidth',3)
            %patch([baselineEndFrame round(baselineEndFrame+((FPSstack/numZplanes)*20)) round(baselineEndFrame+((FPSstack/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
            %alpha(0.4)  
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',3) 
        end

%             legend('BBB','DA Calcium','Vessel Width')
        if BBBQ == 1 
            legend('BBB')
        end 
        if CaQ == 1
            legend('DA Calcium')  
        end 
        if VwQ == 1            
            legend('Vessel Width')                       
        end 
        
        
        
        ylim([dataMin dataMax]);

        if smoothQ == 1 
            title(sprintf('Data smoothed by %d seconds.',filtTime));
        elseif smoothQ == 0
            title("Raw Data.");
        end 

    end                       
end





end 