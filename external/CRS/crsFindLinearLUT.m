function [err, graphics_card, GetVideoLine]  = crsFindLinearLUT(N,INIT,COMPORT)
%   [ERR, cLUT, VideoReceived] = crsFindLinearLUT(N,INIT,COMPORT)
%
%   crsFindLinearLUT determines an appropriate linear LUT to load into the
%   host GPU palette. This is required to ensure that pixel values are
%   transmitted to the CRS video device (Bits# / Display++) without being
%   changed. Changes will result if the host GPU palette is non-linear, or
%   when temporal dithering is being applied by the host GP driver
%
%   ERR = crsFindLinearLUT returns a 1000-by-1 vector of error values by
%   inspecting the output from the graphics card.
%
%   The error correction is implemented by sending a 256 pixel test
%   stimulus to the input of the graphics card and comparing it with the
%   actual output received by the CRS video device.
%   The difference (ERR) is used to calculate a colour look-up-table (cLUT)
%   that inverts any distorsion from the expected output. Since the
%   distorsion can change in time (due the temporal dithering implemented
%   by the driver or GPU of the host graphics card) the correction
%   calculation is done several times - each time correcting the cLUT by a
%   fraction of the error to average out the temporal effects.
%
%   ERR = crsFindLinearLUT(N) sets the number iterations to run after the
%   error has reached zero (default is 200). Make sure this number is high
%   enough to fully correct for temporal dithering.
%
%   ERR = crsFindLinearLUT(N,INIT) sets the ID of the initial condition of
%   the host GPU palette:
%
%   INIT = 1 - use linear cLUT from 0.05 to 0.95
%   INIT = 2 - use a linear cLUT from 0 to 1
%   INIT = 3 - load current cLUT and improve that
%   INIT = 4 - use a linear cLUT with added random noise
%   INIT = 5 - load cLUT preset to Mac Mini with ATI Radeon HD 6630M
%   INIT = 6 - load cLUT preset to AMD HD 7770 card and sample every 20th
%   video line (takes a while to complete)
%   INIT = 7 - load current cLUT, improve that and use EVERY active video
%   line (takes a long time to complete!)
%
%   Default is INIT = 1.
%
%   ERR = crsFindLinearLUT(N,INIT,COMPORT) also sets the address of the
%   Bits# or Display++ USB CDC virtual serial port (the default is to use
%   the address returned from the function CRSfindSerialPort.m)
%
%   [ERR,cLUT,VideoReceived] = crsFindLinearLUT(N,INIT,COMPORT) returns the
%   calculated linear cLUT in the vector cLUT; VideoReceived provides video
%   data returned by the CRS video device when this cLUT is loaded into the
%   host GPU palette
%
%   Uses crsFindSerialPort.m, Psychtoolbox (PTB-3) and Bits# or Display++
%
%   See also crsFindSerialPort
%
% History:
% 2011/11 CA/EW
% 2013/02 JT
% 2014/07 JT/SRE

Screen('Preference', 'SkipSyncTests', 1);

maxiterations = 1000; % maximum allowed iterations before breaking the loop
errCorrFactor = 0.03; % amount of correction done for each iteration
videoLinesToUse = 1;  % defines the video lines to use. Counted from the top.
videoLineOffset = 0;  % horizontal start position
buffsize = maxiterations;

% Number of iterations to run after the error has reached zero. It is
% recommended to use at least 200 to account for temporal dithering.
if nargin==0,
    N = 200;
end

% set the initial condition if not given.
if nargin<2,
    INIT = 1;
end

% find the virtual serial port address.
if nargin<3,
    disp('No serial port address given. Will now try to find the port address using crsFindSerialPort.m....');
    if exist('crsFindSerialPort','file')~=2,
        error('The script crsFindSerialPort.m is not on the MATLAB path');
    end
    DEVICE = 'Bits#';
    try
        disp('Look for Bits#');
        COMPORT = crsFindSerialPort(DEVICE);
        disp(['Found Bits# on port: ',COMPORT]);
    catch ME
        disp('Bits# not found. Look for Display++');
        try
            DEVICE = 'Display++';
            COMPORT = crsFindSerialPort(DEVICE);
            disp(['Found Display++ on port: ',COMPORT]);
        catch ME
            disp('No Bits# or Display++ found. Make sure  USB CDC mode is enabled in the device config.xml file');
            rethrow(ME);
        end
        rethrow(ME);
    end
end

s1 = serial(COMPORT);

% Make buffer size big enough to hold the pixel values. Maximum size for
% 256 pixel values are 14+4*3*(256+maxoffset). if max offset=500 then = 9086.
s1.InputBufferSize = 16384;

