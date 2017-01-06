%% Dartel warp

clear W matlabbatch

Subjs = getSubjects;
sel = listdlg('ListString',Subjs);
Subjs = Subjs(sel);


for i = 1:length(Subjs)
    D = dir(fullfile(getSubpath('STRUCTURALS',Subjs{i}),'sc*'));
    for j = 1:length(D)
        W.images{j}{i,1} = fullfile(getSubpath('STRUCTURALS',Subjs{i}),D(j).name);
    end
end

W.settings.rform = 0;
W.settings.param(1).its = 3;
W.settings.param(1).rparam = [4 2 1e-06];
W.settings.param(1).K = 0;
W.settings.param(1).template = {fullfile(spm('Dir'),'tpm','s4TPM.nii')};
W.settings.param(2).its = 3;
W.settings.param(2).rparam = [2 1 1e-06];
W.settings.param(2).K = 0;
W.settings.param(2).template = {fullfile(spm('Dir'),'tpm','s3TPM.nii')};
W.settings.param(3).its = 3;
W.settings.param(3).rparam = [1 0.5 1e-06];
W.settings.param(3).K = 1;
W.settings.param(3).template = {fullfile(spm('Dir'),'tpm','s2TPM.nii')};
W.settings.param(4).its = 6;
W.settings.param(4).rparam = [0.5 0.25 1e-06];
W.settings.param(4).K = 2;
W.settings.param(4).template = {fullfile(spm('Dir'),'tpm','s1TPM.nii')};
W.settings.param(5).its = 10;
W.settings.param(5).rparam = [0.25 0.125 1e-06];
W.settings.param(5).K = 4;
W.settings.param(5).template = {fullfile(spm('Dir'),'tpm','TPM.nii')};
W.settings.optim.lmreg = 0.01;
W.settings.optim.cyc = 8;
W.settings.optim.its = 3;


matlabbatch{1}.spm.tools.dartel.warp1 = W;

spm_jobman('run',matlabbatch);

%% Warp structural images using u_sc1rmT1_00.nii

clear matlabbatch C

Subjs = getSubjects;
sel = listdlg('ListString',Subjs);
Subjs = Subjs(sel);

C.jactransf = 0;
C.K = 9;
C.interp = 5;

for i = 1:length(Subjs)
    spath = getSubpath('STRUCTURALS',Subjs{i});
    F = dir(fullfile(spath,'u_*'));
    Fn = cellfun(@(a) (fullfile(spath,a)),{F.name}','UniformOutput',false);
    
    R = dir(fullfile(spath,'rmT1_00.nii'));
    Rn = cellfun(@(a) (fullfile(spath,a)),{R.name}','UniformOutput',false);
    
    C.images = {[]};
    C.flowfields = Fn;
    for j = 1:length(Rn)
        C.images{1} = Rn(j);
        matlabbatch{1}.spm.tools.dartel.crt_warped = C;
        spm_jobman('run',matlabbatch);
    end
end

wR = rdir('**\wrmT1_00.nii');
wRn = {wR.name}';

Pt = fullfile(spm('Dir'),'canonical','avg152T1.nii');
spm_check_registration(char([{Pt}; wRn]))


%% Warp functional images to template space

clear matlabbatch C



Subjs = getSubjects;
sel = listdlg('ListString',Subjs);
Subjs = Subjs(sel);



C.jactransf = 0;
C.K = 9;
C.interp = 5;

for i = 1:length(Subjs)
    spath = getSubpath('STRUCTURALS',Subjs{i});
    F = dir(fullfile(spath,'u_*'));
    Fn = {fullfile(spath,F.name)};
    
    R = rdir(fullfile('**',Subjs{i},'\RSS\srm*.nii'));
    Rn = {R.name}';
    
    
    C.images = {[]};
    C.flowfields = Fn;
    for j = 1:length(Rn)
        fprintf('\n\n\nWarping %s with %s\n',Rn{j},char(C.flowfields))
        
        C.images{1} = Rn(j);
        matlabbatch{1}.spm.tools.dartel.crt_warped = C;
        spm_jobman('run',matlabbatch);
        
        wp = fullfile(getSubpath('STRUCTURALS',Subjs{i}),'wsrm*.nii');
        
        [s,m,mid] = movefile(wp,fileparts(Rn{j}),'f');
        assert(s,m,mid)
        
    end
    
end










