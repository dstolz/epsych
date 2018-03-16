function DATA = pp_plot_rasters_AMBehavior_v2(path, subject, session, block, channel, clu)
%
%  pp_plot_rasters(subject, session, channel, clu)  
%    Plots a raster and psth for each unique stimulus. Clu is the label
%    given by UMS (not an index), found in Spikes.sorted.labels.
%
%  KP, 2016-04; last updated 2016-04
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
% % % % GET BEHAVIOR DATA
% % % Behav       =   getbehaviordata(Info);

% GET STIM INFO
% Find unique stimuli
% Poke Dur %
Freq		=	[Stim.Rate]';
dBSPL		=	[Stim.dB]';
dBMin       =   nanmin(dBSPL);
nel         =   dBSPL ~= dBMin;
dBSPL(nel)  =   dBMin;
Dur			=	[Stim.stimDur]';
Par_matrix	=	[Freq dBSPL] ;

%-Remove Remind trials-%
sel         =    Par_matrix(:,1) < 16;
Par_matrix  =   Par_matrix(sel,:);

[unique_stim, unique_IDs, StimID] = unique(Par_matrix,'rows','sorted');
AMRate		=	unique(Freq);

% Make stim struct
stim = struct();
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

% Set up raster/histo plot parameters
t_beg  =	-200;  %ms
t_end  =	5400;  %ms
nt     =	t_end - t_beg +1;  %each entry 1 ms
bin    =	10;    %ms

smooth.wsize = round(nt/200);					%window size for gaussian smoothing of histo for plotting
smooth.cutoff = 20;								%cutoff for the gaussian smoothing
smooth.stdev = Info.fs/(2*pi*smooth.cutoff);	%std for gaussian smoothing of histo for plotting

% Set up figure 
nSubPlots = 2;
cnt		=	0;
CNT		=	nan(numel(stim),1);
cntt	=	0;
CNTT	=	nan(numel(stim),1);
SR		=	cell(numel(stim),1);
SE		=	cell(numel(stim),1);

for ks = 1:numel(stim)
    % Get spiketimes for this stim
    
    tr_this_stim = stim(ks).tr_idx;
    
    raster_x=[];  raster_y=[];  hist_raw=zeros(1,nt);
    for it = 1:numel(tr_this_stim)
        sp=[];  spk_in=[];
        spk_in = find(spiketrials==tr_this_stim(it));
        sp = spiketimes(spk_in) + ones(size(spiketimes(spk_in)))*(Info.t_win_ms(1)-1); %ms, rel to t0
        sp = sp( sp>=t_beg & sp<= t_end );
        
        hist_raw(it, sp-t_beg+1) = 1;
        raster_x = [raster_x sp];
        raster_y = [raster_y it .* ones(1,numel(sp))];
	end
    
	%---Stimulus Duration---%
	dur			=	Dur(tr_this_stim);
    bins        =   t_beg:bin:t_end;
	psth        =   hist(raster_x,bins);
	NReps		=	max(raster_y);
	psth        =   psth/NReps;
	
    % Plot raster
% 	figure(1)
	subplot(2,2,1)
%     subplot(1,3,1)
	plotAMstimuli(AMRate(ks),cnt,max(raster_y),dur)

	if( ~isempty(cnt) )
		raster_Y		=	raster_y + cnt;
		cnt				=	cnt + 0.50;
		CNT(ks,1)		=	cnt;
		if( ks > 1 )
			plot([-1000 6000],[cnt cnt],'k-')
		end
		hold on
		if( ks == 1 )
			plot(  raster_x  ,  raster_Y  , 'r.','MarkerSize',10)
		else
			plot(  raster_x  ,  raster_Y  , 'k.','MarkerSize',10)
		end
		cnt				=	cnt + NReps;
	end
	
	RASTERS(ks,1)	=	{raster_y};
	
    % PSTH
% 	figure(1)
	subplot(2,2,2)
