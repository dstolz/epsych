%% RIF analysis


plotwin = [-0.25 0.4];
analysiswin = [0.0051 0.3051];
excanalysiswin = [0.0051 0.2051];
baselinewin = [-0.2 0];
binsize = 0.001;

gwdur = 0.02;




DB = 'ds_a1_aaf_mod_mgb';

% use parallel processing
if isunix
    if matlabpool('size') == 0
        matlabpool local 12; % KingKong server
    end
    host = 'localhost';
else
    if matlabpool('size') == 0
        matlabpool local 6; % PC
    end
    host = '129.100.241.107';
end




% Make connection to database.
if ~exist('conn','var') || ~isa(conn,'database') || ~strcmp(conn.Instance,DB)
    conn = database(DB, 'DSuser', 'B1PdI0KY8y', 'Vendor', 'MYSQL', ...
        'Server', host);
end

setdbprefs('DataReturnFormat','numeric');
UNITS = myms([ ...
    'SELECT v.unit FROM v_ids v ', ...
    'JOIN blocks b ON v.block = b.id ', ...
    'JOIN units u ON v.unit = u.id ', ...
    'JOIN db_util.protocol_types p ON b.protocol = p.pid ', ...
    'WHERE b.in_use = TRUE AND u.in_use = TRUE ', ...
    'AND p.alias = "RIF"'],conn);





DB_CheckAnalysisParams({'base_fr','base_fr_std','resp_fr','resp_fr_std', ...
    'inhibited_response','peak_fr','peak_latency','resp_thr', ...
    'resp_on','resp_off'}, ...
    {'Mean baseline firing rate','Standard deviation of baseline firing rate', ...
    'Mean response firing rate','Standard deviation of response firing rate', ...
    'Unit''s response inhibited by stimulus','Peak response firing rate', ...
    'Latency to peak response','Response threshold (Hz)', ...
    'Response onset latency','Response offset latency'}, ...
    {'Hz','Hz','Hz','Hz',[],'Hz','sec','Hz','sec','sec'},conn);


% UNITS = 6760; % Excited unit
% UNITS = 6765; % Inhibited unit
UNITS = 6766; % Inhibited unit


