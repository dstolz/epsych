function done = timeout(nsecs)
% done = timeout([nsecs])
% 
% Helper function to implement a timeout in what might be an infinite loop.
%
% ex:
%       timeout(10); % initialize to 10 seconds
%       tic
%       while 1
%           % whatever code you want goes here
% 
%           if timeout, break; end % break loop when timeout returns true
% 
%           pause(0.001); % prevent system from locking up
%       end
%       toc
%       if timeout, disp('Loop timed out!'); end
%
% Daniel.Stolzberg@gmail.com 2015

persistent finishTime

if nargin == 1
    StartTime = clock;
    finishTime = [StartTime(1:end-1) StartTime(end) + nsecs];
    done = false;
    return
end

done = etime(clock,finishTime) >= 0;

