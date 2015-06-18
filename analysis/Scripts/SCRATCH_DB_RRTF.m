function SCRATCH_DB_RRTF

if isempty(which('circ_r'))
    a = repmat('*',1,60);
    fprintf('%s\n\tRRTF requires the CircStat toolbox for Matlab\n%s\n',a,a)
    return
end


%%
IDs = getpref('DB_BROWSER_SELECTION');  

st = DB_GetSpiketimes(IDs.units);
P  = DB_GetParams(IDs.blocks);

%%
win = [0 0.55];
awin = [0.0 0.525]; % analysis window

fpidx = find(diff(P.VALS.Rate))+1;

uRate = P.lists.Rate;

% if any(uRate==1), fpidx = [1; fpidx]; end

VALS = structfun(@(x) (x(fpidx)),P.VALS,'UniformOutput',false);

raster = cell(size(VALS.onset));
for i = 1:length(VALS.onset)
    ind = st >= VALS.onset(i) + win(1) & st < VALS.onset(i) + win(2);
    raster{i} = st(ind) - VALS.onset(i);
end

for i = 1:length(uRate)
    ind = VALS.Rate == uRate(i);
    tname = sprintf('RR%dHz',uRate(i));
    trials.(tname) = cell(sum(ind),1);
    trials.(tname) = raster(ind);
end
% assignin('base','trials',trials);
% assignin('base','uRate',uRate);

%% Plot Rasters
f = findobj('name','DBRRTF_RASTER');
if isempty(f)
f = figure('Color',[0.98 0.98 0.98],'name','DBRRTF_RASTER');
end
figure(f)

lc = flipud(jet(length(uRate)));

fn = fieldnames(trials)';
nrows = length(fn);
k = 1;
for f = fn
    f = char(f); %#ok<FXSET>
    x = cell2mat(trials.(f));
    i = num2cell(1:length(trials.(f)))';
    y = cellfun(@(a,b) (ones(size(a))*b),trials.(f),i,'UniformOutput',false);
    y = cell2mat(y);
    
    subplot(nrows,1,k);
    plot(awin,max(y)*[1 1],'-c');

    hold on
    plot(x,y,'sk','markersize',2,'markerfacecolor','k');
    hold off
    
    set(gca,'xtick',[],'ytick',[],'xlim',win);
    ylabel(uRate(k),'color',lc(k,:));
    k = k + 1;
end
set(gca,'xtickmode','auto','ticklength',[0 0]);



%% Rayleigh statistics
% Berens, 2009 CircStat: A Matlab toolbox for circular statistics

fn = fieldnames(trials);
alpha     = cell(size(uRate));
R         = nan(size(uRate));
clear stats

for i = 1:length(uRate)
    s = cell2mat(trials.(fn{i}));
    ind = s >= awin(1) & s <= awin(2); % limit to analysis window
    s(~ind) = [];
    alpha{i} = (2*pi*s)./(1/uRate(i));
    stats(i) = circ_stats(alpha{i});  %#ok<AGROW>
    R(i)     = circ_r(alpha{i}); % resultant vector length    
end
% assignin('base','alpha',alpha);
% assignin('base','stats',stats);
% assignin('base','R',R);

%% Polar Plot of resultant vectors
f = findobj('name','DBRRTF_Analysis');
if isempty(f)
f = figure('Color',[0.98 0.98 0.98],'name','DBRRTF_Analysis');
end
figure(f)
clf

subplot(221);

zm = R'.*exp(1i*[stats.mean]);

h = polar(0,1);
delete(h);
hold on
for i = 1:length(zm)
    h = plot([0 real(zm(i))], [0, imag(zm(i))]);
    set(h,'color',lc(i,:),'linewidth',2);
end
hold off
title(gca,'Resultant Vector');

f = findobj('name','DBRRTF_Analysis');
if isempty(f)
f = figure('Color',[0.98 0.98 0.98],'name','DBRRTF_Analysis');
end
figure(f)

subplot(222)
% skip 1
[h,hl1,hl2] = plotyy(uRate(2:end),R(2:end),uRate(2:end),abs(angle(zm(2:end))));
set(h(1),'ylim',[0 1]);
set(h(2),'ylim',[0 pi],'ytick',[0 pi/2 pi],'yticklabel',{0,'pi/2','pi'});
set(h,'xlim',[uRate(1) uRate(end)]);
set(hl1,'linewidth',1.5,'marker','o');
set(hl2,'linewidth',1.5,'marker','+','linestyle',':');

grid on
ylabel(h(1),'Resultant Vector Length');
ylabel(h(2),'Abs Resultant Vector Phase');
xlabel('Repetition Rate (Hz)');





%% rMTF (Firing Rate)

cwin = [0.006 0.031]; % post-click counting window

T = 1./uRate; % click period
Ts = cell(size(T));
for i = 1:length(T)
    Ts{i} = 0:T(i):0.5-T(i);
end
Ts{1} = 0;

f = findobj('name','DBRRTF_RASTER');
if isempty(f)
f = figure('Color',[0.98 0.98 0.98],'name','DBRRTF_RASTER');
end
figure(f)

fn   = fieldnames(trials);
Cspk = cell(size(fn));
for i = 1:length(fn)
    subplot(length(fn),1,i)
    hold on
    s = cell2mat(trials.(fn{i}));
    % counting number of spikes per click within counting window cwin
    for j = 1:length(Ts{i})
        Cspk{i}(j) = sum(s >= Ts{i}(j) + cwin(1) & s <= Ts{i}(j) + cwin(2));
        plot(Ts{i}(j)+cwin,[1 1],'-r');
    end
    Cspk{i} = Cspk{i} ./ length(trials.(fn{i})); % mean number of spikes per rep at each click
    
    hold off
end

f = findobj('name','DBRRTF_Analysis');
if isempty(f)
f = figure('Color',[0.98 0.98 0.98],'name','DBRRTF_Analysis');
end
figure(f)

subplot(2,2,[3 4])
cla
hold on

for i = 1:length(Cspk)
%     stem3(T(i)*(0:length(Cspk{i})-1),ones(size(Cspk{i}))*(length(Cspk)-i),Cspk{i}, ...
%         'o:','color',lc(i,:),'LineWidth',1,'MarkerSize',5,'MarkerFaceColor',[0.4 0.4 0.4])
%     plot3(T(i)*(0:length(Cspk{i})-1),ones(size(Cspk{i}))*(length(Cspk)-i),Cspk{i}, ...
%         '-','color',lc(i,:),'LineWidth',1)
    plot(Ts{i},Cspk{i}/Cspk{i}(1),'-o','color',lc(i,:),'LineWidth',2)
end
hold off
grid on
% set(gca,'yticklabel',flipud(uRate));
xlabel('time');
% ylabel('Rep Rate (Hz)');
ylabel('Firing Rate re First Click');
% legend(fn,'Location','BestOutside')




