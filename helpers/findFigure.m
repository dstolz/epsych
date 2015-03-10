function f = findFigure(name,varargin)
% f = findFigure(name)
% f = findFigure(name,PROP1,VALUE1,PROP2,VALUE2,...)
%
% Find the handle to a figure by it's name property.
%
% If a figure by the provided name does not exist, one will be created with
% that name.  Optionally, figure property-value pairs can be specified
% following the figure name and will be used to create a new figure.
% 
% ex:
%   f = findFigure('MyFigure','color','w');
%
% See also, figure
% 
% Daniel.Stolzberg@gmail.com 2015


f = findobj('type','figure','-and','name',name);
if isempty(f)
    if nargin == 1
        f = figure('name',name);
    else
        f = figure('name',name,varargin{:});
    end
end
    