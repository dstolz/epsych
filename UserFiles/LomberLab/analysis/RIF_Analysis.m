%% RIF analysis


plotwin = [-0.3 0.4];
analysiswin = [0.0051 0.3051];
excanalysiswin = [0.0051 0.2051];
baselinewin = [-0.3 0];
binsize = 0.001;

gwdur = 0.02;




DB = 'ds_a1_aaf_mod_mgb';

if isunix
    host = 'localhost';
else
    host = '129.100.241.107';
end




% Make connection to database.
if ~exist('conn','var') || ~isa(conn,'database') || ~strcmp(conn.Instance,DB)
    if ~exist('password','var')
        fprintf(2,'Create a char variable called "password"\n')
        return
    end
    conn = database(DB, 'DSuser', password, 'Vendor', 'MYSQL', ...
        'Server', host);
end




DB_CheckAnalysisParams({'base_fr','base_fr_std','resp_fr','resp_fr_std', ...
    'inhibited_response','peak_fr','peak_latency','resp_thr', ...
    'resp_on00','resp_off00','resp_on25','resp_off25','resp_on50','resp_off50', ...
    'resp_on75','resp_off75','base_corrcoef','resp_corrcoef'}, ...
    {'Mean baseline firing rate','Standard deviation of baseline firing rate', ...
    'Mean response firing rate','Standard deviation of response firing rate', ...
    'Unit''s response inhibited by stimulus','Peak response firing rate', ...
    'Latency to peak response','Response threshold (Hz)', ...
    'Response onset latency at threshold','Response offset latency at threshold', ...
    'Response onset latency at 25% between threshold and peak response', ...
    'Response offset latency at 25% between threshold and peak response', ...
    'Response onset latency at 50% between threshold and peak response', ...
    'Response offset latency at 50% between threshold and peak response', ...
    'Response onset latency at 75% between threshold and peak response', ...
    'Response offset latency at 75% between threshold and peak response', ...
    'Correlation coefficient of response','Correlation coeficient of prestimulus spontaneous'}, ...
    {'Hz','Hz','Hz','Hz',[],'Hz','sec','Hz','sec','sec','sec','sec','sec','sec','sec','sec', ...
    [],[]},conn);


% Select unanalyzed units
UNITS = myms([ ...
    'SELECT DISTINCT v.unit FROM v_ids v ', ...
    'JOIN blocks b ON v.block = b.id ', ...
    'JOIN units u ON v.unit = u.id ', ...
    'JOIN db_util.protocol_types p ON b.protocol = p.pid ', ...
    'LEFT OUTER JOIN unit_properties up ON u.id = up.unit_id ', ...
    'WHERE b.in_use = TRUE AND u.in_use = TRUE ', ...
    'AND p.alias = "RIF" ', ...
    'AND up.id IS null'],conn,'numeric');

% Randomize unit analysis order
UNITS = UNITS(randperm(numel(UNITS)));

% UNITS = 6760; % Excited unit
% UNITS = 6765; % Inhibited unit
% UNITS = 6766; % Inhibited unit

