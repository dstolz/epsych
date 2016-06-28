% Create Tissue Probability Maps based on structural scan using mixture of
% gaussians and expectation-maximization to estimate tissue classes.  Once completed,
% manually assign tissue classes as GM, WM, CSF, NotBrain as the first four volumes
% in a 4D Tissue Probability Map NIfTI file.  These TPM files can then be used in
% the generation of tissue templates using a procedure like DARTEL.
%
% Uses functions from SPM12
%
% Daniel.Stolzberg@gmail.com 6/2016

%% File

[T1fname,sts] = spm_select(1,'image','Select a volume');

V = spm_vol(T1fname);



%% Cleanup and smoothing


[pn,fn,fext] = fileparts(V.fname);
smfname = fullfile(pn,['cleaned_' fn fext]);

% smooth T1
spm_smooth(T1fname,smfname,[0.5 0.5 0.5]);

% remove negative voxels that may have been generated during realignment interpolation
Vt = spm_vol(smfname);
Y = spm_read_vols(Vt);
Y(Y<10|isnan(Y)) = 0;
spm_write_vol(Vt,Y);

Y = spm_read_vols(V);
Y(Y<0|isnan(Y)) = 0;
spm_write_vol(V,Y);

spm_check_registration(V,Vt)

%% Fit Gaussian Mixture to Voxel Intensities


mincomp = 8;
maxcomp = 13;
Replicates = 3;
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


%% Segment


gmBest = gm{bestModelIdx}; % use best fit
% gmBest = gm{5};

xx = linspace(0,max(Y(:)),250)';

figure(findFigure('Interactive'))
subplot(212)
plot(xx,pdf(gmBest,xx),'k','linewidth',2);

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


spm_check_registration(char({T1fname Vc.fname fnames{:}}))



%% Define segments
% use the registration window to identify tissue types
seg_GM = [3 5 7 9];
seg_WM = [2 4];
seg_CSF = [13];
seg_NotBrain = [1 6 8 10 11 12];

[pn,fn,fext] = fileparts(V.fname);

Vs = V;
Vs.descrip = 'TPMs: GM,WM,CSF,NotBrain';
Vs.private.dat.dim(end+1) = 3;
Vs.fname = fullfile(pn,['TPM_' fn fext]);

fnames = cell(1,4);
% GM
Vs.n = [1 1];
Ys = reshape(sum(p(:,seg_GM),2),size(Y));
spm_write_vol(Vs,Ys);
fnames{1} = sprintf('%s,%d',Vs.fname,1);

% WM
Vs.n = [2 1];
Ys = reshape(sum(p(:,seg_WM),2),size(Y));
spm_write_vol(Vs,Ys);
fnames{2} = sprintf('%s,%d',Vs.fname,2);

% CSF
% if ~isempty(seg_CSF)
    Vs.n = [3 1];
    Ys = reshape(sum(p(:,seg_CSF),2),size(Y));
    spm_write_vol(Vs,Ys);
    fnames{3} = sprintf('%s,%d',Vs.fname,3);
% end

% NotBrain
Vs.n = [4 1];
Ys = reshape(sum(p(:,seg_NotBrain),2),size(Y));
spm_write_vol(Vs,Ys);
fnames{4} = sprintf('%s,%d',Vs.fname,4);


spm_check_registration(char({T1fname fnames{:}}));










