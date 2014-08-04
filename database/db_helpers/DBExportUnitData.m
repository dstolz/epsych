function DBExportUnitData(blockid)
% DBExportUnitData;
% DBExportUnitData(blockid);
%
% Export analyzed data stored on the unit_properties table to an Excel
% document.
% 
% If no input is supplied as a blockid, then the currently selected block
% from DB_Browser will be used.  If DB_Browser is not open then it will be
% launched automatically.
% 
% Daniel.Stolzberg@gmail.com        2014
% 
% See also, DB_Browser, DB2dataset, DB2NEX

if nargin == 0
    if isempty(findobj('name','DB_Browser')), DB_Browser; end
    blockid = [];
end

h = BuildGUI;
guidata(h.figure,h);

RefreshData(h.refresh,blockid);





function h = BuildGUI

f = findobj('type','figure','-and','tag','DBExportUnitData');
if isempty(f)
    f = figure('tag','DBExportUnitData','units','normalized','position',[0.5 0.2 0.35 0.6], ...
        'toolbar','none','menubar','none','name','Export Unit Data','numbertitle','off', ...
        'Color',[0.98 0.98 0.98]); 
end

clf(f);

h.figure = f;

figure(f);

h.info = uicontrol('Style','edit','Parent',f, ...
    'Units','normalized','Position',[0.05 0.45 0.50 0.50], ...
    'String','','BackgroundColor','w','FontSize',10, ...
    'HorizontalAlignment','left','Enable','inactive','Max',10);

h.refresh = uicontrol('Style','pushbutton','Parent',f, ...
    'Units','normalized','Position',[0.15 0.22 0.3 0.1], ...
    'String','Refresh','FontSize',12,'Callback',{@RefreshData,[]});

h.export = uicontrol('Style','pushbutton','Parent',f, ...
    'Units','normalized','Position',[0.15 0.05 0.3 0.15], ...
    'String','Export','FontSize',12,'Callback',@ExportData);

h.datatype = uicontrol('Style','popupmenu','Parent',f, ...
    'Units','normalized','Position',[0.15 0.35 0.3 0.05], ...
    'String',{'All','Experiment','Tank','Block'},'Value',4, ...
    'FontSize',12,'Callback',{@RefreshData,[]});

h.groups = uicontrol('Style','listbox','Parent',f, ...
    'Units','normalized','Position',[0.6 0.75 0.35 0.2], ...
    'String','','FontSize',12,'Callback',@UpdateParamsList);

uicontrol('Style','text','Parent',f, ...
    'Units','normalized','Position',[0.6 0.95 0.35 0.03], ...
    'String','Groups','FontSize',12,'BackgroundColor',[0.98 0.98 0.98]);

h.params = uicontrol('Style','listbox','Parent',f, ...
    'Units','normalized','Position',[0.6 0.05 0.35 0.65], ...
    'String','','FontSize',12,'Max',10^6);

uicontrol('Style','text','Parent',f, ...
    'Units','normalized','Position',[0.6 0.7 0.35 0.03], ...
    'String','Parameters','FontSize',12,'BackgroundColor',[0.98 0.98 0.98]);



function UpdateParamsList(hObj,~)
h = guidata(hObj);

g = get_string(hObj);

if isempty(g)
    set(h.params,'Value',1,'String','< NOTHING HERE >');
    set(h.export,'Enable','off');
    return
end
set(h.export,'Enable','on');
ind = ismember(h.DATA.groups,g);

P = h.DATA.params(ind);

set(h.params,'Value',1:length(P.name),'String',P.name);



function RefreshData(hObj,~,blockid)
if nargin < 3 || isempty(blockid)
    blockid = getpref('DB_BROWSER_SELECTION','blocks');
end

h = guidata(hObj);

datatype = get_string(h.datatype);

[info,data,groups,params] = GetDBdata(datatype,blockid);

h.DATA.info = info;
h.DATA.data = data;
h.DATA.groups = groups;
h.DATA.params = params;

guidata(hObj,h);


finfo = FormatDatasetInfo(info);
set(h.info,'String',finfo);

groups(ismember(groups,'info')) = [];
set(h.groups,'Value',1,'String',groups);

UpdateParamsList(h.groups,[]);



function ExportData(hObj,~)
h = guidata(hObj);

