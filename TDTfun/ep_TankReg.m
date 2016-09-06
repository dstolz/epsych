function varargout = TankReg(varargin)
% TankReg
%
% DJS (2011)

% Copyright (C) 2016  Daniel Stolzberg, PhD

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TankReg_OpeningFcn, ...
                   'gui_OutputFcn',  @TankReg_OutputFcn, ...
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


% --- Executes just before TankReg is made visible.
function TankReg_OpeningFcn(hObj, eventdata, h, varargin) %#ok<INUSL>
% Choose default command line output for TankReg
h.output = hObj;

regDir = getpref('TankReg','regDir',cd);
PopulateTanks(h,regDir);
PopulateRegTanks(h);

% Update h structure
guidata(hObj, h);

% uiwait(h.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = TankReg_OutputFcn(hObj, eventdata, h)  %#ok<INUSL>
varargout{1} = h.output;
















%% 
function PopulateRegTanks(h)
% retrieve and display registered tanks
[TT,tanks,TDTfig] = TDT_SetupTT;
if isempty(tanks), tanks = ''; end
delete(TT);
close(TDTfig);

set(h.registered_tanks,'Value',1);
set(h.registered_tanks,'String',tanks);


function PopulateTanks(h,path)
if nargin == 1
    regDir = getpref('TankReg','regDir',cd);
    path = uigetdir(regDir,'Locate Tank Directory');
    if ~path, return; end
end

[tanks,islegacy] = CheckForTanks(path);

if isempty(tanks)
    set(h.available_tanks,'Value',1);
    set(h.available_tanks,'String','');
    fprintf('** NO TANKS FOUND IN THIS DIRECTORY **\n')
    return
end

% Add asterisk to legacy tanks
for i = 1:find(islegacy), tanks{i} = [tanks{i} '*']; end

set(h.available_tanks,'Value',1);
set(h.available_tanks,'String',tanks);

setpref('TankReg','regDir',path);

set(h.tank_dir,'String',path);













%% Callbacks

function register_Callback(hObj, ~, h) %#ok<INUSL,DEFNU>
tanks = get(h.available_tanks,'String');

if isempty(tanks), return; end

x = get(h.available_tanks,'Value');
tanks = cellstr(tanks);
tanks = tanks(x);

set(h.figure1,'Pointer','watch');

regDir = getpref('TankReg','regDir',cd);

for i = 1:length(tanks) 
    % remove asterisk if legacy tank
    if tanks{i}(end) == '*', tanks{i}(end) = []; end

    fprintf('Adding tank: %s ... ',tanks{i})

	r = addTankToRegistry(tanks{i},regDir);

    if r
        fprintf('SUCCESS\n')
    else
        fprintf('FAILURE\n')
    end
    
end

pause(1) % pause for a second to allow registry to update

PopulateRegTanks(h);

set(h.figure1,'Pointer','arrow');


function unregister_Callback(hObj, eventdata, h) %#ok<INUSL,DEFNU>
tanks = cellstr(get(h.registered_tanks,'String'));
tanks = tanks(get(h.registered_tanks,'Value'));
set(h.figure1,'Pointer','watch');

for i = 1:length(tanks)
    fprintf('Removing tank: %s ... ',tanks{i})
    r = remTankFromRegistry(tanks{i});
    if r
        fprintf('SUCCESS\n')
    else
        fprintf('FAILURE\n')
    end
end

pause(1) % pause for a second to allow registry to update

PopulateRegTanks(h);
set(h.figure1,'Pointer','arrow');
