%% Auditory Spatio-Temporal Receptive Field using Dynamic Moving Ripples (in space)

nChan = 17;

dur = 20; % total stimulus duration (seconds)
gate_dur = 0.1; % gate duration (seconds)

ampScale = 0.6; % amplitude scaling (V)

gw_alpha = 9; % 1/std of a gaussian window spreading signal across channels

upsampleFactor = 4; % creates a higher cross-channel sampling. After processing, the signal is resampled to the number of channels

Fs = 48848.125; % Hz

f0    = 0.1; % Base modualtion frequency (Hz)           0.1
f1    = 2;  % maximum modulation frequency (Hz)         2
nComp = 5;  % Number of component frequencies (> 1)     5

d = 1;      % ripple depth (between 0 and 1)            1
omega = 0;  % ripple density in cycles per octave       0 (does this matter in this application?)
w = 0;      % ripple velocity 'drift' (Hz)              0

ripple_phi = 0; % starting phase of the ripple (radians) 0

rng(1234); % seed random number generator for repatable results (default = 1234)

%%

t = 0:1/Fs:dur-1/Fs;
nTime = length(t);

% create evenly spaced modulation frequencies
fd = f1-f0;
f = f0*2.^(linspace(0,fd,nComp))';
nFreq = length(f);

gamma = rand(nComp,1); % amplitude randomization for each component
phi   = 2*pi*rand(nComp,1); % randomize phase of each component

wprime = cumsum(w*ones(1,nTime))/Fs;

X = log2(repmat(f,1,nTime)/f0);

sMod = zeros(1,nTime);
for i = 1:nComp
    A = 1 + d * sin(2 * pi * (wprime .* t + omega * X(i,:)) + ripple_phi);
    S = gamma(i) * sin(2 * pi * f(i) * t + phi(i)) / sqrt(f(i));
    sMod = sMod + A.*S;
end
clear A S X wprime

sMod = sMod / max(abs(sMod));



%% Scale signal_mod to number of channels

sMod = (sMod+1)/2; % -> [0 1]

sMod = sMod*(nChan*4-1)+1;
% sMod = round(sMod*(nChan-1))+1;

% for i = 1:17
%     fprintf('%d: %d (%0.2f%%)\n',i,sum(sMod==i),sum(sMod==i)/length(sMod)*100)
% end

%% generate filtered carrier noise
Y = randn(1,nTime); % white noise

Fstop1 = 500;         % First Stopband Frequency
Fpass1 = 1000;        % First Passband Frequency
Fpass2 = 10000;       % Second Passband Frequency
Fstop2 = 20000;       % Second Stopband Frequency
Astop1 = 60;          % First Stopband Attenuation (dB)
Apass  = 1;           % Passband Ripple (dB)
Astop2 = 80;          % Second Stopband Attenuation (dB)
match  = 'stopband';  % Band to match exactly

% ConTimetruct an FDESIGN object and call its BUTTER method.
h  = fdesign.bandpass(Fstop1, Fpass1, Fpass2, Fstop2, Astop1, Apass, ...
                      Astop2, Fs);
Hd = design(h, 'butter', 'MatchExactly', match);

Y = filter(Hd,Y);

Y = gatestim(Y,gate_dur,Fs,'cos2')';

%% Use signal_mod to direct gaussian envelope moving across speakers
gw = gausswin(nChan*upsampleFactor,gw_alpha);

G = zeros(nChan*upsampleFactor,nTime);
% parfor i = 1:nTime
for i = 1:nTime
    cs = sMod(i)-nChan*upsampleFactor/2+1:sMod(i)+nChan*upsampleFactor/2;
    ind = cs < 1;
    if any(ind)
        G(:,i) = [gw(~ind); zeros(sum(ind),1)];
    else
        ind = cs > nChan*4;
        G(:,i) = [zeros(sum(ind),1); gw(~ind)];
    end 
end
clear sMod

G = G.*repmat(Y,nChan*upsampleFactor,1);

G = G/max(abs(G(:)))*ampScale;

%% downsample across channels
ds = length(gw)/nChan;
% j = 1;
% G = zeros(nChan,nTime);
% for i = 1:ds:length(gw)
%     G(j,:) = mean(GY(i:i+ds-1,:));
%     j = j + 1;
% end
G = G(1:ds:length(gw),:);

%% plot
clf
imagesc(t,1:nChan,abs(G));
set(gca,'ydir','normal')
xlabel('time (s)');
ylabel('channel');
colormap(flipud(gray))

% hold on
% plot(t,sMod/max(sMod)*nChan);
% xlabel('time (s)');
% ylabel('channel');
% set(gca,'xlim',t([1 end]),'ylim',[0 nChan+1]);
% title('Modulation Signal')

%% Store data in an channel-interleaved column vector
audiowrite('TEST_SWEEP.wav',G(:),floor(Fs));

numel(G)

















