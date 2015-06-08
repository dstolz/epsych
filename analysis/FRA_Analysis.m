function out = FRA_Analysis(spiketimes,params,varargin)
% DB_FRA_Analysis(spiketimes,params);
% DB_FRA_Analysis(spiketimes,params,'param',value);
% out = DB_FRA_Analysis(spiketimes,params,...);
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
%                                 receptive field.  This will affect both
%                                 analysis results and plotting.
% 'subtractspont' ... true      % Subtract mean spontaneous firing rate
%                                 from receptive field before analysis.
% 'miny'        ... []          % minimum acceptable value for y parameter
%                                   ex, minimum threshold
% 'oct_range'   ... 0.5         % range around Best Frequency for computing
%                                 Rate-Level Curve.  An oct_range of 0.5
%                                 (half-octave) computes mean firing rate
%                                 for 0.25 octaves above and below best
%                                 frequency.
% 
%
% e.g.
% unit_id = 1234; % where 1234 is a valid unit on the database
% spiketimes = DB_GetSpiketimes(unit_id);
% params     = DB_GetParams(unit_id,'unit');
% out = FRA_Analysis(spiketimes,params,'window',[0 0.1],'conflevel',0.90);
% 
% 
% See also, DB_GetSpiketimes, DB_GetParams
% 
% Daniel.Stolzberg@gmail.com 2014

 


assert(nargin >= 2,'Spiketimes and Params are required inputs')


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
oct_range = 0.5; % octave range around estimated BF
miny = [];

% Parse varargin
ParseVarargin({'window','spontwindow','threshold','plotFRA','plotRLC','FRAax', ...
    'RLCax','paramx','paramy','smoothdata','subtractspont','conflevel','miny','oct_range'}, ...
    {'win','swin','thresh','plotFRA','plotRLC','FRAax','RLCax','paramx','paramy', ...
    'smoothdata','subtractspont','cl','miny','oct_range'},varargin)

% Make FRA
[data,vals] = shapedata_spikes(spiketimes,params,{paramx,paramy},'win',win,'binsize',0.001);
data = data / 0.001;

Freqs  = vals{2}(:);
Levels = vals{3}(:);
bins   = vals{1}(:);

FRA = squeeze(mean(data))';
if smoothdata
    FRA = sgsmooth2d(FRA);
end

% Threshold
spont = shapedata_spikes(spiketimes,params,{paramx,paramy},'win',swin,'binsize',0.001);
spont = squeeze(mean(spont))'/0.001;
spont = spont(:);

x = 0:0.01:max(spont);
mspont = mean(spont);
pcdf = poisscdf(x,mspont);

p = polyfit(pcdf,x,3);
thresh = polyval(p,cl);

sig_ind = FRA >= thresh;

if ~isempty(miny)
    assert(isscalar(miny),'miny must be a scalar value');
    miny = Levels(nearest(Levels,miny));
    ind = Levels >= miny;
    sig_ind(~ind,:) = false;
end

% clean up stray significant pixels
sig_ind = bwareaopen(sig_ind,8);
sig_ind = bwmorph(sig_ind,'fill');

if ~any(sig_ind(:))
%     fprintf(2,'No significant responses found at confidence level %0.3f\n',cl) %#ok<PRTCAL>
    out.FRAax = PlotRF(FRAax,Freqs,Levels,FRA,smoothdata);
    out.FRA = FRA;
    out.sig_ind = sig_ind;
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
peakval = nan(size(FRA,1),1);
peakfreq = nan(size(FRA,1),1);
fr = min(Freqs); % reference frequency (minimum frequency presented)
for i = 1:size(FRA,1)
    k = sig_ind(i,:);
    if sum(k) < 3, continue; end
    
    bw = bwlabel(k);
    ul = unique(bw);
    ul(~ul) = [];
    [~,j] = max(arrayfun(@(x) (median(FRA(i,bw==x))),ul));
    bwind = bw==ul(j);
    flow  = find(bwind,1,'first');
    fhigh = find(bwind,1,'last');

%     flow = find(k,1,'first');
%     fhigh = find(k,1,'last');

    hl(i,:) = Freqs([flow fhigh]); % high and low frequency borders
    
