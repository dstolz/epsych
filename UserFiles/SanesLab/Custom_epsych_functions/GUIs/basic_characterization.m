function varargout = basic_characterization(varargin)
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

% Last Modified by GUIDE v2.5 25-Aug-2016 15:02:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @basic_characterization_OpeningFcn, ...
                   'gui_OutputFcn',  @basic_characterization_OutputFcn, ...
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
function basic_characterization_OpeningFcn(hObject, ~, handles, varargin)
global G_DA G_COMPILED RUNTIME


handles.output = hObject;

%Store device info
RUNTIME.TDT = TDT_GetDeviceInfo(G_DA);
RUNTIME.UseOpenEx = 1;
handles = findModuleIndex_SanesLab('RZ6',handles);

%Initialize physiology
[handles,G_DA] = initializePhysiology_SanesLab(handles,G_DA);



%--------------------------------------------
%INITIALIZE GUI TEXT
%--------------------------------------------
%Initialize selected stim mode: Tone
set(handles.stim_button_panel,'selectedobject',handles.tone);
set(handles.bandwidth_slider_text,'ForegroundColor',[0.5 0.5 0.5]);
set(handles.bandwidth_slider,'enable','off');
set(handles.bandwidth_text,'visible','off');
set(handles.noise,'ForegroundColor','k')
set(handles.noise,'FontWeight','normal')
set(handles.tone,'ForegroundColor','r')
set(handles.tone,'FontWeight','bold')
G_DA.SetTargetVal([handles.module,'.selector'],0);


%Initialize selected modulation mode: No modulation
set(handles.mod_button_panel,'selectedobject',handles.no_modulation);
set(handles.AM_depth_slider,'enable','off');
set(handles.AM_rate_slider,'enable','off');
set(handles.AMdepth_text,'visible','off');
set(handles.AMrate_text,'visible','off');
set(handles.AM_panel,'ForegroundColor',[0.5 0.5 0.5]);
set(handles.AM_depth_slider_text,'ForegroundColor',[0.5 0.5 0.5]);
set(handles.AM_rate_slider_text,'ForegroundColor',[0.5 0.5 0.5]);
set(handles.AMdepth_text,'visible','off');
set(handles.AMrate_text,'visible','off');
set(handles.FM_depth_slider,'enable','off');
set(handles.FM_rate_slider,'enable','off');
set(handles.FMdepth_text,'visible','off');
set(handles.FMrate_text,'visible','off');
set(handles.no_modulation,'ForegroundColor','r');
set(handles.no_modulation,'FontWeight','bold');
set(handles.AM_modulation,'ForegroundColor','k');
set(handles.AM_modulation,'FontWeight','normal');
set(handles.freq_modulation,'ForegroundColor','k');
set(handles.freq_modulation,'FontWeight','normal');

G_DA.SetTargetVal([handles.module,'.mod_depth'],0);
G_DA.SetTargetVal([handles.module,'.mod_rate'],0);
G_DA.SetTargetVal([handles.module,'.FMdepth'],0);
G_DA.SetTargetVal([handles.module,'.FMrate'],0);

%Initialize gui display: center frequency
center_freq = get(handles.center_freq_slider,'Value');
set(handles.center_freq,'String',[num2str(center_freq), ' (Hz)']);

%Initialize gui display: dB SPL
dBSPL = get(handles.dBSPL_slider,'Value');
set(handles.dBSPL_text,'String',[num2str(dBSPL), ' (dB SPL)']);

%Initialize calibrated sound level
update_sound_level(0,dBSPL,handles);

%Initialize gui display: Bandwidth
bandwidth = get(handles.bandwidth_slider,'Value');
set(handles.bandwidth_text,'String',num2str(bandwidth));

%Initialize gui display: Sound duration
duration = G_DA.GetTargetVal([handles.module,'.StimDur']);
set(handles.duration_slider,'Value',duration);
set(handles.duration_text,'String',[num2str(duration), ' (msec)']);

%Initialize gui display: Inter-stim interval
ISI = G_COMPILED.OPTIONS.ISI;
set(handles.ISI_slider,'Value',ISI);
set(handles.ISI_text,'String',[num2str(ISI), ' (msec)']);

