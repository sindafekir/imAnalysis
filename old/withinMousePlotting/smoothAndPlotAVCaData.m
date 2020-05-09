function smoothAndPlotAVCaData(dataToPlot,userInput,FPS,numZplanes,sec_before_stim_start,CaROImasks,ROIinds)

%% average across ROIs and z planes 
ROI = 1;
for ccell = 1:maxCells
    for trialType = 1:size(dataToPlot{ROIinds(ccell)},2) 
        for Z = 1:size(dataToPlot{ROIinds(ccell)},1) 
            if ismember(ROIinds(ccell),CaROImasks{Z}) == 1 
%                 cellROI = max(unique(ROIorders{Z}(CaROImasks{Z} == ROIROIs(ccell))));
                for trial = 1:length(dataToPlot{ROIinds(ccell)}{Z,trialType})    
                    if isempty(dataToPlot{ROIinds(ccell)}{Z,trialType}{trial})== 0 
                        AVdataToPlot1_array{ROI}{trialType}{trial}(Z,:) = dataToPlot{ROIinds(ccell)}{Z,trialType}{trial};                   
                        AVdataToPlot1{ROI}{trialType}{trial} = nanmean(AVdataToPlot1_array{ROI}{trialType}{trial},1);

                        AVdataToPlot2_array{trialType}{trial}(ROI,:) = AVdataToPlot1{ROI}{trialType}{trial};
                        AVdataToPlot{trialType}{trial} = nanmean(AVdataToPlot2_array{trialType}{trial},1);
                    end 
                    
                end 
            end 
        end 
    end 
    ROI = ROI+1;
end 


%% smooth data if you want
smoothQ = input('Do you want to smooth your data? Yes = 1. No = 0. ');

if smoothQ == 1 
    UIr = size(userInput,1)+1;
    filtTime = input('How many seconds do you want to smooth your data by? '); userInput(UIr,1) = ("How many seconds do you want to smooth your data by? "); userInput(UIr,2) = (filtTime); UIr = UIr+1;
    filtData = cell(1,length(AVdataToPlot));
        for trialType = 1:size(AVdataToPlot,2)             
            if isempty(AVdataToPlot{trialType}) == 0 
                for trial = 1:size(AVdataToPlot{trialType},2)                 
                    [filtD] = MovMeanSmoothData(AVdataToPlot{trialType}{trial},filtTime,FPS);
                    filtData{trialType}{trial} = filtD;                 
                end
            end 
        end 

elseif smoothQ == 0 
    filtData = cell(1,length(AVdataToPlot));
    for trialType = 1:size(AVdataToPlot,2)             
        if isempty(AVdataToPlot{trialType}) == 0 
            for trial = 1:size(AVdataToPlot{trialType},2)
                filtData{trialType}{trial} = AVdataToPlot{trialType}{trial};
            end 
        end 
    end 
end 


%average across trials
AVarray = cell(1,length(AVdataToPlot));
AVdata = cell(1,length(AVdataToPlot));
for trialType = 1:size(AVdataToPlot,2)
    if isempty(filtData{trialType}) == 0 
        for trial = 1:size(AVdataToPlot{trialType},2)
            if isempty(filtData{trialType}{trial}) == 0 
                AVarray{trialType}(trial,:) = filtData{trialType}{trial};
                AVdata{trialType} = nanmean(AVarray{trialType},1);
            end 
        end 
    end   
end      


%% plot 
dataMin = input("data Y axis MIN: ");
dataMax = input("data Y axis MAX: ");
FPSstack = FPS/numZplanes;
baselineEndFrame = round(sec_before_stim_start*(FPSstack));


for trialType = 1:size(AVdataToPlot,2)  
    if isempty(AVdataToPlot{trialType}) == 0

        figure;
        ColorSet = varycolor(size(filtData{trialType},2));    
        %set time in x axis            
        if trialType == 1 || trialType == 3 
            Frames = size(AVdataToPlot{trialType}{1},2);                
            Frames_pre_stim_start = -((Frames-1)/2); 
            Frames_post_stim_start = (Frames-1)/2; 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+1);
            FrameVals = round((1:FPSstack*2:Frames)-1); 
        elseif trialType == 2 || trialType == 4 
            Frames = size(AVdataToPlot{trialType}{1},2);
            Frames_pre_stim_start = -((Frames-1)/2); 
            Frames_post_stim_start = (Frames-1)/2; 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+10);
            FrameVals = round((1:FPSstack*2:Frames)-1); 
        end 
        for trial = 1:size(AVdataToPlot{trialType},2)  % this plots all trials  
            hold all;                       
            plot(filtData{trialType}{trial},'Color',ColorSet(trial,:))
            ax=gca;
            ax.FontSize = 20;

            hold on;
            if trialType == 1 
                plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'k','LineWidth',3)
                patch([baselineEndFrame round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
                alpha(0.02)   
            elseif trialType == 3 
                plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'k','LineWidth',3)
                patch([baselineEndFrame round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
                alpha(0.02)                       
            elseif trialType == 2 
                plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'k','LineWidth',3)
                patch([baselineEndFrame round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
                alpha(0.02)   
            elseif trialType == 4 
                plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'k','LineWidth',3)
                patch([baselineEndFrame round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
                alpha(0.02)  
            end
            ax.XTick = FrameVals;
            ax.XTickLabel = sec_TimeVals;
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'k','LineWidth',3)
            plot(AVdata{trialType}, 'k','LineWidth',3)    
           %plot(AVdata, 'k','LineWidth',3)   
            ylim([dataMin dataMax]);
            %xlim([1 size(AVdataToPlot{cell}{z,trialType}{trial},2)]);

        end    
        if smoothQ == 1 
            title(sprintf("DA Calcium Data smoothed by %d seconds. Averaged across Z planes and vessel ROIs.",filtTime));
        elseif smoothQ == 0
            title("Raw DA Calcium Data. Averaged across Z planes and vessel ROIs.");
        end 

    end                         
end
        
 



end 