function varargout = gen_logchirp(Fs,t1,f,phi,gate_dur)
% [y,<t>] = gen_logchirp(Fs,t1,f,<phi>,<gate_dur>)
% 
% Produce logarithmic swept-sine.
%
% Input:
%   Fs       ...   Sampling frequency (Hz)
%   t1       ...   Duration of sweep (seconds)
%   f        ...   Frequency range of sweep (Hz), ex: [100 10000]
%   phi      ...   Phase offset (degrees; default = 0)
%   gate_dur ...   Duration of a Hann gate (seconds; default = 0, no gate)
%
% Output:
%   y        ...   Vector containing frequency sweep values.
%   t        ...   Time vector corresponding to y (seconds)
%
% ex:
%
%   Fs = 44100;
%   f  = [100 10000];
%   t1 = 1;
%   [y,tvec] = gen_logchirp(Fs,t1,f);
%
%   % Plot data
%   figure;
%   subplot(411);
%   plot(tvec,y);
%   xlim(tvec([1 end]))
%   subplot(4,1,[2 4]);
%   spectrogram(y,hann(256),200,1028,Fs,'yaxis');
%   colorbar off
% 
%   % Play sine
%   a = audioplayer(y,Fs);
%   play(a)
% 
% See also, chirp
%
% Daniel.Stolzberg@gmail.com 2015


narginchk(3,5)
nargoutchk(1,2)

f0 = f(1); % start freq (Hz)
f1 = f(2); % end freq (Hz)

if nargin < 4 || isempty(phi)
    phi = 0;  % phase offset (deg)
end

if nargin < 5 || isempty(gate_dur)
    gate_dur = 0; % gate duration (sec)
end

t = 0:1/Fs:t1-1/Fs; % s


instPhi = t1/log(f1/f0)*(f0*(f1/f0).^(t/t1)-f0); % instantaneous phase

y = sin(2*pi * (instPhi + phi/360)); % swept-sine

if gate_dur > 0 % optionally apply gate
    gsamps = ceil(Fs*gate_dur);
    if ~rem(gsamps,2), gsamps = gsamps + 1; end 
    g = hann(gsamps*2)';
    y(1:gsamps) = y(1:gsamps).*g(1:gsamps);
    y(end-gsamps:end) = y(end-gsamps:end).*g(gsamps:end);
end


varargout{1} = y;
varargout{2} = t;


