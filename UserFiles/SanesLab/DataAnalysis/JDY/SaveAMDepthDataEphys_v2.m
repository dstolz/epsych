function DATA = SaveAMDepthDataEphys_v2(path, subject, session, block, channel, clu, bData)
%
%  pp_plot_rasters(subject, session, channel, clu)  
%    Plots a raster and psth for each unique stimulus. Clu is the label
%    given by UMS (not an index), found in Spikes.sorted.labels.
%
%  KP, 2016-04; last updated 04-07-2017 JDY
% 

set(0,'DefaultAxesFontSize',14)

% Load data files

% datadir		=	'/Users/justinyao/Sanes Lab/Experiments/PROJECTS/AM RATE/Ephys/processed_data/';
datadir			=	path;
session			=	[session '-' block];

fprintf('\nloading data...\n')
filename = sprintf( '%s_sess-%s_Spikes',subject,session); load(fullfile(datadir,subject,filename));
filename = sprintf( '%s_sess-%s_Info'  ,subject,session); load(fullfile(datadir,subject,filename));
filename = sprintf( '%s_sess-%s_Stim'  ,subject,session); load(fullfile(datadir,subject,filename));

%%
% GET STIM INFO
% Find unique stimuli
Freq		=	[Stim.Rate]';
uFreq		=	unique(Freq);
selRemind	=	uFreq > 0;
Remind		=	nanmin(uFreq(selRemind));
Dur			=	[Stim.stimDur]';
Depth		=	[Stim.AMdepth]';

[Freq,Depth]	=	getTrials(Depth,Freq);

Par_matrix	=	[Freq Depth] ;
if( max(uFreq) ~= Remind )
	sel			=	Freq == Remind;
	Par_matrix	=	Par_matrix(~sel,:);
end
[unique_stim, unique_IDs, StimID] = unique(Par_matrix,'rows','sorted');
freq		=	unique(unique_stim(:,1));
sel			=	freq > 0;
freq		=	freq(sel);
AMRate		=	bData.Rates;
AMDepth		=	unique(Depth);

% Make stim struct
stim = struct();
% behav_state = {'passive' 'active'};
for ks = 1:size(unique_stim,1)
    stim(ks).tr_idx   = find(StimID==StimID(unique_IDs(ks)));
    stim(ks).stim_str = sprintf('ch %s unit %s\n%i Hz  |  %2.3g dBSPL\n%2.4g ms  | %s',...
        num2str(channel), num2str(clu(1)), ...
        unique_stim(ks,1),unique_stim(ks,2));
end
%%

% GET SPIKE TIMES
spikes = Spikes.sorted(channel);
unit_in = find(spikes.assigns==clu(1));
spiketimes = round(spikes.spiketimes(unit_in) * 1000);  %ms
spiketrials = spikes.trials(unit_in); 

if isempty(spiketimes)
    error('no spike events found for this clu')
elseif spikes.labels(spikes.labels(:,1)==clu(2)) == 4
    warning('  this clu is labeled as noise. are you sure you want to plot?')
    keyboard
end
%%

% Set up raster/histo plot parameters
t_beg  =	-199;	%ms
t_end  =	5400;	%ms

nt     =	t_end - t_beg +1;  %each entry 1 ms
bin    =	10;		%ms
bins	=	t_beg:bin:t_end;

smooth.wsize = round(nt/200);					%window size for gaussian smoothing of histo for plotting
smooth.cutoff = 20;								%cutoff for the gaussian smoothing
smooth.stdev = Info.fs/(2*pi*smooth.cutoff);	%std for gaussian smoothing of histo for plotting

SR		=	cell(numel(stim),1);
SE		=	cell(numel(stim),1);
cnt		=	0;
CNT		=	nan(numel(stim),1);
cntt	=	0;
CNTT	=	nan(numel(stim),1);
col		=	linspace(0,1,numel(stim)+1)';
col		=	repmat(col,1,3);
col		=	col(1:end-1,:);
col		=	rot90(col,2);

