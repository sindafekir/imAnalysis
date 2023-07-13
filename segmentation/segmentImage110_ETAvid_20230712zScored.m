function [BW,maskedImage] = segmentImage110_ETAvid_20230712zScored(X)
%segmentImage Segment image using auto-generated code from Image Segmenter app
%  [BW,MASKEDIMAGE] = segmentImage(X) segments image X using auto-generated
%  code from the Image Segmenter app. The final segmentation is returned in
%  BW, and a masked image is returned in MASKEDIMAGE.

% Auto-generated by imageSegmenter app on 12-Jul-2023
%----------------------------------------------------


% Normalize input data to range in [0,1].
Xmin = min(X(:));
Xmax = max(X(:));
if isequal(Xmax,Xmin)
    X = 0*X;
else
    X = (X - Xmin) ./ (Xmax - Xmin);
end

% Threshold image with manual threshold
BW = im2gray(X) > 7.000000e-01;

% Active contour
iterations = 30;
BW = activecontour(X, BW, iterations, 'Chan-Vese');

% Dilate mask with default
radius = 5;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imdilate(BW, se);

% Active contour
iterations = 20;
BW = activecontour(X, BW, iterations, 'edge');

% Active contour
iterations = 20;
BW = activecontour(X, BW, iterations, 'Chan-Vese');

% Dilate mask with default
radius = 5;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imdilate(BW, se);

% Active contour
iterations = 30;
BW = activecontour(X, BW, iterations, 'Chan-Vese');

% Open mask with default
radius = 1;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imopen(BW, se);

% Dilate mask with default
radius = 3;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imdilate(BW, se);

% Active contour
iterations = 6;
BW = activecontour(X, BW, iterations, 'edge');

% Create masked image.
maskedImage = X;
maskedImage(~BW) = 0;
end
