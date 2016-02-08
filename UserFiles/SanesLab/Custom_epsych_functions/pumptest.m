%Create a serial connection to the pump
clear all;
clc

pump = serial('com1','BaudRate',19200,'DataBits',8,'StopBits',1,'TimerPeriod',0.1);
fopen(pump);

warning('off','MATLAB:serial:fscanf:unsuccessfulRead')
set(pump,'Terminator','CR','Parity','none','FlowControl','none','timeout',0.1);


%% Set up pump parameters. 
fprintf(pump,'DIA%0.1f\n',20.12); % set inner diameter of syringe (mm)
fscanf(pump);


fprintf(pump,'TRGLE\n'); %set trigger to level trigger (rising start, falling stop)
fscanf(pump);

%% DIAMETER (20.12)
fprintf(pump,'DIA\n'); fscanf(pump,'%s',4); % discard junk 4 bytes
D = fscanf(pump,'%f')




%% TRIGGER TYPE (LE)

fprintf(pump,'TRG\n'); fscanf(pump,'%s',4); % discard junk 4 bytes
trig = fscanf(pump,'%f')



%% DIRECTIONAL CONTROL (0)
fprintf(pump,'DIN\n'); fscanf(pump,'%s',4); % discard junk 4 bytes
din = fscanf(pump,'%f')

%% TTL IN (3,4,6 == 1;  2 == 0)

fprintf(pump,'IN2'); fscanf(pump,'%s',4); % discard junk 4 bytes
TTL_in = fscanf(pump,'%f')


%% 
fclose(pump); delete(pump)
