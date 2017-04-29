function varargout = gexf(filename,A,L,S,options)
% [filename] = gexf(filename,A,[L],[S],[options])
%
% Writes a formatted XML file for use with Gephi.
%
% Complies with GEXF 1.2draft format: https://gephi.org/gexf/1.2draft/gexf-12draft-primer.pdf
% 
% Only the adjacency matrix, A is required.  All other fields have default
% values.
%
% The type of graph is determined by the square adjacency matrix, A.  If A
% is symmetric, then the graph is determined to be undirected. If A is not
% symmetric, then it will be dermined to be directed. These defaults can be
% overrided by setting S.graph.defaultedgetype.
%
% inputs:
%   filename   ...   String with *.gexf extension for use with Gephi. A
%                    user dialog will appear if not specified or empty.
% 
%   A          ...   NxN adjacency matrix
% 
%   L          ...   Nx1 cell array of strings labeling nodes of A
% 
%   S          ...   Structure with some optional settings
%   S.graph.defaultedgetype ... 'directed','undirected', or 'mutual'
%   S.attributes.nodes ... Nx1 user-defined node attributes.
%      > Subfields of S.attributes.nodes are added to each node.  The names
%      of subfields are used as attribute labels and the corresponding
%      scalar subfield value is used as teh attribute value.
%           ex: S.attributes.nodes(1).url = 'website1.org'; % adds 'url' attribute to node 1 with the value 'website1.org'
%               S.attributes.nodes(2).url = 'website2.org'; % adds 'url' attribute to node 2 with the value 'website2.org'
%   S.node.color    ... Nx4 red, green, blue, alpha values. rgb [0 255], a [0 1]
%   S.node.position ... Nx3 x, y, z
%   S.node.size     ... Nx1
%   S.node.shape    ... Nx1 cell string array. ex: {'disc';'square','triangle','diamond'}
%   S.edge.color    ... Nx3 red, green, blue [0 255]
%   S.edge.thickness... Nx1 
%   S.edge.shape    ... Nx1 cell string array. ex: {'solid';'dotted';'dashed';'double'}
%
%   options.creator       ... string
%   options.description   ... string
%   options.exclude_zeros ... boolean value to ignore edges that have a
%                             value of zero (default = true)
%
% TO DO: > Add dynamic time options
%        
%
% Daniel.Stolzberg@gmail.com 4/2017


% Parse inputs -----------------------------------------

if isempty(filename)
    dfpn = getpref('gexf','dfpn',cd);
    [fn,pn] = uiputfile({'*.gexf','Gephi GEXF (*.gexf)'},'Save as',dfpn);
    if ~fn(1), varargout{1} = 0; return; end
    setpref('gexf','dfpn',pn);
    filename = fullfile(pn,fn);
end

[~,filen,ext] = fileparts(filename);
filen = [filen ext];


if nargin < 5, options = []; end
if ~isfield(options,'exclude_zeros') || isempty(options.exclude_zeros)
    options.exclude_zeros = true; % If true, do not include graph elements with weight = 0
end

if ~isfield(options,'creator'), options.creator = ''; end
if ~isfield(options,'description'), options.description = 'created with gexf.m'; end



if nargin < 4, S = []; end
% graph options
if ~isfield(S,'graph')
    S.graph = [];
    if ~isfield(S.graph,'defaultedgetype')
        if issymmetric(A)
            S.graph.defaultedgetype = 'undirected';
            A = tril(A,-1);
        elseif nnz(triu(A,1)==0) || nnz(tril(A,-1)==0)
            S.graph.defaultedgetype = 'directed';
            
        else
            S.graph.defaultedgetype = 'mutual';
        end
    end
    if ~isfield(S.graph,'mode'), S.graph.mode = 'static'; end % [static], dynamic
end




% check inputs
assert(numel(A)==prod(size(A)),'A must be a square matix'); %#ok<PSIZE>

if nargin < 3
    L = [];
elseif ~isempty(L)
    assert(numel(L)==size(A,1),'If specified, numel(L) must equal size(A,1)');
end


F.node = struct('color',false,'position',false,'size',false,'shape',false);
F.edge = struct('color',false,'thickness',false,'shape',false);
F.node.attr = isfield(S,'attributes') && isfield(S.attributes,'nodes');
F.edge.attr = isfield(S,'attributes') && isfield(S.attributes,'edges');


if isfield(S,'attributes')
    for fn = fieldnames(S.attributes)'
        S = attr_types(S,char(fn));
    end