%     bwind = k;
    fk = Freqs(bwind)';
    Xk = log2(fk./fr);
    
    % compute cetroid
    Xm(i) = sum(Xk.*FRA(i,bwind))./sum(FRA(i,bwind)); % centroid
    sm(i) = sqrt(sum((Xk-Xm(i)).^2.*FRA(i,bwind))./sum(FRA(i,bwind))); % second order moment

    
    % find peak
    [peakval(i),peaki] = max(FRA(i,bwind));
    peakfreq(i) = Freqs(peaki+flow-1);

end

% Best frequency at each sound level above MT
BF = fr * 2 .^ Xm;

% Bandwidths in octaves
BWsm = sm;
BWhl = log2(hl(:,2)./hl(:,1));

nnind = ~isnan(BF);

MT = min(Levels(nnind)); % Minimum threshold
CF = BF(find(nnind,1));   % Characteristic frequency

% Vq = interp2(Freqs,Levels,FRA,BF,Levels,'spline');


% Plot FRA and tuning
if plotFRA
    if all(isnan(BF))
        fprintf(2,'No significant responses found at confidence level %0.3f\n',cl) %#ok<PRTCAL>
        out.FRAax = PlotRF(FRAax,Freqs,Levels,FRA,smoothdata);
        return
    else
        FRAax = PlotRF(FRAax,Freqs,Levels,FRA,smoothdata,BF,CF,MT,hl,sm);
    end
end



% Rate-Level Curve (RLC) from FRA (Escabi et al, 2007)
BFt = BF;
BFt(~nnind) = CF;

peakfreqt = peakfreq;
peakfreqt(~nnind) = CF;

r = BFt*2.^([-oct_range oct_range]/2);

pkr = peakfreqt*2.^([-oct_range oct_range]/2);

r(r>max(Freqs)) = max(Freqs);
r(r<min(Freqs)) = min(Freqs);

ri   = interp1(Freqs,1:length(Freqs),r,'nearest','extrap');
pkri = interp1(Freqs,1:length(Freqs),pkr,'nearest','extrap');

RLCm   = zeros(size(Levels));
RLCvar = zeros(size(Levels));
n      = zeros(size(Levels));
RLCmpk   = zeros(size(Levels));
RLCvarpk = zeros(size(Levels));
for i = 1:size(ri,1)
    idx = ri(i,1):ri(i,2);
    RLCm(i) = mean(FRA(i,idx));
    t = mean(data(:,idx,i),2);
    n(i) = numel(t);
    RLCvar(i) = var(t);
    
    idx = pkri(i,1):pkri(i,2);
    RLCmpk(i) = mean(FRA(i,idx));
    t = mean(data(:,idx,i),2);
    RLCvarpk(i) = var(t);
end

% normalize RLC by computing D' at each sound level
[RLCmax,RLCmaxi] = max(RLCm);
Dp = (RLCm - RLCmax) ./ sqrt(RLCvar(RLCmaxi)+RLCvar);

[RLCmaxpk,RLCmaxpki] = max(RLCmpk);
Dppk = (RLCmpk - RLCmaxpk) ./ sqrt(RLCvarpk(RLCmaxpki)+RLCvarpk);

% monotonicity index
if RLCmaxi < numel(RLCm)
    MI = min(Dp(RLCmaxi+1:end));
    MIpk = min(Dppk(RLCmaxpki+1:end));
else
    MI = 0;
    MIpk = 0;
end

% Plot RLC
if ~all(isnan(BF)) && plotRLC
    RLCax = PlotRLC(RLCax,Levels,RLCm,RLCvar,RLCmpk,RLCvarpk,Dp,Dppk,MI,n);
else
    cla(RLCax);
    title(RLCax,'No Significant Responses found');
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
out.paramx  = paramx;
out.paramy  = paramy;
out.paramz  = bins;
out.x       = Freqs;
out.y       = Levels;
out.z       = bins;
out.FRA     = FRA;
out.data    = data;
out.spont   = spont;
out.thresh  = thresh;
out.peakval = peakval;
out.peakfreq = peakfreq;
out.RLCmpk   = RLCmpk;
out.RLCvarpk = RLCvarpk;
out.Dppk     = Dppk;
out.MIpk     = MIpk;

out = orderfields(out);



















