function [TT,tanks,TDTfig] = TDT_SetupTT(TT)
% TT = TDT_SetupTT
% [TT,tanks] = TDT_SetupTT
% [TT,tanks,TDTfig] = TDT_SetupTT
% TDT_Setup(TT)
% 
% Initialize TDT TTankX activex control in invisible window and return
% handle to control (TT), registered tanks, and a handle to the invisible
% figure (should close when done using: close(TDTfig); or similar.)
% 
% 
% See also TDT_SetupDA, TDT_SetupRP
% 
% DJS (c) 2010

TDTfig = findobj('type','figure','-and','Name','TTankFig');
if ~exist('TT','var') || isempty(TT)
    if isempty(TDTfig)
        TDTfig = figure('Visible','off','Name','TTankFig');
    end
    
    TT = actxcontrol('TTank.X','parent',TDTfig);
else
    TDTfig = [];
end

TT.ConnectServer('Local','Me');
TT.GetEnumTank(0);

if nargout > 1
    tanks = TDT_RegTanks(TT);
end

if nargin
    TT = tanks; 
end

