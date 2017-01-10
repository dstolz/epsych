%% Split up preprocessed denoised data from CONN into sessions for GIFT

sourcedir = 'H:\DataProcessing\conn_project_161208\results\preprocessing';
targdir = 'H:\DataProcessing\PREPROC\DENOISED_DATA';
P = dir(fullfile(sourcedir,'*.nii'));
P = cellfun(@(a) (fullfile(sourcedir,a)),{P.name}','uniformoutput',false);

% P(1:8) = [] % only process newly added subject
% P(2:8) = []
%%
for k = 1:length(P)
    [~,sn] = fileparts(P{k});
    i = find(sn=='_',1,'last');
    sn = str2double(sn(i-3:i-1));
    fprintf('Splitting Subject %03d (%d of %d) ...',sn,k,length(P))
    V = spm_vol(P{k});
    for i = 1:600
        Y = spm_read_vols(V(i));
        V(i).fname = fullfile(targdir,sprintf('dSubject%02d_1.nii',sn));
        spm_write_vol(V(i),Y);
    end
    for i = 601:1200
        Y = spm_read_vols(V(i));
        V(i).n(1) = V(i).n(1) - 600;
        V(i).fname = fullfile(targdir,sprintf('dSubject%02d_2.nii',sn));
        spm_write_vol(V(i),Y);
    end
    fprintf(' done\n')
end




