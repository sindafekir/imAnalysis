function plotDataAndRunVelocity(dataToPlot,normAVSortedStatsArray,normSortedWheelDataArray,normAVWheelDataArray,FPS,numZplanes,sec_before_stim_start,dataMin,dataMax,velMin,velMax,maxCells,ROIinds)


FPSstack = FPS/numZplanes;

baselineEndFrame = round(sec_before_stim_start*(FPSstack));
            
for cell = 1:maxCells 
    for z = 1:size(dataToPlot{ROIinds(cell)},1)     
        figure;
        for trialType = 1:size(dataToPlot{ROIinds(cell)},2)  
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
                Frames = size(dataToPlot{2}{1,2}{1},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+10);
                %min_TimeVals = (((Frames_pre_stim_start:FPS*60:Frames_post_stim_start)/FPS)+900)/60;
                %min_TimeVals = floor(min_TimeVals); 
                FrameVals = round((1:FPSstack*2:Frames)-1); 
            end 
            for trial = 1:size(dataToPlot{ROIinds(cell)}{z,trialType},2)  % this plots all trials  
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
        suptitle(sprintf('Z-Plane #%d. DA Terminal #%d',z,ROIinds(cell)))
        %cd('C:\Users\Sinda\Desktop\SF56_20190718\SF56_20190710_rawData');
        baseFileName = sprintf('SF56_20190718_Z%d_DAterm%d.fig',z,ROIinds(cell));
        % Specify some particular, specific folder:
        fullFileName = fullfile('C:\Users\Sinda\Desktop\SF56_20190718\SF56_20190710_rawData', baseFileName);  
        %saveas(gcf,fullFileName);
    end 

end 

% USE BELOW CODE TO CREATE RED OR BLUE PATCH OVER PLOTS WHEN READY 


% 
% for Ttype = 1:length(unique(TrialTypes(:,2)))
%     
%     for ROI = 1:size(dataToPlot{1},1)
%         for x = 1:size(dataToPlot{Ttype},3)  % this plots all trials  
%             hold all;
%             subplot(2,1,1)
%             plot(dataToPlot{Ttype,1}(ROI,:,x))
%         end
%         plot(avData{ROI,1},'k','LineWidth',2)
%         ax=gca;
%         ax.FontSize = 20;
%         baselineEndFrame = round(sec_before_stim_start*FPS);
%         plot([baselineEndFrame baselineEndFrame], [-2 2], 'k')
%         plot([round(baselineEndFrame+(FPS*stimOnTime)) round(baselineEndFrame+(FPS*stimOnTime))], [-2 2], 'k')
%         if Ttype == 1 && numVROIs > 0
%             title({sprintf('Change in Vessel %d Dilation and Mouse Running Velocity',ROI); '(Primary Somatosensory Cortex - Red Light)'},'Fontsize',22);
%         elseif Ttype == 2 && numVROIs > 0
%             title({sprintf('Change in Vessel %d Dilation and Mouse Running Velocity',ROI); '(Primary Somatosensory Cortex - Blue Light)'},'Fontsize',22);
%         end 
%         if Ttype == 1 && numVROIs == 0 
%             title({sprintf('Change in ROI %d Pixel Intensity and Mouse Running Velocity',ROI); '(Primary Somatosensory Cortex - Red Light)'},'Fontsize',22);
%         elseif Ttype == 2 && numVROIs == 0 
%             title({sprintf('Change in ROI %d Pixel Intensity and Mouse Running Velocity',ROI); '(Primary Somatosensory Cortex - Blue Light)'},'Fontsize',22);
%         end             
%         ax.XTick = FrameVals;
%         ax.XTickLabel = sec_TimeVals;
%         ylabel({'normalized change in';'vessel diamater'},'Fontsize',20);
%         xlabel('time (sec)','Fontsize',20); 
%         xlim([1 size(dataToPlot{Ttype},2)]);
%         ylim([ylimMin ylimMax]);
% 
%         for y = 1:size(dataToPlot{Ttype},3)  % this plots all ROIs 
%             hold all;
%             subplot(2,1,2)
%             plot(dataToPlot{Ttype,2}(1,:,y))
%         end
%         ax=gca;
%         ax.FontSize = 20;
%         xlim([1 size(dataToPlot{Ttype},2)]);
%         ylim([ylimMinVel ylimMaxVel]);
%         ax.XTick = FrameVals;
%         ax.XTickLabel = sec_TimeVals;
%         plot([baselineEndFrame baselineEndFrame], [-1000 1000], 'k')
%         plot([round(baselineEndFrame+(FPS*stimOnTime)) round(baselineEndFrame+(FPS*stimOnTime))], [-1000 1000], 'k')
%         xlabel('time (sec)','Fontsize',20); 
%         ylabel({'running velocity'},'Fontsize',20);
%         if ROI < size(dataToPlot{1},1)
%             figure;
%         end 
%     end 
%     
%     if Ttype < length(unique(TrialTypes(:,2)))
%         figure;
%     end 
%     
% end 

end 