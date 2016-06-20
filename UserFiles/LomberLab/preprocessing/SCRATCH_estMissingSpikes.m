%% Read a PLX file and estimate how many spikes are likely to be missing based on thresholding errors
% Fits a normal distribution to peak amplitudes of spikes and estimates how
% many peak amplitudes would be expected above the threshold. DJS 5/2016

[fn,pn,fi] = uigetfile('*.plx','Plexon File');
plxfilename = fullfile(pn,fn);


%%
Channel = 19

%
f = findFigure('spikes','color','w');

figure(f);

[units,ts,waves] = PLX2MAT(plxfilename,{Channel});
W = waves{1}; U = units{1}; T = ts{1};
clf(f);

minSamp = round(0.425*size(W,2));
threshguess = double(min(max(W(:,1:minSamp))));
% threshguess = double(mode(min(W)));
% idx = find(W' == threshguess);
% [i,~]=ind2sub(size(W'),idx);
% minSamp = mode(i); % round(mean(i))

uU = unique(U);
k = 1;
for u = 1:length(uU)
    subplot(length(uU),3,k); k = k+1;
    
    idx = find(U == uU(u));
    if numel(idx) > 2500
        plot(W(idx(randsample(numel(idx),2500)),:)');
    else
        plot(W(idx,:)');
    end
    hold(gca,'on')
    plot(xlim,[1 1]*threshguess,'--b')
    
    m = double(max(abs(W(:))));
    set(gca,'xlim',[1 size(W,2)],'ylim',[-1 1]*m);
    title(gca,sprintf('%d | %d spikes',Channel,length(idx)))
    ylabel(gca,sprintf('Unit %d',uU(u)))
    
    
    
    
    
    subplot(length(uU),3,k); k = k + 1;
    
    a = W(idx,minSamp);
    plot(T(idx),a,'.k')
    hold on
    plot(T([1 end]),[0 0],'-k');
    plot(T([1 end]),[1 1]*threshguess,'--b')
    set(gca,'ylim',[-m 100],'xlim',T([1 end]));
    
    title(gca,'Time (sec)')
    
    
    
    
    
    
    
    
    
    subplot(length(uU),3,k); k = k + 1;
    
    [ha,hb] = hist(double(a),50);
    h = barh(hb,ha,'k');
    hold on
    
    plot([0 max(xlim)],[0 0],'-k');
    plot(xlim,[1 1]*threshguess,'--b')
    set(h,'facecolor','k');
    set(gca,'ylim',[-m 100]);
    
    if length(a) > 10
        pd = fitdist(double(a),'normal');
        q = icdf(pd,[0.0013499 0.99865]); % three-sigma range for normal distribution
        x = linspace(q(1),q(2));
        y = pdf(pd,x);
        hbwidth = hb(2) - hb(1);
        area = numel(a) * hbwidth;
        y = area * y;
        p = 1-normcdf(threshguess,pd.mu,pd.std);
        nmissing = round(p*numel(a));
        
        plot(y,x,'-r','linewidth',2)
        set(gca,'yticklabel',[])
        title(gca,sprintf('~%d missing (%%%0.1f)',nmissing,100*nmissing/numel(idx)))
    else
        title(gca,'Not enough spikes')
    end
    
    
    
    
    drawnow
end




