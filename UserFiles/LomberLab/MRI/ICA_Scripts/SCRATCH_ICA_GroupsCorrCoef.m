%% Compute correlation coefficeients for all compenents between groups from GIFT output

GroupAnii = 'H:\DataProcessing\GIFT_Output_161208\g161208_mean_component_ica_s_all_.nii';
GroupBnii = 'H:\DataProcessing\GIFT_ED_161213\ED_mean_component_ica_s_all_.nii';
% GroupAnii = 'H:\DataProcessing\GIFT_Output_161208\g161208_agg__component_ica_.nii';
% GroupBnii = 'H:\DataProcessing\GIFT_ED_161213\ED_agg__component_ica_.nii';

mask = 'C:\MATLAB\work\Plugins\MRI\spm12\canonical\cat_brain_mask.nii';

Va = spm_vol(GroupAnii);
Vb = spm_vol(GroupBnii);

Vmask = spm_vol(mask);

Ya = spm_read_vols(Va);
Yb = spm_read_vols(Vb);

Ymask = spm_read_vols(Vmask);
Ymask = logical(Ymask);

%% Compute Correlation Coefficients to find corresponding components between groups
R = zeros(size(Ya,4));
Rp = R;
for i = 1:size(Ya,4)
    A = Ya(:,:,:,i);
    A = A(Ymask);
    for j = 1:size(Yb,4)
        B = Yb(:,:,:,j);
        B = B(Ymask);
        r = corrcoef(A,B);
        R(i,j) = r(2);
    end
end

[mR,mRidx] = max(R);

T = table(mRidx(:),(1:length(mR))',mR(:),'VariableNames',{'ICA_A','ICA_B','R'});
fprintf('\nMatched Components...\n')
disp(T)

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

[~,Afn] = fileparts(GroupAnii);
ylabel(Afn,'interpreter','none');
[~,Bfn] = fileparts(GroupBnii);
xlabel(Bfn,'interpreter','none');

title('Correlations Between Group ICA Components')

%% Reorganize GroupA to be like GroupB based on max correlation coefficents
Var = Va(mRidx);
Yar = Ya(:,:,:,mRidx);

Pt = fullfile(spm('Dir'),'canonical','avg152T1.nii');
Vt = spm_vol(Pt);

for i = 1:length(Var)
    Var(i).fname = spm_file(Var(i).fname,'prefix','RC_');
    Var(i).n(1) = i;
    Var(i).descrip = sprintf('%s| ICA components from %s.nii reorganized by max correlation coef with %s.nii',datestr(now),Afn,Bfn);
    spm_write_vol(Var(i),Yar(:,:,:,i));
end

fprintf('Wrote: <a href="matlab: spm_check_registration(Var);">%s</a>\n',Var(1).fname)
fprintf('\t<a href="matlab: spm_check_registration([Var(1:6) Vb(1:6)]'')">Compare first 6 components</a>\n')



%% Compute atlas region coverage
Patlas = 'D:\ownCloud\PROJECTS\MRI\FINALIZED\SlicerFinal8\CorticalAtlas-Split.nii';
Tareas = 'D:\ownCloud\PROJECTS\MRI\FINALIZED\conn_catlas.txt';
threshold = [-2 2];

clear Ca Cb
parfor i = 1:length(Var)
    Pstat = sprintf('%s,%d',Var(i).fname,i);
    fprintf('Processing %d of %d: %s\n',i,length(Var),Pstat)
    Ca(i) = voxelCoverage(Pstat,threshold,Patlas,Tareas,false);
end


parfor i = 1:length(Vb)
    Pstat = sprintf('%s,%d',Vb(i).fname,i);
    fprintf('Processing %d of %d: %s\n',i,length(Vb),Pstat)
    Cb(i) = voxelCoverage(Pstat,threshold,Patlas,Tareas,false);
end


clear Ca_* Cb_*
fn = fieldnames(Ca);
for i = 1:length(Ca)
    for j = 1:length(fn)
        Ca_pos(i,j) = Ca(i).(fn{j}).pos.total;
        Ca_neg(i,j) = Ca(i).(fn{j}).neg.total;
        
        Cb_pos(i,j) = Cb(i).(fn{j}).pos.total;
        Cb_neg(i,j) = Cb(i).(fn{j}).neg.total;
    end    
end


% compute difference between groups for each component
dC_pos = Cb_pos - Ca_pos;
dC_neg = Cb_neg - Ca_neg;

%% remap results onto the atlas

Vatlas = spm_vol(Patlas);

Yatlas = spm_read_vols(Vatlas);

Y_z = zeros(size(Yatlas),'single');
Y_map = cell(size(dC_pos,1),1);
for i = 1:length(Y_map), Y_map{i} = Y_z; end
for i = 1:size(dC_pos,2) % atlas regions
    fprintf('Processing Atlas Region % 3d of %d',i,size(dC_pos,2))
    ind = Yatlas == j;
    for j = 1:size(dC_pos,1) % components
        Y_map{j}(ind) = dC_pos(j,i);
    end
    fprintf(' done\n')
end

for i= 1:length(Y_map)
    
    
end




























