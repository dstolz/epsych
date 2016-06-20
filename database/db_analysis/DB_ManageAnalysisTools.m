function varargout = DB_ManageAnalysisTools(varargin)
% h = DB_ManageAnalysisTools(varargin)

% Edit the above text to modify the response to help DB_ManageAnalysisTools

% Last Modified by GUIDE v2.5 19-May-2016 08:43:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DB_ManageAnalysisTools_OpeningFcn, ...
                   'gui_OutputFcn',  @DB_ManageAnalysisTools_OutputFcn, ...
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


% --- Executes just before DB_ManageAnalysisTools is made visible.
function DB_ManageAnalysisTools_OpeningFcn(hObj, ~, h, varargin)
h.output = hObj;

guidata(hObj, h);

CreateDBtable;

UpdateAnalysisTools(h);

tools_Callback(h.tools, [], h);

CheckProtButtons(h);


% --- Outputs from this function are returned to the command line.
function varargout = DB_ManageAnalysisTools_OutputFcn(~, ~, h) 
varargout{1} = h.output;













function tools_Callback(hObj, ~, h)
tstr = get_string(hObj);
t = mymprintf(['SELECT protocol_id_str FROM db_util.analysis_tools ', ...
    'WHERE tool = "%s"'],tstr);

t = str2num(char(t)); %#ok<ST2NM>

ResetProtocols(h);

p = get(h.available_protocols,'UserData');

bind = ismember(p.id,t);

set(h.available_protocols,'String',p.listname(~bind),'Value',1);
set(h.valid_protocols,'String',p.listname(bind),'Value',1);
CheckProtButtons(h);




function add_tool_Callback(~, ~, h) %#ok<DEFNU>
options.WindowStyle = 'modal';
options.Interpreter = 'none';
t = inputdlg('Enter function name:','Add Tool',1,{''},options);
t = char(t);
if isempty(t), return; end

if ~exist(t,'file')
    errordlg(sprintf('The function "%s" was not found on the path.',t), ...
        'Add Tool','modal');
    return
end

mym(['REPLACE db_util.analysis_tools (tool,protocol_id_str) ', ...
     'VALUES ("{S}","[]")'],t);

UpdateAnalysisTools(h);
ResetProtocols(h);
CheckProtButtons(h);

function remove_tool_Callback(~, ~, h) %#ok<DEFNU>
tool = get_string(h.tools);

mym('DELETE FROM db_util.analysis_tools WHERE tool = "{S}"',tool);

UpdateAnalysisTools(h);

tools_Callback(h.tools, [], h);

CheckProtButtons(h);




function UpdateAnalysisTools(h)
t = myms('SELECT tool FROM db_util.analysis_tools');
if isempty(t)
    errordlg('No Analysis Tools Found')
    return
else
    set(h.tools,'String',t,'Value',length(t));
end



function ResetProtocols(h)
p = GetDBProtocols;
set(h.available_protocols,'String',p.listname,'Value',1,'UserData',p);
set(h.valid_protocols,'String','','Value',1);
CheckProtButtons(h);


function CheckProtButtons(h)
s = get(h.available_protocols,'String');
if isempty(s)
    set(h.add_protocol,'Enable','off');
else
    set(h.add_protocol,'Enable','on');
end

s = get(h.valid_protocols,'String');
if isempty(s)
    set(h.remove_protocol,'Enable','off');
else
    set(h.remove_protocol,'Enable','on');
end



function CreateDBtable
myms(['CREATE  TABLE IF NOT EXISTS db_util.analysis_tools (', ...
     'id INT UNSIGNED NOT NULL AUTO_INCREMENT ,', ...
     'tool VARCHAR(45) NOT NULL ,', ...
     'protocol_id_str VARCHAR(45) NOT NULL ,', ...
     'PRIMARY KEY (id, tool) ,', ...
     'UNIQUE INDEX id_UNIQUE (id ASC) );']);


function p = GetDBProtocols
p = mym(['SELECT *,CONCAT(pid," ",alias," - ",name) AS listname ' ,...
         'FROM db_util.protocol_types ', ...
         'ORDER BY pid']);




function UpdateDB(h)
t = get_string(h.tools);
p = get(h.available_protocols,'UserData');

bs = get(h.valid_protocols,'String');

Bid = p.id(ismember(p.listname,bs));

if isempty(Bid)
    pstr = '[]';
else
    pstr = mat2str(Bid);
end
 
mymprintf(['UPDATE db_util.analysis_tools ', ...
     'SET protocol_id_str = "%s" ', ...
     'WHERE tool = "%s"'],pstr,t);


function add_protocol_Callback(~, ~, h) %#ok<DEFNU>
av = get(h.available_protocols,'Value');
as = get(h.available_protocols,'String');
ns = as(av);
as(av) = [];
bs = get(h.valid_protocols,'String');
bs = [bs; ns];

set(h.available_protocols,'String',as,'Value',1);
set(h.valid_protocols,'String',bs,'Value',1);

CheckProtButtons(h);
UpdateDB(h);



function remove_protocol_Callback(~, ~, h) %#ok<DEFNU>
bv = get(h.valid_protocols,'Value');
bs = get(h.valid_protocols,'String');
ns = bs(bv);
bs(bv) = [];
as = get(h.available_protocols,'String');
as = [as; ns];

set(h.available_protocols,'String',as,'Value',1);
set(h.valid_protocols,'String',bs,'Value',1);

CheckProtButtons(h);
UpdateDB(h);













function Done(h) %#ok<DEFNU>
close(h.figure1);