% Open the port for communication and set it to BitsPlusPlus mode (note the
% '13' indicates a carridge return (/n) and should be included at the end
% of all input commands to Bits#)
try
    
    fopen(s1);
    
    % Enumerate the screens connected to the computer's graphics card and
    % choose the one with the highest index. If you have two screens connected,
    % the Screen('Screens') functions will return [1,2]. So, unless you alter
    % this line, you must ensure that screen 2 is the Bits#/stimulus screen.
    whichScreen=max(Screen('Screens'));
    
    % Open window on selected screen for working with.
    [window,rect] = Screen('OpenWindow', whichScreen, 128, [], 32, 2);
    
    % Make the test stimulus. A simple linear ramp ranging from 0 (black) to
    % white (255), with one pixel per level.
    eight_bit_ramp = repmat(linspace(0,255,256)',[1 3 rect(4)]);
    eight_bit_ramp_texture = permute(eight_bit_ramp,[3 1 2]);
    
    % Create texture for stimulus, ready to draw to the window
    myTex = Screen('MakeTexture', window, eight_bit_ramp_texture);
    
    % Set initial status of the cLUT to load into the host GPU palette
    if INIT==1,
        % On some graphics cards (e.g. Intel) the last entry must be below
        % one but will not be adjusted to that automatically.
        graphics_card = repmat(linspace(.05,.95,256)',1,3); % start with a 0.05-0.95 linear LUT
    elseif INIT==2,
        graphics_card = repmat(linspace(0,1,256)',1,3); % start with a new linear LUT
    elseif INIT==3,
        graphics_card = LoadIdentityClut(window); % use original and improve that
        pause(1);
    elseif INIT==4,
        graphics_card = repmat(linspace(0,1,256)'+(rand(1,256)-0.5)'*(2/512),1,3); % with random noise (for testing)
        graphics_card(1,:)=0;
        graphics_card(256,:)=1;
    elseif INIT==5,
        % this one works without modification for Mac Mini OS 10.8 with ATI Radeon HD 6630M
        corr = zeros(256,1);
        corr(1:56) = 1/2^13;
        corr(192:256) = -1/2^13;
        graphics_card = repmat(linspace(0,1,256)'+corr,1,3);
    elseif INIT==6,
        % if INIT is 6 use every 20th active video line for correcting. NB. takes a while to complete
        videoLinesToUse = 1:20:rect(4); % defines the active video lines to sample.
        errCorrFactor = 0.3; % correct by 30 % per iteration - this only works if dithering is off.
        % this one should work on AMD Radeon HD 7700 Series on Windows 7
        graphics_card = repmat(linspace(0,1,256)',1,3);
        graphics_card(10:70,:) = graphics_card(10:70,:)+repmat(linspace(0.00086,0,61)',1,3);
        graphics_card(97:130,:) = graphics_card(97:130,:)+repmat(linspace(0.0005,0,34)',1,3);
        graphics_card(169:196,:) = graphics_card(169:196,:)+repmat(linspace(0.00039,0,28)',1,3);
    elseif INIT==7,
        % if INIT is 7 sample all active video lines. NB. takes a long time
        videoLinesToUse = 1:rect(4); % defines the video lines to use.
        errCorrFactor = 0.3; % correct by 30 % per iteration - this only works if dithering is off.
        graphics_card = LoadIdentityClut(window);
        pause(1);
    else
        error('INIT must be 1, 2, 3, 4, 5, 6 or 7');
    end
    
    % Loop through enough iterations to be confident that any dithering effects
    % will have been overcome. This can be determined by checking the final
    % error values, which should all be 0.
    err = nan(N,1); % preallocate for speed
    errCounter = 0; % how many iterations since last error
    
    KbName('UnifyKeyNames');
    escape = KbName('ESCAPE');
    KbReleaseWait;
    
    for i=1:maxiterations,
        % Load current cLUT to the computer's graphics card.
        Screen('LoadNormalizedGammaTable', window, graphics_card, 1);
        
        % Draw stimulus on all rows of the screen, although they might not all
        % be used
        Screen('DrawTexture', window, myTex, [], [videoLineOffset 0 videoLineOffset+256 rect(4)]);
        
        % Flip the windows so that the stimulus is visible on the screen
        Screen('Flip', window);
        
        % Get the pixel values for the 256 pixels of the specified rows of the
        % screen. This is where the stimulus was displayed and therefore if the
        % graphics card LUT is linear, these values should match the pixel
        % values inputted exactly
        for k=1:length(videoLinesToUse),
            fprintf('.');
            fprintf(s1, ['#GetVideoLine=[',num2str(videoLinesToUse(k)),',',num2str(videoLineOffset+256),']' 13]);
            pause(0.25);
            % Read the measured pixel values from Bits# input buffer. This will be
            % in the form of a string of values, separated by ';'s, indicating the
            % values of R;G;B;R;G;B;R;G;B... colour values for consecutive pixels.
            data = fscanf(s1);
            
            % fscanf always leaves 1 byte at the end, of a blank value, which
            % confuses subsequent calls, so clear it here but as it is an empty
            % point, it does not need to be saved
            fscanf(s1, '%c', 1);
            
            % The first 14 characters of the string are not RGB values. The first
            % digit relating to RGB values will be the 15th character. 'prev' is
            % the variable that will indicate the first digit of a pixel value.
            prev = 15;
            % parse the text to a matrix (starting after the wordy bit at the start)
            C = textscan(data(prev:end),'%d %d %d','Delimiter',';');
            GetVideoLine{k} = double(cell2mat(C));
            GetVideoLine{k} = GetVideoLine{k}(videoLineOffset+1:videoLineOffset+256,:);
        end
        disp(' ');
        disp('Finished sampling the requested number of active video lines. Will now calculate a correction cLUT');
        
        % Caluculate the sum of errors between the input and output pixel
        % values of the graphics card
        for k=1:length(videoLinesToUse),
            err(i,k) = sum(sum(abs(squeeze(eight_bit_ramp(:,:,1))-GetVideoLine{k})));
        end
        
        if sum(err(i,:))==0,
            errCounter = errCounter+1;
            if errCounter>=N,
                disp('Reached the requred amount of samples with zero error');
                break;
            end
        else
            errCounter = 0;
        end
        % Draw a figure showing the error and update every 5th iteration.
        if length(videoLinesToUse)<5,
            modplot = 5;
        else
            modplot = 1;
        end
        if i == 1 || mod(i,modplot) == 0,
            if i==1, h = figure('Name','Diagnostics - prees Esc to Exit and save LUT','position',[20 70 900 500]); end
            figure(h);
            subplot(5,2,[2 4 6 8])
            plot(sum(err,2), 'b+');
            ylim([min(sum(err,2))-.0005 max(sum(err,2))+.0005])
            title([num2str(errCounter),' of ',num2str(N),' (',...
                num2str(floor(errCounter/N*100)),'%) current error:',num2str(sum(err(i,:)))]);
            ylabel('sum of errors'); xlabel('iteration');
            subplot(5,2,10)
            plot(squeeze(eight_bit_ramp(:,:,1))-GetVideoLine{1}); % only shows the first line
            ylabel('Error'); xlabel('cLUT position');
            xlim([0 256])
            subplot(5,2,1:2:9), plot(graphics_card);
            xlim([0 256]);
            title('current cLUT');
        end
        
        % Returns the new LUT to load to the graphics card. cLUTColumn is a
        % separate function (see further below on this script).
        % Input arguments: graphics_card is the old cLUT, eight_bit_ramp is the
        % inputted values, GetVideoLine is the recorded values.
        graphics_card = cLUTColumn(graphics_card, eight_bit_ramp, GetVideoLine,errCorrFactor);
        
        [isdown, secs, keyCode] = KbCheck; %#ok<*ASGLU>
        if isdown
            if keyCode(escape)
                break;
            end
            KbReleaseWait;
        end
    end
    if i==maxiterations,
        disp('Reached the maximum number of iterations. Try to increase maxiterations');
    end
    % Once the loop has finished and we have a new cLUT with adjusted values
    % such that displayed values are the same as values inputted, save this
    % cLUT to the computer's graphics card.
    SaveIdentityClut(window, graphics_card);
    
    % Restore the screen to MonoPlusPlus mode as it will currently display the
    % status screen, and so changing it here saves the user from having to do
    % so manually.
    fprintf(s1, ['#monoPlusPlus' 13]);
    
    % Close communication with the serial port connection.
    fclose(s1);
    
    % Close all windows and textures.
    Screen('CloseAll')
    
catch ME
    fclose(s1);
    rethrow(ME);
end

    function graphics_card = cLUTColumn(previous_graphics_card, eight_bit_ramp, GetVideoLine,errCorrFactor)
        
        % Calculate error between the input values and returned values then convert the
        % error relative to the range of 0-1 (from 0 - 255)
        for u=1:size(GetVideoLine,2),
            ERROR(:,:,u) = (GetVideoLine{u} - squeeze(eight_bit_ramp(:,:,1))) .* (1/255);
        end
        ERROR = mean(ERROR,3);
        
        % Adjust the current cLUT by the error amount but lowered by a factor
        % of 0.03 to average out any temporal dithering. Assign the adjusted
        % cLUT to be used on next iteration.
        graphics_card = previous_graphics_card - ERROR .*errCorrFactor;
        
        % Make sure the values are in the valid range (0 - 1)
        graphics_card(graphics_card > 1) = 1;
        graphics_card(graphics_card < 0) = 0;
        
    end
end