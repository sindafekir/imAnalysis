function [BW,maskedImage] = segmentImage118_20210629_rewBehaviorETA_20240106zScored(X)
%segmentImage Segment image using auto-generated code from Image Segmenter app
%  [BW,MASKEDIMAGE] = segmentImage(X) segments image X using auto-generated
%  code from the Image Segmenter app. The final segmentation is returned in
%  BW, and a masked image is returned in MASKEDIMAGE.

% Auto-generated by imageSegmenter app on 06-Jan-2024
%----------------------------------------------------


% Normalize input data to range in [0,1].
Xmin = min(X(:));
Xmax = max(X(:));
if isequal(Xmax,Xmin)
    X = 0*X;
else
    X = (X - Xmin) ./ (Xmax - Xmin);
end

% Threshold image with adaptive threshold
BW = imbinarize(im2gray(X), 'adaptive', 'Sensitivity', 0.000000, 'ForegroundPolarity', 'bright');

% Active contour
iterations = 1;
BW = activecontour(X, BW, iterations, 'edge');

% Dilate mask with default
radius = 3;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imdilate(BW, se);

% Open mask with default
radius = 1;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imopen(BW, se);

% Active contour
iterations = 1;
BW = activecontour(X, BW, iterations, 'edge');

% Create masked image.
maskedImage = X;
maskedImage(~BW) = 0;
end
