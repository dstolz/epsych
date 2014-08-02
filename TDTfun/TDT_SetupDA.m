function varargout = TDT_SetupDA(tank)
% DA = TDT_SetupDA;
% DA = TDT_SetupDA(tank);
% [DA,tank] = TDT_SetupDA;
% 
% The TDT TDevAcc activex control is used to interface with running OpenEx
% 
% Initialize TDT TDevAcc activex control in invisible window and return
% handle to control (DA), registered tanks, and a handle to the invisible
% figure.  The invisible figure is named 'ODevFig' and can be found using: 
% h = findobj('Type','figure','-and','Name','ODevFig')
% 
% If a handle to the TDevAcc activex control is supplied in 'DA', then this
% function will simply return that handle and registered tanks.
% 
% Input Parameters:
%       'DA'    ...  handle to TDevAcc activex control if already established
%       'tank'  ...  Set active tank
% 
% Output:
%       DA = TDT_SetupDA(...  where DA is a handle to the TDevAcc activex control
%       [DA,tank] = TDT_SetupDA(...  where tank is the currently active tank
% 
% See also TDT_SetupTT, TDT_SetupRP
% 
% DJS (c) 2010

if ~exist('tank','var'), tank = []; end

h = findobj('Type','figure','-and','Name','ODevFig');
if isempty(h)
    h = figure('Visible','off','Name','ODevFig');
end

DA = actxcontrol('TDevAcc.X','parent',h);

DA.ConnectServer('Local');

if ~isempty(tank), DA.SetTankName(char(tank)); end

varargout{1} = DA;
varargout{2} = DA.GetTankName;