end

% VIZ node options
if isfield(S,'node')
    if isfield(S.node,'color')
        assert(size(S.node.color,1)==size(A,1)&size(S.node.color,2)==4, ...
            'S.node.color should be an Nx4 matrix');
        F.node.color = true;
    end
    
    if isfield(S.node,'position')
        assert(size(S.node.position,1)==size(A,1)&size(S.node.position,2)==3, ...
            'S.position should be an Nx3 matrix');
        F.node.position = true;
    end
    
    if isfield(S.node,'size')
        assert(size(S.node.value,1)==size(A,1)&size(S.node.value,2)==1, ...
            'S.value should be an Nx1 matrix');
        F.node.size = true;
    end
    
    if isfield(S.node,'shape')
        assert(size(S.node.shape,1)==size(A,1)&size(S.node.shape,2)==1& ...
            iscellstr(S.node.shape),'S.size should be Nx1 cellstring');
        F.node.shape = true;
    end
end

% VIZ edge options
if isfield(S,'edge')
    if isfield(S.edge,'color')
        assert(size(S.edge.color,1)==size(A,1)&size(S.edge.color,2)==4, ...
            'S.edge.color should be an Nx4 matrix');
        F.edge.color = true;
    end
    
    if isfield(S.edge,'thickness')
        assert(size(S.edge.thickness,1)==size(A,1)&size(S.edge.color,2)==1, ...
            'S.edge.thickness should be an Nx1 matrix');
        F.edge.color = true;
    end
    
    if isfield(S.edge,'shape')
        assert(size(S.edge.shape,1)==size(A,1)&size(S.edge.shape,2)==4, ...
            'S.edge.shape should be an Nx4 matrix');
        F.edge.shape = true;
    end
end










fprintf('\nWriting ''%s'' ',filen)
% XML document ------------------------------------------------
doc = com.mathworks.xml.XMLUtils.createDocument('gexf');
e_gexf = doc.getDocumentElement;
e_gexf.setAttribute('version','1.2');
e_gexf.setAttribute('xmlns:viz','http://www.gexf.net/1.2draft/vis');

% header info
e_meta = doc.createElement('meta');
e_meta.setAttribute('lastmodifieddate',datestr(now,'YYYY-mm-DD'));
e_meta.setAttribute('xmlns','http://www.gexf.net/1.2draft');
e_gexf.appendChild(e_meta);

    e = doc.createElement('creator');
    e.appendChild(doc.createTextNode(options.creator));
    e_meta.appendChild(e);

    e = doc.createElement('description');
    e.appendChild(doc.createTextNode(options.description));
    e_meta.appendChild(e);
fprintf('.')



% graph ------------------------------------------------------
e_graph = doc.createElement('graph');
for fn = fieldnames(S.graph)'
    e_graph.setAttribute(char(fn),S.graph.(char(fn)));
end
e_gexf.appendChild(e_graph);
fprintf('.')


% NODES ------------------------------------------------------
% attributes
e_atts = doc.createElement('attributes');
e_atts.setAttribute('class','node');
e_graph.appendChild(e_atts);

if F.node.attr
    e = doc.createElement('attribute');
    k = 0;
    for fn = fieldnames(S.attributes.nodes(1))'
        e.setAttribute('id',int2str(k)); k = k + 1;
        e.setAttribute('title',(char(fn)));
        e.setAttribute('type',class(S.attributes.nodes(1).(char(fn))));
        e_atts.appendChild(e);
    end
end

% nodes
e_nodes = doc.createElement('nodes');
e_graph.appendChild(e_nodes);
for i = 1:length(L)    
    e_node = doc.createElement('node');
    e_node.setAttribute('id',int2str(i-1));
    if ~isempty(L), e_node.setAttribute('label',L{i}); end
    e_nodes.appendChild(e_node);
    
    if F.node.attr
        e_atts = doc.createElement('attvalues');
        e_node.appendChild(e_atts);
        
        k = 0;
        for fn = fieldnames(S.attributes.nodes)'
            v = S.attributes.nodes(k).(char(fn));
            if isempty(v), continue; end
            e = doc.createElement('attvalues');
            e.setAttribute('for',int2str(k)); k = k + 1;
            e.setAttribute('value',v);
            e_atts.appendChild(e);
        end
    end
    
    if F.node.color
        e = doc.createElement('viz:color');
        e.setAttribute('r',num2str(S.node.color(i,1)),0);
        e.setAttribute('g',num2str(S.node.color(i,2)),0);
        e.setAttribute('b',num2str(S.node.color(i,3)),0);
        e.setAttribute('a',num2str(S.node.color(i,4)),3);
        e_node.appendchild(e);
    end
    
    if F.node.position
        e = doc.createElement('viz:position');
        e.setAttribute('x',num2str(S.node.position(i,1)),6);
        e.setAttribute('y',num2str(S.node.position(i,2)),6);
        e.setAttribute('z',num2str(S.node.position(i,3)),6);
        e_node.appendchild(e);
    end
    
    if F.node.size
        e = doc.createElement('viz:size');
        e.setAttribute('size',num2str(S.node.size(i,1)),6);
        e_node.appendchild(e);
    end    
    
    if F.node.shape
        e = doc.createElement('viz:shape');
        e.setAttribute('shape',S.node.shape{i});
        e_node.appendchild(e);
    end
