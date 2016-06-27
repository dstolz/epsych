function pp_plot_rasters(subject, session, channel, clu)
%
%  pp_plot_rasters(subject, session, channel, clu)  
%    Plots a raster and psth for each unique stimulus. Clu is the label
%    given by UMS (not an index), found in Spikes.sorted.labels.
%
%  KP, 2016-04; last updated 2016-04
% 

set(0,'DefaultAxesFontSize',14)


% Load data files

datadir  = '/Users/kpenikis/Documents/SanesLab/Data/processed_data';
fprintf('\nloading data...\n')
filename = sprintf( '%s_sess-%s_Spikes',subject,session); load(fullfile(datadir,subject,filename));
filename = sprintf( '%s_sess-%s_Info'  ,subject,session); load(fullfile(datadir,subject,filename));
filename = sprintf( '%s_sess-%s_Stim'  ,subject,session); load(fullfile(datadir,subject,filename));


%%%  ------------------------------------------
%%%  |  Binary code for harmonics
%%%  |    
%%%  |      14 :      0   1   1   1   0
%%%  |       1 :      1   0   0   0   0
%%%  |       3 :      1   1   0   0   0
%%%  |       7 :      1   1   1   0   0
%%%  |      15 :      1   1   1   1   0
%%%  | 
%%%  ------------------------------------------


%%

% GET STIM INFO

% Find unique stimuli
Par_matrix = [[Stim.Freq]' [Stim.FMdepth]' [Stim.dB]' [Stim.stimDur]' [Stim.Harms]' [Stim.behaving]'] ;
[unique_stim, unique_IDs, StimID] = unique(Par_matrix,'rows','sorted');


% Make stim struct
stim = struct();    behav_state = {'passive' 'active'};
for ks = 1:size(unique_stim,1)
    
    stim(ks).tr_idx   = find(StimID==StimID(unique_IDs(ks)));
    stim(ks).stim_str = sprintf('ch %s unit %s\n%i Hz  |  %2.3g depth  |  %2.3g dBSPL\n%2.4g ms  |  Harm code %i  |  %s',...
        num2str(channel), num2str(clu), ...
        unique_stim(ks,1),unique_stim(ks,2),unique_stim(ks,3),...
        unique_stim(ks,4),unique_stim(ks,5),behav_state{unique_stim(ks,6)+1});

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
t_end  =  500;   %ms
nt     = t_end - t_beg +1;  %each entry 1 ms
bin    = 20;    %ms

smooth.wsize = round(nt/200);   %window size for gaussian smoothing of histo for plotting
smooth.cutoff = 20;   %cutoff for the gaussian smoothing
smooth.stdev = Info.fs/(2*pi*smooth.cutoff); %std for gaussian smoothing of histo for plotting



% Set up figure 
nSubPlots = 2;
hS = zeros(numel(stim),nSubPlots);

for ks = 1:numel(stim)
    
    % Set current figure/subplot handles
    
    hF(ks) = figure; hold on
    scrsz = get(0,'ScreenSize');
    set(hF(ks),'Position',[1 (scrsz(4)/2) 3*scrsz(3)/4 scrsz(4)/2],...
    'Nextplot','add');

    for isp = 1:nSubPlots
        hS(ks,isp)=subplot(nSubPlots,1,isp);
        set(hS(ks,isp),'Nextplot','add');
    end


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

    
    
    % Plot this stimulus
    
    suptitle(stim(ks).stim_str)
    % raster
    subplot(hS(ks,1)); hold on
    plot([0 0],[-30 30],'k:')
    plot([unique_stim(ks,4) unique_stim(ks,4)],[-30 30],'k:')
    plot(  raster_x  ,  raster_y  , 'k.','MarkerSize',12)
    axis tight
    set(gca, 'XLim', [t_beg t_end], 'XTick',[], 'YLim', ([0 1+it]))
    ylabel('Trials')
    % psth
    subplot(hS(ks,2)); hold on
    plot( t_beg:bin:t_end  , hist_bin , 'k', 'LineWidth', 2)
    set(gca, 'XLim', [t_beg t_end])
    xlabel( 'Time (ms)')
    ylabel('Spikes/sec')
    hold off
    
    
    % SAVE FIGURE
    
    savedir  = '/Users/kpenikis/Documents/SanesLab/Data/processed_data';
    savename = sprintf('%s_%s_raster_ch%i_clu%i_stim%i',subject,session,channel,clu,ks);
    print(hF(ks),'-depsc',fullfile(savedir,subject,'^rasters',savename))
    
end



% Add: save a struct of fully processed data, with just raster & stim info









end

