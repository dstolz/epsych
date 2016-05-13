% Generate a Dynamic Moving Ripple
%
% SSDMR(t,Xk) = P.M/2 * sin[2 * pi * Omega(t) * Xk + Phi(t)]
% P.M = modulation depth (dB)
% Xk = log2(fk/f1) octave frequency axis relative to f1
% Phi(t) = integral 0-t Fm(tau)d(tau) controls time-varying temporal
% modulation rate Fm(t)
% Spectral [Omega(t)] and temporal [Fm(t)] parameters are independent,
% slowyly timevarying random processes with maximum rates of change 1.5 Hz
% for Fm and 3 Hz for Omega (maximum ranges in speech and vocalizations,
% Greenberg 1998)
% uniformly flat distributed amplitudes 0–4 cycles per octave for ? and
% ?350 to +350 Hz for Fm
%

clear

%% Initialization
P.dur           = 20*60; % s
P.velocityrate	= 1.4; % temporal rate of change (Hz) 
P.densityrate	= 3; % spectral rate of change (Hz) 
P.Fs			= 97656; % sampling rate (Hz)

% following parameters from Atencio et al, 2010 
P.densityrange	= [0 4]; % (cycles/octave) (# peaks per octave)
P.velocityrange	= [-40 40]; % (Hz) (# peaks per second; negative value is an upward sweep, positive downward)
P.nFreq	= 50; % number of frequencies per octave
P.F0	= 1000; % base frequency
P.Fmax	= 32000; % maximum frequency
% P.M     = 40; % amplitude modulation depth (decibels)
P.M     = 0.4; % amplitude modulation depth (percent [0 1]) see Depireux et al, 2000




%% Create envelope
tic;

ndensity  = round(P.dur*P.densityrate);
nvelocity = round(P.dur*P.velocityrate);

fprintf('Creating evelope ...')
rng(123)
density	  = randn(ndensity,1);
velocity  = randn(nvelocity,1);

% f = findFigure('DMR_data');
% figure(f)
% clf(f)
% 
% subplot(321)
% t = (0:length(density)-1)/P.densityrate;
% plot(t,density,'ko-')
% hold on
% title('Density')
% 
% subplot(322)
% t = (0:length(velocity)-1)/P.velocityrate;
% plot(t,velocity,'ko-')
% hold on
% title('Velocity')
% % plot((0:length(velocity)-1)/P.velocityrate,velocity,'ro-');

fprintf(' done\n')

%% upsample
fprintf('Upsampling ...')
% resample
nd			= round(P.Fs/P.densityrate);
density		= resample(density,nd,1);
nd = numel(density);

nv			= round(P.Fs/P.velocityrate);
velocity	= resample(velocity,nv,1);
nv = numel(velocity);




N = min([nd nv]);

density = density(1:N);
velocity = velocity(1:N);

% % plot
% subplot(321)
% t = (0:length(density)-1)/P.Fs;
% plot(t,density,'r-')
% 
% subplot(322)
% t = (0:length(velocity)-1)/P.Fs;
% plot(t,velocity,'r-')
% 
% % interpolation
% % interp1(x,y,xi)
% subplot(323)
% hist(density,50);
% xlim([min(density) max(density)])
% 
% subplot(324)
% hist(velocity,50);
% xlim([min(velocity) max(velocity)])

fprintf(' done\n')

%% Convert to uniform distribution (Explained in methods section of Escabi & Schreiner, 2002 J. Neurosci.)
fprintf('Converting to uniform distribution ...')
velocity	= erf(velocity);
density		= erf(density);

% Set range
velocity	= velocity*range(P.velocityrange)/2+mean(P.velocityrange);
density		= density*range(P.densityrange)/2+mean(P.densityrange);


% % figure
% subplot(325)
% hist(density,50);
% % title('Density')
% 
% subplot(326)
% hist(velocity,50);
% % title('Velocity')

fprintf(' done\n')

%% Generating the ripple
fprintf('Generating ripple\n')
% SSDMR(t,Xk) = P.M/2 * sin[2 * pi * Omega(t) * Xk + Phi(t)]
% P.M = modulation depth (dB)
% Xk = log2(fk/f1) octave frequency axis relative to f1
% Phi(t) = integral 0-t Fm(tau)d(tau) controls time-varying temporal
% modulation rate Fm(t)
% P.M		= 100;
time	= (0:length(density)-1)'/P.Fs;
FreqNr	= (0:1:P.nFreq-1)/P.nFreq;

% Orange = pa_freq2bw(P.F0,P.Fmax);
Orange = P.Fmax/P.F0; % bandwidth in Hz
Orange = log2(Orange); % bandwidth in octaves

Xk = Orange*FreqNr; % octaves above the ground frequency

% fk		= pa_oct2bw(P.F0,Xk);
fk = P.F0 .* 2.^Xk;
phi = 2*pi*rand(size(fk));
velocity = 2*pi*cumsum(velocity(:)/P.Fs);


snd = zeros(size(time));



for ii = 1:P.nFreq
    fprintf('Processing frequency: % 9.2f Hz\n',fk(ii))
   
	Sdb	= 1+P.M/2*sin(2*pi*density.* Xk(ii)+velocity);

    snd	= snd + Sdb.*sin(2*pi*fk(ii).*time+phi(ii));
end
snd = snd / max(abs(snd)) * 0.99;
clear velocity density Sdb Slin

% %% Plot DMR
% f = findFigure('DMR_SPEC');
% figure(f)
% 
% subplot(5,1,[1 2])
% plot(time,snd);
% ylim(max(abs(snd))*[-1 1]);
% xlim(time([1 end]));
% ylabel('Amplitude');
% 
% subplot(5,1,[3 5])
% figure
% spectrogram(snd(1:P.Fs),hanning(128),64,2^11,P.Fs,'yaxis');
% % ylim([P.F0 P.Fmax]/1000);
% colorbar off
% 
% linkaxes(get(f,'children'),'x');
% 
% fprintf(' done\n')

%% Save sound
wavfilename = 'DMR.wav';
fprintf('Saving wav file: %s ...',wavfilename)


audiowrite(wavfilename,snd,P.Fs);


fprintf(' done\n')


%% Save envelopes and parameters
paramfilename = 'DMRparameters.mat';
fprintf('Saving parameters: %s ...',paramfilename)

P.info.clock = clock;
P.info.script = mfilename('fullpath');

save(paramfilename,'P');

fprintf(' done\n')



toc