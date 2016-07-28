%% CONN Pipeline
% Preprocess data using CONN toolbox according to a predefined parameters.
%
% Directory/file scheme:
% root dir: .\SUBJECTS\{Subject Name}\
% T1:                 .\{PROTOCOL}\mSUBJECTNAME_T1.nii
% T2*:                .\{PROTOCOL}\mSUBJECTNAME_PROTOCOL.nii
% FieldMap Phase:     .\COMMON\SUBJECTNAME_FM_01.nii
% FieldMap Mag:       .\COMMON\SUBJECTNAME_FM_02.nii
%
% optional "MRIstim" file:
%  .\SUBJECTS\{Subject Names}\{PROTOCOL}\SUBJECTNAME_PROTOCOL_01.mat
%
% Structural and functional scans should be masked and reoriented manually
% so that coronal section appears in top-left image in "Display" and the
% origin is placed at the anterior corpus collosum. Corpus
% collosum should be horizontal.
%
% All volumes should be scaled to twice original acquision resolution:
%     structurals acquired at 0.5x0.5x0.5 -> 1.0x1.0x1.0
%     functionals acquired at 1.0x1.0x1.0 -> 2.0x2.0x2.0
% This can be done using SPM's "Display" GUI on a T1 and then applied to
% all other structural and functional volumes.
%
% After running this script, begin the CONN preprocessing by calling:
%   >> conn_batch(C)
%
% See 'doc conn_batch' for syntax
%
% Daniel.Stolzberg@gmail.com 6/2016



[~,cdir] = fileparts(pwd);
if ~isequal(cdir,'CONN')
    cdir = uigetdir('Select CONN processing directory','CONN Preprocessing');
    cd(cdir)
end


d = dir('SUBJECTS');
d(ismember({d.name},{'.','..'})) = [];
d = dir(fullfile('SUBJECTS',d(1).name));
d(ismember({d.name},{'.','..','NII','VOI'})) = [];
dn = {d.name};
[s,v] = listdlg('PromptString','Select Protocol', ...
                'SelectionMode','single', ...
                'ListSTring',dn);
if ~v, return; end
PROTOCOL = dn{s};


%

clear C S

% C.parallel.N = 4;
% C.parallel.profile = 'Background process (Windows)';

C.name     = sprintf('%s (%s)',PROTOCOL,datestr(now));
C.filename = fullfile(pwd,sprintf('conn_%s_%s.mat',PROTOCOL,datestr(now,'yyyymmdd')));

S.isnew     = 1;
S.done      = 1;
S.overwrite = 1; % <--------------
S.RT        = 1; % TR
S.acquisitiontype = 1; % continuous

d = dir('SUBJECTS');
subjs = {d.name};
subjs(ismember(subjs,{'.','..'})) = [];


k = false(size(subjs));
for i = 1:length(subjs)
    if ~isdir(fullfile('SUBJECTS',subjs{i},PROTOCOL))
        fprintf(2,'\n\nNo Protocol ''%s'' for Subject ''%s''\n',PROTOCOL,subjs{i})
        k(i) = 1;
    end
end
subjs(k) = [];
S.nsubjects = length(subjs);
fprintf('\n\nProcessing %d subjects: ',S.nsubjects)
subjs

% structurals and functionals
for i = 1:length(subjs)
    fprintf('\n\nSubject: %s\n',subjs{i})
    
    
    sT1 = fullfile(pwd,'SUBJECTS',subjs{i},PROTOCOL,sprintf('m%s_T1.nii',subjs{i}));
    
    S.structurals{i} = sT1;
    fprintf('\tStructural: %s\n',S.structurals{i})
    V = spm_vol(S.structurals{i});
    % check for negative or nan data
    Vn = spm_vol(S.structurals{i});
    Yn = spm_read_vols(Vn);
    Yn(isnan(Yn)|Yn<0) = 0;
    spm_write_vol(Vn,Yn);
    clear Yn
    
    
    % ensure the structural voxel size is 1 mm isotropic
    vvoxsiz = getVoxelSize(Vn);
    fprintf('\t\tVoxel size: %s\n',mat2str(vvoxsiz,2))
