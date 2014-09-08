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

T = CreateTimer;

start(T);


% --- Outputs from this function are returned to the command line.
function varargout = ep_BoxFig_OutputFcn(~, ~, h) 

% Get default command line output from h structure
varargout{1} = h.output;






function T = CreateTimer
% Create new timer for RPvds control of experiment
delete(timerfind('Name','BoxTimer'));

T = timer('BusyMode','drop', ...
    'ExecutionMode','fixedSpacing', ...
    'Name','BoxTimer', ...
    'Period',1.0, ...
    'StartFcn',{@BoxTimerSetup}, ...
    'TimerFcn',{@BoxTimerRunTime}, ...
    'ErrorFcn',{@BoxTimerError}, ...
    'StopFcn', {@BoxTimerStop}, ...
    'TasksToExecute',inf, ...
    'StartDelay',5);







function BoxTimerSetup(hObj,~)
global CONFIG

h = guidata(f);

dpref = CONFIG(1).DispPref;

ind  = cell2mat(dpref.design(:,3));
pars = dpref.design(ind,1);

cf = repmat({'numeric'},1,length(par));

tdata = num2cell(zeros(length(CONFIG),length(pars)));

set(h.data_table,'ColumnName',{'# Trials';pars(:)},'RowName',{CONFIG.SUBJECT.BoxID}, ...
    'ColumnFormat',cf,'data',tdata);

D.DispPref = CONFIG(1).DispPref;
D.pars = pars;
D.ind  = ind;
D.bits = find(ind);

for i = 1:length(CONFIG) 
    D.RespCodeStr{i} = ModifyParamTag(sprintf('#RespCode~%d',CONFIG(i).SUBJECT.BoxID));
end


% Check for parameter tags and triggers
for i = 1:length(C(1).RPfiles)
    [t,dt] = ReadRPvdsTags(C(1).RPfiles{i});
    
    ind = cellfun(@(x) (~any(x(1)=='!#')),t);
    D.parameters{i} = t(ind);
    D.datatypes{i}  = dt(ind);
    
    ind = cellfun(@(x) (x(1)=='!'),t);
    D.triggers{i} = t(ind);
end


set(hObj,'UserData',D);






function BoxTimerRunTime(hObj,~)
global CONFIG

D = get(hObj,'UserData');
data = zeros(length(CONFIG),length(D.bits));
n    = zeros(length(CONFIG),1);
for i = 1:length(CONFIG)
    C = CONFIG(i);
    
    % Compute Response Code totals for display bits
    rc = [C.DATA.(D.RespCodeStr{i})];
    data(i,:) = Bits2Data(rc(:),D.bits);
    n(i) = length(rc);
end
data = [n, data];
set(h.data_table,'Data',data);


function BoxTimerError(~,~)



function BoxTimerStop(~,~)














function d = Bits2Data(v,bits)
a = zeros(numel(v),length(bits));
for i = 1:size(v,1)
    a(i,:) = bitget(v(i),bits);
end
d = sum(a);














