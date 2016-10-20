function done = timeout(nsecs)
% done = timeout([nsecs])
% 
% Helper function to implement a timeout in what might be an infinite loop.
%
% Note that the timeout is not exact and is dependent on how long it takes
% to run the code within the loop or other process.
%
% ex:
%       timeout(10); % initialize to 10 seconds
%       tic
%       while ~timeout
%           % whatever code you want goes here
% 
%           pause(0.001); % prevent system from locking up
%       end
%       toc
%       if timeout, disp('Loop timed out!'); end
%
% Daniel.Stolzberg@gmail.com 2015

% Copyright (C) 2016  Daniel Stolzberg, PhD

persistent finishTime

if nargin == 1
    StartTime = clock;
    finishTime = [StartTime(1:end-1) StartTime(end) + nsecs];
    done = false;
    return
end

done = etime(clock,finishTime) >= 0;