DUR		=	cell(numel(stim),1);
for ks = 1:numel(stim)
    % Get spiketimes for this stim
	tr_this_stim = stim(ks).tr_idx; 
    raster_x=[];  raster_y=[];  hist_raw=zeros(1,nt);
	
	dur	=	Dur(tr_this_stim);
	DUR(ks,1)	=	{dur};
    for it = 1:numel(tr_this_stim)
        sp=[];  spk_in=[];
        spk_in = find(spiketrials==tr_this_stim(it));
        sp = spiketimes(spk_in) + ones(size(spiketimes(spk_in)))*(Info.t_win_ms(1)-1); %ms, rel to t0
        sp = sp( sp>=t_beg & sp<= t_end );
        
        hist_raw(it, sp-t_beg+1) = 1;
        raster_x = [raster_x sp];
        raster_y = [raster_y it .* ones(1,numel(sp))];
	end
	NReps		=	max(raster_y);
  %%  
	% Plot raster
	figure(1)
	subplot(2,2,1)
	if( ~isempty(cnt) )
		raster_Y		=	raster_y + cnt;
		cnt				=	cnt + 0.50;
		CNT(ks,1)		=	cnt;
		if( ks > 1 )
			plot([-200 2000],[cnt cnt],'k-')
		end
		hold on
		if( ks == 1 )
			plot(  raster_x  ,  raster_Y  , 'r.','MarkerSize',6)
		else
			plot(  raster_x  ,  raster_Y  , 'k.','MarkerSize',6,'Color',col(ks,:))
		end
		cnt				=	cnt + NReps;
	end
	
    %---Get Spike Rate---%
	[spkrate,se,sd,spon,unmod,xTime,Spks]		=	getspkerate(raster_y,raster_x,dur,AMRate);
	SPKS(ks,1)			=	{raster_x};
	SpikeTrial(ks,1)	=	{raster_y};
	SE(ks,1)			=	{se};
	SD(ks,1)			=	{sd};
	SR(ks,1)			=	{spkrate};	%---Hz---%
	Spon(ks,1)			=	{spon};
	Unmod(ks,1)			=	{unmod};
	SpkVec(ks,1)		=	{Spks};
end
%%
figure(1)
%-Dot Raster Axis-%
subplot(2,2,1)
plot([0 0],[0 cnt],'k--'); hold on
plot([400 400],[0 300],'b-')
set(gca,'FontSize',16)
set(gca, 'XLim', [t_beg 2000])
xlabel( 'Time (ms)')
set(gca,'XTick',0:400:2000,'XTickLabel',0:400:2000);
xlim([-205 1205])
ylabel('AM Depth (%)')
set(gca,'YTick',CNT,'YTickLabel',AMDepth);
if( ~isempty(cnt) )
	ylim([0 cnt+1])
end
hold off
box on
% axis square
if( clu(1,2) == 2 )
	title(['Ch: ' num2str(channel) '; SU '])
else
	title(['Ch: ' num2str(channel) '; MU '])
end

%---Get D-Prime---%
dprimes			=	calculatedprime_v2(SR,SD,AMDepth);
Depth			=	mag2db(AMDepth(2:end));

%---Plot D-Primes---%
subplot(2,2,3)
[xfit,yfit,threshold,MSE,idx,Time,DP]	=	PlotDPrimes(Depth,dprimes,xTime);
idx		=	cell2mat(idx);
%---Plot Spike Rate Functions---%
subplot(2,2,2)
idx		=	[1;idx];
idx		=	idx == 1;

[SR,SE]	=	getadjustedSR(SR,SE,Time,xTime);

plotSRFunctions(SR(idx),SE(idx),AMDepth(idx))
% plotSRFunctions(SR,SE,AMDepth)

%---Check if "Good" Unit---%
dpcrit			=	dprimes(end) >= 1;
MSEcrit			=	MSE < 0.1;
if( dpcrit == 1 & MSEcrit == 1 )
	good		=	1;
else
	good		=	0;
end

