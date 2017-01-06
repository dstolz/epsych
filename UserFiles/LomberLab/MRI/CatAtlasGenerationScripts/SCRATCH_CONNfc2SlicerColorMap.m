%% CONN first-level ROI-2-ROI results to 3D Slicer model color map
% Z contains Fisher-transformed correlation coefficient values (beta
% values) for each ROI-2-ROI pair and for subject

ROI2ROIfile = 'D:\FuncMRIcloud\resultsROI_Condition001.mat';
CatlasFile  = 'D:\ownCloud\PROJECTS\MRI\TPM_Catlas_Slicer4\Catlas_Mod.txt';


scaleAllTogether = true; 


load(ROI2ROIfile)

mZ = mean(Z,3);
maxZ = max(abs(mZ(:)));


[selidx,ok] = listdlg('ListString',names);
if ~ok, return; end

[pn,fn] = fileparts(ROI2ROIfile);

i     = cellfun(@(a)   (find(a=='.',1)+1),names,'UniformOutput',false);
names = cellfun(@(a,b) (a(b:end)),names,i,'UniformOutput',false);
i     = cellfun(@(a)   (find(a=='(',1)-2),names,'UniformOutput',false);
names = cellfun(@(a,b) (a(1:b)),names,i,'UniformOutput',false);
i     = cellfun(@(a)   (find(a==' ',1)),names,'UniformOutput',false);
names = cellfun(@(a,b) ([a(1:b-1) '_' a(b+1)]),names,i,'UniformOutput',false);

% Look up original atlas
fid = fopen(CatlasFile,'r');
clear atlas
i = 1;
while ~feof(fid)
    atlas{i} = fgetl(fid);
    i = i + 1;
end
fclose(fid);

i = cellfun(@(a) (find(a==' ',2)),atlas,'UniformOutput',false);
atlas = cellfun(@(a,b) (a(1:b(2)-1)),atlas,i,'UniformOutput',false);
atlas = cellfun(@(a,b) ([a(1:b(1)-1) '_' a(b(1)+1)]),atlas,i,'UniformOutput',false);

% remap names from analysis results to standard atlas
rmap = nan(size(atlas));
for i = 1:length(atlas)
    ind = ismember(names,atlas{i});
    if ~any(ind)
%         warning(sprintf('The region ''%s'' was not found in the analysis results',names{i}))
        continue
    end
    rmap(i) = find(ind);
end

imap = find(isnan(rmap)); % missing names
rmap = rmap(~isnan(rmap)); % matching names
rmZ = mZ(rmap,:);
rmZ = rmZ(:,rmap);
rnames = names(rmap);
selidx = find(ismember(rnames,names(selidx)));
cvals = round(jet(32)*255);

%% print out a new color lut file for each seed region
for x = 1:length(selidx)
    selZ = rmZ(:,selidx(x));
    
    if ~scaleAllTogether, maxZ = max(abs(selZ)); end
    
    cbins = discretize(selZ,linspace(-maxZ,maxZ,size(cvals,1)));
    
    cfn = fullfile(pn,sprintf('%s_COLORMAP-%s.txt',fn,rnames{selidx(x)}));
    fid = fopen(cfn,'w+');
    k = 1;
    for i = 1:length(atlas)
        fprintf(fid,'%d %s ',i,atlas{i});
        if any(ismember(rnames,atlas{i}))
            if isnan(selZ(i))
                fprintf(fid,'%d %d %d %d',[1 1 1 1]*155);
            else
                fprintf(fid,'%d %d %d %d',cvals(cbins(i),:),255);
            end
            
        else
            fprintf(fid,'%d %d %d %d',[1 1 1]*50,255);
        end
        if i < length(atlas), fprintf(fid,'\n'); end
    end
    fclose(fid);
    
    fprintf('Wrote:\t<a href="matlab: !explorer %s">%s</a>\n',cfn,cfn)
    
end



