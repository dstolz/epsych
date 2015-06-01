function varargout = CondAvoidGUI(varargin)
%CONDAVOIDGUI M-file for CondAvoidGUI.fig
%      CONDAVOIDGUI, by itself, creates a new CONDAVOIDGUI or raises the existing
%      singleton*.
%
%      H = CONDAVOIDGUI returns the handle to a new CONDAVOIDGUI or the handle to
%      the existing singleton*.
%
%      CONDAVOIDGUI('Property','Value',...) creates a new CONDAVOIDGUI using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to CondAvoidGUI_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      CONDAVOIDGUI('CALLBACK') and CONDAVOIDGUI('CALLBACK',hObject,...) call the
%      local function named CALLBACK in CONDAVOIDGUI.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CondAvoidGUI

% Last Modified by GUIDE v2.5 27-May-2015 12:43:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CondAvoidGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @CondAvoidGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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


% --- Executes just before CondAvoidGUI is made visible.
function CondAvoidGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for CondAvoidGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes CondAvoidGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = CondAvoidGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in Tone_dBSPL_popup.
function Tone_dBSPL_popup_Callback(hObject, eventdata, handles)
% hObject    handle to Tone_dBSPL_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Tone_dBSPL_popup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Tone_dBSPL_popup


% --- Executes during object creation, after setting all properties.
function Tone_dBSPL_popup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Tone_dBSPL_popup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
