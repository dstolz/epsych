function masked_files = MySPM_BatchMasking(fmri_fns,mask_fn)
% MySPM_BatchMasking
% MySPM_BatchMasking(fmri_fns,mask_fn)
% d = MySPM_BatchMasking(...)
%
% Use this script to apply a mask to one or more 3D or 4D NIfTI files.
%
% Input:    fmri_fns     ...    cellstr array of 3D or 4D NIfTI files (optional)
%           mask_fn      ...    string with 3D NIfTI mask file (optional)
%
% Output:   masked_files ...    cellstr array of masked NIfTI files
% 
% Resulting masked files will be saved in a subfolder of the fMRI directory
% called 'MASKED' and all masked files are prepended with 'm'.
% 
% Creates a temporary subfolder in the current directory and then deletes
% it when all processing is completed (or if an error occurs).
%
% Note that warnings will be thrown by SPM for all images being masked if
% the dimensions do not match exactly.  This is probably ok if the mask
% file is of a higher resolution than the fMRI files.  A warning will be
% thrown for each frame of a 4D images with dimensions that do not match
% that of the mask image (i.e., lots of warnings).  Again, this is probably
% ok, but always check registration after running this script.
%
% Daniel.Stolzberg@gmail.com 2015

%% Select files
if nargin == 0 || isempty(fmri_fns)
    uiwait(msgbox('Select one or more 3D and/or 4D NIfTI (*.nii) files.','Batch Mask','help','modal'));
    [fmri_fns,fmri_pth] = uigetfile({'*.nii','NIfTI fMRI file (*.nii)'},'fMRI File','MultiSelect','on');
    if ~iscell(fmri_fns) && ~fmri_fns(1), return; end
    fmri_fns = cellstr(fmri_fns);
else
    for i = 1:length(fmri_fns)
        [fmri_fns{i},fmri_pth] = fileparts(fmri_fns{i});
    end
end


if nargin < 2 || isempty(mask_fn)
    uiwait(msgbox('Select one 3D NIfTI (*.nii) file to use as a mask.','Batch Mask','help','modal'));
    [mask_fn,mask_pth] = uigetfile({'*.nii','NIfTI ROI file (*.nii)'},'ROI File');
    if ~mask_fn, return; end
else
    [mask_fn,mask_pth] = fileparts(mask_fn);
end




TMPdir = [fmri_pth 'TMP' num2str(randi(1e9))];
while exist(TMPdir,'dir')
    TMPdir = [fmri_pth 'TMP' num2str(randi(1e9))]; % make unique temporary folder
end
C.outdir{1}= TMPdir;
C.expression = 'i1.*i2';
C.options.dmtx = 0;
C.options.mask = 0;
C.options.interp = -5; % 3rd order sinc interpolation
C.options.dtype = 16;
C.input{2,1} = [fullfile(mask_pth,mask_fn),',1'];

masked_files = cell(size(fmri_fns));

if ~exist([fmri_pth,'MASKED'],'dir'), mkdir([fmri_pth,'MASKED']); end
if ~exist(TMPdir,'dir'), mkdir(TMPdir); end

try
    for f = 1:length(fmri_fns)
        
        % first convert 4D file to a series of 3D files
        fprintf('Splitting ''%s'' ...',fmri_fns{f})
        Vo = spm_file_split(fullfile(fmri_pth,fmri_fns{f}),TMPdir);
        fprintf(' done\n')
        
        matlabbatch = cell(size(Vo));
        Vout = cell(size(Vo));
        k = 1;
        for v = 1:length(Vo)
            C.input{1,1} = Vo(v).fname;
            [p,n,~]= fileparts(Vo(v).fname);
            Vout{v} = fullfile(p,['m' n '.nii']);
            C.output = Vout{v};
            
            matlabbatch{k}.spm.util.imcalc = C;
            k = k + 1;
        end
        
        fprintf('Masking ''%s'' ...',fmri_fns{f})
        spm_jobman('run',matlabbatch);
        fprintf(' done\n')
        
        masked_files{f} = ['m' fmri_fns{f}];
        
        spm_file_merge(Vout,fullfile(fmri_pth,'MASKED',masked_files{f}));
        
        fprintf('Deleting temporary files ...')
        delete([TMPdir '\*.nii'])
        fprintf(' done\n')
    end
    rmdir(TMPdir);
    
catch me
    delete([TMPdir '\*.nii']);
    rmdir(TMPdir);
    rethrow(me);
    
end




