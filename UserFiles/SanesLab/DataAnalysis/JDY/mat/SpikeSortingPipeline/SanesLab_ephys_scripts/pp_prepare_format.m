
function pp_prepare_format(BLOCKS,subject,session_label,ConditionFolder,behavior,Path,savedir,time)
%
%  pp_prepare_format( BLOCKS, subject, session_label )  
%    Creates data structures in the desired format for processing. Groups
%    together sequentially-recorded blocks, indicated in input argument,
%    and makes a structure with stimulus info by trial, a structure with
%    ephys data in windows around each trial (in the format needed for
%    sorting in UMS2000) and file with relevant information, including the 
%    time window around trials start for which ephys data was extracted.
%    
%    For each block, calls functions:
%     - pp_make_stim_struct(epData)
%     - pp_make_phys_struct(epData,t1,t2)
%
%    Saves data files:
%     SUBJECT_sess-XX_Info.mat
%     SUBJECT_sess-XX_Phys.mat
%     SUBJECT_sess-XX_Stim.mat
%
%  KP, 2016-04; last updated 2016-04
% 

tic

    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    %To Add:
    %   change time window with stim duration?
    %   remove noisy trials altogether?

    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% includePath='/Users/kpenikis/Documents/MATLAB/ums2k_02_23_2012';
% includePath='/Users/justinyao/Sanes Lab/mat/SpikeSorter/UltraMegaSort';
% addpath(genpath(includePath));

fprintf('\n------------------------------------------------------------')
fprintf('\nProcessing ephys data from: %s',subject)

Unix    =   isunix;

Stim=[];   Phys=[];

for ib=1:numel(BLOCKS)
    
    % Load this block datafile
    
    block_str = sprintf('Block-%i.mat',BLOCKS(ib));
	
	%%%%%%%%
% 	Path		=	'/Users/justinyao/Sanes Lab/Experiments/PROJECTS/AM RATE/Ephys/';
if( Unix )
	datafile	=	[ Path subject '/' ConditionFolder '/' block_str];
    fprintf('/n loading data file %s...',datafile)
else
    datafile	=	[ Path subject '\' ConditionFolder '\' block_str];
    fprintf('\n loading data file %s...',datafile)
end
    
    epData = [];
    
    load(datafile,'-mat'); %loads data struct: epData

    if isempty(epData)
        error('data file did not load correctly!') 
    end
    starttimes{ib} = epData.info.starttime;
    
    try
    
    % Create STIM struct with stimulus info
    
    fprintf('\n   adding to STIM struct...')
    st = pp_make_stim_struct( epData, BLOCKS(ib), behavior );
    Stim = [Stim st];
    st=[];
    fprintf('                           done.')
%     
    catch
        keyboard
    end
    
    
    % Create struct of phys data in windows around trials
    t1ms    =   time(1);
    t2ms    =   time(2);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fs = epData.streams.Wave.fs;
% % %     % FOR M2 DATA %
% % %     t1ms = -999;				%ms of data to pull before tr start
% % %     t2ms = 6000;                %ms of data to pull before tr end (900)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FOR ACx DATA %
%     t1ms = -299;				%ms of data to pull before tr start
%     t2ms = 600;
%     t2ms = 1200;                %ms of data to pull before tr end (900)  
% 	en		=	max(epData.scalars.Pars.data(2,:));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
% 	if( en == 1400 )
% 		t2ms	=	en + 200;
% 	else
% 		t2ms	=	1200;
% 	end
	
	%---Can adjust t2ms = stim duration (need to save in epData.scalars.Pars.data)---%
    t1 = round(t1ms/1000*fs);   %converted to samples
    t2 = round(t2ms/1000*fs);   %converted to samples
	
    try
        
    fprintf('\n   adding to PHYS struct...')
    ph = pp_make_phys_struct(epData,t1,t2);
    Phys = [Phys; ph];
    ph=[];
    fprintf('       done.')
    
    catch
        keyboard
    end
    
end  %for ib=1:numel(blocks)

% Create Info struct
Info				=	struct;
Info.subject		=	subject;
Info.date			=	epData.info.date;
Info.starttimes		=	starttimes;
Info.blocks			=	BLOCKS';
Info.t_win_ms		=	[t1ms t2ms];
Info.fs				=	epData.streams.Wave.fs;

% SAVE DATA 
% savedir  = '/Users/justinyao/Sanes Lab/Experiments/PROJECTS/AM RATE/Ephys/processed_data';
% savedir  = '/Users/kpenikis/Documents/SanesLab/Data/processed_data';
if ~exist('session_label','var')
    prompt = '\n--> please enter uppercase letters for session label and press enter.';
    session_label = input(prompt,'s');
end
fprintf('\nsaving data...')

session_label		=	[session_label '-' num2str(BLOCKS)];

% Save Stim structure
savename = sprintf('%s_sess-%s_Stim',subject,session_label);
save(fullfile(savedir,subject,savename),'Stim','-v7.3');

% Save Phys structure
savename = sprintf('%s_sess-%s_Phys',subject,session_label);
save(fullfile(savedir,subject,savename),'Phys','-v7.3');

% Save Info structure
savename = sprintf('%s_sess-%s_Info',subject,session_label);
save(fullfile(savedir,subject,savename),'Info','-v7.3');


%
fprintf('\n\n**Finished processing and saving data for this recording session.\n')
fprintf('------------------------------------------------------------\n\n')

%
toc

end  



