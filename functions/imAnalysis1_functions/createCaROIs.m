function [imThresh,mask,CAroiGen] = createCaROIs(stackAVs)
imThresh = input("Set the calcium ROI generation pixel intensity threshold. (Try ~0.01) "); 
brightThresh = 0.0005; %input("Set the calcium ROI generation brightest point intensity threshold. (Try ~2) ");
%apply a threshold to create mask 
nm1BW = imbinarize(stackAVs,imThresh);
%clean the mask up and overlay over original image for comparison 
nm1BW2 = imfill(nm1BW,'holes');
% nm1BW2_perim = bwperim(nm1BW2);

% identify the brightest point of each terminal (the center) 
maskEm = imextendedmax(stackAVs,brightThresh);
%clean up the brightest point mask and overlay 
maskEm = imfill(maskEm, 'holes');            
% CaROIs = imoverlay(stackAVs, maskEm, [.3 1 .3]);% | maskEm, [.3 1 .3]);

%use watershed transform to figure out low and high points in image
%(this separates terminals that are touching) 
nm1eqC = imcomplement(stackAVs);
nm1mod = imimposemin(nm1eqC, ~nm1BW2 | maskEm);
%THE 8 IN THIS WATERSHED FORMULA MAY NEED TO BE CHANGED 
nm1WS = watershed(nm1mod,18); %A scalar connectivity specifier must be 1, 4, 6, 8, 18, or 26.
% imshow(nm1WS,[0 10]);

%create mask 
nm1WS(nm1WS==0)=1;
nm1WS(nm1WS>1)=0;
% nm1WSbw = imbinarize(nm1WS,0);
% nm1WSbw = ~nm1WSbw;
% nm1WSbw_perim = bwperim(nm1WSbw);
% CaROIs = imoverlay(stackAVs, nm1WSbw_perim,[.3 1 .3]);

% get rid of ROIs that are too small
radius = 1;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imdilate(nm1WS, se);

% make ROIs bigger 
radius = 2;
decomposition = 0;
se = strel('disk', radius, decomposition);
mask = imerode(BW, se);

% compare mask to orignal image 
imshow(stackAVs); 
figure; imagesc(mask)

CAroiGen = input('Do the calcium ROIs need to be redone? Yes = 1. No = 0. ');
if CAroiGen == 1 
    clear CaROIs 
end 
end 