group = get_string(h.groups);
if isempty(group)
    msgbox('Select a group','Export','help','modal');
    return
end


param  = get_string(h.params);
if isempty(param)
    msgbox('Select at least one parameter','Export','help','modal');
    return
end

loc = getpref('DBExportUnitData','SaveLoc',cd);

[fn,pn] = uiputfile({'*.tsv',loc},'Export Unit Data (*.tsv)');

if ~fn, return; end

file = fullfile(pn,fn);

for f = fieldnames(h.DATA.data)'
    f = char(f); %#ok<FXSET>
    if isfield(h.DATA.data.(f),group)
        unitdata.(f) = h.DATA.data.(f).(group);
    end
end

params = get(h.params,'String');

ind = ~ismember(params,param);
if any(ind)
    for f = fieldnames(unitdata)'
        f = char(f); %#ok<FXSET>
        ufn = fieldnames(unitdata.(f));
        ind = ~ismember(ufn,param);
        unitdata.(f) = rmfield(unitdata.(f),ufn(ind));
    end
end

fid = fopen(file,'a');

finfo = FormatDatasetInfo(h.DATA.info);

fprintf(fid,'\n%s\n\n',finfo);

datatype = get_string(h.datatype);

if isequal(datatype,'All'), fprintf(fid,'\tExperiment'); end
if ismember(datatype,{'All','Experiment'}), fprintf(fid,'\tTank'); end
if ismember(datatype,{'All','Experiment','Tank'}), fprintf(fid,'\tBlock'); end
    
fprintf(fid,'\tChannel\tUnit\tPool\tCount');

params = get_string(h.params)';
for p = params, fprintf(fid,'\t"%s"',char(p)); end
fprintf(fid,'\n');

info = h.DATA.info;

units = fieldnames(unitdata)';
for u = units
    u = char(u); %#ok<FXSET>
    n = max(structfun(@(x) (size(x,1)),unitdata.(u)));
    for i = 1:n
        if isequal(datatype,'All'), fprintf(fid,'\t%d',info.(u).expt); end
        if ismember(datatype,{'All','Experiment'}), fprintf(fid,'\t%d',info.(u).tank); end
        if ismember(datatype,{'All','Experiment','Tank'}), fprintf(fid,'\t%d',info.(u).block); end
        fprintf(fid,'\t%d\t%d\t"%s"\t%d\t', ...
            info.(u).channel,info.(u).id,char(info.(u).pool),info.(u).count);
        for p = params
            p = char(p); %#ok<FXSET>
            if isfield(unitdata.(u),p)
                if ischar(unitdata.(u).(p))
                    if i <= size(unitdata.(u).(p),1)
                        fprintf(fid,'"%s"\t',unitdata.(u).(p)(i,:));
                    else
                        fprintf(fid,' \t');
                    end
                else
                    if i <= length(unitdata.(u).(p))
                        fprintf(fid,'%g\t',unitdata.(u).(p)(i));
                    else
                        fprintf(fid,' \t');
                    end
                end
            else
                fprintf(fid,' \t');
            end
        end
        fprintf(fid,'\n');
    end
end
fprintf(fid,'\nCreated on:\t%s\n',datestr(clock,'dd-mmm-yyyy'));
fclose(fid);

fprintf('File saved as ''%s''\n',file)



function finfo = FormatDatasetInfo(info,sep)
if nargin == 1 || isempty(sep)
    finfo = sprintf('Database:\t%s\n',info.dbname);
    finfo = sprintf('%sExperiment:\t%s\n',finfo,info.expt_name);
    finfo = sprintf('%sSubject:\t%s\n\tAlias\t%s\n',finfo,info.subject_name,info.subject_alias);
    finfo = sprintf('%s\tsex:\t%s\n\tDOB:\t%s\n\tWeight:\t%0.3f\tgrams\n', ...
        finfo,info.sex,info.dob,info.weight);
    finfo = sprintf('%sTank:\t%s\n\tCondition:\t%s\n\tStart Date:\t%s\n\tStart Time:\t%s\n', ...
        finfo,info.tank_name,info.tank_condition,info.tank_date,info.tank_time);
    finfo = sprintf('%sBlock:\t%d\n\tDate:\t%s\n\tTime:\t%s\n', ...
        finfo,info.block,info.block_date,info.block_time);
    finfo = sprintf('%sProtocol:\t%d\n\tAlias:\t%s\n\tName:\t%s\n', ...
        finfo,info.protocol,info.prot_alias,info.prot_name);
