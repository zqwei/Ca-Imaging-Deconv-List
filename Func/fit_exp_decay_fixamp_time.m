function [tau]=fit_exp_decay_fixamp(traces,time)

ntraces=size(traces,2);
length=size(traces,1);

A=1;
B=0;

for i=1:ntraces
    trace=traces(:,i);
    t=time(:,i);
    t=t-t(1);
    x0=t(round(length/2));  %
    x0 = fminsearch(@fit_error,x0);
    tau(i)=x0;  
    fit=A*exp(-t'/x0)+B;
%     figure;plot(trace)
%     hold on;
%     plot(fit,'r');
end

function sq_error=fit_error(x0)
    fit=A*exp(-t/x0)+B;
    error=trace-fit;
    sq_error=sum(error.^2);
end

end