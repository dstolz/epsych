function t = zBUS_trig(DA,p)
% t = zBUS_trig(DA,P)
% 
% *********THIS NEEDS TO BE UPDATED******************
% 
% This will trigger zBusB synchronously across modules
%   Note: Two ScriptTag components must be included in one of the RPvds
%   circuits.  
%       The ZBUS_ON ScriptTag should have the following code:
%           Sub main
%               TDT.ZTrgOn(Asc("B"))
%           End Sub
% 
%       The ZBUS_OFF ScriptTag should have the following code:
%           Sub main
%               TDT.ZTrgOff(Asc("B"))
%           End Sub


% ****** OLD CODE ***NEEDS TO BE UPDATED**********
if isempty(flags.ZBUSB_ON), t = hat; return; end
DA.SetTargetVal(flags.ZBUSB_ON,1);
t = hat; % start timer for next trial
DA.SetTargetVal(flags.ZBUSB_OFF,1);