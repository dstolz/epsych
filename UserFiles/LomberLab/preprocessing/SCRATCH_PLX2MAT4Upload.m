% Convert PLX file to Matlab file for Uploading using DB_UploadUtility


plxdir = 'D:\DataProcessing\HANSOLO\plx\rep\preproc\sort\';

plxes = dir(fullfile(plxdir,'*.plx'));

trodes = num2cell([1 3 4 7 9 13 18 19 22 25 26 31]);

plxname = {plxes.name};

clear snips
for i = 1:length(plxname)
    fprintf('\n%s\nProcessing %s\n',repmat('*',1,50),plxname{i});
    plxfilename = fullfile(plxdir,plxname{i});
    [s,t,d] = PLX2MAT(plxfilename,trodes);
    snips(i).SNIP.sortcode = cell2mat(s')+1; % Add one to sort codes
    snips(i).SNIP.ts       = cell2mat(t');
    snips(i).SNIP.data     = cell2mat(d');
    
    c = cellfun(@numel,s);
    snips(i).SNIP.chan = [];
    for j = 1:length(c)
        snips(i).SNIP.chan = [snips(i).SNIP.chan; trodes{j}(1)*ones(c(j),1,'uint16')];
    end
    
    badind = snips(i).SNIP.sortcode == 1;
    if any(badind), fprintf(2,'Dumping %d unclassed spikes\n',sum(badind)); end
    snips(i).SNIP.sortcode(badind) = [];
    snips(i).SNIP.ts(badind)       = [];
    snips(i).SNIP.data(badind,:)   = [];
    snips(i).SNIP.chan(badind)     = [];

    
    snips(i).SNIP.fs = 24414;
end



fprintf('Saving ...')
save('HANSOLO_TEST_PLX.mat','snips')
fprintf(' done\n')










