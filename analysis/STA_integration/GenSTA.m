function varargout = GenSTA(ST,P,PVar,opts,varargin)
% STA = GenSTA(ST,P,PVar,opts);
% [STA,raster] = GenSTA(ST,P,PVar,opts);
% [STA,raster,Levels] = GenSTA(ST,P,PVar,opts);
% [STA,...] = GenSTA(ST,P,PVar,opts,'Parameter',value);
%
% Generate structure for STA toolbox for information theory analysis.  See
% www.neuroanalysis.org for more info.
%
% > ST is a vector of raw spike times.  See DB_Spiketimes.
% > P is a parameter structure.  See DB_GetParams.
% > opts is a structure of options for the call to the STA function metric
% 
% 
% Optional Parameter,'value' Inputs...
% > 'Levels' are the stimulus categories to compare. Default is all values
% from P.lists.(PVar).
% > 'fullwin' is a 2-value array (ex: [0 0.5]) with the full window for the
% stimulus-triggered raster.  This is only needed when plotting raster
% (i.e., plotdata = true).  Otherwise, the opts.start_time and
% opts.end_time are used.
% 
% Some values for opts...
%   clear opts
%   opts.clustering_exponent        = -2;
%   opts.unoccupied_bins_strategy   = -1;
%   opts.metric_family              = 0; % 0: D^spike; 1: D^interval
%   opts.parallel                   = 1;
%   opts.possible_words             = 'unique';
%   opts.start_time = 0;
%   opts.end_time   = 0.5;
%   opts.shift_cost = [0 2.^(0:0.1:10)];
%   opts.entropy_estimation_method = {'jack'};
% 
% See also, metric, DB_GetSpiketimes, DB_GetParams
% 
% Daniel.Stolzberg@gmail.com 2014

Levels   = P.lists.(PVar);
fullwin  = [opts.start_time opts.end_time];

ParseVarargin({'Levels','fullwin'},[],varargin);


if nargin == 2 || isempty(Levels)
    Levels = P.lists.(PVar);
end

STA.M = int32(length(Levels));
STA.N = int32(1);

STA.sites(1).label          = {'STA'};
STA.sites.recording_tag     = {'episodic'};
STA.sites.time_scale        = 1;
STA.sites.time_resolution   = 1/P.spike_fs; % ? 0.001
STA.sites.si_unit           = 'none';
STA.sites.si_prefix         = 1;

raster = {[]};
values = [];

k = 1;
for m = 1:STA.M
    STA.categories(m,1).label = {sprintf('%s_%g',PVar,Levels(m))};
    idx = find(Levels(m) == P.VALS.(PVar));
    STA.categories(m).P = int32(length(idx));
    for p = 1:STA.categories(m).P
        x = idx(p);
        
        STA.categories(m).trials(p,1).start_time = fullwin(1);
        STA.categories(m).trials(p).end_time     = fullwin(2);
        
        ind = ST >= P.VALS.onset(x)+fullwin(1) & ST <= P.VALS.onset(x)+fullwin(2);
        
        STA.categories(m).trials(p).Q    = int32(sum(ind));
        STA.categories(m).trials(p).list = ST(ind)-P.VALS.onset(x);
        
        raster{k} = STA.categories(m).trials(p).list;
        values(k) = Levels(m); %#ok<AGROW>
        k = k + 1;
    end
    
end


varargout{1} = STA;
varargout{2} = raster;
varargout{3} = values;

