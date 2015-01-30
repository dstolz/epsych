function varargout = CSDplotter(varargin)
% CSDPLOTTER M-file for CSDplotter.fig
%      CSDPLOTTER, by itself, creates a new CSDPLOTTER or raises the existing
%      singleton*.
%
%      H = CSDPLOTTER returns the handle to a new CSDPLOTTER or the handle to
%      the existing singleton*.
%
%      CSDPLOTTER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CSDPLOTTER.M with the given input arguments.
%
%      CSDPLOTTER('Property','Value',...) creates a new CSDPLOTTER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CSDplotter_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CSDplotter_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CSDplotter

% Last Modified by GUIDE v2.5 23-Nov-2005 21:45:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CSDplotter_OpeningFcn, ...
                   'gui_OutputFcn',  @CSDplotter_OutputFcn, ...
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


% --- Executes just before CSDplotter is made visible.
function CSDplotter_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CSDplotter (see VARARGIN)

% Set path:
[pathstr, name, ext] = fileparts(mfilename('fullpath')); % parts of current directory
addpath(pathstr); % current directory
addpath([pathstr filesep 'methods']); % methods directory
addpath([pathstr filesep 'methods' filesep 'saved']); % saved transformations directory

% show artistic iCSD picture :-)
image(imread('CSDplotter_logo.jpg'))
axis off;
set(hObject,'Color','white');

% Initialize: no methods chosen by default
handles.run_standard=0;
handles.run_delta=0;
handles.run_step=0;
handles.run_spline=0;

% Choose default command line output for CSDplotter
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

setappdata(hObject, 'StartPath', pwd);
addpath(pwd);
%load_listbox(handles)
load_listbox(pwd,handles)

% UIWAIT makes CSDplotter wait for user response (see UIRESUME)
%uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = CSDplotter_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;




% --- Executes on button press in standardCSD.
function standardCSD_Callback(hObject, eventdata, handles)
% hObject    handle to standardCSD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of standardCSD
% handles.run_standard=get(hObject,'Value');
% guidata(hObject,handles)

% --- Executes on button press in deltaiCSD.
function deltaiCSD_Callback(hObject, eventdata, handles)
% hObject    handle to deltaiCSD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of deltaiCSD

% --- Executes on button press in stepiCSD.
function stepiCSD_Callback(hObject, eventdata, handles)
% hObject    handle to stepiCSD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of stepiCSD

% --- Executes on button press in splineiCSD.
function splineiCSD_Callback(hObject, eventdata, handles)
% hObject    handle to splineiCSD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of splineiCSD

% --- Executes on selection change in popupmenu3.
function popupmenu3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu3


% --- Executes during object creation, after setting all properties.
function popupmenu3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in OK.
function OK_Callback(hObject, eventdata, handles)
% hObject    handle to OK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get filename
try
  filenames = get(handles.browse_files,'String');
  my_choice_file = get(handles.browse_files,'Value');
  my_file = filenames{my_choice_file};
catch
  errordlg('Cannot fetch file.')
  return
end;

% open file
try
  load(my_file)
catch
   if isdir(my_file)
       errordlg('A mat-file has to be chosen (not a folder).')
   else
     errordlg('Cannot open file.')
   end;
   return
end;
% get matrix
try
  my_strings = get(handles.matrix_listbox,'String');
  my_choice = get(handles.matrix_listbox,'Value');
  my_string = my_strings{my_choice};
  % fetch matrix:
  pot = eval(my_string); % set pot values to those of my_string
catch
  errordlg('Cannot fetch matrix.')
  return
end;

guidata(hObject,handles)

uiresume;
%temp my_browse
%dt = 0.5;
dt = str2num(get(handles.dt,'String'));

if get(handles.standardCSD,'Value'); my_standardCSD('pot',pot,'dt',dt);end;
if get(handles.deltaiCSD,'Value');my_deltaCSD('pot',pot,'dt',dt);end;
if get(handles.stepiCSD,'Value');my_stepCSD('pot',pot,'dt',dt);end;
if get(handles.splineiCSD,'Value');my_splineCSD('pot',pot,'dt',dt);end;



