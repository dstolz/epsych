function SCRATCH_view_block_FRFs(unitid)
%% Plot all FRFs from currently selected block in DB_Browser

if nargin == 1 && ~isempty(unitid)
    IDs = mym('SELECT * FROM v_ids WHERE unit = {Si}',unitid);
else
    IDs = getpref('DB_BROWSER_SELECTION');
end

U = mym(['SELECT v.unit,u.pool,c.channel FROM v_ids v ', ...
         'JOIN units u ON u.id = v.unit ', ...
         'JOIN channels c ON v.channel = c.id ', ...
         'WHERE v.block = {Si} ', ...
         'AND u.pool > 0'],IDs.blocks);

fname = sprintf('Block_%d',IDs.blocks);
f = findobj('type','figure','-and','name',fname);
if isempty(f), f = figure('name',fname); end
figure(f);
     
E = DB_GetElectrode(IDs.tanks);
E.map = E.map(:);

P = DB_GetParams(IDs.blocks);

upools = unique(U.pool);

nrows = numel(E.map);
ncols = length(upools);

clf
set(gcf,'units','normalized');

% rowpadding = 0.01;
% colpadding = 0.01;
% rowspacing = 1/nrows-rowpadding; 
% colspacing = 1/ncols-colpadding;


fprintf('Processing %d units ',length(U.unit))
for i = 1:length(E.map)
    c = find(U.channel(i)==E.map);
    u = U.unit(U.channel==E.map(i));
    for j = 1:length(u)
        ind = U.unit == u(j);
        st  = DB_GetSpiketimes(U.unit(ind));
        [data,vals] = shapedata_spikes(st,P,{'Freq','Levl'},'win',[0 0.05]);
        
        k = ind2sub([nrows ncols],(i-1)*ncols+U.pool(ind));
        ax = subplot(nrows,ncols,k,'parent',f);
%         a = colpadding*U.pool(ind)+colspacing*(U.pool(ind)-1);
%         b = rowpadding*i+rowspacing*(i-1);
%         axes('position',[a b a+colspacing b+rowspacing]);
        
        d = sgsmooth2d(squeeze(mean(data))');
        d = interp2(d,3);
        
        x = interp1(vals{2},linspace(1,length(vals{2}),size(d,2)),'pchip');
        y = interp1(vals{3},linspace(1,length(vals{3}),size(d,1)),'linear');
        
        surf(x,y,d,'parent',ax);
        view(ax,[0 90]);
        shading(ax,'interp');
        set(ax,'xtick',[],'ytick',[],'xscale','log');
        axis(ax,'tight');
        if j == 1
            ylabel(ax,sprintf('%0.1f',E.mapdepths(i)/1000),'fontsize',5)
        end
        drawnow
    end
    fprintf('.')
end
fprintf(' done\n')


