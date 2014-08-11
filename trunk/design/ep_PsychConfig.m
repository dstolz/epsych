function varargout = ep_PsychConfig(varargin)
% ep_PsychConfig
% 
% Configure a psychophysics experiment with or without OpenEx for
% electrophysiology.
% 
% Daniel.Stolzberg@gmail.com 2014


% Last Modified by GUIDE v2.5 04-Aug-2014 11:34:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ep_PsychConfig_OpeningFcn, ...
                   'gui_OutputFcn',  @ep_PsychConfig_OutputFcn, ...
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


% --- Executes just before ep_PsychConfig is made visible.
function ep_PsychConfig_OpeningFcn(hObj, ~, h, varargin)
h.output = hObj;

h = ClearConfig(h);

guidata(hObj, h);

% --- Outputs from this function are returned to the command line.
function varargout = ep_PsychConfig_OutputFcn(~, ~, h) 

varargout{1} = h.output;










function h = ClearConfig(h)
h.CONFIG = struct('protocolfile',[],'SUBJECT',[],'PROTOCOL',[]);

set(h.add_subject,'Enable','on');
set(h.subject_list,'Value',1,'String','')
set([h.prot_description,h.num_ids,h.expt_protocol],'String','');
set(h.disp_prefs,'Value',1,'String','');

guidata(h.PsychConfig,h);

UpdateGUIstate(h);


function SaveConfig(h) %#ok<DEFNU>
[fn,pn] = uiputfile('*.config','Save Current Configuration');
if ~fn
    fprintf('Configuration not saved.\n')
    return
end

config = h.CONFIG; %#ok<NASGU>
save(fullfile(pn,fn),'config','-mat');

fprintf('Configuration saved as: ''%s''\n',fullfile(pn,fn))

function LoadConfig(h) %#ok<DEFNU>
pn = getpref('ep_PsychConfig','CDir',cd);
[fn,pn] = uigetfile('*.config','Open Configuration File',pn);
if ~fn, return; end
setpref('ep_PsychConfig','CDir',pn);

h = ClearConfig(h);

cfn = fullfile(pn,fn);

fprintf('Loading configuration file: ''%s''\n',cfn)

load(cfn,'-mat');

if ~exist('config','var')
    errordlg('Invalid Configuration file','PsychConfig','modal');
    return
end

h.CONFIG = config;

UpdateSubjectList(h);

set(h.subject_list,'Value',1);

h = LocateProtocol(h,h.CONFIG.protocolfile{1});

set(h.subject_list,'Enable','on');

SelectSubject(h.subject_list,h);

LocateDispPrefs(h, h.CONFIG.DispPref);


UpdateGUIstate(h);


guidata(h.PsychConfig,h);

function h = LocateProtocol(h,pfn)
if nargin == 1
    pn = getpref('ep_PsychConfig','PDir',cd);
    if ~exist(pn,'dir'), pn = cd; end
    drawnow
    [fn,pn] = uigetfile('*.prot','Locate Protocol',pn);
    if ~fn, return; end
    setpref('ep_PsychConfig','PDir',pn);
    pfn = fullfile(pn,fn);
end

if ~exist(pfn,'file')
    warndlg(sprintf('The file "%s" does not exist.',pfn),'Psych Config','modal')
    return
end

load(pfn,'protocol','-mat');

if isempty(h.CONFIG.PROTOCOL)
    h.CONFIG.protocolfile = {pfn};
    h.CONFIG.PROTOCOL = protocol;
else
    h.CONFIG.protocolfile{end+1} = pfn;
    h.CONFIG.PROTOCOL(end+1) = protocol;
end





function boxids = ProtocolBoxIDs(P)
wp = P.COMPILED.writeparams;
t = cellfun(@(a) (tokenize(a,'~')),wp,'uniformoutput',false);
id = cellfun(@(a) (str2double(a{end})),t);
boxids = unique(id);


function h = AddSubject(h,S) 

boxids = 1:16;
Names = [];
if ~isempty(h.CONFIG.SUBJECT)
    boxids = setdiff(boxids,[h.CONFIG.SUBJECT.BoxID]);
    Names = {h.CONFIG.SUBJECT.Name};
end

if nargin == 1
    S = ep_AddSubject([],boxids);
