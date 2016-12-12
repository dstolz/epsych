function x = pollFastrak_InTrial(s,Azi,Ele)
% x = pollFastrak(s)
%
% 
% See also startFastrak, endFastrak
%
% Stephen Gordon 2016

timeOut = 2;

flushinput(s);
fprintf(s,'P');
pause(0.01)
noData = 0;
c = clock;
while s.BytesAvailable < 47
    noData = etime(clock,c) >= timeOut;
    if noData, break; end
    pause(0.001)
end

try
    if noData
        x = zeros(1,7);
    else
        x = fscanf(s,'%f',47);
        if length(x) < 7
            x = zeros(1,7);
        end
        x = [1 c(4:6) x(5:7)'];
        x(5) = x(5) - Azi;
        x(6) = x(6) - Ele;
    end
catch
    disp('pollFastrak Error')
end
