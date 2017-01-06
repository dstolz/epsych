% 5. Use Coregistration of masked T1 to Template brain to finish reorientation



P = spm_select(1,'image','Select masked T1...',{},pwd,'^m.*');



fprintf(2,'***** ENSURE THE ORIGIN OF THE IMAGE IS NEAR ANTERIOR COMMISURE **********\n')
fprintf(2,'***** IF THE T1 NEEDS ADJUSTMENT, THEN BE SURE TO APPLY REORIENTATION TO ALL STRUCTURAL AND FUNCTIONAL VOLUMES **********\n')

spm_image('display',P);


%%
Proot = fileparts(fileparts(P));
D = rdir(fullfile(Proot,'**\m*.nii'));
Pd = {D.name}';
i = cellfun(@(a) (strfind(a,'VOI')),Pd,'UniformOutput',false);
Pd(~cellfun(@isempty,i)) = [];
disp(Pd)


Pd = spm_select('expand',Pd);

e.ref = {fullfile(spm('Dir'),'canonical','avg152T1.nii')};
e.source = {P};
e.other = Pd;
e.eoptions.cost_fun = 'nmi';
e.eoptions.sep = [4 2 1 0.5];
e.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
e.eoptions.fwhm = [7 7];
e.roptions.interp = 5;
e.roptions.wrap = [0 0 0];
e.roptions.mask = 1;
e.roptions.prefix = 'r';
clear matlabbatch
matlabbatch{1}.spm.spatial.coreg.estwrite = e;


F = spm_figure('FindWin','Interactive');
if isempty(F)
    F = spm_figure('Create','Interactive','SPM','on');
    set(F,'position',[108 045 400 395]);
end
spm_figure('Focus',F);

spm_jobman('run',matlabbatch);
