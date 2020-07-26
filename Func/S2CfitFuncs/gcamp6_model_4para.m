function para_final=gcamp6_model_4para(spk,dff,t_frame,para_start)
    fmax       = 20;
    mse0       = 0;
    mse0       = func_error([fmax,para_start(2:end)]);
    options    = optimset('Display','iter','TolX',1e-3,'TolFun',0.1);
    para_final = fminsearch(@func_error,para_start(2:end),options);

    para_final = [fmax,para_final];
    [CaTraces] = func_getCaTraces_general_new(spk,t_frame,para_final);
    % figure;plot(CaTraces);hold on;plot(dff,'r');

    function mse=func_error(p)
        [CaTraces]=func_getCaTraces_general_new(spk,t_frame,[fmax,p]);
        mse=sum((CaTraces-dff).^2);
    end

end
