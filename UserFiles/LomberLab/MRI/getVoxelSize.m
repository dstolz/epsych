function vsz = getVoxelSize(VoP)
% vsz = getVoxelSize(V)
% vsz = getVoxelSize(P)
%
% DJS

if ischar(VoP), VoP = cellstr(VoP); end
if iscellstr(VoP), VoP = spm_vol(VoP{1}); end

m = spm_imatrix(VoP(1).mat);

vsz = m(7:9);