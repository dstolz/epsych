% Spike-count and Spike-timing coding strategies of neurons







% Analysis Parameters

analysiswin = [0 0.65];

nReps = 500;

gw_durations = 2.^(0:8);  % gaussian window duration (ms)

binsize = 1e-4; % ensure binsize is small enough so that only one spike per bin



DB = 'ds_a1_aaf_mod_mgb';


















% use parallel processing
if matlabpool('size') == 0
    if strcmp(computer,'GLNXA64')
        matlabpool local 12; % KingKong server
    else
        matlabpool local 6; % PC
    end
end
















% Make connection to database. 
if ~exist('conn','var') || ~isa(conn,'database') || ~strcmp(conn.Instance,DB)
    conn = database('ds_a1_aaf_mod_mgb', 'DSuser', 'B1PdI0KY8y', 'Vendor', 'MYSQL', ...
        'Server', 'localhost');
end

setdbprefs('DataReturnFormat','numeric');
UNITS = myms(['SELECT v.unit FROM v_ids v ', ...
    'JOIN blocks b ON v.block = b.id ', ...
    'JOIN units u ON v.unit = u.id ', ...
    'JOIN db_util.protocol_types p ON b.protocol = p.pid ', ...
    'WHERE b.in_use = TRUE AND u.in_use = TRUE ', ...
    'AND p.alias = "WAV"'],conn);