%     subplot(1,3,2)
    hist_bin    =   psth;
	CNTT(ks,1)	=	cntt;
	maxx		=	nanmax(hist_bin);
	normhist	=	hist_bin/maxx;
	normhist	=	normhist + cntt;
    msX         =   bins;
	[xx,yy]		=	stairs(msX,normhist);

    plotAMstimuli(AMRate(ks),cntt,1,dur)

	plot([-1000 6000],[cntt cntt],'k-')
	hold on
	
	if( ks == 1 )
		plot( xx  , yy , 'r-', 'LineWidth', 1.5)
	else
		plot( xx  , yy , 'k-', 'LineWidth', 1.5)
	end
	cntt			=	cntt + 1.10;

    %---Get Spike Rate---%
	[spkrate,se,sd,spon,~,Spks,SpkT]		=	getspkerate(raster_y,raster_x,dur,AMRate(ks));

    %---Get Power---%
%     [avgPower,semPower,vect_power]  =   getPower(raster_x,raster_y,dur,AMRate(ks));
    
    %---Get VS---%
    isi                 =   1000/AMRate(ks);
    percrit             =   isi + 400;
    spkt                =   cell2mat(SpkT');
    spksel              =   spkt > percrit;
    spkt                =   spkt(spksel);
    
    VS(ks,1)            =   vectorstrength(spkt,isi);
    
    %---Store Data---%
	SPKS(ks,1)			=	{raster_x};
	SpikeTrial(ks,1)	=	{raster_y};
	SE(ks,1)			=	{se};
	SD(ks,1)			=	{sd};
	SR(ks,1)			=	{spkrate};	%---Hz---%
	Spon(ks,1)			=	{spon};
	SpkVec(ks,1)		=	{Spks};
    
%     Power(ks,1)         =   avgPower;
%     PowerSE(ks,1)       =   semPower;
%     PowerVector(ks,1)    =   {vect_power};
    
end
t_end	=	1400;
% figure(1)
subplot(2,2,1)
% subplot(1,3,1)
plot([0 0],[0 cnt],'k--'); hold on
set(gca,'FontSize',16)
set(gca, 'XLim', [t_beg t_end])
xlabel( 'Time (ms)')
set(gca,'XTick',-200:200:t_end,'XTickLabel',-200:200:t_end);
xlim([-200 t_end])
ylabel('AM Rate (Hz)')
set(gca,'YTick',CNT,'YTickLabel',unique(Freq));
if( ~isempty(cnt) )
	ylim([0 cnt])
end

hold off
box on
if( clu(1,2) == 2 )
	title(['Ch: ' num2str(channel) '; dBSPL: ' num2str(unique_stim(ks,2)) '; SU'])
else
	title(['Ch: ' num2str(channel) '; dBSPL: ' num2str(unique_stim(ks,2)) '; MU'])
end
% axis square

subplot(2,2,2)
% subplot(1,3,2)
plot([0 0],[0 6000],'k--'); hold on
set(gca,'FontSize',16)
set(gca, 'XLim', [t_beg t_end])
xlabel( 'Time (ms)')
set(gca,'XTick',-200:200:t_end,'XTickLabel',-200:200:t_end);
xlim([-200 t_end])
ylabel('AM Rate (Hz)')
set(gca,'YTick',CNTT,'YTickLabel',unique(Freq));
ylim([0 cntt])
hold off
title(['Normalized PSTH; bin width: ' num2str(bin) ' ms'])
% axis square

%---Get D-Prime---%
dprimes			=	calculatedprime_v2(SR,SD,AMRate);
% AMRATE          =   AMRate(1:end-1);
AMRATE          =   AMRate;
dprate          =   AMRATE(2:end);

subplot(2,3,4)
% subplot(3,3,3)
plotSRFunctions(SR,SE,AMRATE)

% %---Plot D-Primes---%
% [xfit,yfit,threshold,MSE,idx,Time,DP]	=	PlotDPrimes(Depth,dprimes,xTime);
% idx		=	cell2mat(idx);
%---Plot Spike Rate Functions---%
% subplot(2,3,4)
% idx		=	[1;idx];
% idx		=	idx == 1;
% 
% [SR,SE]	=	getadjustedSR(SR,SE,Time,xTime);

subplot(2,3,5)
% subplot(3,3,6)
plotDPFunctions(dprimes,dprate)

subplot(2,3,6)
% subplot(3,3,9)
plotVSFunction(VS,AMRATE)
% plotPowerFunctions(Power,PowerSE,AMRATE)

%---STORE VARIABLES---%
DATA.AMRate		=	AMRate;
DATA.SpkRate	=	SR;
DATA.StdDev		=	SD;
DATA.StdErr		=	SE;
% DATA.DPrime		=	DP;
DATA.Rasters	=	SPKS;
DATA.SpikeTrial	=	SpikeTrial;
DATA.Spon		=	Spon;
% DATA.Latency	=	DUR;
% DATA.xfit		=	xfit;
% DATA.yfit		=	yfit;
% DATA.MSE		=	MSE;
% DATA.threshold	=	threshold;
% DATA.GoodUnit	=	double(good);
% DATA.GoodAM		=	double(gAM);

% DATA.Time		=	Time;
% DATA.Dprimes	=	dprimes;
% DATA.xTime		=	xTime;
DATA.SpkVec		=	SpkVec;
DATA.VectorStrength     =   VS;

%---Locals---%
function Behav = getbehaviordata(Info)
ID          =    Info.subject;
Date        =   Info.date;
DATE        =   [Date(10:11) '-' num2str(Date(6:9)) Date(1:4)];

function plotAMstimuli(AMRate,yminval,ymaxval,dur)
ymax	=	yminval + ymaxval;
rV		=	AMRate;
fs = 1000;
t  = cumsum([0 32./rV]);
s = round(t.*fs);
y  = [];

for ip = 1:numel(rV)
	tp=[]; tp = 0:(s(ip+1)-s(ip)-1);
	%         y = [y 1- data.AMdepth*cos(2*pi*rV(ip)/fs*tp)];
	y = [y 1- 1*cos(2*pi*rV(ip)/fs*tp)];
end
%     hold on; plot(y)

% Remove first 1/4 of the first period

yclip = y(dround(0.25/rV(1)*fs):end);

% Add sound during unmodulated portion
y_um = ones(1,round(400/1000*fs)); %0.8165.*
stim = [y_um yclip];

X	=	[1:length(stim) length(stim):-1:1];
Y	=	[stim fliplr(-stim)];
scale	=	[yminval ymax];
% Normalize to [0, 1]:
m = min(Y);
range = max(Y) - m;
array = (Y - m) / range;

% Then scale to [x,y]:
range2 = scale(2) - scale(1);
normalized = (array*range2) + scale(1);

% Plot individual stim, for debugging
%     hF(ks) = figure;
%     scrsz = get(0,'ScreenSize');
%     set(hF(ks),'Position',[1 scrsz(4)/2 scrsz(3) scrsz(4)/2],...
%         'Nextplot','add');
% signal	=	stim/4*ymax + (yminval)/2;
Wcolor = [0.85 0.85 0.85];
% fill([1:length(signal) length(signal):-1:1] /fs*1000,[signal fliplr(-signal)],[0.3 0.3 0.3])
fill(X,normalized,Wcolor,'EdgeColor','none')
% fill([1:length(signal) length(signal):-1:1], [signal fliplr(-signal)],...
%     Wcolor,'EdgeColor','none')
hold on

function [spkrate,se,sd,Spon,stops,Spks,spkt] = getspkerate(trials,spktimes,dur,AMRate)
Per				=	1000/AMRate;
NTrials			=	max(unique(trials));
start			=	0;
% Dur             =   nanmax(dur);
Dur             =   1000;
stops			=	start:25:Dur;
stops			=	stops(2:end);
Nruns			=	length(stops);
for i=1:NTrials
		sel		=	trials == i;
		st		=	spktimes(sel);
		%---Spontaneous Firing Rate---%
		spel	=	st < 0;
		spon(i,1)	=	sum(spel);
		
% 		%---FR for unmodulated portion---%
% 		uel		=	st > 0 & st < 400;
% 		unmod(i,1)	=	sum(uel);
		
		%-Get AM Firing Rate-%
% % % 		for j=1:Nruns
% % % 			stop	=	stops(j);
% % % 			zel		=	st >= start & st < stop;
% % % 			ss		=	sum(zel);
% % % % 			SR		=	(1000/stop)*ss;
% % % 			SR		=	ss;
% % % 			spks(i,j)	=	SR;
% % % 			Stops(1,j)	=	stop - start;
% % % 		end
            
            stop    =   dur(i) - 25;
            zel		=	st >= start & st < stop;
            spkt(i,1)   =   {st(zel)};
			ss		=	sum(zel);
			SR		=	(1000/stop)*ss;
            spks(i,1)	=	SR;
end
%---Extract bad trials---%
SD				=	nanstd(spks(:,end));
ME				=	nanmean(spks(:,end));
crit			=	ME + 2.5*SD;
zel				=	spks(:,end) > crit;
Spks			=	spks(~zel,:);
%------------------------%
% Spks            =   spks;
% SR				=	nanmean(spks) - nanmean(UM);
se				=	nanstd(Spks)/sqrt(length(Spks));
sd				=	nanstd(Spks);
spkrate			=	nanmean(Spks);

% Hz				=	1000./Stops;
% spkrate			=	spkrate.*Hz;
% se				=	se.*Hz;
% sd				=	sd.*Hz;

SponHz			=	1000./200;
spon            =   spon*SponHz;
Spon			=	nanmean(spon(~zel));
% Spon			=	nanmean(spon);

% Unmod			=	nanmean(unmod(~zel));
% UnmodSD			=	nanstd(unmod(~zel));
% UnmodSE			=	nanstd(unmod(~zel))/sqrt(length(unmod(~zel)));
% Hzz				=	1000./400;
% Unmod			=	Unmod.*Hzz;
% UnmodSD			=	UnmodSD.*Hzz;
% UnmodSE			=	UnmodSE.*Hzz;
% stops			=	stops - 400;

function [avgPower,semPower,power_vect] = getPower(spk,trial,dur,MF)
trials      =   unique(trial);
Ntrials     =   length(trials);
fs          =   100; %samples for FFT analysis
power_vect  =   zeros(Ntrials,1);
%-------------------------------------------------------------------
%Initialize parameters for power analysis

params.tapers = [5 9]; %[TW K] where TW = time-bandwidth product and K =
%the number of tapers to be used (<= 2TW-1). [5 9]
%are the values used by Merri Rosen for her 2010
%analysis.

params.pad = 2;        %Padding for the FFT. -1 corresponds to no padding,
%0 corresponds to the next higher power of 2 and so
%on. This value will not affect the result
%calculation, however, using a value of 1 improves
%the efficiancy of the function and increases the
%number of frequency bins of the result.

params.fpass = [0 10]; %[fmin fmax]
%Frequency band to be used in calculation.

params.Fs = fs;        %Sampling rate

params.err = [1 .05];  %Theoretical errorbars (p = 0.05). For Jacknknife
%errorbars use [2 p]. For no errorbars use [0 p].

params.trialave = 0;   %If 1, average over trials or channels.

dt=1/params.Fs;        %Sampling time
fscorr = 1;            %If 1, use finite size corrections.

perdur=1/MF;           %Duration of each period (sec)
%-------------------------------------------------------------------
%---Loop through each trial---%
for i=1:Ntrials
	t		=	400:dt:dur(i);			%Time grid for prolates for data1 (???)
	sel		=	trial == trials(i);
	spikes	=	spk(sel);
    zel     =   spikes >= 400 & spikes < dur(i);
    spikes  =   spikes(zel)-400;
	%Calculate the power across frequencies
	[spectra,f]	=	mtspectrumpt(spikes,params,fscorr,t);
	
	%Find the index value closest to MF
	target	=	min(abs(f-MF));
	MFidx	=	find((abs(f-MF) == target));
	
	%Calculate the power at the MF
	MFpower	=	spectra(MFidx);
	
	%Add the power for that trial into the vector
	power_vect(i)	=	MFpower;
end
avgPower	=	mean(power_vect);
stdPower	=	std(power_vect);
semPower	=	stdPower/sqrt(Ntrials);

function dprimes = calculatedprime_v2(SR,SD,AM)
zel         =   AM == 16;
AM          =   AM(~zel);
Nrate		=	length(AM);
sel			=	AM == nanmin(AM);
NogoSR		=	SR(sel);
NogoSD		=	SD(sel);
GoSR		=	SR(~sel);
GoSD		=	SD(~sel);
Nsr			=	NogoSR{1};
Nsd			=	NogoSD{1};
N			=	length(Nsr);
dprimes		=	nan(Nrate-1,N);

for i=1:Nrate-1
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

function plotSRFunctions(SR,SE,AM)
N			=	length(AM);
for i=1:N
	sr		=	SR{i};
    sr      =   sr(end);
	se		=	SE{i};
    se      =   se(end);
	if( i == 1 )
		plot([AM(i) AM(i)],[sr + se sr - se],'r-')
		hold on
		plot(AM(i),sr,'ro','MarkerFaceColor','r','MarkerSize',10)
	else
		plot([AM(i) AM(i)],[sr + se sr - se],'k-')
		hold on
		plot(AM(i),sr,'ko','MarkerFaceColor','k','MarkerSize',10)
	end
	hold on
	spkrate(1,i)	=	sr;
end
plot(AM(2:end),spkrate(2:end),'k-')
xlim([2 14])
maxy		=	max(spkrate)*1.2;
ylim([0 maxy])
set(gca,'FontSize',16)
xlabel( 'AM Rate')
set(gca,'XTick',AM,'XTickLabel',AM);
ylabel('Firing Rate')
axis square

function plotPowerFunctions(P,SE,AM)
N			=	length(AM);
for i=1:N
	pr		=	P(i);
	se		=	SE(i);
	if( i == 1 )
		plot([AM(i) AM(i)],[pr + se pr - se],'r-')
		hold on
		plot(AM(i),pr,'ro','MarkerFaceColor','r','MarkerSize',10)
	else
		plot([AM(i) AM(i)],[pr + se pr - se],'k-')
		hold on
		plot(AM(i),pr,'ko','MarkerFaceColor','k','MarkerSize',10)
	end
	hold on
	power(1,i)	=	pr;
end
plot(AM(2:end),power(2:end),'k-')
xlim([2 14])
maxy		=	max(power)*1.2;
ylim([0 maxy])
set(gca,'FontSize',16)
xlabel( 'Power')
set(gca,'XTick',AM,'XTickLabel',AM);
ylabel('Firing Rate')
axis square

function plotDPFunctions(DP,AM)
DP          =   DP(:,end);
plot(AM,DP,'k-')
hold on
plot(AM,DP,'ko','MarkerFaceColor','k','MarkerSize',10)
xlim([2 14])
maxy		=	3;
ylim([0 maxy])
set(gca,'FontSize',16)
xlabel( 'AM Rate (Hz)')
set(gca,'XTick',AM,'XTickLabel',AM);
ylabel('d-prime')
set(gca,'YTick',0:1:3,'YTickLabel',0:1:3);
axis square

function plotVSFunction(VS,AM)
plot(AM(2:end),VS(2:end),'k-')
hold on
plot(AM(2:end),VS(2:end),'ko','MarkerFaceColor','k','MarkerSize',10)
plot(AM(1),VS(1),'ro','MarkerFaceColor','r','MarkerSize',10)
xlim([2 14])
maxy		=	nanmax(VS);
if( maxy < 0.50 )
    ylim([0 0.50])
else
    ylim([0 1])
end
set(gca,'FontSize',16)
xlabel( 'AM Rate (Hz)')
set(gca,'XTick',AM,'XTickLabel',AM);
ylabel('VS')
set(gca,'YTick',0:0.25:1,'YTickLabel',0:0.25:1);
axis square