%delete path created in opening function
if isappdata(hObject, 'StartPath')
    rmpath(getappdata(hObject, 'StartPath'));
end


function dt_Callback(hObject, eventdata, handles)
% hObject    handle to dt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dt as text
%        str2double(get(hObject,'String')) returns contents of dt as a double


% --- Executes during object creation, after setting all properties.
function dt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in my_browse.
%function my_browse_Callback(hObject, eventdata, handles)
%lbox2()
% hObject    handle to my_browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% % % --- Executes on selection change in browse_files.
% function browse_files_Callback(hObject, eventdata, handles)
% % % hObject    handle to browse_files (see GCBO)
% % % eventdata  reserved - to be defined in a future version of MATLAB
% % % handles    structure with handles and user data (see GUIDATA)
% % 
% % % Hints: contents = get(hObject,'String') returns browse_files contents as cell array
% % %        contents{get(hObject,'Value')} returns selected item from browse_files
% % 
% 
% % --- Executes during object creation, after setting all properties.

function browse_files_CreateFcn(hObject, eventdata, handles)
% hObject    handle to browse_files (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function varargout = browse_files_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1

get(handles.figure1,'SelectionType');

% The following reacts upon callback from user - changes folder if double
% click on folder, open file if it is a .mat file.
if strcmp(get(handles.figure1,'SelectionType'),'open')
	index_selected = get(handles.browse_files,'Value'); % selected string (nr)
	file_list = get(handles.browse_files,'String');	 % string of files
	filename = file_list{index_selected};   % desired file
	if  handles.is_dir(handles.sorted_index(index_selected))
		cd (filename);
		load_listbox(pwd,handles); %pwd is current directory
	else
	   [path,name,ext] = fileparts(filename);
        try
		  open(filename);
          matrixes=whos('-file',filename); % lists variables of filename
          guidata(hObject,handles); % neccessary?
          set(handles.matrix_listbox,'String',{matrixes.name},'Value',1); % sets the names in the matrix_listbox
        catch
          errordlg(lasterr,'File Type Error','modal');
        end;
   end
end


% ------------------------------------------------------------
% Read the current directory and sort the names
% ------------------------------------------------------------
function load_listbox(dir_path,handles)
%function load_listbox(dir_path,handles)
%makes handles for the folders and .mat files in folder dir_path
cd (dir_path)
dir_struct = dir(dir_path); % list files of dir_path folder
my_mat_files = {dir([dir_path filesep '*.mat'])}; %list .mat files
my_directories = [dir_struct.isdir]; %indexes of folders
%{dir_struct.name} %print out all files and folders
j=1; % counter
for i=1:length({dir_struct.name}) %all files and folders
  [pathstr, name, ext] = fileparts(dir_struct(i).name); %get filetype
  if strcmp(ext,'.mat') %filtype is .mat
      my_files{j} = dir_struct(i).name; %store it in my_files
      my_isdir(j) = 0;
      j=j+1;
  end;
  if my_directories(i) % folder
      my_files{j} = dir_struct(i).name; %store it in my_files
      my_isdir(j)=1;
      j=j+1;
  end;
end;
% my_files % print .mat files and folders
[sorted_names,sorted_index] = sortrows(my_files'); % sort alfabetically
handles.file_names = sorted_names;
handles.is_dir = my_isdir;
handles.sorted_index = [sorted_index];
%guidata(hObject,handles)
guidata(handles.figure1,handles)
set(handles.browse_files,'String',handles.file_names,...
	'Value',1);



% --- Executes on selection change in matrix_listbox.
function matrix_listbox_Callback(hObject, eventdata, handles)
% hObject    handle to matrix_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns matrix_listbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from matrix_listbox

matrix_selected = get(handles.matrix_listbox,'Value'); % string element selected (nr)
all_matrixes = get(handles.matrix_listbox,'String'); % string of matrixes
handles.my_matrix = all_matrixes{matrix_selected};  % desired matrix
%guidata(hObject,handles); % save the desired matrix
guidata(handles.figure1,handles); % save the desired matrix

% --- Executes during object creation, after setting all properties.
function matrix_listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to matrix_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


