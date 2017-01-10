%%
rootdir = getpref('ICA_GROUPCORR','rootdir',pwd);
if ~isempty(rootdir), setpref('ICA_GROUPCORR','rootdir',rootdir); end
mask = 'C:\MATLAB\work\Plugins\MRI\spm12\canonical\cat_brain_mask.nii';

Psa = spm_select([1 inf],'image','GroupA: ICA components for Group A...', ...
    {},rootdir,'.*sub.*component_ica.*.nii');
Psa = cellstr(Psa);
Pma = spm_select(1,'image','GroupA: Mean ICA components, all sessions...', ...
    {},fileparts(Psa{1}),'.*mean_component_ica_s_all.*.nii');
Pma = Pma(1:find(Pma==',',1,'last')-1);

Psb = spm_select([1 inf],'image','GroupB: ICA components...', ...
    {},'H:\DataProcessing','.*sub.*component_ica.*.nii');
Psb = cellstr(Psb);
Pmb = spm_select(1,'image','GroupB: Mean ICA components, all sessions...', ...
    {},fileparts(Psb{1}),'.*mean_component_ica_s_all.*.nii');
Pmb = Pmb(1:find(Pmb==',',1,'last')-1);

Psa = cellfun(@(a) (a(1:find(a==',',1,'last')-1)),cellstr(Psa),'UniformOutput',false);
Psb = cellfun(@(a) (a(1:find(a==',',1,'last')-1)),cellstr(Psb),'UniformOutput',false);


fprintf('Group A\n\t%d Components, Mean: %s\n',size(spm_select('expand',Pma),1),Pma)
for i = 1:length(Psa)
    fprintf('\t%s\n',Psa{i})
end

fprintf('Group B\n\t%d Components, Mean: %s\n',size(spm_select('expand',Pmb),1),Pmb)
for i = 1:length(Psb)
    fprintf('\t%s\n',Psb{i})
end

%%

Vmask = spm_vol(mask);

Vma = spm_vol(Pma);
Vmb = spm_vol(Pmb);

Yma = spm_read_vols(Vma);
Ymb = spm_read_vols(Vmb);

Ymask = spm_read_vols(Vmask);
Ymask = logical(Ymask);



%% Compute Correlation Coefficients to find corresponding components between groups
R = nan(size(Yma,4));
for i = 1:size(Yma,4)
    A = Yma(:,:,:,i);
    A = A(Ymask);
    A(A > -1 & A < 1) = nan;
    for j = 1:size(Ymb,4)
        B = Ymb(:,:,:,j);
        B = B(Ymask);
        B(B > -1 & B < 1) = nan;
        r = corrcoef(A,B,'rows','pairwise');
        if numel(r) == 1, continue; end
        R(i,j) = r(2);
    end
end

[mR,mRidx] = max(R);

