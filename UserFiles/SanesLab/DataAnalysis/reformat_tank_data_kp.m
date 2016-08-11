
function reformat_tank_data_kp(BLKS)
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
%   KP 03/2016.


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


%Cycle through all blocks in this directory
for ii = 1:numel(blocks)
    
    this_block = blocks{ii};
    
    %Check if datafile is already saved. If so, skip it.
    savedir = 'C:\Users\sanesadmin\Google Drive\kp_data';
    savefilename = [fullfile(savedir,tank) '\' this_block '.mat'];
%     if exist(savefilename,'file')
%         continue
%     end
    
    %Parse datafile
    fprintf('\n======================================================\n')
    fprintf('Processing ephys data, %s.......\n', this_block)
    epData = TDT2mat(tank,this_block)';
    
    if isfield(epData.epocs,'iWAV')
        stimfolder = uigetdir('D:\stim','Select folder containing wav stimuli');
        filenames = dir(fullfile(stimfolder,'*.wav'));
        stimdirname = strtok(filenames(1).name,'_');
        
        epData.wavfilenames     = {filenames.name};
        epData.info.stimdirname = stimdirname;
    end
    
    %Save .mat file to google drive
    try
        save(savefilename,'epData','-v7.3')
        fprintf('\n~~~~~~\nSuccessfully saved datafile to drive folder.\n\t %s\n~~~~~~\n',savefilename)
    catch
        error('\n **Could not save file. Check that directory exists.\n')
    end
end

fprintf('\n\n ##### Finished reformatting and saving data files.\n\n')

end


