
function Stim = pp_make_stim_struct( epData, block, behavior )
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
%  KP, 2016-04; last updated 2016-05-02 JDY
% 

 
% STIMULUS ONSET TIMES
%%%%%%%%
if( behavior )
	if( isfield(epData.epocs,'Rate') )
		Rate = epData.epocs.Rate.data;
		onsets = round( 1000*epData.epocs.Rate.onset );	%ms
		duration = round( 1000* (epData.epocs.Rate.offset - epData.epocs.Rate.onset) );
	else
		onsets = round( 1000*epData.epocs.Soun.onset );	%ms
		duration = round( 1000* (epData.epocs.Soun.offset - epData.epocs.Soun.onset) );
	end
    behaving = 1;
%     keyboard
% elseif( isempty(epData.epocs) )
% 	keyboard
else
	if( isfield(epData.epocs,'Freq') )
		Freq = epData.epocs.Freq.data;
		onsets = round( 1000*epData.epocs.Freq.onset );	%ms
		duration = round( 1000* (epData.epocs.Freq.offset - epData.epocs.Freq.onset) );
	elseif( isfield(epData.epocs,'Rate') )
		Rate = epData.epocs.Rate.data;
		onsets = round( 1000*epData.epocs.Rate.onset );	%ms
		duration = round( 1000* (epData.epocs.Rate.offset - epData.epocs.Rate.onset) );
	elseif( isempty(epData.epocs) )
		onsets	=	epData.scalars.Pars.ts;
	end
	behaving = 0;
end
%%%%%%%%

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
	if( ~isempty(epData.epocs) )
		stim_params = stim_params(:, sound_trs);
	end
else
    stim_params = epData.scalars.Pars.data;
end

% Parse the Pars matrix, identifying stimulus parameters based on the
% protocol that was used.
%%%%%%%%---CUSTOM FOR JUSTIN---%%%%%%%%
if( behavior )
	protocol		=	'BEHAVIOR';
	dB_level		=	stim_params(1,:)';
	stimDur			=	duration;
	AMdepth			=	stim_params(2,:)';
    
elseif( isfield(epData.epocs,'Rate') )
	protocol		=	'AMRate';
	dB_level		=	stim_params(1,:)';
	stimDur			=	stim_params(2,:)';
	AMdepth			=	stim_params(3,:)';
	CFreq			=	stim_params(4,:)';
elseif( isempty(epData.epocs) )
	protocol	=	'AMForwardMasking';
	dB_level	=	stim_params(1,:)';
	stimDur		=	stim_params(2,:)';
	AMdepth		=	stim_params(3,:)';
	MaskerRate	=	stim_params(4,:)';
	SignalRate	=	stim_params(5,:)';
	SignalDur	=	stim_params(6,:)';
	MaskerDur	=	stim_params(7,:)';
	DelayDur	=	stim_params(8,:)';
else
	if( isfield(epData.epocs,'Freq') )
		switch size(stim_params,1)
			case 2
				protocol	=	'BestFreq';
				dB_level	=	stim_params(1,:)';
				stimDur		=	stim_params(2,:)';
		end
	end
	switch size(stim_params,1)
		case 4
			protocol	=	'AMRate';
			dB_level	=	stim_params(1,:)';
			stimDur		=	stim_params(2,:)';
			AMdepth		=	stim_params(3,:)';
			CFreq		=	stim_params(4,:)';
	end
end

% CREATE STIM STRUCT
%%%%%%%%---FOR JUSTIN---%%%%%%%%
Stim = struct();
if( behavior )
	for it = 1:numel(onsets)
		
		Stim(it).onset      =    onsets(it);
		Stim(it).behaving   =    behaving;
		Stim(it).block      =    block;
		
		Stim(it).Rate       =    Rate(it);
		Stim(it).dB         =    dB_level(it);
		Stim(it).stimDur    =    stimDur(it);
		Stim(it).AMdepth    =    AMdepth(it);
		
		% incorporate behavioral responses here too?
	end
else
	for it = 1:numel(onsets)
		
		Stim(it).onset      =    onsets(it);
		Stim(it).behaving   =    behaving;
		Stim(it).block      =    block;

		if( strcmp(protocol,'BestFreq') )
			Stim(it).Freq	=	 Freq(it);
		elseif( strcmp(protocol,'AMForwardMasking') )
			Stim(it).MaskerRate	=	 MaskerRate(it);
			Stim(it).SignalRate	=    SignalRate(it);
			Stim(it).AMdepth	=    AMdepth(it);
			Stim(it).SignalDur	=	 SignalDur;
			Stim(it).MaskerDur	=	 MaskerDur;
			Stim(it).DelayDur	=	 DelayDur;			
		else
			Stim(it).Freq	=	 CFreq(it);
			Stim(it).Rate	=    Rate(it);
			Stim(it).AMdepth=    AMdepth(it);
		end

		Stim(it).dB         =    dB_level(it);
		Stim(it).stimDur    =    stimDur(it);
		
	end
end
