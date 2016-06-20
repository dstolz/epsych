function newdata = chunkwiseDeline(data,sr,freqs,freqrange,chunksize,showOutput)
% newdata = chunkwiseDeline(data,sr,freqs,chunksize)
% Removes line noise from a signal in small chunks of data.
% data - an n x 1 vector containing continuous data
% sr - scalar, the sampling rate of the signal
% freqs - a vector of frequencies around which to remove line noise,
%        for example [60,180]
% freqrange (optional) - a scalar specifying the range of frequencies
%                       to use for fitting a parametric function for
%                       line noise (default: 2Hz)
% chunksize (optional) - the size of a chunk in seconds (default : 60)
% showOutput (opt)     - if true, show plots of fits (default: false)
% Algo: for every block of data, take abs(fft(dat)). Then extract the
%      vector corresponding to [freq(1)-freqrange, freq(1)+freqrange].
%      Fit a function thefun = @(p,x) p(1)*exp(-p(2)*abs(x-p(4)).^(p(5)))+p(3);
%      to this range of freqs. Invert the function to obtain a delining
%      filter and apply it. Repeat for other frequencies. Repeat for
%      all blocks. Reassemble blocks.
%
% Source:
%   http://xcorr.net/2011/10/03/removing-line-noise-from-lfps-wideband-signals/
%
data = data(:);
if nargin < 4 || isempty(freqrange)
    freqrange = .5;
end

if nargin < 5 || isempty(chunksize)
    chunksize = 60;
end

if nargin < 6 || isempty(showOutput)
    showOutput = false;
end

%     chunksize = chunksize*sr;
chunksize = round(chunksize*sr);
if mod(chunksize,2) == 1, chunksize = chunksize-1; end
if chunksize > length(data), chunksize = length(data); end % DJS 5/2016
lsamp = data(end);

%zero pad
origlen = length(data);
data = [data(chunksize/2:-1:1);data];
nchunks = ceil((length(data)+chunksize/2)/chunksize);
padsize = nchunks*chunksize - length(data);
data = [data;data(end:-1:end-padsize+1)];

newdata = zeros(size(data));
nchunks = nchunks*2-1;
thewin = (0:chunksize/2-1)'/(chunksize/2-1);
thewin = [thewin;thewin(end:-1:1)];

%Deline each chunk and reassemble
pss = nan(5,nchunks);
for ii = 1:nchunks
    thechunk = data((ii-1)*chunksize/2+(1:chunksize));
    [delinedchunk,pss] = delineChunk(thechunk,sr,showOutput,freqs,freqrange,pss);
    newdata((ii-1)*chunksize/2+(1:chunksize)) = ...
        newdata((ii-1)*chunksize/2+(1:chunksize)) + ...
        delinedchunk.*thewin;
end

newdata = newdata(chunksize/2 + (1:origlen));


%Deline a single chunk of data
function [y, pss] = delineChunk(dat,sr,showoutput,freqs,freqrange,pss)
ae = [];
if mod(length(dat),2) == 1
    ae = dat(end);
    dat = dat(1:end-1);
end
fftdat = fft(double(dat));
a = abs(fftdat);

%Now remove line noise from datlo to obtain y
%
%Eliminate line noise at target frequencies
thefilt = ones(size(a));

winlen = round(length(dat)/sr*freqrange);

%Fit a curve to this chunk of frequencies
opts = optimset('Display','Off','Jacobian','on','Algorithm','levenberg-marquardt');


n = 1;
for tgtr = freqs
    
    peak = tgtr/sr*length(dat);
    
    rg = round(((peak-winlen):(peak+winlen)))';
    datrg = a(rg);
    
    x = (-winlen:winlen)'/winlen*freqrange;
    
    
    %Only adjust a few parameters at a time
    %convergence is better this way
    %everything but the exponent
    %Find the peak
    datrgsm = conv(datrg,ones(21,1),'same');
    [~,peakloc] = max(datrgsm);
    
    %Set the initial parameters
    x0 = [max(datrg)-median(datrg),1/.2^2,median(datrg),(peakloc-1-winlen)/winlen*freqrange,1]';
    
    if ~any(isnan(pss(:,n)))
        x0([2,4,5]) = pss([2,4,5],n);
    end
    
    
    [ps] = lsqcurvefit(@(x,y) thefun([x;x0(5)],y,[1;1;1;1;0]),x0(1:4),x,datrg,[],[],opts);
    xd = ps(4);
    
    %Everything but the center
    [ps] = lsqcurvefit(@(x,y) thefun([x(1:3);xd;x(4)],y,[1;1;1;0;1]),[ps(1:3);x0(5)],x,datrg,[],[],opts);
    
    %Everything
    [ps] = lsqcurvefit(@(x,y) thefun(x,y,[1;1;1;1;1]),[ps(1:3);xd;ps(4)],x,datrg,[],[],opts);
    
    pss(:,n) = ps;
    
    %Good, now adjust the filter in this range accordingly
    thefilt(rg) = ps(3)./thefun(ps,x);
    b = thefilt(rg);
    thefilt(end-rg+2) = b;
    
    if showoutput
        subplot(length(freqs),1,n);
        plot(x+tgtr,datrg,x+tgtr,thefun(ps,x));
        title(sprintf('%3.1f Hz',tgtr));
        drawnow;
        
        [ps(2),ps(4),ps(5)]
    end
    n=n+1;
end

% y is datlo with line noise removed
a = fftdat.*thefilt;
y = [real(ifft(a));ae];



function [y,J] = thefun(p,x,mask)
E = abs(x-p(4)).^(p(5));
M = exp(-p(2)*E);
y = p(1)*M+p(3);
if nargout > 1
    J = [ M,...
        -p(1)*E.*M,...
        ones(size(x)),...
        p(1)*p(2)*p(5)*sign(x-p(4)).*abs(x-p(4)).^(p(5)-1).*M,...
        -p(1)*p(2)*p(5)*E.*log(abs(x-p(4))+1e-6).*M];
    J = J(:,mask==1);
end
