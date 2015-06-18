function Vq = nearest(X,Xq)
% Vq = nearest(X,Xq)
% 
% Convenient version of:
% Vq = interp1(X,1:length(X),Xq,'nearest','extrap');
% 
% DJS

Vq = interp1(X,1:length(X),Xq,'nearest','extrap');



