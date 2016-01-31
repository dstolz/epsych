function varargout = Tinnitus2AFC_Monitor(varargin)
% TINNITUS2AFC_MONITOR MATLAB code for Tinnitus2AFC_Monitor.fig
%      TINNITUS2AFC_MONITOR, by itself, creates a new TINNITUS2AFC_MONITOR or raises the existing
%      singleton*.
%
%      H = TINNITUS2AFC_MONITOR returns the handle to a new TINNITUS2AFC_MONITOR or the handle to
%      the existing singleton*.
%
%      TINNITUS2AFC_MONITOR('CALLBACK',hObj,e,h,...) calls the local
%      function named CALLBACK in TINNITUS2AFC_MONITOR.M with the given input arguments.
%
%      TINNITUS2AFC_MONITOR('Property','Value',...) creates a new TINNITUS2AFC_MONITOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Tinnitus2AFC_Monitor_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Tinnitus2AFC_Monitor_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIh

% Edit the above text to modify the response to help Tinnitus2AFC_Monitor

% Last Modified by GUIDE v2.5 23-Jul-2015 14:05:10

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Tinnitus2AFC_Monitor_OpeningFcn, ...
                   'gui_OutputFcn',  @Tinnitus2AFC_Monitor_OutputFcn, ...
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



% --- Executes just before Tinnitus2AFC_Monitor is made visible.
function Tinnitus2AFC_Monitor_OpeningFcn(hObj, e, h, varargin)
% This function has no output args, see OutputFcn.
% hObj    handle to figure
% e  reserved - to be defined in a future version of MATLAB
% h    structure with h and user data (see GUIDATA)
% varargin   command line arguments to Tinnitus2AFC_Monitor (see VARARGIN)

% Choose default command line output for Tinnitus2AFC_Monitor
h.output = hObj;
h.BOXID = varargin{1};

% Update h structure
guidata(hObj, h);

% UIWAIT makes Tinnitus2AFC_Monitor wait for user response (see UIRESUME)
% uiwait(h.figure1);



% --- Outputs from this function are returned to the command line.
function varargout = Tinnitus2AFC_Monitor_OutputFcn(hObj, e, h) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObj    handle to figure
% e  reserved - to be defined in a future version of MATLAB
% h    structure with h and user data (see GUIDATA)

% Get default command line output from h structure
varargout{1} = h.output;

T = CreateTimer(hObj);

start(T);



function T = CreateTimer(f)

h = guidata(f);

% Create new timer for RPvds control of experiment
T = timerfind('Name',sprintf('BoxTimer~%d',h.BOXID));
if ~isempty(T)
    stop(T);
    delete(T);
end

T = timer('BusyMode','drop', ...
    'ExecutionMode','fixedSpacing', ...
    'Name','BoxTimer', ...
    'Period',0.1, ...
    'StartFcn',{@BoxTimerSetup,f}, ...
    'TimerFcn',{@BoxTimerRunTime,f}, ...
    'ErrorFcn',{@BoxTimerError}, ...
    'StopFcn', {@BoxTimerStop}, ...
    'TasksToExecute',inf, ...
    'StartDelay',0);





function BoxTimerSetup(hObj,~,f)
global AX RUNTIME
h = guidata(f);
T = RUNTIME.TRIALS(h.BOXID);


% % incuedelay
% val{:} = SelectTrial(T,sprintf('cue_delay~%d',h.BOXID));
% set(h.INCueDelay,'String',sprintf('[%0.f %0.f]',val{1}(1),val{1}(2)));
% 
% % intimeout
% val = SelectTrial(T,'timeout_dur~1');
% set(h.INTimeOut,'String',sprintf('%0.f',val));
% 
% % incuedelay
% val = SelectTrial(T,'*RewardRate~1');
% set(h.INRewardRate,'String',sprintf('%0.f',val));
% 

