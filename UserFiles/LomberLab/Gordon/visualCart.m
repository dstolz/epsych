function visualCart(h,x,Target,Head,Tol)

persistent p p2
%Define the shape and colour of the dot based on elevation and target
%heading
if x(6) <= -15
    dotColour = 'b';
    dotMarker = 'o';
elseif x(6) <= 15
    if (x(5) > (Head(Target) - Tol(Target))) && (x(5) < (Head(Target) + Tol(Target)))
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


%Cartesian plot

%Defining the limits of an acceptable response
ppx = [(Head(Target) - Tol(Target)) (Head(Target) - Tol(Target)) (Head(Target) + Tol(Target)) (Head(Target) + Tol(Target))];
%Drawing the limits
if isempty(p)
    p = scatter(h.axes1,ppx,[-5 5 -5 5]);
    p.MarkerEdgeColor = 'k';
    p.Marker = '+';
    %Keep the limits drawn while the current direction gets drawn
    hold(h.axes1,'on')
    %Show the current direction, including a colour and magnitude for elevation
    p2 = scatter(h.axes1,x(5),x(6));
    p2.MarkerEdgeColor = dotColour;
    p2.Marker = dotMarker;
    xlim(h.axes1,[-50 50]);
    ylim(h.axes1,[-50 50]);
    grid(h.axes1,'on');
    grid(h.axes1,'minor');
    h.axes1.XTick = -40:10:40;
    h.axes1.YTick = -40:10:40;
else
    p.XData = ppx;
    %set(p,'xdata',ppx,'ydata',[0 0],'MarkerEdgeColor','k','markertype','+');
    
    p2.XData = x(5);
    p2.YData = x(6);
    p2.MarkerEdgeColor = dotColour;
    p2.Marker = dotMarker;
    %set(p2,'xdata',x(5),'ydata',x(6),'MarkerEdgeColor',dotColour,'markertype',dotMarker);
end

hold(h.axes1,'off')