function vprintf(verbose_level,varargin)
% vprintf(verbose_level,[red],msg,[moreinputs])
%
% Prints timestamp and text to the command window based on the current
% value of the global variable ExptVerbosity.  ExptVerbosity is a scalar
% integer value between 0 and 3:
%   0 suppresses nearly all non-critcal messages
%   1 low, information that may be generally useful to user (default)
%   2 medium, information that can be helpful for debugging
%   3 high, lots of information about nearly all processes
%
% Uses fprintf to print text. Additonal values must correspond to the
% escape characters defined as if calling fprintf directly.
%
% This function always prints a '\n' character at the end of the line,
% skipping a line.
%
% This function also prints messages at verbose_level <= ExptVerbosity to a
% log file for debugging purposes.  Each message in the log will also
% contain the function and line number sending the message.  Note that
% logging at verbose level 3 will probably screw up timing slightly and
% should only be used for debugging.  A new log will be automatically
% generated for each day this script is called.
%
% ex:  
%      global ExptVerbosity
%      ExptVerbosity = 2;
%      vprintf(2,'This is a level %d message: %s',2,'medium verbosity')
%      18:51:35.958: This is a level 2 message: medium verbosity
%      
%      vprintf(1,1,'This is a level %d message: %s',1,'low verbosity')
%      18:51:35.958: This is a level 1 message: low verbosity
%
% 
% Daniel.Stolzberg@gmail.com 2015

global ExptVerbosity ExptLogFID

if verbose_level > ExptVerbosity, return; end


if isempty(ExptVerbosity), ExptVerbosity = 1; end


curTimeStr = datestr(now,'HH:MM:SS.FFF');

moreinputs = [];
red = 0;

if nargin == 2
    msg = varargin{1};
    
elseif nargin > 2 && ~ischar(varargin{1})
    red = varargin{1};
    msg = varargin{2};
    if nargin > 2
        moreinputs = varargin(3:end);
    end
    
elseif nargin > 2
    msg = varargin{1};
    moreinputs = varargin(2:end);
    
end

% Print to command window
if isempty(moreinputs)
    if red
        fprintf(2,['%s: ' msg '\n'],curTimeStr) %#ok<PRTCAL>
    else
        fprintf(['%s: ' msg '\n'],curTimeStr)
    end
else
    if red
        fprintf(2,['%s: ' msg '\n'],curTimeStr,moreinputs{:}) %#ok<PRTCAL>
    else
        fprintf(['%s: ' msg '\n'],curTimeStr,moreinputs{:})
    end
end


% Print to log file
try
    ftell(ExptLogFID);
    needNewLog = false;
catch %#ok<CTCH>
    needNewLog = true;
end

if needNewLog || isempty(ExptLogFID) || ExptLogFID == -1
    ExptLogFID = fopen(sprintf('logs\\expt_log_%s.log',datestr(now,'ddmmmyyyy')),'at');
    fprintf(ExptLogFID,'Log file created: %s\n',datestr(now));
end

if isnumeric(ExptLogFID) && ExptLogFID > 2
    st = dbstack;
    if isempty(moreinputs)
        fprintf(ExptLogFID,['%s,%s,%d: ' msg '\n'],curTimeStr,st(2).name,st(2).line);
    else
        fprintf(ExptLogFID,['%s,%s,%d: ' msg '\n'],curTimeStr,st(2).name,st(2).line,moreinputs{:});
    end
end