% trial count
set(h.PanBox,'Title', ['BOX: ', num2str(h.BOXID)])
set(h.PanTrials,'Title', ['#TRIALS: ', num2str(0)])
set(h.TextHitsNum,'String',num2str(0))
set(h.TextHitsPerc,'String',num2str(0))
set(h.TextMissNum,'String',num2str(0))
set(h.TextMissPerc,'String',num2str(0))
set(h.TextLeftNum,'String',num2str(0))
set(h.TextLeftPerc,'String',num2str(0))
set(h.TextRightNum,'String',num2str(0))
set(h.TextRightPerc,'String',num2str(0))

% detail graph 
cla(h.axDetail); 
UpdateAxDetail(h.axDetail,[1 2 3 5 6 7 8 9],[0 0 0 0 0 0 0 0]);

% detail table
colsD = {'Quiet','AM','NBN','NBN 8','NBN 12','NBN 16','NBN20','NBN24'};
set(h.DetailTable,'Data',{[],[],[],[],[],[],[],[]},'ColumnName',colsD);

% trial history table
colsH = {'TrialType','HPFreq','LPFreq','Level','LevelVar','CueDelay','#NP','Response','Reward'};

HCurrent = cell(1,9);
CurrentTrial = T.NextTrialID;
CurrentTrialDef = T.trials(CurrentTrial,:);

switch  CurrentTrialDef{15} 
    case 0 ;   HCurrent{1} = 'AM';
    case 1 ;   HCurrent{1} = 'QUIET';
    case 2 ;   HCurrent{1} = 'NBN';
end       
HCurrent(2) = CurrentTrialDef(11); 
HCurrent(3) = CurrentTrialDef(12); 
HCurrent(4) = CurrentTrialDef(14); 
HCurrent(5) = {AX.GetTagVal((sprintf('LevelVar~%d',h.BOXID)))};
HCurrent(6) = {AX.GetTagVal((sprintf('CueDelay~%d',h.BOXID)))};
HCurrent(9) = {AX.GetTagVal((sprintf('*RewardTrial~%d',h.BOXID)))};

set(h.HistoryTable,'Data',HCurrent,'RowName','C','ColumnName',colsH)

%R = AX.GetTagVal((sprintf('*RewardTrial~%d',h.BOXID)));
%RUNTIME.TRIALS.DATA.Reward_1{1} = AX.GetTagVal('RewardTrial~1');

% history graph
cla(h.axHistory);




function BoxTimerRunTime(~,~,f)
global AX RUNTIME
persistent lastupdate 

h = guidata(f);

availableBoxes = [RUNTIME.TRIALS.BoxID];
BOX_IND = availableBoxes==h.BOXID;

T = RUNTIME.TRIALS(BOX_IND);

DATA = T.DATA; 
ntrials = DATA(end).TrialID;

if isempty(ntrials)
    ntrials = 0;
    lastupdate(BOX_IND) = 0;
end

if ntrials == lastupdate(BOX_IND), return; end

%% get current data 
TrialType   = [DATA.(sprintf('TrialType_%d',h.BOXID))]';   TrialTypeC = cell(size(TrialType)); 
HPFreq      = [DATA.(sprintf('HPFreq_%d',h.BOXID))]'; % uHPFreq = unique(HPFreq);
LPFreq      = [DATA.(sprintf('LPFreq_%d',h.BOXID))]';
Level       = [DATA.(sprintf('Level_%d',h.BOXID))]';
LevelVar    = [DATA.(sprintf('LevelVar_%d',h.BOXID))]';
CueDelay    = [DATA.(sprintf('CueDelay_%d',h.BOXID))]';
NumNosePokes = [DATA.(sprintf('NumNosePokes_%d',h.BOXID))]';
Reward      = [DATA.(sprintf('x_RewardTrial_%d',h.BOXID))]';
bitmask     = [DATA.ResponseCode]';    Responses = cell(size(bitmask));         


%%Convert trial type to text
AMind = TrialType == 0;     TrialTypeC(AMind)    = {'AM'};
QUIETind = TrialType == 1;  TrialTypeC(QUIETind) = {'QUIET'};
NBNind = TrialType == 2;    TrialTypeC(NBNind)   = {'NBN'};

