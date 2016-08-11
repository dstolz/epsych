function varargout = PumpControl_SanesLab
% pump = PumpControl_SanesLab
%
% Custom function for SanesLab epsych
% 
% This function sets and controls a New Era-1000 Syringe Pump.
%
% Outputs:
%   varargout{1}: serial port object associated with pump
%
%
% Daniel.Stolzberg@gmail.com 2014. Edited by MLC Aug 08 2016.


%Close and delete all open serial ports
out = instrfind('Status','open');
if ~isempty(out)
    fclose(out);
    delete(out);
end

%Create a serial connection to the pump
pump = serial('com1','BaudRate',19200,'DataBits',8,'StopBits',1,'TimerPeriod',0.1);
fopen(pump);

warning('off','MATLAB:serial:fscanf:unsuccessfulRead')
set(pump,'Terminator','CR','Parity','none','FlowControl','none','timeout',0.1);


%Set up pump parameters. Obtain diameter, min and max rates from the last
%page of the NE-1000 Syringe Pump User Manual.
fprintf(pump,'DIA%0.1f\n',20.12); % set inner diameter of syringe (mm)
fprintf(pump,'RAT%s\n','MM');    % set rate units to mL/min
fprintf(pump,'RAT%0.1f\n',20);   % set rate
fprintf(pump,'INF\n');           % set to infuse
fprintf(pump,'VOL%0.2f\n',0);    % set unlimited volume to infuse (==0)
fprintf(pump,'TRGLE\n');         % set trigger type

%Send out variable arguments, if appropriate
if nargout == 1 
    varargout{1} = pump;
else
    fclose(pump); delete(pump)
end

vprintf(0,'Connected to pump.')

















