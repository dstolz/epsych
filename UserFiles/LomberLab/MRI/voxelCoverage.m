function C = voxelCoverage(Pstat,threshold,Patlas,Tareas,verbose)
% C = voxelCoverage(Pstat,[threshold],[Patlas],[Tareas],[verbose])
% 
% Inputs:
%   Pstat       ... Filepath to statistical .nii volume
%   threshold   ... Statistical threshold values. If a single value is
%                   specified, then a negative and a positive values will be
%                   used. Default = [-1 1]
%   Patlas      ... Filepath to atlas volume where each brain region is an
%                   integer.
%   Tareas      ... Filepath to text file containing labels on lines
%                   corresponding to integers defining brain regions in
%                   Patlas.
%   verbose     ... If true (default), then print summary table of results.
%
% Outputs:
%   C           ... Structure with field names defined by area labels
%                   defined in Tareas text file. Each field (region) has 
%                   'pos' and 'neg' subfields which contain positive and
%                   negative voxels within a region that exceeds the
%                   threshold value.  Both 'pos' and 'neg' subfields
%                   contain the following results:
%                       .Area, .Centroid, .anterior, .posterior, .lateral,
%                       .medial, .dorsal, .ventral, .PixelIdxList
%                   Each of the cardinal subfields (.anterior, etc.) are
%                   total voxels from the Pstat volume that exceed the
%                   threshold value within a region of interest relative to
%                   the computed Centroid voxel.  Note that the voxel at
%                   the centroid is not counted for any of the cardinal
%                   measures, but is included in the .Area (total voxel
%                   count within region of interest).
%                       
%
% Daniel.Stolzberg@gmail.com (C) 2016



if nargin == 0 || isempty(Pstat)
    Pstat = spm_select(1,'image','Select file');
end

if nargin < 2 || isempty(threshold), threshold = [-1 1]; end
if numel(threshold) == 1, threshold = [-1 1]*abs(threshold); end

if nargin < 5 || isempty(verbose), verbose = true; end

Vatlas = spm_vol(Patlas);
Vstat  = spm_vol(Pstat);

% Atlas Areas
fid = fopen(Tareas,'r');

i = 1;
while ~feof(fid)
    areaStr{i} = fgetl(fid); %#ok<AGROW>
    i = i + 1;
end
fclose(fid);

% reslice atlas volume to match statistical volume
Yatlas = zeros(Vstat.dim,'uint16');
for i = 1:Vstat.dim(3)
    Yatlas(:,:,i) = spm_slice_vol(Vatlas,spm_matrix([0 0 i]),Vstat.dim([1 2]),0);
end

Ystat = spm_read_vols(Vstat);
mareaStr = matlab.lang.makeValidName(areaStr);
if verbose, fprintf('Region Label\tArea\tCoverage +(-)\n%s\n',repmat('=',1,45)); end
for i = 1:length(areaStr)
    C.(mareaStr{i}).neg = cardinalCoverage(Ystat<threshold(1),Yatlas==i);
    C.(mareaStr{i}).pos = cardinalCoverage(Ystat>threshold(2),Yatlas==i);
    C.(mareaStr{i}).region_label = areaStr{i};
    C.(mareaStr{i}).atlas_size = sum(Yatlas(:)==i);
    
    if verbose
        fprintf('%- 12s\t% 6d\t%4.1f%% (%4.1f%%)\n', ...
            areaStr{i},C.(mareaStr{i}).pos.Area, ...
            C.(mareaStr{i}).pos.total/C.(mareaStr{i}).pos.Area*100, ...
            C.(mareaStr{i}).neg.total/C.(mareaStr{i}).neg.Area*100);
    end
end


function C = cardinalCoverage(Ys,Ya)
C = regionprops(Ya,{'Centroid','Area','PixelIdxList'});
C([C.Area]~=max([C.Area])) = []; % Use largest area if there happens to be multiple objects
C.Centroid = round(C.Centroid); % get voxel nearest actual centroid

Yt = zeros(size(Ys));
Yt(C.PixelIdxList) = 1;
Yt = Yt&Ys;
C.total = nnz(Yt);

% ************** CHECK THESE DIRECTIONS ******************
C.anterior  = nnz(Yt(1:C.Centroid(1)-1,:,:));
C.posterior = nnz(Yt(C.Centroid(1)+1:end,:,:));
C.dorsal    = nnz(Yt(:,:,C.Centroid(3)+1:end));
C.ventral   = nnz(Yt(:,:,1:C.Centroid(3)-1));
if C.Centroid(2) > mean([1 size(Ya,2)])
    C.lateral = nnz(Yt(:,C.Centroid(2)+1:end,:));
    C.medial  = nnz(Yt(:,1:C.Centroid(2)-1,:));
else
    C.medial  = nnz(Yt(:,C.Centroid(2)+1:end,:));
    C.lateral = nnz(Yt(:,1:C.Centroid(2)-1,:));
end