%Initialize gui display: AM depth
AMdepth = get(handles.AM_depth_slider,'Value');
set(handles.AMdepth_text,'String',[num2str(AMdepth*100), ' %']);

%Initialize gui display: AM rate
AMrate = get(handles.AM_rate_slider,'Value');
set(handles.AMrate_text,'String',[num2str(AMrate), ' (Hz)']);

%Initialize gui display: FM depth
FMdepth = get(handles.FM_depth_slider,'Value');
set(handles.FMdepth_text,'String',[num2str(FMdepth), ' %']);

%Initialize gui display: FM rate
FMrate = get(handles.FM_rate_slider,'Value');
set(handles.FMrate_text,'String',[num2str(FMrate), ' (Hz)']);

%Initialize selected optotgenetic mode: off
set(handles.opto_button_panel,'selectedobject',handles.opto_off);
G_DA.SetTargetVal([handles.module,'.Optostim'],0);


%Update handles structure
guidata(hObject, handles);


function varargout = basic_characterization_OutputFcn(~, ~, handles) 

varargout{1} = handles.output;





%---------------------------------------------------------------
%PHYSIOLOGY
%---------------------------------------------------------------
%REFERENCE PHYS
function ReferencePhys_Callback(~, ~, handles) %#ok<*DEFNU>

global G_DA

G_DA = ReferencePhys_SanesLab(handles,G_DA);


%OPTOGENETIC TRIGGER
function opto_button_panel_SelectionChangeFcn(hObject, eventdata, handles)
global G_DA

switch get(eventdata.NewValue,'String')
    case 'On'
        %Turn on optogenetic trigger
        G_DA.SetTargetVal([handles.module,'.Optostim'],1);
        
    case 'Off'
        %Turn off optogenetic trigger
        G_DA.SetTargetVal([handles.module,'.Optostim'],0);
    
end
guidata(hObject,handles)



%---------------------------------------------------------------
%SOUND CONTROLS
%---------------------------------------------------------------
%STIMULUS MODE
function stim_button_panel_SelectionChangeFcn(hObject, eventdata, handles)
global G_DA

switch get(eventdata.NewValue,'String')
    case 'Tone'
        
        %Disable bandwidth option
        set(handles.bandwidth_slider,'enable','off');
        set(handles.bandwidth_text,'visible','off');
        set(handles.bandwidth_slider_text,'ForegroundColor',[0.5 0.5 0.5]);
        
        %Enable FM option
        set(handles.freq_modulation,'enable','on');
        set(handles.freq_modulation,'ForegroundColor','k');
        
        %Highlight selected choice
        set(handles.noise,'ForegroundColor','k')
        set(handles.noise,'FontWeight','normal')
        set(handles.tone,'ForegroundColor','r')
        set(handles.tone,'FontWeight','bold')
        
        %Tell the RPVds circuit that we want a tone
        G_DA.SetTargetVal([handles.module,'.selector'],0);
        
    case 'Noise'
        %Turn off FM
        G_DA.SetTargetVal([handles.module,'.FMdepth'],0);
        G_DA.SetTargetVal([handles.module,'.FMrate'],0);
        
        %Enable bandwidth option
        set(handles.bandwidth_slider,'enable','on');
        set(handles.bandwidth_text,'visible','on');
        set(handles.bandwidth_slider_text,'ForegroundColor','k');
        
        %If FM option was highlighted, defualt to no modulation
        switch get(handles.mod_button_panel,'selectedobject')
            case handles.freq_modulation
            set(handles.mod_button_panel,'selectedobject',handles.no_modulation);
        end
        
        %Disable FM option
        set(handles.freq_modulation,'enable','off');
        set(handles.freq_modulation,'ForegroundColor',[0.5 0.5 0.5]);
        set(handles.freq_modulation,'FontWeight','normal');
        set(handles.FM_depth_slider,'enable','off')
        set(handles.FM_rate_slider,'enable','off')
        set(handles.FMdepth_text,'visible','off')
        set(handles.FMrate_text,'visible','off')
        set(handles.FM_panel,'ForegroundColor',[0.5 0.5 0.5]);
        set(handles.FM_depth_slider_text,'ForegroundColor',[0.5 0.5 0.5]);
        set(handles.FM_rate_slider_text,'ForegroundColor',[0.5 0.5 0.5]);
        
        %Highlight selected choice
        set(handles.noise,'ForegroundColor','r')
        set(handles.noise,'FontWeight','bold')
        set(handles.tone,'ForegroundColor','k')
        set(handles.tone,'FontWeight','normal')
        
        %Tell the RPVds circuit we want noise
        G_DA.SetTargetVal([handles.module,'.selector'],1);
        
        %Apply bandwidth filter
        center_freq = G_DA.GetTargetVal([handles.module,'.center_freq']);
        bandwidth = get(handles.bandwidth_slider,'Value');
        updatebandwidth(center_freq,bandwidth,handles);
        
        
