function isn = checkStrIsNum(Str)
% isn = checkStrIsNum(Str)
% 
% True if all values in strtrim(Str) are numeric characters.
%
% Daniel.Stolzberg@gmail.com 2016

isn = all(ismember(strtrim(Str),'0123456789+-.eEdD'));