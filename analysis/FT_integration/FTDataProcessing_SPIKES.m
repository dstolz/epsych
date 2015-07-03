%% Read SPIKEs from Plexon file
[plxfile,path2plx] = uigetfile({'*.plx','Plexon file (*.plx)'}, ...
     'Locate Plexon File');
SPIKE = ft_read_spike(fullfile(path2plx,plxfile));

%% Read SPIKES directly from TDT Tank (with sort codes if available)
cfg = [];
cfg.tank     = tank;
cfg.block    = block;
cfg.blockroot = [tank '-'];
cfg.event    = 'eNeu';
cfg.sortname = 'FullBayes';
SPIKE = ft_read_spikes_tdt(cfg);


%% Call custom trial function (trialfun_tdt) to segment SPIKE data
cfg = [];
cfg.tank        = tank;
cfg.blocks      = block;
cfg.blockroot   = [tank '-'];
cfg.trialfun            = 'trialfun_tdt';
cfg.trialdef.prestim    = 0.5; % <-- positive value means trial begins before trigger
cfg.trialdef.poststim   = 0.5;
cfg.trialdef.eventtype  = 'BitM';
cfg.trialdef.eventvalue = 16;   % <-- set event value 
cfg.trialdef.fsample    = SPIKE.hdr.ADFrequency; % <-- must specify appropriate sampling rate in trial definition
cfg.timestampspersecond = SPIKE.hdr.ADFrequency;

tcfg = ft_definetrial(cfg);
visSPIKE = ft_spike_maketrials(tcfg,SPIKE);


cfg.trialdef.eventvalue = 32;
tcfg = ft_definetrial(cfg);
audSPIKE = ft_spike_maketrials(tcfg,SPIKE);



%% Do stuff with the waveforms if you like
cfg             = [];
cfg.fsample     = SPIKE.hdr.ADFrequency;
cfg.interpolate = 1; % keep the density of samples as is
cfg.align       = 'no';
cfg.rejectclippedspikes = 'yes';
[wave, SPIKECleaned] = ft_spike_waveform(cfg,SPIKE);


