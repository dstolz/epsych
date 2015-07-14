%% Noise-Flash temporal slewing analysis


plotwin = [-0.15 0.4];
NBwin = [0.005 0.055];
FLwin = [0.03 0.09];
baselinewin = [-0.15 0];
binsize = 0.001;


smdur = 0.025; % Moving average filter duration (s)
gwdur = 0.02; % Gaussian window PSTH duration (s)




DB = 'ds_a1_aaf_mod_mgb';

if isunix
    host = 'localhost';
else
    host = '129.100.241.107';
end




% Make connection to database.
if ~exist('conn','var') || ~isa(conn,'database') || ~strcmp(conn.Instance,DB) || ~isconnection(conn)
    logintimeout('driver',5);
    conn = database(DB, 'DSuser', 'B1PdI0KY8y', 'Vendor', 'MYSQL', ...
        'Server', host);
end




% Select unanalyzed units
UNITS = myms([ ...
    'SELECT DISTINCT v.unit FROM v_ids v ', ...
    'JOIN blocks b ON v.block = b.id ', ...
    'JOIN units u ON v.unit = u.id ', ...
    'JOIN db_util.protocol_types p ON b.protocol = p.pid ', ...
    'LEFT OUTER JOIN unit_properties up ON u.id = up.unit_id ', ...
    'WHERE b.in_use = TRUE AND u.in_use = TRUE ', ...
    'AND p.alias = "TSlew" ', ...
    'AND up.id IS null'],conn,'numeric');

% Randomize unit analysis order
UNITS = UNITS(randperm(numel(UNITS)));

% UNITS = 11469; % bimodal unit
% UNITS = 5621; % strong visual unit
% UNITS = 5762; % weak visual unit
% UNITS = 9461; % wierd visual unit
% UNITS = 9452; % strong auditory unit
% UNITS = 11574;
% UNITS = 11888; % bimodal unit
% UNITS = 11628; % bimodal unit

