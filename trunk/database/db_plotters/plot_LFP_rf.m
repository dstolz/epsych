function plot_LFP_rf(W,P,param,cfg)
% plot_LFP_rf(S,P,param,cfg)
% 
% For use with DB_QuickPlot
%
% DJS 2013
win  = [cfg.win_on cfg.win_off] / 1000; % ms -> s
svec = floor(win(1)*P.wave_fs):round(win(2)*P.wave_fs);


% Organize by stimulus onsets
onsamp = round(P.VALS.onset * P.wave_fs);

% Reorganize by stimulus type
for i = 1:length(param)
    stims{i} = P.lists.(param{i}); %#ok<AGROW>
end

% Won: {stim1 X stim2}(reps X samples)
Won = cell(length(stims{1}),length(stims{2}));
for i = 1:length(stims{1})
    for j = 1:length(stims{2})
        ind = P.VALS.(param{1}) == stims{1}(i) ...
            & P.VALS.(param{2}) == stims{2}(j);
        idx = find(ind);
        Won{i,j} = zeros(length(idx),length(svec));
        for k = 1:length(idx)
            Won{i,j}(k,:) = W(onsamp(idx(k))+svec);
        end
    end
end

mWon = cellfun(@mean,Won,'UniformOutput',false);
rmsWon = cellfun(@(x) sqrt(mean(x.^2)),mWon,'UniformOutput',true)';

% post processing based on user options
if isfield(cfg,'smooth2d') && cfg.smooth2d, rmsWon = sgsmooth2d(rmsWon); end
if isfield(cfg,'interpolate') && cfg.interpolate > 1
    rmsWon = interp2(rmsWon,cfg.interpolate);
    if cfg.xislog
        stims{1} = logspace(log10(stims{1}(1)),log10(stims{1}(end)),size(rmsWon,2));
    else
        stims{1} = linspace(stims{1}(1),stims{1}(end),size(rmsWon,2));
    end
    stims{2} = linspace(stims{2}(1),stims{2}(end),size(rmsWon,1));
end

set(gcf,'renderer','zbuffer'); % OpenGL doesn't seem to like log axes

surf(stims{1},stims{2},rmsWon);
view(2)
if isfield(cfg,'interpolate') && cfg.interpolate > 1 || isfield(cfg,'smooth2d') && cfg.smooth2d
    shading interp
else
    shading flat
end
if cfg.xislog, set(gca,'xscale','log'); end
axis tight

xlabel(param{1});
ylabel(param{2});

ax_data.mWon = mWon;
ax_data.rmsWon = rmsWon;
ax_data.x_axis = stims{1};
ax_data.y_axis = stims{2};
ax_data.P      = P;
ax_data.cfg    = cfg;
set(gca,'UserData',ax_data);






