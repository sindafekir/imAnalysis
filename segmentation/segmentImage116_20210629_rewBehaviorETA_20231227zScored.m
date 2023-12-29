function [BW,maskedImage] = segmentImage116_20210629_rewBehaviorETA_20231227zScored(X)
%segmentImage Segment image using auto-generated code from Image Segmenter app
%  [BW,MASKEDIMAGE] = segmentImage(X) segments image X using auto-generated
%  code from the Image Segmenter app. The final segmentation is returned in
%  BW, and a masked image is returned in MASKEDIMAGE.

% Auto-generated by imageSegmenter app on 22-Dec-2023
%----------------------------------------------------


% Normalize input data to range in [0,1].
Xmin = min(X(:));
Xmax = max(X(:));
if isequal(Xmax,Xmin)
    X = 0*X;
else
    X = (X - Xmin) ./ (Xmax - Xmin);
end

% Threshold image with global threshold
BW = imbinarize(im2gray(X));

% Active contour
iterations = 2;
BW = activecontour(X, BW, iterations, 'edge');

% Open mask with default
radius = 1;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imopen(BW, se);

% Active contour
iterations = 50;
BW = activecontour(X, BW, iterations, 'Chan-Vese');

% Dilate mask with default
radius = 2;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imdilate(BW, se);

% Active contour
iterations = 10;
BW = activecontour(X, BW, iterations, 'Chan-Vese');

% Active contour
iterations = 9;
BW = activecontour(X, BW, iterations, 'edge');

% Active contour
iterations = 50;
BW = activecontour(X, BW, iterations, 'Chan-Vese');

% Close mask with default
radius = 1;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imclose(BW, se);

% Dilate mask with default
radius = 1;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imdilate(BW, se);

% Active contour
iterations = 100;
BW = activecontour(X, BW, iterations, 'Chan-Vese');

% Close mask with default
radius = 3;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imclose(BW, se);

% Dilate mask with default
radius = 2;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imdilate(BW, se);

% Active contour
iterations = 20;
BW = activecontour(X, BW, iterations, 'Chan-Vese');

% Close mask with default
radius = 3;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imclose(BW, se);

% Active contour
iterations = 1;
BW = activecontour(X, BW, iterations, 'edge');

% Create masked image.
maskedImage = X;
maskedImage(~BW) = 0;
end