%Convert response 
HITind      = logical(bitget(bitmask,3)); Responses(HITind)  = {'Hit'};
MISSind     = logical(bitget(bitmask,4)); Responses(MISSind) = {'Miss'};
RIGHTind    = logical(bitget(bitmask,7));
LEFTind     = logical(bitget(bitmask,6));
NORESPind   = logical(bitget(bitmask,10));Responses(NORESPind) = {'Abort'};

%idendify diffrent NBN trails
NBN8ind     = NBNind & HPFreq == 7661;
NBN12ind    = NBNind & HPFreq == 11491;
NBN16ind    = NBNind & HPFreq == 15322;
NBN20ind    = NBNind & HPFreq == 19152;
NBN24ind    = NBNind & HPFreq == 22982;


%% update Trial Counts
set(h.PanTrials,'Title', ['#TRIALS: ', num2str(ntrials)])
set(h.TextHitsNum,'String',num2str(sum(HITind)))
set(h.TextHitsPerc,'String',sprintf('%0.f',(sum(HITind)/ntrials*100)))

set(h.TextMissNum,'String',num2str(sum(MISSind)))
set(h.TextMissPerc,'String',sprintf('%0.f',(sum(MISSind)/ntrials*100)))

set(h.TextLeftNum,'String',num2str(sum(LEFTind)))
set(h.TextLeftPerc,'String',sprintf('%0.f',(sum(LEFTind)/ntrials*100)))

set(h.TextRightNum,'String',num2str(sum(RIGHTind)))
set(h.TextRightPerc,'String',sprintf('%0.f',(sum(RIGHTind)/ntrials*100)))


%% update detail graph - responses to left side
L(1)  = sum(QUIETind & LEFTind)/sum(QUIETind)*100;  
L(2)  = sum(AMind & LEFTind)/sum(AMind)*100;        
L(3)  = sum(NBNind & LEFTind)/sum(NBNind)*100;      
L(4)  = sum(NBN8ind & LEFTind)/sum(NBN8ind)*100;    
L(5)  = sum(NBN12ind & LEFTind)/sum(NBN12ind)*100;  
L(6)  = sum(NBN16ind & LEFTind)/sum(NBN16ind)*100;  
L(7)  = sum(NBN20ind & LEFTind)/sum(NBN20ind)*100;  
L(8)  = sum(NBN24ind & LEFTind)/sum(NBN24ind)*100;  

X     =[1 2 3 5 6 7 8 9];

UpdateAxDetail(h.axDetail,X,L);


%% update detail table - responses to left side
D = zeros(2,8);
D(1,1) = L(1);  D(2,1)  = sum(QUIETind);
D(1,2) = L(2);  D(2,2)  = sum(AMind);
D(1,3) = L(3);  D(2,3)  = sum(NBNind);
D(1,4) = L(4);  D(2,4)  = sum(NBN8ind);
D(1,5) = L(5);  D(2,5)  = sum(NBN12ind);
D(1,6) = L(6);  D(2,6)  = sum(NBN16ind);
D(1,7) = L(7);  D(2,7)  = sum(NBN20ind);
D(1,8) = L(8);  D(2,8)  = sum(NBN24ind);

set(h.DetailTable,'Data',D)


%% update history table
H = cell(ntrials,9);
HCurrent = cell(1,9);

%current trial
CurrentTrial = T.NextTrialID;
CurrentTrialDef = T.trials(CurrentTrial,:);

switch  CurrentTrialDef{strcmp(T.Mwriteparams,sprintf('TrialType_%d',h.BOXID))} 
    case 0 ;   HCurrent{1} = 'AM';
    case 1 ;   HCurrent{1} = 'QUIET';
    case 2 ;   HCurrent{1} = 'NBN';
end
         
HCurrent(2) = CurrentTrialDef(strcmp(T.Mwriteparams,sprintf('HPFreq_%d',h.BOXID))); 
HCurrent(3) = CurrentTrialDef(strcmp(T.Mwriteparams,sprintf('LPFreq_%d',h.BOXID))); 
HCurrent(4) = CurrentTrialDef(strcmp(T.Mwriteparams,sprintf('Level_%d',h.BOXID))); 
HCurrent(5) = {AX.GetTagVal(sprintf('LevelVar~%d',h.BOXID))}; 
HCurrent(6) = {AX.GetTagVal(sprintf('CueDelay~%d',h.BOXID))};
HCurrent(9) = {AX.GetTagVal(sprintf('*RewardTrial~%d',h.BOXID))};

