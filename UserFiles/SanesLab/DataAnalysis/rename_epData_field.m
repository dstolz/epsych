
datadir = 'E:\RawData\PPP_236393\';
filenames = dir(fullfile(datadir,'*.mat'));
filenames = {filenames.name};


for ii = 1:numel(filenames)
    
    load(fullfile(datadir,filenames{ii}));
    
    if isfield(epData.epocs,'DLAM')
        epData.epocs.dBSP = epData.epocs.DLAM;
        epData.epocs = rmfield(epData.epocs,'DLAM');
        epData.epocs.dBSP.name = 'dBSP';
        save(fullfile(datadir,filenames{ii}));
    end
    
    clear epData
end




