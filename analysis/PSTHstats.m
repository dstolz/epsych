function A = PSTHstats(PSTH,bins,varargin)
% A = PSTHstats(PSTH,bins,varargin)
% 
% PSTH is an M by N matrix with each row a sample (bin) and each column a
% different condition (ex, sound level).
% 
% 
% alpha  ... 0.01;
% prewin ... [-0.05 0];
% rspwin ... [0 0.05];
% levels ... 1:n
%
% Daniel.Stolzberg@gmail.com 

[M,N] = size(PSTH);

alpha  = 0.01;
prewin = [-0.05 0];
rspwin = [0 0.05];
levels = 1:size(PSTH,2);

ParseVarargin({'alpha','prewin','rspwin','tail','levels'},[],varargin);

[levels,i] = sort(levels,'ascend');
PSTH = PSTH(:,i);

A.levels = levels;

preIND = bins >= prewin(1) & bins < prewin(2);
rspIND = bins >= rspwin(1) & bins < rspwin(2);
PRE = PSTH(preIND,:);
RSP = PSTH(rspIND,:);

ncols = size(PSTH,2);

% Peak Response
[mag,peakidx] = max(RSP);
rspidx = find(rspIND);
lat = bins(rspidx(peakidx));
[h,p,ci,stats] = ttest2(PRE,mag,alpha,'left');
A.peak.magnitude   = mag; %#ok<*AGROW>
A.peak.latency     = lat;
h(isnan(h)) = 0;
A.peak.rejectnullh = logical(h);
A.peak.p           = p;
A.peak.ci          = -ci;
A.peak.stats       = stats;

% Mean Response
[h,p,ci,stats] = vartest2(PRE,RSP,alpha,'left');
mag = mean(RSP);
A.response.magnitude   = mag;
h(isnan(h)) = 0;
A.response.rejectnullh = logical(h);
A.response.p           = p;
A.response.ci          = ci;
A.response.stats       = stats;


% Response Onset/Offset
threshlevels = 10:20:90;
thresh = A.peak.magnitude' * threshlevels / 100;
rRSP = RSP(2:end,:) > RSP(1:end-1,:); % rising slope samples
fRSP = RSP(2:end,:) < RSP(1:end-1,:); % falling slope samples
for i = 1:ncols
    for j = 1:length(threshlevels)
        f = sprintf('onset%dpk',threshlevels(j));       
        if peakidx(i) > size(rRSP,1), peakidx(i) = size(rRSP,1); end
        sigind = RSP(1:peakidx(i),i) >= thresh(i,j) & rRSP(1:peakidx(i),i);
        if any(sigind)
            bigrun = findConsecutive(sigind,1);
            A.response.(f)(i) = bins(rspidx(bigrun(1)));
%             idx = find(sigind,1,'first');
%             A.response.(f)(i) = bins(rspidx(idx));
        else
            A.response.(f)(i) = nan;
        end
        
        f = sprintf('offset%dpk',threshlevels(j));
        sigind = RSP(peakidx(i):end-1,i) >= thresh(i,j) & fRSP(peakidx(i):end,i);
        if any(sigind)
            bigrun = findConsecutive(sigind,1);
            A.response.(f)(i) = bins(rspidx(peakidx(i)+bigrun(2)));
%             idx = peakidx(i) + find(sigind,1,'last') - 1;
%             A.response.(f)(i) = bins(rspidx(idx));
        else
            A.response.(f)(i) = nan;
        end
    end
end



% Peak IO features
i = find(A.peak.rejectnullh,1);
A.peak.features.threshold = levels(i);
[m,i] = max(A.peak.magnitude);
A.peak.features.maxmag    = m;
A.peak.features.bestlevel = levels(i);

if A.peak.features.bestlevel == levels(end)
    p = polyfit(levels',A.peak.magnitude,1);
else
    p = polyfit(levels(i:end)',A.peak.magnitude(i:end),1);
end
A.peak.features.monotonicity = p(1);
A.peak.features.yintercept   = p(2);


% Response IO features
i = find(A.response.rejectnullh,1);
A.response.features.threshold = levels(i);
[m,i] = max(A.response.magnitude);
A.response.features.maxmag    = m;
A.response.features.bestlevel = levels(i);

if A.response.features.bestlevel == levels(end)
    p = polyfit(levels',A.response.magnitude,1);
else
    p = polyfit(levels(i:end)',A.response.magnitude(i:end),1);
end
A.response.features.monotonicity = p(1);
A.response.features.yintercept   = p(2);