%---STORE VARIABLES---%
DATA.AMRate		=	AMRate;
DATA.AMDepth	=	AMDepth;
DATA.SpkRate	=	SR;
DATA.StdDev		=	SD;
DATA.StdErr		=	SE;
DATA.DPrime		=	DP;
DATA.Rasters	=	SPKS;
DATA.SpikeTrial	=	SpikeTrial;
DATA.Latency	=	DUR;
DATA.xfit		=	xfit;
DATA.yfit		=	yfit;
DATA.MSE		=	MSE;
DATA.threshold	=	threshold;
DATA.GoodUnit	=	double(good);
DATA.Spon		=	Spon;
DATA.Unmod		=	Unmod;
DATA.Time		=	Time;

%---Locals---%
function [Freq,Depth] =	getTrials(Depth,Freq)
uDepth		=	unique(Depth);
N			=	length(uDepth);
for i=1:N
	idx		=	uDepth(i) == Depth;
	cnt		=	sum(idx);
	if( cnt < 10 )
		Depth(idx)	=	[];
		Freq(idx)	=	[];
	end
end

function [spkrate,se,sd,Spon,Unmod,stops,Spks] = getspkerate(trials,spktimes,dur,AMRate)
Per				=	1000/AMRate;
NTrials			=	max(unique(trials));
start			=	400;
stops			=	start:5:1600;
% stops			=	stops + 400;
Nruns			=	length(stops);
for i=1:NTrials
		sel		=	trials == i;
		st		=	spktimes(sel);
		%---Spontaneous Firing Rate---%
		spel	=	st < 0;
		spon(i,1)	=	sum(spel);
		
		%---FR for unmodulated portion---%
		uel		=	st > 0 & st < 400;
		unmod(i,1)	=	sum(uel);
		
		%-Get AM Firing Rate-%
		for j=1:Nruns
			stop	=	stops(j);
			zel		=	st > start & st < stop;
			ss		=	sum(zel);
% 			SR		=	(1000/stop)*ss;
			SR		=	ss;
			spks(i,j)	=	SR;
		end
end
%---Extract bad trials---%
SD				=	nanstd(unmod);
ME				=	nanmean(unmod);
crit			=	ME + SD;
zel				=	unmod > crit;
% critt			=	ME - SD;
% zel				=	spks < crit & spks > critt;
% Spks			=	spks(zel);
%------------------------%
Spks			=	spks(~zel,:);
% SR				=	nanmean(spks) - nanmean(UM);
se				=	nanstd(Spks)/sqrt(length(Spks));
sd				=	nanstd(Spks);
spkrate			=	nanmean(Spks);

Hz				=	1000./stops;
spkrate			=	spkrate.*Hz;
se				=	se.*Hz;
sd				=	sd.*Hz;

Spon			=	nanmean(spon(~zel));

Unmod			=	nanmean(unmod(~zel));

function dprimes = calculatedprime_v2(SR,SD,AMDepth)
Ndepth		=	length(AMDepth);
sel			=	AMDepth == 0;
NogoSR		=	SR(sel);
NogoSD		=	SD(sel);
GoSR		=	SR(~sel);
GoSD		=	SD(~sel);
Nsr			=	NogoSR{1};
Nsd			=	NogoSD{1};
N			=	length(Nsr);
dprimes		=	nan(Ndepth-1,N);
for i=1:Ndepth-1
	Gsr		=	GoSR{i};
	Gsd		=	GoSD{i};
	for j=1:N
% 		commonstds		=	(Nsd(j) + Gsd(j))/2;
% 		dprimes(i,j)	=	(Gsr(j)-Nsr(j))./commonstds;
		commonstds		=	(Nsd(j) + Gsd(j));
		FRdiff			=	2*(Gsr(j) - Nsr(j));
		dprimes(i,j)	=	FRdiff./commonstds;
	end
end
dprimes		=	abs(dprimes);

function [xfit,yfit,threshold,mse,idx] = getthreshold(x,y)
%Create a sigmoidal function:  f = y0 + a/(1 + exp(-(x - x0)/b))
%Parameters (p):
%p(1):  y0 = min
%p(2):   a = max - min
%p(3):   b = slope
%p(4):  x0 = x coordinate at inflection point
f = @(p,x) p(1) + p(2) ./ (1 + exp(-(x-p(3))/p(4)));
%Establish s vector of initial coefficients (beta0)
beta0 = [0 20 50 5];

