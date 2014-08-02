function varargout = TDT_NewTank(varargin)
% TDT_NEWTANK M-file for TDT_NewTank.fig

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
function TDT_NewTank_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<INUSL>
handles.regKey = 'HKCU\Software\MATHWORKS\MATLAB\TDT_CustomGUI';

% tankdir  = GetRegKey(handles.regKey,'tankdir');
% tankname = GetRegKey(handles.regKey,'tankname');
% regtank  = GetRegKey(handles.regKey,'regtank');
tankdir = getpref('TDT_NewTank','tankdir',cd);
tankname = getpref('TDT_NewTank','tankname','');
% regtank = 
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

set(handles.tankdir,'String',tankdir);
set(handles.tankname,'String',tankname);
% set(handles.registertank,'Value',regtank);

setpref('TDT_NewTank','tankdir',tankdir);
setpref('TDT_NewTank','tankname',tankname)

handles.output = hObject;
guidata(hObject, handles);



% --- Outputs from this function are returned to the command line.
function varargout = TDT_NewTank_OutputFcn(hObject, eventdata, handles)  %#ok<INUSL>
varargout{1} = handles.output;

















%% GUI Callbacks
function browse_Callback(hObject, eventdata, handles) %#ok<DEFNU,INUSL>
tankdir = uigetdir;
if ~tankdir, return; end

set(handles.tankdir,'String',tankdir);

function ok_Callback(hObject, eventdata, handles) %#ok<INUSL,DEFNU>
set(gcf,'Pointer','watch'); drawnow

tankname = get(handles.tankname,'String');
tankdir  = get(handles.tankdir,'String');
tankpath = fullfile(tankdir,tankname,'');

if ~exist(tankpath,'dir')
    [s,m,mid] = mkdir(tankdir,tankname); %#ok<NASGU>
    if ~s
        warndlg(m,'Unable to create tank!','modal');
        close(handles.TDT_NewTank);
    end
end

regval = get(handles.registertank,'Value');
if regval
    if ~addTankToRegistry(tankname,tankdir)
        warning('Unable to Register Tank Propertly!');
    end
end

SetRegKey(handles.regKey,'tankdir',tankdir);
SetRegKey(handles.regKey,'tankname',tankname);
SetRegKey(handles.regKey,'regtank',regval);

set(gcf,'Pointer','arrow'); drawnow
close(handles.TDT_NewTank);


function TDT_NewTank_CloseRequestFcn(hObject, eventdata, handles) %#ok<INUSD,DEFNU>

% Hint: delete(hObject) closes the figure
delete(hObject);
