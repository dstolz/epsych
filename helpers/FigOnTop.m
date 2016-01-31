function FigOnTop(figh,state)
% FigOnTop(figh,state)
% 
% Maintain figure (figure handle = figh) on top of all other windows if
% state = true.
% 
% No errors or warnings are thrown if for some reason this function is 
% unable to keep figh on top.
% 
% Daniel.Stolzberg 2014

% narginchk(2,2);
assert(ishandle(figh),'The first input (figh) must be a valid figure handle');
assert(islogical(state)||isscalar(state),'The second input (state) must be true (1) or false (0)');


drawnow expose

try %#ok<TRYNC>
    warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
    J = get(figh,'JavaFrame');
   if verLessThan('matlab','8.1')
        J.fHG1Client.getWindow.setAlwaysOnTop(state);
    else
        J.fHG2Client.getWindow.setAlwaysOnTop(state);
    end
    warning('on','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
end