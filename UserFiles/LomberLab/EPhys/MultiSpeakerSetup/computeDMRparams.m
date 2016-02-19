function [SDMR,Omega,Phi] = computeDMRparams(duration,Fs)
% [SDMR,Omega,Phi] = computeDMRparams(duration,Fs)
%
% Comptue the dynamic moving ripple
%
% Modified from:
% Escabi & Schreiner, J. Neurosci., May 15, 2002, 22(10):4114-4131
%
% Daniel.Stolzberg@gmail.com 2016


t = 0:1/Fs:duration-1/Fs;

% calculate speaker modulation at 6 Hz sampling rate
Omega = rand(1,6*ceil(duration));
Omega = interp1(0:6*ceil(duration)-1,Omega,t,'pchip');

% calculate time-varying temporal modulation rate at 3 Hz sampling rate
Phi = rand(1,3*ceil(duration));
Phi = interp1(0:3*ceil(duration)-1,Phi,t,'pchip');

SDMR = sin(2 * pi * Omega + cumsum(Phi)/Fs);


