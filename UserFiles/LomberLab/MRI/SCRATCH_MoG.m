% Create Tissue Probability Maps based on structural scan using mixture of
% gaussians and expectation-maximization to estimate tissue classes.  Once completed,
% manually assign tissue classes as GM, WM, CSF, NotBrain as the first four volumes
% in a 4D Tissue Probability Map NIfTI file.  These TPM files can then be used in
% the generation of tissue templates using a procedure like DARTEL.
%
% Uses functions from SPM12
%
% Daniel.Stolzberg@gmail.com 6/2016



[T1fname,sts] = spm_select([1 inf],'image','Select volume(s)',{},pwd,'^r');

Vm = spm_vol(T1fname);


for m = 1:length(Vm)
    V = Vm(m);
    
%     %% Cleanup and smoothing
    
    
    [pn,fn,fext] = fileparts(V.fname);
    smfname = fullfile(pn,['cleaned_' fn fext]);
    
    
    Y = spm_read_vols(V);
    
    Vt = V;
    Vt.fname = smfname;
    
    % remove negative voxels that may have been generated during realignment interpolation
    Y(Y<10|isnan(Y)) = 0;
    
    vvoxsiz = getVoxelSize(Vt);
    Y = medfilt3(Y,[2 2 2]);
    % smooth T1
    % spm_smooth(T1fname,smfname,[0.5 0.5 0.5]);
    
    spm_write_vol(Vt,Y);
    
    spm_check_registration(V,Vt)
    
%     %% Fit Gaussian Mixture to Voxel Intensities
    
    
    mincomp = 6;
    maxcomp = 15;
    Replicates = 5;
    MaxIter = 1000;
    
    Y = spm_read_vols(Vt);
    
    ncomp = maxcomp-mincomp+1;
    options = statset('MaxIter',MaxIter,'Display','final');
    gm = cell(ncomp,1);
    AIC = nan(ncomp,1);
    
    f = spm_figure('GetWin','Interactive');
    spm_figure('Clear','Interactive');
    figure(f);
    
    ax = subplot(211);
    haic  = line(0,0,'marker','o','parent',ax);
    haicr = line(0,0,'marker','o','markerfacecolor','r','parent',ax);
    cs = lines(maxcomp);
    ylabel(ax,'AIC')
    xlabel(ax,'# Components')
    yind = Y(:) > 0;
    xx = linspace(0,max(Y(:)),250)';
    for i = 1:ncomp
        gm{i} = fitgmdist(Y(yind),mincomp+i-1,'Options',options,'Replicates',Replicates);
        fprintf('\nGM Mean for %i Components\n',mincomp+i-1)
        Mu = gm{i}.mu
        fprintf('\tAIC = %g\n',gm{i}.AIC)
        
        AIC(i) = gm{i}.AIC;
        set(haic,'xdata',mincomp:maxcomp,'ydata',AIC);
        
        [minAIC, bestModelIdx] = min(AIC);
        set(haicr,'xdata',bestModelIdx+mincomp-1,'ydata',AIC(bestModelIdx))
        
        subplot(212)
        cla
        plot(xx,pdf(gm{i},xx),'k','linewidth',2);
        hold on
        for j = 1:length(gm{i}.mu)
            d = gm{i}.PComponents(j)*normpdf(xx,gm{i}.mu(j),sqrt(gm{i}.Sigma(j)));
            line(xx,d,'color',cs(j,:),'linewidth',2);
        end
        hold off
        set(gca,'xscale','log')
        axis tight
        drawnow
    end
    
    save(fullfile(pn,['MoG_' fn '.mat']));
end
%% Segment
% load(fullfile(pn,['MoG_' fn '.mat']));
[fn,pn] = uigetfile({'MoG*.mat','*.mat'});
load(fullfile(pn,fn))

gmBest = gm{bestModelIdx}; % use best fit
% gmBest = gm{9};

xx = linspace(0,max(Y(:)),250)';

f = spm_figure('GetWin','Interactive');
spm_figure('Clear','Interactive');
figure(f);
subplot(212)
plot(xx,pdf(gmBest,xx),'k','linewidth',2);
set(gca,'xscale','log');

nmu = length(gmBest.mu);

cs = lines(nmu);

Yc = nan(size(Y),'like',Y(1));

% M = mahal(gmBest,Y(:)); % Mahalanobis
C = cluster(gmBest,Y(:));

threshold = sqrt(chi2inv(0.99,2));