u = 1;
while u <= length(UNITS)
    clear DATA
    
    unit_id = UNITS(u);
    
    fprintf('\n%s\n',repmat('*',1,50))
    
    fprintf('Processing unit_id = %d (%d of %d)\n',unit_id,u,length(UNITS))
    
    
    
    
    % Retrieve spiketimes and protocol parameters from the database
    st = DB_GetSpiketimes(unit_id,[],conn);
    P  = DB_GetParams(unit_id,'unit',conn);
    
    
    while 1
        
        
        
        binvec = plotwin(1):binsize:plotwin(2)-binsize;
        
        
        % Reshape and bin data based on stimulus parameters
        FDel = P.VALS.FDel;
        [FDel,i] = sort(FDel);
        onsets = P.VALS.onset(i);
        raster = cell(size(onsets));
        rasterf = cell(size(onsets));
        for i = 1:length(onsets)
            ind = st >= plotwin(1) + onsets(i) & st <= plotwin(2) + onsets(i);
            raster{i}  = st(ind)' - onsets(i);
            rasterf{i} = raster{i} - FDel(i);
        end
        
        D = cell2mat(cellfun(@(a) (histc(a,binvec)),raster,'UniformOutput',false))';
        [Dm,Dn] = size(D);
        
        Df = cell2mat(cellfun(@(a) (histc(a,binvec)),rasterf,'UniformOutput',false))';

        vals{1} = binvec;
        vals{2} = FDel;
        
        % compute sum around each stimulus
        Dmet  = zeros(1,Dn);
        Dfmet = zeros(1,Dn);
        
        for i = 1:Dn
            ind = raster{i} >= NBwin(1) & raster{i} <  NBwin(2);
            Dmet(i)  = sum(ind);
            
            ind = rasterf{i} >= FLwin(1) & rasterf{i} <  FLwin(2);
            Dfmet(i) = sum(ind);
        end
        
        
        % count -> firing rate
        Dmet  = Dmet  / diff(NBwin); 
        Dfmet = Dfmet / diff(FLwin);
        
        
        
        % smooth scatters
        dbinvec = min(vals{2}):binsize:max(vals{2})-binsize;
        bDmet = zeros(size(dbinvec));
        bDfmet = zeros(size(dbinvec));
        for i = 1:length(dbinvec)
            ind = vals{2} >= dbinvec(i) & vals{2} < dbinvec(i)+binsize;
            if ~any(ind), continue; end
            bDmet(i) = mean(Dmet(ind));
            bDfmet(i)= mean(Dfmet(ind));
        end
        smsize = round(smdur/binsize);
        smbDmet  = smooth([repmat(bDmet(1),1,smsize) bDmet repmat(bDmet(1),1,smsize)], smsize);
        smbDfmet = smooth([repmat(bDfmet(1),1,smsize) bDfmet repmat(bDfmet(1),1,smsize)],smsize);
        smbDmet  = smbDmet(smsize+1:end-smsize);
        smbDfmet = smbDfmet(smsize+1:end-smsize);
        
  
        
        % Smooth PSTH
        gw = gausswin(round(gwdur/binsize));
        
        if mod(length(gw),2)
            gwoffset = [floor(length(gw)/2) ceil(length(gw)/2)];
        else
            gwoffset = [1 1]*round(length(gw)/2);
        end
        PSTH = zeros(size(D));
        PSTHf = zeros(size(D));
        for i = 1:Dn
            p = conv(D(:,i),gw,'full');
            PSTH(:,i) = p(gwoffset(1):end-gwoffset(2)); % subtract phase delay
            
            p = conv(Df(:,i),gw,'full');
            PSTHf(:,i) = p(gwoffset(1):end-gwoffset(2)); % subtract phase delay
        end
        PSTH = PSTH/max(PSTH(:)) * max(D(:)); % rescale PSTH
        PSTH(PSTH<0) = 0;
        PSTHmean = mean(PSTH,2);
        PSTHstd  = std(PSTH,1,2);
        
        PSTHf = PSTHf/max(PSTHf(:)) * max(Df(:)); % rescale PSTH
        PSTHf(PSTHf<0) = 0;
        PSTHfmean = mean(PSTHf,2);
        PSTHfstd  = std(PSTHf,1,2);
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        % Analysis ---------------------------------------------------

        % subtract mean baseline firing rate
        indr = vals{1} >= baselinewin(1) & vals{1} < baselinewin(2);
        indc = vals{2} > 0;
        tD = D(indr,indc) / binsize;
        tD = smooth(tD(:),smsize);
        BL.meanfr = mean(tD);
        BL.stdfr  = std(tD);

        
        % Unimodal responses characteristics
        NB.meanfr = mean(smbDmet(end-30:end));
        FL.meanfr = mean(smbDfmet(1:5));
                
        NB.stdfr = std(smbDmet(end-30:end));
        FL.stdfr = std(smbDfmet(1:5));
        
        [NB.ztest_h,NB.ztest_p] = ztest(smbDmet(end-30:end),BL.meanfr,BL.stdfr);
        [FL.ztest_h,FL.ztest_p] = ztest(smbDfmet(1:5),BL.meanfr,BL.stdfr);
        
        
        % Determine response type
        if NB.ztest_h && FL.ztest_h,   R.modality = 'Bimodal';  end
        if xor(NB.ztest_h,FL.ztest_h), R.modality = 'Unimodal'; end
        if ~NB.ztest_h && ~FL.ztest_h, R.modality = 'Amodal';   end
        
       
