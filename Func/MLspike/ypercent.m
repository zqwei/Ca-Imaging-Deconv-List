function ypercent
% function ypercent
%---
% Add % sign to y ticks
%
% See also xpercent, xypercent, fn_ticks

set(gca,'yticklabel',fn_num2str(get(gca,'ytick'),'%i%%','cell'))
