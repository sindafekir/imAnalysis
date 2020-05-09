function smoothAndPlotVesselData(VdataToPlot,userInput,FPS,numZplanes,sec_before_stim_start)

%% smooth data if you want 
smoothQ = input('Do you want to smooth your data? Yes = 1. No = 0. ');

if smoothQ == 1 
    UIr = size(userInput,1)+1;
    filtTime = input('How many seconds do you want to smooth your data by? '); userInput(UIr,1) = ("How many seconds do you want to smooth your data by? "); userInput(UIr,2) = (filtTime); UIr = UIr+1;
    filtData = cell(1,length(VdataToPlot));
    for z = 1:length(VdataToPlot)
        for ROI = 1:size(VdataToPlot{z},2)
            for trialType = 1:size(VdataToPlot{z}{1},2)   
                if isempty(VdataToPlot{z}{ROI}{trialType}) == 0                  
                    for trial = 1:length(VdataToPlot{z}{ROI}{trialType})                         
                        [filtD] = MovMeanSmoothData(VdataToPlot{z}{ROI}{trialType}{trial},filtTime,FPS);
                        filtData{z}{ROI}{trialType}{trial} = filtD;                        
                    end 
                end 
            end
        end 
    end 
elseif smoothQ == 0 
    filtData = cell(1,length(VdataToPlot));
    for z = 1:length(VdataToPlot)
        for ROI = 1:size(VdataToPlot{1},2)
            for trialType = 1:size(VdataToPlot{1}{1},2)   
                if isempty(VdataToPlot{z}{ROI}{trialType}) == 0                  
                    for trial = 1:length(VdataToPlot{z}{ROI}{trialType})                         
                        filtData{z}{ROI}{trialType}{trial} = VdataToPlot{z}{ROI}{trialType}{trial};                        
                    end 
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
AVarray = cell(1,length(filtData));
AVdata = cell(1,length(filtData));

for z = 1:length(VdataToPlot)
    for ROI = 1:size(VdataToPlot{1},2)
        for trialType = 1:size(VdataToPlot{1}{1},2)   
            if isempty(VdataToPlot{z}{ROI}{trialType}) == 0                  
                for trial = 1:length(VdataToPlot{z}{ROI}{trialType})    
                    if isempty(VdataToPlot{z}{ROI}{trialType}{trial}) == 0    
                        AVarray{z}{ROI}{trialType}(trial,:) = filtData{z}{ROI}{trialType}{trial};
                    end 
                end 
                AVdata{z}{ROI}{trialType} = nanmean(AVarray{z}{ROI}{trialType},1);
             end 
        end 
    end 
end 

for z = 1:length(VdataToPlot)
    for ROI = 1:size(VdataToPlot{1},2)
        for trialType = 1:size(VdataToPlot{1}{1},2)  
            if isempty(VdataToPlot{z}{ROI}{trialType}) == 0       
                figure;
                ColorSet = varycolor(size(filtData{z}{ROI}{trialType},2));   
                %set time in x axis            
                if trialType == 1 || trialType == 3 
                    Frames = size(filtData{z}{ROI}{trialType}{2},2);                
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+1);
                    FrameVals = round((1:FPSstack*2:Frames)-1); 
                elseif trialType == 2 || trialType == 4 
                    Frames = size(filtData{z}{ROI}{trialType}{2},2);
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+10);
                    FrameVals = round((1:FPSstack*2:Frames)-1); 
                end 
                
                ax=gca;
                ax.FontSize = 20;
                ax.XTick = FrameVals;
                ax.XTickLabel = sec_TimeVals;
  
                %plot(AVdata, 'k','LineWidth',3)   
                ylim([dataMin dataMax]);
                %xlim([1 size(VdataToPlot{cell}{z,trialType}{trial},2)]);
                    
                
                for trial = 1:length(VdataToPlot{z}{ROI}{trialType})      % this plots all trials  
                    hold all;                       
                    plot(filtData{z}{ROI}{trialType}{trial},'Color',ColorSet(trial,:))


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
                end 

                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'k','LineWidth',3)
                plot(AVdata{z}{ROI}{trialType}, 'k','LineWidth',3)  
                   
                if smoothQ == 1 
                    title(sprintf("Data smoothed by %d seconds. Z plane #%d. Vessel Width ROI #%d",filtTime,z,ROI));
                elseif smoothQ == 0
                    title(sprintf("Raw data. Z plane #%d. Vessel Width ROI #%d",z,ROI));
                end                 
            end                         
        end        
    end 
end 

end 