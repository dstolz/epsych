function varargout = ep_BoxFig(varargin)
% ep_BoxFig
% 
% Default figure for displaying behavior results during runtime.
% 
% Daniel.Stolzberg@gmail.com 2014

% Last Modified by GUIDE v2.5 12-Aug-2014 14:20:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ep_BoxFig_OpeningFcn, ...
                   'gui_OutputFcn',  @ep_BoxFig_OutputFcn, ...
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


% --- Executes just before ep_BoxFig is made visible.
function ep_BoxFig_OpeningFcn(hObj, ~, h, varargin)
% Choose default command line output for ep_BoxFig
h.output = hObj;

% Update h structure
guidata(hObj, h);

T = CreateTimer(hObj);

start(T);


% --- Outputs from this function are returned to the command line.
function varargout = ep_BoxFig_OutputFcn(~, ~, h) 

% Get default command line output from h structure
varargout{1} = h.output;






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
    'Period',1, ...
    'StartFcn',{@BoxTimerSetup,f}, ...
    'TimerFcn',{@BoxTimerRunTime,f}, ...
    'ErrorFcn',{@BoxTimerError}, ...
    'StopFcn', {@BoxTimerStop}, ...
    'TasksToExecute',inf, ...
    'StartDelay',2);







function BoxTimerSetup(hObj,~,f)
global CONFIG 

h = guidata(f);

dpref = CONFIG(1).DispPref;

ind  = cell2mat(dpref.design(:,3));
pars = dpref.design(ind,1);

cf = [{'char'},repmat({'numeric'},1,length(pars)+1)];

tdata = num2cell(zeros(length(CONFIG),length(pars)));
tdata = [repmat({''},length(CONFIG),1),tdata];

BoxIDs = arrayfun(@(b) ({b.SUBJECT.BoxID}),CONFIG)';
set(h.data_table,'ColumnName',[{'Subject'};{'# Trials'};pars(:)]','RowName',BoxIDs, ...
    'ColumnFormat',cf,'data',tdata);

D.DispPref = CONFIG(1).DispPref;
D.pars = pars;
D.ind  = ind;
D.bits = find(ind);

set(hObj,'UserData',D);






function BoxTimerRunTime(hObj,~,f)
global RUNTIME

h = guidata(f);
D = get(hObj,'UserData');

data = zeros(RUNTIME.NSubjects,length(D.bits));
n    = zeros(RUNTIME.NSubjects,1);
for i = 1:RUNTIME.NSubjects   
    % Compute Response Code totals for display bits
    rc = [RUNTIME.TRIALS(i).DATA.ResponseCode];
    if isempty(rc), continue; end
    data(i,:) = SumBits(rc(:),D.bits);
    n(i) = length(rc);
end

name = arrayfun(@(t) (t.Subject.Name),RUNTIME.TRIALS,'UniformOutput',false)';
data = [name,num2cell([n, data])];
set(h.data_table,'Data',data);


function BoxTimerError(~,~)



function BoxTimerStop(~,~)














function d = SumBits(v,bits)
% sum bits from Response Code
a = zeros(numel(v),length(bits));
for i = 1:size(v,1)
    a(i,:) = bitget(v(i),bits);
end
d = sum(a);














