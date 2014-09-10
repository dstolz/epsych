function PhotodiodeMarker(win,seton)
% PhotodiodeMarker(win,seton)
%
% Simple helper function that sets up bottom-right corner of window (win)
% to activate a photodiode.  This function should be the last command
% called just before 'flipping' so it is on top.
% 
% If seton is true, then the bottom-right corner of the window will be
% prepped with a small black square with a white circle in the center.
% 
% If seton is false, then the bottom-right corner of the window will be
% prepped with a small black squre only.
% 
% A Screen('Flip',win) or similar command should be subsequently called to 
% actually update the window.
% 
% For use with Psychtoolbox
% 
% Daniel.Stolzberg@gmail.com 2014

persistent white black winRect

if isempty(white),   white = WhiteIndex(win);      end
if isempty(black),   black = BlackIndex(win);      end
if isempty(winRect), winRect = Screen('Rect',win); end

% draw a black square in bottom right of screen
Screen('FillRect',win,black,[winRect([3 4])-35 winRect([3 4])]);
if seton
    % draw a small white oval in center of black square
    Screen('FillOval',win,white,CenterRectOnPoint([0 0 30 30],winRect(3)-18,winRect(4)-18));
end