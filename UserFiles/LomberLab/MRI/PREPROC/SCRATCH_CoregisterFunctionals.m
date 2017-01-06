%% Coregister functional data
clear matlabbatch

matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {'D:\DataProcessing\ICA_161127\NII\Biscotti\STRUCTURALS\T1_04.nii,1'};
matlabbatch{1}.spm.spatial.coreg.estwrite.source = {'D:\DataProcessing\ICA_161127\NII\Biscotti\RSS\RSS_01.nii,300'};

P = spm_select(1,'image','Select 4D ...');
P = spm_select('expand',P);
matlabbatch{1}.spm.spatial.coreg.estwrite.other = P;

e.cost_fun = 'nmi';
e.sep = [2 1 0.5];
e.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
e.fwhm = [7 7];
r.interp = 5;
r.wrap = [0 0 0];
r.mask = 0;
r.prefix = 'r';

matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions = e;
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions = r;

spm_jobman('run',matlabbatch);
