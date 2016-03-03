function encodedDIOdata = BitsPlusDIO2Matrix(mask, data, command, goggle, DAC)
% encodedDIOdata = BitsPlusDIO2Matrix(mask, data, command [,goggle ,DAC]);
%
% Generates a Matlab matrix containing the magic code and data
% required to set the DIO port of CRS Bits++ box in Bits++ mode.
%
% 'mask', 'data', and 'command' have the same meaning as in the function
% 'bitsEncodeDIO.m'.
%
% This is a helper function, called by bitsEncodeDIO and
% BitsPlusDIO2Texture, as well as from BitsPlusPlus when used with the
% imaging pipeline. It takes parameters for controlling Bits++ DIO and
% generates the data matrix for the corresponding T-Lock control code. This
% matrix is then used by the respective calling routines to convert it into
% a texture, a framebuffer image, or whatever is appropriate.
%
% This is just to unify the actual T-Lock encoding process in one file, so
% we don't have to edit or fix multiple files if something changes...
%
% If the optional google and DAC parameters are used (for Bits#) both must
% be set.
%
%   DAC:
% The analogue output levels are set to be between -5 and +5 Volts for each
% of the two ports. E.g. dac = [3 -4]; for 3 Volts on port 1 and -4 Volts
% on port 2.
%   
%   goggle:
% controls the output on pin 3 and 5 on the TRIAD 01 circular goggle
% connector on the rear panel of the Bits#. E.g. goggle = [1 0]; for pin 3
% high and pin 5 low. The five pins on the connector are numbered
% increasing in counter-clock wise direction starting from the notch. For
% use with FE goggle the following applies:
%   pin 3   pin5    Left eye    Right eye
%   0       0       Open        Closed   
%   0       1       Closed      Closed
%   1       0       Closed      Open
%   1       1       Open        Open

% History:
% 12/10/2007 Written, derived from BitsPlusDIO2Texture. (MK)
% 06/02/2008 Fix handling of LSB of 'mask': bitand(mask,255) was missing,
%            which would cause wrong result if mask > 255. (MK)
% 04.04.2014 Added goggle, DAC and BNC port control for Bits#. (JT)

if nargin < 3
    error('Usage: encodedDIOdata = BitsPlusDIO2Matrix(mask, data, command)');
end


if nargin < 4,
    goggle = [];
    DAC = [];
end


% add goggle and DAC only if given as input parameter
if ~isempty(goggle) && ~isempty(DAC),
    
    % Prepare the data array - with space for goggle and DAC
    encodedDIOdata = uint8(zeros(1, 508+6, 3));
    
    % goggle
    goggle2 = bin2dec(['0',num2str(goggle(2)),num2str(goggle(1)),'00000']);
    encodedDIOdata(1,10,3) = uint8(goggle2);              % goggle
    encodedDIOdata(1,10,2) = uint8(0);                    % always zero
    encodedDIOdata(1,10,1) = uint8(1);                    % address
    
    encodedDIOdata(1,11,:) = uint8([0 0 0]);              % empty

    % DAC
    dac2 = round(((DAC+5)/10)*(2^16-1)); % convert to 0 - 65535 (2^16) range
    dacMS = floor(dac2/256);
    dacLS = rem(dac2,256);

    % DAC port 1
    encodedDIOdata(1,12,3) = uint8(dacLS(1));             % LSB 
    encodedDIOdata(1,12,2) = uint8(dacMS(1));             % MSB
    encodedDIOdata(1,12,1) = uint8(2);                    % address
    
    encodedDIOdata(1,13,:) = uint8([0 0 0]);              % empty
    
    % DAC port 2
    encodedDIOdata(1,14,3) = uint8(dacLS(2));             % LSB 
    encodedDIOdata(1,14,2) = uint8(dacMS(2));             % MSB
    encodedDIOdata(1,14,1) = uint8(3);                    % address
    
    encodedDIOdata(1,15,:) = uint8([0 0 0]);              % empty
    
   % shift the rest of the matrix of goggle and DAC is used
   shift=6;
else
    % Prepare the data array - wothout goggle and DAC
    encodedDIOdata = uint8(zeros(1, 508, 3));
    
    % dont shift if goggle and ADC is not used
    shift = 0;
end


% Putting the unlock code for DVI Data Packet
encodedDIOdata(1,1:8,1:3) =  ...
    uint8([69  40  19  119 52  233 41  183;  ...
    33  230 190 84  12  108 201 124;  ...
    56  208 102 207 192 172 80  221])';

% Length of a packet - it could be changed
encodedDIOdata(1,9,3) = uint8(249);	% length of data packet = number + 1

% Command - data packet
encodedDIOdata(1,10+shift,3) = uint8(2);          % this is a command from the digital output group
encodedDIOdata(1,10+shift,2) = uint8(command);    % command code
encodedDIOdata(1,10+shift,1) = uint8(6);          % address

% -- updated for Bits# --
% mask
maskbin = dec2bin(mask,11);
encodedDIOdata(1,12+shift,3) = uint8(bin2dec(maskbin(:,4:11)));                             % LSB DIO Mask data 
encodedDIOdata(1,12+shift,2) = uint8(bin2dec([maskbin(:,1),'00000',maskbin(:,2:3)]));       % MSB DIO Mask data
encodedDIOdata(1,12+shift,1) = uint8(7);                                                    % address

% data:
databin = dec2bin(data,11);
encodedDIOdata(1,(14:2:508)+shift,3) = uint8(bin2dec(databin(:,4:11)));                                             % LSB DIO
encodedDIOdata(1,(14:2:508)+shift,2) = uint8(bin2dec([databin(:,1),repmat('00000',length(data),1),databin(:,2:3)])); % MSB DIO 
encodedDIOdata(1,(14:2:508)+shift,1) = uint8(8:255);                                                        % addresses
% -- 

% 
% % DIO output mask
% encodedDIOdata(1,12+shift,3) = uint8(bitand(mask, 255));    % LSB DIO Mask data - Modified by MK, added bitand()!
% encodedDIOdata(1,12+shift,2) = uint8(bitshift(mask, -8));   % MSB DIO Mask data
% encodedDIOdata(1,12+shift,1) = uint8(7);                    % address
% 
% % vectorised
% encodedDIOdata(1,(14:2:508)+shift,3) = uint8(bitand(data, 255));            % LSB DIO
% % encodedDIOdata(1,14:2:508,2) = uint8(bitshift(bitand(data, 768), -8));
% encodedDIOdata(1,(14:2:508)+shift,2) = uint8(bitshift(data, -8));           % MSB DIO
% encodedDIOdata(1,(14:2:508)+shift,1) = uint8(8:255);                        % addresses





return;
