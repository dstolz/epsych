%% GIFT Subjects

% load('gSubject.mat')
conn_preproc_dir = 'H:\DataProcessing\conn_project_170107\results\preprocessing';

d = dir(fullfile(conn_preproc_dir,'niftiDATA_Subject*.nii'));

dn = cellfun(@(a) (fullfile(conn_preproc_dir,a)),{d.name},'uniformoutput',false);


SPMFiles = struct('name',[]);
modalityType = 'fMRI';
numOfSess = 2;
numOfSub = length(dn);
%
files = struct('name',[]);
for i = 1:numel(d)
    p = spm_select('expand',dn{i});
    files(end+1).name = p(1:600,:);
    files(end+1).name = p(601:end,:);
end
files(1) = [];

save('gSubject.mat','SPMFiles','modalityType','numOfSess','numOfSub','files');