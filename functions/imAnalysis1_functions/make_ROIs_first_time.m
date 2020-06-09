function [ROI_stack,xmin,ymin,width,height] = make_ROIs_first_time(segmented_data)


ROI_BW = roipoly(segmented_data(:,:,1));      

%Find row and column locations that are non-zero
[y,x] = find(ROI_BW);  

%Find top left corner
xmin = min(x);
ymin = min(y);

%Find bottom right corner
xmax = max(x);
ymax = max(y);

%Find width and height
width = xmax - xmin + 1;
height = ymax - ymin + 1;

for i=1: size(segmented_data,3)     
    %You can now go ahead and crop the image:
    ROI_stack(:,:,i) = imcrop(segmented_data(:,:,i), [xmin ymin width height]);
end 


end 