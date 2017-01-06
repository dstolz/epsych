%% Modify Atlas to place space between ROIs to avoid partial volume effects

scaleFactor = 2;

Patlas = 'D:\ownCloud\PROJECTS\MRI\TPM_Catlas_Slicer4\CombinedAreas.nii';
Vatlas = spm_vol(Patlas);
Yatlas = uint8(spm_read_vols(Vatlas));

fprintf('Upsampling volume...')
[Xq,Yq,Zq] = meshgrid(1:1/scaleFactor:size(Yatlas,1),1:1/scaleFactor:size(Yatlas,2),1:1/scaleFactor:size(Yatlas,3));
iYatlas = interp3(Yatlas,Xq,Yq,Zq,'nearest');
clear *q
fprintf(' done\n')

roiID = unique(iYatlas(:));
roiID(roiID==0|isnan(roiID))=[];

for i = 1:length(roiID)
    fprintf('Processing ROI %2d of %d...',i,length(roiID))
    ind = iYatlas == roiID(i);
    p = bwperim(ind);
    iYatlas(p) = 0;
    fprintf(' done\n');
end
clear p

%%
fprintf('Downsampling volume...')
[Xq,Yq,Zq] = meshgrid(1:scaleFactor:size(iYatlas,1),1:scaleFactor:size(iYatlas,2),1:scaleFactor:size(iYatlas,3));
Yatlas = interp3(iYatlas,Xq,Yq,Zq,'nearest');
clear iYatlas *q
fprintf(' done\n')

%
PatlasB = fullfile(fileparts(Patlas),'AtlasB.nii');
VatlasB = Vatlas;
VatlasB.fname = PatlasB;
% VatlasB.dim   = size(iYatlas);
% m = spm_imatrix(Vatlas.mat);
% m(7:9) = m(7:9)/scaleFactor;
% VatlasB.mat = spm_matrix(m);

spm_write_vol(VatlasB,Yatlas);

spm_check_registration([Vatlas; VatlasB]);

