function tbwrite(table,cols,vecs,varargin)
% tbwrite  Write to MySQL table           [mym utilities]
% Inputs   table - table name, string
%          cols  - list of input columns,  (m*1) cell array of strings 
%          vecs  - list of output vectors, (m*1) cell array of strings
%          buffer - number of rows per INSERT VALUES flush, 1000 default
% Example  With a database open:
%          names = {'employee_name','employee_dob','employee_age'};
%          types = {'varchar(30)','date','double'};
%          vecs  = {'name','dob','age'};
%          tbadd('staff',names,types,'replace')
%          name = {'Brad','Angelina'};
%          dob  = {'1963-12-18',''};
%          age  = [43 NaN];
%          tbwrite('staff',names,vecs)
%          clear name dob age
%          tbread('staff',names,vecs,'') 
%          name, dob, age
% Notes    1. Consider using 'mym('load from infile ..''
%          2. vecs elements are case-sensitive, cols elements are not 
%          3. Columns not found in cols will have NULL values in appended rows 
%          4. Numeric values are passed to MySQL as strings: s = num2str(x,8).
%             Edit code to change digits-of-precision parameter.
% AUTHOR  : Dimitri Shvorob, dimitri.shvorob@vanderbilt.edu, 7/12/07

checkInputs(table,cols,vecs)
if nargin > 3 
   b = varargin{1};
   if ~(b == floor(b) && b > 0)
      error('''buffer'' must be a positive integer.')
   end   
else
   b = 1000;
end
all = tbattr(table);
n = [];
c = cols{1};
for i = 1:length(cols)
    if ~any(strcmpi(all,cols{i}))
       error('Column %s not found in table %s',cols{i},table)
    end  
    try
        ni = evalin('caller',sprintf('length(%s)',vecs{i})); % changed from 'base' to 'caller' DS
        if i == 1
           n = ni;
        else
           c = [c ',' cols{i}];
           if ni ~= n
              error('''vecs'' references vectors of different lengths')  
           end   
        end
    catch
       error('%s not found in workspace',vecs{i}) 
    end
end 
k = length(cols);
n = evalin('caller',sprintf('length(%s)',vecs{1})); % changed from 'base' to 'caller' DS
f = 1:ceil(n/b);
l = 1 + b*(f - 1);
u = min(l + b - 1,n);
for i = f
    for j = 1:k
        x = evalin('caller',sprintf('%s(%d:%d)',vecs{j},l(i),u(i))); % changed from 'base' to 'caller' DS
        if iscell(x)
           x = strcat('''',char(x(:)),'''');
        else
           x = num2str(x(:),8);
        end  
        if j == 1
           Z = strcat('(',x);
        else
           Z = strcat(Z,',',x);
        end   
    end    
    Z = strcat(Z,'),');
    Z = reshape(Z',1,[]);
    Z = strrep(Z,'NaN','NULL');
    Z = strrep(Z,'''''','NULL');
    s = ['insert into ' table ' (' c ') values ' Z];
    s(end) = '';
    try
       mym(s)   
    catch
       error('Write failed')
    end
end

function checkInputs(table,cols,vecs)
if ~istable(table)
   error('Table %s not found; use ''tblist'' to list available tables',table)
end
if ~(iscellstr(cols) && isvector(cols))
   error('''cols'' must be a cell vector of strings')
end
if ~(iscellstr(vecs) && isvector(vecs))
   error('''vecs'' must be a cell vector of strings')
end
if length(cols) ~= length(vecs)
   error('''cols'' and ''vecs'' must have the same length')
end