function offlineSpikeDetect(tank,block,plxdir,sevName,nsamps,shadow,thrMult,delineF)
% offlineSpikeDetect(tank,block,plxdir,sevName,nsamps,shadow,thrMult,delineF)
%
% Offline spike detection from TDT Streamed data
%
% 1. Retrieve streamed data
% 2. Use acausal filter (filtfilt) on raw data to isolate spike signal.
% 3. Computes common average reference and subtracts from all channels
%       (Ludwig et al, 2009)
% 4. Set robust spike-detection threshold for 10 second chunks of data 
%     default = -4;  (eq. 3.1 of Quiroga, Nadasdy, and Ben-Shaul, 2004)
% 5. Detect and Align spikes by largest negative peak in the spike waveform.
% 6. Write spike waveforms and timestamps to plx file with the name
% following: TankName_BlockName.plx
%
% All inputs are optional.  A GUI will appear if no tank or block is
% explicitly specified.
% tank      ... Tank name. Full path if not registered. (string)
% block     ... Block name (string)
% plxdir    ... Plexon output directory (string)
% sevname   ... Specify SEV name (string). If not specified and only one
%               SEV name is found for the block, then the found name will
%               be used.  If multiple SEV names are found, then a list
%               dialog will confirm selection of one SEV name to process.
% nsamps    ... Number of samples to extract from raw waveform (integer)
% shadow    ... Number of samples to ignore following a threshold crossing
%               (integer)
% thrMult   ... Threshold multiplier: thrMult*median(abs(x)/0.6745)
%
% Note.  If you have the Parallel Processing Toolbox, you can start a
% matlab pool before calling this function to significantly speed up the
% filtering step.  Just note that this will take very larger amounts of RAM
% if you have a big dataset.
%
% DJS 4/2016

plotdata = false;

if nargin == 0 || isempty(tank) 
    % launch tank/block selection interface
    TDT = TDT_TTankInterface;
    tank  = TDT.tank;
    block = TDT.block;
elseif nargin >= 1 && ~isempty(tank) && isempty(block)
    TDT.tank = tank;
    TDT = TDT_TTankInterface(TDT);
    tank  = TDT.tank;
    block = TDT.block;
end


if nargin < 3 || isempty(plxdir), plxdir = uigetdir; end
if nargin < 4, sevName = []; end
if nargin < 5 || isempty(nsamps), nsamps = 40; end
if nargin < 6 || isempty(shadow), shadow = round(nsamps); end
if nargin < 7 || isempty(thrMult), thrMult = -4; end

if ~isdir(plxdir), mkdir(plxdir); end


blockDir = fullfile(tank,block);





% find available sev names in the selected block
if isempty(sevName)
    sevName = SEV2mat(blockDir ,'JUSTNAMES',true,'VERBOSE',false);
    fprintf('Found %d sev events in %s\n',length(sevName),blockDir )
end

if isempty(sevName)
    fprintf(2,'No sev events found in %s\n',blockDir ) %#ok<PRTCAL>
    return
    
elseif length(sevName) > 1
    [s,v] = listdlg('PromptString','Select a name', ...
        'SelectionMode','single','ListString',sevName);
    if ~v, return; end
    sevName((1:length(sevName))~=s) = [];
    
end
sevName = char(sevName);
fprintf('Using sev event name: ''%s''\n',sevName)

% retrieve data
fprintf('Retrieving data ...')
sevData = SEV2mat(blockDir ,'EVENTNAME',sevName,'VERBOSE',false);
fprintf(' done\n')

sevFs   = sevData.(sevName).fs;
sevData = sevData.(sevName).data';

nC = size(sevData,2);



% % Remove any DC offset
% sevData = bsxfun(@minus,sevData,mean(sevData));
% 
% 
% 
% 
% % Deline to make sure AC noise is rejected
% % NOTE: The deline function kind of fails for the first few seconds, but
% % hopefully there was some dead time included in the beginning of the block
% % so this can be ignored.
% if nargin < 6 || isempty(delineF), delineF = [60 180]; end
% if any(delineF)
%     fprintf('Delining: \n%s\n\n',repmat('.',1,nC))
%     parfor i = 1:nC
%         sevData(:,i) = chunkwiseDeline(sevData(:,i),sevFs,delineF,2,120,false);
%         fprintf('\b|\n')
%     end
% end




% Design filters
Fstop1 = 150;         % First Stopband Frequency
Fpass1 = 300;         % First Passband Frequency
Fpass2 = 6000;        % Second Passband Frequency
Fstop2 = 12000;       % Second Stopband Frequency
Astop1 = 6;          % First Stopband Attenuation (dB)
Apass  = 1;           % Passband Ripple (dB)
Astop2 = 12;          % Second Stopband Attenuation (dB)
match  = 'passband';  % Band to match exactly

% Construct an FDESIGN object and call its BUTTER method.
h  = fdesign.bandpass(Fstop1, Fpass1, Fpass2, Fstop2, Astop1, Apass, ...
                      Astop2, sevFs);
Hd = design(h, 'butter', 'MatchExactly', match);
sos = Hd.sosMatrix;
g   = Hd.ScaleValues;
nZs = ceil(10*sevFs);
Zs = zeros(nZs,1);
fprintf('Filtering: \n%s\n\n',repmat('.',1,nC))
parfor i = 1:nC
    sig = [Zs; double(sevData(:,i)); Zs];
    sig = single(filtfilt(sos, g, sig)); 
    sevData(:,i) = sig(nZs+1:end-nZs);
    fprintf('\b|\n')
end





