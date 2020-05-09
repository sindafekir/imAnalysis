function plotDataAndRunVelocity(dataToPlot,normAVSortedStatsArray,normSortedWheelDataArray,normAVWheelDataArray,FPS,numZplanes,sec_before_stim_start,dataMin,dataMax,velMin,velMax,maxCells,ROIinds)


FPSstack = FPS/numZplanes;

baselineEndFrame = round(sec_before_stim_start*(FPSstack));
            
for cell = 1:maxCells 
    for z = 1:size(dataToPlot{ROIinds(cell)},1)     
        figure;
        for trialType = 1:size(dataToPlot{ROIinds(cell)},2)  
            if isempty(normAVWheelDataArray{trialType}) == 0 
                ColorSet = varycolor(size(dataToPlot{ROIinds(cell)}{z,trialType},2));    
                %set time in x axis 
                if trialType == 1 || trialType == 3 
                    Frames = size(dataToPlot{2}{1,1}{1},2);
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+1);
                    %min_TimeVals = (((Frames_pre_stim_start:FPS*60:Frames_post_stim_start)/FPS)+900)/60;
                    %min_TimeVals = floor(min_TimeVals); 
                    FrameVals = round((1:FPSstack*2:Frames)-1); 
                elseif trialType == 2 || trialType == 4 
                    Frames = size(dataToPlot{2}{1,4}{1},2);
                    Frames_pre_stim_start = -((Frames-1)/2); 
                    Frames_post_stim_start = (Frames-1)/2; 
                    sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+10);
                    %min_TimeVals = (((Frames_pre_stim_start:FPS*60:Frames_post_stim_start)/FPS)+900)/60;
                    %min_TimeVals = floor(min_TimeVals); 
                    FrameVals = round((1:FPSstack*2:Frames)-1); 
                end 
                for trial = 1:size(normSortedWheelDataArray{trialType},2)  % this plots all trials  
                    hold all;              
                    subplot(2,4,trialType);          
                    plot(dataToPlot{ROIinds(cell)}{z,trialType}{trial},'Color',ColorSet(trial,:))
                    ax=gca;
                    ax.FontSize = 20;
                    hold on;
                    if trialType == 1 
                        plot([round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2))], [-5000 5000], 'k','LineWidth',2)
                        patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
                        alpha(0.03)   
                    elseif trialType == 3 
                        plot([round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2))], [-5000 5000], 'k','LineWidth',2)
                        patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
                        alpha(0.03)                       
                    elseif trialType == 2 
                        plot([round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20))], [-5000 5000], 'k','LineWidth',2)
                        patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
                        alpha(0.03)   
                    elseif trialType == 4 
                        plot([round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20))], [-5000 5000], 'k','LineWidth',2)
                        patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
                        alpha(0.03)  
                    end
                    ax.XTick = FrameVals;
                    ax.XTickLabel = sec_TimeVals;
                    plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'k','LineWidth',2)
                    plot(normAVSortedStatsArray{ROIinds(cell)}{z,trialType}, 'k')                
                    ylim([dataMin dataMax]);
                    %xlim([1 size(dataToPlot{cell}{z,trialType}{trial},2)]);
                    count = trialType+4;
                    subplot(2,4,count);
                    plot(normSortedWheelDataArray{trialType}{trial},'Color',ColorSet(trial,:))
                    ax=gca;
                    ax.FontSize = 20;                
                    hold on;
                    if trialType == 1 
                        plot([round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2))], [-5000 5000], 'k','LineWidth',2)
                        patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
                        alpha(0.03)   
                    elseif trialType == 3 
                        plot([round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2))], [-5000 5000], 'k','LineWidth',2)
                        patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
                        alpha(0.03)                       
                    elseif trialType == 2 
                        plot([round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20))], [-5000 5000], 'k','LineWidth',2)
                        patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
                        alpha(0.03)   
                    elseif trialType == 4 
                        plot([round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20))], [-5000 5000], 'k','LineWidth',2)
                        patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
                        alpha(0.03)  
                    end   
                    ax.XTick = FrameVals;
                    ax.XTickLabel = sec_TimeVals;
                    plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'k','LineWidth',2)
                    plot(normAVWheelDataArray{trialType}, 'k')
                    ylim([velMin velMax]);
                    %xlim([1 size(dataToPlot{cell}{z,trialType}{trial},2)]);
                end   
            end 
        end 
        suptitle(sprintf('Z-Plane #%d. DA Terminal #%d',z,ROIinds(cell)))
%         %cd('C:\Users\Sinda\Desktop\SF56_20190718\SF56_20190710_rawData');
%         baseFileName = sprintf('SF56_20190718_Z%d_DAterm%d.fig',z,ROIinds(cell));
%         % Specify some particular, specific folder:
%         fullFileName = fullfile('C:\Users\Sinda\Desktop\SF56_20190718\SF56_20190710_rawData', baseFileName);  
        %saveas(gcf,fullFileName);
    end 

end 
end 