for u = 1:length(UNITS)
    unit_id = UNITS(u);
    fprintf('Processing unit_id = %d (%d of %d)\n',unit_id,u,length(UNITS))
    
    
    
    
    % Retrieve spiketimes and protocol parameters from the database
    st = DB_GetSpiketimes(unit_id,[],conn);
    P  = DB_GetParams(unit_id,'unit',conn);
    
    
    
    
    
    
    
    
    % Response characteristics -----------------------------------
    % Reshape and bin data based on stimulus parameters
    [D,vals] = shapedata_spikes(st,P,{'NBdB'},'win',plotwin,'binsize',binsize);
    D = D / binsize;
    
    [Dm,Dn] = size(D);
    
    
    
    
    % Smooth PSTH
    gw = gausswin(round(gwdur/binsize));
    
    if mod(length(gw),2)
        gwoffset = [floor(length(gw)/2) ceil(length(gw)/2)];
    else
        gwoffset = [1 1]*round(length(gw)/2);
    end
    PSTH = zeros(size(D));
    for i = 1:Dn
        p = conv(D(:,i),gw,'full');
        PSTH(:,i) = p(gwoffset(1):end-gwoffset(2)); % subtract phase delay
    end
    PSTH = PSTH/max(PSTH(:)) * max(D(:)); % rescale PSTH
    PSTH(PSTH<0) = 0;
    
    
    clear DATA
    
    % compute prestimulus, baseline firing rate after smoothing
    ind = vals{1} >= baselinewin(1) & vals{1} < baselinewin(2);
    sPSTH = PSTH(ind,:);
    DATA.base_fr     = mean(sPSTH);
    DATA.base_fr_std = std(sPSTH);
    
    % response for analysis after smoothing
    ind = vals{1} >= analysiswin(1) & vals{1} < analysiswin(2);
    abvec = vals{1}(ind);
    aPSTH = PSTH(ind,:);
    DATA.resp_fr     = mean(aPSTH);
    DATA.resp_fr_std = std(sPSTH);
    
    % peak response
    [DATA.peak_fr,idx] = max(aPSTH);
    DATA.peak_latency  = abvec(idx);
    
    
    
    
    % response type
    SCdata.inhibited_response = DATA.resp_fr(end) < DATA.base_fr(end);
    
    
    
    
    
    

    if SCdata.inhibited_response
        % define response threshold for inhibited unit
        DATA.resp_thr = norminv(0.025,DATA.base_fr,DATA.base_fr_std);
        
    else
        % define response threshold for excited unit
        DATA.resp_thr = norminv(0.975,DATA.base_fr,DATA.base_fr_std);

        % Threshold - Peak difference
        pkthrdiff = DATA.peak_fr - DATA.resp_thr;
        
        % Find response onsets and offsets
        response_levels = [0 25 50 75];
        for i = 1:length(response_levels)
            DATA.(sprintf('resp_on%02d',response_levels(i)))  = nan(1,Dn);
            DATA.(sprintf('resp_off%02d',response_levels(i))) = nan(1,Dn);
            Pk.(sprintf('pkthr%02d',response_levels(i))) = pkthrdiff * response_levels(i)/100 + DATA.resp_thr;
        end
    end
    DATA.resp_thr(DATA.resp_thr < 0) = 0;

    % restrict to excitatory phase of analysis
    excsamp = floor(excanalysiswin(1)/binsize):ceil(excanalysiswin(2)/binsize);
    epvec = excsamp*binsize;
    ind = vals{1} >= excanalysiswin(1) & vals{1} <= excanalysiswin(2);
    ePSTH = PSTH(ind,:);
    

    % Find response onsets and offsets
    response_levels = [0 25 50 75];
    for i = 1:length(response_levels)
        DATA.(sprintf('resp_on%02d',response_levels(i)))  = nan(1,Dn);
        DATA.(sprintf('resp_off%02d',response_levels(i))) = nan(1,Dn);
        Pk.(sprintf('pkthr%02d',response_levels(i))) = pkthrdiff * response_levels(i)/100 + DATA.resp_thr;
    end
    
    
    for i = 1:Dn
        
        if SCdata.inhibited_response
            [DATA.ttest_h(i),DATA.ttest_p(i)] = ttest(ePSTH(:,i),DATA.base_fr(i),0.025/Dn,'left');
            %             [DATA.kstest_h(i),DATA.kstest_p(i)] = kstest2(sPSTH(:,i),ePSTH(:,i),0.05/Dn);
            
            [a,b] = ResponseOnOffLatency(ePSTH(:,i), epvec, DATA.resp_thr(i), ...
                'lte','span', length(gw)*0.25,1);
            
            
            test = 'lt';
            
            DATA.resp_on00(i)  = a;
            DATA.resp_off00(i) = b;
            
            
        else
            
            [DATA.ttest_h(i),DATA.ttest_p(i)] = ttest(ePSTH(:,i),DATA.base_fr(i),0.025/Dn,'right');
            %             [DATA.kstest_h(i),DATA.kstest_p(i)] = kstest2(sPSTH(:,i),ePSTH(:,i),0.05/Dn);
            
            for rls = response_levels
                
                [a,b] = ResponseOnOffLatency(ePSTH(:,i), epvec, Pk.(sprintf('pkthr%02d',rls))(i), ...
                    'gte','largest', length(gw)*0.25,1);
                
                DATA.(sprintf('resp_on%02d',rls))(i)  = a;
                DATA.(sprintf('resp_off%02d',rls))(i) = b;
                
            end
        end
        
        
    end
    
    
        
        
        
    
    
    
    % Characterize post-response rebound for excited units
    DATA.postresp_suppr_on  = nan(1,Dn);
    DATA.postresp_suppr_off = nan(1,Dn);
    if ~SCdata.inhibited_response
        for i = 1:Dn
            if isnan(DATA.resp_off00(i)), continue; end
            onsamp = round(1/binsize*DATA.resp_off00(i));

            
            [DATA.postresp_suppr_on(i),DATA.postresp_suppr_off(i)] = ...
                ResponseOnOffLatency(aPSTH(onsamp:end,i),DATA.resp_thr(i), ...
                'lt',floor(length(gw)*0.25));
        end
    end
    
    
    
    
    
    
    
    
    %%%% Compute d'
    
    [pD,pvals] = shapedata_spikes(st,P,{'NBdB'},'win',excanalysiswin,'binsize',binsize, ...
        'returntrials',true,'func','sum');
    
    [sD,~] = shapedata_spikes(st,P,{'NBdB'},'win',baselinewin,'binsize',binsize, ...
        'returntrials',true,'func','sum');
    
    pDm = mean(squeeze(sum(pD))/size(pD,2));
    sDm = mean(squeeze(sum(sD))/size(sD,2));
    
    DATA.dprime = norminv(pDm,0,1)-norminv(sDm,0,1);
    
    
    
    
    
    
    
    
    % find valid responses
    if SCdata.inhibited_response
        DATA.valid_response = ~isnan(DATA.resp_on00);
    else
        DATA.valid_response = DATA.peak_fr > DATA.resp_thr;
    end
