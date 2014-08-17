function varargout = TDT_NewTank(varargin)
% TDT_NewTank
% TDT_NewTank(tankname)
% 
% 

% Last Modified by GUIDE v2.5 22-Mar-2011 11:58:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TDT_NewTank_OpeningFcn, ...
                   'gui_OutputFcn',  @TDT_NewTank_OutputFcn, ...
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


% --- Executes just before TDT_NewTank is made visible.
function TDT_NewTank_OpeningFcn(hObj, evnt, h, varargin) %#ok<INUSL>
tankdir  = getpref('TDT_NewTank','tankdir',cd);
tankname = getpref('TDT_NewTank','tankname','');

for i = 1:2:length(varargin)
    switch lower(varargin{i})
%         case 'register'
%             regtank = varargin{i+1};
        case 'tank'
            tankname = varargin{i+1};
        case 'tankdir'
            tankdir  = varargin{i+1};
    end
end

% if isempty(regtank), regtank = 0; elseif ischar(regtank), regtank = str2num(regtank); end %#ok<ST2NM>

set(h.tankdir,'String',tankdir);
set(h.tankname,'String',tankname);

setpref('TDT_NewTank','tankdir',tankdir);
setpref('TDT_NewTank','tankname',tankname)

h.output = hObj;
guidata(hObj, h);



% --- Outputs from this function are returned to the command line.
function varargout = TDT_NewTank_OutputFcn(hObj, evnt, h)  %#ok<INUSL>
varargout{1} = h.output;

















%% GUI Callbacks
function browse_Callback(hObj, evnt, h) %#ok<DEFNU,INUSL>
tankdir = uigetdir;
if ~tankdir, return; end

set(h.tankdir,'String',tankdir);

function ok_Callback(hObj, evnt, h) %#ok<INUSL,DEFNU>
set(gcf,'Pointer','watch'); drawnow

tankname = get(h.tankname,'String');
tankdir  = get(h.tankdir,'String');
tankpath = fullfile(tankdir,tankname,'');

if ~exist(tankpath,'dir')
    [s,m,mid] = mkdir(tankdir,tankname); %#ok<NASGU>
    if ~s
        warndlg(m,'Unable to create tank!','modal');
        close(h.TDT_NewTank);
    end
end

regval = get(h.registertank,'Value');
if regval
    if ~addTankToRegistry(tankname,tankdir)
        warning('Unable to Register Tank Propertly!');
    end
end

SetRegKey(h.regKey,'tankdir',tankdir);
SetRegKey(h.regKey,'tankname',tankname);
SetRegKey(h.regKey,'regtank',regval);

set(gcf,'Pointer','arrow'); drawnow
close(h.TDT_NewTank);


function TDT_NewTank_CloseRequestFcn(hObj, evnt, h) %#ok<INUSD,DEFNU>

% Hint: delete(hObj) closes the figure
delete(hObj);
