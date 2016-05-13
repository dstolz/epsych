%% some parameters to generate signal

dur = 10; % total stimulus duration (seconds)

nChan = 17;
speaker_separation = 15; % deg

Fs = 48848.125;
% Fs = 24424.0625;

ampScale = 0.6;


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

[modpath,Omega,Phi] = computeDMRparams(actDur,Fs,0.5,0.5);

YDMR = signalPath(Y,modpath,nChan,5,4);

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

%% Simulate speaker movements
clf

% th = deg2rad((mpath-1)*speaker_separation);
th = (mpath-1)*speaker_separation/180*pi;

subplot(211)
plot((mpath-1)*speaker_separation)
hold on
% plot(i,(mpath(i)-1)*speaker_separation,'o');
ml = line(i,(mpath(1)-1)*speaker_separation);
set(ml,'marker','o')
hold off

subplot(212)
% tl = line(th(1),1);
% set(tl,'marker','o');

for i = 1:1000:numel(th)
    set(ml,'xdata',i,'ydata',(mpath(i)-1)*speaker_separation);
%     set(tl,'xdata',th(i));

    polar(th(i),1,'o')
    title(i)
%     pause(0.01)
    drawnow
end

%%
audiowrite('TEST_SWEEP.wav',single(YDMR(:)),floor(Fs));

numel(YDMR)

%%
buffer = single(YDMR(:))';
save('TEST_SWEEP.mat','Fs','buffer','modpath','Phi','Omega');
