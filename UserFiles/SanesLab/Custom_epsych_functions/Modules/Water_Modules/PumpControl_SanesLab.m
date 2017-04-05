function varargout = PumpControl_SanesLab
% pump = PumpControl_SanesLab
%
% Custom function for SanesLab epsych
% 
% This function first determines whether food or water reward is going to be delivered. 
% Then it sets and controls a New Era-1000 Syringe Pump.
%
% Outputs:
%   varargout{1}: serial port object associated with pump
%
%
% Daniel.Stolzberg@gmail.com 2014. Edited by MLC 4/5/17.

global AX RUNTIME REWARDTYPE


%-----------------------------------------------------------
%FIRST ASK: FOOD OR WATER REWARD???
%-----------------------------------------------------------

%Find RZ6 index
handles = findModuleIndex_SanesLab('RZ6', []);

%Rename rewardtype parameter for OpenEx Compatibility
if RUNTIME.UseOpenEx
    param = [handles.module,'.','RewardType'];
else
    param  = 'RewardType';
end

%If the RewardType tag is not in the circuit, 
if isempty(find(ismember(RUNTIME.TDT.devinfo(handles.dev).tags,param),1))
    
    REWARDTYPE = 'water';

%If it is in the circuit, but it's not in the protocol, set to default (water)
elseif  ~isempty(find(ismember(RUNTIME.TDT.devinfo(handles.dev).tags,param),1)) && ...
        isempty(find(ismember(RUNTIME.TRIALS.writeparams,param),1))
    
    REWARDTYPE = 'water';
    TDTpartag(AX,RUNTIME.TRIALS,[handles.module,'.',param],0);

%If it is in the circuit, and it's in the protocol, get value from circuit
else ~isempty(find(ismember(RUNTIME.TDT.devinfo(handles.dev).tags,param),1)) && ...
        ~isempty(find(ismember(RUNTIME.TRIALS.writeparams,param),1))
    
    %Get value of parameter tag from circuit
    REWARDTYPE = TDTpartag(AX,RUNTIME.TRIALS,[handles.module,'.',param]);
end

%-----------------------------------------------------------


%Abort if we're using food reward
if strcmp(REWARDTYPE,'food')
    return
end


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

