u = 1;
while u <= length(UNITS)
    unit_id = UNITS(u);
    
    fprintf('\n%s\n',repmat('*',1,50))

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
    
    % Plot response -----------------------------------------------
    f = findFigure('PSTH','name',sprintf('UnitID %d',unit_id), ...
        'position',[740 720 800 230],'color','w');
    figure(f);
    clf(f)
    
    ax_PSTH = subplot(3,10,[1 27]);
    imagesc(vals{1},vals{2},PSTH');
    colorbar('WestOutside')
    set(gca,'ydir','normal');
%     colormap(flipud(gray(64)))
    colormap(jet(128))
    xlabel('time (re stim)')
    hold(ax_PSTH,'on');
    plot([0 0],ylim,'-c');
    
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
    DATA.resp_fr_std = std(aPSTH);
    
    % Preliminary peak response
    [DATA.peak_fr,idx] = max(aPSTH);
    DATA.peak_latency  = abvec(idx);
       
    
    
    
    
    % response type ----------------------------------------------
    
%     SCdata.inhibited_response = DATA.resp_fr(end) < DATA.base_fr(end);
%     SCdata.inhibited_response = ttest(max(sPSTH),DATA.peak_fr,0.1,'left');
    r = input('Response type: (E)xcitatory or (I)nhibited or (R)eject?  ','s');
    if isequal(lower(r),'r')
        REJECT.RIFprop = {'REJECT'};
        DB_UpdateUnitProps(unit_id,REJECT,'RIFprop',1,conn);
        fprintf('Unit %d rejected\n',unit_id)
        u = u + 1;
        continue
    end
    SCdata.inhibited_response = lower(r) == 'i';
    if SCdata.inhibited_response
        fprintf(2,'\nUnit %d marked as Inhibited response\n',unit_id)
    else
        fprintf('\nUnit %d marked as Excited response\n',unit_id)
    end
    
    
    

    if SCdata.inhibited_response
        % define response threshold for inhibited unit
        DATA.resp_thr = norminv(0.025,DATA.base_fr,DATA.base_fr_std);
        
    else
        % define response threshold for excited unit
        s = DATA.base_fr_std;
        s(s==0) = mean(s(s~=0));
        DATA.resp_thr = norminv(0.975,DATA.base_fr,s);
        
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
    

    for i = 1:Dn
        
        if SCdata.inhibited_response            
            [a,b] = ResponseLatency(ePSTH(:,i), epvec, DATA.resp_thr(i), ...
                'lte','largest',length(gw)*0.25,1);
           
            DATA.resp_on00(i)  = a;
            DATA.resp_off00(i) = b;
            
            
        else            
            for rls = response_levels
                
                [a,b] = ResponseLatency(ePSTH(:,i), epvec, ...
                    Pk.(sprintf('pkthr%02d',rls))(i), ...
                    'gte','first', length(gw)*0.25,1);
                
                DATA.(sprintf('resp_on%02d', rls))(i) = a;
                DATA.(sprintf('resp_off%02d',rls))(i) = b;
                
            end
            
            % Make sure peak response is within excitatory response
            if isnan(DATA.resp_on00(i))
                DATA.peak_fr(i)      = nan;
                DATA.peak_latency(i) = nan;
            else
                ind = abvec >= DATA.resp_on00(i) & abvec <= DATA.resp_off00(i);
                [DATA.peak_fr(i),idx] = max(ePSTH(ind,i));
                DATA.peak_latency(i)  = abvec(idx+find(ind,1)-1);
            end

        end
        
        
    end
    
    
        
        
        
    
    
    
    % Characterize post-response suppression for excited units
    DATA.postresp_suppr_on  = nan(1,Dn);
    DATA.postresp_suppr_off = nan(1,Dn);
    if ~SCdata.inhibited_response
        for i = 1:Dn
            if isnan(DATA.resp_off00(i)), continue; end
            onsamp = round(1/binsize*DATA.resp_off00(i));

            [DATA.postresp_suppr_on(i),DATA.postresp_suppr_off(i)] = ...
                ResponseLatency(aPSTH(onsamp:end,i),abvec(onsamp:end), ....
                DATA.resp_thr(i),'lte','first',floor(length(gw)*0.25),1);
        end
    end
    
    
    
    
    
    
    
    
    %%%% Compute d'
    [pD,~] = shapedata_spikes(st,P,{'NBdB'},'win',excanalysiswin,'binsize',binsize, ...
        'returntrials',true,'func','sum');
    
    [sD,~] = shapedata_spikes(st,P,{'NBdB'},'win',baselinewin,'binsize',binsize, ...
        'returntrials',true,'func','sum');
    
    pDm = mean(squeeze(sum(pD))/size(pD,1));
    sDm = mean(squeeze(sum(sD))/size(sD,1));
    
    DATA.dprime = norminv(pDm,0,1)-norminv(sDm,0,1);
    
    
    
    % find valid responses
    for i = 1:Dn
        if SCdata.inhibited_response
            DATA.valid_response(i) = ztest(DATA.base_fr_std,DATA.resp_fr_std(i),1,0.005/Dn,'right');
        else
            DATA.valid_response(i) = ztest(DATA.base_fr_std,DATA.resp_fr_std(i),1,0.005/Dn,'left');
        end
    end
    DATA.valid_response = logical(DATA.valid_response);
    
    % find response threshold
    SCdata.minimum_threshold = vals{2}(find(DATA.valid_response,1,'first'));
    if isempty(SCdata.minimum_threshold), SCdata.minimum_threshold = max(vals{2}); end
    
    
    
    
    
    
    
    % Plot response --------------------------------------------------
   
    
    % Plot onsets and offsets
    y = vals{2}(DATA.valid_response);
    plot(DATA.resp_on00(DATA.valid_response),        y,'>w', ...
        DATA.resp_off00(DATA.valid_response),        y,'<w', ...
        DATA.peak_latency(DATA.valid_response),      y,'*w', ...
        DATA.postresp_suppr_on(DATA.valid_response), y,'>m', ...
        DATA.postresp_suppr_off(DATA.valid_response),y,'<m');
    
    
    
    
    
    % Plot stats
    subplot(3,10,[9 10])
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
    
    
    % plot response std
    subplot(3,10,[19 20]);
    plot(vals{2},DATA.base_fr_std,'-k',vals{2},DATA.resp_fr_std,'-bs');
    xlim(vals{2}([1 end]));
    ylabel('Std');
    
    
    
    % plot dprime
    subplot(3,10,[29 30])
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

    
    
    
    
    
    
    % Request user interaction
    fprintf('\n\n')
    yn = input('Would you like to manually mark valid responses (y or n)? ','s');
    if lower(yn)=='y'
        
        disp('Click plot with left (right) mouse button to mark valid (invalid) response')
        disp('(C)onfirm or any key to quit')
        
        tmpvalid = DATA.valid_response;
        while 1
            [x,y,button] = ginput(1);
            if isempty(button), continue; end
            switch button
                case 1
                    i = nearest(vals{2},y);
                    tmpvalid(i) = true;
                    fprintf('\t% 2.2f dB marked as Valid\n',vals{2}(i))
                    
                case 3
                    i = nearest(vals{2},y);
                    tmpvalid(i) = false;
                    fprintf('\t% 2.2f dB marked as Invalid\n',vals{2}(i))
                    
                case {67, 99}
                    DATA.valid_response = tmpvalid;
                    fprintf('Updated\n')
                    break
                    
                otherwise
                    fprintf('Not updated\n')
                    break
            end
            delete(findobj(ax_PSTH,'type','line'))
            hold(ax_PSTH,'on');
            plot(ax_PSTH,[0 0],ylim,'-c');
            y = vals{2}(tmpvalid);
            plot(ax_PSTH,DATA.resp_on00(tmpvalid),y,'>g', ...
                DATA.resp_off00(tmpvalid),        y,'<g', ...
                DATA.peak_latency(tmpvalid),      y,'*w', ...
                DATA.postresp_suppr_on(tmpvalid), y,'>c', ...
                DATA.postresp_suppr_off(tmpvalid),y,'<c');
        end
        
    end
    
    
    
    
    
    
    
    
    
    
    
    
    % Good to update database?
    fprintf('\n\n')
    r = input('(A)ccept,(R)eanalyze, Re(j)ect, or E(x)it?  ','s');
    
    switch lower(r)
        case 'a'
            fprintf('Unit %d accepted.\n',unit_id)
            
            % Update database
            SCdata.RIFprop = {'RIFprop'};
            DB_UpdateUnitProps(unit_id,SCdata,'RIFprop',1,conn);
            
            DATA.levels = arrayfun(@(a) (sprintf('%03d_dBSPL',a)),vals{2},'uniformoutput',false)';
            DB_UpdateUnitProps(unit_id,DATA,'levels',1,conn);

            
        case 'r'
            fprintf('Reanalyzing Unit %d\n',unit_id)
            u = u-1;
            
        case 'j'
            fprintf(2,'Unit %d rejected\n',unit_id)
                        
        case 'x'
            fprintf(2,'Exited on unit %d (%d of %d)\n',unit_id,u,length(UNITS)) %#ok<PRTCAL>
            break
    end
    
    
    u = u + 1;
end


%
% DELETE FROM ds_a1_aaf_mod_mgb.unit_properties
% WHERE group_id REGEXP "Resp_" AND group_id REGEXP "dB$"
% OR group_id = "RIFprop";