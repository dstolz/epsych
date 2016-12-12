%% Response Latency
function RL = NHP_PlotResponseLatency(Data,ax)
persistent Lo

IND = NHP_decodeResponseCode([Data.ResponseCode]);

Angle = [Data.Behavior_Speaker_Angle];
uAngle = unique(Angle);

rl = cell(size(uAngle));
for i = 1:length(uAngle)
    ind = uAngle(i) == Angle;
    
    ind = ind & ~(IND.Abort | IND.NoResponse);
    
    rl{i} = [Data(ind).Behavior_RespLatency];
end

RL.mean = cellfun(@mean,rl);
RL.median = cellfun(@median,rl);
RL.std  = cellfun(@std,rl);
RL.count = cellfun(@length,rl);
RL.sem  = RL.std./sqrt(RL.count);

if nargin == 1 || ~ishandle(ax)
    f = findFigure('ResponseLatency','color','w','Name','Response Latency');
    ax = findobj(f,'tag','respax');
end

if isempty(ax)
    ax = axes('parent',f,'tag','respax','box','on');
    Lo = [];
end

if ~isfield(Lo,'Hits') || isempty(Lo.Hits)
    Lo.Hits = line(0,0,'parent',ax,'linestyle','none','marker','.','color',[0.5 0.8 0.5]);
    Lo.Miss = line(0,0,'parent',ax,'linestyle','none','marker','.','color',[0.8 0.5 0.5]);
    Lo.Medi = line(0,0,'parent',ax,'linestyle',':', ...
        'marker','o','markerfacecolor','k','color',[0.8 0.5 0.5]);
    Lo.Stim = line(0,0,'parent',ax,'linestyle','-','linewidth',10, ...
        'color',[0.8 0.8 0.8]);
end

% hold(ax,'on');
ind = logical(IND.Hit);
% plot(ax,Angle(ind)-1,[Data(ind).Behavior_RespLatency],'.','color',[0.5 0.8 0.5])
set(Lo.Hits,'xdata',Angle(ind)-1,'ydata',[Data(ind).Behavior_RespLatency]);

ind = logical(IND.Miss);
% plot(ax,Angle(ind)+1,[Data(ind).Behavior_RespLatency],'.','color',[0.8 0.5 0.5])
set(Lo.Miss,'xdata',Angle(ind)+1,'ydata',[Data(ind).Behavior_RespLatency]);

% plot(ax,uAngle,RL.mean,'-sk',uAngle,RL.mean(:)*[1 1]+RL.sem(:)*[-1 1],':k');
% plot(ax,uAngle,RL.median,':ok','markerfacecolor','k');
set(Lo.Medi,'xdata',uAngle,'ydata',RL.median);

% draw stimulus marker
% plot(ax,min(xlim)*[1 1],[0 200],'-', ...
%     'linewidth',10,'color',[0.8 0.8 0.8])
set(Lo.Stim,'xdata',min(xlim)*[1 1],'ydata',[0 200]);

% hold(ax,'off');
ylim(ax,[0 1000])

% title(sprintf('Mean Response Latency (%cSEM)',char(177)))
title(ax,'Mean Response Latency')
xlabel(ax,'Speaker Angle (deg)');
ylabel(ax,'Latency re Stim Onset (ms)');


