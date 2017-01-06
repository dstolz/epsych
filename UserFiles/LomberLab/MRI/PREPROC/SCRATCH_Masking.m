%% 4A Clean up mask

P = spm_select(1,'image','Select T1...');
if isempty(P), return; end
Pm = spm_select(1,'image','Select Mask...',{},fullfile(fileparts(P),'VOI'));

Po = MySPM_BatchMasking2(P,Pm);

% Try to do some additional cleanup on the mask
V = spm_vol(char(Po));
Y = spm_read_vols(V);

Yf = logical(entropyfilt(Y,true(3,3,3)));
Yf = Yf|logical(entropyfilt(Y,true(1,3,1)));
Yf = Yf|logical(entropyfilt(Y,true(3,1,1)));
Yf = Yf|logical(entropyfilt(Y,true(1,1,3)));

Y(Yf) = 0;

[pth,nam,ext,num] = spm_fileparts(Pm);
Vm = spm_vol(fullfile(pth,[nam ext]));
Ym = spm_read_vols(Vm);
Ym(Yf) = 0;
Vmn = Vm;
Vmn.fname = spm_file(Vm.fname,'prefix','n');
spm_write_vol(Vmn,Ym);

Vf = V;
Vf.fname = spm_file(Vf.fname,'prefix','f');
spm_write_vol(Vf,Yf);

Vn = V;
Vn.fname = spm_file(Vn.fname,'prefix','n');
spm_write_vol(Vn,Y);

% 4B
spm_check_registration([spm_vol(P); V; Vn; Vmn]);

%% 4C Apply mask to all volumes of this subject

Proot = fileparts(fileparts(P));

D = rdir(fullfile(Proot,'**\*.nii'));
Pd = {D.name}';
i = cellfun(@(a) (strfind(a,'VOI')),Pd,'UniformOutput',false);
Pd(~cellfun(@isempty,i)) = [];
i = cellfun(@(a) (strfind(a,'FIELDMAPS')),Pd,'UniformOutput',false);
Pd(~cellfun(@isempty,i)) = [];

Po = MySPM_BatchMasking2(Pd,Vmn.fname);

