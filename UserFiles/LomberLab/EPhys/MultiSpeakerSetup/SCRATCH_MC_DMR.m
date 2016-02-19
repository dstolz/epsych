%% some parameters to generate signal

dur = 30; % total stimulus duration (seconds)

% Fs = 48848.125;
Fs = 24424.0625;

ampscale = 0.6;


%% generate click train
click_dur = 0.005; % seconds
click_isi = 0.05;  % seconds

clicksamps = round(click_dur*Fs);
isisamps = round(click_isi*Fs);

nclicks = floor((dur*Fs)/(clicksamps+isisamps));

Y = repmat([zeros(1,isisamps) ones(1,clicksamps)],1,nclicks);

% if rem(nclicks,2), nclicks = nclicks + 1; end
% Y = repmat([zeros(1,isisamps) ones(1,clicksamps) zeros(1,isisamps) -ones(1,clicksamps)],1,nclicks/2);


%% Modulate signal Y across channels

rng(1234); % make predictable signal envelope

actDur = length(Y)/Fs;

[modpath,Omega,Phi] = computeDMRparams(actDur,Fs);

YDMR = signalPath(Y,modpath,10,5,4);

YDMR = ampScale * YDMR;

%% plot
clf

t = linspace(0,size(YDMR,2)/Fs-1/Fs,size(YDMR,2));

imagesc(t,1:size(YDMR,1),YDMR);
set(gca,'ydir','normal');
colormap(gray);

mpath = (modpath+1)/2; % [-1 1] -> [0 1]
mpath = mpath*(size(YDMR,1)-1)+1; % [0 1] -> [1 nChan*upsample]

hold on
plot(t,mpath,'-','linewidth',2);
hold off

xlabel('time (s)');
ylabel('channels');
title('Spatial DMR : YDMR');

%%
audiowrite('TEST_SWEEP.wav',YDMR(:),floor(Fs));

numel(YDMR)


