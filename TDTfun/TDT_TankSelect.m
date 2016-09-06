function varargout = TDT_TankSelect(varargin)
% [tanks,ok] = TDT_TankSelect(varargin)
% 
% Optional Input Parameters:
%       'SelectionMode'  ...  'multiple' or 'single' (default)
%       'Name'           ...  dialog title
%       'OKString'
%       'CancelString'
%       'TankList'       ...  optional tank list for using specified tanks
%                           only.  Default is to display all registered tanks.
%       
% See also, TDT_BlockSelect
%
% DJS 2010

% Copyright (C) 2016  Daniel Stolzberg, PhD

% set defaults
smode = 'single';
sname = 'Select Tank';
okstr = 'Select';
castr = 'Cancel';
tanks = [];

ptags  = {'SelectionMode','Name','OKString','CancelString','tanklist'};
vnames = {'smode','sname','okstr','castr','tanks'};

ParseVarargin(ptags,vnames,varargin);


if isempty(tanks) && (~nargin || ~isa(varargin{1},'COM.TTank_X'))
    [TT,tanks,TDTfig] = TDT_SetupTT;
    delete(TT);
    close(TDTfig);

elseif isempty(tanks) && isa(varargin{1},'COM.TTank_X')
    tanks = TDT_RegTanks(varargin{1});
end
tanks = sort(tanks);

varargout{1} = [];
varargout{2} = 0;
if isempty(tanks)
    warndlg('No Tanks Registered on This System!','No Tanks','modal');
    return
end

[tind,ok] = listdlg('ListString',tanks, ...
                   'SelectionMode',smode, ...
                   'Name',sname, ...
                   'OKString',okstr, ...
                   'CancelString',castr);
               
varargout{1} = tanks(tind);
varargout{2} = ok;
