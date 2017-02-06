function x = pollFastrak3(s,FZero,state)
% x = pollFastrak3(s)
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
        x = zeros(1,10);
    else
        x = fscanf(s,'%f',47);
        if length(x) < 7
            x = zeros(1,10);
        end
        x = [state c(4:6) x(5:7)' x(2:4)'];
        x(5:9) = x(5:9) - FZero(5:9);
        x = correctAzi_1D(x);
        x(5) = x(5)/1.3;
    end
catch
    disp('pollFastrak Error')
end

