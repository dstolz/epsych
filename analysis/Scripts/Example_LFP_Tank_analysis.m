%% Enter Tank Info

tank = 'DILL_MGB_1'; % Specify tank name
block = 'Block-2'; % Specify block name

win = [0 0.2]; % Specify peri-stimulus window for field potentials

% optional: electrode remapping (leave empty for no remapping)
emap = [];
% emap = [17 31 19 29 21 27 23 25 18 32 20 30 22 28 24 26 1 15 3 13 5 11 7 9 2 16 4 14 6 12 8 10];

DataName = 'Wave'; % LFP data name (ex: Wave)
ParName  = 'Levl'; % Name of stimulus parameter (ex: Levl)


%% Retrieve Data and Analyze
% Retrieve stimulus parameters and stream (LFP) data from tank
data = TDT2mat(tank,block,'type',[2 4],'silent',true);


% Simply some variable names
W = data.streams.(DataName);
P = data.epocs.(ParName);
clear data

% rearrange channels according to emap
if ~exist('emap','var') || isempty(emap)
    emap = unique(W.chan);
end
W.data = W.data(:,emap);

Fs = W.fs; % sampling rate

% create time vector
tvec = linspace(0,(size(W.data,1)-1)/Fs,size(W.data,1));

% make sample window for indexing
sampwin = 0:round(W.fs*diff(win))-1;

% preallocate space for LFP matrix
LFP = zeros(length(sampwin),length(W.chan),length(P.onset));

% Cut-up continuously sampled data into epochs relative to stimulus onsets
for i = 1:length(P.onset)
    idx = find(tvec >= P.onset(i),1)+sampwin;
    LFP(:,:,i) = W.data(idx,:);
end
clear W tvec % we're done with these

% Rearrange LFP data by stimulus parameter
P.udata = unique(P.data);
sLFP = cell(size(P.udata));
for i = 1:length(P.udata)
    ind = P.data == P.udata(i);
    
    % Use cell array because it is possible to have an unequal number of
    % presentations for different stimuli and a normal matrix would not be
    % square.
    sLFP{i} = LFP(:,:,ind);
end
clear LFP


%% Plot

% launch figure if it doesn't already exist
f = findobj('type','figure','-and','name','LFP');
if isempty(f), f = figure('name','LFP','color','w'); end
figure(f);
clf

% Plot data as a heat map with time on the x axis and stimulus level on the
% y axis

% this is a fancy way of applying the 'mean' function to all elements of
% sLFP at once
mLFP = cellfun(@mean,sLFP,repmat({3},size(sLFP)),'UniformOutput',false);
clear sLFP

x = sampwin/Fs;
y = 1:size(mLFP{1},2);

nrows = ceil(sqrt(length(P.udata)));
ncols = ceil(length(P.udata)/nrows);
for i = 1:length(mLFP)
    subplot(nrows,ncols,i)
    surf(x,y,mLFP{i}');
    view(2);
    shading interp
    axis tight
    title(P.udata(i));
    
    xlabel('time (ms)');
    ylabel('channel');
end


% scale all heat maps to extreme values
ax = get(f,'children');
c = cell2mat(get(ax,'clim'));
set(ax,'clim',[min(c(:)) max(c(:))]);















