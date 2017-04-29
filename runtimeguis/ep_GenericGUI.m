function varargout = ep_GenericGUI(varargin)
% ep_GenericGUI;
%
% In the ep_RunExpt GUI, click "GUI Figure" under the "Function
% Definitions" menu.  This will prompt you to enter the name to this or 
%
% The primary purpose of this GUI is to serve as a modifiable template for
% developing new GUIs for use with EPsych behavior software (ep_RunExpt).
%
% This GUI was created using Matlab's GUIDE utility.  To modify this GUI,
% enter 'guide ep_GenericGUI' in the command window.  Save the GUI as your
% own and modify the GUI and code to suit your needs.
%
%
% Useful global variables
% > RUNTIME contains info about currently running experiment including
% trial data collected so far.
%
% > AX is the ActiveX control being used.  Gives direct programmatic access
% to running RPvds circuit(s).  AX will be a single handle to OpenDeveloper
% activex control, if using OpenEx, or handle(s) to ActiveX control if not
% using OpenEx.  See TDT documentation for more information on using these
% activex controls.  The function TDTpartag can be used to make the same
% code compatible with either activex control.
%
% Also see, TDTpartag
%
% Daniel.Stolzberg@gmail.com 4/2017



% Last Modified by GUIDE v2.5 25-Apr-2017 19:56:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ep_GenericGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ep_GenericGUI_OutputFcn, ...
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










% --- Executes just before ep_GenericGUI is made visible.
function ep_GenericGUI_OpeningFcn(hObj, ~, h, varargin)
h.output = hObj;
guidata(hObj, h);



% --- Outputs from this function are returned to the command line.
function varargout = ep_GenericGUI_OutputFcn(hObj, ~, h) 
varargout{1} = h.output;

% Generate a new timer object and then start it
T = CreateTimer(hObj);
start(T);

















% GUITimer ---------------------------------------------------------
function T = CreateTimer(f)
% Create new timer for RPvds control of experiment
T = timerfind('Name','GUITimer');
if ~isempty(T)
    stop(T);
    delete(T);
end

T = timer('BusyMode','drop', ...
    'ExecutionMode','fixedSpacing', ...
    'Name','GUITimer', ...
    'Period',0.05, ... % Adjust rate of polling for updates on RPvds circuit
    'StartFcn',{@GUITimerSetup,f},   ... % Called once on startup
    'TimerFcn',{@GUITimerRunTime,f}, ... % Main timer function
    'ErrorFcn',{@GUITimerError},     ... % Catch and handle errors occuring in timer functions
    'StopFcn', {@GUITimerStop},      ... % Called at end of experiment
    'TasksToExecute',inf, ...
    'StartDelay',0);




function GUITimerSetup(T,~,f)
global RUNTIME

% figure handles
h = guidata(f);

% set which function the btn_CreatePlot function will call when clicked.
set(h.btn_CreatePlot,'Callback',{@CreatePlot,h.lst_Xparam,h.lst_Yparam});

% Setup h.tbl_TrialHistory
[~,INFO] = rearrangeDATA(RUNTIME.TRIALS.DATA);
set(h.tbl_TrialHistory,'ColumnName',INFO.fields);

% Setup X and Y lists for plotting
set(h.lst_Xparam,'String',INFO.fields, ...
    'TooltipString','Select one X parameter');

set(h.lst_Yparam,'String',[{'*COUNT*'}; INFO.fields], ...
    'TooltipString','Select one or more Y parameters','Max',5);


%
set(h.btn_LocatePlots,'Callback',@LocatePlots);

if isempty(T.UserData)
    T.UserData = clock; % start time
end






function GUITimerRunTime(T,~,f)
% see main help file for this GUI for more info on these global variables
global RUNTIME AX 

% persistent variables hold their values across calls to this function
persistent lastupdate



% AX changes class if an error occurred during runtime
% if isempty(AX) || ~isa(AX,'COM.TDevAcc_X'), stop(T); return; end


% number of trials is length of
ntrials = RUNTIME.TRIALS.DATA(end).TrialID;

if isempty(ntrials)
    ntrials = 0;
    lastupdate = 0;