%         % Subtract baseline firing rate for the remaining analyses
%         smbDmet  = smbDmet  - BL.meanfr;
%         smbDfmet = smbDfmet - BL.meanfr;
        
        % find maximum and minimum response interactions
        % Flash leading Noise
        [m,i] = max(smbDmet(dbinvec<0));
        FL_NB.max_interact = m;
        FL_NB.max_soa = dbinvec(i);
        [m,i] = min(smbDmet(dbinvec<0));
        FL_NB.min_interact = m;
        FL_NB.min_soa = dbinvec(i);
        [FL_NB.ttest_h,FL_NB.ttest_p] = ttest(smbDmet(end-30:end),FL_NB.max_interact);

        % Noise leading Flash
        [m,i] = max(smbDfmet);
        NB_FL.max_interact = m;
        NB_FL.max_soa = dbinvec(i);
        [m,i] = min(smbDfmet);
        NB_FL.min_interact = m;
        NB_FL.min_soa = dbinvec(i);
        [NB_FL.ttest_h,NB_FL.ttest_p] = ttest(smbDfmet(end-30:end),NB_FL.max_interact);
        
        
        
        % Determine superadditivity
        NB_FL.sadditivity = NB_FL.max_interact > NB.meanfr + FL.meanfr;
        FL_NB.sadditivity = FL_NB.max_interact > NB.meanfr + FL.meanfr;
        
        % Determine supersubtractivity (?)
        NB_FL.ssubtractivity = NB_FL.min_interact < NB.meanfr - FL.meanfr;
        FL_NB.ssubtractivity = FL_NB.min_interact < FL.meanfr - NB.meanfr;
        
        
        
        % difference between flash and noise stimulus response (not currently in use)
        smFractDiff = (smbDfmet - smbDmet)./smbDmet;
        smFractDiff(isnan(smFractDiff)|isinf(smFractDiff)) = 0;
        
        smFractDiffF = (smbDmet - smbDfmet)./smbDfmet;
        smFractDiffF(isnan(smFractDiffF)|isinf(smFractDiffF)) = 0;
        
        
        
      
        
        
         
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        % Plot response -----------------------------------------------
        f = findFigure('TSlew','position',[740 720 800 230],'color','w');
        figure(f);
        clf(f)
        
        set(f,'name',sprintf('UnitID %d',unit_id));
        
        
        ax_main = subplot(10,5,[11 49]);
        pos_main = get(ax_main,'position');
        imagesc(vals{1},vals{2},D')
        set(ax_main,'ydir','normal');
        hold(ax_main,'on');
        plot(xlim,[0 0],'color',[0.6 0.6 0.6]);
        plot([0 0],ylim,'color',[0.6 0.6 0.6]);
        plot(vals{2},vals{2},'color',[0.8 0.3 0.3]);      
        plot(NBwin([1 2; 1 2]),dbinvec([end end; end-30 end-30]),'-','linewidth',3,'color',[0.6 0.6 0.6])
        plot(dbinvec([1 1; 5 5])+FLwin([1 2; 1 2]),dbinvec([1 1; 5 5]),'-','linewidth',3,'color',[0.8 0.3 0.3])
        plot(NBwin([1 2; 1 2]),dbinvec([1 1; end end]),':','linewidth',1,'color',[0.6 0.6 0.6])
        plot(dbinvec([1 1; end end])+FLwin([1 2; 1 2]),dbinvec([1 1; end end]),':','linewidth',1,'color',[0.8 0.3 0.3])
        colormap([0 0 0; 1 1 1]);
        ylabel('Flash onset re NB onset');
        xlabel('Time re NB onset');
        
        
        
        ax_psth = subplot(10,5,[1 9]);
        pos_psth = get(ax_psth,'position');
        plot(vals{1},PSTHmean,'k','linewidth',3);
        hold on
        plot(vals{1},PSTHmean+PSTHstd,'-','color',[0.6 0.6 0.6]);
        plot(vals{1},PSTHmean-PSTHstd,'-','color',[0.6 0.6 0.6]);
        plot(vals{1},PSTHfmean,'-','color',[0.8 0.3 0.3],'linewidth',3);
        plot(vals{1},PSTHfmean+PSTHfstd,'-','color',[0.8 0.3 0.3]);
        plot(vals{1},PSTHfmean-PSTHfstd,'-','color',[0.8 0.3 0.3]);
        plot([0 0],ylim,'color',[0.6 0.6 0.6]);
        plot(NBwin,[0.95 0.95]*max(ylim),'color',[0.6 0.6 0.6],'linewidth',2);
        plot(FLwin,[0.9 0.9]*max(ylim),'color',[0.8 0.3 0.3],'linewidth',2);
        xlim(binvec([1 end]));
        ylim([0 max(ylim)]);
        set(gca,'xaxisLocation','top');
        ylabel('Firing Rate (Hz)');
        xlabel('Time re Stim onset');
        
        
        
        
        ax_reflash = subplot(10,5,[20 50]);
        pos_reflash = get(ax_reflash,'position');
        set(ax_reflash,'position',[pos_reflash(1:3) pos_main(end)], ...
            'yaxisLocation','right');
        hold(ax_reflash,'on');
        ylim([min(vals{2}) max(vals{2})]);
        plot(smbDmet, dbinvec,'-','linewidth',3,'color',[0.3 0.3 0.3]);
        plot([1 1]*NB.meanfr,ylim,':','linewidth',2,'color',[0.3 0.3 0.3]);
        plot(FL_NB.max_interact*1.1,FL_NB.max_soa,'<','markersize',6,'color',[0.8 0.3 0.3],'markerfacecolor',[0.8 0.3 0.3]);
        plot([1.1 1.1]*FL_NB.max_interact,FL_NB.max_soa*[1 1]+[-0.5 0.5]*smdur,'-','linewidth',2,'color',[0.8 0.3 0.3])
        plot(FL_NB.min_interact*0.7,FL_NB.min_soa,'>','markersize',6,'color',[0.8 0.3 0.3],'markerfacecolor',[0.8 0.3 0.3]);
        plot([0.7 0.7]*FL_NB.min_interact,FL_NB.min_soa*[1 1]+[-0.5 0.5]*smdur,'-','linewidth',2,'color',[0.8 0.3 0.3])
        plot(xlim,[0 0],'color',[0.6 0.6 0.6]);
        xlabel('Firing Rate (Hz)');
        ylabel('Flash onset re NB onset');
        box on
        
        
        
        
        ax_bar = subplot(10,5,10);
        pos_bar = get(ax_bar,'position');
        set(ax_bar,'position',[pos_bar(1:3) pos_psth(4)]);
        h = bar([NB.meanfr FL.meanfr FL_NB.max_interact FL_NB.min_interact]);
        hold(ax_bar,'on');
        ylabel('Firing Rate (Hz)')
        plot(xlim,[1 1]*(NB.meanfr+FL.meanfr),':','linewidth',2,'color',[0.6 0.6 0.6]);
        plot(xlim,[1 1]*(NB.meanfr-FL.meanfr),':','linewidth',2,'color',[0.6 0.6 0.6]);
        if min(ylim) > 0, ylim(ax_bar,[0 max(ylim)]); end
        set(ax_bar,'xtick',1:4,'xticklabel',{'NB','FL','I','i'},'yaxislocation','right');
        if NB.ztest_h, plot(1,NB.meanfr*1.05,'*','color',[0.8 0.3 0.3]); end
        if FL.ztest_h, plot(2,FL.meanfr*1.05,'*','color',[0.8 0.3 0.3]); end
        if FL_NB.sadditivity, plot(3,FL_NB.max_interact*1.05,'+','color',[0.8 0.3 0.3]); end
        if FL_NB.ssubtractivity, plot(4,FL_NB.min_interact*1.05,'v','color',[0.8 0.3 0.3]); end
        title(R.modality)
        
        
        
        
        
%         ax_FD = subplot(10,5,[20 50]);
%         pos_FD = get(ax_FD,'position');
%         set(ax_FD,'Position',[pos_FD(1:3) pos_main(4)]);
%         hold on
%         plot(smFractDiff,dbinvec,'-','color',[0.8 0.3 0.3],'linewidth',3);
%         ylim(dbinvec([1 end]));
%         mafd = max(abs([smFractDiff(:); smFractDiffF(:)]));
%         if mafd <= 0, mafd = 1; end
%         xlim([-1.1 1.1]*mafd);
%         plot(xlim,[0 0],':','color',[0.6 0.6 0.6]);
%         plot([0 0],ylim,':','color',[0.6 0.6 0.6]);
%         set(ax_FD,'yaxisLocation','right');
%         xlabel('Fractional Diff');
%         ylabel('Flash re NB');
%         box on
        
        
        
        
%         ax_comp = subplot(10,5,9);
%         pos_comp = get(ax_comp,'position');
%         set(ax_comp,'position',[pos_comp(1:3) pos_psth(4)]);
        
%         f = findFigure('hmap','color','w');
%         clf(f);
%         figure(f);
%         imagesc(dbinvec,dbinvec,smConfuse);
%         hold on
%         plot(dbinvec([1 end]),[0 0],'--','linewidth',2,'color',[0.6 0.6 0.6]);
%         plot([0 0],dbinvec([1 end]),'--','linewidth',2,'color',[0.6 0.6 0.6]);
%         set(gca,'ydir','normal');
%         axis square
%         colorbar
%         colormap jet
%         xlabel('re NB')
%         ylabel('re Flash')
% 
%         
%         
%         
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        % User interaction --------------------------------------------
        r = input('Modify Windows (y/n)?  ','s');
        if isequal(lower(r),'y')
            fprintf('Current windows:\n\tplotwin \t= %s\n\tNBwin \t\t= %s\n\tFLwin \t\t= %s\n\tbaselinewin = %s\n\n', ...
                mat2str(plotwin),mat2str(NBwin),mat2str(FLwin),mat2str(baselinewin))
            
            a = inputdlg({'plotwin','NBwin','FLwin','baselinewin'}, ...
                'Update Windows',1,{mat2str(plotwin),mat2str(NBwin), ...
                mat2str(FLwin),mat2str(baselinewin)});
            
            if isempty(a), continue; end
            
            plotwin     = str2num(a{1}); %#ok<*ST2NM>
            NBwin       = str2num(a{2});
            FLwin       = str2num(a{3});
            baselinewin = str2num(a{4});
        else
            break
        end
        
        
        
    end
    
    
    
    
%     pause








    
    
    u = u + 1;
end