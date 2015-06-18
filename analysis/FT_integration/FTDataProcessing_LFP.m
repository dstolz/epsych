%% Set some variables
tank        = 'TankName';
block       = 1;

%% Read continuous LFP from tank
cfg = [];
cfg.tank   = tank;
cfg.blocks = block;

fullLFP = ft_read_lfp_tdt(cfg.tank,cfg.blocks);

%% Call custom trial function (trialfun_tdt) to segment continuous LFP data
cfg = [];
cfg.tank      = tank;
cfg.blocks    = block;
cfg.trialfun  = 'trialfun_tdt';
cfg.trialdef.prestim    = 0.25; % <-- positive value means trial begins before trigger
cfg.trialdef.poststim   = 1;
cfg.trialdef.eventtype  = 'BitM';
cfg.trialdef.eventvalue = 16;     % <-- set event value 
cfg.trialdef.fsample    = fullLFP.fsample; % <-- must specify appropriate sampling rate in trial definition

tcfg = ft_definetrial(cfg);
visLFP = ft_redefinetrial(tcfg,fullLFP);

cfg.trialdef.eventvalue = 32;    % <-- set event value 
tcfg = ft_definetrial(cfg);
audLFP = ft_redefinetrial(tcfg,fullLFP);

% clear fullLFP

