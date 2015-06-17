%% DB2STA WAV
pvar = 'BuID';
subselection = [1:12];
tadjustments = [];

fullwin = [0 0.6];
clear opts
opts.clustering_exponent = -2;
opts.unoccupied_bins_strategy = -1;
opts.metric_family = 0; % 0: Dspike; 1: Dinterval
opts.parallel = 1;
opts.possible_words = 'unique';

opts.start_time = 0;
opts.end_time   = 0.6;
opts.shift_cost = [0 2.^(-2:13)];

%% DB2STA TSlew
pvar = 'NDel';  
subselection = [200 250 300];
tadjustments = [0.2 0.25 0.3];
% subselection = [];
% tadjustments = [];
fullwin = [0 1];

clear opts
opts.clustering_exponent = -2;
opts.unoccupied_bins_strategy = -1;
opts.metric_family = 0; % 0: Dspike; 1: Dinterval
opts.parallel = 1;
opts.possible_words = 'unique';

opts.start_time = 0;
opts.end_time   = 0.1;
opts.shift_cost = [0 2.^(-2:13)];

%% DB2STA RIF
pvar = 'Levl';  
subselection = [40 60 80];
% tadjustments = [0.2 0.25 0.3];
% subselection = [];
tadjustments = [];
fullwin = [0 0.5];

clear opts
opts.clustering_exponent = -2;
opts.unoccupied_bins_strategy = -1;
opts.metric_family = 0; % 0: Dspike; 1: Dinterval
opts.parallel = 1;
opts.possible_words = 'unique';

opts.start_time = 0.008;
opts.end_time   = 0.05;
% opts.shift_cost = [0 2.^(-2:13)];
opts.shift_cost = [0 logspace(-1,3,10)];


%%

IDs = getpref('DB_BROWSER_SELECTION');

units = mym(['SELECT v.unit,CONCAT(p.class,"-",c.channel,"-",v.unit) AS pool ', ...
             'FROM v_ids v ', ...
             'JOIN units u ON u.id = v.unit ', ...
             'JOIN channels c ON c.id = v.channel ', ...
             'JOIN class_lists.pool_class p ON p.id = u.pool ', ...
             'WHERE v.unit = {Si} ', ...
             'AND u.pool > 0 AND u.pool < 31 ', ...
             'ORDER BY c.channel,u.pool,v.unit'],IDs.units);
pool = units.pool;
unit = units.unit;


P = DB_GetParams(IDs.blocks);



if isempty(subselection), subselection = P.lists.(pvar); end

Levels = subselection;
onsets = P.lists.onset;

if isempty(tadjustments), tadjustments = zeros(size(Levels)); end

clear STA

STA.M = int32(length(Levels));
STA.N = int32(1);

st = DB_GetSpiketimes(unit)';

STA.sites(1).label        = pool;
STA.sites.recording_tag   = {'episodic'};
STA.sites.time_scale      = 1;
STA.sites.time_resolution = 1/P.spike_fs; % ? 0.001
STA.sites.si_unit = 'none';
STA.sites.si_prefix = 1;

for m = 1:STA.M
    STA.categories(m,1).label = {num2str(Levels(m),'%d')};
    idx = find(Levels(m) == P.VALS.(pvar));
    STA.categories(m).P = int32(length(idx));
    adjwin = fullwin + tadjustments(m);
    for p = 1:STA.categories(m).P
        x = idx(p);
        STA.categories(m).trials(p,1).start_time = fullwin(1);
        STA.categories(m).trials(p).end_time     = fullwin(2);
        ind = st >= P.VALS.onset(x) + adjwin(1) & st <= P.VALS.onset(x) + adjwin(2);
        STA.categories(m).trials(p).Q    = int32(sum(ind));
        STA.categories(m).trials(p).list = st(ind)-P.VALS.onset(x)-adjwin(1);
    end
    
end


statin_summ(STA);


%
clear out out_unshuf shuf out_unjk jk;
clear info_plugin info_tpmc info_jack info_unshuf info_unjk;
clear temp_info_shuf temp_info_jk;

figure;
% set(gcf,'name',['Metric ' dataset ' demo']); 

subplot(221);
staraster(STA,[opts.start_time opts.end_time]);
title('Raster plot');

% Simple analysis

opts.entropy_estimation_method = {'plugin','tpmc','jack'};
% opts.entropy_estimation_method = {'jack'};
% opts.variance_estimation_method = {'jack'};
[out,opts_used] = metric(STA,opts);

for q_idx=1:length(opts.shift_cost)
  info_plugin(q_idx) = out(q_idx).table.information(1).value;
  info_tpmc(q_idx) = out(q_idx).table.information(2).value;
  info_jack(q_idx) = out(q_idx).table.information(3).value;
end

subplot(222);
[max_info,max_info_idx]=max(info_plugin);
imagesc(out(max_info_idx).d);
xlabel('Spike train index');
ylabel('Spike train index');
title('Distance matrix at maximum information');

subplot(223);
plot(1:length(opts.shift_cost),info_plugin);
hold on;
plot(1:length(opts.shift_cost),info_tpmc,'--');
plot(1:length(opts.shift_cost),info_jack,'-.');
hold off;
set(gca,'xtick',1:2:length(opts.shift_cost));
set(gca,'xticklabel',opts.shift_cost(1:2:end));
set(gca,'xlim',[1 length(opts.shift_cost)]);
set(gca,'ylim',[-0.5 2.5]);
xlabel('Temporal precision (1/sec)');
ylabel('Information (bits)');
legend('No correction','TPMC correction','Jackknife correction',...
       'location','best');

% Shuffling

opts.entropy_estimation_method = {'plugin'};
rand('state',0);
S=10;
[out_unshuf,shuf,opts_used] = metric_shuf(STA,opts,S);
shuf = shuf';
for q_idx=1:length(opts.shift_cost)
  info_unshuf(q_idx)= out_unshuf(q_idx).table.information.value;
  for s=1:S
    temp_info_shuf(s,q_idx) = shuf(s,q_idx).table.information.value;
  end
end
info_shuf = mean(temp_info_shuf,1);
info_shuf_std = std(temp_info_shuf,[],1);

%%% leave-one-out Jackknife 

[out_unjk,jk,opts_used] = metric_jack(STA,opts);
P_total = size(jk,1);
temp_info_jk = zeros(P_total,length(opts.shift_cost));
for q_idx=1:length(opts.shift_cost)
  info_unjk(q_idx)= out_unjk(q_idx).table.information.value;
  for p=1:P_total
    temp_info_jk(p,q_idx) = jk(p,q_idx).table.information.value;
  end
end
info_jk_sem = sqrt((P_total-1)*var(temp_info_jk,1,1));

%%% Plot results

subplot(224);
errorbar(1:length(opts.shift_cost),info_unjk,2*info_jk_sem);
hold on;
errorbar(1:length(opts.shift_cost),info_shuf,2*info_shuf_std,'r');
hold off;
set(gca,'xtick',1:2:length(opts.shift_cost));
set(gca,'xticklabel',opts.shift_cost(1:2:end));
set(gca,'xlim',[1 length(opts.shift_cost)]);
set(gca,'ylim',[-0.5 2.5]);
xlabel('Temporal precision (1/sec)');
ylabel('Information (bits)');
legend('Original data (\pm 2 SE via Jackknife)','Shuffled data (\pm 2 SD)',...
       'location','best');

scalefig(gcf,1.5);


