function varargout = TC4controller(varargin)
% TC4CONTROLLER MATLAB code for TC4controller.fig
%
% Daniel.Stolzberg@gmail.com 2016

% Edit the above text to modify the response to help TC4controller

% Last Modified by GUIDE v2.5 28-May-2016 18:01:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TC4controller_OpeningFcn, ...
                   'gui_OutputFcn',  @TC4controller_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before TC4controller is made visible.
function TC4controller_OpeningFcn(hObj, ~, h, varargin)

h.A = ArduinoConnect('BaudRate',115200);

for i = 0:3
    ArduinoCom(h.A,sprintf('H,%d',i)); % ensure the pump is off
    ArduinoCom(h.A,sprintf('E,%d,%d',i,1)); % disable
end

h.T = CreateTimer(hObj);
start(h.T);

guidata(hObj, h);

% --- Outputs from this function are returned to the command line.
function varargout = TC4controller_OutputFcn(hObj, ~, h) 



function TC4controller_close(hObj,h)
fprintf('Closing connection to Arduino ...')
fclose(h.A);
fprintf(' closed\n')
stop(h.T);
delete(hObj);


% Timer
function T = CreateTimer(f)
% Create new timer
T = timerfind('Name','TCtimer');
if ~isempty(T), stop(T); delete(T); end
T = timer(                                   ...
    'BusyMode',     'drop',                  ...
    'ExecutionMode','fixedRate',             ...
    'TasksToExecute',inf,                    ...
    'Period',        0.5,                      ...
    'Name',         'TCtimer',               ...
    'TimerFcn',     {@TCTimer,f},            ...
    'StartDelay',   1);



function TCTimer(~,~,f)
h = guidata(f);

idata = get(h.interfaceTable,'Data');

activeProbes = cell2mat(idata(:,1))';

Probes = 1:length(activeProbes);
for i = Probes
    if activeProbes(i)
        try
            t = ArduinoCom(h.A,sprintf('c,%d',i-1)); % current probe temp;
            v = str2double(t);
            idata{i,3} = round(v*1000)/1000;
            
            t = ArduinoCom(h.A,sprintf('s,%d',i-1)); % current pump speed;
            v = str2double(t);
            idata{i,6} = round(v*1000)/1000;
            
            t = ArduinoCom(h.A,sprintf('m,%d',i-1)); % check mode
            v = str2double(t);
            idata{i,5} = logical(v);
        catch me
            disp('Failed com')
        end
    else
        idata{i,3} = [];
        idata{i,5} = 0;
        idata{i,6} = [];
    end
end


set(h.interfaceTable,'Data',idata);



% Table
function interfaceTable_CellEditCallback(hObj, evnt, h) %#ok<DEFNU>
if isempty(evnt.Indices), return; end
h = guidata(h.figure1);
% evnt
% evnt.Error
r = evnt.Indices(1);
c = evnt.Indices(2);
% idata = get(hObj,'Data');
% v = idata{r,c};
v = evnt.EditData;
switch c
    case 1 % enable/disable
        if ~v
            while 'X' ~= ArduinoCom(h.A,sprintf('H,%d',r-1)); end% ensure the pump is off
        end
        while 'X' ~= ArduinoCom(h.A,sprintf('E,%d,%d',r-1,v)); end % enable/disable
        
    case 2 % name
        
    case 4 % target temp
        
    case 5 % pid
        while 'X' ~= ArduinoCom(h.A,sprintf('M,%d,%d',r-1,v)); end % enable/disable PID
        
end

% --- Executes when selected cell(s) is changed in interfaceTable.
function interfaceTable_CellSelectionCallback(hObj, evnt, h) %#ok<DEFNU>
if isempty(evnt.Indices), return; end
h = guidata(h.figure1);
r = evnt.Indices(1);
c = evnt.Indices(2);
idata = get(hObj,'Data');
v = idata{r,c};
opts.Resize = 'off';
opts.WindowStyle = 'modal';
opts.Interpreter = 'none';
switch c
    case 1 % enable/disable
        
    case 2 % name
        newName = inputdlg({sprintf('Name Channel %d',r)},'Name',1,{v},opts);
        if isempty(newName), return; end
        idata(r,2) = newName;
        
        
    case 4 % target temp
        newTarg = inputdlg({sprintf('Target Temperature Channel %d',r)}, ...
            'Target',1,{num2str(v,'%0.2f')},opts);
        if isempty(newTarg), return; end
        if ~checkStrIsNum(char(newTarg))
            warndlg(sprintf('''%s'' cannot be converted to a number.',char(newTarg)), ...
                'invalid value','modal');
            return
        end
        idata{r,4} = str2double(char(newTarg));
        fprintf('T,%d,%0.2f\n',r-1,idata{r,4})
        while 'X' ~= ArduinoCom(h.A,sprintf('T,%d,%0.2f',r-1,idata{r,4})); end % update target temp
        
    case 5 % pid

        
end

set(hObj,'Data',idata);




% % Plot
function updatePlot(ax,temps,speeds,nsamps)