for u = 1:length(UNITS)
    unit_id = UNITS(u);
    fprintf('Processing unit_id = %d (%d of %d)\n',unit_id,u,length(UNITS))
    
    
    
    
    
    
    
    
    % Retrieve spiketimes and protocal parameters from the database
    st = DB_GetSpiketimes(unit_id,[],conn);
    P  = DB_GetParams(unit_id,'unit',conn);
    
    
    % Reshape and bin data based on stimulus parameters
    [D,vals] = shapedata_spikes(st,P,{'BuID','Attn'},'win',analysiswin, ...
        'binsize',binsize,'returntrials',true);
      
    [Dm,Dn,Dp,Dq] = size(D);
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    % Simple plot
    f = findFigure('Classifer','color','w');
    figure(f);
    set(f,'name',sprintf('Unit %d (%d of %d)',unit_id,u,length(UNITS)));
    clf
    binvec = analysiswin(1):binsize:analysiswin(2)-binsize;
    gw = gausswin(32/1000/binsize);
    for i = 1:Dp % BuID
        subplot(1,2,i)
        for j = 1:Dq % Attn
            s(:,j) = conv(squeeze(mean(D(:,:,i,j),2)),gw,'same'); %#ok<SAGROW>
        end
        imagesc(binvec,vals{4},s');
        title(sprintf('BuID = %d',vals{3}(i)))
    end
    drawnow
    
    clear DATA
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    % Spike count based classifier
    
    starttime = clock;
    fprintf('\tStarting Spike Count-based classification:\t\t%s\n',datestr(starttime))
    
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
    
    
    fprintf('\tFinished with Spike count-based classification:\t%s\n',datestr(now))
    fprintf('\t\tComputing time for Spike count-based classifier: ~%0.1f minutes\n',etime(clock,starttime)/60)
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    % Time based classifier
    % Compute the Schreiber Correlation (Rcorr) for all stimulus conditions    
    gwsamps = gw_durations/1000/binsize; % time -> samples
    
    % preallocate some parameters
    class = nan(nReps,Dq,Dp,length(gwsamps));
    class_shuff = nan(size(class));
    
    
    % Compute time-based measure using Schreiber correlation (Rcorr)
    starttime = clock;
    fprintf('\tStarting Spike Time-based classification:\t\t%s\n',datestr(starttime))
    parfor g = 1:length(gwsamps) % gaussian windows
        gwin = gausswin(gwsamps(g));
        d = D; % for parallelization
        
        for i = 1:Dp % BuID
            sm_data = zeros([Dm, Dn, Dq]);
            
            
            for j = 1:Dq % Attn
                
                for k = 1:Dn
                    sm_data(:,k,j) = conv(d(:,k,i,j),gwin,'same');
                end
                
            end
            fprintf('\t > Window = %d ms\t BuID = %d\n',gw_durations(g),i)
            
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
    
    
    fprintf('\tFinished with Spike time-based classification:\t%s\n',datestr(now))
    fprintf('\t\tComputing time for Spike time-based classifier: ~%0.1f minutes\n',etime(clock,starttime)/60)
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    % Descriptive statistics
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
    
    
    % Count-based measures
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
        STATS.Rtime.tests.gt975(i) = TMP.Rtime.mean(i,idx) > cv;
        
        
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
        STATS.Rcount.tests.gt975(i) = TMP.Rcount.mean(i) > cv;
        
        % Confusion matrix on sound level
        a = squeeze(mean(DATA.Rcount.class(:,:,i)));
        STATS.Rcount.confuse_mat{i} = a' * a;
        
        a = squeeze(mean(DATA.Rcount.class_shuff(:,:,i)));
        STATS.Rcount.confuse_mat_shuff{i} = a' * a;
        
        
    end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    % Plot confusion matrices
    f = findFigure('Confuse','color','w');
    figure(f);
    set(f,'name',sprintf('Unit %d (%d of %d)',unit_id,u,length(UNITS)));
    clf
    subplot(221)
    imagesc(vals{4},vals{4},STATS.Rcount.confuse_mat{1});
    axis square
    title('Rcount')
    subplot(222)
    imagesc(vals{4},vals{4},STATS.Rcount.confuse_mat_shuff{1});
    axis square
    title('Rcount-shuff')
    colorbar('peer',gca,'EastOutside')
    subplot(223)
    imagesc(vals{4},vals{4},STATS.Rtime.confuse_mat{2});
    axis square
    title('Rtime')
    subplot(224)
    imagesc(vals{4},vals{4},STATS.Rtime.confuse_mat_shuff{2});
    axis square
    title('Rtime-shuff')
    colorbar('peer',gca,'EastOutside')
    c = [cell2mat(STATS.Rtime.confuse_mat) cell2mat(STATS.Rcount.confuse_mat)];
    set(get(gcf,'children'),'clim',[0 max(c(:))]);
    drawnow
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    % Determine coding strategy of the cell
    Assignment = cell(1,Dp);
    for i = 1:Dp
        if STATS.Rcount.tests.gt975(i) && STATS.Rtime.tests.gt975(i)
            Assignment{i} = 'Bicoding';
        
        elseif ~STATS.Rcount.tests.gt975(i) && STATS.Rtime.tests.gt975(i)
            Assignment{i} = 'Time';
            
        elseif STATS.Rcount.tests.gt975(i) && ~STATS.Rtime.tests.gt975(i)
            Assignment{i} = 'Count';
            
        else
            Assignment{i} = 'None';
            
        end
        
        fprintf('\n\t** Unit ID %d classified as "%s" coding cell (BuID = %d) **\n', ...
            unit_id,Assignment{i},vals{3}(i))
    end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    % Send results to database
    fprintf('\tSending results to database ...')
    
    clear DBp
    
    k = 1;
    for f = fieldnames(STATS)'
        f = char(f); %#ok<FXSET>
        
        for i = 1:Dp
            fi = sprintf('%s_%d',f,vals{3}(i));
            
            DBp.category{k} = fi;
            DBp.mean(k) = STATS.(f).mean(i);
            DBp.median(k) = STATS.(f).median(i);
            DBp.confuse{k} = mat2str(STATS.(f).confuse_mat{i},4);
            
            DBp.ttest_h(k) = STATS.(f).tests.t_h(i);
            DBp.gt975(k)    = STATS.(f).tests.gt975(i);
            
            k = k + 1;
            DBp.category{k} = sprintf('%s_shuff',fi);
            DBp.mean(k)= STATS.(f).mean_shuff(i);
            DBp.median(k) = STATS.(f).median_shuff(i);
            DBp.confuse{k} = mat2str(STATS.(f).confuse_mat_shuff{i},4);
            
        end
    end
        
    DB_CheckAnalysisParams({'Assignment','mean','median','ttest_h','gt975','confuse'}, ...
        {'Classification assignment of unit','Algebraic mean value','Median value', ...
        'Reject null hypothesis after t-test','Greater than 97.5%','Confusion matrix'}, ...
        [],conn);
    
    DB_UpdateUnitProps(unit_id,DBp,'category',1,conn);
    
    Ap.type = {'WAVCoding_1','WAVCoding_2'};
    Ap.Assignment = Assignment;
    DB_UpdateUnitProps(unit_id,Ap,'type',1,conn);
    
    
end













%
% if matlabpool('size') > 0, matlabpool close force local;    end