else
    finfo = sprintf('Database:%c%s\n',sep,info.dbname);
    finfo = sprintf('%sExperiment:%c%s\n',finfo,sep,info.expt_name);
    finfo = sprintf('%sSubject:%c%s\n%cAlias%c%s\n', ...
        finfo,sep,info.subject_name,sep,sep,info.subject_alias);
    finfo = sprintf('%s%csex:%c%s\n%cDOB:%c%s\n%cWeight:%c%0.3f%cgrams\n', ...
        finfo,sep,info.sex,sep,sep,info.dob,sep,sep,info.weight,sep);
    finfo = sprintf('%sTank:%c%s\n%cCondition:%c%s\n%cStart Date:%c%s\n%cStart Time:%c%s\n', ...
        finfo,sep,info.tank_name,sep,sep,info.tank_condition,sep,sep,info.tank_date,sep,sep,info.tank_time);
    finfo = sprintf('%sBlock:%c%d\n%cDate:%c%s\n%cTime:%c%s\n', ...
        finfo,sep,info.block,sep,sep,info.block_date,sep,sep,info.block_time);
    finfo = sprintf('%sProtocol:%c%d\n%cAlias:%c%s\n%cName:%c%s\n', ...
        finfo,sep,info.protocol,sep,sep,info.prot_alias,sep,sep,info.prot_name);
    
end

function [info,data,groups,params] = GetDBdata(datalevel,blockid)

fprintf('Retrieving Unit Properties from Database ...')
set(findobj('type','figure','-and','tag','DBExportUnitData'),'pointer','watch');
drawnow

ids = mym(['SELECT v.*, b.protocol FROM v_ids v ', ...
           'JOIN blocks b ON b.id = v.block ', ...
           'WHERE v.block = {Si} LIMIT 1'],blockid);


switch datalevel
    case 'All'
        chandata = mym([ ...
            'SELECT v.experiment AS experiment_id, v.tank AS tank_id, ', ...
            'v.block AS block_id, v.channel AS channel_id, v.unit as unit_id, ', ...
            'b.block,t.tank_condition, ', ...
            'c.channel, u.pool, u.unit_count, u.note, u.isbad, u.in_use ', ...
            'FROM v_ids v JOIN channels c ON c.id = v.channel ', ...
            'LEFT OUTER JOIN units u ON u.id = v.unit ', ...
            'JOIN blocks b ON b.id = v.block ', ...
            'JOIN tanks t ON t.id = v.tank ', ...
            'WHERE b.protocol = {Si}'],ids.protocol); 
        
    case 'Experiment'
        chandata = mym([ ...
            'SELECT v.experiment AS experiment_id, v.tank AS tank_id, ', ...
            'v.block AS block_id, v.channel AS channel_id, v.unit as unit_id, ', ...
            'b.block,t.tank_condition, ', ...
            'c.channel, u.pool, u.unit_count, u.note, u.isbad, u.in_use ', ...
            'FROM v_ids v JOIN channels c ON c.id = v.channel ', ...
            'LEFT OUTER JOIN units u ON u.id = v.unit ', ...
            'JOIN blocks b ON b.id = v.block ', ...
            'JOIN tanks t ON t.id = v.tank ', ...
            'WHERE v.experiment = {Si} AND b.protocol = {Si}'], ...
            ids.experiment,ids.protocol);   
        
    case 'Tank'
        chandata = mym([ ...
            'SELECT v.experiment AS experiment_id, v.tank AS tank_id, ', ...
            'v.block AS block_id, v.channel AS channel_id, v.unit as unit_id, ', ...
            'b.block,t.tank_condition, ', ...
            'c.channel, u.pool, u.unit_count, u.note, u.isbad, u.in_use ', ...
            'FROM v_ids v JOIN channels c ON c.id = v.channel ', ...
            'LEFT OUTER JOIN units u ON u.id = v.unit ', ...
            'JOIN blocks b ON b.id = v.block ', ...
            'JOIN tanks t ON t.id = v.tank ', ...            
            'WHERE v.tank = {Si} AND b.protocol = {Si}'],ids.tank,ids.protocol);
        
    case 'Block'
        chandata = mym([ ...
            'SELECT v.experiment AS experiment_id, v.tank AS tank_id, ', ...
            'v.block AS block_id, v.channel AS channel_id, v.unit as unit_id, ', ...
            'b.block,t.tank_condition, ', ...
            'c.channel, u.pool, u.unit_count, u.note, u.isbad, u.in_use ', ...
            'FROM v_ids v JOIN channels c ON c.id = v.channel ', ...
            'LEFT OUTER JOIN units u ON u.id = v.unit ', ...
            'JOIN blocks b ON b.id = v.block ', ...            
            'JOIN tanks t ON t.id = v.tank ', ...            
            'WHERE v.block = {Si}'],ids.block);
