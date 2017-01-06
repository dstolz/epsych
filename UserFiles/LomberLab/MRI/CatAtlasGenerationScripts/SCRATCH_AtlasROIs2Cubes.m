%% Create new atlas based on sphere around ROI centroid

cubeSize = 1; % mm

Patlas = 'D:\ownCloud\PROJECTS\MRI\TPM_Catlas_Slicer4\CombinedAreas_SPLIT.nii';
Vatlas = spm_vol(Patlas);
Yatlas = uint8(spm_read_vols(Vatlas));

roi = unique(Yatlas(:));
roi(roi==0|isnan(roi))=[];

vxl = getVoxelSize(Vatlas);
vsq = round(cubeSize./abs(vxl));

SVatlas = Vatlas;
[pn,fn] = fileparts(Patlas);
SVatlas.fname = fullfile(pn,[fn '_Cubes.nii']);

SYatlas = zeros(size(Yatlas),'uint8');

for i = 1:length(roi)
    fprintf('Processing ROI %2d of %d...',i,length(roi))
    ind = Yatlas == roi(i);
  
    r = regionprops(ind,{'Area','Centroid'});
    [~,j] = max([r.Area]);
    r((1:length(r))~=j) = [];
    
    c = round(r.Centroid);
    SYatlas(c(2)-vsq(2):c(2)+vsq(2), ...
            c(1)-vsq(1):c(1)+vsq(1), ...
            c(3)-vsq(3):c(3)+vsq(3)) = roi(i);
        
    fprintf(' done\n');
end

spm_write_vol(SVatlas,SYatlas);

spm_check_registration([Vatlas; SVatlas]);




