
function epData = reformat_tank_data_kp(BLKS)
%reformat_tank_data
%   Function to reformat and save ephys data from epsych program.
%   
%   Program prompts user to select TANK, then cycles through each BLOCK,
%   calls TDT2mat (@DJS) to reformat tank data to a matlab struct, then
%   saves as a -mat file in google drive folder.
%   
%   Note: program will skip any Blocks that have already been processed
%   and saved. 
%
%   Added options for different experiments when a buffer was used to
%   create stimuli. The experiment type is determined by the naming of
%   epocs for saving data in RPVDS.
%   
%   KP 03/2016, last updated 06/2017.

addpath helpers

[~,computerName] = system('hostname');

%Select tank
switch computerName(1:6)
    case 'regina'
        directoryname = uigetdir('D:\data\KP','Select TANK');
        savedir = 'G:\NYUDrive\Sanes\DATADIR\AMJitter\RawData';
    case 'dhs-ri'
        directoryname = uigetdir('G:\KP\Tanks','Select TANK');
        savedir = 'G:\KP\toTransfer';
%         savedir = 'E:\AMjitter_aversive_test';
end
[~,tank] = fileparts(directoryname);

%Choose blocks to process
if nargin<1 %process all blocks
    blocks = dir(fullfile(directoryname,'Block*'));
    blocks = {blocks(:).name};
else 
    for ib = 1:numel(BLKS)
        blocks{ib} = sprintf('Block-%i', BLKS(ib));
    end
end


% Cycle through all blocks in this directory
for ii = 1:numel(blocks)
    
    this_block = blocks{ii};
