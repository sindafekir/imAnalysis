function smoothAndPlotBBBData(BdataToPlot,userInput,FPS,numZplanes,sec_before_stim_start)
%% smooth data if you want 
smoothQ = input('Do you want to smooth your data? Yes = 1. No = 0. ');

if smoothQ == 1 
    UIr = size(userInput,1)+1;
    filtTime = input('How many seconds do you want to smooth your data by? '); userInput(UIr,1) = ("How many seconds do you want to smooth your data by? "); userInput(UIr,2) = (filtTime); UIr = UIr+1;
    filtData = cell(1,length(BdataToPlot));
    for Z = 1:length(BdataToPlot)
        for trialType = 1:size(BdataToPlot{Z},2)             
                if isempty(BdataToPlot{Z}{trialType}) == 0 
                    for trial = 1:size(BdataToPlot{Z}{trialType},2)
                         for VROI = 1:size(BdataToPlot{Z}{trialType}{trial},2) %working on replacing numROIs 
                            [filtD] = MovMeanSmoothData(BdataToPlot{Z}{trialType}{trial}{VROI},filtTime,FPS);
                            filtData{Z}{trialType}{trial}{VROI} = filtD;
                         end 
                    end 
                end 
        end 
    end 
elseif smoothQ == 0 
    filtData = cell(1,length(BdataToPlot));
     for Z = 1:length(BdataToPlot)
            for trialType = 1:size(BdataToPlot{Z},2)             
                    if isempty(BdataToPlot{Z}{trialType}) == 0 
                        for trial = 1:size(BdataToPlot{Z}{trialType},2)
                             for VROI = 1:size(BdataToPlot{Z}{trialType}{trial},2) %working on replacing numROIs 
                                filtData{Z}{trialType}{trial}{VROI} = BdataToPlot{Z}{trialType}{trial}{VROI};
                             end 
                        end 
                    end 
            end 
    end 
end 


%average across trials
AVarray = cell(1,length(BdataToPlot));
AVdata = cell(1,length(BdataToPlot));
for Z = 1:length(BdataToPlot)
    for trialType = 1:size(BdataToPlot{Z},2)
        if isempty(filtData{Z}{trialType}) == 0 
            for trial = 1:size(BdataToPlot{Z}{trialType},2)
                 for VROI = 1:size(BdataToPlot{Z}{trialType}{trial},2) 
                    AVarray{Z}{trialType}{VROI}(trial,:) = filtData{Z}{trialType}{trial}{VROI};
                    AVdata{Z}{trialType}{VROI} = nanmean(AVarray{Z}{trialType}{VROI},1);
                 end 
            end 
            
        end      
    end 
end 

%% plot 
dataMin = input("data Y axis MIN: ");
dataMax = input("data Y axis MAX: ");
FPSstack = FPS/numZplanes;
baselineEndFrame = round(sec_before_stim_start*(FPSstack));

for VROI = 1:size(BdataToPlot{Z}{trialType}{trial},2)
    for Z = 1:length(BdataToPlot)          
        for trialType = 1:size(BdataToPlot{Z},2)  
            if isempty(BdataToPlot{Z}{trialType}) == 0
            
            
                figure;
                ColorSet = varycolor(size(BdataToPlot{Z}{trialType},2));    
                %set time in x axis            
                if trialType == 1 || trialType == 3 
                    Frames = size(BdataToPlot{Z}{trialType}{1}{1},2);                
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+2);
                    FrameVals = round((1:FPSstack*2:Frames)-1); 
                elseif trialType == 2 || trialType == 4 
                    Frames = size(BdataToPlot{Z}{trialType}{1}{1},2);
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+10);
                    FrameVals = round((1:FPSstack*2:Frames)-1); 
                end 
                for trial = 1:size(BdataToPlot{Z}{trialType},2)  % this plots all trials  
                    hold all;                       
                    plot(filtData{Z}{trialType}{trial}{1},'Color',ColorSet(trial,:))
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
                    plot(AVdata{Z}{trialType}{VROI}, 'k','LineWidth',3)    
                   %plot(AVdata, 'k','LineWidth',3)   
                    ylim([dataMin dataMax]);
                    %xlim([1 size(BdataToPlot{cell}{z,trialType}{trial},2)]);
 
                end    
                if smoothQ == 1 
                    title(sprintf("BBB Data smoothed by %d seconds. Z plane #%d. BBB perm ROI #%d",filtTime,Z,VROI));
                elseif smoothQ == 0
                    title(sprintf("Raw BBB Data. Z plane #%d. BBB perm ROI #%d",Z,VROI));
                end 
                
            end                         
        end
        
    end 
end 


end 