else
    S = ep_AddSubject(S,boxids);
end

if isempty(S) || isempty(S.Name), return; end

if ~isempty(Names) && ismember(S.Name,Names)
    warndlg(sprintf('The subject name "%s" is already in use.',S.Name), ...
        'Add Subject','modal');
    return
end

if isempty(h.CONFIG.SUBJECT)
    h.CONFIG.SUBJECT = S;
else
    h.CONFIG.SUBJECT(end+1) = S;
end


h = LocateProtocol(h);

if length(h.CONFIG.PROTOCOL) ~= length(h.CONFIG.SUBJECT)
    return
end


UpdateSubjectList(h);

set(h.subject_list,'Value',length(h.CONFIG.SUBJECT),'Enable','on');

SelectSubject(h.subject_list,h);

guidata(h.PsychConfig,h);

boxids = ProtocolBoxIDs(h.CONFIG.PROTOCOL(end));
if ~any(S.BoxID==boxids)
    RemoveSubject(h);
    b = questdlg(sprintf('WARNING: Box id %d not found in protocol file "%s"\n', ...
        S.BoxID,h.CONFIG.protocolfile{end}),'PsychConfig','Try Again','Cancel','Try Again');
    if strcmp(b,'Try Again')
        h = guidata(h.PsychConfig);
        AddSubject(h,S);
    else
        return
    end
            
end

UpdateGUIstate(h);


function RemoveSubject(h,idx)
if nargin == 1
    idx = get(h.subject_list,'Value');
end
h.CONFIG.SUBJECT(idx)  = [];
h.CONFIG.PROTOCOL(idx) = [];
h.CONFIG.protocolfile(idx) = [];

UpdateGUIstate(h);

UpdateSubjectList(h);

guidata(h.PsychConfig,h);



function UpdateSubjectList(h)
if isempty(h.CONFIG.SUBJECT)
    set(h.subject_list,'Value',1,'String','');
    return
end
BoxIDs = {h.CONFIG.SUBJECT.BoxID};
Names  = {h.CONFIG.SUBJECT.Name};
s = cellfun(@(a,b) (sprintf('Box %d - %s',a,b)),BoxIDs,Names,'UniformOutput',false);
set(h.subject_list,'Value',1,'String',s);




function ViewTrials(h) %#ok<DEFNU>
idx = get(h.subject_list,'Value');

if isempty(h.CONFIG.PROTOCOL(idx)), return; end

ep_CompiledProtocolTrials(h.CONFIG.PROTOCOL(idx),'trunc',2000);







function UpdateGUIstate(h)
GotProtocol = ~isempty(h.CONFIG.PROTOCOL);
GotSubjects = numel(h.CONFIG.SUBJECT);

objs = [h.remove_subject,h.view_trials,h.subject_list];
if GotProtocol && GotSubjects
    set(objs,'Enable','on');
else
    set(objs,'Enable','off');
end


function SelectSubject(hObj,h)
idx = get(hObj,'Value');

protocol = h.CONFIG.PROTOCOL(idx);

set(h.prot_description,'String',protocol.INFO);

[pn,fn,~] = fileparts(h.CONFIG.protocolfile{idx});

set(h.expt_protocol,'String',fn,'tooltipstring',pn);



function LocateDispPrefs(h, data)
if nargin == 1 || isempty(data)
    pn = getpref('ep_BitMasker','filepath',cd);
    [fn,pn] = uigetfile('*.mat','Load Bit Pattern',pn);
    if ~fn, return; end
    dispfn = fullfile(pn,fn);
    load(dispfn,'data');
end

if ~exist('data','var')
    errordlg(sprintf('Invalid file: "%s"',fullfile(pn,fn)),'modal');
end

ind = cell2mat(data.design(:,3));
d   = data.design(ind,1);
if isempty(d)
    d = '< NONE SPECIFIED >';
end

set(h.disp_prefs,'Value',1,'String',d);

h.CONFIG.DispPref = data;
guidata(h.PsychConfig,h);

function LaunchDesign(h) %#ok<DEFNU>
if isempty(h.CONFIG.protocolfile)
    ep_ExperimentDesign;
else
    idx = get(h.subject_list,'Value');
    ep_ExperimentDesign(h.CONFIG.protocolfile{idx});
end

