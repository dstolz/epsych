function DA = TDT_SetupDA(varargin)
% DA = TDT_SetupDA(tank);
% DA = TDT_SetupDA(tank,server);
% 
% The TDT TDevAcc activex control is used to interface with running OpenEx
% 
% Initialize TDT TDevAcc activex control in invisible window and return
% handle to control (DA), registered tanks, and a handle to the invisible
% figure.  The invisible figure is named 'ODevFig' and can be found using: 
% h = findobj('Type','figure','-and','Name','ODevFig')
% 
% This figure should be closed when finished:
%   h = findobj('Type','figure','-and','Name','ODevFig')
%   close(h);
% 
% Input can be a string with a tank name. 
%   ex: DA = TDT_SetupDA('DEMOTANK2');
% 
% A server name can be additionally specified.  Default server is 'local'
%   ex: DA = TDT_SetupDA('DEMOTANK2','SomeServer');
% 
% See also TDT_SetupTT, TDT_SetupRP
% 
% Daniel.Stolzberg@gmail.com 2014

server = 'local';
tank   = [];

if nargin >= 1, tank   = varargin{1}; end
if nargin == 2, server = varargin{2}; end

h = findobj('Type','figure','-and','Name','ODevFig');
if isempty(h)
    h = figure('Visible','off','Name','ODevFig');
end

DA = actxcontrol('TDevAcc.X','parent',h);

DA.ConnectServer(char(server));
if ~isempty(tank),   DA.SetTankName(char(tank));     end