end
fprintf('.')



% EDGES -----------------------------------------------
e_atts = doc.createElement('attributes');
e_atts.setAttribute('class','node');
e_graph.appendChild(e_atts);

if F.edge.attr
    e = doc.createElement('attribute');
    k = 0;
    for fn = fieldnames(S.attributes.edges(i))'
        e.setAttribute('id',int2str(k)); k = k + 1;
        e.setAttribute('title',(char(fn)));
        e.setAttribute('type',class(S.attributes.edges(1).(char(fn))));
        e_atts.appendChild(e);
    end
end


if options.exclude_zeros
    [source,target] = ind2sub(size(A),find(abs(A)>1e-5));
else
    [source,target] = ind2sub(size(A),1:numel(A));
end

e_edges = doc.createElement('edges');
e_graph.appendChild(e_edges);
for i = 1:numel(source)
    e = doc.createElement('edge');
    e.setAttribute('id',    int2str(i-1));
    e.setAttribute('source',int2str(source(i)-1));
    e.setAttribute('target',int2str(target(i)-1));
    e.setAttribute('type',  S.graph.defaultedgetype);
    e.setAttribute('weight',sprintf('%.5f',A(source(i),target(i))));
    e_edges.appendChild(e);
    
    if F.edge.attr
        e_atts = doc.createElement('attvalues');
        e_node.appendChild(e_atts);
        
        k = 0;
        for fn = fieldnames(S.attributes.edges)'
            v = S.attributes.edges(k).(char(fn));
            if isempty(v), continue; end
            e = doc.createElement('attvalues');
            e.setAttribute('for',int2str(k)); k = k + 1;
            e.setAttribute('value',v);
            e_atts.appendChild(e);
        end
    end
    
    if F.edge.color
        e = doc.createElement('viz:color');
        e.setAttribute('r',num2str(S.edge.color(i,1)),0);
        e.setAttribute('g',num2str(S.edge.color(i,2)),0);
        e.setAttribute('b',num2str(S.edge.color(i,3)),0);
        e_node.appendchild(e);
    end
    
    if F.edge.thickness
        e = doc.createElement('viz:thickness');
        e.setAttribute('thickness',num2str(S.edge.thickness(i,1)),6);
        e_node.appendchild(e);
    end    
    
    if F.edge.shape
        e = doc.createElement('viz:shape');
        e.setAttribute('shape',S.edge.shape{i});
        e_node.appendchild(e);
    end
end
fprintf('.')

xmlwrite(filename,doc);
fprintf(' done\n')

fprintf('Click to launch Gephi: <a href="matlab: !explorer %s">%s</a>\n', ...
    filename,filen)

if nargout == 1, varargout{1} = filename; end






function S = attr_types(S,e)
k = 1;
for fn = fieldnames(S.attributes.(e))'
    switch class(S.attributes.(e)(1).(char(fn)))
        case 'char'
            if any(S.attributes.(e)(1).(char(fn)) == '|')
                S.attr_type.(e){k} = 'liststring';
            else
                S.attr_type.(e){k} = 'string';
            end            
            
        case 'logical'
            S.attr_type.(e){k} = 'boolean';
            for i = 1:length(S.attributes.(e))
                if S.attributes.(e)(i).(char(fn))
                    S.attributes.(e)(i).(char(fn)) = 'true';
                else
                    S.attributes.(e)(i).(char(fn)) = 'false';
                end
            end
            
        otherwise
            S.attr_type.(e){k} = class(S.attributes.(e)(1).(char(fn)));
    end
    
    k = k + 1;
end

