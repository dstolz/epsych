%% 7 Take a look at T1s with the pattern 'rm*00.nii'
% D = rdir('**\STRUCTURALS\rm*00.nii');
% P = {D.name}';
P = getFiles('**\STRUCTURALS\rmT1_00.nii');
Pt = fullfile(spm('Dir'),'canonical','avg152T1.nii');
Ptpm = fullfile(spm('Dir'),'tpm','TPM.nii');

spm_check_registration(char([{Pt}; {[Ptpm ',1']}; P]));

%% zero out any NaN or negative voxels

for i = 1:length(P)
    V = spm_vol(P{i});
    Y = spm_read_vols(V);
    ind = Y < 100 | isnan(Y);
    Y(ind) = 0;
    spm_write_vol(V,Y);
end


%% Segment

F = spm_figure('FindWin','Interactive');
if isempty(F)
    F = spm_figure('Create','Interactive','SPM','on');
    set(F,'position',[108 045 400 395]);
end
spm_figure('Focus',F);

clear p matlabbatch

p.channel.vols = P;
p.channel.biasreg = 0.001;
p.channel.biasfwhm = 60;
p.channel.write = [1 1];
p.tissue(1).tpm = {[Ptpm ',1']};
p.tissue(1).ngaus = 1;
p.tissue(1).native = [1 1];
p.tissue(1).warped = [1 1];
p.tissue(2).tpm = {[Ptpm ',2']};
p.tissue(2).ngaus = 1;
p.tissue(2).native = [1 1];
p.tissue(2).warped = [1 1];
p.tissue(3).tpm = {[Ptpm ',3']};
p.tissue(3).ngaus = 2;
p.tissue(3).native = [1 1];
p.tissue(3).warped = [1 1];
p.tissue(4).tpm = {[Ptpm ',4']};
p.tissue(4).ngaus = 3;
p.tissue(4).native = [1 1];
p.tissue(4).warped = [1 1];
p.warp.mrf = 0;
p.warp.cleanup = 0;
p.warp.reg = [0 0.001 1 0.05 0.2];
p.warp.affreg = 'subj';
p.warp.fwhm = 0;
p.warp.samp = 1;
p.warp.write = [1 1];
matlabbatch{1}.spm.spatial.preproc = p;

% Note: had to change default job.warp.vox value from 1.5 to 0.5 in
% run_job/spm_preproc_run (line 67)
spm_jobman('run',matlabbatch);

%
Pwc = P;
Pc = P;
for i = 1:numel(P)
    for j = 1:4
        Pwc{i,j} = spm_file(P{i},'prefix',sprintf('wc%d',j));
        Pc{i,j}  = spm_file(P{i},'prefix',sprintf('c%d',j));
    end
end

% spm_check_registration(char([{Pt}; {[Ptpm ',1']}; Pc(:,1)]));


%% Smooth structurals with 1mm^3 FWHM
clear s matlabbatch

% s.data = Pwc(:);
s.data = Pc(:);
s.fwhm = [1 1 1];
s.dtype = 0;
s.im = 0;
s.prefix = 's';
matlabbatch{1}.spm.spatial.smooth = s;

spm_jobman('run',matlabbatch);

% Ps = Pwc;
Ps = Pc;
for i = 1:numel(Ps)
    Ps{i} = spm_file(Ps{i},'prefix','s');
end

spm_check_registration(char([{Pt}; {[Ptpm ',1']}; Ps(:,1)]));










