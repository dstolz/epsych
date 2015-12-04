function C = TrialFcn_CheckerFlip(C)
% C = TrialFcn_CheckerFlip(C)
%
% Flip checkerboard pattern.
%
% Uses the Psychtoolbox
%
% Daniel.Stolzberg@gmail.com 2015


persistent win w ScreenRect black white vbl




if C.tidx == 1
%     Screen('Preference','SkipSyncTests', true);
    
    win = 3;
    w = Screen('OpenWindow',win, 128);
    ScreenRect=Screen('Rect',w);

    black = BlackIndex(w);
    white = WhiteIndex(w);
    
    vbl = [];
end

if C.FINISHED || C.HALTED
    Screen('CloseAll');
    return
end



% Create a new chckerboard based on the current stimulus parameters
numChks = SelectTrial(C,'Stim.NumCheckers');

chksize = round(ScreenRect(3)/(numChks*2));

% Reverse the checkerboard on each presentation
if mod(C.tidx,2)
    chk = [ones(chksize,'uint8') zeros(chksize,'uint8')];
else
    chk = [zeros(chksize,'uint8') ones(chksize,'uint8')];
end

Check = repmat([chk; fliplr(chk)],numChks,numChks);

Check = Check * white;
Check(~Check) = Check(~Check) * black;

CheckTex = Screen('MakeTexture',w,Check);



if numel(C.OPTIONS.ISI) == 2
    ISI = round(C.OPTIONS.ISI(1)+diff(C.OPTIONS.ISI)*rand(1))/1000;
else
    ISI = C.OPTIONS.ISI/1000;
end

% Show the checker board with a photodiode marker
Screen('DrawTexture',w,CheckTex);
PhotodiodeMarker(w,true);

% this sets the inter-trigger-interval since it is using OperationalTrigger
% mode.
vbl = Screen('Flip',w,vbl + ISI - 0.007); % -0.007 is an empirically derived offset value


% Maintain the checkerboard and turn off photodiode marker
% ... for some reason, the 'dontclear' flag is not working in
% Screen('Flip', ...), so just redraw the same checker board
Screen('DrawTexture',w,CheckTex);
PhotodiodeMarker(w,false);
Screen('Flip',w,vbl+0.1);












