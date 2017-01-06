%% 1. Move select files from subdirectories to another directory

indir = 'D:\ownCloud\BIG_DATA\MRI';
outdir = 'D:\DataProcessing\NII';

d = dir(indir);
d(1:2) = []; % get rid of dots
d(~[d.isdir]) = [];
dname = {d.name}';
disp(dname)

%%
istr = cellfun(@fullfile,repmat(cellstr(indir),size(dname)),dname,repmat({'NII'},size(dname)),'UniformOutput',false);

ind = ~cellfun(@isdir,istr);
if any(ind)
    fprintf(2,'%dname of %dname directories do not have a ''NII'' subdirectory:\n',sum(ind),length(dname))
end
cellfun(@(a) (fprintf(2,'\t%s\n',a)),dname(ind));
istr(ind) = [];
dname(ind)= [];
d(ind) = [];

% remove date from beginning of output subdirectory
for i = 1:length(dname)
    if all(dname{i}(1:2) == '20')
        dname{i} = dname{i}(length('2016_01_01_')+1:end);
    end
end


size_d = size(dname);
ostr{1} = cellfun(@fullfile,repmat(cellstr(outdir),size_d),dname,repmat({'STRUCTURALS'},size_d),'UniformOutput',false);
ostr{2} = cellfun(@fullfile,repmat(cellstr(outdir),size_d),dname,repmat({'RSS'},size_d),'UniformOutput',false);
ostr{3} = cellfun(@fullfile,repmat(cellstr(outdir),size_d),dname,repmat({'FIELDMAPS'},size_d),'UniformOutput',false);
ostr{4} = cellfun(@fullfile,repmat(cellstr(outdir),size_d),dname,repmat({'VELOCITY'},size_d),'UniformOutput',false);

nstr{1} = 'mp2rage';
nstr{2} = 'rss';
nstr{3} = 'grefieldmapping';
nstr{4} = 'Visuals';

rstr{1} = 'T1';
rstr{2} = 'RSS';
rstr{3} = 'FM';
rstr{4} = 'VELOCITY';

fprintf('Copying files...\n')
for i = 1:length(ostr)
    for j = 1:length(istr)
                
        if ~isdir(ostr{i}{j}), mkdir(ostr{i}{j}); end
        
        do = dir(fullfile(istr{j},sprintf('*%s*.nii',nstr{i})));
        [~,sidx] = sort({do.name});
        do = do(sidx);
        
        for k = 1:length(do)
            a = fullfile(istr{j},do(k).name);
            fn = sprintf('%s_%02d.nii',rstr{i},k);
            b = fullfile(ostr{i}{j},fn);
            fprintf('..%s\n(%0.1f MB) -> %s ...',a(length(indir)+1:end),do(k).bytes/1e6,b)
            [s,m,mid] = copyfile(a,b);
            if s
                fprintf(' done\n')
                infofile = fullfile(ostr{i}{j},'info.txt');
                fid = fopen(infofile,'a+');
                fprintf(fid,'Timestamp: %s\n',datestr(clock));
                fprintf(fid,'Original File: %s\n',a);
                fprintf(fid,'Copied File: %s\n',b);
                fclose(fid);
            else
                fprintf(2,' %s\n',m)
            end
        end
        
    end
end

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    