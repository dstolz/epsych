function Spikes = pp_fullprocess( BLOCKS, subject, session )
%
%  Run full processing workflow. Take data from raw (epData) format,
%  through automatic spike sorting steps.
%  
%  Note: user input is required in the middle, to select clean trials.
%

pp_prepare_format( BLOCKS, subject, session );

Spikes = pp_sort_session( subject, session );

end