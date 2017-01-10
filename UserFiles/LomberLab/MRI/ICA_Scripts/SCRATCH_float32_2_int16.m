%%

P = 'H:\DataProcessing\PREPROC\DENOISED_DATA\wsrrmRSS_02.nii';
V = spm_vol(P);


Vd = V;

Yi = zeros([V(1).dim length(V)],'uint16');

% figure
for i = 1:length(V)
    fprintf('%d of %d\n',i,length(V))
    Y = spm_read_vols(V(i));
%     subplot(121)
%     imagesc(Y(:,:,40))
    
    Vd(i).fname = spm_file(V(i).fname,'prefix','d');
    Vd(i).dt(1) = 4;
    
    Y(Y<1) = 0;
    Yi(:,:,:,i) = uint16(Y/max(Y(:))*65535);

%     subplot(122)
%     imagesc(Yi(:,:,40,i));
%     drawnow
end


for i = 1:length(Vd)
    fprintf('Writing volume %d of %d\n',i,length(Vd))
    spm_write_vol(Vd(i),Yi(:,:,:,i));
end












