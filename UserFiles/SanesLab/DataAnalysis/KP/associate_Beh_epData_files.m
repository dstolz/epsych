function associate_Beh_epData_files(subject)

pn = fullfile('/Users/kpenikis/Documents/SanesLab/Data/raw_data',subject);
pnB = fullfile(pn,'BehaviorData');
epData=[];

Beh_files = dir(fullfile(pnB,'old','*.mat'));

for ii = 1:numel(Beh_files)
    
    load( fullfile(pnB,'old', Beh_files(ii).name) );
    
    disp(Beh_files(ii).name)
    
    BLOCK = input(['Please select the ephys BLOCK associated with the behavior session on '...
        Beh_files(ii).date '\n If no ephys, just behavior, enter 0.\n' ],'s');
    
    if ischar(BLOCK) && ~strcmp(BLOCK,'0')
        Info.epBLOCK = ['Block-' BLOCK];
        
        load_epData_addBehfn(Info.epBLOCK)
        
    elseif isnumeric(BLOCK) && BLOCK~=0
        Info.epBLOCK = sprintf('Block-%i',BLOCK);
        
        load_epData_addBehfn(Info.epBLOCK)
        
    elseif strcmp(BLOCK,'0') || BLOCK==0
        Info.epBLOCK = 'no-ephys';
        
    end
    
    
    %Save Behavior file again
    save(fullfile(pnB,Beh_files(ii).name),'Info','Data','-v7.3')
    
    
    clear BLOCK Data Info
    
end


    function load_epData_addBehfn(block)
        
        %Load epData Block
        load(fullfile(pn,[block '.mat']))
        
        %Add behvaior file name
        epData.info.fnBeh = fullfile(pnB,Beh_files(ii).name);
        
        %Correct the stimulus filenames if needed
        if (numel(epData.matfilenames) ~= max([Data.rateVec_ID])) || ~isfield(epData,'matfilenames')
            epData.matfilenames = Info.StimFilenames;
        end
        
        %Save epData
        save(fullfile(pn,[block '.mat']),'epData','-v7.3')
        
        epData=[];
    end


end