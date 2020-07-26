function compare(x,y)
% function compare(x,y)
%---
% Display a message about how do x and y differ (e.g. tell any size
% difference, or the maximal difference max(abs(row(x-y))), or which fields
% differ if x andd y are structures, etc.)

okname = false;
if ischar(x) && ischar(y)
    try
        [xname yname] = deal(x,y);
        [x y] = deal(evalin('caller',xname),evalin('caller',yname));
        okname = true;
    end
end
if ~okname
    [xname yname] = deal(inputname(1),inputname(2));
    if isempty(xname), xname = '1st argument'; end
    if isempty(yname), yname = '2nd argument'; end
end
        
if isequaln(x,y)
    disp 'x and y are identical'
    return
end

if ~strcmp(class(x),class(y))
    fprintf('%s is a %s, %s is a %s\n',xname,class(x),yname,class(y))
    if ~(islogical(x) || isnumeric(x)) || ~(islogical(y) || isnumeric(y)), return, end
end

if ~isequal(size(x),size(y))
    fprintf('size of %s is [%s], size of %s is [%s]\n', ...
        xname,fn_strcat(size(x),' '),yname,fn_strcat(size(y),' '))
    return
end

% now x and y are of compatible types, and of the same size
N = numel(x);
if isnumeric(x) || islogical(x) || ischar(x)
    if isnumeric(x) || isnumeric(y)
        xnan = isnan(x); ynan = isnan(y);
        n = sum(xnan(:) & ~ynan(:));
        if n, fprintf('%s has %i NaN values where %s hasn''t\n',xname,n,yname), end
        n = sum(ynan(:) & ~xnan(:));
        if n, fprintf('%s has %i NaN values where %s hasn''t\n',yname,n,xname), end
    end
    d = row(abs(x-y));
    n = sum(d>0);
    if n
        fprintf('%s and %s differ in %i out of %i values\n',xname,yname,n,N)
        if isnumeric(x) || isnumeric(y), fprintf('maximal difference is %g\n',max(d)), end
    else
        fprintf('Non-NaN values in %s and %s do not differ\n',xname,yname)
    end
elseif iscell(x)
    n = 0;
    for i=1:N, n = n + ~isequaln(x{i},y{i}); end
    if n
        fprintf('%s and %s differ in %i out of %i values\n',xname,yname,n,N)
    else
    end
elseif isstruct(x) && isscalar(x)
    Fx = fieldnames(x);
    Fy = fieldnames(y);
    ok = true;
    F = setdiff(Fx,Fy);
    if ~isempty(F)
        fprintf('Some fields are present in %s but not %s: %s\n',xname,yname,fn_strcat(F,', '))
        ok = false;
    end
    F = setdiff(Fy,Fx);
    if ~isempty(F)
        fprintf('Some fields are present in %s but not %s: %s\n',yname,xname,fn_strcat(F,', '))
        ok = false;
    end
    if ok && ~isequal(Fx,Fy)
        fprintf('Fields in %s and %s are not in the same order\n',yname,xname)
        ok = false;
    end
    F = intersect(Fx,Fy); 
    b = fn_map(F,@(f)~isequaln(x.(f),y.(f)),'array');
    if any(b)
        fprintf('%s and %s differ for field(s) %s\n',yname,xname,fn_strcat(F(b),', '))
    elseif ok
        error('%s and %s seem to be equal, but isequaln(x,y) returned false!',yname,xname)
    end
else
    fprintf('No comparisons implemented for class ''%s''\n',class(x))
end
