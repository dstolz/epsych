function P = getFiles(searchstr)
% P = getFiles([searchstr]);
%
% Daniel.Stolzberg@gmail.com 2016


if ~nargin, searchstr = '**\*.nii'; end

Subjs = getSubjects;

if isempty(Subjs), error('No Subjects found under the current directory: %s',pwd); end
    
[sel,ok] = listdlg('ListString',Subjs, ...
                    'InitialValue',1:length(Subjs), ...
                    'Name','Reorient2Normal',...
                    'PromptString','Select subjects to reorient 2 normal ...');

P = [];
if ~ok, return; end
for i = 1:length(sel)
    D = rdir(fullfile(pwd,'\NII\',Subjs{sel(i)},searchstr));
    fprintf('Found %d files for "%s" matching "%s"\n', ...
        length(D),Subjs{sel(i)},searchstr)
    P = [P; {D.name}'];
end

