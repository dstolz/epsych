function [regions, tolerance] = regionGenerator(numRegions)

tolerance = 90/((numRegions-1)/4);

for i = 1:numRegions
    regions(i) = -90 + (i-1)*(90/((numRegions-1)/2));
end
