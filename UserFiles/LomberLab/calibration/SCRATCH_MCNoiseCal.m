%% BBN Calibration
% clear

Channels = 1:17;

Duration = 100; % ms
Amp      = 3; % V
bufferDuration = 2*Duration; % ms

HPFc = 1000; % Hz
LPFc = 32000; % Hz

nReps = 3; % number of reps

responseWin = [10 90]; % click analysis window (excluding reflections)

%~~~~~~~~~~~~~~~~~
CHECK_CAL = true; % run after calibration to check for equalized response across channels
%~~~~~~~~~~~~~~~~~


Stim.RPfile = 'C:\gits\epsych\calibration\CalUtil_RPvds\STIM_FiltNoise_Calibration.rcx';
Acq.RPfile  = 'C:\gits\epsych\calibration\CalUtil_RPvds\ACQ_Calibration_RX6.rcx';



try
    Stim.AX = TDT_SetupRP('RX8',1,'GB',Stim.RPfile,4);
    Acq.AX  = TDT_SetupRP('RX6',1,'GB',Acq.RPfile);
    
    zf = findFigure('zBUSfig','visible','off');
    zBUS=actxcontrol('ZBUS.x','Parent',zf);
    zBUS.ConnectZBUS('GB');
    
    Acq.Fs = Acq.AX.GetSFreq;
    Stim.Fs = Stim.AX.GetSFreq;
    
    bufferSize = ceil(bufferDuration/1000*Acq.Fs);
    Acq.AX.SetTagVal('bufferSize',bufferSize);
    
    Fstop1 = 250;         % First Stopband Frequency
    Fpass1 = 1000;        % First Passband Frequency
    Fpass2 = 32000;       % Second Passband Frequency
    Fstop2 = 48828;       % Second Stopband Frequency
    Astop1 = 10;          % First Stopband Attenuation (dB)
    Apass  = 1;           % Passband Ripple (dB)
    Astop2 = 10;          % Second Stopband Attenuation (dB)
    match  = 'passband';  % Band to match exactly
    
    % Construct an FDESIGN object and call its BUTTER method.
    h  = fdesign.bandpass(Fstop1, Fpass1, Fpass2, Fstop2, Astop1, Apass, ...
        Astop2, Acq.Fs);
    Hd = design(h, 'butter', 'MatchExactly', match);
    
    tvec = linspace(0,bufferDuration-1/Acq.Fs,bufferSize);
    
    responseWin = responseWin + Duration;
    
    ind = tvec>=responseWin(1) & tvec<responseWin(2);
    if rem(sum(ind),2), ind(find(ind,1,'last')+1) = 1; end
    
    preind = find(ind,1)-sum(ind)+1:find(ind,1);
    
    
    %%
    f = findFigure('PlotFig','color','w');
    figure(f);
    clf;
    
    Stim.AX.SetTagVal('duration',Duration);
    Stim.AX.SetTagVal('Amp',Amp); 
    Stim.AX.SetTagVal('HPFc',HPFc);
    Stim.AX.SetTagVal('LPFc',LPFc);
    
    bufferSig = nan(sum(ind),nReps,length(Channels));
    bufferNoise =  nan(sum(ind),nReps,length(Channels));
    for c = Channels
        if CHECK_CAL
            Stim.AX.SetTagVal('Amp',signal_normV(c));
        end
        fprintf('Calibrating channel %d of %d ',c,length(Channels))
        Stim.AX.SetTagVal('DAC',c);
        
        
        for i = 1:nReps
            Acq.AX.ZeroTag('buffer');
            
            zBUS.zBusTrigA(0,0,5);
            
            timeout(5);
            while Acq.AX.GetTagVal('bufferidx') < bufferSize && ~timeout
                pause(0.05);
            end
            
            assert(~timeout,'TIMED OUT WHILE COLLECTING BUFFER');
            
            newBuffer = Acq.AX.ReadTagV('buffer',0,bufferSize);
            
            assert(any(newBuffer),'NO DATA WAS RECORDED INTO THE BUFFER');
            
            newBuffer = filter(Hd,fliplr(newBuffer));
            newBuffer = filter(Hd,fliplr(newBuffer));
            
            bufferSig(:,i,c) = newBuffer(ind);
            bufferNoise(:,i,c) = newBuffer(preind);
            
            
            % plot time signal
            subplot(221);
            cla
            hold on
            plot(tvec,newBuffer);
            yscale = max(abs(reshape(bufferSig(:,:,c),1,size(bufferSig,1)*size(bufferSig,2))));
            plot(responseWin,yscale*[0.9 0.9],'-r');
            set(gca,'xlim',tvec([1 end]),'ylim',[-1 1]*yscale);
            grid on
            box on
            title(sprintf('Buffer | Channel %d of %d',c,length(Channels)));
            
            
            subplot(222);
            cla
            th = pi/180*15*(-8:8);
            rho = squeeze(sqrt(nanmean(bufferSig.^2)));
            if size(rho,2) > 1, rho = mean(rho); end
            p = polar(th(:),rho(:),'-or');
            set(p,'markerfacecolor','r');
            hold on
            rho = squeeze(sqrt(nanmean(bufferNoise.^2)));
            if size(rho,2) > 1, rho = mean(rho); end
            p = polar(th(:),rho(:),'-sb');
            set(p,'markerfacecolor','b');
            hold off
            title('RMS')
            
            subplot(223);
            cla
            % compute FFT of pre-stimulus noise
            L = length(preind);
            f = Acq.Fs*(0:(L/2))/L;
            f = f/1000;
            y = mean(fft(bufferNoise(:,1:i,c),[],2),2);
            p = abs(y/L);
            p = p(1:L/2+1);
            p(2:end-1) = 2*p(2:end-1);
            hold on
            plot(f,db(p));
            
            % compute FFT of mean signal
            L = sum(ind);
            f = Acq.Fs*(0:(L/2))/L;
            f = f/1000;
            y = mean(fft(bufferSig(:,1:i,c),[],2),2);
            p = abs(y/L);
            p = p(1:L/2+1);
            p(2:end-1) = 2*p(2:end-1);
            
            plot(f,db(p),'-r')
            set(gca,'xlim',[0.2 f(end)],'xscale','linear');
            grid on
            box on
            title('Power Spectrum of Mean Response');
            ylabel('dB');
            xlabel('Frequency (kHz)');
            
            xlim([1 Stim.Fs/2/1000]);
            
            fprintf('.')
            drawnow
        end
        
        % compute FFT
        meanY = squeeze(mean(fft(bufferSig,[]),2));
        
        L = size(bufferSig,1);
        f = Acq.Fs*(0:(L/2))/L;
        f = f/1000;
        p = abs(meanY/L);
        p = p(1:L/2+1,:);
        p(2:end-1,:) = 2*p(2:end-1,:);
        
        
        subplot(224)
        cla
        imagesc(f,Channels,db(p'));
        ylabel('Channel');
        xlabel('Frequency (kHz)');
        set(gca,'xlim',[1 Stim.Fs/2/1000],'TickDir','out');
        title('Mean Power Spectrum')
        
        fprintf('\n')
    end
    
catch me
    
    Stim.AX.Halt;
    Acq.AX.Halt;
    close(findobj('tag','zBUSfig'));
    close(findobj('name','RPfig'));
    
    rethrow(me);
end
%%
Stim.AX.Halt;
Acq.AX.Halt;
close(findobj('tag','zBUSfig'));
close(findobj('name','RPfig'));


%%

meanSignalRMS = mean(squeeze(rms(bufferSig)));

calV = 3.6304; % V RMS @ 114 dB SPL
caldB = 114;

signal_dB = 20*log10(meanSignalRMS/calV)+114;

norm_dB = 70; % dB SPL normalization target

signal_normV = calV*10.^((norm_dB-signal_dB)/20); % normalized V for each channel at norm_dB

timestamp = datestr(now);

if ~CHECK_CAL
    fn = sprintf('NoiseCal_%d-%dkHz.mat',Fpass1/1000,Fpass2/1000);
    
    fprintf('Saving ''%s'' ...',fn)
    save(fn);
    fprintf(' done\n')
end



