function plot_BBB_VW_CA_avs(BdataToPlot,CdataToPlot,VdataToPlot,userInput,FPS,numZplanes,sec_before_stim_start)
%% smooth data if you want 
smoothQ = input('Do you want to smooth your data? Yes = 1. No = 0. ');

if smoothQ == 1 
    UIr = size(userInput,1)+1;
    filtTime = input('How many seconds do you want to smooth your data by? '); userInput(UIr,1) = ("How many seconds do you want to smooth your data by? "); userInput(UIr,2) = (filtTime); UIr = UIr+1;
    
    BfiltData = cell(1,length(BdataToPlot));
    for Z = 1:length(BdataToPlot)
        for trialType = 1:size(BdataToPlot{Z},2)             
                if isempty(BdataToPlot{Z}{trialType}) == 0 
                    for trial = 1:size(BdataToPlot{Z}{trialType},2)
                         for VROI = 1:size(BdataToPlot{Z}{trialType}{trial},2) %working on replacing numROIs 
                            [BfiltD] = MovMeanSmoothData(BdataToPlot{Z}{trialType}{trial}{VROI},filtTime,FPS);
                            BfiltData{Z}{trialType}{trial}{VROI} = BfiltD;
                         end 
                    end 
                end 
        end 
    end 
    
%     count = 1;
%     for ccell = 1:length(CdataToPlot)
%         if isempty(CdataToPlot{ccell}) == 0 
%             for trialType = 1:size(CdataToPlot{ccell},2) 
%                 if isempty(CdataToPlot{ccell}{trialType}) == 0 
%                      for z = 1:size(CdataToPlot{ccell},1)
%                         for trial = 1:size(CdataToPlot{ccell}{z,trialType},2)
%                             [CfiltD] = MovMeanSmoothData(CdataToPlot{ccell}{z,trialType}{trial},filtTime,FPS);
%                             CfiltData{count}{z,trialType}{trial} = CfiltD;
%                         end 
%                     end 
%                 end 
%             end
%             count = count+1;
%         end 
%     end 
    
    VfiltData = cell(1,length(VdataToPlot));
    for z = 1:length(VdataToPlot)
        for ROI = 1:size(VdataToPlot{1},2)
            for trialType = 1:size(VdataToPlot{1}{1},2)   
                if isempty(VdataToPlot{z}{ROI}{trialType}) == 0                  
                    for trial = 1:length(VdataToPlot{z}{ROI}{trialType})                         
                        [VfiltD] = MovMeanSmoothData(VdataToPlot{z}{ROI}{trialType}{trial},filtTime,FPS);
                        VfiltData{z}{ROI}{trialType}{trial} = VfiltD;                        
                    end 
                end 
            end
        end 
    end     
    
elseif smoothQ == 0 
    BfiltData = cell(1,length(BdataToPlot));
     for Z = 1:length(BdataToPlot)
            for trialType = 1:size(BdataToPlot{Z},2)             
                    if isempty(BdataToPlot{Z}{trialType}) == 0 
                        for trial = 1:size(BdataToPlot{Z}{trialType},2)
                             for VROI = 1:size(BdataToPlot{Z}{trialType}{trial},2) %working on replacing numROIs 
                                BfiltData{Z}{trialType}{trial}{VROI} = BdataToPlot{Z}{trialType}{trial}{VROI};
                             end 
                        end 
                    end 
            end 
     end 
    
%     count = 1;
%     for ccell = 1:length(CdataToPlot)
%         if isempty(CdataToPlot{ccell}) == 0 
%             for trialType = 1:size(CdataToPlot{ccell},2) 
%                 if isempty(CdataToPlot{ccell}{trialType}) == 0 
%                      for z = 1:size(CdataToPlot{ccell},1)
%                         for trial = 1:size(CdataToPlot{ccell}{z,trialType},2)                           
%                             CfiltData{count}{z,trialType}{trial} = CdataToPlot{ccell}{z,trialType}{trial};
%                         end 
%                     end 
%                 end 
%             end
%             count = count+1;
%         end 
%     end 
%     
    VfiltData = cell(1,length(VdataToPlot));
    for z = 1:length(VdataToPlot)
        for ROI = 1:size(VdataToPlot{1},2)
            for trialType = 1:size(VdataToPlot{1}{1},2)   
                if isempty(VdataToPlot{z}{ROI}{trialType}) == 0                  
                    for trial = 1:length(VdataToPlot{z}{ROI}{trialType})                         
                        VfiltData{z}{ROI}{trialType}{trial} = VdataToPlot{z}{ROI}{trialType}{trial};                        
                    end 
                end 
            end
        end 
    end     
    
end 


%average across trials
BAVarray = cell(1,length(BdataToPlot));
BAVdata = cell(1,length(BdataToPlot));
for Z = 1:length(BdataToPlot)
    for trialType = 1:size(BdataToPlot{Z},2)
        if isempty(BdataToPlot{Z}{trialType}) == 0 
            for trial = 1:size(BdataToPlot{Z}{trialType},2)
                 for VROI = 1:size(BdataToPlot{Z}{trialType}{trial},2) 
                    BAVarray{Z}{trialType}{VROI}(trial,:) = BfiltData{Z}{trialType}{trial}{VROI};
                 end 
            end 
            BAVdata{Z}{trialType}{VROI} = nanmean(BAVarray{Z}{trialType}{VROI},1);
            BSEMdata{Z}{trialType}{VROI} = (nanstd(BAVarray{Z}{trialType}{VROI},1))/(sqrt(size(BfiltData{Z}{trialType}{VROI},2)));
        end      
    end 
