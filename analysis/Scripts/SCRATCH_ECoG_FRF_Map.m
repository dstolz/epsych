%%  ECoG Map

tank = 'THYME_ECog';
block = 3;


% emap = [1 5 9 13 20 24 28 32; 2 6 10 14 19 23 27 31; 3 7 11 15 18 22 26 30; 4 8 12 16 17 21 25 29]';
emap = [1:4;5:8;9:12;13:16;20:-1:17;24:-1:21;28:-1:25;32:-1:29];




win = [0.0 0.05];

denoise = 1;
scaleall = 0;


data = TDT2mat(tank,sprintf('Block-%d',block),'type',[2 4],'silent',true);

chans = data.streams.Wave.chan;
freq = data.epocs.Freq.data; ufreq = unique(freq);
levl = data.epocs.Levl.data; ulevl = unique(levl);
trials = data.epocs.Freq.onset;


if ~exist('emap','var') || isempty(emap)
    emap = chans;
end

Fs = data.streams.Wave.fs;

W = data.streams.Wave.data;
t = 0:1/Fs:size(W,1)/Fs-1/Fs;

clear data;

strials = round(trials*Fs);
svec = round(win(1)*Fs):round(win(2)*Fs)-1;

Wt = zeros(length(svec),size(W,2),length(trials));
for i = 1:length(strials)
    idx = strials(i) + svec;
    Wt(:,:,i) = W(idx,:);
end
clear W


Wtrms = squeeze(sqrt(mean(Wt.^2)));
clear Wt

%
FRF = zeros(length(ufreq),length(ulevl),length(chans));
for F = 1:length(ufreq)
    for L = 1:length(ulevl)
        ind = ufreq(F) == freq & ulevl(L) == levl; 
        FRF(F,L,:) = mean(Wtrms(:,ind),2);
    end
end

thisname = sprintf('%s_Block-%d',tank,block);
f = findobj('type','figure','-and','name',thisname);
if isempty(f), f = figure('name',thisname); end
figure(f);

[nrows,ncols] = size(emap);
for i = 1:size(FRF,3)
    subplot(nrows,ncols,i)
    
    d = squeeze(FRF(:,:,emap(i)))';
    if denoise, d = sgsmooth2d(d); end
    
    %     imagesc(ufreq,ulevl,sgsmooth2d(squeeze(FRF(:,:,i))'));
    surf(ufreq,ulevl,d);
    %     surf(ufreq,ulevl,squeeze(FRF(:,:,i))');
    
    if denoise
        shading('interp')
    else
        shading('flat') 
    end
    
%     c = get(gca,'clim');
%     set(gca,'clim',[0 c(2)*0.7]);

    view(2)
    axis tight
    
    title(i)
end
ax = findobj(gcf,'type','axes');
set(ax,'xscale','log')

if scaleall
    set(ax,'climmode','auto');
    c = cell2mat(get(ax,'clim'));
    set(ax,'clim',[0 0.85 * max(c(:,2))]);
end




