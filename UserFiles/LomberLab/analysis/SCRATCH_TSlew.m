%% Noise-Flash temporal slewing analysis


plotwin     = [-0.15 0.4];
baselinewin = [-0.15 0];
binsize = 0.001;


smdur = 0.01; % Moving average filter duration (s)
gwdur = 0.01; % Gaussian window APSTH duration (s)

% Uses the Holm-Bonferroni method to correct for multiple comparisons
alpha = 0.025;


DB = 'ds_a1_aaf_mod_mgb';

if isunix
    host = 'localhost';
else
    host = '129.100.241.107';
end




% Make connection to database.
if ~exist('conn','var') || ~isa(conn,'database') || ~strcmp(conn.Instance,DB) || ~isconnection(conn)
    if ~exist('password','var')
        fprintf(2,'Create a char variable called "password"\n')
        return
    end

    logintimeout('driver',5);
    conn = database(DB, 'DSuser', password, 'Vendor', 'MYSQL', ...
        'Server', host);
end






DB_CheckAnalysisParams({'meanfr','stdfr','ttest_h','ttest_p','resp_on', ...
    'resp_off','resp_thr','max_interact','max_soa','min_interact','min_soa', ...
    'Sadd_ttest_p','Supr_ttest_p','Sadd_ttest_h','Supr_ttest_h','superadditive','suppressive','osci_amp', ...
    'osci_freq','powspec_sum','driver','Int_ttest_p','Integrating','modalness','Subthreshold','skipped','Inhibited'}, ...
    {'Mean firing rate','Standard deviation of firing rate','Accept/reject hypothesis with ttest', ...
    'P value from ttest','Response onset','Response offset','Response threshold', ...
    'Maximum interaction firing rate','Maximum interaction stimulus onset asynchrony', ...
    'Minimum interaction firing rate','Minimum interaction stimulus onset asynchrony', ...
    'Superadditive ttest P value','Suppressive ttest P value','Superadditive ttest accept/reject hypothesis', ...
    'Suppressive ttest accept/reject hypothesis','Superadditive response','Suppressive resposne', ...
    'Oscillation amplitude','Oscillation frequency','Sum of power spectrum','Driving modality', ...
    'Interaction ttest P value','Integrating response','Amodal, Unimodal, Bimodal, etc.', ...
    'Subthreshold response','Skipped unit analysis','Mean firing rate is significantly less than baseline firing rate'}, ...
    {'Hz','Hz',[],[],'s','s','Hz','Hz','s','Hz','s',[],[],[],[],[],[],[],'Hz', ...
    [],[],[],[],[],[],[],[]},conn)






prevflag = false;




% Select unanalyzed "WARM" units
UNITS = myms([ ...
    'SELECT DISTINCT v.unit FROM v_ids v ', ...
    'JOIN blocks b ON v.block = b.id ', ...
    'JOIN units u ON v.unit = u.id ', ...
    'JOIN db_util.protocol_types p ON b.protocol = p.pid ', ...
    'JOIN tanks t ON v.tank = t.id ', ...
    'LEFT OUTER JOIN unit_properties up ON u.id = up.unit_id ', ...
    'WHERE b.in_use = TRUE AND u.in_use = TRUE ', ...
    'AND p.alias = "TSlew" ', ...%     'AND t.tank_condition = "WARM" ', ...
    'AND up.id IS null'],conn,'numeric');

% Randomize unit analysis order
UNITS = UNITS(randperm(numel(UNITS)));

% UNITS = 11469; % bimodal unit integrating
% UNITS = 5621; % strong unimodal visual unit
% UNITS = 5762; % long latency weak visual unit
% UNITS = 9452; % strong auditory unit
% UNITS = 11574; % weakly bimodal
% UNITS = 11888; % bimodal unit non-integrating
% UNITS = 11628; % bimodal unit
% UNITS = 11620; % bimodal non-integrating unit
% UNITS = 9065;  % very long latency auditory response that seems to be modulated by visual