%     epData = TDT2mat(tank,this_block)';
    
    
    % Set save location
    
    %now: always external harddrive
    if ~exist(savedir,'dir')
        error('  Connect hard drive!')
    end
    savefilename = [fullfile(savedir,tank) '\' this_block '.mat'];
    
    % If a folder does not yet exist for this tank, make one.
    if ~exist(fullfile(savedir,tank),'dir')
        mkdir(fullfile(savedir,tank))
    end
    
    % Check if datafile is already saved. If so, skip it.
%     if exist(savefilename,'file')
%         fprintf('\n skipping a file already in directory\n')
%         continue
%     end
    
    


    % Parse datafile
    
    fprintf('\n======================================================\n')
    fprintf('Processing ephys data, %s.......\n', this_block)
    epData = TDT2mat(tank,this_block)';
    
    
    
    
    %% Find the associated behavior file if it exists
    
    pn_pieces = strsplit(directoryname,'\');
    pn = fullfile(pn_pieces{1:end-1});
    date_reformat = datestr(datenum(epData.info.date,'yyyy-mmm-dd'));
    
    behaviorfilename = [pn_pieces{end} '_' date_reformat '*'];
    behaviorfile = dir(fullfile(pn,behaviorfilename));
    
    for ib = 1:numel(behaviorfile)
        load(fullfile(pn,behaviorfile(ib).name))
        
        %ephys only, on days with no behavior recording
        if ~isfield(Info,'epBLOCK') 
            keyboard
            behaviorfile = [];
            break
            
        %if the Info file loaded matches this block 
        elseif isfield(Info,'epBLOCK') && strcmp(this_block,Info.epBLOCK)
            behaviorfile = behaviorfile(ib);
            break
        end
        
        %if this block was not saved as an entry in a Behavior Info file, it is ephys only.
        if ib==numel(behaviorfile) 
            behaviorfile = [];
        end
    end
    
    
    
    %% Save buffer stimulus files/info
    
    %~~~~~~~~~~~~~~~~  original RAND/REG experiment  ~~~~~~~~~~~~~~~~~
    
    if isfield(epData.epocs,'iWAV') && ~isfield(epData.scalars,'iWBG')
        
        stimfolder = uigetdir('D:\stim','Select folder containing wav stimuli');
        filenames = dir(fullfile(stimfolder,'*.wav'));
        stimdirname = strtok(filenames(1).name,'_');
        
        epData.wavfilenames     = {filenames.name};
        epData.info.stimdirname = stimdirname;
        
        
        
    %~~~~~~~~~~~  target on background RAND/REG experiment  ~~~~~~~~~~~~
    
    elseif isfield(epData.epocs,'iWAV') && isfield(epData.scalars,'iWBG')
        
        % Target:
        stimfolder = uigetdir('D:\stim','Select folder containing TARGET stimuli');
        filenames = dir(fullfile(stimfolder,'*.wav'));
        targdirname = strtok(filenames(1).name,'_');
        
        epData.targ_wavfilenames = {filenames.name};
        epData.info.targ_dirname = targdirname;
        
        % Background:
        stimfolder = uigetdir('D:\stim','Select folder containing BACKGROUND stimuli');
        filenames = dir(fullfile(stimfolder,'*.wav'));
        bgdirname = strtok(filenames(1).name,'_');
        
        epData.bg_wavfilenames = {filenames.name};
        epData.info.bg_dirname = bgdirname;
        
        
        
    %~~~~~~~~~~~~~~~~~~  AM with jitter experiment  ~~~~~~~~~~~~~~~~~~~
    
    elseif isfield(epData.epocs,'rvID') && ~isfield(epData.streams,'rVrt') && ~isfield(epData.epocs,'CF_0')
        
        if ~isempty(behaviorfile) && exist('Info','var')
            
            % Get stimfiles from behavior file and save to epData
            epData.matfilenames     = Info.StimFilenames;
            epData.info.stimdirname = Info.StimDirName;
            
            % Associate the behavior file with epData struct
            epData.info.fnBeh       = behaviorfile.name;
            
            % Copy behavior file to external harddrive
            copyfile(fullfile(pn,behaviorfile.name),[fullfile(savedir,tank) '\BehaviorData'])
            
            
        else %if no behavior file (just ephys), 
            
            % The stim file names have not yet been saved so must be
            % selected manually.
            
            % Get folder of stimulus files
            stimfolder = uigetdir('D:\stim\AMjitter',['Select folder of stimuli for ' this_block]);
            
            % Manually select files in the same order as protocol file
            filenames = cell(1,numel(dir(fullfile(stimfolder,'*.mat'))));
            for isf=1:numel(dir(fullfile(stimfolder,'*.mat')))
                filenames{isf} = uigetfile(stimfolder);
            end
            
            % Save to epData
            epData.matfilenames     = filenames;
            epData.info.stimdirname = stimfolder;
            
        end
        
        
        % Also transfer a folder containing the matfiles 
        savestimdir = [fullfile(savedir,tank) '\' this_block '_Stim'];
        
        [saved,messg] = copyfile(epData.info.stimdirname,savestimdir,'f');
        
        if ~saved
            warning(' \n !!! Stimulus files not copied ')
            keyboard
        end
        
        
        
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    %~~~~~~~~~~~~~~~~~~  AM stream experiment  ~~~~~~~~~~~~~~~~~~~
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        % epData.streams.rVrt.data
        %  (1,:) = Instantaneous AM rate <-- if Trials stim set, just this
        %  (2,:) = Sound output          <-- if Trials stim set, just this
        %  (3,:) = AM depth
        %  (4,:) = dB SPL
        %  (5,:) = HP
        %  (6,:) = LP
        %  (7,:) = Spout TTL
        
    %~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~   Linearity   ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
    elseif isfield(epData.streams,'rVrt') && ~isfield(epData.epocs,'Dpth') && ~isfield(epData.epocs,'RCod')
        epData.info.stimpath = 'D:\stim\AMjitter\IR_AM_linearity';
        
    %~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~     Trials     ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
    elseif isfield(epData.streams,'rVrt') && isfield(epData.epocs,'Dpth') && ~isfield(epData.epocs,'RCod')
        epData.info.stimpath = 'D:\stim\AMjitter\IR_AM_trials';
            
    %~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~     SpectralSwitch     ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
    elseif isfield(epData.streams,'rVcf') && ~isfield(epData.epocs,'RCod')
        epData.info.stimpath = 'D:\stim\AMjitter\IR_AM_SpectralSwitch';
        
        
        
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    %~~~~~~~~~~~~~~~~~  AM aversive experiment  ~~~~~~~~~~~~~~~~~~
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        % Falling edge of InTrial
        %  epData.epocs.RCod -- response code
        %   17: hit
        %   18: miss
        %   36: CR
        %   40: FA
        
        % StimTrial TTL:
        %  epData.epocs.TTyp --  0: Warn, 1: Safe
        %  epData.epocs.Opto 
        %  epData.epocs.rVID --  rateVec_ID
        
        % end of each AM period
        %  epData.epocs.AMrt  =  instantaneous AM rate of period ending
        
        % epData.streams.rVrt.data
        %  (1,:) = Instantaneous AM rate
        %  (2,:) = Sound output  
        %  (3,:) = AM depth
        %  (4,:) = dB SPL
        %  (5,:) = HP
        %  (6,:) = LP
        %  (7,:) = Spout TTL   
        %  (8,:) = ITI TTL
    
    elseif isfield(epData.streams,'rVrt') && isfield(epData.epocs,'RCod') && isfield(epData.epocs,'AMrt')
        
        if ~isempty(behaviorfile) && exist('Info','var')
            
            % Get stimfiles from behavior file and save to epData
            epData.stimfs     = Info.stimfns;
            
            % Associate the behavior file with epData struct
            epData.info.fnBeh = behaviorfile.name;
            
            % Copy behavior file to external harddrive
            copyfile(fullfile(pn,behaviorfile.name),[fullfile(savedir,tank) '\' this_block '_behavior.mat'])
        end
        
        
    end %filter experiment type
    
    
    
    %%  
    
    % Remove field containing eNeu data to save a little space
    if isfield(epData,'snips')
        epData = rmfield(epData,'snips');
    end
    
    % Save epData .mat file to external hard drive
    %now: always external harddrive
%     savedir = 'G:\NYUDrive\Sanes\DATADIR\AMStream\RawData';
    if ~exist(savedir,'dir')
        error('  Connect hard drive!')
    end
    savefilename = [fullfile(savedir,tank) '\' this_block '.mat'];
    
    try
        fprintf('\nsaving...')
        save(savefilename,'epData','-v7.3')
        fprintf('\n~~~~~~\nSuccessfully saved datafile to drive folder.\n\t %s\n~~~~~~\n',savefilename)
    catch
        warning('\n **Could not save file. Check that directory exists.\n')
        keyboard
    end
    
    
    
    
end  % for ii = 1:numel(blocks)


fprintf('\n\n ##### Finished reformatting and saving data files.\n\n')


end




