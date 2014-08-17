function varargout = ep_AddSubject(varargin)
% S = ep_AddSubject 
% S = ep_AddSubject(S)
% 
% Optionally input a structure S with fields already populated.
% 
% Output/Input(optional) structure:
% S.BoxID
% S.Name
% S.Weight
% S.Sex
% S.Species
% S.Notes
% 
% A second optional input can be used to specify Box IDs.
%  BoxIds = [3 4 6];
%  S = ep_AddSubject(...,BoxIDs);
% 
% Daniel.Stolzberg@gmail.com


% Last Modified by GUIDE v2.5 03-Aug-2014 10:55:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ep_AddSubject_OpeningFcn, ...
                   'gui_OutputFcn',  @ep_AddSubject_OutputFcn, ...
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


% --- Executes just before ep_AddSubject is made visible.
function ep_AddSubject_OpeningFcn(hObj, ~, h, varargin)
h.output = hObj;

set(h.box_id,'String',1:16,'Value',1);
species = getpref('ep_AddSubject','species','< ADD SPECIES >');
userspc = getpref('ep_AddSubject','user_species','');
sval = find(ismember(species,userspc),1);
if isempty(sval), sval = 1; end
set(h.species,'String',species,'Value',sval);
species_Callback(h.species)

if ~isempty(varargin)
    if isstruct(varargin{1})
        PopulateFields(varargin{1},h);
    end
    
    if nargin > 1 && isvector(varargin{2})
        set(h.box_id,'String',varargin{2},'Value',1)
    end
end
guidata(hObj, h);

uiwait(h.ep_AddSubject);



% --- Outputs from this function are returned to the command line.
function varargout = ep_AddSubject_OutputFcn(hObj, ~, ~)
varargout{1} = [];
if ~ishandle(hObj), return; end
h = guidata(hObj);
if isfield(h,'S'), varargout{1} = h.S; end
close(h.ep_AddSubject);




function PopulateFields(S,h)
if isfield(S,'BoxID')
    n = str2num(get(h.box_id,'String')); %#ok<ST2NM>
    idx = find(S.BoxID == n,1);
    if ~isempty(idx)
        set(h.box_id,'Value',idx)
    end
end

if isfield(S,'Name')
    set(h.subject_name,'String',S.Name);
end

if isfield(S,'Weight') && isnumeric(S.Weight)
    set(h.subject_weight,'String',S.Weight)
end

if isfield(S,'Sex')
    idx = find(ismember(get(h.sex,'String'),S.Sex),1);
    if ~isempty(idx)
        set(h.sex,'Value',idx)
    end
end

if isfield(S,'Species')
    idx = find(ismember(get(h.species,'String'),S.Species),1);
    if ~isempty(idx)
        set(h.species,'Value',idx)
    end
end

if isfield(S,'Notes')
    set(h.notes,'String',S.Notes);
end

function species_Callback(hObj)
s = get_string(hObj);

if ~strcmp(s,'< ADD SPECIES >')
    setpref('ep_AddSubject','user_species',s);
    return
end

alls = get(hObj,'String');

news = inputdlg('Enter name of a new species:','Add Subject',1);
if isempty(char(news))
    set(hObj,'Value',1);
    return
end

news = strtrim(news);

if ismember(news,alls)
    msgbox('Species Already Exists');
    return
end
alls = [news,alls];
set(hObj,'String',alls,'Value',1);

setpref('ep_AddSubject',{'species','user_species'},{alls,news})

fprintf('A new species was added to the list: %s\n',news)









function S = CollectSubjectInfo(h)
S.BoxID   = str2double(get_string(h.box_id));
S.Name    = strtrim(get(h.subject_name,'String'));
S.Weight  = str2double(get(h.subject_weight,'String'));
S.Sex     = strtrim(get_string(h.sex));
S.Species = get_string(h.species);
S.Notes   = get(h.notes,'String');





function Done(h) %#ok<DEFNU>
h.S = CollectSubjectInfo(h);

hObj = h.ep_AddSubject;

guidata(hObj,h);

if isequal(get(hObj, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, use UIRESUME
    uiresume(hObj);
else
    % The GUI is no longer waiting, just close it
    delete(hObj);
end







