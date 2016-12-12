
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
%   KP 03/2016, last updated 12/2016.

addpath helpers

%Select tank
directoryname = uigetdir('D:\data\KP','Select TANK');
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
    
    %(old)
%     [~, compName] = system('hostname');
%     if strncmp(compName,'PC',2)
%         savedir = 'E:\kp_data';
%     else
%         savedir = 'C:\Users\sanesadmin\Google Drive\kp_data';
%     end

    %now: always external harddrive
    savedir = 'G:\RawData';
    if ~exist(savedir,'dir')
        error('  Connect hard drive!')
    end
    savefilename = [fullfile(savedir,tank) '\' this_block '.mat'];
    
    % Check if datafile is already saved. If so, skip it.
    if exist(savefilename,'file')
        fprintf('\n skipping a file already in directory\n')
        continue
    end
    
    % If a folder does not yet exist for this tank, make one.
    if ~exist(fullfile(savedir,tank),'dir')
        mkdir(fullfile(savedir,tank))
    end
    
    
    


    % Parse datafile
    
    fprintf('\n======================================================\n')
    fprintf('Processing ephys data, %s.......\n', this_block)
    epData = TDT2mat(tank,this_block)';
    
    
    
    
    % Find the associated behavior file if it exists
    
    pn_pieces = strsplit(directoryname,'\');
    pn = fullfile(pn_pieces{1:end-1});
    date_reformat = datestr(datenum(epData.info.date,'yyyy-mmm-dd'));
    
    behaviorfilename = [pn_pieces{end} '_' date_reformat '*'];
    behaviorfile = dir(fullfile(pn,behaviorfilename));
    
    if numel(behaviorfile)>1
        keyboard
%         behaviorfile = behaviorfile(1);
    end
    
    % Load behavior file if it exists
    if numel(behaviorfile)==1
        load(fullfile(pn,behaviorfile.name))
    end
    
    
    
    
    
    
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
    
    elseif isfield(epData.epocs,'rvID')
        
        if ~isempty(behaviorfile) && exist('Info','var')
            
            % Get stimfiles from behavior file and save to epData
            epData.matfilenames     = Info.StimFilenames;
            epData.info.stimdirname = Info.StimDirName;
            
        else %if no behavior file (just ephys)
            
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
            warning('stimulus matfiles not copied')
            keyboard
        end
        
    end
    
    
    
    
    %Save epData .mat file to google drive
    try
        fprintf('\nsaving...')
        save(savefilename,'epData','-v7.3')
        fprintf('\n~~~~~~\nSuccessfully saved datafile to drive folder.\n\t %s\n~~~~~~\n',savefilename)
    catch
        error('\n **Could not save file. Check that directory exists.\n')
    end
end

fprintf('\n\n ##### Finished reformatting and saving data files.\n\n')

end


