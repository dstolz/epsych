function Pout = MySPM_BatchMasking2(P,Pm)
% Pout = MySPM_BatchMasking2(P,Pm)
% 
% Input:
%   P  ...  Path(s) to NIfTI files in a cell array
%   Pm ...  Path to one mask file
%
% Output:
%   Pout    ...     Resulting masked images prefixed with 'm'
% 
% NOTE: If this function does not work for 4D files, then you may have to
% modify spm_imcalc to allow for multivolume NIfTI files
%
% Daniel.Stolzberg@gmail.com 2016

P = cellstr(P);
for i = 1:length(P)
    [pth,nam,ext,~] = spm_fileparts(P{i});
    P{i} = fullfile(pth,[nam ext]);
end
P = spm_select('expand',P);

Pout = cell(size(P));


Vm = spm_vol(Pm);


% fmask = -1;
finterp = -5;

fprintf('Reading information from %d volumes ...',numel(P))
Vi = spm_vol(P);
fprintf(' done\n')

F = spm_figure('FindWin','Interactive');
if isempty(F)
    F = spm_figure('Create','Interactive','SPM','on');
    set(F,'position',[108 045 400 395]);
end
spm_figure('Focus',F);
spm_progress_bar('Init',numel(Vi),'masking','Volumes completed');
tic
for i = 1:numel(Vi)
    Vo = DoTheMasking(Vi{i},Vm,finterp);
    Pout{i} = Vo.fname;
    spm_progress_bar('Set',i);
end
fprintf('Completed masking %d volumes in %0.1f minutes\n',numel(Vi),toc/60)



function Vo = DoTheMasking(Vi,Vm,finterp)
Vo = Vi;
Vo.fname = spm_file(Vo.fname,'prefix','m');

Yo = zeros(Vo.dim(1:3),'single');


for p = 1:Vo.dim(3)
    B = spm_matrix([0 0 -p 0 0 0 1 1 1]);
    
    % volume
    M = inv(B * inv(Vo.mat) * Vi.mat);
    Y = single(spm_slice_vol(Vi, M, Vo.dim(1:2), [finterp,NaN]));
    Y(isnan(Y)) = 0;
    
    % mask
    Mm = inv(B * inv(Vo.mat) * Vm.mat);
    Ym = single(spm_slice_vol(Vm, Mm, Vo.dim(1:2), [0,NaN]));
    Ym(isnan(Ym)) = 0;
%     if (fmask < 0), Ym(isnan(Ym)) = 0; end
%     if (fmask > 0) && ~spm_type(Vm.dt(1),'nanrep'), Ym(Ym==0)=NaN; end
    
    try
        Yp = Y.*Ym;
        
    catch
        l = lasterror;
        error('%s\nCan''t evaluate "%s".',l.message,f);
    end
    if prod(Vo.dim(1:2)) ~= numel(Yp)
        error(['"',f,'" produced incompatible image.']); end
    
%     Yp(isnan(Yp)) = 0;
    Yo(:,:,p) = reshape(Yp,Vo.dim(1:2));

end

Vo.dt = [16 0]; % single

Vo = spm_write_vol(Vo,Yo);







