function varargout = RF_analysis(varargin)
% RF_analysis
% RF_analysis(unit_id)
%
% Two-dimensional receptive field analysis using features of single or
% multiple contours.
%
% See also, RIF_analysis
% 
% Daniel.Stolzberg@gmail.com 2013


% Last Modified by GUIDE v2.5 06-Sep-2013 10:00:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RF_analysis_OpeningFcn, ...
                   'gui_OutputFcn',  @RF_analysis_OutputFcn, ...
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


% --- Executes just before RF_analysis is made visible.
function RF_analysis_OpeningFcn(hObj, ~, h, varargin)
h.output = hObj;

if length(varargin) == 1
    h.unit_id = varargin{1};
else
    h.unit_id = getpref('DB_BROWSER_SELECTION','units');
end

Check4DBparams;


h.dbdata = DB_GetUnitProps(h.unit_id,'RFid01');


h = InitializeRF(h);

% h = UpdatePlot(h);

guidata(hObj, h);



% --- Outputs from this function are returned to the command line.
function varargout = RF_analysis_OutputFcn(hObj, ~, h)  %#ok<INUSL>
varargout{1} = h.output;

% if ispref('RF_analysis_GUI')
%     pos = getpref('RF_analysis_GUI','windowpos');
%     if ~isempty(pos) && length(pos) == 4
%         set(h.RF_analysis_main,'position',pos);
%     end
% end





function CloseMe(h) %#ok<DEFNU>
% pos = get(h.RF_analysis_main,'Position');
% setpref('RF_analysis_GUI','windowpos',pos);
delete(h.RF_analysis_main);

















%% GUI functions
function h = InitializeRF(h)
P  = DB_GetParams(h.unit_id,'unit');