T = table(mRidx(:),(1:length(mR))',mR(:),'VariableNames',{'ICA_A','ICA_B','R'});
fprintf('\nMatched Components...\n')
disp(T)


%% Write info file
infofile = fullfile(fileparts(Pma),'ICA_Matching_Result_RC.txt');
fid = fopen(infofile,'w+');
fprintf(fid,'Timestamp: %s\n\n',datestr(now));
fprintf(fid,'Group A\n\t%d Components, Mean: %s\n',size(spm_select('expand',Pma),1),Pma);
for i = 1:length(Psa), fprintf(fid,'\t%s\n',Psa{i}); end

fprintf(fid,'Group B\n\t%d Components, Mean: %s\n',size(spm_select('expand',Pmb),1),Pmb);
for i = 1:length(Psb), fprintf(fid,'\t%s\n',Psb{i}); end
fprintf(fid,'\nGroup A\tGroup B\tR\n');
for i = 1:size(T,1)
    fprintf(fid,'%d\t%d\t%0.5f\n',T.ICA_A(i),T.ICA_B(i),T.R(i));
end
fclose(fid);


%% Display results
f = findFigure('ICAGroupCorr');
figure(f);
imagesc(R);
axis square
colorbar
colormap jet
set(gca,'ydir','normal','clim',[-1 1]*max(abs(get(gca,'clim'))))
hold on
plot(xlim,ylim,'-k')

plot(1:length(mRidx),mRidx,'sk','markersize',15)

hold off

[~,Afn] = fileparts(Pma);
ylabel(Afn,'interpreter','none');
[~,Bfn] = fileparts(Pmb);
xlabel(Bfn,'interpreter','none');

title('Correlations Between Group ICA Components')




%% Reorganize GroupA to be like GroupB based on max correlation coefficents
Var = Vma(mRidx);
Yar = Yma(:,:,:,mRidx);

Pt = fullfile(spm('Dir'),'canonical','avg152T1.nii');
Vt = spm_vol(Pt);

for i = 1:length(Var)
    Var(i).fname = spm_file(Var(i).fname,'prefix','RC_');
    Var(i).n(1) = i;
    Var(i).descrip = sprintf('%s| ICA components from %s.nii reorganized by max correlation coef with %s.nii',datestr(now),Afn,Bfn);
    spm_write_vol(Var(i),Yar(:,:,:,i));
end

fprintf('Wrote: <a href="matlab: spm_check_registration(Var);">%s</a>\n',Var(1).fname)
fprintf('\t<a href="matlab: spm_check_registration([Var(1:6) Vmb(1:6)]'')">Compare first 6 components</a>\n')


%% Compute statistics for mean volumes
Patlas = 'D:\ownCloud\PROJECTS\MRI\FINALIZED\SlicerFinal8\CorticalAtlas-Split.nii';
Tareas = 'D:\ownCloud\PROJECTS\MRI\FINALIZED\conn_catlas.txt';
threshold = [-2 2];

clear Cma Cmb

ePma = spm_select('expand',Pma);
ePma = ePma(mRidx,:);
nj = size(ePma,1);

parfor j = 1:nj
    fprintf('Processing Group A mean, component %d of %d\n',j,nj)
    Cma(j) = voxelCoverage(ePma(j,:),threshold,Patlas,Tareas,false);
end

ePmb = spm_select('expand',Pmb);
nj = size(ePmb,1);

parfor j = 1:nj
    fprintf('Processing Group B mean, component %d of %d\n',j,nj)
    Cmb(j) = voxelCoverage(ePmb(j,:),threshold,Patlas,Tareas,false);
end

clear Cma_* Cmb_*

fn = fieldnames(Cma);
for i = 1:numel(Cma)
    for j = 1:length(fn)
        Cma_pos(i,j) = Cma(i).(fn{j}).pos.total / Cma(i).(fn{j}).pos.Area;
        Cma_neg(i,j) = Cma(i).(fn{j}).neg.total / Cma(i).(fn{j}).neg.Area;
    end    
end

for i = 1:numel(Cmb)
    for j = 1:length(fn)
        Cmb_pos(i,j) = Cmb(i).(fn{j}).pos.total / Cmb(i).(fn{j}).pos.Area;
        Cmb_neg(i,j) = Cmb(i).(fn{j}).neg.total / Cmb(i).(fn{j}).neg.Area;
    end    
end


%
Patlas = 'D:\ownCloud\PROJECTS\MRI\FINALIZED\SlicerFinal8\CorticalAtlas-Split.nii';
Tareas = 'D:\ownCloud\PROJECTS\MRI\FINALIZED\CATLAS_COLORS-SPLIT.txt';

fid = fopen(Tareas,'r');
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


for i = 1:size(Cmb_pos,1)
    mn = fullfile(pwd,sprintf('PosVoxCoverage_GroupB_ICA%03d.txt',i));
    fid = fopen(mn,'w+');
    for j = 1:length(area_names)
        m = round(Cmb_pos(i,j)*100);
        if ~m, m = 1; end
        fprintf(fid,'%d %s %d %d %d 255',j,area_names{j},cmap(m,:));
        if j < length(area_names), fprintf(fid,'\n'); end
    end
    fclose(fid);
    fprintf('Wrote: <a href="matlab: !explorer %s">%s</a>\n',mn,mn)

end


%% Compute statistics for backprojections to each subject
for i = 1:length(Psa)
    Psa{i} = spm_select('expand',Psa{i});
    Psa{i} = Psa{i}(mRidx,:);
end
for i = 1:length(Psb)
    Psb{i} = spm_select('expand',Psb{i});
end


clear Ca Cb
for i = 1:length(Psa)
    fprintf('Processing Group A subject %d of %d ',i,length(Psa))
    parfor j = 1:size(Psa{i},1)
        Ca(i,j) = voxelCoverage(Psa{i}(j,:),threshold,Patlas,Tareas,false);
        fprintf('.')
    end
    fprintf(' done\n')
end


for i = 1:length(Psb)
    fprintf('Processing Group B subject %d of %d ',i,length(Psb))
    parfor j = 1:size(Psb{i},1)
        Cb(i,j) = voxelCoverage(Psb{i}(j,:),threshold,Patlas,Tareas,false);
        fprintf('.')
    end
    fprintf(' done\n')
end

clear Ca_* Cb_*

fn = fieldnames(Ca);
for i = 1:numel(Ca)
    for j = 1:length(fn)
        Ca_pos(i,j) = Ca(i).(fn{j}).pos.total / Ca(i).(fn{j}).pos.Area;
        Ca_neg(i,j) = Ca(i).(fn{j}).neg.total / Ca(i).(fn{j}).neg.Area;
    end    
end

for i = 1:numel(Cb)
    for j = 1:length(fn)
        Cb_pos(i,j) = Cb(i).(fn{j}).pos.total / Cb(i).(fn{j}).pos.Area;
        Cb_neg(i,j) = Cb(i).(fn{j}).neg.total / Cb(i).(fn{j}).neg.Area;
    end    
end


Ca_pos = reshape(Ca_pos,[size(Ca) length(fn)]);
Ca_neg = reshape(Ca_neg,[size(Ca) length(fn)]);

Cb_pos = reshape(Cb_pos,[size(Cb) length(fn)]);
Cb_neg = reshape(Cb_neg,[size(Cb) length(fn)]);


Patlas = 'D:\ownCloud\PROJECTS\MRI\FINALIZED\SlicerFinal8\CorticalAtlas-Split.nii';
Tareas = 'D:\ownCloud\PROJECTS\MRI\FINALIZED\CATLAS_COLORS-SPLIT.txt';

fid = fopen(Tareas,'r');
Ta = textscan(fid,'%d %s %d %d %d %d');
fclose(fid);
area_names = Ta{2};

cmap = round(jet(100) * 255);

mCa_pos = squeeze(mean(Ca_pos));
sCa_pos = squeeze(std(Ca_pos));
mCb_pos = squeeze(mean(Cb_pos));
sCb_pos = squeeze(std(Cb_pos));


mCa_neg = squeeze(mean(Ca_neg));
sCa_neg = squeeze(std(Ca_neg));
mCb_neg = squeeze(mean(Cb_neg));
sCb_neg = squeeze(std(Cb_neg));


for i = 1:size(mCa_pos,1)
    mn = fullfile(pwd,sprintf('meanPosVoxCoverage_GroupA_ICA%03d.txt',i));
    fid = fopen(mn,'w+');
    for j = 1:length(area_names)
        m = round(mCa_pos(i,j)*100);
        if ~m, m = 1; end
        fprintf(fid,'%d %s %d %d %d 255',j,area_names{j},cmap(m,:));
        if j < length(area_names), fprintf(fid,'\n'); end
    end
    fclose(fid);
    fprintf('Wrote: <a href="matlab: !explorer %s">%s</a>\n',mn,mn)
end


for i = 1:size(mCb_pos,1)
    mn = fullfile(pwd,sprintf('meanPosVoxCoverage_GroupB_ICA%03d.txt',i));
    fid = fopen(mn,'w+');
    for j = 1:length(area_names)
        m = round(mCb_pos(i,j)*100);
        if ~m, m = 1; end
        fprintf(fid,'%d %s %d %d %d 255',j,area_names{j},cmap(m,:));
        if j < length(area_names), fprintf(fid,'\n'); end
    end
    fclose(fid);
    fprintf('Wrote: <a href="matlab: !explorer %s">%s</a>\n',mn,mn)
end


%% remap results onto the atlas
%  
% Vatlas = spm_vol(Patlas);
% Yatlas = spm_read_vols(Vatlas);
%  
% Y_z = zeros(Vatlas.dim,'single');
% Y_map = cell(size(Ca_pos,1),1);
% for i = 1:length(Y_map), Y_map{i} = Y_z; end
% for i = 1:size(dC_pos,2) % atlas regions
%     fprintf('Processing Atlas Region % 3d of %d',i,size(dC_pos,2))
%     ind = Yatlas == j;
%     for j = 1:size(dC_pos,1) % components
%         Y_map{j}(ind) = dC_pos(j,i);
%     end
%     fprintf(' done\n')
% end
% 













