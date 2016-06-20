% Demonstrate use of Bits# digital output lines using PTB-3
% whichScreen=max(Screen('Screens'));
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32Bit');
PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'ClampOnly'); 
PsychImaging('AddTask', 'General', 'EnableBits++Mono++Output');
[window, screenRect] = PsychImaging('OpenWindow', whichScreen, 0.5, [], 32, 2);
frameRate=Screen('NominalFrameRate', window);

highTime = 1.0; % time to be high in the beginning of the frame (in 100 us steps = 0.1 ms steps)
lowTime = 24.8-highTime; % followed by x msec low (enough to fill the rest of the frame high + low = 24.8 ms)

% Prepare data packets for trigering on the digital outputs (the bits are
% in the order: TRIG OUT, DOUT9, DOUT8, DOUT7, DOUT6, DOUT5, DOUT4, DOUT3,
% DOUT2, DOUT1, DOUT0)
% This example will output 0.2 ms pulses on the TRIG OUT BNC and DOUT0 on
% the DB25 connector at the same time
dat = [repmat(bin2dec('10000000001'),highTime*10,1);repmat(bin2dec('00000000000'),lowTime*10,1)]';

% Run for 3 seconds (minus 1 frame) with a uniform grey screen before triggering
disp(['showing ',num2str(3*frameRate),' grey frames'])
for i=1:(3*frameRate)-1,
    Screen('Flip', window);
end

% Load the trigger on the last grey frame
% Output a trigger pulse train with one trigger for each frame of the white
% patch.
% Use mask 2047 to set all available outputs
% Use command 0 for regular trigger mode
% Note that the DIOCommand defaults to outputing the Data Packet on the
% third video line. This video line is blanked to black by Bits# by default
% when the Data Packet is detected.
BitsPlusPlus('DIOCommand', window, (3*frameRate), 2047, dat, 0);
Screen('Flip', window);

% Show a white patch at the same time as the trigger.
% Show it on the top left of the screen as this is updated first.
% Display patch for 3 seconds
% Note that the blanked Data Packet line will be visible in this example;
% this is deliberate to show when the Data Packet is being processed.
disp(['showing ',num2str(3*frameRate),' frames with white patch with a trigger at the beginning of each frame'])
for i=1:(3*frameRate),
    Screen('FillRect',window, 1, [0 0 200 200]);
    Screen('Flip', window);
end

% Revert to grey uniform screen for 3 seconds
disp(['showing ',num2str(3*frameRate),' grey frames'])
for i=1:(3*frameRate)-1,
    Screen('Flip', window);
end

% close all windows
sca;
