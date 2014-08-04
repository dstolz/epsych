function plot_TSlew(unit_id)
% plot_TSlew(unit_id)
% 
% Plot and analyze temporal slewing experiment
% 
% Daniel.Stolzberg@gmail.com 2014


if nargin == 0 || isempty(unit_id)
    unit_id = getpref('DB_BROWSER_SELECTION','units');
end

f = findobj('tag','plot_TSlew');
if isempty(f)
f = figure('Color',[0.98 0.98 0.98],'tag','plot_TSlew','toolbar','figure');
end

h.unit_id = unit_id;
h.f  = f;
guidata(h.f,h);

h = init([],[],f);
guidata(h.f,h);


function h = init(~,~,f)
h = guidata(f);
figure(h.f);
clf(h.f);
set(h.f,'Name',sprintf('Unit ID: %d',h.unit_id),'units','normalized');

h.DATA.P  = DB_GetParams(h.unit_id,'unit');
h.DATA.st = DB_GetSpiketimes(h.unit_id);

guidata(h.f,h);

h = creategui(h.f);

UpdateFig([],'init',h.f)


function h = creategui(f)
h = guidata(f);

h.f = f;

set(f,'CloseRequestFcn',@CloseMe,'Units','normalized');

fbc = get(f,'Color');

h.ax_raster = subplot('Position',[0.1  0.1 0.8 0.5]);
h.ax_inout  = subplot('Position',[0.5  0.65 0.45 0.25]);


opts = getpref('plot_TSlew',{'vwin','awin','windowpos','density'}, ...
    {[0 700],[0 50],get(f,'Position'),0});

vwin = opts{1};
awin = opts{2};

h.vwin = uicontrol(f,'Style','edit','String',mat2str(vwin), ...
    'units','normalized','Position',[0.3 0.84 0.1 0.05], ...
    'Callback',{@UpdateFig,f},'Tag','vwin');
uicontrol(f,'Style','text','String','View Window (ms):', ...
    'HorizontalAlignment','right', ...
    'units','normalized','Position',[0.0 0.84 0.29 0.05], ...
    'BackgroundColor',fbc,'FontSize',11);

h.awin = uicontrol(f,'Style','edit','String',mat2str(awin), ...
    'units','normalized','Position',[0.3 0.77 0.1 0.05], ...
    'Callback',{@UpdateFig,f},'Tag','awin');
uicontrol(f,'Style','text','String','Analysis Window (ms):', ...
    'HorizontalAlignment','right', ...
    'units','normalized','Position',[0.0 0.77 0.29 0.05], ...
    'BackgroundColor',fbc,'FontSize',11);

h.density = uicontrol(f,'Style','checkbox','String','density', ...
    'units','normalized','Position',[0.15 0.61 0.1 0.05], ...
    'Callback',{@UpdateFig,f},'Tag','density','BackgroundColor',fbc, ...
    'Value',opts{4});


colormap(flipud(gray));

guidata(f,h);



function UpdateFig(hObj,e,f) %#ok<INUSL>
h = guidata(f);

vwin = str2num(get(h.vwin,'String')); %#ok<ST2NM>
awin = str2num(get(h.awin,'String')); %#ok<ST2NM>


P = h.DATA.P;

% parameter automatically selected from data
params = P.param_type;
params(ismember(params,{'onset','offset'})) = [];
n = cellfun(@(x) (length(P.lists.(x))),params);
[~,i] = max(n);
param = params{i};

[rast,vals] = GenerateRaster(h.DATA.st,P.VALS.(param),P.lists.onset,vwin/1000);
rast = cellfun(@(a) (a*1000),rast,'UniformOutput',false); % s -> ms

% Plot raster
cla(h.ax_raster);
if get(h.density,'Value')
    PlotDensity(rast,vals,'ax',h.ax_raster,'bins',vwin(1):vwin(2)-1, ...
        'smoothing',true);
else
    PlotRaster(h.ax_raster,rast,vals);
    grid(h.ax_raster,'off');
    set(h.ax_raster,'xlim',vwin);
end
ylabel(h.ax_raster,param,'fontsize',10);
xlabel(h.ax_raster,'time (ms)','fontsize',10);
box(h.ax_raster,'on');

% Plot analysis windows
hold(h.ax_raster,'on')
plotawins(h.ax_raster,awin,unique(vals));
hold(h.ax_raster,'off')

% Analyze windows
A = analyzewins(rast,vals,awin,1);
cla(h.ax_inout);
[ax,m,p] = plotyy(A.vals,A.mean,A.vals,A.peak);
set(m,'Marker','s','MarkerSize',5,'Color',[0.5 0.5 0.5],'LineStyle','-');
set(p,'Marker','o','MarkerSize',5,'Color','r','LineStyle','-');
set(ax(1),'ycolor','k');
set(ax(2),'ycolor','r');

setpref('plot_TSlew',{'vwin','awin','windowpos','density'}, ...
    {vwin,awin,get(h.f,'position'),get(h.density,'Value')});




function A = analyzewins(rast,vals,awin,binsize)

bins = awin(1):binsize:awin(2)-binsize;

uvals = unique(vals);
nvals = length(uvals);
h = zeros(length(bins),nvals);
for i = 1:nvals
    ind = vals == uvals(i);
    t = cell2mat(rast(ind));
    t = t - uvals(i);   
    h(:,i) = histc(t,bins);
end
A.mean = mean(h);
[A.peak,A.peaklat] = max(h);
A.vals = uvals;


function plotawins(ax,awin,del)
set(ax,'clipping','off');
for d = del(:)'
    plot(ax,d+awin,[1 1]*d,'-r');
end








function [rast,vals] = GenerateRaster(st,vals,ons,win)
wons = ons + win(1);
wofs = ons + win(2);
rast = cell(size(ons));
for i = 1:length(ons)
    sind = st >= wons(i) & st <= wofs(i);
    rast{i} = st(sind) - ons(i);
end
[vals,i] = sort(vals);
rast = rast(i);







function PlotHist







function CloseMe(hObj,~)
h = guidata(hObj);
pos = get(h.f,'Position');
setpref('plot_TSlew','windowpos',pos);
delete(h.f);

