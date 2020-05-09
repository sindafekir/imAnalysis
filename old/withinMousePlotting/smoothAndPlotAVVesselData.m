function smoothAndPlotAVVesselData(VdataToPlot,userInput,FPS,numZplanes,sec_before_stim_start)

%% average across ROIs and z planes 

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



% smooth data if you want 
smoothQ = input('Do you want to smooth your data? Yes = 1. No = 0. ');

if smoothQ == 1 
    UIr = size(userInput,1)+1;
    filtTime = input('How many seconds do you want to smooth your data by? '); userInput(UIr,1) = ("How many seconds do you want to smooth your data by? "); userInput(UIr,2) = (filtTime); UIr = UIr+1;
    filtData = cell(1,size(VAVdataToPlot,2));
    for trialType = 1:size(VAVdataToPlot,2)   
        if isempty(VAVdataToPlot{trialType}) == 0                  
            for trial = 1:length(VAVdataToPlot{trialType})  
                if isempty(VAVdataToPlot{trialType}{trial}) == 0    
                    [filtD] = MovMeanSmoothData(VAVdataToPlot{trialType}{trial},filtTime,FPS);
                    filtData{trialType}{trial} = filtD; 
                end 
            end 
        end 
    end

elseif smoothQ == 0 
    filtData = cell(1,size(VAVdataToPlot,2));
    for trialType = 1:size(VAVdataToPlot,2)   
        if isempty(VAVdataToPlot{trialType}) == 0                  
            for trial = 1:length(VAVdataToPlot{trialType})  
                if isempty(VAVdataToPlot{trialType}{trial}) == 0    
                    filtData{trialType}{trial} = VAVdataToPlot{trialType}{trial}; 
                end 
            end 
        end 
    end
end 

%% plot your data 
dataMin = input("data Y axis MIN: ");
dataMax = input("data Y axis MAX: ");
FPSstack = FPS/numZplanes;
baselineEndFrame = round(sec_before_stim_start*(FPSstack));

%average across trials
AVarray = cell(1,size(VAVdataToPlot,2));
AVdata = cell(1,size(VAVdataToPlot,2));
for trialType = 1:size(VAVdataToPlot,2)   
    if isempty(VAVdataToPlot{trialType}) == 0                  
        for trial = 1:length(VAVdataToPlot{trialType})  
            if isempty(VAVdataToPlot{trialType}{trial}) == 0                  
                AVarray{trialType}(trial,:) = filtData{trialType}{trial};
            end 
        end 
        AVdata{trialType} = nanmean(AVarray{trialType},1);
     end 
end 


for trialType = 1:size(VdataToPlot{1}{1},2)  
    if isempty(VdataToPlot{z}{ROI}{trialType}) == 0       
        figure;
        ColorSet = varycolor(size(filtData{trialType},2));   
        %set time in x axis            
        if trialType == 1 || trialType == 3 
            Frames = size(filtData{trialType}{1},2);                
            Frames_pre_stim_start = -((Frames-1)/2); 
            Frames_post_stim_start = (Frames-1)/2; 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+2);
            FrameVals = round((1:FPSstack*2:Frames)-1); 
        elseif trialType == 2 || trialType == 4 
            Frames = size(filtData{trialType}{1},2);
            Frames_pre_stim_start = -((Frames-1)/2); 
            Frames_post_stim_start = (Frames-1)/2; 
            sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+11);
            FrameVals = round((1:FPSstack*2:Frames)-1); 
        end 

        for trial = 1:length(VAVdataToPlot{trialType})      % this plots all trials  
            hold all;                       
            plot(filtData{trialType}{trial},'Color',ColorSet(trial,:))
            ax=gca;
            ax.FontSize = 20;

            hold on;
            if trialType == 1 
                plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'k','LineWidth',3)
                patch([baselineEndFrame round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
                alpha(0.01)   
            elseif trialType == 3 
                plot([round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2))], [-5000 5000], 'k','LineWidth',3)
                patch([baselineEndFrame round(baselineEndFrame+((FPSstack)*2)) round(baselineEndFrame+((FPSstack)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
                alpha(0.01)                       
            elseif trialType == 2 
                plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'k','LineWidth',3)
                patch([baselineEndFrame round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
                alpha(0.01)   
            elseif trialType == 4 
                plot([round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20))], [-5000 5000], 'k','LineWidth',3)
                patch([baselineEndFrame round(baselineEndFrame+((FPSstack)*20)) round(baselineEndFrame+((FPSstack)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
                alpha(0.01)  
            end
            ax.XTick = FrameVals;
            ax.XTickLabel = sec_TimeVals;
            plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'k','LineWidth',3)
            plot(AVdata{trialType}, 'k','LineWidth',3)    
           %plot(AVdata, 'k','LineWidth',3)   
            ylim([dataMin dataMax]);
            %xlim([1 size(VdataToPlot{cell}{z,trialType}{trial},2)]);

        end    
        if smoothQ == 1 
            title(sprintf("Vessel width data smoothed by %d seconds. Averaged across Z planes and vessel ROIs.",filtTime));
        elseif smoothQ == 0
            title(sprintf("Raw vessel width data. Averaged across Z planes and vessel ROIs."));
        end 

    end                         
end



end 