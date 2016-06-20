%% time domain swept sine
Fs = 44100;

f1 = 50;
f2 = 15000;

T = .064; 
t = 0:1/Fs:T-1/Fs;

ep = (log(f2/f1)*t)./T;

y = sin(((2*pi*f1*T)./log(f2/f1)).^(ep)-1);

f = findFigure('SweptSine');
clf(f)
figure(f);

subplot(411)
plot(1000*t,y)
ylabel('amplitude')
xlim(t([1 end]))

subplot(4,1,[2 4])
spectrogram(y,hanning(64),50,1024,Fs,'yaxis');
colorbar off
% set(gca,'yscale','log');

linkaxes(get(f,'children'),'x');

a = audioplayer(y,Fs);

%%

F1 = 100;
F2 = 20000;
t = 10;
Fs = 44100;

[sweep,invsweepfft,sweeprate] = synthSweep(t,Fs,F1,F2);

subplot(411)
plot(1000*t,sweep)
ylabel('amplitude')
xlim(t([1 end]))

subplot(4,1,[2 4])
spectrogram(sweep,hanning(64),50,1024,Fs,'yaxis');
colorbar off
% set(gca,'yscale','log');

linkaxes(get(f,'children'),'x');

a = audioplayer(sweep,Fs);


