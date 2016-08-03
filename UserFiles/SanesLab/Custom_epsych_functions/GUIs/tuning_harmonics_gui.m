function varargout = tuning_harmonics_gui(varargin)
% BASIC_CHARACTERIZATION MATLAB code for basic_characterization.fig
%      BASIC_CHARACTERIZATION, by itself, creates a new BASIC_CHARACTERIZATION or raises the existing
%      singleton*.
%
%      H = BASIC_CHARACTERIZATION returns the handle to a new BASIC_CHARACTERIZATION or the handle to
%      the existing singleton*.
%
%      BASIC_CHARACTERIZATION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BASIC_CHARACTERIZATION.M with the given input arguments.
%
%      BASIC_CHARACTERIZATION('Property','Value',...) creates a new BASIC_CHARACTERIZATION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before basic_characterization_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to basic_characterization_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help basic_characterization

% Last Modified by GUIDE v2.5 23-Feb-2016 15:41:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @freq_tuning_OpeningFcn, ...
                   'gui_OutputFcn',  @freq_tuning_OutputFcn, ...
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


%OPENING FUNCTION
function freq_tuning_OpeningFcn(hObject, eventdata, handles, varargin)
global G_DA G_COMPILED TONE_CAL


handles.output = hObject;


%--------------------------------------------
%Send initial weight matrix to parameter_tag

%Create initial, non-biased weights
v = ones(1,16);
WeightMatrix = diag(v);

