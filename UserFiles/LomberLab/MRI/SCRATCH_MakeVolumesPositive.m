
%% Update volumes so that all NaN and negative values are set to 0
% Note: writes over original volume.
%
% DJS 17/6/2016

[filenames,sts] = spm_select([1 inf],'image','Select a volume');

filenames = cellstr(filenames);
for i = 1:length(filenames)
    V = spm_vol(filenames{i});
    Y = spm_read_vols(V);
    Y(Y<0|isnan(Y)) = 0;
    spm_write_vol(V,Y);
    spm_image('Display',V)
end


