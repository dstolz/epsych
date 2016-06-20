%% Prepare Psychtoolbox

Screen('Preference', 'SkipSyncTests', 0);

PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32Bit');
PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'ClampOnly'); 
PsychImaging('AddTask', 'General', 'EnableBits++Mono++Output');

rc = PsychGPUControl('SetGPUPerformance',10);


Priority(1);

ScreenNum = max(Screen('Screens'));
% ScreenNum = 2;

window = PsychImaging('OpenWindow',ScreenNum,0.5);

frameRate=Screen('NominalFrameRate', window);

% Setup TrigOut for 1 ms pulse
highTime = 1.0; % ms; time to be high in the beginning of the frame (in 100 us steps = 0.1 ms steps)
lowTime = 24.8-highTime; % followed by x msec low (enough to fill the rest of the frame high + low = 24.8 ms)

% number of frames to present which should equal the number of triggers
% send out of the TrigOut BNC
repetitions = 1;

% data to write to Bits#
dat = [repmat(bin2dec('10000000000'),1,highTime*10) zeros(1,lowTime*10)];



nreps = 10;

% design sin grating and shift each time
textureID = zeros(1,nreps);
for i = 1:nreps
    sinGrating = sin(i+(0:199)/4);
    sinGrating = (sinGrating + 1)/2;
    sinGrating2D = repmat(sinGrating, 200, 1);
    % Make textures
    textureID(i) = Screen('MakeTexture', window, sinGrating2D, [], [], 2);
end


vbl = Screen('Flip',window);

vblTimings = vbl+(1:nreps);

vblR = zeros(1,nreps);

blankDat = zeros(1,248);


for i = 1:nreps

    
    % Setup trigger for next flip
    % NOTE: The DIOCommand must come exactly 1 frame before the intended
    % flip time of the actual stimulus.  Otherwise many triggers will be
    % presented. 
    BitsPlusPlus('DIOCommand', window, 1, bin2dec('10000000000'), dat, 0, 1, 2);
    Screen('Flip',window,vblTimings(i) - 1/frameRate); 

    % Present texture on screen
    % Draw texture
    Screen('DrawTexture',window,textureID(i));    
    vblR(i) = Screen('Flip',window,vblTimings(i));
    
    Screen('Close',textureID(i));
end

sca













