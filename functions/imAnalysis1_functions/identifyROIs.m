function [imThresh,CaROImasks,ROIorders] = identifyROIs(reg_Stacks)

stackAVs = cell(1,length(reg_Stacks));
CaROImasks = cell(1,length(reg_Stacks));
ROIorders = cell(1,length(reg_Stacks));
for Z = 1:length(reg_Stacks)               
    %create average images per Z plane 
    stackAVs{Z} = mean(reg_Stacks{Z},3); 
    %scale the images to be between 0 to 1 
    stackAVs{Z} = stackAVs{Z} ./ max(stackAVs{Z}(:));

    CAroiGen = 1;
    while CAroiGen == 1
        [imThresh,mask,CAroiGen] = createCaROIs(stackAVs{Z});           
    end 
    %invert the CaROImask
    CaROImasks{Z} = ~mask; 
    
    %figure out the order that terminal ROIs are looked at to match ROI
    %with data 
    ROIorders{Z} = bwlabel(CaROImasks{Z});
end

meanPixIntArray = cell(1,size(reg_Stacks,2));
%apply mask to data and get the average pixel intensity of each terminal ROI 
for zStack = 1:size(reg_Stacks,2)
    for frame = 1:length(reg_Stacks{zStack})
        stats = regionprops(CaROImasks{zStack},reg_Stacks{zStack}(:,:,frame),'MeanIntensity');
            for ROI = 1:size(stats,1)
                meanPixIntArray{zStack}(ROI,frame) = stats(ROI).MeanIntensity;
            end 
    end   
end 

%compare the GCaMP signal of each Ca ROI with eachother 
%corr2 gives you a single correlation value for the entire vectors
%being compared 
ROIcorArray = cell(1,size(reg_Stacks,2));
for zStack = 1:size(reg_Stacks,2)
    for ROI = 1:size(meanPixIntArray{zStack},1) 
         for ROIcor = 1:size(meanPixIntArray{zStack},1)
            ROIcorArray{zStack}(ROI,ROIcor) = corr2(meanPixIntArray{zStack}(ROI,:),meanPixIntArray{zStack}(ROIcor,:));
         end
    end
end 

%this updates the Ca ROIs based on their activity patterns and
%location (2D) 
count = 1;
R = cell(1,count);
C = cell(1,count);
for Z = 1:size(reg_Stacks,2)
    for row = 1:size(meanPixIntArray{Z},1) 
        for col = 1:size(meanPixIntArray{Z},1) 
            if ROIcorArray{Z}(row,col) >= 0.75 && ROIcorArray{Z}(row,col) ~= 1 
                %find correlated ROIs 
                R{count} = ROIorders{Z} == row;
                C{count} = ROIorders{Z} == col;

                [CaROImasks,count] = combineCaROIs(CaROImasks,count,Z,R,C);                    
            end
        end 
    end 
end

%relables ROIs that belong to the same terminal across Z        
for x = 1:length(CaROImasks)
    CaROImasks{x} = double(CaROImasks{x});
end 

%the below code isn't necessary anymore, but I'll keep this here for
%safekeeping 
% %relable all ROIs in CaROImasks w/non 1 numbers 
% maxLabel = maxLabel + 1;
% for Z = 1:length(meanPixIntArray)
%     for ROIorder = 1:size(meanPixIntArray{Z},1)
%         if unique(CaROImasks{Z}(ROIorders{Z} == ROIorder)) == 1 
%             CaROImasks{Z}(ROIorders{Z} == ROIorder) = maxLabel;
%             maxLabel = maxLabel + 1;
%         end 
%     end 
% end 

imagesc(CaROImasks{1});grid on;figure;imagesc(ROIorders{1});grid on;
end 