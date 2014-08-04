%% Open DB_Browser GUI to retrieve selected database ids

DB_Browser;



%% Returns structure with database IDs currently selected in DB_Browser GUI
ids = getpref('DB_BROWSER_SELECTION');




%% Retrieve raw spike times from onset of recording block

spiketimes = DB_GetSpiketimes(ids.units);




%% Retrieve protocol data including stimulus parameters and stimulus onset times

params = DB_GetParams(ids.blocks);



%% Reshape spiketime data based on freq and levl parameters

[data,vals] = shapedata_spikes(spiketimes,params,{'Freq','Levl'}, ... % required inputs
    'win',[0 0.05],'binsize',0.001); % optional inputs

% data: trials x Freq x Levl
% Each cell in vals corresponds to dimension in data




%% Make some plots based on processed data

figure;

mean_FRF   = squeeze(mean(data));
smooth_FRF = sgsmooth2d(mean_data);

subplot(211)
imagesc(vals{2},vals{3},mean_FRF');
set(gca,'ydir','normal');
colorbar
xlabel('Frequency (Hz)');
ylabel('Sound Level (dB SPL)');
title(sprintf('Mean FRF: unit %d',ids.units))

subplot(212)
imagesc(vals{2},vals{3},interp2(smooth_FRF',3));
set(gca,'ydir','normal');
colorbar
xlabel('Frequency (Hz)');
ylabel('Sound Level (dB SPL)');
title(sprintf('Filtered FRF: unit %d',ids.units))