ind = ~ismember(P.param_type,{'onset','offset','prot'});
set(h.opt_dimx,'String',P.param_type(ind));
set(h.opt_dimy,'String',P.param_type(ind));
set(h.opt_numfields,'String',num2str((0:10)','%d'));

rftypes = DB_GetRFtypes;
rftypes.name{end+1} = '< ADD RF TYPE >';
rftypes.description{end+1} = 'Select a receptive field type from the list or click ''< ADD RF TYPE >''';
set(h.list_rftype,'String',rftypes.name,'Value',1);
SelectRFtype(h.list_rftype,h);

optnames = {'opt_dimx','opt_dimy','opt_xscalelog','opt_threshold', ...
    'opt_smooth2d','opt_interp','opt_cwinon','opt_cwinoff','opt_numfields', ...
    'opt_viewsurf'};
optdefs = {'Freq','Levl',1,'2',1,1,'0','50','1',2};
opts = getpref('RF_analysis_opts',optnames,optdefs);

% replace default options with values from database
T = DB_GetUnitProps(h.unit_id,'rftype');
if ~isempty(T) && isfield(T,'guisettings') && iscell(T.guisettings)
    vals = tokenize(T.guisettings{1},',');
    opts{1} = vals{1};
    opts{2} = vals{2};
    opts{3} = str2num(vals{3}); %#ok<ST2NM>
    opts{4} = vals{8};
    opts{5} = str2num(vals{4}); %#ok<ST2NM>
    opts{6} = str2num(vals{5}); %#ok<ST2NM>
    opts{7} = vals{6};
    opts{8} = vals{7};
    setpref('RF_analysis_opts',optnames,opts);    
end

if isfield(T,'rftype') && iscellstr(T.rftype)
    rftype = char(T.rftype);
else
    rftype = [];
end

for i = 1:length(opts)
    if ~(isfield(h,optnames{i}) && ishandle(h.(optnames{i}))), continue; end
    ho = h.(optnames{i});
    style = get(ho,'Style');
    switch style
        case 'checkbox'
            set(ho,'Value',opts{i});
        case 'popupmenu'
            ind = ismember(cellstr(get(ho,'String')),opts{i});
            if any(ind)
                set(ho,'Value',find(ind));
            else
                set(ho,'Value',1);
            end
        case 'edit'
            set(ho,'String',opts{i});
    end
end


if ~isempty(rftype) && ischar(rftype)
    s = get(h.list_rftype,'String');
    i = ismember(s,rftype);
    if ~any(i), i = 1; end
    set(h.list_rftype,'Value',find(i));
    SelectRFtype(h.list_rftype,h);
end

IDs = mym('SELECT * FROM v_ids WHERE unit = {Si}',h.unit_id);
h.UNIT.IDs         = IDs;
h.UNIT.spiketimes  = DB_GetSpiketimes(h.unit_id);
h.UNIT.blockparams = DB_GetParams(IDs.block);
h.UNIT.unitprops   = DB_GetUnitProps(h.unit_id,'RF$');

h = UpdatePlot(h);

RF_FreqVsTime(h.unit_id);

set(h.updatedb,'Enable','on');



function UpdateOpts(hObj,h) %#ok<DEFNU>
switch get(hObj,'Style')
    case 'checkbox'
        setpref('RF_analysis_opts',get(hObj,'Tag'),get(hObj,'Value'));
    case 'edit'
        setpref('RF_analysis_opts',get(hObj,'Tag'),get(hObj,'String'));
    case 'popupmenu'
        setpref('RF_analysis_opts',get(hObj,'Tag'),get_string(hObj));
end

h = UpdatePlot(h);

guidata(h.RF_analysis_main,h);



















%% Plotting functions
function Cs = UpdateContours(axM,data,RF,nFields,critval)
% critval = RF.spontmean + RF.spontstd * nstd;
if critval == 0, critval = 0.5; end


[C,ch] = contour3(axM,RF.xvals,RF.yvals,data,[critval critval]);
set(ch,'EdgeColor',[0.4 0.4 0.4],'LineWidth',2)

if isempty(C)
    Cs.id = [];
    Cs.contour = [];
    Cs.h = [];
    return
end

Cc = CutContours(C);
m = cellfun(@length,Cc);

% find largest contour(s)
[~,k] = sort(m,'descend');
Cc = Cc(k);
ch = ch(k);
if length(Cc) > nFields
    Cc(nFields+1:end) = [];
    delete(ch(nFields+1:end))
    ch(nFields+1:end) = [];
end

for i = 1:length(Cc)
    Cs(i).id      = i;     %#ok<AGROW>
    Cs(i).contour = Cc{i}; %#ok<AGROW>
    Cs(i).h       = ch(i); %#ok<AGROW>
end

function h = UpdatePlot(h)

h.RFfig = findobj('tag','RF_analysis');
if isempty(h.RFfig)
    h.RFfig = figure('tag','RF_analysis');
else
    ax = findobj(h.RFfig,'tag','MainAxes');
    opt_viewsurf = get(ax,'View');
    setpref('RF_analysis_opts','opt_viewsurf',opt_viewsurf);
end


IDs = h.UNIT.IDs;
st  = h.UNIT.spiketimes;
P   = h.UNIT.blockparams;

opts = getpref('RF_analysis_opts');

dimx = opts.opt_dimx;
dimy = opts.opt_dimy;

win(1) = str2num(get(h.opt_cwinon,'String')); %#ok<ST2NM>
win(2) = str2num(get(h.opt_cwinoff,'String')); %#ok<ST2NM>

[data,vals] = shapedata_spikes(st,P,{dimy,dimx},'binsize',0.001, ...
    'win',win/1000,'func','mean');

data = data * 1000; % rescale data

% estimate spontaneous activity
spnt = shapedata_spikes(st,P,{dimy,dimx},'binsize',0.001, ...
    'win',[-0.01 0],'func','mean');
spnt = spnt * 1000; % rescale spont
spnt = squeeze(mean(spnt));


data = squeeze(mean(data));


Nd = ndims(data);
xdim = Nd;
ydim = Nd - 1;
tdim = Nd - 2;

tvals = vals{1};
yvals = vals{2};
xvals = vals{3};

if opts.opt_smooth2d
    data = [data; repmat(data(end,:),4,1)];
    data = sgsmooth2d(data,10,4);
    data = data(1:end-4,:);
    spnt = sgsmooth2d(spnt,10,4);
end

if opts.opt_interp
    data = interp2(data,3,'cubic');
    spnt = interp2(spnt,3,'cubic');
    xvals = interp1(xvals,linspace(1,length(xvals),size(data,xdim)),'linear');
    if opts.opt_xscalelog
        yvals = interp1(logspace(log10(1),log10(length(yvals)),length(yvals)), ...
            yvals,logspace(log10(1),log10(length(yvals)),size(data,ydim)),'pchip');
    else
        yvals = interp1(yvals,linspace(1,length(yvals),size(data,ydim)),'linear');
    end
else
    % for consistency of dimensions
    xvals = xvals';
    yvals = yvals';
end

data = [zeros(1,length(xvals)); data]; % add some space below plot for contour function
yvals = [yvals(1)-0.1 yvals];

figure(h.RFfig);
clf(h.RFfig);
set(h.RFfig,'Name',sprintf('Unit %d',IDs.unit),'NumberTitle','off', ...
    'HandleVisibility','on','units','normalized')


axM = subplot('Position',[0.1  0.1  0.6  0.6],'Parent',h.RFfig,'NextPlot','Add','Tag','MainAxes');
axX = subplot('Position',[0.1  0.75 0.6  0.1],'Parent',h.RFfig,'NextPlot','Add','Tag','SumX');
axY = subplot('Position',[0.72 0.02  0.2  0.65],'Parent',h.RFfig,'NextPlot','Add','Tag','SumY');
axH = subplot('position',[0.7  0.75 0.25 0.2],'Parent',h.RFfig,'NextPlot','Replace','Tag','Hist');


% Main RF plot
surf(axM,xvals,yvals,data)



% crossection of receptive field
crsX  = mean(data,ydim);
scrsX = mean(spnt,ydim);
plot(axX,xvals,crsX,'-k','linewidth',2)
plot(axX,xvals,scrsX,'-','color',[0.6 0.6 0.6]);

set([axM axX axY],'box','on');
set([axM axY],'xgrid','on','ygrid','on','zgrid','on');
set([axX axY],'FontSize',8);

if ~isempty(opts.opt_viewsurf)
    view(axM,opts.opt_viewsurf);
end
shading(axM,'flat')

set([axM axX],'xlim',[xvals(1) xvals(end)]);
set([axM axY],'ylim',[yvals(1) yvals(end)]);
if any(data(:))
    set(axX,'ylim',[0 max([crsX(:); scrsX(:)])]);
    set(axM,'zlim',[0 max(data(:))]);
else
    set(axX,'ylim',[0 1]);
    set(axM,'zlim',[0 1]);
end

if opts.opt_xscalelog
    set([axM axX],'xscale','log');
else
    set([axM axX],'xscale','linear');
end

set(axX,'xaxislocation','top','yaxislocation','left');
set(axY,'xaxislocation','bottom','yaxislocation','right');

xlabel(axM,dimx);  ylabel(axM,dimy); zlabel(axM,'Firing Rate (Hz)');
ylabel(axY,dimy);
ylabel(axX,'mean');

colorbar('peer',axM,'EastOutside');
c = get(axM,'clim');
set(axM,'clim',[0 c(2)]);

p = get(axM,'Position');
set(axX,'Position',[p(1) 0.75 p(3) 0.1]);

UD.IDs   = IDs;
UD.data  = data;
UD.spnt  = spnt;
UD.spontmean   = mean(spnt(:));
UD.spontmedian = std(spnt(:));
UD.spontstd    = std(spnt(:));
UD.opts  = opts;
UD.tvals = tvals;   UD.tdim  = tdim;
UD.xvals = xvals;   UD.xdim  = xdim;
UD.yvals = yvals;   UD.ydim  = ydim;
UD.nstd = str2num(opts.opt_threshold); %#ok<ST2NM>
UD.nfields = str2num(opts.opt_numfields); %#ok<ST2NM>


set(axM,'UserData',UD);

h.RFax_main = axM;
h.RFax_crsX = axX;
h.RFax_crsY = axY;
h.ax_hist   = axH;

guidata(h.RFfig,h);

RFprocessing(h)

function RFprocessing(h,critval)


axM = h.RFax_main;
axY = h.RFax_crsY;
axH = h.ax_hist;

UD = get(axM,'UserData');

data = UD.data;
spnt = UD.spnt;
xvals = UD.xvals;
yvals = UD.yvals;

if ~exist('critval','var'), critval = []; end

if isempty(critval)
    critval = UD.spontmean + UD.spontstd * UD.nstd;
else
    m = mean(UD.spnt(:));
    s = std(UD.spnt(:));
    z = (critval - m)/s;
    z = round(z*100)/100;
    UD.nstd = z;
    set(h.opt_threshold,'String',num2str(UD.nstd,'%0.2f'));
end

% data histogram
PlotDataHist(axH,data,spnt,critval);


delete(findobj(axM,'type','line','-or','type','patch'))

m = max(data(:));
if m < critval, critval = m*0.99; end
bw = im2bw(data/m,critval/m);
% stats = regionprops(bw,'all');
hold(axM,'on');
Cdata = UpdateContours(axM,bw,UD,UD.nfields,0.5);
hold(axM,'off');

cla(axY);
if ~isempty(Cdata(1).id)
    ccodes = lines(50); ccodes(1,:) = [];
    for i = 1:length(Cdata)
        z = critval * ones(size(get(Cdata(i).h,'zdata')));
        set(Cdata(i).h,'EdgeColor',ccodes(Cdata(i).id,:),'zdata',z);
        Cdata(i).mask     = ContourMask(Cdata(i).contour,xvals,yvals);
        Cdata(i).Features = ResponseFeatures(data,Cdata(i),xvals,yvals);
        PlotFeatures(h,axM,axY,data,Cdata(i),xvals,yvals);
    end
end
UD.Cdata = Cdata;

a = findobj('tag','axMinfo');
if ~isempty(a), delete(a); end

if isempty(Cdata(1).id)
    annotation('textbox',[0.1 0.1 0.9 0.9],'String','NO FIELDS','tag','axMinfo', ...
        'color','R','linestyle','none','fontsize',8);
    
else
    astr = sprintf('BF = %0.1f Hz; CF = %0.1f Hz; MT = %0.1f dB\n', ...
        Cdata(1).Features.bestfreq,Cdata(1).Features.charfreq,Cdata(1).Features.minthresh);
    if isfield(Cdata(1).Features.EXTRAS,'Q10dB')
        astr = sprintf('%sQ10 = %0.1f',astr,Cdata(1).Features.EXTRAS.Q10dB);
    end
    if isfield(Cdata(1).Features.EXTRAS,'Q40dB')
        astr = sprintf('%s; Q40 = %0.1f',astr,Cdata(1).Features.EXTRAS.Q40dB);
    end
    annotation(h.RFfig,'textbox',[0.1 0.9 0.5 0.09],'String',astr,'tag','axMinfo', ...
        'color','k','linestyle','-','fontsize',8,'backgroundcolor','w','hittest','off');
end

set(axM,'UserData',UD);

h.RFax_ch = [Cdata.h];
guidata(axM,h);

function PlotFeatures(h,axM,axY,data,Cdata,xvals,yvals)


if isstruct(h.dbdata) && isfield(h.dbdata,'HighFreq05dB')
    % Use data downloaded from the database
    F = h.dbdata;
    k = 1;
    for i = 5:5:100
        HF = sprintf('HighFreq%02ddB',i);
        if ~isfield(F,HF), break; end
        LF = sprintf('LowFreq%02ddB',i);
        E.bwLf(k) = F.(LF);
        E.bwHf(k) = F.(HF);
        E.BWy(k)  = F.minthresh+i;
        E.Qs(k)   = F.charfreq / E.BWy(k);
        k = k + 1;
    end
    xi = interp1(xvals,xvals,F.charfreq,'nearest');
    E.cfio = data(:,xvals==xi); %*CharFreq IO function
    mdata = nan(size(data));
    mdata(Cdata.mask) = data(Cdata.mask);
    [F.maxrate,bfi] = max(mdata(:));         % max rate
    [bfi,bfj] = ind2sub(size(mdata),bfi);
    F.bestfreq    = xvals(bfj);                   % best frequency
    F.bestlevel   = yvals(bfi);                   % best response level
    E.bfio = data(:,bfj); %*BestFreq IO function
else
    F = Cdata.Features;
    E = F.EXTRAS;
end

hold(axM,'on');

xi = interp1(xvals,xvals,F.charfreq,'nearest');
yi = interp1(yvals,yvals,F.minthresh,'nearest');
dz = data(yi==yvals,xi==xvals);
plot3(axM,F.charfreq,F.minthresh,dz,'^r','linewidth',2,'markersize',10, ...
    'markerfacecolor','r');

dz = data(yvals==F.bestlevel,xvals==F.bestfreq);
plot3(axM,F.bestfreq,F.bestlevel,dz,'d','linewidth',2,'markersize',10, ...
    'color',[0.8 0.8 0.8]);

if ~isempty(E.bwHf)
    dzpk = max(data(:))*ones(2,length(E.BWy));
    dzmn = min(data(:))*ones(2,length(E.BWy));
    plot3(axM,[E.bwLf; E.bwHf],[E.BWy; E.BWy],dzpk,'--ok','linewidth',1, ...
        'MarkerSize',3,'markerfacecolor','k');
    plot3(axM,[E.bwLf; E.bwHf],[E.BWy; E.BWy],dzmn,'--ok','linewidth',1, ...
        'MarkerSize',3,'markerfacecolor','k');
end

hold(axM,'off');

ccodes = lines(50); ccodes(1,:) = []; 
ccode = ccodes(Cdata.id,:);

hold(axY,'on');

ch = [];
if ~isempty(E.Qs)
    ch(1) = plot(axY,E.Qs./max(E.Qs),E.BWy,'-o','markersize',5,'linewidth',1);
end

ch(end+1) = plot(axY,E.bfio./max(E.bfio),yvals,'-d','markersize',3,'linewidth',0.1);
ch(end+1) = plot(axY,E.cfio./max(E.cfio),yvals,'-s','markersize',3,'linewidth',0.1);

set(ch,'markerfacecolor',ccode,'Clipping','off','color','k');
hold(axY,'off');

legstr = {[]};
if ~isempty(E.Qs),   legstr{end+1} = sprintf('Q vals (%0.1f)',max(E.Qs));  end
if ~isempty(E.bfio), legstr{end+1} = sprintf('IO@BF (%0.1f)',max(E.bfio)); end
if ~isempty(E.bfio), legstr{end+1} = sprintf('IO@CF (%0.1f)',max(E.cfio)); end
legstr(1) = [];

set(axY,'xlim',[0 1.1]);

% legend(axY,legstr,'position',[0.73 0.77 0.22 0.12]);
h = legend(axY,legstr,'location','southoutside','fontsize',8);
set(h,'box','off');

function PlotDataHist(ax,data,spont,critval)
cla(ax);
data = data(:);
mspnt = mean(spont(:));
sspnt = std(spont(:)) * 3;
lbs = mspnt - sspnt;
ubs = mspnt + sspnt;
if critval == 0, critval = 0.5; end
[h,b] = hist(data,100);
mh = max(h);
hold(ax,'on');
patch([lbs lbs ubs ubs],[0 mh mh 0],[0.8 0.94 1],'EdgeColor','none');
bar(ax,b,h,'edgecolor','none','facecolor',[0.6 0.6 0.6]);
axis(ax,'tight')
y = ylim(ax);
plot(ax,critval*[1 1],y,'r')
hold(ax,'off');
set(ax,'fontsize',6,'box','on');
ylabel(ax,'Pixel Count','fontsize',6);
xlabel(ax,'Firing Rate','fontsize',6);
title(ax,'Threshold','fontsize',7);
set([ax; get(ax,'children')],'ButtonDownFcn',@AdjustThreshold,'HitTest','on');


function AdjustThreshold(hObj,~)
h = guidata(hObj);
cp = get(h.ax_hist,'CurrentPoint');
thresh = cp(1);
RFprocessing(h,thresh)













%% Analysis functions
function F = ResponseFeatures(data,Cdata,xvals,yvals)
mdata = nan(size(data));
mdata(Cdata.mask) = data(Cdata.mask);

F.minthresh = min(Cdata.contour(2,:));  % minimum threshold
ind = Cdata.contour(2,:) <= F.minthresh + 1; % find mean CF near threshold
if fix(mean(xvals)) == fix(median(xvals)) % linear data
    F.charfreq = mean(Cdata.contour(1,ind)); % CF for linear frequency spacing
else
    F.charfreq = geomean(Cdata.contour(1,ind)); % CF for logarithmic frequency spacing
end
xi = interp1(xvals,xvals,F.charfreq,'nearest');
F.EXTRAS.cfio = data(:,xvals==xi); %*CharFreq IO function

[F.maxrate,bfi] = max(mdata(:));         % max rate
[bfi,bfj] = ind2sub(size(mdata),bfi);
F.bestfreq    = xvals(bfj);                   % best frequency
F.bestlevel   = yvals(bfi);                   % best response level
F.EXTRAS.bfio = data(:,bfj); %*BestFreq IO function

% compute bandwidths at 5dB steps above minimum threshold
bwlevel = F.minthresh+5:5:max(Cdata.contour(2,:));
BWy = interp1(yvals,yvals,bwlevel,'nearest');
Lfbw = []; Hfbw = []; F.EXTRAS.Qs = []; k = [];
for i = 1:length(BWy)
    yind = BWy(i) == yvals;
    if ~any(Cdata.mask(yind,:)) % can happen with a closed receptive field
        k(end+1) = i; %#ok<AGROW>
        continue
    end
    Lfind = find(Cdata.mask(yind,:),1,'first'); Lfbw(i) = xvals(Lfind); %#ok<AGROW>
    Hfind = find(Cdata.mask(yind,:),1,'last');  Hfbw(i) = xvals(Hfind); %#ok<AGROW>
    BW = Hfbw(i) - Lfbw(i);
    Q  = F.charfreq ./ BW;
    F.EXTRAS.(sprintf('BW%02ddB',i*5)) = BW;
    F.EXTRAS.(sprintf('Q%ddB',i*5))    = Q;
    F.EXTRAS.Qs(i) = Q;
end
if ~isempty(k)
    BWy(k)     = [];
    bwlevel(k) = [];
end
F.EXTRAS.BWy     = BWy;
F.EXTRAS.bwLf    = Lfbw;
F.EXTRAS.bwHf    = Hfbw;
F.EXTRAS.bwyvals = bwlevel;


function mask = ContourMask(C,xvals,yvals)
% mask 2D data matrix within the bounds defined by contour C
yi = interp1(yvals,yvals,C(2,:),'nearest');

[~,inflcty] = min(C(2,:));
LfC = C(:,1:inflcty);        Lfyi = yi(1:inflcty);
HfC = C(:,inflcty+1:end);    Hfyi = yi(inflcty+1:end);

if isempty(LfC) || isempty(HfC)
    mask = false(length(yvals),length(xvals));
    return
end

if mean(HfC(1,:)) < mean(LfC(1,:)) % this can happen
    a = HfC;    HfC = LfC;      LfC = a;
    a = Hfyi;   Hfyi = Lfyi;    Lfyi = a;
end

% this can happen with closed receptive fields
if LfC(1,1) > LfC(1,end) &&  HfC(1,1) < HfC(1,end)
    LfC = fliplr(LfC); Lfyi = fliplr(Lfyi);
    HfC = fliplr(HfC); Hfyi = fliplr(Hfyi);
% elseif HfC(1,1) > HfC(1,end)
%     HfC = fliplr(HfC); Hfyi = fliplr(Hfyi); 
end

for i = 2:length(Lfyi)
    if Lfyi(i-1) > Lfyi(i)
        v = Lfyi(i);
    else
        v = Lfyi(i-1);
    end
    Lfyi(i) = v;
end
for i = length(Hfyi)-1:-1:1
    if Hfyi(i+1) > Hfyi(i)
        v = Hfyi(i);
    else
        v = Hfyi(i+1);
    end
    Hfyi(i) = v;
end

mask = true(length(yvals),length(xvals));

for i = 1:size(LfC,2)
    a = Lfyi(i) == yvals;
    mask(a,:) = mask(a,:) & xvals >= LfC(1,i);
end

for i = 1:size(HfC,2)
    a = Hfyi(i) == yvals;
    mask(a,:) = mask(a,:) & xvals <= HfC(1,i);
end

ind = yvals > max([Lfyi Hfyi]) | yvals < min([Lfyi Hfyi]);
mask(ind,:) = false;


function Cs = CutContours(C)
% cut ContourMatrix C into separate contours
Cs = []; 
if isempty(C), return; end
i = 1; k = 1;
n = size(C,2);
while true
    v = C(2,k);
    Cs{i} = C(:,k+1:k+v); %#ok<AGROW>
    % make sure low x-vals come first on contour
    if Cs{i}(1,1) > Cs{i}(1,end)
        Cs{i} = fliplr(Cs{i}); %#ok<AGROW>
    end
    k = k + v + 1;
    if k > n, break; end
    i = i + 1;
end


function ResetDB(~,h) %#ok<DEFNU>

fprintf('Deleting receptive field analysis data for unit id: %d ...',h.unit_id)
mym('DELETE FROM unit_properties WHERE unit_id = {Si} AND group_id REGEXP "RFid*" OR group_id = "rftype"',h.unit_id)
fprintf(' done\n')

h.dbdata = [];

h = InitializeRF(h);

guidata(h.RF_analysis_main,h);


function rftypes = DB_GetRFtypes(addrftype)
persistent checkrftypes

if nargin == 0, addrftype = false; end

if isempty(checkrftypes) || ~checkrftypes
    mym(['CREATE TABLE IF NOT EXISTS class_lists.rf_types (', ...
        'id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,', ...
        'name VARCHAR(45) NOT NULL,', ...
        'description VARCHAR(500) NULL,', ...
        'PRIMARY KEY (id, name),', ...
        'UNIQUE INDEX id_UNIQUE (id ASC),', ...
        'UNIQUE INDEX name_UNIQUE (name ASC))']);
    checkrftypes = true;
end

rftypes = mym('SELECT * FROM class_lists.rf_types');

if isempty(rftypes.name)
    mym(['INSERT class_lists.rf_types (name,description) VALUES ', ...
        '("Bad RF","No clear receptive field")']);
    rftypes = mym('SELECT * FROM class_lists.rf_types');
end

if addrftype
    opts.WindowStyle = 'modal';
    opts.Interpreter = 'none';
    opts.Resize      = 'on';
    
    p = {'Enter Receptive Field Name (<= 45 chars):', ...
        'Enter description of receptive field type (optional; <= 500 chars):'};
    
    a = inputdlg(p,'Add RF Type',[1; 5],{'',''},opts);
    
    if isempty(a) || isempty(a{1}), return; end
    
    if any(strcmpi(a{1},rftypes.name))
        uiwait(helpdlg(sprintf('Receptive Field Type ''%s'' already exists',a{1}),'RF Type'));
        return
    end
    
    mym(['INSERT class_lists.rf_types ', ...
        '(name,description) VALUES ("{S}","{S}")'],a{1},a{2});
    
    fprintf('Added Receptive Field Type: "%s"\n',a{1})
    
    rftypes = mym('SELECT * FROM class_lists.rf_types');
end


function SelectRFtype(hObj,h)
if strcmp(get_string(hObj),'< ADD RF TYPE >')
    rftypes = DB_GetRFtypes(true);
    rftypes.name{end+1} = '< ADD RF TYPE >';
    rftypes.description{end+1} = 'Select a receptive field type from the list or click ''< ADD RF TYPE >''';
    set(hObj,'String',rftypes.name,'Value',length(rftypes.name)-1);
else
    rftypes = DB_GetRFtypes;
end
i = get(hObj,'Value');
set(h.txt_rftypedesc,'String',sprintf('[ID% 3d]\n%s\n',rftypes.id(i),rftypes.description{i}));







%% Database
function Check4DBparams
persistent p_dbchecked

if ~isempty(p_dbchecked) && p_dbchecked, return; end

L = (5:5:100)';
LowFreqN  = strtrim(cellstr(num2str(L(:),'LowFreq%02ddB')))';
HighFreqN = strtrim(cellstr(num2str(L(:),'HighFreq%02ddB')))';

LowFreqD  = strtrim(cellstr(num2str(L(:),'Low frequency border at %d dB above minimum threshold')))';
HighFreqD = strtrim(cellstr(num2str(L(:),'High frequency border at %d dB above minimum threshold')))';

LowFreqU  = repmat({'Hz'},size(LowFreqN));
HighFreqU = repmat({'Hz'},size(HighFreqN));

n = {'bestfreq','charfreq','minthresh','rftype','spontrate','maxrate','bestlevel','numfields', ...
    'guisettings'};
u = {'Hz','Hz','dB',[],'Hz','Hz','dB',[],[]};
d = {'Best Frequency','Characteristic Frequency','Minimum Threshold', ...
'Receptive Field Type','Spontaneous Firing Rate','Maximum Firing Rate in RF', ...
'Best response level','Number of receptive fields','String of GUI settings for analysis'};
n = [n LowFreqN HighFreqN];
d = [d LowFreqD HighFreqD];
u = [u LowFreqU HighFreqU];

try
    DB_CheckAnalysisParams(n,d,u);
    p_dbchecked = true;
catch me
    p_dbchecked = false;
    rethrow(me);
end

function UpdateDB(h) %#ok<DEFNU>
set(h.RF_analysis_main,'Pointer','watch');
set(h.updatedb,'Enable','off');
drawnow

axM = h.RFax_main;

UD = get(axM,'UserData');

if isempty(UD) ||  ~isfield(UD,'Cdata'), return; end

Cdata = UD.Cdata;
if isempty(Cdata(1).id)
    fprintf('No features have been identified for unit %d.\n',h.unit_id)
    set(h.updatedb,'Enable','on');
    set(h.RF_analysis_main,'Pointer','arrow'); drawnow
    return
end

for i = 1:length(Cdata)
    cf = Cdata(i).Features;
    R.identity{i}   = sprintf('RFid%02d',Cdata(i).id);
    R.bestfreq(i)   = cf.bestfreq;
    R.charfreq(i)   = cf.charfreq;
    R.minthresh(i)  = cf.minthresh;
    R.spontrate(i)  = UD.spontmean;
    R.maxrate(i)    = cf.maxrate;
    R.bestlevel(i)  = cf.bestlevel;
    for j = 1:length(cf.EXTRAS.bwLf)
        fn = sprintf('LowFreq%02ddB',j*5);
        R.(fn)(i) = cf.EXTRAS.bwLf(j);
        fn = sprintf('HighFreq%02ddB',j*5);
        R.(fn)(i) = cf.EXTRAS.bwHf(j);
    end
end

DB_UpdateUnitProps(h.unit_id,R,'identity',true);

m = myms(sprintf(['SELECT COUNT(DISTINCT(group_id)) FROM v_unit_props ', ...
        'WHERE group_id REGEXP "RFid*" AND unit_id = %d'],h.unit_id));
for i = length(Cdata)+1:m
    mym('DELETE FROM unit_properties WHERE unit_id = {Si} AND group_id = "{S}"', ...
        h.unit_id,sprintf('RFid%02d',i));
end

T.identity    = 'rftype';
T.rftype      = get_string(h.list_rftype);
T.numfields   = length(Cdata);
T.guisettings = sprintf('%s,%s,%d,%d,%d,%s,%s,%s', ...
    get_string(h.opt_dimx),get_string(h.opt_dimy),...
    get(h.opt_xscalelog,'Value'),get(h.opt_smooth2d,'Value'),get(h.opt_interp,'Value'), ...
    get(h.opt_cwinon,'String'),get(h.opt_cwinoff,'String'),get(h.opt_threshold,'String'));
DB_UpdateUnitProps(h.unit_id,T,'identity',true);


RF_FreqVsTime(h.unit_id);


set(h.updatedb,'Enable','on');
set(h.RF_analysis_main,'Pointer','arrow'); drawnow







function LocatePlotFig %#ok<DEFNU>
f = findobj('tag','RF_analysis','-and','type','figure');
if ~isempty(f), figure(f); end