%Set the maximum number of iterations to 1000
options = statset('MaxIter',1000,'Robust','on');

%Do the fitting
sel		=	isnan(y);
y(sel)	=	0;
%---Get contiguious y values---%
if( length(y) > 3 )
	idx		=	diff(y(1:4)) > -0.75;
	idx		=	[idx(:,1);1;1];
	idx		=	idx == 1;

	X		=	x(idx);
	Y		=	y(idx);
	
if( length(X) < 4 )
	[p, r, ~, covb, mse] = nlinfit(x,y,f,beta0,options);
	X	=	x;
	Y	=	y;
else
	[p, r, j, covb, mse] = nlinfit(X,Y,f,beta0,options);
end

xfit = linspace(X(1),X(end),1000);
yfit = f(p,xfit);
yfit_corr = f(p,X);

%Get threshold
sel			=	yfit >= 1;
MD			=	db2mag(xfit(sel));
threshold	=	nanmin(MD);
threshold	=	mag2db(threshold);
if( isempty(threshold) )
	threshold	=	NaN;
end

else
	threshold	=	NaN;
	xfit		=	NaN;
	yfit		=	NaN;
	mse			=	NaN;
	idx			=	y > 0;
	idx			=	idx == 1;
end

function [SR,SE] = getadjustedSR(SR,SE,Time,xTime)
sr			=	cell2mat(SR);
se			=	cell2mat(SE);
sel			=	xTime == Time;
SR			=	sr(:,sel);
SE			=	se(:,sel);

function plotSRFunctions(SR,SE,AMDepth)
N			=	length(AMDepth);
Depth		=	mag2db(AMDepth)';
Depth(1)	=	-17;
for i=1:N
	sr		=	SR(i);
	se		=	SE(i);
	
	if( i == 1 )
		plot([Depth(i) Depth(i)],[sr + se sr - se],'r-')
		hold on
		plot(Depth(i),sr,'ro','MarkerFaceColor','r')
	else
		plot([Depth(i) Depth(i)],[sr + se sr - se],'k-')
		hold on
		plot(Depth(i),sr,'ko','MarkerFaceColor','k')
	end
	hold on
	
	spkrate(1,i)	=	sr;
end
plot(Depth(2:end),spkrate(2:end),'k-')
xlim([-18 1])
maxy		=	max(spkrate)*1.2;
% ylim([0 maxy])
set(gca,'FontSize',16)
xlabel( 'AM Depth (dB rel 100%)')
set(gca,'XTick',-21:3:0,'XTickLabel',-21:3:0);
ylabel('Firing Rate')
axis square

function [xFit,yFit,Threshold,MSE,IDX,Time] = PlotDPrimes_old(Depth,dprimes,xTime)
col				=	linspace(0,1,length(dprimes))';
col				=	repmat(col,1,3);
col(end,:)		=	col(end,:)-0.05;
col				=	flipud(col);
N				=	size(dprimes,2);
for i=1:N
	dp			=	dprimes(:,i);
	[xfit,yfit,threshold,mse,idx]	=	getthreshold(Depth,dp);
% 	plot(Depth,dp,'ko','Color',col(i,:),'MarkerSize',8,'MarkerFaceColor',col(i,:))
% 	hold on
% 	h(i)=plot(xfit,yfit,'-','Color',col(i,:),'LineWidth',3);
	
	xFit(1,i)	=	{xfit};
	yFit(1,i)	=	{yfit};
	Threshold(1,i)	=	threshold;
	MSE(1,i)	=	dround(mse);
	IDX(1,i)	=	{idx};
end
dps				=	dprimes(end-2:end,:);
mxdp			=	max(nanmax(dps));
sel				=	dps == mxdp;
Sel				=	sum(sel);
ssel			=	Sel == 1;
Time			=	nanmin(xTime(ssel));

