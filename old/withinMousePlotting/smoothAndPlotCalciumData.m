function smoothAndPlotCalciumData(dataToPlot,userInput,FPS,numZplanes,sec_before_stim_start)

%% smooth data if you want 
smoothQ = input('Do you want to smooth your data? Yes = 1. No = 0. ');

if smoothQ == 1 
    UIr = size(userInput,1)+1;
    filtTime = input('How many seconds do you want to smooth your data by? '); userInput(UIr,1) = ("How many seconds do you want to smooth your data by? "); userInput(UIr,2) = (filtTime); UIr = UIr+1;
    count = 1;
    for ccell = 1:length(dataToPlot)
        if isempty(dataToPlot{ccell}) == 0 
            for trialType = 1:size(dataToPlot{ccell},2) 
                if isempty(dataToPlot{ccell}{trialType}) == 0 
                     for z = 1:size(dataToPlot{ccell},1)
                        for trial = 1:size(dataToPlot{ccell}{z,trialType},2)
                            [filtD] = MovMeanSmoothData(dataToPlot{ccell}{z,trialType}{trial},filtTime,FPS);
                            filtData{count}{z,trialType}{trial} = filtD;
                        end 
                    end 
                end 
            end
            count = count+1;
        end 
    end 
elseif smoothQ == 0 
    count = 1;
    for ccell = 1:length(dataToPlot)
        if isempty(dataToPlot{ccell}) == 0 
            for trialType = 1:size(dataToPlot{ccell},2) 
                if isempty(dataToPlot{ccell}{trialType}) == 0 
                     for z = 1:size(dataToPlot{ccell},1)
                        for trial = 1:size(dataToPlot{ccell}{z,trialType},2)                           
                            filtData{count}{z,trialType}{trial} = dataToPlot{ccell}{z,trialType}{trial};
                        end 
                    end 
                end 
            end
            count = count+1;
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
for count = 1:length(filtData)
    for trialType = 1:size(filtData{count},2) 
        if isempty(filtData{count}{trialType}) == 0 
             for z = 1:size(filtData{count},1)
                for trial = 1:size(filtData{count}{z,trialType},2)
                    if isempty(filtData{count}{z,trialType}{trial}) == 0 
                        AVarray{count}{z,trialType}(trial,:) = filtData{count}{z,trialType}{trial};
                    end 
                end 
                AVdata{count}{z,trialType} = nanmean(AVarray{count}{z,trialType},1);
             end 
        end 
    end 
end 
             
for count = 1:length(filtData)
    for trialType = 1:size(filtData{count},2) 
        if isempty(filtData{count}{trialType}) == 0 
             for z = 1:size(filtData{count},1)
                figure;
                ColorSet = varycolor(size(filtData{count}{z,trialType},2));   
                %set time in x axis            
                if trialType == 1 || trialType == 3 
                    Frames = size(filtData{count}{z,trialType}{1},2);                
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+2);
                    FrameVals = round((1:FPSstack*2:Frames)-1); 
                elseif trialType == 2 || trialType == 4 
                    Frames = size(filtData{count}{z,trialType}{1},2);
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+10);
                    FrameVals = round((1:FPSstack*2:Frames)-1); 
                end 
                
                for trial = 1:size(filtData{count}{z,trialType},2)  % this plots all trials  
                    hold all;                       
                    plot(filtData{count}{z,trialType}{trial},'Color',ColorSet(trial,:))
                    ax=gca;
                    ax.FontSize = 20;

                    hold on;
                    if trialType == 1 
                        plot([round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2))], [-5000 5000], 'k','LineWidth',3)
                        patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
                        alpha(0.03)   
                    elseif trialType == 3 
                        plot([round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2))], [-5000 5000], 'k','LineWidth',3)
                        patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
                        alpha(0.03)                       
                    elseif trialType == 2 
                        plot([round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20))], [-5000 5000], 'k','LineWidth',3)
                        patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
                        alpha(0.03)   
                    elseif trialType == 4 
                        plot([round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20))], [-5000 5000], 'k','LineWidth',3)
                        patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
                        alpha(0.03)  
                    end
                    ax.XTick = FrameVals;
                    ax.XTickLabel = sec_TimeVals;
                    plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'k','LineWidth',3)
                    plot(AVdata{count}{z,trialType}, 'k','LineWidth',3)    
                   %plot(AVdata, 'k','LineWidth',3)   
                    ylim([dataMin dataMax]);
                    %xlim([1 size(dataToPlot{cell}{z,trialType}{trial},2)]);
 
                end    
                if smoothQ == 1 
                    title(sprintf("Data smoothed by %d seconds. Z plane #%d. DA Ca ROI #%d",filtTime,z,count));
                elseif smoothQ == 0
                    title(sprintf("Raw data. Z plane #%d. DA Ca ROI #%d",z,count));
                end 
                
            end                         
        end
        
    end 
end 
end 