end 
% 
% CAVarray = cell(1,length(CfiltData));
% CAVdata = cell(1,length(CfiltData));
% CSEMdata = cell(1,length(CfiltData));
% for count = 1:length(CfiltData)
%     for trialType = 1:size(CfiltData{count},2) 
%         if isempty(CfiltData{count}{trialType}) == 0 
%              for z = 1:size(CfiltData{count},1)
%                 for trial = 1:size(CfiltData{count}{z,trialType},2)
%                     CAVarray{count}{z,trialType}(trial,:) = CfiltData{count}{z,trialType}{trial};
%                 end 
%                 CAVdata{count}{z,trialType} = nanmean(CAVarray{count}{z,trialType},1);
%                 CSEMdata{count}{z,trialType} = (nanstd(CAVarray{count}{z,trialType},1))/(sqrt(size(CfiltData{count}{z,trialType},2)));
%              end 
%         end 
%     end 
% end 

VAVarray = cell(1,length(VfiltData));
VAVdata = cell(1,length(VfiltData));
VSEMdata = cell(1,length(VfiltData));
for z = 1:length(VdataToPlot)
    for ROI = 1:size(VdataToPlot{1},2)
        for trialType = 1:size(VdataToPlot{1}{1},2)   
            if isempty(VdataToPlot{z}{ROI}{trialType}) == 0                  
                for trial = 1:length(VdataToPlot{z}{ROI}{trialType})    
                    if isempty(VdataToPlot{z}{ROI}{trialType}{trial}) == 0 
                        VAVarray{z}{ROI}{trialType}(trial,:) = VfiltData{z}{ROI}{trialType}{trial};
                    end 
                end 
                VAVdata{z}{ROI}{trialType} = nanmean(VAVarray{z}{ROI}{trialType},1);
                VSEMdata{z}{ROI}{trialType} = (nanstd(VAVarray{z}{ROI}{trialType},1))/(sqrt(size(BdataToPlot{Z}{trialType},2)));
             end 
        end 
    end 
end 



%% plot 
% dataMin = input("data Y axis MIN: ");
% dataMax = input("data Y axis MAX: ");
FPSstack = FPS/numZplanes;
baselineEndFrame = round(sec_before_stim_start*(FPSstack));

%for count = length(CfiltData)
    for VROI = 1:size(BAVdata{Z}{trialType},2) 
        for Z = 1:length(BdataToPlot)          
            for trialType = 1:size(BdataToPlot{Z},2)  
                if isempty(BdataToPlot{Z}{trialType}) == 0

                    figure;
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
                    ax=gca;
                    plot(BAVdata{Z}{trialType}{VROI},'r')
                    hold all;     
                    
                   % plot(CAVdata{count}{z,trialType},'b')
                    plot(VAVdata{z}{ROI}{trialType},'k')
                    
                    varargout = boundedline(1:size(BAVdata{Z}{trialType}{VROI},2),BAVdata{Z}{trialType}{VROI},BSEMdata{Z}{trialType}{VROI},'r','transparency', 0.3,'alpha');                                                                             
%                     varargout = boundedline(1:size(CAVdata{count}{z,trialType},2),CAVdata{count}{z,trialType},CSEMdata{count}{z,trialType},'b','transparency', 0.3,'alpha');                                           
                    varargout = boundedline(1:size(VAVdata{z}{ROI}{trialType},2),VAVdata{z}{ROI}{trialType},VSEMdata{z}{ROI}{trialType},'k','transparency', 0.3,'alpha');                        
                    
                    
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

                    
%                     legend('BBB data','DA Calcium','Vessel Width')
                    legend('BBB data','Vessel Width')
                    ylim([dataMin dataMax]);
                   

%                     if smoothQ == 1 
%                         title(sprintf('Data smoothed by %d seconds. Z plane #%d. BBB perm ROI #%d. DA Ca ROI #%d. Vessel Width ROI #%d',filtTime,Z,VROI,count,ROI));
%                     elseif smoothQ == 0
%                         title(sprintf("Raw BBB Data. Z plane #%d. BBB perm ROI #%d. DA Ca ROI #%d. Vessel Width ROI #%d",Z,VROI,count,ROI));
%                     end 
                    if smoothQ == 1 
                        title(sprintf('Data smoothed by %d seconds. Z plane #%d. BBB perm ROI #%d. Vessel Width ROI #%d',filtTime,Z,VROI,ROI));
                    elseif smoothQ == 0
                        title(sprintf("Raw BBB Data. Z plane #%d. BBB perm ROI #%d. Vessel Width ROI #%d",Z,VROI,ROI));
                    end 

                end                       
            end

        end 
    end 
%end 


end 