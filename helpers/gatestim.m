function varargout = gatestim(signal,gate_duration,Fs,varargin)
% Y = gatestim(signal,gate_duration,Fs)
% Y = gatestim(signal,gate_duration,Fs,gatetype)
% Y = gatestim(duration,gate_duration,Fs)
% Y = gatestim(duration,gate_duration,Fs,somefunc)
% Y = gatestim(duration,gate_duration,Fs,somefunc,gatetype)
% [Y,tvec] = gatestim(signal,gate_duration,Fs,...)
% [Y,tvec] = gatestim(duration,gate_duration,Fs,...)
% 
% Convenient function to apply a gate to some arbitrary signal or generate
% a signal using some other function and then apply gate.
% 
% duration and gate_duration are in seconds.
% 
% Fs is the signal sampling rate in Hz.
% 
% somefunc is some function to generate the signal.  Only used if a scalara
% value is specified as the first input parameter.  Default = @randn
% 
% gatetype is passed to the WINDOW function (see help window).  Default =
% @triang (same as a linear gate).  Also available: 'cos2' for cosine
% squared gate.
% 
% ex:
%  % Generate a 400 ms Gaussian noise stimulus with 200 ms blackman gate
%  [Y,tvec] = gatestim(0.4,0.2,44100,@randn,'blackman';
%  plot(tvec,Y);
%
%  % Apply a 100 ms cos^2 gate to a some pre-existing vector called signal
%  [Y,tvec] = gatestim(signal,0.1,44100,'cos2');
%  plot(tvec,Y);
% 
% Daniel.Stolzberg@gmail.com 2015

% Copyright (C) 2016  Daniel Stolzberg, PhD

durflag = isscalar(signal);
somefunc = @randn;
gatetype = @triang;
if durflag
    duration = signal;
    if nargin > 3, somefunc = varargin{1}; end
    if nargin > 4, gatetype = varargin{2}; end
else
    duration = length(signal)/Fs;
    if nargin > 3, gatetype = varargin{1}; end    
end

assert(gate_duration <= duration,'gatestim:gate_duration must be shorter than the length of the signal')

gateN = round(gate_duration*Fs);
if rem(gateN,2), gateN = gateN + 1; end

if isa(gatetype,'function_handle'), gatetype = func2str(gatetype); end
switch lower(gatetype)
    case 'linear'
        gate = window(@triang,gateN);
        
    case 'cos2'
        n = (0:gateN-1)'-gateN/2;
        gate = cos((pi*n)/(gateN-1)-pi/2).^2;
        gate = [gate(gateN/2+1:end); gate(1:gateN/2)];
        
    otherwise
        % use WINDOW function
        gate = window(gatetype,gateN);
end

gate_on  = gate(1:gateN/2);
gate_off = gate(gateN/2+1:end);


% make gate multiplier
gate = [gate_on(:); ones(round(duration*Fs)-gateN,1); gate_off(:)];

% If only the duration of the signal was supplied, then generate a signal
% using @somefunc
if durflag
    signal = feval(somefunc,length(gate));
    signal = signal / max(abs(signal)); % normalize signal
end

% Apply gate to the signal
signal = signal(:).*gate;

% create time vector
tvec = linspace(0,duration-1/Fs,length(signal));

varargout{1} = signal;
varargout{2} = tvec;








