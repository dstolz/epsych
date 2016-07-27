function varargout = TrialFcn_PumpControl
% Custom function for SanesLab epsych
% This function sets and controls a New Era-1000 Syringe Pump.
%
%
% Daniel.Stolzberg@gmail.com 2014. Edited by MLC 7.22.2016.


disp('CONNECTING TO PUMP...')

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

disp('READY_FOR_ANIMAL')


















