function varargout = my_deltaCSD(varargin)
% MY_DELTACSD M-file for my_deltaCSD.fig
%      MY_DELTACSD, by itself, creates a new MY_DELTACSD or raises the existing
%      singleton*.
%
%      H = MY_DELTACSD returns the handle to a new MY_DELTACSD or the
%      handle to
%      the existing singleton*.
%
%      MY_DELTACSD('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MY_DELTACSD.M with the given input arguments.
%
%      MY_DELTACSD('Property','Value',...) creates a new MY_DELTACSD or raises the
%      existing singleton*.  Starting from the left, property value pairs
%      are
%      applied to the GUI before my_deltaCSD_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to my_deltaCSD_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help my_deltaCSD

% Last Modified by GUIDE v2.5 13-Dec-2005 12:41:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @my_deltaCSD_OpeningFcn, ...
                   'gui_OutputFcn',  @my_deltaCSD_OutputFcn, ...
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


% --- Executes just before my_deltaCSD is made visible.
function my_deltaCSD_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to my_deltaCSD (see VARARGIN)
handles.pot = varargin{2};
handles.dt = varargin{4};

%image(imread('CSD_plotter.png'))
axis off;

% Choose default command line output for my_deltaCSD
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes my_deltaCSD wait for user response (see UIRESUME)
% uiwait(handles.delta_CSD);


% --- Outputs from this function are returned to the command line.
function varargout = my_deltaCSD_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function filter_b0_Callback(hObject, eventdata, handles)
% hObject    handle to filter_b0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of filter_b0 as text
%        str2double(get(hObject,'String')) returns contents of filter_b0 as a double


% --- Executes during object creation, after setting all properties.
function filter_b0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filter_b0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function filter_b1_Callback(hObject, eventdata, handles)
% hObject    handle to filter_b1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of filter_b1 as text
%        str2double(get(hObject,'String')) returns contents of filter_b1 as a double


% --- Executes during object creation, after setting all properties.
function filter_b1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filter_b1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ex_cond_Callback(hObject, eventdata, handles)
% hObject    handle to ex_cond (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ex_cond as text
%        str2double(get(hObject,'String')) returns contents of ex_cond as a double


% --- Executes during object creation, after setting all properties.
function ex_cond_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ex_cond (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function top_cond_Callback(hObject, eventdata, handles)
% hObject    handle to top_cond (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of top_cond as text
%        str2double(get(hObject,'String')) returns contents of top_cond as a double


% --- Executes during object creation, after setting all properties.
function top_cond_CreateFcn(hObject, eventdata, handles)
% hObject    handle to top_cond (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function diam_Callback(hObject, eventdata, handles)
% hObject    handle to diam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of diam as text
%        str2double(get(hObject,'String')) returns contents of diam as a double


% --- Executes during object creation, after setting all properties.
function diam_CreateFcn(hObject, eventdata, handles)
% hObject    handle to diam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in run_all.
function run_all_Callback(hObject, eventdata, handles)
% hObject    handle to run_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in run_this.
function run_this_Callback(hObject, eventdata, handles)
% hObject    handle to run_this (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% filter parameters:
b0 = str2num(get(handles.filter_b0,'String'));
b1 = str2num(get(handles.filter_b1,'String'));
if b0+2*b1 == 0 & b1~=0
    errordlg('Singularity: b0+2*b1 cannot equal zero.');
    return
end;

% electrical parameters:
cond = str2num(get(handles.ex_cond,'String'));
if cond<=0
    errordlg('Ex. cond. has to be a positive number');
    return
end;
cond_top = str2num(get(handles.top_cond,'String'));

% size, potential (m1 has to equal number of electrode contacts)
[m1,m2] = size(handles.pot);

% geometrical parameters:
diam = str2num(get(handles.diam,'String'))*1e-3; %diameter in [m]
if diam<=0
    errordlg('Diameter has to be a positive number.');
    return
end;

el_pos = str2num(get(handles.electrode_pos,'String'))*1e-3;
if cond_top~=cond & (el_pos~=abs(el_pos) | length(el_pos)~=length(nonzeros(el_pos)))
    errordlg('Electrode contact positions must be positive when top cond. is different from ex. cond.')
    return;
end;
if m1~=length(el_pos)
    errordlg(['Number of electrode contacts has to equal number of rows in potential matrix. Currently there are ',...
        num2str(length(el_pos)),' electrodes contacts, while the potential matrix has ',num2str(m1),' rows.']) 
    return
end;

% compute delta iCSD:
CSD = F_delta(el_pos,diam,cond,cond_top)^-1*handles.pot;

if b1~=0 %filter iCSD
  [n1,n2]=size(CSD);            
  CSD_add(1,:) = zeros(1,n2);   %add top and buttom row with zeros
  CSD_add(n1+2,:)=zeros(1,n2);
  CSD_add(2:n1+1,:)=CSD;        %CSD_add has n1+2 rows
  CSD = S_general(n1+2,b0,b1)*CSD_add; % CSD has n1 rows
end;

% plot CSD
plot_CSD(CSD,el_pos,handles.dt,1,0) %length(el_pos) must equal rows of CSD! 


function electrode_pos_Callback(hObject, eventdata, handles)
% hObject    handle to electrode_pos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of electrode_pos as text
%        str2double(get(hObject,'String')) returns contents of electrode_pos as a double


% --- Executes during object creation, after setting all properties.
function electrode_pos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to electrode_pos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --------------------------------------------------------------------
function file_menu_Callback(hObject, eventdata, handles)
% hObject    handle to file_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function new_figure_Callback(hObject, eventdata, handles)
% hObject    handle to new_figure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% filter parameters:
b0 = str2num(get(handles.filter_b0,'String'));
b1 = str2num(get(handles.filter_b1,'String'));
% electrical parameters:
cond = str2num(get(handles.ex_cond,'String'));
cond_top = str2num(get(handles.top_cond,'String'));
% geometrical parameters:
diam = str2num(get(handles.diam,'String'))*1e-3; %diameter in [m]
el_pos = str2num(get(handles.electrode_pos,'String'))*1e-3;

% compute delta iCSD:
CSD = F_delta(el_pos,diam,cond,cond_top)^-1*handles.pot;

if b1~=0 %filter iCSD
  [n1,n2]=size(CSD);            
  CSD_add(1,:) = zeros(1,n2);   %add top and buttom row with zeros
  CSD_add(n1+2,:)=zeros(1,n2);
  CSD_add(2:n1+1,:)=CSD;        %CSD_add has n1+2 rows
  CSD = S_general(n1+2,b0,b1)*CSD_add; % CSD has n1 rows
end;

% plot CSD
figure()
plot_CSD(CSD,el_pos,handles.dt,1,0) %length(el_pos) must equal rows of CSD! 


