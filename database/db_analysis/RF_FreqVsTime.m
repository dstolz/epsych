function RF_FreqVsTime(unit_id)
% RF_FreqVsTime
% RF_FreqVsTime(unit_id)
% 
% Visualize receptive field as frequency vs time raster
%
% daniel.stolzberg@gmail.com 2013

if nargin == 0 || isempty(unit_id)
    unit_id = getpref('DB_BROWSER_SELECTION','units');
end

f = findobj('tag','RF_FreqVsTime');
if isempty(f)
f = figure('Color',[0.98 0.98 0.98],'tag','RF_FreqVsTime','toolbar','figure');
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

h.RF.P = DB_GetParams(h.unit_id,'unit');
h.RF.st = DB_GetSpiketimes(h.unit_id);

h.dBprops = DB_GetUnitProps(h.unit_id,'RFid01');

guidata(h.f,h);

h = creategui(h.f);

UpdateFig(h.LevelList,'init',h.f)


function h = creategui(f)
h = guidata(f);

h.f = f;

set(f,'CloseRequestFcn',@CloseMe);

rfwin = [0 50]; % receptive field plot
rwin  = [0 150]; % raster plot

L = h.RF.P.lists.Levl;
level = max(L);

opts = getpref('RF_FreqVsTime',{'rfwin','rwin','level','windowpos','density','subtractmed'}, ...
    {rfwin,rwin,level,[],0,0});

rfwin = opts{1};
rwin  = opts{2};
level = opts{3};

% if ~isempty(opts{4}) && length(opts{4}) == 4
%     set(f,'position',opts{4});
% end

ind = level == L;
if ~any(ind), ind = L == max(L); end
h.LevelList = uicontrol(f,'Style','popup','String',L,'Value',find(ind), ...
    'units','normalized','Position',[0.3 0.86 0.1 0.05], ...
    'Callback',{@UpdateFig,f},'Tag','LevelList');
fbc = get(f,'Color');
uicontrol(f,'Style','text','String','Level (dB):','HorizontalAlignment','right', ...
    'units','normalized','Position',[0.0 0.86 0.29 0.05], ...
    'BackgroundColor',fbc,'FontSize',12);


h.rwin = uicontrol(f,'Style','edit','String',mat2str(rwin), ...
    'units','normalized','Position',[0.3 0.80 0.1 0.05], ...
    'Callback',{@UpdateFig,f},'Tag','rwin');
uicontrol(f,'Style','text','String','Raster Window (ms):','HorizontalAlignment','right', ...
    'units','normalized','Position',[0.0 0.80 0.29 0.05], ...
    'BackgroundColor',fbc,'FontSize',12);


h.rfwin = uicontrol(f,'Style','edit','String',mat2str(rfwin), ...
    'units','normalized','Position',[0.3 0.74 0.1 0.05], ...
    'Callback',{@UpdateFig,f},'Tag','rfwin');
uicontrol(f,'Style','text','String','RF Window (ms):','HorizontalAlignment','right', ...
    'units','normalized','Position',[0.0 0.74 0.29 0.05], ...
    'BackgroundColor',fbc,'FontSize',12);


h.density = uicontrol(f,'Style','checkbox','String','density', ...
    'units','normalized','Position',[0.05 0.68 0.1 0.05], ...
    'Callback',{@UpdateFig,f},'Tag','density','BackgroundColor',fbc, ...
    'Value',opts{5});
h.subtrmed = uicontrol(f,'Style','checkbox','String','subtract median', ...
    'units','normalized','Position',[0.05 0.63 0.15 0.05], ...
    'Callback',{@UpdateFig,f},'Tag','density','BackgroundColor',fbc, ...
    'Value',opts{6});

set(f,'KeyPressFcn',{@clickrf,f})
guidata(f,h);


function CloseMe(hObj,~)
h = guidata(hObj);
% pos = get(h.f,'Position');
% setpref('RF_FreqVsTime','windowpos',pos);
delete(h.f);


function UpdateFig(hObj,event,f) %#ok<INUSL>
h = guidata(f);

s = cellstr(get(h.LevelList,'String'));
level = str2num(s{get(h.LevelList,'Value')}); %#ok<ST2NM>
rwin  = str2num(get(h.rwin,'String')); %#ok<ST2NM>
rfwin = str2num(get(h.rfwin,'String')); %#ok<ST2NM>

