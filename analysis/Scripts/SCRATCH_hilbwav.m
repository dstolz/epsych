%%

win = [0.03 0.6];
binsize = 0.005;

unit = getpref('DB_BROWSER_SELECTION','units');

st = DB_GetSpiketimes(unit);
P  = DB_GetParams(unit,'unit');

[data,vals] = shapedata_spikes(st,P,{'BuID'},'win',win,'binsize',binsize, ...
    'returntrials',true);




%%
pn = 'D:\Dropbox\PROJECTS\Electrophysiology\Dan''s Projects\Vocalizations';

W = dir(fullfile(pn,'*.wav'));

Wn = {W.name};

Wid = cellfun(@(x) (str2num(x(1:2))),Wn); %#ok<ST2NM>

%%
f1 = findobj('tag','Plots1');
if isempty(f1)
    f1 = figure('Color',[0.98 0.98 0.98],'tag','Plots1','toolbar','figure');
end

f2 = findobj('tag','Plots2');
if isempty(f2)
    f2 = figure('Color',[0.98 0.98 0.98],'tag','Plots2','toolbar','figure');
end


%%
for i = 1:length(Wid)
    %%
    fn = Wn{Wid(i)};
    
    fn = fullfile(pn,fn);
    
    [Y,Fs] = wavread(fn);
    
    nY = length(Y);
    
    t = linspace(0,nY/Fs,nY);
    
    clf(f1);
    set(f1,'color','w');
    
    %% Time domain signal
    subplot(411)
    plot(t,Y,'-k')
    axis tight
    y = max(abs(ylim))*1.1;
    ylim([-y y]);
    box on
    ylabel('Amplitude','fontsize',12);
    
 %% Envelope extraction (Hilbert Transform) of WAV file
    env = abs(hilbert(Y));
    
    Fpass = 250;         % Passband Frequency
    Fstop = 500;         % Stopband Frequency
    Apass = 1;           % Passband Ripple (dB)
    Astop = 30;          % Stopband Attenuation (dB)
    match = 'stopband';  % Band to match exactly
    
    % Construct an FDESIGN object and call its BUTTER method.
    h  = fdesign.lowpass(Fpass, Fstop, Apass, Astop, Fs);
    Hd = design(h, 'butter', 'MatchExactly', match);
    
    env = filter(Hd,flipud(env));
    env = filter(Hd,flipud(env));
    
    hold on
    plot(t,env,'b','linewidth',3);
    hold off

    xlim(win);
    title(Wn{Wid(i)},'FontSize',20,'interpreter','none');
    
    %% Short-time FFT Spectrogram
    subplot(412)
    
    nwin = 2^10;
    ovlp = 2^9;
    nfft = 2^13;
    
    hwin = window(@hann,nwin);
    wvec = 1:ovlp:nY-nwin;
    
    S = zeros(nfft/2,length(wvec));
    j = 1;
    for r = wvec
        k = r:r+nwin-1;
        y = Y(k) .* hwin;
        stfft = fft(y,nfft)/nfft;
        S(:,j) = 2*abs(stfft(1:nfft/2));
        j = j + 1;
    end
    
    F = Fs/2*linspace(0,1,nfft/2);
    F = F / 1000; % Hz -> kHz
    S = 10*log10(S);
    S = interp2(S,3);
    
    imagesc(t,F,S);
    set(gca,'ydir','normal');
    ylabel('Frequency (kHz)','fontsize',12);
    ylim([0.5 12])
    xlim(win);

    colormap jet
    freezeColors
    
   
    
    %% Spike Data
    subplot(413)
    ind = vals{3} == Wid(i);
    imagesc(vals{1},vals{2},data(:,:,ind)');
    colormap(flipud(gray))
    ylabel('Trial','fontsize',12);
    freezeColors
    set(gca,'ydir','normal');
    xlim(win);
    xlabel('Time (s)','fontsize',12);

    %% Correlation analysis
    subplot(414)
    D = data(:,:,ind);
    Di = zeros(length(t),size(D,2));
    for j = 1:size(D,2)
        D(:,i)  = conv(D(:,i),gausswin(5),'same');
        Di(:,i) = interp1(1:size(D,1),D(:,i),linspace(1,size(D,1),length(t)),'pchip');
    end
    renv = repmat(env,1,30);
    [r,p] = corrcoef(Di,renv);
    
    h = sum(data(:,:,ind),2);
    hc = conv(h,gausswin(5),'same');
    sf = length(vals{2})*0.9;
    hi = interp1(1:length(hc),hc,linspace(1,length(hc),length(t)),'pchip');
    
    [C,lags] = xcorr(env,hi,'unbiased');
    plot(lags,C,'-k','linewidth',3);
    
    [Cn,lags] = xcorr(env,hi(randperm(length(hi))),'unbiased');
    hold on
    plot(lags,Cn,'-','color',[0.5 0.5 0.5]);
    hold off
    
    xlim([lags(1) lags(end)]);
    grid on
    
    xlabel('Envelope X Histogram','fontsize',12)
    
    %%
    allax = findobj(f1,'type','axes');
    set(allax,'ticklength',[0 0]);   
    
    
    
    %%
    drawnow
%     pause(1)
end