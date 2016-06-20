% Steps taken from Muller - Transfer-Function Measurement with Sweeps
% (p.16)
%
% Also see: Chan - Swept Sine Chirps for Measuring Impulse Response (fig 4)
%
% NOT WORKING YET

clear all
% close all
Fs = 96000;


F1 = 20;
F2 = 20000;
T  = 0.5;

tREF = 0:1/Fs:T-1/Fs;
















% 1. Synthesize Log-Swept Sine ============================================
% yREF = chirp(tREF,F1,T,F2,'logarithmic');
instPhi = T/log(F2/F1)*(F1*(F2/F1).^(tREF/T)-F1);
yREF = sin(2*pi*instPhi);


yREF = gatestim(yREF,0.1,Fs,'cos2')';

yREF = [yREF zeros(1,round(0.1*length(yREF)))];
tREF = linspace(0,length(yREF)/Fs-1/Fs,length(yREF));

f = findFigure('SweptSine');
clf(f)
figure(f);
drawnow

subplot(411)
plot(tREF,yREF)
ylabel('amplitude')
xlim(tREF([1 end]))

subplot(4,1,[2 4])
spectrogram(yREF,hanning(64),50,1024,Fs,'yaxis');
colorbar off
ylim([0 20]);



% WEIGHTING DUT signal for testing
% W = 2*sin(2*pi*0.3*tREF+0.0)+0.1*randn(size(tREF));
% W = 2*sin(2*pi*0.3*tREF+0.0);
W = gausswin(length(tREF),6)';
% W = 1;




% ***** Simulate signal recorded from DUT  ***** 
yDUT = yREF .* (W./max(abs(W))); % FOR TESTING PURPOSES
yDUT = [zeros(1,find(tREF>=0.01,1)) yDUT zeros(1,find(tREF>=0.01,1))];

tDUT = (0:length(yDUT)-1)/Fs;

f = findFigure('DUTSweptSine');
clf(f)
figure(f);

subplot(411)
plot(tDUT,yDUT)
ylabel('amplitude')
xlim(tDUT([1 end]))

subplot(4,1,[2 4])
spectrogram(yDUT,hanning(64),50,1024,Fs,'yaxis');
colorbar off
ylim([0 20]);
drawnow




























% 2. Compute FFTs of DUT and REF signals ==================================
f = findFigure('SweptSineFFT');
clf(f)
figure(f)
drawnow


% REF
nREF = 2^nextpow2(length(yREF));
fy = fft([yREF zeros(size(yREF))],nREF);
% fy = fft(yREF,nREF);
pREF = abs(fy/nREF);
pREF = pREF(1:nREF/2+1);
fREF = Fs*(0:(nREF/2))/nREF;

plot(fREF,pREF);
set(gca,'xscale','log');

hold on


% DUT
nDUT = 2^nextpow2(length(yDUT));
fy = fft([yDUT zeros(size(yDUT))],nDUT);
% fy = fft(yDUT,nDUT);
pDUT = abs(fy/nDUT);
pDUT = pDUT(1:nDUT/2+1);
fDUT = Fs*(0:(nDUT/2))/nDUT;

plot(fDUT,pDUT);
set(gca,'xscale','log');
drawnow





















% 3. Create compensated frequency response of DUT by dividing the spectrum
% of the sweep response(pDUT) by the spectrum of the excitation signal (pREF)

RTF = pDUT ./ pREF;

plot(fREF,RTF);

set(gca,'xscale','log');

grid on
xlabel('f (Hz)')
ylabel('|P1(f)|')

set(gca,'yscale','log')


title('Frequency Responses')
legend(gca,{'Reference','DUT','Compensated'},'location','Best')

xlim([1 20000])
drawnow





















% 4. Compute inverse FFT of compensated frequency response to obtain the
% impulse response of DUT =================================================

RIR = ifft(RTF,2^nextpow2(length(RTF)));
RIR = RIR(1:floor(length(RIR)/2)); % chop off second half of impulse response

f = findFigure('IR');
clf(f)
figure(f)
drawnow

subplot(211)
plot(real(RIR));
% set(gca,'xscale','log')
title('Impluse Response');
xlabel('time');
axis tight

















% 5. Window post-compensated iFFT ????????????


T = tDUT(end);
% not implemented
group_delay = T*log(fDUT/F1)/log(F2/F1);
for N = 1:5
    group_delay_harmonic(N) = -T*log(N)/log(F2/F1);
end















% RIR = RIR(1:500);




% 6. Compute FFT from iFFT to obtain the DUT frequency response ===========

nRIR = 2^nextpow2(length(RIR));
ft = fft(RIR,nRIR);
p = abs(ft/nRIR);
pRIR = p(1:nRIR/2+1);
fRIR = Fs*(0:(nRIR/2))/nRIR;

subplot(212)
plot(fRIR,pRIR);
set(gca,'yscale','log','xscale','log');
axis tight
xlim(fRIR([1 end]))
title('IR Spectrum')


f = findFigure('Txfcn');
clf(f)
figure(f)


% 6b. Gate response
% gate = [0.02 0.13];
% n = round(Fs*0.005);
% win = hann(n*2);

 


% Apply RTF function to signal ????????????????????
yCAL = fftfilt(RIR,yREF);
% yCAL = conv(yREF,RIR,'full');
% yCAL = yCAL(1:length(yDUT));

subplot(411);
plot(linspace(0,length(yCAL)/Fs-1/Fs,length(yCAL)),real(yCAL))
axis tight
title('Calibrated Signal');



subplot(4,1,[2 4]);
spectrogram(yCAL,hanning(64),50,1024,Fs,'yaxis');
ylim([0 20]);
colorbar off

drawnow