% receptive field
subplot(3,5,[4 5],'replace')
[rfdata,rfvals] = shapedata_spikes(h.RF.st,h.RF.P,{'Freq','Levl'}, ...
    'win',rfwin/1000,'binsize',0.001,'func','mean');
plotrf(rfdata*1000,rfvals);
hold on
set(gca,'clipping','off');
x = xlim(gca);
z = zlim(gca);
po = patch([x fliplr(x)],ones(1,4)*level,[z(1) z(1) z(2) z(2)]);
set(po,'zdata',[z(1) z(1) z(2) z(2)],'facecolor','w','facealpha',0.5, ...
    'edgecolor','w','edgealpha',0.5)
plotrffeatures(gca,h.dBprops);
hold off
    


% raster
subplot(3,5,[6 14],'replace')
rast = genrast(h.RF.st,h.RF.P,level,rwin/1000);
if get(h.density,'Value')
    plotdensity(h.RF.P,rast,rwin,rfwin,level,get(h.subtrmed,'value'));
    hold on
    plotrasterfeatures(gca,h.dBprops,level,3);
    c = get(gca,'zlim');
    plot3([0 0],ylim,[1 1]*c(2),'-','color',[0.6 0.6 0.6]);
else
    plotraster(h.RF.P,rast,rwin,rfwin,level);
    hold on
    plotrasterfeatures(gca,h.dBprops,level,2);
    plot([0 0],ylim,'-','color',[0.6 0.6 0.6]);
    hold off
end
box on
xlabel('Time (ms)','FontSize',9);
ylabel('Frequency (kHz)','FontSize',9);
title(sprintf('%d dB',level),'FontSize',14);




% histogram
subplot(3,5,[10 15],'replace');
% rfdata = shapedata_spikes(h.RF.st,h.RF.P,{'Freq','Levl'}, ...
%     'win',[-0.05 0],'binsize',0.001,'func','sum');
% spontrate = mean(rfdata(:));
plothist(rast,h.RF.P.lists.Freq,rfwin);
hold on
plotrasterfeatures(gca,h.dBprops,level,2);
hold off

setpref('RF_FreqVsTime',{'rfwin','rwin','level','density','windowpos','subtractmed'}, ...
    {rfwin,rwin,level,get(h.density,'Value'),get(f,'position'),get(h.subtrmed,'value')});















function plothist(rast,Freq,win)
f = Freq / 1000;
nfreqs = length(f);
nreps = length(rast) / length(f);

win = win / 1000;

trast = cellfun(@(x) (x(x>=win(1) & x < win(2))),rast,'UniformOutput',false);
cnt = cellfun(@numel,trast);
cnt = reshape(cnt,nreps,nfreqs);
h = mean(cnt);
ch = conv(h,gausswin(5),'same');
ch = ch / max(ch) * max(h);

fi  = interp1(1:length(f),f,1:0.2:length(f),'pchip');
if any(isnan(ch))
    ich = zeros(size(fi));
else
    ich = interp1(f,ch,fi,'pchip');
end

plot(ich,fi,'-','linewidth',2,'color',[0.4 0.4 0.4]);
hold on
b = barh(f,h,'hist');
delete(findobj(gca,'marker','*'));
set(b,'facecolor',[0.8 0.94 1],'edgecolor','none');
set(gca,'yscale','log','ylim',[f(1) f(end)],'yaxislocation','right')
% plot([1 1]*spontrate,ylim,'-','color',[0.5 0.5 0.5])
plot([1 1]*median(ch),ylim,'-','color',[0.5 0.5 0.5])
hold off

xlabel('Mean spike count','fontsize',8);

set(gca,'ButtonDownFcn',{@ModifyBorders,gca});






function plotrf(data,vals)
%% Plot Receptive Field
x = vals{2};
y = vals{3};

data = squeeze(mean(data));
data = sgsmooth2d(data);
data = interp2(data,3,'cubic');

ny = length(y);
nx = length(x);
x = interp1(logspace(log10(1),log10(nx),nx),x,logspace(log10(1),log10(nx),size(data,1)),'pchip');
y = interp1(y,linspace(1,ny,size(data,2)),'pchip');

