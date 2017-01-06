%% Realign and then smooth functionals
% Subjs = getSubjects;
Subjs = {'Bass','Butch'};
F = getFncDirs';

clear e r
e.quality   = 1;
e.sep       = 1;
e.fwhm      = 2;
e.rtm       = 0;
e.interp    = 5;
e.wrap      = [0 0 0];
e.weight    = '';
% r.which     = [2 0];
% r.interp    = 5;
% r.wrap      = [0 0 0];
% r.mask      = 1;
% r.prefix    = 'r';

for f = F   
    
    clear matlabbatch
    k = 1;
    for i = 1:length(Subjs)
        d = rdir(fullfile('**\',Subjs{i},'\',char(f),'\rm*.nii'));
        if isempty(d)
            fprintf('Did not find any "%s" functional sessions for "%s"\n',char(f),Subjs{i})
            continue
        end
        P = {d.name}';
        S = [];
        idx = find(~cellfun(@isempty,strfind(P,Subjs{i})));
        
        for j = 1:length(idx)
            S{j} = spm_select('expand',P(idx(j)));
        end
        
        
        matlabbatch{k}.spm.spatial.realign.estimate.data = S;
        matlabbatch{k}.spm.spatial.realign.estimate.eoptions = e;
%         matlabbatch{k}.spm.spatial.realign.estwrite.roptions = r;
        
        k = k + 1;
    end
    
    h = spm_figure('FindWin','Interactive');
    if isempty(h)
        h = spm_figure('Create','Interactive','SPM','on');
        set(h,'position',[108 045 400 395]);
    end
    spm_figure('Focus',h);
    
    spm_jobman('run',matlabbatch);
    
end


%% Smooth functional volumes
clear matlabbatch s

s.fwhm  = [2 2 2];
s.dtype = 0;
s.im    = 0;
s.prefix = 's';

for S = Subjs(:)'
%     P = rdir(fullfile('**\',char(S),'RSS\rrm*.nii'));
    P = rdir(fullfile('**\',char(S),'RSS\rm*.nii'));
    P = {P.name}';
    P = spm_select('expand',P);
    
    fprintf('\nSmoothing %d files for %s\n',length(P),char(S))
    
    s.data  = P;
    matlabbatch{1}.spm.spatial.smooth = s;

    h = spm_figure('FindWin','Interactive');
    if isempty(h)
        h = spm_figure('Create','Interactive','SPM','on');
        set(h,'position',[108 045 400 395]);
    end
    spm_figure('Focus',h);
    
    spm_jobman('run',matlabbatch);
        
end

