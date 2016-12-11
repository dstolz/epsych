function plot_AMJitter_stimWaveform(buffer)
% Plots a polar histogram of spiking during the AM portion of a stimulus. 

set(0,'DefaultAxesFontSize',10)
set(0,'DefaultTextInterpreter','none')

% if nargin<5
%     savedir  = '/Users/kpenikis/Documents/SanesLab/Data/processed_data';
%     savename = sprintf('%s_sess-%s_raster_ch%i_clu%i',subject,session,channel,clu);
%     load(fullfile(savedir,subject,savename))
% end
    
% Load new rate vector stimulus info
% % block = raster(1).block;
% % stimdir  = '/Users/kpenikis/Documents/SanesLab/Data/raw_data';
% % stfs = dir(fullfile(stimdir,subject,sprintf('Block-%i_Stim',block),'*.mat'));
% % stfns = {stfs.name};
% % 
% % % Get vectors of rates for stimuli of this block
% % for iif = 1:numel(stfs)
% %     rateVecs(iif) = load(fullfile(stfs(iif).folder,stfns{iif}));
% % end
% % 
% % for ks = 1:numel(raster)
% %     
% %     data = raster(ks);
% %     
% %     if block ~= data.block
% %         
% %         % Load new rate vector stimulus info
% %         block = data.block;
% %         stfs = dir(fullfile(stimdir,subject,sprintf('Block-%i_Stim',block),'*.mat'));
% %         stfns = {stfs.name};
% %         
% %         % Get vectors of rates for stimuli of this block
% %         for iif = 1:numel(stfs)
% %             rateVecs(iif) = load(fullfile(stfs(iif).folder,stfns{iif}));
% %         end
% %         
% %     end
% %     
% %     % Get rate vector for current stimulus
% %     rV = rateVecs(strcmp(stfns,data.stimfn)).buffer;
    rV = buffer;
    rV = rV(2:end);
    
    fs = 1e3;
    t  = cumsum([0 1./rV]);
    s = round(t.*fs);
    y  = [];
    for ip = 1:numel(rV)
        tp=[]; tp = 0:(s(ip+1)-s(ip)-1);
        y = [y 1-cos(2*pi*rV(ip)/fs*tp)];
%         if numel(unique(rV))>1
%         figure(1); clf; plot(1-cos(2*pi*rV(ip)/fs*tp))
%         keyboard
%         end
    end
    % Remove first 1/4 of the first period
    yclip = y(round(0.25/rV(1)*fs)+1:end);
    % Add sound during unmodulated portion
    t_AMonset = 150 + 25/rV(1);
    y_um = ones(1,round(t_AMonset/1000*fs)); %0.8165.*
    stim = [y_um yclip];
    
    hF = figure;
    scrsz = get(0,'ScreenSize');
    set(hF,'Position',[1 scrsz(4)/2 scrsz(3) scrsz(4)/2],...
        'Nextplot','add');
    fill([1:length(stim) length(stim):-1:1] /fs*1000,[stim fliplr(-stim)],[0.8 0.8 0.8])
    hold on
    xtx = 500:500:3000;
    for itx=xtx
        plot([itx itx],[-2 2],'k--')
    end
    xlim([0 length(stim)]/fs*1000)
    xlabel('time (ms)')
    title(['Jitter range: ' num2str(min(buffer)) ' to ' num2str(max(buffer)) ' Hz '])
        
    
% % end
% % keyboard
end




