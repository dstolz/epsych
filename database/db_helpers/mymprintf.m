function out = mymprintf(sqlstring,varargin)
% [out] = mymprintf(sqlstring,[A],[...])
%
% Simple help function for MyM that incorporates sprintf functionality
%
% ex:
%       theID = 3;
%       out = mymprintf('SELECT * FROM mytable WHERE id = %d',theID);
%
% See also, sprintf, mym, myms
%
% Daniel.Stolzberg@gmail.com 2016

narginchk(1,inf);
nargoutchk(0,1);

% Print to command window
if nargin == 1 || isempty(varargin)
    if nargout
        out = mym(sqlstring);
    else
        mym(sqlstring);
    end
elseif nargout
    out = myms(sprintf(sqlstring,varargin{:}));
else
    mym(sprintf(sqlstring,varargin{:}));
end



