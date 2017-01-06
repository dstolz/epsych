%% Generate random colors for 3d Catlas in Slicer 3D
% This script will read the specified atlas txt file and generate random
% colors and save it as a new file called 'CATLAS_COLORS.txt' in the pwd.
% Manually copy this new file to the Slicer 'ColorFiles' subdirectory.
% Slicer 3D will have to be relaunched if it is already open when the file
% is replaced.
%
% The first 'cell' in this script creates 'CATLAS_COLORS.txt'. The second
% 'cell' creates 'CATLAS_COLORS-SPLIT.txt'.
%
%
% DJS 9/2016

% Cfn = 'C:\Program Files\Slicer 4.5.0-1\share\Slicer-4.5\ColorFiles\CATLAS_COLORS.txt';
Cfn = 'D:\ownCloud\PROJECTS\MRI\TPM_Catlas_Slicer4\Catlas.txt';

clear C
i = 1;
fid = fopen(Cfn,'r');
while ~feof(fid)
    c = fgetl(fid);
    C{1}{i,1} = c(1:find(c==' ',1)-1); % name
    C{2}(i,1) = c(find(c==' ',1)+1:find(c=='(',1)-2); % L/R
    C{3}{i,1} = c(find(c=='(',1)+1:find(c==')',1,'last')-1); % Description
    i = i + 1;
end
fclose(fid);

if ~iscell(C{2}) && any(C{2}(1)=='lrLR')
    ind = lower(C{2}) == 'r';
    C{1}(ind) = [];
    C{3}(ind) = [];
    C{2} = C{3};
    C(3) = [];
end

n = length(C{1});
Colors = lines(n);
Colors = Colors(randperm(n),:);

rng(2)
q = rand(size(Colors));
q(q<0.6) = 1;

Colors = Colors.*q;

Colors(Colors>1) = 1;

dc = sum(diff(Colors),2);
i  = find([false; abs(dc)<0.1]);
Colors(i,:) = Colors(i(randperm(length(i))),:);

r = floor(sqrt(n));
c = ceil(n/r);
m = zeros(r,c);
m(1:n) = 1:n;

f = findFigure('CATLAS_COLORS','color','w');
figure(f)
imagesc(m)

colormap([0 0 0; Colors])

Colors = [round(Colors*255) ones(n,1)*255];

nfn = fullfile(pwd,'CATLAS_COLORS.txt');
fid = fopen(nfn,'w+');
for i = 1:n
    fprintf(fid,'%d %s %d %d %d %d',i,C{1}{i},Colors(i,:));
    if i < n, fprintf(fid,'\n'); end
end
fclose(fid);
fprintf('Wrote: <a href="matlab: edit(''%s'')">%s</a>\n',nfn,nfn)

%% Create a 'split atlas' version of the color map

LR = repmat('LR',n,1);
C{1} = [C{1}; C{1}];
C{1} = cellfun(@(a,b) ([a '_' b]),C{1},cellstr(LR(:)),'UniformOutput',false);

n = length(C{1});
Colors = lines(n);
Colors = Colors(randperm(n),:);

rng(2)
q = rand(size(Colors));
q(q<0.6) = 1;

Colors = Colors.*q;

Colors(Colors>1) = 1;

dc = sum(diff(Colors),2);
i  = find([false; abs(dc)<0.1]);
Colors(i,:) = Colors(i(randperm(length(i))),:);

r = floor(sqrt(n));
c = ceil(n/r);
m = zeros(r,c);
m(1:n) = 1:n;

f = findFigure('CATLAS_COLORS','color','w');
figure(f)
imagesc(m)

colormap([0 0 0; Colors])

Colors = [round(Colors*255) ones(n,1)*255];


nfn = fullfile(pwd,'CATLAS_COLORS-SPLIT.txt');
fid = fopen(nfn,'w+');
for i = 1:n
    fprintf(fid,'%d %s %d %d %d %d',i,C{1}{i},Colors(i,:));
    if i < n, fprintf(fid,'\n'); end
end
fclose(fid);
fprintf('Wrote: <a href="matlab: edit(''%s'')">%s</a>\n',nfn,nfn)








