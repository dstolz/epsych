function DATA = SaveAMRateData2(path, subject, session, block, channel, clu)
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
% GET STIM INFO
% Find unique stimuli
% Poke Dur %
M			=	[Stim.MaskerRate]';
S			=	[Stim.SignalRate]';
Mdur		=	unique([Stim.MaskerDur]');
Sdur		=	unique([Stim.SignalDur]');
Delay		=	Stim.DelayDur;
% Freq		=	Stim.Freq;
dBSPL		=	[Stim.dB]';
Dur			=	[Stim.stimDur]';
dur			=	max(unique(Dur));
uISI		=	getISI(S,dur);

Par_matrix	=	[M S Delay] ;
[unique_stim, unique_IDs, StimID] = unique(Par_matrix,'rows','sorted');

% uISI		=	getISI(Freq,dur);
AMRate		=	unique(M);

% Make stim struct
stim = struct();    behav_state = {'passive' 'active'};
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
t_beg  =	-199;  %ms
% t_beg	=	100;
% t_end  =	1200;   %ms
if( max(Dur) > 3000 )
	t_end	=	5200;
else
	t_end	=	max(Dur) + 200;
end
nt     =	t_end - t_beg +1;  %each entry 1 ms
bin    =	10;    %ms

smooth.wsize = round(nt/200);					%window size for gaussian smoothing of histo for plotting
smooth.cutoff = 20;								%cutoff for the gaussian smoothing
smooth.stdev = Info.fs/(2*pi*smooth.cutoff);	%std for gaussian smoothing of histo for plotting

% Set up figure 
nSubPlots = 2;
hS = zeros(numel(stim),nSubPlots);
cnt		=	0;
CNT		=	nan(numel(stim),1);
cntt	=	0;
CNTT	=	nan(numel(stim),1);
% hF(ks) = figure; hold on
% scrsz = get(0,'ScreenSize');
xx		=	[0 dur];
maxy	=	(10*numel(stim))*1.1;
x       =	[xx fliplr(xx)];
y       =	[maxy maxy 0 0];
% patch(x,y,[0.80 0.80 0.80]); hold on

SR		=	nan(numel(stim),1);
SE		=	nan(numel(stim),1);
VS		=	nan(numel(stim),1);

for ks = 1:numel(stim)
    % Get spiketimes for this stim
	tr_this_stim = stim(ks).tr_idx;
%     if ks == 2
% 		tr_this_stim	=	tr_this_stim(3:end);
% 	end
    
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
	DUR(ks,1)	=	{dur};
	
	delay		=	unique(Delay(tr_this_stim));
	
    hist_raw = sum(hist_raw,1) / it;
    hist_bin = sum(reshape(hist_raw, bin, nt/bin),1)/(bin/1000);
    hist_smooth = smoothts(hist_bin,'g', smooth.wsize, smooth.stdev);

    %---Get Spike Rate---%
	[spkrate,se,Spk,spkdisp,spkdispsd]	=	getspkerate(raster_y,raster_x,dur,delay,Mdur,Sdur);
	stopstim	=	200 + Mdur + delay + Sdur;

	start	=	200 + Mdur + delay;
	stop	=	stopstim;

	spel		=	Spk > start & Spk < stop;
	Spk			=	Spk(spel);
	ISI			=	uISI;

	VS(ks,1)	=	vectorstrength(Spk,ISI);
	NReps		=	max(raster_y);
% 	sel			=	raster_x > 0 & raster_x < dur;
% 	NSpikes		=	sum(sel);
% 	SE(ks,1)	=	getstd(raster_y,raster_x);

	SPKS(ks,1)			=	{raster_x};
	SpikeTrial(ks,1)	=	{raster_y};
if( isempty(se) )
	se			=	NaN;
end
	SE(ks,1)	=	se;
	SR(ks,1)	=	spkrate;	%---Hz---%
	SpkDisp(ks,1)	=	spkdisp;
	SpkDispSD(ks,1)	=	spkdispsd;
% 	SR(ks,1)	=	NSpikes/NReps;
	
    % Plot raster
	figure(1)
	subplot(1,3,1)
	if( ~isempty(cnt) )
		sigstart		=	200 + Mdur + unique_stim(ks,3);
		plot([sigstart sigstart],[cnt cnt + NReps],'r-','LineWidth',2)
		hold on
		raster_Y		=	raster_y + cnt;
		cnt				=	cnt + 0.50;
		CNT(ks,1)		=	cnt;
		if( ks > 1 )
			plot([-200 2000],[cnt cnt],'k-')
		end
		hold on
		if( ks == 1 )
			plot(  raster_x  ,  raster_Y  , 'k.','MarkerSize',6)
		else
			plot(  raster_x  ,  raster_Y  , 'k.','MarkerSize',6)
		end
		cnt				=	cnt + NReps;
		Ylabel(ks,:)	=	{['M: ' num2str(unique_stim(ks,1)) ' delay: ' num2str(unique_stim(ks,3)) ]};
	end
	xlim([-20 1000])
	
	RASTERS(ks,1)	=	{raster_y};
	
    % PSTH
	figure(1)
	subplot(1,3,2)
	CNTT(ks,1)	=	cntt;
	maxx		=	nanmax(hist_bin);
	normhist	=	hist_bin/maxx;
	normhist	=	normhist + cntt;
	msX			=	t_beg:bin:t_end;
	[xx,yy]		=	stairs(msX,normhist);
	plot([-200 2000],[cntt cntt],'k-')
	hold on
	xlim([-20 1000])
	
	plot([sigstart sigstart],[cntt cntt + 1.10],'r-')
	hold on
	
	if( ks == 1 )
		plot( xx  , yy , 'k-', 'LineWidth', 1)
% 		bar(msX,normhist,'r')
	else
		plot( xx  , yy , 'k-', 'LineWidth', 1)
% 		bar(msX,normhist,'k')
	end
	cntt			=	cntt + 1.10;

%     % SAVE FIGURE
%     
%     savedir  = '/Users/kpenikis/Documents/SanesLab/Data/processed_data';
%     savename = sprintf('%s_%s_raster_ch%i_clu%i_stim%i',subject,session,channel,clu,ks);
%     print(hF(ks),'-depsc',fullfile(savedir,subject,'^rasters',savename))
%     pause
end
figure(1)
subplot(1,3,1)
plot([0 0],[0 cnt],'k--'); hold on
set(gca,'FontSize',16)
set(gca, 'XLim', [t_beg t_end])
xlabel( 'Time (ms)')
set(gca,'XTick',0:400:t_end,'XTickLabel',0:400:t_end);
% xlim([-205 1205])
% xlim([-205 505])
xlim([-205 t_end])
ylabel('AM Rate (Hz)')

set(gca,'YTick',CNT,'YTickLabel',Ylabel);
if( ~isempty(cnt) )
	ylim([0 cnt])
end
hold off
box on
if( clu(1,2) == 2 )
	title(['Ch: ' num2str(channel) '; AMRate: ' num2str(unique_stim(ks,2)) ' Hz ; SU'])
else
	title(['Ch: ' num2str(channel) '; AMRate: ' num2str(unique_stim(ks,2)) ' Hz ; MU'])
end
% axis square

subplot(1,3,2)
plot([0 0],[0 20000],'k--'); hold on
set(gca,'FontSize',16)
set(gca, 'XLim', [t_beg t_end])
xlabel( 'Time (ms)')
set(gca,'XTick',0:400:t_end,'XTickLabel',0:400:t_end);
% xlim([-205 1205])3
xlim([-205 t_end])
ylabel('AM Rate (Hz)')
set(gca,'YTick',CNTT,'YTickLabel',Ylabel);
ylim([0 cntt])
hold off
title(['Normalized PSTH; bin width: ' num2str(bin) ' ms'])
% axis square

keyboard

figure(1)
%---Spike Rate---%
AMaxis		=	[4 16 64 256 1024];
AM			=	unique(Freq);
UnMod		=	SR(1);
UnMod		=	repmat(UnMod,length(AM)-1,1);
ymaxx		=	(max(SR) + max(SE))*1.1;
jitAM		=	AM*1.05;
subplot(3,3,3)
plotSD(SE,SR,AM)
s(1)=plot(jitAM(2:end),UnMod,'ro-','LineWidth',2,'MarkerSize',10,'MarkerFaceColor','w');
hold on
plot(AM(2:end),SR(2:end),'ko-','LineWidth',2,'MarkerSize',10,'MarkerFaceColor','w')
hold on
plot([-2 0 2 4],[nan nan nan nan])
set(gca,'FontSize',16)
set(gca,'xscale','log')
xlim([-2 2048])
xlabel( 'AM Rate (Hz)')
set(gca,'XTick',AMaxis,'XTickLabel',AMaxis)
ylabel('Firing Rate (Hz)')
% set(gca,'YTick',CNTT,'YTickLabel',unique(Freq));
ylim([0 ymaxx])
% title('Firing Rate')
axis square
legend(s,'UnMod','Location','NorthEast')
legend('boxoff')

%---D-Prime---%
dprimes		=	calculatedprime(SR,SE,AMRate);
dprimess	=	calculatedprime2(RASTERS,AMRate);
SpkDispDP	=	calculatedprime(SpkDisp,SpkDispSD,AMRate);
X		=	[2;AM(2:end)];
XX		=	[X;2048];
thres	=	ones(1,length(XX));
subplot(3,3,6)
dd(1)=plot(AM(2:end),abs(dprimes),'ko-','LineWidth',2,'MarkerSize',10,'MarkerFaceColor','w');
hold on
% dd(2)=plot(AM(2:end),abs(dprimess),'o-','Color',[0.50 0.50 0.50],'LineWidth',2,'MarkerSize',10,'MarkerFaceColor','w');
plot(XX,thres,'k--')
hold on
plot([-2 0 2 4],[nan nan nan nan])
set(gca,'FontSize',16)
set(gca,'xscale','log')
xlim([-2 2048])
xlabel( 'AM Rate (Hz)')
set(gca,'XTick',AMaxis,'XTickLabel',AMaxis)
set(gca,'YTick',0:1:3,'YTickLabel',0:1:3)
ylabel('Neural d-prime')
% title('Neural D-Prime')
ylim([0 3.1])
axis square
% legend(dd,[{'norm. spk rate'};{'trial-by-trial'}],'Location','NorthEast')
% legend('boxoff')

%---Vector Strength---%
subplot(3,3,9)
plot(AM(2:end),VS(2:end),'ko-','MarkerFaceColor','w','MarkerSize',10,'LineWidth',2)
hold on
plot([-2 0 2 4],[nan nan nan nan])
set(gca,'FontSize',16)
set(gca,'xscale','log')
xlim([-2 2048])
xlabel( 'AM Rate (Hz)')
set(gca,'XTick',AMaxis,'XTickLabel',AMaxis)
set(gca,'YTick',0:0.25:1,'YTickLabel',0:0.25:1)
ylabel('Vector Strength')
% title('Vector Strength')
ylim([0 1])
axis square

%---STORE VARIABLES---%
DATA.AMRate		=	AMRate;
DATA.SpkRate	=	SR;
DATA.StdDev		=	SE;
DATA.VS			=	VS;
DATA.DPrime		=	dprimes;
DATA.Rasters	=	SPKS;
DATA.SpikeTrial	=	SpikeTrial;
DATA.Dur		=	DUR;
DATA.SpkDisp	=	SpkDisp;
DATA.SpkDispSD	=	SpkDispSD;
DATA.SpkDispDP	=	abs(SpkDispDP);

%---Locals---%
function [spkrate,se,ST,SpkDisp,SpkDispSD] = getspkerate(trials,spktimes,dur,delay,Mdur,Sdur)
NTrials		=	max(unique(trials));
SDis		=	nan(NTrials,1);
SRate		=	nan(NTrials,1);
ST			=	[];
start		=	200 + Mdur + delay;
stop		=	start + Sdur;
for i=1:NTrials
	sel		=	trials == i;
	st		=	spktimes(sel);
	d		=	dur(i);
% 	d		=	500;
	zel		=	st > start & st < stop;
	
	S		=	st(zel);
	dis		=	diff(S);
	SDis(i,1)	=	nanmean(dis);
	
	spks	=	sum(zel);
	SR		=	(1000/d)*spks;
	SRate(i,1)	=	SR;
	
	if( i == 1 )
		ST	=	st;
	else
		ST	=	[ST st];
	end
end
se			=	nanstd(SRate)/sqrt(NTrials);
% se			=	nanstd(SRate);
spkrate		=	nanmean(SRate);
SpkDisp		=	nanmean(SDis);
SpkDispSD	=	nanstd(SDis);

function SE = getstd(Trials,spktimes)
NTrials		=	nanmax(Trials);
spks		=	nan(NTrials,1);
for i=1:NTrials
	sel		=	Trials == i;
	S		=	spktimes(sel);
	xel		=	S > 0 & S < 1000;
	spks(i,1)	=	sum(xel);
end
SE		=	dround(nanstd(spks)/sqrt(NTrials));

function plotSD(SD,SR,AM)
N			=	length(AM);
Uup			=	SR(1) + SD(1);
% UP			=	repmat(Uup,N,1);
Udn			=	SR(1) - SD(1);
% DN			=	repmat(Udn,N,1);

% plot(AM(2:end),Uup,'r:')
% hold on
% plot(AM(2:end),Udn(2:end),'r:')
jitAM		=	AM*1.05;
for i=2:N
	up		=	SR(i) + SD(i);
	dn		=	SR(i) - SD(i);
	plot([AM(i) AM(i)],[dn up],'k-','LineWidth',1)
	hold on
	
	plot([jitAM(i) jitAM(i)],[Uup Udn],'r-','LineWidth',1)
end

function ISI = getISI(Freq,Dur)
uFreq		=	unique(Freq);
ISI			=	(1./uFreq)*10^3;

function dprimes = calculatedprime(SR,SD,AMRate)
sel			=	AMRate == 0;
NOGO		=	[SR(sel,1) SD(sel,1)];
GO			=	[SR(~sel,1) SD(~sel,1)];
commonstds	=	(NOGO(1,2) + GO(:,2))/2;
N			=	length(GO);
dprimes		=	nan(N,1);
for i=1:N
	dprimes(i,1)	=	(GO(i,1)-NOGO(1,1))./commonstds(i,1);
end

function dprimes = calculatedprime2(Raster,AMRate)
sel			=	AMRate == 0;
NOGO		=	Raster(sel);
NOGO		=	NOGO{1};
uNogo		=	unique(NOGO);
Nnogo		=	length(uNogo);
NoiseVec	=	nan(1,Nnogo);
for i=1:Nnogo
	zel				=	NOGO == uNogo(i);
	NoiseVec(1,i)	=	sum(zel);
end

GO			=	Raster(~sel);
Namrate		=	length(AMRate)-1;
SignalVec	=	nan(Namrate,Nnogo);
dprimes		=	nan(Namrate,1);
for j=1:Namrate
	go		=	GO{j};
	uGo		=	unique(go);
	Ngo		=	length(uGo);
	for k=1:Ngo
		xel	=	go == uGo(k);
		SignalVec(j,k)	=	sum(xel);
	end
	dprimes(j,1)	=	getdprime(NoiseVec,SignalVec(j,:));
end
