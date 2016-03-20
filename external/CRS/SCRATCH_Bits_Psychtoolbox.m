%% Update Bits# mode
s1 = serial('COM5');
fopen(s1);

fprintf(s1,['#monoPlusPlus' 13]);

fclose(s1);
delete(s1);
clear s1


%%
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatPoint32BitIfPossible');
PsychImaging('AddTask', 'General', 'EnableBits++Mono++Output');
% PsychImaging('AddTask', 'General', 'EnableBits++Mono++OutputWithOverlay');

%% Use Psych toolbox with TriggerOut pulse
ScreenNum = 3;
windowHandle = PsychImaging('OpenWindow',ScreenNum,0.5);
% overlayWindowHandle = PsychImaging('GetOverlayWindow',windowHandle);

repetitions = 1;
data = ones(1,248);
mask = bin2dec('1000000000000000'); % 32768; TriggerOut on pin 16;
command = 0; % 0 tells hardware to output data on the Digital Output ports

BitsPlusPlus('DIOCommandReset', windowHandle);

BitsPlusPlus('DIOCommand', windowHandle, repetitions, mask, data, command,1,2);

%
sinGrating = sin((0:199)/4);
sinGrating = (sinGrating + 1)/2;
sinGrating2D = repmat(sinGrating, 200, 1);

% note: last value in the 'MakeTexture' command is set to 2 so that the
% texture is stored at 32 bits for maximum accuracy
textureID = Screen('MakeTexture', windowHandle, sinGrating2D, [], [], 2);

Screen('DrawTexture',windowHandle,textureID);

Screen('Flip',windowHandle);


WaitSecs(5);
sca


%%


