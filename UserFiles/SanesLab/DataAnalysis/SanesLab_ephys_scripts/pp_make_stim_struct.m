
function Stim = pp_make_stim_struct( epData, block )
%
%  pp_make_stim_struct( epData, block )
%    Sub-routine called by pp_prepare_format.
%    
%    Creates matlab struct with number of elements equal to number of
%    trials, and fields with stimulus information for each trial. 
%    
%    This function should be modified for each experimenter/experiment, to
%    include the relevant parameters and source of trial onset timestamps.
%    
%  KP, 2016-04; last updated 2016-04
% 

 

% STIMULUS ONSET TIMES

if isfield(epData.epocs,'Freq')     %passive recording
    Freq = epData.epocs.Freq.data;
    onsets = round( 1000*epData.epocs.Freq.onset );  %ms
    duration = round( 1000* (epData.epocs.Freq.offset - epData.epocs.Freq.onset) );
    
    behaving = 0;
    
elseif isfield(epData.epocs,'Soun')  %behavior recording
    Freq = epData.epocs.Soun.data;
    onsets = round( 1000*epData.epocs.Soun.onset );  %ms
    duration = round( 1000* (epData.epocs.Soun.offset - epData.epocs.Soun.onset) );
    
    behaving = 1;
    
else
    keyboard
end




% STIM PARAMS

timestamps = round( 1000*epData.scalars.Pars.ts );

if size(onsets',2)~=size(timestamps,2)  
    % if triggers in rpvds circuits for storing stim info are always
    % consistent, this should never be an issue
    sound_trs=[];
    for it = 1:numel(onsets)
        [~,match] = min(abs(onsets(it)-timestamps));
        sound_trs = [sound_trs match];
    end
    
    stim_params = epData.scalars.Pars.data;
    stim_params = stim_params(:, sound_trs);
    
else
    stim_params = epData.scalars.Pars.data;
    
end


% Parse the Pars matrix, identifying stimulus parameters based on the
% protocol that was used. 
switch size(stim_params,1)
    
    case 8    %FreqTuning_FM_harmonics_lite.rcx
        protocol = 'FM_harmonics';
        Harms     = bi2de(stim_params(1:5,:)');
        dB_level  = stim_params(6,:)';
        FMdepth   = stim_params(7,:)';
        stimDur   = stim_params(8,:)';
        
    case 7    %Appetitive_FMsweep_detection_ephys.rcx
        protocol = 'BEHAVIOR';
        Harms     = bi2de(stim_params(1:4,:)');
        dB_level  = stim_params(5,:)';
        FMdepth   = stim_params(6,:)';
        stimDur   = stim_params(7,:)'./epData.streams.Wave.fs *1000;
        
    case 3    %FreqTuning_FM.rcx
        protocol = 'FM_tuning';
        FMdepth  = stim_params(1,:)';
        stimDur  = stim_params(2,:)';
        dB_level = stim_params(3,:)';
        Harms    = ones(size(stim_params,2),1);

    case 2   %FreqTuning.rcx
        protocol = 'Freq_tuning';
        dB_level = stim_params(1,:)';
        stimDur  = stim_params(2,:)';
        FMdepth  = zeros(size(stim_params,2),1);
        Harms    = ones(size(stim_params,2),1);
        
end

%%%  ------------------------------------------
%%%  |  Binary code for harmonics
%%%  |    
%%%  |      14 :      0   1   1   1   0
%%%  |       1 :      1   0   0   0   0
%%%  |       3 :      1   1   0   0   0
%%%  |       7 :      1   1   1   0   0
%%%  |      15 :      1   1   1   1   0
%%%  | 
%%%  ------------------------------------------





% CREATE STIM STRUCT

Stim = struct();
for it = 1:numel(onsets)
    
    Stim(it).onset       =    onsets(it);
    Stim(it).behaving    =    behaving;
    Stim(it).block       =    block;      
    
    Stim(it).Freq        =    Freq(it);
    Stim(it).dB          =    dB_level(it);
    Stim(it).stimDur     =    stimDur(it);
    Stim(it).FMdepth     =    FMdepth(it);
    Stim(it).Harms       =    Harms(it);
    
    % incorporate behavioral responses here too?
    
end

end
