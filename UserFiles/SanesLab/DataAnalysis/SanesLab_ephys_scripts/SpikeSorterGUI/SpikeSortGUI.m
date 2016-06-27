function varargout = SpikeSortGUI(varargin)
% SPIKESORTGUI MATLAB code for SpikeSortGUI.fig
%      SPIKESORTGUI, by itself, creates a new SPIKESORTGUI or raises the existing
%      singleton*.
%
%      H = SPIKESORTGUI returns the handle to a new SPIKESORTGUI or the handle to
%      the existing singleton*.
%
%      SPIKESORTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SPIKESORTGUI.M with the given input arguments.
%
%      SPIKESORTGUI('Property','Value',...) creates a new SPIKESORTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SpikeSortGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SpikeSortGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SpikeSortGUI

% Last Modified by GUIDE v2.5 23-Apr-2016 15:39:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SpikeSortGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @SpikeSortGUI_OutputFcn, ...
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


% --- Executes just before SpikeSortGUI is made visible.
function SpikeSortGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SpikeSortGUI (see VARARGIN)

% Choose default command line output for SpikeSortGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SpikeSortGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

set(hObject,'handlevisibility','off');    %-- Prevent main gui from getting erased accidentally --%
movegui(hObject,'northeast')
drawnow

% --- Outputs from this function are returned to the command line.
function varargout = SpikeSortGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function edit_pathname_Callback(hObject, eventdata, handles)
% hObject    handle to edit_pathname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_pathname as text
%        str2double(get(hObject,'String')) returns contents of edit_pathname as a double


% --- Executes during object creation, after setting all properties.
function edit_pathname_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_pathname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popup_filename.
function popup_filename_Callback(hObject, eventdata, handles)
% hObject    handle to popup_filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_filename contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_filename


% --- Executes during object creation, after setting all properties.
function popup_filename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function edit_elec_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_refwin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_elec_Callback(hObject, eventdata, handles)
% hObject    handle to edit_anawin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_anawin as text
%        str2double(get(hObject,'String')) returns contents of edit_anawin as a double

set(hObject,'Enable','off')
drawnow

D		=	get(handles.popup_filename,'UserData');
if( ~isempty(D) )
	StartSpikeSorting('Sort',handles);
end

set(hObject,'Enable','on')
drawnow

% --- Executes during object creation, after setting all properties.
function edit_anawin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_anawin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_maxwin_Callback(hObject, eventdata, handles)
% hObject    handle to edit_maxwin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_maxwin as text
%        str2double(get(hObject,'String')) returns contents of edit_maxwin as a double


% --- Executes during object creation, after setting all properties.
function edit_maxwin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_maxwin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in startbutton.
function startbutton_Callback(hObject, eventdata, handles)
% hObject    handle to startbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

StartSpikeSorting('Start',handles)

% --- Executes on key press with focus on startbutton and none of its controls.
function startbutton_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to startbutton (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

StartSpikeSorting('Start',handles)

% --- Executes on button press in previousbutton.
function previousbutton_Callback(hObject, eventdata, handles)
% hObject    handle to previousbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%-- First save the old data before continuing --%


%-- Now, continue on --%
Celec		=	str2double( get(handles.edit_elec,'String') );
Celec		=	Celec - 1;
if( Celec >= 1 )
	set(handles.edit_elec,'String',num2str(Celec));
	drawnow
	
	StartSpikeSorting('Start',handles);
else
	set(handles.edit_elec,'String','1');
	drawnow
	
	disp('Clipped to electrode 1.')
end

% --- Executes on key press with focus on previousbutton and none of its controls.
function previousbutton_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to previousbutton (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

Celec		=	str2double( get(handles.edit_elec,'String') );
Celec		=	Celec - 1;

if( Celec >= 1 )
	set(handles.edit_elec,'String',num2str(Celec));
	drawnow
	
	StartSpikeSorting('Start',handles);
else
	set(handles.edit_elec,'String','1');
	drawnow
	
	disp('Clipped to electrode 1.')
end


% --- Executes on button press in nextbutton.
function nextbutton_Callback(hObject, eventdata, handles)
% hObject    handle to nextbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%-- First save the old data before continuing --%
%---WILL HAVE TO CALL THIS NEXT FUNCTION MANUALLY---%
channel		=	str2double(get(handles.edit_elec,'String'));
Pname		=	get(handles.edit_pathname,'String');
Files		=	get(handles.popup_filename,'String');
FileIdx		=	get(handles.popup_filename,'Value');
File		=	Files(FileIdx);
subject		=	get(handles.SubjectID,'String');
session		=	get(handles.session,'String');
DataFile	=	[Pname subject '/' File{1} '.mat'];
load(DataFile)

%---Load spikes file---%
spikesfile	=	[Pname subject '/spikes.mat'];
load(spikesfile)
Spikes		=	pp_save_manual_sort(Pname,subject,session,Spikes,channel,spikes );

%-- Now, continue on --%
Celec		=	str2double( get(handles.edit_elec,'String') );
Celec		=	Celec + 1;
Nelec		=	nanmax(Spikes.channel);		%-- Number of ADC channels is stored in user data --%

if( Celec <= Nelec )
	set(handles.edit_elec,'String',num2str(Celec));
	drawnow
	
	StartSpikeSorting('Start',handles);
else
	set(handles.edit_elec,'String',num2str(Nelec));
	drawnow
	
	disp([num2str(Nelec) ' is the maximal number of channels.'])
end

% --- Executes on key press with focus on nextbutton and none of its controls.
function nextbutton_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to nextbutton (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

Celec		=	str2double( get(handles.edit_elec,'String') );
Celec		=	Celec + 1;
Nelec		=	get(handles.edit_elec,'UserData');		%-- Number of ADC channels is stored in user data --%

if( Celec <= Nelec )
	set(handles.edit_elec,'String',num2str(Celec));
	drawnow
	
	StartSpikeSorting('Sort',handles);
else
	set(handles.edit_elec,'String',num2str(Nelec));
	drawnow
	
	disp([num2str(Nelec) ' is the maximal number of channels.'])
end



function SubjectID_Callback(hObject, eventdata, handles)
% hObject    handle to SubjectID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SubjectID as text
%        str2double(get(hObject,'String')) returns contents of SubjectID as a double


% --- Executes during object creation, after setting all properties.
function SubjectID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SubjectID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function session_Callback(hObject, eventdata, handles)
% hObject    handle to session (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of session as text
%        str2double(get(hObject,'String')) returns contents of session as a double


% --- Executes during object creation, after setting all properties.
function session_CreateFcn(hObject, eventdata, handles)
% hObject    handle to session (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles)
% hObject    handle to Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