%Reshape matrix into single row for RPVds compatibility
WeightMatrix =  reshape(WeightMatrix',[],1);
WeightMatrix = WeightMatrix';



%Prompt user to identify bad channels
numchannels = 16; %Hard coded for a 16 channel array

channelList = {'1','2','3','4','5','6','7','8',...
    '9','10','11','12','13','14','15','16'};

header = 'Select bad channels. Hold Ctrl to select multiple channels.';

bad_channels = listdlg('ListString',channelList,'InitialValue',8,...
    'Name','Channels','PromptString',header,...
    'SelectionMode','multiple','ListSize',[300,300])


if ~isempty(bad_channels)
    %Calculate weight for non-identical pairs
    weight = -1/(numchannels - numel(bad_channels) - 1);
    
    %Initialize weight matrix
    WeightMatrix = repmat(weight,numchannels,numchannels);
    
    %The weights of all bad channels are 0.
    WeightMatrix(:,bad_channels) = 0;
    
    %Do not perform averaging on bad channels: leave as is.
    WeightMatrix(bad_channels,:) = 0;
    
    %For each channel
    for i = 1:numchannels
        
        %Its own weight is 1
        WeightMatrix(i,i) = 1;
        
    end
    
    %Reshape matrix into single row for RPVds compatibility
    WeightMatrix =  reshape(WeightMatrix',[],1);
    WeightMatrix = WeightMatrix';
end


G_DA.WriteTargetVEX('Phys.WeightMatrix',0,'F32',WeightMatrix);

%--------------------------------------------



%--------------------------------------------
%INITIALIZE GUI TEXT
%--------------------------------------------

%Initialize gui display: Inter-stim interval
StimDur = G_DA.GetTargetVal('Behavior.StimDur'); %why is this 100 by default?
ISI = 300 + 1000; 
G_COMPILED.OPTIONS.ISI = ISI;
set(handles.ISI_slider,'Value',ISI);
set(handles.ISI_text,'String',[num2str(ISI), ' (msec)']);
    %%% ISI resets to 1000 at start?

%--------------------------------------------
%Initialize gui display: Harmonics
% % % G_COMPILED.trials(1,strcmp(G_COMPILED.writeparams,'Behavior.weight_F1'))
% % % 
% % % f1_prot = G_DA.GetTargetVal('Behavior.StimDur');
% % % 
set(handles.f1,'enable','off');
set(handles.f2,'enable','off');
set(handles.f3,'enable','off');
set(handles.f4,'enable','off');
set(handles.rel_loudness_f1,'enable','off');
set(handles.rel_loudness_f2,'enable','off');
set(handles.rel_loudness_f3,'enable','off');
set(handles.rel_loudness_f4,'enable','off');
% % % 
% % % set(handles.rel_loudness_f1,'Value',0);


%%%% Haven't yet thought of a way to calibrate the levels of harmonics
%%%% independently; specific issue: how to set FreqX.amp and FreqX.norm
%%%% values when FX changes on every trial. for now, can use just one
%%%% value for F0 per recording, and just set the calibration parameters
%%%% based on this at the beginning. 

%Get F0
F0 = G_COMPILED.trials(1,strcmp(G_COMPILED.writeparams,'Behavior.Freq'));
F0 = F0{1};

%Set calibration values for each harmonic 
%(doesn't matter what weight is)
for ih = 0:4
    %Create strings for parameter tags
    Tag_calAmp = sprintf('Behavior.Freq%i_amp',ih);
    Tag_calNorm = sprintf('Behavior.Freq%i_norm',ih);
    
    %Apply the voltage adjustment for level calibration in RPVds circuit
    CalAmp = Calibrate(F0*(ih+1),TONE_CAL);
    G_DA.SetTargetVal(Tag_calAmp,CalAmp);
    G_DA.SetTargetVal(Tag_calNorm,TONE_CAL.hdr.cfg.ref.norm); %read norm value from cal file
    
    G_DA.GetTargetVal(Tag_calAmp)
    G_DA.GetTargetVal(Tag_calNorm)
    
    %%%% set frequency limits?
end
%--------------------------------------------



%Update handles structure
guidata(hObject, handles);




function varargout = freq_tuning_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.output;





%---------------------------------------------------------------
%PHYSIOLOGY
%---------------------------------------------------------------
%REFERENCE PHYS
function refphys_Callback(hObject, eventdata, handles)
%The method we're using here to reference channels is the following:
%First, bad channels are removed.
%Second a single channel is selected and held aside.
%Third, all of the remaining (good, non-selected) channels are averaged.
%Fourth, this average is subtracted from the selected channel.
%This process is repeated for each good channel.
%
%The way this method is implemented in the RPVds circuit is as follows:  
%
%From Brad Buran:
%
% This is implemented using matrix multiplication in the format D x C =
% R. C is a single time-slice of data in the shape [16 x 1]. In other
% words, it is the value from all 16 channels sampled at a single point
% in time. D is a 16 x 16 matrix. R is the referenced output in the
% shape [16 x 1]. Each row in the matrix defines the weights of the
% individual channels. So, if you were averaging together channels 2-16
% and subtracting the mean from the first channel, the first row would
% contain the weights:
% 
% [1 -1/15 -1/15 ... -1/15]
% 
% If you were averaging together channels 2-8 and subtracting the mean
% from the first channel:
% 
% [1 -1/7 -1/7 ... -1/7 0 0 0 ... 0]
% 
% If you were averaging together channels 3-8 (because channel 2 was
% bad) and subtracting the mean from the first channel:
% 
% [1 0 -1/6 ... -1/6 0 0 0 ... 0]
% 
% To average channels 1-4 and subtract the mean from the first channel:
% 
% [3/4 -1/4 -1/4 -1/4 0 ... 0]
% 
% To repeat the same process (average channels 1-4 and subtract the
% mean) for the second channel, the second row in the matrix would be:
% 
% [-1/4 3/4 -1/4 -1/4 0 ... 0]


global G_DA

%Hard coded for a 16 channel array
numchannels = 16;

%Prompt user to identify bad channels
channelList = {'1','2','3','4','5','6','7','8',...
    '9','10','11','12','13','14','15','16'};

header = 'Select bad channels. Hold Ctrl to select multiple channels.';

bad_channels = listdlg('ListString',channelList,'InitialValue',8,...
    'Name','Channels','PromptString',header,...
    'SelectionMode','multiple','ListSize',[300,300])


if ~isempty(bad_channels)
    %Calculate weight for non-identical pairs
    weight = -1/(numchannels - numel(bad_channels) - 1);
    
    %Initialize weight matrix
    WeightMatrix = repmat(weight,numchannels,numchannels);
    
    %The weights of all bad channels are 0.
    WeightMatrix(:,bad_channels) = 0;
    
    %Do not perform averaging on bad channels: leave as is.
    WeightMatrix(bad_channels,:) = 0;
    
    %For each channel
    for i = 1:numchannels
        
        %Its own weight is 1
        WeightMatrix(i,i) = 1;
        
    end
    
    %Reshape matrix into single row for RPVds compatibility
    WeightMatrix =  reshape(WeightMatrix',[],1);
    WeightMatrix = WeightMatrix';
    
    
    %Send to RPVds
    G_DA.WriteTargetVEX('Phys.WeightMatrix',0,'F32',WeightMatrix);
end

guidata(hObject,handles);




%---------------------------------------------------------------
%SOUND CONTROLS
%---------------------------------------------------------------

%ISI SLIDER
function ISI_slider_Callback(hObject, eventdata, handles)
global G_COMPILED

ISI = get(hObject,'Value');
set(handles.ISI_text,'String',[num2str(ISI), ' (msec)']);

G_COMPILED.OPTIONS.ISI = ISI;


guidata(hObject,handles);





% --- Executes on button press in f1.
function f1_Callback(hObject, eventdata, handles)
global G_COMPILED

% hObject    handle to f1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of f1
guidata(hObject,handles);


% --- Executes on button press in f2.
function f2_Callback(hObject, eventdata, handles)
global G_COMPILED

% hObject    handle to f2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of f2
guidata(hObject,handles);


% --- Executes on button press in f3.
function f3_Callback(hObject, eventdata, handles)
global G_COMPILED

% hObject    handle to f3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of f3
guidata(hObject,handles);


% --- Executes on button press in f4.
function f4_Callback(hObject, eventdata, handles)
% hObject    handle to f4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of f4
guidata(hObject,handles);






function rel_loudness_f1_Callback(hObject, eventdata, handles)
global G_COMPILED

% hObject    handle to rel_loudness_f1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rel_loudness_f1 as text
%        str2double(get(hObject,'String')) returns contents of rel_loudness_f1 as a double
guidata(hObject,handles);


function rel_loudness_f2_Callback(hObject, eventdata, handles)
global G_COMPILED

% hObject    handle to rel_loudness_f2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rel_loudness_f2 as text
%        str2double(get(hObject,'String')) returns contents of rel_loudness_f2 as a double
guidata(hObject,handles);


function rel_loudness_f3_Callback(hObject, eventdata, handles)
global G_COMPILED

% hObject    handle to rel_loudness_f3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rel_loudness_f3 as text
%        str2double(get(hObject,'String')) returns contents of rel_loudness_f3 as a double
guidata(hObject,handles);


% --- Executes on selection change in rel_loudness_f4.
function rel_loudness_f4_Callback(hObject, eventdata, handles)
% hObject    handle to rel_loudness_f4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns rel_loudness_f4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from rel_loudness_f4
guidata(hObject,handles);










%---------------------------------------------------------------
%FIGURE WINDOW CONTROLS
%---------------------------------------------------------------
function figure1_CloseRequestFcn(hObject, eventdata, handles)

%Close the figure
delete(hObject);
