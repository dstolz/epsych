%% GIFT ICA to Slicer colormap
Pma = 'H:\DataProcessing\GIFT_\ALL_mean_component_ica_s_all_.nii';

Patlas = 'D:\ownCloud\PROJECTS\MRI\FINALIZED\SlicerFinal8\CorticalAtlas-Split.nii';
Tareas = 'D:\ownCloud\PROJECTS\MRI\FINALIZED\conn_catlas.txt';
Tcolors = 'D:\ownCloud\PROJECTS\MRI\FINALIZED\CATLAS_COLORS-SPLIT.txt';
threshold = [-1.5 1.5];

clear Cma*

ePma = spm_select('expand',Pma);
nj = size(ePma,1);

parfor j = 1:nj
    fprintf('Processing component %d of %d\n',j,nj)
    Cma(j) = voxelCoverage(ePma(j,:),threshold,Patlas,Tareas,false);
end

fn = fieldnames(Cma);
for i = 1:numel(Cma)
    for j = 1:length(fn)
        Cma_pos(i,j) = Cma(i).(fn{j}).pos.total / Cma(i).(fn{j}).pos.Area;
        Cma_neg(i,j) = Cma(i).(fn{j}).neg.total / Cma(i).(fn{j}).neg.Area;
    end    
end


fid = fopen(Tcolors,'r');
Ta = textscan(fid,'%d %s %d %d %d %d');
fclose(fid);
area_names = Ta{2};

cmap = round(jet(100) * 255);


for i = 1:size(Cma_pos,1)
    mn = fullfile(pwd,sprintf('PosVoxCoverage_GroupA_ICA%03d.txt',i));
    fid = fopen(mn,'w+');
    for j = 1:length(area_names)
        m = round(Cma_pos(i,j)*100);
        if ~m, m = 1; end
        fprintf(fid,'%d %s %d %d %d 255',j,area_names{j},cmap(m,:));
        if j < length(area_names), fprintf(fid,'\n'); end
    end
    fclose(fid);
    fprintf('Wrote: <a href="matlab: !explorer %s">%s</a>\n',mn,mn)
end