%     if round(100*abs(vvoxsiz(1)))/100~=1
%         voxsiz = [1 1 1]; % new voxel size {mm}
%         fprintf(2,'\t\tAdjusting voxel sizes to: %s\n',mat2str(voxsiz)) %#ok<*PRTCAL>
%         bb        = spm_get_bbox(Vn);
%         %         VV(1:2)   = Vn;
%         %         VV(1).mat = spm_matrix([bb(1,:) 0 0 0 voxsiz])*spm_matrix([-1 -1 -1]);
%         %         VV(1).dim = ceil(VV(1).mat \ [bb(2,:) 1]' - 0.1)';
%         %         VV(1).dim = VV(1).dim(1:3);
%         %         spm_reslice(VV,struct('prefix','','mean',false,'which',5,'interp',0)); % 1 for linear
%         M = spm_matrix([bb(1,:) 0 0 0 voxsiz])*spm_matrix([-1 -1 -1]);
%         newdim = ceil(M \ [bb(2,:) 1]' - 0.1)';
%         spm_get_space(Vn.fname,M);
%         Vn.dim = newdim;
%         Vn.dim = newdim(1:3);
%     end
    
    d = ls(fullfile(pwd,'SUBJECTS',subjs{i},PROTOCOL,sprintf('m%s_%s*.nii',subjs{i},PROTOCOL)));
    d = cellstr(d);
    for j  = 1:length(d)
        S.functionals{i}{j} = fullfile(pwd,'SUBJECTS',subjs{i},PROTOCOL,d{j});
        fprintf('\tFunctional: %s\n',S.functionals{i}{j})

        
       
        Vn = spm_vol(S.functionals{i}{j});
        
        % check that orientations are all the same
        [sts,str] = spm_check_orientations(Vn,0);
        if ~sts 
            fprintf('\t > Failed orientation check.\n%s\nRealigning functional volumes ...',str)
            vnfn = cellfun(@(a,b) ([a ',' num2str(b)]),{Vn.fname},num2cell(1:length(Vn)),'uniformoutput',false);
            vnfn = char(vnfn(:));
            rflags.quality = 1;
            vsz = getVoxelSize(Vn(1));
            rflags.fwhm = 2*abs(vsz(1));
            rflags.sep  = abs(vsz(1));
            rflags.interp = 5;
            rflags.rtm = 1;
            spm('createintwin','on');
            spm_realign(vnfn,rflags);
        end
        
        
        
        
        % check for negative/spurious or nan data 
        Yn = spm_read_vols(Vn);
        ind = isnan(Yn)|Yn<1&Yn~=0;
        if nnz(ind)
            fprintf('\t\tCorrecting %d spurious voxels ...',nnz(ind))
            Yn(ind) = 0;
            for k = 1:length(Vn)
                % only bother writing affected volumes
                if ~any(ind(:,:,:,k)), continue; end
                spm_write_vol(Vn(k),Yn(:,:,:,k));
            end
            fprintf(' done\n')
        end
        vvoxsiz = getVoxelSize(Vn(1));
        fprintf('\t\tVoxel size: %s\n',mat2str(vvoxsiz,2))
%         if round(100*abs(vvoxsiz(1)))/100~=2
%             voxsiz = round(100*vvoxsiz*2)/100; % new voxel size {mm}
%             fprintf(2,'\t\tAdjusting voxel sizes to: %s\n',mat2str(voxsiz)) %#ok<*PRTCAL>
%             %             bb        = spm_get_bbox(Vn(1));
%             %             Vn(1).mat = spm_matrix([bb(1,:) 0 0 0 voxsiz])*spm_matrix([-1 -1 -1]);
%             %             Vn(1).dim = ceil(Vn(1).mat \ [bb(2,:) 1]' - 0.1)';
%             %             Vn(1).dim = Vn(1).dim(1:3);
%             %             spm_reslice(Vn,struct('prefix','','mean',false,'which',5,'interp',0)); % 1 for linear
%             %             M = spm_matrix(Vn(1));
% %             M = spm_matrix([bb(1,:) 0 0 0 voxsiz])*spm_matrix([-1 -1 -1]);
%             bb        = abs(voxsiz(1)/vvoxsiz(1))*spm_get_bbox(Vn(1));
% %             Mats = zeros(4,4,numel(Vn));
%             spm('createintwin','on');
% %             spm_progress_bar('Init',numel(Vn),'Reading current orientations',...
% %                 'Images Complete');
% %             for k=1:numel(Vn)
% %                 Mats(:,:,k) = spm_get_space(Vn(k).fname);
% %                 spm_progress_bar('Set',k);
% %             end
%             spm_progress_bar('Init',numel(Vn),'Reorienting images',...
%                 'Images Complete');
%             M = spm_matrix([bb(1,:) 0 0 0 voxsiz])*spm_matrix([-1 -1 -1]);
%             newdim = ceil(M \ [bb(2,:) 1]' - 0.1)';
%             for k=1:numel(Vn)
%                 spm_get_space(Vn(k).fname,M);
%                 Vn(k).dim = newdim;
%                 Vn(k).dim = newdim(1:3);
%                 spm_progress_bar('Set',k);
%             end
%             spm_progress_bar('Clear');
%         end
        clear Vn Yn
        V(end+1) = spm_vol([S.functionals{i}{j} ',1']);
        
        

    end
    
%     % check for fieldmap files to generate vdm file
%     dphase = fullfile(pwd,'SUBJECTS',subjs{i},'COMMON',sprintf('%s_FM_PHASE.nii',subjs{i}));
%     if exist(dphase,'file')
%         dmag   = fullfile(pwd,'SUBJECTS',subjs{i},'COMMON',sprintf('%s_FM_MAG.nii',subjs{i}));
%         fprintf('%s Phase File: %s\n',subjs{i},dphase)
%         if ~exist(dmag,'file')
%             error(sprintf('Phase file found, but no Magnitude File for %s ?????',dmag))
%         end
%         fprintf('%s Magnitude File: %s\n',subjs{i},dmag)
%         
%         fmflags.iformat = 'PM';
%         fmflags.method  = 'Mark3D'; % needs testing
%         fmflags.fwhm    = 4; 
%         fmflags.etd     = 17.82; %??????
%         fmv = spm_vol(fullfile(pwd,'FMbrainmask.nii'));
%         fmflags.bmask   = spm_read_vols(fmv);
%         
%         
%         fm = pm_make_fieldmap({dphase,dmag},fmflags);
%     else
%         fprintf('\tNo FieldMap Phase file for %s\n',subjs{i})
%     end
    
    spm_check_registration(V);
   
    pause(1)
    
    
%     % optional conditon files
%     cfiles = cellstr(ls(fullfile(pwd,'SUBJECTS',subjs{i},PROTOCOL, ...
%         sprintf('%s_%s_*.mat',subjs{i},PROTOCOL))));
%     
%     if isempty(cfiles{1}) % assume only rest condition
%         fprintf('\nNo Stimulus Set file found for %s\n\tUsing rest condition only\n',subjs{i})
%         
        S.conditions.names = {'rest'};
        for j = 1:length(S.functionals{i}) % sessions
            % rest condition
            S.conditions.onsets{1}{i}{j}    = 0;
            S.conditions.durations{1}{i}{j} = inf;
        end
%         
%     else % THIS NEEDS MORE WORK
%         for j = 1:length(cfiles)
%             cf = fullfile(pwd,'SUBJECTS',subjs{i},PROTOCOL,cfiles{j});
%             fprintf('\nUsing Stimulus Set file: %s\n',cf)
%             
%             
%             fcond = load(cf);
%             V = fcond.DATA.VALS;
%             F = fcond.DATA.STIMS([V.StimsInUse]);
%             
%             S.conditions.names = {F.name};
%             if V.IncludeRests
%                 S.conditions.names = [{'rest'} S.conditions.names];
%                 ind = V.TrigHistory(:,1) == 0;
%                 cidx = findConsecutive(ind);
%                 S.conditions.onsets{1}{i}{j}    = cidx(1,:) - 1;
%                 S.conditions.durations{1}{i}{j} = diff(cidx);
%             end
%             
%             for k = 1:length(F)
%                 ind = V.TrigHistory(:,1) == k;
%                 cidx = findConsecutive(ind);
%                 S.conditions.onsets{k+V.IncludeRests}{i}{j}    = cidx(1,:) - 1;
%                 S.conditions.durations{k+V.IncludeRests}{i}{j} = diff(cidx);
%             end
%             
%             for k = 1:length(S.conditions.names)
%                 fprintf('\t''%s''\n',S.conditions.names)
%                 S.conditions.onsets{k}{i}{j}
%                 S.conditions.durations{k}{i}{j}
%             end
%             
%         end        
%     end
end


%
% conditions - manual specification here, but ultimately load from file
% S.conditions.names = {'rest',PROTOCOL};
% S.conditions.onsets{1}{1}{1} = 0:180:720;  S.conditions.durations{1}{1}{1} = 30;
% S.conditions.onsets{1}{2}{1} = 0:60:360;   S.conditions.durations{1}{2}{1} = 30;
% S.conditions.onsets{1}{3}{1} = 0:60:360;   S.conditions.durations{1}{3}{1} = 30;
% 
% S.conditions.onsets{2}{1}{1} = 30:180:570; S.conditions.durations{2}{1}{1} = 30;
% S.conditions.onsets{2}{2}{1} = 30:60:330;  S.conditions.durations{2}{2}{1} = 30;
% S.conditions.onsets{2}{3}{1} = 30:60:330;  S.conditions.durations{2}{3}{1} = 30;



S.analyses        = 1:4; % all analyses
S.voxelmask       = 1;  % 1: Explicit mask (brainmask.nii)
S.voxelmaskfile   = 'D:\DataProcessing\CONN\brainmask.nii'; % cat brain mask from cat TPM
S.voxelresolution = 2; % 1: Volume-based template (SPM; default 2mm isotropic or same as explicit mask if specified); 

C.Setup = S;

P.steps = {'functional_realign&unwarp', ...
           'structural_segment&normalize', ... 
           'functional_coregister', ...
           'functional_art', ...
           'functional_smooth'}; 
       %           'functional_normalize', ... % see P.applytofunctional
       
P.voxelsize     = 2; % remember that voxels are twice the original
P.boundingbox   = 2*[-25 -50 -30; 25 25 20]; % 2*bounding box for 0.5 mm3 -> 1.0 mm3 voxels
P.fwhm          = 5; % remember that voxels are twice the original
P.coregtomean   = 1; % use mean; must do realignment preprocessing step first
P.applytofunctional = 1; % use normalization warp from structural on functional (0 if using functional_normalize)
P.art_thresholds = [3 0.5]; % conservative threshold

% % These files are left as defaults, but replaced with corresponding cat
% % templates/TPM files 
% P.template_structural
% P.template_functional
% P.tpm_template    
% P.tpm_ngaus

C.Setup.preprocessing = P;


% conn_batch(C);


%%  Denoising
D.done          = 1;
D.overwrite     = 1;
D.filter        = [0.008 0.09]; % [low-freq high-freq] cutoffs
D.detrending    = 1; % linear
D.regbp         = 2; % simultaneous filtering with regression
D.confounds = {'White Matter','CSF'}; 

C.Denoising = D;


%% Analyses
A.done              = 1;
A.overwrite         = 1;
A.analysis_number = 'first_analysis';

% roi-to-roi & seed-to-voxel
A.measure       = 1; % bivariate correlation
A.weight        = 2; % 1: none; 2: hrf; 3: hanning
A.modulation    = 0; % standard weighted GLM analysis
A.type          = 3; % all

% voxel-to-voxel


C.Analysis = A;








            















