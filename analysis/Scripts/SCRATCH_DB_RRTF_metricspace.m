%%

unit = getpref('DB_BROWSER_SELECTION','units');

st = DB_GetSpiketimes(unit);
P  = DB_GetParams(unit,'unit');

%%

uRate = P.lists.Rate;

fpidx = find(diff(P.VALS.Rate))+1;

P.VALS = structfun(@(x) (x(fpidx)),P.VALS,'UniformOutput',false);

clear opts
opts.clustering_exponent        = -2;
opts.unoccupied_bins_strategy   = -1;
opts.metric_family              = 0; % 0: D^spike; 1: D^interval
opts.parallel                   = 1;
opts.possible_words             = 'unique';

opts.start_time = 0.02;
opts.end_time   = 0.5;
opts.shift_cost = [0 2.^(0:0.1:11)];

opts.entropy_estimation_method = {'jack'};


Levels = P.lists.Rate(2:end);
maxinfo = log2(length(Levels));
[STA,raster,values] = GenSTA(st,P,'Rate',opts,'Levels',Levels,'fullwin',[0 0.6]);

% metric-space analysis -----------------------------------------------
% [Y,Yb,optout] = metric_shuf(STA,opts,20);
% 
% b = arrayfun(@(a) (a.table.information.value),Yb);
% Ivb  = mean(b,2);
% Ivbs = std(b,0,2);
[Y,optout] = metric(STA,opts);

clear Iv 
for k = 1:numel(Y)
    for j = 1:length(optout.entropy_estimation_method)
        Iv(k,j)  = Y(k).table.information(j).value; %#ok<AGROW>
    end
end

mIv = mean(Iv,2);

% % Mutual information of spike counts
% MI = MUTUALINFO(raster,values);



%%

figure(1);
% clf
hold on
stairs(optout.shift_cost(2:end),mIv(2:end),'-c');

hold on
plot(0.9,mean(Iv(1)),'ob');
hold off

set(gca,'xscale','log','xlim',[0.9 optout.shift_cost(end)]);