Vp(1:nmu) = V;


p = posterior(gmBest,Y(:));

delete POSTERIORS.nii
    
subplot(212)
fnames = cell(1,nmu);
for j = 1:nmu
    
%     ind = M(:,j) <= threshold; % Mahalanobis
    ind = C == j; % Cluster
    
%     Yc(ind) = Y(ind); % Mahalanobis
    Yc(ind) = j; % Cluster

    Vp(j).private.dat.dim(end+1) = nmu;
    Vp(j).n = [j 1];
    Vp(j).fname = 'POSTERIORS.nii';
    spm_write_vol(Vp(j),reshape(p(:,j),size(Y)));
    fnames{j} = sprintf('%s,%d',Vp(j).fname,j);
    
    d = gmBest.PComponents(j)*normpdf(xx,gmBest.mu(j),sqrt(gmBest.Sigma(j)));
    line(xx,d,'color',cs(j,:),'linewidth',2);
    
    
end

Vc = V;
Vc.fname = 'CLUSTERS.nii';
spm_write_vol(Vc,Yc);


spm_check_registration(char({T1fname(m,:) Vc.fname fnames{:}}))



%% Define segments
% use the registration window to identify tissue types
% bass
seg_GM = [1 3 4 6 8 9 13];
seg_WM = [2 5 11 12];
seg_CSF = [7 10];

% blackforest
% seg_GM = [1 3 10];
% seg_WM = [9 11];
% seg_CSF = [4];

% CC
% seg_GM = [7 11 13 15];
% seg_WM = [6 9];
% seg_CSF = [3 5];

% leia
% seg_GM = [4 9];
% seg_WM = [1 3];
% seg_CSF = [11];

% luke
% seg_GM = [4 11 14];
% seg_WM = [9 12];
% seg_CSF = [5 8];

% marie
% seg_GM = [3 5 9 15];
% seg_WM = [1 6 8];
% seg_CSF = [12];

% minnow
% seg_GM = [3 5 6];
% seg_WM = [10 11 12];
% seg_CSF = [7 14];

% % paul
% seg_GM = [5 6 10 11];
% seg_WM = [2 4];
% seg_CSF = [1];

% % halibut
% seg_GM = [2 3 4 6 7 12 13 15];
% seg_WM = [8 14];
% seg_CSF = [9];

% trout
% seg_GM = [2 4 6 7 9 10 11 12 13 14];
% seg_WM = [1 5 15];
% seg_CSF = [3];

[pn,fn,fext] = fileparts(V.fname);

Vs = V;
Vs.descrip = 'TPMs: GM,WM,CSF,NotBrain';
Vs.private.dat.dim(end+1) = 3;
Vs.fname = fullfile(pn,['TPM_' fn fext]);

fnames = cell(1,4);
% GM
Vs.n = [1 1];
Ygm = reshape(sum(p(:,seg_GM),2),size(Y));
spm_write_vol(Vs,Ygm);
fnames{1} = sprintf('%s,%d',Vs.fname,1);

% WM
Vs.n = [2 1];
Ywm = reshape(sum(p(:,seg_WM),2),size(Y));
spm_write_vol(Vs,Ywm);
fnames{2} = sprintf('%s,%d',Vs.fname,2);

% CSF
Vs.n = [3 1];
Ycsf = reshape(sum(p(:,seg_CSF),2),size(Y));
% enable next 4 lines if csf is captured with background
Vbm = spm_vol('D:\ownCloud\PROJECTS\MRI\DARTEL_new\brainmask.nii');
Ybm = spm_read_vols(Vbm);
Ybm = Ybm ./ max(Ybm(:)); 
Ycsf = Ycsf .* Ybm;
spm_write_vol(Vs,Ycsf);
fnames{3} = sprintf('%s,%d',Vs.fname,3);


% NotBrain
Ynb = Ygm+Ywm+Ycsf;
Yc = false(size(Ynb));
IM = Ynb > Ynb(1);
for j = 1:size(Ynb,3)
    Yc(:,:,j) = imfill(IM(:,:,j),'holes');
end
% Yc = 1-(Ynb.*Yc);
Yc = 1-Yc;
Yc = smooth3(Yc,'gaussian',[3 3 3]);
Yc(Yc<0) = 0;
Vs.n = [4 1];
spm_write_vol(Vs,Yc);
fnames{4} = sprintf('%s,%d',Vs.fname,4);


spm_check_registration(char({T1fname(m,:) fnames{:}}));










