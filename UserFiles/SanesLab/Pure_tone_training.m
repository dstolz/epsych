function varargout = Pure_tone_training(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Pure_tone_training_OpeningFcn, ...
                   'gui_OutputFcn',  @Pure_tone_training_OutputFcn, ...
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

%Executes just before GUI is made visible
function Pure_tone_training_OpeningFcn(hObject, eventdata, handles, varargin)

handles.output = hObject;

guidata(hObject, handles);

%Ouputs from this function are returned to the command line
function varargout = Pure_tone_training_OutputFcn(hObject, eventdata, handles) 

%Set up RPVds circuit
handles.RPfile = 'C:\gits\epsych\UserFiles\SanesLab\RPVdsCircuits\Appetitive_pure_tone_training.rcx';

% Get default command line output from handles structure
varargout{1} = handles.output;
guidata(hObject,handles);






%START BUTTON CALLBACK
function start_Callback(hObject, eventdata, handles)

%Open a figure for ActiveX control
handles.f1 = figure('Visible','off','Name','RPfig');

%Connect to the first module of the RZ6 ('GB' = optical gigabit connector)
handles.RP = actxcontrol('RPco.x','parent',handles.f1);

if handles.RP.ConnectRZ6('GB',1);
    disp 'Connected to RZ6'
else
    error('Error: Unable to connect to RZ6')
end

%Load the RPVds file (*.rco or *.rcx)
if handles.RP.LoadCOF(handles.RPfile);
    disp 'Circuit loaded successfully';
else
    error('Error: Unable to load RPVds circuit')
end

%Start the processing chain
if handles.RP.Run;
    disp 'Circuit is running'
else
    error('Error: circuit will not run')
end

%Set the circuit parameters to the values in the GUI
freq = str2double(get(handles.freq,'String'));
level = str2double(get(handles.dBSPL,'String'));
handles.RP.SetTagVal('Freq',freq);
handles.RP.SetTagVal('dBSPL',level);


%Initialize Pump
handles.pump = TrialFcn_PumpControl;
rate = str2num(get(handles.pumprate,'String'));
fprintf(handles.pump,'RAT%0.1f\n',rate) 


%Inactivate START button
set(handles.start,'BackgroundColor',[0.9 0.9 0.9])
set(handles.start,'ForegroundColor',[0.8 0.8 0.8])
set(handles.start,'Enable','off');

guidata(hObject,handles);


%STOP BUTTON CALLBACK
function stop_Callback(hObject, eventdata, handles)

%Stop the RPVds processing chain, and clear everything out
handles.RP.Halt;
handles.RP.ClearCOF;
release(handles.RP);

%Close the activeX controller window
close(handles.f1);

%Close out the pump
fclose(handles.pump); 
delete(handles.pump);

%Inactivate STOP AND APPLY buttons
set(handles.stop,'BackgroundColor',[0.9 0.9 0.9])
set(handles.stop,'ForegroundColor',[0.8 0.8 0.8])
set(handles.stop,'Enable','off');

set(handles.apply,'BackgroundColor',[0.9 0.9 0.9])
set(handles.apply,'ForegroundColor',[0.8 0.8 0.8])
set(handles.apply,'Enable','off');


%APPLY BUTTON CALLBACK
function apply_Callback(hObject, eventdata, handles)
flag = 0;

%Pull parameters from GUI
try
    freq = str2double(get(handles.freq,'String'));
    level = str2double(get(handles.dBSPL,'String'));
    rate = str2num(get(handles.pumprate,'String'));
catch
    beep
    warning('Invalid entry. Values must be numeric.')
    flag = 1;
end

%Check that parameters are reasonable
if freq < 100 || freq > 50000
    beep
    warning('Frequency value must be between 100 and 50,000')
    flag = 1;
end

if level > 130
    beep
    warning('dB SPL value out of range')
    flag = 1;
end



%Send frequency and sound level parameters back to RPVds circuit
if flag == 0

    handles.RP.SetTagVal('Freq',freq);
    handles.RP.SetTagVal('dBSPL',level);
    
end

%Send updated flowrate to pump
fprintf(handles.pump,'RAT%0.1f\n',rate)  



guidata(hObject,handles);
