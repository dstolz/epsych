function Val = ArduinoCom(A,Command)
% Val = ArduinoCom(A,Command)
% Val = ArduinoCom(Command)
% 
% A ... Serial object (required on first call)
% Command ... command string
%
% Optionally returns numerical value from Arduino
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

if S.BytesAvailable, fgetl(S); end  % get rid of any junk in the buffer

fprintf(S,Command); % send command to module



timeout = 2; % seconds
t = tic;
while ~S.BytesAvailable
    if toc(t) > timeout
        fprintf(2,'GetArduinoVal:Unable to communicate with Arduino.\n--> Command = %s\n',Command) %#ok<PRTCAL>
        return
    end
    pause(0.01);
end


s = fgetl(S);

if nargout
    Val = str2double(s);
    % if the returned string can't be converted to a number, then just
    % return the buffer as a string
    if isnan(Val), Val = s; end 
end



