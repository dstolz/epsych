%% Offline spike detection from TDT Streamed data
%
% 1. Uses acausal filter (filtfilt) on raw data to isolate spike signal.
% 2. Sets robust spike-detection threshold at -4*median(abs(x)/0.6745)
% which is defined in eq. 3.1 of Quiroga, Nadasdy, and Ben-Shaul, 2004.
% 3. Aligns spikes by largest negative peak in the spike waveform.
% 4. Writes spike waveforms and timestamps to plx file with the name
% following: TankName_BlockName.plx
%       Modify the PLXDIR variable below to direct where to put the plx
%       file output.
%
% DJS 4/2016

PLXDIR = 'D:\PLXDIR';
nsamps = 50;
shadow = round(nsamps/3);


% launch tank/block selection interface
TDT = TDT_TTankInterface;


TDT.blockDir = fullfile(TDT.tank,TDT.block);

% find available sev names in the selected block
sevName = SEV2mat(TDT.blockDir,'JUSTNAMES',true,'VERBOSE',false);
fprintf('Found %d sev events in %s\n',length(sevName),TDT.blockDir)
if isempty(sevName)
    fprintf(2,'No sev events found in %s\n',TDT.blockDir)
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
sevData = SEV2mat(TDT.blockDir,'EVENTNAME',sevName,'VERBOSE',false);
fprintf(' done\n')

sevFs   = sevData.(sevName).fs;
sevData = sevData.(sevName).data';

sevTime = 0:1/sevFs:size(sevData,1)/sevFs - 1/sevFs; % time vector

% Design filters
Fstop1 = 100;         % First Stopband Frequency
Fpass1 = 500;         % First Passband Frequency
Fpass2 = 7000;        % Second Passband Frequency
Fstop2 = 12000;       % Second Stopband Frequency
Astop1 = 20;          % First Stopband Attenuation (dB)
Apass  = 1;           % Passband Ripple (dB)
Astop2 = 20;          % Second Stopband Attenuation (dB)
match  = 'passband';  % Band to match exactly

% Construct an FDESIGN object and call its BUTTER method.
h  = fdesign.bandpass(Fstop1, Fpass1, Fpass2, Fstop2, Astop1, Apass, ...
                      Astop2, sevFs);
Hd = design(h, 'butter', 'MatchExactly', match);
sos = Hd.sosMatrix;
g   = Hd.ScaleValues;
parfor i = 1:size(sevData,2)
    fprintf('Filter channel %d\n',i)
    sevData(:,i) = single(filtfilt(sos, g, double(sevData(:,i)))); 
end


%% Threshold for spikes
% threshold estimate from eq. 3.1 in Quiroga, Nadasdy, and Ben-Shaul, 2004
fprintf('Computing thresholds ...')
thr = 4 * -median(abs(sevData)/0.6745);
fprintf(' done\n')

%% 
f = findFigure('ThrFig','color','w');
figure(f);
idx = 1:round(sevFs*10);
plot(sevTime(idx),sevData(idx));
hold on
plot(sevTime(idx([1 end])),[1 1]*thr(1),'-');


%% Find spikes crossing threshold

nBefore = round(nsamps/2.5);
nAfter  = nsamps - nBefore;
look4pk = ceil(nsamps*0.7); % look ahead 7/10's nsamps for peak
spikeWaves = cell(1,size(sevData,2));
spikeTimes = spikeWaves;
for i = 1:size(sevData,2)
    fprintf('Finding spikes on channel % 3d, ',i)
    % falling edge detection
    pidx = find(sevData(1:end-1,i) > thr(i) & sevData(2:end,i) <= thr(i));
    
    % search negative peak index
    negPk = zeros(size(pidx));
    for j = 1:length(pidx)
        s = find(sevData(pidx(j):pidx(j)+look4pk,i) < sevData(pidx(j)+1:pidx(j)+look4pk+1,i) ...
               & sevData(pidx(j)+1:pidx(j)+look4pk+1,i) < sevData(pidx(j)+2:pidx(j)+look4pk+2,i),1);
        if isempty(s)
            negPk(j) = 1;
        else
            negPk(j) = s;
        end
    end
    negPk = negPk + pidx - 1;
    
    % throw away timestamps less than the shadow period
    dnegPk = diff(negPk);
    negPk(dnegPk<shadow) = [];
    
    % cut nsamps around negative peak index
    indA = negPk - nBefore;
    indB = negPk + nAfter - 1;
    s = arrayfun(@(a,b) (sevData(a:b,i)),indA,indB,'uniformoutput',false);
    spikeWaves{i} = cell2mat(s')';
    spikeTimes{i} = negPk / sevFs;
    
    fprintf('detected % 8d spikes\n',size(spikeWaves{i},1))
    
end

%% Write out to PLX file


if ~isdir(PLXDIR), mkdir(PLXDIR); end

[~,tank] = fileparts(TDT.tank);
plxfilename = [tank '_' TDT.block '.plx'];
plxfilename = fullfile(PLXDIR,plxfilename);
maxts = max(cell2mat(spikeTimes'));
fid = writeplxfilehdr(plxfilename,sevFs,length(spikeWaves),nsamps,maxts);
for ch = 1:length(spikeWaves)
    writeplxchannelhdr(fid,ch,nsamps)
end
for i = 1:length(spikeWaves)
    fprintf('Writing channel% 3d\t# spikes:% 7d\n',i,length(spikeTimes{i}))
    writeplxdata(fid,i,sevFs,spikeTimes{i},zeros(size(spikeTimes{i})),nsamps,spikeWaves{i}*1e6)
end

fclose(fid);









