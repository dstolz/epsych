%% RIF analysis


plotwin = [-0.25 0.4];
analysiswin = [0.0051 0.2551];
baselinewin = [-0.25 0];
binsize = 1; % ms

gwdur = 10; % ms




DB = 'ds_a1_aaf_mod_mgb';

% use parallel processing
if matlabpool('size') == 0
    if strcmp(computer,'GLNXA64')
        matlabpool local 12; % KingKong server
    else
        matlabpool local 6; % PC
    end
end




% Make connection to database.
if ~exist('conn','var') || ~isa(conn,'database') || ~strcmp(conn.Instance,DB)
    conn = database(DB, 'DSuser', 'B1PdI0KY8y', 'Vendor', 'MYSQL', ...
        'Server', '129.100.241.107');
end

setdbprefs('DataReturnFormat','numeric');
UNITS = myms([ ...
    'SELECT v.unit FROM v_ids v ', ...
    'JOIN blocks b ON v.block = b.id ', ...
    'JOIN units u ON v.unit = u.id ', ...
    'JOIN db_util.protocol_types p ON b.protocol = p.pid ', ...
    'WHERE b.in_use = TRUE AND u.in_use = TRUE ', ...
    'AND p.alias = "RIF"'],conn);






unit_id = 6760; % Excited unit
% unit_id = 6765; % Excited onset unit
% unit_id = 6766; % Inhibited unit


% for u = 1:length(UNITS)
%     unit_id = UNITS(u);
% fprintf('Processing unit_id = %d (%d of %d)\n',unit_id,u,length(UNITS))








% Retrieve spiketimes and protocal parameters from the database
st = DB_GetSpiketimes(unit_id,[],conn);
P  = DB_GetParams(unit_id,'unit',conn);





%%
% Spike counts -----------------------------------------------


% compute prestimulus, baseline firing rate
D = shapedata_spikes(st,P,{'NBdB'},'win',baselinewin, ...
    'binsize',binsize/1000,'func','sum');
DATA.baseline_count = sum(D);


% response sipke count
D = shapedata_spikes(st,P,{'NBdB'},'win',analysiswin, ...
    'binsize',binsize/1000,'func','sum');
DATA.response_count = sum(D);















% Response type ---------------------------------------------
DATA.inhibited_response = sum(DATA.response_count) < sum(DATA.baseline_count);






















% Response characteristics -----------------------------------
% Reshape and bin data based on stimulus parameters
[D,vals] = shapedata_spikes(st,P,{'NBdB'},'win',plotwin, ...
    'binsize',binsize/1000,'returntrials',false);

[Dm,Dn] = size(D);




% Smooth PSTH
gw = gausswin(round(gwdur/binsize));
PSTH = zeros(size(D));
for i = 1:Dn
     PSTH(:,i) = conv(D(:,i),gw,'same');
end
PSTH = PSTH/max(PSTH(:)) * max(D(:)); % rescale PSTH

PSTH = PSTH * binsize * 1000; % mean spike count -> firing rate



% Plot response
f = findFigure('PSTH','name',sprintf('UnitID %d',unit_id),'color','w');
figure(f);
clf
subplot(1,5,[1 4]);
imagesc(vals{1},vals{2},PSTH');
colorbar('West')
set(gca,'ydir','normal');
colormap(flipud(gray(64)))



% compute prestimulus, baseline firing rate after smoothing
ind = vals{1} >= baselinewin(1) & vals{1} < baselinewin(2);
sPSTH = PSTH(ind,:);
baseline_fr = mean(sPSTH(:));
baseline_fr_std = std(sPSTH(:));

% response for analysis after smoothing
ind = vals{1} >= analysiswin(1) & vals{1} < analysiswin(2);
abvec = vals{1}(ind);
aPSTH = PSTH(ind,:);



% peak response
[DATA.peak_firing_rate,idx] = max(aPSTH);
DATA.peak_latency = abvec(idx);



% only trials where the response peak was greater than the spontaneous
% firing rate are valid
DATA.valid_response = DATA.peak_firing_rate > max(sPSTH);



% thr = baseline_fr+3*baseline_fr_std;
DATA.response_threshold = norminv(0.975,baseline_fr,baseline_fr_std);

% Find response onsets and offsets
onset_idx  = nan(1,Dn);
offset_idx = nan(1,Dn);
for i = 1:Dn
    if DATA.inhibited_response
        fon  = find(aPSTH(:,i)<DATA.response_threshold,1,'first');
        foff = find(aPSTH(:,i)<DATA.response_threshold,1,'last');
    else
        fon  = find(aPSTH(:,i)>DATA.response_threshold,1,'first');
        foff = find(aPSTH(:,i)>DATA.response_threshold,1,'last');
    end
    if isempty(fon), continue; end
    onset_idx(i)  = fon;
    offset_idx(i) = foff;
end

DATA.response_onset  = abvec(onset_idx);
DATA.response_offset = abvec(offset_idx);









% Plot onsets and offsets
hold on
y = vals{2}(DATA.valid_response);
plot(DATA.response_onset(DATA.valid_response), y,'>r', ...
    DATA.response_offset(DATA.valid_response), y,'<r', ...
    DATA.peak_latency(DATA.valid_response),    y,'*r');





% Plot stats
subplot(1,5,5)
[ax,h1,h2] = plotyy(vals{2},DATA.peak_firing_rate, ...
    vals{2},DATA.response_count);
set(ax,'xlim',vals{2}([1 end]))
set(h1,'marker','*','color','r');
set(h2,'marker','x')




















% end
