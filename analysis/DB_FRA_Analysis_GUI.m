function f = DB_FRA_Analysis_GUI(a,~,c)
if nargin == 0 || (nargin == 3 && isempty(c))
    unit_id = getpref('DB_BROWSER_SELECTION','units');
end

if nargin == 1 && ~isempty(a)
    unit_id = a;
end

if nargin == 3 && ~isempty(c)
    unit_id = c;
end

h = DrawGUI;

h.unit_id = unit_id;

h.spiketimes = DB_GetSpiketimes(unit_id);
h.params     = DB_GetParams(unit_id,'unit');

guidata(h.fig,h);

UpdateAnalysis;

f = h.fig;

n = {'conflevel','charfreq','minthresh','monoindex','spontrate','threshold', ...
    'bestfreq','bwoctaves','lowfreq','highfreq','dprime','is_good'};
d = {'Confidence level', 'Characteristic frequency','Minimum threshold', ...
    'Monotonicity index','Spontaneous firing rate','Threshold',...
    'Best frequency','Bandwidth in octaves','Low frequency border', ...
    'High frequency border','d-prime selectivity index','Is good quality'};
u = {[],'Hz','dB',[],'Hz',[],'Hz','octaves','Hz','Hz',[],[]};

DB_CheckAnalysisParams(n,d,u);




function h = DrawGUI
f = findobj('type','figure','-and','name','FRA_main');
if isempty(f)
    f = figure('name','FRA_main','units','normalized','color','w', ...
        'position',[0.40 0.65 0.35 0.15],'menubar','none'); 
end
figure(f);
clf

p = getpref('FRA_ANALYSIS',{'conflevel','awin','smoothdata'},{0.95,[0 0.05],1});

uicontrol('parent',f,'style','text','units','normalized', ...
    'String','Confidence Level:','position',[0.01 0.80 0.25 0.15], ...
    'backgroundcolor','w','fontsize',10);

uicontrol('parent',f,'style','pushbutton','units','normalized', ...
    'String','Recalc','Position',[0.4 0.80 0.15 0.15],'tag','recalc', ...
    'fontsize',12,'callback',@UpdateAnalysis);

uicontrol('parent',f,'style','text','units','normalized', ...
    'String','Analysis Window (s):','Position',[0.01 0.65 0.25 0.15], ...
    'fontsize',10);

uicontrol('parent',f,'style','pushbutton','units','normalized', ...
    'String','Update DB','position',[0.7 0.2 0.25 0.25],'tag','updatedb', ...
    'fontsize',14,'callback',@UpdateDB);

uicontrol('parent',f,'style','pushbutton','units','normalized', ...
    'String','Bad Unit','Position',[0.75 0.05 0.15 0.13],'tag','badunit', ...
    'fontsize',8,'callback',@BadUnit);



h.opt.confleveledit = uicontrol('parent',f,'style','edit','units','normalized', ...
    'String',p{1},'position',[0.25 0.82 0.10 0.12],'tag','confleveledit', ...
    'fontsize',12,'callback',@UpdateAnalysis);

h.opt.analysiswin = uicontrol('parent',f,'style','edit','units','normalized', ...
    'String',mat2str(p{2}),'Position',[0.25 0.69 0.10 0.12],'fontsize',10, ...
    'callback',@UpdateAnalysis);

h.opt.smoothdata = uicontrol('parent',f,'style','checkbox','units','normalized', ...
    'String','smooth','Position',[0.36 0.69 0.15 0.10],'fontsize',8, ...
    'value',p{3},'callback',@UpdateAnalysis);



h.distax = axes('parent',f,'units','normalized','position',[0.08 0.18 0.4 0.35]);





h.fig = f;

function BadUnit(~,~)
h = GetMainH;
S.group_id  = 'FRA';
S.conflevel = str2num(get(h.opt.confleveledit,'String')); %#ok<ST2NM>
S.is_good = false;
DB_UpdateUnitProps(h.unit_id,S,'group_id',true);
mym('UPDATE units SET in_use = 0 WHERE id = {Si}',h.unit_id);


function UpdateDB(~,~)
[h,mainf] = GetMainH;
set(mainf,'Pointer','watch'); drawnow

