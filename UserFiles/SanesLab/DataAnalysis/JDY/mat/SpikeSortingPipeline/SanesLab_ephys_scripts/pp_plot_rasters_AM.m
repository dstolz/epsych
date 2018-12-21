function pp_plot_rasters_AM(path, subject, session, block, channel, clu)
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
Freq		=	[Stim.Rate]';
% Freq		=	Stim.Freq;
dBSPL		=	[Stim.dB]';
Dur			=	[Stim.stimDur]';
dur			=	max(unique(Dur));
Behave		=	[Stim.behaving]';
Par_matrix	=	[Freq dBSPL Dur Behave] ;
[unique_stim, unique_IDs, StimID] = unique(Par_matrix,'rows','sorted');


% Make stim struct
stim = struct();    behav_state = {'passive' 'active'};
for ks = 1:size(unique_stim,1)
    
    stim(ks).tr_idx   = find(StimID==StimID(unique_IDs(ks)));
    stim(ks).stim_str = sprintf('ch %s unit %s\n%i Hz  |  %2.3g dBSPL\n%2.4g ms  | %s',...
        num2str(channel), num2str(clu), ...
        unique_stim(ks,1),unique_stim(ks,2),unique_stim(ks,3),...
        behav_state{unique_stim(ks,end)+1});
end


%%

% GET SPIKE TIMES
spikes = Spikes.sorted(channel);
unit_in = find(spikes.assigns==clu);
spiketimes = round(spikes.spiketimes(unit_in) * 1000);  %ms
spiketrials = spikes.trials(unit_in); 

if isempty(spiketimes)
    error('no spike events found for this clu')
elseif spikes.labels(spikes.labels(:,1)==clu,2) == 4
    warning('  this clu is labeled as noise. are you sure you want to plot?')
    keyboard
end


% Set up raster/histo plot parameters
t_beg  = -199;  %ms
t_end  =  1000;   %ms
nt     = t_end - t_beg +1;  %each entry 1 ms
bin    = 20;    %ms

smooth.wsize = round(nt/200);   %window size for gaussian smoothing of histo for plotting
smooth.cutoff = 20;   %cutoff for the gaussian smoothing
smooth.stdev = Info.fs/(2*pi*smooth.cutoff); %std for gaussian smoothing of histo for plotting

% Set up figure 
nSubPlots = 2;
hS = zeros(numel(stim),nSubPlots);
cnt		=	0;
CNT		=	nan(numel(stim),1);
cntt	=	0;
CNTT	=	nan(numel(stim),1);
hF(ks) = figure; hold on
scrsz = get(0,'ScreenSize');
xx		=	[0 dur];
maxy	=	(10*numel(stim))*1.1;
x       =	[xx fliplr(xx)];
y       =	[maxy maxy 0 0];
% patch(x,y,[0.80 0.80 0.80]); hold on

SR		=	nan(numel(stim),1);
SD		=	nan(numel(stim),1);

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
    
    hist_raw = sum(hist_raw,1) / it;
    hist_bin = sum(reshape(hist_raw, bin, nt/bin),1)/(bin/1000);
    hist_smooth = smoothts(hist_bin,'g', smooth.wsize, smooth.stdev);

    
    %---Get Spike Rate---%
	NReps		=	max(raster_y);
	sel			=	raster_x > 0 & raster_x < dur;
	NSpikes		=	sum(sel);
	SE(ks,1)	=	getstd(raster_y,raster_x);
	if( ~isempty(NReps) )
		SR(ks,1)=	NSpikes/NReps;
	end
	
    % Plot raster
	subplot(1,3,1)
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
		plot(  raster_x  ,  raster_Y  , 'k.','MarkerSize',6)
	end
	if( ~isempty(NReps) )
		cnt				=	cnt + NReps;
	end
	
    % PSTH
	subplot(1,3,2)
	CNTT(ks,1)	=	cntt;
	maxx		=	nanmax(hist_bin);
	normhist	=	hist_bin/maxx;
	normhist	=	normhist + cntt;
	msX			=	t_beg:bin:t_end;
	[xx,yy]		=	stairs(msX,normhist);
	plot([-200 2000],[cntt cntt],'k-')
	hold on
	if( ks == 1 )
		plot( xx  , yy , 'r-', 'LineWidth', 1)
	else
		plot( xx  , yy , 'k-', 'LineWidth', 1)
	end
	cntt			=	cntt + 1.10;