function RLCax = PlotRLC(RLCax,Levels,RLCm,RLCvar,RLCmpk,RLCvarpk,Dp,Dppk,MI,n)
if isempty(RLCax)
    f = findobj('type','figure','-and','name','RLC');
    if isempty(f), f = figure('name','RLC','units','normalized','color','w'); end
    figure(f);
    clf
    RLCax = axes('ticklength',[0.001 0.01]);
end

axes(RLCax);

sem = sqrt(RLCvar)./n;
sempk = sqrt(RLCvarpk)./n;
hold(RLCax,'on');
errorbar(Levels,RLCm,sem,sem,'-ok','markersize',8,'linewidth',2);
errorbar(Levels,RLCmpk,sempk,sempk,'-ob','markersize',8,'linewidth',2);
xlim([min(Levels)-10 max(Levels)+10]);
ylabel('Firing Rate (Hz)');
xlabel('Sound Level (dB SPL)');
hold(RLCax,'off');
legend(RLCax,'RLC','peak RLC','Location','NorthWest');

Dpax = axes('position',get(RLCax,'position'),'ycolor',[0.2 0.2 0.2], ...
    'ticklength',[0.001 0.01],'YAxisLocation','right','color','none','xtick',[]);
hold(Dpax,'on');
plot(Levels,Dp,'-.','linewidth',2,'color',[0.2 0.2 0.2]);
plot(Levels,Dppk,'-.b')
hold(Dpax,'off');
xlim([min(Levels)-10 max(Levels)+10]);
ylim([min(get(Dpax,'ylim')) 0.02]);
ylabel('D''');
box(Dpax,'on')
legend(Dpax,'D''','peak D''','Location','SouthEast');

title(sprintf('Monotonicity Index = %0.2f',MI))

RLCax = [RLCax Dpax];



















function FRAax = PlotRF(FRAax,Freqs,Levels,FRA,smoothdata,BF,CF,MT,hl,sm)
if isempty(FRAax)
    f = findobj('type','figure','-and','name','FRA');
    if isempty(f), f = figure('name','FRA','units','normalized','color','w'); end
    figure(f);
    clf
    FRAax = axes;
end

axes(FRAax);

% surf function doesn't display top and right boundary data so manually
% account for this for display purposes
xe = interp1(1:length(Freqs),Freqs,length(Freqs)+1,'pchip','extrap');
x = [Freqs(:); xe];
ye = interp1(1:length(Levels),Levels,length(Levels)+1,'linear','extrap');
y = [Levels(:); ye];
z = [FRA; FRA(end,:)];
z = [z z(:,end)];

surf(FRAax,x,y,z);
set(FRAax,'xscale','log')

if smoothdata
    shading interp
else
    shading flat
end

axis tight
view(2)

if nargin > 5
    hold(FRAax,'on')
    
    yadj = mean(diff(Levels))/2;
    
    nnind = ~isnan(BF);
    
    mv = max(get(gca,'zlim'));
    z  = repmat(mv,2,sum(nnind));
      
    x = BF(nnind)*2.^([-0.25 0.25]);
    plot3(x',(Levels(nnind)*[1 1])'+yadj,z,'-','linewidth',5,'color',[0.6 0.6 0.6])
    
    x = [BF(nnind).*2.^(-sm(nnind)) BF(nnind).*2.^(sm(nnind))]; 
    plot3(x',(Levels(nnind)*[1 1])'+yadj,z,'-k','linewidth',2)
    
    
    plot3(BF(nnind),Levels(nnind)+yadj,z,'ko','linewidth',2, ...
        'markersize',8,'markerfacecolor','none');
   
    plot3(CF,MT+yadj,mv+10,'ko','linewidth',2, ...
        'markersize',8,'markerfacecolor','w');
    
    plot3(hl(nnind,:),(Levels(nnind)*[1 1])+yadj,z',':+w','linewidth',2)
    
    set(FRAax,'clim',[0 max(get(FRAax,'clim'))]);
    
    hold(FRAax,'off')
    
    title(sprintf('CF = %0.1f Hz, MT = % 3.0f dB',CF,MT))
    
end
xlabel('Frequency (Hz)');
ylabel('Sound Level (dB SPL)');
zlabel('Mean Firing Rate (Hz)');

c=colorbar;
ylabel(c,'Firing Rate (Hz)');


