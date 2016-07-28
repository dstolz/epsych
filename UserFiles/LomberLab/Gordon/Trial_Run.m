%Function to output 1 if the desired area was looked at for the
%predetermined period of time, and 0 otherwise. 
function X = Trial_Run(TestValue, s)

f = findFigure('Fastrak','color','w');

%set(gca,'xlim',[-5 5],'ylim',[-5 5],'zlim',[-5 5]);
axis([-5 5 -5 5 -5 5]);
axis manual;
grid(gca,'on');
view(3)

cla
h = line(nan,nan,nan);
set(h,'marker','^','markerfacecolor','b','linestyle','none')


X = 0;
flushinput(s);
fprintf(s,'c');
colours = jet(11);
%
record = zeros(1e6,7);
j  = 0;
for i = 1:size(record,1)

    
    fprintf(s,'P');
    while s.BytesAvailable < 47
%         fprintf('*** BytesAvailable = %d\n',s.BytesAvailable)
        pause(0.001)
    end
    
    x = fscanf(s,'%f');
    
    record(i,:) = x;    
    
    xdir = sind(record(i,5));
    ydir = cosd(record(i,5));
    zdir = sind(record(i,6));

    quiver3(0, 0, 0, xdir, ydir, zdir);
    udir = sind(record(i,5))*cosd(record(i,6));
    vdir = sind(record(i,6));
    
    axis([-2 2 -2 2 -2 2]);
    
    if (record(i,6) >= -15) && (record(i,6) <= 15)
        if (record(i,5) >= -90) && (record(i,5) < -75)
            set(gca,'Color',colours(1,:));
            [j,k] = checkDuration(1);
        elseif (record(i,5) >= -75) && (record(i,5) < -60)
            set(gca,'Color',colours(2,:));
            [j,k] = checkDuration(2);
        elseif (record(i,5) >= -60) && (record(i,5) < -45)
            set(gca,'Color',colours(3,:));
            [j,k] = checkDuration(3);
        elseif (record(i,5) >= -45) && (record(i,5) < -30)
            set(gca,'Color',colours(4,:));
            [j,k] = checkDuration(4);
        elseif (record(i,5) >= -30) && (record(i,5) < -15)
            set(gca,'Color',colours(5,:));
            [j,k] = checkDuration(5);
        elseif (record(i,5) >= -15) && (record(i,5) < 15)
            set(gca,'Color',colours(6,:));
            [j,k] = checkDuration(6);
        elseif (record(i,5) >= 15) && (record(i,5) < 30)
            set(gca,'Color',colours(7,:));
            [j,k] = checkDuration(7);
        elseif (record(i,5) >= 30) && (record(i,5) < 45)
            set(gca,'Color',colours(8,:));
            [j,k] = checkDuration(8);
        elseif (record(i,5) >= 45) && (record(i,5) < 60)
            set(gca,'Color',colours(9,:));
            [j,k] = checkDuration(9);
        elseif (record(i,5) >= 60) && (record(i,5) < 75)
            set(gca,'Color',colours(10,:));
            [j,k] = checkDuration(10);
        elseif (record(i,5) >= 75) && (record(i,5) < 90)
            set(gca,'Color',colours(11,:));
            [j,k] = checkDuration(11);
        else
            set(gca,'Color',[0 0 0]);
        end
    else
        set(gca,'Color',[0 0 0]);
        j = 0;
        k = 0;
    end
    
    fprintf('%s: ',datestr(now,'HH:MM:SS.FFF'))
    fprintf('%6.2f\t',record(i,2:end),'/t',k)
    fprintf('\n')
    
    if (j == 1)
        if (k == TestValue)
            X = 1;
        end
        break
    end
    
    pause(0.05)
    
end



end