function [lfp,lfpFs] = offlineExtractLFP(tank,block,sevName,lfpFs,Hd,delineF,plx)
% [lfp,lfpFs] = offlineExtractLFP(tank,block,sevName,lfpFs,Hd,delineF,plx)
%
% Filter for local field potential signal from raw streamed data and
% downsample.  Uses acausal filter (filtfilt) to avoid phase distortions.
%
% If the Parallel Processing Toolbox is available and a parallel pool has
% been initated, then this function will use the parfor loop to speed up
% filtering.  Note that this will use huge amounts of memory for very long
% duration signals.
%
% All inputs are optional.  A GUI will appear if no tank or block is
% explicitly specified.
% tank      ... Tank name. Full path if not registered. (string)
% block     ... Block name (string)
% sevname   ... Specify SEV name (string). If not specified and only one
%               SEV name is found for the block, then the found name will
%               be used.  If multiple SEV names are found, then a list
%               dialog will confirm selection of one SEV name to process.
% lfpFs     ... New LFP sampling frequency (double; default = 1000)
% Hd        ... Filter design object for specifying custom filter. See code 
%               for filter's default parameters (1 Hz - 200 Hz)
%                   For more info, run: >> fdatool
% delineF   ... Remove line noise by fitting a function to the signal power
%               around 60 Hz and invert it to obtain a filter. Better than
%               using a 60 Hz notch filter.  Note that this may leave line
%               noise for the first second or two of the recording. This
%               does not seem to be due to onset transient (tried ramping
%               and padding) and need to eventuall figure a way around
%               this.  Default = [60 180]. Set = 0 to disable.
% plx       ... PLX file with sorted spikes. Deletes samples with spikes
%               detected that corrupt the LFP and then interpolates missing
%               values for a continuous LFP signal.
%
% Daniel.Stolzberg@gmail.com 5/2016


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

if nargin < 3, sevName = []; end
if nargin < 4 || isempty(lfpFs),  lfpFs = 1000; end
remSpikes = nargin == 7 & exist(plx,'file');


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


if nargin < 6 || isempty(Hd)
    % Design filters
    Fstop1 = 0.5;         % First Stopband Frequency
    Fpass1 = 1;           % First Passband Frequency
    Fpass2 = 200;         % Second Passband Frequency
    Fstop2 = 400;         % Second Stopband Frequency
    Astop1 = 6;           % First Stopband Attenuation (dB)
    Apass  = 1;           % Passband Ripple (dB)
    Astop2 = 12;          % Second Stopband Attenuation (dB)
    match  = 'passband';  % Band to match exactly
    
    % Construct an FDESIGN object and call its BUTTER method.
    h  = fdesign.bandpass(Fstop1, Fpass1, Fpass2, Fstop2, Astop1, Apass, ...
        Astop2, sevFs);
    Hd = design(h, 'butter', 'MatchExactly', match);
end




% first make sure AC noise is rejected (deline uses parfor)
% NOTE: The deline function kind of fails for the first few seconds, but
% hopefully there was some dead time included in the beginning of the block
% so this can be ignored.
if isempty(delineF), delineF = [60 180]; end
if any(delineF)
    sevData = deline(sevData,sevFs,delineF);
end


% filter raw sev data
% ramp up/down the beginning/end of the signals
t = 0:1/sevFs:1-1/sevFs;
w = cos(2*pi*0.5*t+pi/2)'.^2;
nw = length(w);
if rem(nw,2), w = [w(1:floor(nw/2)); w(floor(nw/2)); w(ceil(nw/2):end)]; nw = nw + 1; end
w = repmat(w,1,size(sevData,2));
sevData(1:nw/2,:) = sevData(1:nw/2,:).*w(1:nw/2,:);
sevData(end-nw/2+1:end,:) = sevData(end-nw/2+1:end,:).*w(nw/2+1:end,:);

sos = Hd.sosMatrix;
g   = Hd.ScaleValues;
FsevData = sevData;
parfor i = 1:size(sevData,2)
    fprintf('Filtering channel %d\n',i)
    FsevData(:,i) = single(filtfilt(sos, g, double(sevData(:,i)))); 
end

clear sevData





% downsample.  Since we've already filtered well below the Nyquist rate, we
% shouldn't need to do additional antialiasing filtering (?)
rFs = floor(sevFs/lfpFs);
Ridx = 1:rFs:size(FsevData,1);
lfp = FsevData(Ridx,:);
lfpFs = sevFs*length(Ridx)/size(FsevData,1);






% optionally despike based on plexon file data
if remSpikes
    
    
    fprintf('Removing spikes using file: %s\n',plx)
    [U,T,W] = PLX2MAT(plx);
    
%     % get rid of noise unit (0)
%     i0 = cellfun(@(a) (a~=0),U,'UniformOutput',false);
%     T  = cellfun(@(a,b) (a(b)),T,i0,'UniformOutput',false);
    
    if length(T) ~= size(lfp,2)
        % maybe check for this earlier so we don't have rerun everything
        % again
        error('offlineExtractLFP:Number of Channels in Plexon file does not equal the number of streamed LFP channels.')
    end
    
    lfpT = 0:1/lfpFs:(size(lfp,1)-1)/lfpFs;
    
    s = size(W{1},2);    
    rSamps = round(([-0.425 0.575]*s/round(sevFs))*lfpFs); % round(sevFs) because Plexon only accepts integer sampling rates
    rSamps = rSamps(1):rSamps(2);
    
    % find nearest samples of spike timestamp in LFP signal
    
    Ts     = cellfun(@size,T,'UniformOutput',false);
    rSamps = cellfun(@repmat,repmat({rSamps},size(T)),Ts,'UniformOutput',false);
    ridx   = cellfun(@nearest,repmat({lfpT},size(T)),T,'UniformOutput',false);
    ridx   = cellfun(@bsxfun,repmat({@plus},size(T)),ridx,rSamps,'UniformOutput',false);
    ridx   = cellfun(@transpose,ridx,'UniformOutput',false);

    % Interpolate LFP signal discarding samples with spikes
    idxT = 1:size(lfp,1);
    for i = 1:length(ridx)
        fprintf('Despiking Channel %d\n',i)
        ind = ~ismember(idxT,ridx{i}(ridx{i}>0));
        lfp(:,i) = interp1(idxT(ind),lfp(ind,i),idxT,'pchip');
    end
end








