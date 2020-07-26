function z = zScore (x, y, filterInUse)

    if nargin == 3
        x     = filter(filterInUse, 1, x, [], 2);
        y     = filter(filterInUse, 1, y, [], 2);
    end

    z         = (mean(x) - mean(y))./(var(x)/size(x,1) + var(y)/size(y,1));

end