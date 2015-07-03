%%

tank = 'ZAZU_2';
block = 13;

%
emap = [17 31 19 29 21 27 23 25 18 32 20 30 22 28 24 26 1 15 3 13 5 11 7 9 2 16 4 14 6 12 8 10];
%
win = [-0.025 0.6];

data = TDT2mat(tank,sprintf('Block-%d',block),'type',[2 3],'silent',true);

%-------------------------------------------------

Rate = data.epocs.Rate.data;
fpidx = [1; find(diff(Rate))+1];

uRate = unique(Rate);

onsets = data.epocs.Rate.onset(fpidx);
trials = [onsets + win(1) onsets + win(2)];

chans = data.snips.eNeu.chan;

ts = data.snips.eNeu.ts;

clear data

if ~exist('emap','var') || isempty(emap)
    emap = unique(chans);
end

chspikes = cell(size(emap));
for i = 1:length(emap)
    ind = chans == emap(i);
    chspikes{i} = ts(ind);
end


tdata = cell(length(trials),length(emap));
for i = 1:length(chspikes)
    if isempty(chspikes), continue; end
    for j = 1:size(trials,1)
        ind = chspikes{i} >= trials(j,1) & chspikes{i} < trials(j,2);
        tdata{j,i} = chspikes{i}(ind) - onsets(j);
    end
end

binvec = win(1):0.001:win(2)-0.001;

hdata = zeros(length(binvec),length(uRate),length(emap));
rdata = cell(length(emap),length(uRate));
ydata = cell(size(rdata));
for i = 1:length(uRate)
    ind = uRate(i) == Rate(fpidx);
    idx = find(ind);
    for j = 1:length(emap)
        if ~any(cellfun(@any,tdata(ind,j))), continue; end
        hdata(:,i,j) = histc(cell2mat(tdata(ind,j)'),binvec);     
        for k = 1:length(idx)
            t = tdata{idx(k),j};
            rdata{j,i}(end+1:end+length(t)) = t;
            ydata{j,i}(end+1:end+length(t)) = k;
        end
        ydata{j,i} = ydata{j,i}./k + i;
    end
end

%
thisname = sprintf('%s_Block-%d',tank,block);
f = findobj('type','figure','-and','name',thisname);
if isempty(f), f = figure('name',thisname); end
figure(f);

clf(f)

nrows = floor(sqrt(length(emap)));
ncols = ceil(length(emap)/nrows);
h = [];
for j = 1:length(emap)
    subplot(nrows,ncols,j)
    hold on
    for i = 1:size(rdata,2)
        if isempty(rdata{j,i}), continue; end
%         plot(win,[i i]+1,'-','color',[0.4 0.4 0.4]);
        h(end+1) = line(rdata{j,i},ydata{j,i}); %#ok<SAGROW>
    end
    hold off
    xlim(win);
    ylim([1 i+1]);
    title(emap(j));
end
set(h,'color','k','marker','.','markersize',1,'linestyle','none');
hold off






















