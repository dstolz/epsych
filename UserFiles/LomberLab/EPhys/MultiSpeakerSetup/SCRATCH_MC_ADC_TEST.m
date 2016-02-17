%%

% RPfile = 'C:\Users\Dan\Desktop\SpeakerArrayTest.rcx';
% 
% 
% RP = TDT_SetupRP('RX8',1,'GB',RPfile);
% 
% 
% 
% 
% RP.Halt




















%% Approach 1: mask chan X samples signal with gaussian sweep algorithmically
% This allows for arbitrary speaker paths
 
nChan = 17;

D = 0.5; % siganl duraiton in seconds
gate_dur = 0.001;  % gate duration in seconds

gw_alpha = 7; % variance of gaussian window around channels


% Fs = 48828.125;
Fs = 97656.25;


T = linspace(0,D,D*Fs);
% T = logspace(0,log10(D),D*Fs);


Y = randn(1,length(T)); % white noise

Fstop1 = 500;         % First Stopband Frequency
Fpass1 = 1000;        % First Passband Frequency
Fpass2 = 10000;       % Second Passband Frequency
Fstop2 = 20000;       % Second Stopband Frequency
Astop1 = 60;          % First Stopband Attenuation (dB)
Apass  = 1;           % Passband Ripple (dB)
Astop2 = 80;          % Second Stopband Attenuation (dB)
match  = 'stopband';  % Band to match exactly

% Construct an FDESIGN object and call its BUTTER method.
h  = fdesign.bandpass(Fstop1, Fpass1, Fpass2, Fstop2, Astop1, Apass, ...
                      Astop2, Fs);
Hd = design(h, 'butter', 'MatchExactly', match);

Y = filter(Hd,Y);

Y = gatestim(Y,gate_dur,Fs,'cos2')';

gw = gausswin(nChan,gw_alpha);

% gSweep = 1:nChan;

gSweep = sin(2*pi*2*T);


G = zeros(nChan,nChan);
for i = 1:nChan

    cs = gSweep(i)-nChan/2+1:gSweep(i)+nChan/2;
    ind = cs < 1;
    if any(ind)
        G(:,i) = [gw(~ind); zeros(sum(ind),1)];
    else
        ind = cs > nChan;
        G(:,i) = [zeros(sum(ind),1); gw(~ind)];
    end
    
end

chSweep = linspace(1,nChan,length(T));
K = interp2(G,chSweep',1:nChan,'cubic');


KY = K.*repmat(Y,nChan,1);

KY = KY/max(abs(KY(:)))*0.1;


imagesc(T,gSweep,KY);
set(gca,'ydir','normal')
xlabel('time (s)');
ylabel('channel');


% Store data in an channel-interleaved column vector

wKY = KY(:); 

audiowrite('TEST_SWEEP.wav',wKY,floor(Fs));

numel(wKY)










%% Approach 2: rotate image to create signal
nChan = 17;

D = 0.5; % siganl duraiton in seconds
gate_dur = 0.001;  % gate duration in seconds

gw_alpha = 7; % variance of gaussian window around channels


% Fs = 48828.125;
Fs = 97656.25;

T = linspace(0,D,D*Fs);

% Y = sin(2*pi*F*T);
Y = randn(1,length(T)); % white noise

Fstop1 = 500;         % First Stopband Frequency
Fpass1 = 1000;        % First Passband Frequency
Fpass2 = 10000;       % Second Passband Frequency
Fstop2 = 20000;       % Second Stopband Frequency
Astop1 = 60;          % First Stopband Attenuation (dB)
Apass  = 1;           % Passband Ripple (dB)
Astop2 = 80;          % Second Stopband Attenuation (dB)
match  = 'stopband';  % Band to match exactly

% Construct an FDESIGN object and call its BUTTER method.
h  = fdesign.bandpass(Fstop1, Fpass1, Fpass2, Fstop2, Astop1, Apass, ...
                      Astop2, Fs);
Hd = design(h, 'butter', 'MatchExactly', match);

Y = filter(Hd,Y);

Y = gatestim(Y,gate_dur,Fs,'cos2')';

gw = gausswin(nChan,gw_alpha);

K = gw*Y;

q = -45;

B = imrotate(K,nChan/length(T)*q,'bilinear','crop');

% B = [B fliplr(B)]; % mirror

B = B/max(abs(B(:)))*0.99; % normalize to < 1

% Store data in an channel-interleaved column vector


% B = [B fliplr(B)];

imagesc(T,1:nChan,B);
set(gca,'ydir','normal')
xlabel('time (s)');
ylabel('channel');

wB = B(:);

audiowrite('TEST_SWEEP.wav',wB,floor(Fs));

numel(wB)


%%
