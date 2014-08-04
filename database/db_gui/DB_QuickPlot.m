function varargout = DB_QuickPlot(varargin)
% DB_QUICKPLOT MATLAB code for DB_QuickPlot.fig

% Edit the above text to modify the response to help DB_QuickPlot

% Last Modified by GUIDE v2.5 16-May-2013 12:42:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @DB_QuickPlot_OpeningFcn, ...
    'gui_OutputFcn',  @DB_QuickPlot_OutputFcn, ...
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


% --- Executes just before DB_QuickPlot is made visible.
function DB_QuickPlot_OpeningFcn(hObj, ~, h, varargin)
h.output = hObj;

guidata(hObj, h);

RefreshParameters([],h);

% pref = getpref('DB_QuickPlot','opt','opt_spikes');
% if strcmp(pref,'opt_spikes')
%     e.OldValue = h.opt_LFP;
%     e.NewValue = h.opt_spikes;
% else
%     e.OldValue = h.opt_spikes;
%     e.NewValue = h.opt_LFP;
% end
if get(h.opt_spikes,'Value')
    e.OldValue = h.opt_spikes;
    e.NewValue = h.opt_spikes;
else
    e.OldValue = h.opt_LFP;
    e.NewValue = h.opt_LFP;
end
opts_datatype_SelectionChangeFcn([], e, h)



% --- Outputs from this function are returned to the command line.
function varargout = DB_QuickPlot_OutputFcn(hObj, ~, h)  %#ok<INUSL>
varargout{1} = h.output;






















%%
function RefreshParameters(hObj,h) %#ok<INUSL>
if isempty(h), h = guidata(findobj('type','figure','-and','name','DB_QuickPlot')); end

pref = getpref('DB_BROWSER_SELECTION');
if isempty(pref)
    errordlg('DB_Browser malfunctioned')
    return
end

pref = orderfields(pref,{'experiments','tanks','blocks','channels','units'});

dbstr = '';
dbfn = fieldnames(pref);
for i = 1:length(dbfn)
    dbstr = sprintf('%s%s:\t% 6.0f\n',dbstr,dbfn{i}(1:end-1),pref.(dbfn{i}));
end
set(h.txt_dbinfo,'String',dbstr);

P = DB_GetParams(pref.blocks);

if isfield(P,'lists')
    params = fieldnames(P.lists);
    params(strcmp(params,'onset')) = [];
    
    str = cellstr(get_string(h.list_params));
    str = cellfun(@(x)x(1:find(x==' ',1)-1),str,'UniformOutput',false);
%     str(find(str==' ',1,'first'):end) = [];
    val = find(ismember(params,str));
    if isempty(val), val = 1; end
    
    for i = 1:length(params)
        params{i} = sprintf('%s (%d)',params{i},length(P.lists.(params{i})));
    end
    
    set(h.list_params,'String',params,'Value',val)
end

SelectParam(h.list_params,h);
chk_newfigure_Callback(h.chk_newfig,h)

function SelectParam(hObj,h)
val = get(hObj,'Value');

lastval = get(hObj,'UserData');
if ~isempty(lastval) && numel(val) > 1
    ind = val == lastval;
    set(hObj,'UserData',val(~ind))
    val(ind) = [];
    val = [lastval val];
else
    set(hObj,'UserData',val);
end

if numel(val) > 2
    val(end) = [];
    set(hObj,'Value',val);
end

param = cellstr(get(hObj,'String'));
param = param(val);

data = get(h.optTable,'Data');
ncols = data{1,2};
nrows = data{2,2};
    
if length(param) == 1
    idx = find(param{1} == '(' | param{1} == ')');
    n = str2num(param{1}(idx(1):idx(2))); %#ok<ST2NM>
    if ncols*nrows < n
        nrows = round(sqrt(n));
        ncols = ceil(n/nrows);
    end
    set([h.txt_xaxis h.txt_yaxis h.btn_swapxy],'Visible','off');
else
    nrows = 1;
    ncols = 1;
    set([h.txt_xaxis h.txt_yaxis h.btn_swapxy],'Visible','on');
end