end

    
% escape timer function until a trial has finished
if ntrials == lastupdate,  return; end
lastupdate = ntrials;
% `````````````````````````````````````````````````````````````````````````


% There was a new trial, so do stuff with new data






% Retrieve a structure of handles to objects on the GUI.
h = guidata(f);






% Call a function to rearrange DATA to make it easier to use (see below).
[DATA,INFO] = rearrangeDATA(RUNTIME.TRIALS.DATA);










% Display each trial in the GUI table h.tbl_TrialHistory ------------------

% Flip the DATA matrix so that the most recent trials are displayed at the
% top of the table.
set(h.tbl_TrialHistory,'Data',flipud(DATA));

% set the row names as the trial ids
set(h.tbl_TrialHistory,'RowName',flipud(INFO.TrialID));






% Update any existing plots -----------------------------------------------
updatePlots(DATA,INFO);








function GUITimerError(T,e)
vprintf(0,1,'ep_GenericGUI Error Occurred')
% e = etime(clock,T.UserData);
% vprintf(0,'Session Duration ~ %0.1f minutes',e/60);


function GUITimerStop(T,~)
% e = etime(clock,T.UserData);
% vprintf(0,'Session Duration ~ %0.1f minutes',e/60);













% -------------------------------------------------------------------------
function [DATAout,INFO] = rearrangeDATA(DATAin)
% Access some fields from DATA that are automatically generated by EPsych.
% Note that while the following is just fine, it is coded here for clarity
% and relative ease of use.  You can modify this function for your own
% needs.

% Use Response Code bitmask to compute behavior performance
INFO.RCode = [DATAin.ResponseCode]';
DATAin = rmfield(DATAin,'ResponseCode');

% Trial numbers
INFO.TrialID = [DATAin.TrialID]';
DATAin = rmfield(DATAin,'TrialID');

% Crude timestamp of when the trial occured.  This is not indended for use
% in data analysis.  Only use timestamps generated by the TDT hardware
% since it is much more accurate and precise.
INFO.ComputerTimestamp = [DATAin.ComputerTimestamp]';
DATAin = rmfield(DATAin,'ComputerTimestamp');


% The remaining fields of the DATA structure contain parameters for each
% trial.
fieldsin = fieldnames(DATAin);


% % Remove the leading module alias
% INFO.fields = cellfun(@(a) (a(find(a=='_',1))),fieldsin,'uni',0);

% The following for loop will vectorize fields of the structure DATAin and
% tored in a NxM matrix called DATAout. M is the number of fields in
% DATAin, and N is the number of trials so far.
% Since we don't know the field names of structure ahead of time (changes
% for each experiment), we use dynamic field names (search Matlab
% documentation for more info).
for i = 1:length(fieldsin)
    DATAout(:,i) = [DATAin.(fieldsin{i})];
end

INFO.fields = fieldsin;





function updatePlots(DATA,INFO)
% This function will find all valid plots and update them.  
%


% Find existing axes that we want to update
ax = findobj('type','axes','-and','-regexp','tag','ep_GenericGUI_*');

% Loop through existing axes, find which parameters are plotted, update
% with new data.
for i = 1:length(ax)
    
    % We stored the x and y variables in the axis UserData field
    d = ax(i).UserData;
    
    
    for j = 1:length(d.hline)
        % Extract x and y data
        x = DATA(:,strcmp(d.X,INFO.fields));
        
        
        if isequal(d.Y{j},'*COUNT*');
            ux = unique(x);
            [y,x] = hist(x,ux);
        else
            y = DATA(:,strcmp(d.Y{j},INFO.fields));
        end
        
        
        % Update the 'line' object on the plot
        set(d.hline(j),'xdata',x,'ydata',y);
    end
    
    
end




function CreatePlot(~,~,hX,hY)
% Generate a new plot

global RUNTIME

% get selected values for x and y
sX = get(hX,'String');
iX = get(hX,'Value');
d.X = sX{iX};

sY = get(hY,'String');
iY = get(hY,'Value');
d.Y = sY(iY);

if isempty(iX) || isempty(iY)
    fprintf(2,'Select values for both X and Y\n');
    return
end

% create a new figure with a unique tag (so we can find it in LocatePlots)
f = figure('tag',sprintf('ep_GenericGUI_%d',randi(1e6,1)));

% create a new axis on that figure
ax = axes('Parent',f,'tag',sprintf('ep_GenericGUI_%d',randi(1e6,1)));

% initialize lines
c = lines(length(d.Y));
for i = 1:length(d.Y)
    d.hline(i) = line('xdata',0,'ydata',0,'parent',ax,'marker','o', ...
        'color',c(i,:),'linestyle','none','linewidth',3);
end


grid(ax,'on');

xlabel(ax,d.X);

% add legend
legend(ax,d.Y,'location','northeastoutside','Interpreter','none');
ax.UserData = d;

[DATA,INFO] = rearrangeDATA(RUNTIME.TRIALS.DATA);
updatePlots(DATA,INFO)


function LocatePlots(~,~)
% locate handles ot plot figure and then bring them to the front
f = findobj('type','figure','-and','-regexp','tag','ep_GenericGUI_*');
for i = 1:length(f)
    figure(f(i));
end







