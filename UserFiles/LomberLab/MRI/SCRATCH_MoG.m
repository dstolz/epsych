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

[filename,sts] = spm_select(1,'image','Select a volume');

V = spm_vol(filename);



%% Cleanup and smoothing

Y = spm_read_vols(V);



% filter and smooth
gw = gausswin(5);
[~,wn] = wiener2(Y(:,:,1),[5 5]);
for i = 1:size(Y,3)
    Y(:,:,i) = wiener2(Y(:,:,i),[5 5],wn);
%     Y(:,:,i) = medfilt2(Y(:,:,i));
    Y(:,:,i) = conv2(Y(:,:,i),gw,'same');
end

% remove stray voxels
bY = false(size(Y));
bY(Y>0) = true;
stats = regionprops(bY,{'PixelIdxList','Area'});
clear bY
ind = [stats.Area] == max([stats.Area]);
Y(~ismember((1:numel(Y)),stats(ind).PixelIdxList)) = 0;

Vt = V;
[pn,fn,fext] = fileparts(V.fname);
Vt.fname = fullfile(pn,['cleaned_' fn fext]);
spm_write_vol(Vt,Y);
spm_check_registration(V,Vt)

%% Fit Gaussian Mixture to Voxel Intensities


mincomp = 3;
maxcomp = 10;
Replicates = 5;
MaxIter = 1000;



ncomp = maxcomp-mincomp+1;
options = statset('MaxIter',MaxIter,'Display','final');
gm = cell(ncomp,1);
AIC = nan(ncomp,1);

f = spm_figure('GetWin','Interactive');
spm_figure('Clear','Interactive');
clf(f);
figure(f);
ax = subplot(211);
drawnow

yind = Y(:) > 0;
for i = 1:ncomp
    gm{i} = fitgmdist(Y(yind),mincomp+i-1,'Options',options,'Replicates',Replicates);
    fprintf('\nGM Mean for %i Components\n',mincomp+i-1)
    Mu = gm{i}.mu
    fprintf('\tAIC = %g\n',gm{i}.AIC)
    AIC(i) = gm{i}.AIC;
    plot(ax,mincomp:maxcomp,AIC,'-o');
    ylabel('AIC')
    xlabel('# Components')
    drawnow
end
[minAIC, bestModelIdx] = min(AIC);
hold(ax,'on');
plot(bestModelIdx+mincomp-1,AIC(bestModelIdx),'or','markerfacecolor','r')
hold(ax,'off');

%% Segment


gmBest = gm{bestModelIdx}; % use best fit
% gmBest = gm{5};

xx = linspace(0,max(Y(:)),250)';

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
for j = 1:nmu
    
%     ind = M(:,j) <= threshold; % Mahalanobis
    ind = C == j; % Cluster
    
%     Yc(ind) = Y(ind); % Mahalanobis
    Yc(ind) = j; % Cluster

    Vp(j).private.dat.dim(end+1) = nmu;
    Vp(j).n = [j 1];
    Vp(j).fname = 'POSTERIORS.nii';
    spm_write_vol(Vp(j),reshape(p(:,j),size(Y)));
    
    d = gmBest.PComponents(j)*normpdf(xx,gmBest.mu(j),sqrt(gmBest.Sigma(j)));
    line(xx,d,'color',cs(j,:),'linewidth',2);
    
    
end

Vc = V;
Vc.fname = 'CLUSTERS.nii';
spm_write_vol(Vc,Yc);

images = {V.fname; Vc.fname};
for i = 1:length(Vp)
    images{end+1} = [Vp(i).fname,num2str(i,',%d')];
end
spm_check_registration(char(images))



%% Define segments
% use the registration window to identify tissue types
seg_GM = [3 4 10];
seg_WM = [7 9];
seg_CSF = [];
seg_NotBrain = [1 2 5 6 8];

[pn,fn,fext] = fileparts(V.fname);

Vs = V;
Vs.descrip = 'TPMs: GM,WM,CSF,NotBrain';
Vs.private.dat.dim(end+1) = 3;
Vs.fname = fullfile(pn,['TPM_' fn fext]);

% GM
Vs.n = [1 1];
Ys = reshape(sum(p(:,seg_GM),2),size(Y));
spm_write_vol(Vs,Ys);

% WM
Vs.n = [2 1];
Ys = reshape(sum(p(:,seg_WM),2),size(Y));
spm_write_vol(Vs,Ys);

% CSF
if ~isempty(seg_CSF)
    Vs.n = [3 1];
    Ys = reshape(sum(p(:,seg_CSF),2),size(Y));
    spm_write_vol(Vs,Ys);
end

% NotBrain
Vs.n = [4 1];
Ys = reshape(sum(p(:,seg_NotBrain),2),size(Y));
spm_write_vol(Vs,Ys);


images = {V.fname; Vc.fname};
for i = 1:4
    images{end+1} = [Vs.fname,num2str(i,',%d')];
end
spm_check_registration(char(images))










