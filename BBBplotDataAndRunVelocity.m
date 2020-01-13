function BBBplotDataAndRunVelocity(dataToPlot,FPS,numZplanes,sec_before_stim_start,dataMin,dataMax,numROIs,ROIstacks,filtTime)


FPSstack = FPS/numZplanes;

baselineEndFrame = round(sec_before_stim_start*(FPSstack));

%average across trials
AVarray = cell(1,length(dataToPlot));
AVdata = cell(1,length(dataToPlot));
for Z = 1:length(dataToPlot)
    for trialType = 1:size(dataToPlot{Z},2)
        for VROI = 1:numROIs 
            if isempty(dataToPlot{Z}{trialType}) == 0 
                for trial = 1:size(dataToPlot{Z}{trialType},2)
                    AVarray{Z}{trialType}{VROI}(trial,:) = dataToPlot{Z}{trialType}{trial}{VROI};
                end 
                AVdata{Z}{trialType}{VROI} = nanmean(AVarray{Z}{trialType}{VROI},1);
            end 
        end 
    end 
end 

for VROI = 1:numROIs 
    for Z = 1:length(ROIstacks)          
        for trialType = 1:size(dataToPlot{Z},2)  
            if isempty(dataToPlot{Z}{trialType}) == 0
            
            
                figure;
                ColorSet = varycolor(size(dataToPlot{Z}{trialType},2));    
                %set time in x axis            
                if trialType == 1 || trialType == 3 
                    Frames = size(dataToPlot{Z}{trialType}{1}{1},2);                
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+1);
                    FrameVals = round((1:FPSstack*2:Frames)-1); 
                elseif trialType == 2 || trialType == 4 
                    Frames = size(dataToPlot{Z}{trialType}{1}{1},2);
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+10);
                    FrameVals = round((1:FPSstack*2:Frames)-1); 
                end 
                for trial = 1:size(dataToPlot{Z}{trialType},2)  % this plots all trials  
                    hold all;                       
                    plot(dataToPlot{Z}{trialType}{trial}{1},'Color',ColorSet(trial,:))
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
                    plot(AVdata{Z}{trialType}{VROI}, 'k','LineWidth',3)    
                   %plot(AVdata, 'k','LineWidth',3)   
                    ylim([dataMin dataMax]);
                    %xlim([1 size(dataToPlot{cell}{z,trialType}{trial},2)]);
 
                end    
                title(sprintf("Data smoothed by %d seconds. Z plane #%d. BBB perm ROI #%d",filtTime,Z,VROI));
            end                         
        end
        
    end 
end 


end 