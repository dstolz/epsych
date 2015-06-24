%% Analysis Parameters

unit_id = 6772;

analysiswin = [0 0.8];

nReps = 500;

gw_durations = 2.^(0:8);  % gaussian window duration (ms)

binsize = 1e-5;



DB = 'ds_a1_aaf_mod_mgb';





% %% 
% % get data from database and bin it into 100 microsecond bins to ensure only
% % one spike per bin
% IDs = getpref('DB_BROWSER_SELECTION');
% 
% Dp = DB_GetParams(IDs.blocks);
% 
% st = DB_GetSpiketimes(IDs.units);


%%
%Make connection to database.  Note that the password has been omitted.
%Using JDBC driver.

if exist('conn','var') && isa(conn,'database') && ~strcmp(conn.Instance,DB)
    conn = database('ds_a1_aaf_mod_mgb', 'DSuser', 'B1PdI0KY8y', 'Vendor', 'MYSQL', ...
        'Server', '129.100.241.107', 'PortNumber', 3306);
end






st = DB_GetSpiketimes(unit_id,[],conn);
P  = DB_GetParams(unit_id,'unit',conn);


%%
[D,vals,raster] = shapedata_spikes(st,P,{'BuID','Attn'},'win',analysiswin, ...
    'binsize',binsize,'returntrials',true);

[Dm,Dn,Dp,Dq] = size(D);



%% Simple plot

f = findFigure('Classifer');
figure(f);
PlotRaster(raster(:,1),1:180);








%% Spike count based classifier

starttime = clock;
fprintf('Starting Spike Count-based classification:\t\t%s\n',datestr(starttime))

DATA.Rcount.class = zeros(nReps,Dq,Dp);
DATA.Rcount.class_shuff = zeros(nReps,Dq,Dp);
for i = 1:Dp
    
    [DATA.Rcount.class(:,:,i),DATA.Rcount.class_shuff(:,:,i)] = BasicClassifier(squeeze(D(:,:,i,:)),nReps);
    
end

DATA.Rcount.org_class = zeros(nReps*Dq,Dp);
DATA.Rcount.org_class_shuff = zeros(nReps*Dq,Dp);
for i = 1:Dp

    a = DATA.Rcount.class(:,:,i);
    DATA.Rcount.org_class(:,i) = sort(a(:));
    
    a = DATA.Rcount.class_shuff(:,:,i);
    DATA.Rcount.org_class_shuff(:,i) = sort(a(:));

end
clear a


fprintf('Finished with Spike count-based classification:\t%s\n',datestr(now))
fprintf('Computing time for Spike count-based classifier: ~%0.1f minutes\n',etime(clock,starttime)/60)




















%% Time based classifier
% Compute the Schreiber Correlation (Rcorr) for all stimulus conditions

% use parallel processing
if matlabpool('size') == 0, matlabpool local 6; end

gwsamps = gw_durations/1000/binsize; % time -> samples

% preallocate some parameters
class = nan(nReps,Dq,Dp,length(gwsamps));
class_shuff = nan(size(class));

% Compute time-based measure using Schreiber correlation (Rcorr)
starttime = clock;
fprintf('Starting Spike Time-based classification:\t\t%s\n',datestr(starttime))
parfor g = 1:length(gwsamps) % gaussian windows
    gwin = gausswin(gwsamps(g));
    
    for i = 1:Dp % BuID
        sm_data = zeros([Dm, Dn, Dq]);
        
        for j = 1:Dq % Attn
            
            for k = 1:Dn
                sm_data(:,k,j) = conv(D(:,k,i,j),gwin,'same'); %#ok<PFBNS>
            end
            
        end
        fprintf('Window = %d ms\t BuID = %d\t',gw_durations(g),i)
        
        [class(:,:,i,g),class_shuff(:,:,i,g)] = BasicClassifier2(sm_data,nReps,@SchreiberCorr);
                
    end
end
DATA.Rtime.class = class;
DATA.Rtime.class_shuff = class_shuff;

clear class class_shuff


for g = 1:length(gwsamps)
    for i = 1:Dp
        a = DATA.Rtime.class(:,:,i,g);
        DATA.Rtime.org_class(:,i,g) = sort(a(:));
        
        a = DATA.Rtime.class_shuff(:,:,i,g);
        DATA.Rtime.org_class_shuff(:,i,g) = sort(a(:));
    end