% common average reference (Ludwig et al, 2009)
fprintf('Computing Common Average Reference\n')
elRMS  = rms(sevData(randsample(size(sevData,1),round(0.1*size(sevData,1))),:));
avgRMS = mean(rms(sevData(randsample(numel(sevData),round(0.1*numel(sevData))))));
m = elRMS/avgRMS;
badChannels = m < 0.3 | m > 2;
goodChannels = ~badChannels;
fprintf('Including %d of %d channels in CAR\n',sum(goodChannels),length(badChannels))
if plotdata
    f = findFigure('offlineSpikeDetect','color','w');
    figure(f); clf(f);

    hold on
    stem(find(badChannels),m(badChannels),'-xr','markersize',10)
    stem(find(goodChannels),m(goodChannels),'-og','markersize',5,'markerfacecolor','g');
    plot(xlim'*[1 1],[0.3 2; 0.3 2],'--r')
    ylim(ylim+[0 0.5]);
    xlim([0 length(m)+1]);
    set(gca,'xtick',1:length(m))
    grid on
    box on
    xlabel(gca,'Channels');
    ylabel(gca,'Noise Floor RMS')
    title(gca,'Good Channels are Green')
    hold off
end

car = mean(sevData(:,goodChannels),2);
sevData = bsxfun(@minus,sevData,car);





% Threshold for spikes
% threshold estimate from eq. 3.1 in Quiroga, Nadasdy, and Ben-Shaul, 2004
fprintf('Computing thresholds ...')
chunksize = round(10*sevFs); % temporally localized chunks for computing thresholds
chunkvec = 1:chunksize:size(sevData,1);
if size(sevData,1)~=chunkvec(end), chunkvec(end+1) = size(sevData,1); end
thr = zeros(length(chunkvec)-1,nC);
k = 1;
for i = 1:length(chunkvec)-1
    thr(k,:) = median(abs(sevData(chunkvec(i):chunkvec(i+1)-1,:))/0.6745);
    k = k + 1;
end
thr = thrMult*thr;
fprintf(' done\n')

if plotdata
    f = findFigure('ThrFig','color','w');
    figure(f); clf(f)
    sevTime = 0:1/sevFs:size(sevData,1)/sevFs - 1/sevFs; % time vector
    idx = round(sevFs*40):round(sevFs*60);
    nrow = ceil(sqrt(nC));
    ncol = ceil(nC/nrow);
    for i = 1:nC
        subplot(nrow,ncol,i)
        plot(sevTime(idx),sevData(idx,i));
        hold on
        for j = 1:size(thr,1)
            if chunkvec(j)<idx(1), continue; end
            if chunkvec(j+1)>idx(end), break; end
            plot(chunkvec([j j+1])/sevFs,[1 1]*thr(j,i),'-');
        end
        hold off
        ylim([-1 1]*max(abs([sevData(idx,i);thr(:,i)])))
        title(i)
    end
end






% Find spikes crossing threshold
nBefore = round(nsamps/2.5);
nAfter  = nsamps - nBefore;
look4pk = ceil(nsamps*0.7); % look ahead 7/10's nsamps for peak
spikeWaves = cell(1,nC);
spikeTimes = spikeWaves;
warning('off','signal:findpeaks:largeMinPeakHeight');
for i = 1:nC
    fprintf('Finding spikes on channel % 3d, ',i)
    [spikeWaves{i},spikeTimes{i}] = detectSpikes(sevData(:,i),sevFs,thr(:,i),chunkvec,shadow,nBefore,nAfter);
    fprintf('detected % 8d spikes\n',size(spikeWaves{i},1))
end
warning('on','signal:findpeaks:largeMinPeakHeight');






% Write out to PLX file
if ~isdir(plxdir), mkdir(plxdir); end

[~,tank] = fileparts(tank);
plxfilename = [tank '_' block '.plx'];
fprintf('Creating PLX file: %s (%s)\n',plxfilename,plxdir)
plxfilename = fullfile(plxdir,plxfilename);
ind = cellfun(@isempty,spikeTimes);
spikeWaves(ind) = [];
spikeTimes(ind) = [];
Channels = find(~ind);
maxts = max(cell2mat(spikeTimes'));
fid = writeplxfilehdr(plxfilename,sevFs,length(spikeWaves),nsamps,maxts);
for ch = Channels
    writeplxchannelhdr(fid,ch,nsamps)
end
for i = 1:length(spikeWaves)
    fprintf('Writing channel% 3d\t# spikes:% 7d\n',i,length(spikeTimes{i}))
    writeplxdata(fid,i,sevFs,spikeTimes{i},zeros(size(spikeTimes{i})),nsamps,spikeWaves{i}*1e6)
end

fclose(fid);

fprintf('Finished processing block ''%s'' of tank ''%s''\n\n\n',block,tank)



function [spikes,times] = detectSpikes(data,sevFs,thr,chunkvec,shadow,nBefore,nAfter)
% uses the findpeaks function from Matlab's Signal Processing Toolbox
data = double(-data); % flip sign to detect negative peaks
thr  = -thr;  % "
p = cell(size(thr));
for i = 1:length(thr)
    [~,p{i}] = findpeaks(data(chunkvec(i):chunkvec(i+1)-1), ...
        'MinPeakHeight',thr(i),'MinPeakDistance',shadow);
    p{i} = p{i}+chunkvec(i)-1;
end

negPk = cell2mat(p);

% cut nsamps around negative peak index
indA = negPk - nBefore;
indB = negPk + nAfter - 1;
dind = indA < 1 | indB > size(data,1);
indA(dind) = []; indB(dind) = []; negPk(dind) = [];
s = arrayfun(@(a,b) (-data(a:b)),indA,indB,'uniformoutput',false);
spikes = cell2mat(s')';
times = negPk / sevFs;