end

info = mym(['SELECT e.name AS expt_name, s.name AS subject_name, s.alias AS subject_alias, ', ...
           's.dob, s.sex, s.subject_notes, ', ...
           's.weight, e.start_date AS expt_start_date, e.end_date AS expt_end_date,', ...
           't.tank_condition, t.name AS tank_name, t.tank_date, ', ...
           't.tank_time, t.tank_notes, b.block, b.protocol, b.block_date, b.block_time, b.block_notes, ', ...
           'pt.alias AS prot_alias, pt.name AS prot_name, pt.description AS prot_descr ', ...
           'FROM v_ids v JOIN channels c ON c.id = v.channel ', ...
           'LEFT OUTER JOIN units u ON u.id = v.unit ', ...
           'JOIN experiments e ON e.id = v.experiment ', ...
           'JOIN subjects s ON s.id = e.subject_id ', ...
           'JOIN tanks t ON t.id = v.tank ', ...
           'JOIN blocks b ON b.id = v.block ', ...
           'JOIN db_util.protocol_types pt ON b.protocol = pt.pid ', ...
           'WHERE v.block = {Si} LIMIT 1'],blockid);
info.dbname = myms('SELECT DATABASE()');

for fn = fieldnames(info)'
    fn = char(fn); %#ok<FXSET>
    if iscellstr(info.(fn)), info.(fn) = char(info.(fn)); end
end

% get unit properties
for i = 1:length(chandata.unit_id)
    f = sprintf('unit%d',chandata.unit_id(i));
    data.(f) = DB_GetUnitProps2(chandata.unit_id(i));
end

dfn  = fieldnames(data);
eind = structfun(@isempty,data);
data = rmfield(data,dfn(eind));   
chandata = structfun(@(x) (x(~eind)),chandata,'UniformOutput',false);

ufn = structfun(@fieldnames,data,'uniformoutput',false);
gfn = struct2cell(ufn);
% chandata.unit_id(eind) = [];
for i = 1:length(chandata.unit_id)
    t = mym(['SELECT u.unit_count AS count, p.class AS pool ', ...
        'FROM units u JOIN class_lists.pool_class p ', ...
        'ON u.pool = p.id WHERE u.id = {Si}'],chandata.unit_id(i));
    f = sprintf('unit%d',chandata.unit_id(i));
    info.(f).count = t.count;
    info.(f).pool  = t.pool;
    info.(f).id    = chandata.unit_id(i);
    info.(f).expt  = chandata.experiment_id(i);
    info.(f).tank  = chandata.tank_id(i);
    info.(f).block = chandata.block_id(i);
    info.(f).channel = chandata.channel(i);
end

groups = {''};
for i = 1:length(gfn)
    ind = ~ismember(gfn{i},groups);
    if ~any(ind), continue; end
    groups(end+1:end+sum(ind)) = gfn{i}(ind);
end
groups(1) = [];


for i = 1:length(groups)
    gstr = sprintf([ ...
        'SELECT DISTINCT ap.id,ap.name,ap.units,ap.description ', ...
        'FROM db_util.analysis_params ap ', ...
        'JOIN unit_properties up ON ap.id = up.param_id ', ...
        'WHERE group_id = "%s"'],groups{i});
    params(i) = mym(gstr); %#ok<AGROW>
    [~,idx] = sort(params(i).name);
    params(i) = structfun(@(x) (x(idx)),params(i),'uniformoutput',false); %#ok<AGROW>
end
if ~exist('params','var'), params = []; end

fprintf(' done\n')
set(findobj('type','figure','-and','tag','DBExportUnitData'),'pointer','arrow');




