data = get(h.optTable,'Data');
data{1,2} = ncols;
data{2,2} = nrows;
set(h.optTable,'Data',data);

pref = getpref('DB_BROWSER_SELECTION');
P = DB_GetParams(pref.blocks);
% list parameters
for i = 1:length(param)
    name{i} = param{i}(1:find(param{i} == ' ')-1); %#ok<AGROW>
    t = num2cell(sort(P.lists.(name{i})));
    pdata(1:length(t),i) = t; %#ok<AGROW>
end
set(h.param_table,'data',pdata,'ColumnName',name);

function SwapXY(h) %#ok<DEFNU>

vals = get(h.list_params,'Value');

if length(vals) == 1, return; end

ud = get(h.list_params,'UserData');
ud = flipud(ud(:));
set(h.list_params,'UserData',ud);

SelectParam(h.list_params,h);



















%% Helper functions
function opts_datatype_SelectionChangeFcn(~, e, h)
hObj = h.optTable;

oldtype = get(e.OldValue,'String');
type    = get(e.NewValue,'String');

setpref('DB_QuickPlot','opt',get(e.NewValue,'tag'));

data  = get(hObj,'Data');
udata = get(hObj,'UserData');
if ~isempty(data{1})
    setpref('DB_QuickPlot',sprintf('optTable_%s',oldtype),{data,udata});
end

prefdata = getpref('DB_QuickPlot',sprintf('optTable_%s',type),[]);


% check to see if things have changed
switch type 
    case 'Spikes'
        CURDATASIZE = 11;
    case 'LFPs'
        CURDATASIZE = 9;
end

if isempty(prefdata) || ~iscell(prefdata) || isempty(prefdata{1}{1}) ...
        || size(prefdata{1},1) ~= CURDATASIZE
    clear data udata
    data{1,1} = '# Columns';            data{1,2} = 4;      udata{1} = 'ncols';
    data{2,1} = '# Rows';               data{2,2} = 5;      udata{2} = 'nrows';
    data{3,1} = 'Window Onset (ms)';    data{3,2} = -10;    udata{3} = 'win_on';
    data{4,1} = 'Window Offset (ms)';   data{4,2} = 200;    udata{4} = 'win_off';
    
    switch type
        case 'Spikes'
            data{end+1,1} = 'Plot Raster';      data{end,2} = true; udata{end+1} = 'plotraster';
            data{end+1,1} = 'Plot Histogram';   data{end,2} = true; udata{end+1} = 'plothist';
            data{end+1,1} = 'Bin size (ms)';    data{end,2} = 1;    udata{end+1} = 'binsize';
            
            
        case 'LFPs'
            data{end+1,1} = 'Error band';    data{end,2} = true;  udata{end+1} = 'errorband';

    end
    data{end+1,1} = 'Color Order';      data{end,2} = 'brgbkcmy';   udata{end+1} = 'colororder';
    data{end+1,1} = '2d smoothing';     data{end,2} = true;         udata{end+1} = 'smooth2d';
    data{end+1,1} = '2d interpolate';   data{end,2} = 3;            udata{end+1} = 'interpolate';
    data{end+1,1} = '2d X is log';      data{end,2} = false;        udata{end+1} = 'xislog';
else
    data  = prefdata{1};
    udata = prefdata{2};
end

set(hObj,'data',data,'UserData',udata);
        
function param_table_CellSelectionCallback(hObj, e, h) %#ok<INUSD,DEFNU>
eI = e.Indices;

data = get(hObj,'Data');

uc = unique(eI(:,2));
for i = 1:length(uc)
    idx = find(eI(:,2) == uc(i));
    t = data(eI(idx,1),uc(i));
    eind = cellfun(@isempty,t,'UniformOutput',true);
    eI(idx(eind),:) = [];
end

set(hObj,'UserData',eI);

function optTable_CellEditCallback(~,~,h) %#ok<DEFNU>
if get(h.opt_spikes,'Value')
    e.OldValue = h.opt_spikes;
    e.NewValue = h.opt_spikes;
else
    e.OldValue = h.opt_LFP;
    e.NewValue = h.opt_LFP;