%     % SAVE FIGURE
%     
%     savedir  = '/Users/kpenikis/Documents/SanesLab/Data/processed_data';
%     savename = sprintf('%s_%s_raster_ch%i_clu%i_stim%i',subject,session,channel,clu,ks);
%     print(hF(ks),'-depsc',fullfile(savedir,subject,'^rasters',savename))
%     pause
end
subplot(1,3,1)
plot([0 0],[0 20000],'k--'); hold on
set(gca,'FontSize',16)
set(gca, 'XLim', [t_beg t_end])
xlabel( 'Time (ms)')
set(gca,'XTick',-200:200:1000,'XTickLabel',-200:200:1000);
xlim([-205 1005])
ylabel('AM Rate (Hz)')
set(gca,'YTick',CNT,'YTickLabel',unique(Freq));
ylim([0 max(CNT)*1.1])
hold off
box on
title(['Ch: ' num2str(channel) '; dBSPL: ' num2str(unique_stim(ks,2))])
% axis square

subplot(1,3,2)
plot([0 0],[0 20000],'k--'); hold on
set(gca,'FontSize',16)
set(gca, 'XLim', [t_beg t_end])
xlabel( 'Time (ms)')
set(gca,'XTick',-200:200:1000,'XTickLabel',-200:200:1000);
xlim([-205 1005])
ylabel('AM Rate (Hz)')
set(gca,'YTick',CNTT,'YTickLabel',unique(Freq));
ylim([0 cntt])
hold off
title(['Normalized PSTH; bin width: ' num2str(bin) ' ms'])
% axis square

%---Spike Rate---%
AM			=	unique(Freq);
UnMod		=	SR(1);
UnMod		=	repmat(UnMod,length(AM),1);
ymaxx		=	(max(SR) + max(SE))*1.1;
subplot(1,3,3)
plot(AM,UnMod,'r--','LineWidth',1)
hold on
plotSD(SE,SR,AM)
plot(AM(2:end),SR(2:end),'ko-','LineWidth',2,'MarkerSize',10,'MarkerFaceColor','w')
hold on
plot([-2 0 2 4],[nan nan nan nan])
set(gca,'FontSize',16)
set(gca,'xscale','log')
xlim([-2 2048])
xlabel( 'AM Rate (Hz)')
set(gca,'XTick',AM(2:end),'XTickLabel',AM(2:end));
ylabel('Firing Rate (Hz)')
% set(gca,'YTick',CNTT,'YTickLabel',unique(Freq));
ylim([0 ymaxx])
title('Firing Rate')
axis square


%---Locals---%
function SE = getstd(Trials,spktimes)
NTrials		=	nanmax(Trials);
spks		=	nan(NTrials,1);
for i=1:NTrials
	sel		=	Trials == i;
	S		=	spktimes(sel);
	xel		=	S > 0 & S < 1000;
	spks(i,1)	=	sum(xel);
end
if( ~isempty(spks) )
	SE		=	dround(nanstd(spks)/sqrt(NTrials));
else
	SE		=	NaN;
end

function plotSD(SD,SR,AM)
N			=	length(AM);
up			=	SR(1) + SD(1);
UP			=	repmat(up,N,1);
dn			=	SR(1) - SD(1);
DN			=	repmat(dn,N,1);
plot(AM,UP,'r:')
hold on
plot(AM,DN,'r:')
for i=2:N
	up		=	SR(i) + SD(i);
	dn		=	SR(i) - SD(i);
	plot([AM(i) AM(i)],[dn up],'k-')
	hold on
end

