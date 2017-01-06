function auto_reorient(p)
if ~nargin
    [p,sts] = spm_select(Inf,'image');
    if ~sts, return; end
end
p = cellstr(p);
vg = spm_vol(fullfile(spm('Dir'),'canonical','avg152T1.nii'));
tmp = [tempname '.nii'];
for i=1:numel(p)
    spm_smooth(p{i},tmp,[12 12 12]);
    vf = spm_vol(tmp);
    M  = spm_affreg(vg,vf,struct('regtype','rigid'));
    [u,s,v] = svd(M(1:3,1:3));
    M(1:3,1:3) = u*v';
    N  = nifti(p{i});
    N.mat = M*N.mat;
    create(N);
end
spm_unlink(tmp);