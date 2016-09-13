function x = pollFastrak(s,Azi,Ele)
% x = pollFastrak(s)
%
% 
% See also startFastrak, endFastrak
%
% Steven Gordon 2016

timeOut = 2;

flushinput(s);
fprintf(s,'P');

noData = 0;
c = clock;
while s.BytesAvailable < 47
    %         fprintf('*** BytesAvailable = %d\n',s.BytesAvailable)
    noData = etime(clock,c) >= timeOut;
    if noData, break; end
    pause(0.001)
end

if noData
    x = nan(1,7);
else
    x = fscanf(s,'%f'); 
    x(5) = x(5) - Azi;
    x(6) = x(6) - Ele;
end

