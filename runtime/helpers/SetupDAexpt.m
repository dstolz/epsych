function [DA,TDT] = SetupDAexpt(tank)
% [DA,TDT] = SetupDAexpt
% [DA,TDT] = SetupDAexpt(tank)
% 
% Used to initiate an experiment with OpenEx
% 
% If the input, tank, is omitted then a prompt will appear to select or
% create a tank.
% 
% DA is an ActiveX object that controls an experiment designed in OpenEx.
% 
% TDT.tank
% TDT.server
% 
% 
% See also, ReadDAtags, UpdateDAtags, TDT_GetDeviceInfo
% 
% Daniel.Stolzberg@gmail.com 2014

% Copyright (C) 2016  Daniel Stolzberg, PhD

% narginchk(0,1);
if nargin == 0, tank = [];        end
    



if isempty(tank)
    % launch a GUI where the user can select a server and a tank to record
    % into
    TDT = TDT_TTankInterface;
    if isempty(TDT.tank)
        DA = [];
        return
    end
end



% Instantiate OpenDeveloper ActiveX control and select active tank
DA = TDT_SetupDA(TDT.tank,TDT.server);


% Update system state.  Note: System set to Preview or Record in timer
% start function.
DA.SetSysMode(1); pause(0.5); % Standby



% % Confirm TDT parameters
% if ~DA.CheckServerConnection
%     error('Unable to connect to server')
% end

TDT.tank = DA.GetTankName;












