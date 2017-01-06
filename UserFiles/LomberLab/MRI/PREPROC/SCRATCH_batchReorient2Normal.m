%% 2 Rotate all images into proper plane
% Does not do any fine adjustments to individual brains
%
% DJS 11/28/2016


rootPath = 'D:\DataProcessing\';

cd(rootPath);

addpath H:\DataProcessing\PREPROC

P = getFiles;

% P = P(cellfun(@isempty,strfind(P,'VOI'))); % hide directory

%%
% approximate transformations determined using spm_image
B = [-0.726778228129868,26.8164530330712,-52.5185948677407, ...
    -1.57079632679490,3.14159265358979,0, ...
    1,1,1,0,0,0];  
M = spm_matrix(B);

P = spm_select('expand',P);


F = spm_figure('FindWin','Interactive');
if isempty(F)
    F = spm_figure('Create','Interactive','SPM','on');
    set(F,'position',[108 045 400 395]);
end
spm_figure('Focus',F);

spm_progress_bar('Init',numel(P),'Reading current orientations',...
    'Images Complete');

Mats = zeros(4,4,numel(P));
for i = 1:numel(P)
    Mats(:,:,i) = spm_get_space(P{i});
    spm_progress_bar('Set',i);
end

spm_progress_bar('Init',numel(P),'Reorienting images',...
    'Images Complete');
for i = 1:numel(P)
    spm_get_space(P{i},M*Mats(:,:,i));
    spm_progress_bar('Set',i);
end


% %%
% Pavg = fullfile(spm('Dir'),'canonical','avg152T1.nii');
% spm_check_registration(char({Pavg; P}));

