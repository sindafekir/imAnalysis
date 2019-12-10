function [vessel_diam,boundaries] = findVesWidth(BWstacks)


for y = 1:size(BWstacks,3)
        %determine number of white pixels per row of mask (BW)
        white_pix = flipud(sum(BWstacks(:,:,y) == 1, 2));
        %find mean number of white pixels per row
        av_white_pix = mean(white_pix);
        %find diameter of largest region
        vessel_diam(y) = av_white_pix;
        %make outline
        [B,~] = bwboundaries(BWstacks(:,:,y),'noholes');
        boundaries{y} = B;
end 


end 