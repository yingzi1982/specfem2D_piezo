function [f_lower, f_upper] = octaveBand(f,octaveBand)
    ratio=(2^(1/2))^octaveBand;
    f_lower = f/ratio;
    f_upper = f*ratio;
endfunction
