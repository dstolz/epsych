function varargout = testFigure(varargin)
% TESTFIGURE MATLAB code for testFigure.fig
%      TESTFIGURE, by itself, creates a new TESTFIGURE or raises the existing
%      singleton*.
%
%      H = TESTFIGURE returns the handle to a new TESTFIGURE or the handle to
%      the existing singleton*.
%
%      TESTFIGURE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TESTFIGURE.M with the given input arguments.
%
%      TESTFIGURE('Property','Value',...) creates a new TESTFIGURE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before testFigure_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to testFigure_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help testFigure

% Last Modified by GUIDE v2.5 24-Mar-2016 13:32:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @testFigure_OpeningFcn, ...
                   'gui_OutputFcn',  @testFigure_OutputFcn, ...
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


% --- Executes just before testFigure is made visible.
function testFigure_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to testFigure (see VARARGIN)

% Choose default command line output for testFigure
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

global motorBox LEDValue

LEDValue = 0;
motorBox = serial('COM3');
set(motorBox,'BaudRate',115200);
fopen(motorBox);
pause(2);

% UIWAIT makes testFigure wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = testFigure_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function locSlider_Callback(hObject, eventdata, handles)
% hObject    handle to locSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function locSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to locSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% First bit
function radio1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global motorBox LEDValue
tempBin = dec2bin(LEDValue, 4);
if (tempBin(4)) == '0'
    LEDValue = LEDValue + 1;
else
    LEDValue = LEDValue - 1;
end
fprintf(motorBox,'%d',LEDValue);



% Second bit
function radio2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global motorBox LEDValue
tempBin = dec2bin(LEDValue, 4);
if (tempBin(3)) == '0'
    LEDValue = LEDValue + 2;
else
    LEDValue = LEDValue - 2;
end
fprintf(motorBox,'%d',LEDValue);


% Third bit
function radio3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global motorBox LEDValue
tempBin = dec2bin(LEDValue, 4);
if (tempBin(2)) == '0'
    LEDValue = LEDValue + 4;
else
    LEDValue = LEDValue - 4;
end
fprintf(motorBox,'%d',LEDValue);


% Fourth bit
function radio4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global motorBox LEDValue
tempBin = dec2bin(LEDValue, 4);
if (tempBin(1)) == '0'
    LEDValue = LEDValue + 8;
else
    LEDValue = LEDValue - 8;
end
fprintf(motorBox,'%d',LEDValue);