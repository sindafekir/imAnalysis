function [TSdataBBBperm] = BBBpermTS(inputStacks,userInput)

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

segQ = 1; 
cd(imAn1funcDir); 
while segQ == 1     

    %segment the vessel (small sample of the data) 
    VROI = input("What BBB ROI do you want to use to make segmentation algorithm? ");
    [volIm] = getUserInput(userInput,'Is this volume imaging data? Yes = 1. Not = 0.');
    if volIm == 1
        z = input("What z plane do you want to use to make segmenation algorithm? ");
    elseif volIm == 0 
    end 
    imageSegmenter(ROIstacks{z}{1}{1}{VROI}{1}(:,:,size(ROIstacks{z}{1}{1}{VROI}{1},3)))
    continu = input('Is the image segmenter closed? Yes = 1. No = 0. ');

    while continu == 1 
        BWstacks = cell(1,length(ROIstacks));
        BW_perim = cell(1,length(ROIstacks));
        segOverlays = cell(1,length(ROIstacks));
        for Z = 1:length(ROIstacks)
            for trialType = 1:size(inputStacks{z},2)
                for VROI = 1:numROIs 
                    if isempty(inputStacks{z}{trialType}) == 0 
                        for trial = 1:size(ROIstacks{Z}{trialType},2)

                                for frame = 1:size(ROIstacks{Z}{trialType}{trial}{VROI}{1},3)
                                    [BW,~] = segmentImageBBB(ROIstacks{Z}{trialType}{trial}{VROI}{1}(:,:,frame));
                                    BWstacks{Z}{trialType}{trial}{VROI}(:,:,frame) = BW; 
                                    %get the segmentation boundaries 
                                    BW_perim{Z}{trialType}{trial}{VROI}(:,:,frame) = bwperim(BW);
                                    %overlay segmentation boundaries on data
                                    segOverlays{Z}{trialType}{trial}{VROI}(:,:,:,frame) = imoverlay(mat2gray(ROIstacks{z}{trialType}{trial}{VROI}{1}(:,:,frame)), BW_perim{Z}{trialType}{trial}{VROI}(:,:,frame), [.3 1 .3]);
                                end 

                        end 
                    end 
                end 
            end 
        end 
        continu = 0;
    end 

    %check segmentation 
    if volIm == 1
         Z = input("What Z plane do you want to see? ");
    elseif volIm == 0 
        Z = 1; 
    end 
    VROI = input("What BBB ROI do you want to see? ");
    trialType = input("What trial type do you want to see? ");
    

    %play segmentation boundaries over images 
    implay(segOverlays{Z}{trialType}{1}{VROI})

    segQ = input('Does segmentation need to be redone? Yes = 1. No = 0. ');    
end 


end 