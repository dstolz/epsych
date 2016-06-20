function ph = pp_make_phys_struct( epData, t1, t2 )
%
%  pp_make_phys_struct( epData, t1, t2 )
%    Sub-routine called by pp_prepare_format.
%    
%    Creates matrix of filtered ephys data. First, filters the entire data
%    stream from epData. Then extracts a window of data around each trial
%    onset.
%    
%
%  KP, 2016-04; last updated 2016-04
% 


fs = epData.streams.Wave.fs;

if isfield(epData.epocs,'Freq')                 % passive recording
    onsets = fs*epData.epocs.Freq.onset; %samples
    
elseif isfield(epData.epocs,'Soun')             % active recording
    onsets = fs*epData.epocs.Soun.onset; %samples
    
end
%     duration = fs * (epData.epocs.Freq.offset - epData.epocs.Freq.onset); %samples


wave_raw = double(epData.streams.Wave.data);


% Filter data

Wp = [ 300  6000] * 2 / fs;        %cutoff fqs (passband)
Ws = [ 225  8000] * 2 / fs;        %cutoff fqs (stopband)
[N,Wn] = buttord( Wp, Ws, 3, 20);  %create filter parameters
[B,A] = butter(N,Wn);              %build filter
fprintf('   filtering data...')
for ch = 1:size(wave_raw,1)
    if ch==8;    continue;      end
    wave_filt(ch,:) = filtfilt( B, A, wave_raw(ch,:) );
end



%%% data struct must be either:
%%%    matrix format [trials x samples x channels]
%%%    or cell array {trials}[samples x channels]

ph = nan( numel(onsets), 1+t2-t1, size(wave_filt,1) );

for it = 1:numel(onsets)  %iterate through trials
    
    t0 = round(onsets(it));
    
    for ic = 1:size(wave_filt,1)  %iterate through channels

        try
            % Pull window of data around trial onset
            ph(it,:,ic) = wave_filt(ic,t0+t1:t0+t2);
            
        catch
            warning('inconsistent window sizes')
        end
        if any(isnan(ph(it,:,ic)))
            warning('inconsistent window sizes')
        end
        
                
    end
end
 


end
