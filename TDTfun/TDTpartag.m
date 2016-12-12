function v = TDTpartag(AX,TRIALS,tagname,value)
% v = TDTpartag(AX,TRIALS,tagname,[value])
%
% Inputs:
%   AX      ... ActiveX handle 
%   TRIALS  ... TRIALS structure found in global structure RUNTIME. If
%               running multiple subjects at once, then pass only the
%               TRIALS index of the subject paramters you would like to
%               update.  ex:
%               TDTpartag(AX,TRIALS(3),'ModuleName.ParamterTag',10)
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
%        TDTpartag(AX,TRIALS,'Behavior.MyParameter',1);
%
%        % get 'MyParameter' value from the 'Behavior' module if using with
%        % OpenEx.  Otherwise, 'Behavior.' is removed from tagname and
%        % 'MyParameter' value will be returned.
%        v = TDTpartag(AX,TRIALS,'Behavior.MyParameter');
%
% Daniel.Stolzberg@gmail.com 7/2016

% Copyright (C) 2016  Daniel Stolzberg, PhD

try
% narginchk(3,4);

if ~iscell(tagname), tagname = cellstr(tagname); end

isOpenEx = isa(AX,'COM.TDevAcc_X'); % using OpenEx
if isOpenEx
    if nargin == 3
        fnc = 'GetTargetVal';
    else
        fnc = 'SetTargetVal';
    end
else
    if nargin == 3
        fnc = 'GetTagVal';
    else
        fnc = 'SetTagVal';
    end
    
end

if nargin == 4 && ~iscell(value), value = num2cell(value); end

modname = tagname;
for j = 1:length(tagname)
    i = find(tagname{j} == '.',1,'first');
    modname{j} = tagname{j}(1:i-1);
    if ~isempty(i), tagname{j} = tagname{j}(i+1:end); end
end

v = zeros(size(tagname));

if nargin == 3 % get
    if isOpenEx
        for j = 1:numel(tagname)
            eval(sprintf('v(%d)=AX.%s(''%s.%s'');',j, ...
                fnc,modname{j},tagname{j}));
        end
    else
        
        for j = 1:numel(tagname)
            eval(sprintf('v(%d)=AX(%d).%s(''%s'');',j, ...
                TRIALS.MODULES.(modname{j}),fnc,tagname{j}));
        end
    end
else % set
    
    if isOpenEx
        for j = 1:numel(tagname)
            eval(sprintf('v(%d)=AX.%s(''%s.%s'',%0.10f);',j, ...
                fnc,modname{j},tagname{j},value{j}));
        end

    else
        for j = 1:numel(tagname)
            eval(sprintf('v(%d)=AX(%d).%s(''%s'',%0.10f);',j, ...
                TRIALS.MODULES.(modname{j}),fnc,tagname{j},value{j}));
        end
    end
end
catch me
    
    rethrow(me)
end

















