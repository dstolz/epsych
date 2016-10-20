function v = TDTpartag(AX,tagname,value)
% v = TDTpartag(AX,tagname,[value])
%
% Inputs:
%   AX      ... ActiveX handle 
%   tagname ... Parameter tag name (string or cell-string array)   
%   value   ... To set tag value, include this input. If not specified,
%               i.e. only AX and tagname are specified, the parameter tag
%               value will be returned in v.
%
% Outputs:
%   v   ... Values returned for each tagname (size of tagname)
%
% Set/Get parameter value using either the OpenDeveloper or standard RPco.x
% ActiveX tags from TDT.
%
% If a period '.' character is found in a tagname then this function
% assumes the string before the period is a module identifier.  If AX is
% for OpenDeveloper (OpenEx), then the tagname is not modified.  If AX is
% RPco.x (not OpenEx), then the string before the period, and the period
% itself, are removed from the tagname. 
%
% ex: 
%        % set 'MyParameter' on the 'Behavior' module if using with OpenEx.
%        % If AX is not for OpenEx, then 'Behavior.' is removed from the
%        % tagname.
%        TDTpartag(AX,'Behavior.MyParameter',1);
%
%        % get 'MyParameter' value from the 'Behavior' module if using with
%        % OpenEx.  Otherwise, 'Behavior.' is removed from tagname and
%        % 'MyParameter' value will be returned.
%        v = TDTpartag(AX,'Behavior.MyParameter');
%
% Daniel.Stolzberg@gmail.com 7/2016

% Copyright (C) 2016  Daniel Stolzberg, PhD

narginchk(2,3);

if ~iscell(tagname), tagname = cellstr(tagname); end

if isa(AX,'COM.TDevAcc_X') % using OpenEx
    if nargin == 2
        fnc = 'GetTargetVal';
    else
        fnc = 'SetTargetVal';
    end
else
    if nargin == 2
        fnc = 'GetTagVal';
    else
        fnc = 'SetTagVal';
    end
    
    for j = 1:length(tagname)
        i = find(tagname{j} == '.',1,'first');
        if ~isempty(i), tagname{j} = tagname{j}(i+1:end); end
    end
end

v = zeros(size(tagname));
if nargin == 2 % get
    for j = 1:numel(tagname)
        eval(sprintf('v(%d)=AX.%s(''%s'');',j,fnc,tagname{j}));
    end
else % set
    for j = 1:numel(tagname)
        eval(sprintf('v(%d)=AX.%s(''%s'',%0.20f);',j,fnc,tagname{j},value(j)));
    end    
end
