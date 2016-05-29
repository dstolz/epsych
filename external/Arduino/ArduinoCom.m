function Val = ArduinoCom(A,Command,timeout)
% Val = ArduinoCom(A,Command)
% Val = ArduinoCom(Command)
% Val = ArduinoCom(...,timeout)
% ArduinoCom(...,Command,...)
% 
% A       ... Serial object (required on first call)
% Command ... command string
% timeout ... define timeout duration when waiting for a response from
%             Arduino (default = 1 second)
% 
% Optionally returns numerical value from Arduino
% 
% If no output is expected, then specifying no output arguments will skip
% listening to Arduino.
%
% See also, ArduinoConnect
% 
% Daniel.Stolzberg@gmail.com 2015

persistent S

if isa(A,'serial')
    if nargin == 1, Val = true; return; end

    S = A;
end

if isempty(S), error('Must specify Serial object on first call.'); end

if nargin == 1, Command = A; end

Val = nan;


while ~isequal(S.TransferStatus,'idle'), end

while S.BytesAvailable, fgetl(S); end  % get rid of any junk in the buffer

fprintf(S,Command); % send command to module

if ~nargout, return; end % doesn't want to wait for output

if nargin < 3 || isempty(timeout) || isnumeric(timeout)
    timeout = 0.5; % seconds
end

t = tic;
while ~S.BytesAvailable
    if toc(t) > timeout
%         error('GetArduinoVal:Unable to communicate with Arduino.\n--> Command = %s\n',Command)
        Val = nan;
        return
    end
    pause(0.001);
end

% pause(0.01);
[s,cnt,msg] = fgetl(S);
% cnt
% msg

if nargout
    Val = s;
%     Val = str2double(s);
    % if the returned string can't be converted to a number, then just
    % return the buffer as a string
%     if isnan(Val), Val = s; end 
%     Val
end