S.group_id  = 'FRA';
if ~isfield(h,'data') % no significant data
    S.conflevel = str2num(get(h.opt.confleveledit,'String')); %#ok<ST2NM>
    S.is_good = false;
    DB_UpdateUnitProps(h.unit_id,S,'group_id',true);
    return 
else
    S.is_good = true;
end

S.charfreq  = h.data.CF;
S.minthresh = h.data.MT;
S.monoindex = h.data.MI;
S.spontrate = h.data.spontrate;
S.threshold = h.data.thresh;
DB_UpdateUnitProps(h.unit_id,S,'group_id',true);

P.group_id = 'FRApeak';
P.monoindex = h.data.MIpk;
DB_UpdateUnitProps(h.unit_id,P,'group_id',true);

vidx = find(~isnan(h.data.BF));
V.bestfreq = h.data.BF(vidx);
V.bwoctaves = h.data.BWsm(vidx);
V.lowfreq  = h.data.highlowf(vidx,1);
V.highfreq = h.data.highlowf(vidx,2);
V.dprime   = h.data.Dp(vidx);
V.peakdprime = h.data.Dppk(vidx);
for i = 1:length(vidx)
    V.Levels{i,1} = sprintf('FRA_%03ddB',h.data.y(vidx(i)));
    K.Levels{i,1} = sprintf('FRApeak_%03ddB',h.data.y(vidx(i)));
end
DB_UpdateUnitProps(h.unit_id,V,'Levels',true);

K.dprime = h.data.Dppk(vidx);
DB_UpdateUnitProps(h.unit_id,K,'Levels',true);





set(mainf,'Pointer','arrow'); drawnow

function UpdateAnalysis(a,~)
[h,mainf] = GetMainH;
set(mainf,'Pointer','watch'); drawnow

h.conflevel  = str2double(get(h.opt.confleveledit,'String'));
h.smoothdata = get(h.opt.smoothdata,'Value');
h.awin       = str2num(get(h.opt.analysiswin,'String')); %#ok<ST2NM>

setpref('FRA_ANALYSIS',{'conflevel','awin','smoothdata'},{h.conflevel,h.awin,h.smoothdata});

miny = [];
if nargin>0 && ~strcmp(get(a,'type'),'uicontrol')
    cp = get(get(a,'parent'),'currentPoint');
    miny = cp(1,2);
end

out = FRA_Analysis(h.spiketimes,h.params,'conflevel',h.conflevel, ...
    'window',h.awin,'miny',miny,'smoothdata',h.smoothdata);

if ~isfield(out,'BF') % no significant response
    return
end

h.data = out;

set(get(h.data.FRAax,'children'),'ButtonDownFcn',@UpdateAnalysis);

guidata(h.fig,h);

PlotDistributions(h);
PlotTemporalResponse;

set(mainf,'Pointer','arrow'); drawnow

function PlotDistributions(h)
[sh,sbins] = hist(h.data.spont,50);
bar(h.distax,sbins,sh,1,'k');

hold(h.distax,'on');
[dh,dbins] = hist(h.data.FRA(:),50);
plot(h.distax,dbins,dh,'-c','linewidth',1)
plot(h.distax,[1 1]*h.data.thresh,ylim(h.distax),'-r')
xlabel(h.distax,'Firing Rate (Hz)','fontsize',6);
ylabel(h.distax,'Pixel Count','fontsize',6);
hold(h.distax,'off');
set(h.distax,'fontsize',6);
axis(h.distax,'tight');



function PlotTemporalResponse(~,~)
f = findobj('type','figure','-and','name','FRA_temp');
if isempty(f)
    f = figure('name','FRA_temp','units','normalized','color','w', ...
        'menubar','figure'); 
end
figure(f);

[h,mainf] = GetMainH;

hlevel = findobj(f,'tag','hlevel');

if isempty(hlevel)
    hlevel = uicontrol('parent',f,'style','listbox', ...
        'String',sort(h.data.y,'descend'),'value',1, ...
        'Units','normalized','position',[0.01 0.2 0.1 0.70], ...
        'FontSize',10, ...
        'Callback',@PlotTemporalResponse,'tag','hlevel');
