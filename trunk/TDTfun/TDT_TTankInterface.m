function varargout = TDT_TTankInterface(varargin)
% TDT = TDT_TTankInterface
% TDT = TDT_TTankInterface(TDT)
% TDT = TDT_TTankInterface('server','SomeServer','tank','SomeTank')
% h = TDT_TTankInterface(...,'maintain')
%
% Select/Create TDT server, tank, block, etc. using TTankInterface ActiveX
% GUI
%
% TDT output is a structure with fields with corresponding selected values:
%   TDT.server
%   TDT.tank
%   TDT.block
%   TDT.event
%
% Optionally, this function can be called with inputs to specify a default
% server, tank, block, and event.  Input can specified either as a
% structure with one or multiple fields outlined above for the TDT output
% structure, or as parameter-value pairs.
% 
%   ex: TDT.server = 'Local';
%       TDT.tank   = 'DEMOTANK2';
%       TDT = TDT_TTankInterface(TDT);
% 
%   ex: TDT = TDT_TTankInterface('server','local','tank','DEMOTANK2');
% 
% This interface can also be used by another script or GUI to navigate data
% tanks.  For this behavior, use the keyword 'maintain' as the final input
% to the function.  This syntax will return a figure handle and the current
% selection can be accessed using getappdata.
% 
%   ex: h = TDT_TTankInterface('maintain')
%       TDT = getappdata(h,'TDT');
% 
% 
%   ex: h = TDT_TTankInterface('server','SomeServer','maintain')
%       TDT = getappdata(h,'TDT');
% 
% 
% Daniel.Stolzberg@gmail.com 2014

% Last Modified by GUIDE v2.5 17-Aug-2014 17:28:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @TDT_TTankInterface_OpeningFcn, ...
    'gui_OutputFcn',  @TDT_TTankInterface_OutputFcn, ...
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


% --- Executes just before TDT_TTankInterface is made visible.
function TDT_TTankInterface_OpeningFcn(hObj, ~, h, varargin)

TDT.server = '';
TDT.tank   = '';
TDT.block  = '';
TDT.event  = '';
h.fn = fieldnames(TDT);

h.maintain = false;

if ~isempty(varargin)
    if strcmpi(varargin{end},'maintain')
        h.maintain = true;
        varargin(end) = [];
    end
end

if ~isempty(varargin) && ~isempty(varargin{1})
    if isstruct(varargin{1})
        vfn = fieldnames(varargin{1})';
        for i = vfn
            TDT.(lower(char(i))) = varargin{1}.(char(i));
        end
    else
        idx = find(~ismember(varargin(1:2:end),h.fn));
        if ~isempty(idx), varargin([idx idx+1]) = []; end
        for i = 1:2:length(varargin)
            TDT.(varargin{i}) = varargin{i+1};
        end
    end
end
setappdata(h.figure1,'TDT',TDT);

guidata(hObj,h);

UpdateDisplay(h,1);

if ~h.maintain, uiwait(h.figure1); end


% --- Outputs from this function are returned to the command line.
function varargout = TDT_TTankInterface_OutputFcn(hObj, ~, ~)
global TDT
if ~ishandle(hObj)
    varargout{1} = TDT;
    return
end
h = guidata(hObj);
if h.maintain
    varargout{1} = h.figure1;
else
    varargout{1} = h.TDT;
    close(h.figure1);
end



function activex1_ServerChanged(~, ~, h) %#ok<DEFNU>
UpdateDisplay(h)

function activex2_TankChanged(~, ~, h) %#ok<DEFNU>
UpdateDisplay(h)

function activex3_BlockChanged(~, ~, h) %#ok<DEFNU>
UpdateDisplay(h)

function activex4_ActEventChanged(~, ~, h) %#ok<DEFNU>
UpdateDisplay(h)




function UpdateDisplay(h,init)
global TDT

A = [h.activex1 h.activex2 h.activex3 h.activex4];

if nargin>1 && init
    TDT = getappdata(h.figure1,'TDT');
else
    TDT.server = get(A(1),'ActiveServer');
    TDT.tank   = get(A(2),'ActiveTank');
    TDT.block  = get(A(3),'ActiveBlock');
    TDT.event  = get(A(4),'ActiveEvent');
end

if ~isempty(TDT.server)
    set(A(1),'ActiveServer',TDT.server);
    set(A(2:4),'UseServer',TDT.server);
    Refresh(A(2));
    
    if ~isempty(TDT.tank)
        set(A(2),'ActiveTank',TDT.tank);
        set(A(3:4),'UseTank',TDT.tank);
        Refresh(A(3));
        
        if ~isempty(TDT.block)
            set(A(3),'ActiveBlock',TDT.block);
            set(A(4),'UseBlock',TDT.block);
            Refresh(A(4));
            
            if ~isempty(TDT.event)
                set(A(4),'ActiveEvent',TDT.event);
            end
        end
    end
end

[~,tankname] = fileparts(TDT.tank);
str = sprintf('Server:  %s\nTank:    %s\nBlock:   %s\nEvent:   %s', ...
    TDT.server,tankname,TDT.block,TDT.event);
set(h.tank_info,'String',str);

setappdata(h.figure1,'TDT',TDT);




function figure1_CloseRequestFcn(hObj, ~, h) %#ok<DEFNU>
h.TDT = getappdata(h.figure1,'TDT');

guidata(hObj,h);

if ~h.maintain
    delete(hObj);
    return
end

if isequal(get(hObj, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, use UIRESUME
    uiresume(hObj);
else
    % The GUI is no longer waiting, just close it
    delete(hObj);
end
