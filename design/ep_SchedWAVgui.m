function varargout = ep_SchedWAVgui(varargin)
% ep_SchedWAVgui(callingh,filestruct)
%
% Daniel.Stolzberg@gmail.com 2014

% Last Modified by GUIDE v2.5 03-Aug-2014 15:34:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ep_SchedWAVgui_OpeningFcn, ...
                   'gui_OutputFcn',  @ep_SchedWAVgui_OutputFcn, ...
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


% --- Executes just before ep_SchedWAVgui is made visible.
function ep_SchedWAVgui_OpeningFcn(hObj, evnt, h, varargin) %#ok<INUSL>
% Choose default command line output for ep_SchedWAVgui
h.output = hObj;

h.CALLING_H = varargin{1}; % handle of calling function
h.DATAIN    = varargin{2}; % data input

% Update h structure
guidata(hObj, h);



% --- Outputs from this function are returned to the command line.
function varargout = ep_SchedWAVgui_OutputFcn(hObj, evnt, h)  %#ok<INUSL>

% Get default command line output from h structure
varargout{1} = h.output;







function wav_table_Select(hObj,evnt,h) %#ok<INUSL,DEFNU>
if isempty(evnt.Indices), return; end
h.SELECTED_ROW = evnt.Indices(1);
guidata(h.figure1,h);







function add_file_Callback(hObj, evnt, h) %#ok<INUSL,DEFNU>
lastpath = getpref('ep_SchedWAVgui','lastpath',cd);
if ~ischar(lastpath), lastpath = cd; end

[fn,pn,fi] = uigetfile({'*.wav','WAV file (*.wav)'; '*.mat','MAT file (*.mat)'}, ...
    'Pick a file', ...
    lastpath,'MultiSelect','on');

if ischar(fn), fn = {fn}; end

if ~iscell(fn) && ~fn, return; end

setpref('ep_SchedWAVgui','lastpath',pn);

dat = get(h.wav_table,'Data');
S = get(h.wav_table,'UserData');

for i = 1:length(fn)
    pfn = fullfile(pn,fn{i});
    
    switch fi
        case 1 % wav file
            % read in WAV file as double precision
            [Y,Fs,~] = wavread(pfn,'double');
            
            
            % store WAV data in structure
            s.buffer = Y;
            s.dur    = length(Y)/Fs*1000;
            s.nsamps = length(Y);
            s.Fs     = Fs;
            s.nbits  = nbits;
            s.type   = 'WAV';
            
        case 2 % mat file buffer
            X = who('-file',pfn,'buffer');
            if isempty(X)
                errordlg(sprintf(['The file ''%s'' does not contain the ', ...
                    'variable ''buffer'''],pfn),'Missing Variable ''buffer''')
                return
            end
            
            s = load(pfn);
            s.nsamps = length(s.buffer);
            if ~isfield(s,'Fs'), s.Fs = 1; end
            s.dur = s.nsamps/s.Fs*1000;
            s.type = 'MAT';
            
    end
    
    s.file   = fn{i};
    s.path   = pn;
    
    
    % update table
    if isempty(dat) || isempty(dat{1})
        dat = {fn{i}, num2str(s.Fs,'%0.1f'), num2str(s.dur,'%0.1f')};
    else
        dat(end+1,:) = {fn{i}, num2str(s.Fs,'%0.1f'), num2str(s.dur,'%0.1f')}; %#ok<AGROW>
    end
        
    
    % store all data in UserData
    if isempty(S)
        S = {s};
    else
        S{end+1} = s; %#ok<AGROW>
    end
end

set(h.wav_table,'Data',dat,'UserData',S);


function remove_file_Callback(hObj, evnt, h) %#ok<INUSL,DEFNU>
if ~isfield(h,'SELECTED_ROW'), return; end
selrow = h.SELECTED_ROW;

S = get(h.wav_table,'UserData');
dat = get(h.wav_table,'Data');

if isempty(S) || isempty(dat), return; end

if selrow > length(S), return; end

S(selrow)   = [];
dat(selrow,:) = [];

set(h.wav_table,'Data',dat,'UserData',S);


function move_up_Callback(hObj, evnt, h) %#ok<INUSL,DEFNU>
if ~isfield(h,'SELECTED_ROW'), return; end
selrow = h.SELECTED_ROW;

S = get(h.wav_table,'UserData');
dat = get(h.wav_table,'Data');

if isempty(S) || isempty(dat), return; end

if selrow == 1, return; end

s           = S(selrow-1);
S(selrow-1) = S(selrow);
S(selrow)   = s;

d               = dat(selrow-1,:);
dat(selrow-1,:) = dat(selrow,:);
dat(selrow,:)   = d;

set(h.wav_table,'Data',dat,'UserData',S);

h.SELECTED_ROW = selrow-1;
guidata(h.figure1,h);

function move_down_Callback(hObj, evnt, h) %#ok<INUSL,DEFNU>
if ~isfield(h,'SELECTED_ROW'), return; end
selrow = h.SELECTED_ROW;

S = get(h.wav_table,'UserData');
dat = get(h.wav_table,'Data');

if isempty(S) || isempty(dat), return; end

if selrow == length(S), return; end

s           = S(selrow+1);
S(selrow+1) = S(selrow);
S(selrow)   = s;

d               = dat(selrow+1,:);
dat(selrow+1,:) = dat(selrow,:);
dat(selrow,:)   = d;

set(h.wav_table,'Data',dat,'UserData',S);

h.SELECTED_ROW = selrow+1;
guidata(h.figure1,h);

function done_Callback(hObj, evnt, h) %#ok<INUSL,DEFNU>
S = get(h.wav_table,'UserData');

% send data to calling GUI
setappdata(h.CALLING_H,'ep_SchedWAVgui_DATA',S);

delete(h.figure1);
