% Convert PLX file to Matlab file for Uploading using DB_UploadUtility


plxdir = 'D:\DataProcessing\HANSOLO\HANSOLO_20160519\plx\rep\preproc\presort\sorted\REWARM';
minSpikes = 50;
make_all_MUA = false;
allchannels = true;
% trodes = num2cell(1:32);
% trodes = num2cell([1 3 4 7 9 13 18 19 22 25 26 31]);





plxes = dir(fullfile(plxdir,'*.plx'));
plxname = {plxes.name};

clear snips
for i = 1:length(plxname)
    fprintf('\n%s\nProcessing %s\n',repmat('*',1,50),plxname{i});
    plxfilename = fullfile(plxdir,plxname{i});
    if allchannels
        [s,t,d,c] = PLX2MAT(plxfilename);
        trodes = num2cell(c);
    else
        [s,t,d] = PLX2MAT(plxfilename,trodes);
    end
    
    % make all MUA vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
    if make_all_MUA
        fprintf(2,'Making all units MUA (pool = 1)\n')
        ind = cellfun(@(a) (a>0),s,'UniformOutput',false);
        s = cellfun(@(a,b) (a(b)),s,ind,'UniformOutput',false);
        t = cellfun(@(a,b) (a(b)),t,ind,'UniformOutput',false);
        d = cellfun(@(a,b) (a(b)),d,ind,'UniformOutput',false);
        s = cellfun(@(a) (ones(size(a))),s,'UniformOutput',false);
    end
    % ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    
    snips(i).SNIP.sortcode = cell2mat(s'); % Add one to sort codes
    snips(i).SNIP.ts       = cell2mat(t');
    snips(i).SNIP.data     = cell2mat(d');
    
    c = cellfun(@numel,s);
    snips(i).SNIP.chan = [];
    for j = 1:length(c)
        snips(i).SNIP.chan = [snips(i).SNIP.chan; trodes{j}(1)*ones(c(j),1,'uint16')];
    end
    
    badind = snips(i).SNIP.sortcode == 0;
    if any(badind), fprintf(2,'Dumping %d unclassed spikes\n',sum(badind)); end
    snips(i).SNIP.sortcode(badind) = [];
    snips(i).SNIP.ts(badind)       = [];
    snips(i).SNIP.data(badind,:)   = [];
    snips(i).SNIP.chan(badind)     = [];

    
    snips(i).SNIP.fs = 24414;
end



fprintf('Saving ...')
save('HANSOLO_20160519_SNIPS.mat','snips')
fprintf(' done\n')










