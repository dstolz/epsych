function TrialFcn_PumpControl(ID,rate)
% TrialFcn_PumpControl
% TrialFcn_PumpControl(ID)
% TrialFcn_PumpControl(ID,rate)
%
% This function sets and controls the pump variables for the Aversive AM
% Detection task.
%
% Optional: ID = inner diameter of the syringe
%
% Daniel.Stolzberg@gmail.com 2014. Edited by MLC 10/30/2014.

% global pump % Added for external access DJS 08-May-2015

% check defaults
if nargin == 0, ID = 20.4; end



fprintf('CONNECTING TO PUMP...')

pump = serial('com1','BaudRate',19200,'DataBits',8,'StopBits',1,'TimerPeriod',0.1);

fopen(pump)

warning('off','MATLAB:serial:fscanf:unsuccessfulRead')
set(pump,'Terminator','CR','Parity','none','FlowControl','none','timeout',0.1);


% always query pump even when not setting a value
fprintf(pump,'DIA%0.1f\n',ID); fscanf(pump); % set diameter
fprintf(pump,'RAT%s\n','MM');    fscanf(pump); % set to mL/min
fprintf(pump,'RAT%0.3f\n',rate);  fscanf(pump); % set rate
fprintf(pump,'INF\n');           fscanf(pump); % set to infuse
fprintf(pump,'VOL%0.2f\n',1);    fscanf(pump); % set volume to infuse
fprintf(pump,'TRGLE\n');         fscanf(pump); % set trigger type

% confirm new values
fprintf(pump,'DIA\n'); fscanf(pump,'%s',4); % discard junk 4 bytes
D = fscanf(pump,'%f');

fprintf(pump,'RAT\n'); fscanf(pump,'%s',4);
Pump_Rate = fscanf(pump,'%f')

fprintf(pump,'VOL\n'); fscanf(pump,'%s',4);
V = fscanf(pump,'%f');

%
fclose(pump); delete(pump)
warning('on','MATLAB:serial:fscanf:unsuccessfulRead')
fprintf('READY_FOR_ANIMAL\n')



















