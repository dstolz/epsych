function varargout = PumpControl_Tunings(varargin)
% PUMPCONTROL_TUNINGS MATLAB code for PumpControl_Tunings.fig


% Edit the above text to modify the response to help PumpControl_Tunings

% Last Modified by GUIDE v2.5 23-Sep-2015 10:31:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PumpControl_Tunings_OpeningFcn, ...
                   'gui_OutputFcn',  @PumpControl_Tunings_OutputFcn, ...
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


% --- Executes just before PumpControl_Tunings is made visible.
function PumpControl_Tunings_OpeningFcn(hObj, ~, h, varargin)
h.output = hObj;

h.PumpNames = varargin{1};

SetupTables(h);

% Update h structure
guidata(hObj, h);

% --- Outputs from this function are returned to the command line.
function varargout = PumpControl_Tunings_OutputFcn(~, ~, h) 
varargout{1} = h.output;









function SetupTables(h)
set([h.ConsTunings h.AggrTunings],'rowname',h.PumpNames);


Kc = nan(length(h.PumpNames),3);
Ka = nan(length(h.PumpNames),3);
for PumpID = 0:length(h.PumpNames)-1
    kstr = ArduinoCom(sprintf('l,%d',PumpID));
    kc = textscan(kstr,'%f,%f,%f,%f,%f,%f');
    kval = cell2mat(kc);
    Kc(PumpID+1,:) = kval(1:3);
    Ka(PumpID+1,:) = kval(4:6);
end

set(h.ConsTunings,'Data',Kc);
set(h.AggrTunings,'Data',Ka);

Gap = ArduinoCom('g');
set(h.gap_val,'String',num2str(Gap,'%d'));


function ConsTunings_CellEditCallback(hObj, e, h)
set(h.ConsTunings_slide,'value',e.NewData); drawnow


function ConsTunings_CellSelectionCallback(hObj, e, h)
if isempty(e.Indices), return; end

K = get(hObj,'Data');
set(h.ConsTunings_slide,'value',K(e.Indices(1),e.Indices(2)), ...
    'UserData',e.Indices);



function AggrTunings_CellEditCallback(hObj, e, h)
set(h.AggrTunings_slide,'value',e.NewData); drawnow

function AggrTunings_CellSelectionCallback(hObj, e, h)
if isempty(e.Indices), return; end

K = get(hObj,'Data');
set(h.AggrTunings_slide,'value',K(e.Indices(1),e.Indices(2)), ...
    'UserData',e.Indices);



function SlideCallback(hObj,h)
if strcmp(get(hObj,'tag'),'ConsTunings_slide')
    t = h.ConsTunings;
else
    t = h.AggrTunings;
end

d = get(t,'Data');
c = get(hObj,'UserData');

if isempty(c), return; end

d(c(1),c(2)) = get(hObj,'value');

set(t,'Data',d);


function CheckGapVal(hObj) %#ok<DEFNU>
gap = round(str2double(get(hObj,'String')));
if gap < 1,    gap = 1;    end
if gap > 100, gap = 1000; end
set(hObj,'String',num2str(gap,'%d'));

function UpdateTunings(h) %#ok<DEFNU>
cD = get(h.ConsTunings,'Data');
aD = get(h.AggrTunings,'Data');

c = 'pid';
a = 'PID';

fprintf('Updating tunings ...')

T = timerfind('tag','PumpTimer');
stop(T);

for PumpID = 0:length(h.PumpNames)-1
    for i = 1:size(cD,2)
        ArduinoCom(sprintf('K%c,%d,%0.4f',c(i),PumpID,cD(PumpID+1,i)));
        ArduinoCom(sprintf('K%c,%d,%0.4f',a(i),PumpID,aD(PumpID+1,i)));
    end
end

% SetupTables(h);

gap = str2double(get(h.gap_val,'String'));
ArduinoCom(sprintf('G,%d',gap));

start(T);

fprintf(' done\n')

function Kval = GetCurKval(PumpID,p_i_d)
Kval = nan;
if ~ismember(p_i_d,'pidPID'), return; end
Kval = ArduinoCom(sprintf('b%c,%d',p_i_d,PumpID));

function Kval = GetKval(PumpID,p_i_d)
Kval = nan;
if ~ismember(p_i_d,'pidPID'), return; end
Kval = ArduinoCom(sprintf('k%c,%d',p_i_d,PumpID));

