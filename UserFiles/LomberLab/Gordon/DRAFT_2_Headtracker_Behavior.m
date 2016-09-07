function varargout = DRAFT_2_Headtracker_Behavior(varargin)
% DRAFT_HEADTRACKER_BEHAVIOR MATLAB code for DRAFT_Headtracker_Behavior.fig
%      DRAFT_HEADTRACKER_BEHAVIOR, by itself, creates a new DRAFT_HEADTRACKER_BEHAVIOR or raises the existing
%      singleton*.
%
%      H = DRAFT_HEADTRACKER_BEHAVIOR returns the handle to a new DRAFT_HEADTRACKER_BEHAVIOR or the handle to
%      the existing singleton*.
%
%      DRAFT_HEADTRACKER_BEHAVIOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DRAFT_HEADTRACKER_BEHAVIOR.M with the given input arguments.
%
%      DRAFT_HEADTRACKER_BEHAVIOR('Property','Value',...) creates a new DRAFT_HEADTRACKER_BEHAVIOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DRAFT_Headtracker_Behavior_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DRAFT_Headtracker_Behavior_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DRAFT_Headtracker_Behavior

% Last Modified by GUIDE v2.5 30-Mar-2016 14:02:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DRAFT_2_Headtracker_Behavior_OpeningFcn, ...
                   'gui_OutputFcn',  @DRAFT_2_Headtracker_Behavior_OutputFcn, ...
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


% --- Executes just before DRAFT_Headtracker_Behavior is made visible.
function DRAFT_2_Headtracker_Behavior_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for DRAFT_Headtracker_Behavior
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

T = CreateTimer(handles.figure1);

global motorBox LEDuino

motorBox = serial('COM5');
set(motorBox,'BaudRate',9600);
fopen(motorBox);
pause(2);

% Add this when correct COM port is discovered
LEDuino = serial('COM4');
set(LEDuino,'BaudRate',115200);
fopen(LEDuino);
pause(2);

start(T);


% --- Outputs from this function are returned to the command line.
function varargout = DRAFT_2_Headtracker_Behavior_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.output;



%Button to start a trial from the GUI
function trialbutton_Callback(hObject, eventdata, handles)
global RUNTIME AX FASTRAK

AX.SetTagVal('*StartTrial',1);
AX.SetTagVal('*StartTrial',0);
disp('STARTING TRIAL')

%Button to give a food reward without a "hit"
function manualFeed_Callback(hObject, eventdata, handles)
global RUNTIME AX FASTRAK

AX.SetTagVal('*MANUALFEED',1);
AX.SetTagVal('*MANUALFEED',0);


%Changes the amount of time the food actuator runs. Does not change the
%speed.
function newFoodDuration_Callback(hObject, eventdata, handles)
global RUNTIME AX FASTRAK

AX.SetTagVal('FOODAMOUNT',str2num(handles.foodDuration.String));


%When the inhibit radio button is depressed no trials may occur
function inhibitButton_Callback(hObject, eventdata, handles)
global RUNTIME AX FASTRAK

if (get(hObject,'Value') == get(hObject,'Max'))
	AX.SetTagVal('*INHIBIT',1);
else
	AX.SetTagVal('*INHIBIT',0);
end

%When this is selected the user can choose which region to focus on
function manualOverride_KeyPress(hObject, eventdata, handles)
if strcmp(handles.regionSlider.Visible,'on')
    handles.regionSlider.Visible = 'off';
    handles.manualTarget.Visible = 'off';
else
    handles.regionSlider.Visible = 'on';
    handles.manualTarget.Visible = 'on';
end

%Selects the region in conjunction with the manualOverride radio button
function regionSlider_Callback(hObject, eventdata, handles)
val=round(hObject.Value);
hObject.Value=val;
handles.manualTarget.String = int2str(val);




% Timer Functions --------------------------------------

function T = CreateTimer(f)
% Create new timer for RPvds control of experiment
T = timerfind('Name','BoxTimer');
if ~isempty(T)
    stop(T);
    delete(T);
end

T = timer('BusyMode','drop', ...
    'ExecutionMode','fixedSpacing', ...
    'Name','BoxTimer', ...
    'Period',0.05, ...
    'StartFcn',{@BoxTimerSetup,f}, ...
    'TimerFcn',{@BoxTimerRunTime,f}, ...
    'ErrorFcn',{@BoxTimerError}, ...
    'StopFcn', {@BoxTimerStop}, ...
    'TasksToExecute',inf, ...
    'StartDelay',1);







function BoxTimerSetup(~,~,f)
global FASTRAK

try
    if isempty(FASTRAK) || ~isa(FASTRAK,'serial') || isequal(FASTRAK.Status,'closed')
        FASTRAK = startFastrak;
    end
catch me
    if isequal(me.identifier,'MATLAB:serial:get:invalidOBJ')
        FASTRAK = startFastrak;
    else
        rethrow(me);
    end
end



function BoxTimerRunTime(~,~,f)
% global variables
% RUNTIME contains info about currently running experiment including trial data collected so far
% AX is the ActiveX control being used

global RUNTIME AX FASTRAK motorBox LEDuino
%currentTrial holds variables for the last full trial to be displayed on
%the GUI
persistent lastupdate currentTrial  % persistent variables hold their values across calls to this function


try
    % number of trials is length of
    ntrials = RUNTIME.TRIALS.DATA(end).TrialID;
    
    if isempty(ntrials)
        ntrials = 0;
        lastupdate = 0;
    end
    
    
