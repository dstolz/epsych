%%
Vb= spm_vol(Pn{1});
Yb= spm_read_vols(Vb);

V = spm_vol(Dn{1});
Y = spm_read_vols(V);

x = 20:size(Y,1)-20;
y = 20:size(Y,2)-20;

colormap gray
% colormap jet


for i = 1:size(Y,3)
    
%     imagesc(Yb(x,y,i));
%     set(gca,'clim',[0 1e6]);
    
%     contour(Y(x,y,i),-6:0.5:6);
%     set(gca,'clim',[-6 6])
    
%      hold on
    [u,v,w] = surfnorm(Y(x,y,i));
    quiver(u,v,'autoscale','off','showarrowhead','on');
    hold off
    
    title(sprintf('Z frame %d',i))
    pause(0.05)
end