% UNITS = 5880;

u = 1;
while u <= length(UNITS)
    clear A* V* R
    
    % default analysis windows
    Awin = [0.005 0.08]; 
    Vwin = [0.005 0.08];


    unit_id = UNITS(u);
    
    if strcmp(unit_id,'No Data')
        fprintf(2,'No units to analyze\n')
        break
    end
    
    fprintf('\n%s\n',repmat('*',1,50))
    
    fprintf('Processing unit_id = %d (%d of %d)\n',unit_id,u,length(UNITS))
    
    binvec = plotwin(1):binsize:plotwin(2)-binsize;
    
    % Retrieve spiketimes and protocol parameters from the database
    st = DB_GetSpiketimes(unit_id,[],conn);
    P  = DB_GetParams(unit_id,'unit',conn);
    
    [swave,swtvec,swstddev] = DB_GetSpikeWaveform(unit_id,conn);
    
    while 1
        
        %% Preprocessing ---------------------------------------------------
        
        
        % Reshape and bin data based on stimulus parameters
        FDel = P.VALS.FDel;
        [FDel,i] = sort(FDel);
        onsets = P.VALS.onset(i);
        raster = cell(size(onsets));
        rasterf = cell(size(onsets));
        for i = 1:length(onsets)
            ind = st >= plotwin(1) + onsets(i) & st < plotwin(2) + onsets(i);
            raster{i}  = st(ind)' - onsets(i);
            ind = st >= plotwin(1) + onsets(i) + FDel(i) & st < plotwin(2) + onsets(i) + FDel(i);
            rasterf{i} = st(ind)' - onsets(i) - FDel(i);
        end
        
        if sum(cellfun(@numel,raster)) < 200
            if prevflag
                fprintf(2,'Unit ID %d has too few spikes!\n',unit_id)
            else
                fprintf(2,'Unit ID %d has too few spikes!  Skipping ...\n',unit_id)
                X.groupid = 'TSlew:Skipped';
                X.skipped = 1;
                DB_UpdateUnitProps(unit_id,X,'groupid',false,conn);
                fprintf('Skipped Unit ID %d\n',unit_id)
                break                
                break
            end
        end
        
        prevflag = false;
        
        D  = cell2mat(cellfun(@(a) (histc(a,binvec)),raster, 'UniformOutput',false))';
        [Dm,Dn] = size(D);
        
        Df = cell2mat(cellfun(@(a) (histc(a,binvec)),rasterf,'UniformOutput',false))';

        vals{1} = binvec;
        vals{2} = FDel;
        
        
        
        
        
        
        
        
        
        % Smooth APSTH
        gw = gausswin(round(gwdur/binsize));
        
        if mod(length(gw),2)
            gwoffset = [floor(length(gw)/2) ceil(length(gw)/2)];
        else
            gwoffset = [1 1]*round(length(gw)/2);
        end
        APSTH  = zeros(size(D));
        VPSTH = zeros(size(D));
        for i = 1:Dn
            p = conv(D(:,i),gw,'full');
            APSTH(:,i) = p(gwoffset(1):end-gwoffset(2)); % subtract phase delay
            
            p = conv(Df(:,i),gw,'full');
            VPSTH(:,i) = p(gwoffset(1):end-gwoffset(2)); % subtract phase delay
        end
        APSTH = APSTH/max(APSTH(:)) * max(D(:)); % rescale APSTH
        APSTH = APSTH/binsize; % count -> firing rate
        APSTH(APSTH<0) = 0;
        APSTHmean = mean(APSTH,2);
        APSTHstd  = std(APSTH,1,2);
        
        VPSTH = VPSTH/max(VPSTH(:)) * max(Df(:)); % rescale APSTH
        VPSTH = VPSTH/binsize; % count -> firing rate
        VPSTH(VPSTH<0) = 0;
        VPSTHmean = mean(VPSTH,2);
        VPSTHstd  = std(VPSTH,1,2);
        
        
        
        % compute sum around each stimulus
        Amet  = zeros(1,Dn);
        Vmet = zeros(1,Dn);
        BLmet = zeros(1,Dn);
        for i = 1:Dn
            ind = raster{i} >= Awin(1) & raster{i} <  Awin(2);
            Amet(i)  = sum(ind);
            
            ind = rasterf{i} >= Vwin(1) & rasterf{i} <  Vwin(2);
            Vmet(i) = sum(ind);
            
            ind = raster{i} >= baselinewin(1) & raster{i} <  baselinewin(2);
            BLmet(i) = sum(ind);
        end
        
        
        % count -> firing rate
        Amet  = Amet  / diff(Awin); 
        Vmet  = Vmet  / diff(Vwin);
        BLmet = BLmet / diff(baselinewin);
        

        
        
        
        % force into bins of binsize
        dbinvec = vals{2}(1):binsize:vals{2}(end)-binsize;
        bAmet  = zeros(size(dbinvec));
        bVmet  = zeros(size(dbinvec));
        bBLmet = zeros(size(dbinvec));
        for i = 1:length(dbinvec)
            ind = vals{2} >= dbinvec(i) & vals{2} < dbinvec(i)+binsize;
            if ~any(ind), continue; end
            bAmet(i) = mean(Amet(ind));
            bVmet(i) = mean(Vmet(ind));
            bBLmet(i)= mean(BLmet(ind));
        end
        
        
        % smooth scatters 
        smsize = round(smdur/binsize);
        smbAmet  = smooth([repmat(bAmet(1),1,smsize)  bAmet  repmat(bAmet(end), 1,smsize)],smsize);
        smbVmet  = smooth([repmat(bVmet(1),1,smsize) bVmet repmat(bVmet(end),1,smsize)],smsize);
        smbBLmet = smooth([repmat(bBLmet(1),1,smsize) bBLmet repmat(bBLmet(end),1,smsize)],smsize);
        smbAmet  = smbAmet(smsize+1:end-smsize);
        smbVmet  = smbVmet(smsize+1:end-smsize);
        smbBLmet = smbBLmet(smsize+1:end-smsize);
        
        
        
  
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        %% Analysis ---------------------------------------------------

        
        BLtrials = bBLmet(round(length(bBLmet)/2)+1:end);
        Atrials = bAmet(end-15:end);
        Vtrials = bVmet(1:15);
        
        
        % mean baseline firing rate
        BL.meanfr = mean(BLtrials);
        BL.stdfr  = std(BLtrials);
        BL.semfr  = BL.stdfr / sqrt(length(BLtrials));
        
        
        % Unimodal responses characteristics
        A.meanfr = mean(Atrials);
        A.stdfr  = std(Atrials);
        A.semfr  = A.stdfr/sqrt(length(Atrials));
        
        V.meanfr = mean(Vtrials);
        V.stdfr  = std(Vtrials);
        V.semfr  = V.stdfr/sqrt(length(Vtrials));

        
        
        
        % TTest for unimodal response significance above baseline
        [A.ttest_h,A.ttest_p] = ttest2(Atrials,BLtrials);
        [V.ttest_h,V.ttest_p] = ttest2(Vtrials,BLtrials);
        
        if isnan(A.ttest_h), A.ttest_h = 0; A.ttest_p = 1; end
        if isnan(V.ttest_h), V.ttest_h = 0; V.ttest_p = 1; end
        
        % Check for inhibited response
        A.Inhibited = A.ttest_h & A.meanfr < BL.meanfr;
        V.Inhibited = V.ttest_h & V.meanfr < BL.meanfr;
            
        
        
        % Find response onset and offset
        rind = binvec >= Awin(1) & binvec <= Awin(2);
        rvec = binvec(rind);
        if A.Inhibited
            A.resp_thr = BL.meanfr;
            [A.resp_on,A.resp_off] = ResponseLatency(APSTHmean(rind),rvec, ...
                A.resp_thr,'lt','largest',5,1);
        else
            A.resp_thr = BL.meanfr+BL.stdfr*3;    
            [A.resp_on,A.resp_off] = ResponseLatency(APSTHmean(rind),rvec, ...
                A.resp_thr,'gte','span',5,1);
        end
        
        
        rind = binvec >= Vwin(1) & binvec <= Vwin(2);
        rvec = binvec(rind);
        if V.Inhibited
            V.resp_thr = BL.meanfr;
            [V.resp_on,V.resp_off] = ResponseLatency(VPSTHmean(rind),rvec, ...
                V.resp_thr,'lt','largest',5,1);
        else
            V.resp_thr = BL.meanfr+BL.stdfr*3;    
            [V.resp_on,V.resp_off] = ResponseLatency(VPSTHmean(rind),rvec, ...
                V.resp_thr,'gte','span',5,1);
        end        
        
        
        
        
        
        % find maximum and minimum response interactions

        % Visual leading Auditory
        [m,i] = max(smbAmet(dbinvec<0));
        VA.max_interact = m;
        VA.max_soa = dbinvec(i);
        
        [m,i] = min(smbAmet(dbinvec<0));
        VA.min_interact = m;
        VA.min_soa = dbinvec(i);

        % Auditory leading Visual
        [m,i] = max(smbVmet(dbinvec>0));
        AV.max_interact = m;
        AV.max_soa = dbinvec(i+find(dbinvec>0,1)-1);
        
        [m,i] = min(smbVmet(dbinvec>0));
        AV.min_interact = m;
        AV.min_soa = dbinvec(i+find(dbinvec>0,1)-1);
       
        
        
        
        
        
        
        % Which unimodal response is greatest
        if A.meanfr >= V.meanfr
            R.driver = 'Auditory';
        else
            R.driver = 'Visual';
        end
        
        
        
        
        
        
        
        
        
        
        
        
        
        % Test for an interaction between the driving modality and the
        % other modality at maximum interaction
        if isequal(R.driver,'Auditory')
            [~,R.Int_ttest_p] = ttest(Atrials,VA.max_interact,alpha,'left');
        else
            [~,R.Int_ttest_p] = ttest(Vtrials,AV.max_interact,alpha,'left');
        end
        
        
        % Determine superadditivity of maximum interacting response
        [~, AV.Sadd_ttest_p] = ttest(Vtrials + A.meanfr,AV.max_interact,alpha,'left');
        [~, VA.Sadd_ttest_p] = ttest(Atrials + V.meanfr,VA.max_interact,alpha,'left');
        
        
        % Determine if interacting response is suppressed compared to unimodal response
        [~, AV.Supr_ttest_p] = ttest(Vtrials,AV.min_interact,alpha,'right');
        [~, VA.Supr_ttest_p] = ttest(Atrials,VA.min_interact,alpha,'right');
        
       
        
        
        
        
        
        
        
        
        % Correct P values using Holm-Bonferroni method
        pvals = [A.ttest_p, V.ttest_p, AV.Sadd_ttest_p, VA.Sadd_ttest_p, ...
            AV.Supr_ttest_p, VA.Supr_ttest_p, R.Int_ttest_p];
        
        pvals(isnan(pvals)) = 1;
        
        [cp,hb] = bonf_holm(pvals,alpha); 
        
        A.ttest_p = cp(1);         A.ttest_h = hb(1);
        V.ttest_p = cp(2);         V.ttest_h = hb(2);
        AV.Sadd_ttest_p = cp(3);   AV.Sadd_ttest_h = hb(3);
        VA.Sadd_ttest_p = cp(4);   VA.Sadd_ttest_h = hb(4);
        AV.Supr_ttest_p = cp(5);   AV.Supr_ttest_h = hb(5);
        VA.Supr_ttest_p = cp(6);   VA.Supr_ttest_h = hb(6);
        R.Int_ttest_p = cp(7);     R.Int_ttest_h = hb(7);
        
        
        AV.superadditive = AV.Sadd_ttest_h;
        VA.superadditive = VA.Sadd_ttest_h;
        
        AV.suppressive = AV.Supr_ttest_h;
        VA.suppressive = VA.Supr_ttest_h;
        
        R.Integrating = R.Int_ttest_h;
        
        
    
        
        
        
        

        
        
        % Determine response type
        if A.ttest_h && V.ttest_h,   R.modalness = 'Bimodal';  end
        if xor(A.ttest_h,V.ttest_h), R.modalness = 'Unimodal'; end
        if ~A.ttest_h && ~V.ttest_h, R.modalness = 'Amodal';   end
        
        
      

        
        
        
        
        
        
        
        % Categorize response type
        R.class = sprintf('%s, %s',R.driver,R.modalness);

        if R.Integrating
            R.class = sprintf('%s, Integrating',R.class);
        else
            R.class = sprintf('%s, Non-Integrating',R.class);
        end
        R.Subthreshold = strcmp(R.modalness,'Unimodal') ...
                         & ((isequal(R.driver,'Auditory') & VA.Sadd_ttest_h) ...
                         |  (isequal(R.driver,'Visual')   & AV.Sadd_ttest_h));
        
        if R.Subthreshold
            R.class = sprintf('%s, Subthreshold Multisensory',R.class);
        end
        
        if isequal(R.driver,'Auditory') && VA.Sadd_ttest_h ...
                ||  isequal(R.driver,'Visual') && AV.Sadd_ttest_h
            R.class = sprintf('%s, Superadditive',R.class);
        end
        
        if isequal(R.driver,'Auditory') && VA.Supr_ttest_h ...
                || isequal(R.driver,'Visual') && AV.Supr_ttest_h
            R.class = sprintf('%s, Suppressive',R.class);
        end
        
        fprintf('\n\nClassification: %s\n\n',R.class)
        
        
        
        
        
        
        
        
        
        
        
        
        
        % Spectral analysis to find maximum oscillation
        binnedFs = 1/binsize;
        
        y = smbAmet(dbinvec<=0);
        L = length(y);
        [pxx,pf] = periodogram(y,hamming(L),15:0.1:100,binnedFs);
        [pks,locs] = findpeaks(pxx);
        if isempty(pks)
            VA.osci_amp = nan;
            VA.osci_freq = nan;
        else
            [VA.osci_amp,i] = max(pks);
            VA.osci_freq = pf(locs(i));
        end
        VA.powspec_sum = sum(pxx);
        fprintf('VA: Peak oscillation:\tfreq = %3.1f Hz\tAmp = %0.4f\n', ...
            VA.osci_freq, VA.osci_amp)
        
        y = smbVmet(dbinvec>=0);
        L = length(y);
        [pxx,pf] = periodogram(y,hamming(L),15:0.1:100,binnedFs);
        [pks,locs] = findpeaks(pxx);
        if isempty(pks)
            AV.osci_amp = nan;
            AV.osci_freq = nan;
        else
            [AV.osci_amp,i] = max(pks);
            AV.osci_freq = pf(locs(i));
        end
        AV.powspec_sum = sum(pxx);
        fprintf('AV: Peak oscillation:\tfreq = %3.1f Hz\tAmp = %0.4f\n', ...
            AV.osci_freq, AV.osci_amp)
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        %% Plot response -----------------------------------------------
        f = findFigure('TSlew','position',[740 720 800 230],'color','w');
        figure(f);
        clf(f)
        
        set(f,'name',sprintf('UnitID %d',unit_id));
        
        % RASTER IMAGE PLOT
        ax_main = subplot(10,5,[11 49]);
        pos_main = get(ax_main,'position');
        imagesc(vals{1},vals{2},D')
        set(ax_main,'ydir','normal');
        hold(ax_main,'on');
        plot(xlim,[0 0],'color',[0.6 0.6 0.6]);
        plot([0 0],ylim,'color',[0.6 0.6 0.6]);
        plot(vals{2},vals{2},'color',[0.8 0.3 0.3]);      
        plot(Awin([1 2; 1 2]),dbinvec([end end; end-[1 1]*length(Atrials)]),'-','linewidth',3,'color',[0.6 0.6 0.6])
        plot(dbinvec([1 1; [1 1]*length(Vtrials)])+Vwin([1 2; 1 2]),dbinvec([1 1; [1 1]*length(Vtrials)]),'-','linewidth',3,'color',[0.8 0.3 0.3])
        plot(Awin([1 2; 1 2]),dbinvec([1 1; end end]),':','linewidth',1,'color',[0.6 0.6 0.6])
        plot(dbinvec([1 1; end end])+Vwin([1 2; 1 2]),dbinvec([1 1; end end]),':','linewidth',1,'color',[0.8 0.3 0.3])
%         colormap([0 0 0; 1 1 1]);
        colormap(gray(32));
        ylabel('Flash onset re A onset');
        xlabel('Time re A onset');
        
        
        % APSTH PLOT
        ax_psth = subplot(10,5,[1 9]);
        pos_psth = get(ax_psth,'position');
        plot(vals{1},APSTHmean,'k','linewidth',3);
        hold on
        plot(vals{1},VPSTHmean,'-','color',[0.8 0.3 0.3],'linewidth',3);
        plot([0 0],ylim,'color',[0.6 0.6 0.6]);
        plot(Awin,[0.95 0.95]*max(ylim),'color',[0.6 0.6 0.6],'linewidth',2);
        plot(Vwin,[0.9 0.9]*max(ylim),'color',[0.8 0.3 0.3],'linewidth',2);
        plot([A.resp_on A.resp_off],[1 1]*A.resp_thr,'d-','color',[0.1 0.8 0.1],'markerfacecolor',[0.1 0.8 0.1]);
        plot([V.resp_on V.resp_off],[1 1]*V.resp_thr,'d-','color',[0.1 0.1 0.8],'markerfacecolor',[0.1 0.1 0.8]);
        xlim(binvec([1 end]));
        ylim([0 max(ylim)]);
        ylabel('Firing Rate (Hz)');
        title(sprintf('%s',R.class));
        
        
        % SPIKE WAVEFORM
        ax_spike = axes('position',[0.67 0.85 0.08 0.1]); %#ok<LAXES>
        plot(swtvec([1 end]),[0 0],':','color',[0.3 0.3 0.3]);
        hold(ax_spike,'on');
        fill([swtvec fliplr(swtvec)],[swave+swstddev fliplr(swave-swstddev)],[0.8 0.8 0.8],'linestyle','none');
        plot(swtvec,swave,'-k','linewidth',2);
        xlim(swtvec([1 end]));
        ylim([-1.2 1.2]*max(abs(swave)));
        set(ax_spike,'xtick',[],'ytick',[]);
        c = myms(sprintf(['SELECT c.class FROM units u ', ...
            'JOIN class_lists.pool_class c ON c.id = u.pool ', ...
            'WHERE u.id = %d'],unit_id),conn,'cellarray');
        title(ax_spike,sprintf('Unit ID: %d\n(%s, %d spikes)', ...
            unit_id,char(c),numel(st)));
        
        
        % INTERACTION PLOT
        ax_interact = subplot(10,5,[20 50]);
        pos_interact = get(ax_interact,'position');
        set(ax_interact,'position',[pos_interact(1:3) pos_main(end)], ...
            'yaxisLocation','right');
        hold(ax_interact,'on');
        ylim([min(vals{2}) max(vals{2})]);
        xoffset = max([smbAmet(:); smbVmet(:)])/5;
        plot(smbAmet(dbinvec<=0),  dbinvec(dbinvec<=0),'-','linewidth',3,'color',[0.3 0.3 0.3]);
        plot(smbVmet(dbinvec>=0), dbinvec(dbinvec>=0),'-','linewidth',3,'color',[0.8 0.3 0.3]);
        plot(smbAmet,  dbinvec,'-','linewidth',1,'color',[0.3 0.3 0.3]);
        plot(smbVmet, dbinvec,'-','linewidth',1,'color',[0.8 0.3 0.3]);
        plot([1 1]*BL.meanfr,ylim,'-','linewidth',1,'color',[0.8 0.8 0.8]);
        plot([1 1]*A.meanfr,ylim,':','linewidth',2,'color',[0.3 0.3 0.3]);
        plot([1 1]*V.meanfr,ylim,':','linewidth',2,'color',[0.8 0.3 0.3]);
        plot(VA.max_interact+xoffset,VA.max_soa,'<','markersize',6,'color',[0.3 0.3 0.3],'markerfacecolor',[0.3 0.3 0.3]);
        plot(VA.min_interact+xoffset,VA.min_soa,'o','markersize',6,'color',[0.3 0.3 0.3],'markerfacecolor',[0.3 0.3 0.3]);
        plot(AV.max_interact+xoffset,AV.max_soa,'<','markersize',6,'color',[0.8 0.3 0.3],'markerfacecolor',[0.8 0.3 0.3]);
        plot(AV.min_interact+xoffset,AV.min_soa,'o','markersize',6,'color',[0.8 0.3 0.3],'markerfacecolor',[0.8 0.3 0.3]);
        xlim([0 max(xlim)]);
        plot(xlim,[0 0],'color',[0.6 0.6 0.6]);
        xlabel('Firing Rate (Hz)');
        ylabel('Flash onset re A onset');
        box on
        
        
        
        % BAR PLOT
        ax_bar = subplot(10,5,10);
        pos_bar = get(ax_bar,'position');
        set(ax_bar,'position',[pos_bar(1:3) pos_psth(4)]);
        h = bar([A.meanfr V.meanfr VA.max_interact VA.min_interact ...
            AV.max_interact AV.min_interact],'facecolor',[0.5 0.5 0.5]);
        xlim([0 7]);
        hold(ax_bar,'on');
        ylabel('Firing Rate (Hz)')
        plot([1 1],A.meanfr+[1 -1]*A.semfr,'-k');
        plot([2 2],V.meanfr+[1 -1]*V.semfr,'-k');
        plot(xlim,[1 1]*BL.meanfr,'--','linewidth',2,'color',[0.3 0.3 0.3]); % spontaneous rate
        plot(xlim,[1 1]*(A.meanfr+V.meanfr),':','linewidth',1,'color',[0.6 0.6 0.6]); % sum of unimodal rates
        set(ax_bar,'xtick',1:6,'xticklabel',{'A','V','VA','va','AV','av'},'yaxislocation','right');
        astoffset = max(ylim)/15;
        if A.ttest_h,        plot(1,A.meanfr+astoffset,       '*','color',[0.8 0.3 0.3]); end
        if V.ttest_h,        plot(2,V.meanfr+astoffset,       '*','color',[0.8 0.3 0.3]); end
        if VA.superadditive, plot(3,VA.max_interact+astoffset,'*','color',[0.8 0.3 0.3]); end
        if VA.suppressive,   plot(4,VA.min_interact+astoffset,'*','color',[0.8 0.3 0.3]); end
        if AV.superadditive, plot(5,AV.max_interact+astoffset,'*','color',[0.8 0.3 0.3]); end
        if AV.suppressive,   plot(6,AV.min_interact+astoffset,'*','color',[0.8 0.3 0.3]); end
        title(R.modalness)
        if min(ylim) > 0, ylim(ax_bar,[0 max(ylim)]); end

        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        %% User interaction --------------------------------------------
        fprintf(['\n\nS:\tSkip unit\nA:\tAutomatically adjust Auditory window\n', ...
            'V:\tAutomatically adjust Visual window\nM:\tManually adjust windows\n', ...
            'R:\tReset windows to defaults\nP:\tRedo previous unit\nU:\tConfirm and Upload analysis results\nX:\tExit\n\n'])
        r = input('Enter command character: ','s');
        switch lower(r)
            case 'm'
                fprintf('Current windows:\n\tplotwin \t= %s\n\tAwin \t\t= %s\n\tVwin \t\t= %s\n\tbaselinewin = %s\n\n', ...
                    mat2str(plotwin),mat2str(Awin),mat2str(Vwin),mat2str(baselinewin))
                
                fprintf('A Onset = %4.3f s\tOffset = %4.3f s\n',A.resp_on,A.resp_off)
                fprintf('V Onset = %4.3f s\tOffset = %4.3f s\n',V.resp_on,V.resp_off)
                
                a = inputdlg({'plotwin','Awin','Vwin','baselinewin'}, ...
                    'Update Windows',1,{mat2str(plotwin),mat2str(Awin), ...
                    mat2str(Vwin),mat2str(baselinewin)});
                
                if isempty(a), continue; end
                
                plotwin     = str2num(a{1}); %#ok<*ST2NM>
                Awin       = str2num(a{2});
                Vwin       = str2num(a{3});
                baselinewin = str2num(a{4});
                
            case 'v'
                Vwin = [V.resp_on V.resp_off];
                
            case 'a'
                Awin = [A.resp_on A.resp_off];
                
            case 'u'
                % Upload analysis results to database
                A.groupid  = 'TSlew:Aud';
                V.groupid  = 'TSlew:Vis';
                AV.groupid = 'TSlew:Aud_Vis';
                VA.groupid = 'TSlew:Vis_Aud';
                R.groupid  = 'TSlew:Response';
                DB_UpdateUnitProps(unit_id,A, 'groupid',true,conn);
                DB_UpdateUnitProps(unit_id,V, 'groupid',true,conn);
                DB_UpdateUnitProps(unit_id,AV,'groupid',true,conn);
                DB_UpdateUnitProps(unit_id,VA,'groupid',true,conn);
                DB_UpdateUnitProps(unit_id,R, 'groupid',true,conn);
                break
                
            case 'r'
                % default analysis windows
                Awin = [0.005 0.08];
                Vwin = [0.005 0.08];
            
            case 'p'
                % redo previous unit
                prevflag = true;
                u = u - 2;
                break
                
            case 's'
                X.groupid = 'TSlew:Skipped';
                X.skipped = 1;
                DB_UpdateUnitProps(unit_id,X,'groupid',false,conn);
                fprintf('Skipped Unit ID %d\n',unit_id)
                break
                
            case 'x'
                fprintf('\nI guess we''re done for now\nProcessed %d units. %4d units to go!\n',u-1,length(UNITS)-u+1)
                return
                
            otherwise
                fprintf(2,'I didn''t understand "%s" ...\n',r) %#ok<PRTCAL>
                
        end
        
        if numel(Awin) ~= 2 || any(isnan(Awin)) || Awin(1) >= Awin(2)
            fprintf(2,'Invalid values for Auditory window: %s\n',mat2str(Awin));
            Awin = [0.005 0.08];
        end
        
        if numel(Vwin) ~= 2 || any(isnan(Vwin)) || Vwin(1) >= Vwin(2)
            fprintf(2,'Invalid values for Visual window: %s\n',mat2str(Vwin));
            Vwin = [0.005 0.08];
        end
        
        
        
        fprintf('\n\n')
    end
    
    
    u = u + 1;
end






fprintf('No more spikes to look at!\n')


