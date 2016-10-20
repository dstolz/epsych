function varargout = ep_BitmaskGen(varargin)
% ep_BitmaskGen
% 
% Daniel.Stolzberg@gmail.com

% Copyright (C) 2016  Daniel Stolzberg, PhD

% Last Modified by GUIDE v2.5 25-May-2015 13:17:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ep_BitmaskGen_OpeningFcn, ...
                   'gui_OutputFcn',  @ep_BitmaskGen_OutputFcn, ...
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


% --- Executes just before ep_BitmaskGen is made visible.
function ep_BitmaskGen_OpeningFcn(hObj, ~, h, varargin)
% Choose default command line output for ep_BitmaskGen
h.output = hObj;

% Update h structure
guidata(hObj, h);

SetTables(h);

% UIWAIT makes ep_BitmaskGen wait for user response (see UIRESUME)
% uiwait(h.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ep_BitmaskGen_OutputFcn(~, ~, h) 

% Get default command line output from h structure
varargout{1} = h.output;





function SetTables(h)
d = get_string(h.common_designs);

set(h.design_table,'data',DefaultTableData(d));

set(h.bitmask_table,'data',num2cell(zeros(4,4)), ...
    'rowname',{'Trial Type 0','Trial Type 1', 'Trial Type 2','Trial Type 3'}, ...
    'columnname',{'S0','S1','S2','S3'});

evnt.Indices = [1 1];
design_table_CellEditCallback(h.design_table, evnt, h)


function LoadData(h) %#ok<DEFNU>
pn = getpref('ep_DisplayPrefs','filepath',cd);
[fn,pn] = uigetfile('*.epdp','Load Display Prefs',pn);
if ~fn, return; end

load(fullfile(pn,fn),'data','-mat');

if ~exist('data','var')
    beep
    errordlg(sprintf('Invalid file: "%s"',fullfile(pn,fn)),'modal');
    return
end

if size(data.design,2) == 3, data.design(:,3) = []; end %#ok<NODEF> % for older files
set(h.design_table,'Data',data.design,'UserData',[]);
if ~isfield(data,'bitmask'), data.bitmask = num2cell(zeros(5,4)); end
set(h.bitmask_table,'Data',data.bitmask,'UserData',[]);


function SaveData(h) %#ok<DEFNU>
pn = getpref('ep_DisplayPrefs','filepath',cd);
[fn,pn] = uiputfile('*.epdp','Save Display Prefs',pn);
if ~fn, return; end

data.design = get(h.design_table,'Data');
data.bitmask = get(h.bitmask_table,'Data');
save(fullfile(pn,fn),'data','-mat');

setpref('ep_DisplayPrefs','filepath',pn);






function design_table_CellEditCallback(hObj, evnt, h)
data = get(hObj,'Data');
bm = Bits2Mask(cell2mat(data(:,2)));

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


function bitmask_table_CellSelectionCallback(hObj, evnt, h) %#ok<DEFNU>
if isempty(evnt.Indices)
    I = get(hObj,'UserData');
else
    set(hObj,'UserData',evnt.Indices);
    I = evnt.Indices;
end

data = get(hObj,'Data');
mask = uint32(data{I(1),I(2)});

if ~mask, return; end

dtdata = get(h.design_table,'Data');
nbits  = size(dtdata,1);

bits = fliplr(Mask2Bits(mask,nbits));

dtdata(:,2) = num2cell(logical(bits(:)));
set(h.design_table,'Data',dtdata);



function add_function_Callback(hObj, evnt, h) %#ok<INUSL,DEFNU>
s = inputdlg('Enter new function:','BitMasker',1);
s = strtrim(char(s));
if isempty(s), return; end

data = get(h.design_table,'Data');
if isempty(data{1}), data(1,:) = []; end
data(end+1,:) = {s,false};

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
        data = {'Reward',     true; ...
                'Punish',     false; ...
                'Hit',        true;  ...
                'Miss',       false;  ...
                'Abort',      false; ...
                'Response_A', true;  ...
                'Response_B', false;  ...
                'Pre-RespWin', false; ...
                'Response Win', true; ...
                'Post-RespWin', false; ...
                'Trial-Type 0', false;  ...
                'Trial-Type 1', true;  ...
                'Trial-Type 2', false;  ...
                'Trial-Type 3', false};
        
    case 'DETECT'
        data = {'Reward',     true; ...
                'Punish',     false; ...
                'Hit',        true;  ...
                'Miss',       false;  ...
                'Abort',      false; ...
                'CorrectReject', false;  ...
                'FalseAlarm',  false;    ...
                'Pre-RespWin', false; ...
                'Response Win', true; ...
                'Post-RespWin', false; ...
                'Trial-Type 0', false;  ...
                'Trial-Type 1', true;  ...
                'Trial-Type 2', false;  ...
                'Trial-Type 3', false};        
        
    otherwise
end



