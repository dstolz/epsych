function BitsTrigger(window,vbl)
% BitsTrigger(window,vbl)
%
% Sets the Bits# trigger out (TrigOut) to send a 1 ms pulse on the next
% call to Screen('Flip',window,vbl).  Call this function just prior to the
% Screen('Flip',window) command that you actually want to synchronize with
% the external trigger.
%
% The first input, window, is the window handle returned by a call to
% 'OpenWindow':
%   ex: window = PsychImaging('OpenWindow',ScreenNum,0.5);
%
% The input, vbl, is the vbl timestamp that you would like the trigger to
% actually appear.  So this would be the same vbl value as you would have
% for your call: Screen('Flip',window,vbl)
%
% Daniel.Stolzberg@gmail.com 2016


persistent flipInterval dat

if isempty(flipInterval)
    frameRate = Screen('NominalFrameRate',window,1); 
    flipInterval = 1/frameRate;
end

if isempty(dat), dat = [repmat(1024,1,10) zeros(1,238)]; end % set 1 ms trigger data

BitsPlusPlus('DIOCommand', window, 1, 2047, dat, 0, 2, 1);
Screen('Flip',window,vbl-flipInterval);













