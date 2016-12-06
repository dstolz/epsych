



[x, y] = organizeData(Headtracker,Data);


%%Showing the azimuthal movements during each trial
%
x2 = x((x(:,2)==1),:);

for i = 1:length(y)
    x3 = x2((x2(:,1)==i),:);
    scatter(x3(:,4),x3(:,5),15);
    pause(0.5);
end


%Look at all trials on one plot
%
x2 = x((x(:,2)==1),:);

colorArray = jet(13);
for i = 1:length(y)
    if y(i,5)
        x3 = x2((x2(:,1)==i),:);
        switch x3(1,3)
            case -40
                dataColour = colorArray(1,:);
            case -25
                dataColour = colorArray(2,:);
            case -20
                dataColour = colorArray(3,:);
            case -15
                dataColour = colorArray(4,:);
            case -10
                dataColour = colorArray(5,:);
            case -5
                dataColour = colorArray(6,:);
            case 0
                dataColour = colorArray(7,:);
            case 5
                dataColour = colorArray(8,:);
            case 10
                dataColour = colorArray(9,:);
            case 15
                dataColour = colorArray(10,:);
            case 20
                dataColour = colorArray(11,:);
            case 25
                dataColour = colorArray(12,:);
            case 40
                dataColour = colorArray(13,:);
            otherwise
                dataColour = [0.5 0.5 0.5];
        end
        scatter((x3(:,4))-x3(1,4),x3(:,5),15,dataColour);
        hold on
    end
end


spkrIdx = [-40 -25 -20 -15 -10 -5 0 5 10 15 20 25 40];
for k = 1:13
    plot(linspace(0,1,200),(spkrIdx(k)*ones(1,200)),'.','MarkerFaceColor','k','MarkerEdgeColor','k')
end

ylim([-50 50]);
xlim([0 1]);

hold off


%%Same as above but with subplots
%
x2 = x((x(:,2)==1),:);

figure
colorArray = jet(13);
for i = 1:length(y)
    if y(i,5)
        x3 = x2((x2(:,1)==i),:);
        switch x3(1,3)
            case -40
                dataColour = colorArray(1,:);
                subplot(4,4,1);
                ylim([-50 50]);
                xlim([0 1]);
            case -25
                dataColour = colorArray(2,:);
                subplot(4,4,2);
                ylim([-50 50]);
                xlim([0 1]);
            case -20
                dataColour = colorArray(3,:);
                subplot(4,4,3);
                ylim([-50 50]);
                xlim([0 1]);
            case -15
                dataColour = colorArray(4,:);
                subplot(4,4,4);
                ylim([-50 50]);
                xlim([0 1]);
            case -10
                dataColour = colorArray(5,:);
                subplot(4,4,5);
                ylim([-50 50]);
                xlim([0 1]);
            case -5
                dataColour = colorArray(6,:);
                subplot(4,4,6);
                ylim([-50 50]);
                xlim([0 1]);
            case 0
                dataColour = colorArray(7,:);
                subplot(4,4,7);
                ylim([-50 50]);
                xlim([0 1]);
            case 5
                dataColour = colorArray(8,:);
                subplot(4,4,8);
                ylim([-50 50]);
                xlim([0 1]);
            case 10
                dataColour = colorArray(9,:);
                subplot(4,4,9);
                ylim([-50 50]);
                xlim([0 1]);
            case 15
                dataColour = colorArray(10,:);
                subplot(4,4,10);
                ylim([-50 50]);
                xlim([0 1]);
            case 20
                dataColour = colorArray(11,:);
                subplot(4,4,11);
                ylim([-50 50]);
                xlim([0 1]);
            case 25
                dataColour = colorArray(12,:);
                subplot(4,4,12);
                ylim([-50 50]);
                xlim([0 1]);
            case 40
                dataColour = colorArray(13,:);
                subplot(4,4,13);
                ylim([-50 50]);
                xlim([0 1]);
            otherwise
                dataColour = [0.5 0.5 0.5];
        end
        scatter((x3(:,4))-x3(1,4),x3(:,5),15,dataColour);
        hold on
    end
end


spkrIdx = [-40 -25 -20 -15 -10 -5 0 5 10 15 20 25 40];
for k = 1:13
    subplot(4,4,k);
    plot(linspace(0,1,200),(spkrIdx(k)*ones(1,200)),'.','MarkerFaceColor','k','MarkerEdgeColor','k')
end

ylim([-50 50]);
xlim([0 1]);

hold off




