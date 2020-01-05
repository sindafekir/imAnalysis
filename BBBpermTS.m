function [TSdataBBBperm] = BBBpermTS(inputStacks,userInput)

% inputStacks = sortedStacks; DELETE WHEN DONE TROUBLESHOOTING 


%% create non-vascular ROI for entire x-y plane 

%go to dir w/functions
[imAn1funcDir] = getUserInput(userInput,'imAnalysis1_functions Directory');
cd(imAn1funcDir); 

%update userInput 
UIr = size(userInput,1)+1;
numROIs = input("How many BBB perm ROIs are we making? "); userInput(UIr,1) = ("How many BBB perm ROIs are we making?"); userInput(UIr,2) = (numROIs); UIr = UIr+1;

%for display purposes mostly: average across trials 
inputStacks4D = cell(1,length(inputStacks));
stackAVs = cell(1,length(inputStacks));
stackAVsIm = cell(1,length(inputStacks));
for z = 1:length(inputStacks)
    for trialType = 1:size(inputStacks{z},2)
        if isempty(inputStacks{z}{trialType}) == 0 
            for trial = 1:size(inputStacks{z}{trialType},2)
                inputStacks4D{z}{trialType}(:,:,:,trial) = inputStacks{z}{trialType}{trial};
            end 
            stackAVs{z}{trialType} = mean(inputStacks4D{z}{trialType},4);
            stackAVsIm{z}{trialType} = mean(stackAVs{z}{trialType},3);
        end  
    end 
end 

ROIboundDatas = cell(1,length(inputStacks));
ROIstacks = cell(1,length(inputStacks));
for z = 1:length(inputStacks)
    ROIboundQ = 1; 
    for trialType = 1:size(inputStacks{z},2)
        if isempty(inputStacks{z}{trialType}) == 0 
            %create the ROI boundaries 
            if ROIboundQ == 1           
                for VROI = 1:numROIs 
                    disp('Create your ROI for vessel segmentation');

                    [~,xmins,ymins,widths,heights] = firstTimeCreateROIs(1, stackAVsIm{z}{trialType});
                    ROIboundData{1} = xmins;
                    ROIboundData{2} = ymins;
                    ROIboundData{3} = widths;
                    ROIboundData{4} = heights;

                    ROIboundDatas{z}{VROI} = ROIboundData;
                end 
                ROIboundQ = 0; 
            end 
            
            %use the ROI boundaries to generate ROIstacks 
            for trial = 1:size(inputStacks{z}{trialType},2)
                for VROI = 1:numROIs 
                    xmins = ROIboundDatas{z}{VROI}{1};
                    ymins = ROIboundDatas{z}{VROI}{2};
                    widths = ROIboundDatas{z}{VROI}{3};
                    heights = ROIboundDatas{z}{VROI}{4};
                    [ROI_stacks] = make_ROIs_notfirst_time(inputStacks{z}{trialType}{trial},xmins,ymins,widths,heights);
                    ROIstacks{z}{trialType}{trial}{VROI} = ROI_stacks;
                end 
            end 
        end 
    end 
end 

%% segment the ROIs - goal: identify non-vascular/non-terminal space 

threshQ = 1; 
cd(imAn1funcDir); 
while threshQ == 1     
    %segment the vessel (small sample of the data) 
    imageSegmenter(ROIstacks{z}{trialType}{trial}{VROI}{1}(:,:,size(ROIstacks{z}{trialType}{trial}{VROI}{1},3)))
    continu = input('Is the image segmenter closed? Yes = 1. No = 0. ');
    
    while continu == 1 
        BWstacks = cell(1,length(ROIstacks));
        boundaries = cell(1,length(ROIstacks));
        for Z = 1:length(ROIstacks)
            for trialType = 1:size(inputStacks{z},2)
                if isempty(inputStacks{z}{trialType}) == 0 
                    for trial = 1:size(ROIstacks{Z}{trialType},2)
                        for VROI = 1:numROIs 

                            for frame = 1:size(ROIstacks{Z}{trialType}{trial}{VROI}{1},3)
                                [BW,~] = segmentImageBBB(ROIstacks{Z}{trialType}{trial}{VROI}{1}(:,:,frame));
                                BWstacks{Z}{trialType}{trial}{VROI}(:,:,frame) = BW; 
                                %get the segmentation boundaries 
                                [~,bounds] = findVesWidth(BWstacks{Z}{trialType}{trial}{VROI}(:,:,frame));
                                boundaries{Z}{trialType}{trial}{VROI}{frame} = bounds;
                            end 
                            

                        end 
                    end 
                end 
            end 
        end 
        continu = 0;
    end 
    
    %NEED TO ADD IN BOUNDARIES GENERATION 
    %check segmentation 
    [volIm] = getUserInput(userInput,'Is this volume imaging data? Yes = 1. Not = 0.');
    setMaxPoint = 1;
    while setMaxPoint == 1 
        maxPoint = input("What should the pixel max point be to visualize mask boundaries? ");
        framesToShow = 200;
        if volIm == 1
            Zplane = input('What Z plane do you want to see?');
        elseif volIm == 0
            Zplane = 1;
        end 
        for VROI = 1:numROIs
            %play_mask_over_roi_stack(BWstacks{Z}{trialType}{trial}{VROI},boundaries{Zplane}{VROI},framesToShow,maxPoint);
         %---------------------------------------------------------------   
            figure;
            for frame = 1:size(ROIstacks{Zplane}{trialType}{trial}{VROI}{1},3)
                imshow(ROIstacks{Zplane}{trialType}{trial}{VROI}{1}(:,:,frame),[0,maxPoint])
                hold on; 
                    for bounds = 1:size(boundaries{Z}{trialType}{trial}{VROI}{frame},1)
                        plot(boundaries{Z}{trialType}{trial}{VROI}{frame}{1}{bounds,1}(:,2), boundaries{Z}{trialType}{trial}{VROI}{frame}{1}{bounds,1}(:,1), 'r', 'LineWidth', 2)
                    end 
            end 
            
            %-----------------------------------------------------------------------------------
            
        end 
        setMaxPoint = input("Do you need to reset the pixel max point? Yes = 1. No = 0. "); 
    end 

    segmentVessel = input("Does the vessel need to be segmented again? Yes = 1. No = 0. ");
    if segmentVessel == 1
        clear BWthreshold BWopenRadius BW se boundaries
    end 
    

%---------------------------------------------------------------------------------
    threshQ = input('Change pixel intensity threshold? Yes = 1. No = 0. ');    
end 


                %ABOVE IS WORKING CODE - ADD IN CODE TO PLAY THE MASK OVER
                %THE ORIGINAL STACK AS DONE WITH SEGMENTATION CODE 
            
%               %--------------------------------------------------          
% 
%                 %ABOVE IS WORKING CODE - TROUBLESHOOTING BELOW             
% 
%                     CAroiGen = input('Do the calcium ROIs need to be redone? Yes = 1. No = 0. ');
%                     if CAroiGen == 1 
%                         clear CaROIs 
%                     elseif CAroiGen == 0
%                         userInput(UIr,1) = (sprintf("Set the calcium ROI generation pixel intensity threshold. Z%d",Z)); userInput(UIr,2) = (imThresh); UIr = UIr+1;
%                     end 

%                     CaROImasks{trialType} = nm1BW2; 

                %     %figure out the order that terminal ROIs are looked at to match ROI
                %     %with data 
                %     ROIorders{trialType} = bwlabel(nm1BW2);





end 