%---Plotting---%
plot([Threshold(ssel) Threshold(ssel)],[0 3],'b','Color',[0.8 0.8 1],'LineWidth',12)
hold on
plot(Depth,dprimes(:,ssel),'ko','Color','k','MarkerSize',10,'MarkerFaceColor','k')
xF				=	cell2mat(xFit(ssel));
yF				=	cell2mat(yFit(ssel));
plot(xF,yF,'k-','LineWidth',3);
plot([-100 100],[1 1],'k--')
xlim([-20 1])
ylim([0 3])
set(gca,'FontSize',16)
title(['Neural Performance; MSE: ' num2str(MSE(ssel)) '; Time: ' num2str(Time) ' ms'])
xlabel( 'AM Depth (dB rel 100%)')
set(gca,'XTick',-21:3:0,'XTickLabel',-21:3:0);
ylabel(' d-prime')
set(gca,'YTick',0:1:3,'YTickLabel',0:1:3);
axis square

function [xFit,yFit,Threshold,MSE,IDX,Time,DP] = PlotDPrimes(Depth,dprimes,xTime)
col				=	linspace(0,1,length(dprimes))';
col				=	repmat(col,1,3);
col(end,:)		=	col(end,:)-0.05;
col				=	flipud(col);
N				=	size(dprimes,2);
for i=1:N
	dp			=	dprimes(:,i);
	[xfit,yfit,threshold,mse,idx]	=	getthreshold(Depth,dp);
% 	plot(Depth,dp,'ko','Color',col(i,:),'MarkerSize',8,'MarkerFaceColor',col(i,:))
% 	hold on
% 	h(i)=plot(xfit,yfit,'-','Color',col(i,:),'LineWidth',3);
	
	xFit(1,i)	=	{xfit};
	yFit(1,i)	=	{yfit};
	Threshold(1,i)	=	threshold;
	if( isunix )
		MSE(1,i)	=	dround(mse);
	else
		MSE(1,i)	=	round(mse,3);
	end
	IDX(1,i)	=	{idx};
end
dps				=	dprimes(end-2:end,:);
mxdp			=	max(nanmax(dps));
sel				=	dps == mxdp;
Sel				=	sum(sel);
ssel			=	Sel == 1;
Time			=	nanmin(xTime(ssel));

DP				=	dprimes(:,ssel);
try
DP				=	DP(:,1);
catch
    keyboard
end
Threshold		=	Threshold(ssel);
Threshold		=	Threshold(1);
xFit			=	xFit(ssel);
xFit			=	cell2mat(xFit(1));
yFit			=	yFit(ssel);
yFit			=	cell2mat(yFit(1));
MSE				=	MSE(ssel);
MSE				=	MSE(1);
IDX				=	IDX(ssel);
IDX				=	IDX(1);
%---Plotting---%
plot([Threshold Threshold],[0 3],'b','Color',[0.8 0.8 1],'LineWidth',12)
hold on
plot(Depth,DP,'ko','Color','k','MarkerSize',10,'MarkerFaceColor','k')
plot(xFit,yFit,'k-','LineWidth',3);
plot([-100 100],[1 1],'k--')
xlim([-20 1])
ylim([0 3])
set(gca,'FontSize',16)
title(['Neural Performance; MSE: ' num2str(MSE) '; Time: ' num2str(Time) ' ms'])
xlabel( 'AM Depth (dB rel 100%)')
set(gca,'XTick',-21:3:0,'XTickLabel',-21:3:0);
ylabel(' d-prime')
set(gca,'YTick',0:1:3,'YTickLabel',0:1:3);
axis square

function plotdprime(Depth,dprimes,xfit,yfit,threshold,MSE)
plot([threshold threshold],[0 5],'b','Color',[0.8 0.8 1],'LineWidth',15)
hold on
plot(xfit,yfit,'k-','LineWidth',2)
plot(Depth,dprimes,'ko','MarkerSize',10,'MarkerFaceColor','w','LineWidth',2)
hold on
plot([-100 100],[1 1],'k--')
xlim([-20 1])
ylim([0 3])
set(gca,'FontSize',16)
title(['Neural Performance; RMSE: ' num2str(MSE)])
xlabel( 'AM Depth (dB rel 100%)')
set(gca,'XTick',-21:3:0,'XTickLabel',-21:3:0);
ylabel(' d-prime')
set(gca,'YTick',0:1:3,'YTickLabel',0:1:3);
axis square