end
clear a


fprintf('Finished with Spike time-based classification:\t%s\n',datestr(now))
fprintf('Computing time for Spike time-based classifier: ~%0.1f minutes\n',etime(clock,starttime)/60)

















%% Make some statistical comparisons on data and descriptive statistics

clear STATS TMP

Qs = [.025 .25 .50 .75 .975]; % quantiles
for f = fieldnames(DATA)'
    f = char(f); %#ok<FXSET>
    TMP.(f).mean         = squeeze(mean(DATA.(f).org_class));
    TMP.(f).mean_shuff   = squeeze(mean(DATA.(f).org_class_shuff));
    TMP.(f).median       = squeeze(median(DATA.(f).org_class));
    TMP.(f).median_shuff = squeeze(median(DATA.(f).org_class_shuff));
    TMP.(f).quants       = quantile(DATA.(f).org_class,Qs);
    TMP.(f).quants_shuff = quantile(DATA.(f).org_class_shuff,Qs);
end


% Count-based
STATS.Rcount = TMP.Rcount;

for i = 1:Dp        
        % Time-based ------------------------------------------------------
        % Find optimal gaussian window length
        [STATS.Rtime.OptVal(i),idx] = max(squeeze(TMP.Rtime.mean(i,:)));
        STATS.Rtime.OptGwin(i) = gw_durations(idx);
        STATS.Rtime.OptVal_shuff(i) = TMP.Rtime.mean_shuff(i,idx);
        
        STATS.Rtime.mean(i)         = TMP.Rtime.mean(i,idx);
        STATS.Rtime.mean_shuff(i)   = TMP.Rtime.mean_shuff(i,idx);
        STATS.Rtime.median(i)       = TMP.Rtime.median(i,idx);
        STATS.Rtime.median_shuff(i) = TMP.Rtime.median_shuff(i,idx);
        STATS.Rtime.quants(i)       = TMP.Rtime.quants(i,idx);
        STATS.Rtime.quants_shuff(i) = TMP.Rtime.quants_shuff(i,idx);
        
        
        % Statistical test
        STATS.Rtime.tests.ks_p(i) = kstest2(DATA.Rtime.org_class(:,i,idx), ...
            DATA.Rtime.org_class_shuff(:,i,idx),0.025,'larger');
        
        [STATS.Rtime.tests.t_h(i),STATS.Rtime.tests.t_p(i)] = ttest2( ...
            DATA.Rtime.org_class(:,i,idx), DATA.Rtime.org_class_shuff(:,i,idx), ...
            0.025,'right');
        
        cv = TMP.Rtime.quants_shuff(end,i,idx);
        STATS.Rtime.tests.gt95(i) = TMP.Rtime.mean(i,idx) > cv;
        
        
        % Confusion matrix on sound level
        a = squeeze(mean(DATA.Rtime.class(:,:,i,idx)));
        STATS.Rtime.confuse_mat{i} = a' * a;
        
        a = squeeze(mean(DATA.Rtime.class_shuff(:,:,i,idx)));
        STATS.Rtime.confuse_mat_shuff{i} = a' * a;
        
        
        
        % Count-based -----------------------------------------------------
        STATS.Rcount.tests.ks_p(i) = kstest2(DATA.Rcount.org_class(:,i), ...
            DATA.Rcount.org_class_shuff(:,i),0.025,'larger');
        
        [STATS.Rcount.tests.t_h(i),STATS.Rcount.tests.t_p(i)] = ttest2( ...
            DATA.Rcount.org_class(:,i), DATA.Rcount.org_class_shuff(:,i), ...
            0.025,'right');
        
        cv = TMP.Rcount.quants_shuff(end,i);
        STATS.Rcount.tests.gt95(i) = TMP.Rcount.mean(i) > cv;
        
        
        % Confusion matrix on sound level
        a = squeeze(mean(DATA.Rcount.class(:,:,i)));
        STATS.Rcount.confuse_mat{i} = a' * a;
        
        a = squeeze(mean(DATA.Rcount.class_shuff(:,:,i)));
        STATS.Rcount.confuse_mat_shuff{i} = a' * a;
        
        
end








%% Make judgements based on stats

for s = fieldnames(STATS)'
    
end


















%%
% if matlabpool('size') > 0, matlabpool close force local;    end