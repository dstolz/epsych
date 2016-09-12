function C = voxelCoverage(Pstat,threshold,Patlas,Tareas)
% C = voxelCoverage(Pstat,[threshold],[Patlas],[Tareas])
% 
% Inputs:
%
% Outputs:
%
% Daniel.Stolzberg@gmail.com (C) 2016



if nargin == 0 || isempty(Pstat)
    Pstat = spm_select(1,'image','Select file');
end

if nargin < 2 || isempty(threshold), threshold = 1; end

% Patlas = 'C:\Users\Daniel\Documents\CombinedAreas.nii';
Vatlas = spm_vol(Patlas);
Yatlas = spm_read_vols(Vatlas);

% Atlas Areas
% fid = fopen('C:\Users\Daniel\Documents\AREAS.txt','r');
fid = fopen(Tareas,'r');

i = 1;
while ~feof(fid)
    areaStr{i} = fgetl(fid); %#ok<AGROW>
    i = i + 1;
end
fclose(fid);

I.input = {Pstat; Patlas};
I.outdir = {pwd};
I.options.dmtx = 0;
I.options.mask = 0;
I.options.interp = 0;
I.options.dtype = 16;


M = cell(size(areaStr));
for i = 1:length(areaStr)
    I.output = sprintf('VoxelSum_%s.nii',areaStr{i});
    I.expression = sprintf('i2 == %d & (i1 < %0.1f | i1 > %0.1f)',i,-threshold,threshold);
    M{i}.spm.util.imcalc = I;
end

spm_jobman('run',M);

% areal coverage
for i = 1:length(M)
    f = fullfile(M{i}.spm.util.imcalc.outdir,M{i}.spm.util.imcalc.output);
    Vind = spm_vol(f);
    Yind = spm_read_vols(Vind{1});
    C(i) = cardinalCoverage(Yind,Yatlas==i);
    fprintf('%- 10s Area: % 6d\tTotal: % 4.1f%%\n', ...
        areaStr{i},C(i).Area,C(i).total/C(i).Area*100)
    delete(f)
end

if DIRFLAG, rmdir(outdir); end


function C = cardinalCoverage(Ys,Ya)
C = regionprops(Ya,{'Centroid','Area'});
C([C.Area]~=max([C.Area])) = []; % Use largest area if there happens to be multiple objects
C.Centroid = round(C.Centroid);

% * THIS WILL NOT WORK WHEN IMAGE DIMENSIONS DIFFER *
% CHECK THESE DIRECTIONS
C.anterior  = nnz(Ys(1:C.Centroid(1)-1,:,:));
C.posterior = nnz(Ys(C.Centroid(1)+1:end,:,:));
C.dorsal    = nnz(Ys(:,C.Centroid(2)+1:end,:));
C.ventral   = nnz(Ys(:,1:C.Centroid(2)-1,:));
if C.Centroid(2) > mean([1 size(Ya,2)])
    C.lateral = nnz(Ys(:,:,C.Centroid(3)+1:end));
    C.medial  = nnz(Ys(:,:,1:C.Centroid(3)-1));
else
    C.medial  = nnz(Ys(:,:,C.Centroid(3)+1:end));
    C.lateral = nnz(Ys(:,:,1:C.Centroid(3)-1));
end
C.total = nnz(Ys);