catch me
    % good place to put a breakpoint for debugging
    rethrow(me)    
end



% if we're in a response window, then determine if there is a correct
% response by the subject and then update the TDT circuit.

% TESTING
Headings = -75:25:75;
Tolerance = 12.5;
Target = 8;
initBuffSize = 20;



h = guidata(f);


set(h.foodmL,'String',num2str(sprintf('%0.1f',checkSyringe(motorBox))));


Headings = [-90 -60 -30 -22.5 -15 -7.5 0 7.5 15 22.5 30 60 90];
Tolerance = 5;


if strcmp(h.regionSlider.Visible, 'on')
    Target = h.regionSlider.Value;
end

polarProperties = [(Target*ones(size(Headings)));Headings;(Tolerance*ones(size(Headings)))];

%Look at FASTRAK output and determine in which region the receiver is
%pointed
currentRegion = compareHeading(x(5),Headings,Tolerance);


%Display the target region
set(h.targetText,'String',int2str(Target));

%Initializes currentTrial for the first run through of the code
if isempty(currentTrial)
    currentTrial = [Target nan nan nan];
end

%Reset X to 0 before lookinbg to see if the response window is open. X
%defines whether or not the trial resulted in a hit
X = 0;
try
    %Light up fixation LED
    %fprintf(LEDuino,'%d',2);
    
    %Get the data from FASTRAK
    x = pollFastrak(FASTRAK);
    
    %Look at FASTRAK output and determine in which region the receiver is
    %pointed
    currentRegion = compareHeading(x(5),Headings,Tolerance);
    
    Y = checkFixate(currentRegion);
    if Y == 0
        AX.SetTagVal('*StartTrial',1);
        AX.SetTagVal('*StartTrial',0);
        disp('STARTING TRIAL')
    end
    
    
    
    %Display the current region that the receiver is pointed at
    set(h.actualRegion,'String',int2str(int64(currentRegion)));
    
    %Display the polar plot showing azimuth and elevation
    visualPolar(h,x,polarProperties)
    
    
    
    %whileCheck only allows data to be written to the GUI table once after the
    %while loop has terminated
    whileCheck = 0;
    
    %This while loop defines a trial
    while AX.GetTagVal('*RespWindow') && X == 0
        whileCheck = 1;
        
        %Turn all LEDs off
        %fprintf(LEDuino,'%d',0);
        
        %Get the data from FASTRAK
        x = pollFastrak(FASTRAK);
        
        %Change the azimuth and elevation readings from FASTRAK into
        %radians and display them on the two polar plots
        visualPolar(h,x,polarProperties);
        
        
        %Look at FASTRAK output and determine in which region the receiver is
        %pointed
        currentRegion = compareHeading(x(5),Headings,Tolerance);

        %Display the current region that the receiver is pointed at
        set(h.actualRegion,'String',int2str(int64(currentRegion)));
        
        %When X == 1 then a region has been fixated on. fixedPoint is the
        %current region
        [X,fixedPoint] = checkDuration(currentRegion);
        
        %Testing
        fprintf('%0.2f\t%d\n',X,fixedPoint)
        
        %Stupid slow computer
        pause(0.001);
    end
    
    %After a trial has been run this set of if statements can occur
    if whileCheck == 1
        %If a point had been fixated on for long enough
        if X == 1
            %This defines a hit
            if Target == fixedPoint
                AX.SetTagVal('*CORRECT',1);
                currentTrial = [Target fixedPoint 1 1];
            %Fixated on the wrong region
            else
                AX.SetTagVal('*INCORRECT',1);
                currentTrial = [Target fixedPoint 0 1];
            end
        %No region fixated on for long enough or looked out of bounds for
        %the duration of the response window
        else
            AX.SetTagVal('*INCORRECT',1);
            currentTrial = [Target nan 0 1];
        end
        checkDuration(-1);
    end
catch
    %Troubleshooting
    disp('ERROR')
end

%Reset the CORRECT and INCORRECT parameters going into RPvds
AX.SetTagVal('*CORRECT',0);
AX.SetTagVal('*INCORRECT',0);
    
    

    

% escape until a new trial has been completed
if ntrials == lastupdate,  return; end
lastupdate = ntrials;


% copy DATA structure to make it easier to use
DATA = RUNTIME.TRIALS.DATA;

% Use Response Code bitmask to compute performance
RCode = [DATA.ResponseCode]';

HITS = bitget(RCode,3);
MISSES = bitget(RCode,4);
NORESP = bitget(RCode,10);

%Retrieve the data from the GUI table to add the newest trial to the
%beginning
pastData = get(h.pastTrials,'data');

%Troubleshooting
disp('Sending data to table')

%In the first trial, the new data is presented as the only row in the table
if ntrials == 1
    set(h.pastTrials,'data',currentTrial(1:3),'ColumnName',{'Target','Fixed','Hit?'});
%In any trial after the first the new data is added to the top of the
%table
else
    set(h.pastTrials,'data',cat(1,currentTrial(1:3),pastData),'ColumnName',{'Target','Fixed','Hit?'});
end



function BoxTimerError(~,~)
disp('BoxERROR');
end

function BoxTimerStop(~,~)
global FASTRAK motorBox

fclose(motorBox)
delete(motorBox)
clear motorBox

if ~isempty(FASTRAK) && isa(FASTRAK,'serial') && isequal(FASTRAK.Status,'open')
    fclose(FASTRAK)
    delete(FASTRAK)
    clear FASTRAK
end














