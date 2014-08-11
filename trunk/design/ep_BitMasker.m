function varargout = ep_BitMasker(varargin)
%

% Last Modified by GUIDE v2.5 10-Aug-2014 15:36:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ep_BitMasker_OpeningFcn, ...
                   'gui_OutputFcn',  @ep_BitMasker_OutputFcn, ...
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


% --- Executes just before ep_BitMasker is made visible.
function ep_BitMasker_OpeningFcn(hObj, ~, h, varargin)
% Choose default command line output for ep_BitMasker
h.output = hObj;

% Update h structure
guidata(hObj, h);

set(h.design_table,'data',DefaultTableData('2AFC'));


set(h.bitmask_table,'data',num2cell(zeros(5,4)));

evnt.Indices = [1 1];
design_table_CellEditCallback(h.design_table, evnt, h)

% UIWAIT makes ep_BitMasker wait for user response (see UIRESUME)
% uiwait(h.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ep_BitMasker_OutputFcn(~, ~, h) 

% Get default command line output from h structure
varargout{1} = h.output;







function LoadData(h) %#ok<DEFNU>
pn = getpref('ep_BitMasker','filepath',cd);
[fn,pn] = uigetfile('*.mat','Load Bit Pattern',pn);
if ~fn, return; end

load(fullfile(pn,fn),'data');

if ~exist('data','var')
    errordlg(sprintf('Invalid file: "%s"',fullfile(pn,fn)),'modal');
end

set(h.design_table,'Data',data.design,'UserData',[]); %#ok<NODEF>
if ~isfield(data,'bitmask'), data.bitmask = num2cell(zeros(5,4)); end
set(h.bitmask_table,'Data',data.bitmask,'UserData',[]);


function SaveData(h) %#ok<DEFNU>
pn = getpref('ep_BitMasker','filepath',cd);
[fn,pn] = uiputfile('*.mat','Save Bit Pattern',pn);
if ~fn, return; end

data.design = get(h.design_table,'Data');
data.bitmask = get(h.bitmask_table,'Data');
save(fullfile(pn,fn),'data');

setpref('ep_BitMasker','filepath',pn);


function bm = CalculateBitmask(data)
% bm = CalculateBitmask(data)
% 
% data is the cell matrix from data = get(h.design_table,'Data');

b = cell2mat(data(:,2))';
i = 0:length(b)-1;
bm = sum(b.*2.^i);






function design_table_CellEditCallback(hObj, evnt, h)
data = get(hObj,'Data');
bm = CalculateBitmask(data);

curidx = get(h.bitmask_table,'UserData');
if isempty(curidx)
    d = get(hObj,'UserData');
    if isempty(d)
        curidx = [1 1];
    else
        curidx = d{1};
    end
end
if isempty(curidx), curidx = [1 1]; end

set(hObj,'UserData',{curidx, evnt.Indices});

bmdata = get(h.bitmask_table,'Data');
bmdata{curidx(1),curidx(2)} = bm;
set(h.bitmask_table,'Data',bmdata);

function design_table_CellSelectionCallback(hObj, evnt, ~) %#ok<DEFNU>
d = get(hObj,'UserData');
d{2} = evnt.Indices;
set(hObj,'UserData',d);


function bitmask_table_CellSelectionCallback(hObj, evnt, ~) %#ok<DEFNU>
set(hObj,'UserData',evnt.Indices);






function add_function_Callback(hObj, evnt, h) %#ok<INUSL,DEFNU>
s = inputdlg('Enter new function:','BitMasker',1);
s = strtrim(char(s));
if isempty(s), return; end

data = get(h.design_table,'Data');
if isempty(data{1}), data(1,:) = []; end
data(end+1,:) = {s,false,false};

d = get(h.design_table,'UserData');
d{2} = [size(data,1) 1];

set(h.design_table,'Data',data,'UserData',d);


function remove_function_Callback(hObj, evnt, h) %#ok<INUSL,DEFNU>
d = get(h.design_table,'UserData');
if isempty(d{2}), return; end

data = get(h.design_table,'Data');
data(d{2}(1),:) = [];
d{2} = [];
set(h.design_table,'Data',data,'UserData',d);

function ClearDesignTable(h) %#ok<DEFNU>
set(h.design_table,'Data',{'',false,false});
set(h.bitmask_table,'Data',num2cell(zeros(5,4)));














function data = DefaultTableData(type)


switch type
    case '2AFC'
        data = {'Reward',     true,     false; ...
                'Punish',     false,    false; ...
                'Hit',        true,     true;  ...
                'MISS',       false,    true;  ...
                'ABORT',      false,    false; ...
                'Response_A', true,     true;  ...
                'Response_B', false,    true;  ...
                'Pre-RespWin', false,   false; ...
                'Response Win', true,   false; ...
                'Post-RespWin', false,  false; ...
                'Trial-Type 0', false,  true;  ...
                'Trial-Type 1', true,   true;  ...
                'Trial-Type 2', false,  true;  ...
                'Trial-Type 3', false,  false};
        
    case 'DETECT'
        
        
        
    otherwise
end



