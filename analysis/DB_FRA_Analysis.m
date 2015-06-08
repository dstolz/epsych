function out = DB_FRA_Analysis(unit_id,varargin)
% DB_FRA_Analysis;              % if using with DB_Browser
% DB_FRA_Analysis(unit_id);     % must already be connected to a database
% DB_FRA_Analysis(unit_id,'param',value);
% out = DB_FRA_Analysis(...);
%
% Characterizes receptive field using the centroid method outlined in
% Escabi et al, 2007 Neuroscience 150:970-983.  Additional parameters are
% analyzed as well.  A Rate-Level Curve is also generated from the
% receptive field data.
%
%
% Note: all parameters are optional.
% Parameter     ... Default Value
% 'window'      ... [0 0.05]    % Analysis window relative to
%                                 stimulus onset (seconds)
% 'spontwindow' ... [-0.05 0]   % Window for analyzing spontaneous
%                                 firing rate for thresholding (seconds)
% 'conflevel'   ... 0.975       % Confidence level around mean
%                                 spontaneous firing rate to find
%                                 significant responses. Assumes Poisson
%                                 distribution.
% 'plotFRA'     ... true        % Plot FRA and results of analysis.
% 'plotRLC'     ... true        % Plot RLC analysis.
% 'FRAax'       ... []          % Handle to axis to plot FRA data.
% 'RLCax'       ... []          % Handle to axis to plot RLC data.
% 'paramx'      ... 'Freq'      % X-axis parameter on database. Case sensitive
% 'paramy'      ... 'Levl'      % Y-axis parameter on database. Case sensitive
% 'smoothdata'  ... true        % Uses SGSMOOTH2D function to smooth
%                                 receptive field before anlaysis.
% 'subtractspont' ... true      % Subtract mean spontaneous firing rate
%                                 from receptive field before analysis.
%
% Daniel.Stolzberg@gmail.com 2014

% Set Defaults
win         = [0 0.05];
swin        = [-0.05 0];
cl          = 0.975;
plotFRA     = true;
plotRLC     = true;
FRAax       = [];
RLCax       = [];
paramx      = 'Freq';
paramy      = 'Levl';
smoothdata  = true;
subtractspont = true;

% Parse varargin
ParseVarargin({'window','spontwindow','threshold','plotFRA','plotRLC','FRAax', ...
    'RLCax','paramx','paramy','smoothdata','subtractspont','conflevel'}, ...
    {'win','swin','thresh','plotFRA','plotRLC','FRAax','RLCax','paramx','paramy', ...
    'smoothdata','subtractspont','cl'},varargin)

% Retrieve data from database
if nargin == 0 || isempty(unit_id)
    unit_id = getpref('DB_BROWSER_SELECTION','units');
end
st = DB_GetSpiketimes(unit_id);
P  = DB_GetParams(unit_id,'unit');

% Make FRA
[data,vals] = shapedata_spikes(st,P,{paramx,paramy},'win',win,'binsize',0.001);
data = data / 0.001;

Freqs  = vals{2};
Levels = vals{3};
bins   = vals{1};

FRA = squeeze(mean(data))';
if smoothdata
    FRA = sgsmooth2d(FRA);
end

% Threshold
spont = shapedata_spikes(st,P,{'Freq','Levl'},'win',swin,'binsize',0.001);
spont = squeeze(mean(spont))'/0.001;
spont = spont(:);

x = 0:0.1:max(spont);
mspont = mean(spont);
pcdf = poisscdf(x,mspont);

p = polyfit(pcdf,x,3);
thresh = polyval(p,cl);

sig_ind = FRA >= thresh;

if ~any(sig_ind(:))
    fprintf(2,'No significant responses found at confidence level %0.3f\n',cl) %#ok<PRTCAL>
    out.FRAax = PlotRF(FRAax,Freqs,Levels,FRA);
    return
end

if subtractspont
    data = data - mspont;
    FRA  = FRA - mspont;
    spont = spont - mspont;
end

% Find centroid of thresholded data at each sound level (Escabi et al, 2007)
Xm = nan(size(FRA,1),1);
sm = nan(size(FRA,1),1);
hl = nan(size(FRA,1),2);
fr = min(Freqs); % reference frequency (minimum frequency presented)
for i = 1:size(FRA,1)
    k = sig_ind(i,:);
    if sum(k) < 4, continue; end
    
    fk = Freqs(k)';
    Xk = log2(fk./fr);
    
    Xm(i) = sum(Xk.*FRA(i,k))./sum(FRA(i,k)); % centroid
    sm(i) = sqrt(sum((Xk-Xm(i)).^2.*FRA(i,k))./sum(FRA(i,k))); % second order moment
    
    bw = bwlabel(k);
    ul = unique(bw);
    ul(~ul) = [];
    [~,j] = max(arrayfun(@(x) (sum(bw==x)),ul));
    flow = find(bw==ul(j),1,'first');
    fhigh = find(bw==ul(j),1,'last');
    hl(i,:) = Freqs([flow fhigh]); % high and low frequency borders
    
end

% Best frequency at each sound level above MT
BF = fr * 2 .^ Xm;

% Bandwidths in octaves
BWsm = 2 * sm;
BWhl = log2(hl(:,2)./hl(:,1));

nnind = ~isnan(BF);

MT = min(Levels(nnind)); % Minimum threshold
CF = BF(find(nnind,1));   % Characteristic frequency

