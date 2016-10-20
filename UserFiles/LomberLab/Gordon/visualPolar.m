function visualPolar(h,x,prop)

persistent p p2

%Define the shape and colour of the dot based on elevation and target
%heading
if x(6) <= -1*20
    dotColour = 'bo';
elseif x(6) <= 20
    if (x(5) > (prop(2,prop(1)) - prop(3))) && (x(5) < (prop(2,prop(1)) + prop(3)))
        dotColour = 'g*';
    else
        dotColour = 'go';
    end
else
    dotColour = 'ro';
end


%Polar plot

%Defining the limits of an acceptable response
ppx = [(-1*deg2rad(prop(2,prop(1))) + deg2rad(90+prop(3))) (-1*deg2rad(prop(2,prop(1))) + deg2rad(90-prop(3)))];
%Drawing the limits
p = polar(h.axes1,ppx,[1 1],'k+');
%Keep the limits drawn while the current direction gets drawn
hold(h.axes1,'on')
%Show the current direction, including a colour and magnitude for elevation
p2 = polar(h.axes1,(-1*deg2rad(x(5)) + deg2rad(90)),cosd(x(6)),dotColour);
%Allow the plot to be redrawn for the mext cycle

% find all of the text objects in the polar plot

t = findall(h.axes1,'type','text');

% delete the text objects

delete(t);

hold(h.axes1,'off')