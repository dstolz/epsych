function vprintf(verbose_level,varargin)
% vprintf(verbose_level,[red],msg,[moreinputs])
%
% Prints timestamp and text to the command window based on the current
% value of the global variable GVerbosity.  GVerbosity is a scalar
% integer value between -1 and 3:
%  -1 log message, but do not print to screen
%   0 suppresses nearly all non-critcal messages
%   1 low, information that may be generally useful to user
%   2 medium, information that can be helpful for debugging
%   3 high, lots of information about nearly all processes (debugging)
%
% Uses fprintf to print text. Additonal values must correspond to the
% escape characters defined as if calling fprintf directly.
%
% This function always prints a '\n' character at the end of the line,
% skipping a line.
%
% This function also prints messages at verbose_level <= GVerbosity to a
% log file for debugging purposes.  Each message in the log will also
% contain the function and line number sending the message.  Note that
% logging at verbose level 3 may probably screw up critical timing slightly
% and should only be used for debugging code.  A new log will be
% automatically generated for each day this script is called in a
% subdirectory to the current working directory called 'logs'.
%
% ex:  
%      global GVerbosity
%      GVerbosity = 2;
%      vprintf(2,'This is a level %d message: %s',2,'medium verbosity')
%      18:51:35.958: This is a level 2 message: medium verbosity
% 
%      vprintf(3,'This message will not be printed because GVerbosity = %d',GVerbosity)
%      18:51:35.958: This is a level 2 message: medium verbosity
% 
%      vprintf(1,1,'This is a level %d message: %s',1,'low verbosity')
%      18:51:35.958: This is a level 1 message: low verbosity
%
% 
% It is probably a good idea to close the log file when done.
%       global GLogFID % file id of the log
%       if ~isempty(GLogFID) && GLogFID >2
%           fclose(GLogFID); 
%       end
%
% The msg input can also be an MException object and the entire error
% message and stack will be printed to the log.
%
% Daniel.Stolzberg@gmail.com 2015

% Copyright (C) 2016  Daniel Stolzberg, PhD
global GVerbosity

if isempty(GVerbosity) || ~isnumeric(GVerbosity), GVerbosity = 1; end

if verbose_level > GVerbosity, return; end



 
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

% log error
if isa(msg,'MException')
    vprintf(verbose_level,red,msg.identifier);
    vprintf(verbose_level,red,msg.message);
    for i = 1:length(msg.stack)
        vprintf(verbose_level,red,'Stack %d\n\tfile:\t%s\n\tname:\t%s\n\tline:\t%d', ...
            i,msg.stack(i).file,msg.stack(i).name,msg.stack(i).line);
    end
    return
end


% log message
logmessage(msg,curTimeStr,moreinputs);

% don't want to display message, just log and return
if verbose_level == -1, return; end


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












function logmessage(msg,curTimeStr,moreinputs)
% Print to log file
global GLogFID

try
    ftell(GLogFID);
    needNewLog = false;
catch %#ok<CTCH>
    needNewLog = true;
end

if needNewLog || isempty(GLogFID) || GLogFID == -1
    errlogs = fullfile(epsych_path,'.error_logs');
    if ~isdir(errlogs), mkdir(errlogs); end
    GLogFID = fopen(fullfile(errlogs,['error_log_' datestr(now,'ddmmmyyyy') '.txt']),'at');
end

if isnumeric(GLogFID) && GLogFID > 2
    st = dbstack;
    if length(st)>=3
        st = st(3);
    else
        st = st(end);
    end
    if isempty(moreinputs)
        fprintf(GLogFID,['%s,%s,%d: ' msg '\n'],curTimeStr,st.name,st.line);
    else
        fprintf(GLogFID,['%s,%s,%d: ' msg '\n'],curTimeStr,st.name,st.line,moreinputs{:});
    end
end

