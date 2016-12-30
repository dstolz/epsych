function x = pollFastrak_InTrial2(s,FZero)
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
        x = zeros(1,10);
    else
        x = fscanf(s,'%f',47);
        if length(x) < 7
            x = zeros(1,10);
        end
        x = [1 c(4:6) x(5:7)' x(2:4)'];
        x(5) = x(5) - FZero(5);
        x(6) = x(6) - FZero(6);
        x(8) = x(8) - FZero(8);
        x(9) = x(9) - FZero(9);
        x = correctAzi_1D(x);
    end
catch
    disp('pollFastrak Error')
end
