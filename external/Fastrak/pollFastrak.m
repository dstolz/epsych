function x = pollFastrak(s)
% x = pollFastrak(s)
%
% 
% See also startFastrak, endFastrak
%
% Steven Gordon 2016

timeOut = 1;

fprintf(s,'P');

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
end

