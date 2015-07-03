function [trl,event] = trialfun_tdt(cfg)
% [trl,event] = trialfun_tdt(cfg)
% 
% Returns trl and event structures for use with FieldTrip
%
% cfg.tank          ...     registered tank name (or full path to tank)
%    .block         ...     scalar integer of a single tank block to process
%    .blockroot     ...     root name of the block (eg, 'Block-')
%  
%    .trialdef.eventtype  ... name of an event (eg, 'BitM'). '?' will get you a list of events
%    .trialdef.eventvalue ... value(s) of interest for the event
%    .trialdef.prestim    ... onset time (seconds) of window relative to
%                             event trigger (value > 0 means before
%                             trigger)
%    .trialdef.poststim   ... offset time (seconds) of window relative to event trigger
%    .trialdef.fsample    ... sampling rate to calculate event and trigger
%                             samples
%
% DJS 2013

% check cfg structure
if ~isfield(cfg,'tank'),    error('Missing tank name in cfg');      end
if ~isfield(cfg,'blocks'),  error('Missing blocks number in cfg');  end
if ~isfield(cfg,'blockroot'), cfg.blockroot = [];                   end
if ~isfield(cfg.trialdef,'eventtype'),  cfg.eventtype = [];         end
if ~isfield(cfg.trialdef,'eventvalue'), cfg.eventvalue = [];        end
if ~isfield(cfg.trialdef,'prestim'),    cfg.prestim  = 0;           end
if ~isfield(cfg.trialdef,'poststim'),   cfg.poststim = 1;           end
if ~isfield(cfg.trialdef,'fsample'),    
    error('trialfun_tdt needs the sampling rate to be specified in cfg.trialdef.fsample'); 
end

Fs = cfg.trialdef.fsample;

if cfg.trialdef.eventtype(1) == '?'
    cfg.usemym = false;
    cfg.silently = true;
    tinfo = getTankData(cfg);
    fprintf('\n\n* Event types and values for tank ''%s'',\n\t\t\tblock ''%s-%d''\n', ...
        cfg.tank,cfg.blockroot,cfg.blocks)
    for i = 1:length(tinfo.paramspec)-1
        fprintf('\t''%s'' : %s\n',tinfo.paramspec{i},mat2str(unique(tinfo.epochs(:,i))))
    end
    fprintf('\n\n')
    trl   = [];
    event = [];
    return


else
    try
        % get event structure
        event = ft_read_event_tdt(cfg.tank,cfg.blocks,cfg.blockroot, ...
            cfg.trialdef.eventtype,cfg.trialdef.eventvalue,Fs);
    catch %#ok<CTCH>
        % Ad hoc solution to convert original event codes to BitM code.  This
        % is a fix for a specific experiment.
        fprintf(['\n* There was an error evaluating the default event function (', ...
            'ft_read_event_tdt).\nCalling a backup ad hoc function (ft_read_event_tdt_2BitM)' ,...
            'instead *\n'])
        event = ft_read_event_tdt_2BitM(cfg.tank,cfg.blocks,cfg.blockroot, ...
            cfg.trialdef.eventtype,cfg.trialdef.eventvalue,Fs);
    end
end

% convert prestim and poststim parameters to samples
sprestim  = round(cfg.trialdef.prestim*Fs);
spoststim = round(cfg.trialdef.poststim*Fs);

esamps = [event.sample];

%  The trial definition "trl" is an Nx3 matrix, N is the number of trials.
%   The first column contains the sample-indices of the begin of each trial 
%   relative to the begin of the raw data, the second column contains the 
%   sample-indices of the end of each trial, and the third column contains 
%   the offset of the trigger with respect to the trial. An offset of 0 
%   means that the first sample of the trial corresponds to the trigger. A 
%   positive offset indicates that the first sample is later than the trigger, 
%   a negative offset indicates that the trial begins before the trigger.

trl(:,1) = esamps-sprestim;
trl(:,2) = esamps+spoststim-1;
trl(:,3) = -sprestim;
trl(:,4) = [event.value];

ind = trl(:,1) < 1 | trl(:,1)+trl(:,3) < 1;
if any(ind)
    warning('%d of %d trials start before the recording. They were removed',sum(ind),length(ind))
    trl(ind,:) = [];
end








