%% Example Plot LFPs
cfg = [];
cfg.linewidth = 2;
cfg.channel   = 5;
cfg.interactive = 'no';
figure('windowstyle','docked')
ft_singleplotER(cfg,visLFP,audLFP);

hold on
plot([0 0],ylim,'--','color',[0.6 0.6 0.6]);
hold off








%% Example with SPIKEs

cfg = [];
cfg.binsize = 0.001;
cfg.latency  = [0 0.5];
PSTH = ft_spike_psth(cfg,audSPIKE);

clf
cfg              = [];
% scfg.topplotfunc  = 'line'; % plot as a line
cfg.spikechannel = {'ch05_00','ch05_u01'};
cfg.latency      = 'maxperiod';
scfg.errorbars   = 'std'; % plot with the standard deviation
cfg.interactive  = 'no'; % toggle off interactive mode
ft_spike_plot_raster(cfg, audSPIKE, PSTH);

%% Example with Spike Density
cfg = [];
cfg.timwin = [-0.01 0.01];
cfg.winfunc = 'gauss';
% scfg.winfuncopt = 0.001;
cfg.keeptrials = 'yes';
cfg.timwin = [0 0.4];
PSTH = ft_spikedensity(cfg,audSPIKE);

clf
cfg              = [];
cfg.latency      = [0 0.4]; % <- this parameter doesn't work
cfg.topplotfunc  = 'line'; % plot as a line
cfg.spikechannel = SPIKE.label([5 6]);
cfg.errorbars    = 'sem'; % plot with the standard deviation
cfg.interactive  = 'no'; % toggle off interactive mode
ft_spike_plot_raster(cfg, audSPIKE, PSTH);

%% freq analysis on spike trains
cfg = [];
cfg.method = 'wavelet';
cfg.foi = logspace(log10(2),log10(1000),500);
cfg.toi = -0.5:0.0001:0.5;
cfg.pad = 'maxperlen';
% cfg.trials = randi(length(audSPIKE.trialinfo),20,1);
freq = ft_freqanalysis(cfg,audSPIKE);

%%
cfg = [];
cfg.channel = 6;
cfg.baseline = [-0.5 0];
cfg.baselinetype = 'relative';
cfg.xlim = [0 0.4];
cfg.colorbar = 'no';
cfg.interactive = 'no';
ft_singleplotTFR(cfg,freq);

%%
cfg = [];
cfg.method = 'MTMCONVOL';
cfg.foi = 5:150;
cfg.toi = -0.5:0.01:0.5;
cfg.tapsmofrq = round(logspace(0,1,length(cfg.foi)));
cfg.taper = 'dpss';
cfg.t_ftimwin = 4./cfg.foi;
freq = ft_freqanalysis(cfg,audSPIKE);