% Rewarded or not?

for n = 1: ntrials
 if strcmp(Responses(n),'Miss')|| strcmp(Responses(n),'Abort')
    Reward(n) = 0;
 end
end


%previous trials
H = cell(ntrials,9);
H(:,1) = TrialTypeC;
H(:,2) = num2cell(HPFreq);
H(:,3) = num2cell(LPFreq);
H(:,4) = num2cell(Level);
H(:,5) = num2cell(LevelVar);
H(:,6) = num2cell(CueDelay);
H(:,7) = num2cell(NumNosePokes);
H(:,8) = Responses;
H(:,9) = num2cell(Reward);

H = [HCurrent;flipud(H)];

r = length(Responses):-1:1;
r = cellstr(num2str(r'));
r = ['C'; r];

set(h.HistoryTable,'Data',H,'RowName',r)


%% update history graph

%Set time scale
TS = zeros(ntrials,1);
for i = 1:ntrials
    TS(i) = etime(DATA(i).ComputerTimestamp,RUNTIME.StartTime);
end
TS = TS / 60;

UpdateAxHistory(h.axHistory,TS,HITind,MISSind,NORESPind,RIGHTind,LEFTind,Reward);

%% 
lastupdate(h.BOXID) = ntrials;



function BoxTimerError(~,~)


function BoxTimerStop(~,~)



function UpdateAxDetail(ax,X,L)
cla(ax);
hold(ax,'on')
bar(ax,X,L,'k');
set(ax,'XTick',X,...
       'XTickLabel',{'Quiet','AM','NBN','NBN 8','NBN 12','NBN 16','NBN20','NBN24'},...
       'YLim',[0 100]);
ylabel(ax,'%left');
hold(ax,'off');




function UpdateAxHistory(ax,TS,HITind,MISSind,NORESPind,RIGHTind,LEFTind,Rind)
cla(ax);

hold(ax,'on')
plot(ax,TS(HITind&LEFTind&Rind), ones(sum(HITind&LEFTind&Rind,1)),'go','markerfacecolor','g');
plot(ax,TS(HITind&LEFTind&~Rind), ones(sum(HITind&LEFTind&~Rind,1)),'go','markerfacecolor','none');
plot(ax,TS(MISSind&LEFTind),ones(sum(MISSind&LEFTind,1)),'ro','markerfacecolor','none');

plot(ax,TS(HITind&RIGHTind&Rind), zeros(sum(HITind&RIGHTind&Rind,1)),'go','markerfacecolor','g');
plot(ax,TS(HITind&RIGHTind&~Rind), zeros(sum(HITind&RIGHTind&~Rind,1)),'go','markerfacecolor','none');
plot(ax,TS(MISSind&RIGHTind),zeros(sum(MISSind&RIGHTind,1)),'ro','markerfacecolor','none');

plot(ax,TS(NORESPind),   0.5*ones(sum(NORESPind),1),'ks','markerfacecolor','none');
hold(ax,'off');

set(ax,'ytick',[0 1],'yticklabel',{'RIGHT','LEFT'},'ylim',[-0.1 1.1]);

xlabel(ax,'time (min)');






%% SOFT TRIGGER




% % --- Executes on button press in ButtonFeederLeft.
% function ButtonFeederLeft_Callback(hObject,eventdata, handles)
% % hObject    handle to ButtonFeederLeft (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% global AX
% %AX.SoftTrg(7); 
% 
%  AX.SetTagVal('!ManualLeftFeeder~1',1);
%  pause(0.001);
%  AX.SetTagVal('!ManualLeftFeeder~1',0);
% disp('Box 1: Left Feeder Triggered');
% 
% 
% 
% % --- Executes on button press in ButtonFeederRight.
% function ButtonFeederRight_Callback(hObject,eventdata, handles)
% % hObject    handle to ButtonFeederRight (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% global AX
% 
%  AX.SetTagVal('!ManualRightFeeder~1',1);
%  pause(0.001);
%  AX.SetTagVal('!ManualRightFeeder~1',0);
%  disp('Box 1: Right Feeder Triggered');
% 
% 
% % --- Executes on button press in ButtonTimeOut.
% function ButtonTimeOut_Callback(hObject,eventdata, handles)
% % hObject    handle to ButtonTimeOut (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% global AX
% %AX.SoftTrg(5);
% 
% % % New method of triggering an RPvds circuit so it is compatible with
% % % OpenEx circuits
%  AX.SetTagVal('!ManualTimeOut~1',1);
%  pause(0.001);
%  AX.SetTagVal('!ManualTimeOut~1',0);

 
 

function ButtonFeederLeft_Callback(hObject, e, h)
% hObject    handle to ButtonFeederLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global AX RUNTIME

 AX.SetTagVal(sprintf('!ManualLeftFeeder~%d',h.BOXID),1);
 pause(0.001);
 AX.SetTagVal(sprintf('!ManualLeftFeeder~%d',h.BOXID),0);
 disp(sprintf('Box %d: Left Feeder Triggered',h.BOXID));



% --- Executes on button press in ButtonFeederRight.
function ButtonFeederRight_Callback(hObject, e, h)
% hObject    handle to ButtonFeederRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global AX

 AX.SetTagVal(sprintf('!ManualRightFeeder~%d',h.BOXID),1);
 pause(0.001);
 AX.SetTagVal(sprintf('!ManualRightFeeder~%d',h.BOXID),0);
 disp(sprintf('Box %d: Right Feeder Triggered',h.BOXID));
 

% --- Executes on button press in ButtonTimeOut.
function ButtonTimeOut_Callback(hObject, e, h)
% hObject    handle to ButtonTimeOut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global AX

 AX.SetTagVal(sprintf('!ManualTimeOut~%d',h.BOXID),1);
 pause(0.001);
 AX.SetTagVal(sprintf('!ManualTimeOut~%d',h.BOXID),0);
 disp(sprintf('Box %d: TimeOut Triggered',h.BOXID));





%% 


function INTimeOut_Callback(hObject, eventdata, handles)
% hObject    handle to INTimeOut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of INTimeOut as text
%        str2double(get(hObject,'String')) returns contents of INTimeOut as a double


% --- Executes during object creation, after setting all properties.
function INTimeOut_CreateFcn(hObject, eventdata, handles)
% hObject    handle to INTimeOut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





function INRewardRate_Callback(hObject, eventdata, handles)
% hObject    handle to INRewardRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of INRewardRate as text
%        str2double(get(hObject,'String')) returns contents of INRewardRate as a double


% --- Executes during object creation, after setting all properties.
function INRewardRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to INRewardRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





% --- Executes on button press in ButtonUpdate.
function ButtonUpdate_Callback(hObj, e, h)
global AX RUNTIME

T = RUNTIME.TRIALS(h.BOXID);

set(hObj,'String','UPDATING','BackgroundColor','g'); drawnow

NEWCueDelay   = str2num(get(h.INCueDelay,'String'));
NEWTimeOut    = str2num(get(h.INTimeOut,'String'));
NEWRewardRate = str2num(get(h.INRewardRate,'String'));

ind = ismember(T.writeparams,sprintf('CueDelay~%d',h.BOXID));  
T.trials(:,ind) = {NEWCueDelay};
T.randparams(ind) = numel(NEWCueDelay) == 2;

ind = ismember(T.writeparams,sprintf('TimeOutDur~%d',h.BOXID));
T.trials(:,ind) = {NEWTimeOut};

ind = ismember(T.writeparams,sprintf('*RewardRate~%d',h.BOXID));
T.trials(:,ind) = {NEWRewardRate};


UpdateRPtags(AX,T);





pause(0.5)

set(hObj,'String','UPDATE','BackgroundColor',get(gcf,'Color'));