% Plot FRA and tuning
if plotFRA
    if all(isnan(BF))
        fprintf(2,'No significant responses found at confidence level %0.3f\n',cl) %#ok<PRTCAL>
        out.FRAax = PlotRF(FRAax,Freqs,Levels,FRA);
        return
    else
        FRAax = PlotRF(FRAax,Freqs,Levels,FRA,BF,CF,MT,hl,sm);
    end
end

% Rate-Level Curve (RLC) from FRA (Escabi et al, 2007)
oct_range = 0.5; % octave range around estimated BF


BFt = BF;
BFt(~nnind) = CF;

r = BFt*2.^([-oct_range oct_range]/2);

r(r>max(Freqs)) = max(Freqs);
r(r<min(Freqs)) = min(Freqs);

ri = interp1(Freqs,1:length(Freqs),r,'nearest');

RLCm = zeros(size(Levels));
RLCvar = zeros(size(Levels));
n    = zeros(size(Levels));
for i = 1:size(ri,1)
    idx = ri(i,1):ri(i,2);
    RLCm(i) = mean(FRA(i,idx));
    t = mean(data(:,idx,i),2);
    n(i) = numel(t);
    RLCvar(i) = var(t);
end

% normalize RLC by computing D' at each sound level
[RLCmax,RLCmaxi] = max(RLCm);

Dp = (RLCm - RLCmax) ./ sqrt(RLCvar(RLCmaxi)+RLCvar);

% monotonicity index
if RLCmaxi < numel(RLCm)
    MI = min(Dp(RLCmaxi+1:end));
else
    MI = 0;
end

% Plot RLC
if plotRLC
    RLCax = PlotRLC(RLCax,Levels,RLCm,RLCvar,Dp,MI,n);
end

% Output structure
out.Dp = Dp;
out.MI = MI;
out.RLCm = RLCm;
out.RLCvar = RLCvar;
out.BF = BF;
out.CF = CF;
out.MT = MT;
out.BWsm = BWsm;
out.BWhl = BWhl;
out.highlowf  = hl;
out.spontrate = mspont;
out.FRAax   = FRAax;
out.RLCax   = RLCax;
out.sig_ind = sig_ind;
out.paramx  = Freqs;
out.paramy  = Levels;
out.paramz  = bins;
out.FRA     = FRA;
out.data    = data;
out.spont   = spont;
out.thresh  = thresh;
out.spiketimes = st;
out.params     = P;
out.unit_id    = unit_id;

out = orderfields(out);

function RLCax = PlotRLC(RLCax,Levels,RLCm,RLCvar,Dp,MI,n)
if isempty(RLCax)
    f = findobj('type','figure','-and','name','RLC');
    if isempty(f), f = figure('name','RLC','units','normalized','color','w'); end
    figure(f);
    clf
    RLCax = axes('ticklength',[0.001 0.01]);
end

axes(RLCax);

sem = sqrt(RLCvar)./n;
hold(RLCax,'on');
errorbar(Levels,RLCm,sem,sem,'-ok','markersize',8,'linewidth',2);
xlim([min(Levels)-10 max(Levels)+10]);
% ylim([0 max(get(RLCax,'ylim'))]);
ylabel('Firing Rate (Hz)');
xlabel('Sound Level (dB SPL)');
hold(RLCax,'off');

Dpax = axes('position',get(RLCax,'position'), ...
    'ticklength',[0.001 0.01],'YAxisLocation','right','color','none','xtick',[]);
hold(Dpax,'on');
plot(Levels,Dp,'-.k','linewidth',2);
hold(Dpax,'off');
xlim([min(Levels)-10 max(Levels)+10]);
% ylim([min(get(Dpax,'ylim')) 0.01]);
ylabel('D''');
box on

title(sprintf('RLC | MI=%0.1f',MI))

RLCax = [RLCax Dpax];

function FRAax = PlotRF(FRAax,Freqs,Levels,FRA,BF,CF,MT,hl,sm)
if isempty(FRAax)
    f = findobj('type','figure','-and','name','FRA');
    if isempty(f), f = figure('name','FRA','units','normalized','color','w'); end
    figure(f);
    clf
    FRAax = axes;
end

axes(FRAax);

surf(FRAax,Freqs,Levels,FRA)
set(FRAax,'xscale','log')
shading interp
axis tight
view(2)

if nargin > 4
    hold(FRAax,'on')
    
    nnind = ~isnan(BF);
    
    mv = max(get(gca,'zlim'));
    z  = repmat(mv,2,sum(nnind));
    
    Vq = interp2(Freqs,Levels,FRA,BF(nnind),Levels(nnind),'spline');
    plot3(BF(nnind),Levels(nnind)-0.5,Vq+10,'ok','linewidth',2, ...
        'markersize',8,'markerfacecolor','none');
    

    plot3(CF,MT-0.5,mv+10,'ko','linewidth',2,'markersize',8,'markerfacecolor','w');
    
    x = [BF(nnind).*2.^(-sm(nnind)) BF(nnind).*2.^(sm(nnind))];
    
    plot3(x',(Levels(nnind)*[1 1])'-0.5,z,'-k','linewidth',2)
    
    plot3(hl(nnind,:),(Levels(nnind)*[1 1])-0.5,z',':+k','linewidth',2)
    
    set(FRAax,'clim',[0 max(get(FRAax,'clim'))]);
    
    hold(FRAax,'off')
    
end
xlabel('Frequency (Hz)');
ylabel('Sound Level (dB SPL)');
zlabel('Firing Rate (Hz)');

c=colorbar;
ylabel(c,'Firing Rate (Hz)');


