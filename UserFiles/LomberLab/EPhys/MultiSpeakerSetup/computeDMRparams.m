function [DMR,Omega,Phi] = computeDMRparams(duration,Fs,omega,phi)
% [DMR,Omega,Phi] = computeDMRparams(duration,Fs,[omega],[phi])
%
% Compute the dynamic moving ripple
%
% Input:
%   duration    ...     1x1 scalar value with the intended duration of the
%                       signal.
%   Fs          ...     1x1 scalar value with the sampling rate (Hz)
%   omega       ...     1x1 scalar value specifying the original sampling
%                       rate of the channel modulation rate, Omega (Hz;
%                       default = 6 Hz).
%   phi         ...     1x1 scalar value specifying the original sampling
%                       rate of the time-varying temporal modulation rate,
%                       Phi (Hz; default = 3 Hz).
%
%
% Output:
%   DMR         ...     1xN vector of the resulting dynamically moving
%                       ripple profile.
%   Omega       ...     1xN vector of the speaker modulation rate.
%   Phi         ...     1xN vector of the time-varying temporal modulation
%                       rate.
%   
%
% Modified from:
% Escabi & Schreiner, J. Neurosci., May 15, 2002, 22(10):4114-4131
%
% Daniel.Stolzberg@gmail.com 2016

if nargin < 3 || isempty(omega), omega = 6; end
if nargin < 4 || isempty(phi),   phi   = 3; end

t = 0:1/Fs:duration-1/Fs;

% calculate speaker modulation at omega Hz sampling rate
Omega = randn(1,omega*ceil(duration));
Omega = interp1(0:omega*ceil(duration)-1,Omega,t,'pchip');
Omega = erf(Omega); % normal -> uniform (check this)

% calculate time-varying temporal modulation rate at phi Hz sampling rate
Phi = randn(1,phi*ceil(duration));
Phi = interp1(0:phi*ceil(duration)-1,Phi,t,'pchip');
Phi = erf(Phi); % normal -> uniform (check this)

DMR = sin(2 * pi * Omega + cumsum(Phi)/Fs);



















