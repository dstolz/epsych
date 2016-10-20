
function reformat_tank_data_jy(BLKS)
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

%---FLAG---%
ID      =   '235107';
%Select tank
directoryname = uigetdir('D:\data\JDY\Tanks','Select TANK');
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
    savedir = ['D:\data\JDY\ConvertedTankData\' ID];
    savefilename = [fullfile(savedir,tank) '\' this_block '.mat'];
    if exist(savefilename,'file')
        continue
    end
    
    %Parse datafile
    fprintf('\n======================================================\n')
    fprintf('Processing ephys data, %s.......\n', this_block)
    epData = TDT2mat(tank,this_block)';
    
    %Save .mat file
    try
        save(savefilename,'epData','-v7.3')
        fprintf('\n~~~~~~\nSuccessfully saved datafile to drive folder.\n\t %s\n~~~~~~\n',savefilename)
    catch
        error('\n **Could not save file. Check that directory exists.\n')
    end
end

fprintf('\n\n ##### Finished reformatting and saving data files.\n\n')

end


