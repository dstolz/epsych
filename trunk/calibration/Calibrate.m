function cvals = Calibrate(vals,C)
% cvals = Calibrate(vals,C)
%
% This function uses the Matlab PCHIP function in order to estimate values
% between points (e.g. tone frequencies) which were measured.
% 
% C is a calibration structure saved from a call to the CalibrationUtil GUI
%
% vals  : value to calibrate
% C     : calibration structure
% cvals : calibrated value
%
% See also, CalibrationUtil, pchip
% 
% DJS 2012

% NEED TO PROVIDE DIFFERENT METHODS OF FINDING INTERPOLANT BASED ON
% DIFFERENT CALIBRATION TYPES: e.g. click or filtered noise of varing
% bandwidths.

x = C.data(:,1);
y = C.data(:,end);

if length(y) == 1
    cvals = y;
else
    cvals = pchip(x,y,vals);
end