end
guidata(hObject,handles)

%MODULATION MODE
function mod_button_panel_SelectionChangeFcn(hObject, eventdata, handles)
global G_DA

switch get(eventdata.NewValue,'String')
    
    case 'No Modulation'
        set(handles.AM_depth_slider,'enable','off')
        set(handles.AM_rate_slider,'enable','off')
        set(handles.FM_depth_slider,'enable','off')
        set(handles.FM_rate_slider,'enable','off')
        
        set(handles.AMdepth_text,'visible','off')
        set(handles.AMrate_text,'visible','off')
        set(handles.FMdepth_text,'visible','off')
        set(handles.FMrate_text,'visible','off')
        
        set(handles.AM_panel,'ForegroundColor',[0.5 0.5 0.5]);
        set(handles.AM_depth_slider_text,'ForegroundColor',[0.5 0.5 0.5]);
        set(handles.AM_rate_slider_text,'ForegroundColor',[0.5 0.5 0.5]);

        set(handles.FM_panel,'ForegroundColor',[0.5 0.5 0.5]);
        set(handles.FM_depth_slider_text,'ForegroundColor',[0.5 0.5 0.5]);
        set(handles.FM_rate_slider_text,'ForegroundColor',[0.5 0.5 0.5]);
        
        set(handles.no_modulation,'ForegroundColor','r');
        set(handles.no_modulation,'FontWeight','bold');
        set(handles.AM_modulation,'ForegroundColor','k');
        set(handles.AM_modulation,'FontWeight','normal');
        set(handles.freq_modulation,'ForegroundColor','k');
        set(handles.freq_modulation,'FontWeight','normal');
        
        %Turn off AM
        G_DA.SetTargetVal([handles.module,'.mod_depth'],0);
        G_DA.SetTargetVal([handles.module,'.mod_rate'],0);
        
        %Turn off FM
        G_DA.SetTargetVal([handles.module,'.FMdepth'],0);
        G_DA.SetTargetVal([handles.module,'.FMrate'],0);
        
    case 'Amplitude Modulation'
        set(handles.AM_depth_slider,'enable','on')
        set(handles.AM_rate_slider,'enable','on')
        set(handles.FM_depth_slider,'enable','off')
        set(handles.FM_rate_slider,'enable','off')
        
        set(handles.AMdepth_text,'visible','on')
        set(handles.AMrate_text,'visible','on')
        set(handles.FMdepth_text,'visible','off')
        set(handles.FMrate_text,'visible','off')
        
        set(handles.AM_panel,'ForegroundColor','k');
        set(handles.AM_depth_slider_text,'ForegroundColor','k');
        set(handles.AM_rate_slider_text,'ForegroundColor','k');

        set(handles.FM_panel,'ForegroundColor',[0.5 0.5 0.5]);
        set(handles.FM_depth_slider_text,'ForegroundColor',[0.5 0.5 0.5]);
        set(handles.FM_rate_slider_text,'ForegroundColor',[0.5 0.5 0.5]);
        
        set(handles.no_modulation,'ForegroundColor','k');
        set(handles.no_modulation,'FontWeight','normal');
        set(handles.AM_modulation,'ForegroundColor','r');
        set(handles.AM_modulation,'FontWeight','bold');
        set(handles.freq_modulation,'ForegroundColor',[0.5 0.5 0.5]);
        set(handles.freq_modulation,'FontWeight','normal');

        %Turn off FM
        G_DA.SetTargetVal([handles.module,'.FMdepth'],0);
        G_DA.SetTargetVal([handles.module,'.FMrate'],0);
        
        %Turn on AM
        AMdepth = get(handles.AM_depth_slider,'Value');
        G_DA.SetTargetVal([handles.module,'.mod_depth'],AMdepth);
        
        AMrate = get(handles.AM_rate_slider,'Value');
        G_DA.SetTargetVal([handles.module,'.mod_rate'],AMrate);
        
    case 'Frequency Modulation'
        set(handles.AM_depth_slider,'enable','off')
        set(handles.AM_rate_slider,'enable','off')
        set(handles.FM_depth_slider,'enable','on')
        set(handles.FM_rate_slider,'enable','on')
        
        set(handles.AMdepth_text,'visible','off')
        set(handles.AMrate_text,'visible','off')
        set(handles.FMdepth_text,'visible','on')
        set(handles.FMrate_text,'visible','on')
        
        set(handles.AM_panel,'ForegroundColor',[0.5 0.5 0.5]);
        set(handles.AM_depth_slider_text,'ForegroundColor',[0.5 0.5 0.5]);
        set(handles.AM_rate_slider_text,'ForegroundColor',[0.5 0.5 0.5]);

        set(handles.FM_panel,'ForegroundColor','k');
        set(handles.FM_depth_slider_text,'ForegroundColor','k');
        set(handles.FM_rate_slider_text,'ForegroundColor','k');
        
        set(handles.no_modulation,'ForegroundColor','k');
        set(handles.no_modulation,'FontWeight','normal');
        set(handles.AM_modulation,'ForegroundColor','k');
        set(handles.AM_modulation,'FontWeight','normal');
        set(handles.freq_modulation,'ForegroundColor','r');
        set(handles.freq_modulation,'FontWeight','bold');
        
        %Turn off AM
        G_DA.SetTargetVal([handles.module,'.mod_depth'],0);
        G_DA.SetTargetVal([handles.module,'.mod_rate'],0);
        
        %Turn on FM
        FMdepth = get(handles.FM_depth_slider,'Value');
        G_DA.SetTargetVal([handles.module,'.FMdepth'],FMdepth);
        
        FMrate = get(handles.FM_rate_slider,'Value');
        G_DA.SetTargetVal([handles.module,'.FMrate'],FMrate);