end
opts_datatype_SelectionChangeFcn(h.opts_datatype,e,h);

function chk_newfigure_Callback(hObj,h)
val = get(hObj,'Value');
if val
    set(h.chk_holdplot,'Visible','off');
else
    set(h.chk_holdplot,'Visible','on');
end















%% Plotting
function PlotData(h) %#ok<DEFNU>
global FIGH
persistent CIDX

if isempty(CIDX); CIDX = 1; end

pref = getpref('DB_BROWSER_SELECTION');

if isempty(pref)
    errordlg('DB_Browser malfunctioned')
    return
end

set(h.figure1,'Pointer','watch'); drawnow

P = DB_GetParams(pref.blocks);

paramsel = get(h.param_table,'UserData');
param    = get(h.param_table,'ColumnName');
if ~isempty(paramsel)
    for i = 1:length(param)
        ind = paramsel(:,2) == i;
        if ~any(ind), continue; end
        P.lists.(param{i}) = P.lists.(param{i})(paramsel(ind,1));
    end
end


% Plot Figure
if get(h.chk_newfig,'Value') || isempty(FIGH) || ~ishandle(FIGH), FIGH = figure; end
figure(FIGH)
set(FIGH,'NumberTitle','off','Renderer','painters','pointer','watch'); 



% CFG structure
data   = get(h.optTable,'Data');
params = get(h.optTable,'UserData');
for i = 1:length(params)
    cfg.(params{i}) = data{i,2};
end
if get(h.chk_holdplot,'Value') && ~get(h.chk_newfig,'Value')
    cfg.hold = 'on';
    CIDX = CIDX + 1;
else
    cfg.hold = 'off';
    CIDX = 1;
    clf(FIGH);
end
tidx = mod(CIDX,length(cfg.colororder));
if tidx == 0, tidx = length(cfg.colororder); end
cfg.color = cfg.colororder(tidx);


drawnow

if get(h.opt_spikes,'Value')
    % get spike data
    S = DB_GetSpiketimes(pref.units);
    
    if numel(param) == 1 || (numel(param) == 2 ...
            && (numel(P.lists.(param{1})) == 1 || numel(P.lists.(param{2})) == 1))
        plot_spike_raster(S,P,param,cfg);
    
    elseif numel(param) == 2
        plot_spike_rf(S,P,param,cfg);
            
    end
    
    % label figure
    n = myms(sprintf([ ...
        'SELECT CONCAT(e.name,": ",t.tank_condition,"-",p.alias,"[",c.target,c.channel,"-",cl.class,"]") ', ...
        'FROM tanks t INNER JOIN experiments e ON t.exp_id = e.id ', ...
        'INNER JOIN blocks b ON b.tank_id = t.id ', ...
        'INNER JOIN db_util.protocol_types p ON b.protocol = p.pid ', ...
        'INNER JOIN channels c ON c.block_id = b.id ', ...
        'INNER JOIN units u ON u.channel_id = c.id ', ...
        'INNER JOIN class_lists.pool_class cl ON cl.id = u.pool ', ...
        'WHERE u.id = %d'],pref.units));

else
    % get continuously sampled data
    W = DB_GetWave(pref.channels);

    switch numel(param)
        case 1
            plot_evLFP(W,P,param,cfg);

        case 2
            plot_LFP_rf(W,P,param,cfg);
    end
    
    % label figure
    n = myms(sprintf([ ...
        'SELECT CONCAT(e.name,": ",t.tank_condition,"-",p.alias,"[",c.target,c.channel,"]") ', ...
        'FROM tanks t INNER JOIN experiments e ON t.exp_id = e.id ', ...
        'INNER JOIN blocks b ON b.tank_id = t.id ', ...
        'INNER JOIN db_util.protocol_types p ON b.protocol = p.pid ', ...
        'INNER JOIN channels c ON c.block_id = b.id ', ...
        'WHERE c.id = %d'],pref.channels));

end

set(FIGH,'name',char(n),'pointer','arrow');
set(h.figure1,'Pointer','arrow');









        
        
        
  
