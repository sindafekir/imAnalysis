function [BW,maskedImage] = segmentImage117_20210622_stimBehaviorETA_20231227zScored(X)
%segmentImage Segment image using auto-generated code from Image Segmenter app
%  [BW,MASKEDIMAGE] = segmentImage(X) segments image X using auto-generated
%  code from the Image Segmenter app. The final segmentation is returned in
%  BW, and a masked image is returned in MASKEDIMAGE.

% Auto-generated by imageSegmenter app on 29-Dec-2023
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
BW = im2gray(X) > 2.200000e-01;

% Active contour
iterations = 1;
BW = activecontour(X, BW, iterations, 'Chan-Vese');

% Create masked image.
maskedImage = X;
maskedImage(~BW) = 0;
end

