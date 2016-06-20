%% Prepare Psychtoolbox
Screen('Preference', 'SkipSyncTests', 0);

PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32Bit');
PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'ClampOnly'); 
PsychImaging('AddTask', 'General', 'EnableBits++Mono++Output');

ScreenNum = max(Screen('Screens'));
% ScreenNum = 1;

window = PsychImaging('OpenWindow',ScreenNum,0.5);

Priority(1);

rc = PsychGPUControl('SetGPUPerformance',10);

frameRate = Screen('FrameRate',window);

highTime = 1; % ms; time to be high in the beginning of the frame (in 100 us steps = 0.1 ms steps)
lowTime = 24.8-highTime; % followed by x msec low (enough to fill the rest of the frame high + low = 24.8 ms)
repetitions = 5;

dat = [repmat(bin2dec('10000000000'),1,highTime*10) zeros(1,lowTime*10)];


c = gray(repetitions);

for i = 1:repetitions
    BitsPlusPlus('DIOCommand', window, 1, 2047, dat, 0, 2, 1);
    Screen('Flip',window);

    Screen('FillRect',window, c(i,:), [0 0 100 100]);
    Screen('Flip',window);
    

    WaitSecs(1);
end
%
sca