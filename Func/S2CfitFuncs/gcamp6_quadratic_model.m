function para_final =  gcamp6_quadratic_model(spk, dff, t_frame, para_start)
    options         = optimset('Display','off','TolX',1e-5,'TolFun',1e-2);
    para_final      = fminsearch(@(p) func_error(spk, dff, t_frame, p), para_start, options);
end

function mse   = func_error(spk, dff, t_frame, p)
    CaTraces   = func_getCaTraces_quadratic(spk, t_frame, p);
    mse        = sum((CaTraces - dff).^2);
end