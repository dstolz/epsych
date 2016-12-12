function visualPolar3(h,x,Target,prop)

persistent p p2
%Define the shape and colour of the dot based on elevation and target
%heading
if x(6) <= -15
    dotColour = 'b';
    dotMarker = 'o';
elseif x(6) <= 15
    if (x(5) > (prop(2,prop(1)) - prop(3,prop(1)))) && (x(5) < (prop(2,prop(1)) + prop(3,prop(1))))
        dotColour = 'g';
        dotMarker = '*';
    else
        dotColour = 'g';
        dotMarker = 'o';
    end
else
    dotColour = 'r';
    dotMarker = 'o';
end


%Polar plot

%Defining the limits of an acceptable response
ppx = [(-1*deg2rad(prop(2,prop(1))) + deg2rad(90+prop(3,prop(1)))) (-1*deg2rad(prop(2,prop(1))) + deg2rad(90-prop(3,prop(1))))];
%Drawing the limits
if isempty(p)
    p = polar(h.axes1,ppx,[1 1],'k+');
    %Keep the limits drawn while the current direction gets drawn
    hold(h.axes1,'on')
    %Show the current direction, including a colour and magnitude for elevation
    p2 = polar(h.axes1,(-1*deg2rad(x(5)) + deg2rad(90)),cosd(x(6)));
    set(p2,'Color',dotColour,'Marker',dotMarker);
    %Allow the plot to be redrawn for the mext cycle
    
    % find all of the text objects in the polar plot
    t = findall(h.axes1,'type','text');
    % delete the text objects
    delete(t);
else
    [x1,y1] = pol2cart(ppx,[1 1]);
    set(p,'xdata',x1,'ydata',y1,'Color','k','Marker','+');
    [x2,y2] = pol2cart((-1*deg2rad(x(5)) + deg2rad(90)),cosd(x(6)));
    set(p2,'xdata',x2,'ydata',y2,'Color',dotColour,'Marker',dotMarker);
end

hold(h.axes1,'off')