%%

tank = 'ZAZU_8';
block = 8;

%
emap = [17 31 19 29 21 27 23 25 18 32 20 30 22 28 24 26 1 15 3 13 5 11 7 9 2 16 4 14 6 12 8 10];
%
win = [0.0 0.05];
% win = [0.06 0.1];

denoise  = true;  % smooth FRFs
scaleall = false; % put all FRFs on the same scale

data = TDT2mat(tank,sprintf('Block-%d',block),'type',[2 3],'silent',true);

%-------------------------------------------------

chans = data.snips.eNeu.chan;
freq = data.epocs.Freq.data; ufreq = unique(freq);
levl = data.epocs.Levl.data; ulevl = unique(levl);
trials = data.epocs.Freq.onset;
trials = [trials + win(1) trials + win(2)];

if ~exist('emap','var') || isempty(emap)
    emap = unique(chans);
end

ts = data.snips.eNeu.ts;

chspikes = cell(size(emap));
for i = 1:length(emap)
    ind = chans == emap(i);
    chspikes{i} = ts(ind);
end

spikes = zeros(size(trials,1),length(emap));
for i = 1:length(chspikes)
    if isempty(chspikes), continue; end
    for j = 1:size(trials,1)
        ind =  chspikes{i} >= trials(j,1) & chspikes{i} < trials(j,2);
        spikes(j,i) = sum(ind);
    end
end


%
FRF = zeros(length(ufreq),length(ulevl),length(emap));
for F = 1:length(ufreq)
    for L = 1:length(ulevl)
        ind = ufreq(F) == freq & ulevl(L) == levl; 
        FRF(F,L,:) = nansum(spikes(ind,:))./sum(ind);
    end
end

FRF(find(isnan(FRF))) = 0; %#ok<FNDSB>

%
thisname = sprintf('%s_Block-%d',tank,block);
f = findobj('type','figure','-and','name',thisname);
if isempty(f), f = figure('name',thisname); end
figure(f);

nrows = floor(sqrt(size(FRF,3)));
ncols = ceil(size(FRF,3)/nrows);
for i = 1:size(FRF,3)
    subplot(nrows,ncols,i)
    
    d = squeeze(FRF(:,:,i))';
    if denoise, d = sgsmooth2d(d); end
    
    %     imagesc(ufreq,ulevl,sgsmooth2d(squeeze(FRF(:,:,i))'));
    surf(ufreq,ulevl,d);
    %     surf(ufreq,ulevl,squeeze(FRF(:,:,i))');
    
    if denoise
        shading('interp')
    else
        shading('flat') 
    end
    
    c = get(gca,'clim');
    set(gca,'clim',[0 c(2)*0.7]);

    view(2)
    axis tight
    
    title(emap(i))
end
ax = findobj(gcf,'type','axes');
set(ax,'xscale','log')

if scaleall
    set(ax,'climmode','auto');
    c = cell2mat(get(ax,'clim'));
    set(ax,'clim',[0 0.7 * max(c(:,2))]);
end



