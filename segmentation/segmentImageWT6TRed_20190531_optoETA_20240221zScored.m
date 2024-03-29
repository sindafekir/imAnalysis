function [BW,maskedImage] = segmentImageWT6TRed_20190531_optoETA_20240221zScored(X)
%segmentImage Segment image using auto-generated code from Image Segmenter app
%  [BW,MASKEDIMAGE] = segmentImage(X) segments image X using auto-generated
%  code from the Image Segmenter app. The final segmentation is returned in
%  BW, and a masked image is returned in MASKEDIMAGE.

% Auto-generated by imageSegmenter app on 21-Feb-2024
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

% Fill holes
BW = imfill(BW, 'holes');

% Dilate mask with default
radius = 2;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imdilate(BW, se);

% Active contour
iterations = 100;
BW = activecontour(X, BW, iterations, 'Chan-Vese');

% Active contour
iterations = 1;
BW = activecontour(X, BW, iterations, 'edge');

% Fill holes
BW = imfill(BW, 'holes');

% Open mask with default
radius = 2;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imopen(BW, se);

% Dilate mask with default
radius = 3;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imdilate(BW, se);

% Active contour
iterations = 1;
BW = activecontour(X, BW, iterations, 'edge');

% Active contour
iterations = 50;
BW = activecontour(X, BW, iterations, 'Chan-Vese');

% Fill holes
BW = imfill(BW, 'holes');

% Close mask with default
radius = 2;
decomposition = 0;
se = strel('disk', radius, decomposition);
BW = imclose(BW, se);

% Create masked image.
maskedImage = X;
maskedImage(~BW) = 0;
end