hax = surf(x/1000,y,data');
shading flat
view(2)
axis tight
md = max(data(:));
if isnan(md) || md == 0, md = 1; end
set(gca,'xscale','log','fontsize',7,'zlim',[0 md])
set(hax,'ButtonDownFcn',{@clickrf,gcf});
xlabel('Frequency (kHz)','fontsize',7)
ylabel('Level (dB)','fontsize',7)
h = colorbar('EastOutside','fontsize',7);
c = get(gca,'clim');
set(gca,'clim',[0 c(2)]);
ylabel(h,'Firing Rate (Hz)','fontsize',7)
title(gca,'Receptive Field','fontsize',7);




function clickrf(hObj,event,f) 
h = guidata(hObj);
L = str2num(get(h.LevelList,'String')); %#ok<ST2NM>

if isstruct(event) % Up or Down arrow key press
    curlevel = str2double(get_string(h.LevelList));
    curidx = find(curlevel == L);
    switch event.Key
        case 'uparrow'
            if curidx == length(L), return; end
            curidx = curidx+1;
            
        case 'downarrow'
            if curidx == 1, return; end;
            curidx = curidx-1;
            
        otherwise
            return
            
    end
    level = L(curidx);
    
else
    % RF plot click
    cp = get(gca,'CurrentPoint');
    level = cp(1,2);
end

i = interp1(L,1:length(L),level,'nearest');
if isempty(i) || isnan(i), return; end
set(h.LevelList,'Value',i);
UpdateFig(h.LevelList,'clickrf',f)





function rast = genrast(st,P,level,win)
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
[~,i] = sort(f);
rast = rast(i);





function plotraster(P,rast,win,respwin,level)
rast = cellfun(@(a) (a*1000),rast,'UniformOutput',false); % s -> ms
nreps = sum(P.VALS.Freq == P.lists.Freq(end) & P.VALS.Levl == level);
f = P.lists.Freq / 1000;
f = interp1(1:length(f),f,linspace(1,length(f),length(f)*nreps),'cubic');

minf = min(f);
maxf = max(f);
patch([respwin fliplr(respwin)],[minf minf maxf maxf],[0.8 0.94 1], ...
    'EdgeColor','none');

mcs = gray(nreps+2); mcs(nreps+1:end,:) = [];
mcs = flipud(mcs);
ki = mod(1:length(rast),nreps);
ki(ki == 0) = nreps;

k = 1;
hold on
for i = 1:length(rast)
    if ki(i) == 1, k = 1;  end
    if isempty(rast{i}), continue; end
    line(rast{i},f(i),'marker','s','markersize',2, ...
        'markerfacecolor',mcs(k,:),'color',mcs(k,:));
    k = k + 1;
end
hold off
% set(get(gca,'children'),'markersize',2,'markerfacecolor','k');
set(gca,'yscale','log','ylim',[min(P.lists.Freq) max(P.lists.Freq)]/1000, ...
    'xlim',win,'tickdir','out','ButtonDownFcn',{@ModifyBorders,gca});





function plotdensity(P,rast,win,respwin,level,subtractmed)
rast = cellfun(@(a) (a*1000),rast,'UniformOutput',false); % s -> ms
nreps = sum(P.VALS.Freq == P.lists.Freq(end) & P.VALS.Levl == level);
f = P.lists.Freq / 1000;
f = interp1(1:length(f),f,linspace(1,length(f),length(f)*nreps),'cubic');

binvec = win(1):win(2)-1;

k = 1;
sdata = zeros(length(rast)/nreps,length(binvec));
for i = 1:nreps:length(rast)
    t = cell2mat(rast(i:i+nreps-1));
    sdata(k,:) = hist(t,binvec);
    k = k + 1;
end
sdata = sdata / nreps;
m = max(sdata(:));


gw = gausswin(5) * gausswin(9)';
sdata = conv2(sdata,gw,'same');

if nargin == 6 && subtractmed
    medsdata = median(sdata(:));
    sdata = sdata - medsdata;
end

sdata = sdata / max(sdata(:)) * m;

sh = surf(binvec,P.lists.Freq/1000,sdata);
set(sh,'ButtonDownFcn',{@ModifyBorders,gca});

view(2)
shading interp
UD.data = sdata;
UD.freq = P.lists.Freq;
UD.binvec = binvec;
set(gca,'yscale','log','ylim',[min(P.lists.Freq) max(P.lists.Freq)]/1000, ...
    'xlim',win,'tickdir','out','clipping','off','UserData',UD);
if nargin == 6 && subtractmed && ~any(isnan(sdata(:)))
    set(gca,'clim',[0 max(sdata(:))]);
end
axis tight
box on
hold on
plot3(respwin,[1 1]*max(f),[m m],'-','color',[0.8 0.94 1],'linewidth',7);
hold off
h = colorbar;
set(h,'fontSize',8)



    
function plotrasterfeatures(ax,p,level,dims)
if isempty(p), return; end

x = xlim(ax);

y = 0:5:100;

flevel = round(level - p.minthresh);
flevel = interp1(y,y,flevel,'nearest');
LowFreq  = sprintf('LowFreq%02ddB',flevel);
HighFreq = sprintf('HighFreq%02ddB',flevel);

mlevel = interp1(y,y,p.minthresh,'nearest');
if isnan(mlevel), mlevel = 0; end

set(ax,'clipping','off')

if dims == 3
    c = get(ax,'zlim');
    mv = [1 1] * c(2);
end

fn = fieldnames(p)';
for f = fn
    f = char(f); %#ok<FXSET>
    switch f
        case 'bestfreq'
        
        case 'charfreq'
            if level < mlevel, continue; end
            if dims == 2
                plot(ax,x,[1 1]*p.charfreq/1000,':r');
                plot(ax,x(1),p.charfreq/1000,'>r','markerfacecolor','r');
                plot(ax,x(2),p.charfreq/1000,'<r','markerfacecolor','r');
            elseif dims == 3
                plot3(ax,x,[1 1]*p.charfreq/1000,mv,':r');
                plot3(ax,x(1),p.charfreq/1000,mv,'>r','markerfacecolor','r');
                plot3(ax,x(2),p.charfreq/1000,mv,'<r','markerfacecolor','r');
            end
            
        case LowFreq
            if dims == 2
                plot(ax,x,[1 1]*p.(f)/1000,'-^','color',[0.57 0.57 0.98], ...
                    'markerfacecolor',[0.57 0.57 0.98]);
            elseif dims == 3
                plot3(ax,x,[1 1]*p.(f)/1000,mv,'-^','color',[0.57 0.57 0.98], ...
                    'markerfacecolor',[0.57 0.57 0.98]);
            end
            
            
        case HighFreq
            if dims == 2
                plot(ax,x,[1 1]*p.(f)/1000,'-v','color',[0.98 0.57 0.57], ...
                    'markerfacecolor',[0.98 0.57 0.57]);
            elseif dims == 3
                plot3(ax,x,[1 1]*p.(f)/1000,mv,'-v','color',[0.98 0.57 0.57], ...
                    'markerfacecolor',[0.98 0.57 0.57]);
            end

    end    
end

set(ax,'ButtonDownFcn',{@ModifyBorders,ax});

function ModifyBorders(~,~,ax)
h = guidata(gcf);

lvl = str2double(get_string(h.LevelList));
mt  = h.dBprops.minthresh;

if lvl < mt, return; end

levls = 0:5:100;
dBidx = nearest(levls,lvl-mt);
dB = levls(dBidx);

cp = get(ax,'CurrentPoint');
y = cp(1,2);
freqs = h.RF.P.lists.Freq;

yidx = nearest(freqs/1000,y);
newf = freqs(yidx);

if dB == 0 % adjust characteristic frequency
    upProp.charfreq = newf;
    
else % adjust contour borders
    LF = sprintf('LowFreq%02ddB',dB);
    HF = sprintf('HighFreq%02ddB',dB);
    
    if isfield(h.dBprops,LF) && isfield(h.dBprops,HF)
        i = nearest(log2([h.dBprops.(LF) h.dBprops.(HF)]),log2(newf));
    else
        i = 1;
        if newf >= h.dBprops.charfreq
            i = 2;
        end
    end
    
    if i == 1
        h.dBprops.(LF) = newf;
        upProp.(LF) = newf;
    else
        h.dBprops.(HF) = newf;
        upProp.(HF) = newf;
    end
end

guidata(gcf,h);

UpdateFig([],[],gcf);

upProp.identity = {'RFid01'};

try
    DB_UpdateUnitProps(h.unit_id,upProp,'identity',true);
    
    RF_analysis(h.unit_id);
catch me
    if ~ismember(me.identifier,{'MATLAB:class:InvalidHandle','MATLAB:nonExistentField','MATLAB:UndefinedFunction'})
        rethrow(me);
    end
end
    

function plotrffeatures(ax,p)
if isempty(p), return; end

set(ax,'clipping','off')

z = get(ax,'zlim');

if ~all(isfield(p,{'charfreq','minthresh'})), return; end

plot3(ax,[1 1]*p.charfreq/1000,[1 1]*round(p.minthresh),z,'^-r', ...
    'markerfacecolor','r','markersize',4);






    
    
    
    
    
    
    
    
    
    
    

