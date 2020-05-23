function plotAllAVDataAndRunVelocity(VdataToPlot,VAVsortedData,allAVarray,allAV,wheelDataToPlot,AVwheelData,FPS,numZplanes,sec_before_stim_start,dataMin,dataMax,velMin,velMax,maxCells,ROIinds)

        
SEMallAV = nanstd(allAVarray,0,1);     
SEMallAVred = nanstd(cellAllAvAVred,0,3);   
SEMallAVblue = nanstd(cellAllAvAVblue,0,3); 

SEMallAVredW = nanstd(redW,0,1);   
SEMallAVblueW = nanstd(blueW,0,1); 
SEMallW = nanstd(AllW,0,1);

SEMallVAV = nanstd(VDataArray,0,3);     
SEMallVAVred = nanstd(redV,0,1);   
SEMallVAVblue = nanstd(blueV,0,1); 

% for z = 1:length(VdataToPlot)
%     for ROI = 1:size(VdataToPlot{1},2)
%         for trialType = 1:length(uniqueTrialDataTemplate)    
%             reshapedArray = cat(3,VdataToPlot{z}{ROI}{trialType}{:});            
%             stdVData = nanstd(reshapedArray,0,3);            
%             SEMVdata{z}{ROI}{trialType} = stdVData/(sqrt(size(VdataToPlot{1}{1}{trialType},2))); %SEM = std(data)/squrt(n)
%         end 
%     end 
% end 
% 
% for trialType = 1:size(wheelDataToPlot,2) 
%     reshapedArray = cat(3,wheelDataToPlot{trialType}{:});            
%     stdData = std(reshapedArray,0,3);            
%     SEMWdata{1,trialType} = stdData/(sqrt(size(wheelDataToPlot{1,trialType},2))); %SEM = std(data)/squrt(n)
% end 

FPSstack = FPS/numZplanes;

baselineEndFrame = round(sec_before_stim_start*(FPSstack));
            
for cell = 1
    for z = 1
        figure;
        for trialType = 1 
            %set time in x axis 
            if trialType == 1 || trialType == 3 
%                 Frames = size(dataToPlot{2}{1,1}{1},2);
                Frames = size(allAV,2);
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
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+11);
                %min_TimeVals = (((Frames_pre_stim_start:FPS*60:Frames_post_stim_start)/FPS)+900)/60;
                %min_TimeVals = floor(min_TimeVals); 
                FrameVals = round((1:FPSstack*2:Frames)-1); 
            end 
             

            %subplot(1,4,trialType);  
            hold all; 
            ax=gca;
            if trialType == 1
 %                 varargout = boundedline(1:size(allAV,2),allAV,SEMallAV,'b','transparency', 0.5);      
%                 varargout = boundedline(1:size(AVallW,2),AVallW,SEMallW,'k','transparency', 0.5);  
%                 varargout = boundedline(1:size(allVAV,2),allVAV,SEMallVAV,'r','transparency', 0.5);  
                    %hold all;plot(smoothed_5_BlueVAV,'r'); plot(smoothed_5_BlueAV,'b'); plot(smoothed_5_BlueWAV,'k');
                    hold all;plot(smoothed_5_RedVAV,'r'); plot(smoothed_5_RedAV,'b'); plot(smoothed_5_RedWAV,'k');
% 
%                  varargout = boundedline(1:size(redAV,2),redAV,SEMallAVred,'b','transparency', 0.5);      
%                 %varargout = boundedline(1:size(AVredW,2),AVredW,SEMallAVredW,'k','transparency', 0.5);
%                 varargout = boundedline(1:size(redVAV,2),redVAV,SEMallVAVred,'r','transparency', 0.5); 

%                  varargout = boundedline(1:size(ALLBLUE,2),ALLBLUE,SEMallAVblue,'b','transparency', 0.5);      
%                 varargout = boundedline(1:size(AVblueW,2),AVblueW,SEMallAVblueW,'k','transparency', 0.5);
%                 varargout = boundedline(1:size(blueVAV,2),blueVAV,SEMallVAVblue,'r','transparency', 0.5);
                
            end 
            ax.FontSize = 20;
            %hold on;
            %varargout = boundedline(1:size(AVwheelData{trialType},2),AVwheelData{trialType},SEMWdata{trialType},'k','transparency', 0.5); 
            %varargout = boundedline(1:size(VAVsortedData{z}{1}{trialType},2),VAVsortedData{z}{1}{trialType},SEMVdata{z}{1}{trialType},'r','transparency', 0.5); 
            %varargout = boundedline(1:size(VAVsortedData{z}{2}{trialType},2),VAVsortedData{z}{2}{trialType},SEMVdata{z}{2}{trialType},'m','transparency', 0.5); 
            alpha(0.4)
            
            if trialType == 1 
                plot([round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2))], [-5000 5000], 'r','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
%                 alpha(0.5)   
            elseif trialType == 3 
                plot([round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2))], [-5000 5000], 'r','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*2)) round(baselineEndFrame+((FPS/numZplanes)*2)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
%                 alpha(0.5)                       
            elseif trialType == 2 
                plot([round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20))], [-5000 5000], 'b','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'b','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'b')
%                 alpha(0.5)   
            elseif trialType == 4 
                plot([round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20))], [-5000 5000], 'r','LineWidth',2)
                plot([baselineEndFrame baselineEndFrame], [-5000 5000], 'r','LineWidth',2) 
%                 patch([baselineEndFrame round(baselineEndFrame+((FPS/numZplanes)*20)) round(baselineEndFrame+((FPS/numZplanes)*20)) baselineEndFrame],[-5000 -5000 5000 5000],'r')
%                 alpha(0.5)  
            end
            ax.XTick = FrameVals;
            ax.XTickLabel = sec_TimeVals;              
            ylim([dataMin dataMax]);
            %xlim([1 size(dataToPlot{cell}{z,trialType}{trial},2)]);
            
        end 
        %suptitle(sprintf('Z-Plane #%d. DA Terminal #%d',z,ROIinds(cell)))
        %cd('C:\Users\Sinda\Desktop\SF56_20190718\SF56_20190710_rawData');
        %baseFileName = sprintf('SF56_20190718_Z%d_DAterm%d.fig',z,ROIinds(cell));
        % Specify some particular, specific folder:
        %fullFileName = fullfile('C:\Users\Sinda\Desktop\SF56_20190718\SF56_20190710_rawData', baseFileName);  
        %saveas(gcf,fullFileName);
        
    end
end 

end 