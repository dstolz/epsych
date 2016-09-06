function t = zBUS_trig(DA)
% t = zBUS_trig(DA)
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
% 
% See manual for details.
% 
% Daniel.Stolzberg@gmail.com 2014

% Copyright (C) 2016  Daniel Stolzberg, PhD

DA.SetTargetVal(flags.ZBUSB_ON,1); t = hat;
DA.SetTargetVal(flags.ZBUSB_OFF,1);