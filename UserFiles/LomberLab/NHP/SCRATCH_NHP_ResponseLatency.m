%% Response Latency

RCode = NHP_decodeResponseCode([Data.ResponseCode]);


Angle = [Data.Behavior_Speaker_Angle];
uAngle = unique(Angle);

rl = cell(size(uAngle));
for i = 1:length(uAngle)
    ind = uAngle(i) == Angle;
    
    ind = ind & ~(RCode.Abort | RCode.NoResponse);
    
    rl{i} = [Data(ind).Behavior_RespLatency];
end

RL.mean = cellfun(@mean,rl);
RL.median = cellfun(@median,rl);
RL.std  = cellfun(@std,rl);
RL.count = cellfun(@length,rl);
RL.sem  = RL.std./sqrt(RL.count);

f = findFigure('ResponseLatency','color','w');
figure(f);
clf(f);

hold on


ind = logical(RCode.Hit);
plot(Angle(ind)-1,[Data(ind).Behavior_RespLatency],'.','color',[0.5 0.8 0.5])

ind = logical(RCode.Miss);
plot(Angle(ind)+1,[Data(ind).Behavior_RespLatency],'.','color',[0.8 0.5 0.5])

% plot(uAngle,RL.mean,'-sk',uAngle,RL.mean(:)*[1 1]+RL.sem(:)*[-1 1],':k');
plot(uAngle,RL.median,':ok','markerfacecolor','k');


% draw stimulus marker
plot(min(xlim)*[1 1],[0 200],'-', ...
    'linewidth',10,'color',[0.8 0.8 0.8])

hold off
ylim([0 1000])

% title(sprintf('Mean Response Latency (%cSEM)',char(177)))
title('Mean Response Latency')
xlabel('Speaker Angle (deg)');
ylabel('Latency re Stim Onset (ms)');


