function varargout = my_splineCSD(varargin)
% MY_SPLINECSD M-file for my_splineCSD.fig
%      MY_SPLINECSD, by itself, creates a new MY_SPLINECSD or raises the existing
%      singleton*.
%
%      H = MY_SPLINECSD returns the handle to a new MY_SPLINECSD or the
%      handle to
%      the existing singleton*.
%
%      MY_SPLINECSD('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MY_SPLINECSD.M with the given input arguments.
%
%      MY_SPLINECSD('Property','Value',...) creates a new MY_SPLINECSD or raises the
%      existing singleton*.  Starting from the left, property value pairs
%      are
%      applied to the GUI before my_splineCSD_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to my_splineCSD_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help my_splineCSD

% Last Modified by GUIDE v2.5 13-Dec-2005 12:42:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @my_splineCSD_OpeningFcn, ...
                   'gui_OutputFcn',  @my_splineCSD_OutputFcn, ...
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


% --- Executes just before my_splineCSD is made visible.
function my_splineCSD_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to my_splineCSD (see VARARGIN)
handles.pot = varargin{2};
handles.dt = varargin{4};

%image(imread('CSDplotter_logo.1.jpg'))
axis off;

% Choose default command line output for my_splineCSD
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes my_splineCSD wait for user response (see UIRESUME)
% uiwait(handles.delta_CSD);


% --- Outputs from this function are returned to the command line.
function varargout = my_splineCSD_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function gsigma_Callback(hObject, eventdata, handles)
% hObject    handle to gsigma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gsigma as text
%        str2double(get(hObject,'String')) returns contents of gsigma as a double


% --- Executes during object creation, after setting all properties.
function gsigma_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gsigma (see GCBO)
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
gauss_sigma = str2num(get(handles.gsigma,'String'))*1e-3; % mm -> m
filter_range = 5*gauss_sigma; % numeric filter must be finite in extent
if gauss_sigma<0
    errordlg('The gaussian filter width cannot be negative.')
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

% compute spline iCSD:
Fcs = F_cubic_spline(el_pos,diam,cond,cond_top);
[zs,CSD_cs] = make_cubic_splines(el_pos,handles.pot,Fcs);
%[pos1,my_CSD_spline]=new_CSD_range(zs,CSD_cs,0,2.4e-3);
if gauss_sigma~=0 %filter iCSD
  [zs,CSD_cs]=gaussian_filtering(zs,CSD_cs,gauss_sigma,filter_range);
%  [new_positions,gfiltered_spline_CSD]=gaussian_filtering(zs,CSD_cs,gauss_sigma,filter_range);
end;
 
% %   plot_CSD_with_axes(new_positions,delta_t,gfiltered_spline_CSD,1)
%   [gpot_pos,gfiltered_spline_CSD_short]=new_CSD_range(new_positions,gfiltered_spline_CSD,zstart_plot,zstop_plot);

% plot CSD
plot_CSD(CSD_cs,zs,handles.dt,1,0) %length(el_pos) must equal rows of CSD! 

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
function new_figure_Callback(hObject, eventdata, handles)
% hObject    handle to new_figure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% filter parameters:
gauss_sigma = str2num(get(handles.gsigma,'String'))*1e-3; % mm -> m
filter_range = 5*gauss_sigma; % numeric filter must be finite in extent

% electrical parameters:
cond = str2num(get(handles.ex_cond,'String'));
cond_top = str2num(get(handles.top_cond,'String'));
% geometrical parameters:
diam = str2num(get(handles.diam,'String'))*1e-3; %diameter in [m]
el_pos = str2num(get(handles.electrode_pos,'String'))*1e-3;

% compute step iCSD:
Fcs = F_cubic_spline(el_pos,diam,cond,cond_top);
[zs,CSD_cs] = make_cubic_splines(el_pos,handles.pot,Fcs);
%[pos1,my_CSD_spline]=new_CSD_range(zs,CSD_cs,0,2.4e-3);
if gauss_sigma~=0 %filter iCSD
  [zs,CSD_cs]=gaussian_filtering(zs,CSD_cs,gauss_sigma,filter_range);
%  [new_positions,gfiltered_spline_CSD]=gaussian_filtering(zs,CSD_cs,gauss_sigma,filter_range);
end;
 
% %   plot_CSD_with_axes(new_positions,delta_t,gfiltered_spline_CSD,1)
%   [gpot_pos,gfiltered_spline_CSD_short]=new_CSD_range(new_positions,gfiltered_spline_CSD,zstart_plot,zstop_plot);

% plot CSD
figure()
plot_CSD(CSD_cs,zs,handles.dt,1,0) %length(el_pos) must equal rows of CSD! 


% --------------------------------------------------------------------
function file_menu_Callback(hObject, eventdata, handles)
% hObject    handle to file_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


