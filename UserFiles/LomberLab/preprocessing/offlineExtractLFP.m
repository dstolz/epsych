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

nCh = size(sevData,2);

% Remove DC offset
sevData = bsxfun(@minus,sevData,mean(sevData));




% Deline to make sure AC noise is rejected
% NOTE: The deline function kind of fails for the first few seconds, but
% hopefully there was some dead time included in the beginning of the block
% so this can be ignored.
if nargin < 6 || isempty(delineF), delineF = [60 180]; end
if any(delineF)
    fprintf('Delining: \n%s\n\n',repmat('.',1,nCh))
    parfor i = 1:nCh
        sevData(:,i) = chunkwiseDeline(sevData(:,i),sevFs,delineF,2,240,false);
        fprintf('\b|\n')
    end
end







% optionally despike based on plexon file data
if remSpikes
    % if length(T) ~= size(SDATA,2)
    %     % maybe check for this earlier so we don't have rerun everything
    %     % again
    %     error('offlineExtractLFP:Number of Channels in Plexon file does not equal the number of streamed LFP channels.')
    % end

    [~,T,W] = PLX2MAT(plx);

    fprintf('Despiking: \n%s\n\n',repmat('.',1,length(T)))
    parfor i = 1:nCh

        % my experience is that the we need 100 samples to truly get rid of
        % larger spike waveforms which is ~4.1 ms at ~25 kHz sampling rate
        % which equals ~244 Hz which is above the frequencies we're
        % typically interested when analyzing LFPs, so this larger spike
        % extraction *should* be ok. DJS 5/2016
        sevData(:,i) = despike(sevData(:,i),sevFs,T{i},100);
%         SDATA(:,i) = despike(SDATA(:,i),sevFs,T{i},size(W{i},2));
        fprintf('\b|\n')
    end
    
end





% Filter
if nargin < 6 || isempty(Hd)
    % Design default filter
    Fstop1 = 0.5;         % First Stopband Frequency
    Fpass1 = 1;           % First Passband Frequency
    Fpass2 = 200;         % Second Passband Frequency
    Fstop2 = 400;         % Second Stopband Frequency
    Astop1 = 6;           % First Stopband Attenuation (dB)
    Apass  = 1;           % Passband Ripple (dB)
    Astop2 = 20;          % Second Stopband Attenuation (dB)
    match  = 'passband';  % Band to match exactly
    
    % Construct an FDESIGN object and call its BUTTER method.
    h  = fdesign.bandpass(Fstop1, Fpass1, Fpass2, Fstop2, Astop1, Apass, ...
        Astop2, sevFs);
    Hd = design(h, 'butter', 'MatchExactly', match);
end

sevData = filterData(sevData,sevFs,Hd);












% downsample.  Since we've already filtered well below the Nyquist rate, we
% shouldn't need to do additional antialias filtering (?)
rFs   = floor(sevFs/lfpFs);
Ridx  = 1:rFs:size(sevData,1);
lfp   = sevData(Ridx,:);
lfpFs = sevFs*length(Ridx)/size(sevData,1);



















function data = filterData(data,sevFs,Hd)

% filter raw sev data
% ramp up/down the beginning/end of the signals
t = 0:1/sevFs:1-1/sevFs;
w = cos(2*pi*0.5*t+pi/2)'.^2;
nw = length(w);
if rem(nw,2), w = [w(1:floor(nw/2)); w(floor(nw/2)); w(ceil(nw/2):end)]; nw = nw + 1; end
w = repmat(w,1,size(data,2));
data(1:nw/2,:) = data(1:nw/2,:).*w(1:nw/2,:);
data(end-nw/2+1:end,:) = data(end-nw/2+1:end,:).*w(nw/2+1:end,:);


sos = Hd.sosMatrix;
g   = Hd.ScaleValues;
fprintf('Filtering: \n%s\n\n',repmat('.',1,size(data,2)))
parfor i = 1:size(data,2)
    data(:,i) = single(filtfilt(sos, g, double(data(:,i)))); 
    fprintf('\b|\n')
end




















function SDATA = despike(SDATA,sevFs,T,s)
%     % get rid of noise unit (0)
%     i0 = cellfun(@(a) (a~=0),U,'UniformOutput',false);
%     T  = cellfun(@(a,b) (a(b)),T,i0,'UniformOutput',false);


sevT = 0:1/sevFs:(length(SDATA)-1)/sevFs;


rSamps = round([-0.425 0.575]*s);
rSamps = rSamps(1):rSamps(2);

% find nearest samples of spike timestamp in LFP signal
ridx = nearest(sevT,T);

% Interpolate LFP signal discarding samples with spikes
%  Not sure why, but interp1 seems to screw up when interpolating for
%  missing data when using very large arrays. Anyway, break it up into
%  bite-sized chunks to avoid issues. DJS 5/2016
idxT = 1:length(SDATA);
ridx = bsxfun(@plus,ridx,rSamps)';
ridx(:,any(ridx>length(SDATA)|ridx<1)) = [];
chksze = 100000;
rs = size(ridx,2);
for i = 1:chksze:rs
    k = i:i+chksze-1;
    k(k>rs) = [];
    r = ridx(:,k);
    r = r(:);
    ind = ~ismember(idxT,r);
    SDATA(r) = interp1(idxT(ind),SDATA(ind),r,'pchip');
end







