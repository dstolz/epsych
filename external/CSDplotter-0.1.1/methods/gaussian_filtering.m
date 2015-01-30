function [new_positions,gfiltered_CSD] = gaussian_filtering(positions,unfiltered_CSD,gauss_sigma,filter_range)
%function [new_positions, gfiltered_CSD]= ...
%gaussian_filtering(positions,unfiltered_CSD,gauss_sigma,filter_range)
%
%This function filters the CSD using a gaussian filter.
%
%positions:     The CSD positions
%unfiltered_CSD: The unfiltered CSD matrix
%gauss_sigma:   standard deviation of the gaussian
%filter_range:  the filter width, default: 5*gauss_sigma

%Copyright 2005 Klas H. Pettersen under the General Public License,
%
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or any later version.
%
%See: http://www.gnu.org/copyleft/gpl.html

if nargin<4; filter_range = 5*gauss_sigma; end;

step = positions(2)-positions(1);
filter_positions = -filter_range/2:step:filter_range/2;
gaussian_filter = 1/(gauss_sigma*sqrt(2*pi))*exp(-filter_positions.^2/(2*gauss_sigma^2));
filter_length = length(gaussian_filter);
[m,n]=size(unfiltered_CSD);
temp_CSD=zeros(m+2*filter_length,n);
temp_CSD(filter_length+1:filter_length+m,:)=unfiltered_CSD(:,:); % one filter length of zeros on each side
scaling_factor = sum(gaussian_filter);
chunksze = 500;
for i = 1:chunksze:size(temp_CSD,2) % split up matrix into bitesized epochs for filtering
    if i+chunksze-1 < size(temp_CSD,2)
        temp_CSD(:,i:i+chunksze-1) = filter(gaussian_filter/scaling_factor,1,temp_CSD(:,i:i+chunksze-1)); % filter works such that the first filter_length positions are crap
    else
        temp_CSD(:,i:end) = filter(gaussian_filter/scaling_factor,1,temp_CSD(:,i:end)); % filter works such that the first filter_length positions are crap
    end
end
gfiltered_CSD=temp_CSD(round(1.5*filter_length)+1:round(1.5*filter_length)+m,:); % first filter_length is crap, next 0.5 filter length corresponds to positions smaller than the original positions
new_positions = positions;