end

guidata(hObject,handles)


%CENTER FREQUENCY CALLBACK
function center_freq_slider_Callback(hObject, ~, handles)
global G_DA

%Update the gui
center_freq = get(hObject,'Value');
set(handles.center_freq,'String',[num2str(center_freq), ' (Hz)']);

%Update the frequency in the RPVds circuit
G_DA.SetTargetVal([handles.module,'.center_freq'],center_freq);


selector = G_DA.GetTargetVal([handles.module,'.selector']);


switch selector
    case 0 %tone
        
        %Because we've changed the center frequency, we also need to update the
        %sound calibration level
        dBSPL = G_DA.GetTargetVal([handles.module,'.dBSPL']);
        update_sound_level(selector,dBSPL,handles)
        
    case 1 %noise
        
        %Because we've changed the center frequency, we need to update the
        %bandwidth of the sound
        bandwidth = get(handles.bandwidth_slider,'Value');
        updatebandwidth(center_freq,bandwidth,handles);
end

guidata(hObject,handles);


%FREQUENCY BANDWIDTH CALLBACK
function bandwidth_slider_Callback(hObject, ~, handles)
global G_DA

%Update the gui
bandwidth = get(hObject,'Value');
set(handles.bandwidth_text,'String',num2str(bandwidth));

%Get center frequency of carrier
center_freq = G_DA.GetTargetVal([handles.module,'.center_freq']);

%Calculate high pass and low pass frequencies for the desired bandwidth
updatebandwidth(center_freq,bandwidth,handles);

guidata(hObject,handles);


%UPDATE BANDWIDTH
function updatebandwidth(center_freq,bandwidth,handles)
global G_DA

hp = center_freq - (bandwidth*center_freq/2);
lp = center_freq + (bandwidth*center_freq/2);

%Avoid hp filter values that are too low (not sure why this is a problem,
%but if the value is too low, the filter component macro in the RPVds
%circuit stops working.)
if hp < 10
    hp = 10;
end

%Avoid lp filter values that are too high for the sampling rate of the
%device (nyquist)
if lp > 48000
    lp = 48000;
end


%Send the filter frequencies to the RPVds circuit
G_DA.SetTargetVal([handles.module,'.FiltHP'],hp);
G_DA.SetTargetVal([handles.module,'.FiltLP'],lp);


%AM DEPTH CALLBACK
function AM_depth_slider_Callback(hObject, ~, handles)
global G_DA

AMdepth = get(hObject,'Value');
set(handles.AMdepth_text,'String',[num2str(AMdepth*100), ' %']);

G_DA.SetTargetVal([handles.module,'.mod_depth'],AMdepth);

guidata(hObject,handles);


%AM RATE CALLBACK
function AM_rate_slider_Callback(hObject, ~, handles)
global G_DA

AMrate = get(hObject,'Value');
set(handles.AMrate_text,'String',[num2str(AMrate), ' (Hz)']);

G_DA.SetTargetVal([handles.module,'.mod_rate'],AMrate);

guidata(hObject,handles);


%FM DEPTH CALLBACK
function FM_depth_slider_Callback(hObject, ~, handles)
global G_DA

FMdepth = get(hObject,'Value');
set(handles.FMdepth_text,'String',[num2str(FMdepth), ' %']);

G_DA.SetTargetVal([handles.module,'.FMdepth'],FMdepth);

guidata(hObject,handles);


%FM RATE CALLBACK
function FM_rate_slider_Callback(hObject, ~, handles)
global G_DA

FMrate = get(hObject,'Value');
set(handles.FMrate_text,'String',[num2str(FMrate), ' (Hz)']);

G_DA.SetTargetVal([handles.module,'.FMrate'],FMrate);

guidata(hObject,handles);



%SOUND LEVEL CALLBACK
function dBSPL_slider_Callback(hObject, ~, handles)
global G_DA

%Update gui
dBSPL = get(hObject,'Value');
set(handles.dBSPL_text,'String',[num2str(dBSPL), ' (dBSPL)']);

%Determine which sound carrier is selected (tone or noise)
selector = G_DA.GetTargetVal([handles.module,'.selector']);

%Update the sound level
update_sound_level(selector,dBSPL,handles)
 
 
 
guidata(hObject,handles);


%UPDATE CALIBRATED SOUND LEVEL
function update_sound_level(selector,dBSPL,handles)
global G_DA TONE_CAL NOISE_CAL

switch selector
    case 0 %tone
        
        %Set the normalization value for calibration
        G_DA.SetTargetVal([handles.module,'.~center_freq_norm'],TONE_CAL.hdr.cfg.ref.norm);
        
        %Get the center frequency
        center_freq = G_DA.GetTargetVal([handles.module,'.center_freq']);
        
        %Calculate the voltage adjustment
        CalAmp = Calibrate(center_freq,TONE_CAL);
        
    case 1 %noise
        
        %Set the normalization value for calibration
        G_DA.SetTargetVal([handles.module,'.~center_freq_norm'],NOISE_CAL.hdr.cfg.ref.norm);
        
        %Calculate the voltage adjustment
        CalAmp = NOISE_CAL.data(1,4);
end

%Send the values to the RPvds circuit
G_DA.SetTargetVal([handles.module,'.~center_freq_Amp'],CalAmp);
G_DA.SetTargetVal([handles.module,'.dBSPL'],dBSPL);


%SOUND DURATION SLIDER
function duration_slider_Callback(hObject, ~, handles)
global G_DA

duration = get(hObject,'Value');
set(handles.duration_text,'String',[num2str(duration), ' (msec)']);

G_DA.SetTargetVal([handles.module,'.StimDur'],duration);

guidata(hObject,handles)


%ISI SLIDER
function ISI_slider_Callback(hObject, ~, handles)
global G_COMPILED

ISI = get(hObject,'Value');
set(handles.ISI_text,'String',[num2str(ISI), ' (msec)']);

G_COMPILED.OPTIONS.ISI = ISI;


guidata(hObject,handles);




%---------------------------------------------------------------
%FIGURE WINDOW CONTROLS
%---------------------------------------------------------------
function figure1_CloseRequestFcn(hObject, ~, ~)

%Close the figure
delete(hObject);



