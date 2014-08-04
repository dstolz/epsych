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

h = Initialize(h);

guidata(hObj, h);

% --- Outputs from this function are returned to the command line.
function varargout = ep_PsychConfig_OutputFcn(~, ~, h) 

varargout{1} = h.output;











function h = Initialize(h)
h.CONFIG = struct('filename',[],'SUBJECT',[],'PROTOCOL',[]);







function LocateProtocol(h)
[fn,pn] = uigetfile('*.prot','Locate Protocol');




function h = AddSubject(h,S)

bid = 1:16;

if ~isempty(h.CONFIG.SUBJECT)
    bid = setdiff(bid,[h.CONFIG.SUBJECT.BoxID]);
    Names = {h.CONFIG.SUBJECT.Name};
end

if nargin == 1
    S = ep_AddSubject([],bid);
end

if isempty(S) || isempty(S.Name), return; end

if ismember(S.Name,Names)
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

set(h.remove_subject,'Enable','on');
set(h.subject_list,'Value',length(h.CONFIG.SUBJECT));

guidata(h.PsychConfig,h);



function RemoveSubject(h)
idx = get(h.subject_list,'Value');
h.CONFIG.SUBJECT(idx) = [];

if isempty(h.CONFIG.SUBJECT)
    set(h.remove_subject,'Enable','off');
end

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