end

Level = str2num(get_string(hlevel)); %#ok<ST2NM>

h.temprfax = gca;

set(h.temprfax,'position',[0.22 0.11 0.64 0.815])

[rast,vals] = genrast(h.spiketimes,h.params,Level,[-0.05 0.25]);

D = PlotDensity(rast,vals,'ax',h.temprfax,'smoothing',true,'bins',-0.05:0.001:0.25);
xlabel(h.temprfax,'Time (s)');
ylabel(h.temprfax,'Frequency (Hz)');
zlabel(h.temprfax,'Firing Rate (Hz)');
title(h.temprfax,sprintf('Temporal Response at % 3.1f',Level))

ch = colorbar;
ylabel(ch,'Firing Rate (Hz)');
mv = max(D(:));
hold(h.temprfax,'on');

ind = h.data.y==Level;

plot3(h.temprfax,[0 0],ylim,mv*[1 1],':w');
plot3(h.temprfax,xlim'*[1 1],[1; 1]*h.data.highlowf(ind,:),mv*[1 1; 1 1],':w','linewidth',2);
plot3(h.temprfax,xlim'*[1 1],h.data.highlowf(ind,1)*[1 1],mv*[1 1],'^k', ...
    'markerfacecolor','k','linewidth',2);
plot3(h.temprfax,xlim'*[1 1],h.data.highlowf(ind,2)*[1 1],mv*[1 1],'vk', ...
    'markerfacecolor','k','linewidth',2);

BF   = h.data.BF;
BWsm = h.data.BWsm;
y = [BF(ind).*2.^(-BWsm(ind)) BF(ind).*2.^(BWsm(ind))];
plot3(h.temprfax,[0 0],BF(ind)*2.^([-0.25 0.25]),mv*[1 1],'color',[0.6 0.6 0.6], ...
    'linewidth',5);
plot3(h.temprfax,[0 0],y,mv*[1 1],'-k','linewidth',2);
plot3(h.temprfax,0,h.data.BF(ind),mv,'ko','markersize',10, ...
    'linewidth',2)



if Level == h.data.MT;
    plot3(h.temprfax,0,h.data.CF,mv,'ok','markersize',10, ...
        'linewidth',2,'markerfacecolor','w');
end
hold(h.temprfax,'off');


set(get(h.temprfax,'children'),'ButtonDownFcn',@AdjustHighLowF);

guidata(mainf,h);




function AdjustHighLowF(~,~)
[h,mainf] = GetMainH;

cp = get(h.temprfax,'CurrentPoint');

Level = str2num(get_string(findobj('tag','hlevel'))); %#ok<ST2NM>


BF = h.data.BF;
Y  = h.data.y;
X  = h.data.x;


ind = Y == Level;

% if isnan(h.data.highlowf(ind,1)....

nidx = nearest(X,cp(1,2));
newf = X(nidx);

if newf < BF(ind)
    h.data.highlowf(ind,1) = newf;
else
    h.data.highlowf(ind,2) = newf;
end

guidata(mainf,h);

PlotTemporalResponse;

% manually adjust high/low frequencies on FRA plot
a = findobj(h.data.FRAax,'type','line','-and','color','w');
x1 = get(a(1),'XData');
x2 = get(a(2),'XData');

if all(x1>x2)
    b = a(2);
    a(2) = a(1);
    a(1) = b;
end

set(a(1),'xdata',h.data.highlowf(~isnan(h.data.highlowf(:,1)),1));
set(a(2),'xdata',h.data.highlowf(~isnan(h.data.highlowf(:,2)),2));





function [rast,f] = genrast(st,P,level,win)
ind  = P.VALS.Levl == level;
ons  = P.VALS.onset(ind);
wons = ons + win(1);
wofs = ons + win(2);
rast = cell(size(ons));
for i = 1:length(ons)
    sind = st >= wons(i) & st <= wofs(i);
    rast{i} = st(sind) - ons(i);
end
f = P.VALS.Freq(ind);
[f,i] = sort(f);
rast = rast(i);



function [h,mainf] = GetMainH
mainf = findobj('type','figure','-and','name','FRA_main');
h = guidata(mainf);







