function plot_BBB_VW_CA_avs_AVGDacrossROIandZ(BAVdataToPlot,CAVdataToPlot,VAVdataToPlot,userInput,FPS,numZplanes,sec_before_stim_start)
%% smooth data if you want 
smoothQ = input('Do you want to smooth your data? Yes = 1. No = 0. ');

if smoothQ == 1 
    UIr = size(userInput,1)+1;
    filtTime = input('How many seconds do you want to smooth your data by? '); userInput(UIr,1) = ("How many seconds do you want to smooth your data by? "); userInput(UIr,2) = (filtTime); UIr = UIr+1;
    
    BfiltData = cell(1,size(BAVdataToPlot,2));
    for trialType = 1:size(BAVdataToPlot,2)             
        if isempty(BAVdataToPlot{trialType}) == 0 
            for trial = 1:size(BAVdataToPlot{trialType},2)
                [BfiltD] = MovMeanSmoothData(BAVdataToPlot{trialType}{trial},filtTime,FPS);
                BfiltData{trialType}{trial} = BfiltD;
            end 
        end 
    end 

    
%     count = 1;
%     for ccell = 1:length(CAVdataToPlot)
%         if isempty(CAVdataToPlot{ccell}) == 0 
%             for trialType = 1:size(CAVdataToPlot{ccell},2) 
%                 if isempty(CAVdataToPlot{ccell}{trialType}) == 0 
%                      for z = 1:size(CAVdataToPlot{ccell},1)
%                         for trial = 1:size(CAVdataToPlot{ccell}{z,trialType},2)
%                             [CfiltD] = MovMeanSmoothData(CAVdataToPlot{ccell}{z,trialType}{trial},filtTime,FPS);
%                             CfiltData{count}{z,trialType}{trial} = CfiltD;
%                         end 
%                     end 
%                 end 
%             end
%             count = count+1;
%         end 
%     end 
    
    VfiltData = cell(1,size(VAVdataToPlot,2));
    for trialType = 1:size(VAVdataToPlot,2)   
        if isempty(VAVdataToPlot{trialType}) == 0                  
            for trial = 1:length(VAVdataToPlot{trialType})                         
                [VfiltD] = MovMeanSmoothData(VAVdataToPlot{trialType}{trial},filtTime,FPS);
                VfiltData{trialType}{trial} = VfiltD;                        
            end 
        end 
    end
     
    
elseif smoothQ == 0 
    BfiltData = cell(1,size(BAVdataToPlot,2));
    for trialType = 1:size(BAVdataToPlot,2)             
        if isempty(BAVdataToPlot{trialType}) == 0 
            for trial = 1:size(BAVdataToPlot{trialType},2)
                BfiltData{trialType}{trial} = BAVdataToPlot{trialType}{trial};
            end 
        end 
    end 
    
%     count = 1;
%     for ccell = 1:length(CAVdataToPlot)
%         if isempty(CAVdataToPlot{ccell}) == 0 
%             for trialType = 1:size(CAVdataToPlot{ccell},2) 
%                 if isempty(CAVdataToPlot{ccell}{trialType}) == 0 
%                      for z = 1:size(CAVdataToPlot{ccell},1)
%                         for trial = 1:size(CAVdataToPlot{ccell}{z,trialType},2)                           
%                             CfiltData{count}{z,trialType}{trial} = CAVdataToPlot{ccell}{z,trialType}{trial};
%                         end 
%                     end 
%                 end 
%             end
%             count = count+1;
%         end 
%     end 
%     
    VfiltData = cell(1,size(VAVdataToPlot,2));
    for trialType = 1:size(VAVdataToPlot,2)   
        if isempty(VAVdataToPlot{trialType}) == 0                  
            for trial = 1:length(VAVdataToPlot{trialType})    
                VfiltData{trialType}{trial} = VAVdataToPlot{trialType}{trial};                        
            end 
        end 
    end
    
end 

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@PICK UP HERE TEST ABOVE AND THEN EDIT
%BELOW - REMOVING Z AND ROI ITERATIONS 

%average across trials
BAVarray = cell(1,size(BAVdataToPlot,2));
BAVdata = cell(1,size(BAVdataToPlot,2));
BSEMdata = cell(1,size(BAVdataToPlot,2));
for trialType = 1:size(BAVdataToPlot,2)
    if isempty(BAVdataToPlot{trialType}) == 0 
        for trial = 1:size(BAVdataToPlot{trialType},2)
            BAVarray{trialType}(trial,:) = BfiltData{trialType}{trial};
        end 
        BAVdata{trialType}= nanmean(BAVarray{trialType},1);
        BSEMdata{trialType} = (nanstd(BAVarray{trialType},1))/(sqrt(size(BfiltData{trialType},2)));
    end      
end 


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

VAVarray = cell(1,size(VAVdataToPlot,2) );
VAVdata = cell(1,size(VAVdataToPlot,2) );
VSEMdata = cell(1,size(VAVdataToPlot,2) );
for trialType = 1:size(VAVdataToPlot,2)   
    if isempty(VAVdataToPlot{trialType}) == 0                  
        for trial = 1:length(VAVdataToPlot{trialType})    
            if isempty(VAVdataToPlot{trialType}{trial}) == 0 
                VAVarray{trialType}(trial,:) = VfiltData{trialType}{trial};
            end 
        end 
        VAVdata{trialType} = nanmean(VAVarray{trialType},1);
        VSEMdata{trialType} = (nanstd(VAVarray{trialType},1))/(sqrt(size(BAVdataToPlot{trialType},2)));
     end 
end 




%% plot 
dataMin = input("data Y axis MIN: ");
dataMax = input("data Y axis MAX: ");
FPSstack = FPS/numZplanes;
baselineEndFrame = round(sec_before_stim_start*(FPSstack));

%for count = length(CfiltData)
    for trialType = 1:size(BAVdataToPlot,2)  
        if isempty(BAVdataToPlot{trialType}) == 0

            figure;
            %set time in x axis            
            if trialType == 1 || trialType == 3 
                Frames = size(BAVdataToPlot{trialType}{1},2);                
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+1);
                FrameVals = round((1:FPSstack*2:Frames)-1); 
            elseif trialType == 2 || trialType == 4 
                Frames = size(BAVdataToPlot{trialType}{1},2);
                Frames_pre_stim_start = -((Frames-1)/2); 
                Frames_post_stim_start = (Frames-1)/2; 
                sec_TimeVals = floor(((Frames_pre_stim_start:FPSstack*2:Frames_post_stim_start)/FPSstack)+10);
                FrameVals = round((1:FPSstack*2:Frames)-1); 
            end 
            ax=gca;
            plot(BAVdata{trialType},'r')
            hold all;     
           % plot(CAVdata{count}{z,trialType},'b')
            plot(VAVdata{trialType},'k')

            varargout = boundedline(1:size(BAVdata{trialType},2),BAVdata{trialType},BSEMdata{trialType},'r','transparency', 0.3,'alpha');                                                                             
%                     varargout = boundedline(1:size(CAVdata{count}{z,trialType},2),CAVdata{count}{z,trialType},CSEMdata{count}{z,trialType},'b','transparency', 0.3,'alpha');                                           
            varargout = boundedline(1:size(VAVdata{trialType},2),VAVdata{trialType},VSEMdata{trialType},'k','transparency', 0.3,'alpha');                        


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
                title(sprintf('Data smoothed by %d seconds.',filtTime));
            elseif smoothQ == 0
                title("Raw Data.");
            end 

        end                       
    end


%end 


end 