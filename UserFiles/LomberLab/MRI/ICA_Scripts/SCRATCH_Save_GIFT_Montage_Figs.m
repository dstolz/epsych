%% Save all GIFT Montage images to current directory

h = findobj('type','figure','-and','-regexp','tag','Explorer')

for i = 1:length(h)
    tn = get(h(i),'tag');
    tn(1:length('Explorer'))=[];
    saveas(h(i),sprintf('ICA_Component_%03d.tif',str2double(tn)),'tiffn')
end