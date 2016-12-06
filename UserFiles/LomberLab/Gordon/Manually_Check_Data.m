



[x, y] = organizeData(Headtracker,Data);


%%Showing the azimuthal movements during each trial
%
x2 = x((x(:,2)==1),:);

for i = 1:130
    x3 = x2((x2(:,1)==i),:);
    scatter(x3(:,4),x3(:,5),15);
    pause(0.5);
end


%Look at all trials of different angles
%
% x2 = x((x(:,2)==1),:);
% 
% for i = 1:130
%     x3 = x2((x2(:,1)==i),:);
%     scatter(x3(:,4),x3(:,5),15);
%     pause(0.5);
% end