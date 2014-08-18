function [DA,C] = SetupDAexpt(C,varargin)
% [DA,C] = SetupDAexpt(C)
% [DA,C] = SetupDAexpt(C,tank)
% 
% Used by ep_RunExpt when using in conjunction with OpenEx
% 
% Where C is an Nx1 structure array with atleast the subfields:
% C.OPTIONS
% C.MODULES
% C.COMPILED
% 
% DA is an ActiveX object that controls an experiment designed in OpenEx.
% 
% C.COMPILED.datatype is a cell array of characters indicating the datatype
% of the parameters which will be read from the RPvds circuits during
% runtime.  See TDT ActiveX manual for datatype definitions.
% 
% C.TANK
% 
% 
% See also, ReadDAtags, UpdateDAtags
% 
% Daniel.Stolzberg@gmail.com 2014



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
DA.SetSysMode(0); pause(1); disp('System set to Idle')    % Idle
DA.SetSysMode(1); pause(1); disp('System set to Standby') % Standby


C.TDT = TDT;


