%     DATA.valid_response = true(1,Dn);
    
    % find response threshold
    SCdata.minimum_threshold = vals{2}(find(DATA.valid_response,1,'first'));
    
    
    
    
    
    
    
    
    % Plot response --------------------------------------------------
    f = findFigure('PSTH','name',sprintf('UnitID %d',unit_id), ...
        'position',[740 720 800 230],'color','w');
    figure(f);
    clf
    
    subplot(2,10,[1 17]);
    imagesc(vals{1},vals{2},PSTH');
    if SCdata.inhibited_response
        title('Inhibited');
    else
        title('Excitatory');
    end
    colorbar('West')
    set(gca,'ydir','normal');
    colormap(flipud(gray(64)))
    xlabel('time (re stim)')
    
    % Plot onsets and offsets
    hold on
    plot([0 0],ylim,'-c');
    y = vals{2}(DATA.valid_response);
    plot(DATA.resp_on00(DATA.valid_response),        y,'>g', ...
        DATA.resp_off00(DATA.valid_response),        y,'<g', ...
        DATA.peak_latency(DATA.valid_response),      y,'*r', ...
        DATA.postresp_suppr_on(DATA.valid_response), y,'>c', ...
        DATA.postresp_suppr_off(DATA.valid_response),y,'<c');
    
    
    
    
    
    % Plot stats
    subplot(2,10,[9 10])
    [ax,h1,h2] = plotyy(vals{2},DATA.peak_fr, ...
        vals{2},DATA.resp_fr);
    set(ax,'xlim',vals{2}([1 end]))
    set(ax(1),'ycolor','r','ylim',[0 max(DATA.peak_fr)*1.1]);
    set(ax(2),'ycolor','g','ylim',[0 max(DATA.resp_fr)*1.1]);
    ylabel(ax(1),'Peak Firing Rate');
    ylabel(ax(2),'Mean Firing Rate');
    set(h1,'marker','*','color','r');
    set(h2,'marker','x','color','g')
    hold(ax(1),'on');
    plot(ax(1),[1 1]*SCdata.minimum_threshold,ylim,':k');
    hold(ax(2),'on');
    plot(ax(2),vals{2},DATA.base_fr,':g');
    
    % plot dprime
    subplot(2,10,[19 20])
    plot(vals{2},DATA.dprime,'-o');
    xlim(vals{2}([1 end]));
    hold on
    if SCdata.inhibited_response
        plot(xlim,-[1 1]*1/size(pD,2),':k');
    else
        plot(xlim,[1 1]*1/size(pD,2),':k');
    end
    
    
    ylabel('D''')
    xlabel('Level')

    
    
    DATA.levels = arrayfun(@(a) (sprintf('%03d_dBSPL',a)),vals{2},'uniformoutput',false)';
    
%     DB_UpdateUnitProps(unit_id,DATA,'levels',1,conn);
    
    SCdata.RIFprop = {'RIFprop'};
%     DB_UpdateUnitProps(unit_id,SCdata,'RIFprop',1,conn);
    
    
    
    
%     pause
    
    
end
