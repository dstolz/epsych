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
h.CONFIG = struct('filename',[],'SUBJECT',[],'PROTOCOL',[]);

h.boxids = [];

set(h.subject_list,'Value',1,'String','')
set([h.prot_description,h.num_ids,h.expt_protocol],'String','');


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
[fn,pn] = uigetfile('*.config','Open Configuration File');
if ~fn, return; end

h = ClearConfig(h);

cfn = fullfile(pn,fn);

fprintf('Loading configuration file: ''%s''\n',cfn)

load(cfn,'-mat');

if ~exist('config','var')
    errordlg('Invalid Configuration file','PsychConfig','modal');
    return
end

h.CONFIG = config;

h = LocateProtocol(h,h.CONFIG.filename);

UpdateSubjectList(h);



function h = LocateProtocol(h,pfn)
if nargin == 1
    [fn,pn] = uigetfile('*.prot','Locate Protocol');
    if ~fn, return; end
    pfn = fullfile(pn,fn);
end

load(pfn,'protocol','-mat');

h.CONFIG.filename = pfn;
h.CONFIG.PROTOCOL = protocol;

h = CheckProtocol(h);

guidata(h.PsychConfig,h);

bstr = sprintf('%d,',h.boxids); bstr(end) = [];
set(h.num_ids,'String',sprintf('Box IDs: %s',bstr));

set(h.prot_description,'String',protocol.INFO);

set(h.expt_protocol,'String',pfn,'HorizontalAlignment','left');
set(h.subject_list,'String','','Value',1);

UpdateGUIstate(h);



function h = CheckProtocol(h)
wp = h.CONFIG.PROTOCOL.COMPILED.writeparams;
t = cellfun(@(a) (tokenize(a,'~')),wp,'uniformoutput',false);
id = cellfun(@(a) (str2double(a{end})),t);
h.boxids = unique(id);


function h = AddSubject(h,S) %#ok<DEFNU>

bid = h.boxids;
Names = [];
if ~isempty(h.CONFIG.SUBJECT)
    bid = setdiff(bid,[h.CONFIG.SUBJECT.BoxID]);
    Names = {h.CONFIG.SUBJECT.Name};
end

if isempty(bid),return; end

if nargin == 1
    S = ep_AddSubject([],bid);
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

UpdateSubjectList(h);

set(h.subject_list,'Value',length(h.CONFIG.SUBJECT),'Enable','on');

UpdateGUIstate(h);

guidata(h.PsychConfig,h);



function RemoveSubject(h) %#ok<DEFNU>
idx = get(h.subject_list,'Value');
h.CONFIG.SUBJECT(idx) = [];

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
if isempty(h.CONFIG.PROTOCOL), return; end

ep_CompiledProtocolTrials(h.CONFIG.PROTOCOL,'trunc',2000);







function UpdateGUIstate(h)
GotProtocol = ~isempty(h.CONFIG.PROTOCOL);
GotSubjects = numel(h.CONFIG.SUBJECT);

if length(h.boxids)==GotSubjects
    set(h.add_subject,'Enable','off');
else
    set(h.add_subject,'Enable','on');
end

if GotProtocol && GotSubjects
    set(h.remove_subject,'Enable','on');
else
    set(h.remove_subject,'Enable','off');
end


if GotProtocol
    set(h.view_trials,'Enable','on');
else
    set(h.view_trials,'Enable','off');
end

if GotProtocol && GotSubjects
    set([h.run_experiment,h.subject_list],'Enable','on');
else
    set([h.run_experiment,h.subject_list],'Enable','off');
end








function RunExperiment(h)

% ep_Psychophysics(h